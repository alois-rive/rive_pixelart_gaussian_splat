#!/bin/sh
# Rebuild sheep dog from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from examples/games/sheep-dog.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in ground fence gate tree rock pond hay trough; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/sheep && rm -f sheep.rmdl && hedra model --text sheep.rmdl run sheep.txt >/dev/null 2>&1)
(cd models/dog && rm -f dog.rmdl \
  && hedra model --text dog.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text dog.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/dog/dog.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
