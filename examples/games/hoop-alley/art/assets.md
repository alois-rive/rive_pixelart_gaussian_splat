# Assets: Hoop Alley (DinoKnight 16)

Art grid: 640 x 400 artboard, `pixelSize` 2 -> 320 x 200 art pixels (202 rows with the spare). Perspective
look-at camera, fov 42, from behind and a little right of Juno: at the first spot the eye is at (0.9, 2.9,
10.4) and the target (0.15, 1.9, 0); the game eases both when she walks to another spot (eye x = 0.65 sx +
0.9 within +-3, z = sz + 6.4; target x = 0.28 sx + 0.15). Texel: 2 d tan 21 deg / 202 = 0.0038 d: 0.024 m at
Juno (6.4 m), 0.040 m at the hoop (10.4 m), 0.046 m from the far spot, 0.05 at the back wall. Splat spacing
0.028-0.035 for Juno, the balls and the rim (1.2-1.5 texels where they are seen), 0.045 for the backboard,
0.075 for the court, 0.08-0.085 for the walls (1.6-2 texels at their distance). A static camera between
walks: perspective does not snap, but nothing turns or pans except the short walk between spots.

Light: one evening sun from the front left over Juno's shoulder (yaw -30, pitch 45), `keyLight` 0.4,
`highlight` 0.88, `shadeSteps` 1 (big flat walls: no checker on the shaded faces), `edgeDepth` 0.8. The
string lights, the lamps, the vending machine's window and header are `unlit` geometry (the renderer has one
sun). Sky over the walls: navy over purple, split at 0.16 of the screen.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Splats | Motion |
|---|---|---|---|---|---|---|---|---|
| hoop | hero prop | 1.8 x 1.76 x 1.44 (board, rim, net, four arms, wall plate) | 1 (`hoop`) + the net as 3 bands | paint, blue, ball (the board's painted faces), rim, metal | `hoop/sheet.v1.png` | 236 | 3 700 + 610 net | game: slides along its wall rail in the last 20 s (x = 1.25 sin 0.95 t) |
| net | hero part | r 0.33 -> 0.215, 0.485 deep, three bands of 0.162 | 3 (`net0`..`net2`) | metal (24 x 6 chain-diamond texture), double-sided | the sheet | 3 x 24 | 610 | game: a damped swing (pitch, roll, stepped 2 deg) from rim hits and the ball's push, a stretch when a ball drops through; each band hangs from the one above (`api.transform`) |
| juno (shooter) | character | 0.48 x 0.3 x 1.62 + a bun | 1: `body` (feet to neck), `head`, `arm0`, `arm1` | kit (green jersey with a white 5, dark green shorts, yellow wristbands), skin, paint (sneakers), dusk (hair), rim (headband) | this list | 276 | 4 470 | game: faces the hoop; arms aimed at hand targets (pitch / roll solved per frame, stepped 7.5 deg); a dip while aiming, a jump and follow-through on the shot, a fist pump on a basket, a bob and arm swing when she walks to the next spot |
| ball | prop | r 0.15 (exaggerated from 0.12) | pool of 4 (`ball0`..`ball3`) | ball (orange, dark seams on the equator and a meridian so the spin reads) | this list | 120 | 4 x 285 | game: 3D physics (below), backspin stepped 30 deg |
| fire ball | effect | r 0.15 | pool of 4 (`fire0`..`fire3`) | glow (yellow, orange seams), unlit | this list | 120 | 4 x 280 | game: replaces the ball's bone while ON FIRE |
| spark / ember | effect | 0.1 | pools of 6 + 6 | spark, ember (one colour each), unlit, no shadow | this list | 20 | 260 | game: a burst under the net on a swish or a fire basket; a trail behind fire balls |
| rack (ball cart) | prop | 0.95 x 0.5 x 0.95 with 5 balls | 1 (`rack`) | metal, asphalt, ball | this list | 744 | 2 740 | game: rolls along beside Juno (sx - 1.15, sz + 0.55); lobs her the next ball |
| court | terrain | 9.2 x 12.5 plane | 1 | asphalt, paint, dusk, blue (123 x 167 drawn texture, 0.075 m a texel: worn patches, white lines, a purple key, the 3-point arc, six blue spot discs, a drain) | this list | 48 | 17 200 | |
| walls | architecture | back 9.2 x 5.6, sides 11 x 4.6, copings, the hoop's rail (5.2 m), two lamps | 1 | brick (drawn bricks 4 x 2 texels with mortar, 0.12 m a texel), dusk, ball, blue, kit, paint (murals: a setting sun over hills, a great wave with stars; a vine with leaves and a door; peaks and stars), asphalt, metal, spark (lamps) | this list | 76 | 22 700 | |
| lights | effect | three strings across the alley, 4.5 m up, sagging 0.5 m | 1 | asphalt (wire), spark / ember / cool bulbs (unlit) | this list | 1 452 | 4 900 | |
| bench | prop | 0.52 x 2.0 x 0.86 + a boombox | 1 | brick (tan slats), asphalt, blue, spark | this list | 204 | 3 170 | |
| vending machine | prop | 0.8 x 1.0 x 2.0 | 1 | blue, unlit window of cans (drawn 6 x 12), glow header, asphalt, rim | this list | 80 | 4 460 | |

Bones: 29 of 63, all game bones (hoop, net0-2, rack, body, head, arm0-1, ball0-3, fire0-3, spark0-5,
ember0-5). Blob: 66 522 splats (2.1 MB). The static world is 54 000 of them (walls 22 700, court 17 200).

Play area (`"bounds"`): x -4.7..4.7, y -0.1..5.8, z -1.7..11.

The numbers the game uses (`scene/game.as`): the rim's centre (hx, 3.05, 0), ring radius 0.335, tube 0.045;
the backboard x hx +- 0.9, y 2.83..3.96, z -0.54..-0.43; the back wall z -1.52, the side walls x +-4.6; the
net from 0.045 under the rim, 0.485 deep, radius 0.33 -> 0.215. Spots (x, z): (0, 4.0), (1.8, 3.6),
(-1.8, 3.6) for 2 points, (2.6, 5.4), (-2.6, 5.4), (0, 6.2) for 3 (outside the 5.2 m arc).

Physics (prototyped in a throwaway Python port first): gravity 9.8; the launch is 60 degrees up; the flick's
power p (speed: (px/s - 150) / 900) sets the intended range D + (p - 0.5)(1.6 + 0.25 D), so p 0.5 drops on
the rim's centre from any spot; the flick's slant x 0.25 turns the shot. Four sub-steps a frame; the rim a
torus (restitution 0.5, 85 % of the tangential speed kept), the board a box (0.55, 90 %), the ground 0.7,
walls 0.6. A ball crossing the rim's plane downward inside the ring scores; the net then funnels and slows
it. After its first bounce a ball drifts back to the cart and is taken back in. The 60-degree arc came from
the port: at 54 degrees, from the release height, almost every make touched the rim.
