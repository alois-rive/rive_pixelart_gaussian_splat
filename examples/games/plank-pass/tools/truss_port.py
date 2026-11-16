#!/usr/bin/env python3
"""A Python port of scene/game.as's truss solver and cart (the same constants and order of operations), used to
tune the solver and to verify, before any Rive run, that every gap is solvable within its budget with a known
design and that the demo's flawed tries (the design without its "key" beams) fail.

    /usr/bin/python3 tools/truss_port.py        # prints each design: held / crash, cost, peak stress

The designs below are the ones in game.as (D_DATA), with their key beams (KEY_IDX). The game reached the same
peak stresses within 0.03 when the closed-loop test player built them by touch."""
import math

G = 9.8
SUB = 16            # substeps per 1/60 s frame
DT = 1.0 / 60.0
MAXLEN = 3.2
# kind: 0 plank (road, wood), 1 girder (steel)
MASS = [0.25, 0.5]
COMP = [1.0 / 9000.0, 1.0 / 40000.0]   # compliance (1/stiffness)
STRENGTH = [170.0, 480.0]
COST = [20, 55]            # per metre (rounded per beam)
DAMP_B = [0.02, 0.02]      # constraint damping (s)
CART_M = 8.0
WHEEL = 0.62
JOINT_M = 0.15
DAMPV = 1.5

GAPS = [
    # name, xL, yL, xR, yR, floor, water, anchors (extra, relative)
    dict(name="MILL CREEK", xL=-3, yL=0, xR=3, yR=0, floor=-3.0, water=True, anchors=[(-3, 0), (3, 0), (-3, -2), (3, -2)], rock=None),
    dict(name="FERN GULLY", xL=-4, yL=0, xR=4, yR=0, floor=-4.5, water=False, anchors=[(-4, 0), (4, 0), (-4, -2), (4, -2)], rock=None),
    dict(name="STEP GORGE", xL=-4, yL=0, xR=4, yR=1, floor=-4.5, water=False, anchors=[(-4, 0), (4, 1), (-4, -2), (4, -1)], rock=None),
    dict(name="TWIN ROCK", xL=-6, yL=0, xR=6, yR=0, floor=-3.5, water=True, anchors=[(-6, 0), (6, 0), (-6, -2), (6, -2), (-1, -2), (1, -2)], rock=(-1, 1, -2)),
    dict(name="LONG WASH", xL=-6, yL=0, xR=6, yR=0, floor=-3.5, water=True, anchors=[(-6, 0), (6, 0), (-6, -3), (6, -3)], rock=None),
]


def beam_cost(k, ax, ay, bx, by):
    return int(round(COST[k] * math.hypot(bx - ax, by - ay) / 5.0)) * 5


class Sim:
    def __init__(self, gap, beams):
        self.gap = gap
        self.jx, self.jy, self.px, self.py, self.inv, self.anchor = [], [], [], [], [], []
        idx = {}
        for (x, y) in gap["anchors"]:
            idx[(x, y)] = len(self.jx)
            self.add_joint(x, y, True)
        self.ba, self.bb, self.bl, self.bk, self.bbroken, self.bf = [], [], [], [], [], []
        mass = {}
        for (k, a, b) in beams:
            for p in (a, b):
                if p not in idx:
                    idx[p] = len(self.jx)
                    self.add_joint(p[0], p[1], False)
            ia, ib = idx[a], idx[b]
            L = math.hypot(b[0] - a[0], b[1] - a[1])
            assert L <= MAXLEN + 1e-6, (a, b, L)
            self.ba.append(ia); self.bb.append(ib); self.bl.append(L); self.bk.append(k)
            self.bbroken.append(False); self.bf.append(0.0)
            m = MASS[k] * L * 0.5
            mass[ia] = mass.get(ia, JOINT_M) + m
            mass[ib] = mass.get(ib, JOINT_M) + m
        for i in range(len(self.jx)):
            if not self.anchor[i]:
                self.inv[i] = 1.0 / mass.get(i, JOINT_M)
        self.cost = sum(beam_cost(k, a[0], a[1], b[0], b[1]) for (k, a, b) in beams)
        # cart: x of its middle, two wheels' y and vy
        self.cx = gap["xL"] - 2.5
        self.wy = [gap["yL"], gap["yL"]]
        self.wvy = [0.0, 0.0]
        self.speed = 2.5
        self.wb = [-1, -1]; self.we = [0, 0]; self.wo = [0, 0]; self.airT = 0.0
        self.aL = idx[(gap["xL"], gap["yL"])]; self.aR = idx[(gap["xR"], gap["yR"])]
        self.state = "run"
        self.maxstress = 0.0
        self.t = 0.0
        self.fx = [0.0] * len(self.jx)
        self.fy = [0.0] * len(self.jx)

    def add_joint(self, x, y, anchor):
        self.jx.append(float(x)); self.jy.append(float(y)); self.px.append(float(x)); self.py.append(float(y))
        self.inv.append(0.0); self.anchor.append(anchor)

    def next_plank(self, J, cur, slope):
        best, bd = -1, 1.05   # at most ~60 degrees of turn
        for i in range(len(self.ba)):
            if i == cur or self.bbroken[i] or self.bk[i] != 0:
                continue
            if self.ba[i] == J:
                o = self.bb[i]
            elif self.bb[i] == J:
                o = self.ba[i]
            else:
                continue
            dx = self.jx[o] - self.jx[J]
            if dx < 0.05:
                continue
            d = abs(math.atan2(self.jy[o] - self.jy[J], dx) - math.atan(slope))
            if d < bd:
                bd, best = d, i
        if best >= 0:
            self.wb_e = J
            self.wb_o = self.bb[best] if self.ba[best] == J else self.ba[best]
        return best

    def track(self, w, x):
        """the wheel's road: ground, a plank (followed to its end, then the smoothest plank onward), or the air"""
        g = self.gap
        for _ in range(4):
            b = self.wb[w]
            if b == -1:   # left bank
                if x <= g["xL"]:
                    return g["yL"], True
                nb = self.next_plank(self.aL, -1, 0.0)
                if nb < 0:
                    self.wb[w] = -2
                    return 0, False
                self.wb[w] = nb; self.we[w] = self.wb_e; self.wo[w] = self.wb_o
                continue
            if b == -3:
                return g["yR"], True
            if b == -2:
                return 0, False
            if self.bbroken[b]:
                self.wb[w] = -2
                return 0, False
            e, o = self.we[w], self.wo[w]
            x0, x1 = self.jx[e], self.jx[o]
            if x1 - x0 < 0.02:
                self.wb[w] = -2
                return 0, False
            t = (x - x0) / (x1 - x0)
            if t <= 1.0:
                t = max(t, 0.0)
                F = CART_M * 0.5 * G
                self.fy[e] -= F * (1 - t)
                self.fy[o] -= F * t
                return self.jy[e] + (self.jy[o] - self.jy[e]) * t, True
            # off its end: onward
            if o == self.aR:
                self.wb[w] = -3
                continue
            slope = (self.jy[o] - self.jy[e]) / (x1 - x0)
            nb = self.next_plank(o, b, slope)
            if nb < 0:
                self.wb[w] = -2
                return 0, False
            self.wb[w] = nb; self.we[w] = self.wb_e; self.wo[w] = self.wb_o
        return 0, False

    def frame(self):
        g = self.gap
        h = DT / SUB
        # the cart: wheels fall, land on a surface; the load goes to the plank's joints
        self.fx = [0.0] * len(self.jx)
        self.fy = [0.0] * len(self.jx)
        if self.state == "run":
            self.cx += self.speed * DT
        elif self.state == "fall":
            self.cx += self.speed * 0.6 * DT
        air = 0
        for w in range(2):
            x = self.cx + (WHEEL if w == 0 else -WHEEL)
            if self.state != "run":
                self.wb[w] = -2
            y, ok = self.track(w, x)
            if ok:
                self.wy[w] = y
                self.wvy[w] = 0.0
            else:
                self.wvy[w] -= G * DT
                self.wy[w] += self.wvy[w] * DT
                air += 1
        if self.state == "run" and air > 0:
            self.airT += DT
            if self.airT > 0.2:
                self.state = "fall"
        else:
            self.airT = 0.0
        if min(self.wy) < g["floor"] + 0.3:
            self.state = "crash"
        if self.cx - WHEEL > g["xR"] + 1.0 and self.state == "run":
            self.state = "win"
        # the truss
        for s in range(SUB):
            for i in range(len(self.jx)):
                if self.inv[i] == 0:
                    continue
                vx = (self.jx[i] - self.px[i]) / h
                vy = (self.jy[i] - self.py[i]) / h
                d = math.exp(-DAMPV * h)
                vx *= d; vy *= d
                vy += (-G + self.fy[i] * self.inv[i]) * h
                self.px[i] = self.jx[i]; self.py[i] = self.jy[i]
                self.jx[i] += vx * h
                self.jy[i] += vy * h
            for b in range(len(self.ba)):
                if self.bbroken[b]:
                    continue
                a, c = self.ba[b], self.bb[b]
                wa, wc = self.inv[a], self.inv[c]
                if wa + wc == 0:
                    continue
                dx = self.jx[c] - self.jx[a]; dy = self.jy[c] - self.jy[a]
                L = math.sqrt(dx * dx + dy * dy)
                if L < 1e-9:
                    continue
                nx, ny = dx / L, dy / L
                C = L - self.bl[b]
                al = COMP[self.bk[b]]
                at = al / (h * h)
                gam = al * DAMP_B[self.bk[b]] / h
                rv = ((self.jx[c] - self.px[c]) - (self.jx[a] - self.px[a])) * nx + ((self.jy[c] - self.py[c]) - (self.jy[a] - self.py[a])) * ny
                dl = (-C - gam * rv) / ((1 + gam) * (wa + wc) + at)
                self.jx[a] -= wa * dl * nx; self.jy[a] -= wa * dl * ny
                self.jx[c] += wc * dl * nx; self.jy[c] += wc * dl * ny
                self.bf[b] = -dl / (h * h)   # tension > 0
            # ground: free joints cannot enter the banks or go below the floor
            for i in range(len(self.jx)):
                if self.inv[i] == 0:
                    continue
                if self.jy[i] < g["floor"]:
                    self.jy[i] = g["floor"]
                if self.jx[i] < g["xL"] and self.jy[i] < g["yL"]:
                    self.jx[i] = g["xL"]
                if self.jx[i] > g["xR"] and self.jy[i] < g["yR"]:
                    self.jx[i] = g["xR"]
        for b in range(len(self.ba)):
            if self.bbroken[b]:
                continue
            s = abs(self.bf[b]) / STRENGTH[self.bk[b]]
            self.maxstress = max(self.maxstress, s)
            if s > 1.0:
                self.bbroken[b] = True
        self.t += DT

    def run(self, maxt=12.0, verbose=False):
        while self.t < maxt and self.state in ("run", "fall"):
            self.frame()
        return self.state


def P(k, a, b):
    return (k, a, b)


W, S = 0, 1


def deck(xs, ys=None):
    ys = ys or [0] * len(xs)
    return [P(W, (xs[i], ys[i]), (xs[i + 1], ys[i + 1])) for i in range(len(xs) - 1)]


def pratt():
    b = deck([-6, -4, -2, 0, 2, 4, 6])
    b += [P(S, (-6, 0), (-4, 2)), P(S, (6, 0), (4, 2))]
    b += [P(S, (x, 2), (x + 2, 2)) for x in (-4, -2, 0, 2)]
    b += [P(W, (x, 2), (x, 0)) for x in (-4, -2, 0, 2, 4)]
    b += [P(W, (-4, 2), (-2, 0)), P(W, (-2, 2), (0, 0)), P(W, (2, 2), (0, 0)), P(W, (4, 2), (2, 0))]
    return b


BUDGET = [300, 500, 500, 650, 1700]
# (name, gap, beams, key beam indices)
DESIGNS = [
    ("G0 A", 0, deck([-3, -1, 1, 3]) + [P(W, (-3, -2), (-1, 0)), P(W, (3, -2), (1, 0))], [3]),
    ("G1 A", 1, deck([-4, -2, 0, 2, 4]) + [P(W, (-4, -2), (-2, 0)), P(W, (4, -2), (2, 0)), P(W, (-2, 0), (0, -1)), P(W, (0, -1), (2, 0)), P(W, (0, -1), (0, 0))], [6, 7, 8]),
    ("G1 C", 1, deck([-4, -2, 0, 2, 4]) + [P(W, (-4, -2), (-2, 0)), P(W, (4, -2), (2, 0)), P(W, (-2, 0), (0, 1)), P(W, (0, 1), (2, 0)), P(W, (0, 1), (0, 0))], [6, 7, 8]),
    ("G2 A", 2, deck([-4, -2, 0, 2, 4], [0, 0, 0, 1, 1]) + [P(W, (-4, -2), (-2, 0)), P(W, (4, -1), (2, 1)), P(W, (-2, 0), (0, -1)), P(W, (0, -1), (0, 0)), P(W, (0, -1), (2, 1))], [6, 7, 8]),
    ("G2 C", 2, deck([-4, -2, 0, 2, 4], [0, 0, 0, 1, 1]) + [P(W, (-4, -2), (-2, 0)), P(W, (4, -1), (2, 1)), P(W, (-2, 0), (0, 2)), P(W, (0, 2), (2, 1)), P(W, (0, 2), (0, 0))], [6, 7, 8]),
    ("G3 A", 3, deck([-6, -4, -2, 0, 2, 4, 6]) + [P(W, (-6, -2), (-4, 0)), P(W, (-1, -2), (-2, 0)), P(W, (-1, -2), (0, 0)), P(W, (1, -2), (2, 0)), P(W, (6, -2), (4, 0))], [7, 9]),
    ("G3 B", 3, deck([-6, -4, -2, 0, 2, 4, 6]) + [P(W, (-6, -2), (-4, 0)), P(W, (-1, -2), (-2, 0)), P(W, (-1, -2), (0, 0)), P(W, (1, -2), (2, 0)), P(W, (1, -2), (0, 0)), P(W, (6, -2), (4, 0))], [7, 9, 10]),
    ("G4 Pratt", 4, pratt(), [18]),
]

if __name__ == "__main__":
    for name, g, beams, keys in DESIGNS:
        s = Sim(GAPS[g], beams)
        r = s.run()
        f = Sim(GAPS[g], [b for i, b in enumerate(beams) if i not in keys])
        rf = f.run()
        print(f"{name:9s} {r:5s} cost {s.cost:4d} of {BUDGET[g]:4d} ({100 * s.cost / BUDGET[g]:3.0f} %)  peak stress {s.maxstress:.2f}"
              f"   flawed: {rf} (peak {f.maxstress:.2f})")
