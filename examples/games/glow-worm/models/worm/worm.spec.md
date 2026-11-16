# Asset: worm (hero, the player character; game-driven)
Concept: ../../art/worm/sheet.v1.png (Cold Light colours), refs cut to ../../art/worm/refs/ (no flips:
the sheet follows the brief: the right view's head points left, the top view's head is at the bottom).
Up Z, facing -Y (the head at -Y, the tail at +Y); origin on the ground under the head's centre.
Scale off the FRONT panel: head 207 px for 0.48 m -> 431 px per metre; the RIGHT panel agrees (head
170 px tall = 0.39 m against 162 px from the front).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Head | faceted ellipsoid (uv-sphere 10 x 7) 0.48 wide, 0.358 long, 0.394 tall | centre (0, 0, 0.2) | Glow (glow, pale #b2d5d1); faces whose normal points down (z < -0.55): Band (glow, slate #444d84) |
| Eyes | 8-sided discs r 0.064, 0.06 deep | (+-0.128, -0.15, 0.232), on the head's front | Eye (dim, dark #08001f) |
| Mouth | box 0.12 x 0.045 x 0.036 | (0, -0.162, 0.116) | Eye |
| Feelers | stalks 0.07 square from (+-0.10, 0, 0.37) to (+-0.162, -0.12, 0.53) | top of the head, leaning forward and out | Band |
| Feeler balls | icospheres r 0.066 | (+-0.162, -0.12, 0.53) | Glow |
| Beads (4) | 8-sided barrels: w x h x l 0.41 x 0.39 x 0.30, 0.36 x 0.36 x 0.27, 0.30 x 0.31 x 0.233, 0.235 x 0.255 x 0.19 | centres y 0.329, 0.614, 0.866, 1.077; z 0.194, 0.19, 0.183, 0.178 | five rings each, front to back: chamfer (0.17 l, r x 0.7 to 1), Glow (0.21 l), band ring Band (0.24 l), Glow (0.21 l), chamfer; undersides (normal z < -0.6) Band |

`make_worm.py` writes the phases from these numbers:
- `p1_blockout.txt`: every part at the spec's size (the feeler rotations are computed).
- `p2_form.txt`: deletes the ring caps hidden inside the beads, joins each bead's rings and welds them
  (`merge --by-distance`), joins the head's parts, then paints by geometry, exports `worm.glb`. The
  gated mesh.
- `p3_splat_fit.txt`: fits the mesh to the splats (below). The bench and the scene bake this.
- `p4_parts.txt` (run with `--no-save`): the game's parts, `head.glb` (the head on a stippled pool of
  light r 0.56) and `bead.glb` (the first, largest bead on a pool r 0.40). Each has its origin on the
  floor under its centre (the pivot `api.place` puts), moved to the world origin. The game scales the
  bead down for the tail.

## Assumptions
- The sheet's panels disagree on scale. The TOP panel is drawn smaller and shorter for its width:
  1.29 m long against the RIGHT panel's 1.48 m for the same head width. The front and right panels
  lead for sizes. The length is the compromise both aspect gates accept: the RIGHT panel's lengths
  x 0.93, 1.357 m in all.
- The BACK panel is drawn from about 7 degrees above: the tail beads hang below the head, which a level
  view of beads on a common axis cannot show. Measured from the drop (0.14 m over 1.08 m of depth).
  The back view is gated at `--elevation 7`, the others at 0.
- Join in hedra keeps each part's material slots, so a material on two parts became two glTF
  primitives (and false "specks" warnings in the bake). `p2_form.txt` joins first and paints after,
  by geometry: the band ring is the faces at local y 0 of each bead, the eyes and mouth the islands
  in front of the head's surface (`pos.y < -0.172`, then `select linked`), the stalks and balls
  islands picked by height.
- With three colours, the colour drift measures little (modeling.md, "6 colours or fewer"). It is
  recorded, and the silhouette and the eye lead.
- The worm is unlit in the scene (it glows): the light inputs of the goldens do not matter.

## Gate record (generated-sheet tier, chosen before the build)
Form: IoU >= 0.75, drift <= 0.08. Splats: IoU >= 0.70, drift <= 0.08, colour drift <= 0.25.

Form, hedra views vs refs (`golden.py views --hedra`, back at `--elevation 7`; iou / aspect drift):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.894 / 0.017 | 0.908 / 0.049 | 0.797 / **0.124** (elev 0) | 0.882 / **0.084** | back drawn from above; the 10-sided head only 0.468 wide |
| p1 v2 | 0.901 / 0.011 | 0.908 / 0.049 | 0.895 / 0.006 | 0.879 / 0.056 | head scale 0.492 (faceted width 0.48); back gated at elevation 7 |
| **p2** | **0.875 / 0.011** | **0.895 / 0.072** | **0.863 / 0.014** | **0.875 / 0.056** | materials; eyes r 0.064, feeler balls r 0.066 (specks at r 0.056 / 0.05); beads welded |

Splats, albedo (`lookdev/worm.bin`, `--look albedo`; iou / aspect drift / colour drift):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p2 at spacing 0.05 | 0.845 / 0.022 / 0.12 | 0.873 / **0.200** / 0.01 | 0.849 / 0.017 / 0.04 | 0.901 / 0.002 / 0.01 | splats grow a radius past every edge: the long, low worm reads stubby from the side |
| p3 v1, spacing 0.045 (the scene's) | 0.817 / **0.082** / 0.12 | 0.879 / 0.069 / 0.02 | 0.873 / 0.014 / 0.05 | 0.910 / 0.038 / 0.01 | feeler tips 3 cm lower, body x 1.045 along its length |
| **p3 v2** | **0.840 / 0.034 / 0.12** | **0.871 / 0.044 / 0.02** | **0.853 / 0.019 / 0.05** | **0.898 / 0.056 / 0.01** | feeler tips 2 cm lower, body x 1.06 |

The p3 mesh itself, for the record (it is fitted to the splats, not gated as a mesh): 0.890 / 0.022,
0.896 / 0.021, 0.888 / 0.002, 0.871 / 0.115. Its top aspect fails the mesh tier, as a splat fit is
expected to (modeling.md, "When the mesh gate and the splat gate disagree").

Waivers: none. The back view's elevation is an assumption measured off the sheet (above), not a
loosened gate.

`hedra model worm.rmdl inspect check`: ngons only, on the eye discs, the mouth and the ring chamfer
caps (harmless, triangulated on export). 620 triangles.

Goldens: `goldens/worm` (framed) and `goldens/worm@scene` (`--texel 0.0456 --size 120`, the scene's
texel), `--real-sky`. The Codex sheet is not reviewed by a person yet (`art/worm/sheet.v1.png.json`,
`reviewed: false`).
