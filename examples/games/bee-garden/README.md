# Game: Bee Garden (FunkyFuture 8)

**How to play:** click to fly, then move the pointer to lead the bee over the flowers before they
wilt; hover over one for a moment to pollinate it.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [FunkyFuture 8](https://lospec.com/palette-list/funkyfuture-8) by
Shamaboy, eight colours (navy, plum, pink, white, orange, yellow, blue, cyan) in seven ramps; it loaded
from Lospec, so the spare (`apollo`) was not needed. A floating garden at neon dusk: no green in the
palette, so the lawn is blue with cyan clover and cyan stems, the flowers pink and white, the bee
yellow and navy, all on a navy sky. Orthographic, yaw 0, pitch 45, `orthoHeight` 7.6 m, `pixelSize` 3
(texel 0.056 m), sun from the front left (yaw -35, pitch 48), per-splat dither, ink 1.

## Rules

- One verb: move the pointer. The first click starts a run; the bee flies to the pointer on a spring
  (it lags, banks into turns, faces where it flies).
- Flowers grow out of the seven soil mounds, faster and with shorter lives as the run goes on (from
  two open at once up to five). A bar over each shows its time; it droops when time is short.
- Hover over a flower for 0.3 s to pollinate it: a pop, a pollen burst, +1. It then sinks back into its
  mound and the mound rests for a second.
- From a few seconds in, the spider sometimes guards a flower (marked `X3`, worth 3, and it lasts
  longer). It circles it; when the bee comes near it crouches (the warning) and leaps. Dodge out of
  the way, or come in while it is on the far side.
- A wilted flower or a spider bite costs one of three lives (the flowers top right). A bite knocks the
  bee back and leaves it blinking (safe) for 1.5 s. At zero the bee tumbles onto the lawn: GAME OVER
  with the score and the session's best; the next click starts a new run in the same garden.
- Runs last about 20 to 60 seconds.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the run starts at once with two
flowers open and the bee leaving the hive. The demo player re-decides 2 to 5 times a second with a
little aim error, goes for the flower with the least time left (weighed by distance), now and then
picks a worse one, waits out of reach until the spider has circled to the far side of a guarded
flower, and darts away when it crouches (usually in time: a fifth of its reactions are slow). Its runs
last about 45 to 60 seconds and end by bites and the odd wilt; it restarts itself two seconds after
GAME OVER. When demo is switched off, a fresh run starts at once.

**Sound** (`sfx.as`, silent in demo mode): the bee lifts off with a hop and three rising notes; each
flower that opens plucks its own mound's note (a pentatonic garden that plays itself), and a low pluck
of that note warns when its bar starts to blink. Hovering buzzes in ticks that climb as the pollen
takes; a pollination is a pop and a pluck that climbs the scale with each flower in quick succession (a
coin and a bell for the spider's flower). The spider crouches with a dry click and leaps with a whoosh;
a bite is a crunch; a wilt a soft flop and two falling notes; the game over the lose jingle and a thud
as the bee lands on the lawn.

## What is where

```
art/palette.json, palette.png   FunkyFuture 8 with ramps lawn, petal, cloud, gold, earth, ink, glow; roles
art/assets.md                   the asset list, bones, layout
art/bee/                        the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/bee/                     spec + gate record, make_bee.py -> p1_blockout.txt, p2_form.txt, p3_parts.txt,
                                bee.glb (gated), bee_body.glb + wing_l.glb + wing_r.glb (the game's parts),
                                bee.bake.json, gate shots
models/env/                     make_env.py writes island, hive, bush, fence, rock, flower_pink, flower_white,
                                wilt, spider, sparkle .txt (hedra command files); their GLBs
lookdev/                        the turntable bench (no RML): bee.bin
scene.bake.json                 the composition: world, game bones (bee, wingL, wingR, rose0-3, daisy0-2,
                                wilt0-3, spider, spark0-9), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        bee (framed), bee@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 25 of 63. Splats: 32 972 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the bee (p1, p2, p3), lookdev/bee.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/bee/bee.rmdl -o /tmp/bee_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/bee/refs --shots /tmp/bee_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob bee -o /tmp/bee_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/bee/refs --shots /tmp/bee_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=-35 --arg sunPitch=48)
python3 $K/scripts/golden.py views --rive lookdev --blob bee -o /tmp/bee --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/bee --goldens goldens/bee
python3 $K/scripts/golden.py views --rive lookdev --blob bee -o /tmp/bee_s --texel 0.041 --size 100 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/bee_s --goldens goldens/bee@scene
for n in 100 460 700; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/demo_*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Play it headless: `rive scene --screenshot=$PWD/p.png --advance=30 --pointer=click@320,161 --advance=60
--pointer=move@446,165 --advance=90` (a click on the middle flower, then a move to the right one).

## Notes from building it

- The first renderer drew the HUD from the screen's top-left and the scene's blit from its centred,
  snapped offset (phase 2, 1 here): HUD pixels straddled art pixels (94 % solid blocks). The camera
  target was put a third of a texel off the art grid (`targetX` -0.018627, `targetY` -0.131716 in
  `scene.rml`) so the snap slid the blit onto the HUD's grid, and the shake moves it by whole texels.
  The renderer now aligns the HUD with the art grid itself; the offset is kept (harmless, and the
  goldens were snapped with it).
- The first renderer also drew the HUD one path per colour, so a panel could land under earlier text;
  it now draws in call order, and `hud()` draws every backing panel before the text on it.
- The bee's abdomen is eight frustum rings (clean colour bands); their caps, hidden inside the body,
  baked 770 splats until deleted in `p2_form.txt`.
- A recolour (a flower wilting) is a swap of bones: the pink or white flower droops, then hides, and
  a dark `wilt` copy takes its place.
- The first spider lunged at any bee passing it: 15 bites to 1 wilt in a demo run. It now threatens
  only near the flower it guards, with a 0.36 s crouch to read and dodge.
- The Codex sheet was not reviewed by a person yet (`art/bee/sheet.v1.png.json`, `reviewed: false`).
