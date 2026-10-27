# shellcheck shell=bash
# notes — Obsidian, with ~/Northstar/Cases set up as one vault: settings,
# templates (person, account, organisation, place, event, lead), a Case.md
# overview per case and a Results.md log of every result folder.

ns_register notes "Obsidian notes: the Cases folder as a vault, with case templates" "linux macos" mod_notes

# Obsidian keeps its list of vaults here (Flatpak, native Linux, macOS)
ns_obsidian_config() {
  if ns_is_macos; then printf '%s\n' "$HOME/Library/Application Support/obsidian/obsidian.json"
  elif flatpak info md.obsidian.Obsidian >/dev/null 2>&1; then
    printf '%s\n' "$HOME/.var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json"
  else printf '%s\n' "$HOME/.config/obsidian/obsidian.json"; fi
}

mod_notes() {
  local rc=0
  if ns_is_macos; then
    ns_cask obsidian || rc=1
  else
    if ns_flatpak md.obsidian.Obsidian; then      # verified on Flathub, x86_64 and arm64
      # an `obsidian` command (the Flatpak itself only runs as "flatpak run …")
      printf '#!/usr/bin/env bash\nexec flatpak run md.obsidian.Obsidian "$@"\n' > "$NS_BIN/obsidian"
      chmod +x "$NS_BIN/obsidian"
      ln -sf "$NS_BIN/obsidian" "$HOME/.local/bin/obsidian"
      ns_info "Obsidian installed: in your applications menu, or run 'obsidian'"
    else
      ns_warn "Obsidian (Flatpak) failed to install"; rc=1
    fi
  fi
  "$NS_BIN/ns_vault" setup "$NS_DATA" >/dev/null || rc=1
  # Obsidian rewrites its vault list on exit, so only add ours while it's closed
  if pgrep -f -i 'obsidian' >/dev/null 2>&1; then
    ns_info "Obsidian is open: close it and run ./install.sh --only notes to register the vault, or open $NS_DATA/Cases as a vault yourself"
  else
    "$NS_BIN/ns_vault" register "$NS_DATA" "$(ns_obsidian_config)" >/dev/null || rc=1
  fi
  ns_info "Notes: main menu → Notes (Obsidian). The Cases folder is the vault."
  return $rc
}
