#!/usr/bin/env python3
"""Draws textures/soil.png: the tilled bed, palette-exact (Steam Lords soil ramp): #603b3a earth with
ridges of #775c4f two texels tall every six, broken here and there. 28 x 22 texels over the 5.6 x 4.4 m
bed: 0.2 m a texel (about three splats)."""
import random
from PIL import Image

W, H = 28, 22
EARTH, RIDGE = (0x60, 0x3b, 0x3a), (0x77, 0x5c, 0x4f)
rng = random.Random(5)
img = Image.new("RGB", (W, H), EARTH)
px = img.load()
for y0 in range(1, H, 6):
    gap = rng.randrange(W)
    for x in range(W):
        if (x - gap) % W < 3:
            continue
        for y in (y0, y0 + 1):
            if y < H:
                px[x, y] = RIDGE
img.save("textures/soil.png")
print("wrote textures/soil.png")
