# Step 1: the asset list

Before anything is generated or modelled, write `art/assets.md`: every 3D
asset the scene or game needs, as numbers. The list decides how many concept
sheets to generate, which ramps the palette must have, how big every part
must be to survive as splats, and how many bones the motion costs.

## First, the art grid and the texel

Everything is sized from the **texel**, the world size of one art pixel at
the distance the asset is usually seen:

```
art rows      H = ceil(layout height / pixelSize) + 2   (the renderer keeps a spare art pixel on each side:
                                                         136 rows at 400 px and pixelSize 3)
texel         t = orthoHeight / H                       (orthographic)
              t = 2 · d · tan(fov / 2) / H              (perspective, at distance d)
splat spacing s = 1.2 to 2 t
```

For a game whose camera moves closer and farther, size from the distance the
player spends most time at, and check the near and far extremes.

| Measure | Rule |
|---|---|
| Splat spacing | 1.2 to 2 t: below 1 the splats disappear into a plain low-res render, above 3 silhouettes turn ragged |
| Thinnest part | at least 1.5 s across, or a smaller per-material `spacing` giving 2 splats across it (below the texel is fine for a small face or a detail) |
| Narrowest hole or gap | at least 3 s (it closes by two splat radii), or compensate (below) |
| Smallest painted shape | 2 s |
| A character or hero object on screen | 16 to 60 art pixels tall: smaller reads as a token, larger loses the pixel feel |
| Ink depth step (`edgeDepth`) | about the depth of a hero object |

Read the bake's warnings: `parts with under 12 splats read as specks` names
the mesh (one entry per primitive of that material) to thicken, or mark the
material `"specks": true` when the parts are tiny on purpose: particles, eyes,
rivets meant to read as single art pixels.

## The list

One row per distinct model; instances (a forest of one tree model, ten
crates) are one model placed several times with a yaw, a scale and a phase.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Triangles | Motion | Notes |
|---|---|---|---|---|---|---|---|---|
| `<name>` | hero / character / prop / foliage / terrain / effect | w x d x h | n | the ramps its materials use | sheet, or "from this list" | budget | none / rigid / skinned / game-driven, loop, fps | thin parts, holes, textures |

Classes and their budgets:

| Class | Triangles | Concept | Notes |
|---|---|---|---|
| hero object / character | 200 to 800 | a turnaround sheet, gated | the eye goes here: model the silhouette to the sheet |
| prop | 20 to 300 | a sheet if it has a recognisable shape, else from the list | |
| foliage | 50 to 300 | from the list, or one sheet per species | `sway`, two-sided cards only where a volume would not do |
| terrain / architecture / level pieces | 50 to 500 a piece | from the list or a layout sketch | big faces carry a texture whose texel is about 2 splats; modular pieces snap on a grid |
| effects (glow, fire, water, particles) | few | none | `unlit` ramps, `sway`, rigid looping fields, the fx hook |

**Motion**: kind (rigid parts, skinned, or moved by the game), what moves,
loop length, bake fps. Count the bones: one per animated object or joint, per
instance, 63 per blob (split into several blobs past that, games.md).

## What to model, what to paint, what to drop

- **Model** every part that changes the silhouette at the texel, and
  exaggerate thin ones (a pixel-art habit: handles, ropes, rails, weapons,
  ears get thicker and bigger).
- **Paint** (texture, palette-exact) what is flat on a surface: tiles, planks,
  patches, markings, a path, a window. A coplanar mesh overlay (a decal disc
  on a floor, a sign flush on a wall) fights the surface under it at splat
  size: each splat has one depth.
- **Holes and gaps close up** (measured on flat faces: up to about 1.7 spacings
  per side at the default `fat`): a disc reaches about one radius past the face
  it sits on, so negative space (a letter cut through a plate, a window, the
  gap between planks) shrinks by two radii. Cut it wider than drawn, or stop
  the faces short of it by about a radius (leaving the walls on the true
  outline), bake that part at a finer spacing, and gate the result against
  its reference.
- **Positive shapes come out fatter** by the same spread: thin letters,
  rails, a logo's strokes. Shrink the solid itself (walls and all) by about
  one radius before baking; eroding only its faces leaves the walls drawing
  the old outline and hollows the shape.
- **Points and tips erode**: a thin pointed shape (eaves, spikes, a sail's
  corner, ears) loses its tip to the splat spread and the silhouette comes out
  shorter. Extend and thicken tips by about a splat spacing.
- **Details proud of a surface by less than a spacing** (a door frame 3 cm off
  a wall, trim, a plaque) fight the surface's splats and smear into noise at
  an angle. Either stand them off by at least one spacing or paint them into
  the surface's texture (`uv project-from-view <view> --scale-to-bounds` on that
  face, one material per face).
- **Near a perspective camera, small things become huge**: a 0.15 m object
  2 m from the lens fills a tenth of the frame. Put backdrops (stars, distant
  hills, skyboxes made of splats) well beyond the camera's distance, and keep
  geometry out of the first half metre in first person.
- **Drop** what is smaller than two splats: rivets, bolts, a chain's links,
  grass blades. Their place is a texture shape or nothing.
- **Flat shading** for faceted low-poly. Smooth shading only where a curved
  read is wanted, and still few sides (6 to 8).
- **Hidden faces still bake**: caps buried in the ground, the inside of
  joined walls, the underside of terrain the camera never sees. Delete them.
- **Up Z, facing −Y in hedra** (its front view looks along +Y), origin at the
  ground under the centre (or at the pivot for something that turns): the
  GLB comes out Y-up facing +Z, the renderer's `yaw 0` front.

## The composition file

The list becomes a bake file (`assets/template/scene.bake.json` to copy): one
entry per instance with its model, position (Y up, metres), yaw (degrees),
scale, animation options, and its materials mapped to ramps and flags (see
`splat_bake.py --help`). The bake reports splats per material and warns on
starved parts. Keep a blob under ~100 000 splats for phones (32 bytes each).
A game usually bakes several: static level geometry, props, each character.
