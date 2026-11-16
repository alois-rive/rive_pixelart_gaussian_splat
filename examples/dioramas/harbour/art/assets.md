# Assets: the harbour

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; `orthoHeight` 8.5 m
-> texel 0.064 m. Splat spacing 0.10 m (1.6 texels); thinnest part 0.15 m (1.5 spacings) or a
smaller per-material spacing; smallest painted shape 0.2 m. Ink depth step 0.4 m.
Palette: Summers Past-16 (`palette.json`, 8 ramps; sky 6db7c3 over an e8bf92 haze, void 320011).
Camera: orthographic, yaw 22, pitch 30, no spin, target (0, 0.4, 0). Sun yaw -40, pitch 40.

| Asset | Class | Size (m) | Instances | Ramps (base step) | Concept | Triangles | Notes |
|---|---|---|---|---|---|---|---|
| boat | hero prop, animated | 3.0 x 1.22 x 2.0 (+0.25 below water) | 1 | hull (c33846, e78c5b, crate f7d554), navy (rail 5f3a60, roof 5e80b2, window 320011), deck (e8bf92, c66f5e), white (ece8c2, b7a39d), rock (mast 5f3a60), grass (flag d2cb3e) | `boat/sheet.v1.png`, gated | 334 | bobs: one joined mesh = 1 bone; 4 s loop at 12 fps; mast and flag at spacing 0.06 |
| gull | animated prop | 1.62 span x 0.99 x 0.2 | 3 (scale 0.8-1, phases 0 / 2.7 / 5.3 s) | white (ece8c2), rock (tips 876672), hull (beak f7d554) | this list | 96 | Orbit empty > Body > WingL/R = 3 bones each; 8 s orbit, 6 flaps then a glide; wings exaggerated to 0.70 x 0.30, material spacing 0.06 |
| sea | terrain / effect | 10 x 8 x 0.6 | 1 | sea (texture 5e80b2 / 6db7c3 / ece8c2, `sway`), navy (sides 5f3a60) | this list | 10 | `textures/sea.png` 40 x 32 = 0.25 m a texel; no underside |
| quay | terrain | 10 x 1.8 x 1.2 | 1 | grass + deck path (texture), rock (block texture) | this list | 10 | `grass.png` 50 x 9 (0.2 m a texel), `quay.png` 16 x 8 per 2 m |
| pier | architecture | 1.4 x 3.6 x 0.5, six 0.18 posts | 1 | deck (planks texture, posts 876672) | this list | 84 | `planks.png` 10 x 24 over the deck (0.14 m a texel) |
| islet | terrain | 3.2 x 2.6 x 0.6 | 1 | rock (876672), grass (8da24e) on top | this list | 80 | jittered icosphere, flat top for the lighthouse |
| lighthouse | light prop | 0.92 x 0.92 x 3.3 | 1 | white (ece8c2), hull (c33846 bands, roof), navy (gallery 5f3a60), rock (door), lamp (f7d554, `unlit`) | this list | 154 | four 0.6 m bands; door at spacing 0.05 |
| rock | prop | 1.0 x 0.8 x 0.7 | 5 (scale 0.6-1.2) | rock (876672) | this list | 20 | half in the water |
| crate | prop | 0.5 cube | 4 (one stacked at 0.8) | hull (f7d554) | this list | 28 | lid frame inset; yellow so it reads on the planks |
| barrel | prop | 0.5 x 0.5 x 0.55 | 4 | hull (933942), deck (lid c66f5e) | this list | 44 | 8 sides, bulge |

Bones: boat 1 + 3 gulls x 3 = 10 of 63. Blob: ~21 000 splats, 700 KiB.
Only the boat went through a generated turnaround sheet; everything else is blocked out from
this table (the skill's "assets without a sheet").
