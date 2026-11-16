# Example: a dwarven forge on a floating volcanic island (Lava-GB, 4 colours)

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [Lava-GB](https://lospec.com/palette-list/lava-gb) by Aero,
four colours (navy, purple, magenta, salmon) shared by six ramps. Four values, one job each: the
sky is navy, the island purple, the forge magenta, the lava salmon (with magenta crust, cracks and
lava fall); the trip-hammer's lever and head are navy and purple, so they read against the magenta
forge. A sun from the front left at 50 degrees keeps lit faces on their painted step and
`shadeSteps` 1 drops a face in shade exactly one step (the forge to purple, never to the sky's
navy). The light comes from `unlit` splats: the lava pool and its channel, the glowing cracks, the
furnace fire, the hot bar on the anvil and its sparks, the lava fall, the embers. Bayer (ordered)
dither on the art grid in a narrow band, ink 1, no fog. In the live preview: drag to orbit, wheel
to zoom.

What moves (9 of 63 bones, all rigid, baked at 12 fps, stepped): the trip-hammer lifts its head 30
degrees and drops it on the hot bar on the anvil (1.5 s), and a burst of salmon sparks flies off the
bar for the three frames around each strike; the crucible swings on its chain over the pool (3 s);
four crusted blobs bob out of the lava (2 s, a quarter loop apart); embers spiral up out of the pool
(a seamless 1.5 s helix, four per metre); globs stream down the lava fall into the void (a seamless
1 s loop).

## Readability pass

The first version was hard to read at a glance: the island's rock was painted navy, the sky's own
colour, so its top vanished; a low sun (22 degrees) with key light 0.55 and `shadeSteps` 1.5 sank
the purple forge to navy on every face not turned to the sun (from yaw 120 or 220 the forge was
gone); fog and a wide Bayer band laid navy checkers over the far half; the mouth rim was magenta on
the magenta glow; the embers were a busy column. What changed:

| Problem | Fix |
|---|---|
| island top = sky colour | `scene.bake.json`: island, basalt and rock `Rock` `"step": 1` (navy -> purple); the underside still shades to navy against the purple glow below |
| forge merging with the island | forge `Stone` on the `rock` ramp (navy, purple, magenta) with `"step": 1`: lit magenta, purple in shade, never salmon (salmon is the lava's) |
| everything a step too dark | `sunPitch` 50, `keyLight` 0.4, `highlight` 0.85 (the island top stays purple), `shadeSteps` 1 |
| checker noise, far half eaten | `bandDither` 0.25, `fogMax` 0 |
| the fire lost in its rim | forge `Rim` `"step": -1` (purple frame round the salmon fire) |
| the strike not reading | forge `Iron` `"step": 1` (a purple anvil under the navy head), a hot bar on the anvil and a spark burst at each strike (`hammer.txt`), the lift 24 -> 30 degrees |
| clutter round the forge | the basalt columns scaled 0.7 / 0.6; the crane's iron one step up (purple, not a navy bar across the pool); embers 7 -> 4 a field |
| framing | yaw -40 (the forge's lit front and left, the lever side-on), `orthoHeight` 7, `targetY` -0.1 |

The step offsets live in the scene's bake file, so the forge's own model, its gate record and its
lookdev goldens (`goldens/forge`, `forge@scene`, lit as the first version was) are unchanged.

```
art/palette.json, palette.png   Lava-GB with ramps rock, stone, iron, wood, ember (unlit), lava (unlit)
art/assets.md                   the asset list, layout and the seamless-loop recipe
art/forge/                      the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/forge/                   spec + gate record, p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB
models/env/                     make_env.py (writes island, lavafall, embers, blobs), hammer.txt, crane.txt,
                                rock.txt, basalt.txt: hedra command files and GLBs
lookdev/                        the turntable bench (no RML): forge.bin
scene.bake.json                 the composition: instances, transforms, material -> ramp, flags, fps
scene/                          the Rive project (scene.rml tuned: orthographic 7 m, yaw -40, pitch 30,
                                sun at 50 degrees, narrow Bayer band, navy sky over the purple glow below)
goldens/                        the forge framed and at the scene's texel (0.06 m), three scene frames
shots_scene/                    the scene frames 2 (a strike: sparks), 56 (the head up), 86 (landing)
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                             # models/env + forge from scratch, lookdev/forge.bin, scene/splats.bin
rive scene --verify && rive scene                      # the live preview: drag to orbit, wheel to zoom
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/forge/forge.rmdl -o /tmp/p2 --views front,right,back,top --elevation 3
python3 $K/scripts/golden.py gate --refs art/forge/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08   # top: waiver in the spec
python3 $K/scripts/golden.py views --rive lookdev --blob forge -o /tmp/alb --look albedo --elevation 3 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/forge/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunYaw=-35 --arg sunPitch=22 --arg keyLight=0.55 --arg highlight=0.8 --arg splatDither=0 --arg bandDither=0.4"   # the first version's light (the hero goldens)
python3 $K/scripts/golden.py views --rive lookdev --blob forge -o /tmp/forge --real-sky ${=L}       # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/forge --goldens goldens/forge
python3 $K/scripts/golden.py views --rive lookdev --blob forge -o /tmp/forge_s --texel 0.06 --size 160 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/forge_s --goldens goldens/forge@scene
for n in 2 56 86; do rive scene --screenshot=$PWD/shots_scene/frame_$(printf %03d $n).png --advance=$n; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/frame_002.png -p art/palette.json --pixel 3
```

Notes from building it:

- Four colours make separation a matter of value, not hue: give each read its own value (sky navy,
  ground purple, hero magenta, light salmon) and let shade move a material one step at most. The
  first version painted the island navy and the forge purple: the island top merged with the sky
  and a low sun took the forge down to navy too (see "Readability pass").
- The trip-hammer's beam first crossed the furnace mouth and hid the hero's glow: the axle moved
  back-left (yaw -22.4) and the head grew to 0.6 m so the beam runs above the mouth.
- Rising embers first started 6 m under the pool, and under a floating island that is open air: they
  showed below it. Eight 1 m copies with a golden-angle turn keep the hidden band inside the rock.
- The Codex sheet was not reviewed by a person yet (`art/forge/sheet.v1.png.json`, `reviewed: false`).
