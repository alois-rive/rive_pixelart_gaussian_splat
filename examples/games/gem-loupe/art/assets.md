# Assets: Gem Loupe, a match-3 on a jeweller's bench by candlelight (Galaxy Flame)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare); `orthoHeight`
4.25 m -> texel 0.03125 m, so a 0.5 m board cell is exactly 16 art pixels wide (14.6 tall at the
camera's pitch): a tap target well over 12 art pixels. Splat spacing 0.035 m (1.1 texels) for the
gems, 0.03 to 0.035 for small props and marks, 0.045 for the tray, 0.06 for the bench planks.
Camera: orthographic, yaw 0, pitch 66 (the board from above at a slight angle), target (0.3, 0, 0):
the board left of centre, the order card on the right. Light from the candle's side (sun yaw -55,
pitch 48, key 0.42, highlight 0.85, `shadeSteps` 1), per-splat dither, ink 1, `edgeDepth` 0.3, a flat
sky (never seen: the bench fills the frame).

Palette: Galaxy Flame (16 colours: three teal-blues, six dark-green-to-cream, six umber-to-gold, and
two near-blacks) in 15 ramps: velvet (black, pine, deep, moss), wood (night, umber, brown, tan), brass
(umber .. gold), the five gem ramps sapphire (black, slate, blue, teal, cream), jade (pine, moss,
olive, sage, cream), amber (umber, tan, amber, gold), garnet (night, umber, brown, tan, amber), pearl
(olive, sage, cream, cream); steel (as sapphire), wax, paper, and the unlit ones flame, spark, glint,
plus ink for the baguette's rail. The gems are told apart by ramp AND by cut, so they read in the
palette's narrow hue range: a round blue, a square olive, a gold triangle, a brown marquise, a cream
pearl; the brilliant is an unlit gold star.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| loupe | hero | 0.64 x 0.13 x 1.32 (bake scale 1.15) | 1 (bone `loupe`) | brass, wood | `loupe/sheet.v1.png` | 200 | game: the cursor. Lies flat on the bench at rest; hovers over the cell under the finger or the selected gem, tilted to face the camera (pitch -66) so its ring frames the gem; dips while pressed or selected; eased (16/s) |
| drum (the gems) | game pieces | six cuts 0.42-0.5 wide, 0.14-0.21 tall, on a ring R 0.78 round X | 49 (pool `gem`) | sapphire, jade, amber, garnet, pearl, flame (unlit star) | this list | 158 | game: one per cell, see "Bones" |
| band (baguette mark) | effect | 0.71 x 0.085 x 0.09 | 5 (pool `band`) | ink (rail), spark (unlit tips) | this list | 22 | game: rides on its gem, yaw 0 (row) or 90 (column), the tips breathe |
| claws (cluster mark) | effect | four 0.16 claws at (+-0.19, +-0.19) | 3 (pool `claw`) | spark (unlit) | this list | 24 | game: rides on its gem, pulses |
| bench | terrain | 9 x 6.4 top face, planks texture 72 x 52 (0.125 m texels) | 1 | wood | this list | 2 | |
| tray | architecture | 3.5 x 3.5 velvet (checker texture 28 x 28) + frame 0.2 wide, 0.11 tall, brass corners | 1 | velvet, wood, brass | this list | 82 | |
| card | prop | 1.4 x 3.5 x 0.07 | 1 | paper | this list | 10 | the HUD writes on it |
| candle | prop | dish 0.6 across, wax 0.24 x 0.5 | 1 | brass, wax | this list | 154 | |
| flame | effect | 0.15 x 0.28 (bake scale 1.8) | 1 (bone `flame`) | flame, glint (unlit) | this list | 50 | game: stepped 10 fps flicker (height, width, lean) from a hash of the step, not `api.rand` |
| mandrel | prop | 0.95 long, 0.2 across, a gold ring on it | 1 | steel, wood, brass | this list | 136 | |
| tweezers | prop | 0.95 x 0.14 x 0.07 | 1 | steel | this list | 36 | |

## Bones (59 of 63)

A 7 x 7 board needs 49 gems on screen, each able to be any of six cuts. Ways that were weighed:

- **A pool per cut** (cells x cuts bones): 294 bones. No.
- **One mixed pool of ~53 fixed-cut gems, recycling cleared ones**: fits (49 + 4 spare), but the refill
  can only use the cuts that just cleared plus the few spares: three reds clear, three reds (mostly)
  come back. The refill would be predictable and full of re-matches. No.
- **One bone per cell, every cut on it (chosen)**: each bone is a *drum*: the six cuts sit on a ring
  0.78 m round a horizontal axis 0.78 m under the velvet, 60 degrees apart. The game turns the drum
  (pitch -60 x cut) so the cut it needs stands on the velvet; the other five are inside the bench, under
  the velvet and the bench top (the nearest, at 60 degrees, peaks 9 cm under the velvet: R > 0.72 m
  keeps a 5 cm margin for the tallest cuts; the bench top sits 4 cm under the velvet and reaches past
  the drums' 0.9 m spread). Any cut, any time, no reserve: the refill is truly random and specials need
  no extra pieces except their marks.

Rules that follow, kept by `game.as`: a drum never rises above the velvet (that would lift its hidden
cuts with it); it slides in the velvet plane (swaps, falls), and sinks or rises through the cloth to
appear, vanish or change cut (a new gem rises at the top of its column and slides down; a cleared gem
pops, then shrinks and sinks; a brilliant is forged by sinking, turning out of sight and rising).
Scaling is always about the shown cut's base on the velvet (a scale above 1 pushes the hidden cuts
deeper, below 1 pulls them up but never past it): `placeDrum` writes the bone matrix itself.

Cost: 49 drums x 6 cuts = 64 000 splats (about 220 a cut, the cuts' undersides deleted); 93 700 in
the whole blob. Bones: flame 1 + loupe 1 + gems 49 + bands 5 + claws 3 = 59. Sparkles, beams, the
score pop and the words are HUD (palette colours on the art grid), not bones.

Layout (glTF metres, Y up, +Z towards the camera): velvet top at y 0, cells 0.5 m, column 0 at x -1.5,
row 0 (the far edge) at z -1.5; the frame to +-1.95 (top 0.07); the bench top at y -0.04; the card at
x 2.1 .. 3.5; candle at (-2.45, -1.25), the loupe's rest at (-2.42, 0.35), mandrel and tweezers along
the near edge. Play area (`"bounds"`): 9 x 3.4 x 6.4 m (y -1.8 .. 1.6 holds the drums' lowest cuts).
