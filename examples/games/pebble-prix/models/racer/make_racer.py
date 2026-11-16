# Writes the racer (the hero: a pebble-shaped roadster with its driver) from one table of measurements
# (racer.spec.md), as GLBs in four paint jobs: racer.glb (red, the player's, the gated hero) and
# racer_blue.glb, racer_pink.glb, racer_gold.glb (the computer cars: only the body and the helmet stripe
# change colour). Then `hedra model convert racer.glb -o racer.rmdl` gives the gate its hedra model.
# Run from models/racer: /usr/bin/python3 make_racer.py
# glTF axes: Y up, the nose towards +Z, origin on the ground under the middle of the car's length.
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
from meshkit import Mesh  # noqa: E402

PAINT = {"red": "#e6482e", "blue": "#28ccdf", "pink": "#cd6093", "gold": "#f4b41b"}
COL = {"Stripe": "#dff6f5", "Tyre": "#39314b", "Hub": "#a0938e", "Grille": "#302c2e", "Lamp": "#f4cca1",
       "Glass": "#8aebf1", "Jacket": "#394778", "Goggles": "#394778", "Helmet": "#dff6f5", "Skin": "#eea160",
       "Pipe": "#7d7071", "Seat": "#39314b"}

YB = 0.15                  # the hull's underside
NOSE, TAIL = 1.375, -1.235 # the hull's ends (the exhaust reaches -1.375)
SW = 0.18                  # half the stripe's width
# stations along the hull: z, half width, side top (shoulder), centre top, cockpit (the tub's floor)
ST = [
    (NOSE, 0.40, 0.48, 0.55, False),
    (1.20, 0.54, 0.60, 0.68, False),
    (0.85, 0.60, 0.68, 0.78, False),
    (0.40, 0.61, 0.74, 0.84, False),
    (0.12, 0.61, 0.78, 0.86, False),
    (0.10, 0.61, 0.78, 0.60, True),
    (-0.50, 0.61, 0.82, 0.60, True),
    (-0.52, 0.60, 0.84, 0.96, False),
    (-1.05, 0.55, 0.84, 0.98, False),
    (TAIL, 0.47, 0.74, 0.86, False),
]
WHEEL_R, WHEEL_W, WHEEL_X, WHEEL_Z = 0.315, 0.30, 0.65, 0.85
HELMET = (0.0, 1.13, -0.22, 0.24)

def section(hw, ys, yc):
    """the hull's cross-section, left to right over the top (the underside is never seen)"""
    sh = hw * 0.78
    return [(-(hw - 0.10), YB), (-hw, YB + 0.13), (-hw, ys), (-sh, ys + 0.65 * (yc - ys)),
            (-SW, yc), (SW, yc), (sh, ys + 0.65 * (yc - ys)), (hw, ys), (hw, YB + 0.13), (hw - 0.10, YB)]

def build(paint):
    m = Mesh()
    m.material("Body", PAINT[paint])
    m.material("Trim", PAINT[paint])
    for k, v in COL.items():
        m.material(k, v)
    secs = [(z, section(hw, ys, yc), cp) for (z, hw, ys, yc, cp) in ST]
    centre = np.array([0, 0.5, 0])
    for (za, sa, ca), (zb, sb, cb) in zip(secs[:-1], secs[1:]):
        cock = ca and cb
        for i in range(len(sa) - 1):
            mat = "Body"
            if i == 4:
                mat = "Seat" if cock else "Stripe"
            a0, a1 = sa[i], sa[i + 1]
            b0, b1 = sb[i], sb[i + 1]
            pa0, pa1 = np.array([a0[0], a0[1], za]), np.array([a1[0], a1[1], za])
            pb0, pb1 = np.array([b0[0], b0[1], zb]), np.array([b1[0], b1[1], zb])
            mid = (pa0 + pa1 + pb0 + pb1) / 4
            out = np.array([mid[0], mid[1] - 0.45, 0.0])
            if cock and i in (3, 4, 5):
                out = np.array([0, 1.0, 0])      # the tub's floor and inner shoulders face up
            m.quad(mat, pa0, pb0, pb1, pa1, out=out)
    # the nose and the tail: flat caps, the stripe carried over the nose
    for (z, sec, _), sgn in ((secs[0], 1), (secs[-1], -1)):
        pts = [np.array([x, y, z]) for x, y in sec]
        body = [p for p in pts]
        m.poly("Body", body, out=[0, 0, sgn])
    # the stripe down the nose face, a hair proud (painted on: kept within the face's own splats)
    # the grille and the headlamps, standing just off the nose face
    zf = NOSE + 0.025
    oct_ = lambda cx, cy, rx, ry: [np.array([cx + rx * np.cos(a), cy + ry * np.sin(a), zf]) for a in np.linspace(0, 2 * np.pi, 9)[:-1] + np.pi / 8]
    m.poly("Grille", oct_(0.0, 0.30, 0.17, 0.08), out=[0, 0, 1])
    for sx in (-1, 1):
        m.poly("Lamp", oct_(sx * 0.27, 0.36, 0.075, 0.075), out=[0, 0, 1])
    # the exhaust
    m.prism("Pipe", (0, 0.30, TAIL - 0.05), (0, 0, 1), 0.07, 0.20, n=6, cap_mat="Grille",
            caps=(True, False))
    # the windscreen: a tilted two-sided pane over the cowl
    a, b = np.array([-0.30, 0.84, 0.30]), np.array([0.30, 0.84, 0.30])
    c, d = np.array([0.26, 1.03, 0.16]), np.array([-0.26, 1.03, 0.16])
    m.quad("Glass", a, b, c, d, out=[0, 0.6, 1])
    # the driver: shoulders in the tub, a big round helmet with a stripe, goggles, a face
    m.box("Jacket", -0.30, 0.30, 0.60, 0.97, -0.44, -0.02, skip=("-y",))
    hx, hy, hz, hr = HELMET
    def helmet_mat(fc):
        if abs(fc[0]) < 0.075 and fc[1] > 0.12:
            return "Trim"
        if fc[2] > 0.05 and 0.0 < fc[1] < 0.10:
            return "Goggles"
        if fc[2] > 0.05 and fc[1] <= 0.0:
            return "Skin"
        return "Helmet"
    m.sphere(helmet_mat, (hx, hy, hz), hr, seg=8, rings=6)
    # the wheels: octagonal tyres with light hubs on their outer faces
    for sx in (-1, 1):
        for sz in (-1, 1):
            m.prism("Tyre", (sx * WHEEL_X, WHEEL_R, sz * WHEEL_Z), (sx, 0, 0), WHEEL_R, WHEEL_W, n=8,
                    hub=(0.14, "Hub"), caps=(False, True))
    return m

if __name__ == "__main__":
    for paint in PAINT:
        m = build(paint)
        name = "racer.glb" if paint == "red" else f"racer_{paint}.glb"
        m.write_glb(os.path.join(HERE, name), "Racer")
        if paint == "red":
            lo, hi = m.bounds()
            print(f"racer: {m.count()} triangles, bounds {np.round(lo, 3)} .. {np.round(hi, 3)}")
