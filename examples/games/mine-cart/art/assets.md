# Assets: Mine Cart (EN4)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; orthographic, `orthoHeight` 6.8 m,
pitch 38 -> texel 0.05 m (6.8 m over the art canvas's 136 rows). Splat spacing 0.09 m (1.8 texels); rails, levers, the cart's iron and gems
0.06. Palette: EN4 (`palette.json`, 4 colours: navy #20283d, green #426e5d, tan #e5b083, cream
#fbf7f3) in 7 ramps. Value plan: the cave is green (floor, walls, scenery rocks), the track is navy
(painted beds) with green rails, the cart and the timber are tan, and cream is kept for what the
player wants: gems (and the cart's cargo, lanterns). Tan boulders are the hazard.

| Ramp | Steps | Used by |
|---|---|---|
| rock | navy, green, tan | floor texture (green, navy beds), rockfall boulders (tan) |
| wood | navy, green, tan, cream | the tub, timber, lever stands; HUD colours (`rampColor(1, s)`) |
| iron | navy, navy, green, tan | wheels, rims, levers (baked at `"step": 1` so lit faces reach green) |
| rail | navy, green, tan, cream | rails (green) |
| gem | green, tan, cream | gems, the cart's heap and cargo, lever knobs |
| glow | tan, cream | lanterns, crystals, dust (unlit) |
| cave | navy, green | walls, the floor's rocky skirt, scenery stones, crystal bases (a 2-step ramp: no tan stipple on lit rock) |

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| cart | hero | 0.75 x 1.23 x 0.88 | 1 (shown at 1.25x) | wood, iron, gem, glow | `cart/sheet.v1.png` | 446 | game bone `cart`: follows the track, lean on curves, rattle, squash on a pickup, tumble on a crash |
| floor | terrain | 10.4 x 6.6 x 0.7 | 1 | rock (painted texture), cave | this list | ~150 | |
| rails | track | 2 bars 0.06 x 0.08, gauge 0.46, ~50 m of lane | 1 | rail | this list (generated) | ~2500 | |
| lever | prop | 0.22 x 0.22 x 0.66 | 4 (one per junction) | iron, gem | this list | 60 | game bones `lever0..3`: tilt to the set lane (spring, overshoot, pop) |
| stands | prop | 0.3 x 0.3 x 0.16 | 4 (one mesh) | wood | this list | 48 | |
| gem | pickup | 0.26 x 0.26 x 0.36 | pool of 6 (shown at 1.4x) | gem | this list | 36 | game bones `gem0..5`: pop in, float and turn, swell and vanish; spill on a crash |
| rocks | hazard | 0.91 x 0.73 x 0.72 | pool of 3 (shown at 0.75x) | rock | this list | 60 | game bones `rock0..2`: drop from the roof, squash on landing |
| stones | prop | as rocks | 3 | cave | this list | 60 | |
| puff | effect | 0.98 x 0.98 x 0.3 | pool of 3 | glow (unlit, nocast, specks) | this list | 96 | game bones `puff0..2`: stepped growth in four poses |
| timber | architecture | 2.5 x 0.24 x 2.4 | 3 (at 0.75x) | wood, iron, glow | this list | 60 | |
| crystals | prop | 1.1 x 1.0 x 1.0 | 2 | cave, glow, rock (unlit tan and green) | this list | ~200 | |
| walls | terrain | a ring of rocks 1-1.9 m tall round the back and sides | 1 | cave | this list (seeded) | ~1000 | |

Bones: cart 1 + levers 4 + gems 6 + rocks 3 + puffs 3 = 17 of 63, all game bones (no baked tracks).
Splats: 25 930 (811 KiB).

The track layout lives in one place, `models/env/make_env.py`: the main loop (two 5.2 m straights, two
U-turns of radius 1.7, 21.08 m) and four lane B's (the straights' lanes bulge 0.9 m outwards through
60 degree S-bends, the U-turns' cut a tight inner lane of radius 0.8). From it come the rails (swept in
hedra: `extrude` along straights, `spin` round arcs), the floor texture's navy beds, the lever spots,
and the track table in `scene/game.as` (between its `// <track>` markers) that the cart follows. The
cart moves by arc length along the same straights and arcs, so it always sits on the rails.
