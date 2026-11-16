# Assets: a toy carnival on a round plaza (PICO-8)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels. Perspective camera, fov 40, 12 m from a
target 0.9 m above the plaza's centre: 2 x 12 x tan 20 = 8.7 m at the target over 133 rows, texel 0.066 m.
Splat spacing 0.09 m (1.4 texels at the target; nearer props get bigger splats). Palette: PICO-8
(`palette.json`, 16 colours; black is only the void).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Animation |
|---|---|---|---|---|---|---|---|
| plaza | terrain | 12.4 x 12.4 x 2.5 | 1 | pink (tiles texture), stone (kerb), green, wood (earth) | this list | 108 | |
| carousel | hero prop | 3.0 x 3.0 x 3.42 | 1 | blue, gold, pink, red, cream, green | `carousel/sheet.v1.png` | 860 | rotor rigid, 1 turn / 8 s, linear; 6 horses rigid (children of the rotor), bob 0.3 m / 2 s, eased; 12 fps |
| tent | prop | 2.9 x 2.9 x 2.75 | 1 | cream, blue, red, gold | this list | 74 | |
| stall | prop | 2.1 x 1.2 x 2.75 | 1 | pink, cream, wood, red (awning texture), gold, green, blue | this list | 236 | |
| balloons | prop | 1.0 x 0.6 x 3.0 | 2 (phase 0, 1.3 s) | stone, cream, red, blue, gold | this list | 260 | bunch rigid, a 16 degree conical sway / 3 s, 12 fps |
| lamp | light prop | 1.2 x 0.5 x 2.6 | 3 | stone, glow (unlit) | this list | 112 | |
| tree | foliage | 1.2 x 1.2 x 1.85 | 8 (0.75-1.15) | wood, green | this list | 40 | |

Bones: carousel 7 (rotor + 6 horses), balloons 1 each: 9 of 63. Blob: 85 400 splats.
The horses' bob is keyed on each horse (eased) while the rotor's turn is linear: `keyframe interpolation
linear --all` runs before the horses are keyed, so it only reaches the rotor.
