# Border War's map, in world metres (Y up, x to the right of the screen, z towards the camera:
# the bottom of the screen). The same numbers are written into scene/game.as (search "LAYOUT").
# Point-symmetric: the orc side is the human side turned 180 degrees about the origin.
import math

PLAY_X = 9.3            # playable x -PLAY_X..PLAY_X
PLAY_Z0, PLAY_Z1 = -7.0, 7.2

HALL_H = (-6.6, 4.6)    # the Manor (human hall)
MINE_H = (-8.3, 1.4)    # the human side's gold deposit
GROVES_H = [(-3.6, 6.4), (-1.9, 6.6), (-0.2, 6.3)]   # harvestable pine groves (game bones)

def mirror(p):
    return (-p[0], -p[1])

HALL_O = mirror(HALL_H)
MINE_O = mirror(MINE_H)
GROVES_O = [mirror(g) for g in GROVES_H]

# the river, top-left to bottom-right through the middle; two fords are the only crossings
RIVER = [(-11.0, -9.0), (-7.5, -6.2), (-4.4, -3.3), (-1.6, -1.4), (0.0, 0.0), (1.6, 1.4), (4.4, 3.3),
         (7.5, 6.2), (11.0, 9.0)]
FORDS = [(-4.4, -3.3), (4.4, 3.3)]
FORD_R = 1.0            # along the river, the ford's half length
WATER_W = 0.55          # half width of the water
BANK_W = 0.9            # half width of the channel (water + muddy bank)

# dirt paths (polylines), half width
PATH_W = 0.32
PATHS_H = [
    [(-6.2, 3.8), (-5.9, 2.2), (-5.4, 0.4), (-4.9, -1.6), (-4.6, -2.6)],          # manor -> west ford
    [(-5.6, 4.6), (-3.4, 4.3), (-1.0, 3.9), (1.6, 3.5), (3.7, 3.6)],               # manor -> east ford
    [(-7.2, 3.6), (-7.8, 2.4)],                                                     # manor -> gold
]
PATHS_O = [[mirror(p) for p in path] for path in PATHS_H]

# building spots the computer (and the demo's human) uses; the player builds anywhere valid
SPOTS_H = {"yard": (-4.3, 2.7), "tower0": (-4.0, -0.6), "tower1": (-1.4, 2.6),
           "cottage0": (-8.2, 6.1), "cottage1": (-5.6, 6.3)}
SPOTS_O = {k: mirror(v) for k, v in SPOTS_H.items()}


def seg_dist(p, a, b):
    ax, az = a
    bx, bz = b
    px, pz = p
    dx, dz = bx - ax, bz - az
    L = dx * dx + dz * dz
    t = 0.0 if L == 0 else max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / L))
    qx, qz = ax + dx * t, az + dz * t
    return math.hypot(px - qx, pz - qz), t


def poly_dist(p, pts):
    best = 1e9
    for i in range(len(pts) - 1):
        d, _ = seg_dist(p, pts[i], pts[i + 1])
        best = min(best, d)
    return best


def river_dist(p):
    return poly_dist(p, RIVER)


def ford_dist(p):
    return min(math.hypot(p[0] - f[0], p[1] - f[1]) for f in FORDS)


def river_points(step):
    """Points along the river every `step` metres, with the unit normal there."""
    out = []
    for i in range(len(RIVER) - 1):
        a, b = RIVER[i], RIVER[i + 1]
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        n = max(1, int(L / step))
        tx, tz = (b[0] - a[0]) / L, (b[1] - a[1]) / L
        for k in range(n):
            t = k / n
            out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, -tz, tx))
    return out
