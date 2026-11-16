# Assets: Firefly Jar (retrocal-8)

Art grid: 640 x 400 artboard, `pixelSize` 2 -> 320 x 200 art pixels; an orthographic orbit camera
(yaw 0, pitch 42) aimed at the world origin (the clearing's centre), `orthoHeight` 8.08 m -> texel
0.04 m. Splat spacing 0.07 m; the meadow 0.09, crowns 0.1, bushes 0.08; the jar 0.05 (at scale 1.5),
insects, the net, flowers and tufts 0.035-0.05. Palette: retrocal-8 (`palette.json`, 8 colours).
Night: plum shadows, dark teal grass, crowns as dark silhouettes lit teal on top by a high moon (a high
key light, 0.62, keeps most faces a step down), and the light that matters comes from `unlit` cream
fireflies.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| jar | hero prop | 0.52 x 0.5 x 0.84 (x 1.5 in the scene) | 1, on the stump | glass (teal glass, cream string), cloth (red cap), wood (wire, label) | `jar/sheet.v1.png` | 344 | (static; the caught fireflies glow on it) |
| net | the player's tool | 0.93 across, 1.5 m handle | 1 game bone | wood (hoop, handle), glass (mesh bag, two-sided) | this list | 132 | game: chases the pointer on a spring at 1 m, leans into the sweep (pitch, roll), squashes on a catch, shakes when a moth knocks it |
| firefly | effect | 0.2 | pool of 16 + 12 in the jar (x 0.75) | glow (unlit) | this list | 40 | game: wander loops, rise out of the grass, a stepped dim blink, shy of a close net; caught: an arc into the jar; in the jar: a pop and a twinkle; released at a new run: they fly off |
| moth | enemy | 0.6 wingspan (x 1.4) | pool of 5 | moth (plum body, mauve wings two-sided, red spots) | this list | 76 | game: drawn to the net, erratic, wings flap at 12 fps (x scale) |
| spark | effect | 0.5 twinkle | pool of 4 | glow (unlit) | this list | 36 | game: a stepped pop where a firefly is caught |
| meadow | terrain | 15 x 14 plane | 1 | grass | this list | 2 | |
| pond | prop | 3.2 x 2.2 | 1 | grass (water, pads), wood (stones), glow (the moon's reflection, unlit) | this list | 344 | |
| stump | prop | 0.9 x 0.9 x 0.5 | 1 | wood | this list | 80 | |
| tree | foliage | 3 x 2.6 x 4.2 | 9 | wood (trunk), leaf (plum, plum, teal, light teal: silhouettes) | this list | 100 | |
| bush | foliage | 1.6 x 1.2 x 0.9 | 5 | leaf | this list | 60 | |
| tuft, flower | foliage | 0.6; 0.5 | 34; 16 | grass; leaf, cloth, wood | this list | 20; 48 | |

Bones: net 1 + fireflies 16 + jar fireflies 12 + moths 5 + sparks 4 = 38 of 63. Splats: 80 805.

Layout (glTF metres, Y up): the clearing at y 0; the stump at (-4, 0, 2), the jar on it (its mouth at
y 1.45); the pond at (3.3, 0, -1.6); trees in a ring 4-7 m out; the net flies at y 1.0 within x
-6..6, z -3.6..4.8; fireflies at y 0.1-1.2; moths at 1.0-1.5. A catch is decided on screen (the net's
hoop and the firefly within 10 HUD pixels), a moth's touch within 14.
