# Asset: penguin (hero, game-driven)
Concept: ../../art/penguin/sheet.v2.png (Mist GB colours), refs cut to ../../art/penguin/refs/ (no flips:
the sheet follows the brief's orientation line). Sheet v1 failed `sheet_cut.py`: the beak touched the
RIGHT panel's edge and the feet the TOP panel's (cropped); v2 restated a wide margin first.
Up Z, facing -Y (the head); origin on the ground under the body's centre. 0.81 m beak tip to feet.
Scale from the RIGHT panel (it leads: the game shows the right side): 471 px = 0.80 m -> 589 px/m.

## Parts (metres)
| Part | Size | Position (centre) | Material (ramp, step) |
|---|---|---|---|
| Body | 8-sided egg 0.36 x 0.68 x 0.26 | (0, 0.04, 0.13) | Feather (feather, #2d1b00); faces under z 0.07 Belly |
| Head | 8-sided egg 0.31 x 0.26 x 0.27, top 0.35 | (0, -0.2, 0.215) | Feather; the face patch (front faces, z 0.12-0.29) Belly (belly, #c4f0c2) |
| Beak | 4-sided cone r 0.05, 0.12 long, to -Y | (0, -0.365, 0.19) | Beak (glint, #5ab9a8) |
| Eyes | 0.045 x 0.03 x 0.06 each | (+-0.075, -0.318, 0.24) | Eye (feather, specks) |
| Flippers | 0.1 x 0.3 x 0.06, rolled +-36, swept +-15 | (+-0.175, 0.07, 0.105) | Flipper (feather; its own material, baked at 0.025) |
| Feet | 0.075 x 0.09 x 0.045 each | (+-0.06, 0.36, 0.045) | Beak (glint) |
| Scarf | torus R 0.13, r 0.035, round the neck; an end 0.075 x 0.22 x 0.035 over the LEFT (+X) shoulder | (0, -0.09, 0.165), end (0.1, 0.05, 0.235) | Scarf (water, #1e606e) |

`p1_blockout.txt` (primitives), `p2_form.txt` (materials, face patch, eyes, one joined mesh, `penguin.glb`).

## Assumptions
- The sheet contradicts itself on the width: front aspect 0.644, back 0.697 (the same object), and the
  top view's length/width (1.645) does not fit the right view's length/height (0.437) with either.
  A flipper span of 0.64 x the length is the only one inside 0.08 drift for the front, right and top
  together; the back is left at 0.07.
- The beak is 0.02 m longer than drawn and the flippers thicker (0.06): tips erode under the splats.
- The front view's face patch and eyes are simplified: the game only shows the right side.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`, elevation 0):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.825 / 0.024 | 0.824 / 0.077 | 0.837 / 0.055 | 0.830 / 0.148 | flippers spread too wide, scarf end standing up |
| p1 v2 | 0.804 / 0.118 | 0.837 / 0.077 | 0.828 / 0.032 | 0.871 / 0.069 | narrower span; the neck ring stood above the head |
| p1 v3 | 0.831 / 0.029 | 0.875 / 0.009 | 0.848 / 0.051 | 0.865 / 0.069 | neck ring smaller |
| **p2 (final)** | **0.852 / 0.007** | **0.849 / 0.030** | **0.856 / 0.071** | **0.857 / 0.069** | thicker flippers swept 15 deg, beak 0.12 |

Look, splats albedo (`lookdev/penguin.bin`, spacing 0.04, flippers and beak 0.025, eyes 0.02;
`--min-iou 0.7 --max-aspect-drift 0.08`): IoU 0.814 / 0.846 / 0.811 / 0.885, aspect drift
0.036 / 0.008 / 0.062 / 0.066, colour drift 0.09 / 0.01 / 0.05 / 0.03 (front, right, back, top).
Earlier bakes at 0.05 failed the back and right aspect (0.103-0.132): the thin flippers eroded; the
finer per-material spacing fixed it.

`hedra inspect check`: 0 findings.

Goldens: `goldens/penguin` (framed), `goldens/penguin@scene` (`--texel 0.0256`: the scene's 0.032 m
texel over the bake scale 1.25), lit like the scene (`--arg sunYaw=-35 sunPitch=45 keyLight=0.45
highlight=0.85 shadeSteps=1 bandDither=0.4`, `--real-sky`).
