# Game: Moon Lander (Nyx8, 8 colours)

**How to play:** hold anywhere to fire the thruster and let go to fall; touch down softly on the pad
as the little moon turns it under you. Touching the bare moon, landing too fast or off the pad's
middle is a crash.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [Nyx8](https://lospec.com/palette-list/nyx8) (navy-black,
slates, mauves, tan, cream), loaded from Lospec (the spare, 2bit-demichrome, was not needed). Deep
space: an ink-black sky, cream stars, a ringed planet, a small faceted moon lit from the right as a
crescent (its left side sinks to the navy steps), per-splat dither, ink 1.

The game (`scene/game.as`, all of it): the lander flies straight up and down above the moon's top;
gravity 2.1 m/s^2, thrust 4.5. The moon turns, bringing the pad round from one side. A landing needs
the pad underfoot (within 1 m of its middle) and a descent slower than 1.6 m/s (the speed shows
beside the lander, cream when safe, rose when not). Each landing scores 100 + up to 60 for softness +
up to 40 for centring (FEATHER!, BULLSEYE!), refuels 28-42 %, plants a flag that turns with the moon;
then the lander lifts off by itself, the pad sinks and pops up round the moon, and the moon turns
faster (every third landing, the other way). A pad that goes by sinks and comes back too, so waiting
costs only fuel (19 %/s while thrusting): an empty tank ends the run. Best score for the session.
Motion: the lander squashes on touchdown and stretches as the flame lights; the flame flickers at
12 fps; dust puffs out under the jet near the ground; a crash throws debris that bounces on the moon,
and the camera shakes in whole pixels.

Demo mode (`--arg demo=true`, or the `Sample` view model's `demo`): a pilot that hovers until the
pad is about to come round, then descends to meet it with throttle pulses. Each approach gets a timing
error, small most of the time and big about one time in six, so it lands four to six times and then
misses or runs dry (a run of 30 to 50 s); it is descending with the flame lit from frame 0 and
restarts 2 s after a crash. When demo turns off, a fresh run waits for the first press.

Sound (`sfx.as` presets, silent in demo; the idle hover before the first press is quiet too): a rising
arpeggio as the first press starts the run; the jet lights with a whoosh, then crackles every 6
frames and breathes every 24 while held; fuel alarms blip at 30, 20 and 10 % and the tank sputters
dry; a touchdown clunks (heavier the harder) and plays a three-note jingle, a semitone higher each
landing of the run: a major arpeggio and a high note for FEATHER or BULLSEYE, a smaller step for NICE,
a flat fall for BUMPY; lift-off whooshes and the pad pops up round the moon; a crash bursts, debris
clinks on the moon, then a falling sting.

```
art/palette.json, palette.png   Nyx8, ramps rock, dust, foil, cabin, metal, glass, flame, planet, star
art/assets.md                   the asset list, bones, layout
art/lander/                     the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/lander/                  spec + gate record, make_p1.py -> p1_blockout.txt, p2_form.txt, bake file,
                                gate shots, GLB
models/env/                     make_env.py (writes moon, pad, stars, planet, flame, dust, debris, flag),
                                the command files and GLBs
lookdev/                        the turntable bench (no RML): lander.bin
scene.bake.json                 the composition: game bones (moon, pad, lander, flame, dust x6, debris x6,
                                flag x6), the stars and the planet, the play-area bounds
scene/                          the Rive project: scene.rml (look-at side view, ortho 9 m), game.as
goldens/                        the lander framed and at the scene's texel; scene/: demo_090, demo_200
                                (a feather landing), demo_560 (a bullseye) and frame_030 (the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                             # models from scratch, lookdev/lander.bin, scene/splats.bin
rive scene --verify && rive scene                      # play it
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/lander/lander.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/lander/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob lander -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/lander/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L=(--arg sunYaw=62 --arg sunPitch=24 --arg keyLight=0.4 --arg highlight=0.85 --arg shadeSteps=2 --arg bandDither=0.4)
python3 $K/scripts/golden.py views --rive lookdev --blob lander -o /tmp/ld --real-sky $L && python3 $K/scripts/golden.py check --shots /tmp/ld --goldens goldens/lander
python3 $K/scripts/golden.py views --rive lookdev --blob lander -o /tmp/lds --texel 0.068 --size 120 --real-sky $L && python3 $K/scripts/golden.py check --shots /tmp/lds --goldens goldens/lander@scene
for n in 090 200 560; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --arg demo=true --advance=$n; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_200.png -p art/palette.json --pixel 3
```

Try it headless: `--advance=5 --pointer=click@320,200 --advance=150` falls and crashes ("MISSED THE
PAD"); a hold/release schedule landed the first pad (+126, BUMPY). Each `--pointer` event also
advances a frame, so a scripted schedule drifts unless its `--advance`s are shortened by one.

Notes from building it:

- The first demo only hovered just above the deck (it aimed at the deck's height, never into it) and
  a missed pad took 18 s to come round: it now aims 0.4 m into the deck and a passed pad sinks and
  comes back ahead.
- The lander is 2 m tall: the camera's target sits at y 1.6 so it never clips the top of the frame.
- A bone scaled to 0 (a dust puff's last stepped frame, a flag's first) drew its splats as giant
  slate rectangles: `pose()` hides any bone scaled under 5 %.
- The Codex sheet was not reviewed by a person yet (`art/lander/sheet.v1.png.json`, `reviewed: false`).
