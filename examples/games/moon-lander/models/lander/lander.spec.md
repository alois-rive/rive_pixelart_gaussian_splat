# Asset: lander (hero, game-driven)
Concept: ../../art/lander/sheet.v1.png (Nyx8 colours), refs cut to ../../art/lander/refs/ (no flips).
Up Z, facing -Y; origin on the ground under the descent stage. Total height 2.0 m. Scale from the
front panel: 478 px = 2.0 m -> 239 px per metre. The lander's own right is -X (the dish side).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Descent stage | octagon 1.4 across its flats, 0.46 tall | z 0.5..0.96 | Foil (foil, #997577) |
| Cabin | box 1.04 x 1.1 x 0.46 | z 0.96..1.42 | Cabin (cabin, #c3a38a) |
| Roof | frustum 1.04 x 1.1 -> 0.76 x 0.82, 0.23 tall | z 1.42..1.65 | Cabin |
| Window | triangle r 0.27, 0.06 proud of the front | centre z 1.33 | Glass (glass, #0f2a3f) |
| Hatch | 0.2 x 0.06 x 0.17 | z 1.07, front | Hatch (foil, spacing 0.06) |
| Nozzle | 8-sided bell r 0.23 -> 0.15, 0.33 tall | z 0.17..0.5 | Metal (metal, #4e495f) |
| Legs (4) | struts 0.13 square from (+-0.52, +-0.52, 0.66) to the pads | diagonal corners | Metal |
| Pads (4) | 8-gon r 0.17 x 0.06 | (+-0.88, +-0.88, 0.03) | Metal |
| Mast, dish | r 0.07 x 0.22; cone r 0.07 -> 0.2 x 0.13 tilted 18 degrees out | (-0.35, 0.1, 1.62..1.98) | Metal; Pale (cabin, #f6d6bd) |

`make_p1.py` writes `p1_blockout.txt` (the leg struts' rotations are computed), `p2_form.txt` adds the
materials, window, hatch and the export.

## Assumptions
- The sheet's top view puts the pads at +-0.77 m, its front view at +-0.87 m: the pads sit at +-0.88
  (front, right and back lead; the scene only ever sees the lander side on).
- The top view's descent stage is shallower than the right view's: the right view leads.

## Gate record (generated-sheet tier: form IoU >= 0.75, splat IoU >= 0.70, drift <= 0.08, colour <= 0.25)
| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.851 / 0.086 | 0.838 / 0.117 | 0.865 / 0.084 | 0.920 / 0.020 | fails: the pads too close in (too narrow) |
| **p1 v2 = p2** | **0.900 / 0.004** | **0.889 / 0.010** | **0.893 / 0.002** | **0.837 / 0.040** | pads out to +-0.88 |

Splats albedo (`lookdev/lander.bin`, spacing 0.1): IoU 0.758 / 0.777 / 0.769 / 0.816, aspect drift 0.041
/ 0.055 / 0.032 / 0.026, colour drift 0.10 / 0.08 / 0.07 / 0.15. The mast (r 0.05) and the hatch baked as
specks at first: the mast went to r 0.07, the hatch got its own material at spacing 0.06.

Goldens: `goldens/lander` (framed) and `goldens/lander@scene` (`--texel 0.068 --size 120`), lit like the
scene (`--arg sunYaw=62 sunPitch=24 keyLight=0.4 highlight=0.85 shadeSteps=2 bandDither=0.4`,
`--real-sky`). The sheet is not reviewed by a person yet (`reviewed: false`).
