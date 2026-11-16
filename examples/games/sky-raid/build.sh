#!/bin/sh
# Rebuild Sky Raid from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the hero's splat fit and scene pieces, the lookdev blob and the scene blob.
# Run from examples/games/sky-raid. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py >/dev/null)
for m in fieldsA fieldsB villageA villageB woodsA woodsB riverA riverB balloon supply boat turret drone airship bossgun shot bullet pop crate; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/plane && rm -f plane.rmdl plane_fit.rmdl \
  && hedra model --text plane.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text plane.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save --to plane_fit.rmdl plane.rmdl run p3_splat_fit.txt >/dev/null 2>&1 \
  && hedra model --text --no-save plane_fit.rmdl run p4_body.txt >/dev/null 2>&1 \
  && hedra model --text --no-save plane_fit.rmdl run p4_prop.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/plane/plane.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
