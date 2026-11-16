# Palette-exact textures for the outpost, drawn by script (run from this directory):
#   regolith_48.png  the asteroid's top: rock ramp, #1e3a29 with blobs of #305d42 and #112318
#   pad_32.png       the landing pad's top: pad ramp, #305d42 with a ring and an H in #89a257
import random
from PIL import Image

def hexc(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)

base, light, dark = hexc("#1e3a29"), hexc("#305d42"), hexc("#112318")
N = 48
im = Image.new("RGBA", (N, N), base)
rnd = random.Random(4)
for col, count in ((light, 9), (dark, 7)):
    for _ in range(count):
        cx, cy, r = rnd.uniform(0, N), rnd.uniform(0, N), rnd.uniform(2.0, 3.8)
        for y in range(N):
            for x in range(N):
                # wrap so the texture tiles
                dx = min(abs(x + 0.5 - cx), N - abs(x + 0.5 - cx))
                dy = min(abs(y + 0.5 - cy), N - abs(y + 0.5 - cy))
                if (dx / r) ** 2 + (dy / (r * 0.75)) ** 2 <= 1:
                    im.putpixel((x, y), col)
im.save("textures/regolith_48.png")

pad, mark = hexc("#305d42"), hexc("#89a257")
N = 32
im = Image.new("RGBA", (N, N), pad)
c = (N - 1) / 2
for y in range(N):
    for x in range(N):
        d = ((x - c) ** 2 + (y - c) ** 2) ** 0.5
        if 11.5 <= d <= 14.0:
            im.putpixel((x, y), mark)
        # an H, 3 texels thick
        if (9 <= x <= 11 or 20 <= x <= 22) and 9 <= y <= 22:
            im.putpixel((x, y), mark)
        if 9 <= x <= 22 and 15 <= y <= 16:
            im.putpixel((x, y), mark)
im.save("textures/pad_32.png")
