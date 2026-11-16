# logs.png: the cabin's log courses, 2 x 12 texels for 1.25 m of wall (cube-projected): four logs,
# each two texels of #c69fa5 over one of #8b6d9c (the gap), wood ramp. Run from this directory.
from PIL import Image
a, b = (0xc6, 0x9f, 0xa5, 255), (0x8b, 0x6d, 0x9c, 255)
im = Image.new("RGBA", (2, 12))
for y in range(12):
    for x in range(2):
        im.putpixel((x, y), b if y % 3 == 2 else a)
im.save("textures/logs.png")
