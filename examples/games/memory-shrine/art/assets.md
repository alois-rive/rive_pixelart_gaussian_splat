# Assets: Memory Shrine, a bell gate on a mountain top at night (Citrink)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare); `orthoHeight`
8.6 m -> texel 0.063 m. Splat spacing 0.1 m (1.6 texels) for the world, 0.075 m for the bells, 0.06 to
0.08 m for small parts, 0.13 to 0.16 m for the cliff, the peaks' rock and the clouds. Camera:
orthographic, yaw -6, pitch 11, target (0, 3.9, 0); moon light from the front right (sun yaw 32,
pitch 34), per-splat dither, ink 1, a flat night sky.

Palette: Citrink (8 colours: white, yellow, lime, green, teal, steel blue, navy, ink) in 13 ramps:
stone (ink, navy, steel, teal), moss (navy, teal, green, lime), copper (ink, teal, green, lime),
snow and moon (navy, steel, white), gold (navy, teal, lime, yellow, white), limeb (navy, teal, lime,
yellow), teal (ink, navy, teal, green, lime), and the unlit ones glow (yellow, white), lime (lime,
yellow), white (white x2), spark (yellow x2). The four bells are told apart by ramp: green, lime,
gold and white.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| bell | hero | 1.25 x 1.26 x 1.78 (scales 1.35, 1.2, 1.08, 0.96) | 4 lit + 4 glow (8 bones) | copper, limeb, gold, moon, teal; glow copies copper, lime, white, spark (unlit) | `bell/sheet.v1.png` | 250 | game: a damped swing about the hang point (stepped 15 fps), a slow stir in the wind, glows while it rings, a dull clank (fast, short shake) for a wrong bell |
| terrace | terrain | 17 x 7 (+ steps, cliff cone 19 m across) | 1 | stone (paving, path, cliff), moss | this list | 722 | |
| torii | architecture | 14.6 x 0.8 x 6.6 | 1 | teal (lacquer), stone (cap, feet), moss (bell cords) | this list | 188 | |
| lantern | prop | 1.7 x 1.7 x 2.55 | 2 | stone, glow (unlit fire box) | this list | 136 | |
| pine | foliage | 3.6 x 2 x 4 (scale 1.1) | 1 | stone (bark), copper (needles, sway) | this list | 136 | wind sway |
| peaks | terrain | seven cones 2-4.4 tall, 9-15 m behind | 1 | stone, snow | this list | 123 | |
| moon | effect | disc r 2.6 (scale 0.36) | 1 | white, glow (unlit) | this list | 336 | |
| clouds | effect | puffs in two rings 18-24 m across | 1 | moon | this list | 286 | |
| stars | effect | 46 cubes 0.12-0.18 | 1 | white (unlit, specks) | this list | 552 | |
| ripple | effect | torus r 1.6 (largest size) | 4 (pool `ripple`) | white (unlit, nocast) | this list | 160 | game: grows from a ringing bell (stepped), gone after 0.5 s |
| note | effect | octahedron r 0.18 | 10 (pool `note`) | spark (unlit, specks) | this list | 20 | game: rises and wobbles from a ringing bell, spins, shrinks |

Bones (game bones, `"bone"` / `"copies"` in `scene.bake.json`): bells 4 + glows 4 + ripples 4 +
notes 10 = 22 of 63. Splats: 97 696 in the scene blob (clouds 27 000, terrace 28 000).

Layout (glTF metres, Y up, +Z towards the camera): the terrace top at y 0 (x -8.5..8.5, z -3.5..3.5),
the torii in the plane z -1 with its tie beam's underside at y 4.75; the bells hang at x -3.6, -1.2,
1.2, 3.5 from y 4.45 (the same numbers in `make_env.py` and `game.as`); lanterns at x +-6.2, z 1.7;
the pine at (7.3, 0, -2.6); peaks 9 to 15 m behind; the moon at (4.9, 3.75, -15). Play area
(`"bounds"`): 20 x 11.5 x 21 m.
