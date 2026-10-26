# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [0.4.7] - 2026-10-26

### Changed
- GNOME in VMs: one fixed workspace instead of dynamic workspaces. Searches
  that reused a browser window on the other workspace made the screen slide
  there, which looked like the overview opening.

## [0.4.6] - 2026-10-26

### Fixed
- The "copied to clipboard" dialog in Country search and Image analysis
  opened behind the browser, and the menu waited on it. The dialog now comes
  first, and the browser opens when you click OK.

### Added
- Desktop notifications (shown above all windows) confirm what's on the
  clipboard after the browser opens: Country search, Username and Email
  search, Image analysis. `libnotify-bin` is added to the core packages.

## [0.4.5] - 2026-10-26

### Changed
- In VMs, pressing Super on its own no longer opens GNOME's overview. The
  host's ⌘ or Windows key reaches the guest as Super whenever you switch apps.

## [0.4.4] - 2026-10-26

### Fixed
- SpiderFoot's web UI returned "Error" (HTTP 500) unless it was started from
  its own folder, because it loads its page templates from the current
  directory. The `spiderfoot` command now switches there first.

## [0.4.3] - 2026-10-26

### Fixed
- After a search started from the main menu, the file manager opened in front
  and GNOME opened the menu behind it, so the menu looked frozen at "Results
  saved to:". From the main menu, results folders are no longer opened
  automatically.

### Added
- "Open latest results" in the main menu.

## [0.4.2] - 2026-10-26

### Changed
- GNOME: the Activities overview no longer opens at every login (Debian's
  packaged "No overview at start-up" extension), and in VMs the top-left hot
  corner is turned off, since the pointer crosses it on its way out of the VM
  window.

## [0.4.1] - 2026-10-26

### Fixed
- Menus could hang after a search on GNOME (Wayland): `wl-copy` waits to grab
  focus because GNOME lacks the clipboard data-control protocol. The clipboard
  now uses `xclip` through XWayland when available, and any clipboard helper
  is given at most 3 seconds.
- Username search: Sherlock's text file needs `--txt` in current Sherlock, and
  Blackbird saved nothing (it needs `--csv`/`--json` and writes into its own
  folder). Both now save into the case folder.

## [0.4.0] - 2026-10-26

### Added
- `ns-country`: country-specific public-records searches, driven by data packs
  in `config/countries/`. 17 countries (Canada, United States, United Kingdom,
  Ireland, Australia, New Zealand, Germany, France, Netherlands, Spain, Italy,
  Singapore, Malaysia, Philippines, Thailand, Indonesia, Vietnam) plus an
  International pack (sanctions, leaks, company identifiers, vessels,
  aircraft, crypto addresses, EU institutions).
- Phone-number analysis for every country (libphonenumber), with searches in
  all common formats.
- A "Countries" bookmark folder, with one subfolder per country.
- `lib/ns_country.py validate`, run in CI, checks every pack.
- `docs/COUNTRIES.md`, including how to add a country.

### Changed
- Canada is now a country pack. `ns-canada` still works and opens it directly.
  The Canada bookmarks moved to Countries → Canada.
- The `canada` module is now `countries`.
- `ns-linkcheck` checks the country packs as well as the bookmarks.

## [0.3.1] - 2026-10-26

Fixes from the first real install (Debian 13 arm64, UTM).

### Fixed
- theHarvester: its main branch now needs Python 3.14+, so on older Pythons
  northstar installs release 4.11.1 (Python 3.12+).
- SpiderFoot: its 2023 requirements cap lxml, cryptography and others below
  versions that support Python 3.12+. The caps are lifted (except
  `secure<0.4`, which the web UI needs).
- OBS Studio on arm64 Linux comes from the distribution's packages, since
  Flathub builds it for x86_64 only.

### Changed
- When a pipx, pip or Go install fails, the last lines of its output are
  printed (and so saved in `install.log`) instead of only "failed".

## [0.3.0] - 2026-10-26

### Added
- User extension list: `~/.config/northstar/firefox-extensions.local.txt` is
  merged into the Firefox policy, so users no longer edit the checkout.
- `docs/KASM.md`: how to roll out updates to persistent VMs and pools.

### Changed
- The installer records the modules a user chose to skip
  (`~/.config/northstar/skipped`) instead of the ones installed, so
  `ns-update` installs modules added in later releases. Older
  `~/.config/northstar/modules` files are converted automatically.
- `ns-update` explains a failed `git pull` (which files were edited and how to
  fix it), repeats the warning at the end and exits non-zero, instead of
  continuing with a one-line note.

## [0.2.0] - 2026-10-26

### Added
- Apple Silicon VM guests: the `vm` module detects the hypervisor with
  `systemd-detect-virt` and installs matching guest tools (QEMU/KVM:
  `qemu-guest-agent` + `spice-vdagent`; VMware: `open-vm-tools-desktop`;
  Parallels: a reminder to install Parallels Tools; Apple Virtualization and
  bare metal: no agent).
- "Running in a VM on Apple Silicon" section in `docs/INSTALL.md`.

### Changed
- On arm64 Linux, the `browsers` module skips Tor Browser and Mullvad Browser
  with a clear message: Flathub builds both for x86_64 only, and Tor Browser's
  aarch64 Linux builds are alpha-only.
- `ns-domain` passive enumeration uses the Amass v5 CLI: `amass enum` (passive
  by default) followed by `amass subs -names`. v5 removed `enum -o`, so the old
  command failed immediately.

### Fixed
- Bookmarks: Legacy.com obituaries now point to its obituary search page, and
  LAC ship registrations point to Collection Search (the old
  `bac-lac.gc.ca` database no longer responds). The Vessel search in
  `ns-canada` uses the new LAC link too.

## [0.1.0] - 2026-10-26

### Added
- Modular installer (`install.sh`) with `--list`, `--only`, `--skip`, `--update` and `--yes`.
- Platform support: Debian 13, Ubuntu 24.04, Kali, Parrot and macOS on Apple Silicon.
- Modules: core, username, domain, media, frameworks, browsers, canada, desktop, extras, vm.
- Menu tools: `northstar`, `ns-username`, `ns-domain`, `ns-media`, `ns-metadata`,
  `ns-image`, `ns-canada`, `ns-update`, `ns-seal`, `ns-linkcheck`.
- Per-case output folders and a tab-separated `audit.log` for every action.
- Firefox and Brave policies: OSINT extensions (GUIDs resolved live from AMO) and a
  managed bookmarks folder; Netscape-format bookmarks export.
- Canadian toolkit: search menu and 50+ curated Canadian registry bookmarks.
- VM readiness: QEMU guest agent, xrdp with desktop detection, polkit fix for RDP,
  clone-safe SSH host keys, and `ns-seal` for building templates.
- Automatic installation of a current Go toolchain when the system Go is too old.
- CI: shellcheck, Python compile and JSON validation.
