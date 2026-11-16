# Game: Bubble Loft (Sunset 8)

**How to play:** press and drag to aim the orb puffer (a dotted guide shows the path with one wall
bounce and a ring where the orb will cling), release to launch; a plain tap launches toward the tap. Tap
the orb waiting in the side cup to swap it with the loaded one. Three or more of a colour pop; whatever
no longer hangs from the rafter falls for a bonus.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Sunset 8](https://lospec.com/palette-list/sunset-8) by SamRI, 8 colours
in one long run from navy to cream, cut into 14 short ramps (four orb ramps, iron, copper, brass, petal,
rubber, wood, leaf, clay, roofs, glow); it loaded from Lospec, so the spare (`neon-space`) was not needed.
A rooftop greenhouse loft at sunset: a big window framed by orange posts (the walls the orbs bounce off),
the dusk sky and the town's rooftops with lit windows and a low yellow sun behind the glass, a brass sill
across the window (the danger line), side walls of iron-barred panes with shelves of potted plants, a
hanging basket and a crate of spare orbs, plank floor. Front view from a little above, orthographic 11.2 m
(texel 0.082 m), `pixelSize` 3, a low sun from the left (sun yaw -38, pitch 34), per-splat dither, ink 1.

## Rules

- Controls (touch-ready, nothing needs hovering): a press aims at the pressed point, a drag keeps aiming
  at the finger, the release launches toward the release point; a tap (press and release in one place)
  is a launch toward it. A press that starts and ends on the cup (a 17-pixel target round the next orb)
  swaps the orbs instead. With a mouse (`api.hoverSeen`), hovering also aims (a convenience
  on top). A finger sliding off the tile ends the gesture as a release (the renderer's rule): it launches. A release while the
  next orb is still rolling into the mouth launches as soon as it is in.
- The cluster hangs from a rafter in a hex grid (rows of 8 and 7). An orb flies at 15 m/s, bounces off
  the posts, and clings in the nearest free cell when it touches the rafter or an orb. Three or more of
  its colour pop (10 points each); orbs no longer connected to the rafter fall (30 each, +100 for five or
  more: "AVALANCHE!"). Consecutive popping shots build a combo that multiplies the shot's points (up to
  x5).
- Every few shots (8 on the first cluster, one fewer for each later one, at least 4; the pips under
  DROP IN count down, and the rafter creaks a texel when one shot is left) the rafter drops a row with a
  thud. An orb at or below the brass sill ends the run: GAME OVER with the score and the session's best;
  the next tap starts a new run (the old cluster bursts in a wave and a new one grows).
- Clearing the rafter scores 500 x the cluster's number; the rafter rises back and a new, deeper cluster
  grows (4 rows of 3 colours first, then 5 rows of 4 colours). The next orb is always a colour the
  cluster still holds.
- A run lasts from half a minute to a few minutes.

**Sound** (`sfx.as`, silent in demo mode, never decided by `api.rand()`): a launch is the bulb's puff (a
whoosh) and a low pop as the orb leaves the tulip, then the click of the next orb rolling into the mouth;
a wall bounce is a wooden tick panned at the post; a clinging orb clicks with a high glassy clink; a pop
is a run of pops and plucked notes climbing a pentatonic scale with the group's size (a combo starts it
higher); a falling cluster is a descending cascade of bell notes and a whoosh, then each orb ticks on the
planks and bursts with a low pop; the rafter's drop is a thud with two rattling clicks; the shot before a
drop creaks (two low blips); a cluster one row above the sill rings a three-note bell warning; a cleared
rafter plays a rising jingle (a C major arpeggio into bells) over the win chord; GAME OVER is the lose
sound and a falling bell line (two bright notes after it for a new best); a swap blips, a new cluster
ticks softly as it grows, a restart plays the start chord.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the barrel starts sweeping at once and the
first orb is launched within the first second. For each shot the demo traces every angle from 12 to 168 degrees
(both the loaded and the cup's orb, with one wall bounce), scores the landing cell (pops, what would
fall, same-colour neighbours, rows near the sill) and, like a decent human, mostly takes the best plan,
a quarter of the time the second best, and one shot in five carelessly; every aim carries up to 2
degrees of error, so it banks off the posts, misses now and then and loses runs (30 s to 1.5 min in a
3-minute test, clearing one to three clusters). It swaps when the cup's orb fits better. It restarts two
seconds after GAME OVER; when demo is switched off, a fresh run starts (the old cluster bursts, a new
one grows in about a second).

Motion: the barrel swings to the aim and recoils; the plum bulb breathes and squashes flat on each
launch; the next orb rolls out of the cup in an arc into the mouth (and back on a swap); orbs spin as
they fly; neighbours wobble when an orb clings; popped orbs squeeze and burst into palette shards; loose
orbs shiver, drop, bounce once on the planks and burst; the rafter drops on a spring with a bounce and
shakes the view by whole texels; a new cluster grows in cell by cell.

## What is where

```
art/palette.json, palette.png   Sunset 8 with 14 ramps (dusk, rose, ember, sun, iron, copper, brass, petal, rubber,
                                wood, leaf, clay, roofs, glow); roles: plum sky above, pink sky low, navy void
art/assets.md                   the asset list, the bone plan (pooled orbs per colour), the layout
art/puffer/                     the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/puffer/                  spec + gate record (and the look waiver), make_puffer.py -> p1_blockout.txt,
                                p2_form.txt, p3_splat_fit.txt; puffer.glb (gated form), puffer_splat.glb (the
                                bench's), puffer_base / _barrel / _bulb.glb (the scene's parts), puffer.bake.json,
                                shots/final, shots/final_scene
models/env/                     make_env.py writes loft, far, beam, orb_dusk / rose / ember / sun .txt (hedra
                                command files); their GLBs
lookdev/                        the turntable bench (no RML): puffer.bin
scene.bake.json                 the composition: loft, far, the puffer base (static), game bones (barrel, bulb,
                                beam, dusk0-13, rose0-13, ember0-13, sun0-13), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light, sky), game.as (the whole game), renderer
goldens/                        puffer (framed), puffer@scene (at the scene's texel), scene (demo_050: the first pop
                                and the guide, demo_330: a x3 combo, demo_520: the rafter cleared, frame_030: the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 59 of 63. Splats: 70 452 in the scene blob (the four orb pools 8 662).

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the puffer (p1, p2, p3), lookdev/puffer.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/puffer/puffer.rmdl -o /tmp/pf_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/puffer/refs --shots /tmp/pf_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob puffer -o /tmp/pf_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/puffer/refs --shots /tmp/pf_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=-38 --arg sunPitch=34 --arg keyLight=0.35 --arg highlight=0.85 --arg shadeSteps=1 --arg edgeDepth=0.5)
python3 $K/scripts/golden.py views --rive lookdev --blob puffer -o /tmp/pf --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/pf --goldens goldens/puffer
python3 $K/scripts/golden.py views --rive lookdev --blob puffer -o /tmp/pf_s --texel 0.0717 --size 100 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/pf_s --goldens goldens/puffer@scene
for n in 050 330 520; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Play it headless, touch only (no hover). A world point (x, y) on the window's plane shows at about
screen (320 + 36.4 x, 392 - 36.2 y); the cup (the next orb) is at (365, 343). A swap, a tap launch, a
press-drag-release launch, another tap, then the sound of it:

```sh
rive scene --screenshot=$PWD/p.png --advance=3 --touch=tap@365,343 --advance=20 --touch=down@330,250 --advance=3 \
  --touch=move@250,180 --advance=3 --touch=move@150,100 --advance=3 --touch=up@150,100 --advance=40 \
  --touch=tap@450,120 --advance=40
rive scene --render-audio=$PWD/play.wav --advance=3 --touch=tap@330,200 --advance=50 --touch=tap@365,343 \
  --advance=20 --touch=down@330,250 --advance=3 --touch=move@150,90 --advance=3 --touch=up@150,90 --advance=60 \
  --touch=tap@470,100 --advance=90
```

(`--pointer` with only `down@`, `drag@` and `up@` plays the same. A closed-loop test player, a scratch
script not kept, read a temporary state log and played with `touch down/move/up` lines in `--commands`:
it cleared two clusters, lost twice and restarted with a tap.)

The demo-to-player hand-over: `printf 'data demo=true\nadvance 400\ndata demo=false\nadvance 90\nscreenshot
/tmp/h.png\nquit\n' | rive scene --commands` shows a fresh cluster with the hint.

## Notes from building it

- **The bone plan.** Colour is baked per splat, so every orb bone keeps its colour: four pools of 14
  (56 bones) cover the cluster, the loaded orb, the cup, the shot, bursts and falls; the generator caps a
  colour at 10 and the next orb is dealt only from colours that are both on the rafter and free in the
  pool (art/assets.md). Bake at the largest size, scale down only (the cup's 0.75, a growing cell's 0.3).
- **Room to play.** The first layout (orthographic 10.4 m, 7 rows above the sill) lost a run in 7-10 shots
  under a closed-loop test player; the view went to 11.2 m and 8 rows, and the first cluster to 4 rows.
- **Orbs that touch merge.** At one cell apart the clinging orbs fused into one blob of colour (no ink
  between surfaces at one depth): the orb model is r 0.40 in a 0.46 cell, so a pixel or two of sky shows
  between neighbours and each orb gets its own outline.
- **A shade step equal to the sky.** The tulip mouth (and first the rafter) shaded down to plum, the sky's
  own colour, and vanished in side light: the petal ramp shades to navy now, the rafter is orange under a
  plum transom, the planter behind the puffer is navy iron.
- **Far things rise.** With a 6-degree pitch an orthographic view lifts the rooftops 10-14 m behind the
  glass by ~1.1-1.5 m; they were first modelled 2 m tall and walled off the lower window; they are 0.15-0.8
  m now, with lit windows so the silhouettes read as a town.
- The splat gate's top view came out 10 % too deep (aspect drift 0.105): `p3_splat_fit.txt` shrinks the
  plinth, drum and lid in depth for the splats only and also exports the scene's three parts re-centred
  on their pivots.
- The Codex sheet was not reviewed by a person yet (`art/puffer/sheet.v1.png.json`, `reviewed: false`).
