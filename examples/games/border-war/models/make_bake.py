# Writes ../scene.bake.json: the static world (terrain, woods) and every game bone (buildings, units,
# groves, carried loads, projectiles, scaffolds; 63 in all). Pools are parked off the map (under the
# HUD panel) until game.as places them. Run from models/: /usr/bin/python3 make_bake.py
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))

RAMP = {
    "Grass": "grass", "GrassLt": "grass", "GrassDk": "grass", "Path": "dirt", "Bank": "dirt", "Sand": "dirt",
    "Water": "water", "Ripple": "water", "Leaf": "leaf",
    "Bark": "wood", "Stump": "wood", "Timber": "wood", "Logs": "wood", "LogsLt": "wood", "Wood": "wood",
    "Trousers": "wood", "Leather": "wood", "Door": "wood", "Hair": "wood",
    "Cut": "cream", "Sack": "cream", "Tunic": "cream", "Straw": "cream", "Thatch": "cream", "Plaster": "cream",
    "Shaft": "cream", "Bone": "cream",
    "Rock": "stone", "Stone": "stone", "Dark": "stone",
    "Steel": "steel", "Bright": "steel", "Blade": "steel",
    "Gold": "gold", "Skin": "skin", "Orc": "orcskin", "Hide": "crimson", "HideDk": "crimson",
    "Team": "royal", "Tabard": "royal", "Hood": "royal", "Roof": "royal", "Banner": "royal",
}


def mats(names, spacing=None, extra=None):
    out = {}
    for n in names:
        m = {"ramp": RAMP[n]}
        if spacing:
            m["spacing"] = spacing
        if extra and n in extra:
            m.update(extra[n])
        out[n] = m
    return out


UNIT = ["Skin", "Tunic", "Straw", "Trousers", "Team", "Tabard", "Steel", "Bright", "Blade", "Gold", "Leather",
        "Wood", "Hood", "Orc", "Hide", "Bone", "Hair", "LogsLt"]
BUILD = ["Stone", "Plaster", "Timber", "Door", "Roof", "Banner", "Dark", "Logs", "LogsLt", "Thatch", "Hide", "HideDk",
         "Bone", "Blade", "Gold", "Wood"]
PARK = [0, 0, 9.0]    # under the HUD panel, off the play area


def obj(model, bone=None, copies=None, pos=PARK, yaw=0, names=(), spacing=None, extra=None):
    o = {"model": f"models/{model}/{model}.glb" if "/" not in model else model, "position": list(pos), "yaw": yaw,
         "materials": mats(names, spacing, extra)}
    if bone:
        o["bone"] = bone
    if copies:
        o["copies"] = copies
    return o


tiny = {n: {"specks": True} for n in UNIT + BUILD}
objects = [
    obj("models/env/terrain.glb", pos=(0, 0, 0), names=["Grass", "GrassLt", "GrassDk", "Path", "Bank", "Sand", "Water", "Ripple"],
        spacing=0.11),
    obj("models/env/woods.glb", pos=(0, 0, 0), names=["Leaf", "Bark", "Rock", "Gold", "Timber", "Dark", "Stump", "Cut"], spacing=0.08,
        extra={"Leaf": {"flags": ["sway"], "spacing": 0.095}, "Gold": {"spacing": 0.06}, "Timber": {"spacing": 0.06},
               "Dark": {"spacing": 0.06}, "Stump": {"spacing": 0.06}, "Cut": {"spacing": 0.05, "specks": True}}),
    # the hero: the Manor, at the spacing it was gated at (finer timber)
    {"model": "models/manor/manor.glb", "bone": "manor", "position": PARK, "yaw": 0,
     "materials": {"Stone": {"ramp": "stone", "spacing": 0.07}, "Plaster": {"ramp": "cream", "spacing": 0.07},
                   "Timber": {"ramp": "wood", "spacing": 0.05}, "Door": {"ramp": "wood", "spacing": 0.05},
                   "Roof": {"ramp": "royal", "spacing": 0.07}, "Banner": {"ramp": "royal", "spacing": 0.05},
                   "Dark": {"ramp": "stone", "spacing": 0.04, "specks": True}}},
    obj("yard", "yard", names=["Stone", "Plaster", "Timber", "Door", "Roof", "Blade", "Gold", "Wood", "Thatch", "Bright"],
        spacing=0.075, extra={"Blade": {"spacing": 0.045}, "Gold": {"spacing": 0.045, "specks": True},
                              "Wood": {"spacing": 0.05}, "Bright": {"spacing": 0.04, "specks": True},
                              "Timber": {"spacing": 0.055}, "Thatch": {"spacing": 0.05}}),
    obj("watchtower", "htower", 2, names=["Stone", "Timber", "Roof", "Banner", "Door", "Dark"], spacing=0.07,
        extra={"Timber": {"spacing": 0.045}, "Banner": {"spacing": 0.045}, "Dark": {"spacing": 0.04, "specks": True},
               "Door": {"spacing": 0.05}}),
    obj("cottage", "cottage", 2, names=["Plaster", "Timber", "Thatch", "Stone", "Door", "Dark", "LogsLt"], spacing=0.07,
        extra={"Timber": {"spacing": 0.06}, "Door": {"spacing": 0.05}, "Dark": {"spacing": 0.04, "specks": True},
               "LogsLt": {"spacing": 0.05}, "Stone": {"spacing": 0.05}}),
    obj("warcamp", "warcamp", names=["Logs", "Hide", "HideDk", "LogsLt", "Dark", "Bone"], spacing=0.075,
        extra={"LogsLt": {"spacing": 0.05}, "Bone": {"spacing": 0.05}, "Dark": {"spacing": 0.05}}),
    obj("pit", "pit", names=["Logs", "LogsLt", "Hide", "Bone"], spacing=0.07,
        extra={"LogsLt": {"spacing": 0.05, "specks": True}, "Bone": {"spacing": 0.05}}),
    obj("lookout", "lookout", 2, names=["Logs", "LogsLt", "Hide", "Bone"], spacing=0.065,
        extra={"LogsLt": {"spacing": 0.05}, "Bone": {"spacing": 0.05}}),
    obj("tent", "tent", 2, names=["Hide", "HideDk", "LogsLt", "Dark", "Bone"], spacing=0.07,
        extra={"LogsLt": {"spacing": 0.045, "specks": True}, "Dark": {"spacing": 0.05}, "Bone": {"spacing": 0.045, "specks": True}}),
    obj("yeoman", "yeoman", 5, names=["Skin", "Tunic", "Straw", "Trousers", "Team", "Leather", "Bright"], spacing=0.058,
        extra={"Bright": {"specks": True}, "Leather": {"specks": True}}),
    obj("swordsman", "sword", 5, names=["Skin", "Tabard", "Steel", "Bright", "Blade", "Gold", "Leather", "Team"],
        spacing=0.058, extra={"Gold": {"specks": True}, "Blade": {"specks": True}, "Bright": {"specks": True}}),
    obj("archer", "archer", 4, names=["Skin", "Trousers", "Leather", "Hood", "Wood", "Straw"], spacing=0.058,
        extra={"Straw": {"specks": True}, "Wood": {"specks": True}, "Skin": {"specks": True}}),
    obj("drudge", "drudge", 5, names=["Orc", "Wood", "Hide", "Bone", "Leather", "Steel"], spacing=0.058,
        extra={"Bone": {"specks": True}, "Leather": {"specks": True}, "Steel": {"specks": True}}),
    obj("brute", "brute", 5, names=["Orc", "Hide", "Bone", "Hair", "LogsLt"], spacing=0.058,
        extra={"Bone": {"specks": True}, "Hair": {"specks": True}}),
    obj("thrower", "thrower", 4, names=["Orc", "Wood", "Hide", "Bone", "Bright"], spacing=0.058,
        extra={"Bone": {"specks": True}, "Bright": {"specks": True}, "Wood": {"specks": True}}),
    obj("grove", "grove", 6, names=["Leaf", "Bark"], spacing=0.085, extra={"Leaf": {"flags": ["sway"]}}),
    obj("sack", "sack", 3, names=["Sack", "Wood", "Gold"], spacing=0.04, extra={n: {"specks": True} for n in ("Sack", "Wood", "Gold")}),
    obj("logs", "logs", 3, names=["LogsLt"], spacing=0.05, extra={"LogsLt": {"specks": True}}),
    obj("arrow", "arrow", 4, names=["Shaft", "Blade", "Team"], spacing=0.035,
        extra={n: {"specks": True} for n in ("Shaft", "Blade", "Team")}),
    obj("spear", "spear", 4, names=["Wood", "Blade", "Hide"], spacing=0.035,
        extra={n: {"specks": True} for n in ("Wood", "Blade", "Hide")}),
    obj("scaffold", "scaf", 3, names=["LogsLt", "Wood"], spacing=0.07, extra={n: {"specks": True} for n in ("LogsLt", "Wood")}),
]

bake = {"palette": "art/palette.json", "spacing": 0.07, "fat": 1.0, "seed": 1, "out": "scene/splats.bin",
        "bounds": [[-9.8, -0.4, -9.2], [9.8, 3.4, 7.8]], "objects": objects}
with open(os.path.join(HERE, "..", "scene.bake.json"), "w") as f:
    json.dump(bake, f, indent=1)
print("wrote scene.bake.json:", len(objects), "entries")
