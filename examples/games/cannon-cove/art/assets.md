# Cannon Cove: the asset list

Art grid: 640 x 400 at `pixelSize` 2 (320 x 200 art pixels; HUD 320 x 200), orthographic,
`orthoHeight` 11.5 m: texel t = 11.5 / 202 = 0.057 m. Splat spacing 0.08 m (1.4 t) for most
things, 0.1-0.12 m for the big water and beach (2 t: painterly), 0.05-0.06 m for small parts.
Camera: orbit yaw 20, pitch 22, target on the art grid (-1.213, 2.500, -3; see README).
Palette: SLSO8 (8 colours), ramps in `palette.json`. Up is +Y in the world (+Z in hedra).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Triangles | Motion | Notes |
|---|---|---|---|---|---|---|---|---|
| `cannon` (carriage + barrel) | hero prop | 0.9 x 1.6 x 0.95 (x1.8 in the scene) | 1 | iron, wood, sand (wheels) | `art/cannon/sheet.v1.png`, gated | ~510 | barrel: game bone (elevation with the charge, recoil kick and squash, tremble while charging) | exported as `carriage.glb` (static) and `barrel.glb` (pivot = trunnions at the origin); scene bake paints the barrel one step lighter (`"step": 1`) so it reads against the navy water |
| `ship` | prop / target | 2.9 x 0.8 x 2.9 | pool of 4 | wood, iron (mast), sail | from this list | ~120 | game bones: sail across the lane, bob and rock (stepped 12 fps), hit pop, sink bow-up | the sail runs fore-and-aft so the cannon sees it broadside; far lanes scaled 0.86 / 0.74 |
| `water` | terrain | 24 x 26 | 1 | sea, glow (glints, unlit) | from this list | ~5 000 | sway (twinkle) | 0.5 m facets with height noise; a path of glints under the sun as the yaw-20 camera sees it |
| `shore` | terrain | 24 x 4 + dunes | 1 | sand, rock, palm | from this list | ~900 | fronds sway | palms are dark silhouettes (palm ramp), fronds two-sided |
| `headland` | terrain | 5 x 3 x 2.6 (x1.3 / x1.15) | 2 | rock, sand, palm | from this list | ~500 | fronds sway | underwater faces deleted |
| `ledge` | terrain | 6.5 x 3.6 x 1.6 | 1 | rock, sand, wood (keg), iron (balls) | from this list | ~400 | none | the cannon's rock, a keg, a pyramid of balls |
| `sun` | effect | 3.6 disc + 4 clouds | 1 | glow (unlit) | from this list | ~80 | none | far behind the shore, half set behind the dunes |
| `ball` | prop | 0.36 | 1 (game bone) | iron | from this list | 80 | game: ballistic arc | exaggerated size |
| `marker` | effect | 1.0 ring | 1 (game bone) | glow (unlit) | from this list | ~100 | game: slides out with the charge, pulses | sits 0.16 m up, clear of the wave facets |
| `flash` | effect | 0.9 | 1 (game bone) | glow (unlit) | from this list | 36 | game: two frames at the muzzle | |
| `splash` | effect | 1.3 tall | pool of 3 | glow (unlit) | from this list | ~100 | game: shoots up, hangs, falls back (placeScaled) | |
| `smoke` | effect | 0.7 | pool of 4 | sail | from this list | 80 | game: three puffs roll out of the muzzle, grow, shrink | |
| `plank` | effect | 0.5 x 0.14 x 0.1 | pool of 8 | wood | from this list | 12 | game: debris thrown from a hit ship, spinning | |

Bones: 23 game bones (barrel, ship0-3, ball, marker, flash, splash0-2, smoke0-3, plank0-7) of 63;
no baked tracks. Splats: 112 945 in `scene/splats.bin`.
