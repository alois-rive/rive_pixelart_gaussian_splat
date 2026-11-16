#!/bin/sh
# Rebuild the marble labyrinth from its sources: every hedra model from its command files (from
# nothing: `rm -f x.rmdl` first), the labyrinth's parts, the lookdev blob and the scene blob.
# Run from examples/games/marble-tilt. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in table dish plant books cup marble wall hole goal start spark; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/labyrinth && rm -f labyrinth.rmdl \
  && hedra model --text labyrinth.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text labyrinth.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text labyrinth.rmdl run p3_splat_fit.txt >/dev/null 2>&1 \
  && hedra model --text labyrinth.rmdl export labyrinth.glb >/dev/null \
  && hedra model --text --no-save labyrinth.rmdl run p4_parts.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/labyrinth/labyrinth.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
