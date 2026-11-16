# Game: Knight Dodge (Rust Gold 8)

**How to play:** click to start, then move the pointer: the knight runs to it. Dodge the boulders
that roll in through the gates, grab the coins, stay alive.

**Touch:** tap to start, then drag: the knight runs to a point a few pixels above your finger (so it
stays in sight) and stops where you lift.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Rust Gold 8](https://lospec.com/palette-list/rust-gold-8) by Trigo
Mathmancer, eight colours (gold, rust, brown, dark brown, tan, mauve, grey, black) in six ramps; it
loaded from Lospec, so the spare (`apollo`) was not needed. A round sand arena at torchlit dusk: tan
sand with mauve rings and scuffs, a mauve stone wall broken by four gates, a brazier burning on every
gate pillar, rust banners on the back wall, a black sky. Orthographic, yaw 0, pitch 52,
`orthoHeight` 10 m, `pixelSize` 3 (texel 0.075 m), a low sun from the front left (yaw -35, pitch 38)
casting long wall shadows, per-splat dither, ink 1.

## Rules

- One verb: move the pointer. The first click starts a run; the knight runs to the pointer on a
  spring (top speed 4.4 m/s), faces where it runs, bobs and waddles from foot to foot and leans in.
- Boulders come in through the four gates. Each first sits in its gate for 0.85 s, rocking and kicking
  up dust under a blinking `!` (the warning); then it rolls at the knight (a little off), turning as it
  goes, and smashes on the far wall in a burst of dust. They come faster and more often as the run
  goes on (every 2.3 s at first, every 0.8 s after a minute, sometimes two at once; 3 to 6 m/s).
- A point for every second alive; a gold coin is +5 (one or two glint on the sand at a time).
- A boulder hit costs one of three hearts (top right): the knight is squashed flat, knocked off the
  boulder's line, the camera shakes, and it blinks (safe) for 1.2 s. At zero it topples over: GAME
  OVER with the score and the session's best; the next click starts a new run in the same arena.
- Standing still loses in about 10 seconds; a careful player lasts 40 to 90.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the run starts at once with a boulder
already rumbling in a gate (it rolls within half a second) and a coin on the sand. The demo player
re-decides every 0.15 to 0.3 s: the boulder on course to pass within 1.3 m in the next 1.3 s makes
it step 1.9 m off that boulder's line (to the side it is on, or the other side if the wall is there);
otherwise it runs for the nearest coin, a little off, or loiters near the middle. It misses a threat
now and then (6 % of its decisions), takes knocks into other boulders, and its runs last about 30 to
45 seconds; it restarts itself two seconds after GAME OVER. When demo is switched off, a fresh run
starts at once.

Sound (procedural, `api.sound`; silent in demo): heavy stone and armour. A low fanfare starts a run; a boulder
blips as it appears in its gate, rumbles with rising low thuds while it rocks there, thumps as it sets off, bumps
once a turn as it rolls and bursts on the wall; the knight's armour jingles every few strides; a coin chimes,
a semitone higher for each coin since the last hit; a hit is a crunch and a clank, the last one a falling
tune and a thud as the knight topples; a bell rings every ten seconds survived, higher each time.

## What is where

```
art/palette.json, palette.png   Rust Gold 8 with ramps sand, stone, steel, rock, gold, fire; roles
art/assets.md                   the asset list, bones, layout
art/knight/                     the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/knight/                  spec + gate record, make_knight.py -> p1_blockout.txt, p2_form.txt,
                                knight.glb, knight.bake.json, gate shots
models/env/                     make_env.py writes arena, brazier, flame, banner, boulder, coin, dust .txt
                                (hedra command files); their GLBs
lookdev/                        the turntable bench (no RML): knight.bin
scene.bake.json                 the composition: the arena, braziers, banners, and the game bones
                                (flame0-7, boulder0-5, coin0-1, dust0-11, knight), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        knight (framed), knight@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 29 of 63. Splats: 43 778 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the knight (p1, p2), lookdev/knight.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/knight/knight.rmdl -o /tmp/kn_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/knight/refs --shots /tmp/kn_p2 --min-iou 0.75   # top: waiver in the spec
python3 $K/scripts/golden.py views --rive lookdev --blob knight -o /tmp/kn_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/knight/refs --shots /tmp/kn_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=-35 --arg sunPitch=38)
python3 $K/scripts/golden.py views --rive lookdev --blob knight -o /tmp/kn --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/kn --goldens goldens/knight
python3 $K/scripts/golden.py views --rive lookdev --blob knight -o /tmp/kn_s --texel 0.05 --size 120 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/kn_s --goldens goldens/knight@scene
for n in 48 250 600; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

The demo goldens: `demo_048` the knight takes the first coin (+5), `demo_250` a boulder flattens it
while another gate rumbles (`!`), `demo_600` it runs between two boulders. `frame_030` is the hint
before the first click.

Play it headless (quote a drag: `>` is a redirect in the shell):
`rive scene --screenshot=$PWD/p.png --advance=30 --pointer=click@320,204 --advance=40
--pointer=move@420,170 --advance=50` (start in the middle, then run up and right to the coin), or
`... --pointer="drag@320,204>200,150:30"`.

## Pixel grid

The first renderer drew the HUD from the screen's top-left and the scene's blit from its centred,
snapped offset; at `pixelSize` 3 they sat on different 3-pixel grids. The camera target was put a
third of a texel off the art grid (`targetX` -0.024510, `targetY` 0.159242 in `scene.rml`; texel =
10 / 136), so the snap slid the blit onto the HUD's grid (`palette.py frame`: grid phase 0,0, 100 %
solid), and the camera shake moves the target by whole texels only (x by a texel, y by a texel /
cos 52). The renderer now aligns the HUD with the art grid itself; the offset is kept (harmless, and
the goldens were snapped with it).

## Notes from building it

- The paved apron's top face lay in the sand floor's plane: the two fought splat for splat and the
  whole floor came out as grey-and-tan noise. The apron's top is now a ring cut away under the sand.
- A coin growing in from scale 0 made a degenerate bone: every one of its splats turned into a huge
  flat square over the arena for one frame. The grow-in starts at 0.2.
- The first renderer drew the HUD one path per colour, so the game-over panel could land on its
  text; it now draws in call order, and `hud()` draws every panel before the text on it.
- The first demo player missed one threat in eight and its runs lasted 15 to 45 s; at one in sixteen
  they last 30 to 45.
- The Codex sheet was not reviewed by a person yet (`art/knight/sheet.v1.png.json`, `reviewed: false`).
