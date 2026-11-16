"""The barn's wall textures, palette-exact (Kirokaze Gameboy), 0.1 m a texel (the scene's texel).
Doors, windows and corner boards are painted, not modelled: a board 3 cm proud of a wall fights it at
splat size (one depth a disc) and smeared the door into noise. Every shape is at least 2 texels.
Run: python3 textures/make_textures.py (writes the PNGs beside it). Row 0 of each sketch is the TOP."""
import os
from PIL import Image

C = {"0": (0x33, 0x2C, 0x50), "1": (0x46, 0x87, 0x8F), "2": (0x94, 0xE3, 0x44), "3": (0xE2, 0xF3, 0xE4)}


def wall(w, h, rects):
    """w x h texels of c1 with 2-texel c3 corner strips; rects: (x0, y0_from_bottom, x1, y1, colour), inclusive."""
    px = [["1"] * w for _ in range(h)]
    for y in range(h):
        for x in (0, 1, w - 2, w - 1):
            px[y][x] = "3"
    for x0, y0, x1, y1, c in rects:
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                px[h - 1 - y][x] = c
    return px


def save(name, px):
    im = Image.new("RGB", (len(px[0]), len(px)))
    for y, row in enumerate(px):
        for x, c in enumerate(row):
            im.putpixel((x, y), C[c])
    im.save(os.path.join(os.path.dirname(os.path.abspath(__file__)), name))


# front wall, 3.0 x 1.8 m: a light door frame 2.0 x 1.7 (2-texel border), two dark leaves, a light stile
save("wall_front.png", wall(30, 18, [(5, 0, 24, 16, "3"), (7, 0, 22, 14, "0"), (14, 0, 15, 14, "3")]))
# windows and the loft door are 0.8 m (8 texels: a 2-texel frame round a 4 x 4 pane), not the sheet's
# 0.62: a 1-texel frame samples as a dotted ring
# back wall: a window centred 1.3 m up
save("wall_back.png", wall(30, 18, [(11, 9, 18, 16, "3"), (13, 11, 16, 14, "0")]))
# right wall, 3.55 x 1.8 m: a window centred 1.1 m up
save("wall_right.png", wall(36, 18, [(14, 7, 21, 14, "3"), (16, 9, 19, 12, "0")]))
# left wall: corner boards only
save("wall_left.png", wall(36, 18, []))
# front gable, 3.0 x 1.04 m (a triangle in a 30 x 11 box, no corner strips): the hay-loft door
g = [["1"] * 30 for _ in range(11)]
for y in range(0, 8):
    for x in range(11, 19):
        g[10 - y][x] = "0" if (2 <= y <= 5 and 13 <= x <= 16) else "3"
save("gable_front.png", g)
