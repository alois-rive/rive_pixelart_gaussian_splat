# Assets: Marble Tilt, a wooden labyrinth on a table (WoodSpark)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare); `orthoHeight`
8.2 m -> texel 0.060 m. Splat spacing 0.09 m (1.5 texels) for the box and the floor, 0.11 m for the
table, 0.055 to 0.07 m for the marble, the rails, the holes and the props' small parts. Camera:
orthographic, yaw 0 (screen right is the board's +x, so the tilt follows the pointer naturally),
pitch 56, target (0, 0.9, 0.55); a lamp from the back left (sun yaw -38, pitch 52), per-splat dither,
ink 1, a flat sky (the table fills the frame).

Palette: WoodSpark (16 colours: creams, honey, orange, mauve, plum, three greens, two blues, slate,
grey, pale, red, wine, pink) in 8 ramps: wood (plum, mauve, orange, honey, cream), leaf (pine, green,
olive, cream), glass (slate, blue, sky, pale), steel (plum, slate, grey, pale), berry (plum, wine,
red, pink), pit (plum, plum, mauve), and the unlit flame and spark.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| labyrinth | hero | 9.8 x 7.1 x 1.7 (after the splat fit) | 1 (frame static; floor and 2 knobs: 3 bones) | wood, berry | `labyrinth/sheet.v2.png` | 1 944 | game: the floor tilts up to 5 degrees towards the pointer (stepped by half degrees), the knobs turn a quarter turn at full tilt |
| table | terrain | 24 x 18 plank top | 1 | wood (mauve boards, plum seams) | this list | 448 | |
| marble | character | r 0.26 | 1 + 3 spares in the dish (pool `life`) | glass (blue, a pale swirl band) | this list | 80 | game: rolls (its orientation integrated from its path), drops onto the start ring with two bounces and a squash, sinks into holes and the goal; spares hop out of the dish |
| wall (rail) | level piece | 2.0 x 0.26 x 0.45 | 10 (pool `wall`) | wood (mauve, orange top) | this list | 10 | game: placed per layout on the tilted floor, rise out of it and sink back (stepped) |
| hole | level piece | r 0.38 pit, steel rim r 0.43 | 10 (pool `hole`) | pit, steel | this list | 122 | game: placed per layout, open and close (stepped scale) |
| goal | level piece | r 0.45 olive rim, flag 1.6 tall | 1 | pit, leaf, steel, berry (two-sided flag) | this list | 154 | game: the flag waves (stepped yaw), bounces when the marble drops in |
| start | level piece | ring r 0.4 | 1 | glass | this list | 112 | |
| spark | effect | r 0.11 | 8 (pool `spark`) | spark (unlit, specks) | this list | 20 | game: confetti from the goal, a puff from a hole |
| dish | prop | 1.9 across, 0.4 tall | 1 | berry | this list | 54 | |
| plant | foliage | 2.4 x 2.4 x 2.7 | 1 | wood (pot), leaf (leaves, sway) | this list | 156 | wind sway |
| books | prop | 2.6 x 1.9 x 1.0 | 1 | wood (pages), berry, glass, leaf | this list | 68 | |
| cup | prop | 1.0 x 1.0 x 2.4 | 1 | steel, leaf, berry, glass | this list | 82 | |

Bones (game bones, `"bone"` / `"copies"` in `scene.bake.json`): floor 1 + knobs 2 + walls 10 + holes 10
+ goal 1 + start 1 + marble 1 + spares 3 + sparks 8 = 37 of 63. Splats: 68 556 in the scene blob.

Layout (glTF metres, Y up, +Z towards the camera): the table top at y 0; the box centred at the
origin, its floor's top at y 1.188 (the floor bone's pivot); the playable floor is u -4..4, v
-2.65..2.65 (board coordinates, `game.as`); the front knob's axle at (0, 0.994, 3.74), the right one's
at (5.09, 0.994, 0); the dish at (5.7, 0, 3.6), the plant at (-6.1, 0, -2.4), the books at (6.1, 0,
-2.6), the pencil cup at (-6.0, 0, 3.3). Play area (`"bounds"`): 15 x 3.4 x 11 m.
