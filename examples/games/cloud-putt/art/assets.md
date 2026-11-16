# Assets: Cloud Putt, nine holes of mini golf on a floating cloud island (Taffy 16)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare); `orthoHeight`
7.6 m -> texel 0.056 m. Splat spacing 0.09 m (1.6 texels) by default: the felt 0.11, the borders 0.1,
the cloud ground 0.17 and the island's skirt 0.25 (big painterly cloud dabs far below the course), the
windmill 0.05 to 0.08, the ball and flags 0.045 to 0.05. Camera: orthographic, yaw 0 (never turns:
faces looking north or straight sideways are deleted from the course meshes), pitch 40, the target
gliding from hole to hole (`scene/game.as`); one sun from the front left (yaw -35, pitch 55, key
0.4, highlight 0.9, `shadeSteps` 1), per-splat dither, ink 1, a periwinkle-to-peach sky.

Palette: Taffy 16 (navy, periwinkle, ice, white, peach, pink, rose, indigo, blue, green, lime,
yellow, orange, red, wine, slate) in 9 ramps: felt (slate, green, lime, yellow), cloud (slate,
periwinkle, ice, white), wood (slate, wine, red, orange, peach), candy (slate, wine, rose, pink,
peach), water (navy, indigo, blue, ice, white), gold (red, orange, yellow, white), pit (navy, slate,
periwinkle), and the unlit spark (yellow) and spray (white).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| windmill (tower + sails) | hero | 2.98 x 2.38 x 3.40 (as modelled); x 1.3 in the scene | 1 (tower static, sails 1 bone) | candy, cloud, water, gold, wood, pit | `windmill/sheet.v1.png` | 288 | game: the sails turn a quarter turn every 1.6 s, stepped at 12 fps, about the hub; they block the tunnel in rhythm |
| greens (felt) | terrain | nine greens, 2.6 to 6 m wide, 7.8 to 9.8 m long | 9 (3 files, a row each) | felt (green, lime stripes), candy (tee pad) | this list + `models/course/course.py` | 71 k (0.1 m grid for the height fields) | none (height fields baked into the felt) |
| borders | level piece | 0.2 thick, top 0.24 above the felt beside it, in pieces of at most 0.8 m | 365 boxes (with the plinth), 1 mesh | wood (orange sides, peach tops) | this list | 1 466 | none |
| plinth | level piece | 3.2 x 2.86 x 0.72 | 1 (under the mill) | wood | this list | (in borders) | none |
| cups | level piece | r 0.26, 0.3 deep | 9 | pit | this list | 306 | none |
| water, bridge, gap pit | level piece | the brook 2 x 5.2, the pond 2.7 x 1.3, the bridge 2 x 1 (arch 0.2), the gap 1.4 x 2.6, 1.3 deep | 1 mesh | water (indigo, blue ripples), cloud (banks, gap floor), wood (deck) | this list | 2 332 | none |
| island | terrain | the cloud ground 38.8 x 27 (a superellipse, power 8), the skirt 4.2 deep | 1 | cloud (white, ice puffs) | this list | 36 k | none |
| ball | character | r 0.16 | 1 | cloud (white), candy (pink band) | this list | 80 | game: rolls (its band turns with the distance), flies off the kicker, sinks into cups, squashes while aimed |
| flag | prop | pole 1.35, pennant 0.62 x 0.42 | 9 (pool `flag`) | cloud (pole), gold (pennant, knob) | this list | 48 | game: waves (stepped yaw), lifts out of the cup as the ball nears, hops and spins on a hole |
| gate (sliding block) | level piece | 0.5 x 1.1 x 0.45 | 2 (pool `gate`) | candy, cloud (top) | this list | 10 | game: slides across hole 4's lane (periods 3.2 and 2.6 s) |
| post (bumper) | level piece | r 0.3, 0.5 tall | 7 (static, hole 7) | candy, cloud stripes, gold cap | this list | 88 | none |
| tree | foliage | crown r 0.62, 2 m tall | 4 | wood, candy | this list | 32 | none |
| puff | effect / terrain | r 1 (scaled 0.85 to 2.6) | 23 static round the rim and under the island, 3 drifting (pool `cloudlet`) | cloud | this list | 74 | game: three clouds drift past the island |
| drop | effect | r 0.07 | 6 (pool `drop`) | spray (unlit, specks) | this list | 20 | game: the splash, or a puff from the cloud gap |
| ripple | effect | ring 0.7 across | 1 | spray (unlit) | this list | 128 | game: grows on the water after a splash (stepped scale) |
| spark | effect | r 0.07 | 10 (pool `spark`) | spark (unlit, specks) | this list | 20 | game: confetti from the cup (birdie 6, eagle 8, hole in one 10) |

Bones (game bones, `"bone"` / `"copies"` in `scene.bake.json`): sails 1 + gates 2 + flags 9 + ball 1 +
cloudlets 3 + drops 6 + ripple 1 + sparks 10 = 33 of 63. Splats: 111 801 in the scene blob.

Layout (glTF metres, Y up, +Z towards the camera): the cloud ground at y 0, the felt at 0.12 + h(x, z)
(per hole, `models/course/course.py`). Nine cells of 11 x 7.6 m: holes 1-3 along the back row (z
-8.4, x -12 / 0 / 12), 4-6 back along the middle (z 0), 7-9 along the front (z 8.4). The windmill
stands on hole 1's raised deck at (-13.6, 0.72, -9.95), its sails' hub at (-13.6, 2.83, -8.44). The
island: |x / 19.4|^8 + |z / 13.5|^8 = 1. Play area (`"bounds"`): 44 x 11.5 x 33 m.
