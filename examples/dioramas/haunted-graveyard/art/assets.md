# Assets: a haunted hilltop graveyard (Hollow, 4 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; orthographic, `orthoHeight` 9 m ->
texel 0.068 m. Splat spacing 0.15 m (2.2 texels: big, painterly splats); thin parts get their own spacing
(never under the texel, except the ghost's face at 0.05 m: 2 splats across its small eyes and mouth). Palette: Hollow (`palette.json`, 4 colours: #0f0f1b #565a75 #c6b7be #fafbf6).

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Animation |
|---|---|---|---|---|---|---|---|
| hill | terrain | 11 x 11 x 3.2 | 1 | earth (ground texture: path, dark patches), earth (rock) | this list | 88 | |
| crypt | hero prop | 2.85 x 3.1 x 3.7 | 1 | stone, dark (roof, door), glow (windows, unlit) | `crypt/sheet.v1.png` | 230 | |
| headstone | prop | 0.6 x 0.26 x 1.0 | 6 | stone (#c6b7be) | this list | 40 | |
| cross | prop | 0.72 x 0.4 x 1.3 | 4 | stone | this list | 36 | |
| tree | foliage | 2 x 1 x 2.8 | 1 (1.15) | earth, spacing 0.1 | this list | 64 | |
| fence | prop | 3.1 x 0.26 x 1.37 | 3 | earth (kerb), dark (iron, spacing 0.07) | this list | 144 | |
| lantern | light prop | 0.7 x 0.4 x 1.7 | 1 | dark, glow (unlit) | this list | 60 | |
| ghost | character | 1.0 x 0.7 x 1.2 | 1 | glow (unlit sheet, spacing 0.1), dark (face: eyes 0.1 x 0.15, mouth 0.12 x 0.1, spacing 0.05) | this list | 152 | rigid: orbit r 2 m / 10 s (an empty parent, linear) + bob 0.18 m and rock 6 degrees / 2.5 s, 10 fps |
| moon | effect | 1.6 disc | 1 | glow (unlit, no shadow) | this list | 60 | |

Bones: 1 (the ghost). Blob: 23 800 splats.
With four colours there is one ramp in all: materials differ by the step they are painted on (stones on
#c6b7be, walls and ground on #565a75, roofs and iron on #0f0f1b) and lights by being unlit.
