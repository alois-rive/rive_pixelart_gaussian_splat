#!/bin/sh
# Rebuild crane claw from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the claw (p1 blockout, p2 form, p3 splat fit; p4 writes the game's parts
# without saving), the claw's lookdev blob and the scene blob. Run from examples/games/crane-claw.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in cabinet bulbs_a bulbs_b pit bridge trolley duck bear bunny ball gem confetti_y confetti_m; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/claw && $PY make_claw.py && rm -f claw.rmdl \
  && hedra model --text claw.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text claw.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text claw.rmdl run p3_splat_fit.txt >/dev/null 2>&1 \
  && hedra model --text --no-save claw.rmdl run p4_parts.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/claw/claw.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
