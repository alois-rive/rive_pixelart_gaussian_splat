# Writes Hoop Alley's hedra command files (every model but the hero hoop) and the drawn textures.
# Run from models/env: /usr/bin/python3 make_env.py. Sizes are given in WORLD metres (Y up, the hoop
# towards -Z, the shooter's end towards +Z) and converted to hedra (up Z, front -Y): hedra (x, y, z) =
# world (X, -Z, Y). Colours are exact DinoKnight 16 hexes, so the bake snaps with colour error 0.
#
#   court.txt    the asphalt court (painted lines, a purple key, the six shooting spots): textures/court.png
#   walls.txt    the back wall (bricks, two murals) and the two side walls (bricks, murals, a door),
#                their copings, the hoop's sliding rail, two wall lamps: textures/back.png, left.png, right.png
#   lights.txt   three strings of bulbs zigzagging over the alley (wires; bulbs in three unlit colours)
#   bench.txt    a slatted bench on the left wall with a boombox
#   vend.txt     a vending machine on the right wall (a lit window of cans, a lit header)
#   rack.txt     the ball cart that rolls beside the shooter (game bone `rack`)
#   ball.txt     the ball (pool `ball`) and the glowing ON FIRE ball (pool `fire`): ball.glb, fire.glb
#   spark.txt    a spark (pools `spark`, `ember`)
#   shooter.txt  Juno, the shooter, in posable parts: body.glb, head.glb, arm.glb (bones body, head, arm0, arm1)
import math
import os
import random

from PIL import Image

HEX = {"black": "0f151b", "ink": "292732", "slate": "535867", "grey": "95928f", "white": "f1f1ea",
       "tan": "c58d65", "brown": "8d5242", "dbrown": "513d3d", "yellow": "ecd56d", "orange": "ea7730",
       "red": "cd3d3d", "purple": "7c3f8c", "navy": "304271", "blue": "0083c8", "green": "47a44d",
       "dgreen": "1f6143"}


def rgb(n):
    h = HEX[n]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def col(n):
    return "--base-color " + " ".join(f"{c / 255:.4f}" for c in rgb(n))


def mat(name, colour):
    return f"material new {name} {col(colour) if colour else '--base-color 1 1 1'} --no-slot"


def wbox(name, x0, x1, y0, y1, z0, z1, m=None):
    """a box given in world metres (X x0..x1, Y y0..y1, Z z0..z1)"""
    out = [f"add mesh cube --name {name} --size 1 --location {(x0 + x1) / 2:.4f} {-(z0 + z1) / 2:.4f} {(y0 + y1) / 2:.4f}",
           f"scale {x1 - x0:.4f} {z1 - z0:.4f} {y1 - y0:.4f}", "apply --scale"]
    if m:
        out.append(f"material assign {m}")
    return out


def beam(name, a, b, w, m=None):
    """a square beam w thick from world point a to b"""
    ha = (a[0], -a[2], a[1])
    hb = (b[0], -b[2], b[1])
    d = [hb[i] - ha[i] for i in range(3)]
    L = math.sqrt(sum(v * v for v in d))
    c = [(ha[i] + hb[i]) / 2 for i in range(3)]
    ux, uy, uz = (v / L for v in d)
    ta = math.degrees(math.acos(max(-1, min(1, uz))))
    tb = math.degrees(math.atan2(ux, -uy)) if abs(ta) > 1e-6 else 0.0
    out = [f"add mesh cube --name {name} --size 1 --location {c[0]:.4f} {c[1]:.4f} {c[2]:.4f}",
           f"scale {w} {w} {L:.4f}", "apply --scale", f"set rotation {ta:.3f} 0 {tb:.3f}", "apply --rotation"]
    if m:
        out.append(f"material assign {m}")
    return out


def write(name, lines):
    with open(name + ".txt", "w") as f:
        f.write("\n".join(lines) + "\n")


def keep_faces(obj, expr):
    """delete every face of obj but those matching expr (hedra-local normals)"""
    return [f"select {obj}", f"active {obj}", "mode edit", f"select face where \"!({expr})\"", "delete face",
            "mode object"]


os.makedirs("textures", exist_ok=True)

# ---------------------------------------------------------------- the court
# X -4.6..4.6, Z -1.52..11 (the back wall's face to past the camera), 0.075 m a texel: 123 x 167.
# Row 0 is the far end (Z -1.52): hedra's top view has its -Y (world +Z) at the bottom.
CX0, CX1, CZ0, CZ1, CT = -4.6, 4.6, -1.52, 11.0, 0.075
CW, CH = round((CX1 - CX0) / CT), round((CZ1 - CZ0) / CT)
SPOTS = [(0.0, 4.0), (-1.8, 3.6), (1.8, 3.6), (-2.6, 5.4), (2.6, 5.4), (0.0, 6.2)]   # the game's spots


def court_tex(path):
    rnd = random.Random(11)
    im = Image.new("RGB", (CW, CH), rgb("slate"))
    px = im.load()

    def put(X, Z, c):
        i, j = int((X - CX0) / CT), int((Z - CZ0) / CT)
        if 0 <= i < CW and 0 <= j < CH:
            px[i, j] = c
    # worn patches (dark) and grit (light), each at least 2 x 2 texels
    for _ in range(60):
        cx, cy, r = rnd.randrange(CW), rnd.randrange(CH), rnd.uniform(1.2, 3.2)
        c = rgb("ink")
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            for x in range(int(cx - r * 1.6) - 1, int(cx + r * 1.6) + 2):
                if 0 <= x < CW and 0 <= y < CH and ((x - cx) / 1.6) ** 2 + (y - cy) ** 2 <= r * r:
                    px[x, y] = c
    for _ in range(90):
        x, y = rnd.randrange(CW - 1), rnd.randrange(CH - 1)
        for dx in (0, 1):
            for dy in (0, 1):
                px[x + dx, y + dy] = rgb("grey")
    # the key: purple, X -1.5..1.5 from the baseline (Z -1.1) to the free-throw line (Z 3.6)
    for j in range(CH):
        for i in range(CW):
            X, Z = CX0 + (i + 0.5) * CT, CZ0 + (j + 0.5) * CT
            if -1.5 <= X <= 1.5 and -1.1 <= Z <= 3.6:
                px[i, j] = rgb("purple")
    w = rgb("white")
    lw = 0.15                                  # two texels
    for j in range(CH):
        for i in range(CW):
            X, Z = CX0 + (i + 0.5) * CT, CZ0 + (j + 0.5) * CT
            r = math.hypot(X, Z)
            on = False
            if abs(Z - (-1.1)) < lw / 2 and abs(X) <= 4.4:                       # baseline
                on = True
            if -1.1 <= Z <= 3.6 and (abs(abs(X) - 1.5) < lw / 2):               # the key's sides
                on = True
            if abs(Z - 3.6) < lw / 2 and abs(X) <= 1.5:                         # free-throw line
                on = True
            if Z >= 3.6 and abs(math.hypot(X, Z - 3.6) - 1.2) < lw / 2:         # free-throw circle
                on = True
            zarc = math.sqrt(5.2 ** 2 - 4.0 ** 2)
            if -1.1 <= Z <= zarc and abs(abs(X) - 4.0) < lw / 2:                # the 3-point corners
                on = True
            if Z >= zarc and abs(r - 5.2) < lw / 2:                             # the 3-point arc
                on = True
            if abs(Z - 10.4) < lw / 2:                                          # half-court
                on = True
            if on:
                px[i, j] = w
    # the six spots: blue discs 0.3 m across (orange ones read as loose balls)
    for (sx, sz) in SPOTS:
        for j in range(CH):
            for i in range(CW):
                X, Z = CX0 + (i + 0.5) * CT, CZ0 + (j + 0.5) * CT
                if math.hypot(X - sx, Z - sz) < 0.17:
                    px[i, j] = rgb("blue")
    # a drain grate by the left wall
    for j in range(CH):
        for i in range(CW):
            X, Z = CX0 + (i + 0.5) * CT, CZ0 + (j + 0.5) * CT
            if -4.45 <= X <= -3.95 and 6.0 <= Z <= 6.6:
                px[i, j] = rgb("black") if (i % 2 == 0) else rgb("ink")
    im.save(path)


court_tex("textures/court.png")
write("court", [
    "# The court: asphalt X -4.6..4.6, Z -1.52..11 (world), one quad textured from above with",
    "# textures/court.png (0.075 m a texel): worn patches, white lines, a purple key, the six blue",
    "# shooting spots, a drain. Generated by make_env.py.", "new",
    f"add mesh grid --name Court --size 1 --x-subdivisions 4 --y-subdivisions 6 --location {(CX0 + CX1) / 2} {-(CZ0 + CZ1) / 2} 0",
    f"scale {CX1 - CX0} {CZ1 - CZ0} 1", "apply --scale", mat("Court", None), "material assign Court",
    "active Court", "mode edit", "select all", "uv project-from-view top --scale-to-bounds", "mode object",
    "material texture Court base-color textures/court.png", "shade flat", "export court.glb"])

# ---------------------------------------------------------------- walls
WT = 0.12                                       # wall texel (bricks 4 x 2 texels, mortar 1)


def bricks(w, h, seed):
    rnd = random.Random(seed)
    im = Image.new("RGB", (w, h), rgb("dbrown"))
    px = im.load()
    for y in range(h):
        course = y // 3
        if y % 3 == 2:
            continue                           # the mortar row
        off = 2 if course % 2 else 0
        for x in range(w):
            k = (x + off) // 4
            if (x + off) % 4 == 3:
                continue                       # the mortar joint
            r = random.Random(seed * 1000 + course * 97 + k).random()
            px[x, y] = rgb("brown") if r < 0.78 else (rgb("tan") if r < 0.9 else rgb("dbrown"))
    return im


def disc(px, w, h, cx, cy, r, c, ry=None):
    ry = ry or r
    for y in range(h):
        for x in range(w):
            if ((x + 0.5 - cx) / r) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1:
                px[x, y] = c


def panel(px, x0, y0, x1, y1, c):
    for y in range(y0, y1):
        for x in range(x0, x1):
            px[x, y] = c


# back wall: X -4.6..4.6, Y 0..5.6 -> 77 x 47 texels, row 0 at the top
BW, BH = 77, 47
im = bricks(BW, BH, 3)
p = im.load()
# left mural: a setting sun over purple hills, framed in ink (texels x 3..26, y 6..36)
panel(p, 3, 6, 27, 37, rgb("ink"))
panel(p, 4, 7, 26, 36, rgb("navy"))
disc(p, BW, BH, 15, 20, 8.5, rgb("orange"))
disc(p, BW, BH, 15, 20, 6.0, rgb("yellow"))
for y in range(7, 36):                         # sun stripes
    if y in (22, 25, 28):
        for x in range(4, 26):
            if p[x, y] in (rgb("orange"), rgb("yellow")):
                p[x, y] = rgb("navy")
for x in range(4, 26):                         # hills
    top = 27 + int(3 * math.sin(x * 0.45)) - (4 if 9 <= x <= 16 else 0)
    for y in range(top, 36):
        p[x, y] = rgb("purple")
# right mural: a great blue wave with white crests and three stars (texels x 50..74)
panel(p, 50, 6, 74, 37, rgb("ink"))
panel(p, 51, 7, 73, 36, rgb("navy"))
for x in range(51, 73):
    top = 20 + int(5 * math.sin((x - 51) * 0.38))
    for y in range(top, 36):
        p[x, y] = rgb("blue")
    p[x, top] = rgb("white")
    if (x - 51) % 8 in (2, 3):
        p[x, top + 1] = rgb("white")
for sx, sy in ((55, 10), (63, 13), (69, 9)):
    for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1), (-1, 0), (2, 1), (0, -1), (1, 2)):
        p[sx + dx, sy + dy] = rgb("yellow")
im.save("textures/back.png")

# side walls: Z -1.52..9.5, Y 0..4.6 -> 92 x 38 texels; the left wall seen from +X (row 0 top, column 0
# at the far end Z -1.52); the right wall seen from -X (column 0 at the near end, mirrored when projected)
SW, SH = 92, 38
im = bricks(SW, SH, 5)
p = im.load()
# left: a long green vine mural with big leaves (columns 14..60), a navy door (columns 64..72)
panel(p, 14, 5, 60, 24, rgb("ink"))
panel(p, 15, 6, 59, 23, rgb("dgreen"))
for x in range(15, 59):
    y = 14 + int(4 * math.sin(x * 0.3))
    p[x, y] = rgb("yellow")
    if x % 7 == 0:
        disc(p, SW, SH, x + 1.5, y - 3 if (x // 7) % 2 else y + 3, 2.6, rgb("green"), 1.6)
panel(p, 64, 15, 73, 38, rgb("ink"))
panel(p, 65, 16, 72, 38, rgb("navy"))
panel(p, 70, 26, 71, 28, rgb("yellow"))
im.save("textures/left.png")
im = bricks(SW, SH, 7)
p = im.load()
# right (as seen from the court, column 0 at the far end): purple peaks and stars (columns 22..62)
panel(p, 22, 4, 62, 24, rgb("ink"))
panel(p, 23, 5, 61, 23, rgb("navy"))
for x in range(23, 61):
    h = abs(((x - 23) % 12) - 6)
    for y in range(11 + h, 23):
        p[x, y] = rgb("purple") if ((x - 23) // 12) % 2 == 0 else rgb("blue")
for sx, sy in ((27, 7), (40, 8), (53, 6), (58, 9)):
    for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
        p[sx + dx, sy + dy] = rgb("yellow")
im.transpose(Image.FLIP_LEFT_RIGHT).save("textures/right.png")

L = ["# The alley's walls: the back wall (face at world Z -1.52, 9.2 x 5.6 m) and the side walls (faces at",
     "# X -4.6 and 4.6, Z -1.52..9.5, 4.6 m tall), only their court-side faces kept, textured with drawn",
     "# bricks and murals (0.12 m a texel); copings; the hoop's sliding rail; a lamp over the door and one",
     "# on the right wall (unlit in the bake). Generated by make_env.py.", "new",
     mat("Back", None), mat("Left", None), mat("Right", None), mat("Coping", "ink"), mat("Rail", "slate"),
     mat("Lamp", "yellow"), mat("LampBox", "ink")]
L += wbox("BackWall", -4.6, 4.6, 0, 5.6, -1.62, -1.52, "Back")
L += keep_faces("BackWall", "normal.y < -0.9")
L += ["select BackWall", "active BackWall", "mode edit", "select all", "uv project-from-view front --scale-to-bounds",
      "mode object"]
L += wbox("LeftWall", -4.7, -4.6, 0, 4.6, -1.52, 9.5, "Left")
L += keep_faces("LeftWall", "normal.x > 0.9")
L += ["select LeftWall", "active LeftWall", "mode edit", "select all", "uv project-from-view right --scale-to-bounds",
      "mode object"]
L += wbox("RightWall", 4.6, 4.7, 0, 4.6, -1.52, 9.5, "Right")
L += keep_faces("RightWall", "normal.x < -0.9")
L += ["select RightWall", "active RightWall", "mode edit", "select all", "uv project-from-view left --scale-to-bounds",
      "mode object"]
L += wbox("CapBack", -4.7, 4.7, 5.6, 5.76, -1.66, -1.4, "Coping")
L += keep_faces("CapBack", "normal.y < -0.9 || normal.z < -0.9")
L += wbox("CapLeft", -4.7, -4.48, 4.6, 4.76, -1.52, 9.5, "Coping")
L += keep_faces("CapLeft", "normal.x > 0.9 || normal.z < -0.9")
L += wbox("CapRight", 4.48, 4.7, 4.6, 4.76, -1.52, 9.5, "Coping")
L += keep_faces("CapRight", "normal.x < -0.9 || normal.z < -0.9")
L += wbox("Rail", -2.6, 2.6, 3.27, 3.53, -1.52, -1.4, "Rail")
L += keep_faces("Rail", "normal.y > -0.9")
# lamps: a dark box with a lit underside panel, over the left door (Z 4.8) and on the right wall (Z 2.6)
for nm, x0, x1, z in (("LampL", -4.6, -4.38, 4.85), ("LampR", 4.38, 4.6, 2.6)):
    L += wbox(nm + "Box", x0, x1, 3.0, 3.18, z - 0.22, z + 0.22, "LampBox")
    L += wbox(nm, x0 + (0.04 if x0 < 0 else -0.04), x1 + (0.04 if x0 < 0 else -0.04), 2.9, 3.0, z - 0.18, z + 0.18, "Lamp")
L += ["material texture Back base-color textures/back.png", "material texture Left base-color textures/left.png",
      "material texture Right base-color textures/right.png", "select all", "shade flat", "export walls.glb"]
write("walls", L)

# ---------------------------------------------------------------- string lights
STRANDS = [((-4.55, -0.9), (4.55, 0.9)), ((4.55, 0.9), (-4.55, 2.7)), ((-4.55, 2.7), (4.55, 4.5))]
TOPY, SAG = 4.5, 0.5
L = ["# Three strings of bulbs zigzagging across the alley, 4.45 m up on the walls, sagging 0.55 m: wire",
     "# segments (ink) and bulbs every ~0.5 m hanging under them in three unlit colours. Generated by make_env.py.",
     "new", mat("Wire", "ink"), mat("BulbY", "yellow"), mat("BulbO", "orange"), mat("BulbB", "blue")]
names = []
bi = 0
for s, ((xa, za), (xb, zb)) in enumerate(STRANDS):
    def pt(t):
        return (xa + (xb - xa) * t, TOPY - SAG * 4 * t * (1 - t), za + (zb - za) * t)
    n = 12
    for k in range(n):
        nm = f"W{s}_{k}"
        L += beam(nm, pt(k / n), pt((k + 1) / n), 0.04, "Wire")
        names.append(nm)
    length = math.hypot(xb - xa, zb - za)
    nb = int(length / 0.5)
    for k in range(1, nb):
        t = k / nb
        x, y, z = pt(t)
        m = ("BulbY", "BulbO", "BulbY", "BulbB")[bi % 4]
        bi += 1
        nm = f"B{s}_{k}"
        L += [f"add mesh ico-sphere --name {nm} --subdivisions 1 --radius 0.06 --location {x:.4f} {-z:.4f} {y - 0.09:.4f}",
              f"material assign {m}"]
        names.append(nm)
L += ["select all", "shade flat", "export lights.glb"]
write("lights", L)

# ---------------------------------------------------------------- bench (left wall, Z 1.8..3.8)
L = ["# A bench against the left wall (X -4.55..-4.05, Z 1.8..3.8): two tan seat slats, a back slat, ink legs;",
     "# a boombox on it. Generated by make_env.py.", "new",
     mat("Wood", "tan"), mat("Leg", "ink"), mat("Box", "navy"), mat("Speaker", "ink"), mat("Dial", "yellow")]
L += wbox("Slat0", -4.52, -4.32, 0.44, 0.5, 1.8, 3.8, "Wood")
L += wbox("Slat1", -4.28, -4.06, 0.44, 0.5, 1.8, 3.8, "Wood")
L += wbox("Back", -4.58, -4.52, 0.62, 0.86, 1.8, 3.8, "Wood")
for i, z in enumerate((1.9, 2.8, 3.7)):
    L += wbox(f"LegA{i}", -4.5, -4.42, 0, 0.44, z - 0.04, z + 0.04, "Leg")
    L += wbox(f"LegB{i}", -4.16, -4.08, 0, 0.44, z - 0.04, z + 0.04, "Leg")
    L += wbox(f"Post{i}", -4.58, -4.52, 0.44, 0.86, z - 0.04, z + 0.04, "Leg")
L += wbox("Boom", -4.45, -4.15, 0.5, 0.74, 3.05, 3.55, "Box")
L += wbox("SpkA", -4.16, -4.12, 0.55, 0.69, 3.1, 3.26, "Speaker")
L += wbox("SpkB", -4.16, -4.12, 0.55, 0.69, 3.34, 3.5, "Speaker")
L += wbox("Dial", -4.16, -4.12, 0.6, 0.66, 3.27, 3.33, "Dial")
L += wbox("Handle", -4.33, -4.27, 0.74, 0.8, 3.12, 3.48, "Leg")
L += ["select all", "shade flat", "export bench.glb"]
write("bench", L)

# ---------------------------------------------------------------- vending machine (right wall, Z 0.2..1.2)
VT = 0.09
vim = Image.new("RGB", (6, 12), rgb("ink"))
p = vim.load()
cans = ("red", "yellow", "white", "orange", "blue", "green")
for row in range(3):
    for c in range(3):
        cc = rgb(cans[(row * 3 + c) % 6])
        for dy in range(3):
            p[c * 2, row * 4 + dy] = cc
os.makedirs("textures", exist_ok=True)
vim.save("textures/cans.png")
L = ["# A vending machine against the right wall (X 3.8..4.6, Z 0.2..1.2, 2.0 m tall), its front facing the",
     "# court (-X): a blue body, a lit window of cans (unlit, textures/cans.png), a lit header, an ink pay panel",
     "# and pickup flap, each stood off the front by 4 cm. Generated by make_env.py.", "new",
     mat("Body", "blue"), mat("Window", None), mat("Header", "white"), mat("Panel", "ink"), mat("Button", "red")]
L += wbox("Body", 3.8, 4.6, 0.04, 2.0, 0.2, 1.2, "Body")
L += keep_faces("Body", "normal.x < 0.9 && normal.z > -0.9")
L += wbox("Win", 3.74, 3.8, 0.75, 1.75, 0.27, 0.83, "Window")
L += ["select Win", "active Win", "mode edit", "select all", "uv project-from-view left --scale-to-bounds", "mode object"]
L += wbox("Head", 3.74, 3.8, 1.8, 1.94, 0.27, 1.13, "Header")
L += wbox("Pay", 3.74, 3.8, 0.95, 1.6, 0.9, 1.13, "Panel")
L += wbox("Btn", 3.7, 3.74, 1.3, 1.42, 0.97, 1.06, "Button")
L += wbox("Flap", 3.74, 3.8, 0.22, 0.48, 0.32, 0.78, "Panel")
L += wbox("Feet", 3.82, 4.58, 0, 0.04, 0.24, 1.16, "Panel")
L += ["material texture Window base-color textures/cans.png", "select all", "shade flat", "export vend.glb"]
write("vend", L)

# ---------------------------------------------------------------- the ball cart (game bone `rack`)
BR = 0.15
L = ["# The ball cart that rolls beside the shooter (game bone `rack`): two slate A-frames joined by rails,",
     "# small ink wheels, three balls on top and two below (ball orange, seams dark). Origin on the ground",
     "# under its middle; 0.95 m long (X), 0.5 m deep. Generated by make_env.py.", "new",
     mat("Frame", "grey"), mat("Wheel", "ink"), mat("Ball", "orange"), mat("Seam", "dbrown")]
for i, x in enumerate((-0.45, 0.45)):
    L += beam(f"FA{i}", (x, 0.08, -0.22), (x, 0.82, 0.0), 0.05, "Frame")
    L += beam(f"FB{i}", (x, 0.08, 0.22), (x, 0.82, 0.0), 0.05, "Frame")
    L += wbox(f"WA{i}", x - 0.03, x + 0.03, 0, 0.12, -0.28, -0.16, "Wheel")
    L += wbox(f"WB{i}", x - 0.03, x + 0.03, 0, 0.12, 0.16, 0.28, "Wheel")
for i, (y, z) in enumerate(((0.62, -0.1), (0.62, 0.1), (0.3, -0.16), (0.3, 0.16))):
    L += wbox(f"R{i}", -0.47, 0.47, y - 0.025, y + 0.025, z - 0.025, z + 0.025, "Frame")
balls = [(-0.3, 0.62 + BR - 0.02, 0.0), (0.0, 0.62 + BR - 0.02, 0.0), (0.3, 0.62 + BR - 0.02, 0.0),
         (-0.16, 0.3 + BR - 0.03, 0.0), (0.16, 0.3 + BR - 0.03, 0.0)]
for i, (x, y, z) in enumerate(balls):
    L += [f"add mesh uv-sphere --name Ball{i} --segments 10 --rings 7 --radius {BR} --location {x} {-z} {y}",
          "material assign Ball", f"active Ball{i}", "mode edit", "select face where \"pos.z < 0.035 && pos.z > -0.035\"",
          "material assign Seam", "mode object"]
L += ["select all", "shade flat", "export rack.glb"]
write("rack", L)

# ---------------------------------------------------------------- the ball and the ON FIRE ball
def ball_lines(out, base, seam, base_col, seam_col):
    return ["new", mat(base, base_col), mat(seam, seam_col),
            f"add mesh uv-sphere --name Ball --segments 10 --rings 7 --radius {BR} --location 0 0 0 --rotation 0 0 18",
            "apply --rotation",
            f"material assign {base}", "active Ball", "mode edit",
            "select face where \"(pos.z < 0.035 && pos.z > -0.035) || (pos.x < 0.03 && pos.x > -0.03)\"",
            f"material assign {seam}", "mode object", "shade flat", f"export {out}"]


write("ball", ["# The ball: a faceted sphere r 0.15 (exaggerated from 0.12), orange with a dark equator and a",
               "# meridian seam band so its spin reads. Origin at its centre. Generated by make_env.py."]
      + ball_lines("ball.glb", "Ball", "Seam", "orange", "dbrown"))
write("fire", ["# The ON FIRE ball: the same sphere, yellow with orange seams (glow ramp, unlit in the bake).",
               "# Generated by make_env.py."] + ball_lines("fire.glb", "Fire", "FireSeam", "yellow", "orange"))
write("spark", ["# A spark: a 0.1 m icosahedron, yellow (pool spark) and orange (pool ember), unlit in the bake.",
                "# Generated by make_env.py.", "new", mat("Spark", "yellow"), mat("Ember", "orange"),
                "add mesh ico-sphere --name Spark --subdivisions 1 --radius 0.05 --location 0 0 0",
                "material assign Spark", "shade flat", "export spark.glb --selection",
                "add mesh ico-sphere --name Ember --subdivisions 1 --radius 0.05 --location 0 0 0",
                "material assign Ember", "shade flat", "export ember.glb --selection"])

# ---------------------------------------------------------------- Juno, the shooter
# 1.62 m, built facing -Y in hedra (the GLB faces +Z; the game turns her to the hoop), seen from behind:
# white sneakers, brown legs, dark green shorts, a green sleeveless jersey with a white 5 on the back,
# a hair bun and a red headband. Parts: body (feet to neck; origin at the feet), head (origin at the
# neck top, z 1.36), arm (origin at the shoulder, hanging down -Z: 0.62 m with a yellow wristband).
num = Image.new("RGB", (8, 10), rgb("green"))
p = num.load()
FIVE = ["      ", " #### ", " #    ", " #    ", " #### ", "    # ", "    # ", " #### ", "      ", "      "]
for y, row in enumerate(FIVE):
    for x, ch in enumerate(row):
        if ch == "#":
            p[x + 1, y] = rgb("white")
num.save("textures/jersey.png")
L = ["# Juno, the shooter, in posable parts (game bones body, head, arm0, arm1). Built facing -Y; the camera",
     "# sees her back. Generated by make_env.py.", "new",
     mat("Shoe", "white"), mat("Skin", "brown"), mat("Shorts", "dgreen"), mat("Jersey", "green"),
     mat("Number", None), mat("Hair", "ink"), mat("Band", "red"), mat("Wrist", "yellow")]
H = lambda name, x0, x1, y0, y1, z0, z1, m: [  # a box in hedra coordinates
    f"add mesh cube --name {name} --size 1 --location {(x0 + x1) / 2:.4f} {(y0 + y1) / 2:.4f} {(z0 + z1) / 2:.4f}",
    f"scale {x1 - x0:.4f} {y1 - y0:.4f} {z1 - z0:.4f}", "apply --scale", f"material assign {m}"]
for s, x in (("L", -0.11), ("R", 0.11)):
    L += H(f"Shoe{s}", x - 0.075, x + 0.075, -0.2, 0.1, 0, 0.13, "Shoe")
    L += H(f"Leg{s}", x - 0.07, x + 0.07, -0.07, 0.07, 0.12, 0.52, "Skin")
L += H("Shorts", -0.23, 0.23, -0.14, 0.14, 0.48, 0.8, "Shorts")
L += H("Jersey", -0.24, 0.24, -0.14, 0.14, 0.78, 1.3, "Jersey")
L += ["active Jersey", "mode edit", "select face where \"normal.y > 0.9\"", "uv project-from-view back --scale-to-bounds",
      "material assign Number", "mode object", "material texture Number base-color textures/jersey.png"]
L += H("Neck", -0.07, 0.07, -0.06, 0.06, 1.28, 1.38, "Skin")
L += ["select ShoeL ShoeR LegL LegR Shorts Jersey Neck", "active Jersey", "join", "rename Jersey Body", "select Body", "shade flat",
      "export body.glb --selection"]
# the head: origin at the neck top (hedra z 1.36 -> moved to 0 for its own GLB)
L += ["add mesh ico-sphere --name Head --subdivisions 2 --radius 0.16 --location 0 0 0.17", "material assign Skin",
      "add mesh ico-sphere --name Hair --subdivisions 1 --radius 0.155 --location 0 0.035 0.21", "scale 1.06 1 0.95",
      "apply --scale", "material assign Hair",
      "add mesh ico-sphere --name Bun --subdivisions 1 --radius 0.085 --location 0 0.06 0.38", "material assign Hair",
      "add mesh cylinder --name Band --vertices 10 --radius 0.168 --depth 0.06 --location 0 0.005 0.22",
      "material assign Band",
      "select Head Hair Bun Band", "active Head", "join", "select Head", "shade flat", "export head.glb --selection"]
L += ["add mesh cube --name Arm --size 1 --location 0 0 -0.25", "scale 0.11 0.11 0.5", "apply --scale",
      "material assign Skin",
      "add mesh cube --name Wrist --size 1 --location 0 0 -0.46", "scale 0.125 0.125 0.07", "apply --scale",
      "material assign Wrist",
      "add mesh cube --name Hand --size 1 --location 0 0 -0.56", "scale 0.12 0.13 0.12", "apply --scale",
      "material assign Skin",
      "select Arm Wrist Hand", "active Arm", "join", "select Arm", "shade flat", "export arm.glb --selection"]
write("shooter", L)
print("wrote court walls lights bench vend rack ball fire spark shooter + textures")
