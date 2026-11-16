#!/bin/sh
# Rebuild Cloud Putt from its sources: the props (models/env/make_env.py), the windmill hero
# (p1-p2, then p4_parts.txt for the scene's tower and sails), the course (models/course/make_course.py
# writes the greens, borders, cups, water and island command files, scene.bake.json and the course
# block of scene/game.as), every hedra model from its command file (from nothing: `rm -f x.rmdl`
# first), the lookdev blob and the scene blob.
# Run from examples/games/cloud-putt. Needs hedra, /usr/bin/python3 (NumPy, Pillow).
set -e
K=../../../.claude/skills/pixel-splat-scene
PY=/usr/bin/python3

(cd models/env && $PY make_env.py >/dev/null)
for m in ball flag gate post puff tree drop spark ripple; do
  (cd models/env && rm -f $m.rmdl && hedra model --text $m.rmdl run $m.txt >/dev/null 2>&1)
done
(cd models/windmill && rm -f windmill.rmdl \
  && hedra model --text windmill.rmdl run p1_blockout.txt >/dev/null 2>&1 \
  && hedra model --text windmill.rmdl run p2_form.txt >/dev/null 2>&1 \
  && hedra model --text windmill.rmdl export windmill.glb >/dev/null \
  && hedra model --text --no-save windmill.rmdl run p4_parts.txt >/dev/null 2>&1)
(cd models/course && $PY make_course.py >/dev/null)
for m in greens1 greens2 greens3 borders cups water island; do
  (cd models/course && rm -f "${m:?}.rmdl" "${m:?}.rmdl.undo" && hedra model --text --undo-steps 0 $m.rmdl run $m.txt >/dev/null 2>&1)
done
$PY $K/scripts/splat_bake.py models/windmill/windmill.bake.json
$PY $K/scripts/splat_bake.py scene.bake.json
