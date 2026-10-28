# Menus

All menus save their output to `~/TrueBearing/Cases/<active case>/<kind>/<target>_<timestamp>/`, seal it with `manifest.sha256` and `provenance.json`, and add a line to the case's hash-chained `audit.log`. Each result folder also has a `console.log` with everything the tools printed. When a tool you started on its own finishes, its folder opens automatically. From the main menu, use **Open latest results** instead, so the menu stays in front.

Launch everything from `truebearing`, or each tool on its own (`tb-domain`, etc.) from a terminal or the applications menu.

## True Bearing

The hub. Besides opening each menu, it lets you:

- **Switch / create case**: sets the active case. Names are sanitised to letters, numbers, `.`, `_`, `@` and `-`.
- **Open latest results**: the folder from the last search you ran
- **Open case folder**
- **LAN isolation (firewall)**: `tb-lan`, see [below](#tb-lan-linux).
- **Guides (how to investigate, manuals)**: these guides as offline web pages (`tb-guides`). They're also linked on the desktop.
- **Health check**: `tb-doctor`.
- **Update True Bearing**: runs `tb-update`.

## tb-missing

**Missing person**: subject profile, a timeline built from the whole case and placed relative to the last-seen moment, a findings (CTF flag) log with evidence hashes, duplicate warnings and an export, and **Missing-persons databases** (a country's missing-persons search with the subject's name pre-filled). See [MISSING-PERSONS.md](MISSING-PERSONS.md).

## tb-username

| Option | Runs | Output |
|---|---|---|
| Username search | sherlock, maigret (HTML report), socialscan, blackbird; opens WhatsMyName and a Google search | `sherlock.txt`, `maigret/`, `blackbird/` (CSV, JSON), `console.log` |
| Email search | holehe (registered sites only), socialscan; opens HIBP, Epieos, IntelX. For breach data use **Breach data** (`tb-breach`) | `console.log` |
| Google account | `ghunt email` | `ghunt.json` |
| Generate username and email variants | From a full name and birth year (pre-filled from the Missing person profile): likely usernames (`janedoe`, `jane.doe`, `jdoe`, `janedoe99`, …; accents removed, compound surnames handled) and emails at common providers. Optionally checks the top 10 usernames with Sherlock and the top 10 emails with holehe | `usernames.txt`, `emails.txt`, `sherlock/`, `console.log` |
| Instagram profile details | toutatis (session ID **redacted** from the audit log) | `console.log` |
| Analyse email headers (offline) | A saved message (`.eml`) or its headers: the relay hops oldest first with IPs and UTC times, the first public IP, SPF/DKIM/DMARC as recorded by the receiving server, and warning signs (a Reply-To elsewhere, From/Return-Path/DKIM domains that don't match, failed checks, times out of order). Nothing is looked up; the message is kept in the case with the analysis. IPs and addresses go to Selectors | `headers.txt`, `headers.json`, the message |

The search term is copied to your clipboard for the web services that open.

**Adult (NSFW) sites** are left out of username searches unless the case allows them (Case → **Adult-site (NSFW) searches**). Then Sherlock adds its NSFW sites (`--nsfw`), Maigret also checks every site it tags porn, erotic or webcam (a second report in `maigret-adult/`), and Blackbird keeps its NSFW sites (otherwise `--no-nsfw`). Each result folder's `search-settings.txt` says which applied. Dating sites are searched either way. Username variants are never checked against adult sites: they're guesses.

## tb-telegram

Telegram research. The first options need no account: they read Telegram's public web pages (text only). The rest use a Telegram **research** account, never a personal one.

| Option | What it does | Output |
|---|---|---|
| Look up a channel, group, bot or user | What `t.me/<name>` shows: type, title, bio or description, subscriber or member count | `lookup.json` |
| Search a public channel's posts | Searches the channel's web preview (`t.me/s/<name>?q=`): the most recent matches, with date, link, views and text | `posts.csv` |
| Search for channels | Opens TGStat and Google searches of t.me with your words on the clipboard | |
| Search Telegram for public chats and users | Telegram's own search for public channels, groups, bots and users matching a word or name, with member counts and scam/fake flags | `search.csv` |
| Search messages in a channel or group | Every matching message (or the latest, up to a limit) with sender ID, views, forwards, forward source, replies and media type | `messages.csv`, `chat.json` |
| Members of a group | The members a non-admin can see: ID, username, names, phone (only when the member shares it), bot, premium, last seen. Groups that hide their member list are reported as such | `members.csv` |
| User profile | ID, names, all usernames, bio, premium, birthday and personal channel when public, chats in common with the research account, and the current profile photo | `user.json`, `profile_photo.jpg` |
| Collect a public channel | [telegram-tracker](https://github.com/estebanpdl/telegram-tracker): posts, channel metadata and forward sources, optionally since a date, then a dataset and forward network | `data/` |
| Collect a list of channels | The same for every channel in a text file (`name`, `@name` or t.me links) | `channels.txt`, `data/` |
| Log in for searches | One-time login in the terminal for the searches above. Add the API ID and hash from [my.telegram.org/apps](https://my.telegram.org/apps) under **API keys** first, then type the phone number, Telegram's code and the 2FA password. The session is kept in `~/.config/truebearing/telegram/` (readable only by you) | |
| Log in for channel collection | telegram-tracker's own login, saved in `~/.telegram_tracker` | |

Searches are read-only, but they use the account: Telegram rate-limits heavy use and the menu says how long to wait. Viewing doesn't notify anyone, but joining a group or messaging someone would: don't. Neither the API hash nor the login code ever reaches `audit.log`, and `tb-seal` removes both sessions from template clones.

## tb-domain

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

## tb-media

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

## tb-archive

Evidence-grade web page capture. Each page gets its own folder:

| File | Contents |
|---|---|
| `page.html` | Single-file copy (monolith), **isolated**: opening it can't contact the internet |
| `screenshot*.jpeg`, `gowitness.jsonl` | Full-page screenshot and its details (gowitness) |
| `headers.txt`, `capture.txt` | Response headers; UTC capture time, HTTP status, final URL after redirects, server IP, Wayback result |
| `rdap.json` | Who held the domain at capture time |

Options: capture one page, capture a list of URLs from a text file, or look up existing archived copies (Wayback, archive.today, Ghostarchive). The folder is sealed, you can record it as an exhibit straight away, and archive.today opens so you can add an independent public copy (it needs a CAPTCHA). Pages are fetched over your own connection: use a VPN if your work needs it.

## tb-video

Video verification, from a URL (downloaded with yt-dlp, plus its info JSON, description, thumbnail and comments) or a local file (copied with its timestamps, and the original's SHA-256 recorded).

| Output | Contents |
|---|---|
| `frames/` | A frame at every scene change, and one every 10 seconds, for reverse image search |
| `ffprobe.txt`, `mediainfo.txt`, `exif.txt` | Technical metadata: codecs, durations, creation tags, encoder |
| `transcript/` | Offline transcript of the speech (whisper-ctranslate2, "small" model): text, subtitles (SRT/VTT), JSON with timings. Optional |
| `translation/` | English translation, offered when the speech isn't English |

Transcription runs entirely on your computer. The first time, it downloads a ~500 MB speech model; after that, nothing is sent anywhere. At the end, the reverse image search pages and the frames folder open so you can drag in the most distinctive frames.

## tb-geo

Photo geolocation. **Images never leave your computer.** Only coordinates are looked up, and only if you agree.

| Option | What it does | Output |
|---|---|---|
| Where was this photo taken? | Copies the photo (recording the original's SHA-256), reads EXIF GPS and capture time, reads visible text with OCR, then optionally runs [GeoCLIP](https://github.com/VicenteVivan/geo-clip), an AI model that estimates the location from the scene, on your computer. Optionally looks up place names for the top 5 candidates (OpenStreetMap; coordinates only). Opens maps and Mapillary street-level imagery for the strongest leads, plus Bellingcat OSM Search and Google Lens | `exif.txt`, `text.txt`, `geoclip.csv` (top 10: lat, lon, probability), `places.json` |
| Shadow analysis | [ShadowFinder](https://github.com/bellingcat/ShadowFinder): from an object's height, its shadow's length and the UTC time, maps everywhere on Earth that shadow could occur | `shadow_finder_*.png` |
| Find places by features | Bellingcat OSM Search: places where features occur together (e.g. a church near a river and a fuel station) | |
| Match a skyline or landmark | PeakVisor (mountains and ridgelines) and Google Lens | |

GeoCLIP is often right to the country or region, sometimes the city, rarely the street. Treat its candidates as leads, and confirm them with street-level imagery, landmarks and shadows. The first run downloads its model (about 2 GB). Never upload victim photos, especially of minors, to online services; this menu keeps them on your machine.

## tb-face

Face comparison **within the active case only**: a reference face (for example a missing-person poster) against faces in photos you've already collected in the case. It runs locally with OpenCV's YuNet detector (MIT) and SFace recogniser (Apache-2.0). Nothing is uploaded, and no outside or online photos are searched.

**Safeguards:**
- **Lawful basis first:** the first use in a case asks for its purpose and lawful basis, recorded in `face-comparison-basis.txt` and the audit log.
- **Case photos only:** a folder outside the case is refused.
- **Similarity, never identification:** scores are reported in bands, ≥ 0.50 strong, 0.363–0.50 possible, below that unlikely. Faces too small to judge are flagged.
- **Every run is logged and sealed,** with the reference photo's hash recorded.

| Output | Contents |
|---|---|
| `results.html` | The reference face beside every face found, highest similarity first: open it to review |
| `results.csv` | Image, face number, score, band, quality, detector confidence, position |
| `crops/` | The aligned face crops that were compared |

Accuracy drops for small, blurred or angled faces, children, large age gaps, and differs between demographic groups. A score is a lead for human review and independent corroboration, never an identification on its own. Faces are biometric data: you need a lawful basis to process them, and images of minors only with a law-enforcement partner or equivalent authority.

## tb-watch

Page monitoring: watch public pages (a subject's profile, a `t.me/s/<channel>` preview, a fundraising or missing-person post) for changes, as proof of life or new activity. Each page's visible text is compared with the last snapshot. Pages that need a login or render entirely in JavaScript can't be watched this way.

| Option | What it does |
|---|---|
| Watch a page | Adds the address to the case and records a baseline |
| Check watched pages now | Checks this case's pages; changes are shown with their new lines |
| Recent changes | The last 20 changes in this case |
| List / Stop watching | Manage the case's watched pages |
| Scheduled checks | Every 3, 6, 12 or 24 hours while you're logged in (a systemd user timer on Linux, a launchd agent on macOS), across every open case, with a desktop notification on change. Closed cases are skipped |

Everything is kept in the case's `watch/` folder: `watches.json`, a text snapshot and a diff for every change under `watch/<ID>/` (UTC file names), and `changes.log`. Every baseline and change is also written to the hash-chained `audit.log`. Checks come from your own connection, so keep the number of watched pages and the frequency modest.

## tb-map

Every coordinate in the active case on one map.

| Source | Shown as |
|---|---|
| Places you record with **Add a place** (last seen, sighting, home, work or school, vehicle, other), by address or `lat, lon` | Coloured by kind; "last seen" is pre-filled from the missing-person profile |
| GPS in photo and video metadata anywhere in the case (exiftool) | photo GPS, with the camera-clock time |
| GeoCLIP's top three estimates from each Photo geolocation run, named from `places.json` | AI estimate |

**Build the case map** writes `case.geojson` and `case.kml` (open them offline in QGIS or Google Earth Pro; **Open the latest case map in QGIS** does it for you, with no background map until you add one), `points.csv`, and `map.html`, an interactive map with a layer for each kind. Opening `map.html` loads Leaflet from unpkg (pinned and integrity-checked) and map tiles from CARTO or OpenStreetMap, so those services see which areas you view; the menu asks first. Address lookups use OpenStreetMap Nominatim and are logged in the audit log. Recorded places are kept in the case's `map/places.csv`.

## tb-translate

Offline text translation with [Argos Translate](https://github.com/argosopentech/argos-translate) (MIT). The text never leaves your computer: only the one-time download of each language model (about 100 MB per pair) uses the internet. Pairs without a direct model go through English.

| Option | What it does |
|---|---|
| Translate text | Translates a short passage, shows it and copies it to the clipboard |
| Translate text files | Posts, transcripts (`tb-video`), subtitles (`.srt`, `.vtt`), captured page text: each file is copied into the result folder beside `<name>.<language>.<ext>` |

Results are saved under `translation/` in the case and sealed. Machine translation is a lead: slang, names and dialect are often wrong, so have anything that matters checked by a qualified translator. For speech, use Video verification, which transcribes and translates the audio.

## tb-notes

**Notes (Obsidian)**: `~/TrueBearing/Cases` is one [Obsidian](https://obsidian.md) vault that works as the case hub, from intake to the final report.

| In each case | What it is |
|---|---|
| `Case.md` | The dashboard: case details; counts; findings with their status, grading and checks; latest results; working notes; key records (contemporaneous notes, subject profile, timeline, case map, exhibits, latest report and review); integrity of the notes, audit log and exhibits; page-monitoring changes. Your summary, analysis and next steps go below the generated block, and become the report's summary and analysis |
| `Findings/` | Your conclusions, one note each: status (lead, corroborated, confirmed, discounted), reportable, source and information grades, the results and exhibits it rests on, and what was observed kept apart from your assessment |
| `Results/` | One note per result folder: provenance, exhibit number, integrity, the tool's output as tables and text, tool hits (unverified), images, files. Your **Analyst notes** below the generated part, and properties you add (`relevance`, `reviewed`, `nil_return`), are kept when it's rebuilt |
| `Chronology.md` | The subject's timeline: Event notes (with **when_utc**, **time_kind** and **reportable**), findings with a time, the missing-person timeline (last seen, posts, photo times) and timed places on the case map, oldest first, with the kind of time (camera clock, platform, analyst, witness) and a link to the source. Entries marked reportable, and the last-seen time, go into the report |
| `Handover.md` | For whoever takes the case over: intake and lawful basis, integrity checks, where the findings and report stand, the last review, open leads with who owns them (**assigned_to**), unticked next steps from Case.md, decisions (contemporaneous notes that start with `DECISION:`) and the latest notes |
| `Selectors.md` | Every identifier the tools reported (usernames, emails, phone numbers, domains, IP and onion addresses, Telegram IDs, coordinates, crypto addresses, profile URLs), read from each tool's result files, never from whole captured pages. The exception is **crypto addresses** (Bitcoin legacy, P2SH and bech32, and Ethereum-style `0x…`), which are also read from captured onion pages, Telegram posts and messages: Bitcoin addresses are kept only if their checksum is valid, so a typo or a random string never appears; `0x…` addresses can only be checked for shape. For each: how many different tools saw it, when it was first seen, the result notes it's in, and the searches that would take it further (✓ marks one already run on that value). Candidate usernames from the variants tool aren't included: they're guesses |
| `Accounts.md` | Account tool hits merged across tools. Accounts reported by two or more tools get a generated Account note (`Accounts/`), labelled unverified, where you record whether it's verified and whose it is. Account notes you write yourself are never changed |
| `Link chart.canvas` | A link chart (Obsidian's core Canvas): people, accounts and identifiers seen by two or more tools, with "owned by" and username links. Rebuilt while you haven't changed it; once you edit it, True Bearing writes `Link chart (generated).canvas` beside it instead |
| `People/`, `Accounts/`, `Organisations/`, `Places/`, `Events/`, `Leads/` | Working notes from the templates in `Cases/_templates/` |

| Option | What it does |
|---|---|
| Open this case's notes | Opens `Case.md` |
| New finding from the latest result | A Finding note already linked to the result you just ran, with its exhibit ID if you've recorded it as one |
| New note: finding / person / account / organisation / place / event / lead | A note from its template |
| Discount a finding | Marks it discounted with your reason (also written to the contemporaneous notes). Findings are never deleted: the report lists discounted and unreported findings as unused material, and flags finding notes that have been deleted |
| Open the Cases vault | `Home.md`: every case with status, reference, results and last activity |
| Refresh this case's notes | Rebuilds every result note (your analyst notes are kept) |
| Add a contemporaneous note | The tamper-evident note |

### From findings to the report

1. Record conclusions as **Findings**, linked to the result notes and exhibits that support them. Grade the source (A–F) and the information (1–6).
2. When a finding is corroborated or confirmed, set **reportable: true**.
3. A supervisor records a review (Case → **Record a supervisor review**). The review is written to the hash-chained notes with the fingerprints of the findings and of the summary, analysis and next steps in Case.md.
4. **Build a report** (Case menu) writes `reports/v<n>_<time>/`, which contains:

   | File | Contents |
   |---|---|
   | `report.docx` | The report |
   | `report.md` | Its source |
   | `findings-section.md` | The generated findings part of the report |
   | `findings-frozen.md` | A verbatim copy of the findings it used |
   | `hashes.sha256` | SHA-256 of report.md, report.docx and findings-frozen.md |

   The report's hash and the findings fingerprint are written to the contemporaneous notes.

**What the report contains:**
- your Summary and Analysis;
- each reportable finding with its grading, what was observed, your assessment, and its evidence. Every exhibit's fingerprint and files are re-checked;
- the chronology: Event notes marked reportable, reported findings with a time, and the last-seen time;
- searches with no result: notes you marked `nil_return: true`, plus searches that saved no output and haven't been checked yet;
- unused material;
- the latest review;
- then methodology, exhibits, notes and the audit log.

**Warnings:** anything that doesn't hold up is listed at the top, and you're asked before the report is built. That covers a missing or incomplete intake record, a reportable finding with no sealed evidence, missing grades, an exhibit or file that no longer matches, findings or the Case.md summary changed since the review, no review at all, or a deleted finding. A finding that links a result recorded as an exhibit is checked against the exhibit register.

Each result note opens with **Highlights** for its tool (hits and the tools that reported them, subdomain and live-host counts and registration details, breach summary lines, Telegram IDs and member or message counts, top face-comparison scores with the similarity caveat, top GeoCLIP estimates with the caveat that they're leads, dark-web page details, downloaded media titles). Notes for result folders that have been deleted are removed, or kept with **folder_missing: true** if you wrote in them.

**Finding your way:** `Home.md` has ready-made searches (findings for the report, unverified accounts, open leads, results not yet reviewed, searches that saved nothing), and Obsidian's bookmarks get a **True Bearing** group with every case's dashboard, chronology, selectors, accounts, handover and results.

**Times:** every time True Bearing writes is UTC (properties ending `_utc`). Obsidian's own Templates command fills `{{date}}` with your computer's local date: use it only for `created`, and give event and finding times in UTC.

**Look:** a True Bearing theme snippet, and a snippet that hides raw tool folders and case files from the file list. Links and embeds still work; to browse them, turn off **truebearing-hide-raw** in Settings → Appearance → CSS snippets.

**Safety:**
- **Result notes are views of the sealed folders;** your conclusions live in Findings.
- **Web content is escaped or fenced, and file names that could break a link are shown as text,** so nothing collected can render as HTML or load remote images in Obsidian. Captured web pages are listed but not linked.
- **`notes.md` is read-only on disk,** so Obsidian can't edit it by accident. Add to it through Case → Add a note.
- **Community plugins stay off** unless you turn them on.

## tb-metadata

| Option | Runs | Output |
|---|---|---|
| View metadata | exiftool for every selected file (plus mediainfo for audio/video). If GPS is present, the location opens in Maps. | `<file>.exif.txt`, `<file>.mediainfo.txt`, `<file>.gps.txt` |
| Export folder to CSV | `exiftool -r -csv` | `metadata.csv` |
| Make clean copies | Copies files, then strips metadata with mat2 (or exiftool) | Cleaned copies. **Originals are never modified.** |
| Make a scanned PDF searchable | OCRmyPDF on a copy (pages that already have text are skipped) | `<name>.original.pdf`, `<name>.searchable.pdf`, `<name>.txt` |

## tb-image

| Option | What happens |
|---|---|
| Reverse search an image URL | Opens Google Lens, Yandex, Bing and TinEye with the URL; saves a copy and its EXIF |
| Find the same photo across this case | Perceptual hashing (pHash + dHash, local): finds every picture that appears more than once in the case, or every copy of one photo, even resized, recompressed, converted or lightly edited. Repeated photos across accounts often show the accounts are connected. Heavy crops and mirroring defeat it | `same_photos.html` (side-by-side groups), `same_photos.csv` |
| Read the text in images (OCR) | Tesseract on one or more images. Each image's writing system is detected first (Latin, Cyrillic, Arabic, Hebrew, Greek, Devanagari, Thai, Chinese, Japanese, Korean) and only those languages are used, plus English, which signs often add. Text goes to `<image>.txt`. Photo geolocation reads signs the same way. Machine-read text in a foreign script is a lead: check it, and translate it with **Translate (offline)** |
| Analyze a local image | Copies the image to the case, saves its EXIF and a SHA-256 hash, opens Maps if GPS is present, and opens reverse-search pages ready for drag-and-drop |
| Face search engines (online; read the warning) | Opens PimEyes, FaceCheck.ID, Search4faces and Lenso.ai, after a warning: the photo leaves your computer, a face is biometric data, results are look-alikes, not identifications. It won't open them if the person could be under 18 or the photo is of a victim, and asks for your reason and lawful basis, written to the notes as a `DECISION:` and to the audit log. The bookmark of the same name opens the warning as a page, which records nothing |

## tb-country

Country-specific public-records searches. `tb-country` asks for a country, or takes a code: `tb-country GB`. `tb-canada` opens the Canada pack directly. See [COUNTRIES.md](COUNTRIES.md).

## tb-breach

Breach and infostealer lookups by email, username, domain or phone, a password exposure check, and HIBP's breach catalogue. Free sources always run; paid ones run with your API keys. See [BREACH-DARKWEB.md](BREACH-DARKWEB.md).

## tb-darkweb

Tor connection check, onion search (Ahmia), text-only capture of an onion page, ransomware leak-site claims, Tor Browser, and OnionShare: a private drop box that receives files from a source into the case, and sending files (such as a case export) over a private .onion link. See [BREACH-DARKWEB.md](BREACH-DARKWEB.md).

## tb-lan *(Linux)*

**LAN isolation (firewall)** in the main menu. An nftables table (`inet truebearing_lan`) that stops this machine from **opening** connections to private networks: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, carrier-grade NAT `100.64.0.0/10`, link-local, multicast, and their IPv6 equivalents. A hostile page, document or tool output opened during an investigation then can't reach your router's admin page, NAS, printers, other VMs or the hypervisor host.

What still works: the internet, DNS and DHCP from the local router, IPv6 neighbour discovery, and replies to connections made **to** this machine, so RDP from Kasm and SSH keep working.

| Option (or command) | What it does |
|---|---|
| Status (`tb-lan status`) | On or off, the allow list, and how many packets have been blocked |
| Turn on / off (`tb-lan on`, `tb-lan off`) | Loads or removes the rules; a systemd service (`truebearing-lan-block`) loads them at every boot |
| Allow an address or network (`tb-lan allow 192.168.1.20`) | An exception, for example a NAS holding case data (`TB_DATA` on a share) or a Tailscale network (`100.64.0.0/10`) |
| Remove an allowed address (`tb-lan remove …`) | |

The `lan` module turns it on during the first install **in a VM**, and leaves it alone afterwards if you turn it off. On a physical machine it stays off (it would block your own printers and NAS) until you run `tb-lan on`. The rules are in `/etc/truebearing/lan-block.nft` and the allow list in `/etc/truebearing/lan-allow`. Changes are written to the active case's audit log.

## tb-keys

Add, check or remove API keys (Have I Been Pwned, Intelligence X, DeHashed, LeakCheck). Keys are typed into a hidden field, stored in `~/.config/truebearing/keys.env` (readable only by you), and never logged.

## tb-case

Case records (main menu: **Case: notes, details, report, close**; **Switch / create case** opens the same flow).

| Option | What it does | Output (in the case folder) |
|---|---|---|
| Open or switch case | A new case asks for its intake details: client or matter reference, who authorised it, purpose and lawful basis, scope and subjects, review or retention date. An existing case is switched to, never overwritten | `case.json`, `scope.md` |
| Add a note | A contemporaneous note, saved with the UTC time and operator, and hash-chained so later edits show. Not possible on a closed case | `notes.md` |
| Case details | Shows the intake record and status | |
| Edit case details (intake) | Changes the reference, authority, lawful basis, scope or review date (empty a field to clear it; Cancel changes nothing). Each change goes into the notes with its old and new value; intake recorded after the case was opened is marked late | `case.json`, `scope.md`, `notes.md` |
| Build a report | A Word document (pandoc) from the case details, your Summary and Analysis in Case.md, the reportable findings and their checked exhibits, nil returns, unused material, the latest review, methodology (the tools and sources actually used, from the audit log), exhibits, notes and the audit log. Warnings are listed first. See [From findings to the report](#from-findings-to-the-report) | `reports/v<n>_<UTC>/`: `report.docx`, `report.md`, `findings-section.md`, `findings-frozen.md`, `hashes.sha256` |
| Record a supervisor review | Reviewer, role, decision and comments, written to the notes with the fingerprint of the findings reviewed | `notes.md` |
| Adult-site (NSFW) searches | Allows or stops adult sites in username searches for this case. Allowing them asks whether anyone searched for could be under 18 (if so, they stay off) and for a reason, recorded as a `DECISION:` note | `case.json`, `notes.md` |
| Verify notes and audit log | Checks both hash chains | |
| Close this case | First lists anything unfinished: notes, audit log or exhibits that don't verify, no report or one older than the findings, no review covering the current findings and summary, an incomplete intake, open leads. Closing anyway writes those points to the notes. Then it verifies the audit log, exports the case with a SHA-256 to `~/TrueBearing/Exports`, and marks it closed. Nothing is deleted | `case.json` status |
| Reopen this case | Shown instead of Close on a closed case. Asks for the reason, which goes into the notes | `case.json` status |

## tb-evidence

Record result folders as numbered exhibits (optional OpenTimestamps proof), verify folders and the audit log's hash chain, list exhibits, and export the case with a SHA-256. Every result folder is sealed automatically when a search finishes. See [EVIDENCE.md](EVIDENCE.md).

## tb-doctor

**Health check** in the main menu. Lists every tool with its version, flags anything missing, and checks API key and case folder permissions, ports listening on the network (xrdp 3389, the amass engine 4000, Tor 9050), Firefox policies, free disk space and recent install warnings. The report is saved to `~/TrueBearing/support/` for bug reports. It contains no API keys or case data.

## tb-update

Pulls the latest truebearing-osint and runs `install.sh --update --yes` for every module except the ones you chose to skip, so modules added in a new release are installed too. If the download fails (usually because files in the checkout were edited by hand), it says so clearly, still upgrades the installed tools, and exits with an error.

## tb-seal *(Linux, run with sudo)*

Prepares a **clone** for templating. See [KASM.md](KASM.md).

## tb-linkcheck

Checks every URL in the bookmark collection. Codes 401/403/405/429 usually mean the site blocks scripts, so check those by hand.

```bash
tb-linkcheck                                  # installed bookmarks
tb-linkcheck ~/.config/truebearing/bookmarks.local.json
```
