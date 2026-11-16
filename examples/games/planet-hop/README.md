# Game: Planet Hop (hept32, 32 colours)

**How to play:** your rocket circles a little planet; click to let go and fly off along the tangent,
into the next planet's dashed pull ring, which catches you in a new orbit. Don't wait too long: orbits
decay.

**Touch:** tap anywhere to let go of the orbit.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [hept32](https://lospec.com/palette-list/hept32) by ENDESGA,
32 colours in 15 ramps; it loaded from Lospec, so the spare (`marshmellow32`) was not needed. A bright
toy cosmos rather than black space: a flat royal-blue sky with white and gold stars and pale-blue puff
clouds drifting with parallax, six little planets (a meadow with pines and a red-roofed house, a dune
with cacti and a pyramid, an ice ball bristling with cyan crystals, a pink mushroom world, a lava planet
with glowing cracks and volcanoes, a ringed gas giant), a red and white cartoon rocket. Orthographic side
view, `orthoHeight` 10, `pixelSize` 3 (texel 0.0735 m), one sun from the upper left and in front (yaw
-38, pitch 34), per-splat dither, ink 1.

## Rules

- One verb: click. The first click launches from the home planet; after that, each click lets go.
- The rocket leaves along the tangent of its orbit, a little faster than it was going. Flying into a
  planet's pull ring (the dashed circle round the next planet; the pull of planets ahead bends the path
  a little near their rings) captures it: it spirals onto that planet's orbit, turning the way it came
  in. +1 a hop; skipping a planet scores 2 a planet; a star picked up on the way +1.
- An orbit lasts 6.5 s, shrinking towards 4.2 s as the run goes on; after 45 % of it the rocket sinks
  towards the ground (a blinking `!`, the rocket shudders). Touching down is a crash.
- A rocket that misses every ring flies out of the picture: LOST IN SPACE.
- Each hop the orbits turn faster (1.75 to 2.9 rad/s), the planets stand farther apart and the rings
  shrink (1.1 m outside the orbit down to 0.6 m): the launch window narrows.
- Game over shows the score and the session's best; the next click starts a new run from the home planet.

**Sound** (`sfx.as`, silent in demo mode): the first click plays a start arpeggio; each launch is a
whoosh with an engine zap (a little higher as the orbits speed up); a capture rings the planet's own
chime, a bell and a pluck a fifth up (meadow C, dune D, ice G, mushroom E, lava low G, giant low D; an
octave up and an arpeggio on a SKIP); a star is a coin a semitone higher for each star of the run; a
decaying orbit beeps with the `!` (every half second, then twice as fast past 60 %, rising); a crash
explodes, every game over falls (lower when lost in space), with a high bell for a new best; a new run
returns home on two soft notes.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the run starts in orbit with the launch
window half a second away. Each frame the demo pilot looks ahead along the tangent (the same pull as the
game) and lets go once the path would pass within a fraction of the next ring chosen per orbit (most
launches near the middle, about one in nine early or late: a miss, unless a pull saves it). Its runs
last about 9 to 40 s; it restarts two seconds after a game over. When demo is switched off, a fresh run
waits in orbit for the first click.

## What is where

```
art/palette.json, palette.png   hept32 with ramps hull, trim, glass, rock, grass, soil, sand, candy, ice, lava,
                                glow, nebula, space, stary, starw; roles (flat royal-blue sky)
art/assets.md                   the asset list, bones, layout
art/rocket/                     the hero's Codex brief, sheet (v1) and record, cut views (refs/), gate_palette.json
models/rocket/                  spec + gate record, make_rocket.py -> p1_blockout.txt, p2_form.txt, rocket.glb,
                                rocket.bake.json, gate shots
models/env/                     make_env.py writes meadow, dune, ice, mushroom, lava, giant, star, flame, puff,
                                spark, chunk, stars, nebula .txt (hedra command files); their GLBs
lookdev/                        the turntable bench (no RML): rocket.bin
scene.bake.json                 the composition: game bones (6 planets, rocket, flame, star x3, puff x8, spark x8,
                                chunk x6, sky x2, nebula x2), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        rocket (framed), rocket@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 37 of 63. Splats: 17 127 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the rocket (p1, p2), lookdev/rocket.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/rocket/rocket.rmdl -o /tmp/rocket_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/rocket/refs --shots /tmp/rocket_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob rocket -o /tmp/rocket_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/rocket/refs --shots /tmp/rocket_alb -p art/rocket/gate_palette.json --min-iou 0.7
L=(--arg sunYaw=-38 --arg sunPitch=34 --arg keyLight=0.45 --arg highlight=0.82)
python3 $K/scripts/golden.py views --rive lookdev --blob rocket -o /tmp/rocket --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/rocket --goldens goldens/rocket
python3 $K/scripts/golden.py views --rive lookdev --blob rocket -o /tmp/rocket_s --texel 0.0735 --size 120 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/rocket_s --goldens goldens/rocket@scene
for n in 040 110 200; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

The goldens: `demo_040` (the first launch, the exhaust trail, the dune's ring), `demo_110` (+1 at the
dune, the ice planet's ring), `demo_200` (+1 at the ice planet, a star ahead), `frame_030` (the hint).
Every frame: 100 % solid 3 x 3 blocks, 0 off-palette.

Play it headless: `rive scene --screenshot=$PWD/p.png --advance=27 --pointer=click@320,200 --advance=120`
(the first launch at the right moment: caught by the dune, score 1); `--advance=3 --pointer=click@320,200
--advance=200` (too early: LOST IN SPACE); `--advance=27 --pointer=click@320,200 --advance=500` (caught,
then no click: THE ORBIT DECAYED). The hand-over: a `--commands` file with `data demo=true`, `advance 200`,
`data demo=false`, `advance 30` shows a fresh run waiting in orbit with BEST 0.

## Notes from building it

- The camera never moves. A chain of planets running off to the right would leave the baked bounds (the
  shadow map's reach) behind, so the game keeps world positions and draws everything at (world - camera)
  with the camera rounded to whole texels: the world slides by whole art pixels, like the renderer's own
  snapping. The star field and the nebula are two 20 m tiles each that leapfrog at parallax 0.15 / 0.35.
- The rocket's fins first started 0.05 m inside the fuselage; at 0.1 m spacing their buried discs poked
  through the white hull as red blotches (colour drift 0.5). They start at the body surface now.
- The colour gate is run against `art/rocket/gate_palette.json` (the rocket's four ramps only): with all
  15 ramps, the sheet's shaded reds snapped to colours that only `lava` and `candy` hold. See the spec.
- The pull rings were single dots first and read as more stars; then two big dashed rings (the next two
  planets) read as rain. Now only the next planet's ring is drawn, 22 dashes turning slowly.
- A missed launch first had the camera follow the rocket into empty space for three seconds; the camera
  now stops at the next planet and a miss leaves the frame within about a second.
- The gas giant does not spin (its tilted ring would wheel round the view axis); the others turn 6 to
  13 degrees a second.
- The Codex sheet was not reviewed by a person yet (`art/rocket/sheet.v1.png.json`, `reviewed: false`).
