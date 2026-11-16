# Asset: barn (hero prop)
Concept: ../../art/barn/sheet.v1.png (Kirokaze Gameboy colours), refs cut to ../../art/barn/refs/.
Up Z, facing -Y; origin at the ground under the centre. Total height 3.11 m. Generated-sheet tier.

Measured off the FRONT panel: walls 365 px = 3.0 m, so 121.7 px/m; the RIGHT panel agrees (379 vs 371 px tall).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Walls | 3.0 x 3.55 x 1.8 | z 0..1.8 | WallFront/Back/Right/Left (barn, textures), Walls (barn, #46878f) |
| Gable | wedge 3.0 x 3.55, 1.04 tall | z 1.8..2.84, ridge along Y | GableFront (barn, texture), Walls |
| Roof | 2 slabs 2.24 down the slope x 4.0 (3.57 at the ridge) x 0.22, 36.6 deg | ridge z 3.11 | Roof (roof, #332c50) |
| Door (painted) | frame 2.0 x 1.7, leaves 1.6 x 1.5, stile 0.2 | front, centred | wall_front.png: #e2f3e4 / #332c50 |
| Loft door, windows (painted) | 0.8 square, 0.2 frame | front gable 2.2 m; back 1.3 m; right 1.1 m | #e2f3e4 / #332c50 |
| Corner boards (painted) | 0.2 wide | every wall edge | #e2f3e4 |

Textures: `textures/make_textures.py` (palette-exact, 0.1 m a texel = the scene's texel, every shape
>= 2 texels; `palette.py audit`: 2-3 colours, 0 % lone texels).

## Assumptions and exaggerations
- The sheet's RIGHT view draws the roof as a trapezoid (3.57 m at the ridge, 4.0 at the eave); its TOP
  view is a plain rectangle. Front and top lead; the ridge end is narrowed anyway (it costs nothing).
- Eaves 0.3 m past the walls (sheet 0.2) and roof slabs 0.22 thick (sheet 0.16): the splats ate the
  pointed eave tips and the splat front view came out 10 % too tall for its width (aspect drift 0.10).
- Door X braces dropped, windows and loft door 0.8 m (sheet 0.62): at 0.1 m a texel a brace is one
  pixel, and modelled 3 cm proud of the wall the frame, leaves and braces fought at splat size (one
  depth a disc) and smeared the door into white noise at the scene's angle. Painted, they read.

## Gate record (generated-sheet tier: form IoU >= 0.75, aspect drift <= 0.08; splats IoU >= 0.7)
| Iteration | Gate said | Change |
|---|---|---|
| p1 v1 | IoU 0.96 / 0.98 / 0.96 / 0.95, drift <= 0.05 | - |
| p4 v1 (splats, 0.11 spacing) | front aspect drift 0.108, back 0.103 (model taller than wide) | slabs 0.16 -> 0.22: drift 0.100 |
| p4 v2 | front drift 0.100 | eaves 0.2 -> 0.3 past the walls: drift 0.039 |
| lit, scene texel | door a white smear | details painted into wall textures (above) |

Final (models/barn/shots/p1, p2, p4_albedo):
- Form, hedra views (`--elevation 0`, the sheet has no visible top): IoU 0.943 / 0.987 / 0.950 / 0.952,
  aspect drift 0.053 / 0.020 / 0.051 / 0.009.
- Splats, albedo, 0.12 m spacing (the scene's): IoU 0.937 / 0.958 / 0.950 / 0.924, aspect drift
  0.039 / 0.079 / 0.041 / 0.017, colour drift 0.03 / 0.01 / 0.03 / 0.00. No waivers.
- Bake: colour error 0.000 on every material, no specks warning. Goldens: goldens/barn (framed) and
  goldens/barn@scene (texel 0.1, pixel 4), both with the scene's look args (README).
- The sheet's record (`sheet.v1.png.json`) keeps `reviewed: false`: no person has approved it yet.
