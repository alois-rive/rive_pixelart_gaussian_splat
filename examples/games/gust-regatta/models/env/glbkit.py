# A small flat-shaded mesh builder and GLB writer for Gust Regatta's generated models (the bay, its
# islets and props, the game pieces). World units are metres, Y up, +Z towards the camera (south).
# Every triangle belongs to a named material whose colour is an exact mulfok32 hex, written as the glTF
# base colour in linear light so the bake snaps it back to the same palette step.
import json
import math
import struct

import numpy as np


def lin(hexcol):
    c = np.array([int(hexcol[i:i + 2], 16) / 255.0 for i in (1, 3, 5)])
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return [float(v) for v in c] + [1.0]


class Mesh:
    def __init__(self):
        self.tris = {}
        self.cols = {}

    def mat(self, name, hexcol):
        self.cols[name] = hexcol
        self.tris.setdefault(name, [])

    def tri(self, m, a, b, c, out=None):
        """One triangle; `out` (a direction) flips it so its normal points that way."""
        a, b, c = (np.asarray(p, dtype=np.float64) for p in (a, b, c))
        n = np.cross(b - a, c - a)
        if np.linalg.norm(n) < 1e-9:
            return
        if out is not None and np.dot(n, np.asarray(out, dtype=np.float64)) < 0:
            b, c = c, b
        self.tris[m].append((a, b, c))

    def quad(self, m, a, b, c, d, out=None):
        self.tri(m, a, b, c, out)
        self.tri(m, a, c, d, out)

    def solid(self, m, pts, faces, centre=None):
        """A convex solid from points and faces (index lists), wound outwards from its centre."""
        pts = [np.asarray(p, dtype=np.float64) for p in pts]
        ctr = np.mean(pts, axis=0) if centre is None else np.asarray(centre)
        for f in faces:
            fc = np.mean([pts[i] for i in f], axis=0)
            for k in range(1, len(f) - 1):
                self.tri(m, pts[f[0]], pts[f[k]], pts[f[k + 1]], out=fc - ctr)

    def box(self, m, cx, cy, cz, sx, sy, sz, yaw=0.0, skip_bottom=True):
        hx, hy, hz = sx / 2, sy / 2, sz / 2
        c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
        pts = []
        for dy in (-hy, hy):
            for dx, dz in ((-hx, -hz), (hx, -hz), (hx, hz), (-hx, hz)):
                pts.append((cx + dx * c + dz * s, cy + dy, cz - dx * s + dz * c))
        faces = [[4, 5, 6, 7], [0, 1, 5, 4], [1, 2, 6, 5], [2, 3, 7, 6], [3, 0, 4, 7]]
        if not skip_bottom:
            faces.append([0, 1, 2, 3])
        self.solid(m, pts, faces, centre=(cx, cy, cz))

    def frustum(self, m, cx, cy, cz, r0, r1, h, n=8, top=True, rot=0.0, top_mat=None):
        """An n-sided frustum standing on y = cy (r0 at the bottom, r1 at the top); no bottom cap."""
        b, t = [], []
        for i in range(n):
            a = 2 * math.pi * (i + rot) / n
            b.append((cx + r0 * math.cos(a), cy, cz + r0 * math.sin(a)))
            t.append((cx + r1 * math.cos(a), cy + h, cz + r1 * math.sin(a)))
        ctr = (cx, cy + h / 2, cz)
        for i in range(n):
            j = (i + 1) % n
            fc = np.mean([b[i], b[j], t[j], t[i]], axis=0) - np.asarray(ctr)
            fc[1] = 0
            self.quad(m, b[i], b[j], t[j], t[i], out=fc)
        if top and r1 > 1e-4:
            for i in range(n):
                self.tri(top_mat or m, (cx, cy + h, cz), t[i], t[(i + 1) % n], out=(0, 1, 0))

    def cone(self, m, cx, cy, cz, r, h, n=7, rot=0.0):
        apex = (cx, cy + h, cz)
        for i in range(n):
            a0 = 2 * math.pi * (i + rot) / n
            a1 = 2 * math.pi * (i + 1 + rot) / n
            p0 = (cx + r * math.cos(a0), cy, cz + r * math.sin(a0))
            p1 = (cx + r * math.cos(a1), cy, cz + r * math.sin(a1))
            mid = np.mean([p0, p1], axis=0) - np.array([cx, cy, cz])
            self.tri(m, p0, p1, apex, out=(mid[0], r * 0.3, mid[2]))

    def blob(self, m, cx, cy, cz, rx, ry, rz, rng, jitter=0.15, cut=None):
        """A low-poly lump: an octahedron subdivided once and pushed onto an ellipsoid, jittered.
        cut: drop faces whose centre is below this y (buried under the ground)."""
        v = [np.array(p, dtype=np.float64) for p in
             ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))]
        f = [(0, 2, 4), (4, 2, 1), (1, 2, 5), (5, 2, 0), (0, 4, 3), (4, 1, 3), (1, 5, 3), (5, 0, 3)]
        mid = {}

        def mp(i, j):
            k = (min(i, j), max(i, j))
            if k not in mid:
                p = v[i] + v[j]
                v.append(p / np.linalg.norm(p))
                mid[k] = len(v) - 1
            return mid[k]
        f2 = []
        for a, b, c in f:
            ab, bc, ca = mp(a, b), mp(b, c), mp(c, a)
            f2 += [(a, ab, ca), (ab, b, bc), (ca, bc, c), (ab, bc, ca)]
        pts = []
        for p in v:
            s = 1 + jitter * (rng.random() * 2 - 1)
            pts.append(np.array([cx + p[0] * rx * s, cy + p[1] * ry * s, cz + p[2] * rz * s]))
        for a, b, c in f2:
            fc = (pts[a] + pts[b] + pts[c]) / 3
            if cut is not None and fc[1] < cut:
                continue
            self.tri(m, pts[a], pts[b], pts[c], out=fc - np.array([cx, cy, cz]))

    def count(self):
        return sum(len(t) for t in self.tris.values())


def write_glb(path, mesh):
    """Flat-shaded triangles, one primitive per material, one node, no textures."""
    bin_parts, views, accessors, prims, mats = [], [], [], [], []
    offset = 0
    names = [m for m in mesh.tris if mesh.tris[m]]
    for mi, m in enumerate(names):
        tris = mesh.tris[m]
        pos = np.array([p for t in tris for p in t], dtype=np.float32)
        nrm = []
        for a, b, c in tris:
            n = np.cross(b - a, c - a)
            n = n / np.linalg.norm(n)
            nrm += [n, n, n]
        nrm = np.array(nrm, dtype=np.float32)
        for arr, kind in ((pos, "POSITION"), (nrm, "NORMAL")):
            data = arr.tobytes()
            views.append({"buffer": 0, "byteOffset": offset, "byteLength": len(data), "target": 34962})
            acc = {"bufferView": len(views) - 1, "componentType": 5126, "count": len(arr), "type": "VEC3"}
            if kind == "POSITION":
                acc["min"] = [float(x) for x in arr.min(0)]
                acc["max"] = [float(x) for x in arr.max(0)]
            accessors.append(acc)
            bin_parts.append(data)
            offset += len(data)
            pad = (-offset) % 4
            if pad:
                bin_parts.append(b"\0" * pad)
                offset += pad
        prims.append({"attributes": {"POSITION": len(accessors) - 2, "NORMAL": len(accessors) - 1},
                      "material": mi})
        mats.append({"name": m, "pbrMetallicRoughness": {"baseColorFactor": lin(mesh.cols[m]),
                                                         "metallicFactor": 0, "roughnessFactor": 1}})
    blob = b"".join(bin_parts)
    gltf = {"asset": {"version": "2.0", "generator": "gust-regatta glbkit"},
            "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"mesh": 0, "name": "Mesh"}],
            "meshes": [{"primitives": prims}], "materials": mats, "accessors": accessors,
            "bufferViews": views, "buffers": [{"byteLength": len(blob)}]}
    js = json.dumps(gltf).encode()
    js += b" " * ((-len(js)) % 4)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(blob)))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(blob), 0x004E4942) + blob)
