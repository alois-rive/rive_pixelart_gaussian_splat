#!/bin/sh
# Rebuild Swarm Ward from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the lamplighter's bench blob and the scene blob. Run from
# examples/games/swarm-ward. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_models.py)
for m in ground decor0 decor1 decor2 decor3 moths shambler hound brute boss mote ring spark ember wisp flask; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/lamplighter && $PY make_lamplighter.py && rm -f lamplighter.rmdl \
  && hedra model --text lamplighter.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text lamplighter.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/lamplighter/lamplighter.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
