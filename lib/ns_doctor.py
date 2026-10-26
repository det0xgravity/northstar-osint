#!/usr/bin/env python3
"""Health check for northstar-osint (the engine behind ns-doctor).

Usage: ns_doctor.py [REPORT_FILE]

Prints a report and, when REPORT_FILE is given, writes it there too. It never
includes secrets: API keys are only checked for their file permissions.
"""
import datetime
import os
import platform
import shutil
import socket
import stat
import subprocess
import sys

HOME = os.path.expanduser("~")
NS_HOME = os.environ.get("NS_HOME") or os.path.join(HOME, ".local/share/northstar")
NS_CONF = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config"), "northstar")
NS_DATA = os.environ.get("NS_DATA") or os.path.join(HOME, "Northstar")

TOOLS = {
    "core": ["git", "jq", "python3", "pipx", "go", "pandoc", "ots"],
    "username": ["sherlock", "maigret", "socialscan", "holehe", "ghunt", "toutatis", "blackbird"],
    "social": ["uv", "tgtracker"],
    "domain": ["subfinder", "dnsx", "httpx", "katana", "gowitness", "amass", "theHarvester",
               "waymore", "dnstwist", "shodan", "censys", "whois", "dig"],
    "media": ["yt-dlp", "gallery-dl", "instaloader", "streamlink", "ffmpeg", "exiftool", "mediainfo",
              "monolith", "tesseract", "ocrmypdf", "whisper-ctranslate2", "ia"],
    "frameworks": ["spiderfoot", "recon-ng", "changedetection.io", "sth", "nth"],
    "darkweb": ["tor", "torsocks"],
    "extras": ["keepassxc", "flameshot"],
    "shell": ["zsh", "fzf", "eza", "ranger", "pay-respects"],
    "northstar": ["northstar", "ns-country", "ns-breach", "ns-darkweb", "ns-evidence", "ns-case",
                  "ns-archive", "ns-video", "ns-telegram", "ns_breach", "ns_darkweb", "ns_evidence",
                  "ns_casework"],
}
NO_VERSION = {"northstar"}            # GUI menus: presence only


def version(cmd):
    for flag in ("--version", "-version", "version", "-V"):
        try:
            p = subprocess.run([cmd, flag], capture_output=True, text=True, timeout=10, stdin=subprocess.DEVNULL)
        except (OSError, subprocess.TimeoutExpired):
            continue
        out = (p.stdout or p.stderr).strip().splitlines()
        if p.returncode == 0 and out:
            return out[0].strip()[:70]
    return ""


def listening(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(0.5)
        return s.connect_ex(("127.0.0.1", port)) == 0


def mode(path):
    return stat.S_IMODE(os.stat(path).st_mode) if os.path.exists(path) else None


def main(argv):
    lines, problems = [], []
    say = lines.append
    ver = open(os.path.join(NS_HOME, "VERSION")).read().strip() if os.path.exists(os.path.join(NS_HOME, "VERSION")) else "?"
    say(f"northstar-osint health check, {datetime.datetime.now(datetime.timezone.utc):%Y-%m-%d %H:%M:%S} UTC")
    say(f"Version {ver} · {platform.system()} {platform.release()} · {platform.machine()} · "
        f"Python {platform.python_version()} · desktop {os.environ.get('XDG_CURRENT_DESKTOP', '-')}"
        f" ({os.environ.get('XDG_SESSION_TYPE', '-')})")
    if os.path.join(NS_HOME, "bin") not in os.environ.get("PATH", ""):
        problems.append("northstar's bin folder isn't on PATH: open a new terminal, or log out and in")

    say("\n== Tools")
    for module, cmds in TOOLS.items():
        found = []
        for c in cmds:
            path = shutil.which(c)
            if not path:
                found.append(f"✗ {c}")
                continue
            v = "" if c in NO_VERSION or c.startswith("ns") else version(c)
            found.append(f"✓ {c}" + (f" ({v})" if v else ""))
        missing = [f[2:] for f in found if f.startswith("✗")]
        say(f"[{module}] " + ("all present" if not missing else f"missing: {', '.join(missing)}"))
        say("   " + "\n   ".join(f for f in found if f.startswith("✓")))

    say("\n== Security and configuration")
    keys = os.path.join(NS_CONF, "keys.env")
    m = mode(keys)
    if m is None:
        say("API keys: none stored")
    else:
        say(f"API keys file: mode {m:o}")
        if m & 0o077:
            problems.append(f"{keys} is readable by other accounts: run chmod 600 {keys}")
    for d in (NS_DATA, os.path.join(NS_DATA, "Cases")):
        m = mode(d)
        if m is not None and m & 0o077:
            problems.append(f"{d} is readable by other accounts: run chmod 700 {d}")
    ports = {3389: "xrdp (remote desktop)", 4000: "amass engine", 9050: "Tor SOCKS proxy"}
    for p, what in ports.items():
        say(f"Port {p} ({what}): {'listening' if listening(p) else 'not listening'}")
    pol = [p for p in ("/etc/firefox/policies/policies.json", "/etc/firefox-esr/policies/policies.json",
                       "/Applications/Firefox.app/Contents/Resources/distribution/policies.json") if os.path.exists(p)]
    say("Firefox policies: " + (", ".join(pol) if pol else "not found"))
    if not pol:
        problems.append("Firefox policies aren't installed: ./install.sh --only browsers")
    total, used, free = shutil.disk_usage(HOME)
    say(f"Free disk space in home: {free / 2**30:.1f} GB of {total / 2**30:.1f} GB")
    if free < 5 * 2**30:
        problems.append("Less than 5 GB free: video, captures and Tor Browser need room")
    log = os.path.join(NS_CONF, "install.log")
    if os.path.exists(log):
        tail = open(log, encoding="utf-8", errors="replace").read().splitlines()[-400:]
        failed = [l.strip() for l in tail if "FAILED" in l or "[!]" in l]
        say(f"Last install log: {len(failed)} warnings/failures in its last 400 lines")
        lines.extend("   " + l for l in failed[-15:])

    say("\n== Summary")
    say("No problems found." if not problems else "\n".join(f"! {p}" for p in problems))
    text = "\n".join(lines) + "\n"
    print(text)
    if len(argv) > 1:
        os.makedirs(os.path.dirname(argv[1]), mode=0o700, exist_ok=True)
        with open(argv[1], "w", encoding="utf-8") as fh:
            fh.write(text)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
