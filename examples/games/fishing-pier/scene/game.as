// Fishing Pier: hold to sink the hook, release to reel it in. A fish that touches the hook bites;
// reel it out of the water to score it (deeper fish are worth more). A jellyfish on the hook snaps the
// line: three lines a day. The day lasts 60 seconds (the sun sets as the clock). One verb, one world.
// Demo mode (api.demo) fishes by itself like a patient angler, with the odd jellyfish.
import { GameApi, POINTER_DOWN, POINTER_UP, SFX_BELL, SFX_BLIP, SFX_CLICK, SFX_COIN, SFX_LOSE, SFX_POWERUP, SFX_SPLASH, SFX_THUD,
    SFX_TICK, SFX_WHOOSH, SFX_WIN, SFX_ZAP } from "./game_api";

const HANDS_X: f64 = -4.02;   // the rod's pivot (the fisher's hands) and its tip offset at rest
const HANDS_Y: f64 = 1.85;
const TIP_DX: f64 = 2.663;
const TIP_DY: f64 = 0.865;
const REST_Y: f64 = 1.3;      // the lure dangling above the water
const BOTTOM: f64 = -5.0;
const SINK: f64 = 2.5;        // m/s
const REEL: f64 = 3.3;
const DAY: f64 = 60;
const LINES: i32 = 3;
const NF: i32 = 9;            // fish: 4 small, 3 middling, 2 big
const NJ: i32 = 3;
const NSP: i32 = 5;
const NB: i32 = 6;            // bubbles
const EDGE: f64 = 8.2;        // fish come in and leave beyond this |x|

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

export class Game {
    fisher: i32 = -1;
    rod: i32 = -1;
    lure: i32 = -1;
    waves: i32 = -1;
    swell: i32 = -1;
    sun: i32 = -1;
    cloud: StaticArray<i32> = new StaticArray<i32>(2);
    fish: StaticArray<i32> = new StaticArray<i32>(NF);
    jelly: StaticArray<i32> = new StaticArray<i32>(NJ);
    drop: StaticArray<i32> = new StaticArray<i32>(NSP);
    bub: StaticArray<i32> = new StaticArray<i32>(NB);
    bX: StaticArray<f64> = new StaticArray<f64>(NB);
    bY: StaticArray<f64> = new StaticArray<f64>(NB);
    bT: StaticArray<f64> = new StaticArray<f64>(NB);
    bNext: i32 = 0;
    bTimer: f64 = 0;

    mode: i32 = READY;
    t: f64 = 0;
    clock: f64 = DAY;
    score: i32 = 0;
    best: i32 = 0;
    lines: i32 = LINES;
    caught: i32 = 0;
    held: bool = false;
    needPress: bool = false;  // after a snap the hook waits for a fresh press
    endText: string = "";

    hookY: f64 = REST_Y;
    hookX: f64 = 0;
    snapT: f64 = 9;           // seconds since the line snapped (the lure is gone for a moment)
    hooked: i32 = -1;         // the fish on the hook
    bend: f64 = 0;            // the rod's bend, degrees (negative: the tip down)
    bounce: f64 = 0;          // the fisher's hop after a catch
    flinch: f64 = 0;

    // fish: kind 0 small (shallow), 1 middling, 2 big (deep)
    fKind: StaticArray<i32> = new StaticArray<i32>(NF);
    fOn: StaticArray<bool> = new StaticArray<bool>(NF);
    fX: StaticArray<f64> = new StaticArray<f64>(NF);
    fY: StaticArray<f64> = new StaticArray<f64>(NF);
    fV: StaticArray<f64> = new StaticArray<f64>(NF);
    fWait: StaticArray<f64> = new StaticArray<f64>(NF);
    fFly: StaticArray<f64> = new StaticArray<f64>(NF);   // >= 0: flying to the basket after a catch
    fFX: StaticArray<f64> = new StaticArray<f64>(NF);
    fFY: StaticArray<f64> = new StaticArray<f64>(NF);
    fFlee: StaticArray<bool> = new StaticArray<bool>(NF);

    jX: StaticArray<f64> = new StaticArray<f64>(NJ);
    jY: StaticArray<f64> = new StaticArray<f64>(NJ);
    jV: StaticArray<f64> = new StaticArray<f64>(NJ);
    jPh: StaticArray<f64> = new StaticArray<f64>(NJ);
    jZap: StaticArray<f64> = new StaticArray<f64>(NJ);

    dX: StaticArray<f64> = new StaticArray<f64>(NSP);
    dY: StaticArray<f64> = new StaticArray<f64>(NSP);
    dVX: StaticArray<f64> = new StaticArray<f64>(NSP);
    dVY: StaticArray<f64> = new StaticArray<f64>(NSP);
    dT: StaticArray<f64> = new StaticArray<f64>(NSP);
    dNext: i32 = 0;

    popText: string = "";
    popT: f64 = 9;
    popX: f64 = 0;
    popY: f64 = 0;
    wasUnder: bool = false;

    wasDemo: bool = false;
    dTarget: i32 = -1;
    dDepth: f64 = 0;
    dHold: bool = false;
    dThink: f64 = 0;
    dCareless: bool = false;

    // sound only (never read by the game): fish landed since the last snap, the clock's last second
    streak: i32 = 0;
    lastSec: i32 = 99;
    lastHookY: f64 = REST_Y;

    start(api: GameApi): void {
        api.playable = true;
        this.fisher = api.bone("fisher");
        this.rod = api.bone("rod");
        this.lure = api.bone("lure");
        this.waves = api.bone("waves");
        this.swell = api.bone("swell");
        this.sun = api.bone("sun");
        this.cloud[0] = api.bone("cloud0");
        this.cloud[1] = api.bone("cloud1");
        for (let i = 0; i < NF; i++) {
            let kind = i < 4 ? 0 : (i < 7 ? 1 : 2);
            let name = kind == 0 ? "fs" + i.toString() : (kind == 1 ? "fm" + (i - 4).toString() : "fl" + (i - 7).toString());
            this.fish[i] = api.bone(name);
            this.fKind[i] = kind;
            this.fFly[i] = -1;
            this.spawnFish(api, i, true);
        }
        for (let i = 0; i < NJ; i++) {
            this.jelly[i] = api.bone("jelly" + i.toString());
            this.jX[i] = -3 + i * 3.6 + api.range(-0.5, 0.5);
            this.jY[i] = -1.6 - i * 1.15 + api.range(-0.3, 0.3);
            this.jV[i] = (api.rand() < 0.5 ? -1 : 1) * api.range(0.25, 0.45);
            this.jPh[i] = api.range(0, 6.28);
            this.jZap[i] = 9;
        }
        for (let i = 0; i < NSP; i++) {
            this.drop[i] = api.bone("splash" + i.toString());
            this.dT[i] = 9;
        }
        for (let i = 0; i < NB; i++) {
            this.bub[i] = api.bone("bubble" + i.toString());
            this.bY[i] = 1;
            this.bT[i] = 0;
        }
        this.wasDemo = api.demo;
        this.newRun(api, api.demo ? RUN : READY);
    }

    newRun(api: GameApi, mode: i32): void {
        this.mode = mode;
        this.t = 0;
        this.clock = DAY;
        this.score = 0;
        this.lines = LINES;
        this.caught = 0;
        this.hookY = REST_Y;
        this.snapT = 9;
        this.hooked = -1;
        this.popT = 9;
        this.dTarget = -1;
        this.dHold = false;
        this.streak = 0;
        this.lastSec = 99;
        if (mode == RUN) {
            this.castSound(api);
        }
        for (let i = 0; i < NF; i++) {
            if (this.fFly[i] >= 0 || this.fFlee[i]) {
                this.fFly[i] = -1;
                this.spawnFish(api, i, false);
            }
        }
    }

    // A fish comes in from one side at its kind's depth band, after a short wait (or already in view).
    spawnFish(api: GameApi, i: i32, inView: bool): void {
        let k = this.fKind[i];
        let dir = api.rand() < 0.5 ? -1.0 : 1.0;
        this.fOn[i] = true;
        this.fFlee[i] = false;
        this.fFly[i] = -1;
        this.fY[i] = k == 0 ? api.range(-0.7, -1.7) : (k == 1 ? api.range(-2.0, -3.2) : api.range(-3.6, -4.7));
        let sp = k == 0 ? api.range(1.3, 1.9) : (k == 1 ? api.range(1.0, 1.4) : api.range(0.7, 1.0));
        this.fV[i] = sp * dir;
        this.fX[i] = inView ? api.range(-6, 6) : -dir * EDGE;
        this.fWait[i] = inView ? 0 : api.range(0.3, 2.5);
    }

    // a run starts: the line whips out, a calm bell
    castSound(api: GameApi): void {
        api.sound(SFX_WHOOSH, 1.25, 0.6, -0.4);
        api.note(67, 0.5, -0.2, SFX_BELL);
        api.note(74, 0.4, -0.2, SFX_BELL);
    }

    tipX(): f64 {
        let r = this.bend * Math.PI / 180;
        return HANDS_X + TIP_DX * Math.cos(r) - TIP_DY * Math.sin(r);
    }

    tipY(): f64 {
        let r = this.bend * Math.PI / 180;
        return HANDS_Y + TIP_DX * Math.sin(r) + TIP_DY * Math.cos(r);
    }

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.best = 0;   // the visitor's best is their own, not the demo's
            this.held = false;
            this.newRun(api, api.demo ? RUN : READY);
        }
        this.t += dt;
        this.snapT += dt;
        this.popT += dt;
        this.bounce = Math.max(0, this.bounce - dt * 2.5);
        this.flinch = Math.max(0, this.flinch - dt * 2);

        let input = false;
        if (this.mode == RUN) {
            this.clock -= dt;
            // the last ten seconds of the day tick, higher for the last three
            let sec = <i32>Math.ceil(this.clock);
            if (sec != this.lastSec && sec <= 10 && sec > 0) {
                api.sound(SFX_TICK, sec <= 3 ? 1.4 : 0.9, 0.65);
            }
            this.lastSec = sec;
            if (this.clock <= 0) {
                this.clock = 0;
                this.endRun("THE SUN HAS SET");
                api.sound(SFX_WIN, 0.8, 0.7);
            }
            input = api.demo ? this.demoInput(api, dt) : (this.held && api.pointerDown && !this.needPress);
        } else if (this.mode == OVER && api.demo && this.t > 2.0) {
            this.newRun(api, RUN);
        }

        // the hook: sinks while held, reels up when released (the lure is gone a moment after a snap)
        this.hookX = this.tipX();
        if (this.snapT < 0.8) {
            this.hookY = REST_Y;
        } else if (this.mode == RUN && input) {
            this.hookY = Math.max(BOTTOM, this.hookY - SINK * dt);
        } else {
            this.hookY = Math.min(REST_Y, this.hookY + REEL * (this.hooked >= 0 ? 0.85 : 1) * dt);
        }
        // the reel: a ratchet click every 5 frames while it winds in (slower and lower with a fish on),
        // a soft tick every 12 frames while the line pays out, lower as it goes deeper
        if (this.mode == RUN && this.snapT >= 0.8) {
            if (this.hookY > this.lastHookY + 0.001 && api.frame % (this.hooked >= 0 ? 7 : 5) == 0) {
                api.sound(SFX_CLICK, this.hooked >= 0 ? 0.45 : 0.65, 0.45, -0.5);
            } else if (this.hookY < this.lastHookY - 0.001 && api.frame % 12 == 0) {
                api.sound(SFX_TICK, 0.75 + 0.06 * this.hookY, 0.45, -0.3);
            }
        }
        this.lastHookY = this.hookY;
        let under = this.hookY < -0.05;
        if (under != this.wasUnder) {
            // a plop going in, a lighter splash coming out
            api.soundAt(SFX_SPLASH, this.hookX, 0, 0.3, under ? 0.7 : 1.15, under ? 0.6 : 0.45);
            this.splash(api, this.hookX, 0.05, 4);
            this.wasUnder = under;
        }

        this.updateFish(api, dt);
        this.updateJellies(api, dt);
        this.updateDrops(api, dt);
        this.updateBubbles(api, dt);

        // the rod bends with a fish on, and a little while the hook sinks
        let want = this.hooked >= 0 ? -7 + Math.sin(api.time * 18) * 2.5 : (input ? -2.5 : 0);
        this.bend += (want - this.bend) * Math.min(1, dt * 10);
        this.draw(api);
    }

    endRun(why: string): void {
        this.mode = OVER;
        this.t = 0;
        this.endText = why;
        if (this.score > this.best) this.best = this.score;
        if (this.hooked >= 0) {
            this.fFlee[this.hooked] = true;
            this.hooked = -1;
        }
    }

    updateFish(api: GameApi, dt: f64): void {
        for (let i = 0; i < NF; i++) {
            if (this.fFly[i] >= 0) {
                // a caught fish flies over the rail into the basket
                this.fFly[i] += dt;
                if (this.fFly[i] > 0.7) {
                    // into the basket
                    api.soundAt(SFX_THUD, -5.4, 1.2, 0.6, this.fKind[i] == 2 ? 0.8 : 1.1, 0.5);
                    this.spawnFish(api, i, false);
                }
                continue;
            }
            if (i == this.hooked) {
                this.fX[i] = this.hookX;
                this.fY[i] = this.hookY - 0.42;
                if (this.hookY >= REST_Y - 0.6 && this.mode == RUN) {
                    this.land(api, i);
                }
                continue;
            }
            if (this.fWait[i] > 0) {
                this.fWait[i] -= dt;
                continue;
            }
            let v = this.fFlee[i] ? this.fV[i] * 2.6 : this.fV[i];
            this.fX[i] += v * dt;
            if (Math.abs(this.fX[i]) > EDGE + 0.2) {
                this.spawnFish(api, i, false);
                continue;
            }
            // a bite: the hook in the water, free, touching the fish
            let half = this.fKind[i] == 2 ? 0.6 : (this.fKind[i] == 1 ? 0.45 : 0.35);
            if (this.mode == RUN && this.hooked < 0 && !this.fFlee[i] && this.snapT > 0.8 && this.hookY < -0.2 &&
                Math.abs(this.fX[i] - this.hookX) < half && Math.abs(this.fY[i] - (this.hookY - 0.3)) < 0.32) {
                this.hooked = i;
                this.splash(api, this.hookX, this.hookY - 0.3, 2);
                // a bite: a tug, lower for a bigger fish
                let kp = this.fKind[i] == 0 ? 1.3 : (this.fKind[i] == 1 ? 1.0 : 0.7);
                api.soundAt(SFX_BLIP, this.hookX, this.hookY, 0.3, 0.5 * kp, 0.7);
                api.soundAt(SFX_BLIP, this.hookX, this.hookY, 0.3, 0.75 * kp, 0.5);
            }
        }
    }

    land(api: GameApi, i: i32): void {
        let k = this.fKind[i];
        let pts = k == 0 ? 10 : (k == 1 ? 25 : 60);
        this.score += pts;
        this.caught++;
        if (this.score > this.best) this.best = this.score;
        this.hooked = -1;
        this.fFly[i] = 0;
        this.fFX[i] = this.fX[i];
        this.fFY[i] = this.fY[i];
        this.bounce = 1;
        this.popText = "+" + pts.toString();
        this.popT = 0;
        this.popX = this.hookX;
        this.popY = REST_Y + 0.4;
        this.splash(api, this.hookX, REST_Y - 0.3, 2);
        // landed: a pickup, deeper fish lower and richer, climbing a whole tone per fish since the last snap
        let up = Math.pow(2.0, <f64>(2 * min<i32>(this.streak, 6)) / 12.0);
        this.streak++;
        if (k == 2) {
            api.sound(SFX_POWERUP, 0.9 * up, 0.6, -0.3);
        } else {
            api.sound(SFX_COIN, (k == 0 ? 1.0 : 0.84) * up, 0.65, -0.3);
        }
    }

    updateJellies(api: GameApi, dt: f64): void {
        for (let i = 0; i < NJ; i++) {
            this.jZap[i] += dt;
            this.jX[i] += this.jV[i] * dt;
            if (Math.abs(this.jX[i]) > EDGE) {
                this.jV[i] = -this.jV[i];
                this.jX[i] = clamp(this.jX[i], -EDGE, EDGE);
            }
            // a jelly bobs: each pulse pushes it up, it sinks back between pulses
            this.jPh[i] += dt * 2.4;
            this.jY[i] += (Math.sin(this.jPh[i]) > 0.6 ? 0.55 : -0.17) * dt;
            if (this.jY[i] > -1.0) this.jY[i] = -1.0;
            if (this.jY[i] < -4.7) this.jY[i] = -4.7;
            // the hook in a jellyfish snaps the line
            if (this.mode == RUN && this.snapT > 0.8 && this.hookY < -0.2 &&
                Math.abs(this.jX[i] - this.hookX) < 0.42 && Math.abs(this.jY[i] - (this.hookY - 0.3)) < 0.5) {
                this.snap(api, i);
            }
        }
    }

    snap(api: GameApi, j: i32): void {
        this.jZap[j] = 0;
        this.lines--;
        this.snapT = 0;
        this.needPress = true;
        this.flinch = 1;
        this.splash(api, this.hookX, this.hookY, 4);
        if (this.hooked >= 0) {
            this.fFlee[this.hooked] = true;
            this.hooked = -1;
        }
        this.hookY = REST_Y;
        this.wasUnder = false;
        this.popText = "SNAP!";
        // a sting and the line whipping loose; lower with each line lost
        this.streak = 0;
        api.soundAt(SFX_ZAP, this.jX[j], this.jY[j], 0.4, 0.6 + 0.2 * <f64>this.lines, 0.8);
        api.sound(SFX_WHOOSH, 1.6, 0.5, -0.4);
        this.popT = 0;
        this.popX = this.jX[j];
        this.popY = this.jY[j] + 0.6;
        if (this.lines <= 0) {
            this.endRun("OUT OF LINE");
            api.sound(SFX_LOSE, 0.9, 0.8);
        }
    }

    splash(api: GameApi, x: f64, y: f64, n: i32): void {
        for (let k = 0; k < n; k++) {
            let i = this.dNext;
            this.dNext = (this.dNext + 1) % NSP;
            this.dX[i] = x + api.range(-0.15, 0.15);
            this.dY[i] = y;
            this.dVX[i] = api.range(-1.6, 1.6);
            this.dVY[i] = api.range(1.8, 3.4);
            this.dT[i] = 0;
        }
    }

    updateDrops(api: GameApi, dt: f64): void {
        for (let i = 0; i < NSP; i++) {
            if (this.dT[i] > 0.7) {
                api.hide(this.drop[i]);
                continue;
            }
            this.dT[i] += dt;
            this.dVY[i] -= 9 * dt;
            this.dX[i] += this.dVX[i] * dt;
            this.dY[i] += this.dVY[i] * dt;
            api.place(this.drop[i], this.dX[i], this.dY[i], 0.9, 0, 0, 0, 1);
        }
    }

    // Bubbles rise from two vents in the sand and from the lure while it is under; they wobble up in
    // stepped jiggles and pop at the surface.
    updateBubbles(api: GameApi, dt: f64): void {
        this.bTimer -= dt;
        if (this.bTimer <= 0) {
            this.bTimer = api.range(0.35, 0.7);
            let i = this.bNext;
            this.bNext = (this.bNext + 1) % NB;
            let r = api.rand();
            if (r < 0.3 && this.hookY < -0.4 && this.snapT > 0.8) {
                this.bX[i] = this.hookX; this.bY[i] = this.hookY - 0.2;
            } else {
                this.bX[i] = r < 0.65 ? 2.8 : 5.6; this.bY[i] = -5.3;
            }
            this.bT[i] = 0;
        }
        for (let i = 0; i < NB; i++) {
            if (this.bY[i] > -0.15) {
                api.hide(this.bub[i]);
                continue;
            }
            this.bT[i] += dt;
            this.bY[i] += 1.1 * dt;
            let jig = Math.floor(this.bT[i] * 5) % 2 == 0 ? 0.05 : -0.05;
            api.place(this.bub[i], this.bX[i] + jig, this.bY[i], 0.7, 0, 0, 0, 1);
        }
    }

    // The demo angler: picks a fish it can reach before the fish crosses the line (bigger ones
    // first), sinks to its depth at the right moment, hovers there in short taps, reels when it bites.
    // It mostly steers clear of jellyfish; now and then it does not look.
    demoInput(api: GameApi, dt: f64): bool {
        if (this.hooked >= 0 || this.snapT < 0.8) {
            this.dTarget = -1;
            return false;
        }
        this.dThink -= dt;
        if (this.dTarget >= 0) {
            let i = this.dTarget;
            let ahead = (this.hookX - this.fX[i]) * (this.fV[i] > 0 ? 1 : -1);
            if (!this.fOn[i] || this.fFly[i] >= 0 || this.fFlee[i] || this.fWait[i] > 0 || ahead < -0.9) {
                this.dTarget = -1;
            }
        }
        if (this.dTarget < 0 && this.dThink <= 0) {
            this.dThink = 0.25;
            this.dCareless = api.rand() < 0.15;
            let best = -1, bestV = 0.0;
            for (let i = 0; i < NF; i++) {
                if (this.fFly[i] >= 0 || this.fFlee[i] || this.fWait[i] > 0) continue;
                let tCross = (this.hookX - this.fX[i]) / this.fV[i];
                if (tCross < 0.2) continue;
                let depth = this.fY[i] + 0.3;
                let tSink = Math.max(0, (this.hookY - depth) / SINK);
                if (tCross < tSink - 0.3) continue;
                let k = this.fKind[i];
                let val = (k == 0 ? 10.0 : (k == 1 ? 25.0 : 60.0)) / (1 + Math.max(0, tCross - tSink) * 0.6);
                if (!this.dCareless && this.jellyNear(depth, tCross + 0.5)) continue;
                if (val > bestV) {
                    bestV = val;
                    best = i;
                }
            }
            if (best >= 0) {
                this.dTarget = best;
                this.dDepth = this.fY[best] + 0.3 + api.range(-0.18, 0.18);
            }
        }
        if (this.dTarget < 0) {
            // an eager first cast: the hook goes in at once when a run starts
            return this.t < 1.0;
        }
        let i = this.dTarget;
        let tCross = (this.hookX - this.fX[i]) / this.fV[i];
        let tSink = Math.max(0, (this.hookY - this.dDepth) / SINK);
        if (this.hookY > this.dDepth + 0.08) {
            // start down when the fish will arrive about when the hook does
            if (tCross <= tSink + 0.6 || (this.t < 1.0 && this.hookY > 0)) this.dHold = true;
            else this.dHold = false;
        } else {
            // hover around the depth: tap
            this.dHold = this.hookY > this.dDepth - 0.05 ? (Math.floor(api.time * 10) % 2 == 0) : false;
        }
        return this.dHold;
    }

    // Will a jellyfish be near the hook's line between the surface and this depth in the next t seconds?
    jellyNear(depth: f64, t: f64): bool {
        for (let j = 0; j < NJ; j++) {
            let x0 = this.jX[j], x1 = this.jX[j] + this.jV[j] * t;
            let lo = Math.min(x0, x1) - 0.7, hi = Math.max(x0, x1) + 0.7;
            if (this.hookX > lo && this.hookX < hi && this.jY[j] > depth - 0.7) return true;
        }
        return false;
    }

    draw(api: GameApi): void {
        // the waves slide (stepped at 12 fps), the swell behind slower the other way
        let k12 = Math.floor(api.time * 12) / 12;
        pose(api, this.waves, -((k12 * 0.55) % 1.25), 0, 1.4, 0, 0, 0, 1, 1, 1);
        pose(api, this.swell, (k12 * 0.3) % 1.6, -0.04, -3.0, 0, 0, 0, 1, 1, 1);
        // the sun is the clock: it sinks behind the sea as the day runs out
        let day = this.mode == READY ? 1.0 : clamp(this.clock / DAY, 0, 1);
        pose(api, this.sun, 1.6 + (1 - day) * 1.6, -0.9 + day * 2.8, -9.0, 0, 0, 0, 1, 1, 1);
        for (let c = 0; c < 2; c++) {
            let x = ((api.time * (0.12 + c * 0.07) + c * 9.0) % 18.0) - 9.0;
            pose(api, this.cloud[c], Math.round(x / 0.068) * 0.068, 2.5 - c * 0.45, -8.0 - c, 0, 0, 0, 1 - c * 0.25, 1 - c * 0.25, 1);
        }

        // the fisher breathes (stepped), hops after a catch, flinches at a snap
        let breathe = Math.floor(api.time * 2) % 2 == 0 ? 1.0 : 0.97;
        let hop = Math.sin(Math.min(1, this.bounce) * Math.PI) * 0.18;
        let sq = this.bounce > 0.85 ? 0.9 : 1.0;
        let roll = this.flinch > 0 ? Math.sin(this.flinch * 30) * 6 * this.flinch : (this.hooked >= 0 ? -4 : 0);
        pose(api, this.fisher, -4.55, 0.9 + hop, 0.05, 65, 0, roll, 1.3 / sq * (2 - breathe), 1.3 * breathe * sq, 1.3 / sq * (2 - breathe));
        pose(api, this.rod, HANDS_X, HANDS_Y + hop, 0.3, 0, 0, this.bend, 1, 1, 1);
        if (this.snapT < 0.8) {
            api.hide(this.lure);
        } else {
            pose(api, this.lure, this.hookX, this.hookY, 0.3, 0, 0, 0, 1, 1, 1);
        }

        for (let i = 0; i < NF; i++) {
            let b = this.fish[i];
            if (this.fFly[i] >= 0) {
                let u = this.fFly[i] / 0.7;
                let x = this.fFX[i] + (-5.4 - this.fFX[i]) * u;
                let y = this.fFY[i] + (1.2 - this.fFY[i]) * u + Math.sin(u * Math.PI) * 1.4;
                let s = u > 0.75 ? 1 - (u - 0.75) * 3.6 : 1;
                pose(api, b, x, y, 0.6, 90, -90, u * 540, s, s, s);
                continue;
            }
            if (this.fWait[i] > 0) {
                api.hide(b);
                continue;
            }
            if (i == this.hooked) {
                // hanging head up, thrashing (stepped)
                let w = Math.floor(api.time * 10) % 2 == 0 ? 22.0 : -22.0;
                pose(api, b, this.fX[i], this.fY[i], 0.5, 90, -90, w, 1, 1, 1);
                continue;
            }
            let dir = this.fV[i] > 0 ? 90.0 : -90.0;
            let wig = Math.floor(api.time * 6 + i) % 2 == 0 ? 7.0 : -7.0;
            let bob = Math.sin(api.time * 1.7 + i) * 0.06;
            pose(api, b, this.fX[i], this.fY[i] + bob, 0.5, dir + wig, 0, 0, 1, 1, 1);
        }
        for (let j = 0; j < NJ; j++) {
            // the pulse: squash and stretch in three stepped poses; a zapped jelly flashes big
            let p = Math.sin(this.jPh[j]);
            let sy = p > 0.6 ? 0.8 : (p < -0.3 ? 1.12 : 1.0);
            let sx = 2 - sy;
            if (this.jZap[j] < 0.4) {
                let f = Math.floor(this.jZap[j] * 15) % 2 == 0 ? 1.35 : 1.0;
                sx *= f;
                sy *= f;
            }
            pose(api, this.jelly[j], this.jX[j], this.jY[j], 0.4, j * 40.0, 0, 0, sx, sy, sx);
        }
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            this.held = true;
            this.needPress = false;
            if (this.mode == READY) {
                this.mode = RUN;
                this.t = 0;
                this.castSound(api);
            } else if (this.mode == OVER && this.t > 0.7) {
                this.newRun(api, RUN);
            }
        } else if (kind == POINTER_UP) {
            this.held = false;
        }
        return true;
    }

    hud(api: GameApi): void {
        let plum = api.paletteColor(0);
        let berry = api.paletteColor(1);
        let rose = api.paletteColor(2);
        let gold = api.paletteColor(4);
        let cream = api.paletteColor(5);
        let W = <f32>api.hudW;
        let H = <f32>api.hudH;

        // the line: from the rod's tip to the lure
        if (this.snapT >= 0.8 && api.project(<f32>this.tipX(), <f32>(this.tipY() + Math.sin(this.bounce * 3.14) * 0.18), 0.3)) {
            let ax = api.screenX, ay = api.screenY;
            if (api.project(<f32>this.hookX, <f32>this.hookY, 0.3)) {
                api.line(ax, ay, api.screenX, api.screenY, plum);
            }
        }

        api.text(4, 4, "SCORE " + this.score.toString(), cream, 1, plum);
        let bs = "BEST " + this.best.toString();
        api.text(W - 4 - api.textWidth(bs, 1), 4, bs, gold, 1, plum);
        if (api.demo) {
            api.textCentered(11, "DEMO", berry, 1, plum);
        }
        if (this.mode != READY) {
            // lines left: little hooks; and the day's clock
            for (let i = 0; i < LINES; i++) {
                let x = W - 6 - <f32>(i * 6);
                let c = i < this.lines ? cream : berry;
                api.rect(x + 1, 12, 1, 4, plum);
                api.rect(x, 11, 1, 4, c);
                api.rect(x - 2, 14, 2, 1, c);
                api.rect(x - 2, 13, 1, 1, c);
            }
            // the day's clock, top middle (the sun sinks with it)
            let w = <f32>Math.round(this.clock / DAY * 40);
            let cx = Mathf.floor(W * 0.5) - 21;
            api.rect(cx, 4, 42, 4, plum);
            api.rect(cx + 1, 5, w, 2, this.clock < 10 ? rose : gold);
        }
        if (this.popT < 1.1 && api.project(<f32>this.popX, <f32>(this.popY + this.popT * 0.8), 0.5)) {
            let x = api.screenX - api.textWidth(this.popText, 2) * 0.5;
            api.text(x, api.screenY, this.popText, this.popText == "SNAP!" ? rose : cream, 2, plum);
        }
        if (this.mode == READY) {
            api.rect(0, H - 25, W, 20, plum);
            api.textCentered(H - 21, "HOLD TO SINK THE HOOK, RELEASE TO REEL", cream, 1, plum);
            api.textCentered(H - 13, "DEEP FISH SCORE MORE - MIND THE JELLYFISH", gold, 1, plum);
        }
        if (this.mode == OVER) {
            api.rect(0, 52, W, 44, plum);
            api.textCentered(56, this.endText, cream, 2, plum);
            api.textCentered(70, "SCORE " + this.score.toString() + "   FISH " + this.caught.toString(), gold, 1, plum);
            if (!api.demo && this.t > 0.7) {
                api.textCentered(82, "CLICK TO FISH AGAIN", rose, 1, plum);
            }
        }
    }
}
