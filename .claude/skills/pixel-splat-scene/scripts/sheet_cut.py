#!/usr/bin/env python3
"""Cut a concept turnaround sheet into one reference image per view.

  sheet_cut.py art/<a>/sheet.v1.png -o art/<a>/refs [--grid 2x2] [--views front,right,back,top]
               [--tol 0.06] [--margin 8] [--flip right] [--rotate top=-90]

--flip mirrors a view left to right, --rotate turns one (degrees, counter-clockwise): for a
sheet whose views do not follow hedra's cameras. hedra's `right` view looks along -X, so a
model facing -Y faces LEFT in it; its `top` view has the front at the bottom. A generator
often draws the side view facing right and the top view nose-right: flip / rotate them
(a mirror is only honest for a left-right symmetric object; otherwise regenerate).

Each panel's background is the median of its four corners; a pixel is the object when
it differs from that by more than --tol (0..1, RGB distance). Small specks and stray
labels are dropped (components under 2 % of the largest). Writes per view:

  <view>.png        the object cut out, cropped to its box plus --margin, transparent around it
  <view>.mask.png   the silhouette, white on black, same crop
  views.json        each view's box in the sheet, its aspect (height / width), its area share

Exit 1 when a panel holds no object or the object touches the panel's edge (cropped:
regenerate, the turnaround is unusable for gating).
"""
import argparse
import json
import os
import sys

import numpy as np
from PIL import Image


def components(mask):
    """Label 4-connected components; returns labels and sizes (pure NumPy flood fill by rows)."""
    h, w = mask.shape
    labels = np.zeros((h, w), dtype=np.int32)
    sizes = [0]
    cur = 0
    for y in range(h):
        row = mask[y]
        for x in np.flatnonzero(row & (labels[y] == 0)):
            if labels[y, x]:
                continue
            cur += 1
            stack = [(y, x)]
            labels[y, x] = cur
            n = 0
            while stack:
                cy, cx = stack.pop()
                n += 1
                for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                    if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not labels[ny, nx]:
                        labels[ny, nx] = cur
                        stack.append((ny, nx))
            sizes.append(n)
    return labels, np.array(sizes)


def object_mask(panel, tol):
    rgb = panel[..., :3].astype(np.float64) / 255.0
    h, w = rgb.shape[:2]
    k = max(2, min(h, w) // 40)
    corners = np.concatenate([rgb[:k, :k].reshape(-1, 3), rgb[:k, -k:].reshape(-1, 3),
                              rgb[-k:, :k].reshape(-1, 3), rgb[-k:, -k:].reshape(-1, 3)])
    bg = np.median(corners, axis=0)
    dist = np.sqrt(((rgb - bg) ** 2).sum(-1))
    mask = dist > tol
    # work at reduced size for the component pass, then keep the big components
    step = max(1, min(h, w) // 300)
    small = mask[::step, ::step]
    labels, sizes = components(small)
    if len(sizes) <= 1:
        return np.zeros_like(mask), bg
    big = sizes.max()
    keep = np.flatnonzero(sizes >= max(big * 0.02, 4))
    keep = keep[keep > 0]
    keep_small = np.isin(labels, keep)
    up = np.repeat(np.repeat(keep_small, step, 0), step, 1)[:h, :w]
    pad_h, pad_w = h - up.shape[0], w - up.shape[1]
    if pad_h or pad_w:
        up = np.pad(up, ((0, pad_h), (0, pad_w)), mode="edge")
    # dilate the kept region by one coarse cell, then take the fine mask inside it
    return mask & np.maximum.reduce([np.roll(up, s, a) for a in (0, 1) for s in (-step, 0, step)]), bg


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("sheet")
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--grid", default="2x2", help="columns x rows")
    ap.add_argument("--views", default="front,right,back,top", help="names, row by row")
    ap.add_argument("--tol", type=float, default=0.06)
    ap.add_argument("--margin", type=int, default=8)
    ap.add_argument("--flip", help="views to mirror left-right, comma separated")
    ap.add_argument("--rotate", action="append", default=[], help="VIEW=DEGREES counter-clockwise (repeatable)")
    a = ap.parse_args()
    cols, rows = (int(v) for v in a.grid.lower().split("x"))
    names = a.views.split(",")
    if len(names) != cols * rows:
        raise SystemExit(f"{len(names)} view names for a {cols}x{rows} grid")
    flips = set(a.flip.split(",")) if a.flip else set()
    rotations = {kv.split("=")[0]: float(kv.split("=")[1]) for kv in a.rotate}
    sheet = np.asarray(Image.open(a.sheet).convert("RGBA"))
    H, W = sheet.shape[:2]
    os.makedirs(a.out, exist_ok=True)
    report, bad = {}, []
    for i, name in enumerate(names):
        r, c = divmod(i, cols)
        y0, y1 = r * H // rows, (r + 1) * H // rows
        x0, x1 = c * W // cols, (c + 1) * W // cols
        panel = sheet[y0:y1, x0:x1]
        if name in flips:
            panel = panel[:, ::-1].copy()
        if name in rotations:
            panel = np.asarray(Image.fromarray(panel).rotate(rotations[name], expand=True,
                                                               fillcolor=tuple(int(v) for v in panel[2, 2])))
        mask, bg = object_mask(panel, a.tol)
        if not mask.any():
            bad.append(f"{name}: no object found")
            continue
        ys, xs = np.nonzero(mask)
        by0, by1, bx0, bx1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        ph, pw = mask.shape
        if by0 <= 1 or bx0 <= 1 or by1 >= ph - 1 or bx1 >= pw - 1:
            bad.append(f"{name}: the object touches the panel edge (cropped)")
        m = a.margin
        cy0, cy1 = max(0, by0 - m), min(ph, by1 + m)
        cx0, cx1 = max(0, bx0 - m), min(pw, bx1 + m)
        crop = panel[cy0:cy1, cx0:cx1].copy()
        cmask = mask[cy0:cy1, cx0:cx1]
        crop[..., 3] = np.where(cmask, 255, 0)
        Image.fromarray(crop).save(os.path.join(a.out, f"{name}.png"))
        Image.fromarray((cmask * 255).astype(np.uint8)).save(os.path.join(a.out, f"{name}.mask.png"))
        report[name] = {"box": [int(x0 + bx0), int(y0 + by0), int(bx1 - bx0), int(by1 - by0)],
                        "flipped": name in flips, "rotated": rotations.get(name, 0),
                        "aspect": round((by1 - by0) / (bx1 - bx0), 4),
                        "fill": round(float(mask.sum()) / ((by1 - by0) * (bx1 - bx0)), 4),
                        "background": "#%02x%02x%02x" % tuple(int(v * 255) for v in bg)}
        print(f"{name:6s} box {bx1 - bx0}x{by1 - by0}  aspect {report[name]['aspect']:.3f}  fill {report[name]['fill']:.2f}")
    with open(os.path.join(a.out, "views.json"), "w") as f:
        json.dump({"sheet": os.path.abspath(a.sheet), "grid": a.grid, "views": report}, f, indent=2)
    for b in bad:
        print("FAIL " + b)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
