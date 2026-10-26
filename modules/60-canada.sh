# shellcheck shell=bash
# canada — Canadian public-records tooling. The Canadian bookmark folders are
# delivered by the browsers module; this module sets up the 'ns-canada' menu's
# phone-number analysis (libphonenumber) in a private venv.

ns_register canada "Canadian public-records search menu" "linux macos" mod_canada

mod_canada() {
  local venv="$NS_VENVS/core"
  mkdir -p "$NS_VENVS"
  [ -x "$venv/bin/python" ] || python3 -m venv "$venv" || return 1
  "$venv/bin/pip" install -q --upgrade pip phonenumbers >/dev/null 2>&1 || return 1
  "$venv/bin/python" -c 'import phonenumbers' || return 1
  ns_info "ns-canada ready (phone analysis via libphonenumber)"
}
