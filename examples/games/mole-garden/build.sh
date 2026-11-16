#!/bin/sh
# Rebuild Mole Garden from its sources: the soil texture, every hedra model from its command files (from
# nothing: `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from examples/games/mole-garden.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_soil.py)
for m in garden hole cabbage turnip pumpkin fence scarecrow lantern rabbit mallet bonk; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/mole && rm -f mole.rmdl \
  && hedra model --text mole.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text mole.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text mole.rmdl run p3_splat_fit.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/mole/mole.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
