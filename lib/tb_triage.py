#!/usr/bin/env python3
"""File triage for truebearing-osint (the engine behind Evidence → Check received
or suspicious files): what a file really is and whether it shows warning signs,
without ever opening or running it.

Usage: tb_triage.py PATH... (files or folders; folders are walked)
Writes the report to stdout; with --json FILE also a machine-readable copy.

Checks, per file: the real type (libmagic via `file`) against the extension,
SHA-256, a ClamAV scan when clamscan and its signatures are present, Office
macros (oletools' olevba), active content in PDFs (a keyword count, as pdfid
does), archive contents (listed, never extracted), and EXIF location data in
images. Verdicts are DANGER, CAUTION or "no warning signs", and the last is
never a guarantee that a file is safe.
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import zipfile

EXEC_MIME = ("application/x-executable", "application/x-pie-executable", "application/x-sharedlib",
             "application/x-dosexec", "application/vnd.microsoft.portable-executable", "application/x-mach-binary",
             "application/x-ms-shortcut", "application/x-msi", "application/x-ms-installer", "application/java-archive",
             "application/x-shellscript", "text/x-shellscript", "application/x-iso9660-image")
RISKY_EXT = {".exe", ".dll", ".scr", ".com", ".pif", ".msi", ".lnk", ".hta", ".js", ".jse", ".vbs", ".vbe", ".wsf",
             ".ps1", ".bat", ".cmd", ".jar", ".iso", ".img", ".vhd", ".vhdx", ".appimage", ".sh", ".run", ".deb",
             ".rpm", ".apk", ".dmg", ".pkg", ".app", ".reg", ".cpl", ".chm", ".url", ".library-ms", ".xll", ".one"}
OFFICE_EXT = {".doc", ".docm", ".docx", ".dot", ".dotm", ".xls", ".xlsm", ".xlsx", ".xlsb", ".xla", ".xlam", ".ppt",
              ".pptm", ".pptx", ".ppsm", ".rtf", ".odt", ".ods", ".odp"}
PDF_KEYS = ["/JavaScript", "/JS", "/OpenAction", "/AA", "/Launch", "/EmbeddedFile", "/RichMedia", "/XFA", "/AcroForm",
            "/URI", "/SubmitForm", "/GoToR"]
PDF_ACTIVE = {"/JavaScript", "/JS", "/OpenAction", "/AA", "/Launch", "/EmbeddedFile", "/RichMedia", "/XFA"}
# The extension a file claims, and the types that would fit it
EXPECT = {".pdf": ("application/pdf",), ".jpg": ("image/jpeg",), ".jpeg": ("image/jpeg",), ".png": ("image/png",),
          ".gif": ("image/gif",), ".txt": ("text/",), ".csv": ("text/", "application/csv"), ".zip": ("application/zip",),
          ".mp4": ("video/",), ".mov": ("video/",), ".mp3": ("audio/",), ".docx": ("application/vnd.openxmlformats", "application/zip"),
          ".xlsx": ("application/vnd.openxmlformats", "application/zip"), ".pptx": ("application/vnd.openxmlformats", "application/zip")}


def run(cmd, timeout=300):
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout, p.stderr
    except (OSError, subprocess.SubprocessError) as e:
        return None, "", str(e)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def magic(path):
    if not shutil.which("file"):
        return "", ""
    _, desc, _ = run(["file", "-b", "--", path], 60)
    _, mime, _ = run(["file", "-b", "--mime-type", "--", path], 60)
    return desc.strip(), mime.strip().split(",")[0].split(";")[0].strip()   # some builds append notes


def clam_available():
    return bool(shutil.which("clamscan"))


def clamscan(path):
    """('clean'|'found'|'error', detail)"""
    rc, out, err = run(["clamscan", "--no-summary", "--stdout", "--", path], 900)
    if rc == 0:
        return "clean", ""
    if rc == 1:
        hits = [l.split(": ", 1)[1].replace(" FOUND", "") for l in out.splitlines() if l.endswith(" FOUND")]
        return "found", ", ".join(hits) or "a signature matched"
    msg = (err or out).strip().splitlines()
    return "error", (msg[-1] if msg else "clamscan failed")[:200]


def pdf_keywords(path):
    counts = {}
    with open(path, "rb") as fh:
        data = fh.read(64 * 1024 * 1024)
    for k in PDF_KEYS:
        n = len(re.findall(re.escape(k.encode()) + rb"(?![A-Za-z])", data))
        if n:
            counts[k] = n
    return counts


def olevba(path):
    """List of (type, keyword, description) from olevba, or None if it couldn't run."""
    exe = shutil.which("olevba")
    if not exe:
        return None
    rc, out, _ = run([exe, "--json", "--", path], 300)
    try:
        data = json.loads(out)
    except ValueError:
        return None
    found = []
    for item in data if isinstance(data, list) else []:
        if not isinstance(item, dict):
            continue
        for a in item.get("analysis") or []:
            found.append((a.get("type", ""), a.get("keyword", ""), a.get("description", "")))
        if item.get("macros") and not found:
            found.append(("Macro", "VBA", "contains VBA macros"))
    return found


def archive_listing(path, mime):
    """(names, notes) without extracting anything."""
    names, notes = [], []
    try:
        if zipfile.is_zipfile(path):
            with zipfile.ZipFile(path) as z:
                for i in z.infolist()[:5000]:
                    names.append(i.filename)
                    if i.flag_bits & 0x1:
                        notes.append("password-protected entries (often used to get malware past scanners)")
        elif tarfile.is_tarfile(path):
            with tarfile.open(path) as t:
                names = [m.name for m in t.getmembers()[:5000]]
        elif any(x in mime for x in ("x-7z", "x-rar", "vnd.rar")):
            notes.append("7-Zip/RAR archive: contents not listed here")
    except (OSError, zipfile.BadZipFile, tarfile.TarError, RuntimeError) as e:
        notes.append(f"couldn't list the archive ({e.__class__.__name__})")
    for n in names:
        if n.startswith("/") or ".." in n.split("/"):
            notes.append(f"entry escapes the folder it would be extracted to: {n[:120]}")
        if os.path.splitext(n.lower())[1] in RISKY_EXT:
            notes.append(f"contains a program or script: {n[:120]}")
    return names, list(dict.fromkeys(notes))


def exif_location(path):
    if not shutil.which("exiftool"):
        return ""
    _, out, _ = run(["exiftool", "-n", "-s3", "-GPSLatitude", "-GPSLongitude", "--", path], 60)
    vals = out.split()
    return f"{vals[0]}, {vals[1]}" if len(vals) >= 2 else ""


def triage(path):
    ext = os.path.splitext(path.lower())[1]
    desc, mime = magic(path)
    r = {"file": path, "size": os.path.getsize(path), "sha256": sha256(path), "type": desc, "mime": mime,
         "danger": [], "caution": [], "info": []}
    if mime in EXEC_MIME or ext in RISKY_EXT or "executable" in desc.lower():
        r["danger"].append("a program, script, shortcut or disk image: never run or mount it")
    want = EXPECT.get(ext)
    if want and mime and not any(mime.startswith(w) for w in want):
        r["danger" if mime in EXEC_MIME else "caution"].append(f"named {ext} but is really {mime}")
    if mime in ("text/html", "image/svg+xml") or ext in (".html", ".htm", ".svg", ".mht", ".mhtml"):
        r["caution"].append("a web page or SVG: opening it in a browser can run scripts and contact the sender")
    if clam_available():
        st, d = clamscan(path)
        if st == "found":
            r["danger"].append(f"ClamAV: {d}")
        elif st == "error":
            r["caution"].append(f"ClamAV couldn't scan it: {d}")
        else:
            r["info"].append("ClamAV: no known malware")
    if mime == "application/pdf" or ext == ".pdf":
        k = pdf_keywords(path)
        active = {x: n for x, n in k.items() if x in PDF_ACTIVE}
        if active:
            r["caution"].append("PDF active content: " + ", ".join(f"{x} ×{n}" for x, n in active.items()))
        if "/Launch" in k:
            r["danger"].append("PDF /Launch action: it can try to start another program")
        if k and not active:
            r["info"].append("PDF links or forms: " + ", ".join(k))
    if ext in OFFICE_EXT or "ms-office" in mime or "msword" in mime or "officedocument" in mime or "opendocument" in mime:
        m = olevba(path)
        if m is None:
            r["caution"].append("Office document: macros not checked (oletools isn't installed)")
        elif m:
            auto = [kw for t, kw, _ in m if t == "AutoExec"]
            sus = [kw for t, kw, _ in m if t == "Suspicious"]
            (r["danger"] if auto else r["caution"]).append(
                "macros" + (f" that run on opening ({', '.join(auto[:5])})" if auto else "")
                + (f"; suspicious calls: {', '.join(sus[:8])}" if sus else ""))
        else:
            r["info"].append("no macros found")
    if "zip" in mime or "tar" in mime or "x-7z" in mime or "rar" in mime or ext in (".zip", ".tar", ".tgz", ".7z", ".rar"):
        names, notes = archive_listing(path, mime)
        if names:
            r["info"].append(f"archive with {len(names)} entries (not extracted): " + ", ".join(names[:10])
                             + (" …" if len(names) > 10 else ""))
        for n in notes:
            (r["danger"] if "program or script" in n or "escapes" in n else r["caution"]).append(n)
    if mime.startswith("image/"):
        loc = exif_location(path)
        if loc:
            r["info"].append(f"GPS position in the metadata: {loc}")
    r["verdict"] = "DANGER" if r["danger"] else "CAUTION" if r["caution"] else "no warning signs"
    return r


def human(n):
    for unit in ("bytes", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return f"{n:.0f} {unit}" if unit == "bytes" else f"{n:.1f} {unit}"
        n /= 1024


def main(argv):
    args, out_json = [], None
    it = iter(argv[1:])
    for a in it:
        if a == "--json":
            out_json = next(it, None)
        else:
            args.append(a)
    if not args:
        print(__doc__)
        return 2
    files = []
    for a in args:
        if os.path.isdir(a):
            for root, dirs, names in os.walk(a):
                dirs.sort()
                files += [os.path.join(root, n) for n in sorted(names)]
        elif os.path.isfile(a):
            files.append(a)
    results = []
    for f in files:
        if os.path.islink(f):
            continue
        results.append(triage(f))
    n_d = sum(1 for r in results if r["verdict"] == "DANGER")
    n_c = sum(1 for r in results if r["verdict"] == "CAUTION")
    print(f"File triage: {len(results)} file(s): {n_d} DANGER, {n_c} CAUTION, {len(results) - n_d - n_c} no warning signs")
    if not clam_available():
        print("ClamAV isn't installed, so files weren't scanned for known malware.")
    print("Nothing was opened or run. No warning signs is not proof that a file is safe.\n")
    for r in results:
        print(f"== {r['file']}\n   {r['verdict']}  ·  {r['type'][:120] or r['mime']}  ·  {human(r['size'])}\n   SHA-256 {r['sha256']}")
        for k, mark in (("danger", "!!"), ("caution", " !"), ("info", "  ")):
            for line in r[k]:
                print(f"   {mark} {line}")
        print()
    if out_json:
        with open(out_json, "w", encoding="utf-8") as fh:
            json.dump(results, fh, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
