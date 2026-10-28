# shellcheck shell=bash
# social — Telegram research: True Bearing's own engine (lookups, searches,
# members, profiles; Telethon in a private venv) and telegram-tracker for
# channel collection. telegram-tracker needs Python 3.14+, newer than Debian 13
# and Ubuntu 24.04 ship, so uv installs it with its own Python (Astral's
# standard builds) without touching the system Python.

tb_register social "Telegram research (lookups, searches, members, channel collection)" "linux macos" mod_social

tb_telegram_engine() {
  local venv="$TB_VENVS/telegram"
  mkdir -p "$TB_VENVS" "$TB_BIN" "$TB_HOME/lib"
  [ -x "$venv/bin/python" ] || python3 -m venv "$venv" || return 1
  if ! "$venv/bin/python" -c 'import telethon' 2>/dev/null || [ "$TB_UPDATE" = 1 ]; then
    tb_pip /dev/null "Telethon" "$venv/bin/pip" install --upgrade "telethon<2" || { tb_warn "Telethon install failed"; return 1; }
  fi
  install -m 644 "$TB_REPO/lib/tb_telegram.py" "$TB_HOME/lib/tb_telegram.py"
  printf '#!/usr/bin/env bash\n# True Bearing wrapper: Telegram engine in its own venv\nexec "%s/bin/python" "%s/lib/tb_telegram.py" "$@"\n' \
    "$venv" "$TB_HOME" > "$TB_BIN/tb_telegram"
  chmod +x "$TB_BIN/tb_telegram"
  tb_info "Telegram engine ✓ (API searches: add the API ID and hash under API keys, then Telegram → Log in for searches)"
}

tb_tgtracker() {
  tb_pipx uv || return 1
  if tb_has tgtracker; then
    if [ "$TB_UPDATE" = 1 ]; then tb_bg /dev/null "uv: telegram-tracker" uv tool upgrade telegram-tracker || tb_warn "telegram-tracker: upgrade failed"; fi
    tb_info "tgtracker ✓"
    return 0
  fi
  if tb_bg /dev/null "uv: telegram-tracker (with Python 3.14)" uv tool install --python 3.14 "git+https://github.com/estebanpdl/telegram-tracker"; then
    tb_info "tgtracker installed (Telegram login: Telegram menu → Log in for channel collection)"
  else
    tb_warn "telegram-tracker install failed"; return 1
  fi
}

mod_social() {
  local rc=0
  tb_telegram_engine || rc=1
  tb_tgtracker || rc=1
  return $rc
}
