# shellcheck shell=bash
# messaging — Telegram Desktop and end-to-end encrypted messengers (Signal,
# Element for Matrix) for research accounts and viewing shared content. Each
# comes from its publisher's own repository or a verified Flathub listing.

tb_register messaging "Messaging apps: Telegram Desktop, Signal, Element (Matrix)" "linux macos" mod_messaging

tb_signal_repo() {
  [ -f /etc/apt/sources.list.d/signal-desktop.list ] && return 0
  tb_apt gnupg >/dev/null || return 1
  curl -fsSL https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor \
    | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg >/dev/null || return 1
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" \
    | sudo tee /etc/apt/sources.list.d/signal-desktop.list >/dev/null
  # shellcheck disable=SC2034  # read by tb_apt_update in lib/common.sh
  TB_APT_UPDATED=0
}

tb_element_repo() {
  [ -f /etc/apt/sources.list.d/element-io.list ] && return 0
  sudo curl -fsSLo /usr/share/keyrings/element-io-archive-keyring.gpg \
    https://packages.element.io/debian/element-io-archive-keyring.gpg || return 1
  echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] https://packages.element.io/debian/ default main" \
    | sudo tee /etc/apt/sources.list.d/element-io.list >/dev/null
  # shellcheck disable=SC2034
  TB_APT_UPDATED=0
}

mod_messaging() {
  local rc=0
  if tb_is_macos; then
    tb_cask telegram signal element || rc=1
    return $rc
  fi
  # Telegram Desktop: Flathub's listing is verified by Telegram, x86_64 and arm64
  tb_flatpak org.telegram.desktop || rc=1
  # Signal publishes Linux builds for x86_64 only (arm64 is an unofficial beta)
  if [ "$TB_ARCH" = "amd64" ]; then
    tb_has signal-desktop || { tb_signal_repo && tb_apt signal-desktop; } || rc=1
  else
    tb_info "Skipping Signal: no official arm64 Linux build yet (use Signal on a phone, or an x86_64 machine)"
  fi
  tb_has element-desktop || { tb_element_repo && tb_apt element-desktop; } || rc=1
  tb_info "Use research accounts in these apps, never personal ones; tb-seal clears their data from templates"
  return $rc
}
