# Asset: ghost (character, animated; no sheet: its row in art/assets.md is the brief)
A sheet ghost 1.2 m tall: an 8-sided tapering body (r 0.44 -> 0.3, 0.72) with a zigzag hem, a head
(uv-sphere 8 x 5, r 0.34), stubby raised arms, two small upright eyes (0.1 x 0.15, 0.24 m apart) and a
small mouth (0.12 x 0.1) standing proud of the sheet: a face of a few art pixels (eyes ~2 x 3, mouth ~2 x 2
at the scene's 0.068 m texel). Sheet unlit #fafbf6 (glow, spacing 0.1), face #0f0f1b (dark, unlit,
spacing 0.05, so each face part is 2+ splats across).

Animation (p2_motion.txt): the joined `Ghost` (origin at its middle) is the child of an empty `Orbit` at the
origin that turns -360 degrees about Z in 240 frames at 24 fps, linear (clockwise from above, 10 s); the ghost
sits 2 m out on +X, facing -Y (its direction of travel there), and bobs 0.18 m and rocks 6 degrees with eased
keys every 30 frames. Exported `--bake-animations`; baked at 10 fps: one bone (the empty is not a mesh).
Gates: hedra views and the bake (no specks after the sheet's spacing went to 0.1 for the arms); frames 2..450
of the scene looked at for the loop.

Revision (face): the first face (eyes 0.17 x 0.26, mouth 0.2 x 0.2 at spacing 0.07) read as one dark blob
covering the head; shrunk to the sizes above with the face's spacing at 0.05 (under the texel, but 2 splats
across the smallest part). Gates: the bake (no specks warning), hedra front/right/top views, the scene
frames 0..90 and 540..580 (the face towards the camera) looked at; three scene goldens re-snapped.
