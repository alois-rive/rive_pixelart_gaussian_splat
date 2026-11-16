# Example: a haunted hilltop graveyard (Hollow, four colours)

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Hollow](https://lospec.com/palette-list/hollow) by Poltergasm, 4 colours
(#0f0f1b #565a75 #c6b7be #fafbf6): one ramp, materials told apart by the step they are painted on.
Moody and painterly: big splats (0.15 m, 2.2 texels), jitter 0.35, heavy dithered fog (70 % from 2.5 m to
9 m behind the orbit target), a low moon from the front right, ink 1. What moves: a ghost drifts round the
graves (rigid: an orbit of 2 m every 10 s, bobbing and rocking every 2.5 s, 10 fps, stepped). The lantern,
the chapel's windows, the ghost and the moon glow (unlit splats). The camera holds still (the moon disc is a
prop behind the hill); drag to orbit, wheel to zoom.

```
art/palette.json, palette.png   Hollow with ramps stone, earth, dark, glow; sky #565a75 over #0f0f1b, fog #565a75
art/assets.md                   the asset list
art/crypt/                      the Codex brief, the sheet (v1), its record and log, cut views (refs/)
models/crypt/                   spec (with the gate record), p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB
models/ghost/                   spec, p1_blockout.txt, p2_motion.txt (orbit, bob, rock), GLB
models/env/                     hill (ground texture), headstone, cross, tree, fence, lantern, moon: command files, GLBs
lookdev/                        the turntable bench (no RML)
scene.bake.json                 the composition (23 800 splats, 1 bone)
scene/                          the Rive project (scene.rml tuned)
goldens/                        crypt framed and at the scene's density, three scene frames
shots_scene/                    the scene frames the goldens were snapped from
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
(cd models/env && for m in hill headstone cross tree fence lantern moon; do rm -f $m.rmdl; hedra model --text $m.rmdl run $m.txt; done)
(cd models/crypt && rm -f crypt.rmdl && hedra model --text crypt.rmdl run p1_blockout.txt \
  && hedra model --text crypt.rmdl run p2_form.txt)
(cd models/ghost && rm -f ghost.rmdl && hedra model --text ghost.rmdl run p1_blockout.txt \
  && hedra model --text ghost.rmdl run p2_motion.txt)
python3 $K/scripts/splat_bake.py models/crypt/crypt.bake.json
python3 $K/scripts/splat_bake.py scene.bake.json
rive scene --verify && rive scene                      # the live preview: drag to orbit, wheel to zoom
```

Check:

```sh
for n in 2 120 300; do rive scene --screenshot=$PWD/shots_scene/frame_$(printf %03d $n).png --advance=$n; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/frame_002.png -p art/palette.json --pixel 3
python3 $K/scripts/golden.py views --rive lookdev --blob crypt -o /tmp/cr --size 320 --pixel 2
python3 $K/scripts/golden.py check --shots /tmp/cr --goldens goldens/crypt
python3 $K/scripts/golden.py views --rive lookdev --blob crypt -o /tmp/cr_s --texel 0.0675 --size 160 --pixel 2
python3 $K/scripts/golden.py check --shots /tmp/cr_s --goldens goldens/crypt@scene
```

Tune at launch with `--arg`, e.g. `rive scene --arg fogMax=0.5 --arg sunYaw=110 --arg spin=3`.
