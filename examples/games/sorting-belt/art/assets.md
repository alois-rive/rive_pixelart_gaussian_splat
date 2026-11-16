# Assets: Sorting Belt, a post-office sorting room (Paper 8)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare); orthographic,
yaw 0, pitch 40, `orthoHeight` 8 m -> texel 0.0588 m. Splat spacing 0.1 m (1.7 texels) for the room
and the belt, 0.07 m for the chutes and the parcels, 0.05 to 0.06 m for small parts (signs, cleats,
twine, the clock). Palette: Paper 8 (`palette.json`), 8 colours in 8 ramps:

| Ramp | Steps (dark to light) | Used by |
|---|---|---|
| wood | navy, plum, brick, tan, cream | floor planks (tan), chutes (plum), rims and trims (tan), desk legs |
| red | navy, plum, brick, tan | red parcels and the red sign (brick), the desk top, the clock rim |
| green | navy, teal, green, pale | green parcels and the green sign (green) |
| paper | plum, brick, tan, cream | cream parcels and the cream sign, twine, mail sacks (tan), letters, the clock face |
| wall | navy, teal, green, pale, cream | wallpaper (pale with green stripes, cream dots), the teal wainscot, the window |
| rubber | navy, navy, plum, brick | the belt (plum), its cleats (brick), the clock's hands, the ink pad |
| metal | navy, teal, pale, cream | rails, legs, the intake hopper (teal), the drums (pale) |
| glow | cream, cream | confetti (unlit) |

The three parcel colours are the three most distinct hues the palette has (brick red, green, cream);
the room keeps them for the parcels and the signs only: everything else is plum, tan, teal and pale.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| chute | hero / target | 1.50 x 1.42 x 2.30 | 3 static bodies + 3 sign bones | wood, paper, red | `chute/sheet.v1.png` | ~420 | the signs (game bones, scale 1.5) wiggle on a good sort and flip edge-on to trade places every 8 parcels |
| parcel_red / _green / _cream | prop | 0.8 x 0.6 x 0.62 | 6 each (pools `red`, `green`, `cream`) | red / green / paper + twine | this list | 84 | game: drop from the hopper with a squash, ride the belt, lift and wobble while held, tumble through a flick arc, sink into a chute or bounce off and lie on the floor blinking |
| room | terrain / architecture | 16 x 7.6 floor, 16 x 5 wall | 1 | wood, wall, paper, red, rubber | this list | ~770 | |
| belt | architecture | 11 x 1.2 belt, top at 0.85; hopper 1.1 x 1.1 x 1.1 at y 2.25 | 1 | rubber, metal, wood | this list | ~370 | |
| cleat | effect | 1.1 x 0.05 x 0.14 | 12 (pool `cleat`) | rubber (brick) | this list | 20 | game: ride with the belt, wrap round the drums |
| hand | prop | 0.08 x 0.45 | 1 (`hand`) | rubber (navy) | this list | 20 | game: ticks once a second (a minute a second: a busy shift) |
| props | prop | sacks r 0.4-0.5, a desk 1.9 x 1.0 x 0.95 | 1 | paper, wood, red, rubber | this list | ~420 | |
| confetti | effect | 0.16 square | 10 (pool `bit`) | glow (unlit, nocast, specks) | this list | 24 | game: bursts out of a chute's mouth after a good sort, stepped spin |

Bones (game bones in `scene.bake.json`): 3 signs + 1 clock hand + 12 cleats + 18 parcels + 10 confetti
= 44 of 63. Splats: 53 350 in the scene blob (room 22 432, parcels 16 172, belt 5 797, chute bodies
4 837).

Layout (glTF metres, Y up, +Z towards the camera): the belt runs along X from -5.8 to 5.2 at z 0.5,
its top at y 0.85; parcels drop out of the hopper over x -5.0 and tip off the end past x 5.1. The
chutes stand at x -3.4, 0, 3.4, z -2.0 (mouths at y 1.62), their signs at y 2.16, z -2.75. Back wall at
z -3.4 (window on the left, pigeonholes on the right, the clock at (0, 3.75)); mail sacks front left,
a stamp desk front right. Play area (`"bounds"`): x -7..7, y -0.5..4.6, z -3.6..4.2.
