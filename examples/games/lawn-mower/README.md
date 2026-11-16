# Game: Lawn Mower (Endesga 16)

**How to play:** click to start, then steer the ride-on mower with the pointer (it drives towards it)
over every patch of long grass before the clock runs out; bumping a garden gnome or a flower bed costs
time.

**Touch:** tap to start, then drag: the mower drives to a point a few pixels above your finger and keeps
going there when you lift.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Endesga 16](https://lospec.com/palette-list/endesga-16) by ENDESGA,
16 colours in eight ramps (lawn, rough, wood, red, straw, stone, blue, skin); it loaded from Lospec, so
the spare (`sheltzy32`) was not needed. A back garden on a sunny afternoon: a shaggy dark lawn inside a
sandy path, two raised flower beds on it, soil borders full of flowers and round bushes, a white picket
fence, a red-roofed shed, a birdbath, garden gnomes, and a red ride-on mower driven by a gardener in a
straw hat. As the mower cuts, the bright two-tone stripes of a mowed lawn come through. Orbit camera at
yaw 0 (the lawn's grid square to the art grid), pitch 55, orthographic 7.6 m (texel 0.056 m), `pixelSize`
3, a high sun from the front left (yaw -38, pitch 52), per-splat dither, ink 1.

## Rules

- One verb: steer with the pointer. The first click starts the clock. The mower drives towards the
  pointer like a small vehicle: it turns at most 250 degrees a second, slows while turning hard, tops out
  at 2.7 m/s and stops on the spot under the pointer.
- The lawn is 8 x 6 tiles; 44 carry long grass (the beds cover four). A tile is cut when the mower's
  deck passes within 0.58 m of its middle: +10. Mowing down a column's tiles shows its stripe.
- Gnomes stand on grid corners, so a tile beside one can only be cut off-centre: steer close but not
  into it. A gnome bump costs 3 s, a flower-bed bump 2 s; the mower is knocked back, the gnome topples
  and rocks back up, the bed throws petals. For 2 s after a bump, touching again only slides.
- The whole lawn: LAWN CLEAR! +100 and 2 points per second left, +16 s on the clock. The grass grows
  back in a wave, the gnomes hop to new corners and one more joins (2, 3, then 4).
- When the clock reaches 0: TIME'S UP with the score and the session's best; the next click grows the
  lawn back and starts a new run in the same garden. A run lasts 40 to 70 seconds for a fair player.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the mower is cutting the bottom row within
the first second. The demo driver re-decides 2 to 4 times a second: the nearest long grass, preferring
what is ahead and in the same row, with a small aim error and now and then a sloppier pick; it steers
round beds and gnomes ahead of it and cuts tiles beside a gnome from a clear spot. It drives at 85 % of
full speed and still clips a gnome or a bed now and then; a stall of 3 s makes it try other grass. Its
runs last 45 to 70 s and clear one or two lawns. It restarts two seconds after TIME'S UP; when demo is
switched off, a fresh run waits for the first click.

Sound (procedural, `api.sound`; silent in demo): a little two-stroke and a lawn that plays a scale. A start
jingle; the engine putts (low thuds, 3 a second idling to 7 at full speed, higher as it goes); each cut tile
snips and plucks a note that climbs two octaves of a major scale as the lawn fills; a gnome bump is a crunch and
a ceramic clink, a bed bump a crunch and a pop, both with a falling zap for the seconds lost; the clock ticks
its last eight seconds, higher as they run out; a clear lawn rings a fanfare and the gnomes hop; TIME'S UP
a falling tune.

How coverage is shown with splats: the mowed lawn (one stripe per column) is baked static under the
grass; each tile of long grass is its own game bone (44 of 63). Cutting squashes a tile flat in stepped
frames and hides it; a cleared lawn grows every tile back with an overshoot. The tiles lean in a stepped
breeze, the mower judders at 12 fps, pitches with speed and throws clippings from the chute on its right.

## What is where

```
art/palette.json, palette.png   Endesga 16 with ramps lawn, rough, wood, red, straw, stone, blue, skin; roles
art/assets.md                   the asset list, bones, layout
art/mower/                      the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/mower/                   spec + gate record, make_mower.py -> p1_blockout.txt, p2_form.txt, mower.glb,
                                mower.bake.json, gate shots
models/env/                     make_env.py writes ground, garden, tuft, gnome, clip, petal .txt (hedra command
                                files); their GLBs
lookdev/                        the turntable bench (no RML): mower.bin
scene.bake.json                 the composition: ground and garden (static), game bones (tile0-43, mower,
                                gnome0-3 at 1.4 x, clip0-7, petal0-3), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        mower (framed), mower@scene (at the scene's texel), scene (demo_120: the first row,
                                demo_540: stripes coming through, demo_960: most of a lawn, frame_030: the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 61 of 63. Splats: 68 456 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the mower (p1, p2), lookdev/mower.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/mower/mower.rmdl -o /tmp/mw_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/mower/refs --shots /tmp/mw_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob mower -o /tmp/mw_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/mower/refs --shots /tmp/mw_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=-38 --arg sunPitch=52 --arg keyLight=0.42 --arg highlight=0.9 --arg edgeDepth=0.35)
python3 $K/scripts/golden.py views --rive lookdev --blob mower -o /tmp/mw --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/mw --goldens goldens/mower
python3 $K/scripts/golden.py views --rive lookdev --blob mower -o /tmp/mw_s --texel 0.056 --size 100 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/mw_s --goldens goldens/mower@scene
for n in 120 540 960; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Play it headless. A point (x, z) on the ground is at about (320 + 52.6 x, 200 + 43.1 (z + 0.2)) on the
640 x 400 artboard: the lawn's tile rows are at y 117, 154, 190, 227, 264, 300 and its columns at x 164
to 476, 45 px apart. Mow the bottom row and the next, then wait for TIME'S UP and click again:

```sh
rive scene --screenshot=$PWD/p.png --advance=3 --pointer=click@150,300 --advance=30 --pointer=move@500,300 \
  --advance=150 --pointer=move@500,264 --advance=30 --pointer=move@150,264 --advance=150
rive scene --screenshot=$PWD/p.png --advance=3 --pointer=click@150,300 --advance=2450 --pointer=click@300,200 --advance=30
```

The demo-to-player hand-over: `printf 'data demo=true\nadvance 400\ndata demo=false\nadvance 30\nscreenshot
/tmp/h.png\nquit\n' | rive scene --commands` shows the hint over a lawn grown back.

## Notes from building it

- 63 bones decide the grid: 8 x 6 tiles of 0.85 m with the beds over four of them leaves 44 tile bones,
  the mower, 4 gnomes, 8 clippings and 4 petals: 61. A finer grid would need a second blob or tiles
  that share bones.
- `rough` repeats its darkest green, so long grass stays dark on its lit faces and the mowed stripes
  (`lawn`: light and mid green) stand out; the tile's turf reaches its step with the bake's `"step": 1`.
- The first demo drove straight at its target and ground against a bed (each bump -2 s: a run lasted
  12 s). Bumps now have a 2 s guard, the demo steers round what is ahead, and a gnome is only ever placed
  where every gap round it (to a bed, to another gnome) is wider than the mower: an earlier layout walled
  a tile in between a bed and a gnome and the demo circled it until the clock ran out.
- The first demo was too good (a 90 s run over three lawns): it now drives at 85 % and the lawn bonus is
  16 s.
- `select face where` reads object-local axes: the wheels keep their `--rotation`, so their side caps
  are `abs(normal.z) > 0.9`, not `normal.x`.
- The Codex sheet was not reviewed by a person yet (`art/mower/sheet.v1.png.json`, `reviewed: false`).
