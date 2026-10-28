#!/usr/bin/env python3
"""Case map for truebearing-osint (the engine behind tb-map).

Commands:
  add CASEDIR KIND LAT LON LABEL [WHEN]   record a place (last seen, sighting, home…)
  geocode QUERY                           address → "lat<TAB>lon<TAB>name" (OpenStreetMap Nominatim)
  list CASEDIR
  build CASEDIR OUTDIR                    gather every coordinate and write the map

The map gathers places you've recorded (CASEDIR/map/places.csv), GPS from photo
EXIF anywhere in the case, and GeoCLIP estimates from Photo geolocation
(geoclip.csv, with place names from places.json). It writes case.geojson and
case.kml (QGIS, Google Earth) and map.html. The files work offline; map.html
loads Leaflet and map tiles from the internet when opened.
"""
import csv
import datetime
import getpass
import hashlib
import html
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.parse
import urllib.request

UA = "truebearing-osint (https://github.com/det0xgravity/truebearing-osint)"
KINDS = ["last seen", "sighting", "home", "work or school", "vehicle", "other"]
COLOURS = {"last seen": "#e5484d", "sighting": "#f76b15", "home": "#30a46c", "work or school": "#0090ff",
           "vehicle": "#8e4ec6", "other": "#6e6e6e", "photo GPS": "#ffc53d", "AI estimate": "#12a594"}
FIELDS = ["kind", "lat", "lon", "label", "when_utc", "added_utc", "source"]


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def audit(case_dir, tool, target, detail):
    """Same format and hash chain as tb_audit in lib/ui.sh."""
    log = os.path.join(case_dir, "audit.log")
    clean = lambda s: re.sub(r"[\t\r\n]", " ", str(s))
    body = "\t".join([utc_now(), os.path.basename(os.path.abspath(case_dir)), clean(tool), clean(target),
                      clean(detail), getpass.getuser()])
    prev = ""
    if os.path.exists(log) and os.path.getsize(log):
        with open(log, "rb") as fh:
            fh.seek(max(0, os.path.getsize(log) - 65536))
            prev = fh.read().decode("utf-8", "replace").rstrip("\n").split("\n")[-1]
    with open(log, "a", encoding="utf-8") as fh:
        fh.write(f"{body}\t{hashlib.sha256((prev + body).encode('utf-8')).hexdigest()}\n")


def coord(lat, lon):
    lat, lon = float(lat), float(lon)
    if not (-90 <= lat <= 90 and -180 <= lon <= 180) or (lat == 0 and lon == 0):
        raise ValueError("out of range")
    return round(lat, 6), round(lon, 6)


def places_file(case_dir):
    d = os.path.join(case_dir, "map")
    os.makedirs(d, mode=0o700, exist_ok=True)
    return os.path.join(d, "places.csv")


def cmd_add(case_dir, kind, lat, lon, label, when=""):
    try:
        lat, lon = coord(lat, lon)
    except ValueError:
        print("Coordinates must be decimal latitude and longitude, for example 45.4215, -75.6972.")
        return 1
    p = places_file(case_dir)
    new = not os.path.exists(p)
    with open(p, "a", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=FIELDS)
        if new:
            w.writeheader()
        w.writerow({"kind": kind, "lat": lat, "lon": lon, "label": label, "when_utc": when,
                    "added_utc": utc_now(), "source": "recorded"})
    audit(case_dir, "tb-map", f"{lat},{lon}", f"place added: {kind}: {label}")
    print(f"Added {kind}: {label} ({lat}, {lon})")
    return 0


def cmd_geocode(query):
    url = "https://nominatim.openstreetmap.org/search?" + urllib.parse.urlencode(
        {"q": query, "format": "jsonv2", "limit": 1})
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept-Language": "en"})
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            hits = json.load(resp)
    except Exception as exc:
        print(f"Lookup failed: {exc}", file=sys.stderr)
        return 1
    if not hits:
        print("No match: try a fuller address, or enter coordinates.", file=sys.stderr)
        return 1
    print(f"{float(hits[0]['lat']):.6f}\t{float(hits[0]['lon']):.6f}\t{hits[0].get('display_name', '')}")
    return 0


def gather(case_dir, out_dir):
    pts = []
    p = os.path.join(case_dir, "map", "places.csv")
    if os.path.exists(p):
        for r in csv.DictReader(open(p, encoding="utf-8")):
            pts.append({**r, "lat": float(r["lat"]), "lon": float(r["lon"])})
    skip = os.path.abspath(out_dir)
    # GeoCLIP estimates (top 3 per photo), named from places.json where available
    for root, dirs, files in os.walk(case_dir):
        if os.path.abspath(root).startswith(skip) or "geoclip.csv" not in files:
            continue
        names = {}
        pj = os.path.join(root, "places.json")
        if os.path.exists(pj):
            try:
                names = {str(x.get("rank")): x.get("place", "") for x in json.load(open(pj, encoding="utf-8"))}
            except ValueError:
                pass
        photo = next((f for f in sorted(files) if f.startswith("searched_") or f.startswith("photo")), "")
        for r in list(csv.DictReader(open(os.path.join(root, "geoclip.csv"), encoding="utf-8")))[:3]:
            try:
                lat, lon = coord(r["lat"], r["lon"])
            except (ValueError, KeyError):
                continue
            pts.append({"kind": "AI estimate", "lat": lat, "lon": lon,
                        "label": f"GeoCLIP #{r.get('rank')} (p={r.get('probability')}) {names.get(str(r.get('rank')), '')}".strip(),
                        "when_utc": "", "source": os.path.relpath(os.path.join(root, photo or "geoclip.csv"), case_dir)})
    # GPS in photo and video EXIF
    if shutil.which("exiftool"):
        try:
            out = subprocess.run(["exiftool", "-r", "-json", "-n", "-q", "-q", "-i", out_dir,
                                  "-GPSLatitude", "-GPSLongitude", "-DateTimeOriginal", "-CreateDate",
                                  "-if", "$GPSLatitude and $GPSLongitude", case_dir],
                                 capture_output=True, text=True, timeout=600).stdout
            for j in json.loads(out or "[]"):
                try:
                    lat, lon = coord(j["GPSLatitude"], j["GPSLongitude"])
                except (ValueError, KeyError, TypeError):
                    continue
                rel = os.path.relpath(j["SourceFile"], case_dir)
                if rel.startswith("..") or os.path.abspath(j["SourceFile"]).startswith(skip):
                    continue
                pts.append({"kind": "photo GPS", "lat": lat, "lon": lon, "label": os.path.basename(rel),
                            "when_utc": str(j.get("DateTimeOriginal") or j.get("CreateDate") or "") + " (camera clock)"
                            if (j.get("DateTimeOriginal") or j.get("CreateDate")) else "", "source": rel})
        except (subprocess.SubprocessError, ValueError, OSError):
            pass
    return pts


def kml_doc(pts):
    marks = "".join(
        f"<Placemark><name>{html.escape(p['kind'])}: {html.escape(p['label'])}</name>"
        f"<description>{html.escape(p.get('when_utc') or '')} {html.escape(p.get('source') or '')}</description>"
        f"<Point><coordinates>{p['lon']},{p['lat']},0</coordinates></Point></Placemark>" for p in pts)
    return ('<?xml version="1.0" encoding="UTF-8"?>\n<kml xmlns="http://www.opengis.net/kml/2.2"><Document>'
            f"<name>Case map</name>{marks}</Document></kml>\n")


PAGE = """<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src https://unpkg.com 'unsafe-inline'; style-src https://unpkg.com 'unsafe-inline'; img-src https://*.basemaps.cartocdn.com https://tile.openstreetmap.org https://unpkg.com data:">
<title>Case map: __CASE__</title>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="">
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js" integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
<style>html,body{height:100%;margin:0;font:13px system-ui,sans-serif} #map{position:absolute;top:0;bottom:0;left:0;right:0}
.legend{background:#fff;padding:6px 8px;border-radius:4px;line-height:1.6} .legend i{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:5px}</style>
</head><body><div id="map"></div><script>
const pts = __POINTS__, colours = __COLOURS__;
const map = L.map('map');
const voyager = L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
  {maxZoom: 19, attribution: '&copy; OpenStreetMap contributors &copy; CARTO'}).addTo(map);
const osm = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  {maxZoom: 19, attribution: '&copy; OpenStreetMap contributors'});
const groups = {};
for (const p of pts) {
  const g = groups[p.kind] || (groups[p.kind] = L.featureGroup().addTo(map));
  L.circleMarker([p.lat, p.lon], {radius: 7, color: '#222', weight: 1, fillColor: colours[p.kind] || '#6e6e6e', fillOpacity: .9})
    .bindPopup(p.popup).addTo(g);
}
const overlays = {};
for (const k in groups) overlays['<i style="background:' + (colours[k] || '#6e6e6e') + ';display:inline-block;width:10px;height:10px;border-radius:50%"></i> ' + k + ' (' + groups[k].getLayers().length + ')'] = groups[k];
L.control.layers({'Streets (CARTO)': voyager, 'OpenStreetMap': osm}, overlays, {collapsed: false}).addTo(map);
L.control.scale().addTo(map);
const all = L.featureGroup(Object.values(groups));
if (pts.length) map.fitBounds(all.getBounds().pad(0.2), {maxZoom: 15}); else map.setView([20, 0], 2);
</script></body></html>
"""


def cmd_build(case_dir, out_dir):
    pts = gather(case_dir, out_dir)
    for p in pts:
        p["popup"] = (f"<b>{html.escape(p['kind'])}</b><br>{html.escape(p['label'])}<br>"
                      f"{html.escape(p.get('when_utc') or '')}<br><small>{html.escape(p.get('source') or '')}<br>"
                      f"{p['lat']}, {p['lon']}</small>")
    feats = [{"type": "Feature", "geometry": {"type": "Point", "coordinates": [p["lon"], p["lat"]]},
              "properties": {k: p.get(k, "") for k in ("kind", "label", "when_utc", "source")}} for p in pts]
    with open(os.path.join(out_dir, "case.geojson"), "w", encoding="utf-8") as fh:
        json.dump({"type": "FeatureCollection", "features": feats}, fh, indent=1, ensure_ascii=False)
    with open(os.path.join(out_dir, "case.kml"), "w", encoding="utf-8") as fh:
        fh.write(kml_doc(pts))
    with open(os.path.join(out_dir, "points.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["kind", "lat", "lon", "label", "when_utc", "source"], extrasaction="ignore")
        w.writeheader()
        w.writerows(pts)
    safe = lambda o: json.dumps(o, ensure_ascii=False).replace("</", "<\\/")
    page = (PAGE.replace("__CASE__", html.escape(os.path.basename(os.path.abspath(case_dir))))
            .replace("__COLOURS__", safe(COLOURS))
            .replace("__POINTS__", safe([{k: p[k] for k in ("kind", "lat", "lon", "popup")} for p in pts])))
    with open(os.path.join(out_dir, "map.html"), "w", encoding="utf-8") as fh:
        fh.write(page)
    counts = {}
    for p in pts:
        counts[p["kind"]] = counts.get(p["kind"], 0) + 1
    print(f"{len(pts)} places on the map" + (": " + ", ".join(f"{v} {k}" for k, v in counts.items()) if pts else
          ". Record places, or collect photos with GPS, first."))
    return 0


def cmd_list(case_dir):
    p = os.path.join(case_dir, "map", "places.csv")
    rows = list(csv.DictReader(open(p, encoding="utf-8"))) if os.path.exists(p) else []
    for r in rows:
        print(f"{r['kind']}: {r['label']} ({r['lat']}, {r['lon']}) {r['when_utc']}".rstrip())
    if not rows:
        print("No places recorded in this case yet.")
    return 0


def main(argv):
    cmds = {"add": (cmd_add, 5, 6), "geocode": (cmd_geocode, 1, 1), "list": (cmd_list, 1, 1),
            "build": (cmd_build, 2, 2)}
    if len(argv) < 2 or argv[1] not in cmds or not cmds[argv[1]][1] <= len(argv) - 2 <= cmds[argv[1]][2]:
        print(__doc__)
        return 2
    return cmds[argv[1]][0](*argv[2:])


if __name__ == "__main__":
    sys.exit(main(sys.argv))
