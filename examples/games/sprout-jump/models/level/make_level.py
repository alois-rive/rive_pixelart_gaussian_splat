# Writes level.txt, the hedra command file of the whole static level (every bed, pot, step, wall,
# crate, sunflower, branch, leaf pad, the crown, the oak trunks, the canopy behind, checkpoint stakes,
# the flag pole, garden decor), from layout.py. Run from models/level:
#   /usr/bin/python3 make_level.py            -> level.txt (then: hedra model --text level.rmdl run level.txt)
#   /usr/bin/python3 make_level.py --as       -> prints the AssemblyScript tables for scene/game.as
# Game coordinates (x right, y up, z towards the camera) map to hedra's (x, -z, y): hedra is up Z,
# front -Y, and the GLB comes out Y up, front +Z.
import math, random, sys
import layout as L

C = {"Grass": "#6abe30", "Soil": "#663931", "Stone": "#847e87", "Cap": "#9badb7", "Clay": "#df7126",
     "Wood": "#8f563b", "Bark": "#8f563b", "Canopy": "#37946e", "Leafy": "#6abe30", "Petal": "#fbf236",
     "Disc": "#663931", "Trunk": "#8f563b", "Stalk": "#37946e", "Tulip": "#d95763", "Bush": "#4b692f", "Twig": "#663931"}
TEX = {"Grass": ("textures/grass.png", 3.84), "Soil": ("textures/soil.png", 3.84),
       "Stone": ("textures/bricks.png", 3.0), "Wood": ("textures/planks.png", 2.0),
       "Bark": ("textures/bark.png", 2.4), "Trunk": ("textures/bark.png", 3.2)}
DEEP = -1.1          # where the banks end, under the water band's surface (-0.9)
out = []
n = [0]


def rgb(h):
    return " ".join("%.3f" % (int(h[i:i + 2], 16) / 255) for i in (1, 3, 5))


def H(x, y, z):      # game -> hedra
    return "%.3f %.3f %.3f" % (x, -z, y)


def name(p):
    n[0] += 1
    return "%s%d" % (p, n[0])


def finish(nm, mat, delete=None, uv=None):
    out.append("material assign " + mat)
    if delete or (mat in TEX and uv is not False):
        out.extend(["active " + nm, "mode edit"])
        if mat in TEX and uv is not False:
            out.extend(["select all", "uv cube-project --size %.2f --center 0 0 0" % TEX[mat][1]])
        if delete:
            out.extend(['select face where "%s"' % delete, "delete only-faces"])
        out.append("mode object")


BACK_BOTTOM = "normal.y > 0.9 || normal.z < -0.9"


def box(p, x0, x1, y0, y1, z0, z1, mat, delete=BACK_BOTTOM, uv=None):
    nm = name(p)
    out.append("add mesh cube --name %s --size 1 --location %s" % (nm, H((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)))
    out.extend(["scale %.3f %.3f %.3f" % (x1 - x0, z1 - z0, y1 - y0), "apply --scale"])
    finish(nm, mat, delete, uv)
    return nm


def cyl(p, x, y0, y1, z, r, mat, verts=8, r2=None, delete="normal.y > 0.5 || normal.z < -0.9"):
    nm = name(p)
    if r2 is None:
        out.append("add mesh cylinder --name %s --vertices %d --radius %.3f --depth %.3f --location %s"
                   % (nm, verts, r, y1 - y0, H(x, (y0 + y1) / 2, z)))
    else:   # a cone frustum: radius1 at the bottom, radius2 at the top
        out.append("add mesh cone --name %s --vertices %d --radius1 %.3f --radius2 %.3f --depth %.3f --location %s"
                   % (nm, verts, r, r2, y1 - y0, H(x, (y0 + y1) / 2, z)))
    finish(nm, mat, delete)
    return nm


def blob(p, x, y, z, sx, sy, sz, mat, sub=1, seed=1, delete="normal.y > 0.35"):
    nm = name(p)
    out.extend(["add mesh ico-sphere --name %s --subdivisions %d --radius 0.5 --location %s" % (nm, sub, H(x, y, z)),
            "scale %.3f %.3f %.3f" % (sx, sz, sy), "apply --scale",
            "active " + nm, "mode edit", "select all", "randomize --amount %.3f --seed %d" % (0.06 * min(sx, sy), seed), "mode object"])
    finish(nm, mat, delete)
    return nm


def branch(x0, x1, top, r=0.25, mat="Bark"):
    # a hexagonal log along X with a flat top face at `top`
    nm = name("Br")
    L_ = x1 - x0 + 0.3
    out.extend(["add mesh cylinder --name %s --vertices 6 --radius %.3f --depth %.3f --location 0 0 0" % (nm, r, L_),
            "set rotation 0 0 30", "apply --rotation", "set rotation 0 90 0", "apply --rotation",
            "set location %s" % H((x0 + x1) / 2, top - 0.866 * r, 0), "apply --location"])
    finish(nm, mat, "normal.y > 0.6 || normal.z < -0.3")
    return nm


rnd = random.Random(7)
out += ["# The static level of Sprout Jump: written by make_level.py from layout.py; do not edit by hand.", "new"]
for m, h in C.items():
    out.append("material new %s --base-color %s --no-slot" % (m, rgb(h) if m not in TEX else "1 1 1"))
    if m in TEX:
        out.append("material texture %s base-color %s" % (m, TEX[m][0]))

# ---------------------------------------------------------------- solids
for kind, x0, x1, top in L.SOLIDS:
    if kind == "bed":
        box("Soil", x0, x1, DEEP, top - 0.14, -0.5, 0.5, "Soil", "normal.y > 0.9 || normal.z < -0.9 || normal.z > 0.9")
        box("Turf", x0 - 0.05, x1 + 0.05, top - 0.16, top, -0.55, 0.56, "Grass")
        # tulips behind the run and a tuft or two at the front lip
        for k in range(int((x1 - x0) / 2.6)):
            tx = x0 + 0.8 + k * 2.6 + rnd.uniform(-0.4, 0.4)
            if tx > x1 - 0.5: break
            cyl("TulipStem", tx, top - 0.05, top + 0.42, -0.36, 0.035, "Stalk", 4, delete=None)
            blob("Tulip", tx, top + 0.5, -0.36, 0.2, 0.22, 0.2, "Tulip", sub=1, seed=k + 3, delete=None)
    elif kind == "pot":
        r = (x1 - x0) / 2
        cx = (x0 + x1) / 2
        cyl("Pot", cx, DEEP, top - 0.16, 0, r * 0.82, "Clay", 8, r2=r * 0.95)
        cyl("Rim", cx, top - 0.18, top - 0.02, 0, r * 1.06, "Clay", 8, delete="normal.y > 0.5")
        cyl("PotSoil", cx, top - 0.06, top, 0, r * 0.92, "Soil", 8, delete="normal.z < 0.5")
        blob("Sprig", cx - 0.1, top + 0.12, -0.25, 0.32, 0.28, 0.2, "Leafy", seed=int(cx))
    elif kind == "step":
        box("Step", x0, x1, DEEP, top, -0.5, 0.5, "Stone")
    elif kind == "wall":
        box("Wall", x0, x1, DEEP, top - 0.16, -0.45, 0.45, "Stone")
        box("Coping", x0 - 0.08, x1 + 0.08, top - 0.16, top, -0.55, 0.55, "Cap")
    elif kind == "crate":
        box("Crate", x0, x1, DEEP, top, -0.55, 0.55, "Wood")

# ---------------------------------------------------------------- one-way platforms
for kind, x0, x1, top in L.ONEWAY:
    cx = (x0 + x1) / 2
    r = (x1 - x0) / 2
    if kind == "flower":   # a sunflower head turned up to the sky: petals, a brown disc, a stalk
        cyl("Head", cx, top - 0.14, top - 0.04, 0, r + 0.08, "Petal", 12, delete="normal.y > 0.5")
        cyl("Disc", cx, top - 0.05, top, 0, r * 0.55, "Disc", 10, delete="normal.z < 0.5")
        cyl("Under", cx, top - 0.42, top - 0.14, 0, 0.1, "Stalk", 8, r2=r * 0.7, delete="normal.z > 0.5")
        cyl("Stalk", cx, DEEP, top - 0.42, -0.05, 0.08, "Stalk", 6)
        blob("SLeaf", cx + 0.32, (top + DEEP) / 2 + 0.3, -0.1, 0.5, 0.16, 0.3, "Stalk", seed=int(cx) + 1)
    elif kind in ("branch", "crown"):
        rr = 0.36 if kind == "crown" else 0.25
        branch(x0, x1, top, rr)
        # leaf tufts at the tip and along the back of the bough
        blob("Tuft", x1 + 0.25, top - 0.15, -0.25, 0.75, 0.55, 0.55, "Leafy", seed=int(x1))
        blob("Tuft", x0 - 0.1, top - 0.25, -0.45, 0.6, 0.45, 0.45, "Leafy", seed=int(x0))
        if kind == "crown":
            for k in range(5):
                blob("CTuft", x0 + 0.8 + k * 1.7, top + 0.05, -0.75, 1.1, 0.7, 0.6, "Leafy", seed=40 + k)
    elif kind == "leaf":     # a big leaf lying flat, its stem curling back into the canopy
        blob("Pad", cx, top - 0.06, 0, x1 - x0 + 0.2, 0.14, 0.75, "Leafy", seed=int(cx), delete="normal.z < -0.6")
        cyl("PadStem", cx - 0.2, top - 1.2, top - 0.1, -0.35, 0.05, "Stalk", 5, delete=None)

# ---------------------------------------------------------------- the treetops: trunks, limbs, canopy
# A row of old trees behind the branches: each trunk rises from below the frame into a crown of
# clumps; every branch gets a limb slanting down-left into the foliage under it, so nothing floats.
rc = random.Random(21)
TREES = (106.5, 119.5, 133.0, 146.0, 160.0, 174.5)
for k, tx in enumerate(TREES):
    tops = [t for (_, a, b, t) in L.ONEWAY if a - 8 < tx < b + 8] or [10.0]
    y0, y1 = min(tops) - 4.5, max(tops) + 3.0
    cyl("Trunk", tx, y0, y1, -1.4, 0.5, "Trunk", 8, delete="normal.y > 0.3 || normal.z < -0.9 || normal.z > 0.9")
    for j in range(3):
        blob("Crown", tx + (j - 1) * 2.4 + rc.uniform(-0.4, 0.4), y1 + rc.uniform(-0.3, 0.6) + (0.5 if j == 1 else 0),
             -2.0, 3.6, 2.6, 1.8, "Canopy", sub=2, seed=k * 10 + j)
    blob("Crown", tx + rc.uniform(-1.5, 1.5), y0 + 1.0, -2.2, 3.2, 2.0, 1.6, "Canopy", sub=2, seed=k * 10 + 7)
for kind, x0, x1, top in L.ONEWAY:
    if kind not in ("branch", "crown", "leaf"):
        continue
    nm = name("Limb")
    ax, ay = x0 + 0.2, top - 0.25
    bxx, byy = x0 - 0.9, top - 1.9
    ln = math.hypot(ax - bxx, ay - byy)
    ang = math.degrees(math.atan2(ax - bxx, ay - byy))
    out.extend(["add mesh cylinder --name %s --vertices 5 --radius 0.11 --depth %.3f --location 0 0 0" % (nm, ln),
                "set rotation 0 %.2f 0" % ang, "apply --rotation",
                "set location %s" % H((ax + bxx) / 2, (ay + byy) / 2, -0.2), "apply --location"])
    finish(nm, "Bark", "normal.y > 0.5")
    blob("Under", bxx - 0.2, byy - 0.3, -0.8, 1.9, 1.3, 1.0, "Canopy", sub=2, seed=int(x0 * 3))

# garden shrubs behind the beds
for k, bx in enumerate((-2.0, 7.0, 15.0, 24.0, 33.0, 46.0, 55.0, 70.0, 84.0, 95.0)):
    blob("Bush", bx, 0.4, -1.9, 2.4, 1.6, 1.2, "Bush", sub=2, seed=100 + k)

# ---------------------------------------------------------------- checkpoint stakes, the flag pole, the bridge posts
for i, (cx, cy) in enumerate(L.CHECKPOINTS):
    if i == 0: continue
    cyl("Stake", cx, cy - 0.05, cy + 0.85, -0.3, 0.05, "Twig", 5, delete=None)
fx, fy = L.FLAG
cyl("Pole", fx, fy - 0.05, fy + 2.9, -0.1, 0.07, "Twig", 6, delete=None)
blob("Knob", fx, fy + 2.95, -0.1, 0.22, 0.22, 0.22, "Petal", seed=5, delete=None)
bx, bn, bw, btop = L.BRIDGE
for px in (bx, bx + bn * bw):
    cyl("Post", px, btop - 0.3, btop + 0.75, -0.35, 0.07, "Twig", 5, delete=None)
    cyl("Post", px, btop - 0.3, btop + 0.75, 0.35, 0.07, "Twig", 5, delete=None)

out += ["select all", "active %s1" % "Soil", "join", "rename Soil1 Level", "shade flat", "inspect stats", "export level.glb"]


def as_tables():
    f = lambda v: ("%.2f" % v)
    print("// LEVEL BEGIN (written by models/level/make_level.py --as from layout.py)")
    print("const WATER_Y: f64 = %s;\nconst WATER_END: f64 = %s;" % (f(L.WATER_Y), f(L.WATER_END)))
    print("const SOL: StaticArray<f64> = [%s];" % ", ".join("%s, %s, %s" % (f(a), f(b), f(t)) for _, a, b, t in L.SOLIDS))
    print("const ONE: StaticArray<f64> = [%s];" % ", ".join("%s, %s, %s" % (f(a), f(b), f(t)) for _, a, b, t in L.ONEWAY))
    print("const MOV: StaticArray<f64> = [%s];" % ", ".join("%s, %s, %d, %s, %s" % (f(a), f(b), 0 if ax == "h" else 1, f(c), f(d)) for a, b, ax, c, d in L.MOVERS))
    print("const BRIDGE: StaticArray<f64> = [%s, %d, %s, %s];" % (f(L.BRIDGE[0]), L.BRIDGE[1], f(L.BRIDGE[2]), f(L.BRIDGE[3])))
    print("const SPR: StaticArray<f64> = [%s];" % ", ".join("%s, %s" % (f(a), f(b)) for a, b in L.SPRINGS))
    print("const BUG: StaticArray<f64> = [%s];" % ", ".join("%s, %s, %s" % (f(a), f(b), f(c)) for a, b, c in L.BUGS))
    print("const MOTH: StaticArray<f64> = [%s];" % ", ".join("%s, %s, %d, %s, %s" % (f(a), f(b), 0 if ax == "h" else 1, f(c), f(d)) for a, b, ax, c, d in L.MOTHS))
    print("const CP: StaticArray<f64> = [%s];" % ", ".join("%s, %s" % (f(a), f(b)) for a, b in L.CHECKPOINTS))
    print("const FLAG_X: f64 = %s;\nconst FLAG_Y: f64 = %s;" % (f(L.FLAG[0]), f(L.FLAG[1])))
    print("const SEED: StaticArray<f64> = [%s];" % ", ".join("%s, %s" % (f(a), f(b)) for a, b in L.SEEDS))
    print("// LEVEL END")


if "--as" in sys.argv:
    as_tables()
else:
    open("level.txt", "w").write("\n".join(out) + "\n")
    print("wrote level.txt: %d objects" % n[0])
