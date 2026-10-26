# shellcheck shell=bash
# shellcheck disable=SC2034  # variables are used by install.sh and the modules
# =============================================================================
#  northstar-osint — shared installer library
#  Sourced by install.sh and every module. Bash 3.2 compatible (macOS).
# =============================================================================

NS_VERSION="0.3.1"

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
  local name="$1"; shift
  printf '\n%s==>%s %s%s%s\n' "$C_G" "$C_0" "$C_B" "$name" "$C_0"
  if "$@"; then
    printf '    %sok%s\n' "$C_G" "$C_0"
  else
    printf '    %sFAILED%s: %s\n' "$C_R" "$C_0" "$name"
    NS_FAILED+=("$name")
  fi
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
  sudo apt-get update -q && NS_APT_UPDATED=1
}

# Installs packages as a batch; if the batch fails, retries one by one so a
# single missing package (names differ between distros) doesn't sink the rest.
ns_apt() {
  ns_apt_update || return 1
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$@" && return 0
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
  sudo flatpak install -y --noninteractive flathub "$@"
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
  if pipx install "$spec" >"$log" 2>&1; then
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
    git -C "$dir" pull -q --ff-only || ns_warn "$name: git pull failed, keeping current copy"
  else
    git clone -q --depth 1 "$repo" "$dir" || { ns_warn "$name: clone failed"; return 1; }
  fi
  [ -x "$venv/bin/python" ] || python3 -m venv "$venv" || return 1
  "$venv/bin/pip" install -q --upgrade pip >/dev/null 2>&1
  if [ -f "$dir/$req" ]; then
    reqfile="$dir/$req"
    if [ -n "$filter" ]; then
      reqfile="$venv/requirements.northstar.txt"
      sed -E "$filter" "$dir/$req" > "$reqfile" || return 1
    fi
    log=$(mktemp)
    if ! "$venv/bin/pip" install -q -r "$reqfile" >"$log" 2>&1; then
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

ns_go_ensure() {
  [ "$(ns_go_minor)" -ge 22 ] && return 0
  if ns_is_macos; then ns_brew go; return $?; fi
  local ver os="linux" tmp
  ver=$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -1) || return 1
  ns_info "System Go is missing or too old — installing $ver to $NS_HOME/go"
  tmp=$(mktemp -d)
  curl -fsSL "https://go.dev/dl/${ver}.${os}-${NS_ARCH}.tar.gz" -o "$tmp/go.tgz" || { rm -rf "$tmp"; return 1; }
  rm -rf "$NS_HOME/go" && mkdir -p "$NS_HOME"
  tar -C "$NS_HOME" -xzf "$tmp/go.tgz"
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
  if GOBIN="$NS_BIN" go install "$1" >"$log" 2>&1; then
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
ns_gh_release() {
  local repo="$1" bin="$2" rx="$3" url tmp f
  if [ "$NS_UPDATE" != 1 ] && [ -x "$NS_BIN/$bin" ]; then ns_info "$bin ✓"; return 0; fi
  url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | jq -r --arg rx "$rx" '.assets[] | select(.name | test($rx; "i")) | .browser_download_url' \
        | head -1)
  [ -n "$url" ] || { ns_warn "$bin: no release asset matched /$rx/"; return 1; }
  tmp=$(mktemp -d)
  curl -fsSL "$url" -o "$tmp/asset" || { rm -rf "$tmp"; return 1; }
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
