# shellcheck shell=bash
# vm — makes a Linux install ready to run as a VM (Proxmox/Kasm Workspaces, or a
# desktop hypervisor on Apple Silicon), reachable over RDP and safe to clone.

ns_register vm "VM readiness: guest tools, xrdp, clone-safe identity" "linux" mod_vm

# Installs the guest tools that match the hypervisor (Proxmox, UTM, VMware
# Fusion, Parallels…). Bare metal and unknown hypervisors get no agent.
ns_vm_guest_tools() {
  local virt=""
  ns_has systemd-detect-virt && virt=$(systemd-detect-virt --vm 2>/dev/null)
  virt="${virt:-none}"
  case "$virt" in
    kvm|qemu)
      ns_info "Hypervisor: QEMU/KVM (Proxmox, UTM) — installing guest agent + SPICE agent"
      ns_apt qemu-guest-agent spice-vdagent || return 1
      sudo systemctl start qemu-guest-agent >/dev/null 2>&1 || true   # starts when the virtio port exists
      ;;
    vmware)
      ns_info "Hypervisor: VMware — installing open-vm-tools"
      ns_apt open-vm-tools-desktop || return 1
      ;;
    parallels)
      ns_warn "Hypervisor: Parallels — install Parallels Tools yourself: Actions → Install Parallels Tools"
      ;;
    apple)
      ns_info "Hypervisor: Apple Virtualization framework — no guest agent needed"
      ;;
    none)
      ns_info "No hypervisor detected — skipping guest tools"
      ;;
    *)
      ns_warn "Hypervisor '$virt' isn't handled — install its guest tools yourself"
      ;;
  esac
}

mod_vm() {
  local rc=0 session
  ns_vm_guest_tools || rc=1
  ns_apt xrdp || rc=1
  sudo systemctl enable --now xrdp >/dev/null 2>&1 || rc=1
  getent group ssl-cert >/dev/null && sudo usermod -aG ssl-cert xrdp 2>/dev/null

  # Tell xrdp which desktop to start for this user
  case "$NS_DE" in
    gnome) session="gnome-session" ;;
    xfce)  session="startxfce4" ;;
    mate)  session="mate-session" ;;
    kde)   session="startplasma-x11" ;;
    *)     session="" ;;
  esac
  if [ -n "$session" ]; then
    echo "$session" > "$HOME/.xsession"
    ns_info "xrdp session: $session"
  else
    ns_warn "Unknown desktop — set ~/.xsession yourself (see docs/KASM.md)"
  fi

  # Silence the colour-profile authentication prompt that appears over RDP
  sudo mkdir -p /etc/polkit-1/rules.d
  sudo tee /etc/polkit-1/rules.d/45-northstar-xrdp-colord.rules >/dev/null <<'EOF'
polkit.addRule(function(action, subject) {
  if (action.id.indexOf("org.freedesktop.color-manager.") == 0 && subject.local == false) {
    return polkit.Result.YES;
  }
});
EOF

  # Clones get fresh SSH host keys on first boot (keys are removed by ns-seal)
  if dpkg -s openssh-server >/dev/null 2>&1; then
    sudo tee /etc/systemd/system/northstar-ssh-hostkeys.service >/dev/null <<'EOF'
[Unit]
Description=Regenerate SSH host keys if missing (northstar-osint)
Before=ssh.service
ConditionPathExists=!/etc/ssh/ssh_host_ed25519_key

[Service]
Type=oneshot
ExecStart=/usr/bin/ssh-keygen -A

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable northstar-ssh-hostkeys.service >/dev/null 2>&1 || rc=1
  fi
  # ns-seal runs as root, so it lives where sudo's PATH can find it
  sudo install -m 755 "$NS_REPO/tools/ns-seal" /usr/local/sbin/ns-seal || rc=1
  ns_info "Use 'sudo ns-seal' on a clone before converting it to a template"
  return $rc
}
