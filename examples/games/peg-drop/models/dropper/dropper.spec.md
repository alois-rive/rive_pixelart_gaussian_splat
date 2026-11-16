# Asset: dropper (hero, game-driven)

Concept: ../../art/dropper/sheet.v1.png (Pear36 colours), refs cut to ../../art/dropper/refs/ with
`--flip back` (the sheet's BACK view drew the key on the wrong side: a mirror error; the object is
left-right symmetric but for the key, so the mirrored back view is the honest one). Up Z, facing -Y;
origin on the ground under the chute (the coin leaves there). Scale from the front panel: 463 px = 1.25 m
-> 370 px per metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Chute | octagonal tube, 0.28 across its flats | z 0..0.27 | Dark (brass, #8c3f5d) |
| Body | box 0.84 x 0.65 x 0.55, every edge bevelled 0.07 | z 0.225..0.775 | Brass (brass, #f2a65e) |
| Hopper | octagonal funnel 0.51 -> 0.82 across its flats, 0.27 tall; its top cap is its inside | z 0.775..1.045 | Copper (copper, #eb564b); CopperIn (copper, #73275c) |
| Coin | 12-gon r 0.235, 0.08 thick, face to the front | centre z 1.015 | Gold (gold, #ffe478) |
| Gear | 8-gon r 0.175 + 8 teeth to r 0.255, 0.09 proud of the front | centre z 0.503 | Dark |
| Key | stem 0.13 x 0.07 x 0.07; bow of two 8-gon lobes r 0.107, 0.12 thick, and a bridge | x -0.41..-0.73, z 0.33..0.75 (the object's own right) | Steel (steel, #c2c2d1) |

`make_dropper.py` writes `p1_blockout.txt` (every part, its material), `p2_form.txt` (the bevel, the
hopper's inside, the hidden caps deleted, the export `dropper.glb`) and `p3_splat_fit.txt` (below).

## Assumptions
- The sheet draws the key's lobes with holes; holes of 0.08 m would close under 0.05 m splats: solid lobes.
- The gear's hub is drawn a shade lighter: one material (the light shades it).
- The hopper's open top is drawn as its dark inside: a closed cap in CopperIn (the camera never looks in).
- Hidden caps (the chute's top, the hopper's bottom) are deleted: `inspect check` reports their open
  edges as non-manifold, on purpose.

## Gate record (generated-sheet tier: form IoU >= 0.75, aspect drift <= 0.08, splat IoU >= 0.70, splat drift <= 0.08, colour <= 0.25)
| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.948 / 0.001 | 0.911 / 0.039 | 0.947 / 0.001 | 0.917 / 0.011 | passes; the gear and key lobes had been turned off their axis (`--rotation 90 0 22.5`), fixed to `90 22.5 0` first |
| p1 v2 | 0.948 / 0.001 | 0.911 / 0.039 | 0.947 / 0.001 | 0.924 / 0.011 | the key's bow 0.07 -> 0.12 thick (the top view's block) |
| **p2** | **0.958 / 0.001** | **0.912 / 0.039** | **0.957 / 0.001** | **0.923 / 0.011** | bevelled body |

Splats, albedo, from p2 (`spacing` 0.09): IoU 0.846 / 0.850 / 0.834 / 0.871, aspect drift 0.017 / **0.140** /
0.046 / **0.126**: every disc reaches a radius past its face, so the side and top views come out ~0.1 m
too deep, and the edge-on coin's tip erodes. The mesh gate and the splat gate disagree (modeling.md):
`p3_splat_fit.txt` keeps the gated p2 and only shrinks the hopper and the body to 0.86 of their depth (Y),
keeps the gear on the face, thickens the coin (x 1.5) and the key (x 1.4 in Y) and lifts the coin 0.03;
it exports `dropper_splat.glb`, which the bakes use.

**Splats, albedo, from p3**: IoU **0.854 / 0.837 / 0.878 / 0.857**, aspect drift **0.007 / 0.057 / 0.011 /
0.053**: pass. Colour drift 0.26 / 0.46 / 0.38 / 0.50: **waived**. Pear36's warm half has five ramps that
share hues and colours (brass, gold, wood, copper, lamp: `#f2a65e` is in brass and gold, `#ffb570` in wood
and lamp, the coppers and the woods sit a step apart). The sheet's soft orange shading of the body lands
on wood and lamp (ref shares wood 0.14-0.45, lamp 0.03-0.22) where the model has none; the model's
materials are right (body brass, hopper copper, coin gold, key steel), as the albedo renders show. This is
modeling.md's "colour gate on neighbouring hues" case: recorded rather than repainted.

Goldens: `goldens/dropper` (framed) and `goldens/dropper@scene` (`--texel 0.051 --size 100`: the scene's
0.066 m texel divided by the scene's 1.3 scale), lit like the scene (`--arg sunYaw=-35 sunPitch=38
keyLight=0.4 highlight=0.85 edgeDepth=0.3`, `--real-sky`). The sheet is not reviewed by a person yet
(`art/dropper/sheet.v1.png.json`, `reviewed: false`).
