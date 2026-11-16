# Asset: table (hero, the playfield; static)
Concept: ../../art/table/sheet.v1.png (SLSO-CLR17 colours), refs cut to ../../art/table/refs/ (no flips:
the sheet follows the brief: the coin box on the front, the top view's front at the bottom).
Up Z, facing -Y (the coin-box side), X the length; origin on the ground under the centre.
Scale from the FRONT panel: the body 619 px for 4.7 m -> 132 px per metre (the top panel draws at
128 px per metre, see Assumptions).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Playing surface | 4.32 x 2.07, top face only | top at z 1.06 | Rink (rink: teal #2aa4aa, lines #c1e5ea, goal arcs #41de95), `textures/rink.png` 96 x 46 |
| Rail caps | 0.19 wide, 0.145 tall, all round; end rails split by the goal mouth (0.76 wide) | z 1.065..1.21 | Cap (neon, pink #ea619d; unlit in the scene) |
| Rail bases | under the caps, 0.095 tall | z 0.97..1.065 | Rail (neon, purple #8f3da7) |
| Body | 4.7 x 2.45, sides only | z 0.49..0.97 | Body (steel, slate #3e415f) |
| Goal pockets | 0.35 long (0.16 out of each end), 0.76 wide, 0.28 tall | x ±(2.14..2.51), z 0.76..1.04 | Pocket (steel, ink #2e2c3b) |
| Legs | 0.29 square, 0.49 tall | x ±1.965, y ±0.92 | Leg (steel, #55607d) |
| Coin box | 0.55 x 0.10 x 0.33 on the front, its face inset 0.09 for the plate | x 0, y -1.225..-1.325, z 0.62..0.95 | Body; plate Coin (player, #f3c220) |

`make_table.py` holds these numbers and writes `p1_blockout.txt` (one box per part),
`p2_form.txt` (materials, the rink texture projected from the top, hidden faces deleted: bottoms,
the body's top, the rail bases' tops, the pockets' undersides; the coin plate inset; join; export)
and `textures/rink.png`.

## Assumptions
- The front and top panels draw at slightly different scales (132 and 128 px per metre) and the
  right and top views disagree on the width (2.52 and 2.38 m): the front view leads the length and
  heights, the right view leads the width (2.45 m, between the two).
- The sheet's lines are 0.06 m wide: at the scene's spacing they would break into specks, so the
  texture draws them 0.09 m (two texels); the goal arcs are mint (#41de95, the rink ramp's step
  above teal) instead of the sheet's pale cyan, so the goal ends read apart from the centre.
- The playing surface's height is not visible in the sheet's side views; it sits 0.15 m under the
  rail tops so the rails frame the puck (0.06 thick) and the mallets (0.32 tall).
- The coin box sticks out 0.10 m (the sheet's top view shows 0.15, its front view none): the right
  view takes the difference.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`, elevation 0), IoU / aspect drift:

| Phase | front | right | back | top |
|---|---|---|---|---|
| p1 blockout | 0.969 / 0.004 | 0.912 / 0.025 | 0.980 / 0.002 | 0.977 / 0.002 |
| **p2 form** | **0.969 / 0.004** | **0.911 / 0.025** | **0.980 / 0.002** | **0.977 / 0.002** |

Look, splats albedo (`lookdev/table.bin`, the scene's spacings: rink 0.04, the rest 0.043;
`--min-iou 0.7 --max-aspect-drift 0.08`), IoU / aspect drift / colour drift:

| | front | right | back | top |
|---|---|---|---|---|
| vs the sheet | 0.881 / 0.205 / 0.16 | 0.812 / 0.319 / 0.21 | 0.878 / 0.213 / 0.17 | 0.965 / 0.028 / 0.11 |
| vs the p2 mesh at elevation 5 | 0.954 / 0.049 | 0.950 / 0.025 | 0.951 / 0.040 | - |

**Waiver (side views' aspect drift vs the sheet).** `golden.py views --rive` does not render the
side views at elevation 0: the renderer clamps the orbit pitch to `pitchMin` (5 degrees) every
frame, and `pitchMin` is not an `--arg` it reads, so the "front", "right" and "back" renders look
5 degrees down (and "top" 5 degrees off vertical). For this long, flat table that shows 0.2 m
(front) to 0.4 m (right) of the rink and rail tops above the near rail, which alone makes the
aspect drift 0.2 to 0.3. Measured against the mesh rendered at the same 5 degrees
(`golden.py views --hedra --elevation 5`, `models/table/shots/p2_el5`), the splats pass (IoU 0.95,
drift at most 0.049); the top view and every colour drift pass against the sheet. No p3_splat_fit
phase was needed.

`hedra inspect check`: 128 non-manifold edges and 4 verts (the open borders left where hidden faces
were deleted, and separate boxes joined into one object), 72 duplicate verts (touching boxes), 8 wire
edges (the outline of the playing surface's deleted bottom): all harmless for splats.

Goldens: `goldens/table` (framed), `goldens/table@scene` (`--texel 0.0338 --size 400`), lit like the
scene (`--arg sunYaw=-25 --arg sunPitch=64 --arg keyLight=0.45 --arg highlight=0.93`, `--real-sky`).
Against the bench's ink sky the shaded right end and the legs sink into the dark; in the scene they
stand over the slate carpet.
