#!/usr/bin/env python3
"""Page monitoring for northstar-osint (the engine behind ns-watch).

Commands:
  add CASEDIR URL [LABEL]     start watching a page
  list CASEDIR
  remove CASEDIR ID
  check CASEDIR               check that case's pages now
  check-all DATADIR           check every open case (used by the timer)
  changes CASEDIR             the most recent changes

Each check fetches the page's visible text, compares it with the last snapshot
and, when it differs, keeps the new snapshot and a diff in CASEDIR/watch/, logs
it in changes.log and the case's hash-chained audit.log. Pages that need a
login or render entirely in JavaScript can't be watched this way; public
profile pages and t.me/s/<channel> previews work well.
"""
import datetime
import difflib
import getpass
import hashlib
import html
import json
import os
import re
import sys
import urllib.request

UA = "Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0"


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def wdir(case_dir):
    d = os.path.join(case_dir, "watch")
    os.makedirs(d, mode=0o700, exist_ok=True)
    return d


def load(case_dir):
    p = os.path.join(case_dir, "watch", "watches.json")
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else []


def save(case_dir, w):
    json.dump(w, open(os.path.join(wdir(case_dir), "watches.json"), "w", encoding="utf-8"), indent=2)


def audit(case_dir, tool, target, detail):
    """Same format and hash chain as ns_audit in lib/ui.sh."""
    log = os.path.join(case_dir, "audit.log")
    clean = lambda s: re.sub(r"[\t\r\n]", " ", str(s))
    body = "\t".join([utc_now(), os.path.basename(os.path.abspath(case_dir)), clean(tool), clean(target),
                      clean(detail), getpass.getuser()])
    prev = ""
    if os.path.exists(log) and os.path.getsize(log):
        with open(log, "rb") as fh:
            fh.seek(max(0, os.path.getsize(log) - 65536))
            prev = fh.read().decode("utf-8", "replace").rstrip("\n").split("\n")[-1]
    with open(log, "a", encoding="utf-8") as fh:
        fh.write(f"{body}\t{hashlib.sha256((prev + body).encode('utf-8')).hexdigest()}\n")


def page_text(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "en"})
    with urllib.request.urlopen(req, timeout=40) as resp:
        raw = resp.read(5 * 1024 * 1024).decode(resp.headers.get_content_charset() or "utf-8", "replace")
    raw = re.sub(r"(?is)<(script|style|noscript|svg)[^>]*>.*?</\1>", " ", raw)
    text = html.unescape(re.sub(r"<[^>]+>", "\n", raw))
    return "\n".join(l.strip() for l in text.splitlines() if l.strip())


def cmd_add(case_dir, url, label=""):
    if not re.match(r"^https?://", url):
        print("Use a full address starting with https://")
        return 1
    w = load(case_dir)
    if any(x["url"] == url for x in w):
        print("Already watching that page.")
        return 0
    wid = f"W{max([int(x['id'][1:]) for x in w] or [0]) + 1:03d}"
    w.append({"id": wid, "url": url, "label": label or url, "added_utc": utc_now(), "last_hash": "", "last_check": ""})
    save(case_dir, w)
    audit(case_dir, "ns-watch", url, f"watching as {wid}")
    print(f"{wid}: watching {url}. The first check records a baseline.")
    return 0


def cmd_list(case_dir):
    w = load(case_dir)
    for x in w:
        print(f"{x['id']}  {x['label']}  (last checked {x['last_check'] or 'never'})")
    if not w:
        print("No pages watched in this case.")
    return 0


def cmd_remove(case_dir, wid):
    w = load(case_dir)
    keep = [x for x in w if x["id"] != wid]
    save(case_dir, keep)
    audit(case_dir, "ns-watch", wid, "stopped watching")
    print("Removed." if len(keep) < len(w) else "No such watch.")
    return 0


def cmd_check(case_dir):
    w, changed = load(case_dir), 0
    for x in w:
        stamp = utc_now()
        try:
            text = page_text(x["url"])
        except Exception as exc:
            print(f"{x['id']} {x['label']}: couldn't fetch ({exc})")
            x["last_check"] = stamp
            continue
        h = hashlib.sha256(text.encode("utf-8")).hexdigest()
        snap_dir = os.path.join(wdir(case_dir), x["id"])
        os.makedirs(snap_dir, mode=0o700, exist_ok=True)
        fname, n = stamp.replace(":", ""), 1
        while os.path.exists(os.path.join(snap_dir, f"{fname}.txt")):    # two checks in one second
            fname, n = f"{stamp.replace(':', '')}-{n}", n + 1
        if not x["last_hash"]:
            open(os.path.join(snap_dir, f"{fname}.txt"), "w", encoding="utf-8").write(text)
            print(f"{x['id']} {x['label']}: baseline recorded")
            audit(case_dir, "ns-watch", x["url"], f"baseline {h[:16]}")
        elif h != x["last_hash"]:
            changed += 1
            prev_files = sorted(f for f in os.listdir(snap_dir) if f.endswith(".txt"))
            old = open(os.path.join(snap_dir, prev_files[-1]), encoding="utf-8").read().splitlines() if prev_files else []
            open(os.path.join(snap_dir, f"{fname}.txt"), "w", encoding="utf-8").write(text)
            diff = list(difflib.unified_diff(old, text.splitlines(), "before", "after", lineterm="", n=1))
            open(os.path.join(snap_dir, f"{fname}.diff"), "w", encoding="utf-8").write("\n".join(diff) + "\n")
            added = [l[1:] for l in diff if l.startswith("+") and not l.startswith("+++")]
            with open(os.path.join(wdir(case_dir), "changes.log"), "a", encoding="utf-8") as fh:
                fh.write(f"{stamp}\t{x['id']}\t{x['url']}\t{len(added)} new lines\t" + " | ".join(added[:3])[:300] + "\n")
            print(f"{x['id']} {x['label']}: CHANGED ({len(added)} new lines)")
            for l in added[:5]:
                print(f"    + {l[:150]}")
            audit(case_dir, "ns-watch", x["url"], f"CHANGED: {len(added)} new lines, snapshot {h[:16]}")
        else:
            print(f"{x['id']} {x['label']}: no change")
        x["last_hash"], x["last_check"] = h, stamp
    save(case_dir, w)
    return 10 if changed else 0                       # 10 = something changed (for the timer)


def cmd_check_all(data_dir):
    any_change = False
    root = os.path.join(data_dir, "Cases")
    for case in sorted(os.listdir(root)) if os.path.isdir(root) else []:
        cd = os.path.join(root, case)
        if not load(cd):
            continue
        meta = os.path.join(cd, "case.json")
        if os.path.exists(meta) and json.load(open(meta, encoding="utf-8")).get("status") == "closed":
            continue
        print(f"== case {case}")
        any_change |= cmd_check(cd) == 10
    return 10 if any_change else 0


def cmd_changes(case_dir):
    p = os.path.join(case_dir, "watch", "changes.log")
    if not os.path.exists(p):
        print("No changes recorded yet.")
        return 0
    for line in open(p, encoding="utf-8").read().splitlines()[-20:]:
        t, wid, url, n, sample = (line.split("\t") + [""] * 5)[:5]
        print(f"{t}  {wid}  {n}: {url}\n    {sample[:160]}")
    return 0


def main(argv):
    cmds = {"add": (cmd_add, 2, 3), "list": (cmd_list, 1, 1), "remove": (cmd_remove, 2, 2),
            "check": (cmd_check, 1, 1), "check-all": (cmd_check_all, 1, 1), "changes": (cmd_changes, 1, 1)}
    if len(argv) < 2 or argv[1] not in cmds or not cmds[argv[1]][1] <= len(argv) - 2 <= cmds[argv[1]][2]:
        print(__doc__)
        return 2
    return cmds[argv[1]][0](*argv[2:])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
