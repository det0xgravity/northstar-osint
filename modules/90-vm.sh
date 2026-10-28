# shellcheck shell=bash
# vm — makes a Linux install ready to run as a VM (Proxmox/Kasm Workspaces, or a
# desktop hypervisor on Apple Silicon), reachable over RDP and safe to clone.

tb_register vm "VM readiness: guest tools, xrdp, clone-safe identity" "linux" mod_vm

# The hypervisor this runs under (kvm, qemu, vmware, …), or "none"
tb_vm_virt() {
  local virt=""
  tb_has systemd-detect-virt && virt=$(systemd-detect-virt --vm 2>/dev/null)
  printf '%s\n' "${virt:-none}"
}

# Installs the guest tools that match the hypervisor (Proxmox, UTM, VMware
# Fusion, Parallels…). Bare metal and unknown hypervisors get no agent.
tb_vm_guest_tools() {
  local virt
  virt=$(tb_vm_virt)
  case "$virt" in
    kvm|qemu)
      tb_info "Hypervisor: QEMU/KVM (Proxmox, UTM) — installing guest agent + SPICE agent"
      tb_apt qemu-guest-agent spice-vdagent || return 1
      sudo systemctl start qemu-guest-agent >/dev/null 2>&1 || true   # starts when the virtio port exists
      ;;
    vmware)
      tb_info "Hypervisor: VMware — installing open-vm-tools"
      tb_apt open-vm-tools-desktop || return 1
      ;;
    parallels)
      tb_warn "Hypervisor: Parallels — install Parallels Tools yourself: Actions → Install Parallels Tools"
      ;;
    apple)
      tb_info "Hypervisor: Apple Virtualization framework — no guest agent needed"
      ;;
    none)
      tb_info "No hypervisor detected — skipping guest tools"
      ;;
    *)
      tb_warn "Hypervisor '$virt' isn't handled — install its guest tools yourself"
      ;;
  esac
}

mod_vm() {
  local rc=0 session
  tb_vm_guest_tools || rc=1
  # xrdp listens on the network (port 3389): only set it up inside a VM
  if [ "$(tb_vm_virt)" = none ]; then
    tb_info "Not a VM: skipping xrdp remote desktop (it would listen on the network)"
    sudo install -m 755 "$TB_REPO/tools/tb-seal" /usr/local/sbin/tb-seal || rc=1
    return $rc
  fi
  tb_apt xrdp || rc=1
  sudo systemctl enable --now xrdp >/dev/null 2>&1 || rc=1
  getent group ssl-cert >/dev/null && sudo usermod -aG ssl-cert xrdp 2>/dev/null

  # Tell xrdp which desktop to start for this user
  case "$TB_DE" in
    gnome) session="gnome-session" ;;
    xfce)  session="startxfce4" ;;
    mate)  session="mate-session" ;;
    kde)   session="startplasma-x11" ;;
    *)     session="" ;;
  esac
  if [ -n "$session" ]; then
    echo "$session" > "$HOME/.xsession"
    tb_info "xrdp session: $session"
  else
    tb_warn "Unknown desktop — set ~/.xsession yourself (see docs/KASM.md)"
  fi

  # Silence the colour-profile authentication prompt that appears over RDP
  sudo mkdir -p /etc/polkit-1/rules.d
  sudo tee /etc/polkit-1/rules.d/45-truebearing-xrdp-colord.rules >/dev/null <<'EOF'
polkit.addRule(function(action, subject) {
  if (action.id.indexOf("org.freedesktop.color-manager.") == 0 && subject.local == false) {
    return polkit.Result.YES;
  }
});
EOF

  # Clones get fresh SSH host keys on first boot (keys are removed by tb-seal)
  if dpkg -s openssh-server >/dev/null 2>&1; then
    sudo tee /etc/systemd/system/truebearing-ssh-hostkeys.service >/dev/null <<'EOF'
[Unit]
Description=Regenerate SSH host keys if missing (truebearing-osint)
Before=ssh.service
ConditionPathExists=!/etc/ssh/ssh_host_ed25519_key

[Service]
Type=oneshot
ExecStart=/usr/bin/ssh-keygen -A

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable truebearing-ssh-hostkeys.service >/dev/null 2>&1 || rc=1
  fi
  # Clones get fresh xrdp keys too (tb-seal removes rsakeys.ini; the TLS
  # certificate is Debian's snakeoil one, regenerated alongside)
  if [ -d /etc/xrdp ]; then
    sudo tee /etc/systemd/system/truebearing-xrdp-keys.service >/dev/null <<'EOF'
[Unit]
Description=Regenerate xrdp keys if missing (truebearing-osint)
Before=xrdp.service
ConditionPathExists=!/etc/xrdp/rsakeys.ini

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'xrdp-keygen xrdp auto && chown xrdp /etc/xrdp/rsakeys.ini; make-ssl-cert generate-default-snakeoil --force-overwrite'

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable truebearing-xrdp-keys.service >/dev/null 2>&1 || rc=1
  fi
  # tb-seal runs as root, so it lives where sudo's PATH can find it
  sudo install -m 755 "$TB_REPO/tools/tb-seal" /usr/local/sbin/tb-seal || rc=1
  tb_info "Use 'sudo tb-seal' on a clone before converting it to a template"
  return $rc
}
