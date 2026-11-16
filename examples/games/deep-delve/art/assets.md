# Assets: Deep Delve, a roguelike over an abyss (Gamma Boy)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 216 x 136 art pixels (with the spare), 213 x 133 of
HUD. Camera: orthographic, yaw 0, pitch 52, `orthoHeight` 7.6 m -> texel 0.0559 m; a 1 m tile is 18
art pixels wide and 14 deep; the view shows about 12 x 10 tiles and follows the delver (the renderer
snaps it to whole art pixels). Splat spacing 0.085 m (1.5 texels) for the platforms and bridges, 0.07
for the delver, 0.045 to 0.075 for monsters, items and weapons (a weapon or a potion is 5 to 9 art
pixels long). One sun (yaw -35, pitch 58, `keyLight` 0.42, `highlight` 0.9, `shadeSteps` 1), per-splat
dither, ink 1, a flat green-black sky (`horizon` 2, `#192119`): the abyss.

Palette: Gamma Boy (16 colours, Vsigos), loaded from Lospec; re-skinned from Apollo. Letters below are
its colours by value (OKLab L): K `#192119` .24, S `#252a2d` .28, G `#253825` .32, T `#324b41` .39,
P `#4e4b5a` .42, O `#476a2f` .48, N `#6d7270` .55, E `#69835d` .58, B `#8c7661` .58, W `#8c8980` .63,
Y `#84967b` .65, L `#82a641` .68, H `#a39b6c` .69, A `#a3ad8b` .73, C `#b3c392` .79, X `#b5db66` .84.
Ramps (in `palette.json` order, the HUD's ramp numbers in `game.as`):

| # | Ramp | Steps | For |
|---|---|---|---|
| 0 | stone | K S P N W A | floor flags (P), kerb (W), walls (S), footing (K), stairs, shellback shell (N), axe head |
| 1 | deep | K S G T | the teal flags (T), the rock root (S), the stairs' shaft (K) |
| 2 | wood | S P B H C | tunic, belt, pack, bedroll, skin, bridges (B, P planks, S rails), chest, scroll, flitter wings (H) |
| 3 | brass | P B H C X | gold (C, X glints), chest bands, guards, the spitter's cap, haste |
| 4 | moss | K G O E Y A | moss patches (O, E), the ooze (E, Y crown), spitter, shellback crown and skin |
| 5 | cloak | K G O L X | the delver's cloak (O, lifted to lime by the sun), mending, the scroll's seal |
| 6 | rust | K P B H | skitters (B shell, P head and legs), the sling's band |
| 7 | gloom | K S P N | the flitter's eyes |
| 8 | bone | N W A C | the helmet (A), blades, glass, horns, sling stones, eyes, the attack marker (unlit C) |
| 9 | flame | O L X | unlit: the brazier's flame (L) and tongue (X), the lamp's window (X) |
| 10 | rune | L X | unlit: the step marker, the stairs' runes (X) |
| 11 | acid | O L | unlit: the spitter's globs (L) |
| 12, 13 | spark, ember | X X, C C | one-colour unlit specks: sparks (lime), monster eyes (pale) |
| 14 | glow | O E | unlit: the brazier's pool of light (motes) |

Roles: void, sky and fog all K (fog is off). Lime (L, X) is kept for light, magic, items and the
delver's highlights. Values, darkest to lightest: abyss, walls and root, floor (0.39 to 0.42), kerb,
then every actor and item above the floor.

## The level problem, and the answer

A dungeon level is a 27 x 16 tile map; a bone per tile would be 432 bones of 63. Instead a level is
built from a few big pieces, each ONE game bone, placed per level:

- **Six room platforms**, one per baked size (7x5, 6x5, 5x5, 6x4, 4x4, 5x3 tiles: `room0..room5`),
  each baked at exactly its size with a flagstone texture of one stone per tile, so the tile grid is
  always true (no scaling). The game shuffles them over a 3 x 2 grid of 9 x 8 cells and turns each by 0
  or 90 degrees: 12 footprints. From depth 2 a cell may stay empty (five platforms).
- **Seven bridges** (`bridge0..6`), one baked plank strip 8 tiles long, laid 0.15 m below the room
  floors. A corridor of 1 to 8 tiles uses the same strip: its spare length slides UNDER the two
  platforms it joins, where their floors hide it (planks stay one per half tile, never squashed). Each
  platform holds its column's spine x and its row's spine z, so every corridor is straight. If a gap
  were too short to hide the spare, the strip is squeezed along its length instead (scaled down only);
  the self-test over 60 levels never needed it.
- **Fog of war by bones**: a platform, its bridges, items, braziers and the stairs are hidden until
  the delver's light (5.6 tiles) reaches them; then they rise out of the abyss (stepped, 0.5 s). A
  bridge never shows before both its platforms (its hidden spare would show over the void).
- Monsters, items, projectiles, sparks are pools; the stairs, the markers and the delver's four weapons
  are single bones.

## Bones (game bones, `"bone"` / `"copies"` in `scene.bake.json`): 59 of 63

| Group | Bones | Count |
|---|---|---|
| delver | hero | 1 |
| held weapons (one shown, in the right fist) | dagger, sword, axe, sling | 4 |
| step marker, attack marker | marker, markatk | 2 |
| stairs | stairs | 1 |
| room platforms | room0-5 | 6 |
| bridges | bridge0-6 | 7 |
| braziers (block their tile) | brazier0-3 | 4 |
| monsters | skitter0-3, flitter0-2, shellback0-1, spitter0-1, ooze0-3 (two oozes and their halves) | 15 |
| floor items | chest0-1, potred0-1, potblue, scroll0-1, gold0-2 | 10 |
| projectiles | stone (the sling's), spit0-1 | 3 |
| sparks | spark0-5 | 6 |
| | | **59** |

Splats: 65 536 in the scene blob (platforms 33 800, bridges 16 200, monsters 6 700, braziers 2 700 with
their pools, the rest props).

## The list

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| hero (the delver) | hero / character | 0.88 x 0.62 x 1.23 | 1 | cloak, wood, bone, flame | `hero/sheet.v2.png` (Gamma Boy; v1 was Apollo), gated | 584 | game: hops a tile (stepped arc and stretch), lunges at a blow, squashes when hurt, breathes, topples when slain, sinks down the stairs and drops onto the next depth |
| room platform (6 sizes) | level piece | 7x5 .. 5x3 tiles, 0.46 m walls, a rock root 1 m deep | 6 | stone and deep (top texture, one stone per tile: dark teal flags, a random third purple-grey, mossy and cracked ones, slate grout, a warm-grey kerb texel round the edge), deep (root) | this list | 30-40 | game: rises from the abyss when lit, sinks when the delver goes down |
| bridge | level piece | 8 x 0.9 m, 16 planks, low rails | 7 | wood | this list | 216 | game: placed per corridor, rises when lit |
| stairs | level piece | 0.96 m well-head, a black shaft, three steps light to dark, four rune stones | 1 | stone, deep, rune (unlit) | this list | 144 | game |
| brazier | prop | 0.56 x 0.56 x 1.0, a pool of light r 1.4 | 4 | stone, flame (unlit), glow (unlit motes, `textures/halo.png`, alpha-masked) | this list | 106 (glTF) | game: stepped flicker (height, turn): the motes twinkle |
| skitter | creature (swarm) | 0.56 long | 4 | rust (brown shell, dark head), ember eyes (pale) | this list | 132 | game: steps, jitter, bump |
| flitter | creature (erratic flyer) | 1.0 span, flies at 0.55 | 3 | bone body, wood wings (khaki, brown tips), gloom eyes | this list | 84 | game: wingbeat (stepped squash), bob, hops |
| shellback | creature (slow tank) | 1.3 x 1.4 x 0.85 | 2 | stone (grey shell, slate rim), moss crown and skin, bone horns, ember eyes | this list | 140 | game |
| spitter | creature (ranged, poison) | 0.7 long, 0.66 tall | 2 | moss (olive body, sage belly, pale eyes), brass cap (khaki) | this list | 122 | game; acid globs arc to the delver |
| ooze | creature (splits) | 0.84 across | 4 (halves at 0.72 scale) | moss (sage jelly, grey-green crown), bone eyes | this list | 92 | game: wobble (stepped squash); a half jumps out when struck |
| chest | item | 0.62 x 0.48 x 0.5 | 2 | wood (purple-grey box, brown lid), brass bands (pale) | this list | 60 | game: hop and spin when opened |
| potion (mending lime, haste khaki) | item | 0.36 tall | 2 + 1 | cloak / brass, bone, wood | this list | 56 | game: bob |
| scroll | item | 0.48 long | 2 | wood, cloak seal (lime) | this list | 96 | game: bob |
| gold | item | 0.44 across, 7 coins | 3 | brass (pale coins, lime glints) | this list | 196 | game: bob |
| dagger, sword, axe, sling | weapon (held) | 0.3 .. 0.72 | 1 each | bone, brass, wood, stone, rust | this list | 24-40 | game: held in the right fist, swing (stepped pitch) |
| stone, spit | effect | r 0.09 / 0.12 | 1 + 2 | bone / acid (unlit) | this list | 20 | game: arcs |
| spark | effect | r 0.07 | 6 | spark (unlit, specks) | this list | 20 | game: bursts on hits and kills |
| marker, attack marker | effect (UI in the world) | a 0.9 m tile outline + chevron / four corners + X, 0.08 m over the floor | 1 + 1 | rune (lime) / bone (pale) (unlit) | this list | 84 | game: on the tile a press would act on, stepped pulse |

All non-hero pieces are written by `models/env/make_env.py` (hedra command files and the floor
textures, palette-exact) and are gated by the bake's report (colour error 0.000, no specks warnings
except on purpose: eyes and sparks) and by looking at the scene frames.
