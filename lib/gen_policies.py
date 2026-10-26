#!/usr/bin/env python3
"""Generate browser policy files and a bookmarks export for northstar-osint.

Outputs (into --out):
  firefox-policies.json   Firefox enterprise policies: extensions + managed bookmarks
  brave-policies.json     Chromium-style managed bookmarks for Brave
  northstar-bookmarks.html  Netscape bookmark file for importing anywhere

Extension GUIDs are resolved live from addons.mozilla.org using each add-on's
slug, so the list never goes stale when an author changes an ID.
Exit status is 1 if any extension slug could not be resolved.
"""
import argparse
import html
import json
import os
import sys
import urllib.request

AMO_API = "https://addons.mozilla.org/api/v5/addons/addon/{}/"
AMO_XPI = "https://addons.mozilla.org/firefox/downloads/latest/{}/latest.xpi"


def read_slugs(path):
    slugs = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.split("#", 1)[0].strip()
            if line:
                slugs.append(line)
    return slugs


def resolve(slug):
    req = urllib.request.Request(AMO_API.format(slug),
                                 headers={"User-Agent": "northstar-osint"})
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.load(resp)["guid"]


def to_html(tree, depth=2):
    pad = "    " * depth
    out = []
    for node in tree:
        name = html.escape(node["name"])
        if "children" in node:
            out.append(f"{pad}<DT><H3>{name}</H3>")
            out.append(f"{pad}<DL><p>")
            out.append(to_html(node["children"], depth + 1))
            out.append(f"{pad}</DL><p>")
        else:
            out.append(f'{pad}<DT><A HREF="{html.escape(node["url"])}">{name}</A>')
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--bookmarks", required=True)
    ap.add_argument("--local", help="optional user bookmarks file, merged in")
    ap.add_argument("--extensions", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--folder", default="OSINT", help="top-level bookmark folder name")
    args = ap.parse_args()

    with open(args.bookmarks, encoding="utf-8") as fh:
        tree = json.load(fh)
    if args.local and os.path.isfile(args.local):
        with open(args.local, encoding="utf-8") as fh:
            tree += json.load(fh)
        print(f"   merged local bookmarks from {args.local}")

    extensions, missing = {}, []
    for slug in read_slugs(args.extensions):
        try:
            guid = resolve(slug)
        except Exception as exc:  # network errors, 404s, bad JSON
            missing.append(slug)
            print(f"   {slug:28} NOT RESOLVED ({exc})")
            continue
        extensions[guid] = {"installation_mode": "normal_installed",
                            "install_url": AMO_XPI.format(slug)}
        print(f"   {slug:28} {guid}")

    managed = [{"toplevel_name": args.folder}] + tree
    firefox = {"policies": {
        "ExtensionSettings": extensions,
        "ManagedBookmarks": managed,
        "DisplayBookmarksToolbar": "always",
        "DisableTelemetry": True,
        "DisableFirefoxStudies": True,
        "OfferToSaveLogins": False,
    }}
    brave = {"ManagedBookmarks": managed, "BookmarkBarEnabled": True}

    os.makedirs(args.out, exist_ok=True)
    with open(os.path.join(args.out, "firefox-policies.json"), "w", encoding="utf-8") as fh:
        json.dump(firefox, fh, indent=2)
    with open(os.path.join(args.out, "brave-policies.json"), "w", encoding="utf-8") as fh:
        json.dump(brave, fh, indent=2)
    with open(os.path.join(args.out, "northstar-bookmarks.html"), "w", encoding="utf-8") as fh:
        fh.write("<!DOCTYPE NETSCAPE-Bookmark-file-1>\n"
                 '<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">\n'
                 "<TITLE>Bookmarks</TITLE>\n<H1>Bookmarks</H1>\n<DL><p>\n"
                 f"    <DT><H3>{html.escape(args.folder)}</H3>\n    <DL><p>\n"
                 + to_html(tree) + "\n    </DL><p>\n</DL><p>\n")

    links = sum(1 for f in tree for _ in f.get("children", []))
    print(f"   {len(extensions)} extensions, {links} bookmarks in {len(tree)} folders")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
