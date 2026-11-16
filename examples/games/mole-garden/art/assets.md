# Assets: Mole Garden, whack the moles in a vegetable bed at dusk (Steam Lords)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels. Orthographic, yaw 0, pitch 52,
`orthoHeight` 4.8 m: texel 0.035 m. Splat spacing 0.06 m (1.7 texels). Palette: Steam Lords
(`palette.json`), 9 ramps: fur, snout, soil, leaf, straw, bunny, wood, steel, glow.

Layout (world, Y up, the camera at +Z): a lawn at y -0.15, a tilled bed (5.6 x 4.4 m, top at y 0) with a
3 x 3 grid of molehills at x -1.5 / 0 / 1.5, z -1.3 / 0 / 1.3; vegetables between them, a picket fence
behind and at the sides, a scarecrow, two lanterns, squashes on the lawn.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| mole | hero / character | 0.52 x 0.51 x 0.48 (model), scale 1.3 | 9 (pool `mole0..8`, one per hole) | fur (+1 step in the scene, to read on dark soil), snout, steel (claws, specks) | `mole/sheet.v1.png` | 230 | game: rise with a stretch, pop overshoot, stepped look-around (8 fps), flattened when hit, sink |
| rabbit | character | 0.53 x 0.48 x 1.1 (with ears), scale 1.2 | 3 (`rabbit0..2`) | bunny, snout, fur (eyes) | this list | 184 | game: as the mole; a hit rabbit leaps and spins |
| mallet | prop (the cursor) | 0.4 x 1.07 x 0.36, scale 1.5 | 1 (`mallet`) | straw (handle), wood (head), steel (bands) | this list | 104 | game: follows the pointer, swings about its grip (pitch) |
| bonk | effect | 0.9 ring of 5 stars | 3 (`bonk0..2`) | glow (unlit, nocast) | this list | 100 | game: spins and spreads over a hit mole |
| garden | terrain | 13 x 11 lawn, 5.6 x 4.4 x 0.15 bed | 1 | leaf (lawn, spacing 0.08), soil (texture `soil.png`) | this list | 12 | |
| hole | terrain | 1.24 x 1.24 x 0.14 | 9 | soil (mound, dark hole) | this list | 28 | |
| cabbage, turnip | foliage | 0.84 x 0.84 x 0.42; 0.3 x 0.3 x 0.55 | 7, 9 | leaf (sway), bunny (turnip bulb) | this list | 30, 56 | sway |
| pumpkin | prop | 0.68 x 0.68 x 0.53 | 4 | straw, leaf (stem, specks) | this list | 80 | |
| fence | architecture | 2.0 x 0.1 x 0.72 | 11 | wood | this list | 84 | |
| scarecrow | prop | 1.32 x 0.34 x 2.0, scale 1.2 | 1 | wood, soil (shirt), straw, fur (hat) | this list | 136 | |
| lantern | light prop | 0.3 x 0.3 x 1.28 | 2 | wood, fur (iron), glow (unlit) | this list | 48 | |

Bones: 16 game bones (9 moles, 3 rabbits, the mallet, 3 bonks) of 63; no baked tracks. Blob: 47 313 splats.
Textures: `models/env/textures/soil.png` (28 x 22, drawn by `make_soil.py`: furrow ridges of the soil ramp).
