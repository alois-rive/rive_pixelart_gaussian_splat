# Asset: cannon (hero prop)
Concept: ../../art/cannon/sheet.v1.png (SLSO8 colours, Codex, `reviewed: false`), refs cut to
../../art/cannon/refs/ (no flips: the sheet follows the brief's orientation). Up Z, muzzle towards -Y;
origin on the ground under the carriage's centre. Total height 0.94 m (muzzle top).
Scale from the right panel: carriage 455 px = 1.1 m -> 414 px per metre. The front and back panels
are drawn at about 453 px per metre (see Assumptions).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Tube | frustum r 0.22 (breech) -> 0.15 (muzzle), 1.15 long | pivot-relative y -0.70 .. +0.45 | Iron (iron, #203c56) |
| Muzzle ring | r 0.22, 0.16 long, bore inset 0.06 and sunk 0.14 | y -0.85 .. -0.69 | IronLight (iron, #544e68), Bore (#0d2b45) |
| Breech cap + knob | frustum r 0.22 -> 0.1, 0.17 long; knob r 0.075 | y +0.45 .. +0.75 | IronLight |
| Fuse ring | torus 0.05 / 0.022 | y +0.36, z +0.25 | IronLight |
| Trunnions | cylinder r 0.07, 0.56 across | the pivot | IronLight |
| Barrel placement | pivot (0, -0.09, 0.66), muzzle raised 5 degrees | | |
| Cheeks | 0.11 thick at x +-0.27; front 0.24 x 0.45 tall, middle 0.46 x 0.38, rear 0.40 x 0.28 (stepped down to the back) | z from 0.12 | Wood (wood, #8d697a) |
| Transom | 0.56 x 0.2 x 0.16 | y -0.1, z 0.49 | IronLight |
| Axle blocks | 0.84 x 0.13 x 0.13 | y -0.38 and +0.31, z 0.2 | IronLight |
| Wheels | 10-sided, r 0.17, 0.1 thick | x +-0.40, y -0.38 / +0.31, z 0.17 | Wheel (sand, #d08159) |

`p1_blockout.txt` (primitives; the barrel's parts are built round the trunnion pivot, joined, then
placed), `p2_form.txt` (materials, the bore, joins: Barrel, Carriage; exports `cannon.glb` for the
gates, `carriage.glb` and `barrel.glb` (Barrel moved to the origin and unturned, so its pivot is the
game bone's pivot) for the scene).

## Assumptions
- The sheet's front and back panels are drawn larger than the side panel (muzzle ring 0.46 m across
  in front, 0.39 m from the side). The right and top views lead the sizes; the muzzle ring is 0.44 m
  across as a compromise, the cheeks' outer width 0.65 m.
- The sheet's front and back views of the same silhouette disagree (aspect 1.062 vs 1.017; an
  orthographic front and back are mirror images and must match). The front leads.
- The sheet raises the barrel ~5 degrees; the model does too (the game sets its own elevation).

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75`, aspect drift <= 0.08):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.664 / 0.680 | 0.430 / 1.456 | 0.620 / 0.754 | 0.570 / 0.289 | rotations given at `add` were not applied before the join: the barrel stood upright |
| p1 v2 | 0.710 / 0.017 | 0.818 / 0.007 | 0.708 / 0.026 | 0.887 / 0.038 | `apply --rotation` after each turned part |
| p1 v3 | 0.764 / 0.017 | 0.817 / 0.010 | 0.716 / 0.026 | 0.893 / 0.040 | muzzle ring r 0.22, a transom under the barrel |
| p1 v4 | 0.775 / 0.017 | 0.817 / 0.010 | 0.756 / 0.026 | 0.892 / 0.040 | axle blocks up to z 0.2; wheels r 0.17; trunnions 0.56 |
| **p2** | **0.787 / 0.007** | **0.910 / 0.002** | **0.755 / 0.037** | **0.801 / 0.040** | barrel parts' locations applied before the join (pivot at the trunnions); axles 0.84 |

Look, splats albedo (`lookdev/cannon.bin`, spacing 0.045 = the scene's 0.08 / 1.8,
`--min-iou 0.7`, aspect drift <= 0.08, colour drift <= 0.25):
IoU 0.728 / 0.902 / 0.772 / 0.854, aspect drift 0.002 / 0.052 / **0.100** / 0.032, colour drift
0.05 / 0.03 / 0.03 / 0.02.

Waiver, back aspect at the splat tier (0.100): the sheet's own front and back disagree by 0.045
(above); the model's front and back silhouettes are the same mesh (form drift 0.037 passes) and its
front passes at 0.002. Front leads.

`hedra inspect check`: ngons on cylinder caps (harmless, triangulated on export) and duplicate verts
where the joined barrel shells touch (separate shells, harmless for splats).

Goldens: `goldens/cannon` (framed), `goldens/cannon@scene` (`--texel 0.0316`: the scene's texel over
the scene's x1.8), lit like the scene (`--arg sunYaw=70 --arg sunPitch=32`, `--real-sky`).
