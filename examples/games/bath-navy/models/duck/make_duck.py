# Writes the rubber duck's phase command files from the spec's numbers (duck.spec.md):
#   p1_blockout.txt  one primitive per named part (body, head, beak, two eyes, two wings, tail)
#   p2_form.txt      materials in exact Lost Century colours, flat shading, export
# Run from models/duck: /usr/bin/python3 make_duck.py. Up Z, facing -Y, origin on the ground under the
# body's centre (the game floats it there).

HEX = {"body": "b3a555", "beak": "c77b58", "eye": "4b3d44"}


def col(name):
    h = HEX[name]
    return "--base-color " + " ".join(f"{int(h[i:i + 2], 16) / 255:.4f}" for i in (0, 2, 4))


p1 = ["# Rubber duck, phase 1: blockout. Sizes from the sheet at 640 px a metre (duck.spec.md).",
      "new",
      # body: a faceted egg 0.54 wide, 0.70 long, 0.38 tall, bottom on the ground
      "add mesh uv-sphere --name Body --segments 10 --rings 6 --radius 1 --location 0 0 0",
      "scale 0.26 0.35 0.2",
      "apply --scale",
      "set location 0 0.01 0.19",
      "apply --location",
      # head: a faceted ball r 0.2 over the front half
      "add mesh uv-sphere --name Head --segments 10 --rings 6 --radius 0.2 --location 0 -0.125 0.53",
      # beak: a wide flat wedge out of the head's front
      "add mesh cube --name Beak --size 1 --location 0 -0.37 0.47",
      "scale 0.25 0.16 0.08",
      "apply --scale",
      # eyes: two dark buttons on the head's sides, a little forward
      "add mesh uv-sphere --name EyeL --segments 6 --rings 4 --radius 0.05 --location 0.15 -0.22 0.58",
      "scale 0.6 1 1",
      "apply --scale",
      "add mesh uv-sphere --name EyeR --segments 6 --rings 4 --radius 0.05 --location -0.15 -0.22 0.58",
      "scale 0.6 1 1",
      "apply --scale",
      # wings: stubby slabs on the body's sides
      "add mesh uv-sphere --name WingL --segments 6 --rings 4 --radius 1 --location 0 0 0",
      "scale 0.07 0.17 0.08",
      "apply --scale",
      "set location 0.29 0.06 0.25",
      "set rotation 0 0 -8",
      "add mesh uv-sphere --name WingR --segments 6 --rings 4 --radius 1 --location 0 0 0",
      "scale 0.07 0.17 0.08",
      "apply --scale",
      "set location -0.29 0.06 0.25",
      "set rotation 0 0 8",
      # tail: a short upturned wedge at the back
      "add mesh cone --name Tail --vertices 4 --radius1 0.13 --radius2 0.0 --depth 0.26 --location 0 0 0",
      "scale 1 0.7 1",
      "apply --scale",
      "set rotation 0 0 45",
      "apply --rotation",
      "set rotation -50 0 0",
      "apply --rotation",
      "set location 0 0.3 0.33",
      "select all",
      "shade flat"]

p2 = ["# Rubber duck, phase 2: surfacing. Body, head, wings and tail one yellow; an orange beak; dark eyes.",
      f"material new Body {col('body')} --no-slot",
      f"material new Beak {col('beak')} --no-slot",
      f"material new Eye {col('eye')} --no-slot",
      "select Body Head WingL WingR Tail",
      "material assign Body",
      "select Beak",
      "material assign Beak",
      # the beak tapers to its tip: its front face shrinks a little
      "active Beak",
      "mode edit",
      'select face where "normal.y < -0.9"',
      "scale 0.8 1 0.7",
      "mode object",
      "select EyeL EyeR",
      "material assign Eye",
      "select all",
      "shade flat",
      "export duck.glb"]

open("p1_blockout.txt", "w").write("\n".join(p1) + "\n")
open("p2_form.txt", "w").write("\n".join(p2) + "\n")
print("wrote p1_blockout.txt p2_form.txt")
