#!/usr/bin/env python3
"""Dark web helpers for northstar-osint (the engine behind ns-darkweb).

All .onion traffic goes through the local Tor SOCKS proxy (127.0.0.1:9050) via
curl. Pages are fetched as text only: one HTML document, no images, scripts,
stylesheets or other resources, and anything that isn't text/HTML is refused.

Usage:
  ns_darkweb.py check               is Tor reachable, and is traffic exiting through Tor?
  ns_darkweb.py fetch URL           save one page as text: title, text, links, hashes
  ns_darkweb.py ransomware NAME     search ransomware leak-site claims (ransomware.live)

Results are written to the current directory (the case's result folder).
"""
import datetime
import hashlib
import html
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.parse

SOCKS = os.environ.get("NS_TOR_SOCKS", "127.0.0.1:9050")
# Fetches identify as Tor Browser does (one generic UA for everyone), so the
# investigator's machine doesn't stand out to the site being examined.
UA = "Mozilla/5.0 (Windows NT 10.0; rv:128.0) Gecko/20100101 Firefox/128.0"
MAX_BYTES = 10 * 1024 * 1024
ONION = re.compile(r"\b[a-z2-7]{56}\.onion\b")


def curl(url, tor=True, extra=(), timeout=90):
    """Returns (http_code, content_type, body_bytes, headers_text)."""
    with tempfile.TemporaryDirectory() as tmp:
        hdr, body = os.path.join(tmp, "h"), os.path.join(tmp, "b")
        cmd = ["curl", "-sS", "-L", "--max-redirs", "5", "--max-time", str(timeout),
               "--max-filesize", str(MAX_BYTES), "-A", UA, "-D", hdr, "-o", body,
               "-w", "%{http_code}\t%{content_type}"]
        if tor:
            cmd += ["--socks5-hostname", SOCKS]
        cmd += list(extra) + [url]
        p = subprocess.run(cmd, capture_output=True, text=True)
        if p.returncode != 0:
            raise RuntimeError(p.stderr.strip() or f"curl exit {p.returncode}")
        code, _, ctype = p.stdout.partition("\t")
        data = open(body, "rb").read() if os.path.exists(body) else b""
        headers = open(hdr, encoding="latin-1").read() if os.path.exists(hdr) else ""
        return int(code or 0), ctype, data, headers


def tor_status():
    try:
        _, _, body, _ = curl("https://check.torproject.org/api/ip", timeout=40)
        return json.loads(body.decode() or "{}")
    except (RuntimeError, ValueError):
        return None


def cmd_check():
    st = tor_status()
    if st is None:
        print("Tor is NOT reachable on", SOCKS)
        print("Start it: Linux 'sudo systemctl start tor', macOS 'brew services start tor'.")
        return 1
    print("Tor is working." if st.get("IsTor") else "Connected, but traffic is NOT exiting through Tor!")
    print("Exit IP seen by websites:", st.get("IP"))
    return 0 if st.get("IsTor") else 1


def cmd_fetch(url):
    if not re.match(r"^https?://", url):
        url = "http://" + url
    if tor_status() is None:
        print("Tor isn't reachable, so nothing was fetched. Run 'Check Tor connection' first.")
        return 1
    fetched = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")
    try:
        code, ctype, body, headers = curl(url, timeout=120)
    except RuntimeError as exc:
        print("Fetch failed:", exc)
        return 1
    ctype_main = ctype.split(";")[0].strip().lower()
    with open("headers.txt", "w", encoding="utf-8") as fh:
        fh.write(headers)
    meta = {"url": url, "fetched_utc": fetched, "http_status": code, "content_type": ctype,
            "bytes": len(body), "via": f"Tor SOCKS {SOCKS}"}
    if ctype_main not in ("text/html", "text/plain", "application/xhtml+xml", ""):
        meta["saved"] = False
        meta["reason"] = "not a text page; content discarded unread"
        json.dump(meta, open("metadata.json", "w"), indent=2)
        print(f"HTTP {code}, {ctype}: not a text page, so it was discarded without being saved.")
        return 1
    meta["sha256"] = hashlib.sha256(body).hexdigest()
    page = body.decode("utf-8", "replace")
    title = re.search(r"<title[^>]*>(.*?)</title>", page, re.S | re.I)
    meta["title"] = html.unescape(title.group(1)).strip() if title else ""
    stripped = re.sub(r"(?is)<(script|style|noscript|svg)[^>]*>.*?</\1>", " ", page)
    text = html.unescape(re.sub(r"<[^>]+>", " ", stripped))
    text = "\n".join(line.strip() for line in re.sub(r"[ \t]+", " ", text).splitlines() if line.strip())
    links = sorted(set(urllib.parse.urljoin(url, h) for h in re.findall(r'href=["\']([^"\'#]+)', page, re.I)))
    onions = sorted(set(ONION.findall(page)))
    # Saved as .txt so a double-click opens it in a text editor: opened in a
    # browser it would load the page's trackers from the investigator's own IP
    with open("page.html.txt", "wb") as fh:
        fh.write(body)
    with open("page.txt", "w", encoding="utf-8") as fh:
        fh.write(text + "\n")
    with open("links.txt", "w", encoding="utf-8") as fh:
        fh.write("\n".join(links) + "\n")
    with open("onion_addresses.txt", "w", encoding="utf-8") as fh:
        fh.write("\n".join(onions) + "\n")
    with open("metadata.json", "w", encoding="utf-8") as fh:
        json.dump(meta, fh, indent=2, ensure_ascii=False)
    print(f"HTTP {code} · {ctype} · {len(body):,} bytes · SHA-256 {meta['sha256']}")
    print(f"Title: {meta['title'] or '(none)'}")
    print(f"{len(links)} links, {len(onions)} distinct onion addresses mentioned")
    print("\n--- first lines of text ---")
    print("\n".join(text.splitlines()[:25]))
    print("\nSaved: page.txt, page.html.txt (source; don't open it in a browser), links.txt,")
    print("       onion_addresses.txt, headers.txt, metadata.json")
    return 0


def cmd_ransomware(name):
    try:
        code, _, body, _ = curl("https://api.ransomware.live/v2/searchvictims/" + urllib.parse.quote(name),
                                tor=False, timeout=40)
    except RuntimeError as exc:
        print("Lookup failed:", exc)
        return 1
    data = json.loads(body.decode() or "null") if body else None
    if code == 429:
        print("ransomware.live allows one search per minute. Wait a minute and try again.")
        return 1
    if code != 200 or not isinstance(data, list):
        print(f"ransomware.live returned HTTP {code}: {str(data)[:200]}")
        return 1
    with open("ransomware.json", "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
    print(f"{len(data)} leak-site claims matching '{name}' (claims by criminal groups, often unverified):")
    for v in sorted(data, key=lambda v: str(v.get("attackdate") or v.get("discovered") or ""), reverse=True)[:40]:
        when = str(v.get("attackdate") or v.get("discovered") or "?")[:10]
        print(f"- {when} · {v.get('group') or v.get('group_name') or '?'} · "
              f"{v.get('victim') or v.get('post_title') or '?'} · {v.get('country') or ''} {v.get('domain') or ''}")
    if len(data) > 40:
        print(f"… {len(data) - 40} more in ransomware.json")
    print("\nSaved: ransomware.json. Details per claim: https://www.ransomware.live/")
    return 0


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    cmd, arg = argv[1], (argv[2].strip() if len(argv) > 2 else "")
    if cmd == "check":
        return cmd_check()
    if not arg:
        print("Nothing to search for.")
        return 1
    if cmd == "fetch":
        return cmd_fetch(arg)
    if cmd == "ransomware":
        return cmd_ransomware(arg)
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
