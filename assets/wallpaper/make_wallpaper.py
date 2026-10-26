#!/usr/bin/env python3
"""Generate the northstar-osint desktop wallpaper (original artwork, MIT).

A night sky with map contours and a coordinate grid: the pointer stars of a
stylised dipper lead to a north star inside a compass ring. The Canadian
touches: aurora borealis curtains, a small maple leaf by the signature, and
the coordinates of Alert, Nunavut, the northernmost permanently inhabited
place on Earth. The output is
deterministic, so re-running it reproduces northstar.svg exactly.

Usage: python3 assets/wallpaper/make_wallpaper.py
Then render northstar.png at 3840x2160 (see assets/wallpaper/README.md).
"""
import math
import os
import random

W, H = 3840, 2160
STAR = (2660, 640)            # the north star
RING = 330                    # compass ring radius
rnd = random.Random(1907)     # fixed seed: stable output

out = []
add = out.append


def f(x):
    return f"{x:.1f}".rstrip("0").rstrip(".")


add(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
add("""<defs>
  <radialGradient id="sky" cx="68%" cy="28%" r="95%">
    <stop offset="0" stop-color="#15254a"/>
    <stop offset="0.45" stop-color="#0a1326"/>
    <stop offset="1" stop-color="#04060c"/>
  </radialGradient>
  <radialGradient id="tealglow" cx="18%" cy="88%" r="55%">
    <stop offset="0" stop-color="#0f4a52" stop-opacity="0.45"/>
    <stop offset="1" stop-color="#0f4a52" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="starglow">
    <stop offset="0" stop-color="#ffffff" stop-opacity="0.9"/>
    <stop offset="0.12" stop-color="#cfeaff" stop-opacity="0.55"/>
    <stop offset="0.45" stop-color="#6fb8ff" stop-opacity="0.12"/>
    <stop offset="1" stop-color="#6fb8ff" stop-opacity="0"/>
  </radialGradient>
  <filter id="soft" x="-20%" y="-50%" width="140%" height="200%">
    <feGaussianBlur stdDeviation="38"/>
  </filter>
  <filter id="softer" x="-10%" y="-50%" width="120%" height="200%">
    <feGaussianBlur stdDeviation="9"/>
  </filter>
  <linearGradient id="curtain" x1="0" y1="1" x2="0" y2="0">
    <stop offset="0" stop-color="#45f0b0" stop-opacity="0.55"/>
    <stop offset="0.35" stop-color="#2fd39a" stop-opacity="0.22"/>
    <stop offset="0.75" stop-color="#7a5cff" stop-opacity="0.08"/>
    <stop offset="1" stop-color="#7a5cff" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="bandfade" gradientUnits="userSpaceOnUse" x1="-100" y1="0" x2="2250" y2="0">
    <stop offset="0" stop-color="#3ee6a8" stop-opacity="0.5"/>
    <stop offset="0.6" stop-color="#3ee6a8" stop-opacity="1"/>
    <stop offset="1" stop-color="#3ee6a8" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="bandfadev" gradientUnits="userSpaceOnUse" x1="-100" y1="0" x2="2250" y2="0">
    <stop offset="0" stop-color="#7a5cff" stop-opacity="0.6"/>
    <stop offset="0.55" stop-color="#7a5cff" stop-opacity="1"/>
    <stop offset="1" stop-color="#7a5cff" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="rayv" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#cfeaff" stop-opacity="0"/>
    <stop offset="0.5" stop-color="#ffffff" stop-opacity="0.95"/>
    <stop offset="1" stop-color="#cfeaff" stop-opacity="0"/>
  </linearGradient>
  <linearGradient id="rayh" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#cfeaff" stop-opacity="0"/>
    <stop offset="0.5" stop-color="#ffffff" stop-opacity="0.9"/>
    <stop offset="1" stop-color="#cfeaff" stop-opacity="0"/>
  </linearGradient>
</defs>""")
add(f'<rect width="{W}" height="{H}" fill="url(#sky)"/>')
add(f'<rect width="{W}" height="{H}" fill="url(#tealglow)"/>')

# Coordinate grid: faint meridians and parallels with small tick marks
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

# Aurora borealis: a blurred glow band plus vertical curtain streaks rising
# from a wavy baseline across the upper left of the sky
def aurora_y(x):
    return 760 - 0.10 * x + 70 * math.sin(x / 260) + 35 * math.sin(x / 97 + 1.3)

add('<g filter="url(#soft)">')
band = " L".join(f"{x} {f(aurora_y(x))}" for x in range(-100, 2251, 40))
add(f'<path d="M{band}" fill="none" stroke="url(#bandfade)" stroke-opacity="0.17" stroke-width="140"/>')
band2 = " L".join(f"{x} {f(aurora_y(x) - 170)}" for x in range(-100, 2251, 40))
add(f'<path d="M{band2}" fill="none" stroke="url(#bandfadev)" stroke-opacity="0.08" stroke-width="160"/>')
add("</g>")
add('<g filter="url(#softer)">')
for x in range(-60, 2250, 9):
    base = aurora_y(x)
    fade = max(0.0, min(1.0, (2250 - x) / 950)) * max(0.0, min(1.0, (x + 60) / 300))
    h = 220 + 160 * (0.5 + 0.5 * math.sin(x / 61 + rnd.uniform(0, 0.6))) * rnd.uniform(0.6, 1.0)
    w = rnd.uniform(4, 9)
    op = fade * rnd.uniform(0.25, 0.6)
    add(f'<rect x="{x}" y="{f(base - h)}" width="{f(w)}" height="{f(h)}" fill="url(#curtain)" opacity="{op:.2f}"/>')
add("</g>")

# Topographic contours around a low "hill" in the lower left
cx, cy = 820, 1640
harmonics = [(rnd.uniform(0.04, 0.09), n, rnd.uniform(0, math.tau)) for n in (2, 3, 5, 7)]
add('<g fill="none" stroke="#3fb6c4" stroke-width="2.4">')
for i in range(16):
    base = 110 + i * 62
    pts = []
    for k in range(181):
        t = k / 180 * math.tau
        r = base * (1 + sum(a * math.sin(n * t + p + i * 0.07) for a, n, p in harmonics))
        pts.append((cx + r * math.cos(t) * 1.25, cy + r * math.sin(t)))
    d = "M" + " L".join(f"{f(x)} {f(y)}" for x, y in pts) + "Z"
    op = 0.13 - i * 0.006
    add(f'<path d="{d}" stroke-opacity="{op:.3f}"/>')
add("</g>")

# Star field (kept sparse near the north star so it stands out)
add('<g fill="#e8f2ff">')
for _ in range(520):
    x, y = rnd.uniform(0, W), rnd.uniform(0, H * 0.92)
    if math.hypot(x - STAR[0], y - STAR[1]) < RING + 40:
        continue
    r = rnd.choice([0.9, 1.1, 1.3, 1.6, 2.0, 2.6]) * (1.0 if y < H * 0.6 else 0.8)
    op = rnd.uniform(0.18, 0.85) * (1.0 if y < H * 0.6 else 0.6)
    add(f'<circle cx="{f(x)}" cy="{f(y)}" r="{r}" fill-opacity="{op:.2f}"/>')
add("</g>")

# A stylised dipper: its two "pointer" stars (the bowl's outer edge) line up
# with the north star, as they do in the real sky, with a dashed guide line
ux, uy = STAR[0] - 2050, STAR[1] - 1290
n = math.hypot(ux, uy); ux, uy = ux / n, uy / n
B = (2050, 1290)                                  # lower pointer
A = (B[0] + 150 * ux, B[1] + 150 * uy)            # upper pointer, toward the star
C = (A[0] - 255, A[1] + 45)                       # bowl, handle side
D = (B[0] - 240, B[1] + 70)
handle = [(C[0] - 175, C[1] - 25), (C[0] - 330, C[1] + 20), (C[0] - 500, C[1] - 45)]
outline = list(reversed(handle)) + [C, A, B, D, C]
add('<g stroke="#9fd8ff" stroke-opacity="0.18" stroke-width="2" fill="none">')
add('<path d="M' + " L".join(f"{f(x)} {f(y)}" for x, y in outline) + '"/>')
end = (STAR[0] - ux * (RING + 40), STAR[1] - uy * (RING + 40))
add(f'<path d="M{f(A[0] + ux * 30)} {f(A[1] + uy * 30)} L{f(end[0])} {f(end[1])}" '
    f'stroke-dasharray="4 16" stroke-opacity="0.22"/>')
add("</g>")
add('<g fill="#f2f8ff">')
for x, y in [A, B, C, D] + handle:
    add(f'<circle cx="{f(x)}" cy="{f(y)}" r="4.4" fill-opacity="0.88"/>')
    add(f'<circle cx="{f(x)}" cy="{f(y)}" r="14" fill-opacity="0.06"/>')
add("</g>")

# Compass ring with degree ticks around the north star
sx, sy = STAR
add(f'<g stroke="#9fd8ff" fill="none"><circle cx="{sx}" cy="{sy}" r="{RING}" stroke-opacity="0.16" stroke-width="2"/>')
add(f'<circle cx="{sx}" cy="{sy}" r="{RING - 28}" stroke-opacity="0.07" stroke-width="1.5"/>')
for deg in range(0, 360, 5):
    t = math.radians(deg - 90)
    long_tick = deg % 30 == 0
    r1, r2 = RING, RING + (26 if long_tick else 12)
    op = 0.32 if long_tick else 0.16
    add(f'<line x1="{f(sx + r1 * math.cos(t))}" y1="{f(sy + r1 * math.sin(t))}" '
        f'x2="{f(sx + r2 * math.cos(t))}" y2="{f(sy + r2 * math.sin(t))}" '
        f'stroke-opacity="{op}" stroke-width="{2.5 if long_tick else 1.5}"/>')
add("</g>")
font = 'font-family="DejaVu Sans Mono, Menlo, Consolas, monospace"'
add(f'<text x="{sx}" y="{sy - RING - 44}" text-anchor="middle" {font} font-size="44" '
    f'fill="#cfeaff" fill-opacity="0.6" letter-spacing="2">N</text>')

# The north star: glow, long cardinal rays, short diagonal rays, bright core
add(f'<circle cx="{sx}" cy="{sy}" r="190" fill="url(#starglow)"/>')
add(f'<polygon points="{sx},{sy-300} {sx+7},{sy} {sx},{sy+300} {sx-7},{sy}" fill="url(#rayv)"/>')
add(f'<polygon points="{sx-230},{sy} {sx},{sy-6} {sx+230},{sy} {sx},{sy+6}" fill="url(#rayh)"/>')
d = 70
add(f'<g stroke="#e8f4ff" stroke-opacity="0.5" stroke-width="2.5" stroke-linecap="round">'
    f'<line x1="{sx-d}" y1="{sy-d}" x2="{sx+d}" y2="{sy+d}"/>'
    f'<line x1="{sx-d}" y1="{sy+d}" x2="{sx+d}" y2="{sy-d}"/></g>')
add(f'<circle cx="{sx}" cy="{sy}" r="11" fill="#ffffff"/>')

# Signature
add(f'<text x="{W - 110}" y="{H - 96}" text-anchor="end" {font} font-size="36" '
    f'fill="#9fd8ff" fill-opacity="0.38" letter-spacing="8">northstar-osint</text>')
add(f'<text x="{W - 110}" y="{H - 52}" text-anchor="end" {font} font-size="22" '
    f'fill="#9fd8ff" fill-opacity="0.24" letter-spacing="4">82° 30′ N · 62° 20′ W · ALERT, NUNAVUT</text>')

# A small stylised maple leaf (drawn for this project: right half, mirrored)
half = [(0, -1.0), (0.12, -0.70), (0.30, -0.80), (0.22, -0.40), (0.62, -0.62),
        (0.53, -0.35), (0.80, -0.28), (0.46, -0.04), (0.56, 0.12), (0.20, 0.14),
        (0.24, 0.36), (0.045, 0.30), (0.045, 0.66)]
leaf = half + [(-x, y) for x, y in reversed(half[1:])]
lx, ly, ls = W - 110 - 720, H - 84, 40           # left of both signature lines
pts = " ".join(f"{f(lx + x * ls)},{f(ly + y * ls)}" for x, y in leaf)
add(f'<polygon points="{pts}" fill="#e0525a" fill-opacity="0.55"/>')
add("</svg>")

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "northstar.svg")
with open(path, "w", encoding="utf-8") as fh:
    fh.write("\n".join(out) + "\n")
print(f"wrote {path}")
