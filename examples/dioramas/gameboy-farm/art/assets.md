# Assets: a Game Boy farm (Kirokaze Gameboy, 4 colours)

Art grid: 640 x 400 artboard, `pixelSize` 4 -> 160 x 100 art pixels (a Game Boy is 160 x 144);
`orthoHeight` 10 m -> texel 0.1 m. Splat spacing 0.12 m (1.2 texels: crisp, small splats).
Palette: Kirokaze Gameboy (`palette.json`): `#332c50 #46878f #94e344 #e2f3e4`. With four colours every
ramp is a slice of the same four: grass `0-1-2-3` (painted on 2), barn `0-1-2-3` (textures),
wood `0-1-2` (painted on 1), roof `0-1` (painted on 0), paint `1-2-3`, water `0-1-3`.
Materials are told apart by where they are painted and where their ramp stops, not by hue.

| Asset | Class | Size (m) | Instances | Ramps (painted step) | Concept | Tris | Animation |
|---|---|---|---|---|---|---|---|
| plateau | terrain | 10 x 7.5 x 4.0 (top 0, cliff 1.4, rocky underside) | 1 | grass (2), water (1, a sunken pond), wood (1, cliff), roof (0, underside) | this list | 638 | |
| barn | hero prop | 3.6 x 4.0 x 3.11 | 1 | barn (wall textures, 0.1 m a texel), roof (0) | `barn/sheet.v1.png` | 44 | |
| windpump | prop | 1.8 x 2.4 x 4.66 | 1 | roof (0, lattice, no shadow), wood (1, blades), paint (3, vane) | this list | 472 | rotor: rigid, 1 turn / 4 s, linear, 12 fps |
| field | prop | 3.4 x 3.5 x 0.5 | 1 | roof (0, soil ridges), grass (2, crop tufts) | this list | 540 | |
| fence | prop | 2.4 x 0.24 x 0.84 | 3 | roof (0) | this list | 60 | |
| haystack | prop | 1.6 x 1.6 x 1.05 | 2 (1, 0.7) | paint (2) | this list | 40 | |
| tree | foliage | 1.7 x 1.5 x 2.96 | 2 (1.1, 0.9) | roof (0, trunk), wood (1, crown, sway) | this list | 60 | sway |

Thin parts, exaggerated for the 0.12 m spacing: lattice bars 0.14, fence rails 0.15, vane 0.14 thick,
rotor blades 0.24 wide (six, not eighteen: thinner, denser blades fuse into a disc). The barn's door,
windows and corner boards are painted into its wall textures (see `models/barn/barn.spec.md`).
Bones: 1 (the rotor).
