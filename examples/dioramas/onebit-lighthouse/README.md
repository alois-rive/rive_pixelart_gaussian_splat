# Example: a 1-bit lighthouse at night (1bit Monitor Glow, 2 colours)

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [1bit Monitor Glow](https://lospec.com/palette-list/1bit-monitor-glow),
2 colours. A striped lighthouse and a keeper's hut on a rocky headland over a night sea, in an
Obra-Dinn-like 1-bit look: every tone is a Bayer dither density between the two colours
(`splatDither` false, `bandDither` 1), a perspective camera low over the water (fov 35, pitch 6),
320 x 200 art pixels (`pixelSize` 2), the moon from the front left, distant sea dissolving into a
dithered horizon glow (fog towards `#f0f6f0`), `ink` 2 so white walls get a dark rim against the glow.

How two colours make several tones: ramps repeat colours (`pale` = d l l, `tar` = d d l) and
`shadeSteps` 1.5 / `lightSteps` 2 / `keyLight` = `highlight` 0.6 turn N.L into a white share
(table in `art/assets.md`): white walls never drop below a 50 % dither, the turf goes from white to
black, the rock and the sea are dark with glints, the bands and roofs stay dark.

What moves: the lamp head turns and its two beams sweep the sky (rigid, one turn in 8 s, clockwise
from above, against the demo / orbit camera's turn so the sweep reads while the camera orbits, 12 fps
stepped; the beams are unlit splats, stippled out towards their tips by an alpha-masked texture); the
rowboat bobs (rigid, 3 s); the near sea sways a few centimetres, so its glints shimmer.

```
art/palette.json, palette.png   1bit Monitor Glow with ramps lit, pale, tar, glow
art/assets.md                   the asset list and the tone table
art/lighthouse/                 Codex brief, sheet.v1.png and its record, cut views (refs/)
models/lighthouse/              spec + gate record, p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB
models/env/                     cliff, sea, hut, rock, boat, beam (+ beam_texture.py): command files and GLBs
lookdev/                        the turntable bench (no RML)
scene.bake.json                 the composition
scene/                          the Rive project (scene.rml tuned)
goldens/                        lighthouse framed and at the scene's texel, three scene frames
shots_scene/                    the scene frames the goldens were snapped from
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
(cd models/env && python3 beam_texture.py && for m in cliff sea hut rock boat beam; do rm -f $m.rmdl; hedra model --text $m.rmdl run $m.txt; done)
(cd models/lighthouse && rm -f lighthouse.rmdl && hedra model --text lighthouse.rmdl run p1_blockout.txt \
  && hedra model --text lighthouse.rmdl run p2_form.txt)
python3 $K/scripts/splat_bake.py models/lighthouse/lighthouse.bake.json
python3 $K/scripts/splat_bake.py scene.bake.json
rive scene --verify && rive scene                      # the live preview: drag to orbit, wheel to zoom
```

Check:

```sh
for n in 2 60 120; do rive scene --screenshot=$PWD/shots_scene/frame_$(printf %03d $n).png --advance=$n; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/frame_002.png -p art/palette.json --pixel 2
LOOK="--arg splatDither=0 --arg bandDither=1 --arg shadeSteps=1.5 --arg lightSteps=2 --arg keyLight=0.6 --arg highlight=0.6 --arg sunYaw=-40 --arg sunPitch=35 --arg ink=2"
python3 $K/scripts/golden.py views --rive lookdev --blob lighthouse -o /tmp/lh --size 320 --pixel 2 $LOOK
python3 $K/scripts/golden.py check --shots /tmp/lh --goldens goldens/lighthouse
python3 $K/scripts/golden.py views --rive lookdev --blob lighthouse -o /tmp/lh@scene --texel 0.063 --size 240 --pixel 2 $LOOK
python3 $K/scripts/golden.py check --shots /tmp/lh@scene --goldens goldens/lighthouse@scene
```

(In zsh, write `${=LOOK}` for the args to split.)
