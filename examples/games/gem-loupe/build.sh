#!/bin/sh
# Rebuild Gem Loupe from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from examples/games/gem-loupe.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in bench tray drum band claws candle flame mandrel tweezers card; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/loupe && rm -f loupe.rmdl \
  && hedra model --text loupe.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text loupe.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/loupe/loupe.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
