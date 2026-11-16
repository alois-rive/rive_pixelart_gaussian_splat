#!/usr/bin/env python3
"""Build the gallery: sign every sample into riv/, then write gallery.rml and gallery_data.as.

  (from examples/)
  python3 gallery/build_gallery.py                 sign what changed, regenerate, verify
  python3 gallery/build_gallery.py --force         re-sign every sample
  python3 gallery/build_gallery.py --no-sign       only regenerate from the .riv files already in riv/

The samples, in grid order: dioramas/rive first, the other dioramas, then games/ (each a folder
with a scene/ Rive project). Each is built with `rive <scene> --publish` (a signed .riv: a
decoded file runs its scripts only when Rive signed them; needs `rive login`) into
riv/<group>-<name>.riv, and the gallery embeds them as blobs. A sample is re-signed only when
a file in its scene/ is newer than its .riv.

Then `rive gallery` previews the gallery; `rive gallery --publish` makes the gallery's own .riv.
"""
import argparse
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
EXAMPLES = os.path.dirname(HERE)
SKILL = os.path.join(EXAMPLES, "..", ".claude", "skills", "pixel-splat-scene")
COLS, TW, TH, GAP, LABEL, MARGIN, TOP = 3, 640, 400, 32, 40, 32, 150
W = MARGIN * 2 + COLS * TW + (COLS - 1) * GAP
H = 1280


def samples():
    out = []
    dio = sorted(d for d in glob.glob(os.path.join(EXAMPLES, "dioramas", "*")) if os.path.isdir(os.path.join(d, "scene")))
    dio.sort(key=lambda d: os.path.basename(d) != "rive")
    games = sorted(d for d in glob.glob(os.path.join(EXAMPLES, "games", "*")) if os.path.isdir(os.path.join(d, "scene")))
    for group, dirs in (("dioramas", dio), ("games", games)):
        for d in dirs:
            name = os.path.basename(d)
            try:
                pal = json.load(open(os.path.join(d, "art", "palette.json"))).get("name", "")
            except (OSError, ValueError):
                pal = ""
            out.append({"group": group, "name": name, "dir": d, "palette": pal,
                        "riv": os.path.join(HERE, "riv", f"{group}-{name}.riv")})
    return out


def newest(path):
    t = 0
    for root, dirs, files in os.walk(path):
        dirs[:] = [x for x in dirs if x != "build"]
        for f in files:
            t = max(t, os.path.getmtime(os.path.join(root, f)))
    return t


def sign(s, force):
    scene = os.path.join(s["dir"], "scene")
    if not os.path.exists(os.path.join(scene, "splats.bin")):
        return "not baked yet (skipped)"
    if not force and os.path.exists(s["riv"]) and os.path.getmtime(s["riv"]) >= newest(scene):
        return "up to date"
    tmp = tempfile.mkdtemp(prefix="gallery-")
    r = subprocess.run(["rive", scene, "--publish", f"--output-dir={tmp}"], capture_output=True, text=True)
    made = glob.glob(os.path.join(tmp, "*.riv"))
    if r.returncode != 0 or len(made) != 1:
        err = [l for l in (r.stdout + r.stderr).splitlines() if "error" in l][:3]
        shutil.rmtree(tmp, ignore_errors=True)
        return "NOT SIGNED (skipped): " + " | ".join(err)
    os.makedirs(os.path.dirname(s["riv"]), exist_ok=True)
    shutil.move(made[0], s["riv"])
    shutil.rmtree(tmp, ignore_errors=True)
    return "signed"


def font_table():
    src = open(os.path.join(SKILL, "assets", "template", "game_api.as")).read()
    m = re.search(r"const FONT: StaticArray<u16> = \[([^\]]*)\];", src)
    return m.group(1)


def as_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write(ss):
    n = len(ss)
    tiles, props, values, blobs = [], [], [], []
    nid = 1000
    for i, s in enumerate(ss):
        a, x, y, o, pz = nid, nid + 1, nid + 2, nid + 3, nid + 4
        nid += 5
        col, row = i % COLS, i // COLS
        tx, ty = MARGIN + col * (TW + GAP), TOP + row * (TH + LABEL + GAP)
        tiles.append(f'''        <NestedArtboard artboardId="0:3" x="{tx}" y="{ty}" name="Tile{i}" id="0:{2000 + i}">
            <DataBindContext sourcePathIds="0:40-0:{a}" propertyKey="197"/>
            <DataBindContext sourcePathIds="0:40-0:{x}" propertyKey="13"/>
            <DataBindContext sourcePathIds="0:40-0:{y}" propertyKey="14"/>
            <DataBindContext sourcePathIds="0:40-0:{o}" propertyKey="18"/>
            <DataBindContext sourcePathIds="0:40-0:{pz}" propertyKey="895"/>
            <DataBindContext sourcePathIds="0:40-0:44" propertyKey="16"/>
            <DataBindContext sourcePathIds="0:40-0:44" propertyKey="17"/>
        </NestedArtboard>''')
        props.append(f'''        <ViewModelPropertyArtboard name="tile{i}" id="0:{a}"/>
        <ViewModelPropertyNumber name="x{i}" id="0:{x}"/>
        <ViewModelPropertyNumber name="y{i}" id="0:{y}"/>
        <ViewModelPropertyNumber name="o{i}" id="0:{o}"/>
        <ViewModelPropertyBoolean name="p{i}" id="0:{pz}"/>''')
        values.append(f'''            <ViewModelInstanceArtboard propertyValue="0:3" viewModelPropertyId="0:{a}"/>
            <ViewModelInstanceNumber propertyValue="{tx}" viewModelPropertyId="0:{x}"/>
            <ViewModelInstanceNumber propertyValue="{ty}" viewModelPropertyId="0:{y}"/>
            <ViewModelInstanceNumber propertyValue="1" viewModelPropertyId="0:{o}"/>
            <ViewModelInstanceBoolean propertyValue="true" viewModelPropertyId="0:{pz}"/>''')
        blobs.append(f'    <BlobAsset file="riv/{os.path.basename(s["riv"])}" name="s{i}" id="0:{3000 + i}"/>')
    rml = f'''<Rive version="1" kind="fragment">
    <!-- GENERATED by build_gallery.py: {n} samples. The tiles' artboards, positions and opacity are
         bound to the Gallery view model; gallery.as fills and scrolls them. -->
    <Artboard defaultStateMachineId="0:7" viewModelId="0:40" width="{W}" height="{H}" styleId="0:4" name="Gallery" id="0:2">
        <LayoutComponentStyle name="Artboard Style" id="0:4"/>
        <Fill name="Bg"><SolidColor colorValue="FF0E0E12" name="C"/></Fill>
        <!-- first declared paints on top: the host (a layout filling the artboard, so it learns the
             window's size and lays the grid out to it) draws the dimming, borders, labels and header -->
        <LayoutComponent width="{W}" height="{H}" styleId="0:11" name="Root" id="0:10">
            <LayoutComponentStyle layoutWidthScaleType="fill" layoutHeightScaleType="fill"
                widthUnitsValue="auto" heightUnitsValue="auto" name="Style" id="0:11"/>
            <ScriptedLayout scriptAssetId="0:80" name="Host" id="0:30">
                <FocusData/>
            </ScriptedLayout>
        </LayoutComponent>
{chr(10).join(tiles)}
        <StateMachine name="SM" id="0:7">
            <StateMachineLayer name="L" id="0:8">
                <AnyState x="0" y="-120"/>
                <ExitState x="300" y="-120"/>
                <EntryState><StateTransition stateToId="0:9"/></EntryState>
                <AnimationState x="150" y="0" animationId="0:6" id="0:9">
                    <FocusActionTarget targetId="0:30"/>
                </AnimationState>
            </StateMachineLayer>
        </StateMachine>
        <LinearAnimation loopValue="loop" duration="60" name="Idle" id="0:6"/>
    </Artboard>
    <!-- what a tile shows until its .riv is decoded -->
    <Artboard isComponent="true" x="{W + 200}" y="0" width="{TW}" height="{TH}" styleId="0:5" name="Loading" id="0:3">
        <LayoutComponentStyle name="Artboard Style" id="0:5"/>
        <Fill name="Bg"><SolidColor colorValue="FF1A1A22" name="C"/></Fill>
    </Artboard>
    <ViewModel defaultInstanceId="0:42" name="Gallery" id="0:40">
        <ViewModelPropertyNumber name="tileScale" id="0:44"/>
{chr(10).join(props)}
        <ViewModelInstance exports="true" name="Default" id="0:42">
            <ViewModelInstanceNumber propertyValue="1" viewModelPropertyId="0:44"/>
{chr(10).join(values)}
        </ViewModelInstance>
    </ViewModel>
    <ScriptAsset file="gallery.as" name="gallery" id="0:80"/>
{chr(10).join(blobs)}
</Rive>
'''
    open(os.path.join(HERE, "gallery.rml"), "w").write(rml)
    data = f'''// GENERATED by build_gallery.py from the samples' folders: do not edit.
export const COUNT: i32 = {n};
export const COLS: i32 = {COLS};
export const TILE_W: f32 = {TW};
export const TILE_H: f32 = {TH};
export const GAP: f32 = {GAP};
export const LABEL: f32 = {LABEL};
export const MARGIN: f32 = {MARGIN};
export const TOP: f32 = {TOP};
export const WIDTH: f32 = {W};
export const HEIGHT: f32 = {H};
export const NAMES: string[] = [{", ".join(as_str(s["name"]) for s in ss)}];
export const GROUPS: string[] = [{", ".join(as_str(s["group"]) for s in ss)}];
export const PALETTES: string[] = [{", ".join(as_str(s["palette"]) for s in ss)}];
export const FONT: StaticArray<u16> = [{font_table()}];
'''
    open(os.path.join(HERE, "gallery_data.as"), "w").write(data)
    yml = os.path.join(HERE, "rive.yaml")
    if not os.path.exists(yml):
        open(yml, "w").write("name: gallery\nscripting: wasm\nlogs:\n  file: build/rive.log\n  problems: build/problems.log\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--no-sign", action="store_true")
    ap.add_argument("--only", action="append", default=[], help="sign only these sample names")
    a = ap.parse_args()
    ss = samples()
    if not a.no_sign:
        for s in ss:
            if a.only and s["name"] not in a.only:
                continue
            print(f"{s['group']}/{s['name']}: {sign(s, a.force)}", flush=True)
    ss = [s for s in ss if os.path.exists(s["riv"])]
    write(ss)
    r = subprocess.run(["rive", HERE, "--verify"], capture_output=True, text=True)
    print((r.stdout + r.stderr).strip().splitlines()[-1] if (r.stdout + r.stderr).strip() else "")
    print(f"gallery: {len(ss)} samples, {W}x{H}")
    return r.returncode


if __name__ == "__main__":
    sys.exit(main())
