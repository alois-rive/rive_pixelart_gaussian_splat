# Textures for splats

A texture is not drawn by the renderer at all: the baker samples it **once per
splat** (nearest texel at the splat's UV) and snaps that colour to a step of
the material's ramp. Everything below follows from that.

## The rules

| Rule | Why | Check |
|---|---|---|
| **Palette-exact**: only colours of the material's ramp (plus accents from other ramps on purpose) | the bake snaps anything else to the nearest step, and a near-miss colour lands on the wrong step | `palette.py audit --ramp grass`; the bake's `colour error 0.000` |
| **Paint the lit colour, never light** | the renderer moves each splat down the ramp in shade and up facing the sun; a painted shadow is shaded twice and a painted highlight blows out | look: no gradients, no AO, no rim light in the texture |
| **Base step in the middle of the ramp** | shading needs room: 1 to 2 steps below, 1 above. A material painted on the ramp's darkest step has nowhere to shade | choose ramps of 4 to 6 steps; paint steps 1 to 3 |
| **Shapes at least two splats wide** | one texel per splat: a shape smaller than a splat is sampled by one splat or none, and reads as a speck or vanishes | texel ≈ 1 to 1.5 spacing; `audit` lone texels ≤ 3 % |
| **Few colours**: 2 to 5 per material | each colour is a ramp step that shading moves further; five painted steps over a five-step ramp leave no range | `audit --max-colors` |
| **Flat, hard-edged shapes** | soft edges are in-between colours that snap unpredictably | `fit` with the majority method |
| **Tiny textures** | 8 x 8 to 64 x 64: the texel is world-sized (0.1 to 0.3 m), not screen-sized | a tiled roof: 20 x 8; a grass top: 32 x 32 over 6 m |
| **Nothing flat layered on a surface** | coplanar overlays fight at splat size (one depth per disc) | paint paths, signs, cracks into the surface's texture |

## Texel density

```
texel (m) = surface size (m) / texture size (texels)        aim: 1 to 2 x splat spacing
```

A 6 m wide grass top with a 32-texel texture: 0.19 m a texel, 2.1 splats at
0.09 m spacing. A brick wall at 0.09 m spacing wants bricks of
2 x 1 texels at ~0.18 m a texel: a 16 x 16 texture covers 3 m.

Use `uv project-from-view <view> --scale-to-bounds` for one texture over a
face, `uv reset` to give each face the whole square (slabs, planks),
`uv cube-project` for blocky props. Wrapping repeats (`% 1.0` in the baker).

## Vertex colour or material colour

Most low-poly parts need no texture: one material per colour region, its base
colour set to the ramp step (sRGB 0..1). A typical hero prop is six to ten
materials and at most one or two textures. Reach for a texture when a single surface carries several regions
whose shapes matter (tiles, patches, flowers), never for noise.

## Making one

- **Drawn by a script**, exact, for regular patterns: tiles, planks, bricks,
  stripes. A tiled roof of two reds:

  ```python
  from PIL import Image
  a, b = (0xa2, 0x26, 0x33, 255), (0xe4, 0x3b, 0x44, 255)
  im = Image.new("RGBA", (20, 8))
  for y in range(8):
      for x in range(20):
          off = 2 if (y // 4) % 2 else 0
          im.putpixel((x, y), b if ((x + off) // 4) % 2 == 0 else a)
  im.save("textures/roof_tiles.png")
  ```

- **Generated** with Codex for irregular, hand-painted shapes (the brief is in
  [concept-sheets.md](concept-sheets.md)), then fitted and audited:

  ```sh
  python3 $K/scripts/palette.py fit grass.v1.png -p palette.json -o grass_32.png --size 32 --ramp grass
  python3 $K/scripts/palette.py audit grass_32.png -p palette.json --ramp grass --max-colors 4
  ```

- **Painted by a person** in a pixel editor with the palette loaded (Aseprite,
  Pixelorama): the best results, and the same audit.

## Alpha

Alpha-masked materials (`alpha-mode mask`, leaf cards, fences) are cut at
bake time: a sample under the cutoff makes no splat. Keep the mask's shapes
splat-sized like the colours, and mark the material `double` (two-sided).

A material's texture is snapped into the material's ramp: an accent painted in
another ramp's colour (yellow stars on pink wallpaper) silently turns into the
nearest step of this one, with only a colour error to show for it. Give the
accent its own material (and ramp), or leave the material's `"ramp"` unset so
each texel finds its nearest ramp.

