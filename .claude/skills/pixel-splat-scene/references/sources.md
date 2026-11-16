# Sources

What each reference contributed. Unverified claims are marked.

## Pixel-art gaussian splats and point splatting

- **ink-studio** (Shapeshift Labs): sculpt SDF solids, bake them into pixel-art
  gaussian splats (16 floats a splat: position, density, covariance, packed
  colour, motion), render with EWA covariance projection plus a 0.15 low-pass,
  back-to-front blending with solid splats sharpened by `smoothstep(0.38,
  0.62, g)`, a 2x render resolved by 2 x 2 palette voting (`PixelLook`),
  silhouettes inked in a darker tone of the body colour, palette ramps that
  turn hue as they darken (`km-ramp`), weighted RGB distance (0.30, 0.55,
  0.15), Bayer 4 x 4 dither. https://github.com/siliconjungle/shapeshift-labs-ink-studio
  (this skill's alpha test, 2x vote, self-coloured ink and ramps follow it).
- **Texel Splatting** (Dylan Ebert, 2026): scene rasterised into probe
  cubemaps, texels shaded with OKLab-posterised bands, splatted as world-space
  quads; silhouettes from object-ID changes. https://arxiv.org/html/2603.14587v1
- **Dreams** (Media Molecule, SIGGRAPH 2015 "Learning from failure"): points
  splatted into a G-buffer, later "fluff" splats with stochastic alpha.
  https://advances.realtimerendering.com/s2015/AlexEvans_SIGGRAPH-2015-sml.pdf,
  summary https://andrewkchan.dev/posts/lit-splat.html
- **3D Gaussian Splatting** (Kerbl et al. 2023): `G(x) = exp(−½ xᵀΣ⁻¹x)`,
  `Σ' = J W Σ Wᵀ Jᵀ`, alpha clamped to 0.99, low-pass dilation.
  https://arxiv.org/abs/2308.04079 . Popping from per-splat depth: StopThePop
  https://r4dl.github.io/StopThePop
- Surface splatting with Poisson-disk sampling on meshes (area-weighted
  triangles, minimum-distance thinning): David Holland,
  https://davidholland.netlify.app/articles/3d-pixel-art-rendering

## 3D rendered as pixel art

- David Holland (after t3ssel8r): orthographic camera snapped to a
  texel-sized grid with the remainder applied to the upscaled output;
  4-neighbour depth/normal edges (depth darkens, convex normal edges
  brighten); toon light. https://davidholland.netlify.app/articles/3d-pixel-art-rendering
- Unity recreation of t3ssel8r's edges (thresholds, concave edges rejected):
  https://kyriota.com/2022/08/02/UnityPixelatedArtStyleInURP/
- Snapping only fully solves orthographic cameras (ProPixelizer):
  https://sites.google.com/view/propixelizer/user-guide-v2-0 ; subpixel
  offset (UPixelator): https://github.com/Radivarig/UPixelator_Documentation
- Dead Cells: 3D models rendered tiny without antialiasing, cel-shaded,
  pose-to-pose; "keep models simple".
  https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i-
- Shadowglass: limited palettes for readability; ambient washes out detail.
  https://80.lv/articles/interview-how-project-shadowglass-creates-its-impossible-fully-3d-pixel-art-look

## Dithering and colour

- Joel Yliluoma, arbitrary-palette ordered dithering, Bayer matrices:
  https://bisqwit.iki.fi/story/howto/dither/jy/
- Obra Dinn's dither pinned to a camera-centred sphere (stable under rotation,
  not translation), and a surface-stable alternative: https://runevision.com/tech/dither3d/ ,
  https://github.com/runevision/Dither3D
- Blue noise textures (Christoph Peters): https://momentsingraphics.de/BlueNoise.html
- OKLab (Björn Ottosson): https://bottosson.github.io/posts/oklab/
- Hue-shifted ramps, saturation peaking mid-ramp (Slynyrd):
  https://www.slynyrd.com/blog/2018/1/10/pixelblog-1-color-palettes
- Lospec palettes: Endesga 32 https://lospec.com/palette-list/endesga-32 ,
  Sweetie 16 https://lospec.com/palette-list/sweetie-16 , PICO-8
  https://lospec.com/palette-list/pico-8 , Resurrect 64
  https://lospec.com/palette-list/resurrect-64 , AAP-64
  https://lospec.com/palette-list/aap-64 , Apollo https://lospec.com/palette-list/apollo

## Turnaround sheets

- Generic guidance (vendor and guide advice, not tested results): neutral
  pose, consistent features across views, same scale and baseline, plain
  background, labelled views.
  https://ai-flow.net/templates/character-sheet-generator/ ,
  https://www.elser.ai/blog/ai-character-turnaround-prompts-front-side-back-views
  The brief in [concept-sheets.md](concept-sheets.md) was tested here with
  Codex (codex-cli 0.167): unlabelled 2 x 2 panels worked first time; the side
  views came out drawn from ~7 degrees above.

## Rive

- `rive docs gpu`, `gpu-performance`, `animascript/protocols`,
  `animascript/api/gpu`, `assets`, `gotchas` (rive 1.9.2): GPU canvases,
  WGSL, blobs, AnimaScript vs Luau costs, WebGPU rules.
- The `mesh_skin_as` sample (`rive samples`): a GLB loaded in AnimaScript.
