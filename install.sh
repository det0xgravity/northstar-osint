#!/usr/bin/env bash
# =============================================================================
#  northstar-osint installer
#  https://github.com/det0xgravity/northstar-osint
#
#  Builds an OSINT workstation on Debian 13, Ubuntu 24.04, Kali, Parrot or
#  macOS (Apple Silicon). Modular, idempotent and safe to re-run.
#
#  Usage:  ./install.sh [--list] [--only a,b] [--skip a,b] [--update] [--yes]
#  Run as your normal user. It asks for sudo only when needed.
# =============================================================================

set -uo pipefail

NS_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$NS_REPO/lib/common.sh"

usage() {
  cat <<EOF
northstar-osint $NS_VERSION

Usage: ./install.sh [options]

  --list           List modules and exit
  --only a,b,c     Install only these modules (core always runs)
  --skip a,b,c     Install everything except these modules
  --update         Upgrade tools that are already installed
  --yes            Don't ask for confirmation
  -h, --help       Show this help

Examples:
  ./install.sh                         # everything supported on this platform
  ./install.sh --only username,domain  # just those two modules
  ./install.sh --skip frameworks,vm    # everything except those
  ./install.sh --update --yes          # unattended upgrade (used by ns-update)
EOF
}

ONLY=""; SKIP=""; ASSUME_YES=0; LIST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --list)    LIST=1 ;;
    --only)    ONLY="${2:-}"; shift ;;
    --only=*)  ONLY="${1#*=}" ;;
    --skip)    SKIP="${2:-}"; shift ;;
    --skip=*)  SKIP="${1#*=}" ;;
    --update)  NS_UPDATE=1 ;;
    --yes|-y)  ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) ns_err "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done
export NS_UPDATE

ns_detect_platform

# Load modules in filename order; each one calls ns_register.
for m in "$NS_REPO"/modules/*.sh; do
  # shellcheck disable=SC1090
  . "$m"
done

if [ "$LIST" = 1 ]; then
  printf '%-12s %-14s %s\n' MODULE PLATFORMS DESCRIPTION
  i=0
  while [ $i -lt ${#NS_MOD_NAMES[@]} ]; do
    printf '%-12s %-14s %s\n' "${NS_MOD_NAMES[$i]}" "${NS_MOD_PLATS[$i]}" "${NS_MOD_DESCS[$i]}"
    i=$((i+1))
  done
  exit 0
fi

[ "$(id -u)" -eq 0 ] && ns_die "Run as your normal user, not root or sudo. You'll be asked for sudo when needed."

in_csv() { case ",$2," in *",$1,"*) return 0 ;; esac; return 1; }

# Updates default to the modules installed previously (recorded below)
if [ "$NS_UPDATE" = 1 ] && [ -z "$ONLY" ] && [ -z "$SKIP" ] && [ -s "$NS_CONF/modules" ]; then
  ONLY=$(cat "$NS_CONF/modules")
fi

# Validate module names given to --only / --skip
for n in $(printf '%s' "$ONLY,$SKIP" | tr ',' ' '); do
  found=0
  for m in "${NS_MOD_NAMES[@]}"; do [ "$m" = "$n" ] && found=1; done
  [ $found = 1 ] || ns_die "Unknown module: $n (see --list)"
done

# Build the run list
RUN_IDX=()
i=0
while [ $i -lt ${#NS_MOD_NAMES[@]} ]; do
  n="${NS_MOD_NAMES[$i]}"
  if ns_mod_supported "${NS_MOD_PLATS[$i]}"; then
    if [ "$n" = "core" ]; then
      RUN_IDX+=("$i")
    elif [ -n "$ONLY" ]; then
      in_csv "$n" "$ONLY" && RUN_IDX+=("$i")
    elif ! in_csv "$n" "$SKIP"; then
      RUN_IDX+=("$i")
    fi
  fi
  i=$((i+1))
done

echo "${C_B}northstar-osint $NS_VERSION${C_0}"
echo "  Platform : $NS_PLATFORM ($NS_ARCH)${NS_DE:+, desktop: $NS_DE}"
echo "  Mode     : $([ "$NS_UPDATE" = 1 ] && echo update || echo install)"
printf '  Modules  :'
for i in "${RUN_IDX[@]}"; do printf ' %s' "${NS_MOD_NAMES[$i]}"; done
echo

# --- platform prerequisites ---------------------------------------------------------
if ns_is_macos; then
  xcode-select -p >/dev/null 2>&1 || ns_die "Install the Xcode Command Line Tools first:  xcode-select --install"
  if ! ns_has brew; then
    [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  ns_has brew || ns_die "Homebrew is required. Install it from https://brew.sh and re-run."
fi

if [ "$ASSUME_YES" != 1 ]; then
  printf '\nContinue? [Y/n] '
  read -r ans
  case "$ans" in [Nn]*) exit 0 ;; esac
fi

mkdir -p "$NS_CONF" "$NS_HOME" "$NS_DATA"
LOG="$NS_CONF/install.log"
exec > >(tee -a "$LOG") 2>&1
echo "=== $(date) — northstar $NS_VERSION on $NS_PLATFORM ==="

ns_sudo_keepalive

for i in "${RUN_IDX[@]}"; do
  ns_step "${NS_MOD_NAMES[$i]}: ${NS_MOD_DESCS[$i]}" "${NS_MOD_FUNCS[$i]}"
done

# Remember which modules are installed so 'ns-update' upgrades the same set
saved=$(cat "$NS_CONF/modules" 2>/dev/null)
for i in "${RUN_IDX[@]}"; do
  in_csv "${NS_MOD_NAMES[$i]}" "$saved" || saved="${saved:+$saved,}${NS_MOD_NAMES[$i]}"
done
printf '%s\n' "$saved" > "$NS_CONF/modules"

echo
echo "============================================================"
if [ ${#NS_FAILED[@]} -eq 0 ]; then
  echo " ${C_G}All modules completed.${C_0}"
else
  echo " ${C_Y}Completed with problems in:${C_0}"
  for f in "${NS_FAILED[@]}"; do echo "   - $f"; done
  echo " Full log: $LOG"
  echo " Re-running is safe; see docs/TROUBLESHOOTING.md."
fi
echo
echo " Open a new terminal (to pick up PATH), then run:  northstar"
ns_is_linux && echo " Log out and back in so new launchers appear in your menu."
echo "============================================================"
[ ${#NS_FAILED[@]} -eq 0 ]
