# shellcheck shell=bash
# browsers — Firefox, Brave, Tor Browser, Mullvad Browser, plus policies that
# install OSINT extensions and a managed bookmarks folder in every profile.

ns_register browsers "Browsers + extension/bookmark policies" "linux macos" mod_browsers

ns_brave_repo() {
  [ -f /etc/apt/sources.list.d/brave-browser-release.list ] && return 0
  sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg || return 1
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
    | sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null
  # shellcheck disable=SC2034  # read by ns_apt_update in lib/common.sh
  NS_APT_UPDATED=0   # force an apt update so the new repo is picked up
}

ns_install_policies() {
  local tmp rc d app
  tmp=$(mktemp -d)
  python3 "$NS_REPO/lib/gen_policies.py" \
    --bookmarks  "$NS_REPO/config/bookmarks.json" \
    --local      "$NS_CONF/bookmarks.local.json" \
    --extensions "$NS_REPO/config/firefox-extensions.txt" \
    --out        "$tmp"
  rc=$?
  [ -s "$tmp/firefox-policies.json" ] || { rm -rf "$tmp"; return 1; }

  if ns_is_macos; then
    for app in "/Applications/Firefox.app" "/Applications/Firefox ESR.app"; do
      [ -d "$app" ] || continue
      d="$app/Contents/Resources/distribution"
      sudo mkdir -p "$d" && sudo install -m 644 "$tmp/firefox-policies.json" "$d/policies.json"
      ns_info "Firefox policies → $d (re-run 'ns-update' after Firefox updates itself)"
    done
    ns_info "Brave on macOS: import $NS_DATA/northstar-bookmarks.html (managed bookmarks need an MDM profile)"
  else
    # /etc/firefox covers Firefox and Ubuntu's snap; /etc/firefox-esr covers Debian ESR
    for d in /etc/firefox/policies /etc/firefox-esr/policies; do
      sudo mkdir -p "$d"
      if [ -f "$d/policies.json" ] && ! cmp -s "$d/policies.json" "$tmp/firefox-policies.json"; then
        sudo cp "$d/policies.json" "$d/policies.json.bak.$(date +%Y%m%d%H%M%S)"
      fi
      sudo install -m 644 "$tmp/firefox-policies.json" "$d/policies.json"
    done
    sudo mkdir -p /etc/brave/policies/managed
    sudo install -m 644 "$tmp/brave-policies.json" /etc/brave/policies/managed/northstar.json
    ns_info "Firefox + Brave policies installed"
  fi

  install -m 644 "$tmp/northstar-bookmarks.html" "$NS_DATA/northstar-bookmarks.html"
  rm -rf "$tmp"
  ns_info "Bookmarks export → $NS_DATA/northstar-bookmarks.html"
  ns_info "Fully restart browsers to apply; check about:policies in Firefox"
  return $rc
}

mod_browsers() {
  local rc=0
  if ns_is_macos; then
    ns_cask firefox brave-browser tor-browser mullvad-browser || rc=1
  else
    if ! ns_has firefox && ! ns_has firefox-esr; then
      case "$NS_PLATFORM" in
        ubuntu) ns_warn "Firefox not found — install it with: sudo snap install firefox"; rc=1 ;;
        *)      ns_apt firefox-esr || rc=1 ;;
      esac
    fi
    if ! ns_has brave-browser; then
      { ns_brave_repo && ns_apt brave-browser; } || rc=1
    fi
    if [ "$NS_ARCH" = "arm64" ]; then
      # Flathub builds both for x86_64 only, and Tor Project's aarch64 Linux
      # builds are alpha-only (checked October 2026, Tor Browser 15.0 stable).
      ns_warn "Skipping Tor Browser and Mullvad Browser: no stable arm64 Linux builds yet (see docs/INSTALL.md)"
    else
      ns_flatpak org.torproject.torbrowser-launcher || rc=1
      ns_flatpak net.mullvad.MullvadBrowser || ns_warn "Mullvad Browser flatpak failed to install"
    fi
  fi
  ns_install_policies || rc=1
  return $rc
}
