#!/usr/bin/env python3
"""Draw the harbour's palette-exact textures (Summers Past-16), deterministic.

  /usr/bin/python3 art/textures/make_textures.py      -> models/env/textures/*.png

Each texel is world-sized (about 1.5 to 2.5 splats); every shape is at least 2 texels long.
Lit colours only: the renderer shades along the ramps.
"""
import os
import random

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "models", "env", "textures")
os.makedirs(OUT, exist_ok=True)


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def planks():
    """Pier deck, 10 x 24 over 1.4 x 3.6 m (0.14 x 0.15 m a texel): planks across the pier,
    2 texels wide, c66f5e with every third board a lighter e8bf92; one board in four has a
    butt joint where the colour swaps, staggered."""
    a, b = rgb("c66f5e"), rgb("e8bf92")
    im = Image.new("RGBA", (10, 24))
    for row in range(12):
        light = row % 3 == 2
        cut = (3, 7, 5, 4)[row % 4] if row % 4 == 1 else None
        for y in (2 * row, 2 * row + 1):
            for x in range(10):
                l = light if cut is None or x < cut else (not light)
                im.putpixel((x, y), b if l else a)
    im.save(os.path.join(OUT, "planks.png"))


def sea():
    """Sea top, 40 x 32 over 10 x 8 m (0.25 m a texel): 5e80b2 water with 3 x 1 crests of 6db7c3
    and a few 2 x 1 glints of ece8c2 next to them."""
    base, crest, glint = rgb("5e80b2"), rgb("6db7c3"), rgb("ece8c2")
    im = Image.new("RGBA", (40, 32), base)
    rnd = random.Random(7)
    taken = set()
    n = 0
    while n < 34:
        x, y = rnd.randrange(40), rnd.randrange(32)
        w = rnd.choice([3, 3, 4])
        cells = [((x + i) % 40, y) for i in range(w)]
        ring = {((cx + dx) % 40, (cy + dy) % 32) for cx, cy in cells for dx in (-1, 0, 1) for dy in (-1, 0, 1)}
        if ring & taken:
            continue
        taken |= ring
        for c in cells:
            im.putpixel(c, crest)
        if n % 5 == 0:
            im.putpixel(cells[0], glint)
            im.putpixel(cells[1], glint)
        n += 1
    im.save(os.path.join(OUT, "sea.png"))


def grass():
    """Quay top, 50 x 9 over 10 x 1.8 m (0.2 m a texel): 8da24e with 2 x 2 to 3 x 2 patches of
    d2cb3e and 627057, and a 2-texel sandy path (e8bf92) to the pier head at u 0.53."""
    base, light, dark, path = rgb("8da24e"), rgb("d2cb3e"), rgb("627057"), rgb("e8bf92")
    im = Image.new("RGBA", (50, 9), base)
    rnd = random.Random(11)
    for k in range(16):
        x, y = rnd.randrange(0, 48), rnd.randrange(0, 8)
        w = rnd.choice([2, 3])
        c = light if k % 2 else dark
        for i in range(w):
            for j in range(2):
                im.putpixel(((x + i) % 50, (y + j) % 9), c)
    for y in range(9):
        for x in (26, 27):
            im.putpixel((x, y), path)
    im.save(os.path.join(OUT, "grass.png"))


def quay():
    """Quay wall, 16 x 8 per 2 m (cube-projected at --size 2: 0.125 m a texel): stone blocks
    4 x 2 texels (0.5 x 0.25 m) of 876672 and b7a39d, courses offset by half a block."""
    a, b = rgb("876672"), rgb("b7a39d")
    im = Image.new("RGBA", (16, 8))
    rnd = random.Random(5)
    for course in range(4):
        off = 2 if course % 2 else 0
        cols = [rnd.random() < 0.35 for _ in range(4)]
        for y in (2 * course, 2 * course + 1):
            for x in range(16):
                im.putpixel((x, y), b if cols[((x + off) // 4) % 4] else a)
    im.save(os.path.join(OUT, "quay.png"))


planks()
sea()
grass()
quay()
print("wrote", ", ".join(sorted(os.listdir(OUT))), "to", os.path.normpath(OUT))
