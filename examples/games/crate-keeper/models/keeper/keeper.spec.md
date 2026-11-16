# Asset: keeper (hero, Tansy the greenhouse keeper; one game bone)
Concept: ../../art/keeper/sheet.v1.png (Fairydust 8 colours), refs cut to ../../art/keeper/refs/ (no flips:
the sheet follows the brief's orientation line: the right view faces left, the top view has the front at
the bottom; the watering can is in the character's LEFT hand in every view). Up Z, facing -Y (the GLB
faces +Z, the game turns it to each step), origin on the ground under the body's centre. Total height
0.85 m to the leaf's tip. Shown at 1.3x in the scene (pixel-art exaggeration on a 1 m grid).
Scale from the front panel: the whole figure, 476 px = 0.85 m -> 560 px per metre (the right and back
panels agree: 476 px tall each).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Boots | 2 blocks 0.13 x 0.2 x 0.1, toes forward | x +-0.085, y -0.02, z 0..0.1 | Boots (cloth, #6461c2, step 1) |
| Body | a low-poly sphere (8 x 6) squashed to 0.5 x 0.4 x 0.36, the bib's front faces pushed out 0.02 | centre z 0.26 | Overalls (cloth, #2ba9b4, step 2) |
| Head | sphere (8 x 6) 0.34 x 0.31 x 0.31 | centre (0, -0.01, 0.5) | Skin (skin, #e39aac, step 2) |
| Nose | ico-sphere r 0.05 | (0, -0.175, 0.49) | Skin |
| Eyes | 2 cubes 0.04 (one art pixel each in the game: specks on purpose) | (+-0.06, -0.15, 0.535) | Eye (skin, #634b7d, step 0) |
| Brim | a 12-sided cone frustum r 0.315 -> 0.135, 0.1 tall (a sloped brim) | z 0.525..0.625 | Hat (straw, #f0dab1, step 2) |
| Crown | 10-sided frustum r 0.14 -> 0.118, 0.13 tall | z 0.61..0.74 | Hat |
| Ribbon | 10-sided cylinder r 0.144, 0.045 tall | z 0.645 | Ribbon (wood, #c45d9f, step 1) |
| Leaf sprout | ico-sphere r 0.055 scaled 1 x 0.45 x 1.3, a stem r 0.028 x 0.06 | top at z 0.85 | Leaf (leaf, #93d4b5, step 3) |
| Arms | 6-sided cylinders r 0.06 x 0.2, tilted 12 degrees out | x +-0.215, z 0.29 | Skin |
| Hands | ico-spheres r 0.065 | (+-0.24, -0.02, 0.175) | Skin |
| Watering can | body 0.11 x 0.15 x 0.12, grip 0.04 x 0.11 x 0.05, spout r 0.022 x 0.13 tilted 60 degrees forward | in the LEFT hand: x 0.285 | Leaf |

`p1_blockout.txt` (primitives at these sizes), `p2_form.txt` (materials, eyes, the bib, joins per material,
flat shading, `keeper.glb`), `p3_splat_fit.txt` (splat fit, below; writes `keeper_fit.rmdl` and the
`keeper.glb` that is baked). 516 triangles.

## Assumptions
- The sheet's top view contradicts its front view: the front view hangs the watering can outside the brim
  (its far edge 0.34 m from the centre, the brim 0.31), the top view tucks it under the brim and shows the
  hands and spout ahead of it instead. Front, right and back lead (the game's camera, 42 degrees down,
  sees the hat, the front and the can); the top view's aspect gets a waiver (below).
- The sheet's right view draws the brim tilted (a few degrees of perspective: it is wider on the right).
  The brim is modelled flat-round (0.63 across, as the front and top views agree).
- The sheet paints the body's shade side violet (#6461c2): that is light, not material; the overalls are
  one teal material and the renderer shades them down the cloth ramp.
- The leaf's stem is mostly hidden under the leaf: it bakes to about 10 splats (the "specks" warning names
  Greens); it reads as part of the leaf, kept.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75`, aspect drift <= 0.08):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.741 / 0.094 | 0.818 / 0.009 | 0.736 / 0.148 | 0.843 / 0.200 | arms and can too far out, brim too thin and flat, leaf small |
| p1 v2 | 0.795 / 0.007 | 0.824 / 0.031 | 0.794 / 0.055 | 0.902 / **0.095** | arms in to 0.215, can to 0.285, sloped 0.1 m brim, bigger leaf |
| **p2 (final, stem r 0.028)** | **0.795 / 0.007** | **0.819 / 0.031** | **0.794 / 0.055** | 0.902 / **0.095** | materials, eyes, bib, joins |

(IoU / aspect drift.)

Look, splats albedo (`lookdev/keeper.bin`, `--min-iou 0.7`, aspect drift <= 0.08):

| Iteration | front | right | back | top |
|---|---|---|---|---|
| v1 (p2 mesh, bench spacing 0.055) | 0.761 / 0.021 / 0.06 | 0.777 / **0.110 FAIL** / 0.08 | 0.769 / 0.053 / 0.08 | 0.871 / 0.055 / 0.04 |
| v2 (p3 splat fit: brim pulled in 9 %) | 0.754 / 0.020 / 0.08 | 0.778 / 0.016 / 0.09 | 0.756 / 0.068 / 0.08 | 0.835 / **0.152** / 0.07 |
| **v3 = final** (the scene's density: spacings / 1.3, stem thickened) | **0.750 / 0.029 / 0.07** | **0.767 / 0.018 / 0.07** | **0.758 / 0.041 / 0.10** | 0.867 / **0.126** / 0.05 |

(IoU / aspect drift / colour drift.) The splat right view failed once (0.110): each disc reaches a radius
past the flat brim, so the brim baked wider than the mesh and the side view squatter; `p3_splat_fit.txt`
only shrinks the hat 9 % across (the gated p2 form stays in `keeper.rmdl`).

**Waiver, top aspect** (form 0.095, splats 0.126): the sheet's top view contradicts its front view (above);
front, right and back lead. Its top IoU is 0.902 (form) and 0.867 (splats).

`hedra inspect check`: ngons on the cylinder and cone caps only (harmless, triangulated on export).

Goldens: `goldens/keeper` (framed), `goldens/keeper@scene` (`--texel 0.0486` = the scene's 0.063 / 1.3,
`--size 120`), lit like the scene (`--arg sunYaw=30 sunPitch=55 keyLight=0.42 highlight=0.85 shadeSteps=1
lightSteps=1 edgeDepth=0.5`, `--real-sky`), views front, right, back, top, iso.

The Codex sheet was not reviewed by a person yet (`art/keeper/sheet.v1.png.json`, `reviewed: false`).
