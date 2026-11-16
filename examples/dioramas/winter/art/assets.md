# Assets: the winter windmill at night

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 215 x 136 art pixels; `orthoHeight` 8.2 m -> texel
0.06 m. Splat spacing 0.09 m (1.5 texels). Palette: Magik16 (`palette.json`, 16 colours).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Animation |
|---|---|---|---|---|---|---|---|
| hill | terrain | 6.6 x 6.6 x 3 | 1 | snow, stone | this list | 66 | |
| windmill | hero prop | 2.1 x 2.3 x 2.8 | 1 | stone, wood (planks texture), snow, lamp (unlit) | `windmill/sheet.v1.png` | 216 | sails: rigid, 1 turn / 6 s, 12 fps |
| pine | foliage | 1.8 x 1.8 x 2.2 | 5 (0.7-1.2) | wood, pine, snow (sway) | this list | 140 | sway |
| rock | prop | 1.0 x 0.8 x 0.6 | 2 | stone, snow | this list | 20 | |
| fence | prop | 2.4 x 0.14 x 0.86 | 1 | wood, snow | this list | 72 | |
| lamp | light prop | 0.6 x 0.3 x 1.8 | 1 | wood, lamp (unlit), magic | this list | 48 | lantern: rigid swing +-12 deg / 2 s |
| snowfall | effect | 5.6 x 5.6 x 7.5 | 1 (20 bands, 20 bones) | lamp (unlit, top step) | this list | 380 | rigid fall 7.5 m / 15 s, seamless, ends in the snow |

The snowfall (`models/env/make_snowfall.py` writes `snowfall.txt`) is one 7.5 m column of flakes cut
into 20 thin bands, one object (one bone) each. The bands fall together; when a band is wholly under
the snow (inside the hill's 0.5 m slab) it jumps back to the column's top, above the frame, so every
flake disappears into the snow and none falls past the island into the void below it. Flakes stay
inside a 2.8 m circle (the rim is 3.1 m out). The bands sit one band apart, so the column is uniform
at every frame and the 15 s loop has no seam; the jumps land on the bake's 12 fps samples.
Bones: sails + lantern + 20 snow bands = 22 of 63.
