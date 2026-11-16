# Asset: skater (hero, the player character "Marlo" with his board; game-driven)
Concept: ../../art/skater/sheet.v1.png (AAP-64 colours, the final palette), refs cut to
../../art/skater/refs/ (no flips: the sheet follows the brief: right view faces left, top view chest at
the bottom, board nose at the right in the front view). An original character: a chunky kid in a yellow
beanie and red-orange hoodie on a magenta deck.
Up Z, facing -Y (the chest), the board's nose at +X; origin on the ground under the board's centre.
Scale from the FRONT panel: 478 px for 1.67 m (wheel bottom to beanie top) -> 290 px per metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, colour) |
|---|---|---|---|
| Deck (middle) | box 0.84 x 0.38 x 0.05 | z 0.17..0.22 | Deck (deck, `#bc4a9b`), top faces Grip (grip, `#333941`) |
| Nose and tail kicks | boxes 0.19 x 0.38 x 0.05, turned up 18 degrees | at x +-0.50 | Deck / Grip |
| Trucks | boxes 0.10 x 0.26 x 0.06 | x +-0.345, z 0.115..0.175 | Steel (steel, `#8b93af`) |
| Wheels | 8-sided cylinders r 0.06, 0.07 wide | x +-0.345, y +-0.15, z 0.06 | Wheel (wheel, `#fef3c0`) |
| Shoes | chamfered boxes 0.29 x 0.32 x 0.15 | x +-0.31, y -0.03, on the deck top | Shoe (white, `#dae0ea`) |
| Thighs, shins | boxes 0.15 x 0.17 and 0.17 x 0.19, 0.2065 each, knees 0.035 forward | hips (+-0.10, 0, 0.70) to ankles (+-0.29, 0, 0.34) | Denim (denim, `#285cc4`) |
| Cuffs | boxes 0.22 x 0.23 x 0.07 | at the ankles | Denim |
| Torso | box 0.36 x 0.285 x 0.46, chamfer 0.04 | z 0.68..1.14 | Hoodie (hoodie, `#df3e23`) |
| Hood | box 0.28 x 0.10 x 0.20 | on the back, z 0.96..1.16 | Hoodie |
| Arms | boxes 0.13 x 0.14, 0.336 long | shoulders (+-0.195, 0, 1.06) to wrists (+-0.335, -0.01, 0.755) | Hoodie |
| Hands | boxes 0.11 | under the wrists | Skin (skin, `#dba463`) |
| Head | box 0.40 x 0.36 x 0.28, chamfer 0.04 | z 1.13..1.41 | Skin |
| Hair | box 0.42 x 0.34 x 0.13 | z 1.29..1.42, set back | Hair (wood, `#71413b`) |
| Ears, nose | boxes 0.05 x 0.11 x 0.115 (ears), 0.08 x 0.055 x 0.09 (nose) | head sides, face | Skin |
| Eyes | boxes 0.05 x 0.025 x 0.055 | x +-0.08, face, z 1.29..1.345 | Eye (grip, `#141013`), specks |
| Beanie | 8-sided rim r 0.25 (z 1.38..1.47), two frustums r 0.24 -> 0.185 -> 0.06 to z 1.67 | on the head | Beanie (beanie, `#ffd541`) |

`make_skater.py` writes the four phases:
- `p1_blockout.txt`: every part at the spec's sizes, scale applied.
- `p2_form.txt`: chamfers, materials (exact AAP-64 colours), grip on every upward deck face, flat
  shading, exports `skater.glb` (the gated form).
- `p3_splat_fit.txt` (run `--no-save --to skater_fit.rmdl`, so `skater.rmdl` stays the gated form):
  narrows the beanie (x 0.94, y 0.84), head and hair (y 0.86), the board's width (y 0.86, wheels 2 cm
  in), shoes (0.9), torso and hood (0.9) for the splats; exports `skater_fit.glb`, which the bench bakes.
- `p4_parts.txt` (run `--no-save` on `skater_fit.rmdl`): the game's parts, each with its pivot at the
  world origin: `skater_board.glb` (pivot at the deck's centre), `skater_torso.glb` (torso, hood, head,
  hair, ears, nose, eyes, beanie; pivot at the hips), and limbs rebuilt straight down from their joint so
  their rest direction is -Z: `skater_arm.glb` (sleeve and hand), `skater_thigh.glb`, `skater_shin.glb`
  (with the cuff), `skater_shoe.glb` (pivot on the sole under the ankle). The scene bakes two copies of
  each limb; `game.as` poses them every frame (two-bone IK for the legs, knees towards the chest).

Budget: about 2000 triangles, over the hero class's 800 because every box is chamfered (a chamfered box
is 44 triangles); splats are sampled by area, so this costs nothing in the blob.

## Assumptions
- The sheet draws the board 1.16 m long and 0.38 m wide (the brief said 0.9 x 0.26): the sheet leads.
- The sheet draws a big chibi head (0.48 m wide with the beanie): kept, it is what reads at 25 pixels.
- The hoodie's front pocket is a shade, not a shape: not modelled (proud by less than a spacing).
- Hair shows only at the sides and back under the beanie, as on the sheet; the dark-brown hair is the
  wood ramp's `#71413b`, the nearest AAP-64 colour to the sheet's (the brief did not list it).
- The top panel draws the sleeves spreading wide beside the beanie; the model's arms hang by the body
  (the front and back views lead), which costs the top view some hoodie colour share.

## Gate record (generated-sheet tier, chosen before the build: form IoU >= 0.75, aspect drift <= 0.08;
## splat IoU >= 0.70, splat drift <= 0.08, colour drift <= 0.25)
Form, hedra views vs refs (elevation 0), IoU / aspect drift:

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.840 / 0.000 | 0.815 / 0.072 | 0.831 / 0.000 | 0.866 / 0.048 | passes; the right view a little narrow at the chest |
| p2 v2 | 0.832 / 0.000 | 0.826 / 0.072 | 0.822 / 0.000 | 0.854 / 0.048 | torso 0.285 deep, deck 0.38 wide |
| **p2 v3** | **0.836 / 0.000** | **0.816 / 0.010** | **0.822 / 0.000** | **0.874 / 0.031** | beanie octagon with corners on the axes (0.50 deep in profile, as drawn); ears and nose exaggerated |

Splats, albedo (`lookdev/skater.bin`, spacing 0.055, skin/shoes/hair 0.045, deck 0.04, wheels and
trucks 0.035), IoU / aspect drift / colour drift:

| Bake | front | right | back | top | |
|---|---|---|---|---|---|
| p2 (`skater.glb`), views from 5 / 85 degrees | 0.812 / 0.023 / 0.14 | 0.807 / **0.107** / 0.14 | 0.810 / 0.021 / 0.13 | 0.844 / **0.200** / **0.26** | fails: the discs reach a radius past the beanie and the board, the profile 12 % too wide |
| p3 (`skater_fit.glb`), views from 5 / 85 degrees | 0.818 / 0.013 / 0.13 | 0.792 / 0.023 / 0.12 | 0.826 / 0.011 / 0.10 | 0.823 / **0.165** / 0.23 | the top still fails: the renderer's pitch clamp draws the top from 85 degrees, which adds 1.67 m x sin 5 = 0.15 m of the tall figure's height to its depth |
| **p3, exact views (`--arg pitchMin=0 --arg pitchMax=90`)** | **0.817 / 0.013 / 0.14** | **0.798 / 0.033 / 0.13** | **0.826 / 0.011 / 0.12** | **0.851 / 0.077 / 0.24** | passes (modeling.md, "the gate's real angles": exact views for a tall figure) |

No waivers. The top view's colour drift (0.24) sits near the limit for the reason under Assumptions
(the sheet's sleeves). `hedra inspect check`: ngons on the beanie's cylinder and cone caps (harmless,
triangulated on export). The bake marks the eyes, trucks and wheels `specks` (single dots and dashes at
the scene's texel, on purpose).

Goldens: `goldens/skater` (framed) and `goldens/skater@scene` (`--texel 0.0588`, `--size 120`), lit like
the scene (`--arg sunYaw=-50 --arg sunPitch=50 --arg keyLight=0.42 --arg highlight=0.85 --arg
shadeSteps=1`, `--real-sky`). The sheet is not reviewed by a person yet (`reviewed: false`).
