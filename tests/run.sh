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
cp -R "$R/config/countries" "$H/config/"
for e in breach darkweb evidence doctor; do ln -s "$R/lib/ns_$e.py" "$H/bin/ns_$e"; done
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
