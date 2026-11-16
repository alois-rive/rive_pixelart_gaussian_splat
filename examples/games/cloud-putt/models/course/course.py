# The Cloud Putt course: nine holes on one floating cloud island, as data. One source for the
# meshes (make_course.py writes hedra command files from it) and for the game (make_course.py
# writes the data block of scene/game.as from it), and for the Python port of the physics (sim.py).
#
# World: glTF metres, Y up, +Z towards the camera (yaw 0). The island's cloud ground is at y 0; the
# felt of every green at FELT + h(x, z), h a sum of terms per hole. Holes are written in local
# coordinates (x right, z towards the camera) around their cell centre and shifted into the world.
import math

FELT = 0.12        # felt above the cloud ground
R = 0.16           # ball radius
CUP_R = 0.26       # cup radius
WALL_HALF = 0.1    # half the thickness of a wooden border
WALL_UP = 0.24     # a border's top above the felt next to it

# F kinds for separable terms H * F(x) * F(z)
ONE, SMOOTH, LIN, KICK, ARCH, BOX = 0, 1, 2, 3, 4, 5
SEP, BUMP = 0, 1

CELL_X = [-12.0, 0.0, 12.0]
CELL_Z = [-8.4, 0.0, 8.4]
# the snake: 1-3 along the back row, 4-6 back along the middle, 7-9 along the front
ISLAND_A, ISLAND_B, ISLAND_N = 19.4, 13.5, 8   # the island: |x/A|^N + |z/B|^N = 1
CELLS = [(0, 0), (1, 0), (2, 0), (2, 1), (1, 1), (0, 1), (0, 2), (1, 2), (2, 2)]

# windmill of hole 1 (local): the hero model (across flats 2.2, tunnel 0.67 wide, hub 1.62 up, sails'
# plane 1.16 in front of its centre) baked at MILL_S times its size
MILL_S = 1.3
MILL = (-1.6, -1.55)
TUN = 0.335 * MILL_S
MILL_FRONT = round(MILL[1] + 1.1 * MILL_S, 3)
MILL_BACK = round(MILL[1] - 1.1 * MILL_S, 3)
MILL_Y = 0.6     # the deck under the mill


def sep(H, fx=(ONE, 0, 0), fz=(ONE, 0, 0)):
    return (SEP, H, fx[0], fx[1], fx[2], fz[0], fz[1], fz[2])


def bump(x, z, A, s):
    return (BUMP, A, x, z, s, 0, 0, 0)


HOLES = [
    dict(name="THE MILL", par=3, tee=(-1.6, 2.5), cup=(2.9, -1.6),
         felt=[(-3.2, MILL_FRONT, 0.0, 3.1), (MILL[0] - TUN, MILL_BACK, MILL[0] + TUN, MILL_FRONT),
               (-3.2, -3.95, 0.0, MILL_BACK), (0.0, -3.95, 4.9, 1.2)],
         walls=[[(-3.2, MILL_FRONT), (-3.2, 3.1), (0.0, 3.1), (0.0, MILL_BACK)],
                [(-3.2, MILL_FRONT), (MILL[0] - TUN, MILL_FRONT)], [(MILL[0] + TUN, MILL_FRONT), (0.0, MILL_FRONT)],
                [(-3.2, MILL_BACK), (MILL[0] - TUN, MILL_BACK)], [(MILL[0] + TUN, MILL_BACK), (0.0, MILL_BACK)],
                [(-3.2, MILL_BACK), (-3.2, -3.95), (4.9, -3.95), (4.9, 1.2), (0.0, 1.2)]],
         hidden=[[(MILL[0] - TUN, MILL_FRONT), (MILL[0] - TUN, MILL_BACK)], [(MILL[0] + TUN, MILL_FRONT), (MILL[0] + TUN, MILL_BACK)]],
         plinths=[(-3.2, MILL_BACK, 0.0, MILL_FRONT, MILL_Y)],
         terms=[sep(MILL_Y, (SMOOTH, 0.4, 0.0), (SMOOTH, MILL_BACK, MILL_FRONT)),      # the raised deck the mill stands on
                sep(MILL_Y, (LIN, 0.4, -3.2), (SMOOTH, MILL_FRONT, MILL_BACK)),       # behind the mill: down to the pocket
                sep(0.05, (ONE, 0, 0), (LIN, -3.95, 1.2)),                            # the pocket leans to the north
                bump(2.9, -1.6, -0.03, 0.35)]),
    dict(name="THE HUMP", par=2, tee=(-4.1, 0.5), cup=(3.3, 0.35),
         felt=[(-4.9, -1.5, 4.9, 1.5)],
         walls=[[(-4.9, -1.5), (-4.9, 1.5), (4.9, 1.5), (4.9, -1.5), (-4.9, -1.5)]],
         terms=[bump(0.3, -0.25, 0.32, 0.8), sep(0.07, (SMOOTH, 1.5, 4.9), (ONE, 0, 0)),
                bump(3.3, 0.35, -0.03, 0.35)]),
    dict(name="BROOK BRIDGE", par=3, tee=(-4.1, 1.8), cup=(3.2, -1.2),
         felt=[(-4.9, -2.6, 4.9, 2.6)],
         walls=[[(-4.9, -2.6), (-4.9, 2.6), (4.9, 2.6), (4.9, -2.6), (-4.9, -2.6)]],
         water=[(-1.0, -2.6, 1.0, 2.6)], bridge=(-1.0, -0.5, 1.0, 0.5, 0.2),
         terms=[sep(-0.08, (SMOOTH, -3.0, -1.0), (ONE, 0, 0)),    # the near bank leans to the brook
                sep(0.08, (SMOOTH, 1.0, 3.0), (ONE, 0, 0)),       # the far bank rises from it
                sep(0.1, (SMOOTH, 1.0, 3.0), (LIN, -2.6, 2.6)),   # and leans towards the cup's side
                bump(3.2, -1.2, -0.03, 0.35)]),
    dict(name="SLIDING GATES", par=3, tee=(4.1, 0.0), cup=(-3.4, 0.2),
         felt=[(-4.9, -1.4, 4.9, 1.4)],
         walls=[[(-4.9, -1.4), (-4.9, 1.4), (4.9, 1.4), (4.9, -1.4), (-4.9, -1.4)]],
         blocks=[(1.5, 0.0, 0.25, 0.55, 1, 0.85, 3.2, 0.0), (-1.3, 0.0, 0.25, 0.55, 1, 0.85, 2.6, 1.1)],
         terms=[sep(0.06, (ONE, 0, 0), (LIN, 1.4, -1.4)), bump(-3.4, 0.2, -0.03, 0.35)]),
    dict(name="CLOUD GAP", par=3, tee=(4.1, 0.0), cup=(-3.4, -0.2),
         felt=[(-4.9, -1.3, -1.0, 1.3), (0.4, -1.3, 4.9, 1.3)],
         walls=[[(-4.9, -1.3), (-4.9, 1.3), (4.9, 1.3), (4.9, -1.3), (-4.9, -1.3)]],
         gap=[(-1.0, -1.3, 0.4, 1.3)],
         terms=[sep(0.42, (KICK, 1.6, 0.4), (ONE, 0, 0)), bump(-3.4, -0.2, -0.03, 0.35)]),
    dict(name="STEP UP", par=3, tee=(3.9, 2.2), cup=(-3.2, -1.9),
         felt=[(-4.9, -3.0, 4.9, 3.0)],
         walls=[[(-4.9, -3.0), (-4.9, 3.0), (4.9, 3.0), (4.9, -3.0), (-4.9, -3.0)],
                [(-1.3, -3.0), (-1.3, -1.6)]],
         terms=[sep(0.5, (ONE, 0, 0), (SMOOTH, 0.6, -0.6)), bump(-3.2, -1.9, -0.04, 0.4)]),
    dict(name="BUMPER GARDEN", par=3, tee=(-4.1, 2.0), cup=(3.5, -1.4),
         felt=[(-4.9, -2.8, 4.9, 2.8)],
         walls=[[(-4.9, -2.8), (-4.9, 2.8), (4.9, 2.8), (4.9, -2.8), (-4.9, -2.8)]],
         posts=[(-2.3, 1.0, 0.3), (-1.0, -0.6, 0.3), (0.2, 1.1, 0.3), (1.3, -0.2, 0.3),
                (2.6, 0.9, 0.3), (2.5, -1.7, 0.3), (-0.3, -2.0, 0.3)],
         terms=[sep(0.08, (LIN, 4.9, -4.9), (ONE, 0, 0)), bump(3.5, -1.4, -0.03, 0.35)]),
    dict(name="DOGLEG BANK", par=3, tee=(-4.1, 1.7), cup=(3.25, -2.0),
         felt=[(-4.9, 0.4, 4.9, 3.0), (1.6, -3.2, 4.9, 0.4)],
         walls=[[(-4.9, 0.4), (-4.9, 3.0), (3.7, 3.0), (4.9, 1.8), (4.9, -3.2), (1.6, -3.2), (1.6, 0.4), (-4.9, 0.4)]],
         terms=[sep(0.14, (ONE, 0, 0), (LIN, -3.2, 3.0)), sep(-0.08, (ONE, 0, 0), (LIN, 0.4, 3.0)),
                bump(3.25, -2.0, -0.03, 0.35)]),
    dict(name="SKY SUMMIT", par=3, tee=(-4.1, 2.2), cup=(2.3, -0.5),
         felt=[(-4.9, -3.0, 4.9, 3.0)],
         walls=[[(-4.9, -3.0), (-4.9, 3.0), (4.9, 3.0), (4.9, -3.0), (-4.9, -3.0)]],
         water=[(2.2, 1.7, 4.9, 3.0)],
         terms=[bump(2.3, -0.5, 0.3, 1.0), bump(2.3, -0.5, -0.07, 0.42)]),
]


def F(kind, a, b, u):
    if kind == ONE:
        return 1.0
    if kind == SMOOTH:
        t = min(1.0, max(0.0, (u - a) / (b - a)))
        return t * t * (3 - 2 * t)
    if kind == LIN:
        return min(1.0, max(0.0, (u - a) / (b - a)))
    if kind == KICK:
        t = (u - a) / (b - a)
        return t if 0.0 <= t <= 1.0 else 0.0
    if kind == ARCH:
        t = (u - a) / b
        return max(0.0, 1.0 - t * t)
    if kind == BOX:
        return 1.0 if a <= u <= b else 0.0
    return 0.0


def shift(kind, a, b, c):
    """A term factor's two numbers moved by the cell centre c: both are coordinates, except
    ARCH's second (a half width) and ONE's (unused)."""
    if kind == ONE:
        return (a, b)
    if kind == ARCH:
        return (a + c, b)
    return (a + c, b + c)


def world_holes():
    """The holes in world coordinates (everything shifted by the cell centre)."""
    out = []
    for i, h in enumerate(HOLES):
        cx, cz = CELL_X[CELLS[i][0]], CELL_Z[CELLS[i][1]]
        def p(q):
            return (q[0] + cx, q[1] + cz)
        def rect(r):
            return (r[0] + cx, r[1] + cz, r[2] + cx, r[3] + cz)
        w = dict(index=i, name=h["name"], par=h["par"], cx=cx, cz=cz,
                 tee=p(h["tee"]), cup=p(h["cup"]),
                 felt=[rect(r) for r in h["felt"]],
                 walls=[[p(q) for q in line] for line in h["walls"]],
                 hidden=[[p(q) for q in line] for line in h.get("hidden", [])],
                 water=[rect(r) for r in h.get("water", [])],
                 gap=[rect(r) for r in h.get("gap", [])],
                 posts=[(x + cx, z + cz, r) for (x, z, r) in h.get("posts", [])],
                 blocks=[(b[0] + cx, b[1] + cz) + tuple(b[2:]) for b in h.get("blocks", [])],
                 plinths=[rect(r[:4]) + (r[4],) for r in h.get("plinths", [])])
        if "bridge" in h:
            b = h["bridge"]
            w["bridge"] = (b[0] + cx, b[1] + cz, b[2] + cx, b[3] + cz, b[4])
        terms = []
        for t in h["terms"]:
            if t[0] == BUMP:
                terms.append((BUMP, t[1], t[2] + cx, t[3] + cz, t[4], 0, 0, 0))
            else:
                k1, a1, b1, k2, a2, b2 = t[2:]
                terms.append((SEP, t[1], k1) + shift(k1, a1, b1, cx) + (k2,) + shift(k2, a2, b2, cz))
        if "bridge" in w:
            b = w["bridge"]
            # the arch over the brook, only on the bridge: a box in z keeps it off the water
            terms.append((SEP, b[4], ARCH, (b[0] + b[2]) / 2, (b[2] - b[0]) / 2, BOX, b[1], b[3]))
        w["terms"] = terms
        out.append(w)
    return out


def height(w, x, z):
    h = 0.0
    for t in w["terms"]:
        if t[0] == BUMP:
            dx, dz = x - t[2], z - t[3]
            h += t[1] * math.exp(-(dx * dx + dz * dz) / (2 * t[4] * t[4]))
        else:
            h += t[1] * F(t[2], t[3], t[4], x) * F(t[5], t[6], t[7], z)
    return h


def in_rect(r, x, z, m=0.0):
    return r[0] - m <= x <= r[2] + m and r[1] - m <= z <= r[3] + m


def segments(w, with_hidden=True):
    segs = []
    for line in w["walls"] + (w["hidden"] if with_hidden else []):
        for a, b in zip(line[:-1], line[1:]):
            segs.append((a[0], a[1], b[0], b[1]))
    return segs
