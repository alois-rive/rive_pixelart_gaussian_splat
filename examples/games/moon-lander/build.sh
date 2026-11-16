#!/bin/sh
# Rebuild the moon lander from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from examples/games/moon-lander.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in moon stars planet pad flame dust debris flag; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/lander && $PY make_p1.py && rm -f lander.rmdl \
  && hedra model --text lander.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text lander.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/lander/lander.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
