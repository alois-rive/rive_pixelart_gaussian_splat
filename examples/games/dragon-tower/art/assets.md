# Assets: Dragon Tower (Blessing)

Art grid: 640 x 400 artboard, `pixelSize` 2 -> 320 x 200 art pixels (322 x 202 with the spare
pixels); a look-at orthographic camera 10 degrees above the horizon aimed at the world origin,
`orthoHeight` 10.1 m -> texel 0.05 m. Splat spacing 0.08 m (1.6 texels); ladders and knights 0.05 m,
horns, claws and eyes 0.05 m. Palette: Blessing (`palette.json`, 5 colours: purple, mint, pale
yellow, pink, thistle); every ramp starts at the purple, which is also the ink.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| dragon | hero character | 3.2 x 2.1 x 2.2 (x 1.2 in the scene) | 1 (2 game bones: body, head) | scale (mint), wing (pink, no yellow top: the membranes stay pink in the sun), stone (horns, claws, eyes) | `dragon/sheet.v1.png` | 996 | game: breathes (squash), inhales (squash 0.9, head up), stretches into the flame, flinches, slumps; the head turns and dips towards the aim (neck pivot) |
| tower | architecture | 3.2 x 3.2 x 5.2 | 1 | stone (thistle keep, purple plinth, corbel, slits, door) | this list | 304 | |
| ladder | prop | 0.64 x 0.1 x 4.4 | 3 (at -45, 0, 45 degrees) | stone (pale yellow, step 2) | this list | 156 | |
| ground | terrain | 18 x 16 plane + knoll | 1 | scale (mint), stone (flagstones) | this list | 102 | |
| hills | terrain | 4 low hills, far | 1 | scale (fogged) | this list | 200 | |
| tree | foliage | 1.9 x 1.5 x 2.6 | 6 (0.7-1.05) | armor (purple trunk), blush (pink blossom) | this list | 80 | |
| knight | character | 0.5 x 0.45 x 1.0 (x 1.25) | pool of 9 | armor (purple steel, step 1), scale (mint tunic), blush (pink shield, plume), stone (yellow boss) | this list | 126 | game: walk in with a stepped hop, climb a rung at a time with a tug and a rest (stepped 4 frames), rock 6 degrees per rung; pop on a hit (swell, flatten), tumble off (45-degree steps), puff on landing; hop onto the merlons and gloat on a breach |
| fireball | effect | 0.7 across | pool of 16 | fire (unlit: yellow core, pink licks) | this list | 50 | game: flies 10.5 m/s towards the aim, grows 0.6 -> 1.6, flickers in 47-degree steps at 14 fps, shrinks out |
| poof | effect | 0.7 across | pool of 6 | cloud (unlit) | this list | 60 | game: swells and rises, stepped at 6 sizes |
| cloud | sky | 3.6 x 1.4 x 1.4 | 3 game bones | cloud (unlit) | this list | 80 | game: drifts right and wraps, moved in whole texels |

Bones: dragon 2 + knights 9 + fireballs 16 + puffs 6 + clouds 3 = 36 of 63 (all game bones; no baked
tracks). Splats: 83 085 in `scene/splats.bin`.

Layout (glTF metres, Y up, +Z towards the camera; the frame's centre is the world origin): the meadow
at y -4.4; the tower's axis at x 0, z 0, its walk (where the dragon sits) at y 0.3; ladders 1.45 m
from the axis at -45, 0, 45 degrees; a climbing knight 1.68 m out; the fire flies towards the pointer
on the plane z 2.3 (in front of the ladders) and hits what overlaps it on screen; hills 16 m behind
and 1.5 m low (a pitched orthographic view lifts far things by z sin(pitch)).
