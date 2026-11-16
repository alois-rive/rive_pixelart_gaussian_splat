#!/bin/sh
# Rebuild the snowball run from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from examples/games/snowball-run.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in ground mountains pine ball mound rock spray chunk snowfall; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/snowman && rm -f snowman.rmdl \
  && hedra model --text snowman.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text snowman.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/snowman/snowman.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
