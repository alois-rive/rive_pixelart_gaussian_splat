# Assets: beach balls on a beach at sunset (Journey)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels. Orthographic camera from the front,
a little above (yaw 0, pitch 15), 8 m tall: texel 0.060 m. Splat spacing 0.07 (1.2 texels), finer for the
ball's caps, the crab and the castle's details, 0.1 to 0.12 for sand, sea and sky pieces. Palette: Journey
(`palette.json`, 64 colours), thirteen ramps; the sand and sea textures mix ramps. The sea, sun and clouds are
unlit (a sunset sea keeps its painted colours); the light comes from the front left so the balls read.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| ball | hero | 0.8 (baked x 1.6) | pool of 4 | red, blue, yellow, white, green | `ball/sheet.v2.png` | 240 | game: falls (floaty gravity), kicked up and sideways, spins about the vertical, squashes on a kick, stretches with speed, flattens when it lands |
| shadow | effect | 1.2 x 0.84 | pool of 4 | sand | this list | 12 | game: under each ball, shrinks with its height |
| puff | effect | 0.32 | pool of 8 | sand | this list | 20 | game: sand thrown up by a landing |
| spark | effect | 0.36 | pool of 6 | glow (unlit) | this list | 24 | game: a burst at each kick |
| crab | character | 0.9 x 0.5 x 0.45 (x 1.3) | 1 | red, white | this list | 200 | game: scuttles (stepped), waits, runs from a landing ball |
| beach | terrain | sand 18 x 6.7, sea 18 x 13 | 1 | sand, foam, sea, glow (textures; sea unlit) | this list | 14 | |
| foam | effect | 19 x 0.4 | 1 | foam | this list | 228 | baked: washes in and out, 4 s loop, 12 fps (1 bone) |
| sun | effect | 3.8 disc | 1 | glow (unlit) | this list | 128 | |
| clouds | effect | 6 slabs | 1 | pink, glow (unlit) | this list | 144 | |
| palm | foliage | 2.5 x 2.5 x 6 | 1 | trunk, leaf (sway, double) | this list | 200 | wind sway |
| umbrella | prop | 3 x 3 x 3 | 1 | white, pink | this list | 40 | |
| castle | prop | 1.8 x 0.8 x 1.7 | 1 | sand, red | this list | 180 | |
| towel | prop | 2.2 x 1.1 | 1 | pink, white (texture) | this list | 10 | |
| rocks | prop | 2.5 x 1.5 x 1.5 | 1 | rock | this list | 80 | |

Bones: 24 of 63 (the foam's track, and 23 game bones: crab, ball0-3, shadow0-3, puff0-7, spark0-5). Blob:
48 400 splats.
