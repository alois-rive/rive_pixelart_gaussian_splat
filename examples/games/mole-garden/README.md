# Game: Mole Garden (Steam Lords)

**How to play: click the moles as they pop up; spare the rabbits. 45 seconds.**

Moles pop out of nine molehills in a vegetable bed at dusk; the mallet follows the pointer and a click
brings it down. A mole hit scores 1 (2 from the fifth hit in a row: a streak); a bonked rabbit costs 3. The
moles come faster, stay shorter and come in pairs as the clock runs down. Before the first click moles
peek now and then (the hint is shown); the first click starts the 45 s clock. At zero: "TIME'S UP!" with
moles, score and the session's best; the next click starts a new run in the same garden. Demo mode plays
like a decent human: it notices a mole after 0.3 to 0.6 s, glides the mallet over and whacks, misses one
swing in six, lets some moles get away, almost never hits a rabbit, and restarts two seconds after the
end (about 45 moles and 55 points a run).

Sound (`sfx.as` presets, silent in demo, and the peeks before the first click stay quiet): a rising
arpeggio starts the clock; in a run each mole pops out of its hole (back row highest, front row lowest,
panned by column) and a rabbit hops out; a hit is the mallet's bonk and a coin a whole tone higher for
each mole of the streak, with a bright blip from the fifth (+2); a miss thumps the earth (lower when it
breaks a streak of 3 or more); a bonked bunny crunches with a falling buzz; the last five seconds tick,
higher each second; TIME'S UP is a low fanfare, then a rising arpeggio for a new best.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra
0.1.0, codex-cli. Palette: [Steam Lords](https://lospec.com/palette-list/steam-lords) by Slynyrd (loaded
from Lospec; the spare `pear36` was not needed), 9 ramps. Orthographic, yaw 0, pitch 52, 4.8 m tall,
pixelSize 3; a low dusk sun from the front left; two lanterns glow (unlit splats).

```
art/palette.json, palette.png   Steam Lords with ramps fur, snout, soil, leaf, straw, bunny, wood, steel, glow
art/assets.md                   the asset list, layout, bones
art/mole/                       the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/mole/                    spec + gate record, p1_blockout.txt, p2_form.txt, p3_splat_fit.txt, bake file, gate shots, GLB
models/env/                     garden, hole, cabbage, turnip, pumpkin, fence, scarecrow, lantern, rabbit, mallet, bonk:
                                command files and GLBs; make_soil.py draws textures/soil.png
lookdev/                        the turntable bench (no RML): mole.bin
scene.bake.json                 the composition: game bones (mole0-8, rabbit0-2, mallet, bonk0-2), bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer files
goldens/                        mole framed and at the scene's density; scene/: demo_064, demo_420, demo_600, frame_030
shots_scene/                    the scene frames the goldens were snapped from
build.sh                        rebuilds every model and blob from the command files
```

What moves (16 game bones of 63, all written by `game.as`): moles and rabbits (rise with a stretch, a pop
overshoot, a stepped look-around, a squash flat when hit, a rabbit's startled leap and spin, the sink),
the mallet (glides after the pointer, raised and bobbing; smashes down on a click and springs back), the
star bursts, and a little camera shake when a rabbit is hit.

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # textures, models, lookdev/mole.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary
rive scene                                   # play: click the moles
rive scene --arg demo=true                   # the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/mole/mole.rmdl -o /tmp/mg_p2 --views front,right,back,top   # after p2 only (build.sh runs p3 too)
python3 $K/scripts/golden.py gate --refs art/mole/refs --shots /tmp/mg_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob mole -o /tmp/mg_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/mole/refs --shots /tmp/mg_alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunYaw=-60 --arg sunPitch=38 --arg keyLight=0.4 --arg highlight=0.82 --arg shadeSteps=1.2"
python3 $K/scripts/golden.py views --rive lookdev --blob mole -o /tmp/mg_f --real-sky --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/mg_f --goldens goldens/mole
python3 $K/scripts/golden.py views --rive lookdev --blob mole -o /tmp/mg_fs --real-sky --texel 0.027 --size 160 --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/mg_fs --goldens goldens/mole@scene
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
for n in 64 420 600; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Notes from building it:

- At 5.6 m the moles were tokens: the view closed in to 4.8 m.
- Dark purple fur on dark soil at dusk did not read: the scene bakes the fur one step lighter.
- The mallet first swung in a plane almost along the view, and its raised head hung over the mole it was
  aiming at; it now swings from the right (yaw 75), so the head crosses the screen and the mole stays in view.
- The first demo was a machine (24 points in 15 s); its reaction time and miss rate grew.
- The Codex sheet was not reviewed by a person yet (`art/mole/sheet.v1.png.json`, `reviewed: false`).
