# Asset: lantern (hero prop, the thing you click)
Concept: ../../art/lantern/sheet.v1.png (Midnight Ablaze colours), refs cut to ../../art/lantern/refs/.
Up Z, facing -Y (symmetric); origin on the ground line under the fuel block. Total height 0.856 m on the
sheet (0.916 m modelled: the apex is raised, below).

Scale: the roof's 0.50 m width is 284 px in the front panel (568 px a metre). The three side views are
identical (a square lantern) and straight orthographic: gate at elevation 0.

## Parts (metres)
| Part | Size | Position (z) | Material (ramp, step) |
|---|---|---|---|
| Fuel block | 0.085 cube | 0..0.085 | Fuel (glow, #ff8274; the dark pool bakes it 2 steps down, #7c183c) |
| Bottom ring | 0.40 x 0.40 x 0.044 | 0.146..0.19 | Frame (paper, #31051e) |
| Paper body | square frustum 0.38 -> 0.50 wide, 0.53 tall | 0.19..0.72 | Paper (paper, #7c183c) |
| Band | 0.08 tall (sheet 0.06: exaggerated), 1 cm proud | 0.555..0.635 | Frame |
| Ribs | 4 x 0.05 square, along the corners, outer faces on the corner lines | 0.19..0.72 | Frame |
| Roof | 4-sided pyramid 0.50 wide, 0.134 tall + 0.06 apex extension | 0.72..0.914 | Paper |

## Assumptions
- The two wires (2 cm) are below the splat size: dropped; the fuel block hangs free 6 cm below the ring.
- Phase 3 (`p3_bake.txt`): splats spread about one radius past every edge, so the baked lantern came out
  15 % too wide (aspect drift 0.13-0.16). The bake uses `lantern_bake.glb`, narrowed 0.88 in X and Y;
  `lantern.glb` stays the form-gated model. The apex is raised one splat spacing (tips erode).
- Phase 4 (`p4_lit.txt`): `lantern_lit.glb`, the same solid repainted in the glow ramp (paper #ff8274,
  frame #d53c6a), baked unlit as the lit pool. A material `step` offset on the dark model would have
  snapped the frame into a ramp that does not hold its colour (colour error 0.19).
- 102 triangles.

## Gate record (generated-sheet tier, chosen before the build)
- p1 blockout: IoU 0.978 / 0.979 / 0.983 / 1.000, aspect drift <= 0.005.
- p2 form v1 (ribs centred on the corners): aspect drift 0.083-0.089 (fail: ribs widen it); v2 ribs inset,
  apex raised 0.06: **IoU 0.934 / 0.937 / 0.935 / 0.975, aspect drift 0.060 / 0.056 / 0.064 / 0.003**
  (`--min-iou 0.75`, drift <= 0.08).
- p4 splats, albedo, bench at the scene's scale (1.4) and spacing (0.09): v1 `lantern.glb` aspect drift
  0.146 / 0.158 / 0.143 (fail, fattened); v2 apex raised, fuel at 0.04: 0.134 / 0.107 / 0.094 (fail);
  bake prep narrowed 0.82: drift <= 0.061, IoU 0.84; 0.78: drift <= 0.067; **0.88: IoU 0.904 / 0.844 /
  0.877 / 0.863, aspect drift 0.041 / 0.022 / 0.011 / 0.005, colour drift 0.02 / 0.01 / 0.01 / 0.12**
  (`--min-iou 0.7`): kept. With 7 colours the colour drift says little (modeling.md). No waivers.
- Goldens: `goldens/lantern` (framed), `goldens/lantern@scene` (texel 0.084, 160 px), lit as the scene.
