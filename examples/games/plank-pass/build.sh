#!/bin/sh
# Rebuild Plank Pass from its sources: every hedra model from its command files (from nothing: `rm -f x.rmdl`
# first), the cart's game parts (body, wheels), the lookdev blob and the scene blob.
# Run from examples/games/plank-pass. Needs hedra and /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in terrain pine boulder plank girder puff splash dust depot; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/cart && $PY make_cart.py && rm -f cart.rmdl \
  && hedra model --text cart.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text cart.rmdl run p2_form.txt >/dev/null 2>&1)
# the game parts: the body and one axle's wheels, each from a fresh replay
for part in body wheel; do
  (cd models/cart && rm -f split.rmdl \
    && hedra model --text split.rmdl run p1_blockout.txt >/dev/null 2>&1 \
    && hedra model --text split.rmdl run p2_form.txt >/dev/null 2>&1 \
    && hedra model --text split.rmdl run p3_$part.txt >/dev/null 2>&1 \
    && rm -f split.rmdl split.rmdl.activity split.rmdl.undo)
done
$PY $K/scripts/splat_bake.py models/cart/cart.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
