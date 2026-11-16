"""Shared helpers for the pixel-splat-scene scripts: palettes, ramps, colour distance.

Imported by the other scripts; needs NumPy (and Pillow for the image ones).
"""
import json
import os

import numpy as np

MAX_COLORS = 64     # the renderer's palette table
MAX_RAMPS = 32      # the renderer's ramp table
MAX_STEPS = 8       # steps a ramp may have


def hex_to_rgb(h):
    h = h.strip().lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


def rgb_to_hex(c):
    return "#%02x%02x%02x" % tuple(int(v) for v in c[:3])


def srgb_to_linear(c):
    c = np.asarray(c, dtype=np.float64) / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def oklab(rgb):
    """sRGB 0..255 (..., 3) to OKLab (..., 3). https://bottosson.github.io/posts/oklab/"""
    lin = srgb_to_linear(rgb)
    m1 = np.array([[0.4122214708, 0.5363325363, 0.0514459929],
                   [0.2119034982, 0.6806995451, 0.1073969566],
                   [0.0883024619, 0.2817188376, 0.6299787005]])
    m2 = np.array([[0.2104542553, 0.7936177850, -0.0040720468],
                   [1.9779984951, -2.4285922050, 0.4505937099],
                   [0.0259040371, 0.7827717662, -0.8086757660]])
    lms = np.cbrt(np.einsum("...j,ij->...i", lin, m1))
    return np.einsum("...j,ij->...i", lms, m2)


def luma(rgb):
    rgb = np.asarray(rgb, dtype=np.float64)
    return (0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]) / 255.0


class Palette:
    """A palette file: colours, named ramps (dark to light), roles."""

    def __init__(self, path):
        with open(path) as f:
            doc = json.load(f)
        self.path = path
        self.name = doc.get("name", os.path.basename(path))
        self.hex = [h.lower() for h in doc["colors"]]
        if len(self.hex) > MAX_COLORS:
            raise SystemExit(f"{path}: {len(self.hex)} colours, the renderer takes {MAX_COLORS}")
        self.rgb = np.array([hex_to_rgb(h) for h in self.hex], dtype=np.float64)
        self.lab = oklab(self.rgb)
        self.ramp_names = list(doc.get("ramps", {}).keys())
        self.ramps = []
        for name in self.ramp_names:
            steps = [self.index_of(h, f"ramp {name}") for h in doc["ramps"][name]]
            if not 1 <= len(steps) <= MAX_STEPS:
                raise SystemExit(f"{path}: ramp {name} has {len(steps)} steps (1..{MAX_STEPS})")
            self.ramps.append(steps)
        if len(self.ramps) > MAX_RAMPS:
            raise SystemExit(f"{path}: {len(self.ramps)} ramps, the renderer takes {MAX_RAMPS}")
        self.roles = {k: self.index_of(v, f"role {k}") for k, v in doc.get("roles", {}).items()}

    def index_of(self, h, what="colour"):
        h = h.lower() if h.startswith("#") else "#" + h.lower()
        if h not in self.hex:
            raise SystemExit(f"{self.path}: {what} {h} is not in the palette")
        return self.hex.index(h)

    def ramp_index(self, name):
        if name not in self.ramp_names:
            raise SystemExit(f"{self.path}: no ramp named {name!r} (have {', '.join(self.ramp_names)})")
        return self.ramp_names.index(name)

    def nearest(self, rgb, among=None):
        """Nearest palette index (OKLab distance) for each colour of rgb (..., 3)."""
        lab = oklab(np.asarray(rgb, dtype=np.float64))
        cand = np.arange(len(self.hex)) if among is None else np.asarray(among)
        d = ((lab[..., None, :] - self.lab[cand]) ** 2).sum(-1)
        k = d.argmin(-1)
        return cand[k], np.sqrt(d.min(-1))

    def ramp_of(self, idx):
        """First (ramp, step) holding palette index idx, or None."""
        for r, steps in enumerate(self.ramps):
            if idx in steps:
                return r, steps.index(idx)
        return None
