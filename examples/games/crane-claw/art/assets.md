# Assets: Crane Claw (Peachy Pop 16, 16 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; a fixed perspective camera looking
into the machine through its glass (fov 33, eye (0, 3.15, 6.2), target (0, 1.2, 0)) -> texel about
0.03 m at the pile, 0.0275 m at the claw. Splat spacing 0.04-0.06 m (1.4 to 2 texels). Palette: Kerrie
Lake's Peachy Pop 16 in ten ramps (cabinet, chrome, duck, peach, lilac, mint, rose, red, glow, ink); the
whole cabinet is pinks and magentas, the ball pit cool blues and lilac so the warm toys stand out; bulbs,
the claw's lamp and confetti are `unlit`.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Splats | Motion |
|---|---|---|---|---|---|---|---|---|
| claw (hub, prong, cable) | hero / player | 0.86 x 0.86 x 1.1 | hub 1, prong 3 (`prong0-2`), cable 1 | red, chrome, glow (lamp), ink (cable) | `claw/sheet.v1.png` | 212 | 410 + 3 x 48 + 285 | game: travels on the gantry, drops, swings its prongs shut in 8 stepped poses, lifts, sways with a loose grab |
| cabinet | architecture | 8.4 x 3.9 x 2.6 | 1 (static) | cabinet (wallpaper texture, walls, frame, floor), rose (trim), chrome (rails), red + duck (chute), ink (hole) | this list | ~500 | 35 202 | none |
| wallpaper | texture | 48 x 40 over 4.4 x 3.6 m (0.09 m a texel) | on the back wall | cabinet: candy stripes #ce186a / #fb4771, stars #ff8686 | drawn by `make_env.py` | | | |
| pit | terrain | 4.2 x 2.3, ~170 balls r 0.13 | 1 (static) | chrome (blue, periwinkle), lilac, cabinet (heaps) | this list | ~3500 | 15 618 | none |
| bulbs | effect | 23 bulbs r 0.095 on the back wall's top edge and corners | 2 sets (`bulbsA`, `bulbsB`) over unlit ones | glow (unlit) | this list | ~460 | 1 007 | game: chase lights, faster in the last 10 s, all blinking at TIME UP |
| bridge, trolley | props | beam 2.1 m; box 0.4 m | 1 each | chrome; red, duck | this list | 12; 24 | 602; 376 | game: follow the claw in x (bridge) and x-z (trolley) |
| duck | toy (10 points) | 0.5 x 0.75 x 0.62 | 4 (`duck0-3`) | duck, ink (eyes) | this list | ~200 | 3 102 | game: rests on the pile, hangs and swings in the claw, falls and bounces, drops in from the top when won |
| bear | toy (20) | 0.5 x 0.42 x 0.72 | 3 (`bear0-2`) | rose, ink | this list | ~300 | 2 146 | as duck |
| bunny | toy (20) | 0.4 x 0.42 x 0.86 | 2 (`bunny0-1`) | lilac (white fur), rose (nose), ink | this list | ~200 | 1 156 | as duck |
| ball | toy (10) | r 0.27 | 3 (`ball0-2`) | chrome (white), red, duck, mint | this list | 80 | 1 419 | as duck |
| gem | toy (50, the jackpot) | 0.5 x 0.43 | 1 (`gem`) | mint | this list | 36 | 361 | as duck; comes back only after 14 s |
| confetti | effect | 0.1 | 4 yellow (`confy0-3`) + 4 mint (`confm0-3`) | glow, mint (unlit) | this list | 12 | 195 | game: bursts out of the chute with each prize |

Bones: 30 game bones of 63. Splats: 62 023 in the scene blob.

Layout (glTF metres, Y up, the camera on +Z): the cabinet's inside is x -2.2..2.2, z -1.1 (back wall)
.. 1.35 (the glass), floor y 0; the frame round the glass hides the outside. The pile's top is
0.12 + 0.36 exp(-((x-0.25)^2/2.4 + (z+0.15)^2/1.1)) + 0.09 (the balls' tops; `models/env/pile.json`);
the game uses the same function. The prize chute is the front-left corner (x < -1.3, z > 0.3), its drop
point (-1.75, 0.7). The claw travels at y 2.05 (the hub's origin, the collar's bottom), the trolley at
y 2.8, the bridge at 3.06. Bounds [-4.2, -0.3, -1.6] .. [4.2, 3.9, 1.6].
