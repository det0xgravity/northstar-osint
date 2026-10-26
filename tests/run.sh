#!/usr/bin/env bash
# tests/run.sh — offline functional tests for northstar-osint.
# Runs on Linux and on macOS's Bash 3.2. No network, no sudo, nothing installed:
# everything happens in a temporary folder, with menus driven by NS_UI=script.
# Usage: bash tests/run.sh

R="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
PASS=0; FAIL=0

ok()   { PASS=$((PASS+1)); printf '  ok    %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; [ -n "${2:-}" ] && printf '        %s\n' "$2"; }
check() { if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }
section() { printf '\n== %s\n' "$1"; }

# A throwaway northstar home with the engines on PATH, and scripted dialogs
H="$W/home"; mkdir -p "$H/lib" "$H/bin" "$H/config" "$W/data" "$W/conf"
cp "$R/lib/ui.sh" "$R/lib/ns_country.py" "$H/lib/"
cp "$R/config/ctf-categories.txt" "$H/config/"
cp -R "$R/config/countries" "$H/config/"
for e in breach darkweb evidence doctor missing watch casemap; do ln -s "$R/lib/ns_$e.py" "$H/bin/ns_$e"; done
ln -s "$R/lib/ns_case.py" "$H/bin/ns_casework"
export NS_HOME="$H" NS_DATA="$W/data" XDG_CONFIG_HOME="$W/xdg" NS_UI=script NS_UI_ANSWERS="$W/answers"
export PATH="$H/bin:$PATH"
mkdir -p "$XDG_CONFIG_HOME/northstar"
answers() { printf '%s\n' "$@" > "$NS_UI_ANSWERS"; rm -f "$NS_UI_ANSWERS.pos"; }
menu() { local t="$1"; shift; answers "$@"; bash "$R/tools/$t" < /dev/null > "$W/out.txt" 2>&1; }
CASE="$W/data/Cases/general"

section "Country packs"
check "every pack validates" "python3 '$R/lib/ns_country.py' validate > /dev/null"
check "searches build Google and registry links" \
  "python3 '$R/lib/ns_country.py' run GB 'Business / organization' 'Acme Ltd' | grep -q 'search/companies?q=Acme+Ltd'"
check "transforms clean the query (N-number)" \
  "python3 '$R/lib/ns_country.py' run US 'Aircraft (N-number)' 'n 12345' | grep -q '^clip	N12345$'"

section "Country search menu (scripted)"
menu ns-country "United Kingdom" "Business" "Acme Ltd"
d=$(find "$CASE/united-kingdom" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
check "result folder created" "[ -n '$d' ] && [ -f '$d/query.txt' ]"
check "result folder sealed" "[ -f '$d/manifest.sha256' ] && [ -f '$d/provenance.json' ]"
check "case folders are private (700)" "[ \"\$(ls -ld '$CASE' | cut -c1-10)\" = drwx------ ]"
check "audit log records the search" "grep -q 'ns-country:GB:business-organization' '$CASE/audit.log'"

section "Evidence integrity"
check "fresh folder verifies" "ns_evidence verify '$d' > /dev/null"
echo tampered >> "$d/query.txt"
check "a changed file is detected" "! ns_evidence verify '$d' > /dev/null"
check "audit chain written by Bash verifies in Python" "ns_evidence audit-verify '$CASE/audit.log' > /dev/null"
cp "$CASE/audit.log" "$W/audit.bak"
sed 's/ns-country/ns-COUNTRY/' "$W/audit.bak" > "$CASE/audit.log"
check "an edited audit line is detected" "! ns_evidence audit-verify '$CASE/audit.log' > /dev/null"
cp "$W/audit.bak" "$CASE/audit.log"
mkdir -p "$CASE/ex/one" && echo data > "$CASE/ex/one/a.txt"
ns_evidence seal "$CASE/ex/one" > /dev/null
check "exhibits get sequential IDs" \
  "ns_evidence exhibit '$CASE' '$CASE/ex/one' 'test' | grep -q 'GENERAL-EX-001'"

section "Case records"
answers "Test-Case" "yes" "REF-1" "Counsel" "Litigation support" "Acme" "2030-01-01"
bash "$R/tools/ns-case" open < /dev/null > "$W/out.txt" 2>&1
TC="$W/data/Cases/Test-Case"
check "intake record written" "grep -q '\"reference\": \"REF-1\"' '$TC/case.json'"
menu ns-case "Add a note" "first note"; menu ns-case "Add a note" "second note"
check "notes chain verifies" "ns_casework notes-verify '$TC' > /dev/null"
sed 's/second note/SECOND note/' "$TC/notes.md" > "$W/n" && mv "$W/n" "$TC/notes.md"
check "an edited note is detected" "! ns_casework notes-verify '$TC' > /dev/null"
check "report source builds" "ns_casework report '$TC' '$W/r.md' > /dev/null && grep -q 'REF-1' '$W/r.md'"

section "Secrets"
CANARY="canary-key-0123456789abcdef"
menu ns-keys "Have I Been Pwned" "Set" "$CANARY"
K="$XDG_CONFIG_HOME/northstar/keys.env"
check "key saved" "grep -q '^HIBP_API_KEY=$CANARY$' '$K'"
check "keys file is mode 600" "[ \"\$(ls -l '$K' | cut -c1-10)\" = -rw------- ]"
check "key never reaches case data or logs" "! grep -rq '$CANARY' '$W/data'"
check "breach engine masks passwords" "python3 - <<'PY'
import sys; sys.path.insert(0, '$R/lib'); import ns_breach as b
m = b.masked({'email': 'a@b.c', 'password': 'hunter2', 'nested': [{'hashed_password': 'x'}]})
assert m['password'] == '••••••' and m['nested'][0]['hashed_password'] == '••••••' and m['email'] == 'a@b.c'
PY"

section "Input validation"
mkdir -p "$W/stub"; printf '#!/bin/sh\necho "yt-dlp $*"\n' > "$W/stub/yt-dlp"; chmod +x "$W/stub/yt-dlp"
PATH="$W/stub:$PATH" menu ns-media "Video" "--exec=touch $W/pwned"
check "option-like URL refused" "grep -q 'starting with https' '$W/out.txt' && [ ! -e '$W/pwned' ]"
PATH="$W/stub:$PATH" menu ns-media "Video" "https://example.com/v"
check "-- precedes the URL" "grep -q -- '-- https://example.com/v' '$W/out.txt'"

section "Photo geolocation (stubbed model)"
echo general > "$XDG_CONFIG_HOME/northstar/active_case"     # the case tests switched cases
G="$W/geostub"; mkdir -p "$G"
cat > "$G/ns_geo" <<'STUB'
#!/bin/sh
case "$1" in
  estimate) printf 'rank,lat,lon,probability\n1,45.42153,-75.69719,0.31\n2,48.85661,2.35222,0.12\n' > geoclip.csv ;;
  places)   echo '[]' > places.json ;;
esac
STUB
printf '#!/bin/sh\necho "shadowfinder $*"\n' > "$G/shadowfinder"; chmod +x "$G/"*
printf 'fake' > "$W/photo.jpg"
PATH="$G:$PATH" menu ns-geo "Where was this photo taken" "$W/photo.jpg" "yes" "yes"
gd=$(find "$CASE/geo" -mindepth 1 -maxdepth 1 -type d | head -1)
check "AI candidates saved and folder sealed" "[ -s '$gd/geoclip.csv' ] && [ -f '$gd/manifest.sha256' ]"
check "maps open for the top candidates" "grep -q 'maps/@45.42153,-75.69719' '$W/out.txt' && grep -q 'mapillary.com/app/?lat=48.85661' '$W/out.txt'"
check "photo copied with its original hash recorded" "grep -q 'SHA-256' '$gd/source_url.txt'"
PATH="$G:$PATH" menu ns-geo "Shadow analysis" "1.8" "abc" "2026-06-01" "12:00:00"
check "bad shadow input refused" "grep -q 'Use numbers' '$W/out.txt'"
PATH="$G:$PATH" menu ns-geo "Shadow analysis" "1.8" "2.4" "2026-06-01" "12:00:00"
check "shadow inputs passed to ShadowFinder" "grep -q 'shadowfinder find 1.8 2.4 2026-06-01 12:00:00 --time_format=utc' '$W/out.txt'"

section "Face comparison safeguards (stubbed engine)"
printf '#!/bin/sh\necho "ns_face $*" > results.csv\n' > "$G/ns_face"; chmod +x "$G/ns_face"
PATH="$G:$PATH" menu ns-face "no"
check "declining the safeguards stops it" "[ ! -e '$CASE/face-comparison-basis.txt' ] && ! grep -q 'ns_face ' '$W/out.txt'"
PATH="$G:$PATH" menu ns-face "yes" "Test lawful basis" "$W/photo.jpg" "no" "$W"
check "lawful basis recorded" "grep -q 'Test lawful basis' '$CASE/face-comparison-basis.txt'"
check "folder outside the case refused" "grep -q \"isn't inside case\" '$W/out.txt'"
PATH="$G:$PATH" menu ns-face "$W/photo.jpg" "yes"
fd=$(find "$CASE/face" -mindepth 1 -maxdepth 1 -type d | head -1)
check "reference copied, basis kept with the results, sealed" \
  "[ -f '$fd/reference_photo.jpg' ] && [ -f '$fd/face-comparison-basis.txt' ] && [ -f '$fd/manifest.sha256' ]"
check "only the case folder is searched" "grep -q \"ns_face reference_photo.jpg $CASE \" '$fd/results.csv'"

section "Missing person"
echo general > "$XDG_CONFIG_HOME/northstar/active_case"
menu ns-missing "Subject profile" "Jane Doe" "JD" "1999" "2026-10-01 18:30" "Ottawa bus station" "5'6, red jacket" "janed99" "" "" "" ""
check "profile saved" "grep -q '\"name\": \"Jane Doe\"' '$CASE/subject/subject.json'"
printf 'shot' > "$W/shot.png"
menu ns-missing "Log a finding" "Friends" "https://example.com/p/1" "Friend posted with her on 2026-10-03" "yes" "$W/shot.png"
menu ns-missing "Log a finding" "Location" "https://example.com/p/1/" "Same post, location tag" "no"
check "finding logged with evidence hash" "grep -q '^F001,.*Friends.*shot.png,[0-9a-f]\{64\}' '$CASE/subject/findings.csv'"
check "duplicate URL warned" "grep -q 'already logged as F001' '$W/out.txt'"
menu ns-missing "Add a timeline event" "2026-10-02 09:00" "Bank card used" "police briefing"
mkdir -p "$CASE/media/x"; printf '{"timestamp": 1791100800, "title": "Night out", "uploader": "janed99", "webpage_url": "https://example.com/v"}' > "$CASE/media/x/v.info.json"
menu ns-missing "Build the timeline"
check "timeline marks last seen and later events" "grep -q 'LAST SEEN at Ottawa bus station' '$CASE/subject/timeline.csv' && grep -q '+0.6 days,Bank card used' '$CASE/subject/timeline.csv'"
check "timeline includes media metadata and dated findings" "grep -q 'Post by janed99: Night out' '$CASE/subject/timeline.csv' && grep -q 'Friend posted' '$CASE/subject/timeline.csv'"
menu ns-missing "Export findings"
check "findings export grouped by category" "grep -q '## Friends (1)' '$CASE/subject/findings.md'"

section "Username and email variants"
for t in sherlock holehe; do printf '#!/bin/sh\necho "%s $*"\n' "$t" > "$G/$t"; chmod +x "$G/$t"; done
PATH="$G:$PATH" menu ns-username "Generate" "Jane Doe" "1999" "yes" "yes"
vd=$(find "$CASE/variants" -mindepth 1 -maxdepth 1 -type d | head -1)
check "variants generated" "grep -qx 'jane.doe' '$vd/usernames.txt' && grep -qx 'janedoe99' '$vd/usernames.txt' && grep -qx 'janedoe@gmail.com' '$vd/emails.txt'"
check "top usernames passed to Sherlock" "grep -q 'sherlock janedoe jane.doe' '$vd/console.log'"
check "emails checked with holehe" "[ \"\$(grep -c '^holehe ' '$vd/console.log')\" -eq 10 ]"

section "Same-photo finder (stubbed engine)"
printf '#!/bin/sh\necho "ns_photomatch $*"; printf "<html>" > same_photos.html\n' > "$G/ns_photomatch"; chmod +x "$G/ns_photomatch"
PATH="$G:$PATH" menu ns-image "Find the same photo" "no"
check "whole-case search runs on the case folder" "grep -q 'ns_photomatch groups $CASE \\.' '$W/out.txt'"
PATH="$G:$PATH" menu ns-image "Find the same photo" "yes" "$W/photo.jpg"
check "one-photo search copies the photo in first" "grep -q 'ns_photomatch find searched_photo.jpg $CASE' '$W/out.txt'"

section "Page monitoring"
menu ns-watch "Watch a page" "https://example.org/profile" "Profile" "no"
check "watch added to the case" "grep -q 'https://example.org/profile' '$CASE/watch/watches.json'"
menu ns-watch "Watch a page" "file:///etc/passwd" "" "no"
check "non-web addresses refused" "! grep -q 'file://' '$CASE/watch/watches.json'"
python3 - "$R/lib/ns_watch.py" "$CASE" > "$W/watch.txt" 2>&1 <<'PYEOF2'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("w", sys.argv[1]); w = importlib.util.module_from_spec(spec); spec.loader.exec_module(w)
page = ["Profile\nLast post: hello"]
w.page_text = lambda url: page[0]
w.cmd_check(sys.argv[2]); w.cmd_check(sys.argv[2])
page[0] += "\nNew post: safe in Kingston"
print("rc", w.cmd_check(sys.argv[2]))
PYEOF2
check "first check is a baseline, unchanged page is quiet" "grep -q 'baseline recorded' '$W/watch.txt' && grep -q 'no change' '$W/watch.txt'"
check "a change is detected with its new line" "grep -q 'rc 10' '$W/watch.txt' && grep -q 'safe in Kingston' '$CASE/watch/changes.log'"
check "snapshot and diff kept" "[ \"\$(ls '$CASE'/watch/W001/*.txt | wc -l)\" -eq 2 ] && ls '$CASE'/watch/W001/*.diff >/dev/null"
check "audit log chain intact" "python3 '$R/lib/ns_evidence.py' audit-verify '$CASE/audit.log' | grep -q ' 0 BROKEN'"

section "Case map"
mkdir -p "$CASE/geo/run1"
printf 'rank,lat,lon,probability\n1,45.42,-75.69,0.3\n2,43.65,-79.38,0.2\n' > "$CASE/geo/run1/geoclip.csv"
menu ns-map "Add a place" "sighting" "45.4215, -75.6972" "Rideau Centre <b>" ""
menu ns-map "Add a place" "home" "95, 10" "Bad" ""
check "places recorded, bad coordinates refused" "grep -q 'Rideau Centre' '$CASE/map/places.csv' && ! grep -q 'Bad' '$CASE/map/places.csv'"
menu ns-map "Build" "no"
md=$(find "$CASE/map" -mindepth 1 -maxdepth 1 -type d | head -1)
check "map built from places and GeoCLIP estimates" "grep -q '1 sighting, [0-9]* AI estimate' '$W/out.txt' && [ -s '$md/case.kml' ]"
check "GeoJSON valid, every point present" "python3 -c 'import json,sys; f=json.load(open(sys.argv[1]))[\"features\"]; assert len(f) >= 3 and any(x[\"properties\"][\"kind\"] == \"sighting\" for x in f)' '$md/case.geojson'"
check "labels escaped in the map page" "grep -q 'Rideau Centre &lt;b&gt;' '$md/map.html' && ! grep -q 'Rideau Centre <b>' '$md/map.html'"

section "Offline translation (stubbed engine)"
cat > "$G/ns_translate" <<'STUB'
#!/bin/sh
case "$1" in
  languages) printf 'en\tEnglish *\nes\tSpanish\nfr\tFrench\n' ;;
  get) echo "Ready." ;;
  file) tr 'a-z' 'A-Z' < "$4" > "$5" ;;
esac
STUB
chmod +x "$G/ns_translate"
PATH="$G:$PATH" menu ns-translate "Translate text" "Spanish (es)" "English * (en)" "hola amigo"
td=$(find "$CASE/translation" -mindepth 1 -maxdepth 1 -type d -name 'es-en_*' | head -1)
check "text translated and saved with its source" "grep -qx 'hola amigo' '$td/source.txt' && grep -qx 'HOLA AMIGO' '$td/source.en.txt'"
printf 'uno\n' > "$W/post.srt"
PATH="$G:$PATH" menu ns-translate "Translate text files" "French (fr)" "English * (en)" "$W/post.srt"
td=$(find "$CASE/translation" -mindepth 1 -maxdepth 1 -type d -name 'fr-en_*' | head -1)
check "files copied beside their translation" "[ -f '$td/post.srt' ] && grep -qx 'UNO' '$td/post.en.srt'"
check "translation result sealed" "[ -f '$td/manifest.sha256' ]"

section "Missing-persons searches"
check "seven packs have a Missing persons search" "[ \"\$(grep -l '\"Missing persons\"' '$R'/config/countries/*.json | wc -l)\" -eq 7 ]"
printf '#!/bin/sh\nexec bash "%s/tools/ns-country" "$@"\n' "$R" > "$G/ns-country"; chmod +x "$G/ns-country"
PATH="$G:$PATH" menu ns-missing "Missing-persons" "United States" "<default>" "yes"
check "subject's name pre-filled into the US missing-persons search" "grep -q 'charleyproject.org/?s=Jane+Doe' '$W/out.txt'"

section "Installer module selection"
I="$W/inst"; mkdir -p "$I/modules" "$I/bin" "$I/home"
cp "$R/install.sh" "$I/" && cp -R "$R/lib" "$I/"
mk() { printf 'ns_register %s "d" "linux macos" mod_%s\nmod_%s() { echo "RAN %s"; }\n' "$2" "$2" "$2" "$2" > "$I/modules/$1-$2.sh"; }
mk 00 core; mk 10 alpha; mk 20 beta; mk 30 gamma
printf '#!/bin/sh\nexit 0\n' > "$I/bin/sudo"; printf '#!/bin/sh\nexit 1\n' > "$I/bin/sleep"; chmod +x "$I/bin/"*
inst() { HOME="$I/home" XDG_CONFIG_HOME="$I/home/.config" PATH="$I/bin:$PATH" bash "$I/install.sh" "$@" 2>&1 | grep '^RAN' | tr '\n' ' '; }
inst --only alpha --yes > /dev/null
check "first install records the skipped modules" "grep -qx 'beta,gamma' '$I/home/.config/northstar/skipped'"
mk 40 delta
check "update installs a module added later" "inst --update --yes | grep -q 'RAN delta'"
check "update keeps skipped modules skipped" "! inst --update --yes | grep -q 'RAN beta'"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
