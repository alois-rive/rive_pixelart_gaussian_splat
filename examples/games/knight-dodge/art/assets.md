# Assets: Knight Dodge, a round arena at torchlit dusk (Rust Gold 8)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels; `orthoHeight` 10 m -> texel
0.075 m. Splat spacing 0.09 m (1.2 texels) for the world, 0.065 m for the knight, 0.06-0.07 m for
the coins, dust and flames. Palette: Rust Gold 8 (`palette.json`, 8 colours: gold, rust, brown, dark
brown, tan, mauve, grey, black), 6 ramps sharing them; the brazier flames are `unlit`.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| knight | hero character | 0.99 x 0.71 x 1.18 (x 1.5 in the scene) | 1 | steel (armour, blade, visor), gold (plume, guard, shield rim, tabard), rock (boots, gloves) | `knight/sheet.v1.png` | 392 | game bone: runs to the pointer (spring), stepped bob and waddle, lean, squash on a hit, topples at game over |
| arena | terrain | 11.4 x 11.4 x 3.4 | 1 | sand (floor, painted rings and patches), stone (wall, pillars, apron), rock (underside) | this list | 3722 | |
| brazier | prop | 0.64 x 0.64 x 0.32 | 8 (one per gate pillar) | stone | this list | 48 | |
| flame | effect | 0.5 x 0.5 x 0.62 | 8 | fire (unlit, nocast) | this list | 18 | game bones: a stepped flicker (squash, stretch, a turn), out of step |
| banner | prop | 0.9 x 0.08 x 1.45 (x 0.8) | 3 on the back wall | gold (cloth, band; double), rock (pole) | this list | 48 | |
| boulder | prop | 1.0 across | 6 (pool) | rock (rock, rust veins) | this list | 80 | game bones: wait and rock in a gate (the telegraph), roll (turning one radian per radius), smash on the far wall |
| coin | pickup | 0.48 x 0.09 x 0.48 | 2 (pool) | gold | this list | 60 | game bones: spin and bob (stepped), pop up and away when taken |
| dust | effect | 0.32 across | 12 (pool) | sand (nocast, specks) | this list | 20 | game bones: puffs at rumbling gates, smashes and hits |

Bones: knight 1 + boulders 6 + coins 2 + dust 12 + flames 8 = 29 of 63. Scene blob: 43 778 splats.

Layout (glTF metres, Y up, +Z towards the yaw-0 camera): the sand floor r 4.6 at y 0; the wall on a
circle of r 4.85, 0.75 to 0.93 m tall (crenellated), broken by four gates at 45, 135, 225 and 315
degrees (x = r cos a, z = r sin a: front right, front left, back left, back right), each flanked by
two pillars (1.5 m) carrying a brazier and its flame (y 1.78); a paved apron to r 5.7 and a rocky
underside below it; three banners on the back wall's inner face. The knight runs inside r 4.25; a
boulder waits in its gate at r 5.15 and smashes when its centre passes r 4.2 heading out.
