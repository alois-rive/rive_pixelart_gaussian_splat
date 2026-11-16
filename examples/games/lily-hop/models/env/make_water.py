#!/usr/bin/env python3
"""Draws textures/water.png: the pond's surface, palette-exact (Sweetie 16 water ramp): a deep blue
#3b5dc9 with short horizontal ripple dashes in #41a6f6 (2-4 texels long, 1 tall) and a few #29366f
dark ones. 68 x 24 texels over the 17 x 6 m water plane: 0.25 m a texel (about 3 splats)."""
import random
from PIL import Image

W, H = 68, 24
BASE, LIGHT, DARK = (0x3b, 0x5d, 0xc9), (0x41, 0xa6, 0xf6), (0x29, 0x36, 0x6f)
rng = random.Random(7)
img = Image.new("RGB", (W, H), BASE)
px = img.load()
for i in range(70):
    x, y, n = rng.randrange(W), rng.randrange(H), rng.choice((2, 3, 3, 4))
    c = DARK if i % 5 == 0 else LIGHT
    if any(px[(x + k) % W, y] != BASE or px[(x + k) % W, (y + 1) % H] != BASE or px[(x + k) % W, (y - 1) % H] != BASE
           for k in range(-1, n + 1)):
        continue
    for k in range(n):
        px[(x + k) % W, y] = c
img.save("textures/water.png")
print("wrote textures/water.png")
