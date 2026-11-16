#!/bin/sh
# Rebuild Sprout Jump from its sources: the level's textures and command file, every hedra model from
# its command files (from nothing: `rm -f x.rmdl` first), the part GLBs, the lookdev blob and the
# scene blob. Run from examples/games/sprout-jump. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/level && $PY make_textures.py && $PY make_level.py \
  && rm -f level.rmdl && hedra model --text level.rmdl run level.txt >/dev/null 2>&1)
(cd models/env && $PY make_env.py)
for m in seed pop shellbug moth spring raft plank bloom pennant puff water hills grove cloud; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/pip && rm -f pip.rmdl \
  && hedra model --text pip.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text pip.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save pip.rmdl run p3_parts.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/pip/pip.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
