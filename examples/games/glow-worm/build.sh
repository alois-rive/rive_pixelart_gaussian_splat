#!/bin/sh
# Rebuild the glow-worm cave from its sources: every hedra model from its command files (from
# nothing: `rm -f x.rmdl` first), the worm's phases (p1 blockout, p2 form = the gated mesh, p3 splat
# fit = what bakes, p4 the game's parts), the lookdev blob and the scene blob. Run from
# examples/games/glow-worm. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in cave stalagmite crystal spark; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/worm && $PY make_worm.py && rm -f worm.rmdl \
  && hedra model --text worm.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text worm.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text worm.rmdl run p3_splat_fit.txt >/dev/null 2>&1 \
  && hedra model --text --no-save worm.rmdl run p4_parts.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/worm/worm.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
