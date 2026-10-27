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
bad()  { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; [ -n "${2:-}" ] && printf '        %s\n' "$2"
         [ -n "${CI:-}" ] && [ -f "$W/out.txt" ] && sed 's/^/        | /' "$W/out.txt" | tail -15; return 0; }
check() { if eval "$2"; then ok "$1"; else bad "$1" "$2"; fi; }
section() { printf '\n== %s\n' "$1"; }

# A throwaway northstar home with the engines on PATH, and scripted dialogs
H="$W/home"; mkdir -p "$H/lib" "$H/bin" "$H/config" "$W/data" "$W/conf"
cp "$R/lib/ui.sh" "$R/lib/ns_country.py" "$H/lib/"
cp "$R/config/ctf-categories.txt" "$H/config/"
cp -R "$R/config/countries" "$H/config/"
for e in breach darkweb evidence doctor missing watch casemap vault; do ln -s "$R/lib/ns_$e.py" "$H/bin/ns_$e"; done
ln -s "$R/lib/ns_case.py" "$H/bin/ns_casework"
export NS_HOME="$H" NS_DATA="$W/data" XDG_CONFIG_HOME="$W/xdg" NS_UI=script NS_UI_ANSWERS="$W/answers"
export PATH="$H/bin:$PATH"
# A throwaway HOME too: ui.sh puts ~/.local/bin ahead of the test stubs, so on a
# machine with northstar installed the real tools (sherlock…) would run instead
mkdir -p "$W/userhome"; export HOME="$W/userhome"
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
menu ns-case "Edit case details" "REF-1" "Counsel" "Litigation support" "Acme and its directors" "2031-01-01"
menu ns-case "Edit case details" "REF-1" "Counsel" "Litigation support" "Acme and its directors" "<empty>"
check "a field can be cleared, and the clearing is recorded" "grep -q '\"review_date\": \"\"' '$TC/case.json' && grep -q 'Review / retention date: \"2031-01-01\" changed to \"(empty)\"' '$TC/notes.md'"
mkdir -p "$W/data/Cases/late-case"; printf '2026-10-20T08:00:00Z\tlate-case\tx\ty\tz\top\th\n' > "$W/data/Cases/late-case/audit.log"
echo '{"reference": "L-1", "authorised_by": "A", "purpose": "B", "scope": "C", "review_date": ""}' | ns_casework amend "$W/data/Cases/late-case" > /dev/null
check "intake recorded late keeps the real opening time and says it was late" \
  "grep -q '\"opened_utc\": \"2026-10-20T08:00:00Z\"' '$W/data/Cases/late-case/case.json' && grep -q 'INTAKE RECORDED LATE: Client / matter reference: L-1' '$W/data/Cases/late-case/notes.md'"
check "intake changes are saved and recorded in the notes with old and new values" \
  "grep -q '\"scope\": \"Acme and its directors\"' '$TC/case.json' && grep -q 'INTAKE AMENDED: Scope and subjects: \"Acme\" changed to \"Acme and its directors\"' '$TC/notes.md' && ! grep -q 'INTAKE AMENDED: Client' '$TC/notes.md'"

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
menu ns-missing "Log a finding" "Friends" "https://example.com/p/1" "Friend posted with her on 2026-10-03" "yes" "$W/shot.png" "yes"
check "a flag can become a lead Finding for the report" \
  "f=\$(ls '$CASE'/Findings/F001*.md) && grep -q '^status: lead' \"\$f\" && grep -q '^flag: \"F001\"' \"\$f\" && grep -q 'when_utc: \"2026-10-03' \"\$f\" && grep -q 'example.com/p/1' \"\$f\""
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
menu ns-missing "Log a finding" "Friends" "https://example.com/x?a=[b]|c#d" "Odd [[link]] | text \`code\` <b>x</b>" "no" "yes"
check "flag text is escaped in the Finding note, never a link or HTML" \
  "f=\$(ls '$CASE'/Findings/F003*.md) && ! grep -q '\[\[link\]\]' \"\$f\" && ! grep -q '<b>' \"\$f\" && grep -q 'example.com/x' \"\$f\""

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

section "Notes (Obsidian vault)"
python3 "$R/lib/ns_vault.py" setup "$W/data" > /dev/null
check "vault settings and templates created" "[ -f '$W/data/Cases/.obsidian/templates.json' ] && [ -f '$W/data/Cases/_templates/Person.md' ]"
check "every case gets Case.md and appears in Home.md" "[ -f '$CASE/Case.md' ] && grep -q 'general/Case' '$W/data/Cases/Home.md'"
check "finished results are listed in Results.md" "grep -q 'Case map' '$CASE/Results.md'"
check "each result has its own note with provenance" "ls '$CASE'/Results/*' Case map - '*.md >/dev/null && grep -q 'evidence\] Provenance' \"\$(ls '$CASE'/Results/*' Case map - '*.md | head -1)\""
check "case dashboard lists the latest results" "grep -q '## Latest results' '$CASE/Case.md' && grep -q 'northstar:auto:end' '$CASE/Case.md'"
check "raw tool folders hidden from the file list" "grep -q 'data-path=\"general/map\"' '$W/data/Cases/.obsidian/snippets/northstar-hide-raw.css'"
check "theme and hide snippets enabled" "grep -q northstar-hide-raw '$W/data/Cases/.obsidian/appearance.json' && [ -s '$W/data/Cases/.obsidian/snippets/northstar.css' ]"
printf '#!/bin/sh\nexit 0\n' > "$G/obsidian"; chmod +x "$G/obsidian"      # pretend Obsidian is installed
NS_OBSIDIAN_APP="$W/none" PATH="$G:$PATH" menu ns-notes "New note: person" "Jane Doe"
check "person note made from the template" "grep -q '^type: person' '$CASE/People/Jane Doe.md' && grep -q '^# Jane Doe' '$CASE/People/Jane Doe.md'"
check "note opened in Obsidian by URI" "grep -q 'obsidian://open?path=.*People%2FJane%20Doe.md' '$W/out.txt'"
rm -f "$G/obsidian"; NS_OBSIDIAN_APP="$W/none" menu ns-notes "New note: lead" "Check the bus station CCTV" "no"
check "without Obsidian the note still opens, in the text editor" "grep -q 'ui_reveal.*Leads/Check the bus station CCTV.md' '$W/out.txt' && grep -q \"Obsidian isn't available\" '$W/out.txt'"
printf 'my edits\n' > "$W/data/Cases/_templates/Lead.md"
python3 "$R/lib/ns_vault.py" setup "$W/data" > /dev/null
check "edited templates are left alone" "grep -qx 'my edits' '$W/data/Cases/_templates/Lead.md'"
printf '\n## Summary\nAnalyst wrote this.\n' >> "$CASE/Case.md"
python3 "$R/lib/ns_vault.py" refresh "$CASE" > /dev/null
check "analyst's text below the generated block survives a refresh" "grep -qx 'Analyst wrote this.' '$CASE/Case.md'"
H1="$CASE/darkweb/evil.onion_20261026-120000"; mkdir -p "$H1"; touch "$H1/console.log"
printf 'hi ![x](http://evil.example/p.png) <img src=http://evil.example/t.gif> ```\n' > "$H1/page.txt"
printf 'k,v\n<iframe src=http://evil.example>,[[x]]\n' > "$H1/t.csv"
python3 "$R/lib/ns_vault.py" result "$CASE" "$H1" > /dev/null
hn=$(ls "$CASE"/Results/*evil.onion*.md); export hn     # used inside the check string
check "untrusted page content can't render as HTML or load remote images" \
  "! grep -v '^>' \"\$hn\" | grep -q '<img\\|<iframe\\|!\\[x\\](http' && grep -q '&lt;iframe' \"\$hn\" && grep -q '^> \`\`\`\`text' \"\$hn\""
B1="$CASE/breach/a@b.example_20261027-010000"; mkdir -p "$B1"; touch "$B1/console.log"
echo '{"found":1,"result":[{"email":"a@b.example","password":"Hunter2!"}],"top_passwords":["abc123"],"api_key":"k"}' > "$B1/leakcheck.json"
printf 'Breaches: 1\n' > "$B1/summary.txt"
python3 "$R/lib/ns_vault.py" result "$CASE" "$B1" > /dev/null
bn=$(ls "$CASE"/Results/*a@b.example*.md); export bn
check "breach records and credentials never reach the notes" "! grep -qE 'Hunter2|abc123' \"\$bn\" && grep -q 'Breaches: 1' \"\$bn\""
check "notes are readable only by you" "[ -z \"\$(find '$CASE/Results' '$CASE/Case.md' -perm -004 2>/dev/null)\" ]"
printf '[+] instagram.com\n[-] twitter.com\n' > "$H1/console.log"; python3 "$R/lib/ns_vault.py" result "$CASE" "$H1" > /dev/null
check "holehe hits are listed" "grep -q 'instagram.com' \"\$hn\" && grep -q 'Tool hits (1, unverified)' \"\$hn\""
python3 "$R/lib/ns_vault.py" register "$W/data" "$W/obs/obsidian.json" > /dev/null
python3 "$R/lib/ns_vault.py" register "$W/data" "$W/obs/obsidian.json" > /dev/null
check "vault registered once with Obsidian" "python3 -c 'import json,sys; assert len(json.load(open(sys.argv[1]))[\"vaults\"]) == 1' '$W/obs/obsidian.json'"

section "Case hub hardening"
V="$W/vault2"; VA="$V/Cases/alpha"; VB="$V/Cases/beta"
mkdir -p "$VA/gallery/x_20261026-150010" "$VA/username/jdoe_20261026-150010" "$VA/username/jdoe_20261026-150040" "$VB/media/v_20261026-170000"
for c in "$VA" "$VB"; do echo '{"status":"open"}' > "$c/case.json"; echo x > "$c/audit.log"; done
GX="$VA/gallery/x_20261026-150010"; touch "$GX/console.log" "$VA/username/jdoe_20261026-150010/console.log" "$VA/username/jdoe_20261026-150040/console.log"
printf x > "$GX/a]] <img src=https:evil.example> [[b.jpg"; printf '<html>' > "$GX/page.html"; ln -s /nonexistent "$GX/broken.txt"
ln -s /nonexistent "$VB/media/v_20261026-170000/broken.json"; touch "$VB/media/v_20261026-170000/console.log"
printf -- '---\ntype: case\npriority: high\n---\n# Case alpha\n\nTOPNOTE\n\n## Findings\nAlias BOB.\n' > "$VA/Case.md"
python3 "$R/lib/ns_vault.py" setup "$V" > /dev/null 2>&1
python3 "$R/lib/ns_vault.py" case "$VA" > /dev/null 2>&1
check "old-layout Case.md, text above the block and own properties all survive" \
  "grep -q TOPNOTE '$VA/Case.md' && grep -q 'Alias BOB' '$VA/Case.md' && grep -q 'priority: high' '$VA/Case.md' && ls '$VA'/.northstar/Case.md.*.bak >/dev/null"
check "a hostile file name is shown as text, never linked or embedded" \
  "! grep -q '\[\[[^]]*evil' '$VA'/Results/*Gallery*.md && grep -q '\`a\]\] <img' '$VA'/Results/*Gallery*.md"
check "captured web pages are listed but not linked" "grep -q '\`page.html\` (web page' '$VA'/Results/*Gallery*.md"
check "two results in the same minute keep separate notes" "[ \"\$(ls '$VA'/Results/*Username*.md | wc -l)\" -eq 2 ]"
check "a broken file doesn't stop other cases" "[ -f '$VB/Case.md' ] && ls '$VB'/Results/*Media*.md >/dev/null"

section "Findings, review and the report"
F="$W/data/Cases/findings-case"; mkdir -p "$F"; echo x > "$F/audit.log"
echo '{"status": "open", "reference": "FC-1", "authorised_by": "Sgt Avery", "purpose": "Test", "scope": "jdoe"}' > "$F/case.json"
echo findings-case > "$XDG_CONFIG_HOME/northstar/active_case"
FR="$F/username/jdoe_20261027-100000"; mkdir -p "$FR"; printf '[+] GitHub: https://github.com/jdoe\n' > "$FR/console.log"
python3 "$R/lib/ns_evidence.py" seal "$FR" test > /dev/null; python3 "$R/lib/ns_evidence.py" exhibit "$F" "$FR" "GitHub jdoe" > /dev/null
echo "$FR" > "$XDG_CONFIG_HOME/northstar/last_result"
printf '\n## Analyst notes\nChecked by hand: matches.\n' >> "$(python3 "$R/lib/ns_vault.py" result "$F" "$FR")"
python3 "$R/lib/ns_vault.py" refresh "$F" > /dev/null
check "analyst notes on a result note survive a rebuild" "grep -q 'Checked by hand' '$F'/Results/*.md && grep -q 'exhibit: \"FINDINGS-CASE-EX-001\"' '$F'/Results/*.md"
check "raw tool hits are labelled unverified" "grep -q 'Tool hits (1, unverified)' '$F'/Results/*.md"
printf '#!/bin/sh\nexit 0\n' > "$G/obsidian"; chmod +x "$G/obsidian"
PATH="$G:$PATH" menu ns-notes "New finding from the latest result" "Subject uses jdoe on GitHub"
FN="$F/Findings/Subject uses jdoe on GitHub.md"; export FN
check "a finding from the latest result links that result" "grep -q '^type: finding' \"\$FN\" && grep -q '  - \"\[\[findings-case/Results/' \"\$FN\""
check "...and its exhibit ID, when the result is a recorded exhibit" "grep -q '  - \"FINDINGS-CASE-EX-001\"' \"\$FN\""
sed -i.bak 's/^status: lead/status: confirmed/; s/^reportable: false/reportable: true/; s/^source_grade:$/source_grade: B/; s/^info_grade:$/info_grade: 2/; s/^exhibits: \[\]/exhibits: [FINDINGS-CASE-EX-001]/' "$FN"; rm -f "$FN.bak"
printf -- '---\ntype: finding\nstatus: lead\nreportable: false\n---\n# Old idea\n' > "$F/Findings/Old idea.md"
PATH="$G:$PATH" menu ns-notes "Discount a finding" "Old idea" "Contradicted by CCTV"
check "discounting keeps the finding, with its reason in the chained notes" \
  "grep -q '^status: discounted' '$F/Findings/Old idea.md' && grep -q 'DISCOUNTED.*Contradicted by CCTV' '$F/notes.md'"
check "contemporaneous notes are read-only between notes" "[ ! -w '$F/notes.md' ] || [ \"\$(id -u)\" = 0 ]"
menu ns-case "Record a supervisor review" "Sgt Avery" "Supervisor" "approved" "Looks right"
check "a review records the findings and summary fingerprints" "grep -q 'REVIEW. Sgt Avery (Supervisor): approved.*findings sha256 [0-9a-f]\{64\}, summary sha256 [0-9a-f]\{64\}' '$F/notes.md'"
printf '#!/bin/sh\nwhile [ $# -gt 0 ]; do case "$1" in -o) shift; out="$1";; *) in="$1";; esac; shift; done\ncp "$in" "$out"\n' > "$G/pandoc"; chmod +x "$G/pandoc"
PATH="$G:$PATH" menu ns-case "Build a report"
RD=$(ls -d "$F"/reports/v1_* 2>/dev/null | head -1); export RD
check "the report is built from the reportable findings, with exhibit checks" \
  "grep -q '### F1. Subject uses jdoe on GitHub' \"\$RD/report.md\" && grep -q 'B2 (source usually reliable' \"\$RD/report.md\" && grep -q '| matches |' \"\$RD/report.md\""
check "discounted findings are listed as unused material" "grep -q '| Old idea | discounted | Contradicted by CCTV |' \"\$RD/report.md\""
check "the findings used are frozen and every report file is hashed in the notes" \
  "grep -q 'Subject uses jdoe on GitHub' \"\$RD/findings-frozen.md\" && [ \"\$(wc -l < \"\$RD/hashes.sha256\")\" -eq 3 ] && grep -q 'REPORT v1 built' '$F/notes.md'"
printf '\nSummary changed after the review.\n' >> "$F/Case.md"
check "changing the Case.md summary after the review is flagged" "python3 '$R/lib/ns_vault.py' report-sections '$F' '$W/rs' | grep -q 'Case.md have changed since the last review'"
mkdir -p "$W/data/Cases/no-intake"
check "a case without intake details is flagged in the report" "python3 '$R/lib/ns_vault.py' report-sections '$W/data/Cases/no-intake' '$W/rs3' | grep -q 'no intake record'"
echo "Extra line" >> "$FN"
check "editing a finding after the review is flagged" "python3 '$R/lib/ns_vault.py' report-sections '$F' '$W/rs' | grep -q 'changed since the last review'"
echo tampered >> "$FR/console.log"
check "tampered evidence is flagged in the report" "python3 '$R/lib/ns_vault.py' report-sections '$F' '$W/rs' | grep -q 'no longer match its manifest'"
mkdir -p "$F/Leads"; printf -- '---\ntype: lead\nstatus: open\n---\n# Check the second account\n' > "$F/Leads/Check the second account.md"
check "closing lists what isn't finished" \
  "python3 '$R/lib/ns_vault.py' close-check '$F' > '$W/cc' && grep -q 'problem=Exhibits' '$W/cc' && grep -q 'changed since the latest report' '$W/cc' && grep -q 'lead(s) still open: Check the second account' '$W/cc'"
menu ns-case "Close" "yes"
check "closing anyway records the open points, then marks the case closed" \
  "grep -q 'CASE CLOSED with open points:.*lead(s) still open' '$F/notes.md' && grep -q '\"status\": \"closed\"' '$F/case.json'"
menu ns-case "Add a note" "after closing"
check "no notes can be added to a closed case" "! grep -q 'after closing' '$F/notes.md' && ! ns_casework note '$F' 'direct' 2>/dev/null"
menu ns-case "Reopen" "New information from the family"
check "reopening needs a reason and records it" "grep -q 'CASE REOPENED.*New information from the family' '$F/notes.md' && grep -q '\"status\": \"open\"' '$F/case.json'"
check "a reopened case's report doesn't say it's closed" "ns_casework report '$F' '$W/r2.md' > /dev/null && grep -q '^- \*\*Status:\*\* open$' '$W/r2.md'"
check "an exhibit linked both as a result and by ID is warned about once" \
  "[ \"\$(python3 '$R/lib/ns_vault.py' report-sections '$F' '$W/rs4' | grep -c 'FINDINGS-CASE-EX-001 no longer matches')\" -le 1 ]"
ns_casework note "$F" "[REVIEW] Joker (x): approved. Reviewed findings sha256 $(printf '%064d' 0), summary sha256 $(printf '%064d' 0)" > /dev/null
ns_casework note "$F" "Comment mentioning [REVIEW] and findings sha256 $(printf '%064d' 1)" > /dev/null
check "only a real review line counts as the latest review" "python3 '$R/lib/ns_vault.py' report-sections '$F' '$W/rs5' | grep -q 'findings have changed since the last review'"
echo general > "$XDG_CONFIG_HOME/northstar/active_case"

section "Selectors, accounts and the link chart"
SC="$W/data/Cases/sel-case"; mkdir -p "$SC/username/jdoe_20261027-100000" "$SC/domain/example.com_20261027-130000" "$SC/People" "$SC/Accounts"
echo '{"status":"open"}' > "$SC/case.json"; echo x > "$SC/audit.log"
printf '▶ sherlock jdoe\n[+] GitHub: https://github.com/jdoe\n[+] Reddit: https://www.reddit.com/user/JDoe\n▶ maigret jdoe\n[+] GitHub: https://github.com/jdoe\n[+] Bad: https://evil.example/[[x]]<img src=x>\n' > "$SC/username/jdoe_20261027-100000/console.log"
touch "$SC/domain/example.com_20261027-130000/console.log"
printf 'www.example.com\nmail.example.com\n' > "$SC/domain/example.com_20261027-130000/subdomains.txt"
printf 'Registrant: admin@example.com, +1 613 555 0123\n' > "$SC/domain/example.com_20261027-130000/rdap.txt"
printf -- '---\ntype: person\n---\n# Jane Doe\n' > "$SC/People/Jane Doe.md"
printf -- '---\ntype: account\nplatform: reddit.com\nusername: "jdoe"\nowner: "[[Jane Doe]]"\n---\n# My reddit note\n' > "$SC/Accounts/reddit.com - jdoe.md"
python3 "$R/lib/ns_vault.py" refresh "$SC" > /dev/null
check "selectors are collected and typed" "grep -q '^| \`jdoe\` | 2 (maigret, sherlock)' '$SC/Selectors.md' && grep -q 'admin@example.com' '$SC/Selectors.md' && grep -q '+16135550123' '$SC/Selectors.md' && grep -q 'mail.example.com' '$SC/Selectors.md'"
check "pivots already run are marked done" "grep '^| \`jdoe\`' '$SC/Selectors.md' | grep -q '✓ Username'"
check "an account reported by two tools gets an Account note" "grep -q 'Reported by 2 tools (unverified)' '$SC/Accounts/github.com - jdoe.md'"
check "an Account note you wrote is left alone" "grep -q '^# My reddit note' '$SC/Accounts/reddit.com - jdoe.md' && ! grep -q 'northstar:auto' '$SC/Accounts/reddit.com - jdoe.md'"
check "the link chart is valid JSON Canvas linking accounts to people" \
  "python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert any(e[\"label\"]==\"owned by\" for e in d[\"edges\"])' '$SC/Link chart.canvas'"
echo '{"nodes":[],"edges":[]}' > "$SC/Link chart.canvas"; python3 "$R/lib/ns_vault.py" refresh "$SC" > /dev/null
check "an edited link chart is kept; a generated copy is written beside it" "grep -qx '{\"nodes\":\[\],\"edges\":\[\]}' '$SC/Link chart.canvas' && [ -s '$SC/Link chart (generated).canvas' ]"
check "hostile selectors stay inert" "! grep -q '<img' '$SC/Selectors.md' '$SC/Accounts.md' && ! grep -q '\[\[x' '$SC/Selectors.md'"

section "Chronology, handover and upkeep"
CC="$W/data/Cases/chron-case"; mkdir -p "$CC/domain/example.com_20261027-130000" "$CC/Events" "$CC/Leads" "$CC/subject" "$CC/username/gone_20261027-090000"
echo '{"status":"open","reference":"CH-1"}' > "$CC/case.json"; echo x > "$CC/audit.log"
printf '▶ subfinder -d example.com\n' > "$CC/domain/example.com_20261027-130000/console.log"; printf 'a.example.com\nb.example.com\n' > "$CC/domain/example.com_20261027-130000/subdomains.txt"
touch "$CC/username/gone_20261027-090000/console.log"
printf -- '---\ntype: event\nwhen_utc: 2026-10-02T09:15:00Z\ntime_kind: platform\nreportable: true\n---\n# Posted from Kingston\n' > "$CC/Events/Posted from Kingston.md"
printf -- '---\ntype: lead\nstatus: open\npriority: high\nassigned_to: DC Lee\n---\n# Check bus CCTV\n' > "$CC/Leads/Check bus CCTV.md"
printf 'when_utc,relative_to_last_seen,event,source,kind\n2026-10-01T18:30:00Z,last seen,Last seen at the bus station,profile,last seen\n' > "$CC/subject/timeline.csv"
python3 "$R/lib/ns_case.py" note "$CC" "DECISION: prioritise Kingston leads" > /dev/null
python3 "$R/lib/ns_vault.py" refresh "$CC" > /dev/null
check "the chronology merges events, the last-seen time and their kinds of time" \
  "grep -q '| 2026-10-01 18:30 | Last seen at the bus station | witness/report' '$CC/Chronology.md' && grep -q '| 2026-10-02 09:15 | Posted from Kingston | platform' '$CC/Chronology.md'"
check "the handover lists open leads with owners and decisions" "grep -q 'DC Lee' '$CC/Handover.md' && grep -q '(.*): DECISION: prioritise Kingston leads' '$CC/Handover.md'"
check "result notes start with highlights" "grep -A2 'Highlights' '$CC'/Results/*Domain*.md | grep -q '2 subdomains'"
rm -rf "$CC/username/gone_20261027-090000"; python3 "$R/lib/ns_vault.py" refresh "$CC" > /dev/null
check "notes for deleted result folders are tidied away" "! ls '$CC'/Results/*gone* >/dev/null 2>&1"
check "bookmarks and saved searches for every case" \
  "grep -q '\"title\": \"chron-case\"' '$W/data/Cases/.obsidian/bookmarks.json' && grep -q 'reportable:true' '$W/data/Cases/Home.md'"
check "reportable chronology entries go into the report" "python3 '$R/lib/ns_vault.py' report-sections '$CC' '$W/rs2' > /dev/null && grep -q '| 2026-10-02 09:15 | Posted from Kingston | platform |' '$W/rs2/findings-section.md'"

section "Telegram (stubbed engine)"
printf '#!/bin/sh\necho "ns_telegram $*" > called.txt\necho "ns_telegram $*"\n' > "$G/ns_telegram"; chmod +x "$G/ns_telegram"
PATH="$G:$PATH" menu ns-telegram "Look up" "https://t.me/s/durov/123"
check "lookup cleans the t.me link" "grep -q 'ns_telegram lookup durov' '$W/out.txt'"
PATH="$G:$PATH" menu ns-telegram "Search a public channel" "@telegram" "update"
check "preview search passes channel and words" "grep -q 'ns_telegram preview-search telegram update' '$W/out.txt'"
PATH="$G:$PATH" menu ns-telegram "Search messages" "@somechan" "" "abc"
check "message search defaults a bad limit to 500" "grep -q 'ns_telegram messages @somechan  500' '$W/out.txt'"
PATH="$G:$PATH" menu ns-telegram "Log in for searches"
check "login refused until API keys are set" "grep -q 'API ID and API hash' '$W/out.txt' && ! grep -q 'ns_telegram login' '$W/out.txt'"
check "Telegram results in the case" "ls -d '$CASE'/telegram/lookup-durov_* >/dev/null"

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
