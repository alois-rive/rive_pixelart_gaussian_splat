# Asset: hero (the adventurer; one game bone `hero` in the scene)

Concept: ../../art/hero/sheet.v1.png (MarshMellow32 colours), refs cut to ../../art/hero/refs/ (no flips or
rotations: the sheet follows the brief, the RIGHT view faces left). Up Z, facing -Y; origin on the ground under
the body's centre (the game hops and turns the hero about it). Scale from the FRONT panel: 0.95 m from the boot
soles to the crown's top is 461 px -> 485 px per metre; every part below is read off that panel (the RIGHT panel
for depths) with the same scale.

## Parts (metres; x right of the character is image right in the FRONT view, y depth, z up)
| Part | Size | Position | Material (ramp, base step) |
|---|---|---|---|
| Boots | 0.156 x 0.205 x 0.095 | x +-0.09, toes forward to y -0.135, z 0 .. 0.095 | Belt (wood #593234) |
| Legs | 0.11 x 0.12 x 0.09 | x +-0.085, z 0.09 .. 0.18 | Legs (stone #4b5053) |
| Tunic | square frustum 0.36 x 0.31 at the hem -> 0.26 x 0.22 at the shoulders, 0.30 tall | z 0.17 .. 0.47 | Tunic (water #2d80a6) |
| Belt | square ring 0.342 x 0.30, 0.045 tall | z 0.233 .. 0.278 | Belt |
| Collar | 0.32 x 0.29 x 0.06 | z 0.43 .. 0.49 | Cape (red #8c504d) |
| Cape | 0.30 wide, 0.05 thick, flaring to 0.34 and 0.10 back at its hem | down the back, z 0.19 .. 0.47 | Cape |
| Arms | 0.09 x 0.10 x 0.16 | x +-0.18, z 0.30 .. 0.46 | Tunic |
| Hands | 0.10 x 0.10 x 0.09 | right x -0.235 z 0.22 .. 0.31; left x +0.23 | Skin (skin #b87a66) |
| Head | 0.37 x 0.35 x 0.24 | z 0.47 .. 0.71 | Skin |
| Hair | fringe band 0.41 x 0.395 x 0.075 under the brim, a back plate 0.39 x 0.055 x 0.15 | z 0.69 .. 0.765; back z 0.55 .. 0.70 | Hair (stone #3c3a3f) |
| Eyes | 0.055 x 0.025 x 0.06, flat squares | x +-0.083, z 0.58 .. 0.64, on the face | Hair |
| Brim | octagon, circumradius 0.395 (0.73 across the flats), 0.05 thick | z 0.76 .. 0.81 | Straw (gold #e2b55f) |
| Crown | octagonal frustum r 0.19 -> 0.168, 0.15 tall | z 0.80 .. 0.95 | Straw |
| Hat band | octagonal ring r 0.198, 0.045 tall | z 0.818 .. 0.863 | Band (red #8c504d) |
| Sword | grip 0.04 x 0.04 x 0.08, guard 0.16 x 0.05 x 0.04, blade 0.09 x 0.034 x 0.22, pyramid tip 0.07 | in the right hand, x -0.235, z 0.30 .. 0.70 | Belt, Gold (#e2b55f), Blade (stone #b2b2b2) |
| Shield | octagonal disc r 0.165, 0.05 thick, its outward face turned 40 degrees from +X towards the front; wooden face inset 0.04 inside a gold rim; a boss r 0.05 | on the left forearm, centre (0.285, -0.12, 0.33) | Gold, Shield (gold #a1623b) |

`make_hero.py` writes `p1_blockout.txt` (one primitive per part, the spec's sizes and colours) and `p2_form.txt`
(the shield's face inset into wood, flat shading, `hero.glb`). 402 triangles, 11 materials.

## Assumptions
- The sheet drew the brim 0.755 m across (the brief asked 0.62): the sheet leads.
- The top view is drawn about 5 % larger than the side views (brim 386 px against 367 px); the model follows the
  front and right views. It still passes.
- The sheet's shaded faces (#b68241 on the hat, #734141 on the cape, #235b7c on the tunic) are painted on the lit
  colour; the renderer's ramps shade them.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75`, aspect drift <= 0.08), elevation 0:

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p2 v1 | 0.860 / 0.011 | 0.800 / 0.009 | 0.865 / 0.004 | 0.925 / 0.024 | |
| **p2 v2** | **0.857 / 0.022** | **0.851 / 0.009** | **0.855 / 0.016** | **0.915 / 0.038** | shield r 0.15 -> 0.165 and 0.06 further forward, cape hem 0.04 further back (the compare sheet's magenta) |

Look, splats albedo (`lookdev/hero.bin`, spacing 0.042 = the scene's; Blade 0.026, Belt and Shield 0.03;
`--min-iou 0.7`, aspect drift <= 0.08, colour drift <= 0.25):

| | front | right | back | top |
|---|---|---|---|---|
| IoU | 0.849 | 0.776 | 0.824 | 0.907 |
| aspect drift | 0.017 | 0.023 | 0.032 | 0.006 |
| colour drift | 0.14 | 0.17 | 0.14 | 0.04 |

Every view passes: no waivers. `hedra model hero.rmdl inspect check`: only ngons on the octagon caps (brim,
crown, band, shield, boss), harmless (triangulated on export).

Goldens: `goldens/hero` (framed), `goldens/hero@scene` (`--texel 0.047` = the map's 6.4 / 136, `--size 100`),
lit like the scene (`--arg sunYaw=10 --arg sunPitch=52 --arg keyLight=0.42 --arg highlight=0.85 --arg
shadeSteps=1 --arg edgeDepth=0.35`, `--real-sky`). The sheet is not reviewed by a person yet
(`art/hero/sheet.v1.png.json`, `reviewed: false`).
