#!/bin/sh
# Rebuild Lily Hop from its sources: the water texture, every hedra model from its command files (from
# nothing: `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from examples/games/lily-hop.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_water.py)
for m in pond pad lotus reeds rock bush fly splash ripple; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/frog && rm -f frog.rmdl \
  && hedra model --text frog.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text frog.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text frog.rmdl run p3_splat_fit.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/frog/frog.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
