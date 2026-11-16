# Game: Penguin Slide (Mist GB, 4 colours)

**How to play: click (or tap) to jump; the penguin belly-slides along an endless ice run, jump the
holes between the floes and the seals lying on them, catch fish for +5.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Mist GB](https://lospec.com/palette-list/mist-gb) by Kerrie Lake
(loaded from Lospec; the spare was not needed), four colours (dark brown, teal, mint, pale) shared by
seven ramps. A pale arctic day: an orthographic side view pitched 12 degrees down, the sun from the
front left, per-splat dither, the far bergs and range fading into the mint haze (fog), the sea
stippled where it meets the sky.

Rules: the first click starts the slide (the hint shows until then). Each click jumps (a fixed arc,
0.61 s, 0.71 m high; a click just before landing is kept and jumps again on landing). Falling into a
hole (SPLASH!) or sliding into a seal (BONK!) ends the run: the game-over line shows the metres and
fish, and the next click starts a new run on the same ice. Score = metres slid + 5 a fish; the best
score is kept for the session. The speed rises from 4 to 8.5 m/s, the holes widen with it and the
seals come more often, so every run gets harder until it ends.

Demo mode (`--arg demo=true`, the gallery's `demo`): the penguin plays itself from frame 0 (the first
hole comes up at once: a jump with a fish at about 0.6 s, a seal hopped at 2.8 s). It plans each jump
from the hole's or seal's take-off window like a player, aims a little late with an error that grows
with the run and fumbles now and then (from 4 s on), so it crashes after 8 to 20 s, and starts again
2 s after a game over. When demo turns off, a fresh run waits for the first click.

What moves (37 game bones of 63, no baked tracks: everything is placed by `scene/game.as`): the penguin
(slide wobble at 8 fps, anticipation squash, take-off stretch, nose up then down in the air, landing
squash, a tumble onto its back on a bonk, a dive on a splash); nine ice floes (3, 5 and 8 m, three
copies each) recycled ahead of it; three seals (breathing, looking up as the penguin comes, a startled
hop); four fish (spinning, bobbing, popping when caught); five snow puffs (the spray and the landing
burst); a splash crown; five floating chunks; two strips of wave crests; four bergs and two ranges of
peaks in parallax (35 % and 12 % of the camera, snapped to whole texels); the sea, carried with the
camera.

How the camera follows: the course lives in logical metres; every bone is placed at logical − origin,
and the origin jumps by 12 m whenever the penguin passes +4 m, so the play stays inside the bake's
`bounds` (x ±12 m: the shadow map's reach) for any run length. The texel is exactly 0.032 m
(`orthoHeight` 4.352 over 136 art rows), so the 12 m wrap and the 1.6 m camera lead are whole texels:
a wrap changes no pixel, and the penguin, the sea and the backdrop are placed on the snapped camera's
grid so they never crawl. The renderer keeps the HUD on the art grid's phase while the snapped camera
slides (an earlier `hud()` workaround did this by hand; it is gone, with pixel-identical frames).

```
art/palette.json, palette.png   Mist GB with ramps snow, ice, water, feather, belly, seal, glint
art/assets.md                   the asset list, ramps table, layout
art/penguin/                    the hero's Codex briefs and sheets (v1 cropped, v2 used), records, cut views (refs/)
models/penguin/                 spec + gate record, p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB
models/env/                     make_env.py (writes every other model's hedra command file), *.txt, GLBs
lookdev/                        the turntable bench (no RML): penguin.bin
scene.bake.json                 the composition: every object a game bone or pool, bounds, material -> ramp
scene/                          the Rive project: scene.rml (camera and look), game.as (the whole game), splats.bin
goldens/                        the penguin framed and at the scene's texel; scene/: demo_040, demo_170, demo_560, frame_010
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models/env + penguin from scratch, lookdev/penguin.bin, scene/splats.bin
rive scene --verify && rive scene            # play: click to jump
rive scene --arg demo=true                   # watch the demo
```

Check (gates, goldens, frame audit; zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/penguin/penguin.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/penguin/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob penguin -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/penguin/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunYaw=-35 --arg sunPitch=45 --arg keyLight=0.45 --arg highlight=0.85 --arg shadeSteps=1 --arg bandDither=0.4"
python3 $K/scripts/golden.py views --rive lookdev --blob penguin -o /tmp/pg --real-sky --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/pg --goldens goldens/penguin
python3 $K/scripts/golden.py views --rive lookdev --blob penguin -o /tmp/pgs --texel 0.0256 --size 160 --real-sky --views front,right,back,top,iso ${=L}
python3 $K/scripts/golden.py check --shots /tmp/pgs --goldens goldens/penguin@scene
for n in 40 170 560; do f=$(printf %03d $n); rive scene --screenshot=$PWD/shots_scene/demo_$f.png --advance=$n --arg demo=true --quiet; done
rive scene --screenshot=$PWD/shots_scene/frame_010.png --advance=10 --quiet
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Try it headless: `rive scene --screenshot=$PWD/play.png --advance=20 --pointer=click@320,200 --advance=80
--pointer=click@320,200 --advance=20` starts a run and jumps the first hole (a fish, +5); leave out the
second click and the penguin slides into the hole (SPLASH!).

Notes from building it:

- A low pitch flattens anything lying on the water: wave marks became small wedges standing on the sea,
  and the far bergs and peaks are tiny (0.3-0.5 m): in an orthographic view distance does not shrink
  them, only size and fog say "far".
- With the sea's ramp reaching dark brown, every floe and the jumping penguin cast a dark smear on the
  water; the sea's ramp stops at teal.
- The Codex sheet's views disagree on the penguin's width (front 0.644 vs back 0.697 aspect); the spec
  records the compromise. The sheets were not reviewed by a person yet (`reviewed: false`).
