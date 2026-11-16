# Game: lantern river (Midnight Ablaze)

**How to play:** click the dark paper lanterns as they drift up from the river to light them; light them in
quick succession for a chain. Don't let three dark ones escape into the sky.

**Touch:** tap the dark lanterns to light them.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra 0.1.0,
codex-cli. Palette: [Midnight Ablaze](https://lospec.com/palette-list/midnight-ablaze) by Inkpendude (loaded
from Lospec; the spare `fantasy-24` was not needed): seven colours from near-black to coral, one long ramp cut
into five (night, water, earth, paper, glow). A village across a night river under a crescent moon, seen
almost level (orthographic, pitch 12, 8.4 m tall, `pixelSize` 4: 160 x 100 art pixels), moonlight from the
front left, no shadows; windows, the jetty lamp, the moon, the stars and every lit lantern are `unlit` splats.

Rules: lanterns are set afloat on the water (a squash, a stretch) and climb with the wind. A click on a dark
one lights it (it pops and climbs away, its light shining on the water): +10 times the chain. The chain grows
while each light follows the last within 0.9 s, up to x8; a click on empty sky breaks it. A dark lantern that
leaves the top of the sky costs one of three flames (top right). Launches come faster and climb faster over
50 s, sometimes two at once; a run ends when the flames are gone ("THE RIVER WENT DARK", the score and the
longest chain). Before the first click lanterns drift by without cost; the first click starts the run (and
lights what it hits); after a game over the next click starts again on the same river. Best is kept for
the session.

Demo (`--arg demo=true`): a quick, human hand that goes for the lantern closest to escaping (a third of the
time the one nearest its last click, to keep a chain), needs a second to notice a new lantern, waits 0.4-0.85 s
between clicks and aims a few pixels off (some clicks miss and break the chain). A cross marks where it
clicked. It lights the first lantern at 0.75 s, runs about 48 s, and starts again 2 s after the game-over line.

Sound (procedural, `api.sound`; silent in demo): bells on a quiet night. A soft jingle starts a run; a lit
lantern chimes a bell (over a paper pop) that climbs a pentatonic scale with the chain, with an octave chord
at x8; a launch is a low plop on the water; a click on empty sky a dry tick, and a low pluck if it broke a
chain; a dark lantern lost into the sky a gust and a low bell (lower with each flame); the river going dark
a falling tune.

```
art/palette.json, palette.png   Midnight Ablaze with its ramps and roles
art/assets.md                   the asset list, the art grid, the play area
art/lantern/                    the hero's Codex brief, sheet v1 (reviewed: false), record, cut views (refs/)
models/lantern/                 spec + gate record, p1_blockout.txt, p2_form.txt (lantern.glb), p3_bake.txt
                                (lantern_bake.glb, narrowed for the splat spread), p4_lit.txt (lantern_lit.glb),
                                bake file, gate shots
models/env/                     make_env.py (writes every environment command file and the water texture),
                                the command files, textures/water.png, GLBs
lookdev/                        the turntable bench (no RML): lantern.bin
scene.bake.json                 the composition: 68 000 splats, 36 game bones (lantern0-15, lit0-9, shine0-9)
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        lantern (framed), lantern@scene (texel 0.084), scene (demo_045/600/1500, frame_040)
shots_scene/                    the scene frames the goldens were snapped from
build.sh                        rebuilds every model and blob from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models from scratch, lookdev/lantern.bin, scene/splats.bin
rive scene --verify && rive scene            # play it
rive scene --arg demo=true                   # watch the demo
```

Check (gates, goldens, frame audit):

```sh
python3 $K/scripts/golden.py views --hedra models/lantern/lantern.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/lantern/refs --shots /tmp/p2 --min-iou 0.75 --max-aspect-drift 0.08
#   (lantern.rmdl after build.sh holds the narrowed bake solid: replay p1 + p2 only for the form gate)
python3 $K/scripts/golden.py views --rive lookdev --blob lantern -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/lantern/refs --shots /tmp/alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L="--arg sunYaw=-20 --arg sunPitch=35 --arg keyLight=0.3 --arg shadows=0"
python3 $K/scripts/golden.py views --rive lookdev --blob lantern -o /tmp/lan --real-sky ${=L}        # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/lan --goldens goldens/lantern
python3 $K/scripts/golden.py views --rive lookdev --blob lantern -o /tmp/lan_s --texel 0.084 --size 160 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/lan_s --goldens goldens/lantern@scene
for n in 45 600 1500; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_040.png --advance=40
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_600.png -p art/palette.json --pixel 4
# a played run: light two lanterns (a chain), miss once
rive scene --screenshot=$PWD/played.png --advance=40 --pointer=click@480,152 --advance=20 \
  --pointer=click@322,214 --advance=40 --pointer=click@100,60 --advance=6
```

Notes from building it:

- The first framing (7.2 m, target 2.0 m) filled the middle with the far bank and left a strip of sky:
  the view grew to 8.4 m, the target rose, trees and houses shrank. The moon's craters read as a face: it is
  a crescent now (a darker disc in front of a lit one).
- The camera target sits on the art grid: the renderer's texel is `orthoHeight / (rows + 2)` (the two spare
  pixels), so 8.4 / 102, not 8.4 / 100; with the latter the scene sat one screen pixel off the HUD and the
  audit fell to 95 % (the template has since aligned the HUD with the art grid at any offset).
- The chain first had no cap and a 1.2 s window: the demo never broke it (x32, 12 000 points). Now 0.9 s, x8.
- Dark lanterns first showed as #460e2b against a #1f0510 bank: the key light dropped to 0.3 and the moon
  moved to the front left, so their paper keeps its painted #7c183c.
- The Codex sheet was not reviewed by a person yet (`art/lantern/sheet.v1.png.json`, `reviewed: false`).
