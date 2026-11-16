# Assets: skee ramp (Bubblegum 16)

Art grid: 640 x 400 artboard, `pixelSize` 2 -> 320 x 200 art pixels. Perspective look-at camera, fov 30, eye
(0, 3.3, 7.6) behind the player's end, target (0, 1.0, -0.4): 8.3 m away, the view is 4.46 m tall there, a
texel of 0.022 m at the target lane. Splat spacing 0.035 m (1.6 texels) for the played lane, the tray and the
ball (0.03); 0.05-0.08 m for the neighbour lanes, the floor and the wall (farther, context). A static camera:
perspective does not snap, but nothing turns or pans. An overhead light from the front left (yaw -30, pitch
42), `highlight` 0.92 so the lit orange lane does not jump to yellow, `edgeDepth` 1.2 (a lane is deep).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| lane | hero prop | 1.3 x 3.19 x 2.65 | 3 (the played one; two neighbours, coarser) | fire, pink, blue, dusk | `lane/sheet.v1.png` | 364 | |
| ball | prop | r 0.1 (exaggerated from 0.075) | 9 (game bones `ball0`..`ball8`) | mint | this list | 80 | game-driven: an idle bob, pulled back and squashed while aiming, rolling (stepped spin), the hop off the hump, a squash on the board, sinking into the hole, hopping from the tray to the lane |
| flash | effect | r 0.1 disc, scaled to the ring | 1 (`flash`) | fire (unlit) | this list | 28 | blinks over the ring or cup that scored |
| tray | prop | 1.1 x 0.36 x 0.51 | 1 | mint, pink | this list | 60 | |
| floor | terrain | 10 x 9 plane | 1 | dusk (40 x 36 carpet texture: zigzags, confetti) | this list | 50 | |
| wall | architecture | 10 x 3.6 + skirting | 1 | dusk | this list | 24 | |
| neon | effect | a star, a ring, a bolt, ~0.9 m each | 1 | fire, pink, mint (unlit) | this list | 160 | |

Bones: 10 of 63, all game bones. Blob: 77 000 splats (the played lane 41 500, the two neighbours and floor
and wall the rest).

Play area (`"bounds"`): x -4.5..4.5, y -0.1..4.5, z -2.3..4.5. The lane's numbers that the game uses (the foot
at z 1.595, the surface from 0.58 m to 0.90 m over 2.37 m, the hump at 2.2 m, the board from (z -0.775,
y 0.99) to (z -1.415, y 1.94), the rings centred 0.42 up the board, the cup at 0.884) are the spec's.
