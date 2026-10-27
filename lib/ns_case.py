#!/usr/bin/env python3
"""Case records for northstar-osint (the engine behind ns-case; installed as
`ns_casework`, since `ns_case` is a function in lib/ui.sh).

Commands:
  init CASEDIR            read intake answers as JSON on stdin; write case.json + scope.md
  amend CASEDIR           read changed intake answers as JSON on stdin; each change is written to
                          case.json and scope.md, and recorded in the notes (old and new value)
  show CASEDIR            print the case details
  status CASEDIR          print the case status (open, closed; none without case details)
  note CASEDIR TEXT       append a timestamped, hash-chained note to notes.md (not on a closed case)
  notes-verify CASEDIR    check the notes' hash chain
  report CASEDIR OUTFILE [SECTIONS]
                          write a Markdown report (ns-case converts it with pandoc); SECTIONS
                          is the findings part built from the Obsidian vault (ns_vault report-sections)
  close CASEDIR           mark the case closed in case.json
  reopen CASEDIR REASON   mark a closed case open again; the reason goes in the notes
  nsfw CASEDIR            print "on" if adult-site searches are allowed in this case, else "off"
  nsfw-set CASEDIR on|off REASON
                          allow or stop adult-site (NSFW) searches; the decision and reason go in the notes

Notes chain: every note line ends with `h:<sha256>`, the hash of the previous
note's hash plus this note's time, operator and text, so an edited, inserted or
removed note breaks the chain from that point on.
"""
import csv
import datetime
import getpass
import hashlib
import json
import os
import re
import sys
from collections import Counter

FIELDS = [("reference", "Client / matter reference"), ("authorised_by", "Authorised by"),
          ("purpose", "Purpose and lawful basis"), ("scope", "Scope and subjects"),
          ("review_date", "Review / retention date")]
NOTE = re.compile(r"^- \*\*(?P<t>[0-9TZ:-]+)\*\* \((?P<op>[^)]*)\): (?P<text>.*) `h:(?P<h>[0-9a-f]{64})`$")


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load(case_dir):
    p = os.path.join(case_dir, "case.json")
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else {}


def save(case_dir, data):
    with open(os.path.join(case_dir, "case.json"), "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)


def write_scope(case_dir, data):
    lines = [f"# Case {data['case']}", "", f"Opened {data['opened_utc']} by {data['opened_by']}", ""]
    lines += [f"**{label}:** {data.get(k) or '—'}" for k, label in FIELDS]
    for a in data.get("amendments", []):
        lines.append(f"Amended {a['utc']} by {a['by']}: {a['field']}")
    open(os.path.join(case_dir, "scope.md"), "w", encoding="utf-8").write("\n\n".join(lines) + "\n")


def cmd_init(case_dir):
    if os.path.exists(os.path.join(case_dir, "case.json")):
        print("This case already has its details; they weren't changed.")
        return 1
    answers = json.load(sys.stdin)
    data = {"case": os.path.basename(os.path.abspath(case_dir)), "opened_utc": utc_now(),
            "opened_by": getpass.getuser(), "status": "open"}
    data.update({k: str(answers.get(k, "")).strip() for k, _ in FIELDS})
    save(case_dir, data)
    write_scope(case_dir, data)
    print(f"Case {data['case']} opened.")
    return 0


def first_record(case_dir):
    """UTC time of the case's earliest audit-log line or note."""
    times = []
    try:
        with open(os.path.join(case_dir, "audit.log"), encoding="utf-8", errors="replace") as fh:
            t = fh.readline().split("\t", 1)[0]
            if re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", t):
                times.append(t)
    except OSError:
        pass
    p = os.path.join(case_dir, "notes.md")
    if os.path.exists(p):
        for line in open(p, encoding="utf-8"):
            m = NOTE.match(line.rstrip("\n"))
            if m:
                times.append(m.group("t"))
                break
    return min(times) if times else ""


def cmd_status(case_dir):
    print(load(case_dir).get("status", "none") if load(case_dir) else "none")
    return 0


def cmd_amend(case_dir):
    """Change intake details. A case without them gets them now, recorded as late."""
    answers = json.load(sys.stdin)
    d = load(case_dir)
    late = not d
    if late:                                   # opened when its first record was written, not now
        d = {"case": os.path.basename(os.path.abspath(case_dir)), "opened_utc": first_record(case_dir) or utc_now(),
             "opened_by": getpass.getuser(), "status": "open", "intake_recorded_utc": utc_now()}
    if d.get("status") == "closed":
        print("This case is closed: reopen it first.", file=sys.stderr)
        return 3
    changes = []
    for k, label in FIELDS:
        new = " ".join(str(answers.get(k, d.get(k, ""))).split())
        old = d.get(k, "")
        if new != " ".join(str(old).split()):
            changes.append((k, label, old, new))
            d[k] = new
    if not changes:
        print("No changes.")
        return 0
    t, op = utc_now(), getpass.getuser()
    d.setdefault("amendments", [])
    for k, label, old, new in changes:
        d["amendments"].append({"utc": t, "by": op, "field": k, "old": old, "new": new})
    save(case_dir, d)
    write_scope(case_dir, d)
    for k, label, old, new in changes:
        cmd_note(case_dir, (f"INTAKE RECORDED LATE: {label}: {new or '(empty)'}" if late else
                            f"INTAKE AMENDED: {label}: \"{old or '(empty)'}\" changed to \"{new or '(empty)'}\""))
    print(f"{len(changes)} intake detail(s) {'recorded' if late else 'amended'}; each change is in the notes.")
    return 0

def cmd_show(case_dir):
    d = load(case_dir)
    if not d:
        print("No case details recorded (cases created before v0.14 have none).")
        return 0
    print(f"Case {d.get('case')} — {d.get('status', 'open')}, opened {d.get('opened_utc')} by {d.get('opened_by')}")
    for k, label in FIELDS:
        print(f"{label}: {d.get(k) or '—'}")
    if d.get("status") == "closed" and d.get("closed_utc"):
        print(f"Closed: {d['closed_utc']}")
    for a in d.get("amendments", [])[-5:]:
        print(f"Amended {a['utc']}: {dict(FIELDS).get(a['field'], a['field'])}")
    return 0


def last_note_hash(path):
    h = ""
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            m = NOTE.match(line.rstrip("\n"))
            if m:
                h = m.group("h")
    return h


def cmd_note(case_dir, text):
    path = os.path.join(case_dir, "notes.md")
    text = " ".join(text.split())
    if not text:
        return 1
    if load(case_dir).get("status") == "closed":
        print("This case is closed: reopen it (Case → Reopen this case) before adding notes.", file=sys.stderr)
        return 3
    t, op = utc_now(), getpass.getuser()
    h = hashlib.sha256(f"{last_note_hash(path)}|{t}|{op}|{text}".encode("utf-8")).hexdigest()
    new = not os.path.exists(path)
    if not new:
        os.chmod(path, 0o600)                  # read-only between notes, so it can't be edited by accident
    with open(path, "a", encoding="utf-8") as fh:
        if new:
            fh.write(f"# Notes: case {os.path.basename(os.path.abspath(case_dir))}\n\n"
                     "Contemporaneous notes, newest last. Times are UTC. Each line's `h:` value chains it to the one before.\n\n")
        fh.write(f"- **{t}** ({op}): {text} `h:{h}`\n")
    os.chmod(path, 0o400)
    print(f"Note saved ({t}).")
    return 0


def cmd_notes_verify(case_dir):
    path = os.path.join(case_dir, "notes.md")
    if not os.path.exists(path):
        print("No notes yet.")
        return 0
    prev, ok, bad = "", 0, []
    for n, line in enumerate(open(path, encoding="utf-8"), 1):
        m = NOTE.match(line.rstrip("\n"))
        if not m:
            continue
        want = hashlib.sha256(f"{prev}|{m.group('t')}|{m.group('op')}|{m.group('text')}".encode("utf-8")).hexdigest()
        if want == m.group("h"):
            ok += 1
        else:
            bad.append(n)
        prev = m.group("h")
    print(f"{ok} notes intact, {len(bad)} BROKEN")
    for n in bad[:20]:
        print(f"  chain broken at line {n}")
    return 1 if bad else 0


def md_escape(s):
    return str(s).replace("|", "\\|").replace("\n", " ")


def cmd_report(case_dir, out, sections=""):
    d = load(case_dir)
    case = d.get("case") or os.path.basename(os.path.abspath(case_dir))
    audit = []
    ap = os.path.join(case_dir, "audit.log")
    if os.path.exists(ap):
        for line in open(ap, encoding="utf-8", errors="replace"):
            f = line.rstrip("\n").split("\t")
            if len(f) >= 5:
                audit.append(f)
    tools = Counter(f[2] for f in audit)
    times = [f[0] for f in audit]
    r = [f"---\ntitle: \"Investigation report: {case}\"\ndate: \"{utc_now()[:10]}\"\n---", "",
         "## Case details", ""]
    r += [f"- **{label}:** {md_escape(d.get(k) or '—')}" for k, label in FIELDS]
    r += [f"- **Opened:** {d.get('opened_utc', '—')} by {d.get('opened_by', '—')}",
          f"- **Status:** {d.get('status', '—')}" + (f", closed {d['closed_utc']}" if d.get("status") == "closed" and d.get("closed_utc") else ""), ""]
    if sections and os.path.exists(sections):
        r += [open(sections, encoding="utf-8").read().rstrip(), ""]
    else:
        r += ["## Summary", "", "*Write the findings here.*", ""]
    r += ["## Methodology", "",
          f"Open-source research recorded in a hash-chained audit log: {len(audit)} actions"
          + (f" between {min(times)} and {max(times)}" if times else "") + ". Tools and sources used:", ""]
    r += [f"- {md_escape(t)} ({n}×)" for t, n in tools.most_common()] or ["- none recorded"]
    r += ["", "Every result folder holds a `manifest.sha256` (SHA-256 of each file) and `provenance.json` "
          "(time, operator, tool versions); the fingerprint of a folder is the SHA-256 of its manifest.", ""]
    r += ["## Exhibits", ""]
    ep = os.path.join(case_dir, "exhibits.csv")
    if os.path.exists(ep):
        rows = list(csv.DictReader(open(ep, encoding="utf-8", newline="")))
        r += ["| Exhibit | Recorded (UTC) | Description | Fingerprint (SHA-256) |", "|---|---|---|---|"]
        r += [f"| {md_escape(x['exhibit_id'])} | {md_escape(x['recorded_utc'])} | {md_escape(x['description'])} | "
              f"`{x['manifest_sha256']}` |" for x in rows]
    else:
        r += ["No exhibits recorded."]
    r += ["", "## Notes", ""]
    npth = os.path.join(case_dir, "notes.md")
    notes = [m for m in (NOTE.match(l.rstrip("\n")) for l in open(npth, encoding="utf-8")) if m] if os.path.exists(npth) else []
    r += [f"- **{m.group('t')}** ({m.group('op')}): {m.group('text')}" for m in notes] or ["No notes recorded."]
    r += ["", "## Appendix: audit log", "", "| Time | Tool | Target | Detail |", "|---|---|---|---|"]
    r += [f"| {md_escape(f[0])} | {md_escape(f[2])} | {md_escape(f[3])[:80]} | {md_escape(f[4])[:120]} |" for f in audit]
    with open(out, "w", encoding="utf-8") as fh:
        fh.write("\n".join(r) + "\n")
    print(f"Report source written: {out}")
    return 0


def cmd_close(case_dir):
    d = load(case_dir) or {"case": os.path.basename(os.path.abspath(case_dir))}
    d["status"], d["closed_utc"], d["closed_by"] = "closed", utc_now(), getpass.getuser()
    save(case_dir, d)
    print(f"Case {d['case']} marked closed at {d['closed_utc']}.")
    return 0


def cmd_reopen(case_dir, reason):
    d = load(case_dir)
    if d.get("status") != "closed":
        print("This case isn't closed.")
        return 1
    if not reason.strip():
        print("A reason is needed.", file=sys.stderr)
        return 1
    d["status"] = "open"
    d.setdefault("reopened", []).append({"utc": utc_now(), "by": getpass.getuser(), "reason": " ".join(reason.split())})
    save(case_dir, d)
    cmd_note(case_dir, f"CASE REOPENED (closed {d.get('closed_utc', '?')}): {reason}")
    print(f"Case {d.get('case')} reopened.")
    return 0


def cmd_nsfw(case_dir):
    print("on" if (load(case_dir).get("nsfw") or {}).get("allowed") else "off")
    return 0


def cmd_nsfw_set(case_dir, state, reason):
    d = load(case_dir)
    if not d:
        print("Record the case's intake details first (Case → Edit case details).", file=sys.stderr)
        return 1
    if d.get("status") == "closed":
        print("This case is closed: reopen it first.", file=sys.stderr)
        return 3
    reason = " ".join(reason.split())
    if state not in ("on", "off") or (state == "on" and not reason):
        print("Give on or off, and a reason to allow them.", file=sys.stderr)
        return 1
    d["nsfw"] = {"allowed": state == "on", "reason": reason, "utc": utc_now(), "by": getpass.getuser()}
    save(case_dir, d)
    cmd_note(case_dir, f"DECISION: adult-site (NSFW) searches ALLOWED in this case. Reason: {reason}" if state == "on"
             else f"DECISION: adult-site (NSFW) searches STOPPED in this case.{' Reason: ' + reason if reason else ''}")
    print(f"Adult-site searches {'allowed' if state == 'on' else 'stopped'} in this case.")
    return 0


def main(argv):
    cmds = {"init": (cmd_init, 1), "amend": (cmd_amend, 1), "reopen": (cmd_reopen, 2),
            "nsfw": (cmd_nsfw, 1), "nsfw-set": (cmd_nsfw_set, 3),
            "show": (cmd_show, 1), "status": (cmd_status, 1), "note": (cmd_note, 2),
            "notes-verify": (cmd_notes_verify, 1), "report": (cmd_report, 2), "close": (cmd_close, 1)}
    extra = 1 if len(argv) > 1 and argv[1] == "report" else 0          # report takes an optional SECTIONS file
    if len(argv) < 2 or argv[1] not in cmds or not cmds[argv[1]][1] <= len(argv) - 2 <= cmds[argv[1]][1] + extra:
        print(__doc__)
        return 2
    return cmds[argv[1]][0](*argv[2:])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
