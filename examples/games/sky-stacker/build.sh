#!/bin/sh
# Rebuild Sky Stacker from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from examples/games/sky-stacker.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

for m in peak plinth pine cloud spire; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/storey && rm -f storey.rmdl \
  && hedra model --text storey.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text storey.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text storey.rmdl run p3_splat_fit.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/storey/storey.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
