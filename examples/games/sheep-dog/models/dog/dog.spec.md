# Asset: dog (hero, the player)
Concept: ../../art/dog/sheet.v1.png (DawnBringer 16 colours), refs cut to ../../art/dog/refs/.
Up Z, facing -Y; origin on the ground under the body's centre. Nose to tail tip 1.16 m, ear tip 0.88 m.

Scale: the side and front panels at 520 px a metre (ear tip 456 px above the feet = 0.877 m). The top
panel is drawn smaller (411 px a metre) but in proportion (aspect 2.52 against the side's 603 / 246 = 2.45).
The views are straight orthographic: gate at elevation 0.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Body | 0.40 x 0.60 x 0.33 | centre (0, 0, 0.39) | Fur (fur, #d27d2c) |
| Head | two halves 0.22 x 0.32 x 0.314 | centre (+-0.11, -0.31, 0.613) | Fur; the +X half's front face Cream (the patch over the dog's left eye) |
| Snout, nose | 0.19 x 0.15 x 0.154; 0.09 x 0.04 x 0.06 | (0, -0.53, 0.533); (0, -0.615, 0.585) | Cream (cream, #deeed6); Dark (face, #140c1c) |
| Bib | 0.47 x 0.25 x 0.33, its bottom edge pinched to 0.12 wide | (0, -0.28, 0.375) | Cream |
| Ears | 4-sided cones r 0.11, 0.18 tall, leaning out 12 degrees | (+-0.17, -0.30, 0.80) | Fur |
| Legs, paws | 0.12 x 0.12 x 0.15 on 0.125 x 0.125 x 0.08 paws | x +-0.125, y -0.256 / 0.202 | Fur; Cream |
| Tail, tip | 0.13 x 0.13 x 0.27 (tapering to 0.8), 0.11 x 0.11 x 0.13 tip, at 45 degrees back and up | from (0, 0.29, 0.52) | Fur; Cream |
| Eyes | 0.07 x 0.04 x 0.07, 3 cm proud of the face | (+-0.105, -0.48, 0.675) | Dark, spacing 0.04, `specks` (meant as single art pixels) |

## Assumptions
- The sheet's front view is wider (bib 0.47 m) than its top view at the same scale would say; the side and
  front lead (the top is drawn smaller but in proportion).
- 228 triangles. In the game the dog is a rigid game bone: the gallop, skid and panting are `place` /
  `placeScaled` in `scene/game.as`, not baked clips.

## Gate record (generated-sheet tier, chosen before the build)
- p1 blockout: IoU 0.880 / 0.856 / 0.877 / 0.901, aspect drift 0.006 / 0.056 / 0.004 / 0.039 (pass).
- p2 form (bigger ears leaning out, bib pinched, tail tapered, eyes, patch): **IoU 0.900 / 0.865 / 0.894 /
  0.902, aspect drift 0.024 / 0.044 / 0.013 / 0.039** (`--min-iou 0.75`, drift <= 0.08).
- p4 splats, albedo: v1 at scale 0.75 and spacing 0.07 starved (362 splats, legs read as specks; aspect drift
  0.114 / 0.064 / 0.101 / 0.163: fail). v2 at full size and spacing 0.05 (1.2 texels in the scene, as baked
  there): **IoU 0.825 / 0.781 / 0.846 / 0.874, aspect drift 0.064 / 0.015 / 0.048 / 0.064, colour drift
  0.14 / 0.10 / 0.12 / 0.07** (`--min-iou 0.7`). No waivers.
- Goldens: `goldens/dog` (framed), `goldens/dog@scene` (texel 0.042, 160 px), lit as the scene (sun yaw -40,
  pitch 50).
