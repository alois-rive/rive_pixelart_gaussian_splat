# Assets: Golem Hall (URBEX 16)

Art grid: 640 x 400 artboard, `pixelSize` 2 -> 320 x 200 art pixels (322 x 202 with the spare
border). First person: a perspective look-at camera (fov 68) with the eye at 1.6 m at the hall's
near end (the origin), looking down -Z towards the far gate; `game.as` turns it (yaw +-70 degrees,
eased) and shakes it. Texel `t = 2 d tan(34) / 202`: 0.013 m at 2 m, 0.024 m at the golems' slam
distance (3.6 m), 0.054 m at 8 m, 0.14 m at the gate (22 m). Spacings: golems 0.06 (clay) / 0.05 /
0.035 (glow), the floor 0.14, walls 0.17, trim 0.14, dark passages 0.22, columns 0.11, the staff (0.6
to 1.3 m from the eye) 0.01-0.012. Nothing but the staff comes within 2 m of the eye. Palette: URBEX 16
(`palette.json`, 16 colours), a moonlit stone hall with warm braziers, terracotta golems with cyan
rune-light.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| golem | hero character | 2.2 x 1.2 x 2.3 | pool of 5, 5 game bones each (body, two arms, two legs) | clay (body, rims, band), moss (shoulders), rune (visor, chest rune, unlit) | `golem/sheet.v1.png` | 520 | game: a stepped lumber (legs and arms swing at 8 fps, roll and bob), a slow weave; the telegraph (fists climb overhead over ~1 s, shaking), the slam (a lunge, fists down, a shockwave of chunks); a hit squashes it 2 frames and staggers it back; the third-to-last hit knocks its left arm off (it tumbles to the floor); the last crumbles it (slumps, splays, sinks into the floor) |
| crack | effect | the golem's front, 6 cm proud | pool of 5 (one per golem) | rune (unlit) | this list | 228 | game: shown on a damaged golem, placed with its body |
| hall | architecture | 13 x 28 m floor, 7 m walls | 1 | stone (floor texture, walls, trim, dark passages), cloth (the gate's gloom, unlit), rune (the keystone's diamond, unlit) | this list | 1 300 | |
| pillar | architecture | 1.5 x 1.5 x 6.6 | 5 | stone, moss | this list | 70 | |
| broken | architecture | a 3.3 m stump, a fallen 1.7 m drum | 1 | stone, moss | this list | 110 | |
| brazier | prop + effect | 1.0 x 1.2, a 2.4 m pool of light | 4 | stone (iron, base), fire (coals, unlit), ember (the pool: an alpha-masked Bayer stipple, unlit) | this list | 120 | |
| flame | effect | 0.4 x 0.95 | 4 game bones | fire (unlit) | this list | 30 | game: a stepped flicker (height, width, turn) at 9 fps, out of step |
| banner | prop | 1.2 x 3.0 | 4 | cloth, stone (rod) | this list | 40 | |
| rubble | prop | 2.2 x 1.8 x 1.3 | 3 | stone, moss | this list | 120 | |
| bolt | effect | a 0.3 m core and a 0.7 m tail | pool of 4 | rune (unlit: pale core, cyan tail) | this list | 90 | game: flies at 24 m/s from the staff's orb towards the crosshair's target, turned along its path, spinning |
| chunk | effect | 0.5 m (scaled 0.25-0.5) | pool of 12 | clay | this list | 20 | game: bursts from hits, crumbles and slams, bounces twice, lies in a pool on the floor, sinks away after 3.4 s |
| spark | effect | 8 cubes on a 0.3 m sphere | pool of 3 | glint (one colour: no ink ring) | this list | 96 | game: a stepped burst where a bolt hits |
| staff | first-person prop | 0.9 m long | 1 game bone | stone (haft, prongs), clay (bands), rune (orb, unlit) | this list | 120 | game: held in the lower right, points half-way towards the crosshair, recoils on each shot, bobs |

Bones: golems 5 x 6 (body, crack, two arms, two legs) = 30, bolts 4, chunks 12, sparks 3, flames 4,
staff 1 = 54 of 63. Splats: about 98 000 (the hall 43 000, columns and props 25 000, the five golems
19 500, effects and pools the rest).

Layout (glTF metres, Y up): the player's eye at (0, 1.6, 0); side walls' inner faces at x +-6.5 from
z +4 to -24, three doorways in each (z -3, -9.5, -16.5; 2.4 m wide, 3.6 m tall) with dark passages
2.6 m deep behind; the far wall at z -24 with the great gate (3.4 x 4.6 m, a glowing keystone, a purple
gloom 5 m deep). Columns at x +-3.6, z -6, -13, -20 (the left middle one broken, its drum across the
left aisle); braziers flanking the gate (+-2.7, -22) and against the walls (+-5.6, -13); rubble at
(5.0, 1.6), (-5.2, 2.0), (-5.2, -18.6); banners on the walls at z +1 and -20.5; roof beams at z -6,
-13 (broken) and -20, 6.6 m up, under an open night sky. Golems walk the central aisle (|x| < 2.3
between the columns, < 1.4 past the gate's braziers, < 4.4 near the player) to seven slots 3.6 m from
the eye (every 22 degrees from -66 to +66): the outer slots and the near doorways are out of view at
yaw 0, so the player has to turn.
