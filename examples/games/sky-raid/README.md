# Game: Sky Raid (Fantasy 24)

**How to play: click (or tap) to take off; the biplane follows the pointer (on a phone, drag your finger)
and fires by itself: shoot the balloons, drones, gunboats and the airship, dodge their shots.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra
0.1.0, codex-cli. Palette: [Fantasy 24](https://lospec.com/palette-list/fantasy-24) (loaded from Lospec, no
author listed there; the spare `zughy-32` was not needed), 24 colours in 13 ramps. A late-summer afternoon
seen from 60 degrees up: a patchwork of wheat, ploughed land, meadow and pasture with hedgerows, villages
with red roofs, dark woods and teal rivers scrolling under a cream and orange biplane; the sun from the upper
left of the screen, so every flying thing drops a splat shadow down and to the right on the fields.

Rules: the first click (or tap) starts a run; the plane steers towards the pointer with a little lag and
banks into its turns, and fires twin bolts on its own while the run is on. Waves come in a loop: balloons
drifting down (they drop slow aimed shots), a V of drones diving in and peeling off, a river with a
gunboat (its turret tracks the plane and fires a three-shot spread), a line of drones sweeping across on a
wave, a second river with a pair of diving drones, then the boss: an armoured airship that patrols broadside,
turns nose-down at each end, fires aimed pairs from its two turrets, fans five shots from its gondola and
launches drones; below half strength it fires faster. Each shot is telegraphed by a closing ring over the
shooter. The gold supply balloon drops a crate on a parachute: fly into it for a wider shot (twin, then 3,
then 5 bolts; at full power +500). A hit costs a life and a power level and clears the bullets in the air;
the plane comes back from the bottom edge, blinking and safe for 2.4 s. Three lives; after the boss the loop
repeats faster (scroll, enemies, bullets and fire rate up, the boss tougher), so every run ends. Score:
balloon 100, supply balloon 150, drone 50, gunboat 250, airship 2000 x the loop. The game-over line shows
the score and the best of the session; the next click (or tap) flies again in the same world.

Touch: on a phone the pointer moves only while a finger is down. A tap starts the run and puts the plane's
target at the finger; dragging steers it. While the finger is down the plane flies 1 m (about 12 art
pixels) above the touch point, so the finger never hides it; when the finger lifts, the plane holds where it
was. Nothing needs hovering, and there are no buttons to hit (any tap starts or restarts a run). With a
mouse, moving the pointer is enough.

Sound (`sfx.as`, silent in demo mode): a run starts with a fanfare and a rising C-major arpeggio; the guns'
rattle is a quiet tick every other volley; a hit on a balloon or a boat clicks (rate-limited), a hit on the
airship ticks lower as it weakens; a kill pops (balloon) or bursts (drone, gunboat with a splash), with a
note that climbs a pentatonic run for kills in quick succession; enemies firing zap, a gunboat's shot thumps;
diving drones whoosh in; the supply crate's release blips and catching it plays the power-up with a high
note; the boss is announced by a two-tone bell siren and dies in a chain of five bursts, a boom and a win
jingle; losing a life crunches and booms; a new loop rings three bells; game over plays the falling
arpeggio, with a high bell for a new best. No sound is decided by `api.rand()`.

Demo (`--arg demo=true`, the gallery's `Sample.demo`): a run starts at once with two balloons already in
view and the guns firing (a first kill within the first second). The demo's hand goes for the crate, else lines up
under the lowest enemy (with a little lead and error), keeps to the lower half, and steps out of the way of
bullets it has seen for 0.34 s, misjudging their speed a little; now and then it loses focus for half a
second to a second and its hand stops: that is when it gets hit. Runs last about 1.5 to 4 minutes (loops 1
to 4); two seconds after a game over it starts again. Turning demo off starts a fresh run at once.

What moves (59 game bones of 63, no baked tracks: everything is placed by `scene/game.as`): the plane and its
propeller (a stepped 57-degree turn a frame reads as a spinning blur); 8 terrain tiles; 14 twin-bolt shots;
12 enemy bullets (rising from where they were fired to 3 m, so they always show over the plane, pulsing);
3 balloons and the supply balloon; 2 gunboats and their turrets; 6 drones; the airship and its 2 turrets;
5 pops; the crate.

How the world scrolls: the camera flies forward (`targetZ` decreasing) and the renderer snaps it to the art
grid, so the ground slides by whole screen pixels. The ground is eight 16 x 6 m tiles (two fields, two
villages, two woods, two rivers, all different), laid ahead of the camera in a random order (never the same
kind twice running, rivers only when a wave asks for a gunboat) and freed when they pass the bottom. Every
12 m the world wraps (the camera and every tile jump back 12 m), so the play stays inside the bake's
`bounds` and the shadow map for any run length; `orthoHeight` 9.549657 makes the wrap exactly 148 art rows,
so it changes no pixel. Everything in the air lives in "logic" coordinates (u across, v down the screen, on
the ground plane the pointer meets) relative to the snapped camera's ground point, and is drawn at its
altitude h at z = ground + v + h cot 60, snapped to the art grid: a sprite holding still never crawls, and
collisions are simple 2D circles.

```
art/palette.json, palette.png   Fantasy 24 with 13 ramps (grass, leaf, wheat, soil, water, roof, wall, canvas,
                                paint, metal, glow, shot, foe)
art/assets.md                   the asset list: sizes, ramps, bones (59 of 63), splats (93 056)
art/plane/                      the hero's Codex brief, sheet (v1) and record, cut views (refs/), gate_palette.json
models/plane/                   spec + gate record (waivers), p1_blockout, p2_form, p3_splat_fit, p4_body / p4_prop,
                                bake file, gate shots, GLBs
models/env/                     make_env.py writes the command files of the 8 tiles and every game piece; their GLBs
lookdev/                        the turntable bench (no RML): plane.bin
scene.bake.json                 the composition: every object a game bone or pool, "bounds", material -> ramp
scene/                          the Rive project: scene.rml (camera and look), game.as (the whole game), splats.bin
goldens/                        plane (framed), plane@scene (texel 0.070218), scene: demo_045, demo_1040, demo_2100,
                                frame_030 (the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                             # every model from scratch, lookdev/plane.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary    # clean: 0 errors, 0 warnings, no problems
rive scene                                             # play it
rive scene --arg demo=true                             # watch the demo
```

Check (gates, goldens, frame audit; zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/plane/plane.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/plane/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob plane -o /tmp/alb --look albedo --views front,right,back,top --arg pitchMin=0 --arg pitchMax=90
python3 $K/scripts/golden.py gate --refs art/plane/refs --shots /tmp/alb -p art/plane/gate_palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunYaw=-140 --arg sunPitch=50 --arg keyLight=0.42 --arg highlight=0.85 --arg shadeSteps=1 --arg lightSteps=1 --arg bandDither=0.35 --arg edgeDepth=0.6"
python3 $K/scripts/golden.py views --rive lookdev --blob plane -o /tmp/pl --real-sky --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/pl --goldens goldens/plane
python3 $K/scripts/golden.py views --rive lookdev --blob plane -o /tmp/pls --texel 0.070218 --size 160 --real-sky --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/pls --goldens goldens/plane@scene
for n in 45 1040 2100; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true --quiet; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30 --quiet
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

(The right view fails both hero gates and the back view the splat gate: waivers in
`models/plane/plane.spec.md`, the sheet contradicts itself.)

Try it headless (touch only: presses and drags, no bare moves):

```sh
rive scene --screenshot=$PWD/play.png --advance=3 --pointer=down@320,300 --pointer=up@320,300 --advance=30 \
  --pointer=down@200,320 --pointer="drag@200,320>480,250:40" --advance=10 --pointer=up@480,250 --advance=20
rive scene --render-audio=$PWD/play.wav --advance=3 --pointer=down@320,330 --pointer="drag@320,330>200,330:60" --advance=600
```

The first takes off and steers right; a finger parked at the bottom centre (`--pointer=down@320,330
--advance=6000`) loses all three lives in about 14 s, and weaving drags scored 1100 in 30 s.

Notes from building it:

- The camera's snap rounds the target along its up axis, so a world wrap only changes no pixel when
  `wrap x sin(pitch)` is a whole number of texels: at pitch 60 that set `orthoHeight` (9.549657, not a round
  number). `game.as` repeats the renderer's rounding to find the snapped ground point, and places every
  flying thing relative to it.
- Cottages first had their ridges across the screen: from 60 degrees up the shaded front slope filled the
  view and they read as red blocks. The ridges now run up the screen (one slope lit, one shaded).
- The first balance had 1.4 bullets in the air on average and a demo that never died: enemies fire more now,
  the gunboats have 26 hits (they sank before ever firing) and fire as soon as they show, the boss has 200,
  and the demo hesitates.
- Hiding the boss for a frame on every hit (a classic flicker) hid it most of the time under steady fire; it
  shudders by a texel instead. Balloons and gunboats still flicker (drones die at the first hit).
- The Codex sheet was not reviewed by a person yet (`art/plane/sheet.v1.png.json`, `reviewed: false`).
