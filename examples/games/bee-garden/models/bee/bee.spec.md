# Asset: bee (hero, the player character; game-driven)
Concept: ../../art/bee/sheet.v1.png (FunkyFuture 8 colours), refs cut to ../../art/bee/refs/ (no flips:
the sheet follows the brief: right view faces left, top view head at the bottom).
Up Z, facing -Y; origin at the abdomen's centre (the pivot the game turns and banks it about).
Scale from the RIGHT panel: head front to abdomen back 455 px for 0.91 m -> 500 px per metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Abdomen | ellipsoid profile, 0.63 long (y -0.315..0.318), radius 0.285 across, 8-sided frustum rings | centre at the origin | Body (gold, #ffda45) and Band (ink, navy, `step` 1) alternating |
| Bands | four navy rings: y -0.276..-0.206, -0.116..-0.016, 0.084..0.184, 0.264..0.318 (tip) | on the abdomen | Band |
| Stinger | cone r 0.07, 0.11 long | y 0.32..0.43 | Band |
| Head | 8 x 6 uv-sphere, 0.50 wide, 0.38 long, 0.44 tall | y -0.43, z 0.01 | Body |
| Eyes | 8-sided discs r 0.065, 0.06 deep, x ±0.115 | on the head's front, y -0.615 | Band |
| Antennae | stalks 0.075 square from (±0.06, -0.52, 0.18) to (±0.2, -0.66, 0.33) | top of the head, leaning forward | Band |
| Antenna tips | icospheres r 0.07 | (±0.2, -0.66, 0.33) | Tip (petal, #ff4f69) |
| Wings | hexagonal plates 0.50 x 0.64, 0.045 thick, root end narrowed to half; root (±0.10, -0.20, 0.20), tip (±0.44, 0.12, 0.74) | a V above the abdomen's front | Wing (cloud, #49e7ec) rim, Panel (cloud, #fff7f8) inset 0.06 |

`make_bee.py` writes `p1_blockout.txt` (the rings, and the wing and antenna rotations computed as
hedra's extrinsic XYZ Euler angles); `p2_form.txt` assigns materials, insets the wing panels, deletes
the ring caps hidden inside the body, joins the body and exports `bee.glb` (the gated hero);
`p3_parts.txt` (run with `--no-save`) exports the game's parts: `bee_body.glb`, and `wing_l.glb` /
`wing_r.glb` with their origins at the wing roots, the hinges the game flaps them about.

## Assumptions
- The sheet draws the wings as broad plates in all four views, which a flat wing cannot be (seen
  edge-on from at least one side). The plates' normal is set halfway between the three view axes
  (`v = (±1, 1, 1)` made perpendicular to the wing's long axis), so every view shows them part-broad.
- The sheet's views disagree on the head: wider than the abdomen from the top (240 vs 200 px), smaller
  from the side (200 vs 280 px tall). Front and right lead (the game's 45 degree camera sees both);
  the head is 0.50 wide and the abdomen 0.57.
- The antenna tips sit in front of the head in the right view and over it in the top view; the right
  view leads (the top view's IoU takes the difference).
- No legs (the brief asked for none): at the scene's texel (0.056 m) they would be specks.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`, elevation 0):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.807 / 0.054 | 0.837 / 0.087 | 0.781 / 0.019 | 0.757 / 0.200 | wings edge-on from the front, antennae upright, top too long |
| p1 v2 | ≥ 0.75 / 0.102 | 0.718 / 0.137 | 0.781 / 0.132 | 0.772 / 0.082 | wing normal turned to the front: now edge-on from the side |
| p1 v3 | 0.761 / 0.068 | 0.755 / 0.068 | 0.735 / 0.033 | 0.790 / 0.193 | normal between all three axes; wings too narrow |
| p1 v4 | 0.725 / 0.117 | ≥ 0.75 / 0.089 | 0.741 / 0.146 | 0.739 / 0.011 | wider wing plates: the body now too small against them |
| **p1 v5 = p2** | **0.783 / 0.023** | **0.757 / 0.002** | **0.783 / 0.011** | **0.752 / 0.068** | abdomen radius 0.285, head 0.50 x 0.38 x 0.44, wing tips higher (z 0.74) |

Look, splats albedo (`lookdev/bee.bin`, spacing 0.046 = the scene's 0.065 at scale 1.4,
`--min-iou 0.7 --max-aspect-drift 0.08`, colour drift ≤ 0.25): IoU 0.818 / 0.768 / 0.828 / 0.797,
aspect drift 0.023 / 0.004 / 0.025 / 0.059, colour drift 0.19 / 0.12 / 0.20 / 0.16. (The sheet paints
the shaded side of the body orange; the albedo render keeps it on the painted yellow step.)

`hedra inspect check`: ngons on the eye discs and wing caps (harmless, triangulated on export);
duplicate verts and open edges where the abdomen rings meet (separate shells whose inner caps were
deleted on purpose, harmless for splats).

Goldens: `goldens/bee` (framed), `goldens/bee@scene` (`--texel 0.041` = the scene's 0.056 at scale
1.4, `--size 100`), lit like the scene (`--arg sunYaw=-35 --arg sunPitch=48`, `--real-sky`). Against
the navy sky the navy eyes and antennae read as holes; on the blue lawn of the scene they read.
