# Asset: hero, the delver (character; one game bone, `hero`)
Concept: ../../art/hero/sheet.v2.png (Gamma Boy colours: v1 recoloured by Codex with v1 attached, the
same design; v1 was Apollo), refs cut from v2 to ../../art/hero/refs/ (no flips or
rotations: the RIGHT panel faces left, the TOP panel has the face towards the bottom, as briefed).
Up Z, facing -Y; origin on the ground between the boots. Scale from the FRONT panel: 458 px for the
brief's 1.2 m -> 382 px per metre; every part below is read off the sheet at that scale.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Boots | 0.20 x 0.30 x 0.13 | x +-0.15, toes forward (y -0.03) | Belt (wood, #252a2d) |
| Legs | 0.13 x 0.15 x 0.14 | x +-0.14, z 0.13 .. 0.26 | Tunic (wood, #8c7661) |
| Tunic | 0.58 x 0.40 x 0.43, top 0.8 x 0.92 narrower | z 0.24 .. 0.67 | Tunic |
| Belt | 0.60 x 0.42 x 0.065 | z 0.41 | Belt |
| Cloak | 0.84 x 0.48 x 0.29, top 0.62 x 0.84 narrower | z 0.45 .. 0.74 | Cloak (cloak, #476a2f; lit faces step up to lime #82a641) |
| Chest (tunic between the cloak's edges) | 0.24 x 0.10 x 0.29 | y -0.21 | Tunic |
| Arms | 0.12 x 0.12 x 0.30 | x +-0.33, z 0.38 .. 0.68 | Cloak |
| Fists | 0.16 x 0.16 x 0.17 | x +-0.36, z 0.31 (the right one holds the game's weapon bone) | Skin (wood, #b3c392) |
| Head | 0.46 x 0.36 x 0.24 | z 0.67 .. 0.91 | Skin |
| Eyes | 0.06 x 0.04 x 0.08 (exaggerated from the sheet's 0.03: two splats) | x +-0.10, z 0.81, 0.015 proud | Eye (cloak, #192119), specks |
| Brim | octagonal, r 0.39 -> 0.29, 0.06 thick (sloping down at the rim) | z 0.88 .. 0.94 | Steel (bone, #a3ad8b) |
| Dome | octagonal, r 0.31 -> 0.14, 0.27 tall | z 0.94 .. 1.21 | Steel |
| Lamp | 0.17 x 0.08 x 0.15 (thickened: 7 splats on the first bake), its front inset as the window | y -0.235, z 1.02 | Steel; Window (flame, #b5db66, unlit) |
| Backpack | 0.50 x 0.26 x 0.30 | y +0.35, z 0.34 .. 0.64 | Pack (wood, #4e4b5a) |
| Bedroll | cylinder r 0.11, 0.64 long across x | y +0.35, z 0.74 | Roll (wood, #a39b6c) |

`p1_blockout.txt` (one primitive per part), `p2_form.txt` (the tapers, the lamp window, eyes,
materials, the soles deleted: the mesh gate's model), `p3_splat_fit.txt` (for the splats only, below;
run with `--no-save --to hero_fit.rmdl`, and `hero.glb` is exported from the fit for the bake).
584 triangles.

## Assumptions
- The sheet's TOP view is 12 % deeper than its RIGHT view (338 px vs 301 px, front to back, at one
  scale): the bedroll and the brim reach further in the top panel. Front and right lead for the
  heights; the depth is split between the two views (below).
- The straps on the bedroll (two dark bands in the back and top panels) are thinner than two splats
  and are dropped.
- The brief's head was 0.32 m wide; the sheet drew 0.46 m. The spec measures the sheet.
- Hands are empty: the game attaches one of four weapon bones (dagger, sword, axe, sling) to the right
  fist through `api.transform`.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75`, aspect drift <= 0.08):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.847 / 0.010 | 0.808 / 0.058 | 0.860 / 0.007 | 0.899 / 0.016 | primitives at the spec's sizes |
| p1 v2 | | | | | dome broader at the top (r2 0.14), brim sloping (a cone, not a disc) |
| **p2** | **0.894 / 0.023** | **0.818 / 0.052** | **0.904 / 0.006** | **0.897 / 0.021** | tapers, materials, eyes, window |

Splats, albedo (`--look albedo`, spacing 0.07 = the scene's for characters):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| on p2 | 0.845 / 0.012 / 0.18 | 0.818 / **0.099** / 0.18 | 0.854 / 0.034 / 0.20 | 0.865 / 0.009 / 0.21 | discs widen the side view (brim, lamp, pack) |
| p3 v1 | 0.851 / 0.015 | 0.838 / 0.012 | 0.849 / 0.021 | 0.841 / **0.096** | pack 0.78 deep and 0.03 forward: the top view now too shallow (the sheet's two depths disagree) |
| **p3 v2** | **0.848 / 0.019 / 0.18** | **0.816 / 0.040 / 0.20** | **0.849 / 0.037 / 0.21** | **0.863 / 0.067 / 0.22** | the fit split between the views: brim 0.94, pack 0.88 deep and 0.012 forward, bedroll 0.02 forward and up, lamp 0.02 back, dome 1.12 taller |

(IoU / aspect drift / colour drift.) Every view passes (IoU >= 0.7, drift <= 0.08, colour <= 0.25):
no waiver needed; the depth compromise is the assumption above. The tables above are the Apollo build
against sheet v1.

**Gamma Boy re-skin (sheet v2).** The model's form is unchanged (only `p2_form.txt`'s material colours
and the bake's ramps changed). Sheet v2 is v1 recoloured: its cut-outs overlap v1's at IoU 0.983 (front),
0.984 (right), 0.986 (back), 0.991 (top), and the same boxes within 1 px. Both gates re-run against the
v2 refs, same thresholds:

| Gate | front | right | back | top |
|---|---|---|---|---|
| form, p2 (hedra, `--min-iou 0.75`) | 0.897 / 0.022 | 0.819 / 0.053 | 0.906 / 0.010 | 0.891 / 0.027 |
| splats, albedo (p3 fit, palette Gamma Boy) | 0.845 / 0.020 / 0.07 | 0.816 / 0.041 / 0.15 | 0.849 / 0.033 / 0.09 | 0.861 / 0.061 / 0.14 |

All pass; no waiver. The colour drift fell from 0.18-0.22 to 0.07-0.15: the sheet is in the final
palette, so its shades snap to the same ramps as the splats.

Goldens: `goldens/hero` (framed), `goldens/hero@scene` (`--texel 0.0559`, the scene's, `--size 300`),
lit like the scene (`--arg sunYaw=-35 --arg sunPitch=58 --arg keyLight=0.42 --arg highlight=0.9
--arg shadeSteps=1`, `--real-sky`), re-snapped in Gamma Boy after viewing. Neither sheet is reviewed by
a person yet (`art/hero/sheet.v1.png.json`, `sheet.v2.png.json`, `reviewed: false`).
