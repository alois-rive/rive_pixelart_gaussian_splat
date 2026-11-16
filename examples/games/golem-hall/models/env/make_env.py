#!/usr/bin/env python3
"""Writes the hall's hedra command files (every model but the hero golem, from art/assets.md) and its
drawn textures. Positions are given in the scene's glTF frame (Y up, metres; the player stands at the
origin looking down -Z) and written as hedra's (x, -z, y). Colours are exact URBEX 16 hexes, so the
bake snaps with error 0. Faces the first-person camera never sees (outer wall faces, tops above the
eye, buried caps) are deleted.

  hall.txt     floor (flagstone texture), ruined side walls with three doorways each and their dark
               passages, the far wall with the great gate and its gloom, three roof beams (one broken)
  pillar.txt   an octagonal column on a plinth, a capital, moss at its foot
  broken.txt   a broken column and its fallen drum
  brazier.txt  an iron brazier with glowing coals and its stippled pool of light (halo.png)
  flame.txt    a brazier's flame (a game bone: it flickers)
  banner.txt   a hanging purple banner
  rubble.txt   a pile of fallen blocks with moss
  bolt.txt     the player's bolt (unlit), crack.txt the golem's glowing cracks, chunk.txt a clay
               chunk, spark.txt an impact burst, staff.txt the player's staff (seen in the corner)

Run from this folder: /usr/bin/python3 make_env.py; then `hedra model --text <m>.rmdl run <m>.txt` (build.sh)."""
import math
import os
import random

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
HEX = {"pale": "cbd1be", "grey": "8f9389", "slate": "52534c", "umber": "26201d", "tan": "e0a46e",
       "sage": "91a47a", "green": "5d7643", "olive": "4d533a", "red": "a93130", "crimson": "7a1338",
       "mauve": "834664", "lilac": "917692", "night": "160712", "purple": "593084", "blue": "3870be",
       "cyan": "579fb4"}


def rgb(n):
    h = HEX[n]
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mat(name, col):
    c = " ".join(f"{v / 255:.4f}" for v in rgb(col))
    return f"material new {name} --base-color {c} --no-slot"


def H(x, y, z):
    """glTF (x, y up, z) -> hedra location (x, -z, y)"""
    return f"{x:.3f} {-z:.3f} {y:.3f}"


def box(L, name, x0, x1, y0, y1, z0, z1, m, drop=()):
    """an axis-aligned box over glTF ranges; drop: faces to delete, by glTF direction
    ('+x', '-x', '+y' top, '-y' bottom, '+z', '-z')"""
    cx, cy, cz = (x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2
    L += [f"add mesh cube --name {name} --size 1 --location {H(cx, cy, cz)}",
          f"scale {abs(x1 - x0):.3f} {abs(z1 - z0):.3f} {abs(y1 - y0):.3f}", "apply --scale",
          f"material assign {m}"]
    if drop:
        # glTF direction -> hedra normal test (hedra: x, -z, y)
        tests = {"+x": "normal.x > 0.5", "-x": "normal.x < -0.5", "+y": "normal.z > 0.5", "-y": "normal.z < -0.5",
                 "+z": "normal.y < -0.5", "-z": "normal.y > 0.5"}
        q = " || ".join(tests[d] for d in drop)
        L += [f"active {name}", "mode edit", f'select face where "{q}"', "delete face", "mode object"]


def prism(L, name, r, y0, y1, x, z, m, r2=None, n=8, turn=22.5):
    d = y1 - y0
    if r2 is None:
        L.append(f"add mesh cylinder --name {name} --vertices {n} --radius {r:.3f} --depth {d:.3f} --location {H(x, (y0 + y1) / 2, z)}")
    else:
        L.append(f"add mesh cone --name {name} --vertices {n} --radius1 {r:.3f} --radius2 {r2:.3f} --depth {d:.3f} --location {H(x, (y0 + y1) / 2, z)}")
    if turn:
        L += [f"set rotation 0 0 {turn}", "apply --rotation"]
    L.append(f"material assign {m}")


def caps(L, name, top=True, bottom=True):
    """delete a prism's caps (buried or never seen)"""
    q = []
    if top:
        q.append("normal.z > 0.9")
    if bottom:
        q.append("normal.z < -0.9")
    L += [f"active {name}", "mode edit", f'select face where "{" || ".join(q)}"', "delete face", "mode object"]


def write(name, L):
    L += ["select all", "shade flat", f"export {name}.glb"]
    open(os.path.join(HERE, name + ".txt"), "w").write("\n".join(L) + "\n")


os.makedirs(os.path.join(HERE, "textures"), exist_ok=True)

# ---------------------------------------------------------------- the layout (game.as holds the same numbers)
HW = 6.5            # the side walls' inner faces at x = +-HW
WT = 0.8            # wall thickness
Z_NEAR, Z_FAR = 4.0, -24.0
DOORS = (-3.0, -9.5, -16.5)   # side doorway centres (z), 2.4 m wide, 3.6 m tall
DW, DH = 2.4, 3.6
PASS = 2.6          # passage depth behind a doorway (beyond the wall)
GATE_W, GATE_H = 3.4, 4.6

# ---------------------------------------------------------------- textures (drawn, palette-exact)
# floor: flagstones, 0.1 m a texel, 130 x 280 over 13 x 28 m; rows 1.4 m deep along z, stones 1.2-2.4 m wide,
# joints two texels (0.2 m: two splats) of umber, stones slate, a few grey ones. Row 0 of the image is the far
# end (z -24): the top view has the front (+z) at the bottom.
rnd = random.Random(7)
FW, FH = 130, 280
fl = Image.new("RGB", (FW, FH), rgb("umber"))
y = 0
while y < FH:
    rh = 14
    x = -rnd.randint(0, 12)
    while x < FW:
        w = rnd.randint(12, 24)
        c = rgb("grey") if rnd.random() < 0.05 else rgb("slate")
        for yy in range(y, min(FH, y + rh - 2)):
            for xx in range(max(0, x), min(FW, x + w - 2)):
                fl.putpixel((xx, yy), c)
        # a crack across a few stones
        if rnd.random() < 0.18:
            cx, cy = x + rnd.randint(3, max(4, w - 6)), y + 2
            for k in range(rh - 5):
                if 0 <= cx < FW and cy + k < FH:
                    fl.putpixel((cx, cy + k), rgb("umber"))
                cx += rnd.choice((-1, 0, 0, 1))
        x += w
    y += rh
fl.save(os.path.join(HERE, "textures/floor.png"))

# halo.png: the brazier's pool of light, a stipple: 32 x 32, tan where kept, transparent elsewhere: denser in
# the middle, thinning by a 4 x 4 Bayer threshold to nothing at the rim
BAY = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
N = 32
im = Image.new("RGBA", (N, N))
for yy in range(N):
    for xx in range(N):
        d = math.hypot((xx + 0.5) / N - 0.5, (yy + 0.5) / N - 0.5) * 2
        keep = max(0.0, min(0.55, (1.0 - d) / 0.9))
        on = (BAY[(xx % 4) + (yy % 4) * 4] + 0.5) / 16 < keep
        im.putpixel((xx, yy), rgb("tan") + ((255,) if on else (0,)))
im.save(os.path.join(HERE, "textures/halo.png"))

# ---------------------------------------------------------------- hall
L = ["# The hall (generated by make_env.py): floor, ruined side walls with doorways and dark passages, the",
     "# far wall with the great gate, roof beams. glTF frame: the player at the origin looking down -Z.", "new",
     "material new Floor --base-color 1 1 1 --no-slot", mat("Wall", "slate"), mat("Dark", "umber"),
     mat("Trim", "grey"), mat("Gloom", "purple"), mat("Rune", "cyan")]
L += [f"add mesh plane --name Floor --size 1 --location {H(0, 0, (Z_NEAR + Z_FAR) / 2)}",
      f"scale {2 * HW:.3f} {Z_NEAR - Z_FAR:.3f} 1", "apply --scale", "material assign Floor",
      "active Floor", "mode edit", "select all", "uv project-from-view top --scale-to-bounds", "mode object",
      "material texture Floor base-color textures/floor.png"]
wr = random.Random(3)
k = 0
for s in (-1, 1):
    xi, xo = s * HW, s * (HW + WT)
    x0, x1 = min(xi, xo), max(xi, xo)
    outer = "+x" if s > 0 else "-x"
    # z intervals: walls between the doorways, cut into ~1 m slabs of ruined height
    edges = [Z_NEAR]
    for dz in DOORS:
        edges += [dz + DW / 2, dz - DW / 2]
    edges.append(Z_FAR)
    for i in range(0, len(edges), 2):
        za, zb = edges[i], edges[i + 1]          # za > zb
        n = max(1, round(za - zb))
        for j in range(n):
            z_hi = za - (za - zb) * j / n
            z_lo = za - (za - zb) * (j + 1) / n
            h = 6.6 + wr.uniform(-0.6, 0.7)
            if wr.random() < 0.12:
                h -= 1.3                         # a broken notch in the wall's top
            drop = [outer, "+y", "-y"]
            # slab ends: keep only a doorway's jamb
            if not (j == 0 and i > 0):
                drop.append("+z")
            if not (j == n - 1 and i < len(edges) - 2):
                drop.append("-z")
            box(L, f"W{k}", x0, x1, 0, h, z_lo, z_hi, "Wall", drop)
            k += 1
    for dz in DOORS:
        # lintel over the doorway (its underside seen), wall above it
        box(L, f"Lintel{k}", x0 - (0.15 if s < 0 else 0), x1 + (0.15 if s > 0 else 0), DH, DH + 0.7,
            dz - DW / 2 - 0.3, dz + DW / 2 + 0.3, "Trim", [outer, "+y"])
        box(L, f"W{k}", x0, x1, DH + 0.7, 6.4 + wr.uniform(-0.3, 0.5), dz - DW / 2, dz + DW / 2, "Wall",
            [outer, "+y", "-y", "+z", "-z"])
        k += 1
        # the dark passage behind: floor, two side walls, back wall, ceiling (all faces turned to the hall's side)
        pa, pb = s * (HW + WT), s * (HW + WT + PASS)
        px0, px1 = min(pa, pb), max(pa, pb)
        L += [f"add mesh plane --name PFloor{k} --size 1 --location {H((s * HW + pb) / 2, 0.0, dz)}",
              f"scale {WT + PASS:.3f} {DW:.3f} 1", "apply --scale", "material assign Dark"]
        box(L, f"PSideA{k}", px0, px1, 0, DH, dz + DW / 2, dz + DW / 2 + 0.3, "Dark", ["+z", "+y", "-y", "+x", "-x"])
        box(L, f"PSideB{k}", px0, px1, 0, DH, dz - DW / 2 - 0.3, dz - DW / 2, "Dark", ["-z", "+y", "-y", "+x", "-x"])
        box(L, f"PBack{k}", (pb if s > 0 else pb - 0.3), (pb + 0.3 if s > 0 else pb), 0, DH, dz - DW / 2, dz + DW / 2,
            "Dark", ["+z", "-z", "+y", "-y", outer])
        box(L, f"PTop{k}", px0, px1, DH, DH + 0.3, dz - DW / 2, dz + DW / 2, "Dark", ["+z", "-z", "+y", "+x", "-x"])
        k += 1
# the far wall and the great gate
FZ0, FZ1 = Z_FAR - WT, Z_FAR
box(L, "FarL", -HW - WT, -GATE_W / 2, 0, 7.4, FZ0, FZ1, "Wall", ["-z", "+y", "-y", "-x"])
box(L, "FarR", GATE_W / 2, HW + WT, 0, 7.4, FZ0, FZ1, "Wall", ["-z", "+y", "-y", "+x"])
box(L, "FarTop", -GATE_W / 2, GATE_W / 2, GATE_H, 7.4, FZ0, FZ1, "Wall", ["-z", "+y", "+x", "-x"])
for s in (-1, 1):
    jx0 = s * GATE_W / 2 if s > 0 else -GATE_W / 2 - 0.75
    jx1 = s * GATE_W / 2 + 0.75 if s > 0 else -GATE_W / 2
    box(L, f"Jamb{'LR'[s > 0]}", jx0, jx1, 0, GATE_H + 0.35, Z_FAR, Z_FAR + 0.5, "Trim", ["-z", "+y", "-y"])
box(L, "GateLintel", -GATE_W / 2 - 0.95, GATE_W / 2 + 0.95, GATE_H, GATE_H + 0.9, Z_FAR, Z_FAR + 0.6, "Trim", ["-z", "+y"])
box(L, "Keystone", -0.45, 0.45, GATE_H + 0.5, GATE_H + 1.6, Z_FAR + 0.6, Z_FAR + 0.9, "Trim", ["-z", "+y"])
# a glowing rune diamond on the keystone
L += [f"add mesh cube --name KeyRune --size 1 --location {H(0, GATE_H + 1.05, Z_FAR + 0.95)}",
      "scale 0.36 0.08 0.36", "apply --scale", "set rotation 0 45 0", "apply --rotation", "material assign Rune"]
# the gate's gloom: a passage 4 m deep, dark sides, a purple glow at its end (unlit)
L += [f"add mesh plane --name GFloor --size 1 --location {H(0, 0.0, Z_FAR - 2.4)}",
      f"scale {GATE_W:.3f} 4.8 1", "apply --scale", "material assign Dark"]
for s in (-1, 1):
    gx0 = GATE_W / 2 if s > 0 else -GATE_W / 2 - 0.3
    box(L, f"GSide{'LR'[s > 0]}", gx0, gx0 + 0.3, 0, GATE_H, Z_FAR - 4.8, FZ0, "Dark",
        ["+y", "-y", "+z", "-z", ("+x" if s > 0 else "-x")])
box(L, "GBack", -GATE_W / 2, GATE_W / 2, 0, GATE_H, Z_FAR - 5.1, Z_FAR - 4.8, "Gloom", ["-z", "+y", "-y", "+x", "-x"])
box(L, "GTop", -GATE_W / 2, GATE_W / 2, GATE_H, GATE_H + 0.3, Z_FAR - 4.8, FZ0, "Dark", ["+z", "-z", "+y", "+x", "-x"])
# roof beams across the hall (their undersides and faces seen against the night sky); the middle one broken
for name, z, xa, xb in (("BeamA", -6.0, -HW - WT, HW + WT), ("BeamB", -13.0, 0.9, HW + WT), ("BeamC", -20.0, -HW - WT, HW + WT)):
    box(L, name, xa, xb, 6.6, 7.3, z - 0.35, z + 0.35, "Trim", ["+y"])
L.append("add mesh cube --name BeamStub --size 1 --location " + H(-5.6, 6.7, -13.0))
L += ["scale 1.8 0.7 0.7", "apply --scale", "set rotation 0 -18 0", "apply --rotation", "material assign Trim"]
write("hall", L)

# ---------------------------------------------------------------- pillar
L = ["# A column (generated by make_env.py): plinth, octagonal shaft, capital, a ring of moss at its foot.",
     "# Origin on the floor at its centre.", "new", mat("Column", "grey"), mat("Trim", "slate"), mat("Moss", "green")]
box(L, "Plinth", -0.75, 0.75, 0, 0.5, -0.75, 0.75, "Trim", ["-y"])
prism(L, "Shaft", 0.55, 0.5, 6.1, 0, 0, "Column")
caps(L, "Shaft")
prism(L, "MossRing", 0.68, 0.5, 0.66, 0, 0, "Moss", r2=0.58)
caps(L, "MossRing", top=False)
box(L, "Capital", -0.7, 0.7, 6.1, 6.6, -0.7, 0.7, "Trim", ["+y"])
write("pillar", L)

# ---------------------------------------------------------------- broken pillar and its fallen drum
L = ["# A broken column and its fallen drum (generated by make_env.py). Origin on the floor at the column.", "new",
     mat("Column", "grey"), mat("Trim", "slate"), mat("Moss", "green")]
box(L, "Plinth", -0.75, 0.75, 0, 0.5, -0.75, 0.75, "Trim", ["-y"])
prism(L, "Shaft", 0.55, 0.5, 3.3, 0, 0, "Column")
caps(L, "Shaft", top=False)
L += ["active Shaft", "mode edit", 'select vert where "pos.z > 1.3 && pos.x > 0.1"', "translate 0 0 -0.55", "mode object"]
prism(L, "MossRing", 0.68, 0.5, 0.66, 0, 0, "Moss", r2=0.58)
caps(L, "MossRing", top=False)
# the drum: 1.7 m of shaft lying across the side aisle, towards the wall and the player (clear of the
# doorway's path at z -9.5 and of the central aisle the golems walk)
L += [f"add mesh cylinder --name Drum --vertices 8 --radius 0.55 --depth 1.7 --location {H(-1.0, 0.5, 1.75)}",
      "set rotation 90 0 22.5", "apply --rotation", "set rotation 0 0 80", "apply --rotation", "material assign Column"]
L += [f"add mesh ico-sphere --name Chip0 --subdivisions 1 --radius 0.3 --location {H(-1.1, 0.18, -0.6)}", "material assign Trim",
      f"add mesh ico-sphere --name Chip1 --subdivisions 1 --radius 0.22 --location {H(0.2, 0.14, 1.0)}", "material assign Column"]
write("broken", L)

# ---------------------------------------------------------------- brazier with its pool of light
L = ["# An iron brazier (generated by make_env.py): a plinth, a column, a bowl, glowing coals (unlit) and the",
     "# stippled pool of light on the floor (textures/halo.png, alpha-masked, unlit). Origin on the floor.", "new",
     mat("Iron", "umber"), mat("Trim", "slate"), mat("Coal", "red"),
     "material new Pool --base-color 1 1 1 --no-slot", "material texture Pool base-color textures/halo.png",
     "material set Pool alpha-mode mask", "material set Pool alpha-cutoff 0.5"]
prism(L, "Base", 0.36, 0.0, 0.16, 0, 0, "Trim")
caps(L, "Base", top=False)
prism(L, "Post", 0.13, 0.16, 0.92, 0, 0, "Iron")
caps(L, "Post")
prism(L, "Bowl", 0.22, 0.9, 1.2, 0, 0, "Iron", r2=0.5)
caps(L, "Bowl", bottom=False)
prism(L, "Coals", 0.47, 1.12, 1.22, 0, 0, "Coal", r2=0.36)
caps(L, "Coals", bottom=True, top=False)
L += [f"add mesh circle --name Pool --vertices 16 --radius 2.4 --cap-fill ngon --location {H(0, 0.03, 0)}",
      "material assign Pool", "active Pool", "mode edit", "select all", "uv project-from-view top --scale-to-bounds", "mode object"]
write("brazier", L)

# ---------------------------------------------------------------- flame (a game bone)
L = ["# A brazier's flame (generated by make_env.py), all unlit: a tall tan core and three red tongues round it.",
     "# Origin at the coals.", "new", mat("Hot", "tan"), mat("Flame", "red")]
prism(L, "Core", 0.2, 0.0, 0.95, 0, 0, "Hot", r2=0.0, n=5, turn=0)
for i in range(3):
    a = math.radians(120 * i + 30)
    prism(L, f"Tongue{i}", 0.2, 0.0, 0.6, 0.2 * math.cos(a), 0.2 * math.sin(a), "Flame", r2=0.0, n=4, turn=0)
write("flame", L)

# ---------------------------------------------------------------- banner
L = ["# A hanging banner (generated by make_env.py): 1.2 x 3.0 m, a swallowtail, a dark stripe, on a rod.",
     "# Faces +Z (the hall); origin at the rod's centre.", "new", mat("Cloth", "mauve"), mat("Stripe", "purple"), mat("Rod", "umber")]
box(L, "Rod", -0.8, 0.8, -0.08, 0.08, -0.08, 0.08, "Rod")
box(L, "Cloth", -0.6, 0.6, -2.6, -0.08, -0.04, 0.04, "Cloth", ["-z"])
box(L, "Stripe", -0.6, 0.6, -0.75, -0.45, -0.04, 0.09, "Stripe", ["-z"])
for s in (-1, 1):
    L += [f"add mesh cone --name Tail{'LR'[s > 0]} --vertices 3 --radius1 0.34 --radius2 0 --depth 0.08 --location {H(s * 0.3, -2.6, 0)}",
          "set rotation 90 0 0", "apply --rotation", "set rotation 0 180 0", "apply --rotation",
          "scale 0.88 1 1.4", "apply --scale", "material assign Cloth"]
write("banner", L)

# ---------------------------------------------------------------- rubble
L = ["# A pile of fallen blocks with moss (generated by make_env.py), about 2.2 x 1.1 x 1.8 m. Origin on the floor.", "new",
     mat("Block", "grey"), mat("Trim", "slate"), mat("Moss", "green")]
rr = random.Random(11)
blocks = [(0.0, 0.0, 1.0, 0.7, 0.8, 18), (0.8, 0.4, 0.8, 0.55, 0.7, -25), (-0.7, 0.3, 0.7, 0.5, 0.6, 40),
          (0.2, -0.6, 0.6, 0.45, 0.5, 70), (0.35, 0.15, 0.6, 0.45, 0.55, -8)]
for i, (x, z, w, h, d, yaw) in enumerate(blocks):
    yb = 0.0 if i < 4 else 0.65
    L += [f"add mesh cube --name Block{i} --size 1 --location {H(x, yb + h / 2, z)}",
          f"scale {w:.2f} {d:.2f} {h:.2f}", "apply --scale", f"set rotation {rr.uniform(-8, 8):.1f} {rr.uniform(-6, 6):.1f} {yaw}",
          "apply --rotation", f"material assign {'Block' if i % 2 == 0 else 'Trim'}"]
L += [f"add mesh cone --name MossCap --vertices 6 --radius1 0.42 --radius2 0.2 --depth 0.12 --location {H(0.35, 1.26, 0.15)}",
      "material assign Moss",
      f"add mesh ico-sphere --name Stone0 --subdivisions 1 --radius 0.24 --location {H(-1.1, 0.16, -0.4)}", "material assign Trim",
      f"add mesh ico-sphere --name Stone1 --subdivisions 1 --radius 0.18 --location {H(1.2, 0.12, -0.5)}", "material assign Block"]
write("rubble", L)

# ---------------------------------------------------------------- bolt
L = ["# The player's bolt (generated by make_env.py), unlit: a pale core and a cyan tail streaming behind it",
     "# (+Z: it flies down -Z). Origin at the core.", "new", mat("Core", "pale"), mat("Tail", "cyan")]
L += [f"add mesh ico-sphere --name Core --subdivisions 1 --radius 0.15 --location {H(0, 0, 0)}", "material assign Core"]
L += [f"add mesh cone --name Tail --vertices 6 --radius1 0.14 --radius2 0.0 --depth 0.7 --location {H(0, 0, 0.42)}",
      "set rotation -90 0 0", "apply --rotation", "material assign Tail"]
write("bolt", L)

# ---------------------------------------------------------------- crack (on the golem's front)
C8 = math.cos(math.radians(22.5))


def urn_r(z):
    if z <= 1.45:
        return 0.41 + 0.20 * (z - 0.80) / 0.65
    return 0.61 - 0.06 * (z - 1.45) / 0.25


def surf_y(x, z):
    """hedra y (negative: the front) of the golem's eight-sided urn (or head) at (x, z), 0.06 proud (a splat
    spacing of the golem's clay: closer, its splats swallow the crack)"""
    r = 0.39 if z > 1.86 else urn_r(z)
    if abs(x) <= r * math.sin(math.radians(22.5)):
        return -(r * C8 + 0.06)
    return -((r * C8 - abs(x) * math.sin(math.radians(45))) / math.cos(math.radians(45)) + 0.06)


CRACKS = [[(-0.44, 1.62), (-0.31, 1.49), (-0.37, 1.35), (-0.24, 1.22), (-0.29, 1.12)],
          [(0.22, 1.66), (0.34, 1.55), (0.27, 1.43), (0.40, 1.30), (0.33, 1.20)],
          [(0.12, 2.22), (0.03, 2.12), (0.12, 2.03)],
          [(-0.05, 0.98), (0.06, 0.90), (-0.02, 0.83)]]
L = ["# The golem's glowing cracks (generated by make_env.py): zigzag bars of light standing 6 cm off the",
     "# urn's and the head's front flats, in the golem's frame (hedra: up Z, facing -Y). Origin on the ground.",
     "new", mat("Crack", "cyan")]
k = 0
for c in CRACKS:
    for (xa, za), (xb, zb) in zip(c, c[1:]):
        mx, mz = (xa + xb) / 2, (za + zb) / 2
        ln = math.hypot(xb - xa, zb - za) + 0.05
        ang = math.degrees(math.atan2(zb - za, xb - xa))
        L += [f"add mesh cube --name Crack{k} --size 1 --location {mx:.3f} {surf_y(mx, mz):.3f} {mz:.3f}",
              f"scale {ln:.3f} 0.07 0.06", "apply --scale", f"set rotation 0 {-ang:.1f} 0", "apply --rotation",
              "material assign Crack"]
        k += 1
L += ["select all", "shade flat", "export crack.glb"]
open(os.path.join(HERE, "crack.txt"), "w").write("\n".join(L) + "\n")

# ---------------------------------------------------------------- chunk
L = ["# A chunk of fired clay (generated by make_env.py), 0.5 m, baked at its largest and scaled down.", "new",
     mat("Clay", "red"), mat("Inner", "crimson"),
     "add mesh ico-sphere --name Chunk --subdivisions 1 --radius 0.25 --location 0 0 0", "material assign Clay",
     "active Chunk", "mode edit", "select all", "randomize --amount 0.06 --seed 4",
     'select face where "normal.z < -0.3"', "material assign Inner", "mode object"]
write("chunk", L)

# ---------------------------------------------------------------- spark (an impact burst)
L = ["# An impact burst (generated by make_env.py): eight tiny unlit cubes on a 0.3 m sphere. Origin at its centre.", "new",
     mat("Spark", "cyan")]
sr = random.Random(9)
for i in range(8):
    u, v = sr.uniform(-1, 1), sr.uniform(0, 2 * math.pi)
    q = math.sqrt(1 - u * u)
    L += [f"add mesh cube --name S{i} --size 0.08 --location {0.3 * q * math.cos(v):.3f} {0.3 * q * math.sin(v):.3f} {0.3 * u:.3f}",
          "material assign Spark"]
write("spark", L)

# ---------------------------------------------------------------- staff (the player's, seen in the corner)
L = ["# The player's staff (generated by make_env.py): a dark haft with tan bands, three prongs round a glowing",
     "# orb (unlit). Points down -Z (where the camera looks); origin at the grip, the orb 0.62 m ahead.", "new",
     mat("Haft", "umber"), mat("Band", "tan"), mat("Prong", "slate"), mat("Orb", "cyan")]
L += [f"add mesh cylinder --name Haft --vertices 6 --radius 0.03 --depth 0.85 --location {H(0, 0, -0.1)}",
      "set rotation 90 0 0", "apply --rotation", "material assign Haft"]
for i, z in enumerate((-0.2, -0.46)):
    L += [f"add mesh cylinder --name Band{i} --vertices 6 --radius 0.04 --depth 0.05 --location {H(0, 0, z)}",
          "set rotation 90 0 0", "apply --rotation", "material assign Band"]
for i in range(3):
    a = math.radians(120 * i + 90)
    L += [f"add mesh cube --name Prong{i} --size 1 --location {H(0.055 * math.cos(a), 0.055 * math.sin(a), -0.6)}",
          "scale 0.025 0.16 0.025", "apply --scale", "material assign Prong"]
L += [f"add mesh ico-sphere --name Orb --subdivisions 1 --radius 0.06 --location {H(0, 0, -0.64)}", "material assign Orb"]
write("staff", L)

print("wrote hall pillar broken brazier flame banner rubble bolt crack chunk spark staff (.txt), textures/floor.png, halo.png")
