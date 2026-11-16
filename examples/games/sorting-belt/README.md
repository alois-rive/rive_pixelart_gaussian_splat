# Game: Sorting Belt (Paper 8)

**How to play:** press on a parcel riding the belt, drag towards the chute whose sign has the
parcel's colour, and let go: the parcel is flicked into it.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Paper 8](https://lospec.com/palette-list/paper-8) by Frosty Rabbid,
eight colours (navy, plum, brick, tan, cream, pale green, green, teal) in eight ramps; it loaded from
Lospec, so the spare (`urbex-16`) was not needed. A warm afternoon in an old post office's sorting
room: plank floor, striped wallpaper over a teal wainscot, a window, pigeonholes and a clock on the
back wall, three wooden chutes with enamel signs, a conveyor belt with a hanging intake hopper, mail
sacks and a stamp desk. Orthographic, yaw 0, pitch 40, `orthoHeight` 8 m, `pixelSize` 3 (texel
0.0588 m), sun from the window's side (yaw -35, pitch 55), per-splat dither, ink 1, flat sky (never
seen).

## Rules

- One verb: drag and release. Press on a parcel (it lifts and wobbles but keeps riding), drag towards a
  chute and let go. Only the direction counts: a dotted line shows the drag and brackets blink round
  the sign the parcel would go into. A short tap does nothing; a flick along the belt drops the parcel
  back onto it.
- Parcels come in three colours (red, green, cream) and drop out of the hopper on the left; the belt
  carries them to the right and speeds up as you sort (0.9 to 2.2 m/s), the drops come faster.
- The right chute scores 1, plus 1 for every 5 in a row (a streak shows beside the stamps); confetti
  bursts out of the chute and its sign hops.
- Every 8 sorted parcels the three signs flip edge-on and trade places ("THE CHUTES SWAP!"): watch
  the signs, not the places.
- Each of these costs one of three stamps (top left): a parcel into the wrong chute (it is spat back
  out onto the floor), a flick at no chute (it lands on the floor), a parcel that rides off the end of
  the belt. At zero: SHIFT OVER with the score and the session's best; the next click starts a new
  run in the same room. Runs last about 20 to 60 seconds.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the run starts mid-shift with two
parcels riding and one dropping; a cursor reaches for the first one at once and flicks it at 0.6 s.
The demo clerk lets each parcel ride a little (to a random spot), then takes the one nearest the end,
reaches for it (0.14 to 0.32 s, slower just after a swap), drags a short way towards its chute and
lets go. Its flicks carry a small aim error, and about one in fourteen a wild one; it picks the wrong
chute 3 % of the time (14 % in the two seconds after a swap) and lets one parcel in thirty-three ride
off the end. Its runs last 20 to 56 s (scores 9 to 88 in six minutes of demo); it restarts by itself
2 s after SHIFT OVER. When demo is switched off, a fresh run waits with one parcel on the stopped belt
and the hint; the first press starts the belt (and grabs the parcel if it is under the pointer).

## What is where

```
art/palette.json, palette.png   Paper 8 with ramps wood, red, green, paper, wall, rubber, metal, glow; roles
art/assets.md                   the asset list, ramps, bones, layout
art/chute/                      the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/chute/                   spec + gate record, make_chute.py -> p1_blockout.txt, p2_form.txt, p3_parts.txt,
                                chute.glb (gated), chute_body.glb + sign_red/green/cream.glb (the game's parts),
                                chute.bake.json, gate shots
models/env/                     make_env.py writes room, belt, cleat, parcel_red/green/cream, confetti, hand, props
                                (.txt hedra command files) and textures/ (planks, wallpaper, wainscot); their GLBs
lookdev/                        the turntable bench (no RML): chute.bin
scene.bake.json                 the composition: room, belt, props, three chute bodies; game bones (signRed,
                                signGreen, signCream, hand, cleat0-11, red0-5, green0-5, cream0-5, bit0-9), bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        chute (framed), chute@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 44 of 63. Splats: 53 350 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the chute (p1, p2, p3), lookdev/chute.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/chute/chute.rmdl -o /tmp/chute_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/chute/refs --shots /tmp/chute_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob chute -o /tmp/chute_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/chute/refs --shots /tmp/chute_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=-35 --arg sunPitch=55 --arg keyLight=0.4 --arg highlight=0.85)
python3 $K/scripts/golden.py views --rive lookdev --blob chute -o /tmp/chute --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/chute --goldens goldens/chute
python3 $K/scripts/golden.py views --rive lookdev --blob chute -o /tmp/chute_s --texel 0.0588 --size 120 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/chute_s --goldens goldens/chute@scene
for n in 040 420 1830; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

The scene goldens: `demo_040` (the first flick in the air, the cursor dragging), `demo_420` (confetti
out of the green chute, a streak), `demo_1830` (SHIFT OVER after the demo's first run) and `frame_030`
(the hint). All four frames audit 100 % solid blocks, 0 off-palette.

Play it headless (the waiting red parcel sits at screen 238, 253; the red chute is up and to the
left): `rive scene --screenshot=$PWD/p.png --advance=30 '--pointer=drag@238,253>190,212:8' --advance=60`
sorts it (SCORE 1); `'--pointer=drag@238,253>271,220:8'` flicks it into the green chute (WRONG
CHUTE!, a stamp lost); `--advance=30 --pointer=click@600,380 --advance=1300` starts the belt and lets
three parcels ride off: SHIFT OVER, and a further click starts a new run. The hand-over from demo to
a visitor: `--commands` with `data demo=true`, `advance 300`, `data demo=false`, `advance 30` (the
hint, BEST 0), then a drag.

## Notes from building it

- The sign disc's cream centre (on the sheet) made the red and the cream signs both read as tan
  bullseyes at 1x; the game's discs are solid with only the thin outer ring (p3 recolours the centre),
  baked at 1.5 x and raised so a sign is 16 art pixels across. The gated hero keeps the sheet's disc.
- The chute's rim and disc fatten by a splat radius at 0.08 m spacing (splat aspect drift 0.099 on the
  right view); the chute bakes at 0.07 m, in the bench and the scene.
- `select face where "pos.z < 0.02"` on the sack (object origin at its centre) took its whole lower
  half: hedra's face positions are object-local.
- Plum chutes vanished against a plum wainscot; the wainscot is teal now, and the intake hopper teal
  tin rather than plum wood.
- The first demo flicked every parcel the moment it appeared and the belt looked empty; now each
  parcel rides to a random spot before the clerk wants it, the drops come every 1.9 s at the start, and
  three or four parcels ride at once.
- The twine straps of a parcel are boxes through the parcel: their inner faces bake about 250 hidden
  splats a parcel (kept: 53 k splats in all is well inside the budget).
- The Codex sheet was not reviewed by a person yet (`art/chute/sheet.v1.png.json`, `reviewed: false`).
