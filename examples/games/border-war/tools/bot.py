#!/usr/bin/env python3
"""A closed-loop test player for Border War: drives `rive scene --commands` with pointer presses only
(down@ / up@ taps, drag@ boxes; never a bare move@), reading the state the game prints while its
DEBUG dump is in (scene/game.as). Plays the humans: economy, cottages, the yard, a tower, an army,
defends, then attacks the Warcamp. --idle: never touches anything (checks that an idle player loses).
Usage: python3 tools/bot.py [--idle] [--minutes 10] [--shots DIR] [--touch]"""
import argparse, math, os, subprocess, sys

ap = argparse.ArgumentParser()
ap.add_argument("--idle", action="store_true")
ap.add_argument("--minutes", type=float, default=10)
ap.add_argument("--shots", default="")
ap.add_argument("--touch", action="store_true", help="send --touch events instead of --pointer")
ap.add_argument("--attack-at", type=int, default=7)
ap.add_argument("--every", type=int, default=20)
ap.add_argument("--verbose", action="store_true")
ap.add_argument("--patient", action="store_true", help="attack only with a full army")
ap.add_argument("--pace", type=float, default=0, help="seconds between actions (a human's pace)")
a = ap.parse_args()
HERE = os.path.dirname(os.path.abspath(__file__))
p = subprocess.Popen(["rive", os.path.join(HERE, "..", "scene"), "--commands"], stdin=subprocess.PIPE,
                     stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
state = None


def cmd(c):
    global state
    p.stdin.write(c + "\n")
    p.stdin.flush()
    verb = c.split()[0]
    while True:
        line = p.stdout.readline()
        if not line:
            sys.exit("rive ended")
        if "trapped" in line or " error " in line:
            print("GAME ERROR:", line.strip(), flush=True)
        if " ST " in line:
            state = line.split(" ST ", 1)[1].strip()
        if line.startswith("ok " + verb) or line.startswith("err " + verb):
            if line.startswith("err"):
                print(line.strip())
            return


def parse():
    parts = [x for x in state.split(";") if x]
    h = parts[0].split()
    g = dict(frame=int(h[0]), t=int(h[1]), gold=int(h[2]), wood=int(h[3]), used=int(h[4]), cap=int(h[5]), res=h[6],
             selB=int(h[7]), mode=int(h[8]))
    ents, res = [], {}
    for q in parts[1:]:
        f = q.split()
        if f[0] == "E":
            ents.append(dict(id=int(f[1]), kind=int(f[2]), team=int(f[3]), x=int(f[4]), y=int(f[5]), hp=int(f[6]),
                             st=int(f[7]), prog=int(f[8]), sel=f[9] == "1", q=int(f[10]), r=int(f[11])))
        elif f[0] == "R":
            res[int(f[1])] = (int(f[2]), int(f[3]), int(f[4]))
    return g, ents, res


def tap(x, y):
    if a.touch:
        cmd(f"touch down@{x},{y}")
        cmd(f"touch up@{x},{y}")
    else:
        cmd(f"pointer down@{x},{y}")
        cmd(f"pointer up@{x},{y}")


def button(i):
    tap((122 + i * 39 + 19) * 2, 372)


def world(x, z):
    return int(2 * (160 + x / 0.06)), int(2 * (100 + z * 0.61566 / 0.06))


log = []
FARM_SPOTS = [(-8.2, 6.1), (-5.6, 6.3), (-8.4, 3.4), (-3.0, 4.9), (-6.6, 1.9), (-2.4, 3.2)]
farm_i = [0]
nxt = dict(defend=0, attack=0, train=0, build=0, eco=0)
attacking = False
frames_total = int(a.minutes * 3600)
built = set()
shot_n = 0
import time as _time
_t0 = _time.time()
while True:
    cmd("advance 20")
    if state is None:
        continue
    g, ents, res = parse()
    mine = [e for e in ents if e["team"] == 0]
    foe = [e for e in ents if e["team"] == 1]
    if g["frame"] % (a.every * 60) < 20:
        mil = len([e for e in mine if e["kind"] >= 5])
        print(f"[{_time.time()-_t0:5.1f}s] t={g['t']:4d} gold={g['gold']:4d} wood={g['wood']:4d} sup={g['used']}/{g['cap']} "
              f"mine={len(mine)} mil={mil} foe={len(foe)} foeMil={len([e for e in foe if e['kind'] >= 5])} "
              f"warcamp={[e['hp'] for e in foe if e['kind'] == 0]} manor={[e['hp'] for e in mine if e['kind'] == 0]}",
              flush=True)
        if a.shots:
            cmd(f"screenshot {os.path.abspath(a.shots)}/bot_{g['t']:04d}.png")
    if g["res"] != "P":
        print("RESULT", g["res"], "at", g["t"], "s")
        if a.shots:
            cmd("advance 60")
            cmd(f"screenshot {os.path.abspath(a.shots)}/bot_result.png")
        break
    if g["frame"] > frames_total:
        print("TIMEOUT")
        break
    if a.idle:
        continue
    if a.pace and g["t"] < nxt.get("act", 0):
        continue
    nxt["act"] = g["t"] + a.pace
    if g["mode"] != 0 and t >= nxt["build"]:
        tap(160, 390)          # a failed placement: cancel on the panel
        continue
    t = g["t"]
    manor = next((e for e in mine if e["kind"] == 0), None)
    yard = next((e for e in mine if e["kind"] == 1), None)
    towers = [e for e in mine if e["kind"] == 2]
    farms = [e for e in mine if e["kind"] == 3]
    workers = [e for e in mine if e["kind"] == 4]
    army = [e for e in mine if e["kind"] >= 5]
    queued = sum(e["q"] for e in mine if e["kind"] <= 1)
    # defend: enemy soldiers near home
    threats = [e for e in foe if e["kind"] >= 4 and manor and math.hypot(e["x"] - manor["x"], e["y"] - manor["y"]) < 230]
    if threats and army and t >= nxt["defend"] and not attacking:
        th = threats[0]
        button(4)              # ARMY
        button(0)              # ATTACK
        tap(th["x"], th["y"] + 4)
        nxt["defend"] = t + 4
        continue
    # attack
    foe_mil = len([e for e in foe if e["kind"] >= 5])
    go = len(army) >= a.attack_at or (not a.patient and len(army) >= 5 and foe_mil <= len(army) - 3)
    if (go or (attacking and len(army) >= 3)) and t >= nxt["attack"] and not threats:
        attacking = True
        wc = next((e for e in foe if e["kind"] == 0), None)
        tx, ty = world(5.4, -3.4) if wc else (0, 0)
        button(4)
        g2 = parse()[0]
        button(0)
        g3 = parse()[0]
        tap(tx, ty)
        cmd("advance 2")
        st = [e["st"] for e in parse()[1] if e["team"] == 0 and e["kind"] >= 5]
        if a.verbose:
            print("ATTACK t", t, "mode after ARMY", g2["mode"], "after ATTACK", g3["mode"], "states", st)
        nxt["attack"] = t + 12
        continue
    if attacking and len(army) <= 2:
        attacking = False      # regroup at home
    # wood: two cutters
    cutters = [w for w in workers if 0 <= w["r"] < 6]
    if len(workers) >= 4 and len(cutters) < 2 and t >= nxt["eco"]:
        w = next((w for w in workers if w["r"] >= 6), None)
        grove = next((r for r in (0, 1, 2) if res[r][2] > 0), None)
        if w and grove is not None:
            tap(w["x"], w["y"] - 6)
            tap(res[grove][0], res[grove][1] - 8)
            nxt["eco"] = t + 3
            continue
    if not manor:
        continue
    # supply
    if g["used"] + queued >= g["cap"] - 1 and len(farms) < 2 and g["gold"] >= 50 and g["wood"] >= 40 and t >= nxt["build"] \
            and not any(f["prog"] < 100 for f in farms):
        tap(manor["x"], manor["y"] - 10)
        button(3)
        spot = FARM_SPOTS[farm_i[0] % len(FARM_SPOTS)]
        tap(*world(*spot))
        cmd("advance 2")
        if parse()[0]["mode"] != 0:      # did not fit: cancel, try the next spot next time
            tap(160, 390)
            farm_i[0] += 1
        nxt["build"] = t + 4
        continue
    # workers to five
    if len(workers) + (manor["q"]) < 5 and manor["q"] == 0 and g["gold"] >= 50 and g["used"] + queued < g["cap"]:
        tap(manor["x"], manor["y"] - 10)
        button(0)
        continue
    # the yard
    if not yard and len(workers) >= 4 and g["gold"] >= 120 and g["wood"] >= 80 and t >= nxt["build"]:
        tap(manor["x"], manor["y"] - 10)
        button(1)
        tap(*world(-4.3, 2.7))
        nxt["build"] = t + 4
        continue
    # a tower by the west ford, once there is an army
    if yard and yard["prog"] >= 100 and len(towers) < 1 and len(army) >= 3 and g["gold"] >= 160 and g["wood"] >= 60 and t >= nxt["build"]:
        tap(manor["x"], manor["y"] - 10)
        button(2)
        tap(*world(-4.0, -0.6))
        nxt["build"] = t + 4
        continue
    # soldiers
    if yard and yard["prog"] >= 100 and yard["q"] < 2 and g["used"] + queued < g["cap"] and t >= nxt["train"]:
        want_archer = len([e for e in army if e["kind"] == 6]) * 2 < len([e for e in army if e["kind"] == 5]) and g["wood"] >= 25
        if g["gold"] >= (55 if want_archer else 70):
            tap(yard["x"], yard["y"] - 10)
            button(1 if want_archer else 0)
            nxt["train"] = t + 1
            continue
p.stdin.write("quit\n")
p.stdin.flush()
