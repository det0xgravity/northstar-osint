# Evidence and exhibits

True Bearing records how every result was produced and lets you prove later that nothing has changed. None of this replaces your organisation's evidence procedures, but it gives you the raw material: hashes, times, tool versions and a tamper-evident log.

## What happens automatically

**Every result folder is sealed when a search finishes.** Two files are added:

| File | Contents |
|---|---|
| `manifest.sha256` | A SHA-256 hash of every file in the folder, in the standard `sha256sum` format |
| `provenance.json` | When it was sealed (UTC), the operator account, the machine, the True Bearing version, the version of each tool that ran, and the query |

The SHA-256 of `manifest.sha256` itself is the folder's **fingerprint**: one value that stands for the whole folder. It's written to the case's audit log as the folder is sealed.

Anyone can check a folder without True Bearing:

```bash
cd ~/TrueBearing/Cases/<case>/<kind>/<folder>
sha256sum -c manifest.sha256          # macOS: shasum -a 256 -c manifest.sha256
```

**`audit.log` is tamper-evident.** Each line holds the UTC time, case, tool, target, detail and operator, and ends with a hash covering the previous line plus its own fields. Editing, inserting or deleting any line breaks the chain from that point on. Lines written before v0.10 have no hash; they're reported as "unchained", not as broken.

## tb-evidence (Evidence & exhibits)

| Option | What it does |
|---|---|
| Record a result folder as an exhibit | Checks the folder against its manifest, asks for a short description, and adds a row to the case's `exhibits.csv`: exhibit ID (`CASE-EX-001`, …), UTC time, folder, description, fingerprint, file count, size, operator. Optionally adds an OpenTimestamps proof |
| Verify a folder | Reports every file as intact, changed or missing, plus files added since sealing |
| Verify the audit log's hash chain | Reports intact, broken and unchained lines, and where the chain breaks |
| List exhibits | Shows `exhibits.csv` |
| Export the case | Archives the whole case folder to `~/TrueBearing/Exports/<case>_<UTC time>.tar.gz` (readable only by you) with a `.sha256` beside it, ready to hand over |
| Check received or suspicious files (triage) | Looks at files **without opening or running them**: the real file type against its name (a program called `invoice.pdf`), SHA-256, a ClamAV scan for known malware, macros in Office documents (oletools), active content in PDFs (JavaScript, open actions, launch actions, embedded files), archive contents (listed, never extracted, with password-protected entries and path tricks flagged) and GPS in image metadata. Each file gets **DANGER**, **CAUTION** or **no warning signs**, which is never a guarantee. The report (`triage.txt`, `triage.json`) is sealed in the case |
| Export the case, encrypted (age or PGP) | The same archive, encrypted with [age](https://age-encryption.org) for a **passphrase** (typed in the terminal, never logged) or the **recipient's public key** (`age1…`, or their `ssh-ed25519`/`ssh-rsa` key), or with GnuPG for the **recipient's PGP public key** (choose their `.asc` or `.gpg` key file). For PGP, the key is read into a throwaway keyring that is deleted afterwards, never your own. You're shown its user ID and fingerprint to confirm: check the fingerprint with the recipient by phone or in person, not by the channel the key came from. Revoked, expired and sign-only keys are refused. You get `….tar.gz.age` (or `….tar.gz.gpg`) and its `.sha256`; the unencrypted archive is removed, and its own SHA-256 stays in `….tar.gz.sha256`, so after decrypting, the recipient can check they have exactly what was exported. The audit log records the method and the start of the key (a PGP key's full fingerprint), never a passphrase. Use this for anything that leaves the VM |

### OpenTimestamps (optional)

Recording an exhibit can also create `manifest.sha256.ots`: a proof, anchored in the Bitcoin blockchain, that the manifest existed at that time. It doesn't depend on your computer's clock. Only the manifest's **hash** is sent to the public timestamp servers, never the files.

- The proof completes after a few hours. Run `ots upgrade manifest.sha256.ots` in the folder later to make it self-contained.
- To verify it, open [opentimestamps.org](https://opentimestamps.org) and drop in `manifest.sha256` and its `.ots` file. Verifying it locally needs a Bitcoin node, which True Bearing doesn't install.

## Files from outside: OnionShare

**Dark web → OnionShare: receive files from a source into this case** saves what a source uploads into a result folder under `received/`, lists each file's SHA-256 in `received.txt`, checks every file (the triage above, in `triage.txt`) and seals the folder, so you can record it as an exhibit at once. The drop box's address and key are never written to the case. Received files are untrusted: open them only in the VM.

**OnionShare: send files over a private .onion link** can deliver an export when no approved channel exists. The audit log records each file sent with its SHA-256; give the recipient the `.sha256` separately so they can check it.

## Notes, reports and closing

Case notes (**Case → Add a note**) are chained the same way as the audit log, and **Case → Build a report** pulls the exhibit list, with each exhibit's fingerprint, into the report. A finding linked to a result that was recorded as an exhibit is checked against the exhibit register. See [MENUS.md](MENUS.md#tb-case).

**Case → Close this case** first lists anything unfinished: notes, audit log or exhibits that don't verify, no report or one built before the findings last changed, no review covering the current findings and summary, incomplete intake, open leads. Closing anyway records those points in the notes. A closed case takes no more notes until it's reopened, with a reason.

## Good practice

- **Seal before you analyse.** Record important captures as exhibits straight away, then work on copies.
- **Keep times in UTC** in your notes as well. True Bearing logs in UTC, so they'll line up.
- **Check the chain before handing a case over:** Verify the audit log's hash chain, then Export the case and give the recipient the `.sha256`.
- **Case data is private.** Case folders are readable only by your account; keep it that way when you copy them elsewhere.
