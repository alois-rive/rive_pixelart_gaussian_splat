#!/usr/bin/env python3
"""The RIVE wordmark as extruded 3D letters on a small plinth, from the brand kit's own path data.

  make_wordmark.py -o wordmark.glb [--kit path/to/brand-kit/scene.rml] [--height 0.96] [--depth 0.35]

The letters (R, I, V, E) come from the rive-branding skill's kit, artboard "Wordmark" (5:12):
each Shape's PointsPath (StraightVertex / CubicDetachedVertex, Beziers flattened) at its Shape
offset. The path data is cached in ../../art/wordmark.paths.json, so the model rebuilds without
the kit. Letters are filled on a fine grid (1 brand unit), front and back faces plus walls,
flat shaded, and shrunk by --shrink metres (a splat reaches about one radius past its face: without
it the baked letters come out fatter than the brand's and the E's gaps close). Material "Mark" (white, flagged fx in
the bake: the shader effects play on it). The plinth, material "Plinth", is a low dark slab.
Facing +Z (the renderer's front), standing on the plinth.
"""
import argparse
import json
import math
import os
import re
import struct

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, "..", "..", "art", "wordmark.paths.json")
KIT = os.path.expanduser("~/.claude/skills/rive-branding/assets/brand-kit/scene.rml")


def read_kit(path):
    s = open(path).read()
    art = s[s.index('id="5:12"'):]
    art = art[:art.index("<StateMachine")]
    node = re.search(r'<Node x="([-\d.]+)" y="([-\d.]+)" name="Art"', art)
    ox, oy = float(node.group(1)), float(node.group(2))
    letters = []
    for m in re.finditer(r'<Shape x="([-\d.]+)" y="([-\d.]+)" name="(\w)"[^>]*>(.*?)</Shape>', art, re.S):
        sx, sy, name, body = float(m.group(1)), float(m.group(2)), m.group(3), m.group(4)
        verts = []
        for v in re.finditer(r"<(StraightVertex|CubicDetachedVertex)([^>]*)/>", body):
            attrs = dict(re.findall(r'(\w+)="([-\d.]+)"', v.group(2)))
            g = lambda k: float(attrs[k]) if k in attrs else None
            verts.append({"kind": v.group(1), "x": g("x") + sx + ox, "y": g("y") + sy + oy,
                          "in": [g("inDistance") or 0.0, g("inRotation") or 0.0] if v.group(1) != "StraightVertex" else None,
                          "out": [g("outDistance") or 0.0, g("outRotation") or 0.0] if v.group(1) != "StraightVertex" else None})
        letters.append({"name": name, "verts": verts})
    return {"source": "rive-branding brand kit, artboard Wordmark 5:12 (460 x 100)", "letters": letters}


def flatten(verts, steps=10):
    pts = []
    n = len(verts)
    for i in range(n):
        a, b = verts[i], verts[(i + 1) % n]
        c1 = (a["x"], a["y"])
        if a["out"] and a["out"][0]:
            c1 = (a["x"] + a["out"][0] * math.cos(a["out"][1]), a["y"] + a["out"][0] * math.sin(a["out"][1]))
        c2 = (b["x"], b["y"])
        if b["in"] and b["in"][0]:
            c2 = (b["x"] + b["in"][0] * math.cos(b["in"][1]), b["y"] + b["in"][0] * math.sin(b["in"][1]))
        curved = c1 != (a["x"], a["y"]) or c2 != (b["x"], b["y"])
        k_n = steps if curved else 1
        for k in range(k_n):
            t = k / k_n
            u = 1 - t
            pts.append((u ** 3 * a["x"] + 3 * u * u * t * c1[0] + 3 * u * t * t * c2[0] + t ** 3 * b["x"],
                        u ** 3 * a["y"] + 3 * u * u * t * c1[1] + 3 * u * t * t * c2[1] + t ** 3 * b["y"]))
    return pts


def inside(poly, x, y):
    c = False
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            c = not c
    return c


class Mesh:
    def __init__(self):
        self.pos, self.nrm, self.idx = [], [], {}

    def quad(self, ps, normal, mat):
        base = len(self.pos)
        self.pos += ps
        self.nrm += [normal] * 4
        self.idx.setdefault(mat, []).extend([base, base + 1, base + 2, base, base + 2, base + 3])

    def box(self, x0, x1, y0, y1, z0, z1, mat, top=None):
        self.quad([(x0, y1, z1), (x1, y1, z1), (x1, y1, z0), (x0, y1, z0)], (0, 1, 0), top or mat)
        self.quad([(x0, y0, z0), (x1, y0, z0), (x1, y0, z1), (x0, y0, z1)], (0, -1, 0), mat)
        self.quad([(x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)], (0, 0, 1), mat)
        self.quad([(x1, y0, z0), (x0, y0, z0), (x0, y1, z0), (x1, y1, z0)], (0, 0, -1), mat)
        self.quad([(x0, y0, z0), (x0, y0, z1), (x0, y1, z1), (x0, y1, z0)], (-1, 0, 0), mat)
        self.quad([(x1, y0, z1), (x1, y0, z0), (x1, y1, z0), (x1, y1, z1)], (1, 0, 0), mat)

    def write(self, out, materials):
        names = [m for m in materials if m[0] in self.idx]
        pb = b"".join(struct.pack("<3f", *p) for p in self.pos)
        nb = b"".join(struct.pack("<3f", *q) for q in self.nrm)
        views = [{"buffer": 0, "byteOffset": 0, "byteLength": len(pb)},
                 {"buffer": 0, "byteOffset": len(pb), "byteLength": len(nb)}]
        acc = [{"bufferView": 0, "componentType": 5126, "count": len(self.pos), "type": "VEC3",
                "min": [min(p[k] for p in self.pos) for k in range(3)],
                "max": [max(p[k] for p in self.pos) for k in range(3)]},
               {"bufferView": 1, "componentType": 5126, "count": len(self.nrm), "type": "VEC3"}]
        binary = pb + nb
        prims, mats = [], []
        for name, colour in names:
            ib = b"".join(struct.pack("<I", k) for k in self.idx[name])
            views.append({"buffer": 0, "byteOffset": len(binary), "byteLength": len(ib)})
            acc.append({"bufferView": len(views) - 1, "componentType": 5125, "count": len(self.idx[name]), "type": "SCALAR"})
            binary += ib
            prims.append({"attributes": {"POSITION": 0, "NORMAL": 1}, "indices": len(acc) - 1, "material": len(mats)})
            mats.append({"name": name, "pbrMetallicRoughness": {"baseColorFactor": colour + [1]}})
        gltf = {"asset": {"version": "2.0", "generator": "make_wordmark.py"}, "scene": 0, "scenes": [{"nodes": [0]}],
                "nodes": [{"name": "Wordmark", "mesh": 0}], "materials": mats,
                "meshes": [{"name": "Wordmark", "primitives": prims}], "buffers": [{"byteLength": len(binary)}],
                "bufferViews": views, "accessors": acc}
        js = json.dumps(gltf).encode()
        js += b" " * ((4 - len(js) % 4) % 4)
        binary += b"\0" * ((4 - len(binary) % 4) % 4)
        with open(out, "wb") as f:
            f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(binary)))
            f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
            f.write(struct.pack("<II", len(binary), 0x004E4942) + binary)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-o", "--out", required=True)
    ap.add_argument("--kit", default=KIT)
    ap.add_argument("--height", type=float, default=0.96, help="letter height in metres (80 brand units)")
    ap.add_argument("--depth", type=float, default=0.35)
    ap.add_argument("--shrink", type=float, default=0.045,
                    help="metres the letters are shrunk by, walls and all: each disc reaches about a radius past "
                         "its face, so a positive shape bakes fatter by that much (about 1.1 x the bake's spacing)")
    ap.add_argument("--erode", type=float, default=0.0,
                    help="metres the faces alone stop short of the outline (for cut-out negative space; 0 here)")
    ap.add_argument("--plinth", type=float, default=0.22, help="plinth height; 0 = none")
    a = ap.parse_args()
    if os.path.exists(a.kit):
        data = read_kit(a.kit)
        json.dump(data, open(CACHE, "w"), indent=1)
    else:
        data = json.load(open(CACHE))
    polys = [flatten(L["verts"]) for L in data["letters"]]
    xs = [p[0] for poly in polys for p in poly]
    ys = [p[1] for poly in polys for p in poly]
    x0, x1, y0, y1 = math.floor(min(xs)), math.ceil(max(xs)), math.floor(min(ys)), math.ceil(max(ys))
    cell = 1.0  # brand units
    nx, ny = int((x1 - x0) / cell), int((y1 - y0) / cell)
    s = a.height / (y1 - y0)
    solid = [[any(inside(poly, x0 + (i + 0.5) * cell, y0 + (j + 0.5) * cell) for poly in polys) for i in range(nx)]
             for j in range(ny)]
    k = max(0, int(round(a.shrink / (cell * s))))
    if k:
        solid = [[solid[j][i] and all(0 <= i + di < nx and 0 <= j + dj < ny and solid[j + dj][i + di]
                                      for di in range(-k, k + 1) for dj in range(-k, k + 1) if di * di + dj * dj <= k * k)
                  for i in range(nx)] for j in range(ny)]
    e = max(0, int(round(a.erode / (cell * s))))
    face = [[solid[j][i] and all(0 <= i + di < nx and 0 <= j + dj < ny and solid[j + dj][i + di]
                                 for di in range(-e, e + 1) for dj in range(-e, e + 1) if di * di + dj * dj <= e * e)
             for i in range(nx)] for j in range(ny)]
    cx = (x0 + x1) / 2
    zf, zb = a.depth / 2, -a.depth / 2
    lift = a.plinth

    def world(u, v):
        return ((u - cx) * s, (y1 - v) * s + lift)

    def filled(i, j):
        return 0 <= i < nx and 0 <= j < ny and solid[j][i]

    m = Mesh()
    for j in range(ny):
        for i in range(nx):
            if not solid[j][i]:
                continue
            u0, v0 = x0 + i * cell, y0 + j * cell
            X0, Y0 = world(u0, v0)
            X1, Y1 = world(u0 + cell, v0 + cell)
            if face[j][i]:
                m.quad([(X0, Y1, zf), (X1, Y1, zf), (X1, Y0, zf), (X0, Y0, zf)], (0, 0, 1), "Mark")
                m.quad([(X1, Y1, zb), (X0, Y1, zb), (X0, Y0, zb), (X1, Y0, zb)], (0, 0, -1), "Mark")
            if not filled(i - 1, j):
                m.quad([(X0, Y1, zb), (X0, Y1, zf), (X0, Y0, zf), (X0, Y0, zb)], (-1, 0, 0), "Mark")
            if not filled(i + 1, j):
                m.quad([(X1, Y1, zf), (X1, Y1, zb), (X1, Y0, zb), (X1, Y0, zf)], (1, 0, 0), "Mark")
            if not filled(i, j - 1):
                m.quad([(X0, Y0, zf), (X1, Y0, zf), (X1, Y0, zb), (X0, Y0, zb)], (0, 1, 0), "Mark")
            if not filled(i, j + 1):
                m.quad([(X0, Y1, zb), (X1, Y1, zb), (X1, Y1, zf), (X0, Y1, zf)], (0, -1, 0), "Mark")
    if a.plinth > 0:
        w = (x1 - x0) * s / 2 + 0.35
        m.box(-w, w, 0.0, a.plinth, -a.depth / 2 - 0.35, a.depth / 2 + 0.35, "Plinth", top="PlinthTop")
    m.write(a.out, [("Mark", [1, 1, 1]), ("PlinthTop", [0.361, 0.361, 0.361]), ("Plinth", [0.078, 0.078, 0.078])])
    print(f"wrote {a.out}: {sum(len(v) for v in m.idx.values()) // 3} triangles, letters {(x1 - x0) * s:.2f} x "
          f"{a.height:.2f} m, {a.depth} m deep, plinth {a.plinth} m")


if __name__ == "__main__":
    main()
