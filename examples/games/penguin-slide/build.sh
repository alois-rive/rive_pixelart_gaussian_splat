#!/bin/sh
# Rebuild the penguin slide from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from examples/games/penguin-slide.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in floe3 floe5 floe8 seal fish puff splash chunk berg ridge waves water; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/penguin && rm -f penguin.rmdl \
  && hedra model --text penguin.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text penguin.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/penguin/penguin.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
