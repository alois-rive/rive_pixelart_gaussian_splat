# Assets: Sky Stacker, a pagoda built above the clouds (NA16)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels. Orthographic, yaw 45, pitch 28,
`orthoHeight` 8.5 m (up to 13.5 at a game over, to show the tower): texel 0.0625 m. Splat spacing 0.09 m
(1.44 texels). Palette: NA16 (`palette.json`), 7 ramps: lacquer, roof, gold, stone, pine, cloud, earth.

Layout (world, Y up): a rocky peak whose grassy plateau tops out at y 0, a stone plinth to y 0.4, the
ground storey on it; storeys stack every 0.67 m. The camera climbs with the stack; clouds drift behind
the tower (away from the camera) and are lifted above it as it climbs. Play area (`bounds`):
x, z +-6, y -5 .. 26.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| storey | hero prop | 2.04 x 2.04 x 0.67 (0.86 drawn, shrunk for the splats) | 18 (pool `floor0..17`) + 4 offcuts (`chunk0..3`) | lacquer, roof, gold, stone | `storey/sheet.v1.png` | 164 | game: slide, drop, squash on landing, scaled per axis when cut (`placeScaled`); offcuts fall and tumble (`placeScaled` with pitch / roll) |
| peak | terrain | 10.8 x 10.8 x 7.2 | 1 | earth (rock), pine (grass) | this list | 61 | |
| plinth | architecture | 3.0 x 3.0 x 0.4 | 1 | stone | this list | 24 | |
| pine | foliage | 1.1 x 1.1 x 1.7 | 6 | earth, pine (sway) | this list | 46 | sway |
| cloud | effect | 2.6 x 1.4 x 0.8 | 14 static (sea of clouds, spacing 0.17) + 6 game bones (`cloud0..5`, spacing 0.12) | cloud (nocast) | this list | 100 | game: drift behind the tower, recycled upward |
| spire | prop | 0.6 x 0.6 x 1.6 | 1 (`spire`) | gold | this list | 172 | game: drops on the finished tower and bounces |

Bones: 29 game bones (18 floors, 4 offcuts, the spire, 6 clouds) of 63; no baked tracks. Blob: 87 501
splats (the storey's hidden faces removed and the clouds baked coarser to stay under 100 000).
