# Game: Golem Hall (URBEX 16, 16 colours)

**How to play: the pointer is your crosshair: click (or tap) to fire a bolt where it points, and hold
it at the left or right edge of the view (or press and drag there) to turn and face the clay golems
before they reach you.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [URBEX 16](https://lospec.com/palette-list/urbex-16) by Rustocrat,
sixteen colours; it loaded from Lospec, so the spare (`sheltzy32`) was not needed. A roofless ancient
hall at night: grey stone and moss under a purple-black sky, four braziers throwing tan pools of light,
a purple gloom in the great gate, terracotta golems with cyan rune-light, a staff with a cyan orb in
your hand. The collection's only first-person game.

The rules: you stand at the near end of the hall. Golems lumber in, in waves, from the far gate and
from three doorways on each side (the two beside you are out of view: an arrow at the edge of the view
says where one is coming from). A click fires a bolt from the staff's orb towards the crosshair; it
flies at 24 m/s and stops at a golem, a column, a wall or the floor. The charge meter (BOLTS, bottom
left) holds four bolts and refills a quarter of a second after the last shot (a click on an empty
meter only clicks). A big golem takes 3 hits, a small, quicker one (from the second wave) 2; a hit on
the head counts double. A hit cracks it (glowing cracks), squashes and staggers it; the hit before
last knocks its left arm off; the last crumbles it into a pool of clay chunks (10 points, 6 for a
small one, +4 for a head shot; +1 for each other hit; a cleared wave adds 10 x its number). A golem
that reaches you (3.6 m away) raises its fists for about a second (a blinking "!", red arrows if it is
off to the side) and slams the floor: a shockwave costs a heart (at most one every 1.5 s), shakes the
view and reddens its edges. A hit during the wind-up staggers it and starts the wind-up over. Three
hearts; "CRUSHED!" shows the score, the best and the wave; the next click starts a new run in the same
hall.

Turning: the crosshair inside the outer 17 % of the view on either side turns the view, faster the
nearer the edge (up to 58 degrees a second, eased in and out, like a turret: at most 70 degrees either
way). With a mouse it turns while the pointer rests there; on touch it turns while a finger is down
there (press and hold, or drag along the edge). A tap aims and fires at the tapped point; lifting the
finger stops the turn (a released tap does not leave the view spinning). No hover is needed, and
nothing relies on the pointer leaving the tile.

Sound (procedural, `sfx.as`; silent in demo mode): a bolt is a zap with a breathy whoosh, panned with
the crosshair; a hit is a crunch and a thud where it lands (a head shot adds a high bell); a bolt that
strikes stone pops quietly; a lost arm pops and thuds when it lands. Golems' steps are sparse low thuds
(only the left foot, only within 15 m, quieter far away, lower for big golems) panned by where they
walk; a golem stepping out of a doorway thuds. A wind-up is a low whoosh and a rising run of ticks; the
slam is a low explosion and a thud, then a hurt crunch if it cost a heart. A crumble is a burst, four
falling thuds of chunks and a two-note chime (higher after a head shot); chunks that land tick. Each wave
opens with a low whoosh and a three-bell horn that climbs a step per wave; a cleared wave plays the
power-up; a full meter blips; the game over is the losing jingle over two low bells.

Demo mode (`--arg demo=true`, or the `Sample` view model's `demo`): it opens with two golems already in
the hall, one 10 m ahead, and fires within the first second. It aims at the golem winding up (else the
nearest), leads it by the bolt's flight time with a hand's speed and a hand's error (a few pixels,
sometimes a wild one), lets far golems come (no shots past 15 m), keeps a bolt in reserve unless a
golem is close, and turns by pushing its crosshair into the edge when a golem is out of view, so the
golems from the side doorways get slams in: it loses in wave 2 or 3, after 45 to 75 s, and restarts two
seconds after "CRUSHED!". When demo turns off, a fresh run starts.

What moves (54 of 63 bones, all game bones moved by `scene/game.as`): 5 golems (body, crack overlay,
two arms, two legs each: 30), 4 bolts, 12 clay chunks, 3 sparks, 4 brazier flames, the staff (placed in
the camera's frame every update: lower right, half-way towards the crosshair, a recoil on each shot).
98 281 splats.

```
art/palette.json, palette.png   URBEX 16 with ramps stone, clay, rune, fire, moss, cloth, ember, glint; roles
art/assets.md                   the asset list, bones, splats, layout, camera and texels
art/golem/                      the hero's Codex brief, sheet (v1), record, cut views (refs/),
                                gate_palette.json (the hero's own ramps, for the colour gate)
models/golem/                   make_golem.py -> p1_blockout.txt, p2_form.txt, p3_<part>.txt; spec + gate
                                record (waiver), bake file, gate shots, golem(_body, _arml, _armr, _legl, _legr).glb
models/env/                     make_env.py -> hall, pillar, broken, brazier, flame, banner, rubble, bolt,
                                crack, chunk, spark, staff (.txt command files and .glb), textures/floor.png
                                (flagstones), textures/halo.png (the braziers' pool stipple)
lookdev/                        the turntable bench (no RML): golem.bin
scene.bake.json                 the composition: instances, game bones ("bone", "copies"), bounds (the whole hall)
scene/                          the Rive project: scene.rml (perspective look-at, fov 68, eye at 1.6 m,
                                pixelSize 2, no fog), game.as (the whole game), the renderer files, splats.bin
goldens/                        golem/ (framed), golem@scene/ (texel 0.054: a golem 8 m away), scene/
                                (demo_040, demo_240, demo_2400 in demo mode; frame_030: the hint before the first click)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Rebuild and play (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models from scratch, lookdev/golem.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary
rive scene                                   # play; `rive scene --arg demo=true` to watch the demo
```

Check (gates, goldens, frame audit, a run left alone is lost, touch, the hand-over):

```sh
python3 $K/scripts/golden.py views --hedra models/golem/golem.rmdl -o /tmp/p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/golem/refs --shots /tmp/p2 -p art/golem/gate_palette.json --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob golem -o /tmp/alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/golem/refs --shots /tmp/alb -p art/golem/gate_palette.json --min-iou 0.7   # right: waiver in the spec
L="--arg sunYaw=-25 --arg sunPitch=52 --arg keyLight=0.25 --arg highlight=0.85 --arg shadeSteps=1"
python3 $K/scripts/golden.py views --rive lookdev --blob golem -o /tmp/g --real-sky ${=L}            # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/g --goldens goldens/golem
python3 $K/scripts/golden.py views --rive lookdev --blob golem -o /tmp/gs --texel 0.054 --size 200 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/gs --goldens goldens/golem@scene
mkdir -p /tmp/gh; for n in 040 240 2400; do rive scene --screenshot=/tmp/gh/demo_$n.png --advance=${n#0} --arg demo=true; done
rive scene --screenshot=/tmp/gh/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots /tmp/gh --goldens goldens/scene
python3 $K/scripts/palette.py frame goldens/scene/demo_2400.png -p art/palette.json --pixel 2
rive scene --screenshot=/tmp/lost.png --advance=2 --pointer=click@320,200 --advance=3600     # no defence: CRUSHED!
rive scene --screenshot=/tmp/turn.png --advance=2 --pointer=down@630,200 --advance=60        # a held finger at the edge turns
printf 'data demo=true\nadvance 600\ndata demo=false\nadvance 30\npointer down@320,200\npointer up@320,200\nadvance 30\nscreenshot /tmp/hand.png\nquit\n' | rive scene --commands
rive scene --render-audio=/tmp/play.wav --advance=2 --pointer=click@320,190 --advance=8s       # the sounds (play mode)
```

Notes from building it:

- A first-person camera is a perspective look-at whose eye and target `game.as` writes every update
  (`api.eyeX/Y/Z`, `api.targetX/Y/Z`, the target 1 m along the view). The renderer's near plane is
  `max(0.05, |target - eye| - 2R)`, so a target 1 m ahead keeps it at 5 cm and the far plane at
  `1 + 2R` covers the hall; the bake's `"bounds"` are the whole hall (passages and gate included) so the
  shadow map reaches every column.
- `game.as` keeps its own camera basis from its yaw for aiming, the demo and the HUD (`proj`, `ray`),
  with the renderer's `gridOX/gridOY/gridW/gridH`: the `cam*` fields lag a frame and are empty before the
  first draw. A perspective camera has no snap offset, so the HUD stays on the art grid (100 % solid
  blocks) while the view turns.
- At the first slam distance (2.45 m) the golems were baked at the bake's default spacing (0.1 m: six
  texels there) and came out as a mess of blobs; they are 0.06 m now and stop 3.6 m away (a texel of
  0.024 m), and their buried and downward caps are deleted to pay for it.
- Details painted on the sheet (the rune, the visor, the band, the cracks) stand 6 to 9 cm off the clay:
  closer than a spacing the clay's splats swallowed them into a cyan smear.
- Bayer fog over the flat far wall read as a dotted grid: no fog; the far end stays dark by its
  materials (slate walls, an umber passage, the purple gloom).
- The golems first steered round every column, brazier and pile by repulsion and jammed between the
  broken column and a brazier; they now walk lanes (a doorway straight into the central aisle, then to
  a slot round the player), and the fallen drum lies out of the aisle.
- With only the far doorways the action stayed 10 to 20 m away and the view never had to turn; the
  doorways beside the player (out of view at yaw 0) and slots out to 66 degrees make turning the game.
- The Codex sheet was not reviewed by a person yet (`art/golem/sheet.v1.png.json`, `reviewed: false`).
