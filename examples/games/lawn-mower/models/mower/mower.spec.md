# Asset: mower (hero, game-driven)

Concept: ../../art/mower/sheet.v1.png (Endesga 16 colours), refs cut to ../../art/mower/refs/ (no flips:
the chute is on the image's left in FRONT and TOP, right in BACK, the nose points left in RIGHT, as asked).
Up Z, facing -Y; origin on the ground under the body's centre (the game turns it about there). Scale
from the side panels: 1.3 m tall = 434 px -> 334 px per metre (the TOP panel is drawn at 278 px per metre:
the gate compares shapes, not sizes).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Chassis | box 0.63 x 1.42 x 0.29 | z 0.14..0.43 | Red (red, #e53b44) |
| Hood | box 0.6 x 0.62 x 0.21, its front top edge pulled down 0.15 (the slope) | y -0.71..-0.09, z 0.40..0.61 | Red |
| Rear deck | box 0.63 x 0.51 x 0.13 | y 0.20..0.71, z 0.40..0.53 | Red |
| Cutting deck | box 0.8 x 0.7 x 0.095 | y -0.37..0.33, z 0.045..0.14 | Deck (stone, #4f6781) |
| Grass chute | box 0.27 x 0.345 x 0.14 | x -0.65..-0.38 (the mower's own right) | Deck |
| Rear wheels | 10-gon r 0.25, 0.17 wide, hub inset 0.11 | x +-0.40, y 0.56, z 0.25 | Tyre (wood, #3f2832); Hub (stone, #afbfd2) |
| Front wheels | 8-gon r 0.16, 0.14 wide, hub inset 0.07 | x +-0.385, y -0.56, z 0.16 | Tyre; Hub |
| Seat | cushion 0.44 x 0.35 x 0.07, backrest 0.44 x 0.14 x 0.38 | y 0.25..0.72 | Seat (wood, #743f39) |
| Steering | column 0.06 x 0.06 x 0.32, wheel 8-gon r 0.13 tilted 35 degrees | y -0.12..-0.06 | Seat |
| Gardener | thighs, shins (Seat), torso 0.36 x 0.25 x 0.34 and arms (Shirt, blue #0484d1), hands and head 0.2 x 0.2 x 0.17 (Skin, #e4a672) | torso y 0.265..0.515, z 0.63..0.97 | |
| Hat | brim 10-gon r 0.275 x 0.04, crown cone r 0.13 -> 0.1 x 0.13 | z 1.135..1.30 | Hat (straw, #ffe762) |

`make_mower.py` writes `p1_blockout.txt` (every part with its material) and `p2_form.txt` (the hood's
slope, the hubs inset into the wheel faces, flat shading, the export).

## Assumptions
- The FRONT view's rear wheels look taller (0.57 m) than the RIGHT view's (0.48 m): the side view leads
  (the front panel seems drawn from slightly above).
- The TOP panel is drawn at a smaller scale than the side panels; only its shape is used.
- No face, no tread, no steering-wheel spokes: under two splats.

## Gate record (generated-sheet tier: form IoU >= 0.75, aspect drift <= 0.08, splat IoU >= 0.70, splat drift <= 0.08, colour <= 0.25)
| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 | 0.902 / 0.012 | 0.794 / 0.001 | 0.922 / 0.015 | 0.849 / 0.035 | passes |
| **p2** | **0.902 / 0.012** | **0.811 / 0.001** | **0.922 / 0.015** | **0.849 / 0.035** | the hood's slope; hubs (the first p2 selected the wheel caps by `normal.x`, but `select where` reads local axes and the wheels keep their rotation: `normal.z`) |

Splats, albedo (`lookdev/mower.bin`, spacing 0.075, the scene's): IoU **0.846 / 0.787 / 0.826 / 0.870**,
aspect drift **0.005 / 0.008 / 0.044 / 0.070**, colour drift **0.10 / 0.10 / 0.09 / 0.08**: pass, no waiver.

Goldens: `goldens/mower` (framed) and `goldens/mower@scene` (`--texel 0.056 --size 100`), lit like the
scene (`--arg sunYaw=-38 sunPitch=52 keyLight=0.42 highlight=0.9 edgeDepth=0.35`, `--real-sky`). The sheet
is not reviewed by a person yet (`art/mower/sheet.v1.png.json`, `reviewed: false`).
