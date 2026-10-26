# shellcheck shell=bash
# countries — the 'ns-country' search menus. The country packs themselves are
# installed by core and their bookmark folders by the browsers module; this
# module sets up phone-number analysis (libphonenumber) in a private venv.

ns_register countries "Country search menus (phone analysis for every country)" "linux macos" mod_countries

mod_countries() {
  local venv="$NS_VENVS/core"
  mkdir -p "$NS_VENVS"
  [ -x "$venv/bin/python" ] || python3 -m venv "$venv" || return 1
  "$venv/bin/pip" install -q --upgrade pip phonenumbers >/dev/null 2>&1 || return 1
  "$venv/bin/python" -c 'import phonenumbers' || return 1
  ns_info "ns-country ready: $(python3 "$NS_REPO/lib/ns_country.py" list | wc -l | tr -d ' ') country packs"
}
