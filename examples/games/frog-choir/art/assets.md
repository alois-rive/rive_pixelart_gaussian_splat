# Assets: Frog Choir, a marsh pond at dawn (Eggy 15)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare); orthographic,
`orthoHeight` 6.8 m -> texel 0.05 m, pitch 20 degrees from the near bank, yaw 0. Splat spacing 0.07 m
(1.4 texels) for the world, 0.11 m for the water (foreshortened 3x at this pitch), 0.055 m for the
frogs (0.046 at their bake scale 1.2), 0.05 m for the reeds, 0.04 m for the ripples.

Palette: Eggy 15 (`palette.json`), 15 colours in 16 ramps. Five choir ramps share their black and walk
through the palette's saturated colours: frog_green (black, moss, teal, lime, cream), frog_red (black,
indigo, red, pink, yellow), frog_gold (black, red, orange, yellow, cream), frog_blue (black, indigo,
slate, cyan, cream), frog_violet (black, indigo, magenta, pink, yellow): each frog is painted on step 2
(3 for the blue) and shades into the night colours. belly (slate, mauve, bone, cream), eye (red, orange,
yellow, cream: irises, the throat sac, lotus hearts), ink (black, black, slate), pad (black, moss, teal,
lime: pads, moss, reeds painted on moss so they stand dark against the sky), water (black, indigo,
magenta, pink), glint (orange, yellow, cream; unlit), wood (black, slate, mauve, bone), stone (black,
moss, slate, mauve, bone), lotus (indigo, magenta, pink, cream), sun (yellow twice: unlit, and the ink
cannot darken its rim), mist (bone twice). Roles: sky pink over orange (`horizon` 0.2), void black.
Every colour is in a ramp.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| frog | hero / character | 0.91 x 0.81 x 0.75 (scene scale 1.2) | 5 (bones `frog0`-`frog4`), one skin each | frog_*, belly, eye, ink | `frog/sheet.v1.png` | 784 | game: dips on every beat, draws breath (lean back, squash) as its ring closes, sings (stretch up, head back, sac puffed, a wobble), sulks on a sour note (squash, head shake), heads down at game over; a slow stepped breath of the sac while idle; grooves (stepped roll) at a combo of 8 |
| sac | hero part | 0.48 x 0.41 x 0.38 (scale 1.2) | 5 (pool `sac`) | eye (yellow) | the frog's spec | 48 | game: hangs from its frog's chin (`transform`), inflates 0.45 -> 1.35 when it sings, hidden otherwise |
| pond | terrain | 14 x 16, cells 0.25 | 1 | water (indigo, magenta sheen dashes), glint (the sun's broken reflection, unlit) | this list | 7168 | |
| bank | terrain | far ridge 16 x 1.5 x 0.6 + two side lumps | 1 | pad (moss top), stone (mud face) | this list | 466 | |
| reeds | foliage | clump 0.7 across, 0.8-1.55 tall, 3 cattails | 12 (0.6-1.2) | pad (moss), wood (cattails) | this list | 216 | sway (wind) |
| pad | prop | 1.24 across, 0.06 thick, a notch | 9 (0.6-1.05) | pad | this list | 40 | |
| lotus | prop | pad 1.0 across, flower 0.4 | 4 (0.8-1.0) | pad, lotus, eye | this list | 120 | |
| stone | prop | 1.3 across, top 0.33 above the water | 1 (the lead singer's seat) | stone, pad (moss top) | this list | 25 | |
| log | prop | 3.2 x 0.56, sunk 0.12 | 1 | wood (bark, bone cut ends) | this list | 20 | |
| sun | effect | disc 3 m (scale 0.9 -> 2.7) | 1 | sun (unlit, nocast) | this list | 14 | |
| cloud | effect | four bars 1.6-3.6 x 0.13 | 1 | mist (unlit, nocast) | this list | 48 | |
| mist | effect | wisp 2.6 x 0.9 x 0.26 | 4 (pool `mist`, shown at 0.75) | mist (unlit, nocast) | this list | 20 | game: drifts along the foot of the far bank in 5 cm steps, wrapping |
| ripple | effect | ring 2.4 across, tube 0.09 | 8 (pool `ripple`) | mist (unlit, nocast, specks) | this list | 256 | game: runs out from a frog that sings (scale 0.5 -> 1.05, stepped at 12 fps) |

Bones (game bones in `scene.bake.json`): frogs 5 + sacs 5 + ripples 8 + mist 4 = 22 of 63.
Splats: 66 362 (water 16 100, banks 15 800, reeds 11 900, frogs 8 700, ripples 4 900).

Layout (glTF metres, Y up, +Z towards the camera; the water at y 0): the choir in an arc facing the
camera: frog0 (-3.5, 0.8) yaw 14, frog1 (-1.8, -0.15) yaw 7, frog2 on the stone (0, -0.7) at y 0.31,
frog3 (1.8, -0.15) yaw -7, frog4 (3.5, 0.8) yaw -14 (the same list is in `game.as`). The far bank runs
across z -4.2 to -5.7; the sun stands at (-2.6, -0.25, -7) behind it, its reflection runs down the
water at x -2.6. Play area (`"bounds"`): 14 x 2.8 x 19 m.
