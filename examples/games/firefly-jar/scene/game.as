// Firefly Jar: a summer night in a clearing. Sweep the net (it follows the pointer) through the
// fireflies to catch them; each one flies into the jar on the stump and glows there. Moths flutter
// towards the net: touch one and three fireflies escape from the jar and the net is knocked aside.
// 60 seconds; the score is the fireflies in the jar.
//
// Game bones from scene.bake.json: the net, 16 fireflies, 12 fireflies shown in the jar, 5 moths and
// 4 twinkles. Deterministic: api.rand() only. Demo mode plays itself like a decent human.
import { GameApi, POINTER_DOWN } from "./game_api";

// ramps in art/palette.json order
const R_GRASS: i32 = 0;   // plum, dark teal, green, cream
const R_WOOD: i32 = 2;    // plum, mauve, orange
const R_GLASS: i32 = 3;   // dark teal, teal, cream
const R_CLOTH: i32 = 4;   // plum, mauve, red, orange

const NET_Y: f64 = 1.0;
const X_MIN: f64 = -6.0;
const X_MAX: f64 = 6.0;
const Z_MIN: f64 = -3.6;
const Z_MAX: f64 = 4.8;
const JAR_X: f64 = -4.0;
const JAR_Y: f64 = 0.5;
const JAR_Z: f64 = 2.0;
const JAR_TOP: f64 = 1.45;
const RUN: f64 = 60.0;
const CATCH_PX: f32 = 10;
const MOTH_PX: f32 = 14;

const IDLE: i32 = 0;
const PLAY: i32 = 1;
const OVER: i32 = 2;

const F_AIR: i32 = 0;
const F_CAUGHT: i32 = 1;   // arcing into the jar
const F_WAIT: i32 = 2;     // gone; a new one rises from the grass soon

const NF: i32 = 16;
const NJ: i32 = 12;
const NM: i32 = 5;
const NS: i32 = 4;

export class Game {
    net: i32 = -1;
    fBone: StaticArray<i32> = new StaticArray<i32>(NF);
    fState: StaticArray<i32> = new StaticArray<i32>(NF);
    fCX: StaticArray<f64> = new StaticArray<f64>(NF);   // the centre it wanders round
    fCZ: StaticArray<f64> = new StaticArray<f64>(NF);
    fX: StaticArray<f64> = new StaticArray<f64>(NF);
    fY: StaticArray<f64> = new StaticArray<f64>(NF);
    fZ: StaticArray<f64> = new StaticArray<f64>(NF);
    fP: StaticArray<f64> = new StaticArray<f64>(NF);    // phases
    fT: StaticArray<f64> = new StaticArray<f64>(NF);
    fSX: StaticArray<f64> = new StaticArray<f64>(NF);   // where a catch started
    fSY: StaticArray<f64> = new StaticArray<f64>(NF);
    fSZ: StaticArray<f64> = new StaticArray<f64>(NF);

    jBone: StaticArray<i32> = new StaticArray<i32>(NJ);
    jX: StaticArray<f64> = new StaticArray<f64>(NJ);
    jY: StaticArray<f64> = new StaticArray<f64>(NJ);
    jZ: StaticArray<f64> = new StaticArray<f64>(NJ);
    jT: StaticArray<f64> = new StaticArray<f64>(NJ);    // since it arrived (a pop), or escaping (< 0)
    jEsc: StaticArray<f64> = new StaticArray<f64>(NJ);  // > 0: flying out of the jar
    shownInJar: i32 = 0;

    mBone: StaticArray<i32> = new StaticArray<i32>(NM);
    mOn: StaticArray<bool> = new StaticArray<bool>(NM);
    mX: StaticArray<f64> = new StaticArray<f64>(NM);
    mY: StaticArray<f64> = new StaticArray<f64>(NM);
    mZ: StaticArray<f64> = new StaticArray<f64>(NM);
    mVX: StaticArray<f64> = new StaticArray<f64>(NM);
    mVZ: StaticArray<f64> = new StaticArray<f64>(NM);
    mP: StaticArray<f64> = new StaticArray<f64>(NM);
    mCool: StaticArray<f64> = new StaticArray<f64>(NM);

    sBone: StaticArray<i32> = new StaticArray<i32>(NS);
    sX: StaticArray<f64> = new StaticArray<f64>(NS);
    sY: StaticArray<f64> = new StaticArray<f64>(NS);
    sZ: StaticArray<f64> = new StaticArray<f64>(NS);
    sT: StaticArray<f64> = new StaticArray<f64>(NS);
    sNext: i32 = 0;

    mode: i32 = IDLE;
    wasDemo: bool = false;
    score: i32 = 0;
    best: i32 = 0;
    bestDemo: i32 = 0;
    left: f64 = RUN;
    overTime: f64 = 0;
    popT: f64 = 9;          // "-3" over the net
    popX: f64 = 0;
    popN: i32 = 3;
    popZ: f64 = 0;

    // the net
    nX: f64 = 0;
    nZ: f64 = 1.0;
    nVX: f64 = 0;
    nVZ: f64 = 0;
    tX: f64 = 0;            // where it is going (the pointer on the net's plane)
    tZ: f64 = 1.0;
    stun: f64 = 0;
    catchT: f64 = 9;

    // the demo's hand
    dTarget: i32 = -1;
    dErrX: f64 = 0;
    dErrZ: f64 = 0;
    dErrIn: f64 = 0;
    dWander: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        this.net = api.bone("net");
        for (let i = 0; i < NF; i++) {
            this.fBone[i] = api.bone("fly" + i.toString());
            this.spawnFly(api, i, true);
        }
        for (let i = 0; i < NJ; i++) {
            this.jBone[i] = api.bone("jfly" + i.toString());
            api.hide(this.jBone[i]);
            // a fixed place on the jar's glass, on the side towards the camera
            let a = (-65.0 + 130.0 * api.rand()) * Math.PI / 180;
            let r = 0.4;
            this.jX[i] = JAR_X + r * Math.sin(a);
            this.jZ[i] = JAR_Z + r * Math.cos(a);
            this.jY[i] = JAR_Y + 0.12 + 0.5 * api.rand();
            this.jEsc[i] = 0;
        }
        for (let i = 0; i < NM; i++) {
            this.mBone[i] = api.bone("moth" + i.toString());
            this.mOn[i] = false;
            this.mP[i] = api.range(0, 6.28);
            api.hide(this.mBone[i]);
        }
        for (let i = 0; i < NS; i++) {
            this.sBone[i] = api.bone("spark" + i.toString());
            this.sT[i] = 9;
            api.hide(this.sBone[i]);
        }
        this.wakeMoth(api);
        this.wasDemo = api.demo;
        if (api.demo) {
            this.newRun(api);
            this.opening(api);
        }
    }

    // ------------------------------------------------------------------ runs

    private newRun(api: GameApi): void {
        // the fireflies of the last run fly out of the jar
        for (let i = 0; i < NJ; i++) {
            if (i < this.shownInJar) {
                this.jEsc[i] = 0.001;
            }
        }
        this.shownInJar = 0;
        this.mode = PLAY;
        this.score = 0;
        this.left = RUN;
        this.overTime = 0;
        this.stun = 0;
        for (let i = 1; i < NM; i++) {
            if (this.mOn[i]) {
                this.mOn[i] = false;
                api.hide(this.mBone[i]);
            }
        }
    }

    // the demo opens with the net already sweeping into a little line of fireflies: each is put
    // where its wander will carry it just as the net passes
    private opening(api: GameApi): void {
        this.nX = 2.8;
        this.nZ = 2.2;
        this.tX = 2.6;
        this.tZ = 2.2;
        this.nVX = -2.0;
        for (let k = 0; k < 3; k++) {
            let t = api.time + 0.45 + 0.3 * <f64>k;
            let px = this.nX - 0.9 - 0.9 * <f64>k;
            let pz = this.nZ + 0.15 * <f64>k;
            this.fP[k] = 1.6 + <f64>k * 0.8;
            this.fT[k] = 2.0;
            this.fState[k] = F_AIR;
            this.fCX[k] = px - this.wanderX(t, this.fP[k]);
            this.fCZ[k] = pz - this.wanderZ(t, this.fP[k]);
        }
        this.dTarget = 0;
        this.dErrX = 0;
        this.dErrZ = 0;
        this.dErrIn = 1.6;
    }

    private wanderX(t: f64, p: f64): f64 {
        return 0.8 * Math.sin(t * 0.7 + p) + 0.3 * Math.sin(t * 1.9 + p * 2.0);
    }

    private wanderZ(t: f64, p: f64): f64 {
        return 0.6 * Math.cos(t * 0.6 + p * 1.7) + 0.25 * Math.sin(t * 2.3 + p);
    }

    private gameOver(api: GameApi): void {
        this.mode = OVER;
        this.overTime = 0;
        if (api.demo) {
            this.bestDemo = max<i32>(this.bestDemo, this.score);
        } else {
            this.best = max<i32>(this.best, this.score);
        }
    }

    // ------------------------------------------------------------------ fireflies

    private spawnFly(api: GameApi, i: i32, anywhere: bool): void {
        // somewhere in the clearing, away from the net, rising out of the grass
        let x = 0.0, z = 0.0;
        for (let k = 0; k < 6; k++) {
            x = api.range(X_MIN + 0.4, X_MAX - 0.4);
            z = api.range(Z_MIN + 0.3, Z_MAX - 0.4);
            if ((x - this.nX) * (x - this.nX) + (z - this.nZ) * (z - this.nZ) > 4.0) {
                break;
            }
        }
        this.fCX[i] = x;
        this.fCZ[i] = z;
        this.fP[i] = api.range(0, 100);
        this.fT[i] = anywhere ? 2.0 : 0.0;
        this.fState[i] = F_AIR;
    }

    private updateFlies(api: GameApi, dt: f64): void {
        let t = api.time;
        // (the picking camera is set from the first drawn frame on: no catches in a run's first moment)
        let canCatch = this.mode == PLAY && this.stun <= 0 && RUN - this.left > 0.25;
        let netOn = api.project(<f32>this.nX, <f32>NET_Y, <f32>this.nZ);
        let nsx = api.screenX, nsy = api.screenY;
        for (let i = 0; i < NF; i++) {
            let b = this.fBone[i];
            let s = this.fState[i];
            this.fT[i] += dt;
            if (s == F_WAIT) {
                if (this.fT[i] > 0) {
                    this.spawnFly(api, i, false);
                }
                continue;
            }
            if (s == F_CAUGHT) {
                // an arc from the net into the jar's mouth, 0.55 s
                let u = Math.min(1.0, this.fT[i] / 0.55);
                let x = this.fSX[i] + (JAR_X - this.fSX[i]) * u;
                let z = this.fSZ[i] + (JAR_Z - this.fSZ[i]) * u;
                let y = this.fSY[i] + (JAR_TOP - this.fSY[i]) * u + Math.sin(u * Math.PI) * 1.2;
                api.place(b, x, y, z, 0, 0, 0, 1.0 - 0.4 * u);
                if (u >= 1.0) {
                    api.hide(b);
                    this.fState[i] = F_WAIT;
                    this.fT[i] = -api.range(1.5, 3.5);
                    this.intoJar(api);
                }
                continue;
            }
            // wandering: two slow loops and a hover; the centre drifts too
            let p = this.fP[i];
            this.fCX[i] += 0.25 * Math.sin(t * 0.13 + p) * dt;
            this.fCZ[i] += 0.25 * Math.cos(t * 0.11 + p * 1.3) * dt;
            // shy: they drift away from a net that comes close
            let ax = this.fX[i] - this.nX, az = this.fZ[i] - this.nZ;
            let a2 = ax * ax + az * az;
            if (a2 < 2.0 && a2 > 0.0001 && RUN - this.left > 1.5) {
                let ad = Math.sqrt(a2);
                this.fCX[i] += ax / ad * 1.3 * dt;
                this.fCZ[i] += az / ad * 1.3 * dt;
            }
            this.fCX[i] = Math.max(X_MIN + 0.5, Math.min(X_MAX - 0.5, this.fCX[i]));
            this.fCZ[i] = Math.max(Z_MIN + 0.4, Math.min(Z_MAX - 0.5, this.fCZ[i]));
            let x = this.fCX[i] + this.wanderX(t, p);
            let z = this.fCZ[i] + this.wanderZ(t, p);
            let rise = Math.min(1.0, this.fT[i] / 1.2);
            let y = (0.75 + 0.35 * Math.sin(t * 0.9 + p * 0.7)) * rise + 0.1;
            this.fX[i] = x;
            this.fY[i] = y;
            this.fZ[i] = z;
            // the glow: bright, with a dim blink now and then (stepped)
            let ph = (t * 0.45 + p * 0.37) % 1.0;
            let size = ph < 0.12 ? 0.55 : (ph < 0.2 ? 0.8 : 1.0);
            api.place(b, x, y, z, Math.floor(t * 3.0 + p) * 30.0, 0, 0, size * (0.4 + 0.6 * rise));
            if (canCatch && netOn && rise > 0.6 && api.project(<f32>x, <f32>y, <f32>z)) {
                let dx = api.screenX - nsx;
                let dy = api.screenY - nsy;
                if (dx * dx + dy * dy < CATCH_PX * CATCH_PX) {
                    this.fState[i] = F_CAUGHT;
                    this.fT[i] = 0;
                    this.fSX[i] = x;
                    this.fSY[i] = y;
                    this.fSZ[i] = z;
                    this.catchT = 0;
                    this.spark(x, y, z);
                }
            }
        }
    }

    private intoJar(api: GameApi): void {
        if (this.mode == PLAY) {
            this.score++;
        }
        if (this.shownInJar < NJ) {
            let j = this.shownInJar;
            this.jEsc[j] = 0;
            this.jT[j] = 0;
            this.shownInJar++;
        }
    }

    private updateJar(api: GameApi, dt: f64): void {
        let t = api.time;
        for (let j = 0; j < NJ; j++) {
            let b = this.jBone[j];
            if (this.jEsc[j] > 0) {
                // escaping: up and away over the trees, then gone
                this.jEsc[j] += dt;
                let u = this.jEsc[j];
                if (u > 1.4) {
                    this.jEsc[j] = 0;
                    api.hide(b);
                } else {
                    api.place(b, this.jX[j] + u * 1.2 * Math.sin(<f64>j * 2.1), JAR_TOP + u * 2.2, this.jZ[j] - u * 0.8, 0, 0, 0, 1);
                }
                continue;
            }
            if (j >= this.shownInJar) {
                continue;
            }
            this.jT[j] += dt;
            let pop = this.jT[j] < 0.2 ? 1.6 - this.jT[j] * 3.0 : 1.0;
            let tw = ((t * 0.6 + <f64>j * 0.29) % 1.0) < 0.15 ? 0.6 : 1.0;
            api.place(this.jBone[j], this.jX[j], this.jY[j], this.jZ[j], 0, 0, 0, pop * tw);
        }
    }

    private spark(x: f64, y: f64, z: f64): void {
        let i = this.sNext;
        this.sNext = (this.sNext + 1) % NS;
        this.sX[i] = x;
        this.sY[i] = y;
        this.sZ[i] = z;
        this.sT[i] = 0;
    }

    private updateSparks(api: GameApi, dt: f64): void {
        for (let i = 0; i < NS; i++) {
            if (this.sT[i] >= 0.32) {
                continue;
            }
            this.sT[i] += dt;
            if (this.sT[i] >= 0.32) {
                api.hide(this.sBone[i]);
                continue;
            }
            let u = this.sT[i] / 0.32;
            let s = Math.floor(Math.sin(u * Math.PI) * 4.0) / 4.0 + 0.25;
            api.place(this.sBone[i], this.sX[i], this.sY[i], this.sZ[i], u * 90.0, 45, 0, s);
        }
    }

    // ------------------------------------------------------------------ moths

    private wakeMoth(api: GameApi): void {
        for (let i = 0; i < NM; i++) {
            if (!this.mOn[i]) {
                this.mOn[i] = true;
                // in from a side, over the trees
                let side = api.rand() < 0.5 ? -1.0 : 1.0;
                this.mX[i] = side * 7.0;
                this.mZ[i] = api.range(-2.5, 3.5);
                this.mY[i] = api.range(1.0, 1.5);
                this.mVX[i] = -side * 1.0;
                this.mVZ[i] = 0;
                this.mCool[i] = 0;
                return;
            }
        }
    }

    private updateMoths(api: GameApi, dt: f64): void {
        let t = api.time;
        if (this.mode == PLAY) {
            let want = 1 + <i32>Math.floor((RUN - this.left) / 13.0);
            let have = 0;
            for (let i = 0; i < NM; i++) {
                if (this.mOn[i]) {
                    have++;
                }
            }
            if (have < min<i32>(want, NM)) {
                this.wakeMoth(api);
            }
        }
        let netOn = api.project(<f32>this.nX, <f32>NET_Y, <f32>this.nZ);
        let nsx = api.screenX, nsy = api.screenY;
        for (let i = 0; i < NM; i++) {
            if (!this.mOn[i]) {
                continue;
            }
            this.mCool[i] -= dt;
            // drawn to the net, erratic: a wobble, a sudden dart every second or so
            let dx = this.nX - this.mX[i];
            let dz = this.nZ - this.mZ[i];
            let d = Math.max(0.3, Math.sqrt(dx * dx + dz * dz));
            let pull = this.mCool[i] > 0 ? -1.2 : 0.75;
            let p = this.mP[i];
            this.mVX[i] += (dx / d * pull + 1.6 * Math.sin(t * 2.7 + p) - this.mVX[i] * 0.9) * dt * 2.0;
            this.mVZ[i] += (dz / d * pull + 1.6 * Math.cos(t * 2.3 + p * 1.7) - this.mVZ[i] * 0.9) * dt * 2.0;
            this.mX[i] += this.mVX[i] * dt;
            this.mZ[i] += this.mVZ[i] * dt;
            this.mX[i] = Math.max(-7.5, Math.min(7.5, this.mX[i]));
            this.mZ[i] = Math.max(Z_MIN - 0.5, Math.min(Z_MAX, this.mZ[i]));
            let y = this.mY[i] + 0.2 * Math.sin(t * 3.1 + p);
            let flap = Math.floor(t * 12.0 + p) % 2.0 == 0.0 ? 1.0 : 0.35;
            let yaw = Math.atan2(this.mVX[i], this.mVZ[i]) * 180 / Math.PI;
            api.placeScaled(this.mBone[i], this.mX[i], y, this.mZ[i], yaw, flap, 1, 1, 0, 0);
            // touching the net: three fireflies escape the jar, the net is knocked aside
            if (this.mode == PLAY && RUN - this.left > 0.25 && this.stun <= 0 && this.mCool[i] <= 0 && netOn && api.project(<f32>this.mX[i], <f32>y, <f32>this.mZ[i])) {
                let ex = api.screenX - nsx;
                let ey = api.screenY - nsy;
                if (ex * ex + ey * ey < MOTH_PX * MOTH_PX) {
                    this.mCool[i] = 1.6;
                    this.mVX[i] = -dx / d * 4.0;
                    this.mVZ[i] = -dz / d * 4.0;
                    this.stun = 0.8;
                    this.nVX += dx / d * 5.0;
                    this.nVZ += dz / d * 5.0;
                    let lost = min<i32>(3, this.score);
                    this.score -= lost;
                    for (let k = 0; k < lost; k++) {
                        if (this.shownInJar > 0 && this.score < this.shownInJar) {
                            this.shownInJar--;
                            this.jEsc[this.shownInJar] = 0.001;
                        }
                    }
                    this.popN = lost;
                    this.popT = lost > 0 ? 0.0 : 9.0;
                    this.popX = this.nX;
                    this.popZ = this.nZ;
                }
            }
        }
    }

    // ------------------------------------------------------------------ the demo's hand

    private updateDemo(api: GameApi, dt: f64): void {
        if (this.mode == OVER) {
            if (this.overTime > 2.0) {
                this.newRun(api);
                this.opening(api);
            }
            return;
        }
        // the nearest firefly that is not next to a moth; aim a little off, wander now and then
        let best = -1;
        let bestD = 1e9;
        for (let i = 0; i < NF; i++) {
            if (this.fState[i] != F_AIR || this.fT[i] < 1.0) {
                continue;
            }
            let dx = this.fX[i] - this.nX, dz = this.fZ[i] - this.nZ;
            let d = dx * dx + dz * dz;
            for (let m = 0; m < NM; m++) {
                if (!this.mOn[m]) {
                    continue;
                }
                let mx = this.fX[i] - this.mX[m], mz = this.fZ[i] - this.mZ[m];
                if (mx * mx + mz * mz < 1.0) {
                    d += 6.0;
                }
            }
            if (i == this.dTarget) {
                d -= 1.0;   // keeps to its choice
            }
            if (d < bestD) {
                bestD = d;
                best = i;
            }
        }
        this.dTarget = best;
        this.dErrIn -= dt;
        if (this.dErrIn <= 0) {
            this.dErrIn = api.range(0.5, 1.0);
            let e = api.rand() < 0.2 ? 0.9 : 0.25;
            this.dErrX = api.range(-e, e);
            this.dErrZ = api.range(-e, e);
        }
        let gx = this.nX, gz = this.nZ;
        if (best >= 0) {
            gx = this.fX[best] + this.dErrX;
            gz = this.fZ[best] + this.dErrZ;
        }
        // keep clear of moths close to the net (not always in time)
        for (let m = 0; m < NM; m++) {
            if (!this.mOn[m]) {
                continue;
            }
            let mx = this.nX - this.mX[m], mz = this.nZ - this.mZ[m];
            let d2 = mx * mx + mz * mz;
            if (d2 < 1.6) {
                let d = Math.sqrt(d2) + 0.05;
                gx += mx / d * 1.4;
                gz += mz / d * 1.4;
            }
        }
        // a hand moves at a hand's speed
        let mx = gx - this.tX, mz = gz - this.tZ;
        let m = Math.sqrt(mx * mx + mz * mz);
        let lim = 3.4 * dt;
        if (m > lim) {
            mx *= lim / m;
            mz *= lim / m;
        }
        this.tX += mx;
        this.tZ += mz;
    }

    // ------------------------------------------------------------------ the frame

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.newRun(api);
            if (api.demo) {
                this.opening(api);
            }
        }
        if (this.mode == PLAY) {
            this.left -= dt;
            if (this.left <= 0) {
                this.left = 0;
                this.gameOver(api);
            }
        } else if (this.mode == OVER) {
            this.overTime += dt;
        }
        this.stun -= dt;
        this.catchT += dt;
        this.popT += dt;

        if (api.demo) {
            this.updateDemo(api, dt);
        } else if (api.pointerX >= 0 && api.pick(api.pointerX, api.pointerY, <f32>NET_Y)) {
            this.tX = <f64>api.hitX;
            this.tZ = <f64>api.hitZ;
        } else if (this.mode == IDLE) {
            this.tX = 1.2 * Math.sin(api.time * 0.5);
            this.tZ = 1.0 + 0.6 * Math.sin(api.time * 0.37);
        }
        this.tX = Math.max(X_MIN, Math.min(X_MAX, this.tX));
        this.tZ = Math.max(Z_MIN, Math.min(Z_MAX, this.tZ));
        // the net chases its target on a spring; it leans into its sweep and squashes on a catch
        let k = this.stun > 0 ? 3.0 : 60.0;
        this.nVX += ((this.tX - this.nX) * k - this.nVX * (this.stun > 0 ? 3.0 : 14.0)) * dt;
        this.nVZ += ((this.tZ - this.nZ) * k - this.nVZ * (this.stun > 0 ? 3.0 : 14.0)) * dt;
        this.nX += this.nVX * dt;
        this.nZ += this.nVZ * dt;
        let roll = Math.max(-28.0, Math.min(28.0, -this.nVX * 5.0));
        let pitch = Math.max(-28.0, Math.min(28.0, this.nVZ * 5.0));
        if (this.stun > 0) {
            roll += Math.floor(this.stun * 20.0) % 2.0 == 0.0 ? 14.0 : -14.0;
        }
        let sq = this.catchT < 0.16 ? 1.18 : 1.0;
        let bob = Math.sin(api.time * 2.2) * 0.05;
        api.placeScaled(this.net, this.nX, NET_Y + bob, this.nZ, 0, sq, 1.0 / sq, sq, pitch, roll);

        this.updateFlies(api, dt);
        this.updateJar(api, dt);
        this.updateMoths(api, dt);
        this.updateSparks(api, dt);
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.mode == IDLE) {
                this.newRun(api);
            } else if (this.mode == OVER && this.overTime > 1.0) {
                this.newRun(api);
            }
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let V = api.rampColor(R_GRASS, 0);
        let N = api.rampColor(R_GRASS, 2);
        let W = api.rampColor(R_GRASS, 3);
        let O = api.rampColor(R_WOOD, 2);
        let L = api.rampColor(R_GLASS, 1);
        let E = api.rampColor(R_CLOTH, 2);
        let HW = <f32>api.hudW;
        let H = <f32>api.hudH;
        let best = api.demo ? this.bestDemo : this.best;

        api.text(6, 6, "JAR " + this.score.toString(), W, 2, V);
        api.text(6, 20, "BEST " + best.toString(), O, 1, V);
        // the clock, top right; the last ten seconds blink orange
        let secs = <i32>Math.ceil(this.left);
        let clock = "0:" + (secs < 10 ? "0" : "") + secs.toString();
        if (secs >= 60) {
            clock = "1:00";
        }
        let hurry = this.mode == PLAY && secs <= 10 && Math.floor(this.left * 4.0) % 2.0 == 0.0;
        api.text(HW - api.textWidth(clock, 2) - 6.0, 6, clock, hurry ? O : W, 2, V);

        if (this.popT < 0.9 && api.project(<f32>this.popX, <f32>(NET_Y + 0.6 + this.popT * 0.8), <f32>this.popZ)) {
            api.text(Mathf.round(api.screenX - 6.0), Mathf.round(api.screenY), "-" + this.popN.toString(), E, 2, V);
        }

        if (this.mode == IDLE) {
            api.textCentered(H - 30.0, "CLICK, THEN SWEEP THE NET", W, 2, V);
            api.textCentered(H - 14.0, "CATCH THE FIREFLIES - DODGE THE MOTHS", L, 1, V);
        } else if (this.mode == OVER) {
            api.rect(0, 68, HW, 50, V);
            api.textCentered(74, "TIME!", W, 3, 0);
            api.textCentered(94, this.score.toString() + " FIREFLIES IN THE JAR   BEST " + best.toString(), O, 1, 0);
            if (this.overTime > 1.0 && Math.floor(this.overTime * 2.0) % 2.0 == 0.0) {
                api.textCentered(105, api.demo ? "DEMO" : "CLICK TO PLAY AGAIN", N, 1, 0);
            }
        } else if (this.left > RUN - 3.0 && !api.demo) {
            api.textCentered(H - 14.0, "SWEEP THROUGH THE FIREFLIES - DODGE THE MOTHS", W, 1, V);
        }
        if (api.demo && this.mode != OVER) {
            api.text(HW - 22.0, H - 9.0, "DEMO", L, 1, V);
        }
    }
}
