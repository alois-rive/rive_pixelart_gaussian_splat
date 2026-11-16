// Tiny Quest: a small turn-based RPG on an island seen at an isometric angle. Click a tile and the
// hero hops there along a grid path; wild ground (meadow, wood, the hill) hides monsters, more likely
// the longer it has been since the last fight. A fight happens in the same world: the monsters pop up
// on the tiles beside the hero, the camera eases in, and big buttons choose ATTACK, MAGIC (hits all),
// DEFEND (halves the next blows) or POTION. Win XP and gold, level up, rest at the village inn, buy
// potions, then climb the hill and beat the Warden at the shrine. Pointer only; demo mode plays itself.
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP, SFX_BLIP, SFX_COIN, SFX_HIT, SFX_EXPLODE, SFX_POWERUP,
         SFX_THUD, SFX_WHOOSH, SFX_NOTE, SFX_BELL, SFX_LOSE, SFX_WIN, SFX_TICK, SFX_POP, SFX_CLICK,
         SFX_ZAP, SFX_JUMP } from "./game_api";

// ---------------------------------------------------------------- the island (models/env/make_env.py: MAP)
// 13 columns (x) by 10 rows (z), tile (i, j) centred at (i - 6, j - 4.5); one row per string.
// ~ sea  . sand  g meadow  w wood  r road  = bridge  R river  V village  I inn  h house  1 2 hill  S shrine
const W: i32 = 13;
const D: i32 = 10;
const MAP: string =
    "~~.11.R..~~~~" +
    "~.1221Rgg.~~~" +
    ".12S21Rwgg.~~" +
    ".1221wRwwgg.~" +
    ".g11wg=rrgw.~" +
    ".ggwwgRgrrg.~" +
    "~.ggwgRgwrIh." +
    "~..gg.RggVVh." +
    "~~....R.ghV.~" +
    "~~~~..R....~~";
const START_I: i32 = 9;       // the village plaza
const START_J: i32 = 7;
const INN_I: i32 = 10;
const INN_J: i32 = 6;
const SHRINE_I: i32 = 3;
const SHRINE_J: i32 = 2;

const STEP_T: f64 = 0.27;     // seconds a hop from tile to tile
const HOP: f64 = 0.16;        // hop height
const MAP_H: f64 = 6.4;       // orthoHeight on the map (a tile is about 21 x 11 art pixels: tappable)
const FIGHT_H: f64 = 4.7;     // orthoHeight in a fight
const POTION_COST: i32 = 8;
const POTION_HEAL: i32 = 22;
const MAGIC_COST: i32 = 4;

// states
const ST_TITLE: i32 = 0;      // before the first click: the hint
const ST_MAP: i32 = 1;
const ST_FIGHT: i32 = 2;
const ST_VICTORY: i32 = 3;
const ST_OVER: i32 = 4;

// fight phases
const PH_INTRO: i32 = 0;
const PH_CHOOSE: i32 = 1;
const PH_HERO: i32 = 2;
const PH_ENEMY: i32 = 3;
const PH_WON: i32 = 4;
const PH_LOST: i32 = 5;

// actions
const A_ATTACK: i32 = 0;
const A_MAGIC: i32 = 1;
const A_DEFEND: i32 = 2;
const A_POTION: i32 = 3;

// monster kinds
const K_SLIME: i32 = 0;
const K_BAT: i32 = 1;
const K_SHROOM: i32 = 2;
const K_WARDEN: i32 = 3;
const MAXE: i32 = 3;

const NFT: i32 = 10;          // floating numbers
const NPUFF: i32 = 3;
const NSPARK: i32 = 6;
const NCOIN: i32 = 4;
const NDUST: i32 = 2;
const MAXPATH: i32 = 140;
const NGROVE: i32 = 10;       // one bone per wood tile's trees

// palette indices (art/palette.json "colors")
const P_INK: i32 = 0;         // #2b3f41
const P_TEAL: i32 = 2;        // #57797d
const P_SAGE: i32 = 3;        // #8ca697
const P_LEAF: i32 = 7;        // #a4ab79
const P_RED: i32 = 10;        // #8c504d
const P_ROSE: i32 = 11;       // #b87a66
const P_CREAM: i32 = 12;      // #c1bcac
const P_GOLD: i32 = 20;       // #e2b55f
const P_OCHRE: i32 = 19;      // #b68241
const P_GREY: i32 = 22;       // #7c7c7c
const P_SLATE: i32 = 23;      // #4b5053
const P_PLUM: i32 = 27;       // #8f619a
const P_NAVY: i32 = 28;       // #20415b
const P_SEA: i32 = 29;        // #235b7c
const P_SKY: i32 = 31;        // #5eb3bc

function levelY(n: i32): f64 {
    return n == 0 ? 0.18 : 0.45 + 0.4 * <f64>(n - 1);
}

function cellAt(i: i32, j: i32): i32 {
    if (i < 0 || j < 0 || i >= W || j >= D) {
        return 126; // '~'
    }
    return MAP.charCodeAt(j * W + i);
}

// the tile's level (0 sand .. 4 shrine), or -1 for water
function levelAt(i: i32, j: i32): i32 {
    let c = cellAt(i, j);
    if (c == 46) return 0;                                         // .
    if (c == 103 || c == 119 || c == 114 || c == 86 || c == 73 || c == 104 || c == 61) return 1; // g w r V I h =
    if (c == 49) return 2;                                         // 1
    if (c == 50) return 3;                                         // 2
    if (c == 83) return 4;                                         // S
    return -1;
}

function walkable(i: i32, j: i32): bool {
    let c = cellAt(i, j);
    return levelAt(i, j) >= 0 && c != 104 && c != 83;              // not a house, not the shrine
}

function wild(i: i32, j: i32): bool {
    let c = cellAt(i, j);
    return c == 103 || c == 119 || c == 49 || c == 50;             // meadow, wood, hill
}

function tileX(i: i32): f64 { return <f64>i - 6.0; }
function tileZ(j: i32): f64 { return <f64>j - 4.5; }

function kindName(k: i32): string {
    if (k == K_SLIME) return "GLOOP";
    if (k == K_BAT) return "FLITTER";
    if (k == K_SHROOM) return "CAPLING";
    return "WARDEN";
}

function iabs(a: i32): i32 { return a < 0 ? -a : a; }

export class Game {
    state: i32 = ST_TITLE;
    stateT: f64 = 0;
    wasDemo: bool = false;
    best: i32 = 0;
    score: i32 = 0;

    // bones
    hero: i32 = -1;
    warden: i32 = -1;
    slimeB: StaticArray<i32> = new StaticArray<i32>(3);
    batB: StaticArray<i32> = new StaticArray<i32>(3);
    shroomB: StaticArray<i32> = new StaticArray<i32>(3);
    marker: i32 = -1;
    pin: i32 = -1;
    puffB: StaticArray<i32> = new StaticArray<i32>(NPUFF);
    sparkB: StaticArray<i32> = new StaticArray<i32>(NSPARK);
    coinB: StaticArray<i32> = new StaticArray<i32>(NCOIN);
    potionB: i32 = -1;
    slashB: i32 = -1;
    guardB: i32 = -1;
    dustB: StaticArray<i32> = new StaticArray<i32>(NDUST);
    groveB: StaticArray<i32> = new StaticArray<i32>(NGROVE);
    groveS: StaticArray<f64> = new StaticArray<f64>(NGROVE);  // 1 standing, 0.3 squashed out of the way
    ngrove: i32 = 0;

    // the hero's stats
    level: i32 = 1;
    xp: i32 = 0;
    hp: i32 = 30;
    maxHp: i32 = 30;
    mp: i32 = 8;
    maxMp: i32 = 8;
    atk: i32 = 6;
    gold: i32 = 0;
    potions: i32 = 1;
    steps: i32 = 0;
    wildSteps: i32 = 2;
    wardenDown: bool = false;
    fights: i32 = 0;

    // the hero on the map
    hi: i32 = START_I;
    hj: i32 = START_J;
    fromI: i32 = START_I;
    fromJ: i32 = START_J;
    walking: bool = false;
    walkT: f64 = 0;
    pathI: StaticArray<i32> = new StaticArray<i32>(MAXPATH);
    pathJ: StaticArray<i32> = new StaticArray<i32>(MAXPATH);
    pathLen: i32 = 0;
    pathPos: i32 = 0;
    goalI: i32 = -1;
    goalJ: i32 = -1;
    heroYaw: f64 = 45;
    landT: f64 = 1;
    stepCount: i32 = 0;
    hurtT: f64 = -1;
    hoverI: i32 = -1;
    hoverJ: i32 = -1;
    mapPress: bool = false;     // a press on the map: it aims while held (touch drags) and walks on release
    innT: f64 = -1;             // the rest at the inn: a little glow and a message
    noteText: string = "";      // a short line at the top (map)
    noteT: f64 = -1;
    bangT: f64 = -1;            // the "!" over the hero when monsters jump out
    backT: f64 = -1;            // the hop back from the Warden's doorstep
    backI: i32 = 0;
    backJ: i32 = 0;

    // BFS scratch
    prev: StaticArray<i32> = new StaticArray<i32>(W * D);
    queue: StaticArray<i32> = new StaticArray<i32>(W * D);
    dist: StaticArray<i32> = new StaticArray<i32>(W * D);

    // the fight
    phase: i32 = PH_INTRO;
    phaseT: f64 = 0;
    ne: i32 = 0;
    eKind: StaticArray<i32> = new StaticArray<i32>(MAXE);
    eBone: StaticArray<i32> = new StaticArray<i32>(MAXE);
    eHp: StaticArray<i32> = new StaticArray<i32>(MAXE);
    eMax: StaticArray<i32> = new StaticArray<i32>(MAXE);
    eX: StaticArray<f64> = new StaticArray<f64>(MAXE);
    eY: StaticArray<f64> = new StaticArray<f64>(MAXE);
    eZ: StaticArray<f64> = new StaticArray<f64>(MAXE);
    ePop: StaticArray<f64> = new StaticArray<f64>(MAXE);   // time since popping up
    eFlash: StaticArray<f64> = new StaticArray<f64>(MAXE);
    eDead: StaticArray<f64> = new StaticArray<f64>(MAXE);  // < 0 alive; time since defeated
    ePhase: StaticArray<f64> = new StaticArray<f64>(MAXE);
    eLunge: StaticArray<f64> = new StaticArray<f64>(MAXE); // 0..1 of the way to the hero
    target: i32 = 0;
    defending: bool = false;
    actKind: i32 = 0;           // the hero's action, or the enemy acting
    actor: i32 = -1;            // the enemy acting (PH_ENEMY)
    actHit: bool = false;
    heroLunge: f64 = 0;         // 0..1 towards the target
    heroHop: f64 = 0;
    wardenCycle: i32 = 0;       // the Warden: hit, hit, gather, SLAM
    charged: bool = false;
    shakeT: f64 = -1;
    fightMsg: string = "";
    fightMsgT: f64 = -1;
    wonXp: i32 = 0;
    wonGold: i32 = 0;
    levelUps: i32 = 0;
    pressed: i32 = -1;          // the button flashing after a click
    pressedT: f64 = -1;
    potionT: f64 = -1;
    slashT: f64 = -1;
    slashX: f64 = 0;
    slashY: f64 = 0;
    slashZ: f64 = 0;
    levelUpT: f64 = -1;

    // floating numbers (world point, text, colour, age)
    ftX: StaticArray<f64> = new StaticArray<f64>(NFT);
    ftY: StaticArray<f64> = new StaticArray<f64>(NFT);
    ftZ: StaticArray<f64> = new StaticArray<f64>(NFT);
    ftT: StaticArray<f64> = new StaticArray<f64>(NFT);
    ftC: StaticArray<i32> = new StaticArray<i32>(NFT);
    ftS: Array<string> = new Array<string>(NFT);
    ftNext: i32 = 0;

    // effects
    puffT: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    puffX: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    puffY: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    puffZ: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    puffS: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    puffNext: i32 = 0;
    sparkT: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    sparkX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    sparkY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    sparkZ: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    sparkMode: StaticArray<i32> = new StaticArray<i32>(NSPARK);   // 0 burst, 1 orbit the hero, 2 orbit the Warden
    coinT: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    coinX: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    coinY: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    coinZ: StaticArray<f64> = new StaticArray<f64>(NCOIN);
    dustT: StaticArray<f64> = new StaticArray<f64>(NDUST);
    dustX: StaticArray<f64> = new StaticArray<f64>(NDUST);
    dustY: StaticArray<f64> = new StaticArray<f64>(NDUST);
    dustZ: StaticArray<f64> = new StaticArray<f64>(NDUST);
    dustNext: i32 = 0;

    // the camera
    camX: f64 = 0;
    camY: f64 = 0;
    camZ: f64 = 0;
    camH: f64 = MAP_H;

    // the demo player
    dWait: f64 = 0;
    dGoalLevel: i32 = 3;
    dChoice: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        this.hero = api.bone("hero");
        this.warden = api.bone("warden");
        for (let k = 0; k < 3; k++) {
            this.slimeB[k] = api.bone("slime" + k.toString());
            this.batB[k] = api.bone("bat" + k.toString());
            this.shroomB[k] = api.bone("shroom" + k.toString());
        }
        this.marker = api.bone("marker");
        this.pin = api.bone("pin");
        for (let k = 0; k < NPUFF; k++) {
            this.puffB[k] = api.bone("puff" + k.toString());
        }
        for (let k = 0; k < NSPARK; k++) {
            this.sparkB[k] = api.bone("spark" + k.toString());
        }
        for (let k = 0; k < NCOIN; k++) {
            this.coinB[k] = api.bone("coin" + k.toString());
        }
        for (let k = 0; k < NDUST; k++) {
            this.dustB[k] = api.bone("dust" + k.toString());
        }
        for (let k = 0; k < NGROVE; k++) {
            let b = api.bone("grove" + k.toString());
            if (b < 0) break;
            this.groveB[k] = b;
            this.groveS[k] = 1;
            this.ngrove = k + 1;
        }
        this.potionB = api.bone("potion");
        this.slashB = api.bone("slash");
        this.guardB = api.bone("guard");
        for (let k = 0; k < NFT; k++) {
            this.ftS[k] = "";
        }
        this.wasDemo = api.demo;
        this.clearEffects();
        this.newRun(api);
        this.state = api.demo ? ST_MAP : ST_TITLE;
        this.heroPX = tileX(this.hi);
        this.heroPY = levelY(levelAt(this.hi, this.hj));
        this.heroPZ = tileZ(this.hj);
        this.camX = this.heroPX;
        this.camY = this.heroPY + 0.3;
        this.camZ = this.heroPZ;
        this.dWait = 0.15;
    }

    // ------------------------------------------------------------------ runs

    newRun(api: GameApi): void {
        this.level = 1;
        this.xp = 0;
        this.maxHp = 30;
        this.hp = 30;
        this.maxMp = 8;
        this.mp = 8;
        this.atk = 6;
        this.gold = 0;
        this.potions = 1;
        this.steps = 0;
        this.wildSteps = 2;
        this.wardenDown = false;
        this.fights = 0;
        this.hi = START_I;
        this.hj = START_J;
        this.fromI = START_I;
        this.fromJ = START_J;
        this.walking = false;
        this.pathLen = 0;
        this.pathPos = 0;
        this.goalI = -1;
        this.heroYaw = 45;
        this.ne = 0;
        this.charged = false;
        this.wardenCycle = 0;
        this.defending = false;
        this.hurtT = -1;
        this.noteT = -1;
        this.innT = -1;
        this.state = ST_MAP;
        this.stateT = 0;
        // the demo player: most runs climb at level 3, some try their luck at 2
        this.dGoalLevel = api.rand() < 0.35 ? 2 : 3;
        this.dWait = 0.15;
    }

    hpFor(lv: i32): i32 { return 30 + 9 * (lv - 1); }
    mpFor(lv: i32): i32 { return 8 + 3 * (lv - 1); }
    atkFor(lv: i32): i32 { return 6 + 2 * (lv - 1); }
    xpFor(lv: i32): i32 {
        // XP needed to reach level lv + 1
        if (lv == 1) return 12;
        if (lv == 2) return 32;
        if (lv == 3) return 60;
        if (lv == 4) return 96;
        return 96 + 45 * (lv - 4);
    }

    computeScore(): i32 {
        let s = 500 + this.level * 100 + this.gold * 5 - this.steps * 2;
        return s < 100 ? 100 : s;
    }

    // ------------------------------------------------------------------ paths

    // BFS over walkable tiles (4-neighbours, at most one level up or down). Fills pathI/J from the
    // tile after (si, sj) to (ti, tj); false when unreachable.
    findPath(si: i32, sj: i32, ti: i32, tj: i32): bool {
        if (!walkable(ti, tj)) {
            return false;
        }
        for (let k = 0; k < W * D; k++) {
            this.prev[k] = -2;
        }
        let head = 0, tail = 0;
        let s = sj * W + si;
        this.prev[s] = -1;
        this.queue[tail++] = s;
        let goal = tj * W + ti;
        while (head < tail) {
            let c = this.queue[head++];
            if (c == goal) {
                break;
            }
            let ci = c % W, cj = c / W;
            let lv = levelAt(ci, cj);
            for (let d = 0; d < 4; d++) {
                let ni = ci + (d == 0 ? 1 : (d == 1 ? -1 : 0));
                let nj = cj + (d == 2 ? 1 : (d == 3 ? -1 : 0));
                if (ni < 0 || nj < 0 || ni >= W || nj >= D || !walkable(ni, nj)) {
                    continue;
                }
                let n = nj * W + ni;
                if (this.prev[n] != -2 || iabs(levelAt(ni, nj) - lv) > 1) {
                    continue;
                }
                this.prev[n] = c;
                this.queue[tail++] = n;
            }
        }
        if (this.prev[goal] == -2) {
            return false;
        }
        // walk back from the goal
        let len = 0;
        let c = goal;
        while (c != s && len < MAXPATH) {
            this.queue[len++] = c;
            c = this.prev[c];
        }
        this.pathLen = len;
        for (let k = 0; k < len; k++) {
            let q = this.queue[len - 1 - k];
            this.pathI[k] = q % W;
            this.pathJ[k] = q / W;
        }
        this.pathPos = 0;
        return true;
    }

    // path lengths from (si, sj) to every tile into dist (-1 unreachable)
    flood(si: i32, sj: i32): void {
        for (let k = 0; k < W * D; k++) {
            this.dist[k] = -1;
        }
        let head = 0, tail = 0;
        let s = sj * W + si;
        this.dist[s] = 0;
        this.queue[tail++] = s;
        while (head < tail) {
            let c = this.queue[head++];
            let ci = c % W, cj = c / W;
            let lv = levelAt(ci, cj);
            for (let d = 0; d < 4; d++) {
                let ni = ci + (d == 0 ? 1 : (d == 1 ? -1 : 0));
                let nj = cj + (d == 2 ? 1 : (d == 3 ? -1 : 0));
                if (ni < 0 || nj < 0 || ni >= W || nj >= D || !walkable(ni, nj)) {
                    continue;
                }
                let n = nj * W + ni;
                if (this.dist[n] >= 0 || iabs(levelAt(ni, nj) - lv) > 1) {
                    continue;
                }
                this.dist[n] = this.dist[c] + 1;
                this.queue[tail++] = n;
            }
        }
    }

    // where a walk starts: the tile being hopped to, or the hero's tile
    walkFromI(): i32 { return this.walking ? this.pathI[this.pathPos] : this.hi; }
    walkFromJ(): i32 { return this.walking ? this.pathJ[this.pathPos] : this.hj; }

    // asks the hero to walk to (ti, tj); the shrine or a house means "the nearest tile beside it"
    walkTo(api: GameApi, ti: i32, tj: i32): bool {
        let si = this.walkFromI(), sj = this.walkFromJ();
        if (!walkable(ti, tj)) {
            if (levelAt(ti, tj) < 0) {
                return false;
            }
            // beside it: the reachable neighbour with the shortest walk
            this.flood(si, sj);
            let bi = -1, bj = -1, bd = 9999;
            for (let d = 0; d < 4; d++) {
                let ni = ti + (d == 0 ? 1 : (d == 1 ? -1 : 0));
                let nj = tj + (d == 2 ? 1 : (d == 3 ? -1 : 0));
                if (ni < 0 || nj < 0 || ni >= W || nj >= D) {
                    continue;
                }
                let dd = this.dist[nj * W + ni];
                if (dd >= 0 && dd < bd) {
                    bd = dd;
                    bi = ni;
                    bj = nj;
                }
            }
            if (bi < 0) {
                return false;
            }
            ti = bi;
            tj = bj;
        }
        if (ti == si && tj == sj) {
            if (!this.walking) {
                this.arrive(api, true);
            }
            return true;
        }
        if (!this.findPath(si, sj, ti, tj)) {
            return false;
        }
        if (this.walking) {
            // keep hopping to the tile in progress, then follow the new path: shift it by one
            for (let k = this.pathLen; k > 0; k--) {
                this.pathI[k] = this.pathI[k - 1];
                this.pathJ[k] = this.pathJ[k - 1];
            }
            this.pathI[0] = si;
            this.pathJ[0] = sj;
            this.pathLen++;
            this.pathPos = 0;
        } else {
            this.beginStep(api);
        }
        this.goalI = ti;
        this.goalJ = tj;
        return true;
    }

    beginStep(api: GameApi): void {
        this.fromI = this.hi;
        this.fromJ = this.hj;
        this.walking = true;
        this.walkT = 0;
        let ni = this.pathI[this.pathPos], nj = this.pathJ[this.pathPos];
        let dx = ni - this.hi, dz = nj - this.hj;
        this.heroYaw = dx > 0 ? 90.0 : (dx < 0 ? -90.0 : (dz > 0 ? 0.0 : 180.0));
    }

    // the hero lands on a tile: footsteps, the inn, the shrine, wild encounters
    arrive(api: GameApi, idle: bool): void {
        let i = this.hi, j = this.hj;
        let c = cellAt(i, j);
        if (!idle) {
            this.steps++;
            this.stepCount++;
            this.landT = 0;
            // footsteps: a soft tick every other hop, a thud when the level changes
            let dl = levelAt(i, j) - levelAt(this.fromI, this.fromJ);
            let pan = api.panAt(tileX(i), levelY(levelAt(i, j)), tileZ(j));
            if (dl != 0) {
                api.sound(SFX_THUD, dl > 0 ? 1.3 : 1.0, 0.3, pan);
            } else if (this.stepCount % 2 == 0) {
                api.sound(SFX_TICK, c == 61 ? 0.7 : (c == 46 ? 1.2 : 0.95), 0.4, pan);
            }
            // a puff of dust behind
            let d = this.dustNext;
            this.dustNext = (d + 1) % NDUST;
            this.dustT[d] = 0;
            this.dustX[d] = tileX(this.fromI) * 0.35 + tileX(i) * 0.65;
            this.dustY[d] = levelY(levelAt(i, j));
            this.dustZ[d] = tileZ(this.fromJ) * 0.35 + tileZ(j) * 0.65;
        }
        // the inn: rest (HP and MP full); the buy button shows while standing here
        if (i == INN_I && j == INN_J) {
            if (this.hp < this.maxHp || this.mp < this.maxMp) {
                this.hp = this.maxHp;
                this.mp = this.maxMp;
                this.innT = 0;
                this.say("RESTED AT THE INN: HP AND MP FULL");
                api.note(72, 0.5, 0.3, SFX_BELL);
                api.note(76, 0.45, 0.3, SFX_BELL, 0.18);
                api.note(79, 0.45, 0.3, SFX_BELL, 0.36);
            }
            this.stopWalk();
            return;
        }
        // beside the shrine: the Warden
        if (!this.wardenDown && iabs(i - SHRINE_I) + iabs(j - SHRINE_J) == 1) {
            this.stopWalk();
            this.startFight(api, true);
            return;
        }
        if (!idle && wild(i, j)) {
            this.wildSteps++;
            let p = Math.min(0.45, 0.07 * <f64>(this.wildSteps - 2));
            if (p > 0 && api.rand() < p) {
                this.stopWalk();
                this.startFight(api, false);
                return;
            }
        }
    }

    stopWalk(): void {
        this.walking = false;
        this.pathLen = 0;
        this.pathPos = 0;
        this.goalI = -1;
    }

    say(s: string): void {
        this.noteText = s;
        this.noteT = 0;
    }

    // ------------------------------------------------------------------ fights

    startFight(api: GameApi, boss: bool): void {
        this.state = ST_FIGHT;
        this.stateT = 0;
        this.phase = PH_INTRO;
        this.phaseT = 0;
        this.defending = false;
        this.charged = false;
        this.wardenCycle = 0;
        this.wildSteps = 0;
        this.fightMsgT = -1;
        this.bangT = 0;
        this.ne = 0;
        this.wonXp = 0;
        this.wonGold = 0;
        this.levelUps = 0;
        this.fights++;
        let i = this.hi, j = this.hj;
        if (boss) {
            // the hero hops back a tile (when it can) to face the Warden with room to swing
            let bi = i + (i - SHRINE_I), bj = j + (j - SHRINE_J);
            if (walkable(bi, bj) && iabs(levelAt(bi, bj) - levelAt(i, j)) <= 1) {
                this.backI = i;
                this.backJ = j;
                this.backT = 0;
                this.hi = bi;
                this.hj = bj;
                i = bi;
                j = bj;
            }
            this.ne = 1;
            this.eKind[0] = K_WARDEN;
            this.eBone[0] = this.warden;
            this.eX[0] = tileX(SHRINE_I);
            this.eY[0] = levelY(4);
            this.eZ[0] = tileZ(SHRINE_J);
            this.fightMsg = "THE WARDEN OF THE SHRINE AWAKENS!";
            // the Warden's sting: low and slow
            api.note(45, 0.8, 0, SFX_BELL);
            api.note(52, 0.6, 0, SFX_NOTE, 0.25);
            api.note(51, 0.6, 0, SFX_NOTE, 0.5);
            api.note(45, 0.7, 0, SFX_NOTE, 0.75);
            api.sound(SFX_EXPLODE, 0.5, 0.6, 0, 0.75);
        } else {
            // how many and which: tougher further from the village
            let lv = levelAt(i, j);
            let west = i < 6;
            let n = 1;
            if (lv >= 2) {
                n = 2 + (api.rand() < 0.5 ? 1 : 0);
            } else if (west) {
                n = 2 + (api.rand() < 0.3 ? 1 : 0);
            } else {
                n = 1 + (api.rand() < (this.fights <= 1 ? 0.35 : 0.55) ? 1 : 0);
            }
            // where they stand: a column to the hero's right on screen (the camera looks along the
            // diagonal, so (+1,-1) is straight right, (+2,0) right and down, (0,-2) right and up), or the
            // same column on the left; the tiles right beside the hero are the fallbacks
            // slots: A mid, B low, C high, B2 near low, C2 near high (right side; the left side mirrors them)
            let si: StaticArray<i32> = [1, 2, 0, 1, 0];
            let sj: StaticArray<i32> = [-1, 0, -2, 0, -1];
            let pref: StaticArray<i32> = n == 1 ? [0, 3, 4, 1, 2] : (n == 2 ? [1, 2, 3, 4, 0] : [0, 1, 2, 3, 4]);
            let bestSide = 0, bestCount = -1;
            for (let side = 0; side < 2; side++) {
                let cnt = this.placeSlots(api, i, j, n, side, si, sj, pref, lv, west, false);
                if (cnt > bestCount) {
                    bestCount = cnt;
                    bestSide = side;
                }
            }
            this.placeSlots(api, i, j, n, bestSide, si, sj, pref, lv, west, true);
            if (this.ne == 0) {
                // nowhere to stand: no fight after all
                this.state = ST_MAP;
                this.fights--;
                return;
            }
            // pool bones per kind
            let ns = 0, nb = 0, nm = 0;
            for (let e = 0; e < this.ne; e++) {
                let k = this.eKind[e];
                this.eBone[e] = k == K_SLIME ? this.slimeB[ns++] : (k == K_BAT ? this.batB[nb++] : this.shroomB[nm++]);
            }
            let names = "";
            for (let e = 0; e < this.ne; e++) {
                names += (e > 0 ? (e == this.ne - 1 ? " AND " : ", ") : "") + kindName(this.eKind[e]);
            }
            this.fightMsg = this.ne == 1 ? "A " + names + " JUMPS OUT!" : names + " JUMP OUT!";
            // the encounter sting: a quick rising diminished arpeggio and a hit
            api.note(64, 0.55, 0, SFX_NOTE);
            api.note(67, 0.55, 0, SFX_NOTE, 0.07);
            api.note(70, 0.55, 0, SFX_NOTE, 0.14);
            api.note(73, 0.6, 0, SFX_NOTE, 0.21);
            api.sound(SFX_ZAP, 0.55, 0.5, 0, 0.3);
        }
        for (let e = 0; e < this.ne; e++) {
            this.eFlash[e] = -1;
            this.eDead[e] = -1;
            this.eLunge[e] = 0;
            this.ePhase[e] = api.range(0, 6.28);
            this.ePop[e] = -0.35 - 0.12 * <f64>e;     // they pop up one after another, after the "!"
            let k = this.eKind[e];
            let hp = k == K_SLIME ? 10 : (k == K_BAT ? 7 : (k == K_SHROOM ? 15 : 80));
            this.eHp[e] = hp;
            this.eMax[e] = hp;
        }
        this.target = 0;
        // face the monsters
        this.faceEnemies();
    }

    // fills up to n enemy slots on one side (0 right, 1 left); with commit false only counts them
    placeSlots(api: GameApi, i: i32, j: i32, n: i32, side: i32, si: StaticArray<i32>, sj: StaticArray<i32>,
               pref: StaticArray<i32>, lv: i32, west: bool, commit: bool): i32 {
        let cnt = 0;
        let usedR = new StaticArray<f64>(5), usedU = new StaticArray<f64>(5);
        for (let s = 0; s < 5 && cnt < n; s++) {
            let k = pref[s];
            let di = side == 0 ? si[k] : -si[k], dj = side == 0 ? sj[k] : -sj[k];
            let ti = i + di, tj = j + dj;
            let tl = levelAt(ti, tj);
            let c = cellAt(ti, tj);
            let ok = tl >= 0 && c != 104 && c != 83 && iabs(tl - levelAt(i, j)) <= 1;
            if (!ok) {
                continue;
            }
            // keep them apart on screen
            let r = <f64>(di - dj) * 0.7071, u = -<f64>(di + dj) * 0.3536;
            let clash = false;
            for (let q = 0; q < cnt; q++) {
                if (Math.abs(usedR[q] - r) < 0.6 && Math.abs(usedU[q] - u) < 0.6) {
                    clash = true;
                }
            }
            if (clash) {
                continue;
            }
            usedR[cnt] = r;
            usedU[cnt] = u;
            if (commit) {
                let e = this.ne;
                this.eKind[e] = this.rollKind(api, lv, west);
                this.eX[e] = tileX(ti);
                this.eY[e] = levelY(tl);
                this.eZ[e] = tileZ(tj);
                this.ne++;
            }
            cnt++;
        }
        return cnt;
    }

    rollKind(api: GameApi, lv: i32, west: bool): i32 {
        let r = api.rand();
        if (lv >= 2) {
            return r < 0.45 ? K_BAT : K_SHROOM;
        }
        if (west) {
            return r < 0.3 ? K_SLIME : (r < 0.65 ? K_BAT : K_SHROOM);
        }
        return r < 0.55 ? K_SLIME : (r < 0.88 ? K_BAT : K_SHROOM);
    }

    faceEnemies(): void {
        let cx = 0.0, cz = 0.0, n = 0;
        for (let e = 0; e < this.ne; e++) {
            if (this.eDead[e] < 0) {
                cx += this.eX[e];
                cz += this.eZ[e];
                n++;
            }
        }
        if (n > 0) {
            cx /= <f64>n;
            cz /= <f64>n;
            this.heroYaw = Math.atan2(cx - tileX(this.hi), cz - tileZ(this.hj)) * 180.0 / Math.PI;
        }
    }

    alive(e: i32): bool { return this.eDead[e] < 0 && this.eHp[e] > 0; }

    aliveCount(): i32 {
        let n = 0;
        for (let e = 0; e < this.ne; e++) {
            if (this.alive(e)) n++;
        }
        return n;
    }

    // the target stays on a living monster
    fixTarget(): void {
        if (this.target >= 0 && this.target < this.ne && this.alive(this.target)) {
            return;
        }
        for (let e = 0; e < this.ne; e++) {
            if (this.alive(e)) {
                this.target = e;
                return;
            }
        }
    }

    // the player (or the demo) picks an action
    choose(api: GameApi, a: i32): void {
        if (this.state != ST_FIGHT || this.phase != PH_CHOOSE) {
            return;
        }
        if (a == A_MAGIC && this.mp < MAGIC_COST) {
            api.sound(SFX_CLICK, 0.6, 0.5);
            this.flashMsg("NOT ENOUGH MP");
            return;
        }
        if (a == A_POTION && this.potions <= 0) {
            api.sound(SFX_CLICK, 0.6, 0.5);
            this.flashMsg("NO POTIONS LEFT");
            return;
        }
        api.sound(SFX_BLIP, 1.0 + 0.08 * <f64>a, 0.55);
        this.pressed = a;
        this.pressedT = 0;
        this.fixTarget();
        this.defending = false;
        this.actKind = a;
        this.actHit = false;
        this.phase = PH_HERO;
        this.phaseT = 0;
        if (a == A_MAGIC) {
            this.mp -= MAGIC_COST;
        } else if (a == A_POTION) {
            this.potions--;
        }
    }

    flashMsg(s: string): void {
        this.fightMsg = s;
        this.fightMsgT = 0;
    }

    hitEnemy(api: GameApi, e: i32, dmg: i32, crit: bool): void {
        this.eHp[e] = max<i32>(0, this.eHp[e] - dmg);
        this.eFlash[e] = 0;
        let x = this.eX[e], y = this.eY[e], z = this.eZ[e];
        this.floatText(x, y + this.enemyTop(e), z, dmg.toString() + (crit ? "!" : ""), crit ? P_GOLD : P_CREAM);
        api.soundAt(SFX_HIT, x, y, z, crit ? 1.25 : 1.05, crit ? 0.8 : 0.65);
        if (this.eHp[e] <= 0) {
            this.eDead[e] = 0;
            let k = this.eKind[e];
            this.wonXp += k == K_SLIME ? 4 : (k == K_BAT ? 5 : (k == K_SHROOM ? 8 : 50));
            this.wonGold += k == K_SLIME ? 3 : (k == K_BAT ? 4 : (k == K_SHROOM ? 6 : 40));
        }
    }

    enemyTop(e: i32): f64 {
        let k = this.eKind[e];
        return k == K_SLIME ? 0.62 : (k == K_BAT ? 1.05 : (k == K_SHROOM ? 0.72 : 1.85));
    }

    hurtHero(api: GameApi, dmg: i32): void {
        if (this.defending) {
            dmg = max<i32>(1, (dmg + 1) / 2);
        }
        this.hp = max<i32>(0, this.hp - dmg);
        this.hurtT = 0;
        let x = tileX(this.hi), y = levelY(levelAt(this.hi, this.hj)), z = tileZ(this.hj);
        this.floatText(x, y + 1.05, z, dmg.toString(), P_ROSE);
        api.soundAt(SFX_HIT, x, y, z, 0.75, 0.75);
        api.soundAt(SFX_THUD, x, y, z, 1.2, 0.5);
        if (this.defending) {
            api.soundAt(SFX_CLICK, x, y, z, 1.6, 0.5);
        }
    }

    floatText(x: f64, y: f64, z: f64, s: string, col: i32): void {
        let k = this.ftNext;
        this.ftNext = (k + 1) % NFT;
        this.ftX[k] = x;
        this.ftY[k] = y;
        this.ftZ[k] = z;
        this.ftT[k] = 0;
        this.ftS[k] = s;
        this.ftC[k] = col;
    }

    puffAt(x: f64, y: f64, z: f64, s: f64): void {
        let k = this.puffNext;
        this.puffNext = (k + 1) % NPUFF;
        this.puffT[k] = 0;
        this.puffX[k] = x;
        this.puffY[k] = y;
        this.puffZ[k] = z;
        this.puffS[k] = s;
    }

    sparkAt(k: i32, x: f64, y: f64, z: f64, mode: i32, delay: f64): void {
        this.sparkT[k] = -delay;
        this.sparkX[k] = x;
        this.sparkY[k] = y;
        this.sparkZ[k] = z;
        this.sparkMode[k] = mode;
    }

    updateFight(api: GameApi, dt: f64): void {
        let prevT = this.phaseT;
        this.phaseT += dt;
        let t = this.phaseT;
        let hx = tileX(this.hi), hy = levelY(levelAt(this.hi, this.hj)), hz = tileZ(this.hj);
        if (this.phase == PH_INTRO) {
            for (let e = 0; e < this.ne; e++) {
                let p0 = this.ePop[e];
                this.ePop[e] += dt;
                if (p0 < 0 && this.ePop[e] >= 0) {
                    this.puffAt(this.eX[e], this.eY[e] + 0.2, this.eZ[e], 0.9);
                    api.soundAt(SFX_POP, this.eX[e], this.eY[e], this.eZ[e], 1.1 - 0.1 * <f64>e, 0.55);
                }
            }
            if (t > 0.45 && prevT <= 0.45) {
                this.fightMsgT = 0;
            }
            if (t > 1.15) {
                this.phase = PH_CHOOSE;
                this.phaseT = 0;
                this.dChoice = api.range(0.55, 0.95);
            }
            return;
        }
        for (let e = 0; e < this.ne; e++) {
            this.ePop[e] += dt;
        }
        if (this.phase == PH_CHOOSE) {
            if (api.demo) {
                this.dChoice -= dt;
                if (this.dChoice <= 0) {
                    this.demoChoose(api);
                }
            }
            return;
        }
        if (this.phase == PH_HERO) {
            let a = this.actKind;
            let e = this.target;
            if (a == A_ATTACK) {
                // wind up, lunge, strike, come back
                this.heroLunge = t < 0.1 ? -0.12 * t / 0.1 : (t < 0.22 ? -0.12 + 0.7 * (t - 0.1) / 0.12 : (t < 0.5 ? 0.58 * (1.0 - (t - 0.22) / 0.28) : 0.0));
                if (prevT < 0.1 && t >= 0.1) {
                    api.soundAt(SFX_WHOOSH, hx, hy, hz, 1.3, 0.45);
                }
                if (!this.actHit && t >= 0.22) {
                    this.actHit = true;
                    let dodge = this.eKind[e] == K_BAT && api.rand() < 0.2;
                    this.slashT = 0;
                    this.slashX = this.eX[e];
                    this.slashY = this.eY[e] + this.enemyTop(e) * 0.55;
                    this.slashZ = this.eZ[e];
                    if (dodge) {
                        this.floatText(this.eX[e], this.eY[e] + this.enemyTop(e), this.eZ[e], "MISS", P_SAGE);
                        api.soundAt(SFX_WHOOSH, this.eX[e], this.eY[e], this.eZ[e], 1.8, 0.4);
                    } else {
                        let crit = api.rand() < 0.1;
                        let dmg = this.atk - 1 + <i32>Math.floor(api.rand() * 4.0);
                        if (crit) {
                            dmg = <i32>Math.floor(<f64>dmg * 1.6);
                        }
                        this.hitEnemy(api, e, dmg, crit);
                    }
                }
                if (t > 0.62) {
                    this.endHeroTurn(api);
                }
            } else if (a == A_MAGIC) {
                // a hop, sparks burst on every monster, then the hit
                this.heroHop = t < 0.3 ? Math.sin(t / 0.3 * Math.PI) * 0.25 : 0.0;
                if (prevT <= 0.0001) {
                    api.soundAt(SFX_JUMP, hx, hy, hz, 1.2, 0.35);
                    api.note(76, 0.4, 0, SFX_BELL, 0.05);
                    api.note(83, 0.4, 0, SFX_BELL, 0.15);
                    let s = 0;
                    for (let k = 0; k < this.ne; k++) {
                        if (this.alive(k)) {
                            this.sparkAt(s++, this.eX[k], this.eY[k] + this.enemyTop(k) * 0.5, this.eZ[k], 0, 0.15);
                            this.sparkAt(s++, this.eX[k] + 0.12, this.eY[k] + this.enemyTop(k) * 0.9, this.eZ[k] - 0.1, 0, 0.25);
                        }
                    }
                }
                if (!this.actHit && t >= 0.42) {
                    this.actHit = true;
                    api.sound(SFX_ZAP, 0.8, 0.7);
                    for (let k = 0; k < this.ne; k++) {
                        if (this.alive(k)) {
                            let dmg = 4 + 2 * this.level + <i32>Math.floor(api.rand() * 3.0);
                            this.hitEnemy(api, k, dmg, false);
                        }
                    }
                }
                if (t > 0.85) {
                    this.endHeroTurn(api);
                }
            } else if (a == A_DEFEND) {
                if (prevT <= 0.0001) {
                    this.defending = true;
                    api.soundAt(SFX_CLICK, hx, hy, hz, 1.2, 0.6);
                    api.note(79, 0.3, 0, SFX_NOTE, 0.05);
                    this.floatText(hx, hy + 1.05, hz, "GUARD", P_GOLD);
                }
                if (t > 0.45) {
                    this.endHeroTurn(api);
                }
            } else if (a == A_POTION) {
                if (prevT <= 0.0001) {
                    this.potionT = 0;
                    api.soundAt(SFX_POP, hx, hy, hz, 0.9, 0.6);
                }
                if (!this.actHit && t >= 0.5) {
                    this.actHit = true;
                    let before = this.hp;
                    this.hp = min<i32>(this.maxHp, this.hp + POTION_HEAL);
                    this.floatText(hx, hy + 1.05, hz, "+" + (this.hp - before).toString(), P_LEAF);
                    api.note(72, 0.4, 0, SFX_NOTE);
                    api.note(76, 0.4, 0, SFX_NOTE, 0.08);
                    api.note(79, 0.45, 0, SFX_NOTE, 0.16);
                }
                if (t > 0.85) {
                    this.endHeroTurn(api);
                }
            }
            return;
        }
        if (this.phase == PH_ENEMY) {
            let e = this.actor;
            let k = this.eKind[e];
            let dur = k == K_WARDEN ? 0.95 : 0.7;
            if (k == K_WARDEN && this.wardenCycle % 4 == 2) {
                // gathering power: no blow, the crystals flare
                if (prevT <= 0.0001) {
                    this.charged = true;
                    this.flashMsg("THE WARDEN GATHERS POWER... DEFEND!");
                    api.sound(SFX_POWERUP, 0.5, 0.6);
                    for (let s = 0; s < 3; s++) {
                        this.sparkAt(s, this.eX[e], this.eY[e], this.eZ[e], 2, 0.1 * <f64>s);
                    }
                }
                if (t > 1.0) {
                    this.wardenCycle++;
                    this.nextEnemy(api);
                }
                return;
            }
            // wind up, lunge, strike, back
            let reach = k == K_WARDEN ? 0.3 : (k == K_BAT ? 0.62 : 0.55);
            this.eLunge[e] = t < 0.15 ? -0.1 * t / 0.15 : (t < 0.27 ? -0.1 + (reach + 0.1) * (t - 0.15) / 0.12 : (t < 0.55 ? reach * (1.0 - (t - 0.27) / 0.28) : 0.0));
            if (prevT < 0.15 && t >= 0.15) {
                if (k == K_BAT) {
                    api.soundAt(SFX_WHOOSH, this.eX[e], this.eY[e], this.eZ[e], 1.6, 0.4);
                } else if (k == K_SLIME) {
                    api.soundAt(SFX_JUMP, this.eX[e], this.eY[e], this.eZ[e], 0.7, 0.35);
                } else if (k == K_SHROOM) {
                    api.soundAt(SFX_JUMP, this.eX[e], this.eY[e], this.eZ[e], 0.55, 0.35);
                } else {
                    api.soundAt(SFX_WHOOSH, this.eX[e], this.eY[e], this.eZ[e], 0.6, 0.6);
                }
            }
            if (!this.actHit && t >= 0.27) {
                this.actHit = true;
                let miss = k != K_WARDEN && api.rand() < 0.1;
                if (miss) {
                    this.floatText(hx, hy + 1.05, hz, "MISS", P_SAGE);
                    api.soundAt(SFX_WHOOSH, hx, hy, hz, 1.9, 0.35);
                } else {
                    let dmg = 0;
                    if (k == K_SLIME) {
                        dmg = 1 + <i32>Math.floor(api.rand() * 3.0);
                    } else if (k == K_BAT) {
                        dmg = 1 + <i32>Math.floor(api.rand() * 4.0);
                    } else if (k == K_SHROOM) {
                        dmg = 2 + <i32>Math.floor(api.rand() * 4.0);
                    } else if (this.charged) {
                        dmg = 15 + <i32>Math.floor(api.rand() * 4.0);
                        this.shakeT = 0;
                        api.sound(SFX_EXPLODE, 0.6, 0.8);
                        this.charged = false;
                    } else {
                        dmg = 6 + <i32>Math.floor(api.rand() * 3.0);
                    }
                    this.hurtHero(api, dmg);
                }
            }
            if (t > dur) {
                if (k == K_WARDEN) {
                    this.wardenCycle++;
                }
                this.nextEnemy(api);
            }
            return;
        }
        if (this.phase == PH_WON) {
            if (prevT <= 0.0001) {
                // the spoils
                this.xp += this.wonXp;
                this.gold += this.wonGold;
                let boss = this.eKind[0] == K_WARDEN;
                this.levelUps = 0;
                while (this.xp >= this.xpFor(this.level)) {
                    this.level++;
                    this.levelUps++;
                }
                if (this.levelUps > 0) {
                    this.maxHp = this.hpFor(this.level);
                    this.maxMp = this.mpFor(this.level);
                    this.atk = this.atkFor(this.level);
                    this.hp = this.maxHp;
                    this.mp = this.maxMp;
                }
                if (!boss) {
                    // a short fanfare
                    api.note(67, 0.45, 0, SFX_NOTE);
                    api.note(72, 0.45, 0, SFX_NOTE, 0.1);
                    api.note(76, 0.45, 0, SFX_NOTE, 0.2);
                    api.note(79, 0.55, 0, SFX_NOTE, 0.3);
                    api.note(76, 0.4, 0, SFX_NOTE, 0.45);
                    api.note(79, 0.6, 0, SFX_NOTE, 0.55);
                }
            }
            if (this.levelUps > 0 && prevT < 0.9 && t >= 0.9) {
                this.levelUpT = 0;
                api.sound(SFX_POWERUP, 1.0, 0.7);
                api.note(72, 0.5, 0, SFX_BELL, 0.1);
                api.note(76, 0.5, 0, SFX_BELL, 0.22);
                api.note(79, 0.5, 0, SFX_BELL, 0.34);
                api.note(84, 0.6, 0, SFX_BELL, 0.46);
                for (let s = 0; s < NSPARK; s++) {
                    this.sparkAt(s, hx, hy, hz, 1, 0.08 * <f64>s);
                }
            }
            let endT = this.levelUps > 0 ? 2.6 : 1.7;
            if (t > endT) {
                if (this.eKind[0] == K_WARDEN) {
                    this.wardenDown = true;
                    this.state = ST_VICTORY;
                    this.stateT = 0;
                    this.score = this.computeScore();
                    if (this.score > this.best) {
                        this.best = this.score;
                    }
                    // the victory fanfare
                    api.sound(SFX_WIN, 1.0, 0.7);
                    let mel: StaticArray<f64> = [72, 72, 72, 76, 79, 77, 76, 74, 76, 84];
                    let at: StaticArray<f64> = [0.2, 0.32, 0.44, 0.62, 0.8, 1.0, 1.12, 1.24, 1.4, 1.62];
                    for (let n = 0; n < 10; n++) {
                        api.note(mel[n], 0.5, 0, n == 9 ? SFX_BELL : SFX_NOTE, at[n]);
                    }
                } else {
                    this.state = ST_MAP;
                    this.stateT = 0;
                    this.ne = 0;
                    this.dWait = api.range(0.3, 0.6);
                }
            }
            return;
        }
        if (this.phase == PH_LOST) {
            if (prevT <= 0.0001) {
                api.sound(SFX_LOSE, 0.9, 0.7);
                api.note(64, 0.5, 0, SFX_NOTE, 0.5);
                api.note(60, 0.5, 0, SFX_NOTE, 0.75);
                api.note(57, 0.55, 0, SFX_BELL, 1.0);
            }
            if (t > 1.6) {
                this.state = ST_OVER;
                this.stateT = 0;
                this.score = 0;
            }
        }
    }

    endHeroTurn(api: GameApi): void {
        this.heroLunge = 0;
        this.heroHop = 0;
        if (this.aliveCount() == 0) {
            this.winFight(api);
            return;
        }
        // the monsters' turn, one after another
        this.actor = -1;
        this.nextEnemy(api);
    }

    winFight(api: GameApi): void {
        this.phase = PH_WON;
        this.phaseT = 0;
        this.defending = false;
        if (this.eKind[0] == K_WARDEN) {
            this.flashMsg("THE WARDEN CRUMBLES!");
        } else {
            this.flashMsg("VICTORY!");
        }
    }

    nextEnemy(api: GameApi): void {
        let e = this.actor + 1;
        while (e < this.ne && !this.alive(e)) {
            e++;
        }
        if (this.hp <= 0) {
            this.phase = PH_LOST;
            this.phaseT = 0;
            this.flashMsg("THE HERO FALLS...");
            return;
        }
        if (e >= this.ne) {
            this.phase = PH_CHOOSE;
            this.phaseT = 0;
            this.dChoice = api.range(0.5, 0.9);
            this.fixTarget();
            return;
        }
        this.actor = e;
        this.actHit = false;
        this.phase = PH_ENEMY;
        this.phaseT = 0;
    }

    // ------------------------------------------------------------------ the demo player

    demoChoose(api: GameApi): void {
        let n = this.aliveCount();
        let boss = this.eKind[0] == K_WARDEN;
        let r = api.rand();
        // the weakest first, sometimes just any
        let best = -1, bh = 9999;
        for (let e = 0; e < this.ne; e++) {
            if (this.alive(e) && this.eHp[e] < bh) {
                bh = this.eHp[e];
                best = e;
            }
        }
        if (r < 0.2) {
            for (let e = this.ne - 1; e >= 0; e--) {
                if (this.alive(e)) {
                    best = e;
                    break;
                }
            }
        }
        if (best >= 0) {
            this.target = best;
        }
        let a = A_ATTACK;
        let low = this.hp * 100 < this.maxHp * (boss ? 40 : 30);
        if (low && this.potions > 0 && api.rand() < 0.85) {
            a = A_POTION;
        } else if (boss && this.charged && api.rand() < 0.8) {
            a = A_DEFEND;
        } else if (n >= 2 && this.mp >= MAGIC_COST && api.rand() < 0.8) {
            a = A_MAGIC;
        } else if (!boss && n == 1 && low && api.rand() < 0.3) {
            a = A_DEFEND;
        }
        this.choose(api, a);
    }

    demoMap(api: GameApi, dt: f64): void {
        if (this.walking) {
            return;
        }
        this.dWait -= dt;
        if (this.dWait > 0) {
            return;
        }
        this.dWait = api.range(0.25, 0.7);
        let i = this.hi, j = this.hj;
        // rest and shop at the inn when hurt
        let wantInn = this.hp * 100 < this.maxHp * 45 || (this.gold >= POTION_COST && this.potions < 2 && this.hp * 100 < this.maxHp * 75);
        if (i == INN_I && j == INN_J) {
            if (this.gold >= POTION_COST && this.potions < 2) {
                this.buyPotion(api);
                this.dWait = 0.45;
                return;
            }
            wantInn = false;
        }
        if (wantInn) {
            this.walkTo(api, INN_I, INN_J);
            return;
        }
        // strong enough (or impatient): stock up if the purse allows, then the shrine
        let ready = this.level >= this.dGoalLevel && (this.level >= 3 || this.potions >= 1);
        if (ready && this.dGoalLevel >= 3 && this.gold >= POTION_COST && this.potions < 2) {
            this.walkTo(api, INN_I, INN_J);
            return;
        }
        if (ready) {
            this.walkTo(api, SHRINE_I, SHRINE_J);
            return;
        }
        // drink on the road when low and far from the inn
        if (this.hp * 100 < this.maxHp * 30 && this.potions > 0) {
            this.drink(api);
            return;
        }
        // look for trouble: a wild tile a few hops away, drifting towards the shrine (with detours)
        this.flood(i, j);
        let towards = api.rand() < 0.6;
        let bi = -1, bj = -1;
        let bs = -1e9;
        for (let tj = 0; tj < D; tj++) {
            for (let ti = 0; ti < W; ti++) {
                let d = this.dist[tj * W + ti];
                if (d < 2 || d > 5 || !wild(ti, tj)) {
                    continue;
                }
                // no climbing to the shrine's doorstep by accident
                if (iabs(ti - SHRINE_I) + iabs(tj - SHRINE_J) <= 1) {
                    continue;
                }
                // level 1 grinds the east meadows, level 2 the west lowlands; the hill only on the way up
                let east = ti > 6;
                let zone = this.level <= 1 ? (east ? 0.0 : -3.0) : (east ? -1.5 : 0.0);
                if (levelAt(ti, tj) >= 2) {
                    zone -= 4.0;
                }
                let toShrine = <f64>(iabs(ti - SHRINE_I) + iabs(tj - SHRINE_J));
                let s = api.rand() * 3.0 + zone - (towards ? toShrine * 0.25 : 0.0) - <f64>d * 0.2;
                if (s > bs) {
                    bs = s;
                    bi = ti;
                    bj = tj;
                }
            }
        }
        if (bi >= 0) {
            this.walkTo(api, bi, bj);
        }
    }

    buyPotion(api: GameApi): void {
        if (this.gold < POTION_COST) {
            api.sound(SFX_CLICK, 0.6, 0.5);
            this.say("NOT ENOUGH GOLD");
            return;
        }
        this.gold -= POTION_COST;
        this.potions++;
        this.potionT = 0;
        api.sound(SFX_COIN, 1.0, 0.55);
        api.note(79, 0.35, 0, SFX_NOTE, 0.12);
        this.say("BOUGHT A POTION");
    }

    drink(api: GameApi): void {
        if (this.potions <= 0 || this.hp >= this.maxHp) {
            api.sound(SFX_CLICK, 0.6, 0.5);
            return;
        }
        this.potions--;
        let before = this.hp;
        this.hp = min<i32>(this.maxHp, this.hp + POTION_HEAL);
        this.potionT = 0;
        let x = tileX(this.hi), y = levelY(levelAt(this.hi, this.hj)), z = tileZ(this.hj);
        this.floatText(x, y + 1.05, z, "+" + (this.hp - before).toString(), P_LEAF);
        api.sound(SFX_POP, 0.9, 0.6);
        api.note(72, 0.4, 0, SFX_NOTE, 0.1);
        api.note(76, 0.4, 0, SFX_NOTE, 0.18);
        api.note(79, 0.45, 0, SFX_NOTE, 0.26);
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged || api.demo != this.wasDemo) {
            // the host switched demo on or off: a fresh run (a visitor gets the hint first)
            this.wasDemo = api.demo;
            this.newRun(api);
            this.state = api.demo ? ST_MAP : ST_TITLE;
            this.clearEffects();
        }
        this.stateT += dt;
        let st = this.state;
        if (st == ST_MAP) {
            this.updateWalk(api, dt);
            if (api.demo) {
                this.demoMap(api, dt);
            }
        } else if (st == ST_FIGHT) {
            this.updateFight(api, dt);
        } else if (st == ST_VICTORY || st == ST_OVER) {
            if (api.demo && this.stateT > (st == ST_VICTORY ? 3.5 : 2.2)) {
                this.newRun(api);
                this.clearEffects();
            }
        }
        this.updateEffects(api, dt);
        this.updateCamera(api, dt);
        this.pose(api);
    }

    clearEffects(): void {
        for (let k = 0; k < NFT; k++) this.ftT[k] = -1;
        for (let k = 0; k < NPUFF; k++) this.puffT[k] = -1;
        for (let k = 0; k < NSPARK; k++) this.sparkT[k] = -9;
        for (let k = 0; k < NCOIN; k++) this.coinT[k] = -9;
        for (let k = 0; k < NDUST; k++) this.dustT[k] = -1;
        this.potionT = -1;
        this.slashT = -1;
        this.levelUpT = -1;
        this.shakeT = -1;
        this.bangT = -1;
        this.backT = -1;
    }

    updateWalk(api: GameApi, dt: f64): void {
        if (!this.walking) {
            return;
        }
        this.walkT += dt / STEP_T;
        if (this.walkT >= 1.0) {
            this.hi = this.pathI[this.pathPos];
            this.hj = this.pathJ[this.pathPos];
            this.pathPos++;
            let done = this.pathPos >= this.pathLen;
            this.walking = false;
            this.arrive(api, false);
            if (this.state != ST_MAP || this.walking) {
                return;
            }
            if (!done && this.pathLen > 0) {
                this.beginStep(api);
            } else {
                this.stopWalk();
            }
        }
    }

    updateEffects(api: GameApi, dt: f64): void {
        for (let k = 0; k < NFT; k++) {
            if (this.ftT[k] >= 0) {
                this.ftT[k] += dt;
                if (this.ftT[k] > 1.0) this.ftT[k] = -1;
            }
        }
        for (let k = 0; k < NPUFF; k++) {
            if (this.puffT[k] >= 0) {
                this.puffT[k] += dt;
                if (this.puffT[k] > 0.45) this.puffT[k] = -1;
            }
        }
        for (let k = 0; k < NSPARK; k++) {
            if (this.sparkT[k] > -9) {
                this.sparkT[k] += dt;
                let life = this.sparkMode[k] == 0 ? 0.55 : (this.sparkMode[k] == 1 ? 1.3 : 2.4);
                if (this.sparkMode[k] == 2 && !this.charged && this.sparkT[k] > 0.6) {
                    this.sparkT[k] = -9;
                } else if (this.sparkT[k] > life && !(this.sparkMode[k] == 2 && this.charged)) {
                    this.sparkT[k] = -9;
                }
            }
        }
        for (let k = 0; k < NCOIN; k++) {
            if (this.coinT[k] > -9) {
                let c0 = this.coinT[k];
                this.coinT[k] += dt;
                if (c0 < 0.55 && this.coinT[k] >= 0.55) {
                    api.sound(SFX_COIN, 1.0 + 0.06 * <f64>k, 0.4);
                }
                if (this.coinT[k] > 0.6) this.coinT[k] = -9;
            }
        }
        for (let k = 0; k < NDUST; k++) {
            if (this.dustT[k] >= 0) {
                this.dustT[k] += dt;
                if (this.dustT[k] > 0.35) this.dustT[k] = -1;
            }
        }
        if (this.potionT >= 0) {
            this.potionT += dt;
            if (this.potionT > 0.85) this.potionT = -1;
        }
        if (this.slashT >= 0) {
            this.slashT += dt;
            if (this.slashT > 0.2) this.slashT = -1;
        }
        if (this.levelUpT >= 0) {
            this.levelUpT += dt;
            if (this.levelUpT > 1.6) this.levelUpT = -1;
        }
        if (this.hurtT >= 0) {
            this.hurtT += dt;
            if (this.hurtT > 0.4) this.hurtT = -1;
        }
        if (this.innT >= 0) {
            this.innT += dt;
            if (this.innT > 1.2) this.innT = -1;
        }
        if (this.noteT >= 0) {
            this.noteT += dt;
            if (this.noteT > 2.2) this.noteT = -1;
        }
        if (this.fightMsgT >= 0) {
            this.fightMsgT += dt;
            if (this.fightMsgT > 2.0) this.fightMsgT = -1;
        }
        if (this.backT >= 0) {
            let b0 = this.backT;
            this.backT += dt;
            if (b0 < 0.4 && this.backT >= 0.4) {
                this.landT = 0;
                api.sound(SFX_THUD, 1.1, 0.4);
            }
            if (this.backT > 0.45) this.backT = -1;
        }
        if (this.bangT >= 0) {
            this.bangT += dt;
            if (this.bangT > 0.6) this.bangT = -1;
        }
        if (this.pressedT >= 0) {
            this.pressedT += dt;
            if (this.pressedT > 0.2) this.pressedT = -1;
        }
        if (this.shakeT >= 0) {
            this.shakeT += dt;
            if (this.shakeT > 0.35) this.shakeT = -1;
        }
        // monsters: flashes, defeats (squash, puff, coins)
        if (this.state == ST_FIGHT) {
            for (let e = 0; e < this.ne; e++) {
                if (this.eFlash[e] >= 0) {
                    this.eFlash[e] += dt;
                    if (this.eFlash[e] > 0.32) this.eFlash[e] = -1;
                }
                if (this.eDead[e] >= 0) {
                    let d0 = this.eDead[e];
                    this.eDead[e] += dt;
                    let at = this.eKind[e] == K_WARDEN ? 0.5 : 0.28;
                    if (d0 < at && this.eDead[e] >= at) {
                        let s = this.eKind[e] == K_WARDEN ? 1.6 : 1.0;
                        this.puffAt(this.eX[e], this.eY[e] + 0.25 * s, this.eZ[e], s);
                        api.soundAt(this.eKind[e] == K_WARDEN ? SFX_EXPLODE : SFX_POP, this.eX[e], this.eY[e], this.eZ[e], 0.8, 0.6);
                        if (this.eKind[e] == K_WARDEN) {
                            this.puffAt(this.eX[e] - 0.3, this.eY[e] + 0.9, this.eZ[e] + 0.2, 1.2);
                            this.puffAt(this.eX[e] + 0.3, this.eY[e] + 1.4, this.eZ[e] - 0.1, 1.1);
                        }
                        // coins fly to the hero
                        let nc = this.eKind[e] == K_WARDEN ? 4 : (this.eKind[e] == K_SHROOM ? 2 : 1);
                        let c = 0;
                        for (let k = 0; k < NCOIN && c < nc; k++) {
                            if (this.coinT[k] <= -9) {
                                this.coinT[k] = -0.12 * <f64>c;
                                this.coinX[k] = this.eX[e];
                                this.coinY[k] = this.eY[e] + 0.3;
                                this.coinZ[k] = this.eZ[e];
                                c++;
                            }
                        }
                    }
                }
            }
        }
    }

    updateCamera(api: GameApi, dt: f64): void {
        // the goal: the hero on the map (a little ahead of a walk); the middle of the fight in a fight
        let gx = 0.0, gy = 0.0, gz = 0.0, gh = MAP_H;
        let hx = this.heroPX, hy = this.heroPY, hz = this.heroPZ;
        if (this.state == ST_FIGHT || (this.state == ST_VICTORY && this.stateT < 1.5)) {
            let cx = hx, cy = hy, cz = hz, n = 1.0;
            for (let e = 0; e < this.ne; e++) {
                cx += this.eX[e];
                cy += this.eY[e] + (this.eKind[e] == K_WARDEN ? 0.6 : 0.0);
                cz += this.eZ[e];
                n += 1.0;
            }
            gx = cx / n;
            gy = cy / n + 0.35;
            gz = cz / n;
            gh = FIGHT_H;
            let lift = 0.03;
            if (this.ne > 0 && this.eKind[0] == K_WARDEN) {
                // the span from the hero's feet to the Warden's crystals
                gh = FIGHT_H + 1.1;
                gy = (hy + this.eY[0] + 2.0) * 0.5;
                lift = 0.06;
            }
            // lift the fight above the buttons: the target slides down the screen
            let up = lift * gh;
            gx -= <f64>api.camUX * up;
            gy -= <f64>api.camUY * up;
            gz -= <f64>api.camUZ * up;
        } else {
            gx = hx;
            gy = hy + 0.3;
            gz = hz;
        }
        let k = 1.0 - Math.exp(-dt * 4.5);
        this.camX += (gx - this.camX) * k;
        this.camY += (gy - this.camY) * k;
        this.camZ += (gz - this.camZ) * k;
        this.camH += (gh - this.camH) * k;
        api.useTarget = true;
        api.targetX = this.camX;
        api.targetY = this.camY;
        api.targetZ = this.camZ;
        api.orthoHeight = this.camH;
        // the Warden's slam shakes the view by whole art pixels
        if (this.shakeT >= 0) {
            let texel = this.camH / 136.0;
            let s = Math.floor(this.shakeT * 30.0) % 2 == 0 ? 2.0 : -2.0;
            api.targetX += s * texel * <f64>api.camRX;
            api.targetZ += s * texel * <f64>api.camRZ;
        }
    }

    // ------------------------------------------------------------------ posing the bones

    heroPX: f64 = 0;
    heroPY: f64 = 0;
    heroPZ: f64 = 0;

    // a grove squashes down while it stands between the camera and the hero (or a monster in a fight),
    // so nobody is lost behind the trees; it grows back once they have passed
    poseGroves(api: GameApi): void {
        let dt = api.dt;
        for (let g = 0; g < this.ngrove; g++) {
            let b = this.groveB[g];
            let gx = <f64>api.restX[b], gy = <f64>api.restY[b], gz = <f64>api.restZ[b];
            let want = 1.0;
            for (let p = -1; p < this.ne; p++) {
                let px = 0.0, py = 0.0, pz = 0.0;
                if (p < 0) {
                    px = this.heroPX;
                    py = this.heroPY;
                    pz = this.heroPZ;
                } else {
                    if (this.state != ST_FIGHT || !this.alive(p)) continue;
                    px = this.eX[p];
                    py = this.eY[p];
                    pz = this.eZ[p];
                }
                let dx = gx - px, dz = gz - pz;
                let fwd = (dx + dz) * 0.7071;          // towards the camera (it looks from +x +z)
                let lat = Math.abs(dx - dz) * 0.7071;  // across the screen
                if (fwd > 0.25 && fwd < 2.6 && lat < 1.0 && gy + 1.0 > py + 0.2 + 0.577 * fwd) {
                    want = 0.3;
                }
            }
            let s = this.groveS[g];
            s += (want - s) * Math.min(1.0, dt * 9.0);
            this.groveS[g] = s;
            // stepped, so the trees settle in whole poses
            let q = Math.round(s * 8.0) / 8.0;
            api.placeScaled(b, gx, gy, gz, 0, 1.0 + (1.0 - q) * 0.15, q, 1.0 + (1.0 - q) * 0.15);
        }
    }

    pose(api: GameApi): void {
        let t = api.time;
        // ---- the hero
        let x = tileX(this.hi), z = tileZ(this.hj);
        let y = levelY(levelAt(this.hi, this.hj));
        let sx = 1.0, sy = 1.0;
        let yaw = this.heroYaw;
        let roll = 0.0;
        if (this.state == ST_MAP && this.walking) {
            // a hop along the step, stepped at 20 fps
            let u = Math.floor(this.walkT * STEP_T * 20.0) / (STEP_T * 20.0);
            u = Math.min(1.0, u);
            let ni = this.pathI[this.pathPos], nj = this.pathJ[this.pathPos];
            let y0 = levelY(levelAt(this.hi, this.hj)), y1 = levelY(levelAt(ni, nj));
            x = tileX(this.hi) + (tileX(ni) - tileX(this.hi)) * u;
            z = tileZ(this.hj) + (tileZ(nj) - tileZ(this.hj)) * u;
            y = y0 + (y1 - y0) * u + (HOP + 0.5 * Math.abs(y1 - y0)) * 4.0 * u * (1.0 - u);
            sy = u < 0.2 ? 1.08 : 1.0;
            sx = u < 0.2 ? 0.94 : 1.0;
        } else {
            // idle: a slow breath, stepped
            let b = Math.floor(t * 4.0);
            sy = 1.0 + (b % 2 == 0 ? 0.0 : 0.025);
        }
        if (this.backT >= 0) {
            let u = Math.min(1.0, Math.floor(this.backT * 20.0) / 20.0 / 0.4);
            let y0 = levelY(levelAt(this.backI, this.backJ));
            x = tileX(this.backI) + (x - tileX(this.backI)) * u;
            z = tileZ(this.backJ) + (z - tileZ(this.backJ)) * u;
            y = y0 + (y - y0) * u + 0.3 * 4.0 * u * (1.0 - u);
        }
        if (this.landT < 0.1) {
            sy = 0.86;
            sx = 1.1;
        }
        this.landT += api.dt;
        if (this.state == ST_FIGHT || this.state == ST_VICTORY || this.state == ST_OVER) {
            // lunges towards the target, hops for magic
            if (this.ne > 0 && this.target >= 0 && this.target < this.ne && this.heroLunge != 0) {
                let dx = this.eX[this.target] - x, dz = this.eZ[this.target] - z;
                let dy = this.eY[this.target] - y;
                x += dx * this.heroLunge;
                z += dz * this.heroLunge;
                y += dy * Math.max(0.0, this.heroLunge) + Math.max(0.0, this.heroLunge) * 0.15;
            }
            y += this.heroHop;
            if (this.state == ST_FIGHT && this.phase == PH_WON && this.levelUps > 0 && this.phaseT > 0.9 && this.phaseT < 1.5) {
                // a happy jump for the level up
                let u = (this.phaseT - 0.9) / 0.3;
                y += u < 1.0 ? Math.sin(u * Math.PI) * 0.35 : 0.0;
            }
        }
        let lost = (this.state == ST_FIGHT && this.phase == PH_LOST) || this.state == ST_OVER;
        if (lost) {
            let u = this.state == ST_OVER ? 1.0 : Math.min(1.0, Math.floor(this.phaseT * 12.0) / 6.0);
            roll = -80.0 * u;
            y += 0.1 * u;
        }
        this.heroPX = x;
        this.heroPY = y;
        this.heroPZ = z;
        let blink = this.hurtT >= 0 && Math.floor(this.hurtT * 20.0) % 2 == 0;
        if (blink) {
            api.hide(this.hero);
        } else if (roll != 0) {
            api.placeScaled(this.hero, x, y, z, yaw, 1, 1, 1, 0, roll);
        } else {
            api.placeScaled(this.hero, x, y, z, yaw, sx, sy, sx);
        }

        // ---- the monsters
        for (let k = 0; k < 3; k++) {
            this.markUsed(k, false);
        }
        let wardenPlaced = false;
        if (this.state == ST_FIGHT || this.state == ST_VICTORY) {
            for (let e = 0; e < this.ne; e++) {
                this.poseEnemy(api, e, t);
                if (this.eKind[e] == K_WARDEN) {
                    wardenPlaced = true;
                }
            }
        }
        this.hideUnused(api);
        if (!wardenPlaced) {
            if (this.wardenDown) {
                api.hide(this.warden);
            } else {
                // the Warden waits on its shrine, breathing slowly, facing the island
                let b = Math.floor(t * 2.0) % 2 == 0 ? 1.0 : 1.02;
                api.placeScaled(this.warden, tileX(SHRINE_I), levelY(4), tileZ(SHRINE_J), 45, 1, b, 1);
            }
        }

        this.poseGroves(api);

        // ---- the walk marker and the pin
        let showMarker = false;
        if (this.state == ST_MAP && this.walking && this.goalI >= 0) {
            let gy = levelY(levelAt(this.goalI, this.goalJ));
            api.place(this.marker, tileX(this.goalI), gy + 0.01, tileZ(this.goalJ), 0);
            let bob = Math.floor(t * 6.0) % 3 == 0 ? 0.0 : (Math.floor(t * 6.0) % 3 == 1 ? 0.06 : 0.1);
            api.place(this.pin, tileX(this.goalI), gy + 0.75 + bob, tileZ(this.goalJ), t * 120.0);
            showMarker = true;
        } else if (this.state == ST_FIGHT && (this.phase == PH_CHOOSE || this.phase == PH_HERO) && this.ne > 0) {
            let e = this.target;
            if (e >= 0 && e < this.ne && this.alive(e)) {
                api.place(this.marker, this.eX[e], this.eY[e] + 0.01, this.eZ[e], 0);
                api.hide(this.pin);
                showMarker = true;
            }
        }
        if (!showMarker) {
            api.hide(this.marker);
            api.hide(this.pin);
        }

        // ---- effects
        for (let k = 0; k < NPUFF; k++) {
            let pt = this.puffT[k];
            if (pt < 0) {
                api.hide(this.puffB[k]);
                continue;
            }
            let u = Math.floor(pt * 15.0) / 15.0 / 0.45;
            let s = (u < 0.3 ? 0.5 + u / 0.3 * 0.6 : 1.1 - (u - 0.3) / 0.7 * 0.8) * this.puffS[k];
            api.place(this.puffB[k], this.puffX[k], this.puffY[k] + u * 0.25, this.puffZ[k], u * 90.0, 0, 0, Math.max(0.05, s));
        }
        for (let k = 0; k < NSPARK; k++) {
            let st = this.sparkT[k];
            if (st < 0) {
                api.hide(this.sparkB[k]);
                continue;
            }
            let q = Math.floor(st * 15.0) / 15.0;
            let m = this.sparkMode[k];
            if (m == 0) {
                let s = q < 0.15 ? 0.4 + q / 0.15 * 0.8 : Math.max(0.1, 1.2 - (q - 0.15) / 0.4);
                api.place(this.sparkB[k], this.sparkX[k], this.sparkY[k] + q * 0.3, this.sparkZ[k], q * 400.0, 20, 0, s);
            } else if (m == 1) {
                // the level up: sparks rise round the hero
                let a = q * 4.0 + <f64>k * 1.047;
                let r = 0.45;
                api.place(this.sparkB[k], this.heroPX + Math.cos(a) * r, this.heroPY + 0.1 + q * 0.9, this.heroPZ + Math.sin(a) * r,
                          q * 300.0, 0, 0, Math.max(0.15, 0.8 - q * 0.45));
            } else {
                // the Warden gathering power: sparks circle its head
                let a = q * 3.0 + <f64>k * 2.094;
                api.place(this.sparkB[k], tileX(SHRINE_I) + Math.cos(a) * 0.6, levelY(4) + 1.5 + Math.sin(q * 5.0) * 0.1,
                          tileZ(SHRINE_J) + Math.sin(a) * 0.6, q * 200.0, 0, 0, 0.7);
            }
        }
        for (let k = 0; k < NCOIN; k++) {
            let ct = this.coinT[k];
            if (ct < 0) {
                api.hide(this.coinB[k]);
                continue;
            }
            let u = Math.min(1.0, Math.floor(ct * 15.0) / 15.0 / 0.55);
            let cx = this.coinX[k] + (this.heroPX - this.coinX[k]) * u;
            let cz = this.coinZ[k] + (this.heroPZ - this.coinZ[k]) * u;
            let cy = this.coinY[k] + (this.heroPY + 0.6 - this.coinY[k]) * u + Math.sin(u * Math.PI) * 0.6;
            api.place(this.coinB[k], cx, cy, cz, ct * 720.0);
        }
        for (let k = 0; k < NDUST; k++) {
            let dtt = this.dustT[k];
            if (dtt < 0) {
                api.hide(this.dustB[k]);
                continue;
            }
            let u = Math.floor(dtt * 15.0) / 15.0 / 0.35;
            api.place(this.dustB[k], this.dustX[k], this.dustY[k] + u * 0.08, this.dustZ[k], 0, 0, 0, Math.max(0.1, 1.0 - u * 0.7));
        }
        if (this.potionT >= 0) {
            let u = Math.floor(this.potionT * 15.0) / 15.0;
            api.place(this.potionB, this.heroPX, this.heroPY + 1.0 + Math.min(u, 0.3) * 0.5, this.heroPZ, 45, 0, u > 0.35 ? -60 : 0, 1.0);
        } else {
            api.hide(this.potionB);
        }
        if (this.slashT >= 0) {
            let u = Math.floor(this.slashT * 30.0) / 30.0 / 0.2;
            api.place(this.slashB, this.slashX, this.slashY, this.slashZ, 45, 0, 50.0 - 110.0 * u, 1.3);
        } else {
            api.hide(this.slashB);
        }
        if (this.state == ST_FIGHT && this.defending) {
            let a = this.heroYaw * Math.PI / 180.0;
            let p = Math.floor(t * 6.0) % 2 == 0 ? 1.0 : 1.08;
            api.place(this.guardB, this.heroPX + Math.sin(a) * 0.38, this.heroPY + 0.45, this.heroPZ + Math.cos(a) * 0.38, this.heroYaw, 0, 0, p);
        } else {
            api.hide(this.guardB);
        }
    }

    usedS: i32 = 0;
    usedB: i32 = 0;
    usedM: i32 = 0;

    markUsed(k: i32, v: bool): void {
        if (k == 0) {
            this.usedS = 0;
            this.usedB = 0;
            this.usedM = 0;
        }
    }

    hideUnused(api: GameApi): void {
        for (let k = this.usedS; k < 3; k++) api.hide(this.slimeB[k]);
        for (let k = this.usedB; k < 3; k++) api.hide(this.batB[k]);
        for (let k = this.usedM; k < 3; k++) api.hide(this.shroomB[k]);
    }

    poseEnemy(api: GameApi, e: i32, t: f64): void {
        let k = this.eKind[e];
        let b = this.eBone[e];
        if (k == K_SLIME) this.usedS++;
        else if (k == K_BAT) this.usedB++;
        else if (k == K_SHROOM) this.usedM++;
        // keep the pool counters right: bones are handed out in order per kind
        let x = this.eX[e], y = this.eY[e], z = this.eZ[e];
        let hx = tileX(this.hi), hz = tileZ(this.hj), hy = levelY(levelAt(this.hi, this.hj));
        // face the hero, turned partly towards the camera (which looks from yaw 45) so faces and wings read
        let yaw = Math.atan2(hx - x, hz - z) * 180.0 / Math.PI;
        let dy = 45.0 - yaw;
        while (dy > 180.0) dy -= 360.0;
        while (dy < -180.0) dy += 360.0;
        yaw += dy * (k == K_BAT ? 0.75 : 0.45);
        yaw = Math.round(yaw / 15.0) * 15.0;
        if (k == K_WARDEN) {
            yaw = Math.round(yaw / 45.0) * 45.0;
        }
        let pop = this.ePop[e];
        if (pop < 0) {
            api.hide(b);
            return;
        }
        let dead = this.eDead[e];
        let deadEnd = k == K_WARDEN ? 0.5 : 0.28;
        if (dead >= deadEnd || (this.state == ST_VICTORY && k == K_WARDEN)) {
            api.hide(b);
            return;
        }
        // lunge towards the hero
        let L = this.eLunge[e];
        x += (hx - x) * L;
        z += (hz - z) * L;
        y += (hy - y) * Math.max(0.0, L);
        let sx = 1.0, sy = 1.0, roll = 0.0;
        let ph = this.ePhase[e];
        let q = Math.floor(t * 8.0) / 8.0;
        if (k == K_SLIME) {
            let w = Math.sin(q * 5.0 + ph);
            sy = 1.0 + 0.09 * w;
            sx = 1.0 - 0.06 * w;
            if (L > 0.05) {
                y += Math.sin(Math.min(1.0, L / 0.55) * Math.PI) * 0.25;
                sy = 1.15;
                sx = 0.9;
            }
        } else if (k == K_BAT) {
            y += 0.06 * Math.sin(q * 3.0 + ph) - 0.08;
            sx = Math.floor(t * 9.0 + ph) % 2 == 0 ? 1.0 : 0.7;    // wing beats
        } else if (k == K_SHROOM) {
            roll = Math.floor(t * 3.0 + ph) % 2 == 0 ? 6.0 : -6.0;
            if (L > 0.05) {
                y += Math.sin(Math.min(1.0, L / 0.55) * Math.PI) * 0.3;
            }
        } else {
            sy = Math.floor(t * 2.0) % 2 == 0 ? 1.0 : 1.02;
            if (this.charged) {
                x += (Math.floor(t * 24.0) % 2 == 0 ? 0.03 : -0.03);
            }
        }
        // popping up: grow with an overshoot
        if (pop < 0.3) {
            let u = Math.floor(pop * 20.0) / 20.0 / 0.3;
            let s = u < 0.7 ? 0.3 + u / 0.7 * 0.85 : 1.15 - (u - 0.7) / 0.3 * 0.15;
            sx *= s;
            sy *= s;
        }
        // hit: squash
        let fl = this.eFlash[e];
        if (fl >= 0 && fl < 0.2) {
            sy *= 0.72;
            sx *= 1.22;
        }
        // defeated: flatten, then gone in the puff
        if (dead >= 0) {
            let u = Math.min(1.0, dead / deadEnd);
            sy *= Math.max(0.15, 1.0 - u * 0.85);
            sx *= 1.0 + u * 0.4;
        }
        // the flash: blinks out for a few frames
        if (fl >= 0 && Math.floor(fl * 20.0) % 2 == 1) {
            api.hide(b);
            return;
        }
        if (roll != 0) {
            api.placeScaled(b, x, y, z, yaw, sx, sy, sx, 0, roll);
        } else {
            api.placeScaled(b, x, y, z, yaw, sx, sy, sx);
        }
    }

    // ------------------------------------------------------------------ pointer

    // the tile under a HUD point: test the levels from the top down, so a hill hides what is behind it
    pickTile(api: GameApi, x: f32, y: f32): bool {
        for (let lv = 4; lv >= 0; lv--) {
            if (!api.pick(x, y, <f32>levelY(lv))) {
                continue;
            }
            let i = <i32>Math.floor(<f64>api.hitX + 6.5);
            let j = <i32>Math.floor(<f64>api.hitZ + 5.0);
            if (i >= 0 && j >= 0 && i < W && j < D && levelAt(i, j) == lv) {
                this.hoverI = i;
                this.hoverJ = j;
                // a fingertip off by a little: a tap at the edge of the water or a house takes the
                // walkable tile next to it (the shrine stays clickable: it means "go to the Warden")
                if (!walkable(i, j) && cellAt(i, j) != 83) {
                    this.snapWalkable(<f64>api.hitX, <f64>api.hitZ);
                }
                return true;
            }
        }
        // the river and the bridge (water level)
        if (api.pick(x, y, 0.12)) {
            let i = <i32>Math.floor(<f64>api.hitX + 6.5);
            let j = <i32>Math.floor(<f64>api.hitZ + 5.0);
            if (i >= 0 && j >= 0 && i < W && j < D && (cellAt(i, j) == 61)) {
                this.hoverI = i;
                this.hoverJ = j;
                return true;
            }
        }
        this.hoverI = -1;
        this.hoverJ = -1;
        // water: the nearest walkable tile within half a tile of the tap
        if (api.pick(x, y, 0.12)) {
            return this.snapWalkable(<f64>api.hitX, <f64>api.hitZ);
        }
        return false;
    }

    snapWalkable(hx: f64, hz: f64): bool {
        let bi = -1, bj = -1;
        let bd = 0.55 * 0.55 + 0.5;
        for (let j = 0; j < D; j++) {
            for (let i = 0; i < W; i++) {
                if (!walkable(i, j)) continue;
                let dx = Math.max(0.0, Math.abs(hx - tileX(i)) - 0.5), dz = Math.max(0.0, Math.abs(hz - tileZ(j)) - 0.5);
                let d = dx * dx + dz * dz + 0.5;
                if (dx * dx + dz * dz < 0.3 * 0.3 && d < bd) {
                    bd = d;
                    bi = i;
                    bj = j;
                }
            }
        }
        if (bi >= 0) {
            this.hoverI = bi;
            this.hoverJ = bj;
            return true;
        }
        return false;
    }

    // HUD button rectangles
    btnX(k: i32): f32 { return <f32>(1 + k * 53); }
    btnY(api: GameApi): f32 { return <f32>(api.hudH - 21); }
    mapBtnPotion(api: GameApi, x: f32, y: f32): bool {
        return x >= <f32>(api.hudW - 42) && x < <f32>(api.hudW) && y >= 11 && y < 27;
    }
    shopBtn(api: GameApi, x: f32, y: f32): bool {
        let bx = <f32>Math.floor(<f64>(api.hudW - 90) * 0.5);
        let by = <f32>(api.hudH - 36);
        return x >= bx - 2 && x < bx + 92 && y >= by - 2 && y < by + 17;
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        let st = this.state;
        if (kind == POINTER_MOVE) {
            // a mouse shows the tile under it; a finger aims while it drags (nothing needs a hover)
            if (st == ST_MAP || st == ST_TITLE) {
                this.pickTile(api, x, y);
            }
            return true;
        }
        if (kind == POINTER_UP) {
            // the walk starts on release, on the tile last aimed at
            if (this.mapPress && this.state == ST_MAP) {
                this.mapPress = false;
                if (this.pickTile(api, x, y) && this.walkTo(api, this.hoverI, this.hoverJ)) {
                    api.sound(SFX_BLIP, 1.2, 0.35);
                } else {
                    api.sound(SFX_CLICK, 0.6, 0.4);
                }
            }
            this.mapPress = false;
            return true;
        }
        if (kind != POINTER_DOWN) {
            return true;
        }
        if (st == ST_TITLE) {
            this.state = ST_MAP;
            this.stateT = 0;
            api.sound(SFX_WIN, 1.0, 0.5);
            st = ST_MAP;
        }
        if (st == ST_VICTORY || st == ST_OVER) {
            if (this.stateT > 0.8) {
                this.newRun(api);
                this.clearEffects();
                api.sound(SFX_WIN, 1.0, 0.5);
            }
            return true;
        }
        if (st == ST_MAP) {
            if (this.mapBtnPotion(api, x, y)) {
                this.drink(api);
                return true;
            }
            if (!this.walking && this.hi == INN_I && this.hj == INN_J && this.shopBtn(api, x, y)) {
                this.buyPotion(api);
                return true;
            }
            this.pickTile(api, x, y);
            this.mapPress = true;
            return true;
        }
        if (st == ST_FIGHT) {
            if (this.phase != PH_CHOOSE) {
                return true;
            }
            let by = this.btnY(api);
            if (y >= by && y < by + 19) {
                for (let k = 0; k < 4; k++) {
                    let bx = this.btnX(k);
                    if (x >= bx && x < bx + 51) {
                        this.choose(api, k);
                        return true;
                    }
                }
                return true;
            }
            // a monster: target it
            let best = -1;
            let bd: f32 = 16 * 16;
            for (let e = 0; e < this.ne; e++) {
                if (!this.alive(e)) continue;
                if (api.project(<f32>this.eX[e], <f32>(this.eY[e] + this.enemyTop(e) * 0.5), <f32>this.eZ[e])) {
                    let dx = api.screenX - x, dy = api.screenY - y;
                    let d = dx * dx + dy * dy;
                    if (d < bd) {
                        bd = d;
                        best = e;
                    }
                }
            }
            if (best >= 0) {
                if (best != this.target) {
                    api.sound(SFX_TICK, 1.5, 0.5);
                }
                this.target = best;
            }
            return true;
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    bar(api: GameApi, x: f32, y: f32, w: f32, v: i32, m: i32, full: u32, back: u32): void {
        api.rect(x, y, w, 3, back);
        let f = m > 0 ? Mathf.round(w * <f32>v / <f32>m) : 0;
        if (v > 0 && f < 1) f = 1;
        api.rect(x, y, f, 3, full);
    }

    hud(api: GameApi): void {
        let ink = api.paletteColor(P_INK);
        let navy = api.paletteColor(P_NAVY);
        let cream = api.paletteColor(P_CREAM);
        let gold = api.paletteColor(P_GOLD);
        let teal = api.paletteColor(P_TEAL);
        let rose = api.paletteColor(P_ROSE);
        let red = api.paletteColor(P_RED);
        let sky = api.paletteColor(P_SKY);
        let sea = api.paletteColor(P_SEA);
        let slate = api.paletteColor(P_SLATE);
        let grey = api.paletteColor(P_GREY);
        let leaf = api.paletteColor(P_LEAF);
        let plum = api.paletteColor(P_PLUM);
        let w = <f32>api.hudW, h = <f32>api.hudH;
        let st = this.state;

        // the hovered tile: a diamond outline (map, play only)
        if ((st == ST_MAP || st == ST_TITLE) && !api.demo && this.hoverI >= 0) {
            let y = <f32>levelY(levelAt(this.hoverI, this.hoverJ));
            let cx = <f32>tileX(this.hoverI), cz = <f32>tileZ(this.hoverJ);
            let ok = walkable(this.hoverI, this.hoverJ);
            let col = ok ? cream : grey;
            api.project(cx - 0.5, y, cz - 0.5);
            let ax = api.screenX, ay = api.screenY;
            api.project(cx + 0.5, y, cz - 0.5);
            let bx = api.screenX, by = api.screenY;
            api.project(cx + 0.5, y, cz + 0.5);
            let qx = api.screenX, qy = api.screenY;
            api.project(cx - 0.5, y, cz + 0.5);
            let dx = api.screenX, dy = api.screenY;
            api.line(ax, ay, bx, by, col);
            api.line(bx, by, qx, qy, col);
            api.line(qx, qy, dx, dy, col);
            api.line(dx, dy, ax, ay, col);
        }

        // floating numbers
        for (let k = 0; k < NFT; k++) {
            let ft = this.ftT[k];
            if (ft < 0) continue;
            if (api.project(<f32>this.ftX[k], <f32>this.ftY[k], <f32>this.ftZ[k])) {
                let rise = <f32>Math.floor(Math.min(ft, 0.5) * 24.0);
                let s = this.ftS[k];
                let tw = api.textWidth(s, 1);
                api.text(Mathf.round(api.screenX - tw * 0.5), Mathf.round(api.screenY - 6 - rise), s, api.paletteColor(this.ftC[k]), 1, ink);
            }
        }
        // the "!" over the hero
        if (this.bangT >= 0 && this.bangT < 0.5) {
            if (api.project(<f32>this.heroPX, <f32>(this.heroPY + 1.15), <f32>this.heroPZ)) {
                let bx = Mathf.round(api.screenX - 2), by = Mathf.round(api.screenY - 10);
                api.rect(bx - 2, by - 1, 9, 13, ink);
                api.text(bx, by, "!", gold, 2);
            }
        }

        // ---- the status panel (always)
        api.rect(2, 2, 84, 24, ink);
        api.rect(2, 2, 84, 1, teal);
        api.text(5, 5, "LV" + this.level.toString(), gold, 1);
        let xpNeed = this.xpFor(this.level);
        let xpPrev = this.level == 1 ? 0 : this.xpFor(this.level - 1);
        api.text(23, 5, "XP", api.paletteColor(P_SAGE), 1);
        this.bar(api, 33, 6, 50, this.xp - xpPrev, xpNeed - xpPrev, gold, slate);
        api.text(5, 12, "HP", rose, 1);
        this.bar(api, 15, 13, 40, this.hp, this.maxHp, this.hp * 4 <= this.maxHp ? red : rose, slate);
        api.text(58, 12, this.hp.toString() + "/" + this.maxHp.toString(), cream, 1);
        api.text(5, 19, "MP", sky, 1);
        this.bar(api, 15, 20, 40, this.mp, this.maxMp, sky, slate);
        api.text(58, 19, this.mp.toString() + "/" + this.maxMp.toString(), cream, 1);
        // gold and potions (the potion box is a button on the map)
        api.rect(w - 42, 2, 40, 23, ink);
        api.rect(w - 42, 2, 40, 1, teal);
        api.rect(w - 38, 6, 4, 4, gold);
        api.rect(w - 37, 7, 2, 2, api.paletteColor(P_OCHRE));
        api.text(w - 31, 5, this.gold.toString() + "G", gold, 1);
        let canDrink = st == ST_MAP && this.potions > 0 && this.hp < this.maxHp;
        if (canDrink && !api.demo) {
            api.rect(w - 41, 12, 38, 12, sea);
        }
        // a little bottle
        api.rect(w - 37, 14, 2, 2, cream);
        api.rect(w - 38, 16, 4, 5, plum);
        api.text(w - 31, 15, "X" + this.potions.toString(), cream, 1);

        // the map's messages
        if (this.noteT >= 0 && (st == ST_MAP)) {
            api.textCentered(30, this.noteText, cream, 1, ink);
        }

        if (st == ST_TITLE) {
            let blink = Math.floor(api.time * 2.0) % 2 == 0;
            api.rect(0, h - 23, w, 21, ink);
            api.textCentered(h - 20, "CLICK OR TAP A TILE TO WALK", blink ? gold : cream, 1);
            api.textCentered(h - 12, "GROW STRONG, THEN BEAT THE WARDEN AT THE SHRINE", api.paletteColor(P_SAGE), 1);
            return;
        }
        if (st == ST_MAP) {
            // the inn's shop
            if (!this.walking && this.hi == INN_I && this.hj == INN_J) {
                let bx = Mathf.floor((w - 90) * 0.5), by = h - 36;
                let can = this.gold >= POTION_COST;
                api.rect(bx - 1, by - 1, 92, 16, can ? gold : grey);
                api.rect(bx, by, 90, 14, ink);
                api.textCentered(by + 5, "BUY POTION  " + POTION_COST.toString() + "G", can ? gold : grey, 1);
                api.textCentered(by - 9, "THE INN", cream, 1, ink);
            }
            if (this.stateT < 3.0 && this.fights == 0 && this.steps < 3 && !api.demo) {
                api.textCentered(h - 10, "WILD GRASS AND WOODS HIDE MONSTERS", teal, 1, ink);
            }
            return;
        }
        if (st == ST_FIGHT) {
            this.fightHud(api);
            return;
        }
        // the end panels
        let pw: f32 = 150, ph: f32 = 58;
        let px = Mathf.floor((w - pw) * 0.5), py = Mathf.floor(h * 0.5 - 30);
        api.rect(px - 1, py - 1, pw + 2, ph + 2, st == ST_VICTORY ? gold : rose);
        api.rect(px, py, pw, ph, ink);
        if (st == ST_VICTORY) {
            api.textCentered(py + 4, "VICTORY!", gold, 2);
            api.textCentered(py + 18, "THE SHRINE IS FREE", cream, 1);
            api.textCentered(py + 27, "LV " + this.level.toString() + "   GOLD " + this.gold.toString() + "   STEPS " + this.steps.toString(), teal, 1);
            api.textCentered(py + 36, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), cream, 1);
        } else {
            api.textCentered(py + 4, "GAME OVER", rose, 2);
            api.textCentered(py + 18, "THE HERO FELL", cream, 1);
            api.textCentered(py + 27, "LV " + this.level.toString() + "   GOLD " + this.gold.toString() + "   STEPS " + this.steps.toString(), teal, 1);
            api.textCentered(py + 36, "BEST " + this.best.toString(), cream, 1);
        }
        if (this.stateT > 0.8 && !api.demo) {
            let blink = Math.floor(api.time * 2.0) % 2 == 0;
            api.textCentered(py + 47, "CLICK OR TAP FOR A NEW QUEST", blink ? gold : cream, 1);
        }
    }

    fightHud(api: GameApi): void {
        let ink = api.paletteColor(P_INK);
        let cream = api.paletteColor(P_CREAM);
        let gold = api.paletteColor(P_GOLD);
        let teal = api.paletteColor(P_TEAL);
        let rose = api.paletteColor(P_ROSE);
        let grey = api.paletteColor(P_GREY);
        let slate = api.paletteColor(P_SLATE);
        let sea = api.paletteColor(P_SEA);
        let sky = api.paletteColor(P_SKY);
        let navy = api.paletteColor(P_NAVY);
        let w = <f32>api.hudW, h = <f32>api.hudH;

        // the Warden's HP: a bar at the top, between the panels
        if (this.ne > 0 && this.eKind[0] == K_WARDEN) {
            // between the status panel (x 2..86) and the purse (w - 42 ..)
            let px: f32 = 89, pw = w - 44 - px;
            api.rect(px, 2, pw, 17, ink);
            api.rect(px, 2, pw, 1, api.paletteColor(P_PLUM));
            let nm = "THE WARDEN";
            api.text(Mathf.floor(px + (pw - api.textWidth(nm, 1)) * 0.5), 5, nm, cream, 1);
            this.bar(api, px + 3, 13, pw - 6, this.eHp[0], this.eMax[0], this.eHp[0] * 3 <= this.eMax[0] ? rose : api.paletteColor(P_PLUM), slate);
        }
        // the monsters' HP over their heads
        for (let e = 0; e < this.ne; e++) {
            if (!this.alive(e) || this.ePop[e] < 0.3 || this.eKind[e] == K_WARDEN) continue;
            if (api.project(<f32>this.eX[e], <f32>(this.eY[e] + this.enemyTop(e) + 0.12), <f32>this.eZ[e])) {
                let bw: f32 = this.eKind[e] == K_WARDEN ? 40 : 18;
                let bx = Mathf.round(api.screenX - bw * 0.5), by = Mathf.round(api.screenY - 4);
                api.rect(bx - 1, by - 1, bw + 2, 5, ink);
                this.bar(api, bx, by, bw, this.eHp[e], this.eMax[e], this.eHp[e] * 3 <= this.eMax[e] ? rose : gold, slate);
                if (e == this.target && this.phase == PH_CHOOSE) {
                    let nm = kindName(this.eKind[e]);
                    api.text(Mathf.round(api.screenX - api.textWidth(nm, 1) * 0.5), by - 7, nm, cream, 1, ink);
                }
            }
        }

        // the message line, just above the buttons
        let my = <f32>(api.hudH - 32);
        if (this.phase == PH_WON && this.phaseT > 0.25 && this.eKind[0] != K_WARDEN) {
            api.textCentered(my, "VICTORY!  +" + this.wonXp.toString() + " XP  +" + this.wonGold.toString() + " GOLD", gold, 1, ink);
        } else if (this.fightMsgT >= 0) {
            api.textCentered(my, this.fightMsg, this.phase == PH_LOST ? rose : cream, 1, ink);
        } else if (this.phase == PH_CHOOSE && !api.demo) {
            api.textCentered(my, "YOUR MOVE: PICK A MONSTER, THEN AN ACTION", api.paletteColor(P_SAGE), 1, ink);
        }
        if (this.phase == PH_WON && this.eKind[0] == K_WARDEN && this.phaseT > 0.25) {
            api.textCentered(my - 9, "+" + this.wonXp.toString() + " XP  +" + this.wonGold.toString() + " GOLD", gold, 1, ink);
        }
        if (this.phase == PH_WON && this.levelUps > 0 && this.phaseT > 0.9) {
            let blink = Math.floor(api.time * 6.0) % 2 == 0;
            api.textCentered(my - 25, "LEVEL UP!  LV " + this.level.toString(), blink ? gold : cream, 2, ink);
            api.textCentered(my - 12, "HP " + this.maxHp.toString() + "  MP " + this.maxMp.toString() + "  ATK " + this.atk.toString(), cream, 1, ink);
        }

        // the buttons
        let by = this.btnY(api);
        api.rect(0, by - 2, w, 23, api.paletteColor(P_NAVY));
        let choosing = this.phase == PH_CHOOSE;
        for (let k = 0; k < 4; k++) {
            let bx = this.btnX(k);
            let usable = choosing && !(k == A_MAGIC && this.mp < MAGIC_COST) && !(k == A_POTION && this.potions <= 0);
            let lit = this.pressed == k && this.pressedT >= 0;
            let face = lit ? gold : (usable ? sea : slate);
            let edge = usable ? (this.hoverBtn(api, k) ? gold : sky) : grey;
            api.rect(bx, by, 51, 19, edge);
            api.rect(bx + 1, by + 1, 49, 17, face);
            let label = k == A_ATTACK ? "ATTACK" : (k == A_MAGIC ? "MAGIC" : (k == A_DEFEND ? "DEFEND" : "POTION"));
            let sub = k == A_ATTACK ? "ONE FOE" : (k == A_MAGIC ? MAGIC_COST.toString() + " MP ALL" : (k == A_DEFEND ? "HALF HURT" : "X" + this.potions.toString() + " +" + POTION_HEAL.toString() + "HP"));
            let tc = lit ? ink : (usable ? cream : grey);
            let lw = api.textWidth(label, 2);
            api.text(Mathf.round(bx + (51 - lw) * 0.5), by + 2, label, tc, 2, lit ? 0 : ink);
            let sw = api.textWidth(sub, 1);
            api.text(Mathf.round(bx + (51 - sw) * 0.5), by + 13, sub, lit ? ink : (usable ? gold : grey), 1);
        }
    }

    hoverBtn(api: GameApi, k: i32): bool {
        if (api.demo || api.pointerX < 0) return false;
        let bx = this.btnX(k), by = this.btnY(api);
        return api.pointerX >= bx && api.pointerX < bx + 51 && api.pointerY >= by && api.pointerY < by + 19;
    }
}
