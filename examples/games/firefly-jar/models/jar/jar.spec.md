# Jar: spec and gate record

Concept: `art/jar/sheet.v1.png` (Codex, `reviewed: false`). Measured in the front panel: the body
284 px wide = 0.5 m -> 568 px per metre; the whole jar 474 px = 0.83 m to the top of the handle.

| Part | Size (m) | Position (hedra, Z up, facing -Y) | Material (ramp, step) |
|---|---|---|---|
| Foot | octagonal frustum r 0.24 -> 0.27 x 0.04 | z 0.02 | Glass #6eb8a8 (glass 1) |
| Body | octagon, flat faces 0.25 from the axis, 0.38 tall | z 0.23 | Glass |
| Shoulder | frustum r 0.27 -> 0.19 x 0.1 | z 0.47 | Glass |
| Neck | octagon r 0.19 x 0.08 | z 0.55 | Glass |
| String band | octagon r 0.215 x 0.035 | z 0.555 | String #fcffc0 (glass 2) |
| Cloth cap | frustum r 0.235 -> 0.16 x 0.08 | z 0.61 | Cloth #c6505a (cloth 2) |
| Cloth points | 4 flattened cones r 0.09 x 0.14, pointing down | front, back, sides at r 0.205, z 0.5 | Cloth |
| Wire handle | 7 segments r 0.03, an arch 0.456 wide, 0.26 high | from the neck's sides, z 0.56 -> 0.82 | Wire #774448 (wood 1) |
| Label | 0.2 x 0.04 x 0.2 | front, y -0.255, z 0.22 | Label #ee9c5d (wood 2) |

Assumptions: the glass is drawn opaque (splats are alpha-tested); the sheet's fireflies on the glass
are not modelled: the game puts the caught ones there. The handle is 0.06 m thick (a wire would
vanish as splats). The sheet's front and top disagree on the width (front 0.5 m: the body; top
0.55 m: the handle ends): the handle reaches +-0.228, between the two.

Budgets: 344 triangles; 2 541 splats on the bench at 0.035 m (the scene bakes it at 0.05 m on a 1.5
scale: the same density relative to its size).

## Gate record (tier: generated sheet)

| Phase | View | IoU | Aspect drift | Colour drift | |
|---|---|---|---|---|---|
| p1/p2 hedra (min 0.75, 0.08) | front | 0.892 | 0.017 | 0.06 | pass |
| | right | 0.923 | 0.018 | 0.05 | pass |
| | back | 0.891 | 0.026 | 0.05 | pass |
| | top | 0.948 | 0.064 | 0.07 | pass |
| p4 splats, albedo (min 0.70, 0.08, 0.25) | front | 0.813 | 0.059 | 0.11 | pass |
| | right | 0.880 | 0.070 | 0.10 | pass |
| | back | 0.813 | 0.068 | 0.10 | pass |
| | top | 0.888 | 0.123 | 0.06 | waiver (aspect) |

Waiver (top aspect, splats): the label must stand a splat spacing proud of the glass to survive (a
coplanar overlay fights the surface), and with its splats' reach that adds about 0.06 m of depth that
the sheet's top view (the label as a line) does not have. Goldens: `goldens/jar/` (framed) and
`goldens/jar@scene/` (texel 0.027 on the unscaled bench = the scene's 0.04 at scale 1.5, the scene's
moon).
