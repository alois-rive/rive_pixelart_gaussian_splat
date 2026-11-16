// Moon Lander: hold to thrust, touch down softly on the pad as the little moon turns it under you.
// One verb (hold), one world. Every landing scores (softer and more centred is more), plants a flag
// and refuels a little; then the pad sinks and comes up somewhere else and the moon turns faster.
// Touching the bare moon, landing too fast or off the pad's middle is a crash: game over.
// Demo mode (api.demo) flies itself like a decent pilot with a few misses.
import { GameApi, POINTER_DOWN, POINTER_UP } from "./game_api";

const R: f64 = 4.0;          // the moon's radius; its centre at (0, CY)
const CY: f64 = -4.0;
const GRAV: f64 = 2.1;       // m/s^2
const THRUST: f64 = 4.5;
const SAFE: f64 = 1.6;       // the fastest soft touchdown, m/s
const PAD_TOP: f64 = 0.5;    // the deck's top above the pad's foot
const PAD_OK: f64 = 1.0;     // how far off the pad's middle a landing may be
const PAD_HALF: f64 = 1.9;   // pad half width + lander half width: inside this the pad is underfoot
const START_Y: f64 = 3.0;
const CEIL: f64 = 3.7;
const CAM_Y: f64 = 1.6;
const FX: i32 = 6;

const MODE_READY: i32 = 0;
const MODE_FLY: i32 = 1;
const MODE_LANDED: i32 = 2;
const MODE_OVER: i32 = 3;
const MODE_LIFT: i32 = 4;

// Places a game bone with a turn (degrees: yaw about Y, pitch about X, roll about Z) and a squash in
// world axes (sx, sy, sz) applied after the turn. GameApi.place has a uniform scale and placeScaled
// no roll; a tilted, squashed lander needs both.
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
    // R = Ry * Rx * Rz (as GameApi.place)
    let r00 = cy * cr + sny * sp * sr, r01 = -cy * sr + sny * sp * cr, r02 = sny * cp;
    let r10 = cp * sr, r11 = cp * cr, r12 = -sp;
    let r20 = -sny * cr + cy * sp * sr, r21 = sny * sr + cy * sp * cr, r22 = cy * cp;
    // A = S * R * Ry(-yaw0)
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

function wrap180(a: f64): f64 {
    let r = a % 360;
    if (r > 180) r -= 360;
    if (r < -180) r += 360;
    return r;
}

function clamp(v: f64, a: f64, b: f64): f64 {
    return v < a ? a : (v > b ? b : v);
}

export class Game {
    moon: i32 = -1;
    pad: i32 = -1;
    lander: i32 = -1;
    flame: i32 = -1;
    dust: StaticArray<i32> = new StaticArray<i32>(FX);
    debris: StaticArray<i32> = new StaticArray<i32>(FX);
    flag: StaticArray<i32> = new StaticArray<i32>(FX);

    mode: i32 = MODE_READY;
    t: f64 = 0;               // seconds in this mode
    lx: f64 = 0;              // the lander's feet
    ly: f64 = START_Y;
    vy: f64 = 0;
    roll: f64 = 0;
    fuel: f64 = 100;
    held: bool = false;
    thrusting: bool = false;
    thrustT: f64 = 0;         // seconds since the flame lit (ignition stretch)

    moonA: f64 = 0;           // the moon's turn, degrees (counter-clockwise as seen)
    spin: f64 = 20;           // degrees a second; its sign is the direction
    padLocal: f64 = -50;      // the pad's place on the moon, degrees from the top in the moon's frame
    padState: i32 = 0;        // 0 up, 1 sinking, 2 rising
    padT: f64 = 0;
    padS: f64 = 1;

    score: i32 = 0;
    best: i32 = 0;
    landings: i32 = 0;
    reason: string = "";
    shake: f64 = 0;
    shakeX: f64 = 0;
    shakeY: f64 = 0;
    squash: f64 = 0;          // 1 at a touchdown, decays
    lastLandScore: i32 = 0;

    dX: StaticArray<f64> = new StaticArray<f64>(FX);
    dY: StaticArray<f64> = new StaticArray<f64>(FX);
    dVX: StaticArray<f64> = new StaticArray<f64>(FX);
    dT: StaticArray<f64> = new StaticArray<f64>(FX);
    dLife: StaticArray<f64> = new StaticArray<f64>(FX);
    dNext: i32 = 0;
    dTimer: f64 = 0;

    bX: StaticArray<f64> = new StaticArray<f64>(FX);
    bY: StaticArray<f64> = new StaticArray<f64>(FX);
    bVX: StaticArray<f64> = new StaticArray<f64>(FX);
    bVY: StaticArray<f64> = new StaticArray<f64>(FX);
    bR: StaticArray<f64> = new StaticArray<f64>(FX);
    bVR: StaticArray<f64> = new StaticArray<f64>(FX);
    bOn: bool = false;

    fLocal: StaticArray<f64> = new StaticArray<f64>(FX);
    fOn: StaticArray<bool> = new StaticArray<bool>(FX);
    fPop: StaticArray<f64> = new StaticArray<f64>(FX);
    fNext: i32 = 0;

    popText: string = "";
    popText2: string = "";
    popT: f64 = 9;
    popX: f64 = 0;
    popY: f64 = 0;

    wasDemo: bool = false;
    demoErr: f64 = 0;
    demoThrust: bool = false;
    demoPlanned: bool = false;

    start(api: GameApi): void {
        api.playable = true;
        this.moon = api.bone("moon");
        this.pad = api.bone("pad");
        this.lander = api.bone("lander");
        this.flame = api.bone("flame");
        for (let i = 0; i < FX; i++) {
            this.dust[i] = api.bone("dust" + i.toString());
            this.debris[i] = api.bone("debris" + i.toString());
            this.flag[i] = api.bone("flag" + i.toString());
            api.hide(this.dust[i]);
            api.hide(this.debris[i]);
            api.hide(this.flag[i]);
            this.dT[i] = 99;
        }
        this.wasDemo = api.demo;
        this.newRun(api, api.demo ? MODE_FLY : MODE_READY);
    }

    newRun(api: GameApi, mode: i32): void {
        this.mode = mode;
        this.t = 0;
        this.lx = 0;
        this.ly = START_Y;
        this.vy = mode == MODE_FLY ? -0.4 : 0;
        this.roll = 0;
        this.fuel = 100;
        this.score = 0;
        this.landings = 0;
        this.spin = 20;
        // the pad starts 65 degrees round the moon's right: it reaches the top in 3.2 s
        this.padLocal = -65 - this.moonA;
        this.padState = 0;
        this.padS = 1;
        this.squash = 0;
        this.popT = 9;
        this.shake = 0;
        this.bOn = false;
        this.demoPlanned = false;
        for (let i = 0; i < FX; i++) {
            this.fOn[i] = false;
            api.hide(this.flag[i]);
            api.hide(this.debris[i]);
        }
        this.fNext = 0;
        api.reset(this.lander);
    }

    padWorld(): f64 {
        return wrap180(this.moonA + this.padLocal);
    }

    // The moon's surface height at x (the top of the ball).
    groundAt(x: f64): f64 {
        let h = R * R - x * x;
        return h > 0 ? CY + Math.sqrt(h) : CY;
    }

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.best = 0;   // the visitor's best is their own, not the demo's
            this.held = false;
            this.newRun(api, api.demo ? MODE_FLY : MODE_READY);
        }
        this.t += dt;

        // the moon turns; the pad rides on it (sinking and rising when it moves)
        this.moonA += this.spin * dt;
        if (this.padState == 1) {
            this.padT += dt;
            this.padS = Math.max(0, 1 - this.padT / 0.35);
            if (this.padT >= 0.45) {
                // up again round the far side: the moon brings it back in 3.5 to 6 s
                let ahead = api.range(70, 110);
                let world = this.spin > 0 ? -ahead : ahead;
                this.padLocal = world - this.moonA;
                this.padState = 2;
                this.padT = 0;
            }
        } else if (this.padState == 2) {
            this.padT += dt;
            let u = Math.min(1, this.padT / 0.3);
            this.padS = u < 1 ? u * 1.25 : 1.0;   // a pop: overshoots then settles
            if (this.padT > 0.45) {
                this.padState = 0;
                this.padS = 1;
            }
        }

        // a pad that went by without a landing sinks and comes up ahead again
        if (this.padState == 0 && (this.spin > 0 ? this.padWorld() > 50 : this.padWorld() < -50)) {
            this.padState = 1;
            this.padT = 0;
            this.demoPlanned = false;
        }

        let input = api.demo ? this.demoInput(api) : (this.held && api.pointerDown);

        if (this.mode == MODE_READY) {
            // waiting for the first press: hover and bob, the moon turning below
            this.ly = START_Y + 0.12 * Math.sin(api.time * 2.2);
            this.vy = 0;
            this.thrusting = Math.sin(api.time * 2.2) < 0.2;
        } else if (this.mode == MODE_FLY || this.mode == MODE_LIFT) {
            this.fly(api, dt, input);
        } else if (this.mode == MODE_LANDED) {
            this.thrusting = false;
            let w = this.padWorld();
            let rr = R + PAD_TOP * this.padS;
            this.lx = -rr * Math.sin(w * Math.PI / 180);
            this.ly = CY + rr * Math.cos(w * Math.PI / 180);
            this.roll = w;
            if (this.t > 1.25) {
                // lift off by itself, the pad sinks away and comes up elsewhere
                this.mode = MODE_LIFT;
                this.t = 0;
                this.vy = 1.6;
                this.padState = 1;
                this.padT = 0;
                this.spin = (this.spin > 0 ? 1 : -1) * Math.min(38, Math.abs(this.spin) + 2.5);
                if (this.landings % 3 == 2) {
                    this.spin = -this.spin;   // every third landing the moon turns the other way
                }
                this.demoPlanned = false;
            }
        } else if (this.mode == MODE_OVER) {
            this.thrusting = false;
            if (api.demo && this.t > 2.0) {
                this.newRun(api, MODE_FLY);
            }
        }

        if (this.thrusting) {
            this.thrustT += dt;
        } else {
            this.thrustT = 0;
        }
        this.updateDust(api, dt);
        this.updateDebris(api, dt);
        this.squash = Math.max(0, this.squash - dt * 4);
        this.popT += dt;

        // camera shake, stepped at 15 fps (whole art pixels: the camera snaps)
        this.shake = Math.max(0, this.shake - dt * 0.9);
        if (Math.floor(api.time * 15) != Math.floor((api.time - dt) * 15)) {
            this.shakeX = (api.rand() - 0.5) * this.shake;
            this.shakeY = (api.rand() - 0.5) * this.shake;
        }
        api.eyeX = this.shakeX;
        api.targetX = this.shakeX;
        api.eyeY = CAM_Y + this.shakeY;
        api.targetY = CAM_Y + this.shakeY;

        this.draw(api);
    }

    fly(api: GameApi, dt: f64, input: bool): void {
        if (this.mode == MODE_LIFT) {
            // the take-off: a steady climb back to the middle, the flame lit
            this.thrusting = true;
            this.vy = 1.6;
            this.ly += this.vy * dt;
            this.lx += (0 - this.lx) * Math.min(1, dt * 2.2);
            this.roll += (0 - this.roll) * Math.min(1, dt * 4);
            if (this.t > 1.0) {
                this.mode = MODE_FLY;
                this.t = 0;
            }
            return;
        }
        this.thrusting = input && this.fuel > 0;
        let acc = (this.thrusting ? THRUST : 0) - GRAV;
        this.vy = clamp(this.vy + acc * dt, -6, 3);
        this.ly += this.vy * dt;
        if (this.ly > CEIL) {
            this.ly = CEIL;
            this.vy = Math.min(this.vy, 0);
        }
        if (this.thrusting) {
            this.fuel = Math.max(0, this.fuel - 19 * dt);
        }
        this.lx += (0 - this.lx) * Math.min(1, dt * 2.2);
        this.roll += (0 - this.roll) * Math.min(1, dt * 4);

        // touchdown: on the pad (soft and centred: a landing) or anywhere else (a crash)
        let w = this.padWorld();
        let rr = R + PAD_TOP * this.padS;
        let px = -rr * Math.sin(w * Math.PI / 180);
        let off = px - this.lx;
        let ground = this.groundAt(this.lx);
        let onPad = this.padState == 0 && Math.abs(off) < PAD_HALF && Math.abs(w) < 60;
        if (onPad) {
            ground = Math.max(ground, CY + rr * Math.cos(w * Math.PI / 180) - Math.abs(off) * 0.12);
        }
        if (this.ly <= ground) {
            this.ly = ground;
            if (onPad && Math.abs(off) < PAD_OK && this.vy > -SAFE) {
                this.land(api, off);
            } else {
                this.reason = !onPad ? "MISSED THE PAD" : (this.vy <= -SAFE ? "TOO FAST" : "OFF THE PAD");
                this.crash(api);
            }
        }
    }

    land(api: GameApi, off: f64): void {
        this.mode = MODE_LANDED;
        this.t = 0;
        this.landings++;
        let soft = clamp((SAFE + this.vy) / SAFE, 0, 1);       // 1: a feather, 0: at the limit
        let centre = clamp(1 - Math.abs(off) / PAD_OK, 0, 1);
        let pts = 100 + <i32>Math.round(soft * 60) + <i32>Math.round(centre * 40);
        this.score += pts;
        if (this.score > this.best) {
            this.best = this.score;
        }
        this.lastLandScore = pts;
        this.fuel = Math.min(100, this.fuel + 28 + soft * 14);
        this.squash = 1 + (1 - soft) * 0.6;
        this.shake = (1 - soft) * 0.25;
        this.vy = 0;
        this.popText = "+" + pts.toString();
        this.popText2 = soft > 0.75 ? "FEATHER!" : (centre > 0.75 ? "BULLSEYE!" : (soft < 0.3 ? "BUMPY" : "NICE"));
        this.popT = 0;
        this.popX = 0;
        this.popY = 3.7;
        // a flag goes up beside the pad (it turns with the moon)
        let k = this.fNext;
        this.fNext = (this.fNext + 1) % FX;
        this.fLocal[k] = this.padLocal + (this.spin > 0 ? 17 : -17);
        this.fOn[k] = true;
        this.fPop[k] = 0;
        this.puff(api, this.lx - 0.9, this.ly - PAD_TOP, -1.6);
        this.puff(api, this.lx + 0.9, this.ly - PAD_TOP, 1.6);
    }

    crash(api: GameApi): void {
        this.mode = MODE_OVER;
        this.t = 0;
        this.thrusting = false;
        this.shake = 0.6;
        if (this.score > this.best) {
            this.best = this.score;
        }
        this.bOn = true;
        for (let i = 0; i < FX; i++) {
            this.bX[i] = this.lx + api.range(-0.6, 0.6);
            this.bY[i] = this.ly + api.range(0.3, 1.4);
            this.bVX[i] = api.range(-3.2, 3.2);
            this.bVY[i] = api.range(2.0, 5.0);
            this.bR[i] = api.range(0, 360);
            this.bVR[i] = api.range(-500, 500);
        }
        for (let i = 0; i < 3; i++) {
            this.puff(api, this.lx + api.range(-0.8, 0.8), this.ly, api.range(-2.0, 2.0));
        }
    }

    puff(api: GameApi, x: f64, y: f64, vx: f64): void {
        let k = this.dNext;
        this.dNext = (this.dNext + 1) % FX;
        this.dX[k] = x;
        this.dY[k] = y;
        this.dVX[k] = vx;
        this.dT[k] = 0;
        this.dLife[k] = api.range(0.5, 0.8);
    }

    updateDust(api: GameApi, dt: f64): void {
        // the jet kicks up dust when it is near the ground
        let ground = this.groundAt(this.lx);
        let w = this.padWorld();
        let px = -R * Math.sin(w * Math.PI / 180);
        if (this.padState == 0 && Math.abs(px - this.lx) < PAD_HALF && Math.abs(w) < 60) {
            ground = Math.max(ground, CY + (R + PAD_TOP) * Math.cos(w * Math.PI / 180));
        }
        let h = this.ly - ground;
        this.dTimer -= dt;
        if (this.thrusting && h < 2.6 && this.mode != MODE_READY && this.dTimer <= 0) {
            this.dTimer = 0.09 + h * 0.03;
            let side = api.rand() < 0.5 ? -1.0 : 1.0;
            this.puff(api, this.lx + side * api.range(0.2, 0.6), ground + 0.05, side * api.range(1.6, 2.8) * (1.4 - h * 0.3));
        }
        for (let i = 0; i < FX; i++) {
            let b = this.dust[i];
            if (this.dT[i] >= this.dLife[i]) {
                api.hide(b);
                continue;
            }
            this.dT[i] += dt;
            this.dX[i] += this.dVX[i] * dt;
            this.dVX[i] *= Math.exp(-dt * 2.5);
            this.dY[i] += 0.35 * dt;
            let u = this.dT[i] / this.dLife[i];
            let s = u < 0.3 ? 0.5 + u * 2.5 : 1.25 * (1 - (u - 0.3) / 0.7) + 0.15;
            // stepped growth (12 fps) reads hand-animated
            s = Math.floor(s * 6) / 6;
            if (s < 0.15) {
                api.hide(b);
                continue;
            }
            api.place(b, this.dX[i], this.dY[i], 0.3, 0, 0, 0, s);
        }
    }

    updateDebris(api: GameApi, dt: f64): void {
        if (!this.bOn) {
            for (let i = 0; i < FX; i++) {
                api.hide(this.debris[i]);
            }
            return;
        }
        for (let i = 0; i < FX; i++) {
            this.bVY[i] -= 4.0 * dt;
            this.bX[i] += this.bVX[i] * dt;
            this.bY[i] += this.bVY[i] * dt;
            this.bR[i] += this.bVR[i] * dt;
            let g = this.groundAt(this.bX[i]) + 0.12;
            if (this.bY[i] < g) {
                this.bY[i] = g;
                this.bVY[i] = -this.bVY[i] * 0.35;
                this.bVX[i] *= 0.6;
                this.bVR[i] *= 0.5;
            }
            let s = this.t > 2.2 ? Math.max(0, 1 - (this.t - 2.2) * 2) : 1;
            if (s <= 0) {
                api.hide(this.debris[i]);
            } else {
                api.place(this.debris[i], this.bX[i], this.bY[i], 0.2 + i * 0.05, this.bR[i] * 0.7, this.bR[i], 0, s);
            }
        }
    }

    // The demo pilot: hover until the pad is about to come under, then descend to meet it at a gentle
    // speed. Each approach gets a timing error: small most of the time, now and then a big one.
    demoInput(api: GameApi): bool {
        if (this.mode != MODE_FLY) {
            return false;
        }
        let w = this.padWorld();
        let toTop = this.spin > 0 ? -w : w;               // degrees the pad still has to travel
        let tArrive = toTop / Math.abs(this.spin);
        if (!this.demoPlanned && this.padState == 0) {
            this.demoPlanned = true;
            let r = api.rand();
            this.demoErr = r < 0.18 ? (api.rand() < 0.5 ? -1.0 : 1.0) * api.range(0.75, 1.1) : api.range(-0.18, 0.18);
        }
        let yT: f64;
        if (this.padState != 0 || tArrive < -0.4) {
            yT = 2.2;
        } else {
            yT = PAD_TOP - 0.4 + Math.max(0, tArrive + this.demoErr - 0.1) * 0.95;
            yT = Math.min(yT, 3.2);
        }
        let near = this.ly - PAD_TOP < 1.2;
        let want = clamp((yT - this.ly) * 1.8, near ? -0.95 : -1.7, 1.3);
        // hysteresis: a pilot pulses the throttle
        if (this.vy < want - 0.08) {
            this.demoThrust = true;
        } else if (this.vy > want + 0.08) {
            this.demoThrust = false;
        }
        return this.demoThrust;
    }

    draw(api: GameApi): void {
        // the moon, the pad on it, the flags
        pose(api, this.moon, 0, CY, 0, 0, 0, this.moonA, 1, 1, 1);
        let w = this.padWorld();
        if (this.padS <= 0.15) {
            api.hide(this.pad);
        } else {
            let rr = R - 0.02;
            pose(api, this.pad, -rr * Math.sin(w * Math.PI / 180), CY + rr * Math.cos(w * Math.PI / 180), 0, 0, 0, w,
                 1 + (1 - this.padS) * 0.2, this.padS, 1);
        }
        for (let i = 0; i < FX; i++) {
            if (!this.fOn[i]) {
                api.hide(this.flag[i]);
                continue;
            }
            this.fPop[i] += api.dt;
            let fa = wrap180(this.moonA + this.fLocal[i]);
            let s = Math.min(1, this.fPop[i] / 0.25);
            if (s < 0.15) {
                api.hide(this.flag[i]);
                continue;
            }
            let rr = R - 0.05;
            pose(api, this.flag[i], -rr * Math.sin(fa * Math.PI / 180), CY + rr * Math.cos(fa * Math.PI / 180), 0.6,
                 0, 0, fa, 1, s < 1 ? s * 1.2 : 1, 1);
        }

        // the lander: squash on touchdown, a stretch as the flame lights
        if (this.mode == MODE_OVER) {
            api.hide(this.lander);
            api.hide(this.flame);
            return;
        }
        let sq = this.squash > 0 ? Math.sin(Math.min(1, this.squash) * Math.PI) * 0.16 * Math.max(1, this.squash) : 0;
        let st = this.thrusting && this.thrustT < 0.2 ? Math.sin(this.thrustT / 0.2 * Math.PI) * 0.06 : 0;
        let sy = 1 - sq + st;
        let sx = 1 + sq * 0.6 - st * 0.5;
        pose(api, this.lander, this.lx, this.ly, 0, 0, 0, this.roll, sx, sy, sx);
        if (this.thrusting) {
            // the flame flickers at 12 fps; it grows over its first fifth of a second
            let k = Math.floor(api.time * 12);
            let fl = 0.75 + 0.35 * (((k * 7919) % 5) / 4.0);
            let grow = Math.min(1, this.thrustT / 0.15 + 0.3);
            let r = this.roll * Math.PI / 180;
            let ox = -Math.sin(r) * 0.17 * sy, oy = Math.cos(r) * 0.17 * sy;
            pose(api, this.flame, this.lx + ox, this.ly + oy, 0, 0, 0, this.roll, 0.9 + fl * 0.15, fl * grow, 0.9 + fl * 0.15);
        } else {
            api.hide(this.flame);
        }
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            this.held = true;
            if (this.mode == MODE_READY) {
                this.newRun(api, MODE_FLY);
                this.vy = 0.3;
            } else if (this.mode == MODE_OVER && this.t > 0.6) {
                this.newRun(api, MODE_FLY);
                this.vy = 0.3;
            }
        } else if (kind == POINTER_UP) {
            this.held = false;
        }
        return true;
    }

    hud(api: GameApi): void {
        let cream = api.paletteColor(3);
        let tan = api.paletteColor(4);
        let rose = api.paletteColor(5);
        let dusk = api.paletteColor(7);
        let navy = api.paletteColor(1);
        let ink = api.paletteColor(0);
        let W = <f32>api.hudW;

        api.text(4, 4, "SCORE " + this.score.toString(), cream, 1, navy);
        let bs = "BEST " + this.best.toString();
        api.text(W - 4 - api.textWidth(bs, 1), 4, bs, tan, 1, navy);

        // fuel: a bar under the score, blinking when low
        api.text(4, 12, "FUEL", tan, 1, navy);
        api.rect(21, 12, 42, 5, navy);
        let f = <f32>Math.round(this.fuel / 100 * 40);
        let low = this.fuel < 25;
        if (!low || Math.floor(api.time * 4) % 2 == 0) {
            api.rect(22, 13, f, 3, low ? rose : cream);
        }

        if (this.mode == MODE_READY) {
            api.textCentered(<f32>api.hudH - 22, "HOLD TO THRUST", cream, 1, navy);
            api.textCentered(<f32>api.hudH - 14, "LAND SOFTLY ON THE PAD", tan, 1, navy);
        }
        if (api.demo) {
            api.textCentered(4, "DEMO", dusk, 1, navy);
        }

        // the descent speed beside the lander when it is low: cream is safe, rose too fast
        if (this.mode == MODE_FLY && this.vy < -0.2 && this.ly < 3.0) {
            if (api.project(<f32>this.lx, <f32>(this.ly + 1.0), 0)) {
                let v = <i32>Math.round(-this.vy * 10);
                let s = (v / 10).toString() + "." + (v % 10).toString();
                api.text(api.screenX + 19, api.screenY - 2, s, -this.vy < SAFE ? cream : rose, 1, navy);
            }
        }

        // where the pad comes from, while it is out of sight round the moon
        let w = this.padWorld();
        let px = -R * Math.sin(w * Math.PI / 180), py = CY + R * Math.cos(w * Math.PI / 180);
        if (this.mode != MODE_OVER && this.padState != 1 && api.project(<f32>px, <f32>py, 0)) {
            if (api.screenY > <f32>api.hudH - 6 || api.screenX < 2 || api.screenX > W - 2) {
                if (Math.floor(api.time * 3) % 3 != 0) {
                    if (px > 0) {
                        api.text(W - 24, <f32>api.hudH - 9, "PAD >", tan, 1, navy);
                    } else {
                        api.text(4, <f32>api.hudH - 9, "< PAD", tan, 1, navy);
                    }
                }
            }
        }

        // the landing's score rises from the lander
        if (this.popT < 1.3) {
            if (api.project(<f32>this.popX, <f32>(this.popY + this.popT * 0.8), 0)) {
                let x = api.screenX - api.textWidth(this.popText, 2) * 0.5;
                api.text(x, api.screenY, this.popText, cream, 2, navy);
                let x2 = api.screenX - api.textWidth(this.popText2, 1) * 0.5;
                api.text(x2, api.screenY + 12, this.popText2, tan, 1, navy);
            }
        }

        if (this.mode == MODE_OVER) {
            let y = <f32>32;
            api.textCentered(y, "CRASHED!", rose, 2, navy);
            api.textCentered(y + 14, this.reason, tan, 1, navy);
            api.textCentered(y + 24, "SCORE " + this.score.toString() + "  LANDINGS " + this.landings.toString(), cream, 1, navy);
            if (!api.demo && this.t > 0.6) {
                api.textCentered(y + 34, "CLICK TO FLY AGAIN", tan, 1, navy);
            }
        }
    }
}
