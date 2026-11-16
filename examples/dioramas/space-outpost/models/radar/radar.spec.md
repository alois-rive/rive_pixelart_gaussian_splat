# Asset: radar (hero prop, animated)
Concept: ../../art/radar/sheet.v1.png (Ammo-8 colours), refs cut to ../../art/radar/refs/.
Up Z, facing -Y; origin at the ground under the pedestal's centre. Total height 2.32 m (2.9 m at the
scene's scale 1.25). Measured off the FRONT panel: 478 px = 2.3 m, 208 px a metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Pedestal | 8-sided, r 0.75 (1.39 across flats) x 0.46 | z 0..0.46 | Base (hull, #305d42) |
| Drum | 8-sided, r 0.48 x 0.24 | z 0.46..0.70 | Yoke (hull, #305d42) |
| Yoke | crossbar 1.74 x 0.3 x 0.16; arms 0.17 x 0.28 x 0.96 at x +-0.8; caps 0.2 x 0.34 x 0.2 | arms z 0.62..1.58 | Yoke |
| Dish bowl | 12-sided frustum, rim r 0.8 front, back r 0.45, 0.45 deep, front poked 0.3 concave | axle (pivot) at (0, 0, 1.5) | DishFace (dish, #89a257), DishBack (hull, #4d8061) |
| Feed | 3 struts 0.12 (exaggerated: the sheet's are ~0.03), receiver 0.2, tip 0.12 | receiver 0.8 in front of the rim, level with the axle at rest | Strut (hull, #1e3a29, spacing 0.05), Glow (glow, #eeffcc, unlit, spacing 0.04) |
| Counterweight | 0.5 x 0.3 x 0.3 | behind the dish, level at rest | DishBack |

## Assumptions
- The sheet's views disagree on the dish's tilt: front and right draw it about 30 degrees up, the
  top view as if 60 degrees up (a near-round dish from above). The rest pose is 36 degrees, the tilt
  at which all four views pass (measured at 30 / 36 / 42: 36 maximises the worst view).
- The sheet's receiver sits below the dish axis in the right view; modelled there (level with the
  axle at rest) rather than on the axis.
- The yoke arms bend outward at their foot in the sheet; modelled as a straight crossbar.
- Side views are drawn from about 8 degrees above (the drum's top shows): gate views at `--elevation 8`.
- `inspect check`: 3 ngons (cylinder caps, harmless) and 12 duplicate verts where the three struts
  meet inside the receiver (hidden).

## Animation
`Head` (drum + yoke, origin at the ground centre) turns 0 -> 360 degrees about Z in 192 frames at
24 fps, linear. `Dish` (bowl, feed, counterweight joined, origin on the axle) has rotation
(tilt, 0, yaw) with the same yaw keys and tilt -36, -50, -36, -22, -36 at 0/48/96/144/192: Euler XYZ
is extrinsic (R = Rz Ry Rx), so the tilt happens about the axle and the turn about the vertical axis
through it, exactly as if the dish rode on the yoke. Exported with `--bake-animations`; baked at
12 fps (stepped), 8 s loop. Two bones.

## Gate record (generated-sheet tier, chosen before the build)
- Form, hedra views at `--elevation 8`, `--min-iou 0.75 --max-aspect-drift 0.08`:
  - p1 v1: right IoU 0.70 (struts and receiver too high, dish too small), top aspect drift 0.082.
  - p1 v2 (yoke narrowed to the sheet's 1.84 m, pivot 1.56 -> 1.50, bowl back r 0.25 -> 0.45,
    counterweight moved back): right 0.70, top passes.
  - p1 v3 (receiver lowered to the sheet's, counterweight levelled): right 0.74, top IoU 0.72.
  - p1 v4 (rest tilt 30 -> 36, the views' compromise): **front 0.884, right 0.760, back 0.806,
    top 0.771; aspect drift 0.058 / 0.052 / 0.033 / 0.004. Pass.** p2 (materials, animation): the same.
- Look, splats albedo (bench at the scene's spacing 0.08 and scale 1.25, `--min-iou 0.7`):
  **IoU 0.840 / 0.714 / 0.776 / 0.829, aspect drift 0.042 / 0.058 / 0.010 / 0.054, colour drift
  0.01 / 0.02 / 0.01 / 0.02. Pass**, no waivers.
- Goldens: `goldens/radar` (framed, lit, the scene's ink 2 and Bayer bands), `goldens/radar@scene`
  (`--texel 0.064`), `goldens/radar@3s` (iso, `--arg animSpeed=90`: the frame 3 s into the loop).
