# Asset: mole (hero character, game-driven)
Concept: ../../art/mole/sheet.v1.png (Steam Lords colours), refs cut to ../../art/mole/refs/.
Up Z, facing -Y; origin on the ground (where it leaves the hole) under its centre. In the scene: scale
1.3, a pool of 9 game bones.

Scale: 0.49 m wide at the bottom = 420 px in the front panel (840 px a metre).

## Parts (metres, before the splat fit)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Body | faceted egg (UV sphere 10 x 8) 0.49 x 0.47 x 0.78, centre z 0.12, cut flat at z 0 | | Fur (fur, #433a60) |
| Belly | the body's front faces below z 0.2 within x +-0.16 | | Belly (fur, #4f5277) |
| Snout | 6-sided cone r 0.07 -> 0.035, 0.13 long, pointing -Y | y -0.235, z 0.33 | Snout (snout, #775c4f) |
| Nose | ico-sphere r 0.056 | y -0.31, z 0.31 | Nose (snout, #a19f7c), spacing 0.045 in the scene |
| Paws | 0.16 x 0.1 x 0.12, turned 20 degrees outward | x +-0.165, y -0.17, z 0.24 | Snout |
| Claws (6) | 4-sided cones r 0.024, 0.07 tall | on the paws' tops | Claw (steel, #c0d1cc), specks |
| Eyes | r 0.024 | x +-0.05, y -0.16, z 0.415 | Eye (fur, #170e19), specks |

## Assumptions
- The sheet's nose sits at 0.29 m in the front view and 0.33 m in the side view: 0.31 taken.
- In the scene the fur and belly bake one ramp step lighter (`"step": 1`) so the mole reads on the dark
  soil at dusk; the bench (and the colour gate) keep the sheet's colours.

## Splat fit (p3_splat_fit.txt)
At the scene's spacing the snout's tip erodes and the dome grows a radius up: the p2 mole baked short in
depth and tall (side splat aspect drift 0.096). p3 lengthens it 9 % front to back and lowers it 4 % about
the ground. The mesh gate is taken on p2, the splat gate on p3.

## Gate record (generated-sheet tier, chosen before the build)
- p1 blockout: IoU 0.942 / 0.912 / 0.940 / 0.924, aspect drift <= 0.028.
- p2 form: **IoU 0.948 / 0.911 / 0.951 / 0.924, aspect drift 0.028 / 0.009 / 0.021 / 0.017** (`--min-iou 0.75`).
- p4 splats, albedo, bench at the scene's density (0.046 m on the unscaled model = 0.06 at scale 1.3):
  **IoU 0.886 / 0.879 / 0.885 / 0.870, aspect drift 0.032 / 0.044 / 0.026 / 0.041, colour drift
  0.07 / 0.19 / 0.18 / 0.16** (`--min-iou 0.7 --max-aspect-drift 0.08`). No waivers.
- Goldens: `goldens/mole` (framed), `goldens/mole@scene` (texel 0.027 on the bench = the scene's 0.035 / 1.3).
