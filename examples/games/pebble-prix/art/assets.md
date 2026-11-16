# Assets: Pebble Prix (Zughy 32)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels (136 rows with the spare ones). A
high orthographic follow camera (`orthoHeight` 18, pitch 52): texel 18 / 136 = 0.132 m everywhere, so
a car (2.75 m) is about 20 art pixels long and 12 wide, the track (7 m) 53 pixels across. The camera
translates with the player's car (the target snaps to the art grid) and turns slowly after the
circuit's long-run direction (at most 46 degrees a second, usually far less). Splat spacing: the
ground 0.30 m (2.3 texels), the road 0.25, the town and the trees 0.24, the cars 0.07 (the hero's
detail must survive at 20 pixels; finer still for its lamps, grille, goggles and helmet stripe).
Palette: Zughy 32 (`palette.json`, 32 colours, 26 ramps); the sea is the renderer's sky (`horizon` 2,
a flat `sky_top` #3978a8 round the island), so it costs no splats.

The circuit (models/env/track.py): 218 m a lap, 7 m wide, counter-clockwise on an island village:
the harbour straight (the quay and the sea on the right, the line and the gantry), the lighthouse
hairpin, two switchbacks climbing past vines, the village street under a stone arch, the chapel
corner, the bridge run over the creek, the beach corner back onto the harbour. Three boost strips,
13 cones, 12 hay bales, 6 oil drums.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| racer | hero vehicle + driver | 2.75 x 1.6 x 1.37 | 4 game bones (`car0`..`car3`), one model in four paint jobs | red / blue / pink / gold (body, helmet stripe), white, tyre, peach, navy, stone | `racer/sheet.v1.png` | 476 | game: driven (yaw with a drift slide, roll in turns, a bounce on bumps, a rattle off the track) |
| ground | terrain | the island, 90 x 60 | 1 | grass (two greens), sand, plaster (paving), stone (rock, the quay's face), sea (creek, pond), foam (unlit) | this list | 24 375 | |
| road | terrain | the 218 m ribbon, 7 m wide | 1 | road, red + white (kerbs on every corner), road + white (the chequered line), glow (boost chevrons, unlit) | this list | 12 208 | |
| town | architecture | houses 4.5-6.5 x 5-6 x 3.6-4.8 (+ 1.4 roof), the arch (2.5 x 11.2 x 5.8), the chapel and its 7.8 m tower, the lighthouse (7.4 + 0.9 m), the bridge, dry-stone walls (0.5 x 0.7), the gantry (4.6 m), the quay's bollards, crates, net, jetty; hay bales (1.5 x 0.9 x 0.65), oil drums (0.84 x 0.95) | 1 | white, peach, rose (walls), roof, navy (windows), wood, stone, red (lighthouse bands), glow (its lantern, unlit), gold (hay), sea / red (drums) | this list | 2 964 | |
| trees | foliage | cypresses 3.2-4.4 m, round trees 1.3-1.8 m canopies, vines 0.75 m | 1 | leaf (sway), wood, grass | this list | 1 062 | sway |
| cone | prop | 0.64 x 0.75 | pool of 13 | orange, white, navy | this list | 66 | game: knocked flying (spin, bounce, lie down) |
| boat | prop | 2.0 x 5.2 x 1.65 | 2 game bones | white, sea, pink, red | this list | 43 | game: bobbing and rolling at 8 fps |
| flag | prop | 2.8 m pole, 1.35 x 0.9 chequer | 1 game bone | navy, road, white | this list | 36 | game: waves (faster once you finish) |
| lamp, golamp | effect | 0.6 m glows on the gantry | 3 + 1 game bones | lamp, lime (unlit) | this list | 36 | game: the start lights |
| flame | effect | 1.05 m boost flame | 4 game bones | glow (unlit) | this list | 48 | game: on a boosting car's exhaust, flickering |
| puff | effect | 0.9 m smoke | pool of 12 | smoke | this list | 36 | game: drift smoke from the rear wheels, stepped growth |
| dust | effect | 0.8 m dust | pool of 6 | dust | this list | 36 | game: off the track |
| spark | effect | 1 m burst | pool of 4 | glow (unlit) | this list | 72 | game: bumps |
| gull | animal | 2 m wingspan | 2 game bones | white, navy | this list | 20 | game: circling the harbour, flapping |

Bones: cars 4 + flames 4 + puffs 12 + dust 6 + sparks 4 + cones 13 + boats 2 + flag 1 + lamps 4 +
gulls 2 = 52 of 63, all game bones (no baked tracks). Splats: 106 802 (ground 31.3k, town 31.1k,
road 21.3k, trees 5.4k, the four cars 9.8k, the pools 7.7k): over the ~100k guide by 7 %; every
square metre of the island is within the camera's reach of the track (none is wasted), and the
cars keep their detail.

Layout (glTF metres, Y up, X east, Z south): the start line at (-6, 0, 0) heading +X; the island from
X -41 to 40.5, Z -55.5 to 5.6; the sea below y -1.0. Faces nobody sees (house walls against a
neighbour, the undersides) are not generated; the road sits flush in a hole cut out of the ground
(marching squares on the distance to the centreline), so nothing is layered.
