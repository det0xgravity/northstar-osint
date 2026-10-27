# shellcheck shell=bash
# shellcheck disable=SC2034  # variables are used by install.sh and the modules
# =============================================================================
#  northstar-osint — shared installer library
#  Sourced by install.sh and every module. Bash 3.2 compatible (macOS).
# =============================================================================

NS_VERSION="0.28.0"

NS_HOME="${NS_HOME:-$HOME/.local/share/northstar}"   # tools, venvs, sources
NS_BIN="$NS_HOME/bin"                                # all northstar binaries
NS_VENVS="$NS_HOME/venvs"                            # per-tool Python venvs
NS_SRC="$NS_HOME/src"                                # git checkouts
NS_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/northstar"
NS_DATA="${NS_DATA:-$HOME/Northstar}"                # user-facing output root
NS_UPDATE="${NS_UPDATE:-0}"                          # 1 = upgrade existing tools

export PATH="$NS_BIN:$NS_HOME/go/bin:$HOME/.local/bin:$HOME/go/bin:$PATH"

# --- output ------------------------------------------------------------------
if [ -t 1 ]; then
  C_B=$'\033[1m'; C_G=$'\033[32m'; C_Y=$'\033[33m'; C_R=$'\033[31m'; C_0=$'\033[0m'
else
  C_B=""; C_G=""; C_Y=""; C_R=""; C_0=""
fi
ns_info() { printf '    %s\n' "$*"; }
ns_warn() { printf '    %s[!]%s %s\n' "$C_Y" "$C_0" "$*"; }
ns_err()  { printf '%s[x]%s %s\n' "$C_R" "$C_0" "$*" >&2; }
ns_die()  { ns_err "$*"; exit 1; }
ns_has()  { command -v "$1" >/dev/null 2>&1; }
# ns_show_tail <file> — print the end of a failed command's output (into the log)
ns_show_tail() { tail -n 15 "$1" | sed 's/^/        | /'; }

NS_FAILED=()
ns_step() {
  local name="$1" t0 el; shift
  NS_STEP_I=$((NS_STEP_I + 1))
  if [ "$NS_STEP_N" -gt 0 ]; then
    printf '\n%s==>%s [%s/%s] %s %s%s%s\n' "$C_G" "$C_0" "$NS_STEP_I" "$NS_STEP_N" \
      "$(ns_bar $((NS_STEP_I - 1)) "$NS_STEP_N" 18)" "$C_B" "$name" "$C_0"
  else
    printf '\n%s==>%s %s%s%s\n' "$C_G" "$C_0" "$C_B" "$name" "$C_0"
  fi
  t0=$(date +%s)
  if "$@"; then
    el=$(( $(date +%s) - t0 ))
    printf '    %sok%s (%s)\n' "$C_G" "$C_0" "$(_ns_mmss "$el")"
  else
    printf '    %sFAILED%s: %s\n' "$C_R" "$C_0" "$name"
    NS_FAILED+=("$name")
  fi
}

# --- progress ---------------------------------------------------------------------
# install.sh sets NS_TTY=1 and keeps the terminal on fd 4 when it runs in a
# terminal. Status lines are drawn there only, so install.log stays readable.
NS_TTY="${NS_TTY:-0}"
NS_STEP_I=0; NS_STEP_N=0

# ns_bar <done> <total> <width>   a bar of filled and empty blocks
ns_bar() {
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

# ns_bg <log> <label> <command...>   Runs a long command with its output in
# <log>. In a terminal, a status line shows a spinner, the module counter, the
# elapsed time, and a progress bar when the command reports one (pip's raw
# progress, curl's percentage), otherwise its latest output line.
ns_bg() {
  local log="$1" label="$2" pid rc t0 el last pct cur tot n=0 cols spin='|/-\' detail room off f
  shift 2
  [ ${#label} -gt 48 ] && label="${label:0:45}..."
  if [ "$NS_TTY" != 1 ]; then "$@" >>"$log" 2>&1; return $?; fi
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
      detail="$(ns_bar "$pct" 100 20) $(printf '%3d' "$pct")%  ${detail:0:$room}"
    else
      [ "$room" -gt 0 ] || room=0
      detail="${detail:0:$room}"
    fi
    printf '\r\033[K    %s [%s/%s] %s  %s  %s' "${spin:$((n % 4)):1}" "$NS_STEP_I" "$NS_STEP_N" "$label" \
      "$(_ns_mmss "$el")" "$detail" >&4
    n=$((n+1))
    sleep 1
  done
  wait "$pid"; rc=$?
  printf '\r\033[K' >&4
  return $rc
}

# ns_pip <log> <label> <pip> <args...>   pip install with a download bar when
# this pip supports raw progress (24.1+)
ns_pip() {
  local log="$1" label="$2" pip="$3"
  shift 3
  if [ "$NS_TTY" = 1 ] && "$pip" install --help 2>/dev/null | grep -q 'raw'; then
    ns_bg "$log" "$label" "$pip" "$@" --progress-bar raw
  else
    ns_bg "$log" "$label" "$pip" "$@"
  fi
}

# ns_torch_cpu <log> <venv> <package...>   PyTorch's CPU-only build on Linux
# (x86_64 and arm64). PyPI's Linux builds pull in NVIDIA CUDA libraries, over
# 1 GB that a VM can't use. Sets NS_TORCH_PIN to a pip constraints file that
# keeps later installs (GeoCLIP, Argos Translate) on these builds. macOS: PyPI's
# builds are already CPU/Apple GPU only, so nothing to do.
NS_TORCH_PIN=""
ns_torch_cpu() {
  local log="$1" venv="$2" p v
  shift 2
  NS_TORCH_PIN=""
  ns_is_linux || return 0
  ns_pip "$log" "PyTorch (CPU build)" "$venv/bin/pip" install --upgrade "$@" \
    --index-url https://download.pytorch.org/whl/cpu || return 1
  NS_TORCH_PIN="$venv/torch-cpu-constraints.txt"
  : > "$NS_TORCH_PIN"
  for p in "$@"; do
    v=$("$venv/bin/pip" show "$p" 2>/dev/null | sed -n 's/^Version: //p')
    [ -n "$v" ] && printf '%s==%s\n' "$p" "$v" >> "$NS_TORCH_PIN"
  done
}

# ns_download <url> <file> [label]   curl with a progress bar in a terminal
ns_download() {
  local log
  log=$(mktemp)
  if ns_bg "$log" "${3:-download: ${1##*/}}" curl -fL --progress-bar "$1" -o "$2"; then rm -f "$log"; return 0; fi
  ns_show_tail "$log"; rm -f "$log"; return 1
}

# --- platform detection --------------------------------------------------------
# Sets NS_PLATFORM (debian|ubuntu|kali|parrot|macos), NS_ARCH (amd64|arm64),
# NS_PKG (apt|brew), NS_DE (gnome|xfce|mate|kde|other|none).
ns_detect_platform() {
  case "$(uname -m)" in
    x86_64|amd64)  NS_ARCH=amd64 ;;
    aarch64|arm64) NS_ARCH=arm64 ;;
    *) ns_die "Unsupported CPU architecture: $(uname -m)" ;;
  esac

  if [ "$(uname -s)" = "Darwin" ]; then
    [ "$NS_ARCH" = "arm64" ] || ns_die "macOS support is Apple Silicon only."
    NS_PLATFORM=macos; NS_PKG=brew; NS_DE=none
    return 0
  fi

  [ -r /etc/os-release ] || ns_die "Cannot read /etc/os-release."
  # shellcheck disable=SC1091
  . /etc/os-release
  NS_PKG=apt
  case "${ID:-}" in
    debian) NS_PLATFORM=debian ;;
    ubuntu) NS_PLATFORM=ubuntu ;;
    kali)   NS_PLATFORM=kali ;;
    parrot) NS_PLATFORM=parrot ;;
    *)
      case " ${ID_LIKE:-} " in
        *" debian "*|*" ubuntu "*)
          NS_PLATFORM=debian
          ns_warn "Untested distribution '${ID:-unknown}' — treating it as Debian." ;;
        *) ns_die "Unsupported distribution: ${ID:-unknown}" ;;
      esac ;;
  esac
  ns_detect_desktop
}

ns_detect_desktop() {
  local d
  d=$(printf '%s' "${XDG_CURRENT_DESKTOP:-}${DESKTOP_SESSION:-}" | tr '[:upper:]' '[:lower:]')
  case "$d" in
    *gnome*|*ubuntu*) NS_DE=gnome ;;
    *xfce*)           NS_DE=xfce ;;
    *mate*)           NS_DE=mate ;;
    *kde*|*plasma*)   NS_DE=kde ;;
    "")
      if   ns_has gnome-session; then NS_DE=gnome
      elif ns_has startxfce4;    then NS_DE=xfce
      elif ns_has mate-session;  then NS_DE=mate
      elif ns_has startplasma-x11; then NS_DE=kde
      else NS_DE=none; fi ;;
    *) NS_DE=other ;;
  esac
}

ns_is_macos() { [ "$NS_PLATFORM" = "macos" ]; }
ns_is_linux() { [ "$NS_PLATFORM" != "macos" ]; }
ns_in_gnome_session() {
  [ "$NS_DE" = "gnome" ] && [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && ns_has gsettings
}

# --- sudo ----------------------------------------------------------------------
ns_sudo_keepalive() {
  sudo -v || ns_die "sudo is required."
  ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
}

# --- package managers ----------------------------------------------------------
NS_APT_UPDATED=0
ns_apt_update() {
  [ "$NS_APT_UPDATED" = 1 ] && return 0
  ns_bg "${NS_LOG:-/dev/null}" "apt: updating package lists" sudo apt-get update -q && NS_APT_UPDATED=1
}

# Installs packages as a batch; if the batch fails, retries one by one so a
# single missing package (names differ between distros) doesn't sink the rest.
ns_apt() {
  ns_apt_update || return 1
  ns_bg "${NS_LOG:-/dev/null}" "apt: $*" sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$@" && return 0
  local p rc=0
  for p in "$@"; do
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$p" >/dev/null 2>&1 \
      || { ns_warn "apt package unavailable: $p"; rc=1; }
  done
  return $rc
}

ns_brew() {
  local f rc=0
  for f in "$@"; do
    if brew list --formula "$f" >/dev/null 2>&1; then
      [ "$NS_UPDATE" = 1 ] && { brew upgrade "$f" >/dev/null 2>&1 || true; }
    else
      brew install "$f" || { ns_warn "brew formula failed: $f"; rc=1; }
    fi
  done
  return $rc
}

ns_cask() {
  local c rc=0
  for c in "$@"; do
    brew list --cask "$c" >/dev/null 2>&1 && continue
    brew install --cask "$c" || { ns_warn "brew cask failed: $c"; rc=1; }
  done
  return $rc
}

# ns_flatpak <app-id>...   (system-wide, Linux only)
ns_flatpak() {
  ns_has flatpak || return 1
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || return 1
  ns_bg "${NS_LOG:-/dev/null}" "flatpak: $*" sudo flatpak install -y --noninteractive flathub "$@"
}

# --- Python tools ----------------------------------------------------------------

# ns_pipx <command-it-provides> [pip spec]
# Presence is checked by command name because pipx package names and command
# names often differ (sherlock-project -> sherlock). Upgrades happen in bulk via
# 'pipx upgrade-all' in the core module when --update is used.
ns_pipx() {
  local cmd="$1" spec="${2:-$1}"
  if [ -x "$HOME/.local/bin/$cmd" ] || ns_has "$cmd"; then
    ns_info "$cmd ✓"
    return 0
  fi
  local log
  log=$(mktemp)
  if ns_bg "$log" "pipx: $cmd" pipx install "$spec"; then
    ns_info "$cmd installed"
    rm -f "$log"
  else
    ns_warn "pipx failed: $cmd ($spec)"
    ns_show_tail "$log"; rm -f "$log"
    return 1
  fi
}

# ns_git_venv <name> <repo-url> <entry-script> [requirements-file] [cd] [sed-filter]
# Clones a repo, builds a private venv and writes a wrapper into $NS_BIN.
# Pass "cd" as the 5th argument for tools that must run from their own folder.
# A sed -E filter, if given, is applied to the requirements before installing
# (e.g. to lift version caps that an unmaintained project never updated).
ns_git_venv() {
  local name="$1" repo="$2" entry="$3" req="${4:-requirements.txt}" mode="${5:-}" filter="${6:-}"
  local dir="$NS_SRC/$name" venv="$NS_VENVS/$name" reqfile log
  mkdir -p "$NS_SRC" "$NS_VENVS" "$NS_BIN"
  if [ -d "$dir/.git" ]; then
    ns_bg /dev/null "git: $name" git -C "$dir" pull -q --ff-only || ns_warn "$name: git pull failed, keeping current copy"
  else
    ns_bg /dev/null "git: $name" git clone -q --depth 1 "$repo" "$dir" || { ns_warn "$name: clone failed"; return 1; }
  fi
  [ -x "$venv/bin/python" ] || python3 -m venv "$venv" || return 1
  ns_bg /dev/null "pip: $name" "$venv/bin/pip" install -q --upgrade pip
  if [ -f "$dir/$req" ]; then
    reqfile="$dir/$req"
    if [ -n "$filter" ]; then
      reqfile="$venv/requirements.northstar.txt"
      sed -E "$filter" "$dir/$req" > "$reqfile" || return 1
    fi
    log=$(mktemp)
    if ! ns_pip "$log" "pip: $name" "$venv/bin/pip" install -r "$reqfile"; then
      ns_warn "$name: some requirements failed to install"
      ns_show_tail "$log"; rm -f "$log"
      return 1
    fi
    rm -f "$log"
  fi
  {
    echo '#!/usr/bin/env bash'
    echo "# northstar wrapper for $name"
    [ "$mode" = "cd" ] && echo "cd \"$dir\" || exit 1"
    echo "exec \"$venv/bin/python\" \"$dir/$entry\" \"\$@\""
  } > "$NS_BIN/$name"
  chmod +x "$NS_BIN/$name"
  ns_info "$name ✓"
}

# --- Go tools --------------------------------------------------------------------
# Projects like ProjectDiscovery need a recent Go. Use the system Go if it is new
# enough, otherwise fetch the current release into $NS_HOME/go.
ns_go_minor() {
  ns_has go || { echo 0; return; }
  go env GOVERSION 2>/dev/null | sed -E 's/^go1\.([0-9]+).*/\1/' | grep -E '^[0-9]+$' || echo 0
}

# ns_sha256 <file>   prints the file's SHA-256 (Linux sha256sum or macOS shasum)
ns_sha256() {
  if ns_has sha256sum; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

ns_go_ensure() {
  [ "$(ns_go_minor)" -ge 22 ] && return 0
  if ns_is_macos; then ns_brew go; return $?; fi
  local ver file sum tmp
  # go.dev publishes each release's SHA-256: verify before replacing anything
  ver=$(curl -fsSL 'https://go.dev/dl/?mode=json' | jq -r '.[0].version') || return 1
  file="${ver}.linux-${NS_ARCH}.tar.gz"
  sum=$(curl -fsSL 'https://go.dev/dl/?mode=json' | jq -r --arg f "$file" '.[0].files[] | select(.filename == $f) | .sha256')
  [ -n "$sum" ] || { ns_warn "No checksum published for $file"; return 1; }
  ns_info "System Go is missing or too old — installing $ver to $NS_HOME/go"
  tmp=$(mktemp -d)
  ns_download "https://go.dev/dl/$file" "$tmp/go.tgz" "download: Go toolchain" || { rm -rf "$tmp"; return 1; }
  [ "$(ns_sha256 "$tmp/go.tgz")" = "$sum" ] || { ns_warn "Go download failed its checksum: not installed"; rm -rf "$tmp"; return 1; }
  tar -C "$tmp" -xzf "$tmp/go.tgz" || { rm -rf "$tmp"; return 1; }
  mkdir -p "$NS_HOME" && rm -rf "$NS_HOME/go" && mv "$tmp/go" "$NS_HOME/go"
  rm -rf "$tmp"
  hash -r
  [ "$(ns_go_minor)" -ge 22 ]
}

# ns_go <module@version>
ns_go() {
  local name
  name=$(basename "${1%@*}")
  if [ "$NS_UPDATE" != 1 ] && [ -x "$NS_BIN/$name" ]; then ns_info "$name ✓"; return 0; fi
  local log
  log=$(mktemp)
  if ns_bg "$log" "go: $name" env GOBIN="$NS_BIN" go install "$1"; then
    ns_info "$name installed"
    rm -f "$log"
  else
    ns_warn "go install failed: $1"
    ns_show_tail "$log"; rm -f "$log"
    return 1
  fi
}

# --- GitHub release binaries ---------------------------------------------------------
# ns_gh_release <owner/repo> <binary-name> <asset-regex>
# Downloads the newest release asset matching the regex and installs the binary.
# When the release publishes a checksums file, the download must match it.
ns_gh_release() {
  local repo="$1" bin="$2" rx="$3" json url sums tmp f name want
  if [ "$NS_UPDATE" != 1 ] && [ -x "$NS_BIN/$bin" ]; then ns_info "$bin ✓"; return 0; fi
  json=$(curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
         "https://api.github.com/repos/$repo/releases/latest") || { ns_warn "$bin: GitHub API unavailable (rate limit?)"; return 1; }
  url=$(printf '%s' "$json" | jq -r --arg rx "$rx" '.assets[] | select(.name | test($rx; "i")) | .browser_download_url' | head -1)
  sums=$(printf '%s' "$json" | jq -r '.assets[] | select(.name | test("(checksums?|sha256sums?)(\\.txt)?$"; "i")) | .browser_download_url' | head -1)
  [ -n "$url" ] || { ns_warn "$bin: no release asset matched /$rx/"; return 1; }
  tmp=$(mktemp -d)
  ns_download "$url" "$tmp/asset" "download: $bin" || { rm -rf "$tmp"; return 1; }
  if [ -n "$sums" ]; then
    name=${url##*/}
    want=$(curl -fsSL "$sums" | awk -v n="$name" '{ f=$2; sub(/^\*/, "", f) } f == n { print $1; exit }')
    if [ -z "$want" ] || [ "$(ns_sha256 "$tmp/asset")" != "$want" ]; then
      ns_warn "$bin: download doesn't match the release's published checksum — not installed"
      rm -rf "$tmp"; return 1
    fi
  fi
  case "$url" in
    *.zip)            (cd "$tmp" && unzip -q asset) ;;
    *.tar.gz|*.tgz)   tar -C "$tmp" -xzf "$tmp/asset" ;;
    *)                mv "$tmp/asset" "$tmp/$bin" ;;
  esac
  f=$(find "$tmp" -type f -name "$bin" | head -1)
  [ -n "$f" ] || { ns_warn "$bin: binary not found in archive"; rm -rf "$tmp"; return 1; }
  install -m 755 "$f" "$NS_BIN/$bin"
  rm -rf "$tmp"
  ns_info "$bin installed"
}

# --- shell PATH ------------------------------------------------------------------------
ns_path_setup() {
  local rc line='export PATH="$HOME/.local/share/northstar/bin:$HOME/.local/share/northstar/go/bin:$HOME/.local/bin:$PATH"  # northstar-osint'
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    if [ ! -f "$rc" ]; then
      # macOS uses zsh by default; create .zshrc if it doesn't exist yet
      if [ "$rc" = "$HOME/.zshrc" ] && ns_is_macos; then touch "$rc"; else continue; fi
    fi
    grep -q 'northstar-osint' "$rc" || printf '\n%s\n' "$line" >> "$rc"
  done
}

# --- module registry (indexed arrays: bash 3.2 has no associative arrays) ---------
NS_MOD_NAMES=(); NS_MOD_DESCS=(); NS_MOD_PLATS=(); NS_MOD_FUNCS=()

# ns_register <name> <description> <platforms: "linux macos"> <function>
ns_register() {
  NS_MOD_NAMES+=("$1"); NS_MOD_DESCS+=("$2"); NS_MOD_PLATS+=("$3"); NS_MOD_FUNCS+=("$4")
}

ns_mod_supported() {  # ns_mod_supported <platforms-string>
  case " $1 " in
    *" macos "*) ns_is_macos && return 0 ;;
  esac
  case " $1 " in
    *" linux "*) ns_is_linux && return 0 ;;
  esac
  return 1
}
