# Example: a cabin in an autumn wood (Oil 6)

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [Oil 6](https://lospec.com/palette-list/oil-6), 6 colours.
A soft pastel, painterly look: big splats (0.14 m, 2.2 texels), tone jitter 0.4, per-splat dither,
a warm low sun (pitch 30) with long splat shadows, gentle fog, ink 1, a two-colour dusk sky.

What moves (stepped): chimney smoke (three puffs that rise, drift with the wind, grow and dissolve;
a seamless 4 s loop, 8 fps), falling leaves (40 thin bands of one column falling 9 m per 20 s with a sway,
seamless, each leaf ending in the ground, 10 fps), the seven maples sway about their feet (rigid, +-2 deg, 4 s, out of phase) and
their crowns twinkle in the wind (`sway`); the camera orbits at 3 deg/s.

```
art/palette.json, palette.png   Oil 6 with ramps ground, wood, roof, leaf, smoke, glow
art/assets.md                   the asset list (sizes, ramps, animation, bones)
art/cabin/                      the Codex brief, sheet v1, its record, cut views (refs/)
models/cabin/                   spec with the gate record, p1_blockout.txt, p2_form.txt, logs texture
                                (make_textures.py), bake file, gate shots, GLB
models/env/                     ground, maple, woodpile, mushrooms, rock, smoke, leaves: command files and GLBs;
                                make_textures.py (ground + path), make_leaves.py (writes leaves.txt)
lookdev/                        the turntable bench (no RML)
scene.bake.json                 the composition, with per-object animation (fps, phase)
scene/                          the Rive project (scene.rml tuned: low warm sun, jitter, fog, dusk sky, orbit on)
goldens/                        cabin framed and at the scene's density; three scene frames
shots_scene/                    the scene frames at --advance 2, 90, 240
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
(cd models/env && python3 make_textures.py && python3 make_leaves.py \
  && for m in ground maple woodpile mushrooms rock smoke leaves; do rm -f $m.rmdl; hedra model --text $m.rmdl run $m.txt; done)
(cd models/cabin && python3 make_textures.py && rm -f cabin.rmdl && hedra model --text cabin.rmdl run p1_blockout.txt \
  && hedra model --text cabin.rmdl run p2_form.txt)
python3 $K/scripts/splat_bake.py models/cabin/cabin.bake.json
python3 $K/scripts/splat_bake.py scene.bake.json
rive scene --verify && rive scene                      # the live preview: drag to orbit, wheel to zoom
```

Check:

```sh
python3 $K/scripts/golden.py views --hedra models/cabin/cabin.rmdl -o /tmp/cp2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/cabin/refs --shots /tmp/cp2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob cabin -o /tmp/ca --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/cabin/refs --shots /tmp/ca -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
for n in 2 90 240; do rive scene --screenshot=$PWD/shots_scene/frame_$(printf %03d $n).png --advance=$n; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/frame_002.png -p art/palette.json --pixel 3
python3 $K/scripts/golden.py views --rive lookdev --blob cabin -o /tmp/cd --size 320 --pixel 2 \
  --arg jitter=0.4 --arg bandDither=0.5 --arg keyLight=0.3 --arg highlight=0.85 --arg shadeSteps=1.2
python3 $K/scripts/golden.py check --shots /tmp/cd --goldens goldens/cabin
```
