# Asset: Pip (hero, game-driven, four bones)
Concept: ../../art/pip/sheet.v2.png (DawnBringer 32 colours), refs cut to ../../art/pip/refs/ (no flips:
the sheet follows the brief's orientation line). Sheet v1 produced no image: Codex's image tool
refused it at its output moderation stage ("moderation_blocked", category "other"; the brief called
Pip "a small cute radish sprite"); v2 reworded the first line ("a toy-like game mascot shaped like a
round radish vegetable ... for a children's garden game") and changed nothing else. The record stays
`reviewed: false` until a person approves the sheet.
Up Z, facing -Y (the eyes); origin on the ground between the boots. 1.02 m from the soles to the leaf tips.
Scale from the FRONT panel: the bulb's 264 px are 0.62 m -> 426 px/m.

## Parts (metres)
| Part | Size | Position (centre) | Material (ramp, step) |
|---|---|---|---|
| Bulb | 10-sided sphere 0.62 x 0.60 x 0.55, bottom 0.18 up | (0, 0, 0.455) | Bulb (radish, #d95763); faces under z 0.31 Cream (cream, #eec39a) |
| Root | 5-sided cone r 0.07, 0.1 long, pointing down | (0, 0, 0.16) | Cream |
| Eyes | 0.075 x 0.06 x 0.115 each, 0.03 proud of the bulb | (+-0.117, -0.27, 0.48) | Eye (ink, #222034) |
| Stem | 6-sided cylinder r 0.045, 0.1 tall | (0, 0, 0.76) | Stem (sprout, #6abe30) |
| Leaves | 4-sided ellipsoids 0.17 x 0.10 x 0.43, tilted 60 deg out and 25 deg back | (+-0.185, 0.07, 0.885) | Leaf (sprout, #99e550) |
| Legs | 6-sided cylinders r 0.028, 0.12 tall | (+-0.128, 0, 0.16) | Cream |
| Boots | 0.17 x 0.22 x 0.11, toes forward | (+-0.128, -0.07, 0.055) | Boot (ink, #45283c) |

Objects (each a game bone, `p3_parts.txt` exports them with their pivots at the hedra origin):
Body (bulb, root, eyes; pivot on the ground between the boots), Sprout (stem, leaves; pivot at the
top of the bulb, 0.76 m), FootR and FootL (leg and boot; pivot at the boot's sole; one GLB used twice).
`p1_blockout.txt` (primitives), `p2_form.txt` (materials, the cream lower third, the four joined
objects, `pip.glb` for the gates and the bench), `p3_parts.txt` (run with `--no-save`: the part GLBs).

## Assumptions
- The views disagree on the leaves: the RIGHT view leans them back by about 0.23 m at the tip, the
  TOP view by about 0.1 m. FRONT and TOP lead (tilted 25 degrees back); the right view's IoU stays the
  lowest (0.777) for it.
- Boots sit 0.04 m further forward than the front view suggests: the RIGHT view shows the toes
  well ahead of the bulb.
- The game shows Pip from the side at 25 art pixels: the eyes are one dark cluster at the bulb's
  front edge, the leaves overlap into one tuft. The idle pose turns Pip 35 degrees to the camera so
  both eyes read.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`, elevation 0): IoU / aspect drift

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.861 / 0.063 | 0.770 / 0.058 | 0.857 / 0.063 | 0.916 / 0.009 | leaves thin seen from the side and the top, boots centred under the bulb |
| **p1 v2 = p2 (final)** | **0.859 / 0.007** | **0.777 / 0.022** | **0.856 / 0.007** | **0.900 / 0.033** | leaves thicker (0.10), spread 60 deg, tilted 25 back; boots 0.04 forward |

Look, splats albedo (`lookdev/pip.bin`; `--min-iou 0.7 --max-aspect-drift 0.08`), IoU / aspect drift /
colour drift (front, right, back, top):

| Bake | front | right | back | top |
|---|---|---|---|---|
| 0.05, eyes 0.03, leaves 0.04 | 0.791 / 0.023 / 0.09 | 0.763 / 0.050 / 0.13 | 0.796 / 0.012 / 0.09 | 0.888 / 0.024 / 0.10 (legs warned as specks: 8 and 6 splats) |
| + cream 0.035 | 0.790 / 0.005 / 0.10 | 0.750 / 0.021 / 0.13 | 0.774 / 0.073 / 0.10 | **FAIL** 0.898 / 0.094 / 0.11 (the leaf tips eroded) |
| **+ leaves 0.03 (final, the scene's spacings)** | **0.793 / 0.020 / 0.10** | **0.741 / 0.029 / 0.13** | **0.794 / 0.002 / 0.10** | **0.895 / 0.025 / 0.12** |

No waivers: every view passes its tier. `hedra inspect check`: only ngons (the cylinder caps).

Goldens: `goldens/pip` (framed), `goldens/pip@scene` (`--texel 0.04 --size 160`: the scene's texel,
bake scale 1), lit like the scene (`--arg sunYaw=-35 sunPitch=45 keyLight=0.45 highlight=0.85
shadeSteps=1 bandDither=0.4`, `--real-sky`).
