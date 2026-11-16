# Game: Crate Keeper (Fairydust 8, 8 colours)

**How to play: tap or click toward a tile to step Tansy one tile that way; walk into a crate to push it;
cover every pad to clear the bench. UNDO steps back, RESET starts the bench over.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra
0.1.0, codex-cli. Palette: [Fairydust 8](https://lospec.com/palette-list/fairydust-8) by Yousurname, eight
pastel colours in 12 ramps; it loaded from Lospec, so the spare (`rose-bush`) was not needed. A night
greenhouse: seven small potting benches float in the dusk-purple dark, each a slate floor (a violet and
teal checker) walled by mint hedges on violet planter boxes, with teal bushes, pink flowers and pots on the
walls. Tansy, the keeper (cream straw hat, teal overalls), tidies pink seed crates onto white pads; a crate
on a pad lights up like a lantern. Orthographic, a high isometric view (yaw 45, pitch 42), `orthoHeight`
8.6 m, `pixelSize` 3 (texel 0.063 m), a high sun from the camera's left (yaw 30, pitch 55), per-splat
dither, ink 1, a flat void.

## Rules

- A press steps the keeper ONE tile toward the pointer: the dominant axis from her to the pressed floor
  point (on screen, the four diagonals; the boundaries are the horizontal and vertical lines through her).
  Holding keeps stepping (first repeat after 0.32 s, then every 0.2 s); dragging while held turns her.
  A white arrow on the next tile shows the step at the press (on a crate's lid when it is a push); a small
  pink arrow means blocked (she bumps).
- Walking into a crate pushes it if the cell behind it is floor and free. A crate on a pad glows (its
  unlit twin is swapped in, with a pop, a sparkle and a bell). All pads covered = the bench is clear.
- UNDO (bottom left) takes back one move at a time, all the way to the bench's start; RESET (bottom right)
  puts the bench back as it began. The moves counter counts the moves made (an undo takes one off); it
  turns pink above the bench's par.
- A run is the seven benches. Each clear shows the moves against the par ("PERFECT!" at or under it);
  the camera then glides to the next bench while Tansy hops across and the next crates drop in. After the
  seventh, "GREENHOUSE TIDY!" shows the total against the total par (279), each bench's moves (mint where
  it met its par) and the session's best (fewest); the next tap starts again on bench 1.

| Bench | Name | Size (cells) | Crates | Par (optimal moves) | Pushes in the optimal solution |
|---|---|---|---|---|---|
| 1 | SEED SHELF | 6 x 6 | 1 | 8 | 4 |
| 2 | FERN BAY | 7 x 6 | 2 | 18 | 5 |
| 3 | POTTING NOOK | 7 x 6 | 2 | 30 | 8 |
| 4 | TULIP ROW | 8 x 6 | 3 | 37 | 15 |
| 5 | MOSS CORNER | 8 x 7 | 3 | 46 | 18 |
| 6 | ORCHID LOFT | 8 x 7 | 3 | 64 | 17 |
| 7 | MOON GARDEN | 8 x 7 | 4 | 76 | 25 |

Pars are the fewest keeper steps (pushes count as steps), found by a breadth-first search over (keeper
cell, crate cells) in `models/env/make_env.py`, which asserts every bench is solvable and writes the pars
and one optimal solution per bench into `scene/game.as`. The benches were drafted by hand, refined with
a small hill-climb on the solver's push count (scratch, not kept) and cleaned by hand.

**Touch.** The game needs no hover: on a phone the pointer only exists while a finger is down, so the
arrow appears at the press and follows a drag, a lift stops the stepping, and nothing uses pointer exit.
A tap anywhere works (the direction is measured from the keeper), the buttons are 15 art pixels tall
(44 and 50 wide) with a 3-pixel margin, and the end panel takes a tap anywhere.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): Tansy plays each bench's optimal solution
like a person: 0.2 to 0.3 s a step, a pause to think (0.3 to 0.8 s) before some pushes, now and then a
step aside and back (at most two a bench), and on benches 2 to 7 sometimes a wrong move (a push or a
step) taken back with UNDO (the button flashes; at most one a bench). The arrow shows each step. It
starts mid-bench (the first two steps already walked), so its first move, at 0.12 s, is a push; it runs the
seven benches in about 115 s (about 295 moves against the par of 279), shows the summary and starts again
from bench 1 about 2.6 s later. Turning demo off starts a fresh run on bench 1 at once. Its detours and
undos are drawn from `api.rand()`, so the demo is the same every time.

**Sound** (`sfx.as` presets, silent in demo): soft footsteps (a quiet tick, alternating pitch between
the feet); a crate scrape when one moves (a low whoosh and a tick, each crate its own pitch, panned where
it goes); a dull bump into a wall or a stuck crate; a bell when a crate lands on a pad, the notes of a
little C major chord pad by pad (C, E, G, C), and a soft lower note when one is pushed off; an undo
whoosh; a whoosh and a pop for RESET; a click for the buttons; a bench clear plays the win chime and a
rising C-E-G arpeggio ending on a bell; the hop between benches whooshes and lands with a thud, and each
dropping crate thuds; the end of the run plays a power-up and a seven-note bell melody. No sound is
decided with `api.rand()`.

## What is where

```
art/palette.json, palette.png   Fairydust 8 with ramps tile, wood, planter, leaf, cloth, skin, straw, glow,
                                bloom, mark, dusk, slate; roles (void, fog, sky: all dark)
art/assets.md                   the asset list, the value plan, bones (24 of 63), splats
art/keeper/                     the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/keeper/                  spec + gate record (waiver: top aspect), p1_blockout.txt, p2_form.txt,
                                p3_splat_fit.txt, keeper.bake.json, gate shots, keeper.glb
models/crate/crate.txt          the seed crate (hedra), crate.glb
models/env/make_env.py          the ROOMS list -> BFS pars and solutions, room0..6.txt (hedra), the room
                                table in scene/game.as; marker.txt, puff.txt; their GLBs
lookdev/                        the turntable bench (no RML): keeper.bin
scene.bake.json                 the composition: seven benches (static), the game bones (keeper, crateA/B0-3,
                                glowA/B0-3, markW, markP, puff0-4), material -> ramp, "bounds"
scene/                          the Rive project: scene.rml (camera, light, Sample.demo), game.as (the whole
                                game), the renderer files, splats.bin
goldens/                        keeper (framed), keeper@scene, scene (frame_030 + demo_045, demo_1300, demo_4500)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 24 of 63 (no baked tracks). Splats: 58 172 in the scene blob (1.8 MB).

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # make_env (pars, rooms, room table), every model, both blobs
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
python3 models/env/make_env.py --check                # the solver alone: pars and solutions
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/keeper/keeper.rmdl -o /tmp/k_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/keeper/refs --shots /tmp/k_p2 --min-iou 0.75     # top: waiver in the spec
python3 $K/scripts/golden.py views --rive lookdev --blob keeper -o /tmp/k_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/keeper/refs --shots /tmp/k_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=30 --arg sunPitch=55 --arg keyLight=0.42 --arg highlight=0.85 --arg shadeSteps=1 --arg lightSteps=1 --arg edgeDepth=0.5)
python3 $K/scripts/golden.py views --rive lookdev --blob keeper -o /tmp/k --real-sky --views front,right,back,top,iso $L
python3 $K/scripts/golden.py check --shots /tmp/k --goldens goldens/keeper
python3 $K/scripts/golden.py views --rive lookdev --blob keeper -o /tmp/k_s --texel 0.0486 --size 120 --real-sky --views front,right,back,top,iso $L
python3 $K/scripts/golden.py check --shots /tmp/k_s --goldens goldens/keeper@scene
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
for n in 45 1300 4500; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Play it headless: bench 1's solution (RRuuRUll) with a bump first and an UNDO, clicked at the tiles next
to the keeper, then the jingle and the glide (sound on):

```sh
rive scene --render-audio=$PWD/play.wav --screenshot=$PWD/p.png --advance=5 --pointer=click@184,188 --advance=14 \
  --pointer=click@251,233 --advance=14 --pointer=click@75,363 --advance=14 --pointer=click@251,233 --advance=14 \
  --pointer=click@285,256 --advance=14 --pointer=click@318,233 --advance=14 --pointer=click@352,211 --advance=14 \
  --pointer=click@385,233 --advance=14 --pointer=click@419,211 --advance=14 --pointer=click@385,188 --advance=14 \
  --pointer=click@352,166 --advance=200
```

ends on bench 2 ("ROOM 2/7", MOVES 0) after "ROOM CLEAR! 8 MOVES - PAR 8". With touch instead:
`--touch=down@251,233 --advance=40 --touch=up@251,233` holds a step to the right (three steps, then a bump).
The hand-over from demo to a player, with `--commands`: `data demo=true`, `advance 240`, `data demo=false`,
`advance 30` (a fresh run, bench 1, MOVES 0).

## Notes from building it

- Tested with a closed-loop Python player (a temporary `console.log` of the state and the screen points of
  the four tiles next to the keeper, removed after): it solved the live state with its own BFS and pressed
  the tiles, once with mouse clicks and once with touch only (`touch down@` / `up@`, no moves): both runs
  cleared all seven benches at par (279), and its checks passed: UNDO takes one move back (bench 2), RESET
  restores the bench (bench 3), four steps and four undos return to the start (bench 4), hovering does
  nothing, a held press repeats, a drag turns the held direction, a lift stops, a tap on the end panel
  starts over on bench 1, and switching demo off starts a fresh run.
- The first floor was a cream and pink (then cream and white) checker under teal-topped walls: the teal
  pads vanished into the walls, then the white arrow into the white tiles and the keeper's cream hat (the
  most of her the high camera sees) into the cream tiles. The floor is now a mid-dark slate (violet and
  teal), and everything the player tracks is lighter or warmer than it.
- With the sun at yaw 10 the walls' +X sides shaded to the void's purple and the walls lost their volume;
  at yaw 30 both seen sides keep their painted violet under the mint tops.
- The benches are one static bake, side by side 10 m apart; the camera glides between them (an eased
  translation, so it stays whole-pixel), and the neighbours peek in at the frame's corners. Walls with
  floor behind them are low (0.3 m) so the high camera sees over them; faces turned away from the camera
  are deleted before the bake (about a third of the wall splats).
- Two crate sets alternate between benches, so a cleared bench keeps its glowing crates as the camera
  leaves it. When a run restarts from bench 7, the set that held bench 6's crates is reused for bench 1,
  so bench 6 empties as the camera glides back past it.
- The bake warns that the glowing twin's soil is far from its ramp: on purpose (the dark soil is mapped to
  the glow ramp, so the lit crate glows mint inside).
- The Codex sheet was not reviewed by a person yet (`art/keeper/sheet.v1.png.json`, `reviewed: false`).
