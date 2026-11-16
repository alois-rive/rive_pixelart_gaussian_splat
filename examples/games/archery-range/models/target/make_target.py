# Writes the target's phase command files from the spec's numbers (target.spec.md):
#   p1_blockout.txt  one primitive per named part at its size (boss, legs, braces, runners)
#   p2_form.txt      the painted rings (four insets of the front cap), materials, flat shading, export
# Run from models/target: /usr/bin/python3 make_target.py. Up Z, facing -Y, origin on the ground
# under the boss centre. Colours are exact Island Joy 16 hexes.
import math

HEX = {"gold": "f7e476", "crimson": "c92464", "teal": "11adc1", "night": "393457", "white": "ffffff",
       "straw": "9b9c82", "leg": "f99252", "runner": "cb4d68"}


def col(name):
    h = HEX[name]
    return "--base-color " + " ".join(f"{int(h[i:i + 2], 16) / 255:.4f}" for i in (0, 2, 4))


def beam(name, a, b, w, d=None):
    d = d or w
    dx, dy, dz = (b[i] - a[i] for i in range(3))
    L = math.sqrt(dx * dx + dy * dy + dz * dz)
    c = [(a[i] + b[i]) / 2 for i in range(3)]
    ta = math.degrees(math.acos(max(-1, min(1, dz / L))))
    tb = math.degrees(math.atan2(dx / L, -dy / L)) if ta > 1e-6 else 0.0
    return [f"add mesh cube --name {name} --size 1 --location {c[0]:.4f} {c[1]:.4f} {c[2]:.4f}",
            f"scale {w} {d} {L:.4f}", "apply --scale", f"set rotation {ta:.3f} 0 {tb:.3f}"]


BOSS_R = 0.621      # 12-gon circumradius: 1.2 m flat to flat (turned 15 degrees: flats top and sides)
BOSS_Z = 1.08       # boss centre height
LEAN = 12           # degrees the face leans back
LEG_X = 0.49
RUN_X = 0.53

p1 = ["# Target, phase 1: blockout. One primitive per part at the spec's size (target.spec.md).",
      "new",
      f"add mesh cylinder --name Boss --vertices 12 --radius {BOSS_R} --depth 0.3 --location 0 0 0",
      "set rotation 0 0 15",
      "apply --rotation",
      # local +Z (the painted face) -> front (-Y), leaning back LEAN degrees; rotation kept on the
      # object so p2 can pick the face by its local normal
      f"set rotation {90 - LEAN} 0 0",
      f"set location 0 0.0 {BOSS_Z}"]
for s, x in (("L", -LEG_X), ("R", LEG_X)):
    p1 += beam(f"Leg{s}", (x, -0.22, 0.12), (x, 0.13, 0.95), 0.12)
p1 += beam("BackLeg", (0, 0.19, 1.22), (0, 0.70, 0.08), 0.12)
# The sheet's back and top views draw two braces from the back leg to the front legs; its right view
# has none (they would cross the A as a bar). The right view leads: no braces (spec, Assumptions).
for s, x in (("L", -RUN_X), ("R", RUN_X)):
    p1 += [f"add mesh cube --name Runner{s} --size 1 --location {x} 0.255 0.06", "scale 0.15 1.41 0.12",
           "apply --scale"]
    p1 += beam(f"Tip{s}", (x, -0.42, 0.05), (x, -0.56, 0.17), 0.15, 0.1)
p1 += ["select all", "shade flat"]

p2 = ["# Target, phase 2: form and surfacing. The front cap inset four times into five painted rings of",
      "# equal width (white, night, teal, crimson, gold); straw rim and back; wood legs and runners.",
      f"material new Straw {col('straw')} --no-slot",
      f"material new White {col('white')} --no-slot",
      f"material new Night {col('night')} --no-slot",
      f"material new Teal {col('teal')} --no-slot",
      f"material new Crimson {col('crimson')} --no-slot",
      f"material new Gold {col('gold')} --no-slot",
      f"material new Leg {col('leg')} --no-slot",
      f"material new Runner {col('runner')} --no-slot",
      # splat compensation (assets.md, "positive shapes come out fatter"): every disc reaches about one
      # radius past its face, so the thin parts are thinned by about two radii of their bake spacing
      # (legs, braces, runners at 0.04: 0.12 -> 0.08) and the boss by one radius at 0.1 (0.3 -> 0.22)
      "select LegL LegR BackLeg",
      "scale 0.8 0.8 1 --pivot individual --orient local",
      "select RunnerL RunnerR",
      "scale 0.85 1 0.7 --pivot individual --orient local",
      "select TipL TipR",
      "scale 0.85 0.7 1 --pivot individual --orient local",
      "select Boss",
      "scale 1 1 0.9 --orient local",
      "material assign Straw",
      "active Boss",
      "mode edit",
      'select face where "normal.z > 0.9"',
      "material assign White"]
for m in ("Night", "Teal", "Crimson", "Gold"):
    p2 += ["inset 0.118", f"material assign {m}"]
p2 += ["mode object"]
# the runners' undersides sit on the track and are never seen: delete them (they bake splats that
# reach a radius below the ground)
for r in ("RunnerL", "RunnerR"):
    p2 += [f"active {r}", "mode edit", 'select face where "normal.z < -0.9"', "delete only-faces", "mode object"]
p2 += ["select LegL LegR BackLeg",
       "material assign Leg",
       "select RunnerL RunnerR TipL TipR",
       "material assign Runner",
       "select all",
       "shade flat",
       "export target.glb"]

open("p1_blockout.txt", "w").write("\n".join(p1) + "\n")
open("p2_form.txt", "w").write("\n".join(p2) + "\n")
print("wrote p1_blockout.txt p2_form.txt")
