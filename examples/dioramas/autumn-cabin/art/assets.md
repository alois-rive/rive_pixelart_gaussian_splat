# Assets: a cabin in an autumn wood (Oil 6)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 214 x 134 art pixels; `orthoHeight` 8.5 m -> texel
0.064 m. Splat spacing 0.14 m (2.2 texels: big, painterly splats); the log walls 0.11, small things
(windows, mushrooms, leaves, smoke) 0.06-0.1. Palette: Oil 6 (`palette.json`, 6 colours) with ramps
ground, wood, roof, leaf, smoke, glow (ground and wood hold the same five colours: separate names so
a material can move to its own ramp later). Camera: orthographic, pitch 28, yaw 25, spin 3 deg/s.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Animation |
|---|---|---|---|---|---|---|---|
| ground | terrain | 10 x 10 x 2.4 | 1 | ground (48 px texture: earth, leaf litter, hollows, the path), ground (sides) | this list | 88 | |
| cabin | hero prop | 3.66 x 2.65 x 2.87 | 1 | wood (logs texture 2 x 12), roof (roof, stone), glow (windows, unlit, one step up) | `cabin/sheet.v1.png` | 128 | |
| maple | foliage | 2.6 x 2.4 x 3.4 | 7 (0.6-1.1; every other one a step pinker) | wood, leaf (sway) | this list | 80 | whole tree sways +-2 deg about its foot, 4 s, eased, 8 fps; phases 0-3.4 s |
| woodpile | prop | 1.1 x 0.9 x 0.82 + stump | 1 | wood (bark, pale cut ends) | this list | 196 | |
| mushrooms | prop | 0.7 x 0.5 x 0.36 (x1-1.2) | 2 | smoke (stems), leaf (caps) | this list | 204 | |
| rock | prop | 0.9 x 0.7 x 0.5 | 2 | roof | this list | 20 | |
| leaves | effect | 8.6 x 8.6 x 9 | 1 (40 bands, 40 bones) | leaf (two colours, double, nocast, spacing 0.06) | this list | 1040 | rigid fall 9 m / 20 s with a +-0.4 m sway, seamless (a banded column, each leaf ends in the ground), 10 fps |
| smoke | effect | puff r 0.34 | 3 (phases 0, 1.33, 2.67 s) | smoke (lit, nocast) | this list | 20 | each puff rises 2.6 m, drifts 0.8 m, grows 0.25 -> 1 and shrinks at the top, 4 s loop, 8 fps |

Bones: 7 trees + 40 leaf bands + 3 puffs = 50 of 63. Blob: 26 000 splats, 1.2 MB.

The leaves (`models/env/make_leaves.py` writes `leaves.txt`) are one 9 m column cut into 40 thin
bands, one object (one bone) each, falling and swaying together; a band wholly under the ground
(inside the clearing's 0.5 m slab) jumps back to the column's top, above the frame, so every leaf
sinks into the ground and none falls past the island. Leaves stay inside a 3.9 m circle (with the
sway and their size, inside the 4.83 m rim). The bands sit one band apart, so the 20 s loop has no
seam; the jumps land on the bake's 10 fps samples (every 0.5 s).

The chimney smoke is the snowfall's trick turned into a per-puff loop: one puff model whose frame 0
is its full size (the bake samples splats at frame 0 and inverts its matrix, so frame 0 can be
neither small nor zero), keyed linearly through its life with a one-frame jump from the top back to
the chimney; three copies with phases a third of the loop apart make the column.
