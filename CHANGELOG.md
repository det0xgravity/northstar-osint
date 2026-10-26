# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [0.12.0] - 2026-10-26

Phase 4a of the review: video verification and OCR.

### Added
- `ns-video` (main menu: Video verification): download a video with its
  metadata (or take a local file), extract scene-change and 10-second
  keyframes, and transcribe and translate its speech offline
  (whisper-ctranslate2), then open reverse image search.
- OCR: "Read the text in images" in Image analysis (Tesseract) and "Make a
  scanned PDF searchable" in Metadata (OCRmyPDF, with a plain-text copy).
- `media` module installs tesseract-ocr, ocrmypdf and whisper-ctranslate2.

## [0.11.0] - 2026-10-26

Phase 3 of the review: web page capture.

### Added
- `ns-archive` (main menu: Capture web pages): per page, an isolated
  single-file copy (monolith `-I`), a full-page screenshot, response headers,
  UTC time, final URL, server IP, the domain's RDAP record and a Wayback
  request with its real result; one page or a list. Sealed, with an offer to
  record an exhibit; archive.today opened for an independent public copy.
  Also looks up existing copies (Wayback, archive.today, Memento).
- monolith in the `media` module (release binary on Linux, Homebrew on macOS).

## [0.10.1] - 2026-10-26

### Added
- `docs/EVIDENCE.md`; ns-evidence launcher and dock entry; Country search
  results are sealed too and become the "latest results".

## [0.10.0] - 2026-10-26

Phase 2 of the review: evidence integrity.

### Added
- Every result folder is sealed when a search finishes: `manifest.sha256`
  (checkable with `sha256sum -c`) and `provenance.json` (UTC time, operator,
  host, northstar version, the version of each tool used).
- `audit.log` is hash-chained and in UTC, with the operator: editing,
  inserting or deleting a line breaks the chain.
- `ns-evidence` (main menu: Evidence & exhibits): record exhibits
  (`exhibits.csv`, optional OpenTimestamps proof), verify folders and the
  audit chain, export the case with a SHA-256.

## [0.9.0] - 2026-10-26

Phase 1 of the three-reviewer audit (investigator, OSINT specialist, QC).

### Security
- `ns-seal` now also removes saved browser logins (Firefox `logins.json` and
  `key4.db`, Brave `Login Data`), web storage, API keys (`keys.env`) and tool
  sessions (GHunt, instaloader, Censys, Shodan), and xrdp's keys, which each
  clone regenerates on first boot (`northstar-xrdp-keys.service`).
- Dark web page captures are saved as `page.html.txt`, so double-clicking
  can't open them in a browser and load trackers from your real IP.
- Case folders are private (mode 700).
- Pasted URLs and domains are validated, and `--` precedes them on the command
  line, so input can't be read as an option (for example yt-dlp's `--exec`).
- The Instagram session ID is typed into a hidden field.
- Image analysis asks before downloading an image from the target's server,
  and uses Tor when it's running.
- Go and GitHub-release downloads are checked against their published
  SHA-256 checksums. Go is unpacked before the old copy is replaced.
- xrdp is only set up inside a VM, since it listens on the network.

### Changed
- Censys: the Platform CLI (`cencli`) replaces censys-python, whose legacy
  Search API was deprecated in September 2026. The bookmark points at
  platform.censys.io.
- WHOIS & DNS adds RDAP (registrar, dates, nameservers, status).
- "Save a page" records the real Wayback result, including failures and
  rate limits.
- Retired unmaintained tools: h8mail (2022) and xeuledoc (2021).
  Blackbird's repository moved to antoniaci/blackbird.
- `install.sh --version`.
- Docs: menus list, uninstall steps (no longer removes your own pipx tools),
  KASM sealing, INSTALL paths.

## [0.8.2] - 2026-10-26

### Fixed
- The zsh easter egg failed with "__pr_base: bad substitution": pay-respects
  re-expands the prompt, which Powerlevel10k doesn't allow. It now gets a plain
  prompt character, and the old block is replaced in existing `~/.zshrc` files.

## [0.8.1] - 2026-10-26

### Added
- An easter egg in zsh. Mistype a command, then type the word thefuck made
  famous. It's pay-respects, thefuck's maintained Rust successor (thefuck itself
  no longer runs on Python 3.12+), installed from its official release .deb.

## [0.8.0] - 2026-10-26

### Added
- Terminal navigation: fzf-tab (searchable Tab completion with folder
  previews), dirhistory (Alt+arrows through folders), history-substring-search
  (↑/↓ through matching commands), eza (`ls`/`ll`/`la`/`lt` with icons and git
  status) and ranger (`r` browses and leaves you in the folder you chose).

### Changed
- `~/.zshrc` extras (clipboard fix, navigation) are kept as blocks that are
  added once, to new files and to files whose plugin line is still a northstar
  default. Optional packages (fzf, eza, ranger, command-not-found) no longer
  stop the shell module if one is missing on a distribution.

## [0.7.5] - 2026-10-26

### Added
- zsh plugins: fzf (Ctrl+R history search, Ctrl+T files), z (jump to
  folders), web-search, urltools, encode64, jsontools, extract, copypath,
  copyfile, copybuffer and command-not-found (with the `fzf` and
  `command-not-found` packages). An existing `~/.zshrc` gets the new list only
  if its plugin line is still the one northstar wrote. The copy plugins use
  xclip instead of wl-copy, which can hang on GNOME.

## [0.7.4] - 2026-10-26

### Changed
- GNOME's top-bar clock uses 24-hour time, like the prompt and audit.log.

## [0.7.3] - 2026-10-26

### Changed
- The prompt shows the time on the right (HH:MM:SS), so terminal screenshots
  record when each command ran. Command duration still appears for commands
  that take 3 seconds or more.

## [0.7.2] - 2026-10-26

### Changed
- Powerlevel10k prompt on one line (the rainbow template without its two
  `newline` segments). Replaces the v0.7.0 copy or a northstar-generated one,
  never a style made with `p10k configure`.
- Terminals get a dark theme: GNOME Console "night", Ptyxis dark, and the
  wallpaper's navy in GNOME Terminal and the XFCE terminal.

## [0.7.1] - 2026-10-26

### Changed
- Flameshot goes back to standby in the tray when clicked (the 0.6.1 entry
  that captured immediately is removed), and now starts at login. Print
  Screen still captures directly.

## [0.7.0] - 2026-10-26

### Added
- `shell` module (Linux): zsh as the login shell, with Oh My Zsh,
  Powerlevel10k (rainbow style; `p10k configure` to change it),
  zsh-autosuggestions and zsh-syntax-highlighting, all from their official
  repositories. The MesloLGS NF font is set in GNOME Console, Ptyxis,
  GNOME Terminal and the XFCE terminal. An existing `~/.zshrc` is kept as
  `~/.zshrc.pre-northstar`.

## [0.6.1] - 2026-10-26

### Fixed
- Clicking Flameshot in the app list seemed to do nothing: it only started a
  tray icon, and GNOME has no tray. The entry now opens the capture directly
  (`flameshot gui`), and GNOME gets tray icons via the packaged AppIndicator
  extension (also used by KeePassXC).

## [0.6.0] - 2026-10-26

### Added
- `ns-breach`: breach and infostealer exposure by email, username, domain or
  phone. Free sources: XposedOrNot, Hudson Rock, LeakCheck public, the HIBP
  catalogue. With your keys: Have I Been Pwned, Intelligence X, DeHashed,
  LeakCheck Pro. Passwords are masked on screen; raw results are mode 600.
  A password exposure check uses HIBP's k-anonymity range API and stores nothing.
- `ns-keys`: hidden-input API key manager (`~/.config/northstar/keys.env`,
  mode 600; keys never on a command line or in the audit log).
- `ns-darkweb`: Tor connection check, Ahmia search (opened in the browser),
  text-only capture of onion pages through Tor with SHA-256 hashes,
  ransomware leak-site claims (ransomware.live), and Tor Browser.
- `darkweb` module: the Tor client service and torsocks.
- Tor Browser on arm64 Linux, straight from the Tor Project and
  signature-verified: the alpha for now, switching to stable automatically.
- `docs/BREACH-DARKWEB.md`.

## [0.5.1] - 2026-10-26

### Fixed
- Country search opened no browser when started from its own launcher: since
  0.4.6 the browser is launched last, and the menu's terminal closed straight
  away and took the starting browser with it (SIGHUP). The browser and file
  manager now start in their own session (`setsid`), independent of the
  terminal.

## [0.5.0] - 2026-10-26

### Added
- An original northstar desktop wallpaper (`assets/wallpaper/`): night sky,
  compass and north star, map contours, aurora borealis, a maple leaf and the
  coordinates of Alert, Nunavut. The `desktop` module sets it on GNOME and XFCE
  only when the default background is still in use. A generator script is
  included.

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
