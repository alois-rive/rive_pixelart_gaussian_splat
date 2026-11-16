# Asset: chute (hero; three in the scene, the targets of every flick)
Concept: ../../art/chute/sheet.v1.png (Paper 8 colours), refs cut to ../../art/chute/refs/ (no flips:
the sheet follows the brief: the right view has the sign at the back on the image's right, the top
view the front at the bottom).
Up Z, facing -Y; origin on the ground under the hopper's centre.
Scale from the FRONT panel: the rim 303 px for 1.50 m -> 202 px per metre (the right and top panels
agree within 2 %).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Legs (4) | 0.134 square, 0.86 tall | centres (+-0.40, +-0.40), z 0..0.86 (tops inside the funnel) | Wood (wood, #654053) |
| Hopper (funnel) | mouth 1.46 x 1.38 at z 1.42, outlet 0.66 x 0.66 at z 0.69; open top | centred | Wood, two-sided in the bake (its inside shows from above) |
| Rim | four boards 0.08 thick, 0.134 tall round 1.50 x 1.42 | z 1.42..1.554 | Rim (wood, #d1a67e) |
| Sign post | 0.13 square | (0, 0.70), z 1.554..1.705 | Wood |
| Sign disc | r 0.315, 0.085 thick, 12 sides, face -Y | centre (0, 0.75, 1.98) | Sign (red, #a8605d); front face: Ring (paper, #f6e79c) outer ring 0.05 wide and a centre circle r 0.135 |
| Mail sack | 8 x 6 uv-sphere r 0.32, squashed to 0.8 tall; buried bottom removed | (0, 0, 0.25) | Sack (paper, #d1a67e) |
| Tie, frill | cylinder r 0.13 x 0.07 at z 0.5; cone r 0.10 -> 0.19, 0.11 tall at z 0.585 | on the sack | Cord (wood, #654053); Sack |

`make_chute.py` writes `p1_blockout.txt`, `p2_form.txt` (materials, the funnel opened, leg tops and
the sack's bottom deleted, the sign's insets, `chute.glb`: the gated hero) and `p3_parts.txt` (run with
`--no-save`): `chute_body.glb` (all but the disc, the scene's three static chutes) and the disc alone,
its origin at its centre moved to the origin, in three colours: `sign_red.glb`, `sign_green.glb`,
`sign_cream.glb` (cream with a plum ring). The game's discs are solid: p3 gives the centre circle the
disc's colour (with the cream centre the red and the cream signs both read as bullseyes at the scene's
texel). The scene bakes the discs at scale 1.5 and 0.18 m higher (centre y 2.16): at 0.63 m a sign
was 11 art pixels across, too small to read the colour at a glance.

## Assumptions
- The sheet is 2.30 m tall, not the brief's 2.6 m: the spec measures the sheet.
- The top view puts the sign 0.10 m behind the rim, the right view 0.07 m inside it: the disc sits at
  y 0.75, just behind the rim's back board (0.71), between the two.
- The sheet paints the funnel's shaded flanks navy; the model paints plum everywhere and lets the light
  shade it (the albedo gate keeps it on plum).
- The sheet's back view paints the disc's back red (the brief asked for wood): red kept.

## Gate record (generated-sheet tier, chosen before the build: form IoU >= 0.75, aspect drift <= 0.08;
splat IoU >= 0.70, splat aspect drift <= 0.08, colour drift <= 0.25)
Form, hedra views vs refs, elevation 0 (iou / aspect drift):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.912 / 0.006 | 0.798 / 0.003 | 0.917 / 0.004 | 0.930 / 0.056 | passes; sack pointed at the bottom, sign inside the rim from above |
| p2 v1 | 0.864 / 0.004 | 0.778 / 0.049 | 0.870 / 0.002 | 0.960 / 0.005 | the sack's "bottom" selection was object-local (pos.z < 0.02 took its lower half) |
| **p2 v2** | **0.924 / 0.004** | **0.846 / 0.049** | **0.929 / 0.002** | **0.960 / 0.005** | uv-sphere sack, only its bottom ring deleted (pos.z < -0.21), disc at y 0.75 |

Splats, albedo (`lookdev/chute.bin`):

| Bake | front | right | back | top |
|---|---|---|---|---|
| spacing 0.08 (sign 0.06) | 0.817 / 0.017 / 0.05 | 0.745 / **0.099** / 0.05 | 0.766 / 0.074 / 0.04 | 0.906 / 0.024 / 0.21 |
| **spacing 0.07 (sign, cord 0.05)** = the scene's | **0.838 / 0.009 / 0.05** | **0.752 / 0.066 / 0.05** | **0.776 / 0.077 / 0.05** | **0.909 / 0.016 / 0.20** |

(iou / aspect drift / colour drift.) At 0.08 the rim and the 0.085 m disc fatten by a splat radius each
side and the right view came out too wide; the scene bakes the chute's materials at 0.07 (1.2 texels)
and the bench matches it. No waiver needed. The top view's colour drift (0.20) is the sheet's navy
funnel inside against the model's plum (see Assumptions).

`hedra inspect check`: non-manifold edges on the legs and the funnel (their hidden caps deleted on
purpose), ngons on the disc and the tie (triangulated on export): harmless for splats.

Goldens: `goldens/chute` (framed) and `goldens/chute@scene` (`--texel 0.0588 --size 120`), lit like
the scene (`--arg sunYaw=-35 --arg sunPitch=55 --arg keyLight=0.4 --arg highlight=0.85`, `--real-sky`).
The Codex sheet is not reviewed by a person yet (`art/chute/sheet.v1.png.json`, `reviewed: false`).
