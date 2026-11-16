// Vale Guard: a tower defense. Creeps march out of a cave and down a winding dirt path to the village
// gate; tap a stone pad to build a tower there (a ring of four choices with their costs), tap a tower to
// upgrade it (three levels: it grows, then gilded standards rise round its pad) or sell it. Kills pay gold;
// a creep that reaches the gate costs lives. NEXT WAVE calls the next wave early for bonus gold. Survive
// fifteen waves (a moss troll every fifth). The next tap after the end starts the same valley again.
//
// Pointer only, taps only (touch-ready): every action is a press on a pad, a tower, a ring choice or the
// NEXT button; nothing needs hovering or dragging.
//
// World: glTF metres, Y up, x to the right of the screen, z towards the camera (yaw 0, pitch 40).
// Bones: 4 towers of each kind (16), 8 gilded standards, 20 creeps (8 mites, 4 skitters, 4 shellbacks,
// 3 moths, 1 troll), 11 projectiles (5 bolts, 3 balls, 3 shards), 4 hit puffs: 59 of 63.
import { GameApi, POINTER_DOWN, SFX_BELL, SFX_BLIP, SFX_CLICK, SFX_COIN, SFX_EXPLODE, SFX_HIT, SFX_LOSE, SFX_NOTE,
    SFX_POP, SFX_POWERUP, SFX_SHOOT, SFX_THUD, SFX_WHOOSH, SFX_WIN, SFX_ZAP } from "./game_api";

// <layout> written by models/env/make_env.py: the path every 0.25 m, the build pads
const NPATH: i32 = 139;
const PATH_X: StaticArray<f64> = [-5.750, -5.642, -5.526, -5.373, -5.160, -4.922, -4.675, -4.426, -4.177, -3.935, -3.698, -3.459, -3.214, -2.966, -2.716, -2.467, -2.219, -1.972, -1.724, -1.476, -1.227, -0.977, -0.727, -0.478, -0.228, 0.021, 0.270, 0.520, 0.769, 1.019, 1.269, 1.518, 1.767, 2.016, 2.262, 2.506, 2.745, 2.976, 3.194, 3.398, 3.584, 3.749, 3.883, 3.972, 4.017, 4.023, 3.989, 3.909, 3.780, 3.614, 3.421, 3.207, 2.980, 2.742, 2.496, 2.248, 1.998, 1.749, 1.499, 1.250, 1.000, 0.752, 0.504, 0.256, 0.007, -0.241, -0.490, -0.739, -0.989, -1.239, -1.488, -1.737, -1.986, -2.235, -2.484, -2.734, -2.984, -3.231, -3.477, -3.718, -3.953, -4.177, -4.381, -4.552, -4.688, -4.793, -4.864, -4.899, -4.885, -4.825, -4.731, -4.609, -4.462, -4.288, -4.088, -3.871, -3.642, -3.406, -3.166, -2.923, -2.678, -2.431, -2.184, -1.935, -1.686, -1.436, -1.187, -0.937, -0.687, -0.437, -0.188, 0.061, 0.310, 0.558, 0.805, 1.053, 1.301, 1.548, 1.796, 2.043, 2.289, 2.535, 2.781, 3.026, 3.268, 3.508, 3.747, 3.985, 4.225, 4.468, 4.715, 4.964, 5.213, 5.463, 5.713, 5.963, 6.213, 6.463, 6.600];
const PATH_Z: StaticArray<f64> = [-4.300, -4.075, -3.853, -3.657, -3.528, -3.452, -3.411, -3.398, -3.414, -3.475, -3.555, -3.629, -3.680, -3.700, -3.693, -3.668, -3.636, -3.600, -3.565, -3.535, -3.511, -3.500, -3.501, -3.512, -3.529, -3.548, -3.568, -3.587, -3.600, -3.605, -3.596, -3.580, -3.558, -3.529, -3.488, -3.434, -3.361, -3.264, -3.142, -2.998, -2.832, -2.644, -2.433, -2.200, -1.955, -1.705, -1.458, -1.221, -1.008, -0.821, -0.663, -0.533, -0.430, -0.355, -0.309, -0.280, -0.262, -0.248, -0.236, -0.221, -0.200, -0.173, -0.143, -0.112, -0.081, -0.054, -0.030, -0.011, -0.000, -0.002, -0.016, -0.038, -0.063, -0.088, -0.107, -0.114, -0.102, -0.067, -0.020, 0.045, 0.129, 0.240, 0.384, 0.566, 0.775, 1.002, 1.241, 1.488, 1.737, 1.980, 2.211, 2.429, 2.631, 2.810, 2.960, 3.083, 3.183, 3.265, 3.335, 3.395, 3.445, 3.486, 3.519, 3.546, 3.567, 3.582, 3.593, 3.599, 3.599, 3.590, 3.573, 3.549, 3.520, 3.488, 3.454, 3.420, 3.387, 3.352, 3.316, 3.278, 3.237, 3.193, 3.146, 3.094, 3.034, 2.964, 2.889, 2.813, 2.742, 2.686, 2.646, 2.621, 2.608, 2.598, 2.593, 2.593, 2.595, 2.599, 2.600];
const NPAD: i32 = 10;
const PAD_X: StaticArray<f64> = [-4.70, -2.10, 0.50, 5.05, -3.00, -0.50, 1.90, 4.30, -6.00, -1.90];
const PAD_Z: StaticArray<f64> = [-1.75, -1.85, -1.80, -1.90, 1.65, 1.75, 1.60, 0.60, 0.40, -5.00];
const GATE_X: f64 = 5.4;
const CAVE_X: f64 = -5.9;
const CAVE_Z: f64 = -4.5;
// </layout>

const STEP: f64 = 0.25;          // metres between path points
const PAD_TOP: f64 = 0.11;       // a tower stands on its pad's top

// ---------------------------------------------------------------- towers
const ARROW: i32 = 0;
const CANNON: i32 = 1;
const FROST: i32 = 2;
const STORM: i32 = 3;
const NKIND: i32 = 4;
const PERKIND: i32 = 4;          // pooled towers of each kind (bones)
const NSTD: i32 = 8;             // gilded standards (level 3 towers)
const T_NAME: Array<string> = ["ARROW", "CANNON", "FROST", "STORM"];
const T_BONE: Array<string> = ["loft", "keep", "well", "spire"];
const T_COST: StaticArray<i32> = [40, 70, 55, 90];
const T_UP: StaticArray<i32> = [45, 75, 65, 100, 50, 80, 80, 120];         // [kind * 2 + level]: to the next level
// per [kind * 3 + level]
const T_DMG: StaticArray<f64> = [9, 14, 21, 28, 44, 66, 5, 8, 12, 20, 31, 46];
const T_COOL: StaticArray<f64> = [0.55, 0.46, 0.38, 1.6, 1.45, 1.3, 0.95, 0.85, 0.75, 1.4, 1.2, 1.0];
const T_RANGE: StaticArray<f64> = [2.5, 2.75, 3.0, 2.4, 2.6, 2.85, 2.3, 2.5, 2.75, 2.5, 2.75, 3.0];
const T_SPLASH: StaticArray<f64> = [0, 0, 0, 0.8, 0.9, 1.05, 0, 0.45, 0.6, 0, 0, 0];
const T_SLOW: StaticArray<f64> = [1, 1, 1, 1, 1, 1, 0.55, 0.45, 0.35, 1, 1, 1];  // speed factor while chilled
const T_CHAIN: StaticArray<i32> = [1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 4, 5];
const T_SCALE: StaticArray<f64> = [0.8, 1.0, 1.0];                           // level 1 is smaller
// the towers are baked 1.2 times their models' size (their level-3 size): muzzle forward, height, the top
const T_MUZZLE_F: StaticArray<f64> = [0.72, 0.66, 0.0, 0.0];
const T_MUZZLE_H: StaticArray<f64> = [1.2, 1.38, 1.2, 1.8];
const T_TOP: StaticArray<f64> = [1.95, 1.56, 1.68, 2.04];

// ---------------------------------------------------------------- creeps
const MITE: i32 = 0;
const SKITTER: i32 = 1;
const SHELL: i32 = 2;
const MOTH: i32 = 3;
const TROLL: i32 = 4;
const NCREEP: i32 = 20;
const SLOT0: StaticArray<i32> = [0, 8, 12, 16, 19];       // first slot of each kind
const SLOTN: StaticArray<i32> = [8, 4, 4, 3, 1];
const C_BONE: Array<string> = ["mite", "skitter", "shell", "moth", "troll"];
const C_HP: StaticArray<f64> = [26, 38, 140, 52, 640];
const C_SPEED: StaticArray<f64> = [1.0, 1.85, 0.6, 1.0, 0.42];
const C_ARMOR: StaticArray<f64> = [0, 0, 6, 0, 4];
const C_GOLD: StaticArray<i32> = [4, 5, 10, 7, 60];
const C_LIVES: StaticArray<i32> = [1, 1, 2, 1, 5];
const C_PTS: StaticArray<i32> = [10, 15, 30, 20, 250];
const C_BAR: StaticArray<f64> = [0.62, 0.6, 0.85, 1.75, 1.75];   // HP bar height (creeps baked 1.3x, the troll 1.15x)
const MOTH_Y: f64 = 1.25;

// waves: groups "<kind letter><count>:<gap s>", m mite, s skitter, h shellback, f moth (flyer), t troll
const NWAVE: i32 = 15;
const HP_GROW: f64 = 0.28;     // creeps' HP grows by this much of the base each wave
const HP_LATE: f64 = 0.06;     // and from wave 8 on, compounding
const WAVES: Array<string> = [
    "m6:1.1",
    "m8:0.9",
    "m6:0.8 s3:0.8",
    "s4:0.7 m7:0.7",
    "m6:0.8 t1:0",
    "h3:1.6 m6:0.6",
    "f3:1.4 m6:0.6 s3:0.6",
    "h4:1.3 s4:0.6",
    "m8:0.5 f3:1.0 h2:1.5",
    "t1:0 h3:1.4 m8:0.5",
    "s4:0.5 s4:0.5 f3:1.0 m8:0.5",
    "h4:1.0 m8:0.4 f3:0.9",
    "s4:0.4 h4:1.0 m8:0.4 s4:0.4",
    "f3:0.8 h4:0.9 m8:0.4 f3:0.8",
    "t1:0 h4:1.0 m8:0.4 s4:0.4 f3:0.8"];
const FIRST_WAIT: f64 = 20.0;    // before wave 1
const BETWEEN: f64 = 10.0;       // from the end of a wave's spawning to the next wave
const START_GOLD: i32 = 110;
const START_LIVES: i32 = 20;

// ---------------------------------------------------------------- projectiles and effects
const NBOLT: i32 = 5;
const NBALL: i32 = 3;
const NSHARD: i32 = 3;
const NPROJ: i32 = 11;           // 0-4 bolts, 5-7 balls, 8-10 shards
const NPOP: i32 = 4;
const NLABEL: i32 = 8;
const NZAP: i32 = 4;

const PLAY: i32 = 0;
const WON: i32 = 1;
const LOST: i32 = 2;

// the ring choices (offsets from the pad's screen point, HUD pixels): build: up, right, down, left
const BOX_W: f32 = 34;
const BOX_H: f32 = 13;
const RING_DX: StaticArray<f32> = [-17, 18, -17, -52];
const RING_DY: StaticArray<f32> = [-31, -7, 11, -7];

// the demo's build order: (pad, kind); the central pads cover two runs of the path
const PLAN: StaticArray<i32> = [1, ARROW, 5, CANNON, 2, ARROW, 4, FROST, 6, STORM, 0, ARROW, 7, CANNON, 3, FROST, 8, STORM, 9, ARROW];

function clamp(x: f64, a: f64, b: f64): f64 { return x < a ? a : (x > b ? b : x); }
function deg(r: f64): f64 { return r * 180.0 / Math.PI; }
function hash(n: i32): f64 {
    let h = <u32>n * 2654435761;
    h ^= h >> 15;
    h *= 2246822519;
    h ^= h >> 13;
    return <f64>(h & 0xffff) / 65535.0;
}
function wrap180(a: f64): f64 {
    let x = a % 360.0;
    if (x > 180) x -= 360;
    if (x < -180) x += 360;
    return x;
}

export class Game {
    // ------------------------------------------------------------ bones
    towerB: StaticArray<i32> = new StaticArray<i32>(NKIND * PERKIND);
    towerUsed: StaticArray<bool> = new StaticArray<bool>(NKIND * PERKIND);
    stdB: StaticArray<i32> = new StaticArray<i32>(NSTD);
    stdUsed: StaticArray<bool> = new StaticArray<bool>(NSTD);
    creepB: StaticArray<i32> = new StaticArray<i32>(NCREEP);
    projB: StaticArray<i32> = new StaticArray<i32>(NPROJ);
    popB: StaticArray<i32> = new StaticArray<i32>(NPOP);

    // ------------------------------------------------------------ pads (a tower on each)
    pKind: StaticArray<i32> = new StaticArray<i32>(10);      // -1: empty
    pLvl: StaticArray<i32> = new StaticArray<i32>(10);
    pSlot: StaticArray<i32> = new StaticArray<i32>(10);      // index into towerB
    pStd: StaticArray<i32> = new StaticArray<i32>(10);       // standard index or -1
    pYaw: StaticArray<f64> = new StaticArray<f64>(10);
    pCool: StaticArray<f64> = new StaticArray<f64>(10);
    pSpent: StaticArray<i32> = new StaticArray<i32>(10);
    pBorn: StaticArray<f64> = new StaticArray<f64>(10);      // build / upgrade time (the pop-in)
    pFired: StaticArray<f64> = new StaticArray<f64>(10);
    pGone: StaticArray<f64> = new StaticArray<f64>(10);      // sold: shrinking out since
    pGoneSlot: StaticArray<i32> = new StaticArray<i32>(10);
    pGoneStd: StaticArray<i32> = new StaticArray<i32>(10);
    pGoneKind: StaticArray<i32> = new StaticArray<i32>(10);

    // ------------------------------------------------------------ creeps (slot = bone, fixed kind)
    cOn: StaticArray<bool> = new StaticArray<bool>(NCREEP);
    cKind: StaticArray<i32> = new StaticArray<i32>(NCREEP);
    cHp: StaticArray<f64> = new StaticArray<f64>(NCREEP);
    cMax: StaticArray<f64> = new StaticArray<f64>(NCREEP);
    cD: StaticArray<f64> = new StaticArray<f64>(NCREEP);       // metres along the path (or the moth's line)
    cLane: StaticArray<f64> = new StaticArray<f64>(NCREEP);
    cSlowT: StaticArray<f64> = new StaticArray<f64>(NCREEP);
    cSlowF: StaticArray<f64> = new StaticArray<f64>(NCREEP);
    cHitT: StaticArray<f64> = new StaticArray<f64>(NCREEP);
    cX: StaticArray<f64> = new StaticArray<f64>(NCREEP);
    cY: StaticArray<f64> = new StaticArray<f64>(NCREEP);
    cZ: StaticArray<f64> = new StaticArray<f64>(NCREEP);
    cYaw: StaticArray<f64> = new StaticArray<f64>(NCREEP);
    cWave: StaticArray<i32> = new StaticArray<i32>(NCREEP);
    cPhase: StaticArray<f64> = new StaticArray<f64>(NCREEP);
    cDead: StaticArray<bool> = new StaticArray<bool>(NCREEP);  // to hide this frame

    // ------------------------------------------------------------ projectiles
    jOn: StaticArray<bool> = new StaticArray<bool>(NPROJ);
    jT: StaticArray<f64> = new StaticArray<f64>(NPROJ);        // seconds in flight
    jDur: StaticArray<f64> = new StaticArray<f64>(NPROJ);      // balls: flight time
    jX: StaticArray<f64> = new StaticArray<f64>(NPROJ);
    jY: StaticArray<f64> = new StaticArray<f64>(NPROJ);
    jZ: StaticArray<f64> = new StaticArray<f64>(NPROJ);
    jX0: StaticArray<f64> = new StaticArray<f64>(NPROJ);
    jY0: StaticArray<f64> = new StaticArray<f64>(NPROJ);
    jZ0: StaticArray<f64> = new StaticArray<f64>(NPROJ);
    jX1: StaticArray<f64> = new StaticArray<f64>(NPROJ);
    jZ1: StaticArray<f64> = new StaticArray<f64>(NPROJ);
    jTarget: StaticArray<i32> = new StaticArray<i32>(NPROJ);
    jPad: StaticArray<i32> = new StaticArray<i32>(NPROJ);
    jYaw: StaticArray<f64> = new StaticArray<f64>(NPROJ);
    jPitch: StaticArray<f64> = new StaticArray<f64>(NPROJ);
    jWasOn: StaticArray<bool> = new StaticArray<bool>(NPROJ);

    // ------------------------------------------------------------ effects
    oT: StaticArray<f64> = new StaticArray<f64>(NPOP);
    oX: StaticArray<f64> = new StaticArray<f64>(NPOP);
    oY: StaticArray<f64> = new StaticArray<f64>(NPOP);
    oZ: StaticArray<f64> = new StaticArray<f64>(NPOP);
    oS: StaticArray<f64> = new StaticArray<f64>(NPOP);
    oWasOn: StaticArray<bool> = new StaticArray<bool>(NPOP);
    nextPop: i32 = 0;
    lT: StaticArray<f64> = new StaticArray<f64>(NLABEL);
    lX: StaticArray<f64> = new StaticArray<f64>(NLABEL);
    lY: StaticArray<f64> = new StaticArray<f64>(NLABEL);
    lZ: StaticArray<f64> = new StaticArray<f64>(NLABEL);
    lS: Array<string> = ["", "", "", "", "", "", "", ""];
    lC: StaticArray<i32> = new StaticArray<i32>(NLABEL);       // 0 gold, 1 red, 2 pale
    nextLabel: i32 = 0;
    zT: StaticArray<f64> = new StaticArray<f64>(NZAP);         // a chain of lightning (HUD lines)
    zN: StaticArray<i32> = new StaticArray<i32>(NZAP);
    zPts: StaticArray<f64> = new StaticArray<f64>(NZAP * 18);  // up to 6 points x, y, z
    nextZap: i32 = 0;

    // ------------------------------------------------------------ the run
    state: i32 = PLAY;
    t: f64 = 0;
    gold: i32 = START_GOLD;
    lives: i32 = START_LIVES;
    score: i32 = 0;
    best: i32 = 0;
    demoBest: i32 = 0;
    best0: i32 = 0;
    wave: i32 = 0;                // waves started
    spawning: bool = false;
    countdown: f64 = FIRST_WAIT;
    spawnClock: f64 = 0;
    qKind: StaticArray<i32> = new StaticArray<i32>(64);
    qTime: StaticArray<f64> = new StaticArray<f64>(64);
    qLen: i32 = 0;
    qHead: i32 = 0;
    waveAlive: StaticArray<i32> = new StaticArray<i32>(NWAVE + 1);
    waveDone: StaticArray<bool> = new StaticArray<bool>(NWAVE + 1);
    waveLeak: StaticArray<i32> = new StaticArray<i32>(NWAVE + 1);
    bannerT: f64 = -9;
    bannerS: string = "";
    bannerS2: string = "";
    overT: f64 = 0;
    shakeT: f64 = -9;
    built: i32 = 0;               // towers built this run (the hint goes after the first)
    leakDist: f64 = 0;            // path metres to the gate
    mothLen: f64 = 0;
    mothX0: f64 = 0;
    mothZ0: f64 = 0;
    mothX1: f64 = 0;
    mothZ1: f64 = 0;
    wasDemo: bool = false;
    started: bool = false;

    // ------------------------------------------------------------ the ring (selection)
    sel: i32 = -1;                // the selected pad
    selT: f64 = 0;
    flashBox: i32 = -1;           // a choice just taken (drawn pressed for a moment)
    flashT: f64 = -9;
    denyT: f64 = -9;

    // ------------------------------------------------------------ sound (state-driven only)
    sndShot: StaticArray<f64> = new StaticArray<f64>(NKIND);
    sndHit: f64 = -9;
    sndBoom: f64 = -9;
    sndPop: f64 = -9;

    // ------------------------------------------------------------ the demo player
    aiNext: f64 = 0;
    aiPlan: i32 = 0;
    aiPad: i32 = -1;              // the pad it is about to act on (the ring shows meanwhile)
    aiAct: i32 = -1;              // 0-3 build kind, 10 upgrade
    aiCallAt: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        for (let k = 0; k < NKIND; k++) {
            for (let i = 0; i < PERKIND; i++) this.towerB[k * PERKIND + i] = api.bone(T_BONE[k] + i.toString());
        }
        for (let i = 0; i < NSTD; i++) this.stdB[i] = api.bone("standard" + i.toString());
        for (let k = 0; k < 5; k++) {
            for (let i = 0; i < SLOTN[k]; i++) {
                let s = SLOT0[k] + i;
                this.creepB[s] = k == TROLL ? api.bone("troll") : api.bone(C_BONE[k] + i.toString());
                this.cKind[s] = k;
            }
        }
        for (let i = 0; i < NBOLT; i++) this.projB[i] = api.bone("bolt" + i.toString());
        for (let i = 0; i < NBALL; i++) this.projB[NBOLT + i] = api.bone("ball" + i.toString());
        for (let i = 0; i < NSHARD; i++) this.projB[NBOLT + NBALL + i] = api.bone("shard" + i.toString());
        for (let i = 0; i < NPOP; i++) this.popB[i] = api.bone("pop" + i.toString());
        // the path's length to the gate, the moths' straight line
        this.leakDist = <f64>(NPATH - 1) * STEP;
        for (let i = 0; i < NPATH; i++) {
            if (PATH_X[i] >= GATE_X + 0.3) {
                this.leakDist = <f64>i * STEP;
                break;
            }
        }
        this.mothX0 = CAVE_X + 0.4; this.mothZ0 = CAVE_Z + 0.5;
        this.mothX1 = GATE_X + 0.35; this.mothZ1 = 2.6;
        this.mothLen = Math.sqrt((this.mothX1 - this.mothX0) * (this.mothX1 - this.mothX0)
            + (this.mothZ1 - this.mothZ0) * (this.mothZ1 - this.mothZ0));
        for (let i = 0; i < NKIND; i++) this.sndShot[i] = -9;
        this.wasDemo = api.demo;
        this.t = 0;
        this.hideAll(api);
        this.reset(api);
        if (api.demo) this.beginDemo(api);
        this.started = true;
    }

    // ------------------------------------------------------------ run control

    hideAll(api: GameApi): void {
        for (let i = 0; i < NKIND * PERKIND; i++) api.hide(this.towerB[i]);
        for (let i = 0; i < NSTD; i++) api.hide(this.stdB[i]);
        for (let i = 0; i < NCREEP; i++) api.hide(this.creepB[i]);
        for (let i = 0; i < NPROJ; i++) api.hide(this.projB[i]);
        for (let i = 0; i < NPOP; i++) api.hide(this.popB[i]);
    }

    reset(api: GameApi): void {
        for (let i = 0; i < NKIND * PERKIND; i++) { this.towerUsed[i] = false; api.hide(this.towerB[i]); }
        for (let i = 0; i < NSTD; i++) { this.stdUsed[i] = false; api.hide(this.stdB[i]); }
        for (let p = 0; p < NPAD; p++) {
            this.pKind[p] = -1; this.pLvl[p] = 0; this.pSlot[p] = -1; this.pStd[p] = -1; this.pYaw[p] = 0;
            this.pCool[p] = 0; this.pSpent[p] = 0; this.pBorn[p] = -9; this.pFired[p] = -9; this.pGone[p] = -9;
        }
        for (let i = 0; i < NCREEP; i++) { this.cOn[i] = false; this.cDead[i] = false; api.hide(this.creepB[i]); }
        for (let i = 0; i < NPROJ; i++) { this.jOn[i] = false; this.jWasOn[i] = false; api.hide(this.projB[i]); }
        for (let i = 0; i < NPOP; i++) { this.oT[i] = -9; this.oWasOn[i] = false; api.hide(this.popB[i]); }
        for (let i = 0; i < NLABEL; i++) this.lT[i] = -9;
        for (let i = 0; i < NZAP; i++) this.zT[i] = -9;
        for (let w = 0; w <= NWAVE; w++) { this.waveAlive[w] = 0; this.waveDone[w] = false; this.waveLeak[w] = 0; }
        this.state = PLAY;
        this.gold = START_GOLD;
        this.lives = START_LIVES;
        this.score = 0;
        this.wave = 0;
        this.spawning = false;
        this.countdown = FIRST_WAIT;
        this.qLen = 0; this.qHead = 0;
        this.sel = -1;
        this.built = 0;
        this.bannerT = -9;
        this.shakeT = -9;
        this.best0 = api.demo ? this.demoBest : this.best;
    }

    beginDemo(api: GameApi): void {
        // a valley already in play: three towers built, wave 2 under way, so the first second shows action
        this.reset(api);
        this.gold = 200;
        this.build(api, 1, ARROW, true);
        this.build(api, 5, CANNON, true);
        this.build(api, 2, ARROW, true);
        this.gold = 25;
        this.built = 3;
        this.startWave(api, true);
        this.waveDone[1] = true; this.waveAlive[1] = 0;
        this.startWave(api, true);
        // run the first seconds of wave 2 without drawing: the creeps are on the path, the towers firing
        for (let k = 0; k < 70; k++) this.step(api, 0.1, true);
        for (let p = 0; p < NPAD; p++) if (this.pKind[p] >= 0) this.pBorn[p] = -9;
        this.aiNext = this.t + 0.8;
        this.aiPlan = 3;
        this.aiPad = -1;
        this.aiCallAt = 0;
        this.sel = -1;
    }

    // ------------------------------------------------------------ the path

    // position on the path at d metres (lane: sideways offset): into px, pz, pdx, pdz
    px: f64 = 0; pz: f64 = 0; pdx: f64 = 0; pdz: f64 = 1;
    pathAt(d: f64, lane: f64): void {
        let u = clamp(d / STEP, 0, <f64>(NPATH - 1) - 0.0001);
        let i = <i32>Math.floor(u);
        let f = u - <f64>i;
        let dx = PATH_X[i + 1] - PATH_X[i], dz = PATH_Z[i + 1] - PATH_Z[i];
        let L = Math.sqrt(dx * dx + dz * dz);
        if (L < 1e-6) { dx = 1; dz = 0; L = 1; }
        dx /= L; dz /= L;
        this.pdx = dx; this.pdz = dz;
        this.px = PATH_X[i] + (PATH_X[i + 1] - PATH_X[i]) * f - dz * lane;
        this.pz = PATH_Z[i] + (PATH_Z[i + 1] - PATH_Z[i]) * f + dx * lane;
    }

    // progress towards the gate, 0..1 (moths along their line)
    progress(c: i32): f64 {
        return this.cKind[c] == MOTH ? this.cD[c] / this.mothLen : this.cD[c] / this.leakDist;
    }

    // ------------------------------------------------------------ waves

    startWave(api: GameApi, quiet: bool): void {
        if (this.wave >= NWAVE) return;
        this.wave++;
        let w = this.wave;
        let spec = WAVES[w - 1];
        this.qLen = 0; this.qHead = 0;
        let t = 0.0;
        let groups = spec.split(" ");
        for (let g = 0; g < groups.length; g++) {
            let s = groups[g];
            let c = s.charCodeAt(0);
            let kind = c == 109 ? MITE : (c == 115 ? SKITTER : (c == 104 ? SHELL : (c == 102 ? MOTH : TROLL)));
            let colon = s.indexOf(":");
            let n = <i32>parseInt(s.substring(1, colon));
            let gap = parseFloat(s.substring(colon + 1));
            for (let k = 0; k < n && this.qLen < 64; k++) {
                this.qKind[this.qLen] = kind;
                this.qTime[this.qLen] = t;
                this.qLen++;
                t += gap;
            }
            t += 1.2;
        }
        this.spawnClock = 0;
        this.spawning = true;
        this.countdown = 0;
        this.waveAlive[w] = 0;
        this.waveDone[w] = false;
        let boss = w % 5 == 0;
        this.bannerT = this.t;
        this.bannerS = "WAVE " + w.toString() + (w == NWAVE ? " - THE LAST" : "");
        this.bannerS2 = boss ? "A MOSS TROLL COMES!" : (spec.indexOf("f") >= 0 ? "GLOOM MOTHS FLY OVER" : "");
        if (!quiet) {
            if (boss) {
                api.note(45, 0.8, 0, SFX_BELL);
                api.note(48, 0.6, 0, SFX_NOTE, 0.25);
                api.note(52, 0.6, 0, SFX_NOTE, 0.5);
                api.note(45, 0.7, 0, SFX_NOTE, 0.75);
            } else {
                api.note(60, 0.5, 0, SFX_NOTE);
                api.note(64, 0.5, 0, SFX_NOTE, 0.12);
                api.note(67, 0.6, 0, SFX_NOTE, 0.24);
            }
        }
    }

    callWave(api: GameApi): void {
        if (this.state != PLAY || this.spawning || this.wave >= NWAVE) return;
        let bonus = <i32>Math.floor(this.countdown);
        if (this.wave > 0 && bonus > 0) {
            this.gold += bonus;
            this.addLabel("+" + bonus.toString() + "G EARLY", 4.6, 0.3, 4.6, 0);
            api.sound(SFX_COIN, 1.0, 0.5, 0.6);
        }
        this.startWave(api, false);
    }

    spawn(api: GameApi, kind: i32): bool {
        for (let i = 0; i < SLOTN[kind]; i++) {
            let s = SLOT0[kind] + i;
            if (this.cOn[s] || this.cDead[s]) continue;
            let w = this.wave;
            let hp = C_HP[kind] * (1.0 + HP_GROW * <f64>(w - 1)) * (w >= 8 ? 1.0 + HP_LATE * <f64>(w - 7) : 1.0);
            if (kind == TROLL) hp = C_HP[kind] * (w == 5 ? 1.0 : (w == 10 ? 2.2 : 3.6));
            this.cOn[s] = true;
            this.cHp[s] = hp;
            this.cMax[s] = hp;
            this.cD[s] = 0;
            this.cLane[s] = kind == TROLL ? 0 : api.range(-0.18, 0.18);
            this.cSlowT[s] = 0;
            this.cSlowF[s] = 1;
            this.cHitT[s] = -9;
            this.cWave[s] = w;
            this.cPhase[s] = api.rand();
            this.waveAlive[w]++;
            if (kind == MOTH) {
                this.cX[s] = this.mothX0; this.cZ[s] = this.mothZ0; this.cY[s] = MOTH_Y;
            } else {
                this.pathAt(0, this.cLane[s]);
                this.cX[s] = this.px; this.cZ[s] = this.pz; this.cY[s] = 0;
            }
            return true;
        }
        return false;
    }

    // ------------------------------------------------------------ towers

    freeTower(kind: i32): i32 {
        for (let i = 0; i < PERKIND; i++) if (!this.towerUsed[kind * PERKIND + i]) return kind * PERKIND + i;
        return -1;
    }

    freeStd(): i32 {
        for (let i = 0; i < NSTD; i++) if (!this.stdUsed[i]) return i;
        return -1;
    }

    canBuild(kind: i32): bool { return this.freeTower(kind) >= 0 && this.gold >= T_COST[kind]; }

    upCost(p: i32): i32 {
        if (this.pKind[p] < 0 || this.pLvl[p] >= 2) return -1;
        return T_UP[this.pKind[p] * 2 + this.pLvl[p]];
    }

    canUpgrade(p: i32): bool {
        let c = this.upCost(p);
        if (c < 0 || this.gold < c) return false;
        if (this.pLvl[p] == 1 && this.freeStd() < 0) return false;
        return true;
    }

    build(api: GameApi, p: i32, kind: i32, quiet: bool): bool {
        if (this.pKind[p] >= 0 || this.pGone[p] > this.t - 0.3) return false;
        let slot = this.freeTower(kind);
        if (slot < 0 || this.gold < T_COST[kind]) return false;
        this.towerUsed[slot] = true;
        this.gold -= T_COST[kind];
        this.pKind[p] = kind; this.pLvl[p] = 0; this.pSlot[p] = slot; this.pStd[p] = -1;
        this.pSpent[p] = T_COST[kind];
        this.pCool[p] = 0.3;
        this.pBorn[p] = this.t;
        // face the path's nearest point
        this.pYaw[p] = this.yawToPath(p);
        this.built++;
        if (!quiet) {
            api.soundAt(SFX_THUD, PAD_X[p], 0, PAD_Z[p], 1.0, 0.9);
            api.noteAt(<f64>(60 + kind * 4), PAD_X[p], 0, PAD_Z[p], 0.5, SFX_NOTE, 0.08);
            this.puff(PAD_X[p], 0.15, PAD_Z[p], 0.8);
        }
        return true;
    }

    yawToPath(p: i32): f64 {
        let best = 1e9, by = 0.0;
        for (let i = 0; i < NPATH; i += 2) {
            let dx = PATH_X[i] - PAD_X[p], dz = PATH_Z[i] - PAD_Z[p];
            let d = dx * dx + dz * dz;
            if (d < best) { best = d; by = deg(Math.atan2(dx, dz)); }
        }
        return Math.round(by / 15.0) * 15.0;
    }

    upgrade(api: GameApi, p: i32): bool {
        if (!this.canUpgrade(p)) return false;
        let c = this.upCost(p);
        this.gold -= c;
        this.pSpent[p] += c;
        this.pLvl[p]++;
        this.pBorn[p] = this.t;
        if (this.pLvl[p] == 2) {
            let s = this.freeStd();
            this.stdUsed[s] = true;
            this.pStd[p] = s;
        }
        api.soundAt(SFX_POWERUP, PAD_X[p], 0, PAD_Z[p], this.pLvl[p] == 2 ? 1.19 : 1.0, 0.6);
        this.puff(PAD_X[p], 0.2, PAD_Z[p], 0.9);
        return true;
    }

    sell(api: GameApi, p: i32): void {
        if (this.pKind[p] < 0) return;
        let refund = <i32>Math.floor(<f64>this.pSpent[p] * 0.7);
        this.gold += refund;
        this.pGone[p] = this.t;
        this.pGoneSlot[p] = this.pSlot[p];
        this.pGoneStd[p] = this.pStd[p];
        this.pGoneKind[p] = this.pKind[p];
        this.pKind[p] = -1;
        this.pLvl[p] = 0;
        this.addLabel("+" + refund.toString() + "G", PAD_X[p], 1.2, PAD_Z[p], 0);
        api.soundAt(SFX_COIN, PAD_X[p], 0, PAD_Z[p], 0.9, 0.7);
    }

    // ------------------------------------------------------------ combat

    findTarget(p: i32, kind: i32, range: f64): i32 {
        let best = -1, bp = -1.0;
        for (let c = 0; c < NCREEP; c++) {
            if (!this.cOn[c]) continue;
            if (kind == CANNON && this.cKind[c] == MOTH) continue;
            let dx = this.cX[c] - PAD_X[p], dz = this.cZ[c] - PAD_Z[p];
            if (dx * dx + dz * dz > range * range) continue;
            let pr = this.progress(c);
            if (pr > bp) { bp = pr; best = c; }
        }
        return best;
    }

    damage(api: GameApi, c: i32, dmg: f64, armor: bool): void {
        if (!this.cOn[c]) return;
        let d = armor ? Math.max(1.0, dmg - C_ARMOR[this.cKind[c]]) : dmg;
        this.cHp[c] -= d;
        this.cHitT[c] = this.t;
        if (this.cHp[c] <= 0) {
            this.kill(api, c);
        } else if (this.t - this.sndHit > 0.07) {
            this.sndHit = this.t;
            api.soundAt(SFX_HIT, this.cX[c], this.cY[c], this.cZ[c], this.cKind[c] == SHELL || this.cKind[c] == TROLL ? 0.7 : 1.2, 0.18);
        }
    }

    kill(api: GameApi, c: i32): void {
        let k = this.cKind[c];
        this.cOn[c] = false;
        this.cDead[c] = true;
        this.waveAlive[this.cWave[c]]--;
        this.gold += C_GOLD[k];
        this.score += C_PTS[k];
        this.addLabel("+" + C_GOLD[k].toString(), this.cX[c], this.cY[c] + C_BAR[k] * 0.7, this.cZ[c], 0);
        this.puff(this.cX[c], this.cY[c] + 0.25, this.cZ[c], k == TROLL ? 1.6 : (k == SHELL ? 1.0 : 0.7));
        if (k == TROLL) {
            api.soundAt(SFX_EXPLODE, this.cX[c], 0, this.cZ[c], 0.7, 1.0);
            api.note(72, 0.6, 0, SFX_BELL, 0.1);
            api.note(79, 0.5, 0, SFX_BELL, 0.25);
        } else if (this.t - this.sndPop > 0.05) {
            this.sndPop = this.t;
            let pitch = k == MITE ? 1.3 : (k == SKITTER ? 1.55 : (k == SHELL ? 0.8 : 1.9));
            api.soundAt(SFX_POP, this.cX[c], this.cY[c], this.cZ[c], pitch, 0.5);
        }
    }

    leak(api: GameApi, c: i32): void {
        let k = this.cKind[c];
        this.cOn[c] = false;
        this.cDead[c] = true;
        this.waveAlive[this.cWave[c]]--;
        this.waveLeak[this.cWave[c]]++;
        this.lives = <i32>Math.max(0, this.lives - C_LIVES[k]);
        this.shakeT = this.t;
        this.addLabel("-" + C_LIVES[k].toString(), GATE_X + 0.2, 1.4, 2.6, 1);
        api.soundAt(SFX_HIT, GATE_X, 0.5, 2.6, 0.55, 0.9);
        api.note(this.lives > 8 ? 50 : 45, 0.6, 0.6, SFX_BELL, 0.05);
        if (this.lives <= 0) this.lose(api);
    }

    lose(api: GameApi): void {
        if (this.state != PLAY) return;
        this.state = LOST;
        this.overT = this.t;
        this.sel = -1;
        this.finish(api);
        api.sound(SFX_LOSE, 1.0, 0.8);
    }

    win(api: GameApi): void {
        this.state = WON;
        this.overT = this.t;
        this.sel = -1;
        this.score += this.lives * 50;
        this.finish(api);
        api.sound(SFX_WIN, 1.0, 0.8);
        api.note(72, 0.5, 0, SFX_BELL, 0.5);
        api.note(76, 0.5, 0, SFX_BELL, 0.65);
        api.note(79, 0.5, 0, SFX_BELL, 0.8);
        api.note(84, 0.6, 0, SFX_BELL, 1.0);
    }

    finish(api: GameApi): void {
        if (api.demo) {
            if (this.score > this.demoBest) this.demoBest = this.score;
        } else if (this.score > this.best) {
            this.best = this.score;
            if (this.best0 > 0) api.note(91, 0.4, 0, SFX_BELL, 1.4);
        }
    }

    fire(api: GameApi, p: i32, c: i32, quiet: bool): bool {
        let k = this.pKind[p], lv = this.pLvl[p];
        let i = k * 3 + lv;
        let sc = T_SCALE[lv];
        let yr = this.pYaw[p] * Math.PI / 180.0;
        let mx = PAD_X[p] + Math.sin(yr) * T_MUZZLE_F[k] * sc;
        let mz = PAD_Z[p] + Math.cos(yr) * T_MUZZLE_F[k] * sc;
        let my = PAD_TOP + T_MUZZLE_H[k] * sc;
        if (k == STORM) {
            // chain lightning: instant, hits up to T_CHAIN creeps, each jump weaker; ignores armour
            let z = this.nextZap;
            this.nextZap = (this.nextZap + 1) % NZAP;
            this.zT[z] = this.t;
            this.zPts[z * 18] = mx; this.zPts[z * 18 + 1] = my; this.zPts[z * 18 + 2] = mz;
            let n = 1;
            let cur = c;
            let dmg = T_DMG[i];
            let hitMask: u32 = 0;
            for (let h = 0; h < T_CHAIN[i] && cur >= 0; h++) {
                hitMask |= (<u32>1 << <u32>cur);
                this.zPts[z * 18 + n * 3] = this.cX[cur];
                this.zPts[z * 18 + n * 3 + 1] = this.cY[cur] + C_BAR[this.cKind[cur]] * 0.5;
                this.zPts[z * 18 + n * 3 + 2] = this.cZ[cur];
                n++;
                let nx = this.cX[cur], nz = this.cZ[cur];
                this.damage(api, cur, dmg, false);
                dmg *= 0.75;
                // the nearest unhit creep within 1.6 m
                let nb = -1, nd = 1.6 * 1.6;
                for (let o = 0; o < NCREEP; o++) {
                    if (!this.cOn[o] || (hitMask & (<u32>1 << <u32>o)) != 0) continue;
                    let dx = this.cX[o] - nx, dz = this.cZ[o] - nz;
                    let d = dx * dx + dz * dz;
                    if (d < nd) { nd = d; nb = o; }
                }
                cur = nb;
            }
            this.zN[z] = n;
            if (!quiet && this.t - this.sndShot[k] > 0.18) {
                this.sndShot[k] = this.t;
                api.soundAt(SFX_ZAP, mx, my, mz, 1.0, 0.35);
            }
            return true;
        }
        // a projectile from the tower's pool
        let j0 = k == ARROW ? 0 : (k == CANNON ? NBOLT : NBOLT + NBALL);
        let jn = k == ARROW ? NBOLT : (k == CANNON ? NBALL : NSHARD);
        let j = -1;
        for (let q = j0; q < j0 + jn; q++) if (!this.jOn[q]) { j = q; break; }
        if (j < 0) return false;
        this.jOn[j] = true;
        this.jT[j] = 0;
        this.jX[j] = mx; this.jY[j] = my; this.jZ[j] = mz;
        this.jX0[j] = mx; this.jY0[j] = my; this.jZ0[j] = mz;
        this.jTarget[j] = c;
        this.jPad[j] = p;
        if (k == CANNON) {
            // lob at where the creep will be when the ball lands
            let dur = 0.62;
            let d = this.cD[c] + C_SPEED[this.cKind[c]] * this.cSlowF[c] * dur;
            this.pathAt(d, this.cLane[c]);
            this.jX1[j] = this.px; this.jZ1[j] = this.pz;
            this.jDur[j] = dur;
            if (!quiet && this.t - this.sndShot[k] > 0.12) {
                this.sndShot[k] = this.t;
                api.soundAt(SFX_THUD, mx, my, mz, 1.5, 0.55);
                api.soundAt(SFX_WHOOSH, mx, my, mz, 1.3, 0.15, 0.03);
            }
        } else if (!quiet && this.t - this.sndShot[k] > 0.12) {
            this.sndShot[k] = this.t;
            if (k == ARROW) api.soundAt(SFX_SHOOT, mx, my, mz, 1.5, 0.22);
            else api.noteAt(88, mx, my, mz, 0.18, SFX_BELL);
        }
        return true;
    }

    land(api: GameApi, j: i32, quiet: bool): void {
        let p = this.jPad[j];
        let k = j < NBOLT ? ARROW : (j < NBOLT + NBALL ? CANNON : FROST);
        let lv = this.pKind[p] == k ? this.pLvl[p] : 0;
        let i = k * 3 + lv;
        if (k == CANNON) {
            let r = T_SPLASH[i];
            for (let c = 0; c < NCREEP; c++) {
                if (!this.cOn[c] || this.cKind[c] == MOTH) continue;
                let dx = this.cX[c] - this.jX[j], dz = this.cZ[c] - this.jZ[j];
                if (dx * dx + dz * dz <= r * r) this.damage(api, c, T_DMG[i], true);
            }
            this.puff(this.jX[j], 0.15, this.jZ[j], 0.85);
            if (!quiet && this.t - this.sndBoom > 0.1) {
                this.sndBoom = this.t;
                api.soundAt(SFX_EXPLODE, this.jX[j], 0, this.jZ[j], 1.5, 0.35);
            }
            return;
        }
        let c = this.jTarget[j];
        if (c < 0 || !this.cOn[c]) return;
        if (k == FROST) {
            let r = T_SPLASH[i];
            for (let o = 0; o < NCREEP; o++) {
                if (!this.cOn[o]) continue;
                let dx = this.cX[o] - this.cX[c], dz = this.cZ[o] - this.cZ[c];
                if (o == c || dx * dx + dz * dz <= r * r) {
                    this.cSlowT[o] = 1.8;
                    this.cSlowF[o] = Math.min(this.cSlowF[o], T_SLOW[i]);
                    this.damage(api, o, T_DMG[i], true);
                }
            }
        } else {
            this.damage(api, c, T_DMG[i], true);
        }
    }

    puff(x: f64, y: f64, z: f64, s: f64): void {
        let o = this.nextPop;
        this.nextPop = (this.nextPop + 1) % NPOP;
        this.oT[o] = this.t; this.oX[o] = x; this.oY[o] = y; this.oZ[o] = z; this.oS[o] = s;
    }

    addLabel(s: string, x: f64, y: f64, z: f64, col: i32): void {
        let l = this.nextLabel;
        this.nextLabel = (this.nextLabel + 1) % NLABEL;
        this.lT[l] = this.t; this.lX[l] = x; this.lY[l] = y; this.lZ[l] = z; this.lS[l] = s; this.lC[l] = col;
    }

    // ------------------------------------------------------------ the simulation step (no drawing)

    step(api: GameApi, dt: f64, quiet: bool): void {
        this.t += dt;
        if (this.state != PLAY) {
            // creeps on the field wander on after a loss; projectiles settle
            return;
        }
        // waves
        if (this.spawning) {
            if (this.qHead < this.qLen && this.spawnClock >= this.qTime[this.qHead]) {
                if (this.spawn(api, this.qKind[this.qHead])) this.qHead++;
            } else {
                this.spawnClock += dt;
            }
            if (this.qHead >= this.qLen) {
                this.spawning = false;
                this.countdown = this.wave < NWAVE ? BETWEEN : 0;
            }
        } else if (this.wave < NWAVE) {
            this.countdown -= dt;
            if (this.countdown <= 0) this.startWave(api, quiet);
        }
        // creeps move
        for (let c = 0; c < NCREEP; c++) {
            if (!this.cOn[c]) continue;
            let k = this.cKind[c];
            if (this.cSlowT[c] > 0) {
                this.cSlowT[c] -= dt;
                if (this.cSlowT[c] <= 0) this.cSlowF[c] = 1;
            }
            this.cD[c] += C_SPEED[k] * this.cSlowF[c] * dt;
            if (k == MOTH) {
                let f = this.cD[c] / this.mothLen;
                this.cX[c] = this.mothX0 + (this.mothX1 - this.mothX0) * f;
                this.cZ[c] = this.mothZ0 + (this.mothZ1 - this.mothZ0) * f;
                this.cY[c] = MOTH_Y;
                this.cYaw[c] = deg(Math.atan2(this.mothX1 - this.mothX0, this.mothZ1 - this.mothZ0));
                if (f >= 1) this.leak(api, c);
            } else {
                this.pathAt(this.cD[c], this.cLane[c]);
                this.cX[c] = this.px; this.cZ[c] = this.pz; this.cY[c] = 0;
                this.cYaw[c] = deg(Math.atan2(this.pdx, this.pdz));
                if (this.cD[c] >= this.leakDist) this.leak(api, c);
            }
            if (this.state != PLAY) return;
        }
        // towers aim and fire
        for (let p = 0; p < NPAD; p++) {
            let k = this.pKind[p];
            if (k < 0) continue;
            let i = k * 3 + this.pLvl[p];
            this.pCool[p] -= dt;
            let c = this.findTarget(p, k, T_RANGE[i]);
            if (c < 0) continue;
            if (k == ARROW || k == CANNON) {
                let want = deg(Math.atan2(this.cX[c] - PAD_X[p], this.cZ[c] - PAD_Z[p]));
                let dy = wrap180(want - this.pYaw[p]);
                let turn = 420.0 * dt;
                this.pYaw[p] += Math.abs(dy) < turn ? dy : (dy > 0 ? turn : -turn);
                if (Math.abs(wrap180(want - this.pYaw[p])) > 25) continue;
            }
            if (this.pCool[p] <= 0) {
                if (this.fire(api, p, c, quiet)) {
                    this.pCool[p] = T_COOL[i];
                    this.pFired[p] = this.t;
                }
            }
        }
        // projectiles fly
        for (let j = 0; j < NPROJ; j++) {
            if (!this.jOn[j]) continue;
            this.jT[j] += dt;
            if (j >= NBOLT && j < NBOLT + NBALL) {
                let s = this.jT[j] / this.jDur[j];
                if (s >= 1) {
                    this.jX[j] = this.jX1[j]; this.jZ[j] = this.jZ1[j]; this.jY[j] = 0.1;
                    this.jOn[j] = false;
                    this.land(api, j, quiet);
                    continue;
                }
                this.jX[j] = this.jX0[j] + (this.jX1[j] - this.jX0[j]) * s;
                this.jZ[j] = this.jZ0[j] + (this.jZ1[j] - this.jZ0[j]) * s;
                this.jY[j] = this.jY0[j] * (1 - s) + 0.15 * s + 1.4 * s * (1 - s);
                this.jYaw[j] = 0; this.jPitch[j] = 0;
                continue;
            }
            let c = this.jTarget[j];
            if (c < 0 || !this.cOn[c]) {
                // the target is gone: fly on a moment, then vanish
                if (this.jT[j] > 0.4) this.jOn[j] = false;
                let sp = j < NBOLT ? 11.0 : 8.0;
                let yr = this.jYaw[j] * Math.PI / 180.0;
                this.jX[j] += Math.sin(yr) * sp * dt;
                this.jZ[j] += Math.cos(yr) * sp * dt;
                this.jY[j] -= 2.0 * dt;
                continue;
            }
            let tx = this.cX[c], ty = this.cY[c] + C_BAR[this.cKind[c]] * 0.45, tz = this.cZ[c];
            let dx = tx - this.jX[j], dy = ty - this.jY[j], dz = tz - this.jZ[j];
            let d = Math.sqrt(dx * dx + dy * dy + dz * dz);
            let sp = j < NBOLT ? 11.0 : 8.0;
            if (d <= sp * dt + 0.12) {
                this.jOn[j] = false;
                this.land(api, j, quiet);
                continue;
            }
            this.jX[j] += dx / d * sp * dt;
            this.jY[j] += dy / d * sp * dt;
            this.jZ[j] += dz / d * sp * dt;
            this.jYaw[j] = deg(Math.atan2(dx, dz));
            this.jPitch[j] = deg(Math.atan2(-dy, Math.sqrt(dx * dx + dz * dz)));
        }
        // a wave cleared, the last one won
        for (let w = 1; w <= this.wave; w++) {
            if (this.waveDone[w]) continue;
            if ((w < this.wave || !this.spawning) && this.waveAlive[w] <= 0) {
                this.waveDone[w] = true;
                let clean = this.waveLeak[w] == 0;
                if (clean) this.score += 40 + 10 * w;
                if (w < NWAVE) {
                    let g = 10 + 2 * w;
                    this.gold += g;
                    this.addLabel("+" + g.toString() + "G", 4.6, 0.3, 4.6, 0);
                }
                if (w < NWAVE) {
                    if (!quiet) {
                        api.note(72, 0.4, 0, SFX_NOTE);
                        api.note(76, 0.4, 0, SFX_NOTE, 0.1);
                        api.note(79, 0.4, 0, SFX_NOTE, 0.2);
                        api.note(84, 0.45, 0, SFX_BELL, 0.3);
                    }
                    if (this.bannerT < this.t - 2.0) {
                        this.bannerT = this.t;
                        this.bannerS = "WAVE " + w.toString() + (clean ? " HELD" : " OVER");
                        this.bannerS2 = "";
                    }
                }
            }
        }
        if (this.wave >= NWAVE && !this.spawning) {
            let any = false;
            for (let c = 0; c < NCREEP; c++) if (this.cOn[c]) { any = true; break; }
            if (!any) this.win(api);
        }
    }

    // ------------------------------------------------------------ every frame

    update(api: GameApi): void {
        if (!this.started) return;
        if (api.demo != this.wasDemo || api.demoChanged) {
            this.wasDemo = api.demo;
            if (api.demo) this.beginDemo(api);
            else { this.reset(api); }
        }
        let dt = api.dt;
        if (dt > 0.1) dt = 0.1;
        this.step(api, dt, api.demo);
        if (this.state != PLAY) {
            if (api.demo && this.t - this.overT > 2.0) this.beginDemo(api);
        } else if (api.demo) {
            this.demoPlay(api);
        }
        this.draw(api);
    }

    // ------------------------------------------------------------ placing the bones

    draw(api: GameApi): void {
        let t = this.t;
        let st = Math.floor(t * 12.0) / 12.0;     // stepped animation time (12 fps)
        // towers
        for (let p = 0; p < NPAD; p++) {
            // a sold tower shrinks into its pad
            if (this.pGone[p] > -9 && t - this.pGone[p] < 0.4) {
                let b = this.towerB[this.pGoneSlot[p]];
                let s = 1.0 - (t - this.pGone[p]) / 0.4;
                if (s < 0.08) s = 0.08;
                api.place(b, PAD_X[p], PAD_TOP, PAD_Z[p], this.pYaw[p], 0, 0, s * 0.9);
                if (this.pGoneStd[p] >= 0) api.place(this.stdB[this.pGoneStd[p]], PAD_X[p], 0, PAD_Z[p], 0, 0, 0, Math.max(0.1, s));
            } else if (this.pGone[p] > -9) {
                api.hide(this.towerB[this.pGoneSlot[p]]);
                this.towerUsed[this.pGoneSlot[p]] = false;
                if (this.pGoneStd[p] >= 0) {
                    api.hide(this.stdB[this.pGoneStd[p]]);
                    this.stdUsed[this.pGoneStd[p]] = false;
                }
                this.pGone[p] = -9;
            }
            let k = this.pKind[p];
            if (k < 0) continue;
            let lv = this.pLvl[p];
            let s = T_SCALE[lv];
            let age = t - this.pBorn[p];
            if (age < 0.4) {
                // pop in from the previous size with an overshoot, stepped
                let a = Math.floor(age * 12.0) / 12.0 / 0.4;
                let from = lv == 0 ? 0.25 : T_SCALE[lv - 1];
                s = from + (s - from) * (1.0 + 0.25 * Math.sin(a * Math.PI)) * Math.min(1.0, a * 1.6);
            }
            let yaw = Math.round(this.pYaw[p] / 15.0) * 15.0;
            let sy = 1.0, sx = 1.0;
            let since = t - this.pFired[p];
            if (k == CANNON && since < 0.15) { sy = 0.9; sx = 1.06; }
            if (k == STORM && since < 0.12) { sy = 1.06; }
            if (k == FROST) {
                yaw = 0;
                if (since < 0.15) sy = 1.05;
            }
            let b = this.towerB[this.pSlot[p]];
            if (sy != 1.0 || sx != 1.0) api.placeScaled(b, PAD_X[p], PAD_TOP, PAD_Z[p], yaw, s * sx, s * sy, s * sx);
            else api.place(b, PAD_X[p], PAD_TOP, PAD_Z[p], yaw, 0, 0, s);
            if (this.pStd[p] >= 0) {
                let sa = lv == 2 && age < 0.4 ? Math.max(0.15, Math.floor(age * 12.0) / 12.0 / 0.4) : 1.0;
                api.placeScaled(this.stdB[this.pStd[p]], PAD_X[p], 0, PAD_Z[p], 0, 1, sa, 1);
            }
        }
        // creeps
        for (let c = 0; c < NCREEP; c++) {
            let b = this.creepB[c];
            if (this.cDead[c]) {
                api.hide(b);
                this.cDead[c] = false;
                continue;
            }
            if (!this.cOn[c]) continue;
            let k = this.cKind[c];
            let ph = this.cPhase[c];
            let hit = t - this.cHitT[c] < 0.1;
            let slowF = this.cSlowF[c];
            let gait = st * C_SPEED[k] * slowF * 7.0 + ph * 6.0;
            if (k == MOTH) {
                let flap = Math.floor(st * 10.0 + ph * 4.0) % 2 == 0 ? 1.0 : 0.45;
                let bob = Math.sin(st * 4.0 + ph * 6.0) * 0.08;
                api.placeScaled(b, this.cX[c], this.cY[c] + bob, this.cZ[c], this.cYaw[c], flap, 1, 1);
            } else if (k == TROLL) {
                let roll = Math.sin(gait * 0.5) * 6.0;
                let s = hit ? 0.95 : 1.0;
                api.place(b, this.cX[c], Math.abs(Math.sin(gait * 0.5)) * 0.05, this.cZ[c], this.cYaw[c], 0, roll, s);
            } else {
                let hop = Math.abs(Math.sin(gait)) * (k == SKITTER ? 0.07 : 0.04);
                let wig = Math.sin(gait) * (k == MITE ? 10.0 : 5.0);
                let sq = hit ? 0.8 : 1.0;
                api.placeScaled(b, this.cX[c], hop, this.cZ[c], this.cYaw[c] + wig, 1.0 / Math.sqrt(sq), sq, 1.0 / Math.sqrt(sq));
            }
        }
        // projectiles
        for (let j = 0; j < NPROJ; j++) {
            let b = this.projB[j];
            if (!this.jOn[j]) {
                if (this.jWasOn[j]) { api.hide(b); this.jWasOn[j] = false; }
                continue;
            }
            this.jWasOn[j] = true;
            if (j >= NBOLT && j < NBOLT + NBALL) api.place(b, this.jX[j], this.jY[j], this.jZ[j], 0, 0, 0, 1);
            // the bolt and shard models point -Y in hedra (+z): yaw turns them, pitch tilts
            else api.place(b, this.jX[j], this.jY[j], this.jZ[j], this.jYaw[j], this.jPitch[j], 0, 1);
        }
        // puffs: grow, hold, shrink away (stepped)
        for (let o = 0; o < NPOP; o++) {
            let b = this.popB[o];
            let a = t - this.oT[o];
            if (a > 0.36 || this.oT[o] < -8) {
                if (this.oWasOn[o]) { api.hide(b); this.oWasOn[o] = false; }
                continue;
            }
            this.oWasOn[o] = true;
            let sa = Math.floor(a * 15.0) / 15.0;
            let s = sa < 0.12 ? 0.4 + sa / 0.12 * 0.6 : 1.0 - (sa - 0.12) / 0.24 * 0.55;
            api.place(b, this.oX[o], this.oY[o] + sa * 0.6, this.oZ[o], sa * 200.0, 0, 0, Math.max(0.1, s * this.oS[o] * 0.62));
        }
        // the camera: a short shake when a creep reaches the gate
        let sh = t - this.shakeT;
        let ox = 0.0;
        if (sh < 0.3) ox = (Math.floor(sh * 30.0) % 2 == 0 ? 1.0 : -1.0) * 0.07 * (1.0 - sh / 0.3);
        api.targetX = -0.3 + ox;
    }

    // ------------------------------------------------------------ the demo player

        demoPlay(api: GameApi): void {
        let t = this.t;
        if (this.aiPad >= 0) {
            // the ring has been open a moment: take the choice
            if (t >= this.aiNext) {
                let p = this.aiPad;
                if (this.aiAct < 4) {
                    if (this.build(api, p, this.aiAct, true)) this.aiPlan++;
                } else {
                    this.upgrade(api, p);
                }
                this.flashBox = this.aiAct < 4 ? this.aiAct : 0;
                this.flashT = t;
                this.aiPad = -1;
                this.aiNext = t + api.range(1.0, 2.2);
                this.selT = t;
            }
            return;
        }
        if (this.sel >= 0 && t - this.flashT > 0.25) this.sel = -1;
        if (t < this.aiNext) return;
        // the build order: pads and kinds; once all are built, upgrades
        if (this.aiPlan < 10) {
            let p = PLAN[this.aiPlan * 2], k = PLAN[this.aiPlan * 2 + 1];
            if (this.pKind[p] >= 0) { this.aiPlan++; return; }
            if (this.canBuild(k)) {
                this.sel = p; this.selT = t; this.aiPad = p; this.aiAct = k;
                this.aiNext = t + api.range(0.45, 0.8);
                return;
            }
        }
        // upgrades: the cheapest worthwhile, cannons and storms first, once a reserve for the next build is kept
        let reserve = this.aiPlan < 10 ? T_COST[PLAN[this.aiPlan * 2 + 1]] : 0;
        let bestP = -1, bestV = -1.0;
        for (let p = 0; p < NPAD; p++) {
            if (!this.canUpgrade(p)) continue;
            let c = this.upCost(p);
            if (this.gold - c < reserve && this.wave < 6) continue;
            let v = (this.pKind[p] == CANNON || this.pKind[p] == STORM ? 1.4 : 1.0) / <f64>c + (p == 1 || p == 5 ? 0.004 : 0.0);
            if (v > bestV) { bestV = v; bestP = p; }
        }
        if (bestP >= 0 && api.rand() < 0.8) {
            this.sel = bestP; this.selT = t; this.aiPad = bestP; this.aiAct = 10;
            this.aiNext = t + api.range(0.45, 0.8);
            return;
        }
        // call the next wave early when the field is calm
        if (!this.spawning && this.wave < NWAVE && this.countdown > 2) {
            let near = false;
            for (let c = 0; c < NCREEP; c++) if (this.cOn[c] && this.progress(c) > 0.35) { near = true; break; }
            if (!near && api.rand() < 0.5) {
                this.callWave(api);
                this.flashT = t;
            }
        }
        this.aiNext = t + api.range(0.6, 1.4);
    }

    // ------------------------------------------------------------ input

    padAt(api: GameApi, x: f32, y: f32): i32 {
        let best = -1;
        let bd: f32 = 1e9;
        for (let p = 0; p < NPAD; p++) {
            if (!api.project(<f32>PAD_X[p], <f32>PAD_TOP, <f32>PAD_Z[p])) continue;
            let dx = x - api.screenX, dy = y - api.screenY;
            let top: f32 = this.pKind[p] >= 0 ? -24 : -9;
            if (dx < -11 || dx > 11 || dy < top || dy > 8) continue;
            let d = dx * dx + (dy > 0 ? dy * dy : dy * dy * 0.25);
            if (d < bd) { bd = d; best = p; }
        }
        return best;
    }

    // the ring's choice boxes for the selected pad: their top-left (after clamping to the frame)
    ringX: f32 = 0;
    ringY: f32 = 0;
    ringBox(api: GameApi, i: i32): bool {
        let p = this.sel;
        if (p < 0 || !api.project(<f32>PAD_X[p], <f32>PAD_TOP, <f32>PAD_Z[p])) return false;
        let cx = api.screenX, cy = api.screenY;
        // keep the whole ring inside the frame (and under the top line)
        if (cx < 54) cx = 54;
        if (cx > <f32>api.hudW - 54) cx = <f32>api.hudW - 54;
        if (cy < 50) cy = 50;
        if (cy > <f32>api.hudH - 27) cy = <f32>api.hudH - 27;
        this.ringX = Mathf.round(cx + RING_DX[i]);
        this.ringY = Mathf.round(cy + RING_DY[i]);
        return true;
    }

    // which ring boxes are shown: build: 0-3 (up ARROW, right CANNON, down FROST, left STORM); tower: 0 upgrade, 2 sell
    ringHas(i: i32): bool {
        if (this.sel < 0) return false;
        if (this.pKind[this.sel] < 0) return true;
        return i == 0 || i == 2;
    }

    nextBox(api: GameApi): bool {
        return this.state == PLAY && !this.spawning && this.wave < NWAVE;
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind != POINTER_DOWN) return true;
        let t = this.t;
        if (this.state != PLAY) {
            if (t - this.overT > 0.8) {
                this.reset(api);
                api.sound(SFX_CLICK, 1.0, 0.5);
            }
            return true;
        }
        // NEXT WAVE (bottom right)
        if (this.nextBox(api)) {
            let bx = <f32>api.hudW - 56, by = <f32>api.hudH - 18;
            if (x >= bx && x < bx + 54 && y >= by && y < by + 16) {
                this.sel = -1;
                this.callWave(api);
                return true;
            }
        }
        // a choice in the open ring
        if (this.sel >= 0) {
            for (let i = 0; i < 4; i++) {
                if (!this.ringHas(i) || !this.ringBox(api, i)) continue;
                if (x >= this.ringX - 1 && x < this.ringX + BOX_W + 1 && y >= this.ringY - 1 && y < this.ringY + BOX_H + 1) {
                    let p = this.sel;
                    let ok = false;
                    if (this.pKind[p] < 0) ok = this.build(api, p, i, false);
                    else if (i == 0) ok = this.upgrade(api, p);
                    else { this.sell(api, p); ok = true; }
                    if (ok) {
                        this.flashBox = i;
                        this.flashT = t;
                        this.sel = -1;
                    } else {
                        this.denyT = t;
                        api.sound(SFX_BLIP, 0.55, 0.5);
                    }
                    return true;
                }
            }
        }
        let p = this.padAt(api, x, y);
        if (p >= 0 && p != this.sel) {
            this.sel = p;
            this.selT = t;
            api.sound(SFX_CLICK, 1.2, 0.45);
        } else {
            this.sel = -1;
        }
        return true;
    }

    // ------------------------------------------------------------ the HUD

    heart(api: GameApi, x: f32, y: f32, c: u32): void {
        api.rect(x, y, 2, 1, c); api.rect(x + 3, y, 2, 1, c);
        api.rect(x, y + 1, 5, 2, c); api.rect(x + 1, y + 3, 3, 1, c); api.rect(x + 2, y + 4, 1, 1, c);
    }

    coin(api: GameApi, x: f32, y: f32, c: u32, d: u32): void {
        api.rect(x + 1, y, 3, 5, c); api.rect(x, y + 1, 5, 3, c); api.rect(x + 2, y + 1, 1, 3, d);
    }

    box(api: GameApi, x: f32, y: f32, w: f32, h: f32, fill: u32, edge: u32): void {
        api.rect(x, y, w, h, edge);
        api.rect(x + 1, y + 1, w - 2, h - 2, fill);
    }

    hud(api: GameApi): void {
        let t = this.t;
        let dark = api.rampColor(16, 1);       // #433455
        let black = api.rampColor(16, 0);
        let pale = api.rampColor(3, 3);        // #c5ccb8
        let grey = api.rampColor(3, 2);
        let goldC = api.rampColor(8, 2);       // #be955c
        let red = api.rampColor(7, 1);
        let pink = api.rampColor(7, 2);
        let green = api.rampColor(0, 2);
        let frost = api.rampColor(9, 2);
        let teal = api.rampColor(10, 2);
        let slate = api.rampColor(3, 1);

        // lightning: two-tone zig-zag lines between the chain's points
        for (let z = 0; z < NZAP; z++) {
            let a = t - this.zT[z];
            if (a > 0.16 || this.zT[z] < -8) continue;
            let n = this.zN[z];
            for (let s = 0; s + 1 < n; s++) {
                if (!api.project(<f32>this.zPts[z * 18 + s * 3], <f32>this.zPts[z * 18 + s * 3 + 1], <f32>this.zPts[z * 18 + s * 3 + 2])) continue;
                let x0 = api.screenX, y0 = api.screenY;
                if (!api.project(<f32>this.zPts[z * 18 + s * 3 + 3], <f32>this.zPts[z * 18 + s * 3 + 4], <f32>this.zPts[z * 18 + s * 3 + 5])) continue;
                let x1 = api.screenX, y1 = api.screenY;
                let seed = z * 97 + s * 13 + <i32>Math.floor(t * 30.0) * 7;
                let mx = (x0 + x1) * 0.5 + <f32>(hash(seed) * 8.0 - 4.0);
                let my = (y0 + y1) * 0.5 + <f32>(hash(seed + 1) * 8.0 - 4.0);
                api.line(x0 + 1, y0, mx + 1, my, teal);
                api.line(mx + 1, my, x1 + 1, y1, teal);
                api.line(x0, y0, mx, my, pale);
                api.line(mx, my, x1, y1, pale);
            }
        }

        // creeps' HP bars (when hurt; the troll's always)
        for (let c = 0; c < NCREEP; c++) {
            if (!this.cOn[c]) continue;
            let k = this.cKind[c];
            if (this.cHp[c] >= this.cMax[c] && k != TROLL) continue;
            if (!api.project(<f32>this.cX[c], <f32>(this.cY[c] + C_BAR[k]), <f32>this.cZ[c])) continue;
            let w: f32 = k == TROLL ? 16 : (k == SHELL ? 10 : 8);
            let x = Mathf.round(api.screenX - w * 0.5), y = Mathf.round(api.screenY) - 3;
            let f = <f32>clamp(this.cHp[c] / this.cMax[c], 0, 1);
            api.rect(x, y, w, 2, this.cSlowT[c] > 0 ? frost : dark);
            api.rect(x, y, Mathf.max(1, Mathf.round(w * f)), 2, f > 0.35 ? green : pink);
        }

        // floating labels (gold from kills, refunds, lives lost)
        for (let l = 0; l < NLABEL; l++) {
            let a = t - this.lT[l];
            if (a > 1.0 || this.lT[l] < -8) continue;
            if (!api.project(<f32>this.lX[l], <f32>this.lY[l], <f32>this.lZ[l])) continue;
            let s = this.lS[l];
            let rise = Mathf.floor(<f32>a * 12.0);
            let c = this.lC[l] == 0 ? goldC : (this.lC[l] == 1 ? pink : pale);
            api.text(Mathf.round(api.screenX - api.textWidth(s, 1) * 0.5), Mathf.round(api.screenY) - 6 - rise, s, c, 1, dark);
        }

        // the selected pad: its range as a dotted ellipse, the ring of choices
        if (this.sel >= 0 && this.state == PLAY) {
            let p = this.sel;
            let k = this.pKind[p];
            let r = k >= 0 ? T_RANGE[k * 3 + this.pLvl[p]] : 0.0;
            if (k >= 0) {
                // dashed: every other of 40 segments
                let lx: f32 = 0, ly: f32 = 0;
                for (let a = 0; a <= 40; a++) {
                    let an = <f64>a / 40.0 * Math.PI * 2.0;
                    if (!api.project(<f32>(PAD_X[p] + Math.cos(an) * r), 0.05, <f32>(PAD_Z[p] + Math.sin(an) * r))) continue;
                    let x = Mathf.round(api.screenX), y = Mathf.round(api.screenY);
                    if (a > 0 && a % 2 == 1) {
                        api.line(lx, ly + 1, x, y + 1, dark);
                        api.line(lx, ly, x, y, pale);
                    }
                    lx = x; ly = y;
                }
            }
            // the pad's marker: four corner ticks round it
            if (api.project(<f32>PAD_X[p], <f32>PAD_TOP, <f32>PAD_Z[p])) {
                let cx = Mathf.round(api.screenX), cy = Mathf.round(api.screenY);
                let blink = Math.floor(t * 4.0) % 2 == 0 ? pale : goldC;
                api.rect(cx - 11, cy - 7, 3, 1, blink); api.rect(cx - 11, cy - 7, 1, 3, blink);
                api.rect(cx + 9, cy - 7, 3, 1, blink); api.rect(cx + 11, cy - 7, 1, 3, blink);
                api.rect(cx - 11, cy + 6, 3, 1, blink); api.rect(cx - 11, cy + 4, 1, 3, blink);
                api.rect(cx + 9, cy + 6, 3, 1, blink); api.rect(cx + 11, cy + 4, 1, 3, blink);
            }
            for (let i = 0; i < 4; i++) {
                if (!this.ringHas(i) || !this.ringBox(api, i)) continue;
                let x = this.ringX, y = this.ringY;
                let l1 = "", l2 = "";
                let ok = true;
                let accent = goldC;
                if (k < 0) {
                    l1 = T_NAME[i];
                    let left = this.freeTower(i) >= 0;
                    l2 = left ? T_COST[i].toString() + "G" : "NONE";
                    ok = this.canBuild(i);
                    accent = i == ARROW ? goldC : (i == CANNON ? grey : (i == FROST ? frost : teal));
                } else if (i == 0) {
                    let c = this.upCost(p);
                    l1 = c < 0 ? "MAX" : "UPGRADE";
                    l2 = c < 0 ? "" : c.toString() + "G";
                    ok = this.canUpgrade(p);
                } else {
                    l1 = "SELL";
                    l2 = "+" + (<i32>Math.floor(<f64>this.pSpent[p] * 0.7)).toString() + "G";
                    accent = pink;
                }
                let pressed = this.flashBox == i && t - this.flashT < 0.2;
                this.box(api, x, y, BOX_W, BOX_H, pressed ? goldC : (ok ? dark : black), ok ? accent : slate);
                api.rect(x + 1, y + 1, 2, BOX_H - 2, ok ? accent : slate);
                api.text(x + 4, y + 1, l1, ok ? pale : grey, 1);
                api.text(x + 4, y + 7, l2, ok ? goldC : slate, 1);
            }
            // the tower's name and level over the ring
            if (k >= 0 && this.ringBox(api, 0)) {
                let s = T_NAME[k] + " " + (this.pLvl[p] == 0 ? "I" : (this.pLvl[p] == 1 ? "II" : "III"));
                let ry = this.ringY - 7;
                let rx = Mathf.round(this.ringX + BOX_W * 0.5 - api.textWidth(s, 1) * 0.5);
                api.text(rx, ry, s, pale, 1, dark);
            }
        }
        // a pressed choice that the AI took, seen after the ring closed
        if (this.sel < 0 && this.flashBox >= 0 && t - this.flashT > 0.25) this.flashBox = -1;

        // rank chevrons over level 2 and 3 towers
        for (let p = 0; p < NPAD; p++) {
            let k = this.pKind[p];
            if (k < 0 || this.pLvl[p] == 0 || p == this.sel) continue;
            if (!api.project(<f32>PAD_X[p], <f32>(PAD_TOP + T_TOP[k] + 0.12), <f32>PAD_Z[p])) continue;
            let cx = Mathf.round(api.screenX), cy = Mathf.round(api.screenY) - 3;
            for (let n = 0; n < this.pLvl[p]; n++) {
                let yy = cy - <f32>(n * 3);
                api.rect(cx - 2, yy, 1, 1, goldC); api.rect(cx - 1, yy + 1, 1, 1, goldC); api.rect(cx, yy + 2, 1, 1, goldC);
                api.rect(cx + 1, yy + 1, 1, 1, goldC); api.rect(cx + 2, yy, 1, 1, goldC);
            }
        }

        // the top line: lives, gold, the wave, the score
        this.heart(api, 3, 3, red);
        api.text(10, 3, this.lives.toString(), pale, 1, dark);
        this.coin(api, 23, 3, goldC, api.rampColor(8, 1));
        let gs = this.gold.toString();
        api.text(30, 3, gs, t - this.denyT < 0.4 && Math.floor(t * 10.0) % 2 == 0 ? red : goldC, 1, dark);
        let ws = "WAVE " + max<i32>(1, this.wave).toString() + "/" + NWAVE.toString();
        if (this.wave == 0) ws = "WAVE 1/" + NWAVE.toString();
        api.textCentered(3, ws, pale, 1, dark);
        let sc = "SCORE " + this.score.toString();
        api.text(<f32>api.hudW - api.textWidth(sc, 1) - 3, 3, sc, pale, 1, dark);
        let bs = "BEST " + (api.demo ? this.demoBest : this.best).toString();
        api.text(<f32>api.hudW - api.textWidth(bs, 1) - 3, 10, bs, grey, 1, dark);

        // NEXT WAVE: bottom right, with the countdown as a bar and the early bonus
        if (this.nextBox(api)) {
            let bx = <f32>api.hudW - 56, by = <f32>api.hudH - 18;
            let pressed = api.demo && t - this.flashT < 0.2;
            this.box(api, bx, by, 54, 16, pressed ? goldC : dark, goldC);
            api.text(bx + 4, by + 3, this.wave == 0 ? "START" : "NEXT", pale, 1);
            let bonus = this.wave > 0 ? <i32>Math.floor(this.countdown) : 0;
            if (bonus > 0) {
                let bt = "+" + bonus.toString() + "G";
                api.text(bx + 50 - api.textWidth(bt, 1), by + 3, bt, goldC, 1);
            } else {
                api.text(bx + 25, by + 3, "WAVE", pale, 1);
            }
            let full = this.wave == 0 ? FIRST_WAIT : BETWEEN;
            let f = <f32>clamp(this.countdown / full, 0, 1);
            api.rect(bx + 4, by + 11, 46, 2, black);
            api.rect(bx + 4, by + 11, Mathf.round(46 * f), 2, goldC);
        }

        // the wave banner
        let ba = t - this.bannerT;
        if (ba < 2.2 && this.state == PLAY) {
            api.textCentered(22, this.bannerS, pale, 2, dark);
            if (this.bannerS2.length > 0) api.textCentered(35, this.bannerS2, pink, 1, dark);
        }

        // the hint before the first tower
        if (this.built == 0 && this.state == PLAY && !api.demo && this.sel < 0) {
            let blink = Math.floor(t * 2.0) % 4 != 3;
            if (blink) api.textCentered(<f32>api.hudH - 30, "TAP A STONE PAD TO BUILD A TOWER", pale, 1, dark);
            api.textCentered(<f32>api.hudH - 23, "HOLD THE PATH FOR 15 WAVES", grey, 1, dark);
        }

        // the end
        if (this.state != PLAY) {
            let won = this.state == WON;
            let w: f32 = 150, h: f32 = 50;
            let x = Mathf.floor((<f32>api.hudW - w) * 0.5), y: f32 = 38;
            this.box(api, x, y, w, h, dark, won ? goldC : red);
            api.textCentered(y + 6, won ? "VALLEY SAVED!" : "THE VALLEY FELL", won ? goldC : pink, 2, black);
            let s2 = "SCORE " + this.score.toString() + "   BEST " + (api.demo ? this.demoBest : this.best).toString();
            api.textCentered(y + 22, s2, pale, 1);
            let s3 = won ? "ALL 15 WAVES HELD WITH " + this.lives.toString() + " LIVES" : "WAVE " + this.wave.toString() + " BROKE THROUGH";
            api.textCentered(y + 30, s3, grey, 1);
            if (t - this.overT > 0.8 && Math.floor(t * 2.0) % 2 == 0) api.textCentered(y + 40, "TAP TO PLAY AGAIN", pale, 1);
        }
    }
}
