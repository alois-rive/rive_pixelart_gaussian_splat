# Asset: storey (hero prop: one floor of the pagoda, stacked by the game)
Concept: ../../art/storey/sheet.v1.png (NA16 colours), refs cut to ../../art/storey/refs/.
Up Z, facing -Y; origin on the ground at the centre. In the scene: a pool of game bones, scaled per axis
as the stack is cut.

Scale: the eave 2.0 m = 568 px in the front panel (284 px a metre); the top panel is drawn at 215 px a metre.

## Parts (metres, before the splat fit)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Walls | 1.5 x 1.5 x 0.45 | z 0..0.45 | Lacquer (lacquer, #9d303b) |
| Band | 1.5 x 1.5 x 0.085 | z 0.45..0.535 | Gold (gold, #e4943a), spacing 0.07 |
| Posts (4) | 0.16 x 0.16 x 0.535 | corners at +-0.72 | Post (lacquer, #3e2137) |
| Door | 0.5 x 0.07 x 0.34, one spacing proud of the front wall | front | Door (lacquer, #1f0e1c) |
| Fascia | 2.0 x 2.0 x 0.085 | z 0.535..0.62 | Fascia (roof, #17434b) |
| Roof | 4-sided frustum 2.0 -> 1.3, 0.18 tall, no caps | z 0.62..0.80 | Roof (roof, #34859d) |
| Deck | 1.3 x 1.3 x 0.06 | z 0.80..0.86 | Deck (stone, #584563) |
| Tips (4) | 0.1 x 0.1 x 0.11 | eave corners at +-0.97, z 0.66 | Gold |

Hidden faces removed in p2 (they bake splats nobody sees): the tops of the walls, band and fascia, the
band's bottom, the deck's underside.

## Assumptions
- The sheet's corner tips curl up from the fascia; modelled as small gold blocks at the corners.

## Splat fit (p3_splat_fit.txt)
The discs reach about one radius (0.11 m at 0.09 spacing) past the deck's top and the walls' foot: the p2
storey baked 0.24 m taller than its mesh (splat aspect drift 0.18-0.25) while its width held (the tips
erode). p3 shrinks it vertically about the ground, 0.86 -> 0.67 m (0.84 was not enough: drift 0.083-0.096).
`game.as` stacks storeys every 0.67 m. The mesh gate is taken on p2, the splat gate on p3.

## Gate record (generated-sheet tier, chosen before the build)
- p1 blockout: IoU 0.952 / 0.952 / 0.945 / 0.965, aspect drift <= 0.007.
- p2 form: **IoU 0.950 / 0.954 / 0.943 / 0.993, aspect drift 0.015 / 0.015 / 0.019 / 0.002** (`--min-iou 0.75`).
- p4 splats, albedo, bench at the scene's spacing (0.09): **IoU 0.876 / 0.875 / 0.859 / 0.973, aspect drift
  0.002 / 0.029 / 0.044 / 0.008, colour drift 0.20 / 0.16 / 0.17 / 0.12** (`--min-iou 0.7 --max-aspect-drift 0.08`).
  No waivers.
- Goldens: `goldens/storey` (framed), `goldens/storey@scene` (texel 0.0625).
