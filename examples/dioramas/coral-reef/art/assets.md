# Assets: a coral reef with a giant clam (BLK AQU4)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 215 x 136 art pixels. Perspective camera (fov 40,
distance 9.5 m, pitch 32): at the orbit target the view is 6.9 m tall -> texel ~0.052 m there
(nearer sand is coarser, the far rim finer). Splat spacing 0.09 m (1.7 texels at the clam).
Palette: BLK AQU4 (`palette.json`, 4 colours, 7 ramps sharing them).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Animation |
|---|---|---|---|---|---|---|---|
| seabed | terrain | 14 x 14 x 0.6 | 1 | sand (64 px ripple texture), rock | this list | 602 | |
| clam | hero prop | 2.0 x 1.76 x 1.65 (x1.4 in the scene) | 1 | shell (Shell, Groove, Mantle), glow (pearl, unlit) | `clam/sheet.v1.png` | 236 | upper shell: rigid, closes 10 deg and reopens, 6 s, 12 fps |
| kelp | foliage | 1.0 x 1.0 x 2.75 | 6 (0.9-1.3) | kelp (Stalk, Blade two-sided) | this list | 156 | skinned, 3 bones a stalk, circular sway 4 s, phases 0-3 s |
| coral_branch | prop | 1.3 x 1.3 x 1.1 | 2 | coral (pale) | this list | 140 | |
| coral_brain | prop | 1.1 x 1.1 x 0.55 | 2 | coral (Brain aqua, Fold blue) | this list | 80 | |
| coral_fan | foliage | 1.4 x 0.06 x 1.55 | 2 | coral (blue, two-sided, sway) | this list | 44 | `sway` flag |
| rock | prop | 1.4 x 1.1 x 0.8 | 3 | rock | this list | 20 | |
| fish | creature | school 7.4 x 7.4, fish 0.2 x 0.92 x 0.34 | 2 schools (0.85-1.0) | fish (Scale pale, Fin aqua) | this list | 132 | rigid: Orbit empty turns 360 deg / 12 s; 3 bodies, each a Tail child flicking +-30 deg every 4 frames |
| bubbles | effect | 5.4 x 2.6 x 10 | 1 | glow (unlit, pale) | this list | 840 | rigid rise 5 m / 6 s, seamless |

Bones: clam 1 + kelp 6 x 3 + fish 2 x 6 + bubbles 1 = 32 of 63.

Bubbles: two identical 5 m fields of 21 bubbles (three columns: through the clam, and at (2.6, -1.4)
and (-2.4, 0.6)) stacked; the lower field starts under the sand, inside the seabed, so bubbles come
out of the floor; the object rises one field per loop, so the upper field takes the lower one's
place and the loop has no seam; bubbles leave the frame (and the fog) above 5 m.
