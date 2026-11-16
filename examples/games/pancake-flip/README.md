# Game: Pancake Flip (Vanilla Milkshake)

**How to play:** click a pan when its pancake turns golden to flip it; burnt pancakes are strikes.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Vanilla Milkshake](https://lospec.com/palette-list/vanilla-milkshake)
by Space Sandwich, 16 pastel colours in ten ramps; it loaded from Lospec, so the spare (`apollo`) was
not needed. A cosy pastel kitchen: a mint stove with three pans between cream counters, a two-blue
tiled wall, a plate where the served pancakes pile up, syrup, butter and a batter bowl. Orthographic,
yaw 0, pitch 48, `orthoHeight` 4 m, `pixelSize` 3 (texel 0.029 m), sun from the front left (yaw -30,
pitch 50), per-splat dither, ink 1. The colour of a pancake is its state: pale batter, golden, browned,
burnt.

## Rules

- One verb: click. The first click starts a run (and flips the pan it lands on: the middle pancake is
  golden before the run, a free +3). A click hits a pan's body or its handle.
- Each pan pours batter (it spreads in) and cooks it: pale, then golden for a window, then browned,
  then burnt. The timings vary per pancake; the pace rises from x1 to x2.6 over a minute, which
  shortens the golden window from 1.5 s to about 0.9 s (and the cooking before it).
- A flip: the pan dips (anticipation) and flicks, the pancake flies up turning over once and lands
  with a squash. Golden: PERFECT, +3, a star burst. Browned: OK, +1. Both then hop onto the plate,
  where the stack grows. Raw: RAW!, it flops flat and shrinks away (0). Burnt: a strike.
- A browned pancake smokes as a warning; one left to burn is a strike (BURNT!, a cloud of smoke, a
  small camera shake). Three strikes (the X marks top right) and the KITCHEN CLOSED panel shows the
  score and the session's best; the next click starts a new run in the same kitchen.
- Runs last about 30 to 90 seconds.

**Sound** (`sfx.as`, silent in demo mode): a bright start arpeggio; batter pours with a low blop; a
pancake turning golden dings its pan's own note (C, E, G left to right), browning hisses; a flip is a
whoosh, an empty pan a tink; PERFECT lands with a soft thud and a chime two semitones higher for each
perfect in a row, OK with a low blip, RAW! with a wet flop; a served pancake pops onto the plate, higher
as the stack grows; a strike is a crunch (lower with each one) and a poof; KITCHEN CLOSED is the falling
game-over arpeggio, with a high bell for a new best.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the run starts at once with the middle
pan golden; the demo cook flips it within half a second. For each new pancake it picks its moment:
mostly inside the golden window, 14 % a little late (browned), 6 % too eager (raw), 6 % forgotten
(burnt); it clicks one pan at a time with 0.2 to 0.4 s between clicks, so two pans due at once cost
it. Its runs last about 50 to 60 seconds; it restarts itself two seconds after KITCHEN CLOSED. When
demo is switched off, a fresh run starts at once.

## What is where

```
art/palette.json, palette.png   Vanilla Milkshake with ramps batter, golden, burnt, iron, berry, mint, tile,
                                cream, flame, cake; roles
art/assets.md                   the asset list, bones, layout
art/pan/                        the hero's Codex briefs and sheets (v1 cropped, v2 used) with records, refs/
models/pan/                     spec + gate record, p1_blockout.txt, p2_form.txt, p3_parts.txt, pan.glb (gated),
                                pan_splat.glb (the lookdev hero), pan_only.glb (the scene's pans), pan.bake.json,
                                gate shots
models/env/                     make_env.py writes kitchen, burner, plate, bottle, butter, bowl, pancake_raw,
                                pancake_golden, pancake_dark, pancake_burnt, smoke, star .txt; their GLBs
lookdev/                        the turntable bench (no RML): pan.bin
scene.bake.json                 the composition: kitchen, props, game bones (pan0-2, raw/gold/dark/burnt0-2,
                                stack0-9, smoke0-5, star0-5), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        pan (framed), pan@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 37 of 63. Splats: 31 963 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the pan (p1, p2, p3), lookdev/pan.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/pan/pan.rmdl -o /tmp/pan_p2 --views front,back --elevation 10
python3 $K/scripts/golden.py views --hedra models/pan/pan.rmdl -o /tmp/pan_p2/rt --views right,top && mv /tmp/pan_p2/rt/*.png /tmp/pan_p2/
python3 $K/scripts/golden.py gate --refs art/pan/refs --shots /tmp/pan_p2 --min-iou 0.75     # back aspect: waiver in the spec
python3 $K/scripts/golden.py views --rive lookdev --blob pan -o /tmp/pan_alb --look albedo --views front,back --elevation 10
python3 $K/scripts/golden.py views --rive lookdev --blob pan -o /tmp/pan_alb/rt --look albedo --views right,top && mv /tmp/pan_alb/rt/*.png /tmp/pan_alb/
python3 $K/scripts/golden.py gate --refs art/pan/refs --shots /tmp/pan_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=-30 --arg sunPitch=50)
python3 $K/scripts/golden.py views --rive lookdev --blob pan -o /tmp/pan --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/pan --goldens goldens/pan
python3 $K/scripts/golden.py views --rive lookdev --blob pan -o /tmp/pan_s --texel 0.0294 --size 160 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/pan_s --goldens goldens/pan@scene
for n in 30 90 240; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Play it headless: `rive scene --screenshot=$PWD/p.png --advance=30 --pointer=click@320,185 --advance=60`
(a click on the golden middle pan: +3). The pans' centres are at (220, 185), (320, 185), (420, 185).

## Notes from building it

- Sheet v1 drew the long handle across the panel edges (`sheet_cut.py`: cropped); v2's brief adds a
  margin line first. v2's front and back views are drawn from ~10 degrees above, its right and top
  square-on: the gate renders the two pairs at their own elevations.
- A flat pan (0.22 m tall, 1.47 m long) is the case where splat spread dominates: at 1.5 texels the
  right view's aspect drifted 0.62. Baking it at about one texel and shrinking the splat copy by the
  measured spread on every axis (`p3_parts.txt`) brought every view inside the tier; the hedra model
  keeps the sheet's size. The pancakes are modelled 0.03 m thin for the same reason.
- In hedra, `active X` adds X to the selection: a `set rotation` after it turned every selected
  object, and `material assign` painted them all. Every per-object step starts with `select X`.
- Cooking is a swap between four pancake bones per pan (game.as cannot recolour splats).
- The first renderer drew the HUD from the screen's top-left and the scene's blit from its snapped,
  centred offset: the camera target was put a third of a texel off the art grid (`targetX` -0.009804,
  `targetY` 0.014652, texel = 4 / 136) so both shared one pixel grid (`palette.py frame`: phase 0,0,
  100 % solid), and the strike shake moves the target by whole texels. The renderer now aligns the
  HUD itself; the offset is kept (harmless, and the goldens were snapped with it).
- The first renderer drew the HUD one path per colour; it now draws in call order, and `hud()` draws
  every panel before the text on it.
- The Codex sheets were not reviewed by a person yet (`art/pan/sheet.v2.png.json`, `reviewed: false`).
