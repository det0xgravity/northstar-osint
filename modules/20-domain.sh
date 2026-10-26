# shellcheck shell=bash
# domain — domain, DNS and web infrastructure reconnaissance.

ns_register domain "Domain & infrastructure recon (subfinder, httpx, amass…)" "linux macos" mod_domain

mod_domain() {
  local rc=0

  # Headless Chromium for gowitness screenshots
  case "$NS_PLATFORM" in
    ubuntu) ns_apt chromium-browser || rc=1 ;;
    macos)  : ;;  # gowitness uses Google Chrome if present — see docs/INSTALL.md
    *)      ns_apt chromium || rc=1 ;;
  esac

  if ns_has go; then
    ns_go github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest || rc=1
    ns_go github.com/projectdiscovery/dnsx/cmd/dnsx@latest             || rc=1
    ns_go github.com/projectdiscovery/httpx/cmd/httpx@latest           || rc=1
    ns_go github.com/projectdiscovery/katana/cmd/katana@latest         || rc=1
    ns_go github.com/sensepost/gowitness@latest                        || rc=1
  else
    rc=1
  fi

  if ns_is_macos; then
    ns_brew amass || rc=1
  else
    ns_gh_release owasp-amass/amass amass "linux.*${NS_ARCH}.*(tar\\.gz|zip)$" || rc=1
  fi

  # theHarvester's main branch needs Python 3.14+. 4.11.1 is the last release
  # for 3.12-3.13 (Debian 13, Ubuntu 24.04, Kali). It isn't on PyPI.
  local harv_ref=""
  python3 -c 'import sys; sys.exit(sys.version_info < (3, 14))' || harv_ref="@4.11.1"
  ns_pipx theHarvester "git+https://github.com/laramies/theHarvester.git$harv_ref" || rc=1
  ns_pipx waymore      git+https://github.com/xnl-h4ck3r/waymore.git    || rc=1
  ns_pipx dnstwist     "dnstwist[full]"                                 || rc=1
  ns_pipx shodan                                                        || rc=1
  ns_pipx censys                                                        || rc=1
  return $rc
}
