A modeling reference sheet (turnaround) for ONE low-poly 3D game asset: a toy-like arcade skee-ball machine (a short inclined bowling lane ending in a slanted ring target).

Canvas and layout, keep exactly:
- 1536 x 1024 landscape image, a 2 x 2 grid of four equal panels.
- Top-left panel: FRONT view. Top-right: RIGHT side view. Bottom-left: BACK view. Bottom-right: TOP view (looking straight down).
- Orthographic cameras (no perspective), the same scale in every panel, the object centred in each panel and standing on the same invisible ground line in the three side views.
- Each side view is exactly frontal to its side: no other face of the object shows in it (a slightly oblique view comes out wider and fails the aspect gate).
- The four panels show the SAME object, only turned: FRONT: the object faces the camera. RIGHT: the camera has walked round to the object's own right-hand side (not the image's right), so the object faces the LEFT edge of the image. BACK: seen from behind. TOP: seen from straight above, looking down, with its front towards the BOTTOM edge of the image and no wall showing. Each detail appears only in the views from which it is really visible.
- One flat, uniform, mid grey background (#b0b0b0) everywhere: no floor, no cast shadow, no gradient, no vignette, no frame lines, no text, no labels, no numbers.

The object (identical in all four views):
- The FRONT is the player's end. A straight lane 1.0 m wide and 3.0 m long running from the front to the back, its surface rising from 0.45 m high at the front to 0.80 m high at the back, on a solid cabinet base that reaches the ground.
- Low side rails 0.12 m wide and 0.20 m tall along both long edges of the lane.
- At the back end of the lane, a small ramp hump 0.15 m tall across the lane.
- Behind the hump, the target: a slanted square board 1.2 m wide leaning back at 45 degrees, from 0.8 m up to 1.6 m high, with three raised concentric round rings on it (the largest 1.0 m across, then 0.65 m, then 0.30 m around a dark centre hole), and one small round dark cup above the rings near the top.
- Behind the target, a tall flat backboard 1.3 m wide and 0.15 m thick reaching 2.2 m high, with a rounded-top marquee panel at its top.
- Two cabinet side walls 0.1 m thick around the target, from the backboard forward 0.6 m, as tall as the board.

Style, keep exactly:
- A clean low-poly 3D model render: faceted, flat-shaded faces, hard straight edges, big readable chunky shapes, about 600 triangles worth of detail. No smooth organic surfaces, no tiny details, no texture noise, no grain, no lights or bulbs, no text.
- Flat colour areas only, ONLY these colours (Bubblegum 16): lane surface orange #ff8426, side rails and cabinet sides hot pink #ff2674, cabinet base purple #94216a, the rings alternating white #fafdff and sky blue #68aed4, the target board navy #234975, holes and cup dark #16171a, backboard purple #94216a, marquee yellow #ffd100.
- Soft, even light from the upper left, so each face reads as one flat tone; no specular highlights, no ambient occlusion blur.
