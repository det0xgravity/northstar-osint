# shellcheck shell=bash
# username — account discovery by username and email.

tb_register username "Username & email discovery (sherlock, maigret, holehe…)" "linux macos" mod_username

mod_username() {
  local rc=0
  tb_pipx sherlock    sherlock-project || rc=1
  tb_pipx maigret                      || rc=1
  tb_pipx socialscan                   || rc=1
  tb_pipx holehe                       || rc=1
  # GHunt's last release (2.3.4) caps Pillow below 11, which has no wheels for
  # Python 3.14 (Ubuntu 26.04), so pip tries to compile Pillow and fails. GHunt's
  # main branch moved to Pillow 12: use it on 3.14+, the release elsewhere.
  if python3 -c 'import sys; sys.exit(sys.version_info < (3, 14))'; then
    tb_pipx ghunt "git+https://github.com/mxrch/GHunt.git" || rc=1
  else
    tb_pipx ghunt || rc=1
  fi
  tb_pipx toutatis                     || rc=1
  tb_git_venv blackbird https://github.com/antoniaci/blackbird blackbird.py requirements.txt cd || rc=1
  # Retired: unmaintained since 2022 (tb-breach covers breach lookups now)
  [ -x "$HOME/.local/bin/h8mail" ] && pipx uninstall h8mail >/dev/null 2>&1
  return $rc
}
