# shellcheck shell=bash
# username — account discovery by username and email.

ns_register username "Username & email discovery (sherlock, maigret, holehe…)" "linux macos" mod_username

mod_username() {
  local rc=0
  ns_pipx sherlock    sherlock-project || rc=1
  ns_pipx maigret                      || rc=1
  ns_pipx socialscan                   || rc=1
  ns_pipx holehe                       || rc=1
  ns_pipx ghunt                        || rc=1
  ns_pipx toutatis                     || rc=1
  ns_git_venv blackbird https://github.com/antoniaci/blackbird blackbird.py requirements.txt cd || rc=1
  # Retired: unmaintained since 2022 (ns-breach covers breach lookups now)
  [ -x "$HOME/.local/bin/h8mail" ] && pipx uninstall h8mail >/dev/null 2>&1
  return $rc
}
