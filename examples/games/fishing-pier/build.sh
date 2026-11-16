#!/bin/sh
# Rebuild the fishing pier from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from examples/games/fishing-pier.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in pier rod lure fish_s fish_m fish_l jelly waves swell seabed rock kelp island sun cloud splash bubble seawall; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/fisher && rm -f fisher.rmdl \
  && hedra model --text fisher.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text fisher.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/fisher/fisher.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
