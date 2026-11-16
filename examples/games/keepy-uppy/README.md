# Game: Keepy Uppy (Journey)

**How to play: click a ball to kick it up (hit its side to steer it); more balls join; none may land.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Journey](https://lospec.com/palette-list/journey) by PineappleOnPizza,
64 colours (it loaded from Lospec: the spare, Cold Light, was not needed), thirteen ramps (sand, sea, foam,
leaf, trunk, red, white, yellow, blue, green, pink, glow, rock): a beach at sunset, a plum sky over an orange
horizon, the sun half under the sea with its glitter path, unlit clouds.

The rules: beach balls fall slowly (a beach ball floats). Click one to kick it up; where you hit it steers it
(hit its left side and it flies right, and it spins). Every 9 seconds a new ball drops in (an arrow at the top
shows where), up to four. A kick scores one point for every ball in play. The first ball that touches the
sand ends the run (THUD, a puff of sand, the crab runs off); click to play again. Best score for the session.
Before the first click the ball waits on the sand, hopping now and then; the first click kicks it. Demo mode
(`--arg demo=true`) opens mid-rally and juggles like a decent player: it kicks a falling ball when it gets low,
aims at the side that sends it back to the middle, whiffs now and then and sometimes waits too long; a run
lasts about half a minute, and it starts again 2 s after the game over.

Sound (procedural, `api.sound`; silent in demo): the first kick a start jingle; every kick a rubbery pop
(higher the more balls are in play) and a plucked note that climbs a pentatonic scale with the rally; a soft pop
for the waiting hop, ticks off the walls and the ceiling, a bell when the arrow warns of a new ball and a whoosh as
it drops; a landing is a THUD and a falling game-over tune; a blip for play again.

```
art/palette.json, palette.png   Journey with its ramps and roles (sky #691749 over #f5a15d, void #110524)
art/assets.md                   the asset list
art/ball/                       the hero's Codex briefs, sheets v1 and v2, records and logs, cut views of v2 (refs/)
models/ball/                    make_ball.py (writes p1_blockout.txt, p2_form.txt), spec + gate record, bake file
                                (lookdev), gate shots, the GLB
models/env/                     make_env.py (writes every other command file and the textures): beach, sun,
                                clouds, foam, palm, umbrella, castle, towel, rocks, crab, shadow, puff, spark; GLBs
lookdev/                        the turntable bench (no RML): ball.bin
scene.bake.json                 the composition: the beach, the foam's baked loop, 23 game bones, the play area
scene/                          the Rive project: scene.rml (orthographic 8 m, yaw 0, pitch 15, light from the
                                front left), game.as (all the game), the renderer files, splats.bin (48 400)
goldens/                        ball framed and at the scene's texel (0.06), scene frames (demo_NNN, frame_030)
shots_scene/                    the scene frames the goldens were snapped from
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                  # models from scratch, lookdev/ball.bin, scene/splats.bin
rive scene --verify && rive scene           # play it; `rive scene --arg demo=true` watches the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/ball/ball.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/ball/refs --shots /tmp/p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob ball -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/ball/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7
L="--arg sunYaw=-20 --arg sunPitch=30 --arg keyLight=0.35 --arg highlight=0.85"
python3 $K/scripts/golden.py views --rive lookdev --blob ball -o /tmp/bl --real-sky ${=L}       # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/bl --goldens goldens/ball
python3 $K/scripts/golden.py views --rive lookdev --blob ball -o /tmp/bls --texel 0.06 --size 80 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/bls --goldens goldens/ball@scene
for n in 90 480 780; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_480.png -p art/palette.json --pixel 3
```

Try it headless: `rive scene --screenshot=$PWD/shot.png --advance=5 --pointer=click@314,322 --advance=130
--pointer=click@385,210 --advance=20` (the resting ball, then the same ball 2.2 s later: score 2).

Notes from building it:

- The ball spins about the vertical only (yaw), so its squash along Y stays vertical whatever the spin.
- A sheet of a sphere can still contradict itself: v1 drew the gores in a different order in each view;
  v2 spelt out each panel. The thin pole caps fattened the ball's height as splats until baked finer.
- The sun stands behind the sea's far edge: the sea plane hides its lower half (no clipping needed).
- The Codex sheets were not reviewed by a person yet (`art/ball/sheet.v*.png.json`, `reviewed: false`).
