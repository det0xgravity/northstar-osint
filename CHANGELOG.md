# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

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
