# Asset: rocket (hero, game-driven)
Concept: ../../art/rocket/sheet.v1.png (hept32 colours), refs cut to ../../art/rocket/refs/ (no flips).
Up Z, facing -Y (the porthole side); origin on the ground under the nozzle. Total height 1.4 m. Scale from
the front panel: 451 px = 1.4 m -> 322 px per metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Fuselage | 8-sided barrel, 0.52 across its flats at z 0.22, 0.64 at z 0.8, 0.50 at z 1.05 (two frustums) | z 0.22..1.05 | Hull (hull, #ffffff) |
| Nose cone | 8-sided cone 0.51 across, 0.35 tall | z 1.05..1.40 | Trim (trim, #da2424) |
| Band | 8-sided ring 0.63 across, 0.07 tall | z 0.535 | Band (trim, #da2424; baked at 0.05) |
| Porthole | 10-sided rim r 0.15 (0.08 thick), glass r 0.105, standing 0.03-0.05 off the front flat | centre z 0.77, front | Rim (rock, #8b97b6), Glass (glass, #5ee9e9) |
| Fins (4) | slabs 0.25 out x 0.14 thick x 0.46 tall at the body, outer top corner swept down 0.24 | r 0.23..0.48, z 0..0.46; front, back, left, right | Trim |
| Nozzle | 8-sided bell r 0.17 -> 0.12, 0.17 tall | z 0.05..0.22 | Nozzle (rock, #353658) |

`make_rocket.py` writes `p1_blockout.txt` and `p2_form.txt` (materials, porthole, hidden caps deleted, export).

## Assumptions
- The front panel draws the porthole about 0.07 m to the rocket's right of the middle; the right view
  shows it on the left edge, as a centred porthole would be. Modelled centred.
- The top view is drawn at a larger scale (the fins reach 0.56 m there, 0.48 m in the front view): the
  front, right and back views lead; the top view's IoU is the lowest for that reason.
- In the game the rocket is seen from its front only, turned in the view plane (roll) to point along its
  flight; the 4 fins give the classic two-fins-and-one-in-the-middle profile.

## Gate record (generated-sheet tier: form IoU >= 0.75, splat IoU >= 0.70, drift <= 0.08, colour <= 0.25)
| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.896 / 0.011 | 0.891 / 0.011 | 0.894 / 0.007 | 0.797 / 0.008 | passes |
| p4 albedo v1 (spacing 0.1) | 0.854 / 0.011 / 0.51 | 0.857 / 0.039 / 0.54 | 0.884 / 0.063 / 0.55 | 0.710 / 0.015 / 0.45 | colour fails: fin roots buried 0.05-0.1 m inside the fuselage poked their red discs through the white hull |
| p1 v2 | 0.922 / 0.011 | 0.916 / 0.011 | 0.919 / 0.007 | 0.797 / 0.008 | fins start at the body surface (r 0.23); the band its own material, baked at 0.05 |
| **p2 (= p1 v2 + materials)** | **0.922 / 0.011** | **0.912 / 0.011** | **0.919 / 0.007** | **0.780 / 0.008** | |
| **p4 albedo v2** | **0.874 / 0.044 / 0.17** | **0.843 / 0.014 / 0.18** | **0.883 / 0.054 / 0.20** | **0.723 / 0.015 / 0.10** | passes |

Colour gate note: run against `art/rocket/gate_palette.json` (hept32's colours with only the rocket's
four ramps: hull, trim, glass, rock). Against the full 32-colour palette the drift read 0.50-0.55 on a
correct model: the sheet's shaded reds snap to #813704 (only in `lava`) and #c12458 (only in `candy`), and
white is shared by seven ramps, so the per-ramp share measured other materials' ramps, not this model's.
Measured directly, the concept is about 48 % red and 44 % white-grey and the albedo render 54 % red and
40 % white-grey. The restricted palette is the same colours; no threshold was changed.

Goldens: `goldens/rocket` (framed) and `goldens/rocket@scene` (`--texel 0.0735 --size 120`), lit like
the scene (`--arg sunYaw=-38 sunPitch=34 keyLight=0.45 highlight=0.82`, `--real-sky`). The sheet is not
reviewed by a person yet (`art/rocket/sheet.v1.png.json`, `reviewed: false`).
