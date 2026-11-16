// Skee ramp: nine balls up an arcade lane. Press near the ball, drag up and let go: the longer the
// drag, the harder the roll; sideways steers it. The ball climbs the lane, jumps the hump and lands
// on the target board: the centre hole 50, the rings 30 / 20 / 10, the board 10, the cup at the top
// 100. Too soft and it rolls back for nothing. 300 or more wins a prize. One lane, pointer only.
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP } from "./game_api";

const BALLS: i32 = 9;
const PRIZE: i32 = 300;
const R: f64 = 0.1;            // ball radius
const S0: f64 = 0.25;          // where a ball waits on the lane (metres from the foot)
const S_HUMP: f64 = 2.2;       // the hump: the ball takes off here
const LANE_Z0: f64 = 1.595;    // the lane's foot (world z); it runs towards -z
const DECEL: f64 = 1.6;        // the slope and rolling friction, m/s/s
const XMAX: f64 = 0.42;        // between the rails
const V_MIN: f64 = 2.2;        // launch speed at no power
const V_SPAN: f64 = 4.0;       // ... more at full power
const DRAG_FULL: f32 = 90;     // HUD pixels of drag for full power
const DRAG_MIN: f32 = 8;
// the target board: bottom edge (z -0.775, y 0.99) to top (z -1.415, y 1.94), 1.145 m along its face
const BOARD_LEN: f64 = 1.145;
const NY: f64 = 0.559;         // its normal (towards the player and up)
const NZ: f64 = 0.829;
const RING_T: f64 = 0.42;      // the rings' centre, as a fraction of the board's height
const CUP_T: f64 = 0.884;

const R_PINK: i32 = 0;
const R_FIRE: i32 = 1;
const R_BLUE: i32 = 2;
const R_MINT: i32 = 3;
const R_DUSK: i32 = 4;

const READY: i32 = 0;   // before the first throw of a run (the hint)
const IDLE: i32 = 1;    // a ball waits
const AIM: i32 = 2;     // dragging
const ROLL: i32 = 3;
const FLY: i32 = 4;
const SINK: i32 = 5;    // scored: the ball drops into its hole
const NEXT: i32 = 6;    // the next ball hops from the tray
const OVER: i32 = 7;

export class Game {
    state: i32 = READY;
    wasDemo: bool = false;
    t: f64 = 0;              // time in the current state
    overAt: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    thrown: i32 = 0;         // balls used
    cur: i32 = 0;            // the ball in play (bone pool index)
    bb: StaticArray<i32> = new StaticArray<i32>(BALLS);
    flashB: i32 = -1;

    // the ball in play
    s: f64 = S0;
    x: f64 = 0;
    v: f64 = 0;
    vx: f64 = 0;
    spin: f64 = 0;
    // flight
    fx0: f64 = 0; fy0: f64 = 0; fz0: f64 = 0;
    fx1: f64 = 0; fy1: f64 = 0; fz1: f64 = 0;
    fT: f64 = 0.4;
    fArc: f64 = 0.4;
    landT: f64 = 0;
    landX: f64 = 0;
    pts: i32 = 0;
    ringR: f64 = 0;
    flashT: f64 = 9;
    lastPts: i32 = -1;
    popT: f64 = 9;
    popX: f32 = 0;
    popY: f32 = 0;

    // aiming (HUD pixels)
    ax0: f32 = 0;
    ay0: f32 = 0;
    ax: f32 = 0;
    ay: f32 = 0;

    // demo
    dWait: f64 = 0.15;
    dPower: f64 = 0;
    dSide: f32 = 0;
    dRel: f64 = 0.5;
    dDragging: bool = false;

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < BALLS; i++) {
            this.bb[i] = api.bone("ball" + i.toString());
        }
        this.flashB = api.bone("flash");
        api.hide(this.flashB);
        this.wasDemo = api.demo;
        this.newRun(api);
        this.state = api.demo ? IDLE : READY;
    }

    newRun(api: GameApi): void {
        this.score = 0;
        this.thrown = 0;
        this.cur = 0;
        this.s = S0;
        this.x = 0;
        this.state = IDLE;
        this.t = 0;
        this.dWait = 0.15;
        this.dDragging = false;
        this.lastPts = -1;
    }

    // ---------------------------------------------------------------- geometry

    laneY(s: f64): f64 {
        let y = 0.58 + 0.32 * s / 2.37 + R;
        if (s > 2.2) {
            y += Math.min(1, (s - 2.2) / 0.17) * 0.11; // the hump
        }
        return y;
    }

    laneZ(s: f64): f64 {
        return LANE_Z0 - s;
    }

    // where a ball rests in the tray (slot k of the remaining ones, 5 show)
    trayX(k: i32): f64 {
        return -0.4 + <f64>k * 0.2;
    }

    // the landing fraction up the board for a speed at the hump
    landFor(vh: f64): f64 {
        return (vh - 1.0) / 3.6;
    }

    // the speed at the hump for a launch speed (0 when it never gets there)
    humpSpeed(v0: f64): f64 {
        let q = v0 * v0 - 2 * DECEL * (S_HUMP - S0);
        return q > 0 ? Math.sqrt(q) : 0;
    }

    // ---------------------------------------------------------------- update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.newRun(api);
        }
        this.t += dt;
        this.flashT += dt;
        this.popT += dt;
        let st = this.state;
        if (st == ROLL) {
            this.s += this.v * dt;
            this.v -= DECEL * dt;
            this.x += this.vx * dt;
            if (this.x > XMAX) { this.x = XMAX; this.vx = -this.vx * 0.6; }
            if (this.x < -XMAX) { this.x = -XMAX; this.vx = -this.vx * 0.6; }
            this.spin += this.v * dt / R * 57.3;
            if (this.s >= S_HUMP && this.v > 0) {
                this.takeOff(api);
            } else if (this.v < 0 && this.s <= S0) {
                // too soft: it rolled back
                this.s = S0;
                this.scoreBall(api, 0, 0, 0);
                if (this.state != OVER) {
                    this.state = NEXT;
                    this.t = 0;
                }
            }
        } else if (st == FLY) {
            if (this.t >= this.fT) {
                this.land(api);
            }
        } else if (st == SINK) {
            if (this.t > 0.75) {
                this.thrown++;
                this.cur++;
                this.state = this.thrown >= BALLS ? OVER : NEXT;
                this.t = 0;
                if (this.state == OVER) {
                    this.finish(api);
                }
            }
        } else if (st == NEXT) {
            if (this.t > 0.45) {
                this.state = IDLE;
                this.t = 0;
                this.s = S0;
                this.x = 0;
                this.dWait = api.range(0.6, 1.1);
            }
        } else if (st == OVER) {
            if (api.demo && api.time - this.overAt > 2.0) {
                this.newRun(api);
            }
        }
        if (api.demo) {
            this.demoPlay(api, dt);
        }
        this.drawBalls(api);
    }

    takeOff(api: GameApi): void {
        let vh = Math.max(0, this.v);
        let lt = this.landFor(vh);
        this.landT = Math.min(1.25, Math.max(-0.05, lt));
        this.fT = 0.3 + 0.22 * Math.min(1, Math.max(0, this.landT));
        this.landX = Math.min(0.44, Math.max(-0.44, this.x + this.vx * this.fT));
        this.fx0 = this.x;
        this.fy0 = this.laneY(S_HUMP + 0.12);
        this.fz0 = this.laneZ(S_HUMP + 0.12);
        let bt = Math.min(1.02, this.landT);
        let off = 0.16 + R;
        this.fx1 = this.landX;
        this.fy1 = 0.99 + 0.95 * bt + NY * off;
        this.fz1 = -0.775 - 0.64 * bt + NZ * off;
        this.fArc = 0.25 + 0.3 * Math.max(0, this.landT);
        this.state = FLY;
        this.t = 0;
    }

    land(api: GameApi): void {
        let lt = this.landT, lx = this.landX;
        let pts = 10;
        let rr = 0.0;
        let dc = Math.sqrt(lx * lx + Math.pow((lt - CUP_T) * BOARD_LEN, 2));
        let d = Math.sqrt(lx * lx + Math.pow((lt - RING_T) * BOARD_LEN, 2));
        if (lt <= 1.0 && dc < 0.12) {
            pts = 100;
            rr = 0.11;
        } else if (d < 0.1) {
            pts = 50;
            rr = 0.09;
        } else if (d < 0.2) {
            pts = 30;
            rr = 0.2;
        } else if (d < 0.3) {
            pts = 20;
            rr = 0.3;
        } else if (d < 0.38) {
            rr = 0.38;
        }
        this.scoreBall(api, pts, rr, pts == 100 ? CUP_T : RING_T);
        this.state = SINK;
        this.t = 0;
    }

    scoreBall(api: GameApi, pts: i32, rr: f64, ct: f64): void {
        this.score += pts;
        this.lastPts = pts;
        this.ringR = rr;
        this.flashT = rr > 0 ? 0 : 9;
        if (rr > 0) {
            let off = 0.17;
            api.place(this.flashB, 0, 0.99 + 0.95 * ct + NY * off, -0.775 - 0.64 * ct + NZ * off, 0, 56, 0, rr / 0.1);
        }
        let px = this.fx1, py = this.fy1, pz = this.fz1;
        if (pts == 0) {
            px = this.x; py = this.laneY(S0); pz = this.laneZ(S0);
            this.thrown++;
            this.cur++;
            if (this.thrown >= BALLS) {
                this.state = OVER;
                this.finish(api);
            }
        }
        if (api.project(<f32>px, <f32>py + 0.25, <f32>pz)) {
            this.popX = api.screenX;
            this.popY = api.screenY;
            this.popT = 0;
        }
    }

    finish(api: GameApi): void {
        this.overAt = api.time;
        if (this.score > this.best) {
            this.best = this.score;
        }
    }

    // ---------------------------------------------------------------- drawing the balls

    drawBalls(api: GameApi): void {
        let st = this.state;
        // the flash: a few stepped blinks
        if (this.flashT > 0.6 || (<i32>(this.flashT * 10)) % 2 == 1) {
            api.hide(this.flashB);
        } else {
            let off = 0.17;
            let ct = this.lastPts == 100 ? CUP_T : RING_T;
            api.place(this.flashB, 0, 0.99 + 0.95 * ct + NY * off, -0.775 - 0.64 * ct + NZ * off, 0, 56, 0, this.ringR / 0.1);
        }
        let k = 0;
        for (let i = 0; i < BALLS; i++) {
            let b = this.bb[i];
            if (i < this.cur) {
                api.hide(b); // thrown
                continue;
            }
            if (i == this.cur && st != OVER) {
                this.drawCurrent(api, b);
                continue;
            }
            // waiting in the tray, the first five
            if (k < 5) {
                api.place(b, this.trayX(k), 0.42 + R, 1.78);
            } else {
                api.hide(b);
            }
            k++;
        }
        if (st == OVER) {
            // the next run's balls sit ready in the tray
            for (let i = 0; i < BALLS; i++) {
                if (i < 5) {
                    api.place(this.bb[i], this.trayX(i), 0.42 + R, 1.78);
                } else {
                    api.hide(this.bb[i]);
                }
            }
        }
    }

    drawCurrent(api: GameApi, b: i32): void {
        let st = this.state;
        if (st == NEXT) {
            // a hop from the tray onto the lane
            let u = Math.min(1, this.t / 0.45);
            let x0 = this.trayX(0), y0 = 0.42 + R, z0 = 1.78;
            let y1 = this.laneY(S0), z1 = this.laneZ(S0);
            let h = Math.sin(u * Math.PI) * 0.35;
            api.place(b, x0 + (0 - x0) * u, y0 + (y1 - y0) * u + h, z0 + (z1 - z0) * u);
            return;
        }
        if (st == FLY) {
            let u = this.t / this.fT;
            let x = this.fx0 + (this.fx1 - this.fx0) * u;
            let y = this.fy0 + (this.fy1 - this.fy0) * u + Math.sin(u * Math.PI) * this.fArc;
            let z = this.fz0 + (this.fz1 - this.fz0) * u;
            this.spin += 900 * api.dt;
            api.placeScaled(b, x, y, z, 0, 0.92, 1.12, 0.92, stepped(this.spin, 30));
            return;
        }
        if (st == SINK) {
            // a squash on the board, then it drops into the hole
            let u = this.t;
            if (u < 0.12) {
                api.placeScaled(b, this.fx1, this.fy1, this.fz1, 0, 1.25, 0.7, 1.25);
            } else if (u < 0.45) {
                let w = (u - 0.12) / 0.33;
                let ct = this.lastPts == 100 ? CUP_T : RING_T;
                let tx = this.lastPts >= 20 ? 0 : this.fx1;
                let tt = this.lastPts >= 20 ? ct : Math.max(0, this.landT - 0.15);
                let hy = 0.99 + 0.95 * tt + NY * 0.1, hz = -0.775 - 0.64 * tt + NZ * 0.1;
                let s = 1 - 0.6 * w;
                api.place(b, this.fx1 + (tx - this.fx1) * w, this.fy1 + (hy - this.fy1) * w, this.fz1 + (hz - this.fz1) * w, 0, 0, 0, s);
            } else {
                api.hide(b);
            }
            return;
        }
        let s = this.s, x = this.x;
        if (st == AIM) {
            // anticipation: drawn back, squashed by the pull
            let p = this.power();
            s = S0 - 0.14 * p;
            x = this.side() * 0.08;
            api.placeScaled(b, x, this.laneY(s) - 0.02 * p, this.laneZ(s), 0, 1 + 0.15 * p, 1 - 0.2 * p, 1 + 0.15 * p);
            return;
        }
        if (st == ROLL) {
            api.place(b, x, this.laneY(s), this.laneZ(s), 0, stepped(this.spin, 30));
            return;
        }
        // waiting: a small idle bob
        let bob = (st == IDLE || st == READY) ? Math.abs(Math.sin(stepped(api.time * 3, 0.5))) * 0.03 : 0;
        api.place(b, x, this.laneY(s) + bob, this.laneZ(s));
    }

    // ---------------------------------------------------------------- aiming and throwing

    power(): f64 {
        let dy = this.ay0 - this.ay;
        return Math.min(1, Math.max(0, <f64>(dy - DRAG_MIN) / <f64>(DRAG_FULL - DRAG_MIN)));
    }

    side(): f64 {
        return Math.min(1, Math.max(-1, <f64>(this.ax - this.ax0) / 60.0));
    }

    throwBall(): void {
        let p = this.power();
        this.v = V_MIN + V_SPAN * p;
        this.vx = this.side() * 0.9;
        this.s = S0;
        this.x = 0;
        this.state = ROLL;
        this.t = 0;
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.state == OVER) {
                if (api.time - this.overAt < 0.8) {
                    return true;
                }
                this.newRun(api);
                return true;
            }
            if (this.state == READY || this.state == IDLE) {
                this.state = AIM;
                this.t = 0;
                this.ax0 = x;
                this.ay0 = y;
                this.ax = x;
                this.ay = y;
            }
        } else if (kind == POINTER_MOVE) {
            if (this.state == AIM) {
                this.ax = x;
                this.ay = y;
            }
        } else if (kind == POINTER_UP) {
            if (this.state == AIM) {
                this.ax = x;
                this.ay = y;
                if (this.ay0 - this.ay < DRAG_MIN) {
                    this.state = this.thrown == 0 && this.score == 0 ? READY : IDLE; // too short: no throw
                } else {
                    this.throwBall();
                }
            }
        }
        return true;
    }

    // ---------------------------------------------------------------- the demo player

    demoPlay(api: GameApi, dt: f64): void {
        // a fair player: mostly goes for the 50 hole, now and then the 100 cup, with a hand that
        // is a little off in strength and direction; the drag is shown like a player's
        if (this.state == IDLE) {
            this.dWait -= dt;
            if (this.dWait > 0) {
                return;
            }
            let r = api.rand();
            let target = r < 0.15 ? CUP_T : (r < 0.88 ? RING_T : RING_T + api.range(-0.25, 0.25));
            let vh = 1.0 + 3.6 * target;
            let v0 = Math.sqrt(vh * vh + 2 * DECEL * (S_HUMP - S0));
            let p = (v0 - V_MIN) / V_SPAN + (api.range(-1, 1) + api.range(-1, 1)) * 0.09;
            this.dPower = Math.min(1, Math.max(0.02, p));
            this.dSide = <f32>((api.range(-1, 1) + api.range(-1, 1)) * 10.0);
            this.dRel = api.range(0.35, 0.5);
            if (api.project(<f32>this.x, <f32>this.laneY(S0), <f32>this.laneZ(S0))) {
                this.ax0 = api.screenX;
                this.ay0 = api.screenY;
            }
            this.ax = this.ax0;
            this.ay = this.ay0;
            this.state = AIM;
            this.t = 0;
            return;
        }
        if (this.state == AIM) {
            let u = <f32>Math.min(1, this.t / this.dRel);
            let e = u * u * (3 - 2 * u);
            let dy = DRAG_MIN + <f32>this.dPower * (DRAG_FULL - DRAG_MIN);
            // the side is a fraction of 60 px: the throw's lateral speed
            this.ax = this.ax0 + this.dSide * e;
            this.ay = this.ay0 - dy * e;
            if (this.t >= this.dRel + 0.06) {
                this.throwBall();
            }
        }
    }

    // ---------------------------------------------------------------- HUD

    hud(api: GameApi): void {
        let ink = api.rampColor(R_DUSK, 0);
        let white = api.rampColor(R_BLUE, 3);
        let gold = api.rampColor(R_FIRE, 3);
        let pink = api.rampColor(R_PINK, 2);
        let mint = api.rampColor(R_MINT, 2);
        let w = <f32>api.hudW;
        let h = <f32>api.hudH;
        // a dark band behind the top line
        api.rect(0, 0, w, 13, ink);
        api.text(4, 4, "SCORE", pink, 1, 0);
        api.text(26, 2, this.score.toString(), gold, 2, 0);
        let bs = "BEST " + this.best.toString();
        api.text(w - 4 - api.textWidth(bs, 1), 4, bs, white, 1, 0);
        // balls left: pips
        let left = BALLS - this.thrown;
        let bx = Mathf.floor(w * 0.5 - <f32>27);
        for (let i = 0; i < BALLS; i++) {
            let c = i < left ? mint : api.rampColor(R_DUSK, 1);
            api.rect(bx + <f32>i * 6, 4, 4, 5, c);
        }
        // the aim: a dotted path from the ball, longer and hotter with power
        if (this.state == AIM) {
            let p = this.power();
            let c = p < 0.33 ? mint : (p < 0.66 ? gold : pink);
            let dx = this.ax - this.ax0, dy = this.ay - this.ay0;
            let n = 3 + <i32>(p * 9);
            for (let i = 1; i <= n; i++) {
                let f = <f32>i / <f32>(n);
                let px = this.ax0 + dx * f * 0.6;
                let py = this.ay0 - 6 - <f32>(p * 70) * f;
                api.rect(Mathf.round(px) - 1, Mathf.round(py) - 1, 3, 3, ink);
                api.rect(Mathf.round(px), Mathf.round(py), 1, 1, c);
            }
            // the power bar beside the lane
            api.rect(w - 14, h - 62, 6, 52, ink);
            let ph = <f32>Mathf.round(<f32>p * 50);
            api.rect(w - 13, h - 11 - ph, 4, ph, c);
        }
        // points of the last ball
        if (this.popT < 1.0 && this.lastPts >= 0) {
            let s = this.lastPts == 0 ? "TOO SOFT" : "+" + this.lastPts.toString();
            let sc = this.lastPts >= 50 ? 2 : 1;
            let c = this.lastPts >= 100 ? gold : (this.lastPts >= 30 ? pink : white);
            if (this.lastPts >= 50 && (<i32>(this.popT * 8)) % 2 == 1) {
                c = white;
            }
            let ty = this.popY - 10 - <f32>this.popT * 10;
            api.text(Mathf.floor(this.popX - api.textWidth(s, sc) * 0.5), Mathf.floor(ty), s, c, sc, ink);
        }
        if (this.state == READY) {
            api.textCentered(h - 12, "DRAG UP FROM THE BALL AND LET GO", white, 1, ink);
        } else if (this.state == OVER) {
            let won = this.score >= PRIZE;
            api.rect(0, h * 0.5 - 30, w, 46, ink);
            api.textCentered(h * 0.5 - 26, won ? "PRIZE!" : "NO PRIZE", won ? gold : pink, 3, 0);
            let line = "SCORE " + this.score.toString() + (won ? "  YOU WIN A PLUSH" : "  NEED " + PRIZE.toString());
            api.textCentered(h * 0.5 - 4, line, white, 1, 0);
            if (this.score >= this.best && this.score > 0) {
                api.textCentered(h * 0.5 + 5, "NEW BEST!", gold, 1, 0);
            }
            if (!api.demo && api.time - this.overAt > 0.8) {
                api.textCentered(h - 12, "CLICK TO PLAY AGAIN", white, 1, ink);
            }
        }
    }
}

function stepped(phase: f64, step: f64): f64 {
    return Math.floor(phase / step) * step;
}
