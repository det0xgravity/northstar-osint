# shellcheck shell=bash
# face — local face comparison for ns-face: OpenCV in a private venv, plus the
# OpenCV Zoo YuNet (MIT) and SFace (Apache-2.0) models, checked against the
# SHA-256 that the opencv_zoo repository publishes for them.

ns_register face "Face comparison within a case (OpenCV YuNet + SFace, local)" "linux macos" mod_face

NS_FACE_ZOO="https://media.githubusercontent.com/media/opencv/opencv_zoo/main/models"
# file | SHA-256 (from the repository's Git LFS pointers)
NS_FACE_MODELS_LIST="face_detection_yunet/face_detection_yunet_2023mar.onnx|8f2383e4dd3cfbb4553ea8718107fc0423210dc964f9f4280604804ed2552fa4
face_recognition_sface/face_recognition_sface_2021dec.onnx|0ba9fbfa01b5270c96627c4ef784da859931e02f04419c829e83484087c34e79"

mod_face() {
  local rc=0 venv="$NS_VENVS/face" dir="$NS_HOME/models/face" path sum f
  mkdir -p "$NS_VENVS" "$NS_BIN" "$dir"
  [ -x "$venv/bin/python" ] || python3 -m venv "$venv" || return 1
  if ! "$venv/bin/python" -c 'import cv2' 2>/dev/null || [ "$NS_UPDATE" = 1 ]; then
    "$venv/bin/pip" install -q --upgrade pip opencv-python-headless numpy >/dev/null 2>&1 \
      || { ns_warn "OpenCV install failed"; return 1; }
  fi
  while IFS='|' read -r path sum; do
    [ -n "$path" ] || continue
    f="$dir/$(basename "$path")"
    [ -s "$f" ] && [ "$(ns_sha256 "$f")" = "$sum" ] && continue
    curl -fsSL "$NS_FACE_ZOO/$path" -o "$f.tmp" || { ns_warn "download failed: $(basename "$path")"; rc=1; continue; }
    if [ "$(ns_sha256 "$f.tmp")" = "$sum" ]; then mv "$f.tmp" "$f"
    else rm -f "$f.tmp"; ns_warn "$(basename "$path") failed its checksum: not installed"; rc=1; fi
  done <<LIST
$NS_FACE_MODELS_LIST
LIST
  install -m 644 "$NS_REPO/lib/ns_face.py" "$NS_HOME/lib/ns_face.py"
  printf '#!/usr/bin/env bash\n# northstar wrapper: face comparison in its own venv\nNS_FACE_MODELS="%s" exec "%s/bin/python" "%s/lib/ns_face.py" "$@"\n' \
    "$dir" "$venv" "$NS_HOME" > "$NS_BIN/ns_face"
  chmod +x "$NS_BIN/ns_face"
  [ $rc = 0 ] && ns_info "Face comparison ready (models verified)"
  return $rc
}
