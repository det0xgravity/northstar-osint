# shellcheck shell=bash
# social — Telegram channel collection (telegram-tracker). It needs Python 3.14+,
# newer than Debian 13 and Ubuntu 24.04 ship, so uv installs it with its own
# Python (Astral's standard builds) without touching the system Python.

ns_register social "Telegram channel collection (telegram-tracker)" "linux macos" mod_social

mod_social() {
  ns_pipx uv || return 1
  if ns_has tgtracker; then
    if [ "$NS_UPDATE" = 1 ]; then uv tool upgrade telegram-tracker >/dev/null 2>&1 || ns_warn "telegram-tracker: upgrade failed"; fi
    ns_info "tgtracker ✓"
    return 0
  fi
  if uv tool install --python 3.14 "git+https://github.com/estebanpdl/telegram-tracker" >/dev/null 2>&1; then
    ns_info "tgtracker installed (Telegram login: Telegram menu → Log in)"
  else
    ns_warn "telegram-tracker install failed"; return 1
  fi
}
