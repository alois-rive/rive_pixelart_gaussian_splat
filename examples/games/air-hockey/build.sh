#!/bin/sh
# Rebuild the air hockey arcade from its sources: every hedra model from its command files (from
# nothing: `rm -f x.rmdl` first), the textures, the lookdev blob and the scene blob. Run from
# examples/games/air-hockey. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in floor cabinet stool plant mallet_p mallet_c puck spark; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/table && $PY make_table.py && rm -f table.rmdl \
  && hedra model --text table.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text table.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/table/table.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
