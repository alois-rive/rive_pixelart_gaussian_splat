# A small low-poly mesh writer for Ember Deck's sheet-less models (crypt, foes, effects).
# Flat-shaded triangles grouped by material; each material's colour is an Ink-Crimson hex, written as
# the glTF base colour in linear light so the bake snaps it back to that exact ramp step.
# glTF: Y up, metres, +Z is the model's front (the renderer's yaw 0).
import json
import math
import struct

import numpy as np


def lin(h):
    c = np.array([int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5)])
    return [float(x) for x in np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)] + [1.0]


def ry(d):
    a = math.radians(d); c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def rx(d):
    a = math.radians(d); c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def rz(d):
    a = math.radians(d); c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


class Mesh:
    def __init__(self, name):
        self.name = name
        self.tris = {}
        self.cols = {}

    def mat(self, name, hexcol):
        self.cols[name] = hexcol
        self.tris.setdefault(name, [])
        return name

    def tri(self, m, a, b, c, centre=None, out=None):
        t = np.array([a, b, c], dtype=np.float64)
        n = np.cross(t[1] - t[0], t[2] - t[0])
        if np.linalg.norm(n) < 1e-12:
            return
        ref = None
        if centre is not None:
            ref = t.mean(0) - np.asarray(centre, dtype=np.float64)
        elif out is not None:
            ref = np.asarray(out, dtype=np.float64)
        if ref is not None and np.dot(n, ref) < 0:
            t = t[[0, 2, 1]]
        self.tris[m].append(t)

    def quad(self, m, a, b, c, d, out):
        self.tri(m, a, b, c, out=out)
        self.tri(m, a, c, d, out=out)

    def poly(self, m, pts, out):
        """A convex polygon (fan)."""
        for i in range(1, len(pts) - 1):
            self.tri(m, pts[0], pts[i], pts[i + 1], out=out)

    def box(self, m, c, size, R=None, skip=()):
        hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
        c = np.asarray(c, dtype=np.float64)
        R = np.eye(3) if R is None else R
        F = {"+x": [(hx, -hy, -hz), (hx, hy, -hz), (hx, hy, hz), (hx, -hy, hz)],
             "-x": [(-hx, -hy, -hz), (-hx, -hy, hz), (-hx, hy, hz), (-hx, hy, -hz)],
             "+y": [(-hx, hy, -hz), (-hx, hy, hz), (hx, hy, hz), (hx, hy, -hz)],
             "-y": [(-hx, -hy, -hz), (hx, -hy, -hz), (hx, -hy, hz), (-hx, -hy, hz)],
             "+z": [(-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz)],
             "-z": [(-hx, -hy, -hz), (-hx, hy, -hz), (hx, hy, -hz), (hx, -hy, -hz)]}
        for k, q in F.items():
            if k in skip:
                continue
            p = [c + R @ np.array(v) for v in q]
            self.tri(m, p[0], p[1], p[2], centre=c)
            self.tri(m, p[0], p[2], p[3], centre=c)

    def prism(self, m, base, r0, r1, h, n=8, turn=22.5, R=None, sx=1.0, sz=1.0, caps=(True, True), top_m=None):
        """An n-sided frustum standing on base (radius r0 below, r1 on top), optionally turned by R."""
        R = np.eye(3) if R is None else R
        b = np.asarray(base, dtype=np.float64)
        ring = lambda r, y: [b + R @ np.array([r * sx * math.cos(math.radians(turn + 360 * i / n)), y,
                                               r * sz * math.sin(math.radians(turn + 360 * i / n))]) for i in range(n)]
        lo, hi = ring(r0, 0), ring(r1, h)
        cen = b + R @ np.array([0, h / 2, 0])
        for i in range(n):
            j = (i + 1) % n
            if r1 > 1e-6:
                self.tri(m, lo[i], lo[j], hi[j], centre=cen)
                self.tri(m, lo[i], hi[j], hi[i], centre=cen)
            else:
                self.tri(m, lo[i], lo[j], hi[0], centre=cen)
        if caps[0] and r0 > 1e-6:
            self.poly(m, lo, out=R @ np.array([0, -1.0, 0]))
        if caps[1] and r1 > 1e-6:
            self.poly(top_m or m, hi, out=R @ np.array([0, 1.0, 0]))

    def ico(self, m, c, r, s=(1, 1, 1), R=None, jitter=0.0, rng=None):
        t = (1 + 5 ** 0.5) / 2
        v = np.array([(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
                      (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)], dtype=np.float64)
        v /= np.linalg.norm(v[0])
        if jitter and rng is not None:
            v = v * (1 + rng.uniform(-jitter, jitter, (12, 1)))
        f = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6),
             (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10),
             (8, 6, 7), (9, 8, 1)]
        R = np.eye(3) if R is None else R
        c = np.asarray(c, dtype=np.float64)
        p = [c + R @ (v[i] * np.array(s) * r) for i in range(12)]
        for a, b, d in f:
            self.tri(m, p[a], p[b], p[d], centre=c)

    def octa(self, m, c, r, sy=1.0):
        c = np.asarray(c, dtype=np.float64)
        P = [c + np.array(v) for v in ((r, 0, 0), (-r, 0, 0), (0, r * sy, 0), (0, -r * sy, 0), (0, 0, r), (0, 0, -r))]
        for a in (0, 1):
            for b in (2, 3):
                for d in (4, 5):
                    self.tri(m, P[a], P[b], P[d], centre=c)

    def flame(self, m, base, w, h, n=6, R=None):
        """A teardrop flame: a short widening frustum and a tall cone."""
        b = np.asarray(base, dtype=np.float64)
        R = np.eye(3) if R is None else R
        self.prism(m, b, w * 0.25, w * 0.5, h * 0.3, n=n, R=R, caps=(True, False))
        self.prism(m, b + R @ np.array([0, h * 0.3, 0]), w * 0.5, 0.0, h * 0.7, n=n, R=R, caps=(False, False))

    def write(self, path):
        mats = [m for m in self.tris if self.tris[m]]
        blob = bytearray(); views = []; accs = []; prims = []; materials = []
        for mi, m in enumerate(mats):
            t = np.array(self.tris[m], dtype=np.float32).reshape(-1, 3, 3)
            n = np.cross(t[:, 1] - t[:, 0], t[:, 2] - t[:, 0])
            n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
            pos = t.reshape(-1, 3).astype(np.float32)
            nrm = np.repeat(n, 3, axis=0).astype(np.float32)
            for arr, isPos in ((pos, True), (nrm, False)):
                off = len(blob)
                blob += arr.tobytes()
                while len(blob) % 4:
                    blob += b"\0"
                views.append({"buffer": 0, "byteOffset": off, "byteLength": arr.nbytes, "target": 34962})
                acc = {"bufferView": len(views) - 1, "componentType": 5126, "count": len(arr), "type": "VEC3"}
                if isPos:
                    acc["min"] = [float(x) for x in arr.min(0)]; acc["max"] = [float(x) for x in arr.max(0)]
                accs.append(acc)
            prims.append({"attributes": {"POSITION": len(accs) - 2, "NORMAL": len(accs) - 1}, "material": mi, "mode": 4})
            materials.append({"name": m, "pbrMetallicRoughness": {"baseColorFactor": lin(self.cols[m]),
                                                                    "metallicFactor": 0.0, "roughnessFactor": 1.0}})
        gl = {"asset": {"version": "2.0", "generator": "ember-deck meshkit"}, "scene": 0,
              "scenes": [{"nodes": [0]}], "nodes": [{"mesh": 0, "name": self.name}],
              "meshes": [{"primitives": prims}], "materials": materials, "accessors": accs,
              "bufferViews": views, "buffers": [{"byteLength": len(blob)}]}
        js = json.dumps(gl).encode()
        while len(js) % 4:
            js += b" "
        out = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(blob))
        out += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(blob), 0x004E4942) + bytes(blob)
        open(path, "wb").write(out)
        print(f"wrote {path}: {sum(len(v) for v in self.tris.values())} triangles, {len(mats)} materials")
