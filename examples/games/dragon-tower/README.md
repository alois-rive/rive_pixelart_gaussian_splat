# Game: Dragon Tower (Blessing, 5 colours)

**How to play: hold the pointer to breathe fire where it points; burn the knights climbing the
tower before they reach the top. Let go to let the fire recharge.**

**Touch:** press and hold where the fire should land, slide to sweep it over the climbers, lift to
recharge.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Blessing](https://lospec.com/palette-list/blessing) by
clarigariccus, five pastel colours (purple, mint, pale yellow, pink, thistle); it loaded from Lospec,
so the spare (`nanner-pancakes`) was not needed. A pastel dusk: a thistle sky dithering into a pale
yellow glow at the horizon, a mint meadow with pink blossom trees, a thistle tower with pale yellow
ladders, a mint and pink dragon on top. Every ramp starts at the purple, which is also the ink and
the shade.

The rules: knights walk in from the sides and climb three ladders (at -45, 0 and 45 degrees round the
tower), a rung at a time. Hold to breathe a stream of fireballs towards the pointer; a fireball that
overlaps a knight on screen burns it off its ladder (1 point, 2 in the top third or on the merlons).
The fire lasts about two seconds of holding and recharges when you let go; empty it and the dragon
only smokes ("TOO HOT!") until half the fire is back. A knight that reaches the top hops onto the
merlons, gloats, and is swatted off, but costs a heart; three hearts. Knights come faster, climb
faster and more of them at once as the run goes on. A run starts on the first press (which already
breathes fire); after "THE TOWER FELL!" the next click starts again. Pointer only.

Sound (procedural, `sfx.as`; silent in demo mode): a low fanfare starts a run; the flame roars as a
breathy gust every 10 frames, lower as the fire runs out; overheating zaps and the smoke puffs pop,
a two-blip "ready" when the fire is back. A burnt knight crunches and chimes a pickup a semitone
higher for each knight burnt in the same breath (a +2 a third higher); a knight landing thuds.
Knights in the top third tick on every rung, higher as they climb; one hopping onto the walk boings,
the swat whooshes and the lost heart hurts; THE TOWER FELL plays the lose jingle. Sounds are panned
by where they happen.

Demo mode (`--arg demo=true`, or the `Sample` view model's `demo`): it opens with two knights already
on the ladders and the dragon breathing within the first second; it aims at the highest climber,
leads it a little, with a reaction delay, a hand's speed and some wild misses, holds while the fire
lasts and lets go to recharge, and loses after a minute or so; it restarts two seconds after the game
over. When demo turns off, a fresh run starts.

What moves (36 of 63 bones, all game bones moved by `scene/game.as`): the dragon's body (breathing,
the inhale squash, the stretch into the flame, a flinch when a knight gets on the walk, a slump at the
game over) and head (turned and dipped towards the aim about the neck), 9 knights, 16 fireballs,
6 puffs, 3 drifting clouds.

```
art/palette.json, palette.png   Blessing with ramps stone, scale, blush, armor, fire, cloud, wing; roles
art/assets.md                   the asset list, bones, layout
art/dragon/                     the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/dragon/                  make_dragon.py -> p1_blockout.txt, p2_form.txt, p3_body.txt, p3_head.txt;
                                spec + gate record (waivers), bake file, gate shots, dragon(_body, _head).glb
models/env/                     make_env.py -> tower, ladder, ground, hills, tree, cloud, knight,
                                fireball, poof (.txt command files and .glb)
lookdev/                        the turntable bench (no RML): dragon.bin
scene.bake.json                 the composition: instances, game bones ("bone", "copies"), bounds
scene/                          the Rive project: scene.rml (orthographic look-at, 10.1 m, pitch 10,
                                pixelSize 2), game.as (the whole game), the renderer files, splats.bin
goldens/                        dragon/ (framed), dragon@scene/ (scene texel), scene/ (demo_040, demo_240,
                                demo_600 in demo mode; frame_030: the hint before the first click)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Rebuild and play (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models from scratch, lookdev/dragon.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary
rive scene                                   # play; `rive scene --arg demo=true` to watch the demo
```

Check (gates, goldens, frame audit, a scripted hold):

```sh
python3 $K/scripts/golden.py views --hedra models/dragon/dragon.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/dragon/refs --shots /tmp/p2 --min-iou 0.75          # right, top: waiver in the spec
python3 $K/scripts/golden.py views --rive lookdev --blob dragon -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/dragon/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7
L="--arg sunYaw=-38 --arg sunPitch=55 --arg keyLight=0.45 --arg highlight=0.82"
python3 $K/scripts/golden.py views --rive lookdev --blob dragon -o /tmp/d --real-sky ${=L}            # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/d --goldens goldens/dragon
python3 $K/scripts/golden.py views --rive lookdev --blob dragon -o /tmp/ds --texel 0.042 --size 200 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/ds --goldens goldens/dragon@scene
mkdir -p /tmp/dt; for n in 040 240 600; do rive scene --screenshot=/tmp/dt/demo_$n.png --advance=${n#0} --arg demo=true; done
rive scene --screenshot=/tmp/dt/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots /tmp/dt --goldens goldens/scene
python3 $K/scripts/palette.py frame goldens/scene/demo_240.png -p art/palette.json --pixel 2
rive scene --screenshot=/tmp/hold.png --advance=2 --pointer=down@200,300 --advance=30   # fire towards the pointer
```

Notes from building it:

- A pitched orthographic camera lifts far things by z sin(pitch): hills 16 m back first towered over
  the tower; they are 1.5 m low and 1.1 m tall now.
- With a pink sky the pink wing membranes vanished; the sky became thistle, and the membranes got
  their own `wing` ramp (purple, pink, pink) so the sun does not flare them to yellow.
- Purple knights on the purple shaded side of the tower disappeared; they wear mint and pink now,
  on pale yellow ladders. An `edgeDepth` small enough to outline them against the wall (0.35) speckled
  the grazing-angle meadow with ink, so it stays 1.0.
- `api.project` returns collapsed coordinates until the first frame is drawn: hit tests wait 0.25 s.
- The camera is aimed at the world origin so the orthographic snap is exact and the HUD (on whole art
  pixels from the frame's corner) stays on the art grid: 100 % solid blocks.
- The Codex sheet was not reviewed by a person yet (`art/dragon/sheet.v1.png.json`, `reviewed: false`).
