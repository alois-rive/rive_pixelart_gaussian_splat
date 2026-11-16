# Asset: frog (hero, the choir's singers; game-driven)
Concept: ../../art/frog/sheet.v1.png (Eggy 15 colours), refs cut to ../../art/frog/refs/ (no flips: the
sheet follows the brief: the right view faces left, the top view has the face at the bottom).
Up Z, facing -Y; origin on the ground under the body (the pivot the game squashes and tilts it about).
Scale from the FRONT panel: 520 px across the haunches for 0.90 m -> 578 px per metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Body | 8 x 6 uv-sphere, half extents 0.32 x 0.38 x 0.30 | centre (0, 0.04, 0.27) | Skin (frog_*, #3c9b87 for the gated green) |
| Head | uv-sphere, half extents 0.29 x 0.23 x 0.13 | centre (0, -0.13, 0.50) | Skin |
| Belly | uv-sphere, half extents 0.21 x 0.20 x 0.25, 0.04 proud of the body's front | centre (0, -0.19, 0.27) | Belly (belly, #ddd4cb) |
| Eyes | uv-spheres r 0.095 | (+-0.175, -0.135, 0.625) | Skin |
| Irises | uv-spheres r 0.075 squashed to 0.7 deep | 0.045 in front of each eye | Eye (eye, #f9d955) |
| Pupils | slits 0.10 x 0.03 x 0.035 | on the irises' fronts | Pupil (ink, #0e0c1b, specks) |
| Haunches | uv-spheres 8 x 5, half extents 0.15 x 0.27 x 0.20 | (+-0.31, 0.12, 0.20) | Skin |
| Arms | boxes 0.11 x 0.11 x 0.30, tipped forward 10 degrees | (+-0.19, -0.25, 0.16) | Skin |
| Hands | boxes 0.18 x 0.14 x 0.06 | (+-0.21, -0.31, 0.03) | Skin |
| Feet | boxes 0.15 x 0.15 x 0.06, toed out 10 degrees | (+-0.37, -0.24, 0.03) | Skin |
| Sac (game part only) | uv-sphere, half extents 0.20 x 0.17 x 0.16; pivot at the chin (0, -0.24, 0.36) | centre (0, -0.34, 0.28) | Sac (eye, #f9d955) |

784 triangles. `make_frog.py` writes `p1_blockout.txt` (every part), `p2_form.txt` (materials, join, flat
shading, export `frog.glb`, the gated hero) and `p3_parts.txt` (run with `--no-save`): `sac.glb` with
its origin at the chin, and the body re-coloured in the choir's five skins (`frog_green`, `frog_red`
#ca1e0f, `frog_gold` #ea9d18, `frog_blue` #2bcff2, `frog_violet` #c41be3: each the painted step of its
own ramp, so every frog has its own shade and highlight colours).

## Assumptions
- The mouth line and the irises' orange rims are left out: at the scene's texel (0.05 m, the frog
  1.2 x) they would be one-pixel specks. The ink draws a dark edge where the head overhangs the belly,
  which reads as the mouth.
- The sheet's TOP panel is drawn from slightly in front (the face and the belly's top show); the front
  and right views lead.
- The throat sac is not on the sheet (it is deflated there): it is a separate part the game inflates
  under the chin.

## Gate record (generated-sheet tier, chosen before the build: form IoU >= 0.75, splat IoU >= 0.70,
aspect drift <= 0.08, colour drift <= 0.25)

Form, hedra views vs refs (elevation 0):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.864 / 0.057 | 0.858 / 0.047 | 0.865 / 0.059 | 0.765 / 0.085 | fails top: the back feet splayed past the haunches, the body too shallow |
| p1 v2 | 0.909 / 0.065 | 0.857 / 0.004 | 0.907 / 0.062 | 0.814 / 0.081 | body 0.38 deep, feet in: now too narrow |
| **p1 v3 = p2** | **0.910 / 0.018** | **0.857 / 0.004** | **0.908 / 0.016** | **0.816 / 0.032** | haunches out to +-0.31, feet to +-0.37 |

Splats, albedo (`lookdev/frog.bin`, spacing 0.046 = the scene's 0.055 at scale 1.2; eyes 0.033, pupils
0.029): IoU 0.884 / 0.819 / 0.906 / 0.804, aspect drift 0.048 / 0.054 / 0.009 / 0.039, colour drift
0.23 / 0.18 / **0.35** / 0.12. One mesh passes both gates, so no `p3_splat_fit` phase was needed.

**Waiver, back colour drift 0.35**: the sheet paints the whole back in its shade tones (#2e403d and
darker greens that snap to the stone, wood and ink ramps), while the albedo render keeps every Skin
splat on its painted #3c9b87. The materials are right (one Skin material over the whole back); this is
the "painted light" case of modeling.md, recorded rather than repainted.

`hedra model frog.rmdl inspect check`: 0 findings.

Goldens: `goldens/frog` (framed) and `goldens/frog@scene` (`--texel 0.0417` = the scene's 0.05 at scale
1.2, `--size 120`), lit like the scene (`--arg sunYaw=-45 --arg sunPitch=30 --arg keyLight=0.35
--arg highlight=0.85`, `--real-sky`). The sheet is not reviewed by a person yet
(`art/frog/sheet.v1.png.json`, `reviewed: false`).
