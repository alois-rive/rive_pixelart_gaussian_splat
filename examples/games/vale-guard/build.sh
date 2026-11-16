#!/bin/sh
# Rebuild Vale Guard from its sources: the environment generator (command files, the ground texture, the
# layout table in scene/game.as), every hedra model from its command files (from nothing: `rm -f x.rmdl`
# first), the keep's phases, the lookdev blob and the scene blob. Run from examples/games/vale-guard.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in ground scenery loft well spire standard mite skitter shell moth troll bolt ball shard pop; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/keep && $PY make_keep.py && rm -f keep.rmdl \
  && hedra model --text keep.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text keep.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/keep/keep.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
