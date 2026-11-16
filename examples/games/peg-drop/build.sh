#!/bin/sh
# Rebuild the peg drop from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the dropper's phases (p3 is the splat fit the bakes use), the lookdev blob and
# the scene blob. Run from examples/games/peg-drop. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in board wall gear_big gear_small pendulum coin hand marker spark; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/dropper && $PY make_dropper.py && rm -f dropper.rmdl \
  && hedra model --text dropper.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text dropper.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save dropper.rmdl run p3_splat_fit.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/dropper/dropper.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
