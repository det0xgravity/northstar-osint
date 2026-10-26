#!/usr/bin/env python3
"""Breach-data lookups for northstar-osint (the engine behind ns-breach).

Queries breach-notification and infostealer-intelligence services. It never
downloads or stores breach dumps: only what each service returns about one
selector, saved to the current directory (the case's result folder).

Usage:
  ns_breach.py email ADDRESS
  ns_breach.py username NAME
  ns_breach.py domain DOMAIN
  ns_breach.py phone NUMBER
  ns_breach.py breach NAME          HIBP breach catalogue (free)
  ns_breach.py password             reads ONE password on stdin (HIBP k-anonymity)

Free sources run every time: XposedOrNot, Hudson Rock (infostealers), LeakCheck
public, the HIBP catalogue and Pwned Passwords. Paid sources run when their key
is in ~/.config/northstar/keys.env (managed with ns-keys): HIBP_API_KEY,
INTELX_API_KEY, DEHASHED_API_KEY, LEAKCHECK_API_KEY.

Passwords returned by a service are saved only in that service's JSON file
(mode 600) and are masked on screen and in summary.txt.
"""
import hashlib
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

UA = "northstar-osint (+https://github.com/det0xgravity/northstar-osint)"
KEYS_FILE = os.environ.get("NS_KEYS") or os.path.join(
    os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), "northstar", "keys.env")
SECRET_FIELDS = {"password", "hashed_password", "hash", "passwords", "top_passwords"}
summary = []


# --- plumbing ------------------------------------------------------------------
def keys():
    found = {}
    try:
        with open(KEYS_FILE, encoding="utf-8") as fh:
            for line in fh:
                if "=" in line and not line.lstrip().startswith("#"):
                    k, v = line.rstrip("\n").split("=", 1)
                    if v.strip():
                        found[k.strip()] = v.strip()
    except OSError:
        pass
    return found


class HTTPError(Exception):
    def __init__(self, code, body=""):
        super().__init__(f"HTTP {code}")
        self.code, self.body = code, body


def http(url, method="GET", headers=None, body=None, timeout=30):
    h = {"User-Agent": UA, "Accept": "application/json"}
    h.update(headers or {})
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        h["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=h, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as exc:
        raise HTTPError(exc.code, exc.read().decode("utf-8", "replace")[:300]) from None
    try:
        return json.loads(raw) if raw.strip() else None
    except ValueError:
        return raw


def say(line=""):
    print(line, flush=True)
    summary.append(line)


def save(name, data):
    path = f"{name}.json"
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
    return path


def mask(value):
    return "••••••" if str(value) else ""      # fixed length: don't reveal how long it is


def masked(entry):
    """Copy of a record with secret fields masked, for display."""
    if isinstance(entry, dict):
        return {k: (mask(v) if k.lower() in SECRET_FIELDS and v else masked(v)) for k, v in entry.items()}
    if isinstance(entry, list):
        return [masked(v) for v in entry]
    return entry


def flat(v):
    if isinstance(v, list):
        return ", ".join(str(x) for x in v if x not in (None, ""))
    return "" if v is None else str(v)


def section(title):
    say()
    say(f"== {title}")


def run(title, fn, *args):
    """Run one source; a failing source never stops the others."""
    section(title)
    try:
        fn(*args)
    except HTTPError as exc:
        hint = {401: "key rejected", 402: "no credits left on this key", 403: "access denied",
                404: "not found", 429: "rate limit reached, try again later"}.get(exc.code, "")
        say(f"   error: HTTP {exc.code}{' (' + hint + ')' if hint else ''}")
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        say(f"   error: network problem ({exc})")


def skipped(keyname):
    say(f"   skipped: no {keyname} (add one with ns-keys)")


# --- free sources --------------------------------------------------------------------
def xposedornot(email):
    data = http(f"https://api.xposedornot.com/v1/breach-analytics?email={urllib.parse.quote(email)}")
    details = ((data or {}).get("ExposedBreaches") or {}).get("breaches_details") or []
    if not details:
        say("   not found in any breach")
        return
    save("xposedornot", data)
    say(f"   found in {len(details)} breaches:")
    ordered = sorted(details, key=lambda b: str(b.get("xposed_date", "")), reverse=True)
    for b in ordered[:40]:
        say(f"   - {b.get('breach')} ({b.get('xposed_date', '?')}): {flat(b.get('xposed_data')).replace(';', ', ')}")
    if len(ordered) > 40:
        say(f"   … {len(ordered) - 40} older breaches in xposedornot.json")


def hudsonrock(kind, value):
    param = {"email": "email", "username": "username", "domain": "domain"}[kind]
    data = http("https://cavalier.hudsonrock.com/api/json/v2/osint-tools/"
                f"search-by-{kind}?{param}={urllib.parse.quote(value)}")
    if kind == "domain":                     # response format isn't documented: show its counts
        save("hudsonrock", data)
        counts = {k: v for k, v in (data or {}).items() if isinstance(v, (int, float))}
        say("   " + (", ".join(f"{k.replace('_', ' ')}: {v}" for k, v in counts.items())
                     or "results saved to hudsonrock.json"))
        return
    stealers = (data or {}).get("stealers") or []
    if not stealers:
        say("   no infostealer infection on record")
        return
    save("hudsonrock", data)
    say(f"   {len(stealers)} infostealer-infected computer(s) linked to this {kind}:")
    for s in stealers:
        say(f"   - compromised {str(s.get('date_compromised', '?'))[:10]} · {s.get('computer_name', '?')} · "
            f"{s.get('operating_system', '?')} · {s.get('total_user_services', '?')} saved logins")


def leakcheck_public(value):
    data = http(f"https://leakcheck.io/api/public?check={urllib.parse.quote(value)}")
    if not (data or {}).get("success"):
        say("   not found")
        return
    save("leakcheck-public", data)
    srcs = data.get("sources") or []
    say(f"   found in {data.get('found', len(srcs))} sources; data types: {flat(data.get('fields'))}")
    for s in srcs[:50]:
        say(f"   - {s.get('name')} {('(' + s['date'] + ')') if s.get('date') else ''}")
    if len(srcs) > 50:
        say(f"   … {len(srcs) - 50} more in leakcheck-public.json")


def hibp_domain_breaches(domain):
    data = http(f"https://haveibeenpwned.com/api/v3/breaches?domain={urllib.parse.quote(domain)}") or []
    if not data:
        say("   no known breach of a service on this domain")
        return
    save("hibp-domain-breaches", data)
    for b in data:
        say(f"   - {b.get('Title')} ({b.get('BreachDate')}): {(b.get('PwnCount') or 0):,} accounts; "
            f"{', '.join(b.get('DataClasses', []))}")


def hibp_catalogue(name):
    try:
        data = [http(f"https://haveibeenpwned.com/api/v3/breach/{urllib.parse.quote(name)}")]
    except HTTPError as exc:
        if exc.code != 404:
            raise
        allb = http("https://haveibeenpwned.com/api/v3/breaches") or []
        data = [b for b in allb if name.lower() in (b.get("Name", "") + b.get("Title", "") + b.get("Domain", "")).lower()]
    if not data:
        say("   no breach by that name in HIBP")
        return
    save("hibp-breach", data)
    for b in data[:20]:
        say(f"   {b.get('Title')} — {b.get('Domain') or 'no domain'}")
        say(f"     breached {b.get('BreachDate')}, added {str(b.get('AddedDate', ''))[:10]}, "
            f"{(b.get('PwnCount') or 0):,} accounts, verified: {b.get('IsVerified')}")
        say(f"     data: {', '.join(b.get('DataClasses', []))}")
        desc = re.sub(r"<[^>]+>", "", b.get("Description", ""))
        say(f"     {desc[:400]}{'…' if len(desc) > 400 else ''}")


def pwned_password(pw):
    digest = hashlib.sha1(pw.encode("utf-8")).hexdigest().upper()
    prefix, suffix = digest[:5], digest[5:]
    body = http(f"https://api.pwnedpasswords.com/range/{prefix}", headers={"Add-Padding": "true",
                                                                          "Accept": "text/plain"})
    count = 0
    for line in str(body).splitlines():
        h, _, n = line.strip().partition(":")
        if h == suffix:
            count = int(n or 0)
            break
    if count:
        say(f"   EXPOSED: this password appears {count:,} times in known breaches. Don't use it.")
    else:
        say("   not found in Pwned Passwords (that doesn't prove it's strong)")
    say("   (only the first 5 characters of its SHA-1 hash left this computer)")


# --- paid sources ---------------------------------------------------------------------
def hibp_account(email, key):
    try:
        data = http(f"https://haveibeenpwned.com/api/v3/breachedaccount/{urllib.parse.quote(email)}"
                    "?truncateResponse=false", headers={"hibp-api-key": key})
    except HTTPError as exc:
        if exc.code == 404:
            say("   not found in any breach")
            return
        raise
    save("hibp", data)
    say(f"   found in {len(data)} breaches:")
    for b in sorted(data, key=lambda b: b.get("BreachDate", ""), reverse=True):
        say(f"   - {b.get('Title')} ({b.get('BreachDate')}): {', '.join(b.get('DataClasses', []))}")


def leakcheck_pro(value, kind, key):
    params = {"limit": 1000}
    if kind in ("domain", "phone", "username"):
        params["type"] = {"phone": "phone", "domain": "domain", "username": "username"}[kind]
    data = http(f"https://leakcheck.io/api/v2/query/{urllib.parse.quote(value)}?{urllib.parse.urlencode(params)}",
                headers={"X-API-Key": key})
    rows = (data or {}).get("result") or []
    if not rows:
        say(f"   not found{' (' + str(data.get('error')) + ')' if isinstance(data, dict) and data.get('error') else ''}")
        return
    save("leakcheck", data)
    say(f"   {data.get('found', len(rows))} records; {data.get('quota', '?')} queries left on the key")
    for r in rows[:40]:
        src = r.get("source") or {}
        shown = masked({k: v for k, v in r.items() if k not in ("source", "fields")})
        say(f"   - {src.get('name', '?')} ({src.get('breach_date') or r.get('collected') or '?'}): "
            + ", ".join(f"{k}={flat(v)}" for k, v in shown.items() if v not in (None, "", [])))
    if len(rows) > 40:
        say(f"   … {len(rows) - 40} more in leakcheck.json")


def dehashed(value, kind, key):
    field = {"email": "email", "username": "username", "domain": "domain", "phone": "phone"}[kind]
    query = f'{field}:"{value}"'
    data = http("https://api.dehashed.com/v2/search", method="POST", headers={"Dehashed-Api-Key": key},
                body={"query": query, "page": 1, "size": 1000, "de_dupe": True})
    rows = (data or {}).get("entries") or []
    if not rows:
        say("   not found")
        return
    save("dehashed", data)
    say(f"   {data.get('total', len(rows))} records (showing {min(len(rows), 40)}); "
        f"balance: {data.get('balance', '?')}")
    for r in rows[:40]:
        shown = masked(r)
        db = flat(shown.pop("database_name", "")) or "?"
        shown.pop("id", None)
        say(f"   - {db}: " + ", ".join(f"{k}={flat(v)}" for k, v in shown.items() if v not in (None, "", [])))
    if len(rows) > 40:
        say(f"   … {len(rows) - 40} more in dehashed.json")


def intelx(value, key):
    start = None
    for base in ("https://2.intelx.io", "https://free.intelx.io"):     # paid keys, then free keys
        try:
            start = http(f"{base}/intelligent/search", method="POST", headers={"x-key": key},
                         body={"term": value, "buckets": [], "lookuplevel": 0, "maxresults": 100,
                               "timeout": 5, "datefrom": "", "dateto": "", "sort": 4, "media": 0,
                               "terminate": []})
            break
        except HTTPError as exc:
            if exc.code != 401 or base.startswith("https://free"):
                raise
    sid = (start or {}).get("id")
    if not sid:
        say(f"   search not started (status {(start or {}).get('status')}; IntelX needs a strong selector such as an email or domain)")
        return
    records = []
    for _ in range(15):
        time.sleep(1.2)                                        # IntelX asks for ~1 request/second
        data = http(f"{base}/intelligent/search/result?id={sid}&limit=100", headers={"x-key": key}) or {}
        records += data.get("records") or []
        if data.get("status") in (1, 2):
            break
    if not records:
        say("   no records")
        return
    save("intelx", {"term": value, "records": records})
    buckets = {}
    for r in records:
        buckets[r.get("bucketh") or r.get("bucket") or "?"] = buckets.get(r.get("bucketh") or r.get("bucket") or "?", 0) + 1
    say(f"   {len(records)} records: " + ", ".join(f"{b} {n}" for b, n in sorted(buckets.items(), key=lambda x: -x[1])))
    for r in records[:25]:
        say(f"   - {str(r.get('date', ''))[:10]} {r.get('bucketh') or r.get('bucket')}: {r.get('name', '')[:110]}")
    say("   open records at https://intelx.io/ (search the same term)")


# --- dispatch ----------------------------------------------------------------------------
def main(argv):
    if len(argv) < 2 or argv[1] not in ("email", "username", "domain", "phone", "breach", "password"):
        print(__doc__)
        return 2
    kind = argv[1]
    if kind == "password":
        pw = sys.stdin.readline().rstrip("\n")
        if not pw:
            print("No password given.")
            return 1
        run("Pwned Passwords (HIBP, k-anonymity)", pwned_password, pw)
        return 0                                   # nothing is written to disk for passwords
    if len(argv) < 3 or not argv[2].strip():
        print("Nothing to search for.")
        return 1
    value = argv[2].strip()
    if kind == "email":
        value = value.lower()
        if not re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", value):
            print("That doesn't look like an email address.")
            return 1
    if kind == "domain":
        value = re.sub(r"^[a-z]+://", "", value.lower()).split("/")[0].removeprefix("www.")
    if kind == "phone":
        value = re.sub(r"[^\d+]", "", value)

    k = keys()
    say(f"Breach lookup: {kind} {value}")
    if kind == "breach":
        run("Have I Been Pwned: breach catalogue", hibp_catalogue, value)
    if kind == "email":
        run("XposedOrNot (free)", xposedornot, value)
    if kind in ("email", "username", "domain"):
        run("Hudson Rock: infostealer infections (free)", hudsonrock, kind, value)
    if kind == "domain":
        run("Have I Been Pwned: breaches of this domain's own service (free)", hibp_domain_breaches, value)
    if kind in ("email", "username"):
        if "LEAKCHECK_API_KEY" not in k:
            run("LeakCheck public (free)", leakcheck_public, value)
    if kind == "email":
        if "HIBP_API_KEY" in k:
            run("Have I Been Pwned (key)", hibp_account, value, k["HIBP_API_KEY"])
        else:
            section("Have I Been Pwned (key)")
            skipped("HIBP_API_KEY")
    if kind in ("email", "username", "domain", "phone"):
        for title, name, fn in (("LeakCheck Pro (key)", "LEAKCHECK_API_KEY", leakcheck_pro),
                                ("DeHashed (key)", "DEHASHED_API_KEY", dehashed)):
            if name in k:
                run(title, fn, value, kind, k[name])
            else:
                section(title)
                skipped(name)
    if kind in ("email", "domain", "phone"):
        if "INTELX_API_KEY" in k:
            run("Intelligence X (key)", intelx, value, k["INTELX_API_KEY"])
        else:
            section("Intelligence X (key)")
            skipped("INTELX_API_KEY")

    with open("summary.txt", "w", encoding="utf-8") as fh:
        fh.write("\n".join(summary) + "\n")
    say()
    say("Saved: summary.txt (passwords masked) and one JSON file per source that found something.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
