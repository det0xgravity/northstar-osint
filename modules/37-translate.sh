# shellcheck shell=bash
# translate — offline text translation for tb-translate: Argos Translate (MIT)
# in a private venv. Language models (~100 MB per pair) download on first use.

tb_register translate "Offline text translation (Argos Translate)" "linux macos" mod_translate

mod_translate() {
  local rc=0 venv="$TB_VENVS/translate" log
  mkdir -p "$TB_VENVS" "$TB_BIN"
  [ -x "$venv/bin/python" ] || python3 -m venv "$venv" || return 1
  log=$(mktemp)
  if ! "$venv/bin/python" -c 'import argostranslate' 2>/dev/null || [ "$TB_UPDATE" = 1 ]; then
    tb_bg "$log" "pip" "$venv/bin/pip" install -q --upgrade pip
    tb_info "Installing PyTorch (CPU build, needed by its sentence splitter) and Argos Translate…"
    tb_torch_cpu "$log" "$venv" torch || rc=1
    if [ $rc = 0 ] && tb_pip "$log" "Argos Translate" "$venv/bin/pip" install --upgrade argostranslate ${TB_TORCH_PIN:+-c "$TB_TORCH_PIN"}; then
      tb_info "Argos Translate installed (language models download the first time you use a language)"
    else
      tb_warn "Argos Translate install failed"; tb_show_tail "$log"; rc=1
    fi
  else
    tb_info "Argos Translate ✓"
  fi
  rm -f "$log"
  install -m 644 "$TB_REPO/lib/tb_translate.py" "$TB_HOME/lib/tb_translate.py"
  printf '#!/usr/bin/env bash\n# True Bearing wrapper: Argos Translate in its own venv\nexec "%s/bin/python" "%s/lib/tb_translate.py" "$@"\n' \
    "$venv" "$TB_HOME" > "$TB_BIN/tb_translate"
  chmod +x "$TB_BIN/tb_translate"
  return $rc
}
