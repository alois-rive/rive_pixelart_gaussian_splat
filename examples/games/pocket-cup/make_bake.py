#!/usr/bin/env python3
"""Writes scene.bake.json: the village pitch, the two teams (the gated footballer as a body and two
legs, each its own game bone, in four kits), the ball, the marker ring and the supporters."""
import json, os

here = os.path.dirname(os.path.abspath(__file__))
FITX = 0.96
LEGX = 0.117 * FITX
HIP = 0.60
KITS = {   # shirt, shorts, socks, collar ramps
    "home":   ("coral", "chalk", "coral", "chalk"),
    "homeGK": ("gold", "navy", "gold", "chalk"),
    "away":   ("sky", "navy", "sky", "chalk"),
    "awayGK": ("violet", "chalk", "violet", "chalk"),
}
# the six players: bone name, kit, rest spot (x, z), skin step, hair step, captain
PLAYERS = [
    ("p0", "homeGK", (-10.1, 0.0), 0, -1, False),
    ("p1", "home", (-3.0, 1.8), 0, 0, True),
    ("p2", "home", (-3.5, -2.2), -1, -1, False),
    ("p3", "awayGK", (10.1, 0.0), 0, 2, False),
    ("p4", "away", (3.0, -1.8), 0, 2, True),
    ("p5", "away", (3.5, 2.2), -1, 0, False),
]
# the sheet paints the shirt and socks coral (#ec614a), the shorts cream (#cce2e1), the armband gold
# (#ffda70): mapped onto another kit's ramp they snap to that ramp's nearest step, and "step" brings
# each to the step the kit wants (e.g. the gold shirt snaps to #a36d3e: +1 makes it #f4b03c)
STEP = {("Shirt", "gold"): 1, ("Sock", "gold"): 1, ("Shorts", "navy"): -1,
        ("Band", "coral"): -1, ("Band", "sky"): -1, ("Band", "violet"): -1, ("Band", "pink"): -1,
        ("Band", "teal"): -1}
def mat(m, ramp, **kw):
    d = {"ramp": ramp}
    st = STEP.get((m, ramp), 0) + kw.pop("step", 0)
    if st:
        d["step"] = st
    d.update(kw)
    return d

objs = [
    {"model": "models/env/ground.glb",
     "materials": {"Pitch": {"spacing": 0.1}, "Verge": {"ramp": "verge", "spacing": 0.16}}},
    {"model": "models/env/fence.glb",
     "materials": {"Post": {"ramp": "wood", "spacing": 0.06}, "Rail": {"ramp": "wood", "spacing": 0.08},
                   "Pennant": {"ramp": "gold", "spacing": 0.05}}},
]
for x, yaw in ((-11.0, 90), (11.0, -90)):
    objs.append({"model": "models/env/goal.glb", "position": [x, 0, 0], "yaw": yaw,
                 "materials": {"Frame": {"ramp": "chalk", "spacing": 0.045},
                               "NetBack": {"ramp": "chalk", "flags": ["double"], "spacing": 0.035},
                               "NetSide": {"ramp": "chalk", "flags": ["double"], "spacing": 0.035},
                               "NetTop": {"ramp": "chalk", "flags": ["double"], "spacing": 0.035}}})
for x, z, yaw, s in ((-10.5, -11.0, 0, 1.0), (-4.2, -11.6, 70, 1.15), (2.6, -11.2, 140, 0.95),
                     (8.8, -11.4, 210, 1.1), (13.8, -9.4, 30, 0.9), (-13.9, -9.0, 100, 0.85)):
    objs.append({"model": "models/env/tree.glb", "position": [x, 0, z], "yaw": yaw, "scale": s,
                 "materials": {"Bark": {"ramp": "wood", "spacing": 0.08}, "Crown": {"ramp": "leaf", "spacing": 0.12}}})
for name, kit, (x, z), skin, hair, capt in PLAYERS:
    shirt, shorts, socks, collar = KITS[kit]
    objs.append({"model": "models/player/player_body.glb", "bone": name, "position": [x, 0, z],
                 "materials": {"Shirt": mat("Shirt", shirt), "Trim": mat("Trim", collar),
                               "Shorts": mat("Shorts", shorts),
                               "Skin": mat("Skin", "skin", step=skin), "Hair": mat("Hair", "wood", step=hair),
                               "Eye": {"ramp": "navy", "spacing": 0.04, "specks": True},
                               "Band": mat("Band", "gold" if capt else shirt)}})
    for side, sx in (("L", 1), ("R", -1)):
        objs.append({"model": "models/player/player_leg.glb", "bone": name + side,
                     "position": [x + sx * LEGX, HIP, z],
                     "materials": {"Skin": mat("Skin", "skin", step=skin), "Sock": mat("Sock", socks),
                                   "Boot": {"ramp": "boot"}}})
objs.append({"model": "models/env/ball.glb", "bone": "ball", "position": [0, 0.2, 0],
             "materials": {"Ball": {"ramp": "chalk", "spacing": 0.035}, "Patch": {"ramp": "navy", "spacing": 0.035}}})
objs.append({"model": "models/env/ring.glb", "bone": "ring", "position": [0, 0.04, 0],
             "materials": {"Mark": {"ramp": "mark", "flags": ["unlit", "nocast"], "spacing": 0.045}}})
# the supporters behind the far fence: the footballer's body in village colours (the fence hides the rest)
FANS = [(-8.6, "pink", 0, 0), (-7.4, "teal", -1, 2), (-2.6, "coral", 0, -1), (-1.5, "gold", 0, 2),
        (1.9, "violet", -1, 0), (5.2, "sky", 0, -1), (6.4, "pink", 0, 2), (9.3, "teal", -1, 0)]
for i, (x, shirt, skin, hair) in enumerate(FANS):
    objs.append({"model": "models/player/player_body.glb", "bone": f"fan{i}", "position": [x, 0, -8.0],
                 "materials": {"Shirt": mat("Shirt", shirt), "Trim": mat("Trim", "chalk"),
                               "Shorts": mat("Shorts", "navy"),
                               "Skin": mat("Skin", "skin", step=skin), "Hair": mat("Hair", "wood", step=hair),
                               "Eye": {"ramp": "navy", "spacing": 0.04, "specks": True},
                               "Band": mat("Band", shirt)}})
bake = {"palette": "art/palette.json", "spacing": 0.06, "fat": 1.0, "seed": 1, "out": "scene/splats.bin",
        "bounds": [[-15.0, 0.0, -12.5], [15.0, 4.6, 9.0]], "objects": objs}
with open(os.path.join(here, "scene.bake.json"), "w") as f:
    json.dump(bake, f, indent=1)
print("wrote scene.bake.json:", len(objs), "objects")
