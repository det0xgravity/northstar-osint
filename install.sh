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
  --version        Print the version and exit
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
    --version)
      printf 'northstar-osint %s%s\n' "$NS_VERSION" "$(git -C "$NS_REPO" describe --always --dirty 2>/dev/null | sed 's/^/ (/; s/$/)/')"
      exit 0 ;;
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

is_module() {
  local m
  for m in "${NS_MOD_NAMES[@]}"; do [ "$m" = "$1" ] && return 0; done
  return 1
}

# Validate module names given to --only / --skip
for n in $(printf '%s' "$ONLY,$SKIP" | tr ',' ' '); do
  is_module "$n" || ns_die "Unknown module: $n (see --list)"
done

# The installer records the modules the user chose NOT to install. Updates run
# everything else, so modules added in a new release get installed too.
SKIPPED_FILE="$NS_CONF/skipped"
HAVE_STATE=0; SAVED_SKIP=""
if [ -f "$SKIPPED_FILE" ]; then
  HAVE_STATE=1
  for n in $(tr ',' ' ' < "$SKIPPED_FILE"); do
    is_module "$n" && SAVED_SKIP="${SAVED_SKIP:+$SAVED_SKIP,}$n"   # drop modules that no longer exist
  done
elif [ -s "$NS_CONF/modules" ]; then
  # v0.2 and earlier recorded the installed modules instead
  HAVE_STATE=1
  installed=$(cat "$NS_CONF/modules")
  i=0
  while [ $i -lt ${#NS_MOD_NAMES[@]} ]; do
    n="${NS_MOD_NAMES[$i]}"
    if [ "$n" != core ] && ns_mod_supported "${NS_MOD_PLATS[$i]}" && ! in_csv "$n" "$installed"; then
      SAVED_SKIP="${SAVED_SKIP:+$SAVED_SKIP,}$n"
    fi
    i=$((i+1))
  done
fi
if [ "$NS_UPDATE" = 1 ] && [ -z "$ONLY" ] && [ -z "$SKIP" ]; then
  SKIP="$SAVED_SKIP"
fi

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
# Status lines (lib/common.sh: ns_bg) are drawn on the terminal itself, fd 4,
# so they never clutter install.log
if [ -t 1 ]; then NS_TTY=1; exec 4>&1; fi
NS_LOG="$LOG"
NS_STEP_N=${#RUN_IDX[@]}
exec > >(tee -a "$LOG") 2>&1
echo "=== $(date) — northstar $NS_VERSION on $NS_PLATFORM ==="

ns_sudo_keepalive

for i in "${RUN_IDX[@]}"; do
  ns_step "${NS_MOD_NAMES[$i]}: ${NS_MOD_DESCS[$i]}" "${NS_MOD_FUNCS[$i]}"
done

# Remember which modules the user chose not to install. A module counts as
# skipped when it didn't run and: this is the first install (--only/--skip
# picked the set), it was skipped before, or --skip named it outside an update.
# Anything that ran is no longer skipped.
new_skip=""
i=0
while [ $i -lt ${#NS_MOD_NAMES[@]} ]; do
  n="${NS_MOD_NAMES[$i]}"
  ran=0
  for j in "${RUN_IDX[@]}"; do [ "$j" = "$i" ] && ran=1; done
  if [ $ran = 0 ] && [ "$n" != core ] && ns_mod_supported "${NS_MOD_PLATS[$i]}"; then
    if [ $HAVE_STATE = 0 ] || in_csv "$n" "$SAVED_SKIP" \
       || { [ "$NS_UPDATE" != 1 ] && in_csv "$n" "$SKIP"; }; then
      new_skip="${new_skip:+$new_skip,}$n"
    fi
  fi
  i=$((i+1))
done
printf '%s\n' "$new_skip" > "$SKIPPED_FILE"
rm -f "$NS_CONF/modules"

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
