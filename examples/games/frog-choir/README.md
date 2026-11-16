# Game: Frog Choir (Eggy 15)

**How to play:** click each frog just as the beat ring closing on it reaches its dotted circle.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Eggy 15](https://lospec.com/palette-list/eggy-15), 15 colours in 16
ramps; it loaded from Lospec, so the spare (`rosy-42`) was not needed. A marsh pond at dawn: a pink
and orange sky, a yellow sun rising behind a dark reed bank, its broken reflection down indigo water,
mist drifting along the far bank. Five frogs in an arc (green, red, gold, blue, violet: each painted on
its own ramp of the palette) sit on lily pads and the lead singer on a stone. Orthographic, yaw 0,
pitch 20, `orthoHeight` 6.8 m, `pixelSize` 3 (texel 0.05 m), the light from the front left (yaw -45,
pitch 30, key 0.35), per-splat dither, ink 1, no fog.

## Rules

- One verb: click. The first click starts a run; the first ring closes 1.6 s later.
- A ring in the frog's colour shrinks onto it; a dotted circle marks where it closes (the beat). Click
  the frog then: within 0.075 s of the beat is PERFECT (100), within 0.17 s GOOD (50). The frog
  stretches up, throws its head back, puffs its yellow throat sac; a ripple runs out over the pond and a
  note floats up. Every frog dips on each beat; a frog whose ring is about to close draws breath.
- A sour note costs one of three voices (the notes, top right): a ring that closes with no click
  (LATE), a click far too early (EARLY), or a click on a frog with no ring coming (SOUR). The frog
  squashes and shakes its head and the camera jolts. A click on the water only breaks the combo.
- Notes in a row build a combo ("12 IN TUNE"): every 8 raise the multiplier (up to x4), every 16 win
  a lost voice back; at 8 the waiting frogs start to sway. The tempo rises from a beat every 0.85 s to
  0.4 s over about a minute, rings take less time to close and overlap, quick pairs and rests appear;
  the next singer is a neighbour or a leap of two, weighted towards frogs that have not sung lately.
- With no voices left the choir stops (heads down): GAME OVER with the score, the session's best and
  the longest run of notes; the next click starts a new run. Runs last about 20 to 90 seconds.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): a run starts at once with the first ring
already closing (the first PERFECT about half a second in). The demo player decides each note's click time when the note is
scheduled: a timing error that grows with the tempo (sigma 0.035 s, plus 0.0011 s per second of run),
a fumble (0.26 s early or 0.21 s late) 3 % of the time, a forgotten note 1 %. An arrow cursor glides to
the next frog ahead of the beat and presses on each click. Its runs last 50 to 70 s and end in GAME
OVER (five-ish sour notes, some voices won back); it restarts two seconds later. When demo turns off,
a fresh run starts with a 1.9 s count-in and the hint line.

## What is where

```
art/palette.json, palette.png   Eggy 15 with ramps (five frog skins, belly, eye, ink, pad, water, glint,
                                wood, stone, lotus, sun, mist) and roles
art/assets.md                   the asset list, bones, splats, layout
art/frog/                       the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/frog/                    spec + gate record, make_frog.py -> p1_blockout.txt, p2_form.txt, p3_parts.txt;
                                frog.glb (gated), frog_<skin>.glb x5 and sac.glb (the game's parts),
                                frog.bake.json, gate shots
models/env/                     make_env.py writes pond, bank, reeds, pad, lotus, stone, log, sun, cloud, mist,
                                ripple .txt (hedra command files); their GLBs
lookdev/                        the turntable bench (no RML): frog.bin
scene.bake.json                 the composition: world, game bones (frog0-4, sac0-4, ripple0-7, mist0-3),
                                material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light, sky), game.as (the whole game), renderer
goldens/                        frog (framed), frog@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 22 of 63. Splats: 66 362 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the frog (p1, p2, p3), lookdev/frog.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/frog/frog.rmdl -o /tmp/frog_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/frog/refs --shots /tmp/frog_p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob frog -o /tmp/frog_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/frog/refs --shots /tmp/frog_alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L=(--arg sunYaw=-45 --arg sunPitch=30 --arg keyLight=0.35 --arg highlight=0.85)
python3 $K/scripts/golden.py views --rive lookdev --blob frog -o /tmp/frog --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/frog --goldens goldens/frog
python3 $K/scripts/golden.py views --rive lookdev --blob frog -o /tmp/frog_s --texel 0.0417 --size 120 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/frog_s --goldens goldens/frog@scene
for n in 040 280 600; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

The albedo gate fails the back view's colour drift (0.35) by a recorded waiver (the sheet paints the
back in shade tones): see `models/frog/frog.spec.md`.

Play it headless: `rive scene --screenshot=$PWD/p.png --advance=5 --pointer=click@320,200 --advance=400`
starts a run and lets three rings close: GAME OVER at 3.5 s. Frog centres for clicks (screen pixels):
(109, 238), (211, 217), (319, 190), (427, 217), (529, 238). A scripted player (driven through `rive scene
--commands`, reading the note times from a temporary log, clicking each frog on its beat with a few
deliberately late GOODs) hit 50 notes (a run of 40, x4), skipped three on purpose and reached GAME OVER
at 38.7 s with 10 900.

## Notes from building it

- `rive --commands` screenshots are not palette-exact: their colours are off by one in a channel on
  about 6.5 % of pixels (the frame audit fails them at 45 % solid blocks), while `--screenshot` of the
  same frame is exact. Goldens and audits use `--screenshot`.
- A click in `--commands` costs two frames (down and up), so a scripted rhythm drifts unless it
  re-syncs on the game's own clock.
- The first song walked the choir at random and stayed on the left three frogs for 12 s: the next
  singer is now weighted by how long each frog has waited.
- The first demo fumbled 5 % of its notes and ended runs at 13 s; at 3 % (plus 1 % forgotten) its runs
  last 50 to 70 s.
- Fog at 0.15 dotted the sun with a sparse Bayer grid: the scene has no fog; the dawn mist is four
  drifting wisps (game bones) along the far bank.
- Reeds painted lit teal read as crumbling green posts against the sky; painted on moss (the pad ramp's
  step 1) they stand as dark backlit silhouettes.
- `select vert where "pos.z < -0.2"` + `delete vert` meant to trim buried undersides also ate the far
  bank's front face and most of the log (8 triangles left, no cut ends); the log now sinks by its bake
  position and deletes only faces looking down, and the bank cut sits below its slab.
- The frogs' five skins are five exports of one gated mesh with the Skin colour set per export
  (`p3_parts.txt`), so the colour snaps exactly to each frog's ramp.
- The Codex sheet was not reviewed by a person yet (`art/frog/sheet.v1.png.json`, `reviewed: false`).
