# Asset: manor (hero, the human hall)
Concept: ../../art/manor/sheet.v1.png (Lospec500 colours, `reviewed: false`), refs cut to ../../art/manor/refs/.
Up Z, facing -Y (the door); origin on the ground under the plinth's centre. 2.40 x 2.00 m plinth, flag tip 2.44 m.
In the game it is one rigid game bone (`manor`), turned 35 degrees so the camera sees its door and its
left side (the isometric read): the rising-in-steps, hit squash and collapse are `place` / `placeScaled`
in `scene/game.as`.

Scale: the front panel at 184 px a metre (plinth 442 px = 2.40 m); the top panel agrees (445 px = 2.42 m).
The views are straight orthographic: gate at elevation 0.

## Parts (metres)
| Part | Size | Position (centre) | Material (ramp, step) |
|---|---|---|---|
| Plinth | 2.40 x 2.00 x 0.27 | (0, 0, 0.135) | Stone (stone, #8c78a5) |
| Walls | 2.00 x 1.30 x 0.77, timber frame inset 0.10 round plaster panels | (-0.08, 0, 0.655) | Timber (wood, #6e4c30), Plaster (cream, #e8d282) |
| Roof | 2.24 x 1.54, eaves 1.04, ridge 1.73 along X; -X end hipped 0.29, +X end a plaster gable | (-0.08, 0, 1.385) | Roof (royal, #3859b3) |
| Door | 0.52 x 0.06 x 0.53 | (-0.265, -0.67, 0.535) | Door (wood, #a26d3f) |
| Door canopy | 0.57 x 0.34 x 0.18 gable, ridge along Y | (-0.265, -0.78, 0.89) | Roof |
| Window slits | 0.14 x 0.04 x 0.22, 2 cm proud | (-0.76 / 0.19, -0.665, 0.625) | Dark (stone, #2c1e31), `specks` |
| Tower shaft | 0.68 x 0.68 x 1.28 | (0.78, -0.40, 0.91) | Stone |
| Battlement ring + 8 merlons | 0.80 x 0.80 x 0.17; merlons 0.15 x 0.15 x 0.12 | ring at 1.635, merlons at 1.78 | Stone |
| Tower roof | 4-sided pyramid, base half-width 0.31, 0.46 tall | (0.78, -0.40, 1.72..2.18) | Roof |
| Pole, banner | 0.07 x 0.07 x 0.34; 0.34 x 0.05 x 0.19 to +X | (0.78, -0.40, 2.27); (0.985, -0.40, 2.335) | Timber; Banner (royal, #3388de) |

## Assumptions
- Front and top lead. The RIGHT panel draws the house's gable about 0.3 m further back than the top
  panel puts it, and the BACK and RIGHT panels flip the banner the other way (it points to the image's
  right in every panel, which a turned object cannot do): the banner follows the front and top views.
- The front panel's slanted left roof edge is a hip; the right panel's cream triangle is a gable: the roof
  is hipped at -X and gabled at +X.
- The sheet's plinth brick joints and the 3-per-side merlon gaps are smaller than two splats at the
  scene's spacing: the joints are dropped, the merlons kept (their gaps close up in the scene).
- 244 triangles (exported). `inspect check` reports non-manifold edges only round faces deleted on
  purpose (bottoms on the ground, the walls' top under the roof).

## Gate record (generated-sheet tier, chosen before the build: IoU >= 0.75 mesh / 0.70 splats, drift <= 0.08,
colour drift <= 0.25)
- p1 blockout: **IoU 0.978 / 0.781 / 0.941 / 0.981, aspect drift 0.008 / 0.009 / 0.012 / 0.023** (front, right,
  back, top): pass.
- p2 form (timber frames inset, gable plaster, windows, materials): **IoU 0.978 / 0.781 / 0.941 / 0.981, aspect
  drift 0.008 / 0.009 / 0.012 / 0.023**: pass (the silhouette did not change).
- p4 splats, albedo (spacing 0.07, timber and door 0.05: as baked in the scene): **IoU 0.912 / 0.787 / 0.908 /
  0.950, aspect drift 0.002 / 0.010 / 0.040 / 0.032, colour drift 0.12 / 0.18 / 0.14 / 0.21** (`--min-iou 0.7`):
  pass. No waiver was needed; the right view is the lowest for the sheet's own disagreement above.
- Goldens: `goldens/manor` (framed) and `goldens/manor@scene` (texel 0.06, 200 px), lit as the scene (sun yaw
  -40, pitch 50).
