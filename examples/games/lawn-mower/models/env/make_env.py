# Writes the hedra command files of the lawn-mower garden: ground.txt (the mowed lawn's stripes under
# the tall grass, the sandy path round it, the flower borders, the two flower beds on the lawn),
# garden.txt (picket fence, shed, bushes, a birdbath, flowers), and the game's pooled pieces: tuft.txt
# (one tile of tall grass), gnome.txt, clip.txt (a grass clipping), petal.txt. Run from models/env:
# /usr/bin/python3 make_env.py. hedra: up Z, front -Y (the camera side); glTF x = hedra x,
# glTF z = -hedra y. Colours are exact Endesga 16 steps. The grid numbers are shared with game.as.
import math, random

HEX = {"light": "63c64d", "mid": "327345", "dark": "193d3f", "sand": "b86f50", "soil": "743f39",
       "white": "afbfd2", "snow": "ffffff", "slate": "4f6781", "red": "e53b44", "crimson": "9e2835",
       "orange": "fb922b", "yellow": "ffe762", "blue": "0484d1", "cyan": "2ce8f4", "skin": "e4a672",
       "plum": "3f2832", "tan": "e4a672"}
def rgb(h):
    return " ".join(f"{int(h[i:i + 2], 16) / 255:.3f}" for i in (0, 2, 4))
def mat(name, col):
    return f"material new {name} --base-color {rgb(HEX[col])} --no-slot"
def box(name, x0, x1, y0, y1, z0, z1, m):
    return [f"add mesh cube --name {name} --size 1 --location {(x0 + x1) / 2:.4f} {(y0 + y1) / 2:.4f} {(z0 + z1) / 2:.4f}",
            f"scale {x1 - x0:.4f} {y1 - y0:.4f} {z1 - z0:.4f}", "apply --scale", f"material assign {m}"]
def gbox(name, x0, x1, z0, z1, h0, h1, m):
    """a box in glTF ground coordinates: x, z (towards the camera), height h"""
    return box(name, x0, x1, -z1, -z0, h0, h1, m)
def join(names, keep):
    return ["select " + " ".join(names), f"active {keep}", "join"]
def write(fn, lines):
    open(fn, "w").write("\n".join(lines) + "\n")

# ---------------------------------------------------------------- the grid (glTF, shared with game.as)
T = 0.85; COLS = 8; ROWS = 6
X0 = -COLS * T / 2; Z0 = -ROWS * T / 2          # the lawn's back-left corner
BEDS = [(1, 1), (2, 1), (5, 4), (6, 4)]          # (col, row) tiles under the two flower beds
def cell(c, r):
    return X0 + (c + 0.5) * T, Z0 + (r + 0.5) * T

if __name__ == "__main__":
    rnd = random.Random(11)
    # ------------------------------------------------------------ ground
    g = ["# The ground: the mowed lawn (stripes by column, light and mid green) that the tall grass tiles",
         "# cover, a sandy path round it, soil borders, the two raised flower beds. make_env.py.",
         "new", mat("Light", "light"), mat("Mid", "mid"), mat("Sand", "sand"), mat("Soil", "soil"),
         mat("Edge", "white"), mat("BedSoil", "soil")]
    names = []
    for c in range(COLS):
        x = X0 + c * T
        # each column, split where a bed sits on it
        rows = [r for r in range(ROWS) if (c, r) not in BEDS]
        runs, start = [], None
        for r in range(ROWS + 1):
            if r < ROWS and r in rows:
                start = r if start is None else start
            elif start is not None:
                runs.append((start, r)); start = None
        for k, (r0, r1) in enumerate(runs):
            n = f"Stripe{c}_{k}"
            g += gbox(n, x, x + T, Z0 + r0 * T, Z0 + r1 * T, -0.12, 0.0, "Light" if c % 2 == 0 else "Mid")
            names.append(n)
    g += join(names, names[0]) + [f"rename {names[0]} Lawn"]
    # the path round the lawn, 0.55 wide, and the soil beyond it out to the fence and the frame
    PW = 0.55
    ax0, ax1, az0, az1 = X0 - PW, -X0 + PW, Z0 - PW, -Z0 + PW
    g += gbox("PathN", ax0, ax1, az0, Z0, -0.14, -0.03, "Sand")
    g += gbox("PathS", ax0, ax1, -Z0, az1, -0.14, -0.03, "Sand")
    g += gbox("PathW", ax0, X0, Z0, -Z0, -0.14, -0.03, "Sand")
    g += gbox("PathE", -X0, ax1, Z0, -Z0, -0.14, -0.03, "Sand")
    g += gbox("SoilN", -6.4, 6.4, -5.2, az0, -0.2, -0.06, "Soil")
    g += gbox("SoilS", -6.4, 6.4, az1, 5.4, -0.2, -0.06, "Soil")
    g += gbox("SoilW", -6.4, ax0, az0, az1, -0.2, -0.06, "Soil")
    g += gbox("SoilE", ax1, 6.4, az0, az1, -0.2, -0.06, "Soil")
    # the flower beds: raised soil inside a pale stone kerb (the flowers are in garden.txt)
    for i, (c0, r) in enumerate(((1, 1), (5, 4))):
        bx0, bz0 = X0 + c0 * T, Z0 + r * T
        g += gbox(f"Kerb{i}", bx0 + 0.04, bx0 + 2 * T - 0.04, bz0 + 0.04, bz0 + T - 0.04, -0.05, 0.16, "Edge")
        g += gbox(f"Bed{i}", bx0 + 0.16, bx0 + 2 * T - 0.16, bz0 + 0.16, bz0 + T - 0.16, 0.0, 0.2, "BedSoil")
    g += ["select all", "shade flat", "export ground.glb"]
    write("ground.txt", g)

    # ------------------------------------------------------------ garden: fence, shed, bushes, birdbath, flowers
    d = ["# The garden round the lawn: a white picket fence behind and at the sides, a red-roofed shed",
         "# back left, round bushes, a birdbath, flowers in the borders and the beds. make_env.py.",
         "new", mat("Fence", "white"), mat("Wood", "soil"), mat("Roof", "crimson"), mat("Bush", "mid"),
         mat("BushLit", "light"), mat("Stone", "white"), mat("Water", "blue"), mat("Red", "red"),
         mat("Yellow", "yellow"), mat("Snow", "snow"), mat("Leaf", "mid"), mat("Orange", "orange"), mat("Door", "plum")]
    pn = []
    FZ = -4.35                                     # the fence line behind the lawn
    for i in range(-11, 12):
        x = i * 0.55
        n = f"Picket{i + 11}"
        d += gbox(n, x - 0.11, x + 0.11, FZ - 0.05, FZ + 0.05, 0.0, 0.85, "Fence")
        d += [f"add mesh cone --name {n}t --vertices 4 --radius1 0.155 --radius2 0 --depth 0.18 --location {x:.3f} {-FZ:.3f} 0.94 --rotation 0 0 45",
              "scale 1 0.45 1", "material assign Fence"]
        pn += [n, n + "t"]
    d += gbox("RailHi", -6.2, 6.2, FZ + 0.05, FZ + 0.13, 0.55, 0.67, "Fence")
    d += gbox("RailLo", -6.2, 6.2, FZ + 0.05, FZ + 0.13, 0.2, 0.32, "Fence")
    for s in (-1, 1):
        for k in range(10):
            z = FZ + 0.55 + k * 0.55
            n = f"SP{'L' if s < 0 else 'R'}{k}"
            d += gbox(n, s * 5.75 - 0.05, s * 5.75 + 0.05, z - 0.11, z + 0.11, 0.0, 0.85, "Fence")
            pn.append(n)
    d += join(pn, "Picket0") + ["rename Picket0 Fence"]
    # the shed, back left (its front faces the lawn)
    d += gbox("Shed", -5.6, -4.1, -4.2, -2.9, 0.0, 1.25, "Wood")
    d += gbox("ShedDoor", -5.1, -4.6, -2.92, -2.84, 0.0, 0.95, "Door")
    d += [f"add mesh cube --name RoofL --size 1 --location -4.85 {3.55:.3f} 1.5", "scale 1.8 0.9 0.12", "apply --scale",
          "set rotation 35 0 0", "apply --rotation", "translate 0 -0.36 0", "material assign Roof",
          f"add mesh cube --name RoofR --size 1 --location -4.85 {3.55:.3f} 1.5", "scale 1.8 0.9 0.12", "apply --scale",
          "set rotation -35 0 0", "apply --rotation", "translate 0 0.36 0", "material assign Roof"]
    # round bushes: in the borders, front and sides
    bushes = [(-5.1, 2.4, 0.55), (-5.0, 0.6, 0.45), (5.0, 2.6, 0.55), (5.1, -1.2, 0.5), (4.6, -3.4, 0.7),
              (-2.6, 4.25, 0.5), (0.2, 4.4, 0.55), (3.0, 4.2, 0.48), (-5.3, -1.6, 0.4)]
    for i, (x, z, r) in enumerate(bushes):
        d += [f"add mesh ico-sphere --name Bush{i} --subdivisions 1 --radius {r:.2f} --location {x:.2f} {-z:.2f} {r * 0.75:.2f} --rotation {rnd.uniform(0, 60):.0f} {rnd.uniform(0, 60):.0f} {rnd.uniform(0, 60):.0f}",
              "scale 1 1 0.85", "material assign Bush"]
    # a birdbath on the right border
    d += [f"add mesh cylinder --name BathFoot --vertices 6 --radius 0.12 --depth 0.5 --location 5.0 -0.8 0.25", "material assign Stone",
          f"add mesh cylinder --name Bowl --vertices 8 --radius 0.38 --depth 0.12 --location 5.0 -0.8 0.55", "material assign Stone",
          f"add mesh cylinder --name Water --vertices 8 --radius 0.28 --depth 0.04 --location 5.0 -0.8 0.6", "material assign Water"]
    # flowers: small blocks in the borders (red, yellow, white) and packed in the two beds
    fl = []
    spots = []
    for k in range(34):
        while True:
            x, z = rnd.uniform(-6.0, 6.0), rnd.uniform(-4.1, 4.9)
            inside = abs(x) < -X0 + 0.65 and abs(z) < -Z0 + 0.65
            if not inside and all(math.hypot(x - a, z - b) > 0.35 for a, b in spots) \
                    and all(math.hypot(x - bx, z - bz) > br + 0.1 for bx, bz, br in bushes) \
                    and not (-5.7 < x < -4.0 and -4.3 < z < -2.8) and math.hypot(x - 5.0, z + 0.8) > 0.6:
                break
        spots.append((x, z))
    for i, (c0, r) in enumerate(((1, 1), (5, 4))):
        bx0, bz0 = X0 + c0 * T, Z0 + r * T
        for a in range(4):
            for b in range(2):
                spots.append((bx0 + 0.36 + a * 0.33 + rnd.uniform(-0.03, 0.03), bz0 + 0.3 + b * 0.27, ))
    cols = ["Red", "Yellow", "Snow", "Orange"]
    for i, (x, z) in enumerate(spots):
        top = 0.2 if i >= 34 else 0.0
        m = cols[i % 4] if i < 34 else ("Red" if (i // 2) % 2 == 0 else "Yellow")
        d += [f"add mesh cube --name Stem{i} --size 1 --location {x:.3f} {-z:.3f} {top + 0.1:.3f}", "scale 0.07 0.07 0.2", "apply --scale", "material assign Leaf",
              f"add mesh ico-sphere --name Head{i} --subdivisions 1 --radius 0.12 --location {x:.3f} {-z:.3f} {top + 0.24:.3f}", "material assign " + m]
        fl += [f"Stem{i}", f"Head{i}"]
    d += join(fl, "Stem0") + ["rename Stem0 Flowers"]
    d += ["select all", "shade flat", "export garden.glb"]
    write("garden.txt", d)

    # ------------------------------------------------------------ the tall grass tile (44 game bones)
    tf = ["# One tile of tall grass: a dark turf block 0.85 m square and 0.16 m tall with shaggy tufts on",
          "# top, origin at its centre on the ground. The game places one per lawn tile and hides it when cut.",
          "# Generated by make_env.py.", "new", mat("Turf", "dark"), mat("Tuft", "mid")]
    h = T / 2 - 0.01
    tf += box("Turf", -h, h, -h, h, 0.0, 0.16, "Turf")
    tn = []
    tr = random.Random(4)
    pts = [(-0.22, -0.2), (0.18, -0.24), (0.0, 0.02), (-0.24, 0.22), (0.22, 0.2), (0.27, -0.02), (-0.05, 0.3), (-0.3, -0.02)]
    for i, (x, y) in enumerate(pts):
        r = tr.uniform(0.1, 0.14)
        tf += [f"add mesh cone --name Tuft{i} --vertices 4 --radius1 {r:.3f} --radius2 0 --depth {tr.uniform(0.16, 0.22):.3f} --location {x:.3f} {y:.3f} {0.16 + 0.07:.3f} --rotation {tr.uniform(-12, 12):.0f} {tr.uniform(-12, 12):.0f} {tr.uniform(0, 90):.0f}",
               "material assign Tuft"]
        tn.append(f"Tuft{i}")
    tf += join(tn, "Tuft0")
    # the turf's bottom is never seen
    tf += ["select Turf", "active Turf", "mode edit", 'select face where "normal.z < -0.9"', "delete only-faces", "mode object",
           "select all", "shade flat", "export tuft.glb"]
    write("tuft.txt", tf)

    # ------------------------------------------------------------ gnome, clipping, petal
    write("gnome.txt", ["# A garden gnome 0.66 m tall, facing the camera: dark boots, a blue coat, a skin face, a white",
        "# beard, a tall red hat. Origin on the ground under it. Generated by make_env.py.",
        "new", mat("Boot", "plum"), mat("Coat", "blue"), mat("Face", "skin"), mat("Beard", "snow"), mat("Hat", "red"),
        *box("Boots", -0.15, 0.15, -0.1, 0.12, 0.0, 0.09, "Boot"),
        "add mesh cone --name Coat --vertices 6 --radius1 0.19 --radius2 0.12 --depth 0.26 --location 0 0 0.21", "material assign Coat",
        *box("Face", -0.1, 0.1, -0.11, 0.09, 0.33, 0.47, "Face"),
        "add mesh cone --name Beard --vertices 4 --radius1 0.04 --radius2 0.15 --depth 0.18 --location 0 -0.07 0.36 --rotation 0 0 45",
        "scale 1 0.7 1", "material assign Beard",
        "add mesh cone --name Hat --vertices 6 --radius1 0.15 --radius2 0.02 --depth 0.24 --location 0 0 0.58", "material assign Hat",
        "select all", "shade flat", "export gnome.glb"])
    write("clip.txt", ["# A grass clipping: a small light-green chip (the mower throws them). make_env.py.",
        "new", mat("Clip", "light"), "add mesh cube --name Clip --size 0.11", "scale 1 1 0.6", "material assign Clip", "export clip.glb"])
    write("petal.txt", ["# A petal: a small red chip (a bed hit throws them). make_env.py.",
        "new", mat("Petal", "red"), "add mesh cube --name Petal --size 0.11", "scale 1 1 0.6", "material assign Petal", "export petal.glb"])
