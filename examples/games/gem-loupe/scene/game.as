// Gem Loupe: a match-3 at a jeweller's bench. A 7 x 7 velvet tray of cut gems; swap two neighbours
// (tap one, then the other, or swipe from one to the next) to line up three or more of a cut. Matches
// sparkle away, the gems above slide down and new ones rise in at the top; cascades climb a scale.
// Four in a line make a BAGUETTE (clears its row or column), an L or T a CLUSTER (a 3 x 3 burst),
// five a BRILLIANT (swap it with any gem: every gem of that cut goes). 25 moves, three stars.
//
// Bones: one "drum" per cell (pool gem0..gem48). A drum carries all six cuts on a ring round its X
// axis; the game turns the cut it needs to the top and the other five stay under the velvet and the
// bench. A gem never leaves the velvet plane: it slides (swaps, falls) and sinks or rises through the
// cloth (clears, new gems, a brilliant being forged). Marks for specials: band0..4 (baguette), claw0..2
// (cluster). The loupe is the cursor; the candle flame flickers.
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP, SFX_CLICK, SFX_WHOOSH, SFX_THUD, SFX_BELL,
    SFX_NOTE, SFX_POP, SFX_POWERUP, SFX_ZAP, SFX_EXPLODE, SFX_TICK, SFX_LOSE, SFX_WIN, SFX_BLIP } from "./game_api";

const N: i32 = 7;
const NN: i32 = 49;
const CELL: f64 = 0.5;
const X0: f64 = -1.5;        // column 0's centre (world x)
const Z0: f64 = -1.5;        // row 0's centre (world z), the far edge
const AXIS_Y: f64 = -0.78;   // a drum's axis under the velvet (the top cut's base sits on y 0)
const NCOL: i32 = 5;         // gem colours (cuts 0..4); cut 5 is the brilliant
const T_BRIL: i32 = 5;
const MOVES: i32 = 25;
const NBAND: i32 = 5;
const NCLAW: i32 = 3;
const NSPARK: i32 = 96;
const PITCH: f64 = 66;       // the camera's pitch (scene.rml)

// special pieces
const SP_NONE: i32 = 0;
const SP_ROW: i32 = 1;       // baguette, clears its row (made by a horizontal four)
const SP_COL: i32 = 2;       // baguette, clears its column
const SP_CLUSTER: i32 = 3;   // a 3 x 3 burst (made by an L or a T)
const SP_BRIL: i32 = 4;      // the brilliant (made by five)

// gem visual modes
const G_REST: i32 = 0;
const G_FALL: i32 = 1;
const G_ENTER: i32 = 2;      // waiting under the velvet, then rising at the top of its column
const G_CLEAR: i32 = 3;
const G_HIDDEN: i32 = 4;
const G_FORGE: i32 = 5;      // sinking, turning to the brilliant, rising

// game states
const S_DEAL: i32 = 0;
const S_IDLE: i32 = 1;
const S_SWAP: i32 = 2;
const S_BACK: i32 = 3;
const S_CLEAR: i32 = 4;
const S_FALL: i32 = 5;
const S_SHUFFLE: i32 = 6;
const S_END: i32 = 7;

const SWAP_T: f64 = 0.16;
const STAR1: i32 = 2500;
const STAR2: i32 = 4000;
const STAR3: i32 = 5500;

// a cascade climbs C major pentatonic
const SCALE: StaticArray<f64> = [72, 74, 76, 79, 81, 84, 86, 88, 91, 93, 96];
// crown top above the velvet per cut (where a mark sits)
const TOPY: StaticArray<f64> = [0.14, 0.14, 0.15, 0.14, 0.2, 0.17];
const FORGE_NOTES: StaticArray<f64> = [84, 88, 91, 96];

// palette indices (art/palette.json "colors")
const C_TEAL: i32 = 0;
const C_SAGE: i32 = 8;
const C_CREAM: i32 = 9;
const C_GOLD: i32 = 10;
const C_AMBER: i32 = 11;
const C_TAN: i32 = 12;
const C_BROWN: i32 = 13;
const C_UMBER: i32 = 14;
const C_NIGHT: i32 = 15;

export class Game {
    // ---- board (logical)
    cellGem: StaticArray<i32> = new StaticArray<i32>(NN);   // gem object at a cell, -1 empty
    typ: StaticArray<i32> = new StaticArray<i32>(NN);       // per cell: cut, for the logic
    spc: StaticArray<i32> = new StaticArray<i32>(NN);       // per cell: special
    // ---- gems (objects, one drum bone each)
    bone: StaticArray<i32> = new StaticArray<i32>(NN);
    gType: StaticArray<i32> = new StaticArray<i32>(NN);
    gSpec: StaticArray<i32> = new StaticArray<i32>(NN);
    gMark: StaticArray<i32> = new StaticArray<i32>(NN);     // mark pool slot (band 0..4, claw 10..12), -1
    gMode: StaticArray<i32> = new StaticArray<i32>(NN);
    gT: StaticArray<f64> = new StaticArray<f64>(NN);
    gX: StaticArray<f64> = new StaticArray<f64>(NN);
    gZ: StaticArray<f64> = new StaticArray<f64>(NN);
    gY: StaticArray<f64> = new StaticArray<f64>(NN);        // sink offset
    gS: StaticArray<f64> = new StaticArray<f64>(NN);        // scale
    gTX: StaticArray<f64> = new StaticArray<f64>(NN);
    gTZ: StaticArray<f64> = new StaticArray<f64>(NN);
    gV: StaticArray<f64> = new StaticArray<f64>(NN);
    gLand: StaticArray<f64> = new StaticArray<f64>(NN);     // time since landing (squash), < 0 none
    gYaw: StaticArray<f64> = new StaticArray<f64>(NN);
    gNewType: StaticArray<i32> = new StaticArray<i32>(NN);  // FORGE: the cut it turns into
    gFromX: StaticArray<f64> = new StaticArray<f64>(NN);
    gFromZ: StaticArray<f64> = new StaticArray<f64>(NN);
    markBone: StaticArray<i32> = new StaticArray<i32>(16);
    markUsed: StaticArray<bool> = new StaticArray<bool>(16);
    markPop: StaticArray<f64> = new StaticArray<f64>(16);
    loupe: i32 = -1;
    flame: i32 = -1;

    // ---- the run
    state: i32 = S_DEAL;
    stateT: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    moves: i32 = MOVES;
    cascade: i32 = 0;
    showCascade: i32 = 0;
    cascadeT: f64 = -1;
    firstMove: bool = true;
    newBest: bool = false;
    stars: i32 = 0;
    wasDemo: bool = false;
    started: bool = false;

    // ---- the current swap
    swA: i32 = -1;
    swB: i32 = -1;
    swapCells: bool = false;    // the first resolve after a swap may place specials on the swapped cells

    // ---- clearing
    clr: StaticArray<bool> = new StaticArray<bool>(NN);
    clrDelay: StaticArray<f64> = new StaticArray<f64>(NN);
    activated: StaticArray<bool> = new StaticArray<bool>(NN);
    makeCell: StaticArray<i32> = new StaticArray<i32>(16);  // specials to create this step
    makeSpec: StaticArray<i32> = new StaticArray<i32>(16);
    makeType: StaticArray<i32> = new StaticArray<i32>(16);
    makeN: i32 = 0;
    queue: StaticArray<i32> = new StaticArray<i32>(NN);
    hRun: StaticArray<i32> = new StaticArray<i32>(NN);      // run length through a cell
    vRun: StaticArray<i32> = new StaticArray<i32>(NN);
    grp: StaticArray<i32> = new StaticArray<i32>(NN);
    clearEnd: f64 = 0;
    lastTick: f64 = -1;

    // ---- input
    sel: i32 = -1;
    pressed: bool = false;
    downCell: i32 = -1;
    downX: f32 = 0;
    downY: f32 = 0;
    swiped: bool = false;
    downWasSel: bool = false;
    hoverCell: i32 = -1;
    hoverT: f64 = -10;

    // ---- the loupe (cursor)
    lX: f64 = -2.7;
    lY: f64 = 0.08;
    lZ: f64 = 0.4;
    lPitch: f64 = -90;
    lYaw: f64 = 0;
    lInit: bool = false;

    // ---- HUD effects
    spX: StaticArray<f32> = new StaticArray<f32>(NSPARK);
    spY: StaticArray<f32> = new StaticArray<f32>(NSPARK);
    spVX: StaticArray<f32> = new StaticArray<f32>(NSPARK);
    spVY: StaticArray<f32> = new StaticArray<f32>(NSPARK);
    spT: StaticArray<f32> = new StaticArray<f32>(NSPARK);
    spC: StaticArray<i32> = new StaticArray<i32>(NSPARK);
    spNext: i32 = 0;
    beamKind: StaticArray<i32> = new StaticArray<i32>(8);   // 1 row, 2 col, 3 box, 4 brilliant
    beamCell: StaticArray<i32> = new StaticArray<i32>(8);
    beamR: StaticArray<i32> = new StaticArray<i32>(8);
    beamT: StaticArray<f64> = new StaticArray<f64>(8);
    beamNext: i32 = 0;
    popText: string = "";
    popT: f64 = -1;
    gainText: string = "";
    gainT: f64 = -1;
    gainCell: i32 = 0;
    shuffleMsgT: f64 = -1;

    // ---- the demo player
    dWait: f64 = 0;
    dStep: i32 = 0;      // 0 thinking, 1 loupe to A, 2 holding A, 3 to B
    dA: i32 = -1;
    dB: i32 = -1;
    dCurX: f64 = 0;
    dCurZ: f64 = 0;
    dHasCur: bool = false;
    dCandA: StaticArray<i32> = new StaticArray<i32>(128);
    dCandB: StaticArray<i32> = new StaticArray<i32>(128);
    dCandS: StaticArray<f64> = new StaticArray<f64>(128);

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < NN; i++) {
            this.bone[i] = api.bone("gem" + i.toString());
            this.gMark[i] = -1;
            this.gS[i] = 1;
            this.gLand[i] = -1;
        }
        for (let i = 0; i < 16; i++) {
            this.markBone[i] = -1;
        }
        for (let i = 0; i < NBAND; i++) {
            this.markBone[i] = api.bone("band" + i.toString());
            api.hide(this.markBone[i]);
        }
        for (let i = 0; i < NCLAW; i++) {
            this.markBone[10 + i] = api.bone("claw" + i.toString());
            api.hide(this.markBone[10 + i]);
        }
        this.loupe = api.bone("loupe");
        this.flame = api.bone("flame");
        for (let i = 0; i < NSPARK; i++) {
            this.spT[i] = -1;
        }
        for (let i = 0; i < 8; i++) {
            this.beamT[i] = -1;
        }
        this.wasDemo = api.demo;
        this.newBoard(api, true);
    }

    // ================================================================== board logic

    cellX(c: i32): f64 { return X0 + CELL * <f64>(c % N); }
    // the row of a cell; kept as an i32 call: written inline as <f64>(c / N) it divided as floats
    rowOf(c: i32): i32 { return c / N; }
    cellZ(c: i32): f64 { return Z0 + CELL * <f64>this.rowOf(c); }

    adjacent(a: i32, b: i32): bool {
        if (a < 0 || b < 0) {
            return false;
        }
        let ra = a / N, ca = a % N, rb = b / N, cb = b % N;
        return (ra == rb && (ca - cb == 1 || cb - ca == 1)) || (ca == cb && (ra - rb == 1 || rb - ra == 1));
    }

    // the run of one cut through cell i, horizontal or vertical (the brilliant never matches)
    runAt(i: i32, horiz: bool): i32 {
        let t = this.typ[i];
        if (t < 0 || t >= NCOL) {
            return 0;
        }
        let r = i / N, c = i % N, n = 1;
        if (horiz) {
            for (let k = c - 1; k >= 0 && this.typ[r * N + k] == t; k--) { n++; }
            for (let k = c + 1; k < N && this.typ[r * N + k] == t; k++) { n++; }
        } else {
            for (let k = r - 1; k >= 0 && this.typ[k * N + c] == t; k--) { n++; }
            for (let k = r + 1; k < N && this.typ[k * N + c] == t; k++) { n++; }
        }
        return n;
    }

    swapLogic(a: i32, b: i32): void {
        let t = this.typ[a]; this.typ[a] = this.typ[b]; this.typ[b] = t;
        let s = this.spc[a]; this.spc[a] = this.spc[b]; this.spc[b] = s;
        let g = this.cellGem[a]; this.cellGem[a] = this.cellGem[b]; this.cellGem[b] = g;
    }

    // does swapping a and b do something?
    swapValid(a: i32, b: i32): bool {
        if (!this.adjacent(a, b)) {
            return false;
        }
        if (this.spc[a] == SP_BRIL || this.spc[b] == SP_BRIL) {
            return true;
        }
        if (this.spc[a] != SP_NONE && this.spc[b] != SP_NONE) {
            return true;
        }
        this.swapLogic(a, b);
        let ok = this.runAt(a, true) >= 3 || this.runAt(a, false) >= 3 || this.runAt(b, true) >= 3 || this.runAt(b, false) >= 3;
        this.swapLogic(a, b);
        return ok;
    }

    hasMove(): bool {
        for (let i = 0; i < NN; i++) {
            if (i % N < N - 1 && this.swapValid(i, i + 1)) { return true; }
            if (i / N < N - 1 && this.swapValid(i, i + N)) { return true; }
        }
        return false;
    }

    anyMatch(): bool {
        for (let i = 0; i < NN; i++) {
            if (this.runAt(i, true) >= 3 || this.runAt(i, false) >= 3) {
                return true;
            }
        }
        return false;
    }

    // fills every plain cell (keepSpecials: specials stay) with cuts that make no match, with a move
    fillNoMatch(api: GameApi, keepSpecials: bool): void {
        for (let attempt = 0; attempt < 60; attempt++) {
            for (let i = 0; i < NN; i++) {
                if (!keepSpecials || this.spc[i] == SP_NONE) {
                    this.typ[i] = -1;
                    this.spc[i] = SP_NONE;
                }
            }
            for (let i = 0; i < NN; i++) {
                if (this.typ[i] >= 0) {
                    continue;
                }
                let t = <i32>Math.floor(api.rand() * <f64>NCOL) % NCOL;
                for (let k = 0; k < NCOL; k++) {
                    this.typ[i] = t;
                    if (this.runAt(i, true) < 3 && this.runAt(i, false) < 3) {
                        break;
                    }
                    t = (t + 1) % NCOL;
                }
            }
            if (!this.anyMatch() && this.hasMove()) {
                return;
            }
        }
    }

    // ================================================================== runs

    newBoard(api: GameApi, first: bool): void {
        this.score = 0;
        this.moves = MOVES;
        this.cascade = 0;
        this.firstMove = true;
        this.newBest = false;
        this.stars = 0;
        this.sel = -1;
        this.swA = -1;
        this.swB = -1;
        this.popT = -1;
        this.gainT = -1;
        this.cascadeT = -1;
        this.showCascade = 0;
        this.shuffleMsgT = -1;
        for (let i = 0; i < 8; i++) { this.beamT[i] = -1; }
        this.dStep = 0;
        this.dHasCur = false;
        this.dWait = api.demo ? 0.1 : 0.5;
        for (let i = 0; i < 16; i++) {
            this.markUsed[i] = false;
        }
        for (let i = 0; i < NN; i++) {
            this.spc[i] = SP_NONE;
            this.typ[i] = -1;
        }
        this.fillNoMatch(api, false);
        for (let i = 0; i < NN; i++) {
            let g = i;   // gem i starts at cell i
            this.cellGem[i] = g;
            this.gType[g] = this.typ[i];
            this.gSpec[g] = SP_NONE;
            this.gMark[g] = -1;
            this.gX[g] = this.cellX(i);
            this.gZ[g] = this.cellZ(i);
            this.gTX[g] = this.gX[g];
            this.gTZ[g] = this.gZ[g];
            this.gYaw[g] = 0;
            this.gLand[g] = -1;
            // the deal: rows rise from the far edge to the near one, 0.06 s apart
            this.gMode[g] = G_ENTER;
            this.gT[g] = -(0.04 + 0.06 * <f64>this.rowOf(i) + 0.012 * <f64>(i % N));
            this.gY[g] = -0.3;
            this.gS[g] = 0.6;
            this.gV[g] = 0;
        }
        for (let i = 0; i < 16; i++) {
            if (this.markBone[i] > 0) {
                api.hide(this.markBone[i]);
            }
        }
        this.state = S_DEAL;
        this.stateT = 0;
        if (!first) {
            api.sound(SFX_WHOOSH, 0.8, 0.4);
            api.note(72, 0.35, 0, SFX_NOTE, 0.1);
            api.note(79, 0.35, 0, SFX_NOTE, 0.22);
        }
    }

    starsFor(s: i32): i32 {
        return s >= STAR3 ? 3 : (s >= STAR2 ? 2 : (s >= STAR1 ? 1 : 0));
    }

    endRun(api: GameApi): void {
        this.state = S_END;
        this.stateT = 0;
        this.sel = -1;
        this.stars = this.starsFor(this.score);
        this.newBest = this.score > this.best && this.score > 0;
        if (this.score > this.best) {
            this.best = this.score;
        }
        // the jingle, by stars
        if (this.stars == 0) {
            api.sound(SFX_LOSE, 1, 0.7);
        } else if (this.stars == 1) {
            api.note(72, 0.6, 0, SFX_BELL); api.note(76, 0.6, 0, SFX_BELL, 0.16); api.note(79, 0.7, 0, SFX_BELL, 0.32);
        } else if (this.stars == 2) {
            api.note(72, 0.6, 0, SFX_BELL); api.note(76, 0.6, 0, SFX_BELL, 0.14); api.note(79, 0.6, 0, SFX_BELL, 0.28);
            api.note(84, 0.8, 0, SFX_BELL, 0.42);
        } else {
            api.sound(SFX_WIN, 1, 0.6);
            let m: StaticArray<f64> = [72, 76, 79, 84, 88, 91];
            for (let k = 0; k < 6; k++) {
                api.note(m[k], 0.55, 0, SFX_BELL, 0.1 + 0.11 * <f64>k);
            }
            api.note(96, 0.7, 0, SFX_BELL, 0.8);
        }
    }

    // ================================================================== swap

    beginSwap(api: GameApi, a: i32, b: i32): void {
        this.swA = a;
        this.swB = b;
        this.sel = -1;
        let ga = this.cellGem[a], gb = this.cellGem[b];
        this.gFromX[ga] = this.gX[ga]; this.gFromZ[ga] = this.gZ[ga];
        this.gFromX[gb] = this.gX[gb]; this.gFromZ[gb] = this.gZ[gb];
        this.state = S_SWAP;
        this.stateT = 0;
        api.soundAt(SFX_WHOOSH, (this.cellX(a) + this.cellX(b)) * 0.5, 0, this.cellZ(a), 1.7, 0.3);
    }

    // after the swap slid: commit it or send it back
    swapArrived(api: GameApi): void {
        let a = this.swA, b = this.swB;
        if (!this.swapValid(a, b)) {
            this.state = S_BACK;
            this.stateT = 0;
            let x = (this.cellX(a) + this.cellX(b)) * 0.5;
            api.soundAt(SFX_THUD, x, 0, this.cellZ(a), 1.6, 0.5);
            api.soundAt(SFX_CLICK, x, 0, this.cellZ(a), 0.7, 0.5, 0.12);
            return;
        }
        this.swapLogic(a, b);
        this.moves--;
        this.firstMove = false;
        this.cascade = 0;
        if (this.moves <= 3 && this.moves > 0) {
            api.sound(SFX_BLIP, 0.8, 0.3, 0, 0.2);
        }
        // specials swapped into each other fire at once
        let sa = this.spc[a], sb = this.spc[b];
        if (sa == SP_BRIL || sb == SP_BRIL || (sa != SP_NONE && sb != SP_NONE)) {
            this.fireSwapCombo(api, a, b);
            return;
        }
        this.swapCells = true;
        this.resolve(api);
    }

    // ================================================================== matches and specials

    resetClear(): void {
        for (let i = 0; i < NN; i++) {
            this.clr[i] = false;
            this.clrDelay[i] = 0;
            this.activated[i] = false;
        }
        this.makeN = 0;
    }

    mark(i: i32, delay: f64): void {
        if (i < 0 || i >= NN || this.cellGem[i] < 0) {
            return;
        }
        if (!this.clr[i]) {
            this.clr[i] = true;
            this.clrDelay[i] = delay;
        } else if (delay < this.clrDelay[i]) {
            this.clrDelay[i] = delay;
        }
    }

    addBeam(kind: i32, cell: i32, r: i32): void {
        let k = this.beamNext;
        this.beamNext = (this.beamNext + 1) % 8;
        this.beamKind[k] = kind;
        this.beamCell[k] = cell;
        this.beamR[k] = r;
        this.beamT[k] = 0;
    }

    // the cut most common on the board (what a brilliant hit by a blast takes)
    commonType(): i32 {
        let best = 0, bestN = -1;
        for (let t = 0; t < NCOL; t++) {
            let n = 0;
            for (let i = 0; i < NN; i++) {
                if (this.typ[i] == t) { n++; }
            }
            if (n > bestN) { bestN = n; best = t; }
        }
        return best;
    }

    // fires every special in the clear set (and those they reach), each wave a little later
    propagate(api: GameApi): void {
        let qh = 0, qt = 0;
        for (let i = 0; i < NN; i++) {
            if (this.clr[i] && this.spc[i] != SP_NONE && !this.activated[i]) {
                this.queue[qt++] = i;
                this.activated[i] = true;
            }
        }
        let fired = 0;
        while (qh < qt) {
            let i = this.queue[qh++];
            let s = this.spc[i];
            let r = i / N, c = i % N;
            let d0 = this.clrDelay[i];
            if (s == SP_ROW) {
                for (let k = 0; k < N; k++) { this.mark(r * N + k, d0 + 0.035 * <f64>abs<i32>(k - c)); }
                this.addBeam(1, i, 0);
                api.soundAt(SFX_ZAP, this.cellX(i), 0, this.cellZ(i), 1.0, 0.55, d0);
            } else if (s == SP_COL) {
                for (let k = 0; k < N; k++) { this.mark(k * N + c, d0 + 0.035 * <f64>abs<i32>(k - r)); }
                this.addBeam(2, i, 0);
                api.soundAt(SFX_ZAP, this.cellX(i), 0, this.cellZ(i), 0.85, 0.55, d0);
            } else if (s == SP_CLUSTER) {
                for (let dr = -1; dr <= 1; dr++) {
                    for (let dc = -1; dc <= 1; dc++) {
                        let rr = r + dr, cc = c + dc;
                        if (rr >= 0 && rr < N && cc >= 0 && cc < N) { this.mark(rr * N + cc, d0 + 0.05); }
                    }
                }
                this.addBeam(3, i, 1);
                api.soundAt(SFX_EXPLODE, this.cellX(i), 0, this.cellZ(i), 1.5, 0.45, d0);
            } else if (s == SP_BRIL) {
                let t = this.commonType();
                let n = 0;
                for (let k = 0; k < NN; k++) {
                    if (this.typ[k] == t) { this.mark(k, d0 + 0.08 + 0.02 * <f64>n); n++; }
                }
                this.addBeam(4, i, t);
                api.soundAt(SFX_ZAP, this.cellX(i), 0, this.cellZ(i), 1.6, 0.5, d0);
            }
            fired++;
            for (let k = 0; k < NN; k++) {
                if (this.clr[k] && this.spc[k] != SP_NONE && !this.activated[k]) {
                    this.activated[k] = true;
                    this.queue[qt++] = k;
                }
            }
        }
    }

    // finds every match on the board; false when there is none
    findMatches(api: GameApi): bool {
        let any = false;
        for (let i = 0; i < NN; i++) {
            this.hRun[i] = this.runAt(i, true);
            this.vRun[i] = this.runAt(i, false);
            this.grp[i] = -1;
            if (this.hRun[i] >= 3 || this.vRun[i] >= 3) {
                any = true;
            }
        }
        if (!any) {
            return false;
        }
        // groups: matched cells of one cut joined through their runs
        let ng = 0;
        for (let i = 0; i < NN; i++) {
            if ((this.hRun[i] < 3 && this.vRun[i] < 3) || this.grp[i] >= 0) {
                continue;
            }
            let qh = 0, qt = 0;
            this.queue[qt++] = i;
            this.grp[i] = ng;
            while (qh < qt) {
                let k = this.queue[qh++];
                let r = k / N, c = k % N;
                // neighbours in the same matched run
                if (this.hRun[k] >= 3) {
                    if (c > 0 && this.typ[k - 1] == this.typ[k] && this.grp[k - 1] < 0) { this.grp[k - 1] = ng; this.queue[qt++] = k - 1; }
                    if (c < N - 1 && this.typ[k + 1] == this.typ[k] && this.grp[k + 1] < 0) { this.grp[k + 1] = ng; this.queue[qt++] = k + 1; }
                }
                if (this.vRun[k] >= 3) {
                    if (r > 0 && this.typ[k - N] == this.typ[k] && this.grp[k - N] < 0) { this.grp[k - N] = ng; this.queue[qt++] = k - N; }
                    if (r < N - 1 && this.typ[k + N] == this.typ[k] && this.grp[k + N] < 0) { this.grp[k + N] = ng; this.queue[qt++] = k + N; }
                }
            }
            // what this group makes
            let maxH = 0, maxV = 0, cross = -1, count = qt;
            for (let q = 0; q < qt; q++) {
                let k = this.queue[q];
                if (this.hRun[k] >= 3) { maxH = max<i32>(maxH, this.hRun[k]); }
                if (this.vRun[k] >= 3) { maxV = max<i32>(maxV, this.vRun[k]); }
                if (this.hRun[k] >= 3 && this.vRun[k] >= 3) { cross = k; }
                this.mark(k, 0);
            }
            let make = SP_NONE;
            if (maxH >= 5 || maxV >= 5) {
                make = SP_BRIL;
            } else if (maxH >= 3 && maxV >= 3) {
                make = SP_CLUSTER;
            } else if (maxH == 4) {
                make = SP_ROW;
            } else if (maxV == 4) {
                make = SP_COL;
            }
            if (make != SP_NONE && this.makeN < 16) {
                // where: a swapped cell in the group, else the corner of an L, else the run's second cell
                let at = -1;
                if (this.swapCells) {
                    if (this.grp[this.swB] == ng) { at = this.swB; } else if (this.grp[this.swA] == ng) { at = this.swA; }
                }
                if (at < 0 && cross >= 0) { at = cross; }
                if (at < 0) {
                    // the lowest cell of the group (nearest the player), leftmost on a tie
                    at = this.queue[0];
                    for (let q = 1; q < count; q++) {
                        let k = this.queue[q];
                        if (k / N > at / N || (k / N == at / N && k % N < at % N)) { at = k; }
                    }
                    if (make == SP_ROW || make == SP_COL || make == SP_BRIL) {
                        // the run's middle reads better than its end
                        let best = at, bestD = 99;
                        let mr = 0.0, mc = 0.0;
                        for (let q = 0; q < count; q++) { mr += <f64>this.rowOf(this.queue[q]); mc += <f64>(this.queue[q] % N); }
                        mr /= <f64>count; mc /= <f64>count;
                        for (let q = 0; q < count; q++) {
                            let k = this.queue[q];
                            let d = <i32>(Math.abs(<f64>this.rowOf(k) - mr) * 10 + Math.abs(<f64>(k % N) - mc) * 10);
                            if (d < bestD) { bestD = d; best = k; }
                        }
                        at = best;
                    }
                }
                if (this.spc[at] != SP_NONE) {
                    // that cell fires its own special: put the new one on a plain cell of the group
                    at = -1;
                    for (let q = 0; q < count; q++) {
                        if (this.spc[this.queue[q]] == SP_NONE) { at = this.queue[q]; break; }
                    }
                }
                if (at >= 0) {
                    this.makeCell[this.makeN] = at;
                    this.makeSpec[this.makeN] = make;
                    this.makeType[this.makeN] = this.typ[at];
                    this.makeN++;
                }
            }
            ng++;
        }
        return true;
    }

    // one cascade step: the board's matches (and what their specials reach) clear
    resolve(api: GameApi): void {
        this.resetClear();
        let found = this.findMatches(api);
        this.swapCells = false;
        if (!found) {
            this.settled(api);
            return;
        }
        this.cascade++;
        // a cell becoming a special stays (unless something else clears it)
        for (let m = 0; m < this.makeN; m++) {
            this.clr[this.makeCell[m]] = false;
        }
        this.propagate(api);
        // specials fired from elsewhere may clear a cell that was to become one: it then just clears
        for (let m = 0; m < this.makeN; m++) {
            if (this.clr[this.makeCell[m]]) {
                this.makeSpec[m] = SP_NONE;
            }
        }
        this.startClear(api, 0);
    }

    // the swapped pair holds a brilliant or two specials
    fireSwapCombo(api: GameApi, a: i32, b: i32): void {
        this.resetClear();
        this.cascade = 1;
        let sa = this.spc[a], sb = this.spc[b];
        let x = this.cellX(b), z = this.cellZ(b);
        if (sa == SP_BRIL && sb == SP_BRIL) {
            for (let i = 0; i < NN; i++) { this.mark(i, 0.1 + 0.02 * <f64>(abs<i32>(i / N - b / N) + abs<i32>(i % N - b % N))); }
            this.activated[a] = true; this.activated[b] = true;
            this.addBeam(3, b, 7);
            this.showPop("ROYAL FLUSH!");
            api.soundAt(SFX_EXPLODE, x, 0, z, 0.8, 0.8);
            for (let k = 0; k < 5; k++) { api.note(SCALE[k + 4], 0.5, 0, SFX_BELL, 0.08 * <f64>k); }
        } else if (sa == SP_BRIL || sb == SP_BRIL) {
            let br = sa == SP_BRIL ? a : b;
            let other = br == a ? b : a;
            let t = this.typ[other];
            this.mark(br, 0);
            this.activated[br] = true;
            let n = 0;
            for (let i = 0; i < NN; i++) {
                if (this.typ[i] == t) { this.mark(i, 0.08 + 0.025 * <f64>n); n++; }
            }
            this.addBeam(4, br, t);
            this.showPop("BRILLIANT!");
            api.soundAt(SFX_ZAP, this.cellX(br), 0, this.cellZ(br), 1.6, 0.55);
            for (let k = 0; k < 4; k++) { api.note(SCALE[7 - k], 0.45, 0, SFX_BELL, 0.07 * <f64>k); }
        } else {
            // two specials: a bigger blast at b
            this.activated[a] = true; this.activated[b] = true;
            this.mark(a, 0); this.mark(b, 0);
            let r = b / N, c = b % N;
            let bag = (sa == SP_ROW || sa == SP_COL) ? 1 : 0;
            bag += (sb == SP_ROW || sb == SP_COL) ? 1 : 0;
            if (bag == 2) {
                for (let k = 0; k < N; k++) {
                    this.mark(r * N + k, 0.035 * <f64>abs<i32>(k - c));
                    this.mark(k * N + c, 0.035 * <f64>abs<i32>(k - r));
                }
                this.addBeam(1, b, 0); this.addBeam(2, b, 0);
                this.showPop("CROSS CUT!");
                api.soundAt(SFX_ZAP, x, 0, z, 0.9, 0.7);
            } else if (bag == 0) {
                for (let dr = -2; dr <= 2; dr++) {
                    for (let dc = -2; dc <= 2; dc++) {
                        let rr = r + dr, cc = c + dc;
                        if (rr >= 0 && rr < N && cc >= 0 && cc < N) { this.mark(rr * N + cc, 0.03 * <f64>(abs<i32>(dr) + abs<i32>(dc))); }
                    }
                }
                this.addBeam(3, b, 2);
                this.showPop("BIG CLUSTER!");
                api.soundAt(SFX_EXPLODE, x, 0, z, 1.1, 0.7);
            } else {
                for (let d = -1; d <= 1; d++) {
                    for (let k = 0; k < N; k++) {
                        if (r + d >= 0 && r + d < N) { this.mark((r + d) * N + k, 0.035 * <f64>abs<i32>(k - c)); }
                        if (c + d >= 0 && c + d < N) { this.mark(k * N + c + d, 0.035 * <f64>abs<i32>(k - r)); }
                    }
                }
                for (let d = -1; d <= 1; d++) {
                    if (r + d >= 0 && r + d < N) { this.addBeam(1, (r + d) * N + c, 0); }
                }
                this.showPop("SETTING CUT!");
                api.soundAt(SFX_EXPLODE, x, 0, z, 1.3, 0.6);
                api.soundAt(SFX_ZAP, x, 0, z, 0.9, 0.5, 0.05);
            }
        }
        this.propagate(api);
        this.startClear(api, 0);
    }

    showPop(s: string): void {
        this.popText = s;
        this.popT = 0;
    }

    // starts the clear animation for the marked cells, scores them, plays the step's chime
    startClear(api: GameApi, extra: f64): void {
        let n = 0, last = 0.0, sx = 0.0, sz = 0.0;
        let low = 0, colours = 0;
        let seen = new StaticArray<bool>(8);
        for (let i = 0; i < NN; i++) {
            if (!this.clr[i]) {
                continue;
            }
            let g = this.cellGem[i];
            if (g < 0) {
                continue;
            }
            n++;
            sx += this.cellX(i); sz += this.cellZ(i);
            if (i > low) { low = i; }
            let t = this.typ[i];
            if (t >= 0 && t < 8 && !seen[t]) { seen[t] = true; colours++; }
            this.gMode[g] = G_CLEAR;
            this.gT[g] = -this.clrDelay[i] - extra;
            this.gLand[g] = -1;
            last = Math.max(last, this.clrDelay[i] + extra);
            this.releaseMark(api, g);
        }
        // specials being made: a brilliant is forged (its drum sinks, turns, rises); a baguette or a
        // cluster gets its mark
        let made = 0;
        for (let m = 0; m < this.makeN; m++) {
            let at = this.makeCell[m], sp = this.makeSpec[m];
            if (sp == SP_NONE) {
                continue;
            }
            let g = this.cellGem[at];
            if (g < 0) {
                continue;
            }
            if (sp == SP_BRIL) {
                this.spc[at] = SP_BRIL;
                this.typ[at] = T_BRIL;
                this.gSpec[g] = SP_BRIL;
                this.gMode[g] = G_FORGE;
                this.gT[g] = 0;
                this.gNewType[g] = T_BRIL;
                this.showPop("BRILLIANT!");
                for (let k = 0; k < 4; k++) { api.noteAt(FORGE_NOTES[k], this.cellX(at), 0, this.cellZ(at), 0.4, SFX_BELL, 0.12 + 0.06 * <f64>k); }
                made += 150;
            } else {
                let slot = this.takeMark(sp == SP_CLUSTER);
                if (slot < 0) {
                    continue;
                }
                this.spc[at] = sp;
                this.gSpec[g] = sp;
                this.gMark[g] = slot;
                this.markPop[slot] = 0;
                if (sp == SP_CLUSTER) {
                    this.showPop("CLUSTER!");
                    api.soundAt(SFX_POWERUP, this.cellX(at), 0, this.cellZ(at), 0.9, 0.45, 0.1);
                    made += 80;
                } else {
                    this.showPop("BAGUETTE!");
                    api.soundAt(SFX_POWERUP, this.cellX(at), 0, this.cellZ(at), 1.25, 0.45, 0.1);
                    made += 60;
                }
            }
        }
        let pts = (n * 10 + made) * this.cascade;
        this.score += pts;
        if (pts > 0) {
            this.gainText = "+" + pts.toString();
            this.gainT = 0;
            this.gainCell = low;
            if (n > 0) {
                this.gainX = sx / <f64>n;
                this.gainZ = sz / <f64>n;
            }
        }
        if (this.cascade >= 2) {
            this.showCascade = this.cascade;
            this.cascadeT = 0;
            if (this.cascade >= 3 && this.popT < 0) {
                this.showPop("CASCADE x" + this.cascade.toString());
            }
        }
        // the chime climbs the scale with the cascade; several colours at once add a third and a fifth
        let note = SCALE[min<i32>(this.cascade - 1, 10)];
        let pan = n > 0 ? api.panAt(sx / <f64>max<i32>(n, 1), 0, sz / <f64>max<i32>(n, 1)) : 0.0;
        api.note(note, 0.65, pan, SFX_BELL);
        api.note(note + 12, 0.25, pan, SFX_NOTE, 0.05);
        if (colours >= 2) { api.note(note + 4, 0.4, pan, SFX_BELL, 0.07); }
        if (colours >= 3) { api.note(note + 7, 0.4, pan, SFX_BELL, 0.14); }
        api.sound(SFX_POP, 1.2 + 0.08 * <f64>this.cascade, 0.35, pan, 0.06);
        this.clearEnd = last + 0.34;
        this.state = S_CLEAR;
        this.stateT = 0;
    }

    gainX: f64 = 0;
    gainZ: f64 = 0;

    takeMark(claw: bool): i32 {
        let a = claw ? 10 : 0, b = claw ? 10 + NCLAW : NBAND;
        for (let i = a; i < b; i++) {
            if (!this.markUsed[i]) {
                this.markUsed[i] = true;
                return i;
            }
        }
        return -1;
    }

    releaseMark(api: GameApi, g: i32): void {
        let m = this.gMark[g];
        if (m >= 0) {
            this.markUsed[m] = false;
            api.hide(this.markBone[m]);
            this.gMark[g] = -1;
        }
    }

    // cleared cells empty, the gems above slide down, new ones enter at the top
    gravity(api: GameApi): void {
        // free the cleared gems
        let freeG = new StaticArray<i32>(NN);
        let nf = 0;
        for (let i = 0; i < NN; i++) {
            if (this.clr[i] && this.cellGem[i] >= 0) {
                let g = this.cellGem[i];
                freeG[nf++] = g;
                this.cellGem[i] = -1;
                this.typ[i] = -1;
                this.spc[i] = SP_NONE;
                this.gSpec[g] = SP_NONE;
            }
        }
        let fi = 0;
        for (let c = 0; c < N; c++) {
            let write = N - 1;
            for (let r = N - 1; r >= 0; r--) {
                let i = r * N + c;
                if (this.cellGem[i] < 0) {
                    continue;
                }
                if (r != write) {
                    let j = write * N + c;
                    this.cellGem[j] = this.cellGem[i]; this.typ[j] = this.typ[i]; this.spc[j] = this.spc[i];
                    this.cellGem[i] = -1; this.typ[i] = -1; this.spc[i] = SP_NONE;
                    let g = this.cellGem[j];
                    this.gTZ[g] = this.cellZ(j);
                    this.gTX[g] = this.cellX(j);
                    if (this.gMode[g] != G_FORGE) {
                        this.gMode[g] = G_FALL;
                        this.gV[g] = 1.2;
                    }
                }
                write--;
            }
            // rows 0..write are empty: new gems rise one after another at the column's top and slide
            // down, the deepest first
            let k = 0;
            for (let r = write; r >= 0; r--) {
                let i = r * N + c;
                let g = freeG[fi++];
                let t = <i32>Math.floor(api.rand() * <f64>NCOL) % NCOL;
                this.cellGem[i] = g;
                this.typ[i] = t;
                this.spc[i] = SP_NONE;
                this.gType[g] = t;
                this.gSpec[g] = SP_NONE;
                this.gMark[g] = -1;
                this.gX[g] = this.cellX(c);
                this.gZ[g] = Z0;
                this.gTX[g] = this.cellX(i);
                this.gTZ[g] = this.cellZ(i);
                this.gMode[g] = G_ENTER;
                this.gT[g] = -0.03 - 0.085 * <f64>k;
                this.gY[g] = -0.3;
                this.gS[g] = 0.6;
                this.gV[g] = 1.5;
                this.gYaw[g] = 0;
                k++;
            }
        }
        this.state = S_FALL;
        this.stateT = 0;
    }

    // no more matches: next move, the end, or a reshuffle
    settled(api: GameApi): void {
        this.cascade = 0;
        if (this.moves <= 0) {
            this.endRun(api);
            return;
        }
        if (!this.hasMove()) {
            this.state = S_SHUFFLE;
            this.stateT = 0;
            this.shuffleMsgT = 0;
            for (let i = 0; i < NN; i++) {
                let g = this.cellGem[i];
                if (g >= 0 && this.spc[i] == SP_NONE) {
                    this.gMode[g] = G_HIDDEN;   // sinks (animated in update) and comes back retyped
                    this.gT[g] = 0;
                }
            }
            api.sound(SFX_WHOOSH, 0.7, 0.5);
            api.note(79, 0.4, 0, SFX_NOTE, 0.1); api.note(76, 0.4, 0, SFX_NOTE, 0.2); api.note(72, 0.4, 0, SFX_NOTE, 0.3);
            return;
        }
        this.state = S_IDLE;
        this.stateT = 0;
    }

    // ================================================================== per-frame

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged || api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.newBoard(api, false);
        }
        this.stateT += dt;
        this.started = true;

        // --- the state machine
        if (this.state == S_DEAL) {
            if (this.allRest() && this.stateT > 0.2) {
                this.state = S_IDLE;
                this.stateT = 0;
            }
        } else if (this.state == S_SWAP || this.state == S_BACK) {
            let u = Math.min(this.stateT / SWAP_T, 1.0);
            let e = u * u * (3 - 2 * u);
            let a = this.swA, b = this.swB;
            let ga = this.cellGem[a], gb = this.cellGem[b];
            if (this.state == S_BACK) {
                // ga and gb are still on their own cells: slide back from the other's cell
                this.gX[ga] = this.cellX(b) + (this.cellX(a) - this.cellX(b)) * e;
                this.gZ[ga] = this.cellZ(b) + (this.cellZ(a) - this.cellZ(b)) * e;
                this.gX[gb] = this.cellX(a) + (this.cellX(b) - this.cellX(a)) * e;
                this.gZ[gb] = this.cellZ(a) + (this.cellZ(b) - this.cellZ(a)) * e;
            } else {
                this.gX[ga] = this.cellX(a) + (this.cellX(b) - this.cellX(a)) * e;
                this.gZ[ga] = this.cellZ(a) + (this.cellZ(b) - this.cellZ(a)) * e;
                this.gX[gb] = this.cellX(b) + (this.cellX(a) - this.cellX(b)) * e;
                this.gZ[gb] = this.cellZ(b) + (this.cellZ(a) - this.cellZ(b)) * e;
            }
            // the passive gem ducks into the velvet while the other slides over it
            this.gY[gb] = -0.07 * Math.sin(u * Math.PI);
            this.gS[gb] = 1 - 0.12 * Math.sin(u * Math.PI);
            if (u >= 1) {
                this.gY[gb] = 0; this.gS[gb] = 1;
                if (this.state == S_SWAP) {
                    this.swapArrived(api);
                } else {
                    this.gLand[ga] = 0; this.gLand[gb] = 0;
                    this.state = S_IDLE;
                    this.stateT = 0;
                }
            }
        } else if (this.state == S_CLEAR) {
            if (this.stateT >= this.clearEnd && this.noForging()) {
                this.gravity(api);
            }
        } else if (this.state == S_FALL) {
            if (this.allRest() && this.stateT > 0.05) {
                this.resolve(api);
            }
        } else if (this.state == S_SHUFFLE) {
            if (this.stateT >= 0.32 && this.stateT - dt < 0.32) {
                this.fillNoMatch(api, true);
                for (let i = 0; i < NN; i++) {
                    let g = this.cellGem[i];
                    if (this.gMode[g] == G_HIDDEN) {
                        this.gType[g] = this.typ[i];
                        this.gMode[g] = G_ENTER;
                        this.gT[g] = -0.03 * <f64>(i % N + this.rowOf(i));
                        this.gX[g] = this.cellX(i); this.gZ[g] = this.cellZ(i);
                        this.gTX[g] = this.gX[g]; this.gTZ[g] = this.gZ[g];
                    }
                }
            }
            if (this.stateT > 0.5 && this.allRest()) {
                this.state = S_IDLE;
                this.stateT = 0;
            }
        } else if (this.state == S_END) {
            if (api.demo && this.stateT > 2.4) {
                this.newBoard(api, false);
            }
        }

        if (api.demo) {
            this.demoPlay(api);
        }

        this.animateGems(api);
        this.animateLoupe(api);
        this.animateFlame(api);
        this.animateHud(api);
    }

    allRest(): bool {
        for (let g = 0; g < NN; g++) {
            let m = this.gMode[g];
            if (m == G_FALL || m == G_ENTER || m == G_CLEAR || m == G_FORGE) {
                return false;
            }
        }
        return true;
    }

    noForging(): bool {
        for (let g = 0; g < NN; g++) {
            if (this.gMode[g] == G_FORGE) {
                return false;
            }
        }
        return true;
    }

    // a drum: its axis under (x, z), the cut `type` turned to the top, sunk by y, scaled s about the
    // top cut's base and squashed (sx, sy, sz) there; yaw turns it about the vertical
    placeDrum(api: GameApi, b: i32, x: f64, z: f64, y: f64, type: i32, s: f64, sx: f64, sy: f64, sz: f64, yawDeg: f64): void {
        if (b <= 0) {
            return;
        }
        let th = -60.0 * <f64>type * Math.PI / 180;
        let c = Math.cos(th), sn = Math.sin(th);
        let ps = yawDeg * Math.PI / 180;
        let cy = Math.cos(ps), sy0 = Math.sin(ps);
        let kx = s * sx, ky = s * sy, kz = s * sz;
        // L = S * Ry * Rx
        let l00 = kx * cy, l01 = kx * sy0 * sn, l02 = kx * sy0 * c;
        let l10 = 0.0, l11 = ky * c, l12 = -ky * sn;
        let l20 = -kz * sy0, l21 = kz * cy * sn, l22 = kz * cy * c;
        let p0x = <f64>api.restX[b], p0y = <f64>api.restY[b], p0z = <f64>api.restZ[b];
        // C = the axis, B = the base point scaled about; t = B + S (C - B) - L p0
        let cX = x, cY = AXIS_Y + y, cZ = z;
        let bX = x, bY = y, bZ = z;
        let tx = bX + kx * (cX - bX) - (l00 * p0x + l01 * p0y + l02 * p0z);
        let ty = bY + ky * (cY - bY) - (l10 * p0x + l11 * p0y + l12 * p0z);
        let tz = bZ + kz * (cZ - bZ) - (l20 * p0x + l21 * p0y + l22 * p0z);
        let m = b * 12;
        api.mats[m] = <f32>l00; api.mats[m + 1] = <f32>l01; api.mats[m + 2] = <f32>l02; api.mats[m + 3] = <f32>tx;
        api.mats[m + 4] = <f32>l10; api.mats[m + 5] = <f32>l11; api.mats[m + 6] = <f32>l12; api.mats[m + 7] = <f32>ty;
        api.mats[m + 8] = <f32>l20; api.mats[m + 9] = <f32>l21; api.mats[m + 10] = <f32>l22; api.mats[m + 11] = <f32>tz;
        api.dirty[b] = true;
        api.anyDirty = true;
    }

    animateGems(api: GameApi): void {
        let dt = api.dt;
        let landed = 0;
        for (let g = 0; g < NN; g++) {
            let b = this.bone[g];
            let mode = this.gMode[g];
            this.gT[g] += dt;
            let t = this.gT[g];
            let s = 1.0, sx = 1.0, sy = 1.0, sz = 1.0, y = this.gY[g];
            let typ = this.gType[g];
            if (mode == G_ENTER) {
                if (t < 0) {
                    api.hide(b);
                    continue;
                }
                // rise through the velvet at the top of the column in 0.1 s, then slide to the target
                let u = Math.min(t / 0.1, 1.0);
                y = -0.3 * (1 - u);
                s = 0.6 + 0.4 * u;
                if (u >= 1) {
                    if (Math.abs(this.gZ[g] - this.gTZ[g]) < 0.001 && Math.abs(this.gX[g] - this.gTX[g]) < 0.001) {
                        this.gMode[g] = G_REST;
                        this.gLand[g] = 0;
                        landed++;
                    } else {
                        this.gMode[g] = G_FALL;
                        this.gV[g] = 2.0;
                    }
                }
                this.gY[g] = y;
            } else if (mode == G_FALL) {
                this.gV[g] = Math.min(this.gV[g] + 26 * dt, 9.0);
                let dz = this.gTZ[g] - this.gZ[g];
                let stepz = this.gV[g] * dt;
                if (Math.abs(dz) <= stepz) {
                    this.gZ[g] = this.gTZ[g];
                    this.gX[g] = this.gTX[g];
                    this.gMode[g] = G_REST;
                    this.gLand[g] = 0;
                    landed++;
                } else {
                    this.gZ[g] += dz > 0 ? stepz : -stepz;
                }
            } else if (mode == G_CLEAR) {
                if (t < 0) {
                    // waiting for its wave: a nervous shiver
                    s = 1.0 + 0.04 * Math.sin(api.time * 60.0);
                } else if (t < 0.08) {
                    s = 1.0 + 3.0 * t;   // pops to 1.24
                    if (t - dt < 0) {
                        this.sparkle(api, g);
                    }
                } else if (t < 0.3) {
                    let u = (t - 0.08) / 0.22;
                    s = 1.24 * (1 - u) + 0.12 * u;
                    y = -0.12 * u;
                } else {
                    this.gMode[g] = G_HIDDEN;
                    api.hide(b);
                    continue;
                }
            } else if (mode == G_HIDDEN) {
                // the shuffle sinks gems this way too
                if (this.state == S_SHUFFLE && t < 0.3) {
                    let u = t / 0.3;
                    s = 1 - 0.4 * u;
                    y = -0.3 * u;
                    this.placeDrum(api, b, this.gX[g], this.gZ[g], y, typ, s, 1, 1, 1, this.gYaw[g]);
                    continue;
                }
                api.hide(b);
                continue;
            } else if (mode == G_FORGE) {
                // sinks, turns to the brilliant out of sight, rises with a pop
                if (t < 0.14) {
                    let u = t / 0.14;
                    y = -0.3 * u; s = 1 - 0.4 * u;
                } else if (t < 0.3) {
                    typ = this.gNewType[g];
                    this.gType[g] = typ;
                    let u = (t - 0.14) / 0.16;
                    y = -0.3 * (1 - u); s = 0.6 + 0.6 * u;
                } else if (t < 0.4) {
                    s = 1.2 - 2.0 * (t - 0.3);
                } else {
                    this.gMode[g] = G_REST;
                    this.gY[g] = 0;
                    this.gLand[g] = 0;
                }
                typ = this.gType[g];
            }
            // the landing squash
            if (this.gLand[g] >= 0) {
                this.gLand[g] += dt;
                let u = this.gLand[g];
                if (u < 0.14) {
                    let k = Math.sin(u / 0.14 * Math.PI) * (1 - u / 0.14);
                    sy = 1 - 0.28 * k;
                    sx = 1 + 0.14 * k;
                    sz = 1 + 0.14 * k;
                } else {
                    this.gLand[g] = -1;
                }
            }
            // the selected gem breathes
            let cell = this.cellOf(g);
            if (cell >= 0 && cell == this.sel && this.state == S_IDLE) {
                s *= 1.06 + 0.05 * Math.sin(api.time * 9.0);
            }
            // the brilliant turns slowly
            let yaw = 0.0;
            if (typ == T_BRIL) {
                yaw = Math.floor(api.time * 8.0) * 11.25;
            }
            this.placeDrum(api, b, this.gX[g], this.gZ[g], y, typ, s, sx, sy, sz, yaw);
            // its mark rides on top
            let m = this.gMark[g];
            if (m >= 0) {
                let mb = this.markBone[m];
                this.markPop[m] += dt;
                let mp = this.markPop[m];
                let ms = mp < 0.12 ? 0.3 + mp / 0.12 * 0.95 : (mp < 0.22 ? 1.25 - (mp - 0.12) * 2.5 : 1.0);
                let ss = s * ms;
                if (m >= 10) {
                    // the claws sit at the base, at the gem's corners; they pulse gently
                    let k = 1.0 + 0.06 * Math.sin(api.time * 5.0 + <f64>g);
                    api.place(mb, this.gX[g], y, this.gZ[g], 0, 0, 0, Math.max(0.2, ss * k));
                } else {
                    let yawM = this.gSpec[g] == SP_COL ? 90.0 : 0.0;
                    let ty = y + TOPY[min<i32>(typ, 5)] * s * sy - 0.015;
                    // the rail's gold tips slide out and back: a line about to go
                    let k = 1.0 + 0.08 * Math.sin(api.time * 6.0 + <f64>g);
                    api.placeScaled(mb, this.gX[g], ty, this.gZ[g], yawM, Math.max(0.2, ss * k), Math.max(0.2, ss), Math.max(0.2, ss));
                }
            }
        }
        // landing ticks: one a frame at most, and not more than every 50 ms
        if (landed > 0 && api.time - this.lastTick > 0.05) {
            this.lastTick = api.time;
            api.sound(SFX_TICK, 1.3 + 0.05 * <f64>min<i32>(landed, 6), 0.22 + 0.03 * <f64>min<i32>(landed, 5));
        }
    }

    cellOf(g: i32): i32 {
        for (let i = 0; i < NN; i++) {
            if (this.cellGem[i] == g) {
                return i;
            }
        }
        return -1;
    }

    // ================================================================== the loupe

    animateLoupe(api: GameApi): void {
        let b = this.loupe;
        if (b <= 0) {
            return;
        }
        // where should it be?
        let target = -1, dip = false, curX = 0.0, curZ = 0.0, freeCur = false;
        if (api.demo) {
            if (this.state == S_IDLE && this.dStep > 0) {
                curX = this.dCurX; curZ = this.dCurZ; freeCur = true;
                dip = this.dStep == 2;
            } else if ((this.state == S_SWAP || this.state == S_BACK) && this.swB >= 0) {
                target = this.swB;
            } else if (this.dHasCur) {
                // between moves the hand rests where it last worked
                curX = this.dCurX; curZ = this.dCurZ; freeCur = true;
            }
        } else {
            if (this.pressed && this.downCell >= 0) {
                target = this.hoverCell >= 0 ? this.hoverCell : this.downCell;
                dip = true;
            } else if (this.sel >= 0) {
                target = this.sel;
                dip = true;
            } else if ((this.state == S_SWAP || this.state == S_BACK) && this.swB >= 0) {
                target = this.swB;
            } else if (this.hoverCell >= 0 && api.time - this.hoverT < 2.5) {
                target = this.hoverCell;
            }
        }
        if (this.state == S_END) {
            target = -1; freeCur = false;
        }
        let tx = -2.42, ty = 0.08, tz = 0.35, tp = -90.0, tyaw = 14.0;
        if (target >= 0 || freeCur) {
            let gx = freeCur ? curX : this.cellX(target);
            let gz = freeCur ? curZ : this.cellZ(target);
            let h = dip ? 0.36 : 0.55;
            // the ring's centre sits on the view ray through the gem's middle
            let k = 1.0 / Math.tan(PITCH * Math.PI / 180);
            tx = gx; ty = 0.08 + h; tz = gz + h * k;
            tp = -PITCH; tyaw = -24.0;
        }
        if (!this.lInit) {
            this.lX = tx; this.lY = ty; this.lZ = tz; this.lPitch = tp; this.lYaw = tyaw;
            this.lInit = true;
        }
        let a = 1 - Math.exp(-api.dt * 16.0);
        this.lX += (tx - this.lX) * a;
        this.lY += (ty - this.lY) * a;
        this.lZ += (tz - this.lZ) * a;
        let ar = 1 - Math.exp(-api.dt * 10.0);
        this.lPitch += (tp - this.lPitch) * ar;
        this.lYaw += (tyaw - this.lYaw) * ar;
        // place with the ring's centre at (lX, lY, lZ): find where the ring centre goes for a pivot at
        // the origin, then shift
        let ringY = <f64>api.restY[b] + 1.003 * 1.15;
        api.place(b, 0, 0, 0, this.lYaw, this.lPitch, 0);
        api.transform(b, <f64>api.restX[b], ringY, <f64>api.restZ[b]);
        let ox = api.tx, oy = api.ty, oz = api.tz;
        api.place(b, this.lX - ox, this.lY - oy, this.lZ - oz, this.lYaw, this.lPitch, 0);
    }

    animateFlame(api: GameApi): void {
        let b = this.flame;
        if (b <= 0) {
            return;
        }
        // stepped at 10 fps from a hash of the step: no api.rand(), so the demo is untouched
        let k = <i32>Math.floor(api.time * 10.0);
        let h = <f64>(((k * 1103515245 + 12345) >> 8) & 255) / 255.0;
        let h2 = <f64>(((k * 214013 + 2531011) >> 9) & 255) / 255.0;
        let sy = 0.85 + 0.35 * h;
        let sxz = 1.05 - 0.15 * h;
        api.placeScaled(b, <f64>api.restX[b], <f64>api.restY[b], <f64>api.restZ[b], 0, sxz, sy, sxz, 0, (h2 - 0.5) * 14.0);
    }

    // ================================================================== HUD effects

    sparkle(api: GameApi, g: i32): void {
        if (!api.project(<f32>this.gX[g], 0.1, <f32>this.gZ[g])) {
            return;
        }
        let x = api.screenX, y = api.screenY;
        let col = C_CREAM;
        let t = this.gType[g];
        if (t == 0) { col = C_TEAL; } else if (t == 1) { col = C_SAGE; } else if (t == 2) { col = C_GOLD; }
        else if (t == 3) { col = C_AMBER; } else if (t == 4) { col = C_CREAM; } else { col = C_GOLD; }
        // a burst of sparks, their directions fixed by the gem index (no api.rand: the demo stays put)
        for (let k = 0; k < 5; k++) {
            let i = this.spNext;
            this.spNext = (this.spNext + 1) % NSPARK;
            let ang = (<f64>k * 1.2566 + <f64>g * 0.7) % 6.2832;
            let sp = 22.0 + <f64>((g * 7 + k * 13) % 11) * 2.0;
            this.spX[i] = x; this.spY[i] = y;
            this.spVX[i] = <f32>(Math.cos(ang) * sp);
            this.spVY[i] = <f32>(Math.sin(ang) * sp * 0.8 - 10.0);
            this.spT[i] = 0;
            this.spC[i] = k == 0 ? C_CREAM : col;
        }
    }

    animateHud(api: GameApi): void {
        let dt = <f32>api.dt;
        for (let i = 0; i < NSPARK; i++) {
            if (this.spT[i] < 0) {
                continue;
            }
            this.spT[i] += dt;
            if (this.spT[i] > 0.45) {
                this.spT[i] = -1;
                continue;
            }
            this.spX[i] += this.spVX[i] * dt;
            this.spY[i] += this.spVY[i] * dt;
            this.spVY[i] += 40.0 * dt;
            this.spVX[i] *= <f32>(1.0 - 2.5 * api.dt);
        }
        for (let i = 0; i < 8; i++) {
            if (this.beamT[i] >= 0) {
                this.beamT[i] += api.dt;
                if (this.beamT[i] > 0.3) {
                    this.beamT[i] = -1;
                }
            }
        }
        if (this.popT >= 0) {
            this.popT += api.dt;
            if (this.popT > 1.0) { this.popT = -1; }
        }
        if (this.gainT >= 0) {
            this.gainT += api.dt;
            if (this.gainT > 0.8) { this.gainT = -1; }
        }
        if (this.cascadeT >= 0) {
            this.cascadeT += api.dt;
            if (this.cascadeT > 1.6) { this.cascadeT = -1; }
        }
        if (this.shuffleMsgT >= 0) {
            this.shuffleMsgT += api.dt;
            if (this.shuffleMsgT > 1.2) { this.shuffleMsgT = -1; }
        }
    }

    // ================================================================== the demo player

    // a swap's worth to the demo: what it clears and makes, a little extra low on the board (cascades)
    evalSwap(a: i32, b: i32): f64 {
        let sa = this.spc[a], sb = this.spc[b];
        if (sa == SP_BRIL || sb == SP_BRIL) {
            if (sa == SP_BRIL && sb == SP_BRIL) { return 60; }
            let other = sa == SP_BRIL ? b : a;
            let t = this.typ[other], n = 0;
            for (let i = 0; i < NN; i++) { if (this.typ[i] == t) { n++; } }
            return 8 + <f64>n;
        }
        if (sa != SP_NONE && sb != SP_NONE) {
            return 25;
        }
        this.swapLogic(a, b);
        let v = 0.0;
        for (let k = 0; k < 2; k++) {
            let c = k == 0 ? a : b;
            let h = this.runAt(c, true), w = this.runAt(c, false);
            let hh = h >= 3 ? h : 0, ww = w >= 3 ? w : 0;
            if (hh + ww == 0) { continue; }
            v += <f64>(hh + ww);
            if (hh >= 5 || ww >= 5) { v += 12; } else if (hh >= 3 && ww >= 3) { v += 7; } else if (hh == 4 || ww == 4) { v += 5; }
            if (this.spc[c] != SP_NONE) { v += 6; }
            v += 0.25 * <f64>this.rowOf(c);
        }
        this.swapLogic(a, b);
        return v;
    }

    demoPlay(api: GameApi): void {
        if (this.state != S_IDLE) {
            if (this.state != S_SWAP && this.state != S_BACK) {
                this.dStep = 0;
            }
            return;
        }
        let dt = api.dt;
        if (this.dStep == 0) {
            this.dWait -= dt;
            if (this.dWait > 0) {
                return;
            }
            // pick a move: usually the best, sometimes one of the next few, now and then a slip
            let n = 0;
            for (let i = 0; i < NN; i++) {
                for (let d = 0; d < 2; d++) {
                    let j = d == 0 ? i + 1 : i + N;
                    if ((d == 0 && i % N == N - 1) || j >= NN) { continue; }
                    if (!this.swapValid(i, j)) { continue; }
                    if (n < 128) {
                        this.dCandA[n] = i; this.dCandB[n] = j; this.dCandS[n] = this.evalSwap(i, j);
                        n++;
                    }
                }
            }
            if (n == 0) {
                return;
            }
            // sort by worth (descending), a few candidates only matter
            for (let p = 0; p < n; p++) {
                for (let q = p + 1; q < n; q++) {
                    if (this.dCandS[q] > this.dCandS[p]) {
                        let ta = this.dCandA[p]; this.dCandA[p] = this.dCandA[q]; this.dCandA[q] = ta;
                        let tb = this.dCandB[p]; this.dCandB[p] = this.dCandB[q]; this.dCandB[q] = tb;
                        let ts = this.dCandS[p]; this.dCandS[p] = this.dCandS[q]; this.dCandS[q] = ts;
                    }
                }
            }
            let r = api.rand();
            let pick = 0;
            if (r > 0.62) {
                pick = min<i32>(n - 1, 1 + <i32>Math.floor(api.rand() * 3.0));
            }
            let a = this.dCandA[pick], b = this.dCandB[pick];
            // a slip: 7 % of moves try a swap that does nothing (it bounces back)
            if (api.rand() < 0.07) {
                let c = <i32>Math.floor(api.rand() * <f64>NN) % NN;
                let o = c % N < N - 1 ? c + 1 : c - 1;
                if (!this.swapValid(c, o)) { a = c; b = o; }
            }
            // drag the swap the way a person would: from the gem that moves into the match
            if (api.rand() < 0.5) { let t = a; a = b; b = t; }
            this.dA = a; this.dB = b;
            this.dStep = 1;
            this.dHasCur = true;
            this.dWait = 0.22 + 0.12 * api.rand();
            this.dCurX = this.cellX(a);
            this.dCurZ = this.cellZ(a);
        } else if (this.dStep == 1) {
            this.dCurX = this.cellX(this.dA); this.dCurZ = this.cellZ(this.dA);
            this.dWait -= dt;
            if (this.dWait <= 0) {
                this.dStep = 2;
                this.dWait = 0.16 + 0.1 * api.rand();
                this.sel = this.dA;
            }
        } else if (this.dStep == 2) {
            this.dCurX = this.cellX(this.dA); this.dCurZ = this.cellZ(this.dA);
            this.dWait -= dt;
            if (this.dWait <= 0) {
                this.dStep = 3;
                this.sel = -1;
                this.beginSwap(api, this.dA, this.dB);
                this.dCurX = this.cellX(this.dB); this.dCurZ = this.cellZ(this.dB);
                this.dWait = 0.45 + 0.5 * api.rand();
                this.dStep = 0;
            }
        }
    }

    // ================================================================== input (pointer and touch)

    cellAt(api: GameApi, x: f32, y: f32): i32 {
        if (!api.pick(x, y, 0.08)) {
            return -1;
        }
        let c = <i32>Math.floor((<f64>api.hitX - (X0 - CELL * 0.5)) / CELL);
        let r = <i32>Math.floor((<f64>api.hitZ - (Z0 - CELL * 0.5)) / CELL);
        if (c < 0 || c >= N || r < 0 || r >= N) {
            return -1;
        }
        return r * N + c;
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        let cell = this.cellAt(api, x, y);
        if (kind == POINTER_DOWN) {
            this.pressed = true;
            this.downX = x; this.downY = y;
            this.swiped = false;
            this.hoverCell = cell; this.hoverT = api.time;
            if (this.state == S_END) {
                if (this.stateT > 0.8) {
                    this.newBoard(api, false);
                }
                this.downCell = -1;
                return true;
            }
            this.downCell = cell;
            this.downWasSel = cell >= 0 && cell == this.sel;
            if (this.state != S_IDLE) {
                return true;
            }
            if (cell < 0) {
                this.sel = -1;
                return true;
            }
            if (this.sel >= 0 && this.adjacent(this.sel, cell)) {
                this.beginSwap(api, this.sel, cell);
                this.downCell = -1;
                return true;
            }
            if (cell != this.sel) {
                this.sel = cell;
                api.soundAt(SFX_CLICK, this.cellX(cell), 0, this.cellZ(cell), 1.5, 0.45);
            }
            return true;
        }
        if (kind == POINTER_MOVE) {
            // the loupe follows a finger while it is down; a bare move (a mouse) previews a cell
            if (cell >= 0 && (this.pressed || api.hoverSeen)) { this.hoverCell = cell; this.hoverT = api.time; }
            // a swipe: from the pressed gem towards a neighbour, past 6 art pixels
            if (this.pressed && !this.swiped && this.downCell >= 0 && this.state == S_IDLE) {
                let dx = x - this.downX, dy = y - this.downY;
                if (Mathf.max(Mathf.abs(dx), Mathf.abs(dy)) >= 6) {
                    let r = this.downCell / N, c = this.downCell % N;
                    if (Mathf.abs(dx) > Mathf.abs(dy)) { c += dx > 0 ? 1 : -1; } else { r += dy > 0 ? 1 : -1; }
                    if (r >= 0 && r < N && c >= 0 && c < N) {
                        this.swiped = true;
                        this.beginSwap(api, this.downCell, r * N + c);
                    }
                }
            }
            return true;
        }
        if (kind == POINTER_UP) {
            // a tap on the selected gem (no swipe) puts it down again
            if (this.pressed && !this.swiped && this.downWasSel && cell == this.downCell && this.state == S_IDLE) {
                this.sel = -1;
            }
            this.pressed = false;
            this.downCell = -1;
            return true;
        }
        return true;
    }

    // ================================================================== HUD

    star(api: GameApi, x: f32, y: f32, s: f32, on: bool): void {
        // a five-row star, s pixels a dot
        let fill = on ? api.paletteColor(C_GOLD) : api.paletteColor(C_SAGE);
        let rows: StaticArray<i32> = [4, 14, 31, 14, 17];   // bit masks, 5 wide
        for (let r = 0; r < 5; r++) {
            for (let c = 0; c < 5; c++) {
                if ((rows[r] >> (4 - c)) & 1) {
                    api.rect(x + <f32>c * s, y + <f32>r * s, s, s, fill);
                }
            }
        }
    }

    hud(api: GameApi): void {
        let ink = api.paletteColor(C_UMBER);
        let dark = api.paletteColor(C_NIGHT);
        let cream = api.paletteColor(C_CREAM);
        let gold = api.paletteColor(C_GOLD);
        let tan = api.paletteColor(C_TAN);

        // --- effects over the board
        for (let i = 0; i < 8; i++) {
            if (this.beamT[i] < 0) {
                continue;
            }
            let t = this.beamT[i];
            let on = (<i32>Math.floor(t * 30.0)) % 2 == 0;
            let c = on ? gold : cream;
            let cell = this.beamCell[i];
            let k = this.beamKind[i];
            if (k == 1 || k == 2) {
                let r = cell / N, cc = cell % N;
                let x0: f64, z0: f64, x1: f64, z1: f64;
                if (k == 1) { x0 = this.cellX(r * N); x1 = this.cellX(r * N + N - 1); z0 = this.cellZ(cell); z1 = z0; }
                else { z0 = this.cellZ(cc); z1 = this.cellZ((N - 1) * N + cc); x0 = this.cellX(cell); x1 = x0; }
                let spread = t * 3.5;
                let mx = this.cellX(cell), mz = this.cellZ(cell);
                api.project(<f32>(mx + (x0 - mx) * Math.min(spread, 1.0)), 0.12, <f32>(mz + (z0 - mz) * Math.min(spread, 1.0)));
                let ax = api.screenX, ay = api.screenY;
                api.project(<f32>(mx + (x1 - mx) * Math.min(spread, 1.0)), 0.12, <f32>(mz + (z1 - mz) * Math.min(spread, 1.0)));
                let bx = api.screenX, by = api.screenY;
                api.line(ax, ay, bx, by, c);
                if (k == 1) { api.line(ax, ay - 1, bx, by - 1, cream); } else { api.line(ax - 1, ay, bx - 1, by, cream); }
            } else if (k == 3) {
                api.project(<f32>this.cellX(cell), 0.1, <f32>this.cellZ(cell));
                let cx = api.screenX, cy = api.screenY;
                let rad = <f32>(4.0 + t * 60.0 * (1.0 + <f64>this.beamR[i]));
                let lim = <f32>(16.0 * (<f64>this.beamR[i] + 0.6));
                if (rad > lim) { rad = lim; }
                api.line(cx - rad, cy - rad * 0.9, cx + rad, cy - rad * 0.9, c);
                api.line(cx - rad, cy + rad * 0.9, cx + rad, cy + rad * 0.9, c);
                api.line(cx - rad, cy - rad * 0.9, cx - rad, cy + rad * 0.9, c);
                api.line(cx + rad, cy - rad * 0.9, cx + rad, cy + rad * 0.9, c);
            } else if (k == 4) {
                // the brilliant's light reaches every gem of the cut it took
                api.project(<f32>this.cellX(cell), 0.15, <f32>this.cellZ(cell));
                let cx = api.screenX, cy = api.screenY;
                for (let j = 0; j < NN; j++) {
                    let g = this.cellGem[j];
                    if (g < 0 || this.gMode[g] != G_CLEAR || this.gType[g] != this.beamR[i]) { continue; }
                    api.project(<f32>this.gX[g], 0.1, <f32>this.gZ[g]);
                    api.line(cx, cy, api.screenX, api.screenY, c);
                }
            }
        }
        for (let i = 0; i < NSPARK; i++) {
            if (this.spT[i] < 0) {
                continue;
            }
            let c = api.paletteColor(this.spC[i]);
            let x = Mathf.round(this.spX[i]), y = Mathf.round(this.spY[i]);
            if (this.spT[i] < 0.18) {
                // a little cross first, then a dot
                api.rect(x - 1, y, 3, 1, c);
                api.rect(x, y - 1, 1, 3, c);
            } else {
                api.rect(x, y, 1, 1, c);
            }
        }
        if (this.gainT >= 0) {
            api.project(<f32>this.gainX, 0.2, <f32>this.gainZ);
            let w = api.textWidth(this.gainText, 1);
            let y = api.screenY - 4 - <f32>(this.gainT * 14.0);
            api.text(Mathf.round(api.screenX - w * 0.5), Mathf.round(y), this.gainText, cream, 1, dark);
        }

        // --- the order card (right): score, stars, moves, best; its left edge from the world
        api.project(2.22, 0, 0);
        let cx = Mathf.round(api.screenX);
        let cw: f32 = 38;
        api.text(cx, 13, "SCORE", ink, 1);
        let sc = this.score.toString();
        let scale = sc.length >= 5 ? 1 : 2;
        api.text(cx, <f32>(scale == 2 ? 20 : 22), sc, dark, scale);
        // progress to three stars, with the star marks on it
        let barY: f32 = 33;
        api.rect(cx, barY, cw, 3, api.paletteColor(C_SAGE));
        let f = Mathf.min(<f32>this.score / <f32>STAR3, 1);
        if (f > 0) {
            api.rect(cx, barY, Mathf.max(1, Mathf.round(cw * f)), 3, tan);
        }
        let marks: StaticArray<i32> = [STAR1, STAR2, STAR3];
        for (let k = 0; k < 3; k++) {
            let mx = cx + Mathf.round(cw * <f32>marks[k] / <f32>STAR3) - 1;
            api.rect(mx, barY - 1, 1, 5, ink);
        }
        let earned = this.starsFor(this.score);
        for (let k = 0; k < 3; k++) {
            this.star(api, cx + <f32>(k * 13), 39, 2, k < earned);
        }
        api.text(cx, 55, "MOVES", ink, 1);
        let mv = this.moves.toString();
        api.text(cx, 62, mv, this.moves <= 3 ? api.paletteColor(C_BROWN) : dark, 2);
        api.text(cx, 79, "BEST", ink, 1);
        api.text(cx, 86, this.best.toString(), dark, 1);
        if (this.showCascade >= 2 && this.cascadeT >= 0) {
            api.text(cx, 96, "CASCADE", ink, 1);
            api.text(cx, 103, "x" + this.showCascade.toString(), dark, 2);
        } else {
            api.text(cx, 96, "GOAL", ink, 1);
            let goal = earned >= 3 ? STAR3 : marks[earned];
            api.text(cx, 103, goal.toString(), dark, 1);
        }

        // --- words over the board
        api.project(0, 0.08, 0);
        let bx = Mathf.round(api.screenX);   // the board's centre in HUD pixels
        if (this.popT >= 0) {
            let w = api.textWidth(this.popText, 2);
            let y = <f32>(58.0 - Math.min(this.popT, 0.15) * 40.0);
            api.text(Mathf.round(bx - w * 0.5), Mathf.round(y), this.popText, gold, 2, dark);
        }
        if (this.shuffleMsgT >= 0) {
            let s = "NO MOVES: RESHUFFLE";
            api.text(Mathf.round(bx - api.textWidth(s, 1) * 0.5), 62, s, cream, 1, dark);
        }
        if (this.firstMove && !api.demo && this.state != S_END) {
            let s1 = "TAP A GEM, THEN A NEIGHBOUR";
            let s2 = "OR SWIPE IT. LINE UP 3!";
            api.rect(bx - 57, 119, 114, 14, dark);
            api.text(Mathf.round(bx - api.textWidth(s1, 1) * 0.5), 121, s1, cream, 1);
            api.text(Mathf.round(bx - api.textWidth(s2, 1) * 0.5), 127, s2, gold, 1);
        }

        // --- the end of a tray
        if (this.state == S_END) {
            let pw: f32 = 100, ph: f32 = 62;
            let px = bx - pw * 0.5, py: f32 = 34;
            api.rect(px - 1, py - 1, pw + 2, ph + 2, tan);
            api.rect(px, py, pw, ph, dark);
            let title = this.stars >= 3 ? "MASTERWORK!" : (this.stars >= 1 ? "TRAY SET" : "OUT OF MOVES");
            api.text(Mathf.round(bx - api.textWidth(title, 1) * 0.5), py + 4, title, gold, 1);
            for (let k = 0; k < 3; k++) {
                let shown = k < this.stars && this.stateT > 0.25 + 0.3 * <f64>k;
                this.star(api, bx - 26 + <f32>(k * 18), py + 12, 3, shown);
            }
            let s1 = "SCORE " + this.score.toString();
            api.text(Mathf.round(bx - api.textWidth(s1, 1) * 0.5), py + 31, s1, cream, 1);
            let s2 = this.newBest ? "NEW BEST!" : "BEST " + this.best.toString();
            api.text(Mathf.round(bx - api.textWidth(s2, 1) * 0.5), py + 39, s2, this.newBest ? gold : cream, 1);
            if (this.stateT > 0.8 && (<i32>Math.floor(this.stateT * 2.0)) % 2 == 0) {
                let s3 = api.demo ? "A NEW TRAY SOON" : "TAP FOR A NEW TRAY";
                api.text(Mathf.round(bx - api.textWidth(s3, 1) * 0.5), py + 51, s3, api.paletteColor(C_SAGE), 1);
            }
        }
    }
}
