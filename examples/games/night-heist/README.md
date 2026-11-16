# Game: Night Heist (Cyclope6, 6 colours)

**How to play:** click to start, then move the pointer: the cat follows it across the rooftops. Grab
the fish; stay out of the searchlights' pools.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Cyclope6](https://lospec.com/palette-list/cyclope6) by Naym, six
colours (plum, wine, slate, teal, sea green, mint) in eight ramps; it loaded from Lospec, so the spare
(`urbex-16`) was not needed. Two flat city roofs at night either side of an alley, a row of taller
buildings behind with lit windows and three searchlights on posts, a water tower, chimneys, a skylight,
a full moon with drifting clouds and a wine-red skyline. The roofs are the bright teal mid value, the
cat a wine-red silhouette on them, the light pools and the fish mint. Orthographic, yaw 0, pitch 42,
`orthoHeight` 8 m, `pixelSize` 3 (texel 0.0588 m), moonlight from the front left (sunYaw -35, pitch 55)
so shadows fall back and short, per-splat dither, ink 1, a flat plum sky.

## Rules

- One verb: move the pointer. The first click starts a run; the cat runs to the pointer (up to 3.7 m/s),
  slides along chimneys and boxes, and leaps the alley between the two roofs.
- One fish at a time sits somewhere on the roofs under a bobbing marker. Touch it: +1 (`+1 QUICK!` when
  grabbed within 2.5 s). The next one appears elsewhere, 2.6 to 7.5 m from the cat.
- Searchlights sweep pools of light over the roofs (Lissajous paths). One lamp is on from the start,
  the second wakes after 7 s, the third after 19 s, and they sweep faster as the run goes on.
- Standing in a pool fills the alarm (the bar under the score; `!` over the cat): 0.7 s of light is
  enough. Out of the light it drains (2.5 s from full). A lamp that has seen the cat follows it for a
  moment, slower than the cat runs; a grabbed fish drains a little alarm. While leaping the alley the
  cat is not seen.
- A full alarm: CAUGHT! Every lamp swings onto the cat, it jumps, and the line shows the fish and the
  session's best. The next click (after 0.6 s) starts a new run in the same world.
- Runs last about 15 to 45 seconds.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the run starts at once, the cat already
walking towards the first fish with a lamp sweeping. The demo re-plans 4 to 8 times a second: it tries
twelve directions and takes the best trade between closing on the fish and keeping out of each pool,
where it is and where it will be a moment later; it waits in the dark when the fish is lit. It aims a
little off, now and then reacts late, and about one fish in eight it wants too much and cuts through the
light. Over four minutes its runs lasted 16 to 45 s with 5 to 15 fish; it restarts 2 s after CAUGHT.
When demo is switched off, a fresh run waits for the first click (best reset to 0).

## What is where

```
art/palette.json, palette.png   Cyclope6 with ramps roof, brick, fur, metal, glass, fish, light, spark; roles
art/palette_bench.json          the same palette with the roof's teal as sky, for the lookdev bench only
art/assets.md                   the asset list, bones, layout
art/cat/                        the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/cat/                     spec + gate record, make_cat.py -> p1_blockout.txt, p2_form.txt (cat.glb, gated),
                                p3_splat_fit.txt (cat_fit.glb, baked), p4_parts.txt (cat_body, cat_tail, cat_leg),
                                cat.bake.json, gate shots
models/env/                     make_env.py writes roofs, backrow, props, sky, lamp, pool, fish, spark, cloud .txt
                                (hedra command files) and textures/roof_tar.png, roof_tile.png; their GLBs
lookdev/                        the turntable bench (no RML): cat.bin
scene.bake.json                 the composition: world, game bones (cloud x2, pool x3, lamp x3, fish, spark x8,
                                cat, tail, leg x4), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        cat (framed), cat@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 23 of 63. Splats: 43 995 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the cat (p1-p4), lookdev/cat.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/cat/cat.rmdl -o /tmp/cat_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/cat/refs --shots /tmp/cat_p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob cat -o /tmp/cat_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/cat/refs --shots /tmp/cat_alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L=(--arg sunYaw=-35 --arg sunPitch=55)
python3 $K/scripts/golden.py views --rive lookdev --blob cat -o /tmp/cat --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/cat --goldens goldens/cat
python3 $K/scripts/golden.py views --rive lookdev --blob cat -o /tmp/cat_s --texel 0.0436 --size 120 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/cat_s --goldens goldens/cat@scene
for n in 045 088 1040; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$((10#$n)) --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

The scene goldens: `demo_045` (the first second: the cat on its way, a lamp sweeping), `demo_088` (the
first grab, `+1 QUICK!`), `demo_1040` (CAUGHT!: the lamps converge on the jumping cat) and `frame_030`
(the hint before the first click).

Play it headless: `rive scene --screenshot=$PWD/p.png --advance=3 --pointer=click@115,250 --advance=150`
(a click on the first fish: FISH 1); leave the pointer still after that and a light finds the cat
(CAUGHT! around frame 800). The hand-over from demo to a visitor, with `--commands`:
`data demo=true`, `advance 400`, `data demo=false`, `advance 10`, `screenshot ...` shows the hint.

## Notes from building it

- First look: the roofs painted slate under a low moon from behind: everything sat in one dark value,
  the back row's long dithered shadows covered half the roofs and the cat was lost. The roofs are teal
  now (the bright mid value), the moon lights from the front left and high, and shadows are short.
- The back row was first 3 m deep: seen from 42 degrees its flat tops filled the sky. It is 1 m deep.
- The far skyline sits low and far back (an orthographic camera lifts far things on screen), so it
  showed through the alley as a wine stripe until the back row's facades reached down to the alley's
  floor.
- The fish was teal on teal; it is mint now with a bobbing marker over it. Mint also marks the light,
  but a small turning shape with a marker reads apart from a flat pool.
- The splats widened the cat by a radius each side (back and top aspect drift 0.11): `p3_splat_fit.txt`
  narrows it for the bake, while `cat.glb` (p2) stays the gated form.
- The first demo got pinned in the corner of the back edge and the alley by a following pool (runs of
  6 s). It now scores twelve candidate steps against every pool now and in a moment; a waking lamp also
  starts its sweep far from the cat.
- `--arg` values in zsh: `set -- $c` does not split a variable (`a=(${=c})` does); an unsplit
  `--arg sunYaw=-160 55` left the sun undefined and the frame black.
- The Codex sheet was not reviewed by a person yet (`art/cat/sheet.v1.png.json`, `reviewed: false`).
