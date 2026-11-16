// Golem Hall: a first-person shooter in a roofless, torch-lit ancient hall. Clay golems lumber in from
// the far gate and the four side doorways, in waves. The pointer is the crosshair; held near the left or
// right edge of the view it turns the view (a turret: +-70 degrees, eased); a click fires a glowing bolt
// from the staff, if the charge meter holds one (it refills). A big golem takes 3 hits (2 for a small
// one; a hit on the head counts double): it cracks, staggers, loses an arm, and crumbles into chunks.
// A golem that reaches you raises its fists (the telegraph: a hit staggers it and cancels the slam) and
// slams: a heart, a shake and a red edge on the view. Three hearts.
//
// Every moving thing is a game bone from scene.bake.json: 5 golems (body, crack overlay, two arms, two
// legs each), 4 bolts, 12 clay chunks, 3 sparks, 4 brazier flames, the staff. Deterministic: api.rand()
// only. Demo mode (api.demo) plays itself like a decent human: it turns to threats, leads its shots,
// misses some and gets slammed sometimes.
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP, SFX_BLIP, SFX_CLICK, SFX_EXPLODE, SFX_HIT, SFX_LOSE, SFX_NOTE, SFX_BELL,
    SFX_POP, SFX_POWERUP, SFX_THUD, SFX_TICK, SFX_WHOOSH, SFX_ZAP } from "./game_api";

// ramps in art/palette.json order
const R_STONE: i32 = 0;   // night, umber, slate, grey, pale
const R_CLAY: i32 = 1;    // umber, crimson, red, tan
const R_RUNE: i32 = 2;    // night, purple, blue, cyan, pale

// the hall (metres, Y up; the player stands at the origin looking down -Z): models/env/make_env.py
const EYE_Y: f64 = 1.6;
const HW: f64 = 6.5;              // side walls' inner faces
const Z_FAR: f64 = -24.0;         // the far wall
const FOV: f64 = 68.0;
const YAW_MAX: f64 = 70.0;
const TURN_MAX: f64 = 58.0;       // degrees a second at the very edge
const EDGE: f64 = 0.17;           // the turning zone, a fraction of the view's width on each side
const REACH: f64 = 3.6;           // a golem stops this far from the player and slams (a shockwave)

// golem states
const G_OFF: i32 = 0;
const G_WALK: i32 = 1;
const G_WIND: i32 = 2;      // fists rising: the telegraph
const G_SLAM: i32 = 3;
const G_REST: i32 = 4;      // after a slam, before the next wind-up
const G_STAG: i32 = 5;      // hit: staggers back
const G_DIE: i32 = 6;       // crumbling

const NG: i32 = 5;
const NB: i32 = 4;
const NC: i32 = 12;
const NS: i32 = 3;
const NF: i32 = 4;
const NPOP: i32 = 6;
const NSLOT: i32 = 7;

const IDLE: i32 = 0;
const PLAY: i32 = 1;
const OVER: i32 = 2;

const CHARGE_COST: f64 = 0.25;

export class Game {
    // bones
    gBody: StaticArray<i32> = new StaticArray<i32>(NG);
    gCrack: StaticArray<i32> = new StaticArray<i32>(NG);
    gArmL: StaticArray<i32> = new StaticArray<i32>(NG);
    gArmR: StaticArray<i32> = new StaticArray<i32>(NG);
    gLegL: StaticArray<i32> = new StaticArray<i32>(NG);
    gLegR: StaticArray<i32> = new StaticArray<i32>(NG);
    bBone: StaticArray<i32> = new StaticArray<i32>(NB);
    cBone: StaticArray<i32> = new StaticArray<i32>(NC);
    sBone: StaticArray<i32> = new StaticArray<i32>(NS);
    fBone: StaticArray<i32> = new StaticArray<i32>(NF);
    staff: i32 = -1;

    // golems
    gState: StaticArray<i32> = new StaticArray<i32>(NG);
    gX: StaticArray<f64> = new StaticArray<f64>(NG);
    gZ: StaticArray<f64> = new StaticArray<f64>(NG);
    gYaw: StaticArray<f64> = new StaticArray<f64>(NG);
    gHp: StaticArray<i32> = new StaticArray<i32>(NG);
    gMax: StaticArray<i32> = new StaticArray<i32>(NG);
    gScale: StaticArray<f64> = new StaticArray<f64>(NG);
    gSpeed: StaticArray<f64> = new StaticArray<f64>(NG);
    gT: StaticArray<f64> = new StaticArray<f64>(NG);       // time in the state
    gPh: StaticArray<f64> = new StaticArray<f64>(NG);      // gait phase, in steps
    gSlot: StaticArray<i32> = new StaticArray<i32>(NG);
    gDoor: StaticArray<f64> = new StaticArray<f64>(NG);    // >0: still in a side passage (its side), 0: inside
    gArm: StaticArray<bool> = new StaticArray<bool>(NG);   // the left arm is still on
    gVX: StaticArray<f64> = new StaticArray<f64>(NG);      // velocity (for the demo's lead)
    gVZ: StaticArray<f64> = new StaticArray<f64>(NG);
    gFlash: StaticArray<f64> = new StaticArray<f64>(NG);   // since the last hit
    // the fallen arm
    aX: StaticArray<f64> = new StaticArray<f64>(NG);
    aY: StaticArray<f64> = new StaticArray<f64>(NG);
    aZ: StaticArray<f64> = new StaticArray<f64>(NG);
    aVX: StaticArray<f64> = new StaticArray<f64>(NG);
    aVY: StaticArray<f64> = new StaticArray<f64>(NG);
    aVZ: StaticArray<f64> = new StaticArray<f64>(NG);
    aT: StaticArray<f64> = new StaticArray<f64>(NG);
    aYaw: StaticArray<f64> = new StaticArray<f64>(NG);
    slotUsed: StaticArray<i32> = new StaticArray<i32>(NSLOT);

    // bolts
    bOn: StaticArray<bool> = new StaticArray<bool>(NB);
    bX: StaticArray<f64> = new StaticArray<f64>(NB);
    bY: StaticArray<f64> = new StaticArray<f64>(NB);
    bZ: StaticArray<f64> = new StaticArray<f64>(NB);
    bVX: StaticArray<f64> = new StaticArray<f64>(NB);
    bVY: StaticArray<f64> = new StaticArray<f64>(NB);
    bVZ: StaticArray<f64> = new StaticArray<f64>(NB);
    bAge: StaticArray<f64> = new StaticArray<f64>(NB);
    bNext: i32 = 0;

    // chunks
    cX: StaticArray<f64> = new StaticArray<f64>(NC);
    cY: StaticArray<f64> = new StaticArray<f64>(NC);
    cZ: StaticArray<f64> = new StaticArray<f64>(NC);
    cVX: StaticArray<f64> = new StaticArray<f64>(NC);
    cVY: StaticArray<f64> = new StaticArray<f64>(NC);
    cVZ: StaticArray<f64> = new StaticArray<f64>(NC);
    cAge: StaticArray<f64> = new StaticArray<f64>(NC);
    cSize: StaticArray<f64> = new StaticArray<f64>(NC);
    cSpin: StaticArray<f64> = new StaticArray<f64>(NC);
    cBounce: StaticArray<i32> = new StaticArray<i32>(NC);
    cNext: i32 = 0;

    // sparks
    sX: StaticArray<f64> = new StaticArray<f64>(NS);
    sY: StaticArray<f64> = new StaticArray<f64>(NS);
    sZ: StaticArray<f64> = new StaticArray<f64>(NS);
    sAge: StaticArray<f64> = new StaticArray<f64>(NS);
    sSize: StaticArray<f64> = new StaticArray<f64>(NS);
    sNext: i32 = 0;

    // floating score texts
    tText: Array<string> = new Array<string>(NPOP);
    tX: StaticArray<f64> = new StaticArray<f64>(NPOP);
    tY: StaticArray<f64> = new StaticArray<f64>(NPOP);
    tZ: StaticArray<f64> = new StaticArray<f64>(NPOP);
    tAge: StaticArray<f64> = new StaticArray<f64>(NPOP);
    tNext: i32 = 0;

    // the run
    mode: i32 = IDLE;
    wasDemo: bool = false;
    score: i32 = 0;
    best: i32 = 0;
    bestDemo: i32 = 0;
    hearts: i32 = 3;
    wave: i32 = 0;
    waveLeft: i32 = 0;       // golems still to spawn this wave
    waveT: f64 = 0;          // since the wave's banner
    waveClearT: f64 = 9;
    spawnIn: f64 = 0;
    runTime: f64 = 0;
    overTime: f64 = 0;
    hurtT: f64 = 9;
    kills: i32 = 0;

    // the view and the staff
    yaw: f64 = 0;
    yawVel: f64 = 0;
    eyeX: f64 = 0;
    eyeY: f64 = EYE_Y;
    fx: f64 = 0;
    fz: f64 = -1;
    rx: f64 = 1;
    rz: f64 = 0;
    hh: f64 = 0.67;
    hwid: f64 = 1.07;
    charge: f64 = 1;
    sinceShot: f64 = 9;
    emptyT: f64 = 9;
    recoil: f64 = 9;
    fireReq: bool = false;
    // touch-ready turning: the edges turn the view while a finger (or button) is down, or while a mouse
    // hovers there (a move with no press since the last release); a tap released at an edge stops it
    down: bool = false;
    hover: bool = false;
    aimX: f64 = 160;          // the crosshair, HUD pixels
    aimY: f64 = 100;
    staffYaw: f64 = 0;
    staffPitch: f64 = 12;
    orbX: f64 = 0;
    orbY: f64 = 1.3;
    orbZ: f64 = -0.7;

    // the demo's hand
    dX: f64 = 160;
    dY: f64 = 100;
    dTarget: i32 = -1;
    dReact: f64 = 0;
    dErrX: f64 = 0;
    dErrY: f64 = 0;
    dErrIn: f64 = 0;
    dShotIn: f64 = 0.35;

    // ray results
    hitT: f64 = 0;
    hitG: i32 = -1;
    hitHead: bool = false;
    px: f64 = 0;
    py: f64 = 0;
    pd: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < NG; i++) {
            let s = i.toString();
            this.gBody[i] = api.bone("body" + s);
            this.gCrack[i] = api.bone("crack" + s);
            this.gArmL[i] = api.bone("arml" + s);
            this.gArmR[i] = api.bone("armr" + s);
            this.gLegL[i] = api.bone("legl" + s);
            this.gLegR[i] = api.bone("legr" + s);
            this.gState[i] = G_OFF;
            this.hideGolem(api, i);
            this.aT[i] = -1;
        }
        for (let i = 0; i < NB; i++) {
            this.bBone[i] = api.bone("bolt" + i.toString());
            api.hide(this.bBone[i]);
        }
        for (let i = 0; i < NC; i++) {
            this.cBone[i] = api.bone("chunk" + i.toString());
            this.cAge[i] = 99;
            api.hide(this.cBone[i]);
        }
        for (let i = 0; i < NS; i++) {
            this.sBone[i] = api.bone("spark" + i.toString());
            this.sAge[i] = 9;
            api.hide(this.sBone[i]);
        }
        for (let i = 0; i < NF; i++) {
            this.fBone[i] = api.bone("flame" + i.toString());
        }
        for (let i = 0; i < NPOP; i++) {
            this.tText[i] = "";
            this.tAge[i] = 9;
        }
        this.staff = api.bone("staff");
        this.wasDemo = api.demo;
        if (api.demo) {
            this.newRun(api);
            this.opening(api);
        }
    }

    // ------------------------------------------------------------------ runs and waves

    private newRun(api: GameApi): void {
        this.mode = PLAY;
        this.score = 0;
        this.hearts = 3;
        this.wave = 0;
        this.runTime = 0;
        this.overTime = 0;
        this.hurtT = 9;
        this.charge = 1;
        this.kills = 0;
        for (let i = 0; i < NG; i++) {
            if (this.gState[i] != G_OFF) {
                this.gState[i] = G_OFF;
                this.hideGolem(api, i);
            }
            this.aT[i] = -1;
        }
        for (let i = 0; i < NSLOT; i++) {
            this.slotUsed[i] = -1;
        }
        for (let i = 0; i < NB; i++) {
            this.bOn[i] = false;
            api.hide(this.bBone[i]);
        }
        this.nextWave(api);
    }

    private nextWave(api: GameApi): void {
        this.wave++;
        this.waveLeft = 3 + 2 * this.wave;
        this.waveT = 0;
        this.spawnIn = this.wave == 1 ? 1.6 : 2.4;
        // a low horn: the wave's number climbs a step each time
        let root = 45.0 + <f64>min<i32>(this.wave - 1, 7);
        api.sound(SFX_WHOOSH, 0.35, 0.6);
        api.note(root, 0.7, 0, SFX_BELL, 0.05);
        api.note(root + 7.0, 0.6, 0, SFX_BELL, 0.3);
        api.note(root + 12.0, 0.55, 0, SFX_BELL, 0.55);
    }

    // the demo opens mid-wave: two golems already walking, one in view straight ahead
    private opening(api: GameApi): void {
        let g = this.spawnGolem(api, 0, false);
        if (g >= 0) {
            this.gZ[g] = -10.5;
            this.gX[g] = 0.6;
        }
        let h = this.spawnGolem(api, 2, true);
        if (h >= 0) {
            this.gX[h] = -5.2;
            this.gDoor[h] = 0;
            this.gPh[h] = 0.5;
        }
        this.waveLeft -= 2;
        this.waveT = 2.5;
        this.spawnIn = 3.0;
    }

    private gameOver(api: GameApi): void {
        this.mode = OVER;
        this.overTime = 0;
        if (api.demo) {
            this.bestDemo = max<i32>(this.bestDemo, this.score);
        } else {
            this.best = max<i32>(this.best, this.score);
        }
        api.sound(SFX_LOSE, 0.7, 0.9, 0, 0.25);
        api.note(41, 0.8, 0, SFX_BELL, 0.2);
        api.note(36, 0.8, 0, SFX_BELL, 0.7);
    }

    // ------------------------------------------------------------------ golems

    private hideGolem(api: GameApi, g: i32): void {
        api.hide(this.gBody[g]);
        api.hide(this.gCrack[g]);
        api.hide(this.gArmL[g]);
        api.hide(this.gArmR[g]);
        api.hide(this.gLegL[g]);
        api.hide(this.gLegR[g]);
    }

    // where: 0 the gate, 1-3 the left doorways (near to far), 4-6 the right ones
    private spawnGolem(api: GameApi, where: i32, small: bool): i32 {
        let g = -1;
        for (let i = 0; i < NG; i++) {
            if (this.gState[i] == G_OFF && this.aT[i] < 0) {
                g = i;
                break;
            }
        }
        if (g < 0) {
            return -1;
        }
        this.gState[g] = G_WALK;
        this.gT[g] = 0;
        this.gPh[g] = api.range(0, 2);
        this.gArm[g] = true;
        this.gFlash[g] = 9;
        this.gMax[g] = small ? 2 : 3;
        this.gHp[g] = this.gMax[g];
        this.gScale[g] = small ? 0.78 : api.range(0.95, 1.0);
        let w = <f64>min<i32>(this.wave, 8);
        this.gSpeed[g] = small ? 2.0 + 0.08 * w : 1.35 + 0.07 * w;
        let side = 0.0;
        if (where == 0) {
            this.gX[g] = api.range(-0.8, 0.8);
            this.gZ[g] = -27.0;
            this.gDoor[g] = 0;
        } else {
            side = where <= 3 ? -1.0 : 1.0;
            let j = (where - 1) % 3;
            let dz = j == 0 ? -3.0 : (j == 1 ? -9.5 : -16.5);
            this.gX[g] = side * 8.6;
            this.gZ[g] = dz + api.range(-0.3, 0.3);
            this.gDoor[g] = side;
        }
        // a free slot round the player, nearest the side it comes from
        let want = where == 0 ? 3 : (side < 0 ? (where == 1 ? 0 : 1) : (where == 4 ? 6 : 5));
        let best = -1;
        let bestD = 99;
        for (let k = 0; k < NSLOT; k++) {
            if (this.slotUsed[k] >= 0) {
                continue;
            }
            let d = abs<i32>(k - want) * 2 + (api.rand() < 0.5 ? 1 : 0);
            if (d < bestD) {
                bestD = d;
                best = k;
            }
        }
        this.gSlot[g] = best;
        if (best >= 0) {
            this.slotUsed[best] = g;
        }
        api.soundAt(SFX_THUD, this.gX[g], 1.0, this.gZ[g], 0.4, 0.5);
        return g;
    }

    private slotX(k: i32): f64 {
        let a = (<f64>k - 3.0) * 22.0 * Math.PI / 180;
        return Math.sin(a) * REACH;
    }

    private slotZ(k: i32): f64 {
        let a = (<f64>k - 3.0) * 22.0 * Math.PI / 180;
        return -Math.cos(a) * REACH;
    }

    private alive(g: i32): bool {
        let s = this.gState[g];
        return s != G_OFF && s != G_DIE;
    }

    private updateGolems(api: GameApi, dt: f64): void {
        for (let g = 0; g < NG; g++) {
            let s = this.gState[g];
            if (s == G_OFF) {
                continue;
            }
            this.gT[g] += dt;
            this.gFlash[g] += dt;
            let sc = this.gScale[g];
            let ox = this.gX[g];
            let oz = this.gZ[g];
            let walking = false;
            if (s == G_WALK && this.mode == PLAY) {
                walking = true;
                // the path: a doorway's passage straight into the central aisle (|x| < 2.3, clear of the
                // columns, braziers and rubble), or out of the gate; then to its slot round the player
                let tx: f64, tz: f64;
                if (this.gDoor[g] != 0) {
                    let entry = this.gZ[g] > -5.0 ? 3.4 : 2.0;
                    tx = this.gDoor[g] * entry;
                    tz = this.gZ[g];
                    if (Math.abs(this.gX[g]) < entry + 0.4) {
                        this.gDoor[g] = 0;
                    }
                } else if (this.gZ[g] < -23.0) {
                    tx = this.gX[g];
                    tz = -21.5;
                } else {
                    let k = this.gSlot[g];
                    tx = k >= 0 ? this.slotX(k) : 0;
                    tz = k >= 0 ? this.slotZ(k) : -REACH;
                }
                let dx = tx - this.gX[g];
                let dz = tz - this.gZ[g];
                let d = Math.sqrt(dx * dx + dz * dz);
                let sx = dx / Math.max(d, 0.01);
                let sz = dz / Math.max(d, 0.01);
                let inAisle = this.gDoor[g] == 0 && this.gZ[g] > -23.0;
                if (inAisle) {
                    // keep clear of the other golems
                    this.avoid(g);
                    sx += this.px;
                    sz += this.py;
                    // a slow weave across the path, far from the player
                    if (d > 3.0) {
                        let wv = Math.sin(this.gT[g] * 1.3 + <f64>g * 2.1) * 0.7;
                        sx += -(dz / d) * wv;
                        sz += (dx / d) * wv;
                    }
                }
                let n = Math.sqrt(sx * sx + sz * sz);
                // the lumber: faster mid-stride
                let ph = this.gPh[g] % 1.0;
                let v = this.gSpeed[g] * (0.55 + 0.9 * Math.sin(ph * Math.PI));
                let step = Math.min(v * dt, d);
                this.gX[g] += sx / Math.max(n, 0.01) * step;
                this.gZ[g] += sz / Math.max(n, 0.01) * step;
                if (inAisle) {
                    let lane = this.lane(this.gZ[g]);
                    this.gX[g] = Math.max(-lane, Math.min(lane, this.gX[g]));
                }
                let before = Math.floor(this.gPh[g]);
                let period = sc < 0.9 ? 0.42 : 0.6;
                this.gPh[g] += dt / period;
                if (Math.floor(this.gPh[g]) != before) {
                    this.footfall(api, g);
                }
                let fromP = Math.sqrt(this.gX[g] * this.gX[g] + this.gZ[g] * this.gZ[g]);
                if (this.gDoor[g] == 0 && this.gZ[g] > -23.0 && (d < 0.15 || fromP < REACH + 0.05)) {
                    this.gState[g] = G_WIND;
                    this.gT[g] = 0;
                    api.soundAt(SFX_WHOOSH, this.gX[g], 2.0, this.gZ[g], 0.45, 0.8);
                }
            } else if (s == G_WIND) {
                let wind = this.windTime();
                if (this.mode == PLAY && this.gT[g] >= wind) {
                    this.gState[g] = G_SLAM;
                    this.gT[g] = 0;
                }
                // a rising groan of ticks while the fists climb
                if (this.mode == PLAY && Math.floor(this.gT[g] * 8.0) != Math.floor((this.gT[g] - dt) * 8.0)) {
                    api.soundAt(SFX_TICK, this.gX[g], 2.0, this.gZ[g], 0.5 + this.gT[g] * 0.8, 0.7);
                }
            } else if (s == G_SLAM) {
                if (this.gT[g] >= 0.12 && this.gT[g] - dt < 0.12) {
                    this.slamLands(api, g);
                }
                if (this.gT[g] >= 0.45) {
                    this.gState[g] = G_REST;
                    this.gT[g] = 0;
                }
            } else if (s == G_REST) {
                if (this.mode == PLAY && this.gT[g] >= 1.8) {
                    this.gState[g] = G_WIND;
                    this.gT[g] = 0;
                    api.soundAt(SFX_WHOOSH, this.gX[g], 2.0, this.gZ[g], 0.45, 0.8);
                }
            } else if (s == G_STAG) {
                // pushed back from the player
                let d = Math.sqrt(this.gX[g] * this.gX[g] + this.gZ[g] * this.gZ[g]);
                let push = this.gT[g] < 0.15 ? 1.2 * dt : 0.0;
                this.gX[g] += this.gX[g] / Math.max(d, 0.1) * push;
                this.gZ[g] += this.gZ[g] / Math.max(d, 0.1) * push;
                if (this.gDoor[g] == 0 && this.gZ[g] > -23.0) {
                    let lane = this.lane(this.gZ[g]);
                    this.gX[g] = Math.max(-lane, Math.min(lane, this.gX[g]));
                }
                if (this.gT[g] >= 0.3) {
                    this.gState[g] = G_WALK;
                    this.gT[g] = 0;
                }
            } else if (s == G_DIE) {
                if (this.gT[g] >= 1.15) {
                    this.gState[g] = G_OFF;
                    this.hideGolem(api, g);
                    if (this.aT[g] >= 0) {
                        this.aT[g] = -1;
                    }
                    continue;
                }
            }
            this.gVX[g] = (this.gX[g] - ox) / Math.max(dt, 0.001);
            this.gVZ[g] = (this.gZ[g] - oz) / Math.max(dt, 0.001);
            // face the player (in the passage: face along it)
            let wantYaw = Math.atan2(-this.gX[g], -this.gZ[g]) * 180 / Math.PI;
            if (this.gDoor[g] != 0) {
                wantYaw = this.gDoor[g] > 0 ? -90.0 : 90.0;
            }
            if (s != G_DIE) {
                let dy = wantYaw - this.gYaw[g];
                while (dy > 180) {
                    dy -= 360;
                }
                while (dy < -180) {
                    dy += 360;
                }
                this.gYaw[g] += dy * (1.0 - Math.exp(-dt * 6.0));
            }
            this.poseGolem(api, g, walking);
        }
        this.updateArms(api, dt);
    }

    // how far from the hall's axis a golem may walk: the gate's braziers, then the columns, then open floor
    private lane(z: f64): f64 {
        return z < -18.5 ? 1.4 : (z < -4.6 ? 2.3 : 4.4);
    }

    private windTime(): f64 {
        return Math.max(0.75, 1.1 - 0.05 * <f64>(this.wave - 1));
    }

    // repulsion from the other golems: px, py (x, z)
    private avoid(g: i32): void {
        let x = this.gX[g];
        let z = this.gZ[g];
        let ax = 0.0;
        let az = 0.0;
        for (let o = 0; o < NG; o++) {
            if (o == g || !this.alive(o)) {
                continue;
            }
            let dx = x - this.gX[o];
            let dz = z - this.gZ[o];
            let d = Math.sqrt(dx * dx + dz * dz);
            if (d < 1.7 && d > 0.001) {
                let f = (1.7 - d) / 1.7 * 1.8;
                ax += dx / d * f;
                az += dz / d * f;
            }
        }
        this.px = ax;
        this.py = az;
    }

    private footfall(api: GameApi, g: i32): void {
        let d = Math.sqrt(this.gX[g] * this.gX[g] + this.gZ[g] * this.gZ[g]);
        // sparse: only the left foot, only within 15 m, quieter far away
        if (Math.floor(this.gPh[g]) % 2.0 != 0.0 || d > 15.0 || this.mode != PLAY) {
            return;
        }
        let vol = Math.max(0.15, Math.min(0.75, 1.0 - d / 16.0));
        api.soundAt(SFX_THUD, this.gX[g], 0.2, this.gZ[g], this.gScale[g] < 0.9 ? 0.75 : 0.5, vol);
    }

    // the golem's parts: the body, its crack overlay, arms at the shoulders, legs at the hips
    private poseGolem(api: GameApi, g: i32, walking: bool): void {
        let s = this.gState[g];
        let sc = this.gScale[g];
        let t = this.gT[g];
        let ph = this.gPh[g] % 2.0;
        let step = Math.floor(api.time * 10.0) / 10.0;   // stepped wobble, 10 fps
        let bodyPitch = 0.0;
        let roll = 0.0;
        let bob = 0.0;
        let armL = 0.0;
        let armR = 0.0;
        let legL = 0.0;
        let legR = 0.0;
        let sink = 0.0;
        let yaw = this.gYaw[g];
        if (s == G_WALK) {
            // the lumber, stepped at 8 fps
            let q = Math.floor(ph * 4.0) / 4.0;
            legL = 22.0 * Math.cos(q * Math.PI);
            legR = -legL;
            armL = -14.0 * Math.cos(q * Math.PI);
            armR = -armL;
            roll = 4.5 * Math.sin(q * Math.PI);
            bob = 0.06 * Math.abs(Math.sin(q * Math.PI)) * sc;
            bodyPitch = 6.0;
        } else if (s == G_WIND) {
            // fists climb overhead, shaking harder as the slam nears
            let u = Math.min(1.0, t / this.windTime());
            let e = Math.floor(u * 6.0) / 6.0;
            armL = -165.0 * e;
            armR = armL;
            bodyPitch = -10.0 * e;
            let shake = (Math.floor(api.time * 16.0) % 2.0 == 0.0 ? 1.0 : -1.0) * 3.5 * e;
            roll = shake;
            yaw += shake * 0.6;
        } else if (s == G_SLAM) {
            let u = Math.min(1.0, t / 0.12);
            armL = -165.0 + 150.0 * u;
            armR = armL;
            bodyPitch = -10.0 + 34.0 * u;
            bob = -0.12 * u * sc;
            if (t > 0.12) {
                armL = -15.0;
                armR = -15.0;
                bodyPitch = 24.0 - 30.0 * Math.min(1.0, (t - 0.12) / 0.33);
            }
        } else if (s == G_REST) {
            armL = -8.0;
            armR = -8.0;
            bodyPitch = -6.0 + 4.0 * Math.sin(step * 3.0);
        } else if (s == G_STAG) {
            let u = Math.min(1.0, t / 0.3);
            bodyPitch = -16.0 * (1.0 - u);
            armL = 30.0 * (1.0 - u);
            armR = armL;
            roll = (g % 2 == 0 ? 6.0 : -6.0) * (1.0 - u);
            legL = -10.0 * (1.0 - u);
            legR = 10.0 * (1.0 - u);
        } else if (s == G_DIE) {
            // the crumble: a jolt, then everything slumps and sinks into the floor
            let u = Math.min(1.0, t / 1.15);
            let e = Math.floor(u * 8.0) / 8.0;
            bodyPitch = 26.0 * e;
            roll = (g % 2 == 0 ? 14.0 : -14.0) * e;
            armL = 40.0 * e;
            armR = 30.0 * e;
            legL = -25.0 * e;
            legR = 25.0 * e;
            sink = 1.5 * sc * e * e;
        }
        let x = this.gX[g];
        let z = this.gZ[g];
        let y = bob - sink;
        let body = this.gBody[g];
        // a hit: a 2-frame squash
        let hs = this.gFlash[g] < 0.08 ? 0.94 : 1.0;
        api.place(body, x, y, z, yaw, bodyPitch, roll, sc * hs);
        if (this.gHp[g] < this.gMax[g] && s != G_OFF) {
            api.place(this.gCrack[g], x, y, z, yaw, bodyPitch, roll, sc * hs);
        } else {
            api.hide(this.gCrack[g]);
        }
        let bx = <f64>api.restX[body];
        let by = <f64>api.restY[body];
        let bz = <f64>api.restZ[body];
        api.transform(body, bx - 0.72, by + 1.78, bz);
        api.place(this.gArmR[g], api.tx, api.ty, api.tz, yaw, bodyPitch + armR, roll, sc * hs);
        if (this.gArm[g]) {
            api.transform(body, bx + 0.72, by + 1.78, bz);
            api.place(this.gArmL[g], api.tx, api.ty, api.tz, yaw, bodyPitch + armL, roll, sc * hs);
        }
        api.transform(body, bx + 0.29, by + 0.62, bz);
        api.place(this.gLegL[g], api.tx, api.ty, api.tz, yaw, legL, roll * 0.5, sc);
        api.transform(body, bx - 0.29, by + 0.62, bz);
        api.place(this.gLegR[g], api.tx, api.ty, api.tz, yaw, legR, roll * 0.5, sc);
    }

    // a lost arm tumbles to the floor and lies there until its golem is gone
    private updateArms(api: GameApi, dt: f64): void {
        for (let g = 0; g < NG; g++) {
            if (this.aT[g] < 0) {
                continue;
            }
            this.aT[g] += dt;
            if (this.gState[g] == G_OFF) {
                this.aT[g] = -1;
                api.hide(this.gArmL[g]);
                continue;
            }
            let rest = this.aY[g] <= 0.3 * this.gScale[g];
            if (!rest) {
                this.aVY[g] -= 14.0 * dt;
                this.aX[g] += this.aVX[g] * dt;
                this.aY[g] += this.aVY[g] * dt;
                this.aZ[g] += this.aVZ[g] * dt;
                if (this.aY[g] <= 0.3 * this.gScale[g]) {
                    this.aY[g] = 0.3 * this.gScale[g];
                    api.soundAt(SFX_THUD, this.aX[g], 0.2, this.aZ[g], 0.65, 0.6);
                    this.puffChunks(api, this.aX[g], 0.3, this.aZ[g], 2, 0.5);
                }
            }
            let tumble = rest ? 95.0 : Math.floor(this.aT[g] * 12.0) * 32.0;
            let sink = this.gState[g] == G_DIE ? this.gT[g] * 0.9 : 0.0;
            api.place(this.gArmL[g], this.aX[g], this.aY[g] - sink, this.aZ[g], this.aYaw[g], tumble, 20.0, this.gScale[g]);
        }
    }

    private dropArm(api: GameApi, g: i32): void {
        this.gArm[g] = false;
        let body = this.gBody[g];
        api.transform(body, <f64>api.restX[body] + 0.85, <f64>api.restY[body] + 1.2, <f64>api.restZ[body]);
        this.aX[g] = api.tx;
        this.aY[g] = api.ty;
        this.aZ[g] = api.tz;
        let yr = this.gYaw[g] * Math.PI / 180;
        // out to the golem's side and a little towards the player
        this.aVX[g] = Math.cos(yr) * 2.2 + Math.sin(yr) * 0.8;
        this.aVZ[g] = -Math.sin(yr) * 2.2 + Math.cos(yr) * 0.8;
        this.aVY[g] = 2.6;
        this.aT[g] = 0;
        this.aYaw[g] = this.gYaw[g] + 70.0;
    }

    private slamLands(api: GameApi, g: i32): void {
        api.soundAt(SFX_EXPLODE, this.gX[g], 0.5, this.gZ[g], 0.45, 1.0);
        api.soundAt(SFX_THUD, this.gX[g], 0.5, this.gZ[g], 0.35, 1.0, 0.03);
        this.puffChunks(api, this.gX[g] * 0.75, 0.2, this.gZ[g] * 0.75, 2, 0.45);
        // a heart at most every 1.5 s (two slams together cost one)
        if (this.mode != PLAY || this.hurtT < 1.5) {
            return;
        }
        this.hearts--;
        this.hurtT = 0;
        api.sound(SFX_HIT, 0.5, 1.0, 0, 0.04);
        if (this.hearts <= 0) {
            this.gameOver(api);
        }
    }

    private damage(api: GameApi, g: i32, head: bool, hx: f64, hy: f64, hz: f64): void {
        let dmg = head ? 2 : 1;
        this.gHp[g] -= dmg;
        this.gFlash[g] = 0;
        this.spark(api, hx, hy, hz, 1.0);
        api.soundAt(SFX_HIT, hx, hy, hz, head ? 1.05 : 0.8, 0.8);
        api.soundAt(SFX_THUD, hx, hy, hz, 0.6, 0.5);
        if (head) {
            api.noteAt(84, hx, hy, hz, 0.45, SFX_BELL);
        }
        this.puffChunks(api, hx, hy, hz, head ? 2 : 1, 0.45);
        if (this.gHp[g] <= 0) {
            this.crumble(api, g, head);
            return;
        }
        this.score += 1;
        if (this.gMax[g] == 3 && this.gHp[g] == 1 && this.gArm[g]) {
            this.dropArm(api, g);
            api.soundAt(SFX_POP, hx, hy, hz, 0.5, 0.8);
        }
        // stagger: cancels a wind-up
        this.gState[g] = G_STAG;
        this.gT[g] = 0;
    }

    private crumble(api: GameApi, g: i32, head: bool): void {
        this.gState[g] = G_DIE;
        this.gT[g] = 0;
        if (this.gSlot[g] >= 0) {
            this.slotUsed[this.gSlot[g]] = -1;
            this.gSlot[g] = -1;
        }
        let pts = (this.gMax[g] == 3 ? 10 : 6) + (head ? 4 : 0);
        this.score += pts;
        this.kills++;
        let x = this.gX[g];
        let z = this.gZ[g];
        let sc = this.gScale[g];
        this.popText("+" + pts.toString(), x, 2.6 * sc, z);
        api.soundAt(SFX_EXPLODE, x, 1.2, z, 0.7, 0.9);
        for (let k = 0; k < 4; k++) {
            api.soundAt(SFX_THUD, x, 0.3, z, 0.55 + 0.12 * <f64>k, 0.55 - 0.08 * <f64>k, 0.25 + 0.13 * <f64>k);
        }
        api.noteAt(head ? 79 : 76, x, 1.2, z, 0.5, SFX_NOTE, 0.05);
        api.noteAt(head ? 86 : 83, x, 1.2, z, 0.45, SFX_NOTE, 0.13);
        this.puffChunks(api, x, 1.3 * sc, z, 6, 1.0);
    }

    // ------------------------------------------------------------------ chunks, sparks, texts

    private puffChunks(api: GameApi, x: f64, y: f64, z: f64, n: i32, size: f64): void {
        for (let k = 0; k < n; k++) {
            let i = this.cNext;
            this.cNext = (this.cNext + 1) % NC;
            let a = api.range(0, Math.PI * 2);
            let sp = api.range(1.2, 3.0);
            this.cX[i] = x + Math.cos(a) * 0.2;
            this.cY[i] = y + api.range(-0.2, 0.3);
            this.cZ[i] = z + Math.sin(a) * 0.2;
            this.cVX[i] = Math.cos(a) * sp;
            this.cVZ[i] = Math.sin(a) * sp;
            this.cVY[i] = api.range(1.5, 4.0);
            this.cAge[i] = 0;
            this.cSize[i] = size * api.range(0.55, 1.0);
            this.cSpin[i] = api.range(-1, 1) * 600;
            this.cBounce[i] = 0;
        }
    }

    private updateChunks(api: GameApi, dt: f64): void {
        for (let i = 0; i < NC; i++) {
            if (this.cAge[i] >= 4.0) {
                continue;
            }
            this.cAge[i] += dt;
            let b = this.cBone[i];
            if (this.cAge[i] >= 4.0) {
                api.hide(b);
                continue;
            }
            let r = 0.22 * this.cSize[i];
            let rest = this.cBounce[i] >= 2;
            if (!rest) {
                this.cVY[i] -= 13.0 * dt;
                this.cX[i] += this.cVX[i] * dt;
                this.cY[i] += this.cVY[i] * dt;
                this.cZ[i] += this.cVZ[i] * dt;
                if (this.cY[i] < r) {
                    this.cY[i] = r;
                    this.cBounce[i]++;
                    this.cVY[i] = -this.cVY[i] * 0.3;
                    this.cVX[i] *= 0.4;
                    this.cVZ[i] *= 0.4;
                    if (this.cBounce[i] == 1 && this.cSize[i] > 0.6) {
                        api.soundAt(SFX_TICK, this.cX[i], 0, this.cZ[i], 0.6 + 0.3 * <f64>(i % 3), 0.35);
                    }
                }
            }
            // a pool of chunks on the floor; they sink away in the last 0.6 s
            let sink = this.cAge[i] > 3.4 ? (this.cAge[i] - 3.4) / 0.6 * r * 2.2 : 0.0;
            let spin = rest ? this.cSpin[i] * 0.1 : Math.floor(this.cAge[i] * 12.0) * this.cSpin[i] / 12.0;
            api.place(b, this.cX[i], this.cY[i] - sink, this.cZ[i], spin, spin * 0.6, 0, Math.max(0.2, this.cSize[i]));
        }
    }

    private spark(api: GameApi, x: f64, y: f64, z: f64, size: f64): void {
        let i = this.sNext;
        this.sNext = (this.sNext + 1) % NS;
        this.sX[i] = x;
        this.sY[i] = y;
        this.sZ[i] = z;
        this.sAge[i] = 0;
        this.sSize[i] = size;
    }

    private updateSparks(api: GameApi, dt: f64): void {
        for (let i = 0; i < NS; i++) {
            if (this.sAge[i] >= 0.3) {
                continue;
            }
            this.sAge[i] += dt;
            let b = this.sBone[i];
            if (this.sAge[i] >= 0.3) {
                api.hide(b);
                continue;
            }
            let u = this.sAge[i] / 0.3;
            let s = this.sSize[i] * (0.5 + 1.6 * Math.floor(u * 5.0) / 5.0);
            api.place(b, this.sX[i], this.sY[i], this.sZ[i], u * 200.0, u * 90.0, 0, s);
        }
    }

    private popText(s: string, x: f64, y: f64, z: f64): void {
        let i = this.tNext;
        this.tNext = (this.tNext + 1) % NPOP;
        this.tText[i] = s;
        this.tX[i] = x;
        this.tY[i] = y;
        this.tZ[i] = z;
        this.tAge[i] = 0;
    }

    // ------------------------------------------------------------------ the view

    // the camera basis from the view's yaw (level, no roll)
    private basis(api: GameApi): void {
        let a = this.yaw * Math.PI / 180;
        this.fx = Math.sin(a);
        this.fz = -Math.cos(a);
        this.rx = Math.cos(a);
        this.rz = Math.sin(a);
        this.hh = Math.tan(FOV * 0.5 * Math.PI / 180);
        let gw = <f64>api.gridW;
        let gh = <f64>api.gridH;
        this.hwid = gh > 1 ? this.hh * gw / gh : this.hh * 1.6;
    }

    // a world point in HUD pixels (px, py; pd its depth); false behind the eye
    private proj(api: GameApi, x: f64, y: f64, z: f64): bool {
        let dx = x - this.eyeX;
        let dy = y - this.eyeY;
        let dz = z;
        let depth = dx * this.fx + dz * this.fz;
        if (depth < 0.1) {
            return false;
        }
        let r = dx * this.rx + dz * this.rz;
        let nx = r / (depth * this.hwid);
        let ny = dy / (depth * this.hh);
        this.px = <f64>api.gridOX + (nx + 1.0) * 0.5 * <f64>api.gridW;
        this.py = <f64>api.gridOY + (1.0 - ny) * 0.5 * <f64>api.gridH;
        this.pd = depth;
        return true;
    }

    // the ray through a HUD pixel: its direction in px, py, pd (x, y, z)
    private ray(api: GameApi, hx: f64, hy: f64): void {
        let gw = Math.max(1.0, <f64>api.gridW);
        let gh = Math.max(1.0, <f64>api.gridH);
        let nx = ((hx - <f64>api.gridOX) / gw) * 2.0 - 1.0;
        let ny = 1.0 - ((hy - <f64>api.gridOY) / gh) * 2.0;
        let dx = this.fx + this.rx * nx * this.hwid;
        let dy = ny * this.hh;
        let dz = this.fz + this.rz * nx * this.hwid;
        let n = Math.sqrt(dx * dx + dy * dy + dz * dz);
        this.px = dx / n;
        this.py = dy / n;
        this.pd = dz / n;
    }

    // a ray from (ox, oy, oz) along unit (dx, dy, dz) against the golems: hitT, hitG, hitHead
    private rayGolems(ox: f64, oy: f64, oz: f64, dx: f64, dy: f64, dz: f64, maxT: f64): void {
        this.hitT = maxT;
        this.hitG = -1;
        this.hitHead = false;
        for (let g = 0; g < NG; g++) {
            if (!this.alive(g)) {
                continue;
            }
            let sc = this.gScale[g];
            for (let part = 0; part < 2; part++) {
                let cy = part == 0 ? 1.2 * sc : 2.08 * sc;
                let r = part == 0 ? 0.72 * sc : 0.36 * sc;
                let t = this.sphere(ox, oy, oz, dx, dy, dz, this.gX[g], cy, this.gZ[g], r);
                if (t >= 0 && t < this.hitT) {
                    this.hitT = t;
                    this.hitG = g;
                    this.hitHead = part == 1;
                }
            }
        }
    }

    private sphere(ox: f64, oy: f64, oz: f64, dx: f64, dy: f64, dz: f64, cx: f64, cy: f64, cz: f64, r: f64): f64 {
        let lx = cx - ox;
        let ly = cy - oy;
        let lz = cz - oz;
        let tc = lx * dx + ly * dy + lz * dz;
        let d2 = lx * lx + ly * ly + lz * lz - tc * tc;
        if (d2 > r * r) {
            return -1;
        }
        let th = Math.sqrt(r * r - d2);
        let t = tc - th;
        return t >= 0 ? t : (tc + th >= 0 ? 0 : -1);
    }

    // where a ray from the eye meets the hall: floor, walls, the far wall (columns ignored)
    private rayHall(ox: f64, oy: f64, oz: f64, dx: f64, dy: f64, dz: f64): f64 {
        let t = 40.0;
        if (dy < -1e-4) {
            t = Math.min(t, -oy / dy);
        }
        if (dx > 1e-4) {
            t = Math.min(t, (HW - ox) / dx);
        } else if (dx < -1e-4) {
            t = Math.min(t, (-HW - ox) / dx);
        }
        if (dz < -1e-4) {
            t = Math.min(t, (Z_FAR - oz) / dz);
        }
        return t;
    }

    private updateView(api: GameApi, dt: f64): void {
        // turn: the crosshair in the edge zones drives the yaw, eased in and out
        let W = <f64>api.hudW;
        let want = 0.0;
        if (W > 0 && this.steering(api)) {
            let u = this.aimX / W;
            if (u < EDGE) {
                want = -TURN_MAX * Math.min(1.0, (EDGE - u) / EDGE * 1.25);
            } else if (u > 1.0 - EDGE) {
                want = TURN_MAX * Math.min(1.0, (u - 1.0 + EDGE) / EDGE * 1.25);
            }
        }
        this.yawVel += (want - this.yawVel) * (1.0 - Math.exp(-dt * 5.0));
        this.yaw += this.yawVel * dt;
        if (this.yaw > YAW_MAX) {
            this.yaw = YAW_MAX;
            this.yawVel = Math.min(0, this.yawVel);
        } else if (this.yaw < -YAW_MAX) {
            this.yaw = -YAW_MAX;
            this.yawVel = Math.max(0, this.yawVel);
        }
        // a slam shakes the view for half a second, stepped
        let shake = 0.0;
        let shakeY = 0.0;
        if (this.hurtT < 0.5) {
            let k = Math.floor(this.hurtT * 30.0);
            let amp = 0.09 * (1.0 - this.hurtT / 0.5);
            shake = (k % 2.0 == 0.0 ? 1.0 : -1.0) * amp;
            shakeY = (k % 3.0 == 0.0 ? 1.0 : -0.5) * amp * 0.6;
        }
        this.basis(api);
        this.eyeX = shake * this.rx;
        this.eyeY = EYE_Y + shakeY;
        let ez = shake * this.rz;
        api.lookAt = true;
        api.perspective = true;
        api.fov = FOV;
        api.eyeX = this.eyeX;
        api.eyeY = this.eyeY;
        api.eyeZ = ez;
        api.targetX = this.eyeX + this.fx;
        api.targetY = this.eyeY;
        api.targetZ = ez + this.fz;
        // eyeZ is 0 but for the shake: proj() and ray() treat the eye as (eyeX, eyeY, 0)
    }

    // the staff in the lower right, pointing towards the aim; the bolt leaves from its orb
    private updateStaff(api: GameApi, dt: f64): void {
        let gx = this.eyeX + this.rx * 0.27 + this.fx * 0.58;
        let gy = this.eyeY - 0.42;
        let gz = this.rz * 0.27 + this.fz * 0.58;
        this.ray(api, this.aimX, this.aimY);
        let dx = this.px;
        let dy = this.py;
        let dz = this.pd;
        // aim at a point 12 m down the crosshair's ray, half way from the resting pose
        let ax = this.eyeX + dx * 12.0 - gx;
        let ay = this.eyeY + dy * 12.0 - gy;
        let az = dz * 12.0 - gz;
        let h = Math.sqrt(ax * ax + az * az);
        let aimYaw = Math.atan2(-ax, -az) * 180 / Math.PI;
        let aimPitch = Math.atan2(ay, h) * 180 / Math.PI;
        let restYaw = -this.yaw;
        let ddy = aimYaw - restYaw;
        while (ddy > 180) {
            ddy -= 360;
        }
        while (ddy < -180) {
            ddy += 360;
        }
        let wantYaw = restYaw + ddy * 0.6 - 6.0;
        let wantPitch = 8.0 + aimPitch * 0.6;
        let k = 1.0 - Math.exp(-dt * 14.0);
        this.staffYaw += (wantYaw - this.staffYaw) * k;
        this.staffPitch += (wantPitch - this.staffPitch) * k;
        let kick = this.recoil < 0.14 ? (1.0 - this.recoil / 0.14) : 0.0;
        let yr = this.staffYaw * Math.PI / 180;
        let pr = (this.staffPitch + 10.0 * kick) * Math.PI / 180;
        let ux = -Math.sin(yr) * Math.cos(pr);
        let uy = Math.sin(pr);
        let uz = -Math.cos(yr) * Math.cos(pr);
        gx -= ux * 0.07 * kick;
        gy -= uy * 0.07 * kick;
        gz -= uz * 0.07 * kick;
        // a bob while idle, stepped
        let bob = 0.008 * Math.sin(Math.floor(api.time * 6.0) / 6.0 * 2.2);
        api.place(this.staff, gx, gy + bob, gz, this.staffYaw, this.staffPitch + 10.0 * kick, 0, 1);
        this.orbX = gx + ux * 0.64;
        this.orbY = gy + bob + uy * 0.64;
        this.orbZ = gz + uz * 0.64;
    }

    private fire(api: GameApi): void {
        if (this.sinceShot < 0.16) {
            return;
        }
        if (this.charge < CHARGE_COST) {
            if (this.emptyT > 0.25) {
                api.sound(SFX_CLICK, 0.55, 0.7, 0.4);
                this.emptyT = 0;
            }
            return;
        }
        this.charge -= CHARGE_COST;
        this.sinceShot = 0;
        this.recoil = 0;
        // where the crosshair's ray meets a golem or the hall
        this.ray(api, this.aimX, this.aimY);
        let dx = this.px;
        let dy = this.py;
        let dz = this.pd;
        let tHall = this.rayHall(this.eyeX, this.eyeY, 0, dx, dy, dz);
        this.rayGolems(this.eyeX, this.eyeY, 0, dx, dy, dz, tHall);
        let t = this.hitT;
        let tx = this.eyeX + dx * t;
        let ty = this.eyeY + dy * t;
        let tz = dz * t;
        // from the orb towards that point; the bolt appears a little ahead of the orb
        let vx = tx - this.orbX;
        let vy = ty - this.orbY;
        let vz = tz - this.orbZ;
        let n = Math.sqrt(vx * vx + vy * vy + vz * vz);
        if (n < 0.5) {
            return;
        }
        vx /= n;
        vy /= n;
        vz /= n;
        let i = this.bNext;
        this.bNext = (this.bNext + 1) % NB;
        this.bOn[i] = true;
        this.bAge[i] = 0;
        this.bX[i] = this.orbX + vx * 0.9;
        this.bY[i] = this.orbY + vy * 0.9;
        this.bZ[i] = this.orbZ + vz * 0.9;
        this.bVX[i] = vx * 24.0;
        this.bVY[i] = vy * 24.0;
        this.bVZ[i] = vz * 24.0;
        let pan = Math.max(-0.6, Math.min(0.6, (this.aimX / Math.max(1.0, <f64>api.hudW)) * 2.0 - 1.0));
        api.sound(SFX_ZAP, 1.25, 0.55, pan);
        api.sound(SFX_WHOOSH, 1.6, 0.25, pan, 0.02);
    }

    private updateBolts(api: GameApi, dt: f64): void {
        for (let i = 0; i < NB; i++) {
            if (!this.bOn[i]) {
                continue;
            }
            this.bAge[i] += dt;
            let b = this.bBone[i];
            let ox = this.bX[i];
            let oy = this.bY[i];
            let oz = this.bZ[i];
            let sp = 24.0;
            let dx = this.bVX[i] / sp;
            let dy = this.bVY[i] / sp;
            let dz = this.bVZ[i] / sp;
            let len = sp * dt;
            // golems along this step
            this.rayGolems(ox, oy, oz, dx, dy, dz, len);
            if (this.hitG >= 0 && this.mode == PLAY) {
                let t = this.hitT;
                this.bOn[i] = false;
                api.hide(b);
                this.damage(api, this.hitG, this.hitHead, ox + dx * t, oy + dy * t, oz + dz * t);
                continue;
            }
            // the hall: floor, walls, columns
            let tH = this.rayHall(ox, oy, oz, dx, dy, dz);
            let nx = ox + dx * len;
            let ny = oy + dy * len;
            let nz = oz + dz * len;
            let hitCol = false;
            for (let k = 0; k < 6; k++) {
                let cx = k % 2 == 0 ? -3.6 : 3.6;
                let cz = k < 2 ? -6.0 : (k < 4 ? -13.0 : -20.0);
                let top = k == 2 ? 3.1 : 6.6;
                let ex = nx - cx;
                let ez = nz - cz;
                if (ex * ex + ez * ez < 0.36 && ny < top) {
                    hitCol = true;
                }
            }
            if (tH <= len || hitCol || this.bAge[i] > 2.2) {
                this.bOn[i] = false;
                api.hide(b);
                let t = Math.min(tH, len);
                let hx = ox + dx * t;
                let hy = oy + dy * t;
                let hz = oz + dz * t;
                if (this.bAge[i] <= 2.2) {
                    this.spark(api, hx, hy, hz, 0.7);
                    api.soundAt(SFX_POP, hx, hy, hz, 0.7, 0.35);
                }
                continue;
            }
            this.bX[i] = nx;
            this.bY[i] = ny;
            this.bZ[i] = nz;
            let h = Math.sqrt(dx * dx + dz * dz);
            let yaw = Math.atan2(-dx, -dz) * 180 / Math.PI;
            let pitch = Math.atan2(dy, h) * 180 / Math.PI;
            let grow = Math.min(1.0, 0.35 + this.bAge[i] * 6.0);
            let roll = Math.floor(this.bAge[i] * 20.0) * 40.0;
            api.place(b, nx, ny, nz, yaw, pitch, roll, grow);
        }
    }

    // the braziers' flames: a stepped flicker, out of step with each other
    private updateFlames(api: GameApi): void {
        let t = api.time;
        for (let i = 0; i < NF; i++) {
            let b = this.fBone[i];
            let k = Math.floor(t * 9.0 + <f64>i * 2.3);
            let h = 0.9 + 0.12 * Math.sin(k * 1.7 + <f64>i) + 0.06 * Math.sin(k * 3.1);
            let w = 1.0 + 0.06 * Math.sin(k * 2.3 + <f64>i * 0.7);
            api.placeScaled(b, <f64>api.restX[b], <f64>api.restY[b], <f64>api.restZ[b], k * 47.0 + <f64>i * 30.0, w, h, w);
        }
    }

    // ------------------------------------------------------------------ waves

    private updateWaves(api: GameApi, dt: f64): void {
        if (this.mode != PLAY) {
            return;
        }
        this.waveT += dt;
        let aliveN = 0;
        for (let g = 0; g < NG; g++) {
            if (this.alive(g)) {
                aliveN++;
            }
        }
        if (this.waveLeft <= 0) {
            if (aliveN == 0 && this.waveClearT > 8.0) {
                // the wave is cleared: a bonus, a chime, then the next
                this.waveClearT = 0;
                let bonus = 10 * this.wave;
                this.score += bonus;
                this.popText("WAVE CLEAR +" + bonus.toString(), this.eyeX + this.fx * 5.0, 2.4, this.fz * 5.0);
                api.sound(SFX_POWERUP, 0.75, 0.6);
            }
            if (this.waveClearT < 8.0) {
                this.waveClearT += dt;
                if (this.waveClearT >= 2.0) {
                    this.waveClearT = 9;
                    this.nextWave(api);
                }
            }
            return;
        }
        if (this.waveT < 1.6) {
            return;
        }
        this.spawnIn -= dt;
        let cap = min<i32>(NG, 2 + this.wave);
        if (this.spawnIn <= 0 && aliveN < cap) {
            this.spawnIn = Math.max(1.0, 2.8 - 0.3 * <f64>this.wave) * api.range(0.8, 1.2);
            // the gate most often; the doorways beside the player (out of view: turn!) from the second
            // golem on
            let r = api.rand();
            let where = 0;
            if (r < 0.28) {
                where = 0;
            } else {
                where = 1 + <i32>Math.floor((r - 0.28) / 0.72 * 6.0);
                if (this.wave == 1 && this.waveLeft == 3 + 2 * this.wave) {
                    where = 0;
                }
            }
            let small = this.wave >= 2 && api.rand() < 0.4;
            if (this.spawnGolem(api, where, small) >= 0) {
                this.waveLeft--;
            }
        }
    }

    // ------------------------------------------------------------------ the demo's hand

    private updateDemo(api: GameApi, dt: f64): void {
        if (this.mode == OVER) {
            this.dX += (160.0 - this.dX) * (1.0 - Math.exp(-dt * 3.0));
            if (this.overTime > 2.0) {
                this.newRun(api);
                this.opening(api);
            }
            return;
        }
        // the target: a golem winding up first (the nearest), else the nearest
        let best = -1;
        let bestScore = 1e9;
        for (let g = 0; g < NG; g++) {
            if (!this.alive(g)) {
                continue;
            }
            let d = Math.sqrt(this.gX[g] * this.gX[g] + this.gZ[g] * this.gZ[g]);
            let sc = d;
            if (this.gState[g] == G_WIND || this.gState[g] == G_REST) {
                sc -= 30.0;
            }
            if (this.gDoor[g] != 0) {
                sc += 15.0;
            }
            if (sc < bestScore) {
                bestScore = sc;
                best = g;
            }
        }
        if (best != this.dTarget) {
            this.dTarget = best;
            this.dReact = api.range(0.2, 0.45);
        }
        this.dReact -= dt;
        this.dErrIn -= dt;
        if (this.dErrIn <= 0) {
            // the hand's error, in HUD pixels: usually a few, sometimes a wild one
            this.dErrIn = api.range(0.4, 0.8);
            let big = api.rand() < 0.25;
            let e = big ? 13.0 : 4.0;
            this.dErrX = api.range(-e, e);
            this.dErrY = api.range(-e, e) * 0.7;
        }
        let W = <f64>api.hudW;
        let H = <f64>api.hudH;
        let wantX = W * 0.5;
        let wantY = H * 0.48;
        let onScreen = false;
        if (best >= 0) {
            let g = best;
            let sc = this.gScale[g];
            let d = Math.sqrt(this.gX[g] * this.gX[g] + this.gZ[g] * this.gZ[g]);
            // lead: where it will be when the bolt arrives
            let lead = d / 24.0 + 0.05;
            let tx = this.gX[g] + this.gVX[g] * lead;
            let tz = this.gZ[g] + this.gVZ[g] * lead;
            let ty = 1.35 * sc;
            if (this.proj(api, tx, ty, tz)) {
                wantX = this.px + this.dErrX;
                wantY = this.py + this.dErrY;
                onScreen = wantX > W * EDGE && wantX < W * (1.0 - EDGE);
            }
            if (!onScreen) {
                // turn towards it: push the hand into the edge on its side
                let side = tx * this.rx + tz * this.rz;
                let ahead = tx * this.fx + tz * this.fz;
                let ang = Math.atan2(side, ahead);
                wantX = ang < 0 ? W * 0.03 : W * 0.97;
                wantY = H * 0.5;
                if (Math.abs(ang) < 0.5 && this.px > 0) {
                    wantX = this.px;
                }
            }
        }
        // the hand moves at a hand's speed, with a little lag
        let k = 1.0 - Math.exp(-dt * 8.0);
        let mx = (wantX - this.dX) * k;
        let my = (wantY - this.dY) * k;
        let m = Math.sqrt(mx * mx + my * my);
        let lim = 240.0 * dt;
        if (m > lim) {
            mx *= lim / m;
            my *= lim / m;
        }
        this.dX += mx;
        this.dY += my;
        // fire when on target, keeping a bolt in reserve unless the threat is close
        this.dShotIn -= dt;
        if (best >= 0 && onScreen && this.dReact <= 0 && this.dShotIn <= 0) {
            let ex = this.dX - wantX;
            let ey = this.dY - wantY;
            let d = Math.sqrt(this.gX[best] * this.gX[best] + this.gZ[best] * this.gZ[best]);
            let urgent = d < 7.0 || this.gState[best] == G_WIND;
            // a player lets them come: no shots past 15 m, few past 10
            let inRange = d < 10.0 || (d < 15.0 && this.charge >= 0.99);
            if (ex * ex + ey * ey < 12.0 && inRange && (this.charge >= 0.5 || (urgent && this.charge >= CHARGE_COST))) {
                this.fire(api);
                this.dShotIn = api.range(0.35, 0.75);
            }
        }
    }

    // ------------------------------------------------------------------ the frame

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged || api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.newRun(api);
            this.yaw = 0;
            this.yawVel = 0;
            if (api.demo) {
                this.opening(api);
            }
        }
        if (this.mode == PLAY) {
            this.runTime += dt;
        } else if (this.mode == OVER) {
            this.overTime += dt;
        }
        this.hurtT += dt;
        this.sinceShot += dt;
        this.emptyT += dt;
        this.recoil += dt;
        for (let i = 0; i < NPOP; i++) {
            this.tAge[i] += dt;
        }
        // the charge refills a quarter of a second after the last shot
        if (this.sinceShot > 0.25) {
            let was = this.charge;
            this.charge = Math.min(1.0, this.charge + 0.27 * dt);
            if (was < 1.0 && this.charge >= 1.0 && this.mode == PLAY) {
                api.sound(SFX_BLIP, 1.5, 0.25);
            }
        }

        // the crosshair: the demo's hand or the pointer
        if (api.demo) {
            this.basis(api);
            this.updateDemo(api, dt);
            this.aimX = this.dX;
            this.aimY = this.dY;
        } else if (api.pointerX >= 0) {
            this.aimX = <f64>api.pointerX;
            this.aimY = <f64>api.pointerY;
        } else {
            this.aimX = <f64>api.hudW * 0.5;
            this.aimY = <f64>api.hudH * 0.48;
        }
        this.updateView(api, dt);
        this.updateStaff(api, dt);
        if (this.fireReq) {
            this.fireReq = false;
            if (this.mode == PLAY) {
                this.fire(api);
            }
        }
        this.updateWaves(api, dt);
        this.updateGolems(api, dt);
        this.updateBolts(api, dt);
        this.updateChunks(api, dt);
        this.updateSparks(api, dt);
        this.updateFlames(api);
    }

    // the crosshair turns the view at the edges: always in the demo; for a player while pressed, or
    // while a mouse hovers (touch moves only while a finger is down, so a lifted finger stops the turn)
    private steering(api: GameApi): bool {
        return api.demo || (api.pointerX >= 0 && (this.down || this.hover));
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_UP) {
            this.down = false;
            this.hover = false;
        } else if (kind == POINTER_MOVE) {
            if (!this.down) {
                this.hover = true;
            }
        }
        if (kind == POINTER_DOWN) {
            this.down = true;
            this.aimX = <f64>x;
            this.aimY = <f64>y;
            if (this.mode == IDLE) {
                this.newRun(api);
                this.fireReq = true;
            } else if (this.mode == OVER) {
                if (this.overTime > 0.8) {
                    this.newRun(api);
                    this.yaw = 0;
                    this.yawVel = 0;
                }
            } else {
                this.fireReq = true;
            }
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let NIGHT = api.rampColor(R_STONE, 0);
        let UMBER = api.rampColor(R_STONE, 1);
        let SLATE = api.rampColor(R_STONE, 2);
        let GREY = api.rampColor(R_STONE, 3);
        let PALE = api.rampColor(R_STONE, 4);
        let RED = api.rampColor(R_CLAY, 2);
        let CRIMSON = api.rampColor(R_CLAY, 1);
        let TAN = api.rampColor(R_CLAY, 3);
        let CYAN = api.rampColor(R_RUNE, 3);
        let BLUE = api.rampColor(R_RUNE, 2);
        let PURPLE = api.rampColor(R_RUNE, 1);
        let W = <f32>api.hudW;
        let Hh = <f32>api.hudH;
        let best = api.demo ? this.bestDemo : this.best;
        this.basis(api);

        // the hurt: a red edge round the view, thinning, stepped
        if (this.hurtT < 0.8) {
            let th = <f32>Math.floor((1.0 - this.hurtT / 0.8) * 4.0) + 1;
            api.rect(0, 0, W, th, RED);
            api.rect(0, Hh - th, W, th, RED);
            api.rect(0, th, th, Hh - 2 * th, RED);
            api.rect(W - th, th, th, Hh - 2 * th, RED);
            // a dotted inner rim
            for (let x: f32 = th + 1; x < W - th - 1; x += 3) {
                api.rect(x, th, 1, 1, CRIMSON);
                api.rect(x + 1, Hh - th - 1, 1, 1, CRIMSON);
            }
            for (let y: f32 = th + 1; y < Hh - th - 1; y += 3) {
                api.rect(th, y, 1, 1, CRIMSON);
                api.rect(W - th - 1, y + 1, 1, 1, CRIMSON);
            }
        }

        // the telegraph: a "!" over each golem winding up; off-screen threats as arrows at the edges
        for (let g = 0; g < NG; g++) {
            if (!this.alive(g)) {
                continue;
            }
            let sc = this.gScale[g];
            let s = this.gState[g];
            let threat = s == G_WIND || s == G_REST || s == G_SLAM;
            let d = Math.sqrt(this.gX[g] * this.gX[g] + this.gZ[g] * this.gZ[g]);
            let on = this.proj(api, this.gX[g], 2.75 * sc, this.gZ[g]);
            let sx = this.px;
            let sy = this.py;
            if (on && sx > 2 && sx < <f64>W - 2) {
                if (s == G_WIND && Math.floor(api.time * 8.0) % 2.0 == 0.0) {
                    api.text(<f32>Math.round(sx - 1.0), <f32>Math.max(14.0, Math.round(sy)), "!", TAN, 2, NIGHT);
                }
            } else if (threat || d < 7.0) {
                let side = this.gX[g] * this.rx + this.gZ[g] * this.rz;
                let col = threat && Math.floor(api.time * 6.0) % 2.0 == 0.0 ? RED : TAN;
                let y: f32 = Hh * 0.5 - 4;
                if (side < 0) {
                    api.text(3, y, "<", col, 2, NIGHT);
                    if (threat) {
                        api.text(9, y, "<", col, 2, NIGHT);
                    }
                } else {
                    api.text(W - 9, y, ">", col, 2, NIGHT);
                    if (threat) {
                        api.text(W - 15, y, ">", col, 2, NIGHT);
                    }
                }
            }
        }

        // floating scores
        for (let i = 0; i < NPOP; i++) {
            if (this.tAge[i] >= 1.1) {
                continue;
            }
            if (this.proj(api, this.tX[i], this.tY[i] + this.tAge[i] * 0.8, this.tZ[i])) {
                let s = this.tText[i];
                let w = api.textWidth(s, 1);
                api.text(<f32>Math.round(this.px - <f64>w * 0.5), <f32>Math.round(this.py), s, TAN, 1, NIGHT);
            }
        }

        // score and best, top left; the wave and the hearts, top right
        api.text(6, 5, "SCORE " + this.score.toString(), PALE, 2, NIGHT);
        api.text(6, 19, "BEST " + best.toString(), GREY, 1, NIGHT);
        if (this.mode != IDLE) {
            let ws = "WAVE " + this.wave.toString();
            api.text(W - 6 - api.textWidth(ws, 1), 5, ws, GREY, 1, NIGHT);
        }
        for (let i = 0; i < 3; i++) {
            let x = W - 33.0 + <f32>(i * 9);
            let alive = i < this.hearts;
            let blink = !alive && i == this.hearts && this.hurtT < 1.0 && Math.floor(this.hurtT * 8.0) % 2.0 == 0.0;
            this.heart(api, x, 13, alive || blink ? RED : UMBER, NIGHT);
        }

        // the charge meter, bottom left: four cells, the filling one partly; blinks when empty
        let mx: f32 = 6;
        let my: f32 = Hh - 12;
        api.text(mx, my - 7, "BOLTS", this.charge < CHARGE_COST && this.emptyT < 0.6 && Math.floor(this.emptyT * 10.0) % 2.0 == 0.0 ? RED : GREY, 1, NIGHT);
        api.rect(mx - 1, my - 1, 4 * 11 + 1, 8, NIGHT);
        for (let c = 0; c < 4; c++) {
            let cx = mx + <f32>(c * 11);
            let fill = Math.min(1.0, Math.max(0.0, (this.charge - <f64>c * CHARGE_COST) / CHARGE_COST));
            api.rect(cx, my, 10, 6, PURPLE);
            let fw = <f32>Math.floor(fill * 10.0);
            if (fw > 0) {
                api.rect(cx, my, fw, 6, fill >= 1.0 ? CYAN : BLUE);
                if (fill >= 1.0) {
                    api.rect(cx + 1, my + 1, 3, 1, PALE);
                }
            }
        }

        // the crosshair: a cross with a gap; tan over a golem, cyan otherwise
        let cx = <f32>Math.round(this.aimX);
        let cy = <f32>Math.round(this.aimY);
        this.ray(api, this.aimX, this.aimY);
        let tHall = this.rayHall(this.eyeX, this.eyeY, 0, this.px, this.py, this.pd);
        this.rayGolems(this.eyeX, this.eyeY, 0, this.px, this.py, this.pd, tHall);
        let cc = this.hitG >= 0 ? TAN : CYAN;
        let W2 = W;
        let turning = this.aimX < <f64>W2 * EDGE || this.aimX > <f64>W2 * (1.0 - EDGE);
        if (this.mode != OVER) {
            for (let pass = 0; pass < 2; pass++) {
                let o: f32 = pass == 0 ? 1 : 0;
                let col = pass == 0 ? NIGHT : cc;
                api.rect(cx - 5 + o, cy + o, 3, 1, col);
                api.rect(cx + 3 + o, cy + o, 3, 1, col);
                api.rect(cx + o, cy - 5 + o, 1, 3, col);
                api.rect(cx + o, cy + 3 + o, 1, 3, col);
                api.rect(cx + o, cy + o, 1, 1, col);
            }
            if (turning && this.steering(api)) {
                let left = this.aimX < <f64>W2 * 0.5;
                let atLimit = left ? this.yaw <= -YAW_MAX + 0.5 : this.yaw >= YAW_MAX - 0.5;
                if (!atLimit) {
                    api.text(left ? cx - 13 : cx + 9, cy - 2, left ? "<" : ">", cc, 1, NIGHT);
                }
            }
        }

        // the wave banner
        if (this.mode == PLAY && this.waveT < 2.0 && this.runTime > 0.05) {
            let s = "WAVE " + this.wave.toString();
            api.textCentered(Hh * 0.3, s, TAN, 3, NIGHT);
        }

        if (this.mode == IDLE) {
            api.textCentered(32, "CLICK TO FIRE", PALE, 2, NIGHT);
            api.textCentered(46, "AIM WITH THE POINTER - HOLD IT AT AN EDGE TO TURN", GREY, 1, NIGHT);
            api.textCentered(54, "STOP THE GOLEMS BEFORE THEY REACH YOU", GREY, 1, NIGHT);
        } else if (this.mode == OVER) {
            api.rect(0, 70, W, 50, NIGHT);
            api.rect(0, 70, W, 1, CRIMSON);
            api.rect(0, 119, W, 1, CRIMSON);
            api.textCentered(76, "CRUSHED!", RED, 3, 0);
            api.textCentered(96, "SCORE " + this.score.toString() + "   BEST " + best.toString() + "   WAVE " + this.wave.toString(), TAN, 1, 0);
            if (this.overTime > 0.8 && Math.floor(this.overTime * 2.0) % 2.0 == 0.0) {
                api.textCentered(107, api.demo ? "DEMO" : "CLICK TO PLAY AGAIN", CYAN, 1, 0);
            }
        } else if (this.runTime < 4.0 && !api.demo && this.waveT >= 2.0) {
            api.textCentered(Hh - 12, "HOLD THE POINTER AT AN EDGE TO TURN", GREY, 1, NIGHT);
        }
        if (api.demo && this.mode != OVER) {
            api.textCentered(5, "DEMO", SLATE, 1, NIGHT);
        }
    }

    // a 7 x 6 pixel heart with a shadow
    private heart(api: GameApi, x: f32, y: f32, c: u32, ink: u32): void {
        for (let pass = 0; pass < 2; pass++) {
            let o: f32 = pass == 0 ? 1 : 0;
            let col = pass == 0 ? ink : c;
            api.rect(x + 1 + o, y + o, 2, 1, col);
            api.rect(x + 4 + o, y + o, 2, 1, col);
            api.rect(x + o, y + 1 + o, 7, 2, col);
            api.rect(x + 1 + o, y + 3 + o, 5, 1, col);
            api.rect(x + 2 + o, y + 4 + o, 3, 1, col);
            api.rect(x + 3 + o, y + 5 + o, 1, 1, col);
        }
    }
}
