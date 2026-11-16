#!/usr/bin/env python3
"""Writes the village pitch's hedra command files and its palette-exact textures (Sheltzy32).
Up Z in hedra (the GLB comes out Y up, facing +Z); world z = -hedra y.

  ground.txt   the pitch (25.2 x 14.4 m inside the fence, textures/pitch.png at 0.1 m a texel: mowing
               stripes, chalk lines, worn goalmouths) and the verge around it (textures/verge.png)
  fence.txt    a post-and-rail fence round the pitch (x +-12.6, z +-7.2), pennant posts at the corners
  goal.txt     a small goal: white posts and crossbar 3.2 x 1.5 m, a box net 0.9 m deep (alpha-masked
               net textures, 0.3 m cells); origin on the goal line's centre, mouth facing -Y (front)
  tree.txt     a village tree: a trunk and two faceted crowns
  ball.txt     the ball: a faceted icosahedron, 0.2 m radius (pixel-art big), dark patches
  ring.txt     the marker under your controlled player: a flat ring, 0.5 m radius
"""
import os, random
from PIL import Image

here = os.path.dirname(os.path.abspath(__file__))
tex = os.path.join(here, "textures")
os.makedirs(tex, exist_ok=True)

def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)

def srgb(h):
    c = hexc(h)
    return "%.3f %.3f %.3f" % (c[0] / 255, c[1] / 255, c[2] / 255)

LIGHT, DARK = hexc("#46c657"), hexc("#158968")      # mowing stripes (grass ramp)
CHALK = hexc("#cce2e1")                             # chalk (chalk ramp: shade #8babbf, sun #ffffff)
WORN, WORN2 = hexc("#839740"), hexc("#ccac68")      # a worn goalmouth: olive, sandy earth

# ---------------------------------------------------------------- the pitch texture
FX, FZ = 12.6, 7.2          # the fence (the texture covers the fenced area)
T = 0.1                     # metres a texel
W, H = int(round(2 * FX / T)), int(round(2 * FZ / T))
im = Image.new("RGBA", (W, H))
rnd = random.Random(7)
def world(i, j):            # texel centre -> world x, z (row 0 at the far side, z = -7.2)
    return -FX + (i + 0.5) * T, -FZ + (j + 0.5) * T
LW = 0.1                    # half a chalk line (lines 0.2 m: two splats)
for j in range(H):
    for i in range(W):
        x, z = world(i, j)
        stripe = int((x + FX) // 2.1) % 2
        c = LIGHT if stripe == 0 else DARK
        # worn earth in front of each goal: an olive halo round a sandy core, ragged by a hash
        for gx in (-11.0, 11.0):
            dx, dz = (x - gx) * 0.9, z * 0.62
            r = (dx * dx + dz * dz) ** 0.5 + 0.18 * ((i * 7 + j * 13) % 5) / 4.0
            if r < 1.05:
                c = WORN2 if r < 0.6 else WORN
        ax, az = abs(x), abs(z)
        line = False
        if abs(az - 6.0) < LW and ax <= 11.0 + LW: line = True          # touchlines
        if abs(ax - 11.0) < LW and az <= 6.0 + LW: line = True          # goal lines
        if abs(x) < LW and az <= 6.0: line = True                       # halfway line
        d = (x * x + z * z) ** 0.5
        if abs(d - 2.0) < LW or d < 0.16: line = True                   # centre circle, spot
        if abs(ax - 8.0) < LW and az <= 3.4 + LW: line = True           # the keeper's box
        if abs(az - 3.4) < LW and 8.0 - LW <= ax <= 11.0: line = True
        pd = ((ax - 8.6) ** 2 + z * z) ** 0.5
        if pd < 0.13: line = True                                       # the penalty spots
        if line:
            c = CHALK
        im.putpixel((i, j), c)
im.save(os.path.join(tex, "pitch.png"))

# the verge: olive meadow with dark tufts and pale flecks (0.25 m a texel)
VW, VH = 48, 48
vm = Image.new("RGBA", (VW, VH), hexc("#839740"))
rv = random.Random(3)
for k in range(70):
    x, y = rv.randrange(VW), rv.randrange(VH)
    c = hexc("#158968") if k % 3 else hexc("#c9ec85")
    for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)) if k % 3 else ((0, 0), (1, 0)):
        vm.putpixel(((x + dx) % VW, (y + dy) % VH), c)
vm.save(os.path.join(tex, "verge.png"))

# the net: 0.3 m cells, strands 2 px of 8 (0.075 m), alpha 0 in the holes
def net_texture(name, w, h):
    nx, ny = max(1, round(w / 0.3)), max(1, round(h / 0.3))
    tw, th = nx * 8 + 2, ny * 8 + 2
    t = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    for y in range(th):
        for x in range(tw):
            if x % 8 < 2 or y % 8 < 2:
                t.putpixel((x, y), CHALK)
    t.save(os.path.join(tex, name))
GW, GH, GD = 1.6, 1.5, 0.9    # goal half width (post centres), crossbar height, net depth
net_texture("net_back.png", 2 * GW, GH)
net_texture("net_side.png", GD, GH)
net_texture("net_top.png", 2 * GW, GD)

def write(name, lines):
    with open(os.path.join(here, name), "w") as f:
        f.write("\n".join(lines) + "\n")

def box(name, sx, sy, sz, x, y, z):
    return [f"add mesh cube --name {name} --size 1 --location {x:.3f} {y:.3f} {z:.3f}",
            f"scale {sx:.3f} {sy:.3f} {sz:.3f}", "apply --scale"]

# ---------------------------------------------------------------- ground
g = ["# The village pitch: the fenced grass (25.2 x 14.4 m) with textures/pitch.png at 0.1 m a texel,",
     "# and the verge round it out to x +-15, world z -12.5..9 (textures/verge.png). Generated by make_env.py.",
     "new",
     "material new Pitch --base-color 1 1 1 --no-slot",
     "material texture Pitch base-color textures/pitch.png",
     "material new Verge --base-color 1 1 1 --no-slot",
     "material texture Verge base-color textures/verge.png",
     "add mesh grid --name Ground --size 1 --x-subdivisions 12 --y-subdivisions 8 --location 0 0 0",
     f"scale {2 * FX:.2f} {2 * FZ:.2f} 1", "apply --scale", "material assign Pitch",
     "mode edit", "select all", "uv project-from-view top --scale-to-bounds", "mode object"]
# verge strips (hedra y = -world z): near (z 7.2..9), far (z -12.5..-7.2), the two ends
strips = [("VNear", 30.0, 1.8, 0, -(FZ + 0.9)), ("VFar", 30.0, 5.3, 0, FZ + 2.65),
          ("VLeft", 15 - FX, 2 * FZ, -(FX + (15 - FX) / 2), 0), ("VRight", 15 - FX, 2 * FZ, FX + (15 - FX) / 2, 0)]
for n, sx, sy, x, y in strips:
    g += [f"add mesh grid --name {n} --size 1 --x-subdivisions 4 --y-subdivisions 2 --location {x:.3f} {y:.3f} 0",
          f"scale {sx:.3f} {sy:.3f} 1", "apply --scale", "material assign Verge",
          "mode edit", "select all", "uv cube-project --size 12", "mode object"]
g += ["select all", "active Ground", "join", "shade flat", "export ground.glb"]
write("ground.txt", g)

# ---------------------------------------------------------------- fence
f = ["# A post-and-rail fence round the pitch: posts 0.12 m square, 0.95 m tall about 2.1 m apart, two",
     "# rails (0.14 x 0.06 m) at 0.36 and 0.74 m; taller pennant posts at the corners. Generated by make_env.py.",
     "new",
     f"material new Post --base-color {srgb('#a36d3e')} --no-slot",
     f"material new Rail --base-color {srgb('#ccac68')} --no-slot",
     f"material new Pennant --base-color {srgb('#ffda70')} --no-slot"]
posts, rails, pennants = [], [], []
k = 0
def post(x, y, h=0.95):
    global k
    k += 1
    n = f"P{k}"
    posts.append(n)
    return box(n, 0.12, 0.12, h, x, y, h / 2)
for x in [i * 2.1 - FX for i in range(13)]:
    for y in (-FZ, FZ):
        f += post(x, y, 1.6 if abs(abs(x) - FX) < 0.01 else 0.95)
for y in [i * 2.4 - FZ for i in range(1, 6)]:
    for x in (-FX, FX):
        f += post(x, y)
for hz in (0.36, 0.74):
    for y in (-FZ, FZ):
        n = f"R{len(rails)}"; rails.append(n)
        f += box(n, 2 * FX, 0.06, 0.14, 0, y, hz)
    for x in (-FX, FX):
        n = f"R{len(rails)}"; rails.append(n)
        f += box(n, 0.06, 2 * FZ, 0.14, x, 0, hz)
# pennants: a gold flag on each corner post, pointing along the long side
for i, (x, y) in enumerate(((-FX, -FZ), (FX, -FZ), (-FX, FZ), (FX, FZ))):
    n = f"F{i}"; pennants.append(n)
    sx = 1 if x < 0 else -1
    f += box(n, 0.36, 0.05, 0.26, x + sx * 0.24, y, 1.45)
f += ["select " + " ".join(posts), "material assign Post", "select " + " ".join(rails), "material assign Rail",
      "select " + " ".join(pennants), "material assign Pennant",
      "select all", "active P1", "join", "rename P1 Fence", "cursor set 0 0 0", "origin set --to cursor",
      "mode edit", "select face where \"normal.z < -0.9\"", "delete only-faces", "mode object",
      "shade flat", "export fence.glb"]
write("fence.txt", f)

# ---------------------------------------------------------------- goal
gl = ["# A small goal: white square posts and crossbar (0.1 m) 3.2 x 1.5 m, a box net 0.9 m deep made of",
      "# alpha-masked panels (textures/net_*.png, 0.3 m cells). Origin on the centre of the goal line, the",
      "# mouth facing -Y (the GLB's +Z: yaw +-90 in the scene). Generated by make_env.py.",
      "new",
      f"material new Frame --base-color {srgb('#ffffff')} --no-slot"]
for nm in ("Back", "Side", "Top"):
    gl += [f"material new Net{nm} --base-color 1 1 1 --no-slot",
           f"material texture Net{nm} base-color textures/net_{nm.lower()}.png",
           f"material set Net{nm} alpha-mode mask", f"material set Net{nm} alpha-cutoff 0.5"]
frame = []
for n, sx, sy, sz, x, y, z in (("PostL", 0.1, 0.1, GH + 0.05, -GW, 0, (GH + 0.05) / 2),
                               ("PostR", 0.1, 0.1, GH + 0.05, GW, 0, (GH + 0.05) / 2),
                               ("Bar", 2 * GW + 0.1, 0.1, 0.1, 0, 0, GH),
                               ("BackL", 0.06, 0.06, GH, -GW, GD, GH / 2),
                               ("BackR", 0.06, 0.06, GH, GW, GD, GH / 2),
                               ("BackBar", 2 * GW, 0.06, 0.06, 0, GD, GH - 0.03)):
    frame.append(n)
    gl += box(n, sx, sy, sz, x, y, z)
gl += ["select " + " ".join(frame), "material assign Frame"]
# the net panels: planes, UVs over their bounds
def plane(name, sx, sy, x, y, z, rot, mat, view):
    return [f"add mesh plane --name {name} --size 1 --location {x:.3f} {y:.3f} {z:.3f}",
            f"scale {sx:.3f} {sy:.3f} 1", "apply --scale", f"set rotation {rot}", "apply --rotation",
            f"material assign {mat}", "mode edit", "select all", f"uv project-from-view {view} --scale-to-bounds",
            "mode object"]
gl += plane("NBack", 2 * GW, GH, 0, GD, GH / 2, "90 0 0", "NetBack", "back")
gl += plane("NSideL", GD, GH, -GW, GD / 2, GH / 2, "90 0 90", "NetSide", "right")
gl += plane("NSideR", GD, GH, GW, GD / 2, GH / 2, "90 0 90", "NetSide", "right")
gl += plane("NTop", 2 * GW, GD, 0, GD / 2, GH - 0.02, "0 0 0", "NetTop", "top")
gl += ["select all", "active PostL", "join", "rename PostL Goal", "cursor set 0 0 0", "origin set --to cursor",
       "shade flat", "export goal.glb"]
write("goal.txt", gl)

# ---------------------------------------------------------------- tree
t = ["# A village tree: a six-sided trunk 1.3 m tall and two faceted crowns (icosahedra, r 1.25 and 0.9).",
     "# Generated by make_env.py.", "new",
     f"material new Bark --base-color {srgb('#683c34')} --no-slot",
     f"material new Crown --base-color {srgb('#839740')} --no-slot",
     "add mesh cylinder --name Trunk --vertices 6 --radius 0.18 --depth 1.4 --location 0 0 0.7",
     "material assign Bark",
     "add mesh ico-sphere --name C1 --subdivisions 1 --radius 1.25 --location 0 0 2.2",
     "material assign Crown",
     "add mesh ico-sphere --name C2 --subdivisions 1 --radius 0.9 --location 0.5 -0.3 3.1 --rotation 0 0 30",
     "apply --rotation", "material assign Crown",
     "select all", "active Trunk", "join", "rename Trunk Tree", "cursor set 0 0 0", "origin set --to cursor",
     "mode edit", "select face where \"normal.z < -0.9 && pos.z < 0.05\"", "delete only-faces", "mode object",
     "shade flat", "export tree.glb"]
write("tree.txt", t)

# ---------------------------------------------------------------- ball
b = ["# The ball: an icosahedron 0.2 m in radius (exaggerated: 6 art pixels across in the scene),",
     "# white with dark patches so its roll shows. Origin at its centre. Generated by make_env.py.", "new",
     f"material new Ball --base-color {srgb('#ffffff')} --no-slot",
     f"material new Patch --base-color {srgb('#222a5c')} --no-slot",
     "add mesh ico-sphere --name Ball --subdivisions 1 --radius 0.2 --location 0 0 0",
     "material assign Ball", "mode edit",
     "select face where \"normal.z > 0.75 || normal.z < -0.75 || normal.x > 0.85 || normal.x < -0.85\"",
     "material assign Patch", "mode object", "shade flat", "export ball.glb"]
write("ball.txt", b)

# ---------------------------------------------------------------- ring
r = ["# The marker under your controlled player: a flat ring 0.5 m in radius, 0.1 m wide.",
     "# Generated by make_env.py.", "new",
     f"material new Mark --base-color {srgb('#ffda70')} --no-slot",
     "add mesh torus --name Ring --major-segments 16 --minor-segments 4 --major-radius 0.5 --minor-radius 0.07 --location 0 0 0",
     "scale 1 1 0.3", "apply --scale", "material assign Mark", "shade flat", "export ring.glb"]
write("ring.txt", r)
print("wrote ground fence goal tree ball ring .txt and textures/pitch.png verge.png net_*.png")
