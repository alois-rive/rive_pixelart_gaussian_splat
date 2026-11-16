// What a game (game.as) may read and call. Owned by the renderer: never edit it in a project;
// a game lives entirely in its own game.as. splat_scene.as fills this every frame, calls the
// game, then applies what the game wrote (bones, camera, look) and draws its HUD.
//
// Coordinates: the world is Y up, metres (the bake's). The HUD and the pointer use HUD pixels:
// art pixels from the top-left of the visible frame (hudW x hudH, e.g. 213 x 133 at pixelSize 3).

const FONT: StaticArray<u16> = [0, 9346, 0, 24445, 15518, 21157, 0, 9216, 10530, 8778, 24528, 1488, 20, 448, 2, 4772, 31599, 11415, 29671, 29647, 23497, 31183, 31215, 29330, 31727, 31695, 1040, 0, 5393, 3640, 17492, 25218, 0, 11245, 27566, 14627, 27502, 31143, 31140, 14699, 23533, 29847, 4714, 23469, 18727, 24557, 27501, 11114, 27556, 11123, 27565, 14478, 29842, 23407, 23402, 23549, 23213, 23186, 29351, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2728, 0, 0, 0, 0, 0, 0, 0];

// sounds (sfx.as plays them): api.sound(SFX_COIN), api.soundAt(SFX_HIT, x, y, z), api.note(60)
export const SFX_BLIP: i32 = 0;      // a menu blip, a select
export const SFX_JUMP: i32 = 1;      // a rising hop
export const SFX_COIN: i32 = 2;      // a two-note pickup
export const SFX_HIT: i32 = 3;       // a crunchy hurt
export const SFX_EXPLODE: i32 = 4;   // a low burst
export const SFX_SHOOT: i32 = 5;     // a falling pew
export const SFX_POWERUP: i32 = 6;   // a rising arpeggio
export const SFX_THUD: i32 = 7;      // a low landing
export const SFX_SPLASH: i32 = 8;    // water
export const SFX_WHOOSH: i32 = 9;    // a swing, a gust
export const SFX_NOTE: i32 = 10;     // a plucked note: api.note(midi)
export const SFX_BELL: i32 = 11;     // a long sine bell: api.note(midi, 1, 0, SFX_BELL)
export const SFX_LOSE: i32 = 12;     // game over
export const SFX_WIN: i32 = 13;      // a start, a clear, a win
export const SFX_TICK: i32 = 14;     // a quiet tick (a clock, a step)
export const SFX_POP: i32 = 15;      // a bubble, a pop
export const SFX_CLICK: i32 = 16;    // a switch, a latch
export const SFX_ZAP: i32 = 17;      // a laser, a spark

export const POINTER_DOWN: i32 = 0;
export const POINTER_MOVE: i32 = 1;
export const POINTER_UP: i32 = 2;

export class GameApi {
    // --- read every frame
    time: f64 = 0;          // seconds since the scene started
    frame: i32 = 0;         // updates so far (headless: the --advance frame number), for picking golden frames
    dt: f64 = 0;            // seconds since the last update (0 to 0.1)
    demo: bool = false;     // the game plays itself (gallery tiles, video capture); the pointer is off
    playable: bool = false; // a game sets this in start(): the pointer goes to it, and demo mode no
                            // longer turns the camera
    demoChanged: bool = false; // true for the one update where demo switched (on or off): start a fresh run
    pixelSize: f64 = 3;     // screen pixels per art (and HUD) pixel
    hudW: i32 = 0;          // the visible frame in HUD pixels
    hudH: i32 = 0;
    pointerX: f32 = -1;     // the last pointer position in HUD pixels (-1: none yet)
    pointerY: f32 = -1;
    pointerDown: bool = false;
    hoverSeen: bool = false; // a pointer moved with nothing pressed: a mouse (touch never hovers);
                             // keep hover-only conveniences (a preview, a highlight) for it

    // --- the camera and the look: copied from the scene's inputs before the game's first update;
    // what the game writes here is applied every frame
    yaw: f64 = 0;
    pitch: f64 = 0;
    distance: f64 = 0;
    orthoHeight: f64 = 0;
    perspective: bool = false;
    fov: f64 = 40;
    lookAt: bool = false;
    eyeX: f64 = 0;
    eyeY: f64 = 0;
    eyeZ: f64 = 0;
    useTarget: bool = false;
    targetX: f64 = 0;
    targetY: f64 = 0;
    targetZ: f64 = 0;
    sunYaw: f64 = 0;
    sunPitch: f64 = 0;
    keyLight: f64 = 0;
    fogMax: f64 = 0;
    horizon: f64 = 0.55;    // the sky's split (renderer.md): move it for a sunset, 2 for a flat sky
    skyBlend: f64 = 0.12;

    // --- bones (filled by the renderer from the blob's name table)
    boneCount: i32 = 0;
    names: Array<string> = new Array<string>();
    index: Array<i32> = new Array<i32>();
    restX: StaticArray<f32> = new StaticArray<f32>(64);
    restY: StaticArray<f32> = new StaticArray<f32>(64);
    restZ: StaticArray<f32> = new StaticArray<f32>(64);
    restYaw: StaticArray<f32> = new StaticArray<f32>(64);
    mats: StaticArray<f32> = new StaticArray<f32>(64 * 12);
    dirty: StaticArray<bool> = new StaticArray<bool>(64);
    // per-bone look, 4 per bone: step shift, ramp + 1 (0: its own), flash (1: unlit, top step), 0
    looks: StaticArray<f32> = new StaticArray<f32>(64 * 4);

    constructor() {
        for (let b = 0; b < 64; b++) {
            this.mats[b * 12] = 1; this.mats[b * 12 + 5] = 1; this.mats[b * 12 + 10] = 1;
        }
    }
    anyDirty: bool = false;

    // --- palette (from the blob): 0xAABBGGRR as stored; ramps 32 x 8 palette indices
    palette: StaticArray<u32> = new StaticArray<u32>(64);
    ramps: StaticArray<u32> = new StaticArray<u32>(256);
    rampLen: StaticArray<u32> = new StaticArray<u32>(32);

    // --- the camera of the last drawn frame, for picking (set by the renderer)
    camEX: f32 = 0; camEY: f32 = 0; camEZ: f32 = 0;     // eye
    camFX: f32 = 0; camFY: f32 = 0; camFZ: f32 = -1;    // forward
    camRX: f32 = 1; camRY: f32 = 0; camRZ: f32 = 0;     // right
    camUX: f32 = 0; camUY: f32 = 1; camUZ: f32 = 0;     // up
    camHW: f32 = 1; camHH: f32 = 1;                     // ortho half extents, or tan(fov/2) x aspect and tan(fov/2)
    camPersp: bool = false;
    gridOX: f32 = 0; gridOY: f32 = 0;                   // the art grid's top-left in HUD pixels
    gridW: f32 = 1; gridH: f32 = 1;                     // the art grid in art pixels

    // --- results of transform
    tx: f64 = 0; ty: f64 = 0; tz: f64 = 0;

    // --- results of pick / project
    hitX: f32 = 0; hitY: f32 = 0; hitZ: f32 = 0;
    screenX: f32 = 0; screenY: f32 = 0; screenDepth: f32 = 0;

    // --- the HUD draw list, rebuilt every frame by the game's hud()
    rectX: Array<f32> = new Array<f32>();
    rectY: Array<f32> = new Array<f32>();
    rectW: Array<f32> = new Array<f32>();
    rectH: Array<f32> = new Array<f32>();
    rectC: Array<u32> = new Array<u32>();

    seed: u32 = 12345;

    // --- the sounds asked for this frame (the renderer sends them, unless in demo mode)
    sfxKind: Array<f64> = new Array<f64>();
    sfxPitch: Array<f64> = new Array<f64>();
    sfxVol: Array<f64> = new Array<f64>();
    sfxPan: Array<f64> = new Array<f64>();
    sfxDelay: Array<f64> = new Array<f64>();

    // ---------------------------------------------------------------- bones

    // The bone index of a game bone baked with "bone": "<name>" (pools: "<name>0".."<name>N-1"), or -1.
    bone(name: string): i32 {
        for (let i = 0; i < this.names.length; i++) {
            if (this.names[i] == name) {
                return this.index[i];
            }
        }
        return -1;
    }

    // Places a game bone's object: its pivot (the bake's "position") at x, y, z, turned yawDeg about Y,
    // then pitchDeg about X, then rollDeg about Z, scaled by scale (1: as baked).
    place(b: i32, x: f64, y: f64, z: f64, yawDeg: f64 = 0, pitchDeg: f64 = 0, rollDeg: f64 = 0, scale: f64 = 1): void {
        if (b <= 0 || b >= 64) {
            return;
        }
        if (Math.abs(scale) < 0.001) {
            scale = scale < 0 ? -0.001 : 0.001; // a degenerate bone draws huge flat squares: hide() instead
        }
        let cy = Math.cos(yawDeg * Math.PI / 180), sy = Math.sin(yawDeg * Math.PI / 180);
        let cp = Math.cos(pitchDeg * Math.PI / 180), sp = Math.sin(pitchDeg * Math.PI / 180);
        let cr = Math.cos(rollDeg * Math.PI / 180), sr = Math.sin(rollDeg * Math.PI / 180);
        // R = Ry * Rx * Rz
        let r00 = cy * cr + sy * sp * sr, r01 = -cy * sr + sy * sp * cr, r02 = sy * cp;
        let r10 = cp * sr,                r11 = cp * cr,                 r12 = -sp;
        let r20 = -sy * cr + cy * sp * sr, r21 = sy * sr + cy * sp * cr, r22 = cy * cp;
        // M = T * R * S * Ry(-yaw0) * T(-p0)
        let y0 = <f64>this.restYaw[b] * Math.PI / 180;
        let c0 = Math.cos(y0), s0 = Math.sin(y0);
        // Ry(-yaw0) = [[c0, 0, -s0], [0, 1, 0], [s0, 0, c0]]
        let a00 = (r00 * c0 + r02 * s0) * scale, a01 = r01 * scale, a02 = (-r00 * s0 + r02 * c0) * scale;
        let a10 = (r10 * c0 + r12 * s0) * scale, a11 = r11 * scale, a12 = (-r10 * s0 + r12 * c0) * scale;
        let a20 = (r20 * c0 + r22 * s0) * scale, a21 = r21 * scale, a22 = (-r20 * s0 + r22 * c0) * scale;
        let px = <f64>this.restX[b], py = <f64>this.restY[b], pz = <f64>this.restZ[b];
        let m = b * 12;
        this.mats[m] = <f32>a00; this.mats[m + 1] = <f32>a01; this.mats[m + 2] = <f32>a02;
        this.mats[m + 3] = <f32>(x - (a00 * px + a01 * py + a02 * pz));
        this.mats[m + 4] = <f32>a10; this.mats[m + 5] = <f32>a11; this.mats[m + 6] = <f32>a12;
        this.mats[m + 7] = <f32>(y - (a10 * px + a11 * py + a12 * pz));
        this.mats[m + 8] = <f32>a20; this.mats[m + 9] = <f32>a21; this.mats[m + 10] = <f32>a22;
        this.mats[m + 11] = <f32>(z - (a20 * px + a21 * py + a22 * pz));
        this.dirty[b] = true;
        this.anyDirty = true;
    }

    // Squash and stretch about the pivot: sx, sy, sz per axis (in the object's turned frame),
    // optionally pitched and rolled like place().
    placeScaled(b: i32, x: f64, y: f64, z: f64, yawDeg: f64, sx: f64, sy: f64, sz: f64,
                pitchDeg: f64 = 0, rollDeg: f64 = 0): void {
        this.place(b, x, y, z, yawDeg);
        if (b <= 0 || b >= 64) {
            return;
        }
        if (pitchDeg != 0 || rollDeg != 0) {
            this.placeGeneral(b, x, y, z, yawDeg, pitchDeg, rollDeg, sx, sy, sz);
            return;
        }
        // M = T * Ry * S(sx,sy,sz) * Ry(-yaw0) * T(-p0): rebuild with the per-axis scale
        let yy = yawDeg * Math.PI / 180, y0 = <f64>this.restYaw[b] * Math.PI / 180;
        let c = Math.cos(yy), s = Math.sin(yy), c0 = Math.cos(y0), s0 = Math.sin(y0);
        // Ry*S = [[c*sx,0,s*sz],[0,sy,0],[-s*sx,0,c*sz]] ; times Ry(-yaw0) = [[c0,0,-s0],[0,1,0],[s0,0,c0]]
        let a00 = c * sx * c0 + s * sz * s0, a02 = -c * sx * s0 + s * sz * c0;
        let a20 = -s * sx * c0 + c * sz * s0, a22 = s * sx * s0 + c * sz * c0;
        let px = <f64>this.restX[b], py = <f64>this.restY[b], pz = <f64>this.restZ[b];
        let m = b * 12;
        this.mats[m] = <f32>a00; this.mats[m + 1] = 0; this.mats[m + 2] = <f32>a02;
        this.mats[m + 3] = <f32>(x - (a00 * px + a02 * pz));
        this.mats[m + 4] = 0; this.mats[m + 5] = <f32>sy; this.mats[m + 6] = 0;
        this.mats[m + 7] = <f32>(y - sy * py);
        this.mats[m + 8] = <f32>a20; this.mats[m + 9] = 0; this.mats[m + 10] = <f32>a22;
        this.mats[m + 11] = <f32>(z - (a20 * px + a22 * pz));
    }

    private placeGeneral(b: i32, x: f64, y: f64, z: f64, yawDeg: f64, pitchDeg: f64, rollDeg: f64,
                         sx: f64, sy: f64, sz: f64): void {
        let cy = Math.cos(yawDeg * Math.PI / 180), sy0 = Math.sin(yawDeg * Math.PI / 180);
        let cp = Math.cos(pitchDeg * Math.PI / 180), sp = Math.sin(pitchDeg * Math.PI / 180);
        let cr = Math.cos(rollDeg * Math.PI / 180), sr = Math.sin(rollDeg * Math.PI / 180);
        // R * S, R = Ry * Rx * Rz
        let r00 = (cy * cr + sy0 * sp * sr) * sx, r01 = (-cy * sr + sy0 * sp * cr) * sy, r02 = sy0 * cp * sz;
        let r10 = cp * sr * sx,                   r11 = cp * cr * sy,                    r12 = -sp * sz;
        let r20 = (-sy0 * cr + cy * sp * sr) * sx, r21 = (sy0 * sr + cy * sp * cr) * sy, r22 = cy * cp * sz;
        let y0 = <f64>this.restYaw[b] * Math.PI / 180;
        let c0 = Math.cos(y0), s0 = Math.sin(y0);
        let a00 = r00 * c0 + r02 * s0, a01 = r01, a02 = -r00 * s0 + r02 * c0;
        let a10 = r10 * c0 + r12 * s0, a11 = r11, a12 = -r10 * s0 + r12 * c0;
        let a20 = r20 * c0 + r22 * s0, a21 = r21, a22 = -r20 * s0 + r22 * c0;
        let px = <f64>this.restX[b], py = <f64>this.restY[b], pz = <f64>this.restZ[b];
        let m = b * 12;
        this.mats[m] = <f32>a00; this.mats[m + 1] = <f32>a01; this.mats[m + 2] = <f32>a02;
        this.mats[m + 3] = <f32>(x - (a00 * px + a01 * py + a02 * pz));
        this.mats[m + 4] = <f32>a10; this.mats[m + 5] = <f32>a11; this.mats[m + 6] = <f32>a12;
        this.mats[m + 7] = <f32>(y - (a10 * px + a11 * py + a12 * pz));
        this.mats[m + 8] = <f32>a20; this.mats[m + 9] = <f32>a21; this.mats[m + 10] = <f32>a22;
        this.mats[m + 11] = <f32>(z - (a20 * px + a21 * py + a22 * pz));
        this.dirty[b] = true;
        this.anyDirty = true;
    }

    // Where a point of a placed object is now: give it where the bake put it (its rest position,
    // e.g. restX[b] + an offset to a nozzle, a hand, a muzzle); the result is in tx, ty, tz.
    // Attach one bone to another this way: place the child at the parent's transformed point.
    transform(b: i32, x: f64, y: f64, z: f64): void {
        let m = b * 12;
        this.tx = <f64>this.mats[m] * x + <f64>this.mats[m + 1] * y + <f64>this.mats[m + 2] * z + <f64>this.mats[m + 3];
        this.ty = <f64>this.mats[m + 4] * x + <f64>this.mats[m + 5] * y + <f64>this.mats[m + 6] * z + <f64>this.mats[m + 7];
        this.tz = <f64>this.mats[m + 8] * x + <f64>this.mats[m + 9] * y + <f64>this.mats[m + 10] * z + <f64>this.mats[m + 11];
    }

    // Places a game bone from a rotation matrix (rows r0*, r1*, r2*: world from the object's
    // as-baked axes) instead of angles: leg IK, rolling balls, anything already kept as a matrix.
    // The pivot lands at x, y, z; scale as in place().
    placeMatrix(b: i32, r00: f64, r01: f64, r02: f64, r10: f64, r11: f64, r12: f64,
                r20: f64, r21: f64, r22: f64, x: f64, y: f64, z: f64, scale: f64 = 1): void {
        if (b <= 0 || b >= 64) {
            return;
        }
        let y0 = <f64>this.restYaw[b] * Math.PI / 180;
        let c0 = Math.cos(y0), s0 = Math.sin(y0);
        let a00 = (r00 * c0 + r02 * s0) * scale, a01 = r01 * scale, a02 = (-r00 * s0 + r02 * c0) * scale;
        let a10 = (r10 * c0 + r12 * s0) * scale, a11 = r11 * scale, a12 = (-r10 * s0 + r12 * c0) * scale;
        let a20 = (r20 * c0 + r22 * s0) * scale, a21 = r21 * scale, a22 = (-r20 * s0 + r22 * c0) * scale;
        let px = <f64>this.restX[b], py = <f64>this.restY[b], pz = <f64>this.restZ[b];
        let m = b * 12;
        this.mats[m] = <f32>a00; this.mats[m + 1] = <f32>a01; this.mats[m + 2] = <f32>a02;
        this.mats[m + 3] = <f32>(x - (a00 * px + a01 * py + a02 * pz));
        this.mats[m + 4] = <f32>a10; this.mats[m + 5] = <f32>a11; this.mats[m + 6] = <f32>a12;
        this.mats[m + 7] = <f32>(y - (a10 * px + a11 * py + a12 * pz));
        this.mats[m + 8] = <f32>a20; this.mats[m + 9] = <f32>a21; this.mats[m + 10] = <f32>a22;
        this.mats[m + 11] = <f32>(z - (a20 * px + a21 * py + a22 * pz));
        this.dirty[b] = true;
        this.anyDirty = true;
    }

    // Attaches bone b to bone parent: b is placed as place() would put it while the parent sits at
    // its baked rest (x, y, z and the angles are in that rest world: a hand at the rest arm's tip),
    // then carried by wherever the parent is now. Place the parent first, every frame.
    placeChild(b: i32, parent: i32, x: f64, y: f64, z: f64, yawDeg: f64 = 0, pitchDeg: f64 = 0,
               rollDeg: f64 = 0, scale: f64 = 1): void {
        if (b <= 0 || b >= 64 || parent < 0 || parent >= 64) {
            return;
        }
        this.place(b, x, y, z, yawDeg, pitchDeg, rollDeg, scale);
        let p = parent * 12, m = b * 12;
        let c = new StaticArray<f32>(12);
        for (let r = 0; r < 3; r++) {
            for (let k = 0; k < 4; k++) {
                let v = this.mats[p + r * 4] * this.mats[m + k] + this.mats[p + r * 4 + 1] * this.mats[m + 4 + k]
                    + this.mats[p + r * 4 + 2] * this.mats[m + 8 + k];
                c[r * 4 + k] = k == 3 ? v + this.mats[p + r * 4 + 3] : v;
            }
        }
        for (let i = 0; i < 12; i++) {
            this.mats[m + i] = c[i];
        }
    }

    // Per-bone looks (the whole object; a skinned splat follows its first joint). They stay until
    // changed; lookReset clears all three.
    // shade: move every splat `steps` along its ramp (+ lighter, - darker): hurt, frozen, selected.
    shade(b: i32, steps: f64): void {
        if (b >= 0 && b < 64) {
            this.looks[b * 4] = <f32>steps;
        }
    }
    // recolor: draw the object with ramp `ramp` (palette.json order) instead of its own, keeping
    // each splat's step (clamped to the new ramp): one pool for every team or colour. -1: its own.
    recolor(b: i32, ramp: i32): void {
        if (b >= 0 && b < 64) {
            this.looks[b * 4 + 1] = <f32>(ramp + 1);
        }
    }
    // flash: draw the object unlit at its ramp's lightest step (a hit flash: a frame or two).
    flash(b: i32, on: bool): void {
        if (b >= 0 && b < 64) {
            this.looks[b * 4 + 2] = on ? 1 : 0;
        }
    }
    lookReset(b: i32): void {
        if (b >= 0 && b < 64) {
            this.looks[b * 4] = 0; this.looks[b * 4 + 1] = 0; this.looks[b * 4 + 2] = 0;
        }
    }

    // Takes a game bone's object out of the picture (moved far below everything).
    hide(b: i32): void {
        if (b <= 0 || b >= 64) {
            return;
        }
        let m = b * 12;
        for (let i = 0; i < 12; i++) {
            this.mats[m + i] = 0;
        }
        this.mats[m] = 1; this.mats[m + 5] = 1; this.mats[m + 10] = 1;
        this.mats[m + 7] = -10000;
        this.dirty[b] = true;
        this.anyDirty = true;
    }

    // Back where the bake put it.
    reset(b: i32): void {
        this.place(b, this.restX[b], this.restY[b], this.restZ[b], this.restYaw[b]);
    }

    // ---------------------------------------------------------------- picking

    // The point where the pointer's ray (HUD pixels hx, hy) meets the horizontal plane y = planeY:
    // hitX/hitY/hitZ. False when the ray runs parallel or away from it.
    pick(hx: f32, hy: f32, planeY: f32): bool {
        let nx = ((hx - this.gridOX) / this.gridW) * 2 - 1;
        let ny = 1 - ((hy - this.gridOY) / this.gridH) * 2;
        let ox = this.camEX, oy = this.camEY, oz = this.camEZ;
        let dx = this.camFX, dy = this.camFY, dz = this.camFZ;
        if (this.camPersp) {
            dx += (this.camRX * nx * this.camHW + this.camUX * ny * this.camHH);
            dy += (this.camRY * nx * this.camHW + this.camUY * ny * this.camHH);
            dz += (this.camRZ * nx * this.camHW + this.camUZ * ny * this.camHH);
        } else {
            ox += this.camRX * nx * this.camHW + this.camUX * ny * this.camHH;
            oy += this.camRY * nx * this.camHW + this.camUY * ny * this.camHH;
            oz += this.camRZ * nx * this.camHW + this.camUZ * ny * this.camHH;
        }
        if (Mathf.abs(dy) < 1e-5) {
            return false;
        }
        let t = (planeY - oy) / dy;
        if (t < 0) {
            return false;
        }
        this.hitX = ox + dx * t;
        this.hitY = planeY;
        this.hitZ = oz + dz * t;
        return true;
    }

    // The pointer ray's hit on any plane n . p = d (n need not be unit): hitX/hitY/hitZ. A vertical
    // play wall facing the camera: pickPlane(hx, hy, 0, 0, 1, z).
    pickPlane(hx: f32, hy: f32, nx: f32, ny: f32, nz: f32, d: f32): bool {
        let sx = ((hx - this.gridOX) / this.gridW) * 2 - 1;
        let sy = 1 - ((hy - this.gridOY) / this.gridH) * 2;
        let ox = this.camEX, oy = this.camEY, oz = this.camEZ;
        let dx = this.camFX, dy = this.camFY, dz = this.camFZ;
        if (this.camPersp) {
            dx += this.camRX * sx * this.camHW + this.camUX * sy * this.camHH;
            dy += this.camRY * sx * this.camHW + this.camUY * sy * this.camHH;
            dz += this.camRZ * sx * this.camHW + this.camUZ * sy * this.camHH;
        } else {
            ox += this.camRX * sx * this.camHW + this.camUX * sy * this.camHH;
            oy += this.camRY * sx * this.camHW + this.camUY * sy * this.camHH;
            oz += this.camRZ * sx * this.camHW + this.camUZ * sy * this.camHH;
        }
        let den = nx * dx + ny * dy + nz * dz;
        if (Mathf.abs(den) < 1e-6) {
            return false;
        }
        let t = (d - (nx * ox + ny * oy + nz * oz)) / den;
        if (t < 0) {
            return false;
        }
        this.hitX = ox + dx * t;
        this.hitY = oy + dy * t;
        this.hitZ = oz + dz * t;
        return true;
    }

    // Where a world point shows, in HUD pixels: screenX, screenY (and screenDepth along the view).
    project(x: f32, y: f32, z: f32): bool {
        let dx = x - this.camEX, dy = y - this.camEY, dz = z - this.camEZ;
        let depth = dx * this.camFX + dy * this.camFY + dz * this.camFZ;
        let r = dx * this.camRX + dy * this.camRY + dz * this.camRZ;
        let u = dx * this.camUX + dy * this.camUY + dz * this.camUZ;
        let nx: f32, ny: f32;
        if (this.camPersp) {
            if (depth < 0.01) {
                return false;
            }
            nx = r / (depth * this.camHW);
            ny = u / (depth * this.camHH);
        } else {
            nx = r / this.camHW;
            ny = u / this.camHH;
        }
        this.screenX = this.gridOX + (nx + 1) * 0.5 * this.gridW;
        this.screenY = this.gridOY + (1 - ny) * 0.5 * this.gridH;
        this.screenDepth = depth;
        return true;
    }

    // ---------------------------------------------------------------- sound

    // Plays a sound effect (SFX_*): pitch multiplies its frequency, pan is -1 left .. 1 right.
    // Silent in demo mode (a gallery of tiles stays quiet until one is played). Never draw
    // api.rand() to decide a sound: it would change what the demo does.
    // delay: seconds from now (a jingle's later notes, a crash after a whistle), sample-accurate.
    sound(kind: i32, pitch: f64 = 1, volume: f64 = 1, pan: f64 = 0, delay: f64 = 0): void {
        if (this.sfxKind.length >= 64) {
            return;
        }
        this.sfxKind.push(<f64>kind);
        this.sfxPitch.push(pitch);
        this.sfxVol.push(volume);
        this.sfxPan.push(pan);
        this.sfxDelay.push(Math.max(0, delay));
    }

    // The pan (-0.8 .. 0.8) of where a world point shows; leaves screenX/screenY/screenDepth alone.
    panAt(x: f64, y: f64, z: f64): f64 {
        let sx = this.screenX, sy = this.screenY, sd = this.screenDepth;
        let pan = 0.0;
        if (this.project(<f32>x, <f32>y, <f32>z) && this.hudW > 0) {
            pan = Math.min(Math.max((<f64>this.screenX / <f64>this.hudW) * 2 - 1, -1), 1) * 0.8;
        }
        this.screenX = sx; this.screenY = sy; this.screenDepth = sd;
        return pan;
    }

    // A sound panned by where a world point shows on screen.
    soundAt(kind: i32, x: f64, y: f64, z: f64, pitch: f64 = 1, volume: f64 = 1, delay: f64 = 0): void {
        this.sound(kind, pitch, volume, this.panAt(x, y, z), delay);
    }

    // A tuned note (MIDI number, 60 = middle C) on SFX_NOTE or SFX_BELL: melodies, chords, chimes.
    // A few notes with growing delays make a jingle: note(72), note(76, 1, 0, SFX_NOTE, 0.12), ...
    note(midi: f64, volume: f64 = 1, pan: f64 = 0, kind: i32 = SFX_NOTE, delay: f64 = 0): void {
        this.sound(kind, Math.pow(2, (midi - 69) / 12), volume, pan, delay);
    }

    // A tuned note panned by a world point.
    noteAt(midi: f64, x: f64, y: f64, z: f64, volume: f64 = 1, kind: i32 = SFX_NOTE, delay: f64 = 0): void {
        this.sound(kind, Math.pow(2, (midi - 69) / 12), volume, this.panAt(x, y, z), delay);
    }

    // ---------------------------------------------------------------- random (deterministic)

    rand(): f64 {
        this.seed = this.seed * 1664525 + 1013904223;
        return <f64>(this.seed >> 8) / 16777216.0;
    }

    range(a: f64, b: f64): f64 {
        return a + (b - a) * this.rand();
    }

    // ---------------------------------------------------------------- HUD (call from hud() only)

    // A palette colour: by ramp and step (the palette's ramps, in palette.json order), or by index.
    rampColor(ramp: i32, step: i32): u32 {
        let r = <u32>Math.max(0, Math.min(31, ramp));
        let n = this.rampLen[r] > 0 ? this.rampLen[r] : 1;
        let s = <u32>Math.max(0, Math.min(<f64>(n - 1), <f64>step));
        return this.palette[this.ramps[r * 8 + s]];
    }

    paletteColor(i: i32): u32 {
        return this.palette[<u32>Math.max(0, Math.min(63, i))];
    }

    rect(x: f32, y: f32, w: f32, h: f32, color: u32): void {
        this.rectX.push(Mathf.round(x)); this.rectY.push(Mathf.round(y));
        this.rectW.push(Mathf.round(w)); this.rectH.push(Mathf.round(h));
        this.rectC.push(color);
    }

    // A one-pixel line (a string, a laser, an aim guide), whole HUD pixels, ends included.
    line(x0: f32, y0: f32, x1: f32, y1: f32, color: u32): void {
        let ax = <i32>Mathf.round(x0), ay = <i32>Mathf.round(y0);
        let bx = <i32>Mathf.round(x1), by = <i32>Mathf.round(y1);
        let dx = bx > ax ? bx - ax : ax - bx, dy = by > ay ? ay - by : by - ay;
        let sx = ax < bx ? 1 : -1, sy = ay < by ? 1 : -1;
        let err = dx + dy;
        for (let k = 0; k < 4096; k++) {
            this.rect(<f32>ax, <f32>ay, 1, 1, color);
            if (ax == bx && ay == by) {
                break;
            }
            let e2 = 2 * err;
            if (e2 >= dy) { err += dy; ax += sx; }
            if (e2 <= dx) { err += dx; ay += sy; }
        }
    }

    // Width in HUD pixels of text drawn at this scale (3 x 5 glyphs, 1 pixel apart).
    textWidth(text: string, scale: i32 = 1): f32 {
        return <f32>(text.length * 4 - 1) * <f32>scale;
    }

    // Draws text (A-Z, 0-9, space, : - . ! ? / + % < > * ' , = ( ) # x; lowercase prints as capitals).
    // shadow: a colour drawn one pixel down-right first (0: none), for text over busy art.
    text(x: f32, y: f32, text: string, color: u32, scale: i32 = 1, shadow: u32 = 0): void {
        if (shadow != 0) {
            this.glyphs(x + <f32>scale, y + <f32>scale, text, shadow, scale);
        }
        this.glyphs(x, y, text, color, scale);
    }

    textCentered(y: f32, text: string, color: u32, scale: i32 = 1, shadow: u32 = 0): void {
        let x = Mathf.floor((<f32>this.hudW - this.textWidth(text, scale)) * 0.5);
        this.text(x, y, text, color, scale, shadow);
    }

    private glyphs(x: f32, y: f32, text: string, color: u32, scale: i32): void {
        let s = <f32>scale;
        for (let i = 0; i < text.length; i++) {
            let c = text.charCodeAt(i);
            if (c >= 97 && c <= 122) {
                c -= 32;
            }
            if (c < 32 || c > 127) {
                continue;
            }
            let bits = <u32>FONT[c - 32];
            let gx = x + <f32>(i * 4) * s;
            for (let row = 0; row < 5; row++) {
                for (let col = 0; col < 3; col++) {
                    if ((bits >> <u32>(14 - row * 3 - col)) & 1) {
                        this.rect(gx + <f32>col * s, y + <f32>row * s, s, s, color);
                    }
                }
            }
        }
    }

    clearHud(): void {
        this.rectX.length = 0; this.rectY.length = 0; this.rectW.length = 0;
        this.rectH.length = 0; this.rectC.length = 0;
    }
}
