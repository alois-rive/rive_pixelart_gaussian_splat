#!/bin/sh
# Rebuild Golem Hall from its sources: the hall's models and textures (make_env.py), the golem from its
# command files (from nothing: `rm -f x.rmdl` first) and its five game parts, the lookdev blob and the
# scene blob. Run from examples/games/golem-hall. Needs hedra and /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in hall pillar broken brazier flame banner rubble bolt crack chunk spark staff; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/golem && $PY make_golem.py && rm -f golem.rmdl \
  && hedra model --text golem.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text golem.rmdl run p2_form.txt >/dev/null 2>&1)
# the game parts: body, arms (pivots at the shoulders), legs (at the hips), each from a fresh replay
for part in body arml armr legl legr; do
  (cd models/golem && rm -f split.rmdl \
    && hedra model --text split.rmdl run p1_blockout.txt >/dev/null 2>&1 \
    && hedra model --text split.rmdl run p2_form.txt >/dev/null 2>&1 \
    && hedra model --text split.rmdl run p3_$part.txt >/dev/null 2>&1 \
    && rm -f split.rmdl split.rmdl.activity split.rmdl.undo)
done
$PY $K/scripts/splat_bake.py models/golem/golem.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
