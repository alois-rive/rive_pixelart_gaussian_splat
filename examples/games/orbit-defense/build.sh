#!/bin/sh
# Rebuild Orbit Defense from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from examples/games/orbit-defense.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in planet sky hut dome rubble meteor boulder trail bolt burst debris puff flash; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/satellite && rm -f satellite.rmdl \
  && hedra model --text satellite.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text satellite.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/satellite/satellite.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
