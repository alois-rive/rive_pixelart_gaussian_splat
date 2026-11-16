# Example: a desert oasis, animated

A floating dune chunk with a pond, three swaying palms, a market stall, rocks and shrubs, and a
skinned camel pacing round the pond. Built with the `pixel-splat-scene` skill
(`../../../.claude/skills/pixel-splat-scene`), rive 1.9.2, hedra 0.1.0. Palette: Lospec
"Parchment and Ink" (16 colours, sepia). In the live preview: drag to orbit, wheel to zoom.

```
art/palette.json             Parchment and Ink, 8 ramps (dune, fur, palm, bark, water, cloth, stone, ink)
art/assets.md                the asset list (step 1), with the animation and bone count
art/camel/                   the hero's Codex brief, sheet and cut views (steps 3-4)
art/textures/                make_textures.py and its palette-exact sand, water, canopy textures
models/camel/                spec + gate record, p1_blockout, p2_form, p3_rig (armature, weights, walk),
                             p4_orbit (the walk baked round the pond), build.sh, bake files, gate shots, GLBs
models/palm/palm.txt         trunk rings, fronds, 4-bone rig and sway: palm.glb
models/env/                  ground, stall, rock, shrub: hedra command files and GLBs
lookdev/                     the turntable bench (no RML: every .bin is a blob): camel.bin, camel_rest.bin
scene.bake.json              the composition: instances, transforms, material -> ramp, flags, fps, phase
scene/                       the Rive project: scene.rml (tuned inputs), shaders, AnimaScript, splats.bin
goldens/                     the camel framed and at the scene's density, two scene frames (t = 2 and 240)
```

What moves: the camel (skinned, 12 bones, a 1.2 s pace baked over a 14.4 s orbit, 10 fps), the
palms (skinned, 4 bones each, a 4 s sway, phases 0 / 1.3 / 2.6 s), the water and shrubs
(`sway` flag). 20 515 splats, 24 of 63 animated bones.

Rebuild everything from the sources (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
python3 art/textures/make_textures.py
models/camel/build.sh                                   # camel.glb (walk in place), camel_orbit.glb
(cd models/palm && rm -f palm.rmdl && hedra model --text palm.rmdl run palm.txt)
for m in ground stall rock shrub; do (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt); done
python3 $K/scripts/splat_bake.py models/camel/camel.bake.json        # lookdev/camel.bin (animated)
python3 $K/scripts/splat_bake.py models/camel/camel_rest.bake.json   # lookdev/camel_rest.bin (rest pose, for the gate)
python3 $K/scripts/splat_bake.py scene.bake.json                     # scene/splats.bin
rive scene --verify && rive scene                      # the live preview
```

Check it (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/camel/camel.rmdl -o /tmp/p2 --views front,right,back,top,iso   # run on a p1+p2 build
python3 $K/scripts/golden.py gate --refs art/camel/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob camel_rest -o /tmp/alb --look albedo
python3 $K/scripts/golden.py gate --refs art/camel/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7   # waivers: models/camel/camel.spec.md
python3 $K/scripts/golden.py views --rive lookdev --blob camel -o /tmp/camel --arg shadeSteps=1
python3 $K/scripts/golden.py check --shots /tmp/camel --goldens goldens/camel
python3 $K/scripts/golden.py views --rive lookdev --blob camel -o /tmp/camel_s --texel 0.0705 --size 160 --arg shadeSteps=1
python3 $K/scripts/golden.py check --shots /tmp/camel_s --goldens goldens/camel@scene
rive scene --screenshot=$PWD/shots_scene/frame_002.png --advance=2
rive scene --screenshot=$PWD/shots_scene/frame_240.png --advance=240
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/frame_002.png -p art/palette.json --pixel 3
```

A strip of the walk in one run (`--commands` keeps one session, so the frames are 0.1 s apart):

```sh
printf 'advance 2\nscreenshot /tmp/w0.png\nadvance 6\nscreenshot /tmp/w1.png\nadvance 6\nscreenshot /tmp/w2.png\n' | rive scene --commands
```

Notes from building it:

- hedra's `join` merges vertex groups by index, not by name. The rigs give every part the same
  group list first (one `parent set Rig --type armature --empty-groups` over all parts), fill each
  part's own bone group, then join (models/camel/p3_rig.txt).
- The baker evaluates every animation of a GLB at the same time (mod the longest), so a 1.2 s walk
  next to a 14.4 s orbit stops after one stride. p4_orbit.txt sets the walk cyclic and
  `action bake`s it over the orbit's 288 frames (Rig selected alone).
- Parchment and Ink ramps start at black: bases sit on step 2+, `shadeSteps` is 1, and the sand
  is the light #e6d1a1 so the #c0977a camel reads against it.
