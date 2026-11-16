# Writes the Vale Guard valley from one layout: the hedra command files of the static world (ground.txt:
# the valley floor with its painted path, the back ridge; scenery.txt: the cave, rocks, trees, the village
# palisade and gate, cottages, the ten stone build pads), the game's pooled pieces (loft.txt, well.txt,
# spire.txt: three of the four towers, the fourth is the hero in models/keep; standard.txt: the gilded
# standards of a level-3 tower; mite.txt, skitter.txt, shell.txt, moth.txt, troll.txt: the creeps; bolt.txt,
# ball.txt, shard.txt: projectiles; pop.txt: a hit puff), the ground texture (textures/ground.png) and the
# layout table scene/game.as reads (written between its "// <layout>" markers).
# Run from models/env: /usr/bin/python3 make_env.py
#
# Coordinates: glTF / game metres, Y up, x to the right of the screen, z towards the camera (the camera
# has yaw 0). hedra is up Z, front -Y: hedra (x, y, z) = (x, -z, height). Every colour is a Vinik24 step.
import math, os, random, re
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
HEX = {"grass": "6eaa78", "olive": "93a167", "moss": "557064", "dirt": "c28d75", "rut": "8d6268", "pebble": "be955c",
       "stone": "9a9a97", "pale": "c5ccb8", "slate": "5d6872", "rock": "6f6776", "lilac": "a593a5", "black": "000000",
       "pine": "387080", "leaf": "557064", "wood": "8d6268", "plank": "c28d75", "roof": "9a4f50", "rose": "c38890",
       "wall": "9d9f7f", "brass": "be955c", "ice": "7ca1c0", "blue": "416aa3", "teal": "68aca9", "plum": "8b5580",
       "indigo": "666092", "greyteal": "7e9e99", "dusk": "433455"}


def rgb(h):
    h = HEX.get(h, h)
    return " ".join(f"{int(h[i:i + 2], 16) / 255:.4f}" for i in (0, 2, 4))


def mat(name, col):
    return f"material new {name} --base-color {rgb(col)} --no-slot"


def hbox(name, cx, cy, cz, sx, sy, sz, m, rot=None):
    """a box in hedra coordinates (centre, size)"""
    out = [f"add mesh cube --name {name} --size 1 --location {cx:.4f} {cy:.4f} {cz:.4f}",
           f"scale {sx:.4f} {sy:.4f} {sz:.4f}", "apply --scale"]
    if rot is not None:
        out += [f"set rotation {rot[0]:.2f} {rot[1]:.2f} {rot[2]:.2f}", "apply --rotation"]
    return out + [f"material assign {m}"]


def gbox(name, x, z, h0, sx, sz, sh, m, yaw=0.0):
    """a box standing on the ground at glTF (x, z), from height h0, sizes x, z (depth), height; yaw degrees"""
    out = [f"add mesh cube --name {name} --size 1 --location 0 0 0", f"scale {sx:.4f} {sz:.4f} {sh:.4f}", "apply --scale"]
    if yaw:
        out += [f"set rotation 0 0 {yaw:.2f}", "apply --rotation"]
    return out + [f"translate {x:.4f} {-z:.4f} {h0 + sh / 2:.4f}", f"material assign {m}"]


def ico(name, x, z, h, r, m, s=(1, 1, 1), rot=(0, 0, 0)):
    return [f"add mesh ico-sphere --name {name} --subdivisions 1 --radius {r:.4f} --location 0 0 0",
            f"set rotation {rot[0]:.1f} {rot[1]:.1f} {rot[2]:.1f}", "apply --rotation",
            f"scale {s[0]:.3f} {s[1]:.3f} {s[2]:.3f}", "apply --scale",
            f"translate {x:.4f} {-z:.4f} {h:.4f}", f"material assign {m}"]


def cyl(name, x, z, h0, r, depth, m, verts=8, r2=None, rot=22.5):
    if r2 is None:
        kind = f"cylinder --vertices {verts} --radius {r:.4f}"
    else:
        kind = f"cone --vertices {verts} --radius1 {r:.4f} --radius2 {r2:.4f}"
    return [f"add mesh {kind} --depth {depth:.4f} --name {name} --location 0 0 0", f"set rotation 0 0 {rot}",
            "apply --rotation", f"translate {x:.4f} {-z:.4f} {h0 + depth / 2:.4f}", f"material assign {m}"]


def join(names, keep):
    return ["select " + " ".join(names), f"active {keep}", "join"]


def drop_bottoms(names):
    out = []
    for n in names:
        out += [f"select {n}", f"active {n}", "apply --location", "mode edit",
                'select face where "normal.z < -0.9"', "delete only-faces", "mode object"]
    return out


def write(fn, lines):
    open(os.path.join(HERE, fn), "w").write("\n".join(lines) + "\n")


# ---------------------------------------------------------------- the layout (shared with game.as)
# the path: control points from the cave mouth (left, back) to the village gate (right, front)
CTRL = [(-5.75, -4.3), (-5.3, -3.6), (-4.3, -3.4), (-3.0, -3.7), (-1.0, -3.5), (1.2, -3.6), (2.9, -3.3), (3.9, -2.4), (3.9, -1.2),
        (2.9, -0.4), (1.0, -0.2), (-1.0, 0.0), (-3.0, -0.1), (-4.4, 0.4), (-4.9, 1.6), (-4.3, 2.8), (-2.9, 3.4),
        (-0.8, 3.6), (1.2, 3.4), (3.0, 3.1), (4.4, 2.7), (5.4, 2.6), (6.6, 2.6)]
GATE_X = 5.4                # the palisade line: a creep past it has leaked into the village
PATH_W = 1.0
PADS = [(-4.7, -1.75), (-2.1, -1.85), (0.5, -1.8), (5.05, -1.9), (-3.0, 1.65), (-0.5, 1.75), (1.9, 1.6),
        (4.3, 0.6), (-6.0, 0.4), (-1.9, -5.0)]
PAD_R = 0.62                # across the flats / 2
CAVE = (-5.9, -4.5)
GROUND = (-7.4, 7.4, -6.9, 6.9)     # x0, x1, z0, z1 of the textured valley floor
TPX = 0.115                 # metres per texel of the ground texture


def catmull(pts, step=0.25):
    out = []
    P = [pts[0]] + pts + [pts[-1]]
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        seg = math.hypot(p2[0] - p1[0], p2[1] - p1[1])
        n = max(2, int(seg / step * 3))
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2
                                    + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3) for j in (0, 1)))
    out.append(pts[-1])
    # resample at even spacing
    res = [out[0]]
    acc = 0.0
    for a, b in zip(out, out[1:]):
        d = math.hypot(b[0] - a[0], b[1] - a[1])
        while acc + d >= step:
            t = (step - acc) / d
            a = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
            res.append(a)
            d = math.hypot(b[0] - a[0], b[1] - a[1])
            acc = 0.0
        acc += d
    res.append(pts[-1])
    return res


PATH = catmull(CTRL)


def path_dist(x, z):
    best = 1e9
    for a, b in zip(PATH, PATH[1:]):
        dx, dz = b[0] - a[0], b[1] - a[1]
        L = dx * dx + dz * dz
        t = 0 if L == 0 else max(0, min(1, ((x - a[0]) * dx + (z - a[1]) * dz) / L))
        d = math.hypot(x - a[0] - dx * t, z - a[1] - dz * t)
        best = min(best, d)
    return best


def hexrgb(h):
    h = HEX.get(h, h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def paint_ground():
    """the valley floor: grass with sunny and dark patches, flowers, the dirt path with darker ruts and pebbles"""
    x0, x1, z0, z1 = GROUND
    W, H = round((x1 - x0) / TPX), round((z1 - z0) / TPX)
    rnd = random.Random(5)
    im = Image.new("RGB", (W, H), hexrgb("grass"))
    d = ImageDraw.Draw(im)

    def px(x, z):
        return (x - x0) / TPX, (z - z0) / TPX
    for _ in range(40):           # sunny olive patches and dark clumps, a few texels across
        x, z = rnd.uniform(x0, x1), rnd.uniform(z0, z1)
        r = rnd.uniform(0.25, 0.45)
        c = hexrgb("olive") if rnd.random() < 0.6 else hexrgb("moss")
        cx, cy = px(x, z)
        d.ellipse([cx - r / TPX, cy - r * 0.6 / TPX, cx + r / TPX, cy + r * 0.6 / TPX], fill=c)
    pix = im.load()
    # the path: dirt inside, a rut-coloured verge, pebbles
    for j in range(H):
        for i in range(W):
            x, z = x0 + (i + 0.5) * TPX, z0 + (j + 0.5) * TPX
            dd = path_dist(x, z)
            if x > GATE_X + 0.2 and dd > PATH_W / 2:
                pass
            if dd < PATH_W / 2 - 0.08:
                pix[i, j] = hexrgb("dirt")
            elif dd < PATH_W / 2 + 0.06:
                pix[i, j] = hexrgb("rut")
            # the pads' surroundings: a ring of trodden olive
            for (px_, pz) in PADS:
                if PAD_R < math.hypot(x - px_, z - pz) < PAD_R + 0.16 and dd > PATH_W / 2 + 0.06:
                    pix[i, j] = hexrgb("olive")
    # pebbles (2 x 2 texels) on the path, flowers (2 x 2) in the grass away from it
    for _ in range(90):
        k = rnd.randrange(len(PATH))
        x, z = PATH[k][0] + rnd.uniform(-0.3, 0.3), PATH[k][1] + rnd.uniform(-0.3, 0.3)
        i, j = int((x - x0) / TPX), int((z - z0) / TPX)
        if 0 <= i < W - 1 and 0 <= j < H - 1 and path_dist(x, z) < PATH_W / 2 - 0.15:
            for a in (0, 1):
                for b in (0, 1):
                    pix[i + a, j + b] = hexrgb("pebble") if rnd.random() < 0.5 or (a + b) % 2 == 0 else hexrgb("rut")
    for _ in range(160):
        x, z = rnd.uniform(x0, x1), rnd.uniform(z0, z1)
        if path_dist(x, z) < PATH_W / 2 + 0.3 or any(math.hypot(x - a, z - b) < PAD_R + 0.3 for a, b in PADS):
            continue
        i, j = int((x - x0) / TPX), int((z - z0) / TPX)
        if 0 <= i < W - 1 and 0 <= j < H - 1:
            c = hexrgb("rose") if rnd.random() < 0.45 else (hexrgb("pale") if rnd.random() < 0.5 else hexrgb("pebble"))
            for a in (0, 1):
                for b in (0, 1):
                    pix[i + a, j + b] = c
    os.makedirs(os.path.join(HERE, "textures"), exist_ok=True)
    im.save(os.path.join(HERE, "textures", "ground.png"))
    return W, H


def free_spot(x, z, r, taken):
    if path_dist(x, z) < PATH_W / 2 + r + 0.15:
        return False
    if any(math.hypot(x - a, z - b) < PAD_R + r + 0.25 for a, b in PADS):
        return False
    if any(math.hypot(x - a, z - b) < ra + r for a, b, ra in taken):
        return False
    return True


def layout_table():
    """the layout as AssemblyScript constants, pasted into scene/game.as between its // <layout> markers"""
    xs = ", ".join(f"{p[0]:.3f}" for p in PATH)
    zs = ", ".join(f"{p[1]:.3f}" for p in PATH)
    lines = ["// <layout> written by models/env/make_env.py: the path every 0.25 m, the build pads",
             f"const NPATH: i32 = {len(PATH)};",
             f"const PATH_X: StaticArray<f64> = [{xs}];",
             f"const PATH_Z: StaticArray<f64> = [{zs}];",
             f"const NPAD: i32 = {len(PADS)};",
             "const PAD_X: StaticArray<f64> = [" + ", ".join(f"{p[0]:.2f}" for p in PADS) + "];",
             "const PAD_Z: StaticArray<f64> = [" + ", ".join(f"{p[1]:.2f}" for p in PADS) + "];",
             f"const GATE_X: f64 = {GATE_X};",
             f"const CAVE_X: f64 = {CAVE[0]};",
             f"const CAVE_Z: f64 = {CAVE[1]};",
             "// </layout>"]
    return "\n".join(lines)


if __name__ == "__main__":
    rnd = random.Random(11)
    W, H = paint_ground()
    x0, x1, z0, z1 = GROUND
    # ------------------------------------------------------------ ground
    g = ["# The valley floor: a slab the size of the view whose top carries textures/ground.png (grass, the",
         "# painted dirt path, flowers; drawn by make_env.py from the same layout as the game), and the grassy",
         "# ridge along the back. make_env.py.", "new",
         "material new Ground --base-color 1 1 1 --no-slot", "material texture Ground base-color textures/ground.png",
         mat("Hill", "grass"), mat("HillDark", "moss")]
    g += [f"add mesh cube --name Ground --size 1 --location {(x0 + x1) / 2:.3f} {-(z0 + z1) / 2:.3f} -0.15",
          f"scale {x1 - x0:.3f} {z1 - z0:.3f} 0.3", "apply --scale", "material assign Hill", "mode edit",
          'select face where "normal.z < 0.9"', "delete only-faces", "select all",
          'select face where "normal.z > 0.9"', "material assign Ground", "uv project-from-view top --scale-to-bounds",
          "mode object"]
    hills = []
    for k in range(13):            # the back ridge: flattened mounds rising behind the cave and the path
        x = -7.6 + k * 1.25 + rnd.uniform(-0.2, 0.2)
        r = rnd.uniform(1.0, 1.4)
        n = f"Hill{k}"
        g += ico(n, x, -6.9 + rnd.uniform(-0.2, 0.3), 0.0, r, "Hill" if k % 3 else "HillDark",
                 s=(1.25, 0.9, 0.62), rot=(rnd.uniform(0, 40), rnd.uniform(0, 40), rnd.uniform(0, 90)))
        hills.append(n)
    g += join(hills, hills[0]) + ["select Hill0", "active Hill0", "apply --location", "mode edit",
                                   'select face where "pos.z < 0.02 && normal.z < 0.3"', "delete only-faces", "mode object"]
    g += ["select all", "shade flat", "export ground.glb"]
    write("ground.txt", g)

    # ------------------------------------------------------------ scenery
    s = ["# The scenery: the cave (a rock outcrop with a black mouth where the path starts), boulders, round",
         "# trees and pines, the village palisade with its roofed gate where the path ends, cottage roofs",
         "# behind it, bushes, the ten stone build pads. make_env.py.", "new",
         mat("Rock", "rock"), mat("Mouth", "black"), mat("Trunk", "wood"), mat("Leaf", "leaf"), mat("Pine", "pine"),
         mat("Post", "wood"), mat("Tip", "wood"), mat("Roof", "roof"), mat("Wall", "wall"), mat("Pad", "stone"), mat("PadRim", "slate"), mat("PadTop", "stone"),
         mat("Bush", "grass"), mat("Plank", "plank"), mat("Crown", "grass")]
    taken = []
    # the cave: rocks round a black mouth facing +x at the path's start
    cx, cz = CAVE
    rocks = []
    for k, (dx, dz, r, sy) in enumerate([(-0.2, -1.0, 1.05, 1.15), (-1.15, -0.4, 1.0, 1.0), (0.85, -0.85, 0.75, 0.8),
                                          (-1.2, 0.75, 0.62, 0.75), (-1.9, -1.2, 0.9, 0.7), (1.6, -1.3, 0.6, 0.6),
                                          (-0.7, -1.7, 0.8, 0.9)]):
        n = f"Rock{k}"
        s += ico(n, cx + dx, cz + dz, 0.1, r, "Rock", s=(1.0, 1.0, sy), rot=(rnd.uniform(0, 50), rnd.uniform(0, 50), rnd.uniform(0, 90)))
        rocks.append(n)
        taken.append((cx + dx, cz + dz, r))
    taken.append((cx + 0.7, cz + 1.0, 1.4))      # keep the path's start clear
    s += join(rocks, rocks[0]) + ["rename Rock0 Cave"]
    # the mouth: a black octagon standing upright in the rocks, turned to face the camera and the path
    s += ["add mesh circle --name Mouth --vertices 8 --radius 0.6 --cap-fill ngon --location 0 0 0",
          "set rotation 90 0 0", "apply --rotation", "set rotation 0 0 35", "apply --rotation",
          f"translate {cx + 0.1:.3f} {-(cz + 0.05):.3f} 0.36", "material assign Mouth"]
    # boulders scattered on the valley edges
    bl = []
    for k, (x, z, r) in enumerate([(-6.6, 3.9, 0.35), (3.0, -5.1, 0.32), (-3.8, -5.4, 0.4), (6.8, -4.6, 0.45),
                                    (2.2, 5.6, 0.3), (-6.9, -5.6, 0.5), (4.9, 4.9, 0.3), (-2.5, 5.7, 0.28)]):
        n = f"Boulder{k}"
        s += ico(n, x, z, r * 0.35, r, "Rock", s=(1.2, 1.0, 0.75), rot=(rnd.uniform(0, 60), rnd.uniform(0, 60), rnd.uniform(0, 90)))
        bl.append(n)
        taken.append((x, z, r))
    s += join(bl, bl[0]) + ["rename Boulder0 Boulders"]
    # the palisade: pointed logs along x = GATE_X, the gate gap where the path passes
    gz0, gz1 = 2.0, 3.2
    logs = []
    z = -4.9
    k = 0
    while z < 6.4:
        if not (gz0 - 0.1 < z < gz1 + 0.1):
            hgt = 0.95 + 0.08 * ((k * 7) % 3)
            n = f"Log{k}"
            s += cyl(n, GATE_X + 0.05 * ((k * 5) % 3 - 1) + 0.35, z, 0.0, 0.12, hgt, "Post", verts=6, rot=0)
            s += cyl(n + "t", GATE_X + 0.05 * ((k * 5) % 3 - 1) + 0.35, z, hgt, 0.12, 0.2, "Tip", verts=6, r2=0.0, rot=0)
            logs += [n, n + "t"]
        z += 0.25
        k += 1
    s += join(logs, logs[0]) + [f"rename {logs[0]} Palisade"]
    # the gate: two tall posts, a lintel and a little red roof over the path
    gx = GATE_X + 0.35
    gate = []
    s += cyl("GateA", gx, gz0 - 0.1, 0.0, 0.16, 1.75, "Post", verts=6, rot=0)
    s += cyl("GateB", gx, gz1 + 0.1, 0.0, 0.16, 1.75, "Post", verts=6, rot=0)
    s += gbox("Lintel", gx, (gz0 + gz1) / 2, 1.45, 0.24, gz1 - gz0 + 0.6, 0.2, "Plank")
    s += [f"add mesh cone --name GateRoof --vertices 4 --radius1 0.62 --radius2 0 --depth 0.42 --location 0 0 0 --rotation 0 0 45",
          "apply --rotation", f"scale 0.75 {(gz1 - gz0 + 0.9) / 0.88:.3f} 1", "apply --scale",
          f"translate {gx:.3f} {-(gz0 + gz1) / 2:.3f} {1.65 + 0.21:.3f}", "material assign Roof"]
    # cottages behind the palisade (partly out of the frame on the right)
    for k, (x, z, w, d_, yaw) in enumerate([(6.5, -2.6, 1.3, 1.1, 0), (6.6, 0.4, 1.2, 1.0, 0), (6.4, 5.3, 1.3, 1.1, 0)]):
        s += gbox(f"House{k}", 0, 0, 0.0, w, d_, 1.0, "Wall")
        s += [f"add mesh cone --name HRoof{k} --vertices 4 --radius1 {w * 0.78:.3f} --radius2 0 --depth 0.75 --location 0 0 0 --rotation 0 0 45",
              "apply --rotation", f"scale 1 {d_ / w * 1.05:.3f} 1", "apply --scale", "translate 0 0 1.375", "material assign Roof"]
        s += gbox(f"Door{k}", -w / 2 - 0.02, 0, 0.0, 0.08, 0.3, 0.5, "Trunk")
        # turned corner-on to the camera, then put in place
        s += [f"select House{k} HRoof{k} Door{k}", f"active House{k}", "join", f"set rotation 0 0 {35 + 10 * k}",
              "apply --rotation", f"translate {x:.3f} {-z:.3f} 0"]
    # trees: round trees in the valley's free spots, pines along the ridge
    tn = []
    for k in range(11):
        x, z = rnd.uniform(-6.6, 4.6), rnd.uniform(-5.6, 4.4)
        tries = 0
        while not free_spot(x, z, 0.55, taken) and tries < 400:
            x, z = rnd.uniform(-6.6, 4.6), rnd.uniform(-5.6, 4.4)
            tries += 1
        taken.append((x, z, 0.55))
        r = rnd.uniform(0.42, 0.55)
        s += cyl(f"Trunk{k}", x, z, 0.0, 0.09, 0.5, "Trunk", verts=5, rot=0)
        s += ico(f"Crown{k}", x, z, 0.5 + r * 0.8, r, "Crown", s=(1, 1, 0.9), rot=(rnd.uniform(0, 60), rnd.uniform(0, 60), 0))
        tn += [f"Trunk{k}", f"Crown{k}"]
    for k in range(16):
        x = -7.4 + k * 0.98 + rnd.uniform(-0.2, 0.2)
        z = -6.0 - rnd.uniform(0.0, 0.8)
        if x > GATE_X - 0.3:
            z -= 0.3
        hb = 0.55 + 0.25 * math.sin(k * 1.7) + 0.3
        s += cyl(f"PT{k}", x, z, hb - 0.3, 0.08, 0.35, "Trunk", verts=5, rot=0)
        s += cyl(f"PA{k}", x, z, hb, 0.45, 0.6, "Pine", verts=6, r2=0.12, rot=rnd.uniform(0, 60))
        s += cyl(f"PB{k}", x, z, hb + 0.45, 0.33, 0.55, "Pine", verts=6, r2=0.0, rot=rnd.uniform(0, 60))
        tn += [f"PT{k}", f"PA{k}", f"PB{k}"]
    s += join(tn, "Trunk0") + ["rename Trunk0 Trees"]
    # bushes along the front edge
    bn = []
    for k in range(6):
        x, z = rnd.uniform(-6.5, 4.8), rnd.uniform(4.6, 6.6)
        tries = 0
        while not free_spot(x, z, 0.35, taken) and tries < 400:
            x, z = rnd.uniform(-6.5, 4.8), rnd.uniform(4.6, 6.6)
            tries += 1
        taken.append((x, z, 0.35))
        r = rnd.uniform(0.28, 0.4)
        s += ico(f"Bush{k}", x, z, r * 0.55, r, "Bush", s=(1.2, 1.2, 0.85), rot=(rnd.uniform(0, 60), rnd.uniform(0, 60), 0))
        bn.append(f"Bush{k}")
    s += join(bn, bn[0]) + ["rename Bush0 Bushes"]
    # the build pads: an octagonal stone slab with a darker rim step
    pn = []
    for k, (x, z) in enumerate(PADS):
        R8 = PAD_R / math.cos(math.radians(22.5))
        s += cyl(f"PadRim{k}", x, z, -0.05, R8, 0.12, "PadRim")
        s += cyl(f"Pad{k}", x, z, 0.0, R8 - 0.09, 0.12, "Pad")
        s += ["mode edit", 'select face where "normal.z > 0.9"', "inset 0.09", "material assign PadTop", "mode object"]
        pn += [f"PadRim{k}", f"Pad{k}"]
    s += drop_bottoms(pn)
    s += join(pn, "PadRim0") + ["rename PadRim0 Pads"]
    s += ["select all", "shade flat", "export scenery.glb"]
    write("scenery.txt", s)

    # ------------------------------------------------------------ the arrow tower (Larch Loft)
    lo = ["# Larch Loft, the arrow tower: a stone footing, four timber legs, a plank cabin, a red pyramid roof and",
          "# a brass crossbow poking out of the front (-Y). Origin on the ground at its centre; 1.62 m tall. make_env.py.",
          "new", mat("Stone", "stone"), mat("Leg", "wood"), mat("Plank", "plank"), mat("Roof", "roof"), mat("Brass", "brass"),
          mat("Dark", "dusk")]
    lo += cyl("Foot", 0, 0, 0.0, 0.5, 0.14, "Stone")
    for k, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        lo += gbox(f"Leg{k}", sx * 0.25, sz * 0.25, 0.14, 0.12, 0.12, 0.66, "Leg")
    lo += gbox("Cabin", 0, 0, 0.78, 0.7, 0.7, 0.4, "Plank")
    lo += gbox("Slit", 0, 0.36, 0.86, 0.36, 0.06, 0.2, "Dark")          # the window under the bow (front: glTF +z)
    lo += ["add mesh cone --name Roof --vertices 4 --radius1 0.62 --radius2 0 --depth 0.46 --location 0 0 0 --rotation 0 0 45",
           "apply --rotation", "translate 0 0 1.41", "material assign Roof"]
    lo += hbox("Stock", 0, -0.42, 1.0, 0.1, 0.36, 0.1, "Brass")
    lo += hbox("Bow", 0, -0.58, 1.0, 0.56, 0.08, 0.08, "Brass")
    lo += drop_bottoms(["Foot"])
    lo += ["select all", "shade flat", "export loft.glb"]
    write("loft.txt", lo)

    # ------------------------------------------------------------ the frost tower (Rime Well)
    we = ["# Rime Well, the frost tower: a round stone well, four short standing stones on its rim and a blue",
          "# ice crystal floating over it. Origin on the ground at its centre; 1.45 m tall. make_env.py.",
          "new", mat("Stone", "stone"), mat("Water", "blue"), mat("Ice", "ice"), mat("Rim", "slate")]
    we += cyl("Well", 0, 0, 0.0, 0.5, 0.5, "Stone")
    we += cyl("Water", 0, 0, 0.5, 0.4, 0.03, "Water")
    for k in range(4):
        a = math.radians(45 + 90 * k)
        we += gbox(f"Menhir{k}", 0.4 * math.cos(a), 0.4 * math.sin(a), 0.5, 0.15, 0.15, 0.36, "Rim", yaw=45 + 90 * k)
    we += ["add mesh cone --name CrystalUp --vertices 4 --radius1 0.22 --radius2 0 --depth 0.42 --location 0 0 1.16",
           "material assign Ice",
           "add mesh cone --name CrystalDn --vertices 4 --radius1 0.22 --radius2 0 --depth 0.26 --location 0 0 0.82 --rotation 180 0 0",
           "apply --rotation", "material assign Ice"]
    we += drop_bottoms(["Well"])
    we += ["select all", "shade flat", "export well.glb"]
    write("well.txt", we)

    # ------------------------------------------------------------ the storm tower (Thunder Spire)
    sp = ["# Thunder Spire, the storm tower: an octagonal plinth, a slate obelisk wound with two copper bands,",
          "# a teal storm orb on top held by three copper prongs. Origin on the ground; 1.7 m tall. make_env.py.",
          "new", mat("Stone", "stone"), mat("Slate", "rock"), mat("Copper", "brass"), mat("Orb", "teal")]
    sp += cyl("Plinth", 0, 0, 0.0, 0.48, 0.24, "Stone")
    sp += ["add mesh cone --name Obelisk --vertices 4 --radius1 0.36 --radius2 0.2 --depth 1.0 --location 0 0 0.74 --rotation 0 0 45",
           "apply --rotation", "material assign Slate"]
    sp += cyl("BandA", 0, 0, 0.5, 0.36, 0.09, "Copper", rot=0)
    sp += cyl("BandB", 0, 0, 0.92, 0.3, 0.09, "Copper", rot=0)
    for k in range(3):
        a = math.radians(90 + 120 * k)
        sp += [f"add mesh cone --name Prong{k} --vertices 4 --radius1 0.06 --radius2 0.0 --depth 0.34 --location 0 0 0",
               f"set rotation 0 {-22:.1f} 0", "apply --rotation", f"set rotation 0 0 {120 * k + 90}", "apply --rotation",
               f"translate {0.13 * math.cos(a):.3f} {0.13 * math.sin(a):.3f} 1.38", "material assign Copper"]
    sp += ico("Orb", 0, 0, 1.47, 0.21, "Orb")
    sp += drop_bottoms(["Plinth"])
    sp += ["select all", "shade flat", "export spire.glb"]
    write("spire.txt", sp)

    # ------------------------------------------------------------ the gilded standards (a level-3 tower)
    st = ["# Gilded standards: four poles with gold finials and red pennants at the corners of a build pad and",
          "# a gold band round its edge: a tower at level 3. Origin at the pad's centre. make_env.py.",
          "new", mat("Gold", "brass"), mat("Pole", "brass"), mat("Pennant", "roof")]
    sn = []
    for k in range(4):
        a = math.radians(45 + 90 * k)
        x, z = 0.6 * math.cos(a), 0.6 * math.sin(a)
        st += gbox(f"Pole{k}", x, z, 0.0, 0.08, 0.08, 1.05, "Pole")
        st += ico(f"Fin{k}", x, z, 1.1, 0.1, "Gold")
        # the pennant flies outwards from the pole
        ox, oz = math.cos(a), math.sin(a)
        st += gbox(f"Flag{k}", x + ox * 0.13, z + oz * 0.13, 0.78, 0.2, 0.05, 0.22, "Pennant", yaw=-(45 + 90 * k))
        sn += [f"Pole{k}", f"Fin{k}", f"Flag{k}"]
    R8 = (PAD_R + 0.04) / math.cos(math.radians(22.5))
    st += cyl("Band", 0, 0, 0.0, R8, 0.12, "Gold")
    st += ["mode edit", 'select face where "abs(normal.z) > 0.9"', "delete only-faces", "mode object"]
    st += ["select all", "shade flat", "export standard.glb"]
    write("standard.txt", st)

    # ------------------------------------------------------------ creeps (front -Y, origin on the ground)
    write("mite.txt", ["# Mite, the swarmer: a plum beetle with a pale head and two brass horn nubs. 0.36 x 0.5 x 0.32 m. make_env.py.",
        "new", mat("Shell", "plum"), mat("Head", "rose"), mat("Horn", "brass"), mat("Foot", "dusk"),
        *ico("Body", 0, 0.04, 0.17, 0.17, "Shell", s=(1.05, 1.3, 0.85)),
        *ico("Head", 0, -0.2, 0.15, 0.11, "Head"),
        *[l for k, sx in enumerate((-1, 1)) for l in hbox(f"Horn{k}", sx * 0.07, -0.26, 0.26, 0.07, 0.07, 0.1, "Horn")],
        *[l for k, (sx, sy) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]) for l in hbox(f"Foot{k}", sx * 0.15, sy * 0.1, 0.035, 0.09, 0.1, 0.07, "Foot")],
        "select all", "shade flat", "export mite.glb"])
    write("skitter.txt", ["# Skitter, the fast creep: a lean teal lizard with a red crest and a long tail. 0.3 x 0.78 x 0.34 m. make_env.py.",
        "new", mat("Hide", "teal"), mat("Crest", "roof"), mat("Foot", "slate"),
        *hbox("Body", 0, 0.0, 0.18, 0.22, 0.38, 0.16, "Hide"),
        *hbox("Head", 0, -0.27, 0.22, 0.17, 0.2, 0.14, "Hide"),
        "add mesh cone --name Tail --vertices 4 --radius1 0.09 --radius2 0.0 --depth 0.36 --location 0 0 0 --rotation -90 0 45",
        "apply --rotation", "translate 0 0.36 0.17", "material assign Hide",
        *hbox("Crest", 0, -0.05, 0.3, 0.06, 0.32, 0.09, "Crest"),
        *[l for k, (sx, sy) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]) for l in hbox(f"Leg{k}", sx * 0.14, sy * 0.13, 0.05, 0.08, 0.09, 0.1, "Foot")],
        "select all", "shade flat", "export skitter.glb"])
    write("shell.txt", ["# Shellback, the armoured creep: an indigo dome shell with a lilac rim, a grey-teal head and four stubby",
        "# legs. 0.7 x 0.84 x 0.5 m. make_env.py.",
        "new", mat("Shell", "indigo"), mat("Rim", "lilac"), mat("Skin", "greyteal"), mat("Foot", "slate"),
        *ico("Dome", 0, 0.03, 0.2, 0.33, "Shell", s=(1.0, 1.15, 0.85)),
        *cyl("Rim", 0, 0.03, 0.12, 0.36, 0.1, "Rim", verts=8),
        *hbox("Head", 0, -0.36, 0.2, 0.2, 0.18, 0.17, "Skin"),
        *[l for k, (sx, sy) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]) for l in hbox(f"Leg{k}", sx * 0.24, sy * 0.2, 0.06, 0.13, 0.13, 0.12, "Foot")],
        "select all", "shade flat", "export shell.glb"])
    write("moth.txt", ["# Gloom moth, the flyer: a khaki body, two broad dusky-rose wings (two-sided cards) and pale feelers.",
        "# 0.86 x 0.5 x 0.2 m; origin at the body's centre (the game flies it 1.2 m up). make_env.py.",
        "new", mat("Body", "wall"), mat("Wing", "plum"), mat("Spot", "pale"),
        *ico("Body", 0, 0, 0.0, 0.12, "Body", s=(0.9, 1.6, 0.9)),
        *hbox("WingL", -0.25, 0.02, 0.02, 0.36, 0.36, 0.035, "Wing"),
        *hbox("WingR", 0.25, 0.02, 0.02, 0.36, 0.36, 0.035, "Wing"),
        *hbox("SpotL", -0.28, 0.04, 0.045, 0.12, 0.12, 0.02, "Spot"),
        *hbox("SpotR", 0.28, 0.04, 0.045, 0.12, 0.12, 0.02, "Spot"),
        *hbox("Feel", 0, -0.25, 0.07, 0.2, 0.06, 0.05, "Spot"),
        "select all", "shade flat", "export moth.glb"])
    write("troll.txt", ["# Moss troll, the boss: a hulking lilac-grey body with slate armour plates, a mossy hump, short legs and a",
        "# wooden club. 1.05 x 0.75 x 1.3 m. make_env.py.",
        "new", mat("Skin", "lilac"), mat("Plate", "rock"), mat("Moss", "leaf"), mat("Club", "wood"), mat("Eye", "pale"),
        *hbox("LegL", -0.2, 0.0, 0.22, 0.22, 0.26, 0.44, "Plate"),
        *hbox("LegR", 0.2, 0.0, 0.22, 0.22, 0.26, 0.44, "Plate"),
        *hbox("Torso", 0, 0.0, 0.72, 0.72, 0.5, 0.6, "Skin"),
        *ico("Hump", 0, -0.18, 1.0, 0.36, "Moss", s=(1.1, 0.8, 0.7)),
        *hbox("Head", 0, -0.3, 1.0, 0.36, 0.3, 0.28, "Skin"),
        *hbox("Brow", 0, -0.46, 1.08, 0.38, 0.06, 0.08, "Plate"),
        *hbox("Eyes", 0, -0.47, 0.98, 0.24, 0.04, 0.06, "Eye"),
        *hbox("ArmL", -0.46, -0.06, 0.66, 0.18, 0.2, 0.5, "Skin"),
        *hbox("ArmR", 0.46, -0.06, 0.66, 0.18, 0.2, 0.5, "Skin"),
        *hbox("Belt", 0, 0.0, 0.48, 0.76, 0.54, 0.1, "Plate"),
        "add mesh cone --name Club --vertices 6 --radius1 0.1 --radius2 0.16 --depth 0.7 --location 0 0 0",
        "set rotation 70 0 0", "apply --rotation", "translate 0.5 -0.3 0.42", "material assign Club",
        "select all", "shade flat", "export troll.glb"])

    # ------------------------------------------------------------ projectiles, the pop
    write("bolt.txt", ["# A crossbow bolt: a chunky timber shaft and a brass head pointing -Y. 0.08 x 0.42 m. make_env.py.",
        "new", mat("Shaft", "plank"), mat("Head", "brass"),
        *hbox("Shaft", 0, 0.05, 0, 0.08, 0.32, 0.08, "Shaft"),
        "add mesh cone --name Head --vertices 4 --radius1 0.08 --radius2 0 --depth 0.14 --location 0 0 0 --rotation 90 0 45",
        "apply --rotation", "translate 0 -0.17 0", "material assign Head",
        "select all", "shade flat", "export bolt.glb"])
    write("ball.txt", ["# A cannonball: a dark rock ball 0.26 m across, origin at its centre. make_env.py.",
        "new", mat("Iron", "rock"), *ico("Ball", 0, 0, 0, 0.13, "Iron"), "select all", "shade flat", "export ball.glb"])
    write("shard.txt", ["# A frost shard: a pale-blue ice spindle 0.14 x 0.34 m pointing -Y, origin at its centre. make_env.py.",
        "new", mat("Ice", "ice"),
        "add mesh cone --name A --vertices 4 --radius1 0.08 --radius2 0 --depth 0.2 --location 0 -0.1 0 --rotation 90 0 0",
        "apply --rotation", "material assign Ice",
        "add mesh cone --name B --vertices 4 --radius1 0.08 --radius2 0 --depth 0.14 --location 0 0.07 0 --rotation -90 0 0",
        "apply --rotation", "material assign Ice",
        "select all", "shade flat", "export shard.glb"])
    pp = ["# A hit puff: five pale lumps round a centre and four ochre sparks, origin at the centre (the game scales",
          "# it from small to full and hides it). 0.7 m across at full size. make_env.py.",
          "new", mat("Puff", "pale"), mat("Spark", "brass")]
    for k in range(5):
        a = math.radians(72 * k + 10)
        pp += ico(f"P{k}", 0.17 * math.cos(a), 0.17 * math.sin(a), 0.04 * (k % 2), 0.15, "Puff", rot=(k * 20, k * 31, 0))
    pp += ico("P5", 0, 0, 0.13, 0.15, "Puff")
    for k in range(4):
        a = math.radians(90 * k + 45)
        pp += hbox(f"S{k}", 0.33 * math.cos(a), 0.33 * math.sin(a), 0.1, 0.08, 0.08, 0.08, "Spark")
    pp += ["select all", "shade flat", "export pop.glb"]
    write("pop.txt", pp)

    # ------------------------------------------------------------ the layout table into game.as
    gp = os.path.join(HERE, "..", "..", "scene", "game.as")
    tab = layout_table()
    if os.path.exists(gp):
        src = open(gp).read()
        if "// <layout>" in src:
            src = re.sub(r"// <layout>.*?// </layout>", lambda m: tab, src, flags=re.S)
            open(gp, "w").write(src)
    open(os.path.join(HERE, "layout_table.as.txt"), "w").write(tab + "\n")
    print(f"ground texture {W} x {H}, path {len(PATH)} points ({(len(PATH) - 1) * 0.25:.1f} m), {len(PADS)} pads")
