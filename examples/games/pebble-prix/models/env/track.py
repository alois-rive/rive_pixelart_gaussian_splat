# Pebble Prix's one circuit: the centreline, the walls, the racing line, the speed profile and the
# camera's heading, all from one segment list. Imported by make_env.py (the geometry), sim.py (the
# throwaway Python port of the game) and write_tables() (the tables pasted into scene/game.as).
#
# Map coordinates: x east, y north (metres). World (glTF, the renderer): X = x, Y up, Z = -y.
# A world heading psi (degrees) points along (sin psi, cos psi) in (X, Z): the yaw api.place() takes
# for a model whose front is +Z. Right of the heading: (-cos psi, sin psi). Offsets n > 0 are right.
import math
import numpy as np

HALF = 3.5            # half the track width
STEP = 1.0            # metres between centreline samples
CAR_R = 0.85          # a car's collision radius

# the loop, counter-clockwise seen from above (map), starting on the harbour straight heading east
SEGS = [
    ("S", 42.0),              # 0 the harbour straight (the quay and the sea on the right)
    ("A", 7.0, 180.0),        # 1 the lighthouse hairpin
    ("S", 12.0),              # 2 the back row
    ("A", 6.5, -180.0),       # 3 the first switchback
    ("S", 10.0),              # 4 the vineyard row
    ("A", 6.5, 180.0),        # 5 the second switchback
    ("S", 40.0),              # 6 the village street (the arch)
    ("A", 10.0, 90.0),        # 7 the church corner
    ("S", 20.0),              # 8 the bridge run (the stone bridge over the creek)
    ("A", 10.0, 90.0),        # 9 the beach corner onto the harbour
]
START = (-21.0, 0.0, 0.0)     # map x, y, heading (radians)
LINE_X = -6.0                 # the start / finish line on the harbour straight (map x)

# features along the lap, by map position
ARCH = (-3.0, 40.0)           # the arch over the village street
BRIDGE = (-31.0, 20.0)        # the stone bridge (the creek runs west under it)
LIGHTHOUSE = (35.5, 7.0)
POND = (-12.0, 19.0, 4.0)
CREEK = [(-12.0, 19.0), (-20.0, 20.5), (-28.0, 20.0), (-34.0, 20.0), (-44.0, 21.0)]
CREEK_W = 3.4
QUAY_Y = -5.6                 # the harbour's quay edge (map y), sea south of it

def seg_len(sg):
    return sg[1] if sg[0] == "S" else abs(math.radians(sg[2])) * sg[1]

def walk(segs, start, step):
    """points (x, y, heading, curvature, segment index) every `step` metres"""
    x, y, h = start
    out = []
    carry = 0.0
    for si, sg in enumerate(segs):
        L = seg_len(sg)
        t = carry
        while t < L - 1e-9:
            if sg[0] == "S":
                px, py, ph, k = x + math.cos(h) * t, y + math.sin(h) * t, h, 0.0
            else:
                r, ang = sg[1], math.radians(sg[2])
                sgn = 1.0 if ang > 0 else -1.0
                cx, cy = x - sgn * r * math.sin(h), y + sgn * r * math.cos(h)
                ph = h + sgn * t / r
                px, py = cx + sgn * r * math.sin(ph), cy - sgn * r * math.cos(ph)
                k = sgn / r
            out.append((px, py, ph, k, si))
            t += step
        carry = t - L
        # the segment's end pose
        if sg[0] == "S":
            x, y = x + math.cos(h) * L, y + math.sin(h) * L
        else:
            r, ang = sg[1], math.radians(sg[2])
            sgn = 1.0 if ang > 0 else -1.0
            cx, cy = x - sgn * r * math.sin(h), y + sgn * r * math.cos(h)
            h = h + ang
            x, y = cx + sgn * r * math.sin(h), cy - sgn * r * math.cos(h)
    return out, (x, y, h)

LENGTH = sum(seg_len(s) for s in SEGS)

def centreline(step=STEP):
    """samples starting AT the start line, so s = 0 is the line; returns arrays in map coords"""
    pts, end = walk(SEGS, START, step / 8.0)
    assert abs(end[0] - START[0]) < 1e-6 and abs(end[1] - START[1]) < 1e-6, end
    pts = np.array([(p[0], p[1], p[2], p[3], p[4]) for p in pts])
    # rotate so index 0 is at the line
    s0 = LINE_X - START[0]
    n = int(round(LENGTH / step))
    s = (np.arange(n) * (LENGTH / n) + s0) % LENGTH
    fine = np.arange(len(pts)) * (step / 8.0)
    idx = np.searchsorted(fine, s, side="right") - 1
    frac = (s - fine[idx]) / (step / 8.0)
    nxt = (idx + 1) % len(pts)
    x = pts[idx, 0] + (pts[nxt, 0] - pts[idx, 0]) * frac
    y = pts[idx, 1] + (pts[nxt, 1] - pts[idx, 1]) * frac
    dh = np.angle(np.exp(1j * (pts[nxt, 2] - pts[idx, 2])))
    h = pts[idx, 2] + dh * frac
    k = pts[idx, 3]
    seg = pts[idx, 4].astype(int)
    return {"x": x, "y": y, "h": h, "k": k, "seg": seg, "n": n, "ds": LENGTH / n}

def world(x, y):
    return x, -y

def psi_deg(h):
    """map heading (radians) -> world yaw (degrees)"""
    return 90.0 + np.degrees(h)

def normals(c):
    """map-space right-hand normals"""
    return np.stack([np.sin(c["h"]), -np.cos(c["h"])], 1)

def dist_to_polyline(px, py, xs, ys):
    """distance from points to a closed polyline (vectorised)"""
    ax, ay = xs, ys
    bx, by = np.roll(xs, -1), np.roll(ys, -1)
    P = np.stack([px.ravel(), py.ravel()], 1)
    best = np.full(len(P), 1e9)
    for i in range(len(ax)):
        dx, dy = bx[i] - ax[i], by[i] - ay[i]
        L2 = dx * dx + dy * dy
        t = np.clip(((P[:, 0] - ax[i]) * dx + (P[:, 1] - ay[i]) * dy) / max(L2, 1e-12), 0, 1)
        qx, qy = ax[i] + t * dx, ay[i] + t * dy
        d = np.hypot(P[:, 0] - qx, P[:, 1] - qy)
        best = np.minimum(best, d)
    return best.reshape(px.shape)

def in_box(px, py, x0, x1, y0, y1):
    return x0 <= px <= x1 and y0 <= py <= y1

def walls(c):
    """per sample: the distance from the centre to a barrier on the left and the right, and what the
    ground is beyond the track edge on each side (0 grass, 1 sand, 2 paving). Barriers: half way to
    any other part of the track (the switchback rows, so nobody cuts across), the quay, the street's
    house fronts, the bridge's parapets, the arch, the coast."""
    n = c["n"]
    N = normals(c)
    wl = np.full(n, 11.0)
    wr = np.full(n, 11.0)
    gl = np.zeros(n, int)
    gr = np.zeros(n, int)
    xs, ys = c["x"], c["y"]
    for i in range(n):
        for side, arr in ((1, wr), (-1, wl)):
            nx, ny = N[i] * side
            # other parts of the track along this normal
            for j in range(n):
                ds = min(abs(i - j), n - abs(i - j)) * c["ds"]
                if ds < 22:
                    continue
                vx, vy = xs[j] - xs[i], ys[j] - ys[i]
                along = vx * nx + vy * ny
                perp = abs(-vx * ny + vy * nx)
                if 0 < along < 24 and perp < 1.2:
                    arr[i] = min(arr[i], along * 0.5)
    for i in range(n):
        x, y, seg = xs[i], ys[i], c["seg"][i]
        if seg == 0:                       # harbour straight: quay edge on the right (south)
            wr[i] = min(wr[i], y - QUAY_Y)
            gr[i] = 2
            gl[i] = 2 if x < 15 else 0
        if seg == 9 or (seg == 0 and x < -14):
            gl[i] = 1 if seg == 9 else gl[i]
            gr[i] = 1 if seg == 9 else gr[i]
        if seg == 8:                       # the bridge run: sand on the right (west, the beach)
            gr[i] = 1
        if seg == 6:                       # the village street: house fronts both sides
            wl[i] = min(wl[i], 5.3)
            wr[i] = min(wr[i], 5.3)
            gl[i] = 2
            gr[i] = 2
            if abs(x - ARCH[0]) < 2.0:     # the arch's pillars
                wl[i] = min(wl[i], 4.1)
                wr[i] = min(wr[i], 4.1)
        if seg == 8 and abs(y - BRIDGE[1]) < 4.5:   # the bridge's parapets
            wl[i] = min(wl[i], 4.2)
            wr[i] = min(wr[i], 4.2)
            gl[i] = 2
            gr[i] = 2
        if seg in (7, 8, 9):               # the coast to the west
            wr[i] = min(wr[i], 9.0)
        if seg == 1:                       # the headland: rocks round the lighthouse hairpin
            wr[i] = min(wr[i], 8.0)
    return wl, wr, gl, gr

def racing_line(c, wl, wr, iters=4000):
    """a minimum-curvature line inside the track (and inside any barrier), by relaxation"""
    n = c["n"]
    N = normals(c)
    lim = HALF - CAR_R - 0.25
    lo = -np.minimum(lim, wl - CAR_R - 0.3)
    hi = np.minimum(lim, wr - CAR_R - 0.3)
    off = np.zeros(n)
    for it in range(iters):
        px = c["x"] + N[:, 0] * off
        py = c["y"] + N[:, 1] * off
        mx = 0.5 * (np.roll(px, 1) + np.roll(px, -1))
        my = 0.5 * (np.roll(py, 1) + np.roll(py, -1))
        # pull each point toward the midpoint of its neighbours, along the normal only
        d = (mx - px) * N[:, 0] + (my - py) * N[:, 1]
        off = np.clip(off + 0.5 * d, lo, hi)
    return off

def path_curvature(px, py, ds):
    ax, ay = np.roll(px, 1), np.roll(py, 1)
    bx, by = np.roll(px, -1), np.roll(py, -1)
    h1 = np.arctan2(py - ay, px - ax)
    h2 = np.arctan2(by - py, bx - px)
    dh = np.angle(np.exp(1j * (h2 - h1)))
    seg = 0.5 * (np.hypot(px - ax, py - ay) + np.hypot(bx - px, by - py))
    return dh / np.maximum(seg, 1e-6)

def speed_profile(c, off, vtop=14.0, alat=12.5, accel=5.0, brake=9.0):
    N = normals(c)
    px = c["x"] + N[:, 0] * off
    py = c["y"] + N[:, 1] * off
    k = path_curvature(px, py, c["ds"])
    # smooth the curvature a little (the line is sampled at 1 m)
    for _ in range(2):
        k = (np.roll(k, 1) + 2 * k + np.roll(k, -1)) / 4
    v = np.minimum(vtop, np.sqrt(alat / np.maximum(np.abs(k), 1e-4)))
    seglen = np.hypot(np.roll(px, -1) - px, np.roll(py, -1) - py)
    n = len(v)
    for _ in range(3):
        for i in range(2 * n):              # accelerate forwards
            a, b = i % n, (i + 1) % n
            v[b] = min(v[b], math.sqrt(v[a] ** 2 + 2 * accel * seglen[a]))
        for i in range(2 * n, 0, -1):       # brake backwards
            a, b = i % n, (i - 1) % n
            v[b] = min(v[b], math.sqrt(v[a] ** 2 + 2 * brake * seglen[b]))
    return v, k

def camera_yaw(c, window=50.0):
    """the camera's heading: the track's direction averaged over a long window, so the switchbacks
    read as one climb and the camera turns slowly. World degrees, unwrapped to be continuous."""
    n = c["n"]
    w = int(round(window / c["ds"]))
    tx, ty = np.cos(c["h"]), np.sin(c["h"])
    sx = np.zeros(n)
    sy = np.zeros(n)
    for o in range(-w // 3, w + 1):        # look ahead more than behind
        sx += np.roll(tx, -o)
        sy += np.roll(ty, -o)
    h = np.arctan2(sy, sx)
    # a second, short smoothing on the angle
    z = np.exp(1j * h)
    for _ in range(6):
        z = (np.roll(z, 1) + 2 * z + np.roll(z, -1)) / 4
    return np.degrees(np.unwrap(np.angle(z))) + 90.0

# boost strips: (map x, map y) where each starts, 3 m long, across the full width
def boost_strips(c):
    want = [(6.0, 0.0), (8.0, 40.0), (-31.0, 12.5)]
    out = []
    for (x, y) in want:
        d = np.hypot(c["x"] - x, c["y"] - y)
        out.append(int(np.argmin(d)))
    return out

def props(c):
    """the trackside things a car bumps: hay bales on the outside of the hairpins and corners, oil
    drums in threes, the gantry's posts; and the cones on the inside of every hairpin (knocked flying).
    Map coordinates. Returns obstacles [(kind, x, y, r)] (0 hay, 1 drum, 2 post) and cones [(x, y)]."""
    N = normals(c)
    obs, cones = [], []
    seg = c["seg"]
    for s_id in (1, 3, 5, 7, 9):
        idx = np.where(seg == s_id)[0]
        k = c["k"][idx[0]]
        out = 1.0 if k > 0 else -1.0          # a left turn's outside is on the right
        if s_id in (1, 3, 5):                 # hay bales round the hairpins, every 2.4 m
            for i in idx[2:-2:2]:
                if (i - idx[0]) % 4 == 0 or len(idx) < 12:
                    p = np.array([c["x"][i], c["y"][i]]) + N[i] * out * (HALF + 1.5)
                    obs.append((0, p[0], p[1], 0.75))
        else:                                 # oil drums in threes on the outside of the corners
            mid = idx[len(idx) // 2]
            for o, dn in ((-1, 0.0), (0, 0.5), (1, 0.0)):
                i = (mid + 2 * o) % c["n"]
                p = np.array([c["x"][i], c["y"][i]]) + N[i] * out * (HALF + 1.4 + dn)
                obs.append((1, p[0], p[1], 0.45))
        # cones on the inside, at the apex and either side of it
        m = len(idx)
        picks = (idx[m // 3], idx[2 * m // 3]) if s_id in (7, 9) else (idx[m // 5], idx[m // 2], idx[4 * m // 5])
        for i in picks:
            p = np.array([c["x"][i], c["y"][i]]) - N[i] * out * (HALF + 0.35)
            cones.append((p[0], p[1]))
    # the gantry's posts either side of the line
    for side in (-1, 1):
        p = np.array([c["x"][0], c["y"][0]]) + N[0] * side * (HALF + 0.9)
        obs.append((2, p[0], p[1], 0.35))
    return obs, cones

def build():
    c = centreline()
    wl, wr, gl, gr = walls(c)
    off = racing_line(c, wl, wr)
    v, k = speed_profile(c, off)
    cam = camera_yaw(c)
    obs, cones = props(c)
    zones = []
    for sid in (1, 3, 5, 7, 9):
        idx = np.where(c["seg"] == sid)[0]
        zones.append(((idx[0] * c["ds"] - 3.0) % LENGTH, (idx[-1] * c["ds"] - 2.5) % LENGTH,
                      1.0 if c["k"][idx[0]] > 0 else -1.0))
    return {"zones": zones, "c": c, "wl": wl, "wr": wr, "gl": gl, "gr": gr, "off": off, "v": v, "k": k, "cam": cam,
            "boost": boost_strips(c), "obs": obs, "cones": cones}

def write_tables(T, path):
    """the track tables, written between the // <track> and // </track> markers of game.as"""
    c = T["c"]
    X, Z = world(c["x"], c["y"])
    psi = np.degrees(np.unwrap(c["h"])) + 90.0
    def arr(name, vals, fmt="{:.3f}", typ="f32"):
        s = ", ".join(fmt.format(v) for v in vals)
        return f"const {name}: StaticArray<{typ}> = [{s}];\n"
    out = ["// <track> generated by models/env/track.py (write_tables): do not edit by hand\n",
           f"const TN: i32 = {c['n']};          // centreline samples\n",
           f"const TLEN: f64 = {LENGTH:.4f};   // metres a lap\n",
           f"const TDS: f64 = {c['ds']:.6f};    // metres between samples\n",
           f"const HALF: f64 = {HALF};\n",
           arr("T_X", X), arr("T_Z", Z), arr("T_PSI", psi, "{:.2f}"),
           arr("T_WL", T["wl"], "{:.2f}"), arr("T_WR", T["wr"], "{:.2f}"),
           arr("T_GL", T["gl"], "{:d}", "u8"), arr("T_GR", T["gr"], "{:d}", "u8"),
           arr("T_LINE", T["off"], "{:.2f}"), arr("T_V", T["v"], "{:.2f}"),
           arr("T_CAM", T["cam"], "{:.2f}"),
           "const T_BOOST: StaticArray<i32> = [" + ", ".join(str(b) for b in T["boost"]) + "];\n",
           f"const NOBS: i32 = {len(T['obs'])};\n",
           arr("O_X", [o[1] for o in T["obs"]]), arr("O_Z", [-o[2] for o in T["obs"]]),
           arr("O_R", [o[3] for o in T["obs"]], "{:.2f}"),
           f"const NZONE: i32 = {len(T['zones'])};       // drift zones: the hairpins and the two corners\n",
           arr("Z_A", [z[0] for z in T["zones"]], "{:.2f}"), arr("Z_B", [z[1] for z in T["zones"]], "{:.2f}"),
           arr("Z_D", [z[2] for z in T["zones"]], "{:.0f}"),
           f"const NCONE: i32 = {len(T['cones'])};\n",
           arr("C_X", [p[0] for p in T["cones"]]), arr("C_Z", [-p[1] for p in T["cones"]]),
           "// </track>\n"]
    src = open(path).read()
    a = src.index("// <track>")
    b = src.index("// </track>") + len("// </track>\n")
    open(path, "w").write(src[:a] + "".join(out) + src[b:])

if __name__ == "__main__":
    T = build()
    c = T["c"]
    print("length", LENGTH, "samples", c["n"])
    print("speed min %.1f max %.1f, lap at line speeds %.1f s" % (T["v"].min(), T["v"].max(), (c["ds"] / T["v"]).sum()))
    print("walls L min %.1f R min %.1f" % (T["wl"].min(), T["wr"].min()))
    print("boost at", T["boost"])
