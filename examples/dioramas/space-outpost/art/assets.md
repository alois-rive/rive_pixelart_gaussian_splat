# Assets: a research outpost on an asteroid (Ammo-8)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 214 x 134 art pixels; `orthoHeight` 8.5 m -> texel
0.064 m. Splat spacing 0.08 m (1.25 texels; struts 0.05, small lights 0.04-0.05). Palette: Ammo-8
(`palette.json`, 8 greens) with ramps rock, pad, hull, dish, glow. Camera: orthographic, pitch 50,
yaw -20, spin 3 deg/s.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Animation |
|---|---|---|---|---|---|---|---|
| asteroid | terrain | 9.2 x 9.2 x 3.1 | 1 | rock (regolith texture 48 px, painted one step down in the bake) | this list | 216 | |
| radar | hero prop | 1.84 x 1.77 x 2.32 (x1.25 in the scene) | 1 | hull, dish, glow (unlit) | `radar/sheet.v1.png` | 234 | head + dish turn 360 deg / 8 s, dish nods -36..-50..-22 deg; rigid, 2 bones, 12 fps |
| habitat | architecture | 5.3 x 2.1 x 2.2 | 1 | hull, glow (unlit windows), glow (beacon) | this list | 258 | beacon arm spins 1 turn / 2 s, rigid, 12 fps |
| pad | architecture | 3.4 x 3.4 x 0.26 | 1 | pad (ring + H texture 32 px), glow (8 edge lights) | this list | 124 | |
| antenna | prop | 0.7 x 0.5 x 2.7 | 2 (1, 0.85) | hull, glow (beacon) | this list | 72 | beacon pops on 0.25 s of every 1 s (constant keys: scale 1 <-> 0.05 inside the cap), phase 0 / 0.5 |
| rover | prop | 1.22 x 1.6 x 1.4 | 1 | hull, dish, glow (windscreen) | this list | 244 | parked |
| crate | prop | 0.66 x 0.66 x 0.66 | 4 (one stacked) | hull | this list | 36 | |
| boulder | prop | 1.0 x 0.8 x 0.6 | 4 (0.8-1.2) | rock | this list | 20 | |
| stars | effect | 26 x 26 disc, 8 m below | 1 | glow (unlit, nocast) | this list | 1800 | |
| shuttle | vehicle | 1.7 x 1.7 x 1.0 (x1.2 in the scene) | 1 | dish (hull and wings, light), hull (fin, engines, skids), glow (canopy, unlit) | this list | 124 | game bone `shuttle` (game.as), baked parked on the pad |
| hauler | vehicle | 1.2 x 2.3 x 1.25 | 1 | dish (cab, engine block), hull (cargo pod; spine, nozzles, legs), glow (windscreen, unlit) | this list | 196 | game bone `hauler` (game.as), baked parked on the pad |
| jet | effect | 0.28 x 0.66 x 0.28 | 4 (a pool) | glow (flame and a bright collar, unlit, nocast) | this list | 40 | game bones `jet0`..`jet3`, two per ship: put on its nozzles, scaled by thrust x a stepped flicker |

Bones: radar 2, habitat beacon 1, antennas 2 = 5 tracks; game bones shuttle, hauler, jet0-3 = 6;
11 of 63. Blob: 61 800 splats, 1.9 MB.

Traffic (scene/game.as): a ship every 7 s (shuttle, hauler, shuttle...), each on a 10.8 s run:
approach 3 s (a quadratic Bezier from 20 m up, 6 m out, through a point 5 m up, to a hover 1.6 m
over the pad; heading along the curve, banking with its turn rate), descent 1.4 s, parked 2.6 s,
lift-off 1.2 s (turning to the departure heading), departure 2.6 s (accelerating 18 m up and 6 m
out). The start and end points are high enough to be off the frame at every yaw at the scene's
pitch 50 (screen height of a point = 0.64 y + 0.77 x its distance away from the camera). Ships cast
shadows on the pad as they land; far above the bounds they are outside the shadow map (lit).

Glowing things (screens, windows, beacons, pad lights, stars) are `unlit` splats on the glow ramp:
they never shade, only the ink steps them down at silhouettes. The stars are a flat disc of tiny
unlit cubes 6-10 m below the rock: from a 50 degree orthographic camera they fill the dark around
the asteroid at every yaw (the sky itself is one flat colour, `horizon` 2).
