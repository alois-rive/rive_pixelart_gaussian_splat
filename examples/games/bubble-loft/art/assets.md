# Assets: Bubble Loft (Sunset 8, 8 colours)

Art grid: 640 x 400 artboard, `pixelSize` 3 -> 213 x 133 art pixels (136 rows with the spare); a look-at
front view of the loft's big window from a little above (the eye 2.6 m higher than the target, 25 m out:
about 6 degrees down), orthographic 11.2 m -> texel 0.082 m. Splat spacing 0.1 m (1.2 texels); small parts
finer (brass, iron bars, petals, rubber, ropes 0.07; the lit windows and the sun 0.06). Palette: Sunset 8
(one long navy -> plum -> pink -> salmon -> orange -> gold -> yellow -> cream run) cut into 14 short ramps
that share their ends; the sun, the windows and the cloud streaks are `unlit`.

The four orb colours are told apart by value as much as hue: **dusk** (navy, a plum glint), **rose**
(pink, plum shade, cream glint), **ember** (orange, salmon shade, no glint) and **sun** (cream, gold
shade). The field behind them is the plum sky (`sky_top`), so no orb colour's lit step is the backdrop's;
the sky turns pink (`sky_bottom`) only low behind the rooftops.

| Asset | Class | Size (m) | Instances | Ramps | Concept | Tris | Motion |
|---|---|---|---|---|---|---|---|
| puffer | hero / launcher | 2.83 x 1.38 x 2.42 (x 1.15 in the scene) | 1 static base + bones `barrel`, `bulb` | iron (plinth), copper (drum), brass (lid, barrel, arm, cup), petal (tulip mouth), rubber (bulb, hose) | `puffer/sheet.v1.png` | 294 | game: the barrel swings to the aim (roll about its lid pivot) and recoils; the squeeze bulb breathes and squashes flat against the drum on each launch |
| orb_dusk / rose / ember / sun | effect / pool | r 0.40 (in a 0.46 cell) | 14 each (`dusk0-13`, `rose0-13`, `ember0-13`, `sun0-13`) | dusk (step +1), rose, ember, sun | this list | 80 each | game: cling to the cluster, sit in the mouth or the cup, fly, burst (a squeeze, then HUD shards), fall and bounce on the planks |
| beam | prop | 7.28 x 0.6 x 0.45, ropes 7.15 up | 1 (`beam`) | wood (rafter), brass (4 bands), wood (ropes) | this list | 84 | game: drops a row (0.80 m) every few shots on a spring with a bounce, rises back for a new cluster, shivers a texel when one shot is left |
| loft | terrain / architecture | 18 x 3.8 x 11.4 | 1 | wood (planks, posts, shelves, knee walls), iron (mullions, planter), brass (the sill), clay (pots), leaf (plants, sprouts), dusk / rose / ember (spare orbs in the crate) | this list | 2100 | static |
| far | backdrop | 22 x 4 x 2 behind the glass (glTF z -10 .. -14) | 1 | roofs (step +1), glow (the low sun, lit windows: unlit), clay (cloud streaks: unlit) | this list | 400 | static |

Bones: 59 game bones of 63 (barrel, bulb, beam, 56 orbs). Splats: about 70 500 in `scene/splats.bin`
(the orb pools about 8 700 of them, 155 a ball).

## The bone plan

The cluster is a hex grid of 8 columns (rows of 8 and 7, alternating) under the rafter; at most 8 rows
can hold orbs before the sill (rows 0..7 with the rafter at rest; a row r is lost when r + drops >= 8).
Colour is baked per splat, so a bone's colour is fixed: the orbs are **one pool per colour**, 14 each
(4 x 14 = 56 bones), baked at the largest size they are ever drawn (the cluster's) and only scaled down
(the cup shows its orb at 0.75; a new cluster grows in from 0.3).

- Every orb on screen holds one bone of its colour: the cluster's, the loaded one, the one in the cup,
  the one in flight, a bursting one (0.09 s), a falling one (until its second bounce).
- The board generator caps each colour at 10 (14 - 4: room for the shot, the cup and a burst in flight)
  and the first cluster uses three colours only.
- The next orb's colour is drawn (`api.rand`) only among colours that the cluster still holds AND that
  have a free orb; the mouth and the cup are re-dealt when their colour has left the cluster.
- A cluster can never outgrow the pool for long: 8 rows hold 60 cells but the run ends at the sill first;
  if no orb can be loaded for 2.5 s (a huge cluster with orbs still falling) the loft counts as full and
  the run ends.
- Bursts and falls are short, so a quick player never waits; a new cluster grows cell by cell as the old
  one's orbs free their bones (a restart bursts the old cluster in a wave from the rafter down).

Shards (bursts, wall knocks, landings) are HUD rectangles in the orb's palette colours, not bones.

## Layout (glTF metres, Y up, the camera on +Z; scene/game.as and models/env/make_env.py share these)

The game's plane is z 0. The window's inner half width is 3.68 (the posts the orbs bounce off; an orb's
centre turns at 3.22). The rafter's underside rests at y 9.75; row r of the cluster hangs at
9.29 - 0.797 r (cell width 0.92, odd rows shifted 0.46). The brass sill (the danger line) tops out at 3.2.
The puffer stands at the window's foot, baked at 1.15: the barrel pivots at (0, 1.53), the loaded orb sits
1.15 up the barrel, the cup holds the next orb at (1.23, 1.34). Falling orbs drop in front of the puffer
(z 0.75) onto the planks (an orb's centre at y 0.46). The rooftops, the sun and the clouds stand 10-14 m
behind the glass and show lifted about 1.1 m by the camera's pitch.
