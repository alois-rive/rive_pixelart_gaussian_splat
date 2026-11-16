# Writes the hedra command files of the orchard's environment and its falling things:
# ground.txt, tree.txt (trunk, static), canopy.txt (a game bone: it shakes before it drops fruit),
# fence.txt, crate.txt, bush.txt, rock.txt, apple.txt, orange.txt, plum.txt, pear.txt, rotten.txt,
# spark.txt. Run from models/env: /usr/bin/python3 make_env.py. Up Z, front -Y (hedra); the GLB
# comes out Y up facing +Z. Colours are exact CC-29 steps (sRGB 0..1), so the bake snaps exactly.
import math

HEX = {"grass": "c2d368", "grass_dk": "8ab060", "path": "a77b5b", "leaf": "8ab060", "leaf_dk": "567b79",
       "bark": "80493a", "wood": "a77b5b", "wood_dk": "80493a", "red": "b45252", "orange": "d3a068",
       "plum": "cf8acb", "pear": "ede19e", "rot": "868188", "rot_spot": "4e584a", "stone": "868188",
       "spark": "f2f0e5", "stem": "4b4158", "flower": "edc8c4"}
def col(n):
    h = HEX[n]
    return " ".join(f"{int(h[i:i+2], 16) / 255:.4f}" for i in (0, 2, 4))
def mat(name, key, emit=False):
    s = f"material new {name} --base-color {col(key)} --no-slot"
    return s + (f" --emission {col(key)}" if emit else "")

files = {}

files["ground.txt"] = f"""# Orchard ground: a 14 x 7.5 m grass slab (top at z 0) with a dirt cart path along X, 1.3 m wide,
# its centre 0.3 m in front of the origin (world z +0.3: the lane the cart rolls on and the fruit
# falls into). The top is subdivided so the path is picked as faces (no decal). Hidden faces deleted.
new
{mat('Grass', 'grass')}
{mat('Path', 'path')}
add mesh cube --name Ground --size 1 --location 0 -0.25 -0.15
scale 14 7.5 0.3
apply --scale --location
material assign Grass
mode edit
select face where "normal.z < -0.9"
delete only-faces
select face where "normal.z > 0.9"
subdivide --cuts 13
select face where "normal.z > 0.9 && pos.y > -0.95 && pos.y < 0.35"
material assign Path
select all
shade flat
mode object
export ground.glb
"""

files["tree.txt"] = f"""# Apple tree trunk: a six-sided trunk 0.36 m across, 1.9 m tall, forking into three short limbs
# that disappear into the canopy (a separate model, canopy.txt). Static.
new
{mat('Bark', 'bark')}
add mesh cylinder --name Trunk --vertices 6 --radius 0.18 --depth 1.9 --location 0 0 0.95
material assign Bark
add mesh cylinder --name LimbL --vertices 5 --radius 0.1 --depth 0.8 --location -0.25 0 1.95 --rotation 0 -35 0
material assign Bark
add mesh cylinder --name LimbR --vertices 5 --radius 0.1 --depth 0.8 --location 0.25 0.05 1.95 --rotation 0 35 0
material assign Bark
add mesh cylinder --name Root --vertices 6 --radius 0.3 --depth 0.16 --location 0 0 0.08
material assign Bark
select Trunk LimbL LimbR Root
active Trunk
join
mode edit
select face where "normal.z < -0.9"
delete only-faces
select all
shade flat
mode object
export tree.glb
"""

# canopy: a cluster of ico spheres; red apples dotted on the front (static decoration)
blobs = [(0, 0, 0.0, 1.05), (-0.75, 0.1, -0.15, 0.75), (0.78, 0.05, -0.1, 0.8), (0.0, 0.25, 0.55, 0.75),
         (-0.35, -0.35, -0.35, 0.65), (0.4, -0.4, -0.3, 0.6)]
dots = [(-0.6, -0.6), (0.7, -0.55), (-0.1, 0.25), (0.9, 0.0), (-0.85, 0.05)]
c = ["# Apple tree canopy: six faceted ico-sphere lumps (2.9 m wide, 1.9 m tall), centre at the origin,",
     "# with five small red apples set into its front (smaller than the falling fruit, so those stand out). A game bone: the game shakes it before a fruit drops.",
     "new", mat('Leaf', 'leaf'), mat('Apple', 'red')]
for i, (x, y, z, r) in enumerate(blobs):
    c += [f"add mesh ico-sphere --name Lump{i} --subdivisions 1 --radius {r} --location {x} {y} {z}", "material assign Leaf"]
for i, (x, z) in enumerate(dots):
    # on the front surface: find y by the front lump (approx)
    y = -0.95 + 0.25 * abs(x)
    c += [f"add mesh ico-sphere --name Dot{i} --subdivisions 1 --radius 0.1 --location {x} {y:.2f} {z}", "material assign Apple"]
c += ["select all", "active Lump0", "join", "select all", "shade flat", "export canopy.glb"]
files["canopy.txt"] = "\n".join(c) + "\n"

f = ["# Back fence: posts every 1.4 m and two rails, 13 m long along X, 0.9 m tall. Static.",
     "new", mat('Wood', 'wood')]
xs = [-6.3 + 1.4 * i for i in range(10)]
for i, x in enumerate(xs):
    f += [f"add mesh cube --name Post{i} --size 1 --location {x:.2f} 0 0.5", "scale 0.14 0.14 1.0", "apply --scale", "material assign Wood"]
f += ["add mesh cube --name Rail0 --size 1 --location 0 0 0.75", "scale 13 0.08 0.12", "apply --scale", "material assign Wood",
      "add mesh cube --name Rail1 --size 1 --location 0 0 0.4", "scale 13 0.08 0.12", "apply --scale", "material assign Wood",
      "select all", "active Rail0", "join", "select all", "shade flat", "export fence.glb"]
files["fence.txt"] = "\n".join(f) + "\n"

files["crate.txt"] = f"""# Fruit crate: an open box 0.8 x 0.55 x 0.45 m of light wood with a heap of apples on top. Static.
new
{mat('Wood', 'wood')}
{mat('Slat', 'wood_dk')}
{mat('Apple', 'red')}
add mesh cube --name Box --size 1 --location 0 0 0.225
scale 0.8 0.55 0.45
apply --scale
material assign Wood
add mesh cube --name Band --size 1 --location 0 0 0.25
scale 0.84 0.59 0.1
apply --scale
material assign Slat
add mesh ico-sphere --name A0 --subdivisions 1 --radius 0.15 --location -0.2 -0.05 0.5
material assign Apple
add mesh ico-sphere --name A1 --subdivisions 1 --radius 0.15 --location 0.12 0.06 0.5
material assign Apple
add mesh ico-sphere --name A2 --subdivisions 1 --radius 0.15 --location -0.02 -0.08 0.62
material assign Apple
select all
active Box
join
mode edit
select face where "normal.z < -0.9"
delete only-faces
mode object
select all
shade flat
export crate.glb
"""

files["bush.txt"] = f"""# A round bush with pink flowers, 1.2 m wide, 0.8 m tall. Static (sways with the wind).
new
{mat('Leaf', 'leaf')}
{mat('Flower', 'flower')}
add mesh ico-sphere --name B0 --subdivisions 1 --radius 0.5 --location 0 0 0.35
material assign Leaf
add mesh ico-sphere --name B1 --subdivisions 1 --radius 0.38 --location -0.38 0.05 0.25
material assign Leaf
add mesh ico-sphere --name B2 --subdivisions 1 --radius 0.36 --location 0.4 0 0.24
material assign Leaf
add mesh ico-sphere --name F0 --subdivisions 1 --radius 0.1 --location -0.2 -0.44 0.48
material assign Flower
add mesh ico-sphere --name F1 --subdivisions 1 --radius 0.1 --location 0.22 -0.42 0.36
material assign Flower
add mesh ico-sphere --name F2 --subdivisions 1 --radius 0.1 --location -0.5 -0.3 0.28
material assign Flower
add mesh ico-sphere --name F3 --subdivisions 1 --radius 0.1 --location 0.05 -0.3 0.78
material assign Flower
select all
active B0
join
select all
shade flat
export bush.glb
"""

files["rock.txt"] = f"""# A low grey boulder 0.7 x 0.5 x 0.35 m. Static.
new
{mat('Stone', 'stone')}
add mesh ico-sphere --name Rock --subdivisions 1 --radius 0.35 --location 0 0 0.12
scale 1.0 0.75 0.6
apply --scale
mode edit
select all
randomize --amount 0.04 --seed 3
mode object
material assign Stone
select all
shade flat
export rock.glb
"""

def fruit(name, desc, body, r, sq, extra, emit=False):
    s = [f"# {desc}", "# Origin at the fruit's centre (a game bone pool: the game drops, catches and pops it).", "new",
         mat("Body", body, emit), mat("Stem", "stem")]
    s += [f"add mesh ico-sphere --name Fruit --subdivisions 1 --radius {r} --location 0 0 0",
          f"scale 1 1 {sq}", "apply --scale", "material assign Body",
          f"add mesh cube --name Stalk --size 1 --location 0.02 0 {r * sq + 0.05:.3f}", "scale 0.06 0.06 0.14", "apply --scale",
          "material assign Stem"]
    s += extra
    s += ["select all", "active Fruit", "join", "select all", "shade flat", f"export {name}.glb"]
    return "\n".join(s) + "\n"

files["apple.txt"] = fruit("apple", "Apple: a faceted red ball 0.38 m across, a dark stalk and a leaf.", "red", 0.19, 0.92,
    [mat("Leaf", "leaf"), "add mesh cube --name LeafA --size 1 --location 0.1 0 0.24", "scale 0.16 0.06 0.08", "apply --scale",
     "material assign Leaf"])
files["orange.txt"] = fruit("orange", "Orange (an apricot-orange): a faceted ball 0.36 m across with a stalk.", "orange", 0.18, 1.0, [])
files["plum.txt"] = fruit("plum", "Plum: a pink-purple egg 0.32 m across, 0.4 m tall.", "plum", 0.16, 1.25, [])
files["pear.txt"] = fruit("pear", "Golden pear (bonus, glows): a ball 0.36 m with a narrower top, unlit.", "pear", 0.18, 0.95,
    ["add mesh ico-sphere --name Top --subdivisions 1 --radius 0.11 --location 0 0 0.17", "material assign Body"], emit=True)
files["rotten.txt"] = fruit("rotten", "Rotten apple: a sickly grey ball 0.38 m across with big dark mould patches (light enough to read against the dark fence).", "rot", 0.19, 0.92,
    [mat("Mould", "rot_spot"),
     "add mesh ico-sphere --name M0 --subdivisions 1 --radius 0.11 --location -0.08 -0.14 0.05", "material assign Mould",
     "add mesh ico-sphere --name M1 --subdivisions 1 --radius 0.1 --location 0.11 -0.11 -0.07", "material assign Mould", "add mesh ico-sphere --name M2 --subdivisions 1 --radius 0.09 --location 0.13 0.1 0.08", "material assign Mould"])

files["spark.txt"] = f"""# A pop spark: a small faceted diamond 0.14 m (unlit, cream), pooled: bursts when a fruit is caught.
new
{mat('Spark', 'spark', True)}
add mesh cube --name Spark --size 0.14 --location 0 0 0 --rotation 45 35 0
material assign Spark
select all
shade flat
export spark.glb
"""

for k, v in files.items():
    open(k, "w").write(v)
print("wrote", ", ".join(files))

# hedge: a long row of dark-green lumps behind the fence, the orchard's back wall
h = ["# Hedge: a 15 m row of faceted lumps (0.9 to 1.3 m tall) behind the fence. Static, sways.", "new", mat('Leaf', 'leaf_dk')]
import random
rnd = random.Random(5)
x = -7.6
i = 0
while x < 7.8:
    r = rnd.uniform(0.55, 0.75)
    h += [f"add mesh ico-sphere --name H{i} --subdivisions 1 --radius {r:.2f} --location {x:.2f} {rnd.uniform(-0.15, 0.15):.2f} {r * 0.8:.2f}",
          "material assign Leaf"]
    x += r * 1.3
    i += 1
h += ["select all", "active H0", "join", "mode edit", "select face where \"pos.z < 0.02\"", "delete only-faces", "mode object",
      "select all", "shade flat", "export hedge.glb"]
open("hedge.txt", "w").write("\n".join(h) + "\n")
print("wrote hedge.txt")
