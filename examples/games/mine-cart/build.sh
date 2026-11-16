#!/bin/sh
# Rebuild the mine cart from its sources: the environment generator (hedra command files, the floor
# texture, the track table in scene/game.as), every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from examples/games/mine-cart.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in floor rails stands lever gem rocks stones puff timber crystals walls; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/cart && rm -f cart.rmdl \
  && hedra model --text cart.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text cart.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/cart/cart.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
