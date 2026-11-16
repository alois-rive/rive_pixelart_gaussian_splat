"""The beam's stipple: 128 x 8, light (#f0f6f0) near the lamp (the texture's middle), thinning towards
both tips into transparent texels, ordered (4 x 4 Bayer on the texel grid, one texel ~ one splat). The
material is alpha-masked, so a transparent texel makes no splat at all: the tips dissolve into the night
(and over the horizon glow) instead of ending in a hard edge. Run: python3 models/env/beam_texture.py (writes beam_stipple.png beside it)."""
import os
from PIL import Image

D, L = (0xF0, 0xF6, 0xF0, 0), (0xF0, 0xF6, 0xF0, 255)
B = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
W, H = 128, 8
im = Image.new("RGBA", (W, H))
for y in range(H):
    for x in range(W):
        d = abs((x + 0.5) / W - 0.5) * 2          # 0 at the lamp, 1 at a tip
        keep = min(1.0, max(0.0, (1.0 - d) / 0.7))  # solid for the first 30 %, then thinning out
        im.putpixel((x, y), L if (B[(x % 4) + (y % 4) * 4] + 0.5) / 16 < keep else D)
im.save(os.path.join(os.path.dirname(os.path.abspath(__file__)), "beam_stipple.png"))
