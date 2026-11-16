# Writes the GLBs of Ember Deck that are not the hero, straight from code (meshkit.py: flat-shaded
# low-poly primitives, every colour an exact Ink-Crimson hex):
#   crypt.glb                    the static set: a tiled floor, the back wall of stone blocks with three
#                                arched alcoves (an altar in the middle), two pillars, wall sconces
#   candles0..4.glb, flames0..4.glb   candle clusters and their flames (game bones: flicker)
#   sconce_fire.glb              the cyan soul fire in a sconce (game bones: flicker)
#   mite.glb                     foe 1, the Wax Mite: a squat living candle
#   moth.glb, wing_l.glb, wing_r.glb   foe 2, the Crypt Moth: body and two flapping wings (three bones)
#   warden.glb                   foe 3, the Grave Warden: a frost-blue stone guardian with a tower shield
#   king.glb, king_fire.glb      the boss, the Tallow King: a towering melted candle with a crown of wicks
#   slash.glb, spark.glb, mote.glb, ward.glb, burn.glb   effect pools
# Run from models/env: /usr/bin/python3 make_env.py. glTF: Y up, +Z towards the model's front.
# The candle and sconce places below are the bake's positions (scene.bake.json reads CANDLES too).
import json
import math

import numpy as np

from meshkit import Mesh, rx, ry, rz

C = {"red": "#ff0546", "crimson": "#9c173b", "maroon": "#660f31", "wine": "#450327", "plum": "#270022",
     "night": "#17001d", "ink": "#09010d", "cyan": "#0ce6f2", "blue": "#0098db", "navy": "#1e579c"}
rng = np.random.default_rng(7)

# ------------------------------------------------------------------ the crypt
WALL_Z = -3.0
PILLAR_X = 4.45     # the sconce fires sit at +-(PILLAR_X - 0.68) = 3.77 (scene.bake.json)
ARCHES = [(0.0, 0.0, 1.7, 2.7), (-3.2, 0.7, 1.1, 1.9), (3.2, 0.7, 1.1, 1.9)]   # centre x, sill y, width, top y


def in_arch(x, y):
    for cx, sill, w, top in ARCHES:
        hw = w / 2
        if abs(x - cx) < hw and sill <= y:
            # a stepped round arch: the opening narrows over its top half-width
            spring = top - hw
            if y < spring:
                return True
            dy = y - spring
            if dx_ok(x - cx, dy, hw):
                return True
    return False


def dx_ok(dx, dy, r):
    return dx * dx + dy * dy < r * r


def crypt():
    m = Mesh("Crypt")
    m.mat("TileA", C["plum"]); m.mat("TileB", C["night"]); m.mat("TileC", C["wine"])
    m.mat("Block", C["wine"]); m.mat("BlockD", C["plum"]); m.mat("BlockL", C["maroon"])
    m.mat("Recess", C["night"]); m.mat("Pillar", C["maroon"]); m.mat("Trim", C["maroon"])
    m.mat("Altar", C["plum"]); m.mat("AltarTop", C["maroon"]); m.mat("Iron", C["night"])
    m.mat("Rune", C["navy"])
    # floor: 1 m tiles, a checker of two stones with a few lighter ones
    for i in range(-6, 6):
        for j in range(-3, 3):
            x0, z0 = i, j
            k = (i + j) % 2
            mat = "TileA" if k == 0 else "TileB"
            if rng.random() < 0.12:
                mat = "TileC"
            m.quad(mat, (x0, 0, z0), (x0 + 1, 0, z0), (x0 + 1, 0, z0 + 1), (x0, 0, z0 + 1), out=(0, 1, 0))
    # a rune ring on the floor between the fighters, drawn as its own tiles' colour (coplanar with
    # nothing: the floor quads under it are cut out by drawing the ring as raised slabs 0.08 thick)
    for a in range(0, 360, 30):
        c = (1.0 * math.cos(math.radians(a)), 0.04, -1.2 + 0.5 * math.sin(math.radians(a)))
        m.box("Rune", c, (0.28, 0.08, 0.14), R=ry(-a + 90))
    # the back wall: stone blocks 0.8 x 0.5 in running bond, skipping the arched openings
    H = 4.6
    rows = int(H / 0.5)
    for r in range(rows):
        y0 = r * 0.5
        off = 0.4 if r % 2 else 0.0
        x = -6.4 + off
        while x < 6.4:
            x1 = min(x + 0.8, 6.4)
            xc, yc = (x + x1) / 2, y0 + 0.25
            # cut blocks into four quarters so the arches step at 0.4 x 0.25
            for qx in (0, 1):
                for qy in (0, 1):
                    ax, bx = x + (x1 - x) * qx / 2, x + (x1 - x) * (qx + 1) / 2
                    ay, by = y0 + 0.25 * qy, y0 + 0.25 * (qy + 1)
                    if in_arch((ax + bx) / 2, (ay + by) / 2):
                        continue
                    mat = "Block"
                    h = (hash((round(xc * 10), r)) % 7)
                    if h in (0, 3):
                        mat = "BlockD"
                    m.quad(mat, (ax, ay, WALL_Z), (bx, ay, WALL_Z), (bx, by, WALL_Z), (ax, by, WALL_Z), out=(0, 0, 1))
            x = x1
    # the recesses behind the arches: a back, a floor (sill) and side walls
    for cx, sill, w, top in ARCHES:
        d = 0.7
        m.quad("Recess", (cx - w / 2, sill, WALL_Z - d), (cx + w / 2, sill, WALL_Z - d), (cx + w / 2, top, WALL_Z - d),
               (cx - w / 2, top, WALL_Z - d), out=(0, 0, 1))
        m.quad("BlockD", (cx - w / 2, sill, WALL_Z - d), (cx + w / 2, sill, WALL_Z - d), (cx + w / 2, sill, WALL_Z),
               (cx - w / 2, sill, WALL_Z), out=(0, 1, 0))
        for s in (-1, 1):
            xs = cx + s * w / 2
            m.quad("Recess", (xs, sill, WALL_Z - d), (xs, sill, WALL_Z), (xs, top, WALL_Z), (xs, top, WALL_Z - d), out=(-s, 0, 0))
        if sill > 0:   # a sill ledge sticking out under a niche
            m.box("Trim", (cx, sill - 0.08, WALL_Z + 0.1), (w + 0.3, 0.16, 0.2))
    # the altar in the middle alcove
    m.box("Altar", (0, 0.45, WALL_Z - 0.3), (1.2, 0.9, 0.7), skip=("-y",))
    m.box("AltarTop", (0, 0.95, WALL_Z - 0.28), (1.35, 0.12, 0.78), skip=("-y",))
    # a skirting step along the wall
    m.box("Trim", (0, 0.1, WALL_Z + 0.12), (12.8, 0.2, 0.24), skip=("-y", "-z"))
    # pillars, with a base and a capital
    for px in (-PILLAR_X, PILLAR_X):
        m.box("Pillar", (px, 2.3, -2.3), (0.72, 4.6, 0.72), skip=("-y",))
        m.box("Trim", (px, 0.15, -2.3), (0.95, 0.3, 0.95), skip=("-y",))
        m.box("Trim", (px, 3.4, -2.3), (0.95, 0.24, 0.95))
    # sconces on the pillars' inner faces: an iron cup on a bracket
    for sx in (-1, 1):
        x = sx * (PILLAR_X - 0.36)
        m.box("Iron", (x - sx * 0.15, 1.75, -2.3), (0.3, 0.08, 0.1))
        m.prism("Iron", (x - sx * 0.32, 1.78, -2.3), 0.08, 0.17, 0.16, n=6)
    m.write("crypt.glb")


# ------------------------------------------------------------------ candles and their flames
# clusters: (x, y, z) of the base, then candles (dx, dz, height, radius)
CANDLES = [
    ((0.0, 1.01, -3.3), [(-0.45, 0.05, 0.42, 0.08), (-0.2, -0.1, 0.62, 0.09), (0.05, 0.08, 0.32, 0.08),
                         (0.3, -0.08, 0.52, 0.09), (0.5, 0.1, 0.28, 0.07)]),
    ((-3.2, 0.7, -3.25), [(-0.2, 0.0, 0.5, 0.09), (0.12, 0.08, 0.32, 0.08), (0.28, -0.1, 0.22, 0.07)]),
    ((3.2, 0.7, -3.25), [(-0.25, -0.05, 0.26, 0.08), (0.0, 0.08, 0.46, 0.09), (0.25, -0.05, 0.36, 0.08)]),
    ((-3.75, 0.0, -1.55), [(-0.2, 0.0, 0.62, 0.1), (0.15, 0.15, 0.4, 0.09), (0.2, -0.2, 0.28, 0.08)]),
    ((3.75, 0.0, -1.55), [(0.2, 0.0, 0.58, 0.1), (-0.15, 0.15, 0.36, 0.09), (-0.22, -0.18, 0.24, 0.08)]),
]
FLAME_Y = 0.12   # a flame cluster's pivot sits this far above its tallest candle's base


def candles():
    info = []
    for k, (base, cs) in enumerate(CANDLES):
        m = Mesh(f"Candles{k}")
        m.mat("Wax", C["crimson"]); m.mat("Drip", C["red"]); m.mat("Wick", C["plum"])
        f = Mesh(f"Flames{k}")
        f.mat("Fire", C["red"])
        top = max(h for _, _, h, _ in cs)
        for dx, dz, h, r in cs:
            m.prism("Wax", (dx, 0, dz), r, r * 0.92, h, n=6, top_m="Drip")
            m.box("Drip", (dx + r * 0.6, h - 0.08, dz + r * 0.6), (0.06, 0.14, 0.06))
            m.box("Wick", (dx, h + 0.03, dz), (0.04, 0.06, 0.04))
            # the flame, relative to the cluster's pivot (base + (0, top + FLAME_Y, 0))
            f.flame("Fire", (dx, h + 0.04 - top - FLAME_Y, dz), 0.13, 0.26, n=5)
        m.write(f"candles{k}.glb")
        f.write(f"flames{k}.glb")
        info.append({"base": base, "pivot": [base[0], base[1] + top + FLAME_Y, base[2]]})
    # the sconces' soul fires (pivot at the cup's rim)
    s = Mesh("SconceFire")
    s.mat("Soul", C["cyan"])
    s.flame("Soul", (0, -0.02, 0), 0.24, 0.42, n=6)
    s.write("sconce_fire.glb")
    json.dump(info, open("candles.json", "w"), indent=1)


# ------------------------------------------------------------------ foes
def mite():
    m = Mesh("Mite")
    m.mat("Wax", C["crimson"]); m.mat("Drip", C["red"]); m.mat("Leg", C["wine"]); m.mat("Dark", C["plum"])
    m.mat("Eye", C["cyan"]); m.mat("Fire", C["red"])
    for s in (-1, 1):
        m.box("Leg", (s * 0.18, 0.08, 0.02), (0.16, 0.16, 0.22))
        m.box("Wax", (s * 0.44, 0.42, 0.02), (0.14, 0.14, 0.14), R=rz(s * 20))
    m.prism("Wax", (0, 0.14, 0), 0.4, 0.33, 0.62, n=8, top_m="Drip")
    m.prism("Drip", (0, 0.76, 0), 0.34, 0.27, 0.1, n=8, caps=(False, True))
    for a, L in ((20, 0.3), (75, 0.18), (130, 0.26), (200, 0.22), (250, 0.3), (320, 0.16)):
        c = ry(a)
        p = c @ np.array([0, 0, 0.37])
        m.box("Drip", (p[0], 0.8 - L / 2, p[2]), (0.1, L, 0.06), R=c)
    m.box("Dark", (0, 0.92, 0), (0.07, 0.12, 0.07))
    m.flame("Fire", (0, 0.96, 0), 0.24, 0.36, n=6)
    for s in (-1, 1):
        m.box("Eye", (s * 0.13, 0.52, 0.355), (0.1, 0.13, 0.06))
    m.box("Dark", (0, 0.35, 0.37), (0.22, 0.06, 0.05))
    m.write("mite.glb")


def moth():
    m = Mesh("Moth")
    m.mat("Fur", C["wine"]); m.mat("Band", C["maroon"]); m.mat("Eye", C["cyan"]); m.mat("Feeler", C["crimson"])
    m.ico("Fur", (0, 0, 0), 0.2, s=(1, 1.1, 1.25))
    m.ico("Band", (0, -0.04, -0.36), 0.17, s=(1, 1, 1.6))
    m.ico("Fur", (0, 0.06, 0.27), 0.15)
    for s in (-1, 1):
        m.ico("Eye", (s * 0.1, 0.1, 0.36), 0.075)
        m.box("Feeler", (s * 0.1, 0.32, 0.38), (0.05, 0.36, 0.05), R=rz(-s * 25) @ rx(35))
        m.box("Feeler", (s * 0.2, 0.47, 0.5), (0.16, 0.05, 0.05), R=rz(-s * 25))
    m.write("moth.glb")
    for side, name in ((1, "wing_r"), (-1, "wing_l")):
        w = Mesh(name)
        w.mat("WingIn", C["wine"]); w.mat("WingMid", C["crimson"]); w.mat("WingEye", C["blue"]); w.mat("WingOut", C["maroon"])
        # the forewing in bands from the root out, the hind wing below; in the y = 0 plane, then
        # raised 58 degrees about the body axis
        def P(x, z):
            return (side * x, 0.0, z)
        bands = [(0.04, 0.42, "WingIn"), (0.42, 0.6, "WingMid"), (0.6, 0.72, "WingEye"), (0.72, 0.92, "WingOut")]
        def edge(x):
            return 0.12 + 0.24 * min(x / 0.6, 1.0) - (0.25 * max(x - 0.7, 0) / 0.22), -0.06 - 0.08 * x
        for a, b, mt in bands:
            fa, ba = edge(a); fb, bb = edge(b)
            w.quad(mt, P(a, fa), P(b, fb), P(b, bb), P(a, ba), out=(0, 1, 0))
        w.quad("WingIn", P(0.04, -0.06), P(0.5, -0.14), P(0.42, -0.52), P(0.08, -0.32), out=(0, 1, 0))
        w.quad("WingEye", P(0.3, -0.25), P(0.4, -0.3), P(0.36, -0.4), P(0.27, -0.36), out=(0, 1, 0))
        R = rz(side * 58)
        for mt in w.tris:
            w.tris[mt] = [np.array([R @ v for v in t]) for t in w.tris[mt]]
        w.write(f"{name}.glb")


def warden():
    m = Mesh("Warden")
    m.mat("Stone", C["navy"]); m.mat("Dark", C["night"]); m.mat("Face", C["blue"]); m.mat("Eye", C["cyan"])
    for s in (-1, 1):
        m.box("Dark", (s * 0.24, 0.1, 0.04), (0.34, 0.2, 0.46))
        m.box("Stone", (s * 0.24, 0.42, 0.0), (0.28, 0.46, 0.32))
        m.box("Stone", (s * 0.62, 1.38, 0.0), (0.34, 0.3, 0.38))
        m.box("Stone", (s * 0.64, 0.98, 0.04), (0.22, 0.56, 0.24))
    m.box("Dark", (0, 0.72, 0), (0.72, 0.22, 0.42))
    m.prism("Stone", (0, 0.82, 0), 0.42, 0.55, 0.62, n=4, turn=45, sz=0.6)
    m.box("Face", (0, 1.67, 0.02), (0.38, 0.4, 0.36))
    m.prism("Stone", (0, 1.86, 0.02), 0.32, 0.0, 0.32, n=4, turn=45)
    for s in (-1, 1):
        m.box("Eye", (s * 0.09, 1.7, 0.21), (0.1, 0.07, 0.04))
    # the tower shield on its right arm (-X), facing out and forward
    m.box("Face", (-0.86, 0.95, 0.2), (0.12, 1.25, 0.8), R=ry(-20))
    m.box("Eye", (-0.94, 1.05, 0.2), (0.06, 0.24, 0.24), R=ry(-20) @ rx(45))
    # a stone maul in its left hand (+X), resting on the ground
    m.box("Dark", (0.66, 0.55, 0.32), (0.09, 0.9, 0.09))
    m.box("Stone", (0.66, 0.16, 0.32), (0.34, 0.3, 0.3))
    m.write("warden.glb")


def king():
    m = Mesh("King")
    m.mat("Wax", C["crimson"]); m.mat("Pool", C["maroon"]); m.mat("Drip", C["red"]); m.mat("Dark", C["plum"])
    m.mat("Eye", C["cyan"]); m.mat("Staff", C["night"])
    m.prism("Pool", (0, 0, 0), 0.95, 0.8, 0.14, n=10, caps=(False, True))
    m.prism("Wax", (0, 0.12, 0), 0.72, 0.62, 0.7, n=10)
    m.prism("Wax", (0, 0.8, 0), 0.6, 0.5, 0.95, n=10)
    m.prism("Wax", (0, 1.73, 0), 0.44, 0.4, 0.6, n=10, top_m="Drip")
    for a, y, L in ((10, 1.5, 0.5), (60, 1.6, 0.3), (115, 1.45, 0.45), (170, 1.6, 0.35), (230, 1.5, 0.5), (300, 1.55, 0.3),
                    (35, 0.7, 0.45), (140, 0.75, 0.35), (260, 0.7, 0.4)):
        c = ry(a)
        r = 0.55 if y > 1 else 0.68
        p = c @ np.array([0, 0, r])
        m.box("Drip", (p[0], y - L / 2, p[2]), (0.14, L, 0.07), R=c)
    for s in (-1, 1):
        m.box("Eye", (s * 0.15, 2.05, 0.4), (0.15, 0.11, 0.06))
    m.box("Dark", (0, 1.88, 0.41), (0.3, 0.07, 0.05))
    # the crown: a dark band and five candle stubs
    m.prism("Dark", (0, 2.3, 0), 0.43, 0.45, 0.13, n=10)
    for i in range(5):
        a = math.radians(-90 + 72 * i)
        h = 0.28 if i else 0.4
        m.prism("Drip", (0.33 * math.cos(a), 2.43, 0.33 * math.sin(a) * -1), 0.07, 0.065, h, n=6)
    # arms: thick wax limbs; the right one (-X) holds a staff topped by a soul fire
    m.box("Wax", (-0.68, 1.35, 0.1), (0.26, 0.75, 0.28), R=rz(-28))
    m.box("Wax", (0.68, 1.35, 0.1), (0.26, 0.75, 0.28), R=rz(28))
    m.box("Wax", (-0.88, 1.0, 0.25), (0.26, 0.26, 0.28))
    m.box("Wax", (0.86, 1.0, 0.18), (0.24, 0.24, 0.26))
    m.box("Staff", (-0.9, 1.2, 0.3), (0.09, 2.3, 0.09))
    m.box("Staff", (-0.9, 2.38, 0.3), (0.34, 0.08, 0.09))
    m.write("king.glb")
    f = Mesh("KingFire")      # pivot at the crown's rim (0, 2.43, 0)
    f.mat("Fire", C["red"]); f.mat("Soul", C["cyan"])
    for i in range(5):
        a = math.radians(-90 + 72 * i)
        h = 0.28 if i else 0.4
        f.flame("Fire", (0.33 * math.cos(a), h + 0.0, -0.33 * math.sin(a)), 0.15, 0.3, n=5)
    for sx in (-0.13, 0.13):
        f.flame("Soul", (-0.9 + sx, 2.42 - 2.43, 0.3), 0.15, 0.32, n=5)
    f.write("king_fire.glb")


# ------------------------------------------------------------------ effects
def effects():
    s = Mesh("Slash")
    s.mat("Slash", C["cyan"])
    n = 9
    for i in range(n):
        a0 = math.radians(-70 + 150 * i / n); a1 = math.radians(-70 + 150 * (i + 1) / n)
        t0 = 0.05 + 0.13 * math.sin(math.pi * i / n); t1 = 0.05 + 0.13 * math.sin(math.pi * (i + 1) / n)
        r = 0.75
        p = lambda a, rr, z: (rr * math.cos(a), rr * math.sin(a), z)
        for z in (0.0,):
            s.quad("Slash", p(a0, r - t0, z), p(a1, r - t1, z), p(a1, r + t1, z), p(a0, r + t0, z), out=(0, 0, 1))
    s.write("slash.glb")
    k = Mesh("Spark"); k.mat("Spark", C["red"]); k.octa("Spark", (0, 0, 0), 0.075, sy=1.4); k.write("spark.glb")
    k = Mesh("Mote"); k.mat("Mote", C["cyan"]); k.octa("Mote", (0, 0, 0), 0.075, sy=1.4); k.write("mote.glb")
    w = Mesh("Ward"); w.mat("Ward", C["cyan"])
    R0 = 0.62
    for i in range(6):
        a0 = math.radians(90 + 60 * i); a1 = math.radians(90 + 60 * (i + 1))
        pa = np.array([R0 * math.cos(a0), R0 * math.sin(a0), 0]); pb = np.array([R0 * math.cos(a1), R0 * math.sin(a1), 0])
        c = (pa + pb) / 2; d = pb - pa; L = np.linalg.norm(d)
        w.box("Ward", c, (L + 0.06, 0.09, 0.06), R=rz(math.degrees(math.atan2(d[1], d[0]))))
    w.box("Ward", (0, 0, 0), (0.26, 0.26, 0.06), R=rz(45))
    w.write("ward.glb")
    b = Mesh("Burn"); b.mat("Fire", C["red"])
    b.flame("Fire", (0, 0, 0), 0.3, 0.5, n=6)
    b.flame("Fire", (0.16, 0, 0.05), 0.18, 0.3, n=5)
    b.write("burn.glb")


crypt()
candles()
mite()
moth()
warden()
king()
effects()
