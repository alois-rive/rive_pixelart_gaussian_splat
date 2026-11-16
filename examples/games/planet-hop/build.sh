#!/bin/sh
# Rebuild planet hop from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the rocket's lookdev blob and the scene blob. Run from examples/games/planet-hop.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in meadow dune ice mushroom lava giant star flame puff spark chunk stars nebula; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/rocket && $PY make_rocket.py && rm -f rocket.rmdl \
  && hedra model --text rocket.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text rocket.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/rocket/rocket.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
