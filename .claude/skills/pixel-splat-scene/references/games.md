# Cameras, games and interactive scenes

The renderer draws whatever its inputs say. A still diorama, a cutscene and a
game differ only in who sets those inputs and how often: the scene's own
values in `scene.rml`, a timeline keying them, a view model the host app or
another script writes, or code you add to `splat_scene.as`.

## Choosing a camera

Two modes. **Orbit** (default): `yaw`, `pitch`, `distance` around a target
(`useTarget` + `targetX/Y/Z`, or the bounds' centre). **Look-at**
(`lookAt` true): from `eyeX/Y/Z` to `targetX/Y/Z`, level (no roll). Either can
be orthographic (`orthoHeight` sets the world height shown) or perspective
(`perspective`, `fov`).

| Genre / shot | Mode | Projection | Inputs | Notes |
|---|---|---|---|---|
| Diorama, menu backdrop, title | orbit | ortho | yaw 30-45, pitch 25-35, `spin` 0 or slow | the classic look; `orbit` true for a draggable preview |
| Isometric game | orbit | ortho | yaw 45, pitch 30 (the 2:1 pixel-art iso) or 35.26 (true iso) | target follows the player; snapping keeps scrolling whole-pixel |
| Top-down | look-at | ortho | eye straight above the target (a small z offset keeps "up" defined), or orbit pitch 85-90 | the art grid reads like a tile map |
| Side-scroller / 2.5D platformer | look-at | ortho | eye at (x, y, d), target (x, y, 0); move both with the player | pure translation: snapping makes it pixel-perfect; parallax needs perspective or layers at different scales |
| Third person / follow | look-at | perspective, fov 30-45 | eye behind and above the player, target at the player | lag the eye (spring) in your code; rotation re-rasterises splats, keep turns slow or stepped |
| First person | look-at | perspective, fov 50-70 | eye at the head | near splats get huge: keep geometry beyond ~0.5 m, raise `pixelSize`; turns crawl, which reads as retro |
| Cutscene | either | either | key the inputs on a timeline (`KeyedProperty 243` on each `ScriptInputNumber`) | step the keys at 8-12 fps for the hand-animated feel |
| Asset review | orbit | ortho | `tour` / `tourLoops` turntable, or `golden.py views` | captures are deterministic |

Orthographic snapping: the renderer rounds the target onto the art grid along
the view plane and slides the final blit by the remainder, so a camera that
translates (scrolling, following) moves the picture by whole screen pixels
and nothing shimmers. A camera that rotates cannot be snapped: every splat
re-rasterises, which reads as pixel crawl. Prefer translating cameras for
games; rotate in steps (45 or 90 degrees, over a few stepped frames) when the
game needs to turn.

## Driving the camera from a game

Every `ScriptInputNumber` is bindable and animatable (`rive docs data`). Bind
the camera inputs to a view model the game writes:

```xml
<ScriptedLayout scriptAssetId="0:80" name="Splats" id="0:12">
    <ScriptInputBoolean propertyValue="true" name="lookAt"/>
    <ScriptInputNumber propertyValue="0" name="eyeX">
        <DataBindContext sourcePathIds="<vm>-<camEyeX>" propertyKey="243"/>
    </ScriptInputNumber>
    <ScriptInputNumber propertyValue="0" name="targetX">
        <DataBindContext sourcePathIds="<vm>-<camTargetX>" propertyKey="243"/>
    </ScriptInputNumber>
    ...
</ScriptedLayout>
```

The host app (or a game-logic script) sets the view model each frame; the
renderer reads its inputs every frame. For tighter control (a spring follow,
screen shake, camera collision), write the camera from `game.as` (below):
its `api` camera fields are applied every frame.

## The game hook: game.as

A game is written in ONE file, `game.as`, next to the renderer. The renderer
(`splat_scene.as`) imports it, fills a `GameApi` (`game_api.as`) every frame
and calls four methods; `scaffold.py` copies a do-nothing `game.as` (a
diorama keeps it). Never edit `splat_scene.as` or `game_api.as` in a project:
they are synced from the skill.

```as
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP } from "./game_api";

export class Game {
    player: i32 = -1;
    start(api: GameApi): void {            // first frame, after the scene's inputs are applied
        api.playable = true;               // the pointer goes to the game, demo stops turning the camera
        this.player = api.bone("player");  // a game bone from the bake ("bone": "player")
    }
    update(api: GameApi): void {           // every frame: api.time, api.dt (<= 0.1 s), api.demo
        api.place(this.player, x, 0, z, yawDeg);
    }
    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {   // HUD pixels; never in demo mode
        if (kind == POINTER_DOWN && api.pick(x, y, 0)) { /* api.hitX, api.hitZ on the ground */ }
        return true;                       // taken
    }
    hud(api: GameApi): void {              // every drawn frame
        api.text(4, 4, "SCORE " + this.score.toString(), api.rampColor(0, 3), 2, api.rampColor(0, 0));
    }
}
```

| `GameApi` | |
|---|---|
| `time`, `frame`, `dt`, `demo`, `demoChanged`, `pixelSize`, `hudW`, `hudH` | seconds, the step (0 to 0.1), demo mode, the visible frame in HUD pixels (art pixels from the top-left) |
| `pointerX`, `pointerY`, `pointerDown` | the pointer's last position and state (HUD pixels) |
| `yaw` `pitch` `distance` `orthoHeight` `perspective` `fov` `lookAt` `eyeX/Y/Z` `useTarget` `targetX/Y/Z` `sunYaw` `sunPitch` `keyLight` `fogMax` `horizon` `skyBlend` | the scene's inputs, read before `update` and applied after it: the camera and the light are the game's to move (follow, shake, a day turning to dusk) |
| `bone(name)` | a game bone's index, or -1 |
| `place(b, x, y, z, yaw, pitch, roll, scale)` | puts the object's pivot (its bake `position`) at x, y, z, turned (degrees: yaw about Y, then pitch about X, then roll about Z) and scaled (1 = as baked) |
| `placeScaled(b, x, y, z, yaw, sx, sy, sz, pitch, roll)` | the same with a per-axis squash and stretch |
| `transform(b, x, y, z)` | where a point of a placed object is now (give it where the bake put it: `restX[b]` + an offset): `tx`, `ty`, `tz`. Attach a child bone (a jet on a nozzle, a hat on a head) by placing it there |
| `hide(b)`, `reset(b)` | out of the picture (far below); back where the bake put it |
| `restX/Y/Z[b]`, `restYaw[b]` | where the bake put it |
| `pick(hx, hy, planeY)`, `pickPlane(hx, hy, nx, ny, nz, d)` | the pointer ray's hit on the plane y = planeY, or on any plane n · p = d (a wall facing the camera): `hitX`, `hitY`, `hitZ` |
| `project(x, y, z)` | a world point in HUD pixels: `screenX`, `screenY` (labels, hit tests against objects) |
| `rand()`, `range(a, b)` | a seeded random (`seed`): deterministic, so goldens repeat; never `Math.random` |
| `rampColor(ramp, step)`, `paletteColor(i)` | palette colours for the HUD (ramps in palette.json order) |
| `text(x, y, s, color, scale, shadow)`, `textCentered(y, ...)`, `textWidth(s, scale)`, `rect(x, y, w, h, color)`, `line(x0, y0, x1, y1, color)` | the HUD: a 3 x 5 pixel font (A-Z 0-9 and `: - . ! ? / + % < > * ' , = ( ) #`), rectangles and lines, on whole art pixels aligned with the scene's; drawn in call order (later on top) |

**Game bones.** In the bake file, `"bone": "player"` gives an object its own
bone, baked where the entry puts it; `"copies": 12` makes a pool (`coin0` to
`coin11`, all at the entry's place until the game moves or hides them).
Game bones and animated parts share 63 bones. A game bone is rigid: animate
it in code (bob, spin, squash and stretch with `placeScaled`, a stepped
wobble). A character that needs a baked clip keeps its own track; move the
whole thing by making the clip's root a game bone's child in the composition
(a separate blob) or by keeping it in place.

**The play area.** Moving objects leave the baked bounds, so give the bake a
top-level `"bounds": [[x0, y0, z0], [x1, y1, z1]]` covering where things go: the
default framing and the shadow map's reach come from it.

**Demo mode** (`demo` input, bound to the `Sample` view model): the game
plays itself, and the pointer is not delivered. A host (a gallery of
samples) switches it per tile; `--arg demo=true` forces it for captures. A
diorama turns at `demoSpin` degrees a second instead. Write the demo as a
plausible player: aims with a little error, misses sometimes, restarts after
a game over by itself.

**Determinism.** `api.time` advances in fixed steps headless, and `api.rand()`
is seeded, so a capture at frame N is the same every time: goldens of a game
are taken in demo mode. Demo and play draw from the same stream, so a world
is repeatable per input sequence, not per seed alone.

**Composition.** A pitched orthographic camera lifts far things on screen by
z · sin(pitch) and keeps them full size: distant hills tower over a near scene;
keep backdrops low, small and close, and inside the bake's `"bounds"` (the
depth range comes from them: a moon outside them is clipped). A perspective camera's far plane is the distance plus 2R of the
bounds: far backdrops (a sun, mesas) need the bounds enlarged, which also
spreads the shadow map.

**Headless input.** Each `--pointer` event takes a frame of its own (a
`pointer click` line in `--commands` takes two), so a scripted schedule drifts:
shorten the `--advance` between them. Goldens and frame audits come from
`--screenshot` runs only: a `--commands` session's later screenshots can be a
value off in a channel, which fails the palette audit.

**A closed-loop test player.** A Python script that writes `--commands` lines
frame by frame (advance, read the state the game prints with a temporary
`console.log`, decide, pointer) plays like a person and finds what one-shot
`--pointer` runs miss: stalls, pinned objects, a demo's own goals. Remove the
logging after.

**The first frame.** `start` runs on the first advance: a pointer event before
it goes nowhere. Headless tests advance at least 2 frames before the first
`--pointer`. Test the hand-over from demo to a player (what a gallery does) with
`--commands`: `data demo=true`, advances, `data demo=false`, advances (set
demo through the view model both times; `--arg demo=true` cannot be undone
mid-run).

**The pixel font** is 3 x 5: W and H differ by one pixel, and U reads as O at
scale 2 under a heavy shadow; prefer words that survive it.

**No translucency.** Splats are opaque: a light beam or a glow is either
unlit geometry (a cone, a floor disc; a disc floats over gaps rather than
lying on props) or HUD lines (always on top).

**State on the ground** (mowed grass, painted tiles, lit floor cells): pool
one bone per cell over a baked "after" surface and squash or hide each cell's
"before" tile as it changes. It costs a bone a cell (an 8 x 6 lawn is 48 of
the 63), so keep grids coarse.

**Physics first in Python.** Collisions, sub-stepping and a demo's steering
are easier to debug in a throwaway Python port of `update()`: it finds wedged
coins and stalls before any Rive run.

**The frame budget.** Each frame's script gets 200 ms; going over is an error.
Spread heavy work (a level generator's path searches, a solver) over several
frames, or precompute it.

**Debugging.** `console.log("...")` from `game.as` prints in the `rive` output.
A scale of 0 in `place` is clamped (a degenerate bone draws as huge flat
squares): `hide` an object instead. Bone scale moves splats apart but does not
grow them: bake a pooled object at its LARGEST size and scale it down.

**AssemblyScript traps.** `Math.max` / `Math.min` take f64: for integers write
`max<i32>(a, b)`; `<f32>` and `<f64>` casts are explicit everywhere.

**Coordinates.** HUD pixels are art pixels counted from the top-left of the
visible frame (`hudW` x `hudH`, 213 x 133 at 640 x 400 and `pixelSize` 3), aligned with the
scene's art pixels (the texel is still `orthoHeight / 136` there: the art grid has a spare row each
side); the
pointer arrives in them, and `pick` / `project` convert to and from the world.

## Input

A host may forward only the pointer to a nested artboard (Rive forwards
pointer, scroll and gamepad events to nested artboards, not keys), so a game
meant to be embedded plays with the pointer alone: click or tap, hold, drag.
Keys reach a scene that holds focus (`rive docs focus`); add them as a
convenience on top, never as the only control.

The renderer's pointer orbit (`orbit`) is a preview convenience, off by
default, and off whenever a game sets `playable`.

## HUD and UI

`game.as`'s `hud()` draws on the scene's own pixel grid with the palette:
score, lives, a one-line hint, a game-over line. Pixel text at scale 1 or 2,
with a dark `shadow` colour over busy art. For richer UI, draw it with Rive
itself (shapes, text, nested artboards) above the `ScriptedLayout`: sizes in
multiples of `pixelSize`, colours from the palette.

## Performance

- The G-buffer pass costs per splat and per covered pixel: keep blobs under
  ~100 000 splats for phones; the scene's art grid is small, so fill rate is
  rarely the limit.
- Shadows double the splat work; drop `shadowSize` (512) or turn shadows off
  for busy scenes and use darker ramp steps baked into materials instead.
- Bone updates copy only changed frames; a game writing its own bones every
  frame costs one small upload per object.
- Measure published builds in a browser (`rive docs gpu-performance`).
