# Game: Bath Navy (Lost Century)

**How to play: click to fire a soap bubble where you point; pop the toy boats before they reach the duck.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Lost Century](https://lospec.com/palette-list/lost-century) by
SurrealEmber (it loaded from Lospec: the spare, Cold Light, was not needed), ten ramps (enamel, water,
duck, beak, wood, red, tile, bubble, ink, sponge): a muted, warm bathroom of cream enamel, sage tiles
and teal water.

The rules: the duck floats at the left end of the tub; toy boats rise out of the water under the faucet
and weave down the tub, homing on the duck for the last stretch. Each click turns the duck and fires a
bubble that flies over the water where you pointed (up to four in flight). A sailboat pops for 10, a
speedboat for 20, a tugboat takes two bubbles for 30. A boat that reaches the duck bonks it: three bonks
end the run (the lives are the little ducks, top right). Boats come out faster and sail faster as the run
goes on, so a run lasts about a minute. Best score for the session; click to play again. Before the first
click the fleet waits under the faucet. Demo mode (`--arg demo=true`) starts mid-battle with two boats out:
it leads the nearest boat, misses now and then (a wild shot one time in ten), loses about a minute in, and
starts again 2 s after the game over.

```
art/palette.json, palette.png   Lost Century with its ramps and roles (void #4b3d44; no sky in view: horizon 2)
art/assets.md                   the asset list
art/duck/                       the hero's Codex briefs, sheets v1 and v2, records and logs, cut views of v2 (refs/)
models/duck/                    make_duck.py (writes p1_blockout.txt, p2_form.txt), spec + gate record (with a
                                colour-drift waiver), bake file (lookdev), gate shots, the GLB
models/env/                     make_env.py (writes every other command file and the textures): room, tub,
                                faucet, props, foam, towel, sailboat, tugboat, speedboat, bubble, drop; GLBs
lookdev/                        the turntable bench (no RML): duck.bin
scene.bake.json                 the composition: the bathroom, 27 game bones (pools), the play area bounds
scene/                          the Rive project: scene.rml (orthographic 6.6 m, yaw 0, pitch 50, sun 30 / 50,
                                swaying water), game.as (all the game), the renderer files, splats.bin (41 700)
goldens/                        duck framed and at the scene's texel (0.05), scene frames (demo_NNN, frame_030)
shots_scene/                    the scene frames the goldens were snapped from
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                  # models from scratch, lookdev/duck.bin, scene/splats.bin
rive scene --verify && rive scene           # play it; `rive scene --arg demo=true` watches the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/duck/duck.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/duck/refs --shots /tmp/p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob duck -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/duck/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7 \
  --max-color-drift 1     # colour drift waived: the spec explains it
L="--arg sunYaw=30 --arg sunPitch=50 --arg keyLight=0.4 --arg highlight=0.85"
python3 $K/scripts/golden.py views --rive lookdev --blob duck -o /tmp/dk --real-sky ${=L}       # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/dk --goldens goldens/duck
python3 $K/scripts/golden.py views --rive lookdev --blob duck -o /tmp/dks --texel 0.05 --size 120 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/dks --goldens goldens/duck@scene
for n in 90 300 660; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_300.png -p art/palette.json --pixel 3
```

Try it headless: `rive scene --screenshot=$PWD/shot.png --advance=5 --pointer=click@470,140 --advance=12`.

Notes from building it:

- The back wall first came out as a 1 m strip floating at 2.5 m: `scale` after `--rotation` on `add` scales
  in world axes. Scale, apply, then rotate.
- The basin's floor is the water (a face of the tub, textured), so no separate water surface fights it; its
  splats sway, so the water shimmers.
- The demo first held the tub for 90 s: the fleet now speeds up faster (pace +4 % a boat, up to 2.6 x).
- The Codex sheets were not reviewed by a person yet (`art/duck/sheet.v*.png.json`, `reviewed: false`).
