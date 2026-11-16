# Example: a toy carnival on a round plaza (PICO-8)

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [PICO-8](https://lospec.com/palette-list/pico-8), 16 colours, as nine
short ramps (red, pink, cream, gold, green, blue, wood, stone, glow).
A bright toy diorama under a perspective camera (fov 40) that orbits slowly. What moves: the carousel's
rotor turns (rigid, one turn in 8 s) while its six horses bob on their poles (rigid children of the rotor,
eased, one bob in 2 s); two balloon bunches sway in a slow cone (rigid, 3 s, out of phase); all at 12 fps,
stepped. The lamp bulbs glow (unlit splats).

```
art/palette.json, palette.png   PICO-8 with its ramps and roles (sky #29adff over #ffccaa, fog #c2c3c7, void #000000)
art/assets.md                   the asset list
art/carousel/                   the Codex brief, the sheet (v1), its record and log, cut views (refs/)
models/carousel/                spec (with the gate record), p1_blockout.txt, p2_form.txt (materials, joins, turn, bob), bake file, gate shots, GLB
models/env/                     plaza, tent, stall, balloons, lamp, tree: command files, textures (tiles, awning), GLBs
lookdev/                        the turntable bench (no RML)
scene.bake.json                 the composition (85 400 splats, 9 bones)
scene/                          the Rive project (scene.rml tuned: perspective fov 40, ink 2, per-splat dither, slow spin)
goldens/                        carousel framed and at the scene's density, three scene frames
shots_scene/                    the scene frames the goldens were snapped from
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
(cd models/env && for m in plaza tent stall balloons lamp tree; do rm -f $m.rmdl; hedra model --text $m.rmdl run $m.txt; done)
(cd models/carousel && rm -f carousel.rmdl && hedra model --text carousel.rmdl run p1_blockout.txt \
  && hedra model --text carousel.rmdl run p2_form.txt)
python3 $K/scripts/splat_bake.py models/carousel/carousel.bake.json
python3 $K/scripts/splat_bake.py scene.bake.json
rive scene --verify && rive scene                      # the live preview: drag to orbit, wheel to zoom
```

Check:

```sh
for n in 2 90 240; do rive scene --screenshot=$PWD/shots_scene/frame_$(printf %03d $n).png --advance=$n; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/frame_002.png -p art/palette.json --pixel 3
python3 $K/scripts/golden.py views --rive lookdev --blob carousel -o /tmp/cc --size 320 --pixel 2
python3 $K/scripts/golden.py check --shots /tmp/cc --goldens goldens/carousel
python3 $K/scripts/golden.py views --rive lookdev --blob carousel -o /tmp/cc_s --texel 0.066 --size 160 --pixel 2
python3 $K/scripts/golden.py check --shots /tmp/cc_s --goldens goldens/carousel@scene
```

Tune at launch with `--arg`, e.g. `rive scene --arg spin=0 --arg ink=1 --arg fov=30`.
