# Asset: frog (hero character, game-driven)
Concept: ../../art/frog/sheet.v1.png (Sweetie 16 colours), refs cut to ../../art/frog/refs/.
Up Z, facing -Y; origin on the ground under the body. In the scene: scale 1.4, a game bone (`frog`).

Scale: snout to rump 0.60 m = 532 px in the right panel (887 px a metre).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Back (head and back) | 0.41 x 0.58 x 0.13, front top edge lowered 0.06 (the head slopes to the mouth), rump edge pulled in | z 0.245..0.375, y -0.31..0.27 | Skin (frog, #a7f070) |
| Lower body | 0.34 x 0.44 x 0.21 | z 0.04..0.25 | Skin |
| Throat | 0.30 x 0.16 x 0.21 | front, z 0.035..0.245 | Belly (cream, #ffcd75) |
| Eyes | ico-spheres r 0.066 | x +-0.113, y -0.17, z 0.38 | Eye (cream, #ffcd75), spacing 0.05 in the scene |
| Pupils | r 0.036 | in front of the eyes | Pupil (stone, #1a1c2c), specks |
| Thighs | faceted ellipsoids 0.18 x 0.32 x 0.26 | x +-0.225, y 0.13, z 0.15 | Skin |
| Arms | 0.08 x 0.08 x 0.2 (sheet 0.06: thickened, the bake starved them) | x +-0.125, y -0.16 | Skin |
| Hands, feet | 0.13 x 0.11 x 0.045; 0.17 x 0.22 x 0.045 | on the ground | Feet (frog, #38b764), spacing 0.056 in the scene |

## Assumptions
- The sheet's teal mouth line (a 0.02 m stripe) is below two splats: dropped; the ink between head and throat draws it.
- The top view is drawn about 10 % smaller than the side views (its width 549 px vs 606): front and right lead.

## Splat fit (p3_splat_fit.txt)
At the scene's spacing the thin foot tips (the widest parts) erode and the eyes and back grow a radius up:
the p2 frog baked narrow and tall (splat aspect drift 0.135 back, 0.127 top). p3 widens it 6 % and lowers it
3 % about the ground (1.12 x 0.94 overshot to 0.095). The mesh gate is taken on p2, the splat gate on p3.

## Gate record (generated-sheet tier, chosen before the build)
- p1 blockout: IoU 0.892 / 0.771 / 0.890 / 0.794 (front / right / back / top), aspect drift <= 0.038 (pass, `--min-iou 0.75`).
- p2 form: **IoU 0.885 / 0.770 / 0.883 / 0.794, aspect drift 0.009 / 0.038 / 0.006 / 0.038**.
- p4 splats, albedo, bench at the scene's density (0.057 m on the unscaled model = 0.08 at scale 1.4):
  **IoU 0.799 / 0.798 / 0.777 / 0.838, aspect drift 0.032 / 0.068 / 0.004 / 0.045, colour drift 0.03 / 0.01 / 0.07 / 0.05**
  (`--min-iou 0.7 --max-aspect-drift 0.08`). No waivers.
- Goldens: `goldens/frog` (framed), `goldens/frog@scene` (texel 0.039 on the bench = the scene's 0.054 / 1.4).
