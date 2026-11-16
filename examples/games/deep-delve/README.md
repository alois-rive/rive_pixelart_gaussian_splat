# Game: Deep Delve (Gamma Boy, 16 colours)

**How to play:** tap or click beside the delver to step one tile that way (up, down, left or right);
walk into monsters to fight them, onto items to take them, onto the glowing stairs to go deeper.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Gamma Boy](https://lospec.com/palette-list/gamma-boy) by Vsigos, 16
muted greens, olives and greys in 15 ramps (stone, deep, wood, brass, moss, cloak, rust, gloom, bone, and
the unlit flame, rune, acid, spark, ember, glow); re-skinned from Apollo (46 colours) to a moody, earthy
handheld look, the bright limes kept for light, magic, items and the delver's highlights. A small
roguelike on floating stone platforms joined by plank bridges over a black abyss: the platforms rise
out of the dark as the delver's light reaches them. Orthographic, yaw 0, pitch 52, `orthoHeight` 7.6 m,
`pixelSize` 3 (texel 0.056 m, a tile 18 art pixels), the camera following the delver by whole art
pixels; one high sun, per-splat dither, ink 1, a flat green-black sky (`#192119`): the abyss.

## Rules

- **Moving.** A press steps the delver ONE tile towards the pressed point (the dominant axis: up,
  down, left or right). Holding keeps stepping that way every 0.24 s; the hold stops when a monster
  comes into sight or hits you (release and press again). A press on the delver himself waits a turn.
  A glowing lime outline with a chevron marks the tile a press would step to; pale corners mark a
  monster a press would attack (or shoot, with the sling).
- **Energy turns.** Everyone gains energy every tick at their speed and acts at 100. A step costs 100,
  a blow costs the weapon's weight (dagger 60, sword 100, axe 150), a sling shot 100, wielding,
  drinking or reading 50. The world runs only while the delver waits for energy; then it stops for
  you. Each group of monster actions plays in tick order, so the fast ones visibly move more often:
  the **flitter** (speed 200) acts twice per step, the **shellback** (speed 50) every other step, the
  spitter (80) and the ooze (70) now and then skip one. A small pale bar under each monster's life bar
  shows its energy filling; yours sits under your HP.
- **Monsters.** Skitters come in packs of three or four (weak, speed 100). Flitters are fast and
  erratic (half their moves are random flutters). Shellbacks are slow, armoured (1) and hit for 3 to 6.
  Spitters spit poison acid down a row or a column from 2 to 4 tiles (poison: 1 HP a turn for 4 turns)
  and back away when you close in. Oozes split in two when struck (each half at 0.72 scale). Monsters
  outside the light (5.6 tiles) are unseen; they wake when they are within six steps of you.
- **Items.** Gold piles; mending potions (lime: heal 60 % and cure poison), haste potions (khaki: speed
  200 for 24 turns); blink scrolls (jump to the tile within 7 steps farthest from every monster), sight
  scrolls (every platform, bridge, item and the stairs rise at once); chests (a sword, an axe, a sling,
  leather armour 1 or mail 2, by depth; gold when it is something you already have). The pack has nine
  slots, one per kind of thing, along the bottom: tap a weapon to wield it (the wielded weapon and worn
  armour are framed in khaki), a potion to drink it, a scroll to read it. Hovering a slot with a mouse
  names it; tapping armour names it.
- **Levels.** Each depth is a new layout from the run's seed: five or six of the six platforms shuffled
  over a 3 x 2 grid, turned, joined by a random spanning tree of straight bridges plus a few loops,
  braziers on some inner corners, the stairs in the platform farthest from the start. Deeper: more
  kinds, more of them, +33 % life and +3/4 damage per depth. Kills give experience; a level-up adds
  5 HP and heals 8. You also heal 1 HP every 12 turns.
- **Death** ends the run: YOU FELL ON DEPTH N, what killed you, gold, kills, level and the session's
  best (deepest, then richest). The next press starts a new run with a new seed. Runs last 2 to 5
  minutes; the demo dies on depths 5 to 7 after 2 to 3 minutes.

**Touch.** Everything is a press: on a phone a tap steps towards the tapped side of the delver (or
attacks, shoots, waits), a held finger keeps walking and the direction follows the finger while it
drags; the step marker shows under the finger while it is down (with a mouse, also on hover). No
control needs hovering, a pointer exit or a key. The inventory slots are 16 art pixels square, the map
tiles 18 x 14; game over takes a tap anywhere.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): every depth 1 puts a flitter in the light
of the start platform, so the demo is fighting within its first second. The demo player drinks mending
when low (or poisoned), reads blink when cornered, drinks haste against a shellback or two foes, reads
sight scrolls, wields its best melee weapon and switches to the sling for monsters in line; then it
fights adjacent monsters (or flees when low with nothing to drink), walks to nearby monsters and seen
items, to unseen platforms and finally the stairs, misstepping now and then. It restarts 2.1 s after a
death. When demo is switched off, a fresh run starts at once.

**Sound** (`sfx.as` presets, silent in demo; never chosen by `api.rand()`): soft footsteps on every
other step (a tick on stone, a wooden click on the bridges); a swing whoosh and a weapon-own hit (the
dagger a light high hit and a click, the sword a hit and a ring, the axe a heavy thud), a sling's pew
and a pop on the target; each monster its voice (skitters chitter, flitters zap, shellbacks thud as
they walk and boom when they hit, spitters splash and pop, oozes slosh and burst when they split); a
low hurt hit; a pop and a rising note for each kill; a blip when a new kind comes into sight; a coin
for gold, a click and a power-up for a chest, a blip and a note for a potion or scroll; mending a
power-up and a splash, haste a fast rising arpeggio and a zap, blink a whoosh and a zap, sight a bell
arpeggio; the stairs a whoosh, a descending run and a low bell, a thud on landing; a level-up a
fanfare and an arpeggio; death a falling sting and two low bells, then an arpeggio for a new best.

## What is where

```
art/palette.json, palette.png   Gamma Boy with 15 ramps and roles (the abyss is sky_top / void, #192119)
art/assets.md                   the asset list, the level-pieces plan and the bone budget
art/hero/                       the delver's Codex briefs, sheets v1 (Apollo) and v2 (Gamma Boy, the
                                same design recoloured) with their records, cut views of v2 (refs/)
models/hero/                    spec + gate record, p1_blockout.txt, p2_form.txt (the mesh gate's),
                                p3_splat_fit.txt (the bake's), hero.bake.json, gate shots, hero.glb
models/env/                     make_env.py writes the hedra command files of every other piece (six room
                                platforms and their floor textures, bridge, stairs, brazier and its
                                pool of light (textures/halo.png), five
                                monsters, chest, potions, scroll, gold, four weapons, stone, spit, spark,
                                two markers); their GLBs
lookdev/                        the turntable bench (no RML): hero.bin
scene.bake.json                 the composition: game bones and pools (59), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        hero (framed), hero@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

Game bones: 59 of 63. Splats: 65 536 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the delver (p1-p3), lookdev, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
(cd models/hero && rm -f hero.rmdl && hedra model --text hero.rmdl run p1_blockout.txt && hedra model --text hero.rmdl run p2_form.txt)
python3 $K/scripts/golden.py views --hedra models/hero/hero.rmdl -o /tmp/dd_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/hero/refs --shots /tmp/dd_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob hero -o /tmp/dd_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/hero/refs --shots /tmp/dd_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=-35 --arg sunPitch=58 --arg keyLight=0.42 --arg highlight=0.9 --arg shadeSteps=1)
python3 $K/scripts/golden.py views --rive lookdev --blob hero -o /tmp/dd_h --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/dd_h --goldens goldens/hero
python3 $K/scripts/golden.py views --rive lookdev --blob hero -o /tmp/dd_hs --texel 0.0559 --size 300 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/dd_hs --goldens goldens/hero@scene
for n in 45 2000 2600; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

`demo_045` is the first fight (the flitter at the start), `demo_2000` a shellback fight on depth 2,
`demo_2600` a level-up on depth 3, `frame_030` the hint before the first step.

Play it headless with touch-style input only (presses, no bare moves): `rive scene
--screenshot=$PWD/p.png --advance=20 --pointer=down@380,200 --pointer=up@380,200 --advance=30` steps
right; `--advance=20 --pointer=down@380,160 --advance=16` shows the marker under a held finger. The
hand-over from demo to a player, with `--commands`: `data demo=true`, `advance 240`, `data demo=false`,
`advance 30` (a fresh run on depth 1 with the hint).

## Notes from building it

- **A level without a bone per tile.** Rooms are six baked platforms of fixed sizes (shuffled, turned)
  rather than one platform scaled: a scaled floor would squash the one-stone-per-tile texture off the
  grid. Bridges are one 8-tile strip whose spare length hides under the platforms 0.15 m below their
  floors; a level is 6 + 7 bones however it is laid out. A generator self-test (a temporary loop in
  `start`, removed) built 60 levels on depths 1 to 8: every one valid on the first try, every floor
  tile, item and the stairs reachable, no strip ever needing the squeeze fallback, 5 to 13 monsters;
  a level takes about 1.4 ms (400 in one frame tripped the 200 ms script limit).
- **Revealing hidden geometry.** A bridge revealed before its far platform showed its hidden spare over
  the void, and bridges rising faster than their platform showed through it: a bridge now reveals its
  two platforms with it and rises 0.1 s behind them on the same curve.
- **Testing.** A closed-loop Python player (`--commands`, reading a temporary `console.log` of the
  state, tapping with down/up and holding with a drag while down, never a bare move) played 14 000
  frames: depth 7, no deaths, 67 kills. It first stalled twice: on a full pack (four weapons, armour and
  four consumables are nine kinds for eight slots: the pack has nine now), and by holding for single
  steps (the camera follows, so a held finger keeps walking: by design). The demo, watched over 30 000
  frames, died on depths 6, 5 and 7. Its taps replayed with `--render-audio` gave 40 s of sound, peak
  0.18.
- The hero sheet's top view is 12 % deeper than its right view; the splat fit splits the difference
  (`models/hero/hero.spec.md`).
- The Codex sheets were not reviewed by a person yet (`art/hero/sheet.v1.png.json`, `sheet.v2.png.json`,
  `reviewed: false`).
- **The Gamma Boy re-skin.** Gamma Boy is 16 colours with almost one hue (greens, olives, a purple-grey,
  one brown, one khaki), so every read is told apart by value first, hue second. Values (OKLab L): the
  abyss 0.24 (`#192119`), the platform walls and root 0.24 to 0.32, the floor 0.39 to 0.42 (dark teal
  `#324b41` flags, a third purple-grey `#4e4b5a`, slate grout, olive and sage moss), a warm-grey kerb
  (`#8c8980`, 0.63) one texel wide round every platform's top so the ledges read against the dark, and
  then everything that matters above the floor: the delver's pale helmet (`#a3ad8b`) with an olive
  cloak that the sun lifts to lime, khaki-winged flitters, grey shellbacks with a moss crown, olive
  spitters under a khaki cap, green oozes, brown skitters with pale eyes; items pale and lime (gold
  `#b3c392` with lime glints, mending lime, haste khaki, chest bands pale), and the lights lime (the
  lamp, the step marker, the stairs' runes, the braziers, sparks, acid). The attack marker is pale.
- A first pass with a mid-value floor (`#6d7270` / `#69835d`) washed the delver's pale helmet into it and
  read grey; the dark floor made the scene moodier and every actor pop. A checkerboard of two hues read
  as a tablecloth: the floor is now mostly teal with a random third of purple-grey flags.
- **Braziers** have a pool of light: sparse sage and olive motes (`textures/halo.png`, alpha-masked,
  unlit, one mote a texel on a staggered grid every third texel). A dense Bayer stipple (golem-hall's)
  merged under 0.06 m splats into a blotch that read as moss; spaced motes stay separate, and the
  flame's stepped turn makes them twinkle. The brazier stands a tile in from a corner, so the 1.4 m pool
  always lies on floor. The flame is a lime cone with a brighter tongue rising out of it.
- The sun, `keyLight`, `highlight`, `shadeSteps`, ink and dither stayed: with this palette `highlight`
  0.85 sits on the floor's N.L (0.848) and dithers it, and the other variants tried (sun from the
  other side, key 0.5) changed little. Fog stays off: depth runs up the screen as much as down into the
  abyss, so it could not dim only the rising platforms.
- The HUD uses one tone per ramp (`tone()` in `game.as`): cream text, warm-grey secondary lines, khaki
  gold and finds, lime depths and mending, grey-green poison, brown blows taken, a lime life bar, khaki
  on rust monster bars, pale energy, slots of dark green in teal frames (khaki when worn or wielded).
