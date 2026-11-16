# Game: Kite Day (Twilight 5)

**How to play: hold the pointer to lift the kite, let go to let it dip; catch the stars, dodge the birds.**

A kid flies a kite from a hilltop at dusk. Stars drift in on the wind (one point each); gulls cross
faster, and a gull or the kite's tip touching the knoll costs one of three hearts (the kite blinks
for a moment after a hit). The wind picks up as the run goes on: things come faster and the gulls
come more often, so a run lasts 20 to 60 seconds. One run in one world: the first press starts it
(and lifts), a game over shows the stars caught, the next click flies again; the best score is kept
for the session. Pointer only.

Sound (procedural, `api.sound`; silent in demo): airy and chiming. A start jingle; each press lifts with a
whoosh and the wind blows a soft gust every two seconds, higher as it picks up; a star rings a bell (over a
plucked note) that climbs a pentatonic scale with the streak of stars since the last hit; a gull cries as it
comes in; a hit is a crunch with the gull's squawk (lower with each heart lost), the knoll a thud; the last
heart a falling game-over tune and a soft thud as the kite lands.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Twilight 5](https://lospec.com/palette-list/twilight-5) by Star, five
colours (peach, pink, haze blue, dusk blue, night) as six ramps (hill, kite, glow, bird, wood, cloud):
materials are told apart by value. A side view (orthographic look-at, 10 m tall, `pixelSize` 4: 160 x
100 art pixels), a low dusk sun from the front left, a dusk-blue sky over a dithered pink glow, the
sun half set behind hazy far hills, pink clouds drifting (parallax). The string is drawn by the HUD,
one art pixel wide: taut while you hold, slack when you let go.

What moves (28 of 63 bones, all game bones moved by `scene/game.as`): the kite (lift and sink with
inertia, roll with its speed, a sway, a squash-and-stretch pop on every star, a shake on a hit, a
spin down at game over); its tail, five bows on a verlet chain blown by the wind; six stars (drift,
bob, stepped spin, a swell and a spark burst when caught); four gulls (a stepped 10 fps flap by
squash, a tumble when hit); eight sparks; three clouds; the kid (leans back while the string pulls,
hops on a catch).

Demo mode (`--arg demo=true`, the gallery's `demo`): a pilot steers for the next star, climbs or
dives round the gulls it notices, lets one star in seven go, misses one gull in five and re-plans
only every 0.15 s, so it catches about a star a second and loses a heart now and then; a run lasts
about 40 s, and it flies again two seconds after a game over. Stars and a gull are already in the air
on frame 0, and the first star is caught at about 0.6 s. When demo turns off, a fresh run starts.

```
art/palette.json, palette.png   Twilight 5 with its ramps and roles (sky #333f58 over #ee8695, void #292831)
art/assets.md                   the asset list (sizes, ramps, bones, motion)
art/kite/                       the hero's Codex brief, sheet (v1), record, cut views (refs/)
models/kite/                    spec + gate record (waivers), p1_blockout.txt, p2_form.txt, bake file, gate shots, GLB
models/env/                     make_env.py writes the command files of the ground, far hills, sun, clouds, trees,
                                kid, gull, star, tail bow, spark; their .txt and GLBs
lookdev/                        the turntable bench (no RML): kite.bin
scene.bake.json                 the composition: game bones ("bone", "copies"), a "bounds" play area
scene/                          the Rive project: scene.rml (the tuned inputs), the renderer files, game.as (the game)
goldens/                        kite framed and at the scene's texel, scene/ (demo_040, demo_150, demo_450, frame_060)
shots_scene/                    the frames the scene goldens were snapped from
build.sh                        rebuilds every model and both blobs from the command files
```

Rebuild (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
./build.sh                                   # models/env + kite from scratch, lookdev/kite.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary
rive scene                                   # play; `rive scene --arg demo=true` watches the demo
```

Check (gates, goldens, frame audit, a scripted run):

```sh
python3 $K/scripts/golden.py views --hedra models/kite/kite.rmdl -o /tmp/kd_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/kite/refs --shots /tmp/kd_p2 --min-iou 0.75      # right: waiver in the spec
python3 $K/scripts/golden.py views --rive lookdev --blob kite -o /tmp/kd_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/kite/refs --shots /tmp/kd_alb -p art/palette.json --min-iou 0.7   # right, top aspect: waivers
L="--arg sunYaw=-35 --arg sunPitch=32 --arg keyLight=0.45 --arg highlight=0.8 --arg bandDither=0.4"
python3 $K/scripts/golden.py views --rive lookdev --blob kite -o /tmp/kd_k --real-sky ${=L}     # zsh; ${L} in bash
python3 $K/scripts/golden.py check --shots /tmp/kd_k --goldens goldens/kite
python3 $K/scripts/golden.py views --rive lookdev --blob kite -o /tmp/kd_ks --texel 0.054 --size 160 --real-sky ${=L}
python3 $K/scripts/golden.py check --shots /tmp/kd_ks --goldens goldens/kite@scene
for n in 40 150 450; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_060.png --advance=60
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/demo_040.png -p art/palette.json --pixel 4
# lose: start, never hold (the kite sinks onto the knoll three times); then click to fly again
rive scene --screenshot=$PWD/lose.png --advance=30 --pointer=click@320,200 --advance=420
rive scene --screenshot=$PWD/again.png --advance=30 --pointer=click@320,200 --advance=420 --pointer=click@320,200 --advance=40
```

Notes from building it:

- At 640 x 400 only `pixelSize` 2 or 4 keep the HUD on the art grid (at 3 the art grid is centred
  2 screen pixels off the HUD's: `palette.py frame` 98.1 % solid); and the camera target sits on whole
  texels (y 5 = 51 texels of 10 / 102 m), so the snap leaves the blit unshifted.
- The HUD is drawn one colour at a time in the order each colour first appears, so `hud()` primes
  that order (back to front: bands, shadows, then bright colours) with off-screen rects; without it a
  text shadow or a backing band drew over its own text.
- Gulls: dark silhouettes vanished on the dusk sky and the ink ate a pixel off their outline; they are
  haze blue and `unlit` on the `cloud` ramp's bottom step, so the ink cannot step them down.
- `game_api.place` has no per-axis scale with a roll; the kite's matrix (yaw, roll, squash) is written
  into `api.mats` by `game.as` itself.
- The Codex sheet was not reviewed by a person yet (`art/kite/sheet.v1.png.json`, `reviewed: false`).
