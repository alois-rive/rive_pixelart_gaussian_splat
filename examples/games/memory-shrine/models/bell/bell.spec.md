# Asset: bell (hero; four game bones in the scene, each in its own ramp, plus four unlit "glow" copies)
Concept: ../../art/bell/sheet.v1.png (Citrink colours), refs cut to ../../art/bell/refs/ (no flips or
rotations: the sheet follows the brief). Up Z, facing -Y (a strike boss on the front and the back);
origin on the ground under the lip's centre. Scale from the FRONT panel: lip 324 px for 1.25 m ->
259 px per metre.

## Parts (metres; octagons turned 22.5 degrees so a flat face looks to the front, as drawn)
| Part | Size | Position (z from the lip) | Material (ramp, step) |
|---|---|---|---|
| Flare | octagonal frustum, 1.25 -> 1.13 across the flats, 0.09 tall | z 0 .. 0.09 | Bronze (#fcf660) |
| Body | octagonal frustum, 1.10 -> 0.915 across the flats | z 0.085 .. 1.085 | Bronze |
| Lower band | octagonal ring 1.15 across, 0.13 tall | z 0.09 .. 0.22 | Band (#166e7a) |
| Upper band | octagonal ring 0.98 across, 0.10 tall | z 0.91 .. 1.01 | Band |
| Dome | octagonal frustum 0.915 -> 0.42, 0.23 tall | z 1.085 .. 1.317 | Bronze |
| Loop | torus R 0.20, r 0.07, in the front plane (an O from the front) | centre z 1.527, top 1.78 | Band |
| Strike bosses | octagonal discs r 0.18, 0.16 deep (0.11 proud), front and back | z 0.46 | Band |

`p1_blockout.txt` (the primitives), `p2_form.txt` (materials, hidden caps and the open mouth deleted,
joined, flat, `bell.glb`). 250 triangles.

In the scene the one GLB is baked eight times: `bell0`..`bell3` (green, lime, gold, white: the
Bronze material mapped to the copper, limeb, gold and moon ramps, with `"step"` -1 on the first two;
bake scales 1.35, 1.2, 1.08, 0.96) and `glow0`..`glow3` (the same, unlit, one step brighter, bands
yellow or white), which the game swaps in while a bell rings.

## Assumptions
- The sheet's TOP view is drawn smaller than the side views (the octagon 304 px across against a
  324 px lip) and shows the strike bosses beyond the lip, which the front and right views contradict
  (there they stay inside the lip's width). Front and right lead; the top view gets a waiver.
- The sheet's shaded faces are painted #b2d942 (lime); the model paints every bronze face #fcf660
  and leaves the shade to the renderer's ramp.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`, elevation 0):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.970 / 0.007 | 0.953 / 0.013 | 0.970 / 0.007 | 0.932 / 0.125 | |
| **p1 v2 = p2** | **0.960 / 0.014** | **0.959 / 0.006** | **0.960 / 0.014** | 0.900 / 0.125 (waived) | bosses r 0.16 -> 0.18 (the sheet's are bigger), loop tube 0.06 -> 0.07 |

Look, splats albedo (`lookdev/bell.bin`, spacing 0.058 = the scene's 0.075 at the middle bells' scale
~1.2; `--min-iou 0.7 --max-aspect-drift 0.08`, colour drift <= 0.25): IoU 0.909 / 0.938 / 0.912 /
0.944, aspect drift 0.032 / 0.011 / 0.032 / 0.091 (waived), colour drift 0.15 / 0.21 / 0.16 / 0.29
(waived).

**Waiver, top view** (aspect drift 0.125 mesh, 0.091 splats; colour drift 0.29): the sheet's top view
contradicts its side views (scale and bosses, above), and from above it shows mostly the lime shade
colour, which the colour gate counts against the lime ramps. Front and right lead.

`hedra inspect check`: ngons on the boss and loop caps (harmless, triangulated on export); open edges
where the mouth and the caps buried in the bands were deleted on purpose.

Goldens: `goldens/bell` (framed), `goldens/bell@scene` (`--texel 0.0527` = the scene's 0.0632 at
scale 1.2, `--size 120`), lit like the scene (`--arg sunYaw=32 --arg sunPitch=34 --arg keyLight=0.4
--arg highlight=0.85`, `--real-sky`). The sheet is not reviewed by a person yet
(`art/bell/sheet.v1.png.json`, `reviewed: false`).
