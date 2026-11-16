# Walker: spec and gate record

Concept: `art/walker/sheet.v1.png` (Codex, `reviewed: false`). Measured in the front panel: 1.7 m tall
= 470 px -> 276 px per metre; the pole with its weights 596 px = 2.16 m.

| Part | Size (m) | Position (hedra, Z up, facing -Y) | Material (ramp, step) |
|---|---|---|---|
| Legs | 0.12 x 0.14 x 0.76 each | x +-0.065, z 0.46 | Cloth #63787d (cool 2) |
| Slippers | 0.13 x 0.3 x 0.09 | x +-0.07, y -0.06 | Red #8b4049 (red 1) |
| Hips, torso | 0.3 x 0.2 x 0.14; 0.34 x 0.22 x 0.3, top widened 1.15 | z 0.86; z 1.16 | Cloth |
| Sash | 0.33 x 0.23 x 0.12 | z 0.96 | Sash #8ea091 (cool 3) |
| Arms | upper 0.1 x 0.12 x 0.3, fore 0.1 x 0.18 x 0.1 | x +-0.235 | Cloth |
| Hands | 0.12 cubes | x +-0.235, y -0.16, z 0.97 | Skin #caa05a (red 3) |
| Scarf, tails | 6-gon r 0.12 x 0.1; tails 0.08 x 0.04 x 0.46-0.5 | neck z 1.36; tails y 0.2 | Red |
| Head, hair | 0.22 x 0.24 x 0.24; hair 0.235 x 0.15 x 0.2 | z 1.5 | Skin; Hair #543344 (red 0) |
| Cap, brim | frustum r 0.135 -> 0.07 x 0.13; brim 0.2 x 0.2 x 0.04 | z 1.64; y -0.18 | Red |
| Pole | 6-gon r 0.04 x 1.96 (the sheet draws 0.045 thick: exaggerated to 0.08) | y -0.16, z 0.97 | Pole #c9cca1 (rope 3) |
| Weights | icospheres r 0.09 | x +-1.0 | Weight #ae6a47 (rope 1) |

Game parts (`p3_body.txt`, `p3_pole.txt`): `walker_body.glb` (origin between the feet: he leans about
them) and `walker_pole.glb` (origin at the hands, (0, -0.16, 0.97)).

Assumptions: front leads. The views disagree: the front makes the pole 2.16 m, the top 2.27 m; the
side makes him 0.48 m deep, the top 0.55 m. The pole sits 0.16 m in front of the body as the top
view shows it (the side view would have it 0.28 m out).

Budgets: 324 triangles; 1 533 splats on the bench at 0.05 m (the pole 0.045).

## Gate record (tier: generated sheet)

| Phase | View | IoU | Aspect drift | Colour drift | |
|---|---|---|---|---|---|
| p1/p2 hedra (min 0.75, 0.08) | front | 0.855 | 0.003 | 0.02 | pass |
| | right | 0.751 | 0.028 | 0.03 | pass |
| | back | 0.849 | 0.002 | 0.07 | pass |
| | top | 0.740 | 0.043 | 0.07 | waiver (IoU) |
| p4 splats, albedo (min 0.70, 0.08, 0.25) | front | 0.717 | 0.046 | 0.11 | pass |
| | right | 0.730 | 0.157 | 0.15 | waiver (aspect) |
| | back | 0.726 | 0.028 | 0.06 | pass |
| | top | 0.759 | 0.211 | 0.14 | waiver (aspect) |

Waivers: top IoU (hedra): the top view's widths and depths disagree with the front and side views
(above); moving the pole towards the body for the top made the side worse. Side and top aspect
(splats): a figure 0.48 m deep gains about two splat radii (0.1 m) of depth at a one-texel spacing,
20 % of its depth; the front, the view the camera mostly sees, holds at 0.046. Goldens:
`goldens/walker/` (framed) and `goldens/walker@scene/` (texel 0.045, mid-rope; the scene's sun).
