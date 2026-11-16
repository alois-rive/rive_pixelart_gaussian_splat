# Asset: windmill (hero; hole 1's obstacle: the tower is static, the sails are a game bone)
Concept: ../../art/windmill/sheet.v1.png (Taffy 16 colours), refs cut to ../../art/windmill/refs/
(no flips or rotations: the sheet drew every panel the right way round). Up Z, facing -Y (the sails'
side); origin on the ground under the tower's centre. Scale from the FRONT panel: the tower's base
287 px for 2.2 m -> 130.5 px per metre. The side views are flat elevations (no roof top shows), so
the gates use the default elevation.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Tower | eight-sided frustum, 2.2 across the flats at the ground, 1.92 at the top, 2.02 tall | z 0 .. 2.02, flats facing front and back | Wall (candy, #ff6c7a) |
| Tunnel | a doorway 0.67 wide, 0.67 tall, straight through front to back; a dark liner facing inwards | bottom centre | Dark (pit, #36354d) |
| Band | eight-sided, 2.12 across the corners, 0.24 tall | z 2.02 .. 2.26 | Trim (cloud, #fafffc) |
| Roof | eight-sided cone r 1.12, 0.9 tall | z 2.26 .. 3.16 | Roof (water, #448de7) |
| Finial | icosahedron r 0.14 | z 3.28 | Finial (gold, #ffeb33) |
| Windows | octagonal discs r 0.19, 0.08 thick, standing off the side walls (tilted with them) | x +-1.07, z 1.27 | Dark |
| Hub, axle | cube 0.24; axle r 0.07 | y -1.16 (the sails' plane), z 1.62 | Hub (wood, #f58931) |
| Sails | four spars 0.1 x 0.1 x 1.58 from r 0.1 to 1.68, each with a cloth 0.46 x 1.2 x 0.05 on its counter-clockwise side; a diagonal X | in front of the tower, y -1.16 | Spar (wood, #a63d57), Sail (cloud, #fafffc, two-sided) |

`p1_blockout.txt` (primitives, the sails generated in it), `p2_form.txt` (the tunnel: bisect planes
outline the doorway on the front and back walls, those faces are deleted and a dark liner lines the
passage; hidden caps deleted; the windows), `p4_parts.txt` (run with `--no-save`: `tower.glb`, the
static tower, and `sails.glb`, the hub and sails with their origin at the hub moved to the world
origin, so the bake's position puts the hub in place and the game turns them about it).
`windmill.glb` is the whole model for the bench. 288 triangles.

## Assumptions and changes from the sheet
- The sheet's tunnel has a round top; the model's is squared (a round arch needed booleans that
  hedra's solver left ragged here: the cutter crossing the tower's bottom cap). At the scene's texel
  the doorway is 16 art pixels wide either way.
- The sheet draws the tunnel dark and closed; the model's goes through (you see the green beyond it):
  the ball rolls through. Both silhouette gates take this as missing area in front and back (IoU
  0.82 / 0.81 on the mesh, 0.81 / 0.79 in splats, all above their tiers).
- The sheet's top view shows the roof covering the tower; its front view shows the roof's base no
  wider than the band. Front leads: the roof is r 1.12 (the band's corners 1.06), the tower's base
  peeks out round it in the top view (drift 0.05 / 0.065, inside the tier).
- In the scene the windmill is baked at 1.3 times its size (`MILL_S`), so it reads as the hero and its
  tunnel (0.87 m) takes the 0.32 m ball comfortably; the bench is baked at the scene's spacing
  divided by 1.3 (0.0615 m) and the `@scene` goldens at the scene's texel divided by 1.3 (0.043).
  The game turns the sails at 0.9 of that size (`SAIL_SCALE`) so their tips clear the deck when they
  point down (1.94 m from the hub, which stands 2.1 m above it).

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.853 / 0.059 | 0.912 / **0.082** | 0.855 / 0.071 | 0.929 / 0.023 | sails 1.75 long, cloths on the clockwise side, the sails' plane 0.12 in front of the base |
| **p1 v2** | **0.892 / 0.019** | **0.948 / 0.046** | **0.890 / 0.031** | **0.927 / 0.026** | cloths on the counter-clockwise side (as drawn), sails 1.68, plane 0.06 in front, hub 0.24 |
| p2 (boolean tunnel) | 0.848 / 0.019 | 0.948 / 0.046 | 0.846 / 0.031 | 0.923 / 0.026 | rejected by eye: ragged sliver holes, no tunnel walls |
| **p2** (bisect + liner) | **0.821 / 0.019** | **0.938 / 0.070** | **0.819 / 0.031** | **0.918 / 0.050** | the doorway goes through (see above) |

Splats, albedo (`--min-iou 0.7`, colour drift <= 0.25), on p2 at the scene's density (spacing 0.0615 =
0.08 / 1.3): IoU 0.810 / 0.885 / 0.792 / 0.844, aspect drift 0.007 / 0.022 / 0.000 / 0.065, colour drift
0.06 / 0.10 / 0.14 / 0.14. (At the coarser 0.08: 0.812 / 0.886 / 0.790 / 0.835, drift up to 0.069.)

**Waivers: none.** Every view passes its tier; the deviations above are recorded as assumptions.

`hedra inspect check`: ngons on the cylinder and cone caps (harmless, triangulated on export); open
edges where hidden caps and the doorway's faces were deleted on purpose.

Goldens: `goldens/windmill` (framed), `goldens/windmill@scene` (`--texel 0.043 --size 400`), lit like
the scene (`--arg sunYaw=-35 --arg sunPitch=55 --arg keyLight=0.4 --arg highlight=0.9 --arg
shadeSteps=1`, `--real-sky`). The sheet is not reviewed by a person yet
(`art/windmill/sheet.v1.png.json`, `reviewed: false`).
