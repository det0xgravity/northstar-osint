# shellcheck shell=bash
# lan — LAN isolation (ns-lan): an nftables table that stops this machine from
# opening connections to private networks (home or office LAN, other VMs, the
# NAS, printers), so a hostile page or file opened during an investigation
# can't reach them. Internet, DNS and DHCP keep working, and connections made
# to this machine (RDP from Kasm, SSH) still get replies. Turned on in VMs;
# on a physical machine it's left to you (ns-lan on).

ns_register lan "LAN isolation: block connections from this machine to private networks" "linux" mod_lan

mod_lan() {
  local virt=""
  ns_apt nftables || return 1
  ns_has systemd-detect-virt && virt=$(systemd-detect-virt --vm 2>/dev/null)
  if [ -z "$virt" ] || [ "$virt" = none ]; then
    ns_info "Not a VM: LAN isolation left off (it would also block your printers, NAS and other devices). Turn it on with: ns-lan on"
    return 0
  fi
  if [ -f /etc/northstar/lan-block.nft ] || [ ! -f "$NS_CONF/lan-configured" ]; then
    # First install turns it on; later updates refresh the rules only if it's still on
    NS_LAN_NOAUDIT=1 "$NS_BIN/ns-lan" on >/dev/null || { ns_warn "LAN isolation couldn't be turned on"; return 1; }
    ns_info "LAN isolation on: this VM can't open connections to private networks (exceptions: ns-lan allow ADDRESS; off: ns-lan off)"
  else
    ns_info "LAN isolation is off (you turned it off): ns-lan on to turn it back on"
  fi
  date > "$NS_CONF/lan-configured"
}
