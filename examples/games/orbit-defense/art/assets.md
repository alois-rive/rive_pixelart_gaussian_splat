# Assets: Orbit Defense (Berry Nebula)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 HUD pixels; orthographic, `orthoHeight` 8 m ->
texel 0.06 m. Splat spacing 0.09 m (1.5 texels) for the world, 0.07 for the small game pieces and the hero,
0.05-0.06 for tiny glowing details. Palette: Berry Nebula (`palette.json`, 8 colours, one long ramp from
night purple to cyan) split into 11 ramps; the glows (bolts, bursts, windows, muzzle, stars, nebula, the
meteors' hot faces and tails) are `unlit`.

The play plane is the vertical plane z = 0 (glTF), seen face-on (yaw 0, pitch 0). hedra models are
built up Z, front -Y; things on the planet's rim are placed by the game at an angle with a roll.

| Asset | Class | Size (m) | Instances / bones | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| satellite | hero (the player) | 1.5 x 0.46 x 0.92 (x1.25 in the scene) | 1 bone `sat` | metal, panel, glow (muzzle) | `satellite/sheet.v1.png` | 252 | game: orbits r 2.75, turns to the pointer, recoil squash, reels when struck |
| planet | terrain | r 1.4 sphere (back half deleted) | static | rock (#4f1446), sea (#6e5181), rock spires | this list | 104 | |
| sky | backdrop | 15 x 9 field, 7-12 m behind | static | star (unlit), nebula (unlit), rock (moon) | this list | 884 | |
| hut | prop (a life) | 0.44 x 0.36 x 0.62 (x1.4) | 2 bones `hut0..1` | wall (#6cb9c9), roof (#6e5181), glow (window) | this list | 44 | game: pop-in, wobble |
| dome | prop (a life) | 0.54 x 0.54 x 0.65 (x1.4) | 2 bones `dome0..1` | wall, metal, glow (door, beacon) | this list | 88 | game: pop-in, wobble |
| rubble | prop | 0.45 x 0.3 x 0.25 (x1.4) | 4 bones | roof, fire (ember, unlit) | this list | 48 | game: where a house was |
| meteor | enemy | r 0.3 icosahedron | 6 bones | meteor (#6e5181), fire (hot faces, unlit) | this list | 20 | game: flies, tumbles |
| boulder | enemy (splits in two) | r 0.46 | 3 bones | meteor, fire | this list | 20 | game |
| trail | effect | 0.52 x 1.4 cone pair | 9 bones (one per meteor slot) | fire (unlit) | this list | 40 | game: follows its meteor, flickers at 12 fps |
| bolt | effect | 0.2 x 0.55 | 6 bones | glow (unlit) | this list | 40 | game |
| burst | effect | 1.4 across, 8 spikes | 5 bones | glow (unlit) | this list | 68 | game: pop (scaled down only) |
| debris | effect | r 0.09 | 12 bones | meteor | this list | 20 | game |
| puff | effect | 0.85 x 0.5 (x1.3) | 2 bones | rock | this list | 60 | game |
| flash | effect | 0.5 star | 1 bone | glow (unlit) | this list | 24 | game: two frames after a shot |

Bones: 1 + 4 + 4 + 6 + 3 + 9 + 6 + 5 + 12 + 2 + 1 = 53 of 63 (all game bones, no baked tracks).

Every pool piece is baked at full size and only scaled down or squashed a little by the game: a splat's
size does not follow its bone's scale, so a piece scaled up past ~1.3 opens holes.
