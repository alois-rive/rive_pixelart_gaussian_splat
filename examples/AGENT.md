# Examples: notes for agents

Worked examples of the `pixel-splat-scene` skill
(`../.claude/skills/pixel-splat-scene`). The skill is general (any scene, any
game, any camera); everything specific to these examples lives here and in
each example's own folder. Read the skill's SKILL.md first, then this file,
then the example's README.

```
examples/
  AGENT.md        this file
  gallery.png     one frame of every example
  tools/          record_tour.py (the showcase reel)
  dioramas/       the diorama examples below: one floating or framed scene each, orbitable
  games/          36 mini games, one world and one run each, played with the pointer
  gallery/        a Rive project holding every sample's signed .riv in a scrollable grid
```

Commands below run from `examples/`.

## The dioramas (`dioramas/`)

| Folder | Palette (Lospec) | Style choices | Motion | Hero (concept sheet) |
|---|---|---|---|---|
| `rive/` | the Rive brand (greys, Rive Amber, Portal Prism) | perspective, fov 32, a plinth only; the wordmark through a custom shader FX cycle | the letters: cascade, prism sweep, glitch, scan, dissolve | the RIVE wordmark, extruded from the rive-branding kit's paths (no sheet: gated against Rive's own render) |
| `island/` | Fading 16 | ortho, per-splat dither, faded-postcard sky | pines sway; a campfire flickers and its smoke catches the flames' light (unlit caps keyed in step with the fire) | a stone well (sheet v2) |
| `winter/` | Magik16 | ortho, night, moon from the front left, light fog | sails (rigid), a swinging lantern, a seamless snowfall | a windmill (sheet v2) |
| `oasis/` | Parchment and Ink | ortho, sepia, black-based ramps | a skinned camel walking round the pond, skinned palms | a camel (sheet v1, flipped and rotated) |
| `harbour/` | Summers Past-16 | ortho, warm daylight | a bobbing boat, gulls circling and flapping | a fishing boat (sheet v1, flipped and rotated) |
| `candy-carnival/` | PICO-8 | perspective fov 40, thick ink (2), saturated toy look | the carousel turns, horses bob, balloons sway | a carousel |
| `haunted-graveyard/` | Hollow (4 colours) | ortho, big painterly splats (2.2 texels), jitter, heavy fog | a ghost orbiting and bobbing | a crooked crypt |
| `space-outpost/` | Ammo-8 (8 greens) | ortho, high pitch, ink 2, hard bands, Bayer, flat sky | ships arrive, land, wait and leave every 7 s (`scene/game.as`, game bones, jets on their nozzles); the radar dish turns and nods, blinking beacons | a radar dish |
| `autumn-cabin/` | Oil 6 | big painterly splats, jitter 0.4, warm low sun, light fog | rising chimney smoke, falling leaves, swaying maples | a cabin |
| `gameboy-farm/` | Kirokaze Gameboy (4) | pixelSize 4 (160 x 100), Bayer, bandDither 0.6, crisp splats (1.2 texels), fixed camera | a windpump rotor (one turn in 4 s), swaying trees | a barn |
| `onebit-lighthouse/` | 1bit Monitor Glow (2) | 1-bit: light as Bayer dither density (bandDither 1), ramps that repeat a colour, perspective fov 35, pitch 6, fog towards white | the lamp head and its beams turn, a boat bobs | a lighthouse |
| `lava-forge/` | Lava-GB (4) | one value per read (navy sky, purple island, magenta forge, salmon lava), sun 50, shadeSteps 1, no fog | a trip hammer striking sparks, a swinging crucible, bobbing lava blobs, rising embers, a lava fall | a forge |
| `coral-reef/` | BLK AQU4 (4) | underwater: perspective fov 40, aqua fog, flat sky, high sun | skinned kelp, circling fish schools, rising bubbles, the clam opening and closing | a giant clam |

The folders above are under `dioramas/`. Every example's README has its rebuild and check commands; its
`art/assets.md` the asset list; `models/<hero>/<hero>.spec.md` the hero's
spec and gate record (including waivers).

## The games (`games/`)

Each game is a complete sample built with the skill: its own Lospec palette,
models, concept sheet for its hero, goldens, and a `scene/game.as` holding all
of its logic (the skill's `references/games.md`, "The game hook").

What every game is:

- **Tiny and instantly fun**: one verb (click, hold, drag or move the
  pointer), understood in two seconds from a one-line hint, a run of 20 to 90
  seconds, a score, and a best score for the session.
- **One run in one world**: no menus, levels or screens. The world is there
  from the first frame; a run starts on the first click (or at once), ends in
  a game-over line with the score, and the next click starts a new run in
  the same world.
- **Pointer only**: the gallery forwards only the pointer to a tile. No keys.
- **A demo mode** (`api.demo`, `--arg demo=true`): the game plays itself like
  a decent human (some misses, some near-misses), restarts by itself two
  seconds after a game over, and shows action within its first second: the
  showcase video records it from frame 0. When demo turns off (a gallery
  visitor clicks the tile), a fresh run starts.
- **Beautiful**: a small, complete, lit world in the pixel-splat style with
  its palette's mood; the HUD in palette colours on the art grid; motion
  that reads (anticipation, squash, a pop when something is hit).
- **640 x 400**, `pixelSize` 2 to 4, a fixed or gently following camera.
- **Deterministic**: `api.rand()` only, so captures and goldens repeat.

| Folder | Palette (Lospec slug) | Spare | The game |
|---|---|---|---|
| `games/lily-hop/` | `sweetie-16` | `pear36` | a frog hops across lily pads drifting on a pond: click to jump at the right moment |
| `games/sky-stacker/` | `na16` | `pear36` | floors slide over a pagoda: click to drop; the overhang is sliced off; stack as high as you can |
| `games/mole-garden/` | `steam-lords` | `pear36` | moles pop out of a vegetable patch: click them, spare the rabbits, 45 seconds |
| `games/fruit-basket/` | `cc-29` | `urbex-16` | move a cart under an orchard to catch falling fruit, dodge rotten apples, 3 lives |
| `games/cannon-cove/` | `slso8` | `urbex-16` | hold to charge, release to fire a cannonball arc at ships crossing a cove, 10 shots |
| `games/kite-day/` | `twilight-5` | `urbex-16` | hold to lift a kite over a hill, release to dip; collect stars, avoid birds |
| `games/sheep-dog/` | `dawnbringer-16` | `fantasy-24` | the pointer is the dog: herd six fleeing sheep into the pen before the timer ends |
| `games/lantern-river/` | `midnight-ablaze` | `fantasy-24` | click lanterns drifting up over a night river to light them; quick chains score combos |
| `games/skee-ramp/` | `bubblegum-16` | `fantasy-24` | drag and flick a ball up a ramp into scoring rings, 9 balls |
| `games/snowball-run/` | `ice-cream-gb` | `2bit-demichrome` | steer a growing snowball down a slope with the pointer, dodge trees, flatten snowmen |
| `games/moon-lander/` | `nyx8` | `2bit-demichrome` | hold to thrust, land softly on a pad on a small moon; the pad moves after each landing |
| `games/fishing-pier/` | `pollen8` | `2bit-demichrome` | hold to sink the hook, release to reel; deeper fish score more, jellyfish cost a line |
| `games/bee-garden/` | `funkyfuture-8` | `apollo` | guide a bee with the pointer to pollinate flowers before they wilt; a spider guards one |
| `games/knight-dodge/` | `rust-gold-8` | `apollo` | move a knight around a round arena, dodging rolling boulders: survive |
| `games/pancake-flip/` | `vanilla-milkshake` | `apollo` | click pans to flip pancakes when they are golden; burnt ones are strikes |
| `games/mine-cart/` | `en4` | `zughy-32` | click junctions to switch the rails under a rolling mine cart; gems score, dead ends crash |
| `games/orbit-defense/` | `berry-nebula` | `zughy-32` | a tiny planet: click to fire toward the pointer at incoming meteors |
| `games/penguin-slide/` | `mist-gb` | `zughy-32` | click to jump: a penguin belly-slides an endless ice run over holes and seals |
| `games/archery-range/` | `island-joy-16` | `cold-light` | hold to draw, release to shoot targets crossing a meadow; a wind flag; 10 arrows |
| `games/bath-navy/` | `lost-century` | `cold-light` | a rubber-duck turret in a bathtub: click to fire bubbles at toy boats |
| `games/keepy-uppy/` | `journey` | `cold-light` | click the ball to kick it up on a beach; more balls join; none may land |
| `games/dragon-tower/` | `blessing` | `nanner-pancakes` | hold to breathe fire at knights climbing the dragon's tower; the fire must recharge |
| `games/tightrope/` | `dreamscape8` | `nanner-pancakes` | move the pointer to balance a walker crossing a canyon on a rope through gusts |
| `games/firefly-jar/` | `retrocal-8` | `nanner-pancakes` | sweep the pointer through a summer night to catch fireflies; dodge the moths, 60 seconds |
| `games/memory-shrine/` | `citrink` | `zughy-32` | bells at a mountain shrine ring a sequence; click them back in order; each round adds one |
| `games/marble-tilt/` | `woodspark` | `zughy-32` | the pointer tilts a wooden labyrinth: roll the marble past the holes to the goal, round after round |
| `games/air-hockey/` | `slso-clr17` | `fantasy-24` | the pointer is the paddle on a glowing rink: first to 7 against a computer opponent |
| `games/mirror-beam/` | `sunset-red` | `fantasy-24` | click mirrors to turn them and bounce the sunbeam into a desert temple's crystals before the sun sets |
| `games/planet-hop/` | `hept32` | `marshmellow32` | a ship orbits a planet: click to launch along the tangent and get caught by the next planet's pull |
| `games/crane-claw/` | `peachy-pop-16` | `marshmellow32` | move the claw over a toy pile, click to drop it; the grab wobbles; win prizes in 60 seconds |
| `games/peg-drop/` | `pear36` | `sheltzy32` | in a clockwork workshop, move along the top and click to drop coins through a wall of pegs into scoring cups |
| `games/lawn-mower/` | `endesga-16` | `sheltzy32` | steer a mower with the pointer to stripe the whole lawn; miss the gnomes and flower beds, beat the clock |
| `games/night-heist/` | `cyclope6` | `urbex-16` | a cat follows the pointer across moonlit rooftops: grab the fish, stay out of the sweeping searchlights |
| `games/sorting-belt/` | `paper-8` | `urbex-16` | parcels ride a post-office belt: flick each one into the chute of its colour before it falls off the end |
| `games/glow-worm/` | `cold-light` | `rosy-42` | a glowing worm follows the pointer through a dark cave, eating crystals and growing; never cross its own tail |
| `games/frog-choir/` | `eggy-15` | `rosy-42` | frogs on a dawn marsh: click each frog as its beat ring closes; keep the choir in time |

A palette that does not load from Lospec is replaced by the row's spare (each
agent has its own spare); note the change in the game's README.

Building a game: the skill's pipeline (asset list, palette and ramps, a Codex
sheet for the hero and its gates, the other models from the list, the bake,
the scene), plus:

- `scaffold.py games/<g>/scene --palette games/<g>/art/palette.json` gives the
  renderer, `game_api.as` and a blank `game.as`; the game's code is ONLY in
  `game.as`. Moving things are game bones (`"bone"`, `"copies"`), the bake
  has a `"bounds"` play area.
- The game's README says how to play (one line), what is where, the palette,
  and its rebuild and check commands.
- Goldens (`goldens/scene/`): three frames in demo mode named `demo_NNN.png`
  (captured with `--arg demo=true --advance=NNN`), at frames chosen to show
  action, plus `frame_NNN.png`, the hint before the first click (no demo).
  `golden.py check` must pass on a rebuild.
- `palette.py frame` on the demo frames: 100 % solid blocks, 0 off-palette
  (HUD colours come from the palette, so they pass too).
- Try the game: drive it with `--pointer` (`click@x,y`, `down@x,y`,
  `drag@x1,y1>x2,y2`) and `--advance` and look at the captures; a game that
  cannot be won, or lost, is not done.

## Layout of an example

```
dioramas/<example>/
  README.md               what is where, palette, what moves, rebuild and check commands
  art/palette.json(.png)  the palette and its ramps (Lospec + hand-written ramps and roles)
  art/assets.md           the asset list (step 1)
  art/<hero>/             Codex brief(s), sheet(s) with their records, refs/ cut by sheet_cut.py
  art/textures/           generated or drawn textures, fitted and audited
  models/<name>/          hedra command files (p1_blockout.txt, p2_form.txt or one <name>.txt),
                          spec, bake file, gate shots, the GLB
  lookdev/                the turntable bench (no RML): <hero>.bin baked for the gates
  scene.bake.json         the composition
  scene/                  the Rive project: scene.rml (the tuned inputs), the renderer files, splats.bin
  goldens/                approved renders: <hero>/, <hero>@scene/, scene/
  shots_scene/            the latest scene frames (the check renders into here)
```

## The renderer copies

Each `scene/` and `lookdev/` holds a copy of the skill's renderer
(`assets/template/splat.wgsl`, `resolve.wgsl`, `splat_scene.as`). After the
template changes, refresh them and re-check every golden:

```sh
K=../.claude/skills/pixel-splat-scene
for d in {dioramas,games}/*/scene {dioramas,games}/*/lookdev; do cp $K/assets/template/{resolve.wgsl,splat_scene.as,game_api.as} $d/; done
for d in {dioramas,games}/*/scene {dioramas,games}/*/lookdev; do [ "$d" != dioramas/rive/scene ] && cp $K/assets/template/splat.wgsl $d/; done
for s in {dioramas,games}/*/; do s=${s%/}; [ -d $s/goldens/scene ] || continue
  mkdir -p /tmp/chk/$s
  for f in $s/goldens/scene/*.png; do b=$(basename $f .png); n=$(echo $b | sed -E 's/^(frame|demo)_0*//')
    d=(); [[ $b == demo_* ]] && d=(--arg demo=true)
    rive $s/scene --screenshot=/tmp/chk/$s/$b.png --advance=$n "${d[@]}" --quiet; done
  echo "== $s"; python3 $K/scripts/golden.py check --shots /tmp/chk/$s --goldens $s/goldens/scene
done
```

Exceptions and conventions:

- **`dioramas/rive/scene/splat.wgsl` is custom**: its `fxApply` holds the Rive brand
  FX cycle (the template's is an empty hook). Never overwrite it with the
  template's; merge template changes into it by hand.
- **Every diorama sets `orbit` true** in its `scene.rml` (the template leaves
  it off), so the previews can be dragged and zoomed. Games leave it off.
- **`game.as` is the project's own** (the template's is empty; most dioramas
  keep it, `space-outpost` flies its ships with one); `game_api.as` is synced
  with the other renderer files.
- **Every scene binds `demo`** to its `Sample` view model (the template's
  `scene.rml` has it): the gallery switches it per tile.
- A template change that should not change pictures must leave every golden
  at 0.0000 %; one that should is looked at, approved and re-snapped.

## The showcase video

`tools/record_tour.py` records one reel: a single camera turn runs through
every scene (the renderer's shared turntable, `tourRate` / `tourOffset` /
`tourLength`), so all scenes are seen from the same yaw at the same moment;
each hands over to the next with an 8 x 8 Bayer dithered fade while both turn
in step. The turn eases in at the reel's start and out at its end, landing on
the last scene's authored front view. Captions name the scene and palette.
The Rive scene goes last (a scene named twice keeps its last position):

```sh
python3 tools/record_tour.py dioramas/*/scene dioramas/rive/scene -o ../showcase.mp4 --seconds 10 --loops 2 \
  --overlap 1.2 --hold 1.5 --scene-arg dioramas/rive/scene:fxOffset=3.6 --scene-arg dioramas/rive/scene:fxStopAt=10.05
```

The Rive scene's FX cycle is 12 s (cascade 0-1.6, prism sweep to 5, glitch to
7, scan to 10, dissolve to 12). With `--seconds 10`, `fxOffset` 3.6 makes the
cascade land the letters at the moment the camera stops (scene time 10), and
`fxStopAt` holds that clean wordmark through the hold. Change `--seconds`
and these move with it: `fxOffset` = 1.6 − seconds (mod 12)

It records the dioramas with the orbit camera. The games follow the tour, each
played in demo mode from its first frame (`--demo`):

```sh
python3 tools/record_tour.py dioramas/*/scene dioramas/rive/scene -o ../showcase.mp4 --seconds 10 --loops 2 \
  --overlap 1.2 --hold 1.5 --scene-arg dioramas/rive/scene:fxOffset=3.6 --scene-arg dioramas/rive/scene:fxStopAt=10.05 \
  --demo games/*/scene --demo-seconds 8 --music
```

## The gallery

`gallery/` holds every sample's signed `.riv` and shows them as a scrollable grid
(`gallery/README.md`). After any sample changes:

```sh
python3 gallery/build_gallery.py      # re-signs only the samples whose scene/ changed
```

Every scene must keep the `Sample` view model with `demo` bound (the template's `scene.rml`),
or its tile cannot be switched between demo and play.

`--music` scores it with `tools/reel_music.py`: a quiet A-minor chiptune (pad,
sine bass, triangle arpeggio with an echo; a gentle groove under the games)
built on the reel's own clock, so every scene starts a bar and every
transition falls on a downbeat with a soft accent and a riser into it. The
recorder writes `<out>.timeline.json`; `reel_music.py --timeline ... --mux
<video>` re-scores an existing video without recording again.

## Concept sheets awaiting review

Generated sheets are used only after a person's yes (`"reviewed": true` in
the sheet's `.json` record). At the time of writing every sheet in these
examples still says `false`: review them before treating the heroes as final.
Waivers granted where a sheet contradicts itself are recorded in each hero's
spec (`models/<hero>/<hero>.spec.md`).

## Case studies (what the gates caught)

**The well (`island/`), sheet v1.** The gate turned up, in order: roof slabs
scaled after a rotated `add` and tilted the wrong way (right view an X, IoU
0.27); hedra's grey default material vanishing into the sheet's grey (views
now over black); the sheet's side views drawn from ~7 degrees above (gate at
`--elevation 7`; the rim top had been modelled as height, 8 % too tall); the
sheet's top and right views disagreeing on the roof depth (a waiver); a crank
0.04 m thick at 0.08 m spacing (specks: thickened to 0.07); `uv reset`
applied to the active object only (one slab untextured); holes between thin
discs inked as edges (`fat` 1.0, ink only next to empty pixels); a ridge in
the wrong material (colour drift 0.38).

**Palette changes after concepting.** The island and winter heroes were first
painted in other palettes (Endesga 32, Apollo). After the switch to 16
colours their colour gates failed (0.36-0.54) because the sheets' colours
snapped to the wrong ramps; regenerating the sheets in the final palette
(`sheet.v2`) fixed it and needed one geometry change each.

**The Rive wordmark (`rive/`).** Thin positive strokes bake fatter (each disc
reaches a radius past its face): the letters are shrunk 0.045 m before
baking (`make_wordmark.py --shrink`) and gated against the kit's Wordmark
rendered by Rive (IoU 0.83, aspect drift 0.02). An earlier square Logo
showed the opposite case: its cut-out R closed up until the faces were
eroded around it.

**Seamless particle fields (`winter/`, `autumn-cabin/`).** First two
identical fields stacked one loop height apart: on these floating islands the
lower copy fell past the thin slab into the void. Now a banded column (the
skill's modeling.md): 20 bands of 0.375 m for the snow (22 bones), 40 of
0.225 m for the leaves (50 bones), footprints inside the rims, generated by
`models/env/make_snowfall.py` and `make_leaves.py`.

**Turning with the camera (`onebit-lighthouse/`).** The lamp's beams turned
the same way as the orbiting camera and looked still in captures; they are
keyed 0 to −360 now.

**Small palettes (`haunted-graveyard/`, `gameboy-farm/`, `onebit-lighthouse/`,
`lava-forge/`, `coral-reef/`).** With 2 to 4 colours every material shares
the same steps; Bayer dither with a wide band turns light into dither density.
The 1-bit lighthouse gives its materials different light responses with
ramps that repeat a colour (`pale` = dark, light, light; `tar` = dark, dark,
light) and reaches the later copy with the material's `"step"`; its table is
in `dioramas/onebit-lighthouse/art/assets.md`. Its sea reaches a true perspective
horizon (`horizon` = 0.5 − 0.5 · tan(pitch) / tan(fov / 2), a coarse ring out
to ~90 m).

**Particle loops that cannot hide their wrap (`lava-forge/`).** Embers rising
from a pool on a floating island would show their reset below it: N short
stacked copies, each turned by the golden angle, keep every reset small and
out of step.

**Readability in four colours (`lava-forge/`).** The rock was painted the
sky's navy and a low sun sank the forge to navy on every shaded face: from
two of three angles it vanished. Each read now has its own value, lifted with
the bake's `"step"` (the gated forge model unchanged), with a higher sun and
`shadeSteps` 1.

**Thin points and proud details (`gameboy-farm/`).** The barn's pointed eaves
eroded under the splats (splat aspect drift 0.108) until thickened and
extended; a door frame 3 cm proud of the wall smeared into noise and became
a painted texture on the wall instead.

## Rules for agents working here

- Never publish (`rive --publish`, `rive push`): the gallery's build signs
  every sample at once.
- New examples of another kind (a game level, a side-scroller, a character
  sheet) go in their own folder beside `dioramas/`, with the same layout.
- Touch only the example you were asked about; never edit the skill from
  an example task (report what the skill should change instead).
- `/usr/bin/python3` has NumPy and Pillow. In zsh, never `rm -f x.rmdl*` or
  `rm -f dir/*.png` on a maybe-empty match; never a relative `rm -rf` after a
  `cd`: use absolute paths.
- Rebuild models from their command files; never patch a saved `.rmdl`.
- Keep a golden change only after looking at it.
