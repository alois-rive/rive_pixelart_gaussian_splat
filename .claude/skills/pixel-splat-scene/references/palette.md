# Step 2: the palette, its ramps, and dithering

## The palette file

```json
{
  "name": "Endesga 32",
  "colors": ["#be4a2f", "...", "#c28569"],
  "ramps": {
    "foliage": ["#193c3e", "#265c42", "#3e8948", "#63c74d", "#fee761"],
    "stone":   ["#181425", "#262b44", "#3a4466", "#5a6988", "#8b9bb4", "#c0cbdc"],
    "glow":    ["#feae34", "#fee761", "#ffffff"]
  },
  "roles": { "sky_top": "#124e89", "sky_bottom": "#0099db", "fog": "#8b9bb4", "void": "#181425" }
}
```

- **colors**: at most 64 (the renderer's table); 16 to 32 is the style.
- **ramps**: at most 32, each 1 to 8 colours **dark to light**. A colour may
  sit in several ramps (shared darks are good: they tie materials together).
  Materials are mapped to ramps in the bake file; the painted colour picks
  the step.
- **roles**: the sky's two colours, the fog colour, the void (the artboard
  background). Pick a fog colour that sits in the scene's far colours
  (a desaturated mid tone), never pure white or black.

```sh
python3 $K/scripts/palette.py lospec <slug> -o art/palette.json    # a Lospec palette, ramps proposed from its own ordering
python3 $K/scripts/palette.py check art/palette.json     # each ramp: luma per step, hue travel, "ok" or "NOT dark to light"
python3 $K/scripts/palette.py swatch art/palette.json -o art/palette.png
```

`lospec` fetches `https://lospec.com/palette-list/<slug>.json` and splits the
colour list into runs (designer palettes list their ramps in order: Apollo's
six 6-step ramps come out exactly). The proposal is a start: rename ramps for
materials, fix the ones that break, choose the roles by eye.

`assets/palettes/endesga32.json` is a starter: Endesga 32 with 13 ramps and
roles. Any Lospec palette works once its ramps are written.

## Small palettes (16 colours and fewer)

Most pixel-art palettes have 16 colours or fewer, which changes how ramps are
built:

- **Ramps share colours.** There are not enough colours for separate ramps,
  so the darkest one or two colours sit at the bottom of most ramps (the
  shared shadow ties the scene together) and the brightest at the top of
  several. Keep each ramp 3 to 5 steps.
- **Every colour belongs somewhere**: in a ramp or a role (`check` lists the
  strays). A palette colour nothing uses is a wasted sixth of a ramp.
- **Materials are told apart by ramp, not by base colour**: two materials may
  paint the same colour and shade differently (snow and stone can share their
  mid-grey step).
- **Ramps that start at black** (many 16-colour palettes, PICO-8): a base on step 1
  turns black in shade or under the ink. Paint on step 2 or higher, use
  `shadeSteps` 1, and accept that the ink there is black: with such a palette
  the "never black outlines" rule bends to the palette.
- **Pick the lit step with room**: a material painted on the top of a 4-step
  ramp cannot get a highlight, one painted on step 0 cannot shade.
- **Fewer colours on screen**: a frame typically uses 10 to 14 of 16.
  That is the look: do not add colours to rescue a material, change its ramp.
- **Six to eight colours**: most ramps share most of their colours; give each
  material its own painted step and let light, ink and texture carry the
  rest. A monochrome palette (eight greens) is a single long ramp that every
  material lives on at a different step.
- **A colour may repeat inside a ramp** (`["#222323", "#f0f6f0", "#f0f6f0"]`) to
  give materials different light responses with very few colours: the baker
  snaps a painted colour to its FIRST occurrence in the ramp, so reach a later
  one with the material's `"step"` offset.
- **Tiny unlit particles** (1 to 2 art pixels: snowflakes, sparks) on a ramp of
  two different colours get inked into rings; give them a ramp that repeats
  one colour.
- **Lifting a material in its scene**: a dark mole on dark soil reads once the
  scene's bake gives it `"step": 1`, while the hero bench keeps the sheet's
  colours for the gates. Use `"step"` for scene readability, not repainting.
- **No ambient light**: a face away from the sun always sinks the full
  `shadeSteps`; a material that must stay readable in shade needs a ramp
  whose lower steps are still distinct from the background.
- **Two to four colours** (Game Boy, 1-bit, CGA): every material shares the
  same few steps; shape and light carry the image, and materials are told
  apart by value (which step they are painted on), never by hue. Give each
  read its own value (sky, ground, the hero, the hot thing) and keep them
  apart in shade too: `shadeSteps` 1, a higher sun, little fog. Lift or sink a
  material with the bake's `"step"` rather than repainting a gated model. Use Bayer dither with a
  wide band (`splatDither` false, `bandDither` 0.6 to 1) so light reads as
  dither density, and tell materials apart by their painted step and texture.

## Building ramps

The look's shading is entirely "one step down the ramp in shade, one up
facing the sun", so ramps carry it:

- **4 to 6 steps.** The painted (lit) colour sits at step 1 to 3, with one or
  two below for shade and ink, one above for highlights.
- **Hue-shift along the ramp**: shadows lean cool (towards blue-purple),
  lights warm (towards yellow), up to ~20 degrees a step (Slynyrd). Endesga's
  foliage goes teal → green → yellow; its wood goes purple-brown → tan →
  cream. A ramp that only darkens reads as grey mud in shadow.
- **Saturation peaks in the middle**, falls towards both ends.
- **Even luma steps** (`check` prints them): a ramp with two near-equal steps
  bands invisibly; one with a huge jump (grass's `#63c74d` → `#fee761`) makes
  highlights loud, so keep `highlight` high (0.8) for such ramps' materials or
  give them a ramp without the jump.
- **Accent ramps** for the few things the eye must find (the player, a door,
  a pickup, a light): saturated, used sparingly against a muted world.
- **Emissive ramps** (`glow`) for `unlit` splats: they never shade, so only
  their painted step shows; the ink still steps them down at silhouettes.

Lospec palettes that work (hex lists at the links in
[sources.md](sources.md)):

| Palette | Colours | Character |
|---|---|---|
| Endesga 32 | 32 | warm, saturated, long natural ramps |
| Sweetie 16 | 16 | soft, few ramps; one material per ramp |
| PICO-8 | 16 | hard, toy-like; ramps are short, accents strong |
| Resurrect 64, AAP-64 | 64 | long ramps for big scenes and many materials |
| Apollo | 46 | muted, painterly |

Sweetie 16 as a starting file (write ramps for it the same way):
`1a1c2c 5d275d b13e53 ef7d57 ffcd75 a7f070 38b764 257179 29366f 3b5dc9 41a6f6 73eff7 f4f4f4 94b0c2 566c86 333c57`.

## Snapping colours to the palette

The scripts compare colours in **OKLab** (perceptual, Björn Ottosson's
matrices in `splatlib.py`), not RGB: an RGB nearest-colour picks muddy greys
for saturated darks. The baker snaps each sample to the nearest step **of the
material's ramp** (`"ramp": "wood"`), so a slightly-off painted colour still
lands on the right material; without a ramp it searches every ramp colour
and takes the first ramp holding the winner.

## Dithering

Three places dither, all ordered (no error diffusion: it crawls when anything
moves).

**Band edges** (in `splat.wgsl`). Light gives a continuous step offset `o`;
inside a band `bandDither` wide around each half step, a threshold decides
between the two steps:

| `splatDither` | Threshold | Looks like | Moves with |
|---|---|---|---|
| true (default) | a random number fixed to each splat | blotchy two-tone brushwork; at 2+ px splats, the gaussian character | the world: nothing swims when the camera moves |
| false | the 4 x 4 Bayer matrix on the art grid | the classic checker / cross-hatch gradient | the screen: it swims across a moving surface (the Obra Dinn problem) |

Bayer 4 x 4 (row-major, divided by 16, +0.5/16):
`0 8 2 10 / 12 4 14 6 / 3 11 1 9 / 15 7 13 5`.

`bandDither` 0 gives hard posterised bands, 0.35 a narrow dithered seam,
1 a full gradient. On a flat face whose light sits exactly at a band edge, a
wide band covers the whole face in the pattern: narrow it, or move the sun.

**Fog** (in `resolve.wgsl`): Bayer against
`f = clamp((z − fogStart) / (fogEnd − fogStart), 0, 1) × fogMax`, towards the
palette's fog colour: far geometry dissolves into a stipple
instead of blending (blending would leave the palette).

**Sky**: two palette colours, Bayer across a narrow horizon band
(`skyBlend`); keep it narrow, a wide dithered sky is noisy.

`jitter` (default 0) adds a random tone offset per splat: painterly mottling.
It reaches the ramp's ends (the grass's yellow), so keep it ≤ 0.5 and use it
on ramps without a loud top step.
