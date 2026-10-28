# shellcheck shell=bash
# darkweb — the Tor client service (a local SOCKS proxy on 127.0.0.1:9050) and
# torsocks, used by ns-darkweb, and OnionShare for sending and receiving files
# over private .onion links. Tor Browser itself comes with the browsers module.
# This is a Tor client only, never a relay.

ns_register darkweb "Dark web: Tor client service, torsocks, OnionShare" "linux macos" mod_darkweb

mod_darkweb() {
  local rc=0
  if ns_is_macos; then
    ns_brew tor torsocks || rc=1
    ns_cask onionshare || rc=1
    ns_info "ns-darkweb starts Tor when you need it (brew services start tor)"
  else
    ns_apt tor torsocks || rc=1
    if [ -d /run/systemd/system ]; then
      sudo systemctl enable --now tor >/dev/null 2>&1 || { ns_warn "Couldn't start the tor service"; rc=1; }
    else
      ns_info "No systemd here (a container?): start Tor yourself with 'tor &' when you need it"
    fi
    ns_info "Tor SOCKS proxy on 127.0.0.1:9050 (sudo systemctl disable --now tor to turn it off)"
    # OnionShare: the desktop app (Flathub, verified by the OnionShare project) and
    # its command-line version from PyPI, which ns-darkweb drives using the system tor
    ns_flatpak org.onionshare.OnionShare || rc=1
    ns_pipx onionshare-cli || rc=1
  fi
  return $rc
}
