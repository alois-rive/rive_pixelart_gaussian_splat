# Asset: table (hero: the pool table with its hanging lamp)
Concept: ../../art/table/sheet.v1.png (Chromatic16 colours), refs cut to ../../art/table/refs/ (no flips:
the sheet follows the brief; the right view shows the short end with the two cords overlapping).
Up Z, facing -Y (a long side), X the length; origin on the ground under the centre.
Scale from the FRONT panel: the rails 516 px for 2.32 m -> 222 px per metre (the top panel draws at
221 px per metre).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Felt | 2.04 x 1.04, top face only | top at z 0.71 | Felt (felt, green #20ac00) |
| Rails | 0.16 wide all round (outer 2.32 x 1.32, inner 2.0 x 1.0), 0.14 tall | z 0.61..0.75 | Rail (wood, brown #a05000); their inner faces Cushion (felt, green) |
| Apron | 2.30 x 1.30, sides only | z 0.38..0.61 | Apron (wood, maroon #800018) |
| Legs | 0.20 square, inset 0.06 from the outline | x +-1.00, y +-0.50, z 0..0.38 | Leg (wood, brown) |
| Pockets | 8-sided cups 0.14 across, 2 cm proud of the rails | the corners (+-1.0, +-0.5) and the long sides (0, +-0.53), z 0.60..0.77 | Pocket (hole, black) |
| Shade | 1.33 x 0.44 at its bottom, 1.16 x 0.30 at its top (sloped sides), 0.24 tall | z 1.25..1.49 | Shade (felt, green); its top face ShadeTop (the same green, own material) |
| Glow strip | the shade's footprint, 6 cm deep | z 1.19..1.25 | Glow (glow, peach #ffc080; unlit in the scene) |
| Cords | 3 cm square | x +-0.38, z 1.49..1.94 | Cord (hole, black) |

`make_table.py` holds these numbers and writes `p1_blockout.txt` (one primitive per part) and
`p2_form.txt` (materials, the cushion faces, the shade's sloped sides, hidden faces deleted, the table
and the lamp joined into two objects, export). p2 exports three files: `table.glb` (the hero, gated),
`table_body.glb` and `lamp.glb` (the scene's pieces: the lamp's origin moved to its cords' top, the
pivot its bone swings on; it is put back afterwards so the saved model stays the hero).

## Assumptions
- The front and top views give 1.32 and 1.27 m for the width: the right view (1.32 m) leads.
- The sheet draws the shade's glow strip 3 cm deep; it is 6 cm and the shade's full footprint here,
  so it shows under the shade from the game's high camera (at 3 cm and inset it hid behind the shade's
  lower edge). The front gate still passes (IoU 0.92, drift 0.002).
- The felt's height is not visible in the side views; it sits 4 cm under the rail tops (a 9 cm ball
  stands proud of the rails, as pixel-art balls should).
- The pockets are cups 2 cm proud of the rails (a pocket's leather rim) rather than holes cut in the
  rails: coplanar black discs would fight the rail splats at the same depth.
- The scene changes three things for readability, never the gated model: the lamp hangs 0.42 m
  higher (at the sheet's height, 0.5 m over the felt, it covered the far third of the table from the
  game's 48-degree camera), the shade's top is baked a step down its ramp (navy: seen from above, an
  all-green shade read as a second table) and the apron a step up (brown, so its shaded front reads
  maroon instead of black).

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`, elevation 0), IoU / aspect drift:

| Phase | front | right | back | top |
|---|---|---|---|---|
| p1 blockout | 0.914 / 0.002 | 0.911 / 0.002 | 0.919 / 0.002 | 0.996 / 0.026 |
| **p2 form** | **0.919 / 0.002** | **0.910 / 0.002** | **0.927 / 0.002** | **0.996 / 0.026** |

Look, splats albedo (`lookdev/table.bin`, the scene's spacings: felt 0.021, the rest 0.02;
`--min-iou 0.7 --max-aspect-drift 0.08`), IoU / aspect drift / colour drift:

| | front | right | back | top |
|---|---|---|---|---|
| vs the sheet | 0.772 / 0.017 / 0.12 | 0.673 / 0.042 / 0.17 | 0.775 / 0.027 / 0.11 | 0.983 / 0.045 / 0.04 |
| vs the p2 mesh at elevation 5 | 0.942 / 0.007 | 0.906 / 0.019 | 0.931 / 0.007 | - |

**Waiver (the right view's splat IoU vs the sheet, 0.673 < 0.70).** `golden.py views --rive` draws
the side views from 5 degrees above (the renderer clamps the orbit pitch to `pitchMin`, 5), which for
this flat table shows the felt and the rails' tops above the near rail: the short end view gains a
band the sheet's exactly frontal view does not have (the compare sheet's green band over the rails).
Against the mesh rendered at the same 5 degrees (`shots/p2_el5`) the splats pass in every view (IoU
0.906 to 0.942, drift at most 0.019); every aspect drift and colour drift passes against the sheet.
No p3_splat_fit phase was needed. (The same clamp is recorded in `air-hockey`'s table spec.)

`hedra inspect check`: non-manifold edges and verts (the open borders left where hidden faces were
deleted, separate boxes joined into one object), cylinder caps as ngons: harmless for splats.

Goldens: `goldens/table` (framed), `goldens/table@scene` (`--texel 0.0139 --size 400`), lit like the
scene (`--arg sunYaw=-15 --arg sunPitch=76 --arg keyLight=0.45 --arg highlight=0.985 --arg
shadeSteps=2`, `--real-sky`). Against the bench's black sky the shaded legs, cords and apron sink into
the dark; in the scene they stand over the maroon floor.
