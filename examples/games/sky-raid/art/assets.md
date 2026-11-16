# Assets: Sky Raid (Fantasy 24)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 HUD pixels (136 art rows). Orthographic, yaw 0,
pitch 60, `orthoHeight` 9.549657 m -> texel 0.070218 m (chosen so the game's 12 m world wrap is exactly 148
art rows along the view: 12 sin 60 / texel). The view shows about 15 x 11 m of ground. Splat spacing: the
flat ground 0.14 m (2 texels), the things on it 0.10, the game pieces 0.05-0.08, the hero 0.035-0.05.
Palette: Fantasy 24 (`palette.json`, 24 colours) in 13 ramps; the glows (pops, shots, enemy bullets, a
drone's eye, the airship's exhausts) are `unlit`.

hedra models are built up Z, front -Y (the GLB's front faces the camera: DOWN the screen). The terrain
tiles' far edge (+Y in hedra) is up the screen.

| Asset | Class | Size (m) | Instances / bones | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| plane | hero (the player) | 1.8 x 1.58 x 0.93 | 1 bone `plane` | canvas, paint, metal | `plane/sheet.v1.png` | 342 | game: follows the pointer, banks, pitches, bobs |
| prop | hero part | 0.7 two-blade | 1 bone `prop` | metal | (the sheet) | 12 | game: spins on the nose (stepped 57 degrees a frame) |
| fieldsA/B | terrain tile | 16 x 6 | 2 bones | grass, leaf, wheat, soil | this list | ~1.5k | game: recycled ahead of the camera |
| villageA/B | terrain tile | 16 x 6 | 2 bones | grass, wall, roof, leaf, wheat, soil, water | this list | ~1.5k | game (A: church and pond, B: windmill) |
| woodsA/B | terrain tile | 16 x 6 | 2 bones | grass, leaf, soil, wall, roof | this list | ~1.4k | game (A: dark moss floor, B: meadow floor) |
| riverA/B | terrain tile | 16 x 6, river 2 wide | 2 bones | water, soil, grass, leaf, wheat, wall | this list | ~1.2k | game: a gunboat sails each river tile the waves ask for |
| balloon | enemy | 1.1 x 1.1 x 1.9 | 3 bones | roof, canvas, soil | this list | ~150 | game: drifts down, sways, fires slow aimed shots |
| supply | enemy (power-up carrier) | 1.1 x 1.1 x 2.0 | 1 bone | wheat, canvas, soil, metal | this list | ~160 | game: drops the crate when popped |
| boat | enemy (ground) | 0.72 x 1.9 x 0.6 (x1.25) | 2 bones | metal, roof, wall | this list | ~60 | game: sails along a river tile, rolls, sinks |
| turret | enemy part | 0.44 drum, 0.45 barrel (x1.25) | 2 bones | metal | this list | ~40 | game: on the boat's deck, tracks the plane |
| drone | enemy | 0.84 across | 6 bones | metal, water (rotors), glow (eye) | this list | ~200 | game: V dives, sweeps on a wave, boss dives |
| airship | boss | 5.2 x 1.6 x 1.8 (2.6 with pods) | 1 bone `boss` | wall, roof, metal, glow | this list | ~300 | game: enters, patrols broadside, turns nose-down at each end, sinks |
| bossgun | boss part | 0.6 drum, twin barrels | 2 bones | metal | this list | ~60 | game: two turrets on top, track the plane |
| shot | effect | twin bolts 0.12 x 0.5, 0.32 apart | 14 bones | shot (unlit) | this list | 24 | game |
| bullet | effect | 0.44 ball | 12 bones | foe (unlit; the ink rings it red-orange) | this list | 20 | game: rises to 3 m, pulses |
| pop | effect | 1.6 star (12 spikes) | 5 bones | glow (unlit) | this list | ~70 | game: grows in 0.07 s, shrinks away (scaled down only) |
| crate | power-up | 0.84 chute over a 0.32 crate | 1 bone | canvas, paint, soil, wall, metal | this list | ~80 | game: drifts down, swings |

Bones: 8 tiles + 1 plane + 1 prop + 14 shots + 12 bullets + 3 balloons + 1 supply + 2 boats + 2 turrets
+ 6 drones + 1 boss + 2 boss turrets + 5 pops + 1 crate = 59 of 63 (all game bones, no baked tracks).
Splats: 93 056 (the eight tiles 73 343, the pieces 19 713; the hero 2 943 + 99 for its propeller).

Ramps (dark to light; the painted step in brackets):

| Ramp | Colours | Used by |
|---|---|---|
| grass | #1f240a #39571c #a58c27 | meadow (1), pasture (2), the woods' moss floor (0) |
| leaf | #1f240a #183f39 #39571c #a58c27 | tree canopies, hedges, reeds (2), pines (1) |
| wheat | #724113 #a58c27 #efac28 #efd8a1 | wheat strips (2, 1), haystacks, the supply balloon's gores |
| soil | #36170c #45230d #724113 #ab5c1c | furrows (2, 1), sandy banks (3), trunks, wicker |
| water | #183f39 #276468 #3c9f9c #efd8a1 | river and pond (1), ripples and drone rotors (2) |
| roof | #300f0a #550f0a #9b1a0a #ef3a0c | roofs, balloon gores, fins (2), the airship's bands (1) |
| wall | #392a1c #684c3c #927e6a #efd8a1 | cottage walls (3), lanes, stone, the airship (2), planks (1) |
| canvas | #773421 #a56243 #efb775 #efd8a1 | the plane's wings, balloon and chute gores (3) |
| paint | #550f0a #9b1a0a #ef3a0c #ef692f #efb775 | the plane's fuselage, fin and tips, chute gores (3) |
| metal | #2a1d0d #392a1c #684c3c #927e6a | cowl, struts, hulls, drones, turrets, the gondola |
| glow | #9b1a0a #ef3a0c #ef692f #efac28 #efd8a1 | pops, a drone's eye, exhausts (unlit) |
| shot | #a58c27 #efac28 #efd8a1 | the plane's bolts (unlit, painted on the top step) |
| foe | #550f0a #ef3a0c #efd8a1 | enemy bullets (unlit, top step; the ink rings them in #ef3a0c) |

Roles: no sky shows (the ground fills the view; `horizon` 2): sky_top and sky_bottom #39571c, void #1f240a.

Every pool piece is baked at full size and only scaled down (a pop) or squashed a little by the game: a
splat's size does not follow its bone's scale.
