# Asset: satellite (hero, the player's orbital cannon; game-driven, no baked animation)
Concept: ../../art/satellite/sheet.v1.png (Berry Nebula colours), refs cut to ../../art/satellite/refs/ (no
flips: the sheet follows the brief's orientation line). Up Z = the barrel, facing -Y; origin at the body's
centre (the pivot the game puts on its orbit and rolls so the barrel points away from the planet).
Scale from the front panel: body 229 px = 0.5 m -> 458 px per metre (all four panels share one scale).

## Parts (metres)
| Part | Size | Position (z from the body centre) | Material (ramp, step) |
|---|---|---|---|
| Body | 0.5 x 0.46 x 0.404, vertical edges chamfered 0.1, top/bottom edges 0.045 | z -0.202..0.202 | Body (metal, #6e5181, step 3) |
| Dome | octagonal frustum r 0.215 -> 0.08, 0.138 tall | z 0.202..0.340 | Dome (metal, #6d85a5, step 4) |
| Barrel | hexagonal tube r 0.055, 0.27 long | z 0.342..0.610 | Dark (metal, #4f1446, step 2) |
| Muzzle | hexagonal ring r 0.07, 0.045 tall | z 0.612..0.656 | Muzzle (glow, #6ceded, unlit) |
| Thruster plate | octagon r 0.165, 0.055 thick | z -0.259..-0.204 | Dark |
| Struts | 0.09 long, 0.085 x 0.085 (sheet: 0.06, thickened) | x +-0.285, z 0.025 | Dark |
| Panels | 0.437 x 0.055 x 0.297 each, in three flush strips: top, stripe (0.06 tall), bottom | x +-0.529, z -0.123..0.174 | Panel (panel, #6cb9c9, step 3), Stripe (panel, #2e0a30, step 0) |

`p1_blockout.txt` (primitives at these sizes), `p2_form.txt` (bevels, materials, join, `satellite.glb`, 252 tris).

## Assumptions
- The sheet's "dome" is drawn as an octagonal frustum, so it is modelled as one (not a half sphere).
- The panel stripe runs horizontally through each wing at the strut's height (the sheet), not dividing the
  wing left and right (the brief); the sheet leads.
- The right view of the sheet shows the near panel's edge in plain cyan (no stripe): the model keeps the
  stripe through the panel's thickness; the colour gate is not affected (0.07).
- Struts thickened from 0.06 to 0.085 (pixel-art exaggeration): at 0.06 they baked to 5-7 splats each.
  They still bake to 9-11 splats each (the bake's specks warning names them): two short connectors
  between body and wings, intended to read as one or two art pixels.

## Gate record (generated-sheet tier, chosen before the build: form IoU >= 0.75, drift <= 0.08;
## splats IoU >= 0.7, drift <= 0.08, colour drift <= 0.25)
Form, hedra views vs refs (no elevation: the sheet's side views show no top faces):

| Iteration | front | right | back | top |
|---|---|---|---|---|
| p1 | 0.981 / 0.002 | 0.956 / 0.000 | 0.963 / 0.005 | 0.920 / 0.039 |
| p2 (struts 0.085) | **0.985 / 0.002** | **0.971 / 0.000** | **0.968 / 0.005** | **0.925 / 0.039** |

Look, splats albedo (`lookdev/satellite.bin`). The bench is baked as the scene bakes it: scale 1.25
(the hero is enlarged in the scene) at spacing 0.07 (0.056 m at model scale):

| Bench | front | right | back | top |
|---|---|---|---|---|
| scale 1, spacing 0.09 (first try) | 0.739 / 0.059 | 0.818 / **0.105** | 0.781 / 0.023 | 0.714 / **0.121** |
| **scale 1.25, spacing 0.07** | **0.811 / 0.044 / c 0.06** | **0.905 / 0.060 / c 0.07** | **0.818 / 0.047 / c 0.06** | **0.755 / 0.078 / c 0.12** |

(IoU / aspect drift / colour drift.) At 0.09 m the 1.5 m wide satellite got ~290 splats and its thin
wings fattened past the drift tier; the scene therefore shows it 1.25x larger (pixel-art exaggeration) at
0.07 m, ~690 splats.

`hedra inspect check`: ngons on the cylinder and cone caps (triangulated on export) and 32 duplicate
verts where the flush panel strips touch (separate shells, harmless for splats).

Goldens: `goldens/satellite` (framed) and `goldens/satellite@scene` (`--texel 0.06 --size 160`), lit like
the scene (`--arg sunYaw=-50 sunPitch=35 keyLight=0.45 highlight=0.8 shadeSteps=2 shadows=0`, `--real-sky`).
