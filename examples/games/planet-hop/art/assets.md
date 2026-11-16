# Assets: Planet Hop (hept32, 32 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels (136 rows with the spare); a look-at
side view of the play plane (glTF x-y), orthographic 10 m -> texel 0.0735 m. Splat spacing 0.11 m
(1.5 texels; the rocket 0.1, small parts 0.05-0.08). Palette: ENDESGA's hept32 in 14 ramps (hull, trim,
glass, rock, grass, soil, sand, candy, ice, lava, glow, nebula, space, plus the one-colour star ramps
`stary` and `starw`). Space is a flat royal blue (#1831a7, `sky_top`, `horizon` 2), not black: a bright
toy cosmos. The flame, star field, nebula, collectable stars, sparks and lava are `unlit`.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Splats | Motion |
|---|---|---|---|---|---|---|---|---|
| rocket | hero / player | 0.96 x 0.96 x 1.4 | 1 (`rocket`) | hull, trim, glass (porthole), rock (rim, nozzle) | `rocket/sheet.v1.png` | 228 | 673 | game: orbits, launches along the tangent (stretch), is caught (squash), shudders as an orbit decays |
| meadow | planet | r 1.5 + pines, house | 1 (`meadow`) | grass, soil, hull, trim, rock | this list | ~900 | 2019 | game: placed in the chain, turns slowly about the view axis, pops when the rocket arrives |
| dune | planet | r 1.5 + cacti, pyramid, crater rims | 1 (`dune`) | sand, grass | this list | ~800 | 1900 | as meadow |
| ice | planet | r 1.5 + crystal spikes | 1 (`ice`) | ice | this list | ~400 | 1597 | as meadow |
| mushroom | planet | r 1.5 + five mushrooms, pale patches | 1 (`mushroom`) | candy, hull, trim | this list | ~600 | 1781 | as meadow |
| lava | planet | r 1.5 + volcanoes, glowing cracks | 1 (`lava`) | rock, lava (unlit) | this list | ~500 | 1615 | as meadow |
| giant | planet | r 1.5 banded, ring 4.5 across | 1 (`giant`) | sand, trim, glass | this list | ~800 | 2723 | placed, no spin (its ring would wheel round) |
| star | pickup | 0.95 across | 3 (`star0-2`) | glow (unlit) | this list | ~40 | 349 | game: bobs, ticks round in 12-degree steps, pulses |
| flame | effect | 0.44 x 0.7 | 1 (`flame`) | glow (unlit, nocast) | this list | 24 | 167 | game: flickers at 12 fps, long in flight, short in orbit |
| puff | effect | 0.4 | 8 (`puff0-7`) | hull (nocast) | this list | 20 | 385 | game: the exhaust trail, grows and shrinks in steps |
| spark | effect | 0.16 | 8 (`spark0-7`) | stary (unlit) | this list | 12 | 189 | game: a burst at each capture, star and crash |
| chunk | effect | 0.44 x 0.27 | 6 (`chunk0-5`) | hull, trim (nocast) | this list | 20 | 310 | game: thrown by a crash |
| stars | backdrop | 20 x 13 tile, 70 specks | 2 (`sky0-1`) | starw, stary (unlit) | this list | ~1200 | 737 | game: two tiles leapfrog with parallax 0.15 |
| nebula | backdrop | 20 x 10 tile: six puff clouds, two far planets | 2 (`nebula0-1`) | nebula (unlit), candy, soil | this list | ~2000 | 2682 | game: parallax 0.35 |

Bones: 37 game bones of 63. Splats: 17 127 in the scene blob.

Layout: the game plays in the plane z 0 (glTF). The camera never moves: the game keeps a world
coordinate per object and draws it at (world - camera), with the camera snapped to whole texels, so the
bounds ([-9, -6, -13] .. [9, 6, 3]), the shadow map and the art grid stay put while the chain of planets
runs off to the right. Planets are generated ahead (5.6 to 9.5 m apart, up to 42 degrees up or down,
y within +-2.3) and their six bones are used in turn (meadow, dune, ice, mushroom, lava, giant), scaled
0.72 to 1.0 (baked at the largest size). The star field sits 12 m back, the nebula 11 m.
