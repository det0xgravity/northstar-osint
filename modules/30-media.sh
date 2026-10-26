# shellcheck shell=bash
# media — video/image collection and metadata analysis.

ns_register media "Media collection & metadata (yt-dlp, gallery-dl, exiftool…)" "linux macos" mod_media

mod_media() {
  local rc=0 m
  if ns_is_macos; then
    ns_brew ffmpeg exiftool media-info || rc=1
  else
    ns_apt ffmpeg libimage-exiftool-perl mediainfo mat2 || rc=1
  fi
  # monolith: single-file page captures for ns-archive (official release binary)
  if ns_is_macos; then
    ns_brew monolith || rc=1
  else
    case "$NS_ARCH" in arm64) m=aarch64 ;; *) m=x86_64 ;; esac
    ns_gh_release Y2Z/monolith monolith "^monolith-cli-linux-${m}\$" || rc=1
  fi
  ns_pipx yt-dlp          || rc=1
  ns_pipx gallery-dl      || rc=1
  ns_pipx instaloader     || rc=1
  ns_pipx streamlink      || rc=1
  ns_pipx ia internetarchive || rc=1
  # Retired: xeuledoc is unmaintained since 2021 (use "ghunt drive <id>")
  [ -x "$HOME/.local/bin/xeuledoc" ] && pipx uninstall xeuledoc >/dev/null 2>&1
  return $rc
}
