#!/bin/sh
# Rebuild Bath Navy from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the hero's lookdev blob and the scene blob. Run from examples/games/bath-navy.
# Needs hedra and /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in room tub faucet props foam towel sailboat tugboat speedboat bubble drop; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/duck && $PY make_duck.py && rm -f duck.rmdl \
  && hedra model --text duck.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text duck.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/duck/duck.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
