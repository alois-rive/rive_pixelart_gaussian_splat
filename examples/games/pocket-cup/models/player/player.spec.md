# Asset: player (hero, a Bramblecombe footballer in the home kit)
Concept: ../../art/player/sheet.v1.png (Sheltzy32 colours; `reviewed: false`), refs cut to ../../art/player/refs/.
Up Z, facing -Y; origin on the ground under the body. 1.60 m tall, 0.89 m across the hanging arms.

Scale: 274 px a metre in every panel (the front view's 439 px from boot sole to hair top = 1.60 m). The
side views are straight orthographic: gate at elevation 0 (hedra) and at the renderer's 5 degrees (splats).

## Parts (metres; `make_player.py` holds the table and writes every command file)
| Part | Size (x, y, z) | Centre | Material (ramp, painted step) |
|---|---|---|---|
| Torso (shirt) | 0.41 x 0.26 x 0.44 | (0, 0, 0.93) | Shirt (coral, #ec614a) |
| Collar band | 0.30 x 0.22 x 0.05 | (0, 0, 1.165) | Trim (chalk, #cce2e1) |
| Shorts | 0.44 x 0.26 x 0.19 | (0, 0, 0.615) | Shorts (chalk, #cce2e1) |
| Head | 0.36 x 0.32 x 0.29 | (0, -0.02, 1.325) | Skin (skin, #ffa468) |
| Hair: top slab, back slab | 0.39 x 0.38 x 0.13; 0.39 x 0.09 x 0.28 | (0, 0, 1.535); (0, 0.145, 1.33) | Hair (wood, #683c34) |
| Eyes | 0.05 x 0.03 x 0.05, 1 cm proud | (+-0.085, -0.19, 1.40) | Eye (navy, #222a5c), `specks` (single art pixels) |
| Sleeves, arms, hands | 0.17 x 0.19 x 0.20; 0.13 x 0.15 x 0.36; 0.14 x 0.16 x 0.11 | x +-0.29, z 1.05 / 0.80 / 0.665, then tilted 12 degrees out about the shoulder (+-0.26, 0, 1.13) | Shirt; Skin; Skin |
| Captain's armband | 0.175 x 0.195 x 0.07 | on the LEFT (+X) arm at z 0.99, tilted with it | Band (gold, #ffda70) |
| Legs: knee, sock, boot | 0.16 x 0.19 x 0.29 (to the hip at 0.60); 0.16 x 0.19 x 0.20; 0.20 x 0.30 x 0.13 | x +-0.117: knee z 0.475, sock 0.23, boot 0.065 (toe 0.045 forward) | Skin; Sock (coral); Boot (boot, #38002c) |

## Assumptions
- The sheet's TOP panel disagrees with its RIGHT panel: from above the boots stick 0.12 m out past the head
  and the sleeves are 0.26 m deep, while the side view (and the front) put the toes under the face and the
  arms 0.16 m deep. Front and right lead; the top view gets a waiver (below).
- The hair's temple columns (front view, down to 1.37 m) are modelled as a flat top slab: one band less in
  the front view, invisible at the scene's 22 art pixels.
- 252 triangles. In the game the figure is three game bones: the body (everything but the legs,
  `body.txt` -> `player_body.glb`) and two copies of one leg (`leg.txt` -> `player_leg.glb`, origin at
  the hip, 0.60 m). Running, kicking, staggering, lunging and the keeper's dive are `place` /
  `placeScaled` with pitch and roll in `scene/game.as`, stepped at 12 fps; the body and legs take the
  same splat fit as the gated p3.
- Kits are ramps, not models: the scene bakes the same body and leg in four kits (scene.bake.json via
  `make_bake.py`: coral home, gold home keeper, sky away, violet away keeper; `"step"` puts each kit on
  the step it wants, since the coral the sheet paints snaps to a different step on other ramps).

## Gate record (generated-sheet tier, chosen before the build)
- p1 blockout (arms still straight): IoU 0.816 / 0.886 / 0.817 / 0.855, aspect drift 0.178 / 0.060 /
  0.178 / 0.141: the front, back and top fail on the width of the arms, as expected before p2 tilts them.
- p2 form (arms tilted 12 degrees out; one sign error first tilted them in: IoU 0.784): **IoU 0.881 /
  0.886 / 0.885 / 0.882, aspect drift 0.048 / 0.060 / 0.048 / 0.308** (`--min-iou 0.75`, drift <= 0.08).
  **Waiver: top aspect drift 0.308**: the sheet's top panel contradicts its right panel (Assumptions); its
  IoU passes.
- p4 splats, albedo, at the scene's spacing (0.06 m, ~0.9 texel): p2 baked as is was too fat in the
  narrow views (aspect drift 0.079 / **0.126** / **0.083** / 0.033: fail). p3 (`p3_splat_fit.txt`: x 0.96,
  depth 0.84, the gated p2 kept intact): **IoU 0.852 / 0.821 / 0.836 / 0.833, aspect drift 0.048 / 0.019 /
  0.043 / 0.053, colour drift 0.06 / 0.08 / 0.07 / 0.06** (`--min-iou 0.7`, drift <= 0.08). No other waiver.
- Goldens: `goldens/player` (framed), `goldens/player@scene` (texel 0.0662, 160 px), lit as the scene
  (sun yaw -35, pitch 52, key 0.4, highlight 0.85, shadeSteps 1).
