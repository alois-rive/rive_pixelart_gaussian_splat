# Assets: the desert oasis

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; `orthoHeight` 9.4 m
-> texel 0.0705 m. Splat spacing 0.09 m (1.3 texels; the camel 0.08, its hooves 0.06):
thinnest part 0.13 m, smallest painted shape 0.18 m. Palette: Parchment and Ink (`palette.json`,
16 colours, 8 ramps). Up Z, facing -Y in hedra.

Most Parchment and Ink ramps start at black (`palm`, `bark`, `water`, `cloth`, `stone`): a base
colour on step 1 shades, or is inked, straight to #000000. Every base below sits on step 2 or
higher, and the scene uses `shadeSteps` 1.

| Asset | Class | Size (m) | Instances | Ramps (base colour) | Concept | Triangles | Animation | Notes |
|---|---|---|---|---|---|---|---|---|
| ground | terrain | 8.4 x 8.4 x 3.8 | 1 | dune (sand texture `textures/sand_48.png`: #e6d1a1 + #caac77 ripples; shore #caac77; sides #a58a62), bark (#a58a62 underside), water (texture `water_16.png`: #87867a + #a9a994, `sway`) | this list | ~140 | water `sway` only | 12-sided chunk; the pond is an inset of the top face lowered 0.12 m (no coplanar overlay); 48 texels over 8.4 m = 0.175 m, 2 splats; underside cone 3.4 m deep so it shows below the rim at 30 degrees |
| camel | hero character | 2.3 x 0.85 x 2.0 | 1 | fur (#c0977a body, #886243 muzzle, hooves, tuft), stone (#87867a blanket, #a9a994 top), cloth (#f0d696 stripe) | `camel/sheet.v1.png` | 364 | skinned, 12 bones, rigid weights per segment; pacing walk 1.2 s, baked over a 14.4 s orbit (radius 2.3 m) at 10 fps | `models/camel/camel.spec.md` |
| palm | foliage | 2.6 x 2.6 x 3.3 | 3 (scale 0.9-1.1, phase 0 / 1.3 / 2.6 s) | bark (#a58a62 trunk rings, #594a45 nuts), palm (#ad9d62 fronds, `double`) | this list | 182 | skinned, 4 bones (3 up the trunk, 1 crown), sway 4 s at 10 fps | fronds are 3-segment strips weighted to the crown |
| stall | prop | 1.7 x 1.25 x 1.8 | 1 | bark (#a58a62 posts and counter), cloth (canopy texture `canopy_16.png`: #c0977a / #f0d696 stripes), stone (#a9a994 jars) | this list | ~110 | none | posts 0.14 thick; stripes 2 texels (0.2 m) |
| rock | prop | 0.64 x 0.5 x 0.4 | 3 | stone (#a9a994) | this list | 20 | none | jittered icosphere |
| shrub | foliage | 0.75 x 0.6 x 0.4 | 4 | palm (#887c56, `sway`) | this list | 40 | wind `sway` | two jittered icospheres |

Only the camel goes through a generated turnaround sheet; everything else is blocked out from
this table and judged in the scene at its texel. Budget: 20 515 splats; animated bones:
camel 12 + 3 palms x 4 = 24 of 63.
