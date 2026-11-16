#!/bin/sh
# Rebuild Deep Delve from its sources: every hedra model from its command files (from nothing: `rm -f
# x.rmdl` first), the delver (p1 + p2, the gated form; p3, the splat fit, into hero_fit.rmdl for the
# bake), the lookdev blob and the scene blob. Run from examples/games/deep-delve.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
for f in models/env/*.txt; do
  m=$(basename $f .txt)
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/hero && rm -f hero.rmdl hero_fit.rmdl \
  && hedra model --text hero.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text hero.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save --to hero_fit.rmdl hero.rmdl run p3_splat_fit.txt >/dev/null 2>&1 \
  && hedra model hero_fit.rmdl export hero.glb >/dev/null)
$PY $K/scripts/splat_bake.py models/hero/hero.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
