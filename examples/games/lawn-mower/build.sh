#!/bin/sh
# Rebuild the lawn mower from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the mower's phases, the lookdev blob and the scene blob. Run from
# examples/games/lawn-mower. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in ground garden tuft gnome clip petal; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/mower && $PY make_mower.py && rm -f mower.rmdl \
  && hedra model --text mower.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text mower.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/mower/mower.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
