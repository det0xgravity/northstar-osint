#!/usr/bin/env python3
"""Country search packs for truebearing-osint (the engine behind tb-country).

Each pack, config/countries/<code>.json, lists the searches a country supports
and its bookmark folders. docs/COUNTRIES.md describes the format.

Commands:
  list                      CODE<TAB>Name for every pack (International first)
  name CODE                 the country's name
  searches CODE             one search label per line
  prompt CODE LABEL         the question to ask for that search
  run CODE LABEL QUERY      tab-separated lines for tb-country to act on:
                              dir<TAB>...    result folder name for the case
                              kind<TAB>...   short name of the search, for the audit log
                              url<TAB>...    open in the browser
                              info<TAB>...   show to the user and save
                              clip<TAB>...   copy to the clipboard
                              error<TAB>...  stop with this message
  validate [DIR]            check every pack; exit status 1 on problems

Link syntax inside a search:
  "https://…{q}…"   a URL; placeholders are URL-encoded
  "g:…{q}…"         a Google search for that text
Placeholders: {q} everywhere; {e164} {intl} {national} {alt} {digits} in phone
searches. {alt} is the national format without brackets, joined by hyphens
(613-555-0142), the way many numbers are written online.

Standard library only. Phone analysis uses the 'phonenumbers' package when the
interpreter has it (True Bearing's core venv does) and degrades without it.
"""
import json
import os
import re
import sys
import urllib.parse

HERE = os.path.dirname(os.path.abspath(__file__))
PACKS = os.environ.get("TB_COUNTRIES") or os.path.join(HERE, "..", "config", "countries")
GOOGLE = "https://www.google.com/search?q="
PLACEHOLDER = re.compile(r"{([a-z0-9]+)}")
PHONE_FIELDS = {"q", "e164", "intl", "national", "alt", "digits"}
TRANSFORMS = {"upper", "alnum", "callsign", "digits"}


def load(directory=PACKS):
    packs = {}
    for fn in sorted(os.listdir(directory)):
        if fn.endswith(".json"):
            with open(os.path.join(directory, fn), encoding="utf-8") as fh:
                pack = json.load(fh)
            pack["_file"] = fn
            packs[pack["code"]] = pack
    return packs


def ordered(packs):
    """International first, then countries by name."""
    return sorted(packs.values(), key=lambda p: (p["code"] != "INT", p["name"]))


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def find_search(pack, label):
    for s in pack["searches"]:
        if s["label"] == label:
            return s
    raise SystemExit(f"error\tUnknown search '{label}' for {pack['name']}")


def transform(query, how):
    for t in how or []:
        if t == "upper":
            query = query.upper()
        elif t == "alnum":
            query = re.sub(r"[^A-Za-z0-9]", "", query)
        elif t == "callsign":
            query = re.sub(r"[^A-Za-z0-9/]", "", query)
        elif t == "digits":
            query = re.sub(r"[^0-9]", "", query)
    return query


def phone_fields(raw, region):
    """Returns (fields, info lines). Raises ValueError for an unusable number."""
    digits = re.sub(r"[^0-9]", "", raw)
    try:
        import phonenumbers
        from phonenumbers import carrier, geocoder, PhoneNumberFormat as F, PhoneNumberType
    except ImportError:
        if not digits:
            raise ValueError("Enter a phone number.")
        e164 = "+" + digits if raw.strip().startswith("+") else digits
        return ({"q": raw.strip(), "e164": e164, "intl": raw.strip(),
                 "national": raw.strip(), "alt": raw.strip(), "digits": digits},
                ["Phone analysis unavailable: run ./install.sh --only countries"])
    try:
        n = phonenumbers.parse(raw, region)
    except phonenumbers.NumberParseException:
        hint = "" if region else " Include the country code, e.g. +44 20 7946 0000."
        raise ValueError("That doesn't look like a phone number." + hint)
    national = phonenumbers.format_number(n, F.NATIONAL)
    types = {v: k for k, v in vars(PhoneNumberType).items() if isinstance(v, int)}
    info = [
        f"Number: {phonenumbers.format_number(n, F.INTERNATIONAL)}",
        f"Valid: {phonenumbers.is_valid_number(n)}",
        f"Country: {phonenumbers.region_code_for_number(n) or 'unknown'}",
        f"Region: {geocoder.description_for_number(n, 'en') or 'unknown'}",
        f"Original carrier: {carrier.name_for_number(n, 'en') or 'unknown'} (numbers can be ported)",
        f"Type: {types.get(phonenumbers.number_type(n), 'unknown')}",
    ]
    fields = {
        "q": national,
        "e164": phonenumbers.format_number(n, F.E164),
        "intl": phonenumbers.format_number(n, F.INTERNATIONAL),
        "national": national,
        "alt": re.sub(r"[\s-]+", "-", re.sub(r"[()]", "", national)).strip("-"),
        "digits": str(n.national_number),
    }
    return fields, info


def build(link, fields):
    if link.startswith("g:"):
        text = PLACEHOLDER.sub(lambda m: fields[m.group(1)], link[2:])
        return GOOGLE + urllib.parse.quote_plus(text)
    return PLACEHOLDER.sub(lambda m: urllib.parse.quote_plus(fields[m.group(1)]), link)


def run(pack, label, query):
    s = find_search(pack, label)
    query = transform(query.strip(), s.get("transform"))
    if not query:
        print("error\tNothing to search for.")
        return
    info = []
    if s.get("type") == "phone":
        try:
            fields, info = phone_fields(query, pack.get("phone_region"))
        except ValueError as exc:
            print(f"error\t{exc}")
            return
    else:
        fields = {"q": query}
    print(f"dir\t{slug(pack['name'])}")
    print(f"kind\t{slug(label)}")
    for link in s["links"]:
        print(f"url\t{build(link, fields)}")
    for line in info:
        print(f"info\t{line}")
    if s.get("note"):
        print(f"info\t{s['note']}")
    print(f"clip\t{fields['q']}")


def check_bookmarks(nodes, where, problems):
    for node in nodes:
        if not isinstance(node, dict) or "name" not in node:
            problems.append(f"{where}: bookmark without a name")
        elif "children" in node:
            check_bookmarks(node["children"], f"{where} > {node['name']}", problems)
        elif not str(node.get("url", "")).startswith(("http://", "https://")):
            problems.append(f"{where} > {node['name']}: missing or bad url")


def validate(directory):
    problems = []
    try:
        packs = load(directory)
    except (OSError, ValueError, KeyError) as exc:
        print(f"cannot load packs: {exc}")
        return 1
    for code, p in packs.items():
        where = p["_file"]
        if p["_file"] != code.lower() + ".json":
            problems.append(f"{where}: code '{code}' doesn't match the file name")
        for key in ("name", "searches", "bookmarks"):
            if key not in p:
                problems.append(f"{where}: missing '{key}'")
        labels = set()
        for s in p.get("searches", []):
            label = s.get("label", "?")
            if label in labels:
                problems.append(f"{where}: duplicate search '{label}'")
            labels.add(label)
            if not s.get("prompt"):
                problems.append(f"{where} / {label}: missing prompt")
            if not s.get("links"):
                problems.append(f"{where} / {label}: no links")
            allowed = PHONE_FIELDS if s.get("type") == "phone" else {"q"}
            for t in s.get("transform", []):
                if t not in TRANSFORMS:
                    problems.append(f"{where} / {label}: unknown transform '{t}'")
            for link in s.get("links", []):
                if not link.startswith(("https://", "http://", "g:")):
                    problems.append(f"{where} / {label}: bad link '{link}'")
                for name in PLACEHOLDER.findall(link):
                    if name not in allowed:
                        problems.append(f"{where} / {label}: unknown placeholder {{{name}}}")
        check_bookmarks(p.get("bookmarks", []), where, problems)
    for line in problems:
        print(line)
    print(f"{len(packs)} packs, {sum(len(p.get('searches', [])) for p in packs.values())} searches, "
          f"{len(problems)} problems")
    return 1 if problems else 0


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    cmd = argv[1]
    if cmd == "validate":
        return validate(argv[2] if len(argv) > 2 else PACKS)
    packs = load()
    if cmd == "list":
        for p in ordered(packs):
            print(f"{p['code']}\t{p['name']}")
        return 0
    if len(argv) < 3 or argv[2] not in packs:
        print("error\tUnknown country code. Run 'tb-country' to pick one.")
        return 1
    pack = packs[argv[2]]
    if cmd == "name":
        print(pack["name"])
    elif cmd == "searches":
        for s in pack["searches"]:
            print(s["label"])
    elif cmd == "prompt" and len(argv) > 3:
        print(find_search(pack, argv[3])["prompt"])
    elif cmd == "run" and len(argv) > 4:
        run(pack, argv[3], argv[4])
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
