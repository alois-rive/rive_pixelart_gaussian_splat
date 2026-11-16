#!/bin/sh
# Rebuild the bee garden from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the bee's parts, the lookdev blob and the scene blob. Run from
# examples/games/bee-garden. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in island hive bush fence rock flower_pink flower_white wilt spider sparkle; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/bee && $PY make_bee.py && rm -f bee.rmdl \
  && hedra model --text bee.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text bee.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save bee.rmdl run p3_parts.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/bee/bee.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
