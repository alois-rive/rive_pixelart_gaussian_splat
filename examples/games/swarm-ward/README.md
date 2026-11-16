# Game: Swarm Ward (Rosy 42)

**How to play: tap or click to light the lantern, then lead the lamplighter with the pointer (or a
finger); his lights fight on their own. Gather the wisps, pick an upgrade at every level, and keep
the lantern lit until dawn.**

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Rosy 42](https://lospec.com/palette-list/rosy-42) by
PineappleOnPizza, 42 colours in 18 ramps (loaded from Lospec; the spare `sheltzy32` was not needed).
A haunted moor at night: dark slate-green heath with low heather, turf, tufts, pebbles and
landmarks (standing stones, a dead hawthorn, a peat pool with reeds, a ring of glowing mushrooms,
old ward posts with dark lamps). The lamplighter's lantern lights a stippled pool of green round
him. Orthographic, yaw 0, pitch 53.13 degrees, `orthoHeight` 6.8 m, `pixelSize` 3 (texel 0.05 m);
a low moon from the front left (yaw -40, pitch 38), `shadeSteps` 1, per-splat dither, ink 1. At
dawn the sun climbs and swings round to the right, and the whole moor dithers a step brighter.

An original horde-survival design: the hero, the monsters, the weapons, the names and the look are
this sample's own.

## Rules

- **Moving.** The lamplighter walks toward the pointer (2.8 m/s) and stops when he reaches it. The
  camera stays locked on him, so a pointer held off to one side keeps him walking that way, like a
  stick. He never attacks by hand.
- **The night.** 3:00 on the clock to dawn. Swarms come from every side and keep coming: 9 foe
  slots at first, 26 by the last minute. Every 30 s the mist thickens: a ring of swarms closes in
  and the spawning doubles for 9 s. A cairn brute wakes at 0:55, 1:52 and 2:30. Foes left more than
  11.5 m behind are sent back ahead of him, so the swarm can't be outrun. Foes get tougher over the
  night (HP x1 to x2.6) and a little faster.
- **Hurting.** Touching a foe hurts (moths 4, shamblers 7, hounds 6, brutes 15, the king 16; his
  ground slam 18). He has 100 HP, blinks safe for 0.85 s after a hit, and the lantern's warmth
  heals 0.5 HP a second. At 0 HP the lantern goes out: THE LANTERN WENT OUT, with the time, kills,
  level and the night's best.
- **XP.** A defeated foe leaves a wisp of light (a swarm 4, a shambler or hound 3, a brute 30). Wisps
  inside the pickup reach (1.1 m) fly to him. Wisps that lie more than 7.5 m away or for over 7 s are
  called home by the lantern. Every level pauses the night and deals three cards; tap or click one.
  Level n needs 5 + 6.5 (n-1) + 0.9 (n-1)^2 XP. A run reaches about level 22 to 25.
- **Dawn.** At 0:00 the Mire King rises in front of him (1 700 HP, a slam every few seconds,
  telegraphed by a red ring on the ground). Beat it and the sun is up: every creature bursts, and
  the screen shows DAWN! with the kills and the level. After 45 s the sun starts burning the king
  (3 % of its HP a second), so a night always ends. The next tap or click starts a new night on the
  same moor.
- **Best**: a dawn beats any night that ended in the dark; between dawns the most kills win, between
  dark endings the longest time.

## Weapons and upgrades

Every weapon fires on its own. A run starts with Flint Sparks. Cards offer weapons you hold (most
often), new weapons, and passives. Once everything is maxed, Warm Tea heals 35.

| Card | What it does | Levels |
|---|---|---|
| FLINT SPARKS | sparks fly at the nearest foes (10 m/s) | 1-5: 1, 2, 2, 3, 3 sparks a volley; pierce 0, 0, 1, 1, 2; damage 10 to 18; every 1.0 s to 0.62 s |
| WARD MOTES | motes of lantern light orbit him and strike what they touch | 1, 2, 3 motes, then a wider orbit (1.25 to 1.85 m), faster; damage 7 to 15 |
| LAMP PULSE | a ring of light spreads from him and shoves foes back | radius 2.2 to 3.0 m, damage 12 to 27, every 3.2 s to 1.9 s |
| CINDER TRAIL | burning cinders drop behind him as he walks | life 1.9 to 2.8 s, radius 0.45 to 0.7 m, 5 to 13 damage a 0.4 s tick |
| STORM WICK | lightning strikes random foes in view (and splashes) | 1, 2, 2, 3, 3 bolts; damage 26 to 55; every 2.6 s to 1.5 s |
| SWIFT BOOTS | +12 % speed | 4 |
| LONG HOOK | +45 % pickup reach | 4 |
| TIN COAT | -12 % damage taken | 4 |
| OIL FLASK | +25 max HP, heal 25 | 3 |
| BRIGHT WICK | -8 % cooldowns, +8 % area | 3 |

The foes: **murk moths** (pale, pink-eyed, in swarms of five that weave as they fly at him), **peat
shamblers** (slow, mossy lumps of peat), **barrow hounds** (skull-masked; they lunge when close,
then pant), **cairn brutes** (elite: stacked moor stones with glowing runes; they drop a lamp-oil
flask that heals 30), and **the Mire King** (the dawn boss: a peat giant crowned with pale antlers).

## Touch

The game is played with the pointer alone, and on a phone with one finger. On touch the pointer
moves only while a finger is down:
- **Dragging** steers exactly like a mouse: he walks toward the finger.
- **Lifting** marks the spot under the finger: he walks there and stops. Nothing needs hovering.
- **Cards** are 64 x 64 art pixels: a tap picks one. After a pick he stands still until the
  pointer moves again, so a tapped card never sends him off toward where it was.
- The first tap starts the night; a tap after the end starts the next one.

Tested headless with a touch-only closed-loop player (`touch down`, `touch move` while down,
`touch up`, `touch tap`; never a bare move). It steered by drags from what the game showed and
tapped cards, and it reached DAWN at 3:17, level 24, the Mire King beaten. A naive one (a finger
circling the centre, cards picked blindly) went out at 1:10.

## The bone budget: a crowd on 61 bones

Every moving or appearing thing is a pooled game bone (`scene.bake.json`), recycled the instant it
is free:

| Pool | Bones | |
|---|---|---|
| hero, ground | 2 | the ground is a uniform 12 x 10 m plane whose texture carries the lantern's pool; it rides with the snapped camera |
| decor | 4 | 12 x 12 m patches leapfrogging on a 2 x 2 grid: an endless moor, never re-sampled |
| moth swarms | 12 | **packs**: one bone carries five moths baked in a cluster, flapping (a stepped squash at 10 fps), wobbling and bobbing as one; 60 moths |
| shamblers, hounds | 8 + 6 | |
| brutes, king | 2 + 1 | |
| motes, ring, sparks, cinders | 3 + 1 + 6 + 5 | the ring is baked at its largest radius (3 m) and scaled up from 0.05 as it spreads |
| wisps, flask | 10 + 1 | wisps are baked at their largest size and scaled to 0.55 / 0.75 / 1; a drop with no free bone **merges** into the nearest wisp, and lying wisps closer than 1 m merge every half second |

Up to 77 creatures stand on 29 foe bones. Everything else that flashes costs no bone: hit sparks,
death bursts, damage numbers, the storm-wick lightning, the boss's slam ring and its warning,
arrows to brutes off screen, the hurt flash and the cards are all HUD, on the art grid, in palette
colours. 61 of 63 bones, 62 821 splats. Per frame: simple steering, plain pairwise separation (at
most 406 pairs, fewer tests than a grid would cost at n = 29) and weapon-vs-foe circles. A whole
headless 3-minute night runs in about 5 s (14 000 frames, about 0.36 ms a frame including the
render).

## Demo

`--arg demo=true`, or the gallery's `Sample.demo`. The night starts at once, with seven swarms and
three shamblers already closing in from every side and the first sparks flying in the first tenth of
a second. The demo player:
- re-thinks 5 to 10 times a second;
- scores 16 headings by the danger at two points along each (heavier foes count more) and kites in
  circles (it prefers its last heading bent one way, and now and then flips the turn);
- is drawn to wisps, and to the flask when hurt;
- reads each card hand for 0.75 to 1.3 s (its choice highlighted), then picks sensibly: weapons
  it holds, then new ones (it likes motes and the pulse), armour and oil when hurt;
- now and then gets careless and walks straight for the wisps, more often late in the night.

It sometimes dies and sometimes wins. Seven demo nights in a row: dark at 2:23, 2:37 (twice) and
3:06; dawn three times (3:13 to 3:23). Two seconds after the end it starts the next night. When demo
turns off, the moor resets and a fresh night waits for the first tap, under the hint.

## Sound

Procedural, `sfx.as`, panned by where things happen, silent in demo mode, never decided by
`api.rand()`. Weapon ticks are the busiest sound and share one gate (at most one every 90 ms
across all weapons): a soft high pew for each spark volley, a tick for a mote strike that steps
through four pitches. The pulse whooshes, lightning zaps once a volley, and a brute's stomps thud
softly when on screen. Foe pops are gated to one per 50 ms, pitched by kind (moths high, brutes
low); brutes and the king burst instead. Wisp pickups chime a semitone higher for each wisp of a
streak (an octave at most), and the streak breaks after 0.7 s or a hit. A level-up is a rising
C-E-G-C with three card blips; a pick is a power-up and a click. A hit is a crunch and a thud.
Every 30 s the wave bell tolls (a fifth); a brute's arrival is a minor bell sting and a thud; the
king's rise is a low boom and a falling bell figure. Dawn is a fanfare with a five-bell climb; the
lantern going out is the lose tune and two low bells, and a new best adds a high bell. A
17-second headless play-mode render peaks at 0.23 with an RMS of 0.02; 69 % of its 50 ms windows
are near silent, so the mix keeps room around the fights.

## What is where

```
art/palette.json, palette.png   Rosy 42 with 18 ramps (moor, grass, heather, stone, slate, coat, skin, wood, ...) and roles
art/assets.md                   the bone budget, the asset list, ramps, layout
art/lamplighter/                the hero's Codex brief, sheet (v1) and record, cut views (refs/), gate_palette.json
models/lamplighter/             make_lamplighter.py -> p1_blockout.txt, p2_form.txt; spec + gate record;
                                lamplighter.bake.json (the bench); gate shots; lamplighter.glb
models/env/                     make_models.py writes every other model's hedra command file and ground.png
                                (the lantern's pool); their GLBs
lookdev/                        the turntable bench (no RML): lamplighter.bin
scene.bake.json                 the composition: 61 game bones and pools, material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        lamplighter (framed), lamplighter@scene (the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the lamplighter, lookdev/lamplighter.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/lamplighter/lamplighter.rmdl -o /tmp/l2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/lamplighter/refs --shots /tmp/l2 --min-iou 0.75 --max-aspect-drift 0.08
python3 $K/scripts/golden.py views --rive lookdev --blob lamplighter -o /tmp/la --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/lamplighter/refs --shots /tmp/la -p art/lamplighter/gate_palette.json --min-iou 0.7 --max-aspect-drift 0.08
L=(--arg sunYaw=-40 --arg sunPitch=38 --arg shadeSteps=1 --arg highlight=0.82)
python3 $K/scripts/golden.py views --rive lookdev --blob lamplighter -o /tmp/lg --real-sky --views front,right,back,top,iso $L
python3 $K/scripts/golden.py check --shots /tmp/lg --goldens goldens/lamplighter
python3 $K/scripts/golden.py views --rive lookdev --blob lamplighter -o /tmp/lgs --texel 0.05 --size 120 --real-sky --views front,right,back,top,iso $L
python3 $K/scripts/golden.py check --shots /tmp/lgs --goldens goldens/lamplighter@scene
for n in 090 1200 2600; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --advance=$n --arg demo=true --quiet; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30 --quiet
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

The goldens: `demo_090` (the opening swarm closing in, the first sparks flying), `demo_1200` (a
level-5 card hand, the demo's pick highlighted), `demo_2600` (level 8 with sparks, motes and the
pulse, moths and shamblers all round), `frame_030` (the hint before the first tap).

Try it headless:

```sh
rive scene --screenshot=$PWD/p.png --advance=3 --pointer=click@320,200 --advance=20 --pointer=move@480,200 --advance=120
```

A click starts the night and the move sends him east; a click at (318, 204) picks the middle card
when a hand is open. The hand-over: a `--commands` file with `data demo=true`, `advance 300`,
`data demo=false`, `advance 20` shows the reset moor and the hint. Touch: `touch tap@320,200`,
`touch down@...`, `touch move@...` while down, `touch up@...`.

## Notes from building it

- **Following without shimmer.** The camera target is the hero's position snapped to whole art
  pixels: 0.05 m in x, and 0.0625 m in z (pitch 53.13 has sin 0.8, so 0.05 / 0.8). The hero and the
  ground are placed at that same snapped point, so he stands pixel-still while the moor scrolls under
  him by whole pixels. The logical world wraps its origin by 6 m (120 texels in x, 96 in z), which
  changes no pixel and keeps the placed world inside the bake's bounds.
- **The light pool is a texture, not a disc.** A stippled disc floating over the ground fought with
  the decor's turf, and would have hidden the monsters' feet. Because the ground plane rides with the
  hero, its own texture can hold the pool: the pool needs no bone and fights nothing.
- **Decor never re-samples.** A static periodic ground (bone 0) re-rolls its Poisson splats at every
  origin wrap. Patches that leapfrog off screen keep their splats. Their grid is offset half a cell,
  so a night starts where four patches meet, not on a standing stone.
- **Balance came from headless nights.** A temporary `console.log` every 10 s of the night printed
  the level, kills, HP and active slots. With a 0.6 s spawn gap the screen held 2 to 10 foe slots.
  Spawning in bursts of three fixes that. Wisps left far behind kept absorbing merged drops and
  froze XP at level 12, so stray wisps are now called home. The first demo summed "away + sideways",
  which cancels out when surrounded, and died every night by 1:35. It now scores 16 headings.
- **The hero's sheet** (Codex, `reviewed: false`) paints the hat lighter than the brief asked; the
  model follows the sheet (`models/lamplighter/lamplighter.spec.md`).
