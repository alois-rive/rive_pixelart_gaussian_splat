# Asset: duck (hero, the player's turret)

Concept: `../../art/duck/sheet.v2.png` (v1 listed one colour per material; v2 lists each material's ramp
steps, as the brief template asks), refs cut to `../../art/duck/refs/`. Up Z, facing -Y; origin on the
ground under the body's centre. Built by `make_duck.py`, which writes `p1_blockout.txt` and `p2_form.txt`.

Scale: the right panel's length, beak tip to tail tip, 512 px = 0.8 m (640 px a metre). Height 0.72 m.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Body | uv-sphere 10 x 6, semi-axes 0.26 x 0.35 x 0.2 | centre (0, 0.01, 0.19) | Body (duck, #b3a555, step 2) |
| Head | uv-sphere 10 x 6, r 0.2 | (0, -0.125, 0.53) | Body |
| Beak | 0.25 x 0.16 x 0.08, its front face 0.8 x 0.7 | (0, -0.37, 0.47) | Beak (beak, #c77b58, step 3) |
| Eyes | uv-spheres r 0.05, flattened 0.6 across | (+-0.15, -0.22, 0.58) | Eye (ink, #4b3d44), spacing 0.025, specks |
| Wings | uv-spheres, semi-axes 0.07 x 0.17 x 0.08, turned 8 degrees | (+-0.29, 0.06, 0.25) | Body |
| Tail | 4-sided cone r 0.13 x 0.26, tipped 50 degrees back | (0, 0.3, 0.33) | Body |

## Assumptions
- The palette's ramps were written for the duck: its shade step is the ochre #927441 (even luma steps
  0.27 / 0.47 / 0.63 / 0.78); the olive #77743b went to a `sponge` ramp.
- **Colour-drift waiver (all four views).** The sheet's soft shading spreads the duck's yellow over
  Lost Century's neighbouring ochres, which belong to the wood ramp only (#ba9158, #d1b187, and #927441
  that wood shares): 40-55 % of the concept's pixels. The albedo render paints every body splat on its
  base step, so the drift reads 0.33-0.50 for a model whose materials are right (body yellow, beak
  orange, eyes dark; checked by eye in `shots/p4_albedo/compare.png`). v2 of the sheet, listing the
  ramp steps, did not move it. IoU and aspect lead.
- 362 triangles.

## Gate record (generated-sheet tier, chosen before the build)
- Against sheet v1: p1 0.847 / 0.827 / 0.843 / 0.772; p4 albedo colour drift 0.32-0.58 (the ochres).
- Against sheet v2: p1 v1 0.868 / 0.782 / 0.866 / 0.790; p2 with the underside deleted: right aspect drift
  0.086 (fail: kept the underside, it is under the water anyway); head raised and wings slimmed: front
  drift 0.095 (fail); wings back to 0.07: **p1 0.858 / 0.778 / 0.858 / 0.776, aspect drift 0.002 / 0.010 /
  0.002 / 0.037; p2 0.858 / 0.776 / 0.858 / 0.778** (`--min-iou 0.75`).
- p4 splats, albedo (bench at 0.055, coarser than the scene's 0.035 in model units): **IoU 0.869 / 0.852 /
  0.889 / 0.793, aspect drift 0.048 / 0.027 / 0.027 / 0.077**, colour drift 0.34 / 0.33 / 0.50 / 0.50
  (waived, above).
- Goldens: `goldens/duck` (framed, lit like the scene), `goldens/duck@scene` (texel 0.05, 120 px).
