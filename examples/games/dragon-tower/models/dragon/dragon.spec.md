# Dragon: spec and gate record

Concept: `art/dragon/sheet.v1.png` (Codex, `reviewed: false`). Measured in the front panel: the whole
height (feet to horn tips) 450 px = 2.1 m -> 213 px per metre; the wingspan 619 px = 2.9 m.

| Part | Size (m) | Position (hedra, Z up, facing -Y) | Material (ramp, step) |
|---|---|---|---|
| Body | 1.3 x 1.2 x 1.22, 8 x 6 sphere | 0, 0.08, 0.63 | Scale #96fbc7 (scale 1) |
| Seat (flat base) | 1.1 x 1.0 x 0.2, octagon | 0, 0.12, 0.1 | Scale |
| Back (shoulders) | 1.4 x 0.9 x 0.7 sphere | 0, 0.4, 1.05 | Scale |
| Belly plate | 0.8 x 0.42 x 1.12 sphere | 0, -0.36, 0.64 | Blush #ffb3cb (blush 1; wing in the scene) |
| Legs, feet | 0.46 x 0.7 x 0.52; feet 0.42 x 0.46 x 0.12 | x +-0.54 | Scale |
| Toes, claws | cones r 0.05 x 0.14, r 0.035 x 0.1 | front of the feet, under the arms | Horn #f7ffae (stone 2) |
| Arms | 0.2 x 0.22 x 0.34 | x +-0.31, y -0.5, z 0.92 | Scale |
| Head | 0.8 x 0.86 x 0.66 sphere | 0, -0.18, 1.62 | Scale |
| Snout | 0.46 x 0.4 x 0.32 box | 0, -0.66, 1.5 | Scale |
| Eyes, nostrils | 0.17 x 0.12 x 0.2; 0.07 x 0.04 x 0.06 | x +-0.21, y -0.52, z 1.74 | Eye #74569b (stone 0) |
| Horns | cones r 0.1 x 0.38, tilted back 18 | x +-0.25, z 2.02 | Horn |
| Back spikes | 3 cones r 0.07 x 0.2 | along the neck | Horn |
| Wings | membrane 1.36 x 0.06 x 0.72, arm 1.44 x 0.13 x 0.14; leaned back 30, tip raised 18, swept back 36 | root x +-0.34, y 0.25, z 1.12 | Blush / Scale |
| Wing claws | 3 cones r 0.05 per wing | the membrane's lower edge | Horn |
| Tail | 4 tapered segments r 0.2 -> 0.08 | out of the back, round the dragon's left (+X), ending by its left foot | Scale |
| Spade | cone r 0.12 x 0.24 | 0.84, -0.36, 0.12 | Horn |

Game parts (`p3_body.txt`, `p3_head.txt`): `dragon_body.glb` and `dragon_head.glb`, the head's origin
at the neck pivot (0, -0.05, 1.3), so the game turns and dips it there.

Assumptions: front and back lead. The sheet's views disagree about the wing and the depth: the right
view draws the wing swept back and seen face-on, reaching 1.14 m behind the body, and the whole
dragon 2.11 m deep; the top view draws the wings spread sideways and face-on and the dragon 1.79 m
deep. A flat low-poly wing can face both cameras only in part (its normal is set near
(1, 1, 1)/sqrt 3), so the right and top views cannot reach the tier. The tail is on the dragon's left
in all four panels (the brief asked for the right; the sheet is consistent, so it was kept).

Budgets: 996 triangles (over the 800 guideline: the 8 x 6 spheres; kept for the rounded read),
3 407 splats on the bench at 0.08 m (horns, claws and eyes at 0.05 m, `specks`: they are meant to
read as single art pixels).

## Gate record (tier: generated sheet)

| Phase | View | IoU | Aspect drift | Colour drift | |
|---|---|---|---|---|---|
| p1/p2 hedra (min 0.75, 0.08) | front | 0.783 | 0.045 | 0.09 | pass |
| | right | 0.705 | 0.074 | 0.12 | waiver (IoU) |
| | back | 0.794 | 0.048 | 0.12 | pass |
| | top | 0.728 | 0.055 | 0.10 | waiver (IoU) |
| p4 splats, albedo (min 0.70, 0.08, 0.25) | front | 0.796 | 0.015 | 0.14 | pass |
| | right | 0.721 | 0.101 | 0.24 | waiver (aspect) |
| | back | 0.783 | 0.002 | 0.13 | pass |
| | top | 0.703 | 0.101 | 0.15 | waiver (aspect) |

Waiver (right, top): the sheet's side and top views contradict each other on the wing pose and the
depth (2.11 m vs 1.79 m); front and back lead and pass. A sweep of wing lean, raise and sweep and of
the tail's reach (make_dragon.py's WING, TAILY and BACK) plateaued at right 0.70-0.74 and top
0.70-0.73. Goldens: `goldens/dragon/` (framed) and `goldens/dragon@scene/` (texel 0.042 on the
unscaled bench = the scene's 0.05 at scale 1.2, the scene's sun).
