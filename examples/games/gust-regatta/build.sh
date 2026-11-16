#!/bin/sh
# Rebuild Gust Regatta from its sources: the generated bay, islets, props and game pieces (make_bay.py
# writes their GLBs directly), the sailboat from its hedra command files (from nothing: `rm -f x.rmdl`
# first; p3 is the splat fit, written to its own file), the hero's lookdev blob and the scene blob.
# Run from examples/games/gust-regatta. Needs hedra and /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_bay.py)
(cd models/sailboat && rm -f sailboat.rmdl sailboat_fit.rmdl \
  && hedra model --text sailboat.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text sailboat.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save --to sailboat_fit.rmdl sailboat.rmdl run p3_splat_fit.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/sailboat/sailboat.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
