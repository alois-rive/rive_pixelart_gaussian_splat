# Fruit Basket: asset list

Art grid: 640 x 400 at `pixelSize` 2 (320 x 200 art pixels, a 322 x 202 canvas). Orthographic camera, yaw 0,
pitch 20, `orthoHeight` 7 m: texel t = 7 / 202 = 0.035 m. Splat spacing 0.055 m (1.6 t); big flat ground and
hedge 0.07 m. The cart lane runs along X at z 0.3 (world, Y up); fruit falls into that lane from the canopies.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Triangles | Motion | Notes |
|---|---|---|---|---|---|---|---|---|
| `cart` (hero) | prop / player | 2.0 x 1.1 x 1.1 (body 1.4 x 0.75) | 1 | blue (painted sides), wood (rim, posts, handles), red (hub, apples) | `art/cart/sheet.v1.png` | ~350 | game: bones `cart` (lean, squash) and `wheels` (rolls with the distance) | an open tray (inset + sunk 0.4 m) so caught fruit drops in; rim 0.07 thick |
| `ground` | terrain | 14 x 7.5 | 1 | grass, wood (path) | from this list | ~400 | none | the path picked as faces of the subdivided top, no decal |
| `hedge` | foliage | 15 x 1.2 x 1.3 | 1 | leaf (painted on the teal step) | list | ~1500 | sway | the orchard's back wall |
| `fence` | architecture | 13 x 0.14 x 0.9 | 1 | wood | list | ~150 | none | posts every 1.4 m, two rails |
| `tree` | foliage | 0.6 x 0.6 x 2.3 | 3 | wood | list | ~100 | none | trunk and limbs; the crown is `canopy` |
| `canopy` | foliage | 2.9 x 2 x 1.9 | 3 | leaf, red (five small apples) | list | ~500 | game: bones `canopyL/M/R`, shake before a drop | its apples are smaller than the falling fruit on purpose |
| `apple` | prop | 0.5 (0.38 x 1.3) | 6 (pool) | red, wood (stalk), leaf | list | ~100 | game: hang, wobble, fall, squash | pool scale 1.3 in the bake (exaggerated to read) |
| `orange` | prop | 0.47 | 3 | orange | list | ~90 | game | |
| `plum` | prop | 0.42 x 0.52 | 3 | plum | list | ~90 | game | 2 points |
| `pear` | prop | 0.47, glows | 2 | pear (unlit) | list | ~170 | game | golden pear: 5 points |
| `rotten` | prop | 0.5 | 5 | rot (painted on its top step, grey), grass (dark mould) | list | ~240 | game | light grey so it reads in front of the dark fence |
| `spark` | effect | 0.14 | 8 | stone (unlit, cream) | none | 12 | game: a burst on each catch | `specks` (tiny on purpose) |
| `crate` | prop | 0.84 x 0.6 x 0.6 | 1 | wood, red | list | ~150 | none | |
| `bush` | foliage | 1.2 x 1 x 0.8 | 2 | leaf, red (flowers on the pale step) | list | ~300 | sway | |
| `rock` | prop | 0.7 x 0.5 x 0.35 | 2 | stone | list | 80 | none | |

Bones: 32 of 63 (3 canopies, cart, wheels, 19 fruit, 8 sparks), all game bones, none baked.
Splats: 74 000 (ground 20 200, canopies 29 300, hedge 6 400).

Palette: CC-29 (`cc-29` on Lospec, 29 colours), ramps grass, leaf, wood, red, orange, pear, plum, rot,
blue, stone (`art/palette.json`); sky cyan #68c2d3 over mint #a2dcc7, void #212123.
