# Game: Orbit Defense (Berry Nebula, 8 colours)

**How to play: click to fire: the orbital cannon swings round the tiny planet and shoots at the pointer;
pop the meteors before they flatten the four houses.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra
0.1.0, codex-cli. Palette: [Berry Nebula](https://lospec.com/palette-list/berry-nebula) by LostInIndigo
(loaded from Lospec; the spare was not needed), eight colours in one long run from night purple to cyan,
split into 11 ramps. Deep space: a flat `#0d001a` sky, unlit star specks and wine-dark nebula clouds behind,
a berry planet lit from the upper left (a mauve and blue crescent, a dark night side), houses and the
player in cyan, the enemies in mauve and plum with glowing tails.

Rules: meteors (and from 4 s on, big ones) fly in from every side, each aimed at a living house. A bolt
pops a small meteor (+1); a big one splits into two fast halves (+1). The satellite's body also blocks a
meteor (no score; it reels). A meteor reaching a house flattens it (rubble, a dust puff, a camera shake);
when the fourth house falls the run is over and shows the score. Meteors come faster and closer together
(a gap of 1.2 s falling to 0.55 s, pairs after 12 s): a run lasts 30 to 90 s. The best score is kept for
the session (the demo keeps its own). The satellite follows the pointer as it moves; a click turns it there
and fires (one shot in flight per 0.16 s). The first click starts the run; after a game over the next
click (after 0.8 s) starts a new one in the same world, the houses popping back.

Sound (`sfx.as`, silent in demo mode): a run starts with a rising arpeggio; each shot is a pew (its pitch
cycles over three shots); a hit is a burst (deeper for a boulder) with a note that climbs a pentatonic run
for each hit in a row (a miss or a lost house starts it again); a boulder rushes in with a low whoosh from
its side; the satellite blocking a rock crunches and zaps; a rock reaching the ground booms, a flattened
house crunches with a low note that sinks with each house lost; the last house plays the falling game-over
arpeggio, with a high bell for a new best.

Demo (`--arg demo=true`, the gallery's `Sample.demo`): a run starts at once with a meteor already in view;
the demo waits until a meteor is well inside the frame, aims at the most urgent one with lead, clicks at a
human pace (0.3 to 0.8 s, slowing as it tires), with a small aim error and a clear miss about one shot in
five. It loses its houses one by one and dies after about 75 s (score ~50); two seconds after a game over
it starts again. Turning demo off starts a fresh run at once.

```
art/palette.json, palette.png   Berry Nebula with ramps rock, sea, wall, roof, metal, panel, meteor, glow,
                                star, nebula, fire (roles: flat #0d001a sky)
art/assets.md                   the asset list: sizes, ramps, bones (53 of 63, all game bones)
art/satellite/                  the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/satellite/               spec + gate record, p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB
models/env/                     make_env.py writes the command files of planet, sky, hut, dome, rubble, meteor,
                                boulder, trail, bolt, burst, debris, puff, flash; their GLBs
lookdev/                        the turntable bench (no RML): satellite.bin
scene.bake.json                 the composition: the static planet and sky, every game piece a bone or a pool
                                ("bone" / "copies"), a "bounds" play area
scene/                          the Rive project: scene.rml (orthographic 8 m, yaw 0, pitch 0, sun upper left,
                                no shadows, flat sky), the renderer files, game.as (all of the game)
goldens/                        the satellite framed and at the scene's texel (0.06), four scene frames
shots_scene/                    the scene frames: frame_030 (the hint), demo_045, demo_250, demo_600
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                             # models/env + satellite from scratch, lookdev/satellite.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary    # clean: 0 errors, 0 warnings, no problems
rive scene                                             # play it
rive scene --arg demo=true                             # watch the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/satellite/satellite.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/satellite/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob satellite -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/satellite/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunYaw=-50 --arg sunPitch=35 --arg keyLight=0.45 --arg highlight=0.8 --arg shadeSteps=2 --arg shadows=0"
python3 $K/scripts/golden.py views --rive lookdev --blob satellite -o /tmp/sat --real-sky ${=L}        # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/sat --goldens goldens/satellite
python3 $K/scripts/golden.py views --rive lookdev --blob satellite -o /tmp/sat_s --texel 0.06 --size 160 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/sat_s --goldens goldens/satellite@scene
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
for n in 45 250 600; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
rive scene --screenshot=$PWD/play.png --advance=30 --pointer=click@120,90 --advance=30   # a click fires at a meteor
```

Notes from building it:

- The play plane faces the camera, so `api.pick` (a horizontal plane only) cannot turn the pointer into a
  world point: `game.as` intersects the pointer's ray with z = 0 itself (`toPlane`), from the camera fields
  the renderer fills (`camE*`, `camF*`, `camR*`, `camU*`, `camHW/HH`, `gridO*`).
- Everything on the planet's rim is turned with a roll, and `api.placeScaled` only turns about Y: `game.as`
  writes the bone matrix itself (`placeRoll`: a roll in the play plane plus a per-axis squash).
- At `pixelSize` 3 on a 640-wide frame the HUD first sat 2 screen pixels off the centred art grid, so its
  text straddled art pixels (96.5 % solid blocks), and `game.as` slid every rectangle onto the grid
  (`alignHud`). The renderer now aligns the HUD itself: the workaround is gone, the frames are unchanged.
- The hero first baked at 0.09 m (290 splats) and its wings fattened past the aspect tier; the scene shows it
  1.25x larger at 0.07 m (690 splats), and the bench is baked the same way.
- Dark meteors vanished into the nebula and the night: they are painted on the meteor ramp's top step with
  plum hot faces and a plum-and-mauve tail, the nebula kept to the two darkest steps.
- The Codex sheet was not reviewed by a person yet (`art/satellite/sheet.v1.png.json`, `reviewed: false`).
