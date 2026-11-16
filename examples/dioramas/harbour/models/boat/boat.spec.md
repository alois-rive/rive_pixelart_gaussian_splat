# Asset: boat (hero prop, animated)
Concept: ../../art/boat/sheet.v1.png, refs cut to ../../art/boat/refs/ (`--flip right --rotate top=-90`).
Scale: the hull is 3.0 m long = 656 px in the right panel (220 px/m); the front panel is 275 px
for the 1.22 m beam (225 px/m). Up Z, bow to -Y (hedra front view looks along +Y). Origin at the
waterline under the hull's centre: the sheet cuts the hull at the waterline (z 0).

## Parts (metres, measured on the sheet)
| Part | Size | Position | Material (ramp, colour) |
|---|---|---|---|
| Hull | 1.22 beam, 2.97 long, 0.60 to the rail; bow taper 0.97 long; stem raked 0.55; flares below z 0.30 to 0.98 at the waterline | y -1.50..1.47 | HullRed z<0.30 (hull c33846), HullOrange 0.30-0.47 (hull e78c5b), Rail >0.47 (navy 5f3a60) |
| Deck well | inset 0.07 (the rail), 0.10 deep | z 0.50 | Deck (deck e8bf92) |
| Cabin | 0.91 x 0.88 x 0.72 | y 0.39..1.27, z 0.50..1.22 | CabinWhite (white ece8c2) |
| Windows x4 | wall inset 0.17, sunk 0.03 (0.57 x 0.38) | every wall | Window (navy 320011) |
| Corner posts x4 | 0.12 x 0.12 x 0.72 | cabin corners | CabinTrim (white b7a39d) |
| Roof | 1.03 x 0.98 x 0.13 | z 1.22..1.35 | Roof (navy 5e80b2) |
| Mast | 0.12 square (sheet 0.086, thickened), 1.50 | y -0.06, z 0.50..2.00 | Mast (rock 5f3a60), spacing 0.06 |
| Spars x2 | 0.42 x 0.10 x 0.10, crossed | z 1.63 | Mast |
| Flag | 0.33 x 0.20 x 0.05, 30 deg off the bow line to +X | from the mast top, z 1.75..1.95 | Flag (grass d2cb3e), spacing 0.06, two-sided |
| Crate A | 0.38 x 0.38 x 0.30, yaw 10 | x 0.26, y -0.05 | Crate (hull f7d554) |
| Crate B | 0.30 x 0.30 x 0.24 | x -0.24, y -0.40 | CrateRed (deck c66f5e) |
| Rope coil | 8 sides, r 0.18, 0.14 tall, hole inset 0.08 | y -0.80 | Rope (deck c66f5e) |

## Proportions the views agree on
- Right: height / length 0.663 (total height 2.0 incl. mast). Front: 1.58. Top: 2.38 (beam 1.26 with the rail).
- Cabin occupies the stern 0.88 m; the mast sits at mid-length; the bow taper starts 0.97 m from the tip.

## Assumptions (the sheet does not show, or contradicts itself)
- Crate placement: the front view puts the orange crate on the right, the top view on the left;
  the model follows the top view (light crate at +X near the mast, orange crate at -X forward).
- The flag streams forward in the right and top views but sideways in the front view: set at 30 deg
  between them (the front view loses most of its flag: part of its IoU deficit).
- Crate X-bracing and the coil's turns are smaller than two splats: dropped.
- For the scene (phase 3, `p3_motion.txt`) the parts are joined into one mesh, a 0.25 m skirt is
  extruded below the waterline (a rolled hull never shows its foot) and the bob is keyed.
  `boat_form.glb` (end of phase 2) is what the gates measure; `boat.glb` is what the scene plays.

## Palette
Summers Past-16 (the sheet was drawn in Sweetie 16; colours mapped to the nearest ramp roles).
The roof stayed on 5e80b2 (navy): 6db7c3 is the lookdev sky colour and the gate's mask lost the
roof against it (top IoU 0.58).

## Motion (p3_motion.txt)
Roll 5 deg (sin), pitch 2 deg (cos), rise 0.035 m (twice per loop); keys every 2 frames, linear,
frames 0..48 at 12 fps (frame 48 = frame 0), exported with `--bake-animations`; bake `fps 12, loop 4.0`.

## Budgets
<= 600 triangles (334 with the skirt), 13 materials, no textures, 1 bone.

## Gate record (generated-sheet tier, chosen before the build)
- p1 blockout (hedra, `--elevation 0`; 8 deg tried and worse: front drift 0.09, back 0.17):
  IoU 0.920 / 0.942 / 0.937 / 0.976 (front / right / back / top), aspect drift <= 0.069. Pass (>= 0.75, <= 0.08).
- p2 form (hedra): IoU 0.883 / 0.923 / 0.911 / 0.976, drift <= 0.069, colour drift 0.14 / 0.10 / 0.14 / 0.13. Pass.
- p4 splats, albedo (lookdev, spacing 0.08 as the well's bench): IoU 0.773 / 0.798 / 0.858 / 0.913,
  aspect drift 0.002 / 0.050 / 0.053 / 0.068, colour drift 0.13 / 0.16 / 0.14 / 0.16. Pass (>= 0.70).
- Fixes the gates asked for: hull flare moved below z 0.30 (front/back bottom corners), hull
  location applied so `where` reads metres (a bisect at local 0.30 cut nothing), top-view aspect
  0.080 at the scene spacing 0.10 (the splat fringe widens a 1.2 m beam more than a 3 m length):
  bench baked at 0.08, roof colour kept off the bench's sky colour.
- Goldens: goldens/boat (framed) and goldens/boat@scene (texel 0.06375, 240 px, pixel 3), approved
  through the lit lookdev; `golden.py check` 0.0000 %.
