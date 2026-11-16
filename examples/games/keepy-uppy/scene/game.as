// Keepy Uppy: beach balls on a beach at sunset. Click a ball to kick it up; where you hit it steers it
// (hit its left side and it flies right). Every 9 seconds another ball drops in, up to four. None may
// touch the sand: the first one that lands ends the run. A kick scores one point for every ball in play.
//
// Everything is in this file (references/games.md, "The game hook"); the bones come from
// scene.bake.json: ball0..3, shadow0..3, puff0..7, spark0..5, crab.
import { GameApi, POINTER_DOWN } from "./game_api";

const NB: i32 = 4;
const NPF: i32 = 8;
const NS: i32 = 6;
const NP: i32 = 6;
const RB: f64 = 0.64;          // ball radius (0.4 baked at 1.6)
const GRAV: f64 = 6.0;         // floaty: a beach ball
const KICK: f64 = 7.6;
const WALL: f64 = 5.7;
const CEIL: f64 = 6.6;
const JOIN: f64 = 9.0;         // seconds between new balls
const CRAB_Z: f64 = 2.2;

const M_READY: i32 = 0;
const M_PLAY: i32 = 1;
const M_OVER: i32 = 2;

function clamp(v: f64, a: f64, b: f64): f64 { return v < a ? a : (v > b ? b : v); }

export class Game {
    bBall: StaticArray<i32> = new StaticArray<i32>(NB);
    bShadow: StaticArray<i32> = new StaticArray<i32>(NB);
    bPuff: StaticArray<i32> = new StaticArray<i32>(NPF);
    bSpark: StaticArray<i32> = new StaticArray<i32>(NS);
    bCrab: i32 = -1;

    mode: i32 = M_READY;
    wasDemo: bool = false;
    score: i32 = 0;
    best: i32 = 0;
    kicks: i32 = 0;
    overT: f64 = 0;
    runT: f64 = 0;
    joinT: f64 = 0;
    warnT: f64 = -1;           // a new ball is announced (seconds until it drops)
    warnX: f64 = 0;
    landed: i32 = -1;

    // balls
    on: StaticArray<bool> = new StaticArray<bool>(NB);
    x: StaticArray<f64> = new StaticArray<f64>(NB);
    y: StaticArray<f64> = new StaticArray<f64>(NB);
    vx: StaticArray<f64> = new StaticArray<f64>(NB);
    vy: StaticArray<f64> = new StaticArray<f64>(NB);
    spin: StaticArray<f64> = new StaticArray<f64>(NB);     // degrees a second about the vertical
    yaw: StaticArray<f64> = new StaticArray<f64>(NB);
    kickT: StaticArray<f64> = new StaticArray<f64>(NB);    // since the last kick (squash, stretch)
    landT: StaticArray<f64> = new StaticArray<f64>(NB);    // since it hit the sand (game over squash)
    hopT: f64 = 0;

    // puffs and sparks
    fLife: StaticArray<f64> = new StaticArray<f64>(NPF);
    fX: StaticArray<f64> = new StaticArray<f64>(NPF);
    fY: StaticArray<f64> = new StaticArray<f64>(NPF);
    fZ: StaticArray<f64> = new StaticArray<f64>(NPF);
    fVX: StaticArray<f64> = new StaticArray<f64>(NPF);
    fVY: StaticArray<f64> = new StaticArray<f64>(NPF);
    fVZ: StaticArray<f64> = new StaticArray<f64>(NPF);
    nextPuff: i32 = 0;
    sLife: StaticArray<f64> = new StaticArray<f64>(NS);
    sX: StaticArray<f64> = new StaticArray<f64>(NS);
    sY: StaticArray<f64> = new StaticArray<f64>(NS);
    sVX: StaticArray<f64> = new StaticArray<f64>(NS);
    sVY: StaticArray<f64> = new StaticArray<f64>(NS);
    nextSpark: i32 = 0;

    // popups
    pOn: StaticArray<bool> = new StaticArray<bool>(NP);
    pX: StaticArray<f64> = new StaticArray<f64>(NP);
    pY: StaticArray<f64> = new StaticArray<f64>(NP);
    pAge: StaticArray<f64> = new StaticArray<f64>(NP);
    pKind: StaticArray<i32> = new StaticArray<i32>(NP);
    pText: Array<string> = ["", "", "", "", "", ""];
    nextPop: i32 = 0;

    // the crab
    crabX: f64 = -1.5;
    crabGoal: f64 = 1.5;
    crabWait: f64 = 1.0;
    crabRun: f64 = 0;

    // the demo player
    dCool: f64 = 0;
    dKickH: StaticArray<f64> = new StaticArray<f64>(NB);

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < NB; i++) {
            this.bBall[i] = api.bone("ball" + i.toString());
            this.bShadow[i] = api.bone("shadow" + i.toString());
        }
        for (let i = 0; i < NPF; i++) this.bPuff[i] = api.bone("puff" + i.toString());
        for (let i = 0; i < NS; i++) this.bSpark[i] = api.bone("spark" + i.toString());
        this.bCrab = api.bone("crab");
        this.wasDemo = api.demo;
        this.reset(api);
    }

    reset(api: GameApi): void {
        this.score = 0;
        this.kicks = 0;
        this.runT = 0;
        this.joinT = 0;
        this.warnT = -1;
        this.landed = -1;
        for (let i = 0; i < NB; i++) {
            this.on[i] = false;
            this.landT[i] = -1;
            this.kickT[i] = 9;
            this.spin[i] = 0;
            this.dKickH[i] = 2.0;
        }
        this.on[0] = true;
        this.x[0] = 0;
        this.vx[0] = 0;
        if (api.demo) {
            // the demo opens mid-rally: the ball on its way down, about to be kicked
            this.mode = M_PLAY;
            this.y[0] = 3.6;
            this.vy[0] = -1.5;
            this.x[0] = -0.8;
            this.vx[0] = 0.5;
            this.dCool = 0;
            this.dKickH[0] = 2.2;
        } else {
            this.mode = M_READY;
            this.y[0] = RB;
            this.vy[0] = 0;
            this.hopT = 0;
        }
    }

    // ------------------------------------------------------------------ balls

    addBall(api: GameApi, x: f64): void {
        for (let i = 0; i < NB; i++) {
            if (this.on[i]) continue;
            this.on[i] = true;
            this.x[i] = x;
            this.y[i] = CEIL + 1.6;
            this.vx[i] = api.range(-0.6, 0.6);
            this.vy[i] = -0.5;
            this.spin[i] = api.range(-120, 120);
            this.kickT[i] = 9;
            this.landT[i] = -1;
            this.dKickH[i] = api.range(1.5, 2.6);
            return;
        }
    }

    count(): i32 {
        let n = 0;
        for (let i = 0; i < NB; i++) if (this.on[i]) n++;
        return n;
    }

    // a kick at world point (hx, hy) on ball i: up, and away from where it was hit
    kick(api: GameApi, i: i32, hx: f64, hy: f64): void {
        if (this.mode == M_READY) {
            this.mode = M_PLAY;
            this.runT = 0;
            this.joinT = 0;
        }
        let off = clamp((this.x[i] - hx) / RB, -1, 1);
        this.vy[i] = Math.max(this.vy[i], 0) * 0.25 + KICK;
        this.vx[i] = clamp(this.vx[i] * 0.4 + off * 3.2, -4.5, 4.5);
        this.spin[i] = this.spin[i] * 0.3 - off * 420;
        this.kickT[i] = 0;
        this.kicks += 1;
        let n = this.count();
        this.score += n;
        this.popup(this.x[i], this.y[i] + RB + 0.3, "+" + n.toString(), n > 1 ? 1 : 0);
        this.sparks(api, hx, hy);
    }

    updateBalls(api: GameApi, dt: f64): void {
        if (this.mode == M_PLAY) {
            this.joinT += dt;
            if (this.count() < NB) {
                if (this.warnT < 0 && this.joinT > JOIN - 1.2) {
                    this.warnT = 1.2;
                    // drop it where the others are not
                    let sum = 0.0;
                    for (let i = 0; i < NB; i++) if (this.on[i]) sum += this.x[i];
                    this.warnX = sum > 0 ? api.range(-4.2, -1.5) : api.range(1.5, 4.2);
                }
            } else {
                this.joinT = 0;
            }
            if (this.warnT >= 0) {
                this.warnT -= dt;
                if (this.warnT < 0) {
                    this.addBall(api, this.warnX);
                    this.joinT = 0;
                    this.popup(this.warnX, CEIL - 0.6, "NEW BALL!", 2);
                }
            }
        }
        for (let i = 0; i < NB; i++) {
            let b = this.bBall[i], sh = this.bShadow[i];
            if (!this.on[i]) { api.hide(b); api.hide(sh); continue; }
            this.kickT[i] += dt;
            if (this.mode == M_READY) {
                // waiting on the sand: a little hop now and then, asking to be kicked
                this.hopT += dt;
                if (this.hopT > 1.6) { this.hopT = 0; this.vy[i] = 2.6; this.kickT[i] = 0.15; }
            }
            if (this.landT[i] >= 0) {
                this.landT[i] += dt;
            } else {
                this.vy[i] -= GRAV * dt;
                this.x[i] += this.vx[i] * dt;
                this.y[i] += this.vy[i] * dt;
                this.yaw[i] += this.spin[i] * dt;
                this.spin[i] *= Math.exp(-dt * 0.4);
                this.vx[i] *= Math.exp(-dt * 0.15);
                if (this.x[i] > WALL) { this.x[i] = WALL; this.vx[i] = -Math.abs(this.vx[i]) * 0.8; }
                if (this.x[i] < -WALL) { this.x[i] = -WALL; this.vx[i] = Math.abs(this.vx[i]) * 0.8; }
                if (this.y[i] > CEIL && this.vy[i] > 0) { this.y[i] = CEIL; this.vy[i] = -this.vy[i] * 0.4; }
                if (this.y[i] <= RB) {
                    this.y[i] = RB;
                    if (this.mode == M_PLAY) {
                        this.land(api, i);
                    } else if (this.mode == M_OVER && Math.abs(this.vy[i]) > 1.2) {
                        this.vy[i] = -this.vy[i] * 0.45;
                        this.vx[i] *= 0.6;
                        this.puffs(api, this.x[i], 3);
                    } else {
                        this.vy[i] = 0;
                        this.vx[i] *= Math.exp(-dt * 4);
                    }
                }
            }
            // squash and stretch: a kick squashes then stretches, speed stretches, a landing flattens
            let sy = 1.0, sxz = 1.0;
            let k = this.kickT[i];
            if (k < 0.35) {
                let w = Math.exp(-k * 9) * Math.cos(k * 26);
                sy = 1 - 0.32 * w;
                sxz = 1 + 0.22 * w;
            } else {
                let sp = Math.min(Math.abs(this.vy[i]) / 10, 0.12);
                sy = 1 + sp; sxz = 1 - sp * 0.5;
            }
            let yy = this.y[i];
            if (this.landT[i] >= 0) {
                let u = this.landT[i];
                let w = Math.exp(-u * 4);
                sy = 1 - 0.45 * w * Math.abs(Math.cos(u * 10)) - 0.1;
                sxz = 1 + 0.35 * w + 0.05;
                yy = RB * sy;
            } else if (this.y[i] < RB + 0.15 && this.vy[i] <= 0 && this.mode != M_PLAY) {
                sy *= 0.85; sxz *= 1.1; yy = RB * 0.9;
            }
            api.placeScaled(b, this.x[i], yy, 0, this.yaw[i], sxz, sy, sxz);
            // the blob shadow shrinks with height
            let hgt = Math.max(0, this.y[i] - RB);
            let s = clamp(1.05 - hgt * 0.11, 0.35, 1.05);
            api.placeScaled(sh, this.x[i], 0.06, 0.15, 0, s, 1, s);
        }
    }

    land(api: GameApi, i: i32): void {
        this.mode = M_OVER;
        this.overT = 0;
        this.landed = i;
        this.landT[i] = 0;
        this.vy[i] = 0;
        this.vx[i] = 0;
        if (this.score > this.best) this.best = this.score;
        this.puffs(api, this.x[i], 8);
        this.popup(this.x[i], RB * 2 + 0.6, "THUD!", 3);
        this.warnT = -1;
    }

    // ------------------------------------------------------------------ puffs, sparks, popups

    puffs(api: GameApi, x: f64, n: i32): void {
        for (let k = 0; k < n; k++) {
            let p = this.nextPuff;
            this.nextPuff = (this.nextPuff + 1) % NPF;
            this.fLife[p] = 0.7;
            this.fX[p] = x + api.range(-0.4, 0.4);
            this.fY[p] = 0.1;
            this.fZ[p] = api.range(-0.3, 0.5);
            let a = api.range(0, Math.PI);
            let s = api.range(1.2, 2.6);
            this.fVX[p] = Math.cos(a) * s;
            this.fVY[p] = api.range(2.0, 4.0);
            this.fVZ[p] = api.range(-0.5, 1.0);
        }
    }

    sparks(api: GameApi, x: f64, y: f64): void {
        for (let k = 0; k < 4; k++) {
            let s = this.nextSpark;
            this.nextSpark = (this.nextSpark + 1) % NS;
            let a = Math.PI * (1.15 + 0.23 * <f64>k) + api.range(-0.15, 0.15);
            this.sLife[s] = 0.32;
            this.sX[s] = x; this.sY[s] = y;
            this.sVX[s] = Math.cos(a) * 5;
            this.sVY[s] = Math.sin(a) * 5;
        }
    }

    updateFx(api: GameApi, dt: f64): void {
        for (let p = 0; p < NPF; p++) {
            let b = this.bPuff[p];
            if (this.fLife[p] <= 0) { api.hide(b); continue; }
            this.fLife[p] -= dt;
            this.fVY[p] -= 9.8 * dt;
            this.fX[p] += this.fVX[p] * dt;
            this.fY[p] += this.fVY[p] * dt;
            this.fZ[p] += this.fVZ[p] * dt;
            if (this.fY[p] < 0.08) { this.fY[p] = 0.08; this.fVY[p] = 0; this.fVX[p] *= 0.5; }
            let s = this.fLife[p] < 0.25 ? this.fLife[p] / 0.25 : 1;
            if (s <= 0.05) { api.hide(b); continue; }
            api.place(b, this.fX[p], this.fY[p], this.fZ[p], 0, 0, 0, 0.6 + 0.8 * s);
        }
        for (let s = 0; s < NS; s++) {
            let b = this.bSpark[s];
            if (this.sLife[s] <= 0) { api.hide(b); continue; }
            this.sLife[s] -= dt;
            this.sX[s] += this.sVX[s] * dt;
            this.sY[s] += this.sVY[s] * dt;
            let k = this.sLife[s] / 0.32;
            api.place(b, this.sX[s], this.sY[s], 0.3, 0, 0, Math.floor(api.time * 12) * 45, 0.5 + 0.9 * k);
        }
    }

    popup(x: f64, y: f64, s: string, kind: i32): void {
        let p = this.nextPop;
        this.nextPop = (this.nextPop + 1) % NP;
        this.pOn[p] = true;
        this.pX[p] = x; this.pY[p] = y;
        this.pAge[p] = 0;
        this.pKind[p] = kind;
        this.pText[p] = s;
    }

    // ------------------------------------------------------------------ the crab

    updateCrab(api: GameApi, dt: f64): void {
        // it scuttles to a spot, waits, picks another; a landing ball nearby sends it running
        let speed = this.crabRun > 0 ? 3.2 : 1.1;
        this.crabRun = Math.max(0, this.crabRun - dt);
        let d = this.crabGoal - this.crabX;
        if (Math.abs(d) > 0.05) {
            this.crabX += Math.min(Math.abs(d), speed * dt) * (d > 0 ? 1 : -1);
        } else {
            this.crabWait -= dt;
            if (this.crabWait <= 0) {
                this.crabGoal = api.range(-4.5, 4.5);
                this.crabWait = api.range(0.8, 2.5);
            }
        }
        if (this.landed >= 0 && this.mode == M_OVER && this.overT < 0.1 && Math.abs(this.x[this.landed] - this.crabX) < 3) {
            this.crabGoal = this.x[this.landed] > this.crabX ? -5.5 : 5.5;
            this.crabRun = 1.5;
        }
        let moving = Math.abs(this.crabGoal - this.crabX) > 0.05;
        let step = Math.floor(api.time * (this.crabRun > 0 ? 16 : 10));
        let bob = moving ? 0.05 * (step % 2) : 0;
        let wig = moving ? 6 * (step % 2 == 0 ? 1 : -1) : 3 * Math.sin(Math.floor(api.time * 4) * 1.3);
        api.place(this.bCrab, this.crabX, bob, CRAB_Z, wig);
    }

    // ------------------------------------------------------------------ the demo player

    demoPlay(api: GameApi, dt: f64): void {
        if (this.mode == M_OVER) {
            if (this.overT > 2.0) this.reset(api);
            return;
        }
        this.dCool -= dt;
        if (this.dCool > 0) return;
        // the most urgent falling ball under its kick height
        let best = -1;
        let bestY = 1e9;
        for (let i = 0; i < NB; i++) {
            if (!this.on[i] || this.vy[i] > 0) continue;
            if (this.y[i] > this.dKickH[i]) continue;
            if (this.y[i] < bestY) { bestY = this.y[i]; best = i; }
        }
        if (best < 0) return;
        // aim at the side away from the middle, to send it back in; a hand that shakes a little
        let side = this.x[best] > 0 ? 1.0 : -1.0;
        let e = (api.rand() + api.rand() + api.rand() - 1.5) * 0.55 * RB;
        let hx = this.x[best] + side * 0.3 * RB + e;
        let hy = this.y[best] + (api.rand() - 0.5) * 0.6 * RB;
        let dx = hx - this.x[best], dy = hy - this.y[best];
        if (dx * dx + dy * dy <= (RB + 0.12) * (RB + 0.12)) {
            this.kick(api, best, hx, hy);
        } else {
            this.popup(hx, hy + 0.5, "WHIFF", 0);
        }
        this.dKickH[best] = api.rand() < 0.07 ? 0.75 : api.range(1.3, 2.7);
        this.dCool = api.range(0.2, 0.34);
    }

    // ------------------------------------------------------------------ frame

    update(api: GameApi): void {
        let dt = api.dt;
        if (this.wasDemo != api.demo) {
            this.wasDemo = api.demo;
            this.reset(api);
        }
        if (this.mode == M_OVER) this.overT += dt;
        if (this.mode == M_PLAY) this.runT += dt;
        if (api.demo) this.demoPlay(api, dt);
        this.updateBalls(api, dt);
        this.updateFx(api, dt);
        this.updateCrab(api, dt);
        for (let p = 0; p < NP; p++) {
            if (this.pOn[p]) {
                this.pAge[p] += dt;
                if (this.pAge[p] > 1.0) this.pOn[p] = false;
            }
        }
    }

    pointer(api: GameApi, kind: i32, px: f32, py: f32): bool {
        if (kind != POINTER_DOWN) return true;
        if (this.mode == M_OVER) {
            if (this.overT > 0.6) this.reset(api);
            return true;
        }
        // the ball under the pointer (the lowest one if several), with a little slack
        let hit = -1;
        let hitY = 1e9;
        let wx = 0.0, wy = 0.0;
        for (let i = 0; i < NB; i++) {
            if (!this.on[i]) continue;
            if (!api.project(<f32>this.x[i], <f32>this.y[i], 0)) continue;
            let cx = api.screenX, cy = api.screenY;
            api.project(<f32>(this.x[i] + RB), <f32>this.y[i], 0);
            let r = api.screenX - cx;
            let dx = px - cx, dy = py - cy;
            if (dx * dx + dy * dy <= (r + 3) * (r + 3) && this.y[i] < hitY) {
                hit = i;
                hitY = this.y[i];
                let k = <f64>RB / <f64>r;
                wx = this.x[i] + <f64>dx * k;
                wy = this.y[i] - <f64>dy * k;
            }
        }
        if (hit >= 0) {
            this.kick(api, hit, wx, wy);
        } else if (this.mode == M_READY) {
            // the first click anywhere starts: the ball is kicked straight up
            this.kick(api, 0, this.x[0], RB);
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let white = api.rampColor(2, 3);
        let ink = api.rampColor(12, 0);
        let gold = api.rampColor(7, 2);
        let pink = api.rampColor(10, 4);
        let red = api.rampColor(5, 2);
        let lilac = api.rampColor(6, 1);
        let W = <f32>api.hudW, H = <f32>api.hudH;

        api.text(4, 4, "SCORE " + this.score.toString(), white, 1, ink);
        api.text(4, 11, "BEST " + this.best.toString(), gold, 1, ink);

        // balls in play (top right): a little ball each, empty rings for the ones still to come
        let n = this.count();
        for (let i = 0; i < NB; i++) {
            let x = W - 9 - <f32>(NB - 1 - i) * 8;
            if (i < n) {
                api.rect(x + 1, 4, 4, 6, ink);
                api.rect(x, 5, 6, 4, ink);
                api.rect(x + 1, 3, 4, 6, red);
                api.rect(x, 4, 6, 4, red);
                api.rect(x + 2, 3, 2, 6, white);
            } else {
                api.rect(x + 1, 3, 4, 1, lilac); api.rect(x + 1, 8, 4, 1, lilac);
                api.rect(x, 4, 1, 4, lilac); api.rect(x + 5, 4, 1, 4, lilac);
            }
        }

        // a new ball is coming: an arrow at the top where it will drop, blinking
        if (this.warnT >= 0 && Math.floor(this.warnT * 8) % 2 == 0) {
            if (api.project(<f32>this.warnX, <f32>CEIL, 0)) {
                let sx = Mathf.round(api.screenX);
                api.rect(sx - 3, 2, 7, 1, ink);
                api.rect(sx - 3, 1, 7, 2, gold);
                api.rect(sx - 2, 3, 5, 1, gold);
                api.rect(sx - 1, 4, 3, 1, gold);
                api.rect(sx, 5, 1, 1, gold);
            }
        }

        for (let p = 0; p < NP; p++) {
            if (!this.pOn[p]) continue;
            let age = this.pAge[p];
            if (age > 0.75 && Math.floor(age * 12) % 2 == 0) continue;
            if (api.project(<f32>this.pX[p], <f32>(this.pY[p] + age * 1.0), 0)) {
                let s = this.pText[p];
                let k = this.pKind[p];
                let c = k == 3 ? red : (k == 2 ? gold : (k == 1 ? pink : white));
                let sc = k == 3 ? 2 : 1;
                let tw = api.textWidth(s, sc);
                api.text(Mathf.round(api.screenX - tw * 0.5), Mathf.round(api.screenY), s, c, sc, ink);
            }
        }

        if (this.mode == M_OVER) {
            let y = Mathf.floor(H * 0.3);
            api.rect(0, y - 4, W, 34, ink);
            let ks = this.kicks.toString() + (this.kicks == 1 ? " KICK" : " KICKS");
            api.textCentered(y, "A BALL HIT THE SAND - " + ks, pink, 1, 0);
            api.textCentered(y + 9, "SCORE " + this.score.toString(), white, 2, 0);
            if (!api.demo && this.overT > 0.6) api.textCentered(y + 22, "CLICK TO PLAY AGAIN", gold, 1, 0);
        } else if (this.mode == M_READY && !api.demo) {
            api.rect(0, H - 13, W, 9, ink);
            api.textCentered(H - 11, "CLICK THE BALL TO KICK IT UP - NONE MAY LAND!", white, 1, 0);
        } else if (!api.demo && this.runT < 3) {
            api.rect(0, H - 13, W, 9, ink);
            api.textCentered(H - 11, "MORE BALLS ARE COMING...", white, 1, 0);
        }
    }
}
