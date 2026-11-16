# Game: Vale Guard (Vinik24, 24 colours)

**How to play: tap a stone pad to build a tower, tap a tower to upgrade or sell it; hold the valley path
against 15 waves of creeps.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra
0.1.0, codex-cli. Palette: [Vinik24](https://lospec.com/palette-list/vinik24) by Vinik (loaded from Lospec;
the spare `resurrect-64` was not needed), its soft, muted colours split into 17 ramps that share their
dusk purple and their pale. A green valley seen from above and in front (orthographic, pitch 40, the
cottages turned corner-on): a black cave in a boulder outcrop back left, a dirt path winding across the
valley in three runs to a roofed gate in the village palisade on the right, ten pale stone pads along it,
round trees, a pine ridge behind.

## Rules

A run starts at once: 110 gold, 20 lives, wave 1 in 20 seconds (START WAVE calls it now). Creeps leave the
cave and follow the path; one that reaches the gate costs lives (a troll 5, a shellback 2, others 1).
Kills pay gold, and a finished wave pays 10 + 2 x its number; a wave with no leaks also scores. After a
wave's last creep has come out, the next one starts in 10 s; NEXT calls it now and pays a gold for every
second left. Fifteen waves; every fifth brings the moss troll. Win: all fifteen held with lives left
(the score adds 50 a life). Lose: no lives. The best score is kept for the session (the demo keeps its
own); after the end the next tap starts the same valley again.

| Tower | Cost | Upgrades | Does |
|---|---|---|---|
| ARROW: Larch Loft | 40 | 45, 75 | a timber lookout with a brass crossbow: fast bolts (9 / 14 / 21, every 0.55 / 0.46 / 0.38 s), range 2.5-3 m, hits flyers |
| CANNON: Boulder Keep (the hero) | 70 | 65, 100 | a round stone keep with a brass cannon: lobbed balls that burst on the ground (28 / 44 / 66 in 0.8-1.05 m), slow, cannot hit flyers |
| FROST: Rime Well | 55 | 50, 80 | a well with a floating ice crystal: frost shards that chill (speed x0.55 / 0.45 / 0.35 for 1.8 s; levels 2-3 chill round the target) |
| STORM: Thunder Spire | 90 | 80, 120 | a slate obelisk with a storm orb: lightning that jumps to 3 / 4 / 5 creeps (each jump 75 %), ignores armour, hits flyers |

Level 1 towers are smaller; level 2 grows to full size (one gold chevron over it); level 3 raises gilded
standards round its pad (two chevrons). Selling refunds 70 % of what the tower cost. Arrow and cannon
towers turn to their target (in 15-degree steps); every tower aims at the creep furthest along.

| Creep | HP (wave 1) | Speed | Armour | Gold |
|---|---|---|---|---|
| Mite (plum beetle, the swarm) | 26 | 1.0 m/s | 0 | 4 |
| Skitter (teal lizard, fast) | 38 | 1.85 | 0 | 5 |
| Shellback (indigo dome) | 140 | 0.6 | 6 (each hit loses 6, never below 1) | 10 |
| Gloom moth (flyer) | 52 | 1.0, straight from the cave to the gate | 0 | 7 |
| Moss troll (boss, waves 5, 10, 15) | 640 / 1400 / 2300 | 0.42 | 4 | 60 |

HP grows 28 % of its base a wave, and from wave 8 on another 6 % a wave on top.

## Controls (pointer only, touch-ready)

Every action is a single press: on a pad (a box about 22 x 17 art pixels round it; on a tower up to its
roof), on a choice in the ring (34 x 13 art pixels each: ARROW above the pad, CANNON right, FROST below,
STORM left; on a tower UPGRADE above, SELL below), or on the NEXT / START button (54 x 16, bottom right).
Nothing needs hovering, dragging or a pointer leaving: on a phone a tap is a press at the touched point,
which is all the game reads. The ring shows each choice's cost, greys what you cannot afford, and a refused
choice flashes the gold red; tapping anywhere else closes it. The selected tower's range shows as a dashed
ellipse.

## Sound

`sfx.as` effects, silent in demo mode, every one decided by the game's state (never by `api.rand`): a
build is a thud with a note that rises by tower kind; an upgrade a rising arpeggio (higher for level 3), a
sale a coin. Shots are rate-limited per kind (one in 0.12-0.18 s): a crossbow pew, a cannon thump with a
whoosh and a burst where the ball lands, a high bell for a frost shard, a zap for lightning. Hits crunch
quietly (lower on armour), deaths pop (pitched by creep), the troll falls with an explosion and two
bells. A leak is a low crunch and a bell that drops when lives run short. A wave starts with a three-note
call (a low bell and a falling figure for a troll wave) and a clean wave ends with a four-note jingle.
The win is a fanfare with bells; the loss the falling game-over; a new best adds a high bell. Early gold
and a ring choice click; a refused one blips low.

## Demo

`--arg demo=true` (the gallery's `Sample.demo`): the valley opens mid-game: an arrow loft, a second loft
and a keep already stand, wave 2 has been running for seven seconds (simulated in `beginDemo` without
drawing), so creeps are on the path and the towers are firing from frame 0. The demo player builds in a
sensible order (the central pads first, a mix of all four kinds), opens the ring on a pad and takes the
choice half a second later as a person would, upgrades the cheapest worthwhile tower (cannons and
storms first, keeping a reserve for its next build early on), and calls waves early when no creep is
past a third of the path. Its pace leaves leaks on the hard waves (it usually wins with 14-16 lives, at
about 6 minutes); two seconds after the end it starts again. Turning demo off starts a fresh run.

## Files

```
art/palette.json, palette.png   Vinik24 with 17 ramps (roles: flat #433455 sky, void)
art/assets.md                   the asset list, layout, bones (59 of 63) and splats (97 377)
art/keep/                       the hero's Codex brief, sheet (v1) and record, refs/, gate_palette.json
models/keep/                    spec + gate record (waiver), make_keep.py -> p1_blockout.txt, p2_form.txt,
                                bake file (the bench), gate shots, the GLB
models/env/                     make_env.py: the layout (path, pads), ground texture, every other model's
                                command file (ground, scenery, loft, well, spire, standard, mite, skitter,
                                shell, moth, troll, bolt, ball, shard, pop) and the layout table in game.as
lookdev/                        the turntable bench (no RML): keep.bin
scene.bake.json                 the composition: ground and scenery static, every game piece a pool, "bounds"
scene/                          the Rive project: scene.rml (orthographic 9 m, pitch 40, sun front left),
                                the renderer files, game.as (all of the game)
goldens/                        the keep framed and at the scene's texel; four scene frames
shots_scene/                    frame_030 (the hint), demo_045, demo_1500, demo_17000 (level-3 standards)
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                             # env + keep from scratch, lookdev/keep.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary    # clean: 0 errors, 0 warnings, no problems
rive scene                                             # play it
rive scene --arg demo=true                             # watch the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/keep/keep.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/keep/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob keep -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/keep/refs --shots /tmp/alb -p art/keep/gate_palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunYaw=-35 --arg sunPitch=50 --arg keyLight=0.42 --arg highlight=0.9 --arg edgeDepth=0.45 --arg shadeSteps=1"
python3 $K/scripts/golden.py views --rive lookdev --blob keep -o /tmp/keep --real-sky ${=L}          # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/keep --goldens goldens/keep
python3 $K/scripts/golden.py views --rive lookdev --blob keep -o /tmp/keep_s --texel 0.055 --size 140 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/keep_s --goldens goldens/keep@scene
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
for n in 45 1500 17000; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
# touch only: tap pad 5, take CANNON, tap START WAVE
rive scene --screenshot=$PWD/touch.png --advance=10 --pointer=down@310,254 --pointer=up@310,254 --advance=5 \
  --pointer=down@412,254 --pointer=up@412,254 --advance=20 --pointer=down@553,370 --pointer=up@553,370 --advance=300
```

## Notes from building it

- Bones decide the design: a bone holds one model, so towers are pooled per kind (4 each) and the
  levels are a scale (level 1 at 0.8, everything baked at its largest) plus a shared pool of gilded
  standards for level 3, instead of three models per kind (which would need 48 bones for ten pads).
- The creeps' spawn clock pauses while a kind's pool is full, so a wave never needs more bones; the
  waves are written as short strings (`"h4:1.0 m8:0.4 f3:0.9"`) parsed when a wave starts.
- The demo opens mid-wave by running the game's own step function for seven simulated seconds in
  `beginDemo` (no drawing, no sound); the game keeps its own clock (`this.t`), never `api.time`, so that
  fast-forward cannot run time backwards.
- Lightning, HP bars, labels, range and the ring are HUD lines and rectangles; their jitter comes from a
  hash of the frame, never `api.rand()` (`hud()` runs once per drawn frame, which differs between capture
  modes, so drawing from the seeded stream there would change the game).
- `shadeSteps` 1: at 1.5 the towers' shaded walls sat on a band edge and dithered into a checker.
- The skitter was first ochre (gold ramp) and vanished on the dirt path; it is teal now. The troll's
  grey-teal skin vanished on the grass; it is lilac.
- Balanced with a closed-loop test player (`--commands`, the game printing its state with a temporary
  `console.log`, since removed): a touch-only player (`touch down@ / up@`, no moves) that builds the central
  pads and upgrades the cheapest tower wins with 14 lives; the same with clicks wins the same way; a
  player who never taps loses at wave 4. The next tap after either end restarts the valley.
- The Codex sheet was not reviewed by a person yet (`art/keep/sheet.v1.png.json`, `reviewed: false`).
