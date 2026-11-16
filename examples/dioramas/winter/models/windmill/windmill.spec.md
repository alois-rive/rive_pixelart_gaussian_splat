# Asset: windmill (hero prop, animated)
Concept: ../../art/windmill/sheet.v2.png (in Magik16), refs cut to ../../art/windmill/refs.v2/;
v1 (Apollo colours, refs/) is kept for the record.
Up Z, facing -Y; origin at the ground under the house's centre. Total height 2.77 m.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Base | 1.9 x 1.9 x 0.4 | z 0..0.4 | Stone (stone, #668b90) |
| House | 1.6 x 1.6 x 1.45 | z 0.4..1.85 | Planks (wood, 16 px texture #591e37 / #9b5a44, cube-projected) |
| Attic | wedge 1.6 x 1.6 x 0.75 | z 1.85..2.6 | Gable (wood, #591e37) |
| Roof | 2 slabs 1.35 x 2.25 x 0.2, 43 degrees | ridge along Y | Snow (snow, #bee5e1) |
| Door, windows | 0.45 x 0.8; 0.36 square | front; both sides | Door (wood, #1c1e1f); Glow (lamp, #f0f3c4, unlit) |
| Sails | 4 x (0.38 x 0.95 cloth + 1.1 spar), hub r 0.16 | hub at (0, -0.95, 1.5) | Cloth (wood, #e9cea8, two-sided), Spar (wood, #591e37) |

## Animation
`Sails` (cloth, spars and hub joined, origin at the hub) turns -360 degrees about Y in 144 frames at
24 fps, linear: one turn in 6 s. Exported with `--bake-animations`; baked at 12 fps (stepped).
One bone.

## Gate record (generated-sheet tier)
- Form, hedra views at `--elevation 5`: IoU 0.90 / 0.83 / 0.87 / 0.85, aspect drift <= 0.07.
  Iterations: attic prism lying sideways (Euler XYZ is extrinsic: `90 -90 0`, then replaced by a
  wedge), model 12 % too tall, roof too narrow for the sheet's snow cap, sails above the roof.
- Look, splats albedo: IoU 0.84 / 0.81 / 0.86 / 0.87, colour drift 0.09 / 0.04 / 0.04 / 0.47.
  Waiver, top colour: the sheet was painted in Apollo before the palette became Magik16; its
  grey-white snow snaps to Magik16's cream (the top of the wood ramp), so the top view compares
  "wood" against "snow". Regenerate the sheet with the final palette to remove it.

## Gate record, sheet v2 (Magik16)
Regenerated in the final palette to clear the v1 top-view colour waiver. One change it asked for:
roof 2.0 -> 2.25 m front to back (its top view is deeper).
- Form, hedra `--elevation 5` vs refs.v2: IoU 0.89 / 0.82 / 0.90 / 0.75, aspect drift <= 0.07.
- Look, splats albedo: IoU 0.84 / 0.84 / 0.89 / 0.80, colour drift 0.23 / 0.19 / 0.17 / 0.23. No waivers.
