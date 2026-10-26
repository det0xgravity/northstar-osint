# shellcheck shell=bash
# core — base packages, Python/Go toolchains, northstar runtime and menus.
# Always runs; every other module depends on it.

ns_register core "Base packages, pipx, Go, northstar runtime" "linux macos" mod_core

mod_core() {
  local rc=0

  if ns_is_macos; then
    ns_brew git jq python pipx go || rc=1
  else
    ns_apt git curl jq unzip ca-certificates python3 python3-venv python3-pip \
           pipx golang-go whois bind9-dnsutils xdg-utils zenity \
           wl-clipboard xclip flatpak file || rc=1
  fi

  pipx ensurepath >/dev/null 2>&1 || true
  if [ "$NS_UPDATE" = 1 ]; then
    ns_info "Upgrading pipx-managed tools…"
    pipx upgrade-all >/dev/null 2>&1 || ns_warn "some pipx upgrades failed"
    if ns_is_macos; then
      brew update >/dev/null 2>&1 && brew upgrade >/dev/null 2>&1 || true
    else
      ns_apt_update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -q upgrade || true
      ns_has flatpak && sudo flatpak update -y --noninteractive >/dev/null 2>&1 || true
    fi
  fi
  ns_go_ensure || { ns_warn "Go toolchain unavailable — Go-based tools will be skipped"; rc=1; }

  # Runtime: shared UI library, menu tools and config
  mkdir -p "$NS_BIN" "$NS_HOME/lib" "$NS_HOME/config/countries" "$NS_CONF" \
           "$NS_DATA/Cases" "$HOME/.local/bin"
  install -m 644 "$NS_REPO/lib/ui.sh" "$NS_HOME/lib/ui.sh"
  install -m 644 "$NS_REPO/lib/gen_policies.py" "$NS_HOME/lib/gen_policies.py"
  install -m 644 "$NS_REPO/lib/ns_country.py" "$NS_HOME/lib/ns_country.py"
  cp "$NS_REPO"/config/*.json "$NS_REPO"/config/*.txt "$NS_HOME/config/" 2>/dev/null
  rm -f "$NS_HOME"/config/countries/*.json      # drop packs removed upstream
  cp "$NS_REPO"/config/countries/*.json "$NS_HOME/config/countries/"
  local t
  for t in "$NS_REPO"/tools/*; do
    install -m 755 "$t" "$NS_BIN/$(basename "$t")"
    ln -sf "$NS_BIN/$(basename "$t")" "$HOME/.local/bin/$(basename "$t")"
  done
  ns_is_macos && rm -f "$NS_BIN/ns-seal" "$HOME/.local/bin/ns-seal"   # Linux-only tool

  printf '%s\n' "$NS_REPO" > "$NS_CONF/repo_path"
  printf '%s\n' "$NS_VERSION" > "$NS_CONF/version"
  [ -f "$NS_CONF/active_case" ] || echo "general" > "$NS_CONF/active_case"

  ns_path_setup
  ns_info "Runtime installed to $NS_HOME"
  return $rc
}
