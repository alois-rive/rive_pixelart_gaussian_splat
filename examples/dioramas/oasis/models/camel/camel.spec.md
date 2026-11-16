# Asset: camel (hero character, skinned, walking)
Concept: ../../art/camel/sheet.v1.png, refs cut to ../../art/camel/refs/ (`--flip right --rotate top=-90`).
Scale: the right panel is 499 px for the 2.0 m height at the head -> 250 px per metre; the front
panel (498 px) agrees. Up Z, facing -Y (hedra's front view looks along +Y). Origin on the ground
under the torso's centre.

## Parts (metres, read off the right and front panels)
| Part | Size | Position (centre) | Material (ramp, base) | Bone |
|---|---|---|---|---|
| Torso | 0.68 x 1.14 x 0.52, chest and rump edges chamfered 0.08 | 0, -0.01, 0.98 (z 0.72..1.24) | Fur (fur, #c0977a) | Body |
| Hump | 8 x 6 uv-sphere, radii 0.36 / 0.52 / 0.48 | 0, -0.06, 1.18 (top 1.66) | top rings BlanketTop (stone, #a9a994), the band just above the blanket Stripe (cloth, #f0d696) | Body |
| Blanket | 0.85 x 0.80 x 0.32, top 20 % narrower, corners chamfered 0.12 | 0, 0.03, 1.10 | BlanketSide (stone, #87867a), top face BlanketTop | Body |
| Neck | 0.26 x 0.32 x 0.80, tilted 25 deg forward | 0, -0.80, 1.30 | Fur | Neck |
| Head | 0.36 x 0.42 x 0.30 | 0, -1.00, 1.76 | Fur | Head |
| Snout | 0.26 x 0.28 x 0.20 | 0, -1.32, 1.70 | Muzzle (fur, #886243) | Head |
| Ears x2 | 0.16 x 0.14 x 0.16 (exaggerated from ~0.10) | +-0.20, -0.86, 1.94 | Fur | Head |
| Upper legs x4 | 0.21 x 0.21 x 0.38 | x +-0.21, y -0.35 (front) / +0.46 (back), z 0.40..0.78 | Fur | Thigh** |
| Lower legs x4 | 0.17 x 0.17 x 0.36 | same x/y, z 0.07..0.43 | Fur | Shin** |
| Hooves x4 | 0.22 x 0.26 x 0.08 | 0.03 forward of the leg | Hoof (fur, #886243) | Shin** |
| Tail + tuft | 0.12 x 0.12 x 0.36 tilted 35 deg back, tuft 0.13 cube | 0, 0.67, 0.90 / 0, 0.77, 0.73 | Fur / Hoof | Tail |

## Proportions the views agree on
- Right panel: head-to-tail 2.27 m, height 2.0 m (aspect 0.877); legs 0.72 m to the belly.
- Front panel: blanket 0.85 m wide at its hem (z 1.0), body 0.70, legs 0.20 wide with a 0.22 gap.

## Palette
Materials were chosen by fitting the sheet to the palette (`palette.py fit refs/right.png`):
fur #c0977a, dark muzzle #886243, blanket slate, cream stripe. Two of the fit's colours were
lifted one step: hooves #944431 and blanket #445162 are step 1 of ramps that start at black, so
in shade or under ink they turned into black blots (seen in the first lit lookdev).

## Assumptions (the sheet does not show)
- Eyes are dropped (0.05 m, under one splat).
- The sheet's top panel draws the tail straight back; the side panels droop it: the model follows
  the side panels, tilted 35 deg.

## Rig and animation
12 deform bones: Body (root, along the spine), Neck, Head, Tail, Thigh/Shin x4. Every part is
weighted 1.0 to one bone (rigid, segmented toy). Weights by hand, not `--auto-weights`: the legs
are separate boxes 0.22 m apart and each part belongs to exactly one bone.
Walk: a camel PACES (both legs of one side move together); 24 frames at 20 fps = 1.2 s:
thighs +-22 deg, the swinging shin bent 40 deg at the passing frames, body roll +-3, neck and head
nod +-4. Linear keys, cyclic. p4_orbit.txt bakes it over 288 frames and turns an `Orbit` empty
0 -> -360 deg about the pond (radius 2.3 m, 14.4 s = 12 strides: ~1 m/s, matching the stride).
Bake: 10 fps, stepped.

## Budgets
<= 800 triangles (364), one skinned mesh, 12 bones, 6 materials, no texture.

## Gate record (generated-sheet tier: form IoU >= 0.75, aspect drift <= 0.08; splats IoU >= 0.70)
- Form, p1 blockout (`golden.py views --hedra`, elevation 0): IoU 0.869 / 0.871 / 0.874 / 0.866,
  top aspect drift 0.085 (fail) -> tail tilted 35 deg instead of 25. Elevation 7 was worse
  (back drift 0.14): the sheet is drawn level.
- Form, p2 (final mesh): IoU front 0.890, right 0.823, back 0.890, top 0.869; aspect drift
  0.066 / 0.003 / 0.073 / 0.062. Pass.
- Splats, albedo (`camel_rest.bin`, the rest pose: `"animate": false` in its bake file): IoU
  front 0.794, right 0.734, back 0.788, top 0.803. Pass. Aspect drift 0.078 / 0.037 / 0.006 /
  **0.160 top: waiver** - each disc reaches about one sigma past the mesh, which widens the
  0.85 m-wide top view by ~20 % but the 2.3 m length by ~7 %; the mesh passes (0.062), and the
  sheet's top panel is itself 5 % longer than its side panel.
- Colour drift **0.46 / 0.34 / 0.39 / 0.32: waiver** - the sheet was generated for Endesga 16 and
  the palette became Parchment and Ink afterwards; the gate attributes a colour to the first
  ramp that lists it, and in this palette #a58a62, #886243, #c0977a, #445162 sit in 2-3 ramps
  each, so the sheet's lit orange sides count as `dune`/`bark` and the model's fur as `cloth`.
  The material choice was made with `palette.py fit` of the sheet instead (see Palette).
- Fixes the gates and looks asked for: top aspect (tail angle); black blots (step-1 bases);
  ears and tuft under 12 splats (ears 0.16, hoof material spacing 0.06); the `--arg animate=0`
  view still showed the walk's frame 0, so the rest pose is gated from a separate blob.
- Goldens: `goldens/camel` (framed, lit, `--arg shadeSteps=1`) and `goldens/camel@scene`
  (`--texel 0.0705 --size 160 --arg shadeSteps=1`), both frame 0 of the walk.
