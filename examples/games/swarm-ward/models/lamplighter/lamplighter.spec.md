# Asset: lamplighter (hero, the player character; one rigid game bone)

Concept: `../../art/lamplighter/sheet.v1.png` (Rosy 42 colours, `reviewed: false`), refs cut to
`../../art/lamplighter/refs/` (no flips, no rotation). Up Z, facing -Y; origin on the ground between
the boots; the pole in the figure's right hand (-X). Figure 1.2 m to the hat's crown, the pole's hook
1.48 m (scene scale 1: about 21 art pixels tall at the scene's 0.05 m texel).

Scale from the FRONT panel: crown top (y 100) to boot soles (y 478) = 378 px for 1.2 m -> 315 px per
metre; the right and back panels share the ground line and the scale. Depths from the RIGHT panel.

## Parts (metres)

| Part | Size | Position | Material (ramp, colour) |
|---|---|---|---|
| Boots | 0.19 x 0.27 x 0.10 each | x +-0.14, y -0.04, z 0..0.10 | Dark (coat, `#3b2027`) |
| Legs | 0.15 x 0.17 x 0.12 | x +-0.13, z 0.09..0.21 | Dark |
| Coat | 8-sided A-line frustum, r 0.275 -> 0.215, y squashed 0.86, 0.54 tall | z 0.165..0.705 | Coat (coat, `#cf752b`) |
| Belt | 8-sided ring r 0.252, 0.07 tall | z 0.42..0.49 | Belt (coat, `#7d3833`) |
| Buttons | 6-sided discs r 0.045 | front, z 0.60 and 0.33 | Belt |
| Scarf | 8-sided ring r 0.19, 0.13 tall; an end 0.13 x 0.06 x 0.26 on the chest at +X | z 0.67..0.80 | Scarf (slate, `#4fa4b8`) |
| Head | 8-sided r 0.168, 0.25 tall | z 0.76..1.01 | Face (skin, `#ffc2a1`) |
| Eyes | 0.05 x 0.03 x 0.06 | x +-0.065, z 0.875 | Eye (coat, `#21181b`; specks) |
| Hat | 12-sided brim r 0.343 (y x0.96) sloping to r 0.19, 8-sided crown r 0.172 -> 0.155, 0.24 tall; the whole hat tilted back 10 degrees about (0, -0.02, 0.9) | brim edge z ~0.86, crown top ~1.23 | Hat (wood, `#52333f`) |
| Arms | sleeves r 0.075 (6-sided): right shoulder -> the pole at z 0.6, left hanging to z 0.47 | | Coat |
| Gloves | 0.15 x 0.13 x 0.17 at the pole; 0.13 x 0.13 x 0.17 at (0.32, 0, 0.365) | | Dark |
| Pole | 6-sided r 0.04 from the ground to z 1.36 at (-0.268, -0.03) | | Pole (wood, `#8f4d57`) |
| Hook | three bars r 0.035: up and out to (-0.33, -0.085, 1.445), out and forward to (-0.43, -0.17, 1.42), down to 1.33 | | Pole |
| Lantern | pyramid cap r 0.18 (z 1.22..1.33), glass 0.21 x 0.21 x 0.18 (emissive), four corner posts 0.035, base 0.24 x 0.24 x 0.035 | centred (-0.43, -0.17, 1.135) | Glass (glow, `#ffee83`, unlit); Dark |

`make_lamplighter.py` writes `p1_blockout.txt` (the bars' Euler angles are computed) and
`p2_form.txt` (materials, the soles and the pole's foot removed, one joined `Lamplighter`, flat
shading, `lamplighter.glb`: 572 triangles, 9 materials).

## Assumptions

- **The hook bends outward AND forward.** The front panel draws the lantern 0.43 m out to the
  figure's right, the right panel 0.19 m in front of the body, the top panel out and forward of
  the pole: one diagonal hook satisfies all three (no waiver needed).
- **The hat is tilted back.** In the right panel the brim's front is about 0.04 m higher than its
  back, which is how the face shows under the brim in the front panel; a level brim hid the face.
- **The brim is an ellipse.** 0.686 m across in the front panel, 0.638 m deep in the right one;
  the oblique top panel draws it deeper still. A y scale of 0.96 splits the right and top views (at
  0.93 the hedra top view failed its aspect gate, at 1.0 the splat right view did).
- **The hat's colour is the sheet's, not the brief's.** The brief asked for `#3b2027`; the sheet
  paints the hat about `#593234` (lit) / `#412224` (shade), whose nearest palette colour is `#52333f`.
  The hat is painted `#52333f` (wood ramp): it matches the sheet and lifts the hat (most of what a
  top-down camera sees of the hero) off the dark moor.
- **Lantern glass larger, frame thinner than drawn, no mullions.** At the bench's 0.04 m spacing the
  frame's discs spread over 0.19 m panes and swallowed them (the lantern rendered dark); the glass
  grew to 0.21 m and the cross of mullions was dropped (pixel-art exaggeration).
- The pole is 0.08 m thick (the sheet's 0.065, thickened to survive at the spacing).

## Gate record (generated-sheet tier, thresholds chosen before the build)

Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`), IoU / aspect drift:

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.841 / 0.033 | 0.829 / 0.021 | 0.838 / 0.056 | 0.794 / 0.020 | blockout at the spec's sizes |
| p1 v2 | 0.837 / 0.033 | 0.833 / 0.021 | 0.846 / 0.052 | 0.794 / 0.020 | lantern: bigger glass, no mullions |
| p1 v3 | 0.837 / 0.033 | 0.846 / 0.055 | 0.846 / 0.052 | 0.783 / **0.090** | brim y x0.93 (for the splat right view): the top view fails |
| p1 v4 | 0.837 / 0.033 | 0.845 / 0.021 | 0.846 / 0.052 | 0.788 / 0.058 | brim y x0.96 |
| **p1/p2 v5** | **0.846 / 0.033** | **0.835 / 0.021** | **0.849 / 0.052** | **0.789 / 0.067** | hat tilted back 10 degrees, raised 0.025 (the face shows) |

Look, splats albedo (`lookdev/lamplighter.bin`, the scene's own spacings: 0.055, details 0.035 to
0.045; `--look albedo --min-iou 0.7 --max-aspect-drift 0.08`), IoU / aspect drift / colour drift:

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| v1 (full palette) | 0.819 / 0.007 / 0.24 | 0.822 / 0.049 / **0.35** | 0.825 / 0.019 / 0.23 | 0.824 / 0.016 / **0.72** | the sheet's lit hat lands on `#52333f`, which skin, wood and pool2 hold |
| v1 (gate palette) | 0.819 / 0.007 / 0.20 | 0.822 / 0.049 / **0.33** | 0.825 / 0.019 / 0.22 | 0.824 / 0.016 / **0.72** | hero-only ramps: still the hat |
| v2 | 0.819 / 0.009 / 0.08 | 0.807 / **0.089** / 0.09 | 0.826 / 0.011 / 0.14 | 0.818 / 0.007 / 0.11 | hat painted `#52333f` (the sheet's colour), glass enlarged |
| v4 | 0.820 / 0.032 / 0.08 | 0.812 / 0.049 / 0.09 | 0.826 / 0.002 / 0.14 | 0.809 / 0.029 / 0.10 | brim y x0.96; pole spacing 0.035 (a 9-splat hook speck) |
| **final** | **0.829 / 0.007 / 0.07** | **0.819 / 0.043 / 0.09** | **0.834 / 0.008 / 0.15** | **0.805 / 0.064 / 0.12** | hat tilted back; Dark spacing 0.035 (an 11-splat lantern post) |

The colour gate is taken against `art/lamplighter/gate_palette.json` (the same colours, only the
hero's own ramps: coat, skin, wood, slate, glow), as the skill's modeling.md advises when ramps
share colours: with the full palette `#52333f` also counts for pool2 and the drift says nothing
about the materials.

Waivers: none on the thresholds. Recorded deviations from the brief (not from the sheet): the hat
colour and the lantern's glass (Assumptions).

Bake report: colour error 0.000 on every material, no specks warning (eyes marked `specks`).

Goldens: `goldens/lamplighter` (framed) and `goldens/lamplighter@scene` (`--texel 0.05 --size 120`),
lit like the scene (`--arg sunYaw=-40 --arg sunPitch=38 --arg shadeSteps=1 --arg highlight=0.82`,
`--real-sky`): 100 % solid art pixels, 0 off-palette.
