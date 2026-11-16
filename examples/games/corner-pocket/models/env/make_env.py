# Writes the hedra command files of the Crooked Lamp's pub corner and its game pieces, and their
# textures (drawn here, palette-exact):
#   floor.txt   wooden boards (textures/boards.png)
#   wall.txt    the back wall: navy wallpaper (textures/paper.png) over a wooden wainscot (textures/panel.png)
#   window.txt  a four-paned window, the night outside (textures/night.png: a crescent moon, stars)
#   dart.txt    a dartboard on its backboard (textures/dartboard.png)
#   neon.txt    a neon crescent moon and star (the pub's sign)
#   stool.txt   a bar stool: red leather seat, wooden legs and footring
#   sidetable.txt  a round pub table on a pedestal with a pint and a coaster
#   cat.txt, tail.txt  Biscuit, the pub cat, asleep on a stool; its tail (a game bone: it flicks)
#   cue.txt     the cue (a game bone): its tip at the origin, the butt along +Y (glTF -Z)
#   ball_cue.txt, ball_sun.txt, ball_moon.txt, ball_night.txt  the balls (game bones), centred on
#               the origin, a spot at each pole so their rolling shows
#   chalk.txt   a cube of blue chalk on the rail
# Run from models/env: /usr/bin/python3 make_env.py
# Up Z, front -Y (hedra); colours exact Chromatic16. World (glTF) = (x, z, -y) of hedra.
import math
import os
from PIL import Image

HEX = {"black": "000000", "grey": "90b0b0", "white": "ffffff", "maroon": "800018", "red": "ff0000",
       "brown": "a05000", "orange": "ff8000", "peach": "ffc080", "yellow": "ffff00", "green": "20ac00",
       "lime": "40ff00", "navy": "003070", "blue": "3070b0", "cyan": "00d0ff", "purple": "a000e0",
       "pink": "ff60ff"}


def rgb(n):
    h = HEX[n]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def col(n):
    r, g, b = (c / 255 for c in rgb(n))
    return f"--base-color {r:.4f} {g:.4f} {b:.4f}"


def box(name, x0, x1, y0, y1, z0, z1):
    return (f"add mesh cube --name {name} --size 1 --location {(x0 + x1) / 2:.4f} {(y0 + y1) / 2:.4f} {(z0 + z1) / 2:.4f}\n"
            f"scale {x1 - x0:.4f} {y1 - y0:.4f} {z1 - z0:.4f}\napply --scale\n")


def edit(obj, *cmds):
    return f"select {obj}\nactive {obj}\nmode edit\n" + "\n".join(cmds) + "\nmode object\n"


os.makedirs("textures", exist_ok=True)
files = {}

# ---------------------------------------------------------------- textures
# boards: 6.6 x 3.6 m of floor, boards 0.18 m wide running along X, 0.045 m a texel (about two
# splats): 146 x 80. Maroon boards, end joints staggered (two black texels), a brown knot here and there.
TW, TH = 146, 80
img = Image.new("RGB", (TW, TH), rgb("maroon"))
p = img.load()
for j in range(TH):
    row = j // 4
    for i in range(TW):
        c = "maroon"
        if (i + row * 23) % 44 < 2 and j % 4 != 0:
            c = "black"
        if (i * 7 + row * 13) % 97 < 2 and j % 4 == 2:
            c = "brown"
        p[i, j] = rgb(c)
img.save("textures/boards.png")

# wallpaper: 6.6 x 1.7 m above the wainscot, 0.05 m a texel: 132 x 34. Blue with navy diamonds
# (3 texels) every 0.3 m, offset every other row: a quiet pattern that reads at the texel.
TW, TH = 132, 34
img = Image.new("RGB", (TW, TH), rgb("blue"))
p = img.load()
for j in range(TH):
    for i in range(TW):
        r = j // 6
        cx = (i + (3 if r % 2 else 0)) % 6
        cy = j % 6
        if abs(cx - 2) + abs(cy - 2) <= 1:
            p[i, j] = rgb("navy")
img.save("textures/paper.png")

# wainscot: 6.6 x 0.9 m, 0.05 m a texel: 132 x 18. Brown panels framed in maroon (2 texels).
TW, TH = 132, 18
img = Image.new("RGB", (TW, TH), rgb("maroon"))
p = img.load()
for j in range(TH):
    for i in range(TW):
        if 3 <= j <= 14 and 2 <= i % 12 <= 9:
            p[i, j] = rgb("brown")
img.save("textures/panel.png")

# the night through the window: 0.64 x 0.74 m of panes, 0.04 m a texel: 16 x 18. Navy, a white
# crescent moon (top left pane), cyan stars (two texels), a blue band of distant roofs at the bottom.
TW, TH = 16, 18
img = Image.new("RGB", (TW, TH), rgb("navy"))
p = img.load()
for j in range(TH):
    for i in range(TW):
        d1 = math.hypot(i - 4.5, j - 4.5)
        d2 = math.hypot(i - 5.8, j - 3.6)
        if d1 < 2.9 and d2 > 2.4:
            p[i, j] = rgb("white")
for (i, j) in ((11, 2), (13, 6), (9, 8), (2, 10), (14, 11)):
    p[i, j] = rgb("cyan")
    p[min(TW - 1, i + 1), j] = rgb("cyan")
for i in range(TW):
    h = 3 + (1 if (i // 3) % 2 else 0) + (1 if i in (6, 7) else 0)
    for j in range(TH - h, TH):
        p[i, j] = rgb("blue")
img.save("textures/night.png")

# dartboard: 0.46 m across, 24 x 24 texels (0.019 m: finer than the splats on purpose; the bake is
# finer there too). Black rim with peach wire numbers ring, 12 sectors alternating black and peach,
# a red and green double and treble ring, a green outer bull and a red bull.
TW = 24
img = Image.new("RGB", (TW, TW), rgb("black"))
p = img.load()
for j in range(TW):
    for i in range(TW):
        x, y = (i + 0.5) / TW * 2 - 1, (j + 0.5) / TW * 2 - 1
        r = math.hypot(x, y)
        a = (math.atan2(y, x) / (2 * math.pi) * 12 + 0.5) % 12
        k = int(a) % 2
        c = "black"
        if r < 0.12:
            c = "red"
        elif r < 0.24:
            c = "green"
        elif r < 0.78:
            c = "peach" if k else "black"
            if 0.44 < r < 0.56:
                c = "red" if k else "green"
        elif r < 0.9:
            c = "red" if k else "green"
        p[i, j] = rgb(c)
img.save("textures/dartboard.png")

# ---------------------------------------------------------------- the room
files["floor"] = """# Floor: the pub's wooden boards, 6.6 x 3.6 m, top at z 0, from 1.15 m behind the table's centre
# (the back wall) to 2.45 m in front of it. Generated by make_env.py. Up Z, front -Y.
new
material new Boards --base-color 1 1 1 --no-slot
material texture Boards base-color textures/boards.png
add mesh cube --name Floor --size 1 --location 0 -0.65 -0.05
scale 6.6 3.6 0.1
apply --scale
material assign Boards
mode edit
select face where "normal.z < 0.9"
delete only-faces
select all
uv project-from-view top --scale-to-bounds
mode object
shade flat
export floor.glb
"""

files["wall"] = """# The back wall, its front face at y 0 (the scene puts it 1.15 m behind the table): navy-blue
# wallpaper from 0.9 to 2.6 m over a wooden wainscot 4 cm proud, with a moulded rail on top.
# Generated by make_env.py. Up Z, front -Y, origin on the floor under the middle of the wall.
new
material new Paper --base-color 1 1 1 --no-slot
material texture Paper base-color textures/paper.png
material new Panel --base-color 1 1 1 --no-slot
material texture Panel base-color textures/panel.png
material new Rail """ + col("brown") + """ --no-slot
""" + box("Paper", -3.3, 3.3, 0, 0.1, 0.9, 2.6) + """material assign Paper
""" + edit("Paper", 'select face where "normal.y > -0.9"', "delete only-faces", "select all",
           "uv project-from-view front --scale-to-bounds") + box("Panel", -3.3, 3.3, -0.04, 0.06, 0, 0.9) + """material assign Panel
""" + edit("Panel", 'select face where "normal.y > -0.9"', "delete only-faces", "select all",
           "uv project-from-view front --scale-to-bounds") + box("Rail", -3.3, 3.3, -0.08, 0.0, 0.86, 0.95) + """material assign Rail
""" + edit("Rail", 'select face where "normal.y > 0.9 || normal.z < -0.9 || abs(normal.x) > 0.9"', "delete only-faces") + """select Paper Panel Rail
active Paper
join
shade flat
export wall.glb
"""

# window: 0.8 wide, 0.9 tall, its panes 3 cm behind the frame's front; a sill below
files["window"] = """# A window in the back wall: a wooden frame (sides, head, sill, a cross of glazing bars) and the
# night outside (textures/night.png, unlit in the scene). Generated by make_env.py. Up Z, front -Y,
# origin at the bottom middle, on the wall's face.
new
material new Night --base-color 1 1 1 --no-slot
material texture Night base-color textures/night.png
material new Frame """ + col("brown") + """ --no-slot
""" + box("Panes", -0.33, 0.33, -0.01, 0.0, 0.08, 0.86) + """material assign Night
""" + edit("Panes", 'select face where "normal.y > -0.9"', "delete only-faces", "select all",
           "uv project-from-view front --scale-to-bounds") + \
    box("SideL", -0.40, -0.33, -0.06, 0.0, 0.0, 0.94) + box("SideR", 0.33, 0.40, -0.06, 0.0, 0.0, 0.94) + \
    box("Head", -0.40, 0.40, -0.06, 0.0, 0.86, 0.94) + box("Sill", -0.46, 0.46, -0.11, 0.0, 0.0, 0.08) + \
    box("BarV", -0.025, 0.025, -0.05, -0.01, 0.08, 0.86) + box("BarH", -0.33, 0.33, -0.05, -0.01, 0.45, 0.50) + \
    """select SideL SideR Head Sill BarV BarH
material assign Frame
select Panes SideL SideR Head Sill BarV BarH
active SideL
join
""" + edit("SideL", 'select face where "normal.y > 0.9"', "delete only-faces") + """shade flat
export window.glb
"""

files["dart"] = """# A dartboard on a square backboard: the board a 16-sided disc 0.46 m across, 5 cm thick, its face
# textured (textures/dartboard.png); the backboard maroon, 0.62 m square. Generated by make_env.py.
# Up Z, front -Y, origin at the board's centre on the wall.
new
material new Board --base-color 1 1 1 --no-slot
material texture Board base-color textures/dartboard.png
material new Back """ + col("maroon") + """ --no-slot
material new Rim """ + col("black") + """ --no-slot
""" + box("Back", -0.31, 0.31, -0.03, 0.0, -0.31, 0.31) + """material assign Back
""" + edit("Back", 'select face where "normal.y > 0.9"', "delete only-faces") + """add mesh cylinder --name Disc --vertices 16 --radius 0.23 --depth 0.05 --location 0 -0.055 0
set rotation 90 0 0
apply --rotation
material assign Rim
""" + edit("Disc", 'select face where "normal.y > 0.9"', "delete only-faces",
           'select face where "normal.y < -0.9"', "material assign Board", "uv project-from-view front --scale-to-bounds") + \
    """select Back Disc
active Back
join
shade flat
export dart.glb
"""

# neon: a crescent moon (two arcs of tube) and a four-point star, 4.5 cm tubes, on the wall
nl = ["# The pub's neon sign: a crescent moon and a star, 4.5 cm tubes standing 3 cm off the wall (unlit",
      "# in the scene). Generated by make_env.py. Up Z, front -Y, origin at the moon's centre on the wall.",
      "new", f"material new Tube {col('pink')} --no-slot"]
names = []
def tube(name, x0, z0, x1, z1, w=0.045):
    L = math.hypot(x1 - x0, z1 - z0)
    a = math.degrees(math.atan2(z1 - z0, x1 - x0))
    names.append(name)
    return (f"add mesh cube --name {name} --size 1 --location {(x0 + x1) / 2:.4f} -0.05 {(z0 + z1) / 2:.4f}\n"
            f"scale {L + w * 0.8:.4f} {w:.4f} {w:.4f}\napply --scale\nset rotation 0 {-a:.3f} 0\napply --rotation\n")
k = 0
for (r, c0, a0, a1, n) in ((0.22, (0, 0), 60, 300, 8), (0.17, (0.09, 0.0), 75, 285, 6)):
    for s in range(n):
        t0 = math.radians(a0 + (a1 - a0) * s / n)
        t1 = math.radians(a0 + (a1 - a0) * (s + 1) / n)
        nl.append(tube(f"T{k}", c0[0] + r * math.cos(t0), c0[1] + r * math.sin(t0),
                       c0[0] + r * math.cos(t1), c0[1] + r * math.sin(t1)))
        k += 1
sx, sz = 0.26, 0.17
nl.append(tube("S0", sx - 0.09, sz, sx + 0.09, sz))
nl.append(tube("S1", sx, sz - 0.09, sx, sz + 0.09))
nl.append(f"select {' '.join(names)}\nmaterial assign Tube\nactive T0\njoin\nshade flat\nexport neon.glb\n")
files["neon"] = "\n".join(nl)

# ---------------------------------------------------------------- furniture
files["stool"] = """# A bar stool: a round red leather seat (10 sides, 0.38 m across) at 0.72 m, three wooden legs
# splayed a little, a wooden footring. Generated by make_env.py. Up Z, origin on the floor.
new
material new Seat """ + col("red") + """ --no-slot
material new Wood """ + col("brown") + """ --no-slot
add mesh cylinder --name Seat --vertices 10 --radius 0.19 --depth 0.09 --location 0 0 0.715
material assign Seat
""" + "".join(
    f"add mesh cube --name L{i} --size 1 --location {0.13 * math.cos(math.radians(90 + 120 * i)):.4f} "
    f"{0.13 * math.sin(math.radians(90 + 120 * i)):.4f} 0.335\nscale 0.05 0.05 0.68\napply --scale\n"
    f"set rotation {-5 * math.sin(math.radians(90 + 120 * i)):.3f} {5 * math.cos(math.radians(90 + 120 * i)):.3f} 0\napply --rotation\n"
    for i in range(3)) + """add mesh cylinder --name Ring --vertices 10 --radius 0.15 --depth 0.04 --location 0 0 0.26
select L0 L1 L2 Ring
material assign Wood
""" + edit("Ring", 'select face where "abs(normal.z) > 0.9"', "delete only-faces") + """select Seat L0 L1 L2 Ring
active Seat
join
""" + edit("Seat", 'select face where "normal.z < -0.9"', "delete only-faces") + """shade flat
export stool.glb
"""

files["sidetable"] = """# A round pub table (0.56 m across, 0.7 m tall) on a pedestal and cross foot, with a pint of ale
# (an orange glass with a white head) on a peach coaster. Generated by make_env.py. Up Z, origin on
# the floor.
new
material new Top """ + col("brown") + """ --no-slot
material new Foot """ + col("maroon") + """ --no-slot
material new Ale """ + col("orange") + """ --no-slot
material new Head """ + col("white") + """ --no-slot
material new Coaster """ + col("peach") + """ --no-slot
add mesh cylinder --name Top --vertices 12 --radius 0.28 --depth 0.05 --location 0 0 0.675
material assign Top
add mesh cylinder --name Post --vertices 6 --radius 0.05 --depth 0.62 --location 0 0 0.34
""" + box("FootA", -0.25, 0.25, -0.04, 0.04, 0, 0.05) + box("FootB", -0.04, 0.04, -0.25, 0.25, 0, 0.05) + """select Post FootA FootB
material assign Foot
add mesh cylinder --name Coaster --vertices 8 --radius 0.07 --depth 0.012 --location 0.08 -0.05 0.706
material assign Coaster
add mesh cylinder --name Ale --vertices 8 --radius 0.045 --depth 0.13 --location 0.08 -0.05 0.777
material assign Ale
add mesh cylinder --name Head --vertices 8 --radius 0.05 --depth 0.035 --location 0.08 -0.05 0.86
material assign Head
select Top Post FootA FootB Coaster Ale Head
active Top
join
""" + edit("Top", 'select face where "normal.z < -0.9 && pos.z < 0.02"', "delete only-faces") + """shade flat
export sidetable.glb
"""

# Biscuit the cat: an orange loaf asleep, curled on a stool seat (origin on the seat's top)
files["cat"] = """# Biscuit, the pub cat: an orange loaf asleep (body, head, two ears, a peach muzzle), about 0.42 m
# long. The tail is its own model (tail.txt), a game bone. Generated by make_env.py. Up Z, front -Y,
# origin on the surface it lies on.
new
material new Fur """ + col("orange") + """ --no-slot
material new Muzzle """ + col("peach") + """ --no-slot
material new Ear """ + col("brown") + """ --no-slot
add mesh ico-sphere --name Body --subdivisions 1 --radius 0.5 --location 0 0 0
scale 0.36 0.26 0.2
apply --scale
set location 0.02 0 0.095
material assign Fur
add mesh ico-sphere --name Head --subdivisions 1 --radius 0.5 --location 0 0 0
scale 0.17 0.16 0.14
apply --scale
set location -0.17 -0.06 0.13
material assign Fur
add mesh cone --name EarL --vertices 4 --radius1 0.04 --radius2 0.004 --depth 0.07 --location -0.2 -0.02 0.215
material assign Ear
add mesh cone --name EarR --vertices 4 --radius1 0.04 --radius2 0.004 --depth 0.07 --location -0.14 -0.1 0.215
material assign Ear
add mesh ico-sphere --name Muzzle --subdivisions 1 --radius 0.5 --location 0 0 0
scale 0.07 0.07 0.05
apply --scale
set location -0.235 -0.11 0.11
material assign Muzzle
select Body Head EarL EarR Muzzle
active Body
join
shade flat
export cat.glb
"""

files["tail"] = """# Biscuit's tail: a curled tube of three segments, its root at the origin (the pivot it flicks on),
# lying along +X. Generated by make_env.py. Up Z, front -Y.
new
material new Fur """ + col("orange") + """ --no-slot
material new Tip """ + col("peach") + """ --no-slot
""" + box("T0", 0.0, 0.12, -0.025, 0.025, 0.0, 0.05) + \
    "add mesh cube --name T1 --size 1 --location 0.16 -0.04 0.025\nscale 0.1 0.05 0.05\napply --scale\nset rotation 0 0 -35\napply --rotation\n" + \
    "add mesh cube --name T2 --size 1 --location 0.21 -0.11 0.025\nscale 0.09 0.05 0.05\napply --scale\nset rotation 0 0 -75\napply --rotation\n" + \
    """select T0 T1
material assign Fur
select T2
material assign Tip
select T0 T1 T2
active T0
join
shade flat
export tail.glb
"""

# ---------------------------------------------------------------- game pieces
files["cue"] = """# The cue: 1.1 m, its chalked tip at the origin and its butt along +Y (glTF -Z: the game turns it
# with yaw so the tip points along the shot). Peach maple shaft tapering 0.014 -> 0.02 m, a maroon
# butt to 0.027 m, a blue chalked tip. Exaggerated thick to read at the texel. Generated by make_env.py.
new
material new Shaft """ + col("peach") + """ --no-slot
material new Butt """ + col("maroon") + """ --no-slot
material new Tip """ + col("blue") + """ --no-slot
add mesh cone --name Tip --vertices 6 --radius1 0.013 --radius2 0.014 --depth 0.03 --location 0 0 0.015
material assign Tip
add mesh cone --name Shaft --vertices 6 --radius1 0.014 --radius2 0.02 --depth 0.67 --location 0 0 0.365
material assign Shaft
add mesh cone --name Butt --vertices 6 --radius1 0.021 --radius2 0.027 --depth 0.4 --location 0 0 0.9
material assign Butt
select Tip Shaft Butt
active Shaft
join
apply --location
set rotation -90 0 0
apply --rotation
shade flat
export cue.glb
"""

def ball(name, body, spot):
    return f"""# A ball: 9 cm across (pixel-art large on a 2 x 1 m table), a 10 x 6 faceted sphere in {body},
# a {spot} spot at each pole (the top and bottom rings) so its rolling shows. Centred on the origin
# (the pivot it rolls about). Generated by make_env.py.
new
material new Body {col(body)} --no-slot
material new Spot {col(spot)} --no-slot
add mesh uv-sphere --name Ball --segments 10 --rings 6 --radius 0.045 --location 0 0 0
material assign Body
""" + edit("Ball", 'select face where "abs(pos.z) > 0.034"', "material assign Spot") + f"""shade flat
export {name}.glb
"""

files["ball_cue"] = ball("ball_cue", "white", "red")
files["ball_sun"] = ball("ball_sun", "yellow", "white")
files["ball_moon"] = ball("ball_moon", "cyan", "white")
files["ball_night"] = ball("ball_night", "navy", "white")

files["chalk"] = """# A cube of blue chalk, 4 cm, left on the rail. Generated by make_env.py.
new
material new Chalk """ + col("blue") + """ --no-slot
""" + box("Chalk", -0.02, 0.02, -0.02, 0.02, 0, 0.04) + """material assign Chalk
""" + edit("Chalk", 'select face where "normal.z < -0.9"', "delete only-faces") + """shade flat
export chalk.glb
"""

for k, v in files.items():
    with open(f"{k}.txt", "w") as f:
        f.write(v)
print("wrote", " ".join(f"{k}.txt" for k in files), "and textures/")
