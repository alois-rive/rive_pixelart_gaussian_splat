# Game: Firefly Jar (retrocal-8, 8 colours)

**How to play: click, then sweep the net with the pointer through the fireflies to catch them; keep
the net away from the moths. 60 seconds.**

**Touch:** tap to start, then drag to sweep the net: it rides a few pixels above your finger and stays
where you lift.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [retrocal-8](https://lospec.com/palette-list/retrocal-8) by
polyphrog, eight colours; it loaded from Lospec, so the spare (`nanner-pancakes`) was not needed. A
summer night in a clearing: dark teal grass, plum shadows and tree silhouettes lit teal by a high
moon, red flowers, a pond with the moon's reflection, a glass jar on a stump, and cream fireflies
that glow (unlit) in the dark.

The rules: the net follows the pointer over the clearing (it lags a little on a spring and leans into
the sweep). A firefly that the net's hoop passes over on screen is caught: it arcs into the jar and
glows there (the jar shows up to 12). Fireflies wander, blink and shy away from a net that comes close;
new ones rise out of the grass. Moths (one at first, up to five) flutter towards the net: a touch lets
three fireflies escape from the jar (-3) and knocks the net aside for a moment. The clock runs 60
seconds; "TIME!" shows the jar's count and the session's best; the next click starts again (the jar's
fireflies fly off first). Pointer only.

Sound (procedural, `sfx.as`; silent in demo mode): a run opens on a soft bell fifth; a catch pops
where the net is, and the firefly reaching the jar rings a bell that climbs a major pentatonic with
the jar's count (two octaves, then round again), with a sparkle every tenth. A new moth flutters in
low; a moth on the net knocks and the escaping fireflies whoosh out of the jar. The last ten seconds
tick (higher for the last three); TIME! plays a fanfare, with a sparkle for a new best.

Demo mode (`--arg demo=true`, or the `Sample` view model's `demo`): it opens with the net already
sweeping into a line of fireflies (a catch within the first second); it chases the nearest firefly not
next to a moth, aims a little off, moves at a hand's speed, sidesteps moths that come close (not
always in time), and fills the jar with about 40 in a run; it restarts two seconds after "TIME!".
When demo turns off, a fresh run starts.

What moves (38 of 63 bones, all game bones moved by `scene/game.as`): the net, 16 fireflies, 12
fireflies in the jar, 5 moths, 4 twinkles.

```
art/palette.json, palette.png   retrocal-8 with ramps grass, leaf, wood, glass, cloth, glow, moth; roles
art/assets.md                   the asset list, bones, layout
art/jar/                        the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/jar/                     make_jar.py -> p1_blockout.txt, p2_form.txt; spec + gate record (waiver),
                                bake file, gate shots, jar.glb
models/env/                     make_env.py -> meadow, pond, tree, bush, tuft, flower, stump, net,
                                firefly, moth, spark (.txt command files and .glb)
lookdev/                        the turntable bench (no RML): jar.bin
scene.bake.json                 the composition: instances, game bones, bounds
scene/                          the Rive project: scene.rml (orthographic, yaw 0, pitch 42, 8.08 m,
                                pixelSize 2, moonlight), game.as (the whole game), the renderer files
goldens/                        jar/, jar@scene/, scene/ (demo_045, demo_300, demo_1200; frame_030)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Rebuild and play (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models from scratch, lookdev/jar.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary
rive scene                                   # play; `rive scene --arg demo=true` to watch the demo
```

Check (gates, goldens, frame audit, a scripted sweep):

```sh
python3 $K/scripts/golden.py views --hedra models/jar/jar.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/jar/refs --shots /tmp/p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob jar -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/jar/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7   # top: waiver in the spec
L="--arg sunYaw=-35 --arg sunPitch=58 --arg keyLight=0.62 --arg highlight=0.9"
python3 $K/scripts/golden.py views --rive lookdev --blob jar -o /tmp/j --real-sky ${=L}               # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/j --goldens goldens/jar
python3 $K/scripts/golden.py views --rive lookdev --blob jar -o /tmp/js --texel 0.027 --size 120 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/js --goldens goldens/jar@scene
mkdir -p /tmp/fj; for n in 045 300 1200; do rive scene --screenshot=/tmp/fj/demo_$n.png --advance=${n#0} --arg demo=true; done
rive scene --screenshot=/tmp/fj/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots /tmp/fj --goldens goldens/scene
python3 $K/scripts/palette.py frame goldens/scene/demo_300.png -p art/palette.json --pixel 2
rive scene --screenshot=/tmp/sweep.png --advance=2 --pointer=click@320,200 --advance=10 '--pointer=drag@60,120>600,140:60' '--pointer=drag@600,300>60,280:60'
```

Notes from building it:

- With the crowns painted the grass's teal, only their plum shadows showed: the `leaf` ramp starts
  with the plum twice, so foliage is a night silhouette whose tops catch the moon.
- `api.project` returns collapsed coordinates until the first frame is drawn, which caught all 16
  fireflies at once on frame 1: catches and moth touches wait 0.25 s into a run.
- The first balance let the demo jar 125 in a minute; a smaller catch radius, shy fireflies, a slower
  respawn and a slower demo hand bring it to about 40.
- The Codex sheet was not reviewed by a person yet (`art/jar/sheet.v1.png.json`, `reviewed: false`).
