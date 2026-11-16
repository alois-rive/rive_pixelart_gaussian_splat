# Game: Corner Pocket (Chromatic16)

**How to play:** on your shot, press anywhere and drag back behind the cue ball (the cue follows your
finger or pointer and aims through the ball, the drag's length is the power), then release to strike;
pot your set, then the night ball, before Nell does.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Chromatic16](https://lospec.com/palette-list/chromatic16), 16
colours (black, grey-teal, white, maroon, red, brown, orange, peach, yellow, green, lime, navy, blue,
cyan, purple, pink) in 14 ramps; it loaded from Lospec, so the spare (`neon-space`) was not needed.
The corner of the Crooked Lamp, a pub at night: a green-felt table under a long hanging lamp whose
underside glows, a back wall of navy wallpaper over a dark wainscot, a window onto a crescent moon and
the roofs, a pink neon moon, a dartboard, red bar stools, a pint on a side table, and Biscuit the pub
cat asleep on a stool, flicking her tail when a ball drops. Orthographic, yaw 0, pitch 48,
`orthoHeight` 2.8 m, `pixelSize` 2 (texel 0.014 m: a ball is about 7 art pixels), the lamp as the one
light (sun yaw -15, pitch 76, `shadeSteps` 2 so shaded walls drop one clean step), per-splat dither,
ink 1, a flat black sky.

## Controls (pointer only; touch-ready)

- **Aim and shoot**: press anywhere on your shot, drag, release. While you hold, the cue lies on the
  line from your finger through the cue ball (go round the ball to turn it), and the drag's length
  from where you pressed sets the power (the POWER meter: 70 HUD pixels, about 140 screen pixels, is
  full power). A dotted line runs to the first ball the cue ball will touch, a ring marks the ghost
  ball there, a coloured line shows where that ball goes (pink, with FOUL, if it is not a legal first
  ball) and a grey dotted one where the cue ball glances off. Release with almost no drag to cancel.
- **Ball in hand**: tap where the cue ball goes (it lands exactly there), or drag it and let go:
  while dragged it is held 12 art pixels (`24 / pixelSize`) above the finger so the finger does not
  hide it. It blinks where it cannot go (on another ball) and stays in hand.
- **Next frame**: click (tap) the result panel.
- On touch nothing needs a hover: the aim, the guide and the power exist only while a finger is
  down, and placing the cue ball is a tap. A touch-only test (only `touch down/move/up`, `touch drag`
  and `touch tap`, no bare moves) won a frame against Nell (below).

## Rules (the Crooked Lamp's house rules)

- Seven **suns** (yellow), seven **moons** (blue), the dark **night ball**, and the white cue ball
  (two red dots). You break the first frame; the break alternates after that.
- The table is open until somebody pots a ball: the first ball you pot (the break counts) claims
  its set for you, the other set is Nell's. On an open table any ball but the night ball may be hit
  first.
- Pot one of yours and you shoot again; otherwise it is the other side's shot (a ball of theirs you
  pot stays down for them).
- **Fouls** give the other side the cue ball in hand, anywhere on the table: the cue ball potted, no
  ball hit, or the first ball hit not one of yours (the night ball first while you still have balls).
- With your set cleared you are **on the night ball** (it must be hit first). Pot it cleanly and you
  win the frame; pot it before your set is cleared, or with a foul, and you lose it. A night ball
  potted on the break goes back on the spot.
- The result panel shows who took the frame and why, the frames won (`FRAMES 2 - 1`) and the best
  run of frames you won in a row this session; the next click racks a new frame.

**The physics** (`game.as`, first tuned in a Python port): balls 9 cm across on a 2.0 x 1.0 m bed;
rolling friction 0.62 m/s² plus a little drag; ball-ball collisions along the line of centres,
restitution 0.94 (equal masses); cushions are six segments between the pocket mouths, their ends the
jaws (a ball hits the nearest point: a flat cushion or a jaw's point), restitution 0.72; a ball whose
centre comes within 7 cm of a pocket (or slips past the jaws) drops in: it slides to the pocket's
middle and sinks under the rim. 480 sub-steps a second. Each ball's orientation turns about the axis
across its motion by distance / radius every frame (kept as a 3 x 3 matrix, handed to `place` as
yaw, pitch and roll), so the spots at its poles roll.

**Nell** (the computer, and both sides in the demo): for every legal ball and pocket she finds the
ghost-ball point, rejects cuts past ~75 degrees, blocked lines (to the ghost and on to the pocket)
and square-on misses into side pockets, scores the rest by cut angle and both distances, and hits the
best with the speed the distances need. Her aim error is a triangular ±1.3 degrees (so long thin cuts
miss), she sometimes lands a tight shot from a looser search, and plays a soft half-ball safety on
one of her balls when nothing is on (or now and then by choice). With ball in hand she tries 40 spots
and takes the one with the best pot. In sixteen simulated frames she potted 63 % of her attempts and
a frame took 20 to 40 shots.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): Alf (the left-hand regular) and Nell play
a full frame against each other, the same player with a slightly looser aim for Alf; Alf breaks
within the first second (the cue strikes at about 0.6 s), a frame lasts about 60 to 85 s (five minutes
of demo: four frames, two each, all won on the night ball), and the next frame racks itself two
seconds after the result. When demo is switched off, a fresh match starts with your break and the hint.

**Sound** (`sfx.as`, silent in demo mode, never decided by `api.rand()`): the cue's strike is a click
and a low thud, both louder and brighter with the power (a whoosh on the break); ball clacks are a
tick and a click pitched and levelled by the impact speed (the hardest of each frame, rate limited);
cushions thud by how hard they are hit; a pocket rattles (three ticks and a click knocking round the
iron) and drops with a thud; each of your balls potted in a visit rings a bell a tone higher; a set
claimed is a coin; a foul is a low double buzz; your turn a soft blip; a frame won the win arpeggio
and a rising tune, a frame lost the lose jingle and four falling notes; a new rack whooshes and its
balls click together.

## What is where

```
art/palette.json, palette.png   Chromatic16 with ramps felt, wood, hole, glow, cue, sun, moon, night, wall,
                                leather, neon, sky, spot, dot; roles (black sky and void)
art/assets.md                   the asset list, bones, layout
art/table/                      the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/table/                   spec + gate record (and the elevation waiver), make_table.py -> p1_blockout.txt,
                                p2_form.txt; table.glb (the hero), table_body.glb + lamp.glb (the scene's pieces),
                                table.bake.json, gate shots
models/env/                     make_env.py writes floor, wall, window, dart, neon, stool, sidetable, cat, tail,
                                cue, ball_cue, ball_sun, ball_moon, ball_night, chalk .txt (hedra command files)
                                and textures/ (boards, paper, panel, night, dartboard); their GLBs
lookdev/                        the turntable bench (no RML): table.bin
scene.bake.json                 the composition: the room, the table, game bones (lamp, tail, cue, cueball,
                                sun0-6, moon0-6, night), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        table (framed), table@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 19 of 63. Splats: 77 927 in the scene blob (2.4 MB).

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the table (p1, p2), lookdev/table.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/table/table.rmdl -o /tmp/t_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/table/refs --shots /tmp/t_p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob table -o /tmp/t_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/table/refs --shots /tmp/t_alb -p art/palette.json --min-iou 0.7   # right: see the waiver
python3 $K/scripts/golden.py views --hedra models/table/table.rmdl -o /tmp/t_el5 --views front,right,back --elevation 5
python3 $K/scripts/golden.py gate --refs /tmp/t_el5 --shots /tmp/t_alb --min-iou 0.7 --max-aspect-drift 0.08    # the splats vs the mesh at 5 degrees
L=(--arg sunYaw=-15 --arg sunPitch=76 --arg keyLight=0.45 --arg highlight=0.985 --arg shadeSteps=2)
python3 $K/scripts/golden.py views --rive lookdev --blob table -o /tmp/t --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/t --goldens goldens/table
python3 $K/scripts/golden.py views --rive lookdev --blob table -o /tmp/t_s --texel 0.0139 --size 400 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/t_s --goldens goldens/table@scene
for n in 050 200 5060; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --arg demo=true --advance=$n; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 2; done
```

(The last gate reports `missing top.png`: the 5-degree mesh views have no top; the top view is gated
against the sheet in the line before.)

Goldens: `demo_050` (Alf's break landing in the rack), `demo_200` (Nell lining up: the cue, the
dotted guide, the ghost ball and the object ball's line), `demo_5060` (the first demo frame's end:
ALF TAKES THE FRAME, the night ball, clean), `frame_030` (your break, the cue on the line to the
rack and the two-line hint). Frame audit: 100 % solid 2 x 2 blocks, 14 colours, 0 off-palette.

Play it headless (a point (x, z) on the felt is at about (320 + 144 x, 249 + 107 z) on the 640 x 400
artboard; the cue ball starts near (248, 252)): the break, drawn back at full power and released:
`rive scene --screenshot=$PWD/b.png --advance=10 '--touch=drag@40,252>176,252:10' --advance=24`.
With the mouse it is the same gesture (`'--pointer=drag@40,252>176,252:10'`); a held drag (`down@`,
then `move@`s) shows the guide and the meter. Hear it: the same with `--render-audio=$PWD/b.wav
--advance=7s`. The demo-to-player hand-over: `printf 'data demo=true\nadvance 400\ndata
demo=false\nadvance 30\nscreenshot /tmp/h.png\nquit\n' | rive scene --commands` shows your break and
the hint over a fresh rack.

A closed-loop test (a Python player driving `rive scene --commands` with touch gestures only, reading
the state the game printed through a temporary `console.log`, since removed) placed the cue ball by
tap once and by drag once, and won a frame 1-0 in 14 shots.

## Notes from building it

- The Codex sheet drew the lamp 0.5 m over the felt; from a camera high enough to see the whole bed
  it hid the far third of the table, so the scene hangs it 0.42 m higher (its own GLB and bone, the
  pivot at the cords' top). Seen from above an all-green shade read as a second table, a lime one as
  a slab of light and an orange one as a flat block: the shade's top face got its own material in the
  hero (same green, gates unchanged) and the scene bakes it a step down (navy), so top, slopes and
  glowing rim read as a solid lamp.
- The sheet's glow strip (3 cm, inset) vanished behind the shade's lower edge from 48 degrees: it is
  now the shade's whole footprint and 6 cm deep.
- With `shadeSteps` 1.5 the back wall (lit at about 0.23) sat exactly on a band edge and turned into
  a two-tone stipple; 2 steps drop it cleanly one step (blue wallpaper to navy); the apron is baked a
  step up so its shaded front is maroon, not black.
- The corner jaws first left a 1 cm lane into a corner pocket (the Python port potted nothing in 16
  breaks): the mouths widened to 0.13 m from each corner and 0.17 m across the side pockets. Breaks
  still rarely pot a ball.
- The CLI's synthetic touch (`touch tap@`, `touch drag@`) sends a move before the press, which sets
  `api.hoverSeen` as for a mouse: the ball-in-hand lift is decided by the gesture (a press that moves
  more than 3 HUD pixels) instead of by `hoverSeen`.
- The floor's brown boards drew loud stripes across the frame; it is maroon boards with dark joints.
- `--arg demo=true` and `data demo=true` give different demo runs (the second starts with a
  `demoChanged` re-rack and draws more random numbers): goldens use `--arg`.
- The Codex sheet was not reviewed by a person yet (`art/table/sheet.v1.png.json`, `reviewed: false`).
