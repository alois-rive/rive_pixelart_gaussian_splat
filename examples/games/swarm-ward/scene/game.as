// Swarm Ward: a lamplighter keeps watch on a haunted moor for one night. He walks toward the
// pointer and never attacks by hand: his weapons fire on their own. Murk moths, peat shamblers and
// barrow hounds close in from every side in growing waves, cairn brutes stride in now and then,
// and at dawn the Mire King rises. Defeated monsters leave wisps of light (XP); every level the
// night pauses and three cards offer a new weapon, a weapon level or a passive. Survive to dawn and
// beat the king. Pointer only; demo mode plays itself.
//
// The bone budget (63): every moving thing is a pooled game bone, recycled the moment it is free.
// 29 foe slots carry up to 77 creatures (a moth slot is a swarm of five baked together); hit pops,
// death bursts, damage numbers, the storm-wick lightning and the cards cost no bone (HUD).
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP, SFX_BLIP, SFX_COIN, SFX_HIT, SFX_EXPLODE, SFX_SHOOT,
         SFX_POWERUP, SFX_THUD, SFX_WHOOSH, SFX_NOTE, SFX_BELL, SFX_LOSE, SFX_WIN, SFX_TICK, SFX_POP,
         SFX_CLICK, SFX_ZAP } from "./game_api";

const ST_IDLE: i32 = 0;   // before the first click: the hint
const ST_PLAY: i32 = 1;
const ST_CARDS: i32 = 2;  // a level up: the night holds still, three cards
const ST_OVER: i32 = 3;   // the lantern went out
const ST_DAWN: i32 = 4;   // won

// the camera: orthographic, yaw 0, pitch 53.13 (sin 0.8); one art pixel = 0.05 m in x, 0.0625 m in z
const TEXEL: f64 = 0.05;
const ZTEX: f64 = 0.0625;
const WRAP: f64 = 6.0;    // the origin jumps by 6 m: 120 texels in x, 96 in z (no pixel changes)
const CELL: f64 = 12.0;   // the decor patches leapfrog on a 12 m grid
const NIGHT: f64 = 180.0; // seconds to dawn
const VIEW_X: f64 = 5.4;  // half the view on the ground, metres
const VIEW_Z: f64 = 4.2;

// foes: slots 0-11 moth swarms, 12-19 shamblers, 20-25 hounds, 26-27 brutes, 28 the boss
const K_MOTH: i32 = 0;
const K_SHAM: i32 = 1;
const K_HOUND: i32 = 2;
const K_BRUTE: i32 = 3;
const K_BOSS: i32 = 4;
const NF: i32 = 29;
const K_FIRST: StaticArray<i32> = [0, 12, 20, 26, 28];
const K_COUNT: StaticArray<i32> = [12, 8, 6, 2, 1];
const K_R: StaticArray<f64> = [0.55, 0.45, 0.42, 0.8, 1.3];      // body radius
const K_HP: StaticArray<f64> = [9, 22, 14, 190, 1700];
const K_SPEED: StaticArray<f64> = [2.1, 1.15, 2.7, 1.3, 1.45];
const K_DMG: StaticArray<f64> = [4, 7, 6, 15, 16];
const K_XP: StaticArray<i32> = [4, 3, 3, 30, 0];
const K_KILLS: StaticArray<i32> = [5, 1, 1, 1, 1];
const K_KB: StaticArray<f64> = [1.0, 0.65, 0.9, 0.12, 0.0];     // how far a hit pushes it
const K_POP: StaticArray<f64> = [1.5, 0.85, 1.15, 0.6, 0.45];    // the pop's pitch

// weapons and passives (card ids)
const W_SPARK: i32 = 0;
const W_MOTE: i32 = 1;
const W_PULSE: i32 = 2;
const W_EMBER: i32 = 3;
const W_BOLT: i32 = 4;
const P_BOOTS: i32 = 5;
const P_HOOK: i32 = 6;
const P_COAT: i32 = 7;
const P_FLASK: i32 = 8;
const P_WICK: i32 = 9;
const C_TEA: i32 = 10;
const NUP: i32 = 10;
const MAXLV: StaticArray<i32> = [5, 5, 5, 5, 5, 4, 4, 4, 3, 3, 99];
const NAMES: StaticArray<string> = ["FLINT SPARKS", "WARD MOTES", "LAMP PULSE", "CINDER TRAIL", "STORM WICK",
                                    "SWIFT BOOTS", "LONG HOOK", "TIN COAT", "OIL FLASK", "BRIGHT WICK", "WARM TEA"];

// weapon tables, per level 1-5
const SP_CD: StaticArray<f64> = [1.0, 0.95, 0.85, 0.8, 0.62];
const SP_N: StaticArray<i32> = [1, 2, 2, 3, 3];
const SP_DMG: StaticArray<f64> = [10, 10, 14, 14, 18];
const SP_PIERCE: StaticArray<i32> = [0, 0, 1, 1, 2];
const MO_N: StaticArray<i32> = [1, 2, 3, 3, 3];
const MO_R: StaticArray<f64> = [1.25, 1.3, 1.4, 1.65, 1.85];
const MO_DMG: StaticArray<f64> = [7, 8, 9, 12, 15];
const MO_SPIN: StaticArray<f64> = [3.4, 3.6, 3.9, 4.2, 5.0];     // radians a second
const PU_CD: StaticArray<f64> = [3.2, 2.9, 2.6, 2.3, 1.9];
const PU_R: StaticArray<f64> = [2.2, 2.5, 2.6, 2.9, 3.0];
const PU_DMG: StaticArray<f64> = [12, 14, 18, 20, 27];
const EM_LIFE: StaticArray<f64> = [1.9, 2.1, 2.4, 2.5, 2.8];
const EM_DMG: StaticArray<f64> = [5, 7, 8, 10, 13];
const EM_R: StaticArray<f64> = [0.45, 0.5, 0.6, 0.62, 0.7];
const BO_CD: StaticArray<f64> = [2.6, 2.3, 2.1, 1.9, 1.5];
const BO_N: StaticArray<i32> = [1, 2, 2, 3, 3];
const BO_DMG: StaticArray<f64> = [26, 30, 40, 44, 55];

const NM: i32 = 3;   // motes
const NS: i32 = 6;   // sparks
const NE: i32 = 5;   // cinders
const NW: i32 = 10;  // wisps
const NPOP: i32 = 28;
const NNUM: i32 = 14;
const NBOLT: i32 = 4;

// palette ramps (art/palette.json order) for the HUD
const R_STONE: i32 = 3;
const R_SLATE: i32 = 4;
const R_COAT: i32 = 5;
const R_SKIN: i32 = 6;
const R_BLOOD: i32 = 9;
const R_GLOW: i32 = 10;
const R_EMBER: i32 = 11;
const R_WISP: i32 = 12;
const R_EYE: i32 = 13;

function clampf(v: f64, a: f64, b: f64): f64 {
    return v < a ? a : (v > b ? b : v);
}

function smooth(a: f64, b: f64, v: f64): f64 {
    let t = clampf((v - a) / (b - a), 0, 1);
    return t * t * (3 - 2 * t);
}

function stepYaw(dx: f64, dz: f64, steps: f64): f64 {
    let a = Math.atan2(dx, dz) * 180 / Math.PI;
    let s = 360.0 / steps;
    return Math.round(a / s) * s;
}

function hash(n: i32): f64 {
    let h = <u32>n * 2654435761;
    h ^= h >> 15;
    h *= 2246822519;
    h ^= h >> 13;
    return <f64>(h & 0xFFFF) / 65536.0;
}

function clock(s: f64): string {
    let t = <i32>Math.max(0, Math.ceil(s));
    let m = t / 60, r = t % 60;
    return m.toString() + ":" + (r < 10 ? "0" : "") + r.toString();
}

export class Game {
    state: i32 = ST_IDLE;
    stateT: f64 = 0;
    runT: f64 = 0;
    started: bool = false;
    kills: i32 = 0;
    level: i32 = 1;
    xp: i32 = 0;
    pending: i32 = 0;
    best: f64 = -1;         // best time survived (dawn counts NIGHT + the fight)
    bestKills: i32 = 0;
    bestDawn: bool = false;
    newBest: bool = false;
    won: bool = false;
    endT: f64 = 0;          // the run's time at its end

    // the world: logical metres; every bone sits at logical - origin
    ox: f64 = 0;
    oz: f64 = 0;
    camX: f64 = 0;          // snapped, placed (logical - origin)
    camZ: f64 = 0;

    // bones
    bHero: i32 = -1;
    bGround: i32 = -1;
    bDecor: StaticArray<i32> = new StaticArray<i32>(4);
    bFoe: StaticArray<i32> = new StaticArray<i32>(NF);
    bMote: StaticArray<i32> = new StaticArray<i32>(NM);
    bRing: i32 = -1;
    bSpark: StaticArray<i32> = new StaticArray<i32>(NS);
    bEmber: StaticArray<i32> = new StaticArray<i32>(NE);
    bWisp: StaticArray<i32> = new StaticArray<i32>(NW);
    bFlask: i32 = -1;

    // the hero
    hx: f64 = 0;
    hz: f64 = 0;
    hvx: f64 = 0;
    hvz: f64 = 0;
    hYaw: f64 = 0;
    hWalk: f64 = 0;
    hp: f64 = 100;
    hpMax: f64 = 100;
    invT: f64 = 0;
    hurtT: f64 = 0;
    shakeT: f64 = 0;
    goX: f64 = 0;
    goZ: f64 = 0;
    hasGo: bool = false;

    // upgrades
    lv: StaticArray<i32> = new StaticArray<i32>(11);
    owned: i32 = 0;
    cardId: StaticArray<i32> = new StaticArray<i32>(3);
    cardT: f64 = 0;
    hover: i32 = -1;
    pickT: f64 = -1;        // a card was picked: it flashes, then the night goes on
    picked: i32 = -1;

    // foes
    fOn: StaticArray<i32> = new StaticArray<i32>(NF);   // 0 free, 1 alive, 2 dying
    fKind: StaticArray<i32> = new StaticArray<i32>(NF);
    fX: StaticArray<f64> = new StaticArray<f64>(NF);
    fZ: StaticArray<f64> = new StaticArray<f64>(NF);
    fKX: StaticArray<f64> = new StaticArray<f64>(NF);   // knockback velocity
    fKZ: StaticArray<f64> = new StaticArray<f64>(NF);
    fHp: StaticArray<f64> = new StaticArray<f64>(NF);
    fMax: StaticArray<f64> = new StaticArray<f64>(NF);
    fT: StaticArray<f64> = new StaticArray<f64>(NF);
    fPh: StaticArray<f64> = new StaticArray<f64>(NF);
    fHit: StaticArray<f64> = new StaticArray<f64>(NF);
    fDie: StaticArray<f64> = new StaticArray<f64>(NF);
    fYaw: StaticArray<f64> = new StaticArray<f64>(NF);
    fMoteT: StaticArray<f64> = new StaticArray<f64>(NF);
    fEmbT: StaticArray<f64> = new StaticArray<f64>(NF);
    fPulse: StaticArray<i32> = new StaticArray<i32>(NF);
    fLunge: StaticArray<f64> = new StaticArray<f64>(NF); // hounds: > 0 lunging, < 0 recovering
    fIdle: StaticArray<bool> = new StaticArray<bool>(NF); // circling harmlessly (the hint screen)
    spawnT: f64 = 0;
    waveN: i32 = 0;
    surgeT: f64 = 0;
    eliteN: i32 = 0;
    bossOn: bool = false;
    bossSlamT: f64 = 0;
    bossSlam: f64 = -1;     // >= 0: the slam's wind-up
    bossBurn: f64 = 0;

    // weapons
    spCd: f64 = 0.15;
    spQ: i32 = 0;           // sparks still to throw in this volley
    spQT: f64 = 0;
    sOn: StaticArray<bool> = new StaticArray<bool>(NS);
    sX: StaticArray<f64> = new StaticArray<f64>(NS);
    sZ: StaticArray<f64> = new StaticArray<f64>(NS);
    sDX: StaticArray<f64> = new StaticArray<f64>(NS);
    sDZ: StaticArray<f64> = new StaticArray<f64>(NS);
    sT: StaticArray<f64> = new StaticArray<f64>(NS);
    sPierce: StaticArray<i32> = new StaticArray<i32>(NS);
    sLast: StaticArray<i32> = new StaticArray<i32>(NS);
    moteA: f64 = 0;
    puCd: f64 = 1.0;
    puT: f64 = -1;
    puId: i32 = 0;
    puX: f64 = 0;
    puZ: f64 = 0;
    emCd: f64 = 0;
    eOn: StaticArray<bool> = new StaticArray<bool>(NE);
    eX: StaticArray<f64> = new StaticArray<f64>(NE);
    eZ: StaticArray<f64> = new StaticArray<f64>(NE);
    eT: StaticArray<f64> = new StaticArray<f64>(NE);
    eNext: i32 = 0;
    boCd: f64 = 1.0;
    blX: StaticArray<f64> = new StaticArray<f64>(NBOLT);
    blZ: StaticArray<f64> = new StaticArray<f64>(NBOLT);
    blT: StaticArray<f64> = new StaticArray<f64>(NBOLT);
    blSeed: StaticArray<i32> = new StaticArray<i32>(NBOLT);
    blNext: i32 = 0;

    // pickups
    wOn: StaticArray<i32> = new StaticArray<i32>(NW);   // 0 free, 1 lying, 2 drawn to the hero
    wX: StaticArray<f64> = new StaticArray<f64>(NW);
    wZ: StaticArray<f64> = new StaticArray<f64>(NW);
    wV: StaticArray<i32> = new StaticArray<i32>(NW);
    wSp: StaticArray<f64> = new StaticArray<f64>(NW);
    wT: StaticArray<f64> = new StaticArray<f64>(NW);
    mergeT: f64 = 0;
    flOn: bool = false;
    flX: f64 = 0;
    flZ: f64 = 0;
    flT: f64 = 0;

    // HUD effects (no bones)
    pX: StaticArray<f64> = new StaticArray<f64>(NPOP);
    pY: StaticArray<f64> = new StaticArray<f64>(NPOP);
    pZ: StaticArray<f64> = new StaticArray<f64>(NPOP);
    pT: StaticArray<f64> = new StaticArray<f64>(NPOP);
    pK: StaticArray<i32> = new StaticArray<i32>(NPOP);  // 0 hit, 1 death, 2 big death, 3 slam
    pNext: i32 = 0;
    nX: StaticArray<f64> = new StaticArray<f64>(NNUM);
    nY: StaticArray<f64> = new StaticArray<f64>(NNUM);
    nZ: StaticArray<f64> = new StaticArray<f64>(NNUM);
    nT: StaticArray<f64> = new StaticArray<f64>(NNUM);
    nV: StaticArray<i32> = new StaticArray<i32>(NNUM);
    nNext: i32 = 0;
    banner: string = "";
    bannerT: f64 = -1;
    flashT: f64 = 0;

    // sound gates (never decided by api.rand)
    tickGate: f64 = 0;
    popGate: f64 = 0;
    coinGate: f64 = 0;
    streak: i32 = 0;
    streakT: f64 = 0;
    moteHits: i32 = 0;

    // the demo player
    dThink: f64 = 0;
    dDirX: f64 = 1;
    dDirZ: f64 = 0;
    dSpin: f64 = 1;
    dSlip: f64 = 0;
    dCardT: f64 = 0;
    dCard: i32 = 0;

    // ------------------------------------------------------------------ setup

    start(api: GameApi): void {
        api.playable = true;
        this.bHero = api.bone("hero");
        this.bGround = api.bone("ground");
        for (let i = 0; i < 4; i++) { this.bDecor[i] = api.bone("decor" + i.toString()); }
        let names: StaticArray<string> = ["moths", "shambler", "hound", "brute", "boss"];
        for (let k = 0; k < 5; k++) {
            for (let j = 0; j < K_COUNT[k]; j++) {
                let i = K_FIRST[k] + j;
                this.bFoe[i] = k == K_BOSS ? api.bone("boss") : api.bone(names[k] + j.toString());
                this.fKind[i] = k;
            }
        }
        for (let i = 0; i < NM; i++) { this.bMote[i] = api.bone("mote" + i.toString()); }
        this.bRing = api.bone("ring");
        for (let i = 0; i < NS; i++) { this.bSpark[i] = api.bone("spark" + i.toString()); }
        for (let i = 0; i < NE; i++) { this.bEmber[i] = api.bone("ember" + i.toString()); }
        for (let i = 0; i < NW; i++) { this.bWisp[i] = api.bone("wisp" + i.toString()); }
        this.bFlask = api.bone("flask");
        this.resetWorld(api);
        if (api.demo) {
            this.beginRun(api);
        }
    }

    resetWorld(api: GameApi): void {
        this.hx = 0; this.hz = 0; this.hvx = 0; this.hvz = 0; this.hYaw = 0;
        this.ox = 0; this.oz = 0;
        for (let i = 0; i < NF; i++) { this.fOn[i] = 0; this.fIdle[i] = false; }
        for (let i = 0; i < NS; i++) { this.sOn[i] = false; }
        for (let i = 0; i < NE; i++) { this.eOn[i] = false; }
        for (let i = 0; i < NW; i++) { this.wOn[i] = 0; }
        for (let i = 0; i < NPOP; i++) { this.pT[i] = -1; }
        for (let i = 0; i < NNUM; i++) { this.nT[i] = -1; }
        for (let i = 0; i < NBOLT; i++) { this.blT[i] = -1; }
        for (let i = 0; i < 11; i++) { this.lv[i] = 0; }
        this.lv[W_SPARK] = 1;
        this.owned = 1;
        this.flOn = false;
        this.puT = -1;
        this.hasGo = false;
        this.hp = 100; this.hpMax = 100; this.invT = 0; this.hurtT = 0;
        this.kills = 0; this.level = 1; this.xp = 0; this.pending = 0;
        this.runT = 0; this.waveN = 0; this.surgeT = 0; this.eliteN = 0;
        this.bossOn = false; this.bossSlam = -1; this.bossBurn = 0;
        this.won = false; this.newBest = false;
        this.bannerT = -1;
        // the hint screen: a few swarms circle the lantern's light at a distance
        for (let k = 0; k < 4; k++) {
            let i = k;
            let a = <f64>k / 4.0 * Math.PI * 2 + 0.4;
            this.spawnAt(api, i, Math.cos(a) * 4.0, Math.sin(a) * 3.2);
            this.fIdle[i] = true;
            this.fT[i] = 1.0;
        }
    }

    beginRun(api: GameApi): void {
        this.resetWorld(api);
        for (let i = 0; i < NF; i++) { this.fOn[i] = 0; this.fIdle[i] = false; }
        this.state = ST_PLAY;
        this.stateT = 0;
        this.started = true;
        this.spCd = 0.1;
        this.puCd = 1.0; this.boCd = 1.0; this.emCd = 0;
        this.spawnT = 0.8;
        // the night opens with a swarm already closing in from every side
        let n = 0;
        for (let k = 0; k < 7; k++) {
            let a = (<f64>k + api.range(-0.25, 0.25)) / 7.0 * Math.PI * 2;
            let d = api.range(3.6, 5.2);
            this.spawnAt(api, K_FIRST[K_MOTH] + n, this.hx + Math.cos(a) * d * 1.15, this.hz + Math.sin(a) * d * 0.9);
            n++;
        }
        for (let k = 0; k < 3; k++) {
            let a = (<f64>k + 0.5) / 3.0 * Math.PI * 2 + 0.3;
            this.spawnAt(api, K_FIRST[K_SHAM] + k, this.hx + Math.cos(a) * 5.2, this.hz + Math.sin(a) * 4.2);
        }
        this.say("THE NIGHT BEGINS");
        api.sound(SFX_WIN, 0.75, 0.5);
        api.note(57, 0.35, 0, SFX_BELL, 0.25);
    }

    endRun(api: GameApi, won: bool): void {
        this.state = won ? ST_DAWN : ST_OVER;
        this.stateT = 0;
        this.won = won;
        this.endT = this.runT;
        let better = false;
        if (won && !this.bestDawn) {
            better = true;
        } else if (won == this.bestDawn) {
            better = won ? this.kills > this.bestKills : this.runT > this.best;
        }
        if (better || this.best < 0) {
            this.newBest = this.best >= 0 || won;
            this.best = this.runT;
            this.bestKills = this.kills;
            this.bestDawn = won;
        }
        if (won) {
            api.sound(SFX_WIN, 1.0, 0.7);
            let mel: StaticArray<f64> = [72, 76, 79, 84, 88];
            for (let k = 0; k < 5; k++) { api.note(mel[k], 0.45, 0, SFX_BELL, 0.18 + <f64>k * 0.14); }
        } else {
            api.sound(SFX_LOSE, 0.9, 0.7);
            api.note(45, 0.5, 0, SFX_BELL, 0.5);
            api.note(40, 0.5, 0, SFX_BELL, 0.9);
        }
        if (this.newBest) {
            api.note(91, 0.35, 0, SFX_BELL, 1.3);
        }
    }

    say(s: string): void {
        this.banner = s;
        this.bannerT = 0;
    }

    // ------------------------------------------------------------------ helpers

    upLevel(id: i32): i32 {
        return max<i32>(1, this.lv[id]) - 1;
    }

    cdMul(): f64 {
        return 1.0 - 0.08 * <f64>this.lv[P_WICK];
    }

    areaMul(): f64 {
        return 1.0 + 0.08 * <f64>this.lv[P_WICK];
    }

    need(): i32 {
        let l = <f64>(this.level - 1);
        return <i32>Math.round(5.0 + 6.5 * l + 0.9 * l * l);
    }

    hpMul(): f64 {
        return 1.0 + this.runT / 110.0;
    }

    visible(x: f64, z: f64, m: f64): bool {
        let px = x - this.ox - this.camX, pz = z - this.oz - this.camZ;
        return Math.abs(px) < VIEW_X + m && pz > -VIEW_Z - m && pz < VIEW_Z + m;
    }

    addPop(x: f64, y: f64, z: f64, k: i32): void {
        let i = this.pNext;
        this.pNext = (this.pNext + 1) % NPOP;
        this.pX[i] = x; this.pY[i] = y; this.pZ[i] = z; this.pT[i] = 0; this.pK[i] = k;
    }

    addNum(x: f64, y: f64, z: f64, v: i32): void {
        let i = this.nNext;
        this.nNext = (this.nNext + 1) % NNUM;
        this.nX[i] = x; this.nY[i] = y; this.nZ[i] = z; this.nT[i] = 0; this.nV[i] = v;
    }

    weaponTick(api: GameApi, kind: i32, pitch: f64, vol: f64, x: f64, z: f64): void {
        // the busiest sound: at most one weapon tick every 90 ms across all weapons
        if (this.tickGate > 0) {
            return;
        }
        this.tickGate = 0.09;
        api.soundAt(kind, x - this.ox, 0.5, z - this.oz, pitch, vol);
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged) {
            if (api.demo) {
                this.beginRun(api);
            } else {
                // a visitor took over: a fresh night waits for the first click
                this.state = ST_IDLE;
                this.stateT = 0;
                this.resetWorld(api);
            }
        }
        this.stateT += dt;
        this.tickGate -= dt; this.popGate -= dt; this.coinGate -= dt;
        this.streakT -= dt;
        if (this.streakT <= 0) { this.streak = 0; }
        if (this.bannerT >= 0) {
            this.bannerT += dt;
            if (this.bannerT > 2.6) { this.bannerT = -1; }
        }
        if (this.flashT > 0) { this.flashT -= dt; }
        if (this.shakeT > 0) { this.shakeT -= dt; }

        if (api.demo) {
            this.demoThink(api, dt);
        }
        if (this.state == ST_CARDS) {
            this.updateCards(api, dt);
        } else {
            if (this.state == ST_PLAY) {
                this.runT += dt;
                this.updateClock(api, dt);
            }
            this.updateHero(api, dt);
            if (this.state == ST_PLAY) {
                this.updateWeapons(api, dt);
                this.updateSpawns(api, dt);
            }
            this.updateFoes(api, dt);
            this.updateWisps(api, dt);
            for (let i = 0; i < NPOP; i++) {
                if (this.pT[i] >= 0) { this.pT[i] += dt; if (this.pT[i] > 0.5) { this.pT[i] = -1; } }
            }
            for (let i = 0; i < NNUM; i++) {
                if (this.nT[i] >= 0) { this.nT[i] += dt; if (this.nT[i] > 0.6) { this.nT[i] = -1; } }
            }
            for (let i = 0; i < NBOLT; i++) {
                if (this.blT[i] >= 0) { this.blT[i] += dt; if (this.blT[i] > 0.2) { this.blT[i] = -1; } }
            }
            if (this.state == ST_PLAY && this.pending > 0 && this.hp > 0) {
                this.openCards(api);
            }
            if (api.demo && (this.state == ST_OVER || this.state == ST_DAWN) && this.stateT > 2.2) {
                this.beginRun(api);
            }
        }
        this.updateLight(api);
        this.placeAll(api);
    }

    updateClock(api: GameApi, dt: f64): void {
        let t = this.runT, t0 = t - dt;
        // a wave every 30 s: the mist thickens, a ring of swarms closes in
        if (t < NIGHT && Math.floor(t / 30) != Math.floor(t0 / 30) && t > 1) {
            this.waveN++;
            this.surgeT = 9.0;
            this.say("THE MIST THICKENS");
            api.note(64, 0.4, 0, SFX_BELL);
            api.note(52, 0.35, 0, SFX_BELL, 0.2);
            let n = min<i32>(4 + this.waveN, 9);
            for (let k = 0; k < n; k++) {
                let a = <f64>k / <f64>n * Math.PI * 2 + api.range(0, 0.5);
                let kind = k % 3 == 2 && this.waveN >= 2 ? K_HOUND : K_MOTH;
                let i = this.freeSlot(kind);
                if (i < 0) { i = this.freeSlot(K_MOTH); }
                if (i >= 0) {
                    this.spawnAt(api, i, this.hx + Math.cos(a) * 6.6, this.hz + Math.sin(a) * 5.6);
                }
            }
        }
        // elites
        let eliteAt: StaticArray<f64> = [55, 112, 150];
        for (let k = 0; k < 3; k++) {
            if (t >= eliteAt[k] && t0 < eliteAt[k]) {
                let i = this.freeSlot(K_BRUTE);
                if (i >= 0) {
                    this.spawnRing(api, i);
                    this.say("A CAIRN BRUTE WAKES");
                    api.note(57, 0.55, 0, SFX_BELL);
                    api.note(60, 0.5, 0, SFX_BELL, 0.16);
                    api.note(63, 0.55, 0, SFX_BELL, 0.32);
                    api.sound(SFX_THUD, 0.5, 0.9, 0, 0.05);
                    this.shakeT = 0.25;
                }
            }
        }
        // dawn: the Mire King rises
        if (t >= NIGHT && t0 < NIGHT) {
            let i = K_FIRST[K_BOSS];
            let a = Math.atan2(this.hvz, this.hvx);
            if (Math.abs(this.hvx) + Math.abs(this.hvz) < 0.1) { a = -Math.PI / 2; }
            this.spawnAt(api, i, this.hx + Math.cos(a) * 3.8, this.hz + Math.sin(a) * 3.2);
            this.bossOn = true;
            this.bossSlamT = 4.0;
            this.say("DAWN BREAKS - THE MIRE KING RISES");
            api.sound(SFX_EXPLODE, 0.45, 0.9);
            api.note(45, 0.6, 0, SFX_BELL, 0.1);
            api.note(48, 0.55, 0, SFX_BELL, 0.35);
            api.note(51, 0.55, 0, SFX_BELL, 0.6);
            api.note(44, 0.6, 0, SFX_BELL, 0.95);
            this.shakeT = 0.6;
        }
    }

    updateLight(api: GameApi): void {
        // the moon from the front left all night; the sun rises from the right at dawn
        let t = this.state == ST_IDLE ? 0.0 : this.runT;
        let dawn = smooth(NIGHT - 40, NIGHT + 30, t);
        if (this.state == ST_DAWN) {
            dawn = Math.max(dawn, smooth(0, 2.0, this.stateT));
        }
        api.sunPitch = 38 + 40 * dawn;
        api.sunYaw = -40 + 75 * dawn;
    }

    // ------------------------------------------------------------------ the hero

    updateHero(api: GameApi, dt: f64): void {
        if (this.invT > 0) { this.invT -= dt; }
        if (this.hurtT > 0) { this.hurtT -= dt; }
        if (this.state == ST_PLAY && this.hp > 0) {
            this.hp = Math.min(this.hpMax, this.hp + 0.5 * dt);   // the lantern's warmth
        }
        let moving = false;
        if (this.state == ST_PLAY) {
            let tx = 0.0, tz = 0.0, have = false;
            if (api.demo) {
                tx = this.hx + this.dDirX * 2.0;
                tz = this.hz + this.dDirZ * 2.0;
                have = true;
            } else if (this.hasGo) {
                // touch: the finger lifted (or a card was just picked): walk to that spot and stop
                tx = this.goX; tz = this.goZ;
                have = true;
            } else if (api.pointerX >= 0 && api.pick(api.pointerX, api.pointerY, 0)) {
                // the pointer stays where it is on screen while the camera follows: hold it off to one
                // side and he keeps walking that way
                tx = <f64>api.hitX + this.ox;
                tz = <f64>api.hitZ + this.oz;
                have = true;
            }
            let speed = 2.8 * (1.0 + 0.12 * <f64>this.lv[P_BOOTS]);
            let vx = 0.0, vz = 0.0;
            if (have) {
                let dx = tx - this.hx, dz = tz - this.hz;
                let d = Math.sqrt(dx * dx + dz * dz);
                if (d > 0.25) {
                    let s = speed * Math.min(1.0, (d - 0.15) / 0.5);
                    vx = dx / d * s;
                    vz = dz / d * s;
                }
            }
            let k = Math.min(1.0, dt * 14);
            this.hvx += (vx - this.hvx) * k;
            this.hvz += (vz - this.hvz) * k;
            this.hx += this.hvx * dt;
            this.hz += this.hvz * dt;
            let sp = Math.sqrt(this.hvx * this.hvx + this.hvz * this.hvz);
            if (sp > 0.3) {
                moving = true;
                this.hYaw = stepYaw(this.hvx, this.hvz, 16);
                this.hWalk += dt * sp * 2.6;
            }
        } else {
            this.hvx *= 0.8; this.hvz *= 0.8;
        }
        if (!moving) {
            this.hWalk = 0;
        }
        // the wrapping origin: the placed world stays near 0
        while (this.hx - this.ox > WRAP * 0.5) { this.ox += WRAP; }
        while (this.hx - this.ox < -WRAP * 0.5) { this.ox -= WRAP; }
        while (this.hz - this.oz > WRAP * 0.5) { this.oz += WRAP; }
        while (this.hz - this.oz < -WRAP * 0.5) { this.oz -= WRAP; }
        this.camX = Math.round((this.hx - this.ox) / TEXEL) * TEXEL;
        this.camZ = Math.round((this.hz - this.oz) / ZTEX) * ZTEX;
    }

    hurtHero(api: GameApi, dmg: f64, fx: f64, fz: f64): void {
        if (this.invT > 0 || this.state != ST_PLAY) {
            return;
        }
        let d = dmg * (1.0 - 0.12 * <f64>this.lv[P_COAT]);
        this.hp -= d;
        this.invT = 0.85;
        this.hurtT = 0.18;
        this.shakeT = 0.22;
        this.flashT = 0.16;
        this.streak = 0;
        api.soundAt(SFX_HIT, this.hx - this.ox, 0.6, this.hz - this.oz, 0.9, 0.75);
        api.sound(SFX_THUD, 0.7, 0.5);
        this.addNum(this.hx, 1.5, this.hz, -<i32>Math.round(d));
        if (this.hp <= 0) {
            this.hp = 0;
            this.endRun(api, false);
        }
    }

    // ------------------------------------------------------------------ foes

    freeSlot(kind: i32): i32 {
        for (let j = 0; j < K_COUNT[kind]; j++) {
            let i = K_FIRST[kind] + j;
            if (this.fOn[i] == 0) {
                return i;
            }
        }
        return -1;
    }

    activeCount(): i32 {
        let n = 0;
        for (let i = 0; i < K_FIRST[K_BRUTE]; i++) {
            if (this.fOn[i] == 1) { n++; }
        }
        return n;
    }

    spawnAt(api: GameApi, i: i32, x: f64, z: f64): void {
        let k = this.fKind[i];
        this.fOn[i] = 1;
        this.fX[i] = x; this.fZ[i] = z;
        this.fKX[i] = 0; this.fKZ[i] = 0;
        this.fMax[i] = K_HP[k] * (k == K_BOSS ? 1.0 : this.hpMul());
        this.fHp[i] = this.fMax[i];
        this.fT[i] = 0;
        this.fPh[i] = api.range(0, 6.28);
        this.fHit[i] = 0; this.fDie[i] = 0;
        this.fMoteT[i] = 0; this.fEmbT[i] = 0; this.fPulse[i] = -1;
        this.fLunge[i] = 0;
        this.fIdle[i] = false;
        this.fYaw[i] = stepYaw(this.hx - x, this.hz - z, 16);
    }

    // a spot just outside the view (farther below the frame: tall things there show their heads),
    // ahead of the hero when he walks
    spawnRing(api: GameApi, i: i32): void {
        let a = api.range(0, Math.PI * 2);
        let sp = Math.sqrt(this.hvx * this.hvx + this.hvz * this.hvz);
        if (sp > 0.5 && api.rand() < 0.55) {
            a = Math.atan2(this.hvz, this.hvx) + api.range(-1.0, 1.0);
        }
        let c = Math.cos(a), s = Math.sin(a);
        let rz = s > 0 ? 6.4 : 5.4;
        let k = this.fKind[i];
        let extra = k == K_BRUTE ? 0.8 : 0.0;
        this.spawnAt(api, i, this.hx + c * (6.6 + extra), this.hz + s * (rz + extra));
    }

    updateSpawns(api: GameApi, dt: f64): void {
        let t = this.runT;
        if (this.surgeT > 0) { this.surgeT -= dt; }
        let desired = <i32>Math.min(26.0, 9.0 + t / 7.0);
        let gap = Math.max(0.1, 0.45 - t / 400.0);
        if (this.surgeT > 0) {
            desired += 5;
            gap *= 0.5;
        }
        if (t >= NIGHT) {
            desired = 8;
            gap = 0.9;
        }
        this.spawnT -= dt;
        if (this.spawnT > 0 || this.activeCount() >= desired) {
            return;
        }
        this.spawnT = gap;
        // in bursts of up to three: freed slots refill at once, so the swarm stays thick
        let burst = min<i32>(3, desired - this.activeCount());
        for (let b = 1; b < burst; b++) {
            this.spawnOne(api, t);
        }
        this.spawnOne(api, t);
    }

    spawnOne(api: GameApi, t: f64): void {
        // what comes: swarms all night, shamblers soon, hounds after the first half minute
        let r = api.rand();
        let kind = K_MOTH;
        if (t >= NIGHT) {
            kind = r < 0.7 ? K_MOTH : K_HOUND;
        } else if (t < 25) {
            kind = r < 0.72 ? K_MOTH : K_SHAM;
        } else {
            let pm = 0.5 - 0.1 * smooth(25, 150, t);
            kind = r < pm ? K_MOTH : (r < pm + 0.25 ? K_SHAM : K_HOUND);
        }
        let i = this.freeSlot(kind);
        if (i < 0) { i = this.freeSlot(K_MOTH); }
        if (i < 0) { i = this.freeSlot(K_SHAM); }
        if (i < 0) { i = this.freeSlot(K_HOUND); }
        if (i >= 0) {
            this.spawnRing(api, i);
        }
    }

    hurtFoe(api: GameApi, i: i32, dmg: f64, dx: f64, dz: f64, kb: f64): void {
        if (this.fOn[i] != 1) {
            return;
        }
        let k = this.fKind[i];
        this.fHp[i] -= dmg;
        this.fHit[i] = 0.1;
        let n = Math.max(0.01, Math.sqrt(dx * dx + dz * dz));
        this.fKX[i] += dx / n * kb * K_KB[k];
        this.fKZ[i] += dz / n * kb * K_KB[k];
        let y = k == K_MOTH ? 0.75 : (k == K_BRUTE ? 1.2 : (k == K_BOSS ? 2.2 : 0.6));
        this.addPop(this.fX[i], y, this.fZ[i], 0);
        if (dmg >= 1) {
            this.addNum(this.fX[i], y + 0.3, this.fZ[i], <i32>Math.round(dmg));
        }
        if (this.fHp[i] <= 0) {
            this.killFoe(api, i);
        }
    }

    killFoe(api: GameApi, i: i32): void {
        let k = this.fKind[i];
        this.fOn[i] = 2;
        this.fDie[i] = 0;
        this.kills += K_KILLS[k];
        let y = k == K_MOTH ? 0.75 : (k == K_BRUTE ? 1.0 : (k == K_BOSS ? 1.8 : 0.5));
        this.addPop(this.fX[i], y, this.fZ[i], k >= K_BRUTE ? 2 : 1);
        if (this.popGate <= 0 || k >= K_BRUTE) {
            this.popGate = 0.05;
            api.soundAt(k >= K_BRUTE ? SFX_EXPLODE : SFX_POP, this.fX[i] - this.ox, y, this.fZ[i] - this.oz,
                        K_POP[k] * (1.0 + 0.04 * <f64>(this.kills % 5)), k >= K_BRUTE ? 0.7 : 0.4);
        }
        if (K_XP[k] > 0) {
            this.dropXP(api, this.fX[i], this.fZ[i], K_XP[k]);
        }
        if (k == K_BRUTE && !this.flOn) {
            this.flOn = true;
            this.flX = this.fX[i] + 0.6; this.flZ = this.fZ[i];
            this.flT = 0;
        }
        if (k == K_BOSS) {
            this.bossOn = false;
            this.shakeT = 0.8;
            // the sun is up: every creature of the night bursts
            for (let j = 0; j < NF; j++) {
                if (this.fOn[j] == 1) {
                    this.fOn[j] = 2;
                    this.fDie[j] = -0.08 * <f64>(j % 9);
                    this.addPop(this.fX[j], 0.6, this.fZ[j], 1);
                }
            }
            this.endRun(api, true);
        }
    }

    updateFoes(api: GameApi, dt: f64): void {
        let playing = this.state == ST_PLAY;
        let t = this.runT;
        let speedMul = 1.0 + t / 700.0;
        for (let i = 0; i < NF; i++) {
            let st = this.fOn[i];
            if (st == 0) {
                continue;
            }
            let k = this.fKind[i];
            this.fT[i] += dt;
            if (st == 2) {
                this.fDie[i] += dt;
                if (this.fDie[i] > 0.2) {
                    this.fOn[i] = 0;
                }
                continue;
            }
            if (this.fHit[i] > 0) { this.fHit[i] -= dt; }
            if (this.fMoteT[i] > 0) { this.fMoteT[i] -= dt; }
            if (this.fEmbT[i] > 0) { this.fEmbT[i] -= dt; }
            let dx = this.hx - this.fX[i], dz = this.hz - this.fZ[i];
            let d = Math.max(0.001, Math.sqrt(dx * dx + dz * dz));
            let ux = dx / d, uz = dz / d;
            let sp = K_SPEED[k] * speedMul;
            let vx = 0.0, vz = 0.0;
            if (this.fIdle[i] || !playing) {
                // circling the light at a distance, or wandering off after the night ends
                let r = 3.6 + 0.5 * Math.sin(this.fT[i] * 0.4 + this.fPh[i]);
                let want = (d - r) * 0.8;
                vx = ux * want - uz * 0.9;
                vz = uz * want + ux * 0.9;
                if (!this.fIdle[i] && this.state != ST_IDLE) {
                    vx = -ux * 1.2; vz = -uz * 1.2;
                }
            } else {
                vx = ux * sp; vz = uz * sp;
                if (k == K_MOTH) {
                    // weave across the line of approach
                    let w = Math.sin(this.fT[i] * 2.3 + this.fPh[i]) * 0.9;
                    vx += -uz * w; vz += ux * w;
                } else if (k == K_HOUND) {
                    if (this.fLunge[i] > 0) {
                        this.fLunge[i] -= dt;
                        vx *= 1.75; vz *= 1.75;
                        if (this.fLunge[i] <= 0) { this.fLunge[i] = -1.3; }
                    } else if (this.fLunge[i] < 0) {
                        this.fLunge[i] += dt;
                        let slow = this.fLunge[i] < -0.9 ? 0.35 : 1.0;
                        vx *= slow; vz *= slow;
                        if (this.fLunge[i] >= 0) { this.fLunge[i] = 0; }
                    } else if (d < 3.4) {
                        this.fLunge[i] = 0.5;
                    }
                } else if (k == K_BOSS) {
                    this.updateBoss(api, i, dt, d);
                    if (this.bossSlam >= 0) { vx = 0; vz = 0; }
                }
            }
            this.fX[i] += (vx + this.fKX[i]) * dt;
            this.fZ[i] += (vz + this.fKZ[i]) * dt;
            let damp = Math.exp(-7.0 * dt);
            this.fKX[i] *= damp; this.fKZ[i] *= damp;
            if (Math.abs(vx) + Math.abs(vz) > 0.05) {
                let yawT = stepYaw(vx, vz, 16);
                this.fYaw[i] = yawT;
            }
            // contact
            let reach = K_R[k] * 0.8 + 0.28;
            if (playing && !this.fIdle[i] && d < reach) {
                this.hurtHero(api, K_DMG[k], this.fX[i], this.fZ[i]);
                // pushed back off the hero so it does not stick
                this.fKX[i] -= ux * 2.5 * K_KB[k];
                this.fKZ[i] -= uz * 2.5 * K_KB[k];
            }
            if (d < reach * 0.85) {
                this.fX[i] = this.hx - ux * reach * 0.85;
                this.fZ[i] = this.hz - uz * reach * 0.85;
            }
            // far behind: back in front of the hero (the swarm never thins by being outrun)
            if (playing && d > 11.5 && k < K_BRUTE) {
                this.spawnRing(api, i);
            }
        }
        // separation: n is at most 29, so plain pairs (406 tests) beat any grid here
        for (let i = 0; i < NF; i++) {
            if (this.fOn[i] != 1) { continue; }
            let ri = K_R[this.fKind[i]];
            let mi = this.fKind[i] >= K_BRUTE ? 0.15 : 1.0;
            for (let j = i + 1; j < NF; j++) {
                if (this.fOn[j] != 1) { continue; }
                let rr = (ri + K_R[this.fKind[j]]) * 0.82;
                let dx = this.fX[j] - this.fX[i];
                if (dx > rr || dx < -rr) { continue; }
                let dz = this.fZ[j] - this.fZ[i];
                if (dz > rr || dz < -rr) { continue; }
                let d2 = dx * dx + dz * dz;
                if (d2 >= rr * rr || d2 < 1e-6) { continue; }
                let d = Math.sqrt(d2);
                let push = (rr - d) * 0.5;
                let mj = this.fKind[j] >= K_BRUTE ? 0.15 : 1.0;
                let wi = mi / (mi + mj), wj = mj / (mi + mj);
                this.fX[i] -= dx / d * push * wi * 2; this.fZ[i] -= dz / d * push * wi * 2;
                this.fX[j] += dx / d * push * wj * 2; this.fZ[j] += dz / d * push * wj * 2;
            }
        }
    }

    updateBoss(api: GameApi, i: i32, dt: f64, d: f64): void {
        // a ground slam every few seconds: it stops, rears up (0.8 s, a ring marks the reach), slams
        if (this.bossSlam >= 0) {
            this.bossSlam += dt;
            if (this.bossSlam >= 0.85) {
                this.bossSlam = -1;
                this.bossSlamT = 4.2;
                this.addPop(this.fX[i], 0.1, this.fZ[i], 3);
                this.shakeT = 0.35;
                api.soundAt(SFX_EXPLODE, this.fX[i] - this.ox, 0.2, this.fZ[i] - this.oz, 0.5, 0.9);
                if (d < 2.7) {
                    this.hurtHero(api, 18, this.fX[i], this.fZ[i]);
                }
            }
        } else {
            this.bossSlamT -= dt;
            if (this.bossSlamT <= 0 && d < 4.5) {
                this.bossSlam = 0;
                api.soundAt(SFX_WHOOSH, this.fX[i] - this.ox, 2, this.fZ[i] - this.oz, 0.45, 0.6);
            }
        }
        // the rising sun burns it after a while: the night must end
        this.bossBurn += dt;
        if (this.bossBurn > 45 && Math.floor(this.bossBurn) != Math.floor(this.bossBurn - dt)) {
            this.hurtFoe(api, i, this.fMax[i] * 0.03, 0, 0, 0);
        }
    }

    // ------------------------------------------------------------------ weapons

    nearestFoe(x: f64, z: f64, skip: i32, maxD: f64): i32 {
        let best = -1;
        let bd = maxD * maxD;
        for (let i = 0; i < NF; i++) {
            if (this.fOn[i] != 1 || i == skip) { continue; }
            let dx = this.fX[i] - x, dz = this.fZ[i] - z;
            let d2 = dx * dx + dz * dz;
            if (d2 < bd) { bd = d2; best = i; }
        }
        return best;
    }

    updateWeapons(api: GameApi, dt: f64): void {
        let area = this.areaMul();
        let cdm = this.cdMul();
        // --- flint sparks: a volley at the nearest foes
        let ls = this.upLevel(W_SPARK);
        if (this.lv[W_SPARK] > 0) {
            this.spCd -= dt;
            if (this.spCd <= 0 && this.nearestFoe(this.hx, this.hz, -1, 7.5) >= 0) {
                this.spCd = SP_CD[ls] * cdm;
                this.spQ = SP_N[ls];
                this.spQT = 0;
            }
            if (this.spQ > 0) {
                this.spQT -= dt;
                if (this.spQT <= 0) {
                    this.throwSpark(api, SP_N[ls] - this.spQ);
                    this.spQ--;
                    this.spQT = 0.07;
                }
            }
        }
        for (let s = 0; s < NS; s++) {
            if (!this.sOn[s]) { continue; }
            this.sT[s] += dt;
            this.sX[s] += this.sDX[s] * 10.0 * dt;
            this.sZ[s] += this.sDZ[s] * 10.0 * dt;
            if (this.sT[s] > 0.7) { this.sOn[s] = false; continue; }
            for (let i = 0; i < NF; i++) {
                if (this.fOn[i] != 1 || i == this.sLast[s]) { continue; }
                let rr = K_R[this.fKind[i]] + 0.15;
                let dx = this.fX[i] - this.sX[s], dz = this.fZ[i] - this.sZ[s];
                if (dx * dx + dz * dz < rr * rr) {
                    this.sLast[s] = i;
                    this.hurtFoe(api, i, SP_DMG[ls], this.sDX[s], this.sDZ[s], 1.6);
                    this.sPierce[s]--;
                    if (this.sPierce[s] < 0) { this.sOn[s] = false; break; }
                }
            }
        }
        // --- ward motes: orbiting lights
        if (this.lv[W_MOTE] > 0) {
            let lm = this.upLevel(W_MOTE);
            this.moteA += MO_SPIN[lm] * dt;
            let n = MO_N[lm];
            let r = MO_R[lm] * area;
            for (let m = 0; m < n; m++) {
                let a = this.moteA + <f64>m / <f64>n * Math.PI * 2;
                let mx = this.hx + Math.cos(a) * r, mz = this.hz + Math.sin(a) * r;
                for (let i = 0; i < NF; i++) {
                    if (this.fOn[i] != 1 || this.fMoteT[i] > 0) { continue; }
                    let rr = K_R[this.fKind[i]] + 0.25;
                    let dx = this.fX[i] - mx, dz = this.fZ[i] - mz;
                    if (dx * dx + dz * dz < rr * rr) {
                        this.fMoteT[i] = 0.45;
                        this.moteHits++;
                        this.hurtFoe(api, i, MO_DMG[lm], this.fX[i] - this.hx, this.fZ[i] - this.hz, 2.2);
                        this.weaponTick(api, SFX_TICK, 1.5 + 0.12 * <f64>(this.moteHits % 4), 0.4, mx, mz);
                    }
                }
            }
        }
        // --- lamp pulse: a ring of light that spreads and pushes
        if (this.lv[W_PULSE] > 0) {
            let lp = this.upLevel(W_PULSE);
            this.puCd -= dt;
            if (this.puCd <= 0) {
                this.puCd = PU_CD[lp] * cdm;
                this.puT = 0;
                this.puId++;
                this.puX = this.hx; this.puZ = this.hz;
                api.soundAt(SFX_WHOOSH, this.hx - this.ox, 0.3, this.hz - this.oz, 0.75, 0.32);
            }
            if (this.puT >= 0) {
                this.puT += dt;
                let R = PU_R[lp] * area * Math.min(1.0, this.puT / 0.35);
                this.puX = this.hx; this.puZ = this.hz;
                for (let i = 0; i < NF; i++) {
                    if (this.fOn[i] != 1 || this.fPulse[i] == this.puId) { continue; }
                    let dx = this.fX[i] - this.puX, dz = this.fZ[i] - this.puZ;
                    let rr = R + K_R[this.fKind[i]] * 0.6;
                    if (dx * dx + dz * dz < rr * rr) {
                        this.fPulse[i] = this.puId;
                        this.hurtFoe(api, i, PU_DMG[lp], dx, dz, 4.5);
                    }
                }
                if (this.puT > 0.45) { this.puT = -1; }
            }
        } else {
            this.puT = -1;
        }
        // --- cinder trail: cinders dropped behind as he walks
        if (this.lv[W_EMBER] > 0) {
            let le = this.upLevel(W_EMBER);
            let life = EM_LIFE[le];
            this.emCd -= dt;
            let moving = Math.abs(this.hvx) + Math.abs(this.hvz) > 0.4;
            if (this.emCd <= 0) {
                this.emCd = (life / <f64>NE) * (moving ? 1.0 : 1.8) * cdm;
                let e = this.eNext;
                this.eNext = (this.eNext + 1) % NE;
                this.eOn[e] = true; this.eT[e] = 0;
                this.eX[e] = this.hx - this.hvx * 0.08; this.eZ[e] = this.hz - this.hvz * 0.08;
            }
            let er = EM_R[le] * area;
            for (let e = 0; e < NE; e++) {
                if (!this.eOn[e]) { continue; }
                this.eT[e] += dt;
                if (this.eT[e] > life) { this.eOn[e] = false; continue; }
                for (let i = 0; i < NF; i++) {
                    if (this.fOn[i] != 1 || this.fEmbT[i] > 0) { continue; }
                    let rr = er + K_R[this.fKind[i]] * 0.7;
                    let dx = this.fX[i] - this.eX[e], dz = this.fZ[i] - this.eZ[e];
                    if (dx * dx + dz * dz < rr * rr) {
                        this.fEmbT[i] = 0.4;
                        this.hurtFoe(api, i, EM_DMG[le], dx, dz, 0.3);
                    }
                }
            }
        }
        // --- storm wick: lightning on foes in view
        if (this.lv[W_BOLT] > 0) {
            let lb = this.upLevel(W_BOLT);
            this.boCd -= dt;
            if (this.boCd <= 0) {
                this.boCd = BO_CD[lb] * cdm;
                let n = BO_N[lb];
                let hit = false;
                for (let b = 0; b < n; b++) {
                    // a random foe in view (a few tries), tougher ones more often
                    let pick = -1;
                    for (let tries = 0; tries < 8; tries++) {
                        let i = <i32>Math.floor(api.rand() * <f64>NF) % NF;
                        if (this.fOn[i] == 1 && this.visible(this.fX[i], this.fZ[i], -0.3)) {
                            pick = i;
                            if (this.fKind[i] != K_MOTH) { break; }
                        }
                    }
                    if (pick < 0) { continue; }
                    let x = this.fX[pick], z = this.fZ[pick];
                    let q = this.blNext;
                    this.blNext = (this.blNext + 1) % NBOLT;
                    this.blX[q] = x; this.blZ[q] = z; this.blT[q] = 0; this.blSeed[q] = this.puId * 7 + b * 13 + this.kills;
                    this.hurtFoe(api, pick, BO_DMG[lb], 0, 0, 0);
                    for (let i = 0; i < NF; i++) {      // the splash
                        if (this.fOn[i] != 1 || i == pick) { continue; }
                        let dx = this.fX[i] - x, dz = this.fZ[i] - z;
                        if (dx * dx + dz * dz < 1.0) { this.hurtFoe(api, i, BO_DMG[lb] * 0.4, dx, dz, 1.5); }
                    }
                    if (!hit) {
                        api.soundAt(SFX_ZAP, x - this.ox, 0.5, z - this.oz, 0.8, 0.45);
                        hit = true;
                    }
                }
            }
        }
    }

    throwSpark(api: GameApi, k: i32): void {
        let s = -1;
        for (let j = 0; j < NS; j++) {
            if (!this.sOn[j]) { s = j; break; }
        }
        if (s < 0) { return; }
        // the k-th spark of a volley goes for the k-th nearest foe
        let skip = -1;
        let target = this.nearestFoe(this.hx, this.hz, -1, 8.0);
        if (k > 0 && target >= 0) {
            skip = target;
            let t2 = this.nearestFoe(this.hx, this.hz, skip, 8.0);
            if (k > 1 && t2 >= 0) {
                // the third: the next one again, skipping the two nearest
                let best = -1;
                let bd = 64.0;
                for (let i = 0; i < NF; i++) {
                    if (this.fOn[i] != 1 || i == target || i == t2) { continue; }
                    let dx = this.fX[i] - this.hx, dz = this.fZ[i] - this.hz;
                    let d2 = dx * dx + dz * dz;
                    if (d2 < bd) { bd = d2; best = i; }
                }
                if (best >= 0) { t2 = best; }
            }
            if (t2 >= 0) { target = t2; }
        }
        let dx = 1.0, dz = 0.0;
        if (target >= 0) {
            // lead the target a little
            dx = this.fX[target] - this.hx; dz = this.fZ[target] - this.hz;
        }
        let n = Math.max(0.01, Math.sqrt(dx * dx + dz * dz));
        let ls = this.upLevel(W_SPARK);
        this.sOn[s] = true;
        this.sT[s] = 0;
        this.sX[s] = this.hx; this.sZ[s] = this.hz;
        this.sDX[s] = dx / n; this.sDZ[s] = dz / n;
        this.sPierce[s] = SP_PIERCE[ls];
        this.sLast[s] = -1;
        this.weaponTick(api, SFX_SHOOT, 1.9, 0.16, this.hx, this.hz);
    }

    // ------------------------------------------------------------------ wisps (XP) and the flask

    dropXP(api: GameApi, x: f64, z: f64, v: i32): void {
        for (let w = 0; w < NW; w++) {
            if (this.wOn[w] == 0) {
                this.wOn[w] = 1;
                this.wX[w] = x; this.wZ[w] = z; this.wV[w] = v; this.wSp[w] = 0; this.wT[w] = 0;
                return;
            }
        }
        // the pool is full: the drop joins the nearest lying wisp, which grows (no bone spent)
        let best = -1;
        let bd = 1e9;
        for (let w = 0; w < NW; w++) {
            if (this.wOn[w] != 1) { continue; }
            let dx = this.wX[w] - x, dz = this.wZ[w] - z;
            let d2 = dx * dx + dz * dz;
            if (d2 < bd) { bd = d2; best = w; }
        }
        if (best < 0) {
            best = 0;
        }
        this.wV[best] += v;
        this.wT[best] = 0;
    }

    updateWisps(api: GameApi, dt: f64): void {
        let reach = 1.1 * (1.0 + 0.45 * <f64>this.lv[P_HOOK]);
        let alive = this.state == ST_PLAY;
        // every half second, lying wisps close together merge (frees bones for new drops)
        this.mergeT -= dt;
        let doMerge = this.mergeT <= 0;
        if (doMerge) { this.mergeT = 0.5; }
        for (let w = 0; w < NW; w++) {
            if (this.wOn[w] == 0) { continue; }
            this.wT[w] += dt;
            let dx = this.hx - this.wX[w], dz = this.hz - this.wZ[w];
            let d = Math.sqrt(dx * dx + dz * dz);
            // stray wisps (left far behind, or lying a while) are called home by the lantern: the few
            // wisp bones never sit on XP the hero cannot reach
            if (this.wOn[w] == 1 && alive && (d < reach || d > 7.5 || this.wT[w] > 7.0)) {
                this.wOn[w] = 2;
                this.wSp[w] = 2.0;
            }
            if (this.wOn[w] == 2) {
                this.wSp[w] = Math.min(14.0, this.wSp[w] + 22.0 * dt);
                let s = Math.min(d, this.wSp[w] * dt);
                if (d > 0.001) {
                    this.wX[w] += dx / d * s;
                    this.wZ[w] += dz / d * s;
                }
                if (d < 0.35 && alive) {
                    this.collect(api, w);
                    continue;
                }
            }
            if (doMerge && this.wOn[w] == 1) {
                for (let u = w + 1; u < NW; u++) {
                    if (this.wOn[u] != 1) { continue; }
                    let ex = this.wX[u] - this.wX[w], ez = this.wZ[u] - this.wZ[w];
                    if (ex * ex + ez * ez < 1.1) {
                        this.wV[w] += this.wV[u];
                        this.wX[w] = (this.wX[w] + this.wX[u]) * 0.5;
                        this.wZ[w] = (this.wZ[w] + this.wZ[u]) * 0.5;
                        this.wOn[u] = 0;
                    }
                }
            }
        }
        if (this.flOn) {
            this.flT += dt;
            let dx = this.hx - this.flX, dz = this.hz - this.flZ;
            if (alive && dx * dx + dz * dz < 0.5) {
                this.flOn = false;
                this.hp = Math.min(this.hpMax, this.hp + 30);
                api.soundAt(SFX_POWERUP, this.flX - this.ox, 0.3, this.flZ - this.oz, 1.3, 0.45);
                this.addNum(this.hx, 1.6, this.hz, 30);
            }
        }
    }

    collect(api: GameApi, w: i32): void {
        this.wOn[w] = 0;
        this.xp += this.wV[w];
        // the pickup climbs in pitch while a streak lasts (a semitone a wisp, an octave at most)
        this.streak = min<i32>(this.streak + 1, 12);
        this.streakT = 0.7;
        if (this.coinGate <= 0) {
            this.coinGate = 0.045;
            api.sound(SFX_COIN, Math.pow(2.0, <f64>(this.streak - 1) / 12.0) * 0.9, 0.3);
        }
        while (this.xp >= this.need()) {
            this.xp -= this.need();
            this.level++;
            this.pending++;
        }
    }

    // ------------------------------------------------------------------ level-up cards

    openCards(api: GameApi): void {
        
        this.pending--;
        this.state = ST_CARDS;
        this.stateT = 0;
        this.cardT = 0;
        this.pickT = -1;
        this.picked = -1;
        this.hover = -1;
        // three different offers, weighted: weapons you hold, new weapons, then passives
        let ids = new StaticArray<i32>(11);
        let wts = new StaticArray<f64>(11);
        let n = 0;
        for (let id = 0; id < NUP; id++) {
            if (this.lv[id] >= MAXLV[id]) { continue; }
            let w = 1.6;
            if (id <= W_BOLT) { w = this.lv[id] > 0 ? 3.0 : 2.4; }
            ids[n] = id; wts[n] = w; n++;
        }
        for (let c = 0; c < 3; c++) {
            let tot = 0.0;
            for (let j = 0; j < n; j++) { tot += wts[j]; }
            if (tot <= 0) {
                this.cardId[c] = C_TEA;
                continue;
            }
            let r = api.rand() * tot;
            let pick = n - 1;
            for (let j = 0; j < n; j++) {
                r -= wts[j];
                if (r <= 0 && wts[j] > 0) { pick = j; break; }
            }
            this.cardId[c] = ids[pick];
            wts[pick] = 0;
        }
        api.note(72, 0.45, 0, SFX_NOTE);
        api.note(76, 0.45, 0, SFX_NOTE, 0.08);
        api.note(79, 0.45, 0, SFX_NOTE, 0.16);
        api.note(84, 0.5, 0, SFX_NOTE, 0.24);
        for (let c = 0; c < 3; c++) { api.sound(SFX_BLIP, 1.2 + 0.15 * <f64>c, 0.3, -0.6 + 0.6 * <f64>c, 0.32 + 0.09 * <f64>c); }
        // the demo reads the cards, then chooses
        this.dCardT = api.range(0.75, 1.3);
        this.dCard = this.demoChoice(api);
    }

    updateCards(api: GameApi, dt: f64): void {
        this.cardT += dt;
        if (this.pickT >= 0) {
            this.pickT += dt;
            if (this.pickT > 0.3) {
                this.state = ST_PLAY;
                this.stateT = 0;
                this.invT = Math.max(this.invT, 0.4);
                if (this.pending > 0) {
                    this.openCards(api);
                }
            }
        }
    }

    choose(api: GameApi, c: i32): void {
        if (this.pickT >= 0 || this.cardT < 0.35) {
            return;
        }
        let id = this.cardId[c];
        this.picked = c;
        this.pickT = 0;
        if (id == C_TEA) {
            this.hp = Math.min(this.hpMax, this.hp + 35);
        } else {
            if (id <= W_BOLT && this.lv[id] == 0) { this.owned++; }
            this.lv[id]++;
            if (id == P_FLASK) {
                this.hpMax += 25;
                this.hp = Math.min(this.hpMax, this.hp + 25);
            }
            if (id == W_PULSE && this.lv[id] == 1) { this.puCd = 0.3; }
            if (id == W_BOLT && this.lv[id] == 1) { this.boCd = 0.4; }
        }
        // he stands still until the pointer moves again (a tapped card must not send him off toward it)
        this.hasGo = true;
        this.goX = this.hx; this.goZ = this.hz;
        api.sound(SFX_POWERUP, 1.0, 0.5);
        api.sound(SFX_CLICK, 1.2, 0.4);
    }

    cardX(c: i32, w: f64): f64 {
        return Math.floor(<f64>this.hudWc * 0.5 - 1.5 * w - 6) + <f64>c * (w + 6);
    }
    hudWc: i32 = 213;
    hudHc: i32 = 133;

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        // Touch: the pointer moves only while a finger is down. A drag steers like the mouse (he walks
        // toward the finger); when it lifts, the spot under it becomes his goal and he stops there.
        if (kind == POINTER_UP) {
            if (this.state == ST_PLAY && api.pick(x, y, 0)) {
                this.goX = <f64>api.hitX + this.ox;
                this.goZ = <f64>api.hitZ + this.oz;
                this.hasGo = true;
            }
            return true;
        }
        if (this.state == ST_PLAY) {
            this.hasGo = false;
        }
        if (kind != POINTER_DOWN) {
            if (this.state == ST_CARDS && kind == POINTER_MOVE) {
                this.hover = this.cardAt(<f64>x, <f64>y);
            }
            return true;
        }
        if (this.state == ST_IDLE) {
            this.beginRun(api);
        } else if ((this.state == ST_OVER || this.state == ST_DAWN) && this.stateT > 0.8) {
            this.beginRun(api);
        } else if (this.state == ST_CARDS) {
            let c = this.cardAt(<f64>x, <f64>y);
            if (c >= 0) {
                this.choose(api, c);
            }
        }
        return true;
    }

    cardAt(x: f64, y: f64): i32 {
        let w = 64.0, h = 64.0, top = 36.0;
        for (let c = 0; c < 3; c++) {
            let cx = this.cardX(c, w);
            if (x >= cx && x < cx + w && y >= top && y < top + h) {
                return c;
            }
        }
        return -1;
    }

    // ------------------------------------------------------------------ the demo player

    demoChoice(api: GameApi): i32 {
        let best = 0;
        let bs = -1e9;
        let low = this.hp < this.hpMax * 0.45;
        for (let c = 0; c < 3; c++) {
            let id = this.cardId[c];
            let s = api.range(0, 1.2);
            if (id <= W_BOLT) {
                s += this.lv[id] > 0 ? 3.0 : (this.owned < 4 ? 2.6 : 0.8);
                if (id == W_MOTE || id == W_PULSE) { s += 0.4; }   // it likes things that guard it
            } else if (id == P_COAT || id == P_FLASK) {
                s += low ? 3.6 : 1.2;
            } else if (id == C_TEA) {
                s += low ? 3.0 : 0.2;
            } else {
                s += 1.4;
            }
            if (s > bs) { bs = s; best = c; }
        }
        return best;
    }

    gapX: f64 = 1;
    gapZ: f64 = 0;
    // the demo's heading: 16 headings, each scored by the danger at two points along it, keeping to
    // its circle (the last heading, bent a little one way) and drawn to wisps (gx, gz)
    gapSearch(gx: f64, gz: f64): void {
        let bs = -1e9;
        let turnX = this.dDirX - this.dDirZ * 0.35 * this.dSpin, turnZ = this.dDirZ + this.dDirX * 0.35 * this.dSpin;
        for (let h = 0; h < 16; h++) {
            let a = <f64>h / 16.0 * Math.PI * 2;
            let cx = Math.cos(a), cz = Math.sin(a);
            let danger = 0.0;
            for (let i = 0; i < NF; i++) {
                if (this.fOn[i] != 1) { continue; }
                let k = this.fKind[i];
                let w = k == K_BOSS ? 5.0 : (k == K_BRUTE ? 2.5 : (k == K_HOUND ? 1.4 : 1.0));
                for (let q = 1; q <= 2; q++) {
                    let px = this.hx + cx * 0.85 * <f64>q, pz = this.hz + cz * 0.85 * <f64>q;
                    let dx = this.fX[i] - px, dz = this.fZ[i] - pz;
                    let rr = K_R[k] + 0.3;
                    let d2 = dx * dx + dz * dz;
                    if (d2 < 9.0) { danger += w / (Math.max(0.0, d2 - rr * rr) + 0.25) * (q == 1 ? 1.4 : 1.0); }
                }
            }
            let sc = -danger + 0.8 * (cx * turnX + cz * turnZ) + 0.6 * (cx * gx + cz * gz);
            if (sc > bs) { bs = sc; this.gapX = cx; this.gapZ = cz; }
        }
    }

    demoThink(api: GameApi, dt: f64): void {
        if (this.state == ST_CARDS) {
            this.dCardT -= dt;
            this.hover = this.dCard;
            if (this.dCardT <= 0) {
                this.choose(api, this.dCard);
            }
            return;
        }
        if (this.state != ST_PLAY) {
            return;
        }
        this.dThink -= dt;
        if (this.dSlip > 0) { this.dSlip -= dt; }
        if (this.dThink > 0) {
            return;
        }
        this.dThink = api.range(0.1, 0.22);
        // a moment of carelessness now and then (more often as the night wears on): it walks
        // straight for the wisps and ignores the swarm
        if (this.dSlip <= 0 && api.rand() < 0.012 + 0.03 * smooth(40, 170, this.runT)) {
            this.dSlip = api.range(0.5, 1.1);
        }
        // the nearest wisp (or the flask when hurt)
        let gx = 0.0, gz = 0.0;
        let bd = 49.0;
        for (let w = 0; w < NW; w++) {
            if (this.wOn[w] != 1) { continue; }
            let dx = this.wX[w] - this.hx, dz = this.wZ[w] - this.hz;
            let d2 = dx * dx + dz * dz;
            if (d2 < bd) { bd = d2; let d = Math.sqrt(d2) + 0.001; gx = dx / d; gz = dz / d; }
        }
        if (this.flOn && this.hp < this.hpMax * 0.7) {
            let dx = this.flX - this.hx, dz = this.flZ - this.hz;
            let d = Math.sqrt(dx * dx + dz * dz) + 0.001;
            if (d < 9) { gx = dx / d; gz = dz / d; }
        }
        if (api.rand() < 0.03) { this.dSpin = -this.dSpin; }
        let dirx = 0.0, dirz = 0.0;
        if (this.dSlip > 0) {
            dirx = gx; dirz = gz;
        } else {
            this.gapSearch(gx, gz);
            dirx = this.gapX; dirz = this.gapZ;
        }
        // a little aim error
        let e = api.range(-0.25, 0.25);
        let c = Math.cos(e), s = Math.sin(e);
        let rx = dirx * c - dirz * s, rz = dirx * s + dirz * c;
        let n = Math.sqrt(rx * rx + rz * rz);
        if (n > 0.05) {
            this.dDirX = rx / n; this.dDirZ = rz / n;
        }
    }

    // ------------------------------------------------------------------ placing the bones

    placeAll(api: GameApi): void {
        let ox = this.ox, oz = this.oz;
        let t = api.time;
        let f8 = Math.floor(t * 8);
        let f10 = Math.floor(t * 10);
        // the camera: locked on the hero, whole texels; a hit shakes it a texel
        let cx = this.camX, cz = this.camZ;
        if (this.shakeT > 0) {
            let k = <i32>f10 % 4;
            cx += (k == 0 ? 1.0 : (k == 2 ? -1.0 : 0.0)) * TEXEL;
            cz += (k == 1 ? 1.0 : (k == 3 ? -1.0 : 0.0)) * ZTEX;
        }
        api.targetX = cx;
        api.targetY = 0;
        api.targetZ = cz;
        api.place(this.bGround, this.camX, 0, this.camZ);
        // decor: the nearest cell of each parity (cells centred on half-cells, so a night starts
        // where four patches meet, clear of their landmarks)
        for (let p = 0; p < 4; p++) {
            let px = <f64>(p % 2), pz = <f64>(p / 2);
            let nx = px + 2 * Math.round((this.hx / CELL - 0.5 - px) * 0.5);
            let nz = pz + 2 * Math.round((this.hz / CELL - 0.5 - pz) * 0.5);
            api.place(this.bDecor[p], (nx + 0.5) * CELL - ox, 0, (nz + 0.5) * CELL - oz, 0);
        }
        // the hero, pinned to the snapped camera (the moor scrolls under him by whole pixels)
        let hb = this.bHero;
        if (this.state == ST_OVER) {
            let k = Math.min(1.0, this.stateT / 0.45);
            api.place(hb, this.camX, 0, this.camZ, this.hYaw, -82 * k * k, 0, 1.0);
        } else if (this.invT > 0 && this.state == ST_PLAY && (<i32>Math.floor(this.invT * 12.5)) % 2 == 1) {
            api.hide(hb);
        } else {
            let walk = this.hWalk > 0;
            let ph = Math.floor(this.hWalk * 8 / 6.28) % 2;    // stepped waddle
            let bob = walk ? (ph == 0 ? 0.035 : 0.0) : 0.0;
            let roll = walk ? (ph == 0 ? 4.0 : -4.0) : 0.0;
            let sx = 1.0, sy = 1.0;
            if (this.hurtT > 0) { sx = 1.12; sy = 0.86; }
            if (this.state == ST_IDLE || this.state == ST_CARDS || this.state == ST_DAWN) {
                sy = (<i32>Math.floor(t * 2) % 2 == 0) ? 1.0 : 0.98;   // breathing
            }
            if (sx != 1.0 || sy != 1.0) {
                api.placeScaled(hb, this.camX, bob, this.camZ, this.hYaw, sx, sy, sx, 0, roll);
            } else {
                api.place(hb, this.camX, bob, this.camZ, this.hYaw, 0, roll, 1.0);
            }
        }
        // foes
        for (let i = 0; i < NF; i++) {
            let b = this.bFoe[i];
            let st = this.fOn[i];
            if (st == 0 || (st == 2 && this.fDie[i] < 0 && false)) {
                api.hide(b);
                continue;
            }
            let k = this.fKind[i];
            let x = this.fX[i] - ox, z = this.fZ[i] - oz;
            if (Math.abs(x - this.camX) > 9.0 || Math.abs(z - this.camZ) > 8.0) {
                api.hide(b);
                continue;
            }
            let s = 1.0;
            let y = 0.0;
            if (st == 2) {
                let q = clampf(this.fDie[i] / 0.2, 0, 1);
                if (q >= 1) { api.hide(b); continue; }
                s = 1.0 - 0.85 * q;
                y = k == K_MOTH ? 0.3 * q : -0.1 * q;
            }
            let rise = clampf(this.fT[i] / 0.35, 0, 1);
            let ph = this.fPh[i];
            let yaw = this.fYaw[i];
            let sx = s, sy = s;
            if (this.fHit[i] > 0) { sx *= 1.12; sy *= 0.85; }
            if (k == K_MOTH) {
                let flap = (<i32>(f10 + Math.floor(ph * 3))) % 2 == 0 ? 1.0 : 0.78;
                let bob = 0.07 * Math.sin(t * 3.1 + ph);
                let wob = 14.0 * Math.sin(t * 1.7 + ph) + 360.0 * ((t * 0.08 + ph) % 1.0);
                api.placeScaled(b, x, y + bob - 0.5 * (1 - rise), z, Math.round((yaw + wob) / 10) * 10, sx * flap, sy, sx, 0, 0);
            } else if (k == K_SHAM) {
                let st6 = (<i32>(Math.floor(t * 6 + ph))) % 2;
                let roll = st6 == 0 ? 5.0 : -5.0;
                api.placeScaled(b, x, y + (st6 == 0 ? 0.03 : 0.0) - 0.9 * (1 - rise), z, yaw, sx, sy, sx, 3, roll);
            } else if (k == K_HOUND) {
                let fast = this.fLunge[i] > 0;
                let st10 = (<i32>(f10 + Math.floor(ph * 3))) % 2;
                let pitch = st10 == 0 ? -6.0 : 5.0;
                if (fast) { pitch *= 1.6; }
                api.placeScaled(b, x, y + (st10 == 0 ? 0.05 : 0.0) - 0.8 * (1 - rise), z, yaw, sx, sy, sx, pitch, 0);
            } else if (k == K_BRUTE) {
                let st4 = (<i32>(Math.floor(t * 4 + ph))) % 2;
                if (this.state == ST_PLAY && st4 != (<i32>(Math.floor((t - api.dt) * 4 + ph))) % 2 && this.visible(this.fX[i], this.fZ[i], 0)) {
                    api.soundAt(SFX_THUD, x, 0, z, 0.45, 0.22);
                }
                api.placeScaled(b, x, y + (st4 == 0 ? 0.04 : 0.0) - 1.6 * (1 - rise), z, yaw, sx, sy, sx, 0, st4 == 0 ? 4.0 : -4.0);
            } else {
                // the boss: sways; rears up before a slam
                let sw = (<i32>(Math.floor(t * 3))) % 2 == 0 ? 3.0 : -3.0;
                let rear = this.bossSlam >= 0 ? Math.sin(Math.min(1.0, this.bossSlam / 0.8) * Math.PI * 0.5) : 0.0;
                if (this.bossSlam >= 0.75) { rear = -0.3; }
                api.placeScaled(b, x, y - 2.5 * (1 - clampf(this.fT[i] / 1.2, 0, 1)), z, yaw,
                                sx * (1 - 0.06 * rear), sy * (1 + 0.12 * rear), sx * (1 - 0.06 * rear), -12 * rear, sw);
            }
        }
        // motes
        let lm = this.upLevel(W_MOTE);
        let nmo = this.lv[W_MOTE] > 0 && (this.state == ST_PLAY || this.state == ST_CARDS) ? MO_N[lm] : 0;
        for (let m = 0; m < NM; m++) {
            if (m >= nmo) { api.hide(this.bMote[m]); continue; }
            let a = this.moteA + <f64>m / <f64>nmo * Math.PI * 2;
            let r = MO_R[lm] * this.areaMul();
            api.place(this.bMote[m], this.hx - ox + Math.cos(a) * r, 0.55 + 0.06 * Math.sin(t * 5 + <f64>m), this.hz - oz + Math.sin(a) * r,
                      Math.floor(t * 8) * 45, 0, 0, 1.0);
        }
        // the pulse ring
        if (this.puT >= 0) {
            let lp = this.upLevel(W_PULSE);
            let R = PU_R[lp] * this.areaMul() * Math.min(1.0, this.puT / 0.35);
            let sc = Math.max(0.05, R / 3.0);
            api.placeScaled(this.bRing, this.puX - ox, 0.12, this.puZ - oz, Math.floor(t * 10) * 5, sc, 1.0, sc, 0, 0);
        } else {
            api.hide(this.bRing);
        }
        // sparks
        for (let s = 0; s < NS; s++) {
            if (!this.sOn[s]) { api.hide(this.bSpark[s]); continue; }
            let yaw = Math.atan2(-this.sDX[s], -this.sDZ[s]) * 180 / Math.PI;
            api.place(this.bSpark[s], this.sX[s] - ox, 0.55, this.sZ[s] - oz, yaw, 0, 0, 1.0);
        }
        // cinders
        let le = this.upLevel(W_EMBER);
        for (let e = 0; e < NE; e++) {
            if (!this.eOn[e] || this.lv[W_EMBER] == 0) { api.hide(this.bEmber[e]); continue; }
            let life = EM_LIFE[le];
            let q = this.eT[e];
            let grow = Math.min(1.0, q / 0.12) * Math.min(1.0, (life - q) / 0.4);
            let fl = (<i32>(f10 + e * 3)) % 3;
            let sy = (fl == 0 ? 1.15 : (fl == 1 ? 0.85 : 1.0)) * Math.max(0.1, grow);
            let sc = Math.max(0.1, grow) * EM_R[le] / 0.55 * this.areaMul();
            api.placeScaled(this.bEmber[e], this.eX[e] - ox, 0, this.eZ[e] - oz, <f64>e * 47, sc, sy * sc, sc, 0, 0);
        }
        // wisps
        for (let w = 0; w < NW; w++) {
            if (this.wOn[w] == 0) { api.hide(this.bWisp[w]); continue; }
            let v = this.wV[w];
            let sc = v < 5 ? 0.55 : (v < 15 ? 0.75 : 1.0);
            let pop = Math.min(1.0, this.wT[w] / 0.15);
            api.place(this.bWisp[w], this.wX[w] - ox, 0.38 + 0.06 * Math.sin(t * 4 + <f64>w), this.wZ[w] - oz,
                      Math.floor(t * 6) * 30 + <f64>w * 20, 0, 0, sc * (0.5 + 0.5 * pop));
        }
        if (this.flOn) {
            api.place(this.bFlask, this.flX - ox, 0.15 + 0.06 * Math.sin(this.flT * 4), this.flZ - oz, this.flT * 60, 0, 0, 1.0);
        } else {
            api.hide(this.bFlask);
        }
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let W = <f64>api.hudW, H = <f64>api.hudH;
        this.hudWc = api.hudW;
        this.hudHc = api.hudH;
        let ox = this.ox, oz = this.oz;
        let dark = api.rampColor(R_STONE, 0);
        let pale = api.rampColor(R_STONE, 5);
        let white = api.rampColor(R_SLATE, 5);
        let gold = api.rampColor(R_GLOW, 2);
        let amber = api.rampColor(R_GLOW, 1);
        let red = api.rampColor(R_BLOOD, 4);
        let pink = api.rampColor(R_EYE, 1);
        let teal = api.rampColor(R_WISP, 1);
        let ink = api.rampColor(R_COAT, 0);

        // the storm wick's lightning
        for (let q = 0; q < NBOLT; q++) {
            if (this.blT[q] < 0) { continue; }
            if (!api.project(<f32>(this.blX[q] - ox), 0.5, <f32>(this.blZ[q] - oz))) { continue; }
            let x1 = <f64>api.screenX, y1 = <f64>api.screenY;
            let px = x1 + (hash(this.blSeed[q]) - 0.5) * 30, py = -2.0;
            let segs = 6;
            for (let k = 1; k <= segs; k++) {
                let f = <f64>k / <f64>segs;
                let nx = x1 + (px - x1) * 0 + (hash(this.blSeed[q] * 31 + k) - 0.5) * 12 * (1 - f) + (px - x1) * (1 - f);
                let ny = -2.0 + (y1 + 2.0) * f;
                if (k == segs) { nx = x1; ny = y1; }
                let c = this.blT[q] < 0.08 ? white : gold;
                api.line(<f32>px, <f32>py, <f32>nx, <f32>ny, c);
                api.line(<f32>px + 1, <f32>py, <f32>nx + 1, <f32>ny, this.blT[q] < 0.08 ? gold : amber);
                px = nx; py = ny;
            }
            let r = 2.0 + this.blT[q] * 30;
            this.burst(api, x1, y1, r, 8, white);
        }
        // pops: hits, deaths, the boss's slam
        for (let i = 0; i < NPOP; i++) {
            let q = this.pT[i];
            if (q < 0) { continue; }
            if (!api.project(<f32>(this.pX[i] - ox), <f32>this.pY[i], <f32>(this.pZ[i] - oz))) { continue; }
            let x = Math.round(<f64>api.screenX), y = Math.round(<f64>api.screenY);
            let k = this.pK[i];
            if (k == 0) {
                if (q < 0.1) {
                    let c = q < 0.05 ? white : gold;
                    api.rect(<f32>x, <f32>(y - 1), 1, 3, c);
                    api.rect(<f32>(x - 1), <f32>y, 3, 1, c);
                }
            } else if (k == 1 || k == 2) {
                let dur = k == 1 ? 0.3 : 0.45;
                if (q < dur) {
                    let r = 2.0 + q / dur * (k == 1 ? 9.0 : 18.0);
                    this.burst(api, x, y, r, k == 1 ? 8 : 12, q < dur * 0.4 ? white : (k == 1 ? pink : teal));
                    if (q < 0.06) { api.rect(<f32>(x - 1), <f32>(y - 1), 3, 3, white); }
                }
            } else if (k == 3 && q < 0.4) {
                // the slam: a wide ring on the ground
                for (let a = 0; a < 24; a++) {
                    let an = <f64>a / 24.0 * Math.PI * 2;
                    let rr = 2.7 * Math.min(1.0, q / 0.2);
                    if (api.project(<f32>(this.pX[i] - ox + Math.cos(an) * rr), 0, <f32>(this.pZ[i] - oz + Math.sin(an) * rr))) {
                        api.rect(<f32>Math.round(<f64>api.screenX), <f32>Math.round(<f64>api.screenY), 2, 1, q < 0.15 ? white : amber);
                    }
                }
            }
        }
        // the boss's wind-up: its reach marked on the ground
        if (this.bossOn && this.bossSlam >= 0 && (<i32>Math.floor(this.bossSlam * 10)) % 2 == 0) {
            let bi = K_FIRST[K_BOSS];
            for (let a = 0; a < 20; a++) {
                let an = <f64>a / 20.0 * Math.PI * 2;
                if (api.project(<f32>(this.fX[bi] - ox + Math.cos(an) * 2.7), 0, <f32>(this.fZ[bi] - oz + Math.sin(an) * 2.7))) {
                    api.rect(<f32>Math.round(<f64>api.screenX), <f32>Math.round(<f64>api.screenY), 1, 1, red);
                }
            }
        }
        // damage numbers
        for (let i = 0; i < NNUM; i++) {
            let q = this.nT[i];
            if (q < 0) { continue; }
            if (!api.project(<f32>(this.nX[i] - ox), <f32>this.nY[i], <f32>(this.nZ[i] - oz))) { continue; }
            let v = this.nV[i];
            let s = v < 0 ? (-v).toString() : v.toString();
            let x = Math.round(<f64>api.screenX - <f64>api.textWidth(s, 1) * 0.5);
            let y = Math.round(<f64>api.screenY - 2 - q * 12);
            api.text(<f32>x, <f32>y, s, v < 0 ? red : (v >= 25 ? gold : pale), 1, dark);
        }
        // elites and the boss off screen: an arrow on the edge
        for (let i = K_FIRST[K_BRUTE]; i < NF; i++) {
            if (this.fOn[i] != 1 || this.visible(this.fX[i], this.fZ[i], -0.2)) { continue; }
            if ((<i32>Math.floor(api.time * 4)) % 2 == 0) { continue; }
            let dx = this.fX[i] - this.hx, dz = (this.fZ[i] - this.hz) * 0.8;
            let n = Math.max(0.01, Math.sqrt(dx * dx + dz * dz));
            let ux = dx / n, uz = dz / n;
            let cx = W * 0.5, cy = H * 0.5 + 6;
            let tx = Math.abs(ux) > 1e-3 ? (W * 0.5 - 6) / Math.abs(ux) : 1e9;
            let ty = Math.abs(uz) > 1e-3 ? (H * 0.5 - 12) / Math.abs(uz) : 1e9;
            let tt = Math.min(tx, ty);
            let ax = Math.round(cx + ux * tt), ay = Math.round(cy + uz * tt);
            api.rect(<f32>(ax - 1), <f32>(ay - 1), 3, 3, i == K_FIRST[K_BOSS] ? red : pink);
            api.rect(<f32>(ax + Math.round(ux * 2)), <f32>(ay + Math.round(uz * 2)), 1, 1, white);
        }
        // the hero's health under his feet
        if (this.state == ST_PLAY || this.state == ST_CARDS) {
            if (api.project(<f32>this.camX, 0, <f32>this.camZ)) {
                let x = Math.round(<f64>api.screenX) - 7, y = Math.round(<f64>api.screenY) + 4;
                api.rect(<f32>x - 1, <f32>y - 1, 16, 4, ink);
                let f = Math.round(14 * clampf(this.hp / this.hpMax, 0, 1));
                api.rect(<f32>x, <f32>y, <f32>f, 2, this.hp < this.hpMax * 0.3 && (<i32>Math.floor(api.time * 6)) % 2 == 0 ? gold : red);
            }
        }
        // the hurt flash: the frame's edge
        if (this.flashT > 0) {
            api.rect(0, 0, <f32>W, 2, red); api.rect(0, <f32>(H - 2), <f32>W, 2, red);
            api.rect(0, 0, 2, <f32>H, red); api.rect(<f32>(W - 2), 0, 2, <f32>H, red);
        }

        if (this.state == ST_IDLE) {
            this.hudIdle(api, W, H);
            return;
        }
        // top: XP bar, level, the night's clock, kills
        let need = <f64>this.need();
        api.rect(0, 0, <f32>W, 3, ink);
        api.rect(0, 0, <f32>(Math.round(W * clampf(<f64>this.xp / need, 0, 1))), 2, teal);
        api.text(3, 5, "LV " + this.level.toString(), teal, 1, dark);
        let left = NIGHT - this.runT;
        let ct = left > 0 ? clock(left) : "DAWN";
        let cw = <f64>api.textWidth(ct, 2);
        api.text(<f32>Math.floor((W - cw) * 0.5), 5, ct, left > 0 && left < 20 ? gold : pale, 2, dark);
        if (left > 0) {
            api.textCentered(17, "TO DAWN", api.rampColor(R_STONE, 3), 1, dark);
        }
        let ks = this.kills.toString();
        let kw = <f64>api.textWidth(ks, 1);
        api.text(<f32>(W - 3 - kw), 5, ks, pale, 1, dark);
        this.icon(api, <i32>(W - 3 - kw - 8), 4, -1);
        // the boss's health
        if (this.bossOn) {
            let bi = K_FIRST[K_BOSS];
            api.textCentered(24, "THE MIRE KING", pink, 1, dark);
            let bw = 120.0;
            let bx = Math.floor((W - bw) * 0.5);
            api.rect(<f32>bx - 1, 30, <f32>bw + 2, 4, ink);
            api.rect(<f32>bx, 31, <f32>Math.round(bw * clampf(this.fHp[bi] / this.fMax[bi], 0, 1)), 2, pink);
        }
        // what he carries: weapons, then passives, with their levels
        let n = 0;
        for (let id = 0; id < NUP; id++) {
            if (this.lv[id] == 0) { continue; }
            let x = 3 + n * 12;
            let y = <i32>H - 12;
            api.rect(<f32>(x - 1), <f32>(y - 1), 11, 11, ink);
            this.icon(api, x, y, id);
            api.text(<f32>(x + 7), <f32>(y + 6), this.lv[id].toString(), id <= W_BOLT ? gold : pale, 1, 0);
            n++;
        }
        // banners
        if (this.bannerT >= 0 && this.state == ST_PLAY) {
            let c = (<i32>Math.floor(this.bannerT * 6)) % 2 == 0 || this.bannerT > 0.6 ? gold : white;
            api.textCentered(this.bossOn ? 38 : 26, this.banner, c, 1, dark);
        }
        if (this.state == ST_CARDS) {
            this.hudCards(api, W, H);
        }
        if (this.state == ST_OVER || this.state == ST_DAWN) {
            this.hudEnd(api, W, H);
        }
    }

    burst(api: GameApi, x: f64, y: f64, r: f64, n: i32, c: u32): void {
        for (let k = 0; k < n; k++) {
            let a = <f64>k / <f64>n * Math.PI * 2;
            api.rect(<f32>Math.round(x + Math.cos(a) * r), <f32>Math.round(y + Math.sin(a) * r * 0.8), 1, 1, c);
        }
    }

    hudIdle(api: GameApi, W: f64, H: f64): void {
        let dark = api.rampColor(R_STONE, 0);
        let gold = api.rampColor(R_GLOW, 2);
        let pale = api.rampColor(R_STONE, 5);
        api.textCentered(12, "SWARM WARD", gold, 2, dark);
        api.textCentered(26, "KEEP THE LANTERN LIT TILL DAWN", pale, 1, dark);
        if (api.time % 1.0 < 0.75) {
            api.textCentered(<f32>(H - 28), "TAP OR CLICK TO START", gold, 1, dark);
        }
        api.textCentered(<f32>(H - 19), "HE WALKS TO THE POINTER OR FINGER", api.rampColor(R_STONE, 4), 1, dark);
        api.textCentered(<f32>(H - 11), "HIS LIGHTS FIGHT ON THEIR OWN", api.rampColor(R_STONE, 4), 1, dark);
        if (this.best >= 0) {
            let s = this.bestDawn ? "BEST: DAWN, " + this.bestKills.toString() + " KILLS" : "BEST " + clock(this.best);
            api.textCentered(36, s, api.rampColor(R_WISP, 1), 1, dark);
        }
    }

    hudCards(api: GameApi, W: f64, H: f64): void {
        let dark = api.rampColor(R_STONE, 0);
        let ink = api.rampColor(R_COAT, 0);
        let fill = api.rampColor(R_STONE, 1);
        let edge = api.rampColor(R_STONE, 3);
        let gold = api.rampColor(R_GLOW, 2);
        let pale = api.rampColor(R_STONE, 5);
        let soft = api.rampColor(R_STONE, 4);
        let teal = api.rampColor(R_WISP, 1);
        let white = api.rampColor(R_SLATE, 5);
        api.textCentered(26, "LEVEL " + this.level.toString() + "! CHOOSE ONE", gold, 1, dark);
        let w = 64.0, h = 64.0, top = 36.0;
        for (let c = 0; c < 3; c++) {
            let appear = clampf((this.cardT - 0.06 * <f64>c) / 0.18, 0, 1);
            if (appear <= 0) { continue; }
            let x = this.cardX(c, w);
            let y = top + Math.round((1 - appear) * 10);
            let id = this.cardId[c];
            let hot = this.hover == c;
            let chosen = this.picked == c;
            if (this.picked >= 0 && !chosen && this.pickT > 0.05) { continue; }
            let border = chosen ? ((<i32>Math.floor(this.pickT * 20)) % 2 == 0 ? white : gold) : (hot ? gold : edge);
            api.rect(<f32>(x - 1), <f32>(y - 1), <f32>(w + 2), <f32>(h + 2), ink);
            api.rect(<f32>x, <f32>y, <f32>w, <f32>h, border);
            api.rect(<f32>(x + 1), <f32>(y + 1), <f32>(w - 2), <f32>(h - 2), fill);
            api.rect(<f32>(x + 26), <f32>(y + 4), 12, 12, ink);
            this.icon(api, <i32>(x + 27), <i32>(y + 5), id);
            let name = NAMES[id];
            api.text(<f32>(x + Math.floor((w - <f64>api.textWidth(name, 1)) * 0.5)), <f32>(y + 20), name, hot || chosen ? gold : pale, 1, 0);
            let tag = "";
            if (id == C_TEA) { tag = ""; }
            else if (this.lv[id] == 0) { tag = "NEW!"; }
            else { tag = "LV " + (this.lv[id] + 1).toString(); }
            if (tag.length > 0) {
                api.text(<f32>(x + Math.floor((w - <f64>api.textWidth(tag, 1)) * 0.5)), <f32>(y + 28), tag, this.lv[id] == 0 ? teal : soft, 1, 0);
            }
            let l1 = this.desc(id, 0), l2 = this.desc(id, 1);
            api.text(<f32>(x + Math.floor((w - <f64>api.textWidth(l1, 1)) * 0.5)), <f32>(y + 40), l1, soft, 1, 0);
            api.text(<f32>(x + Math.floor((w - <f64>api.textWidth(l2, 1)) * 0.5)), <f32>(y + 47), l2, soft, 1, 0);
        }
        if (!api.demo) {
            api.textCentered(<f32>(top + h + 6), "TAP A CARD", api.rampColor(R_STONE, 3), 1, dark);
        }
    }

    desc(id: i32, line: i32): string {
        let n = this.lv[id] + 1;   // the level it would reach
        if (id == W_SPARK) {
            if (n == 1) { return line == 0 ? "SPARKS FLY AT" : "THE NEAREST"; }
            if (n == 2 || n == 4) { return line == 0 ? "+1 SPARK" : "EACH VOLLEY"; }
            if (n == 3) { return line == 0 ? "THEY PIERCE," : "+DAMAGE"; }
            return line == 0 ? "FASTER," : "PIERCE TWO";
        }
        if (id == W_MOTE) {
            if (n == 1) { return line == 0 ? "A MOTE CIRCLES" : "AROUND YOU"; }
            if (n <= 3) { return line == 0 ? "+1 MOTE" : "+DAMAGE"; }
            if (n == 4) { return line == 0 ? "WIDER ORBIT" : "+DAMAGE"; }
            return line == 0 ? "FASTER ORBIT" : "+DAMAGE";
        }
        if (id == W_PULSE) {
            if (n == 1) { return line == 0 ? "A RING OF LIGHT" : "PUSHES FOES"; }
            if (n == 3 || n == 5) { return line == 0 ? "+DAMAGE" : "MORE OFTEN"; }
            return line == 0 ? "BIGGER RING" : "MORE OFTEN";
        }
        if (id == W_EMBER) {
            if (n == 1) { return line == 0 ? "CINDERS BURN" : "BEHIND YOU"; }
            if (n == 3) { return line == 0 ? "WIDER, LONGER" : "+DAMAGE"; }
            return line == 0 ? "HOTTER" : "+DAMAGE";
        }
        if (id == W_BOLT) {
            if (n == 1) { return line == 0 ? "LIGHTNING HITS" : "FOES IN VIEW"; }
            if (n == 2 || n == 4) { return line == 0 ? "+1 BOLT" : "+DAMAGE"; }
            if (n == 3) { return line == 0 ? "+DAMAGE" : ""; }
            return line == 0 ? "MORE OFTEN" : "+DAMAGE";
        }
        if (id == P_BOOTS) { return line == 0 ? "+12% SPEED" : ""; }
        if (id == P_HOOK) { return line == 0 ? "+45% PICKUP" : "REACH"; }
        if (id == P_COAT) { return line == 0 ? "-12% DAMAGE" : "TAKEN"; }
        if (id == P_FLASK) { return line == 0 ? "+25 MAX HP" : "AND HEAL 25"; }
        if (id == P_WICK) { return line == 0 ? "-8% COOLDOWN" : "+8% AREA"; }
        return line == 0 ? "HEAL 35 HP" : "";
    }

    hudEnd(api: GameApi, W: f64, H: f64): void {
        let dark = api.rampColor(R_STONE, 0);
        let ink = api.rampColor(R_COAT, 0);
        let gold = api.rampColor(R_GLOW, 2);
        let pale = api.rampColor(R_STONE, 5);
        let teal = api.rampColor(R_WISP, 1);
        let red = api.rampColor(R_BLOOD, 4);
        if (this.stateT < 0.4) {
            return;
        }
        let y = 38.0;
        api.rect(0, <f32>(y - 4), <f32>W, 52, ink);
        api.rect(0, <f32>(y - 4), <f32>W, 1, this.won ? gold : red);
        api.rect(0, <f32>(y + 47), <f32>W, 1, this.won ? gold : red);
        api.textCentered(<f32>y, this.won ? "DAWN!" : "THE LANTERN WENT OUT", this.won ? gold : red, 2, dark);
        let tstr = this.won ? "NIGHT SURVIVED" : "TIME " + clock(this.endT);
        api.textCentered(<f32>(y + 15), tstr + "   KILLS " + this.kills.toString() + "   LV " + this.level.toString(), pale, 1, 0);
        let b = this.bestDawn ? "BEST: DAWN, " + this.bestKills.toString() + " KILLS" : "BEST " + clock(this.best);
        if (this.newBest && (<i32>Math.floor(api.time * 3)) % 2 == 0) {
            b = "NEW BEST!";
        }
        api.textCentered(<f32>(y + 25), b, teal, 1, 0);
        if (this.stateT > 0.8 && !api.demo && (<i32>Math.floor(api.time * 2)) % 2 == 0) {
            api.textCentered(<f32>(y + 37), "TAP FOR A NEW NIGHT", gold, 1, 0);
        }
    }

    // small 9 x 9 icons drawn with rectangles
    icon(api: GameApi, x: i32, y: i32, id: i32): void {
        let fx = <f32>x, fy = <f32>y;
        if (id == -1) {   // a tiny skull: the kill count
            let c = api.rampColor(R_STONE, 5);
            let d = api.rampColor(R_STONE, 0);
            api.rect(fx, fy + 1, 5, 4, c); api.rect(fx + 1, fy, 3, 1, c); api.rect(fx + 1, fy + 5, 3, 1, c);
            api.rect(fx + 1, fy + 2, 1, 1, d); api.rect(fx + 3, fy + 2, 1, 1, d);
            return;
        }
        if (id == W_SPARK) {
            api.line(fx + 1, fy + 8, fx + 7, fy + 2, api.rampColor(R_EMBER, 2));
            api.line(fx + 2, fy + 8, fx + 8, fy + 2, api.rampColor(R_EMBER, 1));
            api.rect(fx + 7, fy + 1, 2, 2, api.rampColor(R_EMBER, 3));
        } else if (id == W_MOTE) {
            let c = api.rampColor(R_GLOW, 2);
            api.rect(fx + 4, fy + 4, 1, 1, api.rampColor(R_COAT, 4));
            api.rect(fx + 3, fy, 3, 2, c); api.rect(fx, fy + 6, 3, 2, c); api.rect(fx + 6, fy + 6, 3, 2, c);
        } else if (id == W_PULSE) {
            let c = api.rampColor(R_GLOW, 2);
            api.rect(fx + 2, fy, 5, 1, c); api.rect(fx + 2, fy + 8, 5, 1, c);
            api.rect(fx, fy + 2, 1, 5, c); api.rect(fx + 8, fy + 2, 1, 5, c);
            api.rect(fx + 1, fy + 1, 1, 1, c); api.rect(fx + 7, fy + 1, 1, 1, c);
            api.rect(fx + 1, fy + 7, 1, 1, c); api.rect(fx + 7, fy + 7, 1, 1, c);
            api.rect(fx + 4, fy + 4, 1, 1, api.rampColor(R_GLOW, 1));
        } else if (id == W_EMBER) {
            api.rect(fx + 1, fy + 7, 7, 2, api.rampColor(R_EMBER, 1));
            api.rect(fx + 2, fy + 4, 5, 3, api.rampColor(R_EMBER, 2));
            api.rect(fx + 3, fy + 2, 3, 2, api.rampColor(R_EMBER, 2));
            api.rect(fx + 4, fy, 1, 2, api.rampColor(R_EMBER, 3));
            api.rect(fx + 4, fy + 5, 1, 2, api.rampColor(R_EMBER, 3));
        } else if (id == W_BOLT) {
            let c = api.rampColor(R_GLOW, 2);
            api.line(fx + 5, fy, fx + 2, fy + 4, c); api.line(fx + 2, fy + 4, fx + 6, fy + 4, c);
            api.line(fx + 6, fy + 4, fx + 3, fy + 8, c);
        } else if (id == P_BOOTS) {
            let c = api.rampColor(R_SKIN, 3);
            api.rect(fx + 2, fy + 1, 3, 6, c); api.rect(fx + 2, fy + 6, 6, 2, c);
            api.rect(fx, fy + 2, 1, 1, api.rampColor(R_STONE, 4)); api.rect(fx, fy + 5, 1, 1, api.rampColor(R_STONE, 4));
        } else if (id == P_HOOK) {
            let c = api.rampColor(R_SKIN, 3);
            api.rect(fx + 2, fy + 2, 1, 7, c); api.rect(fx + 2, fy, 5, 1, c); api.rect(fx + 1, fy + 1, 1, 1, c);
            api.rect(fx + 7, fy + 1, 1, 2, c);
            api.rect(fx + 6, fy + 4, 3, 3, api.rampColor(R_WISP, 1));
        } else if (id == P_COAT) {
            let c = api.rampColor(R_COAT, 4);
            api.rect(fx + 1, fy + 1, 7, 5, c); api.rect(fx + 2, fy + 6, 5, 1, c); api.rect(fx + 3, fy + 7, 3, 1, c);
            api.rect(fx + 4, fy + 2, 1, 4, api.rampColor(R_COAT, 2));
        } else if (id == P_FLASK) {
            api.rect(fx + 3, fy, 3, 2, api.rampColor(R_SKIN, 3));
            api.rect(fx + 1, fy + 2, 7, 7, api.rampColor(R_SLATE, 3));
            api.rect(fx + 1, fy + 5, 7, 2, api.rampColor(R_GLOW, 2));
        } else if (id == P_WICK) {
            api.rect(fx + 3, fy + 4, 3, 5, api.rampColor(R_STONE, 5));
            api.rect(fx + 4, fy + 1, 1, 3, api.rampColor(R_GLOW, 2));
            api.rect(fx + 3, fy + 2, 3, 1, api.rampColor(R_GLOW, 1));
        } else {
            api.rect(fx + 1, fy + 3, 6, 5, api.rampColor(R_SKIN, 4));
            api.rect(fx + 7, fy + 4, 2, 2, api.rampColor(R_SKIN, 4));
            api.rect(fx + 2, fy, 1, 2, api.rampColor(R_STONE, 4)); api.rect(fx + 5, fy + 1, 1, 2, api.rampColor(R_STONE, 4));
        }
    }
}
