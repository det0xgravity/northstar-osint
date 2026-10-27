# Worked case examples

Two complete cases, worked through with northstar's menus from intake to report. They follow the stages in the [investigation guide](INVESTIGATION-GUIDE.md), which explains each menu in more detail.

> **Everything here is fictional.** The handles, accounts, names, companies and addresses are invented, and use "example" so they can't be mistaken for real ones. Emails use the reserved `example.com`/`example.net` domains; onion addresses are shortened placeholders (`exampleforum…onion`). **Don't search for any of them.** Places are real only where a real city is needed to show how geolocation works.

Both cases identify a person, so both start the same way: **no search before the intake is recorded**, and the lawful basis must cover identifying someone. Identification is a conclusion you reach from several independent pieces of evidence, graded and reviewed. No single tool hit, and no face score, ever identifies anyone on its own.

- [Case A: a dark-web vendor, from a username to a name](#case-a-a-dark-web-vendor-from-a-username-to-a-name)
- [Case B: one photo, to where it was taken and who is in it](#case-b-one-photo-to-where-it-was-taken-and-who-is-in-it)

---

## Case A: a dark-web vendor, from a username to a name

### The tasking

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
2. Do the same for the seller's public profile page, if the forum shows it without a login. If the forum asks for a login or a CAPTCHA, **stop**: northstar won't get around it, and you mustn't either. Note it.
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
   - an **infostealer** hit (Hudson Rock): a computer that used this email or username was infected with password-stealing malware. For a criminal, that's a frequent route to their real identity, but details beyond the summary come from the service, not from northstar, and must be handled under your legal basis.

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

Follow the guide from [step 8](INVESTIGATION-GUIDE.md#8-review): supervisor review, **Build a report**, read the whole report, verify, export and hand to the police through counsel. **Don't contact the seller or the person named**, and don't publish anything: that could tip them off or wreck a prosecution.

---

## Case B: one photo, to where it was taken and who is in it

### The tasking

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

Don't run face-search engines that scan the internet for a face: northstar doesn't include any, and running a private person's face through one raises serious legal problems in many places (biometric data under the GDPR, for example). **Face comparison** isn't needed here either: identical photos already prove where they came from, so comparing faces would be processing biometric data for nothing. Further searches on the man (other platforms, his business, his home) are outside the scope.

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

As in the guide, from [step 8](INVESTIGATION-GUIDE.md#8-review). The report goes to the solicitor for the police report. **Nobody contacts the pictured man** unless the police decide to; if anyone does, it's to tell him his photos are being misused.

---

## What both cases have in common

- **Intake first.** Identifying someone needs a purpose and lawful basis that cover it, and the scope says how far to go.
- **Capture, then exhibit, then analyse.** Pages change: seal what you'll rely on as soon as you see it.
- **Pivot on stable identifiers** (PGP key fingerprints, platform IDs, original photos), not on display names or common words.
- **Two independent sources** before a finding is corroborated. Tools that check the same site aren't independent, and neither is a fact derived from another (an email taken from a key's user ID doesn't confirm the key).
- **Control, not display:** a public key, a photo or a handle can be copied. A verified signature or the original upload is stronger.
- **Write the alternatives down**, and discount what fails, with the reason.
- **Measured conclusions:** *probably* and *consistent with* until something confirms it, and "not identified" when that's the truth.
- **Never contact or confront** anyone, and hand identification to the people with legal powers to confirm it.
