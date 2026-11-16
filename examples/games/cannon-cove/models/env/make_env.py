# Writes the hedra command files of the cove and of everything the game moves:
# water.txt, shore.txt (far beach, dunes and palms), headland.txt (a rocky point, placed twice),
# ledge.txt (the rock the cannon stands on, with a powder keg and a pile of balls), sun.txt (sun disc
# and clouds), ship.txt (a sloop: the pooled target), ball.txt, marker.txt (the aim ring on the
# water), splash.txt, smoke.txt, flash.txt, plank.txt (debris).
# Run from models/env: /usr/bin/python3 make_env.py. Up Z, front -Y (hedra); the GLB comes out Y up
# facing +Z. Colours are exact SLSO8 steps (sRGB 0..1), so the bake snaps exactly.
import math, random

HEX = {"navy": "0d2b45", "blue": "203c56", "slate": "544e68", "mauve": "8d697a", "orange": "d08159",
       "light": "ffaa5e", "peach": "ffd4a3", "cream": "ffecd6"}
def col(n):
    h = HEX[n]
    return " ".join(f"{int(h[i:i+2], 16) / 255:.4f}" for i in (0, 2, 4))
def mat(name, key, emit=False):
    s = f"material new {name} --base-color {col(key)} --no-slot"
    return s + (f" --emission {col(key)}" if emit else "")
def box(name, x, y, z, sx, sy, sz, m, rot=None):
    out = [f"add mesh cube --name {name} --size 1 --location {x:.3f} {y:.3f} {z:.3f}", f"scale {sx:.3f} {sy:.3f} {sz:.3f}", "apply --scale"]
    if rot:
        out += [f"set rotation {rot[0]} {rot[1]} {rot[2]}", "apply --rotation"]
    return out + [f"material assign {m}"]
def palm(name, x, y, z, h, lean, seed):
    # a leaning trunk of three segments and five drooping fronds (flattened cubes), dark silhouette
    r = random.Random(seed)
    out = []
    parts = []
    px, pz = x, z
    for i in range(3):
        seg = f"{name}T{i}"
        lx = px + lean * (i + 0.5) * h / 3
        out += box(seg, lx, y, pz + (i + 0.5) * h / 3, 0.16 - 0.02 * i, 0.16 - 0.02 * i, h / 3 + 0.04, "Trunk", (0, math.degrees(math.atan(lean)), 0))
        parts.append(seg)
    tx, tz = px + lean * h, pz + h
    for k in range(5):
        a = k * 72 + r.uniform(-15, 15)
        fx, fy = math.cos(math.radians(a)) * 0.5, math.sin(math.radians(a)) * 0.5
        fr = f"{name}F{k}"
        out += [f"add mesh cube --name {fr} --size 1 --location 0 0 0", "scale 1.1 0.32 0.07", "apply --scale",
                f"set rotation 0 25 {a:.1f}", "apply --rotation", f"set location {tx + fx:.3f} {y + fy:.3f} {tz - 0.18:.3f}",
                "apply --location", "material assign Frond"]
        parts.append(fr)
    out += [f"add mesh ico-sphere --name {name}C --subdivisions 1 --radius 0.16 --location {tx:.3f} {y:.3f} {tz:.3f}", "material assign Frond"]
    parts.append(f"{name}C")
    return out, parts

files = {}

# ---- water: a 24 x 26 m sheet (world x -12..12, z -16..10), gently faceted, with sun glints
gl = []
random.seed(5)
for i in range(18):
    zz = -15.2 + i * 0.62 + random.uniform(-0.15, 0.15)     # hedra y = -world z
    w = 0.15 + 0.05 * i * random.uniform(0.4, 1.0)
    xx = 3.07 + 0.364 * zz + random.uniform(-0.5, 0.5) * (1 + i * 0.08)   # under the sun as the camera (yaw 20) sees it
    gl.append(f"(abs(pos.x - {xx:.2f}) < {w:.2f} && abs(pos.y - {-zz:.2f}) < 0.2)")
glint = " || ".join(gl)
files["water.txt"] = f"""# The cove's water: a 24 x 26 m sheet (world z +10..-16) at z 0, subdivided into ~0.5 m facets with a little height
# noise (waves that catch the low sun), and a path of glints under the setting sun (unlit faces).
new
{mat('Sea', 'blue')}
{mat('Glint', 'light', True)}
add mesh grid --name Water --size 1 --x-subdivisions 48 --y-subdivisions 52 --location 0 0 0
scale 24 26 1
apply --scale
set location 0 3 0
apply --location
material assign Sea
mode edit
select all
randomize --amount 0.07 --seed 11
select face where "{glint}"
material assign Glint
mode object
select all
shade flat
export water.glb
"""

# ---- far shore: a beach strip, dunes and palms at world z -13..-17
sh = ["# Far shore: a sand strip 24 m long, two low rock dunes and four palms (dark silhouettes against",
      "# the sunset), across the back of the cove (hedra y 13..17 = world z -13..-17).", "new",
      mat("Sand", "orange"), mat("Rock", "slate"), mat("Trunk", "blue"), mat("Frond", "navy")]
sh += box("Beach", 0, 15.0, 0.15, 24, 4.0, 0.5, "Sand")
sh += [f"add mesh ico-sphere --name Dune0 --subdivisions 1 --radius 2.2 --location -6 16.4 -0.4", "scale 1.8 0.8 0.6", "apply --scale", "material assign Rock",
       f"add mesh ico-sphere --name Dune1 --subdivisions 1 --radius 2.0 --location 5.5 16.6 -0.4", "scale 2.0 0.8 0.65", "apply --scale", "material assign Rock",
       f"add mesh ico-sphere --name Dune2 --subdivisions 1 --radius 1.6 --location 0.5 16.8 -0.3", "scale 1.6 0.7 0.5", "apply --scale", "material assign Rock"]
names = ["Beach", "Dune0", "Dune1", "Dune2"]
for i, (x, y, h, lean) in enumerate([(-8.5, 14.6, 2.6, 0.18), (-3.0, 14.4, 2.2, -0.15), (3.5, 14.8, 2.8, 0.12), (8.0, 14.3, 2.0, -0.2)]):
    o, p = palm(f"P{i}", x, y, 0.4, h, lean, i)
    sh += o
    names += p
sh += ["select " + " ".join(names), "active Beach", "join", "apply --location", "mode edit", "select face where \"normal.z < -0.9 || pos.z < -0.15\"", "delete only-faces",
       "mode object", "select all", "shade flat", "export shore.glb"]
files["shore.txt"] = "\n".join(sh) + "\n"

# ---- headland: a rocky point (placed left and right, mirrored by yaw)
hd = ["# A rocky headland: stacked faceted boulders 5 m long, 3 m deep, up to 2.6 m tall, a sand top and one",
      "# palm. Placed twice (left, right) to frame the cove.", "new",
      mat("Rock", "slate"), mat("Sand", "orange"), mat("Trunk", "blue"), mat("Frond", "navy")]
rocks = [(0, 0, 1.0, 1.6), (-1.6, 0.6, 0.7, 1.2), (1.5, -0.4, 0.6, 1.15), (0.4, 1.2, 0.5, 1.0), (-0.8, -1.0, 0.4, 0.9), (2.4, 0.6, 0.3, 0.8)]
names = []
for i, (x, y, z, r) in enumerate(rocks):
    hd += [f"add mesh ico-sphere --name R{i} --subdivisions 1 --radius {r} --location {x} {y} {z}", "scale 1.25 1.0 0.95", "apply --scale",
           "mode edit", "select all", f"randomize --amount 0.12 --seed {i + 2}", "mode object", "material assign Rock"]
    names.append(f"R{i}")
hd += [f"add mesh ico-sphere --name Top --subdivisions 1 --radius 1.0 --location 0.1 0.2 2.25", "scale 1.4 1.1 0.35", "apply --scale", "material assign Sand"]
names.append("Top")
o, p = palm("H", 0.3, 0.3, 2.3, 2.3, 0.22, 9)
hd += o
names += p
hd += ["select " + " ".join(names), "active R0", "join", "rename R0 Headland", "apply --location", "mode edit",
       "select face where \"pos.z < -0.1\"", "delete only-faces", "mode object", "select all", "shade flat", "export headland.glb"]
files["headland.txt"] = "\n".join(hd) + "\n"

# ---- the ledge under the cannon (world: centre at the cannon), keg and a pile of balls
ld = ["# The cannon's ledge: a flat-topped rock 6 x 3.4 m, top at z 0.8, with a sand top face, a powder keg",
      "# and a pyramid of six cannonballs beside the cannon. The cannon stands at the origin.", "new",
      mat("Rock", "slate"), mat("Sand", "orange"), mat("Keg", "mauve"), mat("Hoop", "blue"), mat("Ball", "blue")]
ld += ["add mesh cylinder --name Ledge --vertices 9 --radius 2.6 --depth 1.6 --location 0 0.2 0", "scale 1.25 0.7 1", "apply --scale",
       "material assign Rock", "mode edit", "select face where \"normal.z > 0.9\"", "material assign Sand",
       "select face where \"normal.z < -0.9\"", "delete only-faces", "mode object"]
ld += ["add mesh cylinder --name Keg --vertices 8 --radius 0.3 --depth 0.6 --location -1.6 0.3 1.1", "material assign Keg",
       "add mesh cylinder --name Hoop0 --vertices 8 --radius 0.32 --depth 0.08 --location -1.6 0.3 0.95", "material assign Hoop",
       "add mesh cylinder --name Hoop1 --vertices 8 --radius 0.32 --depth 0.08 --location -1.6 0.3 1.25", "material assign Hoop"]
balls = []
k = 0
for (x, y, z) in [(1.35, 0.1, 0.96), (1.71, 0.1, 0.96), (1.53, 0.42, 0.96), (1.53, -0.22, 0.96), (1.53, 0.1, 1.24), (1.89, 0.42, 0.96)]:
    ld += [f"add mesh ico-sphere --name B{k} --subdivisions 1 --radius 0.17 --location {x} {y} {z}", "material assign Ball"]
    balls.append(f"B{k}")
    k += 1
ld += ["select Ledge Keg Hoop0 Hoop1 " + " ".join(balls), "active Ledge", "join", "select all", "shade flat", "export ledge.glb"]
files["ledge.txt"] = "\n".join(ld) + "\n"

files["sun.txt"] = f"""# The setting sun: a 12-sided disc 3.6 m across standing upright, facing the camera (-Y), and two long
# flat clouds. Unlit. Placed far behind the shore.
new
{mat('Sun', 'cream', True)}
{mat('Cloud', 'peach', True)}
add mesh cylinder --name Sun --vertices 12 --radius 1.8 --depth 0.2 --location 0 0 0 --rotation 90 0 0
apply --rotation
material assign Sun
add mesh cube --name C0 --size 1 --location -5.5 0.5 1.1
scale 5.0 0.2 0.45
apply --scale
material assign Cloud
add mesh cube --name C1 --size 1 --location -3.4 0.5 1.7
scale 2.6 0.2 0.4
apply --scale
material assign Cloud
add mesh cube --name C2 --size 1 --location 6.0 0.5 1.5
scale 4.2 0.2 0.4
apply --scale
material assign Cloud
add mesh cube --name C3 --size 1 --location 3.0 -0.3 0.4
scale 3.0 0.2 0.35
apply --scale
material assign Cloud
select Sun C0 C1 C2 C3
active Sun
join
select all
shade flat
export sun.glb
"""

files["ship.txt"] = f"""# A sloop: the target. Hull 2.4 m long (bow to +X), 0.8 m wide, a deck rail, a mast 2.7 m tall,
# one big fore-and-aft sail along the hull (seen broadside from the cannon), a jib and a pennant.
# Origin at the waterline under the mast. A game bone pool: the game sails, bobs, tilts and sinks it.
new
{mat('Hull', 'slate')}
{mat('Deck', 'mauve')}
{mat('Mast', 'blue')}
{mat('Sail', 'peach')}
{mat('Flag', 'orange')}
add mesh cube --name Hull --size 1 --location 0 0 0.1
scale 2.0 0.8 0.55
apply --scale
mode edit
select face where "normal.x > 0.9"
extrude 0.45 0 0.08
scale 0.2 0.25 0.6
select face where "normal.x < -0.9"
extrude -0.12 0 0.04
select face where "normal.z < -0.9"
scale 0.75 0.6 1
mode object
material assign Hull
add mesh cube --name Rail --size 1 --location 0 0 0.42
scale 2.2 0.84 0.1
apply --scale
material assign Deck
add mesh cube --name Cabin --size 1 --location -0.7 0 0.55
scale 0.6 0.5 0.3
apply --scale
material assign Deck
add mesh cylinder --name Mast --vertices 6 --radius 0.07 --depth 2.7 --location 0.1 0 1.65
material assign Mast
add mesh cube --name Sail --size 1 --location -0.45 0 1.55
scale 1.0 0.07 1.7
apply --scale
mode edit
select vert where "pos.x < -0.4 && pos.z > 0.8"
translate 0.25 0 -0.25
mode object
material assign Sail
add mesh cube --name Jib --size 1 --location 0.62 0 1.35
scale 0.85 0.06 1.3
apply --scale
mode edit
select vert where "pos.x > 0.4 && pos.z > 0.6"
translate -0.6 0 0
mode object
material assign Sail
add mesh cube --name Pennant --size 1 --location -0.05 0 2.9
scale 0.3 0.04 0.16
apply --scale
material assign Flag
select Hull Rail Cabin Mast Sail Jib Pennant
active Hull
join
rename Hull Ship
select all
shade flat
export ship.glb
"""

files["ball.txt"] = f"""# A cannonball 0.36 m across (exaggerated), iron. Origin at its centre.
new
{mat('Ball', 'blue')}
add mesh ico-sphere --name Ball --subdivisions 1 --radius 0.18 --location 0 0 0
material assign Ball
shade flat
export ball.glb
"""

files["marker.txt"] = f"""# The aim marker: a flat ring 1.0 m across and a centre dot, lying on the water, unlit. Origin at the centre.
new
{mat('Mark', 'light', True)}
add mesh torus --name Ring --major-radius 0.42 --minor-radius 0.07 --major-segments 12 --minor-segments 4 --location 0 0 0
scale 1 1 0.6
apply --scale
material assign Mark
add mesh cylinder --name Dot --vertices 6 --radius 0.1 --depth 0.06 --location 0 0 0
material assign Mark
select Ring Dot
active Ring
join
shade flat
export marker.glb
"""

sp = ["# A splash: a centre column and a crown of six leaning spikes, 1.3 m tall, unlit cream. Origin at the",
      "# water. The game grows and drops it (placeScaled).", "new", mat("Foam", "cream", True)]
sp += ["add mesh cylinder --name Col --vertices 6 --radius 0.16 --depth 1.3 --location 0 0 0.65", "material assign Foam"]
names = ["Col"]
for i in range(6):
    a = math.radians(i * 60 + 30)
    sp += [f"add mesh cube --name S{i} --size 1 --location 0 0 0", "scale 0.12 0.12 0.7", "apply --scale",
           f"set rotation 0 28 {i * 60 + 30}", "apply --rotation",
           f"set location {0.35 * math.cos(a):.3f} {0.35 * math.sin(a):.3f} 0.3", "apply --location", "material assign Foam"]
    names.append(f"S{i}")
sp += ["select " + " ".join(names), "active Col", "join", "select all", "shade flat", "export splash.glb"]
files["splash.txt"] = "\n".join(sp) + "\n"

files["smoke.txt"] = f"""# A smoke puff: a faceted ball 0.7 m across, sunset-lit. Origin at its centre.
new
{mat('Smoke', 'peach')}
add mesh ico-sphere --name Puff --subdivisions 1 --radius 0.35 --location 0 0 0
mode edit
select all
randomize --amount 0.05 --seed 4
mode object
material assign Smoke
shade flat
export smoke.glb
"""

files["flash.txt"] = f"""# The muzzle flash: three crossed spikes 0.9 m long, unlit cream. Origin at its centre.
new
{mat('Fire', 'cream', True)}
add mesh cube --name F0 --size 1 --location 0 0 0
scale 0.9 0.2 0.2
apply --scale
add mesh cube --name F1 --size 1 --location 0 0 0
scale 0.2 0.9 0.2
apply --scale
add mesh cube --name F2 --size 1 --location 0 0 0
scale 0.2 0.2 0.9
apply --scale
select F0 F1 F2
active F0
join
set rotation 30 20 40
apply --rotation
material assign Fire
shade flat
export flash.glb
"""

files["plank.txt"] = f"""# Debris: a broken plank 0.5 x 0.14 x 0.1 m. Origin at its centre.
new
{mat('Deck', 'mauve')}
add mesh cube --name Plank --size 1 --location 0 0 0
scale 0.5 0.14 0.1
apply --scale
material assign Deck
shade flat
export plank.glb
"""

for k, v in files.items():
    open(k, "w").write(v)
print("wrote", ", ".join(files))
