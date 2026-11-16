# Asset: well (hero prop)
Concept: ../../art/well/sheet.v2.png (approved; v1 was painted in Endesga 32 before the palette
became Fading 16), refs cut to ../../art/well/refs.v2/ (v1's to refs/)
Scale: the ring is 1.2 m across = 337 px in the front panel -> 281 px/m on the sheet.
Up Z, facing -Y (hedra front view looks along +Y). Origin at the ground, centre of the ring.

## Parts (metres, measured on the sheet)
| Part | Size | Position | Material (ramp, base step) |
|---|---|---|---|
| Ring | 8 sides, 1.20 across, 0.52 tall, wall 0.13, flat face to the front | z 0..0.52 | Stone (stone, #5a6988) |
| Moss | 3 of the 8 rim faces | rim, front-left, back-right, right | Moss (grass, #63c74d) |
| Water | disc inside the ring | z 0.30 | Gap (stone, #262b44) |
| Posts x2 | 0.13 x 0.13 x 1.30 | x -0.48 / +0.48, z 0..1.30 | Post (wood, #733e39) |
| Crossbeam | 1.06 x 0.09 x 0.09 | z 1.07 | Beam (wood, #b86f50) |
| Crank | arm 0.04 x 0.04 x 0.22, grip 0.16 x 0.04 x 0.04 | right end, x 0.60..0.76 | Beam |
| Rope | radius 0.02, z 0.75..1.03 | centre | Rope (wood, #ead4aa) |
| Bucket | 8 sides, r 0.12 bottom, 0.16 top, 0.22 tall | z 0.52..0.74 | Beam |
| Roof x2 | slabs 1.41 x 0.62 x 0.05, pitch 40 deg | ridge z 1.69 along X, eaves z 1.22 | Roof (red, tile texture) |
| Ridge cap | 1.45 x 0.08 x 0.06 | z 1.70 | Post |

## Proportions the views agree on
- Front: whole width / height = 0.90 (aspect 1.110); right: 0.67 (aspect 1.49).
- Roof is 1.18x the ring's width; eaves at 0.72 of the height.

## Palette and textures
Ramps from art/palette.json (Fading 16). The roof tiles are a 20 x 8 texture of two
reds (#774251, #9c524e), 4 x 4 texel tiles, rows offset by half a tile: each tile is
~0.28 m, about 2-3 splats across at the scene's spacing.

## Assumptions (the sheet does not show)
- The ring's inside is a dark water disc at 0.30.
- The roof's rafter brackets are left out (smaller than a splat at scene scale).

## Budgets
<= 800 triangles, <= 14 objects, 8 materials, 1 texture.

## Gate record
- Form (hedra mesh, `golden.py views --hedra --elevation 7`): IoU 0.81 / 0.77 / 0.77 / 0.79, aspect drift <= 0.05.
  The sheet's side views are drawn from ~7 degrees above (its ring tops show): goldens use `--elevation 7`.
- Look (splats, albedo): IoU >= 0.72, aspect drift <= 0.05, colour drift 0.14 / 0.32 / 0.15 / 0.18.
  Waiver, right view colour: the sheet draws the post 0.17 wide and the roof's underside brown
  there, and contradicts its own front and top views; the model follows front, back and top.
- Fixes the gates asked for: roof slabs tilted the wrong way (right-view X shape), model 8 % too
  tall (the rim top was counted in the ring height), roof UVs left on the cube cross on one slab
  (edit mode acts on the active object only), crank thinner than a splat (thickened to 0.07),
  ridge in dark wood where the sheet has it red.

## Gate record, sheet v2 (Fading 16)
- Palette change: against the v1 sheet (Endesga 32 colours) the albedo colour drift jumped to
  0.36-0.54: its colours snap to the wrong 16-colour ramps. The sheet was regenerated in the final
  palette (sheet.v2), and the colour gate means something again.
- Form, hedra `--elevation 7` vs refs.v2: IoU 0.82 / 0.80 / 0.81 / 0.76, aspect drift <= 0.06 after one
  change the v2 top view asked for (roof slabs 0.64 -> 0.74 m down the slope).
- Look, splats albedo: IoU 0.77 / 0.77 / 0.77 / 0.78, colour drift 0.18 / 0.41 / 0.20 / 0.23.
  Waiver, right colour: v2 repeats v1's fat brown post and roof underside in that view only.
