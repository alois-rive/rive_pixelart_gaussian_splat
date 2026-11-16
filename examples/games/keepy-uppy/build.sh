#!/bin/sh
# Rebuild Keepy Uppy from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the hero's lookdev blob and the scene blob. Run from examples/games/keepy-uppy.
# Needs hedra and /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in beach sun clouds foam palm umbrella castle towel rocks crab shadow puff spark; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/ball && $PY make_ball.py && rm -f ball.rmdl \
  && hedra model --text ball.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text ball.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/ball/ball.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
