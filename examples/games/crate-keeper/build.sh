#!/bin/sh
# Rebuild Crate Keeper from its sources: the room generator (the BFS pars, room0..6.txt, the room table in
# scene/game.as), every hedra model from its command files (from nothing: `rm -f x.rmdl` first), the
# keeper's splat fit, the lookdev blob and the scene blob. Run from examples/games/crate-keeper.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in room0 room1 room2 room3 room4 room5 room6 marker puff; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/crate && rm -f crate.rmdl && hedra model --text crate.rmdl run crate.txt >/dev/null 2>&1)
(cd models/keeper && rm -f keeper.rmdl keeper_fit.rmdl \
  && hedra model --text keeper.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text keeper.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save --to keeper_fit.rmdl keeper.rmdl run p3_splat_fit.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/keeper/keeper.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
