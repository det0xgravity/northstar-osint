# Breach data and the dark web

Two menus cover exposure research: `ns-breach` for breach and infostealer data, and `ns-darkweb` for Tor-based work. Both save everything to the active case and log every search in `audit.log`.

## Ground rules

- **Lawful basis first.** Only research people and organisations you're authorised to investigate. Breach data is personal data. Privacy law (GDPR, PIPEDA and others) applies to how you collect, keep and share it.
- **Lookups, not dumps.** northstar queries breach-notification and threat-intelligence services about one selector at a time. It never downloads, stores or trades breach dumps: in many countries, simply holding stolen personal data is an offence.
- **Text only on the dark web.** Onion pages are fetched as one text/HTML document through Tor, with no images, scripts or other files. Anything that isn't a text page is discarded unread. Never download files from onion sites.
- **Abuse material.** If you encounter child sexual abuse material, stop. Don't save, screenshot or share it, and report it to the police or your national hotline (for example Cybertip.ca in Canada, NCMEC in the US, the IWF in the UK). Ahmia removes such sites from its index.
- **Stay in the VM.** Do this work inside the investigation VM, and never sign in to personal accounts over Tor.

## ns-breach

| Search | Free sources (always run) | Paid sources (with your API key) |
|---|---|---|
| Email address | XposedOrNot (breaches), Hudson Rock (infostealer infections), LeakCheck public | Have I Been Pwned, LeakCheck Pro, DeHashed |
| Username | Hudson Rock, LeakCheck public | LeakCheck Pro, DeHashed |
| Domain | Hudson Rock (infected employees and users, best effort), HIBP breaches of that domain's own service | LeakCheck Pro (Enterprise plans), DeHashed, Intelligence X |
| Phone number | (none) | LeakCheck Pro, DeHashed, Intelligence X |
| Password exposure | HIBP Pwned Passwords | — |
| Breach details | HIBP breach catalogue | — |

Each source reports *found*, *not found*, *skipped* (no key) or an error, so a failing service never hides the others' results. Results go to `~/Northstar/Cases/<case>/breach/<target>_<time>/`:

- `summary.txt`: what was found, with **passwords masked**
- one `<source>.json` per source that found something, holding the service's full response. These files can contain passwords or hashes, so they're readable only by you (mode 600). Treat the case folder as sensitive.

**Infostealer results (Hudson Rock)** mean a computer that used this email or username was infected with password-stealing malware. That's often more current and more serious than an old breach.

**Password exposure check:** the password is typed into a hidden field and hashed on your computer. Only the first 5 characters of its SHA-1 hash are sent to HIBP (*k-anonymity*). Nothing is written to disk, and the audit log only records that a check was made.

### API keys (`ns-keys`)

Paid sources need a key from the service. Add them with **API keys** in the main menu (or `ns-keys`): keys are typed into a hidden field and stored in `~/.config/northstar/keys.env`, readable only by you. They're never shown in full, put on a command line, or written to the audit log or a case folder.

| Service | What it adds | Get a key |
|---|---|---|
| Have I Been Pwned | Every breach an email appears in (names, dates, data types; no passwords) | [haveibeenpwned.com/API/Key](https://haveibeenpwned.com/API/Key) |
| Intelligence X | Leaks, pastes and dark-web archives mentioning an email, domain or phone | [intelx.io](https://intelx.io/account?tab=developer) (free and paid keys both work) |
| DeHashed | Full breach records by email, username, domain or phone | [dehashed.com](https://app.dehashed.com/) |
| LeakCheck | Breach records and infostealer logs by email, username or phone | [leakcheck.io](https://leakcheck.io/) |

## ns-darkweb

| Option | What it does |
|---|---|
| Check Tor connection | Confirms the local Tor proxy works and shows the exit IP websites see. Offers to start Tor if it isn't running |
| Search onion services (Ahmia) | Opens [Ahmia](https://ahmia.fi/), a search engine for onion sites, with your query on the clipboard. Ahmia protects its search with an anti-bot token, so northstar doesn't automate it |
| Fetch an onion page as text | Fetches one page through Tor and saves `page.txt` (readable text), `page.html.txt` (the document as received, kept as text so it can't be opened in a browser by accident, where it would load trackers from your real IP), `links.txt`, `onion_addresses.txt`, `headers.txt` and `metadata.json` (URL, UTC time, status, size and a SHA-256 hash for your records) |
| Ransomware leak-site check | Searches [ransomware.live](https://www.ransomware.live/) for leak-site claims naming an organisation: date, group, victim, country. These are claims by criminal groups and are often unverified. The service allows one search per minute |
| Open Tor Browser | For visual browsing of onion sites |
| OnionShare: receive files from a source into this case | Opens a private [OnionShare](https://onionshare.org) drop box: a temporary .onion address and private key, shown in the terminal only. Your source opens it in Tor Browser and uploads files or text. Press Ctrl+C to close it; what arrived is listed with SHA-256 hashes in `received.txt` and the folder is sealed. Received files are **untrusted**: don't run programs or enable macros |
| OnionShare: send files over a private .onion link | Shares files you choose, for example a case export from `~/Northstar/Exports`, until the first complete download. Give the recipient the address and private key by two different channels. The audit log records each file's name and SHA-256, never the address or key |
| Open the OnionShare app | The desktop app, also for chat and hosting a static page (Linux: Flathub, verified by the OnionShare project; macOS: Homebrew) |

The `darkweb` module installs the Tor **client** (never a relay) as a service with a SOCKS proxy on `127.0.0.1:9050`, plus `torsocks` and OnionShare (the app, and its command-line version from PyPI, which the menu drives on Linux with the system Tor). OnionShare's links are private by default: without the private key, the address shows nothing. `ns-seal` removes OnionShare's saved addresses and keys from template clones. On Linux the service starts at boot: turn it off with `sudo systemctl disable --now tor`. On macOS, `ns-darkweb` starts Tor when you need it.

### Tor Browser on arm64 (VMs on Apple Silicon)

Flathub only builds Tor Browser for x86_64, so on arm64 Linux northstar installs it straight from the Tor Project into `~/.local/share/northstar/tor-browser` and checks the download's signature against the Tor Browser Developers key (`EF6E 286D DA85 EA2A 4BA7 DE68 4E2C 6E87 9329 8290`). If the signature doesn't verify, nothing is installed.

The Tor Project's stable channel doesn't have an arm64 Linux build yet, so for now this installs the **alpha** (16.0a series), and the installer says so. Alphas are test builds, and the Tor Project advises people at high risk to use stable. Once a stable arm64 build exists, the next `ns-update` replaces the alpha with it. In between, Tor Browser updates itself.

Mullvad Browser has no arm64 Linux build at all yet, so it's skipped there.
