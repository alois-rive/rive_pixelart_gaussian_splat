# Game: Fishing Pier (Pollen8, 8 colours)

**How to play:** hold anywhere to sink the hook, let go to reel it in; a fish that touches the hook
bites, reel it out of the water to land it (deeper fish score more). A jellyfish on the hook snaps
the line: three lines, and the day ends when the sun sets (60 s).

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli 0.167. Palette: [Pollen8](https://lospec.com/palette-list/pollen8) by Conker
(plum, berry, rose, pink, gold, cream, mint, teal), loaded from Lospec (the spare, 2bit-demichrome,
was not needed). A warm afternoon in cross-section: a pink sky over a teal sea split at the water
line (the sky's two roles), a plank pier on long piles, an old fisher in a gold raincoat on an
upturned bucket, a lighthouse islet on the horizon, a gold sun that sets into the sea as the clock,
kelp swaying on a berry seabed. Per-splat dither, ink 1.

The game (`scene/game.as`, all of it): the line hangs from the rod's tip; holding sinks the lure at
2.5 m/s, letting go reels it up at 3.3 m/s. Fish cross at their depth band: small gold ones near the
surface (10), pink ones in the middle (25), big berry ones near the bottom (60). Touching a fish hooks
it; it hangs and thrashes until the lure is reeled out, then flies over the rail into the basket. A
jellyfish touching the lure snaps the line (it flashes, the fish escapes, the lure is gone a moment,
and the hook waits for a fresh press). Best score for the session. Motion: the waves slide in stepped
12 fps beats, the swell behind the other way; jellies pulse in three stepped squash poses; fish
wiggle; the rod bends with a fish on; the fisher breathes, hops on a catch, flinches at a snap;
drops splash where the lure breaks the surface; bubbles rise from two vents and the lure.

Demo mode (`--arg demo=true`, or the `Sample` view model's `demo`): an angler that picks the fish it
can reach before the fish crosses the line (valuable ones first), sinks to its depth at the right
moment, hovers there with taps and reels when it bites; it mostly waits out jellyfish in the line's
path but one choice in seven it does not look. The lure goes in from frame 0; a run is the 60 s day
(or three snaps); it restarts 2 s after the end. When demo turns off, a fresh day waits for the
first press.

```
art/palette.json, palette.png   Pollen8, ramps coat, skin, beard, boot, bucket, wood, sea, weed, sand,
                                fishy, fishp, fishd, jelly, sun, deep
art/assets.md                   the asset list, bones, layout
art/fisher/                     the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/fisher/                  spec + gate record, p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB
models/env/                     make_env.py (writes pier, rod, lure, fish_s/m/l, jelly, waves, swell, seabed,
                                rock, kelp, island, sun, cloud, splash, bubble, seawall), command files, GLBs
lookdev/                        the turntable bench (no RML): fisher.bin
scene.bake.json                 the composition: static pier, seabed, rocks, kelp, island, sea wall; game
                                bones (fisher, rod, lure, fish x9, jelly x3, waves, swell, sun, cloud x2,
                                splash x5, bubble x6), the play-area bounds
scene/                          the Rive project: scene.rml (look-at side view, ortho 9.6 m), game.as
goldens/                        the fisher framed and at the scene's texel; scene/: demo_060, demo_300,
                                demo_960 and frame_030 (the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                             # models from scratch, lookdev/fisher.bin, scene/splats.bin
rive scene --verify && rive scene                      # play it
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/fisher/fisher.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/fisher/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob fisher -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/fisher/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L=(--arg sunYaw=35 --arg sunPitch=40 --arg keyLight=0.4 --arg highlight=0.85 --arg shadeSteps=1)
python3 $K/scripts/golden.py views --rive lookdev --blob fisher -o /tmp/fi --real-sky $L && python3 $K/scripts/golden.py check --shots /tmp/fi --goldens goldens/fisher
python3 $K/scripts/golden.py views --rive lookdev --blob fisher -o /tmp/fis --texel 0.055 --size 120 --real-sky $L && python3 $K/scripts/golden.py check --shots /tmp/fis --goldens goldens/fisher@scene
for n in 060 300 960; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --arg demo=true --advance=$n; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_300.png -p art/palette.json --pixel 3
```

Try it headless: `rive scene --screenshot=$PWD/play.png --advance=5 --pointer=down@320,200 --advance=67
--pointer=up@320,200 --advance=110` and repeat the down/up pair: eleven casts landed six fish (140) and
lost two lines on jellyfish; the day ends at sunset ("THE SUN HAS SET") or at the third snap ("OUT OF
LINE").

Notes from building it:

- The sea is the sky's lower colour, not geometry, so the setting sun first showed through the water:
  an unlit plane 5 m back on a one-colour teal ramp (`deep`) hides it and stays invisible (the ink
  cannot step a one-colour ramp down).
- A baked bubble field (two stacked fields, as in the coral reef) rose on into the sky: here the
  bubbles are a game pool that pops at the surface.
- A long hold could snap three lines on one jellyfish (the lure came back and sank into it again):
  after a snap the hook waits for a fresh press.
- `scale` in hedra after `--rotation` scales world axes: the sea wall first came out 1 m tall.
- The Codex sheet was not reviewed by a person yet (`art/fisher/sheet.v1.png.json`, `reviewed: false`).
