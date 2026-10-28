#!/usr/bin/env python3
"""Email header analysis for northstar-osint (the engine behind Username &
email → Analyse email headers). Fully offline: nothing is looked up.

Usage: ns_email.py FILE [--json OUT]     FILE is a saved message (.eml) or its
                                          headers as text ("Show original")

Reports who the message claims to be from against where it really came from:
the relay hops (oldest first) with their IPs and UTC times, the delay between
hops, the first public IP, SPF/DKIM/DMARC results as recorded by the receiving
server, and the warning signs of spoofing or phishing (From, Return-Path,
Reply-To and DKIM domains that don't match, failed checks, times out of order).
Headers can be forged below the first server you trust: read the chain from
the top (your own provider) down.
"""
import datetime
import email
import email.policy
import email.utils
import ipaddress
import json
import re
import sys

IP4 = re.compile(r"(?<![\d.])(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)(?![\d.])")
IP6 = re.compile(r"(?i)(?<![0-9a-f:])(?:ipv6:)?((?:[0-9a-f]{1,4}:){2,7}[0-9a-f]{0,4}(?::[0-9a-f]{1,4})*)(?![0-9a-f:])")
FIELDS = ["From", "Sender", "Reply-To", "Return-Path", "To", "Cc", "Subject", "Date", "Message-ID", "X-Mailer",
          "User-Agent", "X-Originating-IP", "X-Sender-IP", "List-Unsubscribe"]


def addr_domain(v):
    _, a = email.utils.parseaddr(str(v or ""))
    return a.rsplit("@", 1)[1].lower().strip(">") if "@" in a else ""


def base(dom):
    """example.co.uk → co.uk is wrong, but a two-label match is enough to compare senders here."""
    parts = dom.lower().strip(".").split(".")
    return ".".join(parts[-3:]) if len(parts) > 2 and len(parts[-2]) <= 3 and len(parts[-1]) == 2 else ".".join(parts[-2:])


def ips(text):
    out = []
    for m in IP4.findall(text):
        out.append(m)
    for m in IP6.findall(text):
        try:
            out.append(str(ipaddress.ip_address(m)))
        except ValueError:
            pass
    return list(dict.fromkeys(out))


def public(ip):
    try:
        a = ipaddress.ip_address(ip)
    except ValueError:
        return False
    return a.is_global


def when(s):
    try:
        d = email.utils.parsedate_to_datetime(s.strip())
    except (TypeError, ValueError, IndexError):
        return None
    if d is None or d.tzinfo is None:
        return None
    return d.astimezone(datetime.timezone.utc)


def hop(raw):
    text = " ".join(raw.split())
    stamp, date = text.rsplit(";", 1) if ";" in text else (text, "")
    fr = re.search(r"\bfrom\s+(\S+)(.*?)(?=\bby\b|$)", stamp, re.I)
    by = re.search(r"\bby\s+(\S+)", stamp, re.I)
    wi = re.search(r"\bwith\s+(\S+)", stamp, re.I)
    return {"from": fr.group(1) if fr else "", "from_detail": (fr.group(2).strip() if fr else "")[:200],
            "by": by.group(1) if by else "", "with": wi.group(1) if wi else "",
            "ips": ips(fr.group(0) if fr else stamp), "time": when(date), "raw": text[:600]}


def auth_results(msg):
    res = {}
    for h in msg.get_all("Authentication-Results") or []:
        for k in ("spf", "dkim", "dmarc", "arc"):
            m = re.search(rf"\b{k}=(\w+)", str(h), re.I)
            if m and k not in res:
                res[k] = m.group(1).lower()
    spf = msg.get("Received-SPF")
    if spf and "spf" not in res:
        res["spf"] = str(spf).split()[0].lower()
    return res


def analyse(path):
    raw = open(path, "rb").read()
    msg = email.message_from_bytes(raw, policy=email.policy.compat32)
    head = {f: " ".join(str(msg.get(f, "")).split())[:500] for f in FIELDS if msg.get(f)}
    hops = [hop(str(h)) for h in reversed(msg.get_all("Received") or [])]       # oldest first
    dkim = [dict(re.findall(r"\b([a-z]+)=([^;\s]+)", " ".join(str(d).split()))) for d in msg.get_all("DKIM-Signature") or []]
    auth = auth_results(msg)
    warn, notes = [], []
    dom = {"From": addr_domain(msg.get("From")), "Return-Path": addr_domain(msg.get("Return-Path")),
           "Reply-To": addr_domain(msg.get("Reply-To")), "Sender": addr_domain(msg.get("Sender"))}
    dkim_d = [d.get("d", "").lower() for d in dkim if d.get("d")]
    if not hops:
        warn.append("no Received headers: these may not be the full headers (use your mail client's Show original / View source)")
    if dom["From"]:
        for k in ("Return-Path", "Reply-To", "Sender"):
            if dom[k] and base(dom[k]) != base(dom["From"]):
                (warn if k == "Reply-To" else notes).append(
                    f"{k} domain ({dom[k]}) differs from From ({dom['From']})"
                    + (": replies would go somewhere else, a common phishing sign" if k == "Reply-To" else
                       " (normal for mailing lists and bulk senders; suspicious for a personal message)"))
        if dkim_d and not any(base(d) == base(dom["From"]) for d in dkim_d):
            notes.append(f"DKIM signed by {', '.join(dkim_d)}, not by the From domain {dom['From']}")
    for k, v in auth.items():
        if v in ("fail", "softfail", "permerror", "temperror"):
            warn.append(f"{k.upper()} {v}: the receiving server couldn't confirm the sender")
        elif v in ("none", "neutral"):
            notes.append(f"{k.upper()} {v}: nothing to check against")
    origin = ""
    for h in hops:
        pub = [i for i in h["ips"] if public(i)]
        if pub:
            origin = pub[0]
            break
    xo = head.get("X-Originating-IP", "") or head.get("X-Sender-IP", "")
    xo_ip = (ips(xo) or [""])[0]
    prev = None
    for i, h in enumerate(hops):
        t = h["time"]
        if t and prev and t < prev:
            delta = (prev - t).total_seconds()
            if delta > 300:
                warn.append(f"hop {i + 1} is timestamped {int(delta // 60)} min before the previous one: a wrong clock, or a forged header below it")
        if t and prev:
            h["delay_s"] = int((t - prev).total_seconds())
        prev = t or prev
    sent = when(head.get("Date", "")) if head.get("Date") else None
    if sent and hops and hops[0]["time"]:
        gap = (hops[0]["time"] - sent).total_seconds()
        if gap < -600:
            warn.append(f"the Date header is {int(-gap // 60)} min after the first server received it")
        elif gap > 86400:
            notes.append(f"the first server received it {gap / 3600:.0f} h after its Date header")
    return {"file": path, "headers": head, "domains": dom, "dkim": dkim, "auth": auth, "hops": hops,
            "origin_ip": origin, "x_originating_ip": xo_ip, "warnings": warn, "notes": notes}


def fmt_time(t):
    return t.strftime("%Y-%m-%d %H:%M:%S UTC") if t else "(no valid time)"


def report(r):
    out = ["Email header analysis (offline: nothing was looked up)", ""]
    for k, v in r["headers"].items():
        out.append(f"{k}: {v}")
    out += ["", "Checks recorded by the receiving server: " + (", ".join(f"{k.upper()} {v}" for k, v in r["auth"].items()) or "none recorded")]
    for d in r["dkim"]:
        out.append(f"DKIM signature: domain {d.get('d', '?')}, selector {d.get('s', '?')}")
    out += ["", f"Relay hops, oldest first ({len(r['hops'])}):"]
    for i, h in enumerate(r["hops"], 1):
        out.append(f"  {i}. {fmt_time(h['time'])}" + (f"  (+{h['delay_s']} s)" if h.get("delay_s") is not None else ""))
        out.append(f"     from {h['from'] or '?'} {h['from_detail']}".rstrip())
        out.append(f"     by   {h['by'] or '?'}" + (f" with {h['with']}" if h["with"] else ""))
        if h["ips"]:
            out.append("     IPs: " + ", ".join(f"{i_} ({'public' if public(i_) else 'private/reserved'})" for i_ in h["ips"]))
    out += ["", f"First public IP in the chain: {r['origin_ip'] or 'none'}"
            + (" (often the sender's mail provider, not the sender: webmail hides the sender's own IP)" if r["origin_ip"] else "")]
    if r["x_originating_ip"]:
        out.append(f"X-Originating-IP: {r['x_originating_ip']} (added by some webmail services: the sender's own connection, if genuine)")
    out += ["", f"Warning signs ({len(r['warnings'])}):"] + [f"  !! {w}" for w in r["warnings"]] + (["  none"] if not r["warnings"] else [])
    out += ["", "Notes:"] + [f"   - {n}" for n in r["notes"]] + (["   - none"] if not r["notes"] else [])
    out += ["", "Headers can be forged below the first server you trust. Read the chain from your own provider's",
            "hop downwards, and check an IP with Domain & infrastructure → WHOIS, RDAP & DNS."]
    return "\n".join(out)


def main(argv):
    args = [a for a in argv[1:]]
    out_json = None
    if "--json" in args:
        i = args.index("--json")
        out_json = args[i + 1] if i + 1 < len(args) else None
        del args[i:i + 2]
    if len(args) != 1:
        print(__doc__)
        return 2
    r = analyse(args[0])
    print(report(r))
    if out_json:
        def enc(o):
            return fmt_time(o) if hasattr(o, "strftime") else str(o)
        with open(out_json, "w", encoding="utf-8") as fh:
            json.dump(r, fh, indent=2, default=enc)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
