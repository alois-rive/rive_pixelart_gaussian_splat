# Writes Pebble Prix's world as GLBs, all from the one circuit in track.py:
#   ground.glb   the island: grass (two greens), sand, paving; the coast's faces down to the sea; the
#                creek and the pond; a foam line round the coast (the sea itself is the renderer's sky)
#   road.glb     the circuit: asphalt, red and white kerbs on the corners, the chequered line, the
#                boost strips' chevrons
#   town.glb     the village houses, the arch over the street, the chapel, the lighthouse, the stone
#                bridge, the dry-stone walls between the switchback rows, the quay (bollards, crates,
#                the jetty), the gantry over the line, hay bales and oil drums
#   trees.glb    cypresses, round trees, vines and bushes
#   cone.glb boat.glb flag.glb puff.glb dust.glb flame.glb spark.glb lamp.glb golamp.glb gull.glb
#                the game's moving pieces (bones and pools in scene.bake.json)
# Run from models/env: /usr/bin/python3 make_env.py   (deterministic: random.Random(7))
import math
import os
import random
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, ".."))
import track  # noqa: E402
from meshkit import Mesh, rot_y  # noqa: E402

Z32 = {"ink": "#302c2e", "asph": "#5a5353", "grey": "#7d7071", "stone": "#a0938e", "pale": "#cfc6b8",
       "white": "#dff6f5", "grass": "#71aa34", "grass2": "#397b44", "lime": "#b6d53c", "moss": "#3c5956",
       "sand": "#eea160", "tan": "#bf7958", "terra": "#a05b53", "plum": "#7a444a", "peach": "#f4cca1",
       "rose": "#ffaeb6", "pink": "#cd6093", "sea": "#3978a8", "cyan": "#28ccdf", "ice": "#8aebf1",
       "navy": "#394778", "night": "#39314b", "red": "#e6482e", "brick": "#a93b3b", "orange": "#f47e1b",
       "gold": "#f4b41b", "wood": "#7a444a", "dkwood": "#5e3643"}

T = track.build()
C = T["c"]
N = track.normals(C)
rnd = random.Random(7)

def W(x, y, h=0.0):
    """map (x east, y north) and a height -> glTF (X, Y up, Z = -y)"""
    return [x, h, -y]

def mesh(mats):
    m = Mesh()
    for k in mats:
        m.material(k, Z32[mats[k]] if mats[k] in Z32 else mats[k])
    return m

# ---------------------------------------------------------------- fields on a grid (map coords)
G = 0.5
GX = np.arange(-50.0, 46.01, G)
GY = np.arange(-14.0, 60.01, G)
PX, PY = np.meshgrid(GX, GY)
D = track.dist_to_polyline(PX, PY, C["x"], C["y"])          # distance to the centreline

# the island's outline, counter-clockwise (map): the quay along the harbour, the lighthouse headland,
# the east shore, the village's back gardens, the west beach and the creek mouth
COAST = [(-27.0, -5.6), (27.0, -5.6), (32.5, -4.4), (37.5, -0.5), (40.0, 4.0), (40.5, 9.5), (38.5, 14.0),
         (36.0, 18.5), (36.5, 25.0), (35.5, 31.0), (34.0, 37.5), (31.0, 44.0), (27.0, 52.5), (16.0, 55.0),
         (0.0, 55.5), (-16.0, 55.0), (-27.0, 53.0), (-33.5, 48.5), (-38.0, 41.0), (-40.0, 32.0),
         (-40.5, 24.0), (-40.5, 16.5), (-40.0, 8.5), (-37.0, 1.0), (-32.5, -3.5)]

def poly_sdf(px, py, poly):
    """signed distance to a closed polygon: positive inside"""
    d = np.full(px.shape, 1e9)
    inside = np.zeros(px.shape, bool)
    n = len(poly)
    for i in range(n):
        (ax, ay), (bx, by) = poly[i], poly[(i + 1) % n]
        dx, dy = bx - ax, by - ay
        t = np.clip(((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy), 0, 1)
        d = np.minimum(d, np.hypot(px - ax - t * dx, py - ay - t * dy))
        cond = ((ay > py) != (by > py)) & (px < (bx - ax) * (py - ay) / (by - ay + 1e-12) + ax)
        inside ^= cond
    return np.where(inside, d, -d)

LAND = poly_sdf(PX, PY, COAST)

def creek_field(px, py):
    d = track.dist_to_polyline(px, py, np.array([p[0] for p in track.CREEK] + [p[0] for p in track.CREEK[::-1]]),
                               np.array([p[1] for p in track.CREEK] + [p[1] for p in track.CREEK[::-1]]))
    px0, py0, pr = track.POND
    return np.maximum(track.CREEK_W / 2 - d, pr - np.hypot(px - px0, py - py0))

CREEK = creek_field(PX, PY)

# ---------------------------------------------------------------- the village's houses (map boxes)
# (x0, x1, y0, y1, wall height, wall material); fronts on the village street at |n| = 5.6
HOUSES = []
xs = -24.5
widths = [5.5, 6.0, 4.5, 6.5, 5.0, 6.0, 5.5, 4.5, 6.0, 5.0]
walls_cycle = ["Plaster", "Peach", "Plaster", "Rose", "Plaster", "Peach", "Rose", "Plaster", "Peach", "Plaster"]
for i, w in enumerate(widths):        # the north side of the street
    x0, x1 = xs, xs + w - 0.3
    if x1 > 23.0:
        break
    if not (x1 < track.ARCH[0] - 1.25 or x0 > track.ARCH[0] + 1.25):
        x0, x1 = track.ARCH[0] + 1.25, track.ARCH[0] + 1.25 + w - 1.6
    HOUSES.append((x0, x1, 45.6, 45.6 + rnd.uniform(5.0, 6.2), rnd.choice([3.6, 4.2, 4.8]), walls_cycle[i]))
    xs = x1 + 0.3
xs = -14.0
for i, w in enumerate([5.0, 5.5, 4.5, 6.0, 5.0]):   # the south side, west of the switchbacks
    x0, x1 = xs, xs + w - 0.3
    if x1 > 6.0:
        break
    if not (x1 < track.ARCH[0] - 1.25 or x0 > track.ARCH[0] + 1.25):
        x0, x1 = track.ARCH[0] + 1.25, track.ARCH[0] + 1.25 + w - 1.6
    HOUSES.append((x0, x1, 34.4 - rnd.uniform(4.6, 5.4), 34.4, rnd.choice([3.6, 4.2]), walls_cycle[(i + 3) % 10]))
    xs = x1 + 0.3
CHAPEL = (-25.0, -19.5, 24.5, 31.5)
FOOT = HOUSES and [(h[0] - 0.1, h[1] + 0.1, h[2] - 0.1, h[3] + 0.1) for h in HOUSES] + [
    (CHAPEL[0], CHAPEL[1], CHAPEL[2], CHAPEL[3]), (CHAPEL[0] - 2.2, CHAPEL[0] + 0.2, CHAPEL[3] - 2.4, CHAPEL[3])]

def in_foot(x, y):
    for (x0, x1, y0, y1) in FOOT:
        if x0 + 0.4 < x < x1 - 0.4 and y0 + 0.4 < y < y1 - 0.4:
            return True
    return False

# ---------------------------------------------------------------- marching squares
def contour_tris(g):
    """triangles (map xy) of the region g > 0 on the grid, with interpolated edges"""
    out = []
    ny, nx = g.shape
    for j in range(ny - 1):
        for i in range(nx - 1):
            cs = [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)]
            vals = [g[cj, ci] for ci, cj in cs]
            if all(v <= 0 for v in vals):
                continue
            pts = []
            for k in range(4):
                (ci, cj), v = cs[k], vals[k]
                (ni, nj), w = cs[(k + 1) % 4], vals[(k + 1) % 4]
                if v > 0:
                    pts.append((GX[ci], GY[cj]))
                if (v > 0) != (w > 0):
                    t = v / (v - w)
                    pts.append((GX[ci] + (GX[ni] - GX[ci]) * t, GY[cj] + (GY[nj] - GY[cj]) * t))
            for k in range(1, len(pts) - 1):
                out.append((pts[0], pts[k], pts[k + 1]))
    return out

def boundary_edges(g):
    """the contour g = 0 as segments, each with the inside to its left"""
    segs = []
    ny, nx = g.shape
    for j in range(ny - 1):
        for i in range(nx - 1):
            cs = [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)]
            vals = [g[cj, ci] for ci, cj in cs]
            cross = []
            for k in range(4):
                (ci, cj), v = cs[k], vals[k]
                (ni, nj), w = cs[(k + 1) % 4], vals[(k + 1) % 4]
                if (v > 0) != (w > 0):
                    t = v / (v - w)
                    cross.append(((GX[ci] + (GX[ni] - GX[ci]) * t, GY[cj] + (GY[nj] - GY[cj]) * t), v > 0))
            if len(cross) == 2:
                (a, ain), (b, bin_) = cross
                # walking the cell's corners counter-clockwise, the inside lies between the exit and entry
                segs.append((b, a) if ain else (a, b))
    return segs

def noise(x, y, s=0.13):
    return math.sin(x * s * 1.7 + 1.3) * math.cos(y * s * 1.3 - 0.4) + 0.5 * math.sin((x + y) * s * 2.9)

# ---------------------------------------------------------------- ground
def ground_material(x, y):
    if y < -2.0 and -27 < x < 27:
        return "Paving"                                     # the quay
    if 34.0 < y < 46.0 and -25.5 < x < 23.0:
        return "Paving"                                     # the street's pavements
    if x < -35.0 or (x < -30.0 and y < 2.0) or (y < -2.5 and x < -26.0):
        return "Sand"                                       # the west beach
    if x > 33.0 and y < 16:
        return "Rock"                                       # the headland
    return "Grass2" if noise(x, y) > 0.55 else "Grass"

def make_ground():
    m = mesh({"Grass": "grass", "Grass2": "grass2", "Sand": "sand", "Paving": "pale", "Rock": "stone",
              "Water": "sea", "Bank": "tan", "Cliff": "grey", "Quay": "stone", "Foam": "white"})
    g = np.minimum(np.minimum(LAND, D - track.HALF), -CREEK)
    for (a, b, c) in contour_tris(g):
        cx, cy = (a[0] + b[0] + c[0]) / 3, (a[1] + b[1] + c[1]) / 3
        if in_foot(cx, cy):
            continue
        m.tri(ground_material(cx, cy), W(*a), W(*b), W(*c), out=[0, 1, 0])
    # the coast: faces from the ground down to the sea, and a broken foam line just off it
    for (a, b) in boundary_edges(LAND):
        mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        if D[int(round((my - GY[0]) / G)), int(round((mx - GX[0]) / G))] < track.HALF - 0.2:
            continue
        mat = "Quay" if (my < -4.5 and -27.5 < mx < 27.5) else ("Bank" if ground_material(mx, my) == "Sand" else "Cliff")
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy)
        if L < 1e-6:
            continue
        out = [dy / L, 0, dx / L]              # right of a->b in map = outside; glTF z = -y
        m.quad(mat, W(a[0], a[1], 0), W(b[0], b[1], 0), W(b[0], b[1], -1.0), W(a[0], a[1], -1.0), out=out)
        ox, oy = dy / L * 0.55, -dx / L * 0.55
        if noise(mx * 3.1, my * 3.1, 0.5) > -0.3:
            m.quad("Foam", W(a[0] + ox, a[1] + oy, -0.95), W(b[0] + ox, b[1] + oy, -0.95),
                   W(b[0] + ox * 1.9, b[1] + oy * 1.9, -0.95), W(a[0] + ox * 1.9, a[1] + oy * 1.9, -0.95), out=[0, 1, 0])
    # the creek and the pond: water 0.7 m down, sandy banks (none under the road)
    wg = np.minimum(np.minimum(CREEK, LAND + 0.4), D - track.HALF + 0.3)
    for (a, b, c) in contour_tris(wg):
        m.tri("Water", W(a[0], a[1], -0.7), W(b[0], b[1], -0.7), W(c[0], c[1], -0.7), out=[0, 1, 0])
    for (a, b) in boundary_edges(-CREEK):
        mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        ii, jj = int(round((mx - GX[0]) / G)), int(round((my - GY[0]) / G))
        if D[jj, ii] < track.HALF + 0.1 or LAND[jj, ii] < 0:
            continue
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dy)
        if L < 1e-6:
            continue
        m.quad("Bank", W(a[0], a[1], 0), W(b[0], b[1], 0), W(b[0], b[1], -0.75), W(a[0], a[1], -0.75),
               out=[dy / L, 0, dx / L])
    return m

# ---------------------------------------------------------------- the road
def make_road():
    m = mesh({"Asphalt": "asph", "KerbR": "brick", "KerbW": "white", "Check": "ink", "CheckW": "white",
              "Boost": "orange", "BoostY": "gold"})
    ds = 0.5
    ns = np.linspace(-track.HALF, track.HALF, 15)       # 0.5 m lanes
    L = track.LENGTH
    S = np.arange(0, L + 1e-6, ds)
    # dense centreline from the 1 m samples
    def at(s):
        s = s % L
        f = s / C["ds"]
        i = int(f) % C["n"]
        j = (i + 1) % C["n"]
        u = f - int(f)
        x = C["x"][i] + (C["x"][j] - C["x"][i]) * u
        y = C["y"][i] + (C["y"][j] - C["y"][i]) * u
        h = C["h"][i] + math.atan2(math.sin(C["h"][j] - C["h"][i]), math.cos(C["h"][j] - C["h"][i])) * u
        return x, y, h, C["seg"][i]
    boost = [b * C["ds"] for b in T["boost"]]
    for k in range(len(S) - 1):
        s0, s1 = S[k], S[k + 1]
        x0, y0, h0, sg = at(s0)
        x1, y1, h1, _ = at(s1)
        n0 = (math.sin(h0), -math.cos(h0))
        n1 = (math.sin(h1), -math.cos(h1))
        sm = (s0 + s1) / 2
        corner = sg in (1, 3, 5, 7, 9)
        for q in range(len(ns) - 1):
            a, b = ns[q], ns[q + 1]
            nm = (a + b) / 2
            mat = "Asphalt"
            if corner and abs(nm) > track.HALF - 0.55:
                mat = "KerbR" if int(sm / 1.2) % 2 == 0 else "KerbW"
            ss = (sm + 1.0) % L
            if ss < 1.5:                                           # the line: a 2-row chequer
                mat = "Check" if (int(ss / 0.75) + int((nm + track.HALF) / 0.5)) % 2 == 0 else "CheckW"
            for bs in boost:
                u = (sm - bs) % L
                if u < 3.0 and abs(nm) < 2.6:
                    mat = "BoostY" if int((u - abs(nm) * 0.8) / 0.75) % 2 == 0 else "Boost"
            p = [W(x0 + n0[0] * a, y0 + n0[1] * a), W(x1 + n1[0] * a, y1 + n1[1] * a),
                 W(x1 + n1[0] * b, y1 + n1[1] * b), W(x0 + n0[0] * b, y0 + n0[1] * b)]
            m.quad(mat, *p, out=[0, 1, 0])
    return m

# ---------------------------------------------------------------- town pieces
def wall_cells(m, a, b, h0, h1, mat, out, windows=True, door=None, cell=1.1):
    """a vertical wall from map point a to b, split into cells; windows on the upper rows"""
    L = math.hypot(b[0] - a[0], b[1] - a[1])
    nc = max(1, int(round(L / cell)))
    rows = [(h0, h0 + 0.9), (h0 + 0.9, h0 + 1.9), (h0 + 1.9, h0 + 2.6), (h0 + 2.6, h1)] if h1 - h0 > 3.0 else \
        [(h0, h0 + 0.9), (h0 + 0.9, h0 + 1.9), (h0 + 1.9, h1)]
    for c in range(nc):
        u0, u1 = c / nc, (c + 1) / nc
        pa = (a[0] + (b[0] - a[0]) * u0, a[1] + (b[1] - a[1]) * u0)
        pb = (a[0] + (b[0] - a[0]) * u1, a[1] + (b[1] - a[1]) * u1)
        for r, (r0, r1) in enumerate(rows):
            if r1 <= r0 + 1e-6:
                continue
            mm = mat
            if windows and nc >= 3 and c % 2 == 1 and r in (1, 3) and 0 < c < nc - 1:
                mm = "Window"
            if door is not None and c == door and r in (0, 1):
                mm = "Door"
            m.quad(mm, W(pa[0], pa[1], r0), W(pb[0], pb[1], r0), W(pb[0], pb[1], r1), W(pa[0], pa[1], r1), out=out)

def house(m, x0, x1, y0, y1, h, wall, roof="Roof", front=None, ridge=None, door=True, skip=()):
    """walls with windows, a gable roof (ridge along the longer side) with a 0.3 m overhang; `skip`
    leaves out side walls that touch a neighbour (\"w\", \"e\")"""
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    sides = [((x0, y0), (x1, y0), [0, 0, 1]), ((x1, y0), (x1, y1), [1, 0, 0]),
             ((x1, y1), (x0, y1), [0, 0, -1]), ((x0, y1), (x0, y0), [-1, 0, 0])]
    for (a, b, out) in sides:
        if ("e" in skip and out == [1, 0, 0]) or ("w" in skip and out == [-1, 0, 0]):
            continue
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        dd = None
        if door and front is not None and out == front:
            dd = int(round(L / 1.1)) // 2
        wall_cells(m, a, b, 0, h, wall, out, door=dd)
    rh = 1.4
    o = 0.3
    along_x = (x1 - x0) >= (y1 - y0) if ridge is None else ridge == "x"
    if along_x:
        my = cy
        m.quad(roof, W(x0 - o, y0 - o, h - 0.15), W(x1 + o, y0 - o, h - 0.15), W(x1 + o, my, h + rh), W(x0 - o, my, h + rh),
               out=[0, 1, 1])
        m.quad(roof, W(x0 - o, y1 + o, h - 0.15), W(x1 + o, y1 + o, h - 0.15), W(x1 + o, my, h + rh), W(x0 - o, my, h + rh),
               out=[0, 1, -1])
        for xx, sg in ((x0, -1), (x1, 1)):
            m.tri(wall, W(xx, y0, h), W(xx, y1, h), W(xx, my, h + rh), out=[sg, 0, 0])
    else:
        mx = cx
        m.quad(roof, W(x0 - o, y0 - o, h - 0.15), W(x0 - o, y1 + o, h - 0.15), W(mx, y1 + o, h + rh), W(mx, y0 - o, h + rh),
               out=[-1, 1, 0])
        m.quad(roof, W(x1 + o, y0 - o, h - 0.15), W(x1 + o, y1 + o, h - 0.15), W(mx, y1 + o, h + rh), W(mx, y0 - o, h + rh),
               out=[1, 1, 0])
        for yy, sg in ((y0, 1), (y1, -1)):
            m.tri(wall, W(x0, yy, h), W(x1, yy, h), W(mx, yy, h + rh), out=[0, 0, sg])

def boxm(m, mat, x0, x1, y0, y1, h0, h1, skip=("-y",)):
    m.box(mat, x0, x1, h0, h1, -y1, -y0, skip=skip)

def make_town():
    m = mesh({"Plaster": "white", "Peach": "peach", "Rose": "rose", "Roof": "terra", "Window": "navy",
              "Door": "wood", "Stone": "stone", "StoneD": "grey", "Arch": "night", "Lamp": "gold",
              "LhWhite": "white", "LhRed": "brick", "Wood": "wood", "Hay": "gold", "Drum": "sea",
              "DrumR": "red", "Metal": "night", "Net": "tan", "Crate": "tan", "Beam": "pale", "Bell": "gold"})
    # houses: fronts on the street (the north row faces -y, the south row +y)
    for (x0, x1, y0, y1, h, wall) in HOUSES:
        front = [0, 0, 1] if y0 > 40 else [0, 0, -1]
        skip = []
        for (a0, a1, b0, b1, hh, _) in HOUSES:
            if min(y1, b1) - max(y0, b0) > 2.0 and hh >= h - 0.01:
                if abs(a1 - x0) < 0.45 and a0 < x0:
                    skip.append("w")
                if abs(a0 - x1) < 0.45 and a1 > x1:
                    skip.append("e")
        house(m, x0, x1, y0, y1, h, wall, front=front, ridge="x", skip=skip)
    # the arch over the village street: two stone piers against the house fronts and a vaulted span
    ax = track.ARCH[0]
    for (y0, y1) in ((34.4, 35.9), (44.1, 45.6)):
        boxm(m, "Stone", ax - 1.2, ax + 1.2, y0, y1, 0, 4.4)
    boxm(m, "Stone", ax - 1.2, ax + 1.2, 35.9, 44.1, 3.3, 4.4, skip=())
    house(m, ax - 1.25, ax + 1.25, 34.4, 45.6, 4.4, "Stone", ridge="y", door=False)
    # the chapel and its bell tower
    x0, x1, y0, y1 = CHAPEL
    house(m, x0, x1, y0, y1, 3.8, "Plaster", front=[1, 0, 0], ridge="y")
    tx0, tx1, ty0, ty1 = x0 - 2.2, x0 + 0.2, y1 - 2.4, y1
    for (a, b, out) in (((tx0, ty0), (tx1, ty0), [0, 0, 1]), ((tx1, ty0), (tx1, ty1), [1, 0, 0]),
                        ((tx1, ty1), (tx0, ty1), [0, 0, -1]), ((tx0, ty1), (tx0, ty0), [-1, 0, 0])):
        m.quad("Plaster", W(*a, 0), W(*b, 0), W(*b, 6.0), W(*a, 6.0), out=out)
        m.quad("Bell", W(a[0] + (b[0] - a[0]) * 0.3, a[1] + (b[1] - a[1]) * 0.3, 4.9),
               W(a[0] + (b[0] - a[0]) * 0.7, a[1] + (b[1] - a[1]) * 0.7, 4.9),
               W(a[0] + (b[0] - a[0]) * 0.7, a[1] + (b[1] - a[1]) * 0.7, 5.7),
               W(a[0] + (b[0] - a[0]) * 0.3, a[1] + (b[1] - a[1]) * 0.3, 5.7), out=out)
    cxm, cym = (tx0 + tx1) / 2, (ty0 + ty1) / 2
    for (a, b) in (((tx0 - 0.2, ty0 - 0.2), (tx1 + 0.2, ty0 - 0.2)), ((tx1 + 0.2, ty0 - 0.2), (tx1 + 0.2, ty1 + 0.2)),
                   ((tx1 + 0.2, ty1 + 0.2), (tx0 - 0.2, ty1 + 0.2)), ((tx0 - 0.2, ty1 + 0.2), (tx0 - 0.2, ty0 - 0.2))):
        m.tri("Roof", W(*a, 6.0), W(*b, 6.0), W(cxm, cym, 7.8), centre=W(cxm, cym, 6.5))
    # the lighthouse on the headland: red and white bands, a dark gallery, a glowing lantern
    lx, ly = track.LIGHTHOUSE
    X, Z = lx, -ly
    bands = [(0.0, 1.3, 1.2), (1.3, 2.6, 1.13), (2.6, 3.9, 1.06), (3.9, 5.2, 0.99), (5.2, 6.4, 0.92)]
    for k, (h0, h1, r0) in enumerate(bands):
        r1 = r0 - 0.07 * (h1 - h0)
        m.frustum("LhRed" if k % 2 else "LhWhite", X, h0, Z, r0, r1, h1 - h0, n=8, top=False)
    m.frustum("Metal", X, 6.4, Z, 1.3, 1.3, 0.25, n=8, top=True)
    m.frustum("Lamp", X, 6.65, Z, 0.6, 0.6, 0.75, n=8, top=False)
    m.frustum("LhRed", X, 7.4, Z, 0.85, 0.0, 0.9, n=8)
    boxm(m, "Stone", lx - 2.2, lx + 2.2, ly - 2.2, ly + 2.2, 0, 0.35, skip=("-y",))
    # the stone bridge: a deck either side of the road, parapets, faces down to the water, dark arches
    bx, by = track.BRIDGE
    yb0, yb1 = by - 4.5, by + 4.5
    for sgn in (-1, 1):
        xi, xo = bx + sgn * track.HALF, bx + sgn * 4.7
        lo, hi = min(xi, xo), max(xi, xo)
        boxm(m, "Stone", lo, hi, yb0, yb1, -1.2, 0.0, skip=())
        po, pi = bx + sgn * 4.7, bx + sgn * 4.15
        boxm(m, "StoneD", min(po, pi), max(po, pi), yb0, yb1, 0.0, 0.8, skip=())
        # the arch, a dark half-octagon on the outer face over the water
        xf = bx + sgn * 4.72
        pts = [W(xf, by + 1.6 * math.cos(a), -1.2 + 1.05 * math.sin(a)) for a in np.linspace(0, math.pi, 7)]
        m.poly("Arch", pts, out=[sgn, 0, 0])
    # dry-stone walls where a barrier sits half way between two runs of the track
    wl, wr = T["wl"], T["wr"]
    for i in range(C["n"]):
        j = (i + 1) % C["n"]
        if C["seg"][i] not in (0, 1, 2, 3, 4, 5):
            continue
        for side, arr in ((1, wr), (-1, wl)):
            if arr[i] > 8.0 or arr[j] > 8.0 or (C["seg"][i] == 0 and side == 1):
                continue
            if abs(arr[i] - arr[j]) > 0.6:
                continue
            a = (C["x"][i] + N[i][0] * side * (arr[i] + 0.25), C["y"][i] + N[i][1] * side * (arr[i] + 0.25))
            b = (C["x"][j] + N[j][0] * side * (arr[j] + 0.25), C["y"][j] + N[j][1] * side * (arr[j] + 0.25))
            ang = math.atan2(b[1] - a[1], b[0] - a[0])
            ox, oy = -math.sin(ang) * 0.25, math.cos(ang) * 0.25
            for (p, q, o) in ((a, b, 1), (b, a, -1)):
                m.quad("StoneD", W(p[0] + ox * o, p[1] + oy * o, 0), W(q[0] + ox * o, q[1] + oy * o, 0),
                       W(q[0] + ox * o, q[1] + oy * o, 0.7), W(p[0] + ox * o, p[1] + oy * o, 0.7),
                       out=[ox * o, 0, -oy * o])
            m.quad("Stone", W(a[0] + ox, a[1] + oy, 0.7), W(b[0] + ox, b[1] + oy, 0.7),
                   W(b[0] - ox, b[1] - oy, 0.7), W(a[0] - ox, a[1] - oy, 0.7), out=[0, 1, 0])
    # the quay: bollards along the edge, crates and nets, a wooden jetty out into the harbour
    for x in np.arange(-24.0, 26.0, 5.0):
        m.frustum("Metal", x, 0.0, 5.25, 0.22, 0.18, 0.5, n=6)
    for (x, y, h) in ((-17.0, -4.2, 0.9), (-16.0, -4.4, 0.9), (-16.6, -4.3, 1.8), (16.5, -4.3, 0.9), (17.5, -4.4, 0.9)):
        boxm(m, "Crate", x - 0.45, x + 0.45, y - 0.45, y + 0.45, h - 0.9, h)
    m.frustum("Net", -9.0, 0.0, 4.3, 0.7, 0.3, 0.45, n=6)
    jx = -2.0
    boxm(m, "Wood", jx - 0.8, jx + 0.8, -12.5, -5.6, -0.65, -0.45, skip=())
    for y in (-8.0, -10.5, -12.3):
        for sx in (-0.7, 0.7):
            m.frustum("Wood", jx + sx, -1.3, -y, 0.12, 0.12, 0.85, n=6, top=False)
    # the gantry over the line: two posts and a beam with four dark lamp housings
    x, y = C["x"][0], C["y"][0]
    for side in (-1, 1):
        px_, py_ = x + N[0][0] * side * (track.HALF + 0.9), y + N[0][1] * side * (track.HALF + 0.9)
        boxm(m, "Beam", px_ - 0.25, px_ + 0.25, py_ - 0.25, py_ + 0.25, 0, 4.6)
    boxm(m, "Metal", x - 0.3, x + 0.3, y - track.HALF - 1.2, y + track.HALF + 1.2, 4.0, 4.6, skip=())
    for k in range(4):
        yy = y - 1.65 + k * 1.1
        boxm(m, "Metal", x - 0.55, x - 0.3, yy - 0.4, yy + 0.4, 3.6, 4.4, skip=())
    # hay bales and oil drums (the obstacles game.as bumps against: track.props)
    for (kind, ox, oy, r) in T["obs"]:
        if kind == 0:
            k = int(np.argmin(np.hypot(C["x"] - ox, C["y"] - oy)))
            ang = -math.degrees(C["h"][k])
            R = rot_y(ang)
            hb = Mesh()
            hb.material("Hay", Z32["gold"])
            hb.box("Hay", -0.75, 0.75, 0.0, 0.65, -0.45, 0.45, skip=("-y",))
            m.merge(hb, R=R, offset=np.array(W(ox, oy, 0)))
        elif kind == 1:
            m.frustum("DrumR" if int(ox * 7) % 2 else "Drum", ox, 0.0, -oy, 0.42, 0.42, 0.95, n=8)
    return m

# ---------------------------------------------------------------- trees and vines
def tree_ok(x, y, clear=6.0):
    i, j = int(round((x - GX[0]) / G)), int(round((y - GY[0]) / G))
    if not (0 <= i < len(GX) and 0 <= j < len(GY)):
        return False
    return D[j, i] > clear and LAND[j, i] > 1.5 and CREEK[j, i] < -1.0 and not in_foot(x, y)

def make_trees():
    m = mesh({"Leaf": "grass2", "LeafD": "moss", "Trunk": "dkwood", "Vine": "grass", "Bush": "grass2"})
    def cypress(x, y, h):
        m.frustum("Trunk", x, 0.0, -y, 0.12, 0.12, 0.5, n=5, top=False)
        m.frustum("LeafD", x, 0.4, -y, 0.55, 0.0, h, n=6, rot=rnd.uniform(0, 1))
    def round_tree(x, y, r):
        m.frustum("Trunk", x, 0.0, -y, 0.15, 0.12, 1.0, n=5, top=False)
        c = np.array(W(x, y, 1.0 + r * 0.8))
        def leaf(fc):
            return "Leaf"
        m.sphere(leaf, c, r, seg=6, rings=4, sy=0.8)
    spots = []
    # cypresses along the infield, the chapel's corner and the village's back gardens
    for (x, y) in [(-15, 8), (-11, 8), (-7, 8), (-3, 8), (-18, 12.5), (-23, 34.5), (-27.5, 36.5),
                   (-30, 52), (-20, 53), (-8, 53), (6, 53), (18, 53), (32, 30), (33, 22), (29.5, -1.5),
                   (-38, 36), (-38, 28), (-37.5, 6)]:
        if tree_ok(x, y, 5.0):
            cypress(x, y, rnd.uniform(3.2, 4.4))
            spots.append((x, y))
    for (x, y) in [(-6, 22), (-1, 13), (-17, 25), (-8, 13.5), (-4, 28), (-12, 27), (30, 40), (-34, 44),
                   (12, 56), (-25, 14)]:
        if tree_ok(x, y, 5.5):
            round_tree(x, y, rnd.uniform(1.3, 1.8))
    # vines in rows between the switchback rows (low, so they never hide a car)
    for (yy, x0, x1) in ((20.5, 12.0, 25.0), (33.5, 3.0, 16.0)):
        for dy in (-0.8, 0.8):
            for x in np.arange(x0, x1, 1.2):
                if tree_ok(x, yy + dy, 4.6):
                    m.box("Vine", x - 0.35, x + 0.35, 0.0, 0.75, -(yy + dy) - 0.3, -(yy + dy) + 0.3, skip=("-y",))
    return m

# ---------------------------------------------------------------- moving pieces
def make_props():
    out = {}
    m = mesh({"Cone": "orange", "Band": "white", "Foot": "night"})          # a traffic cone, 0.75 m
    m.box("Foot", -0.32, 0.32, 0.0, 0.08, -0.32, 0.32, skip=("-y",))
    m.frustum("Cone", 0, 0.08, 0, 0.27, 0.19, 0.25, n=8, top=False)
    m.frustum("Band", 0, 0.33, 0, 0.19, 0.13, 0.17, n=8, top=False)
    m.frustum("Cone", 0, 0.50, 0, 0.13, 0.03, 0.25, n=8)
    out["cone"] = m
    m = mesh({"Hull": "white", "HullB": "sea", "Deck": "wood", "Cabin": "pink", "Roof": "red"})  # a fishing boat
    for (x0, x1, h0, h1, mat) in ((-0.9, 0.9, -0.35, 0.15, "HullB"), (-1.0, 1.0, 0.15, 0.55, "Hull")):
        m.box(mat, x0, x1, h0, h1, -2.2, 2.0, skip=("-y",))
    m.tri("Hull", [-1.0, 0.55, 2.0], [1.0, 0.55, 2.0], [0, 0.55, 3.0], out=[0, 1, 0])
    m.tri("Hull", [-1.0, 0.15, 2.0], [-1.0, 0.55, 2.0], [0, 0.55, 3.0], out=[-1, 0, 1])
    m.tri("Hull", [1.0, 0.15, 2.0], [1.0, 0.55, 2.0], [0, 0.55, 3.0], out=[1, 0, 1])
    m.box("Cabin", -0.6, 0.6, 0.55, 1.5, -1.6, -0.4, skip=("-y",))
    m.box("Roof", -0.75, 0.75, 1.5, 1.65, -1.75, -0.25, skip=("-y",))
    out["boat"] = m
    m = mesh({"Pole": "night", "Chk": "ink", "ChkW": "white"})              # the chequered flag
    m.prism("Pole", (0, 1.4, 0), (0, 1, 0), 0.07, 2.8, n=6)
    for i in range(3):
        for j in range(2):
            mat = "Chk" if (i + j) % 2 == 0 else "ChkW"
            x0, x1 = 0.07 + i * 0.45, 0.07 + (i + 1) * 0.45
            y0, y1 = 2.75 - (j + 1) * 0.45, 2.75 - j * 0.45
            m.quad(mat, [x0, y0, 0], [x1, y0, 0], [x1, y1, 0], [x0, y1, 0], out=[0, 0, 1])
    out["flag"] = m
    m = mesh({"Smoke": "pale"})
    m.sphere(lambda fc: "Smoke", (0, 0.45, 0), 0.45, seg=6, rings=4)
    out["puff"] = m
    m = mesh({"Dust": "tan"})
    m.sphere(lambda fc: "Dust", (0, 0.4, 0), 0.4, seg=6, rings=4, sy=0.8)
    out["dust"] = m
    m = mesh({"Flame": "orange", "Core": "gold"})                           # a boost flame, along -Z
    m.prism("Flame", (0, 0, -0.35), (0, 0, 1), 0.16, 0.7, n=6, caps=(True, True))
    m.prism("Core", (0, 0, -0.75), (0, 0, 1), 0.1, 0.3, n=6)
    out["flame"] = m
    m = mesh({"Spark": "gold"})                                             # a bump's spark burst
    for k in range(6):
        a = k * math.pi / 3
        m.box("Spark", -0.07, 0.07, -0.07, 0.07, 0.0, 0.5, R=rot_y(math.degrees(a)) @ np.array(
            [[1, 0, 0], [0, math.cos(0.6), -math.sin(0.6)], [0, math.sin(0.6), math.cos(0.6)]]), pivot=(0, 0, 0))
    out["spark"] = m
    m = mesh({"Glow": "red"})
    m.sphere(lambda fc: "Glow", (0, 0, 0), 0.3, seg=6, rings=4)
    out["lamp"] = m
    m = mesh({"Go": "lime"})
    m.sphere(lambda fc: "Go", (0, 0, 0), 0.3, seg=6, rings=4)
    out["golamp"] = m
    m = mesh({"Wing": "white", "Tip": "night", "Body": "pale"})              # a gull, wings out
    m.box("Body", -0.12, 0.12, -0.1, 0.1, -0.35, 0.35)
    for sx in (-1, 1):
        m.quad("Wing", [sx * 0.1, 0, -0.15], [sx * 0.7, 0.12, -0.2], [sx * 0.7, 0.12, 0.12], [sx * 0.1, 0, 0.18], out=[0, 1, 0])
        m.quad("Tip", [sx * 0.7, 0.12, -0.2], [sx * 1.0, 0.0, -0.25], [sx * 1.0, 0.0, 0.0], [sx * 0.7, 0.12, 0.12], out=[0, 1, 0])
    out["gull"] = m
    return out

if __name__ == "__main__":
    parts = {"ground": make_ground(), "road": make_road(), "town": make_town(), "trees": make_trees()}
    parts.update(make_props())
    for name, m in parts.items():
        m.write_glb(os.path.join(HERE, name + ".glb"), name)
        print(f"{name:8s} {m.count():6d} triangles")
    track.write_tables(T, os.path.join(HERE, "..", "..", "scene", "game.as"))
    print("wrote the track tables into scene/game.as")
