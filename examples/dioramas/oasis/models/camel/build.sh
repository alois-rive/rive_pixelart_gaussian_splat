#!/bin/sh
# Rebuild the camel from its command files: camel.glb (walk in place) and camel_orbit.glb (the scene's).
set -e
cd "$(dirname "$0")"
rm -f camel.rmdl
hedra model --text -q camel.rmdl run p1_blockout.txt
hedra model --text -q camel.rmdl run p2_form.txt
hedra model --text -q camel.rmdl run p3_rig.txt
hedra model --text -q camel.rmdl export camel.glb --bake-animations
hedra model --text -q camel.rmdl run p4_orbit.txt
hedra model --text -q camel.rmdl export camel_orbit.glb --bake-animations
