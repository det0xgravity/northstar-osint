# Missing persons and Trace Labs-style CTFs

northstar's **Missing person** menu (`ns-missing`) supports missing-person casework and OSINT search-party events such as Trace Labs Search Party. Everything goes into the active case under `subject/`.

## Ground rules

- **Passive only.** Never contact the subject, family, friends or employers, and never interact with their accounts (no follows, likes, messages or friend requests). Search-party rules require this, and real cases depend on it.
- **Work through the right channel.** In a real case, findings go to the police or the organisation running the search, not to the public or the family.
- **Treat everything as sensitive.** Missing people are often vulnerable. Keep case data inside the VM and share it only with the case owner.

## The workflow

1. **Open a case** (main menu → Case → Open or switch case) and record the intake details.
2. **Subject profile:** name, aliases, date of birth or age, **last seen (UTC) and where**, description, known usernames, emails, phones and vehicles. Add the official photos (copied with their SHA-256).
3. **Search:** start with **Missing-persons databases** (it picks a country, or International, and opens NamUs, NCMEC, the Charley Project, Missing People, the UK Missing Persons Unit, Canada's Missing, NMPCC, NZ Police, INTERPOL Yellow Notices and others with the subject's name pre-filled), then Username & email, Country search, Photo geolocation, Face comparison (within the case), Media download and Capture web pages. Everything you collect lands in the case.
   - **Page monitoring** watches the subject's public profiles and channels for new activity (proof of life), with scheduled checks and a snapshot and diff of every change.
   - **Case map** puts the last-seen place, sightings, photo GPS and geolocation estimates on one map, with KML and GeoJSON for Google Earth or QGIS.
   - **Translate (offline)** translates posts, captions and transcripts without sending them anywhere.
4. **Log findings as you go** (**Log a finding**): category, URL, what it shows and why it matters, and optionally a screenshot or file, copied in with its SHA-256. Logging the same URL twice gives a warning. Put a date (YYYY-MM-DD) in the explanation and the finding also joins the timeline.
5. **Build the timeline:** dated events from your own entries, the last-seen moment, dated findings, posts in downloaded media (yt-dlp and gallery-dl metadata) and photo capture times (EXIF). Each event is placed relative to the last-seen moment (`+2.5 days`), and everything after it, which "advances the timeline", is highlighted. It's saved as `timeline.csv` and `timeline.html`.
6. **Export findings:** `findings.md`, grouped by category, plus `findings.csv`, ready to transcribe into the event platform or hand over.

## Categories

The finding categories come from `config/ctf-categories.txt`, one per line. The defaults follow the categories Trace Labs events have commonly used. **Check the current Contestant Guide** at [tracelabs.org/searchparty](https://tracelabs.org/searchparty) before an event, and edit the file to match.

## Files

| File | Contents |
|---|---|
| `subject/subject.json`, `subject.md` | The profile |
| `subject/photos/`, `photos/hashes.sha256` | Subject photos and their hashes |
| `subject/events.csv` | Events you added |
| `subject/findings.csv`, `findings.md` | Findings, with evidence file names and hashes |
| `subject/evidence/` | Evidence files attached to findings |
| `subject/timeline.csv`, `timeline.html` | The built timeline |
