# Game: Sky Stacker (NA16)

**How to play: click to drop the sliding storey; what overhangs the one below is sliced off.**

A pagoda grows on a mountain top above a sea of sunset clouds. Each storey slides across the top of the
tower (alternately along the two axes, a little faster each time); a click drops it. The part hanging
over the storey below is cut off and tumbles away, and the next storey is only as big as what stayed. A
drop within 7 cm is PERFECT: no cut, 2 points instead of 1, and from the third perfect in a row the storey
grows back a little. Miss the tower entirely and the storey falls: the camera backs off to show the
tower, a gold spire drops on its top, and the game-over line gives floors, score and best; the next click
clears the stack and starts again on the same peak. Demo mode aims each drop with a small error (wider
as the tower rises) and now and then a clumsy one, so a run ends after 10 to 25 floors; it restarts two
seconds after a miss.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra
0.1.0, codex-cli. Palette: [NA16](https://lospec.com/palette-list/na16) by Nauris (loaded from Lospec; the
spare `pear36` was not needed), 7 ramps. Orthographic three-quarter view (yaw 45, pitch 28) that climbs
with the tower, pixelSize 3; an evening sun from the camera's right; peach fog over the far clouds; a
lavender sky over a dithered peach horizon.

```
art/palette.json, palette.png   NA16 with ramps lacquer, roof, gold, stone, pine, cloud, earth
art/assets.md                   the asset list, layout, bones, splat budget
art/storey/                     the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/storey/                  spec + gate record, p1_blockout.txt, p2_form.txt, p3_splat_fit.txt, bake file, gate shots, GLB
models/env/                     peak, plinth, pine, cloud, spire: command files and GLBs
lookdev/                        the turntable bench (no RML): storey.bin
scene.bake.json                 the composition: game bones (floor0-17, chunk0-3, spire, cloud0-5), bounds
scene/                          the Rive project: scene.rml (camera, light, fog, sky), game.as (the whole game), renderer files
goldens/                        storey framed and at the scene's density; scene/: demo_090, demo_150, demo_480, frame_030
shots_scene/                    the scene frames the goldens were snapped from
build.sh                        rebuilds every model and blob from the command files
```

What moves (29 game bones of 63, all written by `game.as`): up to 18 storeys (the lowest is recycled to
the top once the tower is taller than the view), each dropping from a hover with a squash; offcuts
falling and tumbling about their middles; six clouds drifting behind the tower; the spire; the camera
(it follows the top with a spring and zooms out at the end).

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models, lookdev/storey.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary
rive scene                                   # play: click to drop
rive scene --arg demo=true                   # the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/storey/storey.rmdl -o /tmp/ss_p2 --views front,right,back,top   # after p2 only (build.sh runs p3 too)
python3 $K/scripts/golden.py gate --refs art/storey/refs --shots /tmp/ss_p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob storey -o /tmp/ss_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/storey/refs --shots /tmp/ss_alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunYaw=60 --arg sunPitch=45 --arg keyLight=0.35 --arg highlight=0.85 --arg shadeSteps=1.3"
python3 $K/scripts/golden.py views --rive lookdev --blob storey -o /tmp/ss_f --real-sky --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/ss_f --goldens goldens/storey
python3 $K/scripts/golden.py views --rive lookdev --blob storey -o /tmp/ss_fs --real-sky --texel 0.0625 --size 160 --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/ss_fs --goldens goldens/storey@scene
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
for n in 90 150 480; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Notes from building it:

- The first bake held 180 000 splats (18 storeys of 3 400, big clouds): the storey's hidden faces went
  (1 670 splats each), its gold bakes at 0.07 and the sea of clouds at 0.17: 87 500.
- A low sun put every lacquer wall in its eave's shadow and the tower read as teal stripes; the sun moved
  to the camera's right (yaw 60, pitch 45, key 0.35).
- Pines on the camera's side of the plateau hid the ground storey: removed.
- The first demo landed PERFECT almost every time; its aim error grew (0.11 m + 0.012 m a floor).
- The Codex sheet was not reviewed by a person yet (`art/storey/sheet.v1.png.json`, `reviewed: false`).
