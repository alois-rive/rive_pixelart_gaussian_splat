#!/bin/sh
# Rebuild the pancake kitchen from its sources: every hedra model from its command files (from
# nothing: `rm -f x.rmdl` first), the pan's splat parts, the lookdev blob and the scene blob. Run from
# examples/games/pancake-flip. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in kitchen burner plate bottle butter bowl pancake_raw pancake_golden pancake_dark pancake_burnt smoke star; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/pan && rm -f pan.rmdl \
  && hedra model --text pan.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text pan.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save pan.rmdl run p3_parts.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/pan/pan.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
