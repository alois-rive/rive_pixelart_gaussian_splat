# Steps 4, 5 and 7: from sheet to model to goldens

The model is built with `hedra model` (Blender's vocabulary, scripted) in
phases. Each phase is a command file replayed from scratch, and each ends in
a gate: render the views, compare them with the sheet's views, read the
numbers and the compare sheet, change one thing. hedra's own skills
(`hedra skill install`: `hedra-model-workflow`, `-technique`, `-reference`,
`-repair`) hold the general modelling craft; this page is what the splat look
changes and adds.

## Layout of an asset

```
art/<asset>/sheet.v1.prompt.md, sheet.v1.png(.json)   the approved concept
art/<asset>/refs/<view>.png, <view>.mask.png, views.json
models/<asset>/<asset>.spec.md         the sheet as numbers, assumptions, gate record
models/<asset>/p1_blockout.txt         phase 1 commands (starts with `new`)
models/<asset>/p2_form.txt             phase 2 commands (form, materials, UVs, textures)
models/<asset>/textures/*.png          palette-exact, fitted, audited
models/<asset>/<asset>.glb             the export
models/<asset>/<asset>.bake.json       material -> ramp map, spacing, out: lookdev/<asset>.bin
models/<asset>/shots/p1, p2, p4_albedo, final
goldens/<asset>/<view>.png             approved renders through the splat renderer
```

Rebuild from nothing at every iteration (`rm -f x.rmdl && hedra model --text
x.rmdl run p1_blockout.txt && ... run p2_form.txt && hedra model x.rmdl export
x.glb`; write `rm -f x.rmdl`, not `x.rmdl*`: in zsh an unmatched glob is an
error that stops the chain): the command files are the model, and a fix is an
edit to them, never a patch on a saved state.

The same zsh trap hits any glob with no match (`rm -f shots/*.png` on an empty
folder stops a `&&` chain): use `rm -rf shots/x` on a folder, or
`setopt null_glob` in the script. And zsh does not split variables: a `$ARGS`
holding several `--arg` flags arrives as one argument; write `${=ARGS}` or use
an array.

`rive --advance=N` counts frames at 60 fps (`--advance=30` is half a second);
seconds and milliseconds need a unit (`1.5s`, `250ms`). A bare `0.5` is an
error.

`hedra model x.rmdl inspect check` flags cylinder caps and filled faces as
ngons (`ok="false"`): harmless here, the export and the bake triangulate. Every
other finding (non-manifold, flipped normals, loose verts) gets fixed.

## Assets without a sheet

Simple pieces (rocks, trees, crates, terrain, modular level parts) can skip the concept sheet:
their row in `art/assets.md` is the brief. Their spec is that row expanded
into parts (size, position, material and ramp step) plus the budgets, and
their gates are:

1. `golden.py views --hedra x.rmdl -o shots/p1 --views front,right,top,iso`
   and a look at the four views against the spec's sizes (`hedra model x.rmdl
   inspect stats` for the bounds);
2. the bake's report: colour error 0.000, no specks warning;
3. lookdev renders at the scene's texel (`--texel`), a person's yes, and
   goldens snapped from them.

When the piece matters to the game's identity, generate a sheet anyway.

## The spec (step 4)

Measure the sheet, not the brief. Pick one part whose size you know (a
1.2 m wide base that is 337 px across in the front panel gives 281 px per
metre) and read every other part off the same panel. Write the spec as a table: part,
size, position, material (ramp and base step); then the proportions the views
agree on, the palette and textures, the **Assumptions** (what the sheet does
not show or gets wrong) and the budgets. `views.json` from `sheet_cut.py`
gives each view's aspect for the record.

## Phase 1: blockout

One primitive per named part, at the spec's sizes, scale applied, including
the copies that shape the silhouette (all six horses of a carousel, all four
legs): a blockout with one placeholder copy fails the gate for a reason that
is not a modelling error. Gate it before any edit-mode work:

```sh
python3 $K/scripts/golden.py views --hedra models/<a>/<a>.rmdl -o models/<a>/shots/p1 --views front,right,back,top [--elevation E]
python3 $K/scripts/golden.py gate --refs art/<a>/refs --shots models/<a>/shots/p1 -o models/<a>/shots/p1/compare.png --min-iou 0.75
```

`views --hedra` renders flat material views over black (hedra's default grey
material is too close to the sheet's grey for a mask) with `--dry-run`, so
the model is never touched. `gate` prints per view:

- `iou`: the silhouettes after both are cropped to their box and squared:
  the **form**. Fix with geometry.
- `aspect` and `drift`: height / width before normalising: the
  **proportion**. Fix with scale.
- `worst at 0.31 of the height: ref 0.20, model 0.95`: the row where the
  outlines disagree most, as a fraction of the height from the top, with each
  outline's width there: the repair instruction.

and writes the compare sheet: concept | model | overlay, magenta where the
concept has something the model lacks, green where the model has extra.
Read it before changing anything.

## Phase 2: form and surfacing

Edit-mode work (inset, extrude, bevel only where the silhouette needs it),
then materials in the palette's colours (sRGB 0..1 of the ramp step, so the
bake snaps exactly), textures, UVs, flat shading, export. Gate again with the
hedra views.

## Phase 3: through the splat renderer (step 7)

```sh
python3 $K/scripts/splat_bake.py models/<a>/<a>.bake.json          # -> lookdev/<a>.bin
python3 $K/scripts/golden.py views --rive lookdev --blob <a> -o models/<a>/shots/p4_albedo --look albedo --views front,right,back,top
python3 $K/scripts/golden.py gate --refs art/<a>/refs --shots models/<a>/shots/p4_albedo -p art/palette.json --min-iou 0.7 -o models/<a>/shots/p4_albedo/compare.png
```

`--look albedo` sets `shadeSteps 0, lightSteps 0, ink 0`: every splat on its
painted step, so the **colour drift** (half the L1 distance between the
concept's and the render's pixel shares per ramp) measures material
assignment, not the light. A lit render moves sunlit faces up their ramps and
fails for the wrong reason.

The splat silhouette is a little fatter than the mesh (each disc reaches about
one radius past the edge), so its IoU tier is lower than the mesh's.

## Animation in hedra

Two kinds reach the renderer, chosen by how the model is built:

| Kind | Build | Bones | Use for |
|---|---|---|---|
| **Rigid parts** | key an object's location / rotation / scale (`set rotation ...`, `keyframe insert --channels rot --frame N`); children follow their parent | one per animated mesh object (join what moves together: `join`, origin at the pivot with `cursor set` + `origin set --to cursor`) | wheels, doors, platforms, vehicles, pickups, wings, segmented PS1-style characters, effects (a falling or rising particle field) |
| **Skinned** | an armature (`add armature`, `bone add ... --parent --connected`), `parent set Rig --type armature --auto-weights`, keys on pose bones (`mode pose`, `pose set <bone> rotation ...`, `keyframe insert --channels rot`) | one per joint (4 a splat) | characters, creatures, bending plants, cloth, tails |

Rules:

- **Export with `export x.glb --bake-animations`.** Without it hedra writes
  eased CUBICSPLINE curves, and a 0 → 360 degree turn is two identical
  quaternions: it does not turn at all.
- **Key from frame 0.** hedra writes frame f at f / fps seconds: keys from
  frame 1 make a 4.083 s clip of a 4 s loop and a stutter at the seam (or set
  `"loop"` in the bake file).
- **Loops**: the last key equals the first, and a constant-speed loop gets
  `keyframe interpolation linear --all` (hedra's default keys ease in and
  out: a turning wheel would stutter at the wrap).
- **Seamless effects**: a falling field (snow, rain, leaves, sparks, bubbles)
  is two identical fields stacked one loop height apart, moving one height per
  loop; keep it where its wrap is hidden (inside the ground, out of frame).
  That needs ground at least one loop height thick. Onto THIN ground (a
  floating island's slab) the copies fall through into the void: use a
  **banded column** instead. Cut one tall column into K thin bands, each its
  own object (one bone); all fall at one speed; a band jumps back to the
  column's top (above the frame) once it is wholly inside the slab. Band
  height under the slab's thickness minus the particle size, bands exactly one
  band apart, jumps on the bake's sample times (k / fps). Keep the field's
  footprint inside the ground's rim. It costs K bones of the 63.
- **Fields whose wrap cannot hide in one band** (embers rising from a pool
  on a floating island, where the two-copy wrap would show below it): stack
  N short copies of a thin field, each turned by the golden angle (137.5
  degrees) about the vertical, so no copy's reset lines up with another's.
- **Turning against the camera**: the orbit, `spin`, `demoSpin` and `tourRate`
  turn the camera counter-clockwise seen from above (increasing yaw), the same
  way a positive yaw keyframe turns an object. A lamp, a carousel or a radar
  turning that way looks almost still in a turntable capture: key it the
  other way (0 to −360).
- **Game clips**: a character's idle, walk, run, jump are separate glTF
  animations; bake each as its own object entry (`"animations": ["Walk"]`) or
  pick frames from game state (games.md, "Moving objects the game owns").
- **Several animations on one model** (a walk and an orbit, a flap and a
  circle) each loop on their own length in the bake; set the object's
  `"loop"` to a common multiple of them. `"animate": false` bakes the rest
  pose (`--arg animate=0` only freezes playback at frame 0).
- **Do not rely on cyclic F-curve extrapolation**: `--bake-animations` does
  not sample it. Key the whole loop, or let the baker repeat a short action.
- **Vertex groups and `join`**: `join` merges vertex groups by index, not by
  name. When rigging separate parts, give every part the same group list
  first (`parent set Rig --type armature --empty-groups` on all of them), fill
  each (`vgroup add` before `vgroup assign`), then join.
- **Hierarchies**: `parent set <Parent>` makes the other selected objects its
  children (`select Child1 Child2 Parent`, `active Parent`, `parent set
  Parent`). An empty (`add empty --name Pivot`) is a fine animated parent: key
  the empty, and every child mesh becomes a rigid part that follows it.
- **Frame 0 is the pose that is sampled.** The baker samples splats on the
  frame-0 pose and moves them with their bones: a part at scale 0 on frame 0
  gets no splats (and a singular bone); a part small there stays thin when
  it grows, because a disc's size does not follow its bone's scale. Key frame
  0 at full size (a puff that grows and fades: start it full, shrink and hide
  it through the loop, or hide it with the fx hook).
- **Rotations are extrinsic XYZ** (`--rotation x y z` and `set rotation` mean
  R = Rz · Ry · Rx): to spin a part about its own axis and then lay it down,
  do it in two steps: `set rotation 0 0 <spin>`, `apply --rotation`, then
  `set rotation <tilt> 0 0`.
- **Interpolation applies to existing keys**: `keyframe interpolation linear
  --all` changes the keys already inserted; run it after the last
  `keyframe insert`.
- **Pivot first**: put the origin where the part turns (`cursor set` the
  hinge, `origin set --to cursor`) before keying rotation.
- **Bake fps** in the bake file (`"fps": 12`); 8 to 12 for the pixel-art
  feel. Several instances of one animated model: give each a `phase`.
- **Gate the rest pose** (frame 0) against the sheet as for any model; then
  look at a strip of frames (`rive lookdev --screenshot --advance=N` at a few
  N, side by side). The goldens include a later frame for anything that moves.

## Goldens

When the person approves the lit look:

```sh
python3 $K/scripts/golden.py views --rive lookdev --blob <a> -o models/<a>/shots/final
python3 $K/scripts/golden.py snap --shots models/<a>/shots/final --goldens goldens/<a>
# after any change to a shader, the baker, the palette or the model:
python3 $K/scripts/golden.py views --rive lookdev --blob <a> -o models/<a>/shots/recheck
python3 $K/scripts/golden.py check --shots models/<a>/shots/recheck --goldens goldens/<a>
```

Gate renders use a magenta mask sky (in no palette) so silhouettes cut
cleanly; goldens meant to be looked at or audited with `palette.py frame`
take `--real-sky`, and animated ones a later `--advance` too. For a
perspective scene, `--texel` is the texel at the distance the asset is
usually seen (assets.md).

`views` writes `render.json` (size, pixel, look, texel, elevation, args) next
to the renders and `snap` keeps it with the goldens; `check` refuses renders
made with other settings and prints the exact `views` command to make them.

The renderer is deterministic (fixed seeds, fixed `--advance`): an unchanged
input re-renders to 0.0000 % different pixels, so `check` with its default
0.2 % catches any real change. An intended change is re-approved and
re-snapped, never waved through.

Keep two sets per asset. Framed (the default, `--texel 0`) fills the view:
splats are 3 to 5 art pixels, good for judging form and materials, but
blobbier than the scene. At the scene's density (`--texel <orthoHeight /
art rows>` of the scene, `--size` large enough to hold the model) the asset
looks exactly as it will in the scene: that is the look the person approves
(`goldens/<asset>/` and `goldens/<asset>@scene/`).

Scene goldens are frames: `rive scene --screenshot=$PWD/shots_scene/frame_002.png --advance=2`
(and a later frame for anything that moves; for a game, frames from scripted
input with `--key`, `--pointer` or `--gamepad`), then `golden.py snap / check`
on that folder.

## Threshold tiers

Choose the tier when the spec is written, not after a failure.

| Gate | Generated sheet (Codex) | Clean orthographic drawing |
|---|---|---|
| Form IoU, hedra views | ≥ 0.75 | ≥ 0.85 |
| Aspect drift | ≤ 0.08 | ≤ 0.05 |
| Splat IoU, albedo | ≥ 0.70 | ≥ 0.80 |
| Splat aspect drift | ≤ 0.08 (bake the bench at the scene's spacing; a finer bench hides fattening) | ≤ 0.05 |
| Colour drift, albedo | ≤ 0.25 | ≤ 0.15 |
| Golden check | ≤ 0.2 % pixels | ≤ 0.2 % |

With 6 colours or fewer, or a monochrome palette, the colour drift says
little (every material shares the same few colours): rely on the IoU and the
eye. A view that cannot pass because the sheet contradicts itself gets a waiver in
the spec's gate record, with the reason and the views that lead.

## hedra habits that matter here

- **Edit mode acts on the active object only**, whatever else is selected:
  `active X`, `mode edit`, work, `mode object`, for each object.
- **Scale, apply, then rotate.** `add mesh cube --rotation …` followed by
  `scale` gave slabs at the wrong angle; `scale … / apply --scale / set rotation …`
  is unambiguous.
- `select face where "…"` reads **object-local** positions: a ring at
  z 0.21 has its top at `pos.z` 0.21, not 0.42; `bisect --plane-co` too. Apply
  location (`apply --location`) first when you want world positions.
- Faces nobody sees still bake splats (cylinder caps buried in the ground, the
  inside of a joined wall, terrain undersides the camera never sees): delete
  them in edit mode.
- `material assign` adds a slot when the object has none for that material:
  `material slot add` beforehand is not needed (it only adds empty slots and
  warnings).
- `randomize --amount 0.06 --seed 7`, not a positional amount.
- `ico-sphere --subdivisions 1` is the bare 20-face icosahedron (a good low-poly rock or puff).
- `keyframe interpolation <mode> --all` acts on the selected object's action only, so stepped
  (constant) and linear keys can live in one model, per object.
- `delete vert` (there is no `delete only-verts`).
- `subdivide` on an n-gon cap adds nothing: `poke` it first. `select face where
  pos...` tests face centroids (subdivide a cone's sides to select a snowy tip).
- `select ... where` reads object-LOCAL positions AND normals: a cylinder added
  with `--rotation` still has its caps at `normal.z`.
- Rotations are extrinsic XYZ: a wheel standing on edge facing the camera is
  `--rotation 90 22.5 0` to spin it about its own axle; `90 0 22.5` skews it.
- `select where` combines tests with `&&` and `||` (not `and` / `or`), and has no trigonometry.
- `select random` picks nothing until the select mode matches (`select mode face`).
- `scale` after an `add --rotation` acts in WORLD axes (apply the rotation first).
- `join` merges the selection INTO the active object (its name, origin and
  transform survive): make the keeper active first. It keeps every part's
  material slots: one material on two joined parts exports as two primitives
  (the bake then warns about specks per primitive); join first, then paint by
  geometry (`select linked`). After a join, `select ... where pos.*` reads
  positions from the active part's origin: `apply --location` before any
  position-based selection.
- `active X` ADDS X to the selection: a later `set rotation` or `material assign`
  hits every selected object. `select X` first (it replaces the selection), then
  `active X`.
- A hero scaled in the bake (`"scale": 1.25`) needs its lookdev `--texel` and
  spacing divided by that scale to match the scene: a material's `"spacing"` is
  in world units AFTER the object's scale.
- **The colour gate on neighbouring hues**: when two ramps share hues (a
  yellow and an ochre wood), the sheet's soft shading lands on the wrong ramp
  and colour drift reads 0.3 to 0.5 on a correct model (a colour held by
  several ramps counts towards each). Gate against a copy of the palette that
  keeps only the hero's own ramps (`art/<hero>/gate_palette.json`, same
  colours); if the materials are right and it still drifts, record a waiver
  rather than repaint.
- Turning joined parts about a shared axis: `apply --location` first, or `set
  rotation` turns each part about its own origin.
- **The gate's real angles**: the renderer clamps pitch to `pitchMin` /
  `pitchMax` (5 and 85 by default), so `golden.py views --rive` draws the side
  views from 5 degrees above and the top from 85. Gates so far are taken that
  way (and Codex side panels are often a few degrees high anyway); a long flat
  model can fail aspect drift on it alone: compare against the hedra mesh at
  the same `--elevation 5`, or render with `--arg pitchMin=0 --arg pitchMax=90`
  for exact views (and say so in the spec).
- **When the mesh gate and the splat gate disagree** (a flat storey, a small
  frog: splats grow a radius past flat tops and bottoms while thin tips
  shrink, so no one mesh passes both aspect drifts): keep the gated form
  phase (`p2_form.txt`, the mesh gate's) and add a `p3_splat_fit.txt` that only
  shrinks, thickens and extends for the splats; the splat gate is taken on p3
  and the bake uses p3. Record both in the spec. Keep the gated model intact
  by writing the fit to its own file: `hedra model --no-save --to <a>_fit.rmdl
  <a>.rmdl run p3_splat_fit.txt`, then export the fit.
- **A dark hero against a lit gate sky**: `golden.py views --real-sky` paints
  the sky from the palette's roles; when the hero's shade steps match it, bench
  with a copy of the palette whose `sky_top`/`sky_bottom` roles point at a
  contrasting colour (`art/palette_bench.json`), used only for the bench.
- `ico-sphere --subdivisions` must be at least 1; `randomize` works in edit mode.
- A `--rotation` given at `add` stays an object transform: a later scale or join
  skews it. `apply --rotation` (and `--location`) before joining or scaling.
- `select ... where` has no trigonometry (no `atan2`, `sin`): selections by
  angle (radial ribs, teeth, every other segment) are generated by a script
  that writes the command file.
- The side walls an `extrude` creates keep the material of the face they grew
  from, not the one assigned to the moved face: assign the walls afterwards.
- `hedra model render --view front` ignores `--azimuth` / `--elevation`: for
  an elevated or turned view, drop `--view` and pass `--azimuth A --elevation E
  --ortho` (golden.py does).
- `material texture <mat> base-color <path>` with the material's base colour
  at 1 1 1: glTF multiplies the factor into the texture.
- `uv project-from-view top --scale-to-bounds` on the selected faces maps one
  texture over a top face: set the texel by the texture's size (32 texels over
  6 m = 0.19 m, about two splats at 0.09 m).
- `golden.py views --hedra` uses `--dry-run`: renders never touch the model
  or its undo ring.
- Exports are Y-up facing +Z: the renderer's `yaw 0` is the sheet's front,
  `90` its right, `180` its back, `pitch 90` its top.
