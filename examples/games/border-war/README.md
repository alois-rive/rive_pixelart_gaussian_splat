# Game: Border War (Lospec500)

**How to play:** tap a unit (or drag a box round several) to select, tap the ground to move, a pine grove or
the gold to gather, an enemy to attack; the buttons at the bottom build and train. Grow your village, raise
an army and destroy the orc Warcamp across the river before the warband burns your Manor.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra 0.1.0,
codex-cli. Palette: [Lospec500](https://lospec.com/palette-list/lospec500), 42 colours, loaded from Lospec (the
spare `zughy-32` was not needed), as 16 hand-written ramps (grass, leaf, dirt, wood, stone, cream, royal,
crimson, orcskin, skin, steel, gold, water, glow, plum, rose). A small border country seen from a fixed
orthographic camera (yaw 0, pitch 38, 12.12 m tall, `pixelSize` 2: 320 x 200 art pixels, texel 0.06 m), the
buildings turned 35 degrees so they show a corner (the isometric read on a screen-aligned board), sun from
the front left (yaw -40, pitch 50), per-splat dither, ink 1, `shadeSteps` 1, a flat sky (never seen).

It is an original design: the factions, units, buildings, names and look are this sample's own.

## The rules

- **One map, one match.** Your Manor (bottom left) and the orc Warcamp (top right) face each other across a
  river that can be crossed only at its two sandy fords; woods line its banks. Each side has a gold deposit
  and three pine groves. Destroy the Warcamp: VICTORY. Lose the Manor: DEFEAT. The result shows the time,
  enemies killed, your losses, what you gathered, the score and the session's best; the next tap starts a new
  match on the same map.
- **Economy.** Workers walk to the gold or a grove, work it (a swing, a clink or a chop), and carry the load
  home on their back (a sack of gold) or shoulder (a bundle of logs): 8 a trip, counted at the top of the
  screen. Groves hold 260 wood each and shrink in four steps as they are cut, then fall (their stumps stay).
- **Supply.** The hall gives 5, each finished cottage (tent) 4 more; two at most: 13. Training waits for room.
- **Building.** The Manor's or a yeoman's panel has YARD, TOWER and COTTAGE (enabled when affordable): tap
  one, then tap (or drag your finger to) a spot near your village; the ghost shows green where it fits. The
  nearest yeoman (a selected one first) walks over and builds it: it rises out of the ground in five steps
  inside a wooden scaffold and pops when done. Tap an unfinished building with yeomen selected to help.
- **Army.** The Manor trains yeomen; the Drill Yard swordsmen and archers. Every unit has health (bars show
  when hurt or selected), a reach, a speed; units part round each other, path round the river, woods and
  buildings (a 0.4 m grid, A* on demand, a few searches a frame), and fight back when struck. Soldiers on
  guard engage what comes near and give up a long chase. ATTACK then a tap is an attack-move: fight through
  whatever is met, then go on. ARMY selects every soldier.
- **Score:** 25 a kill, a quarter of all you gathered, and on a win 1000 + 3 for each second under ten minutes.

| | The kingdom (you) | The warband (computer) |
|---|---|---|
| Hall (800 hp) | **Manor**: stone plinth, framed walls, blue roof, a tower with a banner | **Warcamp**: a log ring under a striped red hide cone, a doorway between two great tusks, a war banner |
| Barracks 120 g 80 w | **Drill Yard**: a long hall with crossed swords, a straw dummy and a spear rack | **War Pit**: a staked log palisade, a war drum, a skull banner |
| Tower 90 g 60 w (300 hp, 7 dmg, reach 4.4) | **Watchtower**: round stone, battlements, a blue cone, shoots arrows | **Lookout**: a log stilt platform under a red hide roof, throws spears |
| Supply 50 g 40 w | **Cottage**: thatched, a chimney, a woodpile | **Tent**: a red and maroon hide cone with poles |
| Worker 50 g | **Yeoman**: straw hat, hatchet | **Drudge**: hunched, tusked, a stone maul |
| Melee 70 g | **Swordsman** (65 hp, 8 dmg): blue tabard, helmet, round shield | **Brute** (75 hp, 9 dmg): big, a red pauldron, a club |
| Ranged 55 g 25 w | **Archer** (38 hp, 6 dmg, reach 3.4): blue hood and cape, a bow | **Thrower** (40 hp, 7 dmg, reach 3.1): a red bandana, a tall spear |

**The computer** thinks twice a second: workers to five (two on wood, more when wood runs short), a tent
when supply runs out, the War Pit as soon as four drudges work (saving for it), then a steady stream of
brutes and throwers (two to one), a lookout as soon as the pit stands (in the demo once it has three
soldiers), a second after 4:20.
Its army gathers at a rally point before its fords and defends its village (leashed to it, so it does not
chase across the map). It attacks in waves that grow (3, 4, 5, 6): a wave picks a ford, regroups there,
then marches on the Manor, fighting what it meets and turning on the nearest building when it arrives; it
also attacks early when it clearly outnumbers you, and with everything once its army is full. A horn
sounds and "THE WARBAND MARCHES!" when a wave sets out. Workers take up arms when raiders reach their hall and
few soldiers are home. Its one concession: against a player it keeps four drudges for its first 80 seconds.
Late in a long match (after nine minutes) its waves march past everything to the Manor. Any wave that reaches
a hall lays siege to it; soldiers hit buildings half again as hard, and a hall more than twice as hard.

Played by `tools/bot.py` (closed loop through `--commands`, presses only): a decent player that builds its
economy, two cottages, the yard, a tower, defends and counter-attacks when it has the upper hand wins in 2:40
acting at once, 3:20 at one action every two seconds (pointer and touch alike); a player that waits for a full
army of nine and never counter-attacks is held off (no result in ten minutes); an idle player loses its Manor
at 2:13. A person, slower and less exact than the script, should take four to six minutes.

**Demo** (`--arg demo=true`, or the `Sample` view model's `demo`): the kingdom is played by the same brain as
the warband (with its own timing), so it is a real match: both economies, buildings rising, armies clashing;
either side can win. It opens with both sides' workers already at work (one carrying gold home) and a
skirmish at the west ford (two swordsmen and an archer against two brutes and a thrower) that starts in the
first seconds; the survivors walk back to their rally points. It restarts two seconds after the result. When
demo is switched off a fresh match starts for the player.

**Touch.** Everything is a press, a drag or a release: a tap selects or commands, a drag draws the selection
box, a tap on a button builds or trains. Placing a building needs no hover: after the button, the ghost
appears where the finger presses and follows it while it drags; the building goes where the finger lifts (a
mouse can also hover to see the ghost first). Buttons are 38 x 24 art pixels (76 x 48 screen points), units
answer a tap within 7 art pixels of their feet.

**Sound** (`sfx.as`, silent in demo mode): selecting a unit plays its acknowledgement (a yeoman's two plucked
notes, a swordsman's steel click and a low call, an archer's high pluck), a command the same a little lower
with a blip (two falling notes for an attack); a building selects with a latch click. Your workers' chops and
pick clinks (one every fifth of a second at most), a coin as gold is delivered and a soft thud for wood,
construction knocks (alternating, rate-limited), a thud and a two-bell chime when a building is finished,
the unit's acknowledgement when it is trained; arrows twang and spears whoosh (rate-limited), melee hits
crunch; a falling note when a soldier of yours dies, a grunt for an orc; a building collapses with a low burst
and a thud; a grove falls with a whoosh and a thud. The warband's waves set out to a low three-note horn,
an attack on your village sounds a low zap and two falling notes, a win a fanfare and rising notes, a loss
the losing arpeggio and two low bells. Errors (not enough gold, can't build there) are a low tick. No sound
is ever decided with `api.rand()`.

## What is where

```
art/palette.json, palette.png   Lospec500 with its 16 ramps and roles
art/assets.md                   the asset list, the art grid, the map, the bone and splat budgets
art/manor/                      the hero's Codex brief, sheet v1 (reviewed: false), record, cut views (refs/)
models/manor/                   spec + gate record, p1_blockout.txt, p2_form.txt, bake file, gate shots, the GLB
models/layout.py                the map's numbers (halls, deposits, groves, river, fords, paths, spots)
models/meshkit.py               a small flat-shaded mesh kit and GLB writer
models/make_models.py           units, buildings, groves, loads, projectiles, scaffold -> models/<name>/<name>.glb
models/env/make_env.py          terrain.glb (heightfield, river, fords, paths) and woods.glb (static props), trees.txt
models/make_bake.py             writes scene.bake.json
lookdev/                        the turntable bench (no RML): manor.bin
scene.bake.json                 the composition: 102 835 splats, 63 game bones, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
tools/bot.py                    a closed-loop test player (pointer or touch presses through --commands)
goldens/                        manor (framed), manor@scene (texel 0.06), scene (demo frames + the hint)
shots_scene/                    the scene frames the goldens were snapped from
build.sh                        rebuilds every model and blob
```

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models, the Manor (p1, p2), lookdev/manor.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/manor/manor.rmdl -o /tmp/m_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/manor/refs --shots /tmp/m_p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob manor -o /tmp/m_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/manor/refs --shots /tmp/m_alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L=(--arg sunYaw=-40 --arg sunPitch=50)
python3 $K/scripts/golden.py views --rive lookdev --blob manor -o /tmp/m --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/m --goldens goldens/manor
python3 $K/scripts/golden.py views --rive lookdev --blob manor -o /tmp/m_s --texel 0.06 --size 200 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/m_s --goldens goldens/manor@scene
for n in 120 7200 12600; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 2; done
```

Goldens: `demo_120` (two seconds in: the skirmish at the west ford, workers carrying gold home), `demo_7200`
(2:00: both villages built up, the kingdom's army gathered by its yard, the warband's at its pit), `demo_12600`
(3:30: a watchtower holding the west ford against a wave), `frame_030` (the hint before the first tap). Frame
audit: 100 % solid 2 x 2 blocks, 34-35 colours, 0 off-palette.

Play it headless (presses only, as a phone would): `--touch=drag@20,200>200,330:8` boxes the three yeomen,
`--touch=tap@100,273` selects the Manor and `--touch=tap@516,372` arms COTTAGE; a `drag@` then shows the ghost
under the finger and builds where it lifts. The bot: set `TRACE` true in `scene/game.as` (it prints a state line
every 20 frames), then `python3 tools/bot.py [--touch] [--pace 2] [--idle] [--patient]`; set it back to false.
The demo-to-player hand-over: `printf 'data demo=true\nadvance 400\ndata demo=false\nadvance 30\nscreenshot
/tmp/h.png\nquit\n' | rive scene --commands` shows the hint over a fresh match. A world point (x, z) on the
ground shows at about (320 + 33.3 x, 200 + 20.5 z) on the 640 x 400 artboard.

## Notes from building it

- **Bones are the design.** 63 of 63: a pool per unit type and side (5, 5, 4), one bone per building slot (one
  barracks, two towers, two supply huts a side, which also caps what can be built), six groves, three sacks and
  three log bundles shared by both sides, four arrows and four spears, three scaffolds. Everything else that
  moves or appears (rings, bars, markers, the ghost, sparks, dust, "+8") is HUD pixels.
- **Construction** reuses the building's own bone: it stands sunk into the ground and rises in five steps (the
  ground's splats hide what is below), inside a scaffold scaled to its footprint; the bone pops when done.
  Groves shrink by bone scale in four steps (baked at full size), then fall and hide over baked stumps.
- **Pathing:** a 48 x 38 grid of 0.4 m cells (water, woods, deposits and the map's edge static; buildings and
  groves stamped in when they change), A* with a binary heap on demand, string-pulled with line-of-sight
  checks, at most six searches a frame and one per unit every half second; a clear line skips the search.
  Units push each other apart (a walker shoulders through, a standing unit gives way) and slide along blocked
  cells. A 40-minute demo runs at about 1 ms of script a frame.
- **The first AI never won.** Symmetric armies attacking a home army with towers always lost, so matches never
  ended: waves now regroup at their ford, siege a hall they reach, press a clear advantage, and go all in when
  the army is full; the demo's matches then end in 4 to 15 minutes, won by either side.
- **The camera is not turned.** yaw 0 keeps the board, the grid and the HUD aligned with the screen; the
  isometric read comes from turning every building 35 degrees.
- **Scale:** at `pixelSize` 2 a unit 1 m tall is about 14 art pixels: small but readable, with team colours
  (royal blue, crimson) on every unit and big, separately coloured silhouettes (a straw hat, a helmet and shield,
  a hood and bow; a hunch, a pauldron and club, a tall spear).
- The Codex sheet was not reviewed by a person yet (`art/manor/sheet.v1.png.json`, `reviewed: false`).
