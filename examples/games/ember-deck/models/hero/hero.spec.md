# Asset: the Wick Knight (hero, the player's figure; three rigid game bones in the scene)
Concept: ../../art/hero/sheet.v1.png (Ink-Crimson colours), refs cut to ../../art/hero/refs/ with
`sheet_cut.py --flip top` (see Assumptions). Up Z, facing -Y; origin on the ground between the feet;
the knight's right hand (sword) at -X, its left (shield) at +X. Total height 1.80 m with the crest.
Scale from the FRONT panel: crest tip to boot soles = 465 px for 1.80 m -> 258 px per metre; the
right and back panels share the ground line and the scale.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Boots | 0.32 x 0.46 x 0.17 each | x +-0.23, y -0.08, z 0..0.17 | Dark (leather, #270022) |
| Legs | 0.25 x 0.26 x 0.34 | x +-0.22, z 0.15..0.49 | Plum (leather, #450327) |
| Waist | 8-sided ring r 0.30 (depth x 0.86), 0.12 tall | z 0.41..0.53 | Steel (steel, #0098db) |
| Torso | 8-sided frustum r 0.29 -> 0.34 (depth x 0.84), 0.5 tall | z 0.46..0.96 | Steel |
| Pauldrons | ico-spheres r 0.21 (z x 0.85) | x +-0.37, z 0.92 | Steel |
| Cape | 0.62 x 0.07 x 0.74, tilted 14 degrees (its foot kicks back) | y 0.33, z 0.23..0.97 | Cape (cloth, #9c173b) |
| Helm | 8-sided frustum r 0.30 -> 0.26, 0.48 tall | z 0.96..1.44 | Steel |
| Visor | a T: bar 0.30 x 0.07 x 0.075 and stem 0.085 x 0.07 x 0.16, proud of the helm front | y -0.27, z 1.13..1.31 | Dark |
| Crest | a 4-sided flame: 0.12 widening to r 0.11, then a 0.24 point (depth x 0.55) | z 1.44..1.80 | Crest (cloth/flame, #ff0546) |
| Sword arm | arm 0.18 x 0.20 x 0.26, fist 0.20 x 0.22 x 0.20 at hip height, guard 0.27 x 0.09 x 0.07, blade 0.13 x 0.055 x 0.60 straight up, a 0.14 tip | x -0.43..-0.5, z 0.47..1.48 | Steel, Plum, Dark, Blade (steel, #0ce6f2) |
| Shield arm | arm and fist as above; a 12-sided buckler r 0.33, 0.10 thick, facing +X, both faces inset 0.07 | buckler at (0.60, -0.07, 0.64) | Steel, Plum, Blade (rim), Cape (face) |

`make_hero.py` writes `p1_blockout.txt` and `p3_parts.txt`; `p2_form.txt` assigns the materials,
insets the buckler, joins everything into three objects (HeroBody, SwordArm, ShieldArm) and exports
`hero.glb` (the whole knight, 396 triangles, 6 materials) for the gates. `p3_parts.txt` (run with
`--no-save`) moves each arm's origin to its shoulder (-+0.40, 0, 0.90), puts it at the world origin and
exports `hero_body.glb`, `hero_armr.glb`, `hero_arml.glb`: the game turns each arm about its shoulder
(swing, shield raise) and places it with `api.transform` on the body.

## Assumptions
- The sheet's TOP panel is mirrored against its own FRONT panel: it draws the shield on the image's
  left and the sword hilt on the right, while (front towards the bottom) the knight's left hand must
  be on the image's right, as the front panel shows. The cut flips the top view (`--flip top`); the
  knight is otherwise symmetric, so the mirror only puts the hands back on their sides.
- The sheet's RIGHT panel shows the buckler face-on and forward of the body, and the cape kicking
  back behind the legs: the buckler sits at y -0.07 and the cape is tilted 14 degrees.
- The buckler is 0.66 m across (the sheet's size, not the brief's 0.5 m); the blade 0.13 m wide (the
  sheet's 0.135), which is thick enough at the scene's spacing.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`): IoU / aspect drift.

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.880 / 0.001 | 0.799 / **0.273** | 0.877 / 0.007 | **0.740 / 0.257** | the top ref was mirrored; the model too shallow front to back |
| p1 v2 | 0.886 / 0.001 | 0.772 / 0.060 | 0.883 / 0.007 | 0.779 / 0.006 | `--flip top`; torso depth x 0.84, boots longer and forward, cape back, buckler forward: the cape hung detached in the right view |
| **p1 v3** | **0.886 / 0.001** | **0.819 / 0.012** | **0.883 / 0.007** | **0.796 / 0.035** | the cape tilted the other way, hanging from the shoulders |
| p2 | 0.886 / 0.001 | 0.819 / 0.012 | 0.883 / 0.007 | 0.796 / 0.035 | materials, inset, joins (the silhouette unchanged) |

Look, splats albedo (`lookdev/hero.bin`, spacing 0.055 = the scene's; blade and crest 0.04,
`--min-iou 0.7 --max-aspect-drift 0.08`): IoU 0.863 / 0.811 / 0.853 / 0.831, aspect drift 0.018 /
0.052 / 0.039 / 0.061, colour drift 0.13 / 0.12 / 0.11 / 0.12. Every view passes: no waivers.

`inspect check`: the buckler's caps are ngons (harmless) and HeroBody has 8 duplicate vertices where
the crest's two cones meet (two touching shells after the join; the export and the bake do not care).

In the scene (`scene.bake.json`) the boots and legs are lifted one step on the cloth ramp (`"step": 1`)
so they read against the dark floor, and the crest is unlit (a flame); the bench keeps the sheet's
colours for the gates.

Goldens: `goldens/hero` (framed), `goldens/hero@scene` (`--texel 0.0441 --size 120`), lit like the
scene (`--arg sunYaw=-35 --arg sunPitch=42 --arg keyLight=0.4 --arg highlight=0.85 --arg shadeSteps=1`,
`--real-sky`).
