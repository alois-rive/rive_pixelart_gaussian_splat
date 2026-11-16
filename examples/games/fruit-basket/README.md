# Game: Fruit Basket (CC-29)

**How to play:** move the pointer left and right to roll the cart under the falling fruit; catch the
good fruit, dodge the grey rotten apples. Click to start; click again after the game over.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [CC-29](https://lospec.com/palette-list/cc-29) by Alpha6 (loaded first
time, no spare needed), 29 colours as ten ramps (grass, leaf, wood, red, orange, pear, plum, rot, blue,
stone). A sunny orchard morning: cyan sky over mint, three apple trees in front of a fence and a hedge, a
dirt lane, a crate of apples and a flowering bush. Orthographic, fixed camera (yaw 0, pitch 20, 7 m,
`pixelSize` 2: a 320 x 200 art grid), sun from the front left, per-splat dither, ink 1.

Rules: apples and oranges score 1, plums 2, the glowing golden pear 5. A rotten apple in the cart costs a
life, and so does a good fruit that hits the ground (a rotten one on the ground is a dodge). Three lives;
fruit comes faster, falls faster and rots more over the first 50 seconds (a run lasts 30 to 60 s).
Each fruit first pops out on a branch and wobbles (its tree shakes): that is the warning.
Score, best (this session), lives as three apples, floating +N / YUCK! / SPLAT texts; all on the art grid
in palette colours.

Motion (all game bones, 32 of 63): the cart follows the pointer on a stiff spring, leans into its
acceleration, squashes and rebounds when it catches, shudders on a rotten apple; its wheels roll with
the distance (15 degree steps); fruit pops in, wobbles, stretches on its stalk, falls spinning and
stretched along its speed, sinks into the tray or squashes flat on the grass and blinks out; cream
sparks burst on every catch; the canopies shake before they drop something.

Sound (procedural, `sfx.as`; silent in demo mode): a fanfare starts a run; each stalk snaps as its
fruit lets go (lower for a rotten one); a catch knocks on the tray and chimes up a major scale with
the streak of good fruit (a plum a fifth higher, the golden pear a power-up arpeggio). A rotten
apple in the cart squelches and crunches; a good fruit on the grass splats; a dodged rotten one
thuds softly; the wheels knock once a turn; GAME OVER plays the lose jingle. Panned by where it
happens.

Demo (`--arg demo=true`, the gallery's `Sample.demo`): an apple is already falling on frame 0 and caught
by frame 30. The demo player aims at the good fruit that will land first, a beat late (it re-decides every
0.12-0.24 s) and a little off (+-0.5 m), sidesteps rotten apples 85 % of the time and lets about one aim
in eight go; it loses a run in about 40 s and starts the next 2 s after the game over. Its best is kept
apart from a visitor's. When demo turns off, a fresh run starts at once.

```
art/palette.json, palette.png   CC-29 with its ramps and roles
art/assets.md                   the asset list (sizes, ramps, bones, budgets)
art/cart/                       the hero's Codex brief, sheet (v1), record and log, cut views (refs/, top turned -90)
models/cart/                    spec + gate record, p1_blockout.txt, p2_form.txt, bake file, gate shots, GLBs
                                (cart.glb for the gates; cart_body.glb and cart_wheels.glb for the game)
models/env/                     make_env.py (writes every other command file), the command files and GLBs
lookdev/                        the turntable bench (no RML): cart.bin
scene.bake.json                 the composition: 74 000 splats, 32 game bones, a "bounds" play area
scene/                          the Rive project: scene.rml (tuned inputs), game.as (the whole game), renderer files
goldens/                        cart framed and at the scene's texel; scene/: demo_030, demo_280, demo_520, frame_020
shots_scene/                    the scene frames the goldens were snapped from
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                             # models from scratch, lookdev/cart.bin, scene/splats.bin
rive scene --verify && rive scene                      # play it
rive scene --arg demo=true                             # watch the demo
```

Check (gates, goldens, frame audit; zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/cart/cart.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/cart/refs --shots /tmp/p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob cart -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/cart/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7
L="--arg sunYaw=-35 --arg sunPitch=48 --arg keyLight=0.45 --arg highlight=0.8"
python3 $K/scripts/golden.py views --rive lookdev --blob cart -o /tmp/cart --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/cart --goldens goldens/cart
python3 $K/scripts/golden.py views --rive lookdev --blob cart -o /tmp/cart_s --texel 0.0347 --size 160 --pixel 2 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/cart_s --goldens goldens/cart@scene
for n in 030 280 520; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$((10#$n)) --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_020.png --advance=20
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_280.png -p art/palette.json --pixel 2   # 100 %, 0 off-palette
# play by hand, headless: start, steer, lose, restart
rive scene --screenshot=$PWD/h.png --pointer=click@320,300 --advance=60 --pointer=move@100,300 --advance=600 --pointer=click@320,300 --advance=30
```

Notes from building it:

- `pixelSize` 2, not 3: the HUD is drawn from the frame's top-left, and at 3 the 640 x 400 frame is not a
  whole number of art pixels, so the text sat a screen pixel off the art grid (98 % solid blocks).
- The camera's `targetY` is 47 texels / cos(pitch) (1.733247): a target off the art grid makes the
  renderer slide the picture by the remainder, which again moved the art grid one screen pixel away from
  the HUD's (99.3 % solid). On the grid, both line up (100 %).
- The canopies' painted apples first matched the falling ones and hid them: they are smaller now, and the
  falling fruit is baked at 1.3 x (pixel-art exaggeration). Rotten apples were dark purple and vanished in
  front of the fence; they are light grey with dark mould now.
- A new run used to drop the three idle fruits at once (two lives gone in a second): they now fall one
  after another, 1.4 s apart.
- The cart leans and squashes about its foot with its own matrix in `game.as` (GameApi's `placeScaled`
  has no roll and `place` has no per-axis scale).
- The Codex sheet was not reviewed by a person yet (`art/cart/sheet.v1.png.json`, `reviewed: false`).
