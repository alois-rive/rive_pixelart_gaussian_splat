# Game: Lily Hop (Sweetie 16)

**How to play: click to hop forward; land on a lily pad, not in the water.**

**Touch:** tap anywhere to hop.

A frog crosses a pond on drifting lily pads. Each hop that lands on a pad scores 1; reaching a bank scores 5
more, turns the frog round and speeds the lanes up. A firefly hovering over a lane is worth 3 if the frog
lands under it. Miss a pad, or ride one into the reeds at the pond's sides, and it is a splash: game over,
with the score and the session's best; the next click starts a new run on the same pond. Demo mode
(`--arg demo=true`, or the `Sample` view model's `demo`) plays like a decent human: it waits a beat after
each landing, judges the gap with an error that grows as the lanes speed up, hops early when a pad nears
the reeds, and restarts two seconds after a splash.

Sound (procedural, `api.sound`; silent in demo): a short jingle on the first hop; each hop springs up, and a
pad landing is a soft plop with a plucked note that climbs a pentatonic scale lane by lane across the pond (a
step higher each crossing); a bank lands with a thud and a rising arpeggio (higher each crossing); a firefly
chimes; a miss is a splash and a falling tune (into the reeds: a rustle first); a blip to play again.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra
0.1.0, codex-cli. Palette: [Sweetie 16](https://lospec.com/palette-list/sweetie-16) by GrafxKid (loaded from
Lospec; the spare `pear36` was not needed), 7 ramps. Orthographic camera, yaw 0, pitch 48, 7.4 m tall,
pixelSize 3; a soft sun from the front left; per-splat dither; the water's splats sway, so it shimmers.

```
art/palette.json, palette.png   Sweetie 16 with ramps water, frog, pad, petal, cream, stone, glow
art/assets.md                   the asset list, layout, bones
art/frog/                       the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/frog/                    spec + gate record, p1_blockout.txt, p2_form.txt, p3_splat_fit.txt, bake file, gate shots, GLB
models/env/                     pond, pad, lotus, reeds, rock, bush, fly, splash, ripple: command files and GLBs;
                                make_water.py draws textures/water.png
lookdev/                        the turntable bench (no RML): frog.bin
scene.bake.json                 the composition: game bones (frog, pads 0-13, lotus 0-5, fly, splash, ripple), bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer files
goldens/                        frog framed and at the scene's density; scene/: demo_045, demo_200, demo_280, frame_030
shots_scene/                    the scene frames the goldens were snapped from
build.sh                        rebuilds every model and blob from the command files
```

What moves (24 game bones of 63, all written by `game.as`): the frog (crouch squash, take-off stretch,
arc, landing squash, a stepped idle breath, a turn at each bank, a sinking splash), 20 pads (drift, slow
spin, bob, a damped dip when landed on or left), the firefly (stepped wing flap, a pop when caught), a
splash crown and a ripple ring.

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # textures, models, lookdev/frog.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary
rive scene                                   # play: click to hop
rive scene --arg demo=true                   # the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/frog/frog.rmdl -o /tmp/lh_p2 --views front,right,back,top   # after p2 only (build.sh runs p3 too)
python3 $K/scripts/golden.py gate --refs art/frog/refs --shots /tmp/lh_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob frog -o /tmp/lh_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/frog/refs --shots /tmp/lh_alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunYaw=-35 --arg sunPitch=52 --arg keyLight=0.42 --arg highlight=0.86 --arg shadeSteps=1.2"
python3 $K/scripts/golden.py views --rive lookdev --blob frog -o /tmp/lh_f --real-sky --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/lh_f --goldens goldens/frog
python3 $K/scripts/golden.py views --rive lookdev --blob frog -o /tmp/lh_fs --real-sky --texel 0.039 --size 160 --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/lh_fs --goldens goldens/frog@scene
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
for n in 45 200 280; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Notes from building it:

- The first framing put the far bank under the HUD, and the frog vanished there; the lanes moved to
  1.15 m apart, the banks in to +-3.55 and the target to z -0.6.
- Bushes first shifted onto the far bank's row hid the frog after a crossing; they sit behind it now.
- The frog grew from 1.25 to 1.4 in the scene to read at 213 x 133; its bench was re-baked at the
  matching density (0.057) and re-gated.
- Splat fattening: the gates disagree for a small, flat-footed character at this density (mesh gate passes,
  splat gate failed on aspect): `p3_splat_fit.txt` compensates before the bake (spec).
- The Codex sheet was not reviewed by a person yet (`art/frog/sheet.v1.png.json`, `reviewed: false`).
