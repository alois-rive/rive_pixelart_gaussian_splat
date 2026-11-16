# Asset: cart (hero, the player)
Concept: ../../art/cart/sheet.v1.png (CC-29 colours), refs cut to ../../art/cart/refs/ with
`--rotate top=-90` (the sheet drew the top view with the handles at the bottom; the cart is front/back
symmetric, so the turn is honest). Up Z, facing -Y; origin on the ground under the body's centre.
Scale from the front panel: body 455 px = 1.4 m -> 325 px per metre (front, right and back panels share
it; the top panel is drawn smaller, 214 px per metre, which the gate's normalised IoU ignores).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Body (open tray, inset 0.04, sunk 0.4) | 1.4 x 0.75 x 0.51 | z 0.29..0.8 | Paint (blue, #4b80ca) |
| Rim | four bars 0.07 x 0.09 | top at z 0.855 | Wood (wood, #a77b5b) |
| Corner posts | 0.11 square, 0.6 tall | z 0.27..0.87 | Wood |
| Wheels | octagons r 0.33, 0.11 thick, axle along Y at z 0.32 | y +-0.43 | WheelWood (wood, #80493a) |
| Hubs | octagons r 0.085, 0.06 thick | y +-0.51 | Red (red, #b45252) |
| Shafts | 0.62 x 0.08 x 0.08 | x -1.0; front shaft z 0.64, back shaft z 0.81 | Wood |
| Grip | 0.1 x 0.8 x 0.32 | x -1.33, z 0.74 | Wood |
| Leg | 0.08 x 0.08 x 0.3 | x -0.62 | Wood |
| Apples | three icospheres r 0.125 | heaped over the rim | Red |

`p1_blockout.txt` (primitives), `p2_form.txt` (tray, materials, joins into `Cart` and `Wheels`; exports
`cart.glb` for the gates, `cart_body.glb` and `cart_wheels.glb` (origin moved to the axle) for the game).

## Assumptions
- The sheet's front view shows the two handle shafts at different heights while its top view puts them
  at the front and back edges: the model does both (front shaft low, back shaft high), so every view
  agrees with the sheet.
- The right view leaves out the leg (hidden by nothing in a true side view): kept, the front view shows it.
- Rims thinned from 0.09 to 0.07: splats fatten thin parts by about a radius, and the top view's wood
  share (colour drift) was at the limit.

## Gate record (generated-sheet tier, chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75`, aspect drift <= 0.08):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.812 / 0.025 | 0.835 / 0.026 | 0.813 / 0.000 | 0.865 / 0.075 | shafts rotated at `add` then scaled: skewed, crossing |
| p1 v2 | 0.853 / 0.021 | 0.860 / 0.026 | 0.858 / 0.045 | 0.819 / 0.075 | shafts level, at the body's edges; apples lower |
| **p2** | **0.853 / 0.021** | **0.860 / 0.026** | **0.858 / 0.045** | **0.824 / 0.075** | rims 0.07 |

Look, splats albedo (`lookdev/cart.bin`, spacing 0.055 = the scene's, `--min-iou 0.7`, drift <= 0.08,
colour <= 0.25): v1 top colour drift 0.25 (fail: sheet's lit wood snapping to the orange ramp, wide
rims); **p2: IoU 0.819 / 0.740 / 0.807 / 0.795, aspect drift 0.023 / 0.069 / 0.007 / 0.055, colour
drift 0.20 / 0.18 / 0.19 / 0.23.**

Goldens: `goldens/cart` (framed), `goldens/cart@scene` (`--texel 0.0347 --size 160 --pixel 2`), lit like
the scene (`--arg sunYaw=-35 --arg sunPitch=48 --arg keyLight=0.45 --arg highlight=0.8`, `--real-sky`).
The sheet is not reviewed by a person yet (`art/cart/sheet.v1.png.json`, `reviewed: false`).
