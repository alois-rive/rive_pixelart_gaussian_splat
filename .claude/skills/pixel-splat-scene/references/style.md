# The look in depth: tuning and auditing a frame

## What makes it read as "pixel-art gaussian splats"

1. **Big hard pixels on a fixed grid.** The art grid is small (130 to 270
   rows) and every art pixel is a block of `pixelSize` screen pixels. The
   frame audit checks this.
2. **Surfaces made of blobs.** At a spacing of 1.2 to 2 texels each splat is
   2 to 4 art pixels across; the per-splat dither and the 2 x 2 vote turn
   neighbouring splats of different steps into clusters of two or three
   tones, like a painter's dabs. Silhouettes are lumpy at the splat scale,
   not polygon-straight.
3. **A limited palette, used as ramps.** Shade is a ramp step, highlight is a
   ramp step, outline is a ramp step. 15 to 25 colours on screen at once.
4. **Self-coloured outlines.** A one-step-darker rim of each material against
   the sky and against far things: separates forms without black lines.
5. **Chunky shadows** cast by splats: their edge is splat-shaped.

Prior work in the same spirit (see [sources.md](sources.md)): ink-studio
(sculpted SDF solids baked to palette-quantised gaussian splats, a 2x render
resolved by voting, ink in a body colour), Texel Splatting (Ebert 2026,
world-space texel quads with OKLab posterised light), Dreams (point splats
into a G-buffer), t3ssel8r-style 3D pixel art (low-res render, camera
snapping, depth/normal edges).

## Tuning recipes

| You see | Change |
|---|---|
| looks like a plain low-res render, no blobs | spacing too small for the texel: bake with a larger `spacing` (1.5 to 2 texels), or zoom in (`orthoHeight` down) |
| ragged, moth-eaten silhouettes | spacing too large (> 3 texels): smaller `spacing`; or `minCoverage` 1 |
| holes or dark specks inside surfaces | discs too thin to cover the Poisson gaps: `fat` ≥ 1.0 in the bake, or `splatScale` 1.1 |
| a flat face covered in a checker | its light sits on a band edge: narrow `bandDither`, move the sun, or `splatDither` on |
| everything a step too dark | `keyLight` too high for the sun's pitch (vertical faces get at most cos(pitch)): lower it (0.35 to 0.5) |
| ground full of highlight speckle | `highlight` too low: raise it (0.8 to 0.9); a ramp with a loud top step needs it high |
| no form in shade | `shadeSteps` 1.5 to 2, a darker ramp bottom, or a lower sun |
| everything dissolved in a fog stipple | `fogStart`/`fogEnd` are metres behind the camera target: start at 0 to a few metres, `fogMax` 0.3 to 0.5 |
| outlines everywhere inside objects | `edgeDepth` too small for the scene's scale: about the depth of a hero prop |
| no outlines between overlapping objects | `edgeDepth` too large |
| shadow acne (dark mottling on lit, curved surfaces; stripes on the ground) | `shadowOffset` up (in splat spacings, default 1.5) or `shadowBias` (default 0.5); confirm with `--arg shadows=0` |
| a lit side jumps to what looks like another material (red cap → flat orange) | the ramp's step above the painted one turns hue too far: raise `highlight`, set `lightSteps` 0.5, or give the material a ramp whose top step stays in its hue |
| a dithered horizon line cuts behind a small object | `horizon` 2 (a flat `sky_top`), or move the split above the object |
| shimmer when the camera pans | perspective camera (cannot snap): use orthographic; or Bayer dither swimming: `splatDither` on |
| the scene too busy | fewer colours per material, shorter ramps, no `jitter` |
| a letter, a slot or a window filled in | negative space shrinks by two splat radii: widen it or erode the faces around it, bake that part finer |
| a big blob floating in front of the scene (perspective) | a small object close to the camera: move it far beyond the camera distance |
| the hero lost in the scene | an accent ramp only it uses, a larger size (pixel-art exaggeration), the ink |

## The frame audit

```sh
rive scene --screenshot=$PWD/shots/frame.png --advance=2
python3 $K/scripts/palette.py frame shots/frame.png -p art/palette.json --pixel 3
```

- **solid blocks**: the share of `pixelSize` x `pixelSize` blocks that are a
  single colour, at the best grid phase (the blit is centred, so the grid can
  start anywhere): ≥ 97 % (a clean frame is 100 %). Less means a filtered blit,
  a fractional `pixelSize`, or something drawn at screen resolution over the
  scene (count that HUD in your budget).
- **off-palette**: pixels whose colour is not in the palette: ≤ 0.2 %
  (a clean frame: 0 %).

Then look at it at 1x and zoomed (nearest), and once in the live preview
(`rive scene`) with the camera moving: shimmer, swimming dither and popping
splats show only in motion.

## Motion

- **Camera**: a translating orthographic camera (scrolling, following,
  panning) snaps to the art grid and slides by whole screen pixels. A
  rotating camera (orbit, a third-person turn) re-rasterises every splat:
  keep turns slow (5 to 15 degrees a second) or stepped, or keep the view
  fixed. Camera kinds per genre: games.md.
- **Wind**: `sway` splats move a few centimetres (`windAmp` 0.03): the
  foliage twinkles at splat scale without changing shape.
- **Time of day**: animate `sunYaw` / `sunPitch` (bind or key the
  ScriptInputs); swap the sky roles by baking with another palette roles
  block, or add sky inputs.
- **Animated models**: baked tracks play stepped at their bake `fps`
  (8 to 12 reads as pixel art, pose to pose; 60 fps smooth motion reads as
  3D). Give copies of one animated model different `phase`s.
- **Effects as rigid animation**: a falling or rising field (snow, rain,
  leaves, sparks, bubbles) is a field of tiny unlit cubes moving one
  field-height per loop (two stacked copies make it seamless). Keep the field
  inside what hides its wrap (the ground, the water, the frame's edge).
- **Effects as shader FX**: reveals, dissolves, glitches, hit flashes, a
  highlight sweeping a pickup: the `fxApply` hook (renderer.md, "Shader FX").

## Light that moves without a shader: fire-lit smoke

The renderer lights splats by the sun only, so a flickering fire lighting its
own smoke is built from geometry. Give each smoke puff unlit warm caps on its
underside (a hot step and a cooler one), each its own bone, keyed to pop out
of the puff when the fire is bright for that puff's height and to sink back
inside it otherwise. Key the caps and the flame tongues from one intensity
table, and give the puffs whole-second phases, so every puff stays in step
with the fire: the low puffs flare with each flame, the middle ones only on
the big flares, the top ones never.

## Pools of light from moving things

The renderer has one sun. A glowing worm, a lantern or a torch lights its
surroundings with geometry: a flat disc under it, alpha-masked into a stipple
(a dithered falloff) on an unlit ramp step, moved with it as part of its bone.
On a dark ground this reads as light in two or three colours.

Bayer fog over a flat unlit backdrop reads as a dotted grid: keep fog off
backdrops, or give them some shading.

**Two-tone noise on big shaded walls.** With `shadeSteps` 1.5 (the default) a
fully shaded flat face sits exactly on a band edge, and the band dither turns
it into a checker. Use `shadeSteps` 1 or 2 for scenes with big flat walls.

