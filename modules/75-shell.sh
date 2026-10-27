# shellcheck shell=bash
# shell — zsh as the login shell with Oh My Zsh, the Powerlevel10k prompt,
# autosuggestions and syntax highlighting, plus the MesloLGS NF font that
# Powerlevel10k's icons need, set in the common terminals. Linux only: on a
# Mac, northstar leaves your shell and ~/.zshrc alone.

ns_register shell "zsh + Oh My Zsh + Powerlevel10k prompt and font" "linux" mod_shell

NS_OMZ="$HOME/.oh-my-zsh"
NS_FONT_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"
NS_TERM_FONT="MesloLGS NF 11"
# Default plugin list, and the defaults of earlier versions: an existing
# ~/.zshrc whose plugin line is one of those is upgraded in place.
NS_ZSH_PLUGINS="plugins=(git sudo colored-man-pages fzf z dirhistory web-search urltools encode64 jsontools extract copypath copyfile copybuffer command-not-found fzf-tab zsh-autosuggestions zsh-syntax-highlighting history-substring-search)"
NS_ZSH_PLUGINS_OLD="plugins=(git sudo colored-man-pages zsh-autosuggestions zsh-syntax-highlighting)
plugins=(git sudo colored-man-pages fzf z web-search urltools encode64 jsontools extract copypath copyfile copybuffer command-not-found zsh-autosuggestions zsh-syntax-highlighting)"

# Blocks inserted after "source $ZSH/oh-my-zsh.sh". Each block's first line
# identifies it, so it's only added once.
NS_ZSH_BLOCK_CLIP=$(cat <<'EOF'
# Copy plugins (copypath, copyfile, copybuffer) use Oh My Zsh's clipcopy, which
# prefers wl-copy; on GNOME that can hang. Use xclip when an X display exists.
if [[ -n $DISPLAY ]] && (( $+commands[xclip] )); then
  clipcopy() { xclip -selection clipboard -in < "${1:-/dev/stdin}" >/dev/null 2>&1 }
fi
EOF
)
NS_ZSH_BLOCK_NAV=$(cat <<'EOF'
# Navigation (northstar): eza instead of ls, fzf-tab previews, ranger
zstyle ':completion:*' menu no                    # fzf-tab draws the completion menu
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath 2>/dev/null'
if (( $+commands[eza] )); then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -lh --icons=auto --group-directories-first --git'
  alias la='eza -lah --icons=auto --group-directories-first --git'
  alias lt='eza --tree --level=2 --icons=auto'
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=always --color=always $realpath'
fi
# r: browse with ranger; when you quit, the terminal stays in the folder you were in
r() {
  local f d; f=$(mktemp)
  ranger --choosedir="$f" "$@"
  d=$(cat -- "$f" 2>/dev/null); rm -f -- "$f"
  [[ -d $d && $d != "$PWD" ]] && cd -- "$d"
}
EOF
)

# ns_git_sync <repo-url> <dir>   clone once, pull on --update
ns_git_sync() {
  if [ -d "$2/.git" ]; then
    [ "$NS_UPDATE" = 1 ] && { git -C "$2" pull -q --ff-only || ns_warn "$(basename "$2"): git pull failed"; }
    return 0
  fi
  ns_bg /dev/null "git: $(basename "$2")" git clone -q --depth 1 "$1" "$2" || { ns_warn "clone failed: $1"; return 1; }
}

ns_shell_fonts() {
  local dir="$HOME/.local/share/fonts/MesloLGS-NF" f n=0
  mkdir -p "$dir"
  for f in "Regular" "Bold" "Italic" "Bold Italic"; do
    [ -s "$dir/MesloLGS NF $f.ttf" ] && continue
    curl -fsSL "$NS_FONT_URL/MesloLGS%20NF%20$(printf '%s' "$f" | sed 's/ /%20/g').ttf" \
      -o "$dir/MesloLGS NF $f.ttf" || { ns_warn "font download failed: MesloLGS NF $f"; return 1; }
    n=$((n+1))
  done
  [ $n -gt 0 ] && ns_has fc-cache && fc-cache -f "$dir" >/dev/null 2>&1
  ns_info "MesloLGS NF font ✓"
}

# ns_gset <schema[:path]> <key> <value>   set only if that terminal's schema has the key
ns_gset() {
  local schema="${1%%:*}"
  gsettings list-keys "$schema" 2>/dev/null | grep -qx "$2" || return 1
  gsettings set "$1" "$2" "$3"
}

# Set whichever terminals are installed to the Nerd Font and a dark theme (the
# wallpaper's navy where the terminal allows custom colours). Needs a desktop
# session; skipped quietly otherwise.
ns_shell_terminal_style() {
  [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || { ns_info "Not in a desktop session — terminal font and colours not set (re-run from the desktop)"; return 0; }
  local prof p set="" bg="#0B1324" fg="#D8DEE9"
  ns_has gsettings && {
    ns_gset org.gnome.Console use-system-font false && ns_gset org.gnome.Console custom-font "$NS_TERM_FONT" \
      && ns_gset org.gnome.Console theme night && set="$set Console"
    ns_gset org.gnome.Ptyxis use-system-font false && ns_gset org.gnome.Ptyxis font-name "$NS_TERM_FONT" \
      && { ns_gset org.gnome.Ptyxis interface-style dark; set="$set Ptyxis"; }
    prof=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
    if [ -n "$prof" ]; then
      p="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$prof/"
      gsettings set "$p" use-system-font false && gsettings set "$p" font "$NS_TERM_FONT" \
        && gsettings set "$p" use-theme-colors false && gsettings set "$p" background-color "$bg" \
        && gsettings set "$p" foreground-color "$fg" && set="$set GNOME-Terminal"
    fi
  }
  if ns_has xfconf-query && xfconf-query -c xfce4-terminal -l >/dev/null 2>&1; then
    xfconf-query -c xfce4-terminal -p /font-use-system -n -t bool -s false 2>/dev/null
    xfconf-query -c xfce4-terminal -p /font-name -n -t string -s "$NS_TERM_FONT" 2>/dev/null
    xfconf-query -c xfce4-terminal -p /color-use-theme -n -t bool -s false 2>/dev/null
    xfconf-query -c xfce4-terminal -p /color-background -n -t string -s "$bg" 2>/dev/null
    xfconf-query -c xfce4-terminal -p /color-foreground -n -t string -s "$fg" 2>/dev/null
    set="$set XFCE-Terminal"
  fi
  if [ -n "$set" ]; then ns_info "Terminal font ($NS_TERM_FONT) and dark colours set in:$set"
  else ns_info "Set your terminal's font to \"MesloLGS NF\" for Powerlevel10k's icons"; fi
}

# Powerlevel10k's "rainbow" template on ONE line (its two "newline" segments
# removed), with the clock turned on: terminal screenshots then show when each
# command ran. Written when ~/.p10k.zsh is missing, is the untouched two-line copy
# v0.7.0 installed, or was generated by northstar; a style you made with
# "p10k configure" is never replaced.
ns_shell_p10k() {
  local tpl="$NS_OMZ/custom/themes/powerlevel10k/config/p10k-rainbow.zsh" cfg="$HOME/.p10k.zsh" tmp
  [ -f "$tpl" ] || return 0
  if [ -f "$cfg" ] && ! cmp -s "$cfg" "$tpl" && ! grep -q 'northstar-osint: generated' "$cfg"; then
    ns_info "Keeping your own prompt style (~/.p10k.zsh)"
    return 0
  fi
  tmp=$(mktemp)
  { echo "# northstar-osint: generated from Powerlevel10k's p10k-rainbow.zsh, one-line layout."
    echo "# Run 'p10k configure' to make your own; northstar won't replace that."
    sed -E -e '/^[[:space:]]+newline([[:space:]]|$)/d' \
           -e 's/^([[:space:]]+)# time([[:space:]]+# current time)/\1time\2/' "$tpl"; } > "$tmp"
  mv "$tmp" "$cfg"
  ns_info "Prompt: one-line rainbow style with a clock (change it with: p10k configure)"
}

# Easter egg: pay-respects, the maintained Rust successor to thefuck (which no
# longer runs on Python 3.12+), answering to its old name. Official .deb from
# the project's GitHub releases.
ns_pay_respects() {
  local arch tmp url
  ns_has pay-respects && [ "$NS_UPDATE" != 1 ] && return 0
  case "$NS_ARCH" in arm64) arch=arm64 ;; *) arch=amd64 ;; esac
  url=$(curl -fsSL https://api.github.com/repos/iffse/pay-respects/releases/latest \
        | jq -r --arg a "_$arch.deb" '.assets[] | select(.name | endswith($a)) | .browser_download_url' | head -1)
  [ -n "$url" ] || return 1
  tmp=$(mktemp -d)
  ns_download "$url" "$tmp/pay-respects.deb" "download: pay-respects" \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$tmp/pay-respects.deb" >/dev/null 2>&1
  local rc=$?
  rm -rf "$tmp"
  return $rc
}

NS_ZSH_BLOCK_EGG=$(cat <<'EOF'
# Easter egg (northstar): mistype a command, then pay your respects (v2)
if (( $+commands[pay-respects] )); then
  eval "$(pay-respects zsh --alias fuck --nocnf)"
  # pay-respects re-expands $PROMPT to find the prompt character, which
  # Powerlevel10k's prompt doesn't allow ("bad substitution"): give it one
  __pr_base() {
    _PR_MODE="$1" _PR_PREFIX="❯" _PR_LAST_COMMAND="$2" _PR_ALIAS="$(alias)" _PR_SHELL="zsh" "$commands[pay-respects]"
  }
fi
EOF
)
# Lines from earlier versions' blocks that are removed when found (exact match)
NS_ZSH_RETIRED='# Easter egg (northstar): mistype a command, then pay your respects
(( $+commands[pay-respects] )) && eval "$(pay-respects zsh --alias fuck --nocnf)"'

# ns_zshrc_blocks <file>   insert any missing blocks after the Oh My Zsh source line
ns_zshrc_blocks() {
  local blk
  NS_RET="$NS_ZSH_RETIRED" awk 'BEGIN { n = split(ENVIRON["NS_RET"], r, "\n"); for (i = 1; i <= n; i++) gone[r[i]] = 1 }
    !($0 in gone)' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
  for blk in "$NS_ZSH_BLOCK_CLIP" "$NS_ZSH_BLOCK_NAV" "$NS_ZSH_BLOCK_EGG"; do
    grep -Fqx "$(printf '%s\n' "$blk" | head -1)" "$1" && continue
    NS_BLK="$blk" awk '{ print } $0 == "source \"$ZSH/oh-my-zsh.sh\"" { print ""; print ENVIRON["NS_BLK"] }' \
      "$1" > "$1.tmp" && mv "$1.tmp" "$1"
  done
}

# ~/.zshrc: written once. An existing file that northstar didn't write is kept
# as ~/.zshrc.pre-northstar. After that it's yours: an update only touches it if
# its plugin line is still one of northstar's own defaults.
ns_shell_zshrc() {
  local rc="$HOME/.zshrc" cur
  if grep -q 'northstar-osint: managed-zshrc' "$rc" 2>/dev/null; then
    cur=$(grep -m1 '^plugins=(' "$rc")
    if [ "$cur" = "$NS_ZSH_PLUGINS" ]; then
      ns_zshrc_blocks "$rc"
      ns_info "Your ~/.zshrc ✓ (yours to edit)"
    elif [ -n "$cur" ] && printf '%s\n' "$NS_ZSH_PLUGINS_OLD" | grep -Fqx "$cur"; then
      NS_OLD="$cur" NS_NEW="$NS_ZSH_PLUGINS" awk '$0 == ENVIRON["NS_OLD"] { print ENVIRON["NS_NEW"]; next } { print }' \
        "$rc" > "$rc.tmp" && mv "$rc.tmp" "$rc"
      ns_zshrc_blocks "$rc"
      ns_info "Updated the zsh plugins in ~/.zshrc"
    else
      ns_info "Your ~/.zshrc has its own plugin list; northstar's current one is: $NS_ZSH_PLUGINS"
    fi
    return 0
  fi
  [ -f "$rc" ] && cp "$rc" "$HOME/.zshrc.pre-northstar" && ns_info "Previous ~/.zshrc saved as ~/.zshrc.pre-northstar"
  cat > "$rc" <<'EOF'
# ~/.zshrc, written by northstar-osint's shell module. It's yours to edit:
# northstar won't overwrite it while the next line is here.
# northstar-osint: managed-zshrc

# Powerlevel10k instant prompt: keep this near the top
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/.local/share/northstar/bin:$HOME/.local/share/northstar/go/bin:$HOME/.local/bin:$PATH"  # northstar-osint

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode disabled        # ns-update keeps Oh My Zsh up to date
PLUGINS_LINE
source "$ZSH/oh-my-zsh.sh"

HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_SPACE                  # a command starting with a space isn't saved

# Restyle the prompt any time with: p10k configure
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF
  NS_NEW="$NS_ZSH_PLUGINS" awk '$0 == "PLUGINS_LINE" { print ENVIRON["NS_NEW"]; next } { print }' \
    "$rc" > "$rc.tmp" && mv "$rc.tmp" "$rc"
  ns_zshrc_blocks "$rc"
  ns_info "Wrote ~/.zshrc"
}

mod_shell() {
  local rc=0 custom="$NS_OMZ/custom" zsh_path cur me
  ns_apt zsh fontconfig || return 1
  ns_apt fzf command-not-found eza ranger || rc=1       # optional extras: carry on without any that are missing
  sudo update-command-not-found >/dev/null 2>&1 || true     # builds its package index
  ns_git_sync https://github.com/ohmyzsh/ohmyzsh.git "$NS_OMZ" || return 1
  ns_git_sync https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k" || rc=1
  ns_git_sync https://github.com/zsh-users/zsh-autosuggestions.git "$custom/plugins/zsh-autosuggestions" || rc=1
  ns_git_sync https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom/plugins/zsh-syntax-highlighting" || rc=1
  ns_git_sync https://github.com/Aloxaf/fzf-tab.git "$custom/plugins/fzf-tab" || rc=1
  ns_pay_respects || ns_warn "pay-respects not installed (optional)"
  ns_info "Oh My Zsh, Powerlevel10k and plugins ✓"

  ns_shell_zshrc
  ns_shell_p10k                    # ready-made style, so no setup wizard on first launch

  ns_shell_fonts || rc=1
  ns_shell_terminal_style

  zsh_path=$(command -v zsh)
  me=$(id -un)
  cur=$(getent passwd "$me" | cut -d: -f7)
  if [ -n "$zsh_path" ] && [ "$cur" != "$zsh_path" ]; then
    if sudo usermod -s "$zsh_path" "$me"; then
      ns_info "Default shell is now zsh (new terminals; log out and back in for everything)"
    else
      ns_warn "Couldn't change the default shell; run: chsh -s $zsh_path"; rc=1
    fi
  fi
  return $rc
}
