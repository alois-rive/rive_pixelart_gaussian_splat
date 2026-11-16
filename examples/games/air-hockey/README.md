# Game: Air Hockey (SLSO-CLR17)

**How to play:** the pointer is your orange mallet: click to face off, then knock the glowing puck
into the computer's goal on the right; first to 7 wins.

**Touch:** tap to face off, then drag: the mallet follows a point a few pixels above your finger (so the
finger hides neither it nor the puck) and stays where you lift.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [SLSO-CLR17](https://lospec.com/palette-list/slso-clr17) by Luis
Miguel Maldonado, 17 colours (ink and slate greys, mint, teal, blue, greens, yellow, orange, red,
plum, purple, pink, ice) in 11 ramps; it loaded from Lospec, so the spare (`fantasy-24`) was not
needed. A neon air hockey table under one overhead lamp in a dark arcade: a teal rink with ice and
mint markings, pink rails drawn unlit so they glow, a glowing yellow puck, four cabinets whose
screens and marquees glow at the back while the room dissolves into the dark (Bayer fog towards the
ink void colour). Orthographic, yaw 0, pitch 50, `orthoHeight` 4.6 m, `pixelSize` 3 (texel
0.034 m), lamp at yaw -25, pitch 64, per-splat dither, ink 1.

## Rules

- One verb: move the pointer. Your mallet follows it (up to 12 m/s, kept in your half); the puck
  bounces off the mallets, the rails and the goal posts on an almost frictionless table (top speed
  10 m/s), and spins and leaves a trail when it is fast.
- Click to face off: the puck drifts to your side. After each goal the side that conceded serves
  from its own half.
- Each of your goals scores 100 + up to 60 for a fast shot (`SLAP SHOT`); winning the match adds
  300. The computer's goals score nothing for you.
- The computer is a bot: it defends on the puck's predicted line from a stale read, sets up behind
  a slow puck and strikes it at a corner or off a side rail. It warms up over a match's first 9
  seconds (an early goal is there to take), plays tighter the further you lead and looser when it
  leads, and now and then is caught out by a shot (a late, wide read).
- A puck that stays in one spot (dead, or pinned in a corner) gets a puff of air after 2.5 s.
- First to 7: `YOU WIN 7-2` or `CPU WINS 3-7` with the score and the session's best; the next click
  starts a new match at the same table. A driven match (a scripted player that tracks the puck)
  won 7-1 and 7-2 in about 35 and 75 s of play; standing still loses 0-7 in about 40 s.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the left mallet is the same bot as the
computer, a little slower and as accurate, so the matches are close (ten minutes of demo: 6-7, 7-6,
4-7, 7-6, 7-5, 2-7, 6-7, 5-7) and both sides miss; a match lasts about 50 to 80 s. The puck is already sliding at frame 0, the first
strike lands within a second, and the first goals fall at about 5.8 s and 7.6 s. It restarts by itself
two seconds after the final whistle. When demo is switched off, a fresh match waits for the first
click (the hint).

**Sound** (`sfx.as`, silent in demo mode): an air whoosh and a blip at each face-off; a plastic clack
on every strike (brighter and louder the harder, a neon zap on a slap), a dry tick off the rails and
posts (rate limited); your goal is a coin that climbs a whole tone per goal (a fanfare on a slap
shot), the computer's a crunch and two falling notes; a thud as the puck drops in the pocket; a win
plays an arpeggio and a rising tune, a loss the lose jingle.

## What is where

```
art/palette.json, palette.png   SLSO-CLR17 with ramps steel, rink, neon, cpu, player, puck, leaf, carpet,
                                screen, spark, pspark; roles (sky and void ink)
art/assets.md                   the asset list, bones, layout
art/table/                      the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/table/                   spec + gate record (and the elevation waiver), make_table.py -> p1_blockout.txt,
                                p2_form.txt, textures/rink.png; table.glb, table.bake.json, gate shots
models/env/                     make_env.py writes floor (textures/carpet.png), cabinet, stool, plant,
                                mallet_p, mallet_c, puck, spark .txt (hedra command files); their GLBs
lookdev/                        the turntable bench (no RML): table.bin
scene.bake.json                 the composition: the room, the table, game bones (malletP, malletC, puck,
                                ghost0-3, spark0-9, pspark0-9), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, lamp, fog), game.as (the whole game), renderer
goldens/                        table (framed), table@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 27 of 63. Splats: 44 306 in the scene blob.

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
python3 $K/scripts/golden.py gate --refs art/table/refs --shots /tmp/t_alb -p art/palette.json --min-iou 0.7   # sides: see the waiver
python3 $K/scripts/golden.py views --hedra models/table/table.rmdl -o /tmp/t_el5 --views front,right,back --elevation 5
python3 $K/scripts/golden.py gate --refs /tmp/t_el5 --shots /tmp/t_alb --min-iou 0.7 --max-aspect-drift 0.08    # the splats vs the mesh at 5 degrees
L=(--arg sunYaw=-25 --arg sunPitch=64 --arg keyLight=0.45 --arg highlight=0.93)
python3 $K/scripts/golden.py views --rive lookdev --blob table -o /tmp/t --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/t --goldens goldens/table
python3 $K/scripts/golden.py views --rive lookdev --blob table -o /tmp/t_s --texel 0.0338 --size 400 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/t_s --goldens goldens/table@scene
for n in 090 358 470; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --arg demo=true --advance=$n; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

(The last gate reports `missing top.png`: the 5-degree mesh views have no top; the top view is gated
against the sheet in the line before.)

Goldens: `demo_090` (an early rally: a strike, sparks, the puck's trail), `demo_358` (the demo's
first goal: GOAL! +140, a burst of yellow sparks at the pocket, the camera shaking), `demo_470` (the
computer's reply: CPU SCORES, pink sparks), `frame_030` (the hint before the first click). Frame
audit: 100 % solid 3 x 3 blocks, 16 colours, 0 off-palette.

Play it headless: `rive scene --screenshot=$PWD/p.png --advance=5 --pointer=click@150,250 --advance=38
'--pointer=drag@150,250>330,262:6' --advance=12` (a click to face off, then a swipe through the puck:
sparks at the mallet, the trail across to the computer's mallet). The demo-to-player hand-over:
`printf 'data demo=true\nadvance 400\ndata demo=false\nadvance 30\nscreenshot /tmp/h.png\nquit\n' |
rive scene --commands` shows the hint over a reset table. World to pointer: a point (x, z) on the rink
is at about (318 + 89 x, 249 + 68 z) on the 640 x 400 artboard.

## Notes from building it

- `golden.py views --rive` renders its side views 5 degrees from above: the renderer clamps the
  orbit pitch to `pitchMin` (5) every frame and does not read `pitchMin` from `--arg`. A long flat
  table shows its whole rink at that angle, so the splat gate's side-view aspect drift (0.2 to 0.3)
  is measured against the mesh at the same angle instead and waived (`table.spec.md`).
- The first bots never let a goal in (2 goals in 150 s of demo): a centred mallet plus the puck
  covered the whole 0.76 m mouth. The mallets are now baked at 0.86 scale (radius 0.19), the
  defender reads the puck's line only every ~0.3 s with an error that grows with the puck's speed,
  and is sometimes caught out; the puck's top speed went from 8.5 to 10 m/s.
- A pinned puck (pressed into a corner by a mallet) jittered too much for a "slow puck" test: the
  air puff now fires on a puck that stays within 0.3 m for 2.5 s.
- The demo's opening face-off once slid straight past the demo mallet into its own goal at 1.2 s:
  the opening puck now starts slower (1.6 m/s) a little nearer the demo mallet.
- One cabinet model is mapped to several ramps for variety (`cpu`, `steel`, `player` bodies;
  `screen` or `leaf` screens; `neon`, `puck` or `screen` marquees), so the bake warns that its
  colours are far from some of those ramps: each lands on that ramp's nearest step on purpose.
  Lifting the cabinets a step (`"step": 1`) made their lit tops the loudest shapes in the frame;
  they stay dark and the screens glow.
- The Codex sheet was not reviewed by a person yet (`art/table/sheet.v1.png.json`, `reviewed: false`).
