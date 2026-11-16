# Writes the hedra command files of the kite meadow and the things that fly through it:
# ground.txt (the strip of meadow and the kid's hill), far.txt (the hazy far hills), sun.txt,
# cloud.txt, tree.txt, kid.txt, bird.txt, star.txt, bow.txt (a tail bow), spark.txt.
# Run from models/env: /usr/bin/python3 make_env.py. Up Z, front -Y (hedra); the GLBs come out Y up
# facing +Z. Colours are exact Twilight 5 steps (sRGB 0..1), so the bake snaps exactly.
import math

HEX = {"night": "292831", "dusk": "333f58", "haze": "4a7a96", "pink": "ee8695", "peach": "fbbbad"}
def col(n):
    h = HEX[n]
    return " ".join(f"{int(h[i:i+2], 16) / 255:.4f}" for i in (0, 2, 4))
def mat(name, key):
    return f"material new {name} --base-color {col(key)} --no-slot"

files = {}

files["ground.txt"] = f"""# The meadow: a 22 m strip of ground (top at z 0.6, 4 m deep) with a gently lumpy top, and the kid's
# hill on the left: a big low-poly lump peaking at z 2.6 over x -6.5, and a smaller one beside it.
# Hidden faces (undersides, the parts of the lumps inside the strip) deleted. Static.
new
{mat('Grass', 'dusk')}
add mesh cube --name Strip --size 1 --location 0 0 0.05
scale 22 4 1.1
apply --scale --location
mode edit
select face where "normal.z < -0.9"
delete only-faces
select face where "normal.z > 0.9"
subdivide --cuts 10
select vert where "pos.z > 0.5 && abs(pos.x) < 10.9 && abs(pos.y) < 1.9"
randomize --amount 0.06 --seed 5
mode object
add mesh ico-sphere --name Hill --subdivisions 2 --radius 1 --location 0 0 0
scale 3.8 2.0 2.0
apply --scale
set location -6.5 0.3 0.6
apply --location
mode edit
select all
randomize --amount 0.08 --seed 11
select face where "pos.z < 0.55"
delete only-faces
mode object
add mesh ico-sphere --name Knoll --subdivisions 2 --radius 1 --location 0 0 0
scale 2.2 1.6 1.0
apply --scale
set location -2.9 0.6 0.6
apply --location
mode edit
select face where "pos.z < 0.55"
delete only-faces
mode object
select Strip Hill Knoll
material assign Grass
active Strip
join
rename Strip Ground
select all
shade flat
export ground.glb
"""

far = ["# The far hills: a row of five hazy lumps (z up to 2.9), 26 m long, seen against the sky's pink",
       "# glow. Static, behind everything else.", "new", mat("Haze", "haze")]
lumps = [(-10.5, 2.4, 3.2), (-5.5, 2.9, 3.6), (0.5, 2.2, 3.4), (5.5, 2.7, 3.8), (10.5, 2.1, 3.0)]
for i, (x, h, r) in enumerate(lumps):
    far += [f"add mesh ico-sphere --name Far{i} --subdivisions 2 --radius 1 --location 0 0 0",
            f"scale {r} 1.5 {h}", "apply --scale", f"set location {x} 0 0", "apply --location",
            "mode edit", "select face where \"pos.z < 0.05 || normal.y > 0.3\"", "delete only-faces", "mode object"]
far += ["select all", "material assign Haze", "active Far0", "join", "rename Far0 Far", "select all", "shade flat",
        "export far.glb"]
files["far.txt"] = "\n".join(far) + "\n"

files["sun.txt"] = f"""# The setting sun: a 12-sided disc 3.2 m across, facing the camera (unlit), sinking behind the far hills.
new
{mat('Sun', 'peach')}
add mesh cylinder --name Sun --vertices 12 --radius 1.6 --depth 0.1 --location 0 0 0 --rotation 90 0 0
material assign Sun
mode edit
select face where "normal.y > 0.5"
delete only-faces
mode object
shade flat
export sun.glb
"""

cl = ["# A twilight cloud: five flattened faceted lumps, 3.6 m wide, 1.2 m tall. A game bone: the game",
      "# drifts it across the sky.", "new", mat("Cloud", "pink")]
for i, (x, z, r) in enumerate([(0, 0.1, 0.8), (-0.9, -0.1, 0.6), (0.95, -0.05, 0.65), (-0.35, 0.45, 0.55), (0.45, 0.4, 0.5)]):
    cl += [f"add mesh ico-sphere --name C{i} --subdivisions 1 --radius {r} --location 0 0 0", "scale 1.3 0.7 0.8",
           "apply --scale", f"set location {x} 0 {z}", "apply --location"]
cl += ["select all", "material assign Cloud", "active C0", "join", "rename C0 Cloud", "select all", "shade flat",
       "export cloud.glb"]
files["cloud.txt"] = "\n".join(cl) + "\n"

files["tree.txt"] = f"""# A round dark tree: a six-sided trunk 1.1 m and two faceted crown lumps, 2.8 m tall in all. Static.
new
{mat('Bark', 'night')}
{mat('Crown', 'dusk')}
add mesh cylinder --name Trunk --vertices 6 --radius 0.13 --depth 1.2 --location 0 0 0.6
material assign Bark
add mesh ico-sphere --name Top --subdivisions 1 --radius 0.85 --location 0 0 1.85
material assign Crown
add mesh ico-sphere --name Side --subdivisions 1 --radius 0.55 --location 0.45 -0.1 1.45
material assign Crown
select Trunk Top Side
active Trunk
join
rename Trunk Tree
mode edit
select face where "normal.z < -0.9 && pos.z < 0.1"
delete only-faces
mode object
select all
shade flat
export tree.glb
"""

files["kid.txt"] = f"""# The kid flying the kite: 1.35 m tall, facing the camera (-Y), the right arm (the image's right)
# raised up and out towards the kite, a pink scarf blowing to the right. Origin at the feet: a game
# bone (leans back while the string pulls).
new
{mat('Coat', 'dusk')}
{mat('Dark', 'night')}
{mat('Skin', 'peach')}
{mat('Scarf', 'pink')}
add mesh cube --name LegL --size 1 --location -0.1 0 0.22
scale 0.13 0.14 0.44
apply --scale
material assign Dark
add mesh cube --name LegR --size 1 --location 0.1 0 0.22
scale 0.13 0.14 0.44
apply --scale
material assign Dark
add mesh cylinder --name Body --vertices 6 --radius 0.24 --depth 0.5 --location 0 0 0.68
material assign Coat
add mesh ico-sphere --name Head --subdivisions 1 --radius 0.18 --location 0 0 1.12
material assign Skin
add mesh ico-sphere --name Hair --subdivisions 1 --radius 0.19 --location 0 0.05 1.18
scale 1 1 0.75
apply --scale
material assign Dark
add mesh cube --name Scarf --size 1 --location 0.12 -0.02 0.93
scale 0.5 0.3 0.12
apply --scale
material assign Scarf
add mesh cube --name ArmL --size 1 --location -0.29 0 0.66
scale 0.1 0.12 0.4
apply --scale
material assign Coat
add mesh cube --name ArmR --size 1 --location 0 0 0
scale 0.1 0.12 0.5
apply --scale
set rotation 0 40 0
set location 0.38 0 1.02
material assign Coat
select LegL LegR Body Head Hair Scarf ArmL ArmR
active Body
join
rename Body Kid
select all
shade flat
export kid.glb
"""

files["bird.txt"] = f"""# A dusk gull, the classic "M" silhouette facing the camera (it reads as a bird at any heading): a
# small body, two inner wing halves rising outwards (25 degrees) and two outer halves dipping (20),
# 1.9 m tip to tip, in the XZ plane, hazy blue so it reads on the dusk sky; a pink beak towards the
# camera. Pooled game bone; the game flaps it with a stepped squash. Origin at the body's centre.
new
{mat('Feather', 'haze')}
{mat('Beak', 'pink')}
add mesh ico-sphere --name Body --subdivisions 1 --radius 1 --location 0 0 0
scale 0.24 0.2 0.19
apply --scale
add mesh cone --name Beak --vertices 4 --radius1 0.07 --radius2 0 --depth 0.16 --location 0 -0.24 0.02 --rotation 90 0 0
add mesh cube --name InL --size 1 --location 0 0 0
scale 0.52 0.12 0.26
apply --scale
set rotation 0 25 0
set location -0.27 0 0.1
add mesh cube --name InR --size 1 --location 0 0 0
scale 0.52 0.12 0.26
apply --scale
set rotation 0 -25 0
set location 0.27 0 0.1
add mesh cube --name OutL --size 1 --location 0 0 0
scale 0.5 0.12 0.2
apply --scale
set rotation 0 -20 0
set location -0.72 0 0.16
add mesh cube --name OutR --size 1 --location 0 0 0
scale 0.5 0.12 0.2
apply --scale
set rotation 0 20 0
set location 0.72 0 0.16
select Body InL InR OutL OutR
material assign Feather
select Beak
material assign Beak
select Body Beak InL InR OutL OutR
active Body
join
rename Body Bird
select all
shade flat
export bird.glb
"""

st = ["# A star to catch: five chunky spikes round a faceted core, 0.7 m across, in the XZ plane (facing", 
      "# the camera), unlit peach. Pooled game bone; the game spins and pops it. Origin at the centre.",
      "new", mat("Star", "peach"),
      "add mesh ico-sphere --name Core --subdivisions 1 --radius 0.17 --location 0 0 0",
      "scale 1 0.7 1", "apply --scale"]
for i in range(5):
    a = math.radians(90 + 72 * i)
    x, z = 0.2 * math.cos(a), 0.2 * math.sin(a)
    # the cone points +Z; a turn about Y by -72 i points it along the spike (at 90 + 72 i degrees)
    st += [f"add mesh cone --name S{i} --vertices 4 --radius1 0.11 --radius2 0 --depth 0.26 --location 0 0 0",
           "scale 1 0.6 1", "apply --scale", f"set rotation 0 {-72 * i:.1f} 0", f"set location {x:.3f} 0 {z:.3f}"]
st += ["select all", "material assign Star", "active Core", "join", "rename Core Star", "select all", "shade flat",
       "export star.glb"]
files["star.txt"] = "\n".join(st) + "\n"

files["bow.txt"] = f"""# A tail bow: two flat triangles tip to tip with a knot, 0.36 m wide, pink. Pooled game bone (the
# kite's tail is a chain of these that the game swings). Origin at the knot.
new
{mat('Bow', 'pink')}
add mesh cone --name BL --vertices 3 --radius1 0.11 --radius2 0 --depth 0.18 --location 0 0 0
scale 1 0.5 1
apply --scale
set rotation 0 90 0
set location -0.09 0 0
add mesh cone --name BR --vertices 3 --radius1 0.11 --radius2 0 --depth 0.18 --location 0 0 0
scale 1 0.5 1
apply --scale
set rotation 0 -90 0
set location 0.09 0 0
add mesh ico-sphere --name Knot --subdivisions 1 --radius 0.05 --location 0 0 0
select all
material assign Bow
active BL
join
rename BL Bow
select all
shade flat
export bow.glb
"""

files["spark.txt"] = f"""# A pop spark: a small faceted diamond 0.16 m, unlit peach; pooled: bursts when a star is caught.
new
{mat('Spark', 'peach')}
add mesh cube --name Spark --size 0.16 --location 0 0 0 --rotation 45 35 0
material assign Spark
select all
shade flat
export spark.glb
"""

for k, v in files.items():
    open(k, "w").write(v)
print("wrote", ", ".join(files))
