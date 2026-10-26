# shellcheck shell=bash
# frameworks — larger multi-source frameworks. Heavier installs; skip with
# --skip frameworks if you don't need them.

ns_register frameworks "Frameworks (SpiderFoot, recon-ng, changedetection.io)" "linux macos" mod_frameworks

mod_frameworks() {
  local rc=0
  # SpiderFoot's last release (2023) caps lxml, cryptography and others below
  # versions that support Python 3.12+. Lift the caps, except secure<0.4: the
  # web UI breaks with secure 1.x. "cd": it loads its web templates from the
  # current directory.
  ns_git_venv spiderfoot https://github.com/smicallef/spiderfoot sf.py requirements.txt cd \
    '/^secure/!s/,<[^[:space:]]+//' || rc=1
  ns_git_venv recon-ng   https://github.com/lanmaster53/recon-ng  recon-ng REQUIREMENTS || rc=1
  ns_pipx changedetection.io || rc=1
  ns_pipx sth search-that-hash || rc=1
  ns_pipx nth name-that-hash   || rc=1
  return $rc
}
