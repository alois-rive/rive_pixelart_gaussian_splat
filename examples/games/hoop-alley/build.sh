#!/bin/sh
# Rebuild Hoop Alley from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the hero's lookdev blob and the scene blob. Run from examples/games/hoop-alley.
# Needs hedra and /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in court walls lights bench vend rack ball fire spark shooter; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/hoop && $PY make_hoop.py && rm -f hoop.rmdl net.rmdl \
  && hedra model --text hoop.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text hoop.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text net.rmdl run net.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/hoop/hoop.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
