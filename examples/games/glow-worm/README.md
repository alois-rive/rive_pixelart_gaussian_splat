# Game: Glow Worm (Cold Light, 3 colours)

**How to play:** click to start, then move the pointer: the glowing worm crawls after it. Eat the
crystals to grow; never let its head touch its own body or a stalagmite.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1, codex-cli 0.167. Palette: [Cold Light](https://lospec.com/palette-list/cold-light) by
A_Lamp, three colours: a near-black navy `#08001f`, a slate blue `#444d84` and a pale mint `#b2d5d1`.
It loaded from Lospec, so the spare (`rosy-42`) was not needed.

A dark cave seen from above (orthographic, pitch 58, `orthoHeight` 6.2 m, `pixelSize` 3, texel
0.0456 m). With three colours, light carries everything:
- **The cave is dark.** A skylight from the front left (yaw -50, pitch 52) with `keyLight` 1.0 and
  `shadeSteps` 2 sinks most rock faces from slate into a dithered dark. The rim of boulders is a dark
  mass with slate tops, freckled with pale glow-worm specks. The floor's ramp never steps up: only its
  painted slate glints show, and they vanish in the stalagmites' shadows.
- **What lives there glows.** The worm and the crystals are unlit pale, inked slate at their
  silhouettes. Every bead, the head and every crystal stands on its own stippled pool of light (an
  alpha-masked Bayer disc, `models/env/halo.png`), so the worm lights a trail of floor as it crawls.
  When it dies, the light goes out bead by bead.

## Rules

- **Steering.** One verb: move the pointer. The first click starts a run. The head turns towards the
  pointer at a limited rate (4.2 rad/s) and never stops crawling: 2.0 m/s, plus 0.04 per crystal, up
  to 3.0. Near the cave's walls the worm turns back in by itself; the walls do not kill.
- **Growing.** Three crystals are always in the cave. Eating one scores +1, makes the head gulp and
  sends a bulge down the body. When the bulge reaches the tail, the worm grows one bead (up to 46).
- **Dying.** The run ends when the head touches its own body (from the fourth bead on) or one of the
  three stalagmites. GAME OVER shows the cause, the score and the session's best; the next click
  starts a new run in the same cave.
- **Length of a run.** A long worm cannot circle in place (a tight turn is about 12 beads round), so
  the cave fills up: runs last 20 to 60 seconds.

**Sound** (procedural, `sfx.as`; silent in demo mode): a run opens on a low bell fifth; the worm's
crawl is a faint tick every half second (higher as it speeds up); a new crystal glints. Eating one
gulps and rings a bell that climbs an A minor pentatonic with the score (two octaves, then round
again; every tenth the octave rings too), and the bead the tail grows plips. A crash knocks and
tolls a low bell, the beads go out with falling pops, and GAME OVER plays a low lose jingle. Panned
by where it happens.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the worm is crawling from frame 0 and
eats its first crystal at about 0.5 s. The demo player:
- re-thinks 7 to 14 times a second;
- goes for the nearest crystal with a little aim error;
- weighs a fan of 17 headings by simulating the arc the worm would really crawl at its turn rate, and
  takes the one closest to its goal that keeps clear of its body, the stalagmites and the walls;
- now and then stops looking for half a second (more often the longer it is) and heads straight for
  the crystal. That slip is what ends most of its runs.

Measured over three minutes: runs of 19 to 40 s, scores 16 to 28, ending on a stalagmite or its own
tail. It restarts two seconds after GAME OVER. When demo turns off, a fresh run waits for the first
click, with the idle worm looping round the middle and the hint on screen.

## What is where

```
art/palette.json, palette.png   Cold Light: ramps rock, floor, stone, glow, dim, halo, spark; roles
art/assets.md                   the asset list, the ramp table (one value per read), bones, layout
art/worm/                       the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/worm/                    spec + gate record, make_worm.py -> p1_blockout, p2_form (gated mesh),
                                p3_splat_fit (what bakes), p4_parts (head.glb, bead.glb: the game's parts);
                                worm.bake.json (the bench), gate shots
models/env/                     make_env.py writes cave, stalagmite, crystal, spark .txt (hedra command
                                files), halo.png (the light-pool stipple), floor.png (the floor's glints);
                                their GLBs
lookdev/                        the turntable bench (no RML): worm.bin
scene.bake.json                 the composition: cave, three stalagmites, game bones (gem0-3, spark0-7,
                                seg0-45, head), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        worm (framed), worm@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 59 of 63 (head 1, beads 46, crystals 4, sparks 8). Splats: 85 572 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the worm (p1-p4), lookdev/worm.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh). The back view is gated at elevation 7 (`worm.spec.md`).
p2 is the gated mesh, so rebuild p1 + p2 into a scratch `.rmdl` (and note that p2 also exports
`worm.glb`: run `./build.sh` again afterwards):

```sh
python3 $K/scripts/golden.py views --hedra models/worm/worm.rmdl -o /tmp/w_p3 --views front,right,top
python3 $K/scripts/golden.py views --rive lookdev --blob worm -o /tmp/w_alb --look albedo --views front,right,top
python3 $K/scripts/golden.py views --rive lookdev --blob worm -o /tmp/w_albb --look albedo --views back --elevation 7
cp /tmp/w_albb/back.png /tmp/w_alb/ && python3 $K/scripts/golden.py gate --refs art/worm/refs --shots /tmp/w_alb -p art/palette.json --min-iou 0.7
python3 $K/scripts/golden.py views --rive lookdev --blob worm -o /tmp/w --real-sky
python3 $K/scripts/golden.py check --shots /tmp/w --goldens goldens/worm
python3 $K/scripts/golden.py views --rive lookdev --blob worm -o /tmp/ws --texel 0.0456 --size 120 --real-sky
python3 $K/scripts/golden.py check --shots /tmp/ws --goldens goldens/worm@scene
for n in 090 800 1460; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Play it headless: `rive scene --screenshot=$PWD/p.png --advance=5 --pointer=click@246,230 --advance=50
--pointer=move@202,175 --advance=250`. The click starts the run, and the move leads the worm into the
left stalagmite: it breaks up, then GAME OVER, "IT HIT A STALAGMITE". A click after that starts a new
run. The hand-over: a
`--commands` file with `data demo=true`, `advance 300`, `data demo=false`, `advance 20` shows the idle
worm and the hint. Take goldens and audits with `--screenshot`, not from `--commands` captures (those
were not palette-exact for frog-choir).

## Notes from building it

- **The first look was all dark.** Rocks painted on the dark step with the sun's highlight as the only
  lift drew a black screen with a few slate scraps. A slate rim lit too evenly then drowned the glow.
  The answer is a slate-painted rim that a high `keyLight` (1.0) and `shadeSteps` 2 dither down into
  the dark.
- **The floor's glints.** At 3 splats a texel they read as worms of slate. At one splat a texel they
  read as wet stone.
- **The stalagmites had lost their lower halves.** After the join, the object's origin sat at the
  spire's centre (z 0.575), and `select face where "pos.z < 0"` reads object-local positions: it cut
  away everything under 0.575 m. `apply --location` before the cut fixed it; they are now scaled up
  (1.15 to 1.35) so they read as spires from 58 degrees.
- **Crystals.** Decor crystals on the floor would read as food: there are none, and the cave's ambient
  sparkle is the glow-worm specks on the rocks. The food crystals got fatter shards (r 0.1 to 0.16) when
  the thin ones inked to slate and read as glyphs.
- **The demo.** Its first avoidance tested straight lines the worm cannot turn onto, and it died on a
  stalagmite every few seconds. It now simulates the turning arc of each candidate heading.
- **Idle crystals.** The idle worm loops round the middle. Before a visitor's first click, the
  crystals are placed off that loop, so the worm never crawls over food it does not eat.
- **The sheet.** The Codex sheet was not reviewed by a person yet (`art/worm/sheet.v1.png.json`,
  `reviewed: false`).
