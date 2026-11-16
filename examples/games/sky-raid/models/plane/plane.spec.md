# Asset: plane (hero, the player's biplane; game-driven, no baked animation)
Concept: ../../art/plane/sheet.v1.png (Fantasy 24 colours, `reviewed: false`), refs cut to ../../art/plane/refs/
(no flips or turns: the sheet follows the brief's orientation line: right view nose left, top view nose
down). Up Z, nose to -Y; origin on the fuselage axis, 0.45 m above the wheels' ground (the pivot the game
banks the plane about). d = distance behind the spinner tip, y = d - 0.79; heights below are above the
wheels' ground (the command files subtract 0.45).

Scales: the FRONT panel gives heights and spans (upper wing 566 px = 1.8 m -> 314 px/m); the TOP panel gives
the plan (its span is 482 px: 268 px/m). The panels are not at one scale (see Assumptions).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Fuselage | box 0.36 x 1.30 x 0.40, tapering to 0.10 x 0.12 at the tail, tail end raised 0.06 | d 0.28-1.58, z 0.22-0.62 | Paint (paint, #ef692f, 3) |
| Cowling | 8-sided cylinder r 0.20, 0.18 long, flat top | d 0.10-0.28, centre z 0.43 | Cowl (metal, #684c3c, 2) |
| Spinner | 6-sided cone r 0.07, 0.10 long | d 0-0.10 | Dark (metal, #392a1c, 1) |
| Propeller | 0.70 x 0.08 x 0.03, turned 40 degrees (front view) | d 0.09 | Dark; its own piece in the scene (`prop.glb`, a game bone) |
| Upper wing | 1.80 x 0.36 x 0.09 (cream centre 1.40, orange tips 0.20 chamfered 0.06) | d 0.42-0.78, z 0.64-0.73 | Canvas (canvas, #efd8a1, 3), tips Paint |
| Lower wing | 1.52 x 0.34 x 0.08 | d 0.34-0.68, z 0.21-0.29 | Canvas |
| Struts | four posts 0.06 x 0.06 x 0.35 | x +-0.36, +-0.56; d 0.55 | Cowl |
| Cockpit | 0.20 x 0.16 x 0.08 (0.04 proud) | d 0.85-1.01 | Pit (metal, #2a1d0d, 0) |
| Windscreen | 0.18 x 0.03 x 0.07 | d 0.82 | Screen (metal, #927e6a, 3) |
| Tailplane | 0.70 x 0.16 x 0.05 (cream centre 0.46, orange tips 0.12 chamfered 0.04) | d 1.29-1.45, z 0.44-0.49 | Canvas, tips Paint |
| Fin | 0.06 thick, chord 0.33 at the base to 0.14 at the top, 0.43 tall | d 1.25-1.58, z 0.50-0.93 | Paint |
| Wheels, legs | 8-sided r 0.075 x 0.11; legs 0.05 x 0.05 x 0.14 | x +-0.17, d 0.40 | Dark, Cowl |

`p1_blockout.txt` (one primitive per part), `p2_form.txt` (taper, fin sweep, tip chamfers, materials,
one joined mesh plus the propeller, `plane.glb`, 342 tris), `p3_splat_fit.txt` (the splat fit: upper wing
thinned to 0.055 m, lower wing to 0.05, tailplane to 0.03; `plane_fit.glb`, the bench and the scene use it),
`p4_body.txt` / `p4_prop.txt` (the scene's two pieces: the body without the propeller, the propeller
centred on its hub).

## Assumptions
- The sheet's panels disagree on the length: the TOP view gives length / span 0.88 (1.58 m), the RIGHT view,
  at the front panel's scale, 1.84 m (1.02 x the span, aspect 0.435). The game looks at the plane from above
  (60 degrees), so TOP and FRONT lead and the plane is 1.58 m long; the RIGHT view gets a waiver.
- The FRONT and BACK panels disagree on the fin: 0.22 m above the upper wing in front, 0.18 m from behind
  (the back panel is also 4.6 % shorter overall). FRONT leads; BACK gets a waiver.
- The front view's propeller is diagonal and the top view's horizontal: modelled at 40 degrees (it spins
  in the game anyway).
- The sheet's windscreen is a light blue-grey off the palette: modelled in #927e6a (metal), 0.18 m wide.
- The struts are 0.06 m (the sheet: 0.05) and the lower wing peeks 0.08 m ahead of the upper one (the top
  view; the right view shows them aligned).

## Gate record (generated-sheet tier, chosen before the build: form IoU >= 0.75, drift <= 0.08; splats
## IoU >= 0.7, drift <= 0.08, colour drift <= 0.25)
Form, hedra views vs refs (elevation 0):

| Iteration | front | right | back | top |
|---|---|---|---|---|
| p1 blockout | 0.791 / 0.031 | 0.555 / 0.355 | 0.790 / 0.011 | 0.864 / 0.009 |
| **p2 form** | **0.797 / 0.031** | 0.630 / 0.355 (waiver) | **0.790 / 0.011** | **0.900 / 0.009** |

Look, splats albedo (`lookdev/plane.bin`, baked as the scene bakes it: spacing 0.05, Canvas 0.04, Paint
0.045, Cowl 0.035, Dark 0.04, Pit 0.045, Screen 0.035; 2977 splats). Taken at exact angles
(`--arg pitchMin=0 --arg pitchMax=90`: the sheet is drawn exactly frontal) against
`art/plane/gate_palette.json` (the hero's own ramps canvas, paint and metal: the cream #efd8a1 sits in
seven ramps of the palette and otherwise counts towards each):

| Bench | front | right | back | top |
|---|---|---|---|---|
| p2, spacing 0.065, full palette, pitch 5-85 | 0.593 / 0.077 / c 0.26 | 0.670 / 0.394 / c 0.25 | 0.631 / 0.054 / c 0.32 | 0.818 / 0.016 / c 0.09 |
| p2, finer wings, hero palette | 0.651 / 0.076 / c 0.11 | 0.671 / 0.394 / c 0.07 | 0.667 / 0.049 / c 0.19 | 0.858 / 0.020 / c 0.03 |
| p3 fit (wings 0.04), exact angles | 0.756 / 0.012 / c 0.07 | 0.647 / 0.379 | 0.683 / 0.031 / c 0.13 | 0.882 / 0.000 / c 0.02 |
| **p3 fit (wings 0.055 / 0.05), exact angles** | **0.736 / 0.007 / c 0.06** | 0.647 / 0.394 / c 0.15 (waiver) | 0.641 / 0.025 / c 0.13 (waiver) | **0.883 / 0.000 / c 0.01** |

(IoU / aspect drift / colour drift.) The wings at 0.04 m broke into dashes seen edge-on from behind (an edge
face under two splats); 0.055 m holds. A fin 0.03 m lower passes the back view (0.731) and fails the
front (0.681): the sheet's own contradiction, so the front leads and the back is waived.

Waivers: RIGHT (form and splats): the sheet's side view is 35 % longer than its top view. BACK (splats):
the back panel's fin is lower than the front panel's.

`hedra inspect check`: 15 ngons (cylinder and cone caps, triangulated on export) and 32 duplicate verts where
the flush wing and tailplane tips touch (separate shells, harmless for splats).

Goldens: `goldens/plane` (framed) and `goldens/plane@scene` (`--texel 0.070218 --size 160`), lit like the
scene (`--arg sunYaw=-140 sunPitch=50 keyLight=0.42 highlight=0.85 shadeSteps=1 lightSteps=1
bandDither=0.35 edgeDepth=0.6`, `--real-sky`).
