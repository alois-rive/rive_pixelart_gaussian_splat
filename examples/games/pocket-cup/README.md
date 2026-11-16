# Game: Pocket Cup (Sheltzy32)

**How to play:** your nearest player (gold ring) runs to the pointer or follows your finger; tap to pass,
press, hold and release to shoot; run into the ball carrier to tackle. Beat Fernley in two minutes.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2, hedra
0.1.0, codex-cli. Palette: [Sheltzy32](https://lospec.com/palette-list/sheltzy32) by NatTorpedia, 32
colours, loaded from Lospec (the spare `zughy-32` was not needed), written as 15 ramps (grass, chalk,
verge, leaf, wood, skin, coral, sky, navy, gold, violet, pink, teal, boot, mark). A village pitch on a
late morning: mown stripes and chalk lines, worn goalmouths, small white goals with box nets, a
post-and-rail fence with gold pennants, eight supporters along the far rail, trees behind them.
Bramblecombe (you: coral shirts, cream shorts, a gold-shirted keeper) against Fernley (sky-blue shirts,
navy shorts, a violet keeper), 3-a-side. A broadcast camera on the near touchline: orthographic, yaw 0,
pitch 34, `orthoHeight` 9 m, `pixelSize` 3 (texel 0.066 m), following the ball (the renderer snaps the
target to the art grid, so the pitch slides by whole pixels); sun yaw -35, pitch 52, per-splat dither, ink 1.

## Rules and controls

- **Run**: the Bramblecombe outfield player nearest the ball is yours (a turning gold ring under him); it
  switches by itself (with some hysteresis), to whoever wins the ball, and to the receiver of your pass.
  He runs to the pointer's spot on the grass (a small white cross) and dribbles the ball when he has it.
- **Pass**: a tap (a press shorter than 0.22 s that does not move) passes toward the tapped spot: to your
  teammate when he is within ~35 degrees of that direction, else into that space. Without the ball a tap
  lunges at it.
- **Shoot**: press and hold still, release: the power (a bar over his head, rising ticks) grows over a
  second, from a 9 m/s side-foot to a 22 m/s drive that rises; a full-power shot from far goes over the bar.
- **Tackle**: run into the man on the ball: 55 % to win it (70 % during a lunge); a miss staggers you 0.7 s.
- **Touch** (phones send the pointer only while a finger is down): the player follows the finger while it
  drags and keeps running to where it lifted; a drag (moving more than 6 HUD pixels) only runs, it never
  passes or shoots; a tap passes toward the tapped point; a held press runs toward the pressed point
  while it charges, and the release shoots there. A mouse also steers by hovering. Nothing needs a hover.
- **Match**: two minutes on the clock (it stops for goals; the last ten seconds tick). GOAL! stops play for
  3 s (the scorers run to the corner, the supporters jump), then the side that conceded kicks off. Full time
  shows `YOU WIN 3-2` / `YOU LOSE` / `A DRAW`, the score and the session's **best goal difference**; the
  next click starts a new match on the same pitch. The first click kicks off.
- **Ball**: rolls with friction (1.3 m/s² plus a speed term), flies with gravity and bounces (its shadow
  falls from the sun's shadow map), knocks off the posts, the crossbar, the side and roof netting and the
  fence (no out of play; the corners behind the goals are reachable), and dies in the net.
- **Keepers**: stand on the ball's angle a step off the line (further out when an attacker closes in), come
  for loose balls in their box, read each shot once (a reaction of 0.1 to 0.13 s and an error that grows
  with the shot's speed), then side-step or dive: a roll about the body's forward axis that reaches the
  ball's height and only reaches the corners if the read came early. They catch slower shots and parry hard
  ones out (a diving catch is rarer), then throw to the freer teammate or punt it upfield.
- **The computer**: each outfield pair has a carrier, a support runner (ahead of the ball, on the far
  side), a presser (goal-side of the ball) and a cover (between ball and goal, leaning toward the other
  attacker), or a chaser on an intercept for a loose ball. The carrier dribbles at goal, slips round the man
  in front, passes when pressed and the lane is clear, and shoots inside 7.2 m (Fernley) at the corner away
  from the keeper, with aim errors (some go wide or hit the post). Your uncontrolled teammate is the same AI
  with Bramblecombe's slightly sharper numbers.

A closed-loop touch-only player (a script driving `--commands` with only down, drag-moves and up, reading a
temporary state log) chased the ball, dribbled round defenders, passed and shot: it won 3-2, 4-4, 5-2, 5-4
against Fernley. Standing still loses 0-7 or 0-8.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): both sides are the computer. It opens with
Bramblecombe breaking into Fernley's box, the shot struck at 0.35 s and in the net at 0.55 s, then plays full
matches (six in a row: 2-3, 1-1, 2-6, 4-1, 3-2, 3-3) and kicks off again two seconds after full time. Demo
matches do not count for your best. When demo is switched off a fresh match waits for the first click.

**Sound** (`sfx.as`, silent in demo mode): the referee's pea whistle is a fast trill of two high blips
(`api.note` on `SFX_BLIP`): two pips at kick-off, one long blast for a goal, short-short-long at full time.
A shot is a thud that deepens and swells with the power plus a leather smack (a whoosh above 60 %); a
pass a lighter thud and tick; dribbling a soft tick a stride; a trap a small thud; bounces thud by impact.
The posts and crossbar clang (a click and two high notes, a small shake), the fence knocks (a low thud and a
wooden tick), the netting rustles. A won tackle crunches, a missed one whooshes and stumbles; the keeper's
dive whooshes and lands with a thud, a catch pops into the gloves, a parry thuds. A goal is a crowd cheer
swelling over 1.7 s (fourteen layered noise bursts, rising then falling, panned across) and, for yours, a
coin and a rising C-major jingle; a goal against is a short groan and two falling notes. Full time adds
the win or lose jingle (two bells for a draw). Charging a shot ticks upward. No sound is decided by a
random draw.

## What is where

```
art/palette.json, palette.png   Sheltzy32 with 15 ramps and roles
art/assets.md                   the asset list, the art grid, the play area, bones and splats
art/player/                     the hero's Codex brief, sheet v1 (reviewed: false), record, log, cut views (refs/)
models/player/                  make_player.py -> p1_blockout.txt, p2_form.txt, p3_splat_fit.txt (the gated
                                hero) and body.txt, leg.txt (the scene's parts); spec + gate record (one
                                waiver), player.bake.json, gate shots, the GLBs
models/env/                     make_env.py -> ground, fence, goal, tree, ball, ring .txt and textures/ (pitch,
                                verge, net_*), their GLBs
make_bake.py                    writes scene.bake.json (the six players in four kits, the supporters)
lookdev/                        the turntable bench (no RML): player.bin
scene.bake.json                 the composition: 83 574 splats, 28 game bones of 63, bounds
scene/                          the Rive project: scene.rml (camera, sun), game.as (the whole game), renderer
goldens/                        player (framed), player@scene (texel 0.0662), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the command files
```

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models, textures, lookdev/player.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/player/player.rmdl -o /tmp/pc_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/player/refs --shots /tmp/pc_p2 --min-iou 0.75 --max-aspect-drift 0.08   # top: waiver
python3 $K/scripts/golden.py views --rive lookdev --blob player -o /tmp/pc_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/player/refs --shots /tmp/pc_alb -p art/palette.json --min-iou 0.7 --max-aspect-drift 0.08
L=(--arg sunYaw=-35 --arg sunPitch=52 --arg keyLight=0.4 --arg highlight=0.85 --arg shadeSteps=1)
python3 $K/scripts/golden.py views --rive lookdev --blob player -o /tmp/pc_f --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/pc_f --goldens goldens/player
python3 $K/scripts/golden.py views --rive lookdev --blob player -o /tmp/pc_s --texel 0.0662 --size 160 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/pc_s --goldens goldens/player@scene
for n in 020 075 796; do rive scene --screenshot=$PWD/shots_scene/demo_$n.png --arg demo=true --advance=$n; done
rive scene --screenshot=$PWD/shots_scene/frame_030.png --advance=30
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

Goldens: `demo_020` (the demo's opening attack, the shot about to be struck), `demo_075` (GOAL!, the
ball in the net, the scorers celebrating), `demo_796` (a keeper down after a diving save), `frame_030` (the
hint before the first click, the supporters along the far rail). Frame audit: 100 % solid 3 x 3 blocks,
23 to 27 colours, 0 off-palette.

Play it headless, touch only (a tap to kick off, a drag to run with the ball, a held press and release to
shoot): `rive scene --screenshot=$PWD/t.png --render-audio=$PWD/t.wav --advance=3 --pointer=down@320,200
--pointer=up@320,200 --advance=70 '--pointer=drag@330,230>470,240:20' --advance=10 --pointer=down@560,230
--advance=45 --pointer=up@560,230 --advance=40`. The demo-to-player hand-over: `printf 'data demo=true\nadvance
400\ndata demo=false\nadvance 30\nscreenshot /tmp/h.png\nquit\n' | rive scene --commands` shows the hint over
a fresh line-up.

## Notes from building it

- The physics and AI were tuned in Rive itself rather than a Python port: a headless `--advance=40000`
  demo run takes about 12 s, so whole matches with a temporary `console.log` of goals, shots, saves and
  tackles were the loop. The first keepers saved 4 of 20 shots (17-goal matches): they read late (0.2 s),
  with a 0.4 m error, and a flat dive passed under any ball above the knee. Now they react in 0.1 s, the
  error grows with the shot's speed, and the dive rolls only until the hands meet the ball's predicted height.
- The leg's GLB first kept the hip as a node offset (origin set without moving the object back), so the
  bake put the legs 0.6 m up inside the torso; `leg.txt` now sets the object back to the origin.
- The first camera (pitch 42, 8.5 m) never showed the far fence or the supporters; pitch 34 at 9 m shows
  the whole pitch's depth with the village at the top, and the follow leans to the far side.
- A goal could roll back out of the mouth after hitting the back netting; the net now soaks the ball.
- `BRM` read as `BRN` in the 3 x 5 font: the scoreboard spells the names out.
- The Codex sheet was not reviewed by a person yet (`art/player/sheet.v1.png.json`, `reviewed: false`).
