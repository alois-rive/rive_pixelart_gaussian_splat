# Writes the hedra command files of the night-heist world and its two roof textures:
#   roofs.txt     the two flat roofs the cat walks (top at y 0), their front facades with windows, the
#                 parapets; the alley between them is left open (the void shows through)
#   backrow.txt   the row of taller buildings behind the roofs, lit windows, the searchlights' posts
#   props.txt     chimneys, a skylight, air-conditioning boxes, vent pipes, a water tower (obstacles)
#   sky.txt       the moon, the stars, a far skyline (all unlit)
#   lamp.txt      a searchlight head (origin at its pivot; the game aims it)
#   pool.txt      a pool of searchlight on the roof (an unlit disc; the game sweeps it)
#   fish.txt      the fish the cat steals (origin at its centre)
#   spark.txt     a sparkle for the grab burst
#   cloud.txt     a night cloud drifting over the moon
# and textures/roof_tar.png, textures/roof_tile.png (palette-exact). The obstacle boxes the game
# collides with are printed at the end and copied into scene/game.as (OBST).
# World layout in glTF metres (Y up, +Z towards the camera); hedra is up Z, front -Y, so a glTF point
# (x, y, z) is written as hedra (x, -z, y). Run from models/env: /usr/bin/python3 make_env.py
import math, os, random
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
HEX = {"plum": "#411d31", "wine": "#631b34", "slate": "#32535f", "teal": "#0b8a8f", "sea": "#0eaf9b",
       "mint": "#30e1b9"}
def rgb(n):
    h = HEX[n]
    return " ".join(f"{int(h[i:i + 2], 16) / 255:.3f}" for i in (1, 3, 5))
def mat(name, col, emit=False):
    s = f"material new {name} --base-color {rgb(col)} --no-slot"
    return s + (f" --emission {rgb(col)}" if emit else "")

def box(name, x0, x1, y0, y1, z0, z1, m=None, drop=()):
    """an axis box given in glTF coordinates; drop: faces to delete, of 'bottom top front back left right'
    (front = towards the camera, +z)"""
    hx, hy, hz = (x0 + x1) / 2, -(z0 + z1) / 2, (y0 + y1) / 2
    L = [f"add mesh cube --name {name} --size 1 --location {hx:.3f} {hy:.3f} {hz:.3f}",
         f"scale {x1 - x0:.3f} {z1 - z0:.3f} {y1 - y0:.3f}", "apply --scale"]
    if m:
        L.append(f"material assign {m}")
    sel = {"bottom": "normal.z < -0.9", "top": "normal.z > 0.9", "front": "normal.y < -0.9",
           "back": "normal.y > 0.9", "left": "normal.x < -0.9", "right": "normal.x > 0.9"}
    if drop:
        L += [f"select {name}", f"active {name}", "mode edit",
              "select face where \"" + " || ".join(sel[d] for d in drop) + "\"", "delete only-faces", "mode object"]
    return L

def windows(prefix, x0, x1, y0, y1, z, rnd, lit_share=0.35, w=0.34, h=0.42, gapx=0.36, gapy=0.42):
    """a grid of window boxes standing 0.1 m proud of a wall facing +z at z (glTF); returns
    (commands, lit names, dark names)"""
    L, lit, dark = [], [], []
    nx = int((x1 - x0 + gapx) // (w + gapx)); ny = int((y1 - y0 + gapy) // (h + gapy))
    if nx < 1 or ny < 1:
        return L, lit, dark
    ox = x0 + (x1 - x0 - (nx * w + (nx - 1) * gapx)) / 2
    oy = y0 + (y1 - y0 - (ny * h + (ny - 1) * gapy)) / 2
    for j in range(ny):
        for i in range(nx):
            n = f"{prefix}{j}_{i}"
            wx = ox + i * (w + gapx); wy = oy + j * (h + gapy)
            L += box(n, wx, wx + w, wy, wy + h, z - 0.02, z + 0.1, drop=("back", "bottom"))
            (lit if rnd.random() < lit_share else dark).append(n)
    return L, lit, dark

def save(name, lines):
    open(os.path.join(HERE, name), "w").write("\n".join(lines) + "\n")

# ------------------------------------------------------------------ layout (glTF metres)
ROOF_Z0, ROOF_Z1 = -2.2, 3.2          # the roofs' back and front edges
GAP = 0.5                             # the alley: x -0.5 .. 0.5
XE = 6.9                              # the roofs' outer ends (off screen at x +-6.4)
FACADE_Y = -3.2                       # the facades' foot (below the frame)
LAMPS = [(-2.8, 1.5, -2.75), (2.4, 1.3, -2.75), (5.4, 0.85, -2.75)]   # the posts' feet on the back row
LAMP_H = 0.7                         # post height: the lamp pivot sits this far above the foot

# ------------------------------------------------------------------ textures
os.makedirs(os.path.join(HERE, "textures"), exist_ok=True)
def px(n):
    h = HEX[n]
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))
# tar roof: 32 x 32 texels over 6.4 x 6 m (0.2 m a texel, ~2.4 splats): slate strips 4 texels wide with
# plum seams, a few teal patches (repairs)
im = Image.new("RGB", (32, 32), px("teal"))
r = random.Random(4)
for y in range(0, 32, 5):
    for x in range(32):
        im.putpixel((x, y), px("slate"))
for k in range(5):
    x0, y0 = r.randrange(0, 28), r.randrange(1, 28)
    if y0 % 5 == 0:
        y0 += 1
    for x in range(x0, x0 + r.choice((3, 4, 5))):
        for y in range(y0, min(y0 + 3, (y0 // 5) * 5 + 5)):
            im.putpixel((x % 32, y), px("slate"))
im.save(os.path.join(HERE, "textures", "roof_tar.png"))
# tiled roof: pavers 5 texels with plum joints, some teal (lighter) slabs
im = Image.new("RGB", (32, 32), px("teal"))
r = random.Random(9)
for ty in range(0, 32, 8):
    for tx in range(0, 32, 8):
        for y in range(ty, min(ty + 8, 32)):
            for x in range(tx, min(tx + 8, 32)):
                if x - tx == 7 or y - ty == 7:
                    im.putpixel((x, y), px("slate"))
im.save(os.path.join(HERE, "textures", "roof_tile.png"))

# ------------------------------------------------------------------ roofs
rnd = random.Random(11)
L = ["# The two flat roofs (top at glTF y 0) either side of a 1 m alley, their front facades with windows",
     "# down to y -3.2, a parapet along the front edge and one at each outer end. Textured tops:",
     "# textures/roof_tar.png (left), roof_tile.png (right), projected from the top. Generated by make_env.py.",
     "new", "material new Tar --base-color 1 1 1 --no-slot", "material texture Tar base-color textures/roof_tar.png",
     "material new Tile --base-color 1 1 1 --no-slot", "material texture Tile base-color textures/roof_tile.png",
     mat("Brick", "wine"), mat("Cap", "teal"), mat("Lit", "sea", True), mat("Dark", "slate"), mat("Floor", "plum")]
lit, dark = [], []
for side, (x0, x1), tex in (("L", (-XE, -GAP), "Tar"), ("R", (GAP, XE), "Tile")):
    L += box(f"Block{side}", x0, x1, FACADE_Y, 0.0, ROOF_Z0, ROOF_Z1, "Brick",
             drop=("bottom", "back", "left", "right"))
    L += [f"select Block{side}", f"active Block{side}", "mode edit", 'select face where "normal.z > 0.9"',
          f"material assign {tex}", "uv project-from-view top --scale-to-bounds", "mode object"]
    # front parapet with a teal cap; parapet at the outer end
    L += box(f"Parapet{side}", x0, x1, 0.0, 0.26, 2.95, 3.2, "Brick", drop=("bottom", "back"))
    L += box(f"PCap{side}", x0 - 0.04, x1 + 0.04, 0.26, 0.34, 2.91, 3.24, "Cap", drop=("bottom",))
    ex = x0 if side == "L" else x1 - 0.25
    L += box(f"End{side}", ex, ex + 0.25, 0.0, 0.26, ROOF_Z0, 2.95, "Brick", drop=("bottom",))
    # facade windows: two storeys under the parapet
    for k, (wx0, wx1) in enumerate(((x0 + 0.5, x0 + 2.9), (x0 + 3.4, x1 - 0.5))):
        c, a, b = windows(f"W{side}{k}_", wx0, wx1, -2.9, -0.45, ROOF_Z1, rnd, 0.4, w=0.42, h=0.55, gapx=0.5, gapy=0.55)
        L += c; lit += a; dark += b
# the alley's floor, deep below (a dark slab seen through the gap)
L += box("Alley", -GAP - 0.1, GAP + 0.1, FACADE_Y, FACADE_Y + 0.05, ROOF_Z0, ROOF_Z1, "Floor", drop=("bottom",))
L += ["select " + " ".join(lit), "material assign Lit", "select " + " ".join(dark), "material assign Dark",
      "select all", "shade flat", "export roofs.glb"]
save("roofs.txt", L)

# ------------------------------------------------------------------ the back row
rnd = random.Random(5)
ROW = [(-XE, -4.2, 1.1), (-4.2, -1.3, 1.5), (-1.3, 1.0, 0.45), (1.0, 3.6, 1.3), (3.6, XE, 0.85)]
L = ["# The back row: five buildings behind the roofs (fronts at glTF z -2.2, 1 m deep), lit windows,",
     "# flat roofs with a teal cap, and the posts that carry the three searchlights. Generated by make_env.py.",
     "new", mat("Brick", "wine"), mat("Top", "slate"), mat("Cap", "teal"), mat("Lit", "sea", True),
     mat("Glow", "mint", True), mat("Dark", "slate"), mat("Metal", "slate")]
lit, glow, dark = [], [], []
for i, (x0, x1, h) in enumerate(ROW):
    L += box(f"B{i}", x0, x1, FACADE_Y, h, ROOF_Z0 - 1.0, ROOF_Z0, "Brick", drop=("bottom", "back", "left", "right"))
    L += [f"select B{i}", f"active B{i}", "mode edit", 'select face where "normal.z > 0.9"', "material assign Top",
          "mode object"]
    L += box(f"C{i}", x0, x1, h, h + 0.1, ROOF_Z0 - 0.05, ROOF_Z0 + 0.12, "Cap", drop=("bottom",))
    if h > 0.6:
        c, a, b = windows(f"V{i}_", x0 + 0.35, x1 - 0.35, 0.15, h - 0.2, ROOF_Z0, rnd, 0.45)
        L += c; dark += b
        for n in a:
            (glow if rnd.random() < 0.4 else lit).append(n)
for k, (x, y, z) in enumerate(LAMPS):
    L += box(f"Post{k}", x - 0.08, x + 0.08, y, y + LAMP_H - 0.12, z - 0.08, z + 0.08, "Metal")
    L += box(f"Foot{k}", x - 0.2, x + 0.2, y, y + 0.12, z - 0.2, z + 0.2, "Metal", drop=("bottom",))
for names, m in ((lit, "Lit"), (glow, "Glow"), (dark, "Dark")):
    if names:
        L += ["select " + " ".join(names), f"material assign {m}"]
L += ["select all", "shade flat", "export backrow.glb"]
save("backrow.txt", L)

# ------------------------------------------------------------------ props on the roofs (obstacles)
OBST = []   # (x0, x1, z0, z1) footprints the cat cannot enter
L = ["# Rooftop props: two chimney stacks with pots, a skylight, two air-conditioning boxes, vent pipes and",
     "# a water tower. Generated by make_env.py.", "new",
     mat("Brick", "wine"), mat("Cap", "teal"), mat("Metal", "slate"), mat("Grille", "plum"),
     mat("Glass", "teal"), mat("Tank", "teal"), mat("Band", "slate")]
def chimney(n, x, z, w=0.8, d=0.55, h=0.95):
    OBST.append((x - w / 2, x + w / 2, z - d / 2, z + d / 2))
    c = box(f"{n}Stack", x - w / 2, x + w / 2, 0, h, z - d / 2, z + d / 2, "Brick", drop=("bottom",))
    c += box(f"{n}Cap", x - w / 2 - 0.05, x + w / 2 + 0.05, h, h + 0.1, z - d / 2 - 0.05, z + d / 2 + 0.05, "Cap", drop=("bottom",))
    for k, ox in enumerate((-0.18, 0.18)):
        c += [f"add mesh cylinder --name {n}Pot{k} --vertices 8 --radius 0.11 --depth 0.26 "
              f"--location {x + ox:.3f} {-z:.3f} {h + 0.22:.3f}", "material assign Metal"]
    return c
L += chimney("CL", -4.7, -1.35)
L += chimney("CR", 1.9, -1.55, w=0.7, d=0.5, h=0.8)
# skylight: a low metal frame with a pitched glass roof (a ridge along x)
x, z = -2.5, 0.9
OBST.append((x - 0.7, x + 0.7, z - 0.55, z + 0.55))
L += box("SkyFrame", x - 0.7, x + 0.7, 0, 0.24, z - 0.55, z + 0.55, "Metal", drop=("bottom",))
L += [f"add mesh cone --name SkyRoof --vertices 4 --radius1 0.85 --radius2 0 --depth 0.32 --location {x:.3f} {-z:.3f} 0.4 --rotation 0 0 45",
      "apply --rotation", "scale 1.12 0.84 1", "apply --scale", "material assign Glass"]
# air-conditioning boxes with a dark fan grille set into the top
for n, (x, z) in (("ACL", (-5.4, 1.85)), ("ACR", (2.4, 1.7))):
    OBST.append((x - 0.45, x + 0.45, z - 0.35, z + 0.35))
    L += box(n, x - 0.45, x + 0.45, 0, 0.52, z - 0.35, z + 0.35, "Metal", drop=("bottom",))
    L += [f"select {n}", f"active {n}", "mode edit", 'select face where "normal.z > 0.9"', "inset 0.1",
          "material assign Grille", "mode object"]
# vent pipes
x, z = 5.5, 2.0
OBST.append((x - 0.35, x + 0.35, z - 0.25, z + 0.25))
for k, (ox, h) in enumerate(((-0.17, 0.55), (0.17, 0.4))):
    L += [f"add mesh cylinder --name Vent{k} --vertices 8 --radius 0.13 --depth {h} --location {x + ox:.3f} {-z:.3f} {h / 2:.3f}",
          "material assign Metal",
          f"add mesh cylinder --name VentCap{k} --vertices 8 --radius 0.19 --depth 0.08 --location {x + ox:.3f} {-z:.3f} {h + 0.04:.3f}",
          "material assign Cap"]
# the water tower: four legs, a banded tank and a conical roof
x, z = 4.75, -1.25
OBST.append((x - 0.75, x + 0.75, z - 0.75, z + 0.75))
for k, (ox, oz) in enumerate(((-0.55, -0.55), (0.55, -0.55), (-0.55, 0.55), (0.55, 0.55))):
    L += box(f"TLeg{k}", x + ox - 0.07, x + ox + 0.07, 0, 1.25, z + oz - 0.07, z + oz + 0.07, "Metal", drop=("bottom",))
L += [f"add mesh cylinder --name Tank --vertices 10 --radius 0.72 --depth 1.0 --location {x:.3f} {-z:.3f} 1.75", "material assign Tank",
      f"add mesh cylinder --name TBand0 --vertices 10 --radius 0.76 --depth 0.09 --location {x:.3f} {-z:.3f} 1.42", "material assign Band",
      f"add mesh cylinder --name TBand1 --vertices 10 --radius 0.76 --depth 0.09 --location {x:.3f} {-z:.3f} 2.02", "material assign Band",
      f"add mesh cone --name TRoof --vertices 10 --radius1 0.86 --radius2 0.05 --depth 0.5 --location {x:.3f} {-z:.3f} 2.5", "material assign Band",
      f"add mesh cube --name TDeck --size 1 --location {x:.3f} {-z:.3f} 1.22", "scale 1.4 1.4 0.08", "apply --scale", "material assign Metal"]
L += ["select all", "shade flat", "export props.glb"]
save("props.txt", L)

# ------------------------------------------------------------------ sky: moon, stars, far skyline
# These sit far behind and below the scene: an orthographic camera pitched 45 degrees shows a point
# (y, z) at screen height 0.743 y - 0.669 (z + 1.2) (pitch 42, target z -1.2), so things far back sit low.
rnd = random.Random(21)
L = ["# The sky's things, all unlit: a full moon (a 12-sided disc facing the camera, mint with sea-green",
     "# maria), stars (specks), a far skyline of wine-red silhouettes with a few lit windows.",
     "# Generated by make_env.py.", "new", mat("Moon", "mint", True), mat("Maria", "sea", True),
     mat("Star", "mint", True), mat("Far", "wine", True), mat("FarLit", "sea", True)]
# the camera looks along (0, -0.669, -0.743) (glTF): a disc facing it is turned 42 degrees about x
mx, my, mz = -3.3, -3.85, -10.0
L += [f"add mesh cylinder --name Moon --vertices 12 --radius 0.66 --depth 0.1 --location {mx} {-mz} {my} --rotation 42 0 0",
      "material assign Moon"]
for k, (ox, oy, rr) in enumerate(((-0.2, 0.17, 0.19), (0.23, -0.08, 0.14), (-0.03, -0.3, 0.11))):
    # maria: small discs just in front of the moon, along the view axis
    L += [f"add mesh cylinder --name Mare{k} --vertices 8 --radius {rr} --depth 0.1 "
          f"--location {mx + ox:.3f} {-(mz + 0.11 - oy * 0.669):.3f} {my + 0.1 + oy * 0.743:.3f} --rotation 42 0 0",
          "material assign Maria"]
sn = []
for i in range(46):
    sx = rnd.uniform(-6.8, 6.8); sy = rnd.uniform(-5.4, -3.0)
    if abs(sx - mx) < 1.0 and abs(sy - my) < 1.2:
        continue
    size = 0.12 if rnd.random() < 0.25 else 0.08
    sn.append(f"S{i}")
    L.append(f"add mesh cube --name S{i} --size {size} --location {sx:.3f} 11 {sy:.3f}")
L += ["select " + " ".join(sn), "material assign Star"]
x = -7.2; fn, fl = [], []
while x < 7.2:
    w = rnd.uniform(0.7, 1.6); h = rnd.uniform(-2.7, -1.9)
    n = f"F{len(fn)}"
    L += box(n, x, x + w, -6.5, h, -7.9, -7.5, drop=("bottom", "back", "left", "right")); fn.append(n)
    for j in range(rnd.randint(0, 2)):
        wx = x + rnd.uniform(0.1, w - 0.3); wy = h - rnd.uniform(0.35, 1.2)
        m = f"FW{len(fl)}"
        L += box(m, wx, wx + 0.2, wy, wy + 0.25, -7.5, -7.4, drop=("bottom", "back")); fl.append(m)
    x += w + rnd.uniform(-0.1, 0.25)
L += ["select " + " ".join(fn), "material assign Far"]
if fl:
    L += ["select " + " ".join(fl), "material assign FarLit"]
L += ["select all", "shade flat", "export sky.glb"]
save("sky.txt", L)

# ------------------------------------------------------------------ searchlight head
save("lamp.txt", ["# A searchlight head: a drum 0.5 across and 0.42 long on a yoke, its lens facing -Y (hedra) = +Z",
     "# (glTF), the game's forward; origin at the pivot. Generated by make_env.py.", "new",
     mat("Drum", "slate"), mat("Rim", "teal"), mat("Lens", "mint", True),
     "add mesh cylinder --name Drum --vertices 10 --radius 0.25 --depth 0.42 --location 0 0 0 --rotation 90 0 0",
     "apply --rotation", "material assign Drum",
     "add mesh cylinder --name Rim --vertices 10 --radius 0.29 --depth 0.08 --location 0 -0.2 0 --rotation 90 0 0",
     "apply --rotation", "material assign Rim",
     "add mesh cylinder --name Lens --vertices 10 --radius 0.21 --depth 0.06 --location 0 -0.24 0 --rotation 90 0 0",
     "apply --rotation", "material assign Lens",
     "add mesh cube --name Yoke --size 1 --location 0 0.02 -0.2", "scale 0.62 0.1 0.12", "apply --scale",
     "material assign Drum", "select all", "shade flat", "export lamp.glb"])

# ------------------------------------------------------------------ the pool of light
save("pool.txt", ["# A searchlight's pool on the roof: a 16-sided disc r 1.0, 0.05 thick (its top 0.1 above the",
     "# origin so it never fights the roof), unlit: a sea-green rim and a mint centre. Generated by make_env.py.",
     "new", mat("Rim", "sea", True), mat("Hot", "mint", True),
     "add mesh cylinder --name Pool --vertices 16 --radius 1.0 --depth 0.05 --location 0 0 0.075",
     "material assign Rim", "active Pool", "mode edit", 'select face where "normal.z > 0.9"', "inset 0.2",
     "material assign Hot", 'select face where "normal.z < -0.9"', "delete only-faces", "mode object",
     "shade flat", "export pool.glb"])

# ------------------------------------------------------------------ the fish
save("fish.txt", ["# The fish: a faceted mint body 0.6 long (along x), flat sides facing +-Y (hedra), a forked tail fin,",
     "# a dorsal fin, a dark eye each side. Origin at its centre. Generated by make_env.py.", "new",
     mat("Scale", "mint"), mat("Fin", "sea"), mat("Eye", "plum"),
     "add mesh ico-sphere --name Body --subdivisions 1 --radius 0.5", "scale 0.62 0.2 0.3", "apply --scale",
     "material assign Scale",
     "add mesh cone --name Tail --vertices 3 --radius1 0.2 --radius2 0.0 --depth 0.24 --location 0.36 0 0 --rotation 0 -90 0",
     "apply --rotation", "scale 1 0.35 1.35", "apply --scale", "material assign Fin",
     "add mesh cone --name Dorsal --vertices 3 --radius1 0.12 --radius2 0 --depth 0.13 --location -0.02 0 0.17",
     "scale 1.6 0.4 1", "apply --scale", "material assign Fin",
     "add mesh cube --name EyeL --size 0.08 --location -0.17 -0.085 0.04", "material assign Eye",
     "add mesh cube --name EyeR --size 0.08 --location -0.17 0.085 0.04", "material assign Eye",
     "select all", "shade flat", "export fish.glb"])

save("spark.txt", ["# A sparkle: a turned cube 0.14 (unlit; the game throws and shrinks it). Generated by make_env.py.",
     "new", mat("Spark", "mint", True), "add mesh cube --name Spark --size 0.14 --rotation 30 20 45",
     "material assign Spark", "shade flat", "export spark.glb"])

save("cloud.txt", ["# A night cloud: three flattened faceted puffs side by side, 2.6 m long, unlit slate (it",
     "# drifts across the sky in front of the moon). Facing the camera like the moon. Generated by make_env.py.",
     "new", mat("Cloud", "slate", True),
     "add mesh ico-sphere --name P0 --subdivisions 1 --radius 0.5 --location -0.8 0 0", "scale 1.4 0.3 0.62",
     "apply --scale",
     "add mesh ico-sphere --name P1 --subdivisions 1 --radius 0.62 --location 0.1 0 0.12", "scale 1.4 0.3 0.75",
     "apply --scale",
     "add mesh ico-sphere --name P2 --subdivisions 1 --radius 0.45 --location 0.95 0 -0.02", "scale 1.4 0.3 0.6",
     "apply --scale", "select P0 P1 P2", "active P1", "join", "rename P1 Cloud", "material assign Cloud",
     "set rotation -42 0 0", "apply --rotation", "shade flat", "export cloud.glb"])

print("wrote roofs, backrow, props, sky, lamp, pool, fish, spark, cloud .txt and textures/roof_*.png")
print("OBST (x0, x1, z0, z1):")
for o in OBST:
    print("   ", ", ".join(f"{v:.2f}" for v in o))
