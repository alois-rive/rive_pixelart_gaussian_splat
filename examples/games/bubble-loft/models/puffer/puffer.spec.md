# Asset: puffer, the orb puffer (hero, game-driven)

Concept: ../../art/puffer/sheet.v1.png (Sunset 8 colours), refs cut to ../../art/puffer/refs/ with no flip
or rotation (the sheet's views are where the brief asked: the bulb on the image's left in FRONT and on its
right in BACK, the cup nearest the camera in RIGHT, the front at the bottom of TOP). A copper drum on an
iron plinth, a brass barrel with a pink tulip mouth that holds the orb to launch, a plum squeeze bulb on
its own right (-X) and a brass cup on an arm on its own left (+X) for the next orb. Up Z, facing -Y; origin
on the ground under the barrel. Scale from the front panel: 456 px = 2.4 m -> 190 px per metre.

## Parts (metres)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Plinth | octagonal prism, 1.38 across the flats, 0.33 tall | z 0 .. 0.33 | Iron (iron, #464678) |
| Drum | octagonal prism, 1.11 across the flats | z 0.33 .. 1.12 | Copper (copper, #ffa936) |
| Lid | octagonal cone 1.11 -> 0.35 across the flats | z 1.12 .. 1.33 | Brass (brass, #ffc247) |
| Barrel | octagonal prism, 0.35 across the flats | z 1.33 .. 1.97 | Brass |
| Mouth | octagonal cone 0.35 -> 0.80 across the flats, and four petal blades (4-sided cones r 0.30, flattened to half, leaning out 16 degrees) front, right, back, left | z 1.97 .. 2.22, tips to 2.42 | Petal (petal, #e67595) |
| Bulb | ico-sphere (80 faces) r 0.40 | centre x -1.08, z 0.79 | Rubber (rubber, #9a6390) |
| Hose | hexagonal tube r 0.075, 0.24 long along X | x -0.62, z 0.79 | Rubber |
| Arm | box 0.26 x 0.11 x 0.11 | x 0.66, z 0.82 | Brass |
| Cup | octagonal ring 0.58 across the flats, 0.26 tall, walls 0.06, open top and bottom | centre x 1.07, z 0.72 .. 0.98 | Brass |

`make_puffer.py` writes `p1_blockout.txt` (every part and its material), `p2_form.txt` (the cup hollowed
into a ring, hidden caps deleted, flat shading, the export `puffer.glb`) and `p3_splat_fit.txt` (below).

## Assumptions
- Front and back lead. The sheet's TOP view puts the bulb and the cup about 5 % farther out (1.13-1.17 m)
  than the front view (1.07-1.08 m): modelled from the front; the top view still passes.
- The side views are drawn from a few degrees above (the cup's rim shows as a ring in FRONT): not
  modelled as height; the gate's 5-degree renders see the same.
- The sheet's petals are broad wedges; here four flattened pyramids. The front-view IoU passes; at the
  scene's texel the mouth reads as a crown holding the orb, which is what the game needs.
- Hidden caps (the drum's and the lid's bottoms, the barrel's ends, the plinth's bottom) are deleted:
  `inspect check` reports their open edges as non-manifold, on purpose.

## Gate record (generated-sheet tier: form IoU >= 0.75, aspect drift <= 0.08, splat IoU >= 0.70, splat drift <= 0.08, colour <= 0.25)
| Iteration | front | right | back | top | Change |
|---|---|---|---|---|---|
| p1 v1 | 0.891 / 0.001 | 0.925 / 0.005 | 0.902 / 0.003 | 0.901 / 0.025 | passes; the petals were flattened the wrong way (fins seen edge-on from the front) |
| p1 v2 | 0.895 / 0.001 | 0.932 / 0.005 | 0.906 / 0.001 | 0.901 / 0.025 | petals flattened radially (broad face outwards), wider (r 0.24) |
| **p2** | **0.896 / 0.001** | **0.935 / 0.002** | **0.908 / 0.003** | **0.934 / 0.025** | the cup hollowed into an open ring (the TOP view's hole); petals r 0.30, leaning 16 degrees |

Splats, albedo, from p2 (`spacing` 0.1, brass / petal / rubber 0.07): IoU 0.821 / 0.889 / 0.811 / 0.844,
aspect drift 0.035 / 0.034 / 0.064 / **0.105** (fail): every disc reaches a radius past its face, so the
octagonal plinth and drum come out ~10 % too deep in the TOP view. The mesh gate and the splat gate
disagree (modeling.md): `p3_splat_fit.txt` keeps the gated p2 and only scales the plinth, the drum and the
lid to 0.9 of their depth (Y); it exports `puffer_splat.glb` (the bench's) and the scene's three parts.

**Splats, albedo, from p3**: IoU **0.832 / 0.877 / 0.821 / 0.810**, aspect drift **0.056 / 0.008 / 0.051 /
0.056**, colour drift **0.10 / 0.12 / 0.10 / 0.12**: pass. No waiver was needed for a number.

**Waiver (look, not a number)**: with the scene's light the mouth's shaded faces step down the petal ramp.
The ramp was first `plum, pink, salmon, orange`: its shade step is the plum of the dusk sky, and in the lit
bench (`--real-sky`) the cone vanished into the sky in the side views (only petal tips showed). The petal
ramp now shades to navy (`navy, pink, salmon, orange`); the sheet paints the mouth's shade plum, so its
shaded side differs from the concept by design. The gates above were re-run after the change (same
numbers: albedo renders use the painted step only).

## The scene's parts
`p3_splat_fit.txt` also exports, each re-centred on its pivot so `api.place` turns it there:
`puffer_base.glb` (plinth, drum, lid, hose, arm, cup: static), `puffer_barrel.glb` (barrel + mouth, origin
at the lid's top, z 1.33: the game rolls it to the aim) and `puffer_bulb.glb` (origin at its inner side,
x -0.68: it squashes towards the drum). The scene bakes all three at scale 1.15.

Goldens: `goldens/puffer` (framed) and `goldens/puffer@scene` (`--texel 0.0717 --size 100`: the scene's
0.0824 m texel divided by the scene's 1.15 scale), lit like the scene (`--arg sunYaw=-38 sunPitch=34
keyLight=0.35 highlight=0.85 shadeSteps=1 edgeDepth=0.5`, `--real-sky`). The sheet is not reviewed by a
person yet (`art/puffer/sheet.v1.png.json`, `reviewed: false`).
