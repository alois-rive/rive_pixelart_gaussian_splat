# Assets: a rubber duck holds a bathtub against a toy fleet (Lost Century)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels. Orthographic camera from above the
near rim (yaw 0, pitch 50), 6.6 m tall: texel 0.050 m. Splat spacing 0.08 (1.6 texels), 0.035 to 0.07 for
the duck, the boats and small props, 0.1 to 0.12 for the floor, wall and water. A toy-scale world: the tub
is 9.2 m long. Palette: Lost Century (`palette.json`), ten ramps; the drawn floor, wall, mat and water
textures mix ramps (no `ramp` on their materials: each texel finds its own).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| duck | hero | 0.7 x 0.8 x 0.72 (baked x 2) | 1 | duck, beak, ink | `duck/sheet.v2.png` | 362 | game: turns to the aim, bobs (8 fps), recoils on each shot, squashes when bonked |
| sailboat | prop | 0.56 x 1.2 x 1.25 (x 1.15) | pool of 4 | red, wood, enamel | this list | 52 | game: rises at the faucet, weaves down the tub, homes on the duck, rolls and sinks when popped |
| tugboat | prop | 0.7 x 1.3 x 1.15 (x 1.15) | pool of 3 | red, wood, enamel, ink | this list | 72 | game: the same; two hits |
| speedboat | prop | 0.6 x 1.4 x 0.45 (x 1.15) | pool of 3 | wood, red, water | this list | 36 | game: the same, fast |
| bubble | effect | 0.44 | pool of 6 | bubble | this list | 80 | game: flies over the water, wobbles (stepped), pops on a boat or the wall |
| drop | effect | 0.18 | pool of 10 | bubble (nocast, specks) | this list | 20 | game: splashes |
| tub | terrain | 9.2 x 5.4 x 1.3 | 1 | enamel, water (texture, sway), wood | this list | 330 | the water shimmers (sway) |
| room | terrain | floor 14.4 x 8.8, wall 14 x 5, mat 3 x 2 | 1 | tile, enamel, water, red (textures) | this list | 6 | |
| faucet | prop | 1.0 x 1.1 x 1.0 (x 1.2) | 1 | wood, enamel | this list | 90 | |
| props | prop | soap, dish, bottle, sponge | 1 set | enamel, red, water, sponge | this list | 60 | |
| foam | effect | 1.4 x 1.0 x 0.7 | 4 | bubble | this list | 140 | |
| towel | prop | 2.2 x 0.2 x 1.4 | 1 | wood, red, enamel | this list | 48 | |

Bones: 27 of 63, all game bones (duck, sail0-3, tug0-2, speed0-2, bubble0-5, drop0-9). Blob: 41 700 splats.
