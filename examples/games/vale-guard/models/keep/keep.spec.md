# Asset: keep (Boulder Keep, the cannon tower: hero, game-driven)

Concept: ../../art/keep/sheet.v1.png (Vinik24 colours, Codex), refs cut to ../../art/keep/refs/ (no flips or
rotations: the barrel points left in RIGHT and down in TOP, as asked). Up Z, facing -Y (muzzle and door);
origin on the ground under the drum's centre, the pivot the game turns it about. Scale from the FRONT
panel: the drum's foot, 1.0 m across, is 361 px -> 361 px per metre (the TOP panel is drawn ~5 % larger:
the gate compares shapes).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Drum | octagonal frustum, 1.0 across the flats at the foot, 0.9 at the top, 0.76 tall, a flat face to the front | z 0..0.76 | Stone (stone, `#9a9a97`) |
| Parapet | octagonal ring 0.95 across the flats, 0.12 tall | z 0.76..0.88 | Stone |
| Merlons | 8 blocks 0.15 x 0.15 x 0.11 (sheet 0.13 x 0.10: exaggerated, they baked to specks) at the face centres | z 0.88..0.99 | Stone |
| Door | 0.26 x 0.07 x 0.44, proud of the front face | y -0.5, z 0..0.44 | Door (wood, `#8d6268`) |
| Banner | 0.19 x 0.06 x 0.22 (no V notch: under two splats) | front face, z 0.47..0.69 | Banner (roof, `#9a4f50`) |
| Carriage | block 0.42 x 0.40 x 0.30 | z 0.70..1.00 | Wood (wood, `#c28d75`) |
| Barrel | octagonal, r 0.115, 0.72 long, tilted up 14 degrees | centre y -0.17, z 1.07 | Brass (gold, `#be955c`) |
| Muzzle ring | octagonal, r 0.14, 0.09 long; its front cap inset 0.035 as the bore | barrel's front end | Brass; bore Door |

`make_keep.py` writes `p1_blockout.txt` (every part with its material) and `p2_form.txt` (hidden bottoms
and the drum's top under the parapet removed, the bore, flat shading, the export). Hidden faces are
deleted, so `inspect check` lists non-manifold edges on the open shells (intended) and the caps as ngons.

## Assumptions
- The sheet's three side views are drawn from slightly above (the parapet's floor shows in no side view,
  but the barrel's tilt and the carriage read higher in RIGHT than FRONT): FRONT and TOP lead.
- RIGHT's barrel sits a little lower on the carriage than FRONT's muzzle suggests; the model splits the
  difference (muzzle centre 1.15 m).
- The drum's two-step slope in the side panels is a facet edge, modelled as one straight frustum.

## Gate record (generated-sheet tier: form IoU >= 0.75, aspect drift <= 0.08, splat IoU >= 0.70, splat drift <= 0.08, colour <= 0.25)
| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 | 0.944 / 0.038 | 0.918 / 0.036 | 0.948 / 0.031 | 0.964 / 0.012 | passes |
| **p2** | **0.946 / 0.038** | **0.921 / 0.036** | **0.950 / 0.031** | **0.964 / 0.012** | merlons 0.15 x 0.11 (were 0.13 x 0.10: the first bench bake warned of specks), the bore |

Splats, albedo (`lookdev/keep.bin`, baked at the scene's relative spacing: the scene bakes the keep at
x1.2 with stone at 0.07, so the bench uses 0.058 for stone and the details' spacings / 1.2):

| Render | front | right | back | top |
|---|---|---|---|---|
| IoU / aspect drift, at the renderer's default 5 / 85 degree clamp | 0.896 / 0.024 | 0.897 / 0.063 | 0.916 / 0.074 | 0.938 / 0.021 |
| IoU / aspect drift, exact views (`--arg pitchMin=0 --arg pitchMax=90`) | 0.919 / 0.038 | 0.894 / 0.038 | 0.912 / 0.016 | 0.947 / 0.023 |
| colour drift (gate palette: stone, wood, roof, gold) | 0.09 | 0.10 | 0.10 | 0.03 |

All pass. **Waiver (colour gate):** against the full palette the colour drift reads 0.31-0.35 on every
view. Vinik24's ramps share their dark and pale steps (`#433455`, `#c5ccb8`, `#5d6872` sit in six ramps), so
the sheet's shading lands on moss, plaster, frost and storm too (modeling.md, "The colour gate on
neighbouring hues"). The gate is taken against `art/keep/gate_palette.json` (the same colours, only the
hero's four ramps); the materials are right there (0.03-0.10).

Goldens: `goldens/keep` (framed) and `goldens/keep@scene` (`--texel 0.055 --size 140`: the scene's texel
0.066 / 1.2), lit like the scene (`--arg sunYaw=-35 sunPitch=50 keyLight=0.42 highlight=0.9 edgeDepth=0.45
shadeSteps=1`, `--real-sky`). The sheet is not reviewed by a person yet (`art/keep/sheet.v1.png.json`,
`reviewed: false`).
