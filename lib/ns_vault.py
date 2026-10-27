#!/usr/bin/env python3
"""Obsidian vault for northstar-osint (the engine behind ns-notes).

The Cases folder is one Obsidian vault: each case gets a Case.md overview and
a Results.md log of every result folder, and working notes (people, accounts,
organisations, places, events, leads) are made from templates in _templates/.

Commands:
  setup DATADIR                  vault settings, templates and Home.md (keeps your changes)
  register DATADIR CONFIG_JSON   add the vault to Obsidian's vault list (Obsidian closed)
  case CASEDIR                   create Case.md if missing, refresh Home.md
  result CASEDIR RESULTDIR       add a result folder to Results.md
  new CASEDIR TYPE TITLE         a note from a template; prints its path
  uri PATH                       obsidian:// link that opens PATH

Working notes are ordinary, editable files. The tamper-evident record stays in
notes.md (Case → Add a note) and audit.log.
"""
import datetime
import hashlib
import json
import os
import re
import sys
import time
import urllib.parse

MARK = "<!-- northstar: generated, edit freely -->"
TYPES = {"person": "People", "account": "Accounts", "organisation": "Organisations", "place": "Places",
         "event": "Events", "lead": "Leads"}

TEMPLATES = {
    "Person": """---
type: person
aliases: []
date_of_birth:
nationality:
status: unconfirmed
tags: [person]
created: {{date:YYYY-MM-DD}}
---
# {{title}}

## Identifiers
- Full name:
- Usernames: (link each [[Account]] note)
- Emails:
- Phones:
- Addresses / places: (link [[Place]] notes)

## Description

## Connections
- (link people, organisations and accounts, and say how each link is known)

## Sources
| What | Where (URL or result folder) | Captured (UTC) |
|---|---|---|
|  |  |  |

## Confidence
What is confirmed, by what, and what is still assumption.
""",
    "Account": """---
type: account
platform:
username:
user_id:
url:
owner: "[[ ]]"
status: active
tags: [account]
created: {{date:YYYY-MM-DD}}
---
# {{title}}

- Platform:
- Display name:
- Profile URL:
- Stable ID (survives renames):
- Created / first seen:
- Last activity seen:

## Attribution
Why this account is (or might be) the subject's: shared photos, writing style, linked email or phone, mutual contacts.

## Notable content
- (date, link, what it shows)

## Captures
- (result folders, exhibit numbers)
""",
    "Organisation": """---
type: organisation
jurisdiction:
registration_number:
tags: [organisation]
created: {{date:YYYY-MM-DD}}
---
# {{title}}

- Registered name and number:
- Jurisdiction / registry:
- Address:
- Website / domains:

## People
- (officers, owners, employees: link [[Person]] notes)

## Sources
""",
    "Place": """---
type: place
lat:
lon:
tags: [place]
created: {{date:YYYY-MM-DD}}
---
# {{title}}

- Address:
- Coordinates: (also add it to the Case map)
- Why it matters:

## Visits and sightings
- (UTC time, who, source)
""",
    "Event": """---
type: event
when_utc:
where: "[[ ]]"
tags: [event]
created: {{date:YYYY-MM-DD}}
---
# {{title}}

- When (UTC):
- Where:
- Who:

## What happened

## Sources
""",
    "Lead": """---
type: lead
status: open
priority: medium
tags: [lead]
created: {{date:YYYY-MM-DD}}
---
# {{title}}

- Source of the lead:
- Next step:
- Assigned to:

## Outcome
""",
}

OBSIDIAN_CONFIG = {
    "app.json": {"newFileLocation": "current", "attachmentFolderPath": "./attachments",
                 "showUnsupportedFiles": False, "alwaysUpdateLinks": True,
                 "userIgnoreFilters": ["*/watch/", "*/crops/"]},
    "appearance.json": {"theme": "obsidian"},
    "templates.json": {"folder": "_templates", "dateFormat": "YYYY-MM-DD", "timeFormat": "HH:mm"},
    "core-plugins.json": {"file-explorer": True, "global-search": True, "switcher": True, "graph": True,
                          "backlink": True, "outgoing-link": True, "tag-pane": True, "properties": True,
                          "page-preview": True, "templates": True, "note-composer": True,
                          "command-palette": True, "outline": True, "word-count": True,
                          "file-recovery": True, "canvas": True, "bookmarks": True, "daily-notes": False},
}


def utc(fmt="%Y-%m-%d %H:%M UTC"):
    return datetime.datetime.now(datetime.timezone.utc).strftime(fmt)


def write_if_missing(path, text):
    if not os.path.exists(path):
        os.makedirs(os.path.dirname(path), mode=0o700, exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(text)
        return True
    return False


def cases_root(data_dir):
    return os.path.join(data_dir, "Cases")


def home(root):
    """Home.md lists every case; regenerated while it still carries our marker."""
    path = os.path.join(root, "Home.md")
    if os.path.exists(path) and MARK not in open(path, encoding="utf-8").read():
        return
    rows = []
    for name in sorted(os.listdir(root)):
        cj = os.path.join(root, name, "case.json")
        if name.startswith((".", "_")) or not os.path.isdir(os.path.join(root, name)):
            continue
        meta = json.load(open(cj, encoding="utf-8")) if os.path.exists(cj) else {}
        rows.append(f"| [[{name}/Case\\|{name}]] | {meta.get('status', 'open')} | {cell(meta.get('reference', ''))} | "
                    f"{(meta.get('opened_utc') or meta.get('created_utc') or '')[:10]} |")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(f"{MARK}\n# Cases\n\n| Case | Status | Reference | Opened |\n|---|---|---|---|\n"
                 + "\n".join(rows) + "\n\nNew working notes: open a case's **Case** note and use the "
                 "*Templates* command, or the Notes menu in northstar.\n")


def cmd_setup(data_dir):
    root = cases_root(data_dir)
    os.makedirs(root, mode=0o700, exist_ok=True)
    for name, conf in OBSIDIAN_CONFIG.items():
        write_if_missing(os.path.join(root, ".obsidian", name), json.dumps(conf, indent=2) + "\n")
    for name, text in TEMPLATES.items():
        p = os.path.join(root, "_templates", f"{name}.md")
        # refresh our own templates; a template you've edited is left alone
        if not os.path.exists(p) or open(p, encoding="utf-8").read().endswith(MARK + "\n"):
            os.makedirs(os.path.dirname(p), mode=0o700, exist_ok=True)
            with open(p, "w", encoding="utf-8") as fh:
                fh.write(text + "\n" + MARK + "\n")
    for case in os.listdir(root):
        if os.path.exists(os.path.join(root, case, "case.json")) or os.path.exists(os.path.join(root, case, "audit.log")):
            cmd_case(os.path.join(root, case), quiet=True)
    home(root)
    print(f"Vault ready: {root}")
    return 0


def cmd_register(data_dir, config_json):
    """Obsidian keeps its vault list in obsidian.json; add ours so links open it."""
    root = os.path.realpath(cases_root(data_dir))
    conf = {}
    if os.path.exists(config_json):
        try:
            conf = json.load(open(config_json, encoding="utf-8"))
        except ValueError:
            print("obsidian.json isn't valid JSON: left alone.")
            return 1
    vaults = conf.setdefault("vaults", {})
    if any(os.path.realpath(v.get("path", "")) == root for v in vaults.values()):
        print("Vault already registered.")
        return 0
    vid = hashlib.sha256(root.encode()).hexdigest()[:16]
    vaults[vid] = {"path": root, "ts": int(time.time() * 1000), "open": True}
    os.makedirs(os.path.dirname(config_json), mode=0o700, exist_ok=True)
    with open(config_json, "w", encoding="utf-8") as fh:
        json.dump(conf, fh)
    print(f"Vault registered with Obsidian: {root}")
    return 0


def cell(v):
    return str(v).replace("|", "\\|").replace("\n", " ")


def cmd_case(case_dir, quiet=False):
    name = os.path.basename(os.path.abspath(case_dir))
    cj = os.path.join(case_dir, "case.json")
    meta = json.load(open(cj, encoding="utf-8")) if os.path.exists(cj) else {}
    text = f"""---
type: case
case: {name}
reference: {json.dumps(meta.get('reference', ''))}
status: {json.dumps(meta.get('status', 'open'))}
tags: [case]
---
# Case {name}

| | |
|---|---|
| Reference | {cell(meta.get('reference', ''))} |
| Authorised by | {cell(meta.get('authorised_by', ''))} |
| Purpose and lawful basis | {cell(meta.get('purpose', ''))} |
| Scope | {cell(meta.get('scope', ''))} |
| Review date | {cell(meta.get('review_date', ''))} |

## Summary
What is known so far, in a few lines.

## Subjects
- (link [[Person]] and [[Organisation]] notes)

## Open leads
- [ ]

## Key records
- [[{name}/Results|Results]]: every search and capture, newest last
- [Contemporaneous notes](notes.md): tamper-evident; add to them with Case → Add a note, don't edit here
- [Subject profile](subject/subject.md) · [Timeline](subject/timeline.html) · [Findings](subject/findings.md)
- Folders: People, Accounts, Organisations, Places, Events, Leads (made by Notes → New note)

{MARK}
"""
    made = write_if_missing(os.path.join(case_dir, "Case.md"), text)
    write_if_missing(os.path.join(case_dir, "Results.md"),
                     f"# Results: {name}\n\nEvery result folder in this case, newest last.\n\n")
    if not quiet:
        home(os.path.dirname(os.path.abspath(case_dir)))
        print("Case.md created." if made else "Case.md already exists.")
    return 0


def main_file(result_dir):
    files = sorted(os.listdir(result_dir))
    for pattern in (r"\.html?$", r"report.*\.md$", r"\.csv$", r"\.json$", r"\.(txt|md)$"):
        for f in files:
            if re.search(pattern, f) and f not in ("provenance.json", "manifest.sha256"):
                return f
    return "console.log" if "console.log" in files else ""


def cmd_result(case_dir, result_dir):
    rel = os.path.relpath(os.path.abspath(result_dir), os.path.abspath(case_dir))
    if rel.startswith(".."):
        return 0
    cmd_case(case_dir, quiet=True)
    f = main_file(result_dir)
    tool = rel.split(os.sep)[0]
    link = f"[{os.path.basename(rel)}](<{rel}/{f}>)" if f else f"`{rel}`"
    with open(os.path.join(case_dir, "Results.md"), "a", encoding="utf-8") as fh:
        fh.write(f"- {utc()} · **{tool}** · {link}\n")
    return 0


def cmd_new(case_dir, kind, title):
    kind = kind.lower()
    if kind not in TYPES:
        print(f"Type must be one of: {', '.join(TYPES)}", file=sys.stderr)
        return 2
    root = os.path.dirname(os.path.abspath(case_dir))
    tpl_path = os.path.join(root, "_templates", f"{kind.capitalize()}.md")
    tpl = open(tpl_path, encoding="utf-8").read() if os.path.exists(tpl_path) else TEMPLATES[kind.capitalize()]
    tpl = tpl.replace(MARK, "").rstrip() + "\n"
    safe = re.sub(r'[\\/:*?"<>|#^\[\]]', "-", title).strip() or "Untitled"
    path = os.path.join(case_dir, TYPES[kind], f"{safe}.md")
    text = (tpl.replace("{{title}}", title).replace("{{date:YYYY-MM-DD}}", utc("%Y-%m-%d"))
            .replace("{{date}}", utc("%Y-%m-%d")).replace("{{time}}", utc("%H:%M")))
    write_if_missing(path, text)
    print(path)
    return 0


def cmd_uri(path):
    print("obsidian://open?path=" + urllib.parse.quote(os.path.abspath(path), safe=""))
    return 0


def main(argv):
    cmds = {"setup": (cmd_setup, 1), "register": (cmd_register, 2), "case": (cmd_case, 1),
            "result": (cmd_result, 2), "new": (cmd_new, 3), "uri": (cmd_uri, 1)}
    if len(argv) < 2 or argv[1] not in cmds or len(argv) - 2 != cmds[argv[1]][1]:
        print(__doc__)
        return 2
    return cmds[argv[1]][0](*argv[2:])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
