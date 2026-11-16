# Game: Archery Range (Island Joy 16)

**How to play: hold to draw the bow, release to shoot where the pointer is; lead the moving targets and
lean into the wind.**

**Touch:** press on the spot to aim at, hold to draw (slide to correct the aim), lift to shoot.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Island Joy 16](https://lospec.com/palette-list/island-joy-16) by
Kerrie Lake (it loaded from Lospec: the spare, Cold Light, was not needed), nine ramps (grass, foliage,
wood, straw, crimson, teal, stone, skin, cloth); a teal-to-mint summer sky over the hedge.

The rules: straw targets on sleds slide across three lanes of a meadow (two at a time on a lane, faster
as the run goes on). The pointer aims at the height of the targets' centres; hold to draw (the meter
under the archer fills in 0.65 s), release to loose. A full draw flies flat and fast to the aim; a short
one is slow and drops short; one held past 1.5 s trembles (the meter flashes red, the aim wanders). Each
arrow has its own wind, shown by the flag and `WIND >>`: it pushes the arrow sideways in flight. Rings
score 10 / 8 / 6 / 4 / 2, times the lane (near x1, middle x2, far x3). Ten arrows a run, then the score;
click to shoot again. Best score for the session. Demo mode (`--arg demo=true`) shoots by itself from the
first frame: it leads the targets, half-corrects the wind, misses now and then (a short draw, an
overheld one, a bad lead) and starts a new quiver 2 s after the last arrow.

Sound (`sfx.as`, silent in demo mode): the string coming back, a tick at full draw and a nervous tick
while an overheld draw trembles; the release is a plucked twang (higher with the draw) and a whoosh. A
hit is a straw thump (lighter on a farther lane) and its ring's chime on a pentatonic scale that climbs
with each arrow in a row (a bell and a coin on a bullseye); a miss a dull thunk in the turf; the next
arrow clicks onto the string. An empty quiver plays a fanfare for 7+ hits, a three-bell call for 4+, the
lose jingle below that (a higher last note on a new best).

```
art/palette.json, palette.png   Island Joy 16 with its ramps and roles (sky #11adc1 over #6df7c1, void #393457)
art/assets.md                   the asset list
art/target/                     the hero's Codex brief, sheet (v1), its record and log, cut views (refs/)
models/target/                  make_target.py (writes p1_blockout.txt, p2_form.txt), spec + gate record, bake
                                file (lookdev), gate shots, the GLB
models/env/                     make_env.py (writes every other command file and textures/meadow.png): ground,
                                track, bush, tree, haybale, flagpole, flag, archer, bow, arrow, chip; GLBs
lookdev/                        the turntable bench (no RML): target.bin
scene.bake.json                 the composition: static meadow, 28 game bones (pools), the play area bounds
scene/                          the Rive project: scene.rml (orthographic 10.5 m, yaw 0, pitch 30, sun -35 / 48),
                                game.as (all the game), the renderer files, splats.bin (63 400 splats)
goldens/                        target framed and at the scene's texel (0.079), scene frames (demo_NNN, frame_030)
shots_scene/                    the scene frames the goldens were snapped from
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                  # models from scratch, lookdev/target.bin, scene/splats.bin
rive scene --verify && rive scene           # play it; `rive scene --arg demo=true` watches the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/target/target.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/target/refs --shots /tmp/p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob target -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/target/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7
L="--arg sunYaw=-35 --arg sunPitch=48 --arg keyLight=0.4 --arg highlight=0.85"
python3 $K/scripts/golden.py views --rive lookdev --blob target -o /tmp/tg --real-sky ${=L}     # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/tg --goldens goldens/target
python3 $K/scripts/golden.py views --rive lookdev --blob target -o /tmp/tgs --texel 0.079 --size 160 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/tgs --goldens goldens/target@scene
for n in 60 420 660; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_420.png -p art/palette.json --pixel 3
```

Try it headless: `rive scene --screenshot=$PWD/shot.png --advance=30 --pointer=down@330,150 --advance=45
--pointer=up@330,150 --advance=30` (artboard coordinates, 60 fps frames).

Notes from building it:

- `pixelSize` 3 on a 640-wide artboard centres the art grid at a third of a pixel: with the first renderer
  the HUD, drawn from the frame's corner, sat on another grid (frame audit 96.6 % solid) and the game slid
  it over itself; the renderer now aligns the HUD with the art grid (100 %).
- The bow seen from behind is edge-on (a white string hid it): no string, canted 20 degrees, so its belly
  shows; the draw bends it (`placeScaled` along its depth, with the cant as its roll).
- The target's legs and runners first doubled in width as splats (a disc reaches a radius past its face):
  thinned in p2 and baked at 0.04 (spec).
- The demo first hit 10 of 10: its aim error grew until it lands about 8.
- The Codex sheet was not reviewed by a person yet (`art/target/sheet.v1.png.json`, `reviewed: false`).
