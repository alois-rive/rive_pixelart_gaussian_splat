# Assets: Border War (Lospec500)

Art grid: 640 x 400 artboard, `pixelSize` 2 -> 320 x 200 art pixels (HUD pixels). Orthographic camera, yaw 0,
pitch 38, `orthoHeight` 12.12 m, target (0, 0, 0) (on the art grid: no snap slide): texel 12.12 / 202 = 0.060 m.
A unit 1 m tall stands about 14 art pixels; the Manor is about 52 x 45. Splat spacing: ground 0.11 (1.8 texels),
woods 0.095, buildings 0.065-0.075 (finer for trim), units 0.058, small loads and projectiles 0.035-0.05 (marked
`specks`: they are meant to read as a few art pixels).

The isometric read comes from the buildings, not the camera: the camera looks straight up the map (yaw 0, so
the ground is a screen-aligned board and the pathing grid lines up with the screen), and every building is
turned 35 degrees (human side) or -35 (orc side) so it shows a corner and two walls.

## The map (world metres; models/layout.py and scene/game.as hold the same numbers)

Playable x -9.3..9.3, z -7.0..7.2 (z grows towards the bottom of the screen). The river runs from the top left
to the bottom right through the middle (a polyline, point-symmetric about the origin) and can be crossed only
at its two sandy fords, (-4.4, -3.3) and (4.4, 3.3). Woods line its banks except at the fords. The Manor sits
bottom left at (-6.6, 4.6), the Warcamp top right at (6.6, -4.6); each side has a gold deposit (+-8.3, +-1.4)
and three pine groves (game bones) along its outer edge. Dirt paths join each hall to both fords and its gold.

## The list

| Asset | Class | Size (m) | Instances / bone | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| manor (human hall) | hero | 2.40 x 2.00 x 2.44 | 1, `manor` | stone, cream, wood, royal | `manor/sheet.v1.png` | 244 | game: rises in 5 steps while built (not in this game: it starts built), hit squash, collapse |
| yard (Drill Yard, human barracks) | building | 3.02 x 1.56 x 1.73 | 1, `yard` | stone, cream, wood, royal, steel, gold | this list | 238 | game: rises in steps inside a scaffold, pop when done, hit squash, collapse |
| watchtower (human) | building | 1.15 x 1.15 x 3.15 | 2, `htower0-1` | stone, wood, royal | this list | 232 | game: as above; shoots arrows |
| cottage (human supply) | building | 1.42 x 1.16 x 1.25 | 2, `cottage0-1` | cream, wood, stone | this list | 150 | game: as above |
| warcamp (orc hall) | building | 2.59 x 2.72 x 2.45 | 1, `warcamp` | wood, crimson, cream, stone | this list | 152 | game: as the Manor |
| pit (War Pit, orc barracks) | building | 2.16 x 2.68 x 2.68 | 1, `pit` | wood, crimson, cream | this list | 268 | game |
| lookout (orc tower) | building | 1.16 x 1.16 x 2.94 | 2, `lookout0-1` | wood, crimson, cream | this list | 182 | game; throws spears |
| tent (orc supply) | building | 1.26 x 1.26 x 1.49 | 2, `tent0-1` | crimson, wood, stone, cream | this list | 55 | game |
| yeoman (human worker) | character | 0.56 x 0.40 x 0.98 | 5, `yeoman0-4` | skin, cream, wood, royal, steel | this list | 134 | game: stepped trot (bob + rock), tool swings, carries a sack or logs, tips over and sinks |
| swordsman | character | 0.79 x 0.67 x 1.04 | 5, `sword0-4` | skin, royal, steel, gold, wood | this list | 154 | game: trot, lunge |
| archer | character | 0.64 x 0.42 x 0.98 | 4, `archer0-3` | skin, wood, royal, cream | this list | 158 | game: trot, draw-back |
| drudge (orc worker) | character | 0.70 x 0.42 x 0.86 | 5, `drudge0-4` | orcskin, wood, crimson, cream, steel | this list | 148 | game: as the yeoman |
| brute (orc melee) | character | 0.94 x 0.66 x 1.18 | 5, `brute0-4` | orcskin, crimson, cream, wood | this list | 138 | game |
| thrower (orc ranged) | character | 0.60 x 0.35 x 1.38 | 4, `thrower0-3` | orcskin, wood, crimson, cream, steel | this list | 146 | game |
| grove (harvestable pines) | foliage | 1.65 x 1.47 x 1.60 | 6, `grove0-5` | leaf, wood | this list | 138 | game: shrinks in four steps as it is cut, falls and is gone (stumps remain) |
| sack (carried gold) | prop | 0.31 x 0.28 x 0.43 | 3, `sack0-2` | cream, wood, gold | this list | 50 | game: rides on a worker's back |
| logs (carried wood) | prop | 0.30 x 0.54 x 0.25 | 3, `logs0-2` | wood | this list | 72 | game: on a worker's shoulder |
| arrow | effect | 0.12 x 0.64 | 4, `arrow0-3` | cream, steel, royal | this list | 28 | game: arcs to its target (archers and watchtowers) |
| spear | effect | 0.11 x 0.98 | 4, `spear0-3` | wood, steel, crimson | this list | 28 | game: (throwers and lookouts) |
| scaffold | prop | 2.08 x 2.08 x 1.70 | 3, `scaf0-2` | wood | this list | 168 | game: round a building site, scaled to its footprint |
| terrain | terrain | 19.6 x 17.0 heightfield (0.2 m cells) | static | grass, dirt, water | this list | 16 660 | none |
| woods | foliage, props | 24 round trees, 2 gold deposits, 18 stumps, ford stones, rocks | static | leaf (sway), wood, stone, gold, cream | this list | 2 400 | leaves sway |

Generated models: `models/make_models.py` (units, buildings, props, through `models/meshkit.py`, which writes
GLBs straight from palette-exact flat-shaded triangles), `models/env/make_env.py` (terrain, woods). The Manor is
built in hedra from its sheet (`models/manor/p1_blockout.txt`, `p2_form.txt`).

## Bones: 63 of 63

| Group | Bones |
|---|---|
| human buildings: manor, yard, htower0-1, cottage0-1 | 6 |
| orc buildings: warcamp, pit, lookout0-1, tent0-1 | 6 |
| human units: yeoman0-4, sword0-4, archer0-3 | 14 |
| orc units: drudge0-4, brute0-4, thrower0-3 | 14 |
| pine groves grove0-5 | 6 |
| carried loads sack0-2, logs0-2 (shared by both sides) | 6 |
| projectiles arrow0-3 (humans), spear0-3 (orcs) | 8 |
| scaffolds scaf0-2 (shared) | 3 |

Supply caps an army before the pools do: the hall gives 5, each finished cottage or tent 4 (13 at most), and
each side's pools hold 14 units. A worker whose load finds no free sack or log bundle carries it unseen; an
arrow or spear with no free bone lands at once. Selection rings, health bars, move markers, the building ghost,
hit sparks, dust and "+8" pickups are HUD pixels, not bones.

## Splats: 102 835 (scene/splats.bin)

Terrain 25 373, woods (trees, deposits, stumps, stones) 15 667, buildings 31 399 (the Manor 5 138; the pools'
copies count once each: two towers, two cottages, two lookouts, two tents), units 18 015 (five, five and four of
each side's three kinds), groves 6 153, loads, projectiles and scaffolds 6 228.
