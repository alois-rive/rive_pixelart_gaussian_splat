# A throwaway Python port of scene/game.as's putting physics and its demo player, used to tune the
# holes (pars, slopes, the windmill's rhythm, the jump) before any Rive run (the skill's games.md,
# "Physics first in Python"). Keep it in step with game.as by hand.
#   /usr/bin/python3 sim.py preview out.png      top-down map of every hole with a demo shot traced
#   /usr/bin/python3 sim.py rounds N             the demo player plays N rounds: strokes per hole
import math, random, sys
import course as C

DT = 1.0 / 240.0
G_SLOPE = 6.0
G_AIR = 8.0
MU0, MU1 = 0.9, 0.22
STATIC = 0.8
E_WALL, E_POST, E_BLOCK = 0.6, 0.85, 0.75
V_CAPTURE, V_LIP = 1.15, 2.4
VMAX = 9.0
MILL_SPEED = 90.0 / 1.6   # degrees a second, stepped at 12 fps
SAIL_SCALE = 0.9


def power_speed(p):
    return 0.35 + (VMAX - 0.35) * p ** 1.3


def mill_angle(t):
    return math.floor(t * 12) / 12 * MILL_SPEED


class Ball:
    def __init__(s, x, z):
        s.x, s.z = x, z
        s.vx = s.vz = s.vy = 0.0
        s.air = False
        s.y = 0.0
        s.rest = 0.0
        s.slow = 0.0
        s.incup = False
        s.vys = 0.0      # the ground's vertical speed under the rolling ball (the last step's)


def solid(w, x, z):
    """Over felt (or the bridge) and not over a hazard."""
    b = w.get("bridge")
    if b and C.in_rect(b, x, z):
        return True
    for r in w["water"] + w["gap"]:
        if C.in_rect(r, x, z):
            return False
    for r in w["felt"]:
        if C.in_rect(r, x, z):
            return True
    return False


def hazard_kind(w, x, z):
    for r in w["water"]:
        if C.in_rect(r, x, z):
            return 1
    return 2   # a gap (or off the felt)


def block_pos(b, t):
    x, z, hx, hz, axis, amp, period, phase = b
    off = amp * math.sin(2 * math.pi * (t + phase) / period)
    vel = amp * 2 * math.pi / period * math.cos(2 * math.pi * (t + phase) / period)
    if axis == 1:
        return x, z + off, 0.0, vel
    return x + off, z, vel, 0.0


def step(w, b, t, ev):
    """One substep. Returns None while rolling, 'rest', 'holed', 'water' or 'gap'."""
    h0 = C.height(w, b.x, b.z)
    if not b.air:
        e = 0.02
        gx = (C.height(w, b.x + e, b.z) - C.height(w, b.x - e, b.z)) / (2 * e)
        gz = (C.height(w, b.x, b.z + e) - C.height(w, b.x, b.z - e)) / (2 * e)
        ax, az = -G_SLOPE * gx, -G_SLOPE * gz
        sp = math.hypot(b.vx, b.vz)
        if sp < 0.06 and math.hypot(ax, az) < STATIC:
            b.vx = b.vz = 0.0
            b.rest += DT
            if b.rest > 0.15:
                return "rest"
            return None
        b.rest = 0.0
        b.slow = b.slow + DT if sp < 0.06 else 0.0   # held against a wall by a slope
        if b.slow > 0.6:
            b.vx = b.vz = 0.0
            return "rest"
        f = (MU0 + MU1 * sp) * DT
        if sp > f:
            b.vx -= b.vx / sp * f
            b.vz -= b.vz / sp * f
        else:
            b.vx = b.vz = 0.0
        b.vx += ax * DT
        b.vz += az * DT
        vy_prev = b.vys
        nx, nz = b.x + b.vx * DT, b.z + b.vz * DT
        if not solid(w, nx, nz):
            b.x, b.z = nx, nz
            b.air = True
            b.vy = vy_prev
            b.y = C.FELT + h0 + C.R
        else:
            h1 = C.height(w, nx, nz)
            if h1 - h0 < vy_prev * DT - 0.5 * G_AIR * DT * DT - 0.003:
                b.air = True     # the ground falls away faster than the ball: it flies
                b.vy = vy_prev
                b.y = C.FELT + h0 + C.R + vy_prev * DT
            else:
                b.y = C.FELT + h1 + C.R
                b.vys = (h1 - h0) / DT
            b.x, b.z = nx, nz
    else:
        b.vy -= G_AIR * DT
        b.x += b.vx * DT
        b.z += b.vz * DT
        b.y += b.vy * DT
        if solid(w, b.x, b.z):
            g = C.FELT + C.height(w, b.x, b.z) + C.R
            if b.y <= g:
                b.y = g
                if b.vy < -1.4:
                    ev.append(("land", -b.vy))
                    b.vy = -b.vy * 0.3
                    b.vx *= 0.75     # a hard landing eats speed
                    b.vz *= 0.75
                else:
                    b.air = False
                    b.vy = 0.0
                    b.vys = 0.0
        elif b.y < C.FELT + C.R - 0.35:
            return "water" if hazard_kind(w, b.x, b.z) == 1 else "gap"
    collide(w, b, t, ev)
    # the cup
    if not b.air:
        dx, dz = w["cup"][0] - b.x, w["cup"][1] - b.z
        d = math.hypot(dx, dz)
        sp = math.hypot(b.vx, b.vz)
        if d < C.CUP_R:
            if sp < V_CAPTURE and not b.incup:
                return "holed"
            if not b.incup:
                b.incup = True     # one verdict per pass over the cup
                if sp < V_LIP:
                    # rims out: turned away from the centre, much slower
                    cross = b.vx * dz - b.vz * dx
                    off = abs(cross) / sp
                    ang = math.radians(55) * (1 - off / C.CUP_R) * (-1 if cross > 0 else 1)
                    c, s_ = math.cos(ang), math.sin(ang)
                    b.vx, b.vz = (b.vx * c - b.vz * s_) * 0.55, (b.vx * s_ + b.vz * c) * 0.55
                    ev.append(("lip", sp))
                else:
                    b.vx *= 0.9
                    b.vz *= 0.9
                    ev.append(("skim", sp))
        elif d > C.CUP_R + 0.05:
            b.incup = False
        if not solid(w, b.x, b.z):
            b.air = True
            b.vy = 0.0
    return None


def push(b, nx, nz, depth, e, vxo=0.0, vzo=0.0):
    b.x += nx * depth
    b.z += nz * depth
    rvx, rvz = b.vx - vxo, b.vz - vzo
    vn = rvx * nx + rvz * nz
    if vn < 0:
        rvx -= (1 + e) * vn * nx
        rvz -= (1 + e) * vn * nz
        b.vx, b.vz = rvx + vxo, rvz + vzo
        return -vn
    return 0.0


def collide(w, b, t, ev):
    for (x0, z0, x1, z1) in w["segs"]:
        ex, ez = x1 - x0, z1 - z0
        L2 = ex * ex + ez * ez
        u = max(0.0, min(1.0, ((b.x - x0) * ex + (b.z - z0) * ez) / L2))
        cx, cz = x0 + ex * u, z0 + ez * u
        dx, dz = b.x - cx, b.z - cz
        d = math.hypot(dx, dz)
        lim = C.R + C.WALL_HALF
        if d < lim and d > 1e-6:
            k = push(b, dx / d, dz / d, lim - d, E_WALL)
            if k > 0.3:
                ev.append(("wall", k))
    for (px, pz, pr) in w["posts"]:
        dx, dz = b.x - px, b.z - pz
        d = math.hypot(dx, dz)
        lim = C.R + pr
        if d < lim and d > 1e-6:
            k = push(b, dx / d, dz / d, lim - d, E_POST)
            if k > 0.3:
                ev.append(("post", k))
    for blk in w["blocks"]:
        bx, bz, bvx, bvz = block_pos(blk, t)
        hx, hz = blk[2], blk[3]
        cx = max(bx - hx, min(bx + hx, b.x))
        cz = max(bz - hz, min(bz + hz, b.z))
        dx, dz = b.x - cx, b.z - cz
        d = math.hypot(dx, dz)
        if d < C.R:
            if d > 1e-6:
                nx, nz, depth = dx / d, dz / d, C.R - d
            else:   # the centre inside: out along the shallow axis
                ox, oz = hx - abs(b.x - bx), hz - abs(b.z - bz)
                if ox < oz:
                    nx, nz, depth = (1.0 if b.x > bx else -1.0), 0.0, ox + C.R
                else:
                    nx, nz, depth = 0.0, (1.0 if b.z > bz else -1.0), oz + C.R
            k = push(b, nx, nz, depth, E_BLOCK, bvx, bvz)
            if k > 0.3:
                ev.append(("block", k))
    if w["index"] == 0:
        mill(w, b, t, ev)


def mill(w, b, t, ev):
    mx, mz = C.MILL[0] + w["cx"], C.MILL[1] + w["cz"]
    S = C.MILL_S * SAIL_SCALE
    zb = mz + 1.16 * C.MILL_S
    hy = C.FELT + C.MILL_Y + 1.62 * C.MILL_S
    if abs(b.z - zb) > C.R + 0.05:
        return
    th = mill_angle(t)
    for k in range(4):
        phi = math.radians(th + 45 + 90 * k)
        dx, dy = math.cos(phi), math.sin(phi)
        nx, ny = -dy, dx
        ax = mx + (dx * 0.45 + nx * 0.2) * S
        ay = hy + (dy * 0.45 + ny * 0.2) * S
        bx = mx + (dx * 1.66 + nx * 0.2) * S
        by = hy + (dy * 1.66 + ny * 0.2) * S
        ex, ey = bx - ax, by - ay
        u = max(0.0, min(1.0, ((b.x - ax) * ex + (b.y - ay) * ey) / (ex * ex + ey * ey)))
        d = math.hypot(b.x - (ax + ex * u), b.y - (ay + ey * u))
        if d < C.R + 0.21 * S:
            side = 1.0 if b.z > zb else -1.0
            b.z = zb + side * (C.R + 0.06)
            if b.vz * side < 0:
                ev.append(("sail", abs(b.vz)))
                b.vz = -b.vz * 0.45
            return


def shoot(w, x, z, ang, p, t0, tmax=14.0, trace=None):
    b = Ball(x, z)
    sp = power_speed(p)
    b.vx, b.vz = math.cos(ang) * sp, math.sin(ang) * sp
    t = t0
    ev = []
    n = 0
    while t - t0 < tmax:
        r = step(w, b, t, ev)
        t += DT
        n += 1
        if trace is not None and n % 8 == 0:
            trace.append((b.x, b.z))
        if r:
            return r, b, t - t0, ev
    return "rest", b, t - t0, ev


# ------------------------------------------------------------------ the demo player's map
GRID = 0.2


def field(w):
    """Path distance (metres) from the cup over the walkable felt, 8-neighbour Dijkstra."""
    xs = [r[0] for r in w["felt"]] + [r[2] for r in w["felt"]]
    zs = [r[1] for r in w["felt"]] + [r[3] for r in w["felt"]]
    x0, z0 = min(xs), min(zs)
    nx, nz = int((max(xs) - x0) / GRID) + 1, int((max(zs) - z0) / GRID) + 1
    INF = 1e9
    walk = [[False] * nx for _ in range(nz)]
    for j in range(nz):
        for i in range(nx):
            px, pz = x0 + (i + 0.5) * GRID, z0 + (j + 0.5) * GRID
            ok = solid(w, px, pz)
            if ok:
                for (a, c, bb, d) in w["segs"]:
                    ex, ez = bb - a, d - c
                    u = max(0.0, min(1.0, ((px - a) * ex + (pz - c) * ez) / (ex * ex + ez * ez)))
                    if math.hypot(px - a - ex * u, pz - c - ez * u) < C.WALL_HALF + 0.12:
                        ok = False
                        break
            if ok:
                for (qx, qz, qr) in w["posts"]:
                    if math.hypot(px - qx, pz - qz) < qr + 0.12:
                        ok = False
            walk[j][i] = ok
    dist = [[INF] * nx for _ in range(nz)]
    import heapq
    ci = int((w["cup"][0] - x0) / GRID)
    cj = int((w["cup"][1] - z0) / GRID)
    dist[cj][ci] = 0.0
    q = [(0.0, ci, cj)]
    while q:
        d, i, j = heapq.heappop(q)
        if d > dist[j][i]:
            continue
        for di, dj, c in ((1, 0, 1), (-1, 0, 1), (0, 1, 1), (0, -1, 1), (1, 1, 1.414), (1, -1, 1.414), (-1, 1, 1.414), (-1, -1, 1.414)):
            a, bb = i + di, j + dj
            if 0 <= a < nx and 0 <= bb < nz and walk[bb][a]:
                nd = d + c * GRID
                if nd < dist[bb][a]:
                    dist[bb][a] = nd
                    heapq.heappush(q, (nd, a, bb))
    return dict(x0=x0, z0=z0, nx=nx, nz=nz, d=dist)


def fdist(fd, x, z):
    i = int((x - fd["x0"]) / GRID)
    j = int((z - fd["z0"]) / GRID)
    if 0 <= i < fd["nx"] and 0 <= j < fd["nz"]:
        v = fd["d"][j][i]
        if v < 1e8:
            return v
    return 30.0


def more_strokes(d):
    return 1.0 + min(2.5, 0.1 * d + 0.03 * d * d)


def cost(fd, res, b, lie):
    if res == "holed":
        return 1.0
    if res in ("water", "gap"):
        return 2.0 + more_strokes(fdist(fd, *lie))
    return 1.0 + more_strokes(fdist(fd, b.x, b.z))


AIM_SD = (0.05, 0.08)    # the demo's hand: angle sd (radians) = AIM_SD[0] + AIM_SD[1] * power
POW_SD = 0.1              # power sd, a fraction of the power


def plan(w, fd, x, z, t0):
    """Coarse search, then the six best judged by their mean cost over four nudged copies (a
    person picks a shot that still works when it is a little off)."""
    scored = []
    for k in range(36):
        for p in (0.12, 0.2, 0.28, 0.36, 0.45, 0.55, 0.68, 0.82):
            a = k * math.pi * 2 / 36
            res, b, _, _ = shoot(w, x, z, a, p, t0, 8.0)
            scored.append((cost(fd, res, b, (x, z)), a, p))
    scored.sort()
    best = None
    for (c0, a0, p0) in scored[:6]:
        sa = AIM_SD[0] + AIM_SD[1] * p0
        tot = c0
        for (da, dp) in ((sa, 0.0), (-sa, 0.0), (0.0, POW_SD), (0.0, -POW_SD)):
            res, b, _, _ = shoot(w, x, z, a0 + da, p0 * (1 + dp), t0, 8.0)
            tot += cost(fd, res, b, (x, z))
        if best is None or tot / 5 < best[0]:
            best = (tot / 5, a0, p0)
    return best


def play_hole(w, rng, trace=None):
    for line in []:
        pass
    fd = field(w)
    x, z = w["tee"]
    t = 0.0
    strokes = 0
    log = []
    while strokes < 6:
        c, a, p = plan(w, fd, x, z, t + 1.0)
        a += rng.gauss(0, AIM_SD[0] + AIM_SD[1] * p)
        p = max(0.04, min(1.0, p * (1 + rng.gauss(0, POW_SD))))
        t += 1.0
        tr = [] if trace is not None else None
        res, b, dt, ev = shoot(w, x, z, a, p, t, 14.0, tr)
        if trace is not None:
            trace.append(tr)
        t += dt + 0.5
        strokes += 1
        log.append((res, round(p, 2), round(c, 2)))
        if res == "holed":
            break
        if res in ("water", "gap"):
            strokes += 1
            continue
        x, z = b.x, b.z
    return min(strokes, 6), log


def main():
    W = C.world_holes()
    for w in W:
        w["segs"] = C.segments(w)
    if sys.argv[1] == "rounds":
        n = int(sys.argv[2])
        holes = [int(a) - 1 for a in sys.argv[3:]] or range(9)
        rng = random.Random(7)
        tot = {i: [] for i in holes}
        for r in range(n):
            for i in holes:
                s, log = play_hole(W[i], rng)
                tot[i].append(s)
                print(f"round {r} hole {i + 1} par {W[i]['par']}: {s}  {log}", flush=True)
        for i in holes:
            print(f"hole {i + 1} par {W[i]['par']}: mean {sum(tot[i]) / len(tot[i]):.2f}  {tot[i]}")
    elif sys.argv[1] == "preview":
        from PIL import Image, ImageDraw
        S = 24
        img = Image.new("RGB", (int(38 * S), int(27 * S)), (40, 40, 60))
        dr = ImageDraw.Draw(img)
        def P(x, z):
            return ((x + 19) * S, (z + 13.5) * S)
        rng = random.Random(3)
        for w in W:
            for j in range(int(-3.8 / 0.1), int(3.8 / 0.1)):
                for i in range(int(-5.5 / 0.1), int(5.5 / 0.1)):
                    x, z = w["cx"] + i * 0.1, w["cz"] + j * 0.1
                    if any(C.in_rect(r, x, z) for r in w["felt"]):
                        h = C.height(w, x, z)
                        col = (40, int(120 + 200 * h), 80) if solid(w, x, z) else ((60, 90, 220) if hazard_kind(w, x, z) == 1 else (20, 20, 20))
                        dr.rectangle([P(x, z), P(x + 0.1, z + 0.1)], fill=col)
            for (a, b_, c, d) in w["segs"]:
                dr.line([P(a, b_), P(c, d)], fill=(240, 150, 60), width=3)
            for (px, pz, pr) in w["posts"]:
                dr.ellipse([P(px - pr, pz - pr), P(px + pr, pz + pr)], fill=(255, 110, 120))
            for blk in w["blocks"]:
                bx, bz, _, _ = block_pos(blk, 0)
                dr.rectangle([P(bx - blk[2], bz - blk[3]), P(bx + blk[2], bz + blk[3])], fill=(160, 60, 90))
            cx, cz = w["cup"]
            dr.ellipse([P(cx - C.CUP_R, cz - C.CUP_R), P(cx + C.CUP_R, cz + C.CUP_R)], fill=(0, 0, 0))
            tx, tz = w["tee"]
            dr.rectangle([P(tx - 0.3, tz - 0.3), P(tx + 0.3, tz + 0.3)], outline=(255, 170, 120), width=2)
            dr.text(P(w["cx"] - 5.3, w["cz"] - 3.7), f"{w['index'] + 1} {w['name']} par {w['par']}", fill=(255, 255, 255))
            if len(sys.argv) > 3:
                tr = []
                s, log = play_hole(w, rng, tr)
                print(w["index"] + 1, s, log, flush=True)
                for k, line in enumerate(tr):
                    if len(line) > 1:
                        dr.line([P(*q) for q in line], fill=[(255, 255, 255), (255, 235, 50), (120, 220, 255), (255, 120, 255), (255, 255, 255), (255, 235, 50)][k], width=2)
        img.save(sys.argv[2])


if __name__ == "__main__":
    main()
