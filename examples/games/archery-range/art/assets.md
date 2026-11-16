# Assets: an archery range on a summer meadow (Island Joy 16)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels. Orthographic camera from behind the
archer (yaw 0, pitch 30), 10.5 m tall: texel 0.079 m. Splat spacing 0.1 (1.3 texels), finer for thin and
small parts (0.04 to 0.07), coarser for the meadow (0.13). Palette: Island Joy 16 (`palette.json`), nine
ramps; the meadow texture mixes three of them (no `ramp` on its material: each texel finds its own).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| target | hero prop | 1.2 x 1.55 x 1.7 (baked x 1.25) | pool of 6 | straw, stone, teal, crimson, wood | `target/sheet.v1.png` | 236 | game: slides along its lane, bumps (stepped), rocks back and pops when hit |
| archer | character | 0.9 x 0.6 x 1.75 (baked x 1.3) | 1 | cloth, wood, skin, crimson, straw | this list | 230 | game: turns to the aim, squashes into the draw, recoils |
| bow | prop | 0.13 x 0.4 x 1.4 (x 1.3) | 1 | wood | this list | 60 | game: canted 20 degrees, bends (scaled in depth) with the draw |
| arrow | prop | 0.18 x 1.0 x 0.18 (x 1.15) | pool of 11 | stone, skin, crimson, straw | this list | 44 | game: nocked, flies a ballistic arc with wind, sticks in a boss or the ground and quivers |
| chip | effect | 0.22 | pool of 8 | straw | this list | 20 | game: straw knocked off by a hit, falls |
| flag | effect | 1.3 x 0.1 x 0.7 | 1 | crimson | this list | 4 | game: turns downwind, lifts with the strength, flutters at 10 fps |
| flagpole | prop | 0.4 x 0.4 x 3.3 | 1 | straw, stone | this list | 64 | |
| ground | terrain | 19 x 19 | 1 | grass, straw, crimson (drawn texture, 95 x 95, 0.2 m a texel) | this list | 2 | |
| track | terrain | 19 x 1.0 x 0.06 | 3 lanes (z -3, -6.5, -10) | straw | this list | 10 | |
| bush | foliage | 2.5 x 1.5 x 1.1 | 12 (back hedge) + 1 | foliage (sway) | this list | 60 | wind sway |
| tree | foliage | 3 x 3 x 4.2 | 6 (0.7 - 0.95) | wood, foliage (sway) | this list | 80 | wind sway |
| haybale | prop | 0.9 x 1.0 x 1.0 | 2 | straw | this list | 40 | |

Bones: 28 of 63, all game bones (flag, archer, bow, target0-5, arrow0-10, chip0-7). Blob: 63 400 splats.
The pools are baked under the meadow (z -20 to -24) and placed by `scene/game.as`.
