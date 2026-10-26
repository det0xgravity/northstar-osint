# shellcheck shell=bash
# media — video/image collection and metadata analysis.

ns_register media "Media collection & metadata (yt-dlp, gallery-dl, exiftool…)" "linux macos" mod_media

mod_media() {
  local rc=0
  if ns_is_macos; then
    ns_brew ffmpeg exiftool media-info || rc=1
  else
    ns_apt ffmpeg libimage-exiftool-perl mediainfo mat2 || rc=1
  fi
  ns_pipx yt-dlp          || rc=1
  ns_pipx gallery-dl      || rc=1
  ns_pipx instaloader     || rc=1
  ns_pipx streamlink      || rc=1
  ns_pipx ia internetarchive || rc=1
  ns_pipx xeuledoc        || rc=1
  return $rc
}
