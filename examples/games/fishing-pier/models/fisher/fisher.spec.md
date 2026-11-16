# Asset: fisher (hero character, game-driven)
Concept: ../../art/fisher/sheet.v1.png (Pollen8 colours), refs cut to ../../art/fisher/refs/ (no flips).
Up Z, facing -Y; origin on the ground under the bucket. Total height 1.3 m (placed at 1.3 x in the
scene: 25 art pixels). Scale from the front panel: 484 px = 1.3 m -> 372 px per metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Bucket | 8-sided frustum r 0.27 -> 0.22, 0.38 tall; rim r 0.29 x 0.06 | z 0..0.4 | Bucket, Rim (bucket: teal, mint) |
| Body (coat) | 8-sided frustum r 0.34 -> 0.29, 0.5 tall | z 0.38..0.88 | Coat (coat, gold) |
| Thighs | 0.2 x 0.42 x 0.17 | (+-0.17, -0.22, 0.44) | Coat |
| Boots, feet | 0.2 x 0.22 x 0.4; 0.21 x 0.24 x 0.12 | x +-0.21, front to y -0.59 | Boot (boot, berry) |
| Arms | 0.17 x 0.46 x 0.17, turned 28 degrees in | (+-0.2, -0.22, 0.74) | Coat |
| Hands | ico r 0.1 | (+-0.07, -0.45, 0.73) | Skin (skin, pink) |
| Head | ico r 0.22 | (0, -0.06, 0.95) | Skin |
| Beard, nose, eyes | ico r 0.19 (1.05 x 0.7 x 0.85); r 0.085; 0.06 cubes | the head's front | Beard (beard, cream), Skin, Eye |
| Hat | crown ico r 0.26 (z x 0.95) at z 1.11; brim frustum r 0.34 -> 0.24, 0.15 tall at z 1.0 | to z 1.32 | Coat |

## Assumptions
- The sheet shades the hat's and coat's right halves pink (its light): modelled as one coat material;
  the renderer's light gives the shade.
- The rod is not on the sheet (the brief asked for the hands only): it is a separate scene part
  pivoting at the hands, so the game can bend it.

## Gate record (generated-sheet tier: form IoU >= 0.75, splat IoU >= 0.70, drift <= 0.08, colour <= 0.25)
| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.875 / 0.031 | 0.817 / 0.076 | 0.882 / 0.031 | 0.848 / 0.049 | a pointed witch's hat (magenta round it) |
| p1 v2 | 0.914 / 0.053 | 0.842 / 0.107 | 0.917 / 0.053 | 0.861 / 0.059 | rounded crown, wide brim: too deep in the right view |
| p1 v3 | 0.914 / 0.053 | 0.843 / 0.051 | 0.918 / 0.053 | 0.854 / 0.000 | brim not stretched back, feet 0.03 in |
| splats v1 | 0.872 / 0.095 | 0.837 / 0.028 | 0.865 / 0.097 | 0.836 / 0.028 | splat fattening widens the front past 0.08 |
| splats v2 | 0.848 / 0.086 | 0.828 / 0.030 | 0.874 / 0.076 | 0.825 / 0.051 | brim and body 0.03 narrower; still wide, the face hidden behind the hands |
| **p2 v4** | **0.902 / 0.016** | **0.838 / 0.016** | **0.911 / 0.016** | **0.813 / 0.029** | head, face and hat 0.05 up (the hands covered the beard) |

Splats albedo (`lookdev/fisher.bin`, spacing 0.07 = the scene's 0.09 at the 1.3 x placement): IoU 0.855
/ 0.840 / 0.884 / 0.826, aspect drift 0.061 / 0.002 / 0.050 / 0.047, colour drift 0.17 / 0.20 / 0.23 / 0.10.

Goldens: `goldens/fisher` (framed) and `goldens/fisher@scene` (`--texel 0.055`, the scene's 0.072 at
1.3 x, `--size 120`), lit like the scene (`--arg sunYaw=35 sunPitch=40 keyLight=0.4 highlight=0.85
shadeSteps=1`, `--real-sky`). The sheet is not reviewed by a person yet (`reviewed: false`).
