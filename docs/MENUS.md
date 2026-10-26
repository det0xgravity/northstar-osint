# Menus

All menus save their output to `~/Northstar/Cases/<active case>/<kind>/<target>_<timestamp>/` and add a line to the case's `audit.log`. Each result folder also has a `console.log` with everything the tools printed. When a search finishes, the folder opens automatically.

Launch everything from `northstar`, or each tool on its own (`ns-domain`, etc.) from a terminal or the applications menu.

## northstar

The hub. Besides opening each menu, it lets you:

- **Switch / create case**: sets the active case. Names are sanitised to letters, numbers, `.`, `_`, `@` and `-`.
- **Open case folder**
- **Update northstar**: runs `ns-update`.

## ns-username

| Option | Runs | Output |
|---|---|---|
| Username search | sherlock, maigret (HTML report), socialscan, blackbird; opens WhatsMyName and a Google search | `sherlock.txt`, `maigret/`, `console.log` |
| Email search | holehe (registered sites only), socialscan, h8mail; opens HIBP, Epieos, IntelX | `h8mail.csv`, `console.log` |
| Google account | `ghunt email` | `ghunt.json` |
| Instagram profile details | toutatis (session ID **redacted** from the audit log) | `console.log` |

The search term is copied to your clipboard for the web services that open.

## ns-domain

| Option | Runs | Output |
|---|---|---|
| Full subdomain recon | subfinder → dnsx → httpx (titles, status, tech) → gowitness screenshots | `subdomains.txt`, `resolved.txt`, `live.txt`, `live_urls.txt`, `screenshots/` |
| WHOIS & DNS records | whois, dig for A/AAAA/MX/NS/TXT/SOA/CAA; opens crt.sh, URLScan, ViewDNS reverse IP | `whois.txt`, `dns.txt` |
| Emails & hosts | theHarvester across all passive sources (sources that need an API key you haven't configured are skipped with a note) | `theharvester.json` / `.xml` (plus `.jsonl` with theHarvester 5 on Python 3.14+) |
| Passive enumeration | `amass enum` (passive by default in Amass v5), then `amass subs -names` | `amass.txt` (every name Amass's database holds for the domain, including earlier runs) |
| Crawl a site | katana, depth 3, with JavaScript parsing | `crawl.txt` |
| Archived URLs | waymore | `archived_urls.txt` |
| Lookalike domains | dnstwist, registered only | `lookalikes.csv` |
| Screenshot a URL list | gowitness on a text file you choose | `screenshots/` |

You can paste a full URL as the domain. The scheme, path and `www.` are stripped automatically.

## ns-media

| Option | Runs | Notes |
|---|---|---|
| Video | yt-dlp best quality + info JSON, description, thumbnail, subtitles | Filenames include uploader, title and video ID |
| Audio only | yt-dlp to MP3 + info JSON | |
| Whole channel or playlist | yt-dlp with a download archive | Re-running only fetches new items |
| Image gallery | gallery-dl with metadata | Works with most social platforms |
| Instagram profile | instaloader | Use `instaloader --login <puppet>` once to avoid rate limits |
| Record a live stream | streamlink, best quality | Ctrl+C to stop |
| Save to the Internet Archive | Requests a Wayback capture; opens Wayback and archive.today | `wayback.txt` holds the capture URL |

## ns-metadata

| Option | Runs | Output |
|---|---|---|
| View metadata | exiftool for every selected file (plus mediainfo for audio/video). If GPS is present, the location opens in Maps. | `<file>.exif.txt`, `<file>.mediainfo.txt`, `<file>.gps.txt` |
| Export folder to CSV | `exiftool -r -csv` | `metadata.csv` |
| Make clean copies | Copies files, then strips metadata with mat2 (or exiftool) | Cleaned copies. **Originals are never modified.** |

## ns-image

| Option | What happens |
|---|---|
| Reverse search an image URL | Opens Google Lens, Yandex, Bing and TinEye with the URL; saves a copy and its EXIF |
| Analyze a local image | Copies the image to the case, saves its EXIF and a SHA-256 hash, opens Maps if GPS is present, and opens reverse-search pages ready for drag-and-drop |

## ns-canada

See [CANADA.md](CANADA.md).

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
