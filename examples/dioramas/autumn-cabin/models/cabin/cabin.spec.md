# Asset: cabin (hero prop)
Concept: ../../art/cabin/sheet.v1.png (Oil 6 colours), refs cut to ../../art/cabin/refs/.
Up Z, facing -Y; origin at the ground under the walls' centre. Total height 2.87 m.
Measured off the FRONT panel: the log walls, 3.0 m, are 468 px: 156 px a metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Footing | 3.1 x 2.44 x 0.2 | z 0..0.2 | Stone (roof, #8b6d9c) |
| Walls | 3.0 x 2.34 x 1.25 | z 0.2..1.45 | Logs (wood, texture 2 x 12: #c69fa5 logs, #8b6d9c gaps, cube-projected 1.25 m; spacing 0.11) |
| Attic | wedge 3.0 x 2.34 x 1.1, ridge along X | z 1.45..2.55 | Logs |
| Roof | 2 slabs 3.5 (eave) / 2.95 (ridge) x 1.75 x 0.14, 41.2 degrees | ridge z 2.68 | Roof (roof, #494d7e) |
| Door | 0.66 x 0.1 x 1.12 | front centre | Door (wood, #272744) |
| Windows | 0.48 square x 0.1 | front x +-0.82, back centre, z 1.0 | Glow (glow, #f2d3ab, unlit; +1 step in the bake: #fbf5ef) |
| Chimney | 0.52 x 0.54 x 2.84 + cap 0.62 x 0.64 x 0.14 | x 1.6 (outside the right gable) | Stone |

## Assumptions
- The sheet's top view is shallower than its right view (2.52 m vs 2.75 m deep) and its front view
  draws the roof as a trapezoid; front and right lead. The roof is a trapezoid (3.5 m at the eave,
  2.95 at the ridge) and a little wider than the sheet's 3.37 so the splat top view passes too.
- Log ends at the corners and the stones of the footing are dropped (smaller than two splats).
- The windows are painted one ramp step up in the bake (#fbf5ef) so they read against the sunlit
  logs, whose highlight is the sheet's window colour.
- Side views are drawn level (no rim shows): gate views at elevation 0.

## Gate record (generated-sheet tier, chosen before the build)
- Form, hedra views, `--min-iou 0.75 --max-aspect-drift 0.08`:
  - p1 v1: IoU 0.941 / 0.932 / 0.946 / 0.956, top aspect drift 0.114 FAIL (roof 2.80 m deep).
  - p1 v2 (roof slope 1.85 -> 1.75 m): pass, drift 0.024 / 0.052 / 0.008 / 0.047.
  - final (eave 3.37 -> 3.5, chimney 2.9 -> 2.84, see below): **front 0.929, right 0.898, back
    0.933, top 0.952; aspect drift 0.063 / 0.031 / 0.048 / 0.027. Pass.**
- Look, splats albedo (bench at the scene's spacing 0.14, `--min-iou 0.7`):
  - v1: top aspect drift 0.086 FAIL (the splat silhouette's fattening deepens the roof): eave
    widened to 3.5 m; right drift then 0.079: chimney lowered 6 cm.
  - final: **IoU 0.892 / 0.839 / 0.914 / 0.909, aspect drift 0.003 / 0.070 / 0.026 / 0.071, colour
    drift 0.01 / 0.04 / 0.01 / 0.01. Pass**, no waivers.
- Goldens: `goldens/cabin` (framed, lit with the scene's jitter 0.4, bandDither 0.5, keyLight 0.3,
  highlight 0.85, shadeSteps 1.2) and `goldens/cabin@scene` (`--texel 0.064`).
