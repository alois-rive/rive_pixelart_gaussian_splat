# Assets: Swarm Ward, a lamplighter's night on a haunted moor (Rosy 42)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (213 x 133 visible HUD pixels).
Orthographic, yaw 0, pitch 53.13 degrees (sin 0.8, cos 0.6), `orthoHeight` 6.8 m -> texel 0.05 m
exactly. The camera is locked on the hero, snapped to whole texels (x by 0.05 m, z by 0.0625 m =
texel / sin(pitch)), so the moor scrolls by whole screen pixels. The view shows 10.65 m of moor
across and 8.3 m deep. Splat spacing 0.075 m (1.5 texels); small creatures and effects 0.035 to
0.05 m; the ground 0.1 m (it is flat and uniform).

Palette: Rosy 42 (`palette.json`, 42 colours, loaded from Lospec; the spare `sheltzy32` was not
needed), 18 ramps. A cold night: the moor `#283540` under a low moon from the front left, the
lantern's pool round the hero (the moor's own lit steps `#2f5753` and `#3b7d4f`, stippled: the light
shows the heath's green), everything that glows unlit.

## The bone budget (63 at most; bone 0 is the static world, which this game leaves empty)

A horde game has to look crowded with few bones. Everything that moves or appears is a game bone,
so every bone is a slot that is recycled the moment it is free:

| Pool | Bones | What one bone carries | Why it is enough |
|---|---|---|---|
| hero `hero` | 1 | the lamplighter and his pole and lantern | |
| ground `ground` | 1 | a uniform 12 x 10 m moor plane whose texture holds the lantern's light pool (a stippled disc, two tones) | the camera is locked on the hero, so the plane and its pool ride with the camera and the pool stays under him; uniform, so it never seems to slide |
| decor `decor0-3` | 4 | a 12 x 12 m patch of moor: heather clumps, grass tufts, turf mounds, pebbles, and one landmark (standing stones, a cairn, a peat pool, a fairy ring) | the four patches leapfrog on a 2 x 2 grid of 12 m cells as the hero walks: the moor is endless and never re-sampled |
| moth swarms `moths0-11` | 12 | a PACK: five murk moths baked in a cluster, flapping (stepped squash), wobbling and bobbing as one | 12 slots show 60 moths |
| shamblers `shambler0-7` | 8 | one peat shambler | slow and tough: they stay on screen a long time |
| hounds `hound0-5` | 6 | one barrow hound | fast: they die or arrive quickly, so few slots turn over often |
| elites `brute0-1` | 2 | one cairn brute (big, tough, drops a lamp-oil flask) | one or two at a time |
| boss `boss` | 1 | the Mire King, at dawn | |
| ward motes `mote0-2` | 3 | one orbiting mote of lantern light | the weapon has 3 motes at most |
| pulse ring `ring` | 1 | the lamp pulse: a ring baked at its largest radius (3 m), scaled up from small as it spreads | |
| flint sparks `spark0-5` | 6 | one thrown spark | a spark lives 0.6 s: 6 cover 3 a volley twice |
| cinders `ember0-4` | 5 | one burning cinder of the trail | the oldest is reused |
| XP wisps `wisp0-9` | 10 | one dropped spark of light, baked at its largest size; small ones are scaled to 0.55 | when the pool is full, a new drop merges into the nearest wisp (which grows a size) instead of taking a bone |
| flask `flask` | 1 | a lamp-oil flask (heals) dropped by an elite | |
| **all** | **61** | | 2 spare |

What costs no bone at all: hit pops, death bursts, damage numbers, the storm-wick lightning (a
weapon), the hurt flash, the level-up cards, arrows to elites off screen: all drawn on the HUD,
on the art grid, in palette colours.

So the screen holds up to 60 moths, 8 shamblers, 6 hounds, 2 brutes and the boss: 77 creatures on
29 bones. Foe slots are refilled the instant one dies, from a ring just outside the view, and a foe
left more than 11 m behind is moved back in front of the hero (the swarm never thins by being
outrun).

## The list

| Asset | Class | Size (m) | Instances (game bones) | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| lamplighter | hero / character | 0.62 x 0.62 x 1.7 (figure 1.2, pole 1.7) | 1 `hero` | coat, skin, wood, glow, slate | `lamplighter/sheet.v1.png` | ~600 | game: walks to the pointer, 16 stepped headings, a stepped waddle and bob (8 fps), the lantern swings, a squash and a blink when hurt, a topple at 0 HP |
| ground | terrain | 12 x 10 plane, texture 120 x 100 (0.1 m texels) | 1 `ground` | moor: `#283540` the moor, the pool a Bayer stipple of `#2f5753` to 2.7 m and `#3b7d4f` to 1.6 m | this list | 2 | game: rides with the snapped camera |
| decor patch A-D | terrain / foliage | 12 x 12 each | 4 `decor0-3` | heather (`"step": -1`: a calmer moor), grass, moor, stone, slate, wood, coat, wisp | this list | ~1 500 each | game: leapfrogs on a 12 m grid of half-cell centres (a night starts where four patches meet) |
| murk moth swarm | creature (pack) | 1.0 x 1.0 x 0.45, five moths 0.34 across | 12 `moths0-11` | stone (wings, body), eye (unlit) | this list | ~150 | game: flies at the hero (2.3 m/s), weaves, wobbles and flaps (stepped squash, 10 fps), bobs at 0.5-0.9 m |
| peat shambler | creature | 0.9 x 0.8 x 1.15 | 8 `shambler0-7` | wood (peat body, twigs), grass (moss), eye | this list | ~180 | game: lurches (1.1 m/s), sways, stepped |
| barrow hound | creature | 0.36 x 0.95 x 0.62 | 6 `hound0-5` | hound (coat), stone (skull mask), eye | this list | ~150 | game: lopes (3.1 m/s) with a stepped gallop bob; a lunge |
| cairn brute | elite | 1.4 x 1.0 x 1.9 | 2 `brute0-1` | stone, grass (moss), wisp (runes, unlit) | this list | ~260 | game: stomps (1.3 m/s), rocks from foot to foot |
| the Mire King | boss | 2.8 x 1.5 x 3.5 | 1 `boss` | wood (peat body), grass (moss), stone (antler crown), eye | this list | ~500 | game: rises at dawn, strides (1.5 m/s), a ground slam every few seconds |
| ward mote | effect (weapon) | 0.22 octahedron | 3 `mote0-2` | glow (unlit) | this list | 8 | game: orbits the hero |
| pulse ring | effect (weapon) | ring r 3.0, tube 0.08 | 1 `ring` | glow (unlit) | this list | ~250 | game: spreads from the hero (scaled 0.1 to 1) |
| flint spark | effect (weapon) | 0.1 x 0.36 x 0.1 | 6 `spark0-5` | ember (unlit) | this list | 8 | game: flies at the nearest foe |
| cinder | effect (weapon) | 0.36 x 0.36 x 0.3 | 5 `ember0-4` | ember (unlit), coat | this list | ~40 | game: flickers (stepped squash), dies down |
| XP wisp | pickup | 0.32 octahedron | 10 `wisp0-9` | wisp (unlit) | this list | 8 | game: spins and bobs, drifts to the hero inside the pickup radius |
| lamp-oil flask | pickup | 0.26 x 0.26 x 0.36 | 1 `flask` | slate, glow (unlit oil), wood | this list | ~60 | game: bobs; heals 30 |

Splats: 62 821 in the scene blob (the four decor patches 23 300, the ground 10 100, the 29 foe
slots 23 300 (a moth swarm 400, a shambler 650, a hound 1 230, a brute 1 480, the king 2 870), the
hero 2 280, weapons and pickups 3 850). Every bake warning is cleared except where tiny is the point: eyes, runes and the
dark rims of the small heather clumps are marked `"specks": true`.

## Ramps

| Ramp | Steps (dark to light) | Painted on | Used by |
|---|---|---|---|
| moor | `#1b1f21 #283540 #2f5753 #3b7d4f` | `#283540` (1) | the ground and the lantern's pool in its texture; turf mounds on `#2f5753`. At dawn the sun climbs past `highlight` and the whole moor dithers a step up |
| grass | `#1b1f21 #2f5753 #3b7d4f #63ab3f #c8d45d` | `#3b7d4f` (2) | grass tufts, shamblers, moss |
| heather | `#291d2b #4b1d52 #692464 #9c2a70 #cc2f7b` | `#692464` (2), shown on `#4b1d52` (`"step": -1`) | heather clumps (blooms `#9c2a70`, shown `#692464`) |
| stone | `#14182e #2c354d #404973 #686f99 #a3a7c2 #dfe0e8` | `#686f99` / `#a3a7c2` / `#dfe0e8` | stones, the cairn brute, moth wings, the hound's skull mask, the Mire King's antlers, mushroom stems |
| slate | `#2b2b45 #3a3f5e #4c6885 #4fa4b8 #92e8c0 #f5ffe8` | `#4fa4b8` (3) | the scarf, the peat pool, the flask's glass |
| coat | `#21181b #3b2027 #7d3833 #ab5130 #cf752b #f0b541` | `#cf752b` (4) | the coat; hat, gloves, boots, lantern frame on `#3b2027` |
| skin | `#3d2936 #52333f #8f4d57 #bd6a62 #ffae70 #ffc2a1` | `#ffc2a1` (5) | the face |
| wood | `#3d2936 #52333f #8f4d57 #bd6a62` | `#8f4d57` (2), `#52333f` (1) | the pole, the hat (`#52333f`), peat (shamblers, the Mire King), twigs, bark, ward posts |
| hound | `#291d2b #4b1d52 #692464 #9c2a70` | `#692464` (2) | barrow hounds |
| blood | `#291d2b #4f1d4c #781d4f #ad2f45 #e64539 #ff8933` | | (HUD) |
| glow | `#cf752b #f0b541 #ffee83` | `#ffee83` (2), unlit | the lantern glass, motes, the pulse ring, the flask's oil |
| ember | `#ad2f45 #e64539 #ff8933 #ffae70` | `#ff8933` / `#e64539`, unlit | flint sparks, cinders |
| wisp | `#4fa4b8 #92e8c0 #f5ffe8` | `#92e8c0` (1), unlit | XP wisps, the fairy ring, the brute's runes |
| eye | `#cc2f7b #ff5277 #ffc2a1` | `#ff5277` (1), unlit | every monster's eyes |
| pool, pool2, mote, spark | one colour each | | spare one-step ramps for specks (ink cannot ring them) |

Layout (glTF metres, Y up, +Z towards the camera): the moor's top at y 0. Everything is a game
bone placed by `scene/game.as` at its logical position minus a wrapping origin (jumps of 6 m = 120
texels in x and 96 in z), so the placed world stays inside the bake's `"bounds"` (x, z within
+-15 m) however far the hero walks.
