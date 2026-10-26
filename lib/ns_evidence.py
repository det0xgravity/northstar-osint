#!/usr/bin/env python3
"""Evidence integrity for northstar-osint (the engine behind ns-evidence).

Commands:
  seal DIR [VERSION]        write provenance.json and manifest.sha256 for a result
                            folder (called automatically when a search finishes)
  verify DIR                check every file against manifest.sha256
  exhibit CASEDIR DIR DESC  record DIR as the next exhibit in CASEDIR/exhibits.csv
  audit-verify LOG          check the audit log's hash chain
  export CASEDIR OUTDIR     archive the case (tar.gz) with a SHA-256 of the archive

manifest.sha256 uses sha256sum's format, so `sha256sum -c manifest.sha256` (or
`shasum -a 256 -c` on macOS) checks it without northstar. The fingerprint of a
folder is the SHA-256 of its manifest.

audit.log chain: each line ends with SHA-256(previous line + this line's other
fields). Editing, inserting or deleting a line breaks every hash after it.
Lines written before v0.10 have no hash and are reported as unchained.
"""
import csv
import datetime
import getpass
import hashlib
import json
import os
import platform
import re
import subprocess
import sys
import tarfile

MANIFEST = "manifest.sha256"
PROVENANCE = "provenance.json"
SKIP = {MANIFEST, MANIFEST + ".ots"}           # can't list themselves
HEX64 = re.compile(r"^[0-9a-f]{64}$")


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for block in iter(lambda: fh.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def files_in(folder):
    for root, dirs, files in os.walk(folder):
        dirs.sort()
        for name in sorted(files):
            rel = os.path.relpath(os.path.join(root, name), folder)
            if rel not in SKIP and not name.startswith(".ns-"):
                yield rel


def tool_version(tool, northstar_version):
    if tool.startswith("ns_") or tool.startswith("ns-"):
        return f"northstar-osint {northstar_version}"
    for flag in ("--version", "-version", "version", "-V"):
        try:
            p = subprocess.run([tool, flag], capture_output=True, text=True, timeout=8,
                               stdin=subprocess.DEVNULL)
        except (OSError, subprocess.TimeoutExpired):
            continue
        out = (p.stdout or p.stderr).strip().splitlines()
        if p.returncode == 0 and out:
            return out[0].strip()[:200]
    return "unknown"


def cmd_seal(folder, version="unknown"):
    tools = []
    marker = os.path.join(folder, ".ns-tools")
    if os.path.exists(marker):
        tools = sorted(set(t.strip() for t in open(marker, encoding="utf-8") if t.strip()))
    prov = {
        "sealed_utc": utc_now(),
        "folder": os.path.abspath(folder),
        "operator": getpass.getuser(),
        "host": platform.node(),
        "northstar_version": version,
        "tools": {t: tool_version(t, version) for t in tools},
    }
    for name in ("query.txt", "source_url.txt"):
        p = os.path.join(folder, name)
        if os.path.exists(p):
            prov["query"] = open(p, encoding="utf-8", errors="replace").read().strip()[:2000]
            break
    with open(os.path.join(folder, PROVENANCE), "w", encoding="utf-8") as fh:
        json.dump(prov, fh, indent=2, ensure_ascii=False)
    lines, total = [], 0
    for rel in files_in(folder):
        full = os.path.join(folder, rel)
        lines.append(f"{sha256_file(full)}  {rel}")
        total += os.path.getsize(full)
    with open(os.path.join(folder, MANIFEST), "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")
    fp = sha256_file(os.path.join(folder, MANIFEST))
    print(f"Sealed {len(lines)} files ({total:,} bytes). Fingerprint: {fp}")
    return 0


def cmd_verify(folder):
    mpath = os.path.join(folder, MANIFEST)
    if not os.path.exists(mpath):
        print("No manifest.sha256 in this folder: it was never sealed.")
        return 1
    listed, bad, missing = set(), [], []
    for line in open(mpath, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line:
            continue
        digest, rel = line[:64], line[66:]
        listed.add(rel)
        full = os.path.join(folder, rel)
        if not os.path.exists(full):
            missing.append(rel)
        elif sha256_file(full) != digest:
            bad.append(rel)
    added = [r for r in files_in(folder) if r not in listed]
    print(f"Fingerprint: {sha256_file(mpath)}")
    print(f"{len(listed)} files listed: {len(listed) - len(bad) - len(missing)} intact, "
          f"{len(bad)} CHANGED, {len(missing)} MISSING; {len(added)} added since sealing")
    for label, items in (("CHANGED", bad), ("MISSING", missing), ("added", added)):
        for r in items[:20]:
            print(f"  {label}: {r}")
    ots = mpath + ".ots"
    if os.path.exists(ots):
        print("OpenTimestamps proof present: manifest.sha256.ots (verify at https://opentimestamps.org)")
    return 0 if not (bad or missing) else 1


def cmd_exhibit(case_dir, folder, description):
    mpath = os.path.join(folder, MANIFEST)
    if not os.path.exists(mpath):
        print("Folder isn't sealed yet.")
        return 1
    csv_path = os.path.join(case_dir, "exhibits.csv")
    rows = []
    if os.path.exists(csv_path):
        rows = list(csv.DictReader(open(csv_path, encoding="utf-8", newline="")))
    rel = os.path.relpath(os.path.abspath(folder), os.path.abspath(case_dir))
    for r in rows:
        if r["folder"] == rel:
            print(f"Already exhibit {r['exhibit_id']}.")
            return 0
    case = os.path.basename(os.path.abspath(case_dir.rstrip("/")))
    ex_id = f"{case.upper()}-EX-{len(rows) + 1:03d}"
    files = sum(1 for _ in open(mpath, encoding="utf-8") if _.strip())
    total = sum(os.path.getsize(os.path.join(folder, r)) for r in files_in(folder))
    row = {"exhibit_id": ex_id, "recorded_utc": utc_now(), "folder": rel,
           "description": description.replace("\n", " ").strip(),
           "manifest_sha256": sha256_file(mpath), "files": files, "bytes": total,
           "operator": getpass.getuser(),
           "timestamp_proof": MANIFEST + ".ots" if os.path.exists(mpath + ".ots") else ""}
    new = not os.path.exists(csv_path)
    with open(csv_path, "a", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(row))
        if new:
            w.writeheader()
        w.writerow(row)
    print(f"{ex_id}: {rel}\nFingerprint: {row['manifest_sha256']}")
    return 0


def cmd_audit_verify(log):
    if not os.path.exists(log):
        print("No audit.log yet.")
        return 1
    prev, chained, legacy, broken = None, 0, 0, []
    with open(log, encoding="utf-8", errors="replace") as fh:
        for n, line in enumerate(fh, 1):
            line = line.rstrip("\n")
            body, _, digest = line.rpartition("\t")
            if HEX64.match(digest) and body.count("\t") >= 5:
                expected = hashlib.sha256(((prev or "") + body).encode("utf-8")).hexdigest()
                if digest == expected:
                    chained += 1
                else:
                    broken.append(n)
            else:
                legacy += 1
            prev = line
    print(f"{chained} chained lines intact, {len(broken)} BROKEN, {legacy} unchained (written before v0.10)")
    for n in broken[:20]:
        print(f"  chain broken at line {n}: that line, or the one before it, was edited, inserted or removed")
    return 1 if broken else 0


def cmd_export(case_dir, out_dir):
    case_dir = os.path.abspath(case_dir.rstrip("/"))
    case = os.path.basename(case_dir)
    os.makedirs(out_dir, mode=0o700, exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    archive = os.path.join(out_dir, f"{case}_{stamp}.tar.gz")
    with tarfile.open(archive, "w:gz") as tar:
        tar.add(case_dir, arcname=case)
    os.chmod(archive, 0o600)
    digest = sha256_file(archive)
    with open(archive + ".sha256", "w", encoding="utf-8") as fh:
        fh.write(f"{digest}  {os.path.basename(archive)}\n")
    print(f"Exported: {archive}\nSHA-256:  {digest}")
    return 0


def main(argv):
    cmds = {"seal": (cmd_seal, 1, 2), "verify": (cmd_verify, 1, 1), "exhibit": (cmd_exhibit, 3, 3),
            "audit-verify": (cmd_audit_verify, 1, 1), "export": (cmd_export, 2, 2)}
    if len(argv) < 2 or argv[1] not in cmds:
        print(__doc__)
        return 2
    fn, lo, hi = cmds[argv[1]]
    args = argv[2:]
    if not lo <= len(args) <= hi:
        print(__doc__)
        return 2
    return fn(*args)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
