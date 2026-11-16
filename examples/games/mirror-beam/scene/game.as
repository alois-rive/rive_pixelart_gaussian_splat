// Mirror Beam: click the mirrors to turn them and bounce the sunbeam into every crystal of the
// temple court before the sun sets. One verb (click), one world: each solved court scores, lights
// the temple's sun emblem and gives the sun back a few seconds; then the pieces sink and a new,
// larger layout rises in the same court. When the sun goes down behind the dunes the run is over.
// Demo mode (api.demo) solves like a decent player: it follows the beam, hesitates, and sometimes
// turns the wrong mirror and has to turn it back.
import { GameApi, POINTER_DOWN, POINTER_MOVE } from "./game_api";

// the grid (models/env/make_env.py builds the floor from the same numbers)
const COLS: i32 = 7;
const ROWS: i32 = 4;
const CELL: f64 = 1.2;
const X0: f64 = -3.6;          // the centre of column 0
const Z0: f64 = -1.8;          // the centre of row 0 (the back row)
const BEAM_Y: f64 = 1.266;     // the mirrors' centre height (0.974 m x the bake's 1.3)
const LENS_X: f64 = -5.45;

const EMPTY: i32 = 0;
const MIRROR: i32 = 1;
const CRYSTAL: i32 = 2;
const STUMP: i32 = 3;

const NM: i32 = 10;            // pools (scene.bake.json)
const NC: i32 = 5;
const NS: i32 = 3;
const NSP: i32 = 12;

const DAY: f64 = 40;           // seconds of daylight at the start (the most it can hold)

const MODE_READY: i32 = 0;     // the first court waits for the first click
const MODE_PLAY: i32 = 1;
const MODE_SOLVED: i32 = 2;    // everything lit: the pop, then the swap to a new court
const MODE_OVER: i32 = 3;

// E S W N
const DX: StaticArray<i32> = [1, 0, -1, 0];
const DZ: StaticArray<i32> = [0, 1, 0, -1];

function clamp(v: f64, a: f64, b: f64): f64 {
    return v < a ? a : (v > b ? b : v);
}

// "/" (type 0) and "\" (type 1): the turn of a beam heading d
function reflect(t: i32, d: i32): i32 {
    return t == 0 ? 3 - d : d ^ 1;
}

function cellX(c: i32): f64 { return X0 + <f64>c * CELL; }
function cellZ(r: i32): f64 { return Z0 + <f64>r * CELL; }

export class Game {
    mirrorB: StaticArray<i32> = new StaticArray<i32>(NM);
    crystalB: StaticArray<i32> = new StaticArray<i32>(NC);
    glowB: StaticArray<i32> = new StaticArray<i32>(NC);
    stumpB: StaticArray<i32> = new StaticArray<i32>(NS);
    sparkB: StaticArray<i32> = new StaticArray<i32>(NSP);
    sun: i32 = -1;
    emblem: i32 = -1;
    lens: i32 = -1;
    ring: i32 = -1;

    // the court: what stands in each cell, and which piece of its pool it is
    kind: StaticArray<i32> = new StaticArray<i32>(COLS * ROWS);
    piece: StaticArray<i32> = new StaticArray<i32>(COLS * ROWS);
    // mirrors
    nm: i32 = 0;
    mC: StaticArray<i32> = new StaticArray<i32>(NM);
    mR: StaticArray<i32> = new StaticArray<i32>(NM);
    mType: StaticArray<i32> = new StaticArray<i32>(NM);   // the current turn
    mSol: StaticArray<i32> = new StaticArray<i32>(NM);    // the turn of the generated solution
    mOnPath: StaticArray<bool> = new StaticArray<bool>(NM);
    mAng: StaticArray<f64> = new StaticArray<f64>(NM);    // shown yaw, swings to the target
    mSwing: StaticArray<f64> = new StaticArray<f64>(NM);  // seconds since the last turn
    // crystals
    nc: i32 = 0;
    cC: StaticArray<i32> = new StaticArray<i32>(NC);
    cR: StaticArray<i32> = new StaticArray<i32>(NC);
    cLit: StaticArray<bool> = new StaticArray<bool>(NC);
    cPop: StaticArray<f64> = new StaticArray<f64>(NC);
    // stumps
    ns: i32 = 0;
    sC: StaticArray<i32> = new StaticArray<i32>(NS);
    sR: StaticArray<i32> = new StaticArray<i32>(NS);
    entryRow: i32 = 2;
    lensZ: f64 = 0;

    // the beam: points in the world (x, z) at BEAM_Y, and how it ends
    bx: StaticArray<f64> = new StaticArray<f64>(64);
    bz: StaticArray<f64> = new StaticArray<f64>(64);
    bn: i32 = 0;
    bSplash: bool = false;    // ends on a wall or a stump (a splash), not on a mirror mid-turn
    beamOn: f64 = 1;          // 0..1: the beam's strength (fades at sunset)

    // the run
    mode: i32 = MODE_READY;
    t: f64 = 0;
    day: f64 = DAY;
    shownDay: f64 = DAY;
    score: i32 = 0;
    best: i32 = 0;
    court: i32 = 0;           // courts solved this run
    clicks: i32 = 0;
    par: i32 = 0;
    rise: f64 = 1;            // 0..1 the pieces rising in (1 = up)
    phase: i32 = 0;           // in MODE_SOLVED: 0 the pop, 1 sinking, 2 the next court rising
    emblemT: f64 = 9;
    popText: string = "";
    popText2: string = "";
    popT: f64 = 9;
    hover: i32 = -1;
    hintT: f64 = 0;
    shake: f64 = 0;

    // sparks
    spX: StaticArray<f64> = new StaticArray<f64>(NSP);
    spY: StaticArray<f64> = new StaticArray<f64>(NSP);
    spZ: StaticArray<f64> = new StaticArray<f64>(NSP);
    spVX: StaticArray<f64> = new StaticArray<f64>(NSP);
    spVY: StaticArray<f64> = new StaticArray<f64>(NSP);
    spVZ: StaticArray<f64> = new StaticArray<f64>(NSP);
    spT: StaticArray<f64> = new StaticArray<f64>(NSP);
    spNext: i32 = 0;

    // demo
    dWait: f64 = 0.35;
    dTarget: i32 = -1;
    dCurX: f64 = 150;
    dCurY: f64 = 110;
    dPress: f64 = 9;

    start(api: GameApi): void {
        api.playable = true;
        this.sun = api.bone("sun");
        this.emblem = api.bone("emblem");
        this.lens = api.bone("lens");
        this.ring = api.bone("ring");
        for (let i = 0; i < NM; i++) {
            this.mirrorB[i] = api.bone("mirror" + i.toString());
        }
        for (let i = 0; i < NC; i++) {
            this.crystalB[i] = api.bone("crystal" + i.toString());
            this.glowB[i] = api.bone("glow" + i.toString());
        }
        for (let i = 0; i < NS; i++) {
            this.stumpB[i] = api.bone("stump" + i.toString());
        }
        for (let i = 0; i < NSP; i++) {
            this.sparkB[i] = api.bone("spark" + i.toString());
            this.spT[i] = 99;
            api.hide(this.sparkB[i]);
        }
        api.hide(this.emblem);
        api.hide(this.ring);
        this.newRun(api);
    }

    newRun(api: GameApi): void {
        this.mode = api.demo ? MODE_PLAY : MODE_READY;
        this.t = 0;
        this.day = DAY;
        this.score = 0;
        this.court = 0;
        this.popT = 9;
        this.emblemT = 9;
        this.beamOn = 1;
        this.dWait = 0.3;
        this.dTarget = -1;
        this.generate(api);
        this.rise = 1;
        this.phase = 0;
        this.trace();
    }

    // ------------------------------------------------------------------ the court

    idx(c: i32, r: i32): i32 { return r * COLS + c; }

    // A new layout for court number `this.court`: a random beam path from the west wall with K
    // mirrors on it, crystals along it (one after the last mirror, so every mirror matters), decoy
    // mirrors and stumps off it; then the path's mirrors are scrambled. Solvable by construction.
    generate(api: GameApi): void {
        let n = this.court;
        let K = n < 4 ? 2 + n : 5 + (n >= 6 ? 1 : 0);
        let nCry = min<i32>(1 + (n + 1) / 2, 4);
        let nDecoy = min<i32>(n, 3);
        let nStump = min<i32>((n + 1) / 2, 3);
        if (K + nDecoy > NM) {
            nDecoy = NM - K;
        }
        let pc = new StaticArray<i32>(64);
        let pr = new StaticArray<i32>(64);
        let pm = new StaticArray<i32>(64);    // -1 a plain cell, else the mirror type there
        let plen = 0;
        for (let attempt = 0; attempt < 400; attempt++) {
            for (let i = 0; i < COLS * ROWS; i++) {
                this.kind[i] = EMPTY;
            }
            let row = <i32>(api.rand() * <f64>ROWS);
            let c = -1, r = row, d = 0, mirrors = 0;
            plen = 0;
            let ok = true;
            let sinceTurn = 0;
            for (let s = 0; s < 40; s++) {
                c += DX[d];
                r += DZ[d];
                if (c < 0 || c >= COLS || r < 0 || r >= ROWS) {
                    break;
                }
                let k = this.idx(c, r);
                if (this.kind[k] != EMPTY) {
                    ok = false;
                    break;
                }
                this.kind[k] = 9;   // on the path
                pc[plen] = c; pr[plen] = r; pm[plen] = -1;
                plen++;
                // turn here? only when there are mirrors left to place and room after the turn
                if (mirrors < K && sinceTurn >= 1 && api.rand() < 0.55) {
                    let left = (d + 3) % 4, right = (d + 1) % 4;
                    let nd = api.rand() < 0.5 ? left : right;
                    let nc = c + DX[nd], nr = r + DZ[nd];
                    if (nc < 0 || nc >= COLS || nr < 0 || nr >= ROWS || this.kind[this.idx(nc, nr)] != EMPTY) {
                        nd = nd == left ? right : left;
                        nc = c + DX[nd]; nr = r + DZ[nd];
                    }
                    if (nc >= 0 && nc < COLS && nr >= 0 && nr < ROWS && this.kind[this.idx(nc, nr)] == EMPTY) {
                        // the mirror type that turns d into nd
                        let t = reflect(0, d) == nd ? 0 : 1;
                        pm[plen - 1] = t;
                        d = nd;
                        mirrors++;
                        sinceTurn = 0;
                        continue;
                    }
                }
                sinceTurn++;
            }
            if (!ok || mirrors < K) {
                continue;
            }
            // the cells after the last mirror and the plain cells before it
            let lastM = -1;
            for (let i = 0; i < plen; i++) {
                if (pm[i] >= 0) lastM = i;
            }
            if (plen - 1 - lastM < 1 || plen - (K) < nCry) {
                continue;
            }
            // lay it out
            for (let i = 0; i < COLS * ROWS; i++) {
                this.kind[i] = EMPTY;
                this.piece[i] = -1;
            }
            this.entryRow = row;
            this.nm = 0;
            this.nc = 0;
            this.ns = 0;
            for (let i = 0; i < plen; i++) {
                if (pm[i] >= 0) {
                    this.addMirror(pc[i], pr[i], pm[i], true);
                }
            }
            // one crystal after the last mirror, the others on random plain path cells
            let after = lastM + 1 + <i32>(api.rand() * <f64>(plen - 1 - lastM));
            this.addCrystal(pc[after], pr[after]);
            let tries = 0;
            while (this.nc < nCry && tries < 200) {
                tries++;
                let i = <i32>(api.rand() * <f64>plen);
                if (pm[i] >= 0 || this.kind[this.idx(pc[i], pr[i])] != EMPTY) continue;
                this.addCrystal(pc[i], pr[i]);
            }
            if (this.nc < nCry) {
                continue;
            }
            // mark the rest of the path so decoys and stumps stay off it
            for (let i = 0; i < plen; i++) {
                let k = this.idx(pc[i], pr[i]);
                if (this.kind[k] == EMPTY) this.kind[k] = 9;
            }
            tries = 0;
            while (this.nm < K + nDecoy && tries < 200) {
                tries++;
                let c2 = <i32>(api.rand() * <f64>COLS), r2 = <i32>(api.rand() * <f64>ROWS);
                if (this.kind[this.idx(c2, r2)] != EMPTY) continue;
                this.addMirror(c2, r2, api.rand() < 0.5 ? 0 : 1, false);
            }
            tries = 0;
            while (this.ns < nStump && tries < 200) {
                tries++;
                let c2 = <i32>(api.rand() * <f64>COLS), r2 = <i32>(api.rand() * <f64>ROWS);
                if (this.kind[this.idx(c2, r2)] != EMPTY) continue;
                this.addStump(c2, r2);
            }
            for (let i = 0; i < COLS * ROWS; i++) {
                if (this.kind[i] == 9) this.kind[i] = EMPTY;
            }
            // scramble the path's mirrors: about two in three turned the wrong way, at least half
            let flipped = 0;
            for (let i = 0; i < this.nm; i++) {
                if (this.mOnPath[i] && api.rand() < 0.66) {
                    this.mType[i] ^= 1;
                    flipped++;
                }
            }
            let need = (K + 1) / 2;
            for (let i = 0; i < this.nm && flipped < need; i++) {
                if (this.mOnPath[i] && this.mType[i] == this.mSol[i]) {
                    this.mType[i] ^= 1;
                    flipped++;
                }
            }
            this.par = flipped;
            for (let i = 0; i < this.nm; i++) {
                this.mAng[i] = this.mType[i] == 0 ? 45 : -45;
                this.mSwing[i] = 9;
            }
            this.trace();
            if (this.allLit()) {
                continue;   // scrambled into a solution by chance: again
            }
            break;
        }
        this.clicks = 0;
        this.lensZ = cellZ(this.entryRow);
        for (let i = 0; i < NC; i++) {
            this.cLit[i] = false;
            this.cPop[i] = 9;
        }
        this.trace();
    }

    addMirror(c: i32, r: i32, t: i32, onPath: bool): void {
        let i = this.nm++;
        this.mC[i] = c; this.mR[i] = r;
        this.mType[i] = t; this.mSol[i] = t;
        this.mOnPath[i] = onPath;
        this.kind[this.idx(c, r)] = MIRROR;
        this.piece[this.idx(c, r)] = i;
    }

    addCrystal(c: i32, r: i32): void {
        let i = this.nc++;
        this.cC[i] = c; this.cR[i] = r;
        this.kind[this.idx(c, r)] = CRYSTAL;
        this.piece[this.idx(c, r)] = i;
    }

    addStump(c: i32, r: i32): void {
        let i = this.ns++;
        this.sC[i] = c; this.sR[i] = r;
        this.kind[this.idx(c, r)] = STUMP;
        this.piece[this.idx(c, r)] = i;
    }

    // Follows the beam from the lens through the court; marks the crystals it crosses (cHit).
    cHit: StaticArray<bool> = new StaticArray<bool>(NC);
    trace(): void {
        for (let i = 0; i < NC; i++) this.cHit[i] = false;
        let c = -1, r = this.entryRow, d = 0;
        this.bn = 0;
        this.bx[0] = LENS_X + 0.1; this.bz[0] = cellZ(r);
        this.bn = 1;
        this.bSplash = true;
        for (let s = 0; s < 60; s++) {
            let nc = c + DX[d], nr = r + DZ[d];
            if (nc < 0 || nc >= COLS || nr < 0 || nr >= ROWS) {
                // out over the border: the beam hits the court's wall
                let ex = <f64>nc, ez = <f64>nr;
                this.bx[this.bn] = cellX(c) + <f64>DX[d] * (CELL * 0.5 + 0.3);
                this.bz[this.bn] = cellZ(r) + <f64>DZ[d] * (CELL * 0.5 + 0.3);
                if (c < 0) {   // never entered (cannot happen: the entry is inside)
                    this.bx[this.bn] = ex;
                    this.bz[this.bn] = ez;
                }
                this.bn++;
                return;
            }
            c = nc; r = nr;
            let k = this.idx(c, r);
            let kd = this.kind[k];
            if (kd == MIRROR) {
                let m = this.piece[k];
                this.bx[this.bn] = cellX(c); this.bz[this.bn] = cellZ(r); this.bn++;
                if (this.mSwing[m] < 0.16) {
                    this.bSplash = false;   // mid-turn: the beam stops on it until it settles
                    return;
                }
                d = reflect(this.mType[m], d);
            } else if (kd == CRYSTAL) {
                this.cHit[this.piece[k]] = true;
            } else if (kd == STUMP) {
                this.bx[this.bn] = cellX(c) - <f64>DX[d] * 0.32;
                this.bz[this.bn] = cellZ(r) - <f64>DZ[d] * 0.32;
                this.bn++;
                return;
            }
            if (this.bn >= 62) return;
        }
    }

    allLit(): bool {
        for (let i = 0; i < this.nc; i++) {
            if (!this.cHit[i]) return false;
        }
        return this.nc > 0;
    }

    // ------------------------------------------------------------------ input

    // The mirror under a HUD point: the nearest whose middle (projected) is within reach.
    mirrorAt(api: GameApi, x: f32, y: f32): i32 {
        let bestI = -1;
        let bestD: f32 = 12 * 12;
        for (let i = 0; i < this.nm; i++) {
            api.project(<f32>cellX(this.mC[i]), 0.85, <f32>cellZ(this.mR[i]));
            let dx = api.screenX - x, dy = (api.screenY - y) * 0.8;
            let d = dx * dx + dy * dy;
            if (d < bestD) {
                bestD = d;
                bestI = i;
            }
        }
        return bestI;
    }

    turn(api: GameApi, i: i32): void {
        this.mType[i] ^= 1;
        this.mSwing[i] = 0;
        this.clicks++;
        this.spawnSparks(api, cellX(this.mC[i]), 0.15, cellZ(this.mR[i]), 2, 1.2);
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_MOVE) {
            this.hover = this.mode == MODE_PLAY || this.mode == MODE_READY ? this.mirrorAt(api, x, y) : -1;
            return true;
        }
        if (kind != POINTER_DOWN) {
            return true;
        }
        if (this.mode == MODE_OVER) {
            if (this.t > 0.8) {
                this.newRun(api);
                this.mode = MODE_PLAY;   // the click that restarts also starts the clock
            }
            return true;
        }
        let i = this.mirrorAt(api, x, y);
        this.hover = i;
        if (this.mode == MODE_READY) {
            if (i < 0) {
                return true;            // only a mirror starts the run: the hint says so
            }
            this.mode = MODE_PLAY;
            this.t = 0;
        }
        if (this.mode == MODE_PLAY && i >= 0 && this.rise >= 1) {
            this.turn(api, i);
        }
        return true;
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged) {
            this.best = 0;
            this.hover = -1;
            this.newRun(api);
        }
        this.t += dt;
        this.hintT += dt;
        this.popT += dt;
        this.emblemT += dt;

        if (this.mode == MODE_PLAY || this.mode == MODE_SOLVED) {
            this.day -= dt;
            if (this.day <= 0) {
                this.day = 0;
                this.mode = MODE_OVER;
                this.t = 0;
                this.hover = -1;
                this.phase = 0;
                this.rise = 1;
                if (this.score > this.best) this.best = this.score;
            }
        }
        if (this.mode == MODE_OVER) {
            this.beamOn = Math.max(0, this.beamOn - dt * 1.5);
            if (api.demo && this.t > 2.0) {
                this.newRun(api);
            }
        } else {
            this.beamOn = Math.min(1, this.beamOn + dt * 3);
        }
        if (api.demo && (this.mode == MODE_PLAY)) {
            this.demoPlay(api, dt);
        }

        // mirrors swing to their turn (a quick overshoot), the beam follows when they settle
        for (let i = 0; i < this.nm; i++) {
            this.mSwing[i] += dt;
            let target = this.mType[i] == 0 ? 45.0 : -45.0;
            let u = this.mSwing[i] / 0.16;
            if (u < 1) {
                let from = -target;
                let e = 1 - (1 - u) * (1 - u);
                this.mAng[i] = from + (target - from) * e * 1.12;
            } else if (u < 1.6) {
                this.mAng[i] = target + (target > 0 ? 1.0 : -1.0) * 9 * (1.6 - u) / 0.6 * Math.cos((u - 1) * 12);
            } else {
                this.mAng[i] = target;
            }
        }
        this.trace();
        if (this.beamOn < 0.5) {
            for (let i = 0; i < NC; i++) this.cHit[i] = false;
        }

        // crystals light where the beam crosses them
        for (let i = 0; i < this.nc; i++) {
            this.cPop[i] += dt;
            let lit = this.cHit[i] && this.rise >= 1;
            if (lit != this.cLit[i]) {
                this.cLit[i] = lit;
                this.cPop[i] = 0;
                if (lit) {
                    this.spawnSparks(api, cellX(this.cC[i]), 0.9, cellZ(this.cR[i]), 4, 2.2);
                }
            }
        }
        if (this.mode == MODE_PLAY && this.rise >= 1 && this.allLit()) {
            this.solved(api);
        }
        if (this.mode == MODE_SOLVED) {
            if (this.phase == 0 && this.t > 1.5) {
                this.phase = 1;
            }
            if (this.phase == 1) {
                // the solved court sinks into the floor ...
                this.rise -= dt / 0.45;
                if (this.rise <= 0) {
                    this.rise = 0;
                    this.court++;
                    this.generate(api);
                    this.phase = 2;
                }
            } else if (this.phase == 2) {
                // ... and the next one rises, turning
                this.rise += dt / 0.5;
                if (this.rise >= 1) {
                    this.rise = 1;
                    this.phase = 0;
                    this.mode = MODE_PLAY;
                    this.t = 0;
                    this.dWait = 0.5;
                    this.dTarget = -1;
                }
            }
        }

        this.shownDay += (this.day - this.shownDay) * Math.min(1, dt * 3);
        this.shake = Math.max(0, this.shake - dt * 1.2);
        this.updateSparks(api, dt);
        this.pose(api);
    }

    solved(api: GameApi): void {
        this.mode = MODE_SOLVED;
        this.t = 0;
        let pts = 100 + 25 * this.nc;
        let perfect = this.clicks <= this.par;
        if (perfect) pts += 50;
        this.score += pts;
        if (this.score > this.best) this.best = this.score;
        let bonus = Math.max(2.0, 8.0 - <f64>this.court);
        this.day = Math.min(DAY, this.day + bonus);
        this.popText = "+" + pts.toString();
        this.popText2 = perfect ? "PERFECT!" : (this.nc >= 3 ? "RADIANT!" : "LIT!");
        this.popT = 0;
        this.emblemT = 0;
        this.shake = 0.25;
        for (let i = 0; i < this.nc; i++) {
            this.cPop[i] = 0;
            this.spawnSparks(api, cellX(this.cC[i]), 1.0, cellZ(this.cR[i]), 3, 2.6);
        }
        this.spawnSparks(api, 0, 2.3, -4.5, 4, 2.4);
    }

    // ------------------------------------------------------------------ demo

    // A player that follows the beam: it looks for the first mirror along the solution path that is
    // turned wrong, thinks for a moment and turns it; one turn in five goes to a wrong mirror (a
    // right one or a decoy), which it notices and turns back later. It slows down as courts grow.
    demoPlay(api: GameApi, dt: f64): void {
        this.dPress += dt;
        if (this.rise < 1) return;
        if (this.dTarget < 0) {
            // choose
            let wrong = -1;
            // walk the path in the order the beam meets it: the first wrong mirror on the beam
            for (let p = 1; p < this.bn; p++) {
                let c = <i32>Math.round((this.bx[p] - X0) / CELL), r = <i32>Math.round((this.bz[p] - Z0) / CELL);
                if (c < 0 || c >= COLS || r < 0 || r >= ROWS) continue;
                let k = this.idx(c, r);
                if (this.kind[k] == MIRROR) {
                    let m = this.piece[k];
                    if (this.mType[m] != this.mSol[m]) { wrong = m; break; }
                }
            }
            if (wrong < 0) {
                for (let i = 0; i < this.nm; i++) {
                    if (this.mType[i] != this.mSol[i] && (this.mOnPath[i] || api.rand() < 0.5)) { wrong = i; break; }
                }
            }
            if (wrong < 0) return;
            let slip = api.rand() < 0.22;
            this.dTarget = slip ? <i32>(api.rand() * <f64>this.nm) : wrong;
            let think = 0.45 + api.rand() * 0.6 + <f64>this.court * 0.12;
            if (api.rand() < 0.15) think += 1.0;   // a longer look now and then
            if (this.court == 0 && this.clicks == 0) think = 0.4;   // the first turn comes at once
            this.dWait = think;
        }
        let i = this.dTarget;
        api.project(<f32>cellX(this.mC[i]), 0.85, <f32>cellZ(this.mR[i]));
        let tx = <f64>api.screenX + 1, ty = <f64>api.screenY + 2;
        let k = Math.min(1, dt * 9);
        this.dCurX += (tx - this.dCurX) * k;
        this.dCurY += (ty - this.dCurY) * k;
        this.hover = i;
        this.dWait -= dt;
        if (this.dWait <= 0) {
            this.turn(api, i);
            this.dPress = 0;
            this.dTarget = -1;
        }
    }

    // ------------------------------------------------------------------ effects

    spawnSparks(api: GameApi, x: f64, y: f64, z: f64, n: i32, speed: f64): void {
        for (let j = 0; j < n; j++) {
            let s = this.spNext;
            this.spNext = (this.spNext + 1) % NSP;
            let a = api.rand() * Math.PI * 2;
            let v = speed * (0.5 + api.rand() * 0.5);
            this.spX[s] = x; this.spY[s] = y; this.spZ[s] = z;
            this.spVX[s] = Math.cos(a) * v;
            this.spVZ[s] = Math.sin(a) * v * 0.6;
            this.spVY[s] = speed * (0.8 + api.rand() * 0.7);
            this.spT[s] = 0;
        }
    }

    updateSparks(api: GameApi, dt: f64): void {
        for (let s = 0; s < NSP; s++) {
            if (this.spT[s] > 0.9) {
                if (this.spT[s] < 50) {
                    api.hide(this.sparkB[s]);
                    this.spT[s] = 99;
                }
                continue;
            }
            this.spT[s] += dt;
            this.spVY[s] -= 7 * dt;
            this.spX[s] += this.spVX[s] * dt;
            this.spY[s] += this.spVY[s] * dt;
            this.spZ[s] += this.spVZ[s] * dt;
            let sc = 1.0 - Math.floor(this.spT[s] * 8) / 8 * 0.7;
            api.place(this.sparkB[s], this.spX[s], Math.max(0.05, this.spY[s]), this.spZ[s], this.spT[s] * 400, 0, 0, sc);
        }
    }

    // ------------------------------------------------------------------ the world

    pose(api: GameApi): void {
        // pieces rise out of the floor in steps (8 fps) and sink back the same way
        let rs = Math.floor(clamp(this.rise, 0, 1) * 8) / 8;
        let lift = (rs - 1) * 1.5;
        for (let i = 0; i < NM; i++) {
            let b = this.mirrorB[i];
            if (i >= this.nm || rs <= 0) {
                api.hide(b);
                continue;
            }
            let spin = (1 - rs) * 180;
            api.place(b, cellX(this.mC[i]), lift, cellZ(this.mR[i]), this.mAng[i] + spin, 0, 0, 1);
        }
        for (let i = 0; i < NC; i++) {
            if (i >= this.nc || rs <= 0) {
                api.hide(this.crystalB[i]);
                api.hide(this.glowB[i]);
                continue;
            }
            let x = cellX(this.cC[i]), z = cellZ(this.cR[i]);
            let p = this.cPop[i];
            let sq = p < 0.3 ? 1 + 0.25 * Math.sin(p / 0.3 * Math.PI) : 1.0;
            let bob = this.cLit[i] ? 0.06 * Math.floor(2 + 2 * Math.sin(api.time * 4 + <f64>i)) / 2 : 0;
            let yaw = this.cLit[i] ? Math.floor(api.time * 6) * 15 : <f64>(i * 47);
            let on = this.cLit[i] ? this.glowB[i] : this.crystalB[i];
            let off = this.cLit[i] ? this.crystalB[i] : this.glowB[i];
            api.hide(off);
            api.placeScaled(on, x, lift + bob, z, yaw, 1 / Math.sqrt(sq), sq, 1 / Math.sqrt(sq));
        }
        for (let i = 0; i < NS; i++) {
            if (i >= this.ns || rs <= 0) {
                api.hide(this.stumpB[i]);
                continue;
            }
            api.place(this.stumpB[i], cellX(this.sC[i]), lift, cellZ(this.sR[i]), <f64>(i * 70 + 20), 0, 0, 1);
        }
        // the lens slides to the entry row
        api.place(this.lens, LENS_X, 0, this.lensZ, 0, 0, 0, 1);
        // the emblem glows for a while after a court is solved
        if (this.emblemT < 2.2 && Math.floor(this.emblemT * 10) % 4 != 3 || (this.emblemT < 1.2)) {
            let e = this.emblemT < 0.25 ? 1.0 + 0.3 * Math.sin(this.emblemT / 0.25 * Math.PI) : 1.0;
            api.place(this.emblem, api.restX[this.emblem], api.restY[this.emblem], api.restZ[this.emblem], 0, 0, 0, e);
        } else {
            api.hide(this.emblem);
        }
        // the hover ring under the mirror the pointer (or the demo) is on
        if (this.hover >= 0 && this.hover < this.nm && rs >= 1 && (this.mode == MODE_PLAY || this.mode == MODE_READY)) {
            let pulse = 1.0 + 0.06 * Math.floor(Math.sin(api.time * 8) * 1.5 + 1.5) / 3;
            api.place(this.ring, cellX(this.mC[this.hover]), 0, cellZ(this.mR[this.hover]), 22.5, 0, 0, pulse);
        } else {
            api.hide(this.ring);
        }

        // the sun sinks with the daylight; the light lowers with it
        let f = clamp(this.shownDay / DAY, 0, 1);
        if (this.mode == MODE_READY) f = 1;
        api.sunPitch = 6 + 36 * f;
        api.sunYaw = -70 + 12 * (1 - f);
        api.keyLight = 0.4;
        let sy = 14 + (1 - f) * 36;           // the sun's middle, HUD pixels from the top
        if (api.pickPlane(28, <f32>sy, 0, 0, 1, -12.5)) {
            api.place(this.sun, api.hitX, api.hitY, api.hitZ, 0, 0, 0, 1);
        }
        // a small shake on a solve, in whole texels
        let sh = this.shake > 0 ? (Math.floor(api.time * 20) % 2 == 0 ? 1.0 : -1.0) * this.shake * 0.25 : 0;
        api.targetX = sh;
    }

    // ------------------------------------------------------------------ HUD

    beamLine(api: GameApi, x0: f32, y0: f32, x1: f32, y1: f32, core: u32, glow: u32, wide: bool): void {
        let horiz = Mathf.abs(x1 - x0) >= Mathf.abs(y1 - y0);
        if (wide) {
            if (horiz) {
                api.line(x0, y0 - 1, x1, y1 - 1, glow);
                api.line(x0, y0 + 1, x1, y1 + 1, glow);
            } else {
                api.line(x0 - 1, y0, x1 - 1, y1, glow);
                api.line(x0 + 1, y0, x1 + 1, y1, glow);
            }
        }
        api.line(x0, y0, x1, y1, core);
    }

    hud(api: GameApi): void {
        let E = api.paletteColor(4), D = api.paletteColor(3), C = api.paletteColor(2);
        let B = api.paletteColor(1), A = api.paletteColor(0);

        // the sunlight falling from the sun onto the lens: a dashed ray, marching
        if (this.beamOn > 0.3 && this.mode != MODE_OVER) {
            api.project(<f32>LENS_X, <f32>BEAM_Y, <f32>this.lensZ);
            let lx = api.screenX, ly = api.screenY;
            let f0 = clamp(this.shownDay / DAY, 0, 1);
            if (this.mode == MODE_READY) f0 = 1;
            let sx0: f32 = 34, sy0 = <f32>(14 + (1 - f0) * 36) + 6;
            let L = Mathf.sqrt((lx - sx0) * (lx - sx0) + (ly - sy0) * (ly - sy0));
            let ph = <f32>(Math.floor(api.time * 16) % 6);
            for (let d: f32 = ph; d < L - 4; d += 6) {
                let u = d / L;
                api.rect(Mathf.round(sx0 + (lx - sx0) * u), Mathf.round(sy0 + (ly - sy0) * u), 2, 1, D);
            }
        }

        // the beam (drawn first, under the text)
        if (this.beamOn > 0.05 && this.rise >= 1) {
            let flick = this.beamOn < 0.6 && Math.floor(api.time * 15) % 2 == 0;
            if (!flick) {
                let sx = new StaticArray<f32>(64), sy = new StaticArray<f32>(64);
                for (let p = 0; p < this.bn; p++) {
                    api.project(<f32>this.bx[p], <f32>BEAM_Y, <f32>this.bz[p]);
                    sx[p] = Mathf.round(api.screenX); sy[p] = Mathf.round(api.screenY);
                }
                // the source's first part comes out of the lens prism
                // the glow stops short of each mirror so its bright face still shows; the core runs on
                for (let p = 0; p + 1 < this.bn; p++) {
                    let x0 = sx[p], y0 = sy[p], x1 = sx[p + 1], y1 = sy[p + 1];
                    let L = Mathf.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
                    let s0: f32 = p > 0 ? 5 : 0;
                    let s1: f32 = (p + 2 < this.bn || !this.bSplash) ? 5 : 0;
                    if (L > s0 + s1 + 1 && this.beamOn > 0.6) {
                        let ux = (x1 - x0) / L, uy = (y1 - y0) / L;
                        this.beamLine(api, Mathf.round(x0 + ux * s0), Mathf.round(y0 + uy * s0),
                                      Mathf.round(x1 - ux * s1), Mathf.round(y1 - uy * s1), E, D, true);
                    }
                    api.line(x0, y0, x1, y1, E);
                }
                // light running along the beam: bright dashes stepping forward
                let total: f32 = 0;
                for (let p = 0; p + 1 < this.bn; p++) {
                    total += Mathf.abs(sx[p + 1] - sx[p]) + Mathf.abs(sy[p + 1] - sy[p]);
                }
                let phase = <f32>(Math.floor(api.time * 30) % 12);
                let acc: f32 = 0;
                for (let p = 0; p + 1 < this.bn; p++) {
                    let L = Mathf.abs(sx[p + 1] - sx[p]) + Mathf.abs(sy[p + 1] - sy[p]);
                    if (L < 1) continue;
                    let s0 = Mathf.ceil((acc - phase) / 12) * 12 + phase;
                    for (let s = s0; s < acc + L; s += 12) {
                        let u = (s - acc) / L;
                        let px = Mathf.round(sx[p] + (sx[p + 1] - sx[p]) * u);
                        let py = Mathf.round(sy[p] + (sy[p + 1] - sy[p]) * u);
                        api.rect(px - 1, py - 1, 3, 3, D);
                        api.rect(px, py - 1, 1, 3, E);
                        api.rect(px - 1, py, 3, 1, E);
                    }
                    acc += L;
                }
                // where it ends on a wall or a stump: a flickering splash
                if (this.bSplash && this.bn > 1) {
                    let ex = sx[this.bn - 1], ey = sy[this.bn - 1];
                    let k = <f32>(Math.floor(api.time * 12) % 3);
                    api.rect(ex - 1 - k, ey, 3 + 2 * k, 1, E);
                    api.rect(ex, ey - 1 - k, 1, 3 + 2 * k, E);
                    api.rect(ex - 1, ey - 1, 3, 3, E);
                }
            }
        }

        // the score and the best on the right, the daylight bar and the court's crystals in the middle
        // (the sun itself keeps the top left)
        let w = api.hudW;
        let ss = "SCORE " + this.score.toString();
        api.text(<f32>w - api.textWidth(ss, 1) - 4, 3, ss, E, 1, A);
        let bs = "BEST " + this.best.toString();
        api.text(<f32>w - api.textWidth(bs, 1) - 4, 11, bs, D, 1, A);
        let bw: f32 = 56;
        let bx0 = Mathf.floor((<f32>w - bw) * 0.5);
        let f = <f32>clamp(this.shownDay / DAY, 0, 1);
        let low = this.mode == MODE_PLAY && this.day < 8 && Math.floor(api.time * 4) % 2 == 0;
        api.rect(bx0 - 1, 3, bw + 2, 5, A);
        api.rect(bx0, 4, bw, 3, B);
        api.rect(bx0, 4, Mathf.round(bw * f), 3, low ? E : D);
        if (this.mode != MODE_OVER) {
            let cs = "COURT " + (this.court + 1).toString();
            let cw = api.textWidth(cs, 1) + 3 + <f32>(this.nc * 6);
            let cx0 = Mathf.floor((<f32>w - cw) * 0.5);
            api.text(cx0, 11, cs, D, 1, A);
            let dx0 = cx0 + api.textWidth(cs, 1) + 5;
            for (let i = 0; i < this.nc; i++) {
                let x = dx0 + <f32>(i * 6);
                let col = this.cLit[i] ? E : C;
                api.rect(x - 1, 11, 3, 5, A);
                api.rect(x - 2, 12, 5, 3, A);
                api.rect(x, 11, 1, 1, col);
                api.rect(x - 1, 12, 3, 2, col);
                api.rect(x, 14, 1, 1, col);
            }
        }

        // a pop over the temple when a court is solved
        if (this.popT < 1.6) {
            let y = <f32>(48 - Math.min(this.popT, 0.4) * 15);
            if (Math.floor(this.popT * 12) % 2 == 0 || this.popT > 0.4) {
                api.textCentered(y, this.popText, E, 2, A);
                api.textCentered(y + 12, this.popText2, D, 1, A);
            }
        }

        if (this.mode == MODE_READY) {
            if (Math.floor(this.hintT * 2) % 3 != 2) {
                api.textCentered(<f32>api.hudH - 10, "CLICK A MIRROR TO TURN IT", E, 1, A);
            }
            api.textCentered(<f32>api.hudH - 18, "LIGHT EVERY CRYSTAL BEFORE SUNSET", D, 1, A);
        }
        if (this.mode == MODE_OVER) {
            let y: f32 = 46;
            api.rect(30, y - 6, <f32>w - 60, 40, A);
            api.rect(31, y - 5, <f32>w - 62, 38, B);
            api.textCentered(y, "THE SUN HAS SET", E, 2, A);
            api.textCentered(y + 14, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), D, 1, A);
            if (this.t > 0.8 && !api.demo && Math.floor(this.t * 2) % 3 != 2) {
                api.textCentered(y + 23, "CLICK TO PLAY AGAIN", C, 1, A);
            }
        }

        // the demo's pointer: a small arrow that dips when it clicks
        if (api.demo && this.mode == MODE_PLAY) {
            let px = <f32>Math.round(this.dCurX), py = <f32>Math.round(this.dCurY);
            if (this.dPress < 0.12) py += 1;
            api.rect(px, py, 1, 7, A);
            api.rect(px + 1, py + 1, 1, 6, E);
            api.rect(px + 2, py + 2, 1, 4, E);
            api.rect(px + 3, py + 3, 1, 2, E);
            api.rect(px + 4, py + 4, 1, 1, E);
            api.rect(px + 1, py + 7, 4, 1, A);
            api.rect(px + 5, py + 4, 1, 2, A);
            api.rect(px + 2, py, 1, 1, A);
        }
    }
}
