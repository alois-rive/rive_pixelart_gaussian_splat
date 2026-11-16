# Assets: Bee Garden, a floating garden at neon dusk (FunkyFuture 8)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare); `orthoHeight`
7.6 m -> texel 0.056 m. Splat spacing 0.08 m (1.4 texels) for the world, 0.06 to 0.065 m for the
bee, the flower stems, the fence and the spider. Palette: FunkyFuture 8 (`palette.json`), 8 colours
in 7 ramps: lawn (navy, blue, cyan), petal (navy, plum, pink, white), cloud (blue, cyan, white),
gold (plum, orange, yellow, white), earth (navy, plum, orange), ink (navy, navy, plum: dark things
that still catch light; materials reach the second navy with `"step": 1`), glow (yellow, white, unlit).
No green in the palette: the lawn is blue with cyan clover, the stems cyan.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| bee | hero / character | 1.03 x 1.15 x 1.0 (scene scale 1.4) | 1 (3 bones: body, two wings) | gold, ink, petal, cloud | `bee/sheet.v1.png` | 432 | game: follows the pointer on a spring, faces its flight, banks into turns, bobs, dips to pollinate, pops; wings buzz between three stepped poses at 24 fps; tumbles down at game over |
| island | terrain | 9.2 x 9.2 x 2.7 | 1 | lawn (top, clover patches), earth (rim, underside, soil mounds) | this list | 2248 | |
| fence | architecture | picket arc on the back rim, 0.76 tall | 1 | petal (white, shades pink) | this list | 408 | |
| hive | prop | 1.1 x 1.1 x 1.6 | 1 | gold (straw skep), earth (stump), ink (entrance) | this list | 260 | |
| bush | foliage | 1.5 x 1.0 x 0.9 | 3 (0.8-1) | lawn (cyan) | this list | 60 | |
| rock | prop | 0.9 x 0.7 x 0.5 | 3 (0.7-1) | earth | this list | 20 | |
| flower_pink | prop | 0.9 x 0.4 x 1.1 (scale 1.3) | 4 (pool `rose`) | petal, gold, lawn | this list | 192 | game: grows in (stepped stretch), sways, droops as its time runs out, pops when pollinated, sinks away |
| flower_white | prop | 0.9 x 0.4 x 1.1 (scale 1.3) | 3 (pool `daisy`) | cloud, gold, lawn | this list | 232 | as above |
| wilt | prop | 0.6 x 0.8 x 0.7 (scale 1.3) | 4 (pool `wilt`) | petal (plum), gold (orange), lawn (blue) | this list | 180 | game: lands with a squash where a flower wilted, sinks away |
| spider | character | 1.0 x 0.8 x 0.55 (scale 1.1) | 1 | ink, petal (eyes, specks) | this list | 256 | game: walks to the guarded flower and circles it (stepped scuttle), crouches (squash), leaps (stretch, arc), lands (squash) |
| sparkle | effect | 0.2 | 10 (pool `spark`) | glow (unlit, nocast, specks) | this list | 20 | game: pollen bursts, falling and shrinking, stepped spin |

Bones (game bones, `"bone"` / `"copies"` in `scene.bake.json`): bee 1 + wings 2 + flowers 7 + wilts 4 +
spider 1 + sparkles 10 = 25 of 63. Splats: 32 972 (island 20 000 of them).

Layout (glTF metres, Y up, +Z towards the camera): the island's lawn top at y 0, radius 4.6; seven
flower slots (soil mounds in the island mesh, the same list in `make_env.py` and `game.as`) at
(0, 0.3), (2.4, 0.4), (1.3, 2.4), (-1.2, 2.5), (-2.5, 0.5), (-1.1, -1.7), (1.4, -1.6); the hive at
(-3.25, -2.45) facing the middle; the spider's den by the back-right bush (3.0, -1.6). The bee flies
at y 1.5; a flower head is at y 1.25. Play area (`"bounds"`): 9.6 x 5 x 9.6 m around the island.
