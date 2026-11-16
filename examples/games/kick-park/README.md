# Game: Kick Park (AAP-64, 64 colours)

**How to play:** click to start; the skater follows the pointer (drag on touch); press, hold and
release to ollie; swipe in the air for tricks; land clean to chain combos. 75-second sessions.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [AAP-64](https://lospec.com/palette-list/aap-64) by Adigun A.
Polack, loaded from Lospec (the spare, `zughy-32`, was not needed), with 22 hand-written ramps. A sunny
little concrete skatepark on a lawn: a lilac-painted bowl, two quarter pipes with sandy decks, a teal and
orange fun box with steel ledges, a plywood kicker, a yellow handrail, expansion joints every 3 m, a back
wall of colour-block mural boards, trees, benches and lamp posts. The skater is Marlo, an original
character: a chunky kid in a yellow beanie and red-orange hoodie on a magenta deck. Orthographic camera,
yaw 20, pitch 40, `orthoHeight` 8 m (texel 0.0588 m), `pixelSize` 3, a sun from the front left
(sunYaw -50, pitch 50) with splat shadows that show every air's height, per-splat dither, ink 1.

## Controls (pointer only, mouse or one finger)

- **Steer**: the skater rolls towards the pointer: with a mouse it follows the hovering cursor; on touch it
  follows the finger while it drags. The direction is re-read every frame from the pointer's place on
  screen relative to the skater (the camera follows), so after the finger lifts the skater keeps the
  heading it was given, like a joystick left where it was. Limited turn rate (tighter when slow, half as
  much on steep walls).
- **Ollie**: press and hold without dragging: the skater crouches (a wind-up bar fills beside it in 0.45
  s); release to pop. The height grows with the wind-up (0.26 to 1.05 m on the flat). A press never
  steers, so a tap anywhere only ollies; a press that is dragged more than 12 art pixels becomes steering
  instead and its release does nothing.
- **Ramps**: off the kicker or a ramp lip the slope's speed throws the skater; releasing the wind-up just
  as it leaves the lip (up to 0.2 s after) adds a late pop on top: big air.
- **Tricks**: a quick swipe in the air (at least 10 art pixels within 0.6 s, from the press to the lift; a
  swipe longer than 36 pixels fires while still held, so several can be strung without lifting):
  - up: **FLICK** (the board rolls over once, 0.40 s, 100); long: **DOUBLE FLICK** (twice, 0.64 s, 260)
  - sideways: **HALF TWIRL** (skater and board spin 180, 0.42 s, 120); long: **FULL TWIRL** (360, 0.70 s,
    300); left and right spin opposite ways
  - down: **SUNNY GRAB** (knees up, the front hand on the board, the board tilted; 0.48 s, 140); long:
    **KITE GRAB** (the board pitched up beside, the back arm up; 0.62 s, 220)
  - a swipe during a trick queues one more; tricks animate the board and body (stepped at 12 fps) and the
    finished name pops over the skater.
- **Grinds**: come down onto the handrail or a fun box ledge (within 35 cm of it, moving within 40
  degrees of its line): **RAIL GRIND** / **LEDGE GRIND**, 60 points plus 120 a second, with sparks; tricks
  done on the way in count; it ends at the bar's end, when too slow, or with an ollie off it.

On touch: drag to steer, lift and press again (without dragging) to wind up an ollie, lift to pop, flick
in the air for tricks. Tested with `touch down/move/up` only (no hover): see Check.

## Rules

- **Clean landing**: no trick still turning, and the board within 35 degrees of the travel line (nose or
  tail first: a 180 lands fakie and is clean). On a steep wall (a vert air's landing) 75 degrees, as the
  board swings into the fall line. Anything else, or a landing harder than 11.5 m/s into the surface, is a
  **BAIL**: the skater tumbles downhill, the board shoots on wheels-up and spinning, the combo is lost,
  1.4 s to get up.
- **Combo**: each clean landing adds its tricks (or OLLIE 30 / AIR 50 when there was none) plus 40 a
  metre of height. Then comes a 1.4 s **WHEELIE** (nose up, a bar under the combo line): ollie again
  inside it to chain (+20 and one more to the multiplier); let it run out and the combo is banked.
- **Multiplier** = the number of different tricks in the combo + the chained landings (max 9); the bank is
  the points times the multiplier, popped over the skater with a jingle.
- **Session**: 75 s from the first click; the last five seconds tick. A combo in the air at zero finishes
  first. SESSION OVER shows the score, the best combo and the best (NEW BEST when beaten); the next click
  (after 0.8 s) starts a new session in the same park, the skater where it stopped.

## The physics (`scene/game.as`)

- The park is a height field with analytic gradients: the slab, the bowl (floor r 1.2, a circular
  transition of radius 2 to a 1.4 m deep coping at r 3.1), the quarter pipes (radius 2, 1.2 m, decks
  behind), the fun box (0.45 m, 1.2 m ramps), the kicker (0.6 m over 1.2 m). `models/env/make_env.py`
  builds the meshes from the same numbers.
- On the ground: four sub-steps a frame of a body held to the surface (gravity along the gradient,
  `(G + q) / (1 + |grad|^2)` with the path's curvature `q`, G = 11), rolling friction, a push stroke on
  gentle ground up to 7 m/s (the back foot kicks off beside the board), a pump down every transition
  (+2 m/s^2), top speed 10 m/s. Steps up over 20 cm are walls: the skater bounces off with a thud.
- Airborne when the surface falls away faster than a thrown body would (a lip, the kicker, an edge, a
  deck's drop). Off a quarter pipe's or the bowl's steep lip it is a **vert air**: the speed turns upwards,
  the skater turns 180 in the air and comes back down the wall (in the bowl only while the pointer is
  inside it: point outside to fly out over the coping). Landing keeps the velocity along the surface.
- The pose is rebuilt every frame: the root on the smoothed surface normal (upright in the air), two-bone
  IK legs from the hips to the shoes, the torso leaning with the crouch, arms out for balance (wide on a
  grind, reaching for the board in a grab), the board rolled for a flick, pitched for a wheelie or a kite.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): Marlo is already rolling at the kicker on
frame 0 (crouched, popping at the lip at 0.75 s, a grab and a twirl). The demo skates lines like the
player, through the same steering and pop code: it picks a feature (kicker, either quarter pipe, the rail
both ways, either ledge, over the fun box, through the bowl) by distance, turn and a little chance, heads
for its entry, pursues the line, crouches and pops at the right distance (for a rail: the ollie timed so
the descent crosses the bar), coasts to turn tighter while lining up, does flat-ground ollies on the way,
and picks tricks that fit the air time left, now and then one too many: it bails a few times a session.
Over five minutes: about 34 air tricks, 15 grinds (7 on the rail), 14 vert airs, 5 bails, banks up to
2700. It restarts 2 s after SESSION OVER. Demo off starts a fresh session waiting for the first click.

**Sound** (`sfx.as` presets, silent in demo mode; nothing decided by `api.rand()`): the start is a fanfare
and a latch click; the wheels tick on the concrete, sparser when slow and quicker and brighter with speed,
and every push stroke scuffs; an ollie is a pop with a tail click (brighter for a bigger wind-up); leaving a
lip clicks and a vert air whooshes; a spin is a whoosh (higher for a 360), a flick a quick high whoosh and
click, a grab a low whoosh; a clean landing is a board clack and a thud, louder for a harder landing, with
one note of the combo arpeggio; a grind is a scrape of quick alternating clicks every 3 frames with a zap
as it locks on; a bank plays a major arpeggio, one note more for each step of the multiplier (bells from
x3, a pop past x4); a bail is a thud, a crunch, a clatter and two falling notes; walls thud; the last five
seconds blip; the session ends with a falling four-note line, or a fanfare and bells for a new best.

## What is where

```
art/palette.json, palette.png   AAP-64 with 22 ramps (concrete, sand, grass, leaf, wood, skin, hoodie, beanie,
                                denim, white, deck, grip, wheel, steel, paint, mural, pink, lilac, dust, spark,
                                ember, sky); roles
art/assets.md                   the asset list, bones, splats, the layout
art/skater/                     the hero's Codex brief, sheet (v1) and its record, cut views (refs/)
models/skater/                  spec + gate record, make_skater.py -> p1_blockout.txt, p2_form.txt (skater.glb,
                                gated), p3_splat_fit.txt (skater_fit.glb, the bench's), p4_parts.txt (board,
                                torso, arm, thigh, shin, shoe GLBs), skater.bake.json, gate shots
models/env/                     make_env.py writes park.glb, yard.glb, dust.glb, spark.glb straight from Python
lookdev/                        the turntable bench (no RML): skater.bin
scene.bake.json                 the composition: park, yard, game bones (board, torso, arm x2, thigh x2, shin x2,
                                shoe x2, dust x8, spark x8), material -> ramp, the play-area bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        skater (framed), skater@scene (at the scene's texel), scene (demo_070: a kite
                                grab over the kicker; demo_668: a bail in the bowl; demo_7454: a rail grind;
                                frame_030: the hint before the first click)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from its sources
```

Game bones: 26 of 63. Splats: 94 037 in the scene blob (2.9 MB).

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene` (zsh):

```sh
./build.sh                                            # models/env, the skater (p1-p4), lookdev, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (the mesh gate is on p2; the splat gate on the p3 bench, with exact
view angles for this tall figure, see the spec):

```sh
python3 $K/scripts/golden.py views --hedra models/skater/skater.rmdl -o /tmp/sk_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/skater/refs --shots /tmp/sk_p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob skater -o /tmp/sk_alb --look albedo --views front,right,back,top --arg pitchMin=0 --arg pitchMax=90
python3 $K/scripts/golden.py gate --refs art/skater/refs --shots /tmp/sk_alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L=(--arg sunYaw=-50 --arg sunPitch=50 --arg keyLight=0.42 --arg highlight=0.85 --arg shadeSteps=1)
python3 $K/scripts/golden.py views --rive lookdev --blob skater -o /tmp/sk --real-sky $L && python3 $K/scripts/golden.py check --shots /tmp/sk --goldens goldens/skater
python3 $K/scripts/golden.py views --rive lookdev --blob skater -o /tmp/sks --texel 0.0588 --size 120 --real-sky $L && python3 $K/scripts/golden.py check --shots /tmp/sks --goldens goldens/skater@scene
for n in 70 668 7454; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --arg demo=true --advance=$n; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Play it headless with touch only (no hover): `rive scene --screenshot=$PWD/p.png --advance=3
--touch=down@320,200 --touch=up@320,200 --advance=90 --touch=down@330,190 --advance=28
--touch=up@330,190 --advance=6 --touch=down@330,190 --touch=move@330,150 --touch=move@330,90
--touch=up@330,90 --advance=14` taps to start, rolls into the kicker, winds up, pops at the lip and is
caught mid-FLICK high over the kicker. Sounds of the same run: swap `--screenshot` for `--render-audio=$PWD/p.wav`.
The hand-over from demo with `--commands`: `data demo=true`, `advance 240`, `data demo=false`, `advance 60`
(the hint, a fresh session waiting for the first click).

## Notes from building it

- The physics was ported to a throwaway Python sim first (the skill's games.md): it caught a lip test by
  curvature that fired early and re-landed in the next sub-step (now "the surface falls away faster than a
  thrown body"), finite-difference gradients across walls that turned a kicker's back edge into a
  near-horizontal normal and a 60 m/s "landing" (now analytic gradients of the surface that wins), and a
  4.6 m/s push that could never clear a 1.3 m quarter pipe (now 7 m/s and 1.2 m).
- A closed-loop test player (Python driving `--commands` with `touch` lines, reading a temporary state
  line from `game.as`) played whole sessions by touch (7 873 points; and 5 204 with two rail grinds and
  a ledge grind in its grind run). It found: a finger held still while steering re-armed the wind-up and
  the skater stopped pushing (now only a fresh press winds up); Rive delivers a touch press as a move then a
  down in the same frame, and a lift as an up then a move, which steered the skater to every tap (hover
  moves are now held to the end of the frame and dropped when a press follows, and the move after a lift
  is ignored); the bowl trapped a skater that stopped in it (pushing now works on gentle slopes, pumps are
  stronger, walls carve less).
- The demo's line-up flipped between "loop back" and "pursue" at a threshold and circled (now: go to the
  entry, then pursue the line, fall back only when turned away); its pursuit lookahead was longer than its
  turning circle at 7 m/s (now 0.35 s of travel); after a bail on a quarter pipe's deck it chased a point
  beyond the park's edge (a QP line is done once past its lip).
- In a bail the body vanished: its root matrix shared a scratch matrix the board then overwrote, and the
  tumble laid it into the steep wall (it falls downhill now, on a world-up root).
- The kicker was first painted the hoodie's red: the hero lost its accent; it is plywood now.
- Mural panels 1 cm off the wall shimmered (coplanar splats fight); they are boards 16 cm proud.
- The Codex sheet was not reviewed by a person yet (`art/skater/sheet.v1.png.json`, `reviewed: false`).
