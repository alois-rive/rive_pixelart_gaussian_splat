#!/bin/sh
# Rebuild the bubble loft from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the puffer's phases (p3 is the splat fit and the scene's three parts), the lookdev
# blob and the scene blob. Run from examples/games/bubble-loft. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in loft far beam orb_dusk orb_rose orb_ember orb_sun; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/puffer && $PY make_puffer.py && rm -f puffer.rmdl \
  && hedra model --text puffer.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text puffer.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save puffer.rmdl run p3_splat_fit.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/puffer/puffer.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
