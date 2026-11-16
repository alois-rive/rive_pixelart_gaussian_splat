# Asset: carousel (hero prop, animated)
Concept: ../../art/carousel/sheet.v1.png (PICO-8 colours), refs cut to ../../art/carousel/refs/.
Up Z, facing -Y; origin at the ground under the axis. Total height 3.42 m (flag top).

Scale: the platform's front width, 410 px in the front panel = 3.0 m (137 px a metre). The side views are
drawn from about 3 degrees above (the platform top shows 20 px deep): gate views at `--elevation 4`.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Platform | 8-gon, 3.0 flat to flat, 0.34 tall | z 0..0.34 | Blue sides (blue, #29adff), Orange top (gold, #ffa300) |
| Column | 8-gon r 0.2 | z 0.34..2.02 | Pink (pink, #ff77a8) |
| Poles | 6, r 0.05 (sheet: 0.06 thick, exaggerated), on a ring r 0.96 at 0, 60 .. 300 degrees | z 0.34..2.02 | Yellow (gold, #ffec27), spacing 0.06 |
| Band | 8-gon r 1.55, 0.29 tall | z 2.0..2.29 | Yellow |
| Cone | 8 faces, r 1.55 -> 0.04, 0.67 tall; faces alternate | z 2.29..2.96 | Red (red, #ff004d) / Cream (cream, #fff1e8), the front face red |
| Ball, flag pole, flag | r 0.11; r 0.035 x 0.32; 0.3 x 0.05 x 0.18 pointing +X | z 3.04; 3.1..3.42 | Yellow; Flag (green, #00e436, two-sided) |
| Horse (x6) | body 0.23 x 0.69 x 0.28, neck, head, two leg blocks, saddle, mane, tail; 0.9 long, 0.85 tall | body centre z 1.3 (high) / 1.0 (low), facing counter-clockwise | Cream; Pink saddle; Mane (red, #7e2553), spacing 0.06 |

## Assumptions
- The sheet draws every horse side-on in the front view, which no ring of horses can do; the ring's poles
  sit on the X axis (the front view's outer poles). Turning the ring 30 degrees to put a horse in front of
  the column, as drawn, dropped the back view's IoU to 0.748: reverted.
- The flag points +X in the front and top views and -Y in the right view: front and top lead.
- 860 triangles (6 horses of 8 boxes): over the 800 budget by the horses' boxes; they are the read.

## Animation
`Rotor` (platform, column, poles, canopy, flag joined, origin on the axis) turns +360 degrees about Z
(counter-clockwise from above, the way the horses face) in 192 frames at 24 fps, linear: one turn in 8 s.
`Horse0` .. `Horse0.005` are children of the rotor (`parent set Rotor`) and bob 0.3 m every 2 s (eased
keys every 24 frames), the high ones down while the low ones go up. Exported `--bake-animations`, baked at
12 fps: 7 bones, one 8 s track.

## Gate record (generated-sheet tier, chosen before the build)
- p1 blockout (one horse, the other five are duplicated in p2), hedra `--elevation 4`: IoU 0.715 / 0.704 /
  0.707 / 0.988, aspect drift <= 0.03. Fails on the missing horses (worst at 0.66 of the height: ref 0.85,
  model 0.30), closed by p2.
- p2 form v1: IoU 0.784 / 0.769 / 0.783 / 0.988 (pass); v2 ring turned 30 degrees: back 0.748 (fail,
  reverted); v3 horses 1.15 x: **IoU 0.787 / 0.780 / 0.783 / 0.988, aspect drift 0.027 / 0.022 / 0.026 /
  0.000** (`--min-iou 0.75 --max-aspect-drift 0.08`).
- p4 splats, albedo, bench at the scene's spacing (0.09): **IoU 0.759 / 0.752 / 0.763 / 0.970, aspect drift
  0.017 / 0.005 / 0.010 / 0.023, colour drift 0.11 / 0.14 / 0.11 / 0.04** (`--min-iou 0.7`). No waivers.
- Goldens: `goldens/carousel` (framed, 320 px, pixel 2), `goldens/carousel@scene` (texel 0.066, 160 px).
