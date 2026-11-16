# Writes Border War's static world as two GLBs (generated, no sheet: art/assets.md is the brief):
#   terrain.glb  the ground: grass with light patches and dark tufts, dirt paths and yards, the
#                river (water, muddy banks) with two sandy fords, as one heightfield whose triangles
#                carry their own materials (no coplanar overlays)
#   woods.glb    every static prop: the woods along the river, a tree line along the top edge,
#                the two gold deposits, the stumps under the harvestable groves, ford stepping
#                stones and rocks
# Run from models/env: /usr/bin/python3 make_env.py. World metres, Y up, +Z towards the camera.
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from meshkit import Mesh, rot_y  # noqa: E402
import layout as L  # noqa: E402

rng = np.random.default_rng(7)

# ---------------------------------------------------------------- terrain
X0, X1, Z0, Z1 = -9.8, 9.8, -9.2, 7.8
CELL = 0.2
nx, nz = int(round((X1 - X0) / CELL)), int(round((Z1 - Z0) / CELL))


def vnoise(seed, scale):
    """Smooth value noise over the map, sampled by np.interp-free bilinear lookups."""
    g = np.random.default_rng(seed).random((int((Z1 - Z0) / scale) + 3, int((X1 - X0) / scale) + 3))

    def f(x, z):
        u, v = (x - X0) / scale, (z - Z0) / scale
        i, j = int(math.floor(v)), int(math.floor(u))
        fu, fv = u - j, v - i
        fu, fv = fu * fu * (3 - 2 * fu), fv * fv * (3 - 2 * fv)
        a = g[i, j] * (1 - fu) + g[i, j + 1] * fu
        b = g[i + 1, j] * (1 - fu) + g[i + 1, j + 1] * fu
        return a * (1 - fv) + b * fv
    return f


patch = vnoise(3, 1.1)
edge = vnoise(11, 0.5)


def height(x, z):
    d = L.river_dist((x, z))
    if d >= L.BANK_W:
        return 0.0
    if L.ford_dist((x, z)) < L.FORD_R + 0.2:
        return -0.05 * (1 - d / L.BANK_W)
    if d <= L.WATER_W:
        return -0.16
    t = (d - L.WATER_W) / (L.BANK_W - L.WATER_W)
    return -0.16 * (1 - t)


yards = [(L.HALL_H, 1.75), (L.HALL_O, 1.75), (L.MINE_H, 1.25), (L.MINE_O, 1.25)]


def classify(x, z):
    d = L.river_dist((x, z))
    wob = (edge(x, z) - 0.5) * 0.12
    if d < L.BANK_W + wob:
        if L.ford_dist((x, z)) < L.FORD_R + wob:
            return "Sand"
        if d < L.WATER_W + 0.04:
            # ripples: short streaks along the flow
            return "Ripple" if (edge(x * 0.6 + 3.1, z * 0.6 - 2.3) > 0.72) else "Water"
        return "Bank"
    for path in L.PATHS_H + L.PATHS_O:
        if L.poly_dist((x, z), path) < L.PATH_W + wob:
            return "Path"
    for (cx, cz), r in yards:
        if math.hypot(x - cx, z - cz) < r + wob * 2:
            return "Path"
    p = patch(x, z)
    if p > 0.66:
        return "GrassLt"
    h = (math.sin(x * 12.9898 + z * 78.233) * 43758.5453) % 1.0
    if h < 0.045:
        return "GrassDk"
    return "Grass"


ground = Mesh()
for name, col in (("Grass", "#26854c"), ("GrassLt", "#5ab552"), ("GrassDk", "#006554"), ("Path", "#a26d3f"),
                  ("Bank", "#6e4c30"), ("Sand", "#ce9248"), ("Water", "#008b8b"), ("Ripple", "#36c5f4")):
    ground.material(name, col)
H = np.zeros((nz + 1, nx + 1))
for i in range(nz + 1):
    for j in range(nx + 1):
        H[i, j] = height(X0 + j * CELL, Z0 + i * CELL)
for i in range(nz):
    for j in range(nx):
        x0, z0 = X0 + j * CELL, Z0 + i * CELL
        p00 = (x0, H[i, j], z0)
        p10 = (x0 + CELL, H[i, j + 1], z0)
        p01 = (x0, H[i + 1, j], z0 + CELL)
        p11 = (x0 + CELL, H[i + 1, j + 1], z0 + CELL)
        if (i + j) % 2 == 0:
            tris = [(p00, p01, p11), (p00, p11, p10)]
        else:
            tris = [(p00, p01, p10), (p10, p01, p11)]
        for t in tris:
            c = np.mean(t, axis=0)
            ground.add(classify(c[0], c[2]), [t], out=(0, 1, 0))
ground.write_glb("terrain.glb")
print("terrain.glb", ground.count(), "triangles")

# ---------------------------------------------------------------- static props
w = Mesh()
for name, col in (("Leaf", "#26854c"), ("Bark", "#6e4c30"), ("Rock", "#5e5b8c"), ("Gold", "#f3a833"),
                  ("Timber", "#6e4c30"), ("Dark", "#2c1e31"), ("Stump", "#a26d3f"), ("Cut", "#dab163")):
    w.material(name, col)


def tree(x, z, s, yaw, seed):
    R = rot_y(yaw)
    t = Mesh()
    t.box("Bark", 0, 0.25, 0, 0.17, 0.5, 0.17)
    t.blob("Leaf", 0, 1.0, 0, 0.62, sy=0.85, seed=seed)
    t.blob("Leaf", 0.22, 1.42, -0.1, 0.38, sy=0.9, seed=seed + 1)
    w.merge(t.transformed(R, (x, 0, z), s))


def rock(x, z, r, seed, sy=0.6):
    w.blob("Rock", x, r * sy * 0.45, z, r, sy=sy, seed=seed)


avoid = [(L.HALL_H, 2.3), (L.HALL_O, 2.3), (L.MINE_H, 1.8), (L.MINE_O, 1.8)]
avoid += [(g, 1.5) for g in L.GROVES_H + L.GROVES_O]
avoid += [(v, 1.5) for v in list(L.SPOTS_H.values()) + list(L.SPOTS_O.values())]


def free(x, z, extra=0.0):
    if not (X0 + 0.2 < x < X1 - 0.2 and Z0 + 0.2 < z < Z1 - 0.4):
        return False
    for (cx, cz), r in avoid:
        if math.hypot(x - cx, z - cz) < r + extra:
            return False
    for path in L.PATHS_H + L.PATHS_O:
        if L.poly_dist((x, z), path) < 0.75:
            return False
    return True


trees = []
k = 0
for (x, z, nxv, nzv) in L.river_points(1.2):
    for side in (-1, 1):
        k += 1
        off = 1.55 + rng.uniform(0.0, 0.35)
        tx, tz = x + nxv * off * side + rng.uniform(-0.15, 0.15), z + nzv * off * side + rng.uniform(-0.15, 0.15)
        if L.ford_dist((tx, tz)) < 2.3 or not free(tx, tz):
            continue
        if L.river_dist((tx, tz)) < L.BANK_W + 0.45:
            continue
        trees.append((tx, tz))
        tree(tx, tz, rng.uniform(0.88, 1.12), rng.uniform(0, 360), 100 + k)
# a tree line along the top edge, behind the orc side
for i in range(15):
    tx = -9.4 + i * 1.35 + rng.uniform(-0.25, 0.25)
    tz = -8.35 + rng.uniform(-0.3, 0.3)
    if L.river_dist((tx, tz)) < 1.4:
        continue
    trees.append((tx, tz))
    tree(tx, tz, rng.uniform(0.85, 1.05), rng.uniform(0, 360), 300 + i)

# gold deposits: a rock mound, gold showing through it, a timber-framed adit
for (mx, mz), yaw in ((L.MINE_H, 60), (L.MINE_O, 240)):
    m = Mesh()
    m.blob("Rock", 0, 0.12, 0, 0.88, sy=0.62, seed=21, sx=1.05, sz=0.9)
    m.blob("Rock", 0.42, 0.1, -0.35, 0.5, sy=0.75, seed=22)
    m.blob("Rock", -0.5, 0.05, -0.2, 0.42, sy=0.7, seed=23)
    for gx, gy, gz, gr in ((0.25, 0.55, 0.45, 0.17), (-0.35, 0.5, 0.35, 0.15), (0.05, 0.68, 0.0, 0.18),
                           (0.6, 0.42, 0.05, 0.14), (-0.62, 0.32, -0.15, 0.13), (0.3, 0.6, -0.4, 0.14)):
        m.blob("Gold", gx, gy, gz, gr, sy=0.9, seed=int(gx * 100 + 100))
    m.box("Timber", -0.24, 0.3, 0.74, 0.1, 0.6, 0.1)
    m.box("Timber", 0.24, 0.3, 0.74, 0.1, 0.6, 0.1)
    m.box("Timber", 0, 0.63, 0.74, 0.62, 0.1, 0.12)
    m.box("Dark", 0, 0.27, 0.68, 0.38, 0.54, 0.1)
    w.merge(m.transformed(rot_y(yaw), (mx, 0, mz)))

# stumps under the harvestable groves (seen once a grove is cut down)
PINES = [(-0.36, -0.22), (0.38, -0.12), (0.0, 0.36)]
for gx, gz in L.GROVES_H + L.GROVES_O:
    for px, pz in PINES:
        w.box("Stump", gx + px, 0.07, gz + pz, 0.2, 0.14, 0.2)
        w.box("Cut", gx + px, 0.145, gz + pz, 0.16, 0.01, 0.16)

# stepping stones along the fords' edges, rocks here and there
for fx, fz in L.FORDS:
    for s in (-1, 1):
        for t in (-0.75, 0.0, 0.75):
            # the river's direction near a ford runs about (0.82, 0.57)
            dx, dz = 0.82, 0.57
            rock(fx + dx * s * 1.05 - dz * t, fz + dz * s * 1.05 + dx * t, 0.17, 400 + int(t * 10 + 10) + s + 1)
for i, (x, z, r) in enumerate([(-9.0, 7.0, 0.32), (-2.6, 5.0, 0.25), (8.9, -6.6, 0.3), (2.6, -5.0, 0.25),
                                (-8.9, -1.6, 0.35), (8.9, 1.6, 0.35), (-0.9, 7.3, 0.3), (0.9, -7.2, 0.3)]):
    rock(x, z, r, 500 + i)
w.write_glb("woods.glb")
print("woods.glb", w.count(), "triangles,", len(trees), "trees")
with open("trees.txt", "w") as f:
    f.write("# static tree positions (x z), for game.as's pathing grid\n")
    for x, z in trees:
        f.write(f"{x:.2f} {z:.2f}\n")
