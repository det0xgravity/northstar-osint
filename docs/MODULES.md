# Modules

Every tool is installed from its official source. Each project keeps its own license; northstar-osint only automates installing them.

## core *(always installed)*

System packages (git, curl, jq, Python, pipx, Go, whois, dig, zenity, clipboard tools, flatpak) and the northstar runtime: menu tools, the UI library, configuration and PATH setup.

## username

| Tool | Command | Purpose |
|---|---|---|
| [Sherlock](https://github.com/sherlock-project/sherlock) | `sherlock` | Username across hundreds of sites |
| [Maigret](https://github.com/soxoj/maigret) | `maigret` | Username search with profile parsing and HTML reports |
| [socialscan](https://github.com/iojw/socialscan) | `socialscan` | Username/email availability on major platforms |
| [holehe](https://github.com/megadose/holehe) | `holehe` | Which sites an email is registered on |
| [h8mail](https://github.com/khast3x/h8mail) | `h8mail` | Breach lookups (most sources need API keys) |
| [GHunt](https://github.com/mxrch/GHunt) | `ghunt` | Google account intelligence (run `ghunt login` once) |
| [Toutatis](https://github.com/megadose/toutatis) | `toutatis` | Instagram account details (needs a session ID) |
| [Blackbird](https://github.com/p1ngul1n0/blackbird) | `blackbird` | Username/email search using WhatsMyName data |

## domain

| Tool | Command | Purpose |
|---|---|---|
| [subfinder](https://github.com/projectdiscovery/subfinder) | `subfinder` | Passive subdomain enumeration |
| [dnsx](https://github.com/projectdiscovery/dnsx) | `dnsx` | Fast DNS resolution |
| [httpx](https://github.com/projectdiscovery/httpx) | `httpx` | Live-host probing, titles, technologies |
| [katana](https://github.com/projectdiscovery/katana) | `katana` | Web crawler |
| [gowitness](https://github.com/sensepost/gowitness) | `gowitness` | Website screenshots (uses Chromium/Chrome) |
| [Amass](https://github.com/owasp-amass/amass) | `amass` | Attack-surface mapping |
| [theHarvester](https://github.com/laramies/theHarvester) | `theHarvester` | Emails, hosts and names from public sources. Release 4.11.1 on Python 3.12–3.13 (Debian 13, Ubuntu 24.04, Kali), the latest version on Python 3.14+ |
| [waymore](https://github.com/xnl-h4ck3r/waymore) | `waymore` | URLs from Wayback, Common Crawl, URLScan, OTX |
| [dnstwist](https://github.com/elceef/dnstwist) | `dnstwist` | Lookalike / typosquat domains |
| [Shodan CLI](https://github.com/achillean/shodan-python) | `shodan` | Shodan queries (needs an API key) |
| [Censys CLI](https://github.com/censys/censys-python) | `censys` | Censys search (needs API credentials) |

## media

| Tool | Command | Purpose |
|---|---|---|
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | `yt-dlp` | Video/audio from thousands of sites |
| [gallery-dl](https://github.com/mikf/gallery-dl) | `gallery-dl` | Image galleries and social posts |
| [Instaloader](https://github.com/instaloader/instaloader) | `instaloader` | Instagram profiles, posts, stories |
| [Streamlink](https://github.com/streamlink/streamlink) | `streamlink` | Record live streams |
| [ExifTool](https://exiftool.org/) | `exiftool` | Read/write metadata in almost any file |
| [MediaInfo](https://mediaarea.net/en/MediaInfo) | `mediainfo` | Technical media metadata |
| [mat2](https://0xacab.org/jvoisin/mat2) | `mat2` | Metadata removal (Linux) |
| [FFmpeg](https://ffmpeg.org/) | `ffmpeg` | Media processing (used by yt-dlp) |
| [internetarchive](https://github.com/jjjake/internetarchive) | `ia` | Search and download from archive.org |
| [xeuledoc](https://github.com/Malfrats/xeuledoc) | `xeuledoc` | Public Google document metadata |

## frameworks

| Tool | Command | Purpose |
|---|---|---|
| [SpiderFoot](https://github.com/smicallef/spiderfoot) | `spiderfoot` | Automated multi-source recon (`spiderfoot -l 127.0.0.1:5001` for the web UI). Unmaintained since 2023, so northstar installs it with newer dependencies than it asks for |
| [recon-ng](https://github.com/lanmaster53/recon-ng) | `recon-ng` | Modular recon framework |
| [changedetection.io](https://github.com/dgtlmoon/changedetection.io) | `changedetection.io` | Watch pages for changes (`changedetection.io -d ~/Northstar/changedetection -p 5000`) |
| [search-that-hash](https://github.com/HashPals/Search-That-Hash) | `sth` | Look up hashes in public databases |
| [name-that-hash](https://github.com/HashPals/Name-That-Hash) | `nth` | Identify hash types |

## browsers

| Browser | Purpose |
|---|---|
| Firefox / Firefox ESR | Main investigation browser, with OSINT extensions and bookmarks by policy |
| [Brave](https://brave.com) | Chromium-based alternative, with bookmarks by policy |
| [Tor Browser](https://www.torproject.org) | Anonymity and .onion access (Flatpak launcher on x86_64 Linux; signature-verified download from the Tor Project on arm64 Linux, currently the alpha) |
| [Mullvad Browser](https://mullvad.net/browser) | Tor Browser's anti-fingerprinting without the Tor network (skipped on arm64 Linux) |

On arm64 Linux, such as a VM on Apple Silicon, Mullvad Browser isn't installed because it has no arm64 build, and Tor Browser comes from the Tor Project's alpha channel until stable supports arm64. See [INSTALL.md](INSTALL.md#running-in-a-vm-on-apple-silicon).

**Extensions** (Firefox, from `config/firefox-extensions.txt`): uBlock Origin, Multi-Account Containers, SingleFile, KeePassXC-Browser, Search by Image, Wayback Machine, Mitaka, Shodan, User-Agent Switcher and Manager.

**Policy also sets:** bookmarks toolbar always visible, telemetry and studies off, Firefox's password saving off (use KeePassXC).

> Don't add extensions to Tor Browser or Mullvad Browser. They protect you by making every user look identical, and each extension makes you more unique.

## darkweb

The Tor client as a service (a SOCKS proxy on `127.0.0.1:9050`, never a relay) and `torsocks`, used by `ns-darkweb`. Tor Browser itself comes with `browsers`. See [BREACH-DARKWEB.md](BREACH-DARKWEB.md).

## countries

Creates a private Python environment with Google's [libphonenumber](https://github.com/daviddrysdale/python-phonenumbers) for the phone analysis in `ns-country`. The country packs themselves are installed by `core`, and their bookmark folders by `browsers`. See [COUNTRIES.md](COUNTRIES.md).

## desktop

- **Linux**: `.desktop` launchers for every menu in `~/.local/share/applications` (they show up in any desktop's app menu), plus GNOME dock favourites. On GNOME it also stops the Activities overview from opening at every login (the packaged *No overview at start-up* extension, where the distribution has it). In a VM it also uses a single fixed workspace, so the screen doesn't slide away when a search reuses a browser window on another workspace, and turns off the top-left hot corner and the lone Super-key trigger. Otherwise the overview opens whenever the pointer leaves the VM window through that corner, or the host's ⌘/Windows key reaches the VM.
- **Wallpaper** (GNOME and XFCE): northstar's own desktop background, a night sky with a north star, aurora borealis and a Canadian maple leaf. It's only set if you're still on the distribution's default background. The image is in `~/.local/share/northstar/share/wallpaper/`.
- **macOS**: `~/Applications/Northstar.app`. Your Mac's wallpaper is never changed.

## shell *(Linux only)*

| Component | Purpose |
|---|---|
| [zsh](https://www.zsh.org) | Becomes your login shell |
| [Oh My Zsh](https://ohmyz.sh) | zsh framework; plugins `git`, `sudo` (press Esc twice to add sudo), `colored-man-pages` |
| [Powerlevel10k](https://github.com/romkatv/powerlevel10k) | The prompt: its "rainbow" style on one line. Restyle any time with `p10k configure` (northstar never replaces a style you made) |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Suggests commands from your history as you type (→ to accept) |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Colours commands as you type, so typos show in red |
| [MesloLGS NF](https://github.com/romkatv/powerlevel10k-media) | The font Powerlevel10k's icons need. Set, along with a dark theme, in GNOME Console, Ptyxis, GNOME Terminal and the XFCE terminal (custom navy colours where the terminal allows them) |

All of it is cloned from the official repositories and updated by `ns-update`. Your existing `~/.zshrc`, if any, is kept as `~/.zshrc.pre-northstar`. The new `~/.zshrc` is yours to edit: northstar won't rewrite it. Commands that start with a space aren't saved in history, which is handy for anything sensitive. On macOS this module doesn't run, and your shell is left alone.

## extras

| Tool | Purpose |
|---|---|
| [KeePassXC](https://keepassxc.org) | Store sock-puppet credentials inside the workstation |
| [Flameshot](https://flameshot.org) | Annotated screenshots. Starts at login as a tray icon (click it to capture); Print Screen captures directly on GNOME |
| [OBS Studio](https://obsproject.com) | Screen recording (Flatpak; Debian's package on arm64 Linux) |

## vm *(Linux only)*

Guest tools for the detected hypervisor (QEMU guest agent and SPICE agent on Proxmox/UTM, open-vm-tools on VMware, a Parallels Tools reminder on Parallels), xrdp with the correct desktop session, a polkit rule that removes the colour-profile prompt over RDP, a first-boot service that regenerates SSH host keys on clones, and `ns-seal`. See [KASM.md](KASM.md).
