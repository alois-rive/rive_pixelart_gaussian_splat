# Assets: Night Heist, two moonlit rooftops (Cyclope6)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare); orthographic,
yaw 0, pitch 42, `orthoHeight` 8 m -> texel 0.0588 m. Splat spacing 0.085 m (1.45 texels) for the
world, 0.06 to 0.07 m for small props and the lamps, 0.076 m for the cat (1.3 texels; its bench spacing
0.0565 m is the same at its scene scale 1.35), 0.05 m for sparkles and stars.

Palette: Cyclope6 (`palette.json`), six colours: plum `#411d31`, wine `#631b34`, slate `#32535f`,
teal `#0b8a8f`, sea `#0eaf9b`, mint `#30e1b9`. Eight ramps:

| Ramp | Steps (dark to light) | Used by |
|---|---|---|
| roof | plum, slate, teal, sea | roof tops (painted teal, slate seams), back-row tops |
| brick | plum, wine, slate | facades, parapets, chimneys; unlit: the far skyline (wine) and the alley floor (plum) |
| fur | plum, wine, slate | the cat (painted wine), the fish's eye |
| metal | plum, slate, teal, sea | caps (teal), props, the water tower, the lamps, the cat's muzzle and paws (slate) |
| glass | slate, teal, sea | dark windows, the skylight; unlit: the clouds (slate) |
| fish | slate, teal, sea, mint | the fish (painted mint, fins sea) |
| light | sea, mint | unlit: the searchlight pools, lenses, lit windows, the moon, the cat's eyes |
| spark | mint, mint | unlit specks: stars, sparkles (one colour, so the ink does not ring them) |

Roles: sky plum (flat, `horizon` 2), fog slate, void plum. Value plan: the roofs are the bright mid
value (teal), the cat the dark accent on them (wine, plum in shade), the lights and the fish the
brightest (mint). `art/palette_bench.json` is the same palette with the roof's teal as the sky, used
only by the lookdev bench (`lookdev/cat.bin`): on the plum sky the cat's shaded faces vanish.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| cat | hero / character | 0.45 x 1.09 x 1.0 (tail top), scene scale 1.35 | 1 (6 bones: body, tail, 4 legs) | fur, metal, light | `cat/sheet.v1.png` | 380 | game: follows the pointer at up to 3.7 m/s, turns to face its way, an 8-step walk cycle (legs in diagonal pairs), bob, a hop over the alley, a flinch when lit, a startled jump when caught; the tail sways (stepped) and stands up when seen |
| roofs | terrain / architecture | 13.8 x 6.4, top at y 0, facades to y -3.2 | 1 | roof (textures), brick, metal, light, glass | this list | 1100 | |
| backrow | architecture | five blocks 1 m deep, 0.45 to 1.5 m above the roofs | 1 | brick, roof, metal, light, glass | this list | 900 | |
| props | props (obstacles) | chimneys 0.8 x 0.55 x 0.95 and 0.7 x 0.5 x 0.8, skylight 1.4 x 1.1, AC boxes 0.9 x 0.7 x 0.52, vent pipes, water tower 1.5 x 1.5 x 2.75 | 1 | brick, metal, glass | this list | 700 | |
| sky | effect (unlit) | moon r 0.66, 46 stars, a far skyline | 1 | light, spark, brick | this list | 900 | |
| cloud | effect (unlit) | 2.6 x 1.0 | 2 (pool `cloud`) | glass | this list | 120 | game: drifts across the moon |
| lamp | prop | drum r 0.25 x 0.42 on a yoke | 3 (pool `lamp`) | metal, light | this list | 130 | game: aims at its pool; hangs its head while off |
| pool | effect (unlit) | disc r 1.0 x 0.05 | 3 (pool `pool`) | light | this list | 80 | game: sweeps a Lissajous path, follows the cat after seeing it, pops open in steps when its lamp wakes |
| fish | prop (pickup) | 0.6 x 0.2 x 0.36, scene scale 1.25 | 1 | fish, fur | this list | 70 | game: grows in (stepped), bobs and turns at 10 fps |
| spark | effect (unlit) | 0.14 cube | 8 (pool `spark`) | spark | this list | 12 | game: the grab burst, falling and shrinking in steps |

Bones (game bones, `"bone"` / `"copies"` in `scene.bake.json`): cloud 2 + pool 3 + lamp 3 + fish 1 +
spark 8 + cat 1 + tail 1 + leg 4 = 23 of 63. Splats: 43 995 in the scene blob.

Layout (glTF metres, Y up, +Z towards the camera): two flat roofs at y 0, x -6.9..-0.5 and 0.5..6.9,
z -2.2..3.2, the alley between them open down to a plum floor at y -3.2; the walkable area |x| <= 6.25,
z -1.95..2.72 (the cat hops the alley). The back row stands behind z -2.2; the lamps pivot at
(-2.8, 2.2), (2.4, 2.0), (5.4, 1.55), z -2.75. The obstacle footprints are printed by
`models/env/make_env.py` and copied into `scene/game.as` (`OBST`). The sky's things sit far back and
low (the orthographic camera shows a point at screen height 0.743 y - 0.669 (z + 1.2)).
