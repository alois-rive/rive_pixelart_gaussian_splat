#!/bin/sh
# Rebuild the frog choir from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the frog's parts, the lookdev blob and the scene blob. Run from
# examples/games/frog-choir. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in pond bank reeds pad lotus stone log sun cloud mist ripple; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/frog && $PY make_frog.py && rm -f frog.rmdl \
  && hedra model --text frog.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text frog.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save frog.rmdl run p3_parts.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/frog/frog.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
