// Cannon Cove: hold to charge the cannon (the barrel rises and an aim ring slides out over the
// water), release to fire. Sloops cross the cove on three lanes; lead them so the ball lands on a
// deck. Near ships score 1, the middle lane 2, the far lane 3. Ten shots a run.
//
// Everything here drives game bones baked by scene.bake.json ("bone" / "copies"): the barrel, a
// pool of four ships, the ball, the aim marker, the muzzle flash, splashes, smoke puffs and planks.
// Deterministic: api.rand() only.
import { GameApi, POINTER_DOWN, POINTER_UP } from "./game_api";

// ramps in art/palette.json order
const R_SEA: i32 = 0;
const R_GLOW: i32 = 6;

// run modes
const IDLE: i32 = 0;   // the hint, before the first press
const PLAY: i32 = 1;
const OVER: i32 = 2;

// ship states
const OFF: i32 = 0;
const SAIL: i32 = 1;
const SINK: i32 = 2;

const SHOTS: i32 = 10;
const N_SHIP: i32 = 4;
const N_SPLASH: i32 = 3;
const N_SMOKE: i32 = 4;
const N_PLANK: i32 = 8;
const N_POP: i32 = 6;

// the barrel's pivot (trunnions) as baked, and the muzzle's distance from it
const PX: f64 = 0.0;
const PY: f64 = 1.988;
const PZ: f64 = 3.638;
const MUZZLE: f64 = 1.53;
const REST_ELEV: f64 = 6.0;
const MAX_ELEV: f64 = 38.0;

// where a charge lands: z from Z_NEAR (no charge) to Z_FAR (full)
const Z_NEAR: f64 = 0.0;
const Z_FAR: f64 = -10.0;
const RATE: f64 = 0.62;          // charge per second (it swings back down past full)
const X_EDGE: f64 = 10.5;        // ships appear and leave beyond this

export class Game {
    barrel: i32 = -1;
    ball: i32 = -1;
    marker: i32 = -1;
    flash: i32 = -1;

    // lanes
    laneZ: StaticArray<f64> = [-2.6, -5.4, -8.2];
    laneS: StaticArray<f64> = [1.0, 0.86, 0.74];
    laneV: StaticArray<f64> = [2.3, 1.9, 1.5];
    lanePts: StaticArray<i32> = [1, 2, 3];
    laneWait: StaticArray<f64> = [0, 0, 0];

    // ships
    shBone: StaticArray<i32> = new StaticArray<i32>(N_SHIP);
    shState: StaticArray<i32> = new StaticArray<i32>(N_SHIP);
    shLane: StaticArray<i32> = new StaticArray<i32>(N_SHIP);
    shX: StaticArray<f64> = new StaticArray<f64>(N_SHIP);
    shDir: StaticArray<f64> = new StaticArray<f64>(N_SHIP);
    shV: StaticArray<f64> = new StaticArray<f64>(N_SHIP);
    shT: StaticArray<f64> = new StaticArray<f64>(N_SHIP);
    shSink: StaticArray<f64> = new StaticArray<f64>(N_SHIP);

    // effects
    spBone: StaticArray<i32> = new StaticArray<i32>(N_SPLASH);
    spX: StaticArray<f64> = new StaticArray<f64>(N_SPLASH);
    spZ: StaticArray<f64> = new StaticArray<f64>(N_SPLASH);
    spT: StaticArray<f64> = new StaticArray<f64>(N_SPLASH);
    spSize: StaticArray<f64> = new StaticArray<f64>(N_SPLASH);
    spNext: i32 = 0;
    smBone: StaticArray<i32> = new StaticArray<i32>(N_SMOKE);
    smX: StaticArray<f64> = new StaticArray<f64>(N_SMOKE);
    smY: StaticArray<f64> = new StaticArray<f64>(N_SMOKE);
    smZ: StaticArray<f64> = new StaticArray<f64>(N_SMOKE);
    smVX: StaticArray<f64> = new StaticArray<f64>(N_SMOKE);
    smVY: StaticArray<f64> = new StaticArray<f64>(N_SMOKE);
    smVZ: StaticArray<f64> = new StaticArray<f64>(N_SMOKE);
    smT: StaticArray<f64> = new StaticArray<f64>(N_SMOKE);
    smLife: StaticArray<f64> = new StaticArray<f64>(N_SMOKE);
    smNext: i32 = 0;
    plBone: StaticArray<i32> = new StaticArray<i32>(N_PLANK);
    plX: StaticArray<f64> = new StaticArray<f64>(N_PLANK);
    plY: StaticArray<f64> = new StaticArray<f64>(N_PLANK);
    plZ: StaticArray<f64> = new StaticArray<f64>(N_PLANK);
    plVX: StaticArray<f64> = new StaticArray<f64>(N_PLANK);
    plVY: StaticArray<f64> = new StaticArray<f64>(N_PLANK);
    plVZ: StaticArray<f64> = new StaticArray<f64>(N_PLANK);
    plSpin: StaticArray<f64> = new StaticArray<f64>(N_PLANK);
    plOn: StaticArray<bool> = new StaticArray<bool>(N_PLANK);
    plNext: i32 = 0;
    flashT: f64 = 9;

    // floating texts
    popText: Array<string> = new Array<string>(N_POP);
    popX: StaticArray<f64> = new StaticArray<f64>(N_POP);
    popY: StaticArray<f64> = new StaticArray<f64>(N_POP);
    popZ: StaticArray<f64> = new StaticArray<f64>(N_POP);
    popT: StaticArray<f64> = new StaticArray<f64>(N_POP);
    popHit: StaticArray<bool> = new StaticArray<bool>(N_POP);
    popNext: i32 = 0;

    // the run
    mode: i32 = IDLE;
    shotsLeft: i32 = SHOTS;
    score: i32 = 0;
    hits: i32 = 0;
    best: i32 = 0;
    bestDemo: i32 = 0;
    overT: f64 = 0;
    endWait: f64 = -1;
    wasDemo: bool = false;
    firstShot: bool = false;

    // the cannon
    charging: bool = false;
    charge: f64 = 0;
    chargeT: f64 = 0;
    elev: f64 = REST_ELEV;
    recoilT: f64 = 9;

    // the ball
    flying: bool = false;
    flyT: f64 = 0;
    flyDur: f64 = 1;
    fromY: f64 = 0;
    fromZ: f64 = 0;
    toZ: f64 = 0;
    apex: f64 = 1;

    // the demo player
    aiWait: f64 = 0.15;
    aiAim: f64 = 0;
    aiIdle: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        this.barrel = api.bone("barrel");
        this.ball = api.bone("ball");
        this.marker = api.bone("marker");
        this.flash = api.bone("flash");
        for (let i = 0; i < N_SHIP; i++) {
            this.shBone[i] = api.bone("ship" + i.toString());
            this.shState[i] = OFF;
            api.hide(this.shBone[i]);
        }
        for (let i = 0; i < N_SPLASH; i++) {
            this.spBone[i] = api.bone("splash" + i.toString());
            this.spT[i] = 9;
            api.hide(this.spBone[i]);
        }
        for (let i = 0; i < N_SMOKE; i++) {
            this.smBone[i] = api.bone("smoke" + i.toString());
            this.smT[i] = 9;
            this.smLife[i] = 1;
            api.hide(this.smBone[i]);
        }
        for (let i = 0; i < N_PLANK; i++) {
            this.plBone[i] = api.bone("plank" + i.toString());
            this.plOn[i] = false;
            api.hide(this.plBone[i]);
        }
        for (let i = 0; i < N_POP; i++) {
            this.popText[i] = "";
            this.popT[i] = 9;
        }
        api.hide(this.ball);
        api.hide(this.marker);
        api.hide(this.flash);
        // the cove is busy from the first frame: two ships already under way
        this.launch(api, 0, 0, -3.2, 1.0);
        this.launch(api, 1, 1, 8.5, -1.0);
        this.laneWait[2] = 1.6;
        this.wasDemo = api.demo;
        if (api.demo) {
            this.newRun();
        }
    }

    // ---------------------------------------------------------------- the run

    newRun(): void {
        this.mode = PLAY;
        this.shotsLeft = SHOTS;
        this.score = 0;
        this.hits = 0;
        this.endWait = -1;
        this.charging = false;
        this.charge = 0;
        this.firstShot = false;
        this.aiWait = 0.1;
        this.aiIdle = 0;
    }

    level(): f64 {
        return <f64>(SHOTS - this.shotsLeft) / <f64>SHOTS;
    }

    // ---------------------------------------------------------------- the frame

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            // a gallery visitor took over (or handed back): a fresh run either way
            this.wasDemo = api.demo;
            this.newRun();
            this.flying = false;
            api.hide(this.ball);
        }
        if (this.mode == OVER) {
            this.overT += dt;
            if (api.demo && this.overT > 2.0) {
                this.newRun();
            }
        }
        if (api.demo && this.mode == IDLE) {
            this.newRun();
        }
        if (api.demo && this.mode == PLAY) {
            this.think(api, dt);
        }

        // charge: rises to full and swings back down while held
        if (this.charging) {
            this.chargeT += dt;
            let k = this.chargeT * RATE;
            let m = k - 2.0 * Math.floor(k / 2.0);
            this.charge = m <= 1.0 ? m : 2.0 - m;
        }
        let targetElev = this.charging ? REST_ELEV + (MAX_ELEV - REST_ELEV) * this.charge : REST_ELEV;
        this.elev += (targetElev - this.elev) * Math.min(1.0, dt * 14.0);

        this.updateShips(api, dt);
        this.updateBall(api, dt);
        this.updateEffects(api, dt);
        this.poseBarrel(api, dt);

        // the aim ring: where the current charge lands
        if (this.charging) {
            let z = this.landZ(this.charge);
            let pulse = 1.0 + 0.08 * Math.sin(api.time * 18.0);
            api.place(this.marker, 0, 0.06, z, 0, 0, 0, pulse);
        } else if (this.flying) {
            api.place(this.marker, 0, 0.06, this.toZ, 0, 0, 0, 0.8);
        } else {
            api.hide(this.marker);
        }

        // the end of a run: after the last ball and its splash or sinking
        if (this.mode == PLAY && this.shotsLeft == 0 && !this.flying) {
            if (this.endWait < 0) {
                this.endWait = 1.4;
            }
            this.endWait -= dt;
            if (this.endWait <= 0) {
                this.mode = OVER;
                this.overT = 0;
                if (api.demo) {
                    this.bestDemo = max<i32>(this.bestDemo, this.score);
                } else {
                    this.best = max<i32>(this.best, this.score);
                }
            }
        }
    }

    landZ(c: f64): f64 {
        return Z_NEAR + (Z_FAR - Z_NEAR) * c;
    }

    muzzleY(): f64 {
        return PY + MUZZLE * Math.sin(this.elev * Math.PI / 180.0);
    }

    muzzleZ(): f64 {
        return PZ - MUZZLE * Math.cos(this.elev * Math.PI / 180.0);
    }

    flight(c: f64): f64 {
        let d = this.muzzleZ() - this.landZ(c);
        return 0.45 + 0.075 * d;
    }

    // ---------------------------------------------------------------- input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            this.press();
        } else if (kind == POINTER_UP) {
            this.release(api);
        }
        return true;
    }

    press(): void {
        if (this.mode == OVER) {
            if (this.overT > 0.6) {
                this.newRun();
            }
            return;
        }
        if (this.mode == IDLE) {
            this.newRun();
        }
        if (this.mode == PLAY && !this.flying && this.shotsLeft > 0 && !this.charging) {
            this.charging = true;
            this.chargeT = 0;
            this.charge = 0;
        }
    }

    release(api: GameApi): void {
        if (!this.charging) {
            return;
        }
        this.charging = false;
        this.fire(api, this.charge);
    }

    fire(api: GameApi, c: f64): void {
        // the barrel snaps to the charge's elevation at the moment of the shot
        this.elev = REST_ELEV + (MAX_ELEV - REST_ELEV) * c;
        this.flying = true;
        this.flyT = 0;
        this.fromY = this.muzzleY();
        this.fromZ = this.muzzleZ();
        this.toZ = this.landZ(c);
        this.flyDur = this.flight(c);
        let d = this.fromZ - this.toZ;
        this.apex = 0.9 + 0.3 * d;
        this.shotsLeft -= 1;
        this.firstShot = true;
        this.recoilT = 0;
        this.flashT = 0;
        // smoke: three puffs rolling out of the muzzle
        for (let i = 0; i < 3; i++) {
            let k = this.smNext;
            this.smNext = (this.smNext + 1) % N_SMOKE;
            this.smX[k] = api.range(-0.15, 0.15);
            this.smY[k] = this.fromY + api.range(-0.05, 0.15);
            this.smZ[k] = this.fromZ - 0.3;
            this.smVX[k] = api.range(-0.8, 0.8);
            this.smVY[k] = api.range(0.4, 1.0);
            this.smVZ[k] = api.range(-1.8, -0.6);
            this.smT[k] = -0.04 * <f64>i;
            this.smLife[k] = api.range(1.0, 1.5);
        }
    }

    // ---------------------------------------------------------------- the demo player

    think(api: GameApi, dt: f64): void {
        if (this.charging) {
            // let go at the planned charge (on the rising swing)
            if (this.charge >= this.aiAim || this.chargeT * RATE >= 1.0) {
                this.release(api);
                this.aiWait = api.range(0.25, 0.7);
            }
            return;
        }
        if (this.flying || this.shotsLeft <= 0) {
            return;
        }
        this.aiWait -= dt;
        this.aiIdle += dt;
        if (this.aiWait > 0) {
            return;
        }
        // look for a ship that will be over the cannon's line just as a ball would land
        let best = -1;
        let bestC = 0.0;
        for (let i = 0; i < N_SHIP; i++) {
            if (this.shState[i] != SAIL) {
                continue;
            }
            let lane = this.shLane[i];
            let c = (this.laneZ[lane] - Z_NEAR) / (Z_FAR - Z_NEAR);
            let vx = this.shDir[i] * this.shV[i];
            let arrive = (0.0 - this.shX[i]) / vx;
            if (arrive <= 0) {
                continue;
            }
            let need = c / RATE + this.flight(c) + 0.05;
            let slack = arrive - need;
            if (slack >= -0.04 && slack < 0.06) {
                // prefer the far lanes, they score more
                if (best < 0 || lane > this.shLane[best]) {
                    best = i;
                    bestC = c;
                }
            }
        }
        if (best < 0 && this.aiIdle < 3.0) {
            return;
        }
        if (best < 0) {
            bestC = api.range(0.2, 0.7);   // impatient: a hopeful shot
        }
        // a human's error: usually small, now and then a clear miss
        let err = api.range(-0.025, 0.025);
        if (api.rand() < 0.22 && this.shotsLeft < SHOTS - 1) {
            err = (api.rand() < 0.5 ? -1.0 : 1.0) * api.range(0.07, 0.12);
        }
        this.aiAim = Math.max(0.03, Math.min(0.97, bestC + err));
        this.aiIdle = 0;
        this.press();
    }

    // ---------------------------------------------------------------- ships

    launch(api: GameApi, k: i32, lane: i32, x: f64, dir: f64): void {
        this.shState[k] = SAIL;
        this.shLane[k] = lane;
        this.shX[k] = x;
        this.shDir[k] = dir;
        let speed = this.laneV[lane] * (1.0 + 0.35 * this.level()) * api.range(0.85, 1.15);
        this.shV[k] = speed;
        this.shT[k] = api.range(0, 6.0);
        this.shSink[k] = 0;
    }

    laneBusy(lane: i32): bool {
        for (let i = 0; i < N_SHIP; i++) {
            if (this.shState[i] == SAIL && this.shLane[i] == lane) {
                return true;
            }
        }
        return false;
    }

    updateShips(api: GameApi, dt: f64): void {
        // a free lane gets a new ship after a short wait
        for (let lane = 0; lane < 3; lane++) {
            if (this.laneBusy(lane)) {
                continue;
            }
            this.laneWait[lane] -= dt;
            if (this.laneWait[lane] > 0) {
                continue;
            }
            for (let i = 0; i < N_SHIP; i++) {
                if (this.shState[i] == OFF) {
                    let dir = api.rand() < 0.5 ? 1.0 : -1.0;
                    this.launch(api, i, lane, -dir * X_EDGE, dir);
                    this.laneWait[lane] = api.range(0.4, 1.6);
                    break;
                }
            }
        }
        for (let i = 0; i < N_SHIP; i++) {
            let b = this.shBone[i];
            let st = this.shState[i];
            if (st == OFF) {
                api.hide(b);
                continue;
            }
            let lane = this.shLane[i];
            let s = this.laneS[lane];
            let z = this.laneZ[lane];
            let yaw = this.shDir[i] > 0 ? 0.0 : 180.0;
            this.shT[i] += dt;
            let t = this.shT[i];
            if (st == SAIL) {
                this.shX[i] += this.shDir[i] * this.shV[i] * dt;
                if (Math.abs(this.shX[i]) > X_EDGE + 0.5) {
                    this.shState[i] = OFF;
                    api.hide(b);
                    continue;
                }
                // bob and rock, stepped at 12 fps like the rest of the motion
                let ts = Math.floor(t * 12.0) / 12.0;
                let y = 0.05 * Math.sin(ts * 2.3);
                let rock = 4.0 * Math.sin(ts * 1.7);
                let nod = 2.0 * Math.sin(ts * 1.3 + 1.0);
                this.pose(api, b, this.shX[i], y, z, yaw, rock, nod, s, s, s);
            } else {
                // sinking: a hit pop, then the bow rises and the hull slides under
                this.shSink[i] += dt;
                let u = this.shSink[i];
                let pop = u < 0.12 ? 1.0 + 0.6 * (u / 0.12) * (1.0 - u / 0.12) * 4.0 * 0.25 : 1.0;
                let k = Math.min(1.0, u / 1.8);
                let y = -2.4 * k * k;
                let tilt = 30.0 * Math.min(1.0, u / 0.9);
                let list = 14.0 * Math.min(1.0, u / 0.6);
                let ss = s * pop;
                this.pose(api, b, this.shX[i], y, z, yaw, list, tilt, ss, ss, ss);
                if (u > 1.9) {
                    this.shState[i] = OFF;
                    api.hide(b);
                    this.laneWait[lane] = api.range(0.8, 1.6);
                }
            }
        }
    }

    // ---------------------------------------------------------------- the ball

    updateBall(api: GameApi, dt: f64): void {
        if (!this.flying) {
            api.hide(this.ball);
            return;
        }
        this.flyT += dt;
        let u = Math.min(1.0, this.flyT / this.flyDur);
        let z = this.fromZ + (this.toZ - this.fromZ) * u;
        let y = this.fromY + (0.1 - this.fromY) * u + 4.0 * this.apex * u * (1.0 - u);
        api.place(this.ball, 0, y, z);
        if (u >= 1.0) {
            this.flying = false;
            api.hide(this.ball);
            this.land(api, this.toZ);
        }
    }

    land(api: GameApi, z: f64): void {
        let hit = -1;
        for (let i = 0; i < N_SHIP; i++) {
            if (this.shState[i] != SAIL) {
                continue;
            }
            let lane = this.shLane[i];
            let s = this.laneS[lane];
            if (Math.abs(this.laneZ[lane] - z) < 0.8 * s && Math.abs(this.shX[i]) < 1.35 * s) {
                hit = i;
                break;
            }
        }
        if (hit >= 0) {
            let lane = this.shLane[hit];
            let pts = this.lanePts[lane];
            if (this.mode == PLAY) {
                this.score += pts;
                this.hits += 1;
            }
            this.shState[hit] = SINK;
            this.shSink[hit] = 0;
            this.splash(this.shX[hit], this.laneZ[lane], 1.3);
            let sx = this.shX[hit];
            for (let j = 0; j < 6; j++) {
                let k = this.plNext;
                this.plNext = (this.plNext + 1) % N_PLANK;
                this.plOn[k] = true;
                this.plX[k] = sx + api.range(-0.5, 0.5);
                this.plY[k] = 0.8;
                this.plZ[k] = this.laneZ[lane];
                this.plVX[k] = api.range(-3.0, 3.0);
                this.plVY[k] = api.range(3.0, 5.5);
                this.plVZ[k] = api.range(-1.5, 1.5);
                this.plSpin[k] = api.range(-720, 720);
            }
            this.popup("+" + pts.toString(), sx, 2.6, this.laneZ[lane], true);
        } else {
            this.splash(0, z, 1.0);
            this.popup("MISS", 0, 1.6, z, false);
        }
    }

    // ---------------------------------------------------------------- effects

    splash(x: f64, z: f64, size: f64): void {
        let k = this.spNext;
        this.spNext = (this.spNext + 1) % N_SPLASH;
        this.spX[k] = x;
        this.spZ[k] = z;
        this.spT[k] = 0;
        this.spSize[k] = size;
    }

    popup(s: string, x: f64, y: f64, z: f64, hit: bool): void {
        let k = this.popNext;
        this.popNext = (this.popNext + 1) % N_POP;
        this.popText[k] = s;
        this.popX[k] = x;
        this.popY[k] = y;
        this.popZ[k] = z;
        this.popT[k] = 0;
        this.popHit[k] = hit;
    }

    updateEffects(api: GameApi, dt: f64): void {
        for (let i = 0; i < N_SPLASH; i++) {
            this.spT[i] += dt;
            let t = this.spT[i];
            if (t > 0.75) {
                api.hide(this.spBone[i]);
                continue;
            }
            let s = this.spSize[i];
            // shoots up fast, hangs, falls back
            let h = t < 0.15 ? t / 0.15 * 1.15 : Math.max(0.0, 1.15 - (t - 0.15) / 0.6 * 1.15);
            let w = 0.6 + 0.7 * Math.min(1.0, t / 0.4);
            h = Math.max(0.05, h);
            api.placeScaled(this.spBone[i], this.spX[i], 0.0, this.spZ[i], 0, w * s, h * s, w * s);
        }
        for (let i = 0; i < N_SMOKE; i++) {
            this.smT[i] += dt;
            let t = this.smT[i];
            let life = this.smLife[i];
            if (t < 0 || t > life) {
                api.hide(this.smBone[i]);
                continue;
            }
            let drag = Math.exp(-t * 2.0);
            let x = this.smX[i] + this.smVX[i] * (1.0 - drag) / 2.0;
            let y = this.smY[i] + this.smVY[i] * t;
            let z = this.smZ[i] + this.smVZ[i] * (1.0 - drag) / 2.0;
            let u = t / life;
            let s = u < 0.2 ? 0.5 + 2.5 * u : 1.0 * (1.0 - (u - 0.2) / 0.8) + 0.15;
            api.place(this.smBone[i], x, y, z, 0, 0, 0, s);
        }
        for (let i = 0; i < N_PLANK; i++) {
            if (!this.plOn[i]) {
                api.hide(this.plBone[i]);
                continue;
            }
            this.plVY[i] -= 9.8 * dt;
            this.plX[i] += this.plVX[i] * dt;
            this.plY[i] += this.plVY[i] * dt;
            this.plZ[i] += this.plVZ[i] * dt;
            this.plSpin[i] *= 1.0;
            if (this.plY[i] < -0.1) {
                this.plOn[i] = false;
                api.hide(this.plBone[i]);
                continue;
            }
            let a = this.plSpin[i] * this.plY[i] * 0.2;
            api.place(this.plBone[i], this.plX[i], this.plY[i], this.plZ[i], a, a * 0.7, a * 0.3);
        }
        // the muzzle flash: two frames big, then gone
        this.flashT += dt;
        if (this.flashT < 0.12) {
            let e = this.elev * Math.PI / 180.0;
            let d = MUZZLE + 0.45;
            let s = this.flashT < 0.05 ? 1.3 : 0.8;
            api.place(this.flash, PX, PY + d * Math.sin(e), PZ - d * Math.cos(e), this.flashT * 900.0, 0, 0, s);
        } else {
            api.hide(this.flash);
        }
        for (let i = 0; i < N_POP; i++) {
            this.popT[i] += dt;
        }
    }

    poseBarrel(api: GameApi, dt: f64): void {
        this.recoilT += dt;
        let r = 0.0;
        let sq = 0.0;
        if (this.recoilT < 0.5) {
            // kicked back hard, eased home; squashed along the barrel for a few frames
            let t = this.recoilT;
            r = t < 0.05 ? 0.35 * t / 0.05 : 0.35 * Math.exp(-(t - 0.05) * 7.0);
            sq = t < 0.12 ? 1.0 - t / 0.12 : 0.0;
        }
        // charging: a slight tremble that grows with the charge (the anticipation)
        let tremble = this.charging ? 0.6 * this.charge * Math.sin(api.time * 70.0) : 0.0;
        let e = (this.elev + tremble) * Math.PI / 180.0;
        let x = PX;
        let y = PY - r * Math.sin(e);
        let z = PZ + r * Math.cos(e);
        let bulge = 1.0 + 0.16 * sq + 0.05 * this.charge * (this.charging ? 1.0 : 0.0);
        this.pose(api, this.barrel, x, y, z, 180.0, -(this.elev + tremble), 0.0, bulge, bulge, 1.0 - 0.22 * sq);
    }

    // A game bone with any rotation (yaw about Y, then pitch about X, then roll about Z, as
    // api.place) and a per-axis scale in the object's own frame: api.placeScaled only turns about Y.
    pose(api: GameApi, b: i32, x: f64, y: f64, z: f64, yawDeg: f64, pitchDeg: f64, rollDeg: f64,
         sx: f64, sy: f64, sz: f64): void {
        if (b <= 0 || b >= 64) {
            return;
        }
        let d = Math.PI / 180.0;
        let cy = Math.cos(yawDeg * d), sny = Math.sin(yawDeg * d);
        let cp = Math.cos(pitchDeg * d), sp = Math.sin(pitchDeg * d);
        let cr = Math.cos(rollDeg * d), sr = Math.sin(rollDeg * d);
        // R = Ry * Rx * Rz
        let r00 = cy * cr + sny * sp * sr, r01 = -cy * sr + sny * sp * cr, r02 = sny * cp;
        let r10 = cp * sr, r11 = cp * cr, r12 = -sp;
        let r20 = -sny * cr + cy * sp * sr, r21 = sny * sr + cy * sp * cr, r22 = cy * cp;
        // times S
        r00 *= sx; r10 *= sx; r20 *= sx;
        r01 *= sy; r11 *= sy; r21 *= sy;
        r02 *= sz; r12 *= sz; r22 *= sz;
        // times Ry(-yaw0)
        let y0 = <f64>api.restYaw[b] * d;
        let c0 = Math.cos(y0), s0 = Math.sin(y0);
        let a00 = r00 * c0 + r02 * s0, a01 = r01, a02 = -r00 * s0 + r02 * c0;
        let a10 = r10 * c0 + r12 * s0, a11 = r11, a12 = -r10 * s0 + r12 * c0;
        let a20 = r20 * c0 + r22 * s0, a21 = r21, a22 = -r20 * s0 + r22 * c0;
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

    // ---------------------------------------------------------------- HUD

    hud(api: GameApi): void {
        let cream = api.rampColor(R_GLOW, 3);
        let peach = api.rampColor(R_GLOW, 2);
        let orange = api.rampColor(R_GLOW, 1);
        let ember = api.rampColor(R_GLOW, 0);
        let navy = api.rampColor(R_SEA, 0);
        let slate = api.rampColor(R_SEA, 2);
        let W = <f32>api.hudW;

        // score and best
        api.text(6, 5, "SCORE " + this.score.toString(), cream, 2, navy);
        let b = api.demo ? this.bestDemo : this.best;
        let bs = "BEST " + b.toString();
        api.text(W - 6 - api.textWidth(bs, 2), 5, bs, peach, 2, navy);

        // the shots left: a row of balls under the score
        for (let i = 0; i < SHOTS; i++) {
            let x = <f32>(6 + i * 8);
            let live = i < this.shotsLeft;
            let c = live ? cream : slate;
            api.rect(x + 1, 19, 4, 6, navy);
            api.rect(x, 20, 6, 4, navy);
            api.rect(x + 1, 18, 4, 6, c);
            api.rect(x, 19, 6, 4, c);
        }

        // the charge gauge, beside the cannon
        if (this.charging) {
            let gx: f32 = 196, gy: f32 = 150, gh: f32 = 40;
            api.rect(gx - 1, gy - 1, 6, gh + 2, navy);
            let h = Mathf.round(<f32>this.charge * gh);
            api.rect(gx, gy + gh - h, 4, h, this.charge > 0.66 ? cream : (this.charge > 0.33 ? peach : orange));
        }

        // floating texts
        for (let i = 0; i < N_POP; i++) {
            let t = this.popT[i];
            if (t > 1.1) {
                continue;
            }
            if (api.project(<f32>this.popX[i], <f32>(this.popY[i] + t * 1.2), <f32>this.popZ[i])) {
                let s = this.popText[i];
                let sc = this.popHit[i] ? 2 : 1;
                let x = Mathf.round(api.screenX - api.textWidth(s, sc) * 0.5);
                api.text(x, Mathf.round(api.screenY), s, this.popHit[i] ? cream : peach, sc, navy);
            }
        }

        if (this.mode == IDLE) {
            api.textCentered(64, "HOLD TO CHARGE, RELEASE TO FIRE", cream, 1, navy);
            api.textCentered(74, "SINK THE SHIPS - FAR ONES SCORE MORE", peach, 1, navy);
        } else if (this.mode == PLAY && !this.firstShot && !api.demo) {
            api.textCentered(64, "HOLD TO CHARGE, RELEASE TO FIRE", cream, 1, navy);
        } else if (this.mode == OVER) {
            api.rect(0, 52, W, 40, navy);
            api.textCentered(56, "GAME OVER", cream, 3, ember);
            let rank = this.hits >= 9 ? "ADMIRAL!" : (this.hits >= 6 ? "CAPTAIN" : (this.hits >= 3 ? "GUNNER" : "DECKHAND"));
            let pts = this.score.toString() + (this.score == 1 ? " POINT - " : " POINTS - ");
            let hs = this.hits.toString() + (this.hits == 1 ? " HIT - " : " HITS - ");
            api.textCentered(75, pts + hs + rank, peach, 1);
            if (this.overT > 0.6 && !api.demo) {
                api.textCentered(84, "CLICK TO PLAY AGAIN", orange, 1);
            }
        }
    }
}
