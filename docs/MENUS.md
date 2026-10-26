# Menus

All menus save their output to `~/Northstar/Cases/<active case>/<kind>/<target>_<timestamp>/`, seal it with `manifest.sha256` and `provenance.json`, and add a line to the case's hash-chained `audit.log`. Each result folder also has a `console.log` with everything the tools printed. When a tool you started on its own finishes, its folder opens automatically. From the main menu, use **Open latest results** instead, so the menu stays in front.

Launch everything from `northstar`, or each tool on its own (`ns-domain`, etc.) from a terminal or the applications menu.

## northstar

The hub. Besides opening each menu, it lets you:

- **Switch / create case**: sets the active case. Names are sanitised to letters, numbers, `.`, `_`, `@` and `-`.
- **Open latest results**: the folder from the last search you ran
- **Open case folder**
- **Update northstar**: runs `ns-update`.

## ns-username

| Option | Runs | Output |
|---|---|---|
| Username search | sherlock, maigret (HTML report), socialscan, blackbird; opens WhatsMyName and a Google search | `sherlock.txt`, `maigret/`, `blackbird/` (CSV, JSON), `console.log` |
| Email search | holehe (registered sites only), socialscan; opens HIBP, Epieos, IntelX. For breach data use **Breach data** (`ns-breach`) | `console.log` |
| Google account | `ghunt email` | `ghunt.json` |
| Instagram profile details | toutatis (session ID **redacted** from the audit log) | `console.log` |

The search term is copied to your clipboard for the web services that open.

## ns-telegram

Telegram research with [telegram-tracker](https://github.com/estebanpdl/telegram-tracker), using a Telegram **research** account:

| Option | What it does | Output |
|---|---|---|
| Log in to Telegram | One-time login in the terminal: an API ID and hash from my.telegram.org/apps, the phone number and Telegram's code. Saved by telegram-tracker in `~/.telegram_tracker`, never in the audit log | |
| Collect a public channel | Posts, channel metadata and forward sources, optionally since a date; then builds a dataset and a forward network. Opens the channel's web preview and TGStat page | `data/` (JSON, CSV, network files) |
| Collect a list of channels | The same for every channel in a text file (`name`, `@name` or t.me links) | `channels.txt`, `data/` |
| Search for channels | Opens TGStat and Google searches of t.me with your words on the clipboard | |

Collecting is read-only, but it uses your account: Telegram rate-limits heavy collection. `ns-seal` removes the Telegram session from template clones.

## ns-domain

| Option | Runs | Output |
|---|---|---|
| Full subdomain recon | subfinder → dnsx → httpx (titles, status, tech) → gowitness screenshots | `subdomains.txt`, `resolved.txt`, `live.txt`, `live_urls.txt`, `screenshots/` |
| WHOIS, RDAP & DNS records | whois, RDAP (registrar, dates, nameservers, status: RDAP replaced WHOIS for generic TLDs in 2025), dig for A/AAAA/MX/NS/TXT/SOA/CAA; opens crt.sh, URLScan, ViewDNS reverse IP and the RDAP web client | `whois.txt`, `rdap.json`, `rdap.txt`, `dns.txt` |
| Emails & hosts | theHarvester across all passive sources (sources that need an API key you haven't configured are skipped with a note) | `theharvester.json` / `.xml` (plus `.jsonl` with theHarvester 5 on Python 3.14+) |
| Passive enumeration | `amass enum` (passive by default in Amass v5), then `amass subs -names` | `amass.txt` (every name Amass's database holds for the domain, including earlier runs) |
| Crawl a site | katana, depth 3, with JavaScript parsing | `crawl.txt` |
| Archived URLs | waymore | `archived_urls.txt` |
| Lookalike domains | dnstwist, registered only | `lookalikes.csv` |
| Screenshot a URL list | gowitness on a text file you choose | `screenshots/` |

You can paste a full URL as the domain. The scheme, path and `www.` are stripped automatically, and anything that isn't a valid domain name is refused.

## ns-media

| Option | Runs | Notes |
|---|---|---|
| Video | yt-dlp best quality + info JSON, description, thumbnail, subtitles | Filenames include uploader, title and video ID |
| Audio only | yt-dlp to MP3 + info JSON | |
| Whole channel or playlist | yt-dlp with a download archive | Re-running only fetches new items |
| Image gallery | gallery-dl with metadata | Works with most social platforms |
| Instagram profile | instaloader | Use `instaloader --login <puppet>` once to avoid rate limits |
| Record a live stream | streamlink, best quality | Ctrl+C to stop |
| Save to the Internet Archive | Requests a Wayback capture; opens Wayback and archive.today | `wayback.txt` records the URL, the UTC time and the result: the capture URL, or why it failed (e.g. rate-limited) |

Addresses must start with `http://` or `https://`, so nothing typed in can be mistaken for a command-line option.

## ns-archive

Evidence-grade web page capture. Each page gets its own folder:

| File | Contents |
|---|---|
| `page.html` | Single-file copy (monolith), **isolated**: opening it can't contact the internet |
| `screenshot*.jpeg`, `gowitness.jsonl` | Full-page screenshot and its details (gowitness) |
| `headers.txt`, `capture.txt` | Response headers; UTC capture time, HTTP status, final URL after redirects, server IP, Wayback result |
| `rdap.json` | Who held the domain at capture time |

Options: capture one page, capture a list of URLs from a text file, or look up existing archived copies (Wayback, archive.today, Memento TimeTravel). The folder is sealed, you can record it as an exhibit straight away, and archive.today opens so you can add an independent public copy (it needs a CAPTCHA). Pages are fetched over your own connection: use a VPN if your work needs it.

## ns-video

Video verification, from a URL (downloaded with yt-dlp, plus its info JSON, description, thumbnail and comments) or a local file (copied with its timestamps, and the original's SHA-256 recorded).

| Output | Contents |
|---|---|
| `frames/` | A frame at every scene change, and one every 10 seconds, for reverse image search |
| `ffprobe.txt`, `mediainfo.txt`, `exif.txt` | Technical metadata: codecs, durations, creation tags, encoder |
| `transcript/` | Offline transcript of the speech (whisper-ctranslate2, "small" model): text, subtitles (SRT/VTT), JSON with timings. Optional |
| `translation/` | English translation, offered when the speech isn't English |

Transcription runs entirely on your computer. The first time, it downloads a ~500 MB speech model; after that, nothing is sent anywhere. At the end, the reverse image search pages and the frames folder open so you can drag in the most distinctive frames.

## ns-metadata

| Option | Runs | Output |
|---|---|---|
| View metadata | exiftool for every selected file (plus mediainfo for audio/video). If GPS is present, the location opens in Maps. | `<file>.exif.txt`, `<file>.mediainfo.txt`, `<file>.gps.txt` |
| Export folder to CSV | `exiftool -r -csv` | `metadata.csv` |
| Make clean copies | Copies files, then strips metadata with mat2 (or exiftool) | Cleaned copies. **Originals are never modified.** |
| Make a scanned PDF searchable | OCRmyPDF on a copy (pages that already have text are skipped) | `<name>.original.pdf`, `<name>.searchable.pdf`, `<name>.txt` |

## ns-image

| Option | What happens |
|---|---|
| Reverse search an image URL | Opens Google Lens, Yandex, Bing and TinEye with the URL; saves a copy and its EXIF |
| Read the text in images (OCR) | Tesseract on one or more images, in every installed language. Text goes to `<image>.txt`. On Debian, add languages with e.g. `sudo apt install tesseract-ocr-fra` |
| Analyze a local image | Copies the image to the case, saves its EXIF and a SHA-256 hash, opens Maps if GPS is present, and opens reverse-search pages ready for drag-and-drop |

## ns-country

Country-specific public-records searches. `ns-country` asks for a country, or takes a code: `ns-country GB`. `ns-canada` opens the Canada pack directly. See [COUNTRIES.md](COUNTRIES.md).

## ns-breach

Breach and infostealer lookups by email, username, domain or phone, a password exposure check, and HIBP's breach catalogue. Free sources always run; paid ones run with your API keys. See [BREACH-DARKWEB.md](BREACH-DARKWEB.md).

## ns-darkweb

Tor connection check, onion search (Ahmia), text-only capture of an onion page, ransomware leak-site claims, and Tor Browser. See [BREACH-DARKWEB.md](BREACH-DARKWEB.md).

## ns-keys

Add, check or remove API keys (Have I Been Pwned, Intelligence X, DeHashed, LeakCheck). Keys are typed into a hidden field, stored in `~/.config/northstar/keys.env` (readable only by you), and never logged.

## ns-evidence

Record result folders as numbered exhibits (optional OpenTimestamps proof), verify folders and the audit log's hash chain, list exhibits, and export the case with a SHA-256. Every result folder is sealed automatically when a search finishes. See [EVIDENCE.md](EVIDENCE.md).

## ns-update

Pulls the latest northstar-osint and runs `install.sh --update --yes` for every module except the ones you chose to skip, so modules added in a new release are installed too. If the download fails (usually because files in the checkout were edited by hand), it says so clearly, still upgrades the installed tools, and exits with an error.

## ns-seal *(Linux, run with sudo)*

Prepares a **clone** for templating. See [KASM.md](KASM.md).

## ns-linkcheck

Checks every URL in the bookmark collection. Codes 401/403/405/429 usually mean the site blocks scripts, so check those by hand.

```bash
ns-linkcheck                                  # installed bookmarks
ns-linkcheck ~/.config/northstar/bookmarks.local.json
```
