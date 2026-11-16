# Assets: Pancake Flip, a pastel kitchen (Vanilla Milkshake)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 visible art pixels (136 rows with the two
spare ones); `orthoHeight` 4 m -> texel 0.0294 m. Splat spacing 0.05 m (1.7 texels) for the kitchen,
0.034 m (about one texel) for the pans and pancakes, the thin things the eye is on. Palette: Vanilla
Milkshake (`palette.json`, 16 pastel colours), 10 ramps; the burner flames and the perfect-flip stars
are `unlit`. Camera: orbit, yaw 0, pitch 48, target a third of a texel off the art grid (the first renderer's HUD phase fix, kept).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| pan | hero prop | 0.93 x 1.47 x 0.22 (splat copy shrunk 0.82 x 1.37 x 0.10) | 3 (bones `pan0-2`) | iron (body, rim), berry (handle, cap) | `pan/sheet.v2.png` | 166 | game: dip and flick on a flip, a wobble on an empty click |
| pancake_raw / _golden / _dark / _burnt | prop | 0.54 x 0.54 x 0.03 | 3 each (`raw0-2`, `gold0-2`, `dark0-2`, `burnt0-2`) | batter; cake (golden top, a ramp whose top repeats the golden step so a sun-facing side never turns butter-white mid-flip) + golden; burnt | this list | 48 | game: cooking is a swap between the four looks; pour (spread in), sizzle, flip (arc, one turn at 12 fps, squash), hop to the plate, flop or shrink away |
| stack | prop | pancake_golden | 10 (`stack0-9`) | cake, golden | this list | 48 | game: the served stack grows on the plate, the new top squashes |
| kitchen | architecture | 6.4 x 1.35 x 4.3 | 1 | cream (counter, shelf), iron (cabinets, knobs, oven window), tile (wall checker, doors), mint (stove) | this list | ~300 | |
| burner | prop | 0.9 x 0.9 x 0.1 | 3 | iron (grate), flame (unlit ring) | this list | 72 | |
| plate | prop | 0.96 x 0.96 x 0.07 | 1 | cream | this list | 36 | |
| bottle (syrup) | prop | 0.36 x 0.36 x 0.66 | 2 (one 0.55 on the shelf) | berry, cream, iron (cap at spacing 0.035: specks otherwise) | this list | 80 | |
| bowl (batter) | prop | 0.68 x 0.68 x 0.5 | 2 (one 0.6 on the shelf) | mint, batter, berry | this list | 50 | |
| butter | prop | 0.6 x 0.6 x 0.22 | 1 | iron, golden | this list | 40 | |
| smoke | effect | 0.28 ball | 6 (`smoke0-5`) | cream (nocast) | this list | 20 | game: rises, grows and shrinks, stepped at 12 fps |
| star | effect | 0.14 ball | 6 (`star0-5`) | flame (unlit, nocast, specks) | this list | 20 | game: a burst on a perfect flip |

Bones: pans 3 + pancake looks 12 + stack 10 + smoke 6 + stars 6 = 37 of 63, all game bones.

Layout (glTF metres, Y up, +Z towards the camera): counter top at y 0 from x -3.2 to 3.2, the mint
stove between x -1.6 and 1.6; the pans at x -1, 0, 1 (z 0) on burners, handles to the front; the plate
at (-2.35, 0, 0.1); the bottle, the bowl and the butter on the right counter; the tiled wall at
z -0.6 up to y 2.4, a shelf at y 1.55 in the middle with a small bottle and bowl. `"bounds"`:
(-3.2, -1.9, -0.6) .. (3.2, 2.4, 0.8), covering the flips' arcs.

Hidden faces deleted in `kitchen.txt` (counter and stove bottoms, backs against the wall, the sides
where boxes touch): 42 360 -> 31 963 splats.
