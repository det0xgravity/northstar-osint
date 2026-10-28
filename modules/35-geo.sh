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
    ns_info "Installing PyTorch (CPU build) and GeoCLIP: a few hundred MB the first time…"
    ns_torch_cpu "$log" "$venv" torch torchvision || rc=1
    if [ $rc = 0 ] && ns_pip "$log" "GeoCLIP" "$venv/bin/pip" install --upgrade geoclip ${NS_TORCH_PIN:+-c "$NS_TORCH_PIN"}; then
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
  ns_shadowfinder || rc=1
  return $rc
}

# ShadowFinder 0.7.1 caps cartopy below 0.25 and timezonefinder below 7, which
# have no Python 3.14 wheels (Ubuntu 26.04), so pip tries to compile them and
# fails. On 3.14+ it goes in a private venv without its own pins (pipx won't
# install a package whose declared dependencies it can't find), with current
# releases of those two (same APIs) and its other dependencies as declared.
ns_shadowfinder() {
  python3 -c 'import sys; sys.exit(sys.version_info < (3, 14))' || { ns_pipx shadowfinder; return; }
  local venv="$NS_VENVS/shadowfinder" log
  if [ -x "$venv/bin/shadowfinder" ] && [ "$NS_UPDATE" != 1 ]; then
    ns_info "shadowfinder ✓"; return 0
  fi
  log=$(mktemp)
  mkdir -p "$NS_VENVS" "$NS_BIN"
  if { [ -x "$venv/bin/pip" ] || python3 -m venv "$venv" >>"$log" 2>&1; } \
     && ns_pip "$log" "pip: shadowfinder" "$venv/bin/pip" install -q -U --no-deps shadowfinder \
     && ns_pip "$log" "pip: shadowfinder libraries" "$venv/bin/pip" install -q -U "cartopy>=0.26" "timezonefinder[pytz]>=6.5" \
          "matplotlib>=3.8,<4" "fire>=0.5,<1" "pandas>=2.2,<3" "numpy>=1" "pytz>=2025" "suncalc>=0.1.3,<0.2"; then
    ln -sf "$venv/bin/shadowfinder" "$NS_BIN/shadowfinder"
    ns_info "shadowfinder installed (current cartopy and timezonefinder, for Python 3.14)"
    rm -f "$log"
  else
    ns_warn "shadowfinder install failed"; ns_show_tail "$log"; rm -f "$log"
    return 1
  fi
}
