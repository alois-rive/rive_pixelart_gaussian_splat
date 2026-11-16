#!/bin/sh
# Rebuild the tightrope canyon from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the walker's two game parts, the lookdev blob and the scene blob.
# Run from examples/games/tightrope. Needs hedra and /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in cliffs river mesas stand rope flag streak splash bird cactus rock sun; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/walker && rm -f walker.rmdl \
  && hedra model --text walker.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text walker.rmdl run p2_form.txt >/dev/null 2>&1)
# the game parts: the walker and his pole (its origin at the hands), each from a fresh replay
for part in body pole; do
  (cd models/walker && rm -f split.rmdl \
    && hedra model --text split.rmdl run p1_blockout.txt >/dev/null 2>&1 \
    && hedra model --text split.rmdl run p2_form.txt >/dev/null 2>&1 \
    && hedra model --text split.rmdl run p3_$part.txt >/dev/null 2>&1 \
    && rm -f split.rmdl split.rmdl.activity split.rmdl.undo)
done
$PY $K/scripts/splat_bake.py models/walker/walker.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
