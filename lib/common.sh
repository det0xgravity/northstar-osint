# shellcheck shell=bash
# shellcheck disable=SC2034  # variables are used by install.sh and the modules
# =============================================================================
#  truebearing-osint — shared installer library
#  Sourced by install.sh and every module. Bash 3.2 compatible (macOS).
# =============================================================================

TB_VERSION="0.41.3"

TB_HOME="${TB_HOME:-$HOME/.local/share/truebearing}"   # tools, venvs, sources
TB_BIN="$TB_HOME/bin"                                # all True Bearing binaries
TB_VENVS="$TB_HOME/venvs"                            # per-tool Python venvs
TB_SRC="$TB_HOME/src"                                # git checkouts
TB_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/truebearing"
TB_DATA="${TB_DATA:-${NS_DATA:-$HOME/TrueBearing}}"  # user-facing output root (NS_DATA: before v0.41)
TB_UPDATE="${TB_UPDATE:-0}"                          # 1 = upgrade existing tools

export PATH="$TB_BIN:$TB_HOME/go/bin:$HOME/.local/bin:$HOME/go/bin:$PATH"

# --- output ------------------------------------------------------------------
if [ -t 1 ]; then
  C_B=$'\033[1m'; C_G=$'\033[32m'; C_Y=$'\033[33m'; C_R=$'\033[31m'; C_0=$'\033[0m'
else
  C_B=""; C_G=""; C_Y=""; C_R=""; C_0=""
fi
tb_info() { printf '    %s\n' "$*"; }
tb_warn() { printf '    %s[!]%s %s\n' "$C_Y" "$C_0" "$*"; }
tb_err()  { printf '%s[x]%s %s\n' "$C_R" "$C_0" "$*" >&2; }
tb_die()  { tb_err "$*"; exit 1; }
tb_has()  { command -v "$1" >/dev/null 2>&1; }
# tb_show_tail <file> — print the end of a failed command's output (into the log)
tb_show_tail() { tail -n 15 "$1" | sed 's/^/        | /'; }

TB_FAILED=()
tb_step() {
  local name="$1" t0 el; shift
  TB_STEP_I=$((TB_STEP_I + 1))
  if [ "$TB_STEP_N" -gt 0 ]; then
    printf '\n%s==>%s [%s/%s] %s %s%s%s\n' "$C_G" "$C_0" "$TB_STEP_I" "$TB_STEP_N" \
      "$(tb_bar $((TB_STEP_I - 1)) "$TB_STEP_N" 18)" "$C_B" "$name" "$C_0"
  else
    printf '\n%s==>%s %s%s%s\n' "$C_G" "$C_0" "$C_B" "$name" "$C_0"
  fi
  t0=$(date +%s)
  if "$@"; then
    el=$(( $(date +%s) - t0 ))
    printf '    %sok%s (%s)\n' "$C_G" "$C_0" "$(_ns_mmss "$el")"
  else
    printf '    %sFAILED%s: %s\n' "$C_R" "$C_0" "$name"
    TB_FAILED+=("$name")
  fi
}

# --- progress ---------------------------------------------------------------------
# install.sh sets TB_TTY=1 and keeps the terminal on fd 4 when it runs in a
# terminal. Status lines are drawn there only, so install.log stays readable.
TB_TTY="${TB_TTY:-0}"
TB_STEP_I=0; TB_STEP_N=0

# tb_bar <done> <total> <width>   a bar of filled and empty blocks
tb_bar() {
  local d="$1" t="$2" w="$3" f i=0 out=""
  [ "$t" -gt 0 ] 2>/dev/null || t=1
  f=$(( d * w / t )); [ "$f" -gt "$w" ] && f=$w
  while [ $i -lt "$w" ]; do
    if [ $i -lt $f ]; then out="$out█"; else out="$out░"; fi
    i=$((i+1))
  done
  printf '%s' "$out"
}

_ns_mmss() { printf '%02d:%02d' $(( $1 / 60 )) $(( $1 % 60 )); }

# tb_bg <log> <label> <command...>   Runs a long command with its output in
# <log>. In a terminal, a status line shows a spinner, the module counter, the
# elapsed time, and a progress bar when the command reports one (pip's raw
# progress, curl's percentage), otherwise its latest output line.
tb_bg() {
  local log="$1" label="$2" pid rc t0 el last pct cur tot n=0 cols spin='|/-\' detail room off f
  shift 2
  [ ${#label} -gt 48 ] && label="${label:0:45}..."
  if [ "$TB_TTY" != 1 ]; then "$@" >>"$log" 2>&1; return $?; fi
  cols=$(tput cols 2>/dev/null || echo 100); [ "$cols" -gt 20 ] 2>/dev/null || cols=100
  off=1; [ -f "$log" ] && off=$(( $(wc -c < "$log") + 1 ))   # read only what this command writes
  "$@" >>"$log" 2>&1 </dev/null &
  pid=$!
  t0=$(date +%s)
  while kill -0 "$pid" 2>/dev/null; do
    el=$(( $(date +%s) - t0 ))
    last=$(tail -c +"$off" "$log" 2>/dev/null | tail -c 4000 | tr '\r' '\n' | LC_ALL=C sed $'s/\033\\[[0-9;?]*[A-Za-z]//g' | awk 'NF' | tail -n 3)
    pct=""
    cur=$(printf '%s\n' "$last" | sed -n 's/^Progress \([0-9]*\) of \([0-9]*\).*/\1 \2/p' | tail -1)
    if [ -n "$cur" ]; then
      tot=${cur#* }; cur=${cur% *}
      [ "$tot" -gt 0 ] 2>/dev/null && pct=$(( cur * 100 / tot ))
      f=$(tail -c +"$off" "$log" | tail -n 300 | sed -n 's#^ *Downloading \([^ ]*/\)\{0,1\}\([^/ ]*\) (\(.*\))#\2|\3#p' | tail -1)
      detail=""; [ -n "$f" ] && { detail=${f%%|*}; detail="${detail%%-[0-9]*} (${f#*|})"; }
    else
      detail=$(printf '%s\n' "$last" | tail -1)
      pct=$(printf '%s' "$detail" | sed -n -E 's/(^|.*[^0-9.])([0-9]{1,3})(\.[0-9]+)?%.*/\2/p')
      [ -n "$pct" ] && printf '%s' "$detail" | grep -q '^[#= O-]*[0-9. ]*%' && detail=""
    fi
    room=$(( cols - ${#label} - 24 ))
    if [ -n "$pct" ] && [ "$pct" -le 100 ] 2>/dev/null; then
      room=$(( room - 27 ))
      [ "$room" -gt 0 ] || room=0
      detail="$(tb_bar "$pct" 100 20) $(printf '%3d' "$pct")%  ${detail:0:$room}"
    else
      [ "$room" -gt 0 ] || room=0
      detail="${detail:0:$room}"
    fi
    printf '\r\033[K    %s [%s/%s] %s  %s  %s' "${spin:$((n % 4)):1}" "$TB_STEP_I" "$TB_STEP_N" "$label" \
      "$(_ns_mmss "$el")" "$detail" >&4
    n=$((n+1))
    sleep 1
  done
  wait "$pid"; rc=$?
  printf '\r\033[K' >&4
  return $rc
}

# tb_pip <log> <label> <pip> <args...>   pip install with a download bar when
# this pip supports raw progress (24.1+)
tb_pip() {
  local log="$1" label="$2" pip="$3"
  shift 3
  if [ "$TB_TTY" = 1 ] && "$pip" install --help 2>/dev/null | grep -q 'raw'; then
    tb_bg "$log" "$label" "$pip" "$@" --progress-bar raw
  else
    tb_bg "$log" "$label" "$pip" "$@"
  fi
}

# tb_torch_cpu <log> <venv> <package...>   PyTorch's CPU-only build on Linux
# (x86_64 and arm64). PyPI's Linux builds pull in NVIDIA CUDA libraries, over
# 1 GB that a VM can't use. Sets TB_TORCH_PIN to a pip constraints file that
# keeps later installs (GeoCLIP, Argos Translate) on these builds. macOS: PyPI's
# builds are already CPU/Apple GPU only, so nothing to do.
TB_TORCH_PIN=""
tb_torch_cpu() {
  local log="$1" venv="$2" p v
  shift 2
  TB_TORCH_PIN=""
  tb_is_linux || return 0
  tb_pip "$log" "PyTorch (CPU build)" "$venv/bin/pip" install --upgrade "$@" \
    --index-url https://download.pytorch.org/whl/cpu || return 1
  TB_TORCH_PIN="$venv/torch-cpu-constraints.txt"
  : > "$TB_TORCH_PIN"
  for p in "$@"; do
    v=$("$venv/bin/pip" show "$p" 2>/dev/null | sed -n 's/^Version: //p')
    [ -n "$v" ] && printf '%s==%s\n' "$p" "$v" >> "$TB_TORCH_PIN"
  done
}

# tb_download <url> <file> [label]   curl with a progress bar in a terminal
tb_download() {
  local log
  log=$(mktemp)
  if tb_bg "$log" "${3:-download: ${1##*/}}" curl -fL --progress-bar "$1" -o "$2"; then rm -f "$log"; return 0; fi
  tb_show_tail "$log"; rm -f "$log"; return 1
}

# --- platform detection --------------------------------------------------------
# Sets TB_PLATFORM (debian|ubuntu|kali|parrot|macos), TB_ARCH (amd64|arm64),
# TB_PKG (apt|brew), TB_DE (gnome|xfce|mate|kde|other|none).
tb_detect_platform() {
  case "$(uname -m)" in
    x86_64|amd64)  TB_ARCH=amd64 ;;
    aarch64|arm64) TB_ARCH=arm64 ;;
    *) tb_die "Unsupported CPU architecture: $(uname -m)" ;;
  esac

  if [ "$(uname -s)" = "Darwin" ]; then
    [ "$TB_ARCH" = "arm64" ] || tb_die "macOS support is Apple Silicon only."
    TB_PLATFORM=macos; TB_PKG=brew; TB_DE=none
    return 0
  fi

  [ -r /etc/os-release ] || tb_die "Cannot read /etc/os-release."
  # shellcheck disable=SC1091
  . /etc/os-release
  TB_PKG=apt
  case "${ID:-}" in
    debian) TB_PLATFORM=debian ;;
    ubuntu) TB_PLATFORM=ubuntu ;;
    kali)   TB_PLATFORM=kali ;;
    parrot) TB_PLATFORM=parrot ;;
    *)
      case " ${ID_LIKE:-} " in
        *" debian "*|*" ubuntu "*)
          TB_PLATFORM=debian
          tb_warn "Untested distribution '${ID:-unknown}' — treating it as Debian." ;;
        *) tb_die "Unsupported distribution: ${ID:-unknown}" ;;
      esac ;;
  esac
  tb_detect_desktop
}

tb_detect_desktop() {
  local d
  d=$(printf '%s' "${XDG_CURRENT_DESKTOP:-}${DESKTOP_SESSION:-}" | tr '[:upper:]' '[:lower:]')
  case "$d" in
    *gnome*|*ubuntu*) TB_DE=gnome ;;
    *xfce*)           TB_DE=xfce ;;
    *mate*)           TB_DE=mate ;;
    *kde*|*plasma*)   TB_DE=kde ;;
    "")
      if   tb_has gnome-session; then TB_DE=gnome
      elif tb_has startxfce4;    then TB_DE=xfce
      elif tb_has mate-session;  then TB_DE=mate
      elif tb_has startplasma-x11; then TB_DE=kde
      else TB_DE=none; fi ;;
    *) TB_DE=other ;;
  esac
}

tb_is_macos() { [ "$TB_PLATFORM" = "macos" ]; }
tb_is_linux() { [ "$TB_PLATFORM" != "macos" ]; }
tb_in_gnome_session() {
  [ "$TB_DE" = "gnome" ] && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && tb_has gsettings
}

# --- sudo ----------------------------------------------------------------------
tb_sudo_keepalive() {
  sudo -v || tb_die "sudo is required."
  ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
}

# --- package managers ----------------------------------------------------------
TB_APT_UPDATED=0
tb_apt_update() {
  [ "$TB_APT_UPDATED" = 1 ] && return 0
  tb_bg "${TB_LOG:-/dev/null}" "apt: updating package lists" sudo apt-get update -q && TB_APT_UPDATED=1
}

# Installs packages as a batch; if the batch fails, retries one by one so a
# single missing package (names differ between distros) doesn't sink the rest.
tb_apt() {
  tb_apt_update || return 1
  tb_bg "${TB_LOG:-/dev/null}" "apt: $*" sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$@" && return 0
  local p rc=0
  for p in "$@"; do
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$p" >/dev/null 2>&1 \
      || { tb_warn "apt package unavailable: $p"; rc=1; }
  done
  return $rc
}

tb_brew() {
  local f rc=0
  for f in "$@"; do
    if brew list --formula "$f" >/dev/null 2>&1; then
      [ "$TB_UPDATE" = 1 ] && { brew upgrade "$f" >/dev/null 2>&1 || true; }
    else
      brew install "$f" || { tb_warn "brew formula failed: $f"; rc=1; }
    fi
  done
  return $rc
}

tb_cask() {
  local c rc=0
  for c in "$@"; do
    brew list --cask "$c" >/dev/null 2>&1 && continue
    brew install --cask "$c" || { tb_warn "brew cask failed: $c"; rc=1; }
  done
  return $rc
}

# tb_flatpak <app-id>...   (system-wide, Linux only)
tb_flatpak() {
  tb_has flatpak || return 1
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || return 1
  tb_bg "${TB_LOG:-/dev/null}" "flatpak: $*" sudo flatpak install -y --noninteractive flathub "$@"
}

# --- Python tools ----------------------------------------------------------------

# tb_pipx <command-it-provides> [pip spec]
# Presence is checked by command name because pipx package names and command
# names often differ (sherlock-project -> sherlock). Upgrades happen in bulk via
# 'pipx upgrade-all' in the core module when --update is used.
tb_pipx() {
  local cmd="$1" spec="${2:-$1}"
  if [ -x "$HOME/.local/bin/$cmd" ] || tb_has "$cmd"; then
    tb_info "$cmd ✓"
    return 0
  fi
  local log
  log=$(mktemp)
  if tb_bg "$log" "pipx: $cmd" pipx install "$spec"; then
    tb_info "$cmd installed"
    rm -f "$log"
  else
    tb_warn "pipx failed: $cmd ($spec)"
    tb_show_tail "$log"; rm -f "$log"
    return 1
  fi
}

# tb_git_venv <name> <repo-url> <entry-script> [requirements-file] [cd] [sed-filter]
# Clones a repo, builds a private venv and writes a wrapper into $TB_BIN.
# Pass "cd" as the 5th argument for tools that must run from their own folder.
# A sed -E filter, if given, is applied to the requirements before installing
# (e.g. to lift version caps that an unmaintained project never updated).
tb_git_venv() {
  local name="$1" repo="$2" entry="$3" req="${4:-requirements.txt}" mode="${5:-}" filter="${6:-}"
  local dir="$TB_SRC/$name" venv="$TB_VENVS/$name" reqfile log
  mkdir -p "$TB_SRC" "$TB_VENVS" "$TB_BIN"
  if [ -d "$dir/.git" ]; then
    tb_bg /dev/null "git: $name" git -C "$dir" pull -q --ff-only || tb_warn "$name: git pull failed, keeping current copy"
  else
    tb_bg /dev/null "git: $name" git clone -q --depth 1 "$repo" "$dir" || { tb_warn "$name: clone failed"; return 1; }
  fi
  [ -x "$venv/bin/python" ] || python3 -m venv "$venv" || return 1
  tb_bg /dev/null "pip: $name" "$venv/bin/pip" install -q --upgrade pip
  if [ -f "$dir/$req" ]; then
    reqfile="$dir/$req"
    if [ -n "$filter" ]; then
      reqfile="$venv/requirements.truebearing.txt"
      sed -E "$filter" "$dir/$req" > "$reqfile" || return 1
    fi
    log=$(mktemp)
    if ! tb_pip "$log" "pip: $name" "$venv/bin/pip" install -r "$reqfile"; then
      tb_warn "$name: some requirements failed to install"
      tb_show_tail "$log"; rm -f "$log"
      return 1
    fi
    rm -f "$log"
  fi
  {
    echo '#!/usr/bin/env bash'
    echo "# True Bearing wrapper for $name"
    [ "$mode" = "cd" ] && echo "cd \"$dir\" || exit 1"
    echo "exec \"$venv/bin/python\" \"$dir/$entry\" \"\$@\""
  } > "$TB_BIN/$name"
  chmod +x "$TB_BIN/$name"
  tb_info "$name ✓"
}

# --- Go tools --------------------------------------------------------------------
# Projects like ProjectDiscovery need a recent Go. Use the system Go if it is new
# enough, otherwise fetch the current release into $TB_HOME/go.
tb_go_minor() {
  tb_has go || { echo 0; return; }
  go env GOVERSION 2>/dev/null | sed -E 's/^go1\.([0-9]+).*/\1/' | grep -E '^[0-9]+$' || echo 0
}

# tb_sha256 <file>   prints the file's SHA-256 (Linux sha256sum or macOS shasum)
tb_sha256() {
  if tb_has sha256sum; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

tb_go_ensure() {
  [ "$(tb_go_minor)" -ge 22 ] && return 0
  if tb_is_macos; then tb_brew go; return $?; fi
  local ver file sum tmp
  # go.dev publishes each release's SHA-256: verify before replacing anything
  ver=$(curl -fsSL 'https://go.dev/dl/?mode=json' | jq -r '.[0].version') || return 1
  file="${ver}.linux-${TB_ARCH}.tar.gz"
  sum=$(curl -fsSL 'https://go.dev/dl/?mode=json' | jq -r --arg f "$file" '.[0].files[] | select(.filename == $f) | .sha256')
  [ -n "$sum" ] || { tb_warn "No checksum published for $file"; return 1; }
  tb_info "System Go is missing or too old — installing $ver to $TB_HOME/go"
  tmp=$(mktemp -d)
  tb_download "https://go.dev/dl/$file" "$tmp/go.tgz" "download: Go toolchain" || { rm -rf "$tmp"; return 1; }
  [ "$(tb_sha256 "$tmp/go.tgz")" = "$sum" ] || { tb_warn "Go download failed its checksum: not installed"; rm -rf "$tmp"; return 1; }
  tar -C "$tmp" -xzf "$tmp/go.tgz" || { rm -rf "$tmp"; return 1; }
  mkdir -p "$TB_HOME" && rm -rf "$TB_HOME/go" && mv "$tmp/go" "$TB_HOME/go"
  rm -rf "$tmp"
  hash -r
  [ "$(tb_go_minor)" -ge 22 ]
}

# tb_go <module@version>
tb_go() {
  local name
  name=$(basename "${1%@*}")
  if [ "$TB_UPDATE" != 1 ] && [ -x "$TB_BIN/$name" ]; then tb_info "$name ✓"; return 0; fi
  local log
  log=$(mktemp)
  if tb_bg "$log" "go: $name" env GOBIN="$TB_BIN" go install "$1"; then
    tb_info "$name installed"
    rm -f "$log"
  else
    tb_warn "go install failed: $1"
    tb_show_tail "$log"; rm -f "$log"
    return 1
  fi
}

# --- GitHub release binaries ---------------------------------------------------------
# tb_gh_release <owner/repo> <binary-name> <asset-regex>
# Downloads the newest release asset matching the regex and installs the binary.
# When the release publishes a checksums file, the download must match it.
tb_gh_release() {
  local repo="$1" bin="$2" rx="$3" json url sums tmp f name want
  if [ "$TB_UPDATE" != 1 ] && [ -x "$TB_BIN/$bin" ]; then tb_info "$bin ✓"; return 0; fi
  json=$(curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
         "https://api.github.com/repos/$repo/releases/latest") || { tb_warn "$bin: GitHub API unavailable (rate limit?)"; return 1; }
  url=$(printf '%s' "$json" | jq -r --arg rx "$rx" '.assets[] | select(.name | test($rx; "i")) | .browser_download_url' | head -1)
  sums=$(printf '%s' "$json" | jq -r '.assets[] | select(.name | test("(checksums?|sha256sums?)(\\.txt)?$"; "i")) | .browser_download_url' | head -1)
  [ -n "$url" ] || { tb_warn "$bin: no release asset matched /$rx/"; return 1; }
  tmp=$(mktemp -d)
  tb_download "$url" "$tmp/asset" "download: $bin" || { rm -rf "$tmp"; return 1; }
  if [ -n "$sums" ]; then
    name=${url##*/}
    want=$(curl -fsSL "$sums" | awk -v n="$name" '{ f=$2; sub(/^\*/, "", f) } f == n { print $1; exit }')
    if [ -z "$want" ] || [ "$(tb_sha256 "$tmp/asset")" != "$want" ]; then
      tb_warn "$bin: download doesn't match the release's published checksum — not installed"
      rm -rf "$tmp"; return 1
    fi
  fi
  case "$url" in
    *.zip)            (cd "$tmp" && unzip -q asset) ;;
    *.tar.gz|*.tgz)   tar -C "$tmp" -xzf "$tmp/asset" ;;
    *)                mv "$tmp/asset" "$tmp/$bin" ;;
  esac
  f=$(find "$tmp" -type f -name "$bin" | head -1)
  [ -n "$f" ] || { tb_warn "$bin: binary not found in archive"; rm -rf "$tmp"; return 1; }
  install -m 755 "$f" "$TB_BIN/$bin"
  rm -rf "$tmp"
  tb_info "$bin installed"
}

# --- shell PATH ------------------------------------------------------------------------
tb_path_setup() {
  local rc line='export PATH="$HOME/.local/share/truebearing/bin:$HOME/.local/share/truebearing/go/bin:$HOME/.local/bin:$PATH"  # truebearing-osint'
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ ! -f "$rc" ]; then
      # macOS uses zsh by default; create .zshrc if it doesn't exist yet
      if [ "$rc" = "$HOME/.zshrc" ] && tb_is_macos; then touch "$rc"; else continue; fi
    fi
    grep -q 'truebearing-osint' "$rc" || printf '\n%s\n' "$line" >> "$rc"
  done
}

# --- the rename from northstar to True Bearing (v0.41) ---------------------------------
# Existing installs move across on their next update. Folders are moved, not
# copied, and the old path is left as a link to the new one, so anything that
# still names it (Python venvs, paths in earlier notes and exports) keeps
# working. Safe to run on every install: each step only acts on what's there.

# tb_migrate_dirs: before anything reads the configuration (no sudo)
tb_migrate_dirs() {
  local old new pair
  for pair in "$HOME/.local/share/northstar|$TB_HOME" \
              "${XDG_CONFIG_HOME:-$HOME/.config}/northstar|$TB_CONF" \
              "$HOME/Northstar|$TB_DATA"; do
    old=${pair%%|*}; new=${pair#*|}
    [ -d "$old" ] && [ ! -L "$old" ] || continue
    [ "$old" = "$new" ] && continue
    if [ -e "$new" ]; then
      tb_warn "Both $old and $new exist: left as they are. Move anything you need from the old one by hand."
      continue
    fi
    mkdir -p "$(dirname "$new")"
    mv "$old" "$new" && ln -s "$new" "$old" && tb_info "Moved $old → $new (the old path links to it)"
  done
}

# tb_migrate_legacy: the rest, once sudo is available. LAN isolation is moved
# by the lan module, so the old rules stay on until the new ones replace them.
tb_migrate_legacy() {
  local rc f d hours schema kp list
  # Shell setup: the PATH line, and the markers that let updates find their blocks
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.p10k.zsh"; do
    [ -f "$rc" ] && grep -q 'northstar' "$rc" || continue
    sed -e 's#/\.local/share/northstar/#/.local/share/truebearing/#g' \
        -e 's/northstar-osint/truebearing-osint/g' \
        -e 's/^# \([A-Za-z ]*\) (northstar):/# \1 (truebearing):/' \
        -e "s/^# northstar won't overwrite/# True Bearing won't overwrite/" "$rc" > "$rc.tbtmp" \
      && cat "$rc.tbtmp" > "$rc" && rm -f "$rc.tbtmp" && tb_info "Updated ~/${rc##*/} for the new name"
  done
  # Each case's private state folder
  for d in "$TB_DATA"/Cases/*/.northstar; do
    [ -d "$d" ] && [ ! -e "${d%/.northstar}/.truebearing" ] && mv "$d" "${d%/.northstar}/.truebearing"
  done
  for f in "$TB_DATA/Cases/.obsidian/snippets/northstar.css" "$TB_DATA/Cases/.obsidian/snippets/northstar-hide-raw.css" \
           "$TB_DATA/northstar-bookmarks.html"; do
    rm -f "$f"
  done
  # A Telegram research-account login
  for f in "$TB_CONF"/telegram/northstar.session*; do
    [ -f "$f" ] && mv "$f" "$TB_CONF/telegram/truebearing${f##*/northstar}"
  done
  [ -f "$TB_HOME/tor-browser/.northstar-channel" ] && mv "$TB_HOME/tor-browser/.northstar-channel" "$TB_HOME/tor-browser/.truebearing-channel"
  # Scheduled page monitoring keeps its interval
  if tb_is_macos; then
    f="$HOME/Library/LaunchAgents/org.northstar.watch.plist"
    if [ -f "$f" ]; then
      launchctl unload "$f" >/dev/null 2>&1
      sed -e 's/org\.northstar\.watch/org.truebearing.watch/; s#/northstar/bin/ns-watch#/truebearing/bin/tb-watch#; s#/\.config/northstar/#/.config/truebearing/#g' \
        "$f" > "$HOME/Library/LaunchAgents/org.truebearing.watch.plist" && rm -f "$f"
      launchctl load "$HOME/Library/LaunchAgents/org.truebearing.watch.plist" >/dev/null 2>&1
    fi
    return 0
  fi
  d="$HOME/.config/systemd/user"
  if [ -f "$d/northstar-watch.timer" ]; then
    hours=$(sed -n 's/^OnUnitActiveSec=\([0-9]*\)h$/\1/p' "$d/northstar-watch.timer")
    systemctl --user disable --now northstar-watch.timer >/dev/null 2>&1
    rm -f "$d/northstar-watch.timer" "$d/northstar-watch.service"
    printf '[Unit]\nDescription=True Bearing page monitoring\n\n[Service]\nType=oneshot\nExecStart=%s --scheduled\n' \
      "$TB_BIN/tb-watch" > "$d/truebearing-watch.service"
    printf '[Unit]\nDescription=True Bearing page monitoring every %s hours\n\n[Timer]\nOnBootSec=10min\nOnUnitActiveSec=%sh\nPersistent=true\n\n[Install]\nWantedBy=timers.target\n' \
      "${hours:-6}" "${hours:-6}" > "$d/truebearing-watch.timer"
    systemctl --user daemon-reload >/dev/null 2>&1 && systemctl --user enable --now truebearing-watch.timer >/dev/null 2>&1
    tb_info "Scheduled page monitoring moved to truebearing-watch.timer"
  fi
  # Print Screen → Flameshot: the extras module adds the binding under its new name
  if tb_in_gnome_session; then
    schema="org.gnome.settings-daemon.plugins.media-keys"
    kp="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/northstar-flameshot/"
    list=$(gsettings get "$schema" custom-keybindings 2>/dev/null)
    case "$list" in
      *"$kp"*)
        list=$(printf '%s' "$list" | sed "s#'$kp'##; s/\[, /[/; s/, ,/,/; s/, \]/]/")
        case "$list" in "[]"|"") list="@as []" ;; esac
        gsettings set "$schema" custom-keybindings "$list" >/dev/null 2>&1
        tb_has dconf && dconf reset -f "$kp" >/dev/null 2>&1 ;;
    esac
  fi
  # System files with the old name
  [ -f /etc/brave/policies/managed/northstar.json ] && sudo rm -f /etc/brave/policies/managed/northstar.json
  [ -f /etc/polkit-1/rules.d/45-northstar-xrdp-colord.rules ] && sudo rm -f /etc/polkit-1/rules.d/45-northstar-xrdp-colord.rules
  for f in northstar-ssh-hostkeys northstar-xrdp-keys; do
    [ -f "/etc/systemd/system/$f.service" ] || continue
    sudo systemctl disable "$f.service" >/dev/null 2>&1
    sudo rm -f "/etc/systemd/system/$f.service"
  done
  return 0
}

# --- module registry (indexed arrays: bash 3.2 has no associative arrays) ---------
TB_MOD_NAMES=(); TB_MOD_DESCS=(); TB_MOD_PLATS=(); TB_MOD_FUNCS=()

# tb_register <name> <description> <platforms: "linux macos"> <function>
tb_register() {
  TB_MOD_NAMES+=("$1"); TB_MOD_DESCS+=("$2"); TB_MOD_PLATS+=("$3"); TB_MOD_FUNCS+=("$4")
}

tb_mod_supported() {  # tb_mod_supported <platforms-string>
  case " $1 " in
    *" macos "*) tb_is_macos && return 0 ;;
  esac
  case " $1 " in
    *" linux "*) tb_is_linux && return 0 ;;
  esac
  return 1
}
