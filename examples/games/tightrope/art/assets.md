# Assets: Tightrope (Dreamscape8)

Art grid: 640 x 400 artboard, `pixelSize` 2 -> 320 x 200 art pixels. A fixed perspective look-at camera
(fov 38) stands behind the start platform at (-14, 3.4, -2.4) and looks along the rope across the gorge
to (3, -1.8, 0.5): the walker walks away and back, and his sideways lean is a tilt on screen. A
static perspective camera has no snap offset, so the HUD stays on the art grid. Texel: 0.022 m at
the start platform (8 m), 0.06 m at the far one (22 m). Splat spacing 0.08 m, the walker 0.05, the
pole 0.045, the rope 0.04; the far rock 0.11-0.13, the plateau 0.26, the river 0.15 (seen far away or
barely). Palette: Dreamscape8 (`palette.json`, 8 colours), warm rock under a cool sky.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| walker | hero character | 2.15 x 0.5 x 1.71 | 1 (2 game bones: body, pole) | cool (clothes, sash), red (cap, scarf, slippers, skin, hair), rope (pole, weights) | `walker/sheet.v1.png` | 324 | game: lean (roll about the feet on the rope), a stepped shuffle bob, a cheer (crouch, hop, land) and a stepped turn on each platform, a tumble into the river; the pole rides in his hands (`api.transform`) and tips with the pull |
| cliffs | terrain | two cliffs, 3 strata each, 48 m along the gorge | 1 | rock (sand, rust, red-brown) | this list | 100 | |
| river | terrain | 9.6 x 30 + banks | 1 | water, rock | this list | 6 | |
| mesas | terrain | 4 blocks on the horizon | 1 | cool (fogged) | this list | 16 | |
| stand | prop | 1.1 x 1.1 x 1.5 platform with two posts | 2 | red (wood), rope (deck) | this list | 120 | |
| rope | prop | 14 x 0.08 x 0.08 along +X | 2 game bones (the spans) | rope | this list | 12 | game: each span stretched from its anchor to the walker's feet (`placeScaled` x scale, roll): the rope sags 0.32 m under him at mid-span |
| flag | prop | 0.9 m staff, 0.5 m pennant | 2 game bones | red (double-sided) | this list | 16 | game: streams towards the coming gust, flaps at 10 fps; hangs and sways in a calm |
| streak | effect | 1.6 m wind streak | pool of 8 | wind (unlit) | this list | 12 | game: blow across the gorge during a gust's warning and the gust |
| splash | effect | 1 m crown | 1 game bone | water (unlit) | this list | 140 | game: grows and falls where he hits the river |
| hawk | animal | 1.4 m wingspan | 1 game bone | red | this list | 48 | game: circles over the gorge, banking |
| cactus, rock | props | 2 m; 1.2 m | 4; 4 | cool; rock | this list | 100; 20 | |
| sun | sky | 6 m disc | 1 | wind (unlit) | this list | 44 | |

Bones: walker 2 + rope spans 2 + flags 2 + streaks 8 + splash 1 + hawk 1 = 16 of 63. Splats: 102 695.

Layout (glTF metres, Y up): the rope from x -6.9 to 6.9 at y 0 (z 0), the platforms' decks at y 0
(x +-7.45), the cliff rims at y -0.9 (inner walls at x +-6.6), the river at y -7.5. The near cliff is
only modelled where the camera sees it (x -11..-6.6, z +-8); faces turned away from the camera (+X,
the ends, the bottoms) are deleted in the command files.
