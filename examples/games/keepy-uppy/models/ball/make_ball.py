# Writes the beach ball's phase command files from the spec's numbers (ball.spec.md):
#   p1_blockout.txt  the faceted ball (uv-sphere, 12 segments, 8 rings) and its two pole caps
#   p2_form.txt      six gores picked by the faces' angle round the axis, white pole fans, export
# Run from models/ball: /usr/bin/python3 make_ball.py. Up Z, front -Y; origin at the ball's CENTRE (the
# game spins it about its centre). Colours are exact Journey hexes.

HEX = {"red": "d41e3c", "white": "faffff", "yellow": "ffb84a", "blue": "488bd4", "green": "28c074"}
R = 0.4


def col(name):
    h = HEX[name]
    return "--base-color " + " ".join(f"{int(h[i:i + 2], 16) / 255:.4f}" for i in (0, 2, 4))


p1 = ["# Beach ball, phase 1: blockout. A faceted ball 0.8 m across and two pole caps (ball.spec.md).",
      "new",
      f"add mesh uv-sphere --name Ball --segments 12 --rings 8 --radius {R} --location 0 0 0",
      f"add mesh cylinder --name CapTop --vertices 10 --radius 0.13 --depth 0.06 --location 0 0 {R - 0.005}",
      f"add mesh cylinder --name CapBot --vertices 10 --radius 0.13 --depth 0.06 --location 0 0 {-R + 0.005}",
      "select all",
      "shade flat"]

# the gores, 60 degrees each, centred (from +X, counter-clockwise seen from above) at: red 270 (the
# front, -Y), blue 330, yellow 30, white 90, green 150, white 210. tan 30 = 0.5774, tan 60 = 1.7321.
GORES = [
    ("Red", "pos.y < 0 && abs(pos.x) < -0.5774 * pos.y"),
    ("Blue", "pos.y < 0 && pos.x > 0 && pos.x >= -0.5774 * pos.y"),
    ("Yellow", "pos.y >= 0 && pos.x > 0 && pos.y < 1.7321 * pos.x"),
    ("White", "pos.y > 0 && abs(pos.x) <= 0.5774 * pos.y"),
    ("Green", "pos.y >= 0 && pos.x < 0 && pos.y < -1.7321 * pos.x"),
    ("White", "pos.y < 0 && pos.x < 0 && -pos.x >= -0.5774 * pos.y"),
]
p2 = ["# Beach ball, phase 2: surfacing. Six gores by angle, white pole fans and caps.",
      f"material new Red {col('red')} --no-slot",
      f"material new Blue {col('blue')} --no-slot",
      f"material new Yellow {col('yellow')} --no-slot",
      f"material new White {col('white')} --no-slot",
      f"material new Green {col('green')} --no-slot",
      f"material new Cap {col('white')} --no-slot",
      "active Ball",
      "mode edit"]
for m, expr in GORES:
    p2 += [f'select face where "{expr}"', f"material assign {m}"]
p2 += ['select face where "abs(normal.z) > 0.9"', "material assign White",
       "mode object",
       "select CapTop CapBot",
       "material assign Cap",
       "select all",
       "shade flat",
       "export ball.glb"]

open("p1_blockout.txt", "w").write("\n".join(p1) + "\n")
open("p2_form.txt", "w").write("\n".join(p2) + "\n")
print("wrote p1_blockout.txt p2_form.txt")
