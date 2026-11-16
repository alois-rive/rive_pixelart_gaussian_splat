#!/bin/sh
# Rebuild the firefly meadow from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the lookdev blob and the scene blob.
# Run from examples/games/firefly-jar. Needs hedra and /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in meadow pond tree bush tuft flower stump net firefly moth spark; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/jar && $PY make_jar.py && rm -f jar.rmdl \
  && hedra model --text jar.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text jar.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/jar/jar.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
