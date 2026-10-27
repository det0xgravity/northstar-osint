# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/).

## [0.36.0] - 2026-10-27

### Added
- **62 more bookmarks** (95 in the base set, plus the country packs), chosen
  from tools that several of the large public OSINT lists agree on (jivoi's
  Awesome OSINT, Cipher387, Astrosp, the OSINT Framework, edoardottt) and
  that fill gaps: new folders for alternative search engines, wireless and
  telecom, crypto, the dark web, and verification method; more geolocation
  and imagery (Mapillary, KartaView, Esri Wayback, EO Browser, Bellingcat OSM
  Search), network and threat intelligence (VirusTotal, AbuseIPDB, IPinfo,
  BGP, GreyNoise, OTX, URLhaus), and video and image verification. Face
  search engines are deliberately left out.

### Fixed
- Capture web pages → Look up existing archived copies opened Memento
  TimeTravel, which closed in September 2025; it now searches Ghostarchive.

## [0.35.0] - 2026-10-27

### Added
- **Adult-site (NSFW) searches, per case:** Case → Adult-site (NSFW) searches
  allows them with a reason (a `DECISION:` note), refusing when anyone
  searched for could be under 18. Username searches then run Sherlock with
  `--nsfw`, a second Maigret pass over its porn, erotic and webcam sites, and
  Blackbird with its NSFW sites.

### Changed
- Without that permission, username searches now leave adult sites out of
  every tool: Blackbird runs with `--no-nsfw` and Maigret excludes its porn,
  erotic and webcam tags (both used to include some). Each result folder
  records the setting in `search-settings.txt`.

## [0.34.0] - 2026-10-27

### Added
- **Guides on the desktop:** the desktop module renders every guide in `docs/`
  as an offline web page (pandoc) in `~/.local/share/northstar/guides`,
  rebuilt on each update, and links **Northstar guides** and the
  investigation guide on the desktop (GNOME gets the Desktop Icons NG
  extension so they show). **Guides** in the main menu and `ns-guides` open
  them in the browser.

## [0.33.0] - 2026-10-27

### Added
- **docs/INVESTIGATION-GUIDE.md:** a whole investigation step by step, from a
  new VM to a report ready for submission, with a worked example, grading,
  verification traps, a pre-submission checklist and common mistakes, opening
  with a quick start checklist for people who want to dive straight in.
- **Worked examples** in the investigation guide: two fictional cases end to
  end, a dark-web vendor traced from a username and what they leak, and a
  photo geolocated and traced to its origin and the person in it.
- **Edit case details (intake)** in the Case menu: each change is written to
  the notes with its old and new value; intake recorded late is marked so.
- **Reopen this case:** a closed case can be reopened, with a reason in the notes.
- **Flags become Findings:** logging a flag in Missing person offers to create
  a lead Finding with the URL, explanation, date and evidence hash, so it can
  reach the Word report.

### Changed
- **Closing a case** first lists what isn't finished (records that don't
  verify, no report or one older than the findings, no review of the current
  findings and summary, incomplete intake, open leads). Closing anyway writes
  them to the notes. A closed case takes no more notes, reviews or reports.
- **Supervisor reviews** also fingerprint the summary, analysis and next steps
  in Case.md; the report warns when they change after the review.
- **Exhibits and findings:** a finding linked to a result that was recorded as
  an exhibit is checked against the exhibit register; New finding from the
  latest result fills in the exhibit ID; recording an exhibit updates its
  result note.
- The report warns when the intake record is missing or incomplete.

### Fixed
- docs/MENUS.md: the ns-case table described the old report location.

## [0.32.0] - 2026-10-27

### Changed
- **License:** GNU General Public License v3.0 or later (GPL-3.0-or-later),
  replacing the PolyForm Noncommercial license used in 0.31.0. Anyone who
  distributes northstar-osint, changed or not, must make the full source
  available under the same license.

## [0.31.0] - 2026-10-27

### Changed
- **License:** northstar-osint is now under the PolyForm Noncommercial License
  1.0.0. It's free for any noncommercial use (individuals, volunteers,
  researchers, charities, schools, government and public-safety agencies);
  selling it or using it commercially needs a separate license. Versions up to
  0.30.0 were released under the MIT License, and copies obtained under it keep
  those terms.

## [0.30.0] - 2026-10-27

Phase 4 of the case-hub review.

### Added
- `Chronology.md`: Event notes, findings, the missing-person timeline and
  timed map places in one timeline, with the kind of time and the source;
  reportable entries go into the report's new Chronology section.
- `Handover.md`: intake, integrity, findings and report status, the last
  review, open leads with owners, next steps, decisions (`DECISION:` notes)
  and the latest notes.
- Highlights at the top of each result note, chosen by tool.
- Ready-made searches on Home.md, and a northstar bookmarks group per case.
- Lead notes have assigned_to, outcome_finding and closed_utc; Event notes
  have time_kind and reportable.

### Changed
- Notes for deleted result folders are removed, or flagged folder_missing if
  the analyst wrote in them.

## [0.29.0] - 2026-10-27

Phase 3 of the case-hub review: selectors, accounts and the link chart.

### Added
- `Selectors.md`: identifiers from every result (usernames, emails, phones,
  domains, IP and onion addresses, Telegram IDs, coordinates, profile URLs),
  with how many tools saw each, first seen, source notes, and next searches
  (✓ when already run). Each result note lists the selectors seen in it.
- `Accounts.md`: account hits merged across tools; accounts reported by two
  or more tools get a generated, unverified Account note.
- `Link chart.canvas`: people, accounts and multi-tool selectors on an
  Obsidian Canvas, kept as a generated copy once you edit the chart.
- `ns_run` marks each tool's output in console.log, so hits are credited to
  the tool that reported them.

## [0.28.0] - 2026-10-27

Phase 2 of the case-hub review: findings and the report.

### Added
- Finding notes (`Findings/`): status (lead, corroborated, confirmed,
  discounted), reportable, source (A-F) and information (1-6) grades, results
  and exhibits relied on, observed fact separate from assessment. Notes → New
  finding from the latest result, and Discount a finding (never delete).
- The report is built from the vault: Case.md's summary and analysis, the
  reportable findings with their grading and evidence (each exhibit's
  fingerprint and files re-checked), searches with no result, unused material,
  the latest review, and warnings for anything that doesn't hold up.
- Each report version gets its own folder with a frozen copy of the findings it
  used and SHA-256 hashes; both are recorded in the hash-chained notes.
- Case → Record a supervisor review: name, role, decision and the findings
  fingerprint, in the hash-chained notes; reports flag changes since then.
- Result notes keep the analyst's notes and properties across rebuilds, show
  the exhibit number, flag searches that saved no output, and label raw tool
  hits as unverified.
- The dashboard shows findings and the integrity of the notes, audit log and
  exhibits.

### Changed
- `notes.md` is read-only between notes, so it can't be edited by accident.

## [0.27.2] - 2026-10-27

Phase 1 of the case-hub review (investigator, OSINT specialist, QC).

### Security
- A file name from the web could break out of an Obsidian link and inject HTML
  that loads a remote image (revealing your IP). Names that could do this are
  now shown as text, never linked; captured web pages are listed, not linked.
- Collected text is fully escaped (`& # $ % = ~` too), so it can't become maths,
  tags, hidden comments or entities; terminal colour codes are stripped.

### Fixed
- Case.md never loses the analyst's work: text above and below the generated
  block and added properties are kept; an older Case.md without the markers is
  kept whole (and backed up to `.northstar/`). Notes are written atomically, and
  a lock keeps two northstar runs from writing a case at once.
- A broken symlink or unreadable file no longer stops the notes for that case or
  for every other case; large CSV and text files are read as streams.
- Two results in the same minute no longer share one note (names have seconds).
- The results index reads each note's properties: country labels are right
  and undated results sort last. The Reports link opens the latest report; an
  empty lead status no longer hides the lead.
- A result's note goes into the result's own case even if the active case
  changed during a long run.

## [0.27.1] - 2026-10-27

### Security
- Result notes for breach searches could copy raw breach records, including
  passwords and hashes, out of the result folder's JSON. Breach notes now show
  only ns_breach's masked summary; every other note masks fields that look like
  credentials and never expands nested records. Case notes are written mode 600.

### Fixed
- holehe hits (`[+] site.com`, no URL) now appear under "Accounts found".

## [0.27.0] - 2026-10-27

### Added
- Obsidian case hub: every finished search writes a result note in the case's
  `Results/` folder (provenance, integrity, findings as tables, accounts
  found, key text, embedded images, console output, links to every raw file).
  `Case.md` is now a dashboard (details, counts, latest results, working notes,
  key records, page-monitoring changes) that keeps the analyst's own text
  below its generated part. `Home.md` lists every case with its activity.
- A northstar theme snippet, and a snippet that hides raw tool folders from
  Obsidian's file list (links and embeds still work).
- Notes → Refresh this case's notes. Updating writes notes for existing results.
- Redesigned templates (person, account, organisation, place, event, lead).

### Security
- Web content in result notes is escaped or fenced: it can't render as HTML or
  load remote images in Obsidian.

## [0.26.2] - 2026-10-27

### Fixed
- geo and translate failed on arm64 Linux: PyPI's PyTorch now pulls in NVIDIA
  CUDA libraries (over 1 GB, unusable in a VM), and the download kept breaking.
  Both now install PyTorch's CPU-only build on every Linux machine and pin it so
  GeoCLIP and Argos Translate can't swap in the CUDA build.

## [0.26.1] - 2026-10-27

### Fixed
- Notes did nothing when Obsidian wasn't installed (for example when an update
  stopped before the notes module). It now offers to install Obsidian, and
  otherwise opens the note in the default text editor.
- An `obsidian` command for the Flatpak version (it otherwise only runs as
  `flatpak run md.obsidian.Obsidian`).

## [0.26.0] - 2026-10-27

### Added
- Progress across the whole install: each module header shows `[n/total]`
  and an overall bar, each module reports how long it took, and every long
  step (apt, Flatpak, pipx, pip, go install, git, large downloads, uv) shows a
  live status line with a spinner, elapsed time, and a progress bar for
  downloads (pip and curl) or the step's latest output. Status lines go to the
  terminal only; `install.log` keeps the full output.

### Fixed
- `darkweb` no longer fails where there's no systemd (containers); it says how
  to start Tor by hand.

## [0.25.0] - 2026-10-27

### Added
- Telegram: look up any channel, group, bot or user and search a public
  channel's posts without a login; with a research account (Telethon), search
  Telegram for public chats and users, search messages, list a group's visible
  members and read user profiles. Telegram API ID and hash under API keys.
- `messaging` module: Telegram Desktop (Flathub, verified), Signal (official
  apt repository, x86_64) and Element (official apt repository).
- `notes` module and `ns-notes` (main menu: Notes (Obsidian)): Obsidian with
  `~/Northstar/Cases` as one vault, templates for people, accounts,
  organisations, places, events and leads, a `Case.md` overview per case, and
  `Results.md`, which every finished search now adds a line to.
- `tests/e2e.sh` and the End-to-end workflow: a full install in clean Debian 13
  and Ubuntu 24.04 containers (x86_64 and arm64), then the installed menus and
  engines run with real tools: case and notes, missing persons, same-photo
  finder, EXIF GPS on the case map, OCR, face comparison, page monitoring,
  Telegram previews, translation, and evidence verification.

### Changed
- `ns-seal` also removes Telegram Desktop, Signal and Element logins and the
  Telegram search session.

## [0.24.0] - 2026-10-26

### Added
- "Missing persons" searches and bookmark folders in the US (NamUs, NCMEC,
  Charley Project, Doe Network, FBI), UK (Missing People, UK Missing Persons
  Unit), Ireland (Garda), Australia (NMPCC), New Zealand (NZ Police), Canada
  (Canada's Missing) and International (INTERPOL Yellow Notices and Identify
  Me, ICMP, Missing Children Europe, AMBER Alert Europe) packs.
- Missing person → "Missing-persons databases" picks a country and opens its
  missing-persons search with the subject's name pre-filled.
- `ns-country [CODE [SEARCH [QUERY]]]` can preselect a search and pre-fill it.

## [0.23.0] - 2026-10-26

### Added
- `ns-translate` (main menu: Translate (offline)) and the `translate` module:
  Argos Translate in a private venv. Translate a passage or text files
  (posts, transcripts, subtitles) on this computer; language models download
  once per pair. Results saved with the source text and sealed.

## [0.22.0] - 2026-10-26

### Added
- `ns-map` (main menu: Case map): recorded places (last seen, sightings, home,
  work…, by address or coordinates), photo EXIF GPS and GeoCLIP estimates on
  one map. Exports `case.geojson`, `case.kml` and `points.csv`, plus an
  interactive `map.html` (Leaflet, pinned with SRI; asks before loading tiles).

## [0.21.0] - 2026-10-26

### Added
- `ns-watch` (main menu: Page monitoring): watch public pages for changes as
  proof of life or new activity. Text snapshots and diffs per change in the
  case's `watch/` folder, `changes.log`, audit-log entries, and optional
  scheduled checks (systemd user timer or launchd agent) with notifications.

## [0.20.0] - 2026-10-26

### Added
- Image analysis: "Find the same photo across this case": perceptual hashing
  (pHash + dHash with imagehash, local) groups every repeated picture, or
  finds every copy of one photo, through resizing, recompression, format
  changes and light edits. Review sheet and CSV; sealed.

## [0.19.0] - 2026-10-26

### Added
- Username & email: "Generate username and email variants from a name"
  (accents removed, compound surnames handled, birth year suffixes), pre-filled
  from the missing-person profile, with optional batch checks of the top 10
  usernames (Sherlock) and emails (holehe).

## [0.18.0] - 2026-10-26

### Added
- `ns-missing` (main menu: Missing person): subject profile and photos (with
  hashes); timeline from your events, the last-seen moment, dated findings,
  downloaded media metadata and photo EXIF times, placed relative to last seen
  (`timeline.csv`, `timeline.html`); findings (CTF flag) log with categories
  from `config/ctf-categories.txt`, evidence copied with SHA-256, duplicate-URL
  warnings and a grouped export. `docs/MISSING-PERSONS.md`.
- 6 more tests (41 in total).

## [0.17.0] - 2026-10-26

### Added
- `ns-face` (main menu: Face comparison (within this case)): compare a
  reference face with faces in photos already collected in the active case,
  locally (OpenCV YuNet + SFace). Requires a recorded purpose and lawful basis
  per case, refuses folders outside the case, reports similarity bands (never
  "matches"), flags low-quality faces, and writes a review sheet
  (`results.html`), `results.csv` and face crops; every run is logged and
  sealed.
- `face` module: OpenCV in a private venv and the two models, verified
  against the SHA-256 the opencv_zoo repository publishes.
- 5 more tests (35 in total).

## [0.16.0] - 2026-10-26

### Added
- `ns-geo` (main menu: Photo geolocation): EXIF GPS and time, OCR of visible
  text, a GeoCLIP location estimate run locally (top 10 candidates), optional
  place names (coordinates only, OpenStreetMap), and maps, Mapillary, OSM
  Search and Google Lens for verification. Shadow analysis with ShadowFinder,
  and skyline matching. Photos never leave the computer.
- `geo` module: GeoCLIP in a private venv (CPU PyTorch on x86_64), and
  ShadowFinder.
- 5 more tests (30 in total).

## [0.15.0] - 2026-10-26

Phase 4d of the review: health check and automated tests.

### Added
- `ns-doctor` (main menu: Health check): every tool with its version,
  missing tools, key and case permissions, listening ports, Firefox policies,
  disk space and recent install warnings, saved as a support report.
- `NS_UI=script`: scripted dialogs, so menus run unattended in tests.
- `tests/run.sh`: 25 offline functional tests (country packs, menu results
  and sealing, evidence and audit chain tamper detection, case notes, secrets
  never reaching case data, input validation, installer module selection).
  CI runs them on Ubuntu and on macOS's Bash 3.2.
- `install.yml`: weekly real installs in Debian 13 and Ubuntu 24.04 containers
  on x86_64 and arm64 runners, run twice to check re-runs are safe.

## [0.14.0] - 2026-10-26

Phase 4c of the review: case intake, notes and reports.

### Added
- `ns-case` (main menu: Case): intake record for new cases (reference,
  authority, purpose and lawful basis, scope, review date) in `case.json` and
  `scope.md`; hash-chained contemporaneous notes (`notes.md`); a Word report
  built with pandoc (case details, methodology from the audit log, exhibits
  with fingerprints, notes, audit appendix); verification of notes and the
  audit log; closing a case (verify, export with SHA-256, mark closed).
- pandoc in the `core` module.

## [0.13.0] - 2026-10-26

Phase 4b of the review: Telegram.

### Added
- `ns-telegram` (main menu: Telegram): collect public channels (posts,
  metadata, forward sources, dataset and forward network) with
  telegram-tracker, one or a list; channel search via TGStat and web search;
  one-time login with credentials kept out of the audit log.
- `social` module: telegram-tracker, installed through uv with its own
  Python 3.14 (it needs a newer Python than Debian 13 ships).
- "Social Platforms" bookmark folder: TGStat, Telemetr, Arctic Shift (Reddit),
  Bluesky search, ClearSky, Social Blade.
- `ns-seal` removes the Telegram session.

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
