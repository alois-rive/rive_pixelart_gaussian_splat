#!/bin/sh
# Rebuild the night heist from its sources: the roof textures and every hedra model from its command
# files (from nothing: `rm -f x.rmdl` first), the cat's phases (p1, p2 the gated form, p3 the splat
# fit saved to cat_fit.rmdl, p4 the game's parts), the lookdev blob and the scene blob.
# Run from examples/games/night-heist. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py >/dev/null)
for m in roofs backrow props sky lamp pool fish spark cloud; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/cat && $PY make_cat.py && rm -f cat.rmdl cat_fit.rmdl \
  && hedra model --text cat.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text cat.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save --to cat_fit.rmdl cat.rmdl run p3_splat_fit.txt >/dev/null 2>&1 \
  && hedra model --text --no-save cat_fit.rmdl run p4_parts.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/cat/cat.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
