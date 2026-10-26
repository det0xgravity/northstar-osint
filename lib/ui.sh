# shellcheck shell=bash
# =============================================================================
#  northstar-osint — runtime library for the menu tools
#  Dialogs use zenity on Linux and AppleScript on macOS. Bash 3.2 compatible.
# =============================================================================

NS_HOME="${NS_HOME:-$HOME/.local/share/northstar}"
NS_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/northstar"
NS_DATA="${NS_DATA:-$HOME/Northstar}"
NS_TITLE="Northstar"
export PATH="$NS_HOME/bin:$NS_HOME/go/bin:$HOME/.local/bin:$HOME/go/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

ui_mac() { [ "$(uname -s)" = "Darwin" ]; }
ns_cmd() { command -v "$1" >/dev/null 2>&1; }

# Escape a string for use inside an AppleScript "quoted string"
_as_q() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# --- dialogs -------------------------------------------------------------------
# ui_list "Prompt" "Option 1" "Option 2" ...   -> prints the chosen option
ui_list() {
  local prompt="$1" r items="" i h; shift
  if ui_mac; then
    for i in "$@"; do items="$items\"$(_as_q "$i")\","; done
    r=$(osascript -e "choose from list {${items%,}} with title \"$NS_TITLE\" with prompt \"$(_as_q "$prompt")\"" 2>/dev/null) || return 1
    [ "$r" = "false" ] && return 1
  else
    h=$((170 + 30 * $#)); [ $h -gt 640 ] && h=640
    r=$(zenity --list --title="$NS_TITLE" --text="$prompt" --column="Option" \
          --width=540 --height=$h "$@" 2>/dev/null) || return 1
  fi
  [ -n "$r" ] || return 1
  printf '%s\n' "$r"
}

# ui_entry "Prompt" ["default"]   -> prints the text entered (fails on cancel/empty)
ui_entry() {
  local r
  if ui_mac; then
    r=$(osascript -e "text returned of (display dialog \"$(_as_q "$1")\" default answer \"$(_as_q "${2:-}")\" with title \"$NS_TITLE\")" 2>/dev/null) || return 1
  else
    r=$(zenity --entry --title="$NS_TITLE" --width=460 --text="$1" --entry-text="${2:-}" 2>/dev/null) || return 1
  fi
  r=$(printf '%s' "$r" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  [ -n "$r" ] || return 1
  printf '%s\n' "$r"
}

# ui_secret "Prompt"   -> text typed with hidden input (passwords, API keys)
ui_secret() {
  local r
  if ui_mac; then
    r=$(osascript -e "text returned of (display dialog \"$(_as_q "$1")\" default answer \"\" with hidden answer with title \"$NS_TITLE\")" 2>/dev/null) || return 1
  else
    r=$(zenity --entry --hide-text --title="$NS_TITLE" --width=460 --text="$1" 2>/dev/null) || return 1
  fi
  [ -n "$r" ] || return 1
  printf '%s\n' "$r"
}

ui_info() {
  if ui_mac; then
    osascript -e "display dialog \"$(_as_q "$1")\" buttons {\"OK\"} default button 1 with title \"$NS_TITLE\"" >/dev/null 2>&1
  else
    zenity --info --no-markup --title="$NS_TITLE" --width=480 --text="$1" 2>/dev/null
  fi
}

ui_error() {
  if ui_mac; then
    osascript -e "display dialog \"$(_as_q "$1")\" buttons {\"OK\"} default button 1 with icon stop with title \"$NS_TITLE\"" >/dev/null 2>&1
  else
    zenity --error --no-markup --title="$NS_TITLE" --width=440 --text="$1" 2>/dev/null
  fi
}

ui_question() {   # returns 0 for Yes
  if ui_mac; then
    [ "$(osascript -e "button returned of (display dialog \"$(_as_q "$1")\" buttons {\"No\",\"Yes\"} default button \"Yes\" with title \"$NS_TITLE\")" 2>/dev/null)" = "Yes" ]
  else
    zenity --question --no-markup --title="$NS_TITLE" --width=440 --text="$1" 2>/dev/null
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
  if ns_cmd setsid; then
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
  elif ns_cmd firefox; then
    _ui_detach firefox "$@"
  elif ns_cmd firefox-esr; then
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
  if ns_cmd timeout; then timeout 3 "$@"; else "$@"; fi
}
ui_clip() {
  if ui_mac; then printf '%s' "$1" | pbcopy
  elif [ -n "${DISPLAY:-}" ] && ns_cmd xclip; then
    printf '%s' "$1" | _ui_clip_run xclip -selection clipboard >/dev/null 2>&1
  elif [ -n "${WAYLAND_DISPLAY:-}" ] && ns_cmd wl-copy; then
    printf '%s' "$1" | _ui_clip_run wl-copy >/dev/null 2>&1
  fi
  return 0
}

# ui_notify "Message" — a desktop notification. Notifications are drawn above
# all windows, unlike dialogs, which a browser opening a moment later covers.
ui_notify() {
  if ui_mac; then
    osascript -e "display notification \"$(_as_q "$1")\" with title \"$NS_TITLE\"" >/dev/null 2>&1
  elif ns_cmd notify-send; then
    notify-send -a "$NS_TITLE" "$NS_TITLE" "$1" >/dev/null 2>&1
  fi
  return 0
}

ui_reveal() {
  if ui_mac; then open "$1"; else _ui_detach xdg-open "$1"; fi
}

# --- helpers ---------------------------------------------------------------------
ns_enc()    { python3 -c 'import sys,urllib.parse;print(urllib.parse.quote_plus(sys.argv[1]))' "$1"; }
ns_google() { echo "https://www.google.com/search?q=$(ns_enc "$1")"; }
ns_lower()  { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
ns_upper()  { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }
ns_slug()   { printf '%s' "$1" | tr -c 'A-Za-z0-9._@-' '_' | cut -c1-60; }

# --- API keys ----------------------------------------------------------------------
# One NAME=value per line in ~/.config/northstar/keys.env, mode 600. Read by the
# Python engines directly; keys never go on a command line or into audit.log.
NS_KEYS="$NS_CONF/keys.env"
export NS_KEYS                       # the engines (ns_breach) read keys from here
ns_key_get() { grep -m1 "^$1=" "$NS_KEYS" 2>/dev/null | cut -d= -f2-; }

# ns_key_set NAME VALUE   (an empty VALUE removes the key)
ns_key_set() {
  local tmp
  ( umask 077; mkdir -p "$NS_CONF" )
  tmp=$(mktemp "$NS_CONF/.keys.XXXXXX") || return 1      # mktemp files are mode 600
  grep -v "^$1=" "$NS_KEYS" > "$tmp" 2>/dev/null
  [ -n "$2" ] && printf '%s=%s\n' "$1" "$2" >> "$tmp"
  mv "$tmp" "$NS_KEYS"
}

# --- cases & audit trail --------------------------------------------------------------
# Output for every search lands in ~/Northstar/Cases/<active case>/, and every
# action is appended to that case's audit.log (tab-separated).
ns_case() {
  local c
  c=$(cat "$NS_CONF/active_case" 2>/dev/null)
  printf '%s\n' "${c:-general}"
}

# Case data is private: folders are created mode 700 (only you can read them)
ns_case_dir() {
  local d
  d="$NS_DATA/Cases/$(ns_case)"
  ( umask 077; mkdir -p "$d" )
  chmod 700 "$NS_DATA" "$NS_DATA/Cases" "$d" 2>/dev/null
  printf '%s\n' "$d"
}

ns_set_case() {
  mkdir -p "$NS_CONF"
  ns_slug "$1" > "$NS_CONF/active_case"
  ( umask 077; mkdir -p "$NS_DATA/Cases/$(ns_case)" )
}

# ns_outdir <kind> <target>   -> creates and prints a timestamped result folder
ns_outdir() {
  local d
  d="$(ns_case_dir)/$1/$(ns_slug "$2")_$(date +%Y%m%d-%H%M%S)"
  ( umask 077; mkdir -p "$d" )
  printf '%s\n' "$d"
}

# ns_audit <tool> <target> <detail>
ns_audit() {
  printf '%s\t%s\t%s\t%s\t%s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "$(ns_case)" \
    "$1" "$2" "$3" >> "$(ns_case_dir)/audit.log"
}

# ns_run <outdir> <command> [args...]
# Runs a command inside the result folder, echoes it, logs it and keeps console output.
ns_run() {
  local out="$1"; shift
  if ! ns_cmd "$1"; then
    printf '  [skip] %s is not installed\n' "$1" | tee -a "$out/console.log"
    return 127
  fi
  printf '\n\033[1m▶ %s\033[0m\n' "$*"
  ns_audit "$1" "$(basename "$out")" "$*"
  ( cd "$out" && "$@" ) 2>&1 | tee -a "$out/console.log"
  return "${PIPESTATUS[0]}"
}

# ns_finish <outdir> — shows where results went and keeps a launched terminal open.
# From the main menu the folder isn't opened: GNOME would put the file manager
# in front and open the menu's next dialog behind it, which looks like a hang.
ns_finish() {
  printf '\n\033[1mResults saved to:\033[0m %s\n' "$1"
  mkdir -p "$NS_CONF" && printf '%s\n' "$1" > "$NS_CONF/last_result"
  if [ "${NS_FROM_MAIN:-0}" = 1 ]; then
    printf 'Back to the Northstar menu: choose "Open latest results" to see them.\n'
  else
    ui_reveal "$1"
  fi
  ns_pause
}

ns_pause() {
  [ "${NS_FROM_MAIN:-0}" = 1 ] && return 0
  [ -t 0 ] || return 0
  printf '\nPress Enter to close… '
  read -r _
}
