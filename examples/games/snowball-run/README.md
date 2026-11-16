# Game: Snowball Run (Ice Cream GB, 4 colours)

**How to play:** move the pointer to steer the snowball down the piste (click to start rolling):
flatten snowmen to grow and score, dodge the pines; a pine knocks a third of the ball off, and a ball
too small to take another hit bursts.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [Ice Cream GB](https://lospec.com/palette-list/ice-cream-gb) by
Kerrie Lake (plum, coral, peach, cream), loaded from Lospec (the spare, 2bit-demichrome, was not
needed). An evening piste: cream snow, coral pines, a low sun from the left throwing long dithered
shadows, peach fog over the far snow and the mountains, a coral sky, a steady snowfall. Bayer dither
on the art grid, ink 1.

The game (`scene/game.as`, all of it): the camera stays put behind the ball and the world slides
towards it, faster and faster (6.5 to 13 m/s). Rows of one to three pines (more as the run goes on)
and snowmen come up out of the fog at the far edge with a pop; mounds make the ball hop; rocks and
bank pines slide past. The ball grows as it rolls (+50 % in a minute) and by 0.05 per snowman; a pine
takes 30 % (the SIZE bar's mark shows where the next pine would burst it). Score: a point a metre plus
25 a snowman, x2 to x4 for snowmen flattened less than 3 s apart. Best score for the session. Motion:
the ball rolls (pitch by distance over radius, roll by swerve), squashes on hits and blinks while it
recovers; pines wobble (stepped); snowmen sway while they wait, squash flat in two frames and sink;
spray flies off the ball, chunks fly on hits; the camera shakes in whole pixels.

Demo mode (`--arg demo=true`, or the `Sample` view model's `demo`): a skier that looks 9.5 m ahead
across 13 lanes, avoids pines, goes for snowmen, re-plans five times a second with a little aim
error and now and then keeps its line without looking (a 0.7 s lapse), so it takes hits and bursts
after 30 to 60 s; it rolls from frame 0 and restarts 2 s after a wipeout. When demo turns off, a fresh
run waits for the click.

```
art/palette.json, palette.png   Ice Cream GB, ramps snow, pine, bark, accent, far, flake
art/assets.md                   the asset list, bones, layout
art/snowman/                    the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/snowman/                 spec + gate record, p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB
models/env/                     make_env.py (writes every other command file: ground, mountains, pine, ball,
                                mound, rock, spray, chunk, snowfall), the command files and GLBs
lookdev/                        the turntable bench (no RML): snowman.bin
scene.bake.json                 the composition: static ground and mountains, game bones (ball, tree x9,
                                side x12, snowman x4, mound x6, rock x4, spray x8, chunk x6), the snowfall
                                track, the play-area bounds
scene/                          the Rive project: scene.rml (orbit yaw 0, pitch 20, ortho 10 m), game.as
goldens/                        the snowman framed and at the scene's texel; scene/: demo_150, demo_480,
                                demo_900 and frame_030 (the hint before the first click)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                             # models from scratch, lookdev/snowman.bin, scene/splats.bin
rive scene --verify && rive scene                      # play it
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/snowman/snowman.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/snowman/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob snowman -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/snowman/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L=(--arg sunYaw=-55 --arg sunPitch=30 --arg keyLight=0.42 --arg highlight=0.85 --arg splatDither=0 --arg bandDither=0.45)
python3 $K/scripts/golden.py views --rive lookdev --blob snowman -o /tmp/sm --real-sky $L && python3 $K/scripts/golden.py check --shots /tmp/sm --goldens goldens/snowman
python3 $K/scripts/golden.py views --rive lookdev --blob snowman -o /tmp/sms --texel 0.075 --size 120 --real-sky $L && python3 $K/scripts/golden.py check --shots /tmp/sms --goldens goldens/snowman@scene
for n in 150 480 900; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --arg demo=true --advance=$n; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_480.png -p art/palette.json --pixel 3
```

Try it headless: `rive scene --screenshot=$PWD/play.png --advance=5 --pointer=click@320,330 --advance=60 --pointer=move@150,330 --advance=40`
(the pointer's x steers; a click starts the run and restarts it after a wipeout).

Notes from building it:

- A splat's disc does not follow its bone's scale: the snowball is baked at its largest (r 1.0, spacing
  0.09) and scaled down, never up.
- A bone scaled to 0 makes every splat of it a giant quad (a singular covariance): `game.as`'s `pose()`
  hides a bone instead of scaling it under 5 %, and the pop-in steps start above that.
- Flakes on the two-step `flake` ramp were inked to peach rings; a cream-only ramp (a colour repeated)
  keeps them single cream dots.
- First tuning had the snowball burst on its first pine and the demo never die; the rules above came
  from watching both (an idle player now wipes out in about 20 s).
- The Codex sheet was not reviewed by a person yet (`art/snowman/sheet.v1.png.json`, `reviewed: false`).
