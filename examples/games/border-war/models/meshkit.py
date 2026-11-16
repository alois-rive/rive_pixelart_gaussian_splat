# Border War's small low-poly mesh kit and GLB writer, for the generated (sheet-less) models:
# terrain, units, buildings, props. Flat-shaded triangles grouped by material; a material's colour
# is a Lospec500 hex, written as the glTF base colour in linear light so the bake snaps it back
# exactly. glTF axes: Y up, +Z is the model's front (the renderer's yaw 0).
import json
import math
import struct

import numpy as np


def hex_lin(h):
    c = np.array([int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5)])
    return [float(v) for v in np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)] + [1.0]


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
        """Adds triangles; with `centre` each is wound so its normal points away from it (convex
        solids), with `out` along that direction (flat cards, planes)."""
        lst = self.tris.setdefault(mat, [])
        for t in tris:
            t = np.asarray(t, dtype=np.float64)
            n = np.cross(t[1] - t[0], t[2] - t[0])
            if np.linalg.norm(n) < 1e-12:
                continue
            ref = None
            if centre is not None:
                ref = t.mean(0) - np.asarray(centre, dtype=np.float64)
            elif out is not None:
                ref = np.asarray(out, dtype=np.float64)
            if ref is not None and np.dot(n, ref) < 0:
                t = t[[0, 2, 1]]
            lst.append(t)

    def solid(self, mat, verts, faces, skip_down=True):
        """A convex solid from vertices and polygon faces (index lists); faces pointing straight
        down (resting on the ground) are left out when skip_down."""
        v = np.asarray(verts, dtype=np.float64)
        c = v.mean(0)
        for f in faces:
            p = v[list(f)]
            n = np.cross(p[1] - p[0], p[2] - p[0])
            if np.dot(n, p.mean(0) - c) < 0:
                n = -n
            nn = n / max(np.linalg.norm(n), 1e-12)
            if skip_down and nn[1] < -0.95:
                continue
            for k in range(1, len(f) - 1):
                self.add(mat, [[p[0], p[k], p[k + 1]]], centre=c)

    def box(self, mat, cx, cy, cz, sx, sy, sz, R=None, skip_down=True, pivot=None):
        """A box centred at (cx, cy, cz), sizes along x, y, z, optionally turned by R about pivot
        (default its centre)."""
        hx, hy, hz = sx / 2, sy / 2, sz / 2
        corners = np.array([[x, y, z] for x in (-hx, hx) for y in (-hy, hy) for z in (-hz, hz)])
        c = np.array([cx, cy, cz], dtype=np.float64)
        if R is not None:
            p = c if pivot is None else np.asarray(pivot, dtype=np.float64)
            w = corners + c - p
            w = w @ np.asarray(R).T + p
        else:
            w = corners + c
        faces = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
        self.solid(mat, w, faces, skip_down=skip_down and R is None)

    def prism_roof(self, mat, cx, cy, cz, sx, sz, h, ridge="x", hip=0.0, R=None, gable_mat=None):
        """A gable roof: footprint sx x sz centred at (cx, cy, cz) (its eaves), ridge h above, along
        x or z; hip pulls the ridge ends in. gable_mat paints the triangular ends."""
        if ridge == "x":
            base = [(-sx / 2, 0, -sz / 2), (sx / 2, 0, -sz / 2), (sx / 2, 0, sz / 2), (-sx / 2, 0, sz / 2)]
            top = [(-sx / 2 + hip, h, 0), (sx / 2 - hip, h, 0)]
        else:
            base = [(-sx / 2, 0, -sz / 2), (sx / 2, 0, -sz / 2), (sx / 2, 0, sz / 2), (-sx / 2, 0, sz / 2)]
            top = [(0, h, -sz / 2 + hip), (0, h, sz / 2 - hip)]
        v = np.array(base + top, dtype=np.float64)
        if R is not None:
            v = v @ np.asarray(R).T
        v += np.array([cx, cy, cz])
        c = v.mean(0)
        if ridge == "x":
            slopes = [(0, 1, 5, 4), (3, 2, 5, 4)]
            ends = [(0, 3, 4), (1, 2, 5)]
        else:
            slopes = [(0, 3, 5, 4), (1, 2, 5, 4)]
            ends = [(0, 1, 4), (3, 2, 5)]
        for f in slopes:
            p = v[list(f)]
            self.add(mat, [[p[0], p[1], p[2]], [p[0], p[2], p[3]]], centre=c)
        for f in ends:
            p = v[list(f)]
            self.add(gable_mat or mat, [[p[0], p[1], p[2]]], centre=c)

    def frustum(self, mat, cx, cy, cz, r0, r1, h, n=6, rot=0.0, cap=True, bottom=False, R=None, sx=1.0, sz=1.0):
        """An n-sided frustum (r1 0: a cone / pyramid) standing on (cx, cy, cz)."""
        ring0, ring1 = [], []
        for i in range(n):
            a = math.radians(rot) + 2 * math.pi * i / n
            ring0.append((math.cos(a) * r0 * sx, 0, math.sin(a) * r0 * sz))
            ring1.append((math.cos(a) * r1 * sx, h, math.sin(a) * r1 * sz))
        v = np.array(ring0 + ring1 + [(0, 0, 0), (0, h, 0)], dtype=np.float64)
        if R is not None:
            v = v @ np.asarray(R).T
        v += np.array([cx, cy, cz])
        c = (v[2 * n] + v[2 * n + 1]) / 2
        for i in range(n):
            j = (i + 1) % n
            if r1 > 1e-6:
                self.add(mat, [[v[i], v[j], v[n + j]], [v[i], v[n + j], v[n + i]]], centre=c)
            else:
                self.add(mat, [[v[i], v[j], v[n + i]]], centre=c)
            if cap and r1 > 1e-6:
                self.add(mat, [[v[2 * n + 1], v[n + i], v[n + j]]], centre=c)
            if bottom:
                self.add(mat, [[v[2 * n], v[i], v[j]]], centre=c)

    def blob(self, mat, cx, cy, cz, r, sy=1.0, seed=0, jitter=0.12, sx=1.0, sz=1.0):
        """A faceted lump: an icosahedron, squashed and jittered (foliage, rocks, sacks)."""
        t = (1 + 5 ** 0.5) / 2
        v = np.array([(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
                      (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)], dtype=np.float64)
        v /= np.linalg.norm(v, axis=1, keepdims=True)
        rng = np.random.default_rng(seed)
        v *= (1 + rng.uniform(-jitter, jitter, (12, 1)))
        v *= np.array([r * sx, r * sy, r * sz])
        v += np.array([cx, cy, cz])
        f = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6),
             (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10),
             (8, 6, 7), (9, 8, 1)]
        c = np.array([cx, cy, cz])
        for a, b, d in f:
            tri = np.array([v[a], v[b], v[d]])
            if tri[:, 1].max() < cy - r * sy * 0.6 and cy - r * sy < 0.02:
                continue    # buried underside
            self.add(mat, [tri], centre=c)

    def transformed(self, R=None, offset=(0, 0, 0), scale=1.0):
        """A copy turned, scaled and moved (for placing a part model inside another)."""
        m = Mesh()
        m.colors = dict(self.colors)
        for k, lst in self.tris.items():
            out = []
            for t in lst:
                q = t * scale
                if R is not None:
                    q = q @ np.asarray(R).T
                out.append(q + np.asarray(offset))
            m.tris[k] = out
        return m

    def merge(self, other):
        for k, lst in other.tris.items():
            self.tris.setdefault(k, []).extend(lst)
            self.colors.setdefault(k, other.colors.get(k, "#ffffff"))

    def count(self):
        return sum(len(v) for v in self.tris.values())

    def bounds(self):
        allp = np.concatenate([np.array(v).reshape(-1, 3) for v in self.tris.values() if v])
        return allp.min(0), allp.max(0)

    def write_glb(self, path):
        bin_parts, views, accessors, prims, mats = [], [], [], [], []
        off = 0
        for mi, (name, lst) in enumerate(t for t in self.tris.items() if t[1]):
            tris = np.array(lst, dtype=np.float32).reshape(-1, 3)
            n = len(tris) // 3
            nrm = np.cross(tris[1::3] - tris[0::3], tris[2::3] - tris[0::3])
            nrm /= np.maximum(np.linalg.norm(nrm, axis=1, keepdims=True), 1e-12)
            nrm = np.repeat(nrm, 3, axis=0).astype(np.float32)
            for arr, kind in ((tris, "POSITION"), (nrm, "NORMAL")):
                data = arr.tobytes()
                views.append({"buffer": 0, "byteOffset": off, "byteLength": len(data), "target": 34962})
                acc = {"bufferView": len(views) - 1, "componentType": 5126, "count": len(arr), "type": "VEC3"}
                if kind == "POSITION":
                    acc["min"] = [float(x) for x in arr.min(0)]
                    acc["max"] = [float(x) for x in arr.max(0)]
                accessors.append(acc)
                bin_parts.append(data)
                off += len(data)
            prims.append({"attributes": {"POSITION": len(accessors) - 2, "NORMAL": len(accessors) - 1},
                          "material": len(mats), "mode": 4})
            mats.append({"name": name, "pbrMetallicRoughness": {"baseColorFactor": hex_lin(self.colors[name]),
                                                                 "metallicFactor": 0.0, "roughnessFactor": 1.0}})
        gl = {"asset": {"version": "2.0", "generator": "border-war meshkit"}, "scene": 0,
              "scenes": [{"nodes": [0]}], "nodes": [{"mesh": 0, "name": "Model"}],
              "meshes": [{"primitives": prims}], "materials": mats, "accessors": accessors,
              "bufferViews": views, "buffers": [{"byteLength": off}]}
        js = json.dumps(gl).encode()
        js += b" " * ((4 - len(js) % 4) % 4)
        binb = b"".join(bin_parts)
        binb += b"\0" * ((4 - len(binb) % 4) % 4)
        with open(path, "wb") as f:
            f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(binb)))
            f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
            f.write(struct.pack("<II", len(binb), 0x004E4942) + binb)
