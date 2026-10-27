# shellcheck shell=bash
# social — Telegram research: northstar's own engine (lookups, searches,
# members, profiles; Telethon in a private venv) and telegram-tracker for
# channel collection. telegram-tracker needs Python 3.14+, newer than Debian 13
# and Ubuntu 24.04 ship, so uv installs it with its own Python (Astral's
# standard builds) without touching the system Python.

ns_register social "Telegram research (lookups, searches, members, channel collection)" "linux macos" mod_social

ns_telegram_engine() {
  local venv="$NS_VENVS/telegram"
  mkdir -p "$NS_VENVS" "$NS_BIN" "$NS_HOME/lib"
  [ -x "$venv/bin/python" ] || python3 -m venv "$venv" || return 1
  if ! "$venv/bin/python" -c 'import telethon' 2>/dev/null || [ "$NS_UPDATE" = 1 ]; then
    ns_pip /dev/null "Telethon" "$venv/bin/pip" install --upgrade "telethon<2" || { ns_warn "Telethon install failed"; return 1; }
  fi
  install -m 644 "$NS_REPO/lib/ns_telegram.py" "$NS_HOME/lib/ns_telegram.py"
  printf '#!/usr/bin/env bash\n# northstar wrapper: Telegram engine in its own venv\nexec "%s/bin/python" "%s/lib/ns_telegram.py" "$@"\n' \
    "$venv" "$NS_HOME" > "$NS_BIN/ns_telegram"
  chmod +x "$NS_BIN/ns_telegram"
  ns_info "Telegram engine ✓ (API searches: add the API ID and hash under API keys, then Telegram → Log in for searches)"
}

ns_tgtracker() {
  ns_pipx uv || return 1
  if ns_has tgtracker; then
    if [ "$NS_UPDATE" = 1 ]; then ns_bg /dev/null "uv: telegram-tracker" uv tool upgrade telegram-tracker || ns_warn "telegram-tracker: upgrade failed"; fi
    ns_info "tgtracker ✓"
    return 0
  fi
  if ns_bg /dev/null "uv: telegram-tracker (with Python 3.14)" uv tool install --python 3.14 "git+https://github.com/estebanpdl/telegram-tracker"; then
    ns_info "tgtracker installed (Telegram login: Telegram menu → Log in for channel collection)"
  else
    ns_warn "telegram-tracker install failed"; return 1
  fi
}

mod_social() {
  local rc=0
  ns_telegram_engine || rc=1
  ns_tgtracker || rc=1
  return $rc
}
