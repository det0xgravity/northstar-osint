# shellcheck shell=bash
# gis — QGIS, the desktop GIS, for the case map's GeoJSON and KML exports
# (Case map → Open in QGIS). Flathub's QGIS is verified by the QGIS project
# (x86_64 and arm64, about 600 MB); Homebrew's cask on macOS.

ns_register gis "QGIS desktop GIS, for the case map's exports" "linux macos" mod_gis

mod_gis() {
  if ns_is_macos; then
    ns_cask qgis
  else
    # Flathub has two branches (stable, lts): name one, or flatpak stops to ask
    ns_flatpak org.qgis.qgis//stable
  fi
}
