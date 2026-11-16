# Example: a Game Boy farm (Kirokaze Gameboy, 4 colours)

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [Kirokaze Gameboy](https://lospec.com/palette-list/kirokaze-gameboy),
4 colours. A little farm on a floating grass plateau, styled as a Game Boy game: 160 x 100 big art
pixels (`pixelSize` 4), crisp small splats (0.12 m, 1.2 texels), Bayer ordered dither on the art grid
(`splatDither` false, `bandDither` 0.6), shade as a 50 % checker one step down (`shadeSteps` 0.5),
a one-step self-coloured outline (`ink` 1), no fog, a flat `#e2f3e4` sky, a fixed camera.

What moves: the windpump's six-bladed rotor turns (rigid, one bone, a turn every 4 s, baked and played
stepped at 12 fps); the two trees' crowns sway.

```
art/palette.json, palette.png   Kirokaze Gameboy with ramps grass, barn, wood, roof, paint, water (slices of the 4 colours)
art/assets.md                   the asset list
art/barn/                       Codex brief, sheet.v1.png and its record, cut views (refs/)
models/barn/                    spec + gate record, p1_blockout.txt, p2_form.txt, textures (make_textures.py), bake file, gate shots, GLB
models/env/                     plateau, windpump, field, fence, haystack, tree: command files and GLBs
lookdev/                        the turntable bench (no RML)
scene.bake.json                 the composition
scene/                          the Rive project (scene.rml tuned)
goldens/                        barn framed and at the scene's texel, three scene frames
shots_scene/                    the scene frames the goldens were snapped from
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
(cd models/env && for m in plateau windpump field fence haystack tree; do rm -f $m.rmdl; hedra model --text $m.rmdl run $m.txt; done)
(cd models/barn && python3 textures/make_textures.py && rm -f barn.rmdl && hedra model --text barn.rmdl run p1_blockout.txt \
  && hedra model --text barn.rmdl run p2_form.txt)
python3 $K/scripts/splat_bake.py models/barn/barn.bake.json
python3 $K/scripts/splat_bake.py scene.bake.json
rive scene --verify && rive scene                      # the live preview: drag to orbit, wheel to zoom
```

Check:

```sh
for n in 2 20 50; do rive scene --screenshot=$PWD/shots_scene/frame_$(printf %03d $n).png --advance=$n; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/frame_002.png -p art/palette.json --pixel 4
LOOK="--arg splatDither=0 --arg bandDither=0.6 --arg shadeSteps=0.5 --arg sunYaw=60 --arg sunPitch=45"
python3 $K/scripts/golden.py views --rive lookdev --blob barn -o /tmp/barn --size 320 --pixel 2 $LOOK
python3 $K/scripts/golden.py check --shots /tmp/barn --goldens goldens/barn
python3 $K/scripts/golden.py views --rive lookdev --blob barn -o /tmp/barn@scene --texel 0.1 --size 280 --pixel 4 $LOOK
python3 $K/scripts/golden.py check --shots /tmp/barn@scene --goldens goldens/barn@scene
```

(In zsh, write `${=LOOK}` for the args to split.)
