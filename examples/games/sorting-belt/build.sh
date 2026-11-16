#!/bin/sh
# Rebuild the sorting belt from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the chute's parts, the lookdev blob and the scene blob. Run from
# examples/games/sorting-belt. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in room belt cleat parcel_red parcel_green parcel_cream confetti hand props; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/chute && $PY make_chute.py && rm -f chute.rmdl \
  && hedra model --text chute.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text chute.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save chute.rmdl run p3_parts.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/chute/chute.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
