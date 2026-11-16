A modeling reference sheet (turnaround) for ONE low-poly 3D game asset: a chunky pub pool table with a long hanging lamp above it, the playfield of a pixel-art billiards game.

Canvas and layout, keep exactly:
- 1536 x 1024 landscape image, a 2 x 2 grid of four equal panels.
- Top-left panel: FRONT view. Top-right: RIGHT side view. Bottom-left: BACK view. Bottom-right: TOP view (looking straight down).
- Orthographic cameras (no perspective), the same scale in every panel, the object centred in each panel and standing on the same invisible ground line in the three side views.
- The table is long: draw it small enough that its full length fits inside the FRONT, BACK and TOP panels with a clear margin. The RIGHT view looks at the SHORT end of the table: there the table is only about half as wide as in the front view (1.32 m instead of 2.32 m), and the lamp is seen end-on, much narrower than in the front view; it is NOT a copy of the front view.
- Every view sits whole inside its panel with a clear margin of background all round (at least a tenth of the panel): nothing touches or crosses a panel edge, including the lamp cords at the top.
- Each side view is exactly frontal to its side: no other face of the object shows in it. In the FRONT, BACK and RIGHT views the green playing surface is seen exactly edge-on: it does not show.
- The four panels show the SAME object, only turned: FRONT: we look at one LONG side of the table. RIGHT: the camera has walked round to the SHORT end that was on the RIGHT of the image in the front view. BACK: the other long side. TOP: seen from straight above, looking down, the long side towards the BOTTOM edge of the image, the lamp shade covering the middle of the green surface.
- One flat, uniform, light grey background (#d9d9d9) everywhere: no floor, no cast shadow, no gradient, no vignette, no frame lines, no text, no labels.

The object (identical in all four views), 2.32 m long, 1.32 m wide, 2.5 m tall in all (the table 0.84 m tall, the lamp above it):
- Playing surface: a flat green (#20ac00) rectangle 2.0 m x 1.0 m at 0.80 m above the ground, seen only from the top.
- Rails: a thick wooden rail 0.16 m wide all round the playing surface, its top at 0.84 m: brown (#a05000) on top, with a thin green cushion strip on its inner edge.
- Pockets: six round black (#000000) holes 0.14 m across, one at each of the four corners and one in the middle of each LONG side, cut into the rail (seen from the top).
- Body: a dark red-brown (#800018) box apron under the rails with straight vertical sides, the same footprint as the rails (2.32 x 1.32 m), from 0.56 m up to 0.84 m.
- Legs: four chunky square legs 0.16 m thick, one at each corner (inset 0.1 m), from the ground up to the body, brown (#a05000).
- Lamp: ONE long box-shaped lamp shade 1.1 m long (along the table's length), 0.32 m wide and 0.16 m tall, green (#20ac00) with slightly sloped sides, centred over the table, its bottom 1.80 m above the ground; along its underside a glowing pale peach (#ffc080) strip. It hangs from two thin black (#000000) cords, 0.7 m apart, going straight up from the shade's top to 2.5 m.

Style, keep exactly:
- A clean low-poly 3D model render: faceted, flat-shaded faces, hard straight edges, big readable chunky shapes, about 400 triangles worth of detail. No smooth organic surfaces, no tiny details, no texture noise, no grain, no balls on the table, no cue.
- Flat colour areas only, ONLY these colours (the Chromatic16 palette): playing surface and lamp shade green #20ac00; rail tops and legs brown #a05000; apron #800018; pockets and cords #000000; lamp glow #ffc080.
- Soft, even light from the upper left, so each face reads as one flat tone; no specular highlights, no ambient occlusion blur.
