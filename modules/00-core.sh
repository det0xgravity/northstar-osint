# shellcheck shell=bash
# core — base packages, Python/Go toolchains, True Bearing runtime and menus.
# Always runs; every other module depends on it.

tb_register core "Base packages, pipx, Go, True Bearing runtime" "linux macos" mod_core

mod_core() {
  local rc=0

  if tb_is_macos; then
    tb_brew git jq python pipx go pandoc age gnupg || rc=1
  else
    tb_apt git curl jq unzip ca-certificates python3 python3-venv python3-pip \
           pipx golang-go whois bind9-dnsutils xdg-utils zenity \
           wl-clipboard xclip libnotify-bin flatpak file pandoc age gnupg || rc=1
  fi

  pipx ensurepath >/dev/null 2>&1 || true
  if [ "$TB_UPDATE" = 1 ]; then
    tb_info "Upgrading pipx-managed tools…"
    pipx upgrade-all >/dev/null 2>&1 || tb_warn "some pipx upgrades failed"
    if tb_is_macos; then
      brew update >/dev/null 2>&1 && brew upgrade >/dev/null 2>&1 || true
    else
      tb_apt_update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -q upgrade || true
      tb_has flatpak && sudo flatpak update -y --noninteractive >/dev/null 2>&1 || true
    fi
  fi
  # Independent timestamps for evidence manifests (tb-evidence)
  tb_pipx ots opentimestamps-client || tb_warn "OpenTimestamps client not installed (optional)"
  tb_go_ensure || { tb_warn "Go toolchain unavailable — Go-based tools will be skipped"; rc=1; }

  # Runtime: shared UI library, menu tools and config
  mkdir -p "$TB_BIN" "$TB_HOME/lib" "$TB_HOME/config/countries" "$TB_CONF" \
           "$TB_DATA/Cases" "$HOME/.local/bin"
  install -m 644 "$TB_REPO/lib/ui.sh" "$TB_HOME/lib/ui.sh"
  install -m 644 "$TB_REPO/lib/gen_policies.py" "$TB_HOME/lib/gen_policies.py"
  install -m 644 "$TB_REPO/lib/tb_country.py" "$TB_HOME/lib/tb_country.py"
  # Engines run as commands, so audit.log shows "tb_breach email …"
  install -m 755 "$TB_REPO/lib/tb_breach.py" "$TB_BIN/tb_breach"
  install -m 755 "$TB_REPO/lib/tb_darkweb.py" "$TB_BIN/tb_darkweb"
  install -m 755 "$TB_REPO/lib/tb_evidence.py" "$TB_BIN/tb_evidence"
  install -m 755 "$TB_REPO/lib/tb_case.py" "$TB_BIN/tb_casework"
  install -m 755 "$TB_REPO/lib/tb_doctor.py" "$TB_BIN/tb_doctor"
  install -m 755 "$TB_REPO/lib/tb_missing.py" "$TB_BIN/tb_missing"
  install -m 755 "$TB_REPO/lib/tb_watch.py" "$TB_BIN/tb_watch"
  install -m 755 "$TB_REPO/lib/tb_casemap.py" "$TB_BIN/tb_casemap"
  install -m 755 "$TB_REPO/lib/tb_vault.py" "$TB_BIN/tb_vault"
  install -m 755 "$TB_REPO/lib/tb_triage.py" "$TB_BIN/tb_triage"
  install -m 755 "$TB_REPO/lib/tb_email.py" "$TB_BIN/tb_email"
  cp "$TB_REPO"/config/*.json "$TB_REPO"/config/*.txt "$TB_HOME/config/" 2>/dev/null
  rm -f "$TB_HOME"/config/countries/*.json      # drop packs removed upstream
  cp "$TB_REPO"/config/countries/*.json "$TB_HOME/config/countries/"
  local t n old
  for t in "$TB_REPO"/tools/*; do
    install -m 755 "$t" "$TB_BIN/$(basename "$t")"
    ln -sf "$TB_BIN/$(basename "$t")" "$HOME/.local/bin/$(basename "$t")"
  done
  # The old names from before the rename to True Bearing (v0.41) still work for
  # now: each prints the new name and runs it. To be removed in a later release.
  rm -f "$TB_BIN"/ns_* "$TB_BIN/northstar" "$TB_BIN"/ns-*
  for t in "$TB_REPO"/tools/tb-* "$TB_REPO/tools/truebearing"; do
    n=$(basename "$t")
    case "$n" in truebearing) old=northstar ;; *) old="ns-${n#tb-}" ;; esac
    printf '#!/bin/sh\necho "%s is now called %s (True Bearing OSINT)." >&2\nexec "%s/%s" "$@"\n' \
      "$old" "$n" "$TB_BIN" "$n" > "$TB_BIN/$old"
    chmod 755 "$TB_BIN/$old"
    ln -sf "$TB_BIN/$old" "$HOME/.local/bin/$old"
  done
  tb_is_macos && rm -f "$TB_BIN/tb-seal" "$HOME/.local/bin/tb-seal"   # Linux-only tool

  printf '%s\n' "$TB_REPO" > "$TB_CONF/repo_path"
  printf '%s\n' "$TB_VERSION" > "$TB_CONF/version"
  printf '%s\n' "$TB_VERSION" > "$TB_HOME/VERSION"        # recorded in each result's provenance.json
  [ -f "$TB_CONF/active_case" ] || echo "general" > "$TB_CONF/active_case"

  tb_path_setup
  tb_info "Runtime installed to $TB_HOME"
  return $rc
}
