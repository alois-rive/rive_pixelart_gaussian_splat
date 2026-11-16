# Asset: labyrinth (hero; the box is static, its floor and two knobs are game bones)
Concept: ../../art/labyrinth/sheet.v2.png (WoodSpark colours), refs cut to ../../art/labyrinth/refs/
(no flips or rotations). `sheet.v1.png` drew the RIGHT panel as a copy of the front (the long side);
v2 restates first that the right panel shows the short side. Up Z, facing -Y (the front knob);
origin on the ground under the box's centre. Scale from the FRONT panel: the box 630 px for 9.0 m ->
70 px per metre. The sheet's side views are drawn from about 3 degrees above (the top's inner rim
shows: 24 px of a 420 px deep top): the gate views use `--elevation 3`.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Box | 9.0 x 6.3 x 1.5, walls 0.45 thick, hollowed 0.6 deep | z 0.45 .. 1.95 | Frame (wood, #e08d51), the wall tops Rim (#fabf61) |
| Floor | 8.0 x 5.3 plank, top at z 1.35 | inside the box | Plank (wood, #fabf61) with five 0.2 m Seam strips (#e08d51) across |
| Feet | four blocks 0.9 x 0.9 x 0.45 | x +-3.82, y +-2.5 | Dark (wood, #8a5865) |
| Axles | 0.3 x 0.3 x 0.3 | front wall middle, right wall middle, z 1.13 | Dark |
| Knobs | octagonal discs 1.4 across, 0.42 thick | y -3.66 (front), x 5.01 (right), z 1.13 | Knob (berry, #f05b5b) |

`p1_blockout.txt` (primitives), `p2_form.txt` (the tray hollowed, the floor seams, materials, hidden
faces deleted: the mesh gate's model), `p3_splat_fit.txt` (for the splats only, below; the bake and
the splat gate use it), `p4_parts.txt` (run with `--no-save`: `frame.glb` the static box with feet and
axles, `floor.glb` the tilting floor with its origin at its top centre, `knob.glb` one knob with its
origin on its axle). 1 944 triangles, 1 800 of them the floor's 30 x 30 grid that carries the seams
(a painted texture would do the same; the box itself is 88).

## Assumptions
- The sheet's views disagree on the depth: 6.0 m from the top view, 6.5 m from the right view
  (against the front's scale). Front and top lead; the box is 6.3 deep as a compromise, and the right
  view takes a waiver on its aspect.
- The brief asked for 0.8 m walls and 0.9 m knobs; the sheet drew 1.5 m walls and 1.4 m knobs. The
  spec measures the sheet.
- The sheet's floor is a plain #fabf61; the model adds five seam strips (a plank floor reads as wood
  at the scene's texel, and the seams show the tilt).

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`, `--elevation 3`):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.946 / 0.052 | 0.930 / 0.102 | 0.922 / 0.059 | 0.960 / 0.021 | box 6.0 deep (the top view's depth) |
| **p1 v2 = p2** | **0.939 / 0.043** | **0.940 / 0.052** | **0.935 / 0.050** | **0.933 / 0.018** | 6.3 deep (between the top and the right view) |

Splats, albedo, on p2 (spacing 0.09 = the scene's): IoU 0.902 / 0.903 / 0.908 / 0.927, aspect drift
**0.111 / 0.244 / 0.103** / 0.031: each disc grows a radius past the flat tops and bottoms, so the
flat box comes out 10 % too tall. This is the case for a splat-fit phase (the skill's modeling.md):
`p3_splat_fit.txt` squashes the whole box to 0.88 of its height about the ground and moves the knobs
0.08 m out. On p3: IoU 0.896 / 0.887 / 0.900 / 0.956, aspect drift 0.002 / **0.100** / 0.005 / 0.031,
colour drift 0.06 / 0.04 / 0.06 / 0.03 (<= 0.25).

**Waiver, right view, splats** (aspect drift 0.100 > 0.08): the right view's 6.5 m depth disagrees
with the top view's 6.0 (above); front and top lead.

`hedra inspect check`: ngons on the knob caps (harmless, triangulated on export); open edges where
the hidden faces were deleted on purpose (the box's underside, the feet's tops, the floor's sides).

Goldens: `goldens/labyrinth` (framed), `goldens/labyrinth@scene` (`--texel 0.0603`, the scene's,
`--size 400`), lit like the scene (`--arg sunYaw=-38 --arg sunPitch=52 --arg keyLight=0.42 --arg
highlight=0.85`, `--real-sky`). The sheets are not reviewed by a person yet
(`art/labyrinth/sheet.v2.png.json`, `reviewed: false`).
