# Assets: Lily Hop, a frog crossing a pond (Sweetie 16)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels (216 x 136 with the spare). Orthographic,
yaw 0, pitch 48, `orthoHeight` 7.4 m: texel 0.054 m. Splat spacing 0.08 m (1.5 texels).
Palette: Sweetie 16 (`palette.json`), 7 ramps: water, frog, pad, petal, cream, stone, glow.

Layout (world, Y up, the camera at +Z): the near bank (row 0) at z 3.55, five lanes of lily pads at z 2.3,
1.15, 0, -1.15, -2.3 (1.15 m apart), the far bank (row 6) at z -3.55. Pads drift along X and wrap at
+-6.8 m (out of the frame); reed curtains at x +-6 hide the pond's sides; a frog carried past |x| 5.3 meets
the reeds.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| frog | hero / character | 0.78 x 0.6 x 0.42 (model), scale 1.4 in the scene | 1 (game bone `frog`) | frog, cream, stone | `frog/sheet.v1.png` | 228 | game: hop arc, crouch squash, take-off stretch, landing squash (`placeScaled`), stepped idle breathing (6 fps), turn at each bank, sink |
| pond | terrain | 17 x 14.5 x 0.4 | 1 | water (texture `water.png`, sway), pad (grass), stone (bank sides) | this list | 22 | water splats sway (shimmer) |
| pad | prop | 1.2 x 1.2 x 0.07, a notch cut out | 14 (pool `pad0..13`) | pad | this list | 27 | game: drift, slow spin, bob, dip when landed on |
| lotus | prop | pad + a flower 0.48 x 0.44 | 6 (pool `lotus0..5`) | pad, petal, cream | this list | 87 | as pad |
| reeds | foliage | 0.7 x 0.4 x 1.4 | 16 | pad (two-sided blades, sway), petal (cattails, spacing 0.05) | this list | 120 | sway |
| rock | prop | 0.84 x 0.64 x 0.5 | 10 | stone | this list | 20 | |
| bush | foliage | 1.5 x 1.1 x 1.0 | 7 | pad (sway), cream (flowers, specks) | this list | 120 | sway |
| fly (firefly) | pickup | 0.5 x 0.3 x 0.2 | 1 (game bone `fly`) | glow (unlit, nocast) | this list | 44 | game: hover over a lane, stepped wing flap (12 fps), pop when caught |
| splash | effect | 0.9 x 0.9 x 0.4 | 1 (`splash`) | water (top step, nocast) | this list | 236 | game: crown grows and sinks on a splash |
| ripple | effect | 1.3 ring | 1 (`ripple`) | water | this list | 96 | game: ring spreads where the frog lands |

Bones: 24 game bones (frog, 20 pads, fly, splash, ripple) of 63; no baked tracks. Blob: 53 375 splats.
Textures: `models/env/textures/water.png` (68 x 24, drawn by `make_water.py`, 3 colours of the water ramp,
audited: no lone texels).
