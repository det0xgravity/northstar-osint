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
import pathlib
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


def local_links(nodes, data):
    """Bookmarks to {NS_DATA}/path (local pages such as the face-search warning) as file:// URLs."""
    out = []
    for n in nodes:
        if "children" in n:
            out.append(dict(n, children=local_links(n["children"], data)))
        elif str(n.get("url", "")).startswith("{NS_DATA}/"):
            if data:
                out.append(dict(n, url=pathlib.Path(os.path.abspath(data), n["url"][len("{NS_DATA}/"):]).as_uri()))
        else:
            out.append(n)
    return out


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
    ap.add_argument("--countries", help="folder of country packs; their bookmarks go under 'Countries'")
    ap.add_argument("--extensions", required=True, action="append",
                    help="add-on slug list; repeat to add files (missing files are skipped)")
    ap.add_argument("--out", required=True)
    ap.add_argument("--folder", default="OSINT", help="top-level bookmark folder name")
    ap.add_argument("--data", help="northstar's data folder: bookmarks to {NS_DATA}/… become file:// links "
                                   "there (they're left out without it)")
    args = ap.parse_args()

    with open(args.bookmarks, encoding="utf-8") as fh:
        tree = local_links(json.load(fh), args.data)
    if args.local and os.path.isfile(args.local):
        with open(args.local, encoding="utf-8") as fh:
            tree += json.load(fh)
        print(f"   merged local bookmarks from {args.local}")

    if args.countries and os.path.isdir(args.countries):
        packs = []
        for fn in sorted(os.listdir(args.countries)):
            if fn.endswith(".json"):
                with open(os.path.join(args.countries, fn), encoding="utf-8") as fh:
                    packs.append(json.load(fh))
        packs.sort(key=lambda p: (p["code"] != "INT", p["name"]))   # International first
        tree.append({"name": "Countries", "children": [
            {"name": p["name"], "children": p["bookmarks"]} for p in packs if p.get("bookmarks")]})

    extensions, missing = {}, []
    slugs = []
    for path in args.extensions:
        if not os.path.isfile(path):
            continue
        for slug in read_slugs(path):
            if slug not in slugs:
                slugs.append(slug)
    for slug in slugs:
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

    def count(nodes):
        return sum(count(n["children"]) if "children" in n else 1 for n in nodes)
    print(f"   {len(extensions)} extensions, {count(tree)} bookmarks")
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
