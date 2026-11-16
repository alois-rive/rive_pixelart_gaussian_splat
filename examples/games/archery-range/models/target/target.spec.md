# Asset: target (hero prop, a pool of game bones)

Concept: `../../art/target/sheet.v1.png` (Island Joy 16 colours), refs cut to `../../art/target/refs/`.
Up Z, facing -Y; origin on the ground under the boss centre. Built by `make_target.py`, which writes
`p1_blockout.txt` and `p2_form.txt` from the numbers below.

Scale: the boss, 342 px across in the front panel = 1.2 m (285 px a metre). Total height 474 px = 1.66 m.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Boss | 12-gon, 1.2 flat to flat (circumradius 0.621, turned 15 degrees: flats on top and at the sides), 0.3 thick | centre (0, 0, 1.08), face towards -Y, leaning back 12 degrees | Straw rim and back (straw, #9b9c82) |
| Face rings | five rings 0.118 wide: four insets of the front cap | on the face | White (straw, #ffffff), Night (stone, #393457), Teal (teal, #11adc1), Crimson (crimson, #c92464), Gold centre (straw, #f7e476) |
| Front legs | 0.12 square | from (+-0.49, -0.22, 0.12) to (+-0.49, 0.13, 0.95) | Leg (wood, #f99252) |
| Back leg | 0.12 square | from (0, 0.19, 1.22) to (0, 0.70, 0.08) | Leg |
| Runners | 0.15 x 1.41 x 0.12 | x +-0.53, y -0.45 .. 0.96 | Runner (wood, #cb4d68) |
| Runner tips | 0.15 x 0.1, 0.22 long | from (+-0.53, -0.42, 0.05) up to (+-0.53, -0.56, 0.17) | Runner |

## Assumptions
- The sheet's back and top views draw two braces from the back leg to the front legs; its right view
  draws none (they would cross the A as a bar: right IoU 0.565 with them). The right view leads: no braces.
- The front view hides the back leg behind nothing (it would show below the boss between the front legs);
  the model has it (front view: a little green in the compare sheet), the back and right views lead.
- The face leans 12 degrees (the right view's top edge sits 55 px behind its bottom over 313 px), not
  the brief's 10.
- Splat compensation in p2 (assets.md, "positive shapes come out fatter"): legs 0.8 x thinner, runners
  0.7 x lower and 0.85 x narrower, the boss 0.9 x thinner; the runners' undersides are deleted (they sit
  on the track). Thin parts bake at 0.04, the rings at 0.06, the boss at 0.1.
- 236 triangles.

## Gate record (generated-sheet tier, chosen before the build: IoU >= 0.75 / 0.7 splats, drift <= 0.08,
colour drift <= 0.25)
- p1 blockout v1: right 0.565 (legs a few cm behind the sheet's, braces): fail. v2 legs moved: right 0.720.
  v3 lean 12, legs forward, runners 0.12: 0.914 / 0.878 / 0.945 / 0.832. Final (no braces):
  **0.915 / 0.908 / 0.944 / 0.827, aspect drift 0.029 / 0.003 / 0.027 / 0.053**.
- p2 form (rings, materials, compensation): **0.915 / 0.807 / 0.924 / 0.764, drift 0.022 / 0.010 /
  0.020 / 0.053** (`--min-iou 0.75`).
- p4 splats, albedo, bench at the scene's spacings: without compensation right 0.575 / top 0.683 (legs and
  runners double their width); with it and the braces removed: **IoU 0.859 / 0.705 / 0.879 / 0.720,
  aspect drift 0.000 / 0.034 / 0.002 / 0.003, colour drift 0.08 / 0.11 / 0.14 / 0.11** (`--min-iou 0.7`).
  No waivers.
- Goldens: `goldens/target` (framed, lit like the scene), `goldens/target@scene` (texel 0.079, 160 px).
