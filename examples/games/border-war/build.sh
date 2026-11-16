#!/bin/sh
# Rebuild Border War from its sources: the generated models (units, buildings, props, terrain, woods), the
# Manor from its hedra command files (from nothing: `rm -f manor.rmdl` first), the bake file, the lookdev
# blob and the scene blob. Run from examples/games/border-war. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
(cd models && $PY make_models.py)
(cd models/manor && rm -f manor.rmdl \
  && hedra model --text manor.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text manor.rmdl run p2_form.txt >/dev/null 2>&1)
(cd models && $PY make_bake.py)
$PY $K/scripts/splat_bake.py models/manor/manor.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
