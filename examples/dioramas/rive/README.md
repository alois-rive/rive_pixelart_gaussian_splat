# Example: the Rive opener (the Rive brand palette)

The RIVE wordmark as 3D splat letters on a small plinth. The letters themselves change, through
the renderer's shader FX cycle: they cascade in with the brand's flicker, a Portal Prism band
sweeps through them, they glitch, an amber scanline runs down them, and they dissolve before the
next cascade. Then the pixel resolve (vote, ink, palette) applies on top of every effect. It
closes the showcase video (`record_tour.py`, see the root README).

Built with the `pixel-splat-scene` skill (`../../../.claude/skills/pixel-splat-scene`) and the
`rive-branding` skill's guidelines and kit: rive 1.9.2.

```
art/palette.json                the brand palette: greys, Rive Amber, Portal Prism (12 colours)
art/wordmark.paths.json         the kit's Wordmark path data (cached by make_wordmark.py)
art/wordmark_ref/               a Rive project drawing the kit's Wordmark shapes: the reference
models/logo/make_wordmark.py    the letters extruded (shrunk against the splats' spread) + the plinth
models/logo/gate_wordmark.py    the gate: the letters through the splat renderer vs the kit's render
scene.bake.json                 the composition: the letters flagged `fx`, baked at 0.04 m
scene/                          the Rive project: FX inputs fxPrismRamp 3, fxAccentRamp 5, fxCycle 12
goldens/scene/                  five frames across the FX cycle
```

Rebuild and check (from this directory, `K=../../../.claude/skills/pixel-splat-scene`):

```sh
python3 models/logo/make_wordmark.py -o models/logo/wordmark.glb
python3 $K/scripts/splat_bake.py scene.bake.json
rive scene --verify && rive scene                      # the live preview: drag to orbit, wheel to zoom

# the letters against the kit (IoU 0.83, aspect drift 0.020)
rive art/wordmark_ref --screenshot=$PWD/art/wordmark_ref/wordmark.png --advance=2 --viewport=1840x400 --fit=contain
python3 models/logo/make_wordmark.py -o lookdev/letters.glb --plinth 0
python3 $K/scripts/splat_bake.py lookdev/letters.glb -p art/palette.json -o lookdev/letters.bin --spacing 0.04 --ramp Mark=mark
rive lookdev --screenshot=$PWD/front.png --advance=2 --viewport=1840x480 --arg blobName=letters --arg yaw=0 --arg pitch=0 --arg pixelSize=2 --arg shadows=0 --arg maskSky=1
python3 models/logo/gate_wordmark.py front.png art/wordmark_ref/wordmark.png

for n in 60 200 330 480 640; do rive scene --screenshot=$PWD/shots_scene/frame_$(printf %03d $n).png --advance=$n; done
python3 $K/scripts/golden.py check --shots shots_scene --goldens goldens/scene
python3 $K/scripts/palette.py frame shots_scene/frame_200.png -p art/palette.json --pixel 3
```
