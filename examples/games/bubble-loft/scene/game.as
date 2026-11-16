// Bubble Loft: a rooftop greenhouse at sunset. The orb puffer (a copper atomizer with a tulip mouth and
// a squeeze bulb) puffs coloured glass orbs up at a cluster clinging to a hanging rafter. Press and drag
// to aim (a dotted guide shows one wall bounce), release to launch; a plain tap launches toward the
// tap; tap the orb waiting in the side cup to swap it with the loaded one. An orb sticks where it
// touches; three or more of one colour pop, and whatever no longer hangs from the rafter falls (bonus).
// Every few shots the rafter drops a row; an orb below the brass sill ends the run. Clear the rafter
// for a bonus and a new cluster. Pointer only (touch-ready: no hover needed); demo mode plays itself.
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP, SFX_BELL, SFX_BLIP, SFX_CLICK, SFX_LOSE, SFX_NOTE,
    SFX_POP, SFX_THUD, SFX_TICK, SFX_WHOOSH, SFX_WIN } from "./game_api";

// run states
const ST_PLAY: i32 = 0;    // aiming and shooting (before the first shot: the hint)
const ST_CLEAR: i32 = 1;   // the rafter is bare: bonus, then it rises and a new cluster grows
const ST_OVER: i32 = 2;    // an orb crossed the sill
const ST_BUILD: i32 = 3;   // a new cluster grows on the rafter, row by row

// orb states (one per pooled bone)
const O_FREE: i32 = 0;     // hidden, in the pool
const O_GRID: i32 = 1;     // clinging to the cluster
const O_LOAD: i32 = 2;     // sitting in the tulip mouth, ready
const O_CUP: i32 = 3;      // waiting in the side cup (the next orb)
const O_MOVE: i32 = 4;     // rolling from the cup up into the mouth
const O_FLY: i32 = 5;      // the shot
const O_POP: i32 = 6;      // bursting
const O_FALL: i32 = 7;     // dropping off the cluster to the floor
const O_SWAP: i32 = 8;     // trading places between mouth and cup

// the loft (glTF metres; models/env/make_env.py and models/puffer/make_puffer.py use the same numbers)
const R: f64 = 0.46;               // orb radius
const CW: f64 = 0.92;              // cell width (2 R)
const RH: f64 = 0.7967;            // row height (R * sqrt 3)
const FIELD_X: f64 = 3.68;         // the window's inner half width
const XW: f64 = 3.22;              // where an orb's centre meets a post (FIELD_X - R)
const BEAM_Y: f64 = 9.75;          // the rafter's underside at rest
const SILL_Y: f64 = 3.2;           // the brass sill's top: the danger line
const LOST: i32 = 8;               // a cell row r is past the sill when r + drops >= LOST
const ROWS: i32 = 9;
const COLS: i32 = 8;
const PIV_X: f64 = 0.0;            // the barrel's pivot (the lid's top; the puffer is baked at 1.15)
const PIV_Y: f64 = 1.53;
const MUZZLE: f64 = 1.15;          // pivot -> the loaded orb's centre
const CUP_X: f64 = 1.23;           // the next orb in the side cup
const CUP_Y: f64 = 1.34;
const CUP_S: f64 = 0.75;
const SPEED: f64 = 15.0;           // m/s
const HIT_D: f64 = 0.78;           // centre distance at which a shot touches a clinging orb (1.7 R)
const MIN_A: f64 = 12.0;           // aim limits, degrees from the +x axis
const MAX_A: f64 = 168.0;
const G: f64 = 22.0;               // gravity for falling orbs
const FLOOR_Y: f64 = 0.46;         // a fallen orb's centre on the floor
const FALL_Z: f64 = 0.75;          // falling orbs pass in front of the puffer

const NCOL: i32 = 4;               // dusk (navy), rose (pink), ember (orange), sun (cream)
const PER: i32 = 14;               // pooled orbs per colour
const NPART: i32 = 96;             // HUD shards

// palette indices (art/palette.json "colors")
const P_CREAM: i32 = 0;
const P_YELLOW: i32 = 1;
const P_GOLD: i32 = 2;
const P_ORANGE: i32 = 3;
const P_SALMON: i32 = 4;
const P_PINK: i32 = 5;
const P_PLUM: i32 = 6;
const P_NAVY: i32 = 7;
// each orb colour's shard colours (lit, base)
const SHARD_A: StaticArray<i32> = [P_PLUM, P_CREAM, P_CREAM, P_CREAM];
const SHARD_B: StaticArray<i32> = [P_NAVY, P_PINK, P_ORANGE, P_GOLD];
const COL_NAME: StaticArray<string> = ["dusk", "rose", "ember", "sun"];
// a pentatonic scale for the pops (MIDI), climbing with the group
const SCALE: StaticArray<f64> = [72, 74, 76, 79, 81, 84, 86, 88, 91, 93, 96, 98];

export class Game {
    state: i32 = ST_PLAY;
    stateT: f64 = 0;
    started: bool = false;        // false: the hint shows until the first shot
    wasDemo: bool = false;
    score: i32 = 0;
    best: i32 = 0;
    board: i32 = 1;               // clusters cleared this run + 1
    combo: i32 = 0;               // consecutive shots that popped something
    shots: i32 = 0;               // shots since the rafter last dropped
    dropEvery: i32 = 8;
    drops: i32 = 0;
    beamY: f64 = BEAM_Y;          // shown (eased towards BEAM_Y - drops * RH)
    beamV: f64 = 0;
    buildK: i32 = 0;              // cells visited so far in ST_BUILD
    buildN: i32 = 0;              // orbs grown so far
    buildT: f64 = 0;
    buildRows: i32 = 5;
    warned: bool = false;         // the danger warning played for the present low row

    // bones
    barrel: i32 = -1;
    bulb: i32 = -1;
    beam: i32 = -1;
    pool: StaticArray<i32> = new StaticArray<i32>(NCOL * PER);

    // the grid: colour (-1 empty) and the orb's bone per cell (row * COLS + col)
    gc: StaticArray<i32> = new StaticArray<i32>(ROWS * COLS);
    gb: StaticArray<i32> = new StaticArray<i32>(ROWS * COLS);

    // per bone (indices 0..63)
    oSt: StaticArray<i32> = new StaticArray<i32>(64);
    oCol: StaticArray<i32> = new StaticArray<i32>(64);
    oX: StaticArray<f64> = new StaticArray<f64>(64);
    oY: StaticArray<f64> = new StaticArray<f64>(64);
    oZ: StaticArray<f64> = new StaticArray<f64>(64);
    oVX: StaticArray<f64> = new StaticArray<f64>(64);
    oVY: StaticArray<f64> = new StaticArray<f64>(64);
    oT: StaticArray<f64> = new StaticArray<f64>(64);
    oS: StaticArray<f64> = new StaticArray<f64>(64);      // grow-in scale for new cluster orbs
    oJig: StaticArray<f64> = new StaticArray<f64>(64);    // a knock's wobble
    oSpin: StaticArray<f64> = new StaticArray<f64>(64);
    oHid: StaticArray<bool> = new StaticArray<bool>(64);
    oFX: StaticArray<f64> = new StaticArray<f64>(64);     // a move's start point
    oFY: StaticArray<f64> = new StaticArray<f64>(64);
    oN: StaticArray<i32> = new StaticArray<i32>(64);      // a falling orb's floor bounces

    loaded: i32 = -1;             // bone in the mouth
    next: i32 = -1;               // bone in the cup
    shot: i32 = -1;               // bone in flight
    queued: bool = false;         // released while not ready: launch when ready
    starve: f64 = 0;              // seconds with no orb to load

    // aim
    aimA: f64 = 90;               // target angle (degrees)
    barA: f64 = 90;               // the barrel's shown angle
    aiming: bool = false;         // a press is held for aiming
    swapPress: bool = false;      // the press began on the cup
    recoil: f64 = 0;
    squeeze: f64 = 0;

    // trace results
    trX: f64 = 0;
    trY: f64 = 0;
    trBX: f64 = 0;
    trBY: f64 = 0;
    trB: i32 = 0;
    trHit: bool = false;
    trCell: i32 = -1;

    // scratch for flood fills
    mark: StaticArray<i32> = new StaticArray<i32>(ROWS * COLS);
    stack: StaticArray<i32> = new StaticArray<i32>(ROWS * COLS);
    gc2: StaticArray<i32> = new StaticArray<i32>(ROWS * COLS);

    // HUD shards and labels
    pT: StaticArray<f64> = new StaticArray<f64>(NPART);
    pX: StaticArray<f64> = new StaticArray<f64>(NPART);
    pY: StaticArray<f64> = new StaticArray<f64>(NPART);
    pVX: StaticArray<f64> = new StaticArray<f64>(NPART);
    pVY: StaticArray<f64> = new StaticArray<f64>(NPART);
    pC: StaticArray<i32> = new StaticArray<i32>(NPART);
    pNext: i32 = 0;
    popT: f64 = -1;
    popX: f32 = 0;
    popY: f32 = 0;
    popText: string = "";
    popBig: bool = false;
    bannerT: f64 = -1;
    banner: string = "";
    shakeT: f64 = 0;
    eyeY0: f64 = 0;
    tgtY0: f64 = 0;

    // the demo player
    dThink: f64 = 0.1;
    dPlan: bool = false;
    dAim: f64 = 90;
    dSwap: bool = false;
    dHold: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        this.barrel = api.bone("barrel");
        this.bulb = api.bone("bulb");
        this.beam = api.bone("beam");
        for (let c = 0; c < NCOL; c++) {
            for (let k = 0; k < PER; k++) {
                let b = api.bone(COL_NAME[c] + k.toString());
                this.pool[c * PER + k] = b;
                if (b > 0) {
                    this.oCol[b] = c;
                    this.oSt[b] = O_FREE;
                    this.oSpin[b] = <f64>((b * 47) % 360);
                    api.hide(b);
                    this.oHid[b] = true;
                }
            }
        }
        for (let i = 0; i < NPART; i++) {
            this.pT[i] = -1;
        }
        this.eyeY0 = api.eyeY;
        this.tgtY0 = api.targetY;
        this.wasDemo = api.demo;
        this.newRun(api, true);
    }

    // ------------------------------------------------------------------ cells

    valid(r: i32, c: i32): bool {
        return r >= 0 && r < ROWS && c >= 0 && c < ((r & 1) == 0 ? COLS : COLS - 1);
    }
    cellX(i: i32): f64 {
        let r = i / COLS, c = i % COLS;
        return -XW + CW * <f64>c + ((r & 1) == 1 ? R : 0.0);
    }
    cellYAt(i: i32, beamY: f64): f64 {
        return beamY - R - RH * <f64>(i / COLS);
    }
    logicBeam(): f64 {
        return BEAM_Y - RH * <f64>this.drops;
    }
    // the six neighbours of cell i: -1 where there is none
    nb(i: i32, k: i32): i32 {
        let r = i / COLS, c = i % COLS;
        let even = (r & 1) == 0;
        let rr = r, cc = c;
        if (k == 0) { cc = c - 1; }
        else if (k == 1) { cc = c + 1; }
        else if (k == 2) { rr = r - 1; cc = even ? c - 1 : c; }
        else if (k == 3) { rr = r - 1; cc = even ? c : c + 1; }
        else if (k == 4) { rr = r + 1; cc = even ? c - 1 : c; }
        else { rr = r + 1; cc = even ? c : c + 1; }
        return this.valid(rr, cc) ? rr * COLS + cc : -1;
    }
    count(): i32 {
        let n = 0;
        for (let i = 0; i < ROWS * COLS; i++) {
            if (this.gc[i] >= 0) { n++; }
        }
        return n;
    }
    lowestRow(): i32 {
        let low = -1;
        for (let i = 0; i < ROWS * COLS; i++) {
            if (this.gc[i] >= 0 && i / COLS > low) { low = i / COLS; }
        }
        return low;
    }

    // ------------------------------------------------------------------ pool

    alloc(c: i32): i32 {
        for (let k = 0; k < PER; k++) {
            let b = this.pool[c * PER + k];
            if (b > 0 && this.oSt[b] == O_FREE) {
                return b;
            }
        }
        return -1;
    }
    freeOf(c: i32): i32 {
        let n = 0;
        for (let k = 0; k < PER; k++) {
            let b = this.pool[c * PER + k];
            if (b > 0 && this.oSt[b] == O_FREE) { n++; }
        }
        return n;
    }
    present(c: i32): bool {
        for (let i = 0; i < ROWS * COLS; i++) {
            if (this.gc[i] == c) { return true; }
        }
        return false;
    }
    // a colour for the next orb: one the cluster still has, with a free orb in the pool
    pickColour(api: GameApi): i32 {
        let any = this.count() > 0;
        let n = 0;
        let cand = new StaticArray<i32>(NCOL);
        for (let c = 0; c < NCOL; c++) {
            if (this.freeOf(c) > 0 && (!any || this.present(c))) {
                cand[n++] = c;
            }
        }
        if (n == 0) {
            for (let c = 0; c < NCOL; c++) {
                if (this.freeOf(c) > 0) { cand[n++] = c; }
            }
        }
        if (n == 0) {
            return -1;
        }
        return cand[min<i32>(n - 1, <i32>Math.floor(api.rand() * <f64>n))];
    }
    // the mouth and the cup keep colours the cluster still has
    refresh(api: GameApi): void {
        if (this.count() == 0) {
            return;
        }
        if (this.loaded > 0 && this.oSt[this.loaded] == O_LOAD && !this.present(this.oCol[this.loaded])) {
            let c = this.pickColour(api);
            let b = c >= 0 ? this.alloc(c) : -1;
            if (b > 0) {
                this.oSt[this.loaded] = O_FREE;
                this.oSt[b] = O_LOAD;
                this.oS[b] = 1;
                this.loaded = b;
            }
        }
        if (this.next > 0 && this.oSt[this.next] == O_CUP && !this.present(this.oCol[this.next])) {
            let c = this.pickColour(api);
            let b = c >= 0 ? this.alloc(c) : -1;
            if (b > 0) {
                this.oSt[this.next] = O_FREE;
                this.oSt[b] = O_CUP;
                this.oS[b] = 1;
                this.next = b;
            }
        }
    }

    // ------------------------------------------------------------------ runs and boards

    newRun(api: GameApi, first: bool): void {
        this.score = 0;
        this.board = 1;
        this.combo = 0;
        this.started = false;
        this.queued = false;
        this.aiming = false;
        this.swapPress = false;
        this.dThink = 0.1;
        this.dPlan = false;
        // every orb back to the pool; the old cluster bursts in a quick wave from the rafter down
        for (let i = 0; i < ROWS * COLS; i++) {
            let b = this.gb[i];
            if (b > 0 && !first && this.oSt[b] == O_GRID) {
                this.oSt[b] = O_POP;
                this.oT[b] = -0.012 * <f64>i;
                this.oX[b] = this.cellX(i);
                this.oY[b] = this.cellYAt(i, this.beamY);
            }
        }
        for (let i = 0; i < NCOL * PER; i++) {
            let b = this.pool[i];
            if (b <= 0) { continue; }
            let s = this.oSt[b];
            if (first || (s != O_POP && s != O_FALL)) {
                this.oSt[b] = O_FREE;
            }
        }
        for (let i = 0; i < ROWS * COLS; i++) {
            this.gc[i] = -1;
            this.gb[i] = -1;
        }
        this.loaded = -1;
        this.next = -1;
        this.shot = -1;
        this.beginBoard(api, first);
    }

    beginBoard(api: GameApi, instant: bool): void {
        this.drops = 0;
        this.shots = 0;
        this.warned = false;
        this.dropEvery = max<i32>(4, 9 - this.board);
        this.buildRows = min<i32>(5, 3 + this.board);
        this.genBoard(api);
        this.state = ST_BUILD;
        this.stateT = 0;
        this.buildK = 0;
        this.buildN = 0;
        this.buildT = instant ? 99.0 : -0.3;   // the first board is there from the first frame
    }

    // fills the rows with clumps of colour (a cell often copies a neighbour above or to its left),
    // capping each colour so the pool can always load a shot of it
    genBoard(api: GameApi): void {
        let cap = PER - 4;
        let cnt = new StaticArray<i32>(NCOL);
        let ncol = this.board == 1 ? 3 : NCOL;
        let off = <i32>Math.floor(api.rand() * 4.0) % NCOL;
        for (let r = 0; r < this.buildRows; r++) {
            for (let c = 0; c < COLS; c++) {
                if (!this.valid(r, c)) { continue; }
                let i = r * COLS + c;
                let col = -1;
                let u = api.rand();
                if (u < 0.5) {
                    let k = u < 0.25 ? 0 : (u < 0.38 ? 2 : 3);  // left, upper left, upper right
                    let j = this.nb(i, k);
                    if (j >= 0 && this.gc2[j] >= 0) { col = this.gc2[j]; }
                }
                if (col < 0 || cnt[col] >= cap) {
                    col = (off + <i32>Math.floor(api.rand() * <f64>ncol)) % NCOL;
                    for (let t = 0; t < NCOL && cnt[col] >= cap; t++) {
                        col = (col + 1) % NCOL;
                    }
                }
                cnt[col]++;
                this.gc2[i] = col;
            }
        }
        // gc2 holds the plan; ST_BUILD grows it into gc
        for (let i = 0; i < ROWS * COLS; i++) {
            let r = i / COLS;
            if (r >= this.buildRows || !this.valid(r, i % COLS)) {
                this.gc2[i] = -1;
            }
        }
    }

    // grows planned cells, a few per frame (as falling orbs free their bones), then loads the puffer
    build(api: GameApi, dt: f64): void {
        this.buildT += dt;
        if (this.buildT < 0) {
            return;
        }
        let want = this.buildT > 50 ? 999 : <i32>Math.floor(this.buildT / 0.018);
        while (this.buildK < ROWS * COLS && this.buildN < want) {
            let i = this.buildK;
            let col = this.gc2[i];
            if (col < 0) {
                this.buildK++;
                continue;
            }
            let b = this.alloc(col);
            if (b <= 0 && this.buildT < 4.0) {
                break;      // the old cluster is still bursting: wait for an orb of this colour
            }
            this.buildK++;
            if (b <= 0) { continue; }
            this.buildN++;
            this.gc[i] = col;
            this.gb[i] = b;
            this.oSt[b] = O_GRID;
            this.oS[b] = this.buildT > 50 ? 1.0 : 0.3;
            this.oJig[b] = 0;
            if (this.buildT < 50 && (this.buildN % 3) == 0) {
                api.soundAt(SFX_TICK, this.cellX(i), this.cellYAt(i, this.beamY), 0, 1.4 + 0.02 * <f64>(i % 9), 0.25);
            }
        }
        if (this.buildK >= ROWS * COLS) {
            if (this.loaded <= 0) { this.loadNext(api, true); }
            if (this.next <= 0) { this.fillCup(api); }
            this.refresh(api);
            this.state = ST_PLAY;
            this.stateT = 0;
        }
    }

    fillCup(api: GameApi): void {
        let c = this.pickColour(api);
        let b = c >= 0 ? this.alloc(c) : -1;
        if (b > 0) {
            this.oSt[b] = O_CUP;
            this.oS[b] = 0.3;
            this.next = b;
        } else {
            this.next = -1;
        }
    }

    // the cup's orb rolls up into the mouth; a new one drops into the cup
    loadNext(api: GameApi, direct: bool): void {
        if (this.next <= 0 || direct) {
            if (this.next > 0) {
                this.loaded = this.next;
                this.next = -1;
            } else {
                let c = this.pickColour(api);
                this.loaded = c >= 0 ? this.alloc(c) : -1;
            }
            if (this.loaded > 0) {
                this.oSt[this.loaded] = O_LOAD;
                this.oS[this.loaded] = 1;
            }
            return;
        }
        let b = this.next;
        this.loaded = b;
        this.oSt[b] = O_MOVE;
        this.oT[b] = 0;
        this.oFX[b] = CUP_X;
        this.oFY[b] = CUP_Y;
        this.next = -1;
        this.fillCup(api);
    }

    endRun(api: GameApi): void {
        this.state = ST_OVER;
        this.stateT = 0;
        this.aiming = false;
        this.queued = false;
        let record = this.score > this.best;
        if (record) {
            this.best = this.score;
        }
        api.sound(SFX_LOSE, 1.0, 0.7);
        let notes: StaticArray<f64> = [76, 72, 67, 64, 60];
        for (let k = 0; k < 5; k++) {
            api.note(notes[k], 0.5, 0, SFX_BELL, 0.35 + 0.16 * <f64>k);
        }
        if (record && this.score > 0) {
            api.note(84, 0.45, 0, SFX_BELL, 1.3);
            api.note(88, 0.45, 0, SFX_BELL, 1.42);
        }
        // the cluster dims: every clinging orb shivers once
        for (let i = 0; i < ROWS * COLS; i++) {
            if (this.gb[i] > 0) { this.oJig[this.gb[i]] = 0.5; }
        }
    }

    // ------------------------------------------------------------------ shooting

    ready(): bool {
        return this.state == ST_PLAY && this.shot <= 0 && this.loaded > 0 && this.oSt[this.loaded] == O_LOAD;
    }

    fire(api: GameApi): bool {
        if (!this.ready()) {
            return false;
        }
        let b = this.loaded;
        let a = this.aimA * Math.PI / 180.0;
        let dx = Math.cos(a), dy = Math.sin(a);
        this.barA = this.aimA;
        this.oSt[b] = O_FLY;
        this.oX[b] = PIV_X + dx * MUZZLE;
        this.oY[b] = PIV_Y + dy * MUZZLE;
        this.oZ[b] = 0;
        this.oVX[b] = dx * SPEED;
        this.oVY[b] = dy * SPEED;
        this.oS[b] = 1;
        this.shot = b;
        this.loaded = -1;
        this.recoil = 1;
        this.squeeze = 1;
        this.started = true;
        this.queued = false;
        this.loadNext(api, false);
        let pan = api.panAt(this.oX[b], this.oY[b], 0);
        api.sound(SFX_WHOOSH, 1.5, 0.45, pan);           // the bulb's puff
        api.sound(SFX_POP, 0.62, 0.7, pan);              // the orb leaves the tulip
        api.sound(SFX_CLICK, 0.8, 0.35, pan, 0.18);      // the next orb clicks into the mouth
        return true;
    }

    swap(api: GameApi): bool {
        if (!this.ready() || this.next <= 0 || this.oSt[this.next] != O_CUP) {
            return false;
        }
        let a = this.loaded, b = this.next;
        this.oSt[a] = O_SWAP;
        this.oT[a] = 0;
        this.oFX[a] = PIV_X + Math.cos(this.barA * Math.PI / 180.0) * MUZZLE;
        this.oFY[a] = PIV_Y + Math.sin(this.barA * Math.PI / 180.0) * MUZZLE;
        this.oSt[b] = O_MOVE;
        this.oT[b] = 0;
        this.oFX[b] = CUP_X;
        this.oFY[b] = CUP_Y;
        this.loaded = b;
        this.next = a;
        this.squeeze = 0.4;
        api.soundAt(SFX_BLIP, CUP_X, CUP_Y, 0, 1.3, 0.5);
        api.soundAt(SFX_CLICK, CUP_X, CUP_Y, 0, 1.1, 0.4, 0.12);
        return true;
    }

    // Follows a shot from (x, y) along angle aDeg: walls bounce it (at most maxB times); it stops on
    // the rafter or on touching a clinging orb. trX/trY end, trBX/trBY the first bounce, trB bounces,
    // trHit whether it stuck, trCell the cell it would settle in.
    trace(x0: f64, y0: f64, aDeg: f64, maxB: i32, beamY: f64): void {
        let a = aDeg * Math.PI / 180.0;
        let dx = Math.cos(a), dy = Math.sin(a);
        let x = x0, y = y0;
        this.trB = 0;
        this.trHit = false;
        this.trCell = -1;
        let step = 0.05;
        let hd2 = HIT_D * HIT_D;
        for (let s = 0; s < 600; s++) {
            x += dx * step;
            y += dy * step;
            if (x < -XW || x > XW) {
                x = x < -XW ? -2.0 * XW - x : 2.0 * XW - x;
                dx = -dx;
                if (this.trB == 0) {
                    this.trBX = x;
                    this.trBY = y;
                }
                this.trB++;
                if (this.trB > maxB) {
                    break;
                }
            }
            if (y >= beamY - R) {
                y = beamY - R;
                this.trHit = true;
                break;
            }
            let hit = false;
            for (let i = 0; i < ROWS * COLS; i++) {
                if (this.gc[i] < 0) { continue; }
                let cy = this.cellYAt(i, beamY);
                let ddy = cy - y;
                if (ddy > HIT_D || ddy < -HIT_D) { continue; }
                let ddx = this.cellX(i) - x;
                if (ddx * ddx + ddy * ddy < hd2) {
                    hit = true;
                    break;
                }
            }
            if (hit) {
                this.trHit = true;
                break;
            }
        }
        this.trX = x;
        this.trY = y;
        if (this.trHit) {
            this.trCell = this.snap(x, y, beamY);
        }
    }

    // the empty cell nearest (x, y) that hangs from the rafter or touches an orb
    snap(x: f64, y: f64, beamY: f64): i32 {
        let best = -1;
        let bd = 1e9;
        for (let i = 0; i < ROWS * COLS; i++) {
            let r = i / COLS;
            if (!this.valid(r, i % COLS) || this.gc[i] >= 0) { continue; }
            let ok = r == 0;
            for (let k = 0; k < 6 && !ok; k++) {
                let j = this.nb(i, k);
                if (j >= 0 && this.gc[j] >= 0) { ok = true; }
            }
            if (!ok) { continue; }
            let ddx = this.cellX(i) - x, ddy = this.cellYAt(i, beamY) - y;
            let d = ddx * ddx + ddy * ddy;
            if (d < bd) {
                bd = d;
                best = i;
            }
        }
        return best;
    }

    // same-colour group from cell i in grid g (marks in this.mark with tag); returns its size
    group(g: StaticArray<i32>, i: i32, tag: i32): i32 {
        let col = g[i];
        let n = 0, sp = 0;
        this.stack[sp++] = i;
        this.mark[i] = tag;
        while (sp > 0) {
            let j = this.stack[--sp];
            n++;
            for (let k = 0; k < 6; k++) {
                let m = this.nb(j, k);
                if (m >= 0 && g[m] == col && this.mark[m] != tag) {
                    this.mark[m] = tag;
                    this.stack[sp++] = m;
                }
            }
        }
        return n;
    }
    // marks (tag) every orb of grid g hanging from the rafter; returns how many do NOT
    hanging(g: StaticArray<i32>, tag: i32): i32 {
        let sp = 0;
        for (let c = 0; c < COLS; c++) {
            if (g[c] >= 0 && this.mark[c] != tag) {
                this.mark[c] = tag;
                this.stack[sp++] = c;
            }
        }
        while (sp > 0) {
            let j = this.stack[--sp];
            for (let k = 0; k < 6; k++) {
                let m = this.nb(j, k);
                if (m >= 0 && g[m] >= 0 && this.mark[m] != tag) {
                    this.mark[m] = tag;
                    this.stack[sp++] = m;
                }
            }
        }
        let loose = 0;
        for (let i = 0; i < ROWS * COLS; i++) {
            if (g[i] >= 0 && this.mark[i] != tag) { loose++; }
        }
        return loose;
    }

    clearMarks(): void {
        for (let i = 0; i < ROWS * COLS; i++) { this.mark[i] = 0; }
    }

    // the shot settles in cell i: pops, falls, score, the rafter, the end
    settle(api: GameApi, b: i32, i: i32): void {
        let col = this.oCol[b];
        this.gc[i] = col;
        this.gb[i] = b;
        this.oSt[b] = O_GRID;
        this.oS[b] = 1;
        this.oJig[b] = 0.0;
        this.shot = -1;
        let x = this.cellX(i), y = this.cellYAt(i, this.beamY);
        api.soundAt(SFX_CLICK, x, y, 0, 0.9, 0.55);
        api.noteAt(88, x, y, 0, 0.18, SFX_NOTE);          // a glassy clink
        // the neighbours wobble
        for (let k = 0; k < 6; k++) {
            let j = this.nb(i, k);
            if (j >= 0 && this.gb[j] > 0) { this.oJig[this.gb[j]] = 0.25; }
        }
        this.clearMarks();
        let n = this.group(this.gc, i, 1);
        let popped = 0, fell = 0;
        if (n >= 3) {
            this.combo++;
            let mult = min<i32>(this.combo, 5);
            // pop the group, nearest first
            for (let j = 0; j < ROWS * COLS; j++) {
                if (this.mark[j] != 1) { continue; }
                let bj = this.gb[j];
                let d = Math.sqrt((this.cellX(j) - x) * (this.cellX(j) - x) + (this.cellYAt(j, this.beamY) - y) * (this.cellYAt(j, this.beamY) - y));
                this.oSt[bj] = O_POP;
                this.oT[bj] = -d * 0.045;
                this.oX[bj] = this.cellX(j);
                this.oY[bj] = this.cellYAt(j, this.beamY);
                this.gc[j] = -1;
                this.gb[j] = -1;
            }
            popped = n;
            // the pops climb in pitch with the group (and the combo lifts the start)
            let base = min<i32>(this.combo - 1, 3);
            for (let k = 0; k < n; k++) {
                let dl = 0.055 * <f64>k;
                api.soundAt(SFX_POP, x, y, 0, 1.0 + 0.09 * <f64>k + 0.1 * <f64>base, 0.75, dl);
                api.noteAt(SCALE[min<i32>(k + base, 11)], x, y, 0, 0.32, SFX_NOTE, dl);
            }
            // what no longer hangs falls
            this.clearMarks();
            let loose = this.hanging(this.gc, 2);
            if (loose > 0) {
                let k = 0;
                for (let j = 0; j < ROWS * COLS; j++) {
                    if (this.gc[j] >= 0 && this.mark[j] != 2) {
                        let bj = this.gb[j];
                        this.oX[bj] = this.cellX(j);
                        this.oY[bj] = this.cellYAt(j, this.beamY);
                        this.startFall(bj, 0.1 + 0.03 * <f64>k);
                        this.gc[j] = -1;
                        this.gb[j] = -1;
                        k++;
                    }
                }
                fell = loose;
                // the cascade: a falling run of glassy notes
                for (let q = 0; q < min<i32>(fell, 10); q++) {
                    api.note(SCALE[max<i32>(0, 9 - q)], 0.3, 0, SFX_BELL, 0.18 + 0.07 * <f64>q);
                }
                api.sound(SFX_WHOOSH, 0.7, 0.4, 0, 0.12);
            }
            let pts = (10 * popped + 30 * fell + (fell >= 5 ? 100 : 0)) * mult;
            this.score += pts;
            let p = this.project(api, x, y);
            this.popX = p ? api.screenX : <f32>106;
            this.popY = p ? api.screenY : <f32>60;
            this.popText = "+" + pts.toString();
            this.popBig = fell >= 4 || mult >= 3;
            this.popT = 0;
            if (mult >= 2) {
                this.banner = "COMBO X" + mult.toString();
                this.bannerT = 0;
            }
            if (fell >= 5) {
                this.banner = "AVALANCHE!";
                this.bannerT = 0;
            }
        } else {
            this.combo = 0;
        }
        // shards
        this.shots++;
        if (this.count() == 0) {
            this.cleared(api);
            return;
        }
        this.refresh(api);
        if (this.shots >= this.dropEvery) {
            this.dropRafter(api);
        } else if (this.shots == this.dropEvery - 1) {
            // one shot left before the rafter drops: two quick creaks
            api.sound(SFX_BLIP, 0.8, 0.45);
            api.sound(SFX_BLIP, 0.7, 0.45, 0, 0.12);
        }
        this.checkLine(api);
    }

    startFall(b: i32, delay: f64): void {
        this.oSt[b] = O_FALL;
        this.oT[b] = -delay;
        this.oVX[b] = <f64>((b * 37) % 11 - 5) * 0.12;
        this.oVY[b] = 1.2;
        this.oN[b] = 0;
        this.oZ[b] = FALL_Z;
    }

    dropRafter(api: GameApi): void {
        this.shots = 0;
        this.drops++;
        this.shakeT = 0.32;
        api.sound(SFX_THUD, 0.6, 1.0);
        api.sound(SFX_CLICK, 0.5, 0.5, -0.4, 0.05);
        api.sound(SFX_CLICK, 0.45, 0.5, 0.4, 0.1);
        for (let i = 0; i < ROWS * COLS; i++) {
            if (this.gb[i] > 0) { this.oJig[this.gb[i]] = 0.3; }
        }
    }

    // an orb at or past the sill ends the run; one row above it warns
    checkLine(api: GameApi): void {
        let low = this.lowestRow();
        if (low >= 0 && low + this.drops >= LOST) {
            this.endRun(api);
            return;
        }
        let danger = low >= 0 && low + this.drops >= LOST - 1;
        if (danger && !this.warned) {
            api.note(93, 0.4, 0, SFX_BELL);
            api.note(93, 0.4, 0, SFX_BELL, 0.16);
            api.note(93, 0.4, 0, SFX_BELL, 0.32);
        }
        this.warned = danger;
    }

    cleared(api: GameApi): void {
        let bonus = 500 * this.board;
        this.score += bonus;
        this.banner = "CLEAR! +" + bonus.toString();
        this.bannerT = 0;
        this.state = ST_CLEAR;
        this.stateT = 0;
        this.board++;
        api.sound(SFX_WIN, 1.0, 0.8, 0, 0.15);
        let notes: StaticArray<f64> = [72, 76, 79, 84, 79, 84, 88];
        for (let k = 0; k < 7; k++) {
            api.note(notes[k], 0.5, 0, k < 4 ? SFX_NOTE : SFX_BELL, 0.15 + 0.1 * <f64>k);
        }
    }

    project(api: GameApi, x: f64, y: f64): bool {
        return api.project(<f32>x, <f32>y, 0);
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged || api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.newRun(api, false);
            this.combo = 0;
        }
        this.stateT += dt;
        if (this.state == ST_BUILD) {
            this.build(api, dt);
        } else if (this.state == ST_CLEAR) {
            if (this.stateT > 1.4) {
                this.beginBoard(api, false);
            }
        }
        if (api.demo) {
            this.demoThink(api, dt);
            if (this.state == ST_OVER && this.stateT > 2.0) {
                this.newRun(api, false);
            }
        }
        // the pool ran dry (a huge cluster, orbs still falling): load as soon as one is free; a loft
        // with no orb left to load for a while is full, and the run ends
        if (this.state == ST_PLAY && this.shot <= 0 && this.loaded <= 0) {
            this.loadNext(api, true);
            this.starve = this.loaded > 0 ? 0.0 : this.starve + dt;
            if (this.starve > 2.5) {
                this.endRun(api);
            }
        }
        if (this.state == ST_PLAY && this.next <= 0 && this.loaded > 0 && this.oSt[this.loaded] == O_LOAD) {
            this.fillCup(api);
        }
        if (this.queued && this.ready()) {
            this.fire(api);
        }
        // the barrel turns toward the aim
        let da = this.aimA - this.barA;
        this.barA += da * Math.min(1.0, dt * 18.0);
        this.updateBeam(dt);
        this.updateShot(api, dt);
        this.updateOrbs(api, dt);
        this.updatePuffer(api, dt);
        this.updateParts(dt);
        if (this.popT >= 0) {
            this.popT += dt;
            if (this.popT > 1.1) { this.popT = -1; }
        }
        if (this.bannerT >= 0) {
            this.bannerT += dt;
            if (this.bannerT > 1.6) { this.bannerT = -1; }
        }
        // a whole-texel shake when the rafter drops
        let texel = api.orthoHeight / 136.0;
        let off = 0.0;
        if (this.shakeT > 0) {
            this.shakeT -= dt;
            off = (Math.floor(this.shakeT * 30.0) % 2 == 0 ? 1.0 : -1.0) * texel;
        }
        api.eyeY = this.eyeY0 + off;
        api.targetY = this.tgtY0 + off;
    }

    updateBeam(dt: f64): void {
        // a spring toward the rafter's row: it drops with a bounce
        let target = this.state == ST_CLEAR && this.stateT > 0.6 ? BEAM_Y : this.logicBeam();
        if (this.state == ST_BUILD) { target = BEAM_Y; }
        let k = 160.0, damp = 14.0;
        this.beamV += ((target - this.beamY) * k - this.beamV * damp) * dt;
        this.beamY += this.beamV * dt;
    }

    updateShot(api: GameApi, dt: f64): void {
        let b = this.shot;
        if (b <= 0 || this.oSt[b] != O_FLY) {
            return;
        }
        let beamY = this.logicBeam();
        let dist = SPEED * dt;
        let steps = <i32>Math.ceil(dist / 0.05);
        let st = dist / <f64>steps;
        let vx = this.oVX[b] / SPEED, vy = this.oVY[b] / SPEED;
        let hd2 = HIT_D * HIT_D;
        for (let s = 0; s < steps; s++) {
            let x = this.oX[b] + vx * st, y = this.oY[b] + vy * st;
            if (x < -XW || x > XW) {
                x = x < -XW ? -2.0 * XW - x : 2.0 * XW - x;
                vx = -vx;
                api.soundAt(SFX_TICK, x, y, 0, 1.7, 0.6);   // the post: a wooden tick
                this.spray(api, x < 0 ? -FIELD_X : FIELD_X, y, 3, P_CREAM, P_YELLOW);
            }
            this.oX[b] = x;
            this.oY[b] = y;
            let hit = y >= beamY - R;
            if (hit) {
                this.oY[b] = beamY - R;
            }
            for (let i = 0; i < ROWS * COLS && !hit; i++) {
                if (this.gc[i] < 0) { continue; }
                let ddy = this.cellYAt(i, beamY) - y;
                if (ddy > HIT_D || ddy < -HIT_D) { continue; }
                let ddx = this.cellX(i) - x;
                if (ddx * ddx + ddy * ddy < hd2) { hit = true; }
            }
            if (hit) {
                this.oVX[b] = vx * SPEED;
                this.oVY[b] = vy * SPEED;
                let cell = this.snap(this.oX[b], this.oY[b], beamY);
                if (cell < 0) {
                    // nowhere to cling (a full rafter): it falls
                    this.shot = -1;
                    this.startFall(b, 0);
                    this.oX[b] = x;
                    this.oY[b] = y;
                    return;
                }
                this.settle(api, b, cell);
                return;
            }
        }
        this.oVX[b] = vx * SPEED;
        this.oVY[b] = vy * SPEED;
    }

    updateOrbs(api: GameApi, dt: f64): void {
        let ba = this.barA * Math.PI / 180.0;
        let mx = PIV_X + Math.cos(ba) * MUZZLE, my = PIV_Y + Math.sin(ba) * MUZZLE;
        // a creaking rafter (one shot to go) shivers by a texel
        let creak = this.state == ST_PLAY && this.started && this.shots == this.dropEvery - 1
            && Math.floor(api.time * 8.0) % 2 == 0 ? api.orthoHeight / 136.0 : 0.0;
        for (let q = 0; q < NCOL * PER; q++) {
            let b = this.pool[q];
            if (b <= 0) { continue; }
            let s = this.oSt[b];
            if (s == O_FREE) {
                if (!this.oHid[b]) {
                    api.hide(b);
                    this.oHid[b] = true;
                }
                continue;
            }
            this.oHid[b] = false;
            let spin = this.oSpin[b];
            if (s == O_GRID) {
                let i = -1;
                for (let j = 0; j < ROWS * COLS; j++) {
                    if (this.gb[j] == b) { i = j; break; }
                }
                if (i < 0) { this.oSt[b] = O_FREE; continue; }
                if (this.oS[b] < 1) { this.oS[b] = Math.min(1.0, this.oS[b] + dt * 4.0); }
                let jig = 0.0;
                if (this.oJig[b] > 0) {
                    this.oJig[b] -= dt;
                    jig = Math.sin(this.oJig[b] * 60.0) * this.oJig[b] * 0.25;
                }
                let x = this.cellX(i);
                let y = this.cellYAt(i, this.beamY) + creak;
                this.oX[b] = x;
                this.oY[b] = y;
                api.place(b, x + jig, y, 0, spin, 0, jig * 30.0, this.oS[b]);
            } else if (s == O_LOAD) {
                this.oX[b] = mx;
                this.oY[b] = my;
                api.place(b, mx, my, 0, spin + api.time * 40.0, 0, 0, 1);
            } else if (s == O_CUP) {
                if (this.oS[b] < CUP_S) { this.oS[b] = Math.min(CUP_S, this.oS[b] + dt * 3.0); }
                api.place(b, CUP_X, CUP_Y - (CUP_S - this.oS[b]) * 0.6, 0, spin, 0, 0, this.oS[b]);
            } else if (s == O_MOVE || s == O_SWAP) {
                this.oT[b] += dt / 0.2;
                let t = Math.min(1.0, this.oT[b]);
                let tx = s == O_MOVE ? mx : CUP_X, ty = s == O_MOVE ? my : CUP_Y;
                let x = this.oFX[b] + (tx - this.oFX[b]) * t;
                let y = this.oFY[b] + (ty - this.oFY[b]) * t + Math.sin(t * Math.PI) * 0.6;
                let sc = s == O_MOVE ? CUP_S + (1.0 - CUP_S) * t : 1.0 - (1.0 - CUP_S) * t;
                api.place(b, x, y, 0.3, spin + t * 180.0, 0, 0, sc);
                if (t >= 1.0) {
                    this.oSt[b] = s == O_MOVE ? O_LOAD : O_CUP;
                    this.oS[b] = s == O_MOVE ? 1.0 : CUP_S;
                }
            } else if (s == O_FLY) {
                api.place(b, this.oX[b], this.oY[b], 0, spin + api.time * 720.0, 0, 0, 1);
            } else if (s == O_POP) {
                this.oT[b] += dt;
                let t = this.oT[b];
                if (t < 0) {
                    api.place(b, this.oX[b], this.oY[b], 0, spin, 0, 0, 1);
                } else if (t < 0.09) {
                    // a squeeze before it bursts
                    api.placeScaled(b, this.oX[b], this.oY[b], 0, spin, 1.0, 0.7, 1.0);
                } else {
                    this.spray(api, this.oX[b], this.oY[b], 7, SHARD_A[this.oCol[b]], SHARD_B[this.oCol[b]]);
                    this.oSt[b] = O_FREE;
                    api.hide(b);
                    this.oHid[b] = true;
                }
            } else if (s == O_FALL) {
                this.oT[b] += dt;
                if (this.oT[b] < 0) {
                    let jig = Math.sin(this.oT[b] * 70.0) * 0.05;
                    api.place(b, this.oX[b] + jig, this.oY[b], 0, spin, 0, 0, 1);
                    continue;
                }
                this.oVY[b] -= G * dt;
                this.oX[b] += this.oVX[b] * dt;
                this.oY[b] += this.oVY[b] * dt;
                this.oSpin[b] += this.oVX[b] * 200.0 * dt + 90.0 * dt;
                if (this.oX[b] < -XW - 0.3 || this.oX[b] > XW + 0.3) {
                    this.oVX[b] = -this.oVX[b];
                }
                if (this.oY[b] <= FLOOR_Y && this.oVY[b] < 0) {
                    this.oY[b] = FLOOR_Y;
                    this.oN[b]++;
                    let x = this.oX[b];
                    if (this.oN[b] >= 2 || this.state == ST_OVER || this.state == ST_BUILD) {
                        this.spray(api, x, FLOOR_Y, 6, SHARD_A[this.oCol[b]], SHARD_B[this.oCol[b]]);
                        this.oSt[b] = O_FREE;
                        api.hide(b);
                        this.oHid[b] = true;
                        api.soundAt(SFX_POP, x, FLOOR_Y, FALL_Z, 0.75, 0.4);
                        continue;
                    }
                    this.oVY[b] = -this.oVY[b] * 0.32;
                    this.oVX[b] *= 0.7;
                    api.soundAt(SFX_TICK, x, FLOOR_Y, FALL_Z, 1.1, 0.5);   // glass on planks
                }
                api.place(b, this.oX[b], this.oY[b], FALL_Z, this.oSpin[b], 0, this.oSpin[b] * 0.5, 1);
            }
        }
    }

    updatePuffer(api: GameApi, dt: f64): void {
        if (this.recoil > 0) { this.recoil = Math.max(0.0, this.recoil - dt * 6.0); }
        if (this.squeeze > 0) { this.squeeze = Math.max(0.0, this.squeeze - dt * 3.5); }
        let sy = 1.0 - 0.18 * this.recoil;
        api.placeScaled(this.barrel, PIV_X, PIV_Y - 0.12 * this.recoil, 0, 0, 1.0, sy, 1.0, 0, this.barA - 90.0);
        // the bulb breathes; a launch squeezes it flat against the drum
        let breathe = 0.04 * (0.5 + 0.5 * Math.sin(api.time * 2.4));
        let sq = this.squeeze;
        api.placeScaled(this.bulb, -0.782, 0.909 - 0.05 * sq, 0, 0, 1.0 - breathe - 0.38 * sq, 1.0 - 0.1 * sq, 1.0 - 0.1 * sq);
        // the rafter
        let creak = this.state == ST_PLAY && this.started && this.shots == this.dropEvery - 1
            && Math.floor(api.time * 8.0) % 2 == 0 ? api.orthoHeight / 136.0 : 0.0;
        api.place(this.beam, 0, this.beamY + creak, 0);
    }

    // HUD shards from a world point
    spray(api: GameApi, x: f64, y: f64, n: i32, ca: i32, cb: i32): void {
        if (!this.project(api, x, y)) {
            return;
        }
        let sx = <f64>api.screenX, sy = <f64>api.screenY;
        for (let k = 0; k < n; k++) {
            let i = this.pNext;
            this.pNext = (this.pNext + 1) % NPART;
            // fixed directions (no api.rand: shards never change the game)
            let a = (<f64>k / <f64>n) * Math.PI * 2.0 + <f64>(this.pNext % 5) * 0.4;
            let sp = 38.0 + <f64>((k * 13 + this.pNext * 7) % 5) * 9.0;
            this.pT[i] = 0;
            this.pX[i] = sx;
            this.pY[i] = sy;
            this.pVX[i] = Math.cos(a) * sp;
            this.pVY[i] = Math.sin(a) * sp - 20.0;
            this.pC[i] = (k & 1) == 0 ? ca : cb;
        }
    }

    updateParts(dt: f64): void {
        for (let i = 0; i < NPART; i++) {
            if (this.pT[i] < 0) { continue; }
            this.pT[i] += dt;
            if (this.pT[i] > 0.45) { this.pT[i] = -1; continue; }
            this.pVY[i] += 160.0 * dt;
            this.pX[i] += this.pVX[i] * dt;
            this.pY[i] += this.pVY[i] * dt;
        }
    }

    // ------------------------------------------------------------------ the demo player

    // scores a landing cell for a colour: pops and drops count most, then same-colour neighbours;
    // low rows near the sill are avoided
    evalCell(i: i32, col: i32): f64 {
        if (i < 0) { return -100.0; }
        for (let j = 0; j < ROWS * COLS; j++) { this.gc2[j] = this.gc[j]; }
        this.gc2[i] = col;
        this.clearMarks();
        let n = this.group(this.gc2, i, 1);
        let r = i / COLS;
        let v = 0.0;
        if (n >= 3) {
            for (let j = 0; j < ROWS * COLS; j++) {
                if (this.mark[j] == 1) { this.gc2[j] = -1; }
            }
            this.clearMarks();
            let loose = this.hanging(this.gc2, 2);
            v = 10.0 + 3.0 * <f64>n + 5.0 * <f64>loose;
        } else {
            let same = 0, other = 0;
            for (let k = 0; k < 6; k++) {
                let j = this.nb(i, k);
                if (j >= 0 && this.gc[j] >= 0) {
                    if (this.gc[j] == col) { same++; } else { other++; }
                }
            }
            v = 3.0 * <f64>same - 0.8 * <f64>other + (n == 2 ? 2.0 : 0.0);
            v -= 0.7 * <f64>(r + this.drops);
            if (r + this.drops >= LOST - 1) { v -= 12.0; }
        }
        if (r + this.drops >= LOST) { v -= 60.0; }
        return v;
    }

    demoThink(api: GameApi, dt: f64): void {
        if (this.state != ST_PLAY || !this.ready()) {
            return;
        }
        if (!this.dPlan) {
            this.dThink -= dt;
            if (this.dThink > 0) {
                return;
            }
            // look at every angle for both orbs
            let bestV = -1e9, bestA = 90.0, bestSwap = false;
            let secondV = -1e9, secondA = 90.0, secondSwap = false;
            let canSwap = this.next > 0 && this.oSt[this.next] == O_CUP;
            let lc = this.oCol[this.loaded];
            let nc = canSwap ? this.oCol[this.next] : -1;
            let beamY = this.logicBeam();
            for (let k = 0; k <= 76; k++) {
                let a = MIN_A + 2.0 * <f64>k;
                this.trace(PIV_X + Math.cos(a * Math.PI / 180.0) * MUZZLE, PIV_Y + Math.sin(a * Math.PI / 180.0) * MUZZLE, a, 1, beamY);
                if (!this.trHit) { continue; }
                let cell = this.trCell;
                for (let w = 0; w < 2; w++) {
                    if (w == 1 && nc < 0) { continue; }
                    let v = this.evalCell(cell, w == 0 ? lc : nc) - (w == 1 ? 0.5 : 0.0) - (this.trB > 0 ? 0.3 : 0.0);
                    if (v > bestV) {
                        secondV = bestV; secondA = bestA; secondSwap = bestSwap;
                        bestV = v; bestA = a; bestSwap = w == 1;
                    } else if (v > secondV) {
                        secondV = v; secondA = a; secondSwap = w == 1;
                    }
                }
            }
            let u = api.rand();
            // a decent human: mostly the best plan, sometimes the second, now and then a careless shot
            if (u < 0.2) {
                this.dAim = MIN_A + 10.0 + api.rand() * (MAX_A - MIN_A - 20.0);
                this.dSwap = false;
            } else if (u < 0.45 && secondV > -1e8) {
                this.dAim = secondA;
                this.dSwap = secondSwap;
            } else {
                this.dAim = bestA;
                this.dSwap = bestSwap;
            }
            this.dAim += (api.rand() - 0.5) * 4.0;
            this.dAim = Math.max(MIN_A, Math.min(MAX_A, this.dAim));
            this.dPlan = true;
            this.dHold = (this.started ? 0.3 : 0.15) + api.rand() * 0.25;
            if (this.dSwap) {
                this.swap(api);
            }
            return;
        }
        // sweep the barrel to the plan, then launch
        let d = this.dAim - this.aimA;
        let stepA = 220.0 * dt;
        this.aimA += Math.abs(d) < stepA ? d : (d > 0 ? stepA : -stepA);
        this.dHold -= dt;
        if (this.dHold <= 0 && Math.abs(this.dAim - this.aimA) < 0.5 && Math.abs(this.barA - this.aimA) < 1.5) {
            if (this.fire(api)) {
                this.dPlan = false;
                this.dThink = 0.1 + api.rand() * 0.25;
            }
        }
    }

    // ------------------------------------------------------------------ input

    aimAt(api: GameApi, x: f32, y: f32): void {
        if (!api.pickPlane(x, y, 0, 0, 1, 0)) {
            return;
        }
        let dx = <f64>api.hitX - PIV_X, dy = <f64>api.hitY - PIV_Y;
        let a = Math.atan2(dy, dx) * 180.0 / Math.PI;
        if (a < -90.0) { a = MAX_A; }
        else if (a < 0) { a = MIN_A; }
        this.aimA = Math.max(MIN_A, Math.min(MAX_A, a));
    }

    onCup(api: GameApi, x: f32, y: f32): bool {
        if (!api.project(<f32>CUP_X, <f32>CUP_Y, 0)) {
            return false;
        }
        let dx = x - api.screenX, dy = y - api.screenY;
        return dx * dx + dy * dy <= 8.5 * 8.5;
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.state == ST_OVER) {
                if (this.stateT > 0.8) {
                    api.sound(SFX_WIN, 1.0, 0.6);
                    this.newRun(api, false);
                }
                this.aiming = false;
                this.swapPress = false;
                return true;
            }
            if (this.onCup(api, x, y)) {
                this.swapPress = true;
                this.aiming = false;
                return true;
            }
            this.swapPress = false;
            this.aiming = true;
            this.aimAt(api, x, y);
        } else if (kind == POINTER_MOVE) {
            // a held press aims (a touch drag); a mouse hovering (api.hoverSeen) aims too, as a convenience
            if (!this.swapPress && (this.aiming || (api.hoverSeen && !api.pointerDown))) {
                this.aimAt(api, x, y);
            }
        } else if (kind == POINTER_UP) {
            if (this.swapPress) {
                this.swapPress = false;
                if (this.onCup(api, x, y)) {
                    this.swap(api);
                }
            } else if (this.aiming) {
                this.aiming = false;
                this.aimAt(api, x, y);
                if (!this.fire(api) && (this.state == ST_PLAY || this.state == ST_BUILD)) {
                    this.queued = true;       // launch as soon as the next orb is in the mouth
                }
            }
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    // a marching dotted line between two world points: 2-pixel dashes with a navy shadow below
    dotted(api: GameApi, x0: f64, y0: f64, x1: f64, y1: f64, phase: f64, ca: u32, cb: u32, sh: u32): f64 {
        if (!this.project(api, x0, y0)) { return phase; }
        let ax = <f64>api.screenX, ay = <f64>api.screenY;
        if (!this.project(api, x1, y1)) { return phase; }
        let bx = <f64>api.screenX, by = <f64>api.screenY;
        let len = Math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
        let p = phase;
        let t = 0.0;
        while (t < len) {
            let k = <i32>Math.floor(p / 5.0);
            if ((p % 5.0) < 2.0) {
                let px = <f32>Math.round(ax + (bx - ax) * t / len), py = <f32>Math.round(ay + (by - ay) * t / len);
                api.rect(px, py + 1, 1, 1, sh);
                api.rect(px, py, 1, 1, (k & 1) == 0 ? ca : cb);
            }
            t += 1.0;
            p += 1.0;
        }
        return p;
    }

    hud(api: GameApi): void {
        let cream = api.paletteColor(P_CREAM);
        let yellow = api.paletteColor(P_YELLOW);
        let gold = api.paletteColor(P_GOLD);
        let orange = api.paletteColor(P_ORANGE);
        let salmon = api.paletteColor(P_SALMON);
        let pink = api.paletteColor(P_PINK);
        let plum = api.paletteColor(P_PLUM);
        let navy = api.paletteColor(P_NAVY);

        // the aim guide: from the mouth, one wall bounce, to where the orb would cling
        if (this.state == ST_PLAY && this.loaded > 0 && this.shot <= 0) {
            let ba = this.barA;
            let a = ba * Math.PI / 180.0;
            let sx = PIV_X + Math.cos(a) * (MUZZLE + 0.55), sy = PIV_Y + Math.sin(a) * (MUZZLE + 0.55);
            this.trace(sx, sy, ba, 1, this.logicBeam());
            let ph = 10.0 - (api.time * 14.0) % 10.0;
            if (this.trB > 0) {
                ph = this.dotted(api, sx, sy, this.trBX, this.trBY, ph, cream, yellow, navy);
                this.dotted(api, this.trBX, this.trBY, this.trX, this.trY, ph, cream, yellow, navy);
            } else {
                this.dotted(api, sx, sy, this.trX, this.trY, ph, cream, yellow, navy);
            }
            if (this.trHit && this.trCell >= 0 && this.project(api, this.cellX(this.trCell), this.cellYAt(this.trCell, this.beamY))) {
                // a small ring where it will settle
                let cx = Mathf.round(api.screenX), cy = Mathf.round(api.screenY);
                let col = this.aiming || api.demo || Math.floor(api.time * 3.0) % 3 != 0 ? cream : yellow;
                api.rect(cx - 2, cy - 4, 5, 1, col);
                api.rect(cx - 2, cy + 4, 5, 1, col);
                api.rect(cx - 4, cy - 2, 1, 5, col);
                api.rect(cx + 4, cy - 2, 1, 5, col);
            }
        }

        // the sill glows when the cluster hangs one row above it
        let low = this.lowestRow();
        if (low >= 0 && low + this.drops >= LOST - 1 && this.state == ST_PLAY && Math.floor(api.time * 4.0) % 2 == 0) {
            if (this.project(api, -FIELD_X, SILL_Y + 0.06)) {
                let y = Mathf.round(api.screenY);
                let x0 = Mathf.round(api.screenX);
                this.project(api, FIELD_X, SILL_Y);
                let x1 = Mathf.round(api.screenX);
                for (let x = x0; x <= x1; x += 2) {
                    api.rect(x, y - 1, 1, 1, cream);
                }
            }
        }

        // shards
        for (let i = 0; i < NPART; i++) {
            if (this.pT[i] < 0) { continue; }
            let s: f32 = this.pT[i] < 0.18 ? 2 : 1;
            api.rect(Mathf.round(<f32>this.pX[i]), Mathf.round(<f32>this.pY[i]), s, s, api.paletteColor(this.pC[i]));
        }

        // score, best (left), the rafter's countdown and the cluster count (right)
        api.text(5, 5, "SCORE", salmon, 1, navy);
        api.text(5, 12, this.score.toString(), cream, 2, navy);
        api.text(5, 25, "BEST " + this.best.toString(), gold, 1, navy);
        if (this.board > 1) {
            api.text(5, 32, "LOFT " + this.board.toString(), pink, 1, navy);
        }
        let rx = <f32>api.hudW - 52;
        api.text(rx, 5, "DROP IN", salmon, 1, navy);
        let left = this.dropEvery - this.shots;
        for (let k = 0; k < this.dropEvery; k++) {
            let x = rx + <f32>(k * 6);
            let on = k < left;
            let warn = left <= 1 && Math.floor(api.time * 6.0) % 2 == 0;
            api.rect(x, 13, 5, 5, navy);
            api.rect(x + 1, 14, 3, 3, on ? (warn ? cream : orange) : plum);
        }
        if (this.combo >= 2 && this.state == ST_PLAY && this.bannerT < 0) {
            api.text(rx, 22, "COMBO X" + min<i32>(this.combo, 5).toString(), yellow, 1, navy);
        }

        // before the first launch, a SWAP label beside the cup (the next orb is a tap target)
        if (this.state == ST_PLAY && !this.started && !api.demo && this.project(api, CUP_X, CUP_Y)) {
            let cx = Mathf.round(api.screenX), cy = Mathf.round(api.screenY);
            if (Math.floor(api.time * 2.0) % 2 == 0) {
                api.text(cx + 8, cy - 3, "SWAP", cream, 1, navy);
            }
        }

        // a score label rising from the pop
        if (this.popT >= 0) {
            let rise = <f32>(Math.floor(this.popT * 12.0) * 1.5);
            let sc = this.popBig ? 2 : 1;
            let w = api.textWidth(this.popText, sc);
            let col = this.popBig && Math.floor(this.popT * 10.0) % 2 == 0 ? cream : yellow;
            api.text(Mathf.round(this.popX - w * 0.5), Mathf.round(this.popY - 8 - rise), this.popText, col, sc, navy);
        }
        if (this.bannerT >= 0) {
            let col = Math.floor(this.bannerT * 8.0) % 2 == 0 ? cream : yellow;
            api.textCentered(70, this.banner, col, 2, navy);
        }

        if (this.state == ST_PLAY && !this.started && !api.demo) {
            let blink = Math.floor(api.time * 2.0) % 2 == 0;
            api.textCentered(82, "DRAG TO AIM, RELEASE TO LAUNCH", blink ? cream : yellow, 1, navy);
            api.textCentered(90, "POP 3 OF A COLOUR", cream, 1, navy);
        } else if (this.state == ST_OVER) {
            let pw: f32 = 122, ph: f32 = 42;
            let px = Mathf.floor((<f32>api.hudW - pw) * 0.5), py: f32 = 46;
            api.rect(px - 1, py - 1, pw + 2, ph + 2, gold);
            api.rect(px, py, pw, ph, plum);
            api.rect(px, py + ph - 2, pw, 2, navy);
            api.textCentered(py + 5, "GAME OVER", cream, 2, navy);
            let line = "SCORE " + this.score.toString() + "   BEST " + this.best.toString();
            api.textCentered(py + 20, line, this.score >= this.best && this.score > 0 ? yellow : cream, 1, navy);
            if (this.stateT > 0.8 && !api.demo) {
                let blink = Math.floor(api.time * 2.0) % 2 == 0;
                api.textCentered(py + 31, "TAP TO PLAY AGAIN", blink ? orange : cream, 1, navy);
            }
        }
    }
}
