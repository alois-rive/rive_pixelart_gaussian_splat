# ground_48.png: the clearing's top, 48 texels over 10 m (0.21 m a texel, 1.5 splats), ground ramp:
# #8b6d9c earth, blobs of fallen leaves #c69fa5, a few dark hollows #494d7e, and a winding path
# #f2d3ab from the cabin door (hedra (0.3, -0.3)) to the front edge (-y). Run from this directory.
import math, random
from PIL import Image

def hexc(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)

N, W = 48, 10.0
base, litter, hollow, path = hexc("#8b6d9c"), hexc("#c69fa5"), hexc("#494d7e"), hexc("#f2d3ab")
im = Image.new("RGBA", (N, N), base)
rnd = random.Random(8)

def to_px(x, y):
    # project-from-view top with --scale-to-bounds: u = x across, v = y up; image rows run down
    return (x + W / 2) / W * N, (W / 2 - y) / W * N

for col, count, rmin, rmax in ((litter, 26, 1.2, 2.6), (hollow, 6, 1.0, 1.6)):
    for _ in range(count):
        cx, cy, r = rnd.uniform(0, N), rnd.uniform(0, N), rnd.uniform(rmin, rmax)
        for y in range(N):
            for x in range(N):
                if ((x + 0.5 - cx) / r) ** 2 + ((y + 0.5 - cy) / (r * 0.7)) ** 2 <= 1:
                    im.putpixel((x, y), col)
# the path: a centre line from the door to the edge, about 0.9 m wide, wobbling
pts = []
for i in range(60):
    t = i / 59
    y = -0.3 - t * 4.9
    x = 0.3 - 0.9 * t + 0.45 * math.sin(t * 5.0)
    pts.append(to_px(x, y))
for y in range(N):
    for x in range(N):
        d = min(math.hypot(x + 0.5 - px, y + 0.5 - py) for px, py in pts)
        if d <= 2.2:
            im.putpixel((x, y), path)
im.save("textures/ground_48.png")
