# Asset: lighthouse (hero prop, animated)
Concept: ../../art/lighthouse/sheet.v1.png (two colours on a #9a9a9a ground: the template's #d9d9d9 is
too close to #f0f6f0 for the cut-out), refs cut to ../../art/lighthouse/refs/.
Up Z, facing -Y; origin at the ground under the centre. Total height 4.51 m (the sheet's 4.6 incl. the ball).
Generated-sheet tier.

Measured off the FRONT panel: plinth 208 px = 2.0 m, so 104 px/m. The TOP panel is drawn at another
scale (138 px for the same plinth); the gate normalises size, so only its shape counts.

## Parts (metres; octagons turned 22.5 deg so a flat faces the front, as in the sheet's top view)
| Part | Size (across flats) | Position | Material (ramp, step) |
|---|---|---|---|
| Plinth | 2.0, 0.41 tall | z 0..0.41 | White (pale, +1) |
| Tower | 1.63 -> 0.99, tapered | z 0.41..3.27 | White; bands 1.22..1.65 and 2.26..2.64 (bisected faces) Dark (tar) |
| Gallery | 1.32, 0.27 tall | z 3.27..3.54 | Dark |
| Lamp head (one object, origin on the axis at z 3.76) | glass 0.94 x 0.44, 8 mullions 0.08, cap cone 1.07 x 0.34, finial r 0.11 | z 3.54..4.51 | Glass (glow, unlit), Dark |
| Door | 0.40 x 0.62 | front, z 0.41..1.03 | Dark |
| Window | 0.22 square | right side, z 1.95 | Dark |

## Animation
`LampHead` turns 0 -> -360 deg about Z (clockwise from above, against the demo / orbit camera's turn) in 192 frames at 24 fps, linear: one turn in 8 s. Exported with
`--bake-animations`, baked at 12 fps (stepped). One bone. The beams are a separate model
(`../env/beam.txt`) with the same keys and pivot, placed with the same transform, so the hero's gate
is not polluted by them.

## Gate record (generated-sheet tier: form IoU >= 0.75, aspect drift <= 0.08; splats IoU >= 0.7)
- p1 blockout, hedra views at `--elevation 0`: IoU 0.963 / 0.965 / 0.969 / 0.987, drift <= 0.013.
- p2 form (bands, door, window, mullions): IoU 0.950 / 0.949 / 0.957 / 0.987, aspect drift
  0.010 / 0.013 / 0.010 / 0.007. One fix on the way: the eighth mullion was left out of the join.
- Splats, albedo, 0.08 m spacing (the scene's): IoU 0.921 / 0.917 / 0.927 / 0.953, aspect drift
  0.046 / 0.048 / 0.046 / 0.007, colour drift 0.01 in every view. No waivers.
- Bake: colour error 0.000, no specks warning. Goldens: goldens/lighthouse (framed) and
  goldens/lighthouse@scene (texel 0.063), with the scene's look args (README).
- The sheet's record keeps `reviewed: false`: no person has approved it yet.
