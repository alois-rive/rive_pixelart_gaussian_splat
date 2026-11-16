# Game: Hoop Alley (DinoKnight 16)

**How to play: press on the ball and flick it up at the hoop: a faster flick throws farther, a slanted
one aims left or right. Sixty seconds; three in a row and Juno is ON FIRE.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [DinoKnight 16](https://lospec.com/palette-list/dinoknight-16) (it
loaded from Lospec: the spare, Lost Century 24, was not needed), fourteen ramps (asphalt, paint, brick,
ball, rim, glow, skin, kit, blue, dusk, metal, and three one-colour bulb ramps). An evening street court
between brick walls: murals of a setting sun over hills, a great wave, a vine and some peaks, strings of
bulbs zigzagging overhead, a bench with a boombox, a vending machine glowing by the wall, and a hoop with a
chain net on a sliding wall rail. Seen from behind the shooter, Juno (number 5), through a perspective
camera (fov 42, `pixelSize` 2: 320 x 200 art pixels) that glides to each new spot.

The rules: a run lasts 60 seconds; the clock starts with the first shot. A basket is worth 2 from the
three spots inside the arc, 3 from the three outside it; after three baskets from one spot Juno walks to
the next (her ball cart rolls along). Three baskets in a row: ON FIRE, the ball glows (unlit) and trails
embers, and baskets count x2; six in a row, x3. A miss puts the fire out. In the last 20 seconds the hoop
slides along its rail (lead it with the flick's slant). The buzzer ends the run; balls already in the air
still count ("BUZZER BEATER!"). Then the final score, baskets out of shots and the session's best; a
click (or a tap) starts a new run. The label over the hoop tells how a shot went: SWISH, BANK, +n, RIM
OUT, SHORT, LONG, WIDE, AIRBALL.

Controls (pointer only, touch-ready): press on the ball, or anywhere below it (a generous grab: within
48 art pixels of the ball or lower on the screen), drag upward and let go. The power is the pointer's
speed over the last 0.08 s before the release (600 art pixels a second is a perfect length; the meter at
the right shows the live flick against its green sweet band, and a white mark keeps the last shot's
power); the flick's slant from vertical, times 0.25, turns the shot. Nothing needs a hover: on a phone
the press arrives at the touched point and the flick is the finger's own motion; a release right after
the last move counts as part of the flick; a finger that slides off the tile mid-flick lets go there
(the renderer ends the gesture). A drag shorter than 8 pixels, or not upward, puts the ball back up. The whole game was played with touch gestures only (`touch down@`, `touch drag@`, `touch up@`,
`touch tap@`; no bare moves).

The physics (prototyped in a throwaway Python port, then `scene/game.as`): the ball leaves Juno's hands
60 degrees up at the speed that carries it to the intended range; gravity 9.8; four sub-steps a frame;
the rim is a torus (ring 0.335 m, tube 0.045 m; it keeps half the normal speed and 85 % of the rest), the
backboard a box (0.55), the walls and the ground bounce it; it spins backwards in flight and rolls on the
ground. A ball that drops through the ring scores; the chain net (three bands, each a bone hanging from
the one above) funnels and slows it, stretches and swings, and swings from rim hits too. After its first
bounce a ball drifts back to the cart; the cart lobs Juno the next one about half a second after a shot,
so up to four balls are in play.

Sound (`sfx.as`, silent in demo mode): a click when the ball is grabbed, a whoosh on the release (higher
for a harder shot), a metallic clang off the rim (a crunchy hit with a high note, louder for a harder
knock) with the chains rattling, a low thud off the backboard, a bouncing thump on the asphalt (quieter as
the bounces die) and off the back wall; a basket is a soft noise swish (only for a clean one), the chain
net's rattle (four clicks at fixed little intervals) and a plucked note that climbs a scale with the
streak; ON FIRE a power-up, the fire going out a low blip. The catch from the cart is a soft pop, the
cart's wheels tick while Juno walks, a chime marks the moving hoop, ticks count the last five seconds, and
the buzzer (low square blips back to back over a rasp, 0.9 s) ends the run; a new best plays a fanfare, a
new run a two-note whistle. No sound is decided by `api.rand()`.

Demo (`--arg demo=true`, or the `demo` view-model property): a decent player with a power error of about
0.045 and an aim error of about 1.1 degrees, who leads the moving hoop by guessing where it will be (and
misjudges it a little). It opens with a ball already in the air (action in the first frame), shoots about
every 1.4 s, makes 62-78 % (about half in the moving phase), scores 75-130, and starts a new run 2 s after
the end. Its scores never set the visitor's best. Switching demo off starts a fresh run waiting for the
first flick.

```
art/palette.json, palette.png   DinoKnight 16 with its ramps and roles (sky navy over purple, void #0f151b)
art/assets.md                   the asset list, the camera and texel, the bones, the numbers the game uses
art/hoop/                       the hero's Codex brief, sheet v1 (reviewed: false), its record and log, cut views (refs/)
models/hoop/                    make_hoop.py (writes p1_blockout.txt, p2_form.txt, net.txt and the board and net
                                textures), spec + gate record (top-view waiver), bake file (lookdev), gate shots, GLBs
models/env/                     make_env.py (writes every other command file and the court, wall, mural, can and
                                jersey textures): court, walls, lights, bench, vend, rack, ball, fire, spark (+ ember),
                                shooter (body, head, arm); GLBs
lookdev/                        the turntable bench (no RML): hoop.bin
scene.bake.json                 the composition: 66 522 splats, 29 game bones, the play area bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), the renderer files
goldens/                        hoop (framed), hoop@scene (texel 0.04), scene (demo_040 / 1214 / 2440, frame_030)
shots_scene/                    the scene frames the goldens were snapped from
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                  # models from scratch, lookdev/hoop.bin, scene/splats.bin
rive scene --verify && rive scene           # play it; `rive scene --arg demo=true` watches the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/hoop/hoop.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/hoop/refs --shots /tmp/p2 --min-iou 0.75     # top: waiver in the spec
python3 $K/scripts/golden.py views --rive lookdev --blob hoop -o /tmp/alb --look albedo --views front,right,back,top \
  --arg pitchMin=0 --arg pitchMax=90
python3 $K/scripts/golden.py gate --refs art/hoop/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7
L="--arg sunYaw=-30 --arg sunPitch=45 --arg keyLight=0.4 --arg highlight=0.88 --arg shadeSteps=1 --arg edgeDepth=0.8"
python3 $K/scripts/golden.py views --rive lookdev --blob hoop -o /tmp/hp --real-sky ${=L}       # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/hp --goldens goldens/hoop
python3 $K/scripts/golden.py views --rive lookdev --blob hoop -o /tmp/hps --texel 0.04 --size 160 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/hps --goldens goldens/hoop@scene
for n in 40 1214 2440; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_1214.png -p art/palette.json --pixel 2
```

Try it headless (artboard coordinates, 60 fps frames): a 120-point flick in 6 frames is a perfect length,

```sh
rive scene --screenshot=$PWD/shot.png --advance=10 '--touch=down@285,290' '--touch=drag@285,290>285,170:6' \
  '--touch=up@285,170' --advance=60                       # SWISH +2
rive scene --screenshot=$PWD/shot.png --advance=10 '--pointer=drag@285,280>285,160:6' --advance=60
```

and the gallery's hand-over with `--commands`: `data demo=true`, `advance 400`, `data demo=false`,
`advance 30` (a fresh run with the hint), then a touch flick.

Notes from building it:

- The first launch angle (54 degrees) came from the first Python port, which released the ball at 2.45 m;
  from the real hold point (1.7-1.9 m) almost every make touched the rim and the demo made 47-59 %. At 60
  degrees the ball drops in steeply: clean swishes, and the demo makes 62-78 %.
- Headless, the release arrives a frame after the last drag move at the same point and diluted the
  measured speed (480 instead of 600 px/s): an unmoved release within two frames of the last move is not a
  new sample.
- The six shooting spots were painted orange first and read as loose balls on the court: they are blue.
- The string lights first hung 4-5 m from the lens and drew as big blobs: moved back over the court.
- The Codex sheet was not reviewed by a person yet (`art/hoop/sheet.v1.png.json`, `reviewed: false`).
