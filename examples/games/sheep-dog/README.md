# Game: sheep dog (DawnBringer 16)

**How to play:** click, then steer the dog with the pointer (move or drag): the sheep flee from it; herd all
six through the pen's gate before the 45 seconds run out.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra 0.1.0,
codex-cli. Palette: [DawnBringer 16](https://lospec.com/palette-list/dawnbringer-16) (loaded from Lospec; the
spare `fantasy-24` was not needed), as ten ramps (grass, leaf, wool, face, fur, cream, wood, stone, water, red).
A sunny meadow seen from a fixed orthographic camera (yaw 0, pitch 42, 8.4 m tall, `pixelSize` 2: 320 x 200 art
pixels), sun from the front left, per-splat dither, ink 1.

Rules: a sheep runs from the dog when it comes within 2.7 m, peels off fences, flocks a little when scared and
grazes when left alone. One that walks through the gate is penned: +100, or +150 when it follows another within
3 s. Pen all six and every second left is worth 10 more, and the gate swings shut. The timer ends a run
otherwise. A click after the game-over line starts a new run in the same meadow; the best score is kept for
the session.

Sound (`sfx.as`, silent in demo mode): a rising two-note shepherd's whistle starts a run; a sheep startled
by the dog gives one short note in its own voice (one of three, at most one every third of a second); a
penned sheep is a coin climbing with every sheep in (brighter for a +150 follow-up) and a bleat of three
soft high notes, the last one falling, panned to the pen. The last ten seconds tick (sharper for the last
three); all six penned is a win fanfare and the gate's latch clicking shut, time up the losing arpeggio.

Demo (`--arg demo=true`, or the `Sample` view model's `demo`): a decent shepherd that picks the free sheep
nearest the gate, runs round behind it (flanking on the side the pen does not block) and drives it at the gate,
aiming up to 0.8 m off and re-thinking every 0.3 s; it pens about four of six in 45 s and starts again 2 s after
the game-over line. When demo is switched off a fresh run starts at once.

```
art/palette.json, palette.png   DawnBringer 16 with its ramps and roles
art/assets.md                   the asset list, the art grid, the play area
art/dog/                        the hero's Codex brief, sheet v1 (reviewed: false), record, cut views (refs/)
models/dog/                     spec + gate record, p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB
models/sheep/                   sheep.txt (from the asset list), GLB
models/env/                     make_env.py (writes ground, fence, gate, tree, rock, pond, hay, trough command
                                files and the grass texture), the command files, textures/grass.png, GLBs
lookdev/                        the turntable bench (no RML): dog.bin
scene.bake.json                 the composition: 74 000 splats, 8 game bones (gate, dog, sheep0-5), bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        dog (framed), dog@scene (texel 0.042), scene (demo_060/420/1500, frame_030)
shots_scene/                    the scene frames the goldens were snapped from
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models from scratch, lookdev/dog.bin, scene/splats.bin
rive scene --verify && rive scene            # play it
rive scene --arg demo=true                   # watch the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/dog/dog.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/dog/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob dog -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/dog/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob dog -o /tmp/dog --real-sky --arg sunYaw=-40 --arg sunPitch=50
python3 $K/scripts/golden.py check --shots /tmp/dog --goldens goldens/dog
python3 $K/scripts/golden.py views --rive lookdev --blob dog -o /tmp/dog_s --texel 0.042 --size 160 --real-sky --arg sunYaw=-40 --arg sunPitch=50
python3 $K/scripts/golden.py check --shots /tmp/dog_s --goldens goldens/dog@scene
for n in 60 420 1500; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_420.png -p art/palette.json --pixel 2
# a played run: click to start, drag the dog, then let the time run out
rive scene --screenshot=$PWD/played.png --advance=30 --pointer=click@320,330 --advance=40 \
  --pointer="drag@120,300>200,200:30" --pointer="drag@200,200>420,230:40" --advance=10
```

Notes from building it:

- `pixelSize` 2 (not 3): when this was built, the HUD was drawn from the artboard's top-left corner while the
  scene's art grid is centred, so at 3 (640 / 3 is not whole) the grids differed by two screen pixels and the
  frame audit fell to 94 % solid blocks. The template has since aligned the HUD with the art grid at every
  `pixelSize`; the camera target still sits on the art grid (z -0.621), so the picture never slides.
- The dog first baked at 0.75 scale and 0.07 m spacing starved (362 splats, legs as specks); it is a toy-scale
  dog now, a little longer than a sheep, baked at 0.05 m.
- Sheep pushed against the back fence used to sit in the pocket behind the pen's left wall, where no dog can get
  behind them; frightened sheep now peel off fences (not at the gate gap), and the demo's flank avoids the pen.
- The Codex sheet was not reviewed by a person yet (`art/dog/sheet.v1.png.json`, `reviewed: false`).
