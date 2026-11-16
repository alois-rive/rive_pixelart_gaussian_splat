# Assets: the Rive opener

Art grid: 640 x 400 artboard, `pixelSize` 3; a perspective camera (fov 32) 9.5 m from the word.
Palette: the Rive brand's own (`palette.json`, 12 colours): black, #141414, the theme greys
#5C5C5C and #A0A0A0, #E0E0E0, white, Rive Amber #FFA41C, and the six Portal Prism colours (one
single-step ramp each, in brand order, so the shader can pick them by index).

| Asset | Class | Size (m) | Ramps | Source | Motion |
|---|---|---|---|---|---|
| wordmark | hero mark | 5.40 x 0.96 x 0.35 | mark (white, flag `fx`) | `models/logo/make_wordmark.py`: the brand kit's Wordmark path data, extruded, shrunk 0.045 m against the splats' spread | the renderer's shader FX cycle (12 s) |
| plinth | base | 6.1 x 0.22 x 1.05 | floor (#5C5C5C top, #141414 sides) | same script | none |

The FX cycle (splat.wgsl, `fxApply`), stepped at 12 fps, in the brand's motion vocabulary
(rive-branding `references/motion.md`): a left-to-right cascade with the brand flicker
(0.2, 1, 0.5, 1); a Portal Prism band crossing the letters in order and pushing them forward; a
glitch of slices stepping sideways, a few in Rive Amber; an amber scanline over a ripple; a
dissolve upwards. Nothing else moves; there are no particles.
