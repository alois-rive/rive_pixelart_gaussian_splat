# Assets: Peg Drop (Pear36, 36 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; a look-at front view from a little
above (eye 1.75 m higher than the target, 20 m out), orthographic 9 m -> texel 0.066 m. Splat spacing
0.09 m (1.36 texels); small parts finer (pegs, dividers, lips 0.07; the gear teeth and the key 0.05-0.06).
Palette: Pear36 as nine ramps (brass, gold, wood, felt, steel, copper, plum, jewel, lamp) sharing their
darks; the lamps, the doubled-cup marker and the sparks are `unlit`.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| dropper | hero / player | 1.15 x 0.83 x 1.25 (x 1.3 in the scene) | 1 (`dropper`) | brass (body, gear, chute), copper (hopper), gold (coin), steel (key) | `dropper/sheet.v1.png` | 336 | game: slides along the rail after the pointer on a spring, leans into the slide, squashes as a coin leaves, rattles while it winds up |
| board | terrain | 8.9 x 0.8 x 8.9 | 1 | felt (panel), wood (posts, tray, cabinet), brass (39 pegs, rail, dividers, caps), copper / jewel (cup lips), plum (dark bulbs) | this list | 2644 | static |
| wall | backdrop | 15 x 10, 1.6 m behind | 1 | plum (striped paper), wood (wainscot, shelf, clock rim), jewel / felt / plum / gold (jars), steel (clock face), lamp (bulbs, unlit) | this list | 760 | static |
| gear_big / gear_small | prop | r 1.25 / r 0.7, 0.18 thick | 2 + 1 (`gearA`, `gearC`, `gearB`) | brass | this list | 352 / 252 | game: turn in ticks with the pendulum (escapement), meshing ways |
| pendulum | prop | arm 1.85, bob r 0.36 | 1 (`pendulum`) | brass, copper (hub), gold (boss) | this list | 112 | game: swings 36 degrees each way, 2.6 s a swing; its bob bats coins |
| coin | effect | r 0.22, 0.09 thick | 10 (`coin0-9`) | gold (face, darker rim) | this list | 44 | game: falls through the pegs (2D physics), flips at 12 fps, lands on its cup's pile, sinks at a new run |
| hand | prop | 0.1 x 0.54 | 1 (`hand`) | wood | this list | 12 | game: the clock ticks once a second |
| marker | effect | 0.34 x 0.36 diamond | 1 (`marker`) | lamp (unlit) | this list | 12 | game: hovers over the doubled cup, turns in 45 degree steps, pops on a doubled landing |
| spark | effect | 0.1 cube | 8 (`spark0-7`) | lamp (unlit) | this list | 12 | game: bursts from a cup on a landing and from hard peg hits |

Bones: 25 game bones of 63. Splats: 63 299 (`scene/splats.bin`).

Layout (glTF metres, Y up, the camera on +Z): the board's inner face 8 m wide (x -4..4), the felt at
z -0.2, the game's plane at z 0 (coins, bob, peg heads). Peg rows at y 5.5 .. 1.9 every 0.6 m, 0.95 m
apart, every other row offset; pegs in the pendulum's sweep are left out (`make_env.py` decides, the same
list is in `game.as`). The pendulum's pivot at (0, 4.15). Seven cups between brass dividers at x -2.85,
-1.75, -0.6, 0.6, 1.75, 2.85 (tops at y 0.85), worth 20, 50, 10, 100, 10, 50, 20. The dropper's chute
at y 6.2; coins start at y 6.0. The wall 1.6 m behind; gears 1.3 m behind on the left and right margins.
