# Investigation guide: from zero to a case ready for submission

This guide takes you through a whole investigation on the northstar VM, step by step: preparing the VM, opening a case, collecting, sealing evidence, analysing in Obsidian, writing findings, review, and the report you hand over. It uses one fictional worked example throughout, a missing adult called **Jane Doe**, but the same steps work for due diligence, fraud or threat cases.

It draws on reviews by an experienced case manager (evidence, supervision, handover) and a senior OSINT specialist (collection, verification, OPSEC).

You don't need to know the command line. Everything here is in the **northstar** menu (the compass icon in the dock, or type `northstar` in a terminal). Menu names in **bold** are exactly what you'll see.

> **📷 Screenshots.** Places marked 📷 show what you should see at that step. To capture your own, press **Print Screen** in the VM (Flameshot).

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

## How it fits together

| Where | What it holds | Can it be edited? |
|---|---|---|
| **Result folders** (`~/Northstar/Cases/<case>/<kind>/<target>_<time>/`) | Everything a tool collected, sealed with SHA-256 hashes when the search finishes | No: any change shows when it's verified |
| **`audit.log`** | Every search you ran, with the UTC time, the tool and the operator, hash-chained | No: edits break the chain |
| **`notes.md`** (Case → **Add a note**) | Your contemporaneous notes, hash-chained | No: you can only add to it |
| **Obsidian notes** (Case.md, Findings, People, Accounts…) | Your working analysis and conclusions | Yes: this is your workspace |
| **`reports/v<n>_<time>/`** | Each report version, its frozen findings and their hashes | No: a new version gets a new folder |

The rule of thumb: **tools collect, the seal proves, notes record what you did and why, Findings say what you concluded, the report draws from the Findings.**

---

## 1. Before your first case

Do this once when the VM is new, and the update and health check before every case.

### 1.1 Take a clean snapshot

In UTM, with the VM shut down, take a snapshot called *clean baseline*. Go back to it between unrelated cases so nothing (browser history, logins, cookies) carries over. Case data lives in `~/Northstar`: export it before you revert (step 10).

### 1.2 Update and check health

1. Main menu → **Update northstar**. A good update ends with **All modules completed.**; otherwise it lists the modules that failed (see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)).
2. Main menu → **Health check**. Read the summary at the end: anything missing, and the keys file or Northstar folders readable by other accounts. Note which of ports 3389 (xrdp), 4000 (amass) and 9050 (Tor) are listening, and whether you expected them to be. The report is saved in `~/Northstar/support/`.

📷 *The Health check report, with the Tools section and no problems listed.*

### 1.3 Your connection

Every search leaves from the VM's internet connection. If your organisation requires a VPN or a dedicated research line, connect it **before** you open the browser or run any menu. Check your public IP in the browser before you start.

### 1.4 Research accounts and API keys

- **Research accounts** ("sock puppets") only, never your personal accounts: for Telegram, Instagram and anything else that needs a login. Create them under your organisation's policy.
- **API keys** (optional, adds paid breach sources): main menu → **API keys**. Keys are typed into a hidden field, stored readable only by you, and never logged.
- **Telegram searches** need a one-time login: main menu → **Telegram** → **Log in for searches**, after adding the API ID and hash from [my.telegram.org/apps](https://my.telegram.org/apps) under **API keys**.
- **Logins the menus don't walk you through** (only if you'll use them): the Google account search needs `ghunt login` once in a terminal; Instagram downloads work better after `instaloader --login <research account>`; **Instagram profile details** asks for a session ID, which is never logged.
- **Messaging apps** (Telegram Desktop, Signal, Element) are installed for research accounts only.

### 1.5 Open the vault in Obsidian

Main menu → **Notes (Obsidian)** → **Open the Cases vault (all cases)**. If Obsidian asks whether to trust the vault, either answer works: northstar uses no community plugins, so you can keep restricted mode on. You'll see `Home.md`, the list of every case.

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

Main menu → **Notes (Obsidian)** → **Open this case's notes**. This is `Case.md`, the dashboard. The top part is generated by northstar and refreshed after every search. **Write below the end marker:**

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

> **What leaves the VM.** Image files never leave it through northstar's own tools. But **Reverse search an image URL** sends the URL to Google, Yandex, Bing and TinEye, and anything you **drag into** a reverse-search page that a menu opens (from **Analyze a local image**, **Video verification** or **Photo geolocation**) is uploaded to that service. Never do that with photos of victims or minors. Use the local tools (same-photo finder, face comparison, GeoCLIP) instead.
>
> Other things that go out: **Reverse search an image URL** may download a copy of the image over your connection (it asks first unless Tor is running); case-map address lookups and GeoCLIP place names send text or coordinates to OpenStreetMap; opening `map.html` loads map tiles. Every web search and page capture goes out over your connection.

### 4.1 Missing-persons databases

**Missing person** → **Missing-persons databases and resources** → pick the country (or International). The subject's name is pre-filled; accept it. The official databases open in the browser. Note in Case → **Add a note** which ones you checked and what they showed.

### 4.2 Usernames and emails

**Username & email**:

1. **Username search** with `janedoe90`. Sherlock, Maigret, socialscan and Blackbird check hundreds of sites. Expect **false positives**: a "hit" only means a profile with that name exists.
2. **Email search** with the email: which services it's registered with (holehe).
3. **Generate username and email variants**: likely variants from the name and birth year, optionally checked. These are guesses: hits on them are especially likely to be someone else.
4. **Google account** (with an email; needs `ghunt login`): the name, photo and sometimes public Maps reviews, which can be a location lead.

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

1. **Metadata** → **View metadata** on photos you collected: camera, times and GPS if present. Most social platforms strip metadata, so it's usually only in original files.
2. **Image analysis** → **Find the same photo across this case**: the same picture on two accounts often shows they're connected.
3. **Image analysis** → **Reverse search an image URL** (Google Lens, Yandex, Bing, TinEye), or **Analyze a local image**, which opens Google Lens, Yandex, TinEye and FotoForensics for you to drag it into (and Google Maps if it has GPS). Never upload photos of victims or minors to online services.
4. **Photo geolocation** → **Where was this photo taken?**: EXIF, the text visible in the photo (OCR) and, optionally, GeoCLIP's estimate, all on your computer. GeoCLIP gives **leads, not answers**: confirm them with street-level imagery, signs, landmarks or **Shadow analysis**.
5. **Face comparison (within this case)**: compares a reference face (the official photo) with faces in photos already in the case. It asks for the lawful basis the first time. A score is similarity, never identification: treat it as a reason to look closer.

### 4.6 Video

**Video verification** with a URL or file: frames at every scene change for reverse searching, technical metadata, and an offline transcript and translation of the speech.

### 4.7 Places and the case map

**Case map** → **Add a place** for the last-seen location, sightings, home and work (by address or `lat, lon`). Then **Build the case map**: photo GPS and GeoCLIP estimates are added automatically, and you get `map.html` plus KML and GeoJSON for Google Earth or QGIS.

📷 *map.html with the last-seen place, a photo GPS point and AI estimates.*

### 4.8 Country records

**Country search** → the country → the kind of search (people, business, phone, vehicle, court…). The links and your query are saved to the case; the search pages open in the browser.

### 4.9 Breach data (only if your basis covers it)

**Breach data** with the email or username: which breaches and infostealer infections it appears in. Only lookups: nothing is downloaded. The result note shows the summary only; passwords never reach your notes.

**Careful:** paid services can return passwords. They're masked in `summary.txt` and never reach your notes, but the services' raw responses (`<source>.json`, readable only by you) stay in the result folder, and so in the case export. Handle the export accordingly.

Use it for pivots (old usernames, phone numbers, other services), not as proof. Breach data tells you an identifier existed and was used, not who is using it now. An infostealer hit means one of the subject's devices was once infected; it says nothing about where they are. If breach data isn't needed for your purpose, don't search it, and write a `DECISION:` note saying why.

### 4.10 Page monitoring (proof of life)

**Page monitoring (proof of life)** → **Watch a page** for the subject's public profiles or `t.me/s/<channel>`, then **Scheduled checks** (every 3–24 hours). Scheduled checks cover every open case. A change brings a desktop notification, goes into the audit log and **Recent changes**, and appears in Case.md's **Page monitoring: latest changes** the next time the dashboard is refreshed.

It can't watch pages that need a login or are built entirely by JavaScript, which rules out most Instagram and Facebook profiles: check those by hand on a schedule and note it. A change isn't proof of life on its own: it can be a scheduled post, a relative or admin, or a repost. **Capture** the change and check who posted it. Keep the number of pages and the frequency modest.

### 4.11 Translation

**Translate (offline)** for posts, captions and transcripts. Nothing leaves the VM. Machine translation is a lead: have anything that matters checked by a qualified translator.

### 4.12 Search-party events: flags

At a Trace Labs-style event, log each submission as you find it with **Missing person** → **Log a finding (flag)** (category, URL, why it matters, optional screenshot), then **Export findings** for the event platform. These flags are a separate log for the event: **they don't go into the Word report**. For a case that ends in a report, record conclusions as Obsidian **Findings** (step 7).

### 4.13 Log nil results

A search that finds nothing is still a result. On that result note in Obsidian, set the property **`nil_return: true`** and say what you searched in **Analyst notes**. The report lists nil returns, so the reader knows the ground you covered.

---

## 5. Seal and record evidence

Every result folder is already sealed. **Record the ones you'll rely on as exhibits:** main menu → **Evidence & exhibits** → **Record a result folder as an exhibit**, choose the folder and describe it (`Capture of Instagram profile janedoe90, 2026-10-27`). It gets a number such as `2026-031-JANE-DOE-EX-001`, and its fingerprint goes in `exhibits.csv`. If it's offered, you can add an OpenTimestamps proof.

- Record captures as exhibits **as soon as you take them**, not at the end.
- Copy the exhibit ID: you'll type it into the `exhibits` list of the findings that rely on it.
- Work on copies. Don't open and save files inside result folders: any change shows as a broken seal.
- **Verify a folder (has anything changed?)** before you rely on an older one.

📷 *The exhibit list (List exhibits).*

---

## 6. Analyse in Obsidian

Everything you've collected is now in the vault. Key pages, from the case's dashboard (`Case.md`) or the **northstar** bookmarks group:

| Page | Use it to |
|---|---|
| **Results/** | Read each tool's output as tables. Write what you checked in **Analyst notes** at the bottom, and set `relevance`, `reviewed` or `nil_return` in the properties. Your text is kept when the note is rebuilt |
| **Selectors.md** | Every identifier found, how many tools saw it and when, and the searches that would take it further (✓ = already run). This is your pivot list |
| **Accounts.md** | Account hits merged across tools. Two tools agreeing is still **unverified** |
| **Link chart.canvas** | People, accounts and identifiers seen by two or more tools, connected. Drag, add and annotate: once you edit it, northstar stops overwriting it |
| **Chronology.md** | The timeline from Event notes, findings, the missing-person timeline and timed places, oldest first, with the kind of each time (camera clock, platform, analyst, witness) |
| **People/, Places/, Organisations/, Events/** | Your working notes. Create them from Notes → **New note: …** |

Things to keep in mind:

- **Times:** northstar writes everything in UTC (properties ending `_utc`). Write event and finding times in UTC too, and note what kind of time it is: a camera clock can be wrong, and a platform shows its own time zone.
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
| `exhibits` | The exhibit IDs (`…-EX-001`). The report re-checks each one's fingerprint |
| `when_utc` | When it happened, if it has a time. It joins the chronology |
| `source_grade` | How reliable the **source** is: A always · B usually · C fairly · D not usually · E unreliable · F can't be judged |
| `info_grade` | How credible **this information** is: 1 confirmed elsewhere · 2 probably true · 3 possibly true · 4 doubtful · 5 improbable · 6 can't be judged |
| `status` | `lead` → `corroborated` (two independent sources) → `confirmed` |
| `reportable` | `true` once it's corroborated or confirmed and belongs in the report |

**Grading examples:**
- An official police appeal page stating the last-seen time: **A1**.
- The subject's verified Instagram account posting a photo with a recognisable landmark, matched to street-level imagery: **B2**.
- A single username hit on a site you couldn't open: **F6**. It's a lead, not a finding.

Don't grade everything B2: the grade should say something. A single unverified source is rarely better than C3.

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

The review is written to the contemporaneous notes with a fingerprint of the findings as they stood. **If you change a reportable finding afterwards, the report warns you that findings changed since the review,** so make the changes and record a new review.

---

## 9. Build the report

Main menu → **Case** → **Build a report (Word document)**.

If anything doesn't hold up, northstar lists **warnings** first and asks whether to build anyway. Fix them instead, unless you have a reason you'll write down:

| Warning | Fix |
|---|---|
| A reportable finding has no sealed evidence | Record the result folder as an exhibit (step 5) and add the ID to the finding's `exhibits` |
| Missing grades | Fill in `source_grade` and `info_grade` |
| An exhibit or file no longer matches | Something changed after sealing. Find out why, and write a note. Don't re-seal over it |
| Findings changed since the review / no review | Record a review (step 8) |
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
2. **Evidence & exhibits** → **Export the case (archive + SHA-256)**: a `.tar.gz` of the whole case in `~/Northstar/Exports/`, readable only by you, with a `.sha256` beside it.
3. Submit `report.docx` with `hashes.sha256` (and the export, if the recipient needs the evidence) through your organisation's approved channel, and send the SHA-256 values separately so they can check what they received.
4. If someone else takes over, give them **Handover.md**: intake and lawful basis, integrity, findings and report status, the last review, open leads and owners, next steps and decisions.
5. Case → **Close this case (verify, export, mark closed)**. Nothing is deleted, and scheduled page checks skip closed cases. Delete the working copy when your retention date allows, and revert the VM to its clean snapshot.

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
