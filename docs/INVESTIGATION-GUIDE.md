# Investigation guide: from zero to a case ready for submission

This guide takes you through a whole investigation on the True Bearing VM, step by step: preparing the VM, opening a case, collecting, sealing evidence, analysing in Obsidian, writing findings, review, and the report you hand over. It uses one fictional worked example throughout, a missing adult called **Jane Doe**, but the same steps work for due diligence, fraud or threat cases.

Two more worked examples follow the main guide: [a dark-web vendor traced from their username](#13-worked-example-a-a-dark-web-vendor-from-a-username-to-a-name) and [a photo traced to where it was taken and who is in it](#14-worked-example-b-one-photo-to-where-it-was-taken-and-who-is-in-it).

It draws on reviews by an experienced case manager (evidence, supervision, handover) and a senior OSINT specialist (collection, verification, OPSEC).

**Where to find this guide:** on the VM's desktop (**True Bearing investigation guide**, and the **True Bearing guides** folder for the other manuals), under **Guides** in the True Bearing main menu, or on GitHub. The copies on the VM work offline and are refreshed by every update.

You don't need to know the command line. Everything here is in the **True Bearing** menu (the compass icon in the dock, or type `truebearing` in a terminal). Menu names in **bold** are exactly what you'll see.

> **📷 Screenshots.** Places marked 📷 show what you should see at that step. To capture your own, press **Print Screen** in the VM (Flameshot), or **Cmd+Shift+S** on a Mac keyboard.

## Quick start checklist

For diving straight in. Each step links to the full explanation for when you need it. Menu names are in the **True Bearing** main menu.

**Before you start**
- [ ] VM snapshot taken; VPN or research connection on if your work needs it ([1](#1-before-your-first-case))
- [ ] **Update True Bearing** ends with *All modules completed.*; **Health check** shows nothing missing
- [ ] Research accounts only, never personal ones. API keys (optional) under **API keys**

**Open the case**
- [ ] **Switch / create case**: a new name, answer **Yes**, fill in reference, who authorised it, lawful basis, scope, review date ([2](#2-open-the-case))
- [ ] Case → **Add a note**: what you were asked to do, and your plan ([3.1](#31-write-your-first-contemporaneous-note))
- [ ] Missing person? **Missing person** → **Subject profile** ([3.2](#32-the-subject-profile-missing-person-cases))

**Collect**
- [ ] Run the menus that fit your identifiers: **Username & email**, **Telegram**, **Domain & infrastructure**, **Photo geolocation**, **Country search**… ([4](#4-collect))
- [ ] Found something you'll rely on? **Capture web pages** now, and answer **Yes** to recording it as an exhibit ([4.3](#43-capture-what-matters-as-you-find-it), [5](#5-seal-and-record-evidence))
- [ ] **Don't:** contact anyone, follow, like, join groups, or upload victims' photos to websites
- [ ] Note each decision in Case → **Add a note**, starting with `DECISION:`

**Make sense of it** (main menu → **Notes (Obsidian)** → **Open this case's notes**)
- [ ] Check tool hits by hand: a username hit isn't an account until you've opened and checked it ([4.2](#42-usernames-and-emails))
- [ ] For each conclusion: Notes → **New finding from the latest result**; write *Observed* and *Assessment*, grade it (A–F, 1–6) ([7](#7-write-findings))
- [ ] Two independent sources → `status: corroborated`, `reportable: true`. Wrong? **Discount a finding**, never delete ([7.3](#73-corroborate))
- [ ] Searches that found nothing: `nil_return: true` on the result note ([4.13](#413-log-nil-results))
- [ ] Write the **Summary** and **Analysis** below the line in Case.md

**Finish**
- [ ] Case → **Record a supervisor review** ([8](#8-review))
- [ ] Case → **Build a report (Word document)**; fix the warnings; read the whole report ([9](#9-build-the-report))
- [ ] Case → **Verify notes and audit log**; **Evidence & exhibits** → **Export the case** ([10](#10-submit-hand-over-and-close))
- [ ] Send the report and its hashes through your approved channel, then Case → **Close this case**

Before you submit, go through the full [pre-submission checklist](#11-pre-submission-checklist).

## Contents

1. [Before your first case](#1-before-your-first-case)
2. [Open the case](#2-open-the-case)
3. [Plan before you search](#3-plan-before-you-search)
4. [Collect](#4-collect)
5. [Seal and record evidence](#5-seal-and-record-evidence)
6. [Analyse in Obsidian](#6-analyse-in-obsidian)
7. [Write findings](#7-write-findings)
8. [Review](#8-review)
9. [Build the report](#9-build-the-report)
10. [Submit, hand over and close](#10-submit-hand-over-and-close)
11. [Pre-submission checklist](#11-pre-submission-checklist)
12. [Common mistakes](#12-common-mistakes)
13. [Worked example A: a dark-web vendor, from a username to a name](#13-worked-example-a-a-dark-web-vendor-from-a-username-to-a-name)
14. [Worked example B: one photo, to where it was taken and who is in it](#14-worked-example-b-one-photo-to-where-it-was-taken-and-who-is-in-it)
15. [What the worked examples have in common](#15-what-the-worked-examples-have-in-common)

## How it fits together

| Where | What it holds | Can it be edited? |
|---|---|---|
| **Result folders** (`~/TrueBearing/Cases/<case>/<kind>/<target>_<time>/`) | Everything a tool collected, sealed with SHA-256 hashes when the search finishes | No: any change shows when it's verified |
| **`audit.log`** | Every search you ran, with the UTC time, the tool and the operator, hash-chained | No: edits break the chain |
| **`notes.md`** (Case → **Add a note**) | Your contemporaneous notes, hash-chained | No: you can only add to it |
| **Obsidian notes** (Case.md, Findings, People, Accounts…) | Your working analysis and conclusions | Yes: this is your workspace |
| **`reports/v<n>_<time>/`** | Each report version, its frozen findings and their hashes | No: a new version gets a new folder |

The rule of thumb: **tools collect, the seal proves, notes record what you did and why, Findings say what you concluded, the report draws from the Findings.**

---

## 1. Before your first case

Do this once when the VM is new, and the update and health check before every case.

### 1.1 Take a clean snapshot

In UTM, with the VM shut down, take a snapshot called *clean baseline*. Go back to it between unrelated cases so nothing (browser history, logins, cookies) carries over. Case data lives in `~/TrueBearing`: export it before you revert (step 10).

### 1.2 Update and check health

1. Main menu → **Update True Bearing**. A good update ends with **All modules completed.**; otherwise it lists the modules that failed (see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)).
2. Main menu → **Health check**. Read the summary at the end: anything missing, and the keys file or True Bearing folders readable by other accounts. Note which of ports 3389 (xrdp), 4000 (amass) and 9050 (Tor) are listening, and whether you expected them to be. The report is saved in `~/TrueBearing/support/`.

📷 *The Health check report, with the Tools section and no problems listed.*

### 1.3 Your connection

Every search leaves from the VM's internet connection. If your organisation requires a VPN or a dedicated research line, connect it **before** you open the browser or run any menu. Check your public IP in the browser before you start.

**LAN isolation.** In a VM, True Bearing blocks connections from the VM to your own network (router, NAS, printers, other machines), so nothing you open during an investigation can reach them. Check it's on with main menu → **LAN isolation (firewall)** → **Status**. If your cases are saved to a NAS, allow it there.

### 1.4 Research accounts and API keys

- **Research accounts** ("sock puppets") only, never your personal accounts: for Telegram, Instagram and anything else that needs a login. Create them under your organisation's policy.
- **API keys** (optional, adds paid breach sources): main menu → **API keys**. Keys are typed into a hidden field, stored readable only by you, and never logged.
- **Telegram searches** need a one-time login: main menu → **Telegram** → **Log in for searches**, after adding the API ID and hash from [my.telegram.org/apps](https://my.telegram.org/apps) under **API keys**.
- **Logins the menus don't walk you through** (only if you'll use them): the Google account search needs `ghunt login` once in a terminal; Instagram downloads work better after `instaloader --login <research account>`; **Instagram profile details** asks for a session ID, which is never logged.
- **Messaging apps** (Telegram Desktop, Signal, Element) are installed for research accounts only.

### 1.5 Open the vault in Obsidian

Main menu → **Notes (Obsidian)** → **Open the Cases vault (all cases)**. If Obsidian asks whether to trust the vault, either answer works: True Bearing uses no community plugins, so you can keep restricted mode on. You'll see `Home.md`, the list of every case.

📷 *Obsidian showing Home.md with the case list.*

---

## 2. Open the case

Main menu → **Switch / create case**. Type a short case name (letters, numbers, dashes), for example `2026-031-jane-doe`, then answer **Yes** to record the intake details:

| Prompt | Example | Why it matters |
|---|---|---|
| Client or matter reference | `MP-2026-031` | Ties every exhibit and report to the right matter |
| Authorised by (name, role) | `Det. Sgt A. Example, Missing Persons Unit` | Who approved the work. Get it before you search |
| Purpose and lawful basis | `Locate a missing adult at risk; tasking under [policy/power], request dated 2026-10-27` | Your justification for processing personal data. Be specific |
| Scope and subjects | `Jane Doe (b. 1990) only. Out of scope: family members' accounts beyond confirming contact; no covert interaction` | Stops scope creep, and tells a reviewer what you weren't asked to do |
| Review or retention date | `2027-04-27` | When the case data must be reviewed or deleted |

The case becomes **active**: every menu now saves into it. The current case is shown in the main menu (**Switch / create case (current: …)**).

📷 *The "Case … opened" message with the intake record.*

**Never reuse a case for a different matter.** Each matter gets its own case, so its audit log and exhibits stand on their own.

**If the details change** (the scope widens, the review date moves, you skipped the intake): Case → **Edit case details (intake)**. Each change is recorded in the notes with the old and new value, and intake recorded after the case was opened is marked as late. The report warns if the intake record is missing or incomplete.

---

## 3. Plan before you search

### 3.1 Write your first contemporaneous note

Case menu (main menu → **Case: notes, details, report, close**) → **Add a note**:

> `Tasking received 09:10 UTC from Det. Sgt Example. Objective: find current online activity and possible location of Jane Doe, last seen 2026-10-25. Starting with the selectors supplied: username janedoe90, email jane.doe90@example.com.`

Each note is saved with the UTC time and your account name, and chained to the one before, so later edits show. Write one:
- when you start and stop a session;
- whenever you make a **decision** (start it with `DECISION:`, these are collected in Handover.md): `DECISION: not searching the sister's accounts, out of scope per intake.`
- when something unexpected happens (a site was down, a result looked wrong, you changed approach);
- when you record a nil result that matters.

More examples:

> `DECISION: captured instagram.com/janedoe90 now; a post at 2026-10-26 18:02 UTC may be proof of life and could be deleted.`
> `Sherlock hit on "janedoe_art" unverified: profile photo differs. Kept as a lead.`
> `Collateral: group photo shows 3 unrelated adults. Not processed further.`
> `Correction to the 14:05 UTC note: the account is janedoe90, not janedoe09.`

**Don't write:** passwords, API keys, cookies or session IDs; speculation stated as fact; opinions about the subject's character. Notes are disclosable, so write each one as if the subject's lawyer will read it. The notes can't be edited: correct a mistake with a new note, and if an entry is written late, say so.

Keep facts and actions in the notes. Your interpretation belongs in Findings (step 7).

> **Two buttons, one record.** Case → **Add a note** and Notes → **Add a contemporaneous note (tamper-evident)** write to the same `notes.md`.

### 3.2 The subject profile (missing-person cases)

Main menu → **Missing person** → **Subject profile (create or update)**. Fill in what you were given: full name, aliases, date of birth, **last seen (UTC, `YYYY-MM-DD HH:MM`)** and where, description, known usernames, emails, phones and vehicles. Then **Add subject photos** for the official photos (each is copied with its SHA-256).

The profile pre-fills other menus: the missing-persons database search, the username variants and the "last seen" place on the case map.

### 3.3 The case dashboard

Main menu → **Notes (Obsidian)** → **Open this case's notes**. This is `Case.md`, the dashboard. The top part is generated by True Bearing and refreshed after every search. **Write below the end marker:**

- **Summary**: what you know so far, in a few lines.
- **Analysis**: hypotheses and what would settle them.
- **Next steps**: a checklist. Unticked items show up in Handover.md.

**Everything you write below the end marker, Next steps included, goes into the report.** Write it for the reader of the report.

For each line of enquiry you want to track, add a **Lead** (Notes → **New note: lead**) and fill in **assigned_to** and **priority**.

📷 *Case.md: case details, counts, findings table, latest results, and the Summary / Analysis / Next steps you wrote below.*

---

## 4. Collect

Work outwards from what you were given: **identifiers → accounts → content → places and times**. After every search:

- the result folder is sealed and logged automatically;
- a **result note** appears in Obsidian under `Results/`, with **Highlights** at the top;
- the selectors it found are added to `Selectors.md`.

Below is the order used for the Jane Doe example. Skip what doesn't apply to your case, and **stay within the scope** you recorded: don't collect friends', family's or group members' data beyond what the case needs.

> **What leaves the VM.** Image files never leave it through True Bearing's own tools. But **Reverse search an image URL** sends the URL to Google, Yandex, Bing and TinEye, and anything you **drag into** a reverse-search page that a menu opens (from **Analyze a local image**, **Video verification** or **Photo geolocation**) is uploaded to that service. Never do that with photos of victims or minors. Use the local tools (same-photo finder, face comparison, GeoCLIP) instead.
>
> Other things that go out: **Reverse search an image URL** may download a copy of the image over your connection (it asks first unless Tor is running); case-map address lookups and GeoCLIP place names send text or coordinates to OpenStreetMap; opening `map.html` loads map tiles. Every web search and page capture goes out over your connection.

### 4.1 Missing-persons databases

**Missing person** → **Missing-persons databases and resources** → pick the country (or International). The subject's name is pre-filled; accept it. The official databases open in the browser. Note in Case → **Add a note** which ones you checked and what they showed.

### 4.2 Usernames and emails

**Username & email**:

1. **Username search** with `janedoe90`. Sherlock, Maigret, socialscan and Blackbird check hundreds of sites. Expect **false positives**: a "hit" only means a profile with that name exists.
2. **Email search** with the email: which services it's registered with (holehe).
3. **Generate username and email variants**: likely variants from the name and birth year, optionally checked. These are guesses: hits on them are especially likely to be someone else.
4. **Analyse email headers (offline)**, when the case starts from an email (a threat, a scam, a phishing message): save it with full headers ("Show original" / "Download original"), then see where it really came from and whether it's forged. The first public IP is often the sender's mail provider, not the sender.
5. **Google account** (with an email; needs `ghunt login`): the name, photo and sometimes public Maps reviews, which can be a location lead.

**Adult sites** (pornography, webcam, erotic) are left out unless you allow them for the case: Case → **Adult-site (NSFW) searches**, with your reason. They can be strong leads when a case needs them (a reused username, photos, a location), but opening hits shows explicit material: open them only in the VM, download nothing, and if anything may show a child, stop and report it. They can't be allowed if anyone you're searching for could be under 18.

What the results mean: a username "hit" only shows a profile with that name exists, and common handles collide. Sites that block scripts show "no result", which isn't proof of absence. Some sites answer "found" for any name. holehe shows an email is **registered** with a service, not that the subject is using it.

In Obsidian, open `Accounts.md`: an account reported by **two or more tools** gets an Account note, still labelled **unverified**. Open each likely profile in the browser and check it's the subject (photos, bio, location, friends, writing style, links to known identifiers). Record what you checked in the Account note's **Attribution** section, and set **`verified: true`** and **`owner`** only once you're sure.

📷 *A username result note: Highlights with tool hits, then the tables.*

### 4.3 Capture what matters, as you find it

Profiles change and posts get deleted. When you find something relevant, capture it **before** you analyse it:

- **Capture web pages** → capture one page (or a list): an offline copy, full-page screenshot, headers, capture time and server IP, sealed. When it asks to **record it as an exhibit now**, answer **Yes** (step 5). archive.today opens so you can add an independent public copy.
- **Media download** for videos, galleries and Instagram profiles (with your research account), or **Save a page to the Internet Archive (Wayback)**.

### 4.4 Telegram

**Telegram**:

- **Look up a channel, group, bot or user** and **Search a public channel's posts**: no login, only the public web pages.
- **Search Telegram for public chats and users**, **Search messages in a channel or group**, **Members of a group**, **User profile**: these use your logged-in research account. Read-only: never join a group or message anyone, that would be seen.
- Record the **numeric Telegram ID**: usernames change, the ID doesn't.

### 4.5 Photos: metadata, same photo, place

> Worked through in full in [example B](#14-worked-example-b-one-photo-to-where-it-was-taken-and-who-is-in-it).

1. **Metadata** → **View metadata** on photos you collected: camera, times and GPS if present. Most social platforms strip metadata, so it's usually only in original files.
2. **Image analysis** → **Find the same photo across this case**: the same picture on two accounts often shows they're connected.
3. **Image analysis** → **Reverse search an image URL** (Google Lens, Yandex, Bing, TinEye), or **Analyze a local image**, which opens Google Lens, Yandex, TinEye and FotoForensics for you to drag it into (and Google Maps if it has GPS). Never upload photos of victims or minors to online services.
4. **Photo geolocation** → **Where was this photo taken?**: EXIF, the text visible in the photo (OCR) and, optionally, GeoCLIP's estimate, all on your computer. GeoCLIP gives **leads, not answers**: confirm them with street-level imagery, signs, landmarks or **Shadow analysis**.
5. **Image analysis** → **Face search engines (online; read the warning)**: PimEyes, FaceCheck.ID, Search4faces and Lenso.ai search the web for a face. The photo leaves the VM, a face is biometric data, and results are look-alikes, never identifications. True Bearing warns you first, won't open them for a child or a victim, and records your reason and lawful basis in the notes. Use them only when the case needs it and your basis covers it. The **Face search engines** bookmark opens the same warning as a page, but records nothing.
6. **Face comparison (within this case)**: compares a reference face (the official photo) with faces in photos already in the case. It asks for the lawful basis the first time. A score is similarity, never identification: treat it as a reason to look closer.

**Material from a source.** If someone (a witness, a family member, a whistle-blower) needs to send you files and has no safe way to do it, **Dark web** → **OnionShare: receive files from a source into this case** gives them a private .onion drop box. Send them the address and the private key, and ask them to use Tor Browser. What arrives is hashed, checked for warning signs (a program disguised as a document, macros, PDF scripts, known malware), sealed and listed in the case; record it as an exhibit, and treat every file as hostile (no programs, no macros). For files that reach you any other way, use **Evidence & exhibits** → **Check received or suspicious files (triage)** before you open them.

### 4.6 Video

**Video verification** with a URL or file: frames at every scene change for reverse searching, technical metadata, and an offline transcript and translation of the speech.

### 4.7 Places and the case map

**Case map** → **Add a place** for the last-seen location, sightings, home and work (by address or `lat, lon`). Then **Build the case map**: photo GPS and GeoCLIP estimates are added automatically, and you get `map.html` plus KML and GeoJSON for Google Earth or QGIS. **Open the latest case map in QGIS** opens it there, offline, for measuring distances, adding layers and making a map for the report.

📷 *map.html with the last-seen place, a photo GPS point and AI estimates.*

### 4.8 Country records

**Country search** → the country → the kind of search (people, business, phone, vehicle, court…). The links and your query are saved to the case; the search pages open in the browser.

### 4.9 Breach data (only if your basis covers it)

> Breach data and the dark web used together, from a username to a name: [example A](#13-worked-example-a-a-dark-web-vendor-from-a-username-to-a-name).

**Breach data** with the email or username: which breaches and infostealer infections it appears in. Only lookups: nothing is downloaded. The result note shows the summary only; passwords never reach your notes.

**Careful:** paid services can return passwords. They're masked in `summary.txt` and never reach your notes, but the services' raw responses (`<source>.json`, readable only by you) stay in the result folder, and so in the case export. Handle the export accordingly.

Use it for pivots (old usernames, phone numbers, other services), not as proof. Breach data tells you an identifier existed and was used, not who is using it now. An infostealer hit means one of the subject's devices was once infected; it says nothing about where they are. If breach data isn't needed for your purpose, don't search it, and write a `DECISION:` note saying why.

### 4.10 Page monitoring (proof of life)

**Page monitoring (proof of life)** → **Watch a page** for the subject's public profiles or `t.me/s/<channel>`, then **Scheduled checks** (every 3–24 hours). Scheduled checks cover every open case. A change brings a desktop notification, goes into the audit log and **Recent changes**, and appears in Case.md's **Page monitoring: latest changes** the next time the dashboard is refreshed.

It can't watch pages that need a login or are built entirely by JavaScript, which rules out most Instagram and Facebook profiles: check those by hand on a schedule and note it. A change isn't proof of life on its own: it can be a scheduled post, a relative or admin, or a repost. **Capture** the change and check who posted it. Keep the number of pages and the frequency modest.

### 4.11 Translation

**Translate (offline)** for posts, captions and transcripts. Nothing leaves the VM. Machine translation is a lead: have anything that matters checked by a qualified translator.

### 4.12 Search-party events: flags

At a Trace Labs-style event, log each submission as you find it with **Missing person** → **Log a finding (flag)** (category, URL, why it matters, optional screenshot), then **Export findings** for the event platform. These flags are the event's log; the Word report is built from Obsidian **Findings** (step 7). When you log a flag, True Bearing offers to **make it a Finding too**: it starts as a lead with the URL, explanation, date and evidence hash filled in, so you can capture the page, grade it and corroborate it before it goes into a report.

### 4.13 Log nil results

A search that finds nothing is still a result. On that result note in Obsidian, set the property **`nil_return: true`** and say what you searched in **Analyst notes**. The report lists nil returns, so the reader knows the ground you covered.

---

## 5. Seal and record evidence

Every result folder is already sealed. **Record the ones you'll rely on as exhibits:** main menu → **Evidence & exhibits** → **Record a result folder as an exhibit**, choose the folder and describe it (`Capture of Instagram profile janedoe90, 2026-10-27`). It gets a number such as `2026-031-JANE-DOE-EX-001`, and its fingerprint goes in `exhibits.csv`. If it's offered, you can add an OpenTimestamps proof.

- Record captures as exhibits **as soon as you take them**, not at the end.
- A Finding made with **New finding from the latest result** gets the result's exhibit ID filled in. A finding that links a result under `results` is checked against that result's exhibit too, so you only type exhibit IDs for evidence you didn't link.
- Work on copies. Don't open and save files inside result folders: any change shows as a broken seal.
- **Verify a folder (has anything changed?)** before you rely on an older one.

📷 *The exhibit list (List exhibits).*

---

## 6. Analyse in Obsidian

Everything you've collected is now in the vault. Key pages, from the case's dashboard (`Case.md`) or the **True Bearing** bookmarks group:

| Page | Use it to |
|---|---|
| **Results/** | Read each tool's output as tables. Write what you checked in **Analyst notes** at the bottom, and set `relevance`, `reviewed` or `nil_return` in the properties. Your text is kept when the note is rebuilt |
| **Selectors.md** | Every identifier found, how many tools saw it and when, and the searches that would take it further (✓ = already run). This is your pivot list |
| **Accounts.md** | Account hits merged across tools. Two tools agreeing is still **unverified** |
| **Link chart.canvas** | People, accounts and identifiers seen by two or more tools, connected. Drag, add and annotate: once you edit it, True Bearing stops overwriting it |
| **Chronology.md** | The timeline from Event notes, findings, the missing-person timeline and timed places, oldest first, with the kind of each time (camera clock, platform, analyst, witness) |
| **People/, Places/, Organisations/, Events/** | Your working notes. Create them from Notes → **New note: …** |

Things to keep in mind:

- **Times:** True Bearing writes everything in UTC (properties ending `_utc`). Write event and finding times in UTC too, and note what kind of time it is: a camera clock can be wrong, and a platform shows its own time zone.
- **Rebuild a note** after you change a result folder by hand: Notes → **Refresh this case's notes**.
- **Getting events into the report:** the report's chronology holds Event notes with **`reportable: true`**, the reportable findings that have a `when_utc`, and the last-seen time. Everything else stays in Chronology.md.
- **Missing-person timeline:** **Missing person** → **Build the timeline** places everything relative to the last-seen moment; anything after it "advances the timeline".

📷 *Selectors.md with counts and suggested searches.* 📷 *The link chart.*

---

## 7. Write findings

A **Finding** is one conclusion you're prepared to stand behind. One per note.

### 7.1 Create it

- From a result you've just run: Notes → **New finding from the latest result** (already linked to it).
- Or Notes → **New note: finding**.

Give it a title that states the conclusion: *Jane Doe posted from Kingston on 2026-10-26*.

### 7.2 Fill it in

| Property / section | What to write |
|---|---|
| **Observed** | Only what the source shows, with the date and where it was seen. No interpretation |
| **Assessment** | What you conclude and why, and **the alternative explanations you considered** |
| `results` | Links to the result notes it rests on |
| `exhibits` | The exhibit IDs (`…-EX-001`), filled in when you start from a recorded result. The report re-checks each one's fingerprint |
| `when_utc` | When it happened, if it has a time. It joins the chronology |
| `source_grade` | How reliable the **source** is: A always · B usually · C fairly · D not usually · E unreliable · F can't be judged |
| `info_grade` | How credible **this information** is: 1 confirmed elsewhere · 2 probably true · 3 possibly true · 4 doubtful · 5 improbable · 6 can't be judged |
| `status` | `lead` → `corroborated` (two independent sources) → `confirmed` |
| `reportable` | `true` once it's corroborated or confirmed and belongs in the report |

**Grading examples:**
- An official police appeal page stating the last-seen time: **A1**.
- The subject's verified Instagram account posting a photo with a recognisable landmark, matched to street-level imagery: **B2**.
- A single username hit on a site you couldn't open: **F6**. It's a lead, not a finding.

For complete graded findings tables, see [A6](#a6-findings) and [B6](#b6-findings-and-conclusion). Don't grade everything B2: the grade should say something. A single unverified source is rarely better than C3.

### 7.3 Corroborate

A tool hit is not a finding. Before `corroborated`, you want two **independent** sources, for example two of:

- the same photo on another account known to be the subject's (same-photo finder, or checked by eye);
- bio, links or cross-links consistent with what the intake says;
- the same stable platform ID (Telegram ID, account number);
- location and timeline that fit the known facts;
- contacts and network that overlap with known ones.

Two username tools agreeing is **not** independent: they check the same site.

**Known traps:**

| Source | Trap |
|---|---|
| Username tools | Common names collide; recycled usernames belong to new owners; the richest namesake profile isn't necessarily the subject |
| GeoCLIP | Usually right to the country or region, rarely the street. A probability isn't a location |
| Face comparison | "Strong similarity" isn't identification. Accuracy drops with small, angled or old photos, and varies between groups. The report warns on any finding that cites it |
| Machine translation | Slang, names and dialect go wrong. Have it checked before you rely on it |
| Photo times | EXIF is the camera's clock (time zone unknown, sometimes wrong). Upload time isn't capture time. A repost isn't new activity |
| Ransomware and leak sites | Criminals' claims, often unverified |

### 7.4 Discount, never delete

If a finding turns out wrong: Notes → **Discount a finding**, with the reason (`Different person: account created 2014 in another country, photos don't match`). It's marked discounted, the reason is written to the contemporaneous notes, and the report lists it as **unused material**. A deleted finding is flagged in the report.

**Every finding not in the report is listed by title as unused material,** leads included. Titles are disclosable: write them factually.

📷 *A completed finding note: properties, Observed, Assessment, Sources.*

---

## 8. Review

Before the report, someone other than you checks the work. If you work alone (a solo practitioner or a training exercise), ask a colleague, or record your own review honestly as a self-review (role: `self-review, no supervisor available`) so the reader knows.

1. Finish the **Summary** and **Analysis** in Case.md.
2. The reviewer reads Case.md, the reportable findings and their evidence. The **Integrity** box on Case.md must say *all records intact*.
3. Main menu → **Case** → **Record a supervisor review**: reviewer's name, role, decision (*approved*, *approved with changes*, *changes requested*, *not approved*) and comments.

The review is written to the contemporaneous notes with two fingerprints: the reportable findings, and what you wrote in Case.md (summary, analysis, next steps). **If either changes afterwards, the report warns you,** so make the changes and record a new review.

---

## 9. Build the report

Main menu → **Case** → **Build a report (Word document)**.

If anything doesn't hold up, True Bearing lists **warnings** first and asks whether to build anyway. Fix them instead, unless you have a reason you'll write down:

| Warning | Fix |
|---|---|
| A reportable finding has no sealed evidence | Record the result folder as an exhibit (step 5) and add the ID to the finding's `exhibits` |
| Missing grades | Fill in `source_grade` and `info_grade` |
| An exhibit or file no longer matches | Something changed after sealing. Find out why, and write a note. Don't re-seal over it |
| Findings changed since the review / no review | Record a review (step 8) |
| No intake record, or intake incomplete | Case → **Edit case details (intake)**. Missing intake recorded now is marked late in the notes |
| The summary, analysis or next steps changed since the review | Record a new review |
| Exhibit isn't in the exhibits register | Check the ID you typed in `exhibits` against **List exhibits** |
| Marked reportable but still a lead | Corroborate it first, or set `reportable: false` |
| Discounted without a reason | Fill in `discount_reason` |
| Cites a face comparison | Not an error: check the wording says similarity for human review, never identification |
| A finding note was deleted | Restore it and discount it instead |

Each build is a new version in `reports/v<n>_<time>/`:

| File | Contents |
|---|---|
| `report.docx` | The report: case details, warnings (if any), your summary and analysis, each reportable finding with its grading, observation, assessment and verified exhibits, the chronology, nil returns, unused material, the latest review, then methodology (tools and sources actually used), exhibits, notes and the audit log |
| `report.md` | Its source |
| `findings-section.md` | The generated findings part of the report |
| `findings-frozen.md` | The findings exactly as they were used |
| `hashes.sha256` | SHA-256 of report.md, report.docx and findings-frozen.md |

The report's hash is written to the contemporaneous notes. **Read the whole .docx** before it goes anywhere. If you need to fix something, fix the finding or Case.md and build again; don't edit the generated Word file in place, or keep your edited copy beside it and say so in a note.

📷 *The report folder and its files.* 📷 *The first page of report.docx.*

---

## 10. Submit, hand over and close

1. Case → **Verify notes and audit log**: both chains should report 0 broken.
2. **Evidence & exhibits** → **Export the case (archive + SHA-256)**: a `.tar.gz` of the whole case in `~/TrueBearing/Exports/`, readable only by you, with a `.sha256` beside it. If the export leaves the VM, use **Export the case, encrypted (age or PGP)** instead: encrypted for the recipient's public key (age, SSH or PGP), or a passphrase you send by another channel. For a PGP key, check the fingerprint shown with the recipient before you send.
3. Submit `report.docx` with `hashes.sha256` (and the export, if the recipient needs the evidence) through your organisation's approved channel, and send the SHA-256 values separately so they can check what they received. If no approved channel exists and the recipient has Tor Browser, **Dark web** → **OnionShare: send files over a private .onion link** sends them end to end encrypted; give the address and the private key by two different channels.
4. If someone else takes over, give them **Handover.md**: intake and lawful basis, integrity, findings and report status, the last review, open leads and owners, next steps and decisions.
5. Case → **Close this case (verify, export, mark closed)**. Before closing, True Bearing checks that the notes, audit log and exhibits verify, a report has been built since the last change to findings, a review covers the current findings and summary, the intake is complete and no leads are open. Anything not done is listed; if you close anyway, the open points are written to the notes. Nothing is deleted, and scheduled page checks skip closed cases.

   A closed case takes no more notes, reviews or reports. To work on it again, Case → **Reopen this case**, with a reason (recorded in the notes).

   Delete the working copy when your retention date allows, and revert the VM to its clean snapshot.

---

## 11. Pre-submission checklist

- [ ] Intake complete: reference, authority, lawful basis, scope, review date
- [ ] Collection stayed in scope; the review date hasn't passed
- [ ] Contemporaneous notes cover each session, every decision and the significant nil results
- [ ] Every reportable finding has Observed and Assessment, both grades, `results` and `exhibits`
- [ ] Every reportable finding is corroborated or confirmed; single-source items stay leads
- [ ] Wrong findings are discounted with a reason, not deleted
- [ ] Every result note reviewed (`reviewed: true`); nil returns marked; no "no output saved (not yet checked)" rows left in the report
- [ ] Leads closed, or assigned with `assigned_to`; Next steps in Case.md ticked or explained
- [ ] Unverified accounts aren't presented as the subject's
- [ ] Face similarity, GeoCLIP estimates and machine translations are described as leads and were checked independently
- [ ] Times are in UTC, with their kind (camera, platform, witness)
- [ ] Case.md: Summary and Analysis written; Integrity says all records intact
- [ ] Supervisor review recorded after the last change to findings
- [ ] Report built with **no warnings** (or each one explained in a note)
- [ ] report.docx read in full; no breach passwords, API keys or out-of-scope people in it
- [ ] Notes and audit log verified; each exhibit verified intact; case exported with its SHA-256
- [ ] Delivered through the approved channel; hash sent separately

---

## 12. Common mistakes

- **Treating a username hit as an account.** It means only that the name exists on that site.
- **Searching before the intake is recorded.** Your authority and scope must predate the work.
- **Interacting.** Following, liking, joining a Telegram group, or messaging: all visible, and they can put the subject or the case at risk.
- **Uploading victim photos** to reverse-image or face-search sites. Use the local tools.
- **Capturing late.** Posts disappear. Capture and record exhibits when you find them.
- **Editing inside result folders.** It breaks the seal. Work on copies.
- **Deleting a wrong finding.** Discount it with a reason.
- **Mixing time zones.** Write UTC, and say what kind of time it is.
- **Using one case for several matters.** One matter, one case.
- **Personal accounts in the VM.** Research accounts only. Even viewing can show: LinkedIn shows profile views, and stories show who watched them.
- **Working in the wrong case.** Check the case name in the main menu before each session.
- **Grading everything B2**, or marking a lead reportable.
- **Editing findings after the review** and ignoring the warning.
- **Treating breach passwords as evidence**, or putting them in the report.

---

## Worked examples

Two more complete cases, worked through with the menus from intake to report: one starting from a dark-web username, one from a single photo. Both identify a person, so both start the same way: **no search before the intake is recorded**, and the lawful basis must cover identifying someone. Identification is a conclusion you reach from several independent pieces of evidence, graded and reviewed. No single tool hit, and no face score, ever identifies anyone on its own.

> **Everything here is fictional.** The handles, accounts, names, companies and addresses are invented, and use "example" so they can't be mistaken for real ones. Emails use the reserved `example.com`/`example.net` domains; onion addresses are shortened placeholders (`exampleforum…onion`). **Don't search for any of them.** Places are real only where a real city is needed to show how geolocation works.

---

## 13. Worked example A: a dark-web vendor, from a username to a name

### A. The tasking

A company's security team finds a post on a dark-web forum: a user called **`example_vendor`** is selling what they claim is remote access to the company's network and a sample of its customer records. The company's general counsel asks you to establish whether the claim is credible and who is behind the handle, so the matter can be referred to the police. You may not buy, register on the forum, message or interact with the seller.

### A1. Intake and preparation

**Switch / create case** → `2026-044-vendor`:

| Prompt | Entry |
|---|---|
| Client or matter reference | `CI-2026-044` |
| Authorised by | `General Counsel, Example Corp (fictional); email of 2026-10-27 08:40 UTC` |
| Purpose and lawful basis | `Assess a claimed sale of company access and data; identify the seller for referral to police. Legitimate interest (security of the company's systems and customers' data); legal review on file` |
| Scope and subjects | `The handle example_vendor and the identifiers it publishes. A research account may be used for read-only Telegram lookups. Out of scope: buying, registering on the forum, messaging anyone, login-only forum areas, other forum users` |
| Review date | `2027-01-27` |

First notes (Case → **Add a note**):

> `Tasking received 08:40 UTC. Plan: capture the public post and profile as text, check ransomware leak sites for the company, then pivot on identifiers the seller publishes.`
> `DECISION: no forum account will be registered; if the profile is login-only, collection from the forum stops there.`

Preparation:
- **Dark web** → **Check Tor connection**: it must say the connection goes through Tor.
- Work inside the VM, never logged in to anything personal. Nothing is downloaded from onion sites: the menu fetches one text page.

### A2. Capture the claim

1. **Dark web** → **Fetch an onion page as text (safe)** with the post's address (`exampleforum…onion/thread/…`). Tor fetches one document: scripts aren't run, images aren't fetched, and anything that isn't a text page is discarded unread. The sealed result folder holds:
   - `page.txt`: the readable text;
   - `page.html.txt`: the page source, kept as text (never open it in a browser);
   - `links.txt`, `onion_addresses.txt`, `headers.txt`, `metadata.json`.
2. Do the same for the seller's public profile page, if the forum shows it without a login. If the forum asks for a login or a CAPTCHA, **stop**: True Bearing won't get around it, and you mustn't either. Note it.
3. **Evidence & exhibits** → **Record a result folder as an exhibit** for both: `EX-001 forum post`, `EX-002 seller profile`.
4. **Dark web** → **Ransomware leak-site check (organisation)** with the company's name and domain. A listing would mean a ransomware group claims an attack; that's a criminal's claim, not a fact.

Note in Case → **Add a note** what each page showed and when it was fetched (the capture's UTC time is in the result folder).

### A3. Read what the seller leaks

Read `page.txt` for each capture yourself. The Selectors page picks up onion addresses from these captures, but not usernames or emails in free text. Sellers often leak, for example:

| Seen in the capture (fictional) | Why it matters |
|---|---|
| "Contact: Telegram `@example_vendor_ops`" | A Telegram handle, which has a stable numeric ID |
| A Jabber/XMPP address `exvendor@xmpp.example.net` | A reusable contact identifier |
| A PGP public key block, and posts signed with it | The key's user ID often holds a name or email; a signature shows who controls the key |
| "Member since 2023", post times | An activity history and time-of-day pattern |
| Writing quirks (a repeated typo, a signature line) | Stylistic links to other accounts, weak on their own |

**The PGP key.** Copy the key block from `page.txt` into a new text file outside the result folder (never edit sealed files), then in a terminal:

```bash
gpg --show-keys --with-fingerprint --keyid-format long key.asc
```

This shows the key's user IDs, creation date and fingerprint **without importing it**. Say the user ID is `exvendor <ex.vendor@example.com>`, created 2023-02-11. Remember that the user ID and the date are whatever the key's maker typed and their clock said. Don't look the key up on public keyservers from the case machine without thinking about what that reveals.

If the seller's posts include **PGP-signed messages**, save one the same way and check it against the key (`gpg --verify` needs the key imported; do that in a throwaway keyring, e.g. `GNUPGHOME=$(mktemp -d)`). A valid signature shows the seller holds the private key. A key that's only displayed proves nothing about who controls it: anyone can copy a public key.

Record what you found in a note: `PGP key on profile (EX-002): user ID exvendor <ex.vendor@example.com>, created 2023-02-11, fingerprint …; signed post of 2026-10-20 verifies against it.`

### A4. Pivot to the clear web

Each identifier becomes a search. After each one, the result note appears in Obsidian, and **Selectors.md** shows what was found and which searches are still open (✓ = done).

1. **Username & email** → **Username search** for `example_vendor` and `example_vendor_ops`. Most hits will be other people. Open each likely hit and look for the same contact details, PGP key, avatar or writing.
2. **Username & email** → **Email search** for `ex.vendor@example.com`: the services where this address has an account (holehe). It tells you a site, not which account on it. If it's a Gmail address, **Google account** (GHunt) can show the Google account's name and photo.
3. **Telegram** → **Look up a channel, group, bot or user** for `example_vendor_ops` (no login), then **User profile (login)** with your research account: the numeric ID, all usernames, bio and profile photo. Record the ID: usernames change, the ID doesn't.
4. **Breach data** with the email and the usernames. Lookups only: nothing is downloaded. Two kinds of result are common:
   - the email appears in old breaches of ordinary sites (a forum, a game), sometimes with a username or a name;
   - an **infostealer** hit (Hudson Rock): a computer that used this email or username was infected with password-stealing malware. For a criminal, that's a frequent route to their real identity, but details beyond the summary come from the service, not from True Bearing, and must be handled under your legal basis.

   Passwords are masked in `summary.txt` and never reach your notes. Don't put them in findings or the report.
5. **Domain & infrastructure** → **WHOIS, RDAP & DNS records** and **Archived URLs** for any website the seller mentions: registration dates, name servers and old versions of pages can carry the same email or handle.
6. **Capture web pages** for every clear-web profile you'll rely on, and record each as an exhibit as you go.

Suppose the pivots give this (fictional) picture:

- `example_vendor` on a gaming forum in 2019, with the same avatar as the Telegram profile;
- a code-hosting account `exvendor-dev` whose public profile shows `ex.vendor@example.com` and the name **Alex Example**, and whose project had the same PGP key (same fingerprint) added to its README in a 2023 commit;
- the breach lookup lists `ex.vendor@example.com` in a 2020 breach of a gaming site, **paired with the username `exvendor-dev`**.

### A5. Analyse

- **Accounts.md**: accounts found by two or more tools get an Account note, still **unverified**. For each one you've checked by hand, fill in **Attribution** (what links it) and set `verified: true` and `owner` only when the evidence holds.
- **Link chart.canvas**: connect `example_vendor` → PGP key → `exvendor-dev` → `ex.vendor@example.com` → the person note **Alex Example** (Notes → **New note: person**), and label each edge with its evidence.
- **Chronology.md**: add Event notes (Notes → **New note: event**) with `when_utc` and a `time_kind` that says whose clock it is: `platform` for post and account times, `key maker's clock` for the key's creation date. Post times bunching between 18:00 and 01:00 UTC suggest a time zone, which is supporting context at most.
- **Discount what doesn't hold**: an `example_vendor` on a photography site, plainly a different person, gets Notes → **Discount a finding** with the reason.

### A6. Findings

| Finding (title) | Status | Grade | Rests on |
|---|---|---|---|
| The seller's profile displays a PGP key with user ID ex.vendor@example.com, and their signed post verifies against it | confirmed | F1 | EX-002, EX-003 (signed post), `gpg --verify` output. The capture is certain; the forum as a source can't be judged |
| The same key (same fingerprint) was added to the exvendor-dev project in 2023 | confirmed | B1 | EX-004 (capture of the README and its commit) |
| The exvendor-dev profile shows ex.vendor@example.com and the name Alex Example | confirmed | B1 | EX-004 |
| A 2020 breach record pairs ex.vendor@example.com with the username exvendor-dev | corroborated | C2 | Breach data result (summary only) |
| The account holder's name is Alex Example | lead | C3 | Self-declared on the profile; not verified |

**Assessment** (in Case.md's Analysis): *"The seller example_vendor holds the private key of a PGP key that the exvendor-dev account published in 2023. Separately, a 2020 breach record pairs that account's username with the key's email. The seller is therefore probably the person using exvendor-dev, which gives the name Alex Example. Alternatives considered: the key was stolen, or shared between people (can't be excluded from open sources); exvendor-dev copied the seller's key to look credible (unlikely: the key was on exvendor-dev first, and the breach record links the email to that account in 2020); a deliberate false trail (possible). That the name is real is unverified: confirming it is for the police, with legal process."*

Without a verified signature, the key alone would only show that the seller *displays* exvendor-dev's key, which anyone could copy, possibly to frame them. Use measured language ("probably", "consistent with") and say what would change your view. The claim about the company's data is a separate finding, graded on its own (e.g. *the sample's format matches the company's customer table*: confirmed by the company's security team, not by you).

### A7. Review, report, hand over

Follow the guide from [step 8](#8-review): supervisor review, **Build a report**, read the whole report, verify, export and hand to the police through counsel. **Don't contact the seller or the person named**, and don't publish anything: that could tip them off or wreck a prosecution.

---

## 14. Worked example B: one photo, to where it was taken and who is in it

### B. The tasking

A fraud victim's solicitor sends you one photo. A man calling himself "Daniel" sent it during an online romance that ended with the victim transferring money. The photo shows a smiling man in his thirties in a sunny street: a yellow tram behind him, blue-and-white tiled walls, a shop sign partly visible. Questions: **where and when was the photo taken, who is the man in it, and is he "Daniel"?**

In romance fraud, the photos are very often **stolen from someone else's public account**. So the honest answer to "who is in the photo" may be an unconnected person who is himself a victim. Keep that alternative open from the start.

### B1. Intake

**Switch / create case** → `2026-052-photo`:

| Prompt | Entry |
|---|---|
| Client or matter reference | `Solicitor ref. RF/0000 (fictional)` |
| Authorised by | `Solicitor acting for the victim; instruction letter dated 2026-10-26` |
| Purpose and lawful basis | `Establish where the photo was taken and its origin, to support a fraud report to police. Legal claim / legitimate interest` |
| Scope and subjects | `The photo, the "Daniel" profile, and the account that first published the photo. Out of scope: the pictured man's private life beyond establishing whether he is the source of the photos; contacting anyone` |
| Review date | `2027-01-26` |

> `Received photo daniel_1.jpg by email from the solicitor at 10:05 UTC. Plan: metadata, origin (reverse search), geolocation, then the account that first published it.`

### B2. Preserve and read the file

1. **Image analysis** → **Analyze a local image (EXIF, GPS, then reverse search)**: the photo is copied into the case with its SHA-256, and its EXIF is saved as `<file>.exif.txt`. If it has GPS, the location opens on a map.
2. Read the EXIF. Photos sent through messaging apps are usually stripped. Here the file has no GPS, but it has a camera model and `DateTimeOriginal 2024:06:14 18:52`. That's the **camera's clock**: time zone unknown, possibly wrong. Record it in a note with that caveat.
3. Collect the other "Daniel" photos the victim received the same way. **Image analysis** → **Find the same photo across this case** later shows which of them also appear elsewhere in the case.

### B3. Where did the photo come from?

A photo of an unknown adult used in a fraud is normally reverse-searched. Check your organisation's policy first: anything you **drag into** a reverse-search page is uploaded to that service, including FotoForensics, which the menu also opens. Never do this with photos of victims or children.

- For a photo of a face, start with **TinEye** and **Google Lens**: they look for copies of the same photo. **Yandex** matches faces, so use it only if your policy allows face search; otherwise crop the photo to the background first.
- Suppose Lens finds the same photo on a public Instagram account, **`@example.photo.pt`**, posted **2024-06-15**, two years before the fraud, among years of photos of the same man.

That's the photo's likely origin. Capture **only the posts that match the "Daniel" photos** and the profile page (**Capture web pages**), record them as exhibits, and note it. You don't need the man's whole account.

### B4. Where was it taken?

Work from the photo's own clues, then confirm.

1. **Photo geolocation** → **Where was this photo taken? (clues + AI estimate)**. It reads EXIF, the text in the photo (OCR) and runs GeoCLIP locally. Suppose:
   - OCR reads a partial sign, `…ARMÁCIA`, and **Translate (offline)** confirms *farmácia* is Portuguese for pharmacy;
   - GeoCLIP's top estimates cluster in Lisbon. That's a **lead**, not a location.
2. **Photo geolocation** → **Find places by features (Bellingcat OSM Search)**: look for pharmacies within a few metres of a tram line in Lisbon. Narrow the list by the slope of the street and the tiled façade.
3. Check each candidate in street-level imagery (the menu opens Mapillary for the top estimates; use what your policy allows). Match **at least three independent features**: the tram stop, the tile pattern, the sign's position and the building line. Save screenshots of the matching view and capture its URL.
4. **Photo geolocation** → **Shadow analysis: where could this shadow occur? (ShadowFinder)**. Measure an object whose height you can check in the street-level imagery (a sign post, a door), and its shadow in the photo. ShadowFinder needs a UTC time, and here you don't have an independent one: you only have the camera clock. If you read it as Lisbon local time (UTC+1 in June), say so. A shadow band that includes Lisbon then means "consistent under that assumption", not "confirmed": the place is already part of how you got the time.
5. **Case map** → **Add a place**: `photo location (matched)` at the matched coordinates. **Build the case map**: the place, any photo GPS and the GeoCLIP estimates appear together.

> `Photo geolocated to a tram stop by a pharmacy in Lisbon: tram stop, tile pattern, sign position and building line match street-level imagery (EX-006). Shadow consistent with the camera time read as Lisbon local time (EX-007); not independent of the location.`

**When**: the camera time (14 June, 18:52 on the camera's clock), the shadow (late afternoon in June, under the assumption above) and the Instagram post (15 June, the day after) are consistent. Put each in **Chronology.md** as an Event note with its kind of time: `camera clock`, `analyst` (shadow estimate), `platform` (post).

### B5. Who is the man in the photo, as far as the case needs?

The tasking needs to know whether the pictured man is "Daniel", and where the photos came from. That's answered by **provenance**, not by finding out everything about him.

- The `@example.photo.pt` account has six years of posts, friends tagging him, consistent locations, the original high-resolution photos, and a bio giving the name **Rui Exemplo** (fictional), a photographer.
- The "Daniel" profile was created three weeks before contacting the victim, and every one of its photos appears earlier on `@example.photo.pt`, cropped to remove a watermark. **Find the same photo across this case** groups each "Daniel" photo with its earlier original.

Don't run this photo through the online face search engines (Image analysis → **Face search engines**) either. The man is an unconnected private person whose identity the tasking doesn't need, and sending his face to a commercial service raises serious legal problems in many places (biometric data under the GDPR, for example). **Face comparison** isn't needed here either: identical photos already prove where they came from, so comparing faces would be processing biometric data for nothing. Further searches on the man (other platforms, his business, his home) are outside the scope.

### B6. Findings and conclusion

| Finding (title) | Status | Grade | Rests on |
|---|---|---|---|
| The photo sent by "Daniel" was published on @example.photo.pt on 2024-06-15 | confirmed | B1 | EX-004 (capture of the post); same-photo match |
| Every "Daniel" photo appears earlier on @example.photo.pt | confirmed | B1 | Same-photo finder (EX-009), EX-004 |
| The photo was taken at a tram stop by a pharmacy in Lisbon | corroborated | B2 | EX-006: four features matched in street-level imagery |
| It was probably taken on 2024-06-14 in the late afternoon | lead | C3 | Camera clock (time zone assumed), shadow consistent under that assumption, post date |
| The man pictured is probably the holder of @example.photo.pt, who gives his name as Rui Exemplo | corroborated | C2 | Six years of posts, friends tagging him, original photos; the name is self-declared |

**Assessment**: *"The photos are stolen. The man pictured is probably the holder of @example.photo.pt, a photographer who calls himself Rui Exemplo, with no indication that he is connected to the fraud. Whoever ran the 'Daniel' profile is not identified by this work."* That answers the tasking honestly. Pointing the victim at the man in the photo would be wrong and could put him at risk.

Record the account that ran the fraud (its profile URL, numeric ID if visible, the payment details the victim was given) as leads for the police, who can get records from the platform and the bank.

### B7. Review, report, hand over

As in the guide, from [step 8](#8-review). The report goes to the solicitor for the police report. **Nobody contacts the pictured man** unless the police decide to; if anyone does, it's to tell him his photos are being misused.

---

## 15. What the worked examples have in common

- **Intake first.** Identifying someone needs a purpose and lawful basis that cover it, and the scope says how far to go.
- **Capture, then exhibit, then analyse.** Pages change: seal what you'll rely on as soon as you see it.
- **Pivot on stable identifiers** (PGP key fingerprints, platform IDs, original photos), not on display names or common words.
- **Two independent sources** before a finding is corroborated. Tools that check the same site aren't independent, and neither is a fact derived from another (an email taken from a key's user ID doesn't confirm the key).
- **Control, not display:** a public key, a photo or a handle can be copied. A verified signature or the original upload is stronger.
- **Write the alternatives down**, and discount what fails, with the reason.
- **Measured conclusions:** *probably* and *consistent with* until something confirms it, and "not identified" when that's the truth.
- **Never contact or confront** anyone, and hand identification to the people with legal powers to confirm it.

---

## Appendix: screenshots to capture

To illustrate this guide from your own VM, capture these with **Print Screen** (Flameshot) and save them in `docs/images/guide/`, using a test case with made-up data only:

| File | Step |
|---|---|
| `01-health-check.png` | 1.2 Health check report |
| `02-home.png` | 1.5 Obsidian Home.md |
| `03-case-opened.png` | 2 Case opened message |
| `04-case-dashboard.png` | 3.3 Case.md |
| `05-username-result.png` | 4.2 Username result note |
| `06-case-map.png` | 4.7 map.html |
| `07-exhibits.png` | 5 Exhibit list |
| `08-selectors.png` | 6 Selectors.md |
| `09-link-chart.png` | 6 Link chart |
| `10-finding.png` | 7 Finding note |
| `11-report-folder.png` | 9 Report folder |
| `12-report-docx.png` | 9 report.docx first page |
