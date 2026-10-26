# shellcheck shell=bash
# extras — KeePassXC (persona credentials), Flameshot (annotated screenshots),
# OBS Studio (screen recording).

ns_register extras "KeePassXC, Flameshot, OBS Studio" "linux macos" mod_extras

ns_flameshot_printkey() {
  ns_in_gnome_session || return 0
  local schema="org.gnome.settings-daemon.plugins.media-keys"
  local kpath="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/northstar-flameshot/"
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
  ns_info "Print Screen now opens Flameshot"
}

# Clicking Flameshot in the app list only starts it in the background (a tray
# icon), which looks like nothing happened. A same-named entry in the user's
# applications folder overrides the system one: clicking now takes a screenshot.
ns_flameshot_launcher() {
  local apps="$HOME/.local/share/applications"
  ns_has flameshot || return 0
  mkdir -p "$apps"
  cat > "$apps/org.flameshot.Flameshot.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Flameshot
GenericName=Screenshot tool
Comment=Take an annotated screenshot (northstar: opens the capture straight away)
Exec=flameshot gui
Icon=org.flameshot.Flameshot
Terminal=false
Categories=Graphics;Utility;
Keywords=screenshot;screen;capture;
Actions=Launcher;Config;

[Desktop Action Launcher]
Name=Open the capture launcher (delay, full screen)
Exec=flameshot launcher

[Desktop Action Config]
Name=Settings
Exec=flameshot config
EOF
  ns_info "Flameshot in the app list now takes a screenshot straight away"
}

mod_extras() {
  local rc=0
  if ns_is_macos; then
    ns_cask keepassxc flameshot obs || rc=1
  else
    ns_apt keepassxc flameshot || rc=1
    if [ "$NS_ARCH" = "arm64" ]; then
      ns_apt obs-studio || rc=1               # Flathub builds OBS for x86_64 only
    else
      ns_flatpak com.obsproject.Studio || rc=1
    fi
    ns_flameshot_launcher
    ns_flameshot_printkey || rc=1
  fi
  return $rc
}
