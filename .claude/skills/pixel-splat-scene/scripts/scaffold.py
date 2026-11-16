#!/usr/bin/env python3
"""Create a Rive project that runs the pixel-splat renderer.

  scaffold.py scene/ [--palette art/palette.json]
                                a scene: scene.rml (inputs to tune, a BlobAsset), shaders, script; the
                                artboard's background is the palette's `void` colour
  scaffold.py lookdev/ --lookdev [--palette art/palette.json]
                                a turntable bench: no RML, so every .bin dropped in is a blob, and
                                every input comes from `--arg` (golden.py views drives it)

Refuses to overwrite an existing renderer file; pass --force to refresh the shaders, the
script and game_api.as from the skill (the scene's own scene.rml and game.as are never replaced).
"""
import argparse
import os
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(HERE, "..", "assets", "template")
CODE = ["splat.wgsl", "resolve.wgsl", "splat_scene.as", "game_api.as"]
OWN = ["game.as"]  # the project's own: copied when missing, never refreshed


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("dir")
    ap.add_argument("--lookdev", action="store_true")
    ap.add_argument("--name")
    ap.add_argument("--size", default="640x400", help="artboard size (lookdev)")
    ap.add_argument("--force", action="store_true", help="refresh the renderer files")
    ap.add_argument("--palette", help="a palette file: the artboard's background takes its `void` role")
    a = ap.parse_args()
    os.makedirs(a.dir, exist_ok=True)
    yml0 = os.path.join(a.dir, "rive.yaml")
    if not a.lookdev and os.path.exists(yml0) and "main: splat_scene" in open(yml0).read():
        a.lookdev = True  # an existing bench (no RML): never give it a scene.rml
    name = a.name or os.path.basename(os.path.abspath(a.dir)).replace("-", "_")
    for f in CODE:
        dst = os.path.join(a.dir, f)
        if os.path.exists(dst) and not a.force:
            raise SystemExit(f"{dst} exists (pass --force to refresh the renderer)")
        shutil.copyfile(os.path.join(TEMPLATE, f), dst)
    for f in OWN:
        dst = os.path.join(a.dir, f)
        if not os.path.exists(dst):
            shutil.copyfile(os.path.join(TEMPLATE, f), dst)
    yaml = os.path.join(a.dir, "rive.yaml")
    if not os.path.exists(yaml):
        w, h = a.size.lower().split("x")
        with open(yaml, "w") as f:
            f.write(f"name: {name}\nscripting: wasm\n")
            if a.lookdev:
                bg = "#181425"
                if a.palette:
                    import json
                    bg = json.load(open(a.palette)).get("roles", {}).get("void", bg)
                f.write(f"main: splat_scene\nartboard:\n  width: {w}\n  height: {h}\n  background: \"{bg}\"\n")
            f.write("logs:\n  file: build/rive.log\n  problems: build/problems.log\n")
    rml = os.path.join(a.dir, "scene.rml")
    void = None
    if a.palette:
        import json
        doc = json.load(open(a.palette))
        void = doc.get("roles", {}).get("void")
    if not a.lookdev and not os.path.exists(rml):
        text = open(os.path.join(TEMPLATE, "scene.rml")).read()
        if void:
            text = text.replace('colorValue="FF181425"', 'colorValue="FF%s"' % void.lstrip("#").upper())
        open(rml, "w").write(text)
    gi = os.path.join(a.dir, ".gitignore")
    if not os.path.exists(gi):
        with open(gi, "w") as f:
            f.write("build/\n")
    print(f"{a.dir}: {'lookdev bench' if a.lookdev else 'scene'} ready; bake a .bin into it, then "
          f"`rive {a.dir} --verify` and `rive {a.dir} --screenshot --advance=2`")
    return 0


if __name__ == "__main__":
    sys.exit(main())
