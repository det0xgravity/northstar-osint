#!/usr/bin/env python3
"""Same-photo finder for truebearing-osint (perceptual hashing, run locally).

Usage:
  tb_photomatch.py groups FOLDER OUTDIR          every set of near-identical photos
  tb_photomatch.py find PHOTO FOLDER OUTDIR      photos in FOLDER that are this photo

Perceptual hashes (pHash and dHash, from the imagehash library) survive
resizing, recompression, format changes and light edits, so the same picture
posted on different accounts or sites is found even when the files differ.
Heavy crops, mirroring and overlays defeat them. Nothing is uploaded.
"""
import csv
import html
import os
import sys

from PIL import Image, ImageOps
import imagehash

EXT = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".tif", ".tiff"}
LIMIT = 10          # combined pHash + dHash distance (out of 128) treated as the same photo


def hashes(path):
    try:
        with Image.open(path) as im:
            im = ImageOps.exif_transpose(im).convert("RGB")
            return imagehash.phash(im), imagehash.dhash(im), im.size
    except Exception:                       # unreadable or not really an image
        return None


def images(folder, skip):
    for root, dirs, files in os.walk(folder):
        if os.path.abspath(root).startswith(skip):
            continue
        for n in sorted(files):
            if os.path.splitext(n)[1].lower() in EXT:
                yield os.path.join(root, n)


def card(path, base, note):
    rel = os.path.relpath(path, base)
    return (f'<div class="c"><img src="{html.escape(rel)}" loading="lazy"><small>{html.escape(note)}<br>'
            f'{html.escape(os.path.relpath(path, os.path.dirname(base)))}</small></div>')


PAGE = """<!doctype html><meta charset="utf-8"><title>{title}</title><style>
body{{font:14px system-ui;margin:16px}} .g{{border-top:2px solid #888;padding:8px 0}}
.c{{display:inline-block;width:190px;margin:4px;vertical-align:top}} img{{max-width:180px;max-height:180px;display:block}}
</style><h1>{title}</h1><p>{intro}</p>{body}"""


def cmd_groups(folder, out):
    skip = os.path.abspath(out)
    items = [(p, h) for p in images(folder, skip) if (h := hashes(p))]
    parent = list(range(len(items)))

    def root(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            a, b = items[i][1], items[j][1]
            if (a[0] - b[0]) + (a[1] - b[1]) <= LIMIT:
                parent[root(j)] = root(i)
    groups = {}
    for i in range(len(items)):
        groups.setdefault(root(i), []).append(i)
    multi = sorted((g for g in groups.values() if len(g) > 1), key=len, reverse=True)
    rows, body = [], []
    for n, g in enumerate(multi, 1):
        cards = []
        for i in g:
            p, (ph, dh, size) = items[i]
            rows.append({"group": n, "file": os.path.relpath(p, folder), "width": size[0], "height": size[1],
                         "phash": str(ph), "dhash": str(dh)})
            cards.append(card(p, out, f"{size[0]}×{size[1]}"))
        body.append(f'<div class="g"><b>Group {n}: {len(g)} copies</b><br>{"".join(cards)}</div>')
    with open(os.path.join(out, "same_photos.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["group", "file", "width", "height", "phash", "dhash"])
        w.writeheader()
        w.writerows(rows)
    with open(os.path.join(out, "same_photos.html"), "w", encoding="utf-8") as fh:
        fh.write(PAGE.format(title="Same photo, different places", body="".join(body),
                             intro="Each group is one picture found in several places in the case: often a sign that accounts or "
                                   "posts are connected. The largest version is usually closest to the original."))
    print(f"Hashed {len(items)} images: {len(multi)} groups of the same photo ({sum(len(g) for g in multi)} files).")
    for n, g in enumerate(multi[:10], 1):
        print(f"  group {n}: " + ", ".join(os.path.relpath(items[i][0], folder) for i in g[:4]) + (" …" if len(g) > 4 else ""))
    return 0


def cmd_find(photo, folder, out):
    ref = hashes(photo)
    if not ref:
        print("That file couldn't be read as an image.")
        return 1
    skip = os.path.abspath(out)
    hits = []
    for p in images(folder, skip):
        h = hashes(p)
        if h and os.path.abspath(p) != os.path.abspath(photo):
            d = (ref[0] - h[0]) + (ref[1] - h[1])
            if d <= LIMIT * 2:
                hits.append((d, p, h[2]))
    hits.sort()
    with open(os.path.join(out, "same_photos.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["distance", "verdict", "file", "width", "height"])
        for d, p, size in hits:
            w.writerow([d, "same photo" if d <= LIMIT else "possibly edited copy", os.path.relpath(p, folder), *size])
    cards = "".join(card(p, out, f"distance {d} · {'same photo' if d <= LIMIT else 'possibly edited copy'}")
                    for d, p, _ in hits)
    with open(os.path.join(out, "same_photos.html"), "w", encoding="utf-8") as fh:
        fh.write(PAGE.format(title="Where else this photo appears", body=f'<div class="g">{card(photo, out, "the photo")}</div><div class="g">{cards}</div>',
                             intro="Distance 0 is identical; up to 10 is the same picture resized or recompressed; up to 20 may be an edited copy."))
    same = sum(1 for d, *_ in hits if d <= LIMIT)
    print(f"{same} copies of this photo, {len(hits) - same} possibly edited copies.")
    for d, p, _ in hits[:10]:
        print(f"  {d:>3}  {os.path.relpath(p, folder)}")
    return 0


def main(argv):
    if len(argv) == 4 and argv[1] == "groups":
        return cmd_groups(argv[2], argv[3])
    if len(argv) == 5 and argv[1] == "find":
        return cmd_find(*argv[2:5])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
