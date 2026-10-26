# Evidence and exhibits

northstar records how every result was produced and lets you prove later that nothing has changed. None of this replaces your organisation's evidence procedures, but it gives you the raw material: hashes, times, tool versions and a tamper-evident log.

## What happens automatically

**Every result folder is sealed when a search finishes.** Two files are added:

| File | Contents |
|---|---|
| `manifest.sha256` | A SHA-256 hash of every file in the folder, in the standard `sha256sum` format |
| `provenance.json` | When it was sealed (UTC), the operator account, the machine, the northstar version, the version of each tool that ran, and the query |

The SHA-256 of `manifest.sha256` itself is the folder's **fingerprint**: one value that stands for the whole folder. It's written to the case's audit log as the folder is sealed.

Anyone can check a folder without northstar:

```bash
cd ~/Northstar/Cases/<case>/<kind>/<folder>
sha256sum -c manifest.sha256          # macOS: shasum -a 256 -c manifest.sha256
```

**`audit.log` is tamper-evident.** Each line holds the UTC time, case, tool, target, detail and operator, and ends with a hash covering the previous line plus its own fields. Editing, inserting or deleting any line breaks the chain from that point on. Lines written before v0.10 have no hash; they're reported as "unchained", not as broken.

## ns-evidence (Evidence & exhibits)

| Option | What it does |
|---|---|
| Record a result folder as an exhibit | Checks the folder against its manifest, asks for a short description, and adds a row to the case's `exhibits.csv`: exhibit ID (`CASE-EX-001`, …), UTC time, folder, description, fingerprint, file count, size, operator. Optionally adds an OpenTimestamps proof |
| Verify a folder | Reports every file as intact, changed or missing, plus files added since sealing |
| Verify the audit log's hash chain | Reports intact, broken and unchained lines, and where the chain breaks |
| List exhibits | Shows `exhibits.csv` |
| Export the case | Archives the whole case folder to `~/Northstar/Exports/<case>_<UTC time>.tar.gz` (readable only by you) with a `.sha256` beside it, ready to hand over |

### OpenTimestamps (optional)

Recording an exhibit can also create `manifest.sha256.ots`: a proof, anchored in the Bitcoin blockchain, that the manifest existed at that time. It doesn't depend on your computer's clock. Only the manifest's **hash** is sent to the public timestamp servers, never the files.

- The proof completes after a few hours. Run `ots upgrade manifest.sha256.ots` in the folder later to make it self-contained.
- To verify it, open [opentimestamps.org](https://opentimestamps.org) and drop in `manifest.sha256` and its `.ots` file. Verifying it locally needs a Bitcoin node, which northstar doesn't install.

## Good practice

- **Seal before you analyse.** Record important captures as exhibits straight away, then work on copies.
- **Keep times in UTC** in your notes as well. northstar logs in UTC, so they'll line up.
- **Check the chain before handing a case over:** Verify the audit log's hash chain, then Export the case and give the recipient the `.sha256`.
- **Case data is private.** Case folders are readable only by your account; keep it that way when you copy them elsewhere.
