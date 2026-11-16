# Asset: lane (hero prop, the skee-ball machine)
Concept: ../../art/lane/sheet.v1.png (Bubblegum 16 colours), refs cut to ../../art/lane/refs/.
Up Z, facing -Y (the player's end); origin on the ground under the middle. 1.3 x 3.19 x 2.65 m.

Scale: the cabinet's front width, 226 px in the front panel = 1.3 m (174 px a metre); the right view at the
same scale (554 x 461 px = 3.19 x 2.65 m). The top panel is drawn smaller (146 px a metre) in proportion.

## Parts (metres, y from the front at -1.595)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Base | 1.3 wide, y -1.595..0.775, top sloping 0.52 -> 0.84 | | Cabinet (pink, #94216a) |
| Lane surface | 1.04 wide, 8 cm thick, top 0.58 -> 0.90 | | Lane (fire, #ff8426) |
| Rails | 0.13 wide, tops 0.68 -> 0.98 | x +-0.585 | Rail (pink, #ff2674) |
| Hump | 1.04 x 0.17 x 0.12 | y 0.605..0.775, z 0.89..1.01 | Lane |
| Under the target | 1.3 x 0.64 x 0.99 | y 0.775..1.415 | Cabinet |
| Target walls | 0.13 thick, 1.27 tall at the front sloping to 1.94 | x +-0.565 | Rail |
| Board | 0.93 x 1.145 x 0.06, leaning back 34 degrees, (y 0.775, z 0.99) to (y 1.415, z 1.94) | | Board (blue, #234975) |
| Rings | stepped discs r 0.38 / 0.30 / 0.20 and a hole r 0.09, centred 0.42 up the board | | White (blue, #fafdff), Blue (#68aed4), Hole (dusk, #16171a) |
| Cup | r 0.11, 0.884 up the board | | Hole |
| Backboard, marquee | 1.15 x 0.18 x 2.35; 1.15 x 0.18 x 0.3, top corners cut | y 1.415..1.595 | Cabinet; Marquee (fire, #ffd100; unlit in the scene) |

## Assumptions
- The sheet's front view is drawn from a little above (the lane surface shows); its proportions still match
  the model's front silhouette (IoU 0.955).
- Every downward face is deleted after the join (on the ground, under the rails, the lane, the marquee):
  29 100 -> 24 200 splats on the bench.
- 364 triangles.

## Gate record (generated-sheet tier, chosen before the build)
- p1 blockout and p2 form: **IoU 0.955 / 0.986 / 0.962 / 0.983, aspect drift 0.008 / 0.008 / 0.089 /
  0.022** (`--min-iou 0.75`, drift <= 0.08).
- p4 splats, albedo, bench at the scene's spacing (0.035): **IoU 0.943 / 0.896 / 0.930 / 0.958, aspect
  drift 0.058 / 0.026 / 0.128 / 0.045, colour drift 0.06 / 0.01 / 0.03 / 0.06** (`--min-iou 0.7`).
- **Waiver, back view aspect** (0.089 mesh, 0.128 splats): the sheet's back view shows only the 1.15 m
  backboard, while its front and top views show a 1.3 m base and rails that must stick out behind it from the
  back. The sheet contradicts itself; the front and top views lead. Every other view and measure passes.
- Goldens: `goldens/lane` (framed), `goldens/lane@scene` (texel 0.022, 200 px), lit as the scene.
