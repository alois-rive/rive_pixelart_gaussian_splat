# Asset: cart (hero, the player's mine cart; one game bone)
Concept: ../../art/cart/sheet.v1.png (EN4 colours), refs cut to ../../art/cart/refs/ (no flips: the
sheet follows the brief's orientation line: right view faces left, top view front at the bottom).
Up Z, facing -Y (the cart rolls towards -Y; the GLB faces +Z, the game turns it along the track),
origin on the ground under the cart's centre. Total height 0.88 m.
Scale from the front panel: the rim, 342 px = 0.75 m -> 456 px per metre (the right panel agrees:
its 400 px height is the same 0.88 m).

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Tub | upside-down frustum: top 0.68 x 1.04, bottom 0.50 x 0.92, 0.41 tall; bottom face deleted | z 0.21..0.62 | Wood (wood, #e5b083, step 2) |
| Corner strips | 0.05 chamfer on the tub's four sloped corner edges | | Iron (iron, #20283d, baked at step 1) |
| Ore heap | the tub's top face | z 0.62 | GemTan (gem, #e5b083) |
| Rim | a frame of four bars 0.07 wide, 0.06 tall, outside 0.75 x 1.105 | z 0.61..0.67 | Iron |
| Wheels | 4 octagonal cylinders r 0.145, 0.09 thick, axis X | (+-0.285, +-0.29, 0.145) | Iron |
| Axles | 2 hexagonal cylinders r 0.04 (exaggerated), 0.5 long | (0, +-0.29, 0.145) | Iron |
| Gems | 8 ico-spheres (subdivision 1) r 0.12-0.19, a mound peaking at 0.88 | over the heap | Gem (gem, #fbf7f3) x5, GemTan x3 |
| Lantern | cap cone r 0.095 -> 0.045 (0.08 tall), glass octagon r 0.065 x 0.17, base r 0.09 x 0.05 | (0, -0.63, 0.385..0.64) | Iron; glass Glow (glow, #fbf7f3, unlit) |

`p1_blockout.txt` (primitives), `p2_form.txt` (materials, the corner chamfer, the heap face, joins:
Irons, Gems; `cart.glb`). 446 triangles.

## Assumptions
- The sheet's top view contradicts its side views: its wheels stand outside the rim (wider than the rim
  by 30 px a side) and the rim is 1.22 times as long as wide, where the front and right panels give
  wheels inside the rim and 1.47. Front, right and back lead (the game's camera, 38 degrees down, sees
  the sides and the heap); the top view's aspect gets a waiver (below).
- The sheet paints the shade side green (#426e5d): that is light, not material; the tub is Wood
  throughout and the renderer shades it down its ramp.
- The sheet's hook between rim and lantern is one art pixel at the scene's texel: dropped, the cap
  touches the rim. The cap and base are exaggerated (they baked to 3-10 splats, specks).
- With four colours the colour drift says little (every material shares the same colours); IoU and
  the eye lead (modeling.md, threshold tiers).

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`):

| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.811 / 0.030 | 0.839 / 0.028 | 0.802 / 0.037 | 0.910 / 0.341 | edge gems too high, tub bottom too high |
| p1 v2 | 0.880 / 0.030 | 0.892 / 0.028 | 0.869 / 0.037 | 0.910 / 0.341 | tub to z 0.21, edge gems lowered |
| p2 v1 | 0.880 / 0.030 | 0.890 / 0.028 | 0.870 / 0.037 | 0.910 / 0.341 | rim as a frame (the solid rim read as a lid from the game's camera), heap face |
| **p2 v2** | **0.888 / 0.009** | **0.886 / 0.015** | **0.877 / 0.016** | 0.915 / **0.362** | heap peak raised to the sheet's 0.88 m, hook dropped |

Look, splats albedo (`lookdev/cart.bin`, the scene's spacing 0.09, `--min-iou 0.7 --max-aspect-drift 0.08`):

| Iteration | front | right | back | top |
|---|---|---|---|---|
| v1 | 0.849 / 0.056 / 0.03 | 0.891 / 0.004 / 0.02 | 0.840 / 0.077 / 0.03 | 0.881 / 0.260 / 0.05 |
| v2 (thicker lantern parts) | 0.839 / 0.070 | 0.879 / 0.019 | 0.839 / **0.090 FAIL** | 0.880 / 0.264 |
| **v3 = final** | **0.846 / 0.049 / 0.03** | **0.895 / 0.001 / 0.02** | **0.841 / 0.077 / 0.03** | 0.887 / **0.280** / 0.06 |

(IoU / aspect drift / colour drift.) The back view failed once (0.090) because the splat spread makes a
squat object squatter; raising the heap's peak to the sheet's height fixed it.

Waiver, top aspect (form 0.362, splats 0.280): the sheet's top view contradicts its side views (above);
front, right and back lead. Its top IoU is 0.915 / 0.887.

`hedra inspect check`: ngons on the cylinder caps (harmless, triangulated on export), and 8
non-manifold edges where the tub's bottom face was deleted (an open box, harmless for splats).

Goldens: `goldens/cart` (framed), `goldens/cart@scene` (`--texel 0.05`), lit like the scene
(`--arg sunYaw=-35 sunPitch=42 keyLight=0.45 highlight=0.8 shadeSteps=1 lightSteps=1 splatDither=0
bandDither=0.45 edgeDepth=0.5`, `--real-sky`). The navy iron (wheels, rim) vanishes against the navy
sky in these renders: EN4 has no fifth colour for a sky; in the game the cart rides a navy track bed
too, and the tan tub and the cream heap carry its read.
