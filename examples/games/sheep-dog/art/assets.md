# Assets: sheep dog (DawnBringer 16)

Art grid: 640 x 400 artboard, `pixelSize` 2 -> 320 x 200 art pixels. Orthographic camera, yaw 0, pitch 42,
`orthoHeight` 8.4 m: texel 8.4 / 202 = 0.042 m (the renderer counts the two spare art pixels). Splat spacing 0.07 m (1.7 texels) for the world, 0.05-0.06 m
for the dog, the sheep and the fence (they are small and thin). The camera target sits at z -0.621 m, a whole
number of art pixels along the view's up axis, so the snap offset is zero and the HUD shares the scene's grid.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| dog | hero / player | 0.47 x 1.16 x 0.88 | 1 (game bone `dog`) | fur, cream, face | `dog/sheet.v1.png` | 228 | game-driven: follows the pointer, a stepped gallop (bounce + nose rocking), skids squash, panting |
| sheep | character | 0.72 x 1.1 x 1.0 | 6 (game bones `sheep0`..`sheep5`) | wool, face | this list | 184 | game-driven: flee, flock, graze (nose down, chewing), a startle squash, a bouncing trot, a hop when penned |
| ground | terrain | 16 x 13 plane | 1 | grass (64 x 52 texture: tufts, flowers) | this list | 128 | |
| fence | architecture | the meadow 12.8 x 8.6, the pen 3.4 x 2.6 | 1 | wood (rails), cream (posts) | this list | 756 | |
| gate | prop | 1.8 x 0.1 x 0.62 | 1 (game bone `gate`) | red | this list | 60 | lies open along the fence; swings shut when all six are penned |
| pond | prop | r 1.3 + stone ring | 1 | water, stone | this list | 210 | |
| rock | prop | 1.0 x 0.8 x 0.5 | 3 | stone | this list | 80 | |
| tree | foliage | 1.9 x 1.9 x 2.9 | 6 | wood, leaf (sway) | this list | 92 | wind sway |
| hay | prop | 0.9 x 0.8 x 0.8 | 1 | grass (#dad45e) | this list | 32 | |
| trough | prop | 1.2 x 0.5 x 0.4 | 1 | wood, water | this list | 60 | |

Bones: 8 of 63, all game bones (gate, dog, sheep0-5). Blob: 74 000 splats (grass 31 000, fence 17 200,
tree leaves 11 600, the six sheep 6 400, the dog 1 250).

Play area (`"bounds"` in the bake): x -8..8, y -0.2..2.8, z -6.5..6.5. The fence, the pen (x 3.0..6.4,
z -4.2..-1.6) and the gate gap (x 3.7..5.5) are the same numbers in `models/env/make_env.py` and `scene/game.as`.
