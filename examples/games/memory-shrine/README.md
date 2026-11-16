# Game: Memory Shrine (Citrink, 8 colours)

**How to play:** listen to the shrine's bells, then click them back in the same order; every round
adds one note.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Citrink](https://lospec.com/palette-list/citrink) by Inkpendude,
eight colours (white, yellow, lime, green, teal, steel blue, navy, ink) in 13 ramps; it loaded from
Lospec, so the spare (`zughy-32`) was not needed. A torii on a mountain top above a sea of clouds at
moonrise: navy-black sky, small snowy peaks, a teal gate, stone lanterns glowing yellow, and four
bells in the palette's own ramp from green through lime and gold to white. Orthographic, yaw -6,
pitch 11, `orthoHeight` 8.6 m, `pixelSize` 3 (texel 0.063 m), moonlight from the front right
(yaw 32, pitch 34), per-splat dither, ink 1, a flat night sky.

## Rules

- One verb: click. The first click wakes the bells; the shrine rings a tune of one note.
- Each bell, when it rings, lights up (an unlit copy is swapped in), swings on its cord, sends out a
  ring wave and a few rising sparks. Under the bells a row of pips shows the tune's length; rung
  notes fill in with their bell's colour.
- "YOUR TURN": click the bells in the same order (a click anywhere in a bell's column counts; a small
  mark under the lip shows the bell under the pointer). Repeat the whole tune and the round is clear:
  the tune grows by one note and plays a little faster (0.64 s between notes, down to 0.3 s).
- A wrong bell clanks (a short hard shake, the view jolts by a pixel) and the right bell flashes;
  six seconds of silence on your turn tires the shrine (a bar under the pips counts down the last
  four). Either ends the run: WRONG BELL or TOO SLOW, with the rounds and the session's best; the next
  click starts a new run.
- A run lasts from a few seconds to a minute or two; most people reach 6 to 10 rounds.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the first bell rings within half a
second. The demo player answers at a person's pace (0.3 to 0.8 s a bell, slower late in a long
tune) and never slips on short tunes; from six notes on each answer has a growing chance of a slip
(usually the neighbouring bell, sometimes the note before), so its runs end at 6 to 9 rounds after
40 to 60 s. It restarts two seconds after the game-over panel. When demo is switched off, a fresh run
starts at once.

## What is where

```
art/palette.json, palette.png   Citrink with ramps stone, moss, copper, snow, gold, teal, moon, glow, lime, white,
                                spark, limeb; roles (night sky, fog, void)
art/assets.md                   the asset list, bones, layout
art/bell/                       the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/bell/                    spec + gate record, p1_blockout.txt, p2_form.txt, bell.bake.json, gate shots, bell.glb
models/env/                     make_env.py writes terrace, torii, lantern, pine, peaks, moon, clouds, stars, ripple,
                                note .txt (hedra command files); their GLBs
lookdev/                        the turntable bench (no RML): bell.bin
scene.bake.json                 the composition: world, game bones (bell0-3, glow0-3, ripple0-3, note0-9),
                                material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light, sky), game.as (the whole game), renderer
goldens/                        bell (framed), bell@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 22 of 63. Splats: 97 696 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the bell, lookdev/bell.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/bell/bell.rmdl -o /tmp/bell_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/bell/refs --shots /tmp/bell_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob bell -o /tmp/bell_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/bell/refs --shots /tmp/bell_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=32 --arg sunPitch=34 --arg keyLight=0.4 --arg highlight=0.85)
python3 $K/scripts/golden.py views --rive lookdev --blob bell -o /tmp/bell --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/bell --goldens goldens/bell
python3 $K/scripts/golden.py views --rive lookdev --blob bell -o /tmp/bell_s --texel 0.0527 --size 120 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/bell_s --goldens goldens/bell@scene
for n in 32 1350 2344; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/demo_*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

(The top view fails the bell's gates by design: a waiver in `models/bell/bell.spec.md`.)

Play it headless (the first tune is the white bell, the second white then lime):
`rive scene --screenshot=$PWD/p.png --advance=5 --pointer=click@320,200 --advance=110
--pointer=click@480,200 --advance=185 --pointer=click@480,200 --advance=25 --pointer=click@260,215
--advance=20` clears round 2 ("ROUND 2 CLEAR"); `--advance=5 --pointer=click@320,200 --advance=110
--pointer=click@150,225 --advance=150` rings the wrong bell (WRONG BELL, then the game-over panel).
The hand-over from demo to a player, with `--commands`: `data demo=true`, `advance 240`, `data
demo=false`, `advance 60` (a fresh run, ROUND 1).

## Notes from building it

- The camera is orthographic, so "far" mountains keep their size and a pitched view lifts them by
  z sin(pitch): the first peaks (6 to 9 m tall, 20 to 30 m back) filled the sky behind the bells. They
  are now small cones 9 to 15 m back, sunk in the clouds, with only their camera-facing faces (78 000
  splats down to 6 800). The moon and the stars sat past the bounds' far plane and were clipped; the
  bounds now reach 16 m back and both sit 15 m back.
- Fog (`fogMax` 0.3) dissolved the snow caps into a Bayer checker of white and steel: no fog; the
  depth comes from the paint (navy peaks, steel clouds).
- The four bells are one GLB baked eight times: four lit (the material mapped to a different ramp
  each, with `"step"` to reach the right colour) and four unlit "glow" copies in brighter ramps, swapped
  in while a bell rings. A bell swings about its hang point: the game places the bell's origin (its
  lip) at hang point + R(angle) (0, -L, 0) and rolls it by the same angle.
- The bake warns that the bells' colours are far from their ramps: on purpose (one green-yellow-teal
  model painted once and mapped to five different ramps per copy).
- The Codex sheet was not reviewed by a person yet (`art/bell/sheet.v1.png.json`, `reviewed: false`).
