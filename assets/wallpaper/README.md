# Wallpaper

`truebearing.png` (3840×2160) is the desktop background that the `desktop` module
sets on GNOME and XFCE, but only if you're still using the distribution's default
background. It's original artwork made for this project and covered by the
repository's license (GPL-3.0-or-later):

- a night chart: a coordinate grid and map contours under a faint aurora
- a compass rose with true north marked by a star and magnetic north 14° off it,
  the difference a *true* bearing corrects for
- a bearing from the rose and back-bearings from two survey (trig) points that
  cross at one spot on the hill: a position fix, the way a photo is pinned to a place
- Canadian touches: aurora borealis, a maple leaf, and the coordinates of
  Alert, Nunavut (82° 30′ N), the northernmost permanently inhabited place on Earth

## Regenerating

`make_wallpaper.py` writes `truebearing.svg` deterministically. Render it to PNG at
3840×2160 with any SVG renderer, for example:

```bash
python3 assets/wallpaper/make_wallpaper.py
rsvg-convert -w 3840 -h 2160 assets/wallpaper/truebearing.svg -o assets/wallpaper/truebearing.png
```

The published PNG was rendered with headless Chrome, which matches browsers'
handling of the SVG blur filters.
