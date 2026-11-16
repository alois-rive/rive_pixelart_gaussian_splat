# Writes the mine-cart environment from one track layout: the hedra command files (floor.txt, rails.txt,
# walls.txt, props: gem.txt, rocks.txt, puff.txt, lever.txt, timber.txt, crystals.txt), the floor texture
# (textures/floor.png: the painted track beds) and the track table that scene/game.as follows (written
# between its "// <track>" markers). Run from models/env: /usr/bin/python3 make_env.py
#
# Layout in hedra coordinates (up Z, the camera on -Y: +Y is far, the top of the screen). The cart runs
# clockwise round an oval: the top straight (y 2) heading +X, the right U-turn, the bottom straight (y -2)
# heading -X, the left U-turn. Four junctions each open a second lane (lane B) beside the main one
# (lane A): the straights bulge a lane outwards (0.9 m), the U-turns cut a tight inner lane (0.9 m in).
import math, os, random
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
C = {"navy": (0.125, 0.157, 0.239), "green": (0.259, 0.431, 0.365),
     "tan": (0.898, 0.690, 0.514), "cream": (0.984, 0.969, 0.953)}
HEX = {"navy": (0x20, 0x28, 0x3d), "green": (0x42, 0x6e, 0x5d), "tan": (0xe5, 0xb0, 0x83), "cream": (0xfb, 0xf7, 0xf3)}

def col(n, emit=False):
    r, g, b = C[n]
    s = f"--base-color {r:.3f} {g:.3f} {b:.3f}"
    return s + (f" --emission {r:.3f} {g:.3f} {b:.3f}" if emit else "")

# ---------------------------------------------------------------- the layout
A, H = 2.6, 1.7            # half length of the straights, U-turn radius
D = 0.9                    # lane B offset on the straights (and inside the U-turns)
BEND = 60                  # S-bend: two arcs of BEND degrees offset the lane by D
RB = D / (2 * (1 - math.cos(math.radians(BEND))))
SB = 2 * RB * math.sin(math.radians(BEND))         # S-bend length along the track
PAR = 0.8                  # lane B's parallel run
MARGIN = (2 * A - 2 * SB - PAR) / 2
RI = H - D                 # the tight inner U-turn lane's radius
MAIN = [("S", 2 * A), ("A", H, -180), ("S", 2 * A), ("A", H, -180)]
BULGE = [("A", RB, BEND), ("A", RB, -BEND), ("S", PAR), ("A", RB, -BEND), ("A", RB, BEND)]
INNER = [("A", RI, -90), ("S", 2 * H - 2 * RI), ("A", RI, -90)]
LMAIN = 4 * A + 2 * math.pi * H

def seg_len(sg):
    return sg[1] if sg[0] == "S" else abs(sg[1] * math.radians(sg[2]))

def walk(start, segs, step=0.05):
    """sample points (x, y, heading) every `step` along the path; returns samples and the end pose"""
    x, y, h = start
    pts = [(x, y, h)]
    for sg in segs:
        L = seg_len(sg)
        n = max(1, int(math.ceil(L / step)))
        for i in range(1, n + 1):
            t = L * i / n
            if sg[0] == "S":
                px, py, ph = x + math.cos(h) * t, y + math.sin(h) * t, h
            else:
                r, ang = sg[1], math.radians(sg[2])
                sgn = 1 if ang > 0 else -1
                cx, cy = x - sgn * r * math.sin(h), y + sgn * r * math.cos(h)
                a = t / r * sgn
                ph = h + a
                px, py = cx + sgn * r * math.sin(ph), cy - sgn * r * math.cos(ph)
            pts.append((px, py, ph))
        x, y, h = pts[-1]
    return pts, (x, y, h)

def pose_at(start, segs, s):
    """the exact pose at arc length s along the path"""
    x, y, h = start
    for sg in segs:
        L = seg_len(sg)
        if s <= L + 1e-9:
            pts, _ = walk((x, y, h), [(sg[0], s, 0) if sg[0] == "S" else ("A", sg[1], math.degrees(s / sg[1]) * (1 if sg[2] > 0 else -1))], max(s, 1e-6))
            return pts[-1]
        _, (x, y, h) = walk((x, y, h), [sg], L)
        s -= L
    return (x, y, h)

START = (-A, H, 0.0)
JS = [MARGIN, 2 * A, 2 * A + math.pi * H + MARGIN, 4 * A + math.pi * H]     # diverge s on the main loop
LANES = [BULGE, INNER, BULGE, INNER]
JUNCTIONS = []
for i, (sd, lane) in enumerate(zip(JS, LANES)):
    p = pose_at(START, MAIN, sd)
    llen = sum(seg_len(sg) for sg in lane)
    _, endp = walk(p, lane)
    if lane is BULGE:
        sm = sd + 2 * SB + PAR
    else:
        sm = sd + math.pi * H
    JUNCTIONS.append({"sd": sd, "sm": sm % LMAIN if sm > LMAIN + 1e-6 else sm, "start": p, "lane": lane, "len": llen, "end": endp})

# ---------------------------------------------------------------- the floor and its painted track beds
FX0, FX1, FY0, FY1 = -5.2, 5.2, -3.3, 3.3
TPX = 0.04                         # metres per texture pixel
TW, TH = int(round((FX1 - FX0) / TPX)), int(round((FY1 - FY0) / TPX))

def all_paths(step=0.03):
    out = [walk(START, MAIN, step)[0]]
    for j in JUNCTIONS:
        out.append(walk(j["start"], j["lane"], step)[0])
    return out

def paint_floor():
    rnd = random.Random(7)
    im = Image.new("RGB", (TW, TH), HEX["green"])
    d = ImageDraw.Draw(im)
    def px(x, y):
        return ((x - FX0) / TPX, (FY1 - y) / TPX)
    # dark patches of loose rock and cracks on the cave floor, away from the track
    for _ in range(7):
        x, y = rnd.uniform(FX0 + 0.4, FX1 - 0.4), rnd.uniform(FY0 + 0.4, FY1 - 0.4)
        r = rnd.uniform(0.14, 0.22)
        cx, cy = px(x, y)
        d.ellipse([cx - r / TPX, cy - r * 0.7 / TPX, cx + r / TPX, cy + r * 0.7 / TPX], fill=HEX["navy"])
    # the beds: 0.9 m wide navy bands under every lane (where two lanes run side by side they merge)
    for path in all_paths():
        for (x, y, h) in path:
            cx, cy = px(x, y)
            r = 0.45 / TPX
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=HEX["navy"])
    os.makedirs(os.path.join(HERE, "textures"), exist_ok=True)
    im.save(os.path.join(HERE, "textures", "floor.png"))

def floor_txt():
    return f"""# Cave floor: a slab {FX1 - FX0:.1f} x {FY1 - FY0:.1f} m, top at z 0, its vertical corners chamfered and its
# lower rim made rocky. The top face carries textures/floor.png (the painted track beds, drawn by
# make_env.py from the same layout as the rails), projected from the top over the slab's bounds.
new
material new Floor --base-color 1 1 1 --no-slot
material texture Floor base-color textures/floor.png
material new Rock {col('green')} --no-slot
add mesh cube --name Floor --size 1 --location {(FX0 + FX1) / 2:.3f} {(FY0 + FY1) / 2:.3f} -0.35
scale {FX1 - FX0:.3f} {FY1 - FY0:.3f} 0.7
apply --scale
material assign Rock
mode edit
select edge where "abs(pos.z) < 0.01"
bevel 0.7 --segments 2
select face where "normal.z < -0.9"
delete only-faces
select vert where "pos.z < -0.3"
randomize --amount 0.18 --seed 3
select face where "normal.z > 0.9"
material assign Floor
uv project-from-view top --scale-to-bounds
mode object
shade flat
export floor.glb
"""

# ---------------------------------------------------------------- rails: swept along every lane
RAIL_W, RAIL_H, GAUGE = 0.06, 0.08, 0.23

def sweep(name, start, segs, off):
    x, y, h = start
    nx, ny = -math.sin(h), math.cos(h)
    cx, cy = x + nx * off + math.cos(h) * 0.01, y + ny * off + math.sin(h) * 0.01
    ax = "x" if abs(math.cos(h)) > 0.5 else "y"
    lines = [f"add mesh cube --name {name} --size 1 --location {cx:.4f} {cy:.4f} {RAIL_H / 2:.3f}"]
    sx, sy = (0.02, RAIL_W) if ax == "x" else (RAIL_W, 0.02)
    lines += [f"scale {sx} {sy} {RAIL_H}", "apply --scale", f"active {name}", "mode edit"]
    sign = 1 if (math.cos(h) if ax == "x" else math.sin(h)) > 0 else -1
    lines.append(f'select face where "normal.{ax} {">" if sign > 0 else "<"} {0.9 * sign}"')
    px, py, ph = x, y, h
    for sg in segs:
        if sg[0] == "S":
            L = sg[1]
            lines.append(f"extrude {math.cos(ph) * L:.4f} {math.sin(ph) * L:.4f} 0")
            px, py = px + math.cos(ph) * L, py + math.sin(ph) * L
        else:
            r, ang = sg[1], sg[2]
            sgn = 1 if ang > 0 else -1
            ccx, ccy = px - sgn * r * math.sin(ph), py + sgn * r * math.cos(ph)
            steps = max(3, int(round(abs(ang) / 7.5)))
            lines.append(f"spin --steps {steps} --angle {ang} --axis z --center {ccx:.4f} {ccy:.4f} 0")
            ph2 = ph + math.radians(ang)
            px, py = ccx + sgn * r * math.sin(ph2), ccy - sgn * r * math.cos(ph2)
            ph = ph2
    lines += ['select face where "normal.z < -0.9"', "delete only-faces", "mode object", "material assign Rail"]
    return lines

def rails_txt():
    out = ["# Rails: two steel bars (0.06 x 0.08 m, gauge 0.46) swept along the main loop and the four B lanes",
           "# (extrude for straights, spin for arcs), bottoms deleted (they stand on the floor). Generated by",
           "# make_env.py from the same layout as scene/game.as's track table.",
           "new", f"material new Rail {col('green')} --no-slot"]
    names = []
    paths = [("Main", START, MAIN)] + [(f"Lane{i}", j["start"], j["lane"]) for i, j in enumerate(JUNCTIONS)]
    for nm, st, sg in paths:
        for side, off in (("L", GAUGE), ("R", -GAUGE)):
            names.append(f"{nm}{side}")
            out += sweep(f"{nm}{side}", st, sg, off)
    out += [f"select {' '.join(names)}", f"active {names[0]}", "join", f"rename {names[0]} Rails",
            "shade flat", "export rails.glb"]
    return "\n".join(out) + "\n"

# ---------------------------------------------------------------- lever stands (static) and handles (game bones)
def lever_spots():
    """beside each junction, 0.3 m before the diverge, on the side away from lane B"""
    spots = []
    for j in JUNCTIONS:
        x, y, h = pose_at(START, MAIN, j["sd"] - 0.3)
        # lane B bulges to the left of travel on the straights (outwards) and turns right on the U-turns
        side = -1 if j["lane"] is BULGE else 1
        nx, ny = -math.sin(h), math.cos(h)
        spots.append((x + nx * 0.64 * side, y + ny * 0.64 * side, h))
    return spots

def lever_txt():
    return f"""# Switch lever: an iron handle with a cream knob, pivot at its foot. One game bone per junction: the game
# tilts it towards the lane the switch sends the cart down. Up Z; the knob leans with roll.
new
material new Iron {col('navy')} --no-slot
material new Knob {col('cream')} --no-slot
add mesh cube --name Handle --size 1 --location 0 0 0.25
scale 0.09 0.09 0.5
apply --scale
material assign Iron
add mesh uv-sphere --name Knob --segments 6 --rings 4 --radius 0.11 --location 0 0 0.55
material assign Knob
select all
shade flat
export lever.glb
"""

def stands_txt():
    out = ["# Lever stands: an iron box at every junction (the handles are separate game bones). Generated.",
           "new", f"material new Iron {col('navy')} --no-slot", f"material new Wood {col('tan')} --no-slot"]
    names = []
    for i, (x, y, h) in enumerate(lever_spots()):
        out += [f"add mesh cube --name Stand{i} --size 1 --location {x:.3f} {y:.3f} 0.08", "scale 0.3 0.3 0.16",
                "apply --scale", "material assign Wood"]
        names.append(f"Stand{i}")
    out += [f"select {' '.join(names)}", f"active {names[0]}", "join", "rename Stand0 Stands", "shade flat", "export stands.glb"]
    return "\n".join(out) + "\n"

# ---------------------------------------------------------------- props
def gem_txt():
    return f"""# Gem: a six-sided faceted gem 0.26 across and 0.36 tall, pivot at its foot. A pool of game bones: the game
# floats, spins and pops them.
new
material new Gem {col('cream')} --no-slot
add mesh uv-sphere --name Gem --segments 6 --rings 3 --radius 0.13 --location 0 0 0.18
scale 1 1 1.4
apply --scale
material assign Gem
shade flat
export gem.glb
"""

def rocks_txt():
    return f"""# Rockfall: a pile of three faceted boulders (0.95 x 0.75 x 0.6 m) that turns a lane into a dead end.
# Pivot on the ground at the pile's centre. A pool of game bones (they drop from the roof).
new
material new Boulder {col('tan')} --no-slot
add mesh ico-sphere --name B1 --subdivisions 1 --radius 0.34 --location -0.18 0.05 0.28
add mesh ico-sphere --name B2 --subdivisions 1 --radius 0.28 --location 0.22 -0.1 0.22
add mesh ico-sphere --name B3 --subdivisions 1 --radius 0.22 --location 0.1 0.22 0.45
select B1 B2 B3
active B1
join
mode edit
select all
randomize --amount 0.05 --seed 5
mode object
rename B1 Pile
material assign Boulder
shade flat
export rocks.glb
"""

def stones_txt():
    return rocks_txt().replace("Rockfall: a pile of three faceted boulders (0.95 x 0.75 x 0.6 m) that turns a lane into a dead end.\n# Pivot on the ground at the pile's centre. A pool of game bones (they drop from the roof).",
        "Stones: the rockfall's boulder pile in the cave's green, for scenery (tan is kept for the hazard).").replace(
        "material new Boulder " + col("tan"), "material new Stone " + col("green")).replace("material assign Boulder", "material assign Stone").replace("export rocks.glb", "export stones.glb")

def puff_txt():
    lines = ["# Dust puff: eight chunky motes in a ring (0.9 m across), unlit. A pool of game bones: scaled out",
             "# and hidden by the game when rocks land, gems pop or the cart crashes.", "new",
             f"material new Dust {col('tan', True)} --no-slot"]
    names = []
    for i in range(8):
        a = i * math.pi / 4
        lines += [f"add mesh cube --name M{i} --size 0.14 --location {0.42 * math.cos(a):.3f} {0.42 * math.sin(a):.3f} {0.12 + 0.08 * (i % 2):.3f}",
                  "material assign Dust"]
        names.append(f"M{i}")
    lines += [f"select {' '.join(names)}", "active M0", "join", "rename M0 Puff", "shade flat", "export puff.glb"]
    return "\n".join(lines) + "\n"

def timber_txt():
    return f"""# Timber support: two posts and a cap beam (2.5 m wide, 2.4 m tall) with a lantern under an iron bracket.
# Static scenery along the back wall. Up Z, facing -Y.
new
material new Wood {col('tan')} --no-slot
material new Iron {col('navy')} --no-slot
material new Glow {col('cream', True)} --no-slot
add mesh cube --name PostL --size 1 --location -1.0 0 1.1
scale 0.2 0.2 2.2
apply --scale
add mesh cube --name PostR --size 1 --location 1.0 0 1.1
scale 0.2 0.2 2.2
apply --scale
add mesh cube --name Beam --size 1 --location 0 0 2.3
scale 2.5 0.24 0.22
apply --scale
select PostL PostR Beam
material assign Wood
active PostL
join
rename PostL Timber
add mesh cube --name Bracket --size 1 --location 0.45 -0.05 2.13
scale 0.36 0.3 0.1
apply --scale
material assign Iron
add mesh cylinder --name Lamp --vertices 6 --radius 0.13 --depth 0.3 --location 0.45 -0.05 1.93
material assign Glow
select all
shade flat
export timber.glb
"""

def crystals_txt():
    lines = ["# Crystal cluster: five glowing six-sided crystals leaning out of a rock (1.1 m across, 1.0 m tall). Static.",
             "new", f"material new Rock {col('green')} --no-slot", f"material new Crystal {col('cream', True)} --no-slot",
             f"material new CrystalTan {col('tan', True)} --no-slot",
             "add mesh ico-sphere --name Base --subdivisions 1 --radius 0.45 --location 0 0 0.1",
             "scale 1.2 1 0.6", "apply --scale", "mode edit", "select all", "randomize --amount 0.05 --seed 2", "mode object",
             "material assign Rock"]
    spec = [(0, 0, 0.75, 0, 0, "Crystal"), (0.3, 0.1, 0.55, 25, 20, "CrystalTan"), (-0.32, 0.05, 0.6, -28, 10, "Crystal"),
            (0.1, -0.25, 0.45, 10, -30, "CrystalTan"), (-0.12, 0.28, 0.5, -10, 28, "Crystal")]
    for i, (x, y, h, ry, rx, m) in enumerate(spec):
        lines += [f"add mesh uv-sphere --name C{i} --segments 6 --rings 3 --radius 0.13 --location 0 0 0",
                  f"scale 1 1 {h / 0.26:.3f}", "apply --scale", f"set rotation {rx} {ry} 0", "apply --rotation",
                  f"set location {x} {y} {0.2 + h * 0.4:.3f}", f"material assign {m}"]
    lines += ["select C0 C2 C4", "active C0", "join", "rename C0 Crystals", "select C1 C3", "active C1", "join",
              "rename C1 CrystalsTan", "select all", "shade flat", "export crystals.glb"]
    return "\n".join(lines) + "\n"

def walls_txt():
    """the cave's back wall and side shoulders: a ring of big faceted rocks behind the floor"""
    rnd = random.Random(11)
    lines = ["# Cave wall: big faceted rocks standing round the back and the sides of the floor (1-3 m tall).",
             "# Generated by make_env.py (positions and sizes seeded). Static.", "new",
             f"material new Rock {col('green')} --no-slot"]
    names = []
    rocks = []
    x = FX0 - 0.2
    while x < FX1 + 0.4:                       # the back row
        r = rnd.uniform(0.6, 0.85)
        rocks.append((x, FY1 + 0.1 + rnd.uniform(-0.1, 0.2), r, rnd.uniform(1.1, 1.9)))
        x += r * 1.35
    for side in (-1, 1):                        # the shoulders, lower towards the front
        for k, y in enumerate([2.2, 1.0]):
            r = rnd.uniform(0.5, 0.7)
            rocks.append((side * (FX1 + 0.05), y, r, rnd.uniform(1.0, 1.5) - 0.3 * k))
    for i, (x, y, r, hgt) in enumerate(rocks):
        nm = f"W{i}"
        lines += [f"add mesh ico-sphere --name {nm} --subdivisions 1 --radius 1 --location {x:.3f} {y:.3f} 0",
                  f"scale {r:.3f} {r * 0.8:.3f} {hgt:.3f}", "apply --scale",
                  "mode edit", "select all", f"randomize --amount 0.12 --seed {i + 1}", "mode object", "material assign Rock"]
        names.append(nm)
    lines += [f"select {' '.join(names)}", "active W0", "join", "rename W0 Wall", "mode edit",
              'select face where "pos.z < -0.2"', "delete only-faces", "mode object", "shade flat", "export walls.glb"]
    return "\n".join(lines) + "\n"

# ---------------------------------------------------------------- the game's track table (scene/game.as)
def track_as():
    def segs_as(segs):
        vals = []
        for sg in segs:
            if sg[0] == "S":
                vals += [0, sg[1], 0]
            else:
                vals += [1, sg[1], sg[2]]
        return ", ".join(f"{v:.5f}" if isinstance(v, float) else str(v) for v in vals)
    # hedra (x, y) -> world (x, z = -y); headings flip sign; turns flip sign
    def w(start):
        x, y, h = start
        return f"{x:.5f}, {-y:.5f}, {-math.degrees(h):.5f}"
    def segs_w(segs):
        return [(sg[0], sg[1], -sg[2]) if sg[0] == "A" else sg for sg in segs]
    L = []
    L.append("// <track> generated by models/env/make_env.py from the same layout as the rails: do not edit by hand")
    L.append(f"// world coordinates (x, z), headings in degrees (0 = +X, 90 = +Z); a segment is kind (0 straight,")
    L.append(f"// 1 arc), length or radius, turn degrees (+ = towards +Z from +X). Path 0 is the main loop.")
    L.append(f"const MAIN_LEN: f64 = {LMAIN:.5f};")
    starts = [w(START)] + [w(j["start"]) for j in JUNCTIONS]
    L.append(f"const PATH_START: StaticArray<f64> = [{', '.join(starts)}];")
    segs = [segs_w(MAIN)] + [segs_w(j["lane"]) for j in JUNCTIONS]
    L.append(f"const PATH_NSEG: StaticArray<i32> = [{', '.join(str(len(s)) for s in segs)}];")
    flat = []
    for s in segs:
        flat.append(segs_as(s))
    L.append(f"const PATH_SEGS: StaticArray<f64> = [{', '.join(flat)}];")
    lens = ", ".join("%.5f" % j["len"] for j in JUNCTIONS)
    sds = ", ".join("%.5f" % j["sd"] for j in JUNCTIONS)
    sms = ", ".join("%.5f" % j["sm"] for j in JUNCTIONS)
    L.append(f"const PATH_LEN: StaticArray<f64> = [{LMAIN:.5f}, {lens}];")
    L.append(f"const J_DIVERGE: StaticArray<f64> = [{sds}];")
    L.append(f"const J_MERGE: StaticArray<f64> = [{sms}];")
    lv = []
    for (x, y, h) in lever_spots():
        lv += [f"{x:.4f}", f"{-y:.4f}", f"{-math.degrees(h):.3f}"]
    L.append(f"const LEVER_POS: StaticArray<f64> = [{', '.join(lv)}];")
    L.append("// </track>")
    return "\n".join(L)

if __name__ == "__main__":
    paint_floor()
    files = {"floor.txt": floor_txt(), "rails.txt": rails_txt(), "stands.txt": stands_txt(), "lever.txt": lever_txt(),
             "gem.txt": gem_txt(), "rocks.txt": rocks_txt(), "stones.txt": stones_txt(), "puff.txt": puff_txt(), "timber.txt": timber_txt(),
             "crystals.txt": crystals_txt(), "walls.txt": walls_txt()}
    for n, t in files.items():
        open(os.path.join(HERE, n), "w").write(t)
    block = track_as()
    game = os.path.join(HERE, "..", "..", "scene", "game.as")
    if os.path.exists(game):
        src = open(game).read()
        a, b = src.find("// <track>"), src.find("// </track>")
        if a >= 0 and b > a:
            src = src[:a] + block + src[b + len("// </track>"):]
            open(game, "w").write(src)
            print("updated the track table in scene/game.as")
    open(os.path.join(HERE, "track_table.as.txt"), "w").write(block + "\n")
    print(f"main loop {LMAIN:.3f} m; junctions:", [(round(j['sd'], 3), round(j['sm'], 3), round(j['len'], 3)) for j in JUNCTIONS])
    print("wrote", ", ".join(files), "textures/floor.png", f"({TW}x{TH})")
