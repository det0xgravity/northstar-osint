# shellcheck shell=bash
# media — video/image collection and metadata analysis.

ns_register media "Media collection & metadata (yt-dlp, gallery-dl, exiftool…)" "linux macos" mod_media

mod_media() {
  local rc=0 m
  if ns_is_macos; then
    ns_brew ffmpeg exiftool media-info tesseract tesseract-lang ocrmypdf || rc=1
  else
    ns_apt ffmpeg libimage-exiftool-perl mediainfo mat2 tesseract-ocr ocrmypdf || rc=1
    # OCR languages for the scripts investigators meet most: Latin, Cyrillic, Arabic,
    # Hebrew, Greek, Devanagari, Thai, Chinese, Japanese, Korean (a few MB each).
    # ns_ocr_langs picks the right ones per image, so having many costs nothing.
    ns_apt tesseract-ocr-osd tesseract-ocr-fra tesseract-ocr-deu tesseract-ocr-spa tesseract-ocr-por \
           tesseract-ocr-ita tesseract-ocr-nld tesseract-ocr-pol tesseract-ocr-tur tesseract-ocr-vie \
           tesseract-ocr-ind tesseract-ocr-rus tesseract-ocr-ukr tesseract-ocr-ara tesseract-ocr-fas \
           tesseract-ocr-heb tesseract-ocr-ell tesseract-ocr-hin tesseract-ocr-tha tesseract-ocr-chi-sim \
           tesseract-ocr-chi-tra tesseract-ocr-jpn tesseract-ocr-kor || rc=1
  fi
  # monolith: single-file page captures for ns-archive (official release binary)
  if ns_is_macos; then
    ns_brew monolith || rc=1
  else
    case "$NS_ARCH" in arm64) m=aarch64 ;; *) m=x86_64 ;; esac
    ns_gh_release Y2Z/monolith monolith "^monolith-cli-linux-${m}\$" || rc=1
  fi
  ns_pipx whisper-ctranslate2 || rc=1     # offline transcription/translation for ns-video
  # Same-photo finder: Pillow + imagehash in a small private venv
  [ -x "$NS_VENVS/images/bin/python" ] || python3 -m venv "$NS_VENVS/images" || rc=1
  if ! "$NS_VENVS/images/bin/python" -c 'import imagehash' 2>/dev/null || [ "$NS_UPDATE" = 1 ]; then
    ns_pip /dev/null "Pillow + imagehash" "$NS_VENVS/images/bin/pip" install --upgrade pip pillow imagehash || { ns_warn "imagehash install failed"; rc=1; }
  fi
  install -m 644 "$NS_REPO/lib/ns_photomatch.py" "$NS_HOME/lib/ns_photomatch.py"
  printf '#!/usr/bin/env bash\nexec "%s/bin/python" "%s/lib/ns_photomatch.py" "$@"\n' "$NS_VENVS/images" "$NS_HOME" > "$NS_BIN/ns_photomatch"
  chmod +x "$NS_BIN/ns_photomatch"
  ns_pipx yt-dlp          || rc=1
  ns_pipx gallery-dl      || rc=1
  ns_pipx instaloader     || rc=1
  ns_pipx streamlink      || rc=1
  ns_pipx ia internetarchive || rc=1
  # Retired: xeuledoc is unmaintained since 2021 (use "ghunt drive <id>")
  [ -x "$HOME/.local/bin/xeuledoc" ] && pipx uninstall xeuledoc >/dev/null 2>&1
  return $rc
}
