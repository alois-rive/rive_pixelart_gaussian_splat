A modeling reference sheet (turnaround) for ONE low-poly 3D game asset: a chunky arcade air hockey table, the playfield of a pixel-art arcade game.

Canvas and layout, keep exactly:
- 1536 x 1024 landscape image, a 2 x 2 grid of four equal panels.
- Top-left panel: FRONT view. Top-right: RIGHT side view. Bottom-left: BACK view. Bottom-right: TOP view (looking straight down).
- Orthographic cameras (no perspective), the same scale in every panel, the object centred in each panel and standing on the same invisible ground line in the three side views.
- Every view sits whole inside its panel with a clear margin of background all round (at least a tenth of the panel): nothing touches or crosses a panel edge. The table is long: draw it small enough that its full length fits inside the FRONT, BACK and TOP panels with that margin.
- Each side view is exactly frontal to its side: no other face of the object shows in it (a slightly oblique view comes out wider and fails the aspect gate). In the FRONT, BACK and RIGHT views the playing surface is seen exactly edge-on: it does not show.
- The four panels show the SAME object, only turned: FRONT: we look at one LONG side of the table, the side with the coin box. RIGHT: the camera has walked round to the SHORT end that was on the RIGHT of the image in the front view, so we look straight at that end and its goal pocket. BACK: the other long side, without a coin box. TOP: seen from straight above, looking down, with the coin-box side towards the BOTTOM edge of the image and no side wall showing.
- One flat, uniform, light grey background (#d9d9d9) everywhere: no floor, no cast shadow, no gradient, no vignette, no frame lines, no text, no labels.

The object (identical in all four views), 4.7 m long, 2.6 m wide, 0.95 m tall:
- Playing surface: a flat teal rectangle 4.4 m x 2.3 m on top, at 0.82 m above the ground. Painted on it in pale cyan: a straight centre line across its middle (short way), a centre circle 0.9 m wide, and a half circle 1.1 m wide in front of each goal at both short ends. Lines thick (0.06 m).
- Rails: a thick pink rail 0.15 m wide and 0.13 m tall running all round the playing surface, its top at 0.95 m. In the middle of each SHORT end the rail has a gap 0.9 m wide: the goal mouth.
- Body: a dark slate box under the playing surface with straight vertical sides, the same footprint as the rails (4.7 x 2.6 m), from 0.45 m up to 0.82 m.
- Goal pockets: under each goal mouth, a small dark box 1.0 m wide, 0.25 m deep and 0.25 m tall sticking out from the middle of each short end, its top just under the rail.
- Legs: four chunky square legs 0.22 m thick, one near each corner (inset 0.3 m from the ends and 0.25 m from the sides), from the ground up to the body, in grey steel.
- Coin box: on the FRONT long side only, centred: a small box 0.4 m wide, 0.22 m tall, 0.08 m proud of the body, with a yellow coin slot plate.

Style, keep exactly:
- A clean low-poly 3D model render: faceted, flat-shaded faces, hard straight edges, big readable chunky shapes, about 300 triangles worth of detail. No smooth organic surfaces, no tiny details, no texture noise, no grain, no air holes.
- Flat colour areas only, ONLY these colours (the SLSO-CLR17 palette): playing surface teal #2aa4aa; its lines #c1e5ea; rails pink #ea619d with purple #8f3da7 on their outer sides; body #3e415f; goal pockets #2e2c3b; legs #55607d; coin plate #f3c220.
- Soft, even light from the upper left, so each face reads as one flat tone; no specular highlights, no ambient occlusion blur.
