# Asset: knight (hero, the player character; one rigid game bone)
Concept: ../../art/knight/sheet.v1.png (Rust Gold 8 colours), refs cut to ../../art/knight/refs/ (no
flips). Up Z, facing -Y; origin on the ground between the feet; the knight's right hand (sword) at
-X, its left (shield) at +X. Total height 1.18 m (1.77 m in the scene, baked at scale 1.5).
Scale from the FRONT panel: plume top (y 15) to boot soles (y 492) = 477 px for 1.19 m -> 400 px per
metre; the right and back panels share the ground line and the scale.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Boots | 0.24 x 0.32 x 0.13 each | x +-0.19, y -0.04, z 0..0.13 | Leather (rock, #331c17) |
| Legs | 0.17 x 0.19 x 0.24 | x +-0.165, z 0.12..0.36 | Armour (steel, #725956) |
| Torso | 8-sided barrel r 0.25, depth squashed to 0.78, 0.36 tall | z 0.32..0.68 | Armour |
| Tabard | 0.4 x 0.07 x 0.44, front and back | y -+0.19, z 0.23..0.67 | Tabard (gold, #ac6b26) |
| Pauldrons | ico-spheres r 0.14 (z x 0.85) | x +-0.29, z 0.6 | Armour |
| Arms, gloves | 0.14 x 0.15 x 0.24; 0.15 x 0.16 x 0.13 | x +-0.31, z 0.34..0.58; gloves z 0.31 | Armour; Leather |
| Helm | 10-sided r 0.28, 0.3 tall, a 10-sided dome to r 0.14, 0.17 tall | z 0.62..1.09 | Armour |
| Visor slit | 0.36 x 0.06 x 0.065, proud of the helm front | y -0.265, z 0.81 | Slit (steel, #202020) |
| Plume | 0.11 x 0.42 x 0.16, top edges bevelled 0.04 | z 1.02..1.18 | Gold (gold, #f6cd26) |
| Sword | blade 0.09 x 0.06 x 0.49 from the right glove (-0.33, -0.06, 0.3) to the tip (-0.47, -0.40, 0.02); guard 0.22 x 0.07 x 0.06 | | Blade (steel, #bb7f57); Gold |
| Shield | 10-sided disc r 0.22, 0.06 thick, facing +X turned 30 degrees to the front; both faces inset 0.06 | (0.42, -0.02, 0.38) | Gold rim, Tabard face |

`make_knight.py` writes `p1_blockout.txt` (the sword's Euler angles are computed); `p2_form.txt`
assigns materials, insets the shield, bevels the plume, joins everything into one `Knight` and
exports `knight.glb` (392 triangles, 6 materials).

## Assumptions
- The sheet's RIGHT panel shows the knight's own right side (sword hand towards the camera, shield
  hidden) facing left, which is a mirror image; hedra's `right` view looks along -X and sees the
  knight's left (shield) side facing left. The silhouettes still compare (the shield sits inside the
  body's outline from the side); the gate is run without flips.
- The sheet's TOP panel is drawn from the front at a steep angle, not straight down: the visor slit
  and the helm's front faces show, which adds about 0.15 m of depth, and it draws the shield as a thin
  bar while the front and back panels draw it turned towards the front. Front, right and back lead;
  the top view's aspect gets a waiver (below).
- The sword blade is 0.09 x 0.06 (the sheet's 0.08 m blade, thickened to survive at the bake's
  spacing).

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.872 / drift 0.042 | 0.809 / 0.029 | 0.840 / 0.083 | 0.761 / 0.297 | sword tip 0.5 m out and 0.36 forward, shield turned 25 degrees: too wide |
| p1 v2 | 0.862 / 0.044 | 0.778 / 0.096 | 0.877 / 0.002 | 0.804 / 0.125 | sword tip 0.46 forward, shield 12 degrees: right view too deep |
| p1 v3 | 0.861 / 0.044 | 0.811 / 0.027 | 0.876 / 0.002 | 0.819 / 0.191 | sword tip 0.40 forward (the right panel leads) |
| p2 v1 | 0.859 / 0.044 | 0.814 / 0.027 | 0.874 / 0.002 | 0.819 / 0.191 | materials, joins; splats: front aspect drift 0.105 (the edge-on shield thins out) |
| p2 v2 | 0.810 / 0.062 | 0.770 / 0.060 | 0.840 / 0.019 | 0.793 / 0.151 | sword tip extended 0.07: worse (the tip went below the ground), reverted |
| **p2 v3** | **0.843 / 0.032** | **0.810 / 0.027** | **0.803 / 0.072** | 0.773 / **0.249** | shield turned 30 degrees towards the front and out to x 0.42, as the front and back panels draw it |

Look, splats albedo (`lookdev/knight.bin`, spacing 0.044 = the scene's 0.065 at scale 1.5,
`--min-iou 0.7 --max-aspect-drift 0.08`): IoU 0.853 / 0.828 / 0.819 / 0.805, aspect drift 0.010 /
0.023 / 0.060 / 0.167, colour drift 0.04 / 0.12 / 0.06 / 0.13.

Waiver, top aspect (form 0.249, splats 0.167): the sheet's top panel is not a top view (see
Assumptions); its IoU passes (0.773 / 0.805).

Goldens: `goldens/knight` (framed), `goldens/knight@scene` (`--texel 0.05 --size 120`: the scene's
texel 0.075 at scale 1.5), lit like the scene (`--arg sunYaw=-35 --arg sunPitch=38`, `--real-sky`).
