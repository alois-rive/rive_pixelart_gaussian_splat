# Assets: Sprout Jump (DawnBringer 32)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (213 x 133 visible HUD pixels);
orthographic side view, yaw 0, pitch 10, `orthoHeight` 5.44 m -> a texel of exactly 0.04 m (Pip is
25 art pixels tall; the view is 8.5 m wide). Every moving bone is put on the texel grid (x by 0.04 m,
y by 0.04 / cos 10). Splat spacing 0.07 m (1.75 texels) by default: Pip 0.05 (cream 0.035, leaves
0.03, eyes 0.03), small props 0.03-0.05, level faces 0.08-0.10, far canopy and backdrops 0.12-0.18
(painterly, 3-4.5 texels). Palette: DawnBringer 32 (`palette.json`, 32 colours, 19 ramps).

| Asset | Class | Size (m) | Instances (game bones) | Ramps | Concept | Tris | Splats | Motion |
|---|---|---|---|---|---|---|---|---|
| pip (body, sprout, foot x2) | hero / character | 0.68 x 0.6 x 1.0 | 4 bones: `pip`, `sprout`, `footR`, `footL` | radish (bulb), cream (lower bulb, root, legs), ink (eyes, boots), sprout (leaves, stem) | `pip/sheet.v2.png` | 268 | 954 | game: run cycle (feet by distance, 8 steps), lean, take-off stretch, landing squash, sprout on a damped spring, a stepped forward flip on the double jump, turn through the front, idle look at the camera, a blink while safe, a tumble when hurt, happy hops at the flag |
| level | terrain (static bake) | 186 x 21 x 4 | static (bone 0) | grass, soil, stone, clay, bark, leaf, gold, petal, olive | this list (`models/level/layout.py`) | 4357 | 67 336 | none: beds, pots, steps, a garden wall, crates, three sunflowers, 9 branches, 3 leaf pads and a crown, 6 trunks with limbs and canopy clumps, tulips, shrubs, stakes, the flag pole, bridge posts |
| seed | pickup | 0.17 x 0.1 x 0.28 | pool of 12 `seed0-11` for the 60 seeds (the ones near the camera) | gold | this list | 80 | 1 157 | game: stepped spin and bob; flies up and shrinks when taken |
| pop | effect | 0.6 x 0.6 | 2 `pop0-1` | gold (unlit, nocast) | this list | 48 | 390 | game: a 4-step sparkle on seeds and stomps |
| shellbug | critter | 0.5 x 0.7 x 0.42 | pool of 3 `bug0-2` for the 7 bugs | shell, ink, cream | this list | 270 | 1 627 | game: patrols a platform, a stepped waddle; squashed flat when stomped |
| moth | critter | 0.2 x 0.45 x 0.55 | pool of 2 `moth0-1` for the 2 moths | moth (wings two-sided), shell (eye spots) | this list | 216 | 736 | game: hovers (bob or sweep), wings flap as a stepped squash; tumbles down when stomped |
| spring (bell-bloom) | prop | 0.62 x 0.62 x 0.5 | 3 `spring0-2` | leaf (coiled stem), petal (cup), gold (heart) | this list | 204 | 1 571 | game: a damped squash and wobble on every bounce |
| raft (leaf) | moving platform | 1.85 x 0.9 x 0.14 | 6 `raft0-5` | leaf | this list | 82 | 2 854 | game: sweeps or rises along a sine (a pure function of the run's clock) |
| plank | crumbling bridge | 0.94 x 0.84 x 0.18 | 7 `plank0-6` | bark (board), straw (ropes) | this list | 36 | 4 257 | game: shakes for 0.45 s when stepped on, falls tumbling, pops back 3 s later |
| bloom | checkpoint | 0.5 x 0.1 x 0.5 | 4 `bloom0-3` | petal, gold, leaf | this list | 244 | 1 278 | game: a squashed bud until Pip passes, then bursts open with a stepped spin |
| pennant | goal | 0.95 x 0.6 | 1 `pennant` | petal (two-sided), gold | this list | 24 | 506 | game: hoisted up the pole on a win, flaps in steps |
| puff | effect | 0.34 x 0.3 | 3 `puff0-2` | cloud (nocast) | this list | 20 | 339 | game: dust on jumps and landings, spray on a splash |
| water | terrain (carried) | 19.2 x 2.8 front, 2.4 deep surface | 1 `water` | water (deep front, ripple texture), leaf (lily pads) | this list | 122 | 5 777 | game: carried with the camera in whole 4.8 m ripple tiles, so it reads still; hidden in the treetops |
| hills | backdrop | 24 m strip, 2.6 tall | 2 `hills0-1` | hill (nocast) | this list | 183 | 3 523 | game: parallax at 82 % of the camera in x, 45 % in y (they sink away as Pip climbs) |
| grove | backdrop | 24 m strip of crowns | 2 `grove0-1` | olive (nocast) | this list | 396 | 2 663 | game: parallax at 60 % in x, 30 % in y |
| cloud | backdrop | 2.8 x 1.2 | 3 `cloud0-2` | cloud (nocast) | this list | 48 | 938 | game: drift at 93 % of the camera, wrapping |

Bones: 55 game bones of 63 (no baked tracks). Splats: 95 906 (static level 67 336, everything that
moves 28 570). The blob is 3.0 MB (16 bytes a splat).

## Ramps (dark to light; the painted step in bold)

| Ramp | Steps | Used by |
|---|---|---|
| grass | 323c39, 4b692f, **6abe30**, 99e550 | bed tops (texture: tufts 99e550, dark flecks 4b692f) |
| leaf | 222034, 323c39, **37946e**, 6abe30, 99e550 | canopy clumps, stalks, leaf pads and rafts (painted 6abe30), lily pads |
| soil | 222034, 45283c, **663931**, 8f563b, d9a066 | bed fronts (texture: pebbles 8f563b, clods 45283c), pot soil, sunflower discs |
| bark | 45283c, 663931, **8f563b**, d9a066, eec39a | branches, trunks, crates (planks texture), planks, stakes and the pole (663931) |
| stone | 222034, 595652, 696a6a, **847e87**, 9badb7, cbdbfc | steps and the wall (bricks texture), coping 9badb7 |
| clay | 45283c, 663931, 8f563b, **df7126**, d9a066 | pots |
| water | 222034, 3f3f74, **306082**, 5b6ee1, 639bff, 5fcde4 | the water band (front 306082; surface 5b6ee1 with ripples 639bff, 5fcde4) |
| radish | 45283c, ac3232, **d95763**, eec39a | Pip's bulb (the accent: nothing else is this red-pink) |
| cream | 8f563b, d9a066, **eec39a**, ffffff | Pip's lower bulb, root and legs; bug eyes; HUD text |
| sprout | 37946e, 6abe30, **99e550**, fbf236 | Pip's leaves (stem 6abe30) |
| ink | 000000, **222034**, 45283c | eyes, boots (45283c), bug heads; HUD panels and shadows |
| shell | 222034, 3f3f74, **76428a**, d77bba | shellbugs (spots d77bba), moth eye spots |
| moth | 3f3f74, **847e87**, 9badb7, cbdbfc | moths (wings cbdbfc) |
| gold | 8a6f30, df7126, **fbf236**, ffffff | seeds (stripe 8a6f30), sparkles, sunflower petals, spring hearts, the pole knob |
| petal | 45283c, ac3232, **d95763**, d77bba, eec39a | spring cups, tulips, the pennant, checkpoint blooms (d77bba) |
| cloud | 9badb7, **cbdbfc**, ffffff | clouds, puffs |
| hill | 3f3f74, **306082**, 37946e, 8f974a | far hills (tops 37946e) |
| olive | 323c39, 524b24, **4b692f**, 8f974a | the grove, garden shrubs |
| straw | 8a6f30, **d9a066**, eec39a | the bridge's ropes |

Roles: sky_top 639bff, sky_bottom cbdbfc, fog 9badb7 (fog is off: Bayer fog over the flat far
layers read as a dotted grid), void 222034. The game lowers the horizon as Pip climbs (0.62 of the
screen in the garden, all sky_top in the crown).

## Layout (game metres: x right, y up, z towards the camera; Pip runs at z 0)

The level is data (`models/level/layout.py`): 17 solid blocks (beds, pots, steps, the wall, crates),
16 one-way platforms (3 sunflower heads, 9 branches, 3 leaf pads, the crown), 6 rafts, a 7-plank
bridge, 3 springs, 7 shellbugs, 2 moths, 5 checkpoints (the start included), 60 seeds and the flag at
x 177.5, y 16.2. `make_level.py` writes the static geometry from it and prints the tables pasted in
`scene/game.as` (between `LEVEL BEGIN` and `LEVEL END`). Sections: raised garden beds over a brook
(x -6 to 31, y 0 to 2.4), a raft to the garden wall (checkpoint 1), the crumbling bridge over the pond
(x 43-50), a sunflower bed and three sunflower heads over the pond (checkpoint 2), pots in the pond, a
raft, a stone step (checkpoint 3), crates and a spring up into the treetops (x 104), branches, a
rising raft, a moth (checkpoint 4 at x 127), a raft, a spring, leaf pads round a second moth, a raft,
the crown and the flag (x 172-180, y 16.2).

Bank fronts reach y -1.1, under the water band's surface (-0.9). Faces nobody sees are deleted
(backs, bottoms, the undersides of branches, the backs of canopy clumps and backdrops): `hedra
inspect check` reports their open edges and the cylinder caps as ngons, harmless for splats.
