// Border War: a small real-time strategy game. The human kingdom (you, bottom left) against the orc
// warband (the computer, top right) across a river with two fords. Workers gather gold and wood
// and carry it home; the Manor trains yeomen, the Drill Yard swordsmen and archers; build
// cottages for supply and watchtowers that shoot. Destroy the Warcamp to win; lose the Manor and
// the run is lost. Pointer (or touch) only: tap to select, drag a box to select several, tap the
// ground to move, a resource to gather, an enemy to attack; HUD buttons build and train.
// One world, one run: the result shows the score and the best; the next tap starts a new match.
import {
    GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP,
    SFX_BLIP, SFX_COIN, SFX_HIT, SFX_EXPLODE, SFX_SHOOT, SFX_THUD, SFX_WHOOSH, SFX_NOTE, SFX_BELL,
    SFX_LOSE, SFX_WIN, SFX_TICK, SFX_CLICK, SFX_ZAP
} from "./game_api";

// ---------------------------------------------------------------- LAYOUT (models/layout.py)
const HALL_X: StaticArray<f64> = [-6.6, 6.6];
const HALL_Z: StaticArray<f64> = [4.6, -4.6];
const RES_X: StaticArray<f64> = [-3.6, -1.9, -0.2, 3.6, 1.9, 0.2, -8.3, 8.3];   // 6 groves, 2 gold deposits
const RES_Z: StaticArray<f64> = [6.4, 6.6, 6.3, -6.4, -6.6, -6.3, 1.4, -1.4];
const RIVER: StaticArray<f64> = [-11.0, -9.0, -7.5, -6.2, -4.4, -3.3, -1.6, -1.4, 0.0, 0.0, 1.6, 1.4, 4.4, 3.3,
    7.5, 6.2, 11.0, 9.0];
const FORD_X: StaticArray<f64> = [-4.4, 4.4];
const FORD_Z: StaticArray<f64> = [-3.3, 3.3];
const TREES: StaticArray<f64> = [-7.66, -8.41, -6.49, -7.35, -8.69, -4.81, -5.36, -6.64, -7.61, -4.20, -0.33, -2.79,
    0.99, -1.13, 0.57, 2.84, 7.80, 3.83, 5.35, 6.51, 8.76, 4.68, -6.47, -8.38, -5.34, -8.11, -4.04, -8.12, -2.87, -8.39,
    -1.42, -8.17, 0.11, -8.07, 1.25, -8.62, 2.92, -8.58, 4.15, -8.25, 5.43, -8.27, 6.58, -8.40, 8.26, -8.58, 9.69, -8.34];
// building spots for the computer (and the demo's human): yard, tower0, tower1, farm0, farm1 (human side)
const SPOT_X: StaticArray<f64> = [-4.3, -4.0, -1.4, -8.2, -5.6];
const SPOT_Z: StaticArray<f64> = [2.7, -0.6, 2.6, 6.1, 6.3];
const RALLY_X: StaticArray<f64> = [-4.9, 4.9];
const RALLY_Z: StaticArray<f64> = [0.9, -0.9];
const PX0: f64 = -9.3;
const PX1: f64 = 9.3;
const PZ0: f64 = -7.0;
const PZ1: f64 = 7.2;

// ---------------------------------------------------------------- kinds and stats
const K_HALL: i32 = 0;
const K_BARR: i32 = 1;
const K_TOWER: i32 = 2;
const K_FARM: i32 = 3;
const K_WORKER: i32 = 4;
const K_MELEE: i32 = 5;
const K_RANGED: i32 = 6;
// per team * 7 + kind
const HP: StaticArray<f64> = [800, 600, 300, 280, 30, 65, 38, 800, 620, 300, 280, 32, 75, 40];
const DMG: StaticArray<f64> = [0, 0, 7, 0, 3, 8, 6, 0, 0, 7, 0, 3, 9, 7];
const CD: StaticArray<f64> = [0, 0, 1.5, 0, 1.2, 1.0, 1.4, 0, 0, 1.6, 0, 1.2, 1.15, 1.6];
const RNG: StaticArray<f64> = [0, 0, 4.4, 0, 0.35, 0.4, 3.4, 0, 0, 4.2, 0, 0.35, 0.45, 3.1];
const SPD: StaticArray<f64> = [0, 0, 0, 0, 1.55, 1.35, 1.4, 0, 0, 0, 0, 1.5, 1.3, 1.35];
const RAD: StaticArray<f64> = [1.25, 1.2, 0.55, 0.72, 0.26, 0.28, 0.26, 1.3, 1.12, 0.6, 0.68, 0.27, 0.32, 0.27];
const HGT: StaticArray<f64> = [2.44, 1.73, 3.15, 1.25, 0.98, 1.04, 0.98, 2.45, 2.68, 2.94, 1.49, 0.86, 1.18, 1.0];
const COST_G: StaticArray<i32> = [0, 120, 90, 50, 50, 70, 55, 0, 120, 90, 50, 50, 70, 55];
const COST_W: StaticArray<i32> = [0, 80, 60, 40, 0, 0, 25, 0, 80, 60, 40, 0, 0, 25];
const TIME: StaticArray<f64> = [0, 20, 16, 10, 7, 9, 9, 0, 20, 16, 10, 7, 9, 9];
const NAMES: StaticArray<string> = ["MANOR", "DRILL YARD", "WATCHTOWER", "COTTAGE", "YEOMAN", "SWORDSMAN", "ARCHER",
    "WARCAMP", "WAR PIT", "LOOKOUT", "TENT", "DRUDGE", "BRUTE", "THROWER"];
const SHORT: StaticArray<string> = ["MANOR", "YARD", "TOWER", "COTTAGE", "YEOMAN", "SWORD", "ARCHER",
    "WARCAMP", "PIT", "LOOKOUT", "TENT", "DRUDGE", "BRUTE", "THROWER"];
const BONES: StaticArray<string> = ["manor", "yard", "htower0", "htower1", "cottage0", "cottage1",
    "yeoman0", "yeoman1", "yeoman2", "yeoman3", "yeoman4", "sword0", "sword1", "sword2", "sword3", "sword4",
    "archer0", "archer1", "archer2", "archer3",
    "warcamp", "pit", "lookout0", "lookout1", "tent0", "tent1",
    "drudge0", "drudge1", "drudge2", "drudge3", "drudge4", "brute0", "brute1", "brute2", "brute3", "brute4",
    "thrower0", "thrower1", "thrower2", "thrower3"];
// slot layout per team (20 slots): 0 hall, 1 barracks, 2-3 towers, 4-5 farms, 6-10 workers, 11-15 melee, 16-19 ranged
const SLOT_KIND: StaticArray<i32> = [0, 1, 2, 2, 3, 3, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6, 6];
const NE: i32 = 40;
// TRACE true prints the match every 30 s and, in play mode, a state line every 20 frames for
// tools/bot.py (the closed-loop test player); false in the shipped game
const TRACE: bool = false;
const MAXP: i32 = 24;
const B_YAW: StaticArray<f64> = [35, -35];
const SUPPLY_HALL: i32 = 5;
const SUPPLY_FARM: i32 = 4;
const GROVE_WOOD: f64 = 260;
const LOAD: f64 = 8;

// unit states
const S_IDLE: i32 = 0;
const S_MOVE: i32 = 1;
const S_AMOVE: i32 = 2;
const S_ATTACK: i32 = 3;
const S_GATHER: i32 = 4;
const S_BUILD: i32 = 5;

// the pathing grid
const GW: i32 = 48;
const GH: i32 = 38;
const CS: f64 = 0.4;
const GX0: f64 = -9.6;
const GZ0: f64 = -7.6;
const NC: i32 = GW * GH;

// the HUD (320 x 200 HUD pixels at pixelSize 2)
const PANEL_Y: f32 = 172;
const BTN_X: f32 = 122;
const BTN_W: f32 = 38;
const BTN_H: f32 = 24;

// game modes
const M_NONE: i32 = 0;
const M_PLACE: i32 = 1;
const M_ATTACK: i32 = 2;

// ramps (art/palette.json order)
const R_GRASS: i32 = 0;
const R_DIRT: i32 = 2;
const R_STONE: i32 = 4;
const R_CREAM: i32 = 5;
const R_ROYAL: i32 = 6;
const R_CRIMSON: i32 = 7;
const R_STEEL: i32 = 10;
const R_GOLD: i32 = 11;
const R_GLOW: i32 = 13;

export class Game {
    // ---- entities (unit and building slots; a slot's kind, team and bone are fixed)
    kind: StaticArray<i32> = new StaticArray<i32>(NE);
    team: StaticArray<i32> = new StaticArray<i32>(NE);
    bone: StaticArray<i32> = new StaticArray<i32>(NE);
    alive: StaticArray<bool> = new StaticArray<bool>(NE);
    hp: StaticArray<f64> = new StaticArray<f64>(NE);
    ex: StaticArray<f64> = new StaticArray<f64>(NE);
    ez: StaticArray<f64> = new StaticArray<f64>(NE);
    yaw: StaticArray<f64> = new StaticArray<f64>(NE);
    vx: StaticArray<f64> = new StaticArray<f64>(NE);
    vz: StaticArray<f64> = new StaticArray<f64>(NE);
    state: StaticArray<i32> = new StaticArray<i32>(NE);
    tgt: StaticArray<i32> = new StaticArray<i32>(NE);
    gx: StaticArray<f64> = new StaticArray<f64>(NE);      // the goal of a move / attack-move
    gz: StaticArray<f64> = new StaticArray<f64>(NE);
    g2x: StaticArray<f64> = new StaticArray<f64>(NE);     // the next goal (a wave: the ford, then the hall)
    g2z: StaticArray<f64> = new StaticArray<f64>(NE);
    hasG2: StaticArray<bool> = new StaticArray<bool>(NE);
    wave: StaticArray<bool> = new StaticArray<bool>(NE);
    amv: StaticArray<bool> = new StaticArray<bool>(NE);     // attack-moving: fights what it meets, then goes on
    leash: StaticArray<f64> = new StaticArray<f64>(NE);     // > 0: a chase gives up this far from home
    homeX: StaticArray<f64> = new StaticArray<f64>(NE);
    homeZ: StaticArray<f64> = new StaticArray<f64>(NE);
    cd: StaticArray<f64> = new StaticArray<f64>(NE);
    swing: StaticArray<f64> = new StaticArray<f64>(NE);   // attack / tool animation, counts down
    hurt: StaticArray<f64> = new StaticArray<f64>(NE);    // hit recoil, counts down
    walk: StaticArray<f64> = new StaticArray<f64>(NE);
    deadT: StaticArray<f64> = new StaticArray<f64>(NE);
    scanT: StaticArray<f64> = new StaticArray<f64>(NE);
    res: StaticArray<i32> = new StaticArray<i32>(NE);     // a worker's resource
    phase: StaticArray<i32> = new StaticArray<i32>(NE);   // gather: 0 to it, 1 working, 2 home
    workT: StaticArray<f64> = new StaticArray<f64>(NE);
    cargo: StaticArray<i32> = new StaticArray<i32>(NE);   // 0 none, 1 gold, 2 wood
    cargoAmt: StaticArray<f64> = new StaticArray<f64>(NE);
    carryB: StaticArray<i32> = new StaticArray<i32>(NE);  // the carried load's pool slot (0-2 sacks, 3-5 logs)
    buildT: StaticArray<i32> = new StaticArray<i32>(NE);  // a worker's building site
    prog: StaticArray<f64> = new StaticArray<f64>(NE);    // a building's construction (1 = done)
    scaf: StaticArray<i32> = new StaticArray<i32>(NE);    // its scaffold's pool slot
    popT: StaticArray<f64> = new StaticArray<f64>(NE);
    queue: StaticArray<i32> = new StaticArray<i32>(NE * 5);
    qLen: StaticArray<i32> = new StaticArray<i32>(NE);
    trainT: StaticArray<f64> = new StaticArray<f64>(NE);
    knockT: StaticArray<f64> = new StaticArray<f64>(NE);
    // paths
    pathX: StaticArray<f64> = new StaticArray<f64>(NE * MAXP);
    pathZ: StaticArray<f64> = new StaticArray<f64>(NE * MAXP);
    pathLen: StaticArray<i32> = new StaticArray<i32>(NE);
    pathI: StaticArray<i32> = new StaticArray<i32>(NE);
    pgx: StaticArray<f64> = new StaticArray<f64>(NE);     // the goal the path was made for
    pgz: StaticArray<f64> = new StaticArray<f64>(NE);
    losT: StaticArray<f64> = new StaticArray<f64>(NE);
    pathT: StaticArray<f64> = new StaticArray<f64>(NE);    // a fresh search waits this long (spreads the work)
    losOk: StaticArray<bool> = new StaticArray<bool>(NE);
    stuckT: StaticArray<f64> = new StaticArray<f64>(NE);
    lastX: StaticArray<f64> = new StaticArray<f64>(NE);
    lastZ: StaticArray<f64> = new StaticArray<f64>(NE);

    // ---- resources: 6 groves (game bones) and 2 gold deposits
    resAmt: StaticArray<f64> = new StaticArray<f64>(8);
    groveB: StaticArray<i32> = new StaticArray<i32>(6);
    groveFall: StaticArray<f64> = new StaticArray<f64>(6);

    // ---- pools: carried loads, projectiles, scaffolds
    carryBone: StaticArray<i32> = new StaticArray<i32>(6);
    carryOwner: StaticArray<i32> = new StaticArray<i32>(6);
    projBone: StaticArray<i32> = new StaticArray<i32>(8);   // 0-3 arrows (humans), 4-7 spears (orcs)
    projOn: StaticArray<bool> = new StaticArray<bool>(8);
    projT: StaticArray<f64> = new StaticArray<f64>(8);
    projDur: StaticArray<f64> = new StaticArray<f64>(8);
    projX0: StaticArray<f64> = new StaticArray<f64>(8);
    projY0: StaticArray<f64> = new StaticArray<f64>(8);
    projZ0: StaticArray<f64> = new StaticArray<f64>(8);
    projTgt: StaticArray<i32> = new StaticArray<i32>(8);
    projDmg: StaticArray<f64> = new StaticArray<f64>(8);
    projSrc: StaticArray<i32> = new StaticArray<i32>(8);
    scafBone: StaticArray<i32> = new StaticArray<i32>(3);
    scafOwner: StaticArray<i32> = new StaticArray<i32>(3);

    // ---- teams
    gold: StaticArray<f64> = new StaticArray<f64>(2);
    wood: StaticArray<f64> = new StaticArray<f64>(2);
    gotGold: StaticArray<f64> = new StaticArray<f64>(2);
    gotWood: StaticArray<f64> = new StaticArray<f64>(2);
    lost: StaticArray<i32> = new StaticArray<i32>(2);
    killed: StaticArray<i32> = new StaticArray<i32>(2);
    trained: StaticArray<i32> = new StaticArray<i32>(2);
    underAttackT: StaticArray<f64> = new StaticArray<f64>(2);

    // ---- AI (index: team; the orcs always, the humans in demo mode)
    aiT: StaticArray<f64> = new StaticArray<f64>(2);
    waveN: StaticArray<i32> = new StaticArray<i32>(2);
    waveSize: StaticArray<i32> = new StaticArray<i32>(2);
    nextWave: StaticArray<f64> = new StaticArray<f64>(2);
    pattern: StaticArray<i32> = new StaticArray<i32>(2);
    waveGo: StaticArray<f64> = new StaticArray<f64>(2);   // a wave regroups at its ford until then

    // ---- the pathing grid
    sblk: StaticArray<u8> = new StaticArray<u8>(NC);    // static: water, woods, deposits, the map's edge
    blk: StaticArray<u8> = new StaticArray<u8>(NC);     // + buildings and groves
    gridDirty: bool = true;
    gScore: StaticArray<i32> = new StaticArray<i32>(NC);
    parent: StaticArray<i32> = new StaticArray<i32>(NC);
    stamp: StaticArray<i32> = new StaticArray<i32>(NC);
    closed: StaticArray<i32> = new StaticArray<i32>(NC);
    heapF: StaticArray<i32> = new StaticArray<i32>(NC * 8);
    heapC: StaticArray<i32> = new StaticArray<i32>(NC * 8);
    heapN: i32 = 0;
    searchId: i32 = 0;
    pathBudget: i32 = 0;
    tmpPath: StaticArray<i32> = new StaticArray<i32>(NC);

    // ---- the match
    playing: bool = true;
    over: bool = false;
    won: bool = false;
    overAt: f64 = 0;
    mt: f64 = 0;               // match time
    score: i32 = 0;
    best: i32 = 0;
    newBest: bool = false;
    wasDemo: bool = false;
    demoMode: bool = false;

    // ---- the player's hand
    sel: StaticArray<bool> = new StaticArray<bool>(NE);
    selB: i32 = -1;            // a selected building (own or enemy) or an enemy unit, for its panel
    selRes: i32 = -1;
    mode: i32 = M_NONE;
    placeKind: i32 = 0;
    ghostX: f64 = 0;
    ghostZ: f64 = 0;
    ghostOn: bool = false;
    ghostOk: bool = false;
    isDown: bool = false;
    dragging: bool = false;
    downX: f32 = 0;
    downY: f32 = 0;
    curX: f32 = 0;
    curY: f32 = 0;
    downOnPanel: bool = false;
    msg: string = "";
    msgT: f64 = 0;
    markX: f64 = 0;
    markZ: f64 = 0;
    markT: f64 = 9;
    markAtk: bool = false;

    // ---- effects (HUD): sparks, dust, popups
    fxX: StaticArray<f64> = new StaticArray<f64>(32);
    fxY: StaticArray<f64> = new StaticArray<f64>(32);
    fxZ: StaticArray<f64> = new StaticArray<f64>(32);
    fxAge: StaticArray<f64> = new StaticArray<f64>(32);
    fxKind: StaticArray<i32> = new StaticArray<i32>(32);    // 0 spark, 1 dust, 2 +gold, 3 +wood
    fxN: i32 = 0;

    // ---- sound rate limits (frames)
    lastChop: i32 = -100;
    lastShot: i32 = -100;
    lastHit: i32 = -100;
    lastKnock: i32 = -100;
    lastDeath: i32 = -100;

    // ================================================================ setup

    start(api: GameApi): void {
        api.playable = true;
        for (let e = 0; e < NE; e++) {
            this.team[e] = e < 20 ? 0 : 1;
            this.kind[e] = SLOT_KIND[e % 20];
            this.bone[e] = api.bone(BONES[e]);
        }
        for (let g = 0; g < 6; g++) {
            this.groveB[g] = api.bone("grove" + g.toString());
        }
        for (let k = 0; k < 3; k++) {
            this.carryBone[k] = api.bone("sack" + k.toString());
            this.carryBone[3 + k] = api.bone("logs" + k.toString());
            this.scafBone[k] = api.bone("scaf" + k.toString());
        }
        for (let k = 0; k < 4; k++) {
            this.projBone[k] = api.bone("arrow" + k.toString());
            this.projBone[4 + k] = api.bone("spear" + k.toString());
        }
        this.staticGrid();
        this.wasDemo = api.demo;
        this.reset(api);
    }

    // a fresh match on the same map
    reset(api: GameApi): void {
        for (let e = 0; e < NE; e++) {
            this.alive[e] = false;
            this.deadT[e] = 0;
            this.sel[e] = false;
            this.carryB[e] = -1;
            this.scaf[e] = -1;
            this.qLen[e] = 0;
            this.pathLen[e] = 0;
            api.hide(this.bone[e]);
        }
        for (let k = 0; k < 6; k++) {
            this.carryOwner[k] = -1;
            api.hide(this.carryBone[k]);
        }
        for (let k = 0; k < 3; k++) {
            this.scafOwner[k] = -1;
            api.hide(this.scafBone[k]);
        }
        for (let k = 0; k < 8; k++) {
            this.projOn[k] = false;
            api.hide(this.projBone[k]);
        }
        for (let r = 0; r < 8; r++) {
            this.resAmt[r] = r < 6 ? GROVE_WOOD : 12000;
        }
        for (let g = 0; g < 6; g++) {
            this.groveFall[g] = 0;
        }
        for (let t = 0; t < 2; t++) {
            this.gold[t] = 150;
            this.wood[t] = 60;
            this.gotGold[t] = 0;
            this.gotWood[t] = 0;
            this.lost[t] = 0;
            this.killed[t] = 0;
            this.trained[t] = 0;
            this.underAttackT[t] = -99;
            this.aiT[t] = 0.3 * <f64>t;
            this.waveN[t] = 0;
            this.waveSize[t] = 3;
            this.pattern[t] = 0;
        }
        // the first waves: the warband's at 2:30 against a player; in the demo both sides build up a
        // little longer (two waves crossing at once would race each other to the halls)
        this.nextWave[0] = 175 + api.range(0, 20);
        this.nextWave[1] = api.demo ? 190 + api.range(0, 20) : 150 + api.range(0, 15);
        this.fxN = 0;
        for (let i = 0; i < 32; i++) {
            this.fxAge[i] = 99;
        }
        this.selB = -1;
        this.selRes = -1;
        this.mode = M_NONE;
        this.ghostOn = false;
        this.msg = "";
        this.markT = 9;
        this.over = false;
        this.won = false;
        this.mt = 0;
        this.score = 0;
        this.newBest = false;
        // the halls and the starting crews: three workers already at work, one soldier at home
        for (let t = 0; t < 2; t++) {
            this.placeBuilding(t, K_HALL, HALL_X[t], HALL_Z[t], true);
            let sgn = t == 0 ? 1.0 : -1.0;
            // two on gold (one already carrying home), one on wood
            let w0 = this.spawn(api, t, K_WORKER, RES_X[6 + t] + 0.9 * sgn, RES_Z[6 + t] + 1.0 * sgn);
            this.orderGather(w0, 6 + t);
            let w1 = this.spawn(api, t, K_WORKER, HALL_X[t] - 0.5 * sgn, HALL_Z[t] - 1.7 * sgn);
            this.orderGather(w1, 6 + t);
            this.cargo[w1] = 1;
            this.cargoAmt[w1] = LOAD;
            this.phase[w1] = 2;
            let w2 = this.spawn(api, t, K_WORKER, HALL_X[t] + 2.2 * sgn, HALL_Z[t] + 1.2 * sgn);
            this.orderGather(w2, 3 * t);
            this.spawn(api, t, K_MELEE, HALL_X[t] + 1.9 * sgn, HALL_Z[t] - 0.8 * sgn);
        }
        if (api.demo) {
            // the demo opens with a skirmish at the west ford
            for (let t = 0; t < 2; t++) {
                let sgn = t == 0 ? 1.0 : -1.0;
                let fx = FORD_X[0], fz = FORD_Z[0];
                let bx = fx + (t == 0 ? -1.2 : 1.6), bz = fz + (t == 0 ? 2.3 : -2.0);
                let a = this.spawn(api, t, K_MELEE, bx, bz);
                let b = this.spawn(api, t, K_MELEE, bx + 0.6 * sgn, bz + 0.4 * sgn);
                let c = this.spawn(api, t, K_RANGED, bx - 0.4 * sgn, bz + 0.9 * sgn);
                let ok = 0;
                for (let k = 0; k < 3; k++) {
                    let u = k == 0 ? a : (k == 1 ? b : c);
                    if (u < 0) {
                        continue;
                    }
                    ok++;
                    // to the ford and, whoever is left standing, back to its own rally point
                    this.orderAMove(u, fx - 0.2 * sgn, fz + 0.1 * sgn);
                    this.hasG2[u] = true;
                    this.g2x[u] = RALLY_X[t];
                    this.g2z[u] = RALLY_Z[t];
                }
            }
        }
        this.gridDirty = true;
    }

    // ================================================================ the grid

    cellOf(x: f64, z: f64): i32 {
        let i = <i32>Math.floor((x - GX0) / CS);
        let j = <i32>Math.floor((z - GZ0) / CS);
        if (i < 0 || j < 0 || i >= GW || j >= GH) {
            return -1;
        }
        return j * GW + i;
    }

    cx(c: i32): f64 {
        return GX0 + (<f64>(c % GW) + 0.5) * CS;
    }

    cz(c: i32): f64 {
        return GZ0 + (<f64>(c / GW) + 0.5) * CS;
    }

    staticGrid(): void {
        for (let c = 0; c < NC; c++) {
            let x = this.cx(c), z = this.cz(c);
            let b: u8 = 0;
            if (x < PX0 || x > PX1 || z < PZ0 || z > PZ1) {
                b = 1;
            }
            if (riverDist(x, z) < 0.82 && fordDist(x, z) > 1.0) {
                b = 1;
            }
            for (let k = 0; k < TREES.length; k += 2) {
                let dx = x - TREES[k], dz = z - TREES[k + 1];
                if (dx * dx + dz * dz < 0.62 * 0.62) {
                    b = 1;
                }
            }
            for (let r = 6; r < 8; r++) {
                let dx = x - RES_X[r], dz = z - RES_Z[r];
                if (dx * dx + dz * dz < 1.15 * 1.15) {
                    b = 1;
                }
            }
            this.sblk[c] = b;
        }
    }

    rebuildGrid(): void {
        for (let c = 0; c < NC; c++) {
            this.blk[c] = this.sblk[c];
        }
        for (let g = 0; g < 6; g++) {
            if (this.resAmt[g] > 0) {
                this.stamp_(RES_X[g], RES_Z[g], 0.95);
            }
        }
        for (let e = 0; e < NE; e++) {
            if (this.alive[e] && this.kind[e] <= K_FARM) {
                this.stamp_(this.ex[e], this.ez[e], RAD[this.st(e)] + 0.12);
            }
        }
        this.gridDirty = false;
    }

    stamp_(x: f64, z: f64, r: f64): void {
        let i0 = <i32>Math.floor((x - r - GX0) / CS), i1 = <i32>Math.floor((x + r - GX0) / CS);
        let j0 = <i32>Math.floor((z - r - GZ0) / CS), j1 = <i32>Math.floor((z + r - GZ0) / CS);
        for (let j = max<i32>(0, j0); j <= min<i32>(GH - 1, j1); j++) {
            for (let i = max<i32>(0, i0); i <= min<i32>(GW - 1, i1); i++) {
                let c = j * GW + i;
                let dx = this.cx(c) - x, dz = this.cz(c) - z;
                if (dx * dx + dz * dz < r * r) {
                    this.blk[c] = 1;
                }
            }
        }
    }

    blocked(x: f64, z: f64): bool {
        let c = this.cellOf(x, z);
        return c < 0 || this.blk[c] != 0;
    }

    // a clear straight walk between two points (sampled along the line, a little either side)
    los(x0: f64, z0: f64, x1: f64, z1: f64): bool {
        let dx = x1 - x0, dz = z1 - z0;
        let d = Math.sqrt(dx * dx + dz * dz);
        if (d < 0.01) {
            return true;
        }
        let nx = -dz / d * 0.16, nz = dx / d * 0.16;
        let n = <i32>Math.ceil(d / 0.18);
        for (let k = 1; k <= n; k++) {
            let t = <f64>k / <f64>n;
            let x = x0 + dx * t, z = z0 + dz * t;
            if (this.blocked(x, z) || this.blocked(x + nx, z + nz) || this.blocked(x - nx, z - nz)) {
                return false;
            }
        }
        return true;
    }

    heapPush(f: i32, c: i32): void {
        let i = this.heapN++;
        this.heapF[i] = f;
        this.heapC[i] = c;
        while (i > 0) {
            let p = (i - 1) >> 1;
            if (this.heapF[p] <= this.heapF[i]) {
                break;
            }
            let tf = this.heapF[p], tc = this.heapC[p];
            this.heapF[p] = this.heapF[i]; this.heapC[p] = this.heapC[i];
            this.heapF[i] = tf; this.heapC[i] = tc;
            i = p;
        }
    }

    heapPop(): i32 {
        let top = this.heapC[0];
        this.heapN--;
        if (this.heapN > 0) {
            this.heapF[0] = this.heapF[this.heapN];
            this.heapC[0] = this.heapC[this.heapN];
            let i = 0;
            while (true) {
                let l = i * 2 + 1, r = l + 1, m = i;
                if (l < this.heapN && this.heapF[l] < this.heapF[m]) { m = l; }
                if (r < this.heapN && this.heapF[r] < this.heapF[m]) { m = r; }
                if (m == i) {
                    break;
                }
                let tf = this.heapF[m], tc = this.heapC[m];
                this.heapF[m] = this.heapF[i]; this.heapC[m] = this.heapC[i];
                this.heapF[i] = tf; this.heapC[i] = tc;
                i = m;
            }
        }
        return top;
    }

    // A* from the unit to within stopR of (x, z); writes the unit's waypoints (string-pulled).
    // An unreachable goal ends at the reachable cell nearest to it.
    findPath(e: i32, x: f64, z: f64, stopR: f64): void {
        this.pathLen[e] = 0;
        this.pathI[e] = 0;
        this.pgx[e] = x;
        this.pgz[e] = z;
        let s = this.cellOf(this.ex[e], this.ez[e]);
        if (s < 0) {
            return;
        }
        this.searchId++;
        let sid = this.searchId;
        this.heapN = 0;
        let gi = (x - GX0) / CS - 0.5, gj = (z - GZ0) / CS - 0.5;
        let stopC = stopR / CS;
        this.stamp[s] = sid;
        this.gScore[s] = 0;
        this.parent[s] = -1;
        this.heapPush(0, s);
        let bestC = s;
        let bestH = 1e9;
        let found = -1;
        let pops = 0;
        while (this.heapN > 0 && pops < NC) {
            let c = this.heapPop();
            if (this.closed[c] == sid) {
                continue;
            }
            this.closed[c] = sid;
            pops++;
            let ci = c % GW, cj = c / GW;
            let dx = Math.abs(<f64>ci - gi), dz = Math.abs(<f64>cj - gj);
            let dist = Math.sqrt(dx * dx + dz * dz);
            if (dist <= stopC + 0.35) {
                found = c;
                break;
            }
            if (dist < bestH) {
                bestH = dist;
                bestC = c;
            }
            for (let k = 0; k < 8; k++) {
                let oi = k == 0 ? 1 : (k == 1 ? -1 : (k == 2 ? 0 : (k == 3 ? 0 : (k == 4 || k == 5 ? 1 : -1))));
                let oj = k == 0 ? 0 : (k == 1 ? 0 : (k == 2 ? 1 : (k == 3 ? -1 : (k == 4 || k == 6 ? 1 : -1))));
                let ni = ci + oi, nj = cj + oj;
                if (ni < 0 || nj < 0 || ni >= GW || nj >= GH) {
                    continue;
                }
                let n = nj * GW + ni;
                if (this.blk[n] != 0 || this.closed[n] == sid) {
                    continue;
                }
                if (k >= 4 && (this.blk[cj * GW + ni] != 0 || this.blk[nj * GW + ci] != 0)) {
                    continue; // no corner cutting
                }
                let ng = this.gScore[c] + (k >= 4 ? 14 : 10);
                if (this.stamp[n] != sid || ng < this.gScore[n]) {
                    this.stamp[n] = sid;
                    this.gScore[n] = ng;
                    this.parent[n] = c;
                    let hx = Math.abs(<f64>ni - gi), hz = Math.abs(<f64>nj - gj);
                    let h = Math.max(0, (Math.max(hx, hz) * 10 + Math.min(hx, hz) * 4) - stopC * 10);
                    this.heapPush(ng + <i32>h, n);
                }
            }
        }
        let end = found >= 0 ? found : bestC;
        // walk back
        let n = 0;
        let c = end;
        while (c >= 0 && n < NC) {
            this.tmpPath[n++] = c;
            if (c == s) {
                break;
            }
            c = this.parent[c];
        }
        // tmpPath runs end .. start; string-pull from the start
        let px = this.ex[e], pz = this.ez[e];
        let k = n - 1;
        let out = 0;
        let base = e * MAXP;
        while (k > 0 && out < MAXP - 1) {
            // the farthest cell still in sight, walking ahead until the view is blocked
            let far = k - 1;
            for (let m = k - 2; m >= 0; m--) {
                if (!this.los(px, pz, this.cx(this.tmpPath[m]), this.cz(this.tmpPath[m]))) {
                    break;
                }
                far = m;
            }
            px = this.cx(this.tmpPath[far]);
            pz = this.cz(this.tmpPath[far]);
            this.pathX[base + out] = px;
            this.pathZ[base + out] = pz;
            out++;
            k = far;
        }
        // finish on the goal itself when it is open and in sight
        if (found >= 0 && !this.blocked(x, z) && this.los(px, pz, x, z) && out < MAXP) {
            this.pathX[base + out] = x;
            this.pathZ[base + out] = z;
            out++;
        }
        this.pathLen[e] = out;
    }

    // ================================================================ entities

    st(e: i32): i32 {
        return this.team[e] * 7 + this.kind[e];
    }

    isUnit(e: i32): bool {
        return this.kind[e] >= K_WORKER;
    }

    freeSlot(t: i32, kind: i32): i32 {
        for (let s = 0; s < 20; s++) {
            let e = t * 20 + s;
            if (SLOT_KIND[s] == kind && !this.alive[e] && this.deadT[e] <= 0) {
                return e;
            }
        }
        return -1;
    }

    clearUnit(e: i32): void {
        this.state[e] = S_IDLE;
        this.tgt[e] = -1;
        this.hasG2[e] = false;
        this.wave[e] = false;
        this.amv[e] = false;
        this.leash[e] = 0;
        this.cd[e] = 0;
        this.swing[e] = 0;
        this.hurt[e] = 0;
        this.walk[e] = 0;
        this.deadT[e] = 0;
        this.scanT[e] = <f64>(e % 7) * 0.05;
        this.res[e] = -1;
        this.phase[e] = 0;
        this.workT[e] = 0;
        this.cargo[e] = 0;
        this.buildT[e] = -1;
        this.pathLen[e] = 0;
        this.pathI[e] = 0;
        this.losT[e] = 0;
        this.stuckT[e] = 0;
        this.vx[e] = 0;
        this.vz[e] = 0;
        this.popT[e] = 0;
        this.knockT[e] = 0;
    }

    spawn(api: GameApi, t: i32, kind: i32, x: f64, z: f64): i32 {
        let e = this.freeSlot(t, kind);
        if (e < 0) {
            return -1;
        }
        this.clearUnit(e);
        this.alive[e] = true;
        this.hp[e] = HP[t * 7 + kind];
        this.ex[e] = x;
        this.ez[e] = z;
        this.lastX[e] = x;
        this.lastZ[e] = z;
        this.yaw[e] = t == 0 ? 135 : -45;
        this.gx[e] = x;
        this.gz[e] = z;
        this.popT[e] = 0.25;
        this.prog[e] = 1;
        return e;
    }

    placeBuilding(t: i32, kind: i32, x: f64, z: f64, done: bool): i32 {
        let e = this.freeSlot(t, kind);
        if (e < 0) {
            return -1;
        }
        this.clearUnit(e);
        this.alive[e] = true;
        this.ex[e] = x;
        this.ez[e] = z;
        this.yaw[e] = B_YAW[t];
        this.prog[e] = done ? 1.0 : 0.0;
        this.hp[e] = done ? HP[t * 7 + kind] : HP[t * 7 + kind] * 0.1;
        this.qLen[e] = 0;
        this.trainT[e] = 0;
        this.scaf[e] = -1;
        if (!done) {
            for (let k = 0; k < 3; k++) {
                if (this.scafOwner[k] < 0) {
                    this.scafOwner[k] = e;
                    this.scaf[e] = k;
                    break;
                }
            }
        }
        this.gridDirty = true;
        // units standing on the site step aside
        let r = RAD[t * 7 + kind] + 0.35;
        for (let u = 0; u < NE; u++) {
            if (this.alive[u] && this.isUnit(u)) {
                let dx = this.ex[u] - x, dz = this.ez[u] - z;
                let d = Math.sqrt(dx * dx + dz * dz);
                if (d < r) {
                    let a = d > 0.01 ? 1.0 / d : 1.0;
                    this.ex[u] = x + (d > 0.01 ? dx * a : 1.0) * (r + 0.1);
                    this.ez[u] = z + (d > 0.01 ? dz * a : 0.0) * (r + 0.1);
                }
            }
        }
        return e;
    }

    // ---------------------------------------------------------------- orders

    orderMove(e: i32, x: f64, z: f64): void {
        this.dropJob(e);
        this.state[e] = S_MOVE;
        this.amv[e] = false;
        this.leash[e] = 0;
        this.gx[e] = x;
        this.gz[e] = z;
        this.tgt[e] = -1;
        this.hasG2[e] = false;
        this.wave[e] = false;
        this.pathLen[e] = 0;
        this.losT[e] = 0;
    }

    orderAMove(e: i32, x: f64, z: f64): void {
        this.dropJob(e);
        this.state[e] = S_AMOVE;
        this.amv[e] = true;
        this.leash[e] = 0;
        this.gx[e] = x;
        this.gz[e] = z;
        this.tgt[e] = -1;
        this.hasG2[e] = false;
        this.pathLen[e] = 0;
        this.losT[e] = 0;
        this.scanT[e] = 0;
    }

    orderAttack(e: i32, t: i32): void {
        this.dropJob(e);
        this.state[e] = S_ATTACK;
        this.amv[e] = false;
        this.leash[e] = 0;
        this.tgt[e] = t;
        this.hasG2[e] = false;
        this.wave[e] = false;
        this.pathLen[e] = 0;
        this.losT[e] = 0;
    }

    orderGather(e: i32, r: i32): void {
        if (e < 0) {
            return;
        }
        if (this.buildT[e] >= 0) {
            this.buildT[e] = -1;
        }
        this.state[e] = S_GATHER;
        this.amv[e] = false;
        this.leash[e] = 0;
        this.res[e] = r;
        this.phase[e] = this.cargo[e] != 0 ? 2 : 0;   // a load in hand goes home first
        this.workT[e] = 0;
        this.pathLen[e] = 0;
        this.losT[e] = 0;
    }

    orderBuild(e: i32, b: i32): void {
        this.state[e] = S_BUILD;
        this.amv[e] = false;
        this.leash[e] = 0;
        this.buildT[e] = b;
        this.pathLen[e] = 0;
        this.losT[e] = 0;
    }

    dropJob(e: i32): void {
        this.buildT[e] = -1;
    }

    // ================================================================ the frame

    update(api: GameApi): void {
        let dt = api.dt;
        this.demoMode = api.demo;
        if (api.demo != this.wasDemo || api.demoChanged) {
            this.wasDemo = api.demo;
            this.reset(api);
            this.overAt = api.time;
        }
        if (this.over) {
            if (api.demo && api.time - this.overAt > 2.0) {
                this.reset(api);
            }
            this.draw(api, dt);
            this.tickFx(dt);
            if (TRACE && !api.demo && api.frame % 20 == 0) { this.dumpState(api); }
            return;
        }
        this.mt += dt;
        this.pathBudget = 6;
        if (this.gridDirty) {
            this.rebuildGrid();
        }
        // the computer; and in demo mode a decent human player
        this.think(api, 1, dt);
        if (api.demo) {
            this.think(api, 0, dt);
        }
        for (let e = 0; e < NE; e++) {
            if (this.alive[e]) {
                if (this.isUnit(e)) {
                    this.unitLogic(api, e, dt);
                } else {
                    this.buildingLogic(api, e, dt);
                }
            } else if (this.deadT[e] > 0) {
                this.deadT[e] -= dt;
            }
        }
        this.moveUnits(dt);
        this.projectiles(api, dt);
        this.groves(api, dt);
        this.msgT -= dt;
        this.markT += dt;
        this.tickFx(dt);
        if (this.mode == M_PLACE) {
            this.checkGhost();
        }
        this.draw(api, dt);
        if (TRACE && (api.frame % 1800 == 0 || (this.over && api.time - this.overAt < 0.02))) { this.debugLog(api); }
        if (TRACE && !api.demo && api.frame % 20 == 0) { this.dumpState(api); }
    }

    dumpState(api: GameApi): void {
        let s = "ST " + api.frame.toString() + " " + (<i32>this.mt).toString() + " " + (<i32>this.gold[0]).toString() + " " + (<i32>this.wood[0]).toString() + " " + this.supplyUsed(0).toString() + " " + this.supplyCap(0).toString() + " " + (this.over ? (this.won ? "W" : "L") : "P") + " " + this.selB.toString() + " " + this.mode.toString() + ";";
        for (let e = 0; e < NE; e++) { if (!this.alive[e]) { continue; } api.project(<f32>this.ex[e], 0.4, <f32>this.ez[e]); s += "E " + e.toString() + " " + this.kind[e].toString() + " " + this.team[e].toString() + " " + (<i32>(api.screenX * 2)).toString() + " " + (<i32>(api.screenY * 2)).toString() + " " + (<i32>this.hp[e]).toString() + " " + this.state[e].toString() + " " + (<i32>(this.prog[e] * 100)).toString() + " " + (this.sel[e] ? "1" : "0") + " " + this.qLen[e].toString() + " " + this.res[e].toString() + ";"; }
        for (let r = 0; r < 8; r++) { api.project(<f32>RES_X[r], 0.4, <f32>RES_Z[r]); s += "R " + r.toString() + " " + (<i32>(api.screenX * 2)).toString() + " " + (<i32>(api.screenY * 2)).toString() + " " + (<i32>this.resAmt[r]).toString() + ";"; }
        console.log(s);
    }

    debugLog(api: GameApi): void {
        let s = "DBG t=" + (<i32>this.mt).toString();
        for (let t = 0; t < 2; t++) {
            let w = 0, m = 0, r = 0, b = "";
            for (let k = 6; k < 20; k++) { let e = t * 20 + k; if (this.alive[e]) { if (this.kind[e] == K_WORKER) { w++; } else if (this.kind[e] == K_MELEE) { m++; } else { r++; } } }
            for (let k = 0; k < 6; k++) { let e = t * 20 + k; b += this.alive[e] ? (this.prog[e] >= 1 ? "1" : "c") : "0"; }
            s += " | T" + t.toString() + " g" + (<i32>this.gold[t]).toString() + " w" + (<i32>this.wood[t]).toString() + " W" + w.toString() + " M" + m.toString() + " R" + r.toString() + " B" + b + " hp" + (<i32>this.hp[t * 20]).toString() + " wave" + this.waveN[t].toString() + " k" + this.killed[t].toString();
        }
        if (this.over) { s += " OVER won=" + (this.won ? "1" : "0"); }
        for (let b = 0; b < NE; b++) { if (this.alive[b] && !this.isUnit(b) && this.prog[b] < 1) { s += " SITE" + b.toString() + "@" + (<i32>(this.ex[b]*10)).toString() + "," + (<i32>(this.ez[b]*10)).toString() + " p" + (<i32>(this.prog[b]*100)).toString(); for (let w = 0; w < NE; w++) { if (this.alive[w] && this.buildT[w] == b) { s += " bld" + w.toString() + " st" + this.state[w].toString() + " at" + (<i32>(this.ex[w]*10)).toString() + "," + (<i32>(this.ez[w]*10)).toString() + " pl" + this.pathLen[w].toString(); } } } }
        console.log(s);
    }

    tickFx(dt: f64): void {
        for (let i = 0; i < 32; i++) {
            this.fxAge[i] += dt;
        }
    }

    fx(kind: i32, x: f64, y: f64, z: f64): void {
        let i = this.fxN;
        this.fxN = (this.fxN + 1) % 32;
        this.fxX[i] = x;
        this.fxY[i] = y;
        this.fxZ[i] = z;
        this.fxAge[i] = 0;
        this.fxKind[i] = kind;
    }

    say(s: string): void {
        this.msg = s;
        this.msgT = 3.0;
    }

    // ---------------------------------------------------------------- units

    unitLogic(api: GameApi, e: i32, dt: f64): void {
        let t = this.team[e];
        let k = this.kind[e];
        let s = this.st(e);
        this.cd[e] -= dt;
        this.swing[e] = Math.max(0, this.swing[e] - dt);
        this.hurt[e] = Math.max(0, this.hurt[e] - dt);
        this.popT[e] = Math.max(0, this.popT[e] - dt);
        this.vx[e] = 0;
        this.vz[e] = 0;
        let stt = this.state[e];
        // a wave that reaches the enemy's hall lays siege to it
        if (this.wave[e] && (stt == S_AMOVE || stt == S_ATTACK)) {
            let eh = (1 - t) * 20;
            if (this.alive[eh] && this.tgt[e] != eh) {
                let hx = this.ex[eh] - this.ex[e], hz = this.ez[eh] - this.ez[e];
                if (hx * hx + hz * hz < 5.0 * 5.0) {
                    this.state[e] = S_ATTACK;
                    this.tgt[e] = eh;
                    this.pathLen[e] = 0;
                    stt = S_ATTACK;
                }
            }
        }
        if (stt == S_IDLE) {
            // soldiers keep watch: an enemy in sight is attacked
            if (k != K_WORKER) {
                this.scanT[e] -= dt;
                if (this.scanT[e] <= 0) {
                    this.scanT[e] = 0.3;
                    let f = this.nearestEnemy(e, 4.3, true);
                    if (f >= 0) {
                        // a guard chases only so far from where it stood
                        this.state[e] = S_ATTACK;
                        this.tgt[e] = f;
                        this.pathLen[e] = 0;
                        if (this.leash[e] <= 0) {
                            this.leash[e] = 6.0;
                            this.homeX[e] = this.ex[e];
                            this.homeZ[e] = this.ez[e];
                        }
                    }
                }
            }
        } else if (stt == S_MOVE) {
            if (this.steer(e, this.gx[e], this.gz[e], 0.15, dt)) {
                this.state[e] = S_IDLE;
            }
        } else if (stt == S_AMOVE) {
            this.scanT[e] -= dt;
            // late in a long match a wave marches past everything to lay siege to the hall
            let march = this.wave[e] && !this.hasG2[e] && this.mt > 540;
            if (this.scanT[e] <= 0 && !march) {
                this.scanT[e] = 0.3;
                let f = this.nearestEnemy(e, 4.6, false);
                if (f >= 0) {
                    this.state[e] = S_ATTACK;
                    this.tgt[e] = f;
                    this.pathLen[e] = 0;
                    return;
                }
            }
            if (this.wave[e] && this.hasG2[e] && this.mt < this.waveGo[this.team[e]]) {
                // regrouping at the ford: wait for the stragglers
                let fx = this.gx[e] - this.ex[e], fz = this.gz[e] - this.ez[e];
                if (fx * fx + fz * fz < 1.6 * 1.6) {
                    return;
                }
            }
            if (this.steer(e, this.gx[e], this.gz[e], 0.6, dt)) {
                // arrived: anything hostile in sight, buildings too, is next
                let nb = this.nearestEnemy(e, 4.6, false);
                if (nb >= 0 && !this.hasG2[e]) {
                    this.state[e] = S_ATTACK;
                    this.tgt[e] = nb;
                    this.pathLen[e] = 0;
                    return;
                }
                if (this.hasG2[e]) {
                    this.hasG2[e] = false;
                    this.gx[e] = this.g2x[e];
                    this.gz[e] = this.g2z[e];
                    this.pathLen[e] = 0;
                } else if (this.wave[e]) {
                    let b = this.nearestEnemyBuilding(e);
                    if (b >= 0) {
                        this.state[e] = S_ATTACK;
                        this.tgt[e] = b;
                    } else {
                        this.state[e] = S_IDLE;
                    }
                } else {
                    this.state[e] = S_IDLE;
                }
            }
        } else if (stt == S_ATTACK) {
            this.attackLogic(api, e, dt);
        } else if (stt == S_GATHER) {
            this.gatherLogic(api, e, dt);
        } else if (stt == S_BUILD) {
            this.buildLogic(api, e, dt);
        }
    }

    // after a target falls: an attack-mover goes on, a wave finds the next thing, others look round
    afterTarget(e: i32): void {
        let marching = this.amv[e] || this.wave[e];
        if (this.kind[e] != K_WORKER) {
            let f = this.nearestEnemy(e, marching ? 5.0 : 4.3, !marching);
            if (f >= 0) {
                this.tgt[e] = f;
                this.state[e] = S_ATTACK;
                this.pathLen[e] = 0;
                return;
            }
        }
        this.pathLen[e] = 0;
        if (this.kind[e] == K_WORKER && this.res[e] >= 0) {
            this.orderGather(e, this.res[e]);
            return;
        }
        if (this.leash[e] > 0 && !marching) {
            let lx = this.homeX[e], lz = this.homeZ[e];
            this.orderMove(e, lx, lz);
            return;
        }
        if (marching) {
            this.state[e] = S_AMOVE;
        } else if (this.kind[e] == K_WORKER && this.res[e] >= 0) {
            this.state[e] = S_GATHER;
        } else {
            this.state[e] = S_IDLE;
        }
    }

    attackLogic(api: GameApi, e: i32, dt: f64): void {
        let f = this.tgt[e];
        if (f < 0 || !this.alive[f]) {
            this.afterTarget(e);
            return;
        }
        let s = this.st(e);
        let dx = this.ex[f] - this.ex[e], dz = this.ez[f] - this.ez[e];
        let d = Math.sqrt(dx * dx + dz * dz);
        let edge = d - RAD[s] - RAD[this.st(f)];
        let range = RNG[s];
        // soldiers on watch give up a long chase
        if (this.leash[e] > 0 && edge > range) {
            let hx = this.ex[f] - this.homeX[e], hz = this.ez[f] - this.homeZ[e];
            if (hx * hx + hz * hz > this.leash[e] * this.leash[e]) {
                let lx = this.homeX[e], lz = this.homeZ[e];
                this.orderMove(e, lx, lz);
                return;
            }
        }
        if (edge > range) {
            // a closer enemy unit on the way is worth more than a building
            if (this.kind[f] <= K_FARM && !(this.wave[e] && this.kind[f] == K_HALL)) {
                this.scanT[e] -= dt;
                if (this.scanT[e] <= 0) {
                    this.scanT[e] = 0.4;
                    let n = this.nearestEnemy(e, 3.0, true);
                    if (n >= 0) {
                        this.tgt[e] = n;
                        this.pathLen[e] = 0;
                        return;
                    }
                }
            }
            let stop = RAD[s] + RAD[this.st(f)] + range * 0.8;
            this.steer(e, this.ex[f], this.ez[f], stop, dt);
            return;
        }
        this.face(e, dx, dz, dt);
        if (this.cd[e] <= 0) {
            this.cd[e] = CD[s];
            this.swing[e] = 0.28;
            if (this.kind[e] == K_RANGED) {
                this.shoot(api, e, f, 0.75);
            } else {
                this.damage(api, f, DMG[s], e);
                if (api.frame - this.lastHit > 5) {
                    this.lastHit = api.frame;
                    api.soundAt(SFX_HIT, this.ex[f], 0.5, this.ez[f], this.team[e] == 0 ? 1.25 : 0.95, 0.28);
                }
                this.fx(0, this.ex[f], 0.55, this.ez[f]);
            }
        }
    }

    face(e: i32, dx: f64, dz: f64, dt: f64): void {
        if (Math.abs(dx) + Math.abs(dz) > 0.001) {
            this.yaw[e] = turnTo(this.yaw[e], Math.atan2(dx, dz) * 180 / Math.PI, dt * 720);
        }
    }

    gatherLogic(api: GameApi, e: i32, dt: f64): void {
        let t = this.team[e];
        let r = this.res[e];
        if (this.phase[e] == 2) {
            // home with the load
            let h = t * 20;
            if (!this.alive[h]) {
                this.state[e] = S_IDLE;
                return;
            }
            let stop = RAD[t * 7] + RAD[this.st(e)] + 0.25;
            if (this.steer(e, this.ex[h], this.ez[h], stop, dt)) {
                let load = this.cargoAmt[e];
                if (this.cargo[e] == 1) {
                    this.gold[t] += load;
                    this.gotGold[t] += load;
                    if (t == 0) {
                        api.soundAt(SFX_COIN, this.ex[e], 0.5, this.ez[e], 1.5, 0.22);
                        this.fx(2, this.ex[h], 2.0, this.ez[h]);
                    }
                } else if (this.cargo[e] == 2) {
                    this.wood[t] += load;
                    this.gotWood[t] += load;
                    if (t == 0) {
                        api.soundAt(SFX_THUD, this.ex[e], 0.5, this.ez[e], 1.6, 0.3);
                        this.fx(3, this.ex[h], 2.0, this.ez[h]);
                    }
                }
                this.cargo[e] = 0;
                this.releaseCarry(e);
                // back to it, or to the nearest of the same kind when it ran out
                if (r < 0 || this.resAmt[r] <= 0) {
                    r = this.nearestRes(e, r >= 6 || r < 0);
                    this.res[e] = r;
                }
                if (r < 0) {
                    this.state[e] = S_IDLE;
                    return;
                }
                this.phase[e] = 0;
                this.pathLen[e] = 0;
            }
            return;
        }
        if (r < 0 || this.resAmt[r] <= 0) {
            r = this.nearestRes(e, r >= 6);
            this.res[e] = r;
            this.pathLen[e] = 0;
            if (r < 0) {
                this.state[e] = S_IDLE;
                return;
            }
        }
        let rr = r >= 6 ? 1.12 : 0.8;
        if (this.phase[e] == 0) {
            if (this.steer(e, RES_X[r], RES_Z[r], rr + RAD[this.st(e)] + 0.12, dt)) {
                this.phase[e] = 1;
                this.workT[e] = 0;
            }
            return;
        }
        // working: swing the tool; a chop or a clink each swing
        this.face(e, RES_X[r] - this.ex[e], RES_Z[r] - this.ez[e], dt);
        let before = this.workT[e];
        this.workT[e] += dt;
        if (Math.floor(before / 0.6) != Math.floor(this.workT[e] / 0.6)) {
            this.swing[e] = 0.25;
            if (t == 0 && api.frame - this.lastChop > 11) {
                this.lastChop = api.frame;
                if (r >= 6) {
                    api.soundAt(SFX_CLICK, this.ex[e], 0.5, this.ez[e], 1.9, 0.16);
                } else {
                    api.soundAt(SFX_TICK, this.ex[e], 0.5, this.ez[e], 0.55, 0.35);
                }
            }
        }
        let need = r >= 6 ? 2.2 : 2.6;
        if (this.workT[e] >= need) {
            let take = Math.min(LOAD, this.resAmt[r]);
            this.resAmt[r] -= take;
            this.cargo[e] = r >= 6 ? 1 : 2;
            this.cargoAmt[e] = take;
            this.phase[e] = 2;
            this.pathLen[e] = 0;
            if (r < 6 && this.resAmt[r] <= 0) {
                this.groveFall[r] = 0.0001;
                this.gridDirty = true;
                if (t == 0 || this.team[e] == 0) {
                    api.soundAt(SFX_WHOOSH, RES_X[r], 1, RES_Z[r], 0.6, 0.4);
                    api.soundAt(SFX_THUD, RES_X[r], 1, RES_Z[r], 0.8, 0.5, 0.25);
                }
            }
        }
    }

    nearestRes(e: i32, wantGold: bool): i32 {
        let t = this.team[e];
        if (wantGold) {
            return this.resAmt[6 + t] > 0 ? 6 + t : -1;
        }
        let best = -1;
        let bd = 1e9;
        for (let g = 0; g < 6; g++) {
            if (this.resAmt[g] <= 0) {
                continue;
            }
            let dx = RES_X[g] - this.ex[e], dz = RES_Z[g] - this.ez[e];
            let d = dx * dx + dz * dz + (g / 3 != t ? 60.0 : 0.0);
            if (d < bd) {
                bd = d;
                best = g;
            }
        }
        return best;
    }

    buildLogic(api: GameApi, e: i32, dt: f64): void {
        let b = this.buildT[e];
        if (b < 0 || !this.alive[b] || this.prog[b] >= 1) {
            this.buildT[e] = -1;
            this.backToWork(e);
            return;
        }
        let stop = RAD[this.st(b)] + RAD[this.st(e)] + 0.3;
        if (!this.steer(e, this.ex[b], this.ez[b], stop, dt)) {
            return;
        }
        this.face(e, this.ex[b] - this.ex[e], this.ez[b] - this.ez[e], dt);
        let sb = this.st(b);
        let before = this.prog[b];
        this.prog[b] = Math.min(1, this.prog[b] + dt / TIME[sb]);
        this.hp[b] = Math.min(HP[sb], this.hp[b] + HP[sb] * 0.9 * dt / TIME[sb]);
        this.knockT[e] += dt;
        if (this.knockT[e] > 0.42) {
            this.knockT[e] = 0;
            this.swing[e] = 0.22;
            if (this.team[e] == 0 && api.frame - this.lastKnock > 12) {
                this.lastKnock = api.frame;
                api.soundAt(SFX_TICK, this.ex[b], 0.5, this.ez[b], (api.frame / 25) % 2 == 0 ? 0.75 : 0.9, 0.5);
            }
        }
        if (Math.floor(before * 5) != Math.floor(this.prog[b] * 5) && this.prog[b] < 1) {
            this.fx(1, this.ex[b], 0.3, this.ez[b]);
        }
        if (this.prog[b] >= 1) {
            this.finishBuilding(api, b);
            this.buildT[e] = -1;
            this.backToWork(e);
        }
    }

    finishBuilding(api: GameApi, b: i32): void {
        this.prog[b] = 1;
        this.popT[b] = 0.3;
        if (this.scaf[b] >= 0) {
            this.scafOwner[this.scaf[b]] = -1;
            api.hide(this.scafBone[this.scaf[b]]);
            this.scaf[b] = -1;
        }
        this.fx(1, this.ex[b], 0.4, this.ez[b]);
        if (this.team[b] == 0) {
            api.soundAt(SFX_THUD, this.ex[b], 0.5, this.ez[b], 0.9, 0.5);
            api.note(72, 0.4, 0, SFX_BELL, 0.1);
            api.note(79, 0.4, 0, SFX_BELL, 0.25);
            this.say(NAMES[this.st(b)] + " COMPLETE");
        }
    }

    backToWork(e: i32): void {
        let r = this.res[e];
        if (r < 0 || this.resAmt[r] <= 0) {
            r = this.nearestRes(e, true);
        }
        if (r >= 0) {
            this.orderGather(e, r);
        } else {
            this.state[e] = S_IDLE;
        }
    }

    nearestEnemy(e: i32, range: f64, unitsOnly: bool): i32 {
        let t = this.team[e];
        let best = -1;
        let bd = 1e9;
        let o0 = (1 - t) * 20;
        for (let f = o0; f < o0 + 20; f++) {
            if (!this.alive[f]) {
                continue;
            }
            let isU = this.kind[f] >= K_WORKER;
            if (unitsOnly && !isU && this.kind[f] != K_TOWER) {
                continue;
            }
            let dx = this.ex[f] - this.ex[e], dz = this.ez[f] - this.ez[e];
            let d = Math.sqrt(dx * dx + dz * dz) - RAD[this.st(f)];
            // soldiers first, then workers and towers, then other buildings
            let pen = isU ? (this.kind[f] == K_WORKER ? 1.2 : 0.0) : (this.kind[f] == K_TOWER ? 1.0 : 2.5);
            if (d < range && d + pen < bd) {
                bd = d + pen;
                best = f;
            }
        }
        return best;
    }

    nearestEnemyBuilding(e: i32): i32 {
        let t = this.team[e];
        let best = -1;
        let bd = 1e9;
        let o0 = (1 - t) * 20;
        for (let f = o0; f < o0 + 6; f++) {
            if (!this.alive[f]) {
                continue;
            }
            let dx = this.ex[f] - this.ex[e], dz = this.ez[f] - this.ez[e];
            let d = dx * dx + dz * dz;
            if (d < bd) {
                bd = d;
                best = f;
            }
        }
        return best;
    }

    // moves a unit towards a point (on its path when the way is not clear); true once within stopR
    steer(e: i32, x: f64, z: f64, stopR: f64, dt: f64): bool {
        let dx = x - this.ex[e], dz = z - this.ez[e];
        let d = Math.sqrt(dx * dx + dz * dz);
        if (d <= stopR) {
            this.pathLen[e] = 0;
            return true;
        }
        this.losT[e] -= dt;
        if (this.losT[e] <= 0) {
            this.losT[e] = 0.25;
            this.losOk[e] = this.los(this.ex[e], this.ez[e], x, z);
        }
        let wx = x, wz = z;
        if (!this.losOk[e]) {
            let moved = Math.abs(this.pgx[e] - x) + Math.abs(this.pgz[e] - z);
            this.pathT[e] -= dt;
            if ((this.pathLen[e] == 0 || moved > 0.8) && this.pathBudget > 0 && this.pathT[e] <= 0) {
                this.pathBudget--;
                this.pathT[e] = 0.5;
                this.findPath(e, x, z, stopR);
            }
            let base = e * MAXP;
            while (this.pathI[e] < this.pathLen[e]) {
                let px = this.pathX[base + this.pathI[e]], pz = this.pathZ[base + this.pathI[e]];
                let ddx = px - this.ex[e], ddz = pz - this.ez[e];
                if (ddx * ddx + ddz * ddz < 0.2 * 0.2) {
                    this.pathI[e]++;
                    continue;
                }
                wx = px;
                wz = pz;
                break;
            }
            if (this.pathI[e] >= this.pathLen[e] && this.pathLen[e] > 0) {
                // at the path's end but not in reach: the goal cannot be reached any closer
                let ex = this.pathX[base + this.pathLen[e] - 1] - this.ex[e];
                let ez = this.pathZ[base + this.pathLen[e] - 1] - this.ez[e];
                if (ex * ex + ez * ez < 0.3 * 0.3 && d < stopR + 1.2) {
                    return true;
                }
                this.pathLen[e] = 0;
            }
        }
        let ddx = wx - this.ex[e], ddz = wz - this.ez[e];
        let dd = Math.sqrt(ddx * ddx + ddz * ddz);
        if (dd > 0.001) {
            let sp = SPD[this.st(e)];
            if (this.cargo[e] != 0) {
                sp *= 0.9;
            }
            this.vx[e] = ddx / dd * sp;
            this.vz[e] = ddz / dd * sp;
            this.face(e, ddx, ddz, dt);
        }
        // stuck: a fresh path
        this.stuckT[e] += dt;
        if (this.stuckT[e] > 1.0) {
            let mx = this.ex[e] - this.lastX[e], mz = this.ez[e] - this.lastZ[e];
            if (mx * mx + mz * mz < 0.15 * 0.15) {
                this.pathLen[e] = 0;
                this.losOk[e] = false;
                this.losT[e] = 0.6;
            }
            this.stuckT[e] = 0;
            this.lastX[e] = this.ex[e];
            this.lastZ[e] = this.ez[e];
        }
        return false;
    }

    moveUnits(dt: f64): void {
        // separation: units push each other apart; a standing unit gives way
        for (let a = 0; a < NE; a++) {
            if (!this.alive[a] || !this.isUnit(a)) {
                continue;
            }
            let px = 0.0, pz = 0.0;
            for (let b = 0; b < NE; b++) {
                if (b == a || !this.alive[b] || !this.isUnit(b)) {
                    continue;
                }
                let dx = this.ex[a] - this.ex[b], dz = this.ez[a] - this.ez[b];
                let m = RAD[this.st(a)] + RAD[this.st(b)] + 0.04;
                let d2 = dx * dx + dz * dz;
                if (d2 < m * m) {
                    let d = Math.sqrt(d2);
                    if (d < 0.001) {
                        dx = <f64>(a - b) * 0.01;
                        dz = 0.01;
                        d = Math.sqrt(dx * dx + dz * dz);
                    }
                    // a walker shoulders through; a standing unit gives way
                    let aMov = Math.abs(this.vx[a]) + Math.abs(this.vz[a]) > 0.05;
                    let bMov = Math.abs(this.vx[b]) + Math.abs(this.vz[b]) > 0.05;
                    let wgt = aMov && !bMov ? 0.35 : (!aMov && bMov ? 1.6 : 1.0);
                    let push = (m - d) / m * wgt;
                    px += dx / d * push * 2.4;
                    pz += dz / d * push * 2.4;
                }
            }
            let nx = this.ex[a] + (this.vx[a] + px) * dt;
            let nz = this.ez[a] + (this.vz[a] + pz) * dt;
            let inBlock = this.blocked(this.ex[a], this.ez[a]);
            if (inBlock) {
                // pushed into an obstacle (a new building): walk out of it
                this.ex[a] = nx;
                this.ez[a] = nz;
                if (Math.abs(this.vx[a]) + Math.abs(this.vz[a]) < 0.01) {
                    let c = this.nearestFree(this.ex[a], this.ez[a]);
                    if (c >= 0) {
                        let ox = this.cx(c) - this.ex[a], oz = this.cz(c) - this.ez[a];
                        let od = Math.sqrt(ox * ox + oz * oz);
                        if (od > 0.01) {
                            this.ex[a] += ox / od * Math.min(od, 1.2 * dt);
                            this.ez[a] += oz / od * Math.min(od, 1.2 * dt);
                        }
                    }
                }
            } else if (!this.blocked(nx, nz)) {
                this.ex[a] = nx;
                this.ez[a] = nz;
            } else if (!this.blocked(nx, this.ez[a])) {
                this.ex[a] = nx;
            } else if (!this.blocked(this.ex[a], nz)) {
                this.ez[a] = nz;
            }
            let moving = Math.abs(this.vx[a]) + Math.abs(this.vz[a]) > 0.05;
            if (moving) {
                this.walk[a] += dt * 9.0;
            }
        }
    }

    nearestFree(x: f64, z: f64): i32 {
        let c0 = this.cellOf(x, z);
        if (c0 < 0) {
            return -1;
        }
        let i0 = c0 % GW, j0 = c0 / GW;
        for (let r = 1; r < 8; r++) {
            let best = -1;
            let bd = 1e9;
            for (let j = j0 - r; j <= j0 + r; j++) {
                for (let i = i0 - r; i <= i0 + r; i++) {
                    if (i < 0 || j < 0 || i >= GW || j >= GH) {
                        continue;
                    }
                    let c = j * GW + i;
                    if (this.blk[c] != 0) {
                        continue;
                    }
                    let dx = this.cx(c) - x, dz = this.cz(c) - z;
                    let d = dx * dx + dz * dz;
                    if (d < bd) {
                        bd = d;
                        best = c;
                    }
                }
            }
            if (best >= 0) {
                return best;
            }
        }
        return -1;
    }

    // ---------------------------------------------------------------- damage, death

    damage(api: GameApi, f: i32, amount: f64, src: i32): void {
        if (!this.alive[f]) {
            return;
        }
        // buildings are worth breaking: soldiers hit them half again as hard, a hall more than twice
        // (a wave that reaches it is a real threat; towers shoot units only)
        let mult = 1.0;
        if (this.kind[f] <= K_FARM && src >= 0 && this.isUnit(src)) {
            mult = this.kind[f] == K_HALL ? 2.2 : 1.5;
        }
        this.hp[f] -= amount * mult;
        this.hurt[f] = 0.16;
        let t = this.team[f];
        // the victim's side notices
        if (t == 0 && api.time - this.underAttackT[0] > 14 && !api.demo) {
            let h = 0;
            let dx = this.ex[f] - HALL_X[0], dz = this.ez[f] - HALL_Z[0];
            if (this.kind[f] <= K_FARM || dx * dx + dz * dz < 49) {
                this.underAttackT[0] = api.time;
                this.say("YOUR BASE IS UNDER ATTACK!");
                api.sound(SFX_ZAP, 0.45, 0.4);
                api.note(60, 0.45, 0, SFX_NOTE, 0.12);
                api.note(57, 0.45, 0, SFX_NOTE, 0.26);
                h = 1;
            }
        }
        // a struck soldier or worker on watch turns on its attacker
        if (src >= 0 && this.alive[src] && this.isUnit(f) && this.kind[f] != K_WORKER &&
            (this.state[f] == S_IDLE || (this.state[f] == S_ATTACK && this.tgt[f] >= 0 && this.kind[this.tgt[f]] <= K_FARM))) {
            this.state[f] = S_ATTACK;
            this.tgt[f] = src;
            this.pathLen[f] = 0;
        }
        if (this.hp[f] <= 0) {
            this.kill(api, f, src);
        }
    }

    kill(api: GameApi, f: i32, src: i32): void {
        let t = this.team[f];
        this.alive[f] = false;
        this.sel[f] = false;
        if (this.selB == f) {
            this.selB = -1;
        }
        this.releaseCarry(f);
        this.lost[t]++;
        this.killed[1 - t]++;
        if (this.isUnit(f)) {
            this.deadT[f] = 1.1;
            if (api.frame - this.lastDeath > 6) {
                this.lastDeath = api.frame;
                if (t == 0) {
                    api.noteAt(64, this.ex[f], 0.5, this.ez[f], 0.35, SFX_NOTE);
                    api.noteAt(59, this.ex[f], 0.5, this.ez[f], 0.3, SFX_NOTE, 0.1);
                } else {
                    api.soundAt(SFX_THUD, this.ex[f], 0.5, this.ez[f], 0.7, 0.5);
                    api.noteAt(45, this.ex[f], 0.5, this.ez[f], 0.35, SFX_NOTE, 0.05);
                }
            }
        } else {
            this.deadT[f] = 1.4;
            if (this.scaf[f] >= 0) {
                this.scafOwner[this.scaf[f]] = -1;
                api.hide(this.scafBone[this.scaf[f]]);
                this.scaf[f] = -1;
            }
            this.gridDirty = true;
            api.soundAt(SFX_EXPLODE, this.ex[f], 1, this.ez[f], 0.7, 0.75);
            api.soundAt(SFX_THUD, this.ex[f], 1, this.ez[f], 0.6, 0.8, 0.3);
            for (let k = 0; k < 4; k++) {
                this.fx(1, this.ex[f] + (<f64>(k % 2) - 0.5) * RAD[this.st(f)], 0.3 + 0.3 * <f64>k,
                    this.ez[f] + (<f64>(k / 2) - 0.5) * RAD[this.st(f)]);
            }
            // refund nothing; the queue is lost
            this.qLen[f] = 0;
            if (this.kind[f] == K_HALL) {
                this.endMatch(api, t == 1);
            }
        }
    }

    releaseCarry(e: i32): void {
        let k = this.carryB[e];
        if (k >= 0) {
            this.carryOwner[k] = -1;
            this.carryB[e] = -1;
        }
    }

    endMatch(api: GameApi, humansWon: bool): void {
        this.over = true;
        this.won = humansWon;
        this.overAt = api.time;
        this.mode = M_NONE;
        let secs = <i32>this.mt;
        let s = this.killed[0] * 25 + <i32>((this.gotGold[0] + this.gotWood[0]) / 4);
        if (humansWon) {
            s += 1000 + max<i32>(0, 600 - secs) * 3;
        }
        this.score = s;
        this.newBest = s > this.best;
        if (s > this.best) {
            this.best = s;
        }
        if (humansWon) {
            api.sound(SFX_WIN, 1, 0.7);
            api.note(72, 0.5, 0, SFX_NOTE, 0.35);
            api.note(76, 0.5, 0, SFX_NOTE, 0.5);
            api.note(79, 0.5, 0, SFX_NOTE, 0.65);
            api.note(84, 0.6, 0, SFX_BELL, 0.8);
        } else {
            api.sound(SFX_LOSE, 1, 0.7);
            api.note(57, 0.5, 0, SFX_BELL, 0.5);
            api.note(52, 0.5, 0, SFX_BELL, 0.9);
        }
    }

    // ---------------------------------------------------------------- projectiles

    shoot(api: GameApi, src: i32, f: i32, y0: f64): void {
        let t = this.team[src];
        let dmg = DMG[this.st(src)];
        let slot = -1;
        for (let k = t * 4; k < t * 4 + 4; k++) {
            if (!this.projOn[k]) {
                slot = k;
                break;
            }
        }
        let dx = this.ex[f] - this.ex[src], dz = this.ez[f] - this.ez[src];
        let d = Math.sqrt(dx * dx + dz * dz);
        if (api.frame - this.lastShot > 4) {
            this.lastShot = api.frame;
            if (t == 0) {
                api.soundAt(SFX_SHOOT, this.ex[src], y0, this.ez[src], 1.7, 0.2);
            } else {
                api.soundAt(SFX_WHOOSH, this.ex[src], y0, this.ez[src], 1.4, 0.28);
            }
        }
        if (slot < 0) {
            this.damage(api, f, dmg, src);  // no free arrow to show: the hit lands at once
            return;
        }
        this.projOn[slot] = true;
        this.projT[slot] = 0;
        this.projDur[slot] = Math.max(0.18, d / (t == 0 ? 10.0 : 8.0));
        this.projX0[slot] = this.ex[src];
        this.projY0[slot] = y0;
        this.projZ0[slot] = this.ez[src];
        this.projTgt[slot] = f;
        this.projDmg[slot] = dmg;
        this.projSrc[slot] = src;
    }

    projectiles(api: GameApi, dt: f64): void {
        for (let k = 0; k < 8; k++) {
            if (!this.projOn[k]) {
                continue;
            }
            let f = this.projTgt[k];
            this.projT[k] += dt;
            let u = Math.min(1, this.projT[k] / this.projDur[k]);
            let tx = this.ex[f], tz = this.ez[f];
            let ty = this.isUnit(f) ? 0.5 : HGT[this.st(f)] * 0.4;
            let arc = Math.min(1.2, this.projDur[k] * 2.2);
            let x = this.projX0[k] + (tx - this.projX0[k]) * u;
            let z = this.projZ0[k] + (tz - this.projZ0[k]) * u;
            let y = this.projY0[k] + (ty - this.projY0[k]) * u + arc * 4 * u * (1 - u);
            let u2 = Math.min(1, u + 0.05);
            let x2 = this.projX0[k] + (tx - this.projX0[k]) * u2;
            let z2 = this.projZ0[k] + (tz - this.projZ0[k]) * u2;
            let y2 = this.projY0[k] + (ty - this.projY0[k]) * u2 + arc * 4 * u2 * (1 - u2);
            let hx = x2 - x, hz = z2 - z, hy = y2 - y;
            let yw = Math.atan2(hx, hz) * 180 / Math.PI;
            let pt = -Math.atan2(hy, Math.sqrt(hx * hx + hz * hz)) * 180 / Math.PI;
            api.place(this.projBone[k], x, y, z, yw, pt);
            if (u >= 1) {
                this.projOn[k] = false;
                api.hide(this.projBone[k]);
                if (this.alive[f]) {
                    this.damage(api, f, this.projDmg[k], this.projSrc[k]);
                    this.fx(0, tx, ty, tz);
                }
            }
        }
    }

    // ---------------------------------------------------------------- buildings

    buildingLogic(api: GameApi, b: i32, dt: f64): void {
        let t = this.team[b];
        this.popT[b] = Math.max(0, this.popT[b] - dt);
        this.hurt[b] = Math.max(0, this.hurt[b] - dt);
        if (this.prog[b] < 1) {
            return;
        }
        let k = this.kind[b];
        if (k == K_TOWER) {
            this.cd[b] -= dt;
            if (this.cd[b] <= 0) {
                let f = this.nearestEnemy(b, RNG[this.st(b)] + RAD[this.st(b)], true);
                if (f >= 0) {
                    this.cd[b] = CD[this.st(b)];
                    this.shoot(api, b, f, HGT[this.st(b)] * 0.72);
                } else {
                    this.cd[b] = 0.25;
                }
            }
            return;
        }
        if (this.qLen[b] == 0) {
            return;
        }
        let uk = this.queue[b * 5];
        let s = t * 7 + uk;
        if (this.supplyUsed(t) + 1 > this.supplyCap(t)) {
            return; // waits for supply
        }
        this.trainT[b] += dt;
        if (this.trainT[b] >= TIME[s]) {
            // out of the door
            let yr = B_YAW[t] * Math.PI / 180;
            let fx = Math.sin(yr), fz = Math.cos(yr);
            let r = RAD[this.st(b)] + 0.5;
            let x = this.ex[b] + fx * r, z = this.ez[b] + fz * r;
            if (this.blocked(x, z)) {
                let c = this.nearestFree(x, z);
                if (c >= 0) {
                    x = this.cx(c);
                    z = this.cz(c);
                }
            }
            let u = this.spawn(api, t, uk, x, z);
            if (u < 0) {
                return; // the pool is full: waits
            }
            this.trainT[b] = 0;
            for (let q = 0; q < 4; q++) {
                this.queue[b * 5 + q] = this.queue[b * 5 + q + 1];
            }
            this.qLen[b]--;
            this.trained[t]++;
            this.yaw[u] = B_YAW[t];
            if (uk == K_WORKER) {
                this.orderGather(u, this.nearestRes(u, this.workersOn(t, true) < 3));
            } else {
                this.orderMove(u, x + fx * 1.0, z + fz * 1.0);
            }
            if (t == 0) {
                this.ack(api, uk, 1.0, 0);
                this.say(NAMES[s] + " READY");
            }
        }
    }

    supplyCap(t: i32): i32 {
        let c = this.alive[t * 20] ? SUPPLY_HALL : 0;
        for (let s = 4; s < 6; s++) {
            let e = t * 20 + s;
            if (this.alive[e] && this.prog[e] >= 1) {
                c += SUPPLY_FARM;
            }
        }
        return c;
    }

    supplyUsed(t: i32): i32 {
        let n = 0;
        for (let s = 6; s < 20; s++) {
            if (this.alive[t * 20 + s]) {
                n++;
            }
        }
        return n;
    }

    workersOn(t: i32, onGold: bool): i32 {
        let n = 0;
        for (let s = 6; s < 11; s++) {
            let e = t * 20 + s;
            if (this.alive[e] && this.state[e] == S_GATHER && this.res[e] >= 0 && ((this.res[e] >= 6) == onGold)) {
                n++;
            }
        }
        return n;
    }

    // ---------------------------------------------------------------- groves

    groves(api: GameApi, dt: f64): void {
        for (let g = 0; g < 6; g++) {
            let b = this.groveB[g];
            if (this.resAmt[g] > 0) {
                // shrinks in four steps as it is cut
                let f = Math.ceil(this.resAmt[g] / GROVE_WOOD * 4) / 4;
                let s = 0.5 + 0.5 * f;
                api.place(b, RES_X[g], 0, RES_Z[g], <f64>(g * 47), 0, 0, s);
            } else if (this.groveFall[g] > 0 && this.groveFall[g] < 0.5) {
                this.groveFall[g] += dt;
                let u = Math.min(1, this.groveFall[g] / 0.5);
                api.place(b, RES_X[g], -0.3 * u, RES_Z[g], <f64>(g * 47), 0, stepped(u * 70, 10), 0.5 * (1 - u * 0.6));
            } else {
                api.hide(b);
            }
        }
    }

    // ================================================================ the computer (and the demo's human)

    think(api: GameApi, t: i32, dt: f64): void {
        this.aiT[t] -= dt;
        if (this.aiT[t] > 0) {
            return;
        }
        this.aiT[t] = 0.5;
        let base = t * 20;
        if (!this.alive[base]) {
            return;
        }
        let workers = 0, army = 0, homeArmy = 0;
        for (let s = 6; s < 20; s++) {
            let e = base + s;
            if (!this.alive[e]) {
                continue;
            }
            if (SLOT_KIND[s] == K_WORKER) {
                workers++;
                if (this.state[e] == S_IDLE) {
                    let wood = this.workersOn(t, false);
                    let r = this.nearestRes(e, !(wood < (workers >= 4 ? 2 : 1)));
                    if (r < 0) {
                        r = this.nearestRes(e, true);
                    }
                    this.orderGather(e, r);
                }
            } else {
                army++;
                if (!this.wave[e]) {
                    homeArmy++;
                }
            }
        }
        // keep one or two on wood (more when wood runs short), the rest on gold
        let woodW = this.workersOn(t, false);
        let wantWood = workers >= 4 ? (this.wood[t] < 60 ? 3 : 2) : 1;
        if (this.wood[t] > 260) {
            wantWood = 1;
        }
        if (woodW != wantWood) {
            for (let s = 6; s < 11; s++) {
                let e = base + s;
                if (!this.alive[e] || this.state[e] != S_GATHER || this.cargo[e] != 0) {
                    continue;
                }
                let onGold = this.res[e] >= 6;
                if (woodW < wantWood && onGold) {
                    let r = this.nearestRes(e, false);
                    if (r >= 0) {
                        this.orderGather(e, r);
                    }
                    break;
                }
                if (woodW > wantWood && !onGold) {
                    this.orderGather(e, 6 + t);
                    break;
                }
            }
        }
        let used = this.supplyUsed(t), cap = this.supplyCap(t);
        let queued = 0;
        for (let s = 0; s < 6; s++) {
            queued += this.qLen[base + s];
        }
        let building = false;
        for (let s = 1; s < 6; s++) {
            if (this.alive[base + s] && this.prog[base + s] < 1) {
                building = true;
                // a site with nobody on it gets a builder
                let has = false;
                for (let w = 6; w < 11; w++) {
                    if (this.alive[base + w] && this.buildT[base + w] == base + s) {
                        has = true;
                    }
                }
                if (!has) {
                    let w = this.pickWorker(t, this.ex[base + s], this.ez[base + s], false);
                    if (w >= 0) {
                        this.orderBuild(w, base + s);
                    }
                }
            }
        }
        let hasBarr = this.alive[base + 1];
        let barrDone = hasBarr && this.prog[base + 1] >= 1;
        let g = this.gold[t], w = this.wood[t];
        // 1. workers up to five (the computer against a player keeps four: a decent player can
        // out-grow it)
        let maxW = t == 1 && !api.demo && this.mt < 80 ? 4 : 5;
        if (workers + this.qLen[base] < maxW && this.qLen[base] == 0 && used + queued < cap && g >= 50 &&
            (hasBarr || workers < 4 || g >= 170)) {
            this.enqueue(base, K_WORKER);
            g -= 50;
        }
        // 2. supply
        let farms = (this.alive[base + 4] ? 1 : 0) + (this.alive[base + 5] ? 1 : 0);
        if (!building && cap - used - queued <= 1 && farms < 2 && (hasBarr || farms == 0)) {
            if (g >= 50 && w >= 40) {
                this.aiBuild(api, t, K_FARM);
                building = true;
                g -= 50;
            }
        }
        // 3. the barracks
        let saving = false;
        if (!building && !hasBarr && (workers >= 4 || this.mt > 50)) {
            if (g >= 120 && w >= 80) {
                this.aiBuild(api, t, K_BARR);
                building = true;
            }
            saving = true; // everything else waits for it
        }
        // 4. a tower once there is an army, a second one later
        let towers = (this.alive[base + 2] ? 1 : 0) + (this.alive[base + 3] ? 1 : 0);
        let wantT = this.mt > 260 ? 2 : 1;
        if (!saving && !building && barrDone && towers < wantT && army >= (t == 1 && !api.demo ? 1 : 3) && g >= 160 && w >= 60) {
            this.aiBuild(api, t, K_TOWER);
            building = true;
            g -= 90;
        }
        // 5. soldiers, in a pattern: melee, melee, ranged
        if (!saving && barrDone && this.qLen[base + 1] == 0 && used + queued < cap) {
            let want = this.pattern[t] % 3 == 2 ? K_RANGED : K_MELEE;
            if (want == K_RANGED && w < 30) {
                want = K_MELEE;
            }
            let s = t * 7 + want;
            if (g >= <f64>COST_G[s] && w >= <f64>COST_W[s]) {
                this.enqueue(base + 1, want);
                this.pattern[t]++;
            }
        }
        // 6. the army: defend, gather at the rally point, attack in waves
        let threat = -1;
        let td = 1e9;
        let o0 = (1 - t) * 20;
        for (let f = o0 + 6; f < o0 + 20; f++) {
            if (!this.alive[f]) {
                continue;
            }
            for (let s = 0; s < 6; s++) {
                let b = base + s;
                if (!this.alive[b]) {
                    continue;
                }
                let dx = this.ex[f] - this.ex[b], dz = this.ez[f] - this.ez[b];
                let d = dx * dx + dz * dz;
                let hx = this.ex[f] - HALL_X[t], hz = this.ez[f] - HALL_Z[t];
                if (d < 7.0 * 7.0 && d < td && hx * hx + hz * hz < 9.0 * 9.0) {
                    td = d;
                    threat = f;
                }
            }
        }
        for (let s = 11; s < 20; s++) {
            let e = base + s;
            if (!this.alive[e]) {
                continue;
            }
            if (this.wave[e]) {
                // a wave whose march ended goes for the nearest building
                if (this.state[e] == S_IDLE) {
                    let b = this.nearestEnemyBuilding(e);
                    if (b >= 0) {
                        this.orderAttack(e, b);
                        this.wave[e] = true;
                    }
                }
                continue;
            }
            if (threat >= 0) {
                if (this.state[e] != S_ATTACK) {
                    this.orderAttack(e, threat);
                    this.leash[e] = 9.5;
                    this.homeX[e] = HALL_X[t];
                    this.homeZ[e] = HALL_Z[t];
                }
            } else if (this.state[e] == S_IDLE) {
                let dx = this.ex[e] - RALLY_X[t], dz = this.ez[e] - RALLY_Z[t];
                if (dx * dx + dz * dz > 2.6 * 2.6) {
                    this.orderMove(e, RALLY_X[t] + api.range(-0.9, 0.9), RALLY_Z[t] + api.range(-0.9, 0.9));
                }
            }
        }
        // a wave when it is time and the army is big enough; everything at once when the barracks
        // has nothing left to give
        // a call to arms: with the hall under attack and few soldiers home, the workers fight too
        let raider = -1;
        let rd = 1e9;
        for (let f = o0 + 6; f < o0 + 20; f++) {
            if (!this.alive[f]) {
                continue;
            }
            let dx = this.ex[f] - HALL_X[t], dz = this.ez[f] - HALL_Z[t];
            let d = dx * dx + dz * dz;
            if (d < 4.2 * 4.2 && d < rd) {
                rd = d;
                raider = f;
            }
        }
        if (raider >= 0 && homeArmy < 3) {
            for (let s = 6; s < 11; s++) {
                let e = base + s;
                if (this.alive[e] && this.state[e] != S_ATTACK && this.state[e] != S_BUILD) {
                    let r = this.res[e];
                    this.orderAttack(e, raider);
                    this.res[e] = r;   // back to the same work after (afterTarget)
                    this.leash[e] = 5.0;
                    this.homeX[e] = HALL_X[t];
                    this.homeZ[e] = HALL_Z[t];
                }
            }
        }
        let foes = 0;
        for (let f = o0 + 11; f < o0 + 20; f++) {
            if (this.alive[f]) {
                foes++;
            }
        }
        let onTime = threat < 0 && this.mt >= this.nextWave[t] && homeArmy >= this.waveSize[t];
        // pressing an advantage: clearly more soldiers than the enemy has left
        let advantage = threat < 0 && this.mt >= (api.demo ? 170 : 90) && homeArmy >= 4 && homeArmy >= foes + 3;
        let canGrow = false;
        for (let s = 11; s < 20; s++) {
            if (!this.alive[base + s] && this.deadT[base + s] <= 0 && (SLOT_KIND[s] == K_MELEE || this.wood[t] >= 25)) {
                canGrow = true;
            }
        }
        let allIn = this.mt >= this.nextWave[t] && (homeArmy >= 7 || (!canGrow && homeArmy >= 4 && threat < 0));
        if (onTime || advantage || allIn) {
            let ford = api.rand() < 0.5 ? 0 : 1;
            let far = 0.0;
            for (let s = 11; s < 20; s++) {
                let e = base + s;
                if (this.alive[e] && !this.wave[e]) {
                    let dx = this.ex[e] - FORD_X[ford], dz = this.ez[e] - FORD_Z[ford];
                    far = Math.max(far, Math.sqrt(dx * dx + dz * dz));
                }
            }
            this.waveGo[t] = this.mt + far * 1.3 / 1.3 + 2.0;
            for (let s = 11; s < 20; s++) {
                let e = base + s;
                if (!this.alive[e] || this.wave[e]) {
                    continue;
                }
                this.orderAMove(e, FORD_X[ford] + api.range(-0.3, 0.3), FORD_Z[ford] + api.range(-0.3, 0.3));
                this.hasG2[e] = true;
                this.g2x[e] = HALL_X[1 - t];
                this.g2z[e] = HALL_Z[1 - t];
                this.wave[e] = true;
            }
            this.waveN[t]++;
            // waves grow to six; late in a long match they come smaller and more often
            this.waveSize[t] = min<i32>(6, this.waveSize[t] + 1);
            this.nextWave[t] = this.mt + 48 + api.range(0, 14);
            if (t == 1 && !api.demo) {
                this.say("THE WARBAND MARCHES!");
                api.note(45, 0.7, 0.4, SFX_BELL);
                api.note(45, 0.7, 0.4, SFX_BELL, 0.4);
                api.note(52, 0.8, 0.4, SFX_BELL, 0.8);
            }
        }
    }

    enqueue(b: i32, k: i32): bool {
        let t = this.team[b];
        let s = t * 7 + k;
        if (this.qLen[b] >= 5 || this.gold[t] < <f64>COST_G[s] || this.wood[t] < <f64>COST_W[s]) {
            return false;
        }
        this.gold[t] -= <f64>COST_G[s];
        this.wood[t] -= <f64>COST_W[s];
        this.queue[b * 5 + this.qLen[b]] = k;
        this.qLen[b]++;
        return true;
    }

    aiBuild(api: GameApi, t: i32, k: i32): void {
        let spot = k == K_BARR ? 0 : (k == K_TOWER ? (this.alive[t * 20 + 2] ? 2 : 1) : (this.alive[t * 20 + 4] ? 4 : 3));
        let sgn = t == 0 ? 1.0 : -1.0;
        let x = SPOT_X[spot] * sgn, z = SPOT_Z[spot] * sgn;
        let s = t * 7 + k;
        if (!this.siteFree(x, z, RAD[s])) {
            // somewhere near it, a few tries
            let ok = false;
            for (let i = 0; i < 6 && !ok; i++) {
                let nx = x + api.range(-1.5, 1.5), nz = z + api.range(-1.5, 1.5);
                if (this.siteFree(nx, nz, RAD[s])) {
                    x = nx;
                    z = nz;
                    ok = true;
                }
            }
            if (!ok) {
                return;
            }
        }
        let w = this.pickWorker(t, x, z, false);
        if (w < 0) {
            return;
        }
        let b = this.placeBuilding(t, k, x, z, false);
        if (b < 0) {
            return;
        }
        this.gold[t] -= <f64>COST_G[s];
        this.wood[t] -= <f64>COST_W[s];
        this.orderBuild(w, b);
    }

    // a worker for a job: one of the selected ones when asked, else the nearest not carrying
    pickWorker(t: i32, x: f64, z: f64, selectedOnly: bool): i32 {
        let best = -1;
        let bd = 1e9;
        for (let s = 6; s < 11; s++) {
            let e = t * 20 + s;
            if (!this.alive[e] || (selectedOnly && !this.sel[e]) || this.state[e] == S_BUILD) {
                continue;
            }
            let dx = this.ex[e] - x, dz = this.ez[e] - z;
            let d = dx * dx + dz * dz + (this.cargo[e] != 0 ? 20.0 : 0.0);
            if (d < bd) {
                bd = d;
                best = e;
            }
        }
        return best;
    }

    siteFree(x: f64, z: f64, r: f64): bool {
        if (x - r < PX0 + 0.1 || x + r > PX1 - 0.1 || z - r < PZ0 + 0.1 || z + r > PZ1 - 0.1) {
            return false;
        }
        for (let a = 0; a < 12; a++) {
            let ang = <f64>a * Math.PI / 6;
            for (let q = 0; q < 2; q++) {
                let rr = q == 0 ? r : r * 0.5;
                if (this.blocked(x + Math.cos(ang) * rr, z + Math.sin(ang) * rr)) {
                    return false;
                }
            }
        }
        if (this.blocked(x, z)) {
            return false;
        }
        return true;
    }

    // ================================================================ input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (api.demo) {
            return false;
        }
        this.curX = x;
        this.curY = y;
        if (kind == POINTER_DOWN) {
            this.isDown = true;
            this.dragging = false;
            this.downX = x;
            this.downY = y;
            this.downOnPanel = y >= PANEL_Y;
            if (this.mode == M_PLACE && !this.downOnPanel) {
                this.ghostAt(api, x, y);
            }
            return true;
        }
        if (kind == POINTER_MOVE) {
            // the building's ghost follows the pointer (and a finger while it drags)
            if (this.mode == M_PLACE && y < PANEL_Y) {
                this.ghostAt(api, x, y);
            }
            if (this.isDown && this.mode == M_NONE && !this.downOnPanel) {
                let dx = x - this.downX, dy = y - this.downY;
                if (dx * dx + dy * dy > 16) {
                    this.dragging = true;
                }
            }
            return true;
        }
        if (kind == POINTER_UP) {
            if (!this.isDown) {
                return true;
            }
            this.isDown = false;
            if (this.dragging) {
                this.dragging = false;
                this.boxSelect(api, this.downX, this.downY, x, y);
                return true;
            }
            this.click(api, x, y);
        }
        return true;
    }

    ghostAt(api: GameApi, x: f32, y: f32): void {
        if (api.pick(x, y, 0)) {
            this.ghostX = <f64>api.hitX;
            this.ghostZ = <f64>api.hitZ;
            this.ghostOn = true;
            this.checkGhost();
        }
    }

    checkGhost(): void {
        let s = this.placeKind;
        let ok = this.siteFree(this.ghostX, this.ghostZ, RAD[s]);
        let dx = this.ghostX - HALL_X[0], dz = this.ghostZ - HALL_Z[0];
        if (dx * dx + dz * dz > 8.5 * 8.5) {
            ok = false;
        }
        this.ghostOk = ok;
    }

    boxSelect(api: GameApi, x0: f32, y0: f32, x1: f32, y1: f32): void {
        let ax = Mathf.min(x0, x1), bx = Mathf.max(x0, x1);
        let ay = Mathf.min(y0, y1), by = Mathf.max(y0, y1);
        let n = 0;
        for (let e = 6; e < 20; e++) {
            this.sel[e] = false;
            if (!this.alive[e]) {
                continue;
            }
            if (api.project(<f32>this.ex[e], 0.4, <f32>this.ez[e])) {
                if (api.screenX >= ax - 2 && api.screenX <= bx + 2 && api.screenY >= ay - 2 && api.screenY <= by + 4) {
                    this.sel[e] = true;
                    n++;
                }
            }
        }
        this.selB = -1;
        this.selRes = -1;
        if (n > 0) {
            this.ackSelection(api);
        }
    }

    // what is under the pointer: an entity (units first), or a resource (-10 - r), or -1
    hitTest(api: GameApi, x: f32, y: f32): i32 {
        let best = -1;
        let bd: f32 = 1e9;
        for (let e = 0; e < NE; e++) {
            if (!this.alive[e]) {
                continue;
            }
            let s = this.st(e);
            if (this.isUnit(e)) {
                if (!api.project(<f32>this.ex[e], 0.42, <f32>this.ez[e])) {
                    continue;
                }
                let dx = x - api.screenX, dy = y - api.screenY;
                if (Mathf.abs(dx) <= 7 && dy >= -10 && dy <= 7) {
                    let d = dx * dx + dy * dy;
                    if (d < bd) {
                        bd = d;
                        best = e;
                    }
                }
            }
        }
        if (best >= 0) {
            return best;
        }
        for (let e = 0; e < NE; e++) {
            if (!this.alive[e] || this.isUnit(e)) {
                continue;
            }
            let s = this.st(e);
            let h = <f32>(HGT[s] * (this.prog[e] < 1 ? 0.5 : 1.0));
            if (!api.project(<f32>this.ex[e], 0, <f32>this.ez[e])) {
                continue;
            }
            let bx = api.screenX, by = api.screenY;
            let rw = <f32>(RAD[s] / 0.06) * 0.95;
            let top = by - h * 0.79 / 0.06 - 2;
            if (Mathf.abs(x - bx) <= rw && y >= top && y <= by + rw * 0.55) {
                let d = Mathf.abs(x - bx) + Mathf.abs(y - (by + top) * 0.5);
                if (d < bd) {
                    bd = d;
                    best = e;
                }
            }
        }
        if (best >= 0) {
            return best;
        }
        for (let r = 0; r < 8; r++) {
            if (this.resAmt[r] <= 0) {
                continue;
            }
            if (!api.project(<f32>RES_X[r], 0, <f32>RES_Z[r])) {
                continue;
            }
            let rw: f32 = r >= 6 ? 16 : 14;
            let top = api.screenY - (r >= 6 ? 14 : 24);
            if (Mathf.abs(x - api.screenX) <= rw && y >= top && y <= api.screenY + 7) {
                return -10 - r;
            }
        }
        return -1;
    }

    selectedUnits(onlyWorkers: bool): i32 {
        let n = 0;
        for (let e = 6; e < 20; e++) {
            if (this.sel[e] && this.alive[e] && (!onlyWorkers || this.kind[e] == K_WORKER)) {
                n++;
            }
        }
        return n;
    }

    clearSel(): void {
        for (let e = 0; e < NE; e++) {
            this.sel[e] = false;
        }
        this.selB = -1;
        this.selRes = -1;
    }

    click(api: GameApi, x: f32, y: f32): void {
        if (this.over) {
            if (api.time - this.overAt > 0.8) {
                this.reset(api);
                api.sound(SFX_WIN, 1.2, 0.4);
            }
            return;
        }
        if (y >= PANEL_Y) {
            this.panelClick(api, x, y);
            return;
        }
        if (this.mode == M_PLACE) {
            this.ghostAt(api, x, y);
            if (!this.ghostOn) {
                return;
            }
            let s = this.placeKind;
            let k = s % 7;
            if (!this.ghostOk) {
                this.say("CAN'T BUILD THERE");
                this.error(api);
                return;
            }
            if (this.gold[0] < <f64>COST_G[s] || this.wood[0] < <f64>COST_W[s]) {
                this.say("NOT ENOUGH " + (this.gold[0] < <f64>COST_G[s] ? "GOLD" : "WOOD"));
                this.error(api);
                this.mode = M_NONE;
                return;
            }
            let w = this.pickWorker(0, this.ghostX, this.ghostZ, true);
            if (w < 0) {
                w = this.pickWorker(0, this.ghostX, this.ghostZ, false);
            }
            if (w < 0) {
                this.say("NO YEOMAN TO BUILD IT");
                this.error(api);
                this.mode = M_NONE;
                return;
            }
            let b = this.placeBuilding(0, k, this.ghostX, this.ghostZ, false);
            if (b < 0) {
                this.mode = M_NONE;
                return;
            }
            this.gold[0] -= <f64>COST_G[s];
            this.wood[0] -= <f64>COST_W[s];
            this.orderBuild(w, b);
            this.mode = M_NONE;
            this.ghostOn = false;
            api.soundAt(SFX_THUD, this.ghostX, 0, this.ghostZ, 1.1, 0.5);
            this.ack(api, K_WORKER, 0.9, 0.05);
            this.say("THE YEOMAN GOES TO BUILD");
            return;
        }
        let hit = this.hitTest(api, x, y);
        let nUnits = this.selectedUnits(false);
        if (this.mode == M_ATTACK) {
            this.mode = M_NONE;
            if (hit >= 20) {
                this.commandAttack(api, hit);
            } else if (api.pick(x, y, 0)) {
                this.commandMove(api, <f64>api.hitX, <f64>api.hitZ, true);
            }
            return;
        }
        if (hit >= 0 && hit < 20) {
            // one of ours
            if (this.isUnit(hit)) {
                this.clearSel();
                this.sel[hit] = true;
                this.ackSelection(api);
            } else if (this.prog[hit] < 1 && this.selectedUnits(true) > 0) {
                for (let e = 6; e < 11; e++) {
                    if (this.sel[e] && this.alive[e]) {
                        this.orderBuild(e, hit);
                    }
                }
                this.ack(api, K_WORKER, 0.9, 0);
            } else {
                this.clearSel();
                this.selB = hit;
                api.sound(SFX_CLICK, 0.6, 0.5);
            }
            return;
        }
        if (hit >= 20) {
            if (nUnits > 0) {
                this.commandAttack(api, hit);
            } else {
                this.clearSel();
                this.selB = hit;
                api.sound(SFX_BLIP, 0.7, 0.35);
            }
            return;
        }
        if (hit <= -10) {
            let r = -10 - hit;
            if (this.selectedUnits(true) > 0) {
                for (let e = 6; e < 11; e++) {
                    if (this.sel[e] && this.alive[e]) {
                        this.orderGather(e, r);
                    }
                }
                this.ack(api, K_WORKER, 1.0, 0);
                api.sound(SFX_TICK, 1.2, 0.4);
                this.markX = RES_X[r];
                this.markZ = RES_Z[r];
                this.markT = 0;
                this.markAtk = false;
                if (nUnits > this.selectedUnits(true) && api.pick(x, y, 0)) {
                    this.commandMove(api, <f64>api.hitX, <f64>api.hitZ, false);
                }
                return;
            }
            if (nUnits > 0 && api.pick(x, y, 0)) {
                this.commandMove(api, <f64>api.hitX, <f64>api.hitZ, false);
                return;
            }
            this.clearSel();
            this.selRes = r;
            api.sound(SFX_BLIP, 1.4, 0.3);
            return;
        }
        // the ground
        if (nUnits > 0 && api.pick(x, y, 0)) {
            this.commandMove(api, <f64>api.hitX, <f64>api.hitZ, false);
            return;
        }
        if (this.selB >= 0 || this.selRes >= 0) {
            this.clearSel();
        }
    }

    commandMove(api: GameApi, x: f64, z: f64, attack: bool): void {
        let k = 0;
        let firstKind = -1;
        for (let e = 6; e < 20; e++) {
            if (!this.sel[e] || !this.alive[e]) {
                continue;
            }
            // a loose block round the point
            let ring = k == 0 ? 0.0 : (k < 7 ? 0.62 : 1.2);
            let a = <f64>k * 1.0472 + (k >= 7 ? 0.5 : 0.0);
            let tx = x + Math.cos(a) * ring, tz = z + Math.sin(a) * ring;
            if (this.blocked(tx, tz)) {
                tx = x;
                tz = z;
            }
            if (attack && this.kind[e] != K_WORKER) {
                this.orderAMove(e, tx, tz);
            } else {
                this.orderMove(e, tx, tz);
            }
            if (firstKind < 0) {
                firstKind = this.kind[e];
            }
            k++;
        }
        this.markX = x;
        this.markZ = z;
        this.markT = 0;
        this.markAtk = attack;
        if (firstKind >= 0) {
            this.ack(api, firstKind, attack ? 0.85 : 0.94, 0);
            api.sound(SFX_BLIP, attack ? 0.8 : 1.2, 0.3);
        }
    }

    commandAttack(api: GameApi, f: i32): void {
        let firstKind = -1;
        for (let e = 6; e < 20; e++) {
            if (!this.sel[e] || !this.alive[e]) {
                continue;
            }
            this.orderAttack(e, f);
            if (firstKind < 0) {
                firstKind = this.kind[e];
            }
        }
        this.markX = this.ex[f];
        this.markZ = this.ez[f];
        this.markT = 0;
        this.markAtk = true;
        if (firstKind >= 0) {
            this.ack(api, firstKind, 0.8, 0);
            api.note(64, 0.35, 0, SFX_NOTE, 0.08);
            api.note(60, 0.35, 0, SFX_NOTE, 0.16);
        }
    }

    // the acknowledgement of a unit type: a yeoman's two plucked notes, a swordsman's steel and a
    // low call, an archer's high pluck; pitch: a command plays it a little lower than a selection
    ack(api: GameApi, k: i32, pitch: f64, delay: f64): void {
        let p = 12 * Math.log(pitch) / Math.log(2);
        if (k == K_WORKER) {
            api.note(72 + p, 0.4, 0, SFX_NOTE, delay);
            api.note(76 + p, 0.35, 0, SFX_NOTE, delay + 0.08);
        } else if (k == K_MELEE) {
            api.sound(SFX_CLICK, 1.3 * pitch, 0.4, 0, delay);
            api.note(67 + p, 0.4, 0, SFX_NOTE, delay + 0.05);
            api.note(62 + p, 0.35, 0, SFX_NOTE, delay + 0.14);
        } else {
            api.note(79 + p, 0.4, 0, SFX_NOTE, delay);
            api.note(84 + p, 0.3, 0, SFX_NOTE, delay + 0.07);
        }
    }

    ackSelection(api: GameApi): void {
        for (let e = 6; e < 20; e++) {
            if (this.sel[e]) {
                this.ack(api, this.kind[e], 1.0, 0);
                return;
            }
        }
    }

    error(api: GameApi): void {
        api.sound(SFX_TICK, 0.5, 0.6);
        api.note(48, 0.4, 0, SFX_NOTE, 0.05);
    }

    // ---------------------------------------------------------------- the panel's buttons

    // the button in slot i (0-4): a kind to build (100 + team-kind), to train (200 + kind), or
    // 300 attack, 301 army, -1 none
    button(i: i32): i32 {
        let b = this.selB;
        if (b >= 0 && b < 20 && this.alive[b] && this.prog[b] >= 1) {
            if (this.kind[b] == K_HALL) {
                return i == 0 ? 200 + K_WORKER : (i == 1 ? 100 + K_BARR : (i == 2 ? 100 + K_TOWER : (i == 3 ? 100 + K_FARM : 301)));
            }
            if (this.kind[b] == K_BARR) {
                return i == 0 ? 200 + K_MELEE : (i == 1 ? 200 + K_RANGED : (i == 4 ? 301 : -1));
            }
        }
        let army = 0;
        for (let e = 11; e < 20; e++) {
            if (this.sel[e] && this.alive[e]) {
                army++;
            }
        }
        if (army > 0) {
            return i == 0 ? 300 : (i == 4 ? 301 : -1);
        }
        return i == 0 ? 100 + K_BARR : (i == 1 ? 100 + K_TOWER : (i == 2 ? 100 + K_FARM : (i == 4 ? 301 : -1)));
    }

    buttonEnabled(c: i32): bool {
        if (c >= 200 && c < 300) {
            let s = c - 200;
            return this.gold[0] >= <f64>COST_G[s] && this.wood[0] >= <f64>COST_W[s] && this.qLen[this.selB] < 5;
        }
        if (c >= 100 && c < 200) {
            let s = c - 100;
            if (s == K_BARR && this.alive[1]) {
                return false;
            }
            if (s == K_TOWER && this.alive[2] && this.alive[3]) {
                return false;
            }
            if (s == K_FARM && this.alive[4] && this.alive[5]) {
                return false;
            }
            return this.gold[0] >= <f64>COST_G[s] && this.wood[0] >= <f64>COST_W[s];
        }
        if (c == 301) {
            for (let e = 11; e < 20; e++) {
                if (this.alive[e]) {
                    return true;
                }
            }
            return false;
        }
        return c == 300;
    }

    panelClick(api: GameApi, x: f32, y: f32): void {
        if (this.mode != M_NONE) {
            this.mode = M_NONE;
            this.ghostOn = false;
        }
        for (let i = 0; i < 5; i++) {
            let bx = BTN_X + <f32>i * (BTN_W + 1);
            if (x < bx || x >= bx + BTN_W || y < PANEL_Y + 2) {
                continue;
            }
            let c = this.button(i);
            if (c < 0) {
                return;
            }
            if (!this.buttonEnabled(c)) {
                this.error(api);
                if (c >= 100 && c < 300) {
                    let s = c % 100;
                    let maxed = (c < 200) && ((s == K_BARR && this.alive[1]) || (s == K_TOWER && this.alive[2] && this.alive[3]) ||
                        (s == K_FARM && this.alive[4] && this.alive[5]));
                    this.say(maxed ? "NO MORE OF THOSE" : (this.gold[0] < <f64>COST_G[s] ? "NOT ENOUGH GOLD" : "NOT ENOUGH WOOD"));
                }
                return;
            }
            api.sound(SFX_BLIP, 1.0, 0.4);
            if (c >= 200 && c < 300) {
                let k = c - 200;
                this.enqueue(this.selB, k);
                if (this.supplyUsed(0) + this.queuedAll(0) > this.supplyCap(0)) {
                    this.say("BUILD A COTTAGE FOR MORE SUPPLY");
                } else {
                    this.say("TRAINING " + NAMES[k]);
                }
            } else if (c >= 100 && c < 200) {
                this.mode = M_PLACE;
                this.placeKind = c - 100;
                this.ghostOn = false;
                this.say("TAP WHERE TO BUILD THE " + NAMES[c - 100]);
            } else if (c == 300) {
                this.mode = M_ATTACK;
                this.say("TAP WHERE TO ATTACK");
            } else if (c == 301) {
                this.clearSel();
                for (let e = 11; e < 20; e++) {
                    this.sel[e] = this.alive[e];
                }
                this.ackSelection(api);
            }
            return;
        }
    }

    queuedAll(t: i32): i32 {
        let n = 0;
        for (let s = 0; s < 6; s++) {
            n += this.qLen[t * 20 + s];
        }
        return n;
    }

    // ================================================================ drawing the bones

    draw(api: GameApi, dt: f64): void {
        for (let e = 0; e < NE; e++) {
            let b = this.bone[e];
            if (!this.alive[e]) {
                if (this.deadT[e] > 0) {
                    this.drawDead(api, e);
                } else {
                    api.hide(b);
                }
                continue;
            }
            if (this.isUnit(e)) {
                this.drawUnit(api, e);
            } else {
                this.drawBuilding(api, e);
            }
        }
        // carried loads ride on their worker: a sack on the back, logs on the shoulder
        for (let e = 0; e < NE; e++) {
            if (!this.alive[e] || this.kind[e] != K_WORKER) {
                continue;
            }
            if (this.cargo[e] != 0 && this.carryB[e] < 0) {
                let k0 = this.cargo[e] == 1 ? 0 : 3;
                for (let k = k0; k < k0 + 3; k++) {
                    if (this.carryOwner[k] < 0) {
                        this.carryOwner[k] = e;
                        this.carryB[e] = k;
                        break;
                    }
                }
            }
        }
        for (let k = 0; k < 6; k++) {
            let o = this.carryOwner[k];
            let cb = this.carryBone[k];
            if (o < 0 || !this.alive[o]) {
                this.carryOwner[k] = -1;
                api.hide(cb);
                continue;
            }
            let ub = this.bone[o];
            let isOrc = this.team[o] == 1;
            if (k < 3) {
                api.transform(ub, api.restX[ub], api.restY[ub] + (isOrc ? 0.5 : 0.56), api.restZ[ub] - 0.22);
            } else {
                api.transform(ub, api.restX[ub] + 0.12, api.restY[ub] + (isOrc ? 0.68 : 0.78), api.restZ[ub] - 0.02);
            }
            api.place(cb, api.tx, api.ty, api.tz, this.yaw[o] + (k < 3 ? 0.0 : 90.0), 0, k < 3 ? 0.0 : 8.0);
        }
        // scaffolds round the building sites
        for (let k = 0; k < 3; k++) {
            let o = this.scafOwner[k];
            if (o < 0 || !this.alive[o]) {
                this.scafOwner[k] = -1;
                api.hide(this.scafBone[k]);
                continue;
            }
            let r = RAD[this.st(o)];
            let s = Math.min(1.0, (r + 0.08) / 1.04);
            let sy = Math.min(1.0, HGT[this.st(o)] / 1.9 + 0.1);
            api.placeScaled(this.scafBone[k], this.ex[o], 0, this.ez[o], this.yaw[o], s, sy, s);
        }
    }

    drawUnit(api: GameApi, e: i32): void {
        let b = this.bone[e];
        let x = this.ex[e], z = this.ez[e], yw = this.yaw[e];
        let moving = Math.abs(this.vx[e]) + Math.abs(this.vz[e]) > 0.05;
        let y = 0.0, pitch = 0.0, roll = 0.0;
        let sx = 1.0, sy = 1.0;
        if (moving) {
            // a stepped trot: a bob and a rock from side to side
            let ph = stepped(this.walk[e], 0.75);
            y = Math.abs(Math.sin(ph)) * 0.07;
            roll = Math.sin(ph) * 6;
        }
        if (this.swing[e] > 0) {
            // a lunge or a tool's swing: lean in, then back
            let u = this.swing[e] / 0.28;
            pitch = (u > 0.5 ? (1 - u) : u) * 2 * (this.kind[e] == K_RANGED ? -10 : 22);
        }
        if (this.hurt[e] > 0) {
            sx = 1.1;
            sy = 0.88;
        }
        if (this.popT[e] > 0) {
            let u = 1 - this.popT[e] / 0.25;
            sy = 0.6 + 0.4 * u;
            sx = 1.2 - 0.2 * u;
        }
        if (sx != 1.0 || sy != 1.0) {
            api.placeScaled(b, x, y, z, yw, sx, sy, sx, pitch, roll);
        } else {
            api.place(b, x, y, z, yw, pitch, roll);
        }
    }

    drawDead(api: GameApi, e: i32): void {
        let b = this.bone[e];
        let x = this.ex[e], z = this.ez[e];
        if (this.isUnit(e)) {
            // tips over, lies a moment, sinks away
            let age = 1.1 - this.deadT[e];
            let tip = stepped(Math.min(1, age / 0.3) * 90, 22.5);
            let sink = age > 0.6 ? (age - 0.6) * 0.9 : 0.0;
            api.place(b, x, -sink, z, this.yaw[e], 0, tip);
        } else {
            // a building collapses: it tilts and sinks into the dust in steps
            let age = 1.4 - this.deadT[e];
            let u = stepped(Math.min(1, age / 1.2), 0.125);
            let h = HGT[this.st(e)];
            api.placeScaled(b, x, -h * u * 0.9, z, this.yaw[e], 1 + 0.1 * u, 1 - 0.4 * u, 1 + 0.1 * u, 6 * u, -4 * u);
            if (this.deadT[e] <= 0.05) {
                api.hide(b);
            }
        }
    }

    drawBuilding(api: GameApi, e: i32): void {
        let b = this.bone[e];
        let h = HGT[this.st(e)];
        let y = 0.0;
        if (this.prog[e] < 1) {
            // rises out of the ground in five steps inside its scaffold
            let p = Math.floor(this.prog[e] * 5) / 5;
            y = -h * (1 - (0.15 + 0.85 * p));
            api.place(b, this.ex[e], y, this.ez[e], this.yaw[e]);
            return;
        }
        if (this.popT[e] > 0 || this.hurt[e] > 0) {
            let s = this.popT[e] > 0 ? 1 + this.popT[e] * 0.25 : 1.0;
            let sy = this.hurt[e] > 0 ? 0.97 : s;
            api.placeScaled(b, this.ex[e], 0, this.ez[e], this.yaw[e], s, sy, s);
            return;
        }
        api.place(b, this.ex[e], 0, this.ez[e], this.yaw[e]);
    }

    // ================================================================ the HUD

    hud(api: GameApi): void {
        let ink = api.rampColor(R_STEEL, 0);
        let panel = api.rampColor(R_STONE, 0);
        let edge = api.rampColor(R_STONE, 2);
        let white = api.rampColor(R_CREAM, 4);
        let dim = api.rampColor(R_STONE, 3);
        let goldC = api.rampColor(R_GOLD, 3);
        let woodC = api.rampColor(R_DIRT, 4);
        let green = api.rampColor(R_GRASS, 4);
        let red = api.rampColor(R_CRIMSON, 3);
        let blue = api.rampColor(R_ROYAL, 4);
        let w = <f32>api.hudW;
        let hh = <f32>api.hudH;

        // ---- in the world: rings, bars, the move marker, the ghost, effects
        for (let e = 0; e < NE; e++) {
            if (!this.alive[e]) {
                continue;
            }
            let s = this.st(e);
            let selected = this.sel[e] || this.selB == e;
            let damaged = this.hp[e] < HP[s] - 0.5;
            if (!selected && !damaged && this.prog[e] >= 1) {
                continue;
            }
            if (!api.project(<f32>this.ex[e], 0, <f32>this.ez[e])) {
                continue;
            }
            let sx = api.screenX, sy = api.screenY;
            let rx = <f32>(RAD[s] / 0.06) + (this.isUnit(e) ? 1 : 2);
            if (selected) {
                this.ring(api, sx, sy, rx, rx * 0.62, this.team[e] == 0 ? green : red);
            }
            let top = sy - <f32>(HGT[s] * 0.79 / 0.06) - 4;
            let bw: f32 = this.isUnit(e) ? 10 : 22;
            this.bar(api, sx - bw * 0.5, top, bw, <f32>(this.hp[e] / HP[s]), ink, green, goldC, red);
            if (this.prog[e] < 1 && this.team[e] == 0) {
                this.bar(api, sx - bw * 0.5, top + 3, bw, <f32>this.prog[e], ink, blue, blue, blue);
            }
        }
        if (this.selRes >= 0 && this.resAmt[this.selRes] > 0 && api.project(<f32>RES_X[this.selRes], 0, <f32>RES_Z[this.selRes])) {
            this.ring(api, api.screenX, api.screenY, 16, 10, goldC);
        }
        if (this.markT < 0.6 && api.project(<f32>this.markX, 0, <f32>this.markZ)) {
            let r = <f32>(5 - this.markT * 6);
            let c = this.markAtk ? red : green;
            this.ring(api, api.screenX, api.screenY, r + 1, (r + 1) * 0.62, c);
            api.rect(api.screenX, api.screenY, 1, 1, c);
        }
        if (this.mode == M_PLACE && this.ghostOn && api.project(<f32>this.ghostX, 0, <f32>this.ghostZ)) {
            let s = this.placeKind;
            let rr = <f32>(RAD[s] / 0.06);
            let c = this.ghostOk ? green : red;
            this.ring(api, api.screenX, api.screenY, rr, rr * 0.62, c);
            this.ring(api, api.screenX, api.screenY, rr - 2, (rr - 2) * 0.62, c);
            let label = SHORT[s];
            api.text(Mathf.floor(api.screenX - api.textWidth(label, 1) * 0.5), api.screenY - rr * 0.62 - 9, label, c, 1, ink);
        }
        for (let i = 0; i < 32; i++) {
            let age = this.fxAge[i];
            let k = this.fxKind[i];
            let life = k == 0 ? 0.18 : (k == 1 ? 0.7 : 0.9);
            if (age > life) {
                continue;
            }
            let yy = this.fxY[i] + (k >= 2 ? age * 0.9 : (k == 1 ? age * 0.6 : 0));
            if (!api.project(<f32>this.fxX[i], <f32>yy, <f32>this.fxZ[i])) {
                continue;
            }
            let px = Mathf.floor(api.screenX), py = Mathf.floor(api.screenY);
            if (k == 0) {
                let c = age < 0.09 ? api.rampColor(R_GLOW, 4) : api.rampColor(R_GLOW, 2);
                api.rect(px - 1, py, 3, 1, c);
                api.rect(px, py - 1, 1, 3, c);
                if (age < 0.09) {
                    api.rect(px - 2, py - 2, 1, 1, c);
                    api.rect(px + 2, py + 2, 1, 1, c);
                }
            } else if (k == 1) {
                let r = 2 + <i32>(age * 10);
                let c = api.rampColor(R_DIRT, age < 0.35 ? 5 : 4);
                for (let a = 0; a < 6; a++) {
                    let ang = <f32>a * 1.047 + <f32>i;
                    api.rect(px + <f32>Mathf.round(Mathf.cos(ang) * <f32>r), py + <f32>Mathf.round(Mathf.sin(ang) * <f32>r * 0.6), 2, 1, c);
                }
            } else {
                let s = k == 2 ? "+8" : "+8";
                api.text(px - 3, py, s, k == 2 ? goldC : woodC, 1, ink);
            }
        }

        // ---- the top bar: resources, supply, the clock
        api.rect(0, 0, w, 9, ink);
        this.icon(api, 3, 2, goldC, ink);
        api.text(9, 2, (<i32>this.gold[0]).toString(), goldC);
        this.logIcon(api, 34, 2, woodC);
        api.text(41, 2, (<i32>this.wood[0]).toString(), woodC);
        let su = this.supplyUsed(0), sc = this.supplyCap(0);
        api.text(66, 2, "SUPPLY " + su.toString() + "/" + sc.toString(), su >= sc ? red : white);
        let secs = <i32>this.mt;
        let clock = (secs / 60).toString() + ":" + (secs % 60 < 10 ? "0" : "") + (secs % 60).toString();
        api.text(w - 3 - api.textWidth(clock, 1), 2, clock, dim);
        let orcs = 0;
        for (let e = 26; e < 40; e++) {
            if (this.alive[e]) {
                orcs++;
            }
        }
        let os = "WARBAND " + orcs.toString();
        api.text(w - 26 - api.textWidth(os, 1), 2, os, red);

        // ---- the message line
        if (this.msgT > 0 && this.msg.length > 0 && !this.over) {
            let c = (this.msg.indexOf("ATTACK") >= 0 || this.msg.indexOf("MARCH") >= 0) ? red : white;
            api.textCentered(PANEL_Y - 9, this.msg, c, 1, ink);
        }

        // ---- the panel
        api.rect(0, PANEL_Y, w, hh - PANEL_Y, panel);
        api.rect(0, PANEL_Y, w, 1, edge);
        this.info(api, white, dim, goldC, woodC, green, red, blue, ink);
        for (let i = 0; i < 5; i++) {
            let c = this.button(i);
            let bx = BTN_X + <f32>i * (BTN_W + 1);
            let by = PANEL_Y + 2;
            if (c < 0) {
                continue;
            }
            let on = this.buttonEnabled(c);
            let active = (this.mode == M_PLACE && c == 100 + this.placeKind) || (this.mode == M_ATTACK && c == 300);
            api.rect(bx, by, BTN_W, BTN_H, active ? api.rampColor(R_ROYAL, 2) : (on ? api.rampColor(R_STONE, 1) : ink));
            api.rect(bx, by, BTN_W, 1, on ? edge : panel);
            let name = "";
            let cg = 0, cw = 0;
            if (c >= 200 && c < 300) {
                name = SHORT[c - 200];
                cg = COST_G[c - 200];
                cw = COST_W[c - 200];
            } else if (c >= 100 && c < 200) {
                name = SHORT[c - 100];
                cg = COST_G[c - 100];
                cw = COST_W[c - 100];
            } else if (c == 300) {
                name = "ATTACK";
            } else {
                name = "ARMY";
            }
            let tc = on ? white : dim;
            api.text(Mathf.floor(bx + (BTN_W - api.textWidth(name, 1)) * 0.5), by + 4, name, tc);
            if (cg > 0 || cw > 0) {
                let gs = cg.toString();
                let ws = cw > 0 ? cw.toString() : "";
                let tw = api.textWidth(gs, 1) + (cw > 0 ? 4 + api.textWidth(ws, 1) + 3 : 0) + 3;
                let x0 = Mathf.floor(bx + (BTN_W - tw) * 0.5);
                api.rect(x0, by + 15, 2, 2, on ? goldC : dim);
                api.text(x0 + 3, by + 13, gs, on ? goldC : dim);
                if (cw > 0) {
                    let x1 = x0 + 3 + api.textWidth(gs, 1) + 4;
                    api.rect(x1, by + 14, 1, 3, on ? woodC : dim);
                    api.rect(x1 + 1, by + 15, 1, 2, on ? woodC : dim);
                    api.text(x1 + 3, by + 13, ws, on ? woodC : dim);
                }
            } else if (c == 300) {
                api.text(Mathf.floor(bx + (BTN_W - api.textWidth("MOVE", 1)) * 0.5), by + 13, "MOVE", tc);
            } else {
                api.text(Mathf.floor(bx + (BTN_W - api.textWidth("SELECT", 1)) * 0.5), by + 13, "SELECT", tc);
            }
        }

        // ---- the hint before anything happens, and the result
        if (!api.demo && this.mt < 7 && !this.over && this.msgT <= 0) {
            api.textCentered(PANEL_Y - 9, "TAP OR DRAG TO SELECT, TAP TO COMMAND", white, 1, ink);
        }
        if (this.over) {
            this.result(api, w, white, dim, goldC, woodC, green, red, ink, panel, edge);
        }
        // the drag box
        if (this.dragging && this.isDown) {
            let ax = Mathf.min(this.downX, this.curX), bx2 = Mathf.max(this.downX, this.curX);
            let ay = Mathf.min(this.downY, this.curY), by2 = Mathf.max(this.downY, this.curY);
            api.rect(ax, ay, bx2 - ax + 1, 1, green);
            api.rect(ax, by2, bx2 - ax + 1, 1, green);
            api.rect(ax, ay, 1, by2 - ay + 1, green);
            api.rect(bx2, ay, 1, by2 - ay + 1, green);
        }
    }

    info(api: GameApi, white: u32, dim: u32, goldC: u32, woodC: u32, green: u32, red: u32, blue: u32, ink: u32): void {
        let x: f32 = 4;
        let y: f32 = PANEL_Y + 4;
        let n = 0;
        let one = -1;
        for (let e = 6; e < 20; e++) {
            if (this.sel[e] && this.alive[e]) {
                n++;
                one = e;
            }
        }
        if (n == 1 || (n == 0 && this.selB >= 0 && this.alive[this.selB])) {
            let e = n == 1 ? one : this.selB;
            let s = this.st(e);
            api.text(x, y, NAMES[s], this.team[e] == 0 ? white : red);
            let f = <f32>(this.hp[e] / HP[s]);
            api.rect(x, y + 8, 50, 3, ink);
            api.rect(x, y + 8, Mathf.max(1, Mathf.round(50 * f)), 3, f > 0.5 ? green : (f > 0.25 ? goldC : red));
            api.text(x + 54, y + 7, (<i32>Math.ceil(this.hp[e])).toString() + "/" + (<i32>HP[s]).toString(), dim);
            let line = "";
            if (this.prog[e] < 1 && !this.isUnit(e)) {
                line = "BUILDING " + (<i32>(this.prog[e] * 100)).toString() + "%";
            } else if (!this.isUnit(e) && this.qLen[e] > 0) {
                let k = this.queue[e * 5];
                let blockedS = this.supplyUsed(this.team[e]) + 1 > this.supplyCap(this.team[e]);
                line = (blockedS ? "NEEDS SUPPLY: " : "TRAINING ") + SHORT[this.team[e] * 7 + k];
                if (this.qLen[e] > 1) {
                    line += " +" + (this.qLen[e] - 1).toString();
                }
                let p = <f32>(this.trainT[e] / TIME[this.team[e] * 7 + k]);
                api.rect(x + 80, y + 1, 30, 3, ink);
                api.rect(x + 80, y + 1, Mathf.round(30 * p), 3, blue);
            } else if (this.kind[e] == K_WORKER) {
                line = this.cargo[e] == 1 ? "CARRYING GOLD" : (this.cargo[e] == 2 ? "CARRYING WOOD" :
                    (this.state[e] == S_BUILD ? "BUILDING" : (this.state[e] == S_GATHER ? (this.res[e] >= 6 ? "MINING GOLD" : "CUTTING WOOD") : "IDLE")));
            } else if (this.kind[e] == K_TOWER) {
                line = "SHOOTS WHAT COMES NEAR";
            } else if (this.kind[e] == K_FARM) {
                line = "+4 SUPPLY";
            } else if (this.isUnit(e)) {
                line = this.state[e] == S_ATTACK ? "FIGHTING" : (this.state[e] == S_IDLE ? "ON GUARD" : "MARCHING");
            }
            api.text(x, y + 15, line, dim);
            return;
        }
        if (n > 1) {
            api.text(x, y, n.toString() + " UNITS", white);
            let k = 0;
            for (let e = 6; e < 20; e++) {
                if (!this.sel[e] || !this.alive[e]) {
                    continue;
                }
                let bx = x + <f32>(k % 9) * 12;
                let by = y + 8 + <f32>(k / 9) * 7;
                let s = this.st(e);
                let c = this.kind[e] == K_WORKER ? goldC : (this.kind[e] == K_MELEE ? blue : green);
                api.rect(bx, by, 10, 5, ink);
                api.rect(bx + 1, by + 1, 8, 3, c);
                let f = <f32>(this.hp[e] / HP[s]);
                api.rect(bx + 1, by + 4, Mathf.max(1, Mathf.round(8 * f)), 1, f > 0.5 ? green : red);
                k++;
            }
            return;
        }
        if (this.selRes >= 0) {
            let r = this.selRes;
            api.text(x, y, r >= 6 ? "GOLD DEPOSIT" : "PINE GROVE", r >= 6 ? goldC : woodC);
            api.text(x, y + 9, (<i32>this.resAmt[r]).toString() + (r >= 6 ? " GOLD LEFT" : " WOOD LEFT"), dim);
            return;
        }
        api.text(x, y, "THE KINGDOM", white);
        api.text(x, y + 8, "DESTROY THE WARCAMP", dim);
        api.text(x, y + 15, "ACROSS THE RIVER", dim);
    }

    result(api: GameApi, w: f32, white: u32, dim: u32, goldC: u32, woodC: u32, green: u32, red: u32, ink: u32,
           panel: u32, edge: u32): void {
        let bw: f32 = 210, bh: f32 = 84;
        let bx = Mathf.floor((w - bw) * 0.5), by: f32 = 40;
        api.rect(bx, by, bw, bh, panel);
        api.rect(bx, by, bw, 1, edge);
        api.rect(bx, by + bh - 1, bw, 1, edge);
        api.rect(bx, by, 1, bh, edge);
        api.rect(bx + bw - 1, by, 1, bh, edge);
        let title = this.won ? "VICTORY" : "DEFEAT";
        if (api.demo) {
            title = this.won ? "KINGDOM WINS" : "WARBAND WINS";
        }
        api.textCentered(by + 6, title, this.won ? goldC : red, 3, ink);
        let secs = <i32>this.mt;
        let clock = (secs / 60).toString() + ":" + (secs % 60 < 10 ? "0" : "") + (secs % 60).toString();
        api.textCentered(by + 28, "TIME " + clock + "   KILLED " + this.killed[0].toString() + "   LOST " + this.lost[0].toString(), white);
        api.textCentered(by + 37, "GATHERED " + (<i32>this.gotGold[0]).toString() + " GOLD  " + (<i32>this.gotWood[0]).toString() + " WOOD", dim);
        api.textCentered(by + 50, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), goldC, 1, ink);
        if (this.newBest && this.score > 0) {
            api.textCentered(by + 59, "NEW BEST!", green);
        }
        if (!api.demo && api.time - this.overAt > 0.8) {
            api.textCentered(by + 71, "TAP TO PLAY AGAIN", white);
        }
    }

    ring(api: GameApi, cx: f32, cy: f32, rx: f32, ry: f32, c: u32): void {
        let n = <i32>Mathf.max(12, rx * 2.2);
        let lx: f32 = -999, ly: f32 = -999;
        for (let i = 0; i < n; i++) {
            let a = <f32>i / <f32>n * 6.2832;
            let px = Mathf.round(cx + Mathf.cos(a) * rx), py = Mathf.round(cy + Mathf.sin(a) * ry);
            if (px != lx || py != ly) {
                api.rect(px, py, 1, 1, c);
                lx = px;
                ly = py;
            }
        }
    }

    bar(api: GameApi, x: f32, y: f32, w: f32, f: f32, ink: u32, hi: u32, mid: u32, lo: u32): void {
        let fx = Mathf.floor(x);
        api.rect(fx - 1, y - 1, w + 2, 3, ink);
        let c = f > 0.5 ? hi : (f > 0.25 ? mid : lo);
        api.rect(fx, y, Mathf.max(1, Mathf.round(w * Mathf.max(0, Mathf.min(1, f)))), 1, c);
    }

    icon(api: GameApi, x: f32, y: f32, c: u32, ink: u32): void {
        api.rect(x + 1, y, 3, 5, c);
        api.rect(x, y + 1, 5, 3, c);
        api.rect(x + 2, y + 2, 1, 1, ink);
    }

    logIcon(api: GameApi, x: f32, y: f32, c: u32): void {
        api.rect(x, y + 1, 5, 2, c);
        api.rect(x + 1, y + 3, 5, 2, c);
    }
}

// ---------------------------------------------------------------- helpers

function riverDist(x: f64, z: f64): f64 {
    let best = 1e9;
    for (let i = 0; i + 3 < RIVER.length; i += 2) {
        let ax = RIVER[i], az = RIVER[i + 1], bx = RIVER[i + 2], bz = RIVER[i + 3];
        let dx = bx - ax, dz = bz - az;
        let L = dx * dx + dz * dz;
        let t = L > 0 ? ((x - ax) * dx + (z - az) * dz) / L : 0.0;
        t = t < 0 ? 0 : (t > 1 ? 1 : t);
        let qx = ax + dx * t - x, qz = az + dz * t - z;
        let d = Math.sqrt(qx * qx + qz * qz);
        if (d < best) {
            best = d;
        }
    }
    return best;
}

function fordDist(x: f64, z: f64): f64 {
    let best = 1e9;
    for (let i = 0; i < 2; i++) {
        let dx = x - FORD_X[i], dz = z - FORD_Z[i];
        best = Math.min(best, Math.sqrt(dx * dx + dz * dz));
    }
    return best;
}

function stepped(v: f64, step: f64): f64 {
    return Math.floor(v / step) * step;
}

function turnTo(from: f64, to: f64, maxStep: f64): f64 {
    let d = to - from;
    while (d > 180) { d -= 360; }
    while (d < -180) { d += 360; }
    if (d > maxStep) { d = maxStep; }
    if (d < -maxStep) { d = -maxStep; }
    return from + d;
}
