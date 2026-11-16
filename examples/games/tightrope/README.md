# Game: Tightrope (Dreamscape8, 8 colours)

**How to play: click to start, then move the pointer to keep the walker upright: he leans towards
the pointer, so when he tips one way, move it to his other side. Gusts blow down the gorge.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Dreamscape8](https://lospec.com/palette-list/dreamscape8) by Kerrie
Lake, eight colours; it loaded from Lospec, so the spare (`nanner-pancakes`) was not needed. A desert
evening: banded rust and red-brown cliffs, sand rims with sage cacti, teal-grey sky with fogged mesas
and a pale sun, the walker in teal-grey and red-brown with a cream pole.

The rules: the walker crosses a rope over a gorge, back and forth, at 0.85 m/s. He is an inverted
pendulum: his lean grows by itself, every step nudges it, and gusts push him (announced 0.9 s ahead
by wind streaks, the pennants turning and "WIND >>>"). The pointer's horizontal distance from him
(6 HUD pixels dead zone, full at 60) pulls him towards it; a little arrow under his feet shows the
pull, the BALANCE gauge his lean. Past 20 degrees he stops walking and wobbles; past 43 he falls into
the river. Score: the metres he walked plus 10 for each crossing (a cheer and a turn on the far
platform); the gusts grow stronger and more frequent with every crossing. "HE FELL!" ends the run;
the next click starts again on the first platform. Pointer only.

Sound (`sfx.as`, silent in demo mode): a little four-note circus fanfare starts a run; every step on
the rope creaks, higher and louder the more he leans, and past half the fall angle warning ticks speed up
and climb as he tips. A gust is announced by a faint high whoosh from the side it blows from and arrives
as a big low whoosh (lower and louder for a stronger gust); a crossing is a coin and a bell, both higher
with every crossing. A fall is a long falling whistle, then a splash and the losing arpeggio.

Demo mode (`--arg demo=true`, or the `Sample` view model's `demo`): it opens mid-rope with a gust
blowing; a controller that sees his lean 0.2 s late pulls against it (and against a gust it has seen
coming), at a hand's speed, and looks away for a moment every few seconds (longer as the crossings
mount), so it falls sooner or later; it restarts two seconds after the fall. When demo turns off, a
fresh run starts.

What moves (16 of 63 bones, all game bones moved by `scene/game.as`): the walker and his pole (the
pole attached to his hands with `api.transform`), the rope's two spans (stretched to his feet so the
rope sags under him), two pennants, 8 wind streaks, a splash, a hawk circling over the gorge.

```
art/palette.json, palette.png   Dreamscape8 with ramps rock, cool, red, rope, water, wind; roles
art/assets.md                   the asset list, bones, layout, camera
art/walker/                     the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/walker/                  p1_blockout.txt, p2_form.txt, p3_body.txt, p3_pole.txt; spec + gate record
                                (waivers), bake file, gate shots, walker(_body, _pole).glb
models/env/                     make_env.py -> cliffs, river, mesas, stand, rope, flag, streak, splash,
                                bird, cactus, rock, sun (.txt command files and .glb)
lookdev/                        the turntable bench (no RML): walker.bin
scene.bake.json                 the composition: instances, game bones, bounds
scene/                          the Rive project: scene.rml (perspective look-at, fov 38, pixelSize 2),
                                game.as (the whole game), the renderer files, splats.bin
goldens/                        walker/, walker@scene/, scene/ (demo_040, demo_300, demo_900; frame_030)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Rebuild and play (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models from scratch, lookdev/walker.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary
rive scene                                   # play; `rive scene --arg demo=true` to watch the demo
```

Check (gates, goldens, frame audit, a run left alone falls):

```sh
python3 $K/scripts/golden.py views --hedra models/walker/walker.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/walker/refs --shots /tmp/p2 --min-iou 0.75         # top: waiver in the spec
python3 $K/scripts/golden.py views --rive lookdev --blob walker -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/walker/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7
L="--arg sunYaw=-62 --arg sunPitch=32 --arg keyLight=0.45 --arg highlight=0.8"
python3 $K/scripts/golden.py views --rive lookdev --blob walker -o /tmp/w --real-sky ${=L}            # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/w --goldens goldens/walker
python3 $K/scripts/golden.py views --rive lookdev --blob walker -o /tmp/ws --texel 0.045 --size 120 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/ws --goldens goldens/walker@scene
mkdir -p /tmp/tr; for n in 040 300 900; do rive scene --screenshot=/tmp/tr/demo_$n.png --advance=${n#0} --arg demo=true; done
rive scene --screenshot=/tmp/tr/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots /tmp/tr --goldens goldens/scene
python3 $K/scripts/palette.py frame goldens/scene/demo_300.png -p art/palette.json --pixel 2
rive scene --screenshot=/tmp/fall.png --advance=2 --pointer=click@420,300 --advance=420   # no balancing: he falls
```

Notes from building it:

- The first camera (orthographic, yaw 60, to show the lean) saw the walls edge-on and no sky; looking
  along the rope from behind the start, in perspective, shows the gorge, the far wall face-on, the
  sky, and the lean as a plain tilt. A perspective camera that never moves has no snap offset, so
  the HUD stays aligned (100 % solid blocks).
- Faces the camera never sees are deleted in make_env.py (towards +X, the ends, the bottoms) and the
  far rock is baked coarser: 300 000 splats came down to 103 000.
- A pointer left still is a growing pull as he walks away on screen, so the pull has a dead zone and a
  60-pixel range; the topple (2.2) is slow enough to catch.
- `placeScaled` with pitch and roll stretches the rope's spans; the rope is modelled 14 m long and
  only ever shortened, because a splat's size does not grow with its bone's scale.
- The Codex sheet was not reviewed by a person yet (`art/walker/sheet.v1.png.json`, `reviewed: false`).
