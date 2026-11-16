#!/usr/bin/env python3
"""Gate the 3D wordmark against the brand kit's own wordmark, rendered by Rive.

  gate_wordmark.py SPLAT_FRONT.png REF.png [--min-iou 0.8] [--max-aspect-drift 0.05] [-o overlay.png]

SPLAT_FRONT: the letters alone (make_wordmark.py --plinth 0), baked and rendered straight on
through the splat renderer with `--arg maskSky=1` (the ground pure magenta): the letters are
everything that is not magenta. REF: art/wordmark_ref/wordmark.png, the kit's Wordmark shapes
drawn by `rive --screenshot` (white on black). Both are cropped to the word, compared at
256 x 64 (IoU) and by height / width. The overlay shows magenta where the kit has letter and the
model has none, green the other way.
"""
import argparse
import sys

import numpy as np
from PIL import Image

ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
ap.add_argument("render"); ap.add_argument("ref")
ap.add_argument("--min-iou", type=float, default=0.8)
ap.add_argument("--max-aspect-drift", type=float, default=0.05)
ap.add_argument("-o", "--out")
a = ap.parse_args()
im = np.asarray(Image.open(a.render).convert("RGB")).astype(int)
model = ~((im[..., 0] == 255) & (im[..., 1] == 0) & (im[..., 2] == 255))
ref = np.asarray(Image.open(a.ref).convert("RGB")).astype(int).min(-1) > 128


def crop(m):
    ys, xs = np.nonzero(m)
    return m[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def norm(m):
    return np.asarray(Image.fromarray((m * 255).astype(np.uint8)).resize((256, 64), Image.NEAREST)) > 127


cm, cr = crop(model), crop(ref)
m, r = norm(cm), norm(cr)
iou = (m & r).sum() / (m | r).sum()
am, ar = cm.shape[0] / cm.shape[1], cr.shape[0] / cr.shape[1]
drift = abs(am - ar) / ar
print(f"wordmark: IoU {iou:.3f}, aspect {am:.3f} vs the kit's {ar:.3f} (drift {drift:.3f})")
if a.out:
    ov = np.zeros((64, 256, 3), np.uint8)
    ov[m & r] = (150, 150, 150)
    ov[r & ~m] = (230, 40, 200)
    ov[m & ~r] = (60, 220, 90)
    Image.fromarray(ov).resize((1024, 256), Image.NEAREST).save(a.out)
ok = iou >= a.min_iou and drift <= a.max_aspect_drift
print("pass" if ok else "FAIL")
sys.exit(0 if ok else 1)
