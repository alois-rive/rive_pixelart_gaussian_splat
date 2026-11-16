#!/usr/bin/env python3
"""Palette tools for the pixel-splat look.

  palette.py check  PALETTE.json                       ramps dark to light, hue travel, unused colours
  palette.py swatch PALETTE.json -o swatch.png         every ramp as a row of swatches
  palette.py fit    IMAGE -p PALETTE.json -o OUT.png [--ramp wood,stone] [--size 64] [--dither 0]
                                                        an image to palette colours (a texture or a sheet)
  palette.py audit  TEXTURE -p PALETTE.json [--ramp wood] [--max-colors 6] [--min-run 2]
                                                        a texture is fit for splatting: palette-exact, few colours,
                                                        no single-texel noise
  palette.py lospec SLUG -o PALETTE.json [--file downloaded.json]
                                                        a Lospec palette (lospec.com/palette-list/SLUG) with ramps
                                                        proposed from its own ordering: edit names, ramps, roles
  palette.py frame  SCREENSHOT -p PALETTE.json [--pixel 4]
                                                        a rendered frame uses only palette colours on a whole-pixel grid

Exit 0 passes, 1 fails. Needs NumPy and Pillow.
"""
import argparse
import colorsys
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from splatlib import Palette, luma, rgb_to_hex  # noqa: E402

BAYER4 = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], dtype=np.float64)


def cmd_check(a):
    pal = Palette(a.palette)
    ok = True
    used = set()
    for name, steps in zip(pal.ramp_names, pal.ramps):
        used.update(steps)
        lum = luma(pal.rgb[steps])
        rising = all(lum[i] < lum[i + 1] + 1e-6 for i in range(len(lum) - 1))
        hues = [colorsys.rgb_to_hls(*(pal.rgb[i] / 255))[0] * 360 for i in steps]
        sats = [colorsys.rgb_to_hls(*(pal.rgb[i] / 255))[2] for i in steps]
        coloured = [h for h, s in zip(hues, sats) if s > 0.12]
        travel = 0.0
        if len(coloured) >= 2:
            travel = ((coloured[-1] - coloured[0] + 540) % 360) - 180
        note = "ok" if rising else "NOT dark to light"
        if not rising:
            ok = False
        print(f"{name:10s} {len(steps)} steps  luma {' '.join(f'{v:.2f}' for v in lum)}  "
              f"hue travel {travel:+.0f} deg  {note}")
    unused = [pal.hex[i] for i in range(len(pal.hex)) if i not in used and i not in pal.roles.values()]
    if unused:
        print(f"colours in no ramp and no role: {' '.join(unused)}")
    print(f"{len(pal.hex)} colours, {len(pal.ramps)} ramps, roles {pal.roles}")
    return 0 if ok else 1


def cmd_swatch(a):
    pal = Palette(a.palette)
    cell = 48
    rows = len(pal.ramps) + 1
    width = max(len(pal.hex), 8) * cell // 2 + 140
    img = Image.new("RGB", (max(width, 8 * cell + 140), rows * cell + 8), (24, 20, 37))
    d = ImageDraw.Draw(img)
    for r, (name, steps) in enumerate(zip(pal.ramp_names, pal.ramps)):
        d.text((6, r * cell + cell // 2 - 6), name, fill=(255, 255, 255))
        for s, idx in enumerate(steps):
            x0 = 120 + s * cell
            d.rectangle([x0, r * cell + 4, x0 + cell - 4, r * cell + cell], fill=tuple(int(v) for v in pal.rgb[idx]))
    y = len(pal.ramps) * cell + 8
    w = cell // 2
    for i, c in enumerate(pal.rgb):
        d.rectangle([120 + i * w, y, 120 + i * w + w - 2, y + cell - 8], fill=tuple(int(v) for v in c))
    d.text((6, y + 12), "all", fill=(255, 255, 255))
    img.save(a.out)
    print(f"wrote {a.out}")
    return 0


def allowed_indices(pal, ramps):
    if not ramps:
        return None
    idx = set()
    for name in ramps.split(","):
        idx.update(pal.ramps[pal.ramp_index(name.strip())])
    return sorted(idx)


def fit_majority(img, pal, among, w, h):
    """Quantize at full size, then let each target pixel take the colour most of its block holds:
    a small shape survives whole or vanishes, never as a smear of in-between colours."""
    src = np.asarray(img, dtype=np.float64)
    H, W = src.shape[:2]
    idx, _ = pal.nearest(src[..., :3].reshape(-1, 3), among)
    idx = idx.reshape(H, W)
    alpha = src[..., 3] >= 128
    out = np.zeros((h, w), dtype=np.int64)
    out_a = np.zeros((h, w), dtype=bool)
    ys = np.linspace(0, H, h + 1).astype(int)
    xs = np.linspace(0, W, w + 1).astype(int)
    for y in range(h):
        for x in range(w):
            blk = idx[ys[y]:max(ys[y + 1], ys[y] + 1), xs[x]:max(xs[x + 1], xs[x] + 1)]
            ab = alpha[ys[y]:max(ys[y + 1], ys[y] + 1), xs[x]:max(xs[x + 1], xs[x] + 1)]
            out_a[y, x] = ab.mean() >= 0.5
            vals = blk[ab] if ab.any() else blk.ravel()
            out[y, x] = np.bincount(vals.ravel()).argmax()
    rgb = pal.rgb[out]
    return np.concatenate([rgb, np.where(out_a, 255, 0)[..., None]], -1), len(np.unique(out))


def cmd_fit(a):
    pal = Palette(a.palette)
    img = Image.open(a.image).convert("RGBA")
    among = allowed_indices(pal, a.ramp)
    if a.size and a.method == "majority" and a.dither == 0:
        w, h = (int(v) for v in a.size.lower().split("x")) if "x" in a.size else (int(a.size),) * 2
        arr, n = fit_majority(img, pal, among, w, h)
        Image.fromarray(arr.astype(np.uint8)).save(a.out)
        print(f"wrote {a.out} ({w}x{h}, {n} colours, majority)")
        return 0
    if a.size:
        w, h = (int(v) for v in a.size.lower().split("x")) if "x" in a.size else (int(a.size),) * 2
        img = img.resize((w, h), Image.BOX)
    px = np.asarray(img, dtype=np.float64)
    rgb, alpha = px[..., :3], px[..., 3]
    if a.dither > 0:
        hh, ww = rgb.shape[:2]
        t = (BAYER4[np.arange(hh)[:, None] % 4, np.arange(ww)[None, :] % 4] + 0.5) / 16 - 0.5
        rgb = np.clip(rgb + t[..., None] * a.dither * 64, 0, 255)
    idx, _ = pal.nearest(rgb.reshape(-1, 3), among)
    out = pal.rgb[idx].reshape(rgb.shape)
    a_out = np.where(alpha >= 128, 255, 0)[..., None]
    Image.fromarray(np.concatenate([out, a_out], -1).astype(np.uint8)).save(a.out)
    print(f"wrote {a.out} ({img.width}x{img.height}, {len(np.unique(idx))} colours)")
    return 0


def cmd_audit(a):
    pal = Palette(a.palette)
    img = np.asarray(Image.open(a.texture).convert("RGBA"), dtype=np.int64)
    opaque = img[..., 3] >= 128
    rgb = img[..., :3][opaque]
    fails = []
    hexes = {rgb_to_hex(c) for c in np.unique(rgb, axis=0)}
    off = sorted(h for h in hexes if h not in pal.hex)
    if off:
        fails.append(f"{len(off)} colours not in the palette (first: {', '.join(off[:5])}); run `palette.py fit`")
    among = allowed_indices(pal, a.ramp)
    if among is not None:
        outside = sorted(h for h in hexes if h in pal.hex and pal.hex.index(h) not in among)
        if outside:
            fails.append(f"colours outside ramp(s) {a.ramp}: {', '.join(outside)}")
    if len(hexes) > a.max_colors:
        fails.append(f"{len(hexes)} colours, the budget is {a.max_colors}")
    # single-texel noise: a texel unlike all four neighbours turns into speckle after splatting
    full = img[..., :3]
    h, w = full.shape[:2]
    lone = 0
    for y in range(h):
        for x in range(w):
            if not opaque[y, x]:
                continue
            c = full[y, x]
            same = 0
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = full[(y + dy) % h, (x + dx) % w]
                same += int((q == c).all())
            if same == 0:
                lone += 1
    share = lone / max(1, opaque.sum())
    if share > a.max_lone:
        fails.append(f"{share:.1%} of texels are lone specks (budget {a.max_lone:.0%}): paint shapes, not noise")
    print(f"{a.texture}: {w}x{h}, {len(hexes)} colours, lone texels {share:.1%}")
    for f in fails:
        print("FAIL " + f)
    return 1 if fails else 0


def cmd_frame(a):
    pal = Palette(a.palette)
    img = np.asarray(Image.open(a.screenshot).convert("RGB"), dtype=np.int64)
    h, w = img.shape[:2]
    p = a.pixel
    fails = []
    if p > 1:
        # the art grid may start anywhere (the blit is centred): try every phase, keep the best
        share, phase = 0.0, (0, 0)
        for oy in range(p):
            for ox in range(p):
                sub = img[oy:, ox:]
                hh, ww = (sub.shape[0] // p) * p, (sub.shape[1] // p) * p
                blocks = sub[:hh, :ww].reshape(hh // p, p, ww // p, p, 3)
                sh = (blocks == blocks[:, :1, :, :1]).all(axis=(1, 3, 4)).mean()
                if sh > share:
                    share, phase = sh, (ox, oy)
        print(f"solid {p}x{p} blocks: {share:.2%} (grid phase {phase[0]},{phase[1]})")
        if share < a.min_solid:
            fails.append(f"only {share:.2%} of art pixels are solid blocks (min {a.min_solid:.0%}): "
                         "the blit is filtered or the grid is misaligned")
    cols = np.unique(img.reshape(-1, 3), axis=0)
    off = [c for c in cols if rgb_to_hex(c) not in pal.hex]
    pix_off = 0
    if off:
        offset = {tuple(c) for c in off}
        flat = img.reshape(-1, 3)
        pix_off = sum(1 for c in map(tuple, flat) if c in offset) / flat.shape[0]
    print(f"{len(cols)} colours, {len(off)} off-palette covering {pix_off:.2%} of the frame")
    if pix_off > a.max_off:
        fails.append(f"{pix_off:.2%} of pixels are off the palette (max {a.max_off:.2%})")
    for f in fails:
        print("FAIL " + f)
    return 1 if fails else 0


def hue_name(rgb):
    h, l, sat = colorsys.rgb_to_hls(*(np.asarray(rgb) / 255.0))
    if sat < 0.15 or l < 0.08 or l > 0.95:
        return "grey"
    deg = h * 360
    for limit, name in ((15, "red"), (40, "orange"), (65, "yellow"), (160, "green"), (200, "teal"),
                        (255, "blue"), (290, "purple"), (335, "pink"), (360, "red")):
        if deg < limit:
            return "brown" if name in ("orange", "red", "yellow") and l < 0.45 and sat < 0.5 else name
    return "red"


def cmd_lospec(a):
    import json
    import urllib.request
    if a.file:
        doc = json.load(open(a.file))
    else:
        req = urllib.request.Request(f"https://lospec.com/palette-list/{a.slug}.json",
                                     headers={"User-Agent": "palette-tool"})
        with urllib.request.urlopen(req, timeout=20) as r:
            doc = json.loads(r.read())
    hexes = ["#" + c.lower().lstrip("#") for c in doc["colors"]]
    rgb = np.array([[int(h[i:i + 2], 16) for i in (1, 3, 5)] for h in hexes], dtype=np.float64)
    lum = luma(rgb)
    hues = [colorsys.rgb_to_hls(*(c / 255))[0] * 360 for c in rgb]
    sats = [colorsys.rgb_to_hls(*(c / 255))[2] for c in rgb]
    # designer palettes list their ramps as runs: split where lightness turns round or the hue jumps
    runs, cur, direction = [], [0], 0
    for i in range(1, len(hexes)):
        d = 1 if lum[i] > lum[i - 1] else -1
        dh = abs(((hues[i] - hues[i - 1]) + 180) % 360 - 180)
        # a small palette (8 colours or fewer) is usually one or two long ramps that cross hues:
        # split it on lightness only
        jump = len(hexes) > 8 and sats[i] > 0.15 and sats[i - 1] > 0.15 and dh > 70
        if (direction and d != direction) or jump or len(cur) >= 8:
            runs.append(cur)
            cur, direction = [i], 0
        else:
            cur.append(i)
            direction = d
    runs.append(cur)
    ramps, used = {}, {}
    for run in runs:
        if len(run) < 2:
            continue
        run = sorted(run, key=lambda i: lum[i])
        name = hue_name(rgb[run[len(run) // 2]])
        used[name] = used.get(name, 0) + 1
        key = name if used[name] == 1 else f"{name}{used[name]}"
        ramps[key] = [hexes[i] for i in run]
    order = np.argsort(lum)
    roles = {"void": hexes[order[0]], "fog": hexes[order[len(order) * 2 // 3]],
             "sky_top": hexes[order[len(order) // 3]], "sky_bottom": hexes[order[len(order) // 2]]}
    out = {"name": doc.get("name", a.slug), "source": f"https://lospec.com/palette-list/{a.slug}",
           "author": doc.get("author", ""), "colors": hexes, "ramps": ramps, "roles": roles}
    with open(a.out, "w") as f:
        json.dump(out, f, indent=2)
    print(f"wrote {a.out}: {len(hexes)} colours, {len(ramps)} proposed ramps ({', '.join(ramps)})")
    print("the ramps and roles are a proposal: rename them for materials, fix any that break, "
          "pick the sky and fog by eye; then `palette.py check` and `swatch`")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("check"); s.add_argument("palette")
    s = sub.add_parser("swatch"); s.add_argument("palette"); s.add_argument("-o", "--out", required=True)
    s = sub.add_parser("fit")
    s.add_argument("image"); s.add_argument("-p", "--palette", required=True); s.add_argument("-o", "--out", required=True)
    s.add_argument("--ramp", help="comma list of ramp names the result may use")
    s.add_argument("--size", help="resize first (box filter): 64 or 128x64")
    s.add_argument("--dither", type=float, default=0.0, help="ordered dither strength 0..1 (default 0: flat)")
    s.add_argument("--method", choices=["majority", "box"], default="majority",
                   help="majority: quantize then vote per block (default); box: average then quantize")
    s = sub.add_parser("audit")
    s.add_argument("texture"); s.add_argument("-p", "--palette", required=True)
    s.add_argument("--ramp"); s.add_argument("--max-colors", type=int, default=8)
    s.add_argument("--max-lone", type=float, default=0.03)
    s = sub.add_parser("lospec"); s.add_argument("slug"); s.add_argument("-o", "--out", required=True)
    s.add_argument("--file", help="a palette JSON already downloaded from Lospec")
    s = sub.add_parser("frame")
    s.add_argument("screenshot"); s.add_argument("-p", "--palette", required=True)
    s.add_argument("--pixel", type=int, default=1, help="screen pixels per art pixel")
    s.add_argument("--min-solid", type=float, default=0.97)
    s.add_argument("--max-off", type=float, default=0.002)
    a = ap.parse_args()
    return {"check": cmd_check, "swatch": cmd_swatch, "fit": cmd_fit, "audit": cmd_audit, "frame": cmd_frame,
            "lospec": cmd_lospec}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
