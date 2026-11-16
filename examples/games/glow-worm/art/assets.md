# Assets: Glow Worm, a dark cave lit by what lives in it (Cold Light, 3 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare); an orthographic
camera 58 degrees down, `orthoHeight` 6.2 m -> texel 0.0456 m. Splat spacing 0.07 m (1.5 texels) for
the floor, 0.09 m for the rim rocks (big, seen far), 0.045 to 0.05 m for the worm, the crystals, the
stalagmites and the pools of light. Palette: Cold Light (`palette.json`): `#08001f` (dark), `#444d84`
(slate), `#b2d5d1` (pale). Three colours, so every read has one value and the light is what tells
things apart:

| Ramp | Steps | Painted on | What it gives | Used for |
|---|---|---|---|---|
| rock | dark, slate, slate | slate (step 1) | with keyLight 1.0 and shadeSteps 2 most faces sink towards the dark through per-splat dither; tops facing the skylight stay slate | the rim of boulders |
| floor | dark, dark, slate | dark (step 0) and slate glints (step 2) from `floor.png` | the floor never steps up; a glint sinks to the dark in shade, so the stalagmites' shadows show as missing glints | the cave floor |
| stone | dark, slate, slate, pale | slate, lifted to step 2 with `"step": 1` | shade side dark, lit side slate, the skylight's side pale at the tips | stalagmites |
| glow | slate, pale | pale (step 1) and slate (step 0), unlit | the ink drops a pale silhouette to slate: every glowing thing has a slate rim | the worm, the crystals |
| dim | dark, slate | dark (step 0), unlit | always dark | the worm's eyes and mouth |
| halo | slate | the only step, unlit | ink cannot change it: a stipple stays a stipple | the pools of light (`halo.png`, alpha-masked) |
| spark | pale | the only step, unlit | ink cannot ring a 1-pixel speck | glow-worm specks on the rocks, sparks |

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| worm (hero) | character | 0.48 x 1.44 x 0.56 (head + four beads, p3 fit) | head 1 + beads pool 46 (from the gated model's head and first bead, `p4_parts.txt`) | glow, dim, halo | `worm/sheet.v1.png` | 620 | game: the head turns towards the pointer at 4.2 rad/s and crawls on (2.0 to 3.0 m/s); beads lie along the head's path every 0.25 m, a stepped squash-and-stretch wave runs back down them (12 fps); a gulp and a bulge running down the body when it eats; the tail tapers (0.87, 0.74, 0.6) and a new bead grows in; at a death the beads swell and go out from the head back |
| head pool, bead pool | effect | discs r 0.56 / 0.40 at y 0.03 | joined to the head and the bead | halo | this list | 32 | with their part |
| cave | terrain | floor 14 x 10, rim of 66 boulders r 0.5 to 1.1, 0.5 m (front) to 2.4 m (back) tall | 1 | floor, rock, spark (110 specks, 0.08 to 0.11 m) | this list | 4 400 | |
| stalagmite | prop (deadly) | 0.84 x 0.84 x 1.15 (spire r 0.3 and two smaller spires on a rubble skirt) | 3 (scale 1, 0.9, 0.85) | stone | this list | 120 | |
| crystal | prop (food) | 0.6 x 0.6 x 0.66 (x 1.35 in the scene), on a pool r 0.56 | pool `gem` 4 | glow (shards pale, +x faces slate), halo | this list | 170 | game: grows in with an overshoot (15 fps), turns and pulses stepped (8 fps), spins and shrinks into the mouth when eaten |
| spark | effect | 0.1 cube | pool `spark` 8 | spark | this list | 12 | game: bursts when a crystal is eaten and as beads go out |

Bones: head 1 + beads 46 + crystals 4 + sparks 8 = 59 of 63. Splats: 82 916 (floor 24 600, rocks 34 829,
the bead pool 14 870).

Layout (glTF metres, Y up, +Z towards the camera): the floor's top at y 0; the arena is the ellipse
x^2 / 4.0^2 + (z - 0.25)^2 / 2.45^2 < 1 (`make_env.py` and `game.as` share it), the rim of boulders just
outside it. Stalagmites at (-1.8, -0.35), (1.95, -0.55), (0.25, 1.5). The worm starts at (-2.6, 0.9)
heading right. Play area (`"bounds"`): 13 x 3.7 x 9.6 m round the cave.
