# Assets: Tiny Quest, a turn-based RPG on a small island (MarshMellow32)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare). Orthographic, yaw 45,
pitch 30 (isometric). The map shows `orthoHeight` 6.4 m (texel 0.047 m: a 1 m tile is about 21 x 11 art pixels,
tappable); a fight eases in to 4.7 m (texel 0.035 m), the Warden's fight to 5.8 m. Splat spacing 0.085 m for the
world (1.8 texels on the map, 2.4 in a fight: painterly up close), 0.11 m for the sea shallows, 0.05 to 0.08 m for
props, 0.042 m for the hero, 0.03 to 0.045 m for the monsters and effects. Sun from the upper left of the screen
(yaw 10, pitch 52), `shadeSteps` 1, per-splat dither, ink 1, a flat sky in the deep sea's blue (`horizon` 2).

Palette: MarshMellow32 (32 muted colours) in 18 ramps: grass, leaf, sand, soil, water, red, gold, stone, wood,
purple, skin, cream, jelly (the Gloop), and the unlit ones mark (the walk marker, the pin, the guard ring),
magic (crystals, sparks, the Warden's eye), puff, foam, deep. The hero is the only blue-and-gold thing on the
olive island; the monsters each own a hue (pale blue jelly, purple bat, red capling, grey stone with a purple
crystal).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| hero (the adventurer) | hero | 0.79 x 0.72 x 0.95 | 1 bone | gold, red, skin, stone, water, wood | `hero/sheet.v1.png` | 402 | game: hops tile to tile (stepped 20 fps), squash on landing, a breath when idle, lunges, a magic hop, falls over at 0 HP |
| island | terrain | 13 x 10 tiles of 1 m (sand 0.18, ground 0.45, hill 0.85 / 1.25, shrine 1.65 m), walls, river at 0.12, shallows at 0 | 1 | sand, grass, soil, cream, stone, water, foam, wood, red, gold, purple, magic | this list (`MAP` in make_env.py) | 1902 | river and shallows sway |
| grove | foliage | the trees of one wood tile: 2-3 round trees or pines 0.85-1.1 m tall at its back corners | 10 (one per wood tile, `grove0`-`grove9`) | leaf, wood | this list | 100-200 each | game: squashes to a bush while it stands between the camera and the hero or a monster; sway |
| house | architecture | 0.72 x 0.62 x 0.72 (walls, gable roof, door, window, chimney) | 3 (in island) | cream, red, wood, stone | this list | | |
| inn stall, well, shrine arch, bridge, signpost, rocks, tufts, flowers | props | small | in island | wood, red, cream, purple, stone, water, magic, grass, gold | this list | | |
| slime ("Gloop") | character | 0.58 x 0.58 x 0.53 (baked x1.15) | 3 (pool `slime`) | jelly, stone, grass | this list | 78 | game: wobbles (stepped 8 fps), pops up, lunges with a leap, squashes when hit, flattens and puffs when beaten |
| bat ("Flitter") | character | 1.12 x 0.34 x 0.72 above the ground (baked x1.35) | 3 (pool `bat`) | purple, mark (eyes) | this list | 94 | game: hovers and bobs, wing beats by an x squash at 9 fps, swoops |
| mushroom ("Capling") | character | 0.64 x 0.64 x 0.49 (baked x1.2) | 3 (pool `shroom`) | red, cream, stone, wood | this list | 180 | game: waddles (a stepped roll), hops at the hero |
| Warden | character (boss) | 1.5 x 0.6 x 1.85 | 1 bone, on the shrine | stone, grass, magic | this list | 172 | game: breathes; in its fight lunges, trembles while gathering power, crumbles in three puffs |
| marker | effect | a 0.94 m square frame | 1 | mark (unlit) | this list | 48 | game: the walk target tile, the targeted monster's tile |
| pin | effect | a 0.26 x 0.3 diamond | 1 | mark (unlit) | this list | 12 | game: bobs and spins over the walk target |
| puff | effect | 0.6 m cluster | 3 | puff (unlit) | this list | 100 | game: monsters popping up and beaten |
| spark | effect | 0.4 m six-spike star | 6 | magic (unlit) | this list | 44 | game: MAGIC bursts, the level up, the Warden gathering power |
| coin | effect | 0.22 m octagon | 4 | gold | this list | 32 | game: flies from a beaten monster to the hero |
| potion | effect | 0.24 x 0.34 bottle | 1 | purple, cream, wood | this list | 68 | game: over the hero's head when drinking or buying |
| slash | effect | a 0.76 m crescent | 1 | puff (unlit) | this list | 18 | game: the sword's arc on a hit |
| guard | effect | a 0.8 m octagonal ring | 1 | mark (unlit) | this list | 16 | game: in front of the hero while DEFEND holds |
| dust | effect | 0.25 m puff | 2 | cream | this list | 60 | game: behind each hop |

Bones (game bones, `"bone"` / `"copies"` in `scene.bake.json`): groves 10 + hero 1 + Warden 1 + monsters 9 +
marker 1 + pin 1 + puffs 3 + sparks 6 + coins 4 + potion 1 + slash 1 + guard 1 + dust 2 = 41 of 63.
Splats: 45 374 in the scene blob (island 26 400, groves 4 100, hero 2 600, Warden 2 200, the monster pools 6 400, effects 3 600).

Layout (glTF metres, Y up): tile (i, j) is centred at (i - 6, j - 4.5); the camera looks from +x +z, so +x runs
right-down the screen and +z left-down. The village (start (9, 7), the inn (10, 6)) is near the camera, the river
runs down column 6 with the bridge at (6, 4), the hill rises at the back left with the shrine at (3, 2). Play
area (`"bounds"`): 15.2 x 4 x 12.4 m.
