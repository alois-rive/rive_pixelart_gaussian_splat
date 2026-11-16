#!/bin/sh
# Rebuild Kick Park from its sources: the park's GLBs (written by Python, so the bowl and the quarter
# pipes match the physics in scene/game.as), the skater from its hedra command files (from nothing:
# `rm -f x.rmdl` first; p3 and p4 run --no-save so the gated skater.rmdl stays as p2 left it), the
# lookdev blob and the scene blob. Run from examples/games/kick-park. Needs hedra, /usr/bin/python3
# (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
(cd models/skater && $PY make_skater.py && rm -f skater.rmdl skater_fit.rmdl \
  && hedra model --text skater.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text skater.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save --to skater_fit.rmdl skater.rmdl run p3_splat_fit.txt >/dev/null 2>&1 \
  && hedra model --text --no-save skater_fit.rmdl run p4_parts.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/skater/skater.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
