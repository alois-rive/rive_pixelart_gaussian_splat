# Asset: forge (hero prop, static)
Concept: ../../art/forge/sheet.v1.png (Lava-GB colours), refs cut to ../../art/forge/refs/ (no flips:
the sheet follows the brief's orientation line: right view faces left, top view front at the bottom).
Up Z, facing -Y; origin at the ground under the plinth's centre. Total height 2.9 m.
Scale from the front panel: plinth 395 px = 2.4 m -> 165 px per metre (front, right and back panels
are 480 px tall: one scale).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Plinth | 2.55 x 2.85 x 0.25, top edges chamfered 0.06 | z 0..0.25 | Stone (stone, #4a2480) |
| Furnace | 1.8 x 1.5 x 1.2 | back half, y 0.62 centre, z 0.25..1.45 | Stone |
| Hood | frustum 1.8 x 1.5 -> 0.86 x 0.69, 0.5 tall | z 1.45..1.95 | Stone |
| Chimney | 0.58 x 0.58 x 0.75 | z 1.95..2.7 | Stone |
| Cap | 0.84 x 0.84 x 0.2 | z 2.7..2.9 | Stone |
| Mouth rim | octagon 1.2 x 0.9, 0.08 deep, proud of the furnace face | centre z 0.92 | Rim (ember, #c53a9d, unlit) |
| Fire | octagon 0.98 x 0.74 in front of the rim | centre z 0.9 | Fire (lava, #ff8e80, unlit) |
| Block | 0.7 x 0.47 x 0.22 | y -0.85, z 0.25..0.47 | Stone |
| Anvil | foot 0.6 x 0.36 x 0.1, waist 0.34 x 0.2 x 0.15, face 0.76 x 0.36 x 0.12, horn cone r 0.15 x 0.42 to +X | z 0.47..0.84 | Iron (iron, #051f39) |

`p1_blockout.txt` (primitives), `p2_form.txt` (materials, plinth chamfer, joins: Masonry, Anvil, Rim,
Fire; `forge.glb`). The trip-hammer that strikes the anvil is a separate scene asset
(`models/env/hammer.txt`), so the gated hero stays the sheet's object.

## Assumptions
- The sheet draws the front and right views slightly oblique (a sliver of the plinth's side shows):
  the boxes measured include it, so the plinth is 2.55 wide (not the briefed 2.4) and 2.85 deep, and
  the furnace 1.8 x 1.5. Side views gated at `--elevation 3` (the plinth top's visible depth).
- The sheet's views disagree on depth: the right view's plinth is 2.8-2.9 m deep, the top view's
  2.3 m at the same width. Front, right and back lead (the scene's 30 degree camera sees sides more
  than tops); the top view's aspect gets a waiver (below).

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`, elevation 3):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.914 / drift 0.104 | 0.838 / 0.113 | 0.924 / 0.111 | 0.998 / 0.169 | the sheet's oblique sliver makes it wider than briefed |
| p1 v2 | 0.895 / 0.043 | 0.803 / 0.094 | 0.898 / 0.047 | 0.998 / 0.122 | plinth 2.55 x 2.75; furnace too shallow in the right view |
| **p1 v3 = p2** | **0.929 / 0.040** | **0.921 / 0.056** | **0.940 / 0.050** | 0.998 / **0.163** | plinth 2.85 deep, 0.25 tall; furnace 1.8 x 1.5 |

Look, splats albedo (`lookdev/forge.bin`, spacing 0.09, `--min-iou 0.7 --max-aspect-drift 0.08`):
IoU 0.890 / 0.840 / 0.889 / 0.948, aspect drift 0.050 / 0.056 / 0.048 / 0.174, colour drift
0.03 / 0.03 / 0.03 / 0.04.

Waiver, top aspect (form 0.163, splats 0.174): the sheet contradicts itself (right view 2.9 m deep,
top view 2.3 m); front, right and back lead. Its top IoU is 0.998 / 0.948.

`hedra inspect check`: ngons on the octagon caps (harmless, triangulated on export) and 8
duplicate verts in Masonry where joined boxes touch (separate shells, harmless for splats).

Goldens: `goldens/forge` (framed), `goldens/forge@scene` (`--texel 0.06`), lit like the scene
(`--arg sunYaw=-35 sunPitch=22 keyLight=0.55 highlight=0.8 splatDither=0 bandDither=0.4`, `--real-sky`).
