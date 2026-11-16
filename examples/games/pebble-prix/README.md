# Game: Pebble Prix (Zughy 32)

**How to play: tap or click to start the lights; your car drives itself and steers toward the pointer
(or your finger). Hold the press through a sharp turn to drift, then let go to boost. Three laps.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Zughy 32](https://lospec.com/palette-list/zughy-32) by Zughy, 32
colours in 26 ramps; it loaded from Lospec, so the spare (`gb-chocolate`) was not needed. A sunny
islet village: grass in two greens, a sandy west beach, pale paving, white, peach and rose houses
under terracotta roofs, a red and white lighthouse, and the sea all round, which is the renderer's
flat sky (#3978a8) with a broken foam line along the coast. The cars are red (you), cyan (GULL), pink
(CORAL) and gold (BUOY).

The race: four little roadsters, three laps of a 218 m circuit round the village (the harbour
straight along the quay with the gantry and the chequered line, the lighthouse hairpin on the
headland, two switchbacks climbing between dry-stone walls and vines, the village street under a
stone arch, the chapel corner, the bridge run over the creek, the beach corner back onto the
harbour). You start third on the grid. Positions (1ST-4TH) and the lap top left, the lap counter,
the race clock and your best lap top right; a banner with each lap's time (gold on a best lap); the
start lights on the HUD and on the gantry. At the flag the results: the four places with finishing
times, your time and best time, your best lap; the next click starts a new race on the same grid. If
all three computer cars are home and you are still out there 15 s later, the race ends OUT OF TIME.

The car (all in `scene/game.as`, tuned first in a throwaway Python port): it accelerates on its own
to 14 m/s; it turns toward the pointer at a rate grip allows (13 m/s2 of cornering); steering harder
than that scrubs speed (12 m/s2), which is how you slow for a hairpin. A drift starts when the press
is held and the steer is more than 28 degrees off the car's heading: more turn (19 m/s2), the rear
slides out (the nose swings 24 degrees into the corner), smoke pours from the rear wheels, the speed
settles to 10.5 m/s, and a charge bar fills under the car: 0.8 s of drift earns a 0.9 s boost, 1.8 s a
1.5 s boost (19 m/s, a flame from the exhaust). The drift ends, and fires its boost, when you let go,
when you straighten the steer for 0.3 s, or below 4 m/s. Grass slows you to 7.5 m/s, sand to 6.5 (with
dust); walls (half way to the next run of the track, the quay, the house fronts, the bridge's
parapets, the arch, the coast), hay bales, oil drums and the gantry's posts bounce you back and cost
speed; cones fly; cars bump each other (two circles a car, a light exchange of momentum); boost
strips give 0.8 s of boost. No turning on the spot below walking pace.

Controls on touch (a phone shows the pointer only while a finger is down): the finger steers while
it touches and drags (the car heads toward it, relative to where the car shows); lifting it holds the
car's heading; a drag held sharply to one side (beyond 28 degrees) is the drift, and lifting the
finger, or bringing the drag back in line, lets it go and fires the boost. No hover is needed
anywhere, and the first tap starts the lights. With a mouse the hover steers and a press drifts the
same way. A lifted finger reports one more move at the lift point: `game.as` ignores a move that sits
exactly where the last release was, so the stale point never steers. Tested touch-only with
`touch down@ / move@ / up@` commands (no bare `move@`): a closed-loop player won the race (1st, 50.93 s).

The computer drivers: each follows a minimum-curvature racing line (`track.py`, relaxed inside the
walls) at a speed profile from its curvature, brakes for corners, drifts the hairpins (flick in, hold
the slide, straighten out for the boost), pulls out to the side with more room to pass a slower car
in its lane, and makes small mistakes (a late turn-in that runs wide, a wobble, a missed drift) every
5-11 s divided by its sloppiness. GULL is fast and clean (power 0.97), CORAL quick but untidy (0.96),
BUOY steady and slower and never drifts (0.94). A light rubber band keeps the pack together: a car
leading you eases off up to 10 %, a car behind gains up to 3 %, never on the final lap.

The camera: a high orthographic follow camera (pitch 52, 18 m tall, 213 x 133 art pixels): its target
rides 4 to 5.5 m ahead of your car and snaps to the art grid, so it slides by whole pixels; its yaw
follows the circuit's long-run direction (the track's heading averaged over 50 m, so the switchbacks
read as one climb up the screen), rate-limited to 46 degrees a second. Bumps shake it by a pixel.

Demo (`--arg demo=true`, or the `Sample` view model's `demo`): it opens mid-race on lap 1, the four
cars bunched up the harbour straight a few metres short of the lighthouse hairpin, so the first second
is the whole pack drifting through it. Your car is driven by the same driver code with the player's
controls only (no brake: it scrubs speed by steering hard, drifts the hairpins, lets go for the
boosts, and makes the same kind of mistakes); it finishes anywhere from 1st to 4th, usually 2nd or
3rd, often by tenths. Two and a half seconds after the flag a new race starts with the lights. When
demo turns off, a fresh race waits on the grid for the first tap.

Sound (`sfx.as`, silent in demo mode; never decided by `api.rand()`): the engine is sparse low square
ticks, quicker and higher with speed and higher still on a boost (every 3 to 13 frames: the busiest
sound, rate-limited), revving on the grid during the lights; a drift scrapes (short noise bursts every
4 frames) and blips when it has earned a boost, higher for the long one; a boost is a whoosh and a
rising zip (a boost strip a higher whoosh); off the track a low gravel rumble; a wall is a thud and a
crunch, a hay bale a soft thump, an oil drum a hollow clang, a car a light crunch (rate-limited to one
bump every 0.15 s, louder for harder hits); a knocked cone pops; the lights beep three times and the
start note rings an octave up; a lap is a two-note bell chime (three notes into the final lap,
brighter on a best lap); a place gained is a rising pair of blips, a place lost a falling one; a rival
crossing the line near you a short bell; the finish is a jingle by position (a fanfare and a win
arpeggio for 1st, three rising notes for 2nd, three flatter ones for 3rd, the losing arpeggio for 4th
or out of time) and a rising arpeggio for a new best time.

What moves (52 of 63 bones, all game bones moved by `scene/game.as`, no baked tracks): the four cars
(yaw with the drift slide, roll in turns, a pitch and a bounce on bumps, a rattle off the track) and
their boost flames (on the exhaust with `api.transform`); 12 smoke puffs (from the rear wheels with
`api.transform`), 6 dust puffs and 4 spark bursts (pools, stepped growth); 13 cones (knocked flying,
spinning, bouncing, lying where they land until the next race); two boats bobbing at their moorings;
the chequered flag (waving faster once you finish); the three red start lights and the green on the
gantry; two gulls circling the harbour.

```
art/palette.json, palette.png   Zughy 32 with 26 ramps (road, stone, plaster, peach, rose, roof, grass,
                                leaf, sand, sea, red, blue, pink, gold, tyre, white, navy, wood, orange,
                                glow, lamp, lime, smoke, dust, foam, slate); roles: the sea is the sky
art/assets.md                   the asset list: the art grid, sizes, ramps, bones (52 of 63), splats
art/racer/                      the hero's Codex brief, sheet (v1, reviewed: false) and record, cut views
                                (refs/), gate_palette.json (its own ramps, for the colour gate)
models/meshkit.py               the low-poly mesh kit and GLB writer the generators share
models/racer/                   make_racer.py -> racer.glb (red) + racer_blue/pink/gold.glb, racer.rmdl
                                (the hedra gate model), racer.spec.md (spec, gate record, waiver),
                                racer.bake.json, gate shots
models/env/                     track.py (the circuit: centreline, walls, racing line, speed profile,
                                camera heading, drift zones, props; writes the tables into game.as),
                                make_env.py -> ground, road, town, trees, cone, boat, flag, lamp, golamp,
                                flame, puff, dust, spark, gull (.glb)
lookdev/                        the turntable bench (no RML): racer.bin
scene.bake.json                 the composition: the static island, the cars and the pools as game
                                bones, "bounds" over the whole circuit
scene/                          the Rive project: scene.rml (orthographic 18 m, pitch 52, pixelSize 3,
                                sea-coloured flat sky), game.as (the whole game), the renderer files,
                                splats.bin (106 802 splats)
goldens/                        racer/, racer@scene/, scene/ (frame_030; demo_090, demo_640, demo_1000)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model, the track tables and both blobs
```

Rebuild and play (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # GLBs, racer.rmdl, the track tables, lookdev/racer.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary
rive scene                                   # play; `rive scene --arg demo=true` to watch the demo
```

Check (gates, goldens, frame audit, an idle player never finishes):

```sh
python3 $K/scripts/golden.py views --hedra models/racer/racer.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/racer/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob racer -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/racer/refs --shots /tmp/alb -p art/racer/gate_palette.json --min-iou 0.7 --max-aspect-drift 0.08   # waiver in the spec
L="--arg sunYaw=-35 --arg sunPitch=55 --arg keyLight=0.45 --arg highlight=0.85 --arg shadeSteps=1"
python3 $K/scripts/golden.py views --rive lookdev --blob racer -o /tmp/r --real-sky ${=L}           # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/r --goldens goldens/racer
python3 $K/scripts/golden.py views --rive lookdev --blob racer -o /tmp/rs --texel 0.132 --size 160 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/rs --goldens goldens/racer@scene
mkdir -p /tmp/pp; for n in 090 640 1000; do rive scene --screenshot=/tmp/pp/demo_$n.png --advance=${n#0} --arg demo=true; done
rive scene --screenshot=/tmp/pp/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots /tmp/pp --goldens goldens/scene
python3 $K/scripts/palette.py frame goldens/scene/demo_640.png -p art/palette.json --pixel 3
rive scene --screenshot=/tmp/idle.png --advance=2 --pointer=click@320,300 --advance=85s   # never steered: stuck at the lighthouse, OUT OF TIME
rive scene --render-audio=/tmp/race.wav --advance=2 --pointer=click@320,300 --advance=4s --pointer=move@330,150 \
  --advance=2s --pointer=down@420,200 --advance=1200ms --pointer=up@330,150 --advance=2s       # the lights, the engine, a drift
```

Notes from building it:

- Physics, the racing line, the drivers and the balance were tuned in a throwaway Python port of
  `update()` first: it found that a car without brakes could not take the hairpins (the scrub), that
  drifting was a handicap until it became an arcade drift (more turn, the slide shown on the body, the
  speed settling to a cornering speed), that drivers needed planned drifts (zones) instead of a button
  pressed by the curvature (106 drifts a lap of chatter), and that the leader was decided by the
  rubber band until the catch-up was capped. Then a closed-loop Python player drove the real game
  through `--commands` (reading a temporary `console.log` of the car's state, steering the pointer
  along the racing line on screen): mouse and touch-only it won (1st, 52.37 s and 50.93 s); idle it
  never completed a lap.
- On touch the finger is always down, so a sharp correction outside a hairpin is a drift too: the
  touch player that won keeps its corrections under the drift angle and drags past it on purpose.
- An object-level `"spacing"` in a bake file is ignored (only the top level and each material count):
  the cars first baked at the scene's 0.24 m (340 splats a car) until every material got its own.
- The camera's heading is the track's direction averaged over 50 m, not the car's: the car's own
  heading (and its drift slide) would swing the whole picture, and every turn re-rasterises every
  splat.
- The Codex sheet was not reviewed by a person yet (`art/racer/sheet.v1.png.json`, `reviewed: false`).
