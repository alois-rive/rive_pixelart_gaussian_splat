#!/usr/bin/env python3
"""Goldens: render a model's turnaround, gate it against its concept views, keep approved renders.

  golden.py views --hedra models/<a>/<a>.rmdl -o models/<a>/shots/p2
        the mesh, flat material colours, through `hedra model render` (fast, for blockout and form)
  golden.py views --rive lookdev --blob <a> -o models/<a>/shots/p5 [--pixel 2] [--arg k=v ...]
        the baked splats through the real Rive renderer (assets/template), the look itself
  golden.py gate --refs art/<a>/refs --shots models/<a>/shots/p5 -p palette.json -o compare.png
        silhouette IoU, aspect drift and material colour share per view, against sheet_cut.py's refs
  golden.py snap  --shots models/<a>/shots/p5 --goldens goldens/<a>
  golden.py check --shots models/<a>/shots/p5 --goldens goldens/<a> [--max-diff 0.002]
        approved renders kept as goldens; re-render after any shader, bake or model change and check

Views: front, right, back, left, top, iso. They follow hedra's (Blender's) convention:
the model faces -Y in hedra (+Z in the GLB), so `front` sees its face. Exit 0 pass, 1 fail.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

VIEWS = {  # name: (yaw, pitch) of the Rive orbit camera
    "front": (0, 0), "right": (90, 0), "back": (180, 0), "left": (270, 0), "top": (0, 90), "iso": (35, 30),
}
BG = (0.851, 0.851, 0.851)  # #d9d9d9, the concept sheet's background


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    errs = [l for l in (r.stdout + r.stderr).splitlines() if " error " in l or l.startswith("error")]
    if r.returncode != 0 or errs:
        print("\n".join(errs) or r.stderr[-2000:], file=sys.stderr)
        raise SystemExit(f"failed: {' '.join(cmd[:3])} ...")


def cmd_views(a):
    os.makedirs(a.out, exist_ok=True)
    names = a.views.split(",")
    if a.hedra:
        lines = []
        for v in names:
            out = os.path.abspath(os.path.join(a.out, f"{v}.png"))
            # black, not the sheet's grey: hedra's default material is a light grey
            cam = f"--view {v}"
            if a.elevation and v in ("front", "right", "back", "left"):
                # match a concept drawn from slightly above (its ring tops show)
                az = {"front": 0, "right": 90, "back": 180, "left": 270}[v]
                cam = f"--azimuth {az} --elevation {a.elevation} --ortho"
            lines.append(f"render {out} {cam} --shading material --overlay none "
                         f"--background 0 0 0 1 --size {a.size} {a.size}")
        r = subprocess.run(["hedra", "model", "--dry-run", "--text", a.hedra, "run", "-"],
                           input="\n".join(lines) + "\n", capture_output=True, text=True)
        if r.returncode != 0:
            raise SystemExit(r.stdout + r.stderr)
    else:
        for v in names:
            yaw, pitch = VIEWS[v]
            if a.elevation and pitch == 0:
                pitch = a.elevation
            out = os.path.abspath(os.path.join(a.out, f"{v}.png"))
            args = {"blobName": a.blob, "yaw": yaw, "pitch": pitch, "spin": 0, "maskSky": 0 if a.real_sky else 1, "fogMax": 0,
                    "pixelSize": a.pixel, "shadows": 1 if v == "iso" else 0}
            if a.look == "albedo":
                # every splat on its painted step: the colour gate measures materials, not the sun
                args.update({"shadeSteps": 0, "lightSteps": 0, "ink": 0})
            if a.texel:
                # the scene's density: the same world units per art pixel as the final frame
                args["orthoHeight"] = a.texel * a.size / a.pixel
            for kv in a.arg:
                k, val = kv.split("=", 1)
                args[k] = val
            cmd = ["rive", a.rive, f"--screenshot={out}", f"--advance={a.advance}", f"--viewport={a.size}x{a.size}"]
            for k, val in args.items():
                cmd += ["--arg", f"{k}={val}"]
            run(cmd)
    # the settings travel with the renders, and with the goldens kept from them
    settings = {k: v for k, v in vars(a).items() if k not in ("cmd", "out")}
    with open(os.path.join(a.out, "render.json"), "w") as f:
        json.dump(settings, f, indent=2)
    print(f"wrote {', '.join(names)} to {a.out}")
    return 0


def load_mask(path, tol=0.06):
    img = np.asarray(Image.open(path).convert("RGBA"), dtype=np.float64)
    if path.endswith(".mask.png"):
        return img[..., 0] > 127, None
    if (img[..., 3] < 250).any():
        return img[..., 3] > 127, img
    rgb = img[..., :3] / 255.0
    k = 4
    corners = np.concatenate([rgb[:k, :k].reshape(-1, 3), rgb[:k, -k:].reshape(-1, 3),
                              rgb[-k:, :k].reshape(-1, 3), rgb[-k:, -k:].reshape(-1, 3)])
    bg = np.median(corners, axis=0)
    return np.sqrt(((rgb - bg) ** 2).sum(-1)) > tol, img


def crop_norm(mask, n=128):
    ys, xs = np.nonzero(mask)
    if len(ys) == 0:
        return None, 0.0, None
    box = (ys.min(), ys.max() + 1, xs.min(), xs.max() + 1)
    m = mask[box[0]:box[1], box[2]:box[3]]
    aspect = m.shape[0] / m.shape[1]
    sq = np.asarray(Image.fromarray((m * 255).astype(np.uint8)).resize((n, n), Image.NEAREST)) > 127
    return sq, aspect, box


def ramp_share(img, mask, box, pal):
    """Share of the object's pixels per ramp (material family), colours snapped to the palette."""
    rgb = img[box[0]:box[1], box[2]:box[3], :3][mask[box[0]:box[1], box[2]:box[3]]]
    if len(rgb) == 0:
        return np.zeros(len(pal.ramps))
    ramp_cols = sorted({i for s in pal.ramps for i in s})
    idx, _ = pal.nearest(rgb[:: max(1, len(rgb) // 20000)], ramp_cols)
    # a colour several ramps share (small palettes share their darks) counts 1/k towards each,
    # the same way for the concept and the model, so it never tips the share to the first ramp
    share = np.zeros(len(pal.ramps))
    owners = {}
    for i in idx:
        i = int(i)
        if i not in owners:
            owners[i] = [r for r, steps in enumerate(pal.ramps) if i in steps]
        for r in owners[i]:
            share[r] += 1.0 / len(owners[i])
    return share / max(1, share.sum())


def cmd_gate(a):
    names = a.views.split(",")
    pal = None
    if a.palette:
        from splatlib import Palette
        pal = Palette(a.palette)
    rows, fails, report = [], [], {}
    for v in names:
        ref_path = os.path.join(a.refs, f"{v}.png")
        shot_path = os.path.join(a.shots, f"{v}.png")
        if not (os.path.exists(ref_path) and os.path.exists(shot_path)):
            fails.append(f"{v}: missing {ref_path if not os.path.exists(ref_path) else shot_path}")
            continue
        rmask, rimg = load_mask(ref_path)
        smask, simg = load_mask(shot_path)
        rn, ra, rbox = crop_norm(rmask)
        sn, sa, sbox = crop_norm(smask)
        if rn is None or sn is None:
            fails.append(f"{v}: empty silhouette")
            continue
        iou = float((rn & sn).sum()) / max(1, float((rn | sn).sum()))
        drift = abs(sa - ra) / ra
        entry = {"iou": round(iou, 3), "aspect_ref": round(ra, 3), "aspect_model": round(sa, 3),
                 "aspect_drift": round(drift, 3)}
        # where along the height the outlines disagree most (the repair instruction)
        rw, sw = rn.mean(1), sn.mean(1)
        worst = int(np.argmax(np.abs(rw - sw)))
        entry["worst_row"] = {"at": round(worst / len(rw), 2), "ref_width": round(float(rw[worst]), 2),
                              "model_width": round(float(sw[worst]), 2)}
        if pal is not None and rimg is not None and simg is not None:
            rs, ss = ramp_share(rimg, rmask, rbox, pal), ramp_share(simg, smask, sbox, pal)
            cd = 0.5 * float(np.abs(rs - ss).sum())
            entry["color_drift"] = round(cd, 3)
            entry["ramps"] = {pal.ramp_names[i]: [round(float(rs[i]), 2), round(float(ss[i]), 2)]
                              for i in range(len(rs)) if rs[i] > 0.02 or ss[i] > 0.02}
            if cd > a.max_color_drift:
                fails.append(f"{v}: colour share drift {cd:.2f} > {a.max_color_drift} (ref, model per ramp: {entry['ramps']})")
        if iou < a.min_iou:
            fails.append(f"{v}: silhouette IoU {iou:.3f} < {a.min_iou} (worst at {entry['worst_row']['at']} of the "
                         f"height: ref {entry['worst_row']['ref_width']}, model {entry['worst_row']['model_width']})")
        if drift > a.max_aspect_drift:
            fails.append(f"{v}: aspect drift {drift:.3f} > {a.max_aspect_drift} (ref h/w {ra:.3f}, model {sa:.3f})")
        report[v] = entry
        print(f"{v:6s} iou {iou:.3f}  aspect {ra:.3f} vs {sa:.3f} (drift {drift:.3f})"
              + (f"  colour drift {entry['color_drift']:.2f}" if "color_drift" in entry else ""))
        rows.append((v, ref_path, shot_path, rn, sn))
    if a.out and rows:
        cell = 192
        sheet = Image.new("RGB", (cell * 3 + 16, len(rows) * (cell + 20)), (40, 40, 48))
        d = ImageDraw.Draw(sheet)
        for i, (v, rp, sp, rn, sn) in enumerate(rows):
            y = i * (cell + 20) + 16
            for j, p in enumerate((rp, sp)):
                im = Image.open(p).convert("RGBA")
                im.thumbnail((cell, cell), Image.NEAREST)
                bgc = Image.new("RGBA", im.size, (217, 217, 217, 255))
                bgc.alpha_composite(im)
                sheet.paste(bgc.convert("RGB"), (j * (cell + 8), y))
            ov = np.zeros((128, 128, 3), dtype=np.uint8)
            ov[rn & sn] = (150, 150, 150)
            ov[rn & ~sn] = (230, 40, 200)   # in the concept, missing from the model
            ov[sn & ~rn] = (60, 220, 90)    # in the model, not in the concept
            sheet.paste(Image.fromarray(ov).resize((cell, cell), Image.NEAREST), (2 * (cell + 8), y))
            d.text((4, y - 14), f"{v}: concept | model | overlay (magenta missing, green extra)", fill=(255, 255, 255))
        sheet.save(a.out)
        print(f"wrote {a.out}")
    if a.json:
        with open(a.json, "w") as f:
            json.dump({"views": report, "fails": fails}, f, indent=2)
    for f in fails:
        print("FAIL " + f)
    return 1 if fails else 0


def cmd_snap(a):
    os.makedirs(a.goldens, exist_ok=True)
    n = 0
    for f in sorted(os.listdir(a.shots)):
        if f.endswith(".png") or f == "render.json":
            shutil.copyfile(os.path.join(a.shots, f), os.path.join(a.goldens, f))
            n += 1
    print(f"kept {n} goldens in {a.goldens}")
    return 0


def cmd_check(a):
    fails = []
    gj, sj = os.path.join(a.goldens, "render.json"), os.path.join(a.shots, "render.json")
    if os.path.exists(gj):
        # settings added to `views` later default to their old behaviour in older records
        defaults = {"advance": "2", "real_sky": False, "look": "lit", "texel": 0, "elevation": 0, "arg": []}
        want = {**defaults, **json.load(open(gj))}
        got = {**defaults, **(json.load(open(sj)) if os.path.exists(sj) else {})}
        if want != got:
            src = f"--hedra {want['hedra']}" if want.get("hedra") else f"--rive {want['rive']} --blob {want['blob']}"
            extra = "".join(f" --arg {kv}" for kv in want.get("arg", []))
            print(f"FAIL the renders were not made like the goldens; re-render with:\n  golden.py views {src} "
                  f"-o {a.shots} --views {want['views']} --size {want['size']} --pixel {want['pixel']} "
                  f"--look {want.get('look', 'lit')} --texel {want.get('texel', 0)} --elevation {want.get('elevation', 0)} "
                  f"--advance {want.get('advance', '2')}{' --real-sky' if want.get('real_sky') else ''}{extra}")
            return 1
    for f in sorted(os.listdir(a.goldens)):
        if not f.endswith(".png"):
            continue
        g = np.asarray(Image.open(os.path.join(a.goldens, f)).convert("RGB"), dtype=np.int16)
        sp = os.path.join(a.shots, f)
        if not os.path.exists(sp):
            fails.append(f"{f}: no new render")
            continue
        s = np.asarray(Image.open(sp).convert("RGB"), dtype=np.int16)
        if s.shape != g.shape:
            fails.append(f"{f}: size {s.shape[1]}x{s.shape[0]} vs golden {g.shape[1]}x{g.shape[0]}")
            continue
        diff = (np.abs(s - g).max(-1) > 0).mean()
        print(f"{f:14s} {diff:.4%} of pixels differ")
        if diff > a.max_diff:
            fails.append(f"{f}: {diff:.3%} differs (max {a.max_diff:.3%})")
    for f in fails:
        print("FAIL " + f)
    return 1 if fails else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("views", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    g = s.add_mutually_exclusive_group(required=True)
    g.add_argument("--hedra", help="a .rmdl to render with hedra")
    g.add_argument("--rive", help="a Rive project running the splat renderer")
    s.add_argument("--blob", default="splats")
    s.add_argument("-o", "--out", required=True)
    s.add_argument("--views", default="front,right,back,top,iso")
    s.add_argument("--size", type=int, default=480, help="square viewport, screen pixels")
    s.add_argument("--pixel", type=int, default=2, help="screen pixels per art pixel")
    s.add_argument("--arg", action="append", default=[], help="extra renderer input, name=value (repeatable)")
    s.add_argument("--advance", default="2", help="when to capture: frames at 60 fps, or 1.5s / 250ms (a later "
                   "frame for animated goldens)")
    s.add_argument("--real-sky", action="store_true",
                   help="draw the palette's sky instead of the magenta mask sky (renders to audit with palette.py frame; "
                        "the gate needs the mask sky)")
    s.add_argument("--look", choices=["lit", "albedo"], default="lit",
                   help="albedo: no sun shift and no ink, for the colour gate")
    s.add_argument("--texel", type=float, default=0,
                   help="world units per art pixel (the scene's); 0 frames the model")
    s.add_argument("--elevation", type=float, default=0,
                   help="degrees above the horizon for the side views, to match a concept drawn from above")
    s = sub.add_parser("gate", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    s.add_argument("--refs", required=True)
    s.add_argument("--shots", required=True)
    s.add_argument("--views", default="front,right,back,top")
    s.add_argument("-p", "--palette")
    s.add_argument("--min-iou", type=float, default=0.85)
    s.add_argument("--max-aspect-drift", type=float, default=0.08)
    s.add_argument("--max-color-drift", type=float, default=0.25)
    s.add_argument("-o", "--out", help="compare sheet png")
    s.add_argument("--json")
    s = sub.add_parser("snap"); s.add_argument("--shots", required=True); s.add_argument("--goldens", required=True)
    s = sub.add_parser("check"); s.add_argument("--shots", required=True); s.add_argument("--goldens", required=True)
    s.add_argument("--max-diff", type=float, default=0.002)
    a = ap.parse_args()
    return {"views": cmd_views, "gate": cmd_gate, "snap": cmd_snap, "check": cmd_check}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
