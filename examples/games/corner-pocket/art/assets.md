# Assets: Corner Pocket, a pool table in the corner of the Crooked Lamp at night (Chromatic16)

Art grid: 640 x 400 artboard, `pixelSize` 2 -> 322 x 202 art pixels (with the spare), HUD 320 x 200;
`orthoHeight` 2.8 m -> texel 0.0139 m. A ball (9 cm) is about 7 art pixels: `pixelSize` 3 would
leave it at 4. Camera: orthographic orbit, yaw 0, pitch 48, target (0, 0.71, -0.5): the table's near
long side towards the camera, the felt across the middle, the back wall's window, neon sign and
dartboard along the top. Splat spacing: 0.014 m for the balls (1 texel: they are small and must stay
round), 0.011 m for the cue, 0.02-0.021 m for the table and lamp (1.5 texels), 0.016-0.022 m for the
props, 0.028-0.03 m for the floor and wall.

Palette: Chromatic16 (`palette.json`), 16 colours in 14 ramps: felt (navy, green, lime), wood (black,
maroon, brown, orange, peach), hole (black alone: pockets and cords stay black), glow (orange, peach,
yellow: unlit), cue (grey, white), sun (brown, orange, yellow), moon (navy, blue, cyan), night (black,
navy, blue), wall (black, navy, blue, grey), leather (black, maroon, red), neon (purple, pink: unlit),
sky (navy, blue, cyan, white: unlit, the night through the window), spot (grey, white), dot (maroon,
red: the cue ball's spots). Roles: sky and void black (the pub ends in the night), fog navy (unused).
Every colour sits in a ramp; a frame shows 14 of the 16 (purple and lime only at band edges).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| table (with its lamp) | hero / playfield | 2.32 x 1.32 x 0.75 table, a 1.33 x 0.44 shade 1.22-1.49 up, cords to 1.94 | 1 | felt (felt, cushions, shade), wood (rails, legs; apron a step up in the scene), hole (pockets, cords), glow (the strip under the shade, unlit) | `table/sheet.v1.png` | 250 (214 table + 36 lamp) | table static; the lamp is a game bone (`lamp`) hung 0.42 m higher in the scene, swinging a degree or so after a break (stepped, 10 fps) |
| floor | terrain | 6.6 x 3.6 | 1 | wood (maroon boards, black joints, brown knots: `textures/boards.png`) | this list | 2 | |
| wall | architecture | 6.6 x 2.6, a wainscot to 0.9 | 1 | wall (navy-blue wallpaper, `paper.png`), wood (wainscot panels `panel.png`, the dado rail) | this list | 8 | |
| window | prop | 0.92 x 0.11 x 0.94 | 1 | wood (frame), sky (unlit panes: a crescent moon, stars, roofs: `night.png`) | this list | 62 | |
| dartboard | prop | 0.62 square backboard, a 0.46 m board | 1 | wood (backboard), hole (rim), board texture on its nearest ramps (`dartboard.png`: 12 sectors, double and treble rings, bull) | this list | 56 | |
| neon sign | prop / effect | 0.6 x 0.45 (a crescent moon and a star of 4.5 cm tubes) | 1 | neon (unlit, nocast) | this list | 192 | |
| stool | prop | 0.38 round, 0.76 tall | 3 | leather (seat), wood (legs, footring) | this list | 78 | |
| side table | prop | 0.56 round, 0.7 tall, a pint and a coaster | 1 | wood, glow (ale), cue (the head) | this list | 154 | |
| cat (Biscuit) | character | 0.42 long, asleep on the left stool | 1 | wood (orange fur, peach muzzle, brown ears) | this list | 84 | |
| tail | character part | 0.24 | 1 (bone `tail`) | wood | this list | 36 | game: sways in its sleep, flicks when a ball drops (stepped, 8 fps) |
| cue | prop | 1.1 long, 0.014-0.027 thick (exaggerated) | 1 (bone `cue`) | wood (peach shaft, maroon butt), moon (chalked tip) | this list | 60 | game: lies on the aim line, draws back with the power, strokes |
| balls | game pieces | 0.09 round (10 x 6 faceted sphere, a spot cap at each pole) | 16: bones `cueball`, `sun0-6`, `moon0-6`, `night` | cue + dot, sun + spot, moon + spot, night + spot | this list | 100 | game: roll (turned about the axis across their motion every frame), drop into pockets |
| chalk | prop | 0.04 cube on the near rail | 1 | moon | this list | 10 | |

Bones (game bones, `"bone"` / `"copies"` in `scene.bake.json`): lamp 1 + tail 1 + cue 1 + balls 16 =
19 of 63. Splats: 77 927 in the scene blob (floor 25 442, wall 18 910, table 13 000, the 16 balls
about 1 900).

Layout (glTF metres, Y up, +Z towards the camera): the floor's top at y 0; the table centred at the
origin, its felt at y 0.71, the cushion noses at |x| 1.0 and |z| 0.5 (the game's play area), the
pockets at the four corners and the middle of the long sides; the back wall's face at z -1.15 with
the window (x -1.55), the neon (x -0.85, y 1.45) and the dartboard (x 1.6, y 1.42) on it; the lamp's
cords hang from (0, 2.36, -0.06); stools at x -1.72 (Biscuit on it), x 1.78 and the near right
corner, the side table at the near left. Play area (`"bounds"`): 6.6 x 2.6 x 3.65 m.
