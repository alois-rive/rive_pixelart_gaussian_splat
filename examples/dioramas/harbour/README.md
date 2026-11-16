# Example: a small harbour, animated

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): a fishing
boat bobbing at a pier, three seagulls circling and flapping, a lighthouse on a rocky islet, a
quay with crates and barrels, a shimmering sea. Palette: Lospec Summers Past-16.

```
art/palette.json             Summers Past-16, 8 ramps (hull, deck, white, sea, navy, grass, rock, lamp), roles
art/assets.md                the asset list: art grid, sizes, ramps, budgets, bones (step 1)
art/boat/                    the hero's Codex brief, sheet, record, and its cut views (steps 3-4)
art/textures/make_textures.py  draws the palette-exact textures (planks, sea, grass, quay blocks)
models/boat/                 spec + gate record, p1_blockout.txt, p2_form.txt, p3_motion.txt (join, skirt, bob),
                             boat_form.glb (gated form), boat.glb (animated), bake files, gate shots
models/gull/                 gull.txt (body, wings, orbit empty, flap + orbit keys), gull.glb, lookdev bake
models/env/                  sea, quay, pier, islet, lighthouse, rock, crate, barrel: command files, GLBs, textures/
lookdev/                     the turntable bench (no RML: every .bin is a blob): boat_form, boat, gull
scene.bake.json              the composition: instances, transforms, ramps, flags, animation fps/loop/phase
scene/                       the Rive project: scene.rml (tuned camera), shaders, AnimaScript, splats.bin
goldens/                     approved renders: the boat framed and at the scene's density, two scene frames
build.sh                     rebuilds textures, every model, every blob from the sources
```

Motion: the boat is one joined mesh (one bone) keyed in hedra (roll 5 deg, pitch 2 deg, rise
0.035 m; a 4 s loop); each gull is an orbit empty turning 360 deg in 8 s carrying a body with two
wing objects (three bones), six flaps then a glide. All baked at 12 fps (stepped, pixel-art
motion); the three gulls differ by `phase` (0, 2.7, 5.3 s), scale and orbit centre. 10 bones of 63.

In the live preview, **drag to orbit, wheel to zoom** (the renderer's pointer controls).

Rebuild everything from the sources (from this directory):

```sh
./build.sh                                          # textures, hedra models (from nothing), lookdev + scene blobs
rive scene --verify && rive scene                   # the live preview
```

which runs, per model, `rm -f x.rmdl && hedra model --text x.rmdl run x.txt` (and for the boat
`p1_blockout.txt`, `p2_form.txt`, `export boat_form.glb`, `p3_motion.txt`,
`export boat.glb --bake-animations`), then `splat_bake.py` on each bake file.

Gates and checks (`K=../../../.claude/skills/pixel-splat-scene`, `PY=/usr/bin/python3`):

```sh
# the boat's form against its sheet (generated-sheet tier) and its splats (albedo)
$PY $K/scripts/golden.py views --hedra models/boat/boat.rmdl -o models/boat/shots/p2 --views front,right,back,top   # after p2_form.txt
$PY $K/scripts/golden.py gate --refs art/boat/refs --shots models/boat/shots/p2 -p art/palette.json --min-iou 0.75 --max-aspect-drift 0.08
$PY $K/scripts/golden.py views --rive lookdev --blob boat_form -o models/boat/shots/p4_albedo --look albedo --views front,right,back,top
$PY $K/scripts/golden.py gate --refs art/boat/refs --shots models/boat/shots/p4_albedo -p art/palette.json --min-iou 0.7 -o models/boat/shots/p4_albedo/compare.png
# textures
$PY $K/scripts/palette.py audit models/env/textures/planks.png -p art/palette.json --ramp deck --max-colors 4
$PY $K/scripts/palette.py audit models/env/textures/sea.png -p art/palette.json --ramp sea --max-colors 4
$PY $K/scripts/palette.py audit models/env/textures/grass.png -p art/palette.json --ramp grass,deck --max-colors 4
$PY $K/scripts/palette.py audit models/env/textures/quay.png -p art/palette.json --ramp rock --max-colors 4
# goldens
$PY $K/scripts/golden.py views --rive lookdev --blob boat -o /tmp/boat
$PY $K/scripts/golden.py check --shots /tmp/boat --goldens goldens/boat
$PY $K/scripts/golden.py views --rive lookdev --blob boat -o /tmp/boat_s --texel 0.06375 --size 240 --pixel 3
$PY $K/scripts/golden.py check --shots /tmp/boat_s --goldens goldens/boat@scene
rive scene --screenshot=$PWD/shots_scene/frame_002.png --advance=2
rive scene --screenshot=$PWD/shots_scene/frame_150.png --advance=150     # 2.5 s later: boat and gulls moved
$PY $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
$PY $K/scripts/palette.py frame shots_scene/frame_002.png -p art/palette.json --pixel 3
```

Notes for whoever touches it next:

- The camera lives in `scene/scene.rml` (orthoHeight 8.5, yaw 22, pitch 30, spin 0, target
  0 / 0.4 / 0, shadeSteps 1, horizon 0.88). In this RML project `--arg` does not override an input
  that scene.rml sets: tune the RML.
- `shadeSteps` is 1 (not 1.5): the palette's darkest colour (320011) is near black, and 1.5 steps
  from the hull's c33846 reached it on every shaded face, blotching the hull and the pier.
- The gulls fly outside the blob's rest-pose bounds; the scene's bounds are large enough that the
  camera depth range and the sun's shadow map still cover them. A gull alone in the lookdev bench
  is clipped (its bounds are its rest pose only).
