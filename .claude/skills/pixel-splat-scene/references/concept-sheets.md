# Step 3: concept sheets and textures with Codex

Codex's agent has an image-generation tool. `scripts/codex_image.py` runs
`codex exec` non-interactively, asks for exactly one image, has the agent
copy it to the path you chose, falls back to
`~/.codex/generated_images/<session>/` when it did not, and writes a record
beside the image (`<out>.json`: the brief, inputs and their hashes, the
session, seconds, `reviewed: false`).

```sh
codex login status                                      # once: "Logged in using ChatGPT"
python3 $K/scripts/codex_image.py --brief art/<a>/sheet.v1.prompt.md --out art/<a>/sheet.v1.png
python3 $K/scripts/codex_image.py --brief ... --out ... --image art/<a>/sheet.v1.png   # attach a reference
python3 $K/scripts/codex_image.py --brief ... --out ... --dry-run                       # the command and prompt
```

A run takes 45 to 90 s. A generation is never overwritten: the next attempt
is `sheet.v2.png`, with its own brief file. Never use an image straight from
`~/.codex/generated_images/`.

## The turnaround brief

Write it to `art/<asset>/sheet.v<N>.prompt.md` before running. Order matters:
the generator follows the first constraints best, so the layout comes first.

```markdown
A modeling reference sheet (turnaround) for ONE low-poly 3D game asset: <one line: what it is>.

Canvas and layout, keep exactly:
- 1536 x 1024 landscape image, a 2 x 2 grid of four equal panels.
- Top-left panel: FRONT view. Top-right: RIGHT side view. Bottom-left: BACK view. Bottom-right: TOP view (looking straight down).
- Orthographic cameras (no perspective), the same scale in every panel, the object centred in each panel and standing on the same invisible ground line in the three side views.
- For a long object (a box, a boat, a board), describe the RIGHT view first by its own proportions ("narrower than the front, N times as deep as it is wide") and say it is NOT a copy of the front view: the generator otherwise duplicates the front panel.
- For a round or patterned object (a ball's gores, stripes, a dial), spell out what each panel shows ("FRONT: the red gore centred, white to its left..."): left to itself the generator reorders the pattern from panel to panel.
- Every view sits whole inside its panel with a clear margin of background all round (at least a tenth of the panel): nothing touches or crosses a panel edge.
- Each side view is exactly frontal to its side: no other face of the object shows in it (a slightly oblique view comes out wider and fails the aspect gate).
- The four panels show the SAME object, only turned: FRONT: the object faces the camera. RIGHT: the camera has walked round to the side that was on the RIGHT of the image in the front view (the object's own left-hand side), so the object faces the LEFT edge of the image; a sword held in the object's right hand is on the far side. BACK: seen from behind. TOP: seen from straight above, looking down, with its front towards the BOTTOM edge of the image and no wall showing. Each detail appears only in the views from which it is really visible (a part seen side-on in one view is seen end-on in another).
- One flat, uniform background (<a grey far from every palette colour: #d9d9d9, or #9a9a9a when the palette has near-whites>) everywhere: no floor, no cast shadow, no gradient, no vignette, no frame lines, no text, no labels.

The object (identical in all four views):
- <each named part: its shape, its size in metres, where it sits in the FRONT view>
- <the asymmetric details and which side they are on: "a sword in the right hand", "a handle on the right end">

Style, keep exactly:
- A clean low-poly 3D model render: faceted, flat-shaded faces, hard straight edges, big readable chunky shapes, about <budget> triangles worth of detail. No smooth organic surfaces, no tiny details, no texture noise, no grain.
- Flat colour areas only, from these colours: <material>: <hex> <hex>, ... (the ramp steps of the palette, base step first)
- Soft, even light from the upper left, so each face reads as one flat tone; no specular highlights, no ambient occlusion blur.
```

Why each line is there:

| Line | Because |
|---|---|
| 2 x 2 grid, named panels, 1536 x 1024 | `sheet_cut.py --grid 2x2 --views front,right,back,top` cuts by position; the generator's own landscape size |
| same scale, same ground line | the gate compares aspect ratios per view; the spec measures every part off one scale |
| a flat grey far from the palette, no floor, no shadow, no text | the cut-out takes the background from the panel corners; a shadow or a label becomes part of the silhouette |
| low-poly, faceted, flat-shaded, chunky | the model will be built from primitives in hedra; a smooth, detailed concept cannot be matched and teaches the wrong forms |
| palette hex per material | the colours land on ramp steps, so the albedo gate (colour share per ramp) is meaningful and the person sees the scene's palette already. Use the FINAL palette: a sheet painted in another palette snaps to the wrong ramps (with 16 colours, a grey-white snow becomes a cream that belongs to wood) and fails the colour gate for no fault of the model. If the palette changes after concepting, regenerate the sheet (`sheet.v2`) |
| sizes in metres | the generator keeps relative proportions better when told them; the spec still measures the image, not the brief |
| even light, no AO | each face reads as its material colour, not as lighting to undo |

## Checking a sheet

```sh
python3 $K/scripts/sheet_cut.py art/<a>/sheet.v1.png -o art/<a>/refs
```

Prints each view's box, aspect (height / width) and fill, writes
`<view>.png` (cut out), `<view>.mask.png` and `views.json`, and exits 1 when a
panel is empty or its object touches the panel edge (cropped). Then look:

- **Consistency**: the same asymmetric details on mirrored sides in front and
  back (a handle on the right in front is on the left from behind), the same
  part count in every view.
- **Camera**: generated "orthographic" side views are often drawn from a few
  degrees above (the top of a ring or a box shows). Measure it (visible rim
  depth / width ≈ sin(elevation); 5 to 8 degrees is common) and render the
  model's gate views at that elevation (`golden.py views --elevation 7`).
  Do not model the rim top as height.
- **Views that disagree with each other** (a roof 0.94 m deep from the top
  and 1.13 m from the side): decide which views lead (usually front and top),
  write it under Assumptions in the spec, and expect the other view to need a
  waiver.
- **Orientation**: hedra's `right` view looks along −X, so a model facing −Y
  faces **left** in it, and its `top` view has the front at the bottom. Say so
  in the brief (the template does). When a sheet still draws the side view
  facing right or the top view nose-right, cut it with `sheet_cut.py --flip
  right --rotate top=-90`: a mirror is honest only for a left-right symmetric
  object (most vehicles and creatures); an asymmetric one is regenerated.
- **Off-brief detail**: extra parts, text, a floor shadow. Regenerate rather
  than edit.

Retries: a failed check is a new version. Change one thing in the brief,
restating the failed constraint first and more concretely ("in the TOP panel
the roof covers the base except its front and back edges"). Three versions
failing the same way means the brief asks for something the generator will
not draw: show the person the three and decide together.

**A person approves every sheet before modelling starts**; set `"reviewed":
true` in its record only then. Generated images can carry things that must
not ship (likenesses, logos, text).

## Texture briefs

For a material whose surface carries shapes (a grass top with patches and
flowers, roof tiles, planks, cobbles):

```markdown
A seamless, tileable top-down texture of <surface> for a low-poly pixel-art game, to be shrunk to <32> x <32> pixels.

Keep exactly:
- 1024 x 1024, square, seamless on all four edges (it repeats).
- Flat colour shapes only, no gradients, no lighting, no shadows, no blur, no noise, no grain, no photo detail.
- Big, simple shapes: <base colour hex> covering about 70 percent, <shape> in <hex> about one tenth of the image wide each, ...
- Only those <n> colours. Nothing smaller than one twentieth of the image: anything finer disappears when shrunk.
- No text, no border, no frame.
```

Then fit it to the texel and the ramp, and audit:

```sh
python3 $K/scripts/palette.py fit art/textures/grass.v1.png -p art/palette.json -o art/textures/grass_32.png --size 32 --ramp grass
python3 $K/scripts/palette.py audit art/textures/grass_32.png -p art/palette.json --ramp grass --max-colors 4
```

`fit` quantizes at full size and lets each output texel take its block's
majority colour (`--method majority`, the default): a flower survives as a
whole texel or vanishes, never as a smear of in-between greens (a box filter
averages first and makes exactly that smear). Codex may return 1254 x 1254
instead of 1024: `fit` does not care.

Small regular patterns (tiles, planks, bricks) are faster and exact drawn by
a script: a tiled roof is a 20 x 8 PNG of two reds made in five lines
(textures.md).
Generate when the shapes should look hand-painted and irregular.
