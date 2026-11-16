#!/bin/sh
# Rebuild the archery range from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the hero's lookdev blob and the scene blob. Run from examples/games/archery-range.
# Needs hedra and /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in ground track bush tree haybale flagpole flag archer bow arrow chip; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/target && $PY make_target.py && rm -f target.rmdl \
  && hedra model --text target.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text target.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/target/target.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
