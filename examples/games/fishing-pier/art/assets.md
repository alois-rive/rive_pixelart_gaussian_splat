# Assets: Fishing Pier (Pollen8, 8 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; a look-at side view, orthographic
9.6 m -> texel 0.072 m. Splat spacing 0.09 m (1.25 texels); small parts 0.05-0.07. Palette: Pollen8
(plum, berry, rose, pink, gold, cream, mint, teal) as 15 ramps. The sky's two roles split the frame
at the water line: pink sky above, teal sea below (`horizon` 0.38); everything under water is drawn
against that teal.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| fisher | hero | 0.75 x 0.95 x 1.3 (placed at 1.3 x, yaw 65) | 1 (`fisher`) | coat, skin, beard, boot, bucket | `fisher/sheet.v1.png` | ~370 | game: breathes (stepped), hops after a catch, flinches at a snap |
| rod | prop | 2.8 long, tilted 18 degrees | 1 (`rod`) | wood (spacing 0.05), boot (grip) | this list | 44 | game: bends with a fish on, a little while sinking |
| lure | prop | 0.26 ball + hook | 1 (`lure`) | coat (gold), wood (hook) | this list | 44 | game: sinks / reels; gone for 0.8 s after a snap |
| line | HUD | | | plum | | | `api.line` from the projected rod tip to the lure, every frame |
| fish_s / fish_m / fish_l | creatures | 0.7 / 0.9 / 1.3 long | 4 / 3 / 2 (`fs`, `fm`, `fl`) | fishy (gold), fishp (pink), fishd (berry) | this list | 68 each | game: swim across at their depth band, wiggle (stepped), hang and thrash when hooked, fly into the basket |
| jelly | creature | 0.76 x 1.0 | 3 (`jelly0-2`) | jelly (unlit) | this list | 96 | game: drift, pulse (three stepped squash poses), flash when zapped |
| pier | architecture | 4.2 x 1.8 deck, 0.9 above the water, piles to the seabed | 1 | wood (seams: specks on purpose), sun (lantern, unlit) | this list | 276 | static |
| waves / swell | effect | strips 20 m long, crests every 1.25 / 1.6 m | 1 each (`waves`, `swell`) | sea | this list | 288 / 216 | game: slide one period and wrap (12 fps), the swell behind the other way |
| seabed, rock, kelp | terrain, props | 18 x 3; 1.1; 2.4 tall | 1, 3, 4 | sand; sand; weed (sway) | this list | 300, 20, 84 | static; the kelp sways |
| island | backdrop | 4.8 wide hill, 3 m lighthouse | 1 | sand, beard, boot, sun (lamp) | this list | 86 | static, 7 m back |
| sun | backdrop | 1.6 disc | 1 (`sun`) | sun (unlit) | this list | 88 | game: sinks into the sea over the 60 s day (the clock) |
| seawall | backdrop | 18 x 6.6 plane, 5 m back | 1 | deep (one teal: invisible against the sea) | this list | 8 | static: hides the setting sun and the island's foot under the water line |
| cloud | backdrop | 2.4 wide | 2 (`cloud0-1`) | jelly (cream, unlit) | this list | 60 | game: drift, snapped to the art grid |
| splash, bubble | effects | 0.2, 0.16 | 5, 6 | sea | this list | 20 | game: drops where the lure breaks the surface; bubbles rise from two vents and the lure, pop at the surface |

Bones: 31 game bones of 63. Splats: 35 906.

Layout (glTF metres, Y up, the camera on +Z): the water line at y 0, the seabed's top near y -5.45; the
pier from off the left edge to x -3.5; the fisher on its end at (-4.55, 0.9), the rod's handle at his
hands (-4.02, 1.85), its tip at (-1.36, 2.72): the line hangs there. Fish depth bands: small -0.7 to
-1.7, middling -2.0 to -3.2, big -3.6 to -4.7; jellies -1.0 to -4.7.
