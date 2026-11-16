# Writes every generated (sheet-less) model of Gust Regatta as a GLB, from the rows of art/assets.md:
#   bay.glb       the mainland round the bay: shallows, beaches, rocky shores, meadows, low hills
#   islets.glb    Lantern Isle (the lighthouse islet), Gull Rock, Pine Key, with their shallows
#   ripples.glb   the sea's static ripple dashes (the water itself is the renderer's sky colour)
#   props.glb     the lighthouse, cottages, the jetty, trees, flowering bushes
#   buoy.glb, marker.glb, gust.glb, streak.glb, foam.glb, flag.glb, dinghy_{y,p,b}.glb   the game pieces
# Run from models/env: /usr/bin/python3 make_bay.py. Deterministic (fixed seeds). World: Y up, metres,
# x east, z south (towards the camera); the game's tables (scene/game.as) use the same numbers.
import math
import random

import numpy as np

from glbkit import Mesh, write_glb

C = {"water": "#6d80fa", "shoal_deep": "#8db7ff", "shoal_light": "#aee2ff", "sand": "#ffb879",
     "grass": "#6bc96c", "tree": "#5ba675", "rock": "#a6859f", "white": "#d9bdc8", "pure": "#ffffff",
     "red": "#ea6262", "roof": "#cc425e", "roof2": "#d46eb3", "wood": "#c97373", "post": "#873555",
     "dark": "#4a3052", "bloom": "#ee8fcb", "lamp": "#fcef8d", "gust": "#834dc4", "gustrip": "#8465ec",
     "streak": "#aee2ff", "orange": "#ffb879", "trunk": "#a6555f", "yellow": "#fcef8d"}

# ---------------------------------------------------------------- the bay's shape (shared with game.as)
BAY_CX, BAY_CZ, BAY_AX, BAY_AZ, BAY_N = 0.0, -0.5, 40.0, 31.5, 4.0
RECT = (-49.0, -45.0, 49.0, 41.0)   # the land's outer edge (x0, z0, x1, z1)
ISLETS = [  # name, centre x, z, radius, lobes (a3, p3, a5, p5), kind
    ("lantern", -2.0, -4.0, 6.5, (0.10, 0.6, 0.06, 2.1), "isle"),
    ("gull", -30.0, -6.0, 2.8, (0.12, 1.4, 0.08, 0.3), "rock"),
    ("pine", 18.0, 14.0, 3.2, (0.10, 2.4, 0.07, 1.0), "isle"),
]
LIGHTHOUSE = (-2.5, -5.6)
MOORINGS = [(-7.0, -27.4), (-1.5, -26.8), (9.5, -27.6)]
JETTY_X = 4.0


def islet_r(il, th):
    _, _, _, r0, (a3, p3, a5, p5), _ = il
    return r0 * (1 + a3 * math.sin(3 * th + p3) + a5 * math.sin(5 * th + p5))


def coast_point(t):
    c, s = math.cos(t), math.sin(t)
    e = 2.0 / BAY_N
    x = BAY_CX + BAY_AX * math.copysign(abs(c) ** e, c)
    z = BAY_CZ + BAY_AZ * math.copysign(abs(s) ** e, s)
    return x, z


def coast_normal(x, z):
    u, v = (x - BAY_CX) / BAY_AX, (z - BAY_CZ) / BAY_AZ
    gx, gz = u ** 3 / BAY_AX, v ** 3 / BAY_AZ
    n = math.hypot(gx, gz)
    return gx / n, gz / n


def resample_coast(step=2.0):
    dense = [coast_point(2 * math.pi * i / 4000) for i in range(4000)]
    out, acc = [dense[0]], 0.0
    for i in range(1, len(dense)):
        d = math.dist(dense[i], dense[i - 1])
        acc += d
        if acc >= step:
            out.append(dense[i])
            acc = 0.0
    return out


def smoothstep(a, b, x):
    t = min(max((x - a) / (b - a), 0.0), 1.0)
    return t * t * (3 - 2 * t)


def hills(x, z):
    h = 0.0
    for hx, hz, hr, hh in ((-38, -40, 9, 2.6), (34, -41, 10, 3.0), (-44, 22, 9, 2.0), (42, 30, 8, 1.8),
                           (-14, -44, 7, 1.4), (20, 40, 8, 1.2)):
        h += hh * math.exp(-((x - hx) ** 2 + (z - hz) ** 2) / (hr * hr))
    return h


def rockiness(x, z):
    r = 0.0
    if x < -24 and z < 12:
        r = 1.0
    if x > 26 and z < -12:
        r = 1.0
    if z > 24 and x > 12:
        r = 1.0
    return r


def jit(x, z, seed=0):
    return math.sin(x * 12.9898 + z * 78.233 + seed * 3.7) * 43758.5453 % 1.0


# ---------------------------------------------------------------- the mainland
def make_bay():
    m = Mesh()
    for k in ("shoal_deep", "shoal_light"):
        m.mat("Shoal" + ("Deep" if k == "shoal_deep" else "Light"), C[k])
    m.mat("Sand", C["sand"])
    m.mat("Grass", C["grass"])
    m.mat("Rock", C["rock"])
    pts = resample_coast(2.0)
    n = len(pts)
    rk = [rockiness(x, z) for x, z in pts]
    rk = [sum(rk[(i + k) % n] for k in range(-3, 4)) / 7 for i in range(n)]
    shoal_d = [-2.6, -1.1, -0.15]
    land_d = [-0.15, 0.8, 2.0, 3.8, 6.5, 10.0, 15.0, 21.0]
    sandy_y = [0.03, 0.2, 0.42, 0.75, 1.1, 1.4, 1.7, 1.9]
    rocky_y = [0.03, 1.3, 1.5, 1.75, 1.9, 2.0, 2.1, 2.2]
    cols = []
    for i, (x, z) in enumerate(pts):
        nx, nz = coast_normal(x, z)
        # the distance along the normal to the outer rectangle
        ts = []
        for lim, d in ((RECT[0], nx), (RECT[2], nx)):
            if abs(d) > 1e-6:
                t = (lim - x) / d
                if t > 0:
                    ts.append(t)
        for lim, d in ((RECT[1], nz), (RECT[3], nz)):
            if abs(d) > 1e-6:
                t = (lim - z) / d
                if t > 0:
                    ts.append(t)
        tr = min(ts)
        col = []
        for d in shoal_d:
            col.append((x + nx * d, 0.0, z + nz * d, d))
        for k, d in enumerate(land_d):
            if d >= tr - 1.0:
                break
            px, pz = x + nx * d, z + nz * d
            y = sandy_y[k] * (1 - rk[i]) + rocky_y[k] * rk[i]
            if d >= 2.0:
                y += hills(px, pz) * smoothstep(2.0, 10.0, d) + 0.22 * (jit(px, pz) - 0.5)
            col.append((px, y, pz, d))
        px, pz = x + nx * tr, z + nz * tr
        col.append((px, 1.9 + hills(px, pz) + 0.2 * (jit(px, pz) - 0.5), pz, tr))
        cols.append((col, rk[i]))
    for i in range(n):
        a, ra = cols[i]
        b, rb = cols[(i + 1) % n]
        r = (ra + rb) / 2
        L = min(len(a), len(b))
        for k in range(L - 1):
            p0, p1, p2, p3 = a[k], b[k], b[k + 1], a[k + 1]
            if k + 1 >= len(a) or k + 1 >= len(b):
                break
            dmid = (p0[3] + p2[3]) / 2
            if dmid < -1.1:
                mat = "ShoalDeep"
            elif dmid < -0.15:
                mat = "ShoalLight"
            elif dmid < 2.6:
                mat = "Rock" if r > 0.5 else "Sand"
            elif dmid < 4.5 and r > 0.5:
                mat = "Rock"
            else:
                mat = "Grass"
            q = [np.array(p[:3]) for p in (p0, p1, p2, p3)]
            m.quad(mat, q[0], q[1], q[2], q[3], out=(0, 1, 0))
        # the longer column's tail (the outer ring reached past the shorter one): a fan
        if len(a) != len(b):
            longer, shorter = (a, b) if len(a) > len(b) else (b, a)
            for k in range(L - 1, len(longer) - 1):
                m.tri("Grass", longer[k][:3], longer[k + 1][:3], shorter[-1][:3], out=(0, 1, 0))
    return m


# ---------------------------------------------------------------- islets
def make_islets():
    m = Mesh()
    m.mat("ShoalDeep", C["shoal_deep"])
    m.mat("ShoalLight", C["shoal_light"])
    m.mat("Sand", C["sand"])
    m.mat("Grass", C["grass"])
    m.mat("Rock", C["rock"])
    for il in ISLETS:
        name, cx, cz, r0, _, kind = il
        if kind == "rock":
            rings = [(2.2, 0.0, "ShoalDeep"), (0.9, 0.0, "ShoalLight"), (0.15, 0.03, "Rock"),
                     (-0.45, 0.95, "Rock"), (-1.4, 1.55, "Rock")]
            top = 1.9
        else:
            rings = [(2.4, 0.0, "ShoalDeep"), (1.0, 0.0, "ShoalLight"), (0.15, 0.03, "Sand"),
                     (-1.1, 0.35, "Sand"), (-2.3, 0.75, "Grass"), (-3.6, 1.1, "Grass"), (-4.8, 1.3, "Grass")]
            top = 1.35
        nseg = max(14, int(2 * math.pi * r0 / 1.6))
        grid = []
        for i in range(nseg):
            th = 2 * math.pi * i / nseg
            R = islet_r(il, th)
            north = max(0.0, -math.sin(th))   # z < centre: the north side
            col = []
            for off, y, mat in rings:
                rr = R + off
                if rr < 0.6:
                    break
                yy = y
                if name == "lantern" and north > 0.55 and off < 0.5:
                    yy = max(y, 1.1 if off > -0.5 else y + 0.2)    # a low rocky cliff on the north side
                if off < -1.0:
                    yy += 0.18 * (jit(cx + rr * math.cos(th), cz + rr * math.sin(th), 3) - 0.5)
                col.append((cx + rr * math.cos(th), yy, cz + rr * math.sin(th), mat, north))
            grid.append(col)
        for i in range(nseg):
            a, b = grid[i], grid[(i + 1) % nseg]
            L = min(len(a), len(b))
            for k in range(L - 1):
                mat = a[k + 1][3] if a[k][3].startswith("Shoal") is False else a[k][3]
                if a[k][3].startswith("Shoal"):
                    mat = a[k][3]
                else:
                    mat = a[k + 1][3]
                if name == "lantern" and a[k][4] > 0.55 and not mat.startswith("Shoal") and k < 4:
                    mat = "Rock"
                m.quad(mat, a[k][:3], b[k][:3], b[k + 1][:3], a[k + 1][:3], out=(0, 1, 0))
            ca = (cx, top, cz)
            lm = "Rock" if kind == "rock" else "Grass"
            m.tri(lm, a[L - 1][:3], b[L - 1][:3], ca, out=(0, 1, 0))
    return m


def islet_height(il, x, z):
    """The approximate ground height on an islet's top (props stand on it)."""
    _, cx, cz, r0, _, kind = il
    d = math.hypot(x - cx, z - cz)
    th = math.atan2(z - cz, x - cx)
    R = islet_r(il, th)
    rings = [(0.15, 0.03), (-1.1, 0.35), (-2.3, 0.75), (-3.6, 1.1), (-4.8, 1.3)]
    off = d - R
    prev = None
    for o, y in rings:
        if off >= o:
            if prev is None:
                return y
            o0, y0 = prev
            t = (off - o) / (o0 - o)
            return y + (y0 - y) * t
        prev = (o, y)
    return 1.35


# ---------------------------------------------------------------- static ripples
def make_ripples():
    m = Mesh()
    m.mat("Ripple", "#8db7ff")
    rng = random.Random(7)
    placed = []
    tries = 0
    while len(placed) < 420 and tries < 40000:
        tries += 1
        x = rng.uniform(-39, 39)
        z = rng.uniform(-34, 32)
        u, v = (x - BAY_CX) / (BAY_AX - 4.0), (z - BAY_CZ) / (BAY_AZ - 4.0)
        if u ** 4 + v ** 4 > 1:
            continue
        if any(math.hypot(x - il[1], z - il[2]) < il[3] * 1.2 + 3.5 for il in ISLETS):
            continue
        if any(math.hypot(x - px, z - pz) < 2.4 for px, pz in placed):
            continue
        placed.append((x, z))
        L = rng.uniform(0.6, 1.0)
        w = 0.14
        a = math.radians(rng.uniform(-14, 14))
        dx, dz = math.cos(a) * L / 2, -math.sin(a) * L / 2
        ex, ez = math.sin(a) * w / 2, math.cos(a) * w / 2
        y = 0.06
        m.quad("Ripple", (x - dx - ex, y, z - dz - ez), (x + dx - ex, y, z + dz - ez),
               (x + dx + ex, y, z + dz + ez), (x - dx + ex, y, z - dz + ez), out=(0, 1, 0))
    return m


# ---------------------------------------------------------------- props
def tree_pine(m, x, y, z, s, rng):
    m.box("Trunk", x, y + 0.3 * s, z, 0.3 * s, 0.6 * s, 0.3 * s, yaw=rng.uniform(0, 90))
    rot = rng.random()
    m.cone("Leaf", x, y + 0.5 * s, z, 1.15 * s, 1.5 * s, n=7, rot=rot)
    m.cone("Leaf", x, y + 1.35 * s, z, 0.85 * s, 1.3 * s, n=7, rot=rot + 0.5)


def tree_round(m, x, y, z, s, rng):
    m.box("Trunk", x, y + 0.45 * s, z, 0.32 * s, 0.9 * s, 0.32 * s, yaw=rng.uniform(0, 90))
    m.blob("Leaf", x, y + 1.6 * s, z, 1.15 * s, 0.95 * s, 1.15 * s, rng, jitter=0.18)


def bush(m, x, y, z, s, rng):
    m.blob("Bloom", x, y + 0.25 * s, z, 0.75 * s, 0.5 * s, 0.75 * s, rng, jitter=0.2, cut=y + 0.02)


def cottage(m, x, y, z, yaw, roof, w=2.6, d=2.0, h=1.5):
    m.box("Wall", x, y + h / 2 - 0.2, z, w, h + 0.4, d, yaw=yaw)
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))

    def P(dx, dy, dz):
        return (x + dx * c + dz * s, y + h + dy, z - dx * s + dz * c)
    hw, hd, rh, ov = w / 2 + 0.2, d / 2 + 0.25, 1.0, 0.0
    pts = [P(-hw, -0.05, -hd), P(hw, -0.05, -hd), P(hw, -0.05, hd), P(-hw, -0.05, hd),
           P(-hw, rh, 0), P(hw, rh, 0)]
    faces = [[0, 1, 5, 4], [3, 2, 5, 4], [0, 3, 4], [1, 2, 5]]
    m.solid(roof, pts, faces, centre=P(0, 0.3, 0))
    # a door on the front (+z local) face, proud by a splat
    m.box("Door", *P(0.5, -h + 0.45, d / 2 + 0.06), 0.5, 0.9, 0.12, yaw=yaw)


def lighthouse(m, x, y, z):
    bands = [("Red", 0.95, 0.88), ("Tower", 0.88, 0.81), ("Red", 0.81, 0.74), ("Tower", 0.74, 0.67),
             ("Red", 0.67, 0.6)]
    hb = 0.92
    yy = y
    for mat, r0, r1 in bands:
        m.frustum(mat, x, yy, z, r0, r1, hb, n=8, top=False, rot=0.5)
        yy += hb
    m.frustum("Dark", x, yy, z, 1.0, 1.0, 0.16, n=8, rot=0.5)          # the gallery
    yy += 0.16
    m.frustum("Lamp", x, yy, z, 0.5, 0.5, 0.7, n=8, top=False, rot=0.5)  # the lantern room (unlit)
    yy += 0.7
    m.cone("Red", x, yy, z, 0.72, 0.6, n=8, rot=0.5)
    yy += 0.55
    m.box("Dark", x, yy + 0.5, z, 0.09, 1.0, 0.09)                       # the flag pole
    return yy + 1.0


def jetty(m, x, z0, z1, y=0.42):
    m.box("Plank", x, y - 0.06, (z0 + z1) / 2, 1.5, 0.12, z1 - z0)
    zz = z0 + 0.3
    while zz < z1:
        for sx in (-0.72, 0.72):
            m.box("Post", x + sx, 0.28, zz, 0.2, 0.56, 0.2)
        zz += 1.6


def make_props():
    m = Mesh()
    for k, v in (("Trunk", C["trunk"]), ("Leaf", C["tree"]), ("Bloom", C["bloom"]), ("Wall", C["white"]),
                 ("Roof", C["roof"]), ("Roof2", C["roof2"]), ("Door", C["post"]), ("Red", C["red"]),
                 ("Tower", C["pure"]), ("Dark", C["dark"]), ("Lamp", C["lamp"]), ("Plank", C["wood"]),
                 ("Post", C["post"])):
        m.mat(k, v)
    rng = random.Random(11)
    lt = ISLETS[0]
    ly = islet_height(lt, *LIGHTHOUSE)
    flag_y = lighthouse(m, LIGHTHOUSE[0], ly - 0.05, LIGHTHOUSE[1])
    # keeper's cottage and a few things on Lantern Isle
    cottage(m, 1.4, islet_height(lt, 1.4, -2.6) - 0.05, -2.6, -20, "Roof2", w=2.2, d=1.7, h=1.2)
    for (tx, tz, s) in ((-5.6, -2.2, 0.9), (-4.6, 0.2, 0.8), (2.4, -6.2, 0.75)):
        tree_round(m, tx, islet_height(lt, tx, tz) - 0.05, tz, s, rng)
    for (bx, bz) in ((-0.6, -0.4), (0.4, -6.0), (-4.8, -5.6)):
        bush(m, bx, islet_height(lt, bx, bz) - 0.05, bz, 0.9, rng)
    pk = ISLETS[2]
    for (tx, tz, s) in ((17.4, 13.4, 0.95), (19.2, 15.0, 0.8)):
        tree_pine(m, tx, islet_height(pk, tx, tz) - 0.05, tz, s, rng)
    # the village on the north shore, the jetty, and trees and bushes round the bay
    for (cx, cz, yaw, roof) in ((-9.5, -36.4, 8, "Roof"), (-4.2, -37.4, -6, "Roof2"), (10.5, -36.6, 12, "Roof"),
                                (15.6, -37.6, -10, "Roof2")):
        cottage(m, cx, land_height(cx, cz) - 0.08, cz, yaw, roof)
    jetty(m, JETTY_X, -33.0, -27.8)
    trng = random.Random(5)
    placed = []
    for _ in range(4000):
        if len(placed) >= 36:
            break
        x, z = trng.uniform(-48, 48), trng.uniform(-44, 40)
        u, v = (x - BAY_CX) / (BAY_AX + 5.5), (z - BAY_CZ) / (BAY_AZ + 5.5)
        if u ** 4 + v ** 4 < 1:
            continue
        if -18 < x < 20 and z < -32:      # the village keeps its meadow
            continue
        if any(math.hypot(x - px, z - pz) < 3.6 for px, pz in placed):
            continue
        placed.append((x, z))
        y = land_height(x, z) - 0.08
        k = trng.random()
        if k < 0.45:
            tree_pine(m, x, y, z, trng.uniform(0.85, 1.25), rng)
        elif k < 0.8:
            tree_round(m, x, y, z, trng.uniform(0.85, 1.2), rng)
        else:
            bush(m, x, y, z, trng.uniform(0.9, 1.3), rng)
    for (bx, bz) in ((-14, -35.0), (-1, -35.4), (7, -35.2), (20, -35.8)):
        bush(m, bx, land_height(bx, bz) - 0.05, bz, 1.0, rng)
    return m, (LIGHTHOUSE[0], flag_y, LIGHTHOUSE[1])


_coast = None


def land_height(x, z):
    """The mainland's height at a point (from the same rings as make_bay, nearest column)."""
    global _coast
    if _coast is None:
        _coast = resample_coast(2.0)
    best = None
    for cx, cz in _coast:
        nx, nz = coast_normal(cx, cz)
        dx, dz = x - cx, z - cz
        along = dx * nx + dz * nz
        perp = abs(-dx * nz + dz * nx)
        if along >= -0.5 and (best is None or perp < best[0]):
            best = (perp, along, cx, cz)
    _, d, cx, cz = best
    r = rockiness(cx, cz)
    land_d = [-0.15, 0.8, 2.0, 3.8, 6.5, 10.0, 15.0, 21.0, 40.0]
    sandy_y = [0.03, 0.2, 0.42, 0.75, 1.1, 1.4, 1.7, 1.9, 1.9]
    rocky_y = [0.03, 1.3, 1.5, 1.75, 1.9, 2.0, 2.1, 2.2, 2.2]
    for k in range(len(land_d) - 1):
        if d <= land_d[k + 1]:
            t = (d - land_d[k]) / (land_d[k + 1] - land_d[k])
            ys = sandy_y[k] + (sandy_y[k + 1] - sandy_y[k]) * t
            yr = rocky_y[k] + (rocky_y[k + 1] - rocky_y[k]) * t
            y = ys * (1 - r) + yr * r
            if d >= 2.0:
                y += hills(x, z) * smoothstep(2.0, 10.0, d)
            return y
    return 1.9 + hills(x, z)


# ---------------------------------------------------------------- game pieces
def make_buoy():
    m = Mesh()
    m.mat("Buoy", C["orange"])
    m.mat("BuoyTop", C["pure"])
    m.frustum("Buoy", 0, 0, 0, 0.5, 0.42, 0.55, n=8, top=False, rot=0.5)
    m.frustum("BuoyTop", 0, 0.55, 0, 0.42, 0.3, 0.22, n=8, top=True, rot=0.5)
    m.box("Buoy", 0, 0.77 + 0.15, 0, 0.14, 0.3, 0.14)
    return m


def make_marker():
    m = Mesh()
    m.mat("Marker", C["yellow"])
    pts = [(0, 0.45, 0), (0, -0.45, 0), (0.32, 0, 0), (-0.32, 0, 0), (0, 0, 0.32), (0, 0, -0.32)]
    faces = [[0, 2, 4], [0, 4, 3], [0, 3, 5], [0, 5, 2], [1, 4, 2], [1, 3, 4], [1, 5, 3], [1, 2, 5]]
    m.solid("Marker", pts, faces, centre=(0, 0, 0))
    return m


def disc(m, mat, cx, cz, r, n, rng, y=0.0, wob=0.22):
    rs = [r * (1 - wob * rng.random()) for _ in range(n)]
    for i in range(n):
        a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
        m.tri(mat, (cx, y, cz), (cx + rs[i] * math.cos(a0), y, cz + rs[i] * math.sin(a0)),
              (cx + rs[(i + 1) % n] * math.cos(a1), y, cz + rs[(i + 1) % n] * math.sin(a1)), out=(0, 1, 0))


def make_gust():
    m = Mesh()
    m.mat("Gust", C["gust"])
    m.mat("GustRip", C["gustrip"])
    rng = random.Random(3)
    disc(m, "Gust", 0, 0, 6.0, 18, rng, wob=0.25)
    for k, (dx, dz, r) in enumerate(((-3.6, -2.2, 2.4), (3.4, 1.8, 2.6), (0.8, -3.8, 2.0), (-2.4, 3.4, 2.2))):
        disc(m, "Gust", dx, dz, r, 9, rng, wob=0.3)
    for i in range(30):
        a, rr = rng.uniform(0, 2 * math.pi), 5.0 * math.sqrt(rng.random())
        x, z = rr * math.cos(a), rr * math.sin(a)
        L, w, y = rng.uniform(0.6, 1.0), 0.14, 0.05
        m.quad("GustRip", (x - L / 2, y, z - w / 2), (x + L / 2, y, z - w / 2), (x + L / 2, y, z + w / 2),
               (x - L / 2, y, z + w / 2), out=(0, 1, 0))
    return m


def make_streak():
    m = Mesh()
    m.mat("Streak", C["streak"])
    y, w = 0.0, 0.16
    xs = [-0.95, -0.35, 0.35, 0.95]
    zs = [0.12, -0.05, -0.05, 0.12]
    for i in range(3):
        a, b = (xs[i], zs[i]), (xs[i + 1], zs[i + 1])
        m.quad("Streak", (a[0], y, a[1] - w / 2), (b[0], y, b[1] - w / 2), (b[0], y, b[1] + w / 2),
               (a[0], y, a[1] + w / 2), out=(0, 1, 0))
    return m


def make_foam():
    m = Mesh()
    m.mat("Foam", C["pure"])
    disc(m, "Foam", 0, 0, 0.5, 7, random.Random(9), wob=0.3)
    return m


def make_flag():
    """The lighthouse's wind flag: a striped windsock (a flag that reads from every side), its mouth on
    the pole (the pivot), streaming along +Z: 1.3 long, 0.56 across at the mouth, 0.26 at the tail."""
    m = Mesh()
    m.mat("Flag", C["red"])
    m.mat("FlagWhite", C["pure"])
    n = 8
    rings = [(0.0, 0.28), (0.45, 0.23), (0.9, 0.18), (1.3, 0.13)]
    for k in range(len(rings) - 1):
        (z0, r0), (z1, r1) = rings[k], rings[k + 1]
        mat = "Flag" if k % 2 == 0 else "FlagWhite"
        for i in range(n):
            a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
            p0 = (r0 * math.cos(a0), r0 * math.sin(a0), z0)
            p1 = (r0 * math.cos(a1), r0 * math.sin(a1), z0)
            p2 = (r1 * math.cos(a1), r1 * math.sin(a1), z1)
            p3 = (r1 * math.cos(a0), r1 * math.sin(a0), z1)
            out = (math.cos((a0 + a1) / 2), math.sin((a0 + a1) / 2), 0)
            m.quad(mat, p0, p1, p2, p3, out=out)
    return m


def make_dinghy(hull):
    m = Mesh()
    m.mat("Hull", hull)
    m.mat("Seat", C["wood"])
    m.mat("Spar", C["dark"])
    m.mat("Furl", C["pure"])
    L, W, H = 2.5, 1.05, 0.38
    pts = [(-W / 2, 0, -L / 2), (W / 2, 0, -L / 2), (W / 2 * 0.8, 0, L / 2 - 0.5), (0, 0, L / 2),
           (-W / 2 * 0.8, 0, L / 2 - 0.5),
           (-W / 2, H, -L / 2), (W / 2, H, -L / 2), (W / 2, H, L / 2 - 0.5), (0, H + 0.08, L / 2 + 0.1),
           (-W / 2, H, L / 2 - 0.5)]
    m.solid("Hull", pts, [[5, 6, 7, 8, 9], [0, 1, 6, 5], [1, 2, 7, 6], [2, 3, 8, 7], [3, 4, 9, 8], [4, 0, 5, 9]],
            centre=(0, H / 2, 0))
    m.box("Seat", 0, H + 0.04, -0.3, W * 0.8, 0.08, 0.7)
    m.box("Spar", 0, H + 1.1, 0.45, 0.09, 2.2, 0.09)
    m.box("Furl", 0, H + 0.42, -0.25, 0.18, 0.16, 1.45)
    return m


if __name__ == "__main__":
    out = {}
    out["bay.glb"] = make_bay()
    out["islets.glb"] = make_islets()
    out["ripples.glb"] = make_ripples()
    props, flag = make_props()
    out["props.glb"] = props
    out["buoy.glb"] = make_buoy()
    out["marker.glb"] = make_marker()
    out["gust.glb"] = make_gust()
    out["streak.glb"] = make_streak()
    out["foam.glb"] = make_foam()
    out["flag.glb"] = make_flag()
    out["dinghy_y.glb"] = make_dinghy(C["yellow"])
    out["dinghy_p.glb"] = make_dinghy(C["bloom"])
    out["dinghy_b.glb"] = make_dinghy("#8db7ff")
    for name, mesh in out.items():
        write_glb(name, mesh)
        print(f"{name:12s} {mesh.count():6d} triangles")
    print(f"flag pivot (the lighthouse's pole top): {flag[0]:.2f} {flag[1]:.2f} {flag[2]:.2f}")
    for il in ISLETS:
        rmax = max(islet_r(il, 2 * math.pi * i / 64) for i in range(64))
        print(f"islet {il[0]:8s} centre {il[1]:6.1f} {il[2]:6.1f}  beach radius max {rmax + 0.15:.2f}")
    for mx, mz in MOORINGS:
        print(f"mooring {mx:6.1f} {mz:6.1f}")
