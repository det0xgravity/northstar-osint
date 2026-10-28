#!/usr/bin/env bash
# tests/e2e.sh — end-to-end checks against a real installation: the installed
# menus and engines run with the real tools on generated data, in a throwaway
# data folder. Network use is small (a few public pages and model downloads).
# Usage, after ./install.sh:  bash tests/e2e.sh [INSTALL_LOG]
# Checks for modules that aren't installed are reported as skipped.

R="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="${1:-$HOME/.config/northstar/install.log}"
NS_HOME="${NS_HOME:-$HOME/.local/share/northstar}"
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
PASS=0; FAIL=0; SKIP=0

ok()    { PASS=$((PASS+1)); printf '  ok    %s\n' "$1"; }
bad()   { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; [ -n "${2:-}" ] && printf '        %s\n' "$2"; }
skip()  { SKIP=$((SKIP+1)); printf '  skip  %s (%s)\n' "$1" "$2"; }
check() { if eval "$2" >> "$W/e2e.log" 2>&1; then ok "$1"; else bad "$1" "$2"; tail -5 "$W/e2e.log" | sed 's/^/        | /'; fi; }
have()  { [ -x "$NS_HOME/bin/$1" ] || command -v "$1" >/dev/null 2>&1; }
section() { printf '\n== %s\n' "$1"; }

# Installed tools, a private data folder and config, scripted dialogs
export PATH="$NS_HOME/bin:$HOME/.local/bin:$PATH"
REAL_DATA="${NS_DATA:-$HOME/Northstar}"     # where the installer put the guides
export NS_HOME NS_DATA="$W/data" XDG_CONFIG_HOME="$W/xdg" NS_UI=script NS_UI_ANSWERS="$W/answers"
mkdir -p "$NS_DATA/Cases" "$XDG_CONFIG_HOME/northstar"
answers() { printf '%s\n' "$@" > "$NS_UI_ANSWERS"; rm -f "$NS_UI_ANSWERS.pos"; }
menu() { local t="$1"; shift; answers "$@"; "$NS_HOME/bin/$t" < /dev/null > "$W/out.txt" 2>&1; }
CASE="$NS_DATA/Cases/general"
PY="$NS_HOME/venvs/images/bin/python"; [ -x "$PY" ] || PY=python3

section "Installation"
if [ -f "$LOG" ]; then
  # NS_E2E_EXPECTED_FAIL: modules that can't work where this runs (e.g. "browsers"
  # in an Ubuntu container: Firefox is a snap there, and snaps need systemd)
  failed=$(tail -n 60 "$LOG" | sed -n 's/^ *- \([a-z]*\):.*/\1/p' | sort -u)
  unexpected=""
  for m in $failed; do
    case ",${NS_E2E_EXPECTED_FAIL:-}," in *",$m,"*) printf '        (expected here: %s)\n' "$m" ;; *) unexpected="$unexpected $m" ;; esac
  done
  check "installer reported no unexpected failed modules${unexpected:+:$unexpected}" "[ -z '$unexpected' ]"
  if [ "$(uname -m)" = aarch64 ] && grep -q 'Tor Browser' "$LOG"; then
    check "arm64 Tor Browser signature verified" "grep -q 'signature-verified' '$LOG'"
  fi
else
  skip "installer summary" "no install log at $LOG"
fi
check "health check runs and writes a report" "ns_doctor '$W/doctor.txt' >/dev/null; grep -q '== Tools' '$W/doctor.txt'"
check "every menu tool is installed" "for t in northstar ns-missing ns-username ns-telegram ns-domain ns-media ns-archive ns-metadata ns-image ns-video ns-geo ns-face ns-watch ns-map ns-translate ns-notes ns-country ns-breach ns-darkweb ns-evidence ns-case ns-keys ns-guides ns-lan; do [ -x '$NS_HOME/bin/'\$t ] || { echo missing \$t; exit 1; }; done"

check "the guides are built and linked on the desktop" "[ -f '$REAL_DATA/Guides/INVESTIGATION-GUIDE.html' ] && ls -d \"\$HOME/Desktop/Northstar guides\" \"\$(xdg-user-dir DESKTOP 2>/dev/null)/Northstar guides\" 2>/dev/null | grep -q ."

section "Case, notes and evidence"
answers "e2e-case" "yes" "REF-1" "CI" "End-to-end test" "Test data only" "2030-01-01"
"$NS_HOME/bin/ns-case" open < /dev/null > "$W/out.txt" 2>&1
CASE="$NS_DATA/Cases/e2e-case"
check "case opened with an intake record" "grep -q 'REF-1' '$CASE/case.json'"
check "Case.md created for Obsidian" "grep -q 'REF-1' '$CASE/Case.md'"
menu ns-notes "New note: account" "@janedoe_test"
check "account note made from the template" "grep -q '^type: account' '$CASE/Accounts/@janedoe_test.md'"
menu ns-case "Add a note" "First contemporaneous note"
check "contemporaneous notes chain intact" "ns_casework notes-verify '$CASE' | grep -q ' 0 BROKEN'"

section "Country search and missing persons"
menu ns-missing "Subject profile" "Jane Doe" "" "1990" "2026-10-01 18:30" "Ottawa" "" "janedoe90" "" "" "" ""
menu ns-missing "Missing-persons" "United States" "<default>" "yes"
check "missing-persons search pre-filled from the profile" "grep -q 'charleyproject.org/?s=Jane+Doe' '$W/out.txt'"
menu ns-country "Canada" "Phone number" "+1 613 555 0123"
check "country search saved its links to the case" "grep -rq 'http' '$CASE'/canada/*/links.txt"

section "Images, metadata and the case map"
mkdir -p "$W/photos"
"$PY" - "$W/photos" <<'PYEOF' >> "$W/e2e.log" 2>&1
import sys, random
from PIL import Image, ImageDraw
random.seed(1)
im = Image.new("RGB", (640, 480), "white"); d = ImageDraw.Draw(im)
for _ in range(40):
    x, y = random.randrange(600), random.randrange(440)
    d.rectangle([x, y, x + random.randrange(10, 80), y + random.randrange(10, 80)], fill=tuple(random.randrange(256) for _ in range(3)))
im.save(f"{sys.argv[1]}/original.jpg", quality=95)
im.resize((320, 240)).save(f"{sys.argv[1]}/resized.jpg", quality=60)
im.save(f"{sys.argv[1]}/copy.png")
Image.new("RGB", (640, 480), "navy").save(f"{sys.argv[1]}/other.jpg")
PYEOF
mkdir -p "$CASE/collected" && cp "$W/photos/"* "$CASE/collected/"
if have exiftool; then
  exiftool -q -overwrite_original -GPSLatitude=45.4215 -GPSLatitudeRef=N -GPSLongitude=75.6972 -GPSLongitudeRef=W \
    -DateTimeOriginal="2026:10:02 09:15:00" "$CASE/collected/original.jpg" >> "$W/e2e.log" 2>&1
  check "EXIF GPS written and read back" "exiftool -n -GPSLatitude '$CASE/collected/original.jpg' | grep -q '45.42'"
else skip "EXIF GPS" "exiftool not installed"; fi
if have ns_photomatch; then
  menu ns-image "Find the same photo" "no"
  check "same-photo finder groups the copies, not the other photo" \
    "f=\$(ls -t '$CASE'/same-photo/*/same_photos.csv | head -1); grep -c 'collected/' \"\$f\" | grep -qx 3 && ! grep -q other.jpg \"\$f\""
else skip "same-photo finder" "images venv not installed"; fi
menu ns-map "Add a place" "last seen" "45.4215, -75.6972" "Rideau Centre" ""
menu ns-map "Build" "no"
check "case map has the recorded place and photo GPS" \
  "g=\$(ls -t '$CASE'/map/*/case.geojson | head -1); grep -q 'last seen' \"\$g\" && { ! command -v exiftool >/dev/null || grep -q 'photo GPS' \"\$g\"; }"
if have tesseract; then
  "$PY" -c "from PIL import Image, ImageDraw, ImageFont; im=Image.new('RGB',(900,200),'white'); d=ImageDraw.Draw(im); d.text((20,60),'MISSING PERSON CALL 555 0199',fill='black',font=ImageFont.load_default(size=48)); im.save('$W/sign.png')" >> "$W/e2e.log" 2>&1
  check "OCR reads text in an image" "tesseract '$W/sign.png' - 2>/dev/null | grep -qi 'missing'"
else skip "OCR" "tesseract not installed"; fi

section "Face comparison (local models)"
if have ns_face; then
  curl -fsSL -o "$W/lena.jpg" https://raw.githubusercontent.com/opencv/opencv/4.x/samples/data/lena.jpg >> "$W/e2e.log" 2>&1
  mkdir -p "$CASE/faces"; "$PY" -c "from PIL import Image; Image.open('$W/lena.jpg').resize((400,400)).save('$CASE/faces/lena_small.jpg')"
  check "the same face scores as strong similarity" \
    "mkdir -p '$W/face' && ns_face '$W/lena.jpg' '$CASE/faces' '$W/face' | grep -q 'Strong similarity: 1'"
else skip "face comparison" "face module not installed"; fi

section "Page monitoring"
mkdir -p "$W/site"; printf '<p>Last post: hello</p>' > "$W/site/index.html"
( cd "$W/site" && exec python3 -m http.server 8765 --bind 127.0.0.1 ) >/dev/null 2>&1 &
srv=$!; sleep 2
menu ns-watch "Watch a page" "http://127.0.0.1:8765/" "test page" "yes"
printf '<p>Last post: hello</p><p>New post: safe</p>' > "$W/site/index.html"
check "a change on a watched page is detected" "ns_watch check '$CASE'; [ \$? -eq 10 ] && grep -q 'New post: safe' '$CASE/watch/changes.log'"
kill "$srv" 2>/dev/null

section "Shadow analysis"
SFPY=$(ls "$NS_HOME"/venvs/shadowfinder/bin/python "$HOME"/.local/share/pipx/venvs/shadowfinder/bin/python "$HOME"/.local/pipx/venvs/shadowfinder/bin/python 2>/dev/null | head -1)
if [ -n "$SFPY" ]; then
  check "ShadowFinder's libraries load and find the time zone" \
    "'$SFPY' -c 'import shadowfinder, cartopy.crs, cartopy.feature; from timezonefinder import TimezoneFinder; print(TimezoneFinder(in_memory=True).timezone_at(lng=-9.14, lat=38.72))' | grep -q Europe/Lisbon"
else skip "ShadowFinder" "not installed"; fi

section "Telegram (public web preview, no login)"
if have ns_telegram; then
  check "channel lookup reads the public page" "mkdir -p '$W/tg' && cd '$W/tg' && ns_telegram lookup telegram | grep -q 'type: channel'"
  check "channel preview search returns posts" "cd '$W/tg' && ns_telegram preview-search telegram '' && [ \$(wc -l < '$W/tg/posts.csv') -gt 2 ]"
else skip "Telegram" "social module not installed"; fi

section "Offline translation"
if have ns_translate; then
  check "Spanish to English" "ns_translate get es en && echo 'Hola, estoy bien.' | ns_translate text es en | grep -qi 'fine\|well\|good\|okay'"
else skip "translation" "translate module not installed"; fi

section "Evidence"
check "every result folder verifies against its seal" \
  "for m in \$(find '$CASE' -name manifest.sha256); do ns_evidence verify \"\$(dirname \"\$m\")\" | grep -q ' 0 CHANGED, 0 MISSING' || { echo \"\$m\"; exit 1; }; done"
check "audit log chain intact" "ns_evidence audit-verify '$CASE/audit.log' | grep -q ' 0 BROKEN'"
check "case export with checksum" "ns_evidence export '$CASE' '$W/exports' && ls '$W'/exports/*.sha256"
check "no API keys or secrets in the audit log" "! grep -qiE 'api[_-]?key=|password=|sessionid=' '$CASE/audit.log'"

printf '\n%d passed, %d failed, %d skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
