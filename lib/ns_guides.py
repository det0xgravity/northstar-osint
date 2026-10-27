#!/usr/bin/env python3
"""Readable copies of the user guides for northstar-osint (run by the desktop module).

Commands:
  build DOCSDIR OUTDIR   render every DOCSDIR/*.md to OUTDIR/<name>.html with pandoc
                         (GitHub-flavoured Markdown, so links and anchors match GitHub),
                         plus a stylesheet and index.html. Links between guides point
                         to the HTML copies. Pages are self-contained: nothing is loaded
                         from the internet when they're opened.
"""
import html
import os
import re
import shutil
import subprocess
import sys
import tempfile

# Shown first in the index, in this order, with a line each; other guides follow by name
ORDER = [("INVESTIGATION-GUIDE", "Start here: a quick start checklist, then a whole case step by step, with worked examples"),
         ("MENUS", "What every menu option does and where its output goes"),
         ("EVIDENCE", "Sealed result folders, the tamper-evident audit log, exhibits and export"),
         ("MISSING-PERSONS", "Missing-person casework and search-party events"),
         ("BREACH-DARKWEB", "Breach lookups, the dark web and Tor Browser, with their ground rules"),
         ("COUNTRIES", "Country searches and how to add a country"),
         ("TROUBLESHOOTING", "When something doesn't work"),
         ("INSTALL", "Installing, updating and uninstalling"),
         ("MODULES", "Every tool installed, with links to its project"),
         ("KASM", "Running northstar on Proxmox with Kasm Workspaces")]

CSS = """:root { --bg: #ffffff; --fg: #1f2328; --muted: #59636e; --line: #d1d9e0; --code: #f6f8fa; --link: #0969da; --quote: #f0f6ff; }
@media (prefers-color-scheme: dark) {
  :root { --bg: #0d1117; --fg: #e6edf3; --muted: #9198a1; --line: #30363d; --code: #161b22; --link: #4493f8; --quote: #121d2f; }
}
body { background: var(--bg); color: var(--fg); font: 16px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, "Noto Sans", sans-serif;
       max-width: 920px; margin: 0 auto; padding: 24px 20px 64px; }
a { color: var(--link); }
h1, h2 { border-bottom: 1px solid var(--line); padding-bottom: .3em; }
h1 { font-size: 2em; } h2 { font-size: 1.5em; margin-top: 2em; } h3 { margin-top: 1.6em; }
code { background: var(--code); padding: .15em .35em; border-radius: 4px; font-size: 90%; }
pre { background: var(--code); padding: 12px 16px; border-radius: 6px; overflow-x: auto; }
pre code { background: none; padding: 0; }
table { border-collapse: collapse; display: block; overflow-x: auto; margin: 1em 0; }
th, td { border: 1px solid var(--line); padding: 6px 12px; vertical-align: top; }
th { background: var(--code); }
blockquote { margin: 1em 0; padding: .5em 1em; border-left: 4px solid var(--link); background: var(--quote); color: var(--fg); }
li > input[type=checkbox] { margin-right: .4em; }
ul.task-list, ul.contains-task-list { list-style: none; padding-left: 1.2em; }
hr { border: 0; border-top: 1px solid var(--line); margin: 2em 0; }
img { max-width: 100%; }
.nav { font-size: 14px; color: var(--muted); margin-bottom: 1.5em; }
.guides { list-style: none; padding: 0; } .guides li { margin: .9em 0; } .guides span { color: var(--muted); display: block; }
@media print { .nav { display: none; } body { max-width: none; } }
"""

NAV = '<p class="nav"><a href="index.html">← All northstar guides</a></p>\n'
LINK = re.compile(r"\]\((?!https?:|mailto:|#)([A-Za-z0-9_.-]+)\.md(#[^)\s]*)?\)")


def title_of(text, fallback):
    m = re.search(r"(?m)^# (.+)$", text)
    return (m.group(1).strip() if m else fallback)[:120]


def render(pandoc, src, dest, name):
    text = open(src, encoding="utf-8").read()
    text = LINK.sub(lambda m: f"]({m.group(1)}.html{m.group(2) or ''})", text)
    with tempfile.NamedTemporaryFile("w", suffix=".md", encoding="utf-8", delete=False) as tmp:
        tmp.write(text)
    try:
        subprocess.run([pandoc, "-f", "gfm", "-t", "html5", "--standalone", "--css", "guides.css",
                        "--metadata", f"pagetitle={title_of(text, name)} - northstar",
                        "-o", dest, tmp.name], check=True, capture_output=True, timeout=120)
    finally:
        os.unlink(tmp.name)
    page = open(dest, encoding="utf-8").read()
    page = re.sub(r"(<body[^>]*>\n?)", lambda m: m.group(1) + NAV, page, count=1)
    with open(dest, "w", encoding="utf-8") as fh:
        fh.write(page)


def cmd_build(docs, out):
    pandoc = shutil.which("pandoc")
    if not pandoc:
        print("pandoc isn't installed: the guides can't be rendered", file=sys.stderr)
        return 1
    names = sorted(n[:-3] for n in os.listdir(docs) if n.endswith(".md"))
    if not names:
        print(f"No guides in {docs}", file=sys.stderr)
        return 1
    tmp_out = out + ".new"
    shutil.rmtree(tmp_out, ignore_errors=True)
    os.makedirs(tmp_out)
    with open(os.path.join(tmp_out, "guides.css"), "w", encoding="utf-8") as fh:
        fh.write(CSS)
    if os.path.isdir(os.path.join(docs, "images")):
        shutil.copytree(os.path.join(docs, "images"), os.path.join(tmp_out, "images"))
    titles, failed = {}, []
    for n in names:
        try:
            render(pandoc, os.path.join(docs, n + ".md"), os.path.join(tmp_out, n + ".html"), n)
            titles[n] = title_of(open(os.path.join(docs, n + ".md"), encoding="utf-8").read(), n)
        except (OSError, subprocess.SubprocessError) as e:
            failed.append(f"{n}: {e}")
    known = dict(ORDER)
    order = [n for n, _ in ORDER if n in titles] + [n for n in names if n in titles and n not in known]
    items = "\n".join(f'<li><a href="{html.escape(n)}.html">{html.escape(titles[n])}</a>'
                      f'<span>{html.escape(known.get(n, ""))}</span></li>' for n in order)
    with open(os.path.join(tmp_out, "index.html"), "w", encoding="utf-8") as fh:
        fh.write('<!doctype html>\n<html lang="en">\n<head>\n<meta charset="utf-8">\n'
                 '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
                 '<title>northstar guides</title>\n<link rel="stylesheet" href="guides.css">\n</head>\n<body>\n'
                 '<h1>northstar guides</h1>\n<p>Copies of the guides for this installation, updated by '
                 '<code>ns-update</code>. They work offline.</p>\n'
                 f'<ul class="guides">\n{items}\n</ul>\n</body>\n</html>\n')
    shutil.rmtree(out, ignore_errors=True)
    os.replace(tmp_out, out)
    print(f"{len(titles)} guides rendered to {out}")
    for f in failed:
        print(f"  failed: {f}", file=sys.stderr)
    return 1 if failed else 0


def main(argv):
    if len(argv) != 4 or argv[1] != "build":
        print(__doc__)
        return 2
    return cmd_build(os.path.abspath(argv[2]), os.path.abspath(argv[3]))


if __name__ == "__main__":
    sys.exit(main(sys.argv))
