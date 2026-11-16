# Game: Plank Pass (Cretaceous-16)

**How to play: drag from a steel bolt (or a joint you built) to place a beam, tap a beam to remove it,
then press GO! and watch the kettle cart cross. Planks are the road; girders are stronger frame.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Cretaceous-16](https://lospec.com/palette-list/cretaceous-16) by Joao
Vasconcelos, sixteen muted earth colours; it loaded from Lospec, so the spare (`resurrect-64`) was not
needed. A dusty valley road on an afternoon: olive hills with dark pines, mauve-grey rock banks with a
darker stratum, slate creeks, khaki haze; tan wooden planks, slate girders, and the cart's red as the one
warm accent. Side view, orthographic 10.5 m (texel 0.077 m), `pixelSize` 3, the eye 20 degrees above the
road so the deck tops show; the camera only pans (snapped to the art grid).

## Rules

- One valley road, five gaps, in order: **Mill Creek** (6 m, water), **Fern Gully** (8 m, rocks),
  **Step Gorge** (8 m, the far bank 1 m higher), **Twin Rock** (12 m, a rock pillar in the middle) and
  **Long Wash** (12 m, water, nothing in between). Steel anchor plates sit on each bank edge, on the cliff
  faces below them and on Twin Rock's pillar.
- **Build** (pointer or finger): press on an anchor or a joint (a generous 0.95 m reach, about 12 art
  pixels) and drag; the end snaps to the 1 m grid, inside the gap's air, at most 3.2 m away (the preview
  clamps to the nearest reachable point and shows the beam's cost). Release to place it. A tap (a press
  without a drag) removes the nearest beam. **PLANK** / **GIRDER** select the material, **CLEAR** empties
  the gap, **GO!** tests it.
- **Planks** (wood, 20 a metre) are the road: the cart drives on them, following the smoothest plank onward
  at each joint (so a plank rising off the deck into a truss is not taken). **Girders** (steel, 55 a metre)
  are 2.8 times stronger and 4.4 times stiffer, but the cart does not drive on them. A beam's cost is
  rounded to 5; each gap has a budget (300, 500, 500, 650, 1700) and a beam over it is refused (the budget
  blinks). The stars the current cost would earn show under the budget.
- **The test**: the cart (mass 8) rolls on at 2.5 m/s. The bridge sags under its own weight and the
  cart's; each beam shows its stress as a line from olive through khaki and pink to red. A beam pushed
  past its strength snaps in two halves that dangle and fall; if the road runs out under a wheel the cart
  tumbles in (a splash or a crash), and two seconds later a fresh cart rolls in and you are back to
  building, your bridge as you left it. If the cart reaches the far bank: **IT HOLDS!**, stars by the
  budget left (3 at 80 % or less, 2 at 90 %, else 1), and on along the road to the next gap.
- After Long Wash the cart parks at the depot: **VALLEY CROSSED!** with the run's cost (the score: lower
  is better), its stars (of 15), the tries and the session's best (lowest) cost. The next click starts a
  new run at Mill Creek. A run is 1 to 5 minutes.

**Touch**: everything is a press, a drag or a tap. Nothing needs hovering: the preview appears while the
finger drags, a beam is placed on release, a tap removes one; the buttons are 15 HUD pixels tall and 40
to 44 wide (above the ~12 a phone tile at 0.55 scale needs). Tested touch-only (`touch down@ / drag@ / up@`):
the closed-loop player builds and clears all five gaps, also with every press and release thrown up to
14 px off.

**Sound** (`sfx.as`, silent in demo mode): a wooden plank lands with a low knock and a tick, a girder
with a clank and a faint high ring; removing a beam pops; the material buttons blip (higher for steel),
CLEAR whooshes, a refused beam or an empty GO buzzes low. GO blows the kettle's two-note whistle twice.
While the cart drives its chimney chuffs with every steam puff. Under load the most stressed beam creaks,
sparse and keyed to the stress (wood a low click and tick, steel a tick and a low bell groan, more often
and louder towards red, never more than every 10 to 28 frames). A snapping beam cracks (a hit and a click
for wood, a hit and a burst for steel) and shakes the view. The cart's fall whooshes; water is a splash
and a thud, rocks a burst, a thud and a hit, then a falling two-note sigh. A bridge that holds plays a C
major arpeggio ending on a bell and a coin per star; the valley crossed is a bell arpeggio (plus the win
fanfare for a new best). Nothing is decided by `api.rand()`.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): it opens with Mill Creek already bridged
and the cart rolling onto it at frame 0. At every other gap a hand cursor builds one of the gap's known
designs beam by beam (pressing the material button when the kind changes, a pixel or two of aim error,
quicker on the big Long Wash truss) and presses GO. Four times in ten it first builds the design without
its key beams (no king post, missing pillar struts, one diagonal short), which collapses, and then adds
what it left out and goes again. It restarts 2.6 s after VALLEY CROSSED (a loop is about 90 s); when
demo is switched off, a fresh run starts.

## The solver

A 2D truss in the plane of the planks (`scene/game.as`, `simStep`): joints are point masses (0.15 plus
half of each beam's mass) under gravity, anchors are fixed; beams are distance constraints with a
compliance (XPBD), so a beam stretches or squeezes under load and its force is the constraint's
multiplier. Verlet integration at a fixed 60 Hz step with 16 substeps and one constraint pass a substep
("small steps"), damping along each beam and a little air damping: stable for any design, and cheap
(up to 72 beams; `rive scene --bench=600 --arg demo=true` averages 1.4 ms a frame, script and render). The cart's two axles follow the road:
each wheel rides its plank to the end, then takes the smoothest plank leaving that joint to the right
(at most a 60 degree turn), or the far bank; its half of the cart's weight is split between the plank's
two joints. A beam whose force passes its strength snaps (two halves on new free joints); a wheel with
no road for 0.2 s starts the fall. Free joints stay out of the banks and above the floor.

**Known designs** (verified first in `tools/truss_port.py`, a Python port of the solver, then in the
game by the closed-loop player, by touch; the demo builds these, peak stress shown):

| Gap | Design | Cost / budget | Peak stress | Without its key beams |
|---|---|---|---|---|
| Mill Creek | three 2 m planks, two plank struts from the low anchors | 230 / 300 (3 stars) | 0.55 | crash |
| Fern Gully | four 2 m planks, struts, a king post below (or above) | 380 / 500 (3) | 0.73 | crash (no king post) |
| Step Gorge | a deck climbing one step, struts, a king post below (395) or 2 m above (415) | 395 / 500 (3) | 0.77 / 0.80 | crash |
| Twin Rock | six 2 m planks on struts from both banks and the pillar (485), one more strut (530) | 485 / 650 (3) | 0.55 | crash (no pillar struts) |
| Long Wash | a Pratt truss over the plank deck: steel chords and end posts, wooden verticals and diagonals | 1410 / 1700 (2) | 0.83 | crash (one diagonal short) |

Three stars on Long Wash (1360 or less) is the puzzle left for the player. Planks alone fail everywhere
(a straight chain of pins is a mechanism: it sags until it snaps).

What moves (57 of 63 bones, all game bones moved by `scene/game.as`): the cart's body and its two wheel
pairs (attached with `api.transform`, turning in 22.5-degree steps), a pool of 24 planks and 24 girders
(baked 3.2 m long, `placeScaled` shortened along their length and rolled to their angle; a snapped beam's
second half takes a spare), 4 steam puffs, a splash and a dust cloud. Joints, anchors, the drag preview,
the reachable grid points and the stress lines are HUD (`api.line`, `api.rect`) on the art grid.

## What is where

```
art/palette.json, palette.png   Cretaceous-16 with ramps grass, rock, dust, wood, steel, red, water, cream, far, foam; roles
art/assets.md                   the asset list, bones, splats, layout, camera
art/cart/                       the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/cart/                    spec + gate record (and the top-view waiver), make_cart.py -> p1_blockout.txt,
                                p2_form.txt, p3_body.txt, p3_wheel.txt; cart(_body, _wheel).glb, cart.bake.json, gate shots
models/env/                     make_env.py -> terrain, pine, boulder, plank, girder, puff, splash, dust, depot
                                (.txt command files and .glb); places.json (the pines, copied into the bake)
lookdev/                        the turntable bench (no RML): cart.bin
tools/truss_port.py             the solver and cart in Python: verifies the designs and their flawed tries
scene.bake.json                 the composition: terrain, pines, boulders, depot, the game bones, bounds
scene/                          the Rive project: scene.rml (look-at, ortho 10.5, pixelSize 3), game.as (the
                                whole game), the renderer files, splats.bin
goldens/                        cart/, cart@scene/, scene/ (demo_045, demo_640, demo_2780; frame_030)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Rebuild and play (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models from scratch, lookdev/cart.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary
rive scene                                   # play; `rive scene --arg demo=true` to watch the demo
/usr/bin/python3 tools/truss_port.py         # the designs, verified in the Python port
```

Check (gates, goldens, frame audit, playing):

```sh
python3 $K/scripts/golden.py views --hedra models/cart/cart.rmdl -o /tmp/p2 --views front,right,back,top --elevation 6
python3 $K/scripts/golden.py gate --refs art/cart/refs --shots /tmp/p2 --min-iou 0.75          # top: waiver in the spec
python3 $K/scripts/golden.py views --rive lookdev --blob cart -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/cart/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7
L="--arg sunYaw=55 --arg sunPitch=42 --arg keyLight=0.4 --arg highlight=0.85 --arg shadeSteps=1 --arg edgeDepth=0.5"
python3 $K/scripts/golden.py views --rive lookdev --blob cart -o /tmp/w --real-sky ${=L}               # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/w --goldens goldens/cart
python3 $K/scripts/golden.py views --rive lookdev --blob cart -o /tmp/ws --texel 0.077 --size 100 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/ws --goldens goldens/cart@scene
mkdir -p /tmp/pp; for n in 045 640 2780; do rive scene --screenshot=/tmp/pp/demo_$n.png --advance=$((10#$n)) --arg demo=true; done
rive scene --screenshot=/tmp/pp/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots /tmp/pp --goldens goldens/scene
python3 $K/scripts/palette.py frame goldens/scene/demo_2780.png -p art/palette.json --pixel 3
# planks only across Mill Creek: it sags, a plank snaps, the cart splashes in
rive scene --screenshot=/tmp/pp/planks.png --advance=10 --pointer="drag@203,178>281,178:6" --advance=12 \
  --pointer="drag@281,178>358,178:6" --advance=12 --pointer="drag@358,178>436,178:6" --advance=12 \
  --pointer=click@570,369 --advance=150
```

Notes from building it:

- The solver was tuned in the Python port first: with pin joints every load goes to the joints, so a
  straight deck between anchors is a mechanism and fails, a triangle holds, and shallow triangles carry
  large forces (a king post 1 m deep over a 4 m span is near the wood's limit). Constant compliance per
  beam (not per length) and loads only at joints keep it readable. The verdicts did not change between
  12, 24 and 40 substeps; the game uses 16.
- "Planks are road" first meant "the highest plank under the wheel", and the cart climbed a truss's
  diagonal off the deck; each wheel now follows its plank and takes the smoothest one onward.
- At a 10-degree pitch the horizontal faces sat beyond the renderer's 75-degree one-sided cull and the
  road and planks lost their tops; 20 degrees shows them. The girders run 0.55 m behind the planks' plane,
  so their stress lines are projected at their own depth.
- The bench's lighting for the cart's goldens comes from the side the game shows (sun yaw 55): with the
  scene's yaw the bench's right view looks at the shaded side.
- The 3x5 font has no `$`: money is a small drawn coin.
- The Codex sheet was not reviewed by a person yet (`art/cart/sheet.v1.png.json`, `reviewed: false`).
