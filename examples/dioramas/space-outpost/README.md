# Example: a research outpost on an asteroid (Ammo-8)

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [Ammo-8](https://lospec.com/palette-list/ammo-8), 8 greens.
A monochrome night-vision terminal look: high orthographic view (pitch 50), thick ink (2 steps),
hard Bayer bands (`bandDither` 0.15, `splatDither` off), flat dark space with a field of unlit stars,
glowing (unlit) windows, screens, pad lights and beacons.

What moves (rigid tracks, stepped): the radar dish turns a full circle every 8 s while nodding
(-36 -> -50 -> -36 -> -22 deg), 12 fps; the habitat's beacon arm spins once every 2 s; the two
antenna beacons pop on for a quarter of every second, half a second apart; the camera orbits at
3 deg/s.

Traffic (`scene/game.as`, game bones): a ship comes to the pad every 7 s, a shuttle and a hauler in
turn. Each one drops in from 20 m up on a curved, banking path (3 s), descends from a hover onto the
pad (1.4 s), waits with its jets off (2.6 s), lifts off turning to a new heading (1.2 s) and climbs out
of the top of the frame (2.6 s): a lift-off overlaps the next ship's approach. Two unlit jets per
ship sit on its nozzles, scaled by thrust and a stepped 12 fps flicker. Every pose is a pure
function of the scene time (stepped at 24 fps), so captures repeat exactly; each ship comes in and
leaves on its own headings (the golden angle per ship). At t = 0 the shuttle stands on the pad.

```
art/palette.json, palette.png   Ammo-8 with ramps rock, pad, hull, dish, glow
art/assets.md                   the asset list (sizes, ramps, animation, bones)
art/radar/                      the Codex brief, sheet v1, its record, cut views (refs/)
models/radar/                   spec with the gate record, p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB
models/env/                     asteroid, pad, habitat, antenna, crate, rover, boulder, stars, shuttle, hauler, jet:
                                command files and GLBs;
                                make_textures.py (regolith, pad markings), make_stars.py (writes stars.txt)
lookdev/                        the turntable bench (no RML)
scene.bake.json                 the composition, with per-object animation (fps, phase)
scene/                          the Rive project (scene.rml tuned: pitch 50, ink 2, Bayer bands, flat sky, orbit on);
                                game.as: the ships' schedule and flight paths
goldens/                        radar framed, at the scene's density, 3 s into its loop; three scene frames
shots_scene/                    the scene frames at --advance 2 (the shuttle parked), 240 (the hauler coming in
                                while the shuttle climbs away), 330 (the hauler descending on its jets)
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
(cd models/env && python3 make_textures.py && python3 make_stars.py \
  && for m in asteroid pad habitat antenna crate rover boulder stars shuttle hauler jet; do rm -f $m.rmdl; hedra model --text $m.rmdl run $m.txt; done)
(cd models/radar && rm -f radar.rmdl && hedra model --text radar.rmdl run p1_blockout.txt \
  && hedra model --text radar.rmdl run p2_form.txt)
python3 $K/scripts/splat_bake.py models/radar/radar.bake.json
python3 $K/scripts/splat_bake.py scene.bake.json
rive scene --verify && rive scene                      # the live preview: drag to orbit, wheel to zoom
```

Check:

```sh
python3 $K/scripts/golden.py views --hedra models/radar/radar.rmdl -o /tmp/rp2 --views front,right,back,top --elevation 8
python3 $K/scripts/golden.py gate --refs art/radar/refs --shots /tmp/rp2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob radar -o /tmp/ra --look albedo --elevation 8 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/radar/refs --shots /tmp/ra -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
for n in 2 240 330; do rive scene --screenshot=$PWD/shots_scene/frame_$(printf %03d $n).png --advance=$n; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/frame_002.png -p art/palette.json --pixel 3
python3 $K/scripts/golden.py views --rive lookdev --blob radar -o /tmp/rd --size 320 --pixel 2 --arg ink=2 --arg bandDither=0.15 --arg splatDither=0
python3 $K/scripts/golden.py check --shots /tmp/rd --goldens goldens/radar
```

`goldens/radar@scene` and `goldens/radar@3s` carry their own `render.json`; `check` prints the
exact `views` command when the settings differ.
