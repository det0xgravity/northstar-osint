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

# Tor Browser from the Tor Project's own builds, for Linux on arm64 (Flathub's
# launcher is x86_64-only). Uses the stable channel when it has an arm64 build,
# otherwise the alpha, and verifies the download against the Tor Browser
# Developers signing key. Tor Browser updates itself after that; when stable
# gains arm64, the next run switches the alpha install to stable.
NS_TB_FPR="EF6E286DDA85EA2A4BA7DE684E2C6E8793298290"
ns_tor_browser_tarball() {
  local arch="linux-aarch64" dest="$NS_HOME/tor-browser" chan="" c json="" bin sig ver tmp
  for c in release alpha; do
    json=$(curl -fsSL "https://aus1.torproject.org/torbrowser/update_3/$c/downloads.json") || continue
    bin=$(printf '%s' "$json" | jq -r --arg a "$arch" '.downloads[$a].ALL.binary // empty')
    if [ -n "$bin" ]; then chan=$c; break; fi
  done
  [ -n "$chan" ] || { ns_warn "No Tor Browser build for $arch found"; return 1; }
  if [ "$(cat "$dest/.northstar-channel" 2>/dev/null)" = "$chan" ]; then
    ns_info "Tor Browser ($chan) ✓ — it keeps itself up to date"
    return 0
  fi
  ver=$(printf '%s' "$json" | jq -r '.version')
  sig=$(printf '%s' "$json" | jq -r --arg a "$arch" '.downloads[$a].ALL.sig')
  [ "$chan" = alpha ] && ns_warn "Installing Tor Browser $ver ALPHA: there's no stable arm64 build yet. ns-update switches to stable once there is."
  ns_has gpg || ns_apt gnupg || return 1
  tmp=$(mktemp -d)
  ns_download "$bin" "$tmp/tb.tar.xz" "download: Tor Browser $ver" && curl -fsSL "$sig" -o "$tmp/tb.tar.xz.asc" \
    || { ns_warn "Tor Browser download failed"; rm -rf "$tmp"; return 1; }
  mkdir -m 700 "$tmp/gnupg"
  GNUPGHOME="$tmp/gnupg" gpg --batch --quiet --auto-key-locate nodefault,wkd \
    --locate-keys torbrowser@torproject.org >/dev/null 2>&1 \
    || { ns_warn "Couldn't fetch the Tor Browser signing key"; rm -rf "$tmp"; return 1; }
  if ! GNUPGHOME="$tmp/gnupg" gpg --batch --status-fd 1 --verify "$tmp/tb.tar.xz.asc" "$tmp/tb.tar.xz" 2>/dev/null \
       | grep -q "VALIDSIG .* $NS_TB_FPR\$"; then
    ns_warn "Tor Browser signature did NOT verify — not installing it"
    rm -rf "$tmp"; return 1
  fi
  rm -rf "$dest" && mkdir -p "$dest"
  tar -xJf "$tmp/tb.tar.xz" -C "$dest" --strip-components=1 || { rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"
  printf '%s\n' "$chan" > "$dest/.northstar-channel"
  ( cd "$dest" && ./start-tor-browser.desktop --register-app >/dev/null 2>&1 )
  ns_info "Tor Browser $ver ($chan) installed and signature-verified; it's in your applications menu"
}

ns_install_policies() {
  local tmp rc d app
  tmp=$(mktemp -d)
  # The face-search warning page that its bookmark opens (outside hidden folders,
  # so the Firefox snap on Ubuntu can open it too)
  mkdir -p "$NS_DATA/Guides" && install -m 644 "$NS_REPO/assets/face-search.html" "$NS_DATA/Guides/face-search.html"
  python3 "$NS_REPO/lib/gen_policies.py" \
    --data       "$NS_DATA" \
    --bookmarks  "$NS_REPO/config/bookmarks.json" \
    --local      "$NS_CONF/bookmarks.local.json" \
    --countries  "$NS_REPO/config/countries" \
    --extensions "$NS_REPO/config/firefox-extensions.txt" \
    --extensions "$NS_CONF/firefox-extensions.local.txt" \
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
      # Flathub builds both for x86_64 only. Tor Browser comes straight from the
      # Tor Project instead; Mullvad Browser has no arm64 Linux build at all yet.
      ns_tor_browser_tarball || rc=1
      ns_info "Skipping Mullvad Browser: no arm64 Linux build yet (see docs/INSTALL.md)"
    else
      ns_flatpak org.torproject.torbrowser-launcher || rc=1
      ns_flatpak net.mullvad.MullvadBrowser || ns_warn "Mullvad Browser flatpak failed to install"
    fi
  fi
  ns_install_policies || rc=1
  return $rc
}
