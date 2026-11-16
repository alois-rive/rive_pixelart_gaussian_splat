# Assets: a lighthouse at night (1bit Monitor Glow, 2 colours)

Art grid: 640 x 400 artboard, `pixelSize` 2 -> 320 x 200 art pixels; a perspective camera (fov 35)
20 m from the lighthouse, so the texel there is about 0.063 m (focal 317 art pixels). Splat spacing
0.08 m (the sea 0.22 near, 1.0 far). Palette: 1bit Monitor Glow (`palette.json`): `#222323 #f0f6f0`.

Two colours make every ramp the same two colours, so a material's TONE comes from where it is painted
and how many times each colour repeats in its ramp (the shader steps down `shadeSteps` in shade and up
`lightSteps` past `highlight`, Bayer-dithered across a full step with `bandDither` 1). White density
on a lit face, with x = N.L / keyLight (keyLight = highlight = 0.6, shadeSteps 1.5, lightSteps 2):

| Ramp | Steps | Painted on | White share | Used for |
|---|---|---|---|---|
| pale | d l l | step 2 (light, `step` +1 in the bake) | min(1, 0.5 + 1.5 x): never below a 50 % dither | lighthouse, hut walls, boat |
| lit | d l | step 1 (light) | 1.5 x - 0.5: black in deep shade | cliff turf |
| lit | d l | step 0 (dark) | 2 (N.L - 0.6) / 0.4 above 0.6: glints only | cliff rock, rocks, sea |
| tar | d d l | step 0 (dark) | only past N.L 0.8 | bands, roofs, door, window, the boat's inside |
| glow | l | step 0, unlit | always white | lamp glass, the beams |

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Animation |
|---|---|---|---|---|---|---|---|
| lighthouse | hero prop | 2.0 x 2.0 x 4.51 (x 1.4 in the scene) | 1 | pale, tar, glow (unlit) | `lighthouse/sheet.v1.png` | 344 | lamp head: rigid, 1 turn / 8 s, linear, clockwise from above (against the orbit camera), 12 fps |
| beam | effect | 10 x 1.3 x 1.3 (x 1.4) | 1 | glow (unlit, two-sided), alpha-masked stipple texture | this list | 12 | the same turn as the lamp head |
| cliff | terrain | 11.9 x 9.3, top 4 m above the sea | 1 | lit (rock dark, turf light) | this list | 174 | |
| sea | terrain | discs: 34 m (1 m cells) + a ring to 90 m (4 m cells) | 1 | lit (dark; near part sways) | this list | 4520 | sway (near) |
| hut | prop | 2.7 x 2.5 x 2.95 (x 0.9) | 1 | pale, tar | this list | 80 | |
| rock | prop | 1.8 x 1.4 x 1.15 | 4 (0.7-1.3) | lit (dark) | this list | 20 | |
| boat | prop | 2.2 x 0.9 x 0.57 (x 1.5) | 1 | pale, tar | this list | 24 | bob: rigid roll +-7 deg, heave 6 cm, 3 s, eased |

Bones: 3 (lamp head, beam, boat). 90 580 splats (the far sea ring is 19 000 of them at 1 m spacing).
