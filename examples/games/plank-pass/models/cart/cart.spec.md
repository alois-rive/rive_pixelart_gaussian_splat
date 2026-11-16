# Asset: cart (hero, game-driven) - the kettle cart

Concept: `../../art/cart/sheet.v1.png` (Codex, Cretaceous-16 colours, `reviewed: false`), refs cut to
`../../art/cart/refs/` (no flips: the RIGHT panel faces left, the TOP has the front at the bottom). Up Z,
facing -Y (the boiler is the front); origin on the ground under the middle of the body. Scale from the
RIGHT panel: the whole cart, lamp to tail, 600 px = 1.9 m -> 316 px per metre; the FRONT panel agrees
(420 px tall in both).

The side views are drawn from a little above: the body's top shows as a band 26 px deep over its 0.74 m
width (sin e = 0.082 / 0.74), about 6 degrees: the hedra gates render at `--elevation 6`.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Body | box 0.74 x 1.85 x 0.28 | z 0.2..0.48 | Red #7c4545 (red 1) |
| Wheels (4) | octagons 0.456 across, 0.12 thick | x +-0.426, y +-0.62, axle z 0.228 | Slate #454b4b (steel 2) |
| Hub caps (4) | octagons 0.15 across, 0.04 thick | the wheels' outer faces | Cream #bcb7a5 (cream 2) |
| Boiler | octagonal drum 0.61 across the flats, 0.47 tall | y -0.58, z 0.48..0.95 | Slate |
| Band | octagon 0.644 across, 0.07 tall | z 0.73..0.8 | Cream |
| Lid | octagonal frustum 0.61 -> 0.4 across, 0.07 | z 0.95..1.02 | Slate |
| Chimney | stack 0.17 across, 0.26 tall; flare to 0.28 across; cap 0.03 | z 1.0..1.36 | Slate |
| Headlamp | octagon 0.16 across, 0.09 deep | the boiler's front, z 0.6 | Cream |
| Crate | box 0.65 x 0.69 x 0.51 | y 0.48, z 0.48..0.99 | Wood #9e805c (wood 2) |
| Slats (2) | 0.68 x 0.72 x 0.075 bands round the crate | z 0.65, 0.84 | Slat #675239 (wood 1) |

`make_cart.py` writes `p1_blockout.txt` (every part as a primitive, materials), `p2_form.txt` (band, lid,
chimney flare and cap, slats, hub caps; the hidden bottoms of the boiler, stack and crate deleted; flat
shading; `cart.glb`) and the game parts `p3_body.txt` (`cart_body.glb`: all but the wheels and hub caps)
and `p3_wheel.txt` (`cart_wheel.glb`: the front pair of wheels and caps, the axle moved to the origin;
the scene uses it for both axles).

## Assumptions
- Front and right lead. The TOP panel is drawn at a smaller scale and relatively wider (its height/width
  1.6 against the right and front panels' 600 / 307 = 1.95): the model follows the front and right.
- The pink band along the body's top in the side views is its lit top face, not a separate rim.
- No spokes, no bolts: the hub cap is the only wheel detail.
- `inspect check` reports the cylinders' caps as ngons and the open edges where hidden bottoms were
  deleted (boiler, stack, crate) as non-manifold: on purpose.

Budgets: 454 triangles; 3 065 splats on the bench (spacing 0.08, slate 0.055, cream and slats 0.05),
3 238 in the scene (body 2 018, each wheel pair 610).

## Gate record (generated-sheet tier: form IoU >= 0.75, aspect drift <= 0.08; splat IoU >= 0.70, splat drift <= 0.08, colour <= 0.25)
| Phase | front | right | back | top |
|---|---|---|---|---|
| p1 hedra (iou / drift) | 0.810 / 0.035 | 0.923 / 0.022 | 0.913 / 0.076 | 0.944 / **0.218** |
| **p2 hedra** | **0.881 / 0.032** | **0.963 / 0.057** | **0.935 / 0.076** | **0.908 / 0.135** (waiver) |
| p4 splats, albedo (iou / drift / colour) | 0.818 / 0.074 / 0.22 | 0.883 / 0.044 / 0.23 | 0.877 / 0.034 / 0.11 | 0.892 / **0.103** / 0.14 (waiver) |

Waiver, top aspect drift (mesh 0.135, splats 0.103): the sheet contradicts itself (Assumptions); a model
that matched the top panel's proportions would fail the front and right views, which are the ones the
game shows (the camera sees the cart's left side). Everything else passes.

Goldens: `goldens/cart` (framed) and `goldens/cart@scene` (`--texel 0.077 --size 100`), lit from the
side the game shows (`--arg sunYaw=55 sunPitch=42 keyLight=0.4 highlight=0.85 shadeSteps=1
edgeDepth=0.5`, `--real-sky`): with the scene's own sun yaw (-35) the bench's right view looks at the
cart's shaded side.
