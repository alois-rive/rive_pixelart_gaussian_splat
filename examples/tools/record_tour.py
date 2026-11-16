#!/usr/bin/env python3
"""Record a reel of scenes: one continuous camera turn across all of them, each scene handing over to
the next with a dithered fade while both turn in step, merged into one video.

  (from examples/)
  python3 tools/record_tour.py dioramas/*/scene dioramas/rive/scene -o ../showcase.mp4 --seconds 10 \
      --overlap 1.2 --hold 1.5 --scene-arg dioramas/rive/scene:fxOffset=3.6 \
      --scene-arg dioramas/rive/scene:fxStopAt=10.05
                                     (the Rive scene last; its FX cascade lands as the camera stops, then holds)
  python3 tools/record_tour.py dioramas/winter/scene dioramas/island/scene -o reel.mp4 --seconds 8 --loops 2 --overlap 1

The camera: every scene runs the renderer's shared turntable (`tourRate`, `tourOffset`,
`tourLength`, `tourEase`): one timeline for the whole reel, turning `--loops` times per scene's
`--seconds`, easing in at the reel's start and out at its end. Scene i is captured with its time 0
at i x seconds on that timeline, and every scene shares one base yaw, so during a transition the
outgoing and the incoming scene are seen from the same direction, turning together: one continuous
camera move. The base is chosen so the reel comes to rest on the last scene's authored front view.

The soundtrack (`--music`): tools/reel_music.py scores the reel from the timeline this script
writes next to the video (<out>.timeline.json): every scene starts a bar, so every transition falls
on a downbeat.

The transition: over `--overlap` seconds the incoming scene replaces the outgoing one pixel block by
pixel block through an 8 x 8 Bayer threshold (`--block` capture pixels a cell), the way the scenes
themselves dither. Captions name the scene and its palette (from ../art/palette.json).

Games (or any scene) can follow the tour: `--demo games/*/scene` appends each one played by
itself (`--arg demo=true`) from its first frame for `--demo-seconds`, handing over with the same
dithered fade; the turn of the tour ends before them. `--demo-first` puts them before the tour
instead, so the reel ends on the tour's last scene at rest.

A scene named twice keeps its LAST position (`dioramas/*/scene dioramas/rive/scene` puts the Rive scene last). Frames are
scaled by a whole `--scale` with nearest-neighbour sampling. `--fps` must divide 60. Needs ffmpeg,
Pillow and NumPy.
"""
import argparse
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile

import numpy as np
from PIL import Image, ImageDraw

BAYER8 = np.array([[0, 48, 12, 60, 3, 51, 15, 63], [32, 16, 44, 28, 35, 19, 47, 31],
                   [8, 56, 4, 52, 11, 59, 7, 55], [40, 24, 36, 20, 43, 27, 39, 23],
                   [2, 50, 14, 62, 1, 49, 13, 61], [34, 18, 46, 30, 33, 17, 45, 29],
                   [10, 58, 6, 54, 9, 57, 5, 53], [42, 26, 38, 22, 41, 25, 37, 21]], dtype=np.float64)


def scene_name(scene):
    return os.path.basename(os.path.dirname(os.path.abspath(scene))) or os.path.basename(scene)


def palette_name(scene):
    p = os.path.join(scene, "..", "art", "palette.json")
    try:
        return json.load(open(p)).get("name", "")
    except (OSError, ValueError):
        return ""


def authored_yaw(scene):
    try:
        s = open(os.path.join(scene, "scene.rml")).read()
    except OSError:
        return 35.0
    m = re.search(r'<ScriptInputNumber propertyValue="([-\d.]+)" name="yaw"/>', s)
    return float(m.group(1)) if m else 35.0


def tour_angle(t, rate, length, ease):
    """The renderer's tourAngle, for landing the last scene."""
    e = max(ease, 0.001)
    t = min(max(t, 0.0), length)
    ramp = lambda u: u ** 3 - 0.5 * u ** 4
    if t < e:
        return rate * e * ramp(t / e)
    if t < length - e:
        return rate * (0.5 * e + (t - e))
    return rate * (length - e) - rate * e * ramp((length - t) / e)


def capture(scene, frames_dir, count, a, extra_args, own=()):
    os.makedirs(frames_dir, exist_ok=True)
    step = 60 // a.fps
    cmd_file = frames_dir + ".commands"
    with open(cmd_file, "w") as f:
        for k in range(count):
            f.write(f"screenshot {os.path.join(frames_dir, f'f{k:05d}.png')}\n")
            f.write(f"advance {step}\n")
        f.write("quit\n")
    cmd = ["rive", scene, f"--commands={cmd_file}", f"--viewport={a.size}", "--quiet"]
    for k, v in extra_args.items():
        cmd += ["--arg", f"{k}={v}"]
    for kv in list(a.arg) + list(own):
        cmd += ["--arg", kv]
    r = subprocess.run(cmd, capture_output=True, text=True)
    got = len([f for f in os.listdir(frames_dir) if f.endswith(".png")])
    if r.returncode != 0 or got < count:
        sys.stderr.write(r.stdout[-2000:] + r.stderr[-2000:])
        raise SystemExit(f"{scene}: capture failed ({got}/{count} frames)")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("scenes", nargs="+", help="Rive project directories, in order")
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--seconds", type=float, default=8, help="each scene's time on screen")
    ap.add_argument("--loops", type=float, default=2, help="camera turns per scene")
    ap.add_argument("--overlap", type=float, default=1.0, help="dithered transition, seconds")
    ap.add_argument("--ease", type=float, default=1.5, help="ease in at the reel's start, out at its end")
    ap.add_argument("--hold", type=float, default=1.0, help="seconds held on the last scene's front view")
    ap.add_argument("--fps", type=int, default=30, choices=[10, 12, 15, 20, 30, 60])
    ap.add_argument("--size", default="640x400")
    ap.add_argument("--scale", type=int, default=2)
    ap.add_argument("--block", type=int, default=4, help="capture pixels per dither cell")
    ap.add_argument("--crf", type=int, default=19)
    ap.add_argument("--no-label", dest="label", action="store_false")
    ap.add_argument("--arg", action="append", default=[], help="extra renderer input for every scene")
    ap.add_argument("--demo", nargs="*", default=[], metavar="SCENE",
                    help="scenes appended after the tour, each played in demo mode from its first frame")
    ap.add_argument("--demo-seconds", type=float, default=8, help="each demo scene's time on screen")
    ap.add_argument("--demo-first", action="store_true",
                    help="play the demo scenes first and end on the tour (the turn eases in where it begins)")
    ap.add_argument("--scene-arg", action="append", default=[], metavar="SCENE:NAME=VALUE",
                    help="a renderer input for one scene (its directory), e.g. dioramas/rive/scene:fxOffset=3.6")
    ap.add_argument("--keep", help="keep the frames in this directory")
    ap.add_argument("--music", action="store_true",
                    help="score it: tools/reel_music.py writes a soundtrack whose downbeats land on the transitions")
    a = ap.parse_args()
    if 60 % a.fps:
        raise SystemExit("--fps must divide 60")
    if not shutil.which("ffmpeg"):
        raise SystemExit("ffmpeg not found")

    order = []
    for s in a.scenes:  # keep each scene's LAST mention
        key = os.path.realpath(s)
        order = [o for o in order if os.path.realpath(o) != key] + [s]
    demos = []
    for s_ in a.demo:
        key = os.path.realpath(s_)
        demos = [o for o in demos if os.path.realpath(o) != key] + [s_]
    n = len(order)
    work = os.path.abspath(a.keep) if a.keep else tempfile.mkdtemp(prefix="reel-")
    os.makedirs(work, exist_ok=True)
    D, O, fps = a.seconds, a.overlap, a.fps
    rate = 360.0 * a.loops / D
    length = n * D  # the turntable timeline; the hold after it is still

    # one shared camera: every scene is seen from the same yaw at the same moment (so a transition looks
    # like one continuous move), and that yaw comes to rest on the last scene's authored front view
    base = (authored_yaw(order[-1]) - tour_angle(length, rate, length, a.ease)) % 360.0 if n else 0.0

    # the segments: (scene, start on the reel, seconds on screen, renderer args, local time offset)
    segs = []
    demo_len = len(demos) * a.demo_seconds
    tour_at = demo_len if a.demo_first else 0.0
    for i, scene in enumerate(order):
        dur = D + (a.hold if i == n - 1 else 0)
        args = {"tourRate": f"{rate:.6f}", "tourOffset": f"{i * D:.6f}", "tourLength": f"{length:.6f}",
                "tourEase": f"{a.ease:.6f}", "spin": "0", "yaw": f"{base:.6f}"}
        segs.append((scene, tour_at + i * D, dur, args))
    demo_at = 0.0 if a.demo_first else n * D + (a.hold if n else 0)
    for k, scene in enumerate(demos):
        segs.append((scene, demo_at + k * a.demo_seconds, a.demo_seconds, {"demo": "true"}))
    segs.sort(key=lambda sg: sg[1])
    total = segs[-1][1] + segs[-1][2]
    total_frames = int(round(total * fps))

    for i, (scene, start, dur, args) in enumerate(segs):
        local_len = dur + (O if i < len(segs) - 1 else 0)
        own = [sa.split(":", 1)[1] for sa in a.scene_arg
               if ":" in sa and os.path.realpath(sa.split(":", 1)[0]) == os.path.realpath(scene)]
        count = int(round(local_len * fps)) + 1
        capture(scene, os.path.join(work, f"{i:02d}"), count, a, args, own)
        print(f"{scene_name(scene)}: {count} frames, reel {start:.1f}-{start + local_len:.1f} s", flush=True)

    # composite: segment i owns [start_i, start_i + dur_i); over its first O seconds it dithers in
    w, h = (int(v) for v in a.size.split("x"))
    yy, xx = np.mgrid[0:h, 0:w]
    thresh = (BAYER8[(yy // a.block) % 8, (xx // a.block) % 8] + 0.5) / 64.0
    out_dir = os.path.join(work, "reel")
    os.makedirs(out_dir, exist_ok=True)

    def frame(i, local):
        k = int(round(local * fps))
        p = os.path.join(work, f"{i:02d}", f"f{k:05d}.png")
        return np.asarray(Image.open(p).convert("RGB"))

    captions = [f"{scene_name(sg[0])}" + (f"  /  {palette_name(sg[0])}" if palette_name(sg[0]) else "") for sg in segs]
    starts = [sg[1] for sg in segs]
    for g in range(total_frames):
        t = g / fps
        i = max(k for k in range(len(segs)) if starts[k] <= t + 1e-9)
        local = t - starts[i]
        cur = frame(i, local)
        cap = captions[i]
        if i > 0 and local < O:
            p = local / O
            prev = frame(i - 1, t - starts[i - 1])
            cur = np.where((thresh < p)[..., None], cur, prev)
            if p < 0.5:
                cap = captions[i - 1]
        im = Image.fromarray(cur.astype(np.uint8))
        if a.label:
            d = ImageDraw.Draw(im)
            tw, th = d.textbbox((0, 0), cap)[2:]
            d.rectangle([0, h - th - 8, tw + 10, h], fill=(0, 0, 0))
            d.text((5, h - th - 5), cap, fill=(255, 255, 255))
        im.save(os.path.join(out_dir, f"g{g:05d}.png"))

    vf = f"scale={w * a.scale}:{h * a.scale}:flags=neighbor"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(fps), "-i",
                    os.path.join(out_dir, "g%05d.png"), "-vf", vf, "-c:v", "libx264", "-crf", str(a.crf),
                    "-preset", "slow", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
                    os.path.abspath(a.out)], check=True)
    timeline = {"segments": [{"start": sg[1], "duration": sg[2], "kind": "demo" if "demo" in sg[3] else "tour",
                              "scene": scene_name(sg[0])} for sg in segs], "total": total_frames / fps}
    tl_path = os.path.splitext(os.path.abspath(a.out))[0] + ".timeline.json"
    with open(tl_path, "w") as f:
        json.dump(timeline, f, indent=1)
    if a.music:
        here = os.path.dirname(os.path.abspath(__file__))
        wav = os.path.splitext(os.path.abspath(a.out))[0] + ".wav"
        subprocess.run([sys.executable, os.path.join(here, "reel_music.py"), "--timeline", tl_path, "-o", wav,
                        "--mux", os.path.abspath(a.out)], check=True)
    print(f"wrote {a.out}: {n} toured + {len(demos)} demo scenes, {total_frames / fps:.1f} s, {rate:.0f} deg/s, "
          f"{O:.1f} s dithered transitions")
    if not a.keep:
        shutil.rmtree(work, ignore_errors=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
