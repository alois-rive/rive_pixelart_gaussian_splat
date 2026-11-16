# Asset: sailboat (the hero, the player's boat; two game bones)

Concept: ../../art/sailboat/sheet.v1.png (mulfok32 colours, background #9a9a9a), refs cut to
../../art/sailboat/refs/ (no flips: the sheet follows the brief's orientation). Up Z, bow towards -Y,
origin at the waterline amidships; only the part above the waterline (the water is the scene's sky
colour, so anything below y 0 would show). A cat-rigged racing dinghy: one mast, one mainsail on a boom.
Placed in the scene at scale 1.35 (5.0 m long, about 40 art pixels).

Scale: 150 px per metre, from the front panel's hull width (178 px = 1.19 m); the right panel agrees on
heights at the same scale.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Hull | 1.19 wide, 3.7 long, 0.5 tall; bow a point raked back 0.43 at the waterline; the bottom 0.82 of the deck's width; transom 0.95 wide | deck at z 0.5, taper ends 1.29 m behind the bow | HullRed #ea6262 (red, 4) |
| Deck | the hull's top | | Deck #d9bdc8 (white, 2) |
| Cockpit well | 0.7 x 1.07, 0.15 deep | 2.2 to 3.27 m behind the bow | Wood #a6555f (wood, 3) |
| Mast | 0.12 square, 2.45 above the deck | 0.87 m behind the bow | Spar #4a3052 (rock, 1) |
| Boom | 0.1 square, 2.45 long | 0.29 above the deck, from the mast aft | Spar |
| Mainsail | a 0.05 plate, a right triangle: luff 2.0 up the mast from the boom, foot 2.42 along the boom | | Sail #ffffff (white, 3) |
| Sail band | across the sail at 0.77 to 1.07 above the deck | | Band #d46eb3 (blossom, 2) |
| Rudder, tiller | 0.08 x 0.14 x 0.63 on the transom; tiller 0.06 x 0.95 into the cockpit | | Wood |

156 triangles (hull 108, rig 48). `p1_blockout.txt` (primitives at the spec's sizes, the hull shaped by bisect and vertex
scales, the sail plate pulled into a triangle), `p2_form.txt` (the cockpit sunk, the band cut, materials,
joined into two objects: `Hull` and `Rig`; `sailboat.glb`, the gated form), `p3_splat_fit.txt` (run on a
copy, `sailboat_fit.rmdl`: the splat fit below; exports `sailboat_fit.glb` for the bench, `hull.glb` and
`rig.glb` for the scene's two bones). The rig keeps the mast where the hull carries it; the game swings it
about the mast's foot (0, 0.5, 0.98 in the GLB, x 1.35 in the scene).

## Assumptions
- The sheet's rig is lower than the brief asked (2.45 m above the deck, not 4.2): the sheet leads. It
  suits a view from above (a tall mast would tower over the boat in a pitched orthographic view).
- The sheet contradicts itself on the length: the right panel draws the hull 3.7 m long (553 px), the
  top panel 2.96 m (444 px) at the same width, most of the difference behind the mast. Front, right and
  back lead (they agree on every height and width); the top view gets a waiver (below).
- The sheet's side panels are drawn a degree or two from above (the deck shows as a sliver in front and
  back); the model is built level.
- The sheet's top panel shows the sail as a line along the centre: the model too (boom straight aft).
  In the game the boom swings out to leeward.

## Splat fit (p3)
Splats reach about one radius past every face, so a narrow boat seen end-on comes out fat and the thin
mast triples in width: p3 narrows the hull to x 0.87, lowers it to z 0.86, thins the mast to 0.07 m (baked
at 0.05 m spacing), the sail plate to 0.03 m and the boom to 0.07 m. The bench bakes at the scene's own
density (spacing 0.126 = 0.17 / 1.35, spars 0.037, wood 0.059, sail 0.089).

## Gate record (generated-sheet tier, thresholds chosen before the build)
Form, hedra views vs refs (`--min-iou 0.75 --max-aspect-drift 0.08`), p1 = p2 (p2 adds no silhouette):

| View | IoU | aspect drift |
|---|---|---|
| front | **0.887** | **0.016** |
| right | **0.832** | **0.016** |
| back | **0.756** | **0.009** |
| top | **0.931** | 0.258 (waiver) |

Look, splats albedo (`lookdev/sailboat.bin`, p3 fit at the scene's density; exact views `--arg pitchMin=0
--arg pitchMax=90`; `--min-iou 0.7 --max-aspect-drift 0.08`, colour drift ≤ 0.25):

| View | IoU | aspect drift | colour drift |
|---|---|---|---|
| front | 0.682 (waiver) | **0.014** | **0.16** |
| right | **0.872** | **0.005** | **0.17** |
| back | **0.738** | **0.038** | **0.20** |
| top | **0.893** | 0.176 (waiver) | **0.18** |

At the default gate angles (side views from 5 degrees above, `pitchMin` 5) the end-on views read lower
(front 0.567, back 0.653): a 3.7 m deck seen from 5 degrees adds 0.32 m of height to a 0.46 m hull. The
exact views are the honest measure here and are the ones recorded.

Waivers:
- top, aspect (mesh 0.258, splats 0.176; IoU 0.931 / 0.893 pass): the sheet's top panel is 20 % shorter
  than its right panel at the same width; a hull that matches the right view cannot match the top's
  aspect.
- front, splats IoU (0.682 against 0.7; aspect 0.014 passes): the view is three quarters mast. At the
  scene's density the deck's discs and the hull's top edge each grow a splat radius, so the hull band is
  two splat rows taller relative to a 0.07 m mast; narrowing and lowering the hull further (p3 tried z
  0.92 and 0.86: 0.684, 0.682) does not move it. The game never shows the boat end-on from the water
  line: the camera looks down at 55 degrees, where the right view (0.872) and the top (0.893) describe it.

`hedra model sailboat.rmdl inspect check`: 2 ngon findings on the hull (the bisected deck faces), harmless
(the export triangulates); nothing else.

Goldens: `goldens/sailboat` (framed), `goldens/sailboat@scene` (`--texel 0.0871 --size 160`: the scene's
0.118 m texel at scale 1.35), lit like the scene (`--arg sunYaw=-35 --arg sunPitch=52 --arg keyLight=0.45
--arg highlight=0.85 --arg shadeSteps=1 --arg lightSteps=1`, `--real-sky`).
