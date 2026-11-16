# Asset: claw (hero, game-driven)
Concept: ../../art/claw/sheet.v1.png (Peachy Pop 16 colours), refs cut to ../../art/claw/refs/ (no flips).
Up Z, facing -Y (the lamp side); the prong tips stand on z 0. Total height 1.1 m. Scale from the front
panel: 452 px = 1.1 m -> 411 px per metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Cable stub | 6-sided r 0.035 | z 0.88..1.10 | Cable (ink, #53034b) |
| Hub | octagon 0.50 across its flats, 0.195 tall, a chamfer to 0.36 across over 0.06 | z 0.645..0.90 | Hub (red, #ff4040) |
| Lamp | 8-sided disc r 0.06, 0.06 thick, on the front flat | z 0.745, front | Lamp (glow, #ffec6d, unlit) |
| Collar | octagon 0.44 across its flats, 0.10 tall | z 0.545..0.645 | Chrome (chrome, #9fb9ff) |
| Prongs (3, at 120 degrees: back, front-left, front-right) | bars 0.09 x 0.08: hinge (r 0.15, z 0.56) -> elbow (r 0.43, z 0.30) -> toe (r 0.355, z 0.05) -> tip (r 0.26, z 0.035) | | Chrome |

`make_claw.py` writes four phases: `p1_blockout.txt`, `p2_form.txt` (materials, lamp, hidden caps: the
mesh gate's model), `p3_splat_fit.txt` (the splat gate's model, below) and `p4_parts.txt` (run with
`--no-save`: `claw_hub.glb` with its origin at the collar's bottom, one `claw_prong.glb` turned to +X with
its origin at its hinge, and a 3.5 m `claw_cable.glb` with its origin at its foot). The game places the
hub, turns three prong copies round it (yaw 90, 210, -30) and swings them shut (roll), and scales the
cable to reach the trolley.

## Assumptions
- Front and top lead: both show the three prongs 120 degrees apart (one straight back, two to the
  front-left and front-right). The right view draws the two front prongs spread as far as the back one
  (0.36 m each side); with prongs at 120 degrees they reach only half as far forward (0.22 m). The right
  view is waived (below).
- The elbow radius 0.43 is read off the front view (0.375 m out / sin 60).
- The top view draws the prongs reaching 0.6 m from the middle, longer than the front view allows; it
  passes the mesh tier and is waived at the splat tier, where the slanted bars are seen nearly end-on
  from above.

## Gate record (generated-sheet tier: form IoU >= 0.75, splat IoU >= 0.70, drift <= 0.08, colour <= 0.25)
| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.389 / 0.267 | 0.313 / 0.719 | 0.386 / 0.270 | 0.377 / 0.207 | fails: each prong turned about its own middle (no `apply --location` before the turn) |
| p1 v2 | 0.825 / 0.077 | 0.667 / 0.212 | 0.845 / 0.079 | 0.753 / 0.045 | the prongs about the axis; too narrow |
| p1 v3 | 0.854 / 0.010 | 0.660 / 0.142 | 0.880 / 0.013 | 0.814 / 0.043 | elbow out to r 0.43 |
| **p2 (mesh gate)** | **0.854 / 0.010** | 0.660 / 0.116 (waived) | **0.880 / 0.013** | **0.785 / 0.020** | |
| p2 through the splats (spacing 0.045) | 0.699 / 0.047 | 0.599 / 0.149 | 0.671 / 0.037 | 0.653 / 0.020 | the 0.08 m bars bake about a disc radius fatter |
| **p3 splat fit (albedo)** | **0.734 / 0.068 / 0.07** | 0.614 / 0.116 / 0.07 (waived) | **0.725 / 0.007 / 0.06** | 0.628 / 0.086 / 0.08 (waived) | bars and cable pulled in (`shrink-fatten -0.03`, `-0.012`) |

Waivers: **right** (mesh and splat tiers), the sheet contradicts its own top and front views (see
Assumptions); **top** at the splat tier only, the sheet's top view draws longer prongs than its front.
The game sees the claw from the front, 17 degrees from above.

Colour gate note: run against `art/claw/gate_palette.json` (the 16 colours with only the claw's ramps:
red, chrome, ink, glow). With all ten ramps the shared colours (#ff4040 in four ramps, #9fb9ff in two)
split the shares and the drift read 0.23-0.27 on a correct model; the restricted file is the same colours
and the threshold is unchanged.

Goldens: `goldens/claw` (framed) and `goldens/claw@scene` (`--texel 0.0275 --size 120`), lit like the
scene (`--arg sunYaw=-15 sunPitch=68 shadeSteps=1 highlight=0.82`, `--real-sky`). The sheet is not
reviewed by a person yet (`art/claw/sheet.v1.png.json`, `reviewed: false`).
