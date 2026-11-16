# Asset: ball (hero, a pool of game bones)

Concept: `../../art/ball/sheet.v2.png`, refs cut to `../../art/ball/refs/`. v1's four views disagreed on the
order of the gores (its front and back contradicted its top and right); v2's brief lists, panel by panel,
which gores show, in the order of v1's top view. Up Z, front -Y; origin at the ball's CENTRE (the game spins
and squashes it about its centre). Built by `make_ball.py`, which writes `p1_blockout.txt` and `p2_form.txt`.

Scale: the ball, 430 px across in the front panel = 0.8 m (538 px a metre); the caps stand 0.02 m proud.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Ball | uv-sphere, 12 segments, 8 rings, r 0.4 | centre (0, 0, 0) | six gores of 60 degrees, centred (from +X, counter-clockwise from above) at 270 Red (red, #d41e3c), 330 Blue (blue, #488bd4), 30 Yellow (yellow, #ffb84a), 90 White (white, #faffff), 150 Green (green, #28c074), 210 White; the pole fans White |
| Caps | 10-gon r 0.13, 0.06 thick | at the poles, z +-0.395 | Cap (white), baked at 0.025 |

Gores are picked by the face centre's angle with linear tests (`tan 30` and `tan 60`: `select where` has no
`atan2`); the 12 segments put a vertex on every gore boundary.

## Assumptions
- 240 triangles.
- In the scene the ball is baked at 1.6 x (r 0.64, about 21 art pixels across).

## Gate record (generated-sheet tier, chosen before the build)
- Against v1: p1 0.962 / 0.962 / 0.961 / 0.964; p4 albedo colour drift 0.38 / 0.31 / 0.51 / 0.10 (the model
  follows v1's top view; its front and back views contradict it): a new sheet rather than a waiver.
- Against v2: **p1 and p2 IoU 0.963 / 0.964 / 0.964 / 0.988, aspect drift 0.009 / 0.009 / 0.004 / 0.009**
  (`--min-iou 0.75`).
- p4 splats, albedo (bench at 0.05, the scene's 0.07 at 1.6 x is 0.044 in model units): with the caps baked
  at 0.05 the thin caps fattened the height (right aspect drift 0.099, fail); caps their own material at
  0.025: **IoU 0.947 / 0.953 / 0.952 / 0.975, aspect drift 0.002 / 0.024 / 0.003 / 0.023, colour drift
  0.12 / 0.16 / 0.18 / 0.08** (`--min-iou 0.7`). No waivers.
- Goldens: `goldens/ball` (framed, lit like the scene), `goldens/ball@scene` (texel 0.06, 80 px).
