#!/bin/sh
# Rebuild Kite Day from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the kite's lookdev blob and the scene blob. Run from examples/games/kite-day.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in ground far sun cloud tree kid bird star bow spark; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/kite && rm -f kite.rmdl \
  && hedra model --text kite.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text kite.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/kite/kite.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
