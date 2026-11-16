#!/bin/sh
# Rebuild Pocket Cup from its sources: the textures and every hedra model from its command files (from
# nothing: `rm -f x.rmdl` first), the hero (p1, p2, the p3 splat fit), the scene's body and leg, the
# lookdev blob and the scene blob. Run from examples/games/pocket-cup. Needs hedra, /usr/bin/python3
# (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in ground fence goal tree ball ring; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/player && $PY make_player.py && rm -f player.rmdl player_fit.rmdl \
  && hedra model --text player.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text player.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --no-save --to player_fit.rmdl player.rmdl run p3_splat_fit.txt >/dev/null 2>&1)
for m in body leg; do
  (cd models/player && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
$PY $K/scripts/splat_bake.py models/player/player.bake.json
$PY make_bake.py
$PY $K/scripts/splat_bake.py scene.bake.json
