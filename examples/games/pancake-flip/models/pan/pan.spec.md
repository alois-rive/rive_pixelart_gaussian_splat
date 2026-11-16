# Asset: pan (hero prop: the frying pan with its pancake)
Concept: ../../art/pan/sheet.v2.png (Vanilla Milkshake colours; v1 was cropped: its handle crossed into
the next panels, `sheet_cut.py` refused it; v2 adds a margin line), refs cut to ../../art/pan/refs/ (no
flips: the right view faces left, the top view has the handle at the bottom).
Up Z, the handle towards the front (-Y), origin on the ground under the pan's centre.
Scale from the RIGHT panel (square-on): the rim 435 px = 0.9 m -> 483 px per metre. The panels use
different scales (the top view's rim is 270 px): the gate compares cropped, normalised silhouettes,
so only the proportions inside each view matter.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Body | 12-sided frustum, r 0.39 at the floor -> 0.455, 0.17 tall, open top | z 0..0.17 | Iron (iron, #6c5671) |
| Rim | 12-sided band r 0.455 -> 0.465, 0.045 tall; its top inset 0.06 and pushed down 0.15 (the hollow) | z 0.17..0.215 | Rim (iron, #b0a9e4) on the top ring and outer band; inner walls and floor Iron |
| Handle | box 0.15 x 0.52 x 0.1, narrowed to 0.11 x 0.085 at the pan end, rising 5 degrees | centre y -0.69, z 0.125 | Handle (berry, #f98284) |
| Cap | octagonal cylinder r 0.075, 0.08 long | y -0.97, z 0.14 | Cap (berry, #feaae4) |
| Pancake | 12-sided disc r 0.34, 0.07 thick (bottom face deleted) | centre z 0.13 | Golden (golden, #ffc384) top, Crust (burnt, #dea38b) edge |

`p1_blockout.txt` (primitives), `p2_form.txt` (hollow, taper, tilt, materials, joins: Pan, Pancake;
`pan.glb`), `p3_parts.txt` (run with `--no-save`: the splat versions, below). Triangles: 166.

## Assumptions
- The sheet's FRONT and BACK panels are drawn from about 10 degrees above (the rim's far edge and the
  pancake show: visible rim depth / width 74 / 450 = sin 9.5 degrees); RIGHT and TOP are square-on.
  Front and back are gated at `--elevation 10`, right and top at 0 (two `views` calls into one folder).
- Seen from 10 degrees above, a handle 1 m behind the pan rises above its rim; the sheet's BACK view
  still hides it (the brief said "hidden behind the pan"). The sheet contradicts itself: front, right
  and top lead; the back view's aspect gets a waiver (below).
- Splat spread: on the bench at the scene's pan spacing (0.034 m, about one texel: a flat 0.2 m pan
  at 1.5 texels fattened to aspect 0.25 against the sheet's 0.15), the silhouette still grows ~0.06 m
  on every side. Following assets.md ("Positive shapes come out fatter: shrink the solid itself by
  about one radius"), `p3_parts.txt` shrinks the whole hero by that much about its ground point
  (x 0.88, y 0.93, z 0.46) before export: `pan_splat.glb` (pan + pancake, the lookdev hero),
  `pan_only.glb` (the scene's pans; the pancakes are separate bones). The hedra model stays at the
  sheet's size and is what the form gate measures.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`; front/back elevation 10):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p2 v1 | fail 0.129 drift | 0.702 / 0.270 | 0.854 / 0.378 | 0.928 / 0.036 | `active` adds to the selection: the 5 degree handle tilt turned body and rim too, and the rim material landed on the body |
| p1 | 0.927 / 0.037 | 0.929 / 0.027 | 0.792 / 0.291 | 0.936 / 0.038 | explicit `select` before every per-object step |
| **p2** | **0.926 / 0.037** | **0.912 / 0.027** | 0.793 / **0.291** | **0.928 / 0.038** | |

Look, splats albedo (`lookdev/pan.bin`, `--min-iou 0.7 --max-aspect-drift 0.08`, colour drift 0.25):

| Bake | front | right | back | top |
|---|---|---|---|---|
| pan.glb, spacing 0.05 | aspect 0.500 | 0.814 / aspect 0.249 (0.622) | 0.832 / 0.459 | 0.923 / 0.036 |
| shrunk z 0.68, spacing 0.045 | 0.903 / 0.013 | 0.796 / 0.374 | 0.788 / 0.252 | 0.923 / 0.017 |
| z 0.68, spacing 0.034 | 0.904 / 0.006 | 0.795 / 0.285 | 0.781 / 0.200 | 0.914 / 0.025 |
| z 0.5 | 0.872 / 0.093 | 0.791 / 0.092 | 0.770 / 0.055 | 0.931 / 0.020 |
| **x 0.88 y 0.93 z 0.46, spacing 0.034** | **0.837 / 0.028 / colour 0.06** | **0.786 / 0.044 / 0.14** | 0.745 / **0.153** / 0.11 | **0.923 / 0.069 / 0.19** |

Waiver, back aspect (form 0.291, splats 0.153): the sheet draws the back from 10 degrees above yet
hides the handle that view must show; its IoU passes (0.793 / 0.745). Front, right and top lead.

`hedra inspect check`: ngons on the 12-sided caps (triangulated on export); open boundaries where the
body's top and the rim's bottom caps were deleted (hidden faces, deleted on purpose).

Goldens: `goldens/pan` (framed), `goldens/pan@scene` (`--texel 0.0294 --size 160`), lit like the
scene (`--arg sunYaw=-30 --arg sunPitch=50`, `--real-sky`).
