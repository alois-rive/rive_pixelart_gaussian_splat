// Night Heist: a cat follows the pointer across two moonlit rooftops. Grab the fish; stay out of the
// searchlights' pools. Standing in a pool fills the alarm; out of the light it drains. A full alarm is
// game over (CAUGHT!). A light that has seen the cat follows it for a moment. More lamps wake up as
// the run goes on and they sweep faster. One verb: move the pointer (the first click starts a run).
// Demo mode (api.demo) plays like a decent sneak: it goes for the fish, waits out the light, sometimes
// gets greedy and gets caught.
import { GameApi, POINTER_DOWN, POINTER_MOVE, SFX_BLIP, SFX_CLICK, SFX_COIN, SFX_HIT, SFX_JUMP, SFX_LOSE, SFX_NOTE,
    SFX_POP, SFX_THUD, SFX_WIN, SFX_ZAP } from "./game_api";

const NL: i32 = 3;              // searchlights
const NS: i32 = 8;              // sparkles
const POOL_R: f64 = 1.0;        // a pool's radius (the bake's)
const CAT_R: f64 = 0.3;        // the cat's footprint radius (for obstacles)
const SPEED: f64 = 3.7;         // the cat's top speed, m/s
const X_MAX: f64 = 6.25;        // the walkable roofs: |x| <= X_MAX, z in [Z_MIN, Z_MAX], the alley |x| < GAP
const Z_MIN: f64 = -1.95;
const Z_MAX: f64 = 2.72;
const GAP: f64 = 0.5;
const FILL: f64 = 1.45;         // alarm per second in the light (full in 0.7 s)
const DRAIN: f64 = 0.4;         // alarm per second out of it
const SCALE: f64 = 1.35;        // the cat's bake scale (the model's hip at 0.34 m, the tail's root at 0.55 m up)

const MODE_READY: i32 = 0;
const MODE_RUN: i32 = 1;
const MODE_CAUGHT: i32 = 2;

// the obstacles' footprints (x0, x1, z0, z1): printed by models/env/make_env.py
const OBST: StaticArray<f64> = [
    -5.10, -4.30, -1.62, -1.08,
     1.55,  2.25, -1.80, -1.30,
    -3.20, -1.80,  0.35,  1.45,
    -5.85, -4.95,  1.50,  2.20,
     1.95,  2.85,  1.35,  2.05,
     5.15,  5.85,  1.75,  2.25,
     4.00,  5.50, -2.00, -0.50];
// the lamps' pivots (the posts on the back row: make_env.py LAMPS + LAMP_H)
const LX: StaticArray<f64> = [-2.8, 2.4, 5.4];
const LY: StaticArray<f64> = [2.2, 2.0, 1.55];
const LZ: StaticArray<f64> = [-2.75, -2.75, -2.75];
// each pool's sweep: a Lissajous figure x = cx + ax sin(w t + p), z = cz + az sin(k w t + q)
const PCX: StaticArray<f64> = [-3.4, 0.6, 3.6];
const PAX: StaticArray<f64> = [2.6, 3.4, 2.3];
const PCZ: StaticArray<f64> = [0.4, 0.45, 0.35];
const PAZ: StaticArray<f64> = [1.95, 1.9, 1.9];
const PK: StaticArray<f64> = [1.63, 1.37, 2.21];
const PQ: StaticArray<f64> = [0.9, 2.3, 4.1];
const WAKE: StaticArray<f64> = [0.0, 7.0, 19.0];   // seconds into a run when each lamp switches on

function clamp(v: f64, a: f64, b: f64): f64 {
    return v < a ? a : (v > b ? b : v);
}
function wrap180(a: f64): f64 {
    let r = a % 360;
    if (r > 180) r -= 360;
    if (r < -180) r += 360;
    return r;
}
function stepped(t: f64, fps: f64): f64 {
    return Math.floor(t * fps) / fps;
}

export class Game {
    cat: i32 = -1;
    tail: i32 = -1;
    leg: StaticArray<i32> = new StaticArray<i32>(4);
    lamp: StaticArray<i32> = new StaticArray<i32>(NL);
    pool: StaticArray<i32> = new StaticArray<i32>(NL);
    fish: i32 = -1;
    spark: StaticArray<i32> = new StaticArray<i32>(NS);
    cloud: StaticArray<i32> = new StaticArray<i32>(2);

    mode: i32 = MODE_READY;
    t: f64 = 0;               // seconds in this mode
    runT: f64 = 0;            // seconds into the run (drives the lamps' waking and speed)
    cx: f64 = -1.6;           // the cat
    cz: f64 = 2.2;
    vx: f64 = 0;
    vz: f64 = 0;
    yaw: f64 = 0;
    walk: f64 = 0;            // walk cycle phase
    hop: f64 = 0;             // height of the alley hop
    tx: f64 = -1.6;           // where the cat is going
    tz: f64 = 2.2;
    alarm: f64 = 0;
    seen: bool = false;       // in a light this frame
    flinch: f64 = 0;          // a squash when it is first seen

    // the lights
    on: StaticArray<bool> = new StaticArray<bool>(NL);
    wake: StaticArray<f64> = new StaticArray<f64>(NL);   // seconds since switched on (the pop)
    clock: StaticArray<f64> = new StaticArray<f64>(NL);  // each pool's own sweep clock
    px: StaticArray<f64> = new StaticArray<f64>(NL);     // each pool's place
    pz: StaticArray<f64> = new StaticArray<f64>(NL);
    chase: StaticArray<f64> = new StaticArray<f64>(NL);  // 0..1: how much the pool follows the cat
    chX: StaticArray<f64> = new StaticArray<f64>(NL);    // the chasing point
    chZ: StaticArray<f64> = new StaticArray<f64>(NL);

    // the fish
    fx: f64 = -4.2;
    fz: f64 = 0.0;
    fishT: f64 = 0;           // seconds since it appeared
    fishOn: bool = true;
    fishGone: f64 = 0;        // seconds until the next one appears

    sX: StaticArray<f64> = new StaticArray<f64>(NS);
    sY: StaticArray<f64> = new StaticArray<f64>(NS);
    sZ: StaticArray<f64> = new StaticArray<f64>(NS);
    sVX: StaticArray<f64> = new StaticArray<f64>(NS);
    sVY: StaticArray<f64> = new StaticArray<f64>(NS);
    sVZ: StaticArray<f64> = new StaticArray<f64>(NS);
    sT: StaticArray<f64> = new StaticArray<f64>(NS);

    score: i32 = 0;
    best: i32 = 0;
    popT: f64 = 9;
    popX: f64 = 0;
    popZ: f64 = 0;
    popText: string = "";
    shakeT: f64 = 0;

    // the demo's plan
    dPlan: f64 = 0;           // seconds until it re-plans
    dGreedy: bool = false;    // this fish it ignores the light
    dErrX: f64 = 0;
    dErrZ: f64 = 0;

    // sound (decided from the game's state only, never from api.rand)
    seenN: i32 = 0;           // frames in the light this time (the alarm's beeps every 8)
    wasHop: bool = false;     // over the alley last frame
    hopFrame: i32 = -99;      // the frame of the last leap's sound

    start(api: GameApi): void {
        api.playable = true;
        this.cat = api.bone("cat");
        this.tail = api.bone("tail");
        this.fish = api.bone("fish");
        for (let i = 0; i < 4; i++) {
            this.leg[i] = api.bone("leg" + i.toString());
        }
        for (let i = 0; i < NL; i++) {
            this.lamp[i] = api.bone("lamp" + i.toString());
            this.pool[i] = api.bone("pool" + i.toString());
        }
        for (let i = 0; i < NS; i++) {
            this.spark[i] = api.bone("spark" + i.toString());
            this.sT[i] = 99;
            api.hide(this.spark[i]);
        }
        for (let i = 0; i < 2; i++) {
            this.cloud[i] = api.bone("cloud" + i.toString());
        }
        this.newRun(api, api.demo ? MODE_RUN : MODE_READY);
    }

    newRun(api: GameApi, mode: i32): void {
        this.mode = mode;
        this.t = 0;
        this.runT = 0;
        this.cx = -1.7;
        this.cz = 2.25;
        this.tx = this.cx;
        this.tz = this.cz;
        this.vx = 0;
        this.vz = 0;
        this.yaw = mode == MODE_RUN ? -60 : 15;
        this.alarm = 0;
        this.score = 0;
        this.popT = 9;
        this.flinch = 0;
        for (let i = 0; i < NL; i++) {
            this.on[i] = i == 0;
            this.wake[i] = 9;
            this.chase[i] = 0;
            this.farFromCat(i);
        }
        // the first fish: in reach, to the left
        this.fishOn = true;
        this.fishT = 0;
        this.fx = -4.1;
        this.fz = 0.3;
        this.dPlan = 0;
        this.dGreedy = false;
    }

    // starts a pool's sweep where it is far from the cat (a run's start, a lamp waking up)
    farFromCat(i: i32): void {
        let bestC = 0.0, bestD = -1.0;
        for (let k = 0; k < 24; k++) {
            let c = <f64>k * 0.55;
            this.sweep(i, c);
            let d = Math.hypot(this.px[i] - this.cx, this.pz[i] - this.cz);
            if (d > bestD) {
                bestD = d;
                bestC = c;
            }
        }
        this.clock[i] = bestC;
        this.sweep(i, bestC);
    }

    sweep(i: i32, c: f64): void {
        this.px[i] = PCX[i] + PAX[i] * Math.sin(c);
        this.pz[i] = PCZ[i] + PAZ[i] * Math.sin(PK[i] * c + PQ[i]);
    }

    // inside an obstacle (grown by r)?
    blocked(x: f64, z: f64, r: f64): bool {
        for (let k = 0; k < OBST.length; k += 4) {
            if (x > OBST[k] - r && x < OBST[k + 1] + r && z > OBST[k + 2] - r && z < OBST[k + 3] + r) {
                return true;
            }
        }
        return false;
    }

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged) {
            this.best = 0;   // the visitor's best is their own, not the demo's
            this.newRun(api, api.demo ? MODE_RUN : MODE_READY);
        }
        this.t += dt;

        if (this.mode == MODE_RUN) {
            this.runT += dt;
            if (api.demo) {
                this.demoSteer(api, dt);
            }
            this.moveCat(api, dt);
            let hopping = this.hop > 0;
            if (hopping != this.wasHop && api.frame - this.hopFrame > 12) {
                this.hopFrame = api.frame;
                if (hopping) {
                    api.soundAt(SFX_JUMP, this.cx, 0.3, this.cz, 1.3, 0.45);     // a leap
                } else {
                    api.soundAt(SFX_THUD, this.cx, 0.0, this.cz, 1.5, 0.4);     // soft paws
                }
            }
            this.wasHop = hopping;
            this.lights(api, dt);
            this.fishes(api, dt);
            this.watch(api, dt);
        } else if (this.mode == MODE_READY) {
            // the hint: the cat sits by the front parapet, one lamp sweeps, the fish waits
            this.vx = 0;
            this.vz = 0;
            this.lights(api, dt);
            this.fishT += dt;
        } else {
            // caught: every lamp swings onto the cat
            this.vx = 0;
            this.vz = 0;
            for (let i = 0; i < NL; i++) {
                let u = Math.min(1, dt * 5);
                this.px[i] += (this.cx - this.px[i]) * u;
                this.pz[i] += (this.cz - this.pz[i]) * u;
            }
            if (api.demo && this.t > 2.2) {
                this.newRun(api, MODE_RUN);
            }
        }
        this.updateSparks(api, dt);
        this.popT += dt;
        this.flinch = Math.max(0, this.flinch - dt * 3);
        this.shakeT = Math.max(0, this.shakeT - dt);
        this.draw(api);
    }

    moveCat(api: GameApi, dt: f64): void {
        let tx = clamp(this.tx, -X_MAX, X_MAX), tz = clamp(this.tz, Z_MIN, Z_MAX);
        // never stop in the alley: aim for the nearer roof's edge
        if (Math.abs(tx) < GAP + 0.15) {
            tx = this.cx < 0 ? -(GAP + 0.15) : GAP + 0.15;
            if (Math.abs(this.cx) < GAP) {
                tx = this.vx < 0 ? -(GAP + 0.2) : GAP + 0.2;
            }
        }
        let dx = tx - this.cx, dz = tz - this.cz;
        let d = Math.hypot(dx, dz);
        let want = Math.min(SPEED, d * 5.0);
        let wx = d > 0.02 ? dx / d * want : 0, wz = d > 0.02 ? dz / d * want : 0;
        let k = Math.min(1, dt * 9);
        this.vx += (wx - this.vx) * k;
        this.vz += (wz - this.vz) * k;
        // crossing the alley the cat leaps: keep up its speed over the gap
        if (Math.abs(this.cx) < GAP + 0.05 && Math.abs(this.vx) < 2.2) {
            this.vx = this.vx < 0 || (this.vx == 0 && this.cx < 0) ? -2.2 : 2.2;
        }
        let nx = this.cx + this.vx * dt, nz = this.cz + this.vz * dt;
        nx = clamp(nx, -X_MAX, X_MAX);
        nz = clamp(nz, Z_MIN, Z_MAX);
        // obstacles: slide along them
        if (this.blocked(nx, nz, CAT_R)) {
            if (!this.blocked(nx, this.cz, CAT_R)) {
                nz = this.cz;
                this.vz = 0;
            } else if (!this.blocked(this.cx, nz, CAT_R)) {
                nx = this.cx;
                this.vx = 0;
            } else {
                nx = this.cx;
                nz = this.cz;
                this.vx = 0;
                this.vz = 0;
            }
        }
        this.cx = nx;
        this.cz = nz;
        let sp = Math.hypot(this.vx, this.vz);
        if (sp > 0.3) {
            let face = Math.atan2(this.vx, this.vz) * 180 / Math.PI;
            this.yaw += wrap180(face - this.yaw) * Math.min(1, dt * 12);
        }
        this.walk += sp * dt * 5.5;
        // the hop over the alley: an arc across x in [-0.62, 0.62]
        let u = (this.cx + 0.62) / 1.24;
        this.hop = u > 0 && u < 1 ? Math.sin(u * Math.PI) * 0.55 : 0;
    }

    lights(api: GameApi, dt: f64): void {
        let speed = this.mode == MODE_RUN ? Math.min(1.15, 0.55 + this.runT * 0.011) : 0.55;
        for (let i = 0; i < NL; i++) {
            if (!this.on[i] && this.mode == MODE_RUN && this.runT >= WAKE[i]) {
                this.on[i] = true;
                this.wake[i] = 0;
                this.farFromCat(i);
                api.soundAt(SFX_CLICK, LX[i], LY[i], LZ[i], 0.5, 1.0);   // the switch
                api.soundAt(SFX_ZAP, LX[i], LY[i], LZ[i], 0.35, 0.5);    // the lamp buzzes on
            }
            this.wake[i] += dt;
            if (!this.on[i]) {
                continue;
            }
            this.clock[i] += dt * speed;
            this.sweep(i, this.clock[i]);
            // a lamp that saw the cat follows it for a while, slower than the cat runs
            if (this.chase[i] > 0) {
                let cs = 1.6 + Math.min(1.2, this.runT * 0.02);
                let dx = this.cx - this.chX[i], dz = this.cz - this.chZ[i];
                let d = Math.hypot(dx, dz);
                if (d > 0.01) {
                    let m = Math.min(d, cs * dt);
                    this.chX[i] += dx / d * m;
                    this.chZ[i] += dz / d * m;
                }
                let w = Math.min(1, this.chase[i] * 1.6);
                this.px[i] = this.px[i] * (1 - w) + this.chX[i] * w;
                this.pz[i] = this.pz[i] * (1 - w) + this.chZ[i] * w;
                this.chase[i] = Math.max(0, this.chase[i] - dt * 0.45);
            }
        }
    }

    // the alarm: any pool on the cat fills it; out of the light it drains
    watch(api: GameApi, dt: f64): void {
        let lit = false;
        for (let i = 0; i < NL; i++) {
            if (!this.on[i] || this.wake[i] < 0.3) {
                continue;
            }
            let d = Math.hypot(this.px[i] - this.cx, this.pz[i] - this.cz);
            if (d < POOL_R - 0.05 && this.hop < 0.2) {
                lit = true;
                if (this.chase[i] < 0.5) {
                    this.chX[i] = this.px[i];
                    this.chZ[i] = this.pz[i];
                }
                this.chase[i] = 1.0;
            }
        }
        if (lit && !this.seen) {
            this.flinch = 1;
            this.seenN = 0;
        }
        // the alarm beeps while the cat is lit: every 8 frames, rising with the meter
        if (lit) {
            if (this.seenN % 8 == 0) {
                api.soundAt(SFX_BLIP, this.cx, 0.5, this.cz, 0.5 + this.alarm * 0.9, 0.5 + this.alarm * 0.35);
            }
            this.seenN++;
        }
        this.seen = lit;
        this.alarm = lit ? this.alarm + FILL * dt : Math.max(0, this.alarm - DRAIN * dt);
        if (this.alarm >= 1) {
            this.alarm = 1;
            this.mode = MODE_CAUGHT;
            this.t = 0;
            this.shakeT = 0.5;
            api.soundAt(SFX_HIT, this.cx, 0.5, this.cz, 0.8, 0.7);   // the cat jumps
            api.sound(SFX_LOSE, 0.85, 0.85);
            if (this.score > this.best) {
                this.best = this.score;
            }
            for (let i = 0; i < NL; i++) {
                this.on[i] = true;
            }
        }
    }

    fishes(api: GameApi, dt: f64): void {
        if (!this.fishOn) {
            this.fishGone -= dt;
            if (this.fishGone <= 0) {
                this.placeFish(api);
            }
            return;
        }
        this.fishT += dt;
        // the cat's mouth: a little ahead of its centre
        let yr = this.yaw * Math.PI / 180;
        let mx = this.cx + Math.sin(yr) * 0.45, mz = this.cz + Math.cos(yr) * 0.45;
        if (Math.hypot(this.fx - mx, this.fz - mz) < 0.5 || Math.hypot(this.fx - this.cx, this.fz - this.cz) < 0.5) {
            this.score++;
            if (this.score > this.best) {
                this.best = this.score;
            }
            this.popText = this.fishT < 2.5 ? "+1 QUICK!" : "+1";
            let semi = <f64>min<i32>(this.score - 1, 12);
            api.soundAt(SFX_COIN, this.fx, 0.5, this.fz, Math.pow(2, semi / 12) * 0.8, 0.75);
            if (this.fishT < 2.5) {
                api.note(76 + semi, 0.5, 0, SFX_NOTE);
            }
            this.popT = 0;
            this.popX = this.fx;
            this.popZ = this.fz;
            this.burst(api, this.fx, 0.5, this.fz);
            this.fishOn = false;
            this.fishGone = 0.35;
            this.alarm = Math.max(0, this.alarm - 0.15);
            this.dPlan = 0;
        }
    }

    placeFish(api: GameApi): void {
        for (let tries = 0; tries < 40; tries++) {
            let x = api.range(-5.9, 5.9), z = api.range(-1.7, 2.5);
            if (Math.abs(x) < GAP + 0.5 || this.blocked(x, z, 0.45)) {
                continue;
            }
            let d = Math.hypot(x - this.cx, z - this.cz);
            if (d < 2.6 || d > 7.5) {
                continue;
            }
            this.fx = x;
            this.fz = z;
            break;
        }
        this.fishOn = true;
        this.fishT = 0;
        api.soundAt(SFX_POP, this.fx, 0.4, this.fz, 0.7, 0.45);
        this.dGreedy = api.rand() < 0.12;
        this.dErrX = api.range(-0.25, 0.25);
        this.dErrZ = api.range(-0.25, 0.25);
    }

    burst(api: GameApi, x: f64, y: f64, z: f64): void {
        for (let i = 0; i < NS; i++) {
            let a = <f64>i / <f64>NS * Math.PI * 2 + api.range(-0.3, 0.3);
            let s = api.range(2.0, 3.0);
            this.sX[i] = x;
            this.sY[i] = y;
            this.sZ[i] = z;
            this.sVX[i] = Math.cos(a) * s;
            this.sVZ[i] = Math.sin(a) * s * 0.8;
            this.sVY[i] = api.range(1.2, 2.2);
            this.sT[i] = 0;
        }
    }

    updateSparks(api: GameApi, dt: f64): void {
        for (let i = 0; i < NS; i++) {
            if (this.sT[i] > 0.6) {
                api.hide(this.spark[i]);
                continue;
            }
            this.sT[i] += dt;
            this.sVY[i] -= 9 * dt;
            this.sX[i] += this.sVX[i] * dt;
            this.sY[i] += this.sVY[i] * dt;
            this.sZ[i] += this.sVZ[i] * dt;
            let s = Math.floor((1 - this.sT[i] / 0.6) * 4) / 4;
            if (s < 0.25 || this.sY[i] < 0.05) {
                api.hide(this.spark[i]);
                continue;
            }
            api.place(this.spark[i], this.sX[i], this.sY[i], this.sZ[i], stepped(api.time, 12) * 400 + <f64>i * 40, 0, 0, s);
        }
    }

    // The demo sneak: re-plans a few times a second. It tries twelve directions and takes the one that
    // best trades getting closer to the fish against the light (each pool where it is and where it will
    // be in a moment); with the fish in a pool it waits nearby in the dark. Some fish it wants too much
    // (greedy: it weighs the light lightly), and now and then it reacts late.
    demoSteer(api: GameApi, dt: f64): void {
        this.dPlan -= dt;
        if (this.dPlan > 0) {
            return;
        }
        this.dPlan = api.range(0.12, 0.28);
        if (api.rand() < 0.08) {
            this.dPlan += 0.35;   // a lapse: keeps going the old way a little longer
            return;
        }
        let gx = this.fishOn ? this.fx + this.dErrX : this.cx, gz = this.fishOn ? this.fz + this.dErrZ : this.cz;
        let sweepSpeed = Math.min(1.15, 0.55 + this.runT * 0.011);
        let fishLit = false;
        for (let i = 0; i < NL; i++) {
            if (this.on[i] && Math.hypot(gx - this.px[i], gz - this.pz[i]) < POOL_R + 0.35) {
                fishLit = true;
            }
        }
        if (fishLit && !this.dGreedy && Math.hypot(gx - this.cx, gz - this.cz) < 2.6) {
            gx = this.cx;   // wait it out where it is (the light term moves it off if it must)
            gz = this.cz;
        }
        let w = this.dGreedy ? 0.5 : 3.0;
        let bestS = -1e9, bx = this.cx, bz = this.cz;
        let d0 = Math.hypot(gx - this.cx, gz - this.cz);
        for (let k = 0; k < 13; k++) {
            let x = this.cx, z = this.cz;
            if (k < 12) {
                let a = <f64>k / 12.0 * Math.PI * 2;
                let step = Math.min(1.5, d0 + 0.3);
                x = clamp(this.cx + Math.cos(a) * step, -X_MAX, X_MAX);
                z = clamp(this.cz + Math.sin(a) * step, Z_MIN, Z_MAX);
            }
            if (this.blocked(x, z, CAT_R + 0.05)) {
                continue;
            }
            let danger = 0.0;
            for (let i = 0; i < NL; i++) {
                if (!this.on[i]) {
                    continue;
                }
                let c = this.clock[i] + 0.45 * sweepSpeed;
                let qx = PCX[i] + PAX[i] * Math.sin(c), qz = PCZ[i] + PAZ[i] * Math.sin(PK[i] * c + PQ[i]);
                if (this.chase[i] > 0) {
                    qx = this.px[i] + (this.cx - this.px[i]) * 0.3;
                    qz = this.pz[i] + (this.cz - this.pz[i]) * 0.3;
                }
                let r = POOL_R + 0.8;
                // the path's midpoint and its end, against the pool now and in a moment
                let mx = (x + this.cx) * 0.5, mz = (z + this.cz) * 0.5;
                danger += Math.max(0, r - Math.hypot(x - qx, z - qz)) + Math.max(0, r - Math.hypot(x - this.px[i], z - this.pz[i]))
                        + 0.5 * Math.max(0, r - Math.hypot(mx - this.px[i], mz - this.pz[i]));
            }
            let sc = (d0 - Math.hypot(gx - x, gz - z)) - w * danger + api.range(0, 0.15);
            if (sc > bestS) {
                bestS = sc;
                bx = x;
                bz = z;
            }
        }
        this.tx = bx;
        this.tz = bz;
    }

    draw(api: GameApi): void {
        // clouds drift over the moon
        for (let i = 0; i < 2; i++) {
            let sp = i == 0 ? 0.22 : 0.15;
            let x = ((api.time * sp + <f64>i * 7.3 + 3.0) % 18.0) - 9.0;
            api.place(this.cloud[i], x, i == 0 ? -3.35 : -2.75, -9.4 + <f64>i * 0.3, 0, 0, 0, i == 0 ? 1.0 : 0.8);
        }

        // lamps aim at their pools; pools sit on the roof
        for (let i = 0; i < NL; i++) {
            let lit = this.on[i];
            let gx = lit ? this.px[i] : LX[i] + 0.3, gz = lit ? this.pz[i] : LZ[i] + 1.2;
            let gy = lit ? 0.0 : LY[i] - 1.6;    // an idle lamp hangs its head
            let dx = gx - LX[i], dy = gy - LY[i], dz = gz - LZ[i];
            let yawL = Math.atan2(dx, dz) * 180 / Math.PI;
            let pitchL = Math.atan2(-dy, Math.hypot(dx, dz)) * 180 / Math.PI;
            api.place(this.lamp[i], LX[i], LY[i], LZ[i], yawL, pitchL);
            if (!lit) {
                api.hide(this.pool[i]);
                continue;
            }
            // switching on: the pool pops open in steps
            let w = this.wake[i];
            let s = w < 0.3 ? Math.floor(w / 0.3 * 4 + 1) / 5 : 1.0;
            api.place(this.pool[i], this.px[i], 0, this.pz[i], 0, 0, 0, s);
        }

        // the fish: grows in, bobs and turns (stepped)
        if (this.fishOn && this.mode != MODE_CAUGHT) {
            let g = Math.min(1, this.fishT / 0.25);
            let s = g < 1 ? 0.4 + Math.floor(g * 3) / 3 * 0.6 : 1.0;
            let bob = Math.sin(stepped(api.time, 10) * 4.0) * 0.07;
            api.place(this.fish, this.fx, 0.42 + bob, this.fz, stepped(api.time, 10) * 70, 0, 0, s);
        } else {
            api.hide(this.fish);
        }

        // the cat
        let sp = Math.hypot(this.vx, this.vz);
        let moving = this.mode == MODE_RUN && sp > 0.25;
        let ph = Math.floor(this.walk / (Math.PI / 4)) * (Math.PI / 4);   // an 8-frame walk cycle
        let swing = moving ? 30 * Math.min(1, sp / 1.4) : 0;
        let bob = moving ? Math.abs(Math.sin(ph)) * 0.05 : 0;
        let sq = this.flinch > 0 ? Math.sin(this.flinch * Math.PI) * 0.18 : 0;
        let cy = this.hop + bob;
        let roll = 0.0;
        let yaw = this.yaw;
        if (this.mode == MODE_CAUGHT) {
            // startled: a jump straight up, frozen in the light
            let u = Math.min(1, this.t / 0.45);
            cy = Math.sin(u * Math.PI) * 0.6;
            sq = this.t < 0.15 ? 0.2 : (u < 1 ? -0.12 : 0);
        }
        let sh = 0.0;
        if (this.shakeT > 0) {
            sh = (Math.floor(api.time * 30) % 2 == 0 ? 1 : -1) * 0.04;
        }
        api.placeScaled(this.cat, this.cx + sh, cy, this.cz, yaw, 1 + sq * 0.6, 1 - sq, 1 + sq * 0.3, 0, roll);
        // legs at the hips (model: x +-0.13, y 0.34, z 0.13 front / -0.37 back, times SCALE), swung in diagonal pairs
        for (let k = 0; k < 4; k++) {
            let hx = (k % 2 == 0 ? -0.13 : 0.13) * SCALE;
            let hz = (k < 2 ? 0.13 : -0.37) * SCALE;
            api.transform(this.cat, hx, 0.34 * SCALE, hz);
            let a = (k == 0 || k == 3) ? Math.sin(ph) : -Math.sin(ph);
            let lp = -a * swing;
            if (this.mode == MODE_CAUGHT && this.t < 0.45) {
                lp = (k < 2 ? -35 : 35);   // legs splayed in the jump
            }
            api.place(this.leg[k], api.tx, api.ty, api.tz, yaw, lp, 0, 1);
        }
        // the tail: sways (stepped), stands up when the cat is seen
        api.transform(this.cat, 0, 0.55 * SCALE, -0.44 * SCALE);
        let tsw = Math.sin(stepped(api.time, 8) * 2.6) * (moving ? 8 : 14);
        let tp = this.seen || this.mode == MODE_CAUGHT ? -14 : (moving ? 10 : 0);
        api.place(this.tail, api.tx, api.ty, api.tz, yaw, tp, tsw, 1);
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.mode == MODE_READY || (this.mode == MODE_CAUGHT && this.t > 0.6)) {
                this.newRun(api, MODE_RUN);
                api.sound(SFX_WIN, 0.75, 0.8);   // a low start
                api.sound(SFX_CLICK, 0.6, 0.8);
            }
        }
        if ((kind == POINTER_DOWN || kind == POINTER_MOVE) && this.mode == MODE_RUN) {
            if (api.pick(x, y, 0)) {
                this.tx = api.hitX;
                this.tz = api.hitZ;
            }
        }
        return true;
    }

    // a dotted line (every other pixel, its dots marching) from (x0, y0) to (x1, y1)
    beam(api: GameApi, x0: f32, y0: f32, x1: f32, y1: f32, c: u32, phase: i32): void {
        let n = <i32>Math.max(Math.abs(<f64>(x1 - x0)), Math.abs(<f64>(y1 - y0)));
        for (let k = 0; k <= n; k++) {
            if ((k + phase) % 2 != 0) {
                continue;
            }
            let u = n > 0 ? <f32>k / <f32>n : 0;
            api.rect(Mathf.round(x0 + (x1 - x0) * u), Mathf.round(y0 + (y1 - y0) * u), 1, 1, c);
        }
    }

    hud(api: GameApi): void {
        let plum = api.paletteColor(0);
        let wine = api.paletteColor(1);
        let slate = api.paletteColor(2);
        let sea = api.paletteColor(4);
        let mint = api.paletteColor(5);
        let W = <f32>api.hudW;

        // the beams: dotted rays from each lit lamp's lens to the edges of its pool
        let phase = <i32>Math.floor(api.time * 8) % 2;
        for (let i = 0; i < NL; i++) {
            if (!this.on[i]) {
                continue;
            }
            let dx = this.px[i] - LX[i], dz = this.pz[i] - LZ[i];
            let h = Math.hypot(dx, dz);
            let lx = <f32>(LX[i] + dx / h * 0.28), lz = <f32>(LZ[i] + dz / h * 0.28);
            if (!api.project(lx, <f32>(LY[i] - 0.08), lz)) {
                continue;
            }
            let sx = api.screenX, sy = api.screenY;
            // the pool's left and right edges as seen (perpendicular to the view, along x)
            let s = this.wake[i] < 0.3 ? 0.6 : 0.92;
            api.project(<f32>(this.px[i] - s), 0.1, <f32>this.pz[i]);
            let ax = api.screenX, ay = api.screenY;
            api.project(<f32>(this.px[i] + s), 0.1, <f32>this.pz[i]);
            let bx = api.screenX, by = api.screenY;
            this.beam(api, sx - 1, sy, ax, ay, sea, phase);
            this.beam(api, sx + 1, sy, bx, by, sea, phase);
        }

        // a marker bobbing over the fish (stepped), so it is found at a glance
        if (this.fishOn && this.mode != MODE_CAUGHT && api.project(<f32>this.fx, 1.05, <f32>this.fz)) {
            let by = api.screenY - <f32>(Math.floor(api.time * 4) % 2);
            let bx = Mathf.round(api.screenX);
            api.rect(bx - 2, by, 5, 1, mint);
            api.rect(bx - 1, by + 1, 3, 1, mint);
            api.rect(bx, by + 2, 1, 1, mint);
        }

        api.text(4, 4, "FISH " + this.score.toString(), mint, 1, plum);
        let bs = "BEST " + this.best.toString();
        api.text(W - 4 - api.textWidth(bs, 1), 4, bs, sea, 1, plum);
        if (api.demo) {
            api.textCentered(4, "DEMO", slate, 1, plum);
        }

        // the alarm: a bar under the score, an eye that opens
        if (this.mode != MODE_READY) {
            api.rect(4, 12, 34, 5, plum);
            api.rect(5, 13, 32, 3, slate);
            let f = <f32>Math.round(this.alarm * 32);
            if (f > 0 && (this.alarm < 0.6 || Math.floor(api.time * 8) % 2 == 0)) {
                api.rect(5, 13, f, 3, this.alarm < 0.6 ? sea : mint);
            }
        }

        // over the cat: "!" while it is seen, "?" while the alarm drains
        if (this.alarm > 0.02 && this.mode != MODE_READY) {
            if (api.project(<f32>this.cx, <f32>(1.6 + this.hop), <f32>this.cz)) {
                let mark = this.seen || this.mode == MODE_CAUGHT ? "!" : "?";
                let c = this.seen || this.mode == MODE_CAUGHT ? mint : sea;
                let sc = this.alarm > 0.5 || this.mode == MODE_CAUGHT ? 2 : 1;
                api.text(api.screenX - <f32>(sc), api.screenY - <f32>(5 * sc), mark, c, sc, plum);
            }
        }

        // a grab: the points rise from the fish
        if (this.popT < 1.0) {
            if (api.project(<f32>this.popX, <f32>(1.5 + this.popT * 0.9), <f32>this.popZ)) {
                api.text(api.screenX - api.textWidth(this.popText, 1) * 0.5, api.screenY, this.popText, mint, 1, plum);
            }
        }

        if (this.mode == MODE_READY) {
            api.textCentered(16, "MOVE TO SNEAK, GRAB THE FISH", mint, 1, plum);
            api.textCentered(24, "STAY OUT OF THE SEARCHLIGHTS", sea, 1, plum);
            if (Math.floor(api.time * 2) % 2 == 0) {
                api.textCentered(<f32>api.hudH - 12, "CLICK TO START", mint, 1, plum);
            }
        }
        if (this.mode == MODE_CAUGHT) {
            // the lines go where the cat is not: under the sky when it is low on the roof, else low
            let y = <f32>34;
            if (api.project(<f32>this.cx, 0.6, <f32>this.cz) && api.screenY < 64) {
                y = <f32>api.hudH - 44;
            }
            api.textCentered(y, "CAUGHT!", mint, 2, plum);
            api.textCentered(y + 14, "FISH " + this.score.toString() + "   BEST " + this.best.toString(), sea, 1, plum);
            if (!api.demo && this.t > 0.6) {
                api.textCentered(y + 24, "CLICK TO SNEAK AGAIN", mint, 1, plum);
            }
        }
    }
}
