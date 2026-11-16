# Assets: Penguin Slide (Mist GB)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (213 x 133 visible HUD pixels);
orthographic, yaw 0, pitch 12, `orthoHeight` 4.352 m -> texel 0.032 m exactly (the game's 12 m origin
wrap and 1.6 m camera lead are whole texels). Splat spacing 0.05 m (1.56 texels); the penguin 0.04 m
at bake scale 1.25 (its flippers and beak 0.025, its eyes 0.02); the sea 0.09, the backdrop 0.07-0.08.
Palette: Mist GB (`palette.json`, 4 colours: dark brown, teal, mint, pale), 7 ramps sharing them.

| Asset | Class | Size (m) | Instances (game bones) | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| penguin | hero / character | 0.53 x 0.81 x 0.35 (x1.25 in the scene) | 1 `penguin` | feather (back, flippers, eyes), belly (belly band, face), glint (beak, feet), water (scarf) | `penguin/sheet.v2.png` | 314 | game: slide wobble, anticipation squash, take-off stretch, nose up then down in the air, landing squash, tumble on a bonk, dive on a splash |
| floe3 / floe5 / floe8 | terrain (level pieces) | 3.06, 5.06, 8.06 x 1.48 x 0.52 | 3 + 3 + 3 `floeS0-2`, `floeM0-2`, `floeL0-2` | snow (cap, drifts), ice (front, ends) | this list | 80-116 | game: recycled ahead of the penguin, the gaps between them are the holes |
| seal | prop / obstacle | 0.68 x 1.45 x 0.52 | 3 `seal0-2` | seal (body teal, muzzle mint, nose dark) | this list | 194 | game: breathing, looks up as the penguin comes, a startled hop on a bonk |
| fish | pickup | 0.1 x 0.39 x 0.17 | 4 `fish0-3` | glint | this list | 42 | game: spins and bobs over holes and seals, pops when caught |
| puff | effect | 0.34 x 0.2 x 0.24 | 5 `puff0-4` | snow (nocast) | this list | 60 | game: snow spray behind the slide, a burst on landing |
| splash | effect | 0.84 x 0.8 x 0.75 | 1 `splash` | snow (nocast) | this list | 100 | game: a crown that pops up and sinks where the penguin falls in |
| chunk | prop | 0.9 x 0.55 x 0.3 | 5 `chunk0-4` | ice, snow | this list | 16 | game: floating in front of and behind the run, a stepped bob |
| waves | effect | 8 x 10 strip, crests 0.3-0.5 long | 2 `waves0-1` | water (mint step, nocast) | this list | 272 | game: two strips tile the sea, still in the world |
| water | terrain | 9 x 15 | 1 `sea` | water (teal) | this list | 2 | game: travels with the snapped camera (uniform, so it reads still) |
| berg | backdrop | 2.4 x 1.7 x 1.46 (x0.32-0.55) | 4 `berg0-3` | ice, snow | this list | 26 | game: parallax at 35 % of the camera, snapped to texels |
| ridge | backdrop | 17.3 x 0.83 x 1.1 (y x0.42) | 2 `ridge0-1` | snow (rock mint, caps pale) | this list | 112 | game: parallax at 12 %, two copies tile |

Bones: 37 game bones of 63 (no baked tracks). Splats: 72 697 (the floe pools are most of them).

Ramps (small-palette rules: shared steps, no ramp reaches dark brown where a shadow would smear):

| Ramp | Steps (dark to light) | Painted on | Used by |
|---|---|---|---|
| snow | teal, mint, pale | pale (2) | snow caps, drifts, puffs, splash; the ridge (mint) |
| ice | teal, mint, pale | mint (1) | floe fronts and ends, chunks, bergs |
| water | teal, mint | teal (0) | the sea (no dark step: floe shadows on it stayed as dark smudges), wave crests (mint), the scarf |
| feather | dark, teal | dark (0) | the penguin's back, head, flippers, eyes |
| belly | teal, mint, pale | pale (2) | the penguin's belly band and face |
| seal | dark, teal, mint, pale | teal (1) | the seal; its nose on dark |
| glint | mint, pale | mint / pale | beak, feet, fish |

Layout (glTF metres, Y up, +Z towards the camera): the run's top at y 0 along X at z 0, the sea at
y -0.3, wave crests and chunks in front (z 1.3 to 6) and behind (z -1.2 to -5), bergs at z -5.6 to
-7.2, the ridge at z -8.5. Every piece is a game bone placed each frame from the course (game.as).

Hidden faces are deleted (floe bodies under the caps, backs and bottoms, the undersides of drifts,
bergs, chunks and wave crests): `hedra inspect check` reports their open boundaries as non-manifold
edges, harmless for splats.
