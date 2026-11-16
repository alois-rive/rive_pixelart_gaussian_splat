# Game: Ember Deck (Ink-Crimson, 10 colours)

**How to play:** tap a card to play it (its cost is in the gem, you have 3 energy a turn), then tap
END TURN; beat four foes in a row, picking a new card after each win.

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`): rive 1.9.2,
hedra 0.1.0, codex-cli. Palette: [Ink-Crimson](https://lospec.com/palette-list/ink-crimson) by
Inkpendude, ten colours (seven crimson-to-ink darks, three blues) in 11 ramps; it loaded from Lospec,
so the spare (`twilioquest-76`) was not needed. A candle-lit crypt: a tiled floor, a wall of wine-dark
stone blocks with an altar arch and two niches full of red candles, pillars with cyan soul fires. The
crypt and the foes live in the crimson half of the palette, the hero and his magic in the blue half.
Orthographic, yaw 0, pitch 12, `orthoHeight` 6 m, `pixelSize` 3 (texel 0.044 m), a warm key light
from the front left, per-splat dither, ink 1, a flat sky. The cards are drawn on the HUD.

## Rules

- A run is four fights: the **Wax Mite**, the **Crypt Moth**, the **Grave Warden** and the boss, the
  **Tallow King**. The Wick Knight has 60 HP, and HP carries from fight to fight.
- Each turn: 3 energy, draw 5 cards (the draw pile reshuffles the discard when it runs out). Tap a
  card to play it if you can pay its cost; a card you cannot afford is dimmed and shakes. Block
  lasts until your next turn. END TURN (it blinks when nothing is playable) discards the hand.
- The foe shows its next move over its head: a sword and a number (attack, `4X2` hits twice), a
  shield (it gains block), an arrow (it gains strength: +N on every hit), or HEX (you are weakened:
  your attacks deal 25 % less for 2 turns). Burn hurts the foe at the start of its turn, then drops by
  one; a weakened foe deals 25 % less. Status tags sit beside the HP bars: the blue number is block,
  `WK` weak, `ST` strength, `BN` burn. Attack cards show their real damage (red when strengthened,
  dark when weakened).
- After each win choose 1 of 3 new cards for the deck, or SKIP. The boss win shows VICTORY with the
  stats (foes slain, turns, damage, deck size, score, best); HP 0 shows DEFEAT. The session's best
  score is kept; the next tap starts a new run with the starter deck.
- Score: 100 a foe slain; a victory adds 5 per HP left and 10 per turn under 40.
- Foes: the **Wax Mite** (30 HP) pecks for 7, nips 4 x 2 or hunkers down for 6 block. The **Crypt
  Moth** (36 HP) hexes first, then dives for 10 or 5 x 2. The **Grave Warden** (52 HP) cycles shield
  12 block, a 14 maul, +3 strength, an 8 strike. The **Tallow King** (100 HP) opens with +2 strength
  and 10 block, then cycles 12, 5 x 3, a shield of 14 or a hex, an 18 smash, +2 strength.
- A run takes 2 to 4 minutes; careful play wins most runs, the boss is a real fight.

### The cards

| Card | Cost | Effect | |
|---|---|---|---|
| STRIKE | 1 | 6 damage | starter x5 |
| GUARD | 1 | 5 block | starter x4 |
| KINDLE | 1 | burn 4 | starter x1 |
| CLEAVE | 2 | 13 damage | |
| JAB | 0 | 4 damage | |
| TWINCUT | 1 | 4 damage twice | |
| BULWARK | 2 | 12 block | |
| RIPOSTE | 1 | 5 block, then 5 damage | |
| BLAZE | 2 | burn 9 | |
| WITHER | 1 | the foe is weak for 2 turns | |
| PONDER | 0 | draw 2 | |
| SALVE | 1 | heal 7, once a fight (`1X`) | |
| SURGE | 0 | +1 energy, draw 1, once a fight (`1X`) | |
| SEAR | 1 | 5 damage and burn 2 | |
| SMITE | 3 | 24 damage | |
| TEMPER | 1 | +2 strength for the fight | |

Damage adds strength and is cut by a quarter when weak; block soaks damage first.

**Controls on touch.** Every control acts on the press (`POINTER_DOWN`): a tap on a card plays it, a
tap on END TURN ends the turn, a tap on a reward card or SKIP picks it, a tap on the end panel starts
a new run. Nothing needs hovering (a hovered card lifts 3 pixels with a mouse, cosmetic only), card
details are always printed on the cards, and there is no drag. Tap targets: cards 30 x 42 HUD pixels
(at least 18 wide when a full hand of 8 overlaps), END TURN 27 x 24, SKIP 38 x 13, the reward cards 30 x 42.

**Demo** (`--arg demo=true`, or the gallery's `Sample.demo`): the run opens mid-fight (the hand dealt,
the mite already burning) and the first card is played 0.3 s in. The demo player scores each playable
card (damage, lethal, block against the incoming attack, burn, weak before an attack, draw, heal when
hurt, strength early), divides by the cost and plays the best, ending the turn when nothing is worth
it; one decision in eight it plays a random affordable card instead. It picks rewards weighted by a
liking table and skips one time in ten. Its runs take 100 to 130 s and it loses about a third of them,
always to the Tallow King, often by a few HP; it starts a new run 2.2 s after the VICTORY or DEFEAT
panel. When demo is switched off, a fresh run starts at once. All its choices and every shuffle come
from `api.rand()`.

**Sound** (`sfx.as` presets through `api.sound` / `api.soundAt` / `api.note`, silent in demo): every
dealt card flips (a tick and a click, rising across the hand); a played card whooshes and clicks; a
hit on the foe crunches lower and louder the bigger it is (12 and more adds a thud and shakes the
view by a texel or two); a hit on the knight is a lower crunch and a thud; block gained or spent is a
clang (a click and a high bell); burn is a zap and a soft burst, weaken three falling plucks, a hex
the same from the foe, heal and strength a rising arpeggio, energy a coin, a reshuffle a whoosh; a
not-affordable card thuds dully. Your turn starts with two bright bells, the foe's with one low bell;
a slain foe bursts with a C-E-G pluck; picking a reward is a coin and a bell; SKIP a blip; the next
foe stomps in. VICTORY is a fanfare (C E G C, G C E with a bell on top), DEFEAT a falling sting and
three low bells. No sound is ever decided by `api.rand()`.

## What is where

```
art/palette.json, palette.png   Ink-Crimson with ramps stone, brick, cloth, steel, leather, frost, flame, ember,
                                soul, spark, hot; roles (ink sky, plum fog, void)
art/assets.md                   the asset list, bones, layout
art/hero/                       the hero's Codex brief, sheet (v1) and record, cut views (refs/, top flipped)
models/hero/                    spec + gate record, make_hero.py -> p1_blockout.txt, p3_parts.txt; p2_form.txt;
                                hero.glb (gates), hero_body/armr/arml.glb (the scene's three bones), gate shots
models/env/                     meshkit.py (a tiny GLB writer), make_env.py -> crypt, candles0-4, flames0-4,
                                sconce_fire, mite, moth, wing_l, wing_r, warden, king, king_fire, slash, spark,
                                mote, ward, burn (.glb), candles.json (the candle places the bake uses)
lookdev/                        the turntable bench (no RML): hero.bin
scene.bake.json                 the composition: the crypt, candles, and the game bones (flame0-4, soul0-1, hero,
                                armr, arml, mite, moth, wingl, wingr, warden, king, kingfire, slash0-1, spark0-9,
                                mote0-7, ward, fward, burn0-2), material -> ramp, bounds
scene/                          the Rive project: scene.rml (camera, light), game.as (the whole game), renderer
goldens/                        hero (framed), hero@scene (at the scene's texel), scene (3 demo frames + the hint)
shots_scene/                    the latest scene frames
build.sh                        rebuilds every model and blob from the generators and command files
```

Game bones: 42 of 63. Splats: 50 290 in the scene blob.

## Rebuild and check

From this directory, `K=../../../.claude/skills/pixel-splat-scene`:

```sh
./build.sh                                            # models/env, the knight (p1, p2, p3), lookdev/hero.bin, scene/splats.bin
rive scene --verify && rive inspect scene --summary   # clean
rive scene                                            # play it
rive scene --arg demo=true                            # watch the demo
```

Gates, goldens and the frame audit (zsh):

```sh
python3 $K/scripts/golden.py views --hedra models/hero/hero.rmdl -o /tmp/hero_p2 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/hero/refs --shots /tmp/hero_p2 --min-iou 0.75
python3 $K/scripts/golden.py views --rive lookdev --blob hero -o /tmp/hero_alb --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/hero/refs --shots /tmp/hero_alb -p art/palette.json --min-iou 0.7
L=(--arg sunYaw=-35 --arg sunPitch=42 --arg keyLight=0.4 --arg highlight=0.85 --arg shadeSteps=1)
python3 $K/scripts/golden.py views --rive lookdev --blob hero -o /tmp/hero --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/hero --goldens goldens/hero
python3 $K/scripts/golden.py views --rive lookdev --blob hero -o /tmp/hero_s --texel 0.0441 --size 120 --real-sky $L
python3 $K/scripts/golden.py check --shots /tmp/hero_s --goldens goldens/hero@scene
for n in 30 1500 5520; do rive scene --screenshot=$PWD/shots_scene/demo_$(printf %03d $n).png --advance=$n --arg demo=true; done
rive scene --screenshot=$PWD/shots_scene/frame_060.png --advance=60
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
for f in shots_scene/*.png; do python3 $K/scripts/palette.py frame $f -p art/palette.json --pixel 3; done
```

The demo goldens: `demo_030` the knight raises his ward against the mite's double nip (+5 block),
`demo_1500` the Crypt Moth dives and the ward blocks it, `demo_5520` the Tallow King smashes in.
`frame_060` is the first hand with the hint, before any tap.

Play it headless. The first hand of a fresh run is always STRIKE, KINDLE, STRIKE, GUARD, GUARD (the
seeded shuffle) against a mite about to nip 4 x 2; the cards' centres sit at screen x 114 + 96 i
(i = 0..4), y 330, END TURN at (591, 336):
`rive scene --screenshot=$PWD/p.png --advance=60 --pointer=down@114,330 --pointer=up@114,330 --advance=40
--pointer=down@591,336 --pointer=up@591,336 --advance=150` plays a STRIKE (the mite drops to 24/30), ends
the turn, takes both nips (52/60) and draws the next hand. Touch, with `--commands`: `advance 60`,
`touch down@114,330`, `touch up@114,330`, `advance 40`. The hand-over from demo to a player: `data
demo=true`, `advance 240`, `data demo=false`, `advance 60` (a fresh run, the hint).

A closed-loop player (a Python script reading temporary `console.log` state lines and answering with
`touch down@` / `touch up@` only) beat a whole run: the mite in 3 turns (54 HP left), the moth by turn
6, the warden by turn 10, the Tallow King by turn 18 with 13 HP, deck 13 (it took KINDLE, BLAZE and
TWINCUT). The logging was removed after.

## Notes from building it

- **The HUD is the game.** Everything you click is drawn with `api.rect` / `api.text` in call order:
  the hand (cards slide from the draw pile to their slots), the energy gem, the piles, END TURN, the
  intent box, HP bars and status tags under the figures (placed with `api.project`), floating numbers
  rising from the hit point, the reward panel and the end panel. Card pictures are 9 x 9 icons from
  strings, drawn as one rect per horizontal run.
- **The hero is three bones.** One hedra model gated as a whole, then split by `p3_parts.txt` into a
  body and two arms whose GLB origins are their shoulders; `game.as` places the body, finds the
  shoulders with `api.transform` and turns the arms about them (pitch is the swing).
- The legs and boots were the floor's colours and vanished; they are one step up the cloth ramp in
  the scene bake, and the floor was darkened a step.
- The moth flew with its wings nearly flat, so from a 12-degree camera they were edge-on: they are
  raised 58 degrees and the moth faces out of the picture.
- The ward mesh is painted cyan and baked twice: once on the cyan spark ramp, once on the red ember
  ramp for the foe (the bake warns "colours far from its ramp": on purpose).
- The Codex sheet was not reviewed by a person yet (`art/hero/sheet.v1.png.json`, `reviewed: false`).
