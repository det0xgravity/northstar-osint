# shellcheck shell=bash
# lan — LAN isolation (tb-lan): an nftables table that stops this machine from
# opening connections to private networks (home or office LAN, other VMs, the
# NAS, printers), so a hostile page or file opened during an investigation
# can't reach them. Internet, DNS and DHCP keep working, and connections made
# to this machine (RDP from Kasm, SSH) still get replies. Turned on in VMs;
# on a physical machine it's left to you (tb-lan on).

tb_register lan "LAN isolation: block connections from this machine to private networks" "linux" mod_lan

# The northstar-named service and table, once the new ones are on
tb_lan_drop_old() {
  [ -e /etc/northstar ] || [ -f /etc/systemd/system/northstar-lan-block.service ] || return 0
  if [ -f /etc/systemd/system/northstar-lan-block.service ]; then
    sudo systemctl disable northstar-lan-block >/dev/null 2>&1
    sudo rm -f /etc/systemd/system/northstar-lan-block.service
    sudo systemctl daemon-reload >/dev/null 2>&1
  fi
  sudo nft delete table inet northstar_lan >/dev/null 2>&1
  sudo rm -rf /etc/northstar
  return 0
}

mod_lan() {
  local virt=""
  tb_apt nftables || return 1
  # Before v0.41 (northstar): keep the allow list and the on/off state; the old
  # rules stay on until the new ones replace them
  if [ -f /etc/northstar/lan-allow ] && [ ! -f /etc/truebearing/lan-allow ]; then
    sudo mkdir -p /etc/truebearing && sudo cp -p /etc/northstar/lan-allow /etc/truebearing/lan-allow
  fi
  if [ -f /etc/northstar/lan-block.nft ]; then
    TB_LAN_NOAUDIT=1 "$TB_BIN/tb-lan" on >/dev/null || { tb_warn "LAN isolation couldn't be moved to its new name (the old rules are still on)"; return 1; }
    tb_lan_drop_old
    tb_info "LAN isolation moved to its new name (truebearing-lan-block), still on"
    date > "$TB_CONF/lan-configured"
    return 0
  fi
  tb_lan_drop_old
  tb_has systemd-detect-virt && virt=$(systemd-detect-virt --vm 2>/dev/null)
  if [ -z "$virt" ] || [ "$virt" = none ]; then
    tb_info "Not a VM: LAN isolation left off (it would also block your printers, NAS and other devices). Turn it on with: tb-lan on"
    return 0
  fi
  if [ -f /etc/truebearing/lan-block.nft ] || [ ! -f "$TB_CONF/lan-configured" ]; then
    # First install turns it on; later updates refresh the rules only if it's still on
    TB_LAN_NOAUDIT=1 "$TB_BIN/tb-lan" on >/dev/null || { tb_warn "LAN isolation couldn't be turned on"; return 1; }
    tb_info "LAN isolation on: this VM can't open connections to private networks (exceptions: tb-lan allow ADDRESS; off: tb-lan off)"
  else
    tb_info "LAN isolation is off (you turned it off): tb-lan on to turn it back on"
  fi
  date > "$TB_CONF/lan-configured"
}
