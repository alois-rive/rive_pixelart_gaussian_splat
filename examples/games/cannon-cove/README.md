# Game: Cannon Cove (SLSO8)

**How to play: hold to charge the cannon, release to fire; lead the ships so the ball lands on a
deck. Ten shots.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [SLSO8](https://lospec.com/palette-list/slso8) by Luis Miguel
Maldonado, eight colours from navy to cream, as eight ramps that share them (sea, rock, sand, wood,
sail, iron, glow, palm). A cove at sunset: the sun half set behind the far dunes, a path of glints
on the water, palms as navy silhouettes, sails and sand lit orange by a low sun from the right.
Orthographic, `pixelSize` 2 (320 x 200 art pixels), per-splat dither, ink 1.

The game (all in `scene/game.as`):

- Press and hold anywhere: the barrel rises and trembles, a gauge fills beside it and an aim ring
  slides out over the water to where the ball will land. The charge swings back down past full.
- Release: the cannon kicks back (squash along the barrel), a flash and three smoke puffs, and the
  ball flies its arc to the ring. Sloops cross the cove on three lanes (near, middle, far: 1, 2 and
  3 points; the far ones are smaller and the ball takes longer to get there), so time the release
  to lead them. A hit pops the ship, throws planks and sinks it bow-up; a miss is a splash.
- Ten shots (the balls under the score). Then GAME OVER with points, hits and a rank (deckhand,
  gunner, captain, admiral); the next click starts a new run in the same cove. Best score kept for
  the session (the demo keeps its own).
- The first press starts a run (the hint shows until the first shot). Ships sail from the first
  frame.
- Demo (`--arg demo=true`, or the `Sample` view model's `demo`): plays at once, waits for a ship whose
  crossing lines up with charge time plus flight time, prefers the far lanes, charges to the lane
  with a small error and now and then a clear miss (never on its first two shots, so the reel shows a
  hit within two seconds); restarts two seconds after a game over. Switching demo off starts a fresh
  run. Typical demo run: 5-7 hits, 12-16 points.

```
art/palette.json, palette.png   SLSO8 with its ramps and roles (sky #8d697a over #ffaa5e, void #0d2b45)
art/assets.md                   the asset list (sizes, ramps, bones, motion)
art/cannon/                     the hero's Codex brief, sheet (v1), record, log, cut views (refs/)
models/cannon/                  spec + gate record, p1_blockout.txt, p2_form.txt, bake file, gate shots,
                                cannon.glb (gates), carriage.glb + barrel.glb (the scene)
models/env/                     make_env.py writes water, shore, headland, ledge, sun, ship, ball, marker,
                                splash, smoke, flash, plank (.txt command files) -> .glb
lookdev/                        the turntable bench (no RML): cannon.bin
scene.bake.json                 the composition: 23 game bones (barrel, ship0-3, ball, marker, flash,
                                splash0-2, smoke0-3, plank0-7), a play-area "bounds", 112 945 splats
scene/                          the Rive project: scene.rml (camera, light), game.as (the game), renderer
goldens/                        cannon framed and @scene; scene/: demo_050, demo_110, demo_380, frame_030
shots_scene/                    the latest scene frames (the check renders into here)
build.sh                        rebuilds every model and both blobs from the command files
```

Camera: orbit yaw 20, pitch 22, `orthoHeight` 11.5, target (-1.21309, 2.50033, -3). The target sits
exactly on the art grid (target · right = -2 texels, target · up = 62 texels, texel = 11.5 / 202)
so the renderer's snap offset is zero and the HUD lands on the same pixel grid as the scene (any
other target puts the HUD one screen pixel off the art grid). Re-solve it if the camera changes.

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models from scratch, lookdev/cannon.bin, scene/splats.bin
rive scene --verify && rive scene            # play: hold and release anywhere
rive scene --arg demo=true                   # watch the demo
```

Check (gates, goldens, frame audit, a played run):

```sh
python3 $K/scripts/golden.py views --hedra models/cannon/cannon.rmdl -o /tmp/cc_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/cannon/refs --shots /tmp/cc_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob cannon -o /tmp/cc_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/cannon/refs --shots /tmp/cc_alb -p art/palette.json --min-iou 0.7   # back aspect: waiver in the spec
python3 $K/scripts/golden.py views --rive lookdev --blob cannon -o /tmp/cc_f --real-sky --arg sunYaw=70 --arg sunPitch=32
python3 $K/scripts/golden.py check --shots /tmp/cc_f --goldens goldens/cannon
python3 $K/scripts/golden.py views --rive lookdev --blob cannon -o /tmp/cc_s --texel 0.0316 --size 160 --real-sky --arg sunYaw=70 --arg sunPitch=32
python3 $K/scripts/golden.py check --shots /tmp/cc_s --goldens goldens/cannon@scene
for n in 050 110 380; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$((10#$n)) --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_110.png -p art/palette.json --pixel 2
rive inspect scene --summary
# a played run: ten holds of different lengths, then the game-over line and a restart click
A=(--advance=2); for h in 20 40 55 30 45 25 50 35 40 60; do A+=(--pointer=down@320,200 --advance=$h --pointer=up@320,200 --advance=100); done
rive scene --screenshot=$PWD/over.png "${A[@]}" --advance=120
```

Notes from building it:

- From straight behind, a raised barrel points along the view and reads as a lump; the camera turns
  20 degrees so the barrel shows its length, and the barrel is painted one ramp step lighter in the
  scene (`"step": 1` in `scene.bake.json`) than on the sheet so it stands out from the navy water.
- The barrel needs pitch and a squash along its own axis at once; `api.placeScaled` only turns about
  Y, so `game.as` has its own `pose()` that writes the bone matrix (any yaw / pitch / roll and a
  per-axis scale), as `api.place` does.
- `--pointer` events before the first `--advance` reach the scene before the game has started
  (`start()` runs on the first frame) and are dropped: tests begin with `--advance=2`.
- The Codex sheet was not reviewed by a person yet (`art/cannon/sheet.v1.png.json`, `reviewed: false`).
