# Example: a coral reef with a giant clam (BLK AQU4, 4 colours, underwater)

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [BLK AQU4](https://lospec.com/palette-list/blk-aqu4) by
BurakoIRL, four colours (navy, blue, aqua, pale aqua) shared by seven ramps. Underwater: a
perspective camera (fov 40) low over the sand, heavy fog into the blue water colour (`fogMax` 0.55,
fog = sky = #005f8c, no sky split), a high sun from the surface, soft per-splat dither, a light ink
(1 step, only past 1.2 m of depth). In the live preview: drag to orbit, wheel to zoom.

What moves (32 of 63 bones, baked at 12 fps, stepped): the clam's upper shell breathes (rigid, closes
10 degrees and reopens, 6 s); six kelp stalks sway (skinned, 3 bones each, a circular 4 s sway, each
instance its own phase); two schools of three fish circle the reef (rigid: an Orbit empty turns in
12 s, each fish's tail flicks as a child part); bubbles rise from the sand and through the clam (a
seamless 6 s loop, unlit); the sea fans sway (`sway` flag).

```
art/palette.json, palette.png   BLK AQU4 with ramps sand, rock, coral, kelp, shell, fish, glow (unlit)
art/assets.md                   the asset list, with the animation and bone count
art/clam/                       the hero's Codex brief, sheet (v1), record, cut views (refs/)
art/textures/                   make_textures.py and its palette-exact sand_64.png (ripples)
models/clam/                    spec + gate record, make_p1.py -> p1_blockout.txt, p2_form.txt (rest pose,
                                clam_rest.glb), p3_motion.txt (clam.glb), bake files, gate shots
models/env/                     make_env.py (writes seabed, bubbles, fish), kelp.txt (skinned), coral_branch,
                                coral_brain, coral_fan, rock: hedra command files and GLBs
lookdev/                        the turntable bench (no RML): clam.bin (animated), clam_rest.bin (gates)
scene.bake.json                 the composition: instances, transforms, material -> ramp, flags, fps, phase
scene/                          the Rive project (scene.rml tuned: perspective, fog, flat water colour)
goldens/                        the clam framed, at the scene's density, half closed (@3s); three scene frames
shots_scene/                    the scene frames at t = 2, 30, 70 (60 fps frames)
build.sh                        rebuilds the texture, every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                             # texture, models from scratch, lookdev blobs, scene/splats.bin
rive scene --verify && rive scene                      # the live preview: drag to orbit, wheel to zoom
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/clam/clam.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/clam/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob clam_rest -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/clam/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunPitch=65 --arg sunYaw=-30 --arg keyLight=0.3 --arg highlight=0.95"
python3 $K/scripts/golden.py views --rive lookdev --blob clam -o /tmp/clam --real-sky ${=L}          # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/clam --goldens goldens/clam
python3 $K/scripts/golden.py views --rive lookdev --blob clam -o /tmp/clam_s --texel 0.037 --size 160 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/clam_s --goldens goldens/clam@scene
python3 $K/scripts/golden.py views --rive lookdev --blob clam -o /tmp/clam_3s --views front,right,iso --advance 3s --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/clam_3s --goldens goldens/clam@3s
for n in 2 30 70; do rive scene --screenshot=$PWD/shots_scene/frame_$(printf %03d $n).png --advance=$n; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/frame_002.png -p art/palette.json --pixel 3
```

Notes from building it:

- The clam's teeth and ribs are vertices and faces at given angles round a 10-sided ring; hedra's
  `select where` has no trig, so `make_p1.py` writes the angle tests out as expressions.
- The interior colour goes on the inset face before its extrude, but the walls the extrude makes
  keep the shell's material: `select face where "abs(normal.z) < 0.9 && normal.x*pos.x + normal.y*pos.y < 0"`
  (side faces looking at the axis) picks them afterwards.
- Perspective near sand is coarse: a 32 px ripple texture over 14 m made blotches at the bottom of
  the frame; 64 px (0.22 m a texel, ~2.4 splats) reads as ripples.
- The clam is placed at 1.4x in the scene (pixel-art exaggeration for the hero); its @scene golden
  uses the scene's texel at the clam divided by that scale (0.052 / 1.4 = 0.037).
- The Codex sheet was not reviewed by a person yet (`art/clam/sheet.v1.png.json`, `reviewed: false`).
