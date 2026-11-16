// Lily Hop: a frog crosses a pond by hopping onto drifting lily pads. One verb: click to hop.
// Rows: 0 the near bank, 1..5 lanes of pads drifting left or right, 6 the far bank. Each hop that lands
// on a pad scores 1, each bank reached scores 5 more and turns the frog round; the lanes speed up.
// Missing a pad, or riding one into the reeds at the pond's sides, is a splash: game over.
import { GameApi, POINTER_DOWN } from "./game_api";

const LANES: i32 = 5;
const PER_LANE: i32 = 4;
const PADS: i32 = 20;
const HALF_LEN: f64 = 6.8;      // pads wrap at +-6.8 m, out of the frame
const EDGE: f64 = 5.3;          // a frog carried past this meets the reeds
const LAND_R: f64 = 0.6;        // a landing this close to a pad's centre sticks
const BANK_Y: f64 = 0.3;
const PAD_TOP: f64 = 0.05;
const CROUCH_T: f64 = 0.08;
const HOP_T: f64 = 0.34;
const HOP_H: f64 = 0.8;
const SINK_T: f64 = 0.7;

const READY: i32 = 0;   // on a bank before the first hop of a run
const CROUCH: i32 = 1;  // anticipation
const HOP: i32 = 2;
const SIT: i32 = 3;     // on a pad or a bank, mid-run
const SINK: i32 = 4;    // splash
const OVER: i32 = 5;

const LOTUS_AT: StaticArray<i32> = [1, 6, 9, 12, 15, 18];
const BASE_SPEED: StaticArray<f64> = [0.95, -1.25, 0.8, -1.45, 1.1];

function rowZ(r: i32): f64 {
    if (r <= 0) return 3.55;
    if (r >= 6) return -3.55;
    return 3.45 - 1.15 * <f64>r;
}

function wrapX(x: f64): f64 {
    let L = HALF_LEN * 2;
    let u = (x + HALF_LEN) % L;
    if (u < 0) u += L;
    return u - HALF_LEN;
}

function ease(t: f64): f64 {
    let u = Math.min(Math.max(t, 0), 1);
    return u * u * (3 - 2 * u);
}

// The fixed (or climbing) orthographic camera's target; the renderer snaps it to the art grid.
function aim(api: GameApi, tx: f64, ty: f64, tz: f64): void {
    api.useTarget = true;
    api.targetX = tx;
    api.targetY = ty;
    api.targetZ = tz;
}

export class Game {
    // bones
    frog: i32 = -1;
    padBone: StaticArray<i32> = new StaticArray<i32>(PADS);
    fly: i32 = -1;
    splash: i32 = -1;
    ripple: i32 = -1;
    // lanes and pads
    speed: StaticArray<f64> = new StaticArray<f64>(LANES);
    padX: StaticArray<f64> = new StaticArray<f64>(PADS);
    padYaw: StaticArray<f64> = new StaticArray<f64>(PADS);
    padSpin: StaticArray<f64> = new StaticArray<f64>(PADS);
    padPhase: StaticArray<f64> = new StaticArray<f64>(PADS);
    padHit: StaticArray<f64> = new StaticArray<f64>(PADS);
    speedMul: f64 = 1;
    // the frog
    state: i32 = READY;
    stateT: f64 = 0;
    row: i32 = 0;
    dir: i32 = 1;
    x: f64 = 0;
    y: f64 = BANK_Y;
    z: f64 = 3.55;
    yaw: f64 = 180;
    yawFrom: f64 = 180;
    turnT: f64 = 1;
    pad: i32 = -1;
    padOff: f64 = 0;
    hopX: f64 = 0;
    hopZ0: f64 = 0;
    hopZ1: f64 = 0;
    hopY0: f64 = 0;
    landT: f64 = 9;
    appearT: f64 = 0;
    // the run
    score: i32 = 0;
    best: i32 = 0;
    crossings: i32 = 0;
    overWhy: string = "";
    queued: bool = false;
    // the firefly
    flyLane: i32 = 3;
    flyX: f64 = 1.5;
    flyAlive: bool = true;
    flyT: f64 = 0;          // since caught (when not alive)
    // effects
    splashT: f64 = 9;
    splashX: f64 = 0;
    splashZ: f64 = 0;
    rippleT: f64 = 9;
    rippleX: f64 = 0;
    rippleZ: f64 = 0;
    rippleY: f64 = 0;
    shakeT: f64 = 9;
    popText: Array<string> = new Array<string>();
    popX: Array<f64> = new Array<f64>();
    popY: Array<f64> = new Array<f64>();
    popZ: Array<f64> = new Array<f64>();
    popT: Array<f64> = new Array<f64>();
    // demo
    wasDemo: bool = false;
    thinkT: f64 = 0;
    err: f64 = 0;
    wait: f64 = 0.2;

    start(api: GameApi): void {
        api.playable = true;
        this.frog = api.bone("frog");
        let plain = 0, lotus = 0;
        for (let i = 0; i < PADS; i++) {
            let isLotus = false;
            for (let k = 0; k < LOTUS_AT.length; k++) {
                if (LOTUS_AT[k] == i) isLotus = true;
            }
            this.padBone[i] = isLotus ? api.bone("lotus" + (lotus++).toString()) : api.bone("pad" + (plain++).toString());
            this.padYaw[i] = api.range(0, 360);
            this.padSpin[i] = api.range(-9, 9);
            this.padPhase[i] = api.range(0, 6.28);
            this.padHit[i] = 9;
        }
        // pads spread along each lane with a little jitter; lane 1's first pad drifts under the frog
        // within half a second, so a demo (and the showcase reel) hops at once
        for (let l = 0; l < LANES; l++) {
            let off = api.range(0, 3.4);
            if (l == 0) off = -BASE_SPEED[0] * 0.5;
            for (let k = 0; k < PER_LANE; k++) {
                let j = k == 0 && l == 0 ? 0 : api.range(-0.45, 0.45);
                this.padX[l * PER_LANE + k] = wrapX(off + <f64>k * (HALF_LEN * 2 / <f64>PER_LANE) + j);
            }
        }
        this.fly = api.bone("fly");
        this.splash = api.bone("splash");
        this.ripple = api.bone("ripple");
        this.wasDemo = api.demo;
        this.newRun(api);
        this.appearT = 9;
    }

    newRun(api: GameApi): void {
        this.popText.length = 0; this.popX.length = 0; this.popY.length = 0; this.popZ.length = 0; this.popT.length = 0;
        this.state = READY;
        this.stateT = 0;
        this.row = 0;
        this.dir = 1;
        this.x = 0;
        this.y = BANK_Y;
        this.z = rowZ(0);
        this.yaw = 180;
        this.turnT = 1;
        this.pad = -1;
        this.score = 0;
        this.crossings = 0;
        this.speedMul = 1;
        for (let l = 0; l < LANES; l++) this.speed[l] = BASE_SPEED[l];
        this.queued = false;
        this.appearT = 0;
        this.wait = 0.25;
        this.thinkT = 0;
    }

    // ------------------------------------------------------------------ play

    hop(api: GameApi): void {
        if (this.state != READY && this.state != SIT) {
            if (this.state == HOP || this.state == CROUCH) this.queued = true;
            return;
        }
        this.state = CROUCH;
        this.stateT = 0;
        this.queued = false;
    }

    takeOff(): void {
        this.state = HOP;
        this.stateT = 0;
        this.hopX = this.x;
        this.hopZ0 = this.z;
        this.hopY0 = this.y;
        this.hopZ1 = rowZ(this.row + this.dir);
        if (this.pad >= 0) this.padHit[this.pad] = 0; // the pad bobs as the frog leaves it
        this.pad = -1;
    }

    land(api: GameApi): void {
        let next = this.row + this.dir;
        this.row = next;
        this.landT = 0;
        if (next == 0 || next == 6) {
            this.y = BANK_Y;
            this.state = SIT;
            this.stateT = 0;
            this.crossings++;
            this.score += 5;
            this.pop(this.x, BANK_Y + 1.0, this.z, "+5 CROSSED!");
            this.dir = -this.dir;
            this.yawFrom = this.yaw;
            this.turnT = 0;
            this.speedMul = 1 + 0.13 * <f64>this.crossings;
            for (let l = 0; l < LANES; l++) this.speed[l] = BASE_SPEED[l] * this.speedMul;
            return;
        }
        let l = next - 1;
        let bestK = -1;
        let bestD = 99.0;
        for (let k = 0; k < PER_LANE; k++) {
            let i = l * PER_LANE + k;
            let d = Math.abs(this.padX[i] - this.x);
            if (d < bestD) { bestD = d; bestK = i; }
        }
        if (bestD < LAND_R) {
            this.pad = bestK;
            this.padOff = this.x - this.padX[bestK];
            this.padHit[bestK] = 0;
            this.state = SIT;
            this.stateT = 0;
            this.score += 1;
            this.pop(this.x, PAD_TOP + 0.9, this.z, "+1");
            this.rippleT = 0; this.rippleX = this.padX[bestK]; this.rippleZ = this.z; this.rippleY = 0.0;
            if (this.flyAlive && this.flyLane == next && Math.abs(this.flyPos(api.time) - this.x) < 0.95) {
                this.flyAlive = false;
                this.flyT = 0;
                this.score += 3;
                this.pop(this.x, PAD_TOP + 1.5, this.z, "+3 FIREFLY");
            }
        } else {
            this.splashDown("SPLASH!");
        }
    }

    splashDown(why: string): void {
        this.state = SINK;
        this.stateT = 0;
        this.pad = -1;
        this.overWhy = why;
        this.splashT = 0;
        this.splashX = this.x;
        this.splashZ = this.z;
        this.rippleT = 0; this.rippleX = this.x; this.rippleZ = this.z; this.rippleY = 0.0;
        this.shakeT = 0;
        if (this.score > this.best) this.best = this.score;
    }

    pop(x: f64, y: f64, z: f64, text: string): void {
        this.popText.push(text); this.popX.push(x); this.popY.push(y); this.popZ.push(z); this.popT.push(0);
    }

    flyPos(t: f64): f64 {
        return this.flyX + Math.sin(t * 0.8) * 0.7;
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        let t = api.time;
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.newRun(api); // demo on or off: a fresh run
        }
        // lanes drift
        for (let l = 0; l < LANES; l++) {
            for (let k = 0; k < PER_LANE; k++) {
                let i = l * PER_LANE + k;
                this.padX[i] = wrapX(this.padX[i] + this.speed[l] * dt);
                this.padYaw[i] += this.padSpin[i] * dt;
                this.padHit[i] += dt;
            }
        }
        this.stateT += dt;
        this.landT += dt;
        this.appearT += dt;
        this.turnT += dt;
        if (this.state == CROUCH) {
            if (this.pad >= 0) this.x = this.padX[this.pad] + this.padOff;
            if (this.stateT >= CROUCH_T) this.takeOff();
        } else if (this.state == HOP) {
            let u = Math.min(this.stateT / HOP_T, 1);
            this.z = this.hopZ0 + (this.hopZ1 - this.hopZ0) * u;
            let nextRow = this.row + this.dir;
            let y1 = nextRow == 0 || nextRow == 6 ? BANK_Y : PAD_TOP;
            this.y = this.hopY0 + (y1 - this.hopY0) * u + HOP_H * 4 * u * (1 - u);
            if (u >= 1) {
                this.y = y1;
                this.land(api);
            }
        } else if (this.state == SIT) {
            if (this.pad >= 0) {
                this.x = this.padX[this.pad] + this.padOff;
                if (Math.abs(this.x) > EDGE) this.splashDown("INTO THE REEDS!");
            }
            if (this.queued && this.stateT > 0.06) this.hop(api);
        } else if (this.state == SINK) {
            if (this.stateT > SINK_T) {
                this.state = OVER;
                this.stateT = 0;
            }
        }
        if (this.flyAlive == false) {
            this.flyT += dt;
            if (this.flyT > 2.6) {
                this.flyAlive = true;
                this.flyLane = 1 + <i32>Math.floor(api.range(0, 4.99));
                if (this.flyLane == this.row) this.flyLane = this.flyLane == 5 ? 4 : this.flyLane + 1;
                this.flyX = api.range(-3.2, 3.2);
            }
        }
        if (api.demo) this.playDemo(api);
        this.place(api, t);
        let shake = this.shakeT < 0.25 ? (Math.floor(this.shakeT * 30) % 2 == 0 ? 1.0 : -1.0) * 0.06 : 0.0;
        this.shakeT += dt;
        aim(api, shake, 0, -0.6);
        for (let i = this.popT.length - 1; i >= 0; i--) {
            this.popT[i] += dt;
            if (this.popT[i] > 0.9) {
                this.popT.splice(i, 1); this.popText.splice(i, 1); this.popX.splice(i, 1);
                this.popY.splice(i, 1); this.popZ.splice(i, 1);
            }
        }
    }

    // A plausible player: waits a beat after landing, judges the gap with some error (it grows as the
    // lanes speed up), hops when it believes a pad will be under it; nervous near the reeds.
    playDemo(api: GameApi): void {
        if (this.state == OVER) {
            if (this.stateT > 2.0) {
                this.newRun(api);
            }
            return;
        }
        if (this.state != READY && this.state != SIT) return;
        if (this.stateT < this.wait) return;
        this.thinkT -= api.dt;
        if (this.thinkT > 0) return;
        this.thinkT = 0.12;
        this.err = api.range(-1, 1) * (0.2 + 0.05 * <f64>this.crossings);
        let next = this.row + this.dir;
        if (next == 0 || next == 6) {
            this.hop(api);
            this.wait = api.range(0.15, 0.4);
            return;
        }
        let l = next - 1;
        let T = CROUCH_T + HOP_T;
        let xTake = this.x;
        if (this.pad >= 0) {
            let lc = this.row - 1;
            xTake += this.speed[lc] * CROUCH_T;
        }
        let bestD = 99.0;
        for (let k = 0; k < PER_LANE; k++) {
            let px = wrapX(this.padX[l * PER_LANE + k] + this.speed[l] * T);
            bestD = Math.min(bestD, Math.abs(px - xTake));
        }
        let nervous = this.pad >= 0 && Math.abs(this.x) > 4.0;
        if (bestD + this.err < 0.32 || (nervous && bestD < 0.75)) {
            this.hop(api);
            this.wait = api.range(0.12, 0.45);
        }
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind != POINTER_DOWN) return true;
        if (this.state == OVER) {
            if (this.stateT > 0.5) this.newRun(api);
            return true;
        }
        if (this.state == SINK) return true;
        this.hop(api);
        return true;
    }

    // ------------------------------------------------------------------ bones

    place(api: GameApi, t: f64): void {
        for (let i = 0; i < PADS; i++) {
            let h = this.padHit[i];
            let dip = h < 1.2 ? -0.07 * Math.exp(-5 * h) * Math.cos(16 * h) : 0.0;
            let bob = Math.sin(t * 1.7 + this.padPhase[i]) * 0.012;
            api.place(this.padBone[i], this.padX[i], bob + dip, rowZ(i / PER_LANE + 1), this.padYaw[i]);
        }
        // the frog: squash in the crouch, stretch on take-off, squash on landing, sink on a splash
        let fb = this.frog;
        let bobY = 0.0;
        if (this.pad >= 0) {
            let h = this.padHit[this.pad];
            bobY = (h < 1.2 ? -0.07 * Math.exp(-5 * h) * Math.cos(16 * h) : 0.0) + Math.sin(t * 1.7 + this.padPhase[this.pad]) * 0.012;
        }
        let targetYaw = this.dir > 0 ? 180.0 : 0.0;
        let yaw = this.turnT < 0.25 ? this.yawFrom + (targetYaw - this.yawFrom) * ease(this.turnT / 0.25) : targetYaw;
        this.yaw = yaw;
        let sx = 1.0, sy = 1.0;
        if (this.state == CROUCH) {
            let u = this.stateT / CROUCH_T;
            sy = 1 - 0.3 * u; sx = 1 + 0.16 * u;
        } else if (this.state == HOP) {
            let u = this.stateT / HOP_T;
            let s = Math.max(0, 1 - u * 2.2);
            sy = 1 + 0.32 * s; sx = 1 - 0.14 * s;
        } else if (this.landT < 0.2 && this.state == SIT) {
            let u = this.landT / 0.2;
            let s = Math.sin(u * Math.PI) * (1 - u * 0.5);
            sy = 1 - 0.3 * s; sx = 1 + 0.18 * s;
        } else if (this.state == READY || this.state == SIT) {
            // idle breathing, stepped at 6 fps so it reads hand-animated
            let k = Math.floor(t * 6) % 12;
            let b = k < 6 ? 0.0 : 0.04;
            sy = 1 - b; sx = 1 + b * 0.5;
        }
        if (this.appearT < 0.3) {
            let u = this.appearT / 0.3;
            let s = u < 0.6 ? u / 0.6 * 1.2 : 1.2 - 0.2 * (u - 0.6) / 0.4;
            sx *= s; sy *= s;
        }
        if (this.state == SINK) {
            let u = Math.min(this.stateT / 0.45, 1);
            api.placeScaled(fb, this.x, this.y - 0.7 * u, this.z, yaw, 1 + 0.2 * u, 1 - 0.5 * u, 1 + 0.2 * u);
            if (u >= 1) api.hide(fb);
        } else if (this.state == OVER) {
            api.hide(fb);
        } else {
            api.placeScaled(fb, this.x, this.y + bobY, this.z, yaw, sx, sy, sx);
        }
        // the firefly hovers over its lane, wings flapping (stepped), and pops when caught
        let flyB = this.fly;
        if (this.flyAlive) {
            let flap = Math.floor(t * 12) % 2 == 0 ? 1.0 : 0.6;
            api.placeScaled(flyB, this.flyPos(t), 0.85 + Math.sin(t * 3.1) * 0.1, rowZ(this.flyLane), Math.sin(t) * 30, flap, 1, 1);
        } else if (this.flyT < 0.25) {
            let s = 1 + this.flyT * 4;
            api.place(flyB, this.flyPos(t), 1.0 + this.flyT * 2, rowZ(this.flyLane), 0, 0, 0, s);
        } else {
            api.hide(flyB);
        }
        // splash crown and ripple
        this.splashT += api.dt;
        this.rippleT += api.dt;
        if (this.splashT < 0.6) {
            let u = this.splashT / 0.6;
            let s = 0.4 + 1.1 * Math.sqrt(u);
            api.placeScaled(this.splash, this.splashX, -0.25 * u * u, this.splashZ, 0, s, 1.5 * (1 - u) + 0.1, s);
        } else {
            api.hide(this.splash);
        }
        if (this.rippleT < 0.5) {
            let u = this.rippleT / 0.5;
            let s = 0.5 + 1.2 * u;
            api.placeScaled(this.ripple, this.rippleX, this.rippleY - 0.02 * u, this.rippleZ, 0, s, 1, s);
        } else {
            api.hide(this.ripple);
        }
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let ink = api.rampColor(0, 0);      // #1a1c2c
        let white = api.rampColor(4, 4);    // #f4f4f4
        let gold = api.rampColor(4, 3);     // #ffcd75
        let lime = api.rampColor(1, 3);     // #a7f070
        let w = <f32>api.hudW;
        let h = <f32>api.hudH;
        api.text(4, 4, "SCORE " + this.score.toString(), white, 2, ink);
        let b = "BEST " + this.best.toString();
        api.text(w - api.textWidth(b, 1) - 4, 5, b, gold, 1, ink);
        if (api.demo) {
            api.text(w - api.textWidth("DEMO", 1) - 4, 13, "DEMO", lime, 1, ink);
        }
        // score pops float up from where they happened
        for (let i = 0; i < this.popT.length; i++) {
            let u = this.popT[i];
            if (api.project(<f32>this.popX[i], <f32>(this.popY[i] + u * 0.6), <f32>this.popZ[i])) {
                let s = this.popText[i];
                let c = s.length > 2 ? gold : white;
                if (u < 0.75 || Math.floor(u * 20) % 2 == 0) {
                    let px = Mathf.min(Mathf.max(Mathf.round(api.screenX - api.textWidth(s, 1) * 0.5), 2), <f32>api.hudW - api.textWidth(s, 1) - 2);
                    api.text(px, Mathf.max(Mathf.round(api.screenY), 22), s, c, 1, ink);
                }
            }
        }
        if (this.state == READY && !api.demo) {
            let hint = "CLICK TO HOP - LAND ON THE LILY PADS";
            if (Math.floor(api.time * 2) % 4 != 3) api.textCentered(h - 9, hint, white, 1, ink);
        }
        if (this.state == OVER) {
            api.textCentered(38, this.overWhy, white, 3, ink);
            api.textCentered(60, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), gold, 1, ink);
            if (!api.demo && this.stateT > 0.5) api.textCentered(h - 9, "CLICK TO PLAY AGAIN", white, 1, ink);
        }
    }
}
