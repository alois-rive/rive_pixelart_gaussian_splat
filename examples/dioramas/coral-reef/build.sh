#!/bin/sh
# Rebuild the coral reef from its sources: the sand texture, every hedra model from its command files
# (from nothing: `rm -f x.rmdl` first), the lookdev blobs and the scene blob. Run from examples/dioramas/coral-reef.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

$PY art/textures/make_textures.py
(cd models/env && $PY make_env.py)
for m in seabed bubbles fish kelp coral_branch coral_brain coral_fan rock; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/clam && $PY make_p1.py && rm -f clam.rmdl \
  && hedra model --text clam.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text clam.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text clam.rmdl run p3_motion.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/clam/clam_rest.bake.json
$PY $K/scripts/splat_bake.py models/clam/clam.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
