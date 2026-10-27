# shellcheck shell=bash
# translate — offline text translation for ns-translate: Argos Translate (MIT)
# in a private venv. Language models (~100 MB per pair) download on first use.

ns_register translate "Offline text translation (Argos Translate)" "linux macos" mod_translate

mod_translate() {
  local rc=0 venv="$NS_VENVS/translate" log
  mkdir -p "$NS_VENVS" "$NS_BIN"
  [ -x "$venv/bin/python" ] || python3 -m venv "$venv" || return 1
  log=$(mktemp)
  if ! "$venv/bin/python" -c 'import argostranslate' 2>/dev/null || [ "$NS_UPDATE" = 1 ]; then
    ns_bg "$log" "pip" "$venv/bin/pip" install -q --upgrade pip
    ns_info "Installing PyTorch (CPU build, needed by its sentence splitter) and Argos Translate…"
    ns_torch_cpu "$log" "$venv" torch || rc=1
    if [ $rc = 0 ] && ns_pip "$log" "Argos Translate" "$venv/bin/pip" install --upgrade argostranslate ${NS_TORCH_PIN:+-c "$NS_TORCH_PIN"}; then
      ns_info "Argos Translate installed (language models download the first time you use a language)"
    else
      ns_warn "Argos Translate install failed"; ns_show_tail "$log"; rc=1
    fi
  else
    ns_info "Argos Translate ✓"
  fi
  rm -f "$log"
  install -m 644 "$NS_REPO/lib/ns_translate.py" "$NS_HOME/lib/ns_translate.py"
  printf '#!/usr/bin/env bash\n# northstar wrapper: Argos Translate in its own venv\nexec "%s/bin/python" "%s/lib/ns_translate.py" "$@"\n' \
    "$venv" "$NS_HOME" > "$NS_BIN/ns_translate"
  chmod +x "$NS_BIN/ns_translate"
  return $rc
}
