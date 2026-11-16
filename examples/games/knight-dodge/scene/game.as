// Knight Dodge: the knight runs to wherever the pointer is on the arena floor. Boulders rumble in
// through four gates (each gate shakes and puffs dust for a moment first), roll across and smash on
// the far wall. Survive: a point a second, gold coins +5. Three hearts; a hit knocks the knight
// back and blinks. Pointer only; a run starts on the first click; demo mode plays itself.
import { GameApi, POINTER_DOWN, POINTER_MOVE } from "./game_api";

const ST_IDLE: i32 = 0;
const ST_PLAY: i32 = 1;
const ST_OVER: i32 = 2;

const NB: i32 = 6;          // boulders
const NC: i32 = 2;          // coins
const ND: i32 = 12;         // dust puffs
const NF: i32 = 8;          // brazier flames
const B_IDLE: i32 = 0;
const B_WARN: i32 = 1;      // sitting in its gate, shaking: the telegraph
const B_ROLL: i32 = 2;

const ARENA_R: f64 = 4.25;  // where the knight may run
const GATE_R: f64 = 5.15;   // where a boulder waits in its gate
const WALL_R: f64 = 4.2;    // a boulder's centre reaches the wall here and smashes
const BR: f64 = 0.5;        // boulder radius
const HIT_R: f64 = 0.8;     // boulder centre to knight centre for a hit
const COIN_R: f64 = 0.65;
const WARN_T: f64 = 0.85;

// the camera: orthographic, yaw 0; its target sits a third of a texel off the art grid on both
// axes (the first renderer needed it to put the scene on the HUD's pixel grid; see the README),
// and the shake moves it by whole texels
const PITCH: f64 = 52;
const TEXEL: f64 = 10.0 / 136.0;       // orthoHeight / art rows (136 = ceil(400 / 3) + 2)

// palette indices (art/palette.json "colors")
const C_GOLD: i32 = 0;
const C_RUST: i32 = 1;
const C_DARK: i32 = 3;
const C_TAN: i32 = 4;
const C_GREY: i32 = 6;
const C_BLACK: i32 = 7;

export class Game {
    state: i32 = ST_IDLE;
    stateT: f64 = 0;
    runT: f64 = 0;
    tickT: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    lives: i32 = 3;
    wasDemo: bool = false;

    knight: i32 = -1;
    bBone: StaticArray<i32> = new StaticArray<i32>(NB);
    cBone: StaticArray<i32> = new StaticArray<i32>(NC);
    dBone: StaticArray<i32> = new StaticArray<i32>(ND);
    fBone: StaticArray<i32> = new StaticArray<i32>(NF);
    fX: StaticArray<f64> = new StaticArray<f64>(NF);
    fZ: StaticArray<f64> = new StaticArray<f64>(NF);
    gateA: StaticArray<f64> = [45.0, 135.0, 225.0, 315.0];

    // boulders
    bState: StaticArray<i32> = new StaticArray<i32>(NB);
    bT: StaticArray<f64> = new StaticArray<f64>(NB);
    bX: StaticArray<f64> = new StaticArray<f64>(NB);
    bZ: StaticArray<f64> = new StaticArray<f64>(NB);
    bDX: StaticArray<f64> = new StaticArray<f64>(NB);
    bDZ: StaticArray<f64> = new StaticArray<f64>(NB);
    bSp: StaticArray<f64> = new StaticArray<f64>(NB);
    bRoll: StaticArray<f64> = new StaticArray<f64>(NB);
    bGate: StaticArray<i32> = new StaticArray<i32>(NB);
    bHit: StaticArray<bool> = new StaticArray<bool>(NB);
    spawnT: f64 = 0;

    // coins
    cOn: StaticArray<bool> = new StaticArray<bool>(NC);
    cT: StaticArray<f64> = new StaticArray<f64>(NC);
    cX: StaticArray<f64> = new StaticArray<f64>(NC);
    cZ: StaticArray<f64> = new StaticArray<f64>(NC);
    cGot: StaticArray<f64> = new StaticArray<f64>(NC);   // >= 0: just picked up (the pop)
    coinT: f64 = 0;

    // dust
    dT: StaticArray<f64> = new StaticArray<f64>(ND);
    dX: StaticArray<f64> = new StaticArray<f64>(ND);
    dY: StaticArray<f64> = new StaticArray<f64>(ND);
    dZ: StaticArray<f64> = new StaticArray<f64>(ND);
    dVX: StaticArray<f64> = new StaticArray<f64>(ND);
    dVY: StaticArray<f64> = new StaticArray<f64>(ND);
    dVZ: StaticArray<f64> = new StaticArray<f64>(ND);
    dS: StaticArray<f64> = new StaticArray<f64>(ND);
    dNext: i32 = 0;

    // the knight
    kx: f64 = 0;
    kz: f64 = 0.4;
    kvx: f64 = 0;
    kvz: f64 = 0;
    kyaw: f64 = 0;
    kstep: f64 = 0;
    tx: f64 = 0;
    tz: f64 = 0.4;
    hurtT: f64 = 0;
    squashT: f64 = 0;

    // juice
    shakeT: f64 = 0;
    flashT: f64 = 0;
    camTX: f64 = 0;
    camTY: f64 = 0;
    popT: f64 = -1;
    popX: f32 = 0;
    popY: f32 = 0;
    popText: string = "";

    // the demo player
    dThink: f64 = 0;
    dGoX: f64 = 0;
    dGoZ: f64 = 0;
    dDodge: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        this.knight = api.bone("knight");
        for (let i = 0; i < NB; i++) { this.bBone[i] = api.bone("boulder" + i.toString()); }
        for (let i = 0; i < NC; i++) { this.cBone[i] = api.bone("coin" + i.toString()); }
        for (let i = 0; i < ND; i++) { this.dBone[i] = api.bone("dust" + i.toString()); this.dT[i] = -1; }
        for (let i = 0; i < NF; i++) {
            this.fBone[i] = api.bone("flame" + i.toString());
            let g = this.gateA[i / 2] + (i % 2 == 0 ? -12.5 : 12.5);
            this.fX[i] = 4.85 * Math.cos(g * Math.PI / 180);
            this.fZ[i] = 4.85 * Math.sin(g * Math.PI / 180);
        }
        this.camTX = api.targetX;
        this.camTY = api.targetY;
        this.wasDemo = api.demo;
        this.resetWorld(api);
        if (api.demo) {
            this.beginRun(api);
        }
    }

    // ------------------------------------------------------------------ run control

    resetWorld(api: GameApi): void {
        for (let i = 0; i < NB; i++) { this.bState[i] = B_IDLE; }
        for (let i = 0; i < NC; i++) { this.cOn[i] = false; this.cGot[i] = -1; }
        this.kx = 0; this.kz = 0.4; this.kvx = 0; this.kvz = 0; this.kyaw = 0;
        this.tx = 0; this.tz = 0.4;
        this.hurtT = 0; this.squashT = 0;
        this.score = 0; this.lives = 3; this.runT = 0; this.tickT = 0;
        // a coin glints on the sand from the first frame
        this.placeCoin(api, 0, 1.6, -1.2);
        this.coinT = 3.0;
    }

    beginRun(api: GameApi): void {
        if (this.state == ST_OVER) {
            this.resetWorld(api);
        }
        this.state = ST_PLAY;
        this.stateT = 0;
        this.runT = 0;
        // the first boulder is already rumbling in its gate
        this.spawnT = 0;
        this.launch(api, 0.35);
        this.spawnT = 1.6;
    }

    endRun(): void {
        this.state = ST_OVER;
        this.stateT = 0;
        if (this.score > this.best) {
            this.best = this.score;
        }
    }

    difficulty(): f64 {
        return Math.min(1.0, this.runT / 55.0);
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            // the host switched demo off (a visitor took over) or on: a fresh run either way
            this.wasDemo = api.demo;
            this.state = ST_OVER;
            this.beginRun(api);
        }
        this.stateT += dt;
        if (this.state == ST_PLAY) {
            this.runT += dt;
            this.tickT += dt;
            while (this.tickT >= 1.0) {
                this.tickT -= 1.0;
                this.score += 1;
            }
        }
        if (api.demo) {
            this.demoThink(api, dt);
            if (this.state == ST_OVER && this.stateT > 2.0) {
                this.beginRun(api);
            }
        }
        this.updateBoulders(api, dt);
        this.updateCoins(api, dt);
        this.updateKnight(api, dt);
        this.updateDust(api, dt);
        this.updateFlames(api);
        // camera shake: whole texels only, so the scene stays on the HUD's pixel grid
        if (this.shakeT > 0) {
            this.shakeT -= dt;
            let k = <i32>Math.floor(api.time * 24) % 4;
            let ox = k == 0 ? 1.0 : (k == 2 ? -1.0 : 0.0);
            let oy = k == 1 ? 1.0 : (k == 3 ? -1.0 : 0.0);
            api.targetX = this.camTX + ox * TEXEL;
            api.targetY = this.camTY + oy * TEXEL / Math.cos(PITCH * Math.PI / 180);
        } else {
            api.targetX = this.camTX;
            api.targetY = this.camTY;
        }
        if (this.popT >= 0) {
            this.popT += dt;
            if (this.popT > 0.8) { this.popT = -1; }
        }
        if (this.flashT > 0) { this.flashT -= dt; }
    }

    // ------------------------------------------------------------------ boulders

    launch(api: GameApi, warn: f64): void {
        for (let i = 0; i < NB; i++) {
            if (this.bState[i] != B_IDLE) {
                continue;
            }
            // a gate not already in use
            let g = <i32>Math.floor(api.rand() * 4.0) % 4;
            for (let tries = 0; tries < 4; tries++) {
                let used = false;
                for (let j = 0; j < NB; j++) {
                    if (this.bState[j] == B_WARN && this.bGate[j] == g) { used = true; }
                }
                if (!used) { break; }
                g = (g + 1) % 4;
            }
            let a = this.gateA[g] * Math.PI / 180;
            this.bState[i] = B_WARN;
            this.bT[i] = WARN_T - warn;
            this.bGate[i] = g;
            this.bX[i] = GATE_R * Math.cos(a);
            this.bZ[i] = GATE_R * Math.sin(a);
            this.bRoll[i] = api.range(0, 360);
            this.bHit[i] = false;
            return;
        }
    }

    updateBoulders(api: GameApi, dt: f64): void {
        let playing = this.state == ST_PLAY;
        let d = this.difficulty();
        if (playing) {
            this.spawnT -= dt;
            if (this.spawnT <= 0) {
                this.launch(api, WARN_T);
                if (api.rand() < 0.3 * d) {
                    this.launch(api, WARN_T);
                }
                this.spawnT = 2.3 - 1.5 * d + api.range(-0.25, 0.25);
            }
        }
        for (let i = 0; i < NB; i++) {
            let b = this.bBone[i];
            let st = this.bState[i];
            if (st == B_IDLE) {
                api.hide(b);
                continue;
            }
            this.bT[i] += dt;
            if (st == B_WARN) {
                // the telegraph: it rocks back and forth in its gate, kicking up dust
                let a = this.gateA[this.bGate[i]] * Math.PI / 180;
                let ix = -Math.cos(a), iz = -Math.sin(a);
                let k = Math.floor(this.bT[i] * 12);
                let rock = (k % 2 == 0 ? 1.0 : -1.0) * 0.06;
                api.place(b, this.bX[i] + ix * rock, BR, this.bZ[i] + iz * rock,
                          Math.atan2(ix, iz) * 180 / Math.PI, this.bRoll[i] + rock * 120, 0, 1.0);
                if (Math.floor((this.bT[i] - dt) * 6) != Math.floor(this.bT[i] * 6)) {
                    this.puff(api, this.bX[i] + ix * 0.4 + api.range(-0.4, 0.4), 0.15, this.bZ[i] + iz * 0.4 + api.range(-0.4, 0.4), 0.6, 0.8);
                }
                if (this.bT[i] >= WARN_T) {
                    // roll at the knight, a little off; faster as the run goes on
                    let spread = 1.5 - 0.8 * d;
                    let ax = this.kx + api.range(-spread, spread), az = this.kz + api.range(-spread, spread);
                    let dx = ax - this.bX[i], dz = az - this.bZ[i];
                    let n = Math.max(0.01, Math.sqrt(dx * dx + dz * dz));
                    this.bDX[i] = dx / n;
                    this.bDZ[i] = dz / n;
                    this.bSp[i] = 3.0 + 3.0 * d + api.range(-0.3, 0.3);
                    this.bState[i] = B_ROLL;
                    this.bT[i] = 0;
                    this.shakeT = Math.max(this.shakeT, 0.08);
                }
                continue;
            }
            // rolling: it turns about the axis across its heading, one radian per radius travelled
            let sp = this.bSp[i] * Math.min(1.0, 0.4 + this.bT[i] * 3.0);
            this.bX[i] += this.bDX[i] * sp * dt;
            this.bZ[i] += this.bDZ[i] * sp * dt;
            this.bRoll[i] += sp * dt / BR * 180 / Math.PI;
            let heading = Math.atan2(this.bDX[i], this.bDZ[i]) * 180 / Math.PI;
            let hop = Math.floor(this.bRoll[i] / 60) % 2 == 0 ? 0.0 : 0.04;
            api.place(b, this.bX[i], BR + hop, this.bZ[i], heading, this.bRoll[i], 0, 1.0);
            // the knight
            if (playing && this.hurtT <= 0 && !this.bHit[i]) {
                let dx = this.kx - this.bX[i], dz = this.kz - this.bZ[i];
                if (dx * dx + dz * dz < HIT_R * HIT_R) {
                    this.bHit[i] = true;
                    this.hit(api, i);
                }
            }
            // smash on the far wall (or out through a gate)
            let r = Math.sqrt(this.bX[i] * this.bX[i] + this.bZ[i] * this.bZ[i]);
            let outward = this.bX[i] * this.bDX[i] + this.bZ[i] * this.bDZ[i] > 0;
            if (r > WALL_R && outward && this.bT[i] > 0.3) {
                for (let p = 0; p < 4; p++) {
                    this.puff(api, this.bX[i] + api.range(-0.3, 0.3), api.range(0.2, 0.8), this.bZ[i] + api.range(-0.3, 0.3), 1.0, 1.4);
                }
                this.shakeT = Math.max(this.shakeT, 0.12);
                this.bState[i] = B_IDLE;
                api.hide(b);
            }
        }
    }

    hit(api: GameApi, i: i32): void {
        let dx = this.kx - this.bX[i], dz = this.kz - this.bZ[i];
        let n = Math.max(0.01, Math.sqrt(dx * dx + dz * dz));
        // knocked sideways off the boulder's line and along it
        this.kvx = dx / n * 5.0 + this.bDX[i] * 4.0;
        this.kvz = dz / n * 5.0 + this.bDZ[i] * 4.0;
        this.hurtT = 1.6;
        this.squashT = 0.3;
        this.shakeT = 0.35;
        this.flashT = 0.6;
        for (let p = 0; p < 4; p++) {
            this.puff(api, this.kx + api.range(-0.3, 0.3), api.range(0.4, 1.2), this.kz + api.range(-0.3, 0.3), 1.2, 1.8);
        }
        this.lives -= 1;
        if (this.lives <= 0) {
            this.lives = 0;
            this.endRun();
        }
    }

    // ------------------------------------------------------------------ coins

    placeCoin(api: GameApi, c: i32, x: f64, z: f64): void {
        this.cOn[c] = true;
        this.cT[c] = 0;
        this.cX[c] = x;
        this.cZ[c] = z;
        this.cGot[c] = -1;
    }

    updateCoins(api: GameApi, dt: f64): void {
        if (this.state == ST_PLAY) {
            this.coinT -= dt;
            if (this.coinT <= 0) {
                for (let c = 0; c < NC; c++) {
                    if (this.cOn[c] || this.cGot[c] >= 0) { continue; }
                    // somewhere on the sand, not under the knight
                    for (let tries = 0; tries < 8; tries++) {
                        let a = api.range(0, Math.PI * 2), r = api.range(0.6, 3.4);
                        let x = r * Math.cos(a), z = r * Math.sin(a);
                        if ((x - this.kx) * (x - this.kx) + (z - this.kz) * (z - this.kz) > 2.0 * 2.0) {
                            this.placeCoin(api, c, x, z);
                            break;
                        }
                    }
                    break;
                }
                this.coinT = api.range(2.0, 3.5);
            }
        }
        for (let c = 0; c < NC; c++) {
            let b = this.cBone[c];
            if (this.cGot[c] >= 0) {
                // the pop: up, spinning fast, stretched, then gone
                this.cGot[c] += dt;
                let t = this.cGot[c];
                if (t > 0.45) {
                    this.cGot[c] = -1;
                    api.hide(b);
                    continue;
                }
                let k = Math.floor(t * 15) / 15;
                api.placeScaled(b, this.cX[c], 0.45 + k * 2.2, this.cZ[c], k * 1400, 1.0 - k, 1.0 + k * 1.2, 1.0 - k);
                continue;
            }
            if (!this.cOn[c]) {
                api.hide(b);
                continue;
            }
            this.cT[c] += dt;
            let t = this.cT[c];
            // never scale 0: a degenerate bone turns every splat into a huge square
            let grow = Math.max(0.2, Math.min(1.0, Math.floor(t * 15) / 15 / 0.3));
            let bob = Math.floor(Math.sin(t * 4.0) * 2.0) * 0.04;
            api.place(b, this.cX[c], 0.45 + bob, this.cZ[c], Math.floor(t * 8) * 30, 0, 0, grow);
            if (this.state == ST_PLAY) {
                let dx = this.kx - this.cX[c], dz = this.kz - this.cZ[c];
                if (dx * dx + dz * dz < COIN_R * COIN_R) {
                    this.cOn[c] = false;
                    this.cGot[c] = 0;
                    this.score += 5;
                    if (api.project(<f32>this.cX[c], 1.4, <f32>this.cZ[c])) {
                        this.popX = api.screenX;
                        this.popY = api.screenY;
                        this.popT = 0;
                        this.popText = "+5";
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------ the knight

    updateKnight(api: GameApi, dt: f64): void {
        let b = this.knight;
        if (this.state == ST_OVER) {
            // flattened: topples onto its back and lies there
            let k = Math.min(1.0, this.stateT / 0.5);
            this.kx += this.kvx * dt * (1 - k);
            this.kz += this.kvz * dt * (1 - k);
            api.place(b, this.kx, 0.15 * Math.sin(k * Math.PI), this.kz, this.kyaw, -80 * k * k, 0, 1.0);
            return;
        }
        if (this.state == ST_IDLE) {
            // waits in the middle, shifting its weight
            let k = Math.floor(api.time * 3) % 2;
            api.placeScaled(b, this.kx, 0, this.kz, this.kyaw, 1.0 + 0.03 * <f64>k, 1.0 - 0.03 * <f64>k, 1.0 + 0.03 * <f64>k);
            return;
        }
        // run to the target: a damped spring with a capped speed (knockback overrides for a moment)
        let kk = 28.0, c = 10.0;
        let stunned = this.hurtT > 1.2;
        if (!stunned) {
            this.kvx += (kk * (this.tx - this.kx) - c * this.kvx) * dt;
            this.kvz += (kk * (this.tz - this.kz) - c * this.kvz) * dt;
            let sp = Math.sqrt(this.kvx * this.kvx + this.kvz * this.kvz);
            let maxSp = 4.4;
            if (sp > maxSp) {
                this.kvx *= maxSp / sp;
                this.kvz *= maxSp / sp;
            }
        } else {
            this.kvx *= Math.exp(-dt * 3);
            this.kvz *= Math.exp(-dt * 3);
        }
        this.kx += this.kvx * dt;
        this.kz += this.kvz * dt;
        let r = Math.sqrt(this.kx * this.kx + this.kz * this.kz);
        if (r > ARENA_R) {
            this.kx *= ARENA_R / r;
            this.kz *= ARENA_R / r;
        }
        let sp = Math.sqrt(this.kvx * this.kvx + this.kvz * this.kvz);
        if (sp > 0.5 && !stunned) {
            let want = Math.atan2(this.kvx, this.kvz) * 180 / Math.PI;
            let d = want - this.kyaw;
            while (d > 180) { d -= 360; }
            while (d < -180) { d += 360; }
            this.kyaw += d * Math.min(1.0, dt * 12);
        }
        this.kstep += sp * dt;
        if (this.hurtT > 0) {
            this.hurtT -= dt;
            if (this.hurtT < 1.2 && Math.floor(this.hurtT * 12) % 2 == 0) {
                api.hide(b);
                return;
            }
        }
        if (this.squashT > 0) {
            // flattened by the hit, springing back
            this.squashT -= dt;
            let k = Math.floor((0.3 - this.squashT) * 15) / 15 / 0.3;
            let s = 0.6 + 0.4 * k;
            api.placeScaled(b, this.kx, 0, this.kz, this.kyaw + 25, 1.0 + (1 - s) * 0.8, s, 1.0 + (1 - s) * 0.8);
            return;
        }
        // running: a stepped bob, a waddle from foot to foot, a lean into the run
        let running = sp > 0.6;
        let phase = Math.floor(this.kstep * 3.2);
        let bob = running && phase % 2 == 1 ? 0.07 : 0.0;
        let waddle = running ? (phase % 2 == 0 ? 7.0 : -7.0) : 0.0;
        let lean = Math.min(14.0, sp * 3.2);
        api.place(b, this.kx, bob, this.kz, this.kyaw, lean, waddle, 1.0);
    }

    // ------------------------------------------------------------------ dust

    puff(api: GameApi, x: f64, y: f64, z: f64, spd: f64, up: f64): void {
        let i = this.dNext;
        this.dNext = (this.dNext + 1) % ND;
        this.dT[i] = 0;
        this.dX[i] = x; this.dY[i] = y; this.dZ[i] = z;
        let a = api.range(0, Math.PI * 2);
        this.dVX[i] = Math.cos(a) * spd * api.range(0.4, 1.0);
        this.dVZ[i] = Math.sin(a) * spd * api.range(0.4, 1.0);
        this.dVY[i] = up * api.range(0.5, 1.0);
        this.dS[i] = api.range(0.9, 1.5);
    }

    updateDust(api: GameApi, dt: f64): void {
        for (let i = 0; i < ND; i++) {
            let b = this.dBone[i];
            if (this.dT[i] < 0) {
                api.hide(b);
                continue;
            }
            this.dT[i] += dt;
            let t = this.dT[i];
            if (t > 0.6) {
                this.dT[i] = -1;
                api.hide(b);
                continue;
            }
            this.dVY[i] -= 2.5 * dt;
            this.dX[i] += this.dVX[i] * dt;
            this.dY[i] = Math.max(0.1, this.dY[i] + this.dVY[i] * dt);
            this.dZ[i] += this.dVZ[i] * dt;
            let s = this.dS[i] * (1.0 - Math.floor(t * 12) / 12 / 0.6 * 0.8);
            api.place(b, this.dX[i], this.dY[i], this.dZ[i], 0, 0, 0, s);
        }
    }

    updateFlames(api: GameApi): void {
        for (let i = 0; i < NF; i++) {
            // a stepped flicker, out of step from brazier to brazier
            let k = <f64>(<i32>Math.floor(api.time * 10 + <f64>i * 3.7) % 5);
            let sy = (0.85 + k * 0.08) * 1.35;
            let sx = (1.1 - k * 0.04) * 1.35;
            api.placeScaled(this.fBone[i], this.fX[i], 1.78, this.fZ[i], <f64>i * 47 + k * 20, sx, sy, sx);
        }
    }

    // ------------------------------------------------------------------ the demo player

    demoThink(api: GameApi, dt: f64): void {
        if (this.state != ST_PLAY) {
            this.tx = this.kx;
            this.tz = this.kz;
            return;
        }
        this.dThink -= dt;
        if (this.dDodge > 0) {
            this.dDodge -= dt;
        }
        if (this.dThink <= 0) {
            this.dThink = api.range(0.15, 0.3);
            // the most urgent boulder on a course to pass close by
            let worst = -1;
            let worstT = 1e9;
            let side = 0.0;
            for (let i = 0; i < NB; i++) {
                if (this.bState[i] != B_ROLL) { continue; }
                let rx = this.kx - this.bX[i], rz = this.kz - this.bZ[i];
                let along = rx * this.bDX[i] + rz * this.bDZ[i];
                if (along < -0.5) { continue; }
                let across = rx * this.bDZ[i] - rz * this.bDX[i];
                let tHit = along / Math.max(0.5, this.bSp[i]);
                if (Math.abs(across) < 1.3 && tHit < 1.3 && tHit < worstT) {
                    worst = i;
                    worstT = tHit;
                    side = across >= 0 ? 1.0 : -1.0;
                }
            }
            // now and then a human misses one
            if (worst >= 0 && api.rand() < 0.06) {
                worst = -1;
                this.dThink = 0.45;
            }
            if (worst >= 0) {
                // step off its line, on the side already taken (the other if the wall is there)
                let px = this.bDZ[worst] * side, pz = -this.bDX[worst] * side;
                let gx = this.kx + px * 1.9, gz = this.kz + pz * 1.9;
                if (gx * gx + gz * gz > (ARENA_R - 0.4) * (ARENA_R - 0.4)) {
                    gx = this.kx - px * 1.9;
                    gz = this.kz - pz * 1.9;
                }
                this.dGoX = gx;
                this.dGoZ = gz;
                this.dDodge = 0.5;
            } else if (this.dDodge <= 0) {
                // otherwise go for the nearest coin, or loiter near the middle
                let best = -1;
                let bestD = 1e9;
                for (let c = 0; c < NC; c++) {
                    if (!this.cOn[c]) { continue; }
                    let dx = this.cX[c] - this.kx, dz = this.cZ[c] - this.kz;
                    let d = dx * dx + dz * dz;
                    if (d < bestD) { bestD = d; best = c; }
                }
                if (best >= 0) {
                    this.dGoX = this.cX[best] + api.range(-0.25, 0.25);
                    this.dGoZ = this.cZ[best] + api.range(-0.25, 0.25);
                } else {
                    this.dGoX = 0.8 * Math.sin(api.time * 0.6);
                    this.dGoZ = 0.6 * Math.cos(api.time * 0.45);
                }
            }
        }
        this.tx = this.dGoX;
        this.tz = this.dGoZ;
    }

    // ------------------------------------------------------------------ input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        let hit = api.pick(x, y, 0);
        if (kind == POINTER_DOWN) {
            if (this.state == ST_IDLE) {
                this.beginRun(api);
            } else if (this.state == ST_OVER && this.stateT > 0.8) {
                this.beginRun(api);
            }
        }
        if ((kind == POINTER_DOWN || kind == POINTER_MOVE) && hit && this.state == ST_PLAY) {
            this.tx = <f64>api.hitX;
            this.tz = <f64>api.hitZ;
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let black = api.paletteColor(C_BLACK);
        let dark = api.paletteColor(C_DARK);
        let gold = api.paletteColor(C_GOLD);
        let rust = api.paletteColor(C_RUST);
        let tan = api.paletteColor(C_TAN);
        let grey = api.paletteColor(C_GREY);
        // the telegraph: a blinking "!" over each rumbling gate
        for (let i = 0; i < NB; i++) {
            if (this.bState[i] != B_WARN || Math.floor(this.bT[i] * 8) % 2 == 1) { continue; }
            if (api.project(<f32>this.bX[i], 1.5, <f32>this.bZ[i])) {
                api.text(api.screenX - 2, api.screenY - 6, "!", gold, 2, black);
            }
        }
        if (this.popT >= 0) {
            let rise = <f32>(this.popT * 14.0);
            api.text(this.popX - 3, this.popY - 4 - rise, this.popText, gold, 1, black);
        }
        api.text(4, 4, this.score.toString(), gold, 2, black);
        api.text(4, 16, "BEST " + this.best.toString(), tan, 1, black);
        for (let l = 0; l < 3; l++) {
            let x: f32 = <f32>(api.hudW - 11 - l * 10);
            let c = l < this.lives ? rust : grey;
            if (l == this.lives && this.flashT > 0 && Math.floor(this.flashT * 10) % 2 == 0) {
                c = gold;
            }
            // a heart
            api.rect(x, 5, 3, 3, c);
            api.rect(x + 4, 5, 3, 3, c);
            api.rect(x, 7, 7, 2, c);
            api.rect(x + 1, 9, 5, 1, c);
            api.rect(x + 2, 10, 3, 1, c);
            api.rect(x + 3, 11, 1, 1, c);
        }
        let h = <f32>api.hudH;
        if (this.state == ST_IDLE) {
            let blink = Math.floor(api.time * 2) % 2 == 0;
            api.textCentered(h - 20, "CLICK TO START", blink ? gold : tan, 2, black);
            api.textCentered(h - 8, "THE KNIGHT RUNS TO THE POINTER: DODGE THE BOULDERS", tan, 1, black);
        } else if (this.state == ST_OVER) {
            let pw: f32 = 112, ph: f32 = 40;
            let px = Mathf.floor((<f32>api.hudW - pw) * 0.5), py = Mathf.floor(h * 0.5 - 27);
            api.rect(px, py, pw, ph, black);
            api.rect(px - 1, py - 1, pw + 2, 1, dark);
            api.rect(px - 1, py + ph, pw + 2, 1, dark);
            api.rect(px - 1, py, 1, ph, dark);
            api.rect(px + pw, py, 1, ph, dark);
            api.textCentered(h * 0.5 - 22, "GAME OVER", gold, 2, dark);
            api.textCentered(h * 0.5 - 6, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), tan, 1, black);
            if (this.stateT > 0.8 && !api.demo) {
                api.textCentered(h * 0.5 + 4, "CLICK TO PLAY AGAIN", rust, 1, black);
            }
        } else if (this.runT < 4.0 && !api.demo) {
            api.textCentered(h - 8, "COINS +5, A POINT FOR EVERY SECOND ALIVE", tan, 1, black);
        }
    }
}
