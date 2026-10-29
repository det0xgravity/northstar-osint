# Modules

Every tool is installed from its official source. Each project keeps its own license; truebearing-osint only automates installing them.

## core *(always installed)*

System packages (git, curl, jq, Python, pipx, Go, whois, dig, zenity, clipboard tools, flatpak, pandoc, age and GnuPG for encrypted exports) and the True Bearing runtime: menu tools, the UI library, configuration and PATH setup.

## username

| Tool | Command | Purpose |
|---|---|---|
| [Sherlock](https://github.com/sherlock-project/sherlock) | `sherlock` | Username across hundreds of sites |
| [Maigret](https://github.com/soxoj/maigret) | `maigret` | Username search with profile parsing and HTML reports |
| [socialscan](https://github.com/iojw/socialscan) | `socialscan` | Username/email availability on major platforms |
| [holehe](https://github.com/megadose/holehe) | `holehe` | Which sites an email is registered on |
| [GHunt](https://github.com/mxrch/GHunt) | `ghunt` | Google account intelligence (run `ghunt login` once) |
| [Toutatis](https://github.com/megadose/toutatis) | `toutatis` | Instagram account details (needs a session ID) |
| [Blackbird](https://github.com/antoniaci/blackbird) | `blackbird` | Username/email search using WhatsMyName data |

## social

| Tool | Command | Purpose |
|---|---|---|
| True Bearing's Telegram engine ([Telethon](https://github.com/LonamiWebs/Telethon), private venv) | `tb_telegram` | Lookups and channel-preview search without a login; with a research account, Telegram search, message search, group members and user profiles |
| [telegram-tracker](https://github.com/estebanpdl/telegram-tracker) | `tgtracker` | Channel collection: posts, metadata, forward networks (its own Python 3.14 through uv) |

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
| [Censys Platform CLI](https://github.com/censys/cencli) | `censys` | Censys Platform search. Run `censys config auth add` once with a personal access token. (Replaces the old censys-python CLI, whose legacy Search API was deprecated in September 2026) |

## media

| Tool | Command | Purpose |
|---|---|---|
| [whisper-ctranslate2](https://github.com/Softcatala/whisper-ctranslate2) | `whisper-ctranslate2` | Offline speech-to-text and translation (used by `tb-video`) |
| [Tesseract](https://github.com/tesseract-ocr/tesseract) / [OCRmyPDF](https://github.com/ocrmypdf/OCRmyPDF) | `tesseract`, `ocrmypdf` | Text recognition in images and scanned PDFs. On Linux, languages for 22 languages in 10 scripts are added (French, German, Spanish, Portuguese, Italian, Dutch, Polish, Turkish, Vietnamese, Indonesian, Russian, Ukrainian, Arabic, Persian, Hebrew, Greek, Hindi, Thai, Chinese simplified and traditional, Japanese, Korean); macOS gets Homebrew's `tesseract-lang` |
| [monolith](https://github.com/Y2Z/monolith) | `monolith` | Saves a web page as one self-contained, isolated HTML file (used by `tb-archive`) |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | `yt-dlp` | Video/audio from thousands of sites |
| [gallery-dl](https://github.com/mikf/gallery-dl) | `gallery-dl` | Image galleries and social posts |
| [Instaloader](https://github.com/instaloader/instaloader) | `instaloader` | Instagram profiles, posts, stories |
| [Streamlink](https://github.com/streamlink/streamlink) | `streamlink` | Record live streams |
| [ExifTool](https://exiftool.org/) | `exiftool` | Read/write metadata in almost any file |
| [MediaInfo](https://mediaarea.net/en/MediaInfo) | `mediainfo` | Technical media metadata |
| [mat2](https://0xacab.org/jvoisin/mat2) | `mat2` | Metadata removal (Linux) |
| [FFmpeg](https://ffmpeg.org/) | `ffmpeg` | Media processing (used by yt-dlp) |
| [internetarchive](https://github.com/jjjake/internetarchive) | `ia` | Search and download from archive.org |

## frameworks

| Tool | Command | Purpose |
|---|---|---|
| [SpiderFoot](https://github.com/smicallef/spiderfoot) | `spiderfoot` | Automated multi-source recon (`spiderfoot -l 127.0.0.1:5001` for the web UI). Unmaintained since 2023, so True Bearing installs it with newer dependencies than it asks for |
| [recon-ng](https://github.com/lanmaster53/recon-ng) | `recon-ng` | Modular recon framework |
| [changedetection.io](https://github.com/dgtlmoon/changedetection.io) | `changedetection.io` | Watch pages for changes (`changedetection.io -d ~/TrueBearing/changedetection -p 5000`) |
| [search-that-hash](https://github.com/HashPals/Search-That-Hash) | `sth` | Look up hashes in public databases |
| [name-that-hash](https://github.com/HashPals/Name-That-Hash) | `nth` | Identify hash types |

## geo

| Tool | Purpose |
|---|---|
| [GeoCLIP](https://github.com/VicenteVivan/geo-clip) | AI location estimate from a photo's scene, run locally (private venv with CPU PyTorch; ~2 GB model on first use) |
| [ShadowFinder](https://github.com/bellingcat/ShadowFinder) | Where on Earth a shadow of a given length occurs at a given time |

## face

OpenCV (private venv) with the OpenCV Zoo [YuNet](https://github.com/opencv/opencv_zoo/tree/main/models/face_detection_yunet) face detector (MIT) and [SFace](https://github.com/opencv/opencv_zoo/tree/main/models/face_recognition_sface) face recogniser (Apache-2.0). The model files are checked against the SHA-256 published in the opencv_zoo repository. Used by `tb-face`.

## translate

[Argos Translate](https://github.com/argosopentech/argos-translate) (MIT) in a private venv (CPU PyTorch on x86_64 Linux), used by `tb-translate`. Language models download from the Argos package index the first time a language pair is used, then everything runs offline.

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

The Tor client as a service (a SOCKS proxy on `127.0.0.1:9050`, never a relay) and `torsocks`, used by `tb-darkweb`, and [OnionShare](https://onionshare.org) for sending and receiving files over private .onion links: the app (Flathub, verified by the OnionShare project, x86_64 and arm64; Homebrew cask on macOS) and `onionshare-cli` (pipx). Tor Browser itself comes with `browsers`. See [BREACH-DARKWEB.md](BREACH-DARKWEB.md).

## gis

[QGIS](https://qgis.org), the desktop GIS, for the case map's GeoJSON and KML exports (Case map → Open the latest case map in QGIS): Flathub, verified by the QGIS project, x86_64 and arm64 (about 600 MB); Homebrew cask on macOS. Skip it with `--skip gis` if you don't need it.

## triage

Tools for checking received or suspicious files without opening them: [ClamAV](https://www.clamav.net) with its signature updater (the `clamav-freshclam` service on Linux, about 200 MB of signatures the first time; Homebrew on macOS) and [oletools](https://github.com/decalage2/oletools) (pipx) for Office macros. Used by Evidence → Check received or suspicious files, and automatically when an OnionShare drop box closes. See [EVIDENCE.md](EVIDENCE.md).

## countries

Creates a private Python environment with Google's [libphonenumber](https://github.com/daviddrysdale/python-phonenumbers) for the phone analysis in `tb-country`. The country packs themselves are installed by `core`, and their bookmark folders by `browsers`. See [COUNTRIES.md](COUNTRIES.md).

## desktop

- **Linux**: `.desktop` launchers for every menu in `~/.local/share/applications` (they show up in any desktop's app menu), plus GNOME dock favourites. On GNOME it also sets a 24-hour clock, shows tray icons (AppIndicator extension), and stops the Activities overview from opening at every login (the packaged *No overview at start-up* extension, where the distribution has it). In a VM it also uses a single fixed workspace, so the screen doesn't slide away when a search reuses a browser window on another workspace, and turns off the top-left hot corner and the lone Super-key trigger. Otherwise the overview opens whenever the pointer leaves the VM window through that corner, or the host's ⌘/Windows key reaches the VM.
- **Guides** (Linux and macOS): every guide in `docs/` as an offline web page in `~/TrueBearing/Guides` (pandoc), rebuilt on each update, with **True Bearing guides** and **True Bearing investigation guide** linked on the desktop. On GNOME it enables the packaged *Desktop Icons NG* extension so desktop icons show. Your own files on the desktop are never replaced.
- **Wallpaper** (GNOME and XFCE): True Bearing's own desktop background, a night chart with a compass rose (true and magnetic north), bearings crossing at a position fix, aurora borealis and a Canadian maple leaf. It's only set if you're still on the distribution's default background. The image is in `~/.local/share/truebearing/share/wallpaper/`.
- **macOS**: `~/Applications/TrueBearing.app`. Your Mac's wallpaper is never changed.

## shell *(Linux only)*

| Component | Purpose |
|---|---|
| [zsh](https://www.zsh.org) | Becomes your login shell |
| [Oh My Zsh](https://ohmyz.sh) | zsh framework, with the plugins below |
| `fzf`, `z` | **Ctrl+R** fuzzy-searches your command history, **Ctrl+T** finds files, **Alt+C** jumps into a subfolder; `z part-of-name` jumps to a folder you've used before (e.g. `z osint_test`) |
| [fzf-tab](https://github.com/Aloxaf/fzf-tab) | **Tab** completion becomes a searchable menu, with a preview of each folder's contents |
| `dirhistory` | **Alt+←** / **Alt+→** go back and forward through folders like a browser; **Alt+↑** goes up a level |
| `history-substring-search` | Type part of a command, then **↑** / **↓** cycles through only the matching history |
| [eza](https://eza.rocks) | Replaces `ls` with icons, colours and git status: `ll` long list, `la` including hidden files, `lt` folder tree |
| [ranger](https://ranger.github.io) | Keyboard file manager with previews. Run `r` to browse; when you quit, the terminal stays in the folder you ended in |
| `web-search` | `google "jane doe" site:linkedin.com`, `ddg …`, `github …` open the search in your browser |
| `urltools`, `encode64`, `jsontools` | `urlencode` / `urldecode`; `e64` / `d64` for base64; `pp_json` pretty-prints JSON, `is_json` checks it |
| `extract` | `x file.zip` (or .tar.gz, .7z, .rar…) unpacks any archive |
| `copypath`, `copyfile`, `copybuffer` | Copy the current folder's path, a file's contents, or (**Ctrl+O**) the command you're typing, for your notes |
| `command-not-found` | Tells you which package provides a command that isn't installed |
| `sudo`, `colored-man-pages`, `git` | **Esc Esc** adds sudo to a command; coloured manuals; git shortcuts |
| [Powerlevel10k](https://github.com/romkatv/powerlevel10k) | The prompt: its "rainbow" style on one line, with a clock (HH:MM:SS) so terminal screenshots show when each command ran; commands taking 3 s or more also show their duration. Restyle any time with `p10k configure` (True Bearing never replaces a style you made) |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Suggests commands from your history as you type (→ to accept) |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Colours commands as you type, so typos show in red |
| [MesloLGS NF](https://github.com/romkatv/powerlevel10k-media) | The font Powerlevel10k's icons need. Set, along with a dark theme, in GNOME Console, Ptyxis, GNOME Terminal and the XFCE terminal (custom navy colours where the terminal allows them) |

All of it is cloned from the official repositories and updated by `tb-update`. Your existing `~/.zshrc`, if any, is kept as `~/.zshrc.pre-truebearing`. The new `~/.zshrc` is yours to edit: True Bearing won't rewrite it. Commands that start with a space aren't saved in history, which is handy for anything sensitive. On macOS this module doesn't run, and your shell is left alone.

## extras

| Tool | Purpose |
|---|---|
| [KeePassXC](https://keepassxc.org) | Store sock-puppet credentials inside the workstation |
| [Flameshot](https://flameshot.org) | Annotated screenshots. Starts at login as a tray icon (click it to capture); Print Screen or Super+Shift+S (Cmd+Shift+S on a Mac keyboard) captures directly on GNOME |
| [OBS Studio](https://obsproject.com) | Screen recording (Flatpak; Debian's package on arm64 Linux) |

## messaging

| App | Source | Notes |
|---|---|---|
| [Telegram Desktop](https://desktop.telegram.org) | Flathub (verified), Homebrew on macOS | x86_64 and arm64 |
| [Signal](https://signal.org) | Signal's apt repository, Homebrew on macOS | x86_64 only on Linux: Signal has no official arm64 Linux build yet |
| [Element](https://element.io) | Element's apt repository, Homebrew on macOS | Matrix client, x86_64 and arm64 |

For research accounts only. `tb-seal` removes their logins from template clones.

## notes

[Obsidian](https://obsidian.md) from Flathub (verified; x86_64 and arm64) or Homebrew, with `~/TrueBearing/Cases` set up as a vault: settings (dark theme, core Templates plugin, attachments beside notes), templates for people, accounts, organisations, places, events and leads, `Home.md`, and a `Case.md` per case. The vault is added to Obsidian's vault list while Obsidian is closed. Used by `tb-notes`.

## lan *(Linux only)*

LAN isolation: installs `nftables` and, **in a VM only**, turns on `tb-lan`, a firewall table that blocks connections from the machine to private networks (your LAN, other VMs, the hypervisor host) while the internet, DNS, DHCP and replies to incoming RDP/SSH keep working. On a physical machine it's left off until you run `tb-lan on`. See [MENUS.md](MENUS.md#tb-lan-linux).

## vm *(Linux only)*

Guest tools for the detected hypervisor (QEMU guest agent and SPICE agent on Proxmox/UTM, open-vm-tools on VMware, a Parallels Tools reminder on Parallels), xrdp with the correct desktop session, a polkit rule that removes the colour-profile prompt over RDP, a first-boot service that regenerates SSH host keys on clones, and `tb-seal`. See [KASM.md](KASM.md).
