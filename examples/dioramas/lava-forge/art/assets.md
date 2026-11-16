# Assets: a dwarven forge on a floating volcanic island (Lava-GB)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 215 x 136 art pixels; `orthoHeight` 8 m -> texel
0.06 m. Splat spacing 0.09 m (1.5 texels). Palette: Lava-GB (`palette.json`, 4 colours: navy, purple,
magenta, salmon), 6 ramps sharing them; lava, cracks, fire and embers are `unlit` (emissive) ramps.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Animation |
|---|---|---|---|---|---|---|---|
| island | terrain | 7.2 x 7.2 x 3.5 | 1 | rock (painted navy, `step` +1 in the scene: purple), ember (cracks, unlit), lava (pool + channel, unlit) | this list | ~1300 | |
| forge | hero prop | 2.55 x 2.85 x 2.9 | 1 | stone (in the scene: the rock ramp, `step` +1: magenta), iron (`step` +1: a purple anvil), ember (mouth rim, unlit, `step` -1: purple), lava (fire, unlit) | `forge/sheet.v1.png` | 182 | |
| hammer (trip-hammer) | machine | 2.4 x 0.62 x 1.66 | 1 | wood (purple), iron (navy head), lava (hot bar + sparks, unlit, nocast) | this list | 200 | rigid: beam lifts 30 deg, pauses, drops in 2 frames; 1.5 s, 12 fps. Sparks: 8 cubes, own bone, constant keys, out on frames 16, 17, 0 and 1, shrunk inside the anvil otherwise |
| crane + crucible | prop | 1.2 x 0.3 x 2.2 | 1 | iron (`step` +1: purple), iron (chain, spacing 0.06), lava (melt) | this list | 116 | rigid: chain and crucible swing +-7 deg, 3 s |
| blobs | effect | 0.9 x 0.8 x 0.4 | 1 | ember (unlit) | this list | 80 | 4 rigid blobs bob out of the pool, 2 s, a quarter loop apart |
| embers | effect | 1.2 x 1.2 x 8 | 1 | lava (unlit, nocast) | this list | 384 | rigid helix: rise 1 m and turn 137.5 deg per 1.5 s, 8 stacked copies of 4 embers, seamless |
| lavafall | effect | 0.6 x 0.7 x 6 | 1 | lava (sheet magenta, globs salmon; unlit) | this list | 504 | rigid: globs fall 0.6 m per 1 s, 10 stacked copies, seamless |
| basalt | prop | 1.2 x 1.1 x 1.8 | 2 (0.6-0.7) | rock (`step` +1), ember (one glowing top) | this list | 100 | |
| rock | prop | 1.2 x 0.9 x 0.7 | 3 (0.7-1) | rock (`step` +1) | this list | 20 | |

Bones: hammer 2 (arm, sparks) + crane 1 + blobs 4 + embers 1 + lavafall 1 = 9 of 63.

Values (four colours): sky navy, island purple, forge magenta, lava salmon; every read gets its own
value and shade moves a material one step at most (`shadeSteps` 1). The models keep their painted
colours (the forge's gate record and lookdev goldens are unchanged); the scene's bake file lifts or
lowers materials with `"step"` (see the README's "Readability pass").

Layout (glTF metres, Y up, +Z towards the yaw-0 camera): forge at (0, 0, -0.8) facing +Z; the
trip-hammer's axle at (-1.45, 0, -0.55), yaw -22.4, so its head lands on the anvil (0, 0.84, 0.05) and
its beam passes above the furnace mouth; the pool at (1.4, 0, 1.6), r 0.8, its channel running to the
rim face at (2.263, 0, 2.61) where the lava falls (yaw -49.1: the fall's local +X is the face normal);
the crane's post 1 m from the pool centre (yaw 36.87 points its arm over it).

Seamless effects (both generated in `models/env/make_env.py`): N identical fields stacked one copy
spacing apart, the object moving one spacing per loop, so copy k takes copy k+1's place. The
pop-in end of the stack is hidden (inside the island's rock under the pool for the embers, inside
the 0.2 m lava sheet for the globs) and the pop-out end is outside the frame. The embers add a turn
of 137.5 degrees per copy (and per loop): the column is a helix and does not read as a repeat.
