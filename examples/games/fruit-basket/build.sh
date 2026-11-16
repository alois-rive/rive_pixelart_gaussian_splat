#!/bin/sh
# Rebuild Fruit Basket from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the cart's lookdev blob and the scene blob. Run from examples/games/fruit-basket.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py >/dev/null)
for m in ground hedge fence tree canopy crate bush rock apple orange plum pear rotten spark; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/cart && rm -f cart.rmdl \
  && hedra model --text cart.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text cart.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/cart/cart.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
