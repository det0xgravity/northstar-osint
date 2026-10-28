# shellcheck shell=bash
# countries — the 'tb-country' search menus. The country packs themselves are
# installed by core and their bookmark folders by the browsers module; this
# module sets up phone-number analysis (libphonenumber) in a private venv.

tb_register countries "Country search menus (phone analysis for every country)" "linux macos" mod_countries

mod_countries() {
  local venv="$TB_VENVS/core"
  mkdir -p "$TB_VENVS"
  [ -x "$venv/bin/python" ] || python3 -m venv "$venv" || return 1
  tb_pip /dev/null "phonenumbers" "$venv/bin/pip" install --upgrade pip phonenumbers || return 1
  "$venv/bin/python" -c 'import phonenumbers' || return 1
  tb_info "tb-country ready: $(python3 "$TB_REPO/lib/tb_country.py" list | wc -l | tr -d ' ') country packs"
}
