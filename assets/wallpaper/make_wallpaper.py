#!/usr/bin/env python3
"""Generate the truebearing-osint desktop wallpaper (original artwork, GPL-3.0-or-later).

A night chart: a coordinate grid and map contours under a faint aurora. A
compass rose marks true north with a star and magnetic north a few degrees
off it (the difference is what a "true" bearing corrects for). A bearing
from the rose's centre, and back-bearings from two survey (trig) points,
cross at one spot on the hill: a position fix, the way a photo is pinned to
a place. The Canadian touches: aurora borealis, a small maple leaf by the
signature, and the coordinates of Alert, Nunavut, the northernmost
permanently inhabited place on Earth. The output is deterministic, so
re-running it reproduces truebearing.svg exactly.

Usage: python3 assets/wallpaper/make_wallpaper.py
Then render truebearing.png at 3840x2160 (see assets/wallpaper/README.md).
"""
import math
import os
import random

W, H = 3840, 2160
ROSE = (2720, 860)            # compass rose centre
R = 470                       # degree ring radius
DECL = -14                    # magnetic declination, degrees (west)
FIX = (1010, 1560)            # where the bearings cross (summit of the hill)
TRIG = [(250, 520), (1990, 2040)]   # survey points the back-bearings come from
rnd = random.Random(1907)     # fixed seed: stable output

out = []
add = out.append
font = 'font-family="DejaVu Sans Mono, Menlo, Consolas, monospace"'


def f(x):
    return f"{x:.1f}".rstrip("0").rstrip(".")


def polar(c, r, deg):
    """Point at compass bearing `deg` (clockwise from up) and radius r around c."""
    t = math.radians(deg - 90)
    return c[0] + r * math.cos(t), c[1] + r * math.sin(t)


def bearing(a, b):
    return math.degrees(math.atan2(b[0] - a[0], -(b[1] - a[1]))) % 360


add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
add("""<defs>
  <radialGradient id="sky" cx="70%" cy="38%" r="95%">
    <stop offset="0" stop-color="#132447"/>
    <stop offset="0.45" stop-color="#0a1428"/>
    <stop offset="1" stop-color="#04070d"/>
  </radialGradient>
  <radialGradient id="tealglow" cx="26%" cy="74%" r="45%">
    <stop offset="0" stop-color="#0f4a52" stop-opacity="0.5"/>
    <stop offset="1" stop-color="#0f4a52" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="roseglow">
    <stop offset="0" stop-color="#6fb8ff" stop-opacity="0.16"/>
    <stop offset="0.6" stop-color="#6fb8ff" stop-opacity="0.05"/>
    <stop offset="1" stop-color="#6fb8ff" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="starglow">
    <stop offset="0" stop-color="#ffffff" stop-opacity="0.9"/>
    <stop offset="0.2" stop-color="#cfeaff" stop-opacity="0.45"/>
    <stop offset="1" stop-color="#6fb8ff" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="fixglow">
    <stop offset="0" stop-color="#ffcf6b" stop-opacity="0.5"/>
    <stop offset="0.35" stop-color="#ffb347" stop-opacity="0.14"/>
    <stop offset="1" stop-color="#ffb347" stop-opacity="0"/>
  </radialGradient>
  <filter id="soft" x="-20%" y="-50%" width="140%" height="200%">
    <feGaussianBlur stdDeviation="38"/>
  </filter>
  <filter id="softer" x="-10%" y="-50%" width="120%" height="200%">
    <feGaussianBlur stdDeviation="9"/>
  </filter>
  <linearGradient id="curtain" x1="0" y1="1" x2="0" y2="0">
    <stop offset="0" stop-color="#45f0b0" stop-opacity="0.5"/>
    <stop offset="0.35" stop-color="#2fd39a" stop-opacity="0.2"/>
    <stop offset="0.75" stop-color="#7a5cff" stop-opacity="0.07"/>
    <stop offset="1" stop-color="#7a5cff" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="bandfade" gradientUnits="userSpaceOnUse" x1="-100" y1="0" x2="2100" y2="0">
    <stop offset="0" stop-color="#3ee6a8" stop-opacity="0.5"/>
    <stop offset="0.6" stop-color="#3ee6a8" stop-opacity="1"/>
    <stop offset="1" stop-color="#3ee6a8" stop-opacity="0"/>
  </linearGradient>
</defs>""")
add(f'<rect width="{W}" height="{H}" fill="url(#sky)"/>')
add(f'<rect width="{W}" height="{H}" fill="url(#tealglow)"/>')

# Coordinate grid, with small crosses and edge labels like a chart's margin
add('<g stroke="#7fb3d5" stroke-opacity="0.045" stroke-width="2">')
for x in range(0, W + 1, 240):
    add(f'<line x1="{x}" y1="0" x2="{x}" y2="{H}"/>')
for y in range(0, H + 1, 240):
    add(f'<line x1="0" y1="{y}" x2="{W}" y2="{y}"/>')
add("</g>")
add('<g stroke="#7fb3d5" stroke-opacity="0.12" stroke-width="2">')
for x in range(240, W, 480):
    for y in range(240, H, 480):
        add(f'<path d="M{x-10} {y}H{x+10}M{x} {y-10}V{y+10}"/>')
add("</g>")
add(f'<g {font} font-size="18" fill="#7fb3d5" fill-opacity="0.22" letter-spacing="2">')
for i, x in enumerate(range(480, W - 200, 480)):
    add(f'<text x="{x + 8}" y="30">{65.5 - i * 0.5:.1f}°W</text>'.replace(".0°", "°"))   # west: smaller to the east
for i, y in enumerate(range(480, H - 100, 480)):
    add(f'<text x="14" y="{y - 10}">{82.9 - i * 0.2:.1f}°N</text>')
add("</g>")

# Aurora borealis: a blurred band and curtain streaks across the upper left
def aurora_y(x):
    return 600 - 0.09 * x + 60 * math.sin(x / 260) + 30 * math.sin(x / 97 + 1.3)

add('<g filter="url(#soft)">')
band = " L".join(f"{x} {f(aurora_y(x))}" for x in range(-100, 2101, 40))
add(f'<path d="M{band}" fill="none" stroke="url(#bandfade)" stroke-opacity="0.13" stroke-width="130"/>')
add("</g>")
add('<g filter="url(#softer)">')
for x in range(-60, 2100, 10):
    base = aurora_y(x)
    fade = max(0.0, min(1.0, (2100 - x) / 900)) * max(0.0, min(1.0, (x + 60) / 300))
    h = 190 + 140 * (0.5 + 0.5 * math.sin(x / 61 + rnd.uniform(0, 0.6))) * rnd.uniform(0.6, 1.0)
    w = rnd.uniform(4, 9)
    op = fade * rnd.uniform(0.18, 0.45)
    add(f'<rect x="{x}" y="{f(base - h)}" width="{f(w)}" height="{f(h)}" fill="url(#curtain)" opacity="{op:.2f}"/>')
add("</g>")

# Topographic contours around the hill the fix is on
cx, cy = FIX[0] - 40, FIX[1] + 30
harmonics = [(rnd.uniform(0.04, 0.09), n, rnd.uniform(0, math.tau)) for n in (2, 3, 5, 7)]
add('<g fill="none" stroke="#3fb6c4" stroke-width="2.4">')
for i in range(17):
    base = 70 + i * 60
    pts = []
    for k in range(181):
        t = k / 180 * math.tau
        r = base * (1 + sum(a * math.sin(n * t + p + i * 0.07) for a, n, p in harmonics))
        pts.append((cx + r * math.cos(t) * 1.3, cy + r * math.sin(t)))
    d = "M" + " L".join(f"{f(x)} {f(y)}" for x, y in pts) + "Z"
    op = 0.14 - i * 0.0065
    add(f'<path d="{d}" stroke-opacity="{op:.3f}" stroke-width="{3.2 if i % 5 == 4 else 2.2}"/>')
add("</g>")

# Star field, kept clear of the rose
add('<g fill="#e8f2ff">')
for _ in range(460):
    x, y = rnd.uniform(0, W), rnd.uniform(0, H * 0.9)
    if math.hypot(x - ROSE[0], y - ROSE[1]) < R + 140:
        continue
    r = rnd.choice([0.9, 1.1, 1.3, 1.6, 2.0, 2.5]) * (1.0 if y < H * 0.55 else 0.8)
    op = rnd.uniform(0.15, 0.75) * (1.0 if y < H * 0.55 else 0.55)
    add(f'<circle cx="{f(x)}" cy="{f(y)}" r="{r}" fill-opacity="{op:.2f}"/>')
add("</g>")

# Back-bearings from the two trig points, dashed, through the fix and a little past it
for p in TRIG:
    b = bearing(p, FIX)
    end = polar(FIX, 260, b)
    add(f'<path d="M{f(p[0])} {f(p[1])} L{f(end[0])} {f(end[1])}" stroke="#9fd8ff" stroke-opacity="0.24" '
        f'stroke-width="2" stroke-dasharray="14 12" fill="none"/>')
    tri = [polar(p, 22, a) for a in (0, 120, 240)]
    add('<polygon points="' + " ".join(f"{f(x)},{f(y)}" for x, y in tri)
        + '" fill="none" stroke="#cfeaff" stroke-opacity="0.55" stroke-width="2.5"/>')
    add(f'<circle cx="{f(p[0])}" cy="{f(p[1])}" r="3.5" fill="#cfeaff" fill-opacity="0.7"/>')
    lx, ly = polar(p, 120, b)
    anchor = "start"
    add(f'<text x="{f(lx + 22)}" y="{f(ly - 14)}" text-anchor="{anchor}" {font} font-size="20" fill="#9fd8ff" '
        f'fill-opacity="0.42" letter-spacing="3">{b:05.1f}° T</text>')

# The main bearing: from the rose's centre to the fix
B = bearing(ROSE, FIX)
start = polar(ROSE, 60, B)
add(f'<path d="M{f(start[0])} {f(start[1])} L{f(FIX[0])} {f(FIX[1])}" stroke="#ffd58a" stroke-opacity="0.55" '
    f'stroke-width="3" fill="none"/>')
mid = ((ROSE[0] + FIX[0]) / 2, (ROSE[1] + FIX[1]) / 2)
ang = math.degrees(math.atan2(FIX[1] - ROSE[1], FIX[0] - ROSE[0])) + 180    # text reads left to right
add(f'<text x="{f(mid[0])}" y="{f(mid[1] - 22)}" text-anchor="middle" transform="rotate({ang:.2f} {f(mid[0])} {f(mid[1])})" '
    f'{font} font-size="28" fill="#ffd58a" fill-opacity="0.7" letter-spacing="6">BRG {B:05.1f}° T</text>')

# The fix: glow, ring and crosshair where the three lines meet
fx, fy = FIX
add(f'<circle cx="{fx}" cy="{fy}" r="120" fill="url(#fixglow)"/>')
add(f'<g stroke="#ffd58a" fill="none"><circle cx="{fx}" cy="{fy}" r="30" stroke-opacity="0.85" stroke-width="3"/>'
    f'<circle cx="{fx}" cy="{fy}" r="58" stroke-opacity="0.3" stroke-width="2"/>'
    f'<path d="M{fx-80} {fy}H{fx-38}M{fx+38} {fy}H{fx+80}M{fx} {fy-80}V{fy-38}M{fx} {fy+38}V{fy+80}" '
    f'stroke-opacity="0.7" stroke-width="2.5"/></g>')
add(f'<circle cx="{fx}" cy="{fy}" r="6" fill="#fff1d6"/>')
add(f'<text x="{fx + 96}" y="{fy + 66}" {font} font-size="22" fill="#ffd58a" fill-opacity="0.55" letter-spacing="6">FIX</text>')

# Compass rose
rx, ry = ROSE
add(f'<circle cx="{rx}" cy="{ry}" r="{R + 160}" fill="url(#roseglow)"/>')
add('<g stroke="#9fd8ff" fill="none">')
add(f'<circle cx="{rx}" cy="{ry}" r="{R}" stroke-opacity="0.3" stroke-width="2.5"/>')
add(f'<circle cx="{rx}" cy="{ry}" r="{R - 46}" stroke-opacity="0.12" stroke-width="1.5"/>')
add(f'<circle cx="{rx}" cy="{ry}" r="{R * 0.42:.0f}" stroke-opacity="0.12" stroke-width="1.5"/>')
for deg in range(360):
    if deg % 10 == 0:
        r2, op, w = R - 34, 0.45, 2.5
    elif deg % 5 == 0:
        r2, op, w = R - 22, 0.3, 2
    else:
        r2, op, w = R - 12, 0.16, 1.5
    x1, y1 = polar(ROSE, R, deg)
    x2, y2 = polar(ROSE, r2, deg)
    add(f'<line x1="{f(x1)}" y1="{f(y1)}" x2="{f(x2)}" y2="{f(y2)}" stroke-opacity="{op}" stroke-width="{w}"/>')
add("</g>")
add(f'<g {font} font-size="22" fill="#cfeaff" fill-opacity="0.5" text-anchor="middle" letter-spacing="1">')
for deg in range(30, 360, 30):
    x, y = polar(ROSE, R + 40, deg)
    add(f'<text x="{f(x)}" y="{f(y + 8)}" transform="rotate({deg} {f(x)} {f(y)})">{deg:03d}</text>')
add("</g>")

# The rose's points: cardinals long, intercardinals short, each split light/dark
def point(deg, length, width, light, dark):
    tip = polar(ROSE, length, deg)
    left = polar(ROSE, width, deg - 45)
    right = polar(ROSE, width, deg + 45)
    add(f'<polygon points="{f(rx)},{f(ry)} {f(left[0])},{f(left[1])} {f(tip[0])},{f(tip[1])}" fill="{light}"/>')
    add(f'<polygon points="{f(rx)},{f(ry)} {f(tip[0])},{f(tip[1])} {f(right[0])},{f(right[1])}" fill="{dark}"/>')

add('<g fill-opacity="0.5">')
for d in (45, 135, 225, 315):
    point(d, R * 0.56, 34, "#7fa9cc", "#2c4866")
for d in (90, 180, 270):
    point(d, R - 60, 48, "#a9cde8", "#3a5f82")
add("</g>")
point(0, R - 60, 48, "#e8f4ff", "#8fb6d8")                 # true north, brighter
add(f'<circle cx="{rx}" cy="{ry}" r="16" fill="#0a1428" stroke="#cfeaff" stroke-opacity="0.7" stroke-width="3"/>')
add(f'<circle cx="{rx}" cy="{ry}" r="5" fill="#ffffff"/>')

# True north: a star just outside the ring; magnetic north: an arrow at the declination
tx, ty = polar(ROSE, R + 96, 0)
add(f'<circle cx="{f(tx)}" cy="{f(ty)}" r="70" fill="url(#starglow)"/>')
s = [polar((tx, ty), 34 if i % 2 == 0 else 9, i * 45) for i in range(8)]
add('<polygon points="' + " ".join(f"{f(x)},{f(y)}" for x, y in s) + '" fill="#ffffff"/>')
add(f'<text x="{f(tx + 56)}" y="{f(ty + 10)}" {font} font-size="26" fill="#e8f4ff" fill-opacity="0.75" letter-spacing="3">TN</text>')
mx1, my1 = polar(ROSE, R * 0.46, DECL)
mx2, my2 = polar(ROSE, R + 70, DECL)
add(f'<line x1="{f(mx1)}" y1="{f(my1)}" x2="{f(mx2)}" y2="{f(my2)}" stroke="#ff8f8f" stroke-opacity="0.6" '
    f'stroke-width="2.5" stroke-dasharray="10 8"/>')
head = [polar((mx2, my2), 0, DECL), polar(ROSE, R + 40, DECL - 2.2), polar(ROSE, R + 40, DECL + 2.2)]
head[0] = polar(ROSE, R + 84, DECL)
add('<polygon points="' + " ".join(f"{f(x)},{f(y)}" for x, y in head) + '" fill="#ff8f8f" fill-opacity="0.75"/>')
lx, ly = polar(ROSE, R + 120, DECL - 3)
add(f'<text x="{f(lx)}" y="{f(ly)}" text-anchor="end" {font} font-size="22" fill="#ff8f8f" fill-opacity="0.6" '
    f'letter-spacing="3">MN {abs(DECL)}°W</text>')
# The declination arc between them
a0, a1 = DECL, 0
p0, p1 = polar(ROSE, R + 18, a0), polar(ROSE, R + 18, a1)
add(f'<path d="M{f(p0[0])} {f(p0[1])} A{R + 18} {R + 18} 0 0 1 {f(p1[0])} {f(p1[1])}" fill="none" '
    f'stroke="#ffb3b3" stroke-opacity="0.45" stroke-width="2"/>')

# Signature
add(f'<text x="{W - 110}" y="{H - 96}" text-anchor="end" {font} font-size="36" '
    f'fill="#9fd8ff" fill-opacity="0.4" letter-spacing="8">truebearing-osint</text>')
add(f'<text x="{W - 110}" y="{H - 52}" text-anchor="end" {font} font-size="22" '
    f'fill="#9fd8ff" fill-opacity="0.24" letter-spacing="4">82° 30′ N · 62° 20′ W · ALERT, NUNAVUT</text>')

# A small stylised maple leaf (drawn for this project: right half, mirrored)
half = [(0, -1.0), (0.12, -0.70), (0.30, -0.80), (0.22, -0.40), (0.62, -0.62),
        (0.53, -0.35), (0.80, -0.28), (0.46, -0.04), (0.56, 0.12), (0.20, 0.14),
        (0.24, 0.36), (0.045, 0.30), (0.045, 0.66)]
leaf = half + [(-x, y) for x, y in reversed(half[1:])]
lx, ly, ls = W - 110 - 760, H - 84, 40           # left of both signature lines
pts = " ".join(f"{f(lx + x * ls)},{f(ly + y * ls)}" for x, y in leaf)
add(f'<polygon points="{pts}" fill="#e0525a" fill-opacity="0.55"/>')
add("</svg>")

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "truebearing.svg")
with open(path, "w", encoding="utf-8") as fh:
    fh.write("\n".join(out) + "\n")
print(f"wrote {path}")
