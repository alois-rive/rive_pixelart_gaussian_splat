# Game: Cloud Putt (Taffy 16, 16 colours)

**How to play:** press anywhere, drag back and let go: the ball goes the other way, as hard as the
drag is long. Nine holes of mini golf on a floating cloud island; fewest strokes wins.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Taffy 16](https://lospec.com/palette-list/taffy-16) by
PineappleOnPizza, sixteen colours in 9 ramps (felt, cloud, wood, candy, water, gold, pit, spark,
spray); it loaded from Lospec, so the spare (`rose-bush`) was not needed. A floating island made of
cloud with a mini golf course on it: striped felt greens in orange wooden borders, a coral windmill
with a blue roof, a brook under a wooden bridge, candy-striped bumpers, sliding candy gates, a jump
over a gap in the cloud, lollipop trees, yellow pennants; a periwinkle sky turning peach below, clouds
drifting past. Orthographic, yaw 0, pitch 40, `orthoHeight` 7.6 m, `pixelSize` 3 (texel 0.056 m), the
camera gliding from hole to hole; a sun from the front left (yaw -35, pitch 55), per-splat dither,
ink 1. Shadows fall slate on the felt.

## Rules

- A round is the nine holes (par 26). Each hole starts on its peach tee pad; the camera glides there.
- **The putt**: press anywhere on the screen, drag back, let go. A dotted line from the ball shows
  where it goes (against the drag), a meter beside the ball and the line's length and colour show the
  power (the full meter is 50 art pixels of drag). A drag shorter than 3 % of that is no putt.
- **The ball**: rolls with friction (stronger the faster it goes), curves on the slopes of each
  green, bounces off the wooden borders (and harder off the bumpers), flies off a lip or a crest that
  falls away faster than it can follow, and lands with a hop. Into the cup only when slow enough: a
  faster ball rattles round the rim and lips out, a fast one skims over.
- **Water** (the brook, the pond) and **the cloud gap**: +1 stroke, and the ball comes back to where
  it was putted from.
- **At most 6 strokes a hole** (penalties count): the sixth that misses is "PICKED UP: 6".
- The verdict per hole: HOLE IN ONE! (a fanfare and confetti), EAGLE!, BIRDIE! (confetti), PAR,
  BOGEY, DOUBLE BOGEY, +n. The scorecard along the bottom fills in per hole (yellow an ace, lime
  under par, white par, peach a bogey, pink worse), with the total against the par played so far.
- After hole 9 the round's card: the score against par 26, strokes per hole under each par, and the
  session's best. The next click starts a new round (the camera glides back to hole 1).
- A round takes 2 to 3 minutes (nine holes: longer than the gallery's usual 20 to 90 second run).

**Touch** (phones): the pointer only moves while a finger is down, so nothing waits for a hover. The
press can land anywhere (the ball is only 6 art pixels across); the aim follows the finger while it
drags and the putt goes on the lift. A tap anywhere on the round's card starts the next round.
Tested with touch gestures only (`down@`, `drag@`, `up@`, `tap@`, never a bare `move@`): a full
round won that way, and a tap on the card starting the next.

## The holes

| # | Name | Par | What it is |
|---|---|---|---|
| 1 | THE MILL | 3 | a raised deck up to the windmill: putt through its tunnel while the sails (a quarter turn every 1.6 s) are not across it; behind the mill the lane slopes down into a lower pocket with the cup |
| 2 | THE HUMP | 2 | a long lane with a big hump just off its middle line, the far end rising a little |
| 3 | BROOK BRIDGE | 3 | a brook across the green, crossed by a 1 m wide arched bridge with no rails; both banks lean towards the water |
| 4 | SLIDING GATES | 3 | two candy blocks slide across the lane out of step (3.2 s and 2.6 s) |
| 5 | CLOUD GAP | 3 | a kicker ramp (0.42 m high) and a 1.4 m gap in the cloud: hit it hard enough to fly over, not so hard that the far wall sends it back in |
| 6 | STEP UP | 3 | two tiers joined by a ramp (0.5 m), the cup on the upper tier behind a short wall |
| 7 | BUMPER GARDEN | 3 | seven candy-striped bumpers across a lane that leans down towards the cup |
| 8 | DOGLEG BANK | 3 | an L with a cut corner to bank off; the long leg tilts, the short one runs downhill to the cup |
| 9 | SKY SUMMIT | 3 | the cup on top of a crown (0.3 m), a small dish round it, a pond in the near corner |

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the round starts at once; the first putt
(a fixed line, released at 0.6 s) rolls up the deck into the windmill's tunnel. After that the demo
plays like a decent human with the same physics: it searches 36 directions x 8 powers with a
simulation of each putt (the sails and gates at the moment it will let go), keeps the six best by a
path-distance map of the green, judges those by four nudged copies each (a shot that still works a
little off), then putts with a hand that is off by a few degrees and up to ~10 % in power, drawing
its drag, the dotted line and the meter like a player. The search is spread over the frames (at most
4000 physics steps a frame). It reads the slopes and the timing, misses some long putts, now and
then rims out or splashes into the brook; a round comes out about par (25 and 28 in the last two full runs
in Rive). Two seconds after the round's card it starts a new round. When demo is switched off, a fresh
round starts at hole 1 with the hint.

**Sound** (`sfx.as` presets, silent in demo; nothing is decided by `api.rand()`): the putt is a
click plus a low tock, brighter and louder with the power (a whoosh on top for a hard one); while
aiming, a soft tick for each tenth of power gained; wooden knocks off the borders (higher and
louder the harder, at most one per 4 frames), a blip and pop off a bumper, a thud off a gate, a
thwack off a sail, a thud for a landing; the cup's rattle (three falling ticks and a click) when the
ball lips out, and for a holed ball a rattle, a drop (a low thud) and a click; a splash (two layers)
for the water, a falling pew and a whoosh into the cloud gap; the windmill creaks as each sail swings
past the tunnel (two low ticks, a softer one halfway), louder the nearer the camera is to it; a
whoosh as the camera glides and a pop as the ball appears on the tee; per hole a hole-in-one fanfare
(a win chord, a seven-note run up in C and a bell), an eagle arpeggio, two rising notes and a bell for
a birdie, a fifth for par, falling notes for bogeys; and at the round's end a little eight-note tune
in C (brighter at par or better, with a win chord; a rising arpeggio for a new best).

## What is where

```
art/palette.json, palette.png   Taffy 16 with ramps felt, cloud, wood, candy, water, gold, pit, spark, spray; roles
art/assets.md                   the asset list, bones, layout
art/windmill/                   the hero's Codex brief, sheet and record, cut views (refs/)
models/windmill/                spec + gate record, p1_blockout.txt, p2_form.txt, p4_parts.txt (tower.glb, sails.glb),
                                windmill.bake.json (the bench, at the scene's density), gate shots, the GLBs
models/course/                  course.py (the nine holes as data: felt, walls, height-field terms, hazards, gates,
                                bumpers, pars), make_course.py (writes greens1-3, borders, cups, water, island .txt,
                                scene.bake.json and the course block of scene/game.as), sim.py (the Python port of
                                the physics and the demo player, used to tune the holes), the command files, GLBs
models/env/                     make_env.py writes ball, flag, gate, post, puff, tree, drop, spark, ripple .txt
lookdev/                        the turntable bench (no RML): windmill.bin
scene.bake.json                 the composition (generated): course, windmill, props, game bones, material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light, sky), game.as (the whole game), renderer
goldens/                        windmill (framed), windmill@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from its sources
```

Game bones: 33 of 63 (sails, 2 gates, 9 flags, the ball, 3 drifting clouds, 6 drops, a ripple, 10
sparks). Splats: 111 801 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # props, the windmill (p1, p2, p4), the course, both blobs
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
(cd models/windmill && rm -f windmill.rmdl && hedra model --text windmill.rmdl run p1_blockout.txt && hedra model --text windmill.rmdl run p2_form.txt)
python3 $K/scripts/golden.py views --hedra models/windmill/windmill.rmdl -o /tmp/wm_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/windmill/refs --shots /tmp/wm_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob windmill -o /tmp/wm_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/windmill/refs --shots /tmp/wm_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=-35 --arg sunPitch=55 --arg keyLight=0.4 --arg highlight=0.9 --arg shadeSteps=1)
python3 $K/scripts/golden.py views --rive lookdev --blob windmill -o /tmp/wm --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/wm --goldens goldens/windmill
python3 $K/scripts/golden.py views --rive lookdev --blob windmill -o /tmp/wm_s --texel 0.043 --size 400 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/wm_s --goldens goldens/windmill@scene
for n in 60 2008 4905; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

The demo goldens: 60, the first putt rolling up the deck towards the windmill; 2008, a splash in the
brook beside the bridge (hole 3); 4905, a hole in one on hole 6. `frame_030` is the hint before the
first putt.

Play it headless (touch or pointer): `rive scene --screenshot=$PWD/p.png --advance=30
--touch="drag@198,300>198,382:8" --advance=6s --touch="drag@314,237>266,211:8" --advance=5s` putts
through the windmill's tunnel into the pocket and holes the second putt: a birdie, the camera gliding
to hole 2. `--touch="drag@198,300>198,320:8"` is a soft putt that stops on the deck. Sound:
`rive scene --render-audio=$PWD/p.wav --advance=30 --pointer="drag@198,300>198,382:8" --advance=6s
--pointer="drag@314,237>266,211:8" --advance=6s`. The hand-over from demo to a player, with
`--commands`: `data demo=true`, `advance 400`, `data demo=false`, `advance 40` (a fresh round, the
hint), `touch drag@200,330>200,400:8` (a putt).

Tune a hole in the Python port first: `cd models/course && python3 sim.py rounds 4 3 9` (the demo
player plays holes 3 and 9 four times and prints the strokes), `python3 sim.py preview map.png` (a
top-down map of the course). Then `./build.sh`.

## Notes from building it

- One course file drives everything: `course.py` holds each green as felt rectangles, wall
  polylines, hazards and a height field written as terms (smoothsteps, ramps, a kicker, the bridge's
  arch, bumps); `make_course.py` turns the terms into hedra expressions (`attribute set position
  "vec(pos.x, pos.y, ...)"` on a 0.1 m grid) and into the arrays of `game.as`, so the felt you see and
  the slope the ball feels are the same function.
- A single hedra run over all nine greens took long enough to be stopped ("the program stopped
  responding"); three files of three greens, each shading its own object, run in seconds.
- The windmill's tunnel: hedra's boolean left the cutter's remains wherever the cutter crossed the
  tower's bottom cap, and ragged slivers above; the tunnel is built instead from bisect planes (the
  doorway's faces deleted) and an inward-facing liner. Bisect and `select where` read object-local
  positions: the tower's location had to be applied first, or the cut lands a metre up.
- The sails' GLB kept the hub as its node's translation and the bake added the entry's position on
  top: the sails orbited a point below the hub. The part's origin is at the hub and the object moved
  to the world origin now.
- The first windmill (as modelled, pitch 55) read as a roof with white blobs; at 1.3 times its size
  and pitch 40 it is the hero of hole 1 and the gallery's first frame.
- Taffy 16 has one green and one lime, and the designer's ramp shades green into blue: the windmill's
  shadow on the felt read as puddles of water. The felt ramp shades into slate instead.
- Cups near walls and corners let strong putts trickle back in off the wall (a 67 % ace rate on the
  hump); every cup is at least 1.2 m from a wall now, the capture speed is 1.15 m/s, and a lip-out
  cannot be captured on the same pass. A hump plus a tilt once made a gutter straight to the cup.
- A ball held against a wall by a slope never met the "at rest" test (the slope's pull stayed above
  the static friction); slow for 0.6 s counts as at rest now (in `sim.py` too).
- The demo's search ran 18 simulated putts a frame and tripped the 200 ms script limit (scripts run
  interpreted headless); it now spends at most 4000 physics steps a frame (about 15 ms in the release
  build) and settles for its best so far if the release time comes first. Sixteen parallel captures
  on one machine froze a run at 6000.
- The pixel font draws W like H: holes are named without W (THE HUMP, STEP UP, SKY SUMMIT).
- The Codex sheet was not reviewed by a person yet (`art/windmill/sheet.v1.png.json`, `reviewed:
  false`).
