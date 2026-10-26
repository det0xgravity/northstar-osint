# shellcheck shell=bash
# shell — zsh as the login shell with Oh My Zsh, the Powerlevel10k prompt,
# autosuggestions and syntax highlighting, plus the MesloLGS NF font that
# Powerlevel10k's icons need, set in the common terminals. Linux only: on a
# Mac, northstar leaves your shell and ~/.zshrc alone.

ns_register shell "zsh + Oh My Zsh + Powerlevel10k prompt and font" "linux" mod_shell

NS_OMZ="$HOME/.oh-my-zsh"
NS_FONT_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"
NS_TERM_FONT="MesloLGS NF 11"

# ns_git_sync <repo-url> <dir>   clone once, pull on --update
ns_git_sync() {
  if [ -d "$2/.git" ]; then
    [ "$NS_UPDATE" = 1 ] && { git -C "$2" pull -q --ff-only || ns_warn "$(basename "$2"): git pull failed"; }
    return 0
  fi
  git clone -q --depth 1 "$1" "$2" || { ns_warn "clone failed: $1"; return 1; }
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

# Point whichever terminals are installed at the Nerd Font (needs a desktop
# session; skipped quietly otherwise)
ns_shell_terminal_fonts() {
  [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || { ns_info "Not in a desktop session — terminal fonts not set (re-run from the desktop)"; return 0; }
  local schemas="" prof set=""
  ns_has gsettings && schemas=$(gsettings list-schemas 2>/dev/null)
  case "$schemas" in *org.gnome.Console*)
    gsettings set org.gnome.Console use-system-font false && \
    gsettings set org.gnome.Console custom-font "$NS_TERM_FONT" && set="$set Console" ;; esac
  case "$schemas" in *org.gnome.Ptyxis*)
    gsettings set org.gnome.Ptyxis use-system-font false && \
    gsettings set org.gnome.Ptyxis font-name "$NS_TERM_FONT" && set="$set Ptyxis" ;; esac
  case "$schemas" in *org.gnome.Terminal.ProfilesList*)
    prof=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
    if [ -n "$prof" ]; then
      gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$prof/" use-system-font false && \
      gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$prof/" font "$NS_TERM_FONT" && \
      set="$set GNOME-Terminal"
    fi ;; esac
  if ns_has xfconf-query && xfconf-query -c xfce4-terminal -l >/dev/null 2>&1; then
    xfconf-query -c xfce4-terminal -p /font-use-system -n -t bool -s false 2>/dev/null \
      || xfconf-query -c xfce4-terminal -p /font-use-system -s false
    xfconf-query -c xfce4-terminal -p /font-name -n -t string -s "$NS_TERM_FONT" 2>/dev/null \
      || xfconf-query -c xfce4-terminal -p /font-name -s "$NS_TERM_FONT"
    set="$set XFCE-Terminal"
  fi
  if [ -n "$set" ]; then ns_info "Terminal font set to $NS_TERM_FONT in:$set"
  else ns_info "Set your terminal's font to \"MesloLGS NF\" for Powerlevel10k's icons"; fi
}

# ~/.zshrc: written once. An existing file that northstar didn't write is kept
# as ~/.zshrc.pre-northstar. After that it's yours: northstar never rewrites it.
ns_shell_zshrc() {
  local rc="$HOME/.zshrc"
  grep -q 'northstar-osint: managed-zshrc' "$rc" 2>/dev/null && { ns_info "Your ~/.zshrc ✓ (yours to edit)"; return 0; }
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
plugins=(git sudo colored-man-pages zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_SPACE                  # a command starting with a space isn't saved

# Restyle the prompt any time with: p10k configure
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF
  ns_info "Wrote ~/.zshrc"
}

mod_shell() {
  local rc=0 custom="$NS_OMZ/custom" zsh_path cur me
  ns_apt zsh fontconfig || return 1
  ns_git_sync https://github.com/ohmyzsh/ohmyzsh.git "$NS_OMZ" || return 1
  ns_git_sync https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k" || rc=1
  ns_git_sync https://github.com/zsh-users/zsh-autosuggestions.git "$custom/plugins/zsh-autosuggestions" || rc=1
  ns_git_sync https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom/plugins/zsh-syntax-highlighting" || rc=1
  ns_info "Oh My Zsh, Powerlevel10k and plugins ✓"

  ns_shell_zshrc
  # A ready-made prompt style (Powerlevel10k's own "rainbow" template), so
  # there's no setup wizard on first launch
  if [ ! -f "$HOME/.p10k.zsh" ] && [ -f "$custom/themes/powerlevel10k/config/p10k-rainbow.zsh" ]; then
    cp "$custom/themes/powerlevel10k/config/p10k-rainbow.zsh" "$HOME/.p10k.zsh"
    ns_info "Prompt style: rainbow (change it with: p10k configure)"
  fi

  ns_shell_fonts || rc=1
  ns_shell_terminal_fonts

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
