# Writes every generated Border War model (no sheet: their rows in art/assets.md are the brief) as
# models/<name>/<name>.glb. Each faces +Z (the renderer's yaw 0), Y up, origin on the ground under
# its centre (a projectile: at its middle). Lospec500 colours; material names map to ramps in
# scene.bake.json. Run from models/: /usr/bin/python3 make_models.py
import math
import os

from meshkit import Mesh, rot_x, rot_y, rot_z

HERE = os.path.dirname(os.path.abspath(__file__))

C = {
    "Skin": "#ffa2ac", "Tunic": "#dab163", "Straw": "#e8d282", "Trousers": "#6e4c30", "Team": "#3388de",
    "Tabard": "#3859b3", "Steel": "#5e5b8c", "Bright": "#b0a7b8", "Blade": "#deceed", "Gold": "#f3a833",
    "Leather": "#a26d3f", "Wood": "#6e4c30", "Hood": "#3859b3",
    "Orc": "#62a477", "Hide": "#ac2847", "HideDk": "#6b2643", "Bone": "#f7f3b7", "Hair": "#2c1e31",
    "Stone": "#8c78a5", "Plaster": "#e8d282", "Timber": "#6e4c30", "Door": "#a26d3f", "Roof": "#3859b3",
    "Banner": "#3388de", "Dark": "#2c1e31", "Logs": "#6e4c30", "LogsLt": "#a26d3f", "Thatch": "#dab163",
    "Leaf": "#006554", "Bark": "#6e4c30", "Sack": "#dab163", "Cut": "#e8d282", "Shaft": "#e8d282",
}


def new():
    m = Mesh()
    for k, v in C.items():
        m.material(k, v)
    return m


def save(m, name):
    d = os.path.join(HERE, name)
    os.makedirs(d, exist_ok=True)
    m.write_glb(os.path.join(d, name + ".glb"))
    lo, hi = m.bounds()
    print(f"{name:9s} {m.count():4d} tris  size {hi[0]-lo[0]:.2f} x {hi[1]-lo[1]:.2f} x {hi[2]-lo[2]:.2f}")


# ================================================================ human units

def yeoman():
    m = new()
    for s in (-1, 1):
        m.box("Trousers", 0.08 * s, 0.14, 0, 0.13, 0.28, 0.14)
        m.box("Tunic", 0.225 * s, 0.47, 0, 0.11, 0.3, 0.12)
        m.box("Skin", 0.225 * s, 0.29, 0.01, 0.11, 0.08, 0.11)
    m.box("Tunic", 0, 0.45, 0, 0.34, 0.34, 0.25)
    m.box("Team", 0, 0.35, 0, 0.36, 0.07, 0.27)
    m.box("Skin", 0, 0.73, 0.01, 0.25, 0.22, 0.23)
    m.box("Straw", 0, 0.865, 0, 0.4, 0.05, 0.38)
    m.box("Straw", 0, 0.93, -0.01, 0.23, 0.1, 0.21)
    # a hatchet in the right hand (the figure's right is -x)
    m.box("Leather", -0.235, 0.36, 0.1, 0.07, 0.07, 0.36, R=rot_x(-35), pivot=(-0.235, 0.29, 0.02))
    m.box("Bright", -0.235, 0.47, 0.27, 0.06, 0.14, 0.09, R=rot_x(-35), pivot=(-0.235, 0.29, 0.02))
    save(m, "yeoman")


def swordsman():
    m = new()
    for s in (-1, 1):
        m.box("Steel", 0.085 * s, 0.15, 0, 0.14, 0.3, 0.15)
        m.box("Steel", 0.25 * s, 0.53, 0, 0.12, 0.3, 0.13)
    m.box("Tabard", 0, 0.5, 0, 0.38, 0.4, 0.27)
    m.box("Leather", 0, 0.4, 0, 0.4, 0.06, 0.29)
    m.box("Skin", 0, 0.8, 0.01, 0.25, 0.21, 0.23)
    m.box("Bright", 0, 0.9, 0, 0.29, 0.13, 0.27)
    m.box("Bright", 0, 0.82, 0.09, 0.07, 0.11, 0.06)          # nasal guard
    m.box("Team", 0, 1.0, -0.01, 0.07, 0.09, 0.24)             # crest
    # the shield on the left arm (+x), facing out and forward
    m.box("Team", 0.34, 0.5, 0.05, 0.07, 0.36, 0.32)
    m.box("Gold", 0.385, 0.5, 0.05, 0.04, 0.1, 0.1)
    # the sword in the right hand, held forward and up
    pv = (-0.29, 0.38, 0.06)
    m.box("Blade", -0.29, 0.38, 0.33, 0.07, 0.09, 0.48, R=rot_x(-30), pivot=pv)
    m.box("Gold", -0.29, 0.38, 0.08, 0.18, 0.06, 0.06, R=rot_x(-30), pivot=pv)
    m.box("Skin", -0.29, 0.37, 0.02, 0.1, 0.09, 0.1)
    save(m, "swordsman")


def archer():
    m = new()
    for s in (-1, 1):
        m.box("Trousers", 0.08 * s, 0.14, 0, 0.13, 0.28, 0.14)
        m.box("Leather", 0.23 * s, 0.48, 0, 0.11, 0.3, 0.12)
    m.box("Leather", 0, 0.47, 0, 0.34, 0.36, 0.25)
    m.box("Hood", 0, 0.47, -0.145, 0.36, 0.42, 0.05)          # the cape
    m.box("Hood", 0, 0.78, -0.01, 0.29, 0.27, 0.27)           # the hood
    m.box("Hood", 0, 0.94, -0.06, 0.14, 0.08, 0.14)           # its point
    m.box("Skin", 0, 0.76, 0.12, 0.19, 0.15, 0.05)            # the face in the hood
    # the bow in the left hand (+x): three staves bent forward
    m.box("Wood", 0.3, 0.5, 0.14, 0.06, 0.3, 0.06)
    m.box("Wood", 0.3, 0.73, 0.1, 0.06, 0.22, 0.06, R=rot_x(-25), pivot=(0.3, 0.64, 0.14))
    m.box("Wood", 0.3, 0.27, 0.1, 0.06, 0.22, 0.06, R=rot_x(25), pivot=(0.3, 0.36, 0.14))
    m.box("Skin", 0.3, 0.5, 0.06, 0.1, 0.09, 0.1)
    # a quiver on the back, fletchings showing
    m.box("Wood", -0.1, 0.62, -0.2, 0.11, 0.32, 0.1, R=rot_z(-20), pivot=(-0.1, 0.62, -0.2))
    m.box("Straw", -0.15, 0.8, -0.2, 0.12, 0.08, 0.1, R=rot_z(-20), pivot=(-0.1, 0.62, -0.2))
    save(m, "archer")


# ================================================================ orc units (sage skin, crimson war-colours)

def tusks(m, y, z, half):
    for s in (-1, 1):
        m.box("Bone", half * s, y, z, 0.06, 0.1, 0.06)


def drudge():
    m = new()
    for s in (-1, 1):
        m.box("Orc", 0.1 * s, 0.13, 0, 0.15, 0.26, 0.16)
        m.box("Orc", 0.28 * s, 0.44, 0.03, 0.12, 0.32, 0.13)
        m.box("Orc", 0.2 * s, 0.8, 0.07, 0.14, 0.07, 0.07)      # ears, sticking out
    m.box("Wood", 0, 0.3, 0, 0.4, 0.15, 0.3)
    m.box("Orc", 0, 0.5, 0.0, 0.42, 0.32, 0.31, R=rot_x(12), pivot=(0, 0.35, 0))
    m.box("Hide", 0, 0.56, 0.0, 0.44, 0.08, 0.33, R=rot_x(12), pivot=(0, 0.35, 0))
    m.box("Orc", 0, 0.74, 0.1, 0.29, 0.24, 0.27)
    tusks(m, 0.66, 0.24, 0.08)
    # a stone maul in the right hand (-x)
    m.box("Leather", -0.29, 0.33, 0.12, 0.07, 0.07, 0.34, R=rot_x(-30), pivot=(-0.29, 0.28, 0.04))
    m.box("Steel", -0.29, 0.43, 0.29, 0.14, 0.13, 0.13, R=rot_x(-30), pivot=(-0.29, 0.28, 0.04))
    save(m, "drudge")


def brute():
    m = new()
    for s in (-1, 1):
        m.box("Orc", 0.12 * s, 0.16, 0, 0.18, 0.32, 0.19)
        m.box("Orc", 0.37 * s, 0.6, 0.03, 0.16, 0.38, 0.17)
    m.box("Hide", 0, 0.37, 0, 0.5, 0.2, 0.36)
    m.box("Orc", 0, 0.63, 0, 0.56, 0.42, 0.37)
    m.box("Hide", 0.33, 0.86, 0, 0.24, 0.13, 0.3)              # the pauldron on the left shoulder
    m.box("Bone", 0.4, 0.97, 0, 0.07, 0.12, 0.07)              # its spike
    m.box("Orc", 0, 0.96, 0.06, 0.31, 0.27, 0.29)
    m.box("Hair", 0, 1.13, 0.0, 0.1, 0.1, 0.13)                # a topknot
    tusks(m, 0.88, 0.22, 0.09)
    # a heavy club in the right hand (-x), raised forward
    m.frustum("LogsLt", -0.38, 0.42, 0.06, 0.06, 0.11, 0.58, n=6, R=rot_x(35))
    save(m, "brute")


def thrower():
    m = new()
    for s in (-1, 1):
        m.box("Orc", 0.085 * s, 0.15, 0, 0.13, 0.3, 0.14)
        m.box("Orc", 0.24 * s, 0.5, 0.02, 0.11, 0.32, 0.12)
        m.box("Orc", 0.18 * s, 0.84, 0.05, 0.13, 0.06, 0.07)
    m.box("Wood", 0, 0.33, 0, 0.36, 0.13, 0.27)
    m.box("Orc", 0, 0.52, 0, 0.36, 0.34, 0.26)
    m.box("Hide", 0, 0.55, 0, 0.38, 0.08, 0.28, R=rot_z(25), pivot=(0, 0.55, 0))   # a sash
    m.box("Orc", 0, 0.8, 0.04, 0.26, 0.24, 0.25)
    m.box("Hide", 0, 0.9, 0.03, 0.28, 0.07, 0.27)              # the bandana
    tusks(m, 0.73, 0.18, 0.07)
    # the spear held upright in the right hand (-x)
    m.box("Wood", -0.26, 0.62, 0.06, 0.07, 1.12, 0.07)
    m.frustum("Bright", -0.26, 1.18, 0.06, 0.07, 0.0, 0.2, n=4, rot=45)
    save(m, "thrower")


# ================================================================ human buildings (the Manor is modelled in hedra)

def framed_walls(m, cx, cz, sx, sz, y0, h, wall="Plaster", post="Timber"):
    m.box(wall, cx, y0 + h / 2, cz, sx, h, sz)
    for px in (-1, 1):
        for pz in (-1, 1):
            m.box(post, cx + px * (sx / 2 - 0.04), y0 + h / 2, cz + pz * (sz / 2 - 0.04), 0.13, h, 0.13)
    m.box(post, cx, y0 + h - 0.05, cz, sx + 0.04, 0.1, sz + 0.04)


def yard():
    m = new()
    m.box("Stone", 0, 0.09, 0, 2.3, 0.18, 1.7)
    framed_walls(m, 0, 0, 2.0, 1.3, 0.18, 0.72)
    m.prism_roof("Roof", 0, 0.9, 0, 2.3, 1.62, 0.66, ridge="x", gable_mat="Plaster")
    m.box("Door", 0, 0.47, 0.66, 0.56, 0.58, 0.05)
    # crossed swords over the door
    for s in (-1, 1):
        m.box("Blade", 0, 0.98, 0.83, 0.06, 0.42, 0.04, R=rot_z(35 * s), pivot=(0, 0.98, 0.83))
    m.box("Gold", 0, 0.98, 0.86, 0.11, 0.11, 0.04)
    # a straw training dummy at the front-left (+x) and a spear rack on the right (-x)
    m.box("Wood", 1.25, 0.35, 0.55, 0.08, 0.7, 0.08)
    m.box("Thatch", 1.25, 0.62, 0.55, 0.24, 0.3, 0.2)
    m.box("Wood", 1.25, 0.62, 0.55, 0.5, 0.07, 0.07)
    m.box("Thatch", 1.25, 0.83, 0.55, 0.14, 0.13, 0.14)
    m.box("Wood", -1.25, 0.35, 0.3, 0.08, 0.7, 0.08)
    m.box("Wood", -1.25, 0.35, -0.3, 0.08, 0.7, 0.08)
    m.box("Wood", -1.25, 0.55, 0.0, 0.07, 0.07, 0.7)
    for k in (-0.18, 0.0, 0.18):
        m.box("Wood", -1.3, 0.55, k, 0.06, 0.9, 0.06, R=rot_z(-12), pivot=(-1.3, 0.1, k))
        m.frustum("Bright", -1.3 - 0.85 * math.sin(math.radians(12)), 0.98, k, 0.06, 0, 0.14, n=4, rot=45)
    save(m, "yard")


def watchtower():
    m = new()
    m.frustum("Stone", 0, 0, 0, 0.5, 0.42, 1.8, n=8, rot=22.5)
    m.frustum("Stone", 0, 1.8, 0, 0.58, 0.58, 0.2, n=8, rot=22.5, bottom=True)
    for i in range(8):
        a = math.radians(22.5 + 45 * i)
        m.box("Stone", math.cos(a) * 0.5, 2.06, math.sin(a) * 0.5, 0.15, 0.13, 0.15, R=None)
    for px, pz in ((0.28, 0.28), (-0.28, 0.28), (0.28, -0.28), (-0.28, -0.28)):
        m.box("Timber", px, 2.15, pz, 0.08, 0.3, 0.08)
    m.frustum("Roof", 0, 2.28, 0, 0.62, 0.0, 0.62, n=8, rot=22.5, bottom=True)
    m.box("Timber", 0, 3.0, 0, 0.07, 0.3, 0.07)
    m.box("Banner", 0.17, 3.06, 0, 0.3, 0.17, 0.04)
    m.box("Door", 0, 0.32, 0.45, 0.32, 0.5, 0.06)
    m.box("Dark", 0, 1.25, 0.43, 0.1, 0.24, 0.05)
    save(m, "watchtower")


def cottage():
    m = new()
    framed_walls(m, 0, 0, 1.1, 0.9, 0.0, 0.62)
    m.prism_roof("Thatch", 0, 0.62, 0, 1.36, 1.16, 0.58, ridge="x", gable_mat="Plaster")
    m.box("Stone", -0.32, 1.0, -0.15, 0.18, 0.5, 0.18)
    m.box("Door", 0.18, 0.26, 0.46, 0.26, 0.42, 0.04)
    m.box("Dark", -0.25, 0.36, 0.46, 0.16, 0.14, 0.04)
    # a little woodpile by the side (+x)
    for k in range(3):
        m.frustum("LogsLt", 0.68, 0.06 + 0.11 * (k % 2), -0.2 + 0.13 * k, 0.06, 0.06, 0.5, n=6, R=rot_x(90))
    save(m, "cottage")


# ================================================================ orc buildings

def warcamp():
    m = new()
    m.frustum("Logs", 0, 0, 0, 1.16, 1.1, 0.55, n=10, rot=18, cap=False)
    # the hide roof: alternating panels
    n = 10
    for i in range(n):
        a0 = math.radians(18 + 36 * i)
        a1 = math.radians(18 + 36 * (i + 1))
        p0 = (math.cos(a0) * 1.36, 0.42, math.sin(a0) * 1.36)
        p1 = (math.cos(a1) * 1.36, 0.42, math.sin(a1) * 1.36)
        top = (0, 2.0, 0)
        m.add("Hide" if i % 2 == 0 else "HideDk", [[p0, p1, top]], centre=(0, 1.0, 0))
    # poles through the smoke hole
    for k in range(4):
        a = math.radians(45 + 90 * k)
        m.box("LogsLt", math.cos(a) * 0.12, 2.05, math.sin(a) * 0.12, 0.08, 0.6, 0.08,
              R=rot_y(-math.degrees(a)) @ rot_z(18), pivot=(math.cos(a) * 0.12, 1.8, math.sin(a) * 0.12))
    # the doorway framed by two great tusks
    m.box("Dark", 0, 0.32, 1.14, 0.52, 0.64, 0.1)
    for s in (-1, 1):
        m.box("Bone", 0.42 * s, 0.45, 1.24, 0.13, 0.85, 0.13, R=rot_z(-18 * s) @ rot_x(-12), pivot=(0.42 * s, 0.05, 1.24))
    # a war banner on a pole at the side
    m.box("Logs", -1.05, 1.15, 0.55, 0.09, 2.3, 0.09)
    m.box("Hide", -0.84, 1.95, 0.55, 0.36, 0.55, 0.05)
    m.box("Bone", -1.05, 2.36, 0.55, 0.17, 0.17, 0.17)
    save(m, "warcamp")


def pit():
    m = new()
    S, H = 2.0, 0.55
    for (cx, cz, sx, sz) in ((0, -S / 2, S, 0.16), (-S / 2, 0, 0.16, S), (S / 2, 0, 0.16, S),
                             (-0.62, S / 2, 0.76, 0.16), (0.62, S / 2, 0.76, 0.16)):
        m.box("Logs", cx, H / 2, cz, sx, H, sz)
        # pointed stakes along the top
        n = max(1, int(round(max(sx, sz) / 0.26)))
        for k in range(n):
            t = (k + 0.5) / n - 0.5
            px, pz = (cx + t * sx, cz) if sx > sz else (cx, cz + t * sz)
            m.frustum("LogsLt", px, H, pz, 0.11, 0.0, 0.2, n=4, rot=45)
    # a war drum by the gate and a target post inside
    m.frustum("Hide", 0.62, 0, 1.32, 0.28, 0.28, 0.36, n=8)
    m.frustum("Bone", 0.62, 0.36, 1.32, 0.28, 0.28, 0.03, n=8)
    m.box("Logs", 0, 0.4, -0.1, 0.12, 0.8, 0.12)
    m.box("Hide", 0, 0.62, -0.1, 0.36, 0.24, 0.16)
    # the tall banner pole at the back corner, a skull on top
    m.box("Logs", -0.85, 1.25, -0.85, 0.1, 2.5, 0.1)
    m.box("Hide", -0.62, 2.0, -0.85, 0.4, 0.62, 0.05)
    m.box("Bone", -0.85, 2.58, -0.85, 0.19, 0.19, 0.19)
    save(m, "pit")


def lookout():
    m = new()
    for px, pz in ((0.33, 0.33), (-0.33, 0.33), (0.33, -0.33), (-0.33, -0.33)):
        m.box("Logs", px, 0.82, pz, 0.11, 1.64, 0.11, R=rot_z(-4 * (1 if px > 0 else -1)) @ rot_x(4 * (1 if pz > 0 else -1)),
              pivot=(px, 1.6, pz))
    m.box("LogsLt", 0, 0.8, 0.36, 0.07, 0.95, 0.07, R=rot_z(42), pivot=(0, 0.8, 0.36))
    m.box("LogsLt", 0.36, 0.8, 0, 0.07, 0.95, 0.07, R=rot_x(42), pivot=(0.36, 0.8, 0))
    m.box("Logs", 0, 1.64, 0, 1.0, 0.12, 1.0, skip_down=False)
    for (cx, cz, sx, sz) in ((0, 0.47, 1.0, 0.07), (0, -0.47, 1.0, 0.07), (0.47, 0, 0.07, 1.0), (-0.47, 0, 0.07, 1.0)):
        m.box("LogsLt", cx, 1.83, cz, sx, 0.26, sz)
    for px, pz in ((0.4, 0.4), (-0.4, 0.4), (0.4, -0.4), (-0.4, -0.4)):
        m.box("Logs", px, 2.0, pz, 0.07, 0.45, 0.07)
    m.frustum("Hide", 0, 2.2, 0, 0.82, 0.0, 0.62, n=4, rot=45, bottom=True)
    m.box("Bone", 0, 2.86, 0, 0.16, 0.16, 0.16)
    save(m, "lookout")


def tent():
    m = new()
    n = 8
    for i in range(n):
        a0 = math.radians(22.5 + 45 * i)
        a1 = math.radians(22.5 + 45 * (i + 1))
        p0 = (math.cos(a0) * 0.68, 0, math.sin(a0) * 0.68)
        p1 = (math.cos(a1) * 0.68, 0, math.sin(a1) * 0.68)
        m.add("Hide" if i % 2 == 0 else "HideDk", [[p0, p1, (0, 1.2, 0)]], centre=(0, 0.4, 0))
    for k in range(3):
        a = math.radians(30 + 120 * k)
        m.box("LogsLt", math.cos(a) * 0.08, 1.3, math.sin(a) * 0.08, 0.07, 0.4, 0.07,
              R=rot_y(-math.degrees(a)) @ rot_z(20), pivot=(math.cos(a) * 0.08, 1.15, math.sin(a) * 0.08))
    m.add("Dark", [[(-0.22, 0.02, 0.62), (0.22, 0.02, 0.62), (0, 0.5, 0.45)]], out=(0, 0.2, 1))
    m.box("Bone", 0, 0.62, 0.42, 0.12, 0.12, 0.08)
    save(m, "tent")


# ================================================================ resources, carried loads, projectiles, scaffold

PINES = [(-0.36, -0.22), (0.38, -0.12), (0.0, 0.36)]


def grove():
    m = new()
    for i, (px, pz) in enumerate(PINES):
        s = (1.0, 0.85, 0.92)[i]
        m.box("Bark", px, 0.18 * s, pz, 0.15, 0.36 * s, 0.15)
        m.frustum("Leaf", px, 0.3 * s, pz, 0.5 * s, 0.0, 0.75 * s, n=6, rot=15 * i, bottom=True)
        m.frustum("Leaf", px, 0.72 * s, pz, 0.38 * s, 0.0, 0.62 * s, n=6, rot=15 * i + 30, bottom=True)
        m.frustum("Leaf", px, 1.1 * s, pz, 0.25 * s, 0.0, 0.5 * s, n=6, rot=15 * i, bottom=True)
    save(m, "grove")


def sack():
    m = new()
    m.blob("Sack", 0, 0.16, 0, 0.17, sy=1.0, seed=5)
    m.box("Wood", 0, 0.32, 0, 0.12, 0.05, 0.12)
    m.blob("Gold", 0.03, 0.37, 0.0, 0.09, seed=6)
    save(m, "sack")


def logs():
    m = new()
    for x, y in ((-0.075, 0.07), (0.075, 0.07), (0.0, 0.19)):
        m.frustum("LogsLt", x, y, -0.27, 0.075, 0.075, 0.54, n=6, R=rot_x(90), bottom=True)
    save(m, "logs")


def arrow():
    m = new()
    m.box("Shaft", 0, 0, 0, 0.06, 0.06, 0.5)
    m.frustum("Blade", 0, 0, 0.25, 0.06, 0, 0.12, n=4, rot=45, R=rot_x(90), bottom=True)
    m.box("Team", 0, 0, -0.22, 0.12, 0.03, 0.1)
    save(m, "arrow")


def spear():
    m = new()
    m.box("Wood", 0, 0, 0, 0.07, 0.07, 0.8)
    m.frustum("Blade", 0, 0, 0.4, 0.08, 0, 0.18, n=4, rot=45, R=rot_x(90), bottom=True)
    m.box("Hide", 0, 0, -0.3, 0.1, 0.1, 0.08)
    save(m, "spear")


def scaffold():
    m = new()
    S = 1.0
    for px, pz in ((S, S), (-S, S), (S, -S), (-S, -S)):
        m.box("LogsLt", px, 0.85, pz, 0.08, 1.7, 0.08)
    for y in (0.55, 1.25):
        m.box("LogsLt", 0, y, S, 2 * S + 0.08, 0.07, 0.07)
        m.box("LogsLt", 0, y, -S, 2 * S + 0.08, 0.07, 0.07)
        m.box("LogsLt", S, y, 0, 0.07, 0.07, 2 * S + 0.08)
        m.box("LogsLt", -S, y, 0, 0.07, 0.07, 2 * S + 0.08)
    for s in (-1, 1):
        m.box("Wood", 0, 0.9, S * s, 2.2, 0.07, 0.07, R=rot_z(32), pivot=(0, 0.9, S * s))
        m.box("Wood", S * s, 0.9, 0, 0.07, 0.07, 2.2, R=rot_x(32), pivot=(S * s, 0.9, 0))
    save(m, "scaffold")


for f in (yeoman, swordsman, archer, drudge, brute, thrower, yard, watchtower, cottage, warcamp, pit, lookout,
          tent, grove, sack, logs, arrow, spear, scaffold):
    f()
