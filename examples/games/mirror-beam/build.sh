#!/bin/sh
# Rebuild the mirror-beam court from its sources: every hedra model from its command files (from
# nothing: `rm -f x.rmdl` first), the sun mirror's three phases, the lookdev blob and the scene blob.
# Run from examples/games/mirror-beam. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in court temple desert palm sun crystal stump lens spark ring emblem; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/mirror && $PY make_mirror.py && rm -f mirror.rmdl \
  && hedra model --text mirror.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text mirror.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text mirror.rmdl run p3_splat_fit.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/mirror/mirror.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
