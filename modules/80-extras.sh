# shellcheck shell=bash
# extras — KeePassXC (persona credentials), Flameshot (annotated screenshots),
# OBS Studio (screen recording).

tb_register extras "KeePassXC, Flameshot, OBS Studio" "linux macos" mod_extras

tb_flameshot_printkey() {
  tb_in_gnome_session || return 0
  local schema="org.gnome.settings-daemon.plugins.media-keys"
  local kpath="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/truebearing-flameshot/"
  local cur new
  cur=$(gsettings get "$schema" custom-keybindings) || return 1
  case "$cur" in
    *"$kpath"*) : ;;
    "@as []"|"[]") new="['$kpath']" ;;
    *) new="${cur%]}, '$kpath']" ;;
  esac
  [ -n "${new:-}" ] && { gsettings set "$schema" custom-keybindings "$new" || return 1; }
  gsettings set "$schema.custom-keybinding:$kpath" name    'Flameshot' &&
  gsettings set "$schema.custom-keybinding:$kpath" command 'flameshot gui' &&
  gsettings set "$schema.custom-keybinding:$kpath" binding 'Print' &&
  gsettings set org.gnome.shell.keybindings show-screenshot-ui "[]" &&
  tb_info "Print Screen now opens Flameshot"
}

# Flameshot runs in standby as a tray icon (GNOME's tray comes from the
# AppIndicator extension enabled by the desktop module). Start it at login so
# it's always ready; Print Screen opens the capture directly.
tb_flameshot_tray() {
  local apps="$HOME/.local/share/applications" auto="$HOME/.config/autostart"
  tb_has flameshot || return 0
  # v0.6.1 overrode the app-list entry to capture immediately; restore the
  # standard one, which starts Flameshot in the tray
  grep -qE 'northstar|truebearing' "$apps/org.flameshot.Flameshot.desktop" 2>/dev/null \
    && rm -f "$apps/org.flameshot.Flameshot.desktop"
  mkdir -p "$auto"
  cat > "$auto/org.flameshot.Flameshot.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Flameshot
Comment=Screenshot tool in the tray (started at login by truebearing-osint)
Exec=flameshot
Icon=org.flameshot.Flameshot
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
  tb_info "Flameshot starts in the tray at login (Print Screen captures; remove ~/.config/autostart/org.flameshot.Flameshot.desktop to stop)"
}

mod_extras() {
  local rc=0
  if tb_is_macos; then
    tb_cask keepassxc flameshot obs || rc=1
  else
    tb_apt keepassxc flameshot || rc=1
    if [ "$TB_ARCH" = "arm64" ]; then
      tb_apt obs-studio || rc=1               # Flathub builds OBS for x86_64 only
    else
      tb_flatpak com.obsproject.Studio || rc=1
    fi
    tb_flameshot_tray
    tb_flameshot_printkey || rc=1
  fi
  return $rc
}
