#!/usr/bin/env python3
"""Bake low-poly GLB models into a pixel-splat blob for the Rive renderer.

  splat_bake.py scene.bake.json                 a scene: several models, transforms, material ramps
  splat_bake.py model.glb -p palette.json -o splats.bin [--spacing 0.06] [--ramp Mat=ramp ...]

Every surface is sampled with blue-noise (Poisson-disk) points `spacing` apart; each point
becomes one splat: a flat gaussian disc lying in the surface, its colour snapped to a
palette ramp step. Lighting is NOT baked: the renderer shifts each splat along its ramp
from the sun, so the same blob works at any time of day.

The bake file (JSON):

  {
    "palette": "../palette.json",          every path here (palette, out, model) is relative to the bake file
    "spacing": 0.06,                       world units between splats (~1.5 art pixels, see SKILL.md)
    "fat": 1.0,                            disc sigma across the surface, in spacings (under ~0.9 opens holes)
    "seed": 1,
    "out": "../scene/splats.bin",
    "objects": [
      { "model": "../models/tree/tree.glb",
        "position": [0, 0, 0], "yaw": 30, "scale": 1,
        "materials": { "Leaves": { "ramp": "foliage", "flags": ["double", "sway"] },
                       "Trunk":  { "ramp": "bark", "step": -1 } } }
    ]
  }

Animation (any object whose GLB carries animations; export from hedra with
`export x.glb --bake-animations` so every channel is sampled per frame):

      { "model": "../models/mill/mill.glb", "fps": 12, "loop": 4.0, "phase": 0.5, "speed": 1,
        "animations": ["SailsAction"] }

  fps       frames a second the animation is sampled at and played back, stepped: 8 to 12 reads as
            pixel art (default 12; 24 to 30 for smooth motion)
  loop      seconds before the track repeats (default: the longest selected animation). Every
            animation loops on its own length inside it, so give a common multiple (a 1.2 s walk and
            a 14.4 s orbit: 14.4) or the shorter one restarts mid-cycle at the track's seam
  animate   false: no tracks for this object, it is baked in its rest pose
  phase     seconds of offset, so copies of one model do not move in step
  speed     playback rate
  animations  names of the glTF animations to play together (default all of them)
  bone      "<name>": the whole object becomes ONE bone a game script moves (game.as, api.place);
            its splats are baked where this entry puts it (its rest pose); not animated
  copies    with "bone": n copies of the object (a pool: coins, enemies, bullets), bones
            "<name>0" .. "<name>{n-1}", all at this entry's place until the game moves them

Top level: "bounds": [[x0, y0, z0], [x1, y1, z1]] replaces the computed bounds (the default
framing, the shadow map's reach): a game's play area, which moving objects stay inside.

A mesh node that an animation moves (itself or a parent) becomes a rigid part: one bone. A skinned
mesh keeps its skin: up to 4 bones a splat, weights blended from its triangle's corners. Up to 63
animated bones per blob in all (bone 0 is the static world).

Sampling uses ONE random stream ("seed") through the objects in order: changing one object (its
mesh, its spacing) re-samples every object after it, so expect golden diffs past the changed one.

Material options: ramp (name; texel colours are snapped to its steps), step (shift every
splat of it up or down its ramp), flags: unlit (emissive: ignores the sun), double
(two-sided: leaves, cloth, flat cards), sway (moves with the wind), nocast (casts no shadow),
spacing (override for this material: denser for small detail, sparser for big walls),
specks (true: its parts are particles, tiny on purpose: no "specks" warning), and the flag fx
(the renderer's shader FX cycle plays on these splats: a logo, a title).

Without "ramp" a material's colour picks the nearest colour that belongs to any ramp.

Blob layout (little endian; the bake assembles this v2 layout and writes it as v3, 16 bytes a
splat: see upgrade_blob; `splat_bake.py --upgrade <bin>...` converts older blobs in place):
  0   'SPLT' u32 version u32 count u32 stride u32
  16  bounds min f32x3, max f32x3 (over the animation), spacing f32, palette count u32, ramp count u32
  52  roles u8 x4 (sky_top, sky_bottom, fog, void; 255 = unset)
  64  palette 64 x rgba8
  320 ramps 32 x 8 palette indices (u8)
  576 ramp lengths 32 x u8
  56  bone count u32 (bone 0 = identity), track count u32
  608 track table offset u32
  612 bone name table offset u32 (0: none), named bone count u32 (616)
  then (after the track frames) the name table: per named bone u8 bone index, u8 name length,
      the name (ascii), rest position f32x3, rest yaw f32 (degrees)
  640 splats, 32 bytes each: position f32x3 | normal snorm8x4 | ramp u8, step u8, flags u8, 0 | sigma f32
      | joints u8x4 | weights unorm8x4
  then the track table, 32 bytes a track: first bone u32, bone count u32, frames u32, fps f32,
      phase f32, data offset u32, speed f32, 0
  then each track's frames: frames x bones x 3 rows of vec4 (a 3x4 matrix, row-major), f32
"""
import argparse
import io
import json
import math
import os
import struct
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from splatlib import MAX_COLORS, MAX_RAMPS, MAX_STEPS, Palette  # noqa: E402

FLAG_BITS = {"unlit": 1, "double": 2, "sway": 4, "nocast": 8, "fx": 16}
HEADER = 640      # the v2 layout the bake assembles; written out as v3 by upgrade_blob
STRIDE = 32
HEADER3 = 672     # v3: the v2 header + a 32-byte dequantization block
STRIDE3 = 16
MAX_BONES = 64

# ---------------------------------------------------------------- glTF


COMP = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


class GLB:
    def __init__(self, path):
        self.path = path
        data = open(path, "rb").read()
        if path.lower().endswith(".gltf"):
            self.json = json.loads(data)
            self.bin = None
        else:
            magic, _, length = struct.unpack_from("<III", data, 0)
            if magic != 0x46546C67:
                raise SystemExit(f"{path}: not a GLB")
            off = 12
            self.bin = b""
            while off < length:
                clen, ctype = struct.unpack_from("<II", data, off)
                chunk = data[off + 8: off + 8 + clen]
                if ctype == 0x4E4F534A:
                    self.json = json.loads(chunk)
                elif ctype == 0x004E4942:
                    self.bin = chunk
                off += 8 + clen
        self._images = {}
        self._samplers = {}

    def buffer(self, i):
        b = self.json["buffers"][i]
        if "uri" not in b:
            return self.bin
        return open(os.path.join(os.path.dirname(self.path), b["uri"]), "rb").read()

    def view_bytes(self, vi):
        v = self.json["bufferViews"][vi]
        buf = self.buffer(v["buffer"])
        off = v.get("byteOffset", 0)
        return buf[off: off + v["byteLength"]], v.get("byteStride")

    def accessor(self, ai):
        a = self.json["accessors"][ai]
        dt = np.dtype(COMP[a["componentType"]])
        n = NCOMP[a["type"]]
        count = a["count"]
        if "bufferView" not in a:
            return np.zeros((count, n), dtype=np.float32)
        raw, stride = self.view_bytes(a["bufferView"])
        off = a.get("byteOffset", 0)
        elem = dt.itemsize * n
        if stride and stride != elem:
            rows = [np.frombuffer(raw, dtype=dt, count=n, offset=off + i * stride) for i in range(count)]
            arr = np.stack(rows)
        else:
            arr = np.frombuffer(raw, dtype=dt, count=count * n, offset=off).reshape(count, n)
        arr = arr.astype(np.float64)
        if a.get("normalized"):
            arr = arr / float(np.iinfo(dt).max)
        return arr

    def image(self, ti):
        tex = self.json["textures"][ti]
        si = tex.get("source")
        if si in self._images:
            return self._images[si]
        im = self.json["images"][si]
        if "bufferView" in im:
            raw, _ = self.view_bytes(im["bufferView"])
            img = Image.open(io.BytesIO(raw))
        else:
            img = Image.open(os.path.join(os.path.dirname(self.path), im["uri"]))
        arr = np.asarray(img.convert("RGBA"), dtype=np.float64)
        self._images[si] = arr
        return arr

    def local_matrix(self, i, over=None):
        n = self.json["nodes"][i]
        o = (over or {}).get(i, {})
        if "matrix" in n and not o:
            return np.array(n["matrix"], dtype=np.float64).reshape(4, 4).T
        t = o.get("translation", n.get("translation", [0, 0, 0]))
        x, y, z, w = o.get("rotation", n.get("rotation", [0, 0, 0, 1]))
        sc = o.get("scale", n.get("scale", [1, 1, 1]))
        r = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                      [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                      [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
        m = np.eye(4)
        m[:3, :3] = r * np.array(sc)[None, :]
        m[:3, 3] = t
        return m

    def world_matrices(self, over=None):
        """World matrix of every node, with animated TRS values in `over` ({node: {path: value}})."""
        nodes = self.json.get("nodes", [])
        scene = self.json.get("scenes", [{}])[self.json.get("scene", 0)]
        out = [np.eye(4) for _ in nodes]

        def walk(i, parent):
            out[i] = parent @ self.local_matrix(i, over)
            for c in nodes[i].get("children", []):
                walk(c, out[i])

        for root in scene.get("nodes", range(len(nodes))):
            walk(root, np.eye(4))
        return out

    def mesh_nodes(self):
        """(node, mesh, skin or None) for every node with a mesh in the scene."""
        nodes = self.json.get("nodes", [])
        scene = self.json.get("scenes", [{}])[self.json.get("scene", 0)]
        out = []

        def walk(i):
            n = nodes[i]
            if "mesh" in n:
                out.append((i, n["mesh"], n.get("skin")))
            for c in n.get("children", []):
                walk(c)

        for root in scene.get("nodes", range(len(nodes))):
            walk(root)
        return out

    def animations(self, names=None):
        anims = self.json.get("animations", [])
        return [a for a in anims if names is None or a.get("name") in names]

    def duration(self, anims):
        d = 0.0
        for a in anims:
            for smp in a["samplers"]:
                d = max(d, float(self.accessor(smp["input"]).max()))
        return d

    def evaluate(self, anims, t):
        """{node: {path: value}} of the animations at time t (LINEAR, STEP and CUBICSPLINE).
        Each animation loops on its OWN length, so a 1.2 s walk inside a 14.4 s orbit keeps walking."""
        over = {}
        for a in anims:
            da = self.duration([a])
            ta = (t % da) if da > 0 else 0.0
            for ch in a["channels"]:
                tgt = ch["target"]
                path = tgt.get("path")
                if path not in ("translation", "rotation", "scale") or "node" not in tgt:
                    continue
                smp = a["samplers"][ch["sampler"]]
                key = (id(a), ch["sampler"])
                if key not in self._samplers:
                    times = self.accessor(smp["input"])[:, 0]
                    vals = self.accessor(smp["output"])
                    self._samplers[key] = (times, vals)
                times, vals = self._samplers[key]
                mode = smp.get("interpolation", "LINEAR")
                if mode == "CUBICSPLINE":
                    vin, v, vout = vals[0::3], vals[1::3], vals[2::3]
                else:
                    vin = v = vout = vals
                tt = min(max(ta, times[0]), times[-1])
                k = int(np.searchsorted(times, tt, side="right") - 1)
                k = min(max(k, 0), len(times) - 1)
                if k == len(times) - 1 or mode == "STEP":
                    val = v[k].copy()
                else:
                    dt = times[k + 1] - times[k]
                    u = (tt - times[k]) / dt if dt > 0 else 0.0
                    if mode == "CUBICSPLINE":
                        u2, u3 = u * u, u * u * u
                        val = ((2 * u3 - 3 * u2 + 1) * v[k] + (u3 - 2 * u2 + u) * dt * vout[k]
                               + (-2 * u3 + 3 * u2) * v[k + 1] + (u3 - u2) * dt * vin[k + 1])
                    elif path == "rotation":
                        q0, q1 = v[k], v[k + 1].copy()
                        if np.dot(q0, q1) < 0:
                            q1 = -q1
                        val = q0 * (1 - u) + q1 * u  # nlerp: fine at per-frame key spacing
                    else:
                        val = v[k] * (1 - u) + v[k + 1] * u
                if path == "rotation":
                    val = val / max(np.linalg.norm(val), 1e-12)
                over.setdefault(tgt["node"], {})[path] = list(val)
        return over

    def world_meshes(self):
        """(mesh index, 4x4 world matrix) for every node with a mesh."""
        nodes = self.json.get("nodes", [])
        scene = self.json.get("scenes", [{}])[self.json.get("scene", 0)]
        out = []

        def local(n):
            if "matrix" in n:
                return np.array(n["matrix"], dtype=np.float64).reshape(4, 4).T
            t = n.get("translation", [0, 0, 0])
            x, y, z, w = n.get("rotation", [0, 0, 0, 1])
            s = n.get("scale", [1, 1, 1])
            r = np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                          [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                          [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])
            m = np.eye(4)
            m[:3, :3] = r * np.array(s)[None, :]
            m[:3, 3] = t
            return m

        def walk(i, parent):
            n = nodes[i]
            m = parent @ local(n)
            if "mesh" in n:
                out.append((n["mesh"], m))
            for c in n.get("children", []):
                walk(c, m)

        for root in scene.get("nodes", range(len(nodes))):
            walk(root, np.eye(4))
        return out


# ---------------------------------------------------------------- sampling


def srgb_to_lin(c):
    c = c / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def lin_to_srgb(c):
    c = np.clip(c, 0, 1)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055) * 255.0


def poisson_thin(points, dmin, rng):
    """Greedy dart throwing over candidate points: keep a point when none kept is closer than dmin."""
    order = rng.permutation(len(points))
    cell = dmin
    grid = {}
    keep = []
    d2 = dmin * dmin
    keys = np.floor(points / cell).astype(np.int64)
    for i in order:
        kx, ky, kz = keys[i]
        p = points[i]
        ok = True
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for dz in (-1, 0, 1):
                    for j in grid.get((kx + dx, ky + dy, kz + dz), ()):
                        q = points[j]
                        if (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2 < d2:
                            ok = False
                            break
                    if not ok:
                        break
                if not ok:
                    break
            if not ok:
                break
        if ok:
            grid.setdefault((kx, ky, kz), []).append(i)
            keep.append(i)
    return np.array(sorted(keep), dtype=np.int64)


def sample_primitive(glb, prim, world, spacing, rng, oversample=4.0):
    attrs = prim["attributes"]
    pos = glb.accessor(attrs["POSITION"])[:, :3]
    nrm = glb.accessor(attrs["NORMAL"])[:, :3] if "NORMAL" in attrs else None
    uv = glb.accessor(attrs["TEXCOORD_0"])[:, :2] if "TEXCOORD_0" in attrs else None
    idx = glb.accessor(prim["indices"])[:, 0].astype(np.int64) if "indices" in prim else np.arange(len(pos))
    if prim.get("mode", 4) != 4:
        return None
    tri = idx.reshape(-1, 3)
    pw = np.einsum("ij,nj->ni", world[:3, :3], pos) + world[:3, 3]  # (einsum: BLAS matmul raises spurious FP warnings on macOS)
    nmat = np.linalg.inv(world[:3, :3]).T
    a, b, c = pw[tri[:, 0]], pw[tri[:, 1]], pw[tri[:, 2]]
    cross = np.cross(b - a, c - a)
    area = 0.5 * np.linalg.norm(cross, axis=1)
    face_n = cross / np.maximum(2 * area[:, None], 1e-12)
    dmin = spacing * 0.8
    density = oversample / (dmin * dmin)
    counts = np.floor(area * density + rng.random(len(area))).astype(np.int64)
    total = counts.sum()
    if total == 0:
        return None
    t = np.repeat(np.arange(len(tri)), counts)
    r1 = np.sqrt(rng.random(total))
    r2 = rng.random(total)
    w0, w1, w2 = 1 - r1, r1 * (1 - r2), r1 * r2
    p = a[t] * w0[:, None] + b[t] * w1[:, None] + c[t] * w2[:, None]
    keep = poisson_thin(p, dmin, rng)
    t, w0, w1, w2, p = t[keep], w0[keep], w1[keep], w2[keep], p[keep]
    if nrm is not None:
        nw = np.einsum("ij,nj->ni", nmat, nrm)
        n = nw[tri[t, 0]] * w0[:, None] + nw[tri[t, 1]] * w1[:, None] + nw[tri[t, 2]] * w2[:, None]
        n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
        # a vertex normal far from its face (a smooth normal across a hard corner) is replaced by the face's
        bad = (n * face_n[t]).sum(1) < 0.2
        n[bad] = face_n[t][bad]
    else:
        n = face_n[t]
    st = None
    if uv is not None:
        st = uv[tri[t, 0]] * w0[:, None] + uv[tri[t, 1]] * w1[:, None] + uv[tri[t, 2]] * w2[:, None]
    corners = tri[t]                                  # the triangle's vertex ids, for skin weights
    bary = np.stack([w0, w1, w2], 1)
    return p, n, st, corners, bary


def material_color(glb, mat, st, count):
    """sRGB 0..255 colour and alpha 0..1 of each sample."""
    pbr = (mat or {}).get("pbrMetallicRoughness", {})
    factor = np.array(pbr.get("baseColorFactor", [1, 1, 1, 1]), dtype=np.float64)
    lin = np.tile(factor[:3], (count, 1))
    alpha = np.full(count, factor[3])
    tex = pbr.get("baseColorTexture")
    if tex is not None and st is not None:
        img = glb.image(tex["index"])
        h, w = img.shape[:2]
        x = np.floor((st[:, 0] % 1.0) * w).astype(np.int64) % w
        y = np.floor((st[:, 1] % 1.0) * h).astype(np.int64) % h
        texel = img[y, x]
        lin = lin * srgb_to_lin(texel[:, :3])
        alpha = alpha * texel[:, 3] / 255.0
    return lin_to_srgb(lin), alpha


# ---------------------------------------------------------------- bake


def skin_weights(glb, prim, corners, bary, joint_base):
    """Per splat: the 4 strongest joints (global bone ids) and their weights, blended from the corners."""
    attrs = prim["attributes"]
    J = glb.accessor(attrs["JOINTS_0"]).astype(np.int64)
    W = glb.accessor(attrs["WEIGHTS_0"])
    n = len(corners)
    joints = np.zeros((n, 4), dtype=np.int64)
    weights = np.zeros((n, 4))
    for i in range(n):
        acc = {}
        for c in range(3):
            v = corners[i, c]
            for k in range(4):
                if W[v, k] > 0:
                    acc[J[v, k]] = acc.get(J[v, k], 0.0) + bary[i, c] * W[v, k]
        top = sorted(acc.items(), key=lambda kv: -kv[1])[:4]
        tot = sum(w for _, w in top) or 1.0
        for k, (j, w) in enumerate(top):
            joints[i, k] = joint_base + j
            weights[i, k] = w / tot
    return joints, weights


def rows(m):
    return m[:3, :].astype(np.float32)  # 3 x 4, row-major


def bake(objects, pal, spacing, fat, seed, base_dir):
    rng = np.random.default_rng(seed)
    ramp_colors = sorted({i for steps in pal.ramps for i in steps})
    all_p, all_n, all_info, all_sigma, all_j, all_w = [], [], [], [], [], []
    report = {}
    tracks = []      # dicts: first, count, frames, fps, phase, speed, data (frames x count x 3 x 4)
    next_bone = 1    # bone 0: the static world
    named = []       # game bones: (index, name, position, yaw degrees)
    expanded = []
    for obj in objects:
        if "bone" in obj and int(obj.get("copies", 1)) > 1:
            for c in range(int(obj["copies"])):
                expanded.append({**obj, "bone": f"{obj['bone']}{c}", "copies": 1})
        else:
            expanded.append(obj)
    for obj in expanded:
        path = os.path.join(base_dir, obj["model"])
        glb = GLB(path)
        yaw = math.radians(obj.get("yaw", 0.0))
        s = obj.get("scale", 1.0)
        place = np.eye(4)
        cy, sy = math.cos(yaw), math.sin(yaw)
        place[:3, :3] = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]) * s
        place[:3, 3] = obj.get("position", [0, 0, 0])
        mats_cfg = obj.get("materials", {})
        game_bone = None
        if "bone" in obj:
            if next_bone + 1 > MAX_BONES:
                raise SystemExit(f"{obj['bone']}: past {MAX_BONES - 1} bones (game bones and animated parts "
                                 "together): smaller pools, or split the scene into blobs")
            game_bone = next_bone
            next_bone += 1
            named.append((game_bone, str(obj["bone"]), [float(v) for v in obj.get("position", [0, 0, 0])],
                          float(obj.get("yaw", 0.0))))
        anims = glb.animations(obj.get("animations")) if obj.get("animate", True) and game_bone is None else []
        W0 = glb.world_matrices(glb.evaluate(anims, 0.0))
        # which nodes move: those a channel targets, and everything under them
        moving = set()
        for a in anims:
            for ch in a["channels"]:
                if "node" in ch["target"]:
                    moving.add(ch["target"]["node"])
        nodes = glb.json.get("nodes", [])
        changed = True
        while changed:
            changed = False
            for i, n in enumerate(nodes):
                if i in moving:
                    for c in n.get("children", []):
                        if c not in moving:
                            moving.add(c)
                            changed = True
        # bones of this instance: ("rigid", node) or ("joint", node, inverse bind)
        bones = []
        skin_base = {}
        for node_i, mesh_i, skin_i in glb.mesh_nodes():
            if skin_i is not None and anims:
                if skin_i not in skin_base:
                    skin = glb.json["skins"][skin_i]
                    ibm = glb.accessor(skin["inverseBindMatrices"]).reshape(-1, 4, 4).transpose(0, 2, 1) \
                        if "inverseBindMatrices" in skin else np.tile(np.eye(4), (len(skin["joints"]), 1, 1))
                    skin_base[skin_i] = len(bones)
                    for j, jn in enumerate(skin["joints"]):
                        bones.append(("joint", jn, ibm[j]))
            elif node_i in moving:
                bones.append(("rigid", node_i, None))
        if next_bone + len(bones) > MAX_BONES:
            raise SystemExit(f"{obj['model']}: {next_bone - 1 + len(bones)} animated bones, the renderer takes "
                             f"{MAX_BONES - 1}: fewer parts, fewer joints, or split the scene into blobs")
        first = next_bone
        bone_of = {}
        if bones:
            for k, b in enumerate(bones):
                if b[0] == "rigid":
                    bone_of[b[1]] = first + k
            duration = glb.duration(anims)
            fps = float(obj.get("fps", 12))
            # each animation loops on its own length inside the track; the track's default
            # length is the longest one (set "loop" to a common multiple of them all)
            loop = float(obj.get("loop", duration if duration > 0 else 1.0))
            frames = max(1, int(round(loop * fps)))
            data = np.zeros((frames, len(bones), 3, 4), dtype=np.float32)
            for f in range(frames):
                Wt = glb.world_matrices(glb.evaluate(anims, f / fps))
                for k, b in enumerate(bones):
                    if b[0] == "rigid":
                        data[f, k] = rows(place @ Wt[b[1]] @ np.linalg.inv(place @ W0[b[1]]))
                    else:
                        data[f, k] = rows(place @ Wt[b[1]] @ b[2])
            tracks.append({"first": first, "count": len(bones), "frames": frames, "fps": fps,
                           "phase": float(obj.get("phase", 0.0)), "speed": float(obj.get("speed", 1.0)),
                           "data": data, "name": os.path.basename(path)})
            next_bone += len(bones)
        for node_i, mesh_i, skin_i in glb.mesh_nodes():
            mesh = glb.json["meshes"][mesh_i]
            skinned = skin_i is not None and skin_i in skin_base
            for prim in mesh["primitives"]:
                mat = glb.json["materials"][prim["material"]] if "material" in prim else None
                mname = (mat or {}).get("name", "default")
                cfg = mats_cfg.get(mname, mats_cfg.get("*", {}))
                sp = cfg.get("spacing", spacing)
                if skinned:
                    # bind space: the skin's matrices carry it to the world (glTF ignores the node's own)
                    got = sample_primitive(glb, prim, np.eye(4), sp / s, rng)
                else:
                    got = sample_primitive(glb, prim, place @ W0[node_i], sp, rng)
                if got is None:
                    continue
                p, n, st, corners, bary = got
                rgb, alpha = material_color(glb, mat, st, len(p))
                keep = np.ones(len(p), dtype=bool)
                if (mat or {}).get("alphaMode", "OPAQUE") != "OPAQUE":
                    keep = alpha >= (mat or {}).get("alphaCutoff", 0.5)
                p, n, rgb, corners, bary = p[keep], n[keep], rgb[keep], corners[keep], bary[keep]
                if len(p) == 0:
                    continue
                if skinned:
                    joints, weights = skin_weights(glb, prim, corners, bary, first + skin_base[skin_i])
                else:
                    joints = np.zeros((len(p), 4), dtype=np.int64)
                    weights = np.zeros((len(p), 4))
                    weights[:, 0] = 1.0
                    joints[:, 0] = game_bone if game_bone is not None else bone_of.get(node_i, 0)
                if "ramp" in cfg:
                    r = pal.ramp_index(cfg["ramp"])
                    steps = pal.ramps[r]
                    k, err = pal.nearest(rgb, steps)
                    step = np.array([steps.index(int(i)) for i in k])
                    ramp = np.full(len(p), r)
                else:
                    k, err = pal.nearest(rgb, ramp_colors)
                    rs = [pal.ramp_of(int(i)) for i in k]
                    ramp = np.array([x[0] for x in rs])
                    step = np.array([x[1] for x in rs])
                if "step" in cfg:
                    lens = np.array([len(pal.ramps[int(x)]) for x in ramp])
                    step = np.clip(step + int(cfg["step"]), 0, lens - 1)
                flags = 0
                for f in cfg.get("flags", []):
                    flags |= FLAG_BITS[f]
                if (mat or {}).get("doubleSided"):
                    flags |= FLAG_BITS["double"]
                emis = (mat or {}).get("emissiveFactor", [0, 0, 0])
                if max(emis) > 0.01:
                    flags |= FLAG_BITS["unlit"]
                info = np.stack([ramp, step, np.full(len(p), flags), np.zeros(len(p))], 1)
                all_p.append(p)
                all_n.append(n)
                all_info.append(info)
                all_sigma.append(np.full(len(p), sp * fat))
                all_j.append(joints)
                all_w.append(weights)
                used = sorted({pal.ramp_names[int(x)] for x in np.unique(ramp)})
                key = (os.path.basename(path), mname)
                row = report.setdefault(key, {"n": 0, "ramps": set(), "err": [], "starved": []})
                row["n"] += len(p)
                row["ramps"].update(used)
                row["err"].append(float(np.mean(err)))
                if len(p) < 12 and not cfg.get("specks"):
                    row["starved"].append(f"{mesh.get('name', mesh_i)} ({len(p)})")
    if not all_p:
        raise SystemExit("nothing to bake: no triangles found")
    return (np.concatenate(all_p), np.concatenate(all_n), np.concatenate(all_info).astype(np.int64),
            np.concatenate(all_sigma), np.concatenate(all_j), np.concatenate(all_w), tracks, next_bone, report,
            named)


def posed(p, joints, weights, tracks, bone_count):
    """Positions at frame 0 (for the bounds)."""
    mats = np.tile(np.eye(4)[:3], (bone_count, 1, 1)).astype(np.float64)
    for t in tracks:
        mats[t["first"]:t["first"] + t["count"]] = t["data"][0]
    ph = np.concatenate([p, np.ones((len(p), 1))], 1)
    out = np.zeros_like(p)
    for k in range(4):
        out += weights[:, k:k + 1] * np.einsum("nij,nj->ni", mats[joints[:, k]], ph)
    return out


def posed_bounds(p, joints, weights, tracks, bone_count, samples=16):
    """Bounds over the whole animation (a sample of frames of every track), so nothing that
    moves leaves the camera's depth range or the shadow box."""
    lo, hi = None, None
    longest = max([t["frames"] for t in tracks] + [1])
    for k in range(min(samples, longest)):
        f = int(k * longest / min(samples, longest))
        mats = np.tile(np.eye(4)[:3], (bone_count, 1, 1)).astype(np.float64)
        for t in tracks:
            mats[t["first"]:t["first"] + t["count"]] = t["data"][f % t["frames"]]
        ph = np.concatenate([p, np.ones((len(p), 1))], 1)
        out = np.zeros_like(p)
        for j in range(4):
            out += weights[:, j:j + 1] * np.einsum("nij,nj->ni", mats[joints[:, j]], ph)
        lo = out.min(0) if lo is None else np.minimum(lo, out.min(0))
        hi = out.max(0) if hi is None else np.maximum(hi, out.max(0))
    return lo, hi


def write_blob(out, pal, p, n, info, sigma, joints, weights, tracks, bone_count, spacing, named=(), bounds=None):
    count = len(p)
    world = posed(p, joints, weights, tracks, bone_count)
    blo, bhi = posed_bounds(p, joints, weights, tracks, bone_count) if tracks else (world.min(0), world.max(0))
    if bounds is not None:
        blo, bhi = np.array(bounds[0], dtype=np.float64), np.array(bounds[1], dtype=np.float64)
    head = bytearray(HEADER)
    struct.pack_into("<4sIII", head, 0, b"SPLT", 2, count, STRIDE)
    struct.pack_into("<3f3ff", head, 16, *blo, *bhi, spacing)
    struct.pack_into("<II", head, 44, len(pal.hex), len(pal.ramps))
    roles = [pal.roles.get(k, 255) for k in ("sky_top", "sky_bottom", "fog", "void")]
    struct.pack_into("<4B", head, 52, *roles)
    struct.pack_into("<II", head, 56, bone_count, len(tracks))
    for i, c in enumerate(pal.rgb[:MAX_COLORS]):
        struct.pack_into("<4B", head, 64 + i * 4, int(c[0]), int(c[1]), int(c[2]), 255)
    for r, steps in enumerate(pal.ramps[:MAX_RAMPS]):
        for s, idx in enumerate(steps[:MAX_STEPS]):
            head[320 + r * 8 + s] = idx
        head[576 + r] = len(steps)
    rec = np.zeros(count, dtype=[("p", "<f4", 3), ("n", "i1", 4), ("info", "u1", 4), ("sigma", "<f4"),
                                 ("j", "u1", 4), ("w", "u1", 4)])
    rec["p"] = p
    rec["n"][:, :3] = np.clip(np.round(n * 127), -127, 127)
    rec["info"] = info
    rec["sigma"] = sigma
    rec["j"] = joints
    wq = np.floor(weights * 255 + 0.5).astype(np.int64)
    wq[:, 0] += 255 - wq.sum(1)  # sum exactly 255
    rec["w"] = np.clip(wq, 0, 255)
    table_at = HEADER + count * STRIDE
    data_at = table_at + 32 * len(tracks)
    table = bytearray(32 * len(tracks))
    blobs = []
    off = data_at
    for i, t in enumerate(tracks):
        struct.pack_into("<IIIffIff", table, i * 32, t["first"], t["count"], t["frames"], t["fps"],
                         t["phase"], off, t["speed"], 0.0)
        b = t["data"].astype("<f4").tobytes()
        blobs.append(b)
        off += len(b)
    struct.pack_into("<II", head, 608, table_at, off - data_at)
    names = bytearray()
    for idx, name, pos, yaw in named:
        nb = name.encode("ascii")[:255]
        names += struct.pack("<BB", idx, len(nb)) + nb + struct.pack("<4f", *pos, yaw)
    if named:
        struct.pack_into("<II", head, 612, off, len(named))
        off += len(names)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "wb") as f:
        f.write(upgrade_blob(bytes(head) + rec.tobytes() + bytes(table) + b"".join(blobs) + bytes(names)))
    return off, world


def upgrade_blob(data):
    """A v2 blob (32 bytes a splat) as v3 (16 bytes a splat), the format the renderer reads.

    v3 splat, 16 bytes: x, y, z u16 (quantized over the splats' own box), then sigma u8 | ramp u8 << 8
    (sigma quantized over its range) | octahedral normal u16 x2 | step | flags << 3, joint 0, joint 1,
    weight 0 (weight 1 = 1 - weight 0; a splat with more bones keeps its two strongest). Header: the v2
    header (version 3, stride 16), then at 640: box min f32x3, box step f32x3, sigma min f32, sigma
    step f32; splats start at 672. Every absolute offset into the data after the splats moves with
    them. A v3 blob comes back unchanged."""
    head = bytearray(data[:HEADER])
    version = struct.unpack_from("<I", head, 4)[0]
    if version == 3:
        return data
    assert version == 2, f"blob version {version}"
    count = struct.unpack_from("<I", head, 8)[0]
    rec = np.frombuffer(data[HEADER:HEADER + count * STRIDE],
                        dtype=[("p", "<f4", 3), ("n", "i1", 4), ("info", "u1", 4), ("sigma", "<f4"),
                               ("j", "u1", 4), ("w", "u1", 4)])
    tail = data[HEADER + count * STRIDE:]
    p = rec["p"].astype(np.float64)
    lo = p.min(0) if count else np.zeros(3)
    hi = p.max(0) if count else np.ones(3)
    step = np.maximum(hi - lo, 1e-6) / 65535.0
    q = np.clip(np.round((p - lo) / step), 0, 65535).astype(np.uint32)
    sg = rec["sigma"].astype(np.float64)
    smin, smax = (float(sg.min()), float(sg.max())) if count else (0.0, 1.0)
    sstep = max(smax - smin, 1e-9) / 255.0
    sq = np.clip(np.round((sg - smin) / sstep), 0, 255).astype(np.uint32)
    # octahedral normal (z-major)
    n = rec["n"][:, :3].astype(np.float64) / 127.0
    n = n / np.maximum(np.abs(n).sum(1, keepdims=True), 1e-9)
    ox, oy = n[:, 0].copy(), n[:, 1].copy()
    neg = n[:, 2] < 0
    sx = np.where(ox >= 0, 1.0, -1.0)
    sy = np.where(oy >= 0, 1.0, -1.0)
    ox[neg], oy[neg] = ((1 - np.abs(n[neg, 1])) * sx[neg], (1 - np.abs(n[neg, 0])) * sy[neg])
    oct16 = np.clip(np.round((np.stack([ox, oy], 1) * 0.5 + 0.5) * 65535), 0, 65535).astype(np.uint32)
    # the two strongest bones
    w = rec["w"].astype(np.float64)
    order = np.argsort(-w, 1, kind="stable")[:, :2]
    rows = np.arange(count)[:, None]
    j2 = rec["j"][rows, order]
    w2 = w[rows, order]
    tot = np.maximum(w2.sum(1), 1e-9)
    w0 = np.clip(np.round(w2[:, 0] / tot * 255), 0, 255).astype(np.uint32)
    ramp, stp, flags = rec["info"][:, 0], rec["info"][:, 1], rec["info"][:, 2]
    out = np.zeros(count, dtype=[("q", "<u2", 4), ("n", "<u2", 2), ("b", "u1", 4)])
    out["q"][:, :3] = q
    out["q"][:, 3] = sq | (ramp.astype(np.uint32) << 8)
    out["n"] = oct16
    out["b"][:, 0] = (stp & 7) | ((flags & 31) << 3)
    out["b"][:, 1] = j2[:, 0]
    out["b"][:, 2] = j2[:, 1]
    out["b"][:, 3] = w0
    shift = (HEADER3 + count * STRIDE3) - (HEADER + count * STRIDE)
    struct.pack_into("<I", head, 4, 3)
    struct.pack_into("<I", head, 12, STRIDE3)
    table_at, = struct.unpack_from("<I", head, 608)
    tracks, = struct.unpack_from("<I", head, 60)
    names_at, = struct.unpack_from("<I", head, 612)
    named, = struct.unpack_from("<I", head, 616)
    tail = bytearray(tail)
    for t in range(tracks):  # each track's frame data offset (absolute)
        at = table_at - (HEADER + count * STRIDE) + t * 32 + 20
        off, = struct.unpack_from("<I", tail, at)
        struct.pack_into("<I", tail, at, off + shift)
    struct.pack_into("<I", head, 608, table_at + shift)
    if named:
        struct.pack_into("<I", head, 612, names_at + shift)
    quant = struct.pack("<8f", *lo, *step, smin, sstep)
    return bytes(head) + quant + out.tobytes() + bytes(tail)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input", nargs="?", help="a .bake.json scene, or one .glb")
    ap.add_argument("--upgrade", nargs="+", metavar="BIN", help="rewrite v2 blobs as v3 in place, and stop")
    ap.add_argument("-p", "--palette")
    ap.add_argument("-o", "--out")
    ap.add_argument("--spacing", type=float)
    ap.add_argument("--fat", type=float)
    ap.add_argument("--seed", type=int)
    ap.add_argument("--ramp", action="append", default=[], help="MATERIAL=ramp (single-model mode)")
    a = ap.parse_args()
    if a.upgrade:
        for b in a.upgrade:
            data = open(b, "rb").read()
            new = upgrade_blob(data)
            if new is not data:
                open(b, "wb").write(new)
            print(f"{b}: {len(data) / 1024:.0f} KiB -> {len(new) / 1024:.0f} KiB")
        return
    if a.input.endswith(".json"):
        cfg = json.load(open(a.input))
        base = os.path.dirname(os.path.abspath(a.input))
    else:
        cfg = {"objects": [{"model": os.path.abspath(a.input),
                            "materials": {m.split("=")[0]: {"ramp": m.split("=")[1]} for m in a.ramp}}]}
        base = os.getcwd()
    pal_path = a.palette or (os.path.join(base, cfg["palette"]) if "palette" in cfg else None)
    out = a.out or (os.path.join(base, cfg["out"]) if "out" in cfg else None)
    if not pal_path or not out:
        raise SystemExit("need a palette (-p or \"palette\") and an output (-o or \"out\")")
    pal = Palette(pal_path)
    spacing = a.spacing or cfg.get("spacing", 0.06)
    fat = a.fat or cfg.get("fat", 1.0)
    seed = a.seed if a.seed is not None else cfg.get("seed", 1)
    p, n, info, sigma, joints, weights, tracks, bones, report, named = bake(cfg["objects"], pal, spacing, fat, seed, base)
    size, world = write_blob(out, pal, p, n, info, sigma, joints, weights, tracks, bones, spacing, named,
                             cfg.get("bounds"))
    warn = 0
    for (model, mname), row in report.items():
        print(f"  {model}:{mname:14s} {row['n']:7d} splats  ramps {','.join(sorted(row['ramps']))}  "
              f"colour error {max(row['err']):.3f}")
        if max(row["err"]) > 0.05:
            print(f"    warning: {mname}'s colours are far from its ramp: paint it with the ramp's colours")
        if row["starved"]:
            warn += 1
            print(f"    warning: parts with under 12 splats read as specks: {', '.join(row['starved'])}; "
                  "thicken them (pixel-art exaggeration) or give the material a smaller \"spacing\"")
    for t in tracks:
        print(f"  track {t['name']}: bones {t['first']}..{t['first'] + t['count'] - 1}, {t['frames']} frames "
              f"at {t['fps']:g} fps ({t['frames'] / t['fps']:.2f} s loop)")
    if named:
        print(f"  game bones: " + ", ".join(f"{nm} {i}" for i, nm, _, _ in named))
    lo, hi = world.min(0), world.max(0)
    if cfg.get("bounds"):
        lo, hi = np.array(cfg["bounds"][0]), np.array(cfg["bounds"][1])  # what the blob carries
    print(f"wrote {out}: {len(p)} splats, {size / 1024:.0f} KiB, bounds "
          f"[{lo[0]:.2f} {lo[1]:.2f} {lo[2]:.2f}]..[{hi[0]:.2f} {hi[1]:.2f} {hi[2]:.2f}], spacing {spacing}")


if __name__ == "__main__":
    main()
