// Peg Drop: a clockwork coin dropper rides the rail over a peg board in a workshop. Move the pointer
// to slide it, click to drop a coin; the coin rattles down through the brass pegs (and past the
// swinging pendulum) into one of seven cups. Ten coins a run; the lit cup doubles. The coins stay in
// the cups as a pile until the next run. Pointer only; demo mode plays itself.
import { GameApi, POINTER_DOWN, POINTER_MOVE, SFX_BELL, SFX_CLICK, SFX_COIN, SFX_NOTE, SFX_POP, SFX_POWERUP, SFX_TICK,
    SFX_WHOOSH, SFX_WIN } from "./game_api";

const ST_IDLE: i32 = 0;
const ST_PLAY: i32 = 1;
const ST_OVER: i32 = 2;

// coin states
const C_OFF: i32 = 0;    // hidden (in the dropper's stock)
const C_FALL: i32 = 1;   // rattling down the board
const C_LAND: i32 = 2;   // dropping onto its cup's pile
const C_REST: i32 = 3;   // in a cup
const C_SINK: i32 = 4;   // the cups empty for a new run

const NCOIN: i32 = 10;
const NSPARK: i32 = 8;
const NCUP: i32 = 7;

// the board (glTF metres; models/env/make_env.py writes the same numbers)
const G: f64 = 7.0;            // gravity, m/s^2 (slowed: the board is 7 m tall)
const RC: f64 = 0.22;          // coin radius
const RP: f64 = 0.1;           // peg head radius
const REST: f64 = 0.45;        // restitution on pegs
const WALL: f64 = 4.0;         // inner half width
const PIV_X: f64 = 0.0;
const PIV_Y: f64 = 4.15;
const ARM: f64 = 1.85;
const SWING: f64 = 36.0;       // degrees each way
const PERIOD: f64 = 2.6;       // seconds a full swing
const BOB_R: f64 = 0.36;
const HUB_R: f64 = 0.2;
const DIV_TOP: f64 = 0.85;
const DIV_HALF: f64 = 0.06;
const RAIL_Y: f64 = 6.2;       // the dropper's chute mouth (its bake position)
const SPAWN_Y: f64 = 6.0;
const RAIL_MIN: f64 = -3.7;
const RAIL_MAX: f64 = 3.7;
const RELOAD: f64 = 1.1;       // the dropper winds itself up between coins

const PEG_X: StaticArray<f64> = [-3.325, -2.375, -1.425, -0.475, 0.475, 1.425, 2.375, 3.325, -2.85, -1.9, -0.95, 0.0, 0.95, 1.9, 2.85,
    -3.325, -2.375, -1.425, 1.425, 2.375, 3.325, -2.85, -1.9, -0.95, 0.95, 1.9, 2.85, -3.325, -2.375, 2.375, 3.325, -2.85, -1.9, 1.9, 2.85,
    -3.325, -2.375, 2.375, 3.325];
const PEG_Y: StaticArray<f64> = [5.5, 5.5, 5.5, 5.5, 5.5, 5.5, 5.5, 5.5, 4.9, 4.9, 4.9, 4.9, 4.9, 4.9, 4.9,
    4.3, 4.3, 4.3, 4.3, 4.3, 4.3, 3.7, 3.7, 3.7, 3.7, 3.7, 3.7, 3.1, 3.1, 3.1, 3.1, 2.5, 2.5, 2.5, 2.5,
    1.9, 1.9, 1.9, 1.9];
const DIV_X: StaticArray<f64> = [-2.85, -1.75, -0.6, 0.6, 1.75, 2.85];
const EDGE: StaticArray<f64> = [-4.0, -2.85, -1.75, -0.6, 0.6, 1.75, 2.85, 4.0];
const VALUE: StaticArray<i32> = [20, 50, 10, 100, 10, 50, 20];
// sound: the peg rows ring a pentatonic scale, high at the top, low at the bottom (MIDI)
const ROW_NOTE: StaticArray<f64> = [86, 84, 81, 79, 76, 74, 72];

// palette indices (art/palette.json "colors")
const C_GOLD: i32 = 4;        // #ffe478
const C_CREAM: i32 = 15;      // #ffffeb
const C_SILVER: i32 = 16;     // #c2c2d1
const C_INK: i32 = 20;        // #272736
const C_PLUMDK: i32 = 21;     // #3e2347
const C_ORANGE: i32 = 25;     // #ffb570
const C_PINK: i32 = 34;       // #ff6b97
const C_MINT: i32 = 14;       // #66ffe3
const C_BRASS: i32 = 3;       // #f2a65e
const C_DARKBR: i32 = 1;      // #8c3f5d

export class Game {
    state: i32 = ST_IDLE;
    stateT: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    left: i32 = NCOIN;          // coins still in the dropper
    wasDemo: bool = false;

    // bones
    dropper: i32 = -1;
    pendulum: i32 = -1;
    gearA: i32 = -1;
    gearB: i32 = -1;
    gearC: i32 = -1;
    hand: i32 = -1;
    marker: i32 = -1;
    coinBone: StaticArray<i32> = new StaticArray<i32>(NCOIN);
    sparkBone: StaticArray<i32> = new StaticArray<i32>(NSPARK);

    // the dropper
    dx: f64 = -1.2;
    dv: f64 = 0;
    tx: f64 = -1.2;
    reload: f64 = 0;
    dropQ: f64 = -1;        // a press waiting for the dropper to reach it, seconds (-1: none)
    squash: f64 = 0;

    // coins
    cSt: StaticArray<i32> = new StaticArray<i32>(NCOIN);
    cX: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    cY: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    cZ: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    cVX: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    cVY: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    cT: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    cSpin: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    cCheckY: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    cCheckT: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    cFromY: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    cRX: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    cRY: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    cRZ: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    pile: StaticArray<i32> = new StaticArray<i32>(NCUP);
    lit: i32 = 3;
    litT: f64 = 0;              // > 0: the marker pops (a doubled landing)

    // sparks
    pT: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pVX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pVY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pNext: i32 = 0;

    // juice
    popT: f64 = -1;
    popX: f32 = 0;
    popY: f32 = 0;
    popText: string = "";
    popBig: bool = false;
    shakeT: f64 = 0;
    camTX: f64 = 0;
    camTY: f64 = 0;
    endT: f64 = 0;              // the last coin has settled: a beat before GAME OVER

    // the demo player
    dPlanX: f64 = 0;
    dWait: f64 = 0;
    dHasPlan: bool = false;

    // sound (decided from the game's state only, never from api.rand)
    hitF: StaticArray<i32> = new StaticArray<i32>(NCOIN);   // each coin's last knock (frame)
    knockF: i32 = -99;          // the last knock on any peg (a global cooldown)
    lastTk: f64 = -1;           // the escapement's last tick

    start(api: GameApi): void {
        api.playable = true;
        this.dropper = api.bone("dropper");
        this.pendulum = api.bone("pendulum");
        this.gearA = api.bone("gearA");
        this.gearB = api.bone("gearB");
        this.gearC = api.bone("gearC");
        this.hand = api.bone("hand");
        this.marker = api.bone("marker");
        for (let i = 0; i < NCOIN; i++) {
            this.coinBone[i] = api.bone("coin" + i.toString());
        }
        for (let i = 0; i < NSPARK; i++) {
            this.sparkBone[i] = api.bone("spark" + i.toString());
            this.pT[i] = -1;
        }
        this.camTX = api.targetX;
        this.camTY = api.targetY;
        this.wasDemo = api.demo;
        this.resetRun(api);
        this.state = ST_IDLE;
        if (api.demo) {
            this.beginRun(api);
        }
    }

    // ------------------------------------------------------------------ run control

    resetRun(api: GameApi): void {
        for (let i = 0; i < NCOIN; i++) {
            this.cSt[i] = C_OFF;
        }
        for (let c = 0; c < NCUP; c++) {
            this.pile[c] = 0;
        }
        this.left = NCOIN;
        this.score = 0;
        this.reload = 0;
        this.endT = 0;
        this.popT = -1;
        this.shakeT = 0;
        this.litT = 0;
        this.lit = this.pickLit(api, -1);
    }

    beginRun(api: GameApi): void {
        if (this.state == ST_OVER) {
            // the cups empty: every coin in them sinks through the tray
            for (let i = 0; i < NCOIN; i++) {
                if (this.cSt[i] == C_REST || this.cSt[i] == C_LAND) {
                    this.cSt[i] = C_SINK;
                    this.cT[i] = 0;
                    this.cFromY[i] = this.cRY[i];
                } else if (this.cSt[i] == C_FALL) {
                    this.cSt[i] = C_OFF;
                }
            }
            for (let c = 0; c < NCUP; c++) {
                this.pile[c] = 0;
            }
            this.left = NCOIN;
            this.score = 0;
            this.reload = 0.3;
            this.endT = 0;
            this.lit = this.pickLit(api, this.lit);
        }
        this.state = ST_PLAY;
        this.stateT = 0;
        this.dHasPlan = false;
    }

    endRun(): void {
        this.state = ST_OVER;
        this.stateT = 0;
        if (this.score > this.best) {
            this.best = this.score;
        }
    }

    pickLit(api: GameApi, not: i32): i32 {
        for (let k = 0; k < 8; k++) {
            let c = <i32>Math.floor(api.rand() * <f64>NCUP) % NCUP;
            if (c != not) {
                return c;
            }
        }
        return (not + 2) % NCUP;
    }

    drop(api: GameApi): bool {
        if (this.state != ST_PLAY || this.left <= 0 || this.reload > 0) {
            return false;
        }
        let i = -1;
        for (let k = 0; k < NCOIN; k++) {
            if (this.cSt[k] == C_OFF) {
                i = k;
                break;
            }
        }
        if (i < 0) {
            return false;
        }
        this.left--;
        this.cSt[i] = C_FALL;
        this.cX[i] = this.dx;
        this.cY[i] = SPAWN_Y;
        this.cZ[i] = 0;
        this.cVX[i] = this.dv * 0.25 + api.range(-0.05, 0.05);
        this.cVY[i] = -0.6;
        this.cT[i] = 0;
        this.cSpin[i] = api.range(480, 900) * (api.rand() < 0.5 ? -1.0 : 1.0);
        this.cCheckY[i] = SPAWN_Y;
        this.cCheckT[i] = 0;
        this.reload = RELOAD;
        this.squash = 0.25;
        this.hitF[i] = api.frame;
        api.soundAt(SFX_CLICK, this.dx, RAIL_Y, 0, 0.7, 0.9);    // the latch lets go
        api.soundAt(SFX_POP, this.dx, RAIL_Y, 0, 1.3, 0.45);
        return true;
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged || api.demo != this.wasDemo) {
            // the host switched demo on or off: a fresh run either way
            this.wasDemo = api.demo;
            this.resetRun(api);
            for (let i = 0; i < NCOIN; i++) {
                api.hide(this.coinBone[i]);
            }
            this.state = ST_IDLE;
            if (api.demo) {
                this.beginRun(api);
            }
        }
        this.stateT += dt;
        if (this.reload > 0) {
            this.reload -= dt;
            if (this.reload <= 0 && this.state == ST_PLAY && this.left > 0) {
                api.soundAt(SFX_CLICK, this.dx, RAIL_Y, 0, 1.2, 0.6);   // wound up: ready
            }
        }
        if (api.demo) {
            this.demoThink(api, dt);
            if (this.state == ST_OVER && this.stateT > 2.0) {
                this.beginRun(api);
            }
        } else if (this.state == ST_IDLE) {
            // before the first click the dropper idles along the rail unless the pointer leads it
            if (api.pointerX < 0) {
                this.tx = -1.2 + 1.6 * Math.sin(api.time * 0.8);
            }
        }
        this.updateDropper(api, dt);
        if (this.dropQ >= 0) {
            // a queued press: drop once the dropper is over it (at most 0.6 s later)
            this.dropQ += dt;
            let target = Math.max(RAIL_MIN, Math.min(RAIL_MAX, this.tx));
            if (api.demo || this.state != ST_PLAY) {
                this.dropQ = -1;
            } else if ((Math.abs(this.dx - target) < 0.12 && Math.abs(this.dv) < 1.0) || this.dropQ > 0.6) {
                this.dropQ = -1;
                this.drop(api);
            }
        }
        this.updateClockwork(api);
        this.updateCoins(api, dt);
        this.updateSparks(api, dt);
        this.updateMarker(api, dt);

        // the run ends a beat after the last coin settles
        if (this.state == ST_PLAY && this.left == 0) {
            let busy = false;
            for (let i = 0; i < NCOIN; i++) {
                if (this.cSt[i] == C_FALL || this.cSt[i] == C_LAND) {
                    busy = true;
                }
            }
            if (!busy) {
                this.endT += dt;
                if (this.endT > 0.7) {
                    let record = this.score > this.best;
                    this.endRun();
                    if (record) {
                        api.sound(SFX_WIN, 1.0, 0.85);      // a new best
                    } else {
                        api.note(72, 0.6, 0, SFX_BELL);     // the run is over: a calm chord
                        api.note(76, 0.5, 0, SFX_BELL);
                        api.note(79, 0.5, 0, SFX_BELL);
                    }
                }
            }
        }
        // camera shake on a jackpot: whole texels, so the frame stays on the HUD's grid
        let texel = api.orthoHeight / 136.0;
        if (this.shakeT > 0) {
            this.shakeT -= dt;
            let k = Math.floor(api.time * 30);
            let ox = Math.sin(k * 12.9898) * 43758.5453;
            ox = ox - Math.floor(ox);
            let oy = Math.sin(k * 78.233) * 12543.1234;
            oy = oy - Math.floor(oy);
            api.targetX = this.camTX + Math.round(ox * 2.0 - 1.0) * texel;
            api.targetY = this.camTY + Math.round(oy * 2.0 - 1.0) * texel;
        } else {
            api.targetX = this.camTX;
            api.targetY = this.camTY;
        }
        if (this.popT >= 0) {
            this.popT += dt;
            if (this.popT > 1.0) {
                this.popT = -1;
            }
        }
    }

    updateDropper(api: GameApi, dt: f64): void {
        let target = Math.max(RAIL_MIN, Math.min(RAIL_MAX, this.tx));
        // a stiff spring along the rail: it lags a little and leans into the slide
        let acc = (target - this.dx) * 60.0 - this.dv * 14.0;
        this.dv += acc * dt;
        this.dx += this.dv * dt;
        if (this.dx < RAIL_MIN) { this.dx = RAIL_MIN; this.dv = 0; }
        if (this.dx > RAIL_MAX) { this.dx = RAIL_MAX; this.dv = 0; }
        let roll = Math.max(-12.0, Math.min(12.0, -this.dv * 3.0));
        roll = Math.round(roll / 3.0) * 3.0;
        if (this.reload > 0 && this.squash <= 0 && this.state == ST_PLAY) {
            // winding up for the next coin: a stepped 12 fps rattle
            roll += Math.floor(api.time * 12.0) % 2 == 0 ? 2.0 : -2.0;
        }
        let sy = 1.0, sx = 1.0;
        if (this.squash > 0) {
            // the drop: a squash as the coin leaves, then a stretch back (stepped at 15 fps)
            this.squash -= dt;
            let k = Math.floor((0.25 - this.squash) * 15.0) / 15.0 / 0.25;
            sy = k < 0.35 ? 1.0 - k / 0.35 * 0.18 : 0.82 + (k - 0.35) / 0.65 * 0.18 + Math.sin((k - 0.35) / 0.65 * Math.PI) * 0.08;
            sx = 2.0 - sy;
        }
        api.placeScaled(this.dropper, this.dx, RAIL_Y, 0, 0, sx, sy, 1.0, 0, roll);
    }

    updateClockwork(api: GameApi): void {
        // the pendulum swings smoothly; the gears and the clock's hand advance on its ticks
        let th = SWING * Math.sin(2.0 * Math.PI * api.time / PERIOD);
        api.place(this.pendulum, PIV_X, PIV_Y, 0, 0, 0, th);
        let ticks = api.time * 2.0 / PERIOD * 2.0;
        let tk = Math.floor(ticks);
        if (tk != this.lastTk) {
            // the escapement: tick, tock, quietly, only while a run is on
            if (this.state == ST_PLAY && this.lastTk >= 0) {
                api.sound(SFX_TICK, <i32>tk % 2 == 0 ? 0.55 : 0.42, 0.45, -0.5);
            }
            this.lastTk = tk;
        }
        let fr = Math.min(1.0, (ticks - tk) / 0.18);
        let a = (tk + fr) * 9.0;
        api.place(this.gearA, api.restX[this.gearA], api.restY[this.gearA], api.restZ[this.gearA], 0, 0, -a);
        api.place(this.gearB, api.restX[this.gearB], api.restY[this.gearB], api.restZ[this.gearB], 0, 0, a * 14.0 / 9.0 + 10.0);
        api.place(this.gearC, api.restX[this.gearC], api.restY[this.gearC], api.restZ[this.gearC], 0, 0, a * 0.8);
        api.place(this.hand, api.restX[this.hand], api.restY[this.hand], api.restZ[this.hand], 0, 0, -6.0 * Math.floor(api.time) - 40.0);
    }

    bobX(t: f64): f64 {
        return PIV_X + ARM * Math.sin(SWING * Math.PI / 180.0 * Math.sin(2.0 * Math.PI * t / PERIOD));
    }

    updateCoins(api: GameApi, dt: f64): void {
        let steps = 4;
        let h = dt / <f64>steps;
        for (let i = 0; i < NCOIN; i++) {
            let b = this.coinBone[i];
            let st = this.cSt[i];
            if (st == C_OFF) {
                api.hide(b);
                continue;
            }
            this.cT[i] += dt;
            let t = this.cT[i];
            if (st == C_FALL) {
                for (let s = 0; s < steps; s++) {
                    this.stepCoin(api, i, h, api.time - dt + h * <f64>(s + 1));
                }
                // a coin that has not got lower for a while is teetering: tip it off
                this.cCheckT[i] += dt;
                if (this.cCheckT[i] > 0.45) {
                    if (this.cCheckY[i] - this.cY[i] < 0.05) {
                        this.cVX[i] += (api.rand() < 0.5 ? -1.0 : 1.0) * 1.2;
                        this.cVY[i] += 0.8;
                    }
                    this.cCheckT[i] = 0;
                    this.cCheckY[i] = this.cY[i];
                }
                if (this.cY[i] < DIV_TOP - RC * 0.5) {
                    this.land(api, i);
                    continue;
                }
                // it flips as it falls (stepped at 12 fps) and rolls with its sideways speed
                let yaw = Math.floor(t * 12.0) / 12.0 * this.cSpin[i];
                api.place(b, this.cX[i], this.cY[i], this.cZ[i], yaw, 0, -this.cVX[i] * 20.0);
            } else if (st == C_LAND) {
                // a short drop onto the pile with a little bounce
                let k = Math.min(1.0, Math.floor(t * 20.0) / 20.0 / 0.25);
                let y = this.cFromY[i] + (this.cRY[i] - this.cFromY[i]) * Math.min(1.0, k * 1.6);
                if (k > 0.62) {
                    y = this.cRY[i] + Math.sin((k - 0.62) / 0.38 * Math.PI) * 0.12;
                }
                api.place(b, this.cRX[i], y, this.cRZ[i], 0, 0, (1.0 - k) * 40.0);
                if (k >= 1.0) {
                    this.cSt[i] = C_REST;
                }
            } else if (st == C_REST) {
                api.place(b, this.cRX[i], this.cRY[i], this.cRZ[i], 0, 0, 0);
            } else if (st == C_SINK) {
                let k = Math.floor(t * 15.0) / 15.0;
                let y = this.cFromY[i] - k * k * 9.0;
                if (y < -0.6) {
                    this.cSt[i] = C_OFF;
                    api.hide(b);
                } else {
                    api.place(b, this.cRX[i], y, this.cRZ[i], 0, 0, 0);
                }
            }
        }
    }

    collide(api: GameApi, i: i32, cx: f64, cy: f64, r: f64, bvx: f64, bvy: f64, e: f64): void {
        let dx = this.cX[i] - cx, dy = this.cY[i] - cy;
        let d2 = dx * dx + dy * dy;
        let rr = RC + r;
        if (d2 >= rr * rr || d2 < 1e-10) {
            return;
        }
        let d = Math.sqrt(d2);
        let nx = dx / d, ny = dy / d;
        this.cX[i] = cx + nx * rr;
        this.cY[i] = cy + ny * rr;
        let rvx = this.cVX[i] - bvx, rvy = this.cVY[i] - bvy;
        let vn = rvx * nx + rvy * ny;
        if (vn >= 0) {
            return;
        }
        let tx = -ny, ty = nx;
        let vt = rvx * tx + rvy * ty;
        let hard = -vn;
        vn = -vn * e;
        vt = vt * 0.9 + (api.rand() - 0.5) * 0.5;
        this.cVX[i] = bvx + nx * vn + tx * vt;
        this.cVY[i] = bvy + ny * vn + ty * vt;
        if (ny > 0.85) {
            // balanced on top of something: it rolls off to one side
            let side = Math.abs(nx) > 0.02 ? (nx > 0 ? 1.0 : -1.0) : (api.rand() < 0.5 ? -1.0 : 1.0);
            this.cVX[i] += side * 0.7;
        }
        if (hard > 2.6) {
            this.spark(api, cx + nx * r, cy + ny * r, nx * 1.5, ny * 1.5 + 1.0);
        }
        this.knock(api, i, cx, cy, r, hard);
    }

    // a knock: a quiet pluck tuned by the peg's row (the coin's height), a bonk off the bob, a tick off
    // the hub and the dividers; rate-limited per coin (5 frames) and across coins (3 frames)
    knock(api: GameApi, i: i32, cx: f64, cy: f64, r: f64, hard: f64): void {
        if (hard < 0.9 || api.frame - this.hitF[i] < 5 || api.frame - this.knockF < 3) {
            return;
        }
        this.hitF[i] = api.frame;
        this.knockF = api.frame;
        let v = Math.min(1.0, 0.35 + hard * 0.1);
        if (r == RP) {
            let row = <i32>Math.round((5.5 - cy) / 0.6);
            row = max<i32>(0, min<i32>(6, row));
            api.soundAt(SFX_NOTE, cx, cy, 0, Math.pow(2, (ROW_NOTE[row] - 69) / 12), v * 0.8);
        } else if (r == BOB_R) {
            api.soundAt(SFX_POP, cx, cy, 0, 0.5, 0.9);
        } else {
            api.soundAt(SFX_TICK, cx, cy, 0, 0.8, v);
        }
    }

    stepCoin(api: GameApi, i: i32, h: f64, t: f64): void {
        this.cVY[i] -= G * h;
        this.cX[i] += this.cVX[i] * h;
        this.cY[i] += this.cVY[i] * h;
        let x = this.cX[i], y = this.cY[i];
        for (let p = 0; p < PEG_X.length; p++) {
            if (Math.abs(PEG_X[p] - x) < 0.4 && Math.abs(PEG_Y[p] - y) < 0.4) {
                this.collide(api, i, PEG_X[p], PEG_Y[p], RP, 0, 0, REST);
            }
        }
        this.collide(api, i, PIV_X, PIV_Y, HUB_R, 0, 0, REST);
        // the pendulum's bob: it bats the coin with its own speed
        let w = 2.0 * Math.PI / PERIOD;
        let th = SWING * Math.PI / 180.0 * Math.sin(w * t);
        let om = SWING * Math.PI / 180.0 * w * Math.cos(w * t);
        let bx = PIV_X + ARM * Math.sin(th), by = PIV_Y - ARM * Math.cos(th);
        this.collide(api, i, bx, by, BOB_R, om * ARM * Math.cos(th), om * ARM * Math.sin(th), 0.6);
        for (let k = 0; k < DIV_X.length; k++) {
            let xd = DIV_X[k];
            if (this.cY[i] < DIV_TOP && Math.abs(this.cX[i] - xd) < RC + DIV_HALF) {
                this.cX[i] = xd + (RC + DIV_HALF) * (this.cX[i] > xd ? 1.0 : -1.0);
                this.cVX[i] = -this.cVX[i] * 0.4;
            }
            this.collide(api, i, xd, DIV_TOP, 0.09, 0, 0, REST);
        }
        if (this.cX[i] < -WALL + RC) {
            this.cX[i] = -WALL + RC;
            this.cVX[i] = Math.abs(this.cVX[i]) * 0.5;
        }
        if (this.cX[i] > WALL - RC) {
            this.cX[i] = WALL - RC;
            this.cVX[i] = -Math.abs(this.cVX[i]) * 0.5;
        }
    }

    land(api: GameApi, i: i32): void {
        let x = this.cX[i];
        let c = 0;
        for (let k = 0; k < NCUP; k++) {
            if (x >= EDGE[k] && x < EDGE[k + 1]) {
                c = k;
            }
        }
        let n = this.pile[c];
        this.pile[c] = n + 1;
        let mid = (EDGE[c] + EDGE[c + 1]) * 0.5;
        let col = n % 3, row = n / 3;
        this.cRX[i] = mid + (col == 0 ? -0.26 : (col == 1 ? 0.26 : 0.0)) + api.range(-0.04, 0.04);
        this.cRY[i] = 0.22 + <f64>row * 0.2 + (col == 2 ? 0.12 : 0.0);
        this.cRZ[i] = (col == 2 ? -0.11 : 0.0) - <f64>row * 0.02;
        this.cFromY[i] = this.cY[i];
        this.cSt[i] = C_LAND;
        this.cT[i] = 0;
        let pts = VALUE[c];
        let doubled = c == this.lit;
        if (doubled) {
            pts *= 2;
        }
        this.score += pts;
        // a pop of sparks out of the cup and a rising number
        let burst = pts >= 100 ? 7 : 4;
        for (let s = 0; s < burst; s++) {
            this.spark(api, mid + api.range(-0.3, 0.3), 0.75, api.range(-1.6, 1.6), api.range(2.2, 4.0));
        }
        if (api.project(<f32>mid, <f32>1.25, 0)) {
            this.popX = api.screenX;
            this.popY = api.screenY;
        }
        this.popText = "+" + pts.toString() + (doubled ? " X2" : "");
        this.popBig = pts >= 100;
        this.popT = 0;
        if (pts >= 100) {
            this.shakeT = 0.3;
        }
        if (doubled) {
            this.litT = 0.5;
        }
        // the cup rings by its value: a coin and a bell (10 low .. 100 high), a fifth more when doubled
        let bell = VALUE[c] >= 100 ? 84.0 : (VALUE[c] >= 50 ? 79.0 : (VALUE[c] >= 20 ? 76.0 : 72.0));
        api.soundAt(SFX_COIN, mid, 0.8, 0, Math.pow(2, (bell - 84) / 12), 0.8);
        api.note(bell - 12, 0.6, 0, SFX_BELL);
        if (doubled) {
            api.note(bell - 5, 0.5, 0, SFX_BELL);
        }
        if (pts >= 100) {
            api.sound(SFX_POWERUP, doubled ? 1.5 : 1.0, 0.75);
        }
    }

    spark(api: GameApi, x: f64, y: f64, vx: f64, vy: f64): void {
        let k = this.pNext;
        this.pNext = (this.pNext + 1) % NSPARK;
        this.pT[k] = 0;
        this.pX[k] = x;
        this.pY[k] = y;
        this.pVX[k] = vx;
        this.pVY[k] = vy;
    }

    updateSparks(api: GameApi, dt: f64): void {
        for (let k = 0; k < NSPARK; k++) {
            let b = this.sparkBone[k];
            if (this.pT[k] < 0) {
                api.hide(b);
                continue;
            }
            this.pT[k] += dt;
            this.pVY[k] -= 9.0 * dt;
            this.pX[k] += this.pVX[k] * dt;
            this.pY[k] += this.pVY[k] * dt;
            if (this.pT[k] > 0.6) {
                this.pT[k] = -1;
                api.hide(b);
                continue;
            }
            api.place(b, this.pX[k], this.pY[k], 0.3, 0, 0, 0);
        }
    }

    updateMarker(api: GameApi, dt: f64): void {
        // the lit bulb hovers over the doubled cup; after a doubled landing it pops and moves on
        if (this.litT > 0) {
            this.litT -= dt;
            if (this.litT <= 0) {
                this.lit = this.pickLit(api, this.lit);
            }
        }
        let mid = (EDGE[this.lit] + EDGE[this.lit + 1]) * 0.5;
        let bob = Math.floor(api.time * 4.0) % 2 == 0 ? 0.0 : 0.05;
        let s = 1.0;
        if (this.litT > 0) {
            s = 1.0 + Math.floor(this.litT * 20.0) % 2 * 0.5;
        }
        api.place(this.marker, mid, 1.22 + bob, 0.35, Math.floor(api.time * 4.0) * 45.0, 0, 0, s);
    }

    // ------------------------------------------------------------------ the demo player

    demoThink(api: GameApi, dt: f64): void {
        if (this.state != ST_PLAY) {
            return;
        }
        if (!this.dHasPlan) {
            // a plan for the next coin: mostly the jackpot, sometimes the lit cup, now and then a whim
            let r = api.rand();
            let litMid = (EDGE[this.lit] + EDGE[this.lit + 1]) * 0.5;
            if (r < 0.5) {
                this.dPlanX = api.range(-0.55, 0.55);
            } else if (r < 0.85) {
                this.dPlanX = litMid + api.range(-0.45, 0.45);
            } else {
                this.dPlanX = api.range(-3.4, 3.4);
            }
            this.dPlanX = Math.max(RAIL_MIN, Math.min(RAIL_MAX, this.dPlanX));
            // the first coin goes at once (action in the first second); later ones after a look
            this.dWait = this.left == NCOIN ? 0.25 : api.range(1.1, 2.3);
            this.dHasPlan = true;
        }
        this.tx = this.dPlanX;
        this.dWait -= dt;
        if (this.dWait <= 0 && Math.abs(this.dx - this.dPlanX) < 0.12 && Math.abs(this.dv) < 1.0 && this.reload <= 0) {
            // a careful player waits for the bob to swing away from the middle before a jackpot try
            if (Math.abs(this.dPlanX) < 0.7 && this.left < NCOIN && Math.abs(this.bobX(api.time + 1.2)) < 0.6 && api.rand() < 0.9) {
                return;
            }
            if (this.drop(api)) {
                this.dHasPlan = false;
            }
        }
    }

    // ------------------------------------------------------------------ input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if ((kind == POINTER_DOWN || kind == POINTER_MOVE) && api.pickPlane(x, y, 0, 0, 1, 0)) {
            this.tx = <f64>api.hitX;
        }
        if (kind == POINTER_DOWN) {
            if (this.state == ST_IDLE) {
                api.sound(SFX_WIN, 1.0, 0.6);
                this.beginRun(api);
                this.dx = Math.max(RAIL_MIN, Math.min(RAIL_MAX, this.tx));
                this.dv = 0;
                this.drop(api);
            } else if (this.state == ST_OVER) {
                if (this.stateT > 0.8) {
                    api.sound(SFX_WHOOSH, 0.45, 0.7);      // the coins drain through the tray
                    api.sound(SFX_WIN, 1.0, 0.6);
                    this.beginRun(api);
                }
            } else if (this.state == ST_PLAY && this.reload <= 0) {
                // the coin drops where the press is: the dropper slides there first and drops on
                // arrival (a phone has no hover to lead it; under a mouse it is already there)
                this.dropQ = 0;
            }
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let gold = api.paletteColor(C_GOLD);
        let cream = api.paletteColor(C_CREAM);
        let silver = api.paletteColor(C_SILVER);
        let ink = api.paletteColor(C_INK);
        let plum = api.paletteColor(C_PLUMDK);
        let orange = api.paletteColor(C_ORANGE);
        let pink = api.paletteColor(C_PINK);
        let mint = api.paletteColor(C_MINT);
        let brass = api.paletteColor(C_BRASS);
        let darkbr = api.paletteColor(C_DARKBR);
        // the cups' values on their lips (the lit one blinks X2)
        for (let c = 0; c < NCUP; c++) {
            let mid = (EDGE[c] + EDGE[c + 1]) * 0.5;
            if (!api.project(<f32>mid, 0.3, 0.42)) {
                continue;
            }
            let s = VALUE[c].toString();
            let w = api.textWidth(s, 1);
            let col = c == 3 ? mint : cream;
            api.text(Mathf.round(api.screenX - w * 0.5), Mathf.round(api.screenY), s, col, 1, ink);
            if (c == this.lit && Math.floor(api.time * 3.0) % 3 != 0) {
                if (api.project(<f32>mid, 1.22, 0.35)) {
                    api.text(Mathf.round(api.screenX + 5), Mathf.round(api.screenY - 2), "X2", gold, 1, ink);
                }
            }
        }
        if (this.popT >= 0) {
            let rise = <f32>(Math.floor(this.popT * 12.0) * 1.5);
            let sc = this.popBig ? 2 : 1;
            let w = api.textWidth(this.popText, sc);
            let col = this.popBig && Math.floor(this.popT * 10.0) % 2 == 0 ? cream : gold;
            api.text(Mathf.round(this.popX - w * 0.5), Mathf.round(this.popY - 6 - rise), this.popText, col, sc, ink);
        }
        // score, best, coins left
        api.text(4, 4, this.score.toString(), gold, 2, ink);
        api.text(4, 16, "BEST " + this.best.toString(), silver, 1, ink);
        for (let k = 0; k < NCOIN; k++) {
            let x = <f32>(api.hudW - 8 - k * 6);
            let has = k < this.left;
            api.rect(x, 4, 5, 5, ink);
            api.rect(x + 1, 3, 3, 7, ink);
            api.rect(x - 1, 5, 7, 3, ink);
            api.rect(x, 5, 5, 3, has ? gold : plum);
            api.rect(x + 1, 4, 3, 5, has ? gold : plum);
            if (has) {
                api.rect(x + 1, 5, 1, 1, cream);
            }
        }
        let h = <f32>api.hudH;
        if (this.state == ST_IDLE) {
            let blink = Math.floor(api.time * 2.0) % 2 == 0;
            api.textCentered(30, "CLICK TO DROP A COIN", blink ? gold : cream, 2, ink);
            api.textCentered(44, "MOVE THE DROPPER - 10 COINS - LIT CUP X2", cream, 1, ink);
        } else if (this.state == ST_OVER) {
            let pw: f32 = 120, ph: f32 = 42;
            let px = Mathf.floor((<f32>api.hudW - pw) * 0.5), py = Mathf.floor(h * 0.5 - 30);
            api.rect(px - 1, py - 1, pw + 2, ph + 2, brass);
            api.rect(px, py, pw, ph, plum);
            api.rect(px, py + ph - 2, pw, 2, darkbr);
            api.textCentered(py + 5, "GAME OVER", gold, 2, ink);
            let line = "SCORE " + this.score.toString() + "   BEST " + this.best.toString();
            api.textCentered(py + 20, line, this.score >= this.best && this.score > 0 ? orange : cream, 1, ink);
            if (this.stateT > 0.8 && !api.demo) {
                let blink = Math.floor(api.time * 2.0) % 2 == 0;
                api.textCentered(py + 31, "CLICK TO PLAY AGAIN", blink ? pink : cream, 1, ink);
            }
        }
    }
}
