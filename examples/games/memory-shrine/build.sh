#!/bin/sh
# Rebuild the memory shrine from its sources: every hedra model from its command files (from
# nothing: `rm -f x.rmdl` first), the lookdev blob and the scene blob. Run from
# examples/games/memory-shrine. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for m in terrace torii lantern pine peaks moon clouds stars ripple note; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/bell && rm -f bell.rmdl \
  && hedra model --text bell.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text bell.rmdl run p2_form.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/bell/bell.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
