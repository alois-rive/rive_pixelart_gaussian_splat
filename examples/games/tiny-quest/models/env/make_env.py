# Writes the GLBs of Tiny Quest's island and everything that is not the hero, straight from code
# (meshkit.py: flat-shaded low-poly primitives, colours exact MarshMellow32 hexes):
#   island.glb   the static world: the tile grid from MAP (sand, meadow, wood, road, plaza, hill tiers, the
#                shrine), cliff walls, the river and the sea shallows with foam, the bridge, trees, houses,
#                the inn's stall, a well, the shrine's arch, rocks, tufts, flowers, a signpost
#   slime.glb, bat.glb, shroom.glb, warden.glb       the monsters (game bones; the warden guards the shrine)
#   marker.glb, pin.glb, puff.glb, spark.glb, coin.glb, potion.glb, slash.glb, guard.glb, dust.glb   effects
# Run from models/env: /usr/bin/python3 make_env.py. glTF: Y up, +Z towards the model's front.
# MAP, LEVEL_Y and the tile size are the same numbers as in scene/game.as (MAP, levelY).
import math
import random

import numpy as np

from meshkit import Mesh, rot_x, rot_y, rot_z

# x (columns 0..12) left to right, z (rows 0..9) back to front; tile (i, j) is centred at (i - 6, j - 4.5)
MAP = [
    "~~.11.R..~~~~",
    "~.1221Rgg.~~~",
    ".12S21Rwgg.~~",
    ".1221wRwwgg.~",
    ".g11wg=rrgw.~",
    ".ggwwgRgrrg.~",
    "~.ggwgRgwrIh.",
    "~..gg.RggVVh.",
    "~~....R.ghV.~",
    "~~~~..R....~~",
]
W, D = len(MAP[0]), len(MAP)
LEVEL = {".": 0, "g": 1, "w": 1, "r": 1, "V": 1, "I": 1, "h": 1, "=": 1, "1": 2, "2": 3, "S": 4}
RIVER_Y = 0.12
SEA_Y = 0.0


def level_y(n):
    return 0.18 if n == 0 else 0.45 + 0.4 * (n - 1)


def cell(i, j):
    if 0 <= i < W and 0 <= j < D:
        return MAP[j][i]
    return "~"


def centre(i, j):
    return i - 6.0, j - 4.5


def is_land(c):
    return c in LEVEL and c != "="


HEX = {"Sand": "#afa491", "SandSide": "#907b67", "Grass": "#767f45", "Floor": "#555735", "Road": "#907b67",
       "Plaza": "#c1bcac", "Cliff": "#71554a", "Slab": "#b2b2b2", "StoneSide": "#7c7c7c", "River": "#2d80a6",
       "Shallow": "#2d80a6", "Foam": "#5eb3bc", "Leaf": "#57797d", "Pine": "#3a5356", "Trunk": "#734141",
       "Wall": "#c1bcac", "Roof": "#8c504d", "Timber": "#734141", "Door": "#593234", "Plank": "#8c504d",
       "Rock": "#7c7c7c", "Tuft": "#a4ab79", "Flower": "#e2b55f", "Bloom": "#b87a66", "Awning": "#8c504d",
       "Cloth": "#c1bcac", "Crystal": "#8f619a", "Brew": "#8f619a", "Water": "#2d80a6"}


def mesh_with(*names):
    m = Mesh()
    for n in names:
        m.material(n, HEX[n])
    return m


# ---------------------------------------------------------------- the island
def island():
    rng = random.Random(7)
    nrng = np.random.default_rng(7)
    m = mesh_with(*HEX.keys())
    top_mat = {".": "Sand", "g": "Grass", "w": "Floor", "r": "Road", "V": "Plaza", "I": "Plaza", "h": "Grass",
               "1": "Grass", "2": "Grass", "S": "Slab"}
    for j in range(D):
        for i in range(W):
            c = cell(i, j)
            x, z = centre(i, j)
            if is_land(c):
                y = level_y(LEVEL[c])
                m.quad(top_mat[c], (x - 0.5, y, z - 0.5), (x + 0.5, y, z - 0.5), (x + 0.5, y, z + 0.5), (x - 0.5, y, z + 0.5),
                       out=(0, 1, 0))
                # walls down to each lower neighbour (or the water)
                for di, dj, a, b in ((1, 0, (0.5, -0.5), (0.5, 0.5)), (-1, 0, (-0.5, 0.5), (-0.5, -0.5)),
                                     (0, 1, (0.5, 0.5), (-0.5, 0.5)), (0, -1, (-0.5, -0.5), (0.5, -0.5))):
                    n = cell(i + di, j + dj)
                    if is_land(n):
                        lo = level_y(LEVEL[n])
                    elif n == "=":
                        lo = RIVER_Y
                    elif n == "R":
                        lo = RIVER_Y
                    else:
                        lo = SEA_Y
                    if y - lo < 0.02:
                        continue
                    mat = "SandSide" if c == "." else ("StoneSide" if c == "S" else "Cliff")
                    p0 = (x + a[0], lo, z + a[1])
                    p1 = (x + b[0], lo, z + b[1])
                    m.quad(mat, p0, p1, (p1[0], y, p1[2]), (p0[0], y, p0[2]), out=(di, 0, dj))
                    if not is_land(n) and n not in ("R", "="):
                        # foam along the shore, on the shallows, as a strip off the wall
                        fx, fz = di * 0.14, dj * 0.14
                        m.quad("Foam", (p0[0], SEA_Y + 0.02, p0[2]), (p1[0], SEA_Y + 0.02, p1[2]),
                               (p1[0] + fx, SEA_Y + 0.02, p1[2] + fz), (p0[0] + fx, SEA_Y + 0.02, p0[2] + fz), out=(0, 1, 0))
            elif c in ("R", "="):
                m.quad("River", (x - 0.5, RIVER_Y, z - 0.5), (x + 0.5, RIVER_Y, z - 0.5), (x + 0.5, RIVER_Y, z + 0.5),
                       (x - 0.5, RIVER_Y, z + 0.5), out=(0, 1, 0))
                # where the river meets the sea, a step down to the shallows
                for dj in (-1, 1):
                    if cell(i, j + dj) == "~":
                        zz = z + 0.5 * dj
                        m.quad("Foam", (x - 0.5, SEA_Y + 0.02, zz), (x + 0.5, SEA_Y + 0.02, zz),
                               (x + 0.5, SEA_Y + 0.02, zz + 0.16 * dj), (x - 0.5, SEA_Y + 0.02, zz + 0.16 * dj), out=(0, 1, 0))
                        m.quad("Foam", (x - 0.5, SEA_Y, zz), (x + 0.5, SEA_Y, zz), (x + 0.5, RIVER_Y, zz), (x - 0.5, RIVER_Y, zz),
                               out=(0, 0, dj))
    # the shallows: sea cells next to land (8-neighbours), out to one cell past the grid
    for j in range(-1, D + 1):
        for i in range(-1, W + 1):
            if cell(i, j) != "~":
                continue
            near = any(is_land(cell(i + a, j + b)) or cell(i + a, j + b) == "R" for a in (-1, 0, 1) for b in (-1, 0, 1))
            if not near:
                continue
            x, z = centre(i, j)
            m.quad("Shallow", (x - 0.5, SEA_Y, z - 0.5), (x + 0.5, SEA_Y, z - 0.5), (x + 0.5, SEA_Y, z + 0.5),
                   (x - 0.5, SEA_Y, z + 0.5), out=(0, 1, 0))

    # ---- decoration
    def tree(mm, x, y, z, kind, s):
        mm.frustum("Trunk", x, y, z, 0.07 * s, 0.055 * s, 0.32 * s, n=6)
        if kind == 0:
            mm.ico("Leaf", x, y + 0.48 * s, z, 0.30 * s, sy=0.85, jitter=0.12, rng=nrng)
            mm.ico("Leaf", x + 0.04 * s, y + 0.74 * s, z - 0.02 * s, 0.21 * s, sy=0.9, jitter=0.12, rng=nrng)
        else:
            for k, (r, h, yy) in enumerate(((0.34, 0.36, 0.22), (0.27, 0.32, 0.44), (0.18, 0.30, 0.64))):
                mm.frustum("Pine", x, y + yy * s, z, r * s, 0.0, h * s, n=7, turn=rng.uniform(0, 50), caps=(True, False))

    groves = []

    for j in range(D):
        for i in range(W):
            c = cell(i, j)
            if not is_land(c):
                continue
            x, z = centre(i, j)
            y = level_y(LEVEL[c])
            if c == "w":
                # a grove: this tile's trees around the tile's centre on the ground, its own GLB (one game bone:
                # the game squashes it while it stands between the camera and the hero or a monster)
                g = mesh_with("Leaf", "Pine", "Trunk")
                spots = [(-0.3, -0.3)] + rng.sample([(0.3, -0.32), (-0.32, 0.3)], 1 + (rng.random() < 0.35))
                for (ox, oz) in spots:
                    tree(g, ox + rng.uniform(-0.05, 0.05), 0.0, oz + rng.uniform(-0.05, 0.05), rng.randrange(2),
                         rng.uniform(0.85, 1.1))
                g.write(f"grove{len(groves)}.glb")
                groves.append((i, j))
            elif c in "g12":
                if rng.random() < 0.55:
                    for _ in range(rng.randint(1, 3)):
                        tx, tz = x + rng.uniform(-0.42, 0.42), z + rng.uniform(-0.42, 0.42)
                        if abs(tx - x) < 0.18 and abs(tz - z) < 0.18:
                            continue
                        m.frustum("Tuft", tx, y, tz, 0.07, 0.0, 0.13, n=3, turn=rng.uniform(0, 120), caps=(False, False))
                if rng.random() < 0.35:
                    fx, fz = x + rng.choice([-1, 1]) * rng.uniform(0.25, 0.4), z + rng.choice([-1, 1]) * rng.uniform(0.25, 0.4)
                    mat = rng.choice(["Flower", "Bloom"])
                    for k in range(3):
                        m.box(mat, fx + rng.uniform(-0.08, 0.08), y + 0.06, fz + rng.uniform(-0.08, 0.08), 0.07, 0.07, 0.07)
            elif c == ".":
                if rng.random() < 0.3:
                    rx, rz = x + rng.uniform(-0.35, 0.35), z + rng.uniform(-0.35, 0.35)
                    m.ico("Rock", rx, y + 0.04, rz, rng.uniform(0.1, 0.17), sy=0.7, jitter=0.15, rng=nrng)
            elif c == "h":
                house(m, x, y, z, rng)
            elif c == "I":
                stall(m, x, y, z)
            elif c == "S":
                arch(m, x, y, z)
            elif c == "V" and (i, j) == (10, 8):
                well(m, x + 0.28, y, z + 0.28)
    # the bridge over the river at (6, 4): planks across x, rails along both sides
    bx, bz = centre(6, 4)
    deck = level_y(1) + 0.05
    for k in range(5):
        m.box("Plank", bx - 0.4 + 0.2 * k, deck - 0.05, bz, 0.18, 0.1, 0.86)
    for side in (-1, 1):
        m.box("Timber", bx, deck + 0.13, bz + side * 0.4, 1.1, 0.06, 0.06)
        for px in (-0.5, 0.5):
            m.box("Timber", bx + px, deck + 0.05, bz + side * 0.4, 0.08, 0.26, 0.08)
    # a signpost by the road, east of the bridge
    sx, sz = centre(7, 4)
    m.box("Timber", sx + 0.3, level_y(1) + 0.22, sz + 0.36, 0.06, 0.44, 0.06)
    m.box("Plank", sx + 0.26, level_y(1) + 0.38, sz + 0.36, 0.3, 0.12, 0.04)
    m.write("island.glb")
    # the groves' places, for the bake file (scene.bake.json) and game.as (it reads them from the bones)
    print("groves:", ", ".join(f"grove{k} ({i}, {j}) -> [{centre(i, j)[0]}, {level_y(1)}, {centre(i, j)[1]}]" for k, (i, j) in enumerate(groves)))


def house(m, x, y, z, rng):
    w, d, h = 0.72, 0.62, 0.42
    m.box("Wall", x, y + h / 2, z, w, h, d, skip=("-y",))
    # a gable roof along x, overhanging
    rh = 0.3
    ox, oz = w / 2 + 0.08, d / 2 + 0.1
    ridge_y = y + h + rh
    a = (x - ox, y + h - 0.02, z - oz)
    b = (x + ox, y + h - 0.02, z - oz)
    c = (x + ox, ridge_y, z)
    e = (x - ox, ridge_y, z)
    f = (x - ox, y + h - 0.02, z + oz)
    g = (x + ox, y + h - 0.02, z + oz)
    m.quad("Roof", a, b, c, e, out=(0, 0.6, -1))
    m.quad("Roof", f, e, c, g, out=(0, 0.6, 1))
    # gable ends (wall colour)
    m.add("Wall", [[(x - w / 2, y + h, z - d / 2), (x - w / 2, ridge_y - 0.02, z), (x - w / 2, y + h, z + d / 2)]], out=(-1, 0, 0))
    m.add("Wall", [[(x + w / 2, y + h, z - d / 2), (x + w / 2, ridge_y - 0.02, z), (x + w / 2, y + h, z + d / 2)]], out=(1, 0, 0))
    # door on the front (+z) and a window on the +x side, proud by a splat
    m.box("Door", x - 0.12, y + 0.14, z + d / 2 + 0.03, 0.16, 0.28, 0.05)
    m.box("Timber", x + w / 2 + 0.03, y + 0.24, z, 0.05, 0.14, 0.18)
    m.box("Rock", x + 0.2, ridge_y - 0.05, z - 0.08, 0.1, 0.24, 0.1)


def stall(m, x, y, z):
    # the inn's market stall at the back of its tile: counter, posts, a striped awning, a potion on the counter
    cx, cz = x - 0.12, z - 0.22
    m.box("Plank", cx, y + 0.13, cz, 0.62, 0.26, 0.26)
    for px in (-0.3, 0.3):
        m.box("Timber", cx + px, y + 0.3, cz - 0.1, 0.06, 0.6, 0.06)
    for k in range(4):
        mat = "Awning" if k % 2 == 0 else "Cloth"
        x0 = cx - 0.36 + 0.18 * k
        m.quad(mat, (x0, y + 0.62, cz - 0.18), (x0 + 0.18, y + 0.62, cz - 0.18), (x0 + 0.18, y + 0.5, cz + 0.2),
               (x0, y + 0.5, cz + 0.2), out=(0, 1, 0.3))
    m.ico("Brew", cx + 0.1, y + 0.33, cz + 0.02, 0.07)
    m.box("Cloth", cx + 0.1, y + 0.42, cz + 0.02, 0.04, 0.06, 0.04)


def arch(m, x, y, z):
    # two stone pillars and a lintel at the back of the shrine's tile, a purple crystal on top
    for px in (-0.36, 0.36):
        m.box("Rock", x + px, y + 0.42, z - 0.36, 0.18, 0.84, 0.18)
    m.box("Rock", x, y + 0.9, z - 0.36, 0.98, 0.14, 0.24)
    m.frustum("Crystal", x, y + 0.97, z - 0.36, 0.09, 0.0, 0.3, n=4, turn=45)
    m.frustum("Crystal", x, y + 0.97, z - 0.36, 0.09, 0.0, 0.0001, n=4, turn=45, caps=(True, False))


def well(m, x, y, z):
    m.frustum("Rock", x, y, z, 0.17, 0.17, 0.2, n=8)
    m.quad("Water", (x - 0.1, y + 0.15, z - 0.1), (x + 0.1, y + 0.15, z - 0.1), (x + 0.1, y + 0.15, z + 0.1),
           (x - 0.1, y + 0.15, z + 0.1), out=(0, 1, 0))
    for px in (-0.15, 0.15):
        m.box("Timber", x + px, y + 0.32, z, 0.04, 0.3, 0.04)
    m.box("Roof", x, y + 0.48, z, 0.42, 0.06, 0.3)


# ---------------------------------------------------------------- monsters (origin on the ground, front +Z)
def slime():
    m = Mesh()
    m.material("Jelly", "#5eb3bc")
    m.material("Eye", "#3c3a3f")
    m.material("Sprout", "#a4ab79")
    m.ico("Jelly", 0, 0.2, 0, 0.29, sy=0.72, cut=0.0)
    m.frustum("Jelly", 0, 0.0, 0, 0.27, 0.27, 0.04, n=10, caps=(False, False))
    for sx in (-1, 1):
        m.box("Eye", sx * 0.09, 0.25, 0.235, 0.065, 0.1, 0.05)
    # a sprout on top: a short stem and two leaves
    m.box("Sprout", 0, 0.42, 0, 0.04, 0.1, 0.04)
    for sx in (-1, 1):
        m.add("Sprout", [[(0, 0.46, 0), (sx * 0.17, 0.53, 0.04), (sx * 0.1, 0.47, -0.06)]], out=(0, 1, 0))
    m.write("slime.glb")


def bat():
    m = Mesh()
    m.material("Fur", "#6e4d7e")
    m.material("Wing", "#4e3c5c")
    m.material("Glint", "#e2b55f")
    by = 0.55
    m.ico("Fur", 0, by, 0, 0.17, sy=0.95)
    for sx in (-1, 1):
        m.frustum("Fur", sx * 0.08, by + 0.1, -0.01, 0.05, 0.0, 0.13, n=4, turn=45)
        m.box("Glint", sx * 0.06, by + 0.03, 0.155, 0.05, 0.05, 0.04)
        # a wing: a stiff membrane in three panels, two-sided, its edge scalloped
        pts = [(0.12, 0.08), (0.48, 0.2), (0.56, -0.02), (0.42, -0.04), (0.33, -0.12), (0.22, -0.06), (0.12, -0.06)]
        p = [(sx * a, by + b, -0.02) for a, b in pts]
        for k in range(1, len(p) - 1):
            m.add("Wing", [[p[0], p[k], p[k + 1]]], out=(0, 0, 1))
        # thickness so a wing seen edge-on still has a spar
        m.box("Wing", sx * 0.3, by + 0.13, -0.02, 0.36, 0.035, 0.04, R=rot_z(sx * 19))
    m.write("bat.glb")


def shroom():
    m = Mesh()
    m.material("Stem", "#c1bcac")
    m.material("Cap", "#8c504d")
    m.material("Spot", "#c1bcac")
    m.material("Eye", "#3c3a3f")
    m.material("Foot", "#734141")
    m.frustum("Stem", 0, 0.05, 0, 0.13, 0.11, 0.25, n=8)
    m.frustum("Cap", 0, 0.27, 0, 0.32, 0.15, 0.15, n=8)
    m.frustum("Cap", 0, 0.42, 0, 0.15, 0.0, 0.07, n=8, caps=(False, False))
    for k in range(5):
        a = math.radians(30 + 72 * k)
        m.box("Spot", 0.22 * math.sin(a), 0.36, 0.22 * math.cos(a), 0.09, 0.05, 0.09, R=rot_y(math.degrees(a)) @ rot_x(30))
    for sx in (-1, 1):
        m.box("Eye", sx * 0.05, 0.19, 0.12, 0.04, 0.07, 0.04)
        m.box("Foot", sx * 0.08, 0.03, 0.02, 0.1, 0.06, 0.16)
    m.write("shroom.glb")


def warden():
    m = Mesh()
    m.material("Rock", "#7c7c7c")
    m.material("Moss", "#767f45")
    m.material("Eye", "#5eb3bc")
    m.material("Crystal", "#8f619a")
    m.box("Rock", 0, 0.18, 0, 0.78, 0.36, 0.56)
    m.frustum("Rock", 0, 0.34, 0, 0.62, 0.5, 0.62, n=4, turn=45, sz=0.72)
    m.box("Rock", 0, 1.16, 0.02, 0.56, 0.42, 0.5)
    m.box("Moss", 0, 1.41, 0.0, 0.62, 0.1, 0.56)
    m.box("Moss", -0.18, 1.32, 0.27, 0.16, 0.14, 0.04)
    m.box("Moss", 0.3, 0.9, 0.0, 0.2, 0.1, 0.44)
    m.box("Eye", 0, 1.17, 0.27, 0.2, 0.11, 0.05)
    for sx in (-1, 1):
        m.box("Rock", sx * 0.55, 0.72, 0, 0.24, 0.42, 0.3, R=rot_z(sx * 8))
        m.box("Rock", sx * 0.6, 0.38, 0.03, 0.32, 0.3, 0.36)
        m.frustum("Crystal", sx * 0.17, 1.44, -0.06, 0.08, 0.0, 0.3 + 0.08 * (sx > 0), n=4, turn=45, R=rot_z(-sx * 14))
    m.frustum("Crystal", 0, 0.6, 0.31, 0.08, 0.0, 0.0001, n=4, turn=45, R=rot_x(90))
    m.box("Crystal", 0, 0.62, 0.3, 0.14, 0.14, 0.04, R=rot_z(45))
    m.write("warden.glb")


# ---------------------------------------------------------------- effects
def effects():
    m = Mesh()
    m.material("Mark", "#e2b55f")
    o, t, h = 0.47, 0.11, 0.04
    m.box("Mark", 0, h / 2, -(o - t / 2), 2 * o, h, t)
    m.box("Mark", 0, h / 2, (o - t / 2), 2 * o, h, t)
    m.box("Mark", -(o - t / 2), h / 2, 0, t, h, 2 * o - 2 * t)
    m.box("Mark", (o - t / 2), h / 2, 0, t, h, 2 * o - 2 * t)
    m.write("marker.glb")

    m = Mesh()
    m.material("Mark", "#e2b55f")
    m.frustum("Mark", 0, 0.0, 0, 0.0001, 0.13, 0.2, n=4, turn=45, caps=(False, False))
    m.frustum("Mark", 0, 0.2, 0, 0.13, 0.0, 0.1, n=4, turn=45, caps=(False, False))
    m.write("pin.glb")

    rng = np.random.default_rng(3)
    m = Mesh()
    m.material("Puff", "#c1bcac")
    for (x, y, z, r) in ((0, 0, 0, 0.22), (0.18, 0.08, 0.05, 0.16), (-0.17, 0.06, -0.04, 0.17), (0.02, 0.2, -0.05, 0.15),
                         (0.0, -0.08, 0.15, 0.14)):
        m.ico("Puff", x, y, z, r, jitter=0.12, rng=rng)
    m.write("puff.glb")

    m = Mesh()
    m.material("Spark", "#8f619a")
    m.material("Core", "#5eb3bc")
    for R in (np.eye(3), rot_z(90), rot_x(90)):
        for sgn in (1, -1):
            m.frustum("Spark", 0, 0.04 * sgn, 0, 0.06, 0.0, 0.2 * sgn, n=4, turn=45, R=R, caps=(False, False))
    m.ico("Core", 0, 0, 0, 0.08)
    m.write("spark.glb")

    m = Mesh()
    m.material("Coin", "#e2b55f")
    m.frustum("Coin", 0, -0.02, 0, 0.11, 0.11, 0.04, n=8, R=rot_x(90))
    m.write("coin.glb")

    m = Mesh()
    m.material("Brew", "#8f619a")
    m.material("Glass", "#c1bcac")
    m.material("Cork", "#734141")
    m.ico("Brew", 0, 0.12, 0, 0.12)
    m.frustum("Glass", 0, 0.2, 0, 0.05, 0.045, 0.09, n=6)
    m.frustum("Cork", 0, 0.29, 0, 0.055, 0.05, 0.05, n=6)
    m.write("potion.glb")

    m = Mesh()
    m.material("Slash", "#c1bcac")
    n = 9
    for k in range(n):
        a0 = math.radians(-50 + 130 * k / n)
        a1 = math.radians(-50 + 130 * (k + 1) / n)
        w0 = 0.03 + 0.05 * math.sin(math.pi * k / n)
        w1 = 0.03 + 0.05 * math.sin(math.pi * (k + 1) / n)
        p = [(0.38 * math.cos(a0), 0.38 * math.sin(a0), 0), (0.38 * math.cos(a1), 0.38 * math.sin(a1), 0),
             ((0.38 - w1) * math.cos(a1), (0.38 - w1) * math.sin(a1), 0), ((0.38 - w0) * math.cos(a0), (0.38 - w0) * math.sin(a0), 0)]
        m.quad("Slash", p[0], p[1], p[2], p[3], out=(0, 0, 1))
    m.write("slash.glb")

    m = Mesh()
    m.material("Mark", "#e2b55f")
    n = 8
    for k in range(n):
        a0 = math.radians(22.5 + 360 * k / n)
        a1 = math.radians(22.5 + 360 * (k + 1) / n)
        r0, r1 = 0.4, 0.32
        p = [(r0 * math.cos(a0), r0 * math.sin(a0), 0), (r0 * math.cos(a1), r0 * math.sin(a1), 0),
             (r1 * math.cos(a1), r1 * math.sin(a1), 0), (r1 * math.cos(a0), r1 * math.sin(a0), 0)]
        m.quad("Mark", p[0], p[1], p[2], p[3], out=(0, 0, 1))
    m.write("guard.glb")

    m = Mesh()
    m.material("Dust", "#c1bcac")
    for (x, y, z, r) in ((0, 0.07, 0, 0.09), (0.08, 0.05, 0.03, 0.065), (-0.07, 0.05, -0.02, 0.07)):
        m.ico("Dust", x, y, z, r, jitter=0.1, rng=rng)
    m.write("dust.glb")


if __name__ == "__main__":
    island()
    slime()
    bat()
    shroom()
    warden()
    effects()
