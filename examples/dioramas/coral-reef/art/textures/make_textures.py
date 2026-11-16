# Palette-exact textures for the reef, drawn by script (regular patterns are exact this way).
# sand_64.png: aqua sand (#00b9be) with wavy pale ripple crests (#9ff4e5), two texels thick, 8 apart, over 64 texels (0.22 m a texel on the 14 m seabed).
# Run from the example's directory: /usr/bin/python3 art/textures/make_textures.py
import math, os
from PIL import Image
here = os.path.dirname(os.path.abspath(__file__))
pale, mid = (0x9f, 0xf4, 0xe5, 255), (0x00, 0xb9, 0xbe, 255)
N = 64
im = Image.new("RGBA", (N, N), mid)
for x in range(N):
    off = round(1.5 * math.sin(2 * math.pi * x / N * 2))
    for y0 in range(0, N, 8):
        for t in (0, 1):
            im.putpixel((x, (y0 + off + t) % N), pale)
im.save(os.path.join(here, "sand_64.png"))
print("wrote sand_64.png")
