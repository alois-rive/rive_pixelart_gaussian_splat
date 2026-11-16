# Gust Regatta: the asset list

Art grid: 640 x 400 at `pixelSize` 3 (213 x 133 HUD pixels, 136 art rows), an orthographic chase view
looking north 55 degrees down (`yaw` 0, `pitch` 55), `orthoHeight` 16 m: texel 16 / 136 = 0.118 m,
splat spacing 0.17 m (1.45 texels) for props and the boat, 0.2 to 0.3 m for the big ground. The camera
only translates (the target follows the boat with a lead), so the picture slides by whole pixels and
nothing re-rasterises. The view shows about 26 x 20 m of water.

**The water is the sky.** Nothing is spent on a sea surface: the palette's `sky_top` and `sky_bottom`
are both the sea blue `#6d80fa` and `horizon` 2 makes it flat, so every pixel no splat covers is open
water. Everything on the water (shallows, ripples, gusts, wavelets, foam) is a flat unlit layer just above
y 0; the shore's shallows draw the coastline, and the renderer's ink steps their outer edge down to the
sea colour. Boats cast no shadow on the water (there is no water to receive one); their own ink outlines
seat them.

Palette: Lospec `mulfok32` (loaded from Lospec; the spare `endesga-64` was not needed), 32 colours, 18
ramps (`palette.json`). Unlit water layers use ramps that repeat one colour (`foam`, `ripple`, `gust`,
`gustrip`, `streak`, `ghost`) so the ink cannot eat them. HUD colours are palette colours by index.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Triangles | Motion | Notes |
|---|---|---|---|---|---|---|---|---|
| `sailboat` (hull + rig) | hero, the player | 3.7 x 1.2 x 2.95 (x 1.35 in the scene: 5.0 m long, ~40 art px) | 1 | red (hull), white (deck, sail), wood (cockpit, rudder, tiller), rock (mast, boom), blossom (sail band) | sheet v1, gated (spec) | 156 | 2 game bones: the hull (heading, heel, pitch, bob) and the rig (the boom swung about the mast, heeling with the hull) | two GLBs from one gated model (p3 splat fit); mast 0.07 at spacing 0.05 |
| `ghost` | effect | the sailboat | 1 | ghost (unlit, pale pink `#ffc3f2`) | the hero's GLB | 156 | game bone: replays the best race | every material mapped to one unlit colour (the bake warns, on purpose) |
| `bay` | terrain | 98 x 86, a superellipse bay 80 x 63 inside | 1 | shoal (unlit), sand, grass, rock | from this list | 2080 | none | rings offset from the coastline: shallows (2 tones), beach or rocky shore, meadow, low hills in the corners; rocky stretches west, north-east, south-east |
| `islets` | terrain | Lantern Isle r 6.5, Gull Rock r 2.8, Pine Key r 3.2 | 3 | shoal, sand, grass, rock | from this list | 569 | none | lobed outlines; Lantern Isle has a low rocky cliff on its north side |
| `ripples` | effect | 0.6-1.0 x 0.14 dashes | 420 | ripple (unlit) | none | 828 | none | the sea's static texture: it gives the moving camera something to slide past; `specks` |
| `props` | architecture / foliage | lighthouse 2 m wide, 7 m to the pole top; cottages 2.6 x 2 x 2.5; trees 2.3 x 3; jetty 1.5 x 5.2 | 1 lighthouse, 5 cottages, ~40 trees and bushes, 1 jetty | white, red, rock, glow (lamp, unlit), wood, grass, blossom | from this list | 2160 | none | the lighthouse on Lantern Isle: five red and white bands, a dark gallery, the lantern, a red cap, the flag pole |
| `buoy` | prop (the gates) | 1.0 across, 1.07 tall | 10 (pool) | buoy (orange), white | from this list | 50 | game bones: bob, a stepped roll, a squash-and-stretch pop when their gate is taken or bumped | two per gate, 6.8 m apart |
| `marker` | effect | 0.64 x 0.9 diamond | 1 | glow (unlit) | none | 8 | game bone: floats and spins (stepped) over the next gate | |
| `gust` | effect | a 12 m lobed disc with 30 ripple dashes | 4 (pool) | gust, gustrip (unlit) | none | 114 | game bones: appear upwind, drift downwind, grow and shrink (scale, stepped), shrink near shores | darker, ruffled water; inside one the wind is up to 1.5 x stronger |
| `streak` | effect | 1.9 x 0.16 wavelet | 14 (pool) | streak (unlit) | none | 6 | game bones: wavelets round the camera, crests across the wind, drifting downwind at the wind's speed | `specks` |
| `foam` | effect | 1.0 lobed disc | 12 (pool) | foam (unlit) | none | 7 | game bones: the wake (a V of dabs off the stern), bow spray when fast, a burst at a gate or a bump; shrink in 4 steps | `specks` |
| `flag` | prop (wind) | a windsock 1.3 long, 0.56 across | 1 | red, white | none | 48 | game bone: on the lighthouse's pole, streams downwind, droops when the wind eases, flutters (8 fps) | a sock rather than a flat pennant: a pennant streaming towards the camera is edge-on and vanishes |
| `dinghy` | prop | 2.5 x 1.05 x 2.6 | 3 (yellow, pink, blue hulls: three GLBs) | sand / blossom / sea, wood, rock, white | from this list | 43 | game bones: moored off the jetty, they swing their bows into the wind and bob | a wind cue near the village |

Bones: 48 of 63 (hull 1, rig 1, ghost 1, buoys 10, marker 1, gusts 4, streaks 14, foam 12, flag 1,
dinghies 3), all game bones moved by `scene/game.as`; no baked tracks. Splats: 96 562 (bay 51.6 k, props
19.5 k, islets 8.4 k, gusts 5.9 k for the pool of 4, ripples 3.3 k, the boat 2.1 k, the ghost 1.8 k).

The bake's `"bounds"` [-49, -0.5, -45]..[49, 9, 41] cover the whole land ring: the camera target is
clamped to x -33..33, z -28..25 so the view never runs past the land's outer edge.
