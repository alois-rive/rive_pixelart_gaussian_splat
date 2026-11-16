# Game: Tiny Quest (MarshMellow32)

**How to play:** click or tap a tile to walk the island; fight what jumps out of the grass with the big
buttons, grow strong, rest at the inn, then beat the Warden at the shrine on the hill.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [MarshMellow32](https://lospec.com/palette-list/marshmellow32), 32 muted
colours in 18 ramps (grass, leaf, sand, soil, water, red, gold, stone, wood, purple, skin, cream, jelly and the
unlit mark, magic, puff, foam, deep); it loaded from Lospec, so the spare (`rosy-42`) was not needed. A small
island in a deep blue sea, seen at an isometric angle: sandy beaches with foam, olive meadows with tufts and
flowers, teal groves, a river with a wooden bridge, a red-roofed village with an inn's market stall and a well,
and a hill in three tiers with a stone arch on top, where the Warden waits. The hero is a stubby adventurer in a
wide straw hat, a blue tunic and a red cape, with a short sword and a round buckler. Orthographic camera, yaw 45,
pitch 30, `orthoHeight` 6.4 m on the map (texel 0.047 m), easing in to 4.7 m in a fight (5.8 m for the
Warden); `pixelSize` 3, a sun from the upper left (yaw 10, pitch 52), `shadeSteps` 1, per-splat dither, ink 1,
a flat sky in the sea's blue.

## Rules

- **The map.** Click or tap a tile: the hero hops there tile by tile along the shortest grid path (BFS over
  walkable tiles, at most one tier up or down a hop), a gold frame and a spinning pin on the target. Water,
  houses and the shrine block the way; a tap on the shrine walks to its doorstep, a tap a little off the
  island's edge takes the nearest walkable tile.
- **Encounters.** Each hop onto wild ground (meadow, wood, the hill) may wake monsters: the chance is 0 for
  the first two wild hops after a fight, then 7 %, 14 %, 21 % ... up to 45 %. Sand, road, bridge and village
  are safe. Near the village 1 or 2 monsters, across the river 2 or 3, on the hill 2 or 3 of the tougher kinds.
- **Fights, in the same world.** A "!" over the hero, a sting, and the monsters pop up in a column to the
  hero's right on screen (or left, when the right is sea), while the camera eases in. Pick a monster (it
  gets the gold frame and its name), then a button:
  ATTACK (one foe: ATK -1 to +2, 10 % critical x1.6; the Flitter dodges 20 %),
  MAGIC (4 MP: hits every monster for 4 + 2 x level + 0..2),
  DEFEND (the next blows are halved) and
  POTION (+22 HP). Then each monster takes its turn: a lunge, a hit, a blink and the number floating up.
  Beaten monsters flatten, puff and throw their coins to the hero. Win: XP and gold; a level up raises
  HP +9, MP +3, ATK +2 and refills both (XP to level 2: 12, 3: 32, 4: 60).
- **The monsters.** Gloop (a pale jelly with a sprout: 10 HP, hits 1-3, 4 XP, 3 G), Flitter (a purple bat:
  7 HP, hits 1-4, dodges, 5 XP, 4 G), Capling (a red-capped mushroom: 15 HP, hits 2-5, 8 XP, 6 G), all missing
  10 % of the time. The Warden (a mossy stone sentinel with a crystal eye: 80 HP) strikes for 6-8 twice, then
  gathers power (sparks circle it, "DEFEND!") and slams for 15-18 (the view shakes), and again.
- **The village.** Standing on the inn's tile rests the hero (HP and MP full) and shows BUY POTION (8 G).
  The potion box at the top right drinks one on the map.
- **The run.** Reach a tile beside the shrine: the hero hops back to give the Warden room, and the boss fight
  starts. Beat it: VICTORY with the level, gold, steps and a score (500 + 100 x level + 5 x gold - 2 x steps,
  at least 100) and the session's best. HP 0 anywhere: GAME OVER with the same lines. The next click or tap
  starts a new run on the same island (the Warden back on its shrine). A run takes 3 to 5 fights and one or two
  levels: about one to two minutes; level 3 with a potion beats the Warden almost always, level 2 rarely.

**Touch.** Everything is a press: a tap on a tile walks (the walk starts when the finger lifts; while it is down
and dragging, the outline follows it, so a fingertip that lands a little off can slide onto the tile it meant),
a tap on a monster targets it, a tap on a button acts; nothing needs a hover (a mouse also shows the tile under
it, as a convenience). Tap targets at `pixelSize` 3: a map tile is about 21 x 11 art pixels (at the gallery's
0.55 scale about 35 x 18 screen points), the fight buttons 51 x 19, the map's potion box 42 x 16, BUY POTION
94 x 19; a monster takes taps within 16 art pixels of its middle. Tested with touch events alone (`touch
down@`, `drag@`, `up@`): a run won and a rushed run lost.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the hero is hopping out of the village within the
first frames; the first "!" comes at 2.1 s and the first fight is won by 7.8 s. The demo grinds the east
meadows at level 1 and the west lowlands at level 2, walking to wild tiles 2 to 5 hops away with detours and
pauses; it fights sensibly (the weakest monster first, sometimes another; MAGIC on two or more; DEFEND when the
Warden gathers power, most of the time; a potion when low, most of the time). Most runs climb at level 3 after
buying a second potion at the inn and win; about a third are impatient (level 2, one potion) and usually lose.
Runs last 55 to 125 s; it restarts 2 s after GAME OVER (3.5 s after VICTORY). When demo is switched off, a fresh
run waits for the first click with the hint.

**Sound** (procedural, `api.sound` / `api.note`; silent in demo): soft ticks on every other hop (higher on sand,
lower on the bridge) and a thud when a hop changes tier; a blip for a walk order, a dull click for a tile out of
reach; the encounter sting (a quick rising diminished arpeggio and a zap); a deep bell and a slow falling line
for the Warden; pops as monsters appear; button blips (a dull click for a greyed one); a whoosh on the lunge and
a crunch on the hit (higher for a critical), a high whoosh for a miss; MAGIC rings two bells, then a zap; DEFEND
a latch and a note; a potion's pop and three rising notes; a hurt hero's crunch and thud (and a clink while
guarding); the Warden's rising power-up, then an explosion for the slam; a pop for each beaten monster, a coin
for each coin that reaches the hero; a little fanfare for a won fight, a bell arpeggio and a power-up for a
level up; three bells at the inn, a coin for a potion bought; the victory fanfare; GAME OVER's falling sting.
Nothing is decided by `api.rand()`.

## What is where

```
art/palette.json, palette.png   MarshMellow32 with 18 ramps and roles (the sky is the deep sea)
art/assets.md                   the asset list, bones, layout
art/hero/                       the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/hero/                    spec + gate record, make_hero.py -> p1_blockout.txt, p2_form.txt, hero.glb,
                                hero.bake.json, gate shots (p2, p4_albedo, final, final_scene)
models/env/                     make_env.py (+ meshkit.py, a small GLB writer) writes island.glb (from MAP, the same
                                grid as game.as), grove0-9.glb, slime, bat, shroom, warden and the effects' GLBs
lookdev/                        the turntable bench (no RML): hero.bin
scene.bake.json                 the composition: the island (static), game bones (grove0-9, hero, warden, slime0-2,
                                bat0-2, shroom0-2, marker, pin, puff0-2, spark0-5, coin0-3, potion, slash, guard,
                                dust0-1), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light, sky), game.as (the whole game), renderer
goldens/                        hero (framed), hero@scene (at the map's texel), scene (demo_250: the first fight,
                                demo_1496: MAGIC on a Flitter and a Gloop, demo_2440: the Warden gathering power,
                                frame_030: the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the sources
```

Game bones: 41 of 63. Splats: 45 374 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the hero (p1, p2), lookdev/hero.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/hero/hero.rmdl -o /tmp/tq_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/hero/refs --shots /tmp/tq_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob hero -o /tmp/tq_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/hero/refs --shots /tmp/tq_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=10 --arg sunPitch=52 --arg keyLight=0.42 --arg highlight=0.85 --arg shadeSteps=1 --arg edgeDepth=0.35)
python3 $K/scripts/golden.py views --rive lookdev --blob hero -o /tmp/tq_h --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/tq_h --goldens goldens/hero
python3 $K/scripts/golden.py views --rive lookdev --blob hero -o /tmp/tq_hs --texel 0.047 --size 100 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/tq_hs --goldens goldens/hero@scene
for n in 250 1496 2440; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Play it headless. At the start the camera is centred on the hero at the plaza; tile (i, j) shows at about
(320 + 45 (di - dj), 217 + 22.6 (di + dj) - 55 dy) on the 640 x 400 artboard, di and dj counted from the hero's
tile and dy the height difference (0 on the same tier). The meadow left of the plaza is at (275, 194), the inn
at (410, 217):

```sh
rive scene --screenshot=$PWD/p.png --advance=12 --pointer=click@275,194 --advance=60          # one hop west: a Flitter jumps out
rive scene --screenshot=$PWD/p.png --advance=12 --touch=down@410,217 --touch=up@410,217 --advance=50   # the inn, by touch
```

A whole run needs the camera to follow, so it is easiest with a closed-loop player over `--commands`
(`advance`, `touch down@x,y`, `touch up@x,y`, `screenshot`): read the state, tap a tile, a monster, a button. The
demo-to-player hand-over: `data demo=true`, `advance 400`, `data demo=false`, `advance 30` shows the hint over a
fresh run; a tap then walks.

## Notes from building it

- Forest trees hid the hero and the monsters from an isometric camera (a tree on the tile in front covers the
  lower half of a 0.95 m hero). Each wood tile's trees became one game bone, a "grove" (10 bones); a grove that
  stands between the camera and the hero (or a monster in a fight) squashes to a bush in stepped poses and grows
  back after.
- Monsters on the tiles right beside the hero stacked up along the camera's line of sight and overlapped the
  hero. They now stand in a screen column one diagonal away, (+1, -1), (+2, 0), (0, -2), kept 0.6 m apart on
  screen, with the adjacent tiles as fallbacks and the mirrored column when the right is sea.
- The Warden first fell at level 2 every time (64 HP); a small Python port of the fight set it to 80 HP, blows
  6-8 and a slam of 15-18: level 2 with one potion wins about 10 %, level 3 with one about 99 %.
- The Warden's overhead bar ran under the status panel; the boss has its own bar between the panels, the hero
  hops back a tile at the start so the two stand apart, and its camera frames the span from the hero's feet to
  the crystals.
- For touch, the map zoomed in from 8 to 6.4 m (a tile from 17 x 8.5 to 21 x 11 art pixels), the walk starts on
  release (aim while dragging) and off-island taps snap to the nearest walkable tile.
- The monsters face the hero turned partly towards the camera (the bat three quarters), or a bat seen side-on is
  a sliver.
- The Codex sheet was not reviewed by a person yet (`art/hero/sheet.v1.png.json`, `reviewed: false`).
