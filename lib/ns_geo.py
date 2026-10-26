#!/usr/bin/env python3
"""Photo geolocation helpers for northstar-osint (the engine behind ns-geo).

Commands:
  estimate IMAGE [TOP_K]   GeoCLIP location estimate, run on this computer:
                           writes geoclip.csv and prints the candidates
  places [N]               place names for the top N candidates in geoclip.csv
                           (OpenStreetMap Nominatim; sends coordinates only)

GeoCLIP (MIT) predicts likely coordinates from what the scene looks like. It's
often right to the country or region, sometimes the city, rarely the street:
treat every candidate as a lead to verify with street-level imagery.
The image never leaves the computer. The first run downloads the CLIP image
backbone (about 1.7 GB, cached by Hugging Face) after GeoCLIP's own weights.
"""
import csv
import json
import os
import sys
import time
import urllib.parse
import urllib.request

UA = "northstar-osint (+https://github.com/det0xgravity/northstar-osint)"


def cmd_estimate(image, top_k="10"):
    try:
        import torch
        from geoclip import GeoCLIP
    except ImportError:
        print("GeoCLIP isn't installed: ./install.sh --only geo")
        return 1
    torch.set_grad_enabled(False)
    print("Loading GeoCLIP (the first run downloads the model)…", flush=True)
    model = GeoCLIP()
    model.eval()
    gps, prob = model.predict(image, top_k=int(top_k))
    rows = [{"rank": i + 1, "lat": round(float(g[0]), 5), "lon": round(float(g[1]), 5),
             "probability": round(float(p), 4)} for i, (g, p) in enumerate(zip(gps, prob))]
    with open("geoclip.csv", "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    print(f"\nTop {len(rows)} GeoCLIP candidates (leads to verify, not answers):")
    for r in rows:
        print(f"  {r['rank']:>2}. {r['lat']:>9}, {r['lon']:>10}   p={r['probability']}")
    return 0


def cmd_places(n="5"):
    if not os.path.exists("geoclip.csv"):
        print("Run estimate first.")
        return 1
    rows = list(csv.DictReader(open("geoclip.csv", encoding="utf-8")))[: int(n)]
    out = []
    for r in rows:
        url = ("https://nominatim.openstreetmap.org/reverse?format=jsonv2&zoom=10&"
               + urllib.parse.urlencode({"lat": r["lat"], "lon": r["lon"]}))
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "en"})
            with urllib.request.urlopen(req, timeout=20) as resp:
                place = json.load(resp).get("display_name", "?")
        except Exception as exc:                         # network, rate limit
            place = f"(lookup failed: {exc})"
        out.append({**r, "place": place})
        print(f"  {r['rank']:>2}. {r['lat']}, {r['lon']}: {place}")
        time.sleep(1.1)                                  # Nominatim policy: 1 request/second
    with open("places.json", "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=2, ensure_ascii=False)
    return 0


def main(argv):
    if len(argv) >= 3 and argv[1] == "estimate":
        return cmd_estimate(*argv[2:4])
    if len(argv) >= 2 and argv[1] == "places":
        return cmd_places(*argv[2:3])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
