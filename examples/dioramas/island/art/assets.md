# Assets: the floating well island

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; `orthoHeight` 8.5 m
-> texel 0.064 m. Splat spacing 0.09 m (1.4 texels). Palette: Fading 16 (`palette.json`, 16 colours).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Triangles | Notes |
|---|---|---|---|---|---|---|---|
| island | terrain | 6 x 6 x 2.5 | 1 | grass (texture `textures/grass_32.png`), wood step -1 (dirt), stone | this list | 72 | grass texture from Codex, fitted to 32 px |
| well | hero prop | 1.5 x 1.1 x 1.64 | 1 | stone, grass, wood, red (texture) | `well/sheet.v1.png` | 232 | the full concept -> gates -> goldens loop |
| pine | foliage | 1.7 x 1.7 x 2.2 | 4 (scale 0.85-1.25) | bark, foliage (sway) | this list | 80 | |
| rock | prop | 1.0 x 0.8 x 0.6 | 3 | stone | this list | 20 | |
| lantern | light prop | 0.4 x 0.2 x 1.0 | 1 | wood, glow (unlit) | this list | 36 | emissive glass |
| campfire | effect + prop | 1.1 x 1.1 x 0.95 | 1, at (-0.9, 0, 1.3) | stone (7 stones), wood (3 logs), fire (ember bed, flame base, 3 tongues; unlit) | this list | 312 | 3 tongues rigid, one bone each: stepped scale/sway on a 1 s loop (12 frames, constant), from the intensity table `I` in make_campfire.py |
| smoke puff | effect | 0.64 across at full size, rises 2.0 m | 6 (phases 0..5 s) | smoke (lit, nocast, `step` +1), fire (two warm caps, unlit) | this list | 320 | puff + 2 caps = 3 bones each: rise, drift, grow and shrink on a 6 s loop; caps out of the puff (lit) or inside it (dark) per frame from `I` and the puff's height |

Only the hero went through a generated turnaround sheet; the environment pieces are
simple enough to block out from this table.

Bones: campfire 3 + smoke 6 x 3 = 21 of 63 (the pines sway in the shader, no bones). The fire's light
on the smoke is two layered caps per puff, not a shader: a lit grey puff and unlit warm caps on its
underside that the animation pushes out of the puff (visible) or shrinks inside it (hidden), frame by
frame, in step with the flames.
