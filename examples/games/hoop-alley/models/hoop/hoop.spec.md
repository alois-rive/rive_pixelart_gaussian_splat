# Asset: hoop (hero prop, the alley's wall-mounted hoop)
Concept: ../../art/hoop/sheet.v1.png (DinoKnight 16 colours; `reviewed: false`), refs cut to
../../art/hoop/refs/. Up Z, the rim towards -Y (the shooter); origin at the rim's centre. 1.8 x 1.76 x 1.44 m.
Everything is written by `make_hoop.py` (p1_blockout.txt, p2_form.txt, net.txt and the three textures).

Scale: the board's width, 506 px in the front panel = 1.8 m (281 px a metre). The right panel is drawn at
285 px a metre, the top panel at 257: each view's parts are measured off its own panel.

## Parts (metres, hedra frame)
| Part | Size | Position | Material (ramp, step) |
|---|---|---|---|
| Board | 1.8 x 0.11 x 1.13 | x +-0.9, y 0.43..0.54, z -0.22..0.91 | Board (paint, #f1f1ea); front and back faces painted (textures/board_front.png 26 x 16: a navy #304271 border, an orange #ea7730 open square 0.76 x 0.51 m over the rim; board_back.png: the border) |
| Rim | torus R 0.335, tube 0.045 (outer 0.38), 12 x 4 segments | centre (0, 0, 0) | Rim (rim, #cd3d3d) |
| Clip | 0.2 x 0.13 x 0.13 | from the rim's back to the board, z -0.04..0.09 | Rim |
| Arms | four, 0.1 x 0.69 x 0.1 | x +-0.40, z 0.03 / 0.46, y 0.54..1.23 | Steel (metal, #535867) |
| Wall plate | 1.06 x 0.15 x 0.72 | y 1.23..1.38, z -0.10..0.62 | Steel |
| Net | an open frustum r 0.33 -> 0.215, z -0.045..-0.53, 12 sides, three bands | | Net (metal: textures/net.png 24 x 6, grey #95928f with #535867 chain diamonds) |

## Assumptions
- The sheet draws the net as a solid surface (asked for: a see-through chain net would close up as splats);
  the model is an open frustum, two-sided in the scene.
- Four arms: the right panel shows an upper and a lower arm, the top panel a left and a right one, the back
  panel four corner blocks on the plate. Their x (+-0.40) splits the top panel (+-0.37) and the back panel
  (+-0.45); their heights and the plate's are the right panel's.
- The depth (rim front to plate back) is the right panel's 1.76 m; the top panel draws it 1.68 m.
- In the scene the hoop is three game bones' worth of parts: `hoop_body.glb` (board, rim, clip, arms,
  plate: bone `hoop`, pivot the rim's centre at y 3.05) and `net0..2.glb` (`net.txt`: the same bands, each
  built with its hinge at its own origin). The arms' ends (inside the board and the plate) are deleted.
- 236 triangles.

## Gate record (generated-sheet tier, chosen before the build)
- p1 blockout and p2 form (hedra views): **IoU front 0.992, right 0.859, back 0.994, top 0.666; aspect
  drift 0.027 / 0.008 / 0.013 / 0.051** (`--min-iou 0.75`, drift <= 0.08). Shots in `shots/p1`, `shots/p2`.
- p4 splats, albedo, bench at the scene's spacing (0.045, rim and net 0.035), rendered at exact angles
  (`--arg pitchMin=0 --arg pitchMax=90`; the default 5-degree side views shift the thin arms against the
  rim): **IoU 0.961 / 0.745 / 0.954 / 0.599, aspect drift 0.016 / 0.029 / 0.002 / 0.034, colour drift
  0.07 / 0.11 / 0.09 / 0.14** (`--min-iou 0.7`, colour <= 0.25). Shots in `shots/p4_albedo`.
- **Waiver, top view** (IoU 0.666 mesh, 0.599 splats): the sheet contradicts itself. Its front and side
  panels draw a solid net hanging inside the rim, but its top panel leaves the ring's hole open (background
  through it), and it draws the hoop 5 % shallower than the right panel (the board bar sits at 0.45 of the
  top panel's height, the model's at 0.48). Gated without the net, the mesh's top view reaches 0.747; the
  rest is the bar's position. Front, right and back lead; every other view and measure passes.
- Goldens: `goldens/hoop` (framed) and `goldens/hoop@scene` (texel 0.04, 160 px), lit as the scene
  (sun -30 / 45, keyLight 0.4, highlight 0.88, shadeSteps 1, edgeDepth 0.8).
