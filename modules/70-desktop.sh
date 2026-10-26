# shellcheck shell=bash
# desktop — application-menu launchers for every northstar menu (Linux), GNOME
# dock favourites, and a Northstar.app launcher on macOS.

ns_register desktop "Menu launchers (app menu, GNOME dock, macOS app)" "linux macos" mod_desktop

# id | name | icon | description
NS_LAUNCHERS="northstar|Northstar|system-search|All northstar OSINT menus
ns-username|Username & Email|avatar-default|Find accounts by username or email
ns-domain|Domain Recon|network-workgroup|Subdomains, DNS, crawling, archives, lookalikes
ns-media|Media Download|video-x-generic|Collect video, images, galleries and streams
ns-metadata|Metadata|document-properties|View, export and strip file metadata
ns-image|Image Analysis|image-x-generic|Reverse image search and EXIF/GPS
ns-country|Country Search|applications-internet|Public-records searches for Canada, the US, UK, Europe, Asia-Pacific and more"

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
            "ns-metadata.desktop", "ns-image.desktop", "ns-country.desktop"]:
    if app not in favs:
        favs.append(app)
subprocess.check_call(["gsettings", "set", "org.gnome.shell", "favorite-apps", str(favs)])
PY
}

# GNOME opens the Activities overview at every login, and its top-left hot
# corner reopens it whenever the pointer brushes that corner, which in a VM
# window happens on the way to the host's toolbar. Skip the login overview
# (Debian's packaged "No overview at start-up" extension) and, in VMs only,
# turn the hot corner off.
ns_gnome_tweaks() {
  ns_in_gnome_session || return 0
  local ext="no-overview@fthx" virt=""
  if [ ! -d "/usr/share/gnome-shell/extensions/$ext" ]; then
    ns_apt gnome-shell-extensions-extra >/dev/null 2>&1 \
      || ns_info "No-overview extension not packaged here — GNOME will still open the overview at login"
  fi
  if [ -d "/usr/share/gnome-shell/extensions/$ext" ]; then
    python3 - "$ext" <<'PY'
import ast, subprocess, sys
key = ["org.gnome.shell", "enabled-extensions"]
raw = subprocess.check_output(["gsettings", "get"] + key, text=True)
exts = ast.literal_eval(raw.replace("@as ", "").strip())
if sys.argv[1] not in exts:
    subprocess.check_call(["gsettings", "set"] + key + [str(exts + [sys.argv[1]])])
PY
    ns_info "Login no longer opens the Activities overview (from your next login)"
  fi
  ns_has systemd-detect-virt && virt=$(systemd-detect-virt --vm 2>/dev/null)
  if [ -n "$virt" ] && [ "$virt" != none ]; then
    gsettings set org.gnome.desktop.interface enable-hot-corners false \
      && ns_info "Top-left hot corner off (VM) — re-enable in Settings → Multitasking"
  fi
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
  fi
}
