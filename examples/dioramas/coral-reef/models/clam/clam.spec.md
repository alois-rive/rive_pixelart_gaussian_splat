# Asset: giant clam (hero prop, animated)
Concept: ../../art/clam/sheet.v1.png (BLK AQU4 colours), refs cut to ../../art/clam/refs/ (no flips).
Up Z, facing -Y, hinge at the back (+Y); origin at the ground under the lower shell's centre.
Scale from the front panel: 547 px = 2.0 m (273.5 px per metre).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Lower shell | 10-sided bowl, 2.0 x 1.72 at the rim, 0.5 tall, foot ring x0.7, poked bottom | z 0..0.5 | Shell (shell, #00b9be); every other side face Groove (#005f8c) |
| Lower interior | rim inset 0.09, hollow 0.32 deep | top | Mantle (shell, #002b59) |
| Teeth | five rim verts (18 + 36k deg, k odd; one at the front centre) raised 0.12 | rim | - |
| Upper shell | the same bowl upside down, 2.0 x 1.6 x 0.45, dome x0.7 poked, its apex 0.15 towards the hinge | hinged at (0, 0.82, 0.5), lifted 30 deg | Shell / Groove ribs; interior Groove |
| Pearl | ico-sphere r 0.21 | (0, -0.05, 0.62) | Pearl (glow, #9ff4e5, unlit) |

Built in `make_p1.py` -> `p1_blockout.txt` (the teeth and ribs are long angle expressions, so they are
generated), `p2_form.txt` (pearl joined to the lower shell, flat shading, `clam_rest.glb`),
`p3_motion.txt` (the breathing, `clam.glb`).

## Assumptions
- The sheet's side views are drawn level (no visible elevation): gate views at elevation 0.
- The sheet's upper shell is curved; a lifted, upside-down bowl reads the same at the texel.
- The shell interior colours are taken from the sheet: Mantle in the lower shell, Groove in the upper.

## Animation
`Upper` (origin at the hinge since p1) rotates 0 -> +10 -> 0 degrees about X over 72 frames at 12 fps
(6 s, hedra's eased keys), exported with `--bake-animations`, baked at 12 fps: one bone. Frame 0 is
the gated rest pose.

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`), elevation 0:

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.87 / drift 0.28 | 0.74 | 0.88 / 0.27 | 0.89 / 0.18 | upper shell a thick cylinder lid: boxy, too tall |
| p1 v2 | 0.84 / 0.04 | 0.66 / 0.10 | 0.85 / 0.05 | 0.91 / 0.04 | upper as a cone fanned from the hinge: too thin in the side view |
| p1 v3 | 0.90 / 0.22 | 0.70 / 0.06 | 0.91 / 0.21 | 0.89 / 0.13 | upper as the lower bowl upside down, lifted 45 deg: too steep |
| p1 v4 | 0.88 / 0.07 | 0.82 / 0.04 | 0.90 / 0.06 | 0.92 / 0.09 | lifted 30 deg; top too deep |
| **p1 v5 = p2** | **0.881 / 0.043** | **0.812 / 0.030** | **0.898 / 0.038** | **0.909 / 0.058** | upper shell depth 0.86 -> 0.8. PASS |

Look, splats albedo (`lookdev/clam_rest.bin`, spacing 0.09, `--min-iou 0.7 --max-aspect-drift 0.08`):
IoU 0.867 / 0.812 / 0.877 / 0.913, aspect drift 0.014 / 0.031 / 0.009 / 0.035, colour drift
0.01 / 0.03 / 0.01 / 0.06. PASS, no waivers.

Goldens: `goldens/clam` (framed), `goldens/clam@scene` (`--texel 0.037`: the scene's 0.052 m texel
at the clam over its 1.4 scale), `goldens/clam@3s` (half closed), all lit like the scene
(`--arg sunPitch=65 sunYaw=-30 keyLight=0.3 highlight=0.95`, `--real-sky`).
