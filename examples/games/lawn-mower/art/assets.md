# Assets: Lawn Mower (Endesga 16, 16 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; an orbit camera at yaw 0 (the lawn's
grid and stripes square to the art grid), pitch 55, orthographic 7.6 m -> texel 0.056 m. Splat spacing
0.075 m (1.34 texels); small parts finer (fence, flowers, gnomes, the mower's people 0.05-0.065).
Palette: Endesga 16 as eight ramps (lawn, rough, wood, red, straw, stone, blue, skin). `rough` repeats its
darkest green (`#193d3f` twice) so the long grass stays dark on its lit faces and only its tufts catch the
mid green; `lawn` holds the two mowed stripe greens.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| mower | hero / player | 1.14 x 1.52 x 1.3 | 1 (`mower`) | red (body), wood (tyres, seat, legs), stone (deck, chute, hubs), blue (shirt), skin, straw (hat) | `mower/sheet.v1.png` | 556 | game: drives after the pointer (turn rate, speed by heading), judders at 12 fps, pitches with speed, hops and shakes on a bump |
| tuft | terrain / game tile | 0.84 x 0.84 x 0.34 | 44 (`tile0-43`) | rough (turf, tufts) | this list | 58 | game: one per lawn tile; squashed flat and hidden when cut, sprouts back with an overshoot in a wave when a lawn is cleared; leans in a stepped breeze |
| ground | terrain | 12.8 x 10.6 | 1 | lawn (8 stripe columns: light / mid), wood (sandy path, soil), stone (bed kerbs) | this list | 288 | static |
| garden | props | round the lawn | 1 | stone (picket fence, birdbath), wood (shed), red (roof, flowers), lawn (bushes, sway), straw / stone (flowers), blue (water) | this list | 2582 | bushes sway |
| gnome | prop / obstacle | 0.42 x 0.32 x 0.92 (1.4 x its model) | 4 (`gnome0-3`) | wood (boots), blue (coat), skin, stone (beard), red (hat) | this list | 76 | game: stands on a grid corner, topples and rocks back when bumped, hops to a new corner each lawn |
| clip | effect | 0.11 chip | 8 (`clip0-7`) | lawn | this list | 12 | game: thrown from the chute on the mower's right while it cuts |
| petal | effect | 0.11 chip | 4 (`petal0-3`) | red | this list | 12 | game: thrown up when the mower hits a flower bed |

Bones: 61 game bones of 63 (44 tiles, the mower, 4 gnomes, 8 clippings, 4 petals). Splats: 68 456.

Layout (glTF metres, Y up, the camera on +Z): the lawn is 8 x 6 tiles of 0.85 m (x -3.4..3.4, z
-2.55..2.55); the two flower beds cover tiles (1, 1)-(2, 1) and (5, 4)-(6, 4) (column, row from the
back-left), so 44 tiles carry long grass. Under them the mowed lawn is baked static, one stripe a
column. A sandy path 0.55 m wide runs round it; the mower may drive on it (|x| <= 3.75, |z| <= 2.9).
Beyond: soil borders with flowers and bushes, the shed back left, the birdbath right, the picket fence at
z -4.35 and down both sides.

How coverage is shown with splats: each tile of long grass is its own game bone over the baked stripes.
Cutting squashes the tile flat (stepped) and hides it, so the stripe underneath shows; a cleared lawn
grows every tile back (scale up from 0.12 with an overshoot), as a wave from the back-right corner.
