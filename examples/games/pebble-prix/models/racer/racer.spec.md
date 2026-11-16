# Asset: racer (hero, the player's car with its driver; four paint jobs)
Concept: ../../art/racer/sheet.v1.png (Zughy 32 colours, `reviewed: false`), refs cut to
../../art/racer/refs/ with no flips (the sheet follows the brief: the nose to the left in the RIGHT
panel, the nose to the bottom in the TOP panel).
glTF axes: Y up, the nose towards +Z, origin on the ground under the middle of the car's length
(hedra sees it facing -Y after `hedra model convert racer.glb -o racer.rmdl`).
Scale: the front panel's 388 px are the 1.6 m across the wheels (242 px per metre); the right panel
draws at 240 px per metre, the top at 159: the three agree on 2.75 x 1.6 x 1.37 m.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Hull | 2.61 long, 1.22 wide at the middle (0.80 at the nose, 0.94 at the tail), lofted through 10 octagonal stations | z -1.235 .. 1.375, underside 0.15 | Body (red #e6482e, step 2) |
| Hull's top line | nose 0.55, cowl 0.84-0.86, the tub's floor 0.60 (z 0.10 .. -0.50), tail deck 0.96-0.98 | | |
| Stripe | 0.36 wide over the top, nose to tail, around the tub | | Stripe (white #dff6f5, step 3) |
| Tub floor | between the stations at z 0.10 and -0.50 | y 0.60 | Seat (tyre #39314b) |
| Grille, headlamps | an octagon 0.34 x 0.16; two octagons 0.15 across, 0.025 off the nose face | y 0.30 / 0.36, x 0 / +-0.27 | Grille (tyre #302c2e), Lamp (peach #f4cca1) |
| Windscreen | a tilted pane 0.60 -> 0.52 wide, 0.19 tall | z 0.30 .. 0.16, y 0.84 .. 1.03 | Glass (blue #8aebf1, two-sided) |
| Driver | shoulders a box 0.60 x 0.37 x 0.42; helmet a UV sphere (8 x 6) r 0.24 | helmet centre (0, 1.13, -0.22) | Jacket, Goggles (navy #394778), Helmet (white #dff6f5), Trim (the helmet's stripe, the body's ramp), Skin (peach #eea160) |
| Wheels | octagonal, r 0.315, 0.30 wide; light hubs r 0.14 on the outer faces | x +-0.65, z +-0.85 | Tyre (tyre #39314b), Hub (white #a0938e) |
| Exhaust | a hexagonal stub r 0.07 | (0, 0.30, -1.235 .. -1.385) | Pipe (stone #7d7071), its open end Grille |

476 triangles. `make_racer.py` holds these numbers and writes racer.glb (red, the player) and
racer_blue.glb (#28ccdf, GULL), racer_pink.glb (#cd6093, CORAL), racer_gold.glb (#f4b41b, BUOY):
only Body and Trim change colour, so the four cars are one gated model in four paint jobs, each baked
on its own ramp (red, blue, pink, gold) in scene.bake.json.

## Assumptions
- The sheet's right and back views disagree on the tail's height (1.06 and 0.87 m): the tail deck is
  0.96-0.98 m, between the two.
- The front and right views put the front axle 0.47 and 0.575 m behind the nose, the rear 0.42 and
  0.50 m in front of the tail: the axles sit at +-0.85 (a 1.7 m wheelbase).
- The sheet paints the hull's lower faces a darker red (#a93b3b): that is light, so the model paints
  them the body colour and leaves the shade to the renderer.
- No headrest fairing: the sheet does not draw the one the brief asked for; the tail deck rises
  behind the driver instead.
- The model is built by a generator script (meshkit) instead of hedra command files: the hull is a
  loft through measured stations, which hedra's primitives would only approximate. The hedra gate
  runs on the imported GLB (`racer.rmdl`), one form phase.

## Budgets
Splats at the scene's spacing (0.07 m; lamps 0.035, grille 0.04, goggles and helmet stripe 0.045):
2457 a car, 9 828 for the four. Bones: one game bone a car (`car0`..`car3`) plus its boost flame.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views of racer.rmdl vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`, elevation 0),
IoU / aspect drift:

| Phase | front | right | back | top |
|---|---|---|---|---|
| **form (make_racer.py)** | **0.928 / 0.019** | **0.832 / 0.013** | **0.926 / 0.048** | **0.929 / 0.018** |

Look, splats albedo (`lookdev/racer.bin`, the scene's spacings; `--min-iou 0.7 --max-aspect-drift
0.08 --max-color-drift 0.25`), IoU / aspect drift / colour drift:

| Palette | front | right | back | top |
|---|---|---|---|---|
| `art/racer/gate_palette.json` (the racer's own ramps) | 0.827 / 0.014 / 0.25 | 0.878 / 0.042 / 0.16 | 0.849 / 0.035 / 0.23 | 0.904 / 0.032 / 0.10 |
| `art/palette.json` (all 26 ramps), for the record | 0.827 / 0.014 / 0.29 | 0.878 / 0.042 / 0.22 | 0.849 / 0.035 / 0.29 | 0.904 / 0.032 / 0.13 |

**Waiver (colour drift against the full palette).** Zughy 32's red-orange steps sit in five ramps
(red, gold, orange, glow, lamp) and its blues in three (blue, sea, navy): against the full palette
the sheet's soft shading and the car's red count towards ramps the car never uses, and the front and
back read 0.29. modeling.md's remedy is followed: the colour gate is taken against a copy of the
palette holding only the racer's own ramps (red, white, tyre, peach, blue, navy, stone; the same
colours), where every view passes (the front at the limit, 0.25). The materials were checked by
eye against the sheet; nothing was repainted to pass.

Goldens: `goldens/racer` (framed) and `goldens/racer@scene` (`--texel 0.132 --size 160`), lit like
the scene (`--arg sunYaw=-35 --arg sunPitch=55 --arg keyLight=0.45 --arg highlight=0.85 --arg
shadeSteps=1`, `--real-sky`): the lit sides warm along the red ramp to orange, the shade drops to
#a93b3b, the stripe and the helmet stay white.
