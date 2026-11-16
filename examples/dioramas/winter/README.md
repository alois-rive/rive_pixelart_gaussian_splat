# Example: a windmill on a snowy hill at night (Magik16)

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [Magik16](https://lospec.com/palette-list/magik16), 16 colours.
Three animations play in one blob: the sails turn (rigid, 12 fps), the lantern swings (rigid), the
snow falls (20 rigid bands, a seamless loop; each flake ends in the snow); the pines and their snow sway; the camera orbits slowly.

```
art/palette.json, palette.png   Magik16 with ramps snow, stone, pine, wood, lamp, magic
art/assets.md                   the asset list
art/windmill/                   Codex briefs and sheets (v1 Apollo colours, v2 the final Magik16), records, cut views (refs.v2)
models/windmill/                spec, p1_blockout.txt, p2_form.txt, planks texture, bake file, gate shots, GLB
models/env/                     hill, pine, rock, fence, lamp, snowfall: command files and GLBs;
                                make_snowfall.py (writes snowfall.txt)
lookdev/                        the turntable bench (no RML)
scene.bake.json                 the composition, with per-object animation (fps)
scene/                          the Rive project (scene.rml tuned: night sky, moon from the front left, fog)
goldens/                        windmill framed and at the scene's density, three scene frames
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
(cd models/env && python3 make_snowfall.py && for m in hill pine rock fence lamp snowfall; do rm -f $m.rmdl; hedra model --text $m.rmdl run $m.txt; done)
(cd models/windmill && rm -f windmill.rmdl && hedra model --text windmill.rmdl run p1_blockout.txt \
  && hedra model --text windmill.rmdl run p2_form.txt)
python3 $K/scripts/splat_bake.py models/windmill/windmill.bake.json
python3 $K/scripts/splat_bake.py scene.bake.json
rive scene --verify && rive scene                      # the live preview: drag to orbit, wheel to zoom
```

Check:

```sh
for n in 2 40 90; do rive scene --screenshot=$PWD/shots_scene/frame_$(printf %03d $n).png --advance=$n; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/frame_002.png -p art/palette.json --pixel 3
python3 $K/scripts/golden.py views --rive lookdev --blob windmill -o /tmp/wm --size 320 --pixel 2
python3 $K/scripts/golden.py check --shots /tmp/wm --goldens goldens/windmill
```
