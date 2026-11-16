# A tiny low-poly mesh kit and GLB writer for the generated (sheet-less) models of Tiny Quest.
# Flat-shaded triangles grouped by material; each material's colour is a palette hex (written as the
# glTF base colour in linear light, so the bake snaps it back exactly). Y up, +Z is the model's front.
import json
import math
import struct

import numpy as np


def hex_lin(h):
    c = np.array([int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5)])
    return list(np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)) + [1.0]


def rot_y(deg):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def rot_x(deg):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def rot_z(deg):
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


class Mesh:
    def __init__(self):
        self.tris = {}      # material -> list of (3, 3) arrays
        self.colors = {}    # material -> hex

    def material(self, name, hexcol):
        self.colors[name] = hexcol
        self.tris.setdefault(name, [])

    def add(self, mat, tris, centre=None, out=None):
        """Adds triangles; with `centre`, each is wound so its normal points away from it (convex solids);
        with `out`, so its normal points along that direction (flat cards, planes)."""
        lst = self.tris.setdefault(mat, [])
        for t in tris:
            t = np.asarray(t, dtype=np.float64)
            n = np.cross(t[1] - t[0], t[2] - t[0])
            if np.linalg.norm(n) < 1e-12:
                continue
            ref = None
            if centre is not None:
                ref = t.mean(0) - np.asarray(centre)
            elif out is not None:
                ref = np.asarray(out, dtype=np.float64)
            if ref is not None and np.dot(n, ref) < 0:
                t = t[[0, 2, 1]]
            lst.append(t)

    # ------------------------------------------------------------ primitives (world placed)
    def quad(self, mat, a, b, c, d, out):
        self.add(mat, [[a, b, c], [a, c, d]], out=out)

    def box(self, mat, cx, cy, cz, sx, sy, sz, R=None, skip=()):
        """An axis box (optionally turned by R about its centre). skip: faces to leave out ('-y', '+x', ...)."""
        hx, hy, hz = sx / 2, sy / 2, sz / 2
        c = np.array([cx, cy, cz])
        R = np.eye(3) if R is None else R
        faces = {
            "+x": [(hx, -hy, -hz), (hx, hy, -hz), (hx, hy, hz), (hx, -hy, hz)],
            "-x": [(-hx, -hy, -hz), (-hx, -hy, hz), (-hx, hy, hz), (-hx, hy, -hz)],
            "+y": [(-hx, hy, -hz), (-hx, hy, hz), (hx, hy, hz), (hx, hy, -hz)],
            "-y": [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, -hy, hz), (-hx, -hy, hz)],
            "+z": [(-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz)],
            "-z": [(-hx, -hy, -hz), (-hx, hy, -hz), (hx, hy, -hz), (hx, -hy, -hz)],
        }
        for k, q in faces.items():
            if k in skip:
                continue
            p = [c + R @ np.array(v) for v in q]
            self.add(mat, [[p[0], p[1], p[2]], [p[0], p[2], p[3]]], centre=c)

    def frustum(self, mat, cx, y0, cz, r0, r1, h, n=8, turn=22.5, caps=(True, True), R=None, sx=1.0, sz=1.0):
        """An n-sided prism / frustum standing on y0 (radius r0 at the bottom, r1 at the top)."""
        R = np.eye(3) if R is None else R
        base = np.array([cx, y0, cz])
        def ring(r, y):
            return [base + R @ np.array([r * sx * math.cos(math.radians(turn + 360 * i / n)), y,
                                         r * sz * math.sin(math.radians(turn + 360 * i / n))]) for i in range(n)]
        lo, hi = ring(r0, 0), ring(r1, h)
        centre = base + R @ np.array([0, h / 2, 0])
        for i in range(n):
            j = (i + 1) % n
            if r1 > 1e-6:
                self.add(mat, [[lo[i], lo[j], hi[j]], [lo[i], hi[j], hi[i]]], centre=centre)
            else:
                self.add(mat, [[lo[i], lo[j], hi[0]]], centre=centre)
        top = base + R @ np.array([0, h, 0])
        if caps[0]:
            for i in range(n):
                self.add(mat, [[base, lo[i], lo[(i + 1) % n]]], out=R @ np.array([0, -1, 0]))
        if caps[1] and r1 > 1e-6:
            for i in range(n):
                self.add(mat, [[top, hi[i], hi[(i + 1) % n]]], out=R @ np.array([0, 1, 0]))

    def ico(self, mat, cx, cy, cz, r, sy=1.0, jitter=0.0, rng=None, R=None, sx=1.0, sz=1.0, cut=None):
        """A 20-face icosahedron (scaled per axis, optionally jittered); cut: drop faces wholly below y = cut."""
        t = (1 + 5 ** 0.5) / 2
        v = np.array([(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
                      (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)], dtype=np.float64)
        v /= np.linalg.norm(v[0])
        f = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6),
             (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10),
             (8, 6, 7), (9, 8, 1)]
        if jitter and rng is not None:
            v = v * (1 + rng.uniform(-jitter, jitter, (len(v), 1)))
        R = np.eye(3) if R is None else R
        c = np.array([cx, cy, cz])
        p = np.array([c + R @ (np.array([x * sx, y * sy, z * sz]) * r) for x, y, z in v])
        tris = [[p[a], p[b], p[cc]] for a, b, cc in f]
        if cut is not None:
            tris = [t for t in tris if max(q[1] for q in t) > cut]
        self.add(mat, tris, centre=c)

    def write(self, path):
        """Writes a GLB: one mesh, one primitive per material, flat normals, no indices."""
        mats = [m for m in self.tris if self.tris[m]]
        blob = bytearray()
        views, accs, prims, materials = [], [], [], []
        for mi, m in enumerate(mats):
            t = np.array(self.tris[m], dtype=np.float32).reshape(-1, 3, 3)
            n = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0])
            n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
            pos = t.reshape(-1, 3)
            nrm = np.repeat(n, 3, axis=0).astype(np.float32)
            for arr, kind in ((pos, "pos"), (nrm, "nrm")):
                off = len(blob)
                blob += arr.astype(np.float32).tobytes()
                while len(blob) % 4:
                    blob += b"\0"
                views.append({"buffer": 0, "byteOffset": off, "byteLength": arr.nbytes, "target": 34962})
                acc = {"bufferView": len(views) - 1, "componentType": 5126, "count": len(arr), "type": "VEC3"}
                if kind == "pos":
                    acc["min"] = [float(x) for x in arr.min(0)]
                    acc["max"] = [float(x) for x in arr.max(0)]
                accs.append(acc)
            prims.append({"attributes": {"POSITION": len(accs) - 2, "NORMAL": len(accs) - 1}, "material": mi, "mode": 4})
            materials.append({"name": m, "pbrMetallicRoughness": {"baseColorFactor": hex_lin(self.colors[m]),
                                                                    "metallicFactor": 0.0, "roughnessFactor": 1.0}})
        gl = {"asset": {"version": "2.0", "generator": "tiny-quest meshkit"}, "scene": 0,
              "scenes": [{"nodes": [0]}], "nodes": [{"mesh": 0, "name": path.split("/")[-1].split(".")[0]}],
              "meshes": [{"primitives": prims}], "materials": materials, "accessors": accs, "bufferViews": views,
              "buffers": [{"byteLength": len(blob)}]}
        js = json.dumps(gl).encode()
        while len(js) % 4:
            js += b" "
        out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(blob))
        out += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(blob), 0x004E4942) + bytes(blob)
        open(path, "wb").write(out)
        ntri = sum(len(v) for v in self.tris.values())
        print(f"wrote {path}: {ntri} triangles, {len(mats)} materials")
