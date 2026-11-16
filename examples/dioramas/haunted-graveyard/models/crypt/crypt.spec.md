# Asset: crypt chapel (hero prop)
Concept: ../../art/crypt/sheet.v1.png (Hollow colours), refs cut to ../../art/crypt/refs/.
Up Z, facing -Y; origin at the ground under the centre. Total height 3.69 m (spire tip, leaning).

Scale: the front wall, 220 px in the front panel = 1.8 m (122 px a metre). Gate views at `--elevation 4`.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Plinth | 2.3 x 3.0 x 0.15 | z 0..0.15 | Roof (dark, #0f0f1b) |
| Walls | 1.8 x 2.7 x 1.42 | z 0.15..1.57 | Stone (stone, #565a75) |
| Gable | wedge 1.8 x 2.7 x 1.15 (52 degrees) | z 1.57..2.72 | Stone |
| Roof | 2 slabs 1.88 x 3.1 x 0.2, 52 degrees, 0.26 overhang | ridge along Y | Roof (dark) |
| Buttresses | 4, 0.55 out x 0.35 x 1.2, outer top sloped 0.7 | x +-1.15, y +-0.85 | Stone |
| Door | pointed: leaf 0.54 x 1.2 + tip; frame 0.8 x 1.34 + tip, standing 0.08 / 0.13 proud | front, z 0.15..1.6 | Door (dark, spacing 0.1); Trim (stone, #c6b7be, spacing 0.1) |
| Windows | pointed 0.3 x 0.62 + tip, one each long wall | x +-0.93, z 0.69..1.46 | Glow (glow, #fafbf6, unlit, spacing 0.08) |
| Tower | 0.6 x 0.6 x 1.1, a pale belfry band 0.36, a 4-sided spire 0.45; leaned 15 degrees to +X and 8 to the front about its foot | foot (0.3, -0.95, 2.25) | Stone; Trim; Roof |

## Assumptions
- The sheet's top view is drawn from in front (the front wall and door show below the roof): its depth is
  4.1 m against the right view's 3.1 m. Front and right lead; the top view's aspect gets a waiver.
- The tower leans to +X (the image's right in front, left in back, right in top): consistent across the
  sheet, though the brief asked for the chapel's right. Modelled as drawn.
- The bell openings (a pale square with a bell on each face) are drawn as a pale belfry band: a bell is
  under two splats.

## Gate record (generated-sheet tier, chosen before the build)
- p1/p2 v1 hedra `--elevation 4`: IoU 0.797 / 0.877 / 0.839 / 0.794; aspect drift front 0.137, back 0.170,
  top 0.128 (fail): the sheet's buttresses splay to 2.85 m and its tower is 0.2 m lower.
- p2 v2 (buttresses 0.55 out at x +-1.15, tower 1.1 tall): **IoU 0.812 / 0.848 / 0.847 / 0.821, aspect drift
  0.002 / 0.017 / 0.027 / 0.189** (`--min-iou 0.75 --max-aspect-drift 0.08`). p1 (tower upright): 0.784 /
  0.851 / 0.798 / 0.821.
- p4 splats, albedo, bench at the scene's spacing (0.15): **IoU 0.780 / 0.828 / 0.804 / 0.872, aspect drift
  0.049 / 0.048 / 0.007 / 0.160, colour drift 0.01 / 0.01 / 0.02 / 0.01** (`--min-iou 0.7`).
- Waiver, top aspect (0.189 mesh, 0.160 splats): the sheet's top view is not a top view (see Assumptions).
- Bake: `Door (11)`, `WinL (11)` speck warnings at 0.1 m spacing (the arch tips are separate islands): door
  0.1, windows 0.08; joined each tip to its opening.
- Goldens: `goldens/crypt` (framed, 320 px, pixel 2), `goldens/crypt@scene` (texel 0.0675, 160 px).
