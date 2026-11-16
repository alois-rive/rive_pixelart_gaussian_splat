// Marble Tilt: a wooden labyrinth box on a table. The board inside tilts towards the pointer (seen
// from the marble), so the marble rolls where you lead it: past the holes, round the rails, into
// the green-rimmed goal. Every goal brings a new layout with one more hole. Three marbles (the
// spares wait in the dish); a marble that drops into a hole is gone. Pointer only; a run starts on
// the first click; demo mode plays itself.
import { GameApi, POINTER_DOWN, POINTER_MOVE, SFX_WIN, SFX_THUD, SFX_TICK, SFX_BLIP, SFX_POP, SFX_SHOOT,
    SFX_LOSE, SFX_POWERUP, SFX_COIN, SFX_WHOOSH, SFX_JUMP } from "./game_api";

const ST_IDLE: i32 = 0;   // before the first click: the marble waits on the start ring
const ST_DROP: i32 = 1;   // a marble falls onto the start ring
const ST_ROLL: i32 = 2;   // playing
const ST_FALL: i32 = 3;   // the marble drops into a hole
const ST_GOAL: i32 = 4;   // the marble sinks into the goal, confetti
const ST_SWAP: i32 = 5;   // the old layout sinks, the new one rises
const ST_OVER: i32 = 6;

const NWALL: i32 = 10;
const NHOLE: i32 = 10;
const NSPARK: i32 = 8;
const NLIFE: i32 = 3;
const MARBLES: i32 = 3;         // per run: one on the board, two in the dish

const FLOOR_Y: f64 = 1.188;     // the floor's top (its bake position)
const R: f64 = 0.26;            // the marble's radius
const HALF_U: f64 = 4.0;        // the floor's half size inside the frame
const HALF_V: f64 = 2.65;
const WALL_L: f64 = 2.0;        // a rail: 2.0 x 0.26 (x 0.45 tall)
const WALL_T: f64 = 0.26;
const HOLE_FALL: f64 = 0.3;     // the marble's centre this near a hole's centre: it drops in
const HOLE_PULL: f64 = 0.72;    // the rim slopes in: a pull towards the hole inside this radius
const GOAL_IN: f64 = 0.34;
const MAX_TILT: f64 = 5.0;      // degrees
const ACCEL: f64 = 3.2;         // m/s^2 at full tilt
const GAIN: f64 = 0.95;         // tilt per metre between the marble and the pointer
const DAMP: f64 = 0.32;         // tilt per m/s of the marble's speed (the hand steadies it)

const GRID: f64 = 0.2;          // the demo's path grid
const GW: i32 = 40;
const GH: i32 = 27;

// palette indices (art/palette.json "colors")
const C_CREAM: i32 = 0;
const C_HONEY: i32 = 1;
const C_MAUVE: i32 = 3;
const C_PLUM: i32 = 4;
const C_OLIVE: i32 = 7;
const C_SKY: i32 = 8;
const C_BLUE: i32 = 9;
const C_RED: i32 = 13;

export class Game {
    state: i32 = ST_IDLE;
    stateT: f64 = 0;
    round: i32 = 0;
    score: i32 = 0;
    best: i32 = 0;
    marbles: i32 = MARBLES;
    wasDemo: bool = false;
    runT: f64 = 0;

    // bones
    floor: i32 = -1;
    knobF: i32 = -1;
    knobR: i32 = -1;
    goalB: i32 = -1;
    startB: i32 = -1;
    marble: i32 = -1;
    wallB: StaticArray<i32> = new StaticArray<i32>(NWALL);
    holeB: StaticArray<i32> = new StaticArray<i32>(NHOLE);
    sparkB: StaticArray<i32> = new StaticArray<i32>(NSPARK);
    lifeB: StaticArray<i32> = new StaticArray<i32>(NLIFE);

    // the layout (board coordinates: u along x, v along z, metres from the floor's centre)
    nWall: i32 = 0;
    wU: StaticArray<f64> = new StaticArray<f64>(NWALL);
    wV: StaticArray<f64> = new StaticArray<f64>(NWALL);
    wVert: StaticArray<bool> = new StaticArray<bool>(NWALL);
    nHole: i32 = 0;
    hU: StaticArray<f64> = new StaticArray<f64>(NHOLE);
    hV: StaticArray<f64> = new StaticArray<f64>(NHOLE);
    startU: f64 = -3.2;
    startV: f64 = 0;
    goalU: f64 = 3.2;
    goalV: f64 = 0;
    // the previous layout, sinking during a swap
    oWall: i32 = 0;
    oWU: StaticArray<f64> = new StaticArray<f64>(NWALL);
    oWV: StaticArray<f64> = new StaticArray<f64>(NWALL);
    oWVert: StaticArray<bool> = new StaticArray<bool>(NWALL);
    oHole: i32 = 0;
    oHU: StaticArray<f64> = new StaticArray<f64>(NHOLE);
    oHV: StaticArray<f64> = new StaticArray<f64>(NHOLE);
    oGoalU: f64 = 0;
    oGoalV: f64 = 0;
    oStartU: f64 = 0;
    oStartV: f64 = 0;
    rise: f64 = 0;          // 0..1: how far the current layout has risen out of the floor
    sink: f64 = 1;          // 1..0: the old layout during a swap

    // the marble
    mu: f64 = -3.2;
    mv: f64 = 0;
    mh: f64 = 0;            // height above its resting height (drops, sinking)
    mvu: f64 = 0;
    mvv: f64 = 0;
    mvh: f64 = 0;
    fallU: f64 = 0;
    fallV: f64 = 0;
    // its orientation (rows of a rotation matrix), rolled by its motion
    m00: f64 = 1; m01: f64 = 0; m02: f64 = 0;
    m10: f64 = 0; m11: f64 = 1; m12: f64 = 0;
    m20: f64 = 0; m21: f64 = 0; m22: f64 = 1;

    // the board's tilt: fractions of MAX_TILT, towards +u (right) and +v (front)
    tiltU: f64 = 0;
    tiltV: f64 = 0;
    aimU: f64 = 0;          // where the player (or the demo) leads the marble
    aimV: f64 = 0;
    hasAim: bool = false;

    // juice
    pT: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pZ: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pVX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pVY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pVZ: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    popT: f64 = -1;
    popText: string = "";
    popX: f32 = 0;
    popY: f32 = 0;
    flagT: f64 = -1;
    lifeT: f64 = -1;        // a spare marble leaving the dish
    lifeIdx: i32 = -1;
    nearMiss: f64 = 0;
    // sound (never decided by api.rand: the demo stays the same)
    sClack: i32 = -100;     // the frame of the last rail clack (sparse: one per 5 frames at most)
    sBest: bool = false;    // a new best to cheer once the game-over sting has played

    // the demo player
    dist: StaticArray<i32> = new StaticArray<i32>(GW * GH);
    queue: StaticArray<i32> = new StaticArray<i32>(GW * GH);
    dAimU: f64 = 0;
    dAimV: f64 = 0;
    dErrU: f64 = 0;
    dErrV: f64 = 0;
    dThink: f64 = 0;
    dRush: f64 = 0;
    dLook: i32 = 5;

    start(api: GameApi): void {
        api.playable = true;
        this.floor = api.bone("floor");
        this.knobF = api.bone("knobF");
        this.knobR = api.bone("knobR");
        this.goalB = api.bone("goal");
        this.startB = api.bone("start");
        this.marble = api.bone("marble");
        for (let i = 0; i < NWALL; i++) {
            this.wallB[i] = api.bone("wall" + i.toString());
        }
        for (let i = 0; i < NHOLE; i++) {
            this.holeB[i] = api.bone("hole" + i.toString());
        }
        for (let i = 0; i < NSPARK; i++) {
            this.sparkB[i] = api.bone("spark" + i.toString());
            this.pT[i] = -1;
        }
        for (let i = 0; i < NLIFE; i++) {
            this.lifeB[i] = api.bone("life" + i.toString());
        }
        this.wasDemo = api.demo;
        this.resetRun(api);
        if (api.demo) {
            this.beginRun(api);
        }
    }

    // ------------------------------------------------------------------ run control

    resetRun(api: GameApi): void {
        this.round = 0;
        this.score = 0;
        this.marbles = MARBLES;
        this.runT = 0;
        this.oWall = 0;
        this.oHole = 0;
        this.makeLayout(api);
        this.rise = 1;
        this.sink = 0;
        this.mu = this.startU;
        this.mv = this.startV;
        this.mh = 0;
        this.mvu = 0; this.mvv = 0; this.mvh = 0;
        this.tiltU = 0; this.tiltV = 0;
        this.lifeT = -1;
        this.state = ST_IDLE;
        this.stateT = 0;
    }

    beginRun(api: GameApi): void {
        if (this.state == ST_OVER) {
            this.resetRun(api);
        }
        api.sound(SFX_WIN, 1.0, 0.6);
        this.dropMarble();
    }

    dropMarble(): void {
        this.state = ST_DROP;
        this.stateT = 0;
        this.mu = this.startU;
        this.mv = this.startV;
        this.mh = 2.6;
        this.mvh = 0;
        this.mvu = 0;
        this.mvv = 0;
        this.dThink = 0;
    }

    endRun(): void {
        this.state = ST_OVER;
        this.stateT = 0;
        if (this.score > this.best) {
            this.best = this.score;
        }
    }

    // ------------------------------------------------------------------ layouts

    // A new layout for this round: the start on one side, the goal on the other, rails, then holes,
    // kept only when the demo's path finder can still get from the start to the goal.
    makeLayout(api: GameApi): void {
        let side = this.round % 2 == 0 ? 1.0 : -1.0;
        for (let attempt = 0; attempt < 8; attempt++) {
            this.startU = -3.3 * side;
            this.startV = api.range(-1.7, 1.7);
            this.goalU = 3.3 * side;
            this.goalV = api.range(-1.7, 1.7);
            // rails: 1 to 5 of them, more as the rounds go
            let nw = min<i32>(1 + this.round / 2 + <i32>Math.floor(api.rand() * 2.0), 5);
            this.nWall = 0;
            for (let k = 0; k < nw * 6 && this.nWall < nw; k++) {
                let vert = api.rand() < 0.6;
                let u: f64, v: f64;
                if (vert) {
                    u = Math.round(api.range(-2.2, 2.2) / 0.55) * 0.55;
                    v = api.rand() < 0.5 ? -HALF_V + WALL_L * 0.5 : HALF_V - WALL_L * 0.5;
                    if (api.rand() < 0.25) {
                        v = 0;
                    }
                } else {
                    u = Math.round(api.range(-1.8, 1.8) / 0.5) * 0.5;
                    v = Math.round(api.range(-1.4, 1.4) / 0.7) * 0.7;
                }
                if (this.nearPoint(u, v, vert, this.startU, this.startV) < 0.9 ||
                    this.nearPoint(u, v, vert, this.goalU, this.goalV) < 0.9) {
                    continue;
                }
                let clash = false;
                for (let j = 0; j < this.nWall; j++) {
                    let du = Math.abs(this.wU[j] - u), dv = Math.abs(this.wV[j] - v);
                    if (du < 1.3 && dv < 1.3) {
                        clash = true;
                    }
                }
                if (clash) {
                    continue;
                }
                this.wU[this.nWall] = u;
                this.wV[this.nWall] = v;
                this.wVert[this.nWall] = vert;
                this.nWall++;
            }
            // holes: three, one more each round, up to ten
            let nh = min<i32>(3 + this.round, 9);
            this.nHole = 0;
            for (let k = 0; k < nh * 12 && this.nHole < nh; k++) {
                let u = api.range(-3.5, 3.5), v = api.range(-2.2, 2.2);
                let ds = Math.hypot(u - this.startU, v - this.startV);
                let dg = Math.hypot(u - this.goalU, v - this.goalV);
                if (ds < 1.25 || dg < 1.1) {
                    continue;
                }
                let ok = true;
                for (let j = 0; j < this.nWall; j++) {
                    if (this.nearPoint(this.wU[j], this.wV[j], this.wVert[j], u, v) < 0.62) {
                        ok = false;
                    }
                }
                for (let j = 0; j < this.nHole; j++) {
                    if (Math.hypot(u - this.hU[j], v - this.hV[j]) < 1.15) {
                        ok = false;
                    }
                }
                if (!ok) {
                    continue;
                }
                this.hU[this.nHole] = u;
                this.hV[this.nHole] = v;
                this.nHole++;
            }
            this.buildField();
            if (this.fieldAt(this.startU, this.startV) >= 0) {
                return;
            }
        }
        // no solvable layout in a few tries (a frame has 200 ms of script): drop holes until it is
        while (this.nHole > 0) {
            this.nHole--;
            this.buildField();
            if (this.fieldAt(this.startU, this.startV) >= 0) {
                return;
            }
        }
    }

    // the distance from a point to a rail's box (0 inside)
    nearPoint(wu: f64, wv: f64, vert: bool, u: f64, v: f64): f64 {
        let hu = vert ? WALL_T * 0.5 : WALL_L * 0.5;
        let hv = vert ? WALL_L * 0.5 : WALL_T * 0.5;
        let dx = Math.max(0.0, Math.abs(u - wu) - hu);
        let dy = Math.max(0.0, Math.abs(v - wv) - hv);
        return Math.sqrt(dx * dx + dy * dy);
    }

    cellFree(u: f64, v: f64): bool {
        if (Math.abs(u) > HALF_U - R - 0.05 || Math.abs(v) > HALF_V - R - 0.05) {
            return false;
        }
        for (let j = 0; j < this.nWall; j++) {
            if (this.nearPoint(this.wU[j], this.wV[j], this.wVert[j], u, v) < R + 0.1) {
                return false;
            }
        }
        let c = HOLE_FALL + 0.3;
        for (let j = 0; j < this.nHole; j++) {
            let du = u - this.hU[j], dv = v - this.hV[j];
            if (du * du + dv * dv < c * c) {
                return false;
            }
        }
        return true;
    }

    // breadth-first steps from the goal to every free cell (-1: blocked or unreachable)
    buildField(): void {
        for (let i = 0; i < GW * GH; i++) {
            this.dist[i] = -2;
        }
        for (let gy = 0; gy < GH; gy++) {
            for (let gx = 0; gx < GW; gx++) {
                let u = -HALF_U + (<f64>gx + 0.5) * GRID, v = -HALF_V + (<f64>gy + 0.5) * GRID;
                if (this.cellFree(u, v)) {
                    this.dist[gy * GW + gx] = -1;
                }
            }
        }
        let g = this.cellOf(this.goalU, this.goalV);
        let head = 0, tail = 0;
        this.dist[g] = 0;
        this.queue[tail++] = g;
        while (head < tail) {
            let c = this.queue[head++];
            let cx = c % GW, cy = c / GW;
            let d = this.dist[c] + 1;
            for (let k = 0; k < 4; k++) {
                let nx = cx + (k == 0 ? 1 : (k == 1 ? -1 : 0));
                let ny = cy + (k == 2 ? 1 : (k == 3 ? -1 : 0));
                if (nx < 0 || ny < 0 || nx >= GW || ny >= GH) {
                    continue;
                }
                let n = ny * GW + nx;
                if (this.dist[n] == -1) {
                    this.dist[n] = d;
                    this.queue[tail++] = n;
                }
            }
        }
    }

    cellOf(u: f64, v: f64): i32 {
        let gx = <i32>Math.floor((u + HALF_U) / GRID);
        let gy = <i32>Math.floor((v + HALF_V) / GRID);
        gx = max<i32>(0, min<i32>(GW - 1, gx));
        gy = max<i32>(0, min<i32>(GH - 1, gy));
        return gy * GW + gx;
    }

    fieldAt(u: f64, v: f64): i32 {
        return this.dist[this.cellOf(u, v)];
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged || api.demo != this.wasDemo) {
            // the host switched demo off (a visitor took over) or on: a fresh run either way
            this.wasDemo = api.demo;
            this.resetRun(api);
            this.beginRun(api);
        }
        this.stateT += dt;
        if (this.state != ST_IDLE && this.state != ST_OVER) {
            this.runT += dt;
        }
        if (api.demo) {
            this.demoThink(api, dt);
            if (this.state == ST_OVER && this.stateT > 2.0) {
                this.beginRun(api);
            }
        }
        this.updateTilt(dt);
        this.updateMarble(api, dt);
        this.updateSparks(dt);
        if (this.popT >= 0) {
            this.popT += dt;
            if (this.popT > 1.0) {
                this.popT = -1;
            }
        }
        if (this.nearMiss > 0) {
            this.nearMiss -= dt;
        }
        if (this.sBest && this.state == ST_OVER && this.stateT > 0.9) {
            this.sBest = false;
            api.sound(SFX_POWERUP, 1.0, 0.6);
        }
        this.pose(api);
    }

    updateTilt(dt: f64): void {
        let tu = 0.0, tv = 0.0;
        if (this.state == ST_ROLL && this.hasAim) {
            tu = (this.aimU - this.mu) * GAIN - this.mvu * DAMP;
            tv = (this.aimV - this.mv) * GAIN - this.mvv * DAMP;
            let m = Math.hypot(tu, tv);
            if (m > 1) {
                tu /= m;
                tv /= m;
            }
        }
        // a hand on the knobs: the tilt follows at a limited rate
        let rate = 3.2 * dt;
        this.tiltU += Math.max(-rate, Math.min(rate, tu - this.tiltU));
        this.tiltV += Math.max(-rate, Math.min(rate, tv - this.tiltV));
    }

    updateMarble(api: GameApi, dt: f64): void {
        let st = this.state;
        if (st == ST_IDLE) {
            this.mh = 0;
            return;
        }
        if (st == ST_DROP) {
            // falls onto the start ring and bounces twice
            this.mvh -= 22.0 * dt;
            this.mh += this.mvh * dt;
            if (this.mh <= 0) {
                this.mh = 0;
                // glass on wood: a knock and a click, softer each bounce
                let hit = Math.min(1.0, -this.mvh / 10.0);
                if (hit > 0.08) {
                    api.soundAt(SFX_THUD, this.mu, FLOOR_Y, this.mv, 1.3, 0.35 + 0.6 * hit);
                    api.soundAt(SFX_TICK, this.mu, FLOOR_Y, this.mv, 0.55, 0.4 + 0.5 * hit);
                }
                if (this.mvh < -2.5) {
                    this.mvh = -this.mvh * 0.32;
                } else {
                    this.mvh = 0;
                    this.state = ST_ROLL;
                    this.stateT = 0;
                }
            }
            return;
        }
        if (st == ST_FALL) {
            // into the hole: slides to its middle and sinks under the floor
            let k = Math.min(1.0, this.stateT / 0.18);
            this.mu += (this.fallU - this.mu) * k;
            this.mv += (this.fallV - this.mv) * k;
            this.mh = -Math.min(0.75, this.stateT * this.stateT * 9.0);
            if (this.stateT > 1.0) {
                this.marbles--;
                if (this.marbles <= 0) {
                    this.sBest = this.score > this.best && this.score > 0;
                    api.sound(SFX_LOSE, 1.0, 0.8);
                    this.endRun();
                } else {
                    // the next marble leaves the dish
                    api.sound(SFX_JUMP, 1.25, 0.5, -0.5);
                    this.lifeIdx = this.marbles - 1;
                    this.lifeT = 0;
                    this.dropMarble();
                }
            }
            return;
        }
        if (st == ST_GOAL) {
            let k = Math.min(1.0, this.stateT / 0.15);
            this.mu += (this.goalU - this.mu) * k;
            this.mv += (this.goalV - this.mv) * k;
            this.mh = -Math.min(0.75, this.stateT * this.stateT * 7.0);
            if (this.stateT > 0.9) {
                this.startSwap(api);
            }
            return;
        }
        if (st == ST_SWAP) {
            // the old layout sinks (0.35 s), the new one rises (0.35 s), then the next marble drops
            this.sink = Math.max(0.0, 1.0 - this.stateT / 0.35);
            this.rise = Math.max(0.0, Math.min(1.0, (this.stateT - 0.35) / 0.35));
            if (this.stateT > 0.8) {
                this.sink = 0;
                this.rise = 1;
                this.oWall = 0;
                this.oHole = 0;
                this.dropMarble();
            }
            return;
        }
        if (st == ST_OVER) {
            return;
        }
        // ST_ROLL: the tilt accelerates it, the hole rims pull it in, rails and the frame bounce it
        let au = this.tiltU * ACCEL, av = this.tiltV * ACCEL;
        for (let j = 0; j < this.nHole; j++) {
            let du = this.hU[j] - this.mu, dv = this.hV[j] - this.mv;
            let d = Math.hypot(du, dv);
            if (d < HOLE_PULL && d > 0.001) {
                let pull = 2.2 * (1.0 - d / HOLE_PULL);
                au += du / d * pull;
                av += dv / d * pull;
            }
        }
        this.mvu += au * dt;
        this.mvv += av * dt;
        let fr = Math.max(0.0, 1.0 - 0.45 * dt);
        this.mvu *= fr;
        this.mvv *= fr;
        let sp = Math.hypot(this.mvu, this.mvv);
        if (sp > 4.5) {
            this.mvu *= 4.5 / sp;
            this.mvv *= 4.5 / sp;
        }
        let ou = this.mu, ov = this.mv;
        this.mu += this.mvu * dt;
        this.mv += this.mvv * dt;
        // the frame
        let lu = HALF_U - R, lv = HALF_V - R;
        let imp = 0.0;  // the hardest knock this frame, for the clack
        if (this.mu > lu) { imp = Math.max(imp, Math.abs(this.mvu)); this.mu = lu; this.mvu = -Math.abs(this.mvu) * 0.35; }
        if (this.mu < -lu) { imp = Math.max(imp, Math.abs(this.mvu)); this.mu = -lu; this.mvu = Math.abs(this.mvu) * 0.35; }
        if (this.mv > lv) { imp = Math.max(imp, Math.abs(this.mvv)); this.mv = lv; this.mvv = -Math.abs(this.mvv) * 0.35; }
        if (this.mv < -lv) { imp = Math.max(imp, Math.abs(this.mvv)); this.mv = -lv; this.mvv = Math.abs(this.mvv) * 0.35; }
        // the rails
        for (let j = 0; j < this.nWall; j++) {
            let hu = this.wVert[j] ? WALL_T * 0.5 : WALL_L * 0.5;
            let hv = this.wVert[j] ? WALL_L * 0.5 : WALL_T * 0.5;
            let cu = Math.max(this.wU[j] - hu, Math.min(this.wU[j] + hu, this.mu));
            let cv = Math.max(this.wV[j] - hv, Math.min(this.wV[j] + hv, this.mv));
            let du = this.mu - cu, dv = this.mv - cv;
            let d = Math.hypot(du, dv);
            if (d < R) {
                let nu: f64, nv: f64;
                if (d > 0.0001) {
                    nu = du / d; nv = dv / d;
                } else {
                    nu = this.mu > this.wU[j] ? 1.0 : -1.0; nv = 0;
                }
                this.mu = cu + nu * R;
                this.mv = cv + nv * R;
                let vn = this.mvu * nu + this.mvv * nv;
                if (vn < 0) {
                    imp = Math.max(imp, -vn);
                    this.mvu -= 1.35 * vn * nu;
                    this.mvv -= 1.35 * vn * nv;
                }
            }
        }
        this.roll(this.mu - ou, this.mv - ov);
        // a clack against a rail or the frame: harder knocks ring higher and louder
        if (imp > 0.7 && api.frame - this.sClack >= 5) {
            this.sClack = api.frame;
            let k = Math.min(1.0, imp / 4.0);
            api.soundAt(SFX_TICK, this.mu, FLOOR_Y, this.mv, 0.45 + 0.35 * k, 0.45 + 0.5 * k);
            api.soundAt(SFX_THUD, this.mu, FLOOR_Y, this.mv, 1.8, 0.25 + 0.35 * k);
        }
        // the goal
        if (Math.hypot(this.mu - this.goalU, this.mv - this.goalV) < GOAL_IN) {
            this.scoreGoal(api);
            return;
        }
        // the holes
        for (let j = 0; j < this.nHole; j++) {
            let d = Math.hypot(this.mu - this.hU[j], this.mv - this.hV[j]);
            if (d < HOLE_FALL) {
                this.state = ST_FALL;
                this.stateT = 0;
                this.fallU = this.hU[j];
                this.fallV = this.hV[j];
                this.burst(api, this.hU[j], this.hV[j], 3, 0.6);
                // plop, and the marble rattling away under the board
                api.soundAt(SFX_POP, this.hU[j], FLOOR_Y, this.hV[j], 0.45, 1.0);
                api.soundAt(SFX_SHOOT, this.hU[j], FLOOR_Y, this.hV[j], 0.4, 0.5);
                if (api.project(<f32>this.hU[j], <f32>(FLOOR_Y + 0.6), <f32>this.hV[j])) {
                    this.popX = api.screenX;
                    this.popY = api.screenY;
                    this.popText = this.marbles > 1 ? "PLOP!" : "OH NO!";
                    this.popT = 0;
                }
                return;
            }
            if (d < 0.5) {
                if (this.nearMiss <= 0) {
                    // teetering on a rim: a low warning blip
                    api.soundAt(SFX_BLIP, this.mu, FLOOR_Y, this.mv, 0.5, 0.45);
                }
                this.nearMiss = 0.6;
            }
        }
    }

    scoreGoal(api: GameApi): void {
        this.state = ST_GOAL;
        this.stateT = 0;
        this.score++;
        this.flagT = 0;
        // each goal of the run a step up the major scale, and the confetti pops
        let step = min<i32>(this.score - 1, 7);
        let semis = step == 0 ? 0 : (step == 1 ? 2 : (step == 2 ? 4 : (step == 3 ? 5 : (step == 4 ? 7 : (step == 5 ? 9 : (step == 6 ? 11 : 12))))));
        api.soundAt(SFX_COIN, this.goalU, FLOOR_Y, this.goalV, Math.pow(2, <f64>semis / 12), 0.8);
        api.soundAt(SFX_POP, this.goalU, FLOOR_Y, this.goalV, 1.4, 0.5);
        this.burst(api, this.goalU, this.goalV, NSPARK, 1.0);
        if (api.project(<f32>this.goalU, <f32>(FLOOR_Y + 1.9), <f32>this.goalV)) {
            this.popX = api.screenX;
            this.popY = api.screenY;
            this.popText = "GOAL!";
            this.popT = 0;
        }
    }

    startSwap(api: GameApi): void {
        // keep the old layout to sink it, make the next one
        this.oWall = this.nWall;
        for (let j = 0; j < this.nWall; j++) {
            this.oWU[j] = this.wU[j]; this.oWV[j] = this.wV[j]; this.oWVert[j] = this.wVert[j];
        }
        this.oHole = this.nHole;
        for (let j = 0; j < this.nHole; j++) {
            this.oHU[j] = this.hU[j]; this.oHV[j] = this.hV[j];
        }
        this.oGoalU = this.goalU; this.oGoalV = this.goalV;
        this.oStartU = this.startU; this.oStartV = this.startV;
        this.round++;
        this.makeLayout(api);
        api.sound(SFX_WHOOSH, 0.6, 0.6);
        this.state = ST_SWAP;
        this.stateT = 0;
        this.sink = 1;
        this.rise = 0;
        this.mh = -2;
    }

    // rolls the marble's orientation by a displacement on the board
    roll(du: f64, dv: f64): void {
        let d = Math.hypot(du, dv);
        if (d < 1e-6) {
            return;
        }
        // axis = up x direction = (dv, 0, -du) / d, angle = d / R
        let ax = dv / d, az = -du / d;
        let a = d / R;
        let c = Math.cos(a), s = Math.sin(a), t = 1 - c;
        // Rodrigues with ay = 0
        let r00 = t * ax * ax + c, r01 = -s * az, r02 = t * ax * az;
        let r10 = s * az, r11 = c, r12 = -s * ax;
        let r20 = t * ax * az, r21 = s * ax, r22 = t * az * az + c;
        let n00 = r00 * this.m00 + r01 * this.m10 + r02 * this.m20;
        let n01 = r00 * this.m01 + r01 * this.m11 + r02 * this.m21;
        let n02 = r00 * this.m02 + r01 * this.m12 + r02 * this.m22;
        let n10 = r10 * this.m00 + r11 * this.m10 + r12 * this.m20;
        let n11 = r10 * this.m01 + r11 * this.m11 + r12 * this.m21;
        let n12 = r10 * this.m02 + r11 * this.m12 + r12 * this.m22;
        let n20 = r20 * this.m00 + r21 * this.m10 + r22 * this.m20;
        let n21 = r20 * this.m01 + r21 * this.m11 + r22 * this.m21;
        let n22 = r20 * this.m02 + r21 * this.m12 + r22 * this.m22;
        // re-orthonormalise (rows 0 and 1, row 2 their cross product)
        let l0 = Math.sqrt(n00 * n00 + n01 * n01 + n02 * n02);
        n00 /= l0; n01 /= l0; n02 /= l0;
        let dp = n10 * n00 + n11 * n01 + n12 * n02;
        n10 -= dp * n00; n11 -= dp * n01; n12 -= dp * n02;
        let l1 = Math.sqrt(n10 * n10 + n11 * n11 + n12 * n12);
        n10 /= l1; n11 /= l1; n12 /= l1;
        this.m00 = n00; this.m01 = n01; this.m02 = n02;
        this.m10 = n10; this.m11 = n11; this.m12 = n12;
        this.m20 = n01 * n12 - n02 * n11;
        this.m21 = n02 * n10 - n00 * n12;
        this.m22 = n00 * n11 - n01 * n10;
    }

    burst(api: GameApi, u: f64, v: f64, n: i32, power: f64): void {
        let made = 0;
        for (let i = 0; i < NSPARK && made < n; i++) {
            if (this.pT[i] >= 0) {
                continue;
            }
            let a = api.range(0, Math.PI * 2);
            let sp = api.range(1.0, 2.2) * power;
            this.pT[i] = 0;
            this.pX[i] = u;
            this.pY[i] = FLOOR_Y + 0.4;
            this.pZ[i] = v;
            this.pVX[i] = Math.cos(a) * sp;
            this.pVZ[i] = Math.sin(a) * sp;
            this.pVY[i] = api.range(3.5, 5.5) * power;
            made++;
        }
    }

    updateSparks(dt: f64): void {
        for (let i = 0; i < NSPARK; i++) {
            if (this.pT[i] < 0) {
                continue;
            }
            this.pT[i] += dt;
            this.pVY[i] -= 12.0 * dt;
            this.pX[i] += this.pVX[i] * dt;
            this.pY[i] += this.pVY[i] * dt;
            this.pZ[i] += this.pVZ[i] * dt;
            if (this.pT[i] > 0.9 || this.pY[i] < FLOOR_Y + 0.05) {
                this.pT[i] = -1;
            }
        }
    }

    // ------------------------------------------------------------------ the demo player

    demoThink(api: GameApi, dt: f64): void {
        if (this.state != ST_ROLL) {
            this.hasAim = false;
            return;
        }
        this.dThink -= dt;
        if (this.dThink <= 0) {
            // re-decide 6 times a second: follow the path a few cells ahead, with a little error;
            // now and then hurry (looks further ahead, more speed, more risk)
            this.dThink = api.range(0.12, 0.2);
            if (api.rand() < 0.05) {
                this.dRush = api.range(0.8, 1.6);
            }
            let err = this.dRush > 0 ? 0.42 : 0.16;
            this.dErrU = api.range(-err, err);
            this.dErrV = api.range(-err, err);
            this.dLook = this.dRush > 0 ? 9 : 5;
            // walk the field downhill from the marble's cell
            let c = this.cellOf(this.mu, this.mv);
            if (this.dist[c] < 0) {
                // off the field (next to a rail or a hole): the nearest good cell
                let bestD = 1e9, bestC = -1;
                for (let k = 0; k < GW * GH; k++) {
                    if (this.dist[k] < 0) {
                        continue;
                    }
                    let u = -HALF_U + (<f64>(k % GW) + 0.5) * GRID, v = -HALF_V + (<f64>(k / GW) + 0.5) * GRID;
                    let d = Math.hypot(u - this.mu, v - this.mv);
                    if (d < bestD) {
                        bestD = d;
                        bestC = k;
                    }
                }
                c = bestC;
            }
            if (c >= 0) {
                for (let s = 0; s < this.dLook; s++) {
                    let cx = c % GW, cy = c / GW;
                    let best = c, bd = this.dist[c];
                    for (let k = 0; k < 4; k++) {
                        let nx = cx + (k == 0 ? 1 : (k == 1 ? -1 : 0));
                        let ny = cy + (k == 2 ? 1 : (k == 3 ? -1 : 0));
                        if (nx < 0 || ny < 0 || nx >= GW || ny >= GH) {
                            continue;
                        }
                        let n = ny * GW + nx;
                        if (this.dist[n] >= 0 && this.dist[n] < bd) {
                            bd = this.dist[n];
                            best = n;
                        }
                    }
                    c = best;
                }
                this.dAimU = -HALF_U + (<f64>(c % GW) + 0.5) * GRID;
                this.dAimV = -HALF_V + (<f64>(c / GW) + 0.5) * GRID;
            }
        }
        if (this.dRush > 0) {
            this.dRush -= dt;
        }
        this.aimU = this.dAimU + this.dErrU;
        this.aimV = this.dAimV + this.dErrV;
        if (this.dist[this.cellOf(this.mu, this.mv)] >= 0 && this.dist[this.cellOf(this.mu, this.mv)] < 4) {
            this.aimU = this.goalU;
            this.aimV = this.goalV;
        }
        this.hasAim = true;
    }

    // ------------------------------------------------------------------ pointer

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.state == ST_IDLE) {
                this.beginRun(api);
            } else if (this.state == ST_OVER && this.stateT > 0.6) {
                this.beginRun(api);
            }
        }
        if (kind == POINTER_DOWN || kind == POINTER_MOVE) {
            if (api.pick(x, y, <f32>(FLOOR_Y + R))) {
                this.aimU = <f64>api.hitX;
                this.aimV = <f64>api.hitZ;
                this.hasAim = true;
            }
        }
        return true;
    }

    // ------------------------------------------------------------------ posing the bones

    // places an object lying on the tilted floor at board point (u, h, v)
    onFloor(api: GameApi, b: i32, u: f64, h: f64, v: f64, yaw: f64, pitch: f64, roll: f64): void {
        api.transform(this.floor, u, FLOOR_Y + h, v);
        if (yaw == 0) {
            api.place(b, api.tx, api.ty, api.tz, 0, pitch, roll);
        } else {
            // a rail turned 90 degrees: the floor's tilt seen in the rail's own frame
            api.place(b, api.tx, api.ty, api.tz, 90, -roll, pitch);
        }
    }

    pose(api: GameApi): void {
        // the floor tilts in steps of half a degree (stepped like hand animation; fewer re-rasterised frames)
        let pitch = Math.round(this.tiltV * MAX_TILT * 2.0) / 2.0;    // +v (front) goes down
        let roll = -Math.round(this.tiltU * MAX_TILT * 2.0) / 2.0;    // +u (right) goes down
        api.place(this.floor, 0, FLOOR_Y, 0, 0, pitch, roll);
        // the knobs turn with the tilt (geared up: a quarter turn at full tilt)
        api.place(this.knobF, api.restX[this.knobF], api.restY[this.knobF], api.restZ[this.knobF], 0, 0, roll * 18.0);
        api.place(this.knobR, api.restX[this.knobR], api.restY[this.knobR], api.restZ[this.knobR], 90, 0, -pitch * 18.0);
        // the layout: rails and holes rise out of the floor (stepped), the old ones sink
        let up = Math.floor(this.rise * 6.0) / 6.0;
        let down = Math.floor(this.sink * 6.0) / 6.0;
        let wi = 0;
        for (let j = 0; j < this.nWall && wi < NWALL; j++) {
            this.onFloor(api, this.wallB[wi++], this.wU[j], -0.5 * (1.0 - up), this.wV[j], this.wVert[j] ? 90.0 : 0.0, pitch, roll);
        }
        for (let j = 0; j < this.oWall && wi < NWALL && down > 0; j++) {
            this.onFloor(api, this.wallB[wi++], this.oWU[j], -0.5 * (1.0 - down), this.oWV[j], this.oWVert[j] ? 90.0 : 0.0, pitch, roll);
        }
        while (wi < NWALL) {
            api.hide(this.wallB[wi++]);
        }
        let hi = 0;
        for (let j = 0; j < this.nHole && hi < NHOLE; j++) {
            let s = 0.25 + 0.75 * up;
            api.transform(this.floor, this.hU[j], FLOOR_Y + 0.0, this.hV[j]);
            if (up <= 0) {
                api.hide(this.holeB[hi++]);
            } else {
                api.place(this.holeB[hi++], api.tx, api.ty, api.tz, 0, pitch, roll, s);
            }
        }
        // the old holes close up during a swap (only while the pool has room)
        for (let j = 0; j < this.oHole && hi < NHOLE && down > 0; j++) {
            api.transform(this.floor, this.oHU[j], FLOOR_Y, this.oHV[j]);
            api.place(this.holeB[hi++], api.tx, api.ty, api.tz, 0, pitch, roll, 0.25 + 0.75 * down);
        }
        while (hi < NHOLE) {
            api.hide(this.holeB[hi++]);
        }
        // goal and start: the old ones until the swap's middle, then the new ones grow in
        let swapping = this.state == ST_SWAP && this.stateT < 0.35;
        let gu = swapping ? this.oGoalU : this.goalU, gv = swapping ? this.oGoalV : this.goalV;
        let su = swapping ? this.oStartU : this.startU, sv = swapping ? this.oStartV : this.startV;
        let gs = swapping ? 0.3 + 0.7 * down : (this.state == ST_SWAP ? 0.3 + 0.7 * up : 1.0);
        // the flag bounces when the marble drops in
        let fs = 1.0;
        if (this.flagT >= 0) {
            this.flagT += api.dt;
            let k = Math.floor(this.flagT * 12.0) / 12.0;
            fs = 1.0 + 0.35 * Math.sin(k * 14.0) * Math.max(0.0, 1.0 - k / 0.8);
            if (this.flagT > 0.8) {
                this.flagT = -1;
            }
        }
        api.transform(this.floor, gu, FLOOR_Y, gv);
        let wave = Math.floor(api.time * 6.0) % 2 == 0 ? -4.0 : 4.0;
        api.placeScaled(this.goalB, api.tx, api.ty, api.tz, wave, gs, gs * fs, gs, pitch, roll);
        api.transform(this.floor, su, FLOOR_Y, sv);
        api.place(this.startB, api.tx, api.ty, api.tz, 0, pitch, roll, swapping ? 0.3 + 0.7 * down : (this.state == ST_SWAP ? 0.3 + 0.7 * up : 1.0));
        // the marble
        if (this.state == ST_SWAP || (this.state == ST_OVER) || (this.mh < -0.7)) {
            api.hide(this.marble);
        } else {
            let pitchM = Math.asin(Math.max(-1.0, Math.min(1.0, -this.m12))) * 180.0 / Math.PI;
            let yawM = Math.atan2(this.m02, this.m22) * 180.0 / Math.PI;
            let rollM = Math.atan2(this.m10, this.m11) * 180.0 / Math.PI;
            let squash = 1.0;
            if (this.state == ST_DROP && this.mh < 0.12 && this.mvh > 0) {
                squash = 0.85;
            }
            api.transform(this.floor, this.mu, FLOOR_Y + R + this.mh, this.mv);
            if (squash < 1) {
                api.placeScaled(this.marble, api.tx, api.ty - 0.03, api.tz, 0, 1.08, squash, 1.08);
            } else {
                api.place(this.marble, api.tx, api.ty, api.tz, yawM, pitchM, rollM);
            }
        }
        // the spares in the dish: one leaves (hops out and vanishes) when it is needed
        let spares = this.state == ST_IDLE ? MARBLES - 1 : this.marbles - 1;
        if (this.state == ST_OVER) {
            spares = 0;
        }
        for (let i = 0; i < NLIFE; i++) {
            let b = this.lifeB[i];
            let ox = (i == 0 ? -0.3 : (i == 1 ? 0.3 : 0.0)), oz = (i == 2 ? -0.32 : 0.12);
            if (i < spares) {
                api.place(b, api.restX[b] + ox, api.restY[b], api.restZ[b] + oz, <f64>i * 70.0);
            } else if (i == this.lifeIdx && this.lifeT >= 0 && this.lifeT < 0.3) {
                let k = Math.floor(this.lifeT * 15.0) / 15.0;
                api.place(b, api.restX[b] + ox - k * 3.0, api.restY[b] + k * 3.0 - k * k * 6.0, api.restZ[b] + oz - k * 2.0, 0);
            } else {
                api.hide(b);
            }
        }
        if (this.lifeT >= 0) {
            this.lifeT += api.dt;
            if (this.lifeT > 0.3) {
                this.lifeT = -1;
            }
        }
        // sparks
        for (let i = 0; i < NSPARK; i++) {
            if (this.pT[i] < 0) {
                api.hide(this.sparkB[i]);
            } else {
                let s = 1.0 - Math.floor(this.pT[i] * 8.0) / 8.0 * 0.6;
                api.place(this.sparkB[i], this.pX[i], this.pY[i], this.pZ[i], this.pT[i] * 400.0, 30, 0, s);
            }
        }
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let cream = api.paletteColor(C_CREAM);
        let honey = api.paletteColor(C_HONEY);
        let plum = api.paletteColor(C_PLUM);
        let mauve = api.paletteColor(C_MAUVE);
        let red = api.paletteColor(C_RED);
        let olive = api.paletteColor(C_OLIVE);
        let sky = api.paletteColor(C_SKY);
        let blue = api.paletteColor(C_BLUE);
        let w = <f32>api.hudW, h = <f32>api.hudH;
        // the aim: a small cross where the player leads the marble
        if (this.state == ST_ROLL && this.hasAim && !api.demo) {
            if (api.project(<f32>this.aimU, <f32>(FLOOR_Y + 0.05), <f32>this.aimV)) {
                // four corner ticks round the point, cream on a plum outline
                let ax = Mathf.round(api.screenX), ay = Mathf.round(api.screenY);
                for (let k = 0; k < 4; k++) {
                    let sx: f32 = (k & 1) != 0 ? 1 : -1, sy: f32 = (k & 2) != 0 ? 1 : -1;
                    let cx = ax + sx * 3, cy = ay + sy * 3;
                    api.rect(Mathf.min(cx, cx - sx) - 1, cy - 1, 4, 3, plum);
                    api.rect(cx - 1, Mathf.min(cy, cy - sy) - 1, 3, 4, plum);
                }
                for (let k = 0; k < 4; k++) {
                    let sx: f32 = (k & 1) != 0 ? 1 : -1, sy: f32 = (k & 2) != 0 ? 1 : -1;
                    let cx = ax + sx * 3, cy = ay + sy * 3;
                    api.rect(Mathf.min(cx, cx - sx), cy, 2, 1, cream);
                    api.rect(cx, Mathf.min(cy, cy - sy), 1, 2, cream);
                }
            }
        }
        if (this.popT >= 0) {
            let rise = <f32>(Math.floor(this.popT * 12.0) * 1.5);
            let c = this.popText == "GOAL!" ? olive : red;
            let px = Mathf.max(60, Mathf.min(w - 60, Mathf.round(this.popX - api.textWidth(this.popText, 1) * 0.5)));
            let py = Mathf.max(26, this.popY - 6) - rise;
            api.rect(px - 2, py - 2, api.textWidth(this.popText, 1) + 4, 9, plum);
            api.text(px, py, this.popText, c, 1);
        }
        // score: goals, the round's holes, best
        api.rect(3, 3, 54, 19, plum);
        api.text(6, 6, "GOALS", honey, 1);
        api.text(30, 5, this.score.toString(), cream, 2);
        api.text(6, 14, "BEST " + this.best.toString(), mauve, 1);
        // marbles left
        for (let i = 0; i < MARBLES; i++) {
            let x = w - 10 - <f32>i * 9;
            let alive = this.state == ST_IDLE ? true : i < this.marbles;
            if (this.state == ST_OVER) {
                alive = false;
            }
            api.rect(x + 1, 4, 5, 7, plum);
            api.rect(x, 5, 7, 5, plum);
            api.rect(x + 1, 5, 5, 5, alive ? blue : mauve);
            if (alive) {
                api.rect(x + 2, 6, 2, 1, sky);
            }
        }
        if (this.state == ST_IDLE) {
            let blink = Math.floor(api.time * 2) % 2 == 0;
            api.textCentered(h - 21, "CLICK TO DROP THE MARBLE", blink ? cream : honey, 1, plum);
            api.textCentered(h - 12, "LEAD IT WITH THE POINTER: THE BOARD TILTS", cream, 1, plum);
            api.textCentered(h - 5, "MISS THE HOLES, REACH THE FLAG", honey, 1, plum);
        } else if (this.state == ST_OVER) {
            let pw: f32 = 120, ph: f32 = 42;
            let px = Mathf.floor((w - pw) * 0.5), py = Mathf.floor(h * 0.5 - 30);
            api.rect(px - 1, py - 1, pw + 2, ph + 2, mauve);
            api.rect(px, py, pw, ph, plum);
            api.textCentered(py + 4, "OUT OF MARBLES", red, 2);
            api.textCentered(py + 18, "GOALS " + this.score.toString() + "   BEST " + this.best.toString(), cream, 1);
            if (this.stateT > 0.6 && !api.demo) {
                let blink = Math.floor(api.time * 2) % 2 == 0;
                api.textCentered(py + 30, "CLICK TO PLAY AGAIN", blink ? honey : cream, 1);
            }
        } else if (this.state == ST_DROP && this.round == 0 && this.marbles == MARBLES && !api.demo) {
            api.textCentered(h - 10, "LEAD THE MARBLE TO THE FLAG", cream, 1, plum);
        } else {
            api.text(w - 34, 14, "HOLES " + this.nHole.toString(), honey, 1, plum);
        }
    }
}
