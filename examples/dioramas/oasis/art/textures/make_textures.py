#!/usr/bin/env python3
"""Palette-exact textures for the oasis, drawn by script (flat shapes, no light painted in).

  sand_48.png    48 x 48 over the 8.4 m ground top (0.175 m a texel, ~2 splats): #e6d1a1 sand,
                 wind ripples of #caac77 one texel thick (dune ramp steps 3 and 2): light sand, so the
                 camel (#c0977a) reads against it
  water_16.png   16 x 16 over the 2.5 m pond (0.16 m a texel): #87867a water, #a9a994 ripple dashes
                 two texels long (water ramp steps 2 and 3)
  canopy_16.png  16 x 8 over the stall canopy: #c0977a / #f0d696 stripes two texels wide (cloth 2, 3)
"""
import math
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def sand():
    a, b = rgb("e6d1a1"), rgb("caac77")
    im = Image.new("RGBA", (48, 48), a)
    for x in range(48):
        # wavy ripple rows every 8 texels, broken into dashes so they read as wind ripples
        for row in range(0, 48, 8):
            y = (row + round(1.6 * math.sin(2 * math.pi * x / 24 + row))) % 48
            if (x + row * 3) % 16 < 12:
                im.putpixel((x, y), b)
    im.save(os.path.join(HERE, "sand_48.png"))


def water():
    a, b = rgb("87867a"), rgb("a9a994")
    im = Image.new("RGBA", (16, 16), a)
    for (x, y) in [(2, 2), (9, 4), (5, 8), (12, 10), (1, 13), (8, 14)]:
        for dx in range(3):
            im.putpixel(((x + dx) % 16, y), b)
    im.save(os.path.join(HERE, "water_16.png"))


def canopy():
    a, b = rgb("c0977a"), rgb("f0d696")
    im = Image.new("RGBA", (16, 8))
    for y in range(8):
        for x in range(16):
            im.putpixel((x, y), a if (x // 2) % 2 == 0 else b)
    im.save(os.path.join(HERE, "canopy_16.png"))


if __name__ == "__main__":
    sand()
    water()
    canopy()
