#!/usr/bin/env python3
"""Face comparison within a case for truebearing-osint (the engine behind tb-face).

Usage: tb_face.py REFERENCE_IMAGE CANDIDATE_FOLDER OUTPUT_FOLDER

Finds faces with YuNet and compares each to the reference face with SFace, both
OpenCV Zoo models (MIT and Apache-2.0) running locally. Nothing is uploaded.
Model files are read from $TB_FACE_MODELS.

Scores are cosine similarities between face embeddings. They indicate how
alike two faces look to this model, not who someone is:
  >= 0.50        strong similarity
  0.363 - 0.50   possible similarity (0.363 is OpenCV's suggested threshold)
  < 0.363        unlikely
Accuracy drops with small, blurred, angled or partly hidden faces, children,
large age gaps, and for some demographic groups. A score is never an
identification on its own.
"""
import csv
import html
import os
import sys

os.environ.setdefault("OPENCV_LOG_LEVEL", "ERROR")     # quiet OpenCV 5's backend notices
import cv2  # noqa: E402
import numpy as np  # noqa: E402

MODELS = os.environ.get("TB_FACE_MODELS", "")
DETECTOR = os.path.join(MODELS, "face_detection_yunet_2023mar.onnx")
RECOGNISER = os.path.join(MODELS, "face_recognition_sface_2021dec.onnx")
IMAGE_EXT = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".tif", ".tiff"}
STRONG, POSSIBLE = 0.50, 0.363
MIN_FACE = 60          # pixels: smaller faces are flagged as low quality


def band(score):
    if score >= STRONG:
        return "strong similarity"
    if score >= POSSIBLE:
        return "possible similarity"
    return "unlikely"


class Faces:
    def __init__(self):
        self.det = cv2.FaceDetectorYN.create(DETECTOR, "", (320, 320), 0.8, 0.3, 5000)
        self.rec = cv2.FaceRecognizerSF.create(RECOGNISER, "")

    def find(self, img):
        h, w = img.shape[:2]
        scale = min(1.0, 1600.0 / max(h, w))            # very large photos: detect on a resized copy
        work = cv2.resize(img, (int(w * scale), int(h * scale))) if scale < 1 else img
        self.det.setInputSize((work.shape[1], work.shape[0]))
        _, found = self.det.detect(work)
        faces = []
        for f in (found if found is not None else []):
            f = f.copy()
            f[:14] = f[:14] / scale                     # box and landmarks back to full size
            aligned = self.rec.alignCrop(img, f)
            feat = self.rec.feature(aligned)
            faces.append({"box": [int(v) for v in f[:4]], "conf": float(f[14]),
                          "crop": aligned, "feat": feat})
        return faces


def read(path):
    data = np.fromfile(path, dtype=np.uint8)            # handles non-ASCII paths
    return cv2.imdecode(data, cv2.IMREAD_COLOR) if data.size else None


def main(argv):
    if len(argv) != 4:
        print(__doc__)
        return 2
    ref_path, folder, out = argv[1:]
    if not (os.path.exists(DETECTOR) and os.path.exists(RECOGNISER)):
        print("Face models are missing: ./install.sh --only face")
        return 1
    os.makedirs(os.path.join(out, "crops"), exist_ok=True)
    fx = Faces()

    ref = read(ref_path)
    ref_faces = fx.find(ref) if ref is not None else []
    if not ref_faces:
        print("No face found in the reference image. Use a clearer, front-facing photo.")
        return 1
    ref_face = max(ref_faces, key=lambda f: f["box"][2] * f["box"][3])
    if len(ref_faces) > 1:
        print(f"The reference image has {len(ref_faces)} faces: using the largest. "
              "Crop the reference to one person for clearer results.")
    cv2.imwrite(os.path.join(out, "crops", "reference.jpg"), ref_face["crop"])

    rows, scanned = [], 0
    out_abs = os.path.abspath(out)
    for root, dirs, files in os.walk(folder):
        if os.path.abspath(root).startswith(out_abs):
            continue                                     # never compare our own crops
        for name in sorted(files):
            if os.path.splitext(name)[1].lower() not in IMAGE_EXT:
                continue
            path = os.path.join(root, name)
            if os.path.abspath(path) == os.path.abspath(ref_path):
                continue
            img = read(path)
            if img is None:
                continue
            scanned += 1
            for i, f in enumerate(fx.find(img)):
                score = float(fx.rec.match(ref_face["feat"], f["feat"], cv2.FaceRecognizerSF_FR_COSINE))
                small = min(f["box"][2], f["box"][3]) < MIN_FACE
                crop = f"c{len(rows) + 1:04d}.jpg"
                cv2.imwrite(os.path.join(out, "crops", crop), f["crop"])
                rows.append({"image": os.path.relpath(path, folder), "face": i + 1,
                             "score": round(score, 3), "band": band(score),
                             "quality": "LOW (small face)" if small else "ok",
                             "detector_confidence": round(f["conf"], 2),
                             "box_x_y_w_h": " ".join(map(str, f["box"])), "crop": f"crops/{crop}"})
    rows.sort(key=lambda r: -r["score"])
    with open(os.path.join(out, "results.csv"), "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0]) if rows else ["image"])
        w.writeheader()
        w.writerows(rows)

    # Contact sheet for human review (local images only; nothing loads from the internet)
    cards = "".join(
        f'<div class="c {r["band"].split()[0]}"><img src="{html.escape(r["crop"])}">'
        f'<b>{r["score"]:.3f}</b> {html.escape(r["band"])}<br><small>{html.escape(r["image"])} · face {r["face"]}'
        f'{" · " + html.escape(r["quality"]) if r["quality"] != "ok" else ""}</small></div>'
        for r in rows[:300])
    page = f"""<!doctype html><meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src 'self'; style-src 'unsafe-inline'">
<title>Face comparison</title><style>
body{{font:14px system-ui,sans-serif;margin:16px;background:#0b1324;color:#d8dee9}}
.c{{display:inline-block;width:150px;margin:6px;vertical-align:top}} img{{width:112px;height:112px;display:block}}
.strong{{color:#7ee787}} .possible{{color:#f2cc60}} .unlikely{{color:#8b949e}}
.ref img{{width:160px;height:160px}} p{{max-width:70em}}</style>
<h1>Face comparison: similarity, not identification</h1>
<p>Scores show how alike faces look to the SFace model (≥ 0.50 strong, 0.363–0.50 possible, below that unlikely).
Accuracy drops for small or blurred faces, unusual angles, children and large age gaps, and differs between
demographic groups. Every result needs human review and independent corroboration.</p>
<div class="c ref"><img src="crops/reference.jpg"><b>Reference</b></div><hr>{cards}"""
    with open(os.path.join(out, "results.html"), "w", encoding="utf-8") as fh:
        fh.write(page)

    counts = {b: sum(1 for r in rows if r["band"] == b) for b in ("strong similarity", "possible similarity")}
    print(f"Scanned {scanned} images, {len(rows)} faces.")
    print(f"Strong similarity: {counts['strong similarity']} · possible: {counts['possible similarity']}")
    for r in rows[:10]:
        print(f"  {r['score']:.3f}  {r['band']:<20} {r['image']} (face {r['face']}){'  LOW QUALITY' if r['quality'] != 'ok' else ''}")
    print("Review results.html: a score is not an identification.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
