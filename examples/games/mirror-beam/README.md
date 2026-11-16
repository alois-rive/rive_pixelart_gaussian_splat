# Game: Mirror Beam (Sunset Red, 5 colours)

**How to play:** click a mirror to turn it a quarter turn; bounce the sunbeam through every crystal in
the temple court before the sun sets.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [Sunset Red](https://lospec.com/palette-list/sunset-red) by
Cabezinu, five colours of one hue (navy-black, plum, wine, crimson, red); it loaded from Lospec, so the
spare (`fantasy-24`) was not needed. A monochrome sunset: materials are told apart by value, the world
in the dark steps, everything the player plays with (mirrors, crystals, the beam) in the brightest red.
Orthographic, yaw 0, pitch 40, `orthoHeight` 8.6 m, `pixelSize` 3 (texel 0.063 m), the sun low in the
west-south-west (yaw -70), Bayer dither (`splatDither` false, `bandDither` 0.4), `shadeSteps` 1, ink 1.

## Rules

- One verb: click. A click on a mirror swings it a quarter turn (from `/` to `\` and back, seen from
  above). The beam leaves the glowing lens on the court's west side, reflects off every mirror it
  meets, passes through crystals (lighting them) and stops on broken pillars and on the walls.
- Light every crystal of the court at once (the diamonds under the daylight bar) to solve it: +100,
  +25 a crystal, +50 PERFECT when it took no more turns than the scramble did. The temple's sun emblem
  flashes, the pieces sink and a new court rises: more mirrors on the path (2, 3, 4, 5, then 6), more
  crystals (up to 4), decoy mirrors off the path and pillars.
- The sun is the clock: 40 s of daylight, shown by the bar and by the sun itself sinking towards the
  horizon, the light falling and the court darkening with it. Each solved court gives back 8 s (one
  less per court, at least 2), up to the full 40.
- When the sun sets, the beam dies: THE SUN HAS SET with the score and the session's best; the next
  click starts a new run in the same court (the sun comes back up). Runs last about 40 to 90 seconds.
- Every court is solvable by construction: `generate()` walks a random beam path from the west wall,
  puts K mirrors on its turns, one crystal after the last mirror (so every mirror matters) and the
  others along it, decoys and pillars off it, then turns at least half of the path's mirrors the wrong
  way (and re-rolls if the scramble happens to be solved).

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the run starts at once; the beam is on
from the first frame and the first turn comes at 0.4 s. The demo player follows the beam: it finds the
first mirror along the beam that is turned wrong, moves a small arrow to it (the hover ring marks it),
thinks 0.45 to 1 s (longer as courts grow, now and then a long look) and clicks; one click in five goes
to a wrong mirror, which it turns back later. It solves eight to ten courts and loses to the sunset at
about 65 s, then restarts two seconds later. When demo is switched off, a fresh run waits for the first
click on a mirror.

## What is where

```
art/palette.json, palette.png   Sunset Red with ramps sand, stone, bronze, glass, ember, glow, night; roles
art/assets.md                   the asset list, values per read, bones, layout
art/mirror/                     the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/mirror/                  spec + gate record, make_mirror.py -> p1_blockout.txt, p2_form.txt
                                (mirror_p2.glb, the gated form), p3_splat_fit.txt (mirror.glb, baked),
                                mirror.bake.json, gate shots
models/env/                     make_env.py writes court, temple, desert, palm, sun, crystal, stump, lens,
                                spark, ring, emblem .txt (hedra command files); their GLBs
lookdev/                        the turntable bench (no RML): mirror.bin
scene.bake.json                 the composition: world, game bones (sun, emblem, lens, mirror0-9,
                                crystal0-4, glow0-4, stump0-2, ring, spark0-11), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        mirror (framed), mirror@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 39 of 63. Splats: 60 541 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the mirror (p1, p2, p3), lookdev/mirror.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
(cd models/mirror && rm -f /tmp/mirror_p2.rmdl && hedra model --text /tmp/mirror_p2.rmdl run p1_blockout.txt \
  && hedra model --text /tmp/mirror_p2.rmdl run p2_form.txt)          # the p2 form, outside the build
python3 $K/scripts/golden.py views --hedra /tmp/mirror_p2.rmdl -o /tmp/mir_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/mirror/refs --shots /tmp/mir_p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob mirror -o /tmp/mir_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/mirror/refs --shots /tmp/mir_alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L=(--arg sunYaw=-70 --arg sunPitch=42 --arg keyLight=0.4 --arg highlight=0.85 --arg shadeSteps=1 --arg splatDither=0 --arg bandDither=0.4)
python3 $K/scripts/golden.py views --rive lookdev --blob mirror -o /tmp/mir --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/mir --goldens goldens/mirror
python3 $K/scripts/golden.py views --rive lookdev --blob mirror -o /tmp/mir_s --texel 0.0486 --size 100 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/mir_s --goldens goldens/mirror@scene
for n in 100 3000 3900; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

The scene goldens: `demo_100` (the first court solved, +175 PERFECT, the emblem lit), `demo_3000`
(court 7 at dusk, two crystals lit, the sun on the horizon), `demo_3900` (THE SUN HAS SET), and
`frame_030` (the first court and the hint, before the first click).

Play it headless: `rive scene --screenshot=$PWD/p.png --advance=5 --pointer=click@320,223 --advance=40`
turns the middle mirror of the first court and solves it (+175 PERFECT); with `--advance=2600` after
the click instead, the sun sets on court 2 (THE SUN HAS SET, SCORE 175); a further
`--pointer=click@100,300 --advance=60` starts a new run (score 0, best 175). The hand-over from demo to
a player: `rive scene --commands=hand.txt` with `data demo=true`, `advance 200`, `data demo=false`,
`advance 30` shows a fresh court waiting for its first click, best reset.

## Notes from building it

- The beam is not geometry: `trace()` follows it cell by cell and `hud()` draws it with `api.line` from
  points projected at the mirrors' centre height (an E core, a D glow that stops five pixels short of
  each mirror so the mirror's face still shows, bright dashes running along it, a splash where it
  ends). At this pitch a beam at mirror height always passes above the tops of the next row's mirrors,
  so the HUD line never wrongly crosses in front of a piece.
- A first framing (pitch 54, a 7 x 5 court, `orthoHeight` 9.4) left no sky for the sun and mirrors
  ten art pixels tall whose lit faces shaded into the floor; the court lost a row, the camera came
  down to pitch 40 and in, the mirrors grew (scale 1.3) and their faces went unlit.
- The sand plane under the court sat 3 cm below the floor and its big discs won the depth test through
  the tiles (a B speckle over the whole floor). The sand grid's lines now meet at the court's border
  and the faces inside are deleted; its `select ... where` needed `apply --location` first (object-local
  positions: the first hole opened behind the court instead).
- A monochrome palette leaves no hue to separate things, so each read got a value: the world B/C, the
  pieces D/E. The sun is the clock: `sunPitch` falls from 42 to 6 degrees with the daylight, so the
  court's tiles sink from C to B and the shadows stretch as time runs out.
- The sun is placed with `api.pickPlane` at a HUD position on the plane z = -12.5, behind the sand's
  far edge: it sinks below the horizon by itself.
- The Codex sheet was not reviewed by a person yet (`art/mirror/sheet.v1.png.json`, `reviewed: false`).
