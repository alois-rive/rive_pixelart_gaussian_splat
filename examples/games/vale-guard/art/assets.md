# Assets: Vale Guard (Vinik24, 24 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels (136 rows with the spare); an orbit
camera at yaw 0, pitch 40, orthographic 9 m -> texel 0.066 m. Splat spacing 0.085 m for the scenery
(1.3 texels), 0.1 for the ground and 0.1-0.13 for the far rocks, palisade and ridge; towers 0.07-0.075
(after their 1.2 bake scale), creeps 0.05-0.065, projectiles 0.04-0.05.

Palette: Vinik24 (Lospec `vinik24`, loaded; the spare `resurrect-64` was not needed). Its 24 colours sit
on four luma levels (0.24, ~0.40, ~0.60, 0.78 plus black), so every ramp is the shared dusk purple
`#433455`, one mid colour, one light colour and (mostly) the shared pale `#c5ccb8`: materials differ by
hue, the ramps by their mid and light steps. 17 ramps: grass, leaf, dirt, stone, rock, moss, wood, roof,
gold, frost, storm, plum, shell, plaster, fire, spark, ink (HUD and unlit dark). Roles: flat `#433455` sky
(hidden behind the ridge), fog `#7e9e99` (unused), void `#433455`.

## Layout (glTF metres, Y up; x to the right of the screen, z towards the camera)

`models/env/make_env.py` holds the layout and writes it into `scene/game.as` (`// <layout>`):

- The path: 22 control points from the cave mouth (-5.75, -4.3) to the village (6.6, 2.6), smoothed
  (Catmull-Rom) and resampled every 0.25 m (139 points, 34.8 m). Three runs across the valley (z -3.5,
  0, 3.4) joined by two bends; 1.0 m wide, painted into the ground texture. A creep past x 5.7 (the
  palisade, `GATE_X` 5.4 + 0.3) has reached the village: 32.3 m of path.
- Ten build pads (octagons 1.24 m across the flats): three between the back and middle runs, three
  between the middle and front runs (each covers two runs), one in each bend's outside, one by the cave,
  one behind the back run.
- The gloom moths fly straight from the cave to the gate (13.4 m), 1.25 m up, over everything.

## The list

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| keep (Boulder Keep, the cannon tower) | hero | 1.0 x 1.05 x 1.29 (baked x1.2) | 4 (`keep0-3`) | stone (drum, parapet, merlons), wood (door, carriage), gold (barrel), roof (banner) | `keep/sheet.v1.png` | ~230 | game: turns to aim (15-degree steps), squashes on a shot, pops in when built or upgraded |
| loft (Larch Loft, the arrow tower) | prop / tower | 1.0 x 1.2 x 1.62 (x1.2) | 4 (`loft0-3`) | stone (footing), wood (legs, cabin), roof (pyramid roof), gold (crossbow), ink (window) | this list | ~120 | game: turns to aim |
| well (Rime Well, the frost tower) | prop / tower | 1.0 x 1.0 x 1.45 (x1.2) | 4 (`well0-3`) | stone (well), frost (water, crystal), moss (standing stones) | this list | ~100 | game: bobs on a shot (no aim) |
| spire (Thunder Spire, the storm tower) | prop / tower | 0.96 x 0.96 x 1.7 (x1.2) | 4 (`spire0-3`) | stone (plinth), rock (obelisk), gold (copper bands, prongs), storm (orb) | this list | ~130 | game: stretches on a strike; lightning is HUD lines |
| standard (gilded standards, level 3) | prop | 1.4 x 1.4 x 1.2 | 8 (`standard0-7`) | gold (band, poles, finials), roof (pennants, two-sided) | this list | ~150 | game: rise round a pad when its tower reaches level 3 |
| mite (swarmer) | character | 0.36 x 0.5 x 0.32 (x1.3) | 8 (`mite0-7`) | plum (shell, head), gold (horns), ink (feet) | this list | ~120 | game: scuttles (yaw wiggle, hop) |
| skitter (fast) | character | 0.3 x 0.78 x 0.34 (x1.3) | 4 (`skitter0-3`) | storm (hide), roof (crest), moss (feet) | this list | ~80 | game: hops |
| shell (Shellback, armoured) | character | 0.7 x 0.84 x 0.5 (x1.3) | 4 (`shell0-3`) | shell (dome, rim), moss (head, feet) | this list | ~110 | game: plods |
| moth (Gloom moth, flyer) | character | 0.86 x 0.5 x 0.2 (x1.3) | 3 (`moth0-2`) | plaster (body, spots), plum (wings, two-sided) | this list | ~80 | game: flies a straight line, wings flap (x squash, 10 fps), bobs |
| troll (Moss troll, the boss) | character | 1.05 x 0.75 x 1.3 (x1.15) | 1 (`troll`) | shell (skin), rock (legs, plates, brow), leaf (hump), wood (club), plaster (eyes) | this list | ~150 | game: lumbers (roll), waves 5, 10, 15 |
| bolt | effect | 0.08 x 0.42 | 5 (`bolt0-4`) | wood, gold | this list | 16 | game: homes on its target at 11 m/s |
| ball (cannonball) | effect | 0.26 | 3 (`ball0-2`) | rock | this list | 20 | game: lobbed (0.62 s arc) at where the creep will be |
| shard (frost shard) | effect | 0.16 x 0.34 | 3 (`shard0-2`) | frost (unlit) | this list | 8 | game: homes at 8 m/s |
| pop (hit puff) | effect | 0.7 | 4 (`pop0-3`) | plaster (puffs), fire (sparks, unlit) | this list | 140 | game: grows, shrinks, hides in 0.36 s (stepped) |
| ground | terrain | 14.8 x 13.8 | 1 | texture (grass, dirt; `textures/ground.png`, 129 x 120, 0.115 m a texel), grass (ridge mounds) | this list | ~270 | static |
| scenery | terrain / props | round the valley | 1 | rock (cave, boulders), rock unlit (the black mouth), wood (palisade, gate, trunks), roof, plaster (cottages), grass +1 step (round tree crowns, bushes, sway), leaf (pines, sway), stone (pads, a lighter step on their tops) | this list | ~3000 | static (sway) |

## Bones (59 of 63, all game bones)

| Pool | Bones | Why this many |
|---|---|---|
| towers: keep, loft, well, spire | 4 x 4 = 16 | one bone per built tower, pooled per kind: a tower is its kind's model, so a pad cannot share one bone across kinds. Four of each covers ten pads (a player who wants five of one kind is told NONE LEFT in the ring) |
| gilded standards | 8 | level 3 is shown by a second object on the pad, not a third model per kind: up to 8 towers at level 3 |
| creeps: mite 8, skitter 4, shell 4, moth 3, troll 1 | 20 | the most on the path at once; a wave's next creep waits for a free slot (the spawn clock pauses), so a pool never overflows |
| projectiles: bolt 5, ball 3, shard 3 | 11 | flights are short (0.1-0.6 s); a tower waits for a free one. Lightning costs no bone (HUD lines) |
| hit puffs | 4 | recycled round-robin |

Levels without more bones: level 1 is the tower at 0.8 of its baked size (baked at the largest, level 2
and 3 at 1.0, only ever scaled down), level 2 grows it (with a pop and one gold chevron over it), level 3
raises the gilded standards round its pad (two chevrons).

Splats: 97 377 (3.0 MB): ground 21.2k, scenery 25.5k, towers 26.9k (16 bones: keep 1.7k, loft 1.9k,
well 1.3k, spire 1.8k each), standards 8.1k (8), creeps 13.6k (20), bolts, balls, shards and puffs 2.1k.

## What was dropped or exaggerated

- Arrows are chunky crossbow bolts (0.08 m), not arrows; merlons are 0.15 m (the sheet's 0.13 bake to
  specks); pennant poles and the palisade's pointed tips are their own finer materials.
- The cave mouth is an unlit black octagon (rock ramp step 0) set in a ring of boulders, turned to face
  the camera and the path.
- No grass blades, no stone courses, no faces: below two splats.
