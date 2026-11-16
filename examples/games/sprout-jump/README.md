# Game: Sprout Jump (DawnBringer 32)

**How to play: hold your finger (or the mouse button) below Pip to run toward it; tap or press above
Pip to jump, hold longer to jump higher; press again in the air for a double jump. Climb from the
garden to the top of the trees and reach the flag.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [DawnBringer 32](https://lospec.com/palette-list/dawnbringer-32) by
DawnBringer (loaded from Lospec; the spare `endesga-64` was not needed), 19 ramps. A bright spring
morning: an orthographic side view pitched 10 degrees down, 5.44 m tall (a texel of exactly 0.04 m),
following Pip; the sun from the front left, per-splat dither, chunky splat shadows (a 2048 map over
the whole 192 m level); no fog. The horizon sinks as Pip climbs, so the crown of the trees is all
deep sky.

The hero is Pip, a radish sprout with boots. The level is one handcrafted run of about 180 m: raised
garden beds over a brook, a leaf raft to the garden wall, a crumbling plank bridge over the pond,
sunflower heads as stepping stones, pots standing in the water, a stone step, crates and a springy
bell-bloom that throws Pip into the treetops, branches, rising and sweeping leaf rafts, two moths,
leaf pads and a last raft to the crown, where the flag waits. Shellbugs patrol seven platforms.
60 seeds, 5 checkpoints (the start included), 3 lives. A good player clears it in about a minute
(the demo player, which never wastes a step, in 44-50 s).

## Controls and feel (pointer only, touch-ready)

| Gesture | Does |
|---|---|
| hold or drag below Pip's feet | runs toward the finger's side: speed by distance (full at 2 m), stops in a 0.35 m dead zone round Pip |
| press above Pip's feet (anywhere higher on the screen) | jumps at once; held: rises on light gravity (1.84 m), released: the jump is cut (0.75 m) |
| a quick tap below Pip | a short hop |
| while holding low, slide the finger up past Pip's feet | jumps (a flick), the finger keeps steering; slide back below the feet to cut the jump and re-arm the flick |
| a second press within 0.5 s of the first jump, in the air | a double jump (+1.3 m, a stepped forward flip) |
| a mouse moving unpressed | steers like a held finger, once the renderer has seen a hover (`api.hoverSeen`): a convenience, nothing needs hovering |
| after a game over or the flag | tap to play again |

On a phone the pointer moves only while a finger is down, so every control works from the press and
the drag: one finger steers by where it rests and jumps by pressing high or flicking up. Running never
jumps (a hold below the feet only steers), and a finger lifted in the air leaves Pip's momentum alone
(no input on the ground stops Pip; no input in the air keeps the speed). A finger's lift sends a last
move at the same point, which is not taken for a hover. A finger still down through a death keeps
steering after the respawn. The hint before the first tap says it in three lines.

Feel: run 4.2 m/s (accelerate 30 m/s², brake 40, 18 in the air); gravity 24 m/s² rising with the
press held, 60 rising after a release, 36 falling (13 m/s at most); coyote time 0.1 s; a press up to
0.14 s before landing jumps on landing; springs throw Pip 4.2 m, a stomp bounces 0.5 m (1.3 m held).
Physics runs at a fixed 1/120 s step, so it is the same at any frame rate.

## Physics

An axis-aligned map written in `scene/game.as` (tables generated from `models/level/layout.py`):
solid blocks (beds, pots, steps, the wall, crates) push Pip out sideways and are landed on from
above; one-way platforms (sunflowers, branches, leaf pads, the crown, the rafts, the planks) are
landed on only when falling through their top; springs are solid stems with a bouncing top. Rafts,
shellbugs and moths are pure functions of the run's clock (they keep moving through deaths), so the
demo player can predict them. A raft carries Pip by its own displacement. A plank shakes 0.45 s after
Pip steps on it, falls, and comes back 3 s later (or at once on a respawn). Touching a critter from
above stomps it (falling, feet above its top less 0.22 m); from anywhere else it costs a life, as does
the brook and pond (x < 104, below y -1.15) or falling off the bottom of the screen in the treetops.
A respawn is at the last checkpoint passed, with 1.5 s of blinking safety. The whole thing was
written first as a throwaway Python port (physics, camera rule, demo player) and tuned there.

## The demo

`--arg demo=true` (the gallery's `demo`): Pip plays itself from frame 0 (running at once, the first
jump, over a pot, within the first second). The demo player runs right; when running on for 0.3 s would hurt, fall or stall, it
simulates 20 candidate jumps with the game's own step function (5 holds x with or without a double
jump x full or 55 % steering), up to 2.4 s each, and takes the safe one that lands furthest right with
the most seeds (a double jump costs a little, so it is rare); in the air it re-checks every 4 frames
and corrects the hold, the steering or adds a double jump. Like a person it stops to wait for rafts,
backs off to find a spring behind it, looks before a leap (35 % of the time, 0.2-0.6 s), and fumbles
12 % of its jumps (the hold far too short or too long, and no correcting it), so some runs clear in
about 50 s and others lose a life or three. It restarts 2.2 s after the flag or a game over; when demo
turns off, a fresh run waits for the first tap. All its randomness is `api.rand()`, so it repeats.

## Sound

`sfx.as` effects, silent in demo mode, none decided by `api.rand()`: a three-note start jingle; each
jump a rising hop whose pitch climbs with the height Pip has reached in the level (the treetops jump
higher), the double jump a higher hop with a whoosh; a landing is a thud scaled by the fall speed
with a soft tick of grass; seeds are coins that climb a semitone for each seed taken within 1.2 s of
the last (an octave at most); a stomp is a low pop and a thud; a spring is a "boi-ng" (two hops, low
then higher, and a plucked note); a plank creaks when stepped on and whooshes as it drops; a
checkpoint rings a bell arpeggio (C, E, G); a fall into the water splashes, a fall off the trees is a
falling "pew", a critter's touch is a hit and two falling notes; a respawn pops; the flag plays the
win arpeggio and a six-note fanfare with a high bell (and one more for a new best); a game over plays
the losing arpeggio and two low notes.

## HUD

Lives as three little radishes, the seed count, the run time; "CHECKPOINT!", "SPLASH!", "WHOOPS!",
"OUCH!" for a second; the end panel with the time, the seeds, the best time and the most seeds of the
session ("NEW BEST!" when the time beats it).

## What moves

55 game bones of 63, no baked tracks: Pip (4: body, sprout, two feet), 12 seeds and 2 sparkles, 3
shellbugs and 2 moths (pools given to the ones near the camera), 3 springs, 6 rafts, 7 planks, 4
checkpoint blooms, the pennant, 3 puffs, the water band, 2 hills, 2 groves, 3 clouds. 95 906 splats
(the static level 67 336). Pip's feet and sprout are placed on points of the body (`api.transform`),
so they follow its squash and stretch and its lean; the sprout swings on a damped spring and is drawn
in 6-degree steps. Every bone is put on the texel grid (x by 0.04 m, y by 0.04 / cos 10 m), so
nothing crawls as the camera scrolls; the camera leads 1.2 m in the running direction, follows the
height Pip stands at (not the jumps), and rises only when Pip goes above the upper part of the view.
The water band moves in whole 4.8 m ripple tiles; the hills, grove and clouds move at 82, 60 and 93 %
of the camera across and sink at 45, 30 and 90 % as Pip climbs.

```
art/palette.json, palette.png   DawnBringer 32 with 19 ramps
art/assets.md                   the asset list, ramps table, layout
art/pip/                        the hero's Codex briefs (v1 refused by the image tool, v2 used), sheet, record, refs/
models/pip/                     spec + gate record, p1_blockout.txt, p2_form.txt, p3_parts.txt, bake file, gate shots, GLBs
models/level/                   layout.py (the level as data), make_level.py (-> level.txt; --as prints the game's tables),
                                make_textures.py (-> textures/), level.txt, level.glb
models/env/                     make_env.py (writes every prop's hedra command file), *.txt, GLBs
lookdev/                        the turntable bench (no RML): pip.bin
scene.bake.json                 the composition: the level, every game bone and pool, bounds, material -> ramp
scene/                          the Rive project: scene.rml (camera and look), game.as (the whole game), splats.bin
goldens/                        pip framed and at the scene's texel; scene/: demo_045, demo_1010, demo_2250, frame_010
shots_scene/                    the latest scene frames
build.sh                        rebuilds every texture, model and blob from the scripts and command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # textures, level, props, Pip (+ parts), lookdev/pip.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary
rive scene                                   # play
rive scene --arg demo=true                   # the demo
```

After editing `models/level/layout.py`: `./build.sh`, then paste the output of `(cd models/level &&
/usr/bin/python3 make_level.py --as)` over the lines from `// LEVEL BEGIN` to `// LEVEL END` in
`scene/game.as`.

Check (gates, goldens, frame audit; zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/pip/pip.rmdl -o /tmp/sj_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/pip/refs --shots /tmp/sj_p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob pip -o /tmp/sj_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/pip/refs --shots /tmp/sj_alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunYaw=-35 --arg sunPitch=45 --arg keyLight=0.45 --arg highlight=0.85 --arg shadeSteps=1 --arg bandDither=0.4"
python3 $K/scripts/golden.py views --rive lookdev --blob pip -o /tmp/sj_pg --real-sky --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/sj_pg --goldens goldens/pip
python3 $K/scripts/golden.py views --rive lookdev --blob pip -o /tmp/sj_pgs --texel 0.04 --size 160 --real-sky --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/sj_pgs --goldens goldens/pip@scene
for n in 45 1010 2250; do f=$(printf %03d $n); rive scene --screenshot=$PWD/shots_scene/demo_$f.png --advance=$n --arg demo=true --quiet; done
rive scene --screenshot=$PWD/shots_scene/frame_010.png --advance=10 --quiet
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Try it headless (touch only: `down`, `move` with the finger down, `up`, `tap`; no bare hover):

```sh
# tap to start (a hop), hold low and right to run, slide up past Pip's feet to jump the pot
rive scene --screenshot=$PWD/touch.png --advance=3 --touch=tap@300,150 --advance=2 \
  --touch=down@520,320 --advance=30 --touch=move@520,200 --advance=10
# the mouse: click to start, hover right to run, click above Pip to jump
rive scene --screenshot=$PWD/mouse.png --advance=3 --pointer=click@300,150 --advance=2 \
  --pointer=move@520,300 --advance=40 --pointer=click@520,150 --advance=12
# the gallery hand-over: demo on, then off (a fresh run waits for a tap)
printf 'data demo=true\nadvance 400\ndata demo=false\nadvance 30\nscreenshot %s\nquit\n' $PWD/handover.png | rive scene --commands
```

How it was tested: a closed-loop Python player drove `rive scene --commands` with touch events only
(`touch down`, `touch move` while down, `touch up`), reading the game's state each frame from a
temporary log and deciding with the Python port of the demo player: it cleared the level in 43.7 s
with 53 of 60 seeds and no life lost; its 2125 recorded events, replayed as `--touch`/`--advance`
flags on the clean build, end on the same "NEW BEST! 0:43.7, 53/60" panel, and `--render-audio` of
that replay (46 s) peaks at 0.34 with no clipping. Another closed-loop run lost three lives on
purpose: the game over panel, then a tap restarts with 3 lives and 0 seeds. The demo was run to
6000 frames (a clear in 49 s, then a run losing two lives). `rive scene --bench=600 --arg demo=true`:
script 0.24 ms a frame on average, 9.5 ms at the worst (a demo decision), render 0.95 ms.

Notes from building it:

- Codex's image tool refused the first brief at its output check (no reason given beyond
  "other"); rewording the first line as "a toy-like game mascot shaped like a round radish
  vegetable" passed with nothing else changed.
- A 192 m level baked whole costs splats, not bones: the first bake was 140 000 splats. Coarser
  spacing for faces seen flat on (soil and stone fronts 0.10, crates 0.10, trunks 0.13, the canopy
  0.18, backdrops 0.12-0.18), deleting the undersides of branches and the backs of clumps, and
  fewer canopy clumps brought the whole blob to 95 906.
- Bayer fog over the flat far layers (the grove, the hills) reads as a dotted grid, as the skill
  warns: the far layers carry their distance by ramp (blue-green hills, olive grove) with fog off.
- The shadow map spans the bake's bounds (192 m here), so a 2048 map gives 0.094 m shadow texels,
  about 2.4 art pixels: chunky but readable under Pip on the tops of things.
- The sheets were not reviewed by a person yet (`reviewed: false`).
