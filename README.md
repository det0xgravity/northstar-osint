# True Bearing OSINT

**A modular, open-source OSINT workstation builder for Linux and Apple Silicon — with country-specific public-records searches for 17 countries.**

truebearing-osint turns a fresh Debian, Ubuntu, Kali, Parrot or macOS install into a ready-to-work investigation machine: current open-source tools, simple point-and-click menus, browser hardening and bookmarks applied by policy, per-case output folders with an audit trail, and optional support for running as a Proxmox/Kasm Workspaces template.

[![Lint](https://github.com/det0xgravity/truebearing-osint/actions/workflows/lint.yml/badge.svg)](https://github.com/det0xgravity/truebearing-osint/actions/workflows/lint.yml)
![License: GPL v3](https://img.shields.io/badge/license-GPLv3-blue)
![Platforms](https://img.shields.io/badge/platforms-Debian%2013%20%7C%20Ubuntu%2024.04%20%2F%2026.04%20%7C%20Kali%20%7C%20Parrot%20%7C%20macOS%20(arm64)-informational)

> **Formerly northstar-osint.** The project was renamed in October 2026 (v0.41.0) to avoid confusion with an unrelated commercial service of a similar name. An update (`ns-update`, or **Update northstar** in the old menu) moves an existing install across: your cases, settings and keys move to the new folders (`~/TrueBearing`, `~/.config/truebearing`), the old paths link to the new ones, and the `ns-…` commands keep working for now, each pointing you to its new `tb-…` name. True Bearing OSINT is an independent open-source project, not affiliated with any commercial product.

---

## Why

Most OSINT build scripts are a long list of commands that break silently when one step fails, install Python tools in ways that collide with the system, and stop being maintained. truebearing-osint is built to be **re-run safely forever**:

- **Modular**: install everything, or just the pieces you want (`--only`, `--skip`).
- **Idempotent**: re-running skips what's already there; `--update` upgrades in place.
- **Isolated**: Python tools go into [pipx](https://pipx.pypa.io/) or private venvs. It never removes Debian's `EXTERNALLY-MANAGED` safeguard.
- **Honest about failures**: every module reports success or failure, and a summary at the end lists anything that needs attention.
- **Portable**: one codebase for Linux and macOS. The scripts run on the Bash 3.2 that ships with macOS.

## Features

| | |
|---|---|
| **Menus** | The `truebearing` main menu and a menu per task (usernames, Telegram, domains, media, page capture, images, video, geolocation, face comparison, page monitoring, the case map, translation, countries, breach data, the dark web, evidence, notes). Dialogs use zenity on Linux and native dialogs on macOS. See the [menu list](#using-it). |
| **Cases & audit trail** | Each case has an intake record (reference, authority, lawful basis, scope, review date; changes are logged), hash-chained contemporaneous notes, and a checked close that lists anything unfinished. Results are saved under `~/TrueBearing/Cases/<case>/` (private: only your account can read it), and every action is logged to that case's `audit.log`. |
| **Notes, findings & report** | The Cases folder is an [Obsidian](https://obsidian.md) vault: a dashboard per case, a note per result, findings with source and information grades, selectors, accounts, a link chart, a chronology and a handover page. A supervisor review fingerprints the findings and summary, and each report version (Word) is built from the reportable findings with every exhibit re-checked. |
| **Guides** | A step-by-step [investigation guide](docs/INVESTIGATION-GUIDE.md) with a quick start checklist and worked examples, and every manual, as offline pages on the VM's desktop. |
| **Countries** | `tb-country`: people, business, phone, property, courts, financial/regulatory, political and transport searches tailored to each country's public records: Canada, the US, UK, Ireland, Australia, New Zealand, Germany, France, the Netherlands, Spain, Italy, Singapore, Malaysia, the Philippines, Thailand, Indonesia and Vietnam, plus an International pack (sanctions, leaks, vessels, aircraft, crypto). Phone analysis for every country, and 250+ curated registry bookmarks. Adding a country is one JSON file. |
| **Browsers** | Firefox, Brave, Tor Browser and Mullvad Browser. OSINT extensions and a managed bookmarks folder are delivered through **browser policy**, so they apply to every profile and every clone. |
| **Evidence** | Every result folder is sealed with a SHA-256 manifest and provenance (UTC time, operator, tool versions); `audit.log` is hash-chained so edits show; `tb-evidence` records numbered exhibits (optional OpenTimestamps proof), verifies folders and the log, and exports a case with a checksum. |
| **Breach & dark web** | `tb-breach`: breach and infostealer exposure by email, username, domain or phone (free sources plus HIBP, Intelligence X, DeHashed and LeakCheck with your keys), and a private password exposure check. `tb-darkweb`: Tor, onion search, text-only capture of onion pages, ransomware leak-site claims, and OnionShare (a private .onion drop box that receives files from a source into the case, and sending files over a private link). API keys are stored privately and never logged. |
| **Safeguards** | Adult-site username searches and online face search engines only with a recorded reason, never for a possible child or victim; face comparison runs locally on case photos only. LAN isolation (`tb-lan`) stops the VM from reaching your own network. Received files are checked (ClamAV, macros, PDF scripts, disguised programs) before anyone opens them, and exports can be encrypted (age or PGP). |
| **Recon** | Pipelines for subdomain enumeration → DNS resolution → live-host probing → screenshots, plus WHOIS/DNS, crawling, archives and lookalike domains. |
| **Media** | Video/audio/playlists with platform metadata preserved, galleries, Instagram, live-stream recording, Wayback captures. |
| **VM-ready** | Guest tools for the detected hypervisor, xrdp with the right desktop session (VMs only), clone-safe SSH and xrdp keys, and `tb-seal`, which strips history, saved logins, API keys and tool sessions before you make a template. |

## Supported platforms

| Platform | Status | Notes |
|---|---|---|
| Debian 13 (GNOME) | ✅ Primary target | Full feature set including dock integration |
| Ubuntu 24.04 / 26.04 LTS | ✅ Supported | Firefox is a snap; policies still apply. 26.04 ships Python 3.14: GHunt and ShadowFinder are installed with newer libraries there |
| Kali Linux (rolling) | ✅ Supported | Layers onto an existing Kali install |
| Parrot OS 6 | ✅ Supported | Installs a current Go automatically if the system Go is too old |
| macOS 14+ (Apple Silicon) | ✅ Supported | Needs Homebrew; no `vm` module; Brave bookmarks via import |

## Quick start

```bash
git clone https://github.com/det0xgravity/truebearing-osint.git
cd truebearing-osint
./install.sh
```

Run it **as your normal user**. It asks for your sudo password once.

When it finishes, open a new terminal and run:

```bash
truebearing
```

On Linux, log out and back in so the new launchers show up in your applications menu. On macOS, open **True Bearing** from `~/Applications` or Spotlight.

### Choosing what to install

```bash
./install.sh --list                      # show modules
./install.sh --only username,domain      # just these (core always runs)
./install.sh --skip frameworks,vm        # everything except these
tb-update                                # pull the latest version and upgrade everything
```

| Module | What it adds |
|---|---|
| `core` | Base packages, pipx, Go, the True Bearing runtime and menus *(always installed)* |
| `username` | sherlock, maigret, socialscan, holehe, GHunt, toutatis, blackbird |
| `social` | Telegram research engine (Telethon, private venv) and telegram-tracker for channel collection (its own Python 3.14 through uv) |
| `geo` | GeoCLIP (local AI photo geolocation) and ShadowFinder |
| `face` | Local face comparison within a case (OpenCV YuNet + SFace, checksum-verified models) |
| `translate` | Offline text translation (Argos Translate) for `tb-translate` |
| `domain` | subfinder, dnsx, httpx, katana, gowitness, amass, theHarvester, waymore, dnstwist, Shodan & Censys Platform CLIs |
| `media` | yt-dlp, gallery-dl, instaloader, streamlink, ffmpeg, exiftool, mediainfo, mat2, internetarchive |
| `frameworks` | SpiderFoot, recon-ng, changedetection.io, search-that-hash, name-that-hash |
| `browsers` | Firefox, Brave, Tor Browser, Mullvad Browser + extension and bookmark policies |
| `darkweb` | Tor client service and torsocks for `tb-darkweb`, and OnionShare (private .onion drop box and file sending) |
| `countries` | Phone-number analysis for the country menus (the country bookmarks come with `browsers`) |
| `desktop` | App-menu launchers, GNOME dock favourites, macOS `TrueBearing.app` |
| `shell` | zsh with Oh My Zsh, the Powerlevel10k prompt, autosuggestions, syntax highlighting and the MesloLGS NF font *(Linux)* |
| `extras` | KeePassXC, Flameshot (bound to Print Screen and Super+Shift+S on GNOME), OBS Studio |
| `messaging` | Telegram Desktop, Signal (x86_64), Element (Matrix) for research accounts |
| `notes` | Obsidian, with the Cases folder set up as a vault (templates, Case.md, Results.md) |
| `lan` | LAN isolation (`tb-lan`): blocks connections from the VM to private networks *(Linux; on in VMs)* |
| `vm` | QEMU guest agent, xrdp, clone-safe identity, `tb-seal` *(Linux only)* |

Full details: [docs/MODULES.md](docs/MODULES.md).

## Using it

```
truebearing                # main menu
├── Missing person       # tb-missing
├── Username & email     # tb-username
├── Telegram             # tb-telegram
├── Domain & infrastructure  # tb-domain
├── Media download       # tb-media
├── Capture web pages    # tb-archive
├── Metadata             # tb-metadata
├── Image analysis       # tb-image
├── Video verification   # tb-video
├── Photo geolocation    # tb-geo
├── Face comparison (within this case)   # tb-face
├── Page monitoring      # tb-watch
├── Case map             # tb-map
├── Translate (offline)  # tb-translate
├── Country search       # tb-country
├── Breach data          # tb-breach
├── Dark web             # tb-darkweb
├── Evidence & exhibits  # tb-evidence
├── API keys             # tb-keys
├── Notes (Obsidian)     # tb-notes
├── Case: notes, details, report, close   # tb-case
├── Switch / create case
├── Open latest results
├── Open case folder
├── LAN isolation (firewall)   # tb-lan
├── Guides (how to investigate, manuals)   # tb-guides
├── Health check         # tb-doctor
└── Update True Bearing     # tb-update
```

Each menu tool can also be launched on its own from a terminal or the applications menu. What every option does and where its output goes is covered in [docs/MENUS.md](docs/MENUS.md).

### Cases and the audit trail

Before you start, pick **Switch / create case** and give the investigation a name. From then on:

```
~/TrueBearing/Cases/<case>/
├── audit.log                         # timestamp  case  tool  target  command
├── username/jdoe_20261026-101500/    # one folder per search
├── domain/example.com_20261026-102210/
└── united-kingdom/...                # country searches, by country
```

Secrets you type into a menu, such as session cookies, are redacted from `audit.log`.

## Documentation

- [Investigation guide](docs/INVESTIGATION-GUIDE.md): a [quick start checklist](docs/INVESTIGATION-GUIDE.md#quick-start-checklist), then a whole case step by step, from a new VM to a report ready for submission, with worked examples (a dark-web vendor from username to name; a photo to place and person)
- [Installation](docs/INSTALL.md): per-platform notes, options, uninstalling
- [Modules](docs/MODULES.md): every tool installed, with upstream links
- [Menus](docs/MENUS.md): what each menu option runs and produces
- [Countries](docs/COUNTRIES.md): country searches, the resource list, and how to add a country
- [Missing persons & CTFs](docs/MISSING-PERSONS.md): subject profile, timeline, findings log, ground rules
- [Evidence & exhibits](docs/EVIDENCE.md): manifests, provenance, the tamper-evident audit log, exhibits, export
- [Breach data & dark web](docs/BREACH-DARKWEB.md): sources, safety rules, API keys, Tor Browser on arm64
- [Kasm & Proxmox](docs/KASM.md): running True Bearing as a brokered VM and building templates
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md)

## Legal and ethical use

truebearing-osint collects **publicly available** information. You are responsible for how you use it:

- Only investigate where you have a lawful basis and proper authorization.
- Respect the terms of service of the sites you query, and the privacy laws that apply to you (GDPR in the EU and UK, PIPEDA in Canada, and so on).
- Use sock-puppet accounts and a separated environment (such as a VM) for investigative browsing. Never use your personal accounts.
- Don't use this toolkit to stalk, harass or dox anyone.

The tools installed are third-party open-source projects, each under its own license; this project's license covers only truebearing-osint's own code and content. truebearing-osint installs them from their official sources and doesn't redistribute them.

## License

Copyright (C) 2026 det0xgravity

truebearing-osint is free software: you can redistribute it and/or modify it under the terms of the [GNU General Public License](LICENSE) as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the license for details.

In plain terms: use it, study it, change it and share it freely. If you distribute it, changed or not, you must make the full source available under the same license and keep this notice.

Versions up to 0.30.0 were released under the MIT License, and 0.31.0 under the PolyForm Noncommercial License 1.0.0; copies obtained under those keep their terms.

Contributions are welcome. By opening a pull request, you agree that your contribution is licensed under the GPL (version 3 or later) and that the maintainer may also license it under other terms.
