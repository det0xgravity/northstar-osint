#!/usr/bin/env python3
"""Offline translation for northstar-osint (the engine behind ns-translate).

Usage:
  ns_translate.py languages                list languages (installed ones marked *)
  ns_translate.py get FROM TO              download the language models needed (once)
  ns_translate.py text FROM TO             translate stdin to stdout
  ns_translate.py file FROM TO IN OUT      translate a text file

Uses Argos Translate (MIT): models run on this computer, so the text you
translate never leaves it. Only the one-time model download uses the internet.
Language pairs without a direct model go through English. Machine translation
is a lead: have important passages checked by a qualified translator.
"""
import os
import sys

os.environ.setdefault("ARGOS_DEVICE_TYPE", "cpu")
import argostranslate.package  # noqa: E402
import argostranslate.translate  # noqa: E402


def installed():
    return {l.code: l for l in argostranslate.translate.get_installed_languages()}


def cmd_languages():
    have = installed()
    try:
        argostranslate.package.update_package_index()
        names = {}
        for p in argostranslate.package.get_available_packages():
            names[p.from_code], names[p.to_code] = p.from_name, p.to_name
    except Exception as exc:                         # offline: installed ones only
        print(f"(couldn't fetch the model index: {exc})", file=sys.stderr)
        names = {c: l.name for c, l in have.items()}
    for code, name in sorted(names.items(), key=lambda x: x[1]):
        print(f"{code}\t{name}{' *' if code in have else ''}")
    return 0


def cmd_get(src, dst):
    if translator(src, dst):                         # already installed: no network needed
        print("Ready (models already installed).")
        return 0
    argostranslate.package.update_package_index()
    avail = argostranslate.package.get_available_packages()
    have = {(p.from_code, p.to_code) for p in argostranslate.package.get_installed_packages()}
    direct = [p for p in avail if (p.from_code, p.to_code) == (src, dst)]
    route = direct or [p for p in avail if (p.from_code, p.to_code) in ((src, "en"), ("en", dst))]
    if not direct and len(route) < (1 if "en" in (src, dst) else 2):
        print(f"No model for {src} → {dst} (or through English).")
        return 1
    for p in route:
        if (p.from_code, p.to_code) in have:
            print(f"{p.from_name} → {p.to_name}: already installed")
            continue
        print(f"Downloading {p.from_name} → {p.to_name} (about 100 MB)…", flush=True)
        argostranslate.package.install_from_path(p.download())
    print("Ready.")
    return 0


def translator(src, dst):
    have = installed()
    if src not in have or dst not in have:
        return None
    return have[src].get_translation(have[dst])


def translate(tr, text):
    # Paragraph by paragraph keeps the layout and long texts manageable
    return "\n".join(tr.translate(p) if p.strip() else p for p in text.split("\n"))


def main(argv):
    if len(argv) == 2 and argv[1] == "languages":
        return cmd_languages()
    if len(argv) == 4 and argv[1] == "get":
        return cmd_get(argv[2], argv[3])
    if (len(argv) == 4 and argv[1] == "text") or (len(argv) == 6 and argv[1] == "file"):
        tr = translator(argv[2], argv[3])
        if tr is None:
            print(f"The {argv[2]} → {argv[3]} models aren't installed yet: run 'get' first.", file=sys.stderr)
            return 1
        if argv[1] == "text":
            sys.stdout.write(translate(tr, sys.stdin.read()) + "\n")
        else:
            with open(argv[4], encoding="utf-8", errors="replace") as fh:
                out = translate(tr, fh.read())
            with open(argv[5], "w", encoding="utf-8") as fh:
                fh.write(out + "\n")
            print(f"Translated {argv[4]} → {argv[5]}")
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
