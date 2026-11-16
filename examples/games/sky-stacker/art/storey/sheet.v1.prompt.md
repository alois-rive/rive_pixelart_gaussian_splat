A modeling reference sheet (turnaround) for ONE low-poly 3D game asset: one storey (floor module) of a Japanese pagoda, a square block that stacks on top of itself.

Canvas and layout, keep exactly:
- 1536 x 1024 landscape image, a 2 x 2 grid of four equal panels.
- Top-left panel: FRONT view. Top-right: RIGHT side view. Bottom-left: BACK view. Bottom-right: TOP view (looking straight down).
- Orthographic cameras (no perspective), the same scale in every panel, the object centred in each panel and standing on the same invisible ground line in the three side views.
- Each side view is exactly frontal to its side: no other face of the object shows in it (a slightly oblique view comes out wider and fails the aspect gate).
- The four panels show the SAME object, only turned: FRONT: the object faces the camera. RIGHT: the camera has walked round to the object's own right-hand side, so its front faces the LEFT edge of the image. BACK: seen from behind. TOP: seen from straight above, looking down, with its front towards the BOTTOM edge of the image and no wall showing.
- One flat, uniform background (#9a9a9a, a mid grey) everywhere: no floor, no cast shadow, no gradient, no vignette, no frame lines, no text, no labels.

The object (identical in all four views):
- A square storey 2.0 m wide, 2.0 m deep and 0.8 m tall in all.
- The lower part: a square box of walls 1.6 m wide, 1.6 m deep, 0.5 m tall, centred, painted red lacquer, with a thick square post at each of the four corners (0.16 m square, slightly proud of the walls) and a gold band 0.08 m tall along the top of the walls.
- In the middle of the FRONT wall only: one dark doorway 0.5 m wide and 0.35 m tall. The other three walls are plain.
- The upper part: a wide square tiled roof, a flat-topped pyramid (frustum): 2.0 m by 2.0 m at its lower edge (overhanging the walls by 0.2 m on every side), sloping up to a flat square top 1.6 m by 1.6 m, 0.3 m tall. The four roof corners curl up a little (a small upturned tip at each corner).
- The flat roof top is a plain square deck (the next storey stands on it).

Style, keep exactly:
- A clean low-poly 3D model render: faceted, flat-shaded faces, hard straight edges, big readable chunky shapes, about 200 to 400 triangles worth of detail. No tiny details, no texture noise, no grain, no tile lines drawn on the roof.
- Flat colour areas only, ONLY these colours (the NA16 palette): walls red lacquer #9d303b, corner posts #3e2137, gold band #e4943a, doorway #1f0e1c, roof teal #34859d (lit slopes) and #17434b (shaded slopes and the roof's underside), roof deck on top #584563, corner tips gold #e4943a.
- Soft, even light from the upper left, so each face reads as one flat tone; no specular highlights, no ambient occlusion blur.
