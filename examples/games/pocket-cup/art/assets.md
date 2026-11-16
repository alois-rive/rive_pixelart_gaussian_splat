# Pocket Cup: the asset list

Art grid: 640 x 400, `pixelSize` 3 (213 x 133 HUD pixels, 136 art rows). Camera: orthographic orbit,
yaw 0, pitch 34, `orthoHeight` 9 m: texel 9 / 136 = **0.0662 m**. A 1.6 m footballer is ~20 to 22 art
pixels tall. The game moves the target after the ball (x -7.4..7.4, z -3.6..0.2).

Play area (bake `bounds`): x -15..15, y 0..4.6, z -12.5..9. The pitch: goal lines x +-11, touchlines
z +-6, the fence (the ball's walls) at x +-12.6, z +-7.2; goals 3.2 x 1.5 m, 0.9 m deep.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Triangles | Motion | Notes |
|---|---|---|---|---|---|---|---|---|
| `player` | hero / character | 0.89 x 0.40 x 1.60 | 6 players (body + 2 legs each) + 8 supporters (body only) | coral, sky, gold, violet, pink, teal (shirts); chalk, navy (shorts); skin; wood (hair); boot; navy (eyes) | sheet v1 (Codex) | 252 (body 180, leg 36) | game-driven: 3 bones a player (run cycle, kick, lunge, stagger, the keeper's dive by roll), 1 a supporter (sway, jumps) | spacing 0.06; p3 splat fit; eyes `specks` |
| `ground` | terrain | 30 x 21.5 | 1 | grass, chalk, verge, wood (texture, no ramp: each texel finds its ramp) | from this list | 256 | none | pitch.png 252 x 144 (0.1 m a texel: mowing stripes 2.1 m, chalk lines 0.2 m = 2 splats, worn goalmouths); verge.png 48 x 48 |
| `fence` | architecture | 25.2 x 14.4 x 0.95 | 1 | wood, gold | from this list | 480 | none | posts 0.12 m, rails 0.14 x 0.06 m (gaps 0.24 m: 3 splats); gold pennants on 1.6 m corner posts; spacing 0.06 / 0.08 |
| `goal` | prop | 3.3 x 1.0 x 1.55 | 2 (yaw +-90) | chalk | from this list | 80 | none | square bars 0.1 m; net panels alpha-masked (0.3 m cells, 0.075 m strands, `double`), spacing 0.035 so the holes stay open |
| `tree` | foliage | 2.5 x 2.5 x 4 | 6 | wood, leaf | from this list | 56 | none | two icosahedron crowns; spacing 0.12 (painterly) |
| `ball` | prop | 0.4 | 1 (bone) | chalk, navy | from this list | 20 | game: rolls (pitch about its heading), flies | 0.2 m radius: pixel-art big (6 art pixels); dark patches show the roll |
| `ring` | effect | 1.1 x 0.04 | 1 (bone) | mark (unlit, nocast) | from this list | 128 | game: under your player, turning | |

Bones: 28 of 63 (p0..p5, p0L/R..p5L/R, ball, ring, fan0..fan7). Splats: 83 574 (ground 39.8k: pitch and
verge; fence 11.2k, goals 10.2k, trees 9k, bodies 11.1k, legs 1.6k, ball and ring 0.6k).
