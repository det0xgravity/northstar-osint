# shellcheck shell=bash
# desktop — application-menu launchers for every True Bearing menu (Linux), GNOME
# dock favourites, a TrueBearing.app launcher on macOS, and the user guides as
# offline web pages, linked on the desktop.

tb_register desktop "Menu launchers (app menu, GNOME dock, macOS app) and the guides on the desktop" "linux macos" mod_desktop

# id | name | icon | description
TB_LAUNCHERS="truebearing|True Bearing|system-search|All True Bearing OSINT menus
tb-missing|Missing Person|system-users|Subject profile, timeline from last seen, findings (CTF flags) with evidence
tb-username|Username & Email|avatar-default|Find accounts by username or email
tb-telegram|Telegram|internet-chat|Collect public Telegram channels: posts, metadata, forward networks
tb-domain|Domain Recon|network-workgroup|Subdomains, DNS, crawling, archives, lookalikes
tb-media|Media Download|video-x-generic|Collect video, images, galleries and streams
tb-archive|Capture Web Pages|document-save|Evidence-grade page captures: single-file copy, screenshot, headers, Wayback
tb-video|Video Verification|video-x-generic|Keyframes for reverse search, offline transcript and translation
tb-geo|Photo Geolocation|find-location|Where was this photo taken? Clues, local AI estimate, shadows, OSM search
tb-watch|Page Monitoring|appointment-new|Watch public pages for changes: proof of life, new posts, snapshots and diffs
tb-map|Case Map|find-location|Every coordinate in the case on one map, with GeoJSON and KML exports
tb-translate|Translate|accessories-dictionary|Offline text translation: posts, transcripts, subtitles, captures
tb-face|Face Comparison|avatar-default|Compare a reference face with photos already in the case (local, safeguarded)
tb-metadata|Metadata|document-properties|View, export and strip file metadata
tb-image|Image Analysis|image-x-generic|Reverse image search and EXIF/GPS
tb-country|Country Search|applications-internet|Public-records searches for Canada, the US, UK, Europe, Asia-Pacific and more
tb-breach|Breach Data|dialog-password|Breach and infostealer exposure for emails, usernames, domains and phones
tb-darkweb|Dark Web|network-vpn|Tor connection check, onion search, text-only page capture, ransomware leak-site claims
tb-notes|Notes|accessories-text-editor|Case notes in Obsidian: people, accounts, organisations, places, events, leads
tb-case|Case|x-office-document|Open a case with intake details, take notes, build the report, close the case
tb-evidence|Evidence & Exhibits|security-high|Record exhibits, verify folders and the audit log, export the case
tb-guides|Guides|help-browser|The investigation guide and manuals, offline in your browser"

tb_linux_launchers() {
  local apps="$HOME/.local/share/applications" id name icon desc
  mkdir -p "$apps"
  # Launchers from before the rename to True Bearing (v0.41)
  rm -f "$apps/northstar.desktop" "$apps"/ns-*.desktop
  while IFS='|' read -r id name icon desc; do
    [ -n "$id" ] || continue
    cat > "$apps/$id.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Comment=$desc
Exec=$TB_BIN/$id
Icon=$icon
Terminal=true
Categories=Network;Utility;
Keywords=osint;truebearing;investigation;
EOF
  done <<EOF
$TB_LAUNCHERS
EOF
  tb_has update-desktop-database && update-desktop-database "$apps" >/dev/null 2>&1
  tb_info "Launchers written to $apps"
}

tb_gnome_dock() {
  tb_in_gnome_session || { tb_info "Not in a GNOME session — dock favourites skipped"; return 0; }
  python3 - <<'PY'
import ast, subprocess
raw = subprocess.check_output(["gsettings", "get", "org.gnome.shell", "favorite-apps"], text=True)
favs = ast.literal_eval(raw.replace("@as ", "").strip())
# Favourites from before the rename to True Bearing (v0.41) keep their place
favs = ["truebearing.desktop" if f == "northstar.desktop" else "tb-" + f[3:] if f.startswith("ns-") else f
        for f in favs if f != "ns-canada.desktop"]
favs = list(dict.fromkeys(favs))
for app in ["truebearing.desktop", "tb-username.desktop", "tb-domain.desktop", "tb-media.desktop",
            "tb-metadata.desktop", "tb-image.desktop", "tb-country.desktop",
            "tb-breach.desktop", "tb-darkweb.desktop", "tb-evidence.desktop"]:
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
# tb_gnome_extension <uuid> <apt-package> <message>
# Installs a packaged GNOME Shell extension if needed and enables it (from the
# next login). Non-fatal: not every distribution packages every extension.
tb_gnome_extension() {
  local uuid="$1" pkg="$2" msg="$3"
  # Only ask apt for packages this distribution has (Ubuntu lacks some), so the log stays clean
  [ -d "/usr/share/gnome-shell/extensions/$uuid" ] || ! apt-cache show "$pkg" >/dev/null 2>&1 || tb_apt "$pkg" >/dev/null 2>&1
  [ -d "/usr/share/gnome-shell/extensions/$uuid" ] || { tb_info "$pkg isn't available here — skipped"; return 0; }
  python3 - "$uuid" <<'PY'
import ast, subprocess, sys
key = ["org.gnome.shell", "enabled-extensions"]
raw = subprocess.check_output(["gsettings", "get"] + key, text=True)
exts = ast.literal_eval(raw.replace("@as ", "").strip())
if sys.argv[1] not in exts:
    subprocess.check_call(["gsettings", "set"] + key + [str(exts + [sys.argv[1]])])
PY
  tb_info "$msg"
}

tb_gnome_tweaks() {
  tb_in_gnome_session || return 0
  local virt=""
  tb_gnome_extension no-overview@fthx gnome-shell-extensions-extra \
    "Login no longer opens the Activities overview (from your next login)"
  # GNOME has no system tray; Flameshot and KeePassXC live there
  tb_gnome_extension ubuntu-appindicators@ubuntu.com gnome-shell-extension-appindicator \
    "Tray icons enabled for Flameshot and KeePassXC (from your next login)"
  # 24-hour clock, matching the prompt and the timestamps in audit.log
  gsettings set org.gnome.desktop.interface clock-format 24h \
    && tb_info "Top-bar clock set to 24-hour"
  tb_has systemd-detect-virt && virt=$(systemd-detect-virt --vm 2>/dev/null)
  if [ -n "$virt" ] && [ "$virt" != none ]; then
    gsettings set org.gnome.desktop.interface enable-hot-corners false \
      && tb_info "Top-left hot corner off (VM) — re-enable in Settings → Multitasking"
    gsettings set org.gnome.mutter overlay-key '' \
      && tb_info "Super/Cmd key alone no longer opens the overview (VM) — undo: gsettings reset org.gnome.mutter overlay-key"
    gsettings set org.gnome.mutter dynamic-workspaces false \
      && gsettings set org.gnome.desktop.wm.preferences num-workspaces 1 \
      && tb_info "One fixed workspace (VM) — undo: gsettings reset org.gnome.mutter dynamic-workspaces"
  fi
}

# Desktop background: True Bearing's own (assets/wallpaper), but only replacing the
# distribution's default, never a background the user chose. Linux only.
tb_wallpaper() {
  local img="$TB_HOME/share/wallpaper/truebearing.png" uri cur prop n=0
  mkdir -p "$(dirname "$img")"
  install -m 644 "$TB_REPO/assets/wallpaper/truebearing.png" "$img" || return 1
  rm -f "$TB_HOME/share/wallpaper/northstar.png"
  uri="file://$img"
  if tb_in_gnome_session; then
    cur=$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null)
    case "$cur" in
      # (the northstar wallpaper from before v0.41 counts as ours)
      *"/usr/share/"*|"''"|*"$img"*|*"/northstar/share/wallpaper/northstar.png"*)
        gsettings set org.gnome.desktop.background picture-uri "$uri"
        gsettings set org.gnome.desktop.background picture-uri-dark "$uri"
        gsettings set org.gnome.desktop.background picture-options zoom
        tb_info "Desktop background set to the True Bearing wallpaper" ;;
      *) tb_info "Keeping your own desktop background (True Bearing's is in $img)" ;;
    esac
  elif [ "$TB_DE" = xfce ] && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && tb_has xfconf-query; then
    for prop in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep '/last-image$'); do
      cur=$(xfconf-query -c xfce4-desktop -p "$prop" 2>/dev/null)
      case "$cur" in
        ""|/usr/share/*|"$img"|*/northstar/share/wallpaper/northstar.png)
          xfconf-query -c xfce4-desktop -p "$prop" -s "$img" && n=$((n+1)) ;;
      esac
    done
    if [ $n -gt 0 ]; then tb_info "Desktop background set to the True Bearing wallpaper"
    else tb_info "Desktop background unchanged (True Bearing's is in $img)"; fi
  fi
  return 0
}

tb_macos_app() {
  local app="$HOME/Applications/TrueBearing.app"
  mkdir -p "$HOME/Applications"
  rm -rf "$app" "$HOME/Applications/Northstar.app"      # the name before v0.41
  osacompile -o "$app" \
    -e 'tell application "Terminal"' \
    -e "  do script \"'$TB_BIN/truebearing'; exit\"" \
    -e '  activate' \
    -e 'end tell' || return 1
  tb_info "TrueBearing.app created in ~/Applications (find it with Spotlight)"
}

# The guides (docs/*.md) as offline web pages in $TB_DATA/Guides, rebuilt on
# every update, with links on the desktop: "True Bearing guides" (the folder) and
# the investigation guide itself. GNOME shows desktop icons only with the
# Desktop Icons NG extension, which is enabled here.
tb_desktop_dir() {
  local d=""
  tb_has xdg-user-dir && d=$(xdg-user-dir DESKTOP 2>/dev/null)
  [ -n "$d" ] && [ "$d" != "$HOME" ] || d="$HOME/Desktop"
  printf '%s\n' "$d"
}

tb_guides() {
  # Not under a hidden folder: the Firefox snap (Ubuntu) can't open files there
  local out="$TB_DATA/Guides" desk
  rm -rf "$TB_HOME/guides"                      # where they were before v0.37
  python3 "$TB_REPO/lib/tb_guides.py" build "$TB_REPO/docs" "$out" || { tb_warn "The guides couldn't be rendered (is pandoc installed?)"; return 1; }
  desk=$(tb_desktop_dir)
  mkdir -p "$desk"
  # Links from before the rename to True Bearing (v0.41)
  [ -L "$desk/Northstar guides" ] && rm -f "$desk/Northstar guides"
  [ -L "$desk/Northstar investigation guide.html" ] && rm -f "$desk/Northstar investigation guide.html"
  # links only: never replace a file or folder of yours with the same name
  [ -e "$desk/True Bearing guides" ] && [ ! -L "$desk/True Bearing guides" ] || ln -sfn "$out" "$desk/True Bearing guides"
  [ -e "$desk/True Bearing investigation guide.html" ] && [ ! -L "$desk/True Bearing investigation guide.html" ] \
    || ln -sfn "$out/INVESTIGATION-GUIDE.html" "$desk/True Bearing investigation guide.html"
  if tb_in_gnome_session; then
    tb_gnome_extension ding@rastersoft.com gnome-shell-extension-desktop-icons-ng \
      "Desktop icons enabled, for the guides (from your next login)"
  fi
  tb_info "Guides on the desktop ($desk), and under Guides in the main menu"
}

mod_desktop() {
  local rc=0
  if tb_is_macos; then
    tb_macos_app
  else
    tb_linux_launchers || return 1
    tb_gnome_dock
    tb_gnome_tweaks
    tb_wallpaper
  fi
  tb_guides || rc=1
  return $rc
}
