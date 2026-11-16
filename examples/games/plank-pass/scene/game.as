// Plank Pass: a little steam kettle cart follows a valley road cut by five gaps. At each gap, drag from a
// steel anchor bolt (or a joint you made) to place a beam: wooden PLANKS are the road the cart drives on,
// steel GIRDERS are stronger and stiffer frame members it does not drive on. Joints snap to a 1 m grid, a
// beam is at most 3.2 m long, every beam costs money and each gap has a budget. Tap a beam to remove it,
// GO sends the cart across. The bridge is a 2D mass-spring truss (Verlet / XPBD small steps): joints fall
// with gravity, beams stretch and squeeze, the stress shows as a colour on each beam; a beam pushed past
// its strength snaps, and the cart falls in. Then fix it and go again. Cross all five gaps: the score is
// the total cost (lower is better) with stars per gap by the budget left. Pointer (or touch) only.
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP, SFX_BELL, SFX_BLIP, SFX_CLICK, SFX_COIN, SFX_EXPLODE,
    SFX_HIT, SFX_NOTE, SFX_POP, SFX_SPLASH, SFX_THUD, SFX_TICK, SFX_WHOOSH, SFX_WIN } from "./game_api";

// ------------------------------------------------------------------ the world (models/env/make_env.py)
const NG: i32 = 5;
const GC: StaticArray<f64> = [0.0, 18.0, 36.0, 56.0, 78.0];      // gap centres (x)
const GB: StaticArray<f64> = [0.0, 0.0, 0.0, 1.0, 1.0];          // the road's y at the gap's left bank
const GL: StaticArray<i32> = [-3, -4, -4, -6, -6];               // left edge (relative)
const GR: StaticArray<i32> = [3, 4, 4, 6, 6];                    // right edge
const GYR: StaticArray<i32> = [0, 0, 1, 0, 0];                   // the right bank's y (relative)
const GFL: StaticArray<f64> = [-3.0, -4.5, -4.5, -3.5, -3.5];    // the floor or the water (relative)
const GWET: StaticArray<bool> = [true, false, false, true, true];
const BUDGET: StaticArray<i32> = [300, 500, 500, 650, 1700];
const GNAME: StaticArray<string> = ["MILL CREEK", "FERN GULLY", "STEP GORGE", "TWIN ROCK", "LONG WASH"];
// anchors (relative grid points), gap g's from AN_OFF[g] to AN_OFF[g + 1]
const AN_OFF: StaticArray<i32> = [0, 4, 8, 12, 18, 22];
const AN_X: StaticArray<i32> = [-3, 3, -3, 3, -4, 4, -4, 4, -4, 4, -4, 4, -6, 6, -6, 6, -1, 1, -6, 6, -6, 6];
const AN_Y: StaticArray<i32> = [0, 0, -2, -2, 0, 0, -2, -2, 0, 1, -2, -1, 0, 0, -2, -2, -2, -2, 0, 0, -3, -3];
const GRID_TOP: i32 = 3;          // joints may sit up to 3 m above the road
const DEPOT_X: f64 = 91.5;        // the road's end: the cart parks at the depot

// ------------------------------------------------------------------ the beams and the solver
const MAXLEN: f64 = 3.2;          // a beam's longest (the models are baked at it, and only shortened)
const K_PLANK: i32 = 0;
const K_GIRDER: i32 = 1;
const MASS: StaticArray<f64> = [0.25, 0.5];             // per metre
const COMPL: StaticArray<f64> = [1.0 / 9000.0, 1.0 / 40000.0]; // compliance (1 / stiffness)
const STRENGTH: StaticArray<f64> = [170.0, 480.0];      // the force that snaps it
const COST: StaticArray<f64> = [20.0, 55.0];            // per metre (a beam's cost is rounded to 5)
const DAMP_B: f64 = 0.02;         // damping along a beam (XPBD)
const DAMPV: f64 = 1.5;           // velocity damping (air)
const JOINT_M: f64 = 0.15;
const G: f64 = 9.8;
const SUB: i32 = 16;              // substeps per 1/60 s step
const STEP: f64 = 1.0 / 60.0;
const CART_M: f64 = 8.0;
const WHEEL: f64 = 0.62;          // the axles, either side of the cart's middle
const WHEEL_R: f64 = 0.228;
const DECK: f64 = 0.11;           // half a plank's thickness: the cart rides on its top
const GIRDER_Z: f64 = -0.55;      // the girders run on the far side of the road
const SPEED: f64 = 2.5;           // the cart's test speed across a bridge
const NPLANK: i32 = 24;
const NGIRDER: i32 = 24;
const MAXDB: i32 = 30;            // beams in one design
const MAXJ: i32 = 80;
const MAXSB: i32 = 72;
const NPUFF: i32 = 4;

// ------------------------------------------------------------------ states
const ST_BUILD: i32 = 0;
const ST_RUN: i32 = 1;            // the cart crosses
const ST_HELD: i32 = 2;           // made it: stars, then on to the next gap
const ST_FAIL: i32 = 3;           // it fell: back to building
const ST_MOVE: i32 = 4;           // driving along the road to the next gap
const ST_END: i32 = 5;            // all five crossed

const CS_ROAD: i32 = 0;           // on the road or a deck
const CS_FALL: i32 = 1;
const CS_DOWN: i32 = 2;           // in the water or on the rocks

// wheel tracks
const W_LEFT: i32 = -1;
const W_AIR: i32 = -2;
const W_RIGHT: i32 = -3;

// HUD buttons (HUD pixels, bottom row): plank, girder, clear, go
const BTN_Y: f32 = 116;
const BTN_H: f32 = 15;

// palette indices (art/palette.json "colors")
const P_INK: i32 = 0;      // #313432
const P_RED: i32 = 4;      // #7c4545
const P_BROWN: i32 = 5;    // #675239
const P_MAUVE: i32 = 6;    // #625055
const P_ROCK: i32 = 8;     // #796c64
const P_OLIVE: i32 = 9;    // #718245
const P_TAN: i32 = 10;     // #9e805c
const P_PINK: i32 = 12;    // #ac9086
const P_GREY: i32 = 13;    // #a6a296
const P_KHAKI: i32 = 14;   // #b4ab8f
const P_CREAM: i32 = 15;   // #bcb7a5

// ------------------------------------------------------------------ the known designs (verified with a Python
// port of this solver; the demo builds them, sometimes first without its "key" beams, which fails)
// one beam: kind, ax, ay, bx, by (relative grid points); KEY marks the beams a flawed try leaves out
const D_OFF: StaticArray<i32> = [0, 5, 14, 23, 32, 41, 52, 64, 85];
const D_GAP: StaticArray<i32> = [0, 1, 1, 2, 2, 3, 3, 4];
const D_DATA: StaticArray<i32> = [
    // G0 A: three 2 m planks, two planks from the low anchors as struts (230)
    0, -3, 0, -1, 0, 0, -1, 0, 1, 0, 0, 1, 0, 3, 0, 0, -3, -2, -1, 0, 0, 3, -2, 1, 0,
    // G1 A: four 2 m planks, struts from the low anchors, a king post below (380)
    0, -4, 0, -2, 0, 0, -2, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 4, 0, 0, -4, -2, -2, 0, 0, 4, -2, 2, 0, 0, -2, 0, 0, -1,
    0, 0, -1, 2, 0, 0, 0, -1, 0, 0,
    // G1 C: the same with the king post above (380)
    0, -4, 0, -2, 0, 0, -2, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 4, 0, 0, -4, -2, -2, 0, 0, 4, -2, 2, 0, 0, -2, 0, 0, 1,
    0, 0, 1, 2, 0, 0, 0, 1, 0, 0,
    // G2 A: a deck climbing one step, struts, a king post below (395)
    0, -4, 0, -2, 0, 0, -2, 0, 0, 0, 0, 0, 0, 2, 1, 0, 2, 1, 4, 1, 0, -4, -2, -2, 0, 0, 4, -1, 2, 1, 0, -2, 0, 0, -1,
    0, 0, -1, 0, 0, 0, 0, -1, 2, 1,
    // G2 C: the king post above, 2 m (415)
    0, -4, 0, -2, 0, 0, -2, 0, 0, 0, 0, 0, 0, 2, 1, 0, 2, 1, 4, 1, 0, -4, -2, -2, 0, 0, 4, -1, 2, 1, 0, -2, 0, 0, 2,
    0, 0, 2, 2, 1, 0, 0, 2, 0, 0,
    // G3 A: six 2 m planks on struts from the banks and the rock (485)
    0, -6, 0, -4, 0, 0, -4, 0, -2, 0, 0, -2, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 4, 0, 0, 4, 0, 6, 0,
    0, -6, -2, -4, 0, 0, -1, -2, -2, 0, 0, -1, -2, 0, 0, 0, 1, -2, 2, 0, 0, 6, -2, 4, 0,
    // G3 B: one more strut from the rock (530)
    0, -6, 0, -4, 0, 0, -4, 0, -2, 0, 0, -2, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 4, 0, 0, 4, 0, 6, 0,
    0, -6, -2, -4, 0, 0, -1, -2, -2, 0, 0, -1, -2, 0, 0, 0, 1, -2, 2, 0, 0, 1, -2, 0, 0, 0, 6, -2, 4, 0,
    // G4: a Pratt truss over a plank deck: steel chords and ends, wooden posts and diagonals (1410)
    0, -6, 0, -4, 0, 0, -4, 0, -2, 0, 0, -2, 0, 0, 0, 0, 0, 0, 2, 0, 0, 2, 0, 4, 0, 0, 4, 0, 6, 0,
    1, -6, 0, -4, 2, 1, 6, 0, 4, 2, 1, -4, 2, -2, 2, 1, -2, 2, 0, 2, 1, 0, 2, 2, 2, 1, 2, 2, 4, 2,
    0, -4, 2, -4, 0, 0, -2, 2, -2, 0, 0, 0, 2, 0, 0, 0, 2, 2, 2, 0, 0, 4, 2, 4, 0,
    0, -4, 2, -2, 0, 0, -2, 2, 0, 0, 0, 2, 2, 0, 0, 0, 4, 2, 2, 0];
// for each design, the beams (index within the design) a flawed try leaves out
const KEY_OFF: StaticArray<i32> = [0, 1, 4, 7, 10, 13, 15, 18, 19];
const KEY_IDX: StaticArray<i32> = [3, 6, 7, 8, 6, 7, 8, 6, 7, 8, 6, 7, 8, 7, 9, 7, 9, 10, 18];

export class Game {
    state: i32 = ST_BUILD;
    stateT: f64 = 0;
    gap: i32 = 0;
    wasDemo: bool = false;
    started: bool = false;     // play mode: the first beam or GO starts the clock of a run

    // run score
    total: i32 = 0;            // money spent on the bridges that held
    stars: i32 = 0;
    tries: i32 = 0;
    best: i32 = 0;             // the lowest total of a full run (0: none yet)
    gapStars: StaticArray<i32> = new StaticArray<i32>(5);
    lastStars: i32 = 0;
    lastCost: i32 = 0;
    newBest: bool = false;

    // the design being built (relative grid points)
    nd: i32 = 0;
    dK: StaticArray<i32> = new StaticArray<i32>(MAXDB);
    dAX: StaticArray<i32> = new StaticArray<i32>(MAXDB);
    dAY: StaticArray<i32> = new StaticArray<i32>(MAXDB);
    dBX: StaticArray<i32> = new StaticArray<i32>(MAXDB);
    dBY: StaticArray<i32> = new StaticArray<i32>(MAXDB);
    kind: i32 = K_PLANK;       // the material button

    // the solver
    nj: i32 = 0;
    jx: StaticArray<f64> = new StaticArray<f64>(MAXJ);
    jy: StaticArray<f64> = new StaticArray<f64>(MAXJ);
    jpx: StaticArray<f64> = new StaticArray<f64>(MAXJ);
    jpy: StaticArray<f64> = new StaticArray<f64>(MAXJ);
    jinv: StaticArray<f64> = new StaticArray<f64>(MAXJ);
    jm: StaticArray<f64> = new StaticArray<f64>(MAXJ);
    jfy: StaticArray<f64> = new StaticArray<f64>(MAXJ);
    nb: i32 = 0;
    sa: StaticArray<i32> = new StaticArray<i32>(MAXSB);
    sb: StaticArray<i32> = new StaticArray<i32>(MAXSB);
    sl: StaticArray<f64> = new StaticArray<f64>(MAXSB);
    sk: StaticArray<i32> = new StaticArray<i32>(MAXSB);
    sHalf: StaticArray<bool> = new StaticArray<bool>(MAXSB);  // a broken half: dangles, carries nothing
    sGone: StaticArray<bool> = new StaticArray<bool>(MAXSB);
    sBone: StaticArray<i32> = new StaticArray<i32>(MAXSB);
    sF: StaticArray<f64> = new StaticArray<f64>(MAXSB);
    sShow: StaticArray<f64> = new StaticArray<f64>(MAXSB);   // the stress shown (smoothed)
    acc: f64 = 0;
    simOn: bool = false;
    aL: i32 = 0;
    aR: i32 = 0;
    usedPlank: i32 = 0;
    usedGirder: i32 = 0;
    maxStress: f64 = 0;
    snaps: i32 = 0;

    // bones
    plankBone: StaticArray<i32> = new StaticArray<i32>(NPLANK);
    girderBone: StaticArray<i32> = new StaticArray<i32>(NGIRDER);
    cartB: i32 = -1;
    wheelFB: i32 = -1;
    wheelRB: i32 = -1;
    puffB: StaticArray<i32> = new StaticArray<i32>(NPUFF);
    splashB: i32 = -1;
    dustB: i32 = -1;

    // the cart
    cx: f64 = 0;
    cv: f64 = 0;               // forward speed
    cs: i32 = CS_ROAD;
    wb: StaticArray<i32> = new StaticArray<i32>(2);
    we: StaticArray<i32> = new StaticArray<i32>(2);
    wo: StaticArray<i32> = new StaticArray<i32>(2);
    wy: StaticArray<f64> = new StaticArray<f64>(2);
    wvy: StaticArray<f64> = new StaticArray<f64>(2);
    airT: f64 = 0;
    nextE: i32 = 0;
    nextO: i32 = 0;
    fy: f64 = 0;               // falling: the base point, its velocity, the tilt and its spin
    fvy: f64 = 0;
    fvx: f64 = 0;
    fang: f64 = 0;
    fangV: f64 = 0;
    spin: f64 = 0;             // the wheels' turn (degrees)
    tilt: f64 = 0;
    baseY: f64 = 0;
    parkX: f64 = 0;
    rollIn: f64 = 0;           // > 0: a fresh cart rolls in to the bank after a fall

    // effects
    pT: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    pX: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    pY: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    pNext: i32 = 0;
    puffT: f64 = 0;
    splT: f64 = -1;
    splX: f64 = 0;
    splY: f64 = 0;
    dustT: f64 = -1;
    dustX: f64 = 0;
    dustY: f64 = 0;
    shakeT: f64 = 0;
    camX: f64 = 0;
    camY: f64 = 0;
    camFromX: f64 = 0;
    camFromY: f64 = 0;
    moveFromX: f64 = 0;
    eyeDY: f64 = 0;
    eyeDZ: f64 = 0;
    flashT: f64 = 0;           // a refused action blinks the budget
    msg: string = "";
    creakF: i32 = -99;
    chuffT: f64 = 0;

    // the pointer
    down: bool = false;
    dragging: bool = false;
    fromX: i32 = 0;
    fromY: i32 = 0;
    toX: i32 = 0;
    toY: i32 = 0;
    toOk: bool = false;
    downHX: f32 = 0;
    downHY: f32 = 0;
    downWX: f64 = 0;
    downWY: f64 = 0;
    moved: bool = false;

    // the demo player
    dDesign: i32 = 0;
    dFlawed: bool = false;
    dWasFlawed: bool = false;
    dQueue: StaticArray<i32> = new StaticArray<i32>(MAXDB);  // design beam indices still to build
    dQn: i32 = 0;
    dQi: i32 = 0;
    dPhase: i32 = 0;           // 0 think, 1 move to the start, 2 drag, 3 to a button, 4 press
    dT: f64 = 0;
    curX: f32 = 0;             // the demo's hand (HUD pixels)
    curY: f32 = 0;
    curFX: f32 = 0;
    curFY: f32 = 0;
    curTX: f32 = 0;
    curTY: f32 = 0;
    curOn: bool = false;
    curPress: bool = false;
    dBtn: i32 = -1;

    // ================================================================== setup

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < NPLANK; i++) {
            this.plankBone[i] = api.bone("plank" + i.toString());
        }
        for (let i = 0; i < NGIRDER; i++) {
            this.girderBone[i] = api.bone("girder" + i.toString());
        }
        this.cartB = api.bone("cart");
        this.wheelFB = api.bone("wheelF");
        this.wheelRB = api.bone("wheelR");
        for (let i = 0; i < NPUFF; i++) {
            this.puffB[i] = api.bone("puff" + i.toString());
            this.pT[i] = -1;
        }
        this.splashB = api.bone("splash");
        this.dustB = api.bone("dust");
        // the camera keeps the scene's offset from its target (20 degrees above, 30 m away)
        this.eyeDY = api.eyeY - api.targetY;
        this.eyeDZ = api.eyeZ - api.targetZ;
        this.wasDemo = api.demo;
        this.newRun(api);
    }

    // ------------------------------------------------------------------ run control

    newRun(api: GameApi): void {
        this.total = 0;
        this.stars = 0;
        this.tries = 0;
        this.newBest = false;
        for (let g = 0; g < NG; g++) {
            this.gapStars[g] = 0;
        }
        this.started = false;
        this.splT = -1;
        this.dustT = -1;
        for (let i = 0; i < NPUFF; i++) {
            this.pT[i] = -1;
        }
        this.enterGap(api, 0);
        this.camX = GC[0];
        this.camY = GB[0] - 0.6;
        if (api.demo) {
            // the demo opens with the first bridge built and the cart already rolling onto it
            this.dDesign = 0;
            this.dFlawed = false;
            this.loadDesign(0, false);
            this.cx = GC[0] + <f64>GL[0] - 2.2;
            this.go(api, true);
        }
    }

    enterGap(api: GameApi, g: i32): void {
        this.gap = g;
        this.nd = 0;
        this.kind = K_PLANK;
        this.simOn = false;
        this.state = ST_BUILD;
        this.stateT = 0;
        this.parkX = GC[g] + <f64>GL[g] - 1.7;
        this.cx = this.parkX;
        this.cv = 0;
        this.cs = CS_ROAD;
        this.tilt = 0;
        this.rollIn = 0;
        this.dragging = false;
        this.down = false;
        this.dPhase = 0;
        this.dQn = 0;
        this.dQi = 0;
        this.curOn = false;
        this.dWasFlawed = false;
        if (api.demo) {
            this.pickDemoDesign(api);
        }
    }

    // ------------------------------------------------------------------ the design

    beamCost(k: i32, ax: i32, ay: i32, bx: i32, by: i32): i32 {
        let L = Math.sqrt(<f64>((bx - ax) * (bx - ax) + (by - ay) * (by - ay)));
        return <i32>Math.round(COST[k] * L / 5.0) * 5;
    }

    cost(): i32 {
        let c = 0;
        for (let i = 0; i < this.nd; i++) {
            c += this.beamCost(this.dK[i], this.dAX[i], this.dAY[i], this.dBX[i], this.dBY[i]);
        }
        return c;
    }

    countKind(k: i32): i32 {
        let n = 0;
        for (let i = 0; i < this.nd; i++) {
            if (this.dK[i] == k) {
                n++;
            }
        }
        return n;
    }

    isAnchor(g: i32, x: i32, y: i32): bool {
        for (let a = AN_OFF[g]; a < AN_OFF[g + 1]; a++) {
            if (AN_X[a] == x && AN_Y[a] == y) {
                return true;
            }
        }
        return false;
    }

    isJoint(x: i32, y: i32): bool {
        if (this.isAnchor(this.gap, x, y)) {
            return true;
        }
        for (let i = 0; i < this.nd; i++) {
            if ((this.dAX[i] == x && this.dAY[i] == y) || (this.dBX[i] == x && this.dBY[i] == y)) {
                return true;
            }
        }
        return false;
    }

    // a grid point a joint may sit on: in the gap's air (not in a bank, the rock or the floor), or an anchor
    allowed(x: i32, y: i32): bool {
        let g = this.gap;
        if (this.isAnchor(g, x, y)) {
            return true;
        }
        if (x < GL[g] || x > GR[g] || y > GRID_TOP + max<i32>(0, GYR[g])) {
            return false;
        }
        if (<f64>y < GFL[g] + 1.0) {
            return false;
        }
        if (x == GL[g] && y <= 0) {
            return false;
        }
        if (x == GR[g] && y <= GYR[g]) {
            return false;
        }
        if (g == 3 && x >= -1 && x <= 1 && y <= -2) {
            return false;   // Twin Rock's pillar
        }
        return true;
    }

    findBeam(ax: i32, ay: i32, bx: i32, by: i32): i32 {
        for (let i = 0; i < this.nd; i++) {
            if ((this.dAX[i] == ax && this.dAY[i] == ay && this.dBX[i] == bx && this.dBY[i] == by) ||
                (this.dAX[i] == bx && this.dAY[i] == by && this.dBX[i] == ax && this.dBY[i] == ay)) {
                return i;
            }
        }
        return -1;
    }

    // 0 placed, 1 over budget, 2 no room, 3 already there / invalid
    addBeam(k: i32, ax: i32, ay: i32, bx: i32, by: i32): i32 {
        if ((ax == bx && ay == by) || this.findBeam(ax, ay, bx, by) >= 0) {
            return 3;
        }
        if (this.nd >= MAXDB || this.countKind(k) >= (k == K_PLANK ? NPLANK - 4 : NGIRDER - 4)) {
            return 2;
        }
        if (this.cost() + this.beamCost(k, ax, ay, bx, by) > BUDGET[this.gap]) {
            return 1;
        }
        let i = this.nd;
        this.dK[i] = k;
        this.dAX[i] = ax;
        this.dAY[i] = ay;
        this.dBX[i] = bx;
        this.dBY[i] = by;
        this.nd++;
        return 0;
    }

    removeBeam(i: i32): void {
        for (let k = i; k < this.nd - 1; k++) {
            this.dK[k] = this.dK[k + 1];
            this.dAX[k] = this.dAX[k + 1];
            this.dAY[k] = this.dAY[k + 1];
            this.dBX[k] = this.dBX[k + 1];
            this.dBY[k] = this.dBY[k + 1];
        }
        this.nd--;
    }

    loadDesign(d: i32, flawed: bool): void {
        this.nd = 0;
        for (let i = 0; i < (D_OFF[d + 1] - D_OFF[d]); i++) {
            if (flawed && this.isKey(d, i)) {
                continue;
            }
            let o = (D_OFF[d] + i) * 5;
            this.addBeam(D_DATA[o], D_DATA[o + 1], D_DATA[o + 2], D_DATA[o + 3], D_DATA[o + 4]);
        }
    }

    isKey(d: i32, i: i32): bool {
        for (let k = KEY_OFF[d]; k < KEY_OFF[d + 1]; k++) {
            if (KEY_IDX[k] == i) {
                return true;
            }
        }
        return false;
    }

    // ================================================================== the solver

    addJoint(x: f64, y: f64, fixed: bool): i32 {
        let j = this.nj;
        if (j >= MAXJ) {
            return MAXJ - 1;
        }
        this.jx[j] = x;
        this.jy[j] = y;
        this.jpx[j] = x;
        this.jpy[j] = y;
        this.jinv[j] = fixed ? 0.0 : 1.0;   // set from the masses below
        this.jm[j] = fixed ? 0.0 : JOINT_M;
        this.jfy[j] = 0;
        this.nj++;
        return j;
    }

    jointAt(x: f64, y: f64): i32 {
        for (let j = 0; j < this.nj; j++) {
            if (Math.abs(this.jx[j] - x) < 0.01 && Math.abs(this.jy[j] - y) < 0.01) {
                return j;
            }
        }
        return -1;
    }

    takeBone(k: i32): i32 {
        if (k == K_PLANK) {
            if (this.usedPlank < NPLANK) {
                return this.plankBone[this.usedPlank++];
            }
        } else if (this.usedGirder < NGIRDER) {
            return this.girderBone[this.usedGirder++];
        }
        return -1;
    }

    // the design becomes the solver's joints and beams, in the gap's world coordinates
    buildSim(): void {
        let g = this.gap;
        let ox = GC[g], oy = GB[g];
        this.nj = 0;
        this.nb = 0;
        this.usedPlank = 0;
        this.usedGirder = 0;
        for (let a = AN_OFF[g]; a < AN_OFF[g + 1]; a++) {
            this.addJoint(ox + <f64>AN_X[a], oy + <f64>AN_Y[a], true);
        }
        this.aL = this.jointAt(ox + <f64>GL[g], oy);
        this.aR = this.jointAt(ox + <f64>GR[g], oy + <f64>GYR[g]);
        for (let i = 0; i < this.nd; i++) {
            let ax = ox + <f64>this.dAX[i], ay = oy + <f64>this.dAY[i];
            let bx = ox + <f64>this.dBX[i], by = oy + <f64>this.dBY[i];
            let ja = this.jointAt(ax, ay);
            if (ja < 0) {
                ja = this.addJoint(ax, ay, false);
            }
            let jb = this.jointAt(bx, by);
            if (jb < 0) {
                jb = this.addJoint(bx, by, false);
            }
            let k = this.dK[i];
            let b = this.nb++;
            this.sa[b] = ja;
            this.sb[b] = jb;
            this.sl[b] = Math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
            this.sk[b] = k;
            this.sHalf[b] = false;
            this.sGone[b] = false;
            this.sF[b] = 0;
            this.sShow[b] = 0;
            this.sBone[b] = this.takeBone(k);
            let m = MASS[k] * this.sl[b] * 0.5;
            if (this.jinv[ja] > 0) {
                this.jm[ja] += m;
            }
            if (this.jinv[jb] > 0) {
                this.jm[jb] += m;
            }
        }
        for (let j = 0; j < this.nj; j++) {
            this.jinv[j] = this.jm[j] > 0 ? 1.0 / this.jm[j] : 0.0;
        }
        this.maxStress = 0;
        this.snaps = 0;
        this.acc = 0;
    }

    // the smoothest unbroken plank leaving joint J towards +x (at most ~60 degrees of turn)
    nextPlank(J: i32, cur: i32, slope: f64): i32 {
        let best = -1;
        let bd = 1.05;
        for (let i = 0; i < this.nb; i++) {
            if (i == cur || this.sGone[i] || this.sHalf[i] || this.sk[i] != K_PLANK) {
                continue;
            }
            let o = -1;
            if (this.sa[i] == J) {
                o = this.sb[i];
            } else if (this.sb[i] == J) {
                o = this.sa[i];
            } else {
                continue;
            }
            let dx = this.jx[o] - this.jx[J];
            if (dx < 0.05) {
                continue;
            }
            let d = Math.abs(Math.atan2(this.jy[o] - this.jy[J], dx) - Math.atan(slope));
            if (d < bd) {
                bd = d;
                best = i;
                this.nextE = J;
                this.nextO = o;
            }
        }
        return best;
    }

    // the wheel's road at x: the left bank, a plank (followed to its end, then the smoothest plank onward),
    // the right bank, or the air. Returns the road's centre line y, or -1e9 in the air; loads the plank.
    track(w: i32, x: f64): f64 {
        let g = this.gap;
        for (let it = 0; it < 4; it++) {
            let b = this.wb[w];
            if (b == W_LEFT) {
                if (x <= GC[g] + <f64>GL[g]) {
                    return GB[g] - DECK;
                }
                let nb = this.nextPlank(this.aL, -1, 0.0);
                if (nb < 0) {
                    this.wb[w] = W_AIR;
                    return -1e9;
                }
                this.wb[w] = nb;
                this.we[w] = this.nextE;
                this.wo[w] = this.nextO;
                continue;
            }
            if (b == W_RIGHT) {
                return GB[g] + <f64>GYR[g] - DECK;
            }
            if (b == W_AIR) {
                return -1e9;
            }
            if (this.sGone[b] || this.sHalf[b]) {
                this.wb[w] = W_AIR;
                return -1e9;
            }
            let e = this.we[w], o = this.wo[w];
            let x0 = this.jx[e], x1 = this.jx[o];
            if (x1 - x0 < 0.02) {
                this.wb[w] = W_AIR;
                return -1e9;
            }
            let t = (x - x0) / (x1 - x0);
            if (t <= 1.0) {
                if (t < 0) {
                    t = 0;
                }
                let F = CART_M * 0.5 * G;
                this.jfy[e] -= F * (1 - t);
                this.jfy[o] -= F * t;
                return this.jy[e] + (this.jy[o] - this.jy[e]) * t;
            }
            if (o == this.aR) {
                this.wb[w] = W_RIGHT;
                continue;
            }
            let slope = (this.jy[o] - this.jy[e]) / (x1 - x0);
            let nb = this.nextPlank(o, b, slope);
            if (nb < 0) {
                this.wb[w] = W_AIR;
                return -1e9;
            }
            this.wb[w] = nb;
            this.we[w] = this.nextE;
            this.wo[w] = this.nextO;
        }
        return -1e9;
    }

    // one 1/60 s step of the cart and the truss
    simStep(api: GameApi): void {
        let g = this.gap;
        let h = STEP / <f64>SUB;
        for (let j = 0; j < this.nj; j++) {
            this.jfy[j] = 0;
        }
        // the cart: its wheels follow the road and load the deck
        if (this.cs == CS_ROAD && (this.state == ST_RUN || this.state == ST_HELD)) {
            let target = this.state == ST_HELD ? 4.5 : SPEED;
            this.cv += Math.max(-3.0, Math.min(2.5, (target - this.cv) * 2.0)) * STEP;
            this.cx += this.cv * STEP;
            let air = 0;
            for (let w = 0; w < 2; w++) {
                let x = this.cx + (w == 0 ? WHEEL : -WHEEL);
                let y = this.track(w, x);
                if (y > -1e8) {
                    this.wy[w] = y;
                    this.wvy[w] = 0;
                } else {
                    this.wvy[w] -= G * STEP;
                    this.wy[w] += this.wvy[w] * STEP;
                    air++;
                }
            }
            if (air > 0) {
                this.airT += STEP;
                if (this.airT > 0.2) {
                    this.startFall(api);
                }
            } else {
                this.airT = 0;
            }
            if (this.state == ST_RUN && this.cx - WHEEL > GC[g] + <f64>GR[g] + 1.0) {
                this.held(api);
            }
        }
        // the truss: Verlet with small steps, one XPBD pass a substep
        let fl = GB[g] + GFL[g] - (GWET[g] ? 0.6 : 0.0);
        let xl = GC[g] + <f64>GL[g], xr = GC[g] + <f64>GR[g];
        let yl = GB[g], yr = GB[g] + <f64>GYR[g];
        let damp = Math.exp(-DAMPV * h);
        for (let s = 0; s < SUB; s++) {
            for (let i = 0; i < this.nj; i++) {
                let wi = this.jinv[i];
                if (wi == 0) {
                    continue;
                }
                let vx = (this.jx[i] - this.jpx[i]) / h * damp;
                let vy = (this.jy[i] - this.jpy[i]) / h * damp;
                vy += (-G + this.jfy[i] * wi) * h;
                this.jpx[i] = this.jx[i];
                this.jpy[i] = this.jy[i];
                this.jx[i] += vx * h;
                this.jy[i] += vy * h;
            }
            for (let b = 0; b < this.nb; b++) {
                if (this.sGone[b]) {
                    continue;
                }
                let a = this.sa[b], c = this.sb[b];
                let wa = this.jinv[a], wc = this.jinv[c];
                if (wa + wc == 0) {
                    continue;
                }
                let dx = this.jx[c] - this.jx[a], dy = this.jy[c] - this.jy[a];
                let L = Math.sqrt(dx * dx + dy * dy);
                if (L < 1e-9) {
                    continue;
                }
                let nx = dx / L, ny = dy / L;
                let C = L - this.sl[b];
                let al = COMPL[this.sk[b]];
                let at = al / (h * h);
                let gam = al * DAMP_B / h;
                let rv = ((this.jx[c] - this.jpx[c]) - (this.jx[a] - this.jpx[a])) * nx +
                         ((this.jy[c] - this.jpy[c]) - (this.jy[a] - this.jpy[a])) * ny;
                let dl = (-C - gam * rv) / ((1 + gam) * (wa + wc) + at);
                this.jx[a] -= wa * dl * nx;
                this.jy[a] -= wa * dl * ny;
                this.jx[c] += wc * dl * nx;
                this.jy[c] += wc * dl * ny;
                this.sF[b] = -dl / (h * h);   // tension > 0
            }
            // free joints stay out of the banks and above the floor (debris sinks a little into the water)
            for (let i = 0; i < this.nj; i++) {
                if (this.jinv[i] == 0) {
                    continue;
                }
                if (this.jy[i] < fl) {
                    this.jy[i] = fl;
                    this.jpx[i] = this.jx[i] * 0.5 + this.jpx[i] * 0.5;
                }
                if (this.jx[i] < xl && this.jy[i] < yl) {
                    this.jx[i] = xl;
                }
                if (this.jx[i] > xr && this.jy[i] < yr) {
                    this.jx[i] = xr;
                }
            }
        }
        // stress and breaks
        let worst = 0.0, worstB = -1;
        for (let b = 0; b < this.nb; b++) {
            if (this.sGone[b] || this.sHalf[b]) {
                continue;
            }
            let s = Math.abs(this.sF[b]) / STRENGTH[this.sk[b]];
            this.sShow[b] += (s - this.sShow[b]) * 0.25;
            if (s > this.maxStress) {
                this.maxStress = s;
            }
            if (s > worst) {
                worst = s;
                worstB = b;
            }
            if (s > 1.0) {
                this.snap(api, b);
            }
        }
        // creaks: sparse, keyed to the most stressed beam (never from api.rand)
        if (worstB >= 0 && worst > 0.5 && this.state == ST_RUN) {
            let gapF = <i32>(28.0 - worst * 18.0);
            if (api.frame - this.creakF > gapF) {
                this.creakF = api.frame;
                let mx = (this.jx[this.sa[worstB]] + this.jx[this.sb[worstB]]) * 0.5;
                let my = (this.jy[this.sa[worstB]] + this.jy[this.sb[worstB]]) * 0.5;
                if (this.sk[worstB] == K_PLANK) {
                    api.soundAt(SFX_CLICK, mx, my, 0, 0.32 + worst * 0.12, 0.25 + worst * 0.4);
                    api.soundAt(SFX_TICK, mx, my, 0, 0.45 + worst * 0.2, 0.2 + worst * 0.3, 0.05);
                } else {
                    api.soundAt(SFX_TICK, mx, my, 0, 0.22 + worst * 0.1, 0.3 + worst * 0.4);
                    api.noteAt(40.0 + worst * 6.0, mx, my, 0, 0.12 + worst * 0.15, SFX_BELL);
                }
            }
        }
    }

    // a beam snaps: two halves, each hanging from one end, a new free joint at the break
    snap(api: GameApi, b: i32): void {
        let a = this.sa[b], c = this.sb[b];
        let mx = (this.jx[a] + this.jx[c]) * 0.5, my = (this.jy[a] + this.jy[c]) * 0.5;
        let k = this.sk[b];
        let L = this.sl[b] * 0.5;
        this.snaps++;
        api.soundAt(SFX_HIT, mx, my, 0, k == K_PLANK ? 1.25 : 0.8, 0.9);
        api.soundAt(k == K_PLANK ? SFX_CLICK : SFX_EXPLODE, mx, my, 0, k == K_PLANK ? 0.7 : 1.6, 0.6, 0.03);
        this.shakeT = Math.max(this.shakeT, 0.18);
        if (this.nj + 2 > MAXJ || this.nb + 1 > MAXSB) {
            this.sGone[b] = true;
            return;
        }
        let vxa = this.jx[a] - this.jpx[a], vya = this.jy[a] - this.jpy[a];
        let vxc = this.jx[c] - this.jpx[c], vyc = this.jy[c] - this.jpy[c];
        let m = MASS[k] * L * 0.5 + 0.05;
        // half A: a .. j1
        let j1 = this.addJoint(mx - (mx - this.jx[a]) * 0.04, my - (my - this.jy[a]) * 0.04, false);
        this.jm[j1] = m;
        this.jinv[j1] = 1.0 / m;
        this.jpx[j1] = this.jx[j1] - vxa;
        this.jpy[j1] = this.jy[j1] - vya;
        this.sb[b] = j1;
        this.sl[b] = L * 0.96;
        this.sHalf[b] = true;
        // half B: j2 .. c, with a spare bone of the same kind (if the pool has none, it is gone)
        let bone = this.takeBone(k);
        if (bone < 0) {
            return;
        }
        let j2 = this.addJoint(mx + (this.jx[c] - mx) * 0.04, my + (this.jy[c] - my) * 0.04, false);
        this.jm[j2] = m;
        this.jinv[j2] = 1.0 / m;
        this.jpx[j2] = this.jx[j2] - vxc;
        this.jpy[j2] = this.jy[j2] - vyc;
        let n = this.nb++;
        this.sa[n] = j2;
        this.sb[n] = c;
        this.sl[n] = L * 0.96;
        this.sk[n] = k;
        this.sHalf[n] = true;
        this.sGone[n] = false;
        this.sBone[n] = bone;
        this.sF[n] = 0;
        this.sShow[n] = 0;
    }

    // ================================================================== the flow

    go(api: GameApi, quiet: bool): void {
        if (this.state != ST_BUILD) {
            return;
        }
        this.buildSim();
        this.simOn = true;
        this.state = ST_RUN;
        this.stateT = 0;
        this.cs = CS_ROAD;
        this.cv = quiet ? SPEED : 0.0;
        this.wb[0] = W_LEFT;
        this.wb[1] = W_LEFT;
        this.wy[0] = GB[this.gap] - DECK;
        this.wy[1] = GB[this.gap] - DECK;
        this.wvy[0] = 0;
        this.wvy[1] = 0;
        this.airT = 0;
        this.tries++;
        this.started = true;
        this.dragging = false;
        if (!quiet) {
            // the kettle's whistle: toot-toot
            api.noteAt(79, this.cx, GB[this.gap] + 1.3, 0, 0.55);
            api.noteAt(83, this.cx, GB[this.gap] + 1.3, 0, 0.45);
            api.noteAt(79, this.cx, GB[this.gap] + 1.3, 0, 0.55, SFX_NOTE, 0.2);
            api.noteAt(83, this.cx, GB[this.gap] + 1.3, 0, 0.45, SFX_NOTE, 0.2);
            api.sound(SFX_WHOOSH, 1.6, 0.25, 0, 0.05);
        }
    }

    startFall(api: GameApi): void {
        if (this.cs != CS_ROAD) {
            return;
        }
        this.cs = CS_FALL;
        this.fy = (this.wy[0] + this.wy[1]) * 0.5 + DECK;
        this.fvy = Math.min(this.wvy[0], this.wvy[1]) * 0.5;
        this.fvx = this.cv * 0.7;
        this.fang = this.tilt;
        // the end that lost its road drops first
        this.fangV = this.wy[0] < this.wy[1] ? -110.0 : 110.0;
        api.soundAt(SFX_WHOOSH, this.cx, this.fy, 0, 0.6, 0.5);
    }

    held(api: GameApi): void {
        let c = this.cost();
        let frac = <f64>c / <f64>BUDGET[this.gap];
        let st = frac <= 0.8 ? 3 : (frac <= 0.9 ? 2 : 1);
        this.lastStars = st;
        this.lastCost = c;
        this.gapStars[this.gap] = st;
        this.total += c;
        this.stars += st;
        this.state = ST_HELD;
        this.stateT = 0;
        // a jingle: up the C major arpeggio, a coin per star
        let x = this.cx;
        let y = GB[this.gap] + 1.0;
        api.noteAt(72, x, y, 0, 0.5, SFX_NOTE, 0.0);
        api.noteAt(76, x, y, 0, 0.5, SFX_NOTE, 0.11);
        api.noteAt(79, x, y, 0, 0.5, SFX_NOTE, 0.22);
        api.noteAt(84, x, y, 0, 0.55, SFX_BELL, 0.33);
        for (let s = 0; s < st; s++) {
            api.soundAt(SFX_COIN, x, y, 0, 1.0 + <f64>s * 0.12, 0.45, 0.55 + <f64>s * 0.16);
        }
    }

    crash(api: GameApi): void {
        let g = this.gap;
        this.cs = CS_DOWN;
        this.state = ST_FAIL;
        this.stateT = 0;
        this.shakeT = 0.35;
        let floor = GB[g] + GFL[g];
        if (GWET[g]) {
            this.splT = 0;
            this.splX = this.cx;
            this.splY = floor;
            api.soundAt(SFX_SPLASH, this.cx, floor, 0, 0.9, 1.0);
            api.soundAt(SFX_THUD, this.cx, floor, 0, 0.7, 0.5);
            this.msg = "SPLASH!";
        } else {
            this.dustT = 0;
            this.dustX = this.cx;
            this.dustY = floor;
            api.soundAt(SFX_EXPLODE, this.cx, floor, 0, 0.55, 0.8);
            api.soundAt(SFX_THUD, this.cx, floor, 0, 0.6, 1.0);
            api.soundAt(SFX_HIT, this.cx, floor, 0, 0.7, 0.5, 0.08);
            this.msg = "CRASH!";
        }
        api.sound(SFX_NOTE, Math.pow(2, (57.0 - 69.0) / 12.0), 0.35, 0, 0.5);
        api.sound(SFX_NOTE, Math.pow(2, (53.0 - 69.0) / 12.0), 0.35, 0, 0.7);
    }

    backToBuild(api: GameApi): void {
        this.simOn = false;
        this.state = ST_BUILD;
        this.stateT = 0;
        this.cs = CS_ROAD;
        this.tilt = 0;
        this.cv = 0;
        // a fresh cart rolls in from up the road
        this.rollIn = 1.0;
        this.cx = this.parkX - 5.0;
        this.dPhase = 0;
        if (api.demo && this.dWasFlawed) {
            // the demo saw what broke: it adds the beams it left out
            this.dFlawed = false;
            this.queueMissing();
        }
    }

    finish(api: GameApi): void {
        this.state = ST_END;
        this.stateT = 0;
        this.newBest = this.best == 0 || this.total < this.best;
        if (this.newBest) {
            this.best = this.total;
        }
        api.note(72, 0.5, 0, SFX_BELL, 0.0);
        api.note(76, 0.45, 0, SFX_BELL, 0.15);
        api.note(79, 0.45, 0, SFX_BELL, 0.3);
        api.note(84, 0.5, 0, SFX_BELL, 0.45);
        if (this.newBest) {
            api.sound(SFX_WIN, 1.0, 0.7, 0, 0.7);
        }
    }

    // ================================================================== update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged || api.demo != this.wasDemo) {
            // the host switched demo on or off: a fresh run either way
            this.wasDemo = api.demo;
            this.newRun(api);
        }
        this.stateT += dt;
        if (this.flashT > 0) {
            this.flashT -= dt;
        }
        let g = this.gap;

        if (api.demo) {
            this.demoThink(api, dt);
        }

        if (this.state == ST_BUILD) {
            if (this.rollIn > 0) {
                // the new cart rolls in and stops at the bank
                this.rollIn -= dt;
                let k = Math.max(0.0, this.rollIn);
                let nx = this.parkX - 5.0 * k * k;
                this.spin -= (nx - this.cx) / WHEEL_R * 57.2958;
                this.cx = nx;
            }
        }
        if (this.simOn) {
            this.acc += dt;
            let n = 0;
            while (this.acc >= STEP && n < 4) {
                this.acc -= STEP;
                this.simStep(api);
                n++;
            }
            if (this.acc > STEP) {
                this.acc = 0;
            }
        }
        if (this.state == ST_RUN || this.state == ST_HELD) {
            if (this.cs == CS_ROAD) {
                this.tilt = Math.atan2(this.wy[0] - this.wy[1], 2.0 * WHEEL) * 180.0 / Math.PI;
                this.baseY = (this.wy[0] + this.wy[1]) * 0.5 + DECK;
                this.spin -= this.cv * dt / WHEEL_R * 57.2958;
            }
        }
        if (this.cs == CS_FALL) {
            this.fvy -= G * dt;
            this.fy += this.fvy * dt;
            this.cx += this.fvx * dt;
            this.fang += this.fangV * dt;
            this.fangV *= Math.exp(-0.8 * dt);
            this.baseY = this.fy;
            this.tilt = this.fang;
            if (this.fy < GB[g] + GFL[g] + 0.15) {
                this.crash(api);
            }
        } else if (this.cs == CS_DOWN) {
            if (GWET[g]) {
                // sinking
                this.baseY -= 0.8 * dt;
            } else {
                this.baseY = GB[g] + GFL[g];
                this.tilt += (Math.round(this.tilt / 180.0) * 180.0 - this.tilt) * Math.min(1.0, dt * 6.0);
            }
        }
        if (this.state == ST_HELD) {
            if (this.stateT > 1.6 || this.cx > GC[g] + <f64>GR[g] + 5.0) {
                // on along the road
                this.state = ST_MOVE;
                this.stateT = 0;
                this.camFromX = this.camX;
                this.camFromY = this.camY;
                this.moveFromX = this.cx;
            }
        } else if (this.state == ST_MOVE) {
            let last = g == NG - 1;
            let tx = last ? DEPOT_X - 1.6 : GC[g + 1] + <f64>GL[g + 1] - 1.7;
            let d = tx - this.cx;
            let v = Math.min(5.0, Math.max(0.6, d * 1.4));
            if (d > 0.02) {
                this.cv = v;
                this.cx += Math.min(d, v * dt);
                this.spin -= v * dt / WHEEL_R * 57.2958;
            } else {
                this.cv = 0;
            }
            // the road's height here: the bank the cart is on
            let ry = g + 1 < NG ? GB[g + 1] : GB[NG - 1];
            if (this.cx < GC[g] + <f64>GR[g] + 0.5) {
                ry = GB[g] + <f64>GYR[g];
            }
            this.baseY = ry;
            this.tilt = 0;
            if (d <= 0.02 && this.stateT > 0.8) {
                // hide the old bridge once the camera has left it, and start the next gap (or finish)
                if (last) {
                    this.simOn = false;
                    this.finish(api);
                } else {
                    this.enterGap(api, g + 1);
                }
            }
        } else if (this.state == ST_FAIL) {
            if (this.stateT > 2.3) {
                this.backToBuild(api);
            }
        } else if (this.state == ST_END) {
            if (api.demo && this.stateT > 2.6) {
                this.newRun(api);
            }
        }
        if (this.state == ST_BUILD || (this.state == ST_END && this.cs == CS_ROAD)) {
            this.baseY = this.state == ST_END ? GB[NG - 1] : GB[this.gap];
            if (this.rollIn <= 0) {
                this.tilt = 0;
            }
        }

        this.updateCamera(api, dt);
        this.drawBeams(api);
        this.drawCart(api, dt);
        this.updateEffects(api, dt);
    }

    updateCamera(api: GameApi, dt: f64): void {
        let g = this.gap;
        let tx = GC[g], ty = GB[g] - 0.6;
        if (this.state == ST_MOVE) {
            // follow the cart, easing towards the next gap
            let last = g == NG - 1;
            let nx = last ? DEPOT_X - 4.0 : GC[g + 1];
            let ny = last ? GB[NG - 1] - 0.6 : GB[g + 1] - 0.6;
            let cartTo = last ? DEPOT_X - 1.6 : GC[g + 1] + <f64>GL[g + 1] - 1.7;
            let k = Math.max(0.0, Math.min(1.0, (this.cx - this.moveFromX) / Math.max(0.1, cartTo - this.moveFromX)));
            k = k * k * (3.0 - 2.0 * k);
            tx = this.camFromX + (nx - this.camFromX) * k;
            ty = this.camFromY + (ny - this.camFromY) * k;
        } else if (this.state == ST_END) {
            tx = DEPOT_X - 4.0;
            ty = GB[NG - 1] - 0.6;
        }
        if (this.state == ST_MOVE || this.state == ST_END) {
            this.camX = tx;
            this.camY = ty;
        } else {
            this.camX += (tx - this.camX) * Math.min(1.0, dt * 4.0);
            this.camY += (ty - this.camY) * Math.min(1.0, dt * 4.0);
        }
        let texel = api.orthoHeight / 136.0;
        let ox = 0.0, oy = 0.0;
        if (this.shakeT > 0) {
            this.shakeT -= dt;
            let k = Math.floor(api.time * 30.0);
            let a = Math.sin(k * 12.9898) * 43758.5453;
            a = a - Math.floor(a);
            let b = Math.sin(k * 78.233) * 12543.1234;
            b = b - Math.floor(b);
            ox = Math.round(a * 2.0 - 1.0) * texel;
            oy = Math.round(b * 2.0 - 1.0) * texel;
        }
        api.lookAt = true;
        api.targetX = this.camX + ox;
        api.targetY = this.camY + oy;
        api.targetZ = 0;
        api.eyeX = api.targetX;
        api.eyeY = api.targetY + this.eyeDY;
        api.eyeZ = this.eyeDZ;
    }

    // a beam's bone from a to b: baked 3.2 m long along +X from its pivot, shortened and rolled
    placeBeam(api: GameApi, bone: i32, ax: f64, ay: f64, bx: f64, by: f64): void {
        if (bone < 0) {
            return;
        }
        if (bx < ax) {
            let t = ax; ax = bx; bx = t;
            t = ay; ay = by; by = t;
        }
        let L = Math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
        if (L < 0.05) {
            api.hide(bone);
            return;
        }
        let ang = Math.atan2(by - ay, bx - ax) * 180.0 / Math.PI;
        api.placeScaled(bone, ax, ay, 0, 0, L / MAXLEN, 1, 1, 0, ang == 0 ? 0.0001 : ang);
    }

    drawBeams(api: GameApi): void {
        let usedP = 0, usedG = 0;
        if (this.simOn) {
            for (let b = 0; b < this.nb; b++) {
                let bone = this.sBone[b];
                if (bone < 0) {
                    continue;
                }
                if (this.sGone[b]) {
                    api.hide(bone);
                    continue;
                }
                this.placeBeam(api, bone, this.jx[this.sa[b]], this.jy[this.sa[b]], this.jx[this.sb[b]], this.jy[this.sb[b]]);
            }
            usedP = this.usedPlank;
            usedG = this.usedGirder;
        } else if (this.state == ST_BUILD) {
            let g = this.gap;
            for (let i = 0; i < this.nd; i++) {
                let bone = this.dK[i] == K_PLANK ? (usedP < NPLANK ? this.plankBone[usedP++] : -1) : (usedG < NGIRDER ? this.girderBone[usedG++] : -1);
                this.placeBeam(api, bone, GC[g] + <f64>this.dAX[i], GB[g] + <f64>this.dAY[i], GC[g] + <f64>this.dBX[i], GB[g] + <f64>this.dBY[i]);
            }
        }
        for (let i = usedP; i < NPLANK; i++) {
            api.hide(this.plankBone[i]);
        }
        for (let i = usedG; i < NGIRDER; i++) {
            api.hide(this.girderBone[i]);
        }
    }

    drawCart(api: GameApi, dt: f64): void {
        let bob = 0.0;
        if (this.state == ST_BUILD && this.rollIn <= 0) {
            // idling: the kettle shivers on its springs (stepped, 8 fps)
            bob = Math.floor(api.time * 8.0) % 2 == 0 ? 0.0 : 0.02;
        }
        let y = this.baseY + bob;
        if (this.cs == CS_DOWN && GWET[this.gap] && this.baseY < GB[this.gap] + GFL[this.gap] - 2.2) {
            api.hide(this.cartB);
            api.hide(this.wheelFB);
            api.hide(this.wheelRB);
            return;
        }
        api.place(this.cartB, this.cx, y, 0, 90, -this.tilt, 0, 1);
        let sp = Math.floor(this.spin / 22.5) * 22.5;    // the wheels turn in eighths of an octagon's corner
        api.transform(this.cartB, api.restX[this.wheelFB], api.restY[this.wheelFB], api.restZ[this.wheelFB]);
        api.place(this.wheelFB, api.tx, api.ty, api.tz, 90, -this.tilt + sp, 0, 1);
        api.transform(this.cartB, api.restX[this.wheelRB], api.restY[this.wheelRB], api.restZ[this.wheelRB]);
        api.place(this.wheelRB, api.tx, api.ty, api.tz, 90, -this.tilt + sp, 0, 1);
    }

    updateEffects(api: GameApi, dt: f64): void {
        // steam puffs from the chimney: fast while driving, lazy while waiting
        let driving = (this.state == ST_RUN || this.state == ST_HELD || this.state == ST_MOVE) && this.cs == CS_ROAD && this.cv > 0.3;
        let every = driving ? 0.28 : 0.75;
        if (this.cs != CS_ROAD || this.state == ST_END) {
            every = 1e9;
        }
        this.puffT += dt;
        if (this.puffT > every) {
            this.puffT = 0;
            api.transform(this.cartB, api.restX[this.cartB] + 0.58, api.restY[this.cartB] + 1.38, api.restZ[this.cartB]);
            let k = this.pNext;
            this.pNext = (this.pNext + 1) % NPUFF;
            this.pT[k] = 0;
            this.pX[k] = api.tx;
            this.pY[k] = api.ty;
            if (driving) {
                // the engine's chuff, keyed to the puffs
                api.soundAt(SFX_TICK, api.tx, api.ty, 0, 0.3, 0.18);
            }
        }
        for (let k = 0; k < NPUFF; k++) {
            let b = this.puffB[k];
            if (this.pT[k] < 0) {
                api.hide(b);
                continue;
            }
            this.pT[k] += dt;
            let t = this.pT[k];
            if (t > 1.1) {
                this.pT[k] = -1;
                api.hide(b);
                continue;
            }
            let ts = Math.floor(t * 10.0) / 10.0;     // stepped, 10 fps
            let drift = driving ? -1.2 : -0.25;
            let s = 0.6 + ts * 1.1;
            if (ts > 0.8) {
                s *= Math.max(0.15, 1.0 - (ts - 0.8) / 0.3);
            }
            api.place(b, this.pX[k] + drift * ts, this.pY[k] + 0.9 * ts, 0.0, ts * 90.0, 0, 0, s);
        }
        // the splash: a crown that rises and falls back
        if (this.splT >= 0) {
            this.splT += dt;
            let t = Math.floor(this.splT * 12.0) / 12.0;
            if (t > 1.0) {
                this.splT = -1;
                api.hide(this.splashB);
            } else {
                let up = t < 0.35 ? t / 0.35 : 1.0 - (t - 0.35) / 0.65;
                api.placeScaled(this.splashB, this.splX, this.splY - 0.2, 0.0, 0, 1.0 + t * 0.6, Math.max(0.05, up * 1.5), 1.0 + t * 0.6);
            }
        } else {
            api.hide(this.splashB);
        }
        if (this.dustT >= 0) {
            this.dustT += dt;
            let t = Math.floor(this.dustT * 10.0) / 10.0;
            if (t > 1.3) {
                this.dustT = -1;
                api.hide(this.dustB);
            } else {
                let s = 0.7 + t * 0.9;
                let sy = t > 0.8 ? Math.max(0.1, 1.0 - (t - 0.8) / 0.5) : 1.0;
                api.placeScaled(this.dustB, this.dustX, this.dustY + t * 0.3, 0.6, 0, s, s * sy, s);
            }
        } else {
            api.hide(this.dustB);
        }
    }

    // ================================================================== input

    // a grid point near world (wx, wy) the drag may end on: allowed, within reach of the start, not the start
    snapTarget(wx: f64, wy: f64): void {
        let g = this.gap;
        let rx = wx - GC[g], ry = wy - GB[g];
        let bestD = 1e9;
        this.toOk = false;
        let x0 = this.fromX - 4, x1 = this.fromX + 4;
        for (let x = x0; x <= x1; x++) {
            for (let y = this.fromY - 4; y <= this.fromY + 4; y++) {
                if (x == this.fromX && y == this.fromY) {
                    continue;
                }
                let L = Math.sqrt(<f64>((x - this.fromX) * (x - this.fromX) + (y - this.fromY) * (y - this.fromY)));
                if (L > MAXLEN + 1e-6 || !this.allowed(x, y)) {
                    continue;
                }
                let d = (<f64>x - rx) * (<f64>x - rx) + (<f64>y - ry) * (<f64>y - ry);
                if (d < bestD) {
                    bestD = d;
                    this.toX = x;
                    this.toY = y;
                    this.toOk = true;
                }
            }
        }
    }

    // the joint (anchor or built) nearest world (wx, wy) within reach of a finger
    nearestJoint(wx: f64, wy: f64, r: f64): bool {
        let g = this.gap;
        let rx = wx - GC[g], ry = wy - GB[g];
        let bestD = r * r;
        let found = false;
        for (let x = GL[g]; x <= GR[g]; x++) {
            for (let y = -5; y <= GRID_TOP + 1; y++) {
                let d = (<f64>x - rx) * (<f64>x - rx) + (<f64>y - ry) * (<f64>y - ry);
                if (d < bestD && this.isJoint(x, y)) {
                    bestD = d;
                    this.fromX = x;
                    this.fromY = y;
                    found = true;
                }
            }
        }
        return found;
    }

    // the built beam nearest world (wx, wy) (to its line, ties to its middle), or -1
    nearestBeam(wx: f64, wy: f64, r: f64): i32 {
        let g = this.gap;
        let rx = wx - GC[g], ry = wy - GB[g];
        let best = -1;
        let bestS = 1e9;
        for (let i = 0; i < this.nd; i++) {
            let ax = <f64>this.dAX[i], ay = <f64>this.dAY[i];
            let bx = <f64>this.dBX[i], by = <f64>this.dBY[i];
            let dx = bx - ax, dy = by - ay;
            let L2 = dx * dx + dy * dy;
            let t = ((rx - ax) * dx + (ry - ay) * dy) / L2;
            t = Math.max(0.0, Math.min(1.0, t));
            let px = ax + dx * t - rx, py = ay + dy * t - ry;
            let d = Math.sqrt(px * px + py * py);
            if (d > r) {
                continue;
            }
            let s = d + Math.abs(t - 0.5) * 0.35;
            if (s < bestS) {
                bestS = s;
                best = i;
            }
        }
        return best;
    }

    // which HUD button is at (x, y): 0 plank, 1 girder, 2 clear, 3 go, -1 none
    buttonAt(api: GameApi, x: f32, y: f32): i32 {
        if (y < BTN_Y - 2 || y > BTN_Y + BTN_H + 2) {
            return -1;
        }
        for (let k = 0; k < 4; k++) {
            let bx = this.btnX(api, k), bw = this.btnW(k);
            if (x >= bx - 1 && x <= bx + bw + 1) {
                return k;
            }
        }
        return -1;
    }

    btnX(api: GameApi, k: i32): f32 {
        if (k == 0) {
            return 3;
        }
        if (k == 1) {
            return 44;
        }
        if (k == 2) {
            return <f32>api.hudW - 84;
        }
        return <f32>api.hudW - 43;
    }

    btnW(k: i32): f32 {
        if (k == 0) {
            return 40;
        }
        if (k == 1) {
            return 44;
        }
        return 40;
    }

    press(api: GameApi, k: i32): void {
        if (this.state != ST_BUILD) {
            return;
        }
        if (k == 0 || k == 1) {
            if (this.kind != k) {
                this.kind = k;
                api.sound(SFX_BLIP, k == K_PLANK ? 0.9 : 1.2, 0.4);
            }
        } else if (k == 2) {
            if (this.nd > 0) {
                this.nd = 0;
                api.sound(SFX_WHOOSH, 0.8, 0.4);
                api.sound(SFX_POP, 0.6, 0.4, 0, 0.05);
            }
        } else if (k == 3) {
            if (this.nd > 0) {
                this.go(api, false);
            } else {
                api.sound(SFX_BLIP, 0.5, 0.4);
                this.flashT = 0.6;
            }
        }
    }

    // places the dragged beam (the demo uses the same path)
    place(api: GameApi): void {
        let g = this.gap;
        let r = this.addBeam(this.kind, this.fromX, this.fromY, this.toX, this.toY);
        let mx = GC[g] + <f64>(this.fromX + this.toX) * 0.5, my = GB[g] + <f64>(this.fromY + this.toY) * 0.5;
        if (r == 0) {
            this.started = true;
            if (this.kind == K_PLANK) {
                // a wooden knock
                api.soundAt(SFX_THUD, mx, my, 0, 1.6, 0.55);
                api.soundAt(SFX_TICK, mx, my, 0, 0.7, 0.5, 0.03);
            } else {
                // a steel clank
                api.soundAt(SFX_CLICK, mx, my, 0, 0.55, 0.7);
                api.noteAt(88, mx, my, 0, 0.18, SFX_BELL, 0.01);
                api.noteAt(95, mx, my, 0, 0.1, SFX_BELL, 0.02);
            }
        } else if (r == 1) {
            api.soundAt(SFX_BLIP, mx, my, 0, 0.45, 0.5);
            this.flashT = 0.6;
        } else if (r == 2) {
            api.soundAt(SFX_BLIP, mx, my, 0, 0.6, 0.4);
        }
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            this.down = true;
            this.moved = false;
            this.downHX = x;
            this.downHY = y;
            if (this.state == ST_END) {
                if (this.stateT > 1.0) {
                    api.sound(SFX_WIN, 1.0, 0.5);
                    this.newRun(api);
                }
                return true;
            }
            if (this.state == ST_FAIL && this.stateT > 0.6) {
                this.backToBuild(api);
                return true;
            }
            if (this.state != ST_BUILD) {
                return true;
            }
            let k = this.buttonAt(api, x, y);
            if (k >= 0) {
                this.press(api, k);
                this.down = false;
                return true;
            }
            if (api.pickPlane(x, y, 0, 0, 1, 0)) {
                this.downWX = <f64>api.hitX;
                this.downWY = <f64>api.hitY;
                // a generous reach for a finger: 0.95 m is ~12 art pixels
                if (this.nearestJoint(this.downWX, this.downWY, 0.95)) {
                    this.dragging = true;
                    this.toOk = false;
                }
            }
            return true;
        }
        if (kind == POINTER_MOVE) {
            if (this.down && this.dragging && this.state == ST_BUILD && api.pickPlane(x, y, 0, 0, 1, 0)) {
                let dx = x - this.downHX, dy = y - this.downHY;
                if (dx * dx + dy * dy > 9) {
                    this.moved = true;
                }
                if (this.moved) {
                    this.snapTarget(<f64>api.hitX, <f64>api.hitY);
                }
            }
            return true;
        }
        if (kind == POINTER_UP) {
            if (this.down && this.state == ST_BUILD) {
                if (api.pickPlane(x, y, 0, 0, 1, 0)) {
                    let dx = x - this.downHX, dy = y - this.downHY;
                    if (dx * dx + dy * dy > 9) {
                        this.moved = true;
                    }
                    if (this.dragging && this.moved) {
                        this.snapTarget(<f64>api.hitX, <f64>api.hitY);
                        if (this.toOk) {
                            this.place(api);
                        }
                    } else if (!this.moved) {
                        // a tap: remove the beam under it
                        let b = this.nearestBeam(this.downWX, this.downWY, 0.6);
                        if (b >= 0) {
                            let g = this.gap;
                            let mx = GC[g] + <f64>(this.dAX[b] + this.dBX[b]) * 0.5;
                            let my = GB[g] + <f64>(this.dAY[b] + this.dBY[b]) * 0.5;
                            this.removeBeam(b);
                            api.soundAt(SFX_POP, mx, my, 0, 0.75, 0.55);
                            api.soundAt(SFX_TICK, mx, my, 0, 0.5, 0.3, 0.04);
                        }
                    }
                }
            }
            this.down = false;
            this.dragging = false;
            this.toOk = false;
            return true;
        }
        return true;
    }

    // ================================================================== the demo player

    pickDemoDesign(api: GameApi): void {
        let g = this.gap;
        // the designs for this gap, one at random; sometimes a first try without the key beams
        let first = -1, n = 0;
        for (let d = 0; d < D_GAP.length; d++) {
            if (D_GAP[d] == g) {
                if (first < 0) {
                    first = d;
                }
                n++;
            }
        }
        this.dDesign = first + min<i32>(n - 1, <i32>Math.floor(api.rand() * <f64>n));
        this.dFlawed = api.rand() < 0.4;
        this.dWasFlawed = this.dFlawed;
        this.dQn = 0;
        let d = this.dDesign;
        for (let i = 0; i < D_OFF[d + 1] - D_OFF[d]; i++) {
            if (this.dFlawed && this.isKey(d, i)) {
                continue;
            }
            this.dQueue[this.dQn++] = i;
        }
        this.dQi = 0;
        this.dPhase = 0;
        this.dT = 0.35;
    }

    queueMissing(): void {
        let d = this.dDesign;
        this.dQn = 0;
        for (let i = 0; i < D_OFF[d + 1] - D_OFF[d]; i++) {
            if (this.isKey(d, i)) {
                this.dQueue[this.dQn++] = i;
            }
        }
        this.dQi = 0;
        this.dPhase = 0;
        this.dT = 0.6;
        this.dWasFlawed = false;
    }

    hudOf(api: GameApi, rx: i32, ry: i32): void {
        let g = this.gap;
        api.project(<f32>(GC[g] + <f64>rx), <f32>(GB[g] + <f64>ry), 0);
    }

    demoThink(api: GameApi, dt: f64): void {
        if (this.state != ST_BUILD || this.rollIn > 0) {
            this.curOn = false;
            return;
        }
        this.curOn = true;
        this.dT -= dt;
        let fast = this.gap == NG - 1 ? 0.6 : 1.0;      // the big truss goes quicker
        let move = (this.dPhase == 1 || this.dPhase == 3) ? 0.24 * fast : 0.26 * fast;
        let k = this.dT <= 0 ? 1.0 : Math.max(0.0, 1.0 - this.dT / move);
        k = k * k * (3.0 - 2.0 * k);
        this.curX = this.curFX + (this.curTX - this.curFX) * <f32>k;
        this.curY = this.curFY + (this.curTY - this.curFY) * <f32>k;
        if (this.dPhase == 2 && this.dragging) {
            // the hand drags: the target follows it like a pointer would
            if (api.pickPlane(this.curX, this.curY, 0, 0, 1, 0)) {
                this.snapTarget(<f64>api.hitX, <f64>api.hitY);
            }
        }
        if (this.dT > 0) {
            return;
        }
        this.curFX = this.curX;
        this.curFY = this.curY;
        if (this.dPhase == 0) {
            // think: the next beam, or GO
            this.curPress = false;
            if (this.dQi < this.dQn) {
                let o = (D_OFF[this.dDesign] + this.dQueue[this.dQi]) * 5;
                if (D_DATA[o] != this.kind) {
                    this.dBtn = D_DATA[o];
                    this.curTX = this.btnX(api, this.dBtn) + 12;
                    this.curTY = BTN_Y + 8;
                    this.dPhase = 3;
                    this.dT = 0.24 * fast;
                    return;
                }
                this.hudOf(api, D_DATA[o + 1], D_DATA[o + 2]);
                // a hand's small error (still inside the joint's reach)
                this.curTX = api.screenX + <f32>(api.rand() * 4.0 - 2.0);
                this.curTY = api.screenY + <f32>(api.rand() * 4.0 - 2.0);
                this.dPhase = 1;
                this.dT = 0.24 * fast;
            } else {
                this.dBtn = 3;
                this.curTX = this.btnX(api, 3) + 18;
                this.curTY = BTN_Y + 8;
                this.dPhase = 3;
                this.dT = 0.4;
            }
        } else if (this.dPhase == 1) {
            // press on the start joint, then drag to the end
            let o = (D_OFF[this.dDesign] + this.dQueue[this.dQi]) * 5;
            this.curPress = true;
            if (api.pickPlane(this.curX, this.curY, 0, 0, 1, 0) && this.nearestJoint(<f64>api.hitX, <f64>api.hitY, 0.95)) {
                this.dragging = true;
                this.fromX = D_DATA[o + 1];
                this.fromY = D_DATA[o + 2];
            }
            this.hudOf(api, D_DATA[o + 3], D_DATA[o + 4]);
            this.curTX = api.screenX + <f32>(api.rand() * 4.0 - 2.0);
            this.curTY = api.screenY + <f32>(api.rand() * 4.0 - 2.0);
            this.dPhase = 2;
            this.dT = 0.26 * fast;
        } else if (this.dPhase == 2) {
            // release: the beam goes in
            if (this.dragging && api.pickPlane(this.curX, this.curY, 0, 0, 1, 0)) {
                this.snapTarget(<f64>api.hitX, <f64>api.hitY);
                if (this.toOk) {
                    this.place(api);
                }
            }
            this.dragging = false;
            this.curPress = false;
            this.dQi++;
            this.dPhase = 0;
            this.dT = 0.12 * fast;
        } else if (this.dPhase == 3) {
            // tap a button
            this.curPress = true;
            this.press(api, this.dBtn);
            this.dPhase = 4;
            this.dT = 0.15;
        } else {
            this.curPress = false;
            this.dPhase = 0;
            this.dT = 0.1;
        }
    }

    // ================================================================== HUD

    stressColor(api: GameApi, s: f64): u32 {
        if (s < 0.4) {
            return api.paletteColor(P_OLIVE);
        }
        if (s < 0.65) {
            return api.paletteColor(P_KHAKI);
        }
        if (s < 0.85) {
            return api.paletteColor(P_PINK);
        }
        return api.paletteColor(P_RED);
    }

    // a little coin: the money
    coin(api: GameApi, x: f32, y: f32): void {
        let ink = api.paletteColor(P_INK);
        api.rect(x, y - 1, 5, 7, ink);
        api.rect(x - 1, y, 7, 5, ink);
        api.rect(x, y, 5, 5, api.paletteColor(P_KHAKI));
        api.rect(x + 1, y + 1, 3, 3, api.paletteColor(P_TAN));
        api.rect(x + 2, y + 1, 1, 3, api.paletteColor(P_KHAKI));
    }

    dot(api: GameApi, x: f32, y: f32, inner: u32, outer: u32): void {
        api.rect(Mathf.round(x) - 1, Mathf.round(y) - 1, 3, 3, outer);
        api.rect(Mathf.round(x), Mathf.round(y), 1, 1, inner);
    }

    button(api: GameApi, k: i32, label: string, fill: u32, text: u32, on: bool): void {
        let ink = api.paletteColor(P_INK);
        let x = this.btnX(api, k), w = this.btnW(k);
        api.rect(x - 1, BTN_Y - 1, w + 2, BTN_H + 2, ink);
        api.rect(x, BTN_Y, w, BTN_H, fill);
        if (on) {
            api.rect(x, BTN_Y + BTN_H - 2, w, 2, api.paletteColor(P_INK));
        } else {
            api.rect(x, BTN_Y, w, 1, api.paletteColor(P_CREAM));
        }
        let tw = api.textWidth(label, 1);
        api.text(Mathf.floor(x + (w - tw) * 0.5), BTN_Y + 5, label, text, 1, 0);
    }

    hud(api: GameApi): void {
        let ink = api.paletteColor(P_INK);
        let cream = api.paletteColor(P_CREAM);
        let khaki = api.paletteColor(P_KHAKI);
        let red = api.paletteColor(P_RED);
        let olive = api.paletteColor(P_OLIVE);
        let tan = api.paletteColor(P_TAN);
        let grey = api.paletteColor(P_GREY);
        let rock = api.paletteColor(P_ROCK);
        let g = this.gap;
        let W = <f32>api.hudW, H = <f32>api.hudH;

        // the bridge: joints and stress (while it is tested), or the build marks
        if (this.simOn && this.state != ST_MOVE) {
            for (let b = 0; b < this.nb; b++) {
                if (this.sGone[b] || this.sHalf[b]) {
                    continue;
                }
                let z = this.sk[b] == K_GIRDER ? <f32>GIRDER_Z : 0.0;
                if (!api.project(<f32>this.jx[this.sa[b]], <f32>this.jy[this.sa[b]], z)) {
                    continue;
                }
                let x0 = api.screenX, y0 = api.screenY;
                api.project(<f32>this.jx[this.sb[b]], <f32>this.jy[this.sb[b]], z);
                api.line(x0, y0, api.screenX, api.screenY, this.stressColor(api, this.sShow[b]));
            }
            for (let j = 0; j < this.nj; j++) {
                if (api.project(<f32>this.jx[j], <f32>this.jy[j], 0)) {
                    api.rect(Mathf.round(api.screenX), Mathf.round(api.screenY), 1, 1, ink);
                }
            }
        }
        if (this.state == ST_BUILD) {
            // anchors: steel bolts; built joints: pins; reachable grid points while dragging
            if (this.dragging) {
                for (let x = this.fromX - 4; x <= this.fromX + 4; x++) {
                    for (let y = this.fromY - 4; y <= this.fromY + 4; y++) {
                        let L = Math.sqrt(<f64>((x - this.fromX) * (x - this.fromX) + (y - this.fromY) * (y - this.fromY)));
                        if (L > MAXLEN + 1e-6 || !this.allowed(x, y)) {
                            continue;
                        }
                        this.hudOf(api, x, y);
                        api.rect(Mathf.round(api.screenX), Mathf.round(api.screenY), 1, 1, ink);
                    }
                }
            }
            for (let a = AN_OFF[g]; a < AN_OFF[g + 1]; a++) {
                this.hudOf(api, AN_X[a], AN_Y[a]);
                let blink = this.nd == 0 && Math.floor(api.time * 2.5) % 2 == 0;
                this.dot(api, api.screenX, api.screenY, blink ? red : cream, ink);
            }
            for (let i = 0; i < this.nd; i++) {
                this.hudOf(api, this.dAX[i], this.dAY[i]);
                this.dot(api, api.screenX, api.screenY, khaki, ink);
                this.hudOf(api, this.dBX[i], this.dBY[i]);
                this.dot(api, api.screenX, api.screenY, khaki, ink);
            }
            if (this.dragging && this.toOk) {
                let over = this.cost() + this.beamCost(this.kind, this.fromX, this.fromY, this.toX, this.toY) > BUDGET[g];
                let dup = this.findBeam(this.fromX, this.fromY, this.toX, this.toY) >= 0;
                let col = over || dup ? red : (this.kind == K_PLANK ? tan : grey);
                this.hudOf(api, this.fromX, this.fromY);
                let x0 = api.screenX, y0 = api.screenY;
                this.hudOf(api, this.toX, this.toY);
                let x1 = api.screenX, y1 = api.screenY;
                api.line(x0, y0 + 1, x1, y1 + 1, ink);
                api.line(x0, y0, x1, y1, col);
                api.line(x0 + 1, y0, x1 + 1, y1, col);
                this.dot(api, x1, y1, col, ink);
                let c = this.beamCost(this.kind, this.fromX, this.fromY, this.toX, this.toY).toString();
                this.coin(api, Mathf.round(x1 + 4), Mathf.round(y1 - 8));
                api.text(Mathf.round(x1 + 11), Mathf.round(y1 - 8), c, over ? red : cream, 1, ink);
            }
        }

        // top: the gap, the budget
        let title = (g + 1).toString() + "/5 " + GNAME[g];
        api.text(3, 3, title, cream, 1, ink);
        if (this.state == ST_BUILD || this.state == ST_RUN || this.state == ST_FAIL || this.state == ST_HELD) {
            let c = this.cost();
            let s = c.toString() + "/" + BUDGET[g].toString();
            let blink = this.flashT > 0 && Math.floor(api.time * 10.0) % 2 == 0;
            let frac = <f64>c / <f64>BUDGET[g];
            let col = blink ? red : (frac <= 0.8 ? cream : (frac <= 0.9 ? khaki : api.paletteColor(P_PINK)));
            api.text(W - 3 - api.textWidth(s, 1), 3, s, col, 1, ink);
            this.coin(api, W - 10 - api.textWidth(s, 1), 3);
            // the stars this cost would earn
            let st = frac <= 0.8 ? 3 : (frac <= 0.9 ? 2 : 1);
            if (this.state == ST_BUILD && this.nd > 0) {
                let ss = st == 3 ? "***" : (st == 2 ? "**" : "*");
                api.text(W - 3 - api.textWidth(ss, 1), 10, ss, khaki, 1, ink);
            }
        }
        // the run so far: a pip per gap
        for (let k = 0; k < NG; k++) {
            let x = 3 + <f32>k * 6;
            api.rect(x, 10, 5, 3, ink);
            api.rect(x + 1, 11, 3, 1, k < g || this.state == ST_END ? olive : (k == g ? khaki : rock));
        }

        if (this.state == ST_BUILD) {
            if (this.nd == 0 && !api.demo) {
                api.textCentered(18, "DRAG FROM A BOLT TO PLACE A BEAM", cream, 1, ink);
                api.textCentered(25, "PLANKS ARE ROAD - GIRDERS ARE STRONG", khaki, 1, ink);
                api.textCentered(32, "TAP A BEAM TO REMOVE IT", khaki, 1, ink);
            }
            this.button(api, 0, "PLANK", this.kind == K_PLANK ? tan : rock, this.kind == K_PLANK ? ink : khaki, this.kind == K_PLANK);
            this.button(api, 1, "GIRDER", this.kind == K_GIRDER ? grey : rock, this.kind == K_GIRDER ? ink : khaki, this.kind == K_GIRDER);
            this.button(api, 2, "CLEAR", api.paletteColor(P_MAUVE), cream, false);
            this.button(api, 3, "GO!", red, cream, false);
        } else if (this.state == ST_RUN) {
            let s = this.maxStress;
            api.textCentered(18, "TESTING...", cream, 1, ink);
            // the peak stress so far
            let bw: f32 = 60;
            let bx = Mathf.floor((W - bw) * 0.5);
            api.rect(bx - 1, 25, bw + 2, 4, ink);
            api.rect(bx, 26, <f32>Math.min(1.0, s) * bw, 2, this.stressColor(api, s));
        } else if (this.state == ST_HELD) {
            api.textCentered(20, "IT HOLDS!", cream, 2, ink);
            let ss = this.lastStars == 3 ? "* * *" : (this.lastStars == 2 ? "* *" : "*");
            api.textCentered(34, ss, khaki, 2, ink);
            api.textCentered(48, "COST " + this.lastCost.toString() + " OF " + BUDGET[g].toString(), cream, 1, ink);
        } else if (this.state == ST_FAIL) {
            api.textCentered(20, this.msg, red, 2, ink);
            api.textCentered(34, this.snaps > 0 ? "A BEAM SNAPPED - FIX IT AND GO AGAIN" : "THE ROAD RAN OUT - FIX IT", cream, 1, ink);
        } else if (this.state == ST_END) {
            let pw: f32 = 132, ph: f32 = 58;
            let px = Mathf.floor((W - pw) * 0.5), py = Mathf.floor(H * 0.5 - 40);
            api.rect(px - 1, py - 1, pw + 2, ph + 2, ink);
            api.rect(px, py, pw, ph, api.paletteColor(P_BROWN));
            api.rect(px, py, pw, 1, tan);
            api.textCentered(py + 5, "VALLEY CROSSED!", cream, 2, ink);
            api.textCentered(py + 20, "COST " + this.total.toString() + "   STARS " + this.stars.toString() + "/15", cream, 1, ink);
            api.textCentered(py + 29, "TRIES " + this.tries.toString() + "   BEST " + this.best.toString(), this.newBest ? khaki : grey, 1, ink);
            if (this.newBest) {
                api.textCentered(py + 38, "NEW BEST!", khaki, 1, ink);
            }
            if (this.stateT > 1.0 && !api.demo) {
                let blink = Math.floor(api.time * 2.0) % 2 == 0;
                api.textCentered(py + 48, "CLICK TO PLAY AGAIN", blink ? cream : khaki, 1, ink);
            }
        }
        if (this.state == ST_MOVE) {
            let next = g + 1 < NG ? GNAME[g + 1] : "THE DEPOT";
            api.textCentered(20, "ON TO " + next, cream, 1, ink);
        }
        // the demo's hand
        if (api.demo && this.curOn) {
            let x = Mathf.round(this.curX), y = Mathf.round(this.curY);
            let c = this.curPress ? khaki : cream;
            api.rect(x, y, 1, 7, ink);
            api.rect(x + 1, y + 1, 1, 5, c);
            api.rect(x + 1, y, 1, 1, ink);
            api.rect(x + 2, y + 2, 1, 4, c);
            api.rect(x + 2, y + 1, 1, 1, ink);
            api.rect(x + 3, y + 3, 1, 3, c);
            api.rect(x + 3, y + 2, 1, 1, ink);
            api.rect(x + 4, y + 3, 1, 1, ink);
            api.rect(x + 4, y + 4, 1, 1, c);
            api.rect(x + 5, y + 4, 1, 1, ink);
            api.rect(x + 1, y + 6, 4, 1, ink);
            api.rect(x + 2, y + 7, 1, 1, ink);
        }
    }
}
