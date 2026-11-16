# Pebble Prix's small low-poly mesh kit and GLB writer (after border-war's): flat-shaded triangles
# grouped by material, each material's colour an exact Zughy 32 hex written as the glTF base colour in
# linear light, so the bake snaps it back exactly. glTF axes: Y up, +Z is a model's front (yaw 0).
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

    def tri(self, mat, a, b, c, out=None, centre=None):
        """one triangle; wound so its normal points along `out`, or away from `centre`"""
        t = np.array([a, b, c], dtype=np.float64)
        n = np.cross(t[1] - t[0], t[2] - t[0])
        if np.linalg.norm(n) < 1e-12:
            return
        ref = None
        if out is not None:
            ref = np.asarray(out, dtype=np.float64)
        elif centre is not None:
            ref = t.mean(0) - np.asarray(centre, dtype=np.float64)
        if ref is not None and np.dot(n, ref) < 0:
            t = t[[0, 2, 1]]
        self.tris.setdefault(mat, []).append(t)

    def quad(self, mat, a, b, c, d, out=None, centre=None):
        self.tri(mat, a, b, c, out, centre)
        self.tri(mat, a, c, d, out, centre)

    def poly(self, mat, pts, out=None, centre=None):
        """a convex polygon, fanned from its centroid"""
        pts = [np.asarray(p, dtype=np.float64) for p in pts]
        m = np.mean(pts, 0)
        for i in range(len(pts)):
            self.tri(mat, m, pts[i], pts[(i + 1) % len(pts)], out, centre)

    def box(self, mat, x0, x1, y0, y1, z0, z1, skip=(), R=None, pivot=(0, 0, 0)):
        """an axis-aligned box; `skip` names faces to leave out: -y +y -x +x -z +z"""
        c = np.array([(x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2])
        v = np.array([[x, y, z] for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)], dtype=np.float64)
        faces = {"-x": [0, 1, 3, 2], "+x": [4, 6, 7, 5], "-y": [0, 4, 5, 1], "+y": [2, 3, 7, 6],
                 "-z": [0, 2, 6, 4], "+z": [1, 5, 7, 3]}
        if R is not None:
            p = np.asarray(pivot, dtype=np.float64)
            v = (v - p) @ R.T + p
            c = (c - p) @ R.T + p
        for k, f in faces.items():
            if k in skip:
                continue
            self.quad(mat, *(v[i] for i in f), centre=c)

    def prism(self, mat, centre, axis, r, length, n=8, cap_mat=None, hub=None, caps=(True, True), rot0=None):
        """an n-sided cylinder along a unit axis; `hub` = (radius, material) drawn on the caps"""
        centre = np.asarray(centre, dtype=np.float64)
        axis = np.asarray(axis, dtype=np.float64)
        axis /= np.linalg.norm(axis)
        u = np.cross(axis, [0, 1, 0]) if abs(axis[1]) < 0.9 else np.cross(axis, [1, 0, 0])
        u /= np.linalg.norm(u)
        w = np.cross(axis, u)
        a0 = math.pi / n if rot0 is None else rot0
        ring = [math.cos(a0 + 2 * math.pi * k / n) * u + math.sin(a0 + 2 * math.pi * k / n) * w for k in range(n)]
        e0 = centre - axis * length / 2
        e1 = centre + axis * length / 2
        for k in range(n):
            a, b = ring[k], ring[(k + 1) % n]
            self.quad(mat, e0 + a * r, e0 + b * r, e1 + b * r, e1 + a * r, centre=centre)
        for end, sgn, on in ((e0, -1, caps[0]), (e1, 1, caps[1])):
            if not on:
                continue
            cm = cap_mat or mat
            if hub:
                hr, hm = hub
                for k in range(n):
                    a, b = ring[k], ring[(k + 1) % n]
                    self.quad(cm, end + a * r, end + b * r, end + b * hr, end + a * hr, out=axis * sgn)
                self.poly(hm, [end + ring[k] * hr for k in range(n)], out=axis * sgn)
            else:
                self.poly(cm, [end + ring[k] * r for k in range(n)], out=axis * sgn)

    def frustum(self, mat, cx, cy, cz, r0, r1, h, n=8, top=True, top_mat=None, rot=0.0):
        """a vertical n-sided frustum from y = cy to cy + h"""
        for k in range(n):
            a = rot + 2 * math.pi * k / n
            b = rot + 2 * math.pi * (k + 1) / n
            p0 = [cx + r0 * math.cos(a), cy, cz + r0 * math.sin(a)]
            p1 = [cx + r0 * math.cos(b), cy, cz + r0 * math.sin(b)]
            p2 = [cx + r1 * math.cos(b), cy + h, cz + r1 * math.sin(b)]
            p3 = [cx + r1 * math.cos(a), cy + h, cz + r1 * math.sin(a)]
            if r1 > 1e-6:
                self.quad(mat, p0, p1, p2, p3, centre=[cx, cy + h * 0.4, cz])
            else:
                self.tri(mat, p0, p1, p2, centre=[cx, cy + h * 0.3, cz])
        if top and r1 > 1e-6:
            self.poly(top_mat or mat, [[cx + r1 * math.cos(rot + 2 * math.pi * k / n), cy + h,
                                        cz + r1 * math.sin(rot + 2 * math.pi * k / n)] for k in range(n)], out=[0, 1, 0])

    def sphere(self, mat_of, centre, r, seg=8, rings=6, sy=1.0):
        """a low-poly UV sphere; mat_of(face centre relative to the sphere centre) -> material"""
        c = np.asarray(centre, dtype=np.float64)
        def p(i, j):
            th = math.pi * i / rings
            ph = 2 * math.pi * j / seg + math.pi / seg
            return c + np.array([r * math.sin(th) * math.cos(ph), r * sy * math.cos(th), r * math.sin(th) * math.sin(ph)])
        for i in range(rings):
            for j in range(seg):
                a, b, cc, d = p(i, j), p(i, j + 1), p(i + 1, j + 1), p(i + 1, j)
                fc = (a + b + cc + d) / 4 - c
                m = mat_of(fc)
                if m is None:
                    continue
                if i == 0:
                    self.tri(m, a, cc, d, centre=c)
                elif i == rings - 1:
                    self.tri(m, a, b, cc, centre=c)
                else:
                    self.quad(m, a, b, cc, d, centre=c)

    def merge(self, other, R=None, offset=(0, 0, 0)):
        for m, lst in other.tris.items():
            self.colors.setdefault(m, other.colors[m])
            for t in lst:
                t2 = t @ R.T if R is not None else t
                self.tris.setdefault(m, []).append(t2 + np.asarray(offset))

    def count(self):
        return sum(len(v) for v in self.tris.values())

    def bounds(self):
        allp = np.concatenate([np.array(v).reshape(-1, 3) for v in self.tris.values() if v])
        return allp.min(0), allp.max(0)

    def write_glb(self, path, name="Model"):
        bin_parts, views, accessors, prims, mats = [], [], [], [], []
        off = 0
        for name_m, lst in self.tris.items():
            if not lst:
                continue
            tris = np.array(lst, dtype=np.float32).reshape(-1, 3)
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
            mats.append({"name": name_m, "pbrMetallicRoughness": {"baseColorFactor": hex_lin(self.colors[name_m]),
                                                                   "metallicFactor": 0.0, "roughnessFactor": 1.0}})
        gl = {"asset": {"version": "2.0", "generator": "pebble-prix meshkit"}, "scene": 0,
              "scenes": [{"nodes": [0]}], "nodes": [{"mesh": 0, "name": name}],
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
