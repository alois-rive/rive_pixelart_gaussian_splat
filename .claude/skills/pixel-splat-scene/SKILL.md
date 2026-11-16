---
name: pixel-splat-scene
description: Make 3D scenes and games for the Rive CLI look like pixel art built from gaussian splats - low-poly models sampled into flat gaussian discs, drawn by an AnimaScript GPU renderer at a small art grid, shaded along the ramps of a limited palette, dithered, self-outlined, shown with hard pixels, animated (rigid and skinned glTF) and open to shader effects. Covers the whole pipeline - the asset list, Lospec palettes and ramps, Codex briefs for low-poly turnaround sheets and textures, modelling and animating with `hedra model` against the sheet with measured gates and goldens, textures for splats, dithering, baking GLBs into splat blobs, the tested WGSL shaders and renderer, cameras for any genre (fixed, follow, side view, top-down, orbit), composition, frame audits. Use whenever someone wants pixel-art 3D, a gaussian or point-splat look, a painterly or voxel-like 3D look in Rive, and whenever such a scene's or game's assets are planned, generated, modelled, animated, baked, rendered or checked.
---

# Pixel-art gaussian splats in Rive

The look: 3D that reads as hand-placed pixel art. Every surface is a crowd
of soft-edged blobs (gaussian discs lying in the surface) drawn into a small
grid of big square pixels. Colour never comes from lighting maths: each blob
sits on a **ramp** of a limited palette (dark to light, hue-shifting) and the
light moves it a step up or down. Silhouettes are drawn in a darker step of
the same material. Band edges and fog dissolve through ordered or per-splat
dither. Nothing on screen is off the palette, and every art pixel is a hard
block.

It is a rendering style, not a genre: it fits a diorama, a menu backdrop, a
side-scroller, a top-down or isometric game, a third-person or first-person
view, a cutscene, a title card. The renderer takes its camera from inputs
that the scene or the game drives, and nothing in the pipeline assumes a
particular kind of scene.

## The pipeline

```
 1 asset list ──► 2 palette + ramps ──► 3 concept sheets (Codex) ──► 4 refs (sheet_cut)
                                                                          │
 9 goldens + audit ◄─ 8 compose, wire ◄─ 7 lookdev gate ◄─ 6 bake ◄─ 5 model (hedra), gated per phase
```

| # | Step | Tool | Gate (a command, not an opinion) | Read |
|---|---|---|---|---|
| 1 | List every asset, with sizes, ramps, splat budgets, motion | `art/assets.md` | every asset has a size in metres, a class, ramps, a concept plan | [assets.md](references/assets.md) |
| 2 | Pick the palette and write its ramps (dark to light, hue-shifted) | `palette.py lospec / check / swatch` | every ramp dark to light; no stray colours | [palette.md](references/palette.md) |
| 3 | One low-poly turnaround sheet per hero asset; palette textures | `codex_image.py` | `sheet_cut.py` finds four uncropped views; a person approves | [concept-sheets.md](references/concept-sheets.md) |
| 4 | Cut the sheet into per-view references; write the spec | `sheet_cut.py` | the spec names a number for every part | [modeling.md](references/modeling.md) |
| 5 | Model and animate: blockout, form, surfacing, each phase a replayable command file | `hedra model` | `golden.py views --hedra` + `gate`: silhouette IoU, aspect drift | [modeling.md](references/modeling.md) |
| 6 | Bake the GLB into splats: blue-noise discs, colours snapped to ramp steps, bones | `splat_bake.py` | colour error 0.000, no "specks" warning | [textures.md](references/textures.md) |
| 7 | Render the splats in the real renderer, gate against the sheet | `golden.py views --rive`, `gate` | albedo colour drift, IoU at the splat tier | [modeling.md](references/modeling.md) |
| 8 | Compose (a bake file), scaffold the Rive project, choose and wire the camera | `splat_bake.py`, `scaffold.py` | `rive --verify`, `rive inspect` clean | [renderer.md](references/renderer.md), [games.md](references/games.md) |
| 9 | Frame audit, look at it at 1x and in motion, keep goldens | `palette.py frame`, `golden.py snap / check` | ≥ 97 % solid art pixels, ≤ 0.2 % off-palette; goldens exact | [style.md](references/style.md) |

Steps 3, 5 and 7 loop: a failed gate names what to fix (a proportion, a
part, a material, a starved part); change one thing and re-measure. A person
approves each concept sheet before modelling and each golden before it is
kept. Simple pieces (rocks, trees, props, terrain) may skip steps 3-4: their
row in the asset list is the brief (modeling.md, "Assets without a sheet").

## Decide these first

| Decision | Starting point | Why it matters |
|---|---|---|
| **Art grid**: screen points per art pixel (`pixelSize`) and the world height the view shows (`orthoHeight`, or the fov and distance) | 3 to 4 | they fix the **texel**, the world size of one art pixel; every other size derives from it |
| **Splat spacing** | 1.2 to 2 texels | at 1 texel or less the splats disappear into a plain low-res render; at 2 to 3 the blobby, painterly character shows; past 4 silhouettes turn ragged |
| **Palette** | 4 to 16 colours (Lospec), 3 to 9 ramps of 2 to 5 steps sharing their darks | the ramps ARE the shading; fewer colours read more as pixel art |
| **Camera** | whatever the game needs: fixed, follow, side view, top-down, isometric, orbit, first or third person ([games.md](references/games.md)) | orthographic can snap to the art grid so panning slides by whole pixels; perspective works, rotation re-rasterises every splat |
| **Motion** | baked tracks at 8 to 12 fps, stepped | stepped motion reads hand-animated; 60 fps motion reads as 3D |
| **Light** | one sun: key 0.45, highlight 0.8, 1.5 steps down, 1 up | most lit faces keep their painted step, faces towards the sun step up, faces away step down |
| **Dither** | per splat (world-stable), band width 0.35; Bayer for a retro ordered look | per-splat dither does not swim when the camera moves |

## The signature

| Trait | How it is made | Default |
|---|---|---|
| **Hard art pixels** | the scene renders into a W x H `GPUCanvas` (the art grid, plus one spare pixel per side) drawn with a **nearest** sampler, scaled by a whole `pixelSize` | 3 to 4 |
| **Gaussian splats, crisp edged** | surfaces sampled into Poisson-disk points; each a disc gaussian (sigma = spacing across, 0.3 x through), projected with EWA (`J W Σ Wᵀ Jᵀ` + 0.3 px² low-pass), **alpha-tested**, not blended: no sorting, a depth buffer does visibility | `threshold` 0.5, `fat` 1.0 |
| **2x supersample, voted** | the splat pass draws at 2W x 2H; the resolve votes the 2 x 2 samples per art pixel: lumpy splat edges settle into clean pixel clusters | `minCoverage` 2 |
| **Palette-exact colour** | the G-buffer stores palette indices; the resolve looks them up | 0 off-palette pixels |
| **Ramp shading** | per-splat light (N·L, shadow) moves the splat along its material's ramp | key 0.45, highlight 0.8 |
| **Dithered band edges** | the fractional step is thresholded per splat (world-stable) or by Bayer 4 x 4 on the art grid, inside a narrow band | per splat, 0.35 |
| **Self-coloured outline (ink)** | a drawn pixel next to sky, or in front of something farther than `edgeDepth`, drops `ink` steps down its own ramp | 1 step |
| **Chunky splat shadows** | the sun's shadow map is drawn by the same splats; each splat is lit or shadowed as a whole | 1024 map |
| **Dithered fog and sky** | fog: a Bayer threshold towards the palette's fog colour; sky: two palette colours across a narrow band | off |
| **Low-poly, faceted models** | flat shading, parts no thinner than ~1.5 splats, holes no narrower than a few | [assets.md](references/assets.md) |
| **Animation, stepped** | rigid parts and skinned meshes from glTF, pre-sampled per instance at `fps`, one frame per track copied into a bone buffer | 12 fps |
| **Shader effects that stay pixel art** | a hook (`fxApply`) on splats flagged `fx` moves, hides or recolours them by ramp step: reveals, dissolves, glitches, highlights | [renderer.md](references/renderer.md) |

## What breaks the look: never

- A colour that is not a palette colour: a texture painted off-palette, a
  blended (soft-alpha) splat, a bilinear blit, MSAA on the art canvas.
- Lighting baked into textures (painted shadows, AO, gradients): the renderer
  shades by ramp steps, a painted shadow is shaded again.
- Detail smaller than two splats: texture speckle, parts that read as dotted
  specks, holes that close up. Exaggerate it, bake it finer, or drop it.
- Pure-black shadows and outlines (unless the palette's ramps start at black),
  more than one sun, a different palette per asset.
- A non-integer `pixelSize`, or a layout scaled after the blit: art pixels of
  two sizes. A HUD on another pixel grid than the scene's.
- Smooth subdivided models: the splats follow them and the faceted,
  hand-made read is lost.

## The renderer at a glance

```
blob.bin ──► bone buffer   (64 x 3x4 matrices: animation frames, or the game's own transforms)
         ├─► shadow pass   (sun view, depth only, the same splats)          shadow map
         └─► G-buffer pass (camera, 2W x 2H): instanced quads, EWA conic, fx hook,
              alpha test, ramp step + dither → rgba8 (palette idx, ramp, step, flags) + depth
                       └─► resolve pass (W x H): 2x2 vote, ink, fog, sky → palette colours
                                  └─► Renderer.drawImage(canvas.image, nearest) scaled by pixelSize
```

`assets/template/` holds the tested files: `splat.wgsl`, `resolve.wgsl`,
`splat_scene.as` (the `Layout`: blob, uniforms, camera, passes, blit, input
overrides) and `scene.rml` (the ScriptedLayout, its inputs, the BlobAsset).
[renderer.md](references/renderer.md) has every input, the uniform layouts,
the blob format, the traps and how to extend it; [games.md](references/games.md)
how a game drives the camera, moves objects, layers a HUD and stays fast. A game's
logic lives in one file, `game.as` (the renderer calls it every frame with a `GameApi`:
game bones from the bake, camera, pointer picking, a pixel HUD, a seeded random, demo
mode); the renderer files are never edited in a project.

## Files

```
pixel-splat-scene/
  SKILL.md                          this
  references/assets.md              step 1: the asset list, classes, sizes, budgets, what to model vs paint
  references/palette.md             step 2: palettes, ramps, hue shift, small palettes, dithering
  references/concept-sheets.md      step 3: Codex briefs for turnaround sheets and textures, review, retries
  references/modeling.md            steps 4-5, 7: spec, hedra phases and animation, gates, thresholds, goldens
  references/textures.md            texture style for splats: palette-exact, flat, big shapes, texel density
  references/renderer.md            the shaders and the AnimaScript renderer: inputs, uniforms, blob, fx, traps
  references/games.md               cameras for every genre, the game hook (game.as), demo mode, HUD, input, performance
  references/style.md               the look in depth, tuning recipes, the frame audit, motion
  references/sources.md             the references behind the choices
  assets/template/                  splat.wgsl, resolve.wgsl, splat_scene.as, game_api.as, game.as (a game's own file),
                                    scene.rml (with the Sample view model: demo), rive.yaml, scene.bake.json
  assets/palettes/endesga32.json    a starter palette with ramps and roles
  scripts/palette.py                lospec (fetch + ramps), check, swatch, fit (image -> palette), audit, frame
  scripts/codex_image.py            one Codex image generation into a known file, with a record
  scripts/sheet_cut.py              a turnaround sheet into per-view cut-outs, masks, aspects
  scripts/golden.py                 turnaround renders (hedra or splats), the gate, goldens snap / check
  scripts/splat_bake.py             GLB(s) -> splat blob (Poisson discs, ramp steps, flags, bones, tracks)
  scripts/scaffold.py               a scene project (RML) or a lookdev bench (no RML)
```

Tools: `rive` 1.9+ (AnimaScript, `scripting: wasm`), `hedra` 0.1+ (`hedra
model`; `hedra skill install` adds its `hedra-model-*` skills, which this one
builds on), the Codex CLI logged in (`codex login status`), Python 3 with
NumPy and Pillow (`/usr/bin/python3` on macOS has both). `$K` below is this
skill's directory, `<a>` an asset's name.

## A run, end to end

```sh
K=.claude/skills/pixel-splat-scene
python3 $K/scripts/palette.py lospec <slug> -o art/palette.json          # then edit its ramps and roles
python3 $K/scripts/palette.py check art/palette.json
python3 $K/scripts/codex_image.py --brief art/<a>/sheet.v1.prompt.md --out art/<a>/sheet.v1.png
python3 $K/scripts/sheet_cut.py art/<a>/sheet.v1.png -o art/<a>/refs
hedra model --text models/<a>/<a>.rmdl run models/<a>/p1_blockout.txt
python3 $K/scripts/golden.py views --hedra models/<a>/<a>.rmdl -o models/<a>/shots/p1 --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/<a>/refs --shots models/<a>/shots/p1 -o models/<a>/shots/p1/compare.png --min-iou 0.75
hedra model --text models/<a>/<a>.rmdl run models/<a>/p2_form.txt && hedra model models/<a>/<a>.rmdl export models/<a>/<a>.glb
python3 $K/scripts/scaffold.py lookdev --lookdev
python3 $K/scripts/splat_bake.py models/<a>/<a>.bake.json                 # -> lookdev/<a>.bin
python3 $K/scripts/golden.py views --rive lookdev --blob <a> -o models/<a>/shots/p4 --look albedo
python3 $K/scripts/golden.py gate --refs art/<a>/refs --shots models/<a>/shots/p4 -p art/palette.json --min-iou 0.7
python3 $K/scripts/golden.py views --rive lookdev --blob <a> -o models/<a>/shots/final && python3 $K/scripts/golden.py snap --shots models/<a>/shots/final --goldens goldens/<a>
python3 $K/scripts/scaffold.py scene && cp $K/assets/template/scene.bake.json .    # edit: models, transforms, ramps
python3 $K/scripts/splat_bake.py scene.bake.json                          # -> scene/splats.bin; then set the camera in scene/scene.rml
rive scene --verify && rive inspect scene --summary && rive scene --screenshot=$PWD/shots/frame.png --advance=2
python3 $K/scripts/palette.py frame shots/frame.png -p art/palette.json --pixel 3
rive scene                                                                # the live preview
```

## Rules that outrank taste

**The texel decides every size.** Splat spacing, the thinnest part, the
narrowest hole, the smallest texture shape, the outline depth: each is a
multiple of the world size of one art pixel. Choose the art grid first.

**Colour is an index until the last pass.** Materials are ramps, textures are
palette-exact, the G-buffer and every effect hold indices. A colour that was
never a palette colour can never reach the screen.

**Light moves along ramps.** Paint the lit colour; the renderer finds the
shade and the highlight on the same ramp. Never paint light.

**Measure, then look, then ask.** Every phase ends in a gate command; then
look at the frame at 1x and in motion; then a person approves the concept and
the golden. A gate is never loosened to pass a model: threshold tiers are
chosen before the build, and a waiver is written into the spec with its reason.

**One change per iteration.** A failed gate names a view, a height and a
material. Change the one thing it names, regenerate, re-gate.
