# Game: Gust Regatta (mulfok32)

**How to play: the boat steers towards the pointer (on a phone: drag or tap where to go; it keeps its
heading when you let go), hold to turn hard; sail two laps through the buoy gates in order. You cannot
sail straight into the wind (the "no-go zone", about 40 degrees either side of it): to go upwind, zigzag
(tack).**

A dinghy race in a sunlit bay: a lighthouse on Lantern Isle in the middle, Gull Rock and Pine Key, a
village with a jetty and three moored dinghies on the north shore. The course is the start/finish line
(two orange buoys south of Lantern Isle) and four gates round the island; two laps, against the clock and
the ghost of your best race. One run in one world: the first click starts a race (the boat is already
sailing towards the start line; the clock starts as it crosses), the finish shows the time and the best,
and the next click races again. Pointer only.

The sailing model (`scene/game.as`):

- **Steering**: the wanted heading is the direction from the boat to the pointer on the water
  (`api.pick`), set by every pointer move and press and, while pressed, every frame; it persists when the
  pointer stops or lifts. The rudder turns towards it at a limited rate (30 + 14 °/s per m/s, up to 85)
  with a little inertia; holding the pointer down turns 1.7 x harder (up to 140 °/s) but a hard turn
  costs a quarter of the speed while it lasts.
- **The polar**: speed is a share of 6.5 m/s x the wind's strength by the angle off the wind: nothing
  under 40 degrees (the no-go zone: the sail luffs and flaps, the boat coasts to a stop, "NO GO" blinks
  over it and, if it stalls, "IN IRONS: TURN AWAY FROM THE WIND"), 0.78 at 55, best (1.0) on a beam reach
  at 95, 0.92 at 135, 0.68 dead downwind. The boat speeds up slowly and coasts down slowly (momentum), and
  drifts downwind a little.
- **The sail trims itself** on the leeward side (the boom out 6 to 82 degrees with the angle off the
  wind); crossing the wind with the bow is a tack, with the stern a gybe: the boom swings across at
  220 °/s. The hull heels to leeward with the sail's pull (up to about 20 degrees on a reach, none on a
  run or in irons), pitches and bobs.
- **The wind** swings about 35 degrees either side of north and breathes (strength 0.82 to 1.18) on the
  race's own clock, so every race and the ghost meet the same wind. It shows in the HUD's wind arrow (it
  points the way the wind blows, longer when stronger, pink in a gust), in the wavelets drifting downwind
  round the boat, in the lighthouse's windsock, and in the moored dinghies swinging their bows into it.
- **Gusts**: four dark, ruffled patches (12 m across) appear upwind, drift downwind and fade; inside one
  the wind is up to 1.5 x stronger ("GUST!").
- **Gates**: a gate counts when the boat crosses the line between its buoys, in order. Passing outside
  the buoys, or through a later gate, shows "MISSED GATE n: GO BACK" and does not count. Bumping a buoy,
  an islet or the shore slows the boat hard. Each gate shows the split against the ghost (green ahead,
  red behind).
- **The ghost** (a pale pink boat) replays your best race from the moment it crossed the start line.

Touch: the pointer only exists while a finger is down, so nothing needs hovering. A press steers towards
the touched point at once (the first press also starts the race), a drag steers continuously (with the
hard turn, since the finger is down), and lifting the finger keeps the boat on its last heading, so
steering by quick taps works as well as by dragging. Both were played to the finish by a touch-only
scripted player (below).

Demo mode (`--arg demo=true`, the gallery's `Sample.demo`): the race starts at once with the boat on a
fast beam reach 7 m from the start line (it crosses at 1.6 s, wake and wavelets from frame 1). The pilot
re-plans every quarter second with a few degrees of aim error: it heads for the next gate (lining up and
sailing on through), rounds islets, sails for a gust that lies on its way, and upwind sails close-hauled
(50 degrees off), tacking when the gate falls far enough onto the other side or when its tack runs at an
islet or the shore. One gate in ten it means to miss: it sails past just outside a buoy, sees it ("MISSED
GATE"), and comes back through. A demo race takes 82 to 102 s; two seconds after the finish it races
again (against its own ghost from the second race on). Turning demo off starts a fresh race at once.

Sound (procedural, `api.sound`; silent in demo): a blip on the click that starts a race; water slaps
keyed to the distance sailed (one every 3.4 m, so sparse when slow, brisk when fast; pitch and volume
follow the speed); a sail flap (a click and a tick) every 0.32 s while luffing in the no-go zone; a whoosh
on a tack, a lower whoosh and a boom thud on a gybe; a gust swell (two low whooshes) when the boat sails
into a gust; a start bell; a bell over a plucked note climbing a pentatonic scale with every gate of the
race; a four-note jingle at the end of the first lap; a falling two-note buzz for a missed gate; a pop for
a bumped buoy, a thud and a splash for an islet or the shore; at the finish a fanfare with a rising bell
arpeggio, and a power-up for a new best. Every sound is decided by the boat's state and the frame clock,
never by `api.rand()`.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra
0.1.0, codex-cli. Palette: [mulfok32](https://lospec.com/palette-list/mulfok32) by mulfok (loaded from
Lospec; the spare `endesga-64` was not needed), 32 colours as 18 ramps. An orthographic chase view
(`orthoHeight` 16 m, `pitch` 55, looking north, `pixelSize` 3: texel 0.118 m); the camera only
translates, leading the boat by its speed, so the picture slides by whole pixels. The water is the sky
colour (`#6d80fa`, `horizon` 2): nothing is spent on a sea surface; shallows, ripples, gusts, wavelets and
foam are flat unlit layers on it. A high sun from the front left, `shadeSteps` 1, ink 1.

What moves (48 of 63 bones, all game bones moved by `scene/game.as`): the hull (heading, heel, pitch,
bob) and the rig (swung about the mast's foot, heeling with the hull: its matrix is composed in
`game.as`); the ghost; ten buoys (bob, roll, a pop when their gate is taken or bumped); the next-gate
marker; four gusts; fourteen wavelets; twelve foam dabs (the wake's V, bow spray, bursts); the windsock;
three moored dinghies.

```
art/palette.json, palette.png   mulfok32 with 18 ramps and its roles (the sea blue as both sky colours)
art/assets.md                   the asset list (sizes, ramps, bones, the water-is-the-sky choice)
art/sailboat/                   the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/sailboat/                spec + gate record (waivers), p1_blockout.txt, p2_form.txt, p3_splat_fit.txt,
                                bake file, gate shots, sailboat.glb (gated form), sailboat_fit.glb, hull.glb, rig.glb
models/env/                     make_bay.py (+ glbkit.py, a flat-shaded GLB writer): the bay, islets, ripples,
                                props, buoy, marker, gust, wavelet, foam, windsock, dinghies; their GLBs
lookdev/                        the turntable bench (no RML): sailboat.bin
scene.bake.json                 the composition: game bones ("bone", "copies"), a "bounds" play area
scene/                          the Rive project: scene.rml (the tuned inputs), the renderer files, game.as (the game)
goldens/                        sailboat framed and at the scene's texel, scene/ (demo_045, demo_1200, demo_2100, frame_020)
shots_scene/                    the frames the scene goldens were snapped from
build.sh                        rebuilds every model and both blobs
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models/env, the sailboat (p1, p2, p3), lookdev/sailboat.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary
rive scene                                   # play; `rive scene --arg demo=true` watches the demo
```

Check (gates, goldens, frame audit, a scripted run):

```sh
python3 $K/scripts/golden.py views --hedra models/sailboat/sailboat.rmdl -o /tmp/gr_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/sailboat/refs --shots /tmp/gr_p2 --min-iou 0.75 --max-aspect-drift 0.08   # top: waiver
python3 $K/scripts/golden.py views --rive lookdev --blob sailboat -o /tmp/gr_alb --look albedo --views front,right,back,top --arg pitchMin=0 --arg pitchMax=90
python3 $K/scripts/golden.py gate --refs art/sailboat/refs --shots /tmp/gr_alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08   # front IoU, top aspect: waivers
L="--arg sunYaw=-35 --arg sunPitch=52 --arg keyLight=0.45 --arg highlight=0.85 --arg shadeSteps=1 --arg lightSteps=1"
python3 $K/scripts/golden.py views --rive lookdev --blob sailboat -o /tmp/gr_k --real-sky --views front,right,back,top,iso ${=L}   # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/gr_k --goldens goldens/sailboat
python3 $K/scripts/golden.py views --rive lookdev --blob sailboat -o /tmp/gr_ks --real-sky --texel 0.0871 --size 160 --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/gr_ks --goldens goldens/sailboat@scene
for n in 45 1200 2100; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_020.png --advance=20
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_1200.png -p art/palette.json --pixel 3
# play: click to start, steer north into the wind (luffing, NO GO), then a hard turn and a reach
rive scene --screenshot=$PWD/play.png --advance=3 --pointer=click@200,210 --advance=150 --pointer=move@320,20 --advance=180 \
  --pointer=down@40,40 --advance=50 --pointer=up@40,40 --advance=200 --pointer=move@600,60 --advance=200
# touch only: a tap starts and steers, a drag steers, the heading holds after the lift
rive scene --screenshot=$PWD/touch.png --advance=3 --touch=down@60,190 --touch=up@60,190 --advance=150 \
  --touch=down@40,120 --touch=move@30,110 --advance=40 --touch=up@30,110 --advance=180
# hand-over from the demo to a player, as the gallery does it
printf 'data demo=true\nadvance 600\ndata demo=false\nadvance 30\nscreenshot %s/handover.png\nquit\n' $PWD | rive scene --commands
rive scene --render-audio=$PWD/play.wav --advance=3 --pointer=click@200,210 --advance=600    # play mode: the synth's output
```

Tested: a closed-loop player (Python driving `rive scene --commands` with touch events only, reading
the state from a temporary log) sailed the whole race twice, once steering by taps (86 to 110 s) and once
by drags (118 s, slower for the hard turns); the demo was run for 10 minutes (six races, every one
finished, its deliberate misses recovered); the physics and the pilot were first written as a throwaway
Python port. Every golden frame audits 100 % solid 3 x 3 blocks, 0 off-palette.

Notes from building it:

- **The water as the sky colour** halves the splat budget a bay would cost and removes every depth fight
  between flat layers and a sea surface. The price: nothing shadows the water, and anything modelled
  below y 0 shows through, so the hero has no keel and the buoys stand on the waterline.
- **A flat pennant vanishes** when it streams towards the camera (edge-on): the lighthouse's flag is a
  windsock, readable from every side.
- **Gates face the leg that leads to them.** Gates first faced the average of the legs in and out; the
  upwind gate then sat diagonal to the wind and every tacking approach crossed its line outside the buoys
  (a false "MISSED GATE"). A gate can be crossed either way (coming back through counts).
- **The demo pilot** orbited a gate it had passed outside: the "sail on through" point lay beside it.
  Past the gate's line outside the buoys it now aims at the gate itself and comes back through.
- `game_api.place` turns an object about its own pivot only; the rig hangs on the hull and turns about
  the mast (`R_hull · Ry(boom)` about the mast's foot carried by the hull), so `game.as` writes those
  matrices into `api.mats` itself (`setBone`).
- The Codex sheet was not reviewed by a person yet (`art/sailboat/sheet.v1.png.json`, `reviewed: false`).
