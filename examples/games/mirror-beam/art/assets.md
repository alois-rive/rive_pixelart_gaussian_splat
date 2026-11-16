# Assets: Mirror Beam, a desert temple court at sunset (Sunset Red, 5 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare); orthographic,
yaw 0, pitch 40, `orthoHeight` 8.6 m -> texel 0.0632 m. Splat spacing 0.1 m (1.6 texels) for the world,
0.075 for the court floor (its grout lines), 0.14 for the open sand, 0.05 to 0.07 for the pieces.

Palette: Sunset Red (`palette.json`), five colours of one hue, near-black navy A `#0d101b`, plum B
`#281a2d`, wine C `#6b2341`, crimson D `#af2747`, red E `#ee243d`. A monochrome palette: materials are
told apart by value, so each read has its own step. Ramps: sand and stone (A B C D), bronze (A to E),
glass (C D E), ember (A B C), glow (C D E E, unlit things; E repeats so tiny sparks are not inked into
rings and a painted C reaches E with `"step": 2`), night (A A B, the gate's dark). Light is Bayer
dither (`splatDither` false, `bandDither` 0.4) with `shadeSteps` 1.

| Read | Value |
|---|---|
| sky | C above, D at the horizon (Bayer split), the sun E |
| sand, temple, columns, palms | B, lit faces and tops C, shade and silhouettes A |
| court floor | C tiles in B grout by day; B as the sun sinks (the light falls under `keyLight`) |
| mirrors, lens, lit crystals, the beam | E (unlit), the mirrors' bronze D |
| dark crystals | D (glass ramp), shading to C |

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| mirror | hero | 0.95 x 0.83 x 1.32 (scene scale 1.3) | 10 (pool `mirror`) | glow (face, back: unlit), bronze, stone | `mirror/sheet.v1.png` | 182 | game: rises out of the floor turning (stepped, 8 fps), swings a quarter turn on a click with an overshoot and a wobble, sinks when the court is solved |
| court | architecture | 9.5 x 5.9 floor + border, columns 1.9 tall | 1 | stone | this list | ~700 | |
| temple | architecture | 5.4 x 3.3 x 3.0 (steps, two pylons, lintel, gate, hall) | 1 | stone, night | this list | ~150 | |
| emblem | prop | 2.25 x 0.14 x 0.84 (sun disc with wings) | 1 dark (static) + 1 lit (bone `emblem`) | stone / glow | this list | 70 | game: the lit copy flashes on over the dark one when a court is solved |
| desert | terrain | 18 x 12.4 sand grid (open under the court) + 4 low dunes | 1 | sand | this list | ~500 | |
| palm | foliage | 2.2 x 2.2 x 3.1 | 2 (yaw 160, 20; scale 1, 0.85) | stone, ember (sway, double) | this list | ~170 | sway |
| sun | effect | 1.9 wide disc of strips, tilted 40 to face the camera | 1 (bone `sun`) | glow (unlit, nocast) | this list | 84 | game: placed in the sky by `pickPlane` behind the horizon, sinks with the daylight |
| crystal | prop | 0.6 x 0.6 x 1.03 (scale 1.3) | 5 dark (pool `crystal`) + 5 lit (pool `glow`) | stone + glass / glow (unlit) | this list | ~130 | game: rises with the court; lit: swapped for the glowing copy with a pop, turns in 15 degree steps, bobs |
| stump | prop | 0.8 x 0.8 x 1.1 (scale 0.9) | 3 (pool `stump`) | stone | this list | ~80 | game: rises and sinks with the court; blocks the beam |
| lens | prop | 0.5 x 0.5 x 1.5 | 1 (bone `lens`) | stone, glow (unlit) | this list | ~40 | game: slides to the row the beam enters |
| ring | effect | 1.24 octagon ring, flat | 1 (bone `ring`) | glow (unlit, nocast) | this list | 64 | game: under the hovered (or the demo's next) mirror, pulsing |
| spark | effect | 0.18 | 12 (pool `spark`) | glow (unlit, nocast, specks) | this list | 20 | game: bursts on turns, lit crystals and solves; fall and shrink in steps |

Bones (game bones, `"bone"` / `"copies"` in `scene.bake.json`): sun 1 + emblem 1 + lens 1 + mirrors 10
+ crystals 5 + lit crystals 5 + stumps 3 + ring 1 + sparks 12 = 39 of 63. Splats: 60 541.

Layout (glTF metres, Y up, +Z towards the camera): the court is a 7 x 4 grid of 1.2 m tiles, floor top
at y 0, column centres x -3.6 .. 3.6, row centres z -1.8 (back) .. 1.8 (front) (the same numbers in
`make_env.py` and `game.as`); a 0.55 m border round it; colonnades of six columns at x ±4.95; the
temple's steps from z -2.95, its pylons at x ±2.0, the emblem on the lintel at (0, 2.3, -4.15); palms
at (-6.1, -3.6) and (6.2, -4.4); the lens at x -5.45 on the entry row; the beam at y 1.266 (the
mirrors' centre). The sand ends at z -6.9: its edge is the horizon the sun sets behind (the sun moves
on the plane z = -12.5). Play area (`"bounds"`): 14 x 4 x 12 m.
