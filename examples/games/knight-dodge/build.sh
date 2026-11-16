#!/bin/sh
# Rebuild the knight's arena from its sources: every hedra model from its command files (from
# nothing: `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from
# examples/games/knight-dodge. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in arena brazier flame banner boulder coin dust; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/knight && $PY make_knight.py && rm -f knight.rmdl \
  && hedra model --text knight.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text knight.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/knight/knight.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
