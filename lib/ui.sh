# shellcheck shell=bash
# =============================================================================
#  truebearing-osint — runtime library for the menu tools
#  Dialogs use zenity on Linux and AppleScript on macOS. Bash 3.2 compatible.
# =============================================================================

TB_HOME="${TB_HOME:-$HOME/.local/share/truebearing}"
TB_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/truebearing"
TB_DATA="${TB_DATA:-${NS_DATA:-$HOME/TrueBearing}}"
TB_TITLE="True Bearing"
export PATH="$TB_HOME/bin:$TB_HOME/go/bin:$HOME/.local/bin:$HOME/go/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

ui_mac() { [ "$(uname -s)" = "Darwin" ]; }
tb_cmd() { command -v "$1" >/dev/null 2>&1; }

# Escape a string for use inside an AppleScript "quoted string"
_as_q() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# --- dialogs -------------------------------------------------------------------
# ui_list "Prompt" "Option 1" "Option 2" ...   -> prints the chosen option
ui_list() {
  local prompt="$1" r items="" i h; shift
  if ui_mac; then
    for i in "$@"; do items="$items\"$(_as_q "$i")\","; done
    r=$(osascript -e "choose from list {${items%,}} with title \"$TB_TITLE\" with prompt \"$(_as_q "$prompt")\"" 2>/dev/null) || return 1
    [ "$r" = "false" ] && return 1
  else
    h=$((170 + 30 * $#)); [ $h -gt 640 ] && h=640
    r=$(zenity --list --title="$TB_TITLE" --text="$prompt" --column="Option" \
          --width=540 --height=$h "$@" 2>/dev/null) || return 1
  fi
  [ -n "$r" ] || return 1
  printf '%s\n' "$r"
}

# tb_ocr_langs <image>   -> the Tesseract languages for this image, e.g. "rus+ukr+eng".
# Tesseract's script detection (OSD) picks the writing system; only installed
# languages of that script are used, plus English, which signs often add.
# Passing every installed language at once is slow and less accurate.
tb_ocr_langs() {
  local have script want l out=""
  have=$(tesseract --list-langs 2>/dev/null | tail -n +2)
  script=""
  if printf '%s\n' "$have" | grep -qx osd; then
    script=$(tesseract "$1" - --psm 0 -l osd 2>/dev/null | sed -n 's/^Script: //p' | head -1)
  fi
  case "$script" in
    Cyrillic)   want="rus ukr" ;;
    Arabic)     want="ara fas" ;;
    Hebrew)     want="heb" ;;
    Greek)      want="ell" ;;
    Devanagari) want="hin" ;;
    Thai)       want="tha" ;;
    Han)        want="chi_sim chi_tra" ;;
    Japanese|Katakana|Hiragana) want="jpn" ;;
    Hangul)     want="kor" ;;
    *)          want="eng fra deu spa por ita nld" ;;   # Latin, or too little text to tell
  esac
  for l in $want eng; do
    printf '%s\n' "$have" | grep -qx "$l" || continue
    case "+$out+" in *"+$l+"*) ;; *) out="${out:+$out+}$l" ;; esac
  done
  printf '%s\n' "${out:-eng}"
}

# ui_entry "Prompt" ["default"]   -> prints the text entered (fails on cancel/empty;
#                                    with TB_ALLOW_EMPTY=1 only cancel fails)
ui_entry() {
  local r
  if ui_mac; then
    r=$(osascript -e "text returned of (display dialog \"$(_as_q "$1")\" default answer \"$(_as_q "${2:-}")\" with title \"$TB_TITLE\")" 2>/dev/null) || return 1
  else
    r=$(zenity --entry --title="$TB_TITLE" --width=460 --text="$1" --entry-text="${2:-}" 2>/dev/null) || return 1
  fi
  r=$(printf '%s' "$r" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  [ -n "$r" ] || [ -n "${TB_ALLOW_EMPTY:-}" ] || return 1
  printf '%s\n' "$r"
}

# ui_secret "Prompt"   -> text typed with hidden input (passwords, API keys)
ui_secret() {
  local r
  if ui_mac; then
    r=$(osascript -e "text returned of (display dialog \"$(_as_q "$1")\" default answer \"\" with hidden answer with title \"$TB_TITLE\")" 2>/dev/null) || return 1
  else
    r=$(zenity --entry --hide-text --title="$TB_TITLE" --width=460 --text="$1" 2>/dev/null) || return 1
  fi
  [ -n "$r" ] || return 1
  printf '%s\n' "$r"
}

ui_info() {
  if ui_mac; then
    osascript -e "display dialog \"$(_as_q "$1")\" buttons {\"OK\"} default button 1 with title \"$TB_TITLE\"" >/dev/null 2>&1
  else
    zenity --info --no-markup --title="$TB_TITLE" --width=480 --text="$1" 2>/dev/null
  fi
}

ui_error() {
  if ui_mac; then
    osascript -e "display dialog \"$(_as_q "$1")\" buttons {\"OK\"} default button 1 with icon stop with title \"$TB_TITLE\"" >/dev/null 2>&1
  else
    zenity --error --no-markup --title="$TB_TITLE" --width=440 --text="$1" 2>/dev/null
  fi
}

ui_question() {   # returns 0 for Yes
  if ui_mac; then
    [ "$(osascript -e "button returned of (display dialog \"$(_as_q "$1")\" buttons {\"No\",\"Yes\"} default button \"Yes\" with title \"$TB_TITLE\")" 2>/dev/null)" = "Yes" ]
  else
    zenity --question --no-markup --title="$TB_TITLE" --width=440 --text="$1" 2>/dev/null
  fi
}

# ui_files "Prompt"   -> newline-separated paths (multiple selection)
ui_files() {
  if ui_mac; then
    osascript -e "set fs to choose file with prompt \"$(_as_q "$1")\" with multiple selections allowed" \
              -e 'set out to ""' -e 'repeat with f in fs' \
              -e 'set out to out & POSIX path of f & linefeed' -e 'end repeat' -e 'return out' 2>/dev/null
  else
    zenity --file-selection --multiple --separator=$'\n' --title="$1" 2>/dev/null
  fi
}

# ui_dir "Prompt"   -> a folder path
ui_dir() {
  if ui_mac; then
    osascript -e "POSIX path of (choose folder with prompt \"$(_as_q "$1")\")" 2>/dev/null
  else
    zenity --file-selection --directory --title="$1" 2>/dev/null
  fi
}

# --- browser, clipboard, files -------------------------------------------------------
# _ui_detach CMD...  Starts a GUI program in its own session, so it survives
# the menu's terminal closing (which would otherwise kill it with SIGHUP).
_ui_detach() {
  if tb_cmd setsid; then
    setsid -f "$@" >/dev/null 2>&1 </dev/null
  else
    # same as setsid -f: the child detaches before this call returns
    python3 -c 'import os, sys
if os.fork() == 0:
    os.setsid()
    os.execvp(sys.argv[1], sys.argv[1:])' "$@" >/dev/null 2>&1 </dev/null
  fi
}

# ui_open URL...   Opens all URLs as tabs (Firefox preferred).
ui_open() {
  [ $# -gt 0 ] || return 0
  if ui_mac; then
    if [ -d "/Applications/Firefox.app" ]; then open -a Firefox "$@"; else open "$@"; fi
  elif tb_cmd firefox; then
    _ui_detach firefox "$@"
  elif tb_cmd firefox-esr; then
    _ui_detach firefox-esr "$@"
  else
    local u; for u in "$@"; do _ui_detach xdg-open "$u"; done
  fi
}

# Clipboard helpers can block: wl-copy on GNOME waits to grab focus because
# mutter lacks the data-control protocol. So prefer xclip (works through
# XWayland on GNOME, and under xrdp), cap each attempt at 3 seconds, and keep
# the background clipboard owner off our stdout/stderr.
_ui_clip_run() {
  if tb_cmd timeout; then timeout 3 "$@"; else "$@"; fi
}
ui_clip() {
  if ui_mac; then printf '%s' "$1" | pbcopy
  elif [ -n "${DISPLAY:-}" ] && tb_cmd xclip; then
    printf '%s' "$1" | _ui_clip_run xclip -selection clipboard >/dev/null 2>&1
  elif [ -n "${WAYLAND_DISPLAY:-}" ] && tb_cmd wl-copy; then
    printf '%s' "$1" | _ui_clip_run wl-copy >/dev/null 2>&1
  fi
  return 0
}

# ui_notify "Message" — a desktop notification. Notifications are drawn above
# all windows, unlike dialogs, which a browser opening a moment later covers.
ui_notify() {
  if ui_mac; then
    osascript -e "display notification \"$(_as_q "$1")\" with title \"$TB_TITLE\"" >/dev/null 2>&1
  elif tb_cmd notify-send; then
    notify-send -a "$TB_TITLE" "$TB_TITLE" "$1" >/dev/null 2>&1
  fi
  return 0
}

ui_reveal() {
  if ui_mac; then open "$1"; else _ui_detach xdg-open "$1"; fi
}

# --- helpers ---------------------------------------------------------------------
tb_enc()    { python3 -c 'import sys,urllib.parse;print(urllib.parse.quote_plus(sys.argv[1]))' "$1"; }
tb_google() { echo "https://www.google.com/search?q=$(tb_enc "$1")"; }
tb_lower()  { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
tb_upper()  { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }
tb_slug()   { printf '%s' "$1" | tr -c 'A-Za-z0-9._@-' '_' | cut -c1-60; }

# --- API keys ----------------------------------------------------------------------
# One NAME=value per line in ~/.config/truebearing/keys.env, mode 600. Read by the
# Python engines directly; keys never go on a command line or into audit.log.
TB_KEYS="$TB_CONF/keys.env"
export TB_KEYS                       # the engines (tb_breach) read keys from here
tb_key_get() { grep -m1 "^$1=" "$TB_KEYS" 2>/dev/null | cut -d= -f2-; }

# tb_key_set NAME VALUE   (an empty VALUE removes the key)
tb_key_set() {
  local tmp
  ( umask 077; mkdir -p "$TB_CONF" )
  tmp=$(mktemp "$TB_CONF/.keys.XXXXXX") || return 1      # mktemp files are mode 600
  grep -v "^$1=" "$TB_KEYS" > "$tmp" 2>/dev/null
  [ -n "$2" ] && printf '%s=%s\n' "$1" "$2" >> "$tmp"
  mv "$tmp" "$TB_KEYS"
}

# --- cases & audit trail --------------------------------------------------------------
# Output for every search lands in ~/TrueBearing/Cases/<active case>/, and every
# action is appended to that case's audit.log (tab-separated).
tb_case() {
  local c
  c=$(cat "$TB_CONF/active_case" 2>/dev/null)
  printf '%s\n' "${c:-general}"
}

# Case data is private: folders are created mode 700 (only you can read them)
tb_case_dir() {
  local d
  d="$TB_DATA/Cases/$(tb_case)"
  ( umask 077; mkdir -p "$d" )
  chmod 700 "$TB_DATA" "$TB_DATA/Cases" "$d" 2>/dev/null
  printf '%s\n' "$d"
}

tb_set_case() {
  mkdir -p "$TB_CONF"
  tb_slug "$1" > "$TB_CONF/active_case"
  ( umask 077; mkdir -p "$TB_DATA/Cases/$(tb_case)" )
}

# tb_outdir <kind> <target>   -> creates and prints a timestamped result folder
tb_outdir() {
  local d
  d="$(tb_case_dir)/$1/$(tb_slug "$2")_$(date +%Y%m%d-%H%M%S)"
  ( umask 077; mkdir -p "$d" )
  printf '%s\n' "$d"
}

# tb_hash_str <text>   SHA-256 of a string (Linux sha256sum or macOS shasum)
tb_hash_str() {
  if tb_cmd sha256sum; then printf '%s' "$1" | sha256sum | cut -d' ' -f1
  else printf '%s' "$1" | shasum -a 256 | cut -d' ' -f1; fi
}

_ns_field() { printf '%s' "$1" | tr '\t\n\r' '   '; }      # one TSV field: no tabs/newlines

# tb_audit <tool> <target> <detail>
# Appends: UTC time, case, tool, target, detail, operator, chain hash. The hash
# is SHA-256(previous line + this line's other fields), so editing, inserting or
# deleting any line breaks every hash after it (tb-evidence verifies the chain).
tb_audit() {
  local log body prev
  log="$(tb_case_dir)/audit.log"
  body=$(printf '%s\t%s\t%s\t%s\t%s\t%s' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$(tb_case)" \
    "$(_ns_field "$1")" "$(_ns_field "$2")" "$(_ns_field "$3")" "$(id -un)")
  prev=""
  [ -s "$log" ] && prev=$(tail -n 1 "$log")
  printf '%s\t%s\n' "$body" "$(tb_hash_str "$prev$body")" >> "$log"
}

# tb_run <outdir> <command> [args...]
# Runs a command inside the result folder, echoes it, logs it and keeps console output.
tb_run() {
  local out="$1"; shift
  if ! tb_cmd "$1"; then
    printf '  [skip] %s is not installed\n' "$1" | tee -a "$out/console.log"
    return 127
  fi
  printf '\n\033[1m▶ %s\033[0m\n' "$*"
  printf '▶ %s\n' "$*" >> "$out/console.log"     # which tool printed what follows (for the case notes)
  tb_audit "$1" "$(basename "$out")" "$*"
  printf '%s\n' "$1" >> "$out/.tb-tools"          # provenance.json lists each tool's version
  ( cd "$out" && "$@" ) 2>&1 | tee -a "$out/console.log"
  return "${PIPESTATUS[0]}"
}

# tb_seal_result <outdir>   hash every file into manifest.sha256 + provenance.json
tb_seal_result() {
  tb_cmd tb_evidence || return 0
  [ -f "$1/manifest.sha256" ] && return 0      # sealed once: an exhibit's fingerprint must stay valid
  tb_evidence seal "$1" "$(cat "$TB_HOME/VERSION" 2>/dev/null || echo unknown)" 2>/dev/null \
    && tb_audit tb-evidence "$(basename "$1")" "sealed: $(tb_hash_file "$1/manifest.sha256")"
}

# tb_hash_file <file>
tb_hash_file() {
  if tb_cmd sha256sum; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

# tb_finish <outdir> — shows where results went and keeps a launched terminal open.
# From the main menu the folder isn't opened: GNOME would put the file manager
# in front and open the menu's next dialog behind it, which looks like a hang.
tb_finish() {
  printf '\n\033[1mResults saved to:\033[0m %s\n' "$1"
  tb_seal_result "$1"
  tb_cmd tb_vault && tb_vault result "$(tb_case_dir)" "$1" >/dev/null 2>&1   # listed in the case's Results.md
  mkdir -p "$TB_CONF" && printf '%s\n' "$1" > "$TB_CONF/last_result"
  if [ "${TB_FROM_MAIN:-0}" = 1 ]; then
    printf 'Back to the True Bearing menu: choose "Open latest results" to see them.\n'
  else
    ui_reveal "$1"
  fi
  tb_pause
}

tb_pause() {
  [ "${TB_FROM_MAIN:-0}" = 1 ] && return 0
  [ -t 0 ] || return 0
  printf '\nPress Enter to close… '
  read -r _
}

# --- scripted dialogs (tests and CI) ---------------------------------------------------
# TB_UI=script TB_UI_ANSWERS=<file>: every dialog takes the next line of the file
# (an empty line cancels; "<default>" accepts an entry's pre-filled value)
# instead of asking. ui_list picks the first option starting with that line;
# ui_question takes y/yes as yes; a missing line cancels. Browser, clipboard,
# notification and folder actions are logged to stderr and not performed.
if [ "${TB_UI:-}" = script ]; then
  _ui_next() {
    local n line
    n=$(cat "$TB_UI_ANSWERS.pos" 2>/dev/null || echo 1)
    line=$(sed -n "${n}p" "$TB_UI_ANSWERS")
    echo $((n + 1)) > "$TB_UI_ANSWERS.pos"
    [ -n "$line" ] || return 1
    printf '%s\n' "$line"
  }
  ui_list() {
    local want o; shift
    want=$(_ui_next) || return 1
    for o in "$@"; do case "$o" in "$want"*) printf '%s\n' "$o"; return 0 ;; esac; done
    return 1
  }
  ui_entry()    { local a; a=$(_ui_next) || return 1; [ "$a" = "<default>" ] && a="${2:-}"; [ "$a" = "<empty>" ] && a=""; printf '%s\n' "$a"; }
  ui_secret()   { _ui_next; }
  ui_files()    { _ui_next; }
  ui_dir()      { _ui_next; }
  ui_question() { case "$(_ui_next)" in y|Y|yes|Yes) return 0 ;; esac; return 1; }
  ui_info()     { printf '[ui_info] %s\n' "$1" >&2; }
  ui_error()    { printf '[ui_error] %s\n' "$1" >&2; }
  ui_open()     { printf '[ui_open] %s\n' "$@" >&2; }
  ui_clip()     { printf '[ui_clip] %s\n' "$1" >&2; }
  ui_notify()   { printf '[ui_notify] %s\n' "$1" >&2; }
  ui_reveal()   { printf '[ui_reveal] %s\n' "$1" >&2; }
fi
