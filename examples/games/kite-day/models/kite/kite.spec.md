# Asset: kite (hero, the player; a game bone)
Concept: ../../art/kite/sheet.v1.png (Twilight 5 colours), refs cut to ../../art/kite/refs/ (no flips:
the sheet follows the brief's orientation line). Up Z, facing -Y; origin at the spar crossing (the
pivot the game turns the kite about). Placed in the scene at scale 1.8 (2.4 m tall, ~24 art pixels).
Scale from the front panel: the sail's side tips 304 px apart = 1.0 m -> 304 px per metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Sail | rhombus 1.0 wide x 1.35 tall, 0.08 thick plate | top tip z 0.57, side tips z 0, bottom tip z -0.78 | Pink #ee8695 (kite, 1), Peach #fbbbad (kite, 2) |
| Bow | side tips 0.2 back (+Y), corners 0.1: four planar panels | | |
| Panels | front: top-left and bottom-right pink, the others peach; back as the sheet draws it | | |
| Vertical spar | 0.07 x 0.07 x 1.37 | proud of the front face (y -0.075) | Spar #292831 (bird, 0) |
| Cross spar | two halves 0.54 long, turned 21.8 degrees to follow the bow | z 0 | Spar |
| Knot | 0.15 x 0.07 x 0.15 | front of the crossing (y -0.085) | Spar |
| Stub | 0.09 x 0.09 x 0.16 | under the bottom tip, z -0.85 | Spar |

108 triangles. `p1_blockout.txt` (the plate pulled into the rhombus, the bow, spars, knot, stub),
`p2_form.txt` (materials by face, join, `kite.glb`). The tail is not part of the hero: it is a chain of
five bows (`models/env/bow.txt`) the game swings from the stub.

## Assumptions
- The sheet's widest point sits 0.57 m below the top tip (the brief said 0.4): the sheet leads.
- The sheet contradicts itself on the bow: the top view shows the tips 0.2-0.25 m back (V depth / width
  0.344 with the 0.15 m of sail and spar), the right view shows a flat 0.155 m sliver with no bow. Front,
  back and top lead; the right view gets a waiver (below).
- The sheet's back view repeats the front's panel colours instead of mirroring them (top-left pink seen
  from behind too). The model paints its back faces as the sheet draws them; both colours share the kite
  ramp, so the colour gate is unaffected.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.936 / 0.001 | 0.651 / 0.592 | 0.943 / 0.012 | 0.841 / 0.085 | knot stood 0.14 proud |
| **p1 v2 = p2** | **0.936 / 0.001** | 0.612 / 0.568 | **0.943 / 0.012** | **0.821 / 0.015** | knot 0.07 deep at y -0.085 |

Look, splats albedo (`lookdev/kite.bin`, spacing 0.083 = the scene's 0.15 / 1.8, spars 0.05,
`--min-iou 0.7 --max-aspect-drift 0.08`): front 0.918 / drift 0.049 / colour 0.07, back 0.910 / 0.041 /
0.01, top 0.767 / 0.341 / 0.06, right 0.693 / 0.652 / 0.05.

Waivers:
- right (form 0.612 / drift 0.568, splats 0.693 / 0.652): the sheet draws no bow in its side view while
  its top view does; a 0.36 m deep bowed kite cannot match a 0.155 m sliver (aspect 9.8).
- top, splats aspect (0.341; form 0.015 passes): a 0.08 m plate seen edge-on grows by a splat radius on
  each side; at the scene's spacing the 0.36 m deep V comes out ~0.46 deep. The game only ever shows the
  kite's face (yaw within 14 degrees), where front IoU is 0.918.

`hedra inspect check`: 0 findings.

Goldens: `goldens/kite` (framed), `goldens/kite@scene` (`--texel 0.054`: the scene's 0.098 m texel at
scale 1.8), lit like the scene (`--arg sunYaw=-35 sunPitch=32 keyLight=0.45 highlight=0.8
bandDither=0.4`, `--real-sky`). Its back is dark in them: the dusk sun is in front of the kite.
