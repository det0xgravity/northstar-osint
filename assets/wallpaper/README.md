# Wallpaper

`northstar.png` (3840×2160) is the desktop background that the `desktop` module
sets on GNOME and XFCE, but only if you're still using the distribution's default
background. It's original artwork made for this project and covered by the
repository's license (GPL-3.0-or-later):

- a night sky over map contours and a coordinate grid
- a north star inside a compass ring, with a dipper whose pointer stars lead to it
- Canadian touches: aurora borealis, a maple leaf, and the coordinates of
  Alert, Nunavut (82° 30′ N), the northernmost permanently inhabited place on Earth

## Regenerating

`make_wallpaper.py` writes `northstar.svg` deterministically. Render it to PNG at
3840×2160 with any SVG renderer, for example:

```bash
python3 assets/wallpaper/make_wallpaper.py
rsvg-convert -w 3840 -h 2160 assets/wallpaper/northstar.svg -o assets/wallpaper/northstar.png
```

The published PNG was rendered with headless Chrome, which matches browsers'
handling of the SVG blur filters.
