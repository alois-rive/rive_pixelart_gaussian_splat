# Writes the park's GLBs straight from Python (the curved bowl and quarter pipes must match the game's
# physics, scene/game.as, to the centimetre, so both use the same numbers below). Flat-shaded triangles,
# one primitive per material, material colours exact AAP-64 colours (baseColorFactor is linear, so the
# hex is converted), Y up, metres, the renderer's yaw 0 looks along -Z.
#   park.glb     the concrete slab, the bowl, two quarter pipes, the fun box with its ledges, the kicker,
#                the handrail, the curb
#   yard.glb     the grass round the slab, the back wall with its mural panels, trees, benches, a bin,
#                planters and lamp posts
#   dust.glb     one puff (a squat icosahedron) for the dust pool
#   spark.glb    one spark (a small octahedron) for the grind sparks
# Run from models/env: /usr/bin/python3 make_env.py
import json, math, struct
import numpy as np

# ---------------------------------------------------------------- the park (mirrored in scene/game.as)
SLAB = (-12.5, 13.0, -10.4, 9.5)                      # x0, x1, z0, z1 of the concrete
BX, BZ, RF, RT, BD = -8.0, 0.5, 1.2, 2.0, 1.4         # bowl centre, floor radius, transition radius, depth
BS = math.sqrt(RT * RT - (RT - BD) ** 2)              # the wall's run
RC = RF + BS                                          # the coping's radius
QH, QR = 1.2, 2.0                                     # quarter pipes: height, transition radius
QS = math.sqrt(QR * QR - (QR - QH) ** 2)
QDECK = 1.3                                           # deck depth behind the coping
QP1 = (-5.0, 5.0, -7.2)                               # back: x0, x1, base z (rises towards -z)
QP2 = (-6.0, 2.0, 9.6)                                # right: z0, z1, base x (rises towards +x)
FB = (1.0, 4.0, 0.5, 2.5, 0.45, 1.2)                  # fun box top x0, x1, z0, z1, height, ramp run
KK = (-4.2, -3.0, -5.3, -3.7, 0.6)                    # kicker x0, x1 (rises to +x), z0, z1, height
RAIL = (-4.0, 1.5, 6.0, 0.55, 0.08)                   # handrail x0, x1, z, top height, bar size


def srgb_lin(hx):
    c = [int(hx[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]


class Mesh:
    def __init__(self):
        self.tris = {}          # material -> list of (a, b, c)

    def tri(self, mat, a, b, c, out=None):
        a, b, c = (np.array(p, dtype=np.float64) for p in (a, b, c))
        n = np.cross(b - a, c - a)
        if np.linalg.norm(n) < 1e-10:
            return
        if out is not None and np.dot(n, out) < 0:
            b, c = c, b
        self.tris.setdefault(mat, []).append((a, b, c))

    def quad(self, mat, a, b, c, d, out=None):
        self.tri(mat, a, b, c, out)
        self.tri(mat, a, c, d, out)

    def box(self, mat, x0, x1, y0, y1, z0, z1, skip=()):
        P = lambda x, y, z: (x, y, z)
        cx, cy, cz = (x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2
        faces = {"top": ((x0, y1, z0), (x1, y1, z0), (x1, y1, z1), (x0, y1, z1), (0, 1, 0)),
                 "bottom": ((x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1), (0, -1, 0)),
                 "-x": ((x0, y0, z0), (x0, y1, z0), (x0, y1, z1), (x0, y0, z1), (-1, 0, 0)),
                 "+x": ((x1, y0, z0), (x1, y1, z0), (x1, y1, z1), (x1, y0, z1), (1, 0, 0)),
                 "-z": ((x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (0, 0, -1)),
                 "+z": ((x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1), (0, 0, 1))}
        for k, (a, b, c, d, o) in faces.items():
            if k not in skip:
                m = mat[k] if isinstance(mat, dict) else mat
                self.quad(m, a, b, c, d, o)

    def write(self, path, colors):
        bufs, views, accs, prims, mats = bytearray(), [], [], [], []
        for mi, (mat, tris) in enumerate(sorted(self.tris.items())):
            pos = np.array([p for t in tris for p in t], dtype=np.float32)
            nrm = []
            for a, b, c in tris:
                n = np.cross(b - a, c - a)
                n /= np.linalg.norm(n)
                nrm += [n, n, n]
            nrm = np.array(nrm, dtype=np.float32)
            for arr, kind in ((pos, "POSITION"), (nrm, "NORMAL")):
                off = len(bufs)
                bufs += arr.tobytes()
                while len(bufs) % 4:
                    bufs += b"\0"
                views.append({"buffer": 0, "byteOffset": off, "byteLength": arr.nbytes})
                acc = {"bufferView": len(views) - 1, "componentType": 5126, "count": len(arr), "type": "VEC3"}
                if kind == "POSITION":
                    acc["min"] = pos.min(0).tolist()
                    acc["max"] = pos.max(0).tolist()
                accs.append(acc)
            prims.append({"attributes": {"POSITION": len(accs) - 2, "NORMAL": len(accs) - 1}, "material": mi})
            mats.append({"name": mat, "pbrMetallicRoughness": {"baseColorFactor": srgb_lin(colors[mat]) + [1.0],
                                                               "metallicFactor": 0.0, "roughnessFactor": 1.0}})
        gl = {"asset": {"version": "2.0", "generator": "kick-park make_env.py"}, "scene": 0,
              "scenes": [{"nodes": [0]}], "nodes": [{"mesh": 0, "name": path.split(".")[0]}],
              "meshes": [{"primitives": prims}], "materials": mats, "accessors": accs, "bufferViews": views,
              "buffers": [{"byteLength": len(bufs)}]}
        js = json.dumps(gl).encode()
        while len(js) % 4:
            js += b" "
        out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(bufs))
        out += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(bufs), 0x004E4942) + bytes(bufs)
        open(path, "wb").write(out)
        n = sum(len(t) for t in self.tris.values())
        print(f"wrote {path}: {n} triangles, materials {', '.join(sorted(self.tris))}")


COL = {"Concrete": "#b3b9d1", "Pool": "#849be4", "Warm": "#c7b08b", "Coping": "#6d758d", "Paint": "#f9a31b",
       "Rail": "#ffd541", "Box": "#20d6c7", "Kick": "#dba463", "Grass": "#59c135", "Leaf": "#5daf8d",
       "LeafB": "#14a02e", "Bark": "#71413b", "Wood": "#bb7547", "Wall": "#c7b08b", "MuralA": "#249fde",
       "MuralB": "#e86a73", "MuralC": "#ffd541", "MuralD": "#5daf8d", "Metal": "#6d758d", "Lamp": "#fef3c0",
       "Dust": "#e4d2aa", "Spark": "#fffc40", "Curb": "#a08662", "Seam": "#8b93af"}

# ---------------------------------------------------------------- park.glb
park = Mesh()
UP = (0, 1, 0)
x0, x1, z0, z1 = SLAB


def covered(cx, cz):
    """Slab cells hidden under a feature (their faces would only bake splats nobody sees)."""
    if math.hypot(cx - BX, cz - BZ) < RC + 0.45:
        return True
    if QP1[0] <= cx <= QP1[1] and cz < QP1[2]:
        return True
    if QP2[0] <= cz <= QP2[1] and cx > QP2[2]:
        return True
    if FB[0] - FB[5] <= cx <= FB[1] + FB[5] and FB[2] <= cz <= FB[3]:
        return True
    if KK[0] <= cx <= KK[1] and KK[2] <= cz <= KK[3]:
        return True
    return False


# the slab, 0.5 m cells (cells under a feature dropped; the bowl's apron covers its ring)
CELL = 0.5
SEAM_EVERY, SW = 6, 0.06    # a joint every 3 m, 12 cm wide (two half strips)
nx, nz = int(round((x1 - x0) / CELL)), int(round((z1 - z0) / CELL))
for i in range(nx):
    for j in range(nz):
        ax, az = x0 + i * (x1 - x0) / nx, z0 + j * (z1 - z0) / nz
        bx, bz = x0 + (i + 1) * (x1 - x0) / nx, z0 + (j + 1) * (z1 - z0) / nz
        if covered((ax + bx) / 2, (az + bz) / 2):
            # keep the cells half under a fun box ramp or a kicker side: they show beside it
            continue
        # expansion joints every 3 m: the cell gives up a strip along a joint edge to a darker seam
        a0, a1, c0, c1 = ax, bx, az, bz
        if i % SEAM_EVERY == 0 and i > 0:
            park.quad("Seam", (ax, 0, az), (ax + SW, 0, az), (ax + SW, 0, bz), (ax, 0, bz), UP); a0 = ax + SW
        if (i + 1) % SEAM_EVERY == 0 and i < nx - 1:
            park.quad("Seam", (bx - SW, 0, az), (bx, 0, az), (bx, 0, bz), (bx - SW, 0, bz), UP); a1 = bx - SW
        if j % SEAM_EVERY == 0 and j > 0:
            park.quad("Seam", (a0, 0, az), (a1, 0, az), (a1, 0, az + SW), (a0, 0, az + SW), UP); c0 = az + SW
        if (j + 1) % SEAM_EVERY == 0 and j < nz - 1:
            park.quad("Seam", (a0, 0, bz - SW), (a1, 0, bz - SW), (a1, 0, bz), (a0, 0, bz), UP); c1 = bz - SW
        park.quad("Concrete", (a0, 0, c0), (a1, 0, c0), (a1, 0, c1), (a0, 0, c1), UP)

# the bowl: floor, wall (the circular transition), the coping band, an apron out to the slab cells
NA = 40
rings = [(0.0, -BD, "Pool"), (RF, -BD, "Pool")]
NW = 9
for k in range(1, NW + 1):
    s = BS * k / NW
    rings.append((RF + s, -BD + RT - math.sqrt(RT * RT - s * s), "Pool" if k < NW else "Coping"))
rings += [(RC + 0.12, 0.0, "Coping"), (RC + 1.15, 0.0, "Concrete")]
for a in range(NA):
    t0, t1 = 2 * math.pi * a / NA, 2 * math.pi * (a + 1) / NA
    c0, s0, c1, s1 = math.cos(t0), math.sin(t0), math.cos(t1), math.sin(t1)
    for k in range(len(rings) - 1):
        ra, ya, _ = rings[k]
        rb, yb, mat = rings[k + 1]
        if mat == "Pool" and k == 0:
            mat = "Pool"
        pa0, pa1 = (BX + ra * c0, ya, BZ + ra * s0), (BX + ra * c1, ya, BZ + ra * s1)
        pb0, pb1 = (BX + rb * c0, yb, BZ + rb * s0), (BX + rb * c1, yb, BZ + rb * s1)
        rm = (ra + rb) / 2
        out = (-(c0 + c1) / 2 * (yb - ya) * 4, 1.0, -(s0 + s1) / 2 * (yb - ya) * 4) if rb > ra else UP
        park.quad(mat, pa0, pa1, pb1, pb0, out)

# quarter pipes: the transition in strips, the coping band, the deck, the back and the side walls
NQ = 10


def qp_profile():
    pts = [(0.0, 0.0)]
    for k in range(1, NQ + 1):
        d = QS * k / NQ
        pts.append((d, QR - math.sqrt(QR * QR - d * d)))
    return pts


prof = qp_profile()


def qp(world):
    """world(u, v, y) -> point: u runs from the base up the ramp, v across it (lo..hi)."""
    lo, hi = 0.0, 1.0
    for k in range(len(prof) - 1):
        (ua, ya), (ub, yb) = prof[k], prof[k + 1]
        mat = "Coping" if k == len(prof) - 2 else "Pool"
        park.quad(mat, world(ua, lo, ya), world(ua, hi, ya), world(ub, hi, yb), world(ub, lo, yb), None)
    # deck: a coping band, then the deck top
    park.quad("Coping", world(QS, lo, QH), world(QS, hi, QH), world(QS + 0.14, hi, QH), world(QS + 0.14, lo, QH), None)
    park.quad("Warm", world(QS + 0.14, lo, QH), world(QS + 0.14, hi, QH), world(QS + QDECK, hi, QH), world(QS + QDECK, lo, QH), None)
    # back wall (hidden by the park's own back wall for QP1, seen for QP2 only from outside: kept small)
    park.quad("Warm", world(QS + QDECK, lo, 0), world(QS + QDECK, hi, 0), world(QS + QDECK, hi, QH), world(QS + QDECK, lo, QH), None)
    # side walls: the profile and the deck down to the ground, as fans
    for v in (lo, hi):
        pts = [(u, y) for u, y in prof] + [(QS + QDECK, QH)]
        for k in range(len(pts) - 1):
            (ua, ya), (ub, yb) = pts[k], pts[k + 1]
            park.quad("Warm", world(ua, v, 0), world(ub, v, 0), world(ub, v, yb), world(ua, v, ya), None)


def orient(m, center, mats=None):
    """Flip every triangle of the last-added geometry to face away from `center` (or up for floors)."""


# QP1: base z -7.2, rises to -z; v across x
def qp1(u, v, y):
    return (QP1[0] + (QP1[1] - QP1[0]) * v, y, QP1[2] - u)


def qp2(u, v, y):
    return (QP2[2] + u, y, QP2[0] + (QP2[1] - QP2[0]) * v)


for fn, out_dir in ((qp1, (0, 0, 1)), (qp2, (-1, 0, 0))):
    before = {k: len(v) for k, v in park.tris.items()}
    qp(fn)
    # orient the new triangles: ramp faces towards the open side and up, side walls outwards
    for mat, tris in park.tris.items():
        for i in range(before.get(mat, 0), len(tris)):
            a, b, c = tris[i]
            n = np.cross(b - a, c - a)
            n /= np.linalg.norm(n)
            if abs(n[1]) > 0.05 or abs(np.dot(n, out_dir)) > 0.5:
                want = np.array(out_dir, dtype=float) + np.array([0, 1.0, 0])
            else:
                # a side wall: outwards from the ramp's middle
                mid = np.array(fn(1.0, 0.5, 0.5))
                want = (a + b + c) / 3 - mid
                want[1] = 0
            if np.dot(n, want) < 0:
                tris[i] = (a, c, b)

# fun box: ramps, top, side walls (painted), the steel ledges on the long top edges
fx0, fx1, fz0, fz1, fh, fr = FB
L = 0.09   # the ledge band
park.quad("Box", (fx0 - fr, 0, fz0), (fx0, fh, fz0), (fx0, fh, fz1), (fx0 - fr, 0, fz1), (-1, 2, 0))
park.quad("Box", (fx1, fh, fz0), (fx1 + fr, 0, fz0), (fx1 + fr, 0, fz1), (fx1, fh, fz1), (1, 2, 0))
park.quad("Warm", (fx0, fh, fz0 + L), (fx1, fh, fz0 + L), (fx1, fh, fz1 - L), (fx0, fh, fz1 - L), UP)
for zz, sg in ((fz0, 1), (fz1, -1)):
    park.quad("Coping", (fx0, fh, zz), (fx1, fh, zz), (fx1, fh, zz + sg * L), (fx0, fh, zz + sg * L), UP)
    park.quad("Coping", (fx0, fh - L, zz), (fx1, fh - L, zz), (fx1, fh, zz), (fx0, fh, zz), (0, 0, -sg))
    park.quad("Paint", (fx0, 0, zz), (fx1, 0, zz), (fx1, fh - L, zz), (fx0, fh - L, zz), (0, 0, -sg))
    park.tri("Paint", (fx0 - fr, 0, zz), (fx0, 0, zz), (fx0, fh, zz), (0, 0, -sg))
    park.tri("Paint", (fx1, 0, zz), (fx1 + fr, 0, zz), (fx1, fh, zz), (0, 0, -sg))

# kicker: the ramp, its sides and back
kx0, kx1, kz0, kz1, kh = KK
park.quad("Kick", (kx0, 0, kz0), (kx1, kh, kz0), (kx1, kh, kz1), (kx0, 0, kz1), (-1, 2, 0))
park.quad("Coping", (kx1 - 0.08, kh * (1 - 0.08 / (kx1 - kx0)), kz0), (kx1, kh, kz0), (kx1, kh, kz1),
          (kx1 - 0.08, kh * (1 - 0.08 / (kx1 - kx0)), kz1), (-1, 2, 0))
park.quad("Metal", (kx1, 0, kz0), (kx1, kh, kz0), (kx1, kh, kz1), (kx1, 0, kz1), (1, 0, 0))
park.tri("Metal", (kx0, 0, kz0), (kx1, 0, kz0), (kx1, kh, kz0), (0, 0, -1))
park.tri("Metal", (kx0, 0, kz1), (kx1, 0, kz1), (kx1, kh, kz1), (0, 0, 1))

# handrail: a square bar on three posts (exaggerated: 8 cm, so two splats across)
rx0, rx1, rz, ry, rb = RAIL
park.box("Rail", rx0 - 0.05, rx1 + 0.05, ry - rb, ry, rz - rb / 2, rz + rb / 2, skip=("bottom",))
park.box("Rail", rx0 - 0.05, rx0 + 0.03, 0, ry - rb, rz - rb / 2, rz + rb / 2, skip=("bottom", "top"))
for px in (rx0 + (rx1 - rx0) / 2 - 0.04, rx1 - 0.08):
    park.box("Metal", px, px + 0.08, 0, ry - rb, rz - 0.04, rz + 0.04, skip=("bottom", "top"))
park.box("Rail", rx1 - 0.03, rx1 + 0.05, 0, ry - rb, rz - rb / 2, rz + rb / 2, skip=("bottom", "top"))

# the curb round the slab (front and sides; the back is the wall)
CH = 0.14
for (ax, az, bx, bz, o) in ((x0, z1, x1, z1, (0, 0, 1)), (x0 - 0.3, z0, x0, z1 + 0.3, (-1, 0, 0)),
                            (x1, z0, x1 + 0.3, z1 + 0.3, (1, 0, 0))):
    if o[2]:
        park.box("Curb", ax - 0.3, bx + 0.3, 0, CH, az, az + 0.3, skip=("bottom",))
    else:
        park.box("Curb", ax, bx, 0, CH, az, bz, skip=("bottom",))
park.write("park.glb", COL)

# ---------------------------------------------------------------- yard.glb
yard = Mesh()
GX0, GX1, GZ0, GZ1 = -17.0, 17.5, -11.0, 14.0
# grass: big cells round the slab (skipping the slab and the curb)
for (ax, bx, az, bz) in ((GX0, x0 - 0.3, GZ0, GZ1), (x1 + 0.3, GX1, GZ0, GZ1), (x0 - 0.3, x1 + 0.3, z1 + 0.3, GZ1)):
    n_x = max(1, int((bx - ax) / 1.5))
    n_z = max(1, int((bz - az) / 1.5))
    for i in range(n_x):
        for j in range(n_z):
            a0, a1 = ax + (bx - ax) * i / n_x, ax + (bx - ax) * (i + 1) / n_x
            c0, c1 = az + (bz - az) * j / n_z, az + (bz - az) * (j + 1) / n_z
            yard.quad("Grass", (a0, 0, c0), (a1, 0, c0), (a1, 0, c1), (a0, 0, c1), UP)
# the back wall behind QP1 and along the back, with mural panels (colour blocks, no text)
WZ, WH = z0 - 0.02, 2.4
yard.box("Wall", x0 - 0.3, x1 + 0.3, 0, WH, WZ - 0.4, WZ, skip=("bottom", "-z", "top"))
yard.box("Wall", x0 - 0.3, x1 + 0.3, WH, WH + 0.12, WZ - 0.45, WZ + 0.05, skip=("-z",))
panels = [(-12.0, -9.0, "MuralA"), (-9.0, -7.4, "MuralB"), (-7.4, -5.2, "MuralD"), (5.4, 7.6, "MuralC"),
          (7.6, 10.2, "MuralA"), (10.2, 12.6, "MuralB")]
for (a, b, m) in panels:
    # boards standing off the wall by more than a splat spacing (a coplanar overlay would fight it)
    yard.box(m, a + 0.04, b - 0.04, 0.25, WH - 0.2, WZ, WZ + 0.16, skip=("bottom", "-z"))
# a few big shapes on the panels: diamonds and stripes in other mural colours (proud of the panel)
shapes = [(-10.5, 1.3, 0.6, "MuralC"), (-8.2, 1.2, 0.45, "MuralD"), (-6.3, 1.25, 0.55, "MuralB"),
          (6.5, 1.3, 0.55, "MuralA"), (8.9, 1.25, 0.6, "MuralB"), (11.4, 1.3, 0.55, "MuralD")]
for (cx, cy, r, m) in shapes:
    zz = WZ + 0.34
    yard.quad(m, (cx, cy - r, zz), (cx + r, cy, zz), (cx, cy + r, zz), (cx - r, cy, zz), (0, 0, 1))


def tree(cx, cz, s, mat):
    # a trunk and two stacked low-poly crowns (8-sided frustums)
    yard.box("Bark", cx - 0.12 * s, cx + 0.12 * s, 0, 1.2 * s, cz - 0.12 * s, cz + 0.12 * s, skip=("bottom",))
    for (y0, y1, r0, r1) in ((1.0, 2.2, 1.0, 0.75), (2.2, 3.1, 0.75, 0.15)):
        for k in range(8):
            t0, t1 = 2 * math.pi * k / 8, 2 * math.pi * (k + 1) / 8
            a0 = (cx + r0 * s * math.cos(t0), y0 * s, cz + r0 * s * math.sin(t0))
            a1 = (cx + r0 * s * math.cos(t1), y0 * s, cz + r0 * s * math.sin(t1))
            b0 = (cx + r1 * s * math.cos(t0), y1 * s, cz + r1 * s * math.sin(t0))
            b1 = (cx + r1 * s * math.cos(t1), y1 * s, cz + r1 * s * math.sin(t1))
            o = (math.cos((t0 + t1) / 2), 0.6, math.sin((t0 + t1) / 2))
            yard.quad(mat, a0, a1, b1, b0, o)
        if y0 == 1.0:
            for k in range(8):
                t0, t1 = 2 * math.pi * k / 8, 2 * math.pi * (k + 1) / 8
                yard.tri(mat, (cx, y0 * s, cz), (cx + r0 * s * math.cos(t0), y0 * s, cz + r0 * s * math.sin(t0)),
                         (cx + r0 * s * math.cos(t1), y0 * s, cz + r0 * s * math.sin(t1)), (0, -1, 0))
    yard.tri(mat, (cx, 3.1 * s, cz), (cx, 3.1 * s, cz), (cx, 3.1 * s, cz))


for (cx, cz, s, m) in ((-14.8, -8.5, 1.1, "Leaf"), (-15.2, -2.0, 0.95, "LeafB"), (-14.6, 4.5, 1.15, "Leaf"),
                       (-14.9, 10.5, 1.0, "LeafB"), (15.3, -8.0, 1.05, "LeafB"), (15.0, -1.5, 1.15, "Leaf"),
                       (15.4, 5.0, 0.95, "LeafB"), (15.0, 11.2, 1.1, "Leaf"), (-8.5, 12.2, 1.0, "Leaf"),
                       (-1.0, 12.6, 1.15, "LeafB"), (6.5, 12.3, 1.0, "Leaf")):
    tree(cx, cz, s, m)


def bench(cx, cz, along_x):
    w, d = (2.0, 0.5) if along_x else (0.5, 2.0)
    yard.box("Wood", cx - w / 2, cx + w / 2, 0.42, 0.52, cz - d / 2, cz + d / 2, skip=("bottom",))
    for sx in (-1, 1):
        if along_x:
            yard.box("Metal", cx + sx * (w / 2 - 0.2) - 0.06, cx + sx * (w / 2 - 0.2) + 0.06, 0, 0.42, cz - d / 2 + 0.05,
                     cz + d / 2 - 0.05, skip=("bottom", "top"))
        else:
            yard.box("Metal", cx - w / 2 + 0.05, cx + w / 2 - 0.05, 0, 0.42, cz + sx * (d / 2 - 0.2) - 0.06,
                     cz + sx * (d / 2 - 0.2) + 0.06, skip=("bottom", "top"))


bench(-4.0, 11.0, True)
bench(4.0, 11.0, True)
bench(14.4, 6.5, False)
bench(-14.0, -5.0, False)
# a bin and two planters
yard.box("Metal", 9.6, 10.2, 0, 0.8, 10.6, 11.2, skip=("bottom",))
for (cx, cz) in ((-11.2, 11.6), (11.8, 11.6)):
    yard.box("Wall", cx - 0.6, cx + 0.6, 0, 0.5, cz - 0.6, cz + 0.6, skip=("bottom", "top"))
    yard.box("LeafB", cx - 0.5, cx + 0.5, 0.5, 0.75, cz - 0.5, cz + 0.5, skip=("bottom",))
# lamp posts at the slab's corners
for (cx, cz) in ((-13.4, 9.9), (13.9, 9.9), (-13.4, -9.6), (13.9, -9.6)):
    yard.box("Metal", cx - 0.08, cx + 0.08, 0, 3.4, cz - 0.08, cz + 0.08, skip=("bottom",))
    yard.box("Lamp", cx - 0.22, cx + 0.22, 3.4, 3.65, cz - 0.22, cz + 0.22)
yard.write("yard.glb", COL)

# ---------------------------------------------------------------- dust.glb, spark.glb (pool particles)
dust = Mesh()
t = (1 + math.sqrt(5)) / 2
V = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t), (t, 0, -1),
     (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
F = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6),
     (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10),
     (8, 6, 7), (9, 8, 1)]
R = 0.16 / math.sqrt(1 + t * t)
for a, b, c in F:
    P = [(V[i][0] * R, V[i][1] * R * 0.75 + 0.12, V[i][2] * R) for i in (a, b, c)]
    ctr = np.mean(np.array(P), 0) - np.array([0, 0.12, 0])
    dust.tri("Dust", *P, out=ctr)
dust.write("dust.glb", COL)
spark = Mesh()
S = 0.06
O = [(S, 0, 0), (-S, 0, 0), (0, S, 0), (0, -S, 0), (0, 0, S), (0, 0, -S)]
for a in (0, 1):
    for b in (2, 3):
        for c in (4, 5):
            spark.tri("Spark", O[a], O[b], O[c], out=np.array(O[a]) + O[b] + O[c])
spark.write("spark.glb", COL)
