# Game: Crane Claw (Peachy Pop 16)

**How to play:** move the pointer to steer the claw over the toy pile and click to drop it; a grab near
a toy's middle holds, an edge grab wobbles and may slip. Win as many prizes as you can in 60 seconds.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [Peachy Pop 16](https://lospec.com/palette-list/peachy-pop-16)
by Kerrie Lake, 16 colours in ten ramps; it loaded from Lospec, so the spare (`marshmellow32`) was not
needed. The inside of a pink arcade claw machine seen through its glass: candy-stripe wallpaper with pale
stars, chase-light bulbs along the back wall, a ball pit in blues and lilac, a yellow and red prize chute
in the front-left corner, chrome rails and a red trolley above, and a heap of toys (rubber ducks, pink
teddy bears, white bunnies, beach balls and one mint gem). A fixed perspective camera (fov 33),
`pixelSize` 3, one light from above and slightly in front (yaw -15, pitch 68) so the claw's shadow falls
on the pile where it will land, `shadeSteps` 1, per-splat dither, ink 1.

## Rules

- One verb: point and click. The claw follows the pointer over the pile on its gantry (2.3 m/s; a white
  cross on the pile marks where it will land). A click drops it as soon as it reaches the pointer (a tap
  on a touch screen aims and drops at once).
- The claw drops onto whatever is under it, swings its three prongs shut (eight stepped poses) and
  lifts. The nearest toy within 0.26 m of the claw's middle is taken; the closer to its middle, the
  surer the hold (a centred grab holds about nine times in ten, an edge grab one time in four; the ball
  and the gem are slipperier) and the smaller the swing. A loose grab
  swings hard and may slip on the way up or across (SLIPPED!): the toy falls, bounces and stays where it
  lands. An empty grab is a MISS.
- A held toy is carried to the chute and let go: duck and ball 10, bear and bunny 20, the gem 50, with
  confetti. A toy that slips into the chute by luck counts too. A new toy drops into the pile from above
  (the gem only after 14 s).
- 60 seconds from the first drop; the chase lights speed up and the clock blinks in the last ten. A grab
  under way when time runs out still finishes (LAST GRAB!). TIME UP shows prizes, score and the session's
  best; the next click starts a new run in the same machine (the toys stay where they are).

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the clock runs at once and the claw starts
right above a toy and drops within the first second. The demo player picks a toy by value and distance
(with some whim), steers to it with an aim error (about one grab in three lands on an edge or beside the
toy), pauses a moment and drops. Its first grab of a run is careful and always holds, so the showcase
sees a prize land (the gem, +50, at 3.7 s; a ball slips at 6.7 s). A run has about 11 prizes, half a
dozen slips and two to four misses (230 to 300 points); it restarts two seconds after TIME UP. When demo
is switched off, a fresh run waits for the first drop.

**Sound** (`sfx.as`, silent in demo mode): a coin in the slot at the first drop; the gantry's motor ticks
every 7 frames while it travels; the claw winds down, its prongs snap shut, the winch pulls it up; a
grab blips brighter the nearer the middle, an empty claw plays two falling notes, a slip a whoosh and an
"aww" (three falling notes); toys land on the pile with a thud by kind (the gem rings higher). A prize is
a coin and the next note of an arcade jingle (one step up the scale for each prize of the run; the gem
adds a power-up and a bell). The last ten seconds tick, higher each second; TIME UP plays a fanfare and
a run up the prize scale if anything was won, the lose jingle if not.

## What is where

```
art/palette.json, palette.png   Peachy Pop 16 with ramps cabinet, chrome, duck, peach, lilac, mint, rose, red, glow, ink
art/assets.md                   the asset list, bones, layout
art/claw/                       the hero's Codex brief, sheet (v1) and record, cut views (refs/), gate_palette.json
models/claw/                    spec + gate record, make_claw.py -> p1_blockout.txt, p2_form.txt, p3_splat_fit.txt,
                                p4_parts.txt; claw.glb (gated), claw_hub.glb + claw_prong.glb + claw_cable.glb (the
                                game's parts), claw.bake.json, gate shots
models/env/                     make_env.py writes cabinet, bulbs_a, bulbs_b, pit, bridge, trolley, duck, bear, bunny,
                                ball, gem, confetti_y, confetti_m .txt (hedra command files) and textures/wallpaper.png;
                                their GLBs; pile.json (the mound the game shares)
lookdev/                        the turntable bench (no RML): claw.bin
scene.bake.json                 the composition: the static cabinet and pit, game bones (bulbsA, bulbsB, bridge, trolley,
                                hub, prong x3, cable, duck x4, bear x3, bunny x2, ball x3, gem, confy x4, confm x4)
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        claw (framed), claw@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 30 of 63. Splats: 62 023 in the scene blob (the cabinet 35 202, the pit 15 618).

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the claw (p1-p4), lookdev/claw.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh; the mesh gate is taken on p2, the splat gate on p3):

```sh
(cd models/claw && rm -f /tmp/claw_p2.rmdl && hedra model --text /tmp/claw_p2.rmdl run p1_blockout.txt && hedra model --text /tmp/claw_p2.rmdl run p2_form.txt)
python3 $K/scripts/golden.py views --hedra /tmp/claw_p2.rmdl -o /tmp/claw_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/claw/refs --shots /tmp/claw_p2 --min-iou 0.75          # right: waived (spec)
python3 $K/scripts/golden.py views --rive lookdev --blob claw -o /tmp/claw_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/claw/refs --shots /tmp/claw_alb -p art/claw/gate_palette.json --min-iou 0.7   # right, top: waived
L=(--arg sunYaw=-15 --arg sunPitch=68 --arg shadeSteps=1 --arg highlight=0.82)
python3 $K/scripts/golden.py views --rive lookdev --blob claw -o /tmp/claw --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/claw --goldens goldens/claw
python3 $K/scripts/golden.py views --rive lookdev --blob claw -o /tmp/claw_s --texel 0.0275 --size 120 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/claw_s --goldens goldens/claw@scene
for n in 160 220 400; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
python3 $K/scripts/palette.py audit models/env/textures/wallpaper.png -p art/palette.json --ramp cabinet --max-colors 4
```

The goldens: `demo_160` (the gem carried to the chute, swinging), `demo_220` (+50 GEM! and confetti
over the chute), `demo_400` (a ball SLIPPED! on its way), `frame_030` (the hint). Every frame: 100 % solid
3 x 3 blocks, 0 off-palette.

Play it headless: `rive scene --screenshot=$PWD/p.png --advance=3 --pointer=click@304,285 --advance=300`
(the claw travels to the bear in the middle, grabs it and drops it in the chute: SCORE 20);
`--pointer=click@515,298` wins the front-right duck (10), `--pointer=click@448,284` a ball (10),
`--pointer=click@300,270` drops between toys (MISS). The demo's clock runs out at frame 3600; the grab
under way finishes (LAST GRAB!), then TIME UP, and a new run starts two seconds later.

## Notes from building it

- The side walls first came out as noisy two-tone dither: with `shadeSteps` 1.5 a wall facing away from
  the light sits exactly on a band edge (1.5 steps down). `shadeSteps` 1 gives clean walls.
- The camera started further back with the frame round the glass in view and its bulbs on it: the
  machine's inside filled half the picture. It moved in to 6.2 m; the bulbs went onto the back wall and
  the cabinet was made shallower (2.45 m) so the side walls do not swallow the frame.
- The wallpaper's stars were first yellow: the baker snaps a texture into its material's ramp, so they
  came out pink with colour error 0.018. They are the cabinet ramp's palest pink now.
- The claw's thin chrome bars baked a disc radius fatter (splat IoU 0.67-0.70); `p3_splat_fit.txt` pulls
  their faces in (`shrink-fatten`), keeping `p2_form.txt` as the mesh gate's model (the skill's
  p3_splat_fit phase).
- The game's cable is one 3.5 m bone scaled down to reach the trolley (a bone's scale moves splats
  closer, never apart, so it is baked long).
- The demo first went for the gem every time (it is worth five ducks): six gems and 300 points a run. Its
  choice now weighs the square root of the value, and a won gem comes back only after 14 s. With a
  0.32 m grab radius almost any drop into the dense pile found some toy's middle (13-14 prizes, no
  misses): the radius is 0.26 now and holds are less certain.
- The Codex sheet was not reviewed by a person yet (`art/claw/sheet.v1.png.json`, `reviewed: false`).
