#!/bin/sh
# Rebuild Ember Deck from its sources: the generated models (models/env/make_env.py), the Wick Knight
# from its hedra command files (from nothing: `rm -f hero.rmdl` first; p3 exports the three game parts
# without saving), the lookdev blob and the scene blob. Run from examples/games/ember-deck.
# Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py)
(cd models/hero && $PY make_hero.py && rm -f hero.rmdl \
  && hedra model --text hero.rmdl run p1_blockout.txt >/dev/null \
  && hedra model --text hero.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text --no-save hero.rmdl run p3_parts.txt >/dev/null 2>&1)
$PY $K/scripts/splat_bake.py models/hero/hero.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
