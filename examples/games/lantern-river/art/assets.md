# Assets: lantern river (Midnight Ablaze, 7 colours)

Art grid: 640 x 400 artboard, `pixelSize` 4 -> 160 x 100 art pixels (chunky, for the night). Orthographic
camera, yaw 0, pitch 12 (almost level, so depth lifts far things into the sky), `orthoHeight` 8.4 m over
102 rendered rows: texel 0.082 m. Splat spacing 0.09 m (1.1 texels) for the world, 0.1-0.14 m for the water
and the hills, 0.04-0.07 m for windows, stars, reeds and the lanterns' frames. The camera target is
(0, 2.94675, 0): a whole number of art pixels along the view's up axis, so the HUD shares the scene's grid.
Shadows off (a night lit by the moon from the front left, key light 0.3 so the dark paper keeps its step).

With seven colours, every ramp is a slice of the one long ramp (palette.md, "Six to eight colours"):
night (all 7), water (the 4 darkest), earth (5), paper (steps 1-5), glow (the 3 brightest, `unlit` only).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| lantern | hero prop | 0.5 x 0.5 x 0.92, baked at 1.4x | 16 dark (`lantern0`..`15`) + 10 lit (`lit0`..`9`) | paper (dark), glow (lit, unlit) | `lantern/sheet.v1.png` | 102 | game-driven: a squash on launch, rising, drifting with the wind, a stepped sway; lit: a pop and a fast climb |
| shine | effect | 0.7 x 0.8 dashes | 10 (`shine0`..`9`) | glow (unlit) | this list | 36 | under each lit lantern on the water, shrinking as it climbs |
| water | terrain | 18 x 12 plane | 1 | water (72 x 48 ripple texture) | this list | 48 | |
| bank | terrain | 18 x 4.5 slab + slope | 1 | earth | this list | 96 | |
| hills | terrain | five mounds, 2.3-3 m radius | 1 | earth (step 1) | this list | 163 | |
| tree | foliage | 1.24 x 2.2, baked at 0.6-0.85x | 7 | earth (sway) | this list | 76 | wind sway |
| house | architecture | 1.6 x 1.2 x 1.7 | 3 | earth, glow (windows, unlit) | this list | 64 | |
| jetty | prop | 0.9 x 3 x 1.6 | 1 | earth, glow (lamp) | this list | 168 | |
| reeds | foliage | 0.8 x 0.6 x 1.1 | 10 | earth (sway) | this list | 50 | wind sway |
| moon | backdrop | r 0.6 crescent | 1 | glow (unlit), night | this list | 24 | |
| glint | effect | 7 dashes over 6 m | 1 | glow (unlit) | this list | 84 | |
| stars | backdrop | 46 cubes, 5-8 cm | 1 | glow (unlit, `specks`) | this list | 552 | |

Bones: 36 of 63, all game bones (16 dark lanterns, 10 lit, 10 shines). Blob: 68 000 splats (water 18 100,
lanterns 21 900 for all 26, bank 9 600, reeds 5 700).

Play area (`"bounds"`): x -8..8, y -0.5..6.5, z -8..8. Lanterns launch at x -5.2..5.2, z -1.6..2.8 on the water.
