# shellcheck shell=bash
# triage — tools for checking received or suspicious files without opening
# them (Evidence → Check received or suspicious files, and after an OnionShare
# drop box closes): ClamAV for known malware, with its signatures kept up to
# date, and oletools for Office macros. The checks themselves are tb_triage.

tb_register triage "File triage: ClamAV and oletools, for received or suspicious files" "linux macos" mod_triage

mod_triage() {
  local rc=0 conf
  tb_pipx olevba oletools || rc=1
  if tb_is_macos; then
    tb_brew clamav || return 1
    conf="$(brew --prefix)/etc/clamav/freshclam.conf"
    [ -f "$conf" ] || sed '/^Example/d' "$conf.sample" > "$conf" 2>/dev/null
    tb_bg "${TB_LOG:-/dev/null}" "ClamAV signatures" freshclam || tb_warn "ClamAV signatures didn't download; run freshclam later"
  else
    tb_apt clamav clamav-freshclam || return 1
    if [ -d /run/systemd/system ]; then
      # The freshclam service keeps the signatures current (about 200 MB the first time)
      sudo systemctl enable --now clamav-freshclam >/dev/null 2>&1 || { tb_warn "Couldn't start clamav-freshclam"; rc=1; }
      tb_info "ClamAV signatures download in the background (about 200 MB); scans work once they're in"
    else
      tb_info "No systemd here: get ClamAV's signatures with 'sudo freshclam'"
    fi
  fi
  return $rc
}
