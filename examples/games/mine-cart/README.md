# Game: Mine Cart (EN4, 4 colours)

**How to play: click a switch (or anywhere: the next one ahead) to send the rolling cart down the other
lane: grab the gems, dodge the rockfalls.**

**Touch:** tap a switch to flip it, or tap anywhere to flip the next one ahead.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra
0.1.0, codex-cli. Palette: [EN4](https://lospec.com/palette-list/en4) by ENDESGA (loaded from Lospec; the
spare was not needed), four colours shared by 7 ramps. A lantern-lit mine floor in the dark: green rock,
a navy track with green rails, tan timber and a tan cart, and cream kept for the gems. Orthographic, 38
degrees down, Bayer dither at the band edges, ink 1, a flat navy void.

Rules: the cart rolls round an oval track by itself, clockwise, a little faster with every gem (2.2 to
4.6 m/s). Four junctions each open a second lane beside the main one (the straights bulge a lane
outwards, the U-turns cut a tight inner lane). A click flips the switch nearest the click (its lever or
its lane), or, away from every switch, the next one ahead; the lever swings over and a dotted line shows
the lane each switch is set to (the next one blinks). Gems float on the lanes (+1 each, one or two at a
time); rockfalls drop from the roof onto a lane and turn it into a dead end: running into one crashes the
cart, which tumbles, spills its cargo and ends the run with the score. When the cart leaves a junction
the junction gets new content, rocks more often as the score grows. The first junction of a run is
friendly (a gem on lane B), the second has a rock on lane A. The first click rolls the cart; after a crash
the next click (after 0.7 s) rolls again in the same mine. The best is kept for the session (the demo
keeps its own).

Demo (`--arg demo=true`, the gallery's `Sample.demo`): a run starts at once, 2.4 m before the first
junction; a rock starts dropping on lane A within half a second and the demo flips the switch at about 0.4 s, so there is
action in the first second. For each junction ahead it picks the lane away from rocks and towards gems,
and clicks with a human lead (usually 0.55 to 1.5 s before the junction, sometimes a late 0.2 to 0.35 s,
and with a chance that grows with the score, 2.5 % rising to 30 %, too late). A typical demo run collects
15 to 25 gems and crashes after 30 to 60 s; two seconds after the crash it rolls again. Turning demo off
starts a fresh run at once.

Sound (`sfx.as` presets, silent in demo): a fanfare rolls the cart; the wheels clack over a rail joint
every 1.2 m, so the rhythm quickens with the speed; a flipped lever latches with a click and a clunk
(a little higher towards lane B); each gem rings a coin, quick pickups climbing a pentatonic step each,
every tenth gem a rising arpeggio; a loose rock whooshes from the roof and lands with a thud and a
gravel crunch (louder near the cart); a crash bursts and crunches, the tub thuds down, then a falling
sting with CRASH! and a rising arpeggio for a new best.

```
art/palette.json, palette.png   EN4 with ramps rock, wood, iron, rail, gem, glow, cave
art/assets.md                   the asset list: sizes, ramps, the value plan, bones (17 of 63, all game bones)
art/cart/                       the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/cart/                    spec + gate record, p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB
models/env/                     make_env.py: the one track layout -> rails.txt (swept rails), floor.txt +
                                textures/floor.png (painted beds), stands.txt, the lever spots, the track table
                                in scene/game.as; and lever, gem, rocks, stones, puff, timber, crystals, walls
                                command files; their GLBs
lookdev/                        the turntable bench (no RML): cart.bin
scene.bake.json                 the composition: the static mine, the game pieces as bones and pools
                                ("bone" / "copies"), a "bounds" play area
scene/                          the Rive project: scene.rml (orthographic 6.8 m, yaw 0, pitch 38, sun front left,
                                Bayer dither), the renderer files, game.as (all of the game)
goldens/                        the cart framed and at the scene's texel (0.05 m); scene frames (the hint and
                                three demo frames)
shots_scene/                    the latest scene frames (frame_030, demo_045, demo_300, demo_2250)
build.sh                        rebuilds every model and blob from the command files
```

What moves (17 game bones, no baked tracks): the cart (follows the track by arc length on the same
straights and arcs as the rails; leans on curves, rattles, squashes on a pickup, tumbles on a crash),
four levers (a spring with an overshoot and a pop), six gems (pop in, float and turn, swell away; spill
from the tub on a crash), three rockfalls (drop from the roof, squash on landing, a dust puff), three
dust puffs (stepped growth in four poses). A crash and a nearby landing shake the camera by whole art
pixels (the orthographic target snaps to the grid).

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                             # models/env + cart from scratch, lookdev/cart.bin, scene/splats.bin
rive scene --verify && rive scene                      # play; --arg demo=true to watch the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/cart/cart.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/cart/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08    # top: waiver in the spec
python3 $K/scripts/golden.py views --rive lookdev --blob cart -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/cart/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunYaw=-35 --arg sunPitch=42 --arg keyLight=0.45 --arg highlight=0.8 --arg shadeSteps=1 --arg lightSteps=1 --arg splatDither=0 --arg bandDither=0.45 --arg edgeDepth=0.5"
python3 $K/scripts/golden.py views --rive lookdev --blob cart -o /tmp/cart --real-sky ${=L}            # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/cart --goldens goldens/cart
python3 $K/scripts/golden.py views --rive lookdev --blob cart -o /tmp/cart_s --texel 0.05 --size 160 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/cart_s --goldens goldens/cart@scene
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
for n in 45 300 2250; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Notes from building it:

- The first layout (11 m of track at a 9.6 m view, texel 0.072) made the cart a 16-pixel white blob and
  the rails fat tan bands: the mine was rebuilt around the cart (the oval shrunk to 9.2 m, the view to
  6.8 m, pitch 52 -> 38 so the tub's sides and wheels show) and the rails painted green, so the track is
  a dark band and only gems and the cargo are cream.
- With four colours, value carries everything: tan was taken from the scenery (green stones, a 2-step
  `cave` ramp for the walls so lit rock does not stipple tan) and kept for the cart, the timber and the
  hazard; the tan crystal cluster first placed in the middle of the oval read as a rockfall and moved
  out.
- One layout, three uses: `make_env.py` sweeps the rails in hedra (`extrude` for straights, `spin` round
  arcs), paints the beds into the floor texture and writes the track table that `game.as` follows; the
  cart therefore never leaves the rails, whatever the layout.
- At pixelSize 3 on 640 the HUD first sat 2 screen pixels off the art grid (the frame audit dropped to
  ~96 % solid blocks) and `hud()` slid every rectangle onto it; the renderer now aligns the HUD itself,
  the workaround is gone and the frames are pixel-identical.
- The Codex sheet was not reviewed by a person yet (`art/cart/sheet.v1.png.json`, `reviewed: false`).
