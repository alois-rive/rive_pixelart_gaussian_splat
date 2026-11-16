# Game: Gem Loupe (Galaxy Flame, 16 colours)

**How to play:** swap two neighbouring gems on the velvet tray to line up three or more of a cut;
25 moves to reach the stars.

**Touch:** tap a gem, then tap a neighbour; or put a finger on a gem and swipe towards the neighbour
(6 art pixels is enough). Nothing needs hovering: the loupe follows the finger only while it is down and
stays on the selected gem. Cells are 16 art pixels wide and 15 tall, about 26 screen points on a phone
tile at 0.55 scale. The same holds for the mouse (click-click or drag).

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Galaxy Flame](https://lospec.com/palette-list/galaxy-flame) by Rhoq,
16 colours in 15 ramps (velvet, wood, brass, sapphire, jade, amber, garnet, pearl, steel, wax, paper and
the unlit flame, spark, glint, ink). It loaded from Lospec, so the spare (`lost-century-24`) was not
needed. A jeweller's bench at night: dark planks, a velvet tray of 7 x 7 cells in a wood frame with brass
corners, a candle in a brass dish, a ring mandrel, tweezers, and an order card where the score is kept.
The cursor is a jeweller's hand loupe that hovers over the gem you touch. Orthographic, yaw 0, pitch 66
(the board from above at a slight angle), `orthoHeight` 4.25 m (texel 0.03125 m: a cell is exactly 16
art pixels wide), `pixelSize` 3, light from the candle's side (sun yaw -55, pitch 48), per-splat dither,
ink 1, `shadeSteps` 1.

## Rules

- The tray starts full and without matches, and always has a move. Swap two neighbours (tap one, then
  the other; or swipe). A swap that lines up nothing slides back with a bump and costs no move.
- Three or more of a cut in a row or a column clear with a sparkle; the gems above slide down and new
  ones rise through the velvet at the top of each column and slide into place. New matches clear by
  themselves: a cascade. Each cleared gem scores 10 x the cascade step (1, 2, 3 ...).
- If no move is left, the tray reshuffles itself (NO MOVES: RESHUFFLE; specials stay where they are).
- 25 moves. Stars at 2 500, 4 000 and 5 500. When the moves are spent and the tray settles, a panel
  shows the stars, the score and the session's best (NEW BEST!); the next tap deals a new tray. A run
  takes 40 to 80 seconds.

The cuts: sapphire (round, blue), jade (square, olive), amber (triangle, gold), garnet (marquise,
brown), pearl (cream ball). The ramps are close in hue in this palette, so every colour also has its
own silhouette.

### Special gems (the game's own)

| Made by | Piece | Looks like | Does |
|---|---|---|---|
| four in a line | **Baguette** | a dark rail across the gem with two gold tips, along the line it was made in | when it clears: the whole row (horizontal four) or column (vertical four) |
| an L or a T (a row and a column meeting) | **Cluster** | four gold claws at the gem's corners | when it clears: a 3 x 3 burst |
| five in a line | **Brilliant** | a turning gold star (the drum's sixth cut, unlit) | swap it with any gem: every gem of that cut goes. Hit by a blast: the most common cut goes |
| two specials swapped | **Cross Cut** (two baguettes), **Big Cluster** (two clusters, 5 x 5), **Setting Cut** (a baguette and a cluster: three rows and three columns), **Royal Flush** (two brilliants: the whole tray) | | at once, no match needed |

Specials score 60 (baguette), 80 (cluster), 150 (brilliant) when made; a special caught in a blast
fires too (chains run in waves a few hundredths of a second apart).

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the tray rises row by row from frame 0
the loupe leaves the bench at 0.7 s and the first swap lands at 1.2 s. The demo player looks at every valid swap, values what it
clears and makes (specials, using a special, a little extra low on the board for cascades), takes the
best about 60 % of the time and one of the next three otherwise, and 7 % of the time tries a swap that
does nothing (it bounces back). It moves the loupe to the gem, holds it, then swaps, at a person's pace
(0.45 to 0.95 s of thought). Its trays score 2 800 to 6 600 (1 to 3 stars, most often 2; nine trays measured) in about 65 s; it deals a
new tray 2.4 s after the end panel. When demo is switched off, a fresh tray is dealt with the hint.

**Sound** (procedural, `api.sound` / `api.note`; silent in demo; never chosen by `api.rand`): a soft
click picks a gem; a swap is a quick high whoosh; a swap that does nothing bumps (a high thud) and
clicks back. Every clearing step rings a bell on C major pentatonic that climbs with the cascade (C, D,
E, G, A, C ...) with a plucked octave above it; two or three colours at once add a third and a fifth,
and a pop goes with the sparkle. Making a baguette or a cluster plays a rising power-up (higher for the
baguette); forging a brilliant a four-bell arpeggio. A baguette fires with a zap (lower for a column), a
cluster with a small high burst, a brilliant with a high zap and falling bells. Gems landing tick softly
(one tick a frame at most, 50 ms apart, a little higher when many land). The last three moves blip.
The end: no star, a falling sting; one star, three bells; two, four; three stars, a win chord and a
rising six-bell run. A reshuffle whooshes and three notes fall; a new tray whooshes up a fifth.

## How the board is made of bones (59 of 63)

A 7 x 7 board needs 49 gems, each able to be any of six cuts. Every cell has one game bone, a **drum**:
the six cuts sit on a ring 0.78 m round a horizontal axis under the velvet, 60 degrees apart, and the game
turns the drum so the cut it needs stands on the cloth; the other five stay inside the bench, out of
sight. So refills are truly random, and a special needs no extra piece except its mark (5 baguette
rails, 3 cluster claws); the brilliant is the drum's sixth cut. A drum never rises above the velvet: it
slides (swaps, falls) and sinks or rises through the cloth (a gem pops and sinks when cleared, a new one
rises at the top of its column, a brilliant is forged by sinking, turning and rising). The loupe and
the candle flame are the last two bones. Sparkles, beams, score pops and words are HUD. The reasoning
and the other options weighed are in `art/assets.md`.

## What is where

```
art/palette.json, palette.png   Galaxy Flame with its 15 ramps and roles
art/assets.md                   the asset list, the bone plan (drums), layout
art/loupe/                      the hero's Codex brief, sheet (v1) and record, cut views (refs/)
models/loupe/                   spec + gate record, p1_blockout.txt, p2_form.txt, loupe.bake.json, gate shots, loupe.glb
models/env/                     make_env.py writes bench, tray, drum (the six cuts), band, claws, candle, flame,
                                mandrel, tweezers, card .txt (hedra command files) and textures/ (planks, velvet);
                                their GLBs
lookdev/                        the turntable bench (no RML): loupe.bin
scene.bake.json                 the composition: bench, tray, card, props (static), game bones (flame, loupe,
                                gem0-48, band0-4, claw0-2), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        loupe (framed), loupe@scene (at the scene's texel), scene (demo_1060: a baguette
                                made in a cascade, demo_3990: the end panel with three stars, demo_7936: a
                                brilliant firing, frame_060: the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 59 of 63. Splats: 93 695 in the scene blob (the 49 drums 64 000 of them).

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the loupe, lookdev/loupe.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/loupe/loupe.rmdl -o /tmp/lp_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/loupe/refs --shots /tmp/lp_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob loupe -o /tmp/lp_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/loupe/refs --shots /tmp/lp_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=-55 --arg sunPitch=48 --arg keyLight=0.42 --arg highlight=0.85 --arg shadeSteps=1)
python3 $K/scripts/golden.py views --rive lookdev --blob loupe -o /tmp/lp --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/lp --goldens goldens/loupe
python3 $K/scripts/golden.py views --rive lookdev --blob loupe -o /tmp/lp_s --texel 0.0272 --size 140 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/lp_s --goldens goldens/loupe@scene
for n in 1060 3990 7936; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_060.png --advance=60
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

(The loupe's top view fails its gates by design: a waiver in `models/loupe/loupe.spec.md`.)

Play it headless. Cell (row r, column c) is at about (147 + 48 c, 63 + 43.9 r) on the 640 x 400
artboard (row 0 is the far edge). On the first tray, cells 37 and 44 (column 2, rows 5 and 6) make a
match and a cascade (180 points); a touch-only sequence (no hover):

```sh
rive scene --screenshot=$PWD/p.png --advance=50 --pointer=down@243,283 --pointer=up@243,283 --advance=5 \
  --pointer=down@243,326 --pointer=up@243,326 --advance=150 "--pointer=drag@195,195>243,195:4" --advance=60
```

(the last swipe, cells 22 and 23, makes nothing on the new tray: it bounces back). With `--commands`,
`touch down@x,y` / `touch up@x,y` / `touch drag@x1,y1>x2,y2:4` do the same as a finger. The
demo-to-player hand-over: `printf 'data demo=true\nadvance 400\ndata demo=false\nadvance 60\nscreenshot
/tmp/h.png\nquit\n' | rive scene --commands` shows a fresh tray with the hint.

## Notes from building it

- The board of drums (above) is the one idea the game rests on: 49 bones instead of 294, and the hidden
  cuts cost splats (six per cell) but no bones. The drum radius comes from the rule that the cuts at
  +-60 degrees stay at least 5 cm under the velvet; the bench top sits 4 cm under the velvet and reaches
  0.9 m past the board, where the drums' lower cuts swing.
- `placeDrum` in `game.as` writes the bone matrix itself (scale about the shown cut's base, a turn
  about the drum's axis and a yaw): `api.place` scales about the bake pivot (the drum's axis), which
  would sink the gem into the cloth when it should only squash.
- AssemblyScript: `<f64>(c / N)` with two i32s divides as floats (the cast types the expression), so
  every row came out fractional and the board was a staircase, and picking missed by a row towards the
  bottom. Rows go through an i32 helper (`rowOf`) now.
- Game bones that are never placed did not stay at their baked rest: unplaced pool bones (marks under
  the bench) drew a big dark square over the board. `start()` hides every pool bone.
- The order card was first 2 cm thick: the bench's splats under it won the depth test here and there
  (a disc has one depth) and pocked the card with dark specks. It is 7 cm thick now.
- The loupe is baked at 1.15 so that its ring, closed by about two splat radii, still frames a gem;
  tilted to the camera's pitch and centred on the view ray through the gem, it reads as a round cursor.
- The Codex sheet was not reviewed by a person yet (`art/loupe/sheet.v1.png.json`, `reviewed: false`).
