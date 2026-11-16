# Asset: sun mirror (hero, the game's one moving piece; game-driven, a pool of 10)
Concept: ../../art/mirror/sheet.v1.png (Sunset Red colours), refs cut to ../../art/mirror/refs/ (no flips:
the sheet follows the brief: the right view shows the mirror edge-on, the top view its front at the
bottom). Up Z, the face towards -Y; origin on the ground under the pivot (the game turns it about Y).
Scale from the FRONT panel: the yoke 331 px for 0.95 m -> 348 px per metre (the sheet came out 1.32 m
tall, not the brief's 1.1: the image leads).

## Parts (metres)
| Part | Size | Position | Material (ramp, base step) |
|---|---|---|---|
| Base | octagon, 0.83 flat to flat, 0.167 tall | z 0..0.167 | Stone (stone, #281a2d); top face StoneTop (stone, #6b2341) |
| Step | octagon, 0.56 flat to flat, 0.126 tall | z 0.167..0.293 | Stone / StoneTop |
| Post | 0.16 square | z 0.293..0.497 | Stone |
| Crossbar | 0.95 x 0.09 x 0.092 | z 0.497..0.589 | Rim (bronze, #af2747) |
| Arms | 0.09 square, x ±0.43 | z 0.497..1.12 | Rim |
| Mirror | octagonal slab 0.70 flat to flat, 0.095 thick, flats up and sideways | centre z 0.974 | Rim (edges, a 0.06 ring on the front), Face (glass, #ee243d) inset, Back (bronze, #6b2341) |
| Pins | hexagonal rod r 0.035 across the mirror to the arms | z 0.974 | Rim |
| Boss | 8-sided disc r 0.10, 0.05 deep | on the back, z 0.974 | Back |

`make_mirror.py` writes the three phases: `p1_blockout.txt` (one primitive per part), `p2_form.txt`
(materials, the face inset, the boss, hidden bottoms deleted, join, flat shading, export
`mirror_p2.glb`: the gated form), `p3_splat_fit.txt` (splat fit, below; exports `mirror.glb`, the
model the bench and the scene bake). 182 triangles.

## Assumptions
- The sheet's right view draws the mirror and the arms as one thin column with the slab poking out
  above the arms; the model hangs the slab between the arms on pins as the front view shows, so the
  right view's column is the slab and both arms overlapping (they line up exactly edge-on).
- The brief asked for a recessed face inside a raised rim; the first build recessed it 0.025 m and the
  rim's splats covered the face (51 of 770 splats). The face is flush (an inset only): the rim is a
  colour ring, not a step.
- In the scene the face and the back are baked unlit on the `glow` ramp (the sheet's lit `glass` and
  `bronze` stay on the bench): at the court's texel a lit face shaded into the floor's colour and the
  mirror vanished; an unlit face reads as a mirror catching the sunset from any side.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`, elevation 0), IoU / aspect drift:

| Phase | front | right | back | top |
|---|---|---|---|---|
| p1 blockout | 0.968 / 0.001 | 0.926 / 0.005 | 0.978 / 0.001 | 0.975 / 0.031 |
| **p2 form** | **0.968 / 0.001** | **0.914 / 0.005** | **0.978 / 0.001** | **0.975 / 0.031** |
| p3 splat fit (mesh, for the record) | 0.968 / 0.001 | 0.881 / 0.005 | 0.978 / 0.001 | 0.975 / 0.031 |

Look, splats albedo (`lookdev/mirror.bin`, spacing 0.05 = the scene's 0.065 at scale 1.3,
`--min-iou 0.7 --max-aspect-drift 0.08`), IoU / aspect drift / colour drift:

| Bake | front | right | back | top | Change |
|---|---|---|---|---|---|
| p2, spacing 0.065, face recessed | 0.763 / 0.025 / 0.07 | **0.653** / 0.027 / 0.03 | 0.755 / 0.013 / 0.05 | 0.911 / 0.035 / 0.12 | the edge-on right view is a thin column the discs widen by a radius each side; its tip eroded |
| p2, spacing 0.05, face flush | 0.788 / 0.016 / 0.04 | **0.688** / 0.029 / 0.03 | 0.782 / 0.010 / 0.06 | 0.922 / 0.016 / 0.12 | finer discs: closer, still under 0.7 |
| **p3 splat fit** | **0.789 / 0.016 / 0.07** | **0.718 / 0.019 / 0.07** | **0.786 / 0.003 / 0.05** | **0.922 / 0.016 / 0.16** | p3: the slab, arms and crossbar thinned front to back to 0.62 (about one spacing) |

The mesh gate and the splat gate disagree on the edge-on view (a thin column), so the form phase keeps
the sheet's depths and `p3_splat_fit.txt` only thins them for the splats (modeling.md, "When the mesh
gate and the splat gate disagree"). With five colours of one hue every material shares the same steps,
so the colour drift (0.05 to 0.16) says little: the IoU and the eye lead (palette.md, small palettes).
No waiver was needed.

`hedra inspect check`: ngons on the octagon caps and the boss (harmless, triangulated on export);
open edges where the bottoms were deleted (harmless for splats).

Goldens: `goldens/mirror` (framed), `goldens/mirror@scene` (`--texel 0.0486` = the scene's 0.0632 at
scale 1.3, `--size 100`), lit like the scene's full daylight (`--arg sunYaw=-70 --arg sunPitch=42
--arg keyLight=0.4 --arg highlight=0.85 --arg shadeSteps=1 --arg splatDither=0 --arg bandDither=0.4`,
`--real-sky`).
