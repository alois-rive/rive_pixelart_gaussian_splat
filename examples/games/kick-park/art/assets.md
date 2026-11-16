# Kick Park: asset list

Art grid: 640 x 400 at `pixelSize` 3 (213 x 133 HUD pixels, 136 art rows). Camera: orthographic,
yaw 20, pitch 40, `orthoHeight` 8 m, following the skater by translation only (snapped to the grid).
Texel t = 8 / 136 = 0.0588 m. Splat spacing 1.2 to 2 t: 0.07 to 0.12 m for the park, finer for the
skater (0.04 to 0.055 m: a 1.67 m hero is about 25 art pixels tall and must keep its face and hands).

Palette: AAP-64 (Lospec `aap-64`, 64 colours) with 22 hand-written ramps (`art/palette.json`): concrete,
sand, grass, leaf, wood, skin, hoodie, beanie, denim, white, deck, grip, wheel, steel, paint, mural,
pink, lilac, and the one-colour particle ramps dust, spark, ember, plus sky.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Triangles | Motion | Notes |
|---|---|---|---|---|---|---|---|---|
| `skater` (Marlo with his board) | hero / character | 1.16 x 0.38 x 1.67 | 1 (10 game bones) | hoodie, beanie, denim, skin, white, wood (hair), grip (eyes), deck, grip, steel, wheel | sheet `art/skater/sheet.v1.png` | ~2000 (chamfered boxes) | game-driven: board, torso+head, 2 arms, 2 thighs, 2 shins, 2 shoes, posed every frame by `game.as` (IK legs, crouch, flips, spins, grabs, push, bail) | ears and nose exaggerated to stay over 12 splats; the beanie and head narrowed for the splats (p3) |
| `park` (slab, bowl, 2 QPs, fun box, kicker, rail, curb) | terrain / level | 25.5 x 19.9 slab | 1 | concrete, lilac (bowl and QP faces), steel (copings, seams of the ledges), sand (decks, curb), mural (fun box ramps), paint (fun box sides), wood (kicker), beanie (rail) | from this list (`models/env/make_env.py`) | 4.5 k | none | written straight to GLB by Python so the curved bowl and QPs match the physics in `game.as` exactly; expansion joints every 3 m as separate darker strips (not an overlay) |
| `yard` (grass, back wall, murals, trees, benches, lamps) | terrain / props | 34.5 x 25 | 1 | grass, leaf, wood, sand, mural, deck, beanie, steel, wheel (unlit lamps) | from this list | 1 k | none | the mural boards stand 16 cm off the wall (an overlay 1 cm off fought the wall's splats) |
| `dust` | effect | 0.32 x 0.24 x 0.32 | 8 (pool) | dust (one colour) | none | 20 | game-driven puffs (push, ollie, landing, bail), grown and shrunk in 12 fps steps | baked at the largest size, scaled down |
| `spark` | effect | 0.12 | 8 (pool) | spark (one colour) | none | 8 | game-driven grind sparks, ballistic | unlit, no shadow |

Bones: 26 of 63 (10 skater + 8 dust + 8 spark). Splats: 94 037 in `scene/splats.bin` (2.9 MB).

## Layout (world metres, Y up; the camera looks towards -Z)

```
z=-10.4 ┌──────── back wall with mural boards ───────────────────────────┐
        │        QP1 (x -5..5): base z -7.2, coping z -9.02, deck 1.2 m  │
        │                                                               │
        │   kicker x -4.2..-3.0, z -5.3..-3.7, rising to +x, 0.6 m   QP2 │ z -6..2: base x 9.6,
        │                                                               │ coping x 11.47
  bowl  │ (-8, 0.5): floor r 1.2, depth 1.4, coping r 3.1               │
        │                  fun box x 1..4 (+1.2 m ramps), z 0.5..2.5,   │
        │                  0.45 m, steel ledges along both long edges   │
        │      handrail x -4..1.5, z 6, 0.55 m                          │
z=9.5   └──────────────────── curb, grass, trees, benches ──────────────┘
```
