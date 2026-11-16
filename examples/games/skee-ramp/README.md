# Game: skee ramp (Bubblegum 16)

**How to play:** press on the ball, drag up and let go: a longer drag rolls it harder, sideways steers it.
Nine balls; land them in the rings; 300 wins a prize.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra 0.1.0,
codex-cli. Palette: [Bubblegum 16](https://lospec.com/palette-list/bubblegum-16) (loaded from Lospec; the spare
`fantasy-24` was not needed), as six ramps (pink, fire, blue, mint, dusk, wood). A night arcade: three
skee-ball lanes on a zigzag carpet under neon signs (a star, a ring, a bolt: `unlit`), seen from behind the
player through a fixed perspective camera (fov 30, `pixelSize` 2: 320 x 200 art pixels), lit from above.

Rules: the ball rolls up the sloping lane, slowing; with enough speed it jumps the hump and lands on the
slanted target board: the centre hole 50, the rings around it 30, 20 and 10, the board around them 10, the
small cup near the top 100 (it takes a hard roll). Too soft and it rolls back for nothing ("TOO SOFT"). The
scored ring blinks, the ball squashes and drops into its hole, and the next ball hops out of the tray. After
nine balls: "PRIZE!" at 300 or more, else "NO PRIZE"; best is kept for the session; a click starts again.
While aiming, the ball is drawn back and squashed, a dotted path and a power bar grow with the drag
(mint, yellow, pink).

Sound (`sfx.as`, silent in demo mode): a blip when the ball is pressed, a rising note at every fifth of
the power while dragging, a thump on release (deeper for a harder roll), then a low rumble of ticks while
it rolls (quicker and higher when fast), a click off a rail and a hop over the hump. On the board a thud
and the hole's sound: 10 a low note, 20 a higher one, 30 a coin, 50 a coin and a bell, the 100 cup a
power-up and a high bell; too soft is a sad falling bloop. The next ball clacks onto the lane; a run ends
with a fanfare and a bell for a prize, the losing arpeggio without; a new run drops a token in the slot.

Demo (`--arg demo=true`): a fair player who mostly goes for the 50 hole, now and then the cup (15 %), with a
hand that is off in strength by up to 0.18 of the power range and sideways by up to 20 px; its drag is shown
like a player's. It aims within the first half second and throws at 0.6 s; a run takes about 22 s, scores
about 290 on average (a prize about 40 % of the time), and starts again 2 s after the end.

```
art/palette.json, palette.png   Bubblegum 16 with its ramps and roles
art/assets.md                   the asset list, the camera, the lane's numbers the game uses
art/lane/                       the hero's Codex brief, sheet v1 (reviewed: false), record, cut views (refs/)
models/lane/                    spec + gate record (back-view waiver), p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB
models/env/                     make_env.py (writes floor, wall, neon, tray, ball, flash command files and the
                                carpet texture), the command files, textures/carpet.png, GLBs
lookdev/                        the turntable bench (no RML): lane.bin
scene.bake.json                 the composition: 77 000 splats, 10 game bones (ball0-8, flash)
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        lane (framed), lane@scene (texel 0.022), scene (demo_030/075/1440, frame_030)
shots_scene/                    the scene frames the goldens were snapped from
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models from scratch, lookdev/lane.bin, scene/splats.bin
rive scene --verify && rive scene            # play it
rive scene --arg demo=true                   # watch the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/lane/lane.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/lane/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08   # back: waiver in the spec
python3 $K/scripts/golden.py views --rive lookdev --blob lane -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/lane/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunYaw=-30 --arg sunPitch=42 --arg highlight=0.92 --arg edgeDepth=1.2"
python3 $K/scripts/golden.py views --rive lookdev --blob lane -o /tmp/lane --real-sky ${=L}           # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/lane --goldens goldens/lane
python3 $K/scripts/golden.py views --rive lookdev --blob lane -o /tmp/lane_s --texel 0.022 --size 200 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/lane_s --goldens goldens/lane@scene
for n in 30 75 1440; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_075.png -p art/palette.json --pixel 2
# played: one good throw (+50), and nine weak ones (NO PRIZE)
rive scene --screenshot=$PWD/played.png --advance=10 '--pointer=drag@320,290>320,218:10' --advance=105
```

Notes from building it:

- The first camera (5 m away, fov 36) filled the frame with one lane and made near splats huge; it backed
  off to 8.3 m at fov 30, and the neighbours, floor and wall dropped to coarser spacings (102 000 -> 77 000).
- The lit lane jumped from orange to yellow (the fire ramp's top step): `highlight` 0.92.
- Scoring was first 50/40/30/20 with a demo error half as large: every demo run won (420-520). The values
  are skee-ball's (50/30/20/10, the cup 100) and the demo's hand was tuned with a simulation of the throw
  model (average about 290, a prize 40 % of the time).
- The ball is a game bone moved along the lane's own numbers; the flight off the hump is an eased arc to the
  landing point the speed at the hump picks (a fraction up the board), not a collision with the mesh.
- The Codex sheet was not reviewed by a person yet (`art/lane/sheet.v1.png.json`, `reviewed: false`).
