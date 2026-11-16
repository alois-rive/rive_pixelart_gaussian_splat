# Assets: Moon Lander (Nyx8, 8 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; a look-at side view, orthographic
9 m -> texel 0.068 m. Splat spacing 0.1 m (1.5 texels). Palette: Nyx8 (navy-black to cream through
slate and mauves) as nine ramps sharing their darks; the flame, lamps and stars are `unlit`.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| lander | hero / player | 2.1 x 2.1 x 2.0 | 1 (`lander`) | foil, cabin, metal (legs, nozzle; 0.08), glass (window), cabin (dish) | `lander/sheet.v1.png` | ~420 | game: falls, thrusts, tilts with the pad, squashes on touchdown, stretches as the flame lights |
| moon | terrain | r 4 (front half) + crater rims, rim boulders | 1 (`moon`) | rock (body), dust (crater rims) | this list | ~1600 | game: rolls about the view axis (counter-clockwise, faster after each landing, reversing every third) |
| pad | prop | 2.4 x 2.4 x 0.6 (+ struts into the ground) | 1 (`pad`) | foil (deck), cabin (stripe), metal (struts), star (lamps, unlit) | this list | ~110 | game: rides on the moon, sinks and pops up elsewhere after a landing or a miss |
| flame | effect | 0.5 x 0.8 | 1 (`flame`) | flame (unlit, nocast) | this list | ~24 | game: flickers at 12 fps, grows as it lights |
| dust | effect | 0.5 | 6 (`dust0-5`) | dust | this list | 20 | game: kicked up by the jet near the ground, grows and fades (stepped) |
| debris | effect | 0.3 | 6 (`debris0-5`) | foil | this list | 12 | game: thrown on a crash, bounces on the moon |
| flag | prop | 0.6 x 0.9 | 6 (`flag0-5`) | metal (pole), cabin (pennant) | this list | 24 | game: planted beside each landing, turns with the moon |
| stars | backdrop | 75 specks 10 m back | 1 | star (unlit) | this list | 900 | static |
| planet | backdrop | r 1.1 with a ring 3.6 wide | 1 | planet | this list | ~500 | static, lit by the same sun (a crescent) |

Bones: 22 game bones of 63 (moon, pad, lander, flame, dust x6, debris x6, flag x6). Splats: 22 521.

Layout (glTF metres, Y up, the camera on +Z looking along -Z): the moon's centre at (0, -4, 0), its top
at y 0; the lander's feet at x 0 (it flies straight up and down; after a landing it eases back to the
middle); the play area's bounds [-7.5, -4.5, -3]..[7.5, 6, 3]; the stars 10 m back, the planet 8 m.
The moon is only its front half: it turns about the view axis, so the back is never seen.
