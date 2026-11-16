#!/bin/sh
# Rebuild lantern river from its sources: every hedra model from its command files (from nothing:
# `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from examples/games/lantern-river.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in water bank hills tree house jetty reeds moon glint stars shine; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
# the lantern: blockout, form (lantern.glb, gated), bake prep (lantern_bake.glb), lit (lantern_lit.glb)
(cd models/lantern && rm -f lantern.rmdl \
  && hedra model --text lantern.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text lantern.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text lantern.rmdl run p3_bake.txt >/dev/null 2>&1 \
  && hedra model --text lantern.rmdl run p4_lit.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/lantern/lantern.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
