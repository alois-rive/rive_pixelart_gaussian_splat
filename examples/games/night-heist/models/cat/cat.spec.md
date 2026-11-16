# Asset: cat (hero, the player character; game-driven)
Concept: ../../art/cat/sheet.v1.png (Cyclope6 colours), refs cut to ../../art/cat/refs/ (no flips: the
sheet follows the brief: right view faces left, top view head at the bottom).
Up Z, facing -Y; origin on the ground under the body's centre.
Scale from the RIGHT panel: nose to rump 452 px for 1.0 m -> 452 px per metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Torso | box 0.45 x 0.76 x 0.33, edges chamfered 0.07, the chest's lower front pulled back 0.05 | x 0, y -0.26..0.50, z 0.25..0.58 | Fur (fur, wine `#631b34`) |
| Head | box 0.41 x 0.365 x 0.27, chamfered 0.06 | y -0.445..-0.08, z 0.43..0.70 | Fur |
| Muzzle | 4-sided frustum r 0.115 -> 0.035, 0.12 long, pointing forward | y -0.46, z 0.475 | Slate (metal, `#32535f`) |
| Ears | 4-sided pyramids r 0.105, 0.17 tall, leaning out 8 degrees | x +-0.14, y -0.24, tips z 0.86 | Fur |
| Eyes | 6-sided discs r 0.065, squashed to 0.62 | x +-0.095, y -0.455, z 0.585 | Eye (light, mint, unlit) |
| Legs | boxes 0.15 x 0.15, z 0.05..0.34 | x +-0.13, y -0.13 (front), 0.37 (back) | Fur |
| Paws | boxes 0.17 x 0.2 x 0.07 | under each leg, 0.015 forward | Slate |
| Tail | column 0.11 square, 0.43 tall, leaning back 12 degrees, from the rump (root 0, 0.44, 0.55); a bar over the top curling forward (y 0.33..0.585, z 0.89..1.0); the tip hanging (y 0.31..0.40, z 0.80..0.93) | | Fur |

`make_cat.py` writes the four phases:
- `p1_blockout.txt`: every part at the spec's sizes, scale applied.
- `p2_form.txt`: chamfers, the chest, materials, flat shading, exports `cat.glb` (the gated form).
- `p3_splat_fit.txt` (run `--no-save --to cat_fit.rmdl`, so `cat.rmdl` stays the gated form): narrows
  the parts for the splats (torso and head x 0.8, ears 0.85 and 15 % taller, legs 0.75, paws 0.8),
  exports `cat_fit.glb`, which the bench and the scene bake.
- `p4_parts.txt` (run `--no-save` on `cat_fit.rmdl`): the game's parts `cat_body.glb`, `cat_tail.glb`
  (origin at the tail's root) and `cat_leg.glb` (origin at the hip; four copies in the scene).

## Assumptions
- The views disagree on the body's length: the top view draws it 0.77 m nose to rump, the right view
  1.0 m. Front and right lead (the game's 42 degree camera sees the cat's sides and back most).
- The tail curls forward over the back in the right view, sideways in the front view and backwards in
  the top view: the right view leads (a curl in the cat's own plane), so the front and top views lose a
  little IoU at the tail.
- The sheet's top view shows the eyes and the face (drawn slightly from the front); not modelled.
- No whiskers, no mouth: below two splats at the scene's texel.

## Gate record (generated-sheet tier, chosen before the build: form IoU >= 0.75, aspect drift <= 0.08; splat IoU >= 0.70, splat drift <= 0.08, colour drift <= 0.25)
Form, hedra views vs refs (elevation 0), IoU / aspect drift:

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.856 / 0.034 | **0.701** / 0.016 | 0.861 / 0.037 | 0.772 / 0.017 | fails right: the tail stood straight up at the rump; the sheet's leans back and curls forward past it |
| p1 v2 | 0.878 / 0.034 | 0.864 / 0.057 | 0.884 / 0.037 | 0.793 / **0.092** | tail leaning back, belly lower, head higher, legs 0.15; fails top: too long for its width |
| **p1 v3** | **0.875 / 0.008** | **0.872 / 0.029** | **0.882 / 0.006** | **0.792 / 0.017** | torso 0.45 wide, muzzle 0.015 back, tail lean 12 degrees |
| **p2** | **0.873 / 0.008** | **0.870 / 0.029** | **0.879 / 0.006** | **0.800 / 0.017** | chamfers, chest, materials |

Splats, albedo (`lookdev/cat.bin`, spacing 0.0565 = the scene's 0.076 at scale 1.35), IoU / aspect
drift / colour drift:

| Bake | front | right | back | top | |
|---|---|---|---|---|---|
| p2 (`cat.glb`) | 0.803 / 0.068 / 0.13 | 0.744 / 0.006 / 0.17 | 0.787 / **0.114** / 0.18 | 0.836 / **0.113** / 0.07 | fails: the discs reach a radius past every side, the widths come out 25 % too wide |
| **p3 (`cat_fit.glb`)** | **0.778 / 0.016 / 0.12** | **0.755 / 0.024 / 0.17** | **0.777 / 0.058 / 0.18** | **0.832 / 0.022 / 0.05** | passes: narrowed for the splats (modeling.md, "when the mesh gate and the splat gate disagree") |

No waivers. `hedra inspect check`: ngons on the eye discs (cylinder caps, harmless, triangulated on
export). The bake marks the eyes `specks` (a mint dot or two each at the scene's texel, on purpose).

Goldens: `goldens/cat` (framed) and `goldens/cat@scene` (`--texel 0.0436` = the scene's 0.0588 at scale
1.35, `--size 120`), lit like the scene (`--arg sunYaw=-35 --arg sunPitch=55`, `--real-sky`). The bench
is baked with `art/palette_bench.json` (the roof's teal as sky): on the scene palette's plum sky the
cat's shaded faces, plum too, vanish. The sheet is not reviewed by a person yet (`reviewed: false`).
