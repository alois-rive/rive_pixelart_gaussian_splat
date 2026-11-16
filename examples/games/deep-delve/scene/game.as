// Deep Delve: a small roguelike on floating stone platforms over an abyss. The pointer steps the delver
// one tile up, down, left or right (towards the pointer, the dominant axis); stepping into a monster
// attacks it, onto an item picks it up, onto the stairs goes down. Turns are timed by energy: every
// actor gains energy at its speed and acts at 100; actions cost energy (a step 100, a blow the
// weapon's weight, a potion 50), and the world runs only while the delver waits for energy. Each
// depth is a new layout from the run's seed. Pointer only; demo mode plays itself.
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP, SFX_BLIP, SFX_COIN, SFX_HIT, SFX_EXPLODE, SFX_SHOOT,
         SFX_POWERUP, SFX_THUD, SFX_SPLASH, SFX_WHOOSH, SFX_NOTE, SFX_BELL, SFX_LOSE, SFX_WIN, SFX_TICK,
         SFX_POP, SFX_CLICK, SFX_ZAP } from "./game_api";

// ------------------------------------------------------------------ the map
// Tiles are 1 m; tile (i, j) spans x i..i+1, z j..j+1. 3 x 2 cells of 9 x 8 tiles, one platform per
// cell (a room of 3 to 7 tiles a side keeps the cell's last column and row empty), so neighbours are
// always at least one tile of abyss apart and every corridor is a straight bridge.
const MW: i32 = 27;
const MH: i32 = 16;
const CW: i32 = 9;
const CH: i32 = 8;
const NROOM: i32 = 6;
const NBRIDGE: i32 = 7;
const NBRAZ: i32 = 4;
const BRIDGE_LEN: i32 = 8;     // the baked bridge's length in tiles (the spare slides under the rooms)
const BRIDGE_Y: f64 = -0.15;   // bridge decks sit under the room floors
const ROOM_W: StaticArray<i32> = [7, 6, 5, 6, 4, 5];   // the six baked platforms (room0..room5)
const ROOM_H: StaticArray<i32> = [5, 5, 5, 4, 4, 3];
const T_VOID: i32 = 0;
const T_FLOOR: i32 = 1;
const T_BRIDGE: i32 = 2;
const LIGHT: f64 = 5.6;        // the delver's light: monsters further away stay in the dark

// ------------------------------------------------------------------ actors
// slot 0 is the delver; slots 1..15 are tied to the monster bones (a pool per kind)
const MAXA: i32 = 16;
const K_HERO: i32 = 0;
const K_SKITTER: i32 = 1;      // a swarm: packs of three or four, weak
const K_FLITTER: i32 = 2;      // an erratic flyer: speed 200, acts twice per step
const K_SHELL: i32 = 3;        // a slow tank: speed 50, acts every other step, hits hard
const K_SPITTER: i32 = 4;      // ranged: spits poison acid down a row or a column, keeps away
const K_OOZE: i32 = 5;         // special: splits in two when struck
const SLOT_LO: StaticArray<i32> = [0, 1, 5, 8, 10, 12];
const SLOT_HI: StaticArray<i32> = [0, 4, 7, 9, 11, 15];
const K_NAME: StaticArray<string> = ["DELVER", "SKITTER", "FLITTER", "SHELLBACK", "SPITTER", "OOZE"];
const K_HP: StaticArray<i32> = [20, 3, 4, 15, 6, 8];
const K_SPD: StaticArray<i32> = [100, 100, 200, 50, 80, 70];
const K_DLO: StaticArray<i32> = [0, 1, 1, 3, 1, 2];
const K_DHI: StaticArray<i32> = [0, 2, 2, 6, 2, 3];
const K_ACC: StaticArray<f64> = [0, 0.7, 0.6, 0.8, 0.75, 0.75];
const K_XP: StaticArray<i32> = [0, 1, 2, 6, 4, 2];
const K_ARM: StaticArray<i32> = [0, 0, 0, 1, 0, 0];
const K_TOP: StaticArray<f64> = [1.3, 0.45, 1.05, 1.0, 0.8, 0.72];  // where the HP bar floats
const K_FLY: StaticArray<f64> = [0, 0, 0.55, 0, 0, 0];
const K_SEEN_MSG: StaticArray<string> = ["", "SKITTERS! THEY COME IN PACKS", "A FLITTER - FAST AND ERRATIC",
    "A SHELLBACK - SLOW BUT HEAVY", "A SPITTER - IT SPITS POISON", "AN OOZE - IT SPLITS WHEN HIT"];

// ------------------------------------------------------------------ items
const MAXI: i32 = 10;          // floor items, tied to bones: chest0-1, potred0-1, potblue, scroll0-1, gold0-2
const IT_CHEST: i32 = 0;
const IT_MEND: i32 = 1;
const IT_HASTE: i32 = 2;
const IT_SCROLL: i32 = 3;
const IT_GOLD: i32 = 4;
const ISLOT_LO: StaticArray<i32> = [0, 2, 4, 5, 7];
const ISLOT_HI: StaticArray<i32> = [1, 3, 4, 6, 9];
// what the pack holds
const V_DAGGER: i32 = 0;
const V_SWORD: i32 = 1;
const V_AXE: i32 = 2;
const V_SLING: i32 = 3;
const V_LEATHER: i32 = 4;
const V_MAIL: i32 = 5;
const V_MEND: i32 = 6;
const V_HASTE: i32 = 7;
const V_BLINK: i32 = 8;
const V_SIGHT: i32 = 9;
const V_NAME: StaticArray<string> = ["DAGGER", "SWORD", "AXE", "SLING", "LEATHER", "MAIL", "MENDING POTION",
    "HASTE POTION", "BLINK SCROLL", "SIGHT SCROLL"];
const V_INFO: StaticArray<string> = ["2-4 DMG, COSTS 60 - QUICK", "3-6 DMG, COSTS 100", "5-9 DMG, COSTS 150 - SLOW",
    "SHOOTS 5 TILES, 2-4 DMG", "ARMOUR 1", "ARMOUR 2", "HEALS AND CURES POISON", "DOUBLE SPEED FOR A WHILE",
    "JUMPS AWAY FROM DANGER", "SHOWS THE WHOLE DEPTH"];
const W_LO: StaticArray<i32> = [2, 3, 5, 2];
const W_HI: StaticArray<i32> = [4, 6, 9, 4];
const W_COST: StaticArray<i32> = [60, 100, 150, 100];
const W_ACC: StaticArray<f64> = [0.92, 0.86, 0.8, 0.85];
const NSLOT: i32 = 9;          // one slot per kind of thing the pack can hold: it never overflows
const SLOT: i32 = 16;          // inventory slots: 16 art pixels square (a finger's tap on a phone)
const SLOT_STEP: i32 = 18;

// ------------------------------------------------------------------ states and timing
const ST_PLAY: i32 = 0;
const ST_DESCEND: i32 = 1;
const ST_OVER: i32 = 2;
const MOVE_DUR: f64 = 0.11;
const HIT_DUR: f64 = 0.14;
const AN_NONE: i32 = 0;
const AN_MOVE: i32 = 1;
const AN_BUMP: i32 = 2;
const DIRX: StaticArray<i32> = [1, 0, -1, 0];
const DIRZ: StaticArray<i32> = [0, 1, 0, -1];

// palette indices (art/palette.json "colors") and ramps (its "ramps" order)
// (Gamma Boy: stone, deep, wood, brass, moss, cloak, rust, gloom, bone, flame, rune, acid, spark, ember)
const R_STONE: i32 = 0;
const R_DEEP: i32 = 1;
const R_WOOD: i32 = 2;
const R_BRASS: i32 = 3;
const R_MOSS: i32 = 4;
const R_CLOAK: i32 = 5;
const R_RUST: i32 = 6;
const R_GLOOM: i32 = 7;
const R_BONE: i32 = 8;
const R_RUNE: i32 = 10;

// 9 x 9 HUD icons: '.' empty, letters a palette colour (see iconColor)
const ICONS: StaticArray<string> = [
    // dagger
    ".......w.......ww......ww......ww....a.ww......aw.......ka......k..a....k........",
    // sword
    "........w.......ww......ww......ww......ww....a.ww......aw......kaa.....k........",
    // axe
    "...ss......ssss.....ssws......sw........w........w........w........w........w....",
    // sling
    ".w.....w..w.....w...wrrrw....w...w.....w.w.......w........w........w........w....",
    // leather
    ".ww...ww.wwwwwwwwwwwwwwwwww.wwwwwww...wkkkw....wwwww....wwwww....wwwww...........",
    // mail
    ".ss...ss.sbsbsbsbsbsbsbsbsb.sbsbsbs...sbsbs....bsbsb....sbsbs....bsbsb...........",
    // mend
    "...kkk.......g.......g.g.....grrrg...grrrrrg..grrrrrg..grrrrrg...ggggg...........",
    // haste
    "...kkk.......g.......g.g.....gcccg...gcccccg..gcccccg..gcccccg...ggggg...........",
    // blink
    ".........kpppppppkkpppppppk.pcpppcp..ppcpcpp..pppcppp.kpppppppkkpppppppk.........",
    // sight
    ".........kpppppppkkpppppppk.pprrrpp..prppprpp.pprrrpp.kpppppppkkpppppppk.........",
];

export class Game {
    state: i32 = ST_PLAY;
    stateT: f64 = 0;
    wasDemo: bool = false;
    started: bool = false;     // the player made a first move (the hint hides)

    // run
    runSeed: u32 = 1;
    lrng: u32 = 1;             // the level generator's own stream (seeded from the run and the depth)
    depth: i32 = 1;
    gold: i32 = 0;
    kills: i32 = 0;
    xp: i32 = 0;
    level: i32 = 1;
    cause: string = "";
    bestDepth: i32 = 0;
    bestGold: i32 = 0;
    newBest: bool = false;
    ticks: i32 = 0;

    // map
    tile: StaticArray<i32> = new StaticArray<i32>(MW * MH);
    tRoom: StaticArray<i32> = new StaticArray<i32>(MW * MH);
    tBridge: StaticArray<i32> = new StaticArray<i32>(MW * MH);
    tBlock: StaticArray<bool> = new StaticArray<bool>(MW * MH);    // braziers
    dist: StaticArray<i32> = new StaticArray<i32>(MW * MH);        // steps from the delver
    work: StaticArray<i32> = new StaticArray<i32>(MW * MH);        // BFS scratch
    queue: StaticArray<i32> = new StaticArray<i32>(MW * MH);
    back: StaticArray<i32> = new StaticArray<i32>(MW * MH);        // BFS from a goal (the demo)
    // rooms (by bone: room k is always the k-th baked platform)
    rOn: StaticArray<bool> = new StaticArray<bool>(NROOM);
    rX0: StaticArray<i32> = new StaticArray<i32>(NROOM);
    rZ0: StaticArray<i32> = new StaticArray<i32>(NROOM);
    rW: StaticArray<i32> = new StaticArray<i32>(NROOM);
    rH: StaticArray<i32> = new StaticArray<i32>(NROOM);
    rRot: StaticArray<bool> = new StaticArray<bool>(NROOM);
    rSeen: StaticArray<bool> = new StaticArray<bool>(NROOM);
    rSeenT: StaticArray<f64> = new StaticArray<f64>(NROOM);
    rCell: StaticArray<i32> = new StaticArray<i32>(NROOM);
    cellRoom: StaticArray<i32> = new StaticArray<i32>(6);
    // bridges
    bOn: StaticArray<bool> = new StaticArray<bool>(NBRIDGE);
    bVert: StaticArray<bool> = new StaticArray<bool>(NBRIDGE);
    bLine: StaticArray<i32> = new StaticArray<i32>(NBRIDGE);      // the row (or column) it runs along
    bA: StaticArray<i32> = new StaticArray<i32>(NBRIDGE);         // first and last abyss tile it spans
    bB: StaticArray<i32> = new StaticArray<i32>(NBRIDGE);
    bS: StaticArray<f64> = new StaticArray<f64>(NBRIDGE);         // where the baked strip starts
    bScale: StaticArray<f64> = new StaticArray<f64>(NBRIDGE);
    bSeen: StaticArray<bool> = new StaticArray<bool>(NBRIDGE);
    bSeenT: StaticArray<f64> = new StaticArray<f64>(NBRIDGE);
    bRA: StaticArray<i32> = new StaticArray<i32>(NBRIDGE);        // the platforms it joins
    bRB: StaticArray<i32> = new StaticArray<i32>(NBRIDGE);
    // braziers
    zOn: StaticArray<bool> = new StaticArray<bool>(NBRAZ);
    zX: StaticArray<i32> = new StaticArray<i32>(NBRAZ);
    zZ: StaticArray<i32> = new StaticArray<i32>(NBRAZ);
    stairX: i32 = 0;
    stairZ: i32 = 0;
    startRoom: i32 = 0;

    // actors
    aKind: StaticArray<i32> = new StaticArray<i32>(MAXA);
    aLive: StaticArray<i32> = new StaticArray<i32>(MAXA);      // 0 free, 1 alive, 2 dying
    aX: StaticArray<i32> = new StaticArray<i32>(MAXA);
    aZ: StaticArray<i32> = new StaticArray<i32>(MAXA);
    aHp: StaticArray<i32> = new StaticArray<i32>(MAXA);
    aMax: StaticArray<i32> = new StaticArray<i32>(MAXA);
    aEn: StaticArray<i32> = new StaticArray<i32>(MAXA);
    aSpd: StaticArray<i32> = new StaticArray<i32>(MAXA);
    aDmg: StaticArray<i32> = new StaticArray<i32>(MAXA);       // depth bonus
    aGen: StaticArray<i32> = new StaticArray<i32>(MAXA);       // ooze: 0 whole, 1 a half
    aAlert: StaticArray<bool> = new StaticArray<bool>(MAXA);
    aSeen: StaticArray<bool> = new StaticArray<bool>(MAXA);
    aEver: StaticArray<bool> = new StaticArray<bool>(MAXA);
    aCool: StaticArray<i32> = new StaticArray<i32>(MAXA);
    aYaw: StaticArray<f64> = new StaticArray<f64>(MAXA);
    aBone: StaticArray<i32> = new StaticArray<i32>(MAXA);
    anK: StaticArray<i32> = new StaticArray<i32>(MAXA);
    anT0: StaticArray<f64> = new StaticArray<f64>(MAXA);
    anDur: StaticArray<f64> = new StaticArray<f64>(MAXA);
    anFX: StaticArray<f64> = new StaticArray<f64>(MAXA);
    anFZ: StaticArray<f64> = new StaticArray<f64>(MAXA);
    anTX: StaticArray<f64> = new StaticArray<f64>(MAXA);
    anTZ: StaticArray<f64> = new StaticArray<f64>(MAXA);
    hurtT: StaticArray<f64> = new StaticArray<f64>(MAXA);
    dieT: StaticArray<f64> = new StaticArray<f64>(MAXA);
    seenT: StaticArray<f64> = new StaticArray<f64>(MAXA);
    vX: StaticArray<f64> = new StaticArray<f64>(MAXA);         // where it shows now
    vZ: StaticArray<f64> = new StaticArray<f64>(MAXA);
    kindSeen: StaticArray<bool> = new StaticArray<bool>(6);

    // the delver
    heroReady: bool = true;
    busyUntil: f64 = 0;
    poison: i32 = 0;
    haste: i32 = 0;            // ticks of haste left
    regenT: i32 = 0;
    weapon: i32 = V_DAGGER;
    armour: i32 = -1;
    invK: StaticArray<i32> = new StaticArray<i32>(NSLOT);
    invN: StaticArray<i32> = new StaticArray<i32>(NSLOT);
    swingT: f64 = -1;
    stepCount: i32 = 0;
    heroBone: i32 = -1;
    weaponBone: StaticArray<i32> = new StaticArray<i32>(4);
    markBone: i32 = -1;
    atkBone: i32 = -1;
    stairBone: i32 = -1;
    roomBone: StaticArray<i32> = new StaticArray<i32>(NROOM);
    bridgeBone: StaticArray<i32> = new StaticArray<i32>(NBRIDGE);
    brazBone: StaticArray<i32> = new StaticArray<i32>(NBRAZ);

    // floor items
    iOn: StaticArray<i32> = new StaticArray<i32>(MAXI);        // 0 none, 1 lying, 2 picked (anim)
    iType: StaticArray<i32> = new StaticArray<i32>(MAXI);
    iSub: StaticArray<i32> = new StaticArray<i32>(MAXI);
    iX: StaticArray<i32> = new StaticArray<i32>(MAXI);
    iZ: StaticArray<i32> = new StaticArray<i32>(MAXI);
    iT: StaticArray<f64> = new StaticArray<f64>(MAXI);
    iBone: StaticArray<i32> = new StaticArray<i32>(MAXI);

    // projectiles: 0 the sling stone, 1-2 acid
    pOn: StaticArray<bool> = new StaticArray<bool>(3);
    pT0: StaticArray<f64> = new StaticArray<f64>(3);
    pDur: StaticArray<f64> = new StaticArray<f64>(3);
    pFX: StaticArray<f64> = new StaticArray<f64>(3);
    pFZ: StaticArray<f64> = new StaticArray<f64>(3);
    pTX: StaticArray<f64> = new StaticArray<f64>(3);
    pTZ: StaticArray<f64> = new StaticArray<f64>(3);
    pY: StaticArray<f64> = new StaticArray<f64>(3);
    pBone: StaticArray<i32> = new StaticArray<i32>(3);
    // sparks
    sT: StaticArray<f64> = new StaticArray<f64>(6);
    sX: StaticArray<f64> = new StaticArray<f64>(6);
    sY: StaticArray<f64> = new StaticArray<f64>(6);
    sZ: StaticArray<f64> = new StaticArray<f64>(6);
    sVX: StaticArray<f64> = new StaticArray<f64>(6);
    sVY: StaticArray<f64> = new StaticArray<f64>(6);
    sVZ: StaticArray<f64> = new StaticArray<f64>(6);
    sBone: StaticArray<i32> = new StaticArray<i32>(6);
    sNext: i32 = 0;
    // floating numbers
    fT: StaticArray<f64> = new StaticArray<f64>(8);
    fX: StaticArray<f64> = new StaticArray<f64>(8);
    fY: StaticArray<f64> = new StaticArray<f64>(8);
    fZ: StaticArray<f64> = new StaticArray<f64>(8);
    fS: Array<string> = ["", "", "", "", "", "", "", ""];
    fC: StaticArray<i32> = new StaticArray<i32>(8);
    fNext: i32 = 0;
    // messages
    msg0: string = "";
    msg1: string = "";
    msgT: f64 = -10;
    msgC: i32 = 0;
    flashT: f64 = -10;         // the screen edge flashes on a hit taken

    // pointer
    holding: bool = false;
    holdBlocked: bool = false;
    repeatAt: f64 = 0;
    hoverSlot: i32 = -1;
    hoverSeen: bool = false;   // a mouse moved without a press (never on touch): the marker may follow it
    // what a click would do now (the markers show it)
    tgtKind: i32 = 0;          // 0 nothing, 1 step, 2 attack, 3 shoot, 4 wait, 5 blocked
    tgtX: i32 = 0;
    tgtZ: i32 = 0;
    tgtDir: i32 = 0;

    // demo
    dThink: f64 = 0;
    dGoal: i32 = -1;

    descendPhase: i32 = 0;
    arriveT: f64 = 0;
    camX: f64 = 13.5;
    camZ: f64 = 8;
    shakeT: f64 = -10;

    // ================================================================ setup

    start(api: GameApi): void {
        api.playable = true;
        this.heroBone = api.bone("hero");
        this.weaponBone[0] = api.bone("dagger");
        this.weaponBone[1] = api.bone("sword");
        this.weaponBone[2] = api.bone("axe");
        this.weaponBone[3] = api.bone("sling");
        this.markBone = api.bone("marker");
        this.atkBone = api.bone("markatk");
        this.stairBone = api.bone("stairs");
        for (let i = 0; i < NROOM; i++) this.roomBone[i] = api.bone("room" + i.toString());
        for (let i = 0; i < NBRIDGE; i++) this.bridgeBone[i] = api.bone("bridge" + i.toString());
        for (let i = 0; i < NBRAZ; i++) this.brazBone[i] = api.bone("brazier" + i.toString());
        const names: StaticArray<string> = ["", "skitter", "flitter", "shellback", "spitter", "ooze"];
        this.aBone[0] = this.heroBone;
        for (let k = 1; k < 6; k++) {
            for (let s = SLOT_LO[k]; s <= SLOT_HI[k]; s++) {
                this.aBone[s] = api.bone(names[k] + (s - SLOT_LO[k]).toString());
            }
        }
        this.iBone[0] = api.bone("chest0");
        this.iBone[1] = api.bone("chest1");
        this.iBone[2] = api.bone("potred0");
        this.iBone[3] = api.bone("potred1");
        this.iBone[4] = api.bone("potblue");
        this.iBone[5] = api.bone("scroll0");
        this.iBone[6] = api.bone("scroll1");
        this.iBone[7] = api.bone("gold0");
        this.iBone[8] = api.bone("gold1");
        this.iBone[9] = api.bone("gold2");
        this.pBone[0] = api.bone("stone");
        this.pBone[1] = api.bone("spit0");
        this.pBone[2] = api.bone("spit1");
        for (let i = 0; i < 6; i++) {
            this.sBone[i] = api.bone("spark" + i.toString());
            this.sT[i] = -1;
        }
        for (let i = 0; i < 8; i++) this.fT[i] = -10;
        this.wasDemo = api.demo;
        this.newRun(api);
    }

    // ================================================================ runs and levels

    newRun(api: GameApi): void {
        this.runSeed = <u32>(api.rand() * 4294967295.0);
        this.depth = 1;
        this.gold = 0;
        this.kills = 0;
        this.xp = 0;
        this.level = 1;
        this.cause = "";
        this.newBest = false;
        this.poison = 0;
        this.haste = 0;
        this.regenT = 0;
        this.weapon = V_DAGGER;
        this.armour = -1;
        for (let i = 0; i < NSLOT; i++) {
            this.invK[i] = -1;
            this.invN[i] = 0;
        }
        this.invK[0] = V_DAGGER;
        this.invN[0] = 1;
        this.invK[1] = V_MEND;
        this.invN[1] = 1;
        this.aKind[0] = K_HERO;
        this.aMax[0] = K_HP[0];
        this.aHp[0] = K_HP[0];
        this.aSpd[0] = 100;
        this.aLive[0] = 1;
        this.hurtT[0] = -10;
        this.dieT[0] = -10;
        this.swingT = -10;
        this.started = api.demo;
        this.msg0 = "";
        this.msg1 = "";
        this.state = ST_PLAY;
        this.stateT = api.time;
        this.holding = false;
        this.holdBlocked = false;
        this.dThink = api.time + 0.25;
        this.buildLevel(api);
        this.camX = this.vX[0];
        this.camZ = this.vZ[0];
        this.say(api, "DEPTH 1 - FIND THE STAIRS DOWN", R_RUNE);
    }

    lr(): f64 {
        this.lrng = this.lrng * 1664525 + 1013904223;
        return <f64>(this.lrng >> 8) / 16777216.0;
    }

    lri(n: i32): i32 {
        return min<i32>(n - 1, <i32>(this.lr() * <f64>n));
    }

    idx(x: i32, z: i32): i32 {
        return z * MW + x;
    }

    inMap(x: i32, z: i32): bool {
        return x >= 0 && z >= 0 && x < MW && z < MH;
    }

    walkable(x: i32, z: i32): bool {
        if (!this.inMap(x, z)) return false;
        let i = this.idx(x, z);
        return this.tile[i] != T_VOID && !this.tBlock[i];
    }

    floorY(x: i32, z: i32): f64 {
        if (!this.inMap(x, z)) return 0;
        return this.tile[this.idx(x, z)] == T_BRIDGE ? BRIDGE_Y : 0.0;
    }

    actorAt(x: i32, z: i32): i32 {
        for (let s = 0; s < MAXA; s++) {
            if (this.aLive[s] == 1 && this.aX[s] == x && this.aZ[s] == z) return s;
        }
        return -1;
    }

    itemAt(x: i32, z: i32): i32 {
        for (let i = 0; i < MAXI; i++) {
            if (this.iOn[i] == 1 && this.iX[i] == x && this.iZ[i] == z) return i;
        }
        return -1;
    }

    // Builds depth this.depth: platforms, bridges, braziers, stairs, monsters, items. Every layout is
    // checked (every floor tile reachable from the start); a failed one is rebuilt with the next seed.
    buildLevel(api: GameApi): void {
        let tries = 0;
        while (true) {
            this.lrng = this.runSeed ^ (<u32>this.depth * 2654435761) ^ (<u32>tries * 40503);
            for (let k = 0; k < 4; k++) this.lr();
            if (this.layout() || tries >= 12) break;
            tries++;
        }
        this.populate(api);
        // reset the visual state
        for (let k = 0; k < NROOM; k++) {
            this.rSeen[k] = false;
            this.rSeenT[k] = -10;
        }
        for (let b = 0; b < NBRIDGE; b++) {
            this.bSeen[b] = false;
            this.bSeenT[b] = -10;
        }
        this.vX[0] = <f64>this.aX[0] + 0.5;
        this.vZ[0] = <f64>this.aZ[0] + 0.5;
        this.anK[0] = AN_NONE;
        this.aEn[0] = 100;
        this.heroReady = true;
        this.busyUntil = 0;
        this.computeDist();
        this.updateSight(api, true);
        for (let k = 0; k < NROOM; k++) if (this.rSeen[k]) this.rSeenT[k] = api.time - 2;
        for (let b = 0; b < NBRIDGE; b++) if (this.bSeen[b]) this.bSeenT[b] = api.time - 2;
    }

    // The platforms and bridges; false when a check fails.
    layout(): bool {
        for (let i = 0; i < MW * MH; i++) {
            this.tile[i] = T_VOID;
            this.tRoom[i] = -1;
            this.tBridge[i] = -1;
            this.tBlock[i] = false;
        }
        // which cell stays empty (from depth 2 on, now and then)
        let skip = -1;
        if (this.depth >= 2 && this.lr() < 0.4) skip = this.lri(6);
        // shuffle the six platforms over the cells
        let order = new StaticArray<i32>(6);
        for (let i = 0; i < 6; i++) order[i] = i;
        for (let i = 5; i > 0; i--) {
            let j = this.lri(i + 1);
            let t = order[i]; order[i] = order[j]; order[j] = t;
        }
        // spines: every platform in a column holds that column's spine x, every one in a row its spine z
        let sx = new StaticArray<i32>(3);
        let sz = new StaticArray<i32>(2);
        for (let c = 0; c < 3; c++) sx[c] = c * CW + 3 + this.lri(2);
        for (let r = 0; r < 2; r++) sz[r] = r * CH + 2 + this.lri(3);
        for (let k = 0; k < NROOM; k++) this.rOn[k] = false;
        for (let cell = 0; cell < 6; cell++) {
            this.cellRoom[cell] = -1;
            let k = order[cell];
            if (cell == skip) continue;
            let c = cell % 3, r = cell / 3;
            let rot = this.lr() < 0.5;
            let w = rot ? ROOM_H[k] : ROOM_W[k];
            let h = rot ? ROOM_W[k] : ROOM_H[k];
            let lox = max<i32>(c * CW, sx[c] - w + 1), hix = min<i32>(c * CW + 8 - w, sx[c]);
            let loz = max<i32>(r * CH, sz[r] - h + 1), hiz = min<i32>(r * CH + 7 - h, sz[r]);
            if (hix < lox || hiz < loz) return false;
            this.rOn[k] = true;
            this.rRot[k] = rot;
            this.rW[k] = w;
            this.rH[k] = h;
            this.rX0[k] = lox + this.lri(hix - lox + 1);
            this.rZ0[k] = loz + this.lri(hiz - loz + 1);
            this.rCell[k] = cell;
            this.cellRoom[cell] = k;
        }
        // close gaps wider than a bridge: pull neighbours together (they keep their spines)
        for (let pass = 0; pass < 4; pass++) {
            for (let cell = 0; cell < 6; cell++) {
                let a = this.cellRoom[cell];
                if (a < 0) continue;
                let c = cell % 3;
                if (c < 2 && this.cellRoom[cell + 1] >= 0) {
                    let b = this.cellRoom[cell + 1];
                    while (this.rX0[b] - (this.rX0[a] + this.rW[a]) > BRIDGE_LEN) {
                        if (this.rX0[b] > max<i32>((c + 1) * CW, sx[c + 1] - this.rW[b] + 1)) this.rX0[b]--;
                        else if (this.rX0[a] < min<i32>(c * CW + 8 - this.rW[a], sx[c])) this.rX0[a]++;
                        else break;
                    }
                }
                if (cell < 3 && this.cellRoom[cell + 3] >= 0) {
                    let b = this.cellRoom[cell + 3];
                    while (this.rZ0[b] - (this.rZ0[a] + this.rH[a]) > BRIDGE_LEN) {
                        if (this.rZ0[b] > max<i32>(CH, sz[1] - this.rH[b] + 1)) this.rZ0[b]--;
                        else if (this.rZ0[a] < min<i32>(7 - this.rH[a], sz[0])) this.rZ0[a]++;
                        else break;
                    }
                }
            }
        }
        for (let k = 0; k < NROOM; k++) {
            if (!this.rOn[k]) continue;
            for (let z = this.rZ0[k]; z < this.rZ0[k] + this.rH[k]; z++) {
                for (let x = this.rX0[k]; x < this.rX0[k] + this.rW[k]; x++) {
                    let i = this.idx(x, z);
                    this.tile[i] = T_FLOOR;
                    this.tRoom[i] = k;
                }
            }
        }
        // edges between neighbouring cells: a random spanning tree, then a few loops
        let ea = new StaticArray<i32>(7);
        let eb = new StaticArray<i32>(7);
        let ne = 0;
        for (let cell = 0; cell < 6; cell++) {
            if (this.cellRoom[cell] < 0) continue;
            if (cell % 3 < 2 && this.cellRoom[cell + 1] >= 0) { ea[ne] = cell; eb[ne] = cell + 1; ne++; }
            if (cell < 3 && this.cellRoom[cell + 3] >= 0) { ea[ne] = cell; eb[ne] = cell + 3; ne++; }
        }
        for (let i = ne - 1; i > 0; i--) {
            let j = this.lri(i + 1);
            let t = ea[i]; ea[i] = ea[j]; ea[j] = t;
            t = eb[i]; eb[i] = eb[j]; eb[j] = t;
        }
        let comp = new StaticArray<i32>(6);
        for (let i = 0; i < 6; i++) comp[i] = i;
        let used = new StaticArray<bool>(7);
        for (let e = 0; e < ne; e++) {
            let ca = comp[ea[e]], cb = comp[eb[e]];
            if (ca != cb) {
                used[e] = true;
                for (let i = 0; i < 6; i++) if (comp[i] == cb) comp[i] = ca;
            }
        }
        for (let e = 0; e < ne; e++) {
            if (!used[e] && this.lr() < 0.35) used[e] = true;
        }
        let nb = 0;
        for (let b = 0; b < NBRIDGE; b++) this.bOn[b] = false;
        for (let e = 0; e < ne; e++) {
            if (!used[e]) continue;
            let a = this.cellRoom[ea[e]], b = this.cellRoom[eb[e]];
            let vert = eb[e] - ea[e] == 3;
            let lo: i32, hi: i32, s0: i32, s1: i32, lenA: i32, lenB: i32;
            if (!vert) {
                lo = max<i32>(this.rZ0[a], this.rZ0[b]);
                hi = min<i32>(this.rZ0[a] + this.rH[a], this.rZ0[b] + this.rH[b]) - 1;
                s0 = this.rX0[a] + this.rW[a];
                s1 = this.rX0[b] - 1;
                lenA = this.rW[a]; lenB = this.rW[b];
            } else {
                lo = max<i32>(this.rX0[a], this.rX0[b]);
                hi = min<i32>(this.rX0[a] + this.rW[a], this.rX0[b] + this.rW[b]) - 1;
                s0 = this.rZ0[a] + this.rH[a];
                s1 = this.rZ0[b] - 1;
                lenA = this.rH[a]; lenB = this.rH[b];
            }
            if (hi < lo || s1 < s0) return false;
            let line = lo + this.lri(hi - lo + 1);
            let g = s1 - s0 + 1;
            // the strip: BRIDGE_LEN tiles covering the gap, the spare split under the two platforms
            let spare = BRIDGE_LEN - g;
            let scale = 1.0;
            let start: f64;
            if (spare < 0) {
                return false;
            } else if (spare > lenA + lenB - 2) {
                // too short to hide the spare: squeeze the strip (planks a little closer)
                scale = <f64>(g + lenA + lenB - 2) / <f64>BRIDGE_LEN;
                start = <f64>(s0 - lenA + 1);
            } else {
                let oa = min<i32>(lenA - 1, max<i32>(spare - (lenB - 1), spare / 2));
                start = <f64>(s0 - oa);
            }
            this.bOn[nb] = true;
            this.bVert[nb] = vert;
            this.bLine[nb] = line;
            this.bA[nb] = s0;
            this.bB[nb] = s1;
            this.bS[nb] = start;
            this.bScale[nb] = scale;
            this.bRA[nb] = a;
            this.bRB[nb] = b;
            for (let t = s0; t <= s1; t++) {
                let i = vert ? this.idx(line, t) : this.idx(t, line);
                this.tile[i] = T_BRIDGE;
                this.tBridge[i] = nb;
            }
            nb++;
        }
        // braziers: on an inner corner of the bigger rooms, never next to a bridge's landing
        for (let z = 0; z < NBRAZ; z++) this.zOn[z] = false;
        let nz = 0;
        for (let k = 0; k < NROOM && nz < NBRAZ; k++) {
            if (!this.rOn[k] || this.rW[k] < 5 || this.rH[k] < 4) continue;
            let corner = this.lri(4);
            let x = corner % 2 == 0 ? this.rX0[k] + 1 : this.rX0[k] + this.rW[k] - 2;
            let z = corner < 2 ? this.rZ0[k] + 1 : this.rZ0[k] + this.rH[k] - 2;
            let near = false;
            for (let d = 0; d < 4; d++) {
                for (let r = 1; r <= 2; r++) {
                    let nx = x + DIRX[d] * r, nz2 = z + DIRZ[d] * r;
                    if (this.inMap(nx, nz2) && this.tile[this.idx(nx, nz2)] == T_BRIDGE) near = true;
                }
            }
            if (near) continue;
            this.zOn[nz] = true;
            this.zX[nz] = x;
            this.zZ[nz] = z;
            this.tBlock[this.idx(x, z)] = true;
            nz++;
        }
        // every floor tile reachable from any one of them
        let first = -1, total = 0;
        for (let i = 0; i < MW * MH; i++) {
            if (this.tile[i] != T_VOID && !this.tBlock[i]) {
                total++;
                if (first < 0) first = i;
            }
        }
        if (this.bfs(first % MW, first / MW, this.work) != total) return false;
        return true;
    }

    // Breadth-first steps from (x, z) over walkable tiles into out (-1 unreached); returns the count.
    bfs(x: i32, z: i32, out: StaticArray<i32>): i32 {
        for (let i = 0; i < MW * MH; i++) out[i] = -1;
        let head = 0, tail = 0;
        let s = this.idx(x, z);
        out[s] = 0;
        this.queue[tail++] = s;
        while (head < tail) {
            let c = this.queue[head++];
            let cx = c % MW, cz = c / MW;
            for (let d = 0; d < 4; d++) {
                let nx = cx + DIRX[d], nz = cz + DIRZ[d];
                if (!this.walkable(nx, nz)) continue;
                let n = this.idx(nx, nz);
                if (out[n] >= 0) continue;
                out[n] = out[c] + 1;
                this.queue[tail++] = n;
            }
        }
        return tail;
    }

    computeDist(): void {
        this.bfs(this.aX[0], this.aZ[0], this.dist);
    }

    randomFree(k: i32, avoidX: i32, avoidZ: i32, minD: i32): i32 {
        for (let t = 0; t < 40; t++) {
            let x = this.rX0[k] + this.lri(this.rW[k]);
            let z = this.rZ0[k] + this.lri(this.rH[k]);
            if (!this.walkable(x, z)) continue;
            if (x == this.stairX && z == this.stairZ) continue;
            if (this.actorAt(x, z) >= 0 || this.itemAt(x, z) >= 0) continue;
            if (abs<i32>(x - avoidX) + abs<i32>(z - avoidZ) < minD) continue;
            return this.idx(x, z);
        }
        return -1;
    }

    // Start, stairs, monsters and items for this depth.
    populate(api: GameApi): void {
        for (let s = 1; s < MAXA; s++) this.aLive[s] = 0;
        for (let i = 0; i < MAXI; i++) this.iOn[i] = 0;
        for (let p = 0; p < 3; p++) this.pOn[p] = false;
        for (let k = 0; k < 6; k++) this.kindSeen[k] = false;
        // the start: a random platform; the stairs: in the platform farthest from it
        let rooms = new StaticArray<i32>(6);
        let nr = 0;
        for (let k = 0; k < NROOM; k++) if (this.rOn[k]) rooms[nr++] = k;
        this.startRoom = rooms[this.lri(nr)];
        let sx = this.rX0[this.startRoom] + this.rW[this.startRoom] / 2;
        let sz = this.rZ0[this.startRoom] + this.rH[this.startRoom] / 2;
        if (!this.walkable(sx, sz)) {
            let f = this.randomFree(this.startRoom, -100, -100, 0);
            sx = f % MW; sz = f / MW;
        }
        this.aX[0] = sx;
        this.aZ[0] = sz;
        this.stairX = -10;
        this.stairZ = -10;
        this.bfs(sx, sz, this.work);
        let far = -1, farD = -1;
        for (let k = 0; k < NROOM; k++) {
            if (!this.rOn[k] || k == this.startRoom) continue;
            let cx = this.rX0[k] + this.rW[k] / 2, cz = this.rZ0[k] + this.rH[k] / 2;
            let d = this.work[this.idx(cx, cz)] + this.lri(3);
            if (d > farD) { farD = d; far = k; }
        }
        if (far < 0) far = this.startRoom;
        let st = this.randomFree(far, sx, sz, 3);
        if (st < 0) st = this.randomFree(far, -100, -100, 0);
        this.stairX = st % MW;
        this.stairZ = st / MW;
        this.tBlock[st] = false;
        // monsters: how many of each kind at this depth
        let d = this.depth;
        let nSk = d == 1 ? 3 : 4;
        let nFl = d == 1 ? 1 : (d < 4 ? 2 : 3);
        let nSh = d < 2 ? 0 : (d < 5 ? 1 : 2);
        let nSp = d < 3 ? 0 : (d < 4 ? 1 : 2);
        let nOz = d < 2 ? 0 : (d < 3 ? 1 : 2);
        // the start platform gets one flitter in the light (the first second has something moving)
        let fs = this.randomFree(this.startRoom, sx, sz, 3);
        if (fs >= 0) this.spawn(K_FLITTER, fs % MW, fs / MW);
        // packs and loners in the other platforms
        let packRoom = this.otherRoom(rooms, nr);
        let anchor = this.randomFree(packRoom, sx, sz, 4);
        for (let i = 0; i < nSk && anchor >= 0; i++) {
            let ax = anchor % MW, az = anchor / MW;
            let placed = false;
            for (let t = 0; t < 12 && !placed; t++) {
                let x = ax + this.lri(3) - 1, z = az + this.lri(3) - 1;
                if (this.walkable(x, z) && this.actorAt(x, z) < 0 && !(x == this.stairX && z == this.stairZ)) {
                    this.spawn(K_SKITTER, x, z);
                    placed = true;
                }
            }
        }
        this.spawnSome(K_FLITTER, nFl, rooms, nr, sx, sz);
        this.spawnSome(K_SHELL, nSh, rooms, nr, sx, sz);
        this.spawnSome(K_SPITTER, nSp, rooms, nr, sx, sz);
        this.spawnSome(K_OOZE, nOz, rooms, nr, sx, sz);
        // items
        let nGold = 2 + this.lri(2);
        for (let i = 0; i < nGold; i++) this.dropItem(IT_GOLD, (4 + this.lri(6)) * (2 + d) / 2, rooms, nr, sx, sz);
        this.dropItem(IT_MEND, 0, rooms, nr, sx, sz);
        if (this.lr() < 0.25) this.dropItem(IT_MEND, 0, rooms, nr, sx, sz);
        if (this.lr() < 0.35) this.dropItem(IT_HASTE, 0, rooms, nr, sx, sz);
        this.dropItem(IT_SCROLL, this.lr() < 0.55 ? V_BLINK : V_SIGHT, rooms, nr, sx, sz);
        if (this.lr() < 0.4) this.dropItem(IT_SCROLL, this.lr() < 0.5 ? V_BLINK : V_SIGHT, rooms, nr, sx, sz);
        let nChest = d >= 3 ? 2 : 1;
        for (let i = 0; i < nChest; i++) this.dropItem(IT_CHEST, this.chestLoot(), rooms, nr, sx, sz);
    }

    otherRoom(rooms: StaticArray<i32>, nr: i32): i32 {
        for (let t = 0; t < 10; t++) {
            let k = rooms[this.lri(nr)];
            if (k != this.startRoom) return k;
        }
        return rooms[0];
    }

    spawnSome(kind: i32, n: i32, rooms: StaticArray<i32>, nr: i32, sx: i32, sz: i32): void {
        for (let i = 0; i < n; i++) {
            let k = this.otherRoom(rooms, nr);
            let f = this.randomFree(k, sx, sz, 5);
            if (f >= 0) this.spawn(kind, f % MW, f / MW);
        }
    }

    chestLoot(): i32 {
        let d = this.depth;
        let r = this.lr();
        if (d == 1) return r < 0.4 ? V_SWORD : (r < 0.75 ? V_SLING : V_LEATHER);
        if (r < 0.22) return V_SWORD;
        if (r < 0.44) return V_AXE;
        if (r < 0.62) return V_SLING;
        if (r < 0.82 || d < 3) return V_LEATHER;
        return V_MAIL;
    }

    dropItem(type: i32, sub: i32, rooms: StaticArray<i32>, nr: i32, sx: i32, sz: i32): void {
        let slot = -1;
        for (let i = ISLOT_LO[type]; i <= ISLOT_HI[type]; i++) {
            if (this.iOn[i] == 0) { slot = i; break; }
        }
        if (slot < 0) return;
        let k = rooms[this.lri(nr)];
        let f = this.randomFree(k, sx, sz, 2);
        if (f < 0) return;
        this.iOn[slot] = 1;
        this.iType[slot] = type;
        this.iSub[slot] = sub;
        this.iX[slot] = f % MW;
        this.iZ[slot] = f / MW;
        this.iT[slot] = 0;
    }

    spawn(kind: i32, x: i32, z: i32): i32 {
        let s = -1;
        for (let i = SLOT_LO[kind]; i <= SLOT_HI[kind]; i++) {
            if (this.aLive[i] == 0) { s = i; break; }
        }
        if (s < 0) return -1;
        let d = this.depth - 1;
        this.aKind[s] = kind;
        this.aLive[s] = 1;
        this.aX[s] = x;
        this.aZ[s] = z;
        this.aMax[s] = K_HP[kind] + (K_HP[kind] * d) / 3;
        this.aHp[s] = this.aMax[s];
        this.aSpd[s] = K_SPD[kind];
        this.aDmg[s] = (d * 3) / 4;
        this.aEn[s] = <i32>(this.lr() * 90.0);
        this.aGen[s] = 0;
        this.aAlert[s] = false;
        this.aSeen[s] = false;
        this.aEver[s] = false;
        this.aCool[s] = 0;
        this.aYaw[s] = <f64>(this.lri(4) * 90);
        this.anK[s] = AN_NONE;
        this.hurtT[s] = -10;
        this.dieT[s] = -10;
        this.seenT[s] = -10;
        this.vX[s] = <f64>x + 0.5;
        this.vZ[s] = <f64>z + 0.5;
        return s;
    }

    // ================================================================ sight

    // Reveals the platforms and bridges the light reaches (they rise out of the abyss) and decides
    // which monsters are seen.
    updateSight(api: GameApi, quiet: bool): void {
        let hx = this.aX[0], hz = this.aZ[0];
        let r2 = LIGHT * LIGHT;
        for (let k = 0; k < NROOM; k++) {
            if (!this.rOn[k] || this.rSeen[k]) continue;
            let cx = <f64>max<i32>(this.rX0[k], min<i32>(hx, this.rX0[k] + this.rW[k] - 1));
            let cz = <f64>max<i32>(this.rZ0[k], min<i32>(hz, this.rZ0[k] + this.rH[k] - 1));
            let dx = cx - <f64>hx, dz = cz - <f64>hz;
            if (dx * dx + dz * dz <= r2) {
                this.rSeen[k] = true;
                this.rSeenT[k] = api.time;
            }
        }
        for (let b = 0; b < NBRIDGE; b++) {
            if (!this.bOn[b] || this.bSeen[b]) continue;
            for (let t = this.bA[b]; t <= this.bB[b]; t++) {
                let x = this.bVert[b] ? this.bLine[b] : t, z = this.bVert[b] ? t : this.bLine[b];
                let dx = <f64>(x - hx), dz = <f64>(z - hz);
                if (dx * dx + dz * dz <= r2) {
                    // a bridge's spare length lies under its platforms: they show with it
                    this.bSeen[b] = true;
                    this.bSeenT[b] = api.time;
                    for (let e = 0; e < 2; e++) {
                        let k = e == 0 ? this.bRA[b] : this.bRB[b];
                        if (!this.rSeen[k]) {
                            this.rSeen[k] = true;
                            this.rSeenT[k] = api.time;
                        }
                    }
                    break;
                }
            }
        }
        for (let s = 1; s < MAXA; s++) {
            if (this.aLive[s] != 1) continue;
            let dx = <f64>(this.aX[s] - hx), dz = <f64>(this.aZ[s] - hz);
            let seen = dx * dx + dz * dz <= r2;
            if (seen && !this.aSeen[s]) {
                this.seenT[s] = api.time;
                this.aAlert[s] = true;
                if (!quiet) {
                    this.holdBlocked = true;
                    if (!this.kindSeen[this.aKind[s]]) {
                        this.say(api, K_SEEN_MSG[this.aKind[s]], R_BRASS);
                        api.soundAt(SFX_BLIP, <f64>this.aX[s] + 0.5, 0, <f64>this.aZ[s] + 0.5, 0.6, 0.35);
                    }
                }
                this.kindSeen[this.aKind[s]] = true;
            }
            this.aSeen[s] = seen;
            if (seen) this.aEver[s] = true;
        }
    }

    roomRevealed(x: i32, z: i32): bool {
        if (!this.inMap(x, z)) return false;
        let i = this.idx(x, z);
        if (this.tRoom[i] >= 0) return this.rSeen[this.tRoom[i]];
        if (this.tBridge[i] >= 0) return this.bSeen[this.tBridge[i]];
        return false;
    }

    // ================================================================ messages and effects

    say(api: GameApi, s: string, ramp: i32): void {
        if (s == this.msg0 && api.time - this.msgT < 0.5) return;
        this.msg1 = this.msg0;
        this.msg0 = s;
        this.msgT = api.time;
        this.msgC = ramp;
    }

    popup(x: f64, y: f64, z: f64, s: string, ramp: i32, t: f64): void {
        let i = this.fNext;
        this.fNext = (this.fNext + 1) % 8;
        this.fT[i] = t;
        this.fX[i] = x;
        this.fY[i] = y;
        this.fZ[i] = z;
        this.fS[i] = s;
        this.fC[i] = ramp;
    }

    burst(api: GameApi, x: f64, y: f64, z: f64, n: i32, delay: f64): void {
        for (let k = 0; k < n; k++) {
            let i = this.sNext;
            this.sNext = (this.sNext + 1) % 6;
            let a = <f64>(k * 2 + this.sNext) * 1.3;
            this.sT[i] = api.time + delay;
            this.sX[i] = x;
            this.sY[i] = y;
            this.sZ[i] = z;
            this.sVX[i] = Math.cos(a) * 1.6;
            this.sVZ[i] = Math.sin(a) * 1.6;
            this.sVY[i] = 2.4 + <f64>(k % 2) * 0.8;
        }
    }

    tween(s: i32, kind: i32, tx: f64, tz: f64, dur: f64, api: GameApi): void {
        this.anK[s] = kind;
        this.anT0[s] = api.time;
        this.anDur[s] = dur;
        this.anFX[s] = this.vX[s];
        this.anFZ[s] = this.vZ[s];
        this.anTX[s] = tx;
        this.anTZ[s] = tz;
    }

    face(s: i32, dx: i32, dz: i32): void {
        if (dx == 0 && dz == 0) return;
        this.aYaw[s] = Math.atan2(<f64>dx, <f64>dz) * 180.0 / Math.PI;
    }

    // ================================================================ the delver's actions

    // What a step in direction d does now: 1 step, 2 attack, 3 shoot, 5 blocked, 0 nothing.
    planDir(d: i32): i32 {
        let hx = this.aX[0], hz = this.aZ[0];
        let nx = hx + DIRX[d], nz = hz + DIRZ[d];
        this.tgtDir = d;
        this.tgtX = nx;
        this.tgtZ = nz;
        if (this.weapon == V_SLING) {
            for (let r = 1; r <= 5; r++) {
                let x = hx + DIRX[d] * r, z = hz + DIRZ[d] * r;
                if (!this.inMap(x, z)) break;
                if (this.tBlock[this.idx(x, z)]) break;
                let a = this.actorAt(x, z);
                if (a > 0 && this.aSeen[a]) {
                    this.tgtX = x;
                    this.tgtZ = z;
                    return 3;
                }
            }
        }
        let a = this.actorAt(nx, nz);
        if (a > 0) return 2;
        if (this.walkable(nx, nz)) return 1;
        return 5;
    }

    // The pointer's direction from the delver: -1 (the delver's own tile: wait) or 0..3.
    pointerDir(api: GameApi, px: f32, py: f32): i32 {
        let fy = this.floorY(this.aX[0], this.aZ[0]);
        if (!api.pick(px, py, <f32>(fy + 0.3))) return -2;
        let dx = <f64>api.hitX - this.vX[0], dz = <f64>api.hitZ - this.vZ[0];
        if (Math.abs(dx) < 0.5 && Math.abs(dz) < 0.5) return -1;
        if (Math.abs(dx) >= Math.abs(dz)) return dx > 0 ? 0 : 2;
        return dz > 0 ? 1 : 3;
    }

    canAct(api: GameApi): bool {
        return this.state == ST_PLAY && this.heroReady && api.time >= this.busyUntil;
    }

    heroDir(api: GameApi, d: i32): bool {
        if (d == -1) {
            this.heroWait(api);
            return true;
        }
        if (d < 0) return false;
        let plan = this.planDir(d);
        if (plan == 3) {
            this.heroShoot(api, this.tgtX, this.tgtZ, d);
            return true;
        }
        if (plan == 2) {
            this.heroAttack(api, this.actorAt(this.tgtX, this.tgtZ), d);
            return true;
        }
        if (plan == 1) {
            this.heroStep(api, d);
            return true;
        }
        this.face(0, DIRX[d], DIRZ[d]);
        api.sound(SFX_TICK, 0.5, 0.25);
        if (!api.demo) this.say(api, "THE ABYSS. NO WAY THERE", R_STONE);
        return false;
    }

    spend(api: GameApi, cost: i32, dur: f64): void {
        this.aEn[0] -= cost;
        this.heroReady = false;
        this.busyUntil = api.time + dur;
        this.started = true;
    }

    heroWait(api: GameApi): void {
        this.spend(api, 100, 0.12);
        this.popup(this.vX[0], 1.4, this.vZ[0], "WAIT", R_STONE, api.time);
        api.sound(SFX_TICK, 0.7, 0.2);
    }

    heroStep(api: GameApi, d: i32): void {
        let nx = this.aX[0] + DIRX[d], nz = this.aZ[0] + DIRZ[d];
        this.face(0, DIRX[d], DIRZ[d]);
        this.aX[0] = nx;
        this.aZ[0] = nz;
        this.tween(0, AN_MOVE, <f64>nx + 0.5, <f64>nz + 0.5, MOVE_DUR, api);
        this.spend(api, 100, MOVE_DUR);
        this.stepCount++;
        // footsteps, sparse: every other step; wood on the bridges
        if (this.stepCount % 2 == 0) {
            if (this.tile[this.idx(nx, nz)] == T_BRIDGE) api.sound(SFX_CLICK, 0.55, 0.35);
            else api.sound(SFX_TICK, this.stepCount % 4 == 0 ? 0.8 : 0.9, 0.3);
        }
        this.computeDist();
        this.updateSight(api, false);
        let it = this.itemAt(nx, nz);
        if (it >= 0) this.pickUp(api, it);
        if (nx == this.stairX && nz == this.stairZ) this.descend(api);
    }

    heroAttack(api: GameApi, s: i32, d: i32): void {
        this.face(0, DIRX[d], DIRZ[d]);
        let w = this.weapon;
        let cost = w == V_SLING ? 100 : W_COST[w];
        this.tween(0, AN_BUMP, <f64>this.aX[s] + 0.5, <f64>this.aZ[s] + 0.5, HIT_DUR, api);
        this.swingT = api.time;
        this.spend(api, cost, HIT_DUR);
        let x = <f64>this.aX[s] + 0.5, z = <f64>this.aZ[s] + 0.5;
        let pitch = w == V_DAGGER ? 1.5 : (w == V_AXE ? 0.7 : 1.0);
        api.soundAt(SFX_WHOOSH, x, 0, z, pitch, 0.35);
        let acc = w == V_SLING ? 0.8 : W_ACC[w];
        if (api.rand() > acc) {
            this.popup(x, K_TOP[this.aKind[s]] + 0.4, z, "MISS", R_STONE, api.time + 0.07);
            return;
        }
        let lo = w == V_SLING ? 1 : W_LO[w], hi = w == V_SLING ? 2 : W_HI[w];
        let dmg = lo + <i32>(api.rand() * <f64>(hi - lo + 1)) + (this.level - 1) / 2;
        // the blow lands: each weapon its own sound
        if (w == V_DAGGER) {
            api.soundAt(SFX_HIT, x, 0, z, 1.35, 0.6, 0.06);
            api.soundAt(SFX_CLICK, x, 0, z, 1.6, 0.4, 0.06);
        } else if (w == V_SWORD) {
            api.soundAt(SFX_HIT, x, 0, z, 1.0, 0.75, 0.06);
            api.soundAt(SFX_ZAP, x, 0, z, 2.2, 0.15, 0.07);
        } else if (w == V_AXE) {
            api.soundAt(SFX_THUD, x, 0, z, 0.9, 0.8, 0.07);
            api.soundAt(SFX_HIT, x, 0, z, 0.7, 0.7, 0.07);
        } else {
            api.soundAt(SFX_THUD, x, 0, z, 1.3, 0.4, 0.06);
        }
        this.damage(api, s, dmg, 0.07);
    }

    heroShoot(api: GameApi, tx: i32, tz: i32, d: i32): void {
        this.face(0, DIRX[d], DIRZ[d]);
        let s = this.actorAt(tx, tz);
        let r = abs<i32>(tx - this.aX[0]) + abs<i32>(tz - this.aZ[0]);
        let flight = 0.06 + 0.045 * <f64>r;
        this.swingT = api.time;
        this.spend(api, 100, flight + 0.04);
        this.launch(0, <f64>this.aX[0] + 0.5, <f64>this.aZ[0] + 0.5, <f64>tx + 0.5, <f64>tz + 0.5,
            0.75 + this.floorY(this.aX[0], this.aZ[0]), flight, api);
        api.sound(SFX_SHOOT, 1.25, 0.45);
        let x = <f64>tx + 0.5, z = <f64>tz + 0.5;
        if (s < 0 || api.rand() > 0.85 - 0.04 * <f64>r) {
            if (s >= 0) this.popup(x, K_TOP[this.aKind[s]] + 0.4, z, "MISS", R_STONE, api.time + flight);
            return;
        }
        let dmg = W_LO[V_SLING] + <i32>(api.rand() * <f64>(W_HI[V_SLING] - W_LO[V_SLING] + 1)) + (this.level - 1) / 2;
        api.soundAt(SFX_POP, x, 0, z, 0.8, 0.7, flight);
        api.soundAt(SFX_HIT, x, 0, z, 1.2, 0.5, flight);
        this.damage(api, s, dmg, flight);
    }

    launch(p: i32, fx: f64, fz: f64, tx: f64, tz: f64, y: f64, dur: f64, api: GameApi): void {
        this.pOn[p] = true;
        this.pT0[p] = api.time;
        this.pDur[p] = dur;
        this.pFX[p] = fx;
        this.pFZ[p] = fz;
        this.pTX[p] = tx;
        this.pTZ[p] = tz;
        this.pY[p] = y;
    }

    // A blow on monster s (after delay seconds): hurt, maybe split (an ooze), maybe die.
    damage(api: GameApi, s: i32, dmg0: i32, delay: f64): void {
        let dmg = max<i32>(1, dmg0 - K_ARM[this.aKind[s]]);
        let x = <f64>this.aX[s] + 0.5, z = <f64>this.aZ[s] + 0.5;
        let y = this.floorY(this.aX[s], this.aZ[s]);
        this.aHp[s] -= dmg;
        this.aAlert[s] = true;
        this.hurtT[s] = api.time + delay;
        this.popup(x, y + K_TOP[this.aKind[s]] + 0.3, z, dmg.toString(), R_BRASS, api.time + delay);
        this.burst(api, x, y + 0.4 + K_FLY[this.aKind[s]], z, 2, delay);
        if (this.aHp[s] <= 0) {
            this.kill(api, s, delay);
            return;
        }
        if (this.aKind[s] == K_OOZE && this.aGen[s] == 0 && this.aHp[s] >= 2) {
            // the ooze splits: half its life jumps to a free tile beside it
            for (let d = 0; d < 4; d++) {
                let nx = this.aX[s] + DIRX[d], nz = this.aZ[s] + DIRZ[d];
                if (!this.walkable(nx, nz) || this.actorAt(nx, nz) >= 0) continue;
                if (nx == this.stairX && nz == this.stairZ) continue;
                let n = this.spawn(K_OOZE, nx, nz);
                if (n < 0) break;
                let half = this.aHp[s] / 2;
                this.aHp[n] = half;
                this.aMax[n] = max<i32>(1, this.aMax[s] / 2);
                this.aHp[s] -= half;
                this.aMax[s] = max<i32>(1, this.aMax[s] / 2);
                this.aGen[s] = 1;
                this.aGen[n] = 1;
                this.aDmg[n] = this.aDmg[s];
                this.aAlert[n] = true;
                this.aSeen[n] = this.aSeen[s];
                this.aEver[n] = true;
                this.aEn[n] = this.aEn[s];
                this.vX[n] = x;
                this.vZ[n] = z;
                this.tween(n, AN_MOVE, <f64>nx + 0.5, <f64>nz + 0.5, 0.16, api);
                this.anT0[n] = api.time + delay;
                this.say(api, "THE OOZE SPLITS!", R_RUST);
                api.soundAt(SFX_SPLASH, x, 0, z, 1.3, 0.6, delay + 0.03);
                api.soundAt(SFX_POP, x, 0, z, 1.5, 0.4, delay + 0.09);
                break;
            }
        }
    }

    kill(api: GameApi, s: i32, delay: f64): void {
        this.aLive[s] = 2;
        this.dieT[s] = api.time + delay;
        this.kills++;
        let k = this.aKind[s];
        let x = <f64>this.aX[s] + 0.5, z = <f64>this.aZ[s] + 0.5;
        api.soundAt(SFX_POP, x, 0, z, k == K_SHELL ? 0.5 : (k == K_SKITTER ? 1.6 : 1.0), 0.6, delay + 0.05);
        api.noteAt(<f64>(60 + (this.kills % 5) * 2), x, 0, z, 0.25, SFX_NOTE, delay + 0.1);
        this.burst(api, x, 0.4 + K_FLY[k], z, 4, delay);
        this.gainXp(api, K_XP[k], delay);
    }

    gainXp(api: GameApi, n: i32, delay: f64): void {
        this.xp += n;
        let need = 5 + this.level * this.level * 4;
        if (this.xp >= need) {
            this.xp -= need;
            this.level++;
            this.aMax[0] += 5;
            this.aHp[0] = min<i32>(this.aMax[0], this.aHp[0] + 8);
            this.say(api, "LEVEL " + this.level.toString() + "! STRONGER AND TOUGHER", R_BRASS);
            this.popup(this.vX[0], 1.6, this.vZ[0], "LEVEL UP", R_BRASS, api.time + delay);
            api.sound(SFX_WIN, 1.0, 0.5, 0, delay + 0.1);
            const tune: StaticArray<i32> = [72, 76, 79, 84];
            for (let i = 0; i < 4; i++) api.note(<f64>tune[i], 0.35, 0, SFX_NOTE, delay + 0.12 + 0.08 * <f64>i);
        }
    }

    pickUp(api: GameApi, it: i32): void {
        let t = this.iType[it];
        let x = <f64>this.iX[it] + 0.5, z = <f64>this.iZ[it] + 0.5;
        if (t == IT_GOLD) {
            this.gold += this.iSub[it];
            this.say(api, this.iSub[it].toString() + " GOLD", R_BRASS);
            this.popup(x, 1.2, z, "+" + this.iSub[it].toString(), R_BRASS, api.time + 0.05);
            api.sound(SFX_COIN, 1.0, 0.55, 0, 0.05);
            this.iOn[it] = 2;
            this.iT[it] = api.time;
            return;
        }
        let v = t == IT_MEND ? V_MEND : (t == IT_HASTE ? V_HASTE : (t == IT_SCROLL ? this.iSub[it] : this.iSub[it]));
        if (t == IT_CHEST) {
            api.sound(SFX_CLICK, 0.8, 0.5, 0, 0.05);
            // already owned, or worse armour: gold instead
            if (this.owns(v) || (v == V_LEATHER && this.armour == V_MAIL)) {
                let g = 10 + this.depth * 6;
                this.gold += g;
                this.say(api, "THE CHEST HOLDS " + g.toString() + " GOLD", R_BRASS);
                this.popup(x, 1.2, z, "+" + g.toString(), R_BRASS, api.time + 0.05);
                api.sound(SFX_COIN, 0.9, 0.55, 0, 0.15);
                this.iOn[it] = 2;
                this.iT[it] = api.time;
                return;
            }
        }
        if (v == V_LEATHER || v == V_MAIL) {
            let s = this.slotOf(V_LEATHER);
            if (s < 0) s = this.slotOf(V_MAIL);
            if (s < 0) s = this.freeSlot();
            if (s < 0) {
                this.say(api, "THE PACK IS FULL", R_STONE);
                return;
            }
            this.invK[s] = v;
            this.invN[s] = 1;
            this.armour = v;
            this.say(api, "FOUND " + V_NAME[v] + " - WORN AT ONCE", R_BRASS);
            api.sound(SFX_POWERUP, 0.9, 0.45, 0, 0.12);
            this.iOn[it] = 2;
            this.iT[it] = api.time;
            return;
        }
        let s = this.slotOf(v);
        if (s >= 0 && v >= V_MEND) {
            this.invN[s]++;
        } else {
            s = this.freeSlot();
            if (s < 0) {
                this.say(api, "THE PACK IS FULL", R_STONE);
                api.sound(SFX_TICK, 0.5, 0.3);
                return;
            }
            this.invK[s] = v;
            this.invN[s] = 1;
        }
        this.say(api, "FOUND " + (v <= V_SLING ? "A " : "") + V_NAME[v] + (v <= V_SLING ? " - TAP IT TO WIELD" : ""), R_BRASS);
        if (t == IT_CHEST) {
            api.sound(SFX_POWERUP, 1.0, 0.45, 0, 0.12);
        } else {
            api.sound(SFX_BLIP, 1.2, 0.45, 0, 0.04);
            api.note(76, 0.3, 0, SFX_NOTE, 0.1);
        }
        this.iOn[it] = 2;
        this.iT[it] = api.time;
    }

    owns(v: i32): bool {
        return this.slotOf(v) >= 0;
    }

    slotOf(v: i32): i32 {
        for (let i = 0; i < NSLOT; i++) if (this.invK[i] == v) return i;
        return -1;
    }

    freeSlot(): i32 {
        for (let i = 0; i < NSLOT; i++) if (this.invK[i] < 0) return i;
        return -1;
    }

    // A click on an inventory slot: wield, quaff or read.
    useSlot(api: GameApi, s: i32): void {
        let v = this.invK[s];
        if (v < 0) return;
        let x = this.vX[0], z = this.vZ[0];
        if (v <= V_SLING) {
            if (this.weapon == v) return;
            this.weapon = v;
            this.say(api, "WIELDING THE " + V_NAME[v] + " - " + V_INFO[v], R_BRASS);
            api.sound(SFX_CLICK, 1.1, 0.5);
            this.spend(api, 50, 0.12);
            return;
        }
        if (v == V_LEATHER || v == V_MAIL) {
            this.say(api, V_NAME[v] + " - " + V_INFO[v] + " (WORN)", R_STONE);
            return;
        }
        this.invN[s]--;
        if (this.invN[s] <= 0) this.invK[s] = -1;
        if (v == V_MEND) {
            let heal = max<i32>(8, this.aMax[0] * 6 / 10);
            this.aHp[0] = min<i32>(this.aMax[0], this.aHp[0] + heal);
            this.poison = 0;
            this.say(api, "MENDED. POISON GONE", R_CLOAK);
            this.popup(x, 1.5, z, "+" + heal.toString(), R_CLOAK, api.time);
            api.sound(SFX_POWERUP, 1.0, 0.5);
            api.sound(SFX_SPLASH, 1.6, 0.25);
        } else if (v == V_HASTE) {
            this.haste = 240;
            this.say(api, "HASTE! TWO STEPS FOR EVERY ONE OF THEIRS", R_BONE);
            const t: StaticArray<i32> = [72, 76, 79, 84, 88];
            for (let i = 0; i < 5; i++) api.note(<f64>t[i], 0.3, 0, SFX_NOTE, 0.05 * <f64>i);
            api.sound(SFX_ZAP, 1.4, 0.35);
        } else if (v == V_BLINK) {
            this.blink(api);
        } else if (v == V_SIGHT) {
            for (let k = 0; k < NROOM; k++) {
                if (this.rOn[k] && !this.rSeen[k]) {
                    this.rSeen[k] = true;
                    this.rSeenT[k] = api.time + 0.08 * <f64>k;
                }
            }
            for (let b = 0; b < NBRIDGE; b++) {
                if (this.bOn[b] && !this.bSeen[b]) {
                    this.bSeen[b] = true;
                    this.bSeenT[b] = api.time + 0.3 + 0.06 * <f64>b;
                }
            }
            this.say(api, "THE WHOLE DEPTH RISES FROM THE DARK", R_RUNE);
            const t: StaticArray<i32> = [67, 72, 76, 79, 84];
            for (let i = 0; i < 5; i++) api.note(<f64>t[i], 0.3, 0, SFX_BELL, 0.09 * <f64>i);
        }
        this.spend(api, 50, 0.15);
    }

    // The blink scroll: the free tile farthest from every monster within 7 steps.
    blink(api: GameApi): void {
        let best = -1, bestS = -1.0;
        for (let i = 0; i < MW * MH; i++) {
            let dd = this.dist[i];
            if (dd < 2 || dd > 7) continue;
            let x = i % MW, z = i / MW;
            if (this.actorAt(x, z) >= 0 || (x == this.stairX && z == this.stairZ)) continue;
            let near = 99.0;
            for (let s = 1; s < MAXA; s++) {
                if (this.aLive[s] != 1) continue;
                let m = <f64>(abs<i32>(this.aX[s] - x) + abs<i32>(this.aZ[s] - z));
                if (m < near) near = m;
            }
            let score = near + <f64>dd * 0.1;
            if (score > bestS) { bestS = score; best = i; }
        }
        if (best < 0) return;
        this.burst(api, this.vX[0], 0.6, this.vZ[0], 3, 0);
        this.aX[0] = best % MW;
        this.aZ[0] = best / MW;
        this.vX[0] = <f64>this.aX[0] + 0.5;
        this.vZ[0] = <f64>this.aZ[0] + 0.5;
        this.anK[0] = AN_NONE;
        this.hurtT[0] = -10;
        this.burst(api, this.vX[0], 0.6, this.vZ[0], 3, 0.05);
        this.say(api, "BLINK! YOU ARE ELSEWHERE", R_GLOOM);
        api.sound(SFX_WHOOSH, 1.4, 0.5);
        api.sound(SFX_ZAP, 0.8, 0.35, 0, 0.08);
        this.computeDist();
        this.updateSight(api, false);
        let it = this.itemAt(this.aX[0], this.aZ[0]);
        if (it >= 0) this.pickUp(api, it);
    }

    descend(api: GameApi): void {
        this.state = ST_DESCEND;
        this.descendPhase = 0;
        this.stateT = api.time;
        this.holding = false;
        this.say(api, "DOWN THE STAIRS...", R_RUNE);
        api.sound(SFX_WHOOSH, 0.7, 0.5, 0, 0.1);
        const t: StaticArray<i32> = [79, 74, 71, 67, 62];
        for (let i = 0; i < 5; i++) api.note(<f64>t[i], 0.3, 0, SFX_NOTE, 0.15 + 0.11 * <f64>i);
        api.note(55, 0.35, 0, SFX_BELL, 0.75);
    }

    // ================================================================ the world's turns

    // Runs ticks until the delver has energy again, pausing whenever a seen monster acts so each
    // group of actions shows (the fast ones act more often, the slow ones less).
    runWorld(api: GameApi): void {
        for (let n = 0; n < 600; n++) {
            this.ticks++;
            let hs = this.haste > 0 ? 200 : 100;
            this.aEn[0] += hs / 10;
            if (this.ticks % 10 == 0) {
                if (this.haste > 0) {
                    this.haste -= 10;
                    if (this.haste <= 0) this.say(api, "THE HASTE WEARS OFF", R_BONE);
                }
                if (this.poison > 0) {
                    this.poison--;
                    this.aHp[0]--;
                    this.hurtT[0] = api.time;
                    this.popup(this.vX[0], 1.5, this.vZ[0], "1", R_MOSS, api.time);
                    api.sound(SFX_HIT, 1.6, 0.25);
                    if (this.aHp[0] <= 0) {
                        this.cause = "POISON";
                        this.die(api);
                        return;
                    }
                }
                this.regenT++;
                if (this.regenT >= 12 && this.aHp[0] < this.aMax[0]) {
                    this.regenT = 0;
                    this.aHp[0]++;
                }
            }
            let shown = 0.0;
            for (let s = 1; s < MAXA; s++) {
                if (this.aLive[s] != 1) continue;
                this.aEn[s] += this.aSpd[s] / 10;
                if (this.aEn[s] >= 100) {
                    let d = this.monsterAct(api, s);
                    if (d > shown) shown = d;
                    if (this.aHp[0] <= 0) {
                        this.die(api);
                        return;
                    }
                }
            }
            if (this.aEn[0] >= 100) {
                this.heroReady = true;
                if (shown > 0) this.busyUntil = api.time + shown;
                return;
            }
            if (shown > 0) {
                this.busyUntil = api.time + shown;
                return;
            }
        }
    }

    // One monster's action; returns how long it shows (0: unseen).
    monsterAct(api: GameApi, s: i32): f64 {
        let k = this.aKind[s];
        let x = this.aX[s], z = this.aZ[s];
        let hx = this.aX[0], hz = this.aZ[0];
        let man = abs<i32>(x - hx) + abs<i32>(z - hz);
        let seen = this.aSeen[s];
        let here = this.dist[this.idx(x, z)];
        if (!this.aAlert[s] && here >= 0 && here <= 6) this.aAlert[s] = true;
        if (this.aCool[s] > 0) this.aCool[s]--;
        this.aEn[s] -= 100;
        if (!this.aAlert[s]) {
            // asleep or wandering
            if (api.rand() < 0.3) {
                let d = <i32>(api.rand() * 4.0) % 4;
                if (this.monsterStep(api, s, d)) return seen ? MOVE_DUR : 0;
            }
            return 0;
        }
        if (k == K_SPITTER) {
            let inLine = (x == hx || z == hz) && man >= 2 && man <= 4 && this.clearLine(x, z, hx, hz);
            if (inLine && this.aCool[s] == 0) {
                this.monsterSpit(api, s);
                return seen ? 0.06 + 0.05 * <f64>man : 0;
            }
            if (man <= 2 && api.rand() < 0.7) {
                if (this.stepAway(api, s)) return seen ? MOVE_DUR : 0;
            }
            if (man == 1) {
                this.monsterHit(api, s);
                return HIT_DUR;
            }
            if (this.stepToward(api, s)) return seen ? MOVE_DUR : 0;
            return 0;
        }
        if (k == K_FLITTER && api.rand() < 0.45) {
            // erratic: a flutter in a random direction
            let d = <i32>(api.rand() * 4.0) % 4;
            if (this.monsterStep(api, s, d)) return seen ? MOVE_DUR * 0.8 : 0;
        }
        if (man == 1) {
            this.monsterHit(api, s);
            return HIT_DUR;
        }
        if (this.stepToward(api, s)) {
            if (k == K_SHELL && seen) api.soundAt(SFX_THUD, <f64>this.aX[s] + 0.5, 0, <f64>this.aZ[s] + 0.5, 0.55, 0.45);
            if (k == K_OOZE && seen) api.soundAt(SFX_SPLASH, <f64>this.aX[s] + 0.5, 0, <f64>this.aZ[s] + 0.5, 0.7, 0.18);
            return seen ? (k == K_FLITTER ? MOVE_DUR * 0.8 : MOVE_DUR) : 0;
        }
        return 0;
    }

    clearLine(x0: i32, z0: i32, x1: i32, z1: i32): bool {
        let dx = x1 > x0 ? 1 : (x1 < x0 ? -1 : 0), dz = z1 > z0 ? 1 : (z1 < z0 ? -1 : 0);
        let x = x0 + dx, z = z0 + dz;
        while (x != x1 || z != z1) {
            if (this.tBlock[this.idx(x, z)] || this.actorAt(x, z) >= 0) return false;
            x += dx;
            z += dz;
        }
        return true;
    }

    monsterStep(api: GameApi, s: i32, d: i32): bool {
        let nx = this.aX[s] + DIRX[d], nz = this.aZ[s] + DIRZ[d];
        if (!this.walkable(nx, nz) || this.actorAt(nx, nz) >= 0) return false;
        if (nx == this.stairX && nz == this.stairZ) return false;
        this.face(s, DIRX[d], DIRZ[d]);
        this.aX[s] = nx;
        this.aZ[s] = nz;
        if (this.aSeen[s]) {
            this.tween(s, AN_MOVE, <f64>nx + 0.5, <f64>nz + 0.5, this.aKind[s] == K_FLITTER ? MOVE_DUR * 0.8 : MOVE_DUR, api);
        } else {
            this.vX[s] = <f64>nx + 0.5;
            this.vZ[s] = <f64>nz + 0.5;
        }
        // stepping into or out of the light
        let dx = <f64>(nx - this.aX[0]), dz = <f64>(nz - this.aZ[0]);
        let seen = dx * dx + dz * dz <= LIGHT * LIGHT;
        if (seen && !this.aSeen[s]) {
            this.seenT[s] = api.time;
            this.vX[s] = <f64>nx + 0.5;
            this.vZ[s] = <f64>nz + 0.5;
            this.holdBlocked = true;
            if (!this.kindSeen[this.aKind[s]]) {
                this.kindSeen[this.aKind[s]] = true;
                this.say(api, K_SEEN_MSG[this.aKind[s]], R_BRASS);
                api.soundAt(SFX_BLIP, <f64>nx + 0.5, 0, <f64>nz + 0.5, 0.6, 0.35);
            }
        }
        this.aSeen[s] = seen;
        if (seen) this.aEver[s] = true;
        return true;
    }

    stepToward(api: GameApi, s: i32): bool {
        let here = this.dist[this.idx(this.aX[s], this.aZ[s])];
        let best = -1, bestD = here < 0 ? 9999 : here;
        let start = <i32>(api.rand() * 4.0) % 4;
        for (let j = 0; j < 4; j++) {
            let d = (start + j) % 4;
            let nx = this.aX[s] + DIRX[d], nz = this.aZ[s] + DIRZ[d];
            if (!this.walkable(nx, nz) || this.actorAt(nx, nz) >= 0) continue;
            let nd = this.dist[this.idx(nx, nz)];
            if (nd >= 0 && nd < bestD) { bestD = nd; best = d; }
        }
        if (best < 0) return false;
        return this.monsterStep(api, s, best);
    }

    stepAway(api: GameApi, s: i32): bool {
        let here = this.dist[this.idx(this.aX[s], this.aZ[s])];
        let best = -1, bestD = here;
        for (let d = 0; d < 4; d++) {
            let nx = this.aX[s] + DIRX[d], nz = this.aZ[s] + DIRZ[d];
            if (!this.walkable(nx, nz) || this.actorAt(nx, nz) >= 0) continue;
            let nd = this.dist[this.idx(nx, nz)];
            if (nd > bestD) { bestD = nd; best = d; }
        }
        if (best < 0) return false;
        return this.monsterStep(api, s, best);
    }

    monsterHit(api: GameApi, s: i32): void {
        let k = this.aKind[s];
        this.face(s, this.aX[0] - this.aX[s], this.aZ[0] - this.aZ[s]);
        this.tween(s, AN_BUMP, this.vX[0], this.vZ[0], HIT_DUR, api);
        let x = <f64>this.aX[s] + 0.5, z = <f64>this.aZ[s] + 0.5;
        // each kind its voice
        if (k == K_SKITTER) {
            api.soundAt(SFX_TICK, x, 0, z, 2.2, 0.4);
            api.soundAt(SFX_TICK, x, 0, z, 2.6, 0.35, 0.05);
        } else if (k == K_FLITTER) {
            api.soundAt(SFX_ZAP, x, 0, z, 2.0, 0.25);
        } else if (k == K_SHELL) {
            api.soundAt(SFX_EXPLODE, x, 0, z, 0.9, 0.35);
        } else if (k == K_OOZE) {
            api.soundAt(SFX_SPLASH, x, 0, z, 1.0, 0.4);
        } else {
            api.soundAt(SFX_POP, x, 0, z, 0.6, 0.4);
        }
        if (api.rand() > K_ACC[k]) {
            this.popup(this.vX[0], 1.5, this.vZ[0], "MISS", R_STONE, api.time + 0.07);
            return;
        }
        let dmg = K_DLO[k] + <i32>(api.rand() * <f64>(K_DHI[k] - K_DLO[k] + 1)) + this.aDmg[s];
        if (k == K_OOZE && this.aGen[s] == 1) dmg = max<i32>(1, dmg - 1);
        this.hurtHero(api, dmg, 0.07, s);
    }

    monsterSpit(api: GameApi, s: i32): void {
        this.face(s, this.aX[0] - this.aX[s], this.aZ[0] - this.aZ[s]);
        let man = abs<i32>(this.aX[s] - this.aX[0]) + abs<i32>(this.aZ[s] - this.aZ[0]);
        let flight = 0.05 + 0.05 * <f64>man;
        let p = this.pOn[1] ? 2 : 1;
        this.launch(p, <f64>this.aX[s] + 0.5, <f64>this.aZ[s] + 0.5, this.vX[0], this.vZ[0],
            0.45 + this.floorY(this.aX[s], this.aZ[s]), flight, api);
        this.aCool[s] = 2;
        let x = <f64>this.aX[s] + 0.5, z = <f64>this.aZ[s] + 0.5;
        api.soundAt(SFX_SPLASH, x, 0, z, 1.6, 0.4);
        api.soundAt(SFX_POP, x, 0, z, 1.8, 0.3, 0.03);
        if (api.rand() > 0.7) {
            this.popup(this.vX[0], 1.5, this.vZ[0], "MISS", R_STONE, api.time + flight);
            return;
        }
        let dmg = 1 + <i32>(api.rand() * 2.0) + this.aDmg[s];
        this.hurtHero(api, dmg, flight, s);
        if (this.aHp[0] > 0) {
            this.poison = max<i32>(this.poison, 4);
            this.say(api, "POISONED! A MENDING POTION CURES IT", R_MOSS);
        }
    }

    hurtHero(api: GameApi, dmg0: i32, delay: f64, s: i32): void {
        let arm = this.armour == V_MAIL ? 2 : (this.armour == V_LEATHER ? 1 : 0);
        let dmg = max<i32>(1, dmg0 - arm);
        this.aHp[0] -= dmg;
        this.hurtT[0] = api.time + delay;
        this.flashT = api.time + delay;
        this.shakeT = api.time + delay;
        this.popup(this.vX[0], 1.5, this.vZ[0], dmg.toString(), R_RUST, api.time + delay);
        api.sound(SFX_HIT, 0.7, 0.6, 0, delay);
        this.holdBlocked = true;
        if (this.aHp[0] <= 0) this.cause = "A " + K_NAME[this.aKind[s]];
    }

    die(api: GameApi): void {
        this.state = ST_OVER;
        this.stateT = api.time;
        this.holding = false;
        this.aLive[0] = 2;
        this.dieT[0] = api.time + 0.1;
        let better = this.depth > this.bestDepth || (this.depth == this.bestDepth && this.gold > this.bestGold);
        if (better) {
            this.bestDepth = this.depth;
            this.bestGold = this.gold;
            this.newBest = true;
        }
        api.sound(SFX_LOSE, 1.0, 0.6, 0, 0.1);
        api.note(57, 0.35, 0, SFX_BELL, 0.6);
        api.note(52, 0.35, 0, SFX_BELL, 0.95);
        if (this.newBest) {
            const t: StaticArray<i32> = [72, 76, 79, 84];
            for (let i = 0; i < 4; i++) api.note(<f64>t[i], 0.3, 0, SFX_NOTE, 1.5 + 0.09 * <f64>i);
        }
    }

    // ================================================================ the demo player

    demoThink(api: GameApi): void {
        let hx = this.aX[0], hz = this.aZ[0];
        let hp = this.aHp[0], mx = this.aMax[0];
        let mend = this.slotOf(V_MEND), hasteS = this.slotOf(V_HASTE);
        let blinkS = this.slotOf(V_BLINK), sight = this.slotOf(V_SIGHT);
        let adj = -1, adjD = 0, nAdj = 0;
        for (let d = 0; d < 4; d++) {
            let a = this.actorAt(hx + DIRX[d], hz + DIRZ[d]);
            if (a > 0) {
                nAdj++;
                if (adj < 0 || this.aHp[a] < this.aHp[adj]) { adj = a; adjD = d; }
            }
        }
        // drink, read, wield
        if (mend >= 0 && (hp * 10 < mx * 4 || (this.poison > 0 && hp * 2 < mx))) { this.useSlot(api, mend); return; }
        if (blinkS >= 0 && hp * 4 < mx && nAdj > 0) { this.useSlot(api, blinkS); return; }
        if (hasteS >= 0 && nAdj > 0 && (this.aKind[adj] == K_SHELL || nAdj >= 2)) { this.useSlot(api, hasteS); return; }
        if (sight >= 0 && nAdj == 0) {
            let hidden = 0;
            for (let k = 0; k < NROOM; k++) if (this.rOn[k] && !this.rSeen[k]) hidden++;
            if (hidden >= 2) { this.useSlot(api, sight); return; }
        }
        let melee = this.owns(V_AXE) ? V_AXE : (this.owns(V_SWORD) ? V_SWORD : V_DAGGER);
        if (nAdj > 0 && this.weapon == V_SLING) { this.useSlot(api, this.slotOf(melee)); return; }
        if (nAdj == 0 && this.weapon != V_SLING && this.weapon != melee) { this.useSlot(api, this.slotOf(melee)); return; }
        // a monster in line for the sling
        if (this.owns(V_SLING) && nAdj == 0) {
            for (let d = 0; d < 4; d++) {
                for (let r = 2; r <= 5; r++) {
                    let x = hx + DIRX[d] * r, z = hz + DIRZ[d] * r;
                    if (!this.inMap(x, z) || this.tBlock[this.idx(x, z)]) break;
                    let a = this.actorAt(x, z);
                    if (a > 0 && this.aSeen[a]) {
                        if (this.weapon != V_SLING) { this.useSlot(api, this.slotOf(V_SLING)); return; }
                        this.heroDir(api, d);
                        return;
                    }
                    if (a >= 0) break;
                }
            }
        }
        // a slip now and then (a person misclicks too)
        if (api.rand() < 0.06) {
            let d = <i32>(api.rand() * 4.0) % 4;
            if (this.walkable(hx + DIRX[d], hz + DIRZ[d])) { this.heroDir(api, d); return; }
        }
        if (adj > 0) {
            // low and nothing left: run (towards the stairs if known), else fight
            if (hp * 10 < mx * 3 && mend < 0 && api.rand() < 0.6) {
                if (this.demoFlee(api)) return;
            }
            this.heroDir(api, adjD);
            return;
        }
        // goals: a seen monster close by, a seen item, an unseen platform, the stairs
        let goal = -1;
        this.bfs(hx, hz, this.work);
        let bestD = 9999;
        for (let s = 1; s < MAXA; s++) {
            if (this.aLive[s] != 1 || !this.aSeen[s]) continue;
            let d = this.pathTo(this.aX[s], this.aZ[s]);
            if (d > 0 && d <= 4 && d < bestD && hp * 10 >= mx * 3) { bestD = d; goal = this.idx(this.aX[s], this.aZ[s]); }
        }
        if (goal < 0) {
            for (let i = 0; i < MAXI; i++) {
                if (this.iOn[i] != 1 || !this.roomRevealed(this.iX[i], this.iZ[i])) continue;
                let d = this.work[this.idx(this.iX[i], this.iZ[i])];
                if (d > 0 && d < bestD) { bestD = d; goal = this.idx(this.iX[i], this.iZ[i]); }
            }
        }
        if (goal < 0) {
            for (let i = 0; i < MW * MH; i++) {
                let d = this.work[i];
                if (d <= 0 || d >= bestD) continue;
                let k = this.tRoom[i];
                if (k >= 0 && !this.rSeen[k]) { bestD = d; goal = i; }
            }
        }
        if (goal < 0 && this.roomRevealed(this.stairX, this.stairZ)) goal = this.idx(this.stairX, this.stairZ);
        if (goal < 0) goal = this.idx(this.stairX, this.stairZ);
        let d = this.firstStep(goal);
        if (d >= 0) {
            this.heroDir(api, d);
            return;
        }
        this.heroWait(api);
    }

    // Steps from the delver to (x, z) in this.work (a BFS from the delver), through monsters' tiles.
    pathTo(x: i32, z: i32): i32 {
        let best = 9999;
        for (let d = 0; d < 4; d++) {
            let nx = x + DIRX[d], nz = z + DIRZ[d];
            if (!this.inMap(nx, nz)) continue;
            let w = this.work[this.idx(nx, nz)];
            if (w >= 0 && w + 1 < best) best = w + 1;
        }
        return best;
    }

    // The first step on a shortest path to goal (a BFS back from the goal), or -1.
    firstStep(goal: i32): i32 {
        let gx = goal % MW, gz = goal / MW;
        this.bfs(gx, gz, this.back);
        let hx = this.aX[0], hz = this.aZ[0];
        let best = -1, bestD = 9999;
        for (let d = 0; d < 4; d++) {
            let nx = hx + DIRX[d], nz = hz + DIRZ[d];
            if (!this.inMap(nx, nz)) continue;
            let w = this.back[this.idx(nx, nz)];
            if (nx == gx && nz == gz) w = 0;
            if (w < 0) continue;
            let a = this.actorAt(nx, nz);
            if (a > 0 && !(nx == gx && nz == gz)) w += 6;
            if (w < bestD) { bestD = w; best = d; }
        }
        return best;
    }

    demoFlee(api: GameApi): bool {
        let hx = this.aX[0], hz = this.aZ[0];
        let best = -1, bestS = -1;
        for (let d = 0; d < 4; d++) {
            let nx = hx + DIRX[d], nz = hz + DIRZ[d];
            if (!this.walkable(nx, nz) || this.actorAt(nx, nz) >= 0) continue;
            let near = 99;
            for (let s = 1; s < MAXA; s++) {
                if (this.aLive[s] != 1) continue;
                near = min<i32>(near, abs<i32>(this.aX[s] - nx) + abs<i32>(this.aZ[s] - nz));
            }
            if (near > bestS) { bestS = near; best = d; }
        }
        if (best < 0 || bestS < 2) return false;
        this.heroDir(api, best);
        return true;
    }

    // ================================================================ the frame

    update(api: GameApi): void {
        if (api.demoChanged || api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.newRun(api);
        }
        let t = api.time;
        if (this.state == ST_PLAY) {
            if (t >= this.busyUntil && !this.heroReady) this.runWorld(api);
            if (this.state == ST_PLAY && this.canAct(api)) {
                if (api.demo) {
                    if (t >= this.dThink) {
                        this.demoThink(api);
                        this.dThink = t + 0.2;
                    }
                } else if (this.holding && !this.holdBlocked && t >= this.repeatAt && this.hoverSlot < 0) {
                    let d = this.pointerDir(api, api.pointerX, api.pointerY);
                    if (d >= 0 && this.heroDir(api, d)) this.repeatAt = t + 0.24;
                }
            }
        } else if (this.state == ST_DESCEND) {
            if (this.descendPhase == 0 && t - this.stateT >= 1.05) {
                this.depth++;
                this.buildLevel(api);
                this.descendPhase = 1;
                this.arriveT = t;
                this.camX = this.vX[0];
                this.camZ = this.vZ[0];
                this.say(api, "DEPTH " + this.depth.toString() + (this.depth >= 3 ? " - DEEPER, DEADLIER" : ""), R_RUNE);
                api.sound(SFX_THUD, 0.8, 0.5, 0, 0.45);
            }
            if (this.descendPhase == 1 && t - this.arriveT >= 0.55) {
                this.state = ST_PLAY;
                this.stateT = t;
                this.dThink = t + 0.3;
            }
        } else if (this.state == ST_OVER) {
            if (api.demo && t - this.stateT > 2.1) this.newRun(api);
        }
        this.animate(api);
    }

    // ---------------------------------------------------------------- placing every bone

    animate(api: GameApi): void {
        let t = api.time;
        // descending: the old level sinks, the new one arrives
        let sink = 0.0, drop = 0.0;
        if (this.state == ST_DESCEND) {
            if (this.descendPhase == 0) {
                let p = Math.min(1.0, Math.max(0.0, (t - this.stateT - 0.35) / 0.7));
                p = Math.floor(p * 10) / 10;
                sink = -9.0 * p * p;
            } else {
                let p = Math.min(1.0, (t - this.arriveT) / 0.55);
                p = Math.floor(p * 8) / 8;
                drop = 3.5 * (1 - p) * (1 - p);
            }
        }
        // platforms rise out of the dark when first lit
        for (let k = 0; k < NROOM; k++) {
            let b = this.roomBone[k];
            if (!this.rOn[k] || !this.rSeen[k] || t < this.rSeenT[k]) { api.hide(b); continue; }
            let p = Math.min(1.0, (t - this.rSeenT[k]) / 0.5);
            p = Math.floor(p * 6) / 6;
            let y = -4.0 * (1 - p) * (1 - p) * (1 - p) + sink;
            let cx = <f64>this.rX0[k] + <f64>this.rW[k] * 0.5, cz = <f64>this.rZ0[k] + <f64>this.rH[k] * 0.5;
            api.place(b, cx, y, cz, this.rRot[k] ? 90 : 0);
        }
        for (let i = 0; i < NBRIDGE; i++) {
            let b = this.bridgeBone[i];
            if (!this.bOn[i] || !this.bSeen[i] || t < this.bSeenT[i] + 0.1) { api.hide(b); continue; }
            let p = Math.min(1.0, Math.max(0.0, (t - this.bSeenT[i] - 0.1) / 0.5));
            p = Math.floor(p * 6) / 6;
            let y = BRIDGE_Y - 4.0 * (1 - p) * (1 - p) * (1 - p) + sink;
            let along = this.bS[i] + <f64>BRIDGE_LEN * this.bScale[i] * 0.5;
            let across = <f64>this.bLine[i] + 0.5;
            if (this.bVert[i]) api.placeScaled(b, across, y, along, 90, this.bScale[i], 1, 1);
            else api.placeScaled(b, along, y, across, 0, this.bScale[i], 1, 1);
        }
        for (let i = 0; i < NBRAZ; i++) {
            let b = this.brazBone[i];
            if (!this.zOn[i] || !this.roomRevealed(this.zX[i], this.zZ[i])) { api.hide(b); continue; }
            let k = this.tRoom[this.idx(this.zX[i], this.zZ[i])];
            let p = Math.min(1.0, (t - this.rSeenT[k]) / 0.5);
            p = Math.floor(p * 6) / 6;
            let y = -4.0 * (1 - p) * (1 - p) * (1 - p) + sink;
            // the flame flickers (stepped)
            let f = Math.floor(t * 8 + <f64>i * 3);
            let fl = 0.92 + 0.08 * Math.sin(f * 2.1);
            api.placeScaled(this.brazBone[i], <f64>this.zX[i] + 0.5, y, <f64>this.zZ[i] + 0.5, f % 2 == 0 ? 0.0 : 30.0, 1, fl, 1);
        }
        if (this.roomRevealed(this.stairX, this.stairZ)) {
            let k = this.tRoom[this.idx(this.stairX, this.stairZ)];
            let p = Math.min(1.0, (t - this.rSeenT[k]) / 0.5);
            p = Math.floor(p * 6) / 6;
            api.place(this.stairBone, <f64>this.stairX + 0.5, -4.0 * (1 - p) * (1 - p) * (1 - p) + sink, <f64>this.stairZ + 0.5, 0);
        } else {
            api.hide(this.stairBone);
        }
        // items: bob a little; picked ones hop and vanish
        for (let i = 0; i < MAXI; i++) {
            let b = this.iBone[i];
            if (this.iOn[i] == 0 || !this.roomRevealed(this.iX[i], this.iZ[i])) { api.hide(b); continue; }
            let x = <f64>this.iX[i] + 0.5, z = <f64>this.iZ[i] + 0.5;
            let k = this.tRoom[this.idx(this.iX[i], this.iZ[i])];
            let rise = 0.0;
            if (k >= 0) {
                let p = Math.min(1.0, (t - this.rSeenT[k]) / 0.5);
                p = Math.floor(p * 6) / 6;
                rise = -4.0 * (1 - p) * (1 - p) * (1 - p);
            }
            if (this.iOn[i] == 2) {
                let p = (t - this.iT[i]) / 0.3;
                if (p >= 1) { this.iOn[i] = 0; api.hide(b); continue; }
                p = Math.floor(p * 8) / 8;
                api.place(b, x, 0.6 * p + 0.5 * p, z, p * 180, 0, 0, 1 - p * 0.8);
                continue;
            }
            let bob = this.iType[i] == IT_CHEST ? 0.0 : 0.04 * Math.floor(1.5 + 1.5 * Math.sin(t * 3 + <f64>i));
            let yaw = this.iType[i] == IT_SCROLL ? 35 : (this.iType[i] == IT_CHEST ? 0 : <f64>(i * 40));
            api.place(b, x, this.floorY(this.iX[i], this.iZ[i]) + bob + rise + sink, z, yaw);
        }
        // actors
        for (let s = 0; s < MAXA; s++) this.placeActor(api, s, sink, drop);
        // the delver's weapon in his right fist
        for (let w = 0; w < 4; w++) {
            let b = this.weaponBone[w];
            if (w != this.weapon || this.aLive[0] == 0 || (this.state == ST_OVER && t - this.stateT > 0.5)) { api.hide(b); continue; }
            let hb = this.heroBone;
            api.transform(hb, <f64>api.restX[hb] - 0.36, <f64>api.restY[hb] + 0.3, <f64>api.restZ[hb] + 0.05);
            let sw = t - this.swingT;
            let pitch = 30.0;
            if (sw >= 0 && sw < 0.18) {
                let p = Math.floor(sw / 0.18 * 6) / 6;
                pitch = w == V_SLING ? 30 - 40 * Math.sin(p * Math.PI) : 30 + 70 * Math.sin(p * Math.PI);
            }
            api.place(b, api.tx, api.ty, api.tz, this.aYaw[0], pitch, 0, w == V_SLING ? 1.0 : 1.0);
        }
        // projectiles
        for (let p = 0; p < 3; p++) {
            let b = this.pBone[p];
            if (!this.pOn[p]) { api.hide(b); continue; }
            let u = (t - this.pT0[p]) / this.pDur[p];
            if (u >= 1) {
                this.pOn[p] = false;
                api.hide(b);
                this.burst(api, this.pTX[p], 0.5, this.pTZ[p], 2, 0);
                continue;
            }
            let x = this.pFX[p] + (this.pTX[p] - this.pFX[p]) * u;
            let z = this.pFZ[p] + (this.pTZ[p] - this.pFZ[p]) * u;
            api.place(b, x, this.pY[p] + 0.35 * Math.sin(u * Math.PI), z, u * 400);
        }
        // sparks
        for (let i = 0; i < 6; i++) {
            let b = this.sBone[i];
            let age = t - this.sT[i];
            if (this.sT[i] < 0 || age < 0 || age > 0.4) { api.hide(b); continue; }
            let a = Math.floor(age * 30) / 30;
            api.place(b, this.sX[i] + this.sVX[i] * a, this.sY[i] + this.sVY[i] * a - 9 * a * a, this.sZ[i] + this.sVZ[i] * a,
                0, 0, 0, 1 - a * 1.5);
        }
        this.placeMarkers(api);
        // the camera follows the delver, a little behind on the way
        let k = Math.min(1.0, api.dt * 7);
        this.camX += (this.vX[0] - this.camX) * k;
        this.camZ += (this.vZ[0] - this.camZ) * k;
        let shake = 0.0;
        if (t - this.shakeT >= 0 && t - this.shakeT < 0.18) shake = (Math.floor((t - this.shakeT) * 30) % 2 == 0 ? 0.07 : -0.07);
        api.useTarget = true;
        api.targetX = this.camX + shake;
        api.targetY = 0;
        // after a fall the view slides up so the delver lies below the summary
        let over = this.state == ST_OVER ? Math.min(1.0, (t - this.stateT) / 0.6) : 0.0;
        api.targetZ = this.camZ + 0.3 - 1.6 * Math.floor(over * 6) / 6;
    }

    placeActor(api: GameApi, s: i32, sink: f64, drop: f64): void {
        let t = api.time;
        let b = this.aBone[s];
        if (b < 0) return;
        if (this.aLive[s] == 0) { api.hide(b); return; }
        let k = this.aKind[s];
        // where it shows: the tween of its last action
        let y = 0.0, sx = 1.0, sy = 1.0, sz = 1.0, pitch = 0.0, roll = 0.0;
        let x = <f64>this.aX[s] + 0.5, z = <f64>this.aZ[s] + 0.5;
        if (this.anK[s] != AN_NONE) {
            let u = (t - this.anT0[s]) / this.anDur[s];
            if (u < 0) u = 0;
            if (u >= 1) {
                this.anK[s] = AN_NONE;
            } else {
                u = Math.floor(u * 6) / 6;
                if (this.anK[s] == AN_MOVE) {
                    x = this.anFX[s] + (this.anTX[s] - this.anFX[s]) * u;
                    z = this.anFZ[s] + (this.anTZ[s] - this.anFZ[s]) * u;
                    y = 0.16 * Math.sin(u * Math.PI);
                    sy = 1 + 0.12 * Math.sin(u * Math.PI);
                } else {
                    let lunge = 0.4 * Math.sin(u * Math.PI);
                    x = this.anFX[s] + (this.anTX[s] - this.anFX[s]) * lunge;
                    z = this.anFZ[s] + (this.anTZ[s] - this.anFZ[s]) * lunge;
                    sy = 1 - 0.12 * Math.sin(u * Math.PI);
                }
            }
        }
        this.vX[s] = x;
        this.vZ[s] = z;
        let fy = this.floorY(<i32>Math.floor(x), <i32>Math.floor(z));
        // a monster outside the light is not drawn; one just seen pops up
        if (s > 0 && this.aLive[s] == 1 && !this.aSeen[s]) { api.hide(b); return; }
        let scale = 1.0;
        if (k == K_OOZE && this.aGen[s] == 1) scale = 0.72;
        if (s > 0) {
            let ap = (t - this.seenT[s]) / 0.15;
            if (ap >= 0 && ap < 1) scale *= 0.4 + 0.6 * Math.floor(ap * 4) / 4;
        }
        // hurt: a squash and a shake
        let h = t - this.hurtT[s];
        if (h >= 0 && h < 0.2) {
            let q = Math.floor(h * 30);
            sx = 1.15; sz = 1.15; sy *= 0.8;
            x += (q % 2 == 0 ? 0.05 : -0.05);
        }
        // idle life: flitters flap, oozes wobble, the delver breathes (all stepped)
        let f = Math.floor(t * 8 + <f64>s * 1.7);
        if (k == K_FLITTER) {
            y += K_FLY[k] + 0.06 * Math.sin(f * 0.9);
            sx *= f % 2 == 0 ? 1.0 : 0.6;
        } else if (k == K_OOZE) {
            let w = 0.06 * Math.sin(f * 0.8);
            sx *= 1 + w; sz *= 1 + w; sy *= 1 - w;
        } else if (k == K_SKITTER) {
            y += f % 2 == 0 ? 0 : 0.02;
        } else if (k == K_HERO && this.anK[0] == AN_NONE) {
            sy *= f % 8 < 4 ? 1.0 : 0.97;
        }
        // dying: squash flat, sink and vanish
        if (this.aLive[s] == 2) {
            let d = t - this.dieT[s];
            if (s > 0 && d > 0.35) {
                this.aLive[s] = 0;
                api.hide(b);
                return;
            }
            if (d > 0) {
                if (s == 0) {
                    let p = Math.min(1.0, d / 0.5);
                    p = Math.floor(p * 6) / 6;
                    roll = 90 * p;
                    y -= 0.25 * p;
                } else {
                    let p = Math.floor(d / 0.35 * 5) / 5;
                    sy *= 1 - 0.85 * p;
                    sx *= 1 + 0.4 * p; sz *= 1 + 0.4 * p;
                }
            }
        }
        if (s == 0) {
            if (this.state == ST_DESCEND) {
                if (this.descendPhase == 0) {
                    let p = Math.min(1.0, Math.max(0.0, (t - this.stateT) / 0.4));
                    p = Math.floor(p * 6) / 6;
                    y -= 1.2 * p * p;
                    scale = 1 - 0.6 * p;
                    if (p >= 1) { api.hide(b); return; }
                } else {
                    y += drop;
                }
            }
        } else {
            y += sink;
        }
        api.placeScaled(b, x, fy + y, z, this.aYaw[s], sx * scale, sy * scale, sz * scale, pitch, roll);
    }

    placeMarkers(api: GameApi): void {
        this.tgtKind = 0;
        // the marker shows what a press there does: under a finger while it is down (touch: the pointer
        // only moves then), and under a hovering mouse
        let show = this.state == ST_PLAY && this.heroReady && !api.demo && this.hoverSlot < 0 && api.pointerX >= 0 &&
            (api.pointerDown || this.hoverSeen);
        if (api.demo && this.state == ST_PLAY && this.heroReady) show = false;
        if (show) {
            let d = this.pointerDir(api, api.pointerX, api.pointerY);
            if (d == -1) {
                this.tgtKind = 4;
                this.tgtX = this.aX[0];
                this.tgtZ = this.aZ[0];
            } else if (d >= 0) {
                this.tgtKind = this.planDir(d);
            }
        }
        let pulse = Math.floor(api.time * 4) % 2 == 0 ? 1.0 : 0.94;
        if (this.tgtKind == 1 || this.tgtKind == 4) {
            let y = this.floorY(this.tgtX, this.tgtZ);
            let yaw = this.tgtKind == 4 ? 0 : Math.atan2(<f64>DIRX[this.tgtDir], <f64>DIRZ[this.tgtDir]) * 180 / Math.PI;
            api.placeScaled(this.markBone, <f64>this.tgtX + 0.5, y, <f64>this.tgtZ + 0.5, yaw, pulse, 1, pulse);
        } else {
            api.hide(this.markBone);
        }
        if (this.tgtKind == 2 || this.tgtKind == 3) {
            let y = this.floorY(this.tgtX, this.tgtZ);
            api.placeScaled(this.atkBone, <f64>this.tgtX + 0.5, y, <f64>this.tgtZ + 0.5, 0, pulse, 1, pulse);
        } else {
            api.hide(this.atkBone);
        }
    }

    // ================================================================ input

    slotAt(api: GameApi, x: f32, y: f32): i32 {
        let x0 = <f32>((api.hudW - (NSLOT * SLOT_STEP - 2)) / 2);
        let y0 = <f32>(api.hudH - SLOT - 3);
        if (y < y0 - 1 || y > y0 + <f32>SLOT) return -1;
        let i = <i32>Mathf.floor((x - x0 + 1) / <f32>SLOT_STEP);
        if (i < 0 || i >= NSLOT) return -1;
        return i;
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        this.hoverSlot = this.slotAt(api, x, y);
        if (kind == POINTER_DOWN) {
            if (this.state == ST_OVER) {
                if (api.time - this.stateT > 0.9) this.newRun(api);
                return true;
            }
            if (this.hoverSlot >= 0) {
                if (this.canAct(api) && this.invK[this.hoverSlot] >= 0) this.useSlot(api, this.hoverSlot);
                return true;
            }
            this.holding = true;
            this.holdBlocked = false;
            this.repeatAt = api.time + 0.3;
            if (this.canAct(api)) {
                let d = this.pointerDir(api, x, y);
                this.heroDir(api, d);
            }
            return true;
        }
        if (kind == POINTER_UP) {
            this.holding = false;
            this.holdBlocked = false;
            this.hoverSlot = -1;
        } else if (kind == POINTER_MOVE && !api.pointerDown) {
            this.hoverSeen = true;
        }
        return true;
    }

    // ================================================================ HUD

    iconColor(api: GameApi, c: i32): u32 {
        if (c == 119) return api.rampColor(R_BONE, 2);      // w  blade
        if (c == 97) return api.rampColor(R_BRASS, 2);      // a  brass guard
        if (c == 107) return api.rampColor(R_WOOD, 1);      // k  grip, cork, scroll ends
        if (c == 115) return api.rampColor(R_STONE, 4);     // s  steel
        if (c == 98) return api.rampColor(R_STONE, 2);      // b  dark steel
        if (c == 114) return api.rampColor(R_CLOAK, 3);     // r  mending (lime), the sight scroll's mark
        if (c == 99) return api.rampColor(R_BRASS, 2);      // c  haste (khaki), the blink scroll's mark
        if (c == 103) return api.rampColor(R_BONE, 1);      // g  glass
        if (c == 112) return api.rampColor(R_WOOD, 4);      // p  paper
        return 0;
    }

    icon(api: GameApi, x: f32, y: f32, v: i32): void {
        let s = ICONS[v];
        for (let i = 0; i < 81 && i < s.length; i++) {
            let c = s.charCodeAt(i);
            if (c == 46) continue;
            let col = this.iconColor(api, c);
            if (v == V_LEATHER && c == 119) col = api.rampColor(R_WOOD, 2);
            if (v == V_SLING && c == 119) col = api.rampColor(R_WOOD, 2);
            if (v == V_SLING && c == 114) col = api.rampColor(R_BRASS, 2);
            if (v == V_AXE && c == 119) col = api.rampColor(R_WOOD, 2);
            api.rect(x + <f32>(i % 9), y + <f32>(i / 9), 1, 1, col);
        }
    }

    // the HUD colour of a message or a floating number of ramp `r` (legible over the scene with the ink shadow)
    tone(api: GameApi, r: i32): u32 {
        if (r == R_STONE) return api.rampColor(R_STONE, 5);   // pale sage-grey
        if (r == R_BRASS) return api.rampColor(R_BRASS, 2);   // khaki: gold, finds, blows dealt
        if (r == R_CLOAK) return api.rampColor(R_CLOAK, 4);   // lime: mending
        if (r == R_RUNE) return api.rampColor(R_RUNE, 1);     // lime: the depths
        if (r == R_MOSS) return api.rampColor(R_MOSS, 4);     // grey-green: poison
        if (r == R_RUST) return api.rampColor(R_RUST, 2);     // brown: blows taken, the ooze
        if (r == R_GLOOM) return api.rampColor(R_STONE, 4);   // warm grey: blink
        if (r == R_BONE) return api.rampColor(R_BONE, 3);     // cream: haste
        return api.rampColor(r, 3);
    }

    bar(api: GameApi, x: f32, y: f32, w: f32, h: f32, frac: f64, fg: u32, bg: u32): void {
        api.rect(x - 1, y - 1, w + 2, h + 2, api.rampColor(R_DEEP, 0));
        api.rect(x, y, w, h, bg);
        let fw = <f32>Math.round(<f64>w * Math.min(1.0, Math.max(0.0, frac)));
        if (fw > 0) api.rect(x, y, fw, h, fg);
    }

    hud(api: GameApi): void {
        let t = api.time;
        let W = <f32>api.hudW, H = <f32>api.hudH;
        let ink = api.rampColor(R_DEEP, 0);
        let white = api.rampColor(R_BONE, 3);     // cream
        let grey = api.rampColor(R_STONE, 4);     // warm grey
        let amber = api.rampColor(R_BRASS, 2);    // khaki: gold, the worn and wielded frames
        let life = api.rampColor(R_CLOAK, 3);     // lime: the delver's life
        let foe = api.rampColor(R_RUST, 3);       // khaki on rust: a monster's life
        let lime = api.rampColor(R_RUNE, 1);      // bright lime: the depth
        let pale = api.rampColor(R_BONE, 2);      // pale sage: energy
        // monsters' life and energy, over their heads
        for (let s = 1; s < MAXA; s++) {
            if (this.aLive[s] != 1 || !this.aSeen[s]) continue;
            let k = this.aKind[s];
            let sc = k == K_OOZE && this.aGen[s] == 1 ? 0.72 : 1.0;
            if (!api.project(<f32>this.vX[s], <f32>(this.floorY(this.aX[s], this.aZ[s]) + K_TOP[k] * sc + 0.25), <f32>this.vZ[s])) continue;
            let x = Mathf.round(api.screenX) - 5, y = Mathf.round(api.screenY) - 4;
            this.bar(api, x, y, 10, 1, <f64>this.aHp[s] / <f64>this.aMax[s], foe, api.rampColor(R_RUST, 1));
            this.bar(api, x, y + 2, 10, 1, <f64>this.aEn[s] / 100.0, pale, api.rampColor(R_DEEP, 2));
        }
        // floating numbers
        for (let i = 0; i < 8; i++) {
            let a = t - this.fT[i];
            if (a < 0 || a > 0.8) continue;
            if (!api.project(<f32>this.fX[i], <f32>(this.fY[i] + Math.floor(a * 10) * 0.06), <f32>this.fZ[i])) continue;
            let s = this.fS[i];
            api.text(Mathf.round(api.screenX - api.textWidth(s, 1) * 0.5), Mathf.round(api.screenY), s,
                this.tone(api, this.fC[i]), 1, ink);
        }
        // a red edge when hurt
        if (t - this.flashT >= 0 && t - this.flashT < 0.16) {
            let c = api.rampColor(R_RUST, 2);
            api.rect(0, 0, W, 2, c);
            api.rect(0, H - 2, W, 2, c);
            api.rect(0, 0, 2, H, c);
            api.rect(W - 2, 0, 2, H, c);
        }
        // top bar: life, energy, depth, gold, level
        let hp = <f64>max<i32>(0, this.aHp[0]) / <f64>this.aMax[0];
        api.text(3, 3, "HP", white, 1, ink);
        this.bar(api, 13, 3, 40, 5, hp, hp < 0.3 && Math.floor(t * 4) % 2 == 0 ? amber : life, api.rampColor(R_CLOAK, 1));
        api.text(56, 3, max<i32>(0, this.aHp[0]).toString() + "/" + this.aMax[0].toString(), white, 1, ink);
        let en = Math.min(1.0, <f64>max<i32>(0, this.aEn[0]) / 100.0);
        this.bar(api, 13, 10, 40, 1, en, this.haste > 0 ? white : pale, api.rampColor(R_DEEP, 2));
        let tags = "";
        if (this.poison > 0) tags += "POISON ";
        if (this.haste > 0) tags += "HASTE";
        if (tags.length > 0) api.text(56, 9, tags, this.poison > 0 ? this.tone(api, R_MOSS) : white, 1, ink);
        let right = "DEPTH " + this.depth.toString();
        api.text(W - 3 - api.textWidth(right, 1), 3, right, lime, 1, ink);
        let g = "GOLD " + this.gold.toString() + "  LV " + this.level.toString();
        api.text(W - 3 - api.textWidth(g, 1), 10, g, amber, 1, ink);
        // the inventory bar
        let x0 = <f32>((api.hudW - (NSLOT * SLOT_STEP - 2)) / 2);
        let y0 = H - <f32>SLOT - 3;
        for (let i = 0; i < NSLOT; i++) {
            let x = x0 + <f32>(i * SLOT_STEP);
            let v = this.invK[i];
            let eq = v >= 0 && (v == this.weapon || v == this.armour);
            let border = eq ? amber : (i == this.hoverSlot ? grey : api.rampColor(R_DEEP, 3));
            let q = <f32>SLOT;
            api.rect(x - 1, y0 - 1, q + 2, q + 2, ink);
            api.rect(x, y0, q, q, border);
            api.rect(x + 1, y0 + 1, q - 2, q - 2, api.rampColor(R_DEEP, 2));
            if (v >= 0) {
                this.icon(api, x + 3, y0 + 3, v);
                if (this.invN[i] > 1) api.text(x + q - 5, y0 + q - 6, this.invN[i].toString(), white, 1, ink);
            }
        }
        // messages (and the hint before the first step)
        let my = y0 - 9;
        if (this.state == ST_PLAY && !this.started && !api.demo) {
            api.textCentered(my - 8, "TAP OR CLICK BESIDE THE DELVER TO STEP", white, 1, ink);
            api.textCentered(my, "WALK INTO MONSTERS TO FIGHT, HOLD TO KEEP GOING", grey, 1, ink);
        } else if (this.hoverSlot >= 0 && this.invK[this.hoverSlot] >= 0 && !api.demo) {
            let v = this.invK[this.hoverSlot];
            api.textCentered(my, V_NAME[v] + " - " + V_INFO[v], white, 1, ink);
        } else if (t - this.msgT < 4.5) {
            if (t - this.msgT < 2.5 && this.msg1.length > 0) api.textCentered(my - 7, this.msg1, grey, 1, ink);
            api.textCentered(my, this.msg0, this.tone(api, this.msgC), 1, ink);
        }
        if (api.demo) api.text(3, 16, "DEMO", grey, 1, ink);
        // game over
        if (this.state == ST_OVER && t - this.stateT > 0.6) {
            let py = 27.0;
            api.rect(14, <f32>py - 6, W - 28, 58, ink);
            api.rect(15, <f32>py - 5, W - 30, 56, api.rampColor(R_DEEP, 2));
            api.textCentered(<f32>py, "YOU FELL ON DEPTH " + this.depth.toString(), amber, 2, ink);
            api.textCentered(<f32>py + 14, "SLAIN BY " + this.cause, white, 1, ink);
            api.textCentered(<f32>py + 22, "GOLD " + this.gold.toString() + "   KILLS " + this.kills.toString() + "   LEVEL " + this.level.toString(), amber, 1, ink);
            api.textCentered(<f32>py + 32, (this.newBest ? "NEW BEST! " : "BEST ") + "DEPTH " + this.bestDepth.toString() + ", GOLD " + this.bestGold.toString(), lime, 1, ink);
            if (!api.demo && t - this.stateT > 0.9) api.textCentered(<f32>py + 42, "TAP TO DELVE AGAIN", white, 1, ink);
        }
    }
}
