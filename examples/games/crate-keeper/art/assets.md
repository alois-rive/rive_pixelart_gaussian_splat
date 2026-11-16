# Assets: Crate Keeper (Fairydust 8)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; orthographic, `orthoHeight` 8.6 m,
yaw 45, pitch 42 (a high isometric view) -> texel 0.063 m (8.6 m over the art canvas's 136 rows). Splat
spacing 0.1 m (1.6 texels) for the benches, 0.07 for crates, 0.04 to 0.06 for the keeper (baked at 1.3x),
0.12 for the benches' skirts. A cell is 1 m; the largest bench (8 x 7 cells) fits the view with the HUD in
the empty corners of the iso diamond.

Palette: [Fairydust 8](https://lospec.com/palette-list/fairydust-8) (`palette.json`, 8 colours: dark purple
#634b7d, violet #6461c2, magenta #c45d9f, teal #2ba9b4, pink #e39aac, mint #93d4b5, cream #f0dab1, white
#f0f6e8) in 12 ramps. Value plan (a night greenhouse): the void is the darkest purple; the benches' floors
are a mid-dark slate checker (violet and teal) so that everything the player tracks is lighter or warmer
than them: the keeper's cream hat, the pink and magenta crates, the white pads, the white arrow. The walls
are hedges: mint tops on violet planter sides, so the room outline reads at a glance. A crate on a pad
turns to its unlit cream-and-white twin (a lantern), the only unlit thing on a bench.

| Ramp | Steps | Used by |
|---|---|---|
| tile | purple, magenta, pink, cream, white | (kept for the HUD's palette indices; the first floor tried) |
| wood | purple, magenta, pink, cream | crates (magenta frame, pink panels), pots, the hat's ribbon |
| planter | purple, violet, teal | wall sides (violet) |
| leaf | purple, violet, teal, mint, white | hedge tops (mint), bushes (teal), crate sprouts, the keeper's leaf and can |
| cloth | purple, violet, teal, mint | the keeper's overalls (teal) and boots (violet) |
| skin | purple, magenta, pink, cream | the keeper's face and hands (pink), eyes (purple) |
| straw | magenta, pink, cream, white | the keeper's hat (cream); the glowing crate's frame and panels (unlit, `"step": 2`); dust puffs (unlit) |
| glow | mint, white | pads (white), the glowing crate's soil and sprouts (unlit) |
| bloom | magenta, pink, white | flowers on the hedges; the pink "blocked" arrow (unlit) |
| mark | white, white | the white direction arrow (unlit, one colour so the ink cannot ring it) |
| dusk | purple, purple, violet | the benches' skirts, the crates' soil |
| slate | purple, violet, teal, mint | the floor checker (violet and teal) |

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| keeper (Tansy) | hero / character | 0.66 x 0.63 x 0.85 (shown at 1.3x: 1.1 m tall, the hat 0.75 m across) | 1 | cloth, skin, straw, wood, leaf | `keeper/sheet.v1.png` | 516 | game bone `keeper`: slides a cell per step (smoothstep, a little hop, squash and stretch), turns to the step, bumps into walls, a crouch-hop-land between benches, a stepped idle breath, a happy bounce on a clear |
| room0..6 | terrain (generated) | 6 x 6 to 8 x 7 cells, walls 0.3 / 0.55 tall, skirt 0.3 | 7 (one each) | slate, glow, planter, leaf, dusk, bloom, wood | this list + `models/env/make_env.py` | 300 to 700 each | static (baked) |
| crate | prop | 0.76 x 0.76 x 0.78 (with sprouts) | 8 + 8 unlit twins | wood, dusk, leaf; twins straw, glow | this list | 118 | game bones `crateA0..3`, `crateB0..3`: slide with the push (squash along it, bulge across), drop in from 4 m when a bench opens (land squash, thud, dust); `glowA0..3`, `glowB0..3`: swapped in on a pad, with a pop |
| marker | effect | 0.55 x 0.52 x 0.05 arrowhead | 2 (white, pink) | mark, bloom (unlit, nocast) | this list | 20 | game bones `markW` (a step or a push: on the next tile or on the crate's lid), `markP` (blocked: small, against the keeper); shown at a press and while held |
| puff | effect | 0.9 ring of 8 motes | pool of 5 | straw (unlit, nocast, specks) | this list | 96 | game bones `puff0..4`: pushes, pad pops, landings, resets; stepped growth in four poses |
| bushes, flowers, pots | foliage / props (generated per room) | bushes r 0.26-0.34, flowers r 0.08, pots 0.4 x 0.26 | ~6 to 10 a bench | leaf, bloom, wood | this list (seeded) | 20 each | static |

Bones: keeper 1 + crates 8 + glow twins 8 + markers 2 + puffs 5 = **24 of 63**, all game bones (no baked
tracks). Two crate sets (A and B) alternate between benches so a solved bench keeps its glowing crates
while the camera glides away and the next bench's crates drop in. Splats: **58 172** in the scene blob
(1.8 MB), under the ~100k budget: the seven benches are static bake side by side (a 3 x 3 snake, 10 m
apart, 0 to 20 m in X and Z), faces turned away from the camera deleted.

The benches live in one place, `models/env/make_env.py` (the `ROOMS` list): from it come each bench's
hedra command file, the BFS pars and solutions, and the room table in `scene/game.as` (between its
`// <rooms>` markers) that the game plays. Walls with floor behind them (towards the camera's far side)
are low (0.3 m) so the camera sees over them; the others are 0.55 m.
