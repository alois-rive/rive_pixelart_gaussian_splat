# Kite Day: the asset list

Art grid: 640 x 400 at `pixelSize` 4 (160 x 100 art pixels; 4 keeps the HUD on the art grid), a side
view (orthographic look-at from +Z), `orthoHeight` 10 m: texel 0.098 m, splat spacing 0.15 m (1.5
texels). The play plane is z 0.5; the view spans x -8..8, y 0..10. Palette: Twilight 5 (five colours,
six ramps, see `palette.json`): materials are told apart by value. Sky: dusk blue #333f58 above a
dithered pink glow #ee8695 behind the far hills.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Triangles | Motion | Notes |
|---|---|---|---|---|---|---|---|---|
| `kite` | hero, the player | 1.0 x 0.36 x 1.5 (x 1.8 in the scene) | 1 | kite (pink, peach), bird (spars) | sheet v1, gated | 108 | game bone: hold/release lift, roll with speed, sway, squash on a catch | spars 0.07 (0.126 in scene) baked at spacing 0.07 |
| `bow` | prop (the tail) | 0.36 x 0.11 x 0.22 (x 1.6) | 5 | kite | from this list | ~30 | game bones: a verlet chain from the kite's stub, wind | `double`, `specks` (tiny on purpose) |
| `star` | pickup | 0.7 across (x 2.0) | 6 (pool) | glow (unlit) | from this list | ~80 | game bones: drift left, bob, stepped spin in the picture plane, pop | |
| `bird` | hazard | 1.9 span (x 1.4) | 4 (pool) | cloud (unlit, haze step), kite (beak) | from this list | ~70 | game bones: drift left faster, bob, stepped flap (y squash, 10 fps), tumble when hit | an "M" gull facing the camera; unlit so the ink cannot eat its outline |
| `spark` | effect | 0.16 (x 1.3) | 8 (pool) | glow (unlit) | none | 12 | game bones: a burst on each catch or hit | `specks` |
| `kid` | character | 0.75 x 0.4 x 1.35 (x 1.4) | 1 | bird (coat, hair, legs), kite (face, scarf) | from this list | ~120 | game bone: leans back while the string pulls, hops on a catch | the raised right hand holds the string |
| `cloud` | backdrop | 3.6 x 1.0 x 1.2 (x 1.3) | 3 | cloud | from this list | ~400 | game bones: slow drift with wrap (parallax) | lit: pink, peach tops, haze undersides |
| `ground` | terrain | 22 x 4 x 1.1, hill to z 2.6 | 1 | hill | from this list | ~900 | none | the kid's hill at x -6.5, a knoll at -2.9 under the kite |
| `far` | terrain | 26 x 1.5 x 2.9 | 1 | hill (haze step) | from this list | ~400 | none | back faces deleted |
| `sun` | backdrop | 3.2 disc | 1 | glow (unlit) | none | 12 | none | half set behind the far hills |
| `tree` | foliage | 1.7 x 1.4 x 2.8 | 3 | bird (trunk), hill (crown) | from this list | ~90 | `sway` | |

Bones: 28 of 63 (kite 1, bows 5, stars 6, birds 4, sparks 8, clouds 3, kid 1). Splats: 19 541.
The string is not a model: the HUD draws it, one art pixel wide, as a sagging curve from the kid's hand
to the kite (taut while held, slack when let go).
