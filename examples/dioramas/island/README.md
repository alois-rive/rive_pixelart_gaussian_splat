# Example: a floating island, end to end (Fading 16)

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`), every step
run for real with rive 1.9.2, hedra 0.1.0 and codex-cli 0.167. Palette:
[Fading 16](https://lospec.com/palette-list/fading-16), 16 colours.

What moves: the pines sway (shader wind); a small campfire burns in front of the well, left of it
from the default view. Its three flame tongues flicker on a stepped 1 s loop (12 frames, one bone
each), and a seamless column of six smoke puffs rises from it (each puff one 6 s loop, the six a
second apart). The lower puffs catch the fire's flickering light: each puff carries two unlit warm
caps on its underside (terracotta, and tan below it) that pop out of the puff when the fire is bright
enough for the puff's height and shrink back inside it otherwise, keyed from the same 12-frame
intensity table as the flames (phases in whole seconds keep every puff in step with the fire). The
lowest puffs glow on every frame and flare tan with the flames, the middle ones only on the fire's
flares, the top ones never. All baked (21 of 63 bones), no shader effect, no `game.as`.

```
art/palette.json             Fading 16 (16 colours) with its ramps (step 2)
art/assets.md                the asset list (step 1)
art/well/                    the hero's Codex briefs and sheets (v1 in Endesga 32, v2 in the final Fading 16), records, cut views (refs.v2)
art/textures/                the grass texture: Codex brief, 1254 px generation, 32 px fit
models/well/                 spec, p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB (steps 5-7)
models/env/                  island, pine, rock, lantern, campfire, smoke: hedra command files and GLBs;
                             make_campfire.py writes campfire.txt and smoke.txt
lookdev/                     the turntable bench (no RML: every .bin is a blob)
scene.bake.json              the composition: instances, transforms, material -> ramp, flags
scene/                       the Rive project: scene.rml, shaders, AnimaScript, splats.bin
goldens/                     approved renders: the well framed and at the scene's density, three scene frames
                             (2: the fire flaring, smoke lit warm; 8: a dip; 120: the camera turned)
```

Rebuild everything from the sources (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
(cd models/env && /usr/bin/python3 make_campfire.py)
for m in island pine rock lantern campfire smoke; do (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt); done
(cd models/well && rm -f well.rmdl && hedra model --text well.rmdl run p1_blockout.txt \
  && hedra model --text well.rmdl run p2_form.txt && hedra model well.rmdl export well.glb)
python3 $K/scripts/splat_bake.py models/well/well.bake.json
python3 $K/scripts/splat_bake.py scene.bake.json
rive scene --verify && rive scene                      # the live preview: drag to orbit, wheel to zoom
```

Check it against the goldens:

```sh
python3 $K/scripts/golden.py views --rive lookdev --blob well -o /tmp/well --size 320 --pixel 2
python3 $K/scripts/golden.py check --shots /tmp/well --goldens goldens/well    # prints the exact views command if the settings differ
python3 $K/scripts/golden.py views --rive lookdev --blob well -o /tmp/well_s --texel 0.0625 --size 160 --pixel 2
python3 $K/scripts/golden.py check --shots /tmp/well_s --goldens goldens/well@scene  # the well at the scene's density
for n in 2 8 120; do rive scene --screenshot=$PWD/shots_scene/frame_$(printf %03d $n).png --advance=$n; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/frame_002.png -p art/palette.json --pixel 3
```

The campfire (`models/env/make_campfire.py`, palette ramps `fire` and `smoke`):

- `fire` = plum, brick, terracotta, tan, cream (all unlit: ember bed brick, flame base terracotta,
  side tongues tan, core cream; the ink steps the flames' edges one down). `smoke` = slate, grey,
  grey, light grey: the puffs are painted on the second grey (`"step": 1` in the bake), so a face
  turned from the sun drops to the first grey and only the far side reaches slate (a three-step ramp
  made the whole column slate).
- Puffs are born at the flames' tips (born inside them, the lowest puffs hid the fire) and are
  sampled at their full size (frame 0 of the clip is the moment the puff is largest).
- The well's goldens (`goldens/well`, `well@scene`) were taken with the real sky but their records
  predate `real_sky`, so `check` renders them with the mask sky; with `--real-sky` the current
  renderer still differs from them by ~40 % (the original bench renders the same, 0.0000 % against
  the rebuilt one): they need a re-approval, unrelated to the campfire.
