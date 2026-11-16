# Game: Peg Drop (Pear36)

**How to play:** move the pointer to slide the clockwork dropper along the rail, click to drop a coin;
it rattles down through the brass pegs and past the swinging pendulum into a cup. Ten coins a run; the
cup under the glowing diamond pays double.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Pear36](https://lospec.com/palette-list/pear36) by PineappleOnPizza,
36 colours in nine ramps (brass, gold, wood, felt, steel, copper, plum, jewel, lamp); it loaded from
Lospec, so the spare (`sheltzy32`) was not needed. A clockwork workshop at lamp light: a teal felt peg
board between wooden posts, brass pegs and cups, plum striped wallpaper, big brass gears ticking on the
wall, two warm hanging lamps, a shelf of jars and a clock. Front view from a little above, orthographic
9 m (texel 0.066 m), `pixelSize` 3, the lamp light from the upper left (sun yaw -35, pitch 38), per-splat
dither, ink 1.

## Rules

- One verb: move and click. The dropper follows the pointer along the rail on a spring (it lags and
  leans into the slide). A click drops a coin from its chute; it then winds itself up for 1.1 s (it
  rattles) before the next coin. The first click starts the run and drops the first coin.
- Coins fall through 39 pegs with real bounces (2D physics in the board's plane, restitution 0.45, a
  random nudge per hit, a coin balanced on a peg tips off). The middle of the board has no pegs: the
  pendulum's bob swings through it (36 degrees each way, 2.6 s a swing) and bats coins aside with its
  own speed.
- Seven cups pay 20, 50, 10, **100**, 10, 50, 20. The middle cup is guarded by the pendulum and the hub
  at its pivot; its neighbours pay little. A glowing diamond hovers over one cup: a coin landing there
  scores double, then the diamond moves to another cup.
- Coins stay in their cups as a pile. After the tenth coin settles: GAME OVER with the score and the
  session's best; the next click empties the cups (the coins drop through the tray) and starts a new run.
- A run lasts 15 to 30 seconds.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the dropper sets off at once and drops its
first coin within half a second. For each coin the demo player picks a plan (half the time the
jackpot, a third the lit cup, otherwise a whim) with a little aim error, waits a moment, and before a
jackpot try waits for the bob to be swinging away from the middle (nine times in ten). The pegs and the
pendulum decide the rest, so it scores 200 to 700 a run with plenty of 10s. It restarts two seconds
after GAME OVER; when demo is switched off, a fresh run waits for the first click.

Motion: the gears and the clock's hand advance in ticks with the pendulum (an escapement); coins flip
as they fall (12 fps) and roll with their sideways speed; the dropper squashes and stretches as a coin
leaves; landings pop sparks and a rising number; a 100 or more shakes the view by whole texels; hard
peg hits spark.

## What is where

```
art/palette.json, palette.png   Pear36 with ramps brass, gold, wood, felt, steel, copper, plum, jewel, lamp; roles
art/assets.md                   the asset list, bones, layout
art/dropper/                    the hero's Codex brief, sheet (v1) and record, cut views (refs/, back flipped)
models/dropper/                 spec + gate record (and the colour waiver), make_dropper.py -> p1_blockout.txt,
                                p2_form.txt, p3_splat_fit.txt; dropper.glb (gated form), dropper_splat.glb (the
                                bakes'), dropper.bake.json, gate shots
models/env/                     make_env.py writes board, wall, gear_big, gear_small, pendulum, coin, hand,
                                marker, spark .txt (hedra command files) and pegs.txt (the peg list); their GLBs
lookdev/                        the turntable bench (no RML): dropper.bin
scene.bake.json                 the composition: board and wall (static), game bones (dropper x1.3, pendulum,
                                gearA-C, hand, marker, coin0-9, spark0-7), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        dropper (framed), dropper@scene (at the scene's texel), scene (demo_090: the first
                                coins falling, demo_300: a jackpot, demo_600: piles in the cups, frame_030: the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 25 of 63. Splats: 63 299 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the dropper (p1, p2, p3), lookdev/dropper.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/dropper/dropper.rmdl -o /tmp/dr_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/dropper/refs --shots /tmp/dr_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob dropper -o /tmp/dr_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/dropper/refs --shots /tmp/dr_alb -p art/palette.json --min-iou 0.7   # colour drift waived (spec)
L=(--arg sunYaw=-35 --arg sunPitch=38 --arg keyLight=0.4 --arg highlight=0.85 --arg edgeDepth=0.3)
python3 $K/scripts/golden.py views --rive lookdev --blob dropper -o /tmp/dr --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/dr --goldens goldens/dropper
python3 $K/scripts/golden.py views --rive lookdev --blob dropper -o /tmp/dr_s --texel 0.051 --size 100 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/dr_s --goldens goldens/dropper@scene
for n in 090 300 600; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Play it headless. A world x on the board is at about screen x = 320 + 45.3 x (the rail spans 152 to
488); the dropper only reads the pointer's x. Ten drops, then GAME OVER, then a click for a new run:

```sh
rive scene --screenshot=$PWD/p.png --advance=3 --pointer=click@320,60 --advance=70 --pointer=click@250,60 \
  --advance=70 --pointer=click@400,60 --advance=70 --pointer=click@320,60 --advance=70 --pointer=click@150,60 \
  --advance=70 --pointer=click@480,60 --advance=70 --pointer=click@320,60 --advance=70 --pointer=click@330,60 \
  --advance=70 --pointer=click@310,60 --advance=70 --pointer=click@200,60 --advance=400
```

The demo-to-player hand-over: `printf 'data demo=true\nadvance 400\ndata demo=false\nadvance 30\nscreenshot
/tmp/h.png\nquit\n' | rive scene --commands` shows the hint over empty cups.

## Notes from building it

- A Python port of the coin physics (scratch, not kept) sized the board before any Rive run: with pegs
  1.0 m apart a coin wedged between the wall and the outer peg (a 0.4 m gap for a 0.44 m coin) every
  time; at 0.95 m spacing the gap is 0.575 m. Coins dropped exactly over a peg balanced on it for
  seconds: a hit on a coin's underside now rolls it off sideways, and a coin that has not got 5 cm
  lower in 0.45 s is tipped off (rarely needed).
- The pegs in the pendulum's sweep (rod and bob) and next to its hub are left out by `make_env.py`;
  the same list is pasted into `game.as` (`PEG_X`, `PEG_Y`), so the bake and the physics agree.
- The sheet's BACK view drew the key on the wrong side; it is cut with `--flip back` (the dropper is
  symmetric but for the key).
- The splat gate's aspect drift failed in the right and top views (0.14, 0.13) on the gated form: a
  `p3_splat_fit.txt` shrinks the depth and thickens the coin and key for the splats only.
- A clock face with four tick marks read as a skull at the art grid: the ticks were dropped, a brass
  pin and the hand are left.
- The dropper is baked at 1.3 x its sheet size so the hero reads at 25 art pixels wide.
- The Codex sheet was not reviewed by a person yet (`art/dropper/sheet.v1.png.json`, `reviewed: false`).
