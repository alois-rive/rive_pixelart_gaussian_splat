# Assets: Plank Pass (Cretaceous-16, 16 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; a look-at side view of the valley
road from the front, the eye 20 degrees above (30 m out), orthographic 10.5 m -> texel 0.077 m. The camera
only translates (it pans from gap to gap), so it snaps to the art grid. Splat spacing 0.12 m for the
ground (1.6 texels), 0.13-0.15 for the big rock faces, 0.2 for the hill; the beams 0.1 (planks) and 0.07
(girders); the cart 0.08, its slate parts 0.055, its cream details and the crate's slats 0.05.
Palette: Cretaceous-16 (`palette.json`) as ten ramps (grass, rock, dust, wood, steel, red, water, cream,
far, foam) sharing the darkest #313432; the cart's red is the only warm accent; the splash is `unlit`.

At 20 degrees of pitch a horizontal face is 70 degrees from the eye, just inside the renderer's
one-sided cull (75): the road's top, the planks' tops and the grass show (at 10 degrees they were culled).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| cart | hero / vehicle | 1.04 x 1.9 x 1.36 | 1 (3 game bones: `cart`, `wheelF`, `wheelR`) | red (body), steel (boiler, chimney, wheels), cream (band, lamp, hub caps), wood (crate, slats) | `cart/sheet.v1.png` | 454 | game: rides the deck (its two axles follow the planks), tilts with the road, the wheels turn in 22.5-degree steps, idles with a stepped shiver, tumbles into a gap |
| plank | level piece | 3.2 x 0.22 x 1.2 along +X from its pivot | pool of 24 (`plank0-23`) | wood (top; front and ends a step darker) | this list | 8 | game: one per wooden beam, `placeScaled` shortened along its length (never stretched: baked at the 3.2 m maximum) and rolled to its angle; a snapped beam's second half takes a spare |
| girder | level piece | 3.2 x 0.2 x 0.2, at z -0.55 (the road's far side) | pool of 24 (`girder0-23`) | steel | this list | 12 | game: as the planks |
| terrain | terrain | 114 m of road, five gaps | 1 | grass (verges, hill), dust (road), rock (faces, a darker band, back walls), water, steel (anchor plates), rock (dry floors, the pillar) | this list | 190 | static |
| pine | foliage | 1.5 x 2.3 | 33 on the hill | grass, wood (trunk) | this list | 80 | static |
| boulder | prop | 1.2 x 0.9 x 0.75 | 14 | rock | this list | 20 | static |
| depot | prop | 3 x 2 x 3.3 shed, red roof | 1 (the road's end) | wood, red | this list | 36 | static |
| puff | effect | r 0.2 | pool of 4 (`puff0-3`) | cream | this list | 20 | game: steam from the chimney (fast while driving), grows and drifts, stepped at 10 fps |
| splash | effect | 1.2 m crown | 1 (`splash`) | foam (unlit) | this list | 140 | game: rises and falls where the cart hits the water |
| dust | effect | 1.8 m cloud | 1 (`dust`) | dust | this list | 140 | game: where the cart hits a dry floor |

Bones: 57 game bones of 63 (planks 24, girders 24, cart 3, puffs 4, splash, dust). Splats: 110 386
(`scene/splats.bin`): the rock faces 18 k, water 10 k, girders 10 k, the pines 9.6 k, the hill 8.8 k,
planks 12.4 k, the cart 3.2 k.

Layout (glTF metres, Y up, the camera on +Z): the road along +X at y 0 (y 1 after Step Gorge), 1.6 m
wide (z -0.8..0.8), a grass verge to z 1.2 where the banks' rock faces drop to y -6.5. Gaps (centre,
edges, floor; all relative to the road's y there): Mill Creek x 0, -3..3, water at -3; Fern Gully x 18,
-4..4, rocks at -4.5; Step Gorge x 36, -4..4, the far bank 1 m higher, rocks at -4.5; Twin Rock x 56,
-6..6, water at -3.5, a rock pillar (x -1.3..1.3) up to -2; Long Wash x 78, -6..6, water at -3.5. Each
gap's back wall at z -3, then the hill rises 0.9 m over 3.5 m. Anchors (steel plates in the terrain, the
same list in `game.as`): the bank edges at road level and on the cliff faces 2 m down (Step Gorge's far
one 1 m down, Long Wash's 3 m down), Twin Rock's pillar top at x -1 and 1. The build plane is z 0 (the
planks' middle); the girders sit 0.55 m behind it. The depot at x 93.

Faces the camera never sees are not modelled (towards -Z, the gap walls seen edge-on, the bottoms); the
planks have no back and no bottom (a beam is always drawn from its left joint, so its bottom never faces
up).
