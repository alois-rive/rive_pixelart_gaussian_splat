#!/bin/sh
# Rebuild the dragon tower from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the dragon's two game parts, the lookdev blob and the scene blob.
# Run from examples/games/dragon-tower. Needs hedra and /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in tower ladder ground hills tree cloud knight fireball poof; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/dragon && $PY make_dragon.py && rm -f dragon.rmdl \
  && hedra model --text dragon.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text dragon.rmdl run p2_form.txt >/dev/null 2>&1)
# the game parts: the body and the head (its origin at the neck), each from a fresh replay
for part in body head; do
  (cd models/dragon && rm -f split.rmdl \
    && hedra model --text split.rmdl run p1_blockout.txt >/dev/null 2>&1 \
    && hedra model --text split.rmdl run p2_form.txt >/dev/null 2>&1 \
    && hedra model --text split.rmdl run p3_$part.txt >/dev/null 2>&1 \
    && rm -f split.rmdl split.rmdl.activity split.rmdl.undo)
done
$PY $K/scripts/splat_bake.py models/dragon/dragon.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
