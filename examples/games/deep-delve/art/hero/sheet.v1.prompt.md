A modeling reference sheet (turnaround) for ONE low-poly 3D game asset: a short, stocky dungeon delver (a small adventurer with a lamp-helmet and a backpack), the player character of a top-down roguelike.

Canvas and layout, keep exactly:
- 1536 x 1024 landscape image, a 2 x 2 grid of four equal panels.
- Top-left panel: FRONT view. Top-right: RIGHT side view. Bottom-left: BACK view. Bottom-right: TOP view (looking straight down).
- Orthographic cameras (no perspective), the same scale in every panel, the figure centred in each panel and standing on the same invisible ground line in the three side views.
- Every view sits whole inside its panel with a clear margin of background all round (at least a tenth of the panel): nothing touches or crosses a panel edge.
- Each side view is exactly frontal to its side: no other face of the figure shows in it (a slightly oblique view comes out wider and fails the aspect gate).
- The four panels show the SAME figure, only turned: FRONT: the delver faces the camera (we see the face, the lamp on the helmet's front, both arms hanging at the sides). RIGHT: the camera has walked round to the delver's own right-hand side, so the face and the lamp point to the LEFT edge of the image and the backpack sticks out to the RIGHT. BACK: seen from behind (the backpack and the red bedroll fill the back, no face). TOP: seen from straight above, looking down, with the face towards the BOTTOM edge of the image: the round helmet brim is the biggest shape, the backpack and bedroll stick out towards the TOP edge. Each detail appears only in the views from which it is really visible.
- One flat, uniform, light grey background (#d9d9d9) everywhere: no floor, no cast shadow, no gradient, no vignette, no frame lines, no text, no labels.

The figure (identical in all four views), 1.2 m tall, 0.78 m wide at the helmet brim, 0.62 m deep with the backpack; chunky toy proportions (the head and helmet about a third of the height):
- Boots: two short blocky boots 0.18 m tall, 0.16 m wide, 0.24 m long, 0.12 m apart, dark brown.
- Legs: two short thick legs 0.14 m wide, 0.18 m tall, above the boots, leather brown.
- Body: a barrel-like tunic 0.5 m wide, 0.36 m deep, 0.36 m tall, its bottom 0.34 m above the ground, slightly wider at the bottom; a dark belt 0.06 m tall round its middle.
- A short blue cloak over the shoulders and upper back: a cape 0.56 m wide that hangs to the belt behind, open at the front (the tunic shows between its edges).
- Arms: two thick arms 0.12 m square hanging at the sides, slightly away from the body, ending in big blocky fists 0.13 m (the right fist will hold a weapon: leave it empty).
- Head: a faceted block 0.32 m wide, 0.28 m deep, 0.24 m tall on the shoulders, tan skin, two small dark eyes and nothing else on the face.
- Helmet: a round iron cap (eight-sided dome) over the top of the head with a flat, round brim 0.78 m across and 0.05 m thick sticking out all round, steel grey; on the front of the cap a small square lamp 0.12 m across with a glowing pale-yellow window, facing forward.
- Backpack: a box 0.4 m wide, 0.18 m deep, 0.38 m tall on the back, warm brown, with a red rolled bedroll (a horizontal cylinder 0.46 m long, 0.12 m thick) strapped across its top.
- The figure is left-right symmetric: no asymmetric details.

Style, keep exactly:
- A clean low-poly 3D model render: faceted, flat-shaded faces, hard straight edges, big readable chunky shapes, about 600 triangles worth of detail. No smooth organic surfaces, no tiny details, no straps or buckles smaller than the belt, no texture noise, no grain.
- Flat colour areas only, ONLY these colours (from the Apollo palette): cloak blue #3c5e8b (lit) and #253a5e (shade); tunic and legs leather #ad7757; belt and boots dark brown #4d2b32; backpack #884b2b; bedroll red #a53030; skin #d7b594; helmet steel #819796 (lit) and #577277 (shade); lamp window #e8c170; eyes #172038.
- Soft, even light from the upper left, so each face reads as one flat tone; no specular highlights, no ambient occlusion blur.
