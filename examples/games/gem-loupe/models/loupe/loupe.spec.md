# Asset: loupe (hero; the game's cursor, one game bone `loupe`)
Concept: ../../art/loupe/sheet.v1.png (Galaxy Flame colours), refs cut to ../../art/loupe/refs/ (no flips
or rotations: the sheet follows the brief). Modelled standing upright as drawn: up Z, the ring facing
-Y; origin on the ground under the knob. Scale from the FRONT panel: ring 229 px across for 0.64 m ->
358 px per metre; total height 470 px -> 1.31 m.

## Parts (metres)
| Part | Size | Position (z from the knob's bottom) | Material (ramp, step) |
|---|---|---|---|
| Knob | eight-sided squat ball, 0.21 across, 0.17 tall | z 0 .. 0.17 | Wood (#704d2b, wood step 2) |
| Handle | eight-sided frustum, 0.126 across at the bottom, 0.166 at the top, 0.45 long | z 0.15 .. 0.60 | Wood |
| Ferrule | eight-sided cylinder 0.174 across, 0.09 tall | z 0.60 .. 0.69 | Brass (#b6834c, brass step 2) |
| Ring | twelve-sided flat ring, 0.64 across the flats outside, 0.44 inside, 0.129 deep | centre z 1.003, top 1.32 | Brass |

`p1_blockout.txt` (the primitives; the ring is a 12-sided cylinder whose caps are inset by the band
width, opened and bridged), `p2_form.txt` (materials, caps buried in the ferrule deleted, joined,
flat, `loupe.glb`). 200 triangles.

In the scene the loupe is baked once at scale 1.15 (the inner opening 0.51 m, so that after the splats
close it by about two radii it still frames a 0.42 m gem). The game tilts it to face the camera
(pitch -66 = the camera's pitch) and hovers it over a cell with its ring centred on the view ray
through the gem: the ring frames the gem like a cursor. At rest it lies flat on the bench (pitch -90).

## Assumptions
- The sheet's TOP view is drawn at another scale (the ring 271 px long against 229 px in the front
  view) and its knob reads 0.18 m deep where front and right say 0.21. Front and right lead; the top
  view gets a waiver.
- The sheet shades the ring with #e8b26f on its lit faces and the handle with #40231e on its shaded
  ones; the model paints one colour per material and leaves the shade to the renderer's ramps.
- The handle's slight swelling under the ferrule is simplified to a straight taper.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75`, aspect drift <= 0.08, elevation 0):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| **p1 v1 = p2** | **0.901 / 0.007** | **0.923 / 0.005** | **0.911 / 0.003** | 0.895 / 0.162 (waived) | |

Look, splats albedo (`lookdev/loupe.bin`, spacing 0.028 = the scene's 0.032 at scale 1.15; `--min-iou
0.7`, aspect drift <= 0.08, colour drift <= 0.25): IoU 0.806 / 0.861 / 0.801 / 0.755, aspect drift
0.035 / 0.069 / 0.069 / 0.632 (waived), colour drift 0.09 / 0.11 / 0.10 / 0.14.

**Waiver, top view** (aspect drift 0.162 mesh, 0.632 splats): the sheet's top view disagrees with its
side views (scale, knob depth, above), and the renderer draws the "top" from 85 degrees (its
`pitchMax`), so the 1.3 m tall upright loupe shows a sliver of its front and doubles the thin bar's
depth. Front and right lead.

The splat front view's inner opening is smaller than the sheet's (green ring in the compare sheet):
negative space closes by about two splat radii, as expected; the scene bakes the loupe at 1.15.

`hedra inspect check`: ngons on the caps (harmless, triangulated on export); open edges where the
caps buried in the ferrule and handle were deleted on purpose.

Goldens: `goldens/loupe` (framed), `goldens/loupe@scene` (`--texel 0.0272` = the scene's 0.03125 at
scale 1.15, `--size 140`), lit like the scene (`--arg sunYaw=-55 --arg sunPitch=48 --arg keyLight=0.42
--arg highlight=0.85 --arg shadeSteps=1`, `--real-sky`). The sheet is not reviewed by a person yet
(`art/loupe/sheet.v1.png.json`, `reviewed: false`).
