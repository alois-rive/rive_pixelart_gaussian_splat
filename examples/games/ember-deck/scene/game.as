// Ember Deck: a small deckbuilding card battler in a candle-lit crypt. The Wick Knight (left) fights
// one foe at a time (right): a run of four fights, the Tallow King last. Cards live on the HUD (drawn
// in call order on the art grid); the 3D figures, the effects and the candles are game bones.
//
// A turn: 3 energy, draw 5; tap a card to play it (its cost in the gem); END TURN discards the hand
// and the foe acts on the intent shown over its head. After a win choose 1 of 3 new cards (or skip);
// HP carries over. Pointer only, and every control acts on the press, so touch plays the same.
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP,
         SFX_BLIP, SFX_COIN, SFX_HIT, SFX_EXPLODE, SFX_POWERUP, SFX_THUD, SFX_WHOOSH, SFX_BELL,
         SFX_LOSE, SFX_WIN, SFX_TICK, SFX_CLICK, SFX_ZAP, SFX_NOTE } from "./game_api";

// ------------------------------------------------------------------ cards
const ATK: i32 = 0;
const BLK: i32 = 1;
const SPL: i32 = 2;
const N_CARDS: i32 = 16;
const C_NAME: StaticArray<string> = ["STRIKE", "GUARD", "CLEAVE", "JAB", "TWINCUT", "BULWARK", "RIPOSTE", "KINDLE",
    "BLAZE", "WITHER", "PONDER", "SALVE", "SURGE", "SEAR", "SMITE", "TEMPER"];
const C_COST: StaticArray<i32> = [1, 1, 2, 0, 1, 2, 1, 1, 2, 1, 0, 1, 0, 1, 3, 1];
const C_TYPE: StaticArray<i32> = [ATK, BLK, ATK, ATK, ATK, BLK, BLK, SPL, SPL, SPL, SPL, SPL, SPL, ATK, ATK, SPL];
const C_DMG: StaticArray<i32> = [6, 0, 13, 4, 4, 0, 5, 0, 0, 0, 0, 0, 0, 5, 24, 0];
const C_HITS: StaticArray<i32> = [1, 0, 1, 1, 2, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0];
const C_BLOCK: StaticArray<i32> = [0, 5, 0, 0, 0, 12, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0];
const C_BURN: StaticArray<i32> = [0, 0, 0, 0, 0, 0, 0, 4, 9, 0, 0, 0, 0, 2, 0, 0];
const C_WEAK: StaticArray<i32> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0];
const C_DRAW: StaticArray<i32> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1, 0, 0, 0];
const C_HEAL: StaticArray<i32> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0];
const C_ENERGY: StaticArray<i32> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0];
const C_STR: StaticArray<i32> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2];
const C_ONCE: StaticArray<bool> = [false, false, false, false, false, false, false, false, false, false, false, true,
    true, false, false, false];
// the card's picture (ICONS) and the big number on it
const C_ICON: StaticArray<i32> = [0, 1, 0, 0, 0, 1, 1, 2, 2, 3, 5, 4, 6, 2, 0, 7];
const C_BIG: StaticArray<i32> = [6, 5, 13, 4, 4, 12, 5, 4, 9, 2, 2, 7, 1, 5, 24, 2];
const C_SUB: StaticArray<string> = ["DAMAGE", "BLOCK", "DAMAGE", "DAMAGE", "DMG X2", "BLOCK", "+5 DMG", "BURN",
    "BURN", "WEAKEN", "DRAW", "HEAL", "ENERGY", "+BURN 2", "DAMAGE", "+STR"];
// how much the demo player likes a reward (higher: picked more often)
const C_RATE: StaticArray<f64> = [1, 1, 6, 4, 6, 5, 5, 5, 7, 4, 4, 5, 3, 6, 6, 6];
const STARTER: StaticArray<i32> = [0, 0, 0, 0, 0, 1, 1, 1, 1, 7];

// 9 x 9 icons, one string a row ('#' set): sword, shield, flame, skull, heart, cards, bolt, fist
const ICONS: StaticArray<string> = [
    "       ##", "      ###", "     ### ", "#   ###  ", " # ###   ", "  ###    ", "  ##     ", " #  #    ", "#        ",
    " ####### ", " #     # ", " # ### # ", " # ### # ", " #  #  # ", "  #   #  ", "  #   #  ", "   # #   ", "    #    ",
    "    #    ", "   ##    ", "   ###   ", "  ####   ", "  ## ##  ", " ##  ### ", " #    ## ", " ##  ### ", "  #####  ",
    "  #####  ", " ####### ", " #  #  # ", " #  #  # ", " ####### ", "  ## ##  ", "  #####  ", "  # # #  ", "         ",
    "         ", " ### ### ", "#########", "#########", " ####### ", "  #####  ", "   ###   ", "    #    ", "         ",
    "  ###### ", "  #    # ", "#####  # ", "#   #  # ", "#   #  # ", "#   #### ", "#   #    ", "#####    ", "         ",
    "     ### ", "    ###  ", "   ###   ", "  ###### ", "     ### ", "    ###  ", "   ##    ", "  ##     ", " #       ",
    "    #    ", "   ###   ", "  #####  ", " ### ### ", "   ###   ", "   ###   ", "   ###   ", "   ###   ", "         "];
const IC_SWORD: i32 = 0;
const IC_SHIELD: i32 = 1;
const IC_SKULL: i32 = 3;
const IC_UP: i32 = 7;

// ------------------------------------------------------------------ foes
const N_FIGHTS: i32 = 4;
const F_NAME: StaticArray<string> = ["WAX MITE", "CRYPT MOTH", "GRAVE WARDEN", "TALLOW KING"];
const F_HP: StaticArray<i32> = [30, 36, 52, 100];
const F_TOP: StaticArray<f64> = [1.45, 2.05, 2.3, 3.2];     // where the intent floats (metres above the floor)
const F_MID: StaticArray<f64> = [0.5, 1.35, 1.1, 1.5];     // where hits land
const I_ATK: i32 = 0;
const I_DEF: i32 = 1;
const I_BUFF: i32 = 2;
const I_HEX: i32 = 3;

// ------------------------------------------------------------------ the stage
const HERO_X: f64 = -2.2;
const FOE_X: f64 = 2.2;
const HERO_YAW: f64 = 50;
const FOE_YAW: f64 = -40;
const TEXEL: f64 = 6.0 / 136.0;
const HERO_HP: i32 = 60;

// phases
const P_DEAL: i32 = 0;
const P_PLAYER: i32 = 1;
const P_RESOLVE: i32 = 2;
const P_FOE: i32 = 3;
const P_WIN: i32 = 4;
const P_REWARD: i32 = 5;
const P_ENTER: i32 = 6;
const P_VICTORY: i32 = 7;
const P_DEFEAT: i32 = 8;

// figure animations
const A_NONE: i32 = 0;
const A_ATTACK: i32 = 1;
const A_BLOCK: i32 = 2;
const A_CAST: i32 = 3;
const A_HURT: i32 = 4;
const A_DIE: i32 = 5;
const A_BUFF: i32 = 6;
const A_CHEER: i32 = 7;

// the hand's layout on the HUD
const CARD_W: f32 = 30;
const CARD_H: f32 = 42;
const HAND_Y: f32 = 89;
const HAND_X0: f32 = 23;
const HAND_X1: f32 = 181;     // the last card's right edge at most
const BTN_X: f32 = 184;
const BTN_Y: f32 = 100;
const BTN_W: f32 = 27;
const BTN_H: f32 = 24;
const MAX_HAND: i32 = 8;
const PILE_X: f32 = 4;
const PILE_Y: f32 = 112;

function smooth(t: f64): f64 {
    let x = Math.min(Math.max(t, 0), 1);
    return x * x * (3 - 2 * x);
}

function hash(a: i32, b: i32): f64 {
    let h: u32 = <u32>(a * 374761393 + b * 668265263);
    h = (h ^ (h >> 13)) * 1274126177;
    h = h ^ (h >> 16);
    return <f64>(h & 0xffff) / 65536.0;
}

export class Game {
    // bones
    hero: i32 = -1; armR: i32 = -1; armL: i32 = -1;
    foeBone: StaticArray<i32> = new StaticArray<i32>(4);
    wingL: i32 = -1; wingR: i32 = -1; kingFire: i32 = -1;
    flames: StaticArray<i32> = new StaticArray<i32>(7);
    slash: StaticArray<i32> = new StaticArray<i32>(2);
    spark: StaticArray<i32> = new StaticArray<i32>(10);
    mote: StaticArray<i32> = new StaticArray<i32>(8);
    burnB: StaticArray<i32> = new StaticArray<i32>(3);
    ward: i32 = -1; fward: i32 = -1;

    // colours (filled each hud())
    cInk: u32 = 0; cNight: u32 = 0; cPlum: u32 = 0; cWine: u32 = 0; cMaroon: u32 = 0; cCrimson: u32 = 0;
    cRed: u32 = 0; cNavy: u32 = 0; cBlue: u32 = 0; cCyan: u32 = 0;

    // the run
    deck: Array<i32> = new Array<i32>();
    drawPile: Array<i32> = new Array<i32>();
    discard: Array<i32> = new Array<i32>();
    hand: Array<i32> = new Array<i32>();
    handX: Array<f64> = new Array<f64>();     // where each hand card is drawn now (HUD px)
    handY: Array<f64> = new Array<f64>();
    handT: Array<f64> = new Array<f64>();     // when it was dealt (it slides in from the pile)
    fight: i32 = 0;
    hp: i32 = HERO_HP;
    block: i32 = 0;
    energy: i32 = 3;
    weak: i32 = 0;
    str: i32 = 0;
    foe: i32 = 0;
    foeHp: i32 = 0;
    foeMax: i32 = 0;
    foeBlock: i32 = 0;
    foeWeak: i32 = 0;
    foeBurn: i32 = 0;
    foeStr: i32 = 0;
    foeTurn: i32 = 0;
    intent: i32 = 0;
    intentVal: i32 = 0;
    intentHits: i32 = 1;
    lastIntent: i32 = -1;
    turns: i32 = 0;
    dealt: i32 = 0;           // damage dealt this run
    played: i32 = 0;          // cards played this run
    slain: i32 = 0;
    score: i32 = 0;
    best: i32 = 0;
    won: bool = false;
    firstPlay: bool = true;   // the hint until the first card of a run

    // phase machine
    phase: i32 = P_DEAL;
    pt: f64 = 0;              // seconds in this phase
    pdt: f64 = 0;             // this frame's step (for crossed())
    dealN: i32 = 0;           // cards still to deal
    dealNext: f64 = 0;
    playing: i32 = -1;        // the card being resolved
    playFromX: f64 = 0;
    playFromY: f64 = 0;
    hitsDone: i32 = 0;
    rewards: StaticArray<i32> = new StaticArray<i32>(3);
    pickedReward: i32 = -1;
    endTime: f64 = 0;

    // figures
    heroAnim: i32 = A_NONE; heroAT: f64 = 0; heroHits: i32 = 1;
    foeAnim: i32 = A_NONE; foeAT: f64 = 0; foeHits: i32 = 1;
    wardPop: f64 = -10; fwardPop: f64 = -10;
    shake: f64 = 0;
    baseTX: f64 = 0; baseTY: f64 = 0;
    // particles
    sx: StaticArray<f64> = new StaticArray<f64>(10); sy: StaticArray<f64> = new StaticArray<f64>(10);
    sz: StaticArray<f64> = new StaticArray<f64>(10); svx: StaticArray<f64> = new StaticArray<f64>(10);
    svy: StaticArray<f64> = new StaticArray<f64>(10); svz: StaticArray<f64> = new StaticArray<f64>(10);
    sl: StaticArray<f64> = new StaticArray<f64>(10); sg: StaticArray<f64> = new StaticArray<f64>(10);
    mx: StaticArray<f64> = new StaticArray<f64>(8); my: StaticArray<f64> = new StaticArray<f64>(8);
    mz: StaticArray<f64> = new StaticArray<f64>(8); mvx: StaticArray<f64> = new StaticArray<f64>(8);
    mvy: StaticArray<f64> = new StaticArray<f64>(8); mvz: StaticArray<f64> = new StaticArray<f64>(8);
    ml: StaticArray<f64> = new StaticArray<f64>(8);
    slashT: StaticArray<f64> = new StaticArray<f64>(2);
    slashRoll: StaticArray<f64> = new StaticArray<f64>(2);
    nextSlash: i32 = 0;
    // floating numbers
    ftX: Array<f64> = new Array<f64>(); ftY: Array<f64> = new Array<f64>(); ftZ: Array<f64> = new Array<f64>();
    ftT: Array<f64> = new Array<f64>(); ftS: Array<string> = new Array<string>(); ftC: Array<i32> = new Array<i32>();
    // demo
    demoWait: f64 = 0;
    // pointer
    hoverCard: i32 = -1;
    pressCard: i32 = -1;
    pressT: f64 = -10;
    denyCard: i32 = -1;
    denyT: f64 = -10;
    lastTime: f64 = 0;
    time: f64 = 0;

    // ============================================================== setup
    start(api: GameApi): void {
        api.playable = true;
        this.hero = api.bone("hero");
        this.armR = api.bone("armr");
        this.armL = api.bone("arml");
        this.foeBone[0] = api.bone("mite");
        this.foeBone[1] = api.bone("moth");
        this.foeBone[2] = api.bone("warden");
        this.foeBone[3] = api.bone("king");
        this.wingL = api.bone("wingl");
        this.wingR = api.bone("wingr");
        this.kingFire = api.bone("kingfire");
        for (let i = 0; i < 5; i++) this.flames[i] = api.bone("flame" + i.toString());
        this.flames[5] = api.bone("soul0");
        this.flames[6] = api.bone("soul1");
        for (let i = 0; i < 2; i++) this.slash[i] = api.bone("slash" + i.toString());
        for (let i = 0; i < 10; i++) this.spark[i] = api.bone("spark" + i.toString());
        for (let i = 0; i < 8; i++) this.mote[i] = api.bone("mote" + i.toString());
        for (let i = 0; i < 3; i++) this.burnB[i] = api.bone("burn" + i.toString());
        this.ward = api.bone("ward");
        this.fward = api.bone("fward");
        this.baseTX = api.targetX;
        this.baseTY = api.targetY;
        for (let i = 0; i < 2; i++) this.slashT[i] = -10;
        this.newRun(api);
    }

    // ============================================================== the run
    newRun(api: GameApi): void {
        this.deck.length = 0;
        for (let i = 0; i < STARTER.length; i++) this.deck.push(STARTER[i]);
        this.hp = HERO_HP;
        this.str = 0;
        this.weak = 0;
        this.turns = 0;
        this.dealt = 0;
        this.played = 0;
        this.slain = 0;
        this.won = false;
        this.firstPlay = true;
        this.ftX.length = 0; this.ftY.length = 0; this.ftZ.length = 0; this.ftT.length = 0; this.ftS.length = 0; this.ftC.length = 0;
        for (let i = 0; i < 10; i++) this.sl[i] = 0;
        for (let i = 0; i < 8; i++) this.ml[i] = 0;
        this.heroAnim = A_NONE;
        this.startFight(api, 0, false);
        if (api.demo) {
            // the demo opens mid-fight: the hand already dealt, the mite already singed, and a card
            // about to be played
            this.foeHp = 19;
            this.foeBurn = 2;
            this.hp = 54;
            this.turns = 2;
            this.dealHandNow(api, 5);
            this.firstPlay = false;
            this.setPhase(P_PLAYER);
            this.demoWait = 0.3;
        }
    }

    startFight(api: GameApi, f: i32, enter: bool): void {
        this.fight = f;
        this.foe = f;
        this.foeMax = F_HP[f];
        this.foeHp = this.foeMax;
        this.foeBlock = 0;
        this.foeWeak = 0;
        this.foeBurn = 0;
        this.foeStr = 0;
        this.foeTurn = 0;
        this.lastIntent = -1;
        this.block = 0;
        this.weak = 0;
        this.str = 0;
        this.foeAnim = A_NONE;
        // a fresh draw pile: the whole deck, shuffled
        this.drawPile.length = 0;
        this.discard.length = 0;
        this.hand.length = 0; this.handX.length = 0; this.handY.length = 0; this.handT.length = 0;
        for (let i = 0; i < this.deck.length; i++) this.drawPile.push(this.deck[i]);
        this.shuffle(api, this.drawPile);
        this.chooseIntent(api);
        if (enter) {
            this.setPhase(P_ENTER);
        } else {
            this.beginTurn(api);
        }
    }

    shuffle(api: GameApi, a: Array<i32>): void {
        for (let i = a.length - 1; i > 0; i--) {
            let j = <i32>Math.floor(api.rand() * <f64>(i + 1));
            if (j > i) j = i;
            let t = a[i]; a[i] = a[j]; a[j] = t;
        }
    }

    setPhase(p: i32): void {
        this.phase = p;
        this.pt = 0;
    }

    beginTurn(api: GameApi): void {
        this.turns++;
        this.block = 0;
        this.energy = 3;
        this.dealN = 5;
        this.dealNext = 0.15;
        this.setPhase(P_DEAL);
        api.note(76, 0.35, -0.4, SFX_BELL);
        api.note(83, 0.25, -0.4, SFX_BELL, 0.09);
    }

    // takes one card from the draw pile (reshuffling the discard when it runs out); -1 when none
    drawOne(api: GameApi): i32 {
        if (this.hand.length >= MAX_HAND) return -1;
        if (this.drawPile.length == 0) {
            if (this.discard.length == 0) return -1;
            for (let i = 0; i < this.discard.length; i++) this.drawPile.push(this.discard[i]);
            this.discard.length = 0;
            this.shuffle(api, this.drawPile);
            api.sound(SFX_WHOOSH, 1.6, 0.35, -0.8);
        }
        let c = this.drawPile.pop();
        this.hand.push(c);
        this.handX.push(<f64>PILE_X);
        this.handY.push(<f64>PILE_Y);
        this.handT.push(this.time);
        return c;
    }

    dealHandNow(api: GameApi, n: i32): void {
        for (let i = 0; i < n; i++) this.drawOne(api);
        this.layoutHand(true);
    }

    // the x of hand slot i of n
    slotX(i: i32, n: i32): f64 {
        if (n <= 1) return <f64>HAND_X0;
        let step = Math.min(32.0, <f64>(HAND_X1 - HAND_X0 - CARD_W) / <f64>(n - 1));
        let w = step * <f64>(n - 1) + <f64>CARD_W;
        let x0 = <f64>HAND_X0 + Math.max(0, (<f64>(HAND_X1 - HAND_X0) - w) * 0.5);
        return x0 + step * <f64>i;
    }

    layoutHand(snap: bool): void {
        let n = this.hand.length;
        for (let i = 0; i < n; i++) {
            let tx = this.slotX(i, n);
            let ty = <f64>HAND_Y;
            if (snap) {
                this.handX[i] = tx; this.handY[i] = ty;
            }
        }
    }

    // ============================================================== damage
    heroDamage(base: i32): i32 {
        let d = base + this.str;
        if (this.weak > 0) d = <i32>Math.floor(<f64>d * 0.75);
        return max<i32>(d, 0);
    }

    foeDamage(base: i32): i32 {
        let d = base + this.foeStr;
        if (this.foeWeak > 0) d = <i32>Math.floor(<f64>d * 0.75);
        return max<i32>(d, 0);
    }

    // the hero hits the foe: block first, then HP
    hitFoe(api: GameApi, d: i32): void {
        let fx = this.foeX(), fy = F_MID[this.foe];
        let absorbed = min<i32>(this.foeBlock, d);
        this.foeBlock -= absorbed;
        let dmg = d - absorbed;
        this.foeHp -= dmg;
        this.dealt += dmg;
        if (dmg > 0) {
            this.addFloat(fx, fy + 0.6, 0.3, "-" + dmg.toString(), 0);
            this.foeAnim = A_HURT; this.foeAT = 0;
            let p = 1.35 - Math.min(<f64>dmg, 24) / 40.0;
            api.soundAt(SFX_HIT, fx, fy, 0, p, 0.55 + Math.min(<f64>dmg, 24) / 40.0);
            if (dmg >= 12) {
                api.soundAt(SFX_THUD, fx, fy, 0, 0.8, 0.8);
                this.shake = 0.25;
            } else {
                this.shake = Math.max(this.shake, 0.12);
            }
        } else {
            this.addFloat(fx, fy + 0.6, 0.3, "BLOCKED", 2);
        }
        if (absorbed > 0) {
            api.soundAt(SFX_CLICK, fx, fy, 0, 0.7, 0.9);
            api.noteAt(88, fx, fy, 0, 0.3, SFX_BELL);
            this.fwardPop = this.time;
        }
        this.burst(api, fx - 0.2, fy + 0.2, 0.3, 4 + min<i32>(dmg / 3, 5), 2.2, 0);
        if (this.foeHp <= 0) this.foeHp = 0;
    }

    hitHero(api: GameApi, d: i32): void {
        let hx = this.heroX(), hy = 1.0;
        let absorbed = min<i32>(this.block, d);
        this.block -= absorbed;
        let dmg = d - absorbed;
        this.hp -= dmg;
        if (dmg > 0) {
            this.addFloat(hx, hy + 0.7, 0.3, "-" + dmg.toString(), 0);
            this.heroAnim = A_HURT; this.heroAT = 0;
            api.soundAt(SFX_HIT, hx, hy, 0, 0.85 - Math.min(<f64>dmg, 20) / 60.0, 0.7 + Math.min(<f64>dmg, 20) / 40.0);
            api.soundAt(SFX_THUD, hx, hy, 0, 1.0, 0.5 + Math.min(<f64>dmg, 20) / 40.0);
            this.shake = dmg >= 10 ? 0.3 : 0.18;
        } else {
            this.addFloat(hx, hy + 0.7, 0.3, "BLOCKED", 2);
        }
        if (absorbed > 0) {
            api.soundAt(SFX_CLICK, hx, hy, 0, 0.6, 1.0);
            api.noteAt(86, hx, hy, 0, 0.35, SFX_BELL);
            api.noteAt(93, hx, hy, 0, 0.18, SFX_BELL, 0.03);
            this.wardPop = this.time;
        }
        this.burst(api, hx + 0.3, hy + 0.1, 0.3, 3 + min<i32>(dmg / 3, 5), 2.0, 1);
        if (this.hp < 0) this.hp = 0;
    }

    // ============================================================== intents
    chooseIntent(api: GameApi): void {
        let f = this.foe;
        let k = this.foeTurn;
        let it = I_ATK, v = 6, h = 1;
        let r = api.rand();
        if (f == 0) {             // the mite: pecks, double nips, sometimes hunkers down
            if (r < 0.45) { it = I_ATK; v = 7; h = 1; }
            else if (r < 0.8) { it = I_ATK; v = 4; h = 2; }
            else { it = I_DEF; v = 6; }
            if (it == I_DEF && this.lastIntent == I_DEF) { it = I_ATK; v = 7; h = 1; }
        } else if (f == 1) {      // the moth: hexes first, then dust-storms
            if (k == 0) { it = I_HEX; v = 2; }
            else if (r < 0.45) { it = I_ATK; v = 10; h = 1; }
            else if (r < 0.8 || this.weak > 0) { it = I_ATK; v = 5; h = 2; }
            else { it = I_HEX; v = 2; }
        } else if (f == 2) {      // the warden: a slow, heavy cycle
            let c = k % 4;
            if (c == 0) { it = I_DEF; v = 12; }
            else if (c == 1) { it = I_ATK; v = 14; h = 1; }
            else if (c == 2) { it = I_BUFF; v = 3; }
            else { it = I_ATK; v = 8; h = 1; }
        } else {                  // the Tallow King
            if (k == 0) { it = I_BUFF; v = 2; }
            else {
                let c = (k - 1) % 5;
                if (c == 0) { it = I_ATK; v = 12; h = 1; }
                else if (c == 1) { it = I_ATK; v = 5; h = 3; }
                else if (c == 2) { it = r < 0.5 ? I_DEF : I_HEX; v = it == I_DEF ? 14 : 2; }
                else if (c == 3) { it = I_ATK; v = 18; h = 1; }
                else { it = I_BUFF; v = 2; }
            }
        }
        this.intent = it;
        this.intentVal = v;
        this.intentHits = h;
        this.lastIntent = it;
    }

    // ============================================================== playing cards
    canPlay(i: i32): bool {
        if (i < 0 || i >= this.hand.length) return false;
        return C_COST[this.hand[i]] <= this.energy;
    }

    playCard(api: GameApi, i: i32): void {
        let c = this.hand[i];
        this.energy -= C_COST[c];
        this.playing = c;
        this.playFromX = this.handX[i];
        this.playFromY = this.handY[i];
        this.hand.splice(i, 1);
        this.handX.splice(i, 1);
        this.handY.splice(i, 1);
        this.handT.splice(i, 1);
        this.hitsDone = 0;
        this.played++;
        this.firstPlay = false;
        let t = C_TYPE[c];
        if (t == ATK) {
            this.heroAnim = A_ATTACK; this.heroHits = C_HITS[c];
            this.endTime = 0.22 + 0.2 * <f64>(C_HITS[c] - 1) + 0.38;
        } else if (t == BLK) {
            this.heroAnim = C_DMG[c] > 0 ? A_ATTACK : A_BLOCK; this.heroHits = 1;
            this.endTime = C_DMG[c] > 0 ? 0.62 : 0.45;
        } else {
            this.heroAnim = A_CAST;
            this.endTime = 0.55;
        }
        this.heroAT = 0;
        this.setPhase(P_RESOLVE);
        api.sound(SFX_WHOOSH, 1.7, 0.3, -0.2);
        api.sound(SFX_CLICK, 1.3, 0.5, -0.2);
    }

    // the moments of a card's effect, by the resolve clock
    resolveCard(api: GameApi): void {
        let c = this.playing;
        let t = C_TYPE[c];
        let fx = this.foeX();
        if (C_DMG[c] > 0) {
            for (let k = 0; k < C_HITS[c]; k++) {
                let ht = 0.22 + 0.2 * <f64>k;
                if (C_BLOCK[c] > 0) ht = 0.3;
                if (this.crossed(ht)) {
                    this.slashAt(api, k);
                    this.hitFoe(api, this.heroDamage(C_DMG[c]));
                }
            }
        }
        if (C_BLOCK[c] > 0 && this.crossed(0.12)) {
            this.block += C_BLOCK[c];
            this.wardPop = this.time;
            this.addFloat(this.heroX(), 1.75, 0.3, "+" + C_BLOCK[c].toString(), 1);
            api.soundAt(SFX_CLICK, this.heroX(), 1, 0, 0.55, 1.0);
            api.noteAt(81, this.heroX(), 1, 0, 0.35, SFX_BELL);
            api.noteAt(88, this.heroX(), 1, 0, 0.2, SFX_BELL, 0.04);
        }
        if (t == SPL && this.crossed(0.22)) {
            let hx = this.heroX();
            if (C_BURN[c] > 0) {
                this.foeBurn += C_BURN[c];
                this.addFloat(fx, F_MID[this.foe] + 0.7, 0.3, "BURN " + this.foeBurn.toString(), 0);
                this.stream(api, hx + 0.4, 1.3, fx, F_MID[this.foe], 6);
                api.soundAt(SFX_ZAP, fx, 1, 0, 0.55, 0.6);
                api.soundAt(SFX_EXPLODE, fx, 1, 0, 1.6, 0.35, 0.08);
            }
            if (C_WEAK[c] > 0) {
                this.foeWeak += C_WEAK[c];
                this.addFloat(fx, F_MID[this.foe] + 0.7, 0.3, "WEAK", 1);
                this.motesAt(fx, F_TOP[this.foe] + 0.2, 0, 6, -1.4);
                api.noteAt(67, fx, 1, 0, 0.5, SFX_NOTE);
                api.noteAt(63, fx, 1, 0, 0.5, SFX_NOTE, 0.1);
                api.noteAt(58, fx, 1, 0, 0.5, SFX_NOTE, 0.2);
            }
            if (C_DRAW[c] > 0) {
                for (let k = 0; k < C_DRAW[c]; k++) {
                    if (this.drawOne(api) >= 0) {
                        api.sound(SFX_TICK, 1.2 + 0.15 * <f64>k, 0.9, -0.6, 0.08 * <f64>k);
                        api.sound(SFX_CLICK, 1.6, 0.3, -0.6, 0.08 * <f64>k);
                    }
                }
                this.motesAt(hx, 1.6, 0, 3, 1.2);
            }
            if (C_HEAL[c] > 0) {
                let before = this.hp;
                this.hp = min<i32>(HERO_HP, this.hp + C_HEAL[c]);
                this.addFloat(hx, 1.8, 0.3, "+" + (this.hp - before).toString() + " HP", 1);
                this.motesAt(hx, 0.4, 0, 8, 1.6);
                api.soundAt(SFX_POWERUP, hx, 1, 0, 1.2, 0.6);
            }
            if (C_ENERGY[c] > 0) {
                this.energy += C_ENERGY[c];
                this.addFloat(hx, 1.8, 0.3, "+" + C_ENERGY[c].toString() + " EN", 1);
                this.motesAt(hx, 1.0, 0, 4, 1.4);
                api.sound(SFX_COIN, 1.5, 0.5, -0.5);
            }
            if (C_STR[c] > 0) {
                this.str += C_STR[c];
                this.addFloat(hx, 1.8, 0.3, "+" + C_STR[c].toString() + " STR", 0);
                this.burst(api, hx, 1.2, 0.2, 7, 1.4, 2);
                api.soundAt(SFX_POWERUP, hx, 1, 0, 0.75, 0.6);
            }
        }
        if (C_DMG[c] > 0 && C_BURN[c] > 0 && this.crossed(0.32)) {
            this.foeBurn += C_BURN[c];
            api.soundAt(SFX_ZAP, fx, 1, 0, 0.55, 0.45);
        }
        if (this.pt >= this.endTime) {
            // to the discard pile, or gone for this fight (ONCE)
            if (!C_ONCE[c]) this.discard.push(c);
            this.playing = -1;
            if (this.foeHp <= 0) {
                this.foeDies(api);
            } else {
                this.setPhase(P_PLAYER);
                this.demoWait = 0.35 + api.rand() * 0.35;
            }
        }
    }

    endTurn(api: GameApi): void {
        for (let i = 0; i < this.hand.length; i++) this.discard.push(this.hand[i]);
        this.hand.length = 0; this.handX.length = 0; this.handY.length = 0; this.handT.length = 0;
        if (this.weak > 0) this.weak--;
        this.setPhase(P_FOE);
        this.foeHits = 0;
        api.sound(SFX_BLIP, 0.8, 0.5, 0.6);
        api.note(57, 0.4, 0.5, SFX_BELL, 0.05);
    }

    // the foe's turn, by its clock: burn, then the intent, then the next intent and the hero's turn
    runFoe(api: GameApi): void {
        let fx = this.foeX();
        if (this.crossed(0.05)) this.foeBlock = 0;
        let actAt = 0.25;
        if (this.foeBurn > 0 || this.pt < 0.3) {
            if (this.crossed(0.2) && this.foeBurn > 0) {
                let b = this.foeBurn;
                this.foeHp -= b;
                this.dealt += b;
                this.addFloat(fx, F_MID[this.foe] + 0.6, 0.3, "-" + b.toString(), 0);
                this.foeBurn--;
                this.foeAnim = A_HURT; this.foeAT = 0;
                this.burst(api, fx, F_MID[this.foe], 0.3, 5, 1.6, 0);
                api.soundAt(SFX_ZAP, fx, 1, 0, 0.45, 0.55);
                api.soundAt(SFX_HIT, fx, 1, 0, 1.2, 0.4);
                if (this.foeHp <= 0) {
                    this.foeHp = 0;
                    this.foeDies(api);
                    return;
                }
            }
        }
        actAt = 0.65;
        let it = this.intent;
        if (this.crossed(actAt)) {
            this.foeAT = 0;
            this.foeHits = this.intentHits;
            if (it == I_ATK) this.foeAnim = A_ATTACK;
            else if (it == I_DEF) this.foeAnim = A_BLOCK;
            else this.foeAnim = A_BUFF;
            if (it == I_ATK) api.soundAt(SFX_WHOOSH, fx, 1, 0, 0.8, 0.5);
        }
        let end = actAt + 0.9;
        if (it == I_ATK) {
            for (let k = 0; k < this.intentHits; k++) {
                if (this.crossed(actAt + 0.2 + 0.22 * <f64>k)) {
                    this.hitHero(api, this.foeDamage(this.intentVal));
                    if (this.hp <= 0) {
                        this.heroDies(api);
                        return;
                    }
                }
            }
            end = actAt + 0.2 + 0.22 * <f64>(this.intentHits - 1) + 0.55;
        } else if (it == I_DEF) {
            if (this.crossed(actAt + 0.15)) {
                this.foeBlock += this.intentVal;
                this.fwardPop = this.time;
                this.addFloat(fx, F_TOP[this.foe] - 0.2, 0.3, "+" + this.intentVal.toString(), 1);
                api.soundAt(SFX_CLICK, fx, 1, 0, 0.45, 1.0);
                api.noteAt(76, fx, 1, 0, 0.35, SFX_BELL);
            }
        } else if (it == I_BUFF) {
            if (this.crossed(actAt + 0.15)) {
                this.foeStr += this.intentVal;
                this.addFloat(fx, F_TOP[this.foe] - 0.2, 0.3, "+" + this.intentVal.toString() + " STR", 0);
                this.burst(api, fx, F_MID[this.foe], 0.2, 8, 1.6, 2);
                api.soundAt(SFX_POWERUP, fx, 1, 0, 0.6, 0.6);
                if (this.foe == 3) {
                    this.foeBlock += 10;
                    this.fwardPop = this.time;
                }
            }
        } else {
            if (this.crossed(actAt + 0.1)) {
                this.stream(api, fx - 0.3, F_MID[this.foe] + 0.2, this.heroX(), 1.4, 7);
                api.noteAt(70, fx, 1, 0, 0.5, SFX_NOTE);
                api.noteAt(65, fx, 1, 0, 0.5, SFX_NOTE, 0.1);
                api.noteAt(61, fx, 1, 0, 0.5, SFX_NOTE, 0.2);
            }
            if (this.crossed(actAt + 0.45)) {
                this.weak += this.intentVal;
                this.addFloat(this.heroX(), 1.9, 0.3, "WEAK", 0);
            }
        }
        if (this.pt >= end) {
            if (this.foeWeak > 0) this.foeWeak--;
            this.foeTurn++;
            this.chooseIntent(api);
            this.beginTurn(api);
        }
    }

    foeDies(api: GameApi): void {
        this.foeAnim = A_DIE; this.foeAT = 0;
        this.heroAnim = A_CHEER; this.heroAT = 0;
        this.slain++;
        this.setPhase(P_WIN);
        // the hand goes back; the deck is whole again for the next fight
        this.hand.length = 0; this.handX.length = 0; this.handY.length = 0; this.handT.length = 0;
        let fx = this.foeX();
        this.burst(api, fx, F_MID[this.foe] + 0.3, 0.3, 10, 2.6, 0);
        api.soundAt(SFX_EXPLODE, fx, 1, 0, 1.0, 0.7);
        api.note(72, 0.4, 0, SFX_NOTE, 0.25);
        api.note(76, 0.4, 0, SFX_NOTE, 0.37);
        api.note(79, 0.45, 0, SFX_NOTE, 0.49);
        this.shake = 0.3;
    }

    heroDies(api: GameApi): void {
        this.heroAnim = A_DIE; this.heroAT = 0;
        this.foeAnim = A_NONE;
        this.won = false;
        this.score = this.slain * 100;
        if (this.score > this.best) this.best = this.score;
        this.setPhase(P_DEFEAT);
        api.sound(SFX_LOSE, 1, 0.7);
        api.note(57, 0.5, 0, SFX_BELL, 0.5);
        api.note(52, 0.5, 0, SFX_BELL, 0.8);
        api.note(45, 0.6, 0, SFX_BELL, 1.15);
    }

    offerRewards(api: GameApi): void {
        let n = 0;
        let guard = 0;
        while (n < 3 && guard < 100) {
            guard++;
            let c = 2 + <i32>Math.floor(api.rand() * <f64>(N_CARDS - 2));
            if (c >= N_CARDS) c = N_CARDS - 1;
            let dup = false;
            for (let k = 0; k < n; k++) if (this.rewards[k] == c) dup = true;
            if (!dup) { this.rewards[n] = c; n++; }
        }
        this.pickedReward = -1;
        this.setPhase(P_REWARD);
        api.sound(SFX_POWERUP, 1.0, 0.45);
    }

    pickReward(api: GameApi, k: i32): void {
        if (this.phase != P_REWARD || this.pickedReward >= 0) return;
        this.pickedReward = k;
        this.pt = 0;
        if (k < 3) {
            this.deck.push(this.rewards[k]);
            api.sound(SFX_COIN, 1.0, 0.7);
            api.note(84, 0.3, 0, SFX_BELL, 0.1);
        } else {
            api.sound(SFX_BLIP, 0.7, 0.5);
        }
    }

    victory(api: GameApi): void {
        this.won = true;
        this.score = this.slain * 100 + this.hp * 5 + max<i32>(0, 40 - this.turns) * 10;
        if (this.score > this.best) this.best = this.score;
        this.setPhase(P_VICTORY);
        this.heroAnim = A_CHEER; this.heroAT = 0;
        api.sound(SFX_WIN, 1, 0.6, 0, 0.2);
        let m: StaticArray<i32> = [72, 76, 79, 84, 79, 84, 88];
        for (let i = 0; i < m.length; i++) {
            api.note(<f64>m[i], 0.45, 0, i == m.length - 1 ? SFX_BELL : SFX_NOTE, 0.6 + 0.13 * <f64>i);
        }
    }

    // the end panel shows at once after a victory (the foe already melted), a second after a defeat
    panelAt(): f64 {
        return this.phase == P_DEFEAT ? 1.2 : 0.0;
    }

    crossed(t: f64): bool {
        return this.pt - this.pdt < t && this.pt >= t;
    }

    // ============================================================== update
    update(api: GameApi): void {
        this.time = api.time;
        let dt = api.dt;
        if (api.demoChanged) {
            this.newRun(api);
        }
        this.pdt = dt;
        this.pt += dt;
        let p = this.phase;
        if (p == P_DEAL) {
            this.dealNext -= dt;
            if (this.dealN > 0 && this.dealNext <= 0) {
                let k = 5 - this.dealN;
                if (this.drawOne(api) >= 0) {
                    api.sound(SFX_TICK, 1.0 + 0.12 * <f64>k, 0.9, -0.7);
                    api.sound(SFX_CLICK, 1.5 + 0.1 * <f64>k, 0.35, -0.7);
                }
                this.dealN--;
                this.dealNext = 0.09;
            }
            if (this.dealN <= 0 && this.dealNext <= -0.12) {
                this.setPhase(P_PLAYER);
                this.demoWait = 0.45 + api.rand() * 0.3;
            }
        } else if (p == P_PLAYER) {
            if (api.demo) this.demoPlay(api, dt);
        } else if (p == P_RESOLVE) {
            this.resolveCard(api);
        } else if (p == P_FOE) {
            this.runFoe(api);
        } else if (p == P_WIN) {
            if (this.pt >= 1.4) {
                if (this.fight >= N_FIGHTS - 1) {
                    this.victory(api);
                } else {
                    this.offerRewards(api);
                    this.demoWait = 1.0 + api.rand() * 0.8;
                }
            }
        } else if (p == P_REWARD) {
            if (this.pickedReward < 0 && api.demo) {
                this.demoWait -= dt;
                if (this.demoWait <= 0) this.pickReward(api, this.demoReward(api));
            }
            if (this.pickedReward >= 0 && this.pt >= 0.45) {
                this.startFight(api, this.fight + 1, true);
                api.soundAt(SFX_THUD, 4, 0, 0, 1.4, 0.4, 0.15);
                api.soundAt(SFX_THUD, 3.5, 0, 0, 1.4, 0.4, 0.4);
                api.soundAt(SFX_THUD, 3, 0, 0, 1.4, 0.4, 0.65);
            }
        } else if (p == P_ENTER) {
            if (this.pt >= 1.0) {
                this.beginTurn(api);
            }
        } else if (p == P_VICTORY || p == P_DEFEAT) {
            if (api.demo && this.pt >= this.panelAt() + 2.2) {
                this.newRun(api);
            }
        }
        // hand cards slide towards their slots
        let n = this.hand.length;
        let k = 1 - Math.exp(-dt * 18);
        for (let i = 0; i < n; i++) {
            let tx = this.slotX(i, n);
            let ty = <f64>HAND_Y;
            if (this.time - this.handT[i] < 0) continue;
            this.handX[i] += (tx - this.handX[i]) * k;
            this.handY[i] += (ty - this.handY[i]) * k;
        }
        this.animate(api, dt);
    }

    // ============================================================== demo player
    demoPlay(api: GameApi, dt: f64): void {
        this.demoWait -= dt;
        if (this.demoWait > 0) return;
        let incoming = 0;
        if (this.intent == I_ATK) incoming = this.foeDamage(this.intentVal) * this.intentHits;
        let need = incoming - this.block;
        let best = -1;
        let bestS = 0.25;
        let any = -1;
        let nPlay = 0;
        for (let i = 0; i < this.hand.length; i++) {
            if (!this.canPlay(i)) continue;
            nPlay++;
            let c = this.hand[i];
            let s = 0.0;
            let dmg = this.heroDamage(C_DMG[c]) * C_HITS[c];
            let eff = Math.max(0, <f64>(dmg - this.foeBlock));
            if (C_DMG[c] > 0) {
                s += eff * 0.9;
                if (<f64>this.foeHp <= eff) s += 30;
            }
            if (C_BLOCK[c] > 0) s += need > 0 ? <f64>min<i32>(C_BLOCK[c], need) * 1.25 : 0.3;
            if (C_BURN[c] > 0) s += this.foeHp > 10 ? <f64>C_BURN[c] * 1.4 : 1;
            if (C_WEAK[c] > 0) s += this.foeWeak > 0 ? 0.5 : (this.intent == I_ATK ? 5 : 2.5);
            if (C_DRAW[c] > 0) s += 4.0 * <f64>C_DRAW[c];
            if (C_HEAL[c] > 0) s += HERO_HP - this.hp >= 7 ? 6 : 0.1;
            if (C_ENERGY[c] > 0) s += 5;
            if (C_STR[c] > 0) s += this.foeHp > 20 ? 5 : 0.5;
            s = s / Math.max(<f64>C_COST[c], 0.6);
            if (s > bestS) { bestS = s; best = i; }
            any = i;
        }
        // now and then a human-ish slip: a random playable card
        if (nPlay > 1 && api.rand() < 0.12) {
            let pick = <i32>Math.floor(api.rand() * <f64>nPlay);
            let k = 0;
            for (let i = 0; i < this.hand.length; i++) {
                if (!this.canPlay(i)) continue;
                if (k == pick) { best = i; break; }
                k++;
            }
        }
        if (best >= 0) {
            this.pressCard = best;
            this.pressT = this.time;
            this.playCard(api, best);
        } else {
            this.endTurn(api);
        }
    }

    demoReward(api: GameApi): i32 {
        if (api.rand() < 0.1) return 3;  // skip now and then
        let total = 0.0;
        for (let k = 0; k < 3; k++) total += C_RATE[this.rewards[k]];
        let r = api.rand() * total;
        for (let k = 0; k < 3; k++) {
            r -= C_RATE[this.rewards[k]];
            if (r <= 0) return k;
        }
        return 2;
    }

    // ============================================================== effects
    heroX(): f64 { return HERO_X; }
    foeX(): f64 { return this.foe == 3 ? FOE_X + 0.1 : FOE_X; }

    addFloat(x: f64, y: f64, z: f64, s: string, col: i32): void {
        this.ftX.push(x); this.ftY.push(y); this.ftZ.push(z); this.ftT.push(this.time); this.ftS.push(s); this.ftC.push(col);
    }

    // sparks: kind 0 burst (gravity), 1 small (gravity), 2 rising
    burst(api: GameApi, x: f64, y: f64, z: f64, n: i32, speed: f64, kind: i32): void {
        let made = 0;
        for (let i = 0; i < 10 && made < n; i++) {
            if (this.sl[i] > 0) continue;
            let a = api.rand() * Math.PI * 2;
            let u = api.rand();
            this.sx[i] = x; this.sy[i] = y; this.sz[i] = z;
            if (kind == 2) {
                this.sx[i] = x + Math.cos(a) * 0.45; this.sz[i] = z + Math.sin(a) * 0.3; this.sy[i] = y - 0.5 + u;
                this.svx[i] = 0; this.svy[i] = 1.2 + u; this.svz[i] = 0; this.sg[i] = 0;
            } else {
                this.svx[i] = Math.cos(a) * speed * (0.4 + 0.6 * u);
                this.svy[i] = speed * (0.4 + api.rand() * 0.8);
                this.svz[i] = Math.sin(a) * speed * 0.4;
                this.sg[i] = 7;
            }
            this.sl[i] = 0.45 + api.rand() * 0.35;
            made++;
        }
    }

    // a stream of sparks flying from one point to another (a burn, a hex)
    stream(api: GameApi, x0: f64, y0: f64, x1: f64, y1: f64, n: i32): void {
        let made = 0;
        for (let i = 0; i < 10 && made < n; i++) {
            if (this.sl[i] > 0) continue;
            let tt = 0.35 + 0.05 * <f64>made;
            this.sx[i] = x0; this.sy[i] = y0 + (api.rand() - 0.5) * 0.4; this.sz[i] = 0.3;
            this.svx[i] = (x1 - x0) / tt; this.svy[i] = (y1 - this.sy[i]) / tt + 0.5 * 3 * tt; this.svz[i] = 0;
            this.sg[i] = 3;
            this.sl[i] = tt;
            made++;
        }
    }

    motesAt(x: f64, y: f64, z: f64, n: i32, vy: f64): void {
        let made = 0;
        for (let i = 0; i < 8 && made < n; i++) {
            if (this.ml[i] > 0) continue;
            let a = <f64>made * 2.4 + <f64>i;
            this.mx[i] = x + Math.cos(a) * 0.5; this.mz[i] = z + Math.sin(a) * 0.35;
            this.my[i] = y + (vy > 0 ? 0 : 0.3) + <f64>made * 0.12 * (vy > 0 ? 1 : -1);
            this.mvx[i] = -Math.cos(a) * 0.15; this.mvy[i] = vy; this.mvz[i] = 0;
            this.ml[i] = 0.6 + 0.06 * <f64>made;
            made++;
        }
    }

    slashAt(api: GameApi, k: i32): void {
        let s = this.nextSlash;
        this.nextSlash = (s + 1) % 2;
        this.slashT[s] = this.time;
        this.slashRoll[s] = k % 2 == 0 ? 0 : 180;
        api.soundAt(SFX_WHOOSH, this.foeX(), 1, 0, 1.3 + 0.15 * <f64>k, 0.45);
    }

    // ============================================================== figures
    animate(api: GameApi, dt: f64): void {
        let t = this.time;
        let step = Math.floor(t * 12) / 12;   // stepped idle motion, 12 fps
        this.heroAT += dt;
        this.foeAT += dt;

        // ---- the hero
        let hx = HERO_X, hy = 0.0, hz = 0.0, hyaw = HERO_YAW;
        let sxs = 1.0, sys = 1.0;
        let swing = 0.0, shieldP = 0.0, shieldR = 0.0, lean = 0.0;
        let bob = Math.sin(step * 2.6) * 0.015;
        let at = Math.floor(this.heroAT * 15) / 15;
        let ha = this.heroAnim;
        if (ha == A_ATTACK) {
            let n = this.heroHits;
            let hit0 = this.playing >= 0 && C_BLOCK[this.playing] > 0 ? 0.3 : 0.22;
            let last = hit0 + 0.2 * <f64>(n - 1);
            let lunge = 0.0;
            if (at < 0.12) { lunge = -0.12 * smooth(at / 0.12); swing = -50 * smooth(at / 0.12); }
            else if (at < hit0) { let u = smooth((at - 0.12) / (hit0 - 0.12)); lunge = -0.12 + 1.42 * u; swing = -50 + 165 * u; }
            else if (at < last + 0.05) {
                let u = (at - hit0) / 0.2 - Math.floor((at - hit0) / 0.2);
                lunge = 1.3; swing = u < 0.5 ? 115 - 170 * (u * 2) : -55 + 170 * ((u - 0.5) * 2);
            } else {
                let u = smooth((at - last - 0.05) / 0.3);
                lunge = 1.3 * (1 - u); swing = 115 * (1 - u);
            }
            if (this.playing >= 0 && C_BLOCK[this.playing] > 0) shieldP = 55;
            hx += lunge;
            lean = lunge > 0.5 ? 10 : 0;
            if (at > last + 0.4) this.heroAnim = A_NONE;
        } else if (ha == A_BLOCK) {
            let u = at < 0.12 ? smooth(at / 0.12) : (at > 0.35 ? 1 - smooth((at - 0.35) / 0.2) : 1);
            shieldP = 70 * u; shieldR = 0; hx -= 0.08 * u;
            if (at > 0.6) this.heroAnim = A_NONE;
        } else if (ha == A_CAST) {
            let u = at < 0.15 ? smooth(at / 0.15) : (at > 0.4 ? 1 - smooth((at - 0.4) / 0.2) : 1);
            swing = -25 * u; hy = 0.08 * u; sys = 1 + 0.04 * u;
            if (at > 0.65) this.heroAnim = A_NONE;
        } else if (ha == A_HURT) {
            let u = 1 - smooth(at / 0.35);
            hx -= 0.3 * u;
            hx += (Math.floor(at * 30) % 2 == 0 ? 0.04 : -0.04) * u;
            sys = 1 - 0.1 * u; sxs = 1 + 0.06 * u; lean = -12 * u;
            if (at > 0.4) this.heroAnim = A_NONE;
        } else if (ha == A_DIE) {
            let u = smooth(at / 0.6);
            lean = -80 * u; hx -= 0.4 * u; hy = 0;
            swing = 40 * u;
        } else if (ha == A_CHEER) {
            let u = at < 0.2 ? smooth(at / 0.2) : 1;
            swing = -170 * u * (1 - smooth((at - 1.2) / 0.3));
            hy = Math.abs(Math.sin(at * 8)) * 0.12 * (at < 1.0 ? 1 : 0);
        }
        hy += bob;
        // the body: lean is a roll towards the foe (about the axis it faces across)
        api.placeScaled(this.hero, hx, hy, hz, hyaw, sxs, sys, sxs, lean, 0);
        api.transform(this.hero, <f64>api.restX[this.hero] - 0.40, 0.9, <f64>api.restZ[this.hero]);
        api.place(this.armR, api.tx, api.ty, api.tz, hyaw, lean + swing, 0, 1);
        api.transform(this.hero, <f64>api.restX[this.hero] + 0.40, 0.9, <f64>api.restZ[this.hero]);
        api.place(this.armL, api.tx, api.ty, api.tz, hyaw - shieldR, lean + shieldP, 0, 1);

        // the hero's ward: pops when block is gained or used, then stays small while block lasts
        let wp = t - this.wardPop;
        if (this.block > 0 || wp < 0.35) {
            let s = wp < 0.35 ? 0.6 + 0.6 * smooth(wp / 0.2) : 0.62 + 0.03 * Math.sin(step * 5);
            if (this.phase == P_VICTORY || this.phase == P_DEFEAT || this.phase == P_REWARD) s = 0;
            if (s > 0.01) api.place(this.ward, hx + 0.8, 1.0 + hy, 0.35, HERO_YAW, 0, 0, s);
            else api.hide(this.ward);
        } else {
            api.hide(this.ward);
        }

        // ---- the foe
        for (let i = 0; i < 4; i++) if (i != this.foe) api.hide(this.foeBone[i]);
        if (this.foe != 1) { api.hide(this.wingL); api.hide(this.wingR); }
        if (this.foe != 3) api.hide(this.kingFire);
        let fx = this.foeX(), fy = 0.0, fz = 0.0, fyaw = FOE_YAW;
        let fsx = 1.0, fsy = 1.0, fpitch = 0.0;
        let ft = Math.floor(this.foeAT * 15) / 15;
        let fa = this.foeAnim;
        let visible = true;
        if (this.phase == P_ENTER) {
            let u = smooth(this.pt / 0.9);
            fx = 6.8 + (fx - 6.8) * u;
            fy = Math.abs(Math.sin(Math.floor(this.pt * 12) / 12 * 11)) * 0.15 * (1 - u);
        }
        if (this.phase == P_REWARD || this.phase == P_VICTORY) visible = false;
        if (fa == A_ATTACK) {
            let n = this.foeHits;
            let last = 0.2 + 0.22 * <f64>(n - 1);
            let lunge = 0.0;
            if (ft < 0.1) lunge = 0.2 * smooth(ft / 0.1);
            else if (ft < 0.2) lunge = 0.2 - 1.75 * smooth((ft - 0.1) / 0.1);
            else if (ft < last + 0.05) {
                let u = (ft - 0.2) / 0.22 - Math.floor((ft - 0.2) / 0.22);
                lunge = -1.55 + 0.35 * Math.sin(u * Math.PI);
            } else lunge = -1.55 * (1 - smooth((ft - last - 0.05) / 0.3));
            fx += lunge;
            fpitch = lunge < -0.5 ? 14 : 0;
            fsy = lunge < -0.5 ? 0.92 : 1.0; fsx = lunge < -0.5 ? 1.08 : 1.0;
            if (ft > last + 0.4) this.foeAnim = A_NONE;
        } else if (fa == A_BLOCK) {
            let u = ft < 0.15 ? smooth(ft / 0.15) : 1 - smooth((ft - 0.4) / 0.2);
            fsy = 1 - 0.1 * u; fsx = 1 + 0.08 * u;
            if (ft > 0.7) this.foeAnim = A_NONE;
        } else if (fa == A_BUFF) {
            let u = ft < 0.2 ? smooth(ft / 0.2) : 1 - smooth((ft - 0.45) / 0.25);
            fsy = 1 + 0.12 * u; fsx = 1 + 0.05 * u; fy = 0.1 * u;
            if (ft > 0.8) this.foeAnim = A_NONE;
        } else if (fa == A_HURT) {
            let u = 1 - smooth(ft / 0.35);
            fx += 0.3 * u + (Math.floor(ft * 30) % 2 == 0 ? 0.05 : -0.05) * u;
            fsy = 1 - 0.12 * u; fsx = 1 + 0.08 * u; fpitch = -12 * u;
            if (ft > 0.4) this.foeAnim = A_NONE;
        } else if (fa == A_DIE) {
            let u = smooth(ft / 0.8);
            fsy = 1 - 0.85 * u; fsx = 1 + 0.3 * u; fpitch = -10 * u;
            fx += (Math.floor(ft * 20) % 2 == 0 ? 0.04 : -0.04) * (1 - u);
            if (ft > 0.9) visible = false;
        }
        let b = this.foeBone[this.foe];
        if (!visible) {
            api.hide(b);
            if (this.foe == 1) { api.hide(this.wingL); api.hide(this.wingR); }
            if (this.foe == 3) api.hide(this.kingFire);
        } else if (this.foe == 1) {
            // the moth hovers, bobbing, and flaps (stepped); it faces out of the picture, a little
            // towards the knight, so its raised wings show broad
            fyaw = -25;
            let hov = 1.35 + Math.sin(step * 3.1) * 0.12 + fy;
            api.placeScaled(b, fx, hov, fz, fyaw, fsx, fsy, fsx, fpitch, 0);
            let flap = 28 * Math.sin(step * 13.0) - 6;
            if (fa == A_ATTACK) flap = 30 * Math.sin(step * 26.0);
            if (fa == A_DIE) flap = -40 * smooth(ft / 0.6);
            api.transform(b, <f64>api.restX[b], <f64>api.restY[b], <f64>api.restZ[b]);
            api.place(this.wingR, api.tx, api.ty, api.tz, fyaw, fpitch, flap, fsx);
            api.place(this.wingL, api.tx, api.ty, api.tz, fyaw, fpitch, -flap, fsx);
        } else {
            let breathe = fa == A_NONE ? 1 + Math.sin(step * 2.2) * 0.02 : 1.0;
            api.placeScaled(b, fx, fy, fz, fyaw, fsx, fsy * breathe, fsx, fpitch, 0);
            if (this.foe == 3) {
                api.transform(b, <f64>api.restX[b], <f64>api.restY[b] + 2.43, <f64>api.restZ[b]);
                let fl = 1 + 0.15 * (hash(<i32>(t * 10), 99) - 0.5);
                api.placeScaled(this.kingFire, api.tx, api.ty, api.tz, fyaw, fsx, fsy * fl * breathe, fsx, fpitch, 0);
            }
        }
        // the foe's ward
        let fw = t - this.fwardPop;
        if (visible && fa != A_DIE && (this.foeBlock > 0 || fw < 0.35)) {
            let s = fw < 0.35 ? 0.6 + 0.6 * smooth(fw / 0.2) : 0.62 + 0.03 * Math.sin(step * 5);
            let wy = this.foe == 1 ? 1.4 : (this.foe == 3 ? 1.5 : 0.95);
            api.place(this.fward, fx - 0.85, wy, 0.35, FOE_YAW, 0, 0, s * (this.foe == 3 ? 1.3 : 1.0));
        } else {
            api.hide(this.fward);
        }
        // burn flames on the foe
        let nb = visible && fa != A_DIE ? min<i32>(3, (this.foeBurn + 2) / 3) : 0;
        for (let i = 0; i < 3; i++) {
            if (i < nb) {
                let ox = (<f64>i - 1) * 0.32;
                let oy = this.foe == 1 ? 1.1 + <f64>(i % 2) * 0.2 : 0.15 + <f64>(i % 2) * 0.35 + (this.foe == 3 ? 0.4 : 0);
                let fl = 0.8 + 0.4 * hash(<i32>(t * 9), i);
                api.placeScaled(this.burnB[i], fx + ox, oy, 0.45, 0, 1, fl, 1);
            } else {
                api.hide(this.burnB[i]);
            }
        }

        // ---- slashes
        for (let i = 0; i < 2; i++) {
            let st = t - this.slashT[i];
            if (st < 0.2) {
                let s = 0.7 + 0.6 * Math.floor(st * 30) / 6;
                api.place(this.slash[i], this.foeX() - 0.35, F_MID[this.foe] + 0.25, 0.6, -20, 0, this.slashRoll[i] - 30 + st * 300, s);
            } else {
                api.hide(this.slash[i]);
            }
        }
        // ---- sparks and motes
        for (let i = 0; i < 10; i++) {
            if (this.sl[i] > 0) {
                this.sl[i] -= dt;
                this.svy[i] -= this.sg[i] * dt;
                this.sx[i] += this.svx[i] * dt; this.sy[i] += this.svy[i] * dt; this.sz[i] += this.svz[i] * dt;
                if (this.sy[i] < 0.05) { this.sy[i] = 0.05; this.svy[i] = -this.svy[i] * 0.3; }
                api.place(this.spark[i], this.sx[i], this.sy[i], this.sz[i], step * 200, 0, 0, this.sl[i] < 0.15 ? 0.6 : 1.0);
            } else {
                api.hide(this.spark[i]);
            }
        }
        for (let i = 0; i < 8; i++) {
            if (this.ml[i] > 0) {
                this.ml[i] -= dt;
                this.mx[i] += this.mvx[i] * dt; this.my[i] += this.mvy[i] * dt; this.mz[i] += this.mvz[i] * dt;
                api.place(this.mote[i], this.mx[i], this.my[i], this.mz[i], step * 160, 0, 0, this.ml[i] < 0.15 ? 0.6 : 1.0);
            } else {
                api.hide(this.mote[i]);
            }
        }
        // ---- the candles flicker (stepped, out of step with each other)
        for (let i = 0; i < 7; i++) {
            let fb = this.flames[i];
            let h = hash(<i32>(t * 8) + i * 7, i);
            let h2 = hash(<i32>(t * 8) + i * 13, i + 50);
            api.placeScaled(fb, <f64>api.restX[fb], <f64>api.restY[fb], <f64>api.restZ[fb], <f64>api.restYaw[fb],
                0.9 + 0.2 * h2, 0.82 + 0.36 * h, 0.9 + 0.2 * h2);
        }
        // ---- the camera shake (whole texels, so the picture slides by whole pixels)
        if (this.shake > 0) {
            this.shake -= dt;
            let k = Math.floor(t * 30) % 2 == 0 ? 1.0 : -1.0;
            api.targetX = this.baseTX + k * TEXEL * (this.shake > 0.15 ? 2 : 1);
        } else {
            api.targetX = this.baseTX;
        }
        api.targetY = this.baseTY;
        // floating numbers expire
        let j = 0;
        while (j < this.ftT.length) {
            if (t - this.ftT[j] > 1.1) {
                this.ftX.splice(j, 1); this.ftY.splice(j, 1); this.ftZ.splice(j, 1);
                this.ftT.splice(j, 1); this.ftS.splice(j, 1); this.ftC.splice(j, 1);
            } else {
                j++;
            }
        }
    }

    // ============================================================== pointer
    cardAt(x: f32, y: f32): i32 {
        for (let i = this.hand.length - 1; i >= 0; i--) {
            let cx = <f32>this.handX[i], cy = <f32>this.handY[i];
            if (x >= cx && x < cx + CARD_W && y >= cy - 4 && y < cy + CARD_H) return i;
        }
        return -1;
    }

    rewardX(k: i32): f32 {
        return <f32>(Math.floor(<f64>(213 - 3 * 30 - 2 * 12) * 0.5) + <f64>k * 42);
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_MOVE || kind == POINTER_DOWN) {
            this.hoverCard = this.phase == P_PLAYER ? this.cardAt(x, y) : -1;
        }
        if (kind == POINTER_UP) {
            this.hoverCard = -1;
            return true;
        }
        if (kind != POINTER_DOWN) return true;
        let p = this.phase;
        if (p == P_PLAYER) {
            let i = this.cardAt(x, y);
            if (i >= 0) {
                if (this.canPlay(i)) {
                    this.pressCard = i;
                    this.pressT = this.time;
                    this.hoverCard = -1;
                    this.playCard(api, i);
                } else {
                    this.denyCard = i;
                    this.denyT = this.time;
                    api.sound(SFX_THUD, 1.8, 0.35);
                    api.sound(SFX_BLIP, 0.5, 0.25);
                }
                return true;
            }
            if (x >= BTN_X && x < BTN_X + BTN_W && y >= BTN_Y - 4 && y < BTN_Y + BTN_H + 4) {
                this.endTurn(api);
                return true;
            }
        } else if (p == P_REWARD) {
            for (let k = 0; k < 3; k++) {
                let rx = this.rewardX(k);
                if (x >= rx - 2 && x < rx + CARD_W + 2 && y >= 30 && y < 30 + CARD_H + 2) {
                    this.pickReward(api, k);
                    return true;
                }
            }
            if (x >= 88 && x < 126 && y >= 76 && y < 90) {
                this.pickReward(api, 3);
                return true;
            }
        } else if ((p == P_VICTORY || p == P_DEFEAT) && this.pt > this.panelAt() + 1.0) {
            this.newRun(api);
            api.sound(SFX_WIN, 1, 0.45);
            return true;
        }
        return true;
    }

    // ============================================================== HUD
    hud(api: GameApi): void {
        this.cInk = api.rampColor(0, 0); this.cNight = api.rampColor(0, 1); this.cPlum = api.rampColor(0, 2);
        this.cWine = api.rampColor(0, 3); this.cMaroon = api.rampColor(0, 4); this.cCrimson = api.rampColor(1, 4);
        this.cRed = api.rampColor(2, 4); this.cNavy = api.rampColor(3, 1); this.cBlue = api.rampColor(3, 2);
        this.cCyan = api.rampColor(3, 3);
        let t = this.time;
        let W = <f32>api.hudW;
        let p = this.phase;

        // ---- the top bar
        api.rect(0, 0, W, 9, this.cInk);
        api.rect(0, 9, W, 1, this.cPlum);
        api.text(3, 2, "FIGHT " + (this.fight + 1).toString() + "/" + N_FIGHTS.toString(), this.cCrimson, 1);
        let nm = F_NAME[this.foe];
        api.text(<f32>Math.floor((<f64>W - <f64>api.textWidth(nm, 1)) * 0.5), 2, nm, this.foe == 3 ? this.cRed : this.cBlue, 1);
        let bs = "BEST " + this.best.toString();
        api.text(W - api.textWidth(bs, 1) - 3, 2, bs, this.cMaroon, 1);

        // ---- the fighters' bars, statuses, the foe's intent
        let showFigures = p != P_REWARD && p != P_VICTORY;
        if (showFigures) {
            this.bar(api, HERO_X, this.hp, HERO_HP, this.block, this.weak, this.str, 0, this.cRed);
            let fa = this.foeAnim;
            if (p != P_ENTER && !(fa == A_DIE)) {
                this.bar(api, this.foeX(), this.foeHp, this.foeMax, this.foeBlock, this.foeWeak, this.foeStr, this.foeBurn, this.cRed);
                if (p != P_FOE && p != P_WIN && p != P_DEFEAT) this.drawIntent(api);
            }
        }

        // ---- floating numbers
        for (let i = 0; i < this.ftT.length; i++) {
            let age = t - this.ftT[i];
            if (age < 0) continue;
            let rise = Math.floor(age * 14);
            if (!api.project(<f32>this.ftX[i], <f32>this.ftY[i], <f32>this.ftZ[i])) continue;
            let s = this.ftS[i];
            let sc = s.length <= 3 && s.charAt(0) == "-" ? 2 : 1;
            let tw = api.textWidth(s, sc);
            let col = this.ftC[i] == 0 ? this.cRed : (this.ftC[i] == 1 ? this.cCyan : this.cBlue);
            if (age > 0.85 && Math.floor(age * 20) % 2 == 0) continue;
            api.text(<f32>Math.floor(<f64>api.screenX - <f64>tw * 0.5), <f32>(Math.floor(<f64>api.screenY) - <f32>rise), s, col, sc, this.cInk);
        }

        // ---- the hand area
        api.rect(0, 87, W, 1, this.cPlum);
        api.rect(0, 88, W, <f32>api.hudH - 88, this.cInk);
        this.drawEnergy(api);
        this.drawPiles(api);
        this.drawButton(api);
        let n = this.hand.length;
        for (let i = 0; i < n; i++) {
            if (t - this.handT[i] < 0) continue;
            let lift: f32 = 0;
            if (i == this.hoverCard && p == P_PLAYER) lift = 3;
            let dx: f32 = 0;
            if (i == this.denyCard && t - this.denyT < 0.3) dx = (Math.floor((t - this.denyT) * 30) % 2 == 0) ? 1 : -1;
            this.drawCard(api, <f32>Math.round(this.handX[i]) + dx, <f32>Math.round(this.handY[i]) - lift, this.hand[i],
                C_COST[this.hand[i]] <= this.energy, true);
        }
        // the card being played flies up towards its target and is gone
        if (p == P_RESOLVE && this.playing >= 0 && this.pt < 0.2) {
            let u = smooth(this.pt / 0.2);
            let tx = C_TYPE[this.playing] == BLK || C_HEAL[this.playing] > 0 || C_DRAW[this.playing] > 0 || C_ENERGY[this.playing] > 0 || C_STR[this.playing] > 0 ? 50.0 : 150.0;
            let x = this.playFromX + (tx - this.playFromX) * u;
            let y = this.playFromY + (40 - this.playFromY) * u;
            if (u < 0.85) this.drawCard(api, <f32>Math.round(x), <f32>Math.round(y), this.playing, true, true);
        }

        // ---- hints and panels
        if (this.firstPlay && p == P_PLAYER && !api.demo) {
            this.hint(api, "TAP A CARD TO PLAY IT");
        } else if (p == P_PLAYER && !api.demo && this.energy == 0 && this.turns <= 2 && this.fight == 0) {
            this.hint(api, "OUT OF ENERGY: END TURN");
        } else if (p == P_FOE) {
            this.hint(api, "FOE'S TURN");
        } else if (p == P_ENTER) {
            this.hint(api, F_NAME[this.foe] + " APPROACHES");
        }
        if (p == P_REWARD) this.drawReward(api);
        if ((p == P_VICTORY || p == P_DEFEAT) && this.pt >= this.panelAt()) this.drawEnd(api);
        else if (p == P_DEFEAT) this.hint(api, "THE WICK KNIGHT FALLS");
    }

    hint(api: GameApi, s: string): void {
        let w = api.textWidth(s, 1);
        let x = <f32>Math.floor((<f64>api.hudW - <f64>w) * 0.5);
        api.rect(x - 3, 12, w + 6, 9, this.cInk);
        api.text(x, 14, s, this.cCyan, 1);
    }

    bar(api: GameApi, x: f64, hp: i32, mx: i32, blk: i32, wk: i32, st: i32, burn: i32, col: u32): void {
        if (!api.project(<f32>x, 0, 0.3)) return;
        let bw: f32 = 36;
        let bx = <f32>Math.floor(<f64>api.screenX - <f64>bw * 0.5);
        let by = <f32>Math.floor(<f64>api.screenY) + 2;
        if (by > 78) by = 78;
        api.rect(bx - 1, by - 1, bw + 2, 9, this.cInk);
        api.rect(bx, by, bw, 7, this.cNight);
        let fw = <f32>Math.round(<f64>bw * <f64>max<i32>(hp, 0) / <f64>mx);
        api.rect(bx, by, fw, 7, blk > 0 ? this.cNavy : this.cMaroon);
        api.rect(bx, by, fw, 1, blk > 0 ? this.cBlue : this.cCrimson);
        let s = hp.toString() + "/" + mx.toString();
        api.text(bx + <f32>Math.floor((<f64>bw - <f64>api.textWidth(s, 1)) * 0.5), by + 1, s, blk > 0 ? this.cCyan : col, 1);
        // statuses left of the bar: block (a shield), then weak, strength and burn below it
        let sx = bx - 2;
        if (blk > 0) {
            let bs = blk.toString();
            let w = api.textWidth(bs, 1) + 4;
            api.rect(sx - w, by - 1, w, 9, this.cBlue);
            api.text(sx - w + 2, by + 1, bs, this.cInk, 1);
        }
        let ty = by + 1;
        let tx = bx + bw + 3;
        if (wk > 0) { tx = this.tag(api, tx, ty, "WK" + wk.toString(), this.cMaroon); }
        if (st > 0) { tx = this.tag(api, tx, ty, "ST" + st.toString(), this.cRed); }
        if (burn > 0) { tx = this.tag(api, tx, ty, "BN" + burn.toString(), this.cRed); }
    }

    tag(api: GameApi, x: f32, y: f32, s: string, c: u32): f32 {
        let w = api.textWidth(s, 1);
        api.rect(x - 1, y - 2, w + 4, 9, this.cInk);
        api.text(x + 1, y, s, c, 1);
        return x + w + 4;
    }

    drawIntent(api: GameApi): void {
        let fy = F_TOP[this.foe];
        if (this.foe == 1) fy += Math.sin(Math.floor(this.time * 12) / 12 * 3.1) * 0.12;
        if (!api.project(<f32>this.foeX(), <f32>fy, 0)) return;
        let s = "";
        let col = this.cRed;
        let icon = IC_SWORD;
        if (this.intent == I_ATK) {
            let d = this.foeDamage(this.intentVal);
            s = d.toString();
            if (this.intentHits > 1) s += "X" + this.intentHits.toString();
        } else if (this.intent == I_DEF) {
            s = this.intentVal.toString(); col = this.cBlue; icon = IC_SHIELD;
        } else if (this.intent == I_BUFF) {
            s = "+" + this.intentVal.toString(); col = this.cRed; icon = IC_UP;
        } else {
            s = "HEX"; col = this.cCyan; icon = IC_SKULL;
        }
        let tw = api.textWidth(s, 1);
        let w = 9 + 2 + tw;
        let x = <f32>Math.floor(<f64>api.screenX - <f64>w * 0.5);
        let bobY = Math.floor(this.time * 3) % 2 == 0 ? 0 : 1;
        let y = <f32>Math.floor(<f64>api.screenY) - 10 + <f32>bobY;
        if (y < 12) y = 12;
        api.rect(x - 2, y - 2, <f32>w + 4, 13, this.cInk);
        api.rect(x - 2, y + 11, <f32>w + 4, 1, col);
        this.icon(api, x, y, icon, col);
        api.text(x + 11, y + 2, s, col, 1);
    }

    icon(api: GameApi, x: f32, y: f32, ic: i32, col: u32): void {
        for (let r = 0; r < 9; r++) {
            let row = ICONS[ic * 9 + r];
            let c = 0;
            while (c < 9) {
                if (row.charCodeAt(c) == 35) {
                    let c0 = c;
                    while (c < 9 && row.charCodeAt(c) == 35) c++;
                    api.rect(x + <f32>c0, y + <f32>r, <f32>(c - c0), 1, col);
                } else {
                    c++;
                }
            }
        }
    }

    // one card, 30 x 42, at (x, y): frame by type, the cost gem, the picture and its number, the name
    drawCard(api: GameApi, x: f32, y: f32, c: i32, playable: bool, live: bool): void {
        let tp = C_TYPE[c];
        let frame = tp == ATK ? this.cCrimson : (tp == BLK ? this.cBlue : this.cMaroon);
        let dim = live && !playable;
        if (dim) frame = this.cWine;
        api.rect(x, y, CARD_W, CARD_H, this.cInk);
        api.rect(x + 1, y + 1, CARD_W - 2, CARD_H - 2, frame);
        api.rect(x + 2, y + 2, CARD_W - 4, CARD_H - 4, this.cNight);
        // the picture window
        let win = tp == ATK ? this.cPlum : (tp == BLK ? this.cNight : this.cWine);
        api.rect(x + 3, y + 10, CARD_W - 6, 14, dim ? this.cNight : (tp == BLK ? this.cNavy : win));
        let icCol = tp == ATK ? this.cRed : (tp == BLK ? this.cCyan : (C_ICON[c] == 2 ? this.cRed : this.cCyan));
        if (dim) icCol = this.cMaroon;
        this.icon(api, x + 4, y + 13, C_ICON[c], icCol);
        let big = C_BIG[c];
        if (tp == ATK && C_DMG[c] > 0) big = this.heroDamage(C_DMG[c]);
        let bstr = big.toString();
        let bw = api.textWidth(bstr, 2);
        let bcol = dim ? this.cMaroon : this.cCyan;
        if (tp == ATK && C_DMG[c] > 0 && !dim) bcol = big > C_DMG[c] ? this.cRed : (big < C_DMG[c] ? this.cMaroon : this.cCyan);
        api.text(x + CARD_W - 3 - bw, y + 12, bstr, bcol, 2, this.cInk);
        // the cost gem
        api.rect(x, y, 9, 9, this.cInk);
        api.rect(x + 1, y + 1, 7, 7, dim ? this.cMaroon : this.cCyan);
        api.text(x + 3, y + 2, C_COST[c].toString(), this.cInk, 1);
        if (C_ONCE[c]) api.text(x + CARD_W - 10, y + 3, "1X", dim ? this.cMaroon : this.cRed, 1);
        // name and line
        let nm = C_NAME[c];
        api.text(x + <f32>Math.floor((<f64>CARD_W - <f64>api.textWidth(nm, 1)) * 0.5), y + 27, nm, dim ? this.cMaroon : this.cCyan, 1);
        let sub = C_SUB[c];
        api.text(x + <f32>Math.floor((<f64>CARD_W - <f64>api.textWidth(sub, 1)) * 0.5), y + 34, sub, dim ? this.cWine : this.cCrimson, 1);
    }

    drawEnergy(api: GameApi): void {
        let x: f32 = 2, y: f32 = 90;
        let full = this.energy > 0;
        // a faceted gem: an octagon of rects
        api.rect(x + 3, y, 12, 18, this.cInk);
        api.rect(x, y + 3, 18, 12, this.cInk);
        api.rect(x + 4, y + 1, 10, 16, full ? this.cRed : this.cWine);
        api.rect(x + 1, y + 4, 16, 10, full ? this.cRed : this.cWine);
        api.rect(x + 4, y + 1, 10, 3, full ? this.cCyan : this.cMaroon);
        let s = this.energy.toString();
        api.text(x + 9 - <f32>Math.floor(<f64>api.textWidth(s, 2) * 0.5), y + 5, s, this.cInk, 2);
    }

    drawPiles(api: GameApi): void {
        // the draw pile (cards still to draw) and the discard pile, under the energy gem
        let x = PILE_X - 2, y: f32 = 110;
        api.rect(x, y, 8, 10, this.cMaroon);
        api.rect(x + 1, y + 1, 6, 8, this.cCrimson);
        api.text(x + 10, y + 3, this.drawPile.length.toString(), this.cCrimson, 1);
        api.rect(x, y + 11, 8, 10, this.cNavy);
        api.rect(x + 1, y + 12, 6, 8, this.cNight);
        api.text(x + 10, y + 14, this.discard.length.toString(), this.cBlue, 1);
    }

    drawButton(api: GameApi): void {
        let live = this.phase == P_PLAYER;
        let urge = live && (this.energy == 0 || !this.anyPlayable());
        let blink = urge && Math.floor(this.time * 3) % 2 == 0;
        api.rect(BTN_X, BTN_Y, BTN_W, BTN_H, this.cInk);
        api.rect(BTN_X + 1, BTN_Y + 1, BTN_W - 2, BTN_H - 2, live ? (blink ? this.cRed : this.cCrimson) : this.cPlum);
        api.rect(BTN_X + 2, BTN_Y + 2, BTN_W - 4, BTN_H - 4, live ? this.cMaroon : this.cNight);
        let a = this.phase == P_FOE ? "FOE" : "END";
        let b = "TURN";
        let col = live ? this.cCyan : this.cWine;
        api.text(BTN_X + <f32>Math.floor((<f64>BTN_W - <f64>api.textWidth(a, 1)) * 0.5), BTN_Y + 5, a, col, 1);
        api.text(BTN_X + <f32>Math.floor((<f64>BTN_W - <f64>api.textWidth(b, 1)) * 0.5), BTN_Y + 13, b, col, 1);
    }

    anyPlayable(): bool {
        for (let i = 0; i < this.hand.length; i++) if (this.canPlay(i)) return true;
        return false;
    }

    drawReward(api: GameApi): void {
        let W = <f32>api.hudW;
        api.rect(14, 14, W - 28, 80, this.cInk);
        api.rect(15, 15, W - 30, 78, this.cMaroon);
        api.rect(16, 16, W - 32, 76, this.cNight);
        api.textCentered(19, "VICTORY! CHOOSE A CARD", this.cCyan, 1);
        for (let k = 0; k < 3; k++) {
            let rx = this.rewardX(k);
            let ry: f32 = 30;
            if (this.pickedReward == k) {
                ry -= <f32>Math.min(8, Math.floor(this.pt * 40));
                api.rect(rx - 2, ry - 2, CARD_W + 4, CARD_H + 4, this.cCyan);
            }
            if (this.pickedReward >= 0 && this.pickedReward != k) continue;
            this.drawCard(api, rx, ry, this.rewards[k], true, false);
        }
        let sk = this.pickedReward == 3;
        api.rect(88, 76, 38, 13, this.cInk);
        api.rect(89, 77, 36, 11, sk ? this.cCyan : this.cPlum);
        api.text(99, 80, "SKIP", sk ? this.cInk : this.cBlue, 1);
        let d = "DECK " + this.deck.length.toString() + "  HP " + this.hp.toString() + "/" + HERO_HP.toString();
        api.text(20, 80, "", this.cMaroon, 1);
        api.text(W - 20 - api.textWidth(d, 1), 104 - 24, "", this.cMaroon, 1);
        api.textCentered(<f32>api.hudH - 30, d, this.cCrimson, 1);
        api.textCentered(<f32>api.hudH - 20, "NEXT: " + F_NAME[min<i32>(this.fight + 1, N_FIGHTS - 1)], this.cBlue, 1);
    }

    drawEnd(api: GameApi): void {
        let W = <f32>api.hudW;
        let win = this.phase == P_VICTORY;
        let edge = win ? this.cCyan : this.cRed;
        api.rect(30, 16, W - 60, 72, this.cInk);
        api.rect(31, 17, W - 62, 70, edge);
        api.rect(32, 18, W - 64, 68, this.cNight);
        api.textCentered(22, win ? "VICTORY!" : "DEFEAT", edge, 2, this.cInk);
        if (!win) api.textCentered(35, "FELL TO THE " + F_NAME[this.foe], this.cCrimson, 1);
        else api.textCentered(35, "THE TALLOW KING MELTS", this.cBlue, 1);
        let y: f32 = 45;
        this.stat(api, y, "FOES SLAIN", this.slain.toString()); y += 7;
        this.stat(api, y, "TURNS", this.turns.toString()); y += 7;
        this.stat(api, y, "DAMAGE", this.dealt.toString()); y += 7;
        this.stat(api, y, "CARDS IN DECK", this.deck.length.toString()); y += 7;
        this.stat(api, y, "SCORE", this.score.toString()); y += 7;
        this.stat(api, y, "BEST", this.best.toString());
        if (this.pt > this.panelAt() + 1.0 && !api.demo && Math.floor(this.pt * 2) % 2 == 0) {
            api.textCentered(<f32>api.hudH - 12, "TAP FOR A NEW RUN", this.cCyan, 1);
        }
    }

    stat(api: GameApi, y: f32, k: string, v: string): void {
        api.text(44, y, k, this.cCrimson, 1);
        api.text(<f32>api.hudW - 44 - api.textWidth(v, 1), y, v, this.cCyan, 1);
    }
}
