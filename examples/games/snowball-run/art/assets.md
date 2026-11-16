# Assets: Snowball Run (Ice Cream GB, 4 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; orbit camera yaw 0, pitch 20,
orthographic 10 m -> texel 0.075 m. Splat spacing 0.11 m (1.5 texels); the ground 0.14, the mountains
0.16 (flat, fogged). Palette: Ice Cream GB (plum, coral, peach, cream) shared by six ramps; materials
are told apart by their painted step (snow cream, needles coral, bark and coal plum), Bayer dither.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| snowman | hero prop | 1.7 x 0.95 x 2.0 | 4 (pool `snowman0-3`) | snow, bark (hat, coal, arms; spacing 0.08), accent (nose, band, scarf; 0.065) | `snowman/sheet.v1.png` | 378 | game: pops in, a stepped idle sway, flattened in two frames, sinks |
| ball (the snowball) | player | r 1.0 (scaled 0.36-1.12) | 1 (`ball`) | snow (cream + peach packed snow), bark (twigs, pebbles) | this list | 164 | game: rolls (pitch by distance / radius, roll by swerve), squash on hits, blinks while recovering |
| pine | foliage | 2.0 x 2.0 x 2.6 | 9 on the piste (`tree0-8`) + 12 on the banks (`side0-11`) | bark, pine, snow | this list | 140 | game: pops in, wobbles (stepped) when hit |
| ground | terrain | 22 x 25, banks 1.5 high | 1 | snow | this list | 192 | static (plain snow: the moving pieces carry the speed) |
| mountains | terrain | a range 28 m wide, peaks 4-6 m | 1 | far (coral rock, cream caps) | this list | 160 | static, fogged |
| mound | prop | 1.9 x 1.2 x 0.4 | 6 (`mound0-5`) | snow | this list | 12 | game: slides, makes the ball hop |
| rock | prop | 1.0 x 0.8 x 0.6 | 4 (`rock0-3`) | pine (coral), snow | this list | 20 | game: slides along the piste's edges |
| spray | effect | 0.28 | 8 (`spray0-7`) | flake | this list | 20 | game: thrown off the rolling ball |
| chunk | effect | 0.5 | 6 (`chunk0-5`) | snow | this list | 20 | game: thrown on hits and the final burst |
| snowfall | effect | 22 x 23 x 6 | 1 | flake (cream only: the ink cannot ring it) | this list | 2160 | baked rigid loop: two stacked fields fall 6 m in 4 s (12 fps) |

Bones: 52 game bones (ball 1, tree 9, side 12, snowman 4, mound 6, rock 4, spray 8, chunk 6) + the
snowfall track 1 = 53 of 63. Splats: 80 647 (the 21 pines are 40 % of them).

Why the ball is baked big: a splat's disc does not grow with its bone's scale, so a ball baked at
r 0.5 and scaled up shows gaps. It is baked at r 1.0 at a finer spacing (0.09) and only scaled down.

Layout (glTF metres, Y up, +Z towards the camera): the piste is flat for |x| < 5.5, banks rise to 1.5 m
by |x| 8; the snowball's centre stays at z 3.4; obstacles come up at z -12.6 (the far edge, in the
fog) and leave past z 9.5; the mountains stand 16-19 m back with their bases sunk 3 m.
