# Game: Marble Tilt (WoodSpark, 16 colours)

**How to play:** click to drop the marble, then move the pointer where you want it to roll: the
board tilts towards the pointer. Miss the holes, reach the flag.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [WoodSpark](https://lospec.com/palette-list/woodspark) by Anubi,
sixteen colours in 8 ramps (wood, leaf, glass, steel, berry, pit, flame, spark); it loaded from
Lospec, so the spare (`zughy-32`) was not needed. A classic wooden tilt-maze toy on a plank table in
lamplight: a honey-coloured box with red knobs, steel-rimmed holes, a blue glass marble, a red-flagged
goal, and on the table a dish of spare marbles, a potted plant, a stack of books and a pencil cup.
Orthographic, yaw 0, pitch 56, `orthoHeight` 8.2 m, `pixelSize` 3 (texel 0.060 m), a lamp from the back
left (yaw -38, pitch 52), per-splat dither, ink 1.

## Rules

- One verb: move the pointer. The first click drops a marble onto the blue start ring.
- The board tilts (up to 5 degrees, in half-degree steps; the knobs turn with it) towards where the
  pointer is, seen from the marble, and less as the marble picks up speed, like a hand on the knobs:
  lead the marble round the rails and past the holes into the goal under the flag. A small reticle
  marks the pointer on the board.
- The holes' rims slope in: roll too close and the marble is pulled in. A marble in a hole is gone
  ("PLOP!"); the next one hops out of the dish and drops onto the start ring.
- The goal: confetti, the flag bounces, +1. The layout sinks into the floor and a new one rises: the
  start and the goal swap sides, the rails move (one to five), and there is one more hole (three in the
  first round, up to nine). Each layout is checked solvable by the demo's path finder before use.
- Three marbles (one on the board, two in the dish; the HUD shows them top right). The last one lost
  ends the run: OUT OF MARBLES, the goals and the session's best; the next click starts a new run.
- Runs last 30 to 90 seconds.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the marble drops at once. The demo
player steers with the same control as a person (a virtual pointer), following a breadth-first path
from the goal round the rails and the holes, re-deciding 6 times a second with a little aim error;
now and then it hurries (aims further ahead with more error), and the holes' pull catches it. It
scores 1 to 7 goals a run (about 25 to 80 s) and restarts two seconds after OUT OF MARBLES. When demo is
switched off, a fresh run starts at once.

## What is where

```
art/palette.json, palette.png   WoodSpark with ramps wood, leaf, glass, steel, berry, pit, flame, spark; roles
art/assets.md                   the asset list, bones, layout
art/labyrinth/                  the hero's Codex briefs, sheets (v1: the right view wrong; v2 used) and records,
                                cut views (refs/)
models/labyrinth/               spec + gate record, p1_blockout.txt, p2_form.txt (the mesh gate's), p3_splat_fit.txt
                                (the bake's), p4_parts.txt (frame.glb, floor.glb, knob.glb), labyrinth.bake.json,
                                gate shots, the GLBs
models/env/                     make_env.py writes table, dish, plant, books, cup, marble, wall, hole, goal, start,
                                spark .txt (hedra command files); their GLBs
lookdev/                        the turntable bench (no RML): labyrinth.bin
scene.bake.json                 the composition: world, game bones (floor, knobF, knobR, wall0-9, hole0-9, goal,
                                start, marble, life0-2, spark0-7), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        labyrinth (framed), labyrinth@scene (at the scene's texel), scene (3 demo frames
                                + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 37 of 63. Splats: 68 556 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the labyrinth (p1-p4), lookdev, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh; the gate's p2 is the mesh gate, so rebuild p1 + p2 first):

```sh
(cd models/labyrinth && rm -f labyrinth.rmdl && hedra model --text labyrinth.rmdl run p1_blockout.txt && hedra model --text labyrinth.rmdl run p2_form.txt)
python3 $K/scripts/golden.py views --hedra models/labyrinth/labyrinth.rmdl -o /tmp/lab_p2 --views front,right,back,top --elevation 3
python3 $K/scripts/golden.py gate --refs art/labyrinth/refs --shots /tmp/lab_p2 --min-iou 0.75
./build.sh                                            # back to p3 (the splat fit) for the bake
python3 $K/scripts/golden.py views --rive lookdev --blob labyrinth -o /tmp/lab_alb --look albedo --views front,right,back,top --elevation 3
python3 $K/scripts/golden.py gate --refs art/labyrinth/refs --shots /tmp/lab_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=-38 --arg sunPitch=52 --arg keyLight=0.42 --arg highlight=0.85)
python3 $K/scripts/golden.py views --rive lookdev --blob labyrinth -o /tmp/lab --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/lab --goldens goldens/labyrinth
python3 $K/scripts/golden.py views --rive lookdev --blob labyrinth -o /tmp/lab_s --texel 0.0603 --size 400 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/lab_s --goldens goldens/labyrinth@scene
for n in 50 368 2208; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/demo_*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

(The splat gate's right view fails its aspect by design: a waiver in `models/labyrinth/labyrinth.spec.md`.)

Play it headless: `rive scene --screenshot=$PWD/p.png --advance=5 --pointer=click@155,100 --advance=40
--pointer=move@330,92 --advance=60 --pointer=move@485,98 --advance=200` rolls the first marble along the
top into the goal (GOALS 1, round 2's layout); `--advance=5 --pointer=click@155,100 --advance=40
--pointer=move@300,180 --advance=1400` steers each marble into the middle hole: OUT OF MARBLES. The
hand-over from demo to a player, with `--commands`: `data demo=true`, `advance 240`, `data demo=false`,
`advance 60` (a fresh run, the marble dropping).

## Notes from building it

- The first sheet drew the RIGHT panel as a copy of the front (the long side, a knob in its middle);
  v2 restated that panel first ("the SHORT side ... NOT a copy of the front view") and was right.
- The flat box passed the mesh gate but came out 10 to 24 % too tall in splats (discs reach a radius
  past every flat top and bottom): `p3_splat_fit.txt` squashes it to 0.88 of its height for the bake
  only, as the skill's modeling.md describes.
- The first floor alternated pale and honey planks: busy, and the rails (honey too) vanished into
  it. The floor is honey with thin orange seams now, the rails mauve with orange tops.
- The board tilts as a real labyrinth's does: the frame stays still and only the floor (with the
  rails, holes, goal, start ring and marble on it, all placed through `api.transform` of the floor
  bone) turns. 5 degrees is enough to read with the seams and the knobs turning, small enough that the
  floor's edge never clears the frame's walls. A rail turned 90 degrees gets the floor's tilt as
  (pitch, roll) = (-roll, pitch) in its own frame (`place` turns yaw first).
- The marble's roll is integrated as a rotation matrix (axis up x motion, angle distance / r) and
  turned back into `place`'s yaw, pitch, roll each frame.
- Layout generation once ran 34 unsolvable tries in one frame (6 ms each, the path finder's field)
  and tripped the 200 ms script limit at round 7: now at most 8 tries, then holes are dropped one by
  one until the field reaches the start.
- The Codex sheets were not reviewed by a person yet (`art/labyrinth/sheet.v2.png.json`, `reviewed:
  false`).
