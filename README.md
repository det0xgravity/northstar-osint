# northstar-osint

**A modular, open-source OSINT workstation builder for Linux and Apple Silicon — with first-class Canadian public-records coverage.**

northstar-osint turns a fresh Debian, Ubuntu, Kali, Parrot or macOS install into a ready-to-work investigation machine: current open-source tools, simple point-and-click menus, browser hardening and bookmarks applied by policy, per-case output folders with an audit trail, and optional support for running as a Proxmox/Kasm Workspaces template.

[![Lint](https://github.com/det0xgravity/northstar-osint/actions/workflows/lint.yml/badge.svg)](https://github.com/det0xgravity/northstar-osint/actions/workflows/lint.yml)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)
![Platforms](https://img.shields.io/badge/platforms-Debian%2013%20%7C%20Ubuntu%2024.04%20%7C%20Kali%20%7C%20Parrot%20%7C%20macOS%20(arm64)-informational)

---

## Why

Most OSINT build scripts are a long list of commands that break silently when one step fails, install Python tools in ways that collide with the system, and stop being maintained. northstar-osint is built to be **re-run safely forever**:

- **Modular**: install everything, or just the pieces you want (`--only`, `--skip`).
- **Idempotent**: re-running skips what's already there; `--update` upgrades in place.
- **Isolated**: Python tools go into [pipx](https://pipx.pypa.io/) or private venvs. It never removes Debian's `EXTERNALLY-MANAGED` safeguard.
- **Honest about failures**: every module reports success or failure, and a summary at the end lists anything that needs attention.
- **Portable**: one codebase for Linux and macOS. The scripts run on the Bash 3.2 that ships with macOS.

## Features

| | |
|---|---|
| **Menus** | `northstar` main menu plus `ns-username`, `ns-domain`, `ns-media`, `ns-metadata`, `ns-image` and `ns-canada`. Dialogs use zenity on Linux and native dialogs on macOS. |
| **Cases & audit trail** | Results are saved under `~/Northstar/Cases/<case>/`, and every action is logged with a timestamp to that case's `audit.log`. |
| **Canada** | A dedicated search menu (people, businesses, phones, property, financial/regulatory, political, vessels, aircraft, VINs, call signs) plus 50+ curated Canadian registry bookmarks. |
| **Browsers** | Firefox, Brave, Tor Browser and Mullvad Browser. OSINT extensions and a managed bookmarks folder are delivered through **browser policy**, so they apply to every profile and every clone. |
| **Recon** | Pipelines for subdomain enumeration → DNS resolution → live-host probing → screenshots, plus WHOIS/DNS, crawling, archives and lookalike domains. |
| **Media** | Video/audio/playlists with platform metadata preserved, galleries, Instagram, live-stream recording, Wayback captures. |
| **VM-ready** | QEMU guest agent, xrdp with the right desktop session, clone-safe SSH host keys, and `ns-seal` to prepare a template. |

## Supported platforms

| Platform | Status | Notes |
|---|---|---|
| Debian 13 (GNOME) | ✅ Primary target | Full feature set including dock integration |
| Ubuntu 24.04 LTS | ✅ Supported | Firefox is a snap; policies still apply |
| Kali Linux (rolling) | ✅ Supported | Layers onto an existing Kali install |
| Parrot OS 6 | ✅ Supported | Installs a current Go automatically if the system Go is too old |
| macOS 14+ (Apple Silicon) | ✅ Supported | Needs Homebrew; no `vm` module; Brave bookmarks via import |

## Quick start

```bash
git clone https://github.com/det0xgravity/northstar-osint.git
cd northstar-osint
./install.sh
```

Run it **as your normal user**. It asks for your sudo password once.

When it finishes, open a new terminal and run:

```bash
northstar
```

On Linux, log out and back in so the new launchers show up in your applications menu. On macOS, open **Northstar** from `~/Applications` or Spotlight.

### Choosing what to install

```bash
./install.sh --list                      # show modules
./install.sh --only username,domain      # just these (core always runs)
./install.sh --skip frameworks,vm        # everything except these
ns-update                                # pull the latest version and upgrade everything
```

| Module | What it adds |
|---|---|
| `core` | Base packages, pipx, Go, the northstar runtime and menus *(always installed)* |
| `username` | sherlock, maigret, socialscan, holehe, h8mail, GHunt, toutatis, blackbird |
| `domain` | subfinder, dnsx, httpx, katana, gowitness, amass, theHarvester, waymore, dnstwist, Shodan & Censys CLIs |
| `media` | yt-dlp, gallery-dl, instaloader, streamlink, ffmpeg, exiftool, mediainfo, mat2, internetarchive, xeuledoc |
| `frameworks` | SpiderFoot, recon-ng, changedetection.io, search-that-hash, name-that-hash |
| `browsers` | Firefox, Brave, Tor Browser, Mullvad Browser + extension and bookmark policies |
| `canada` | Phone-number analysis for the Canada menu (the bookmarks come with `browsers`) |
| `desktop` | App-menu launchers, GNOME dock favourites, macOS `Northstar.app` |
| `extras` | KeePassXC, Flameshot (bound to Print Screen on GNOME), OBS Studio |
| `vm` | QEMU guest agent, xrdp, clone-safe identity, `ns-seal` *(Linux only)* |

Full details: [docs/MODULES.md](docs/MODULES.md).

## Using it

```
northstar                # main menu
├── Username & email     # ns-username
├── Domain & infrastructure  # ns-domain
├── Media download       # ns-media
├── Metadata             # ns-metadata
├── Image analysis       # ns-image
├── Canada search        # ns-canada
├── Switch / create case
├── Open case folder
└── Update northstar     # ns-update
```

Each menu tool can also be launched on its own from a terminal or the applications menu. What every option does and where its output goes is covered in [docs/MENUS.md](docs/MENUS.md).

### Cases and the audit trail

Before you start, pick **Switch / create case** and give the investigation a name. From then on:

```
~/Northstar/Cases/<case>/
├── audit.log                         # timestamp  case  tool  target  command
├── username/jdoe_20261026-101500/    # one folder per search
├── domain/example.com_20261026-102210/
└── canada/...
```

Secrets you type into a menu, such as session cookies, are redacted from `audit.log`.

## Documentation

- [Installation](docs/INSTALL.md): per-platform notes, options, uninstalling
- [Modules](docs/MODULES.md): every tool installed, with upstream links
- [Menus](docs/MENUS.md): what each menu option runs and produces
- [Canada](docs/CANADA.md): the Canadian toolkit and resource list
- [Kasm & Proxmox](docs/KASM.md): running northstar as a brokered VM and building templates
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Contributing](CONTRIBUTING.md) · [Changelog](CHANGELOG.md)

## Legal and ethical use

northstar-osint collects **publicly available** information. You are responsible for how you use it:

- Only investigate where you have a lawful basis and proper authorization.
- Respect the terms of service of the sites you query, and the privacy laws that apply to you (in Canada, PIPEDA and provincial equivalents).
- Use sock-puppet accounts and a separated environment (such as a VM) for investigative browsing. Never use your personal accounts.
- Don't use this toolkit to stalk, harass or dox anyone.

The tools installed are third-party open-source projects, each under its own license. northstar-osint installs them from their official sources and doesn't redistribute them.

## License

[MIT](LICENSE). Use it, fork it, improve it. Pull requests are welcome.
