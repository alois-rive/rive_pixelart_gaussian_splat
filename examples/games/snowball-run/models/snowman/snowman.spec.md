# Asset: snowman (hero prop, game-driven)
Concept: ../../art/snowman/sheet.v1.png (Ice Cream GB colours), refs cut to ../../art/snowman/refs/ (no
flips: the sheet follows the brief's orientation). Up Z, facing -Y; origin on the ground under the
bottom ball. Total height 2.0 m. Scale from the front panel: 477 px = 2.0 m -> 238 px per metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Bottom ball | ico r 0.5 (80 faces), scaled 1.03 x 1.03 x 0.86 | centre z 0.42 | Snow (snow, cream) |
| Middle ball | ico r 0.4, scaled 0.96 x 0.96 x 0.82 | centre z 0.98 | Snow |
| Head | ico r 0.29 | centre z 1.45 | Snow |
| Hat brim / crown | 8-gon r 0.3 x 0.05 / r 0.18 x 0.27 | z 1.71 / 1.73-2.0 | Plum (bark, plum) |
| Hat band | 8-gon r 0.19 x 0.07 | z 1.775 | Coral (accent, coral) |
| Nose | cone r 0.09 x 0.26, pointing -Y | z 1.43 | Coral |
| Eyes, 3 buttons | ico r 0.05 | the head's and middle ball's front | Plum |
| Scarf | torus R 0.25 r 0.075 | z 1.235 | Coral |
| Scarf tail | 0.13 x 0.07 x 0.36, on the snowman's right (-X) front | (-0.2, -0.24, 1.03) | Coral |
| Arms | 0.09 x 0.09 x 0.56, 29 degrees up | tips at x +-0.8, z 1.26 | Plum |
| Twigs | 0.07 x 0.07 x 0.2 at the tips | | Plum |

`p1_blockout.txt` (balls, hat, nose, arms), `p2_form.txt` (materials, band, scarf, eyes, buttons, twigs,
export). Bake: spacing 0.11 (the scene's), Plum 0.08 (specks: coal and twigs are meant to be single
pixels), Coral 0.065 (the nose).

## Gate record (generated-sheet tier, chosen before the build: form IoU >= 0.75, splat IoU >= 0.70, drift <= 0.08, colour <= 0.25)
| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.881 / 0.004 | 0.886 / 0.020 | 0.883 / 0.006 | 0.856 / 0.041 | |
| p2 v1 | 0.862 / 0.029 | 0.902 / 0.020 | 0.863 / 0.031 | 0.842 / 0.063 | bottom ball too narrow (magenta at its sides) |
| **p2 v2** | **0.873 / 0.029** | **0.897 / 0.029** | **0.874 / 0.031** | **0.870 / 0.052** | bottom ball 1.03 wide; nose r 0.09 (it baked as specks) |

Splats albedo (`lookdev/snowman.bin`): IoU 0.816 / 0.890 / 0.813 / 0.843, aspect drift 0.027 / 0.066 /
0.031 / 0.029, colour drift 0.06 / 0.05 / 0.05 / 0.04. (A longer nose, 0.30 m, pushed the right view's
splat drift to 0.090: kept at 0.26.) With 4 colours the colour drift says little; IoU and the eye lead.

Goldens: `goldens/snowman` (framed) and `goldens/snowman@scene` (`--texel 0.075 --size 120`), lit like
the scene (`--arg sunYaw=-55 sunPitch=30 keyLight=0.42 highlight=0.85 splatDither=0 bandDither=0.45`,
`--real-sky`). The sheet is not reviewed by a person yet (`reviewed: false`).
