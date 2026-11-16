// Tightrope: a walker crosses a canyon on a rope, back and forth, while gusts blow down the gorge.
// He leans and would fall; the pointer pulls him towards it: when he tips right, move the pointer to
// his left. Lean too far (43 degrees) and he falls into the
// river. Score: metres walked, +10 for each crossing; the gusts grow with every crossing.
//
// Game bones from scene.bake.json: the walker and his pole (attached to his hands with
// api.transform), the rope's two spans (stretched from each anchor to his feet, so the rope sags under
// him), two pennants, 8 wind streaks, a splash and a hawk. Deterministic: api.rand() only.
import { GameApi, POINTER_DOWN } from "./game_api";

const R_ROCK: i32 = 0;    // plum, red-brown, rust, ochre, cream
const R_COOL: i32 = 1;    // plum, slate, teal-grey, sage, cream

const ANCHOR: f64 = 6.9;      // the rope runs from x -6.9 to 6.9 at y 0
const DECK: f64 = 7.45;       // where the walker stands on each platform
const SAG: f64 = 0.32;        // how far the rope dips under him at mid-span
const RIVER_Y: f64 = -7.5;
const FALL_AT: f64 = 0.75;    // radians of lean
const G: f64 = 2.2;           // the topple (an inverted pendulum)
const DAMP: f64 = 1.1;
const PULL: f64 = 3.8;        // what the pointer can do
const WALK: f64 = 0.85;       // metres a second

const IDLE: i32 = 0;
const PLAY: i32 = 1;
const OVER: i32 = 2;

// the walker
const W_STAND: i32 = 0;     // on a platform (turning, cheering)
const W_ROPE: i32 = 1;
const W_FALL: i32 = 2;
const W_GONE: i32 = 3;

const NS: i32 = 8;

export class Game {
    body: i32 = -1;
    pole: i32 = -1;
    ropeA: i32 = -1;
    ropeB: i32 = -1;
    flagA: i32 = -1;
    flagB: i32 = -1;
    splash: i32 = -1;
    bird: i32 = -1;
    sBone: StaticArray<i32> = new StaticArray<i32>(NS);
    sX: StaticArray<f64> = new StaticArray<f64>(NS);
    sY: StaticArray<f64> = new StaticArray<f64>(NS);
    sZ: StaticArray<f64> = new StaticArray<f64>(NS);
    sV: StaticArray<f64> = new StaticArray<f64>(NS);
    sLife: StaticArray<f64> = new StaticArray<f64>(NS);
    sNext: i32 = 0;
    streakIn: f64 = 0;

    mode: i32 = IDLE;
    wasDemo: bool = false;
    score: i32 = 0;
    best: i32 = 0;
    bestDemo: i32 = 0;
    crossings: i32 = 0;
    metres: f64 = 0;
    runTime: f64 = 0;
    overTime: f64 = 0;

    // the walker's state
    ws: i32 = W_STAND;
    wt: f64 = 0;            // seconds in this state
    x: f64 = -DECK;
    dir: f64 = 1;           // +1 walks away from the camera (+X), -1 back
    yaw: f64 = 90;
    lean: f64 = 0;          // radians, + = leaning to the screen's right
    leanV: f64 = 0;
    u: f64 = 0;             // the pull, -1..1
    stepT: f64 = 0;
    arrived: bool = false;  // on the far platform: cheer, then turn round
    fallX: f64 = 0;
    fallY: f64 = 0;
    fallZ: f64 = 0;
    fallVY: f64 = 0;
    fallVZ: f64 = 0;
    poleY: f64 = 0;
    poleVY: f64 = 0;
    poleZ: f64 = 0;
    splashT: f64 = 9;
    splashX: f64 = 0;
    splashZ: f64 = 0;
    popT: f64 = 9;          // "+10" over the platform

    // wind: a gust is announced (streaks, pennants) before it pushes
    gustIn: f64 = 2.5;
    gustWarn: f64 = 0;
    gustT: f64 = 0;
    gustLen: f64 = 0;
    gustDir: f64 = 1;
    gustPow: f64 = 0;
    gustNow: f64 = 0;       // the force this frame

    // the demo's hand
    dU: f64 = 0;
    dHist: StaticArray<f64> = new StaticArray<f64>(16);
    dHistV: StaticArray<f64> = new StaticArray<f64>(16);
    dHistAt: i32 = 0;
    dLapse: f64 = 0;
    dLapseIn: f64 = 3;
    walkerSX: f64 = 160;
    walkerSY: f64 = 120;

    start(api: GameApi): void {
        api.playable = true;
        this.body = api.bone("walker");
        this.pole = api.bone("pole");
        this.ropeA = api.bone("ropeA");
        this.ropeB = api.bone("ropeB");
        this.flagA = api.bone("flagA");
        this.flagB = api.bone("flagB");
        this.splash = api.bone("splash");
        this.bird = api.bone("bird");
        for (let i = 0; i < NS; i++) {
            this.sBone[i] = api.bone("streak" + i.toString());
            this.sLife[i] = 0;
            api.hide(this.sBone[i]);
        }
        api.hide(this.splash);
        this.wasDemo = api.demo;
        this.resetWalker();
        if (api.demo) {
            this.newRun(api);
            this.opening(api);
        }
    }

    // ------------------------------------------------------------------ runs

    private resetWalker(): void {
        this.ws = W_STAND;
        this.wt = 0;
        this.x = -DECK;
        this.dir = 1;
        this.yaw = 90;
        this.lean = 0;
        this.leanV = 0;
        this.u = 0;
        this.arrived = false;
    }

    private newRun(api: GameApi): void {
        this.mode = PLAY;
        this.score = 0;
        this.crossings = 0;
        this.metres = 0;
        this.runTime = 0;
        this.overTime = 0;
        this.gustIn = 2.2;
        this.gustLen = 0;
        this.gustT = 0;
        this.gustWarn = 0;
        if (this.ws != W_STAND && this.ws != W_ROPE) {
            this.resetWalker();
        }
        this.wt = 0;
        this.popT = 9;
    }

    // the demo starts on the rope, a gust already blowing
    private opening(api: GameApi): void {
        this.resetWalker();
        this.ws = W_ROPE;
        this.x = -3.2;
        this.lean = 0.12;
        this.gustIn = 0;
        this.gustWarn = 0.35;
        this.gustDir = 1;
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

    // ------------------------------------------------------------------ wind

    private updateWind(api: GameApi, dt: f64): void {
        this.gustNow = 0;
        if (this.mode != PLAY) {
            return;
        }
        let lvl = <f64>this.crossings;
        if (this.gustWarn > 0) {
            this.gustWarn -= dt;
            if (this.gustWarn <= 0) {
                this.gustT = 0;
            }
        } else if (this.gustT < this.gustLen) {
            this.gustT += dt;
            // the push swells and dies away
            let k = Math.sin(Math.min(1.0, this.gustT / this.gustLen) * Math.PI);
            this.gustNow = this.gustDir * this.gustPow * k;
            if (this.gustT >= this.gustLen) {
                this.gustIn = Math.max(1.2, api.range(2.4, 4.2) - lvl * 0.25);
            }
        } else if (this.ws == W_ROPE) {
            this.gustIn -= dt;
            if (this.gustIn <= 0) {
                this.gustWarn = 0.9;
                this.gustDir = api.rand() < 0.5 ? -1.0 : 1.0;
                this.gustPow = (1.6 + 0.55 * lvl) * api.range(0.75, 1.25);
                this.gustLen = api.range(1.0, 1.7) + lvl * 0.1;
                this.gustT = 0;
            }
        }
    }

    private windy(): bool {
        return this.gustWarn > 0 || (this.gustT < this.gustLen && this.mode == PLAY);
    }

    private updateStreaks(api: GameApi, dt: f64): void {
        if (this.windy()) {
            this.streakIn -= dt;
            if (this.streakIn <= 0) {
                this.streakIn = this.gustWarn > 0 ? 0.16 : 0.08;
                let i = this.sNext;
                this.sNext = (this.sNext + 1) % NS;
                this.sX[i] = this.x + api.range(-3.5, 4.5);
                this.sY[i] = api.range(-0.6, 2.8);
                this.sZ[i] = -this.gustDir * api.range(4.5, 6.5);
                this.sV[i] = this.gustDir * api.range(9, 13);
                this.sLife[i] = 1.2;
            }
        }
        for (let i = 0; i < NS; i++) {
            if (this.sLife[i] <= 0) {
                continue;
            }
            this.sLife[i] -= dt;
            this.sZ[i] += this.sV[i] * dt;
            if (this.sLife[i] <= 0) {
                api.hide(this.sBone[i]);
                continue;
            }
            api.place(this.sBone[i], this.sX[i], this.sY[i], Math.round(this.sZ[i] / 0.1) * 0.1, 0, 0, 0, 1);
        }
    }

    // ------------------------------------------------------------------ the walker

    private feetY(x: f64): f64 {
        if (Math.abs(x) >= ANCHOR) {
            return 0;
        }
        let f = x / ANCHOR;
        return -SAG * (1.0 - f * f);
    }

    private updateWalker(api: GameApi, dt: f64): void {
        this.wt += dt;
        if (this.ws == W_STAND) {
            // settle, cheer on arrival, turn round, step onto the rope
            this.leanV += (-this.lean * 30.0 - this.leanV * 8.0) * dt;
            this.lean += this.leanV * dt;
            if (this.mode == PLAY) {
                if (this.arrived) {
                    if (this.wt > 1.0) {
                        this.arrived = false;
                        this.dir = -this.dir;
                    }
                } else {
                    this.x += this.dir * WALK * dt;
                    if (Math.abs(this.x) <= ANCHOR) {
                        this.ws = W_ROPE;
                        this.wt = 0;
                    }
                }
            }
            let face = this.dir > 0 ? 90.0 : -90.0;
            if (this.arrived) {
                // turn round in four stepped frames after the cheer
                let turn = Math.min(1.0, Math.max(0.0, (this.wt - 0.6) / 0.4));
                this.yaw = face + (-2.0 * face) * Math.floor(turn * 4.0) / 4.0;
            } else {
                this.yaw = face;
            }
        } else if (this.ws == W_ROPE) {
            let st = Math.abs(this.lean);
            // the topple, the damping, the gust and the pull
            let acc = G * Math.sin(this.lean) - DAMP * this.leanV + this.gustNow + PULL * this.u;
            this.leanV += acc * dt;
            this.lean += this.leanV * dt;
            // walking: slower when leaning, a frozen wobble past 20 degrees
            let pace = st > 0.35 ? 0.0 : WALK * (1.0 - st / 0.35 * 0.7);
            if (this.mode == PLAY) {
                this.x += this.dir * pace * dt;
                this.metres += pace * dt;
                // every step nudges him a little
                this.stepT += pace * dt;
                if (this.stepT > 0.38) {
                    this.stepT -= 0.38;
                    this.leanV += api.range(-0.12, 0.12);
                }
            }
            if (Math.abs(this.lean) > FALL_AT && this.mode == PLAY) {
                this.ws = W_FALL;
                this.wt = 0;
                this.fallX = this.x;
                this.fallY = this.feetY(this.x);
                this.fallZ = 0;
                this.fallVY = 1.2;
                this.fallVZ = (this.lean > 0 ? 1.0 : -1.0) * 1.6;
                this.poleY = 0.97 + this.fallY;
                this.poleVY = 2.0;
                this.poleZ = 0;
                this.gameOver(api);
            } else if (Math.abs(this.x) > ANCHOR) {
                // onto the far platform: a crossing
                this.ws = W_STAND;
                this.wt = 0;
                this.x = this.dir * DECK;
                this.crossings++;
                this.arrived = true;
                this.score += 10;
                this.popT = 0;
                this.gustT = this.gustLen;
                this.gustWarn = 0;
            }
        } else if (this.ws == W_FALL) {
            this.leanV += 6.0 * (this.lean > 0 ? 1.0 : -1.0) * dt;
            this.lean += this.leanV * dt;
            this.fallVY -= 9.8 * dt;
            this.fallY += this.fallVY * dt;
            this.fallZ += this.fallVZ * dt;
            this.poleVY -= 9.8 * dt;
            this.poleY += this.poleVY * dt;
            this.poleZ += this.fallVZ * 0.6 * dt;
            if (this.fallY < RIVER_Y) {
                this.ws = W_GONE;
                this.splashT = 0;
                this.splashX = this.fallX;
                this.splashZ = this.fallZ;
                api.hide(this.body);
                api.hide(this.pole);
            }
        }
        if (this.ws == W_GONE) {
            return;
        }
        // place him: the feet on the rope (or the deck), the lean rolls him about them
        let roll = (this.dir > 0 ? 1.0 : -1.0) * this.lean * 180.0 / Math.PI;
        if (this.ws == W_FALL) {
            api.place(this.body, this.fallX, this.fallY, this.fallZ, this.yaw, 0, roll, 1);
        } else {
            let y = this.feetY(this.x);
            let bob = 0.0;
            let sx = 1.0, sy = 1.0;
            if (this.ws == W_ROPE && this.mode == PLAY && Math.abs(this.lean) < 0.35) {
                bob = Math.floor(Math.abs(Math.sin(this.metres / 0.38 * Math.PI)) * 3.0) / 3.0 * 0.04;
            }
            if (this.ws == W_STAND && this.popT < 0.7) {
                // the cheer: crouch, hop, land
                let t = this.popT;
                if (t < 0.12) {
                    sy = 0.86;
                } else if (t < 0.5) {
                    let h = Math.sin((t - 0.12) / 0.38 * Math.PI);
                    bob = 0.35 * h;
                    sy = 1.1;
                } else {
                    sy = 0.9;
                }
                sx = 1.0 / Math.sqrt(sy);
            }
            if (this.mode == IDLE) {
                roll = 2.5 * Math.sin(Math.floor(api.time * 6.0) / 6.0 * 1.7);
            }
            api.placeScaled(this.body, this.x, y + bob, 0, this.yaw, sx, sy, sx, 0, roll);
        }
        // the pole rides in his hands, tipping a little with the pull
        api.transform(this.body, api.restX[this.body], api.restY[this.body] + 0.97, api.restZ[this.body] + 0.16);
        let tilt = -this.u * 12.0 * (this.dir > 0 ? 1.0 : -1.0);
        if (this.ws == W_FALL) {
            api.place(this.pole, this.fallX, this.poleY, this.poleZ, this.yaw, 0, this.wt * 400.0, 1);
        } else {
            api.place(this.pole, api.tx, api.ty, api.tz, this.yaw, 0, roll + tilt, 1);
        }
    }

    // the rope's two spans meet under his feet (straight while nobody stands on it)
    private updateRope(api: GameApi): void {
        let fx = 0.0, fy = 0.0;
        if (this.ws == W_ROPE) {
            fx = this.x;
            fy = this.feetY(this.x);
        }
        this.span(api, this.ropeA, -ANCHOR, 0, fx, fy);
        this.span(api, this.ropeB, fx, fy, ANCHOR, 0);
    }

    private span(api: GameApi, b: i32, x0: f64, y0: f64, x1: f64, y1: f64): void {
        let dx = x1 - x0, dy = y1 - y0;
        let len = Math.sqrt(dx * dx + dy * dy);
        let roll = Math.atan2(dy, dx) * 180.0 / Math.PI;
        api.placeScaled(b, x0, y0, 0, 0, Math.max(len, 0.01) / 14.0, 1, 1, 0, roll);
    }

    // ------------------------------------------------------------------ the demo's hand

    private updateDemo(api: GameApi, dt: f64): void {
        if (this.mode == OVER) {
            if (this.overTime > 2.0) {
                this.resetWalker();
                this.newRun(api);
                this.opening(api);
            }
            return;
        }
        // it sees the lean a moment late (a reaction time), pulls against it, and now and then
        // looks away for a moment
        this.dHist[this.dHistAt] = this.lean;
        this.dHistV[this.dHistAt] = this.leanV;
        this.dHistAt = (this.dHistAt + 1) % 16;
        let old = (this.dHistAt + 4) % 16;      // ~0.2 s ago
        let l = this.dHist[old];
        let v = this.dHistV[old];
        this.dLapseIn -= dt;
        if (this.dLapseIn <= 0) {
            this.dLapse = api.range(0.25, 0.55) + <f64>this.crossings * 0.07;
            this.dLapseIn = api.range(2.0, 4.5);
        }
        let want = -(2.3 * l + 0.75 * v) / PULL * 2.2;
        if (this.gustWarn <= 0 && this.gustT < this.gustLen) {
            want -= this.gustDir * this.gustPow / PULL * 0.6;   // it has seen the streaks
        }
        if (this.dLapse > 0) {
            this.dLapse -= dt;
            want = this.dU;
        }
        want = Math.max(-1.0, Math.min(1.0, want));
        let lim = 3.5 * dt;
        this.dU += Math.max(-lim, Math.min(lim, want - this.dU));
    }

    // ------------------------------------------------------------------ the frame

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.resetWalker();
            this.newRun(api);
            if (api.demo) {
                this.opening(api);
            }
        }
        if (this.mode == PLAY) {
            this.runTime += dt;
        } else if (this.mode == OVER) {
            this.overTime += dt;
        }
        this.popT += dt;
        // where he is on screen: the pointer pulls relative to him
        let hy = this.ws == W_FALL ? this.fallY : this.feetY(this.x);
        if (api.project(<f32>this.x, <f32>(hy + 1.0), 0)) {
            this.walkerSX = <f64>api.screenX;
            this.walkerSY = <f64>api.screenY;
        }
        if (api.demo) {
            this.updateDemo(api, dt);
            this.u = this.dU;
        } else if (api.pointerX >= 0 && this.mode == PLAY) {
            // a dead zone of 6 HUD pixels round him, full pull 60 pixels away
            let off = <f64>api.pointerX - this.walkerSX;
            off = off > 6.0 ? off - 6.0 : (off < -6.0 ? off + 6.0 : 0.0);
            this.u = Math.max(-1.0, Math.min(1.0, off / 60.0));
        } else {
            this.u = 0;
        }
        this.updateWind(api, dt);
        this.updateWalker(api, dt);
        this.updateRope(api);
        this.updateStreaks(api, dt);

        // the pennants stream with the wind (towards the coming gust's side), hang loose in a calm
        let t = api.time;
        let windy = this.windy();
        let flap = Math.floor(t * 10.0) % 2.0 == 0.0 ? 1.0 : 0.82;
        for (let k = 0; k < 2; k++) {
            let b = k == 0 ? this.flagA : this.flagB;
            let fx = k == 0 ? -ANCHOR : ANCHOR;
            let fz = k == 0 ? 0.42 : -0.42;
            if (windy) {
                api.placeScaled(b, fx, 0.59, fz, this.gustDir > 0 ? 0.0 : 180.0, 1, flap, 1, 0, 0);
            } else {
                let sway = 12.0 * Math.sin(Math.floor(t * 4.0) / 4.0 * 1.3 + <f64>k);
                api.placeScaled(b, fx, 0.59, fz, 90.0 + sway, 1, 1, 1, 50.0, 0);
            }
        }
        // the splash
        if (this.splashT < 0.8) {
            this.splashT += dt;
            let u = this.splashT / 0.8;
            let s = u < 0.3 ? 0.4 + u / 0.3 * 0.9 : 1.3 * (1.0 - (u - 0.3) / 0.7) + 0.05;
            s = Math.floor(s * 6.0) / 6.0;
            if (this.splashT >= 0.8) {
                api.hide(this.splash);
            } else {
                api.placeScaled(this.splash, this.splashX, RIVER_Y, this.splashZ, 0, s, s * 1.3, s, 0, 0);
            }
        }
        // a hawk circles over the gorge, banking
        let a = t * 0.28;
        let bx = 6.0 + 7.0 * Math.cos(a);
        let bz = 1.5 + 9.0 * Math.sin(a);
        api.place(this.bird, bx, 4.6 + 0.3 * Math.sin(t * 0.9), bz, Math.atan2(-7.0 * Math.sin(a), 9.0 * Math.cos(a)) * 180.0 / Math.PI, 0, 18.0, 1);
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.mode == IDLE) {
                this.newRun(api);
            } else if (this.mode == OVER && this.overTime > 1.0) {
                this.resetWalker();
                this.newRun(api);
                this.popT = 0;
            }
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let U = api.rampColor(R_ROCK, 0);
        let Bk = api.rampColor(R_ROCK, 1);
        let O = api.rampColor(R_ROCK, 3);
        let C = api.rampColor(R_ROCK, 4);
        let S = api.rampColor(R_COOL, 1);
        let A = api.rampColor(R_COOL, 3);
        let W = <f32>api.hudW;
        let H = <f32>api.hudH;
        let best = api.demo ? this.bestDemo : this.best;
        let shown = this.score + <i32>Math.floor(this.metres);

        api.text(6, 6, "SCORE " + shown.toString(), C, 2, U);
        api.text(6, 20, "BEST " + best.toString() + "   CROSSINGS " + this.crossings.toString(), O, 1, U);

        // the balance gauge, top right: a bead that must stay in the middle
        let gw: f32 = 72;
        let gx = W - gw - 8.0;
        let gy: f32 = 8;
        api.rect(gx - 1, gy - 1, gw + 2, 9, U);
        api.rect(gx, gy, gw, 7, S);
        api.rect(gx, gy, 10, 7, Bk);
        api.rect(gx + gw - 10.0, gy, 10, 7, Bk);
        api.rect(gx + gw * 0.5, gy - 2, 1, 11, C);
        let f = Math.max(-1.0, Math.min(1.0, this.lean / FALL_AT));
        let bx = gx + gw * 0.5 + <f32>Math.round(f * <f64>(gw * 0.5 - 3.0)) - 2.0;
        let danger = Math.abs(f) > 0.7 && Math.floor(api.time * 8.0) % 2.0 == 0.0;
        api.rect(bx, gy + 1, 5, 5, danger ? C : O);
        api.text(gx + 16.0, gy + 11.0, "BALANCE", A, 1, U);

        // the wind's warning
        if (this.mode == PLAY && this.windy()) {
            let s = this.gustDir > 0 ? "WIND >>>" : "<<< WIND";
            let blink = this.gustWarn > 0 && Math.floor(api.time * 6.0) % 2.0 == 0.0;
            if (!blink) {
                api.textCentered(30, s, C, 2, U);
            }
        }
        // the pull: a little arrow under his feet, how hard and which way the pointer pulls
        if (this.mode == PLAY && this.ws == W_ROPE) {
            let px = <f32>Math.round(this.walkerSX);
            let py = <f32>Math.round(this.walkerSY) + 2.0;
            if (api.project(<f32>this.x, <f32>(this.feetY(this.x) - 0.25), 0)) {
                py = Mathf.round(api.screenY);
            }
            let len = <f32>Math.round(this.u * 14.0);
            if (Mathf.abs(len) >= 1) {
                api.line(px, py, px + len, py, C);
                let tip = px + len;
                let s: f32 = len > 0 ? -1 : 1;
                api.rect(tip + s, py - 1, 1, 3, C);
            }
        }
        if (this.popT < 1.0) {
            let s = "+10";
            if (api.project(<f32>this.x, <f32>(2.2 + this.popT * 0.6), 0)) {
                api.text(Mathf.round(api.screenX - api.textWidth(s, 2) * 0.5), Mathf.round(api.screenY), s, C, 2, U);
            }
        }

        if (this.mode == IDLE) {
            api.textCentered(H - 30.0, "CLICK TO START", C, 2, U);
            api.textCentered(H - 14.0, "MOVE THE POINTER TO PULL HIM UPRIGHT", C, 1, U);
        } else if (this.mode == OVER) {
            api.rect(0, 70, W, 46, U);
            api.textCentered(76, "HE FELL!", C, 3, 0);
            api.textCentered(96, "SCORE " + shown.toString() + "   BEST " + best.toString(), O, 1, 0);
            if (this.overTime > 1.0 && Math.floor(this.overTime * 2.0) % 2.0 == 0.0) {
                api.textCentered(106, api.demo ? "DEMO" : "CLICK TO TRY AGAIN", A, 1, 0);
            }
        } else if (this.runTime < 4.0 && !api.demo) {
            api.textCentered(H - 14.0, "HE LEANS TOWARDS THE POINTER - MIND THE WIND", C, 1, U);
        }
        if (api.demo && this.mode != OVER) {
            api.text(W - 22.0, H - 9.0, "DEMO", C, 1, U);
        }
    }
}
