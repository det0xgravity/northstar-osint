# shellcheck shell=bash
# desktop — application-menu launchers for every northstar menu (Linux), GNOME
# dock favourites, and a Northstar.app launcher on macOS.

ns_register desktop "Menu launchers (app menu, GNOME dock, macOS app)" "linux macos" mod_desktop

# id | name | icon | description
NS_LAUNCHERS="northstar|Northstar|system-search|All northstar OSINT menus
ns-username|Username & Email|avatar-default|Find accounts by username or email
ns-domain|Domain Recon|network-workgroup|Subdomains, DNS, crawling, archives, lookalikes
ns-media|Media Download|video-x-generic|Collect video, images, galleries and streams
ns-archive|Capture Web Pages|document-save|Evidence-grade page captures: single-file copy, screenshot, headers, Wayback
ns-video|Video Verification|video-x-generic|Keyframes for reverse search, offline transcript and translation
ns-metadata|Metadata|document-properties|View, export and strip file metadata
ns-image|Image Analysis|image-x-generic|Reverse image search and EXIF/GPS
ns-country|Country Search|applications-internet|Public-records searches for Canada, the US, UK, Europe, Asia-Pacific and more
ns-breach|Breach Data|dialog-password|Breach and infostealer exposure for emails, usernames, domains and phones
ns-darkweb|Dark Web|network-vpn|Tor connection check, onion search, text-only page capture, ransomware leak-site claims
ns-evidence|Evidence & Exhibits|security-high|Record exhibits, verify folders and the audit log, export the case"

ns_linux_launchers() {
  local apps="$HOME/.local/share/applications" id name icon desc
  mkdir -p "$apps"
  rm -f "$apps/ns-canada.desktop"     # replaced by ns-country in v0.4
  while IFS='|' read -r id name icon desc; do
    [ -n "$id" ] || continue
    cat > "$apps/$id.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Comment=$desc
Exec=$NS_BIN/$id
Icon=$icon
Terminal=true
Categories=Network;Utility;
Keywords=osint;northstar;investigation;
EOF
  done <<EOF
$NS_LAUNCHERS
EOF
  ns_has update-desktop-database && update-desktop-database "$apps" >/dev/null 2>&1
  ns_info "Launchers written to $apps"
}

ns_gnome_dock() {
  ns_in_gnome_session || { ns_info "Not in a GNOME session — dock favourites skipped"; return 0; }
  python3 - <<'PY'
import ast, subprocess
raw = subprocess.check_output(["gsettings", "get", "org.gnome.shell", "favorite-apps"], text=True)
favs = ast.literal_eval(raw.replace("@as ", "").strip())
favs = [f for f in favs if f != "ns-canada.desktop"]   # replaced by ns-country
for app in ["northstar.desktop", "ns-username.desktop", "ns-domain.desktop", "ns-media.desktop",
            "ns-metadata.desktop", "ns-image.desktop", "ns-country.desktop",
            "ns-breach.desktop", "ns-darkweb.desktop", "ns-evidence.desktop"]:
    if app not in favs:
        favs.append(app)
subprocess.check_call(["gsettings", "set", "org.gnome.shell", "favorite-apps", str(favs)])
PY
}

# GNOME opens the Activities overview at every login, from its top-left hot
# corner, and on a lone Super key press. In a VM the pointer crosses that
# corner on its way to the host's toolbar, and the host's Cmd/Windows key
# reaches the guest as Super whenever you switch apps. Skip the login overview
# (Debian's packaged "No overview at start-up" extension) and, in VMs only,
# turn off the hot corner and the Super-key trigger. Also in VMs, use a single
# fixed workspace: with GNOME's dynamic workspaces, a search that reuses a
# browser window on the other workspace makes the whole screen slide there.
# ns_gnome_extension <uuid> <apt-package> <message>
# Installs a packaged GNOME Shell extension if needed and enables it (from the
# next login). Non-fatal: not every distribution packages every extension.
ns_gnome_extension() {
  local uuid="$1" pkg="$2" msg="$3"
  [ -d "/usr/share/gnome-shell/extensions/$uuid" ] || ns_apt "$pkg" >/dev/null 2>&1
  [ -d "/usr/share/gnome-shell/extensions/$uuid" ] || { ns_info "$pkg isn't available here — skipped"; return 0; }
  python3 - "$uuid" <<'PY'
import ast, subprocess, sys
key = ["org.gnome.shell", "enabled-extensions"]
raw = subprocess.check_output(["gsettings", "get"] + key, text=True)
exts = ast.literal_eval(raw.replace("@as ", "").strip())
if sys.argv[1] not in exts:
    subprocess.check_call(["gsettings", "set"] + key + [str(exts + [sys.argv[1]])])
PY
  ns_info "$msg"
}

ns_gnome_tweaks() {
  ns_in_gnome_session || return 0
  local virt=""
  ns_gnome_extension no-overview@fthx gnome-shell-extensions-extra \
    "Login no longer opens the Activities overview (from your next login)"
  # GNOME has no system tray; Flameshot and KeePassXC live there
  ns_gnome_extension ubuntu-appindicators@ubuntu.com gnome-shell-extension-appindicator \
    "Tray icons enabled for Flameshot and KeePassXC (from your next login)"
  # 24-hour clock, matching the prompt and the timestamps in audit.log
  gsettings set org.gnome.desktop.interface clock-format 24h \
    && ns_info "Top-bar clock set to 24-hour"
  ns_has systemd-detect-virt && virt=$(systemd-detect-virt --vm 2>/dev/null)
  if [ -n "$virt" ] && [ "$virt" != none ]; then
    gsettings set org.gnome.desktop.interface enable-hot-corners false \
      && ns_info "Top-left hot corner off (VM) — re-enable in Settings → Multitasking"
    gsettings set org.gnome.mutter overlay-key '' \
      && ns_info "Super/Cmd key alone no longer opens the overview (VM) — undo: gsettings reset org.gnome.mutter overlay-key"
    gsettings set org.gnome.mutter dynamic-workspaces false \
      && gsettings set org.gnome.desktop.wm.preferences num-workspaces 1 \
      && ns_info "One fixed workspace (VM) — undo: gsettings reset org.gnome.mutter dynamic-workspaces"
  fi
}

# Desktop background: northstar's own (assets/wallpaper), but only replacing the
# distribution's default, never a background the user chose. Linux only.
ns_wallpaper() {
  local img="$NS_HOME/share/wallpaper/northstar.png" uri cur prop n=0
  mkdir -p "$(dirname "$img")"
  install -m 644 "$NS_REPO/assets/wallpaper/northstar.png" "$img" || return 1
  uri="file://$img"
  if ns_in_gnome_session; then
    cur=$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null)
    case "$cur" in
      *"/usr/share/"*|"''"|*"$img"*)
        gsettings set org.gnome.desktop.background picture-uri "$uri"
        gsettings set org.gnome.desktop.background picture-uri-dark "$uri"
        gsettings set org.gnome.desktop.background picture-options zoom
        ns_info "Desktop background set to the northstar wallpaper" ;;
      *) ns_info "Keeping your own desktop background (northstar's is in $img)" ;;
    esac
  elif [ "$NS_DE" = xfce ] && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && ns_has xfconf-query; then
    for prop in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep '/last-image$'); do
      cur=$(xfconf-query -c xfce4-desktop -p "$prop" 2>/dev/null)
      case "$cur" in
        ""|/usr/share/*|"$img")
          xfconf-query -c xfce4-desktop -p "$prop" -s "$img" && n=$((n+1)) ;;
      esac
    done
    if [ $n -gt 0 ]; then ns_info "Desktop background set to the northstar wallpaper"
    else ns_info "Desktop background unchanged (northstar's is in $img)"; fi
  fi
  return 0
}

ns_macos_app() {
  local app="$HOME/Applications/Northstar.app"
  mkdir -p "$HOME/Applications"
  rm -rf "$app"
  osacompile -o "$app" \
    -e 'tell application "Terminal"' \
    -e "  do script \"'$NS_BIN/northstar'; exit\"" \
    -e '  activate' \
    -e 'end tell' || return 1
  ns_info "Northstar.app created in ~/Applications (find it with Spotlight)"
}

mod_desktop() {
  if ns_is_macos; then
    ns_macos_app
  else
    ns_linux_launchers || return 1
    ns_gnome_dock
    ns_gnome_tweaks
    ns_wallpaper
  fi
}
