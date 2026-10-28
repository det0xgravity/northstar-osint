# shellcheck shell=bash
# notes — Obsidian, with ~/TrueBearing/Cases set up as one vault: settings,
# templates (person, account, organisation, place, event, lead), a Case.md
# overview per case and a Results.md log of every result folder.

tb_register notes "Obsidian notes: the Cases folder as a vault, with case templates" "linux macos" mod_notes

# Obsidian keeps its list of vaults here (Flatpak, native Linux, macOS)
tb_obsidian_config() {
  if tb_is_macos; then printf '%s\n' "$HOME/Library/Application Support/obsidian/obsidian.json"
  elif flatpak info md.obsidian.Obsidian >/dev/null 2>&1; then
    printf '%s\n' "$HOME/.var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json"
  else printf '%s\n' "$HOME/.config/obsidian/obsidian.json"; fi
}

mod_notes() {
  local rc=0
  if tb_is_macos; then
    tb_cask obsidian || rc=1
  else
    if tb_flatpak md.obsidian.Obsidian; then      # verified on Flathub, x86_64 and arm64
      # an `obsidian` command (the Flatpak itself only runs as "flatpak run …")
      printf '#!/usr/bin/env bash\nexec flatpak run md.obsidian.Obsidian "$@"\n' > "$TB_BIN/obsidian"
      chmod +x "$TB_BIN/obsidian"
      ln -sf "$TB_BIN/obsidian" "$HOME/.local/bin/obsidian"
      tb_info "Obsidian installed: in your applications menu, or run 'obsidian'"
    else
      tb_warn "Obsidian (Flatpak) failed to install"; rc=1
    fi
  fi
  "$TB_BIN/tb_vault" setup "$TB_DATA" >/dev/null || rc=1
  # Obsidian rewrites its vault list on exit, so only add ours while it's closed
  if pgrep -f -i 'obsidian' >/dev/null 2>&1; then
    tb_info "Obsidian is open: close it and run ./install.sh --only notes to register the vault, or open $TB_DATA/Cases as a vault yourself"
  else
    "$TB_BIN/tb_vault" register "$TB_DATA" "$(tb_obsidian_config)" >/dev/null || rc=1
  fi
  tb_info "Notes: main menu → Notes (Obsidian). The Cases folder is the vault."
  return $rc
}
