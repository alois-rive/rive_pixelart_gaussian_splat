// Snowball Run: steer a snowball down a piste with the pointer. It grows as it rolls and grows more
// when it flattens a snowman (points, and a combo for quick ones); a pine knocks a third of it off.
// Too small after a crash and it bursts: game over. One verb (move the pointer), one world.
// Demo mode (api.demo) skis itself like a decent player, with the odd pine.
import { GameApi, POINTER_DOWN, POINTER_MOVE } from "./game_api";

const BALL_Z: f64 = 3.4;      // the snowball's centre, metres towards the camera
const SPAWN_Z: f64 = -12.6;   // obstacles come up at the piste's far edge (in the fog)
const KILL_Z: f64 = 9.5;      // and leave below the frame
const PISTE: f64 = 4.7;       // |x| the snowball and the obstacles keep to
const R0: f64 = 0.55;
const R_MIN: f64 = 0.36;
const HIT: f64 = 0.7;        // a pine leaves this much of the snowball
const R_MAX: f64 = 1.12;
const NT: i32 = 9;            // pines on the piste
const NS: i32 = 4;            // snowmen
const NSIDE: i32 = 12;        // pines on the banks
const NM: i32 = 6;            // mounds
const NR: i32 = 4;            // rocks
const NP: i32 = 8;            // spray
const NC: i32 = 6;            // chunks

const READY: i32 = 0;
const RUN: i32 = 1;
const OVER: i32 = 2;

// A game bone turned (yaw, pitch, roll as GameApi.place) and squashed in world axes after the turn.
function pose(api: GameApi, b: i32, x: f64, y: f64, z: f64, yawDeg: f64, pitchDeg: f64, rollDeg: f64,
              sx: f64, sy: f64, sz: f64): void {
    if (b <= 0 || b >= 64) {
        return;
    }
    if (Math.abs(sx) < 0.05 || Math.abs(sy) < 0.05 || Math.abs(sz) < 0.05) {
        api.hide(b);   // a singular bone would blow every splat of it up to a giant quad
        return;
    }
    let cy = Math.cos(yawDeg * Math.PI / 180), sny = Math.sin(yawDeg * Math.PI / 180);
    let cp = Math.cos(pitchDeg * Math.PI / 180), sp = Math.sin(pitchDeg * Math.PI / 180);
    let cr = Math.cos(rollDeg * Math.PI / 180), sr = Math.sin(rollDeg * Math.PI / 180);
    let r00 = cy * cr + sny * sp * sr, r01 = -cy * sr + sny * sp * cr, r02 = sny * cp;
    let r10 = cp * sr, r11 = cp * cr, r12 = -sp;
    let r20 = -sny * cr + cy * sp * sr, r21 = sny * sr + cy * sp * cr, r22 = cy * cp;
    let y0 = <f64>api.restYaw[b] * Math.PI / 180;
    let c0 = Math.cos(y0), s0 = Math.sin(y0);
    let a00 = (r00 * c0 + r02 * s0) * sx, a01 = r01 * sx, a02 = (-r00 * s0 + r02 * c0) * sx;
    let a10 = (r10 * c0 + r12 * s0) * sy, a11 = r11 * sy, a12 = (-r10 * s0 + r12 * c0) * sy;
    let a20 = (r20 * c0 + r22 * s0) * sz, a21 = r21 * sz, a22 = (-r20 * s0 + r22 * c0) * sz;
    let px = <f64>api.restX[b], py = <f64>api.restY[b], pz = <f64>api.restZ[b];
    let m = b * 12;
    api.mats[m] = <f32>a00; api.mats[m + 1] = <f32>a01; api.mats[m + 2] = <f32>a02;
    api.mats[m + 3] = <f32>(x - (a00 * px + a01 * py + a02 * pz));
    api.mats[m + 4] = <f32>a10; api.mats[m + 5] = <f32>a11; api.mats[m + 6] = <f32>a12;
    api.mats[m + 7] = <f32>(y - (a10 * px + a11 * py + a12 * pz));
    api.mats[m + 8] = <f32>a20; api.mats[m + 9] = <f32>a21; api.mats[m + 10] = <f32>a22;
    api.mats[m + 11] = <f32>(z - (a20 * px + a21 * py + a22 * pz));
    api.dirty[b] = true;
    api.anyDirty = true;
}

function clamp(v: f64, a: f64, b: f64): f64 {
    return v < a ? a : (v > b ? b : v);
}

// The banks: flat piste to |x| 5.5, rising 1.5 m by |x| 8.
function bankY(x: f64): f64 {
    return clamp((Math.abs(x) - 5.5) / 2.5, 0, 1) * 1.5;
}

// A pop-in scale: 0 -> 1.15 -> 1 over 0.3 s, stepped at 12 fps.
function popScale(t: f64): f64 {
    let u = Math.floor(t * 12) / 12 / 0.3;
    if (u >= 1) return 1;
    return u < 0.7 ? u / 0.7 * 1.15 : 1.15 - (u - 0.7) / 0.3 * 0.15;
}

export class Game {
    ball: i32 = -1;
    tree: StaticArray<i32> = new StaticArray<i32>(NT);
    man: StaticArray<i32> = new StaticArray<i32>(NS);
    side: StaticArray<i32> = new StaticArray<i32>(NSIDE);
    mound: StaticArray<i32> = new StaticArray<i32>(NM);
    rock: StaticArray<i32> = new StaticArray<i32>(NR);
    spray: StaticArray<i32> = new StaticArray<i32>(NP);
    chunk: StaticArray<i32> = new StaticArray<i32>(NC);

    mode: i32 = READY;
    t: f64 = 0;
    speed: f64 = 0;
    dist: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    men: i32 = 0;
    combo: i32 = 0;
    comboT: f64 = 9;
    nextRow: f64 = 0;         // distance at which the next row of obstacles comes up
    nextDecor: f64 = 0;

    bx: f64 = 0;
    bvx: f64 = 0;
    tx: f64 = 0;
    r: f64 = R0;
    pitchA: f64 = 0;
    rollA: f64 = 0;
    squash: f64 = 0;
    inv: f64 = 0;
    hop: f64 = 0;

    tOn: StaticArray<bool> = new StaticArray<bool>(NT);
    tX: StaticArray<f64> = new StaticArray<f64>(NT);
    tZ: StaticArray<f64> = new StaticArray<f64>(NT);
    tYaw: StaticArray<f64> = new StaticArray<f64>(NT);
    tPop: StaticArray<f64> = new StaticArray<f64>(NT);
    tWob: StaticArray<f64> = new StaticArray<f64>(NT);
    tHit: StaticArray<bool> = new StaticArray<bool>(NT);

    sOn: StaticArray<bool> = new StaticArray<bool>(NS);
    sX: StaticArray<f64> = new StaticArray<f64>(NS);
    sZ: StaticArray<f64> = new StaticArray<f64>(NS);
    sYaw: StaticArray<f64> = new StaticArray<f64>(NS);
    sPop: StaticArray<f64> = new StaticArray<f64>(NS);
    sFlat: StaticArray<f64> = new StaticArray<f64>(NS);   // < 0: standing; else seconds since flattened

    sideX: StaticArray<f64> = new StaticArray<f64>(NSIDE);
    sideZ: StaticArray<f64> = new StaticArray<f64>(NSIDE);
    sideS: StaticArray<f64> = new StaticArray<f64>(NSIDE);
    sidePop: StaticArray<f64> = new StaticArray<f64>(NSIDE);

    mOn: StaticArray<bool> = new StaticArray<bool>(NM);
    mX: StaticArray<f64> = new StaticArray<f64>(NM);
    mZ: StaticArray<f64> = new StaticArray<f64>(NM);
    mYaw: StaticArray<f64> = new StaticArray<f64>(NM);
    mPop: StaticArray<f64> = new StaticArray<f64>(NM);
    rOn: StaticArray<bool> = new StaticArray<bool>(NR);
    rX: StaticArray<f64> = new StaticArray<f64>(NR);
    rZ: StaticArray<f64> = new StaticArray<f64>(NR);
    rYaw: StaticArray<f64> = new StaticArray<f64>(NR);
    rPop: StaticArray<f64> = new StaticArray<f64>(NR);

    pX: StaticArray<f64> = new StaticArray<f64>(NP);
    pY: StaticArray<f64> = new StaticArray<f64>(NP);
    pZ: StaticArray<f64> = new StaticArray<f64>(NP);
    pVX: StaticArray<f64> = new StaticArray<f64>(NP);
    pVY: StaticArray<f64> = new StaticArray<f64>(NP);
    pVZ: StaticArray<f64> = new StaticArray<f64>(NP);
    pT: StaticArray<f64> = new StaticArray<f64>(NP);
    pLife: StaticArray<f64> = new StaticArray<f64>(NP);
    pNext: i32 = 0;
    sprayT: f64 = 0;

    cX: StaticArray<f64> = new StaticArray<f64>(NC);
    cY: StaticArray<f64> = new StaticArray<f64>(NC);
    cZ: StaticArray<f64> = new StaticArray<f64>(NC);
    cVX: StaticArray<f64> = new StaticArray<f64>(NC);
    cVY: StaticArray<f64> = new StaticArray<f64>(NC);
    cVZ: StaticArray<f64> = new StaticArray<f64>(NC);
    cT: StaticArray<f64> = new StaticArray<f64>(NC);
    cS: StaticArray<f64> = new StaticArray<f64>(NC);
    cNext: i32 = 0;

    shake: f64 = 0;
    shX: f64 = 0;
    shY: f64 = 0;
    popText: string = "";
    popT: f64 = 9;
    popX: f64 = 0;
    popZ: f64 = 0;
    flash: f64 = 9;           // seconds since a pine hit (the size line blinks)

    wasDemo: bool = false;
    demoT: f64 = 0;
    demoAim: f64 = 0;
    demoLapse: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        this.ball = api.bone("ball");
        for (let i = 0; i < NT; i++) this.tree[i] = api.bone("tree" + i.toString());
        for (let i = 0; i < NS; i++) this.man[i] = api.bone("snowman" + i.toString());
        for (let i = 0; i < NSIDE; i++) this.side[i] = api.bone("side" + i.toString());
        for (let i = 0; i < NM; i++) this.mound[i] = api.bone("mound" + i.toString());
        for (let i = 0; i < NR; i++) this.rock[i] = api.bone("rock" + i.toString());
        for (let i = 0; i < NP; i++) { this.spray[i] = api.bone("spray" + i.toString()); this.pT[i] = 99; this.pLife[i] = 1; }
        for (let i = 0; i < NC; i++) { this.chunk[i] = api.bone("chunk" + i.toString()); this.cT[i] = 99; }
        // the banks' pines, both sides, evenly spread down the slope
        for (let i = 0; i < NSIDE; i++) {
            let s = i % 2 == 0 ? -1.0 : 1.0;
            this.sideX[i] = s * api.range(6.3, 8.6);
            this.sideZ[i] = SPAWN_Z + (KILL_Z - SPAWN_Z) * <f64>(i / 2) / <f64>(NSIDE / 2) + api.range(0, 1.5);
            this.sideS[i] = api.range(0.85, 1.25);
            this.sidePop[i] = 9;
        }
        this.wasDemo = api.demo;
        this.newRun(api, api.demo ? RUN : READY);
    }

    newRun(api: GameApi, mode: i32): void {
        this.mode = mode;
        this.t = 0;
        this.speed = mode == RUN ? 6.5 : 0;
        this.dist = 0;
        this.score = 0;
        this.bonus = 0;
        this.men = 0;
        this.combo = 0;
        this.comboT = 9;
        this.bx = 0;
        this.bvx = 0;
        this.tx = 0;
        this.r = R0;
        this.squash = 0;
        this.inv = 0;
        this.popT = 9;
        this.flash = 9;
        for (let i = 0; i < NT; i++) { this.tOn[i] = false; api.hide(this.tree[i]); }
        for (let i = 0; i < NS; i++) { this.sOn[i] = false; api.hide(this.man[i]); }
        for (let i = 0; i < NM; i++) { this.mOn[i] = false; api.hide(this.mound[i]); }
        for (let i = 0; i < NR; i++) { this.rOn[i] = false; api.hide(this.rock[i]); }
        // the slope is already dressed: rows from the far edge down to a few metres before the ball
        let z = SPAWN_Z + 0.5;
        let first = true;
        while (z < BALL_Z - 7.5) {
            this.spawnRow(api, z, first, true);
            first = false;
            z += api.range(3.6, 4.6);
        }
        for (let k = 0; k < 4; k++) {
            this.spawnDecor(api, SPAWN_Z + 2 + k * 4.5, true);
        }
        this.nextRow = 4.2;
        this.nextDecor = 3;
    }

    freeTree(): i32 {
        for (let i = 0; i < NT; i++) if (!this.tOn[i]) return i;
        return -1;
    }

    freeMan(): i32 {
        for (let i = 0; i < NS; i++) if (!this.sOn[i]) return i;
        return -1;
    }

    // One row across the piste: one or two pines, sometimes a snowman, never on top of each other.
    spawnRow(api: GameApi, z: f64, gentle: bool, popped: bool = false): void {
        let pop0 = popped ? 1.0 : 0.0;
        let xs = new StaticArray<f64>(4);
        let n = 0;
        let hard = clamp(this.dist / 650, 0, 1);
        let trees = api.rand() < 0.4 + hard * 0.45 ? 2 : 1;
        if (hard > 0.6 && api.rand() < 0.25) trees = 3;
        if (gentle) trees = 1;
        for (let k = 0; k < trees; k++) {
            let i = this.freeTree();
            if (i < 0) break;
            let x = 0.0;
            for (let tries = 0; tries < 8; tries++) {
                x = api.range(-PISTE, PISTE);
                let ok = true;
                for (let j = 0; j < n; j++) if (Math.abs(xs[j] - x) < 2.6) ok = false;
                if (ok) break;
            }
            xs[n++] = x;
            this.tOn[i] = true;
            this.tX[i] = x;
            this.tZ[i] = z + api.range(-0.5, 0.5);
            this.tYaw[i] = api.range(0, 360);
            this.tPop[i] = pop0;
            this.tWob[i] = 9;
            this.tHit[i] = false;
        }
        if (api.rand() < 0.62) {
            let i = this.freeMan();
            if (i >= 0) {
                let x = 0.0;
                for (let tries = 0; tries < 8; tries++) {
                    x = api.range(-PISTE + 0.3, PISTE - 0.3);
                    let ok = true;
                    for (let j = 0; j < n; j++) if (Math.abs(xs[j] - x) < 2.4) ok = false;
                    if (ok) break;
                }
                this.sOn[i] = true;
                this.sX[i] = x;
                this.sZ[i] = z + api.range(-0.4, 0.4);
                this.sYaw[i] = api.range(-25, 25);
                this.sPop[i] = pop0;
                this.sFlat[i] = -1;
            }
        }
    }

    spawnDecor(api: GameApi, z: f64, popped: bool = false): void {
        let pop0 = popped ? 1.0 : 0.0;
        for (let i = 0; i < NM; i++) {
            if (!this.mOn[i]) {
                this.mOn[i] = true;
                this.mX[i] = api.range(-PISTE - 0.5, PISTE + 0.5);
                this.mZ[i] = z;
                this.mYaw[i] = api.range(-30, 30);
                this.mPop[i] = pop0;
                break;
            }
        }
        if (api.rand() < 0.5) {
            for (let i = 0; i < NR; i++) {
                if (!this.rOn[i]) {
                    this.rOn[i] = true;
                    let s = api.rand() < 0.5 ? -1.0 : 1.0;
                    this.rX[i] = s * api.range(5.2, 6.4);
                    this.rZ[i] = z + api.range(-1, 1);
                    this.rYaw[i] = api.range(0, 360);
                    this.rPop[i] = pop0;
                    break;
                }
            }
        }
    }

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.best = 0;   // the visitor's best is their own, not the demo's
            this.newRun(api, api.demo ? RUN : READY);
        }
        this.t += dt;

        if (this.mode == READY) {
            this.speed = 0;
        } else if (this.mode == RUN) {
            // faster and faster: 6.5 m/s up to 13
            this.speed = Math.min(13, Math.max(this.speed, 6.5) + dt * 0.09);
            if (this.t < 0.5) this.speed = 6.5 * Math.min(1, 0.3 + this.t * 1.4);
            if (api.demo) this.demoSteer(api, dt);
        } else {
            this.speed = Math.max(0, this.speed - dt * 9);
            if (api.demo && this.t > 2.0) {
                this.newRun(api, RUN);
            }
        }
        let dz = this.speed * dt;
        this.dist += dz;

        if (this.mode == RUN) {
            // the ball follows the pointer (a spring with a top speed) and grows as it rolls
            let want = clamp((this.tx - this.bx) * 7, -8, 8);
            this.bvx += (want - this.bvx) * Math.min(1, dt * 10);
            this.bx = clamp(this.bx + this.bvx * dt, -PISTE, PISTE);
            this.r = Math.min(R_MAX, this.r + dt * 0.0085 * this.speed / 6.5);
            this.nextRow -= dz;
            if (this.nextRow <= 0) {
                this.spawnRow(api, SPAWN_Z, false);
                let hard = clamp(this.dist / 650, 0, 1);
                this.nextRow = api.range(4.2, 5.4) - hard * 1.5;
            }
            this.nextDecor -= dz;
            if (this.nextDecor <= 0) {
                this.spawnDecor(api, SPAWN_Z);
                this.nextDecor = api.range(3.0, 5.0);
            }
        } else if (this.mode == READY) {
            this.bvx = 0;
        }
        if (this.mode == RUN) {
            this.score = <i32>Math.floor(this.dist) + this.bonus;
        }
        this.inv = Math.max(0, this.inv - dt);
        this.squash = Math.max(0, this.squash - dt * 3.5);
        this.comboT += dt;
        this.popT += dt;
        this.flash += dt;

        // the world slides towards the camera
        this.hop = 0;
        for (let i = 0; i < NT; i++) {
            if (!this.tOn[i]) continue;
            this.tZ[i] += dz;
            this.tPop[i] += dt;
            this.tWob[i] += dt;
            if (this.tZ[i] > KILL_Z) { this.tOn[i] = false; continue; }
            if (this.mode == RUN && !this.tHit[i] && this.inv <= 0 &&
                Math.abs(this.tX[i] - this.bx) < 0.75 + this.r * 0.8 && Math.abs(this.tZ[i] - BALL_Z) < 0.4 + this.r * 0.6) {
                this.hitTree(api, i);
            }
        }
        for (let i = 0; i < NS; i++) {
            if (!this.sOn[i]) continue;
            this.sZ[i] += dz;
            this.sPop[i] += dt;
            if (this.sFlat[i] >= 0) this.sFlat[i] += dt;
            if (this.sZ[i] > KILL_Z || this.sFlat[i] > 0.9) { this.sOn[i] = false; continue; }
            if (this.mode == RUN && this.sFlat[i] < 0 &&
                Math.abs(this.sX[i] - this.bx) < 0.4 + this.r * 0.8 && Math.abs(this.sZ[i] - BALL_Z) < 0.35 + this.r * 0.6) {
                this.flatten(api, i);
            }
        }
        for (let i = 0; i < NM; i++) {
            if (!this.mOn[i]) continue;
            this.mZ[i] += dz;
            this.mPop[i] += dt;
            if (this.mZ[i] > KILL_Z + 1) { this.mOn[i] = false; continue; }
            let ddx = Math.abs(this.mX[i] - this.bx), ddz = Math.abs(this.mZ[i] - BALL_Z);
            if (ddx < 1.0 + this.r * 0.5 && ddz < 0.7) {
                this.hop = Math.max(this.hop, 0.32 * (1 - ddz / 0.7));
            }
        }
        for (let i = 0; i < NR; i++) {
            if (!this.rOn[i]) continue;
            this.rZ[i] += dz;
            this.rPop[i] += dt;
            if (this.rZ[i] > KILL_Z + 1) this.rOn[i] = false;
        }
        for (let i = 0; i < NSIDE; i++) {
            this.sideZ[i] += dz;
            this.sidePop[i] += dt;
            if (this.sideZ[i] > KILL_Z + 1.5) {
                this.sideZ[i] -= (KILL_Z + 1.5 - SPAWN_Z);
                let s = this.sideX[i] < 0 ? -1.0 : 1.0;
                this.sideX[i] = s * api.range(6.3, 8.6);
                this.sideS[i] = api.range(0.85, 1.25);
                this.sidePop[i] = 0;
            }
        }

        // rolling: the ball turns about X by distance / radius, about Z as it swerves
        this.pitchA -= dz / this.r * 180 / Math.PI;
        this.rollA -= this.bvx * dt / this.r * 180 / Math.PI * 0.6;
        this.updateSpray(api, dt);
        this.updateChunks(api, dt);

        this.shake = Math.max(0, this.shake - dt * 1.2);
        if (Math.floor(api.time * 15) != Math.floor((api.time - dt) * 15)) {
            this.shX = (api.rand() - 0.5) * this.shake;
            this.shY = (api.rand() - 0.5) * this.shake;
        }
        api.targetX = this.shX;
        api.targetY = this.shY;
        this.draw(api);
    }

    bonus: i32 = 0;

    hitTree(api: GameApi, i: i32): void {
        this.tHit[i] = true;
        this.tWob[i] = 0;
        this.inv = 0.7;
        this.squash = 1;
        this.shake = 0.5;
        this.flash = 0;
        this.combo = 0;
        for (let k = 0; k < 4; k++) {
            this.throwChunk(api, this.bx, this.r, BALL_Z, api.range(-3, 3), api.range(2.5, 5), api.range(0.5, 3.5), this.r * 0.9);
        }
        this.r *= HIT;
        if (this.r < R_MIN) {
            this.burst(api);
        }
    }

    burst(api: GameApi): void {
        this.mode = OVER;
        this.t = 0;
        this.shake = 0.8;
        if (this.score > this.best) this.best = this.score;
        for (let k = 0; k < NC; k++) {
            this.throwChunk(api, this.bx, this.r, BALL_Z, api.range(-4, 4), api.range(3, 6), api.range(-1, 4), 0.9);
        }
        for (let k = 0; k < NP; k++) {
            this.throwSpray(api, this.bx, this.r, BALL_Z, api.range(-3, 3), api.range(2, 5), api.range(-1, 3));
        }
    }

    flatten(api: GameApi, i: i32): void {
        this.sFlat[i] = 0;
        this.men++;
        if (this.comboT < 3.0) {
            this.combo = this.combo < 3 ? this.combo + 1 : 3;
        } else {
            this.combo = 0;
        }
        this.comboT = 0;
        let pts = 25 * (this.combo + 1);
        this.bonus += pts;
        this.r = Math.min(R_MAX, this.r + 0.05);
        this.squash = 0.6;
        this.shake = 0.15;
        this.popText = "+" + pts.toString() + (this.combo > 0 ? " X" + (this.combo + 1).toString() : "");
        this.popT = 0;
        this.popX = this.sX[i];
        this.popZ = this.sZ[i];
        for (let k = 0; k < 3; k++) {
            this.throwChunk(api, this.sX[i], 1.0, this.sZ[i], api.range(-2.5, 2.5), api.range(2.5, 4.5), api.range(-1.5, 1.5), 0.7);
        }
    }

    throwChunk(api: GameApi, x: f64, y: f64, z: f64, vx: f64, vy: f64, vz: f64, s: f64): void {
        let k = this.cNext;
        this.cNext = (this.cNext + 1) % NC;
        this.cX[k] = x; this.cY[k] = y; this.cZ[k] = z;
        this.cVX[k] = vx; this.cVY[k] = vy; this.cVZ[k] = vz;
        this.cT[k] = 0;
        this.cS[k] = s;
    }

    throwSpray(api: GameApi, x: f64, y: f64, z: f64, vx: f64, vy: f64, vz: f64): void {
        let k = this.pNext;
        this.pNext = (this.pNext + 1) % NP;
        this.pX[k] = x; this.pY[k] = y; this.pZ[k] = z;
        this.pVX[k] = vx; this.pVY[k] = vy; this.pVZ[k] = vz;
        this.pT[k] = 0;
        this.pLife[k] = api.range(0.35, 0.55);
    }

    updateSpray(api: GameApi, dt: f64): void {
        // a rolling snowball throws snow off its sides
        this.sprayT -= dt;
        if (this.mode == RUN && this.sprayT <= 0) {
            this.sprayT = 0.07;
            let s = api.rand() < 0.5 ? -1.0 : 1.0;
            this.throwSpray(api, this.bx + s * this.r * 0.75, 0.15, BALL_Z + this.r * 0.3,
                            s * api.range(0.8, 2.0) + this.bvx * 0.3, api.range(1.6, 3.0), this.speed * api.range(0.3, 0.6));
        }
        for (let i = 0; i < NP; i++) {
            if (this.pT[i] >= this.pLife[i]) {
                api.hide(this.spray[i]);
                continue;
            }
            this.pT[i] += dt;
            this.pVY[i] -= 9 * dt;
            this.pX[i] += this.pVX[i] * dt;
            this.pY[i] += this.pVY[i] * dt;
            this.pZ[i] += this.pVZ[i] * dt;
            let u = this.pT[i] / this.pLife[i];
            let s = Math.floor((1.3 - u) * 4) / 4;
            if (this.pY[i] < 0 || s < 0.25) {
                api.hide(this.spray[i]);
                continue;
            }
            api.place(this.spray[i], this.pX[i], this.pY[i], this.pZ[i], 0, 0, 0, s);
        }
    }

    updateChunks(api: GameApi, dt: f64): void {
        for (let i = 0; i < NC; i++) {
            if (this.cT[i] > 1.3) {
                api.hide(this.chunk[i]);
                continue;
            }
            this.cT[i] += dt;
            this.cVY[i] -= 10 * dt;
            this.cX[i] += this.cVX[i] * dt;
            this.cY[i] += this.cVY[i] * dt;
            this.cZ[i] += (this.cVZ[i] + this.speed * 0.8) * dt;
            if (this.cY[i] < 0.15) {
                this.cY[i] = 0.15;
                this.cVY[i] = -this.cVY[i] * 0.3;
                this.cVX[i] *= 0.6;
            }
            let s = this.cS[i] * (this.cT[i] > 0.9 ? Math.max(0, 1 - (this.cT[i] - 0.9) / 0.4) : 1);
            s = Math.floor(s * 6) / 6;
            if (s < 0.2) {
                api.hide(this.chunk[i]);
                continue;
            }
            api.place(this.chunk[i], this.cX[i], this.cY[i], this.cZ[i], this.cT[i] * 300, this.cT[i] * 200, 0, s);
        }
    }

    // The demo skier: looks ahead along a few lanes, avoids the nearest pines, goes for snowmen, keeps
    // close to where it is; re-plans five times a second with a little aim error; now and then it is
    // late to see a pine.
    demoSteer(api: GameApi, dt: f64): void {
        this.demoT -= dt;
        if (this.demoT > 0) {
            this.tx = this.demoAim;
            return;
        }
        this.demoT = 0.2;
        if (this.demoLapse > 0) {
            // a lapse: the skier keeps its line without looking for a moment
            this.demoLapse -= 0.2;
            this.tx = this.demoAim;
            return;
        }
        if (api.rand() < 0.09) {
            this.demoLapse = 0.7;
        }
        let careless = api.rand() < 0.06;
        let bestX = this.bx, bestV = -1e9;
        for (let k = 0; k <= 12; k++) {
            let x = -PISTE + 2 * PISTE * <f64>k / 12.0;
            let v = -Math.abs(x - this.bx) * 0.35;
            for (let i = 0; i < NT; i++) {
                if (!this.tOn[i] || this.tHit[i]) continue;
                let ahead = BALL_Z - this.tZ[i];
                if (ahead < -0.3 || ahead > 9.5) continue;
                if (careless && ahead < 3.2) continue;
                let w = 1.0 + this.r * 0.8;
                let d = Math.abs(this.tX[i] - x);
                if (d < w) v -= 10 * (1 - d / w) + 6 * (1 - ahead / 9.5);
            }
            for (let i = 0; i < NS; i++) {
                if (!this.sOn[i] || this.sFlat[i] >= 0) continue;
                let ahead = BALL_Z - this.sZ[i];
                if (ahead < 0 || ahead > 8) continue;
                let d = Math.abs(this.sX[i] - x);
                if (d < 0.9) v += 4 * (1 - d / 0.9);
            }
            if (v > bestV) {
                bestV = v;
                bestX = x;
            }
        }
        this.demoAim = clamp(bestX + api.range(-0.35, 0.35), -PISTE, PISTE);
        this.tx = this.demoAim;
    }

    draw(api: GameApi): void {
        // the ball: rolls, squashes on hits, blinks while it shakes a hit off, bursts at the end
        if (this.mode == OVER) {
            api.hide(this.ball);
        } else if (this.inv > 0 && Math.floor(this.inv * 12) % 2 == 1) {
            api.hide(this.ball);
        } else {
            let wob = this.mode == READY ? Math.sin(api.time * 5) * 0.05 : 0;
            let sq = Math.sin(Math.min(1, this.squash) * Math.PI * 0.5) * 0.28 + wob;
            let sy = 1 - sq, sxz = 1 + sq * 0.55;
            let s = this.r;  // the ball is baked at r 1.0
            pose(api, this.ball, this.bx, this.r * sy + this.hop, BALL_Z, 0, this.pitchA, this.rollA, s * sxz, s * sy, s * sxz);
        }
        for (let i = 0; i < NT; i++) {
            if (!this.tOn[i]) { api.hide(this.tree[i]); continue; }
            let p = popScale(this.tPop[i]);
            let wob = this.tWob[i] < 1.2 ? Math.sin(this.tWob[i] * 22) * 14 * (1 - this.tWob[i] / 1.2) : 0;
            wob = Math.round(wob / 4) * 4;
            pose(api, this.tree[i], this.tX[i], 0, this.tZ[i], this.tYaw[i], 0, wob, p, p, p);
        }
        for (let i = 0; i < NS; i++) {
            if (!this.sOn[i]) { api.hide(this.man[i]); continue; }
            let p = popScale(this.sPop[i]);
            let f = this.sFlat[i];
            if (f < 0) {
                // idle: a tiny stepped sway, as if it had been waiting
                let k = Math.floor(api.time * 4 + i) % 4;
                let roll = k == 1 ? 3.0 : (k == 3 ? -3.0 : 0.0);
                pose(api, this.man[i], this.sX[i], 0, this.sZ[i], this.sYaw[i], 0, roll, p, p, p);
            } else {
                // flattened: squashed in two frames, spread, then sinks into the snow
                let sy = f < 0.08 ? 0.45 : 0.18;
                let sx = f < 0.08 ? 1.35 : 1.7;
                let y = f > 0.5 ? -(f - 0.5) * 0.9 : 0;
                pose(api, this.man[i], this.sX[i], y, this.sZ[i], this.sYaw[i], 0, 0, sx, sy, sx);
            }
        }
        for (let i = 0; i < NM; i++) {
            if (!this.mOn[i]) { api.hide(this.mound[i]); continue; }
            let p = popScale(this.mPop[i]);
            pose(api, this.mound[i], this.mX[i], 0, this.mZ[i], this.mYaw[i], 0, 0, p, p, p);
        }
        for (let i = 0; i < NR; i++) {
            if (!this.rOn[i]) { api.hide(this.rock[i]); continue; }
            let p = popScale(this.rPop[i]);
            pose(api, this.rock[i], this.rX[i], bankY(this.rX[i]) * 0.9, this.rZ[i], this.rYaw[i], 0, 0, p, p, p);
        }
        for (let i = 0; i < NSIDE; i++) {
            let p = popScale(this.sidePop[i]) * this.sideS[i];
            pose(api, this.side[i], this.sideX[i], bankY(this.sideX[i]) - 0.1, this.sideZ[i], i * 47.0, 0, 0, p, p, p);
        }
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN || kind == POINTER_MOVE) {
            if (api.pick(x, y, 0)) {
                this.tx = clamp(<f64>api.hitX, -PISTE, PISTE);
            }
        }
        if (kind == POINTER_DOWN) {
            if (this.mode == READY) {
                this.mode = RUN;
                this.t = 0;
                this.squash = 0.8;   // the push-off
            } else if (this.mode == OVER && this.t > 0.7) {
                this.newRun(api, RUN);
                this.squash = 0.8;
            }
        }
        return true;
    }

    hud(api: GameApi): void {
        let plum = api.paletteColor(0);
        let coral = api.paletteColor(1);
        let peach = api.paletteColor(2);
        let cream = api.paletteColor(3);
        let W = <f32>api.hudW;
        let H = <f32>api.hudH;

        api.text(4, 4, "SCORE " + this.score.toString(), cream, 1, plum);
        let bs = "BEST " + this.best.toString();
        api.text(W - 4 - api.textWidth(bs, 1), 4, bs, cream, 1, plum);
        if (api.demo) {
            api.textCentered(4, "DEMO", peach, 1, plum);
        }
        // the snowball's size: a bar of snow, the danger mark where a pine would burst it
        if (this.mode != READY) {
            let w = <f32>Math.round((this.r - R_MIN * HIT) / (R_MAX - R_MIN * HIT) * 40);
            api.text(4, 12, "SIZE", cream, 1, plum);
            api.rect(21, 12, 42, 5, plum);
            let blink = this.flash < 0.6 && Math.floor(this.flash * 10) % 2 == 0;
            if (!blink) api.rect(22, 13, w, 3, this.r * HIT < R_MIN ? coral : cream);
            let mark = <f32>Math.round((R_MIN / HIT - R_MIN * HIT) / (R_MAX - R_MIN * HIT) * 40);
            api.rect(22 + mark, 11, 1, 7, coral);
        }
        if (this.popT < 1.0 && api.project(<f32>this.popX, <f32>(2.2 + this.popT * 1.2), <f32>this.popZ)) {
            let x = api.screenX - api.textWidth(this.popText, 1) * 0.5;
            api.text(x, api.screenY, this.popText, cream, 1, plum);
        }
        if (this.mode == READY) {
            api.rect(0, H - 26, W, 20, plum);
            api.textCentered(H - 22, "CLICK TO ROLL", cream, 1, plum);
            api.textCentered(H - 14, "STEER WITH THE POINTER - FLATTEN SNOWMEN", peach, 1, plum);
        }
        if (this.mode == OVER) {
            api.rect(0, 34, W, 44, plum);
            api.textCentered(38, "WIPEOUT!", cream, 2, plum);
            api.textCentered(52, "SCORE " + this.score.toString() + "   SNOWMEN " + this.men.toString(), peach, 1, plum);
            if (!api.demo && this.t > 0.7) {
                api.textCentered(64, "CLICK TO ROLL AGAIN", coral, 1, plum);
            }
        }
    }
}
