#!/usr/bin/env python3
"""Missing-person casework for northstar-osint (the engine behind ns-missing).

Everything lives in the case folder under subject/:
  subject.json, subject.md   the subject profile
  events.csv                 timeline events you add
  findings.csv               findings (CTF flags) with category, URL, evidence hash
  timeline.csv/.html         built timeline

Commands:
  profile-set CASEDIR         profile answers as JSON on stdin
  profile-get CASEDIR FIELD   one profile value (for pre-filling dialogs)
  profile-show CASEDIR
  event-add CASEDIR WHEN DESCRIPTION SOURCE
  timeline CASEDIR            gather dated events and write timeline.csv + .html
  finding-add CASEDIR CATEGORY URL EXPLANATION [EVIDENCE_FILE]
  findings-export CASEDIR     findings grouped by category, as Markdown
"""
import csv
import datetime
import getpass
import glob
import hashlib
import html
import json
import os
import re
import shutil
import subprocess
import sys

FIELDS = [("name", "Full name"), ("aliases", "Aliases and nicknames"), ("dob", "Date of birth or age"),
          ("last_seen", "Last seen (UTC, YYYY-MM-DD HH:MM)"), ("last_seen_place", "Last seen where"),
          ("description", "Description (height, build, hair, eyes, marks, clothing)"),
          ("usernames", "Known usernames"), ("emails", "Known emails"), ("phones", "Known phone numbers"),
          ("vehicles", "Vehicles (make, model, colour, plate)"), ("notes", "Other context")]
IMAGE_EXT = (".jpg", ".jpeg", ".png", ".heic", ".tif", ".tiff", ".webp")


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sdir(case_dir):
    d = os.path.join(case_dir, "subject")
    os.makedirs(d, mode=0o700, exist_ok=True)
    return d


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for b in iter(lambda: fh.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def parse_when(text):
    """Best effort: many date formats → ISO 8601 UTC string, or None."""
    t = str(text).strip()
    if not t:
        return None
    if re.fullmatch(r"\d{10}(\.\d+)?", t):                                   # Unix timestamp
        return datetime.datetime.fromtimestamp(float(t), datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    if re.fullmatch(r"\d{8}", t):                                            # yt-dlp upload_date
        return f"{t[:4]}-{t[4:6]}-{t[6:]}T00:00:00Z"
    t = t.replace("/", "-")
    m = re.match(r"(\d{4})[-:](\d{2})[-:](\d{2})(?:[ T](\d{2}):(\d{2})(?::(\d{2}))?)?", t)
    if m:
        y, mo, d, h, mi, s = m.groups()
        return f"{y}-{mo}-{d}T{h or '00'}:{mi or '00'}:{s or '00'}Z"
    return None


def cmd_profile_set(case_dir):
    d = sdir(case_dir)
    answers = json.load(sys.stdin)
    path = os.path.join(d, "subject.json")
    data = json.load(open(path, encoding="utf-8")) if os.path.exists(path) else {"created_utc": utc_now()}
    data.update({k: str(answers.get(k, data.get(k, ""))).strip() for k, _ in FIELDS})
    data["updated_utc"] = utc_now()
    json.dump(data, open(path, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    lines = [f"# Subject: {data.get('name') or 'unnamed'}", ""]
    lines += [f"**{label}:** {data.get(k) or '—'}  " for k, label in FIELDS]
    open(os.path.join(d, "subject.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("Profile saved.")
    return 0


def profile(case_dir):
    p = os.path.join(case_dir, "subject", "subject.json")
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else {}


def cmd_profile_get(case_dir, field):
    print(profile(case_dir).get(field, ""))
    return 0


def cmd_profile_show(case_dir):
    p = profile(case_dir)
    if not p:
        print("No subject profile yet.")
        return 0
    for k, label in FIELDS:
        print(f"{label}: {p.get(k) or '—'}")
    photos = glob.glob(os.path.join(case_dir, "subject", "photos", "*"))
    print(f"Photos: {len(photos)}")
    return 0


def cmd_event_add(case_dir, when, description, source):
    iso = parse_when(when)
    if not iso:
        print("Couldn't read that date: use YYYY-MM-DD or YYYY-MM-DD HH:MM (UTC).")
        return 1
    path = os.path.join(sdir(case_dir), "events.csv")
    new = not os.path.exists(path)
    with open(path, "a", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        if new:
            w.writerow(["when_utc", "description", "source", "added_utc", "operator"])
        w.writerow([iso, description, source, utc_now(), getpass.getuser()])
    print(f"Event added: {iso} {description}")
    return 0


def gather(case_dir):
    """Dated events from everything in the case."""
    ev = []
    p = profile(case_dir)
    ls = parse_when(p.get("last_seen", ""))
    if ls:
        ev.append((ls, "LAST SEEN" + (f" at {p['last_seen_place']}" if p.get("last_seen_place") else ""),
                   "subject profile", "profile"))
    path = os.path.join(case_dir, "subject", "events.csv")
    if os.path.exists(path):
        for r in csv.DictReader(open(path, encoding="utf-8", newline="")):
            ev.append((r["when_utc"], r["description"], r["source"], "your event"))
    path = os.path.join(case_dir, "subject", "findings.csv")
    if os.path.exists(path):
        for r in csv.DictReader(open(path, encoding="utf-8", newline="")):
            if r.get("when_utc"):
                ev.append((r["when_utc"], f"[{r['category']}] {r['explanation']}", r["url"], "finding"))
    # Downloaded media metadata: yt-dlp info.json and gallery-dl json
    for meta in glob.glob(os.path.join(case_dir, "**", "*.json"), recursive=True):
        if meta.endswith(("manifest.json", "provenance.json", "subject.json", "case.json")) or os.sep + "subject" + os.sep in meta:
            continue
        try:
            j = json.load(open(meta, encoding="utf-8"))
        except (ValueError, OSError, UnicodeDecodeError):
            continue
        if not isinstance(j, dict):
            continue
        when = parse_when(j.get("timestamp") or j.get("upload_date") or j.get("date") or "")
        if when and (j.get("title") or j.get("description") or j.get("content")):
            what = (j.get("title") or j.get("content") or j.get("description") or "")[:140].replace("\n", " ")
            author = j.get("author")
            who = j.get("uploader") or j.get("username") or (author.get("name") if isinstance(author, dict) else author) or ""
            ev.append((when, f"Post by {who}: {what}" if who else f"Post: {what}",
                       j.get("webpage_url") or j.get("url") or os.path.relpath(meta, case_dir), "media metadata"))
    # Photo capture times (camera clock) via exiftool
    if shutil.which("exiftool"):
        try:
            out = subprocess.run(["exiftool", "-r", "-json", "-n", "-DateTimeOriginal", "-GPSLatitude",
                                  "-GPSLongitude", "-ext", "jpg", "-ext", "jpeg", "-ext", "heic", "-ext", "png",
                                  "-ext", "tif", case_dir], capture_output=True, text=True, timeout=300).stdout
            for j in json.loads(out or "[]"):
                when = parse_when(j.get("DateTimeOriginal", ""))
                if when:
                    gps = f" (GPS {j['GPSLatitude']:.5f}, {j['GPSLongitude']:.5f})" if "GPSLatitude" in j and "GPSLongitude" in j else ""
                    ev.append((when, f"Photo taken (camera clock){gps}", os.path.relpath(j["SourceFile"], case_dir), "photo EXIF"))
        except (subprocess.SubprocessError, ValueError, OSError):
            pass
    return sorted(set(ev)), ls


def cmd_timeline(case_dir):
    ev, ls = gather(case_dir)
    d = sdir(case_dir)
    base = datetime.datetime.fromisoformat(ls.replace("Z", "+00:00")) if ls else None
    rows = []
    for when, what, src, kind in ev:
        rel = ""
        if base:
            delta = datetime.datetime.fromisoformat(when.replace("Z", "+00:00")) - base
            hours = delta.total_seconds() / 3600
            rel = "last seen" if abs(hours) < 0.01 else (f"+{hours / 24:.1f} days" if hours > 0 else f"{hours / 24:.1f} days")
        rows.append({"when_utc": when, "relative_to_last_seen": rel, "event": what, "source": src, "kind": kind})
    with open(os.path.join(d, "timeline.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["when_utc", "relative_to_last_seen", "event", "source", "kind"])
        w.writeheader()
        w.writerows(rows)
    trs = "".join(
        f'<tr class="{"after" if r["relative_to_last_seen"].startswith("+") else ("ls" if r["relative_to_last_seen"] == "last seen" else "")}">'
        f'<td>{html.escape(r["when_utc"])}</td><td>{html.escape(r["relative_to_last_seen"])}</td>'
        f'<td>{html.escape(r["event"])}</td><td>{html.escape(r["kind"])}</td><td>{html.escape(r["source"])}</td></tr>'
        for r in rows)
    page = f"""<!doctype html><meta charset="utf-8"><title>Timeline</title>
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'">
<style>body{{font:14px system-ui;margin:16px}} table{{border-collapse:collapse;width:100%}}
td,th{{border-bottom:1px solid #ccc;padding:4px 8px;text-align:left;vertical-align:top}}
tr.ls{{background:#ffe08a;font-weight:bold}} tr.after{{background:#e7f5ff}}</style>
<h1>Timeline: {html.escape(profile(case_dir).get("name") or os.path.basename(os.path.abspath(case_dir)))}</h1>
<p>UTC. Highlighted: the last-seen moment, and everything after it (advancing the timeline). Photo times come
from camera clocks, which can be wrong.</p>
<table><tr><th>When (UTC)</th><th>From last seen</th><th>Event</th><th>Kind</th><th>Source</th></tr>{trs}</table>"""
    open(os.path.join(d, "timeline.html"), "w", encoding="utf-8").write(page)
    after = sum(1 for r in rows if r["relative_to_last_seen"].startswith("+"))
    print(f"{len(rows)} dated events ({after} after the last-seen moment). Saved subject/timeline.csv and timeline.html")
    return 0


def cmd_finding_add(case_dir, category, url, explanation, evidence=""):
    d = sdir(case_dir)
    path = os.path.join(d, "findings.csv")
    rows = list(csv.DictReader(open(path, encoding="utf-8", newline=""))) if os.path.exists(path) else []
    norm = url.strip().rstrip("/").lower()
    dupes = [r["id"] for r in rows if r["url"].strip().rstrip("/").lower() == norm and norm]
    ev_name = ev_hash = ""
    if evidence and os.path.isfile(evidence):
        os.makedirs(os.path.join(d, "evidence"), mode=0o700, exist_ok=True)
        ev_name = f"F{len(rows) + 1:03d}_{os.path.basename(evidence)}"
        shutil.copy2(evidence, os.path.join(d, "evidence", ev_name))
        ev_hash = sha256(os.path.join(d, "evidence", ev_name))
    row = {"id": f"F{len(rows) + 1:03d}", "logged_utc": utc_now(), "category": category, "url": url.strip(),
           "explanation": " ".join(explanation.split()), "when_utc": "", "evidence": ev_name,
           "evidence_sha256": ev_hash, "operator": getpass.getuser()}
    m = re.search(r"\b(\d{4}-\d{2}-\d{2}(?:[ T]\d{2}:\d{2})?)\b", explanation)
    if m:
        row["when_utc"] = parse_when(m.group(1)) or ""
    with open(path, "a", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(row))
        if not rows:
            w.writeheader()
        w.writerow(row)
    print(f"{row['id']} logged ({category})." + (f" WARNING: same URL already logged as {', '.join(dupes)}." if dupes else ""))
    return 0


def cmd_findings_export(case_dir):
    path = os.path.join(case_dir, "subject", "findings.csv")
    if not os.path.exists(path):
        print("No findings yet.")
        return 0
    rows = list(csv.DictReader(open(path, encoding="utf-8", newline="")))
    out = [f"# Findings: {profile(case_dir).get('name') or os.path.basename(os.path.abspath(case_dir))}",
           f"\n{len(rows)} findings, exported {utc_now()}\n"]
    for cat in sorted({r["category"] for r in rows}):
        sub = [r for r in rows if r["category"] == cat]
        out.append(f"\n## {cat} ({len(sub)})\n")
        for r in sub:
            ev = f" Evidence: {r['evidence']} (SHA-256 {r['evidence_sha256'][:16]}…)" if r["evidence"] else ""
            out.append(f"- **{r['id']}** {r['url']}\n  {r['explanation']}{ev}")
    dest = os.path.join(case_dir, "subject", "findings.md")
    open(dest, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print(f"Exported {len(rows)} findings to subject/findings.md (and findings.csv)")
    for cat in sorted({r["category"] for r in rows}):
        print(f"  {cat}: {sum(1 for r in rows if r['category'] == cat)}")
    return 0


def main(argv):
    cmds = {"profile-set": (cmd_profile_set, 1, 1), "profile-get": (cmd_profile_get, 2, 2),
            "profile-show": (cmd_profile_show, 1, 1), "event-add": (cmd_event_add, 4, 4),
            "timeline": (cmd_timeline, 1, 1), "finding-add": (cmd_finding_add, 4, 5),
            "findings-export": (cmd_findings_export, 1, 1)}
    if len(argv) < 2 or argv[1] not in cmds or not cmds[argv[1]][1] <= len(argv) - 2 <= cmds[argv[1]][2]:
        print(__doc__)
        return 2
    return cmds[argv[1]][0](*argv[2:])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
