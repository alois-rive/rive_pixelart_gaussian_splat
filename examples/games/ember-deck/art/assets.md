# Assets: Ember Deck, a card battle in a candle-lit crypt (Ink-Crimson)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 HUD pixels (216 x 136 art pixels with the
spare); `orthoHeight` 6 m -> texel 0.0441 m. Splat spacing 0.07 m (1.6 texels) for the crypt, 0.055 m
for the knight and the foes, 0.035 to 0.045 m for blades, wicks, flames, eyes and effects. Camera:
orthographic, yaw 0, pitch 12, target (0, 0.62, 0): a side-on stage, the knight on the left (x -2.2)
facing right, the foe on the right (x 2.2). A warm key light from the front left (sun yaw -35, pitch
42, key 0.4, highlight 0.85, `shadeSteps` 1), per-splat dither, ink 1, `edgeDepth` 1.2, a flat sky.

Palette: Ink-Crimson (10 colours: red, crimson, maroon, wine, plum, night, ink; cyan, blue, navy) in
11 ramps: stone (ink..maroon), brick (night..crimson), cloth (plum..red), steel (night, navy, blue,
cyan), leather (ink..wine), frost (ink, night, navy, blue), and the unlit ones flame (crimson, red),
ember (red x2), soul (blue, cyan), spark (cyan x2), hot (red, cyan; spare). The crypt lives in the
crimson darks; the knight, the warden and the magic in the blues: the two halves of the palette are
the two sides of the fight.

The cards are not 3D: they are HUD rectangles, lines and pixel text drawn in call order on the art
grid (`scene/game.as`, `hud()`), so the bones go to the figures and the effects.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| hero (the Wick Knight) | hero character | 1.29 x 0.85 x 1.80 | 1, in 3 parts (body, sword arm, shield arm) | steel (armour, blade, rim), cloth (cape, buckler face; boots and legs lifted a step), flame (crest, unlit) | `hero/sheet.v1.png` | 396 | game bones: idle breathing (stepped 12 fps), a wind-up, a lunge and a sword swing per hit, a shield raise, a cast (sword up), a knock-back, a fall, a cheer; the arms turn about the shoulders |
| crypt | terrain / architecture | 12.8 x 6.8 x 4.6 | 1 | stone (floor tiles, wall blocks, recesses, altar), brick (pillars, trim), leather (sconce irons), frost (a rune ring on the floor) | this list | 1528 | |
| candles0..4 | prop | clusters of 3 to 5 candles 0.22 to 0.62 tall | 5 (altar, two niches, two on the floor) | cloth (wax, drips), leather (wicks) | this list | 132-220 | |
| flames0..4 | effect | 0.13 x 0.26 a flame | 5 bones | flame (unlit, nocast) | this list | 54-90 | game bones: a stepped flicker (squash and stretch, out of step) |
| sconce_fire | effect | 0.24 x 0.42 | 2 bones | soul (unlit, nocast) | this list | 22 | game bones: flicker |
| mite (Wax Mite) | foe | 0.88 x 0.8 x 1.32 | 1 bone | cloth, leather, spark (eyes, unlit), flame (wick, unlit) | this list | 240 | game bone: breathe, lunge, recoil, melt, hop in |
| moth (Crypt Moth) | foe | body 0.4 x 0.4 x 0.9; wings 1.0 each (x 1.3 in the scene) | 3 bones (body, two wings) | cloth (+1 step), steel (wing eyes), spark (eyes, unlit) | this list | 148 + 2 x 12 | game bones: hovers and bobs, the wings flap (roll about the body, stepped), dives at the knight |
| warden (Grave Warden) | foe | 1.7 x 1.0 x 2.0 | 1 bone | frost (stone), steel (face, shield), spark (eyes, rune, unlit) | this list | 210 | game bone: as the mite |
| king (Tallow King) | boss | 1.9 x 1.9 x 2.85 | 1 bone | cloth (wax, pool, drips), leather (crown band, staff), spark (eyes, unlit) | this list | 488 | game bone: as the mite, bigger |
| king_fire | effect | the crown's five flames and the staff's soul fire | 1 bone | flame, soul (unlit) | this list | 126 | follows the king (`api.transform`), flickers |
| slash | effect | an arc r 0.75 | 2 (pool) | spark (unlit, double) | this list | 18 | game bones: a swept arc over the foe per hit, 0.2 s, stepped growth |
| spark | effect | octahedron 0.15 x 0.21 | 10 (pool) | ember (unlit, specks) | this list | 8 | game bones: hit bursts (ballistic), burn and hex streams, rising buff sparks |
| mote | effect | octahedron 0.15 x 0.21 | 8 (pool) | spark (unlit, specks) | this list | 8 | game bones: heal, draw and energy motes rising; weaken motes falling |
| ward | effect | a hexagon r 0.62 | 2 (the knight's cyan one, the foe's red one) | spark / ember (unlit, double) | this list | 84 | game bones: pops when block is gained or spent, stays small while block lasts |
| burn | effect | a double flame 0.3 x 0.5 | 3 (pool) | flame (unlit) | this list | 40 | game bones: on a burning foe, one per 3 burn, flickering |

Bones (game bones, `"bone"` / `"copies"` in `scene.bake.json`): knight 3 + foes 6 (mite, moth and its
two wings, warden, king) + king fire 1 + candle flames 5 + sconce fires 2 + slashes 2 + sparks 10 +
motes 8 + wards 2 + burns 3 = 42 of 63. Splats: 50 290 in the scene blob (crypt 34 200, king 3 900,
knight 2 200).

Layout (glTF metres, Y up, +Z towards the camera): the floor of 1 m tiles at y 0 (x -6..6, z -3..3);
the back wall in the plane z -3, 4.6 m tall, stone blocks 0.8 x 0.5 in running bond, broken by a big
arch over the altar (x 0, 1.7 wide, 2.7 tall) and two niches (x +-3.2, sill 0.7); pillars at x
+-4.45, z -2.3, with sconces on their inner faces (fires at +-3.77, 1.94, -2.3); a rune ring at z
-1.2 between the fighters. The knight stands at (-2.2, 0, 0) turned 50 degrees towards the foe, the
foe at (2.2, 0, 0) turned -40 (the moth hovers at 1.35 m, facing out at -25). Play area
(`"bounds"`): 12.8 x 5.4 x 6.8 m.
