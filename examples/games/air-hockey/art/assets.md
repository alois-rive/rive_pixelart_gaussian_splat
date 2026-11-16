# Assets: Air Hockey, a glowing table in a dark arcade (SLSO-CLR17)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare); `orthoHeight`
4.6 m -> texel 0.034 m. Camera: orthographic orbit, yaw 0, pitch 50, target (0, 1.06, -0.75): the
player's long side of the table towards the camera, the rink (y 1.06) across the middle of the frame,
the cabinets at the top fading into the dark (fog towards the void colour). Splat spacing: 0.04 m for
the rink (1.2 texels), 0.043 m for the rest of the table, 0.05-0.055 m for the room, 0.032 m for the
mallets (0.028 m after their 0.86 scale), 0.03 m for the puck and sparks.

Palette: SLSO-CLR17 (`palette.json`), 17 colours in 11 ramps: steel (ink, slate, steel, grey, ice),
rink (slate, blue, teal, mint, ice), neon (plum, purple, pink: the unlit rails), cpu (ink, plum,
purple, pink), player (ink, red, orange, yellow), puck (orange, yellow, lime: unlit), leaf (ink,
greens, lime), carpet (ink, slate, plum), screen (blue, teal, mint, ice: unlit), spark and pspark
(one repeated colour each: tiny unlit particles are not inked into rings). Roles: the sky and the
void are the ink (the room ends in darkness), fog ink-slate.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| table | hero / playfield | 5.02 x 2.45 x 1.21 (4.7 body + 0.16 pockets each end) | 1 | rink (textured), neon (rail caps unlit, rail sides lit), steel (body, legs, pockets), player (coin plate) | `table/sheet.v1.png` | 188 | none (static, bone 0) |
| floor | terrain | 9 x 6.5, a slab top at y 0 | 1 | carpet (texture: slate with plum confetti) | this list | 2 | |
| cabinet | prop | 0.8 x 0.72 x 1.75 | 4 (bodies on cpu / steel / player ramps) | body ramp, screen or leaf (unlit), neon / puck / screen marquee (unlit), buttons | this list | 86 | |
| stool | prop | 0.48 round, 0.76 tall | 2 | player (seat), steel (post) | this list | 84 | |
| plant | foliage | 0.76 x 0.7 x 1.45 | 2 (1, 0.85) | steel (pot), leaf | this list | 82 | |
| mallet_p / mallet_c | character (the paddles) | 0.44 round, 0.32 tall, baked at scale 0.86 (0.38 round) | 1 each (bones `malletP`, `malletC`) | player / cpu | this list | 106 | game: follows the pointer or the bot, leans into its motion (up to 14 degrees), squashes on a hit (stepped) |
| puck | prop | 0.28 round, 0.06 thick | 1 (bone `puck`) | puck (unlit: it glows) | this list | 28 | game: slides, spins with its speed, pops in at a face-off, drops into a pocket |
| ghost | effect | the puck at 0.8 to 0.35 scale | 4 (pool `ghost`) | puck one step down (unlit, nocast) | this list | 28 | game: the trail of a fast puck, sampled at 20 fps |
| spark | effect | 0.09 | 10 + 10 (pools `spark` yellow, `pspark` pink) | spark, pspark (unlit, nocast, specks) | this list | 20 | game: bursts on hard hits, rail smacks and goals, fall and bounce on the rink, shrink in steps |

Bones (game bones, `"bone"` / `"copies"` in `scene.bake.json`): malletP 1 + malletC 1 + puck 1 +
ghosts 4 + sparks 20 = 27 of 63. Splats: 44 306 (the floor 16 245, the table 14 004).

Layout (glTF metres, Y up, +Z towards the camera): the floor's top at y 0; the table centred at the
origin, its rink at y 1.06, inside the rails x -2.16..2.16, z -1.035..1.035, goal mouths |z| < 0.38
at both ends (the player's goal at -x, the computer's at +x); four cabinets along the back at
z -2.45..-2.5 (x ±2.05, ±3.0), stools at the front corners, plants by the back corners. Play area
(`"bounds"`): 9.2 x 2.2 x 6.6 m.
