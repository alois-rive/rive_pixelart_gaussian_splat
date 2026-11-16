#!/bin/sh
# Rebuild the harbour from its sources: textures, every hedra model from its command files
# (from nothing: `rm -f x.rmdl` first), the lookdev blobs and the scene blob.
# Run from examples/dioramas/harbour. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

$PY art/textures/make_textures.py
for m in sea quay pier islet rock lighthouse crate barrel; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/gull && rm -f gull.rmdl && hedra model --text gull.rmdl run gull.txt >/dev/null 2>&1)
(cd models/boat && rm -f boat.rmdl \
  && hedra model --text boat.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text boat.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model boat.rmdl export boat_form.glb >/dev/null \
  && hedra model --text boat.rmdl run p3_motion.txt >/dev/null \
  && hedra model boat.rmdl export boat.glb --bake-animations >/dev/null)
$PY $K/scripts/splat_bake.py models/boat/boat_form.bake.json
$PY $K/scripts/splat_bake.py models/boat/boat.bake.json
$PY $K/scripts/splat_bake.py models/gull/gull.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
