#!/bin/sh
# Rebuild Pebble Prix from its sources: the racer's four paint jobs and its hedra gate model, every
# environment GLB and the track tables in scene/game.as (models/env/make_env.py, from track.py), the
# lookdev blob and the scene blob. Run from examples/games/pebble-prix.
# Needs hedra and /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/racer && $PY make_racer.py && rm -f racer.rmdl && hedra model convert racer.glb -o racer.rmdl >/dev/null)
(cd models/env && $PY make_env.py)
$PY $K/scripts/splat_bake.py models/racer/racer.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
