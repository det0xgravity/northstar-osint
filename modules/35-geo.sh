# shellcheck shell=bash
# geo — photo geolocation for ns-geo: GeoCLIP (an AI model that estimates where
# a photo was taken, run locally) in a private venv, and Bellingcat's
# ShadowFinder. Large: PyTorch, plus a ~2 GB model downloaded on first use.

ns_register geo "Photo geolocation: GeoCLIP (local AI estimate), ShadowFinder" "linux macos" mod_geo

mod_geo() {
  local rc=0 venv="$NS_VENVS/geo" log
  mkdir -p "$NS_VENVS" "$NS_BIN"
  [ -x "$venv/bin/python" ] || python3 -m venv "$venv" || return 1
  log=$(mktemp)
  if ! "$venv/bin/python" -c 'import geoclip' 2>/dev/null || [ "$NS_UPDATE" = 1 ]; then
    ns_bg "$log" "pip" "$venv/bin/pip" install -q --upgrade pip
    ns_info "Installing PyTorch and GeoCLIP (about 1 GB the first time: this can take 10-20 minutes)…"
    # x86_64 Linux: PyTorch's CPU build (PyPI's default is a multi-GB GPU build).
    # arm64 Linux and macOS: PyPI's builds are already CPU/Apple-GPU only.
    if ns_is_linux && [ "$NS_ARCH" = amd64 ]; then
      ns_pip "$log" "PyTorch (CPU)" "$venv/bin/pip" install torch torchvision --index-url https://download.pytorch.org/whl/cpu || rc=1
    fi
    if [ $rc = 0 ] && ns_pip "$log" "GeoCLIP" "$venv/bin/pip" install --upgrade geoclip; then
      ns_info "GeoCLIP installed (its ~2 GB model downloads the first time you use it)"
    else
      ns_warn "GeoCLIP install failed"; ns_show_tail "$log"; rc=1
    fi
  else
    ns_info "GeoCLIP ✓"
  fi
  rm -f "$log"
  install -m 644 "$NS_REPO/lib/ns_geo.py" "$NS_HOME/lib/ns_geo.py"
  printf '#!/usr/bin/env bash\n# northstar wrapper: GeoCLIP helpers in their own venv\nexec "%s/bin/python" "%s/lib/ns_geo.py" "$@"\n' \
    "$venv" "$NS_HOME" > "$NS_BIN/ns_geo"
  chmod +x "$NS_BIN/ns_geo"
  ns_pipx shadowfinder || rc=1
  return $rc
}
