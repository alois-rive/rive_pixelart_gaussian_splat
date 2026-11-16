# Draws the level's palette-exact textures (DawnBringer 32 steps of each material's ramp; no light
# painted in). Run from models/level: /usr/bin/python3 make_textures.py
import random
from PIL import Image

def hexc(h): return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16), 255)

def soil():          # 24 x 24 over 3.84 m (0.16 m a texel): soil with pebbles and dark clods
    r = random.Random(3)
    base, peb, clod = hexc("#663931"), hexc("#8f563b"), hexc("#45283c")
    im = Image.new("RGBA", (24, 24), base)
    for k in range(14):
        x, y = r.randrange(24), r.randrange(24)
        c = peb if k % 2 else clod
        for dx, dy in ((0, 0), (1, 0)) if k % 3 else ((0, 0), (1, 0), (0, 1), (1, 1)):
            im.putpixel(((x + dx) % 24, (y + dy) % 24), c)
    im.save("textures/soil.png")

def grass():         # 24 x 24 over 3.84 m: grass with lighter tufts and a few tiny flowers
    r = random.Random(5)
    base, tuft, dark = hexc("#6abe30"), hexc("#99e550"), hexc("#4b692f")
    im = Image.new("RGBA", (24, 24), base)
    for k in range(18):
        x, y = r.randrange(24), r.randrange(24)
        c = tuft if k % 3 else dark
        im.putpixel((x, y), c); im.putpixel(((x + 1) % 24, y), c)
    im.save("textures/grass.png")

def bricks():        # 20 x 20 over 3 m (0.15 m a texel): stone blocks 4 x 2 texels, mortar 1
    a, b, m = hexc("#847e87"), hexc("#9badb7"), hexc("#595652")
    im = Image.new("RGBA", (20, 20), m)
    for row in range(0, 20, 3):
        off = 2 if (row // 3) % 2 else 0
        for x in range(20):
            if (x + off) % 5 == 4: continue
            c = b if ((x + off) // 5 + row // 3) % 3 == 0 else a
            for y in (row, row + 1):
                if y < 20: im.putpixel((x, y), c)
    im.save("textures/bricks.png")

def planks():        # 16 x 16 over 2 m (0.125 m a texel): crate boards, dark seams and staggered joints
    a, s = hexc("#8f563b"), hexc("#663931")
    im = Image.new("RGBA", (16, 16), a)
    for y in range(16):
        for x in range(16):
            row = y // 4
            if y % 4 == 3 or (y % 4 < 3 and x == (5 + row * 7) % 16):
                im.putpixel((x, y), s)
    im.save("textures/planks.png")

def bark():          # 16 x 16 over 2.4 m: vertical bark grooves
    a, g, l = hexc("#8f563b"), hexc("#663931"), hexc("#d9a066")
    im = Image.new("RGBA", (16, 16), a)
    r = random.Random(9)
    for x in range(0, 16, 4):
        y0 = r.randrange(16)
        for y in range(16):
            if (y - y0) % 16 < 11: im.putpixel((x, y), g)
    for k in range(5):
        x, y = r.randrange(16), r.randrange(16)
        im.putpixel((x, y), l)
    im.save("textures/bark.png")

def ripples():       # 24 x 24 over 4.8 m: the water's surface, light ripple dashes
    r = random.Random(11)
    base, rip, hi = hexc("#5b6ee1"), hexc("#639bff"), hexc("#5fcde4")
    im = Image.new("RGBA", (24, 24), base)
    for k in range(16):
        x, y = r.randrange(24), r.randrange(24)
        c = hi if k % 4 == 0 else rip
        for dx in range(3):
            im.putpixel(((x + dx) % 24, y), c)
    im.save("textures/ripples.png")

for f in (soil, grass, bricks, planks, bark, ripples):
    f()
print("wrote textures/soil, grass, bricks, planks, bark, ripples")
