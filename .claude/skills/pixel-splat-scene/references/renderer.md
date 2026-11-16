# The renderer: shaders, AnimaScript, blob, inputs

Everything here is in `assets/template/` and was built, rendered and audited
with `rive` 1.9.2 (`--verify`, `inspect`, `--screenshot`, `--bench`). Rive
draws 3D only through a script with a GPU canvas, and AnimaScript is the
language for it: per-frame maths and setup run many times faster than Luau
(`rive docs gpu-performance`).

## Passes

| Pass | Target | Pipeline | What it does |
|---|---|---|---|
| shadow | `depth32float`, `shadowSize`² | `vs_shadow` / `fs_shadow`, no colour target | the same splats from the sun (orthographic around the scene's bounds); skipped when `shadows` is false |
| G-buffer | `rgba8unorm` + `depth32float`, **2W x 2H** | `vs_main` / `fs_main`, depth `less`, write | instanced quads, one per splat (`draw(6, count)`, per-instance vertex buffer); alpha test; ramp step; writes (palette index, ramp, step, flags) / 255 |
| resolve | the `GPUCanvas`, **W x H** | `vs_full` / `fs_resolve`, full-screen triangle | 2 x 2 vote, ink, fog, sky; writes palette colours |
| blit | Rive's renderer | `drawImage(canvas.image, nearest)` under `Mat2D.withScaleAndTranslation(pixelSize, …)` | whole-pixel scale, centred, plus the camera-snap offset |

W x H is the art grid: `ceil(layout / pixelSize) + 2` per axis (one spare art
pixel per side: the camera snap slides the picture by up to a pixel and the
canvas edge must never show).

## The splat, in the vertex stage (`splat.wgsl`)

0. Skin: `p = Σ wₖ Bₖ p₀`, `n = normalize(Σ wₖ Bₖ n₀)` over the splat's up to 4
   bones (`B` is a uniform array of 64 3x4 matrices; bone 0 is the identity,
   the static world). A rigid part is one bone at weight 1; a skinned mesh
   blends its joints. Both entry points (camera and shadow) skin, so shadows
   move with the animation.
1. Sway (flag 4): `p += wind.xyz * sin(time * wind.w + dot(p, (2.1, 0.7, 1.7)))`.
2. Facing: a one-sided splat (no flag 2) whose normal looks more than ~75
   degrees away from the eye is culled (degenerate quad); a two-sided one
   turns its normal round. This is what keeps the back of a thin wall from
   poking through.
3. Covariance of a disc in view space: `Σ = st² I + (sn² − st²) n nᵀ`, with
   `st = sigma * splatScale`, `sn = st * flatness`.
4. Jacobian to G-buffer pixels. Orthographic: `J = k [1 0 0; 0 1 0]`, `k` px per
   world unit. Perspective: `J = [f/z 0 f·x/z²; 0 f/z f·y/z²]`, `z = −view.z`.
5. `Σ' = J Σ Jᵀ + 0.3 I` (the low-pass that keeps a splat at least a pixel,
   as in 3DGS); `conic = Σ'⁻¹`.
6. Quad half-extent per axis: `sqrt(Σ'ᵢᵢ) * sqrt(−2 ln threshold) + 0.5`,
   capped at 64 px: only the part the alpha test keeps is rasterised.
7. Light, constant over the splat: `direct = max(N·sun, 0)`, times 0 when the
   shadow map (read with `textureLoad` at the splat centre plus a normal
   offset, no sampler) says it is behind something. Unlit (flag 1) splats skip
   it.
8. `noise = hash(position)`: two numbers fixed to the splat in the world.

## The splat, in the fragment stage

```wgsl
let power = -0.5 * (conic.x*d.x*d.x + 2.0*conic.y*d.x*d.y + conic.z*d.y*d.y);
if (exp(power) < threshold) { discard; }           // crisp-edged blob, no blending
// light -> continuous ramp offset
o = dl < key ? -shadeSteps * (1 - dl/key)
             : lightSteps * max(dl - highlight, 0) / (1 - highlight);
o += (noise.y - 0.5) * jitter;
lo = floor(o); t = clamp((fract(o) - 0.5) / bandDither + 0.5, 0, 1);
step = base + lo + (threshold(splat or Bayer on the art grid) < t ? 1 : 0);
index = ramps[ramp][clamp(step, 0, len - 1)];
return vec4(index, ramp, step, flags) / 255;
```

The Bayer threshold is taken on the **art** grid (`frag.xy * 0.5`), so a
dither cell is one art pixel even though the pass is 2x.

## The resolve (`resolve.wgsl`)

For art pixel p, the four G-buffer samples `2p + (0|1, 0|1)`:

1. Fewer than `minCoverage` covered: sky, `sky_top` or `sky_bottom` chosen by
   Bayer across `horizon ± skyBlend / 2` of the height.
2. Vote: the palette index most covered samples hold; ties go to the nearest.
3. Ink: when any 4-neighbour art pixel is empty, or farther (linear depth)
   than `edgeDepth`, the winner's ramp step drops by `ink`. A partly covered
   pixel inside a surface is not an edge (that would ink every gap between
   splats).
4. Fog: `f = clamp((z − fogStart) / (fogEnd − fogStart)) * fogMax`; Bayer
   below `f` takes the palette's fog colour.
5. `debug` 1: the vote alone (no ink, no fog); 2: linear depth in grey.

## Uniform layouts (std140-like, bytes)

`Frame` (G-buffer and shadow, 1456 bytes; two buffers, one per pass):

| Offset | Field | Contents |
|---|---|---|
| 0 | `view` mat4 | world → view (`Mat4.lookAt` with the camera's own up, so straight down works) |
| 64 | `proj` mat4 | `Mat4.ortho` or `Mat4.perspective` (depth 0..1) |
| 128 | `lightViewProj` mat4 | world → shadow clip |
| 192 | `sun` | xyz to the sun, w key light |
| 208 | `grid` | target px w, h; px per unit (ortho) or focal px; 1 ortho / 0 perspective |
| 224 | `splat` | sigma scale, threshold, flatness, jitter |
| 240 | `shade` | shade steps, light steps, band dither, time |
| 256 | `shadow` | map size (0 off), depth bias (`shadowBias` spacings / 3R), normal offset (`shadowOffset` spacings), dither mode (1 per splat) |
| 272 | `wind` | xyz amplitude, w frequency |
| 288 | `tone` | x highlight |
| 304 | `ramps` array<vec4u, 64> | ramp r step s at `[r*2 + s/4][s%4]` |
| 1328 | `rampLen` array<vec4u, 8> | |

`Look` (resolve, 2256 bytes): `palette` array<vec4f, 64> at 0, `ramps` at
1024, `rampLen` at 2048, then `grid` (W, H, ink, edgeDepth), `depth` (near,
far, ortho, fogStart), `fog` (fogEnd, fogMax, fog index, minCoverage), `sky`
(top, bottom, horizon, blend), `debug`.

A uniform buffer smaller than the shader's block fails at bind-group creation
(`binds 2240 bytes but the shader's uniform block needs 2256`): when you add a
field, grow the struct by 16 bytes, the byte constant, and every offset after
it.

## The blob (`splat_bake.py` → `*.bin`)

```
0    'SPLT'  version u32 (2)  count u32  stride u32 (32)
16   bounds min f32x3, max f32x3 (over sampled frames of every track), spacing f32, palette count u32, ramp count u32
52   roles u8 x4: sky_top, sky_bottom, fog, void (255 unset)
56   bone count u32 (bone 0 = identity), track count u32
64   palette 64 x rgba8
320  ramps 32 x 8 u8 palette indices
576  ramp lengths 32 x u8
608  track table offset u32, bone data bytes u32
640  splats: position f32x3 | normal snorm8x4 | ramp u8, step u8, flags u8, 0 | sigma f32
           | joints u8x4 | weights unorm8x4 (summing to 255)
...  track table, 32 bytes a track: first bone, bone count, frames, fps f32, phase f32,
           data offset, speed f32, 0
...  each track's frames: frames x bones x 3 x vec4 f32 (row-major 3x4 matrices)
```

A splat's position is stored where its bones expect it: a static splat in
the world; a rigid part's splat in the world at frame 0 (its bone holds
`B(t) = Place · W(t) · (Place · W(0))⁻¹`); a skinned splat in the mesh's bind
space (its bones hold `Place · W_joint(t) · IBM_joint`, exactly linear blend
skinning). The baker samples every track at its own `fps`, so the runtime
does no animation maths at all.

## Animation playback

Each frame the script computes, per track, `k = floor((time · animSpeed ·
speed + phase) · fps) mod frames` and, only when `k` changed, copies that
frame's matrices straight from the blob into the bone buffer
(`GPUBuffer.update(firstBone · 48, blob, bones · 48, dataOffset + k · bones · 48)`).
Stepped playback is the pixel-art convention (8 to 12 fps reads hand-animated,
24 to 30 smooth); to play smoothly, bake at a higher fps rather than
interpolating. Budget: 63 animated bones per blob (16 KB uniform limit is far
away; the cap is the u8 joint index and the table size). A few tracks cost
about 0.1 ms of script a frame.

Flags: 1 unlit (emissive: ignores the sun and shadows, casts none), 2
two-sided, 4 sway, 8 casts no shadow. The vertex buffer is filled straight
from the blob (`GPUBuffer.update(0, blob, count * 32, 640)`): no per-splat
work in the script. 18 000 splats: 570 KB, ~0.26 ms of script per frame. A
blob of another version is refused with "re-bake it".

## Inputs

Every `@input` of `SplatScene` is set by a `ScriptInput*` of the same name in
RML, and every one can be overridden at launch with `--arg name=value`
(booleans `1`/`true`). RML applies its inputs after `init`, so the script
applies the `--arg`s again on its first frame: the command line wins.

| Input | Default | Meaning |
|---|---|---|
| `blobName` | `splats` | the blob to draw |
| `pixelSize` | 4 | screen points per art pixel (whole numbers) |
| `orthoHeight` | 0 | world units shown vertically; 0 frames the bounds |
| `perspective`, `fov` | false, 35 | a perspective camera instead |
| `lookAt`, `eyeX/Y/Z` | false, (0, 3, 10) | look-at camera: from the eye to the target (games.md) |
| `yaw`, `pitch`, `distance`, `spin` | 35, 30, 0, 0 | orbit camera (degrees, deg/s); distance 0 = from the bounds |
| `targetX/Y/Z`, `useTarget` | 0, false | the camera's target; orbit with `useTarget` false uses the bounds' centre |
| `sunYaw`, `sunPitch` | -40, 40 | the sun |
| `keyLight`, `highlight` | 0.45, 0.8 | below key: steps down; above highlight: steps up |
| `shadeSteps`, `lightSteps` | 1.5, 1 | how far down / up the ramp |
| `bandDither`, `splatDither` | 0.35, true | dither band width; per-splat (world-stable) or Bayer |
| `jitter` | 0 | random tone per splat, in steps (painterly; reaches the ramp's ends) |
| `shadows`, `shadowSize` | true, 1024 | |
| `shadowOffset`, `shadowBias` | 1.5, 0.5 | in splat spacings (read from the blob): the receiver pushed out along its normal, and the depth bias |
| `splatScale`, `threshold`, `flatness` | 1, 0.5, 0.3 | disc size, alpha test, thickness |
| `ink`, `edgeDepth` | 1, 0.4 | outline steps, depth step that counts |
| `fogStart`, `fogEnd`, `fogMax` | 0, 0, 0 | metres BEHIND THE CAMERA TARGET where fog starts and where it reaches `fogMax` (fogEnd 0 = 1.5 x the scene's radius); measured from the target so it does not move when the camera backs off |
| `animate`, `animSpeed` | true, 1 | play the baked tracks; a global rate |
| `orbit`, `orbitSpeed` | false, 0.35 | pointer orbit for previews: drag to orbit (left-right) and tilt (up-down), degrees per point; a released drag keeps turning and settles; the auto `spin` holds while a drag is held |
| `pitchMin`, `pitchMax` | 5, 85 | the tilt's limits (85: almost straight down) |
| `zoomMin`, `zoomMax` | 0.4, 2.5 | wheel / trackpad zoom: a factor on the view size (orthographic) or the distance (perspective) |
| `minCoverage` | 2 | samples of 4 an art pixel needs |
| `horizon`, `skyBlend` | 0.55, 0.12 | sky split as a fraction of the SCREEN height (from the top) and its dither band; 2 or more = all `sky_top`. With a perspective camera the true horizon sits at 0.5 − 0.5 · tan(pitch) / tan(fov / 2); a sea or plain reaching it needs geometry out to a large radius (a coarse ring) |
| `windAmp`, `windFreq` | 0.03, 1.5 | sway |
| `debug` | 0 | 1 vote only, 2 depth |
| `fx`, `fxPeriod`, `fxRampA`, `fxRampB` | true, 12, -1, -1 | the shader FX hook on splats flagged `fx`: the time in a `fxPeriod` loop and two ramp ids reach `fxApply` (an empty hook in the template) |
| `fxOffset`, `fxStopAt` | 0, 0 | the FX clock shifted by `fxOffset` s, and frozen from scene time `fxStopAt` on (0: never): start a cycle mid-way, desync copies, or end a capture on a chosen state |
| `demo`, `demoSpin` | false, 12 | demo mode, bound to the `Sample` view model: a game (`game.as`) plays itself and gets no pointer; a diorama turns at `demoSpin` degrees a second (counter-clockwise seen from above, like `spin`). A host such as a gallery sets it per sample |
| `tour`, `tourLoops` | 0, 2 | a turntable for captures (orbit camera): `tourLoops` turns in `tour` seconds, eased in and out (`0.5 − 0.5 cos πt`); spin and pointer are ignored meanwhile |
| `tourRate`, `tourOffset`, `tourLength`, `tourEase` | 0, 0, 0, 1.5 | a turntable shared by several captures (a reel whose scenes cross-fade while turning in step): `tourRate` degrees a second on one timeline `tourLength` s long, eased in over the first `tourEase` s and out over the last; this capture starts at `tourOffset` on it. Overrides `tour` when non-zero |
| `maskSky` | false | a pure magenta sky (in no palette), for silhouette masks: `golden.py views` sets it |

## Shader FX

Splats baked with the flag `fx` (`"flags": ["fx"]` on a material) run through `fxApply` in
both vertex entry points (camera and shadow). The hook may move a splat, hide it (a culled
quad: flicker, dissolve, reveal) and recolour it by switching its ramp and step (a glow colour
is drawn unlit). It receives the time in a `fxPeriod` loop, two ramp ids the scene passes
(`fxRampA`, `fxRampB`), the FX splats' x and y bounds at rest (the script measures them at
load, for left-to-right or bottom-to-top effects) and two random numbers fixed to the splat.
Because the result is still a palette index, the 2x2 vote, the ink and the palette apply to
the effect like to anything else: the effect is pixel art too.

The template's `fxApply` does nothing; a project writes its own in its copy of `splat.wgsl`
(the comment above it has a small example). Effects that work: a stepped reveal or dissolve,
a flicker (hide by `h.x` against a stepped level), a colour sweep (a band of ramp ids
crossing `u`), a glitch (slices offset by a hash of the slice and a stepped time), a hit flash
(every splat of an object to a light ramp for two frames), a ripple (z offset by a sine).
Keep them stepped (`floor(t * 12) / 12`) and palette-exact. For effects tied to game events,
drive `fx` time from the game (a bound input) instead of the free-running loop.

## Pointer orbit (previews)

`SplatScene` overrides `pointerDown/Move/Up/Exit` and `pointerScroll`: a drag
adds to `yaw` and `pitch` (clamped to `pitchMin..pitchMax`), the wheel scales
the view, and `event.hit()` claims the gesture. Pointer input reaches a
script only in an artboard with a state machine (the template's `scene.rml`
has one; the lookdev bench, without RML, is driven by `--arg` instead). With
no pointer input the picture is pixel-identical, so goldens are unaffected.
Test a gesture headless:

```sh
rive scene --screenshot=$PWD/drag.png --pointer="drag@200,200>440,200:20" --advance=2
rive scene --screenshot=$PWD/zoom.png --pointer="wheel@320,200:0,-300:6" --advance=2
```

Turn it on with `<ScriptInputBoolean propertyValue="true" name="orbit"/>`. A
game leaves it off and drives the camera itself (games.md). Orbiting
re-rasterises every splat from a new angle: art pixels crawl while the view
turns and settle when it stops. Panning snaps to the grid; turning cannot.

## Wiring it into a scene

`scene.rml`: an artboard with a state machine (without one, binds and pointer
input are dead in the CLI), a fill-sized `LayoutComponent`, a
`ScriptedLayout` pointing at `<ScriptAsset file="splat_scene.as">`, the
`ScriptInput*` children, and **a `<BlobAsset file="splats.bin" name="splats">`
for each blob**: in an RML project an undeclared `.bin` is not found
(`splat_scene: no blob named splats`). A project with no RML (`main:
splat_scene` in rive.yaml, the lookdev bench) turns every `.bin` into a blob
by itself. Shaders and scripts never need declaring.

To drive the scene from a view model (a time of day, a camera rail), bind the
`ScriptInputNumber`s like any property (`rive docs data`) or key them in a
timeline.

## Traps this renderer hit (Rive 1.9.2)

| Symptom | Cause | Fix in the template |
|---|---|---|
| `no overload of '>>' for (i32, i32)` | WGSL shifts take a `u32` amount | `k >> 1u` |
| `Built-in Position is present more than once` | a fragment took both the VOut's `@builtin(position)` and its own | read `i.clip.xy` in the fragment |
| `binds N bytes but the shader's uniform block needs M` | UBO smaller than the struct | sizes as constants next to the layout table |
| `no blob named …` in an RML project | blobs must be declared | `<BlobAsset>` |
| a line of background at one edge | the snap offset slid the canvas | +2 art pixels |
| top view black / NaN | `lookAt` with up parallel to the view | the camera's own up vector |
| storage buffers, compute | scripts cannot bind them | no GPU sort: alpha-tested splats + depth instead of sorted blending |
| integer varyings | need `flat`; avoided | ramp/step/flags travel as `f32` and are rounded |
| depth read in the resolve | WebGPU forbids reading a texture in the pass that writes it, and a depth texture through a filtering sampler | separate passes, `textureLoad`, a `depthOnly` view |
| shadow acne on small assets | offsets in scene units (R x 0.01) were smaller than a disc | offsets in splat spacings, read from the blob header |
| `resize` scale ignored | the art canvas is deliberately small: the blit's nearest sampler does the scaling | the HUD and text drawn beside it keep full resolution |

On the web, `@rive-app/webgl2` draws GPU canvases only with
`enableGPUCanvas: true` and no offscreen renderer, and a file with scripts
must be built with `--publish` (signed). Check a published build in a browser
before calling it done (`rive docs publish-web`).

## Extending it

- **More than one blob**: a static world blob plus per-object blobs with their
  own model matrix (add a `model` mat4 per draw, a dynamic-offset UBO), for
  scenes past 63 bones or for objects the game moves itself.
- **Game-driven motion** (a character steered by input): write that
  object's bone from the script (`bones.update` with your own matrix) instead
  of a baked track; its animation clips stay baked.
- **Soft splats** (smoke, glow, water spray): a second pipeline drawn after
  the opaque one, additive or premultiplied blend, depth test without write,
  into a separate target the resolve adds with a dithered threshold. Sort
  only these, on the CPU, if they overlap a lot.
- **Normal-edge highlights** (t3ssel8r style): write an octahedral normal into
  a second colour target and step convex creases one up in the resolve.
- **Stable dither for Bayer mode under camera motion**: anchor the Bayer
  index to the snapped camera (art-grid offset), or use per-splat dither.
- **A HUD**: draw it with Rive shapes and text beside the `ScriptedLayout`;
  keep its sizes on whole multiples of `pixelSize` and its colours on the
  palette.
