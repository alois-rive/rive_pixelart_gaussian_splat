// Kick Park: a skateboard game in one sunny little skatepark. The skater (Marlo) keeps rolling and
// steers towards the pointer (drag on touch); press and hold still to crouch, release to ollie (the
// longer the wind-up, the higher); off a ramp lip or the kicker the air is big. A quick swipe in the
// air picks a trick by direction: up a FLICK (the board rolls over), sideways a TWIRL (180 or 360 by
// length), down a GRAB. Land clean (trick finished, board straight) to add it to the combo; the
// multiplier grows with every different trick and every chained landing (ollie again during the
// wheelie after a landing), and a grind on the ledge or the rail keeps it going. Land mid-trick and the
// skater bails: the combo is lost. 75 second sessions; the next click starts a new one.
// Demo mode (api.demo) skates lines through the park like a decent player and bails now and then.
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP, SFX_TICK, SFX_CLICK, SFX_POP, SFX_WHOOSH, SFX_THUD,
    SFX_HIT, SFX_NOTE, SFX_BELL, SFX_WIN, SFX_BLIP, SFX_ZAP } from "./game_api";

// ------------------------------------------------------------------ the park (models/env/make_env.py)
const BX: f64 = -8.0;  const BZ: f64 = 0.5;            // bowl centre
const RF: f64 = 1.2;   const RT: f64 = 2.0;  const BD: f64 = 1.4;
const QH: f64 = 1.2;   const QR: f64 = 2.0;             // quarter pipes
const Q1X0: f64 = -5.0; const Q1X1: f64 = 5.0; const Q1Z: f64 = -7.2;   // back QP: rises to -z
const Q2Z0: f64 = -6.0; const Q2Z1: f64 = 2.0; const Q2X: f64 = 9.6;    // right QP: rises to +x
const FX0: f64 = 1.0; const FX1: f64 = 4.0; const FZ0: f64 = 0.5; const FZ1: f64 = 2.5;
const FH: f64 = 0.45; const FRL: f64 = 1.2;             // fun box
const KX0: f64 = -4.2; const KX1: f64 = -3.0; const KZ0: f64 = -5.3; const KZ1: f64 = -3.7; const KH: f64 = 0.6;
const XMIN: f64 = -12.25; const XMAX: f64 = 12.75; const ZMIN: f64 = -10.2; const ZMAX: f64 = 9.25;
// grind lines: ax, az, bx, bz, height
const NRAIL: i32 = 3;
const RAILS: StaticArray<f64> = [-4.0, 6.0, 1.5, 6.0, 0.55,   FX0, FZ0, FX1, FZ0, FH,   FX0, FZ1, FX1, FZ1, FH];

// ------------------------------------------------------------------ physics
const G: f64 = 11.0;
const CRUISE: f64 = 7.0;     // pushes up to this on the flat
const VMAX: f64 = 10.0;
const SESSION: f64 = 75.0;
const WINDOW: f64 = 1.4;     // the wheelie after a clean landing: ollie again inside it to chain

// the skater's rig (models/skater/make_skater.py, glTF axes: nose +X, chest +Z, up +Y)
const HIP_X: f64 = 0.10;  const HIP_Y: f64 = 0.70;
const FOOT_X: f64 = 0.31; const DECK_TOP: f64 = 0.22; const BOARD_Y: f64 = 0.195;
const ANKLE_UP: f64 = 0.12;  // ankle above the sole
const L_LEG: f64 = 0.2065;   // thigh and shin
const SH_X: f64 = 0.195;  const SH_Y: f64 = 1.06;

// tricks: name, seconds, points, kind (0 flip, 1 spin, 2 grab), amount (degrees)
const T_FLICK: i32 = 0; const T_DFLICK: i32 = 1; const T_HALF: i32 = 2; const T_FULL: i32 = 3;
const T_SUNNY: i32 = 4; const T_KITE: i32 = 5; const T_OLLIE: i32 = 6; const T_AIR: i32 = 7;
const T_RAIL: i32 = 8; const T_LEDGE: i32 = 9; const T_WHEELIE: i32 = 10; const NT: i32 = 11;
const TNAME: StaticArray<string> = ["FLICK", "DOUBLE FLICK", "HALF TWIRL", "FULL TWIRL", "SUNNY GRAB", "KITE GRAB",
    "OLLIE", "AIR", "RAIL GRIND", "LEDGE GRIND", "WHEELIE"];
const TDUR: StaticArray<f64> = [0.40, 0.64, 0.42, 0.70, 0.48, 0.62, 0, 0, 0, 0, 0];
const TPTS: StaticArray<i32> = [100, 260, 120, 300, 140, 220, 30, 50, 60, 60, 20];
const TKIND: StaticArray<i32> = [0, 0, 1, 1, 2, 2, -1, -1, -1, -1, -1];
const TAMT: StaticArray<f64> = [360, 720, 180, 360, 0, 0, 0, 0, 0, 0, 0];

const GROUND: i32 = 0; const AIR: i32 = 1; const GRIND: i32 = 2; const BAIL: i32 = 3;
const READY: i32 = 0; const RUN: i32 = 1; const OVER: i32 = 2;

// a combo climbs a major arpeggio
const JINGLE: StaticArray<f64> = [72, 76, 79, 84, 88, 91, 96, 100, 103];

// demo lines: entry x, z, axis x, z, trigger x, z, kind (0 kicker, 1 vert QP, 2 rail/ledge, 3 fun box, 4 bowl, 5 flat)
const NF: i32 = 9;
const FEAT: StaticArray<f64> = [
    -10.0, -4.5,  1, 0,   KX1, -4.5,  0,    // kicker
     4.0, -2.0,   1, 0,   11.2, -2.0, 1,    // right QP
     0.0, -2.5,   0, -1,  0.0, -8.8,  1,    // back QP
    -10.0, 6.0,   1, 0,  -4.0, 6.0,   2,    // rail, heading +x
    11.5, 6.0,   -1, 0,   1.5, 6.0,   2,    // rail, heading -x
    -4.4, 0.3,    1, 0,   FX0, 0.3,   2,    // front ledge, heading +x
    11.5, 2.7,   -1, 0,   FX1, 2.7,   2,    // back ledge, heading -x
    -3.0, 1.5,    1, 0,   FX1, 1.5,   3,    // over the fun box
    -1.5, 0.6,   -1, 0,   BX, 0.6,    4];   // through the bowl

function clamp(v: f64, a: f64, b: f64): f64 { return v < a ? a : (v > b ? b : v); }
function wrap(a: f64): f64 {
    while (a > Math.PI) a -= 2 * Math.PI;
    while (a < -Math.PI) a += 2 * Math.PI;
    return a;
}
function ease(p: f64): f64 { return p * p * (3 - 2 * p); }

// ------------------------------------------------------------------ the surface: height and gradient
let sY: f64 = 0, sGX: f64 = 0, sGZ: f64 = 0;
function surf(x: f64, z: f64): void {
    let y = 0.0, gx = 0.0, gz = 0.0;
    let dx = x - BX, dz = z - BZ;
    let r = Math.sqrt(dx * dx + dz * dz);
    let bs = Math.sqrt(RT * RT - (RT - BD) * (RT - BD));
    if (r < RF + bs) {
        let s = r - RF;
        if (s <= 0) {
            y = -BD;
        } else {
            let q = Math.sqrt(Math.max(RT * RT - s * s, 1e-4));
            y = -BD + RT - q;
            let d = s / q;
            gx = d * dx / r; gz = d * dz / r;
        }
    }
    let qs = Math.sqrt(QR * QR - (QR - QH) * (QR - QH));
    if (x >= Q1X0 && x <= Q1X1) {
        let d = Q1Z - z;
        if (d > 0) {
            let yy = QH, dd = 0.0;
            if (d < qs) { let q = Math.sqrt(Math.max(QR * QR - d * d, 1e-4)); yy = QR - q; dd = -d / q; }
            if (yy > y) { y = yy; gx = 0; gz = dd; }
        }
    }
    if (z >= Q2Z0 && z <= Q2Z1) {
        let d = x - Q2X;
        if (d > 0) {
            let yy = QH, dd = 0.0;
            if (d < qs) { let q = Math.sqrt(Math.max(QR * QR - d * d, 1e-4)); yy = QR - q; dd = d / q; }
            if (yy > y) { y = yy; gx = dd; gz = 0; }
        }
    }
    if (z >= FZ0 && z <= FZ1 && x >= FX0 - FRL && x <= FX1 + FRL) {
        let yy = FH, dd = 0.0;
        if (x < FX0) { yy = FH * (x - (FX0 - FRL)) / FRL; dd = FH / FRL; }
        else if (x > FX1) { yy = FH * ((FX1 + FRL) - x) / FRL; dd = -FH / FRL; }
        if (yy > y) { y = yy; gx = dd; gz = 0; }
    }
    if (z >= KZ0 && z <= KZ1 && x >= KX0 && x <= KX1) {
        let yy = KH * (x - KX0) / (KX1 - KX0);
        if (yy > y) { y = yy; gx = KH / (KX1 - KX0); gz = 0; }
    }
    sY = y; sGX = gx; sGZ = gz;
}
function hAt(x: f64, z: f64): f64 { surf(x, z); return sY; }

// ------------------------------------------------------------------ 3x3 rotations (row-major)
class M3 {
    m: StaticArray<f64> = new StaticArray<f64>(9);
    ident(): M3 { for (let i = 0; i < 9; i++) this.m[i] = (i % 4 == 0) ? 1 : 0; return this; }
    // columns X, Y, Z
    cols(xx: f64, xy: f64, xz: f64, yx: f64, yy: f64, yz: f64, zx: f64, zy: f64, zz: f64): M3 {
        this.m[0] = xx; this.m[1] = yx; this.m[2] = zx;
        this.m[3] = xy; this.m[4] = yy; this.m[5] = zy;
        this.m[6] = xz; this.m[7] = yz; this.m[8] = zz;
        return this;
    }
    axis(ax: i32, deg: f64): M3 {
        let c = Math.cos(deg * Math.PI / 180), s = Math.sin(deg * Math.PI / 180);
        if (ax == 0) return this.cols(1, 0, 0, 0, c, s, 0, -s, c);
        if (ax == 1) return this.cols(c, 0, -s, 0, 1, 0, s, 0, c);
        return this.cols(c, s, 0, -s, c, 0, 0, 0, 1);
    }
    mul(a: M3, b: M3): M3 {   // this = a * b (this must not be a or b)
        for (let r = 0; r < 3; r++) {
            for (let c = 0; c < 3; c++) {
                this.m[r * 3 + c] = a.m[r * 3] * b.m[c] + a.m[r * 3 + 1] * b.m[3 + c] + a.m[r * 3 + 2] * b.m[6 + c];
            }
        }
        return this;
    }
    copy(a: M3): M3 { for (let i = 0; i < 9; i++) this.m[i] = a.m[i]; return this; }
}
let vX: f64 = 0, vY: f64 = 0, vZ: f64 = 0;
function apply(R: M3, x: f64, y: f64, z: f64): void {
    vX = R.m[0] * x + R.m[1] * y + R.m[2] * z;
    vY = R.m[3] * x + R.m[4] * y + R.m[5] * z;
    vZ = R.m[6] * x + R.m[7] * y + R.m[8] * z;
}
// A rotation taking the rest "down" (-Y) onto the direction (dx, dy, dz), the rest +Z towards (bx, by, bz).
function aim(out: M3, dx: f64, dy: f64, dz: f64, bx: f64, by: f64, bz: f64): void {
    let l = Math.sqrt(dx * dx + dy * dy + dz * dz);
    let yx = -dx / l, yy = -dy / l, yz = -dz / l;
    let k = bx * yx + by * yy + bz * yz;
    let zx = bx - k * yx, zy = by - k * yy, zz = bz - k * yz;
    let zl = Math.sqrt(zx * zx + zy * zy + zz * zz);
    if (zl < 1e-6) { zx = 1; zy = 0; zz = 0; zl = 1; }
    zx /= zl; zy /= zl; zz /= zl;
    let xx = yy * zz - yz * zy, xy = yz * zx - yx * zz, xz = yx * zy - yy * zx;
    out.cols(xx, xy, xz, yx, yy, yz, zx, zy, zz);
}
// Writes a game bone: rotation R about its baked pivot, the pivot placed at (x, y, z).
function setBone(api: GameApi, b: i32, R: M3, x: f64, y: f64, z: f64): void {
    if (b <= 0 || b >= 64) return;
    let px = <f64>api.restX[b], py = <f64>api.restY[b], pz = <f64>api.restZ[b];
    let m = b * 12;
    for (let r = 0; r < 3; r++) {
        let a0 = R.m[r * 3], a1 = R.m[r * 3 + 1], a2 = R.m[r * 3 + 2];
        api.mats[m + r * 4] = <f32>a0; api.mats[m + r * 4 + 1] = <f32>a1; api.mats[m + r * 4 + 2] = <f32>a2;
        let t = r == 0 ? x : (r == 1 ? y : z);
        api.mats[m + r * 4 + 3] = <f32>(t - (a0 * px + a1 * py + a2 * pz));
    }
    api.dirty[b] = true;
    api.anyDirty = true;
}
// The same with a uniform scale (pool particles).
function setScaled(api: GameApi, b: i32, s: f64, x: f64, y: f64, z: f64): void {
    if (b <= 0 || b >= 64) return;
    if (s < 0.06) { api.hide(b); return; }
    api.place(b, x, y, z, 0, 0, 0, s);
}

export class Game {
    // bones
    bBoard: i32 = -1; bTorso: i32 = -1;
    bArm: StaticArray<i32> = new StaticArray<i32>(2);
    bThigh: StaticArray<i32> = new StaticArray<i32>(2);
    bShin: StaticArray<i32> = new StaticArray<i32>(2);
    bShoe: StaticArray<i32> = new StaticArray<i32>(2);
    bDust: StaticArray<i32> = new StaticArray<i32>(8);
    bSpark: StaticArray<i32> = new StaticArray<i32>(8);

    // the session
    mode: i32 = READY;
    t: f64 = 0;              // session time
    overT: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    bestCombo: i32 = 0;
    sessionBestCombo: i32 = 0;
    newBest: bool = false;
    wasDemo: bool = false;
    lastSec: i32 = -1;

    // the skater
    st: i32 = GROUND;
    x: f64 = 0; y: f64 = 0; z: f64 = 0;
    vx: f64 = 0; vz: f64 = 0; vy: f64 = 0;
    hd: f64 = 0;             // travel heading (direction (sin, cos))
    yaw: f64 = 0;            // board yaw on the ground; in the air the base yaw
    yawTo: f64 = 0;          // the air turn's goal (vert airs turn round)
    turnRate: f64 = 0;
    nX: f64 = 0; nY: f64 = 1; nZ: f64 = 0;   // the body's up, smoothed
    crouch: f64 = 0;         // 0..1 shown
    airT: f64 = 0;
    leftT: f64 = 0;          // when the skater last left the ground (session time)
    ollied: bool = false;
    vert: bool = false;
    takeY: f64 = 0; maxY: f64 = 0;
    trick: i32 = -1; trickT: f64 = 0; trickDir: f64 = 1;
    queue: i32 = -1; queueDir: f64 = 1;
    airTricks: StaticArray<i32> = new StaticArray<i32>(8);
    nAir: i32 = 0;
    rail: i32 = -1; railS: f64 = 0; railV: f64 = 0; grindT: f64 = 0;
    bailT: f64 = 0;
    bdX: f64 = 0; bdY: f64 = 0; bdZ: f64 = 0; bdVX: f64 = 0; bdVZ: f64 = 0; bdYaw: f64 = 0; bdSpin: f64 = 0;
    pushPh: f64 = 0;         // the push stroke's phase (0: not pushing)
    pushing: bool = false;
    wheelie: f64 = 0;        // the wheelie window left (s)
    landSquash: f64 = 0;

    // the combo
    combo: StaticArray<i32> = new StaticArray<i32>(32);
    nCombo: i32 = 0;
    comboPts: i32 = 0;
    chains: i32 = 0;
    seen: StaticArray<bool> = new StaticArray<bool>(NT);
    nSeen: i32 = 0;

    // input
    pressing: bool = false;
    armed: bool = false;     // the press winds up an ollie (held still)
    holdT: f64 = 0;
    swX: f32 = 0; swY: f32 = 0; swT: f64 = 0;   // the swipe's origin in the air
    swiping: bool = false;
    steerX: f32 = -1; steerY: f32 = -1;         // where the skater heads (HUD pixels, re-picked each frame)
    tgtX: f64 = 0; tgtZ: f64 = 0; hasTgt: bool = false;
    startClick: bool = false;

    // camera
    camX: f64 = 0; camY: f64 = 0; camZ: f64 = 0;

    // particles
    dX: StaticArray<f64> = new StaticArray<f64>(8); dY: StaticArray<f64> = new StaticArray<f64>(8);
    dZ: StaticArray<f64> = new StaticArray<f64>(8); dVX: StaticArray<f64> = new StaticArray<f64>(8);
    dVY: StaticArray<f64> = new StaticArray<f64>(8); dVZ: StaticArray<f64> = new StaticArray<f64>(8);
    dT: StaticArray<f64> = new StaticArray<f64>(8); dS: StaticArray<f64> = new StaticArray<f64>(8);
    dNext: i32 = 0;
    pX: StaticArray<f64> = new StaticArray<f64>(8); pY: StaticArray<f64> = new StaticArray<f64>(8);
    pZ: StaticArray<f64> = new StaticArray<f64>(8); pVX: StaticArray<f64> = new StaticArray<f64>(8);
    pVY: StaticArray<f64> = new StaticArray<f64>(8); pVZ: StaticArray<f64> = new StaticArray<f64>(8);
    pT: StaticArray<f64> = new StaticArray<f64>(8);
    pNext: i32 = 0;
    sparkT: f64 = 0;

    // HUD pops
    msg: string = ""; msgT: f64 = 9; msgCol: i32 = 0;
    pop: string = ""; popT: f64 = 9; popX: f64 = 0; popY: f64 = 0; popZ: f64 = 0;
    lastTrick: string = ""; lastTrickT: f64 = 9;

    // sound
    tickIn: i32 = 0;
    scrapeIn: i32 = 0;

    // demo
    dF: i32 = 0; dPhase: i32 = 0; dClock: f64 = 0; dErr: f64 = 0; dTricks: i32 = 0; dBowl: i32 = 0;
    dHist0: i32 = -1; dHist1: i32 = -1; dGreedy: bool = false; dCoast: bool = false; dFlat: f64 = 0; dPop: f64 = 0;

    // scratch rotations
    R0: M3 = new M3(); R1: M3 = new M3(); R2: M3 = new M3(); R3: M3 = new M3(); Rr: M3 = new M3(); R4: M3 = new M3();

    start(api: GameApi): void {
        api.playable = true;
        this.bBoard = api.bone("board");
        this.bTorso = api.bone("torso");
        for (let i = 0; i < 2; i++) {
            this.bArm[i] = api.bone("arm" + i.toString());
            this.bThigh[i] = api.bone("thigh" + i.toString());
            this.bShin[i] = api.bone("shin" + i.toString());
            this.bShoe[i] = api.bone("shoe" + i.toString());
        }
        for (let i = 0; i < 8; i++) {
            this.bDust[i] = api.bone("dust" + i.toString()); this.dT[i] = 99;
            this.bSpark[i] = api.bone("spark" + i.toString()); this.pT[i] = 99;
        }
        this.wasDemo = api.demo;
        this.fresh(api);
        this.camX = this.x + 2.0; this.camY = 0; this.camZ = this.z + 1.0;
    }

    // A fresh session: in demo the skater is already rolling into the kicker; in play it waits.
    fresh(api: GameApi): void {
        this.resetSkater();
        this.score = 0;
        this.t = 0;
        this.sessionBestCombo = 0;
        this.newBest = false;
        this.lastSec = -1;
        this.clearCombo();
        this.msgT = 9; this.popT = 9; this.lastTrickT = 9;
        this.pressing = false; this.armed = false; this.swiping = false;
        if (api.demo) {
            this.mode = RUN;
            this.x = -8.6; this.z = -4.5; this.hd = Math.PI / 2; this.yaw = this.hd;
            this.vx = 6.8; this.vz = 0;
            this.dF = 0; this.dPhase = 1; this.dClock = 0; this.dErr = 0; this.dTricks = 0;
            this.dHist0 = 0; this.dHist1 = -1;
            this.steerX = -1; this.hasTgt = false;
        } else {
            this.mode = READY;
            this.x = -7.6; this.z = -4.5; this.hd = Math.PI / 2; this.yaw = this.hd;
            this.vx = 0; this.vz = 0;
            this.steerX = -1; this.hasTgt = false;
        }
        surf(this.x, this.z);
        this.y = sY;
    }

    resetSkater(): void {
        this.st = GROUND; this.vy = 0; this.crouch = 0; this.trick = -1; this.queue = -1; this.nAir = 0;
        this.rail = -1; this.bailT = 0; this.wheelie = 0; this.pushPh = 0; this.nX = 0; this.nY = 1; this.nZ = 0;
        this.vert = false; this.ollied = false;
    }

    clearCombo(): void {
        this.nCombo = 0; this.comboPts = 0; this.chains = 0; this.nSeen = 0;
        for (let i = 0; i < NT; i++) this.seen[i] = false;
    }

    mult(): i32 { return min<i32>(9, max<i32>(1, this.nSeen + this.chains)); }
    comboValue(): i32 { return this.comboPts * this.mult(); }

    addCombo(idx: i32, pts: i32): void {
        if (this.nCombo < 32) { this.combo[this.nCombo] = idx; this.nCombo++; }
        this.comboPts += pts;
        if (!this.seen[idx]) { this.seen[idx] = true; this.nSeen++; }
    }

    speed(): f64 { return Math.sqrt(this.vx * this.vx + this.vz * this.vz); }

    // ------------------------------------------------------------------ update
    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged || api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.best = 0; this.bestCombo = 0;
            this.fresh(api);
        }
        if (this.mode == RUN) {
            this.t += dt;
            let left = SESSION - this.t;
            let sec = <i32>Math.ceil(left);
            if (left > 0 && left <= 5 && sec != this.lastSec) {
                this.lastSec = sec;
                api.sound(SFX_BLIP, sec == 1 ? 1.5 : 1.2, 0.35);
            }
            if (left <= 0 && this.st != AIR && this.st != GRIND) {
                this.endSession(api);
            }
        } else if (this.mode == OVER) {
            this.overT += dt;
            if (api.demo && this.overT > 2.0) this.fresh(api);
        }
        if (api.demo && this.mode == RUN) this.demo(api, dt);
        this.input(api, dt);
        // sub-steps
        let n = 4;
        for (let i = 0; i < n; i++) this.step(api, dt / <f64>n);
        this.timers(api, dt);
        this.particles(api, dt);
        this.pose(api, dt);
        this.camera(api, dt);
    }

    endSession(api: GameApi): void {
        if (this.nCombo > 0 && this.st != BAIL) this.bank(api);
        this.mode = OVER;
        this.overT = 0;
        this.pressing = false; this.armed = false;
        if (this.score > this.best) { this.best = this.score; this.newBest = this.score > 0; }
        if (this.newBest) {
            api.sound(SFX_WIN, 1, 0.6);
            api.note(84, 0.5, 0, SFX_BELL, 0.45); api.note(88, 0.5, 0, SFX_BELL, 0.6); api.note(91, 0.5, 0, SFX_BELL, 0.75);
        } else {
            api.note(79, 0.5, 0, SFX_NOTE); api.note(76, 0.5, 0, SFX_NOTE, 0.14); api.note(72, 0.55, 0, SFX_NOTE, 0.28);
            api.note(67, 0.45, 0, SFX_BELL, 0.42);
        }
    }

    // the steering target from the pointer (re-picked each frame: the camera moves) and the wind-up
    input(api: GameApi, dt: f64): void {
        if (this.hoverPending) {
            this.hoverPending = false;
            if (this.mode == RUN && !this.startClick) { this.steerX = this.hoverX; this.steerY = this.hoverY; }
        }
        this.afterUp = false;
        if (!api.demo) {
            this.hasTgt = false;
            if (this.steerX >= 0 && api.pick(this.steerX, this.steerY, <f32>Math.max(this.y, -0.6))) {
                this.tgtX = <f64>api.hitX; this.tgtZ = <f64>api.hitZ; this.hasTgt = true;
            }
        }
        if (this.pressing) {
            this.holdT += dt;
        }
        let want = (this.pressing && this.armed && this.mode == RUN && this.st != BAIL) ? Math.min(1.0, this.holdT / 0.45) : 0.0;
        if (this.st == AIR) want = 0;
        this.crouch += (want - this.crouch) * Math.min(1.0, dt * (want > this.crouch ? 30 : 12));
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (api.demo) return true;
        if (kind == POINTER_DOWN) {
            this.hoverPending = false;   // a finger's press comes with a move: it is not a hover
            if (this.mode == READY || (this.mode == OVER && this.overT > 0.8)) {
                if (this.mode == OVER) this.fresh(api);
                this.mode = RUN;
                this.t = 0;
                this.steerX = x; this.steerY = y;
                api.sound(SFX_WIN, 1, 0.45);
                api.sound(SFX_CLICK, 0.9, 0.5, 0, 0.05);
                this.startClick = true;
                return true;
            }
            if (this.mode != RUN) return true;
            this.pressing = true;
            this.holdT = 0;
            if (this.st == AIR) {
                this.armed = false;
                this.swiping = true; this.swX = x; this.swY = y; this.swT = this.t;
            } else {
                // a press winds up an ollie; it steers only once it is dragged away (below)
                this.armed = true;
                this.swiping = false;
                this.pressOX = x; this.pressOY = y;
            }
            return true;
        }
        if (kind == POINTER_MOVE) {
            if (!this.pressing) {
                // a mouse hovering steers; a finger only moves while down, but its press arrives as
                // a move then a down, and its lift as an up then a move: wait for the frame to tell
                if (this.afterUp && x == this.upX && y == this.upY) { this.afterUp = false; return true; }
                this.hoverPending = true; this.hoverX = x; this.hoverY = y;
                return true;
            }
            if (this.startClick) { this.steerX = x; this.steerY = y; return true; }
            if (this.st == AIR || this.swiping) {
                if (!this.swiping) { this.swiping = true; this.swX = x; this.swY = y; this.swT = this.t; }
                if (this.t - this.swT > 0.6) { this.swX = x; this.swY = y; this.swT = this.t; }
                let dx = x - this.swX, dy = y - this.swY;
                if (dx * dx + dy * dy >= 36 * 36 && this.st == AIR) {
                    this.swipe(api, dx, dy, true);
                    this.swX = x; this.swY = y; this.swT = this.t;
                }
                return true;
            }
            // on the ground a drag steers: leaving the press spot turns the wind-up into steering
            if (this.armed) {
                let ex = x - this.pressOX, ey = y - this.pressOY;
                if (ex * ex + ey * ey > 12 * 12) this.armed = false;
            }
            if (!this.armed) { this.steerX = x; this.steerY = y; }
            return true;
        }
        if (kind == POINTER_UP) {
            this.afterUp = true; this.upX = x; this.upY = y;
            if (this.startClick) { this.startClick = false; this.pressing = false; return true; }
            if (!this.pressing) return true;
            this.pressing = false;
            let c = Math.min(1.0, this.holdT / 0.45);
            if (this.mode == RUN && this.armed && (this.st == GROUND || this.st == GRIND)) {
                this.ollie(api, c);
            } else if (this.mode == RUN && this.armed && this.st == AIR && this.t - this.leftT < 0.2 && !this.ollied) {
                this.latePop(api, c);
            } else if (this.st == AIR && this.swiping) {
                let dx = x - this.swX, dy = y - this.swY;
                if (dx * dx + dy * dy >= 10 * 10 && this.t - this.swT <= 0.6) this.swipe(api, dx, dy, false);
            }
            this.armed = false;
            this.swiping = false;
            return true;
        }
        return true;
    }

    hoverPending: bool = false; hoverX: f32 = 0; hoverY: f32 = 0;
    afterUp: bool = false; upX: f32 = 0; upY: f32 = 0;

    // the wind-up spot: where the press happened
    pressOX: f32 = 0; pressOY: f32 = 0;

    // A swipe in the air: up a flip, sideways a spin, down a grab; long ones are the bigger tricks.
    swipe(api: GameApi, dx: f32, dy: f32, long: bool): void {
        let len = Mathf.sqrt(dx * dx + dy * dy);
        let big = long || len >= 36;
        let t = -1;
        let dir = 1.0;
        if (Mathf.abs(dy) > Mathf.abs(dx) * 1.1) {
            t = dy < 0 ? (big ? T_DFLICK : T_FLICK) : (big ? T_KITE : T_SUNNY);
        } else {
            t = big ? T_FULL : T_HALF;
            dir = dx < 0 ? 1.0 : -1.0;
        }
        this.doTrick(api, t, dir);
    }

    doTrick(api: GameApi, t: i32, dir: f64): void {
        if (this.st != AIR) return;
        if (this.trick < 0) {
            this.trick = t; this.trickT = 0; this.trickDir = dir;
            this.trickSound(api, t);
        } else if (this.queue < 0) {
            this.queue = t; this.queueDir = dir;
        }
    }

    trickSound(api: GameApi, t: i32): void {
        let k = TKIND[t];
        if (k == 1) api.soundAt(SFX_WHOOSH, this.x, this.y + 1, this.z, t == T_FULL ? 1.15 : 0.9, 0.6);
        else if (k == 0) {
            api.soundAt(SFX_WHOOSH, this.x, this.y + 0.3, this.z, 1.6, 0.4);
            api.soundAt(SFX_CLICK, this.x, this.y + 0.3, this.z, 1.4, 0.35, 0.02);
        } else api.soundAt(SFX_WHOOSH, this.x, this.y + 0.6, this.z, 0.7, 0.4);
    }

    ollie(api: GameApi, c: f64): void {
        let vy0 = 0.0;
        if (this.st == GROUND) {
            surf(this.x, this.z);
            vy0 = Math.max(0, this.vx * sGX + this.vz * sGZ);
        }
        if (this.st == GRIND) this.endGrind(api, false);
        this.leave(false);
        this.vy = vy0 + 2.4 + 2.4 * c;
        this.ollied = true;
        this.airTricks[this.nAir++] = T_OLLIE;
        api.soundAt(SFX_POP, this.x, this.y, this.z, 0.75 + 0.2 * c, 0.75);
        api.soundAt(SFX_CLICK, this.x, this.y, this.z, 0.8, 0.6);
        this.dust(api, this.x, this.y, this.z, 2);
    }

    latePop(api: GameApi, c: f64): void {
        this.vy += (this.vert ? 0.45 : 0.9) * (2.4 + 2.4 * c);
        this.ollied = true;
        if (this.nAir < 8) this.airTricks[this.nAir++] = T_OLLIE;
        api.soundAt(SFX_POP, this.x, this.y, this.z, 0.95, 0.75);
        api.soundAt(SFX_CLICK, this.x, this.y, this.z, 0.9, 0.6);
    }

    leave(lip: bool): void {
        this.st = AIR;
        this.airT = 0;
        this.leftT = this.t;
        this.takeY = this.y; this.maxY = this.y;
        this.nAir = 0;
        this.ollied = false;
        this.vert = false;
        this.yawTo = this.yaw; this.turnRate = 0;
        if (this.wheelie > 0 && this.nCombo > 0) {
            this.chains++;
            this.addCombo(T_WHEELIE, TPTS[T_WHEELIE]);
        }
        this.wheelie = 0;
    }

    // off a lip: a QP or the bowl turns the speed upwards and brings the skater back (turning round
    // in the air); the kicker or a lip being left for the deck throws it forwards
    launch(api: GameApi, gx: f64, gz: f64, vyt: f64): void {
        let g = Math.sqrt(gx * gx + gz * gz);
        let vert = g > 1.5;
        let dx = this.x - BX, dz = this.z - BZ;
        let inBowl = Math.sqrt(dx * dx + dz * dz) < RF + 2.2;
        if (vert && inBowl && this.hasTgt) {
            let tx = this.tgtX - BX, tz = this.tgtZ - BZ;
            vert = Math.sqrt(tx * tx + tz * tz) < 3.0;
        }
        let oldYaw = this.yaw;
        this.leave(true);
        if (vert) {
            let nhx = gx / g, nhz = gz / g;
            let vn = this.vx * nhx + this.vz * nhz;
            let tx = this.vx - vn * nhx, tz = this.vz - vn * nhz;
            let v3 = Math.sqrt(vn * vn + vyt * vyt);
            this.vy = v3 * 0.92;
            this.vx = tx - 0.10 * this.vy * nhx; this.vz = tz - 0.10 * this.vy * nhz;
            this.vert = true;
            // turn round in the air: towards the side the skater carves to
            let side = tx * nhz - tz * nhx;
            this.yawTo = oldYaw + (side >= 0 ? Math.PI : -Math.PI);
            this.turnRate = Math.PI / Math.max(0.25, 2 * this.vy / G * 0.6);
            api.soundAt(SFX_WHOOSH, this.x, this.y + 1, this.z, 0.6, 0.35);
        } else {
            this.vy = vyt;
        }
        this.airTricks[this.nAir++] = T_AIR;
        api.soundAt(SFX_CLICK, this.x, this.y, this.z, 1.2, 0.45);
    }

    endGrind(api: GameApi, fell: bool): void {
        let idx = RAILS[this.rail * 5 + 1] == 6.0 ? T_RAIL : T_LEDGE;
        let pts = TPTS[idx] + <i32>(this.grindT * 120);
        this.addCombo(idx, pts);
        this.lastTrick = TNAME[idx]; this.lastTrickT = 0;
        this.rail = -1;
        this.st = AIR;
        this.airT = 0;
        this.leftT = this.t;
        this.takeY = this.y; this.maxY = this.y;
        this.nAir = 0; this.ollied = false; this.vert = false;
        this.yawTo = this.yaw; this.turnRate = 0;
        this.vy = fell ? 0.5 : 1.3;
        api.soundAt(SFX_CLICK, this.x, this.y, this.z, 1.1, 0.5);
    }

    bail(api: GameApi, why: string): void {
        this.st = BAIL;
        this.bailT = 0;
        this.trick = -1; this.queue = -1; this.nAir = 0;
        this.clearCombo();
        this.wheelie = 0;
        this.msg = "BAIL!"; this.msgT = 0; this.msgCol = 1;
        // the board shoots ahead, wheels up, spinning
        this.bdX = this.x; this.bdY = this.y; this.bdZ = this.z;
        this.bdVX = this.vx * 1.3; this.bdVZ = this.vz * 1.3; this.bdYaw = this.yaw;
        this.bdSpin = (this.vx * 0.7 + this.vz * 0.3) >= 0 ? 7 : -7;
        api.soundAt(SFX_THUD, this.x, this.y, this.z, 0.7, 0.9);
        api.soundAt(SFX_HIT, this.x, this.y, this.z, 0.75, 0.5, 0.03);
        api.soundAt(SFX_CLICK, this.x, this.y, this.z, 0.6, 0.5, 0.12);
        api.note(55, 0.35, 0, SFX_NOTE, 0.18); api.note(50, 0.35, 0, SFX_NOTE, 0.3);
        this.dust(api, this.x, this.y, this.z, 4);
    }

    land(api: GameApi): void {
        surf(this.x, this.z);
        let gx = sGX, gz = sGZ;
        let nl = Math.sqrt(gx * gx + 1 + gz * gz);
        let nx = -gx / nl, ny = 1 / nl, nz = -gz / nl;
        let vd = this.vx * nx + this.vy * ny + this.vz * nz;
        this.vx -= vd * nx; this.vz -= vd * nz;
        this.vy = 0;
        this.y = sY;
        this.st = GROUND;
        let air = this.airT;
        let sp = this.speed();
        if (sp > 0.3) this.hd = Math.atan2(this.vx, this.vz);
        if (this.trick >= 0) { this.bail(api, "mid-trick"); return; }
        let d = Math.abs(wrap(this.yaw - this.hd));
        if (d > Math.PI / 2) d = Math.PI - d;
        // on a steep wall the board swings into the fall line: more room there (a vert air's landing)
        let tol = (this.vert || gx * gx + gz * gz > 0.25) ? 75.0 : 35.0;
        if (sp > 0.5 && d > tol * Math.PI / 180) { this.bail(api, "sideways"); return; }
        if (-vd > 11.5) { this.bail(api, "hard"); return; }
        // clean
        this.landSquash = 1;
        let hard = clamp(-vd / 8, 0.2, 1);
        api.soundAt(SFX_CLICK, this.x, this.y, this.z, 0.7, 0.5 + 0.4 * hard);
        api.soundAt(SFX_THUD, this.x, this.y, this.z, 1.3, 0.25 + 0.35 * hard, 0.01);
        if (air > 0.25) this.dust(api, this.x, this.y, this.z, 2);
        // what the air was worth
        let any = false, n = 0;
        let height = this.maxY - this.takeY;
        for (let i = 0; i < this.nAir; i++) {
            let k = this.airTricks[i];
            if (k != T_OLLIE && k != T_AIR) { this.addCombo(k, TPTS[k]); any = true; n++; }
        }
        let hb = <i32>(Math.max(0, height) * 40);
        if (!any) {
            let ol = false, ai = false;
            for (let i = 0; i < this.nAir; i++) { if (this.airTricks[i] == T_OLLIE) ol = true; if (this.airTricks[i] == T_AIR) ai = true; }
            if (ai && (air > 0.35 || height > 0.3)) { this.addCombo(T_AIR, TPTS[T_AIR] + hb); any = true; this.lastTrick = height > 0.9 ? "BIG AIR" : "AIR"; this.lastTrickT = 0; }
            else if (ol) { this.addCombo(T_OLLIE, TPTS[T_OLLIE] + hb); any = true; this.lastTrick = "OLLIE"; this.lastTrickT = 0; }
        } else {
            this.comboPts += hb;
        }
        this.nAir = 0;
        if (this.nCombo > 0) {
            this.wheelie = WINDOW;
            if (any) api.note(JINGLE[min<i32>(this.mult() - 1, 8)], 0.3, 0, SFX_NOTE, 0.04);
        }
        this.vert = false;
    }

    // a combo banked: score, a pop, a jingle that climbs with the multiplier
    bank(api: GameApi): void {
        let v = this.comboValue();
        let m = this.mult();
        this.score += v;
        if (v > this.sessionBestCombo) this.sessionBestCombo = v;
        if (v > this.bestCombo) this.bestCombo = v;
        this.pop = "+" + v.toString() + (m > 1 ? " X" + m.toString() : "");
        this.popT = 0; this.popX = this.x; this.popY = this.y + 2.0; this.popZ = this.z;
        let k = min<i32>(m + 1, 8);
        for (let i = 0; i < k; i++) {
            api.note(JINGLE[i], 0.42, 0, m >= 3 && i == k - 1 ? SFX_BELL : SFX_NOTE, 0.065 * <f64>i);
        }
        if (m >= 4) api.sound(SFX_POP, 1.4, 0.4, 0, 0.065 * <f64>k);
        this.clearCombo();
    }

    // ------------------------------------------------------------------ physics step
    step(api: GameApi, dt: f64): void {
        if (this.st == GROUND || this.st == BAIL) {
            surf(this.x, this.z);
            let gx = sGX, gz = sGZ, y0 = sY;
            let g2 = gx * gx + gz * gz;
            let sp = this.speed();
            let q = 0.0;
            if (sp > 0.01) {
                let ux = this.vx / sp, uz = this.vz / sp, ds = 0.06;
                q = sp * sp * (hAt(this.x + ux * ds, this.z + uz * ds) - 2 * y0 + hAt(this.x - ux * ds, this.z - uz * ds)) / (ds * ds);
                q = Math.max(q, 0.0);
            }
            this.vx += -(G + q) * gx / (1 + g2) * dt;
            this.vz += -(G + q) * gz / (1 + g2) * dt;
            sp = this.speed();
            if (this.st == GROUND) {
                // steering towards the target
                if (sp > 0.05) this.hd = Math.atan2(this.vx, this.vz);
                let steer = this.mode == RUN && this.hasTgt;
                if (steer) {
                    let ddx = this.tgtX - this.x, ddz = this.tgtZ - this.z;
                    if (ddx * ddx + ddz * ddz > 1.0) {
                        let d = wrap(Math.atan2(ddx, ddz) - this.hd);
                        let rate = 3.4 / (1 + sp / 9.0) * (g2 > 1 ? 0.35 : 1.0);
                        d = clamp(d, -rate * dt, rate * dt);
                        this.hd += d;
                        if (sp > 0.05) { this.vx = sp * Math.sin(this.hd); this.vz = sp * Math.cos(this.hd); }
                    }
                }
                // pushing on the flat, pumping down the transitions
                this.pushing = this.mode == RUN && g2 < 0.09 && sp < (this.dCoast && api.demo ? 4.5 : CRUISE) && this.crouch < 0.3;
                if (this.pushing) {
                    this.vx += Math.sin(this.hd) * 2.6 * dt; this.vz += Math.cos(this.hd) * 2.6 * dt;
                }
                if (g2 > 0.06 && (this.vx * gx + this.vz * gz) < 0 && sp > 0.1) {
                    let k = 2.0 * Math.min(1.0, Math.sqrt(g2) / 1.5);
                    this.vx += this.vx / sp * k * dt; this.vz += this.vz / sp * k * dt;
                }
                sp = this.speed();
                let f = Math.max(0.0, sp - (0.12 + 0.012 * sp * sp) * dt);
                if (this.mode == OVER) f = Math.max(0.0, sp - 1.2 * dt);
                if (f > VMAX) f = VMAX;
                if (sp > 0) { this.vx *= f / sp; this.vz *= f / sp; }
            } else {
                // a bail: sliding to a stop
                let k = sp > 0 ? Math.max(0, sp - 7 * dt) / sp : 0;
                this.vx *= k; this.vz *= k;
            }
            let nx = this.x + this.vx * dt, nz = this.z + this.vz * dt;
            if (hAt(nx, nz) - y0 > 0.2) {
                let bump = false;
                if (hAt(nx, this.z) - y0 > 0.2) { this.vx = -0.4 * this.vx; nx = this.x; bump = true; }
                if (hAt(nx, nz) - y0 > 0.2) { this.vz = -0.4 * this.vz; nz = this.z; bump = true; }
                if (bump) this.wallSound(api);
            }
            nx = this.borderX(api, nx); nz = this.borderZ(api, nz);
            let ny = hAt(nx, nz);
            if (this.st == GROUND) {
                let vyt = this.vx * gx + this.vz * gz;
                if (ny < y0 + vyt * dt - 0.5 * G * dt * dt - 0.004) {
                    // the surface falls away faster than a thrown body: airborne
                    this.x = nx; this.z = nz; this.y = y0 + vyt * dt;
                    if (vyt > 0.8 && g2 > 0.04) {
                        this.launch(api, gx, gz, vyt);
                    } else {
                        this.leave(false);
                        this.vy = vyt;
                    }
                    return;
                }
            }
            this.x = nx; this.z = nz; this.y = ny;
            if (this.st == GROUND && this.speed() > 0.3) {
                // the board follows the travel, nose or tail first (fakie)
                let fak = Math.abs(wrap(this.yaw - this.hd)) > Math.PI / 2;
                this.yaw = fak ? wrap(this.hd + Math.PI) : this.hd;
            }
        } else if (this.st == AIR) {
            this.vy -= G * dt;
            let px = this.x, py = this.y, pz = this.z;
            let nx = this.x + this.vx * dt, ny = this.y + this.vy * dt, nz = this.z + this.vz * dt;
            nx = this.borderX(api, nx); nz = this.borderZ(api, nz);
            if (this.vy < 0) {
                for (let i = 0; i < NRAIL; i++) {
                    let ax = RAILS[i * 5], az = RAILS[i * 5 + 1], bx = RAILS[i * 5 + 2], bz = RAILS[i * 5 + 3], ry = RAILS[i * 5 + 4];
                    if (py >= ry - 0.03 && ny <= ry + 0.04) {
                        let dx = bx - ax, dz = bz - az;
                        let L = Math.sqrt(dx * dx + dz * dz);
                        let ux = dx / L, uz = dz / L;
                        let t = (nx - ax) * ux + (nz - az) * uz;
                        let d = -(nx - ax) * uz + (nz - az) * ux;
                        let sp = this.speed();
                        if (t >= 0 && t <= L && Math.abs(d) < 0.35 && sp > 0.5) {
                            let al = Math.abs(this.vx * ux + this.vz * uz) / sp;
                            if (al > 0.766) { this.grind(api, i, t, this.vx * ux + this.vz * uz); return; }
                        }
                    }
                }
            }
            let g = hAt(nx, nz);
            if (g - py > 0.3) {
                this.vx = -0.3 * this.vx; this.vz = -0.3 * this.vz;
                nx = px; nz = pz;
                g = hAt(nx, nz);
                this.wallSound(api);
            }
            this.x = nx; this.y = ny; this.z = nz;
            if (this.y > this.maxY) this.maxY = this.y;
            if (this.y <= g) { this.y = g; this.land(api); }
        } else if (this.st == GRIND) {
            let i = this.rail;
            let ax = RAILS[i * 5], az = RAILS[i * 5 + 1], bx = RAILS[i * 5 + 2], bz = RAILS[i * 5 + 3], ry = RAILS[i * 5 + 4];
            let dx = bx - ax, dz = bz - az;
            let L = Math.sqrt(dx * dx + dz * dz);
            let ux = dx / L, uz = dz / L;
            let sg = this.railV > 0 ? 1.0 : -1.0;
            this.railV -= sg * 0.9 * dt;
            this.railS += this.railV * dt;
            this.grindT += dt;
            this.x = ax + ux * this.railS; this.z = az + uz * this.railS; this.y = ry;
            this.vx = ux * this.railV; this.vz = uz * this.railV;
            if (this.railS < -0.1 || this.railS > L + 0.1 || Math.abs(this.railV) < 0.6) this.endGrind(api, Math.abs(this.railV) < 0.6);
        }
    }

    grind(api: GameApi, i: i32, t: f64, v: f64): void {
        if (this.trick >= 0) {
            this.y = RAILS[i * 5 + 4];
            this.bail(api, "grind mid-trick");
            return;
        }
        // tricks done on the way in still count
        for (let k = 0; k < this.nAir; k++) {
            let tr = this.airTricks[k];
            if (tr != T_OLLIE && tr != T_AIR) this.addCombo(tr, TPTS[tr]);
        }
        this.nAir = 0;
        this.st = GRIND;
        this.rail = i; this.railS = t; this.railV = v; this.grindT = 0;
        this.y = RAILS[i * 5 + 4]; this.vy = 0;
        let ux = RAILS[i * 5 + 2] - RAILS[i * 5];
        this.hd = v * ux >= 0 ? Math.PI / 2 : -Math.PI / 2;
        let fak = Math.abs(wrap(this.yaw - this.hd)) > Math.PI / 2;
        this.yaw = fak ? wrap(this.hd + Math.PI) : this.hd;
        this.landSquash = 0.7;
        api.soundAt(SFX_CLICK, this.x, this.y, this.z, 1.5, 0.7);
        api.soundAt(SFX_ZAP, this.x, this.y, this.z, 0.5, 0.25);
        this.scrapeIn = 2;
    }

    wallSound(api: GameApi): void {
        if (this.scrapeIn > -6) return;
        this.scrapeIn = 0;
        api.soundAt(SFX_THUD, this.x, this.y, this.z, 0.9, 0.5);
    }

    borderX(api: GameApi, x: f64): f64 {
        if (x < XMIN) { this.vx = Math.abs(this.vx) * 0.5; this.wallSound(api); return XMIN; }
        if (x > XMAX) { this.vx = -Math.abs(this.vx) * 0.5; this.wallSound(api); return XMAX; }
        return x;
    }
    borderZ(api: GameApi, z: f64): f64 {
        if (z < ZMIN) { this.vz = Math.abs(this.vz) * 0.5; this.wallSound(api); return ZMIN; }
        if (z > ZMAX) { this.vz = -Math.abs(this.vz) * 0.5; this.wallSound(api); return ZMAX; }
        return z;
    }

    // ------------------------------------------------------------------ per frame timers, sounds
    timers(api: GameApi, dt: f64): void {
        let sp = this.speed();
        if (this.st == AIR) {
            this.airT += dt;
            // the air turn (vert) towards its goal
            if (this.turnRate > 0) {
                let d = wrap(this.yawTo - this.yaw);
                let s = this.turnRate * dt;
                if (Math.abs(d) <= s) { this.yaw = this.yawTo; this.turnRate = 0; } else this.yaw += d > 0 ? s : -s;
            }
            if (this.trick >= 0) {
                this.trickT += dt;
                if (this.trickT >= TDUR[this.trick]) {
                    let k = this.trick;
                    if (TKIND[k] == 1) this.yaw = wrap(this.yaw + this.trickDir * TAMT[k] * Math.PI / 180);
                    if (this.nAir < 8) this.airTricks[this.nAir++] = k;
                    this.lastTrick = TNAME[k]; this.lastTrickT = 0;
                    this.trick = this.queue; this.trickDir = this.queueDir; this.trickT = 0;
                    this.queue = -1;
                    if (this.trick >= 0) this.trickSound(api, this.trick);
                }
            }
        }
        if (this.st == BAIL) {
            this.bailT += dt;
            this.bdX += this.bdVX * dt; this.bdZ += this.bdVZ * dt;
            let bs = Math.sqrt(this.bdVX * this.bdVX + this.bdVZ * this.bdVZ);
            if (bs > 0) { let k = Math.max(0, bs - 5 * dt) / bs; this.bdVX *= k; this.bdVZ *= k; }
            this.bdX = clamp(this.bdX, XMIN, XMAX); this.bdZ = clamp(this.bdZ, ZMIN, ZMAX);
            surf(this.bdX, this.bdZ); this.bdY = sY;
            this.bdYaw += this.bdSpin * dt; this.bdSpin *= Math.max(0, 1 - 2.5 * dt);
            if (this.bailT > 1.4) {
                this.st = GROUND;
                this.landSquash = 0.6;
                if (sp > 0.2) this.hd = Math.atan2(this.vx, this.vz);
                this.yaw = this.hd;
                api.soundAt(SFX_CLICK, this.x, this.y, this.z, 0.8, 0.45);
            }
        }
        if (this.st == GROUND) {
            if (this.wheelie > 0) {
                this.wheelie -= dt;
                if (this.wheelie <= 0) { this.wheelie = 0; if (this.nCombo > 0) this.bank(api); }
            }
            // wheels on the concrete: sparse ticks, quicker with speed
            if (sp > 0.6) {
                this.tickIn--;
                if (this.tickIn <= 0) {
                    this.tickIn = <i32>clamp(20 - sp * 1.6, 5, 20);
                    api.soundAt(SFX_TICK, this.x, this.y, this.z, 0.55 + sp * 0.05, 0.18 + sp * 0.015);
                }
            }
            // the push stroke: a scuff at each kick
            if (this.pushing || this.pushPh > 0) {
                let before = this.pushPh;
                this.pushPh += dt / 0.55;
                if (before < 0.5 && this.pushPh >= 0.5) {
                    api.soundAt(SFX_TICK, this.x, this.y, this.z, 0.35, 0.3);
                    this.dust(api, this.x - Math.sin(this.hd) * 0.4, this.y, this.z - Math.cos(this.hd) * 0.4, 1);
                }
                if (this.pushPh >= 1) this.pushPh = this.pushing ? this.pushPh - 1 : 0;
            }
        }
        if (this.st == GRIND) {
            // the scrape: quick clicks and sparks
            this.scrapeIn--;
            if (this.scrapeIn <= 0) {
                this.scrapeIn = 3;
                let alt = (api.frame / 3) % 2 == 0;
                api.soundAt(SFX_CLICK, this.x, this.y, this.z, alt ? 1.7 : 2.0, 0.32);
            }
            this.sparkT -= dt;
            if (this.sparkT <= 0) { this.sparkT = 0.04; this.spark(api); }
        } else if (this.scrapeIn > -60) {
            this.scrapeIn--;
        }
        if (this.landSquash > 0) this.landSquash = Math.max(0, this.landSquash - dt * 5);
        this.msgT += dt; this.popT += dt; this.lastTrickT += dt;
    }

    // ------------------------------------------------------------------ particles
    dust(api: GameApi, x: f64, y: f64, z: f64, n: i32): void {
        for (let k = 0; k < n; k++) {
            let i = this.dNext; this.dNext = (this.dNext + 1) % 8;
            let a = api.range(0, 2 * Math.PI);
            this.dX[i] = x + Math.cos(a) * 0.25; this.dY[i] = y; this.dZ[i] = z + Math.sin(a) * 0.25;
            this.dVX[i] = Math.cos(a) * 0.9 - this.vx * 0.15; this.dVY[i] = api.range(0.4, 0.9);
            this.dVZ[i] = Math.sin(a) * 0.9 - this.vz * 0.15;
            this.dT[i] = 0; this.dS[i] = api.range(0.8, 1.2);
        }
    }

    spark(api: GameApi): void {
        let i = this.pNext; this.pNext = (this.pNext + 1) % 8;
        this.pX[i] = this.x; this.pY[i] = this.y + 0.02; this.pZ[i] = this.z;
        this.pVX[i] = -this.vx * 0.4 + api.range(-1.2, 1.2); this.pVY[i] = api.range(1.0, 2.6);
        this.pVZ[i] = -this.vz * 0.4 + api.range(-1.2, 1.2);
        this.pT[i] = 0;
    }

    particles(api: GameApi, dt: f64): void {
        for (let i = 0; i < 8; i++) {
            if (this.dT[i] < 0.6) {
                this.dT[i] += dt;
                this.dX[i] += this.dVX[i] * dt; this.dY[i] += this.dVY[i] * dt; this.dZ[i] += this.dVZ[i] * dt;
                this.dVX[i] *= 1 - 3 * dt; this.dVZ[i] *= 1 - 3 * dt; this.dVY[i] *= 1 - 2 * dt;
                let u = Math.floor(this.dT[i] * 12) / 12 / 0.6;
                let s = (u < 0.25 ? 0.5 + u * 2 : 1.0 - (u - 0.25) * 1.2) * this.dS[i];
                if (this.dT[i] >= 0.6) api.hide(this.bDust[i]);
                else setScaled(api, this.bDust[i], s, this.dX[i], this.dY[i], this.dZ[i]);
            } else if (this.dT[i] < 90) {
                this.dT[i] = 99; api.hide(this.bDust[i]);
            }
            if (this.pT[i] < 0.4) {
                this.pT[i] += dt;
                this.pVY[i] -= 9 * dt;
                this.pX[i] += this.pVX[i] * dt; this.pY[i] += this.pVY[i] * dt; this.pZ[i] += this.pVZ[i] * dt;
                if (this.pT[i] >= 0.4) api.hide(this.bSpark[i]);
                else api.place(this.bSpark[i], this.pX[i], this.pY[i], this.pZ[i]);
            } else if (this.pT[i] < 90) {
                this.pT[i] = 99; api.hide(this.bSpark[i]);
            }
        }
    }

    // ------------------------------------------------------------------ the pose
    pose(api: GameApi, dt: f64): void {
        // the body's up: the surface normal on the ground, upright in the air
        let tx = 0.0, ty = 1.0, tz = 0.0;
        if (this.st == GROUND) {
            surf(this.x, this.z);
            let l = Math.sqrt(sGX * sGX + 1 + sGZ * sGZ);
            tx = -sGX / l; ty = 1 / l; tz = -sGZ / l;
        }
        let k = Math.min(1.0, dt * (this.st == AIR ? 7 : (this.st == BAIL ? 30 : 20)));
        this.nX += (tx - this.nX) * k; this.nY += (ty - this.nY) * k; this.nZ += (tz - this.nZ) * k;
        let nl = Math.sqrt(this.nX * this.nX + this.nY * this.nY + this.nZ * this.nZ);
        let nx = this.nX / nl, ny = this.nY / nl, nz = this.nZ / nl;

        // the trick's progress
        let p = 0.0, kind = -1, amt = 0.0;
        if (this.st == AIR && this.trick >= 0) {
            p = clamp(this.trickT / TDUR[this.trick], 0, 1);
            p = Math.floor(p * 12) / 12;   // stepped, pose to pose
            kind = TKIND[this.trick]; amt = TAMT[this.trick];
        }
        let spin = kind == 1 ? this.trickDir * amt * ease(p) : 0.0;
        let yawNow = this.yaw + spin * Math.PI / 180;
        // the root frame: nose (local X) along the yaw, up along n
        let fx = Math.sin(yawNow), fz = Math.cos(yawNow), fy = 0.0;
        let kd = fx * nx + fy * ny + fz * nz;
        fx -= kd * nx; fy -= kd * ny; fz -= kd * nz;
        let fl = Math.sqrt(fx * fx + fy * fy + fz * fz);
        fx /= fl; fy /= fl; fz /= fl;
        let zx = fy * nz - fz * ny, zy = fz * nx - fx * nz, zz = fx * ny - fy * nx;   // f x n
        let R = this.R0.cols(fx, fy, fz, nx, ny, nz, zx, zy, zz);
        let ox = this.x, oy = this.y, oz = this.z;

        // the bail: the body rolls over backwards onto the ground, lies, gets up
        let tumble = 0.0;
        if (this.st == BAIL) {
            let b = this.bailT;
            let a = b < 0.3 ? b / 0.3 : (b < 1.0 ? 1.0 : Math.max(0, 1 - (b - 1.0) / 0.4));
            // fall downhill (on a ramp the body must not lie into it): head towards the low side
            surf(this.x, this.z);
            let side = -(sGX * zx + sGZ * zz);
            tumble = (side > 0.05 ? 80.0 : -80.0) * Math.floor(a * 6) / 6;
            this.R1.axis(0, tumble);
            this.R2.mul(R, this.R1);
            R = this.R4.copy(this.R2);
        }

        // body numbers
        let c = this.crouch;
        let tuck = 0.0, lift = 0.0, grab = 0.0, kite = 0.0, flip = 0.0;
        if (this.st == AIR) {
            tuck = 0.10;
            if (kind == 0) { flip = this.trickDir * amt * ease(p); let s = Math.sin(p * Math.PI); tuck = 0.10 + 0.16 * s; lift = 0.12 * s; }
            if (kind == 2) {
                let s = p < 0.25 ? p / 0.25 : (p > 0.8 ? (1 - p) / 0.2 : 1.0);
                grab = s;
                if (this.trick == T_KITE) kite = s;
                tuck = 0.10 + 0.22 * s;
            }
        }
        if (this.st == GRIND) c = Math.max(c, 0.35);
        if (this.pushing) c = Math.max(c, 0.12);
        c = Math.max(c, this.landSquash * 0.6);
        let wheel = (this.st == GROUND && this.wheelie > 0) ? Math.min(1.0, (WINDOW - this.wheelie) * 6) * Math.min(1.0, this.wheelie * 4) : 0.0;
        let hipY = HIP_Y - 0.26 * c - tuck * 0.5;
        let lean = 22 * c + 10 * grab;

        // the board: under the feet, pitched in a wheelie or a kite grab, rolled in a flip
        let byLocal = BOARD_Y + tuck * 0.9 - lift;
        let bpitch = 14 * wheel + 32 * kite;
        let broll = flip + 18 * grab * (1 - kite);
        this.R1.axis(2, bpitch);
        this.R2.axis(0, broll);
        let Rb = this.R3;
        if (this.st == BAIL) {
            // the board on its own: wheels up, spinning
            this.R1.axis(1, this.bdYaw * 180 / Math.PI);
            this.R2.axis(0, 180);
            Rb.mul(this.R1, this.R2);
            let ch = this.bailT < 0.25 ? 0.4 * Math.sin(this.bailT / 0.25 * Math.PI) : 0.0;
            setBone(api, this.bBoard, Rb, this.bdX, this.bdY + 0.13 + ch, this.bdZ);
        } else {
            this.Rr.mul(this.R1, this.R2);
            Rb.mul(R, this.Rr);
            apply(R, 0, byLocal + (wheel > 0 ? 0.04 * wheel : 0), 0);
            setBone(api, this.bBoard, Rb, ox + vX, oy + vY, oz + vZ);
        }

        // feet: on the deck (lifted with a flip or a tuck); the back foot pushes on the flat
        let footY = DECK_TOP + tuck * 0.9;
        let push = (this.pushing && this.st == GROUND) ? this.pushPh : -1.0;
        for (let i = 0; i < 2; i++) {
            let s = i == 0 ? -1.0 : 1.0;
            let fxl = s * FOOT_X, fyl = footY, fzl = 0.0;
            if (this.st == GROUND && wheel > 0) fyl += (s > 0 ? 0.16 : 0.02) * wheel;
            if (i == 0 && push >= 0) {
                // the back foot steps off beside the board, kicks back and returns
                let ph = push;
                let down = Math.sin(ph * Math.PI);
                fxl = -0.18 - 0.42 * ph + 0.1;
                fyl = DECK_TOP - 0.2 * down;
                fzl = 0.24 * down;
            }
            if (this.st == BAIL) { fxl = s * 0.28; fyl = 0.08; }
            // the shoe flat in the root frame
            apply(R, fxl, fyl, fzl);
            let sx = ox + vX, sy = oy + vY, sz = oz + vZ;
            setBone(api, this.bShoe[i], R, sx, sy, sz);
            // the leg: hip -> knee -> ankle, knees bending towards the chest (+Z)
            let hx = s * HIP_X, hy = hipY, hz = 0.0;
            let ax = fxl - s * 0.02, ay = fyl + ANKLE_UP, az = fzl;
            if (this.st == BAIL) { ax = s * 0.25; ay = 0.12; az = 0.0; }
            let dx = ax - hx, dy = ay - hy, dz = az - hz;
            let dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
            let maxd = 2 * L_LEG - 0.002;
            if (dist > maxd) { dx *= maxd / dist; dy *= maxd / dist; dz *= maxd / dist; dist = maxd; }
            let ux = dx / dist, uy = dy / dist, uz = dz / dist;
            // the bend direction: +Z off the leg's line
            let bk = uz;
            let bx = -bk * ux, by = -bk * uy, bz = 1 - bk * uz;
            let bl = Math.sqrt(bx * bx + by * by + bz * bz);
            bx /= bl; by /= bl; bz /= bl;
            let hgt = Math.sqrt(Math.max(0, L_LEG * L_LEG - dist * dist / 4));
            let kx = hx + dx / 2 + bx * hgt, ky = hy + dy / 2 + by * hgt, kz = hz + dz / 2 + bz * hgt;
            aim(this.R1, kx - hx, ky - hy, kz - hz, bx, by, bz);
            this.R2.mul(R, this.R1);
            apply(R, hx, hy, hz);
            setBone(api, this.bThigh[i], this.R2, ox + vX, oy + vY, oz + vZ);
            aim(this.R1, ax - kx, ay - ky, az - kz, bx, by, bz);
            this.R2.mul(R, this.R1);
            apply(R, kx, ky, kz);
            setBone(api, this.bShin[i], this.R2, ox + vX, oy + vY, oz + vZ);
        }

        // the torso (and head): leaning towards the chest when low, a bob when pushing
        let bob = push >= 0 ? -0.03 * Math.sin(push * Math.PI) : 0.0;
        this.R1.axis(0, lean);
        let Rt = this.R2.mul(R, this.R1);
        apply(R, 0, hipY + bob, 0);
        let tpx = ox + vX, tpy = oy + vY, tpz = oz + vZ;
        setBone(api, this.bTorso, Rt, tpx, tpy, tpz);
        // arms from the shoulders: out for balance, the front one reaching the board in a grab
        for (let i = 0; i < 2; i++) {
            let s = i == 0 ? -1.0 : 1.0;
            apply(this.R1, s * SH_X, SH_Y - HIP_Y, 0);     // shoulder in the root frame (lean only)
            let shx = vX, shy = vY + hipY + bob, shz = vZ;
            let ax = s * 0.45, ay = -1.0, az = 0.12;
            if (this.st == AIR) { ax = s * 0.9; ay = -0.5; az = 0.2; }
            if (this.st == GRIND) { ax = s * 1.0; ay = -0.35; az = 0.0; }
            if (push >= 0 && i == 0) { ax = -0.3; ay = -1; az = 0.4 * Math.sin(push * Math.PI * 2); }
            if (this.st == BAIL) { ax = s * 0.6; ay = 0.3; az = 0.6; }
            if (grab > 0 && i == 1) {
                // reach the board's front edge
                let gx = 0.22, gy = byLocal + 0.02, gz = 0.18;
                ax = ax * (1 - grab) + (gx - shx) * grab; ay = ay * (1 - grab) + (gy - shy) * grab; az = az * (1 - grab) + (gz - shz) * grab;
            }
            if (kite > 0 && i == 0) { ax = -0.6; ay = 0.5; az = 0.2; }
            aim(this.R3, ax, ay, az, 0, 0, 1);
            this.Rr.mul(R, this.R3);
            apply(R, shx, shy, shz);
            setBone(api, this.bArm[i], this.Rr, ox + vX, oy + vY, oz + vZ);
        }
    }

    // ------------------------------------------------------------------ the camera
    camera(api: GameApi, dt: f64): void {
        let lead = 0.35;
        let sx = this.st == BAIL ? this.x : this.x + this.vx * lead;
        let sz = this.st == BAIL ? this.z : this.z + this.vz * lead;
        let gy = this.st == AIR ? Math.min(this.y, this.takeY + 0.4) : this.y;
        let k = Math.min(1.0, dt * 3.0);
        this.camX += (sx - this.camX) * k;
        this.camZ += (sz - this.camZ) * k;
        this.camY += (clamp(gy * 0.6, -0.7, 0.7) - this.camY) * Math.min(1.0, dt * 2.0);
        api.useTarget = true;
        api.targetX = clamp(this.camX, -8.0, 8.5);
        api.targetY = this.camY + 0.5;
        api.targetZ = clamp(this.camZ, -6.2, 5.6);
    }

    // ------------------------------------------------------------------ the demo player
    demoPick(api: GameApi): void {
        let bestC = 1e9, bi = 0;
        for (let i = 0; i < NF; i++) {
            if (i == this.dHist0 || i == this.dHist1) continue;
            let ex = FEAT[i * 7], ez = FEAT[i * 7 + 1], ax = FEAT[i * 7 + 2], az = FEAT[i * 7 + 3];
            let dx = ex - this.x, dz = ez - this.z;
            let d = Math.sqrt(dx * dx + dz * dz);
            let ang = Math.abs(wrap(Math.atan2(dx, dz) - this.hd));
            let along = (this.x - ex) * ax + (this.z - ez) * az;
            let c = d * 0.5 + ang * 2.0 + (along > -1 ? 4 : 0) + api.range(0, 10) - (i == 3 || i == 4 ? 3 : 0);
            if (c < bestC) { bestC = c; bi = i; }
        }
        this.dHist1 = this.dHist0; this.dHist0 = bi;
        this.dF = bi; this.dPhase = 0; this.dClock = 0; this.dCoast = false; this.dTricks = 0; this.dBowl = 0;
        this.dErr = api.range(-0.18, 0.18);
        this.dGreedy = api.rand() < 0.2;    // now and then it wants one trick too many
    }

    demo(api: GameApi, dt: f64): void {
        if (this.st == BAIL) { this.pressing = false; return; }
        let i = this.dF;
        let ex = FEAT[i * 7], ez = FEAT[i * 7 + 1], ax = FEAT[i * 7 + 2], az = FEAT[i * 7 + 3];
        let px = FEAT[i * 7 + 4], pz = FEAT[i * 7 + 5];
        let kind = <i32>FEAT[i * 7 + 6];
        let along = (this.x - px) * ax + (this.z - pz) * az;
        let lat = -(this.x - px) * az + (this.z - pz) * ax;
        let sp = this.speed();
        let hdOk = (Math.sin(this.hd) * ax + Math.cos(this.hd) * az) > 0.9;
        this.dClock += dt;
        this.hasTgt = true;
        this.demoTricks(api, kind);
        if (this.st != GROUND) this.dFlat = 0;
        else this.dFlat += dt;
        if ((this.dPhase == 0 || along < -6.5) && this.st == GROUND && this.dFlat > 1.8 && sp > 3.8 && !this.pressing && this.flatAhead()) {
            // a flat-ground ollie on the way
            if (api.rand() < 0.05) { this.demoPress(); this.dTricks = 0; this.dPop = 0.3 + api.range(0, 0.15); }
        }
        if (this.dPop > 0) {
            this.dPop -= dt;
            if (this.dPop <= 0 && this.pressing && this.st == GROUND) this.demoRelease(api);
        }
        if (this.dPhase == 0 && kind == 4) {
            let bx = this.x - BX, bz = this.z - BZ;
            if (Math.sqrt(bx * bx + bz * bz) < 6.5) this.dPhase = 1;
        }
        if (this.dPhase == 0) {
            // head for the entry first (a little behind it), then take the line
            let dex = this.x - ex, dez = this.z - ez;
            this.tgtX = ex - ax * 1.5; this.tgtZ = ez - az * 1.5;
            this.dCoast = Math.sqrt(dex * dex + dez * dez) < 6;
            if (Math.sqrt(dex * dex + dez * dez) < 2.5 || (along < -2.5 && Math.abs(lat) < 0.8 && hdOk)) this.dPhase = 1;
            if (this.dClock > 10) this.demoPick(api);
            return;
        }
        // turned away from the line before reaching the feature: go round again
        if (this.st == GROUND && along < -1 && (Math.sin(this.hd) * ax + Math.cos(this.hd) * az) < -0.5 && kind != 4) {
            this.dPhase = 0;
            return;
        }
        // on the line: pursue it, act at the feature
        this.dCoast = Math.abs(lat) > 0.8 && along < -3;
        let q = along + Math.max(2.0, sp * 0.35);
        this.tgtX = px + ax * q - az * this.dErr; this.tgtZ = pz + az * q + ax * this.dErr;
        if (kind == 0 || kind == 1) {
            // crouch into the lip, pop off it
            if (this.st == GROUND && along > -2.0 && along < -1.0 && !this.pressing && this.dTricks == 0) this.demoPress();
            if (this.st == AIR && this.pressing && this.t - this.leftT > 0.03) this.demoRelease(api);
        } else if (kind == 2) {
            // ollie so the descent crosses the bar a metre in
            let c = 0.85;
            let vy = 2.4 + 2.4 * c;
            let ry = 0.55;
            if (Math.abs(pz - 6.0) > 0.01) ry = FH;
            let tdesc = (vy + Math.sqrt(Math.max(0, vy * vy - 2 * G * (ry + 0.05)))) / G;
            let need = sp * (tdesc + 0.38) - 1.0;
            if (this.st == GROUND && !this.pressing && -along <= need && along < 1.5 && this.dTricks == 0 && Math.abs(lat) < 0.45) {
                if (Math.abs(lat) < 0.4 && hdOk) this.demoPress();
                this.dTricks = 1;
            }
            if (this.pressing && this.st == GROUND && this.holdT >= 0.38) this.demoRelease(api);
            if (this.st == GRIND) this.dTricks = 3;
        } else if (kind == 3) {
            // over the fun box: ollie off its top
            surf(this.x, this.z);
            if (this.st == GROUND && !this.pressing && Math.abs(sY - FH) < 0.01 && along > -1.6 && this.dTricks == 0) { this.demoPress(); this.dTricks = 1; }
            if (this.pressing && this.st == GROUND && (this.holdT >= 0.3 || along > -0.4)) this.demoRelease(api);
        } else if (kind == 4) {
            // the bowl: across to the far wall for one air, then out the near side
            if (this.dBowl == 0) {
                this.tgtX = BX - 2.0; this.tgtZ = BZ + this.dErr;
                if (this.st == AIR && this.vert) this.dBowl = 1;
            } else {
                this.tgtX = BX + 7.0; this.tgtZ = BZ + 1.5;
                let dx = this.x - BX, dz = this.z - BZ;
                if (this.st == GROUND && Math.sqrt(dx * dx + dz * dz) > 4.0) { this.demoPick(api); return; }
            }
        }
        // a wind-up that found no lip: let it go
        if (this.pressing && this.st == GROUND && this.holdT > 0.8) this.demoRelease(api);
        if (this.st == GRIND && this.dTricks == 3 && this.grindT > 0.5 && api.rand() < 0.02) {
            this.demoPress(); this.holdT = 0.3;
        }
        if (this.st == GRIND && this.pressing && this.holdT > 0.45) this.demoRelease(api);
        // done with this feature
        if (this.st == AIR && this.vert && kind == 1) this.dBowl = 1;
        if (this.st == GROUND && kind == 1 && (this.dBowl == 1 || along > 0.5)) { this.demoPick(api); return; }
        if (this.st == GROUND && kind != 4 && (along > 2.5 || (kind == 1 && this.dClock > 1.5 && along < -4 && !hdOk))) this.demoPick(api);
        if (this.dClock > 12) this.demoPick(api);
        // the odd flat-ground ollie on the way
    }

    demoTricks(api: GameApi, kind: i32): void {
        if (this.st == AIR && this.trick < 0 && (this.dPhase == 0 || kind != 2) && this.t - this.leftT > 0.08) {
            let tl = this.timeLeft();
            if (this.dTricks < 3) {
                let pick = -1;
                let r = api.rand();
                let opts = 0;
                for (let k = 0; k < 6; k++) if (TDUR[k] < tl - 0.1) opts++;
                if (this.dGreedy && tl > 0.3 && this.dTricks >= 1) {
                    pick = <i32>Math.floor(api.rand() * 6);   // too much: likely a bail
                    this.dGreedy = false;
                } else if (opts > 0 && (this.dTricks <= 1 || r < 0.55)) {
                    let w = <i32>Math.floor(api.rand() * <f64>opts);
                    for (let k = 0; k < 6; k++) { if (TDUR[k] < tl - 0.1) { if (w == 0) { pick = k; break; } w--; } }
                }
                if (pick >= 0) {
                    this.doTrick(api, pick, api.rand() < 0.5 ? 1.0 : -1.0);
                    this.dTricks = this.dTricks <= 1 ? 2 : 3;
                } else this.dTricks = 3;
            }
        }
    }

    demoPress(): void {
        this.pressing = true; this.armed = true; this.holdT = 0;
    }
    demoRelease(api: GameApi): void {
        this.pressing = false;
        let c = Math.min(1.0, this.holdT / 0.45);
        if (this.st == GROUND || this.st == GRIND) this.ollie(api, c);
        else if (this.st == AIR && this.t - this.leftT < 0.2 && !this.ollied) this.latePop(api, c);
        this.armed = false;
    }

    // three metres of flat concrete ahead, and no rail in the way
    flatAhead(): boolean {
        let fx = Math.sin(this.hd), fz = Math.cos(this.hd);
        for (let k = 0; k <= 4; k++) {
            let d = <f64>k;
            surf(this.x + fx * d, this.z + fz * d);
            if (Math.abs(sY) > 0.001 || sGX != 0 || sGZ != 0) return false;
        }
        return Math.abs(this.z + fz * 2 - 6.0) > 1.0;
    }

    timeLeft(): f64 {
        surf(this.x, this.z);
        let dy = this.y - (this.vert ? this.takeY - 0.3 : sY);
        let disc = this.vy * this.vy + 2 * G * Math.max(dy, 0);
        return (this.vy + Math.sqrt(disc)) / G;
    }

    // ------------------------------------------------------------------ HUD
    hud(api: GameApi): void {
        let W = <f32>api.hudW, H = <f32>api.hudH;
        let white = api.rampColor(9, 4), ink = api.rampColor(11, 1), yellow = api.rampColor(7, 3);
        let red = api.rampColor(6, 3), teal = api.rampColor(15, 3), orange = api.rampColor(14, 4);
        let pale = api.rampColor(9, 3);
        // score, best, time
        if (this.mode != READY || api.demo) {
            api.text(4, 4, "SCORE " + this.score.toString(), white, 1, ink);
            api.text(4, 11, "BEST " + max<i32>(this.best, this.score).toString(), pale, 1, ink);
            let left = <i32>Math.max(0, Math.ceil(SESSION - this.t));
            let ts = left.toString();
            let tc = left <= 5 && this.mode == RUN ? red : white;
            api.text(W - 4 - api.textWidth(ts, 2), 4, ts, tc, 2, ink);
        }
        if (api.demo) api.text(W - 4 - api.textWidth("DEMO"), 16, "DEMO", yellow, 1, ink);
        // the skater's crouch: a wind-up bar beside it
        if (this.pressing && this.armed && this.crouch > 0.05 && this.mode == RUN && this.st != AIR && !api.demo) {
            if (api.project(<f32>this.x, <f32>(this.y + 0.2), <f32>this.z)) {
                let bx = Mathf.round(api.screenX + 10), by = Mathf.round(api.screenY - 14);
                api.rect(bx - 1, by - 1, 4, 14, ink);
                let hpx = Mathf.round(<f32>this.crouch * 12);
                api.rect(bx, by + 12 - hpx, 2, hpx, this.crouch >= 0.99 ? yellow : orange);
            }
        }
        // the trick just done, over the skater
        if (this.lastTrickT < 0.9 && this.mode != READY) {
            if (api.project(<f32>this.x, <f32>(this.y + 2.1), <f32>this.z)) {
                let w = api.textWidth(this.lastTrick);
                let lx = Mathf.min(Mathf.max(Mathf.round(api.screenX - w / 2), 2), W - w - 3);
                api.text(lx, Mathf.max(Mathf.round(api.screenY - 6), 20), this.lastTrick, yellow, 1, ink);
            }
        }
        // the combo line
        if (this.nCombo > 0 && this.mode != READY) {
            let s = "";
            let from = max<i32>(0, this.nCombo - 3);
            if (from > 0) s = "... + ";
            for (let i = from; i < this.nCombo; i++) {
                s += TNAME[this.combo[i]];
                if (i < this.nCombo - 1) s += " + ";
            }
            let w = api.textWidth(s);
            if (w > W - 8) { s = TNAME[this.combo[this.nCombo - 1]]; w = api.textWidth(s); }
            api.text(Mathf.floor((W - w) / 2), H - 22, s, white, 1, ink);
            let v = this.comboPts.toString() + " X" + this.mult().toString();
            api.textCentered(H - 14, v, this.wheelie > 0 ? yellow : teal, 1, ink);
            if (this.wheelie > 0 && this.st == GROUND) {
                let bw = <f32>Math.round(this.wheelie / WINDOW * 40);
                api.rect(Mathf.floor(W / 2 - 20), H - 7, 40, 2, ink);
                api.rect(Mathf.floor(W / 2 - 20), H - 7, bw, 2, yellow);
            }
        }
        // a banked combo pops up
        if (this.popT < 1.2 && this.mode != READY) {
            if (api.project(<f32>this.popX, <f32>this.popY, <f32>this.popZ)) {
                let rise = Mathf.floor(<f32>this.popT * 14);
                let w = api.textWidth(this.pop, 2);
                let lx = Mathf.min(Mathf.max(Mathf.round(api.screenX - w / 2), 2), W - w - 4);
                api.text(lx, Mathf.max(Mathf.round(api.screenY - 8 - rise), 22), this.pop, yellow, 2, ink);
            }
        }
        if (this.msgT < 1.0) {
            api.textCentered(Mathf.floor(H * 0.3), this.msg, red, 2, ink);
        }
        if (this.mode == READY && !api.demo) {
            api.textCentered(10, "KICK PARK", yellow, 3, ink);
            api.textCentered(H - 36, "DRAG TO STEER", white, 1, ink);
            api.textCentered(H - 28, "PRESS, HOLD, RELEASE: OLLIE", white, 1, ink);
            api.textCentered(H - 20, "SWIPE IN THE AIR: TRICKS", white, 1, ink);
            api.textCentered(H - 11, "CLICK TO START", orange, 1, ink);
        }
        if (this.mode == OVER) {
            let cy = Mathf.floor(H * 0.22);
            api.rect(Mathf.floor(W / 2 - 64), cy - 6, 128, 64, ink);
            api.textCentered(cy, "SESSION OVER", yellow, 2, 0);
            api.textCentered(cy + 16, "SCORE " + this.score.toString(), white, 1, 0);
            api.textCentered(cy + 25, "BEST COMBO " + this.sessionBestCombo.toString(), pale, 1, 0);
            api.textCentered(cy + 34, (this.newBest ? "NEW BEST " : "BEST ") + this.best.toString(), this.newBest ? orange : pale, 1, 0);
            if (!api.demo && this.overT > 0.8) api.textCentered(cy + 46, "CLICK FOR A NEW SESSION", teal, 1, 0);
        }
    }
}
