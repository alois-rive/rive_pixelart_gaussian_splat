// Sky Raid: a shoot'em up. A biplane flies over a scrolling patchwork countryside; it follows the pointer
// (with a little lag and a bank) and fires on its own while a run is on. Waves come in a loop: drifting
// balloons, drone formations, gunboats on the rivers firing slow aimed shots, then an armoured airship
// (the boss); after the boss the loop repeats, faster. A supply balloon drops a crate that widens the
// shot. Three lives; the first click starts a run, the next click after a game over starts another.
//
// The world: the camera looks down at 60 degrees and flies forward (targetZ decreasing). Everything
// in the air lives in "logic" coordinates (u across, v down the screen, metres on the ground the
// pointer meets), relative to the snapped camera's ground point g, and is drawn at its altitude h at
// z = g + v + h cot 60, so it shows exactly over its logic point. Positions are snapped to the art
// grid, so a still sprite never crawls. The ground is eight pooled 16 x 6 m tiles (two of each kind)
// recycled ahead of the camera; the world wraps by 12 m (148 art rows exactly: see scene.rml), so the
// play stays inside the bake's bounds for any run length.
import { GameApi, POINTER_DOWN, POINTER_UP, SFX_BELL, SFX_BLIP, SFX_CLICK, SFX_EXPLODE, SFX_HIT, SFX_LOSE,
    SFX_NOTE, SFX_POP, SFX_POWERUP, SFX_SPLASH, SFX_TICK, SFX_WHOOSH, SFX_WIN, SFX_ZAP } from "./game_api";

const SINP: f64 = 0.8660254037844386;   // sin 60
const COT: f64 = 0.5773502691896257;    // cot 60
const TEX: f64 = 0.070218;              // the texel (orthoHeight / 136)
const VSTEP: f64 = 0.070218 / 0.8660254037844386;  // one art row, in ground metres
const WRAP: f64 = 12.0;
const TILE: f64 = 6.0;
const NTILE: i32 = 8;                   // fieldsA fieldsB villageA villageB woodsA woodsB riverA riverB
const PH: f64 = 2.6;                    // the plane's altitude
const NSHOT: i32 = 14;
const NBUL: i32 = 12;
const NBAL: i32 = 4;                    // 0..2 balloons, 3 the supply balloon
const NBOAT: i32 = 2;
const NDRONE: i32 = 6;
const NPOP: i32 = 5;
const NLABEL: i32 = 6;
const UMAX: f64 = 6.9;
const VMIN: f64 = -4.0;
const VMAX: f64 = 4.9;

const READY: i32 = 0;
const PLAY: i32 = 1;
const OVER: i32 = 2;

// drone paths
const D_V: i32 = 0;       // a V formation: dive, then peel off to the sides
const D_SWEEP: i32 = 1;   // a line crossing the screen on a wave
const D_DIVE: i32 = 2;    // launched by the boss: straight at where the plane was

// boss
const B_OFF: i32 = 0;
const B_WARN: i32 = 1;
const B_ENTER: i32 = 2;
const B_FIGHT: i32 = 3;
const B_DIE: i32 = 4;

// sound: a chain of kills climbs this run (C major pentatonic, MIDI)
const CHAIN: StaticArray<f64> = [72, 74, 76, 79, 81, 84, 86, 88];

function clamp(x: f64, a: f64, b: f64): f64 { return x < a ? a : (x > b ? b : x); }
function rad(d: f64): f64 { return d * Math.PI / 180.0; }
function deg(r: f64): f64 { return r * 180.0 / Math.PI; }
function snapU(u: f64): f64 { return Math.round(u / TEX) * TEX; }
function snapV(v: f64): f64 { return Math.round(v / VSTEP) * VSTEP; }

export class Game {
    // ---- bones
    tileB: StaticArray<i32> = new StaticArray<i32>(NTILE);
    plane: i32 = -1;
    prop: i32 = -1;
    shotB: StaticArray<i32> = new StaticArray<i32>(NSHOT);
    bulB: StaticArray<i32> = new StaticArray<i32>(NBUL);
    balB: StaticArray<i32> = new StaticArray<i32>(NBAL);
    boatB: StaticArray<i32> = new StaticArray<i32>(NBOAT);
    turB: StaticArray<i32> = new StaticArray<i32>(NBOAT);
    droneB: StaticArray<i32> = new StaticArray<i32>(NDRONE);
    boss: i32 = -1;
    gunB: StaticArray<i32> = new StaticArray<i32>(2);
    popB: StaticArray<i32> = new StaticArray<i32>(NPOP);
    crate: i32 = -1;

    // ---- the world scroll
    dist: f64 = 0;          // metres flown
    speed: f64 = 2.4;       // metres a second
    g: f64 = 0;             // the snapped camera's ground point (world z)
    wrapK: f64 = 0;         // world wraps so far (12 m each)
    tileS: StaticArray<f64> = new StaticArray<f64>(NTILE);   // a tile's start distance (-1e9: free)
    tileYaw: StaticArray<f64> = new StaticArray<f64>(NTILE);
    nextS: f64 = -12;
    lastKind: i32 = -1;
    riverReq: i32 = 0;      // river tiles wanted (each brings a gunboat)

    // ---- the plane
    pu: f64 = 0;
    pv: f64 = 3.0;
    pvu: f64 = 0;
    pvv: f64 = 0;
    tu: f64 = 0;            // where it is steered (the pointer, or the demo's hand)
    tv: f64 = 3.0;
    roll: f64 = 0;
    alive: bool = true;
    deadT: f64 = -9;
    safeUntil: f64 = 0;
    lives: i32 = 3;
    power: i32 = 1;
    fireT: f64 = 0;
    volleys: i32 = 0;
    lastPower: f64 = -9;

    // ---- player shots
    sOn: StaticArray<bool> = new StaticArray<bool>(NSHOT);
    sU: StaticArray<f64> = new StaticArray<f64>(NSHOT);
    sV: StaticArray<f64> = new StaticArray<f64>(NSHOT);
    sVU: StaticArray<f64> = new StaticArray<f64>(NSHOT);
    sVV: StaticArray<f64> = new StaticArray<f64>(NSHOT);

    // ---- enemy bullets
    eOn: StaticArray<bool> = new StaticArray<bool>(NBUL);
    eU: StaticArray<f64> = new StaticArray<f64>(NBUL);
    eV: StaticArray<f64> = new StaticArray<f64>(NBUL);
    eVU: StaticArray<f64> = new StaticArray<f64>(NBUL);
    eVV: StaticArray<f64> = new StaticArray<f64>(NBUL);
    eH0: StaticArray<f64> = new StaticArray<f64>(NBUL);       // altitude it was fired from (rises to 3)
    eT: StaticArray<f64> = new StaticArray<f64>(NBUL);

    // ---- balloons (slot 3: the supply balloon)
    bOn: StaticArray<bool> = new StaticArray<bool>(NBAL);
    bU: StaticArray<f64> = new StaticArray<f64>(NBAL);
    bV: StaticArray<f64> = new StaticArray<f64>(NBAL);
    bHp: StaticArray<i32> = new StaticArray<i32>(NBAL);
    bT: StaticArray<f64> = new StaticArray<f64>(NBAL);
    bFire: StaticArray<f64> = new StaticArray<f64>(NBAL);      // next shot (telegraph starts 0.5 s before)
    bHit: StaticArray<f64> = new StaticArray<f64>(NBAL);

    // ---- gunboats: on a river tile, sailing along it
    gOn: StaticArray<bool> = new StaticArray<bool>(NBOAT);
    gTile: StaticArray<i32> = new StaticArray<i32>(NBOAT);
    gX: StaticArray<f64> = new StaticArray<f64>(NBOAT);
    gDir: StaticArray<f64> = new StaticArray<f64>(NBOAT);
    gHp: StaticArray<i32> = new StaticArray<i32>(NBOAT);
    gFire: StaticArray<f64> = new StaticArray<f64>(NBOAT);
    gAim: StaticArray<f64> = new StaticArray<f64>(NBOAT);      // turret yaw (world degrees)
    gHit: StaticArray<f64> = new StaticArray<f64>(NBOAT);
    gSink: StaticArray<f64> = new StaticArray<f64>(NBOAT);     // -9: afloat

    // ---- drones
    dOn: StaticArray<bool> = new StaticArray<bool>(NDRONE);
    dMode: StaticArray<i32> = new StaticArray<i32>(NDRONE);
    dU: StaticArray<f64> = new StaticArray<f64>(NDRONE);
    dV: StaticArray<f64> = new StaticArray<f64>(NDRONE);
    dVU: StaticArray<f64> = new StaticArray<f64>(NDRONE);
    dVV: StaticArray<f64> = new StaticArray<f64>(NDRONE);
    dT: StaticArray<f64> = new StaticArray<f64>(NDRONE);       // spawn time
    dA: StaticArray<f64> = new StaticArray<f64>(NDRONE);       // path parameter (turn time, base v)
    dB: StaticArray<f64> = new StaticArray<f64>(NDRONE);       // side / direction
    dFire: StaticArray<f64> = new StaticArray<f64>(NDRONE);    // shot time after spawn (-1: none)
    dHit: StaticArray<f64> = new StaticArray<f64>(NDRONE);

    // ---- the boss
    bossState: i32 = B_OFF;
    bossT: f64 = 0;
    bossU: f64 = 0;
    bossV: f64 = -9;
    bossYaw: f64 = 90;
    bossHp: i32 = 0;
    bossHp0: i32 = 1;
    bossHit: f64 = -9;
    bossPat: i32 = 0;
    bossNext: f64 = 0;      // the next pattern's telegraph start (fight time)
    bossTele: f64 = -9;     // the current telegraph's start
    bossKind: i32 = -1;     // the telegraphed pattern
    bossShots: i32 = 0;     // shots of the pattern still to fire
    bossShotT: f64 = 0;
    gunAim: StaticArray<f64> = new StaticArray<f64>(2);
    bossFight: f64 = 0;

    // ---- crate (power-up)
    cOn: bool = false;
    cU: f64 = 0;
    cV: f64 = 0;
    cT: f64 = 0;

    // ---- pops and labels
    pT: StaticArray<f64> = new StaticArray<f64>(NPOP);
    pU: StaticArray<f64> = new StaticArray<f64>(NPOP);
    pV: StaticArray<f64> = new StaticArray<f64>(NPOP);
    pH: StaticArray<f64> = new StaticArray<f64>(NPOP);
    pS: StaticArray<f64> = new StaticArray<f64>(NPOP);
    nextPop: i32 = 0;
    lT: StaticArray<f64> = new StaticArray<f64>(NLABEL);
    lU: StaticArray<f64> = new StaticArray<f64>(NLABEL);
    lV: StaticArray<f64> = new StaticArray<f64>(NLABEL);
    lH: StaticArray<f64> = new StaticArray<f64>(NLABEL);
    lS: Array<string> = ["", "", "", "", "", ""];
    nextLabel: i32 = 0;

    // ---- the run
    state: i32 = READY;
    t: f64 = 0;
    runT: f64 = 0;
    overT: f64 = 0;
    wave: i32 = 0;
    waveT: f64 = 0;
    loop: i32 = 0;
    bannerT: f64 = -9;
    banner: string = "";
    score: i32 = 0;
    best: i32 = 0;
    demoBest: i32 = 0;
    best0: i32 = 0;
    wasDemo: bool = false;
    shake: f64 = -9;
    chain: i32 = 0;
    chainT: f64 = -9;
    lastHitSnd: f64 = -9;

    held: bool = false;     // a finger (or the button) is down

    // ---- the demo's hand
    aiNext: f64 = 0;
    aiLapse: f64 = -9;
    aiU: f64 = 0;
    aiV: f64 = 3.0;

    // ------------------------------------------------------------ setup

    start(api: GameApi): void {
        api.playable = true;
        let names: Array<string> = ["fieldsA", "fieldsB", "villageA", "villageB", "woodsA", "woodsB", "riverA", "riverB"];
        for (let i = 0; i < NTILE; i++) this.tileB[i] = api.bone(names[i]);
        this.plane = api.bone("plane");
        this.prop = api.bone("prop");
        for (let i = 0; i < NSHOT; i++) this.shotB[i] = api.bone("shot" + i.toString());
        for (let i = 0; i < NBUL; i++) this.bulB[i] = api.bone("bullet" + i.toString());
        for (let i = 0; i < 3; i++) this.balB[i] = api.bone("balloon" + i.toString());
        this.balB[3] = api.bone("supply");
        for (let i = 0; i < NBOAT; i++) {
            this.boatB[i] = api.bone("boat" + i.toString());
            this.turB[i] = api.bone("turret" + i.toString());
        }
        for (let i = 0; i < NDRONE; i++) this.droneB[i] = api.bone("drone" + i.toString());
        this.boss = api.bone("boss");
        this.gunB[0] = api.bone("bossgun0");
        this.gunB[1] = api.bone("bossgun1");
        for (let i = 0; i < NPOP; i++) this.popB[i] = api.bone("pop" + i.toString());
        this.crate = api.bone("crate");
        // the first ground: fields under the plane, a village coming up
        for (let i = 0; i < NTILE; i++) this.tileS[i] = -1e9;
        this.placeTile(api, 0, -12);
        this.placeTile(api, 2, -6);
        this.placeTile(api, 1, 0);
        this.placeTile(api, 4, 6);
        this.nextS = 12;
        this.lastKind = 2;
        this.wasDemo = api.demo;
        this.clearRun();
        if (api.demo) this.begin(api);
    }

    // ------------------------------------------------------------ run control

    clearRun(): void {
        for (let i = 0; i < NSHOT; i++) this.sOn[i] = false;
        for (let i = 0; i < NBUL; i++) this.eOn[i] = false;
        for (let i = 0; i < NBAL; i++) this.bOn[i] = false;
        for (let i = 0; i < NDRONE; i++) this.dOn[i] = false;
        for (let i = 0; i < NBOAT; i++) {
            if (this.gOn[i] && this.gSink[i] < 0) this.gSink[i] = this.t;   // boats of the last run sink
        }
        for (let i = 0; i < NPOP; i++) this.pT[i] = -9;
        for (let i = 0; i < NLABEL; i++) this.lT[i] = -9;
        this.cOn = false;
        this.bossState = B_OFF;
        this.riverReq = 0;
    }

    begin(api: GameApi): void {
        this.clearRun();
        this.state = PLAY;
        this.runT = 0;
        this.score = 0;
        this.lives = 3;
        this.power = 1;
        this.loop = 0;
        this.wave = 0;
        this.waveT = 0;
        this.speed = 2.4;
        this.alive = true;
        this.safeUntil = this.t + 1.5;
        this.fireT = 0;
        this.chain = 0;
        this.best0 = api.demo ? this.demoBest : this.best;
        this.aiNext = 0;
        this.aiLapse = -9;
        // a first pair of balloons already in view: a run (and the demo) opens on action
        this.spawnBalloon(api, 0, -2.0, -3.4, false);
        this.spawnBalloon(api, 1, 2.6, -4.6, false);
        this.showBanner("TAKE OFF!");
        api.sound(SFX_WIN, 1.0, 0.55);
        api.note(72, 0.35, 0, SFX_NOTE, 0.0);
        api.note(76, 0.35, 0, SFX_NOTE, 0.1);
        api.note(79, 0.35, 0, SFX_NOTE, 0.2);
    }

    showBanner(s: string): void {
        this.banner = s;
        this.bannerT = this.t;
    }

    bumpBest(): void {
        if (this.wasDemo) {
            if (this.score > this.demoBest) this.demoBest = this.score;
        } else if (this.score > this.best) {
            this.best = this.score;
        }
    }

    addScore(api: GameApi, n: i32, u: f64, v: f64, h: f64): void {
        this.score += n;
        this.bumpBest();
        this.label(u, v, h, "+" + n.toString());
    }

    // ------------------------------------------------------------ helpers: placing in logic coordinates

    // a sprite at logic (u, v) and altitude h, on the art grid
    put(api: GameApi, b: i32, u: f64, v: f64, h: f64, yaw: f64, pitch: f64, roll: f64, s: f64): void {
        api.place(b, snapU(u), h, this.g + snapV(v) + h * COT, yaw, pitch, roll, s);
    }

    // the logic point of a world point on the ground (y = 0)
    groundV(z: f64): f64 { return z - this.g; }

    // ------------------------------------------------------------ the ground

    tileZ(i: i32): f64 { return -(this.tileS[i] + TILE * 0.5) + this.wrapK * WRAP; }

    placeTile(api: GameApi, i: i32, s: f64): void {
        this.tileS[i] = s;
        this.tileYaw[i] = 0;
    }

    // a free tile of a kind (0 fields, 1 village, 2 woods, 3 river), or any free one
    freeTile(kind: i32, api: GameApi): i32 {
        let a = kind * 2;
        let first = api.rand() < 0.5 ? 0 : 1;
        for (let k = 0; k < 2; k++) {
            let i = a + ((first + k) % 2);
            if (this.tileS[i] < -1e8) return i;
        }
        for (let i = 0; i < NTILE; i++) if (this.tileS[i] < -1e8) return i;
        return -1;
    }

    stepTiles(api: GameApi): void {
        // free the tiles that have scrolled past the bottom
        for (let i = 0; i < NTILE; i++) {
            if (this.tileS[i] > -1e8 && this.tileS[i] + TILE < this.dist - 8.0) this.tileS[i] = -1e9;
        }
        // lay new ones ahead
        while (this.nextS < this.dist + 13.0) {
            let kind: i32;
            if (this.riverReq > 0) {
                kind = 3;
            } else {
                // fields most often, never the same kind twice running, no river unasked
                let r = api.rand();
                kind = r < 0.45 ? 0 : (r < 0.72 ? 1 : 2);
                if (kind == this.lastKind) kind = (kind + 1 + (api.rand() < 0.5 ? 0 : 1)) % 3;
            }
            let i = this.freeTile(kind, api);
            if (i < 0) break;
            this.tileS[i] = this.nextS;
            this.tileYaw[i] = api.rand() < 0.5 ? 0 : 180;
            this.lastKind = i / 2;
            if (i >= 6 && this.riverReq > 0) {
                this.riverReq--;
                this.spawnBoat(api, i);
            }
            this.nextS += TILE;
        }
    }

    // ------------------------------------------------------------ spawning

    spawnBalloon(api: GameApi, k: i32, u: f64, v: f64, supply: bool): void {
        if (k < 0 || k >= NBAL || this.bOn[k]) return;
        this.bOn[k] = true;
        this.bU[k] = u;
        this.bV[k] = v;
        this.bHp[k] = supply ? 4 : 6;
        this.bT[k] = this.t;
        this.bFire[k] = supply ? 1e9 : this.t + api.range(0.9, 1.7) / this.fireK();
        this.bHit[k] = -9;
    }

    freeBalloon(): i32 {
        for (let i = 0; i < 3; i++) if (!this.bOn[i]) return i;
        return -1;
    }

    spawnBoat(api: GameApi, tile: i32): void {
        for (let k = 0; k < NBOAT; k++) {
            if (this.gOn[k]) continue;
            this.gOn[k] = true;
            this.gTile[k] = tile;
            let side = api.rand() < 0.5 ? -1.0 : 1.0;
            this.gX[k] = side * api.range(4.0, 5.5);
            this.gDir[k] = -side;
            this.gHp[k] = 26 + this.loop * 6;
            this.gFire[k] = this.t + 0.7;
            this.gAim[k] = 180;
            this.gHit[k] = -9;
            this.gSink[k] = -9;
            return;
        }
    }

    spawnDrone(mode: i32, u: f64, v: f64, a: f64, b: f64, fireAt: f64): void {
        for (let k = 0; k < NDRONE; k++) {
            if (this.dOn[k]) continue;
            this.dOn[k] = true;
            this.dMode[k] = mode;
            this.dU[k] = u;
            this.dV[k] = v;
            this.dVU[k] = 0;
            this.dVV[k] = 0;
            this.dT[k] = this.t;
            this.dA[k] = a;
            this.dB[k] = b;
            this.dFire[k] = fireAt;
            this.dHit[k] = -9;
            if (mode == D_SWEEP) { this.dVU[k] = b * 3.4; }
            if (mode == D_DIVE) { this.dVU[k] = a; this.dVV[k] = b; }
            return;
        }
    }

    fireK(): f64 { return 1.0 + 0.22 * <f64>this.loop; }
    bulletSpeed(): f64 { return 3.3 * (1.0 + 0.12 * <f64>this.loop); }

    // an enemy bullet from (u, v) towards the plane, turned by `off` degrees
    shoot(api: GameApi, u: f64, v: f64, h: f64, off: f64, speed: f64): void {
        let dx = this.pu - u, dy = this.pv - v;
        let l = Math.sqrt(dx * dx + dy * dy);
        if (l < 0.01) { dx = 0; dy = 1; l = 1; }
        let a = Math.atan2(dy, dx) + rad(off);
        this.shootDir(u, v, h, Math.cos(a) * speed, Math.sin(a) * speed);
    }

    shootDir(u: f64, v: f64, h: f64, vu: f64, vv: f64): void {
        for (let i = 0; i < NBUL; i++) {
            if (this.eOn[i]) continue;
            this.eOn[i] = true;
            this.eU[i] = u; this.eV[i] = v;
            this.eVU[i] = vu; this.eVV[i] = vv;
            this.eH0[i] = h;
            this.eT[i] = this.t;
            return;
        }
    }

    pop(u: f64, v: f64, h: f64, s: f64): void {
        let k = this.nextPop;
        this.nextPop = (k + 1) % NPOP;
        this.pT[k] = this.t; this.pU[k] = u; this.pV[k] = v; this.pH[k] = h; this.pS[k] = s;
    }

    label(u: f64, v: f64, h: f64, s: string): void {
        let k = this.nextLabel;
        this.nextLabel = (k + 1) % NLABEL;
        this.lT[k] = this.t; this.lU[k] = u; this.lV[k] = v; this.lH[k] = h; this.lS[k] = s;
    }

    // ------------------------------------------------------------ waves

    at(t: f64, dt: f64): bool { return this.waveT >= t && this.waveT - dt < t; }

    enemiesLeft(): i32 {
        let n = 0;
        for (let i = 0; i < NBAL; i++) if (this.bOn[i]) n++;
        for (let i = 0; i < NDRONE; i++) if (this.dOn[i]) n++;
        for (let i = 0; i < NBOAT; i++) if (this.gOn[i] && this.gSink[i] < 0) n++;
        return n;
    }

    bulletsUp(): i32 {
        let n = 0;
        for (let i = 0; i < NBUL; i++) if (this.eOn[i]) n++;
        return n;
    }

    nextWave(api: GameApi): void {
        this.wave++;
        this.waveT = 0;
        if (this.wave > 5) {
            this.wave = 0;
            this.loop++;
            this.speed = 2.4 * (1.0 + 0.12 * <f64>this.loop);
            this.showBanner("LOOP " + (this.loop + 1).toString() + " - FASTER!");
            api.note(72, 0.4, 0, SFX_BELL);
            api.note(79, 0.4, 0, SFX_BELL, 0.15);
            api.note(84, 0.4, 0, SFX_BELL, 0.3);
        }
    }

    stepWaves(api: GameApi, dt: f64): void {
        this.waveT += dt;
        let w = this.wave;
        let left = this.enemiesLeft();
        if (w == 0) {
            // balloons drifting in (two are already up from begin), then the supply balloon
            if (this.at(1.6, dt)) this.spawnBalloon(api, this.freeBalloon(), api.range(-5, 5), -6.6, false);
            if (this.at(3.4, dt)) this.spawnBalloon(api, 3, api.range(-4, 4), -6.6, true);
            if (this.at(5.0, dt)) this.spawnBalloon(api, this.freeBalloon(), api.range(-5, 5), -6.6, false);
            if ((this.waveT > 6.5 && left == 0) || this.waveT > 11) this.nextWave(api);
        } else if (w == 1) {
            // a V of five drones dives in, then peels off to both sides
            if (this.at(0.6, dt)) {
                let cu = clamp(this.pu * 0.5, -3, 3);
                for (let k = 0; k < 5; k++) {
                    let o = <f64>(k - 2);
                    let fire = api.range(0.7, 1.3);
                    this.spawnDrone(D_V, cu + o * 1.05, -6.4 - Math.abs(o) * 0.75, 1.75 + Math.abs(o) * 0.1, o < 0 ? -1 : (o > 0 ? 1 : (api.rand() < 0.5 ? -1 : 1)), fire);
                }
                api.sound(SFX_WHOOSH, 1.3, 0.35);
            }
            if ((this.waveT > 3 && left == 0) || this.waveT > 9) this.nextWave(api);
        } else if (w == 2) {
            // a river with a gunboat; balloons over it
            if (this.at(0.05, dt)) this.riverReq = 1;
            if (this.at(2.5, dt)) this.spawnBalloon(api, this.freeBalloon(), api.range(-5, -1), -6.6, false);
            if (this.at(4.5, dt)) this.spawnBalloon(api, this.freeBalloon(), api.range(1, 5), -6.6, false);
            if ((this.waveT > 7 && left == 0) || this.waveT > 15) this.nextWave(api);
        } else if (w == 3) {
            // a line of drones sweeps across on a wave; from the second loop a second line comes back
            if (this.at(0.4, dt)) {
                let dir = api.rand() < 0.5 ? 1.0 : -1.0;
                for (let k = 0; k < 4; k++) {
                    this.spawnDrone(D_SWEEP, -dir * (8.6 + <f64>k * 1.15), -3.9, -3.9, dir, api.range(1.6, 3.4));
                }
                api.sound(SFX_WHOOSH, 1.1, 0.35);
            }
            if (this.loop > 0 && this.at(3.4, dt)) {
                let dir = this.dB[0] > 0 ? -1.0 : 1.0;
                for (let k = 0; k < 2; k++) this.spawnDrone(D_SWEEP, -dir * (8.6 + <f64>k * 1.15), -2.4, -2.4, dir, api.range(1.5, 2.6));
            }
            if ((this.waveT > 4 && left == 0) || this.waveT > 11) this.nextWave(api);
        } else if (w == 4) {
            // a river with a gunboat, a pair of drones diving, the supply balloon
            if (this.at(0.05, dt)) this.riverReq = 1;
            if (this.at(1.0, dt)) this.spawnBalloon(api, 3, api.range(-4, 4), -6.6, true);
            if (this.at(3.6, dt)) {
                for (let k = 0; k < 2; k++) {
                    let u = k == 0 ? -4.5 : 4.5;
                    this.spawnDrone(D_DIVE, u, -6.4, (this.pu - u) * 0.28, 3.4, 1.0);
                }
                api.sound(SFX_WHOOSH, 1.2, 0.35);
            }
            if ((this.waveT > 8 && left == 0) || this.waveT > 15) this.nextWave(api);
        } else if (w == 5) {
            // the boss
            if (this.at(0.05, dt)) {
                this.bossState = B_WARN;
                this.bossT = 0;
                this.showBanner("WARNING!");
                // a two-tone siren
                for (let k = 0; k < 4; k++) {
                    api.note(<f64>(k % 2 == 0 ? 69 : 64), 0.45, 0, SFX_BELL, <f64>k * 0.38);
                }
            }
            if (this.bossState == B_OFF && this.waveT > 1) this.nextWave(api);
        }
    }

    // ------------------------------------------------------------ the frame

    update(api: GameApi): void {
        this.t = api.time;
        let dt = api.dt;

        if (api.demoChanged || api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.begin(api);
        }
        if (this.state == OVER && api.demo && this.t - this.overT > 2.0) this.begin(api);

        // the scroll: the camera flies forward; the world wraps every 12 m
        this.dist += this.speed * dt;
        this.wrapK = Math.floor(this.dist / WRAP);
        let cz = -(this.dist - this.wrapK * WRAP);
        // a hit shakes the camera by whole art pixels
        let ks = this.t - this.shake;
        let sx = 0.0, sz = 0.0;
        if (ks < 0.3) {
            let amp = 0.16 * (1 - ks / 0.3);
            sx = Math.sin(ks * 95) * amp;
            sz = Math.cos(ks * 70) * amp;
        }
        api.targetX = sx;
        api.targetY = 0;
        api.targetZ = cz + sz;
        // the renderer snaps the target along the view: the ground point it ends up on
        let su = Math.round(-(cz + sz) * SINP / TEX) * TEX;
        this.g = -su / SINP;
        this.stepTiles(api);

        if (this.state == PLAY) {
            this.runT += dt;
            if (api.demo) this.think(api);
            this.stepWaves(api, dt);
        } else if (this.state == READY) {
            // waiting for the first click: the plane weaves gently over the fields
            this.tu = Math.sin(this.t * 0.6) * 2.2;
            this.tv = 3.0 + Math.sin(this.t * 0.9) * 0.4;
        }

        this.stepPlane(api, dt);
        this.stepShots(api, dt);
        this.stepBalloons(api, dt);
        this.stepDrones(api, dt);
        this.stepBoats(api, dt);
        this.stepBoss(api, dt);
        this.stepBullets(api, dt);
        this.stepCrate(api, dt);
        this.draw(api);
    }

    // ------------------------------------------------------------ the plane

    stepPlane(api: GameApi, dt: f64): void {
        if (!this.alive) {
            if (this.state == PLAY && this.t - this.deadT > 1.3) {
                // back in from the bottom edge
                this.alive = true;
                this.pu = 0;
                this.pv = 6.2;
                this.pvu = 0;
                this.pvv = 0;
                this.safeUntil = this.t + 2.4;
                api.sound(SFX_WHOOSH, 0.9, 0.5);
            }
            return;
        }
        let tu = clamp(this.tu, -UMAX, UMAX), tv = clamp(this.tv, VMIN, VMAX);
        // follow with a little lag: a spring towards the target, capped speed
        let wu = (tu - this.pu) * 9.0, wv = (tv - this.pv) * 9.0;
        let l = Math.sqrt(wu * wu + wv * wv);
        if (l > 14.0) { wu *= 14.0 / l; wv *= 14.0 / l; }
        let k = 1.0 - Math.exp(-dt * 14.0);
        this.pvu += (wu - this.pvu) * k;
        this.pvv += (wv - this.pvv) * k;
        this.pu += this.pvu * dt;
        this.pv += this.pvv * dt;
        let want = clamp(this.pvu * 5.0, -42, 42);
        this.roll += (want - this.roll) * (1.0 - Math.exp(-dt * 10.0));

        // fire while a run is on
        if (this.state == PLAY) {
            this.fireT -= dt;
            if (this.fireT <= 0) {
                this.fireT += this.power >= 3 ? 0.16 : 0.13;
                if (this.fireT < 0) this.fireT = 0;
                this.volley(api);
            }
        }
    }

    volley(api: GameApi): void {
        let n = this.power == 1 ? 1 : (this.power == 2 ? 3 : 5);
        let spread: StaticArray<f64> = [0, -9, 9, -19, 19];
        for (let j = 0; j < n; j++) {
            for (let i = 0; i < NSHOT; i++) {
                if (this.sOn[i]) continue;
                let a = rad(spread[j]);
                this.sOn[i] = true;
                // the twin guns fire from the nose, the side shots from the wings
                let side = j == 0 ? 0.0 : (j <= 2 ? 0.5 : 0.85);
                this.sU[i] = this.pu + (spread[j] < 0 ? -side : side);
                this.sV[i] = this.pv - (j == 0 ? 0.85 : 0.45);
                this.sVU[i] = Math.sin(a) * 15.0;
                this.sVV[i] = -Math.cos(a) * 15.0;
                break;
            }
        }
        this.volleys++;
        // a quiet tick every other volley (the guns' rattle)
        if (this.volleys % 2 == 0) {
            api.sound(SFX_TICK, this.volleys % 4 == 0 ? 1.7 : 1.5, 0.22, clamp(this.pu / 8, -0.6, 0.6));
        }
    }

    hurt(api: GameApi): void {
        if (!this.alive || this.state != PLAY || this.t < this.safeUntil) return;
        this.alive = false;
        this.deadT = this.t;
        this.lives--;
        this.shake = this.t;
        this.chain = 0;
        this.pop(this.pu, this.pv, PH, 1.0);
        this.pop(this.pu + 0.5, this.pv - 0.3, PH, 0.7);
        api.soundAt(SFX_HIT, this.pu, PH, this.g + this.pv, 0.8, 0.9);
        api.soundAt(SFX_EXPLODE, this.pu, PH, this.g + this.pv, 0.65, 0.9, 0.06);
        // the bullets in the air are cleared: the next life starts fair
        for (let i = 0; i < NBUL; i++) {
            if (this.eOn[i]) { this.eOn[i] = false; }
        }
        if (this.power > 1) this.power--;
        if (this.lives <= 0) {
            this.state = OVER;
            this.overT = this.t;
            api.sound(SFX_LOSE, 0.9, 0.8, 0, 0.5);
            if (!this.wasDemo && this.best > this.best0) api.note(84, 0.5, 0, SFX_BELL, 1.3);
        }
    }

    // ------------------------------------------------------------ shots and what they hit

    stepShots(api: GameApi, dt: f64): void {
        for (let i = 0; i < NSHOT; i++) {
            if (!this.sOn[i]) continue;
            this.sU[i] += this.sVU[i] * dt;
            this.sV[i] += this.sVV[i] * dt;
            let u = this.sU[i], v = this.sV[i];
            if (v < -6.8 || Math.abs(u) > 8.5) { this.sOn[i] = false; continue; }
            if (this.hitSomething(api, u, v)) this.sOn[i] = false;
        }
    }

    hitSound(api: GameApi, u: f64, pitch: f64): void {
        if (this.t - this.lastHitSnd < 0.06) return;
        this.lastHitSnd = this.t;
        api.sound(SFX_CLICK, pitch, 0.32, clamp(u / 8, -0.7, 0.7));
    }

    killNote(api: GameApi, u: f64): void {
        if (this.t - this.chainT > 2.5) this.chain = 0;
        this.chainT = this.t;
        api.note(CHAIN[min<i32>(this.chain, CHAIN.length - 1)], 0.32, clamp(u / 8, -0.7, 0.7), SFX_NOTE, 0.05);
        this.chain++;
    }

    hitSomething(api: GameApi, u: f64, v: f64): bool {
        // balloons
        for (let k = 0; k < NBAL; k++) {
            if (!this.bOn[k]) continue;
            let du = u - this.bU[k], dv = v - this.bV[k];
            if (du * du + dv * dv < 0.62 * 0.62) {
                this.bHp[k]--;
                this.bHit[k] = this.t;
                if (this.bHp[k] <= 0) {
                    this.bOn[k] = false;
                    this.pop(this.bU[k], this.bV[k], 3.4, 0.85);
                    api.soundAt(SFX_POP, this.bU[k], 3.4, this.g + this.bV[k], 0.8, 0.8);
                    api.soundAt(SFX_EXPLODE, this.bU[k], 3.4, this.g + this.bV[k], 1.5, 0.45);
                    this.killNote(api, this.bU[k]);
                    if (k == 3) {
                        this.addScore(api, 150, this.bU[k], this.bV[k], 3.4);
                        this.cOn = true; this.cU = this.bU[k]; this.cV = this.bV[k]; this.cT = this.t;
                        api.sound(SFX_BLIP, 1.5, 0.4, 0, 0.12);
                    } else {
                        this.addScore(api, 100, this.bU[k], this.bV[k], 3.4);
                    }
                } else {
                    this.hitSound(api, u, 1.4);
                }
                return true;
            }
        }
        // drones
        for (let k = 0; k < NDRONE; k++) {
            if (!this.dOn[k]) continue;
            let du = u - this.dU[k], dv = v - this.dV[k];
            if (du * du + dv * dv < 0.5 * 0.5) {
                this.dOn[k] = false;
                this.pop(this.dU[k], this.dV[k], 2.4, 0.6);
                api.soundAt(SFX_EXPLODE, this.dU[k], 2.4, this.g + this.dV[k], 1.7, 0.5);
                this.killNote(api, this.dU[k]);
                this.addScore(api, 50, this.dU[k], this.dV[k], 2.4);
                return true;
            }
        }
        // gunboats (on the water: their logic point is where the river shows)
        for (let k = 0; k < NBOAT; k++) {
            if (!this.gOn[k] || this.gSink[k] >= 0) continue;
            let bv = this.groundV(this.tileZ(this.gTile[k]));
            let du = u - this.gX[k], dv = v - bv;
            if (Math.abs(du) < 1.25 && Math.abs(dv) < 0.65) {
                this.gHp[k]--;
                this.gHit[k] = this.t;
                if (this.gHp[k] <= 0) {
                    this.gSink[k] = this.t;
                    this.pop(this.gX[k], bv, 0.3, 1.0);
                    this.shake = this.t;
                    api.soundAt(SFX_EXPLODE, this.gX[k], 0, this.g + bv, 0.9, 0.85);
                    api.soundAt(SFX_SPLASH, this.gX[k], 0, this.g + bv, 0.8, 0.6, 0.18);
                    this.killNote(api, this.gX[k]);
                    this.addScore(api, 250, this.gX[k], bv, 0.4);
                } else {
                    this.hitSound(api, u, 1.0);
                }
                return true;
            }
        }
        // the boss
        if (this.bossState == B_FIGHT || (this.bossState == B_ENTER && this.bossV > -5.0)) {
            let sy = Math.abs(Math.sin(rad(this.bossYaw))), cy = Math.abs(Math.cos(rad(this.bossYaw)));
            let ru = 0.95 + 1.75 * sy, rv = 0.95 + 1.75 * cy;
            let du = (u - this.bossU) / ru, dv = (v - this.bossV) / rv;
            if (du * du + dv * dv < 1.0) {
                this.bossHp--;
                this.bossHit = this.t;
                if (this.bossHp <= 0) {
                    this.bossState = B_DIE;
                    this.bossT = 0;
                    this.score += 2000 * (this.loop + 1);
                    this.bumpBest();
                    this.label(this.bossU, this.bossV, 3.6, "+" + (2000 * (this.loop + 1)).toString());
                    for (let i = 0; i < NBUL; i++) this.eOn[i] = false;
                    // a chain of bursts, then the big one and a fanfare
                    for (let j = 0; j < 5; j++) {
                        api.soundAt(SFX_EXPLODE, this.bossU + <f64>(j - 2) * 0.8, 3.6, this.g + this.bossV,
                            1.1 - <f64>j * 0.08, 0.75, <f64>j * 0.28);
                    }
                    api.sound(SFX_EXPLODE, 0.55, 1.0, 0, 1.45);
                    api.sound(SFX_WIN, 1.0, 0.6, 0, 1.9);
                } else {
                    if (this.t - this.lastHitSnd >= 0.07) {
                        this.lastHitSnd = this.t;
                        api.sound(SFX_TICK, 0.8 + 0.4 * <f64>this.bossHp / <f64>this.bossHp0, 0.4, clamp(u / 8, -0.7, 0.7));
                    }
                }
                return true;
            }
        }
        return false;
    }

    // ------------------------------------------------------------ balloons

    stepBalloons(api: GameApi, dt: f64): void {
        for (let k = 0; k < NBAL; k++) {
            if (!this.bOn[k]) continue;
            // they drift with the wind, slower than the ground: the plane overtakes them
            this.bV[k] += 1.25 * (1.0 + 0.1 * <f64>this.loop) * dt;
            this.bU[k] += Math.sin((this.t - this.bT[k]) * 0.8 + <f64>k * 2.0) * 0.35 * dt;
            if (this.bV[k] > 6.8) { this.bOn[k] = false; continue; }
            // a slow aimed shot every few seconds while well in view (telegraphed 0.5 s before)
            if (this.state == PLAY && this.t >= this.bFire[k]) {
                if (this.bV[k] > -4.6 && this.bV[k] < 2.0 && this.alive) {
                    this.shoot(api, this.bU[k], this.bV[k] + 0.5, 2.6, 0, this.bulletSpeed());
                    api.soundAt(SFX_ZAP, this.bU[k], 3.4, this.g + this.bV[k], 0.7, 0.3);
                }
                this.bFire[k] = this.t + api.range(1.5, 2.2) / this.fireK();
            }
            // the plane flying into one
            if (this.alive) {
                let du = this.pu - this.bU[k], dv = this.pv - this.bV[k];
                if (du * du + dv * dv < 0.7 * 0.7) this.hurt(api);
            }
        }
    }

    // ------------------------------------------------------------ drones

    stepDrones(api: GameApi, dt: f64): void {
        for (let k = 0; k < NDRONE; k++) {
            if (!this.dOn[k]) continue;
            let age = this.t - this.dT[k];
            let m = this.dMode[k];
            if (m == D_V) {
                if (age < this.dA[k]) {
                    this.dVV[k] = 3.3 * (1.0 + 0.1 * <f64>this.loop);
                    this.dVU[k] = 0;
                } else {
                    // peel off: swing out to its side, slowing its dive
                    let q = 1.0 - Math.exp(-dt * 3.0);
                    this.dVU[k] += (this.dB[k] * 5.0 - this.dVU[k]) * q;
                    this.dVV[k] += (0.6 - this.dVV[k]) * q;
                }
                this.dU[k] += this.dVU[k] * dt;
                this.dV[k] += this.dVV[k] * dt;
            } else if (m == D_SWEEP) {
                this.dU[k] += this.dVU[k] * (1.0 + 0.1 * <f64>this.loop) * dt;
                let nv = this.dA[k] + 1.15 * Math.sin(this.dU[k] * 0.75 * this.dB[k]);
                this.dVV[k] = (nv - this.dV[k]) / Math.max(dt, 0.001);
                this.dV[k] = nv;
            } else {
                this.dU[k] += this.dVU[k] * dt;
                this.dV[k] += this.dVV[k] * dt;
            }
            if (this.dFire[k] >= 0 && age >= this.dFire[k]) {
                this.dFire[k] = -1;
                if (this.state == PLAY && this.alive && this.dV[k] < 2.5 && this.dV[k] > -5.2 && Math.abs(this.dU[k]) < 7.2) {
                    this.shoot(api, this.dU[k], this.dV[k] + 0.3, 2.4, 0, this.bulletSpeed() * 1.1);
                    api.soundAt(SFX_ZAP, this.dU[k], 2.4, this.g + this.dV[k], 1.3, 0.25);
                }
            }
            let gone = m == D_SWEEP ? this.dU[k] * this.dB[k] > 9.8 : Math.abs(this.dU[k]) > 9.8;
            if (this.dV[k] > 7.0 || gone || (age > 1.0 && this.dV[k] < -7.5)) {
                this.dOn[k] = false;
                continue;
            }
            if (this.alive) {
                let du = this.pu - this.dU[k], dv = this.pv - this.dV[k];
                if (du * du + dv * dv < 0.6 * 0.6) {
                    this.dOn[k] = false;
                    this.pop(this.dU[k], this.dV[k], 2.4, 0.6);
                    this.hurt(api);
                }
            }
        }
    }

    // ------------------------------------------------------------ gunboats

    stepBoats(api: GameApi, dt: f64): void {
        for (let k = 0; k < NBOAT; k++) {
            if (!this.gOn[k]) continue;
            let ti = this.gTile[k];
            if (this.tileS[ti] < -1e8) { this.gOn[k] = false; continue; }
            let bv = this.groundV(this.tileZ(ti));
            if (bv > 7.5) { this.gOn[k] = false; continue; }
            if (this.gSink[k] >= 0) {
                if (this.t - this.gSink[k] > 0.9) this.gOn[k] = false;
                continue;
            }
            // sail along the river, turning back before the bank's end
            this.gX[k] += this.gDir[k] * 0.85 * dt;
            if (this.gX[k] > 6.6) this.gDir[k] = -1;
            if (this.gX[k] < -6.6) this.gDir[k] = 1;
            // the turret tracks the plane (its ground point)
            let want = deg(Math.atan2(this.pu - this.gX[k], (this.g + this.pv) - this.tileZ(ti)));
            let d = want - this.gAim[k];
            while (d > 180) d -= 360;
            while (d < -180) d += 360;
            this.gAim[k] += clamp(d, -160 * dt, 160 * dt);
            // the first shot comes 0.7 s after it shows (its telegraph starts as it comes into view)
            if (bv < -5.0) this.gFire[k] = Math.max(this.gFire[k], this.t + 0.7);
            if (this.state == PLAY && this.t >= this.gFire[k]) {
                if (bv > -5.0 && bv < 3.6 && this.alive) {
                    let sp = this.bulletSpeed();
                    this.shoot(api, this.gX[k], bv, 0.4, 0, sp);
                    let spr = this.loop > 0 ? 13.0 : 17.0;
                    this.shoot(api, this.gX[k], bv, 0.4, -spr, sp);
                    this.shoot(api, this.gX[k], bv, 0.4, spr, sp);
                    api.soundAt(SFX_ZAP, this.gX[k], 0, this.g + bv, 0.55, 0.4);
                    api.soundAt(SFX_HIT, this.gX[k], 0, this.g + bv, 1.6, 0.2);
                }
                this.gFire[k] = this.t + 1.7 / this.fireK();
            }
        }
    }

    // ------------------------------------------------------------ the boss

    stepBoss(api: GameApi, dt: f64): void {
        let st = this.bossState;
        if (st == B_OFF) return;
        this.bossT += dt;
        if (st == B_WARN) {
            if (this.bossT > 2.0) {
                this.bossState = B_ENTER;
                this.bossT = 0;
                this.bossU = 0;
                this.bossV = -9.5;
                this.bossYaw = 90;
                this.bossHp0 = 200 + 70 * this.loop;
                this.bossHp = this.bossHp0;
                this.bossPat = 0;
                this.gunAim[0] = 180;
                this.gunAim[1] = 180;
                api.sound(SFX_WHOOSH, 0.5, 0.7);
            }
            return;
        }
        if (st == B_ENTER) {
            this.bossV += (-3.0 - this.bossV) * (1.0 - Math.exp(-dt * 1.6));
            if (this.bossT > 2.6) {
                this.bossState = B_FIGHT;
                this.bossT = 0;
                this.bossFight = 0;
                this.bossNext = 0.6;
                this.bossTele = -9;
                this.bossKind = -1;
                this.bossShots = 0;
            }
        } else if (st == B_FIGHT) {
            this.bossFight += dt;
            // a slow patrol from side to side; it turns (nose down the screen) at each end
            let ph = this.bossFight * 0.42;
            let nu = 3.6 * Math.sin(ph);
            let vu = nu - this.bossU;
            this.bossU = nu;
            this.bossV = -3.0 + 0.35 * Math.sin(this.bossFight * 1.1);
            let wantYaw = Math.cos(ph) >= 0 ? 90.0 : -90.0;
            if (Math.abs(vu) < 1e-6) wantYaw = this.bossYaw;
            this.bossYaw += clamp(wantYaw - this.bossYaw, -150 * dt, 150 * dt);
            this.bossPatterns(api, dt);
        } else if (st == B_DIE) {
            // sinking and bursting along its hull
            this.bossV += 0.9 * dt;
            let k0 = Math.floor((this.bossT - dt) / 0.28), k1 = Math.floor(this.bossT / 0.28);
            if (k1 != k0 && this.bossT < 1.5) {
                let j = <f64>k1;
                let off = Math.sin(j * 2.7) * 1.8;
                let sy = Math.sin(rad(this.bossYaw));
                this.pop(this.bossU + off * sy, this.bossV + 0.3 * Math.cos(j * 1.9), 3.6, 0.75 + 0.1 * Math.sin(j));
                this.shake = this.t;
            }
            if (this.bossT > 1.5 && this.bossT - dt <= 1.5) {
                this.pop(this.bossU, this.bossV, 3.6, 1.0);
                this.pop(this.bossU - 1.2, this.bossV, 3.6, 0.9);
                this.pop(this.bossU + 1.2, this.bossV, 3.6, 0.9);
                this.shake = this.t;
            }
            if (this.bossT > 1.6) {
                this.bossState = B_OFF;
                this.showBanner("AIRSHIP DOWN!");
            }
        }
        // the airship's body hurts the plane
        if (this.alive && (this.bossState == B_FIGHT || this.bossState == B_ENTER)) {
            let sy = Math.abs(Math.sin(rad(this.bossYaw))), cy = Math.abs(Math.cos(rad(this.bossYaw)));
            let du = (this.pu - this.bossU) / (0.8 + 1.6 * sy), dv = (this.pv - this.bossV) / (0.8 + 1.6 * cy);
            if (du * du + dv * dv < 1.0) this.hurt(api);
        }
    }

    gunPoint(i: i32): f64 {
        // the turrets sit 0.9 m forward and 0.8 m back along the hull
        let off = i == 0 ? 0.9 : -0.8;
        return off;
    }

    bossPatterns(api: GameApi, dt: f64): void {
        let rage = this.bossHp * 2 < this.bossHp0;
        // the turrets track the plane
        for (let i = 0; i < 2; i++) {
            let off = this.gunPoint(i);
            let gu = this.bossU + off * Math.sin(rad(this.bossYaw));
            let gv = this.bossV + off * Math.cos(rad(this.bossYaw));
            let want = deg(Math.atan2(this.pu - gu, this.pv - gv));
            let d = want - this.gunAim[i];
            while (d > 180) d -= 360;
            while (d < -180) d += 360;
            this.gunAim[i] += clamp(d, -200 * dt, 200 * dt);
        }
        if (this.state != PLAY || !this.alive) {
            this.bossTele = -9;
            this.bossShots = 0;
            this.bossNext = this.bossFight + 1.2;
            return;
        }
        // a pattern: telegraph (0.7 s), then its shots
        if (this.bossKind < 0 && this.bossFight >= this.bossNext) {
            this.bossKind = this.bossPat % 3;
            this.bossPat++;
            this.bossTele = this.t;
            api.sound(SFX_BLIP, this.bossKind == 1 ? 0.6 : 0.8, 0.35);
        }
        if (this.bossKind >= 0 && this.t - this.bossTele >= 0.7) {
            let sp = this.bulletSpeed();
            if (this.bossShots == 0 && this.t - this.bossTele < 0.7 + dt) {
                this.bossShots = this.bossKind == 0 ? (rage ? 4 : 3) : 1;
                this.bossShotT = this.t;
            }
            if (this.bossShots > 0 && this.t >= this.bossShotT) {
                if (this.bossKind == 0) {
                    // the turrets: an aimed shot each
                    for (let i = 0; i < 2; i++) {
                        let off = this.gunPoint(i);
                        let gu = this.bossU + off * Math.sin(rad(this.bossYaw));
                        let gv = this.bossV + off * Math.cos(rad(this.bossYaw)) + 0.35;
                        this.shoot(api, gu, gv, 3.8, 0, sp * 1.1);
                    }
                    api.sound(SFX_ZAP, 0.6, 0.45);
                } else if (this.bossKind == 1) {
                    // a fan down the screen from the gondola
                    let n = rage ? 7 : 5;
                    for (let j = 0; j < n; j++) {
                        let a = rad(90 + (<f64>j - <f64>(n - 1) * 0.5) * (rage ? 15.0 : 18.0));
                        this.shootDir(this.bossU, this.bossV + 0.5, 3.2, Math.cos(a) * sp * 0.85, Math.sin(a) * sp * 0.85);
                    }
                    api.sound(SFX_EXPLODE, 1.6, 0.4);
                } else {
                    // two drones launched from its sides, diving at the plane
                    for (let s = -1; s <= 1; s += 2) {
                        let u = this.bossU + <f64>s * 1.6;
                        this.spawnDrone(D_DIVE, u, this.bossV + 0.4, (this.pu - u) * 0.4, 3.6, 0.9);
                    }
                    api.sound(SFX_WHOOSH, 1.3, 0.4);
                }
                this.bossShots--;
                this.bossShotT = this.t + 0.3;
                if (this.bossShots <= 0) {
                    this.bossKind = -1;
                    this.bossNext = this.bossFight + (rage ? 1.1 : 1.6) / this.fireK();
                }
            }
        }
    }

    // ------------------------------------------------------------ enemy bullets

    stepBullets(api: GameApi, dt: f64): void {
        for (let i = 0; i < NBUL; i++) {
            if (!this.eOn[i]) continue;
            this.eU[i] += this.eVU[i] * dt;
            this.eV[i] += this.eVV[i] * dt;
            let u = this.eU[i], v = this.eV[i];
            if (v > 6.8 || v < -7 || Math.abs(u) > 8.6) { this.eOn[i] = false; continue; }
            if (this.alive) {
                let du = u - this.pu, dv = v - this.pv;
                if (du * du + dv * dv < 0.42 * 0.42) {
                    this.eOn[i] = false;
                    this.hurt(api);
                }
            }
        }
    }

    // ------------------------------------------------------------ the supply crate

    stepCrate(api: GameApi, dt: f64): void {
        if (!this.cOn) return;
        this.cV += 1.3 * dt;
        this.cU += Math.sin((this.t - this.cT) * 1.6) * 0.5 * dt;
        if (this.cV > 6.8) { this.cOn = false; return; }
        if (this.alive && this.state == PLAY) {
            let du = this.pu - this.cU, dv = this.pv - this.cV;
            if (du * du + dv * dv < 0.9 * 0.9) {
                this.cOn = false;
                this.lastPower = this.t;
                if (this.power < 3) {
                    this.power++;
                    this.label(this.cU, this.cV, PH, "WIDER SHOT!");
                } else {
                    this.score += 500;
                    this.bumpBest();
                    this.label(this.cU, this.cV, PH, "+500");
                }
                api.sound(SFX_POWERUP, 1.0, 0.7);
                api.note(84, 0.35, 0, SFX_NOTE, 0.2);
            }
        }
    }

    // ------------------------------------------------------------ the demo player

    // Plays like a decent human: goes for the crate, lines up under the lowest enemy, keeps to the lower
    // half, and steps out of the way of bullets it has seen for a moment (a reaction time). Now and then
    // it loses focus for half a second and may get hit.
    think(api: GameApi): void {
        if (this.runT >= this.aiNext) {
            this.aiNext = this.runT + 0.14;
            if (this.runT > 3.0 && api.rand() < 0.08) this.aiLapse = this.t + api.range(0.5, 1.1);
            // what to go for
            let aimU = this.pu, prefV = 2.9;
            let bestV = -99.0;
            if (this.cOn && this.cV > -4.0) {
                aimU = this.cU; prefV = clamp(this.cV + 0.3, VMIN, VMAX);
            } else {
                for (let k = 0; k < NBAL; k++) {
                    if (this.bOn[k] && this.bV[k] > -5.6 && this.bV[k] > bestV) { bestV = this.bV[k]; aimU = this.bU[k]; }
                }
                for (let k = 0; k < NDRONE; k++) {
                    if (this.dOn[k] && this.dV[k] > -5.6 && this.dV[k] < 3.5 && this.dV[k] > bestV && Math.abs(this.dU[k]) < 7) {
                        bestV = this.dV[k]; aimU = this.dU[k] + this.dVU[k] * 0.35;
                    }
                }
                for (let k = 0; k < NBOAT; k++) {
                    if (!this.gOn[k] || this.gSink[k] >= 0) continue;
                    let bv = this.groundV(this.tileZ(this.gTile[k]));
                    if (bv > -5.2 && bv < 2.0 && bv > bestV) { bestV = bv; aimU = this.gX[k] + this.gDir[k] * 0.4; }
                }
                if (this.bossState == B_FIGHT) { aimU = this.bossU; prefV = 3.2; }
                if (bestV > 0.5) prefV = clamp(bestV + 2.6, 2.4, VMAX);
            }
            aimU += api.range(-0.35, 0.35);
            let focus = this.t > this.aiLapse;
            // a lapse: the hand hesitates where it is
            if (!focus) { this.tu = this.aiU; this.tv = this.aiV; return; }
            // try spots around the plane; the cheapest wins
            let bu = this.pu, bv2 = this.pv, bc = 1e9;
            for (let a = -3; a <= 3; a++) {
                for (let b = -2; b <= 2; b++) {
                    let cu = clamp(this.pu + <f64>a * 0.75, -UMAX, UMAX);
                    let cv = clamp(this.pv + <f64>b * 0.6, VMIN, VMAX);
                    let c = 0.4 * Math.abs(cu - aimU) + 0.25 * Math.abs(cv - prefV);
                    if (focus) c += this.danger(cu, cv);
                    if (c < bc) { bc = c; bu = cu; bv2 = cv; }
                }
            }
            this.aiU = bu;
            this.aiV = bv2;
        }
        this.tu = this.aiU;
        this.tv = this.aiV;
    }

    // how risky a spot is over the next ~0.8 s: bullets seen for 0.22 s or more, bodies near it
    danger(cu: f64, cv: f64): f64 {
        let d = 0.0;
        // the straight path from here to the spot, at roughly the plane's speed
        let du = cu - this.pu, dv = cv - this.pv;
        let l = Math.sqrt(du * du + dv * dv);
        let tt = l / 8.0;
        for (let i = 0; i < NBUL; i++) {
            if (!this.eOn[i] || this.t - this.eT[i] < 0.34) continue;
            for (let s = 0; s <= 8; s++) {
                let tm = <f64>s * 0.1;
                let f = tt > 0 ? Math.min(1.0, tm / tt) : 1.0;
                let px = this.pu + du * f, py = this.pv + dv * f;
                let ex = this.eU[i] + this.eVU[i] * tm * 0.8 - px, ey = this.eV[i] + this.eVV[i] * tm * 0.8 - py;
                let r = Math.sqrt(ex * ex + ey * ey);
                if (r < 0.75) d += (0.75 - r) * 9.0 * (1.0 - <f64>s * 0.06);
            }
        }
        for (let k = 0; k < NDRONE; k++) {
            if (!this.dOn[k]) continue;
            let ex = this.dU[k] + this.dVU[k] * 0.3 - cu, ey = this.dV[k] + this.dVV[k] * 0.3 - cv;
            let r = Math.sqrt(ex * ex + ey * ey);
            if (r < 1.3) d += (1.3 - r) * 6.0;
        }
        for (let k = 0; k < NBAL; k++) {
            if (!this.bOn[k]) continue;
            let ex = this.bU[k] - cu, ey = this.bV[k] + 0.4 - cv;
            let r = Math.sqrt(ex * ex + ey * ey);
            if (r < 1.4) d += (1.4 - r) * 6.0;
        }
        if (this.bossState == B_FIGHT || this.bossState == B_ENTER) {
            let ex = (this.bossU - cu) / 3.2, ey = (this.bossV - cv) / 1.6;
            let r = Math.sqrt(ex * ex + ey * ey);
            if (r < 1.0) d += (1.0 - r) * 12.0;
        }
        return d;
    }

    // ------------------------------------------------------------ drawing

    draw(api: GameApi): void {
        let t = this.t;
        // the ground tiles
        for (let i = 0; i < NTILE; i++) {
            if (this.tileS[i] < -1e8) { api.hide(this.tileB[i]); continue; }
            api.place(this.tileB[i], 0, 0, this.tileZ(i), this.tileYaw[i]);
        }

        // the plane: banked by its sideways speed, nose dipping as it dives; blinking while safe
        let blink = this.alive && this.lives < 3 && t < this.safeUntil && t - this.deadT < 4.0 && Math.floor(t * 12) % 2 == 1;
        if (!this.alive || (this.state == OVER) || blink) {
            api.hide(this.plane);
            api.hide(this.prop);
        } else {
            let yaw = 180 - clamp(this.pvu * 1.5, -12, 12);
            let pitch = clamp(-this.pvv * 1.6, -10, 10);
            let bob = Math.sin(t * 2.2) * 0.05;
            this.put(api, this.plane, this.pu, this.pv, PH + bob, yaw, pitch, this.roll, 1);
            // the propeller on the nose, spinning (a stepped blur)
            api.transform(this.plane, <f64>api.restX[this.plane], <f64>api.restY[this.plane] - 0.02, <f64>api.restZ[this.plane] - 0.70);
            let spin = <f64>((api.frame * 57) % 180);
            api.place(this.prop, api.tx, api.ty, api.tz, yaw, pitch, this.roll + spin);
        }

        // player shots
        for (let i = 0; i < NSHOT; i++) {
            if (!this.sOn[i]) { api.hide(this.shotB[i]); continue; }
            let a = deg(Math.atan2(this.sVU[i], -this.sVV[i]));
            this.put(api, this.shotB[i], this.sU[i], this.sV[i], PH, 180 - a, 0, 0, 1);
        }

        // enemy bullets: rising from where they were fired to 3 m (always over the plane), pulsing
        for (let i = 0; i < NBUL; i++) {
            if (!this.eOn[i]) { api.hide(this.bulB[i]); continue; }
            let k = Math.min(1.0, (t - this.eT[i]) / 0.35);
            let h = this.eH0[i] + (3.0 - this.eH0[i]) * k;
            let s = 0.85 + 0.15 * (Math.floor(t * 8 + <f64>i) % 2);
            this.put(api, this.bulB[i], this.eU[i], this.eV[i], h, 0, 0, 0, s);
        }

        // balloons: a slow sway; a hit flickers (one frame hidden) and squashes
        for (let k = 0; k < NBAL; k++) {
            if (!this.bOn[k]) { api.hide(this.balB[k]); continue; }
            let kh = t - this.bHit[k];
            if (kh < 0.035) { api.hide(this.balB[k]); continue; }
            let sq = kh < 0.2 ? 1.0 - 0.1 * Math.sin(kh / 0.2 * Math.PI) : 1.0;
            let sway = Math.sin(t * 1.3 + <f64>k) * 6;
            this.put(api, this.balB[k], this.bU[k], this.bV[k], 3.4, <f64>k * 40 + t * 8, sway, sway * 0.5, sq);
        }

        // drones: facing where they fly, banking; rotors whirl as a stepped yaw wobble
        for (let k = 0; k < NDRONE; k++) {
            if (!this.dOn[k]) { api.hide(this.droneB[k]); continue; }
            if (t - this.dHit[k] < 0.035) { api.hide(this.droneB[k]); continue; }
            let vu = this.dVU[k], vv = this.dVV[k];
            let yaw = deg(Math.atan2(vu, vv));
            let wob = (api.frame % 4 < 2) ? 3.0 : -3.0;
            this.put(api, this.droneB[k], this.dU[k], this.dV[k], 2.4, yaw + wob, clamp(vv * 3, -12, 12), clamp(vu * 5, -30, 30), 1);
        }

        // gunboats on their rivers, the turrets on their decks
        for (let k = 0; k < NBOAT; k++) {
            if (!this.gOn[k]) { api.hide(this.boatB[k]); api.hide(this.turB[k]); continue; }
            let z = this.tileZ(this.gTile[k]);
            let yaw = this.gDir[k] > 0 ? 90.0 : -90.0;
            let ks = this.gSink[k];
            let y = 0.0, roll = Math.sin(t * 2.0 + <f64>k) * 3.0;
            if (ks >= 0) {
                let q = (t - ks) / 0.9;
                y = -0.5 * q;
                roll = 25 * q;
            }
            let kh = t - this.gHit[k];
            if (kh < 0.035) { api.hide(this.boatB[k]); api.hide(this.turB[k]); continue; }
            api.place(this.boatB[k], snapU(this.gX[k]), y, z, yaw, 0, roll);
            // the mount: 0.4 m towards the bow on the deck (the bake put the boat at yaw 90)
            api.transform(this.boatB[k], <f64>api.restX[this.boatB[k]] + 0.5, <f64>api.restY[this.boatB[k]] + 0.25, <f64>api.restZ[this.boatB[k]]);
            api.place(this.turB[k], api.tx, api.ty, api.tz, this.gAim[k], 0, roll);
        }

        // the boss and its turrets
        if (this.bossState == B_ENTER || this.bossState == B_FIGHT || this.bossState == B_DIE) {
            // a hit makes it shudder (a stepped one-texel jolt and a little squash)
            let kh = t - this.bossHit;
            let jolt = kh < 0.06 && this.bossState != B_DIE ? (api.frame % 2 == 0 ? TEX : -TEX) : 0.0;
            let tilt = this.bossState == B_DIE ? this.bossT * 14 : 0;
            {
                let bob = Math.sin(t * 1.1) * 0.06;
                this.put(api, this.boss, this.bossU + jolt, this.bossV, 3.6 + bob, this.bossYaw, tilt, Math.sin(t * 0.9) * 2, kh < 0.06 ? 0.98 : 1);
                for (let i = 0; i < 2; i++) {
                    let off = i == 0 ? 0.9 : -0.8;
                    api.transform(this.boss, <f64>api.restX[this.boss] + off, <f64>api.restY[this.boss] + 0.8, <f64>api.restZ[this.boss]);
                    api.place(this.gunB[i], api.tx, api.ty, api.tz, this.gunAim[i], tilt * 0.5, 0);
                }
            }
        } else {
            api.hide(this.boss); api.hide(this.gunB[0]); api.hide(this.gunB[1]);
        }

        // the crate swinging under its chute
        if (this.cOn) {
            this.put(api, this.crate, this.cU, this.cV, 2.9, t * 30, Math.sin(t * 2.4) * 10, Math.cos(t * 1.9) * 8, 1);
        } else {
            api.hide(this.crate);
        }

        // pops: grow fast, then shrink away, stepped at 30 fps
        for (let i = 0; i < NPOP; i++) {
            let k = t - this.pT[i];
            if (k < 0 || k > 0.42) { api.hide(this.popB[i]); continue; }
            let ks2 = Math.floor(k * 30) / 30;
            let s = ks2 < 0.07 ? 0.3 + ks2 / 0.07 * 0.7 : 1.0 - (ks2 - 0.07) / 0.35 * 0.85;
            this.put(api, this.popB[i], this.pU[i], this.pV[i], this.pH[i], ks2 * 260, ks2 * 120, 0, s * this.pS[i]);
        }
    }

    // ------------------------------------------------------------ input

    // Mouse: the plane follows the pointer (hovering is enough). Touch: the pointer only moves while a
    // finger is down, so a press puts the target at the finger and a drag steers; while pressed the
    // plane flies 1 m above the touch point, so the finger does not hide it. On release it holds there.
    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) this.held = true;
        if (kind == POINTER_UP) { this.held = false; return true; }
        if (api.pick(x, y, 0)) {
            this.tu = <f64>api.hitX;
            this.tv = <f64>api.hitZ - this.g - (this.held ? 1.0 : 0.0);
        }
        if (kind == POINTER_DOWN) {
            if (this.state == READY) {
                this.begin(api);
            } else if (this.state == OVER && this.t - this.overT > 0.8) {
                this.begin(api);
            }
        }
        return true;
    }

    // ------------------------------------------------------------ HUD

    ring(api: GameApi, cx: f32, cy: f32, r: f32, c: u32): void {
        let n = <i32>Math.max(8, Math.floor(<f64>r * 6.3));
        for (let k = 0; k < n; k++) {
            let a = <f64>k / <f64>n * Math.PI * 2;
            api.rect(Mathf.round(cx + r * <f32>Math.cos(a)), Mathf.round(cy + r * <f32>Math.sin(a)), 1, 1, c);
        }
    }

    // a closing ring over a shooter about to fire: k goes 0 -> 1 over the telegraph
    tele(api: GameApi, x: f64, y: f64, z: f64, k: f64, c1: u32, c2: u32): void {
        if (!api.project(<f32>x, <f32>y, <f32>z)) return;
        let r = <f32>(8.0 - 5.0 * k);
        let c = Math.floor(this.t * 14) % 2 == 0 ? c1 : c2;
        this.ring(api, api.screenX, api.screenY, r, c);
    }

    hud(api: GameApi): void {
        let ink = api.rampColor(9, 0);      // #2a1d0d
        let cream = api.rampColor(6, 3);    // #efd8a1
        let gold = api.rampColor(2, 2);     // #efac28
        let orange = api.rampColor(8, 3);   // #ef692f
        let red = api.rampColor(12, 1);     // #ef3a0c
        let teal = api.rampColor(4, 2);     // #3c9f9c
        let t = this.t;
        let w = <f32>api.hudW, h = <f32>api.hudH;

        // telegraphs: a closing ring over whoever is about to fire
        if (this.state == PLAY) {
            for (let k = 0; k < NBAL; k++) {
                if (!this.bOn[k] || k == 3) continue;
                let left = this.bFire[k] - t;
                if (left < 0.5 && left >= 0 && this.bV[k] > -4.6 && this.bV[k] < 2.0) {
                    this.tele(api, snapU(this.bU[k]), 2.6, this.g + snapV(this.bV[k] + 0.5) + 2.6 * COT, 1 - left / 0.5, cream, red);
                }
            }
            for (let k = 0; k < NBOAT; k++) {
                if (!this.gOn[k] || this.gSink[k] >= 0) continue;
                let left = this.gFire[k] - t;
                let bv = this.groundV(this.tileZ(this.gTile[k]));
                if (left < 0.6 && left >= 0 && bv > -5.0 && bv < 3.6) {
                    this.tele(api, this.gX[k], 0.4, this.tileZ(this.gTile[k]), 1 - left / 0.6, cream, red);
                }
            }
            if (this.bossState == B_FIGHT && this.bossKind >= 0) {
                let k = (t - this.bossTele) / 0.7;
                if (k >= 0 && k <= 1) {
                    if (this.bossKind == 0) {
                        for (let i = 0; i < 2; i++) {
                            let off = this.gunPoint(i);
                            let gu = this.bossU + off * Math.sin(rad(this.bossYaw));
                            let gv = this.bossV + off * Math.cos(rad(this.bossYaw)) + 0.35;
                            this.tele(api, snapU(gu), 3.8, this.g + snapV(gv) + 3.8 * COT, k, cream, red);
                        }
                    } else {
                        this.tele(api, snapU(this.bossU), 3.2, this.g + snapV(this.bossV + 0.5) + 3.2 * COT, k,
                            this.bossKind == 1 ? gold : teal, red);
                    }
                }
            }
        }

        // floating scores
        for (let i = 0; i < NLABEL; i++) {
            let k = t - this.lT[i];
            if (k < 0 || k > 0.8) continue;
            if (api.project(<f32>this.lU[i], <f32>this.lH[i], <f32>(this.g + this.lV[i] + this.lH[i] * COT))) {
                let s = this.lS[i];
                api.text(api.screenX - api.textWidth(s, 1) * 0.5, api.screenY - 9 - <f32>Math.floor(k * 12), s, k < 0.55 ? cream : gold, 1, ink);
            }
        }

        // score, best, lives, power
        api.text(4, 3, this.score.toString(), cream, 2, ink);
        let b = "BEST " + (api.demo ? this.demoBest : this.best).toString();
        api.text(w - api.textWidth(b, 1) - 4, 3, b, gold, 1, ink);
        for (let i = 0; i < 3; i++) {
            let x = w - 4 - <f32>(3 - i) * 10 + 1;
            let c = i < this.lives ? cream : api.rampColor(9, 2);
            // a tiny biplane: wing, fuselage, tail
            api.rect(x + 1, 12, 8, 2, ink);
            api.rect(x, 11, 8, 2, c);
            api.rect(x + 3, 10, 2, 6, i < this.lives ? orange : c);
            api.rect(x + 2, 15, 4, 1, c);
        }
        for (let i = 0; i < 3; i++) {
            let c = i < this.power ? gold : api.rampColor(9, 2);
            api.rect(4 + <f32>i * 5, 15, 4, 2, c);
        }
        if (t - this.lastPower < 0.6 && Math.floor(t * 10) % 2 == 0) {
            api.text(20, 14, "POWER", gold, 1, ink);
        }

        // the boss's strength
        if (this.bossState == B_FIGHT || this.bossState == B_ENTER) {
            let bw: f32 = 70;
            let bx = Mathf.floor((w - bw) * 0.5);
            api.rect(bx - 1, 4, bw + 2, 5, ink);
            api.rect(bx, 5, bw * <f32>this.bossHp / <f32>this.bossHp0, 3, this.bossHp * 2 < this.bossHp0 ? red : orange);
        }

        // banners
        let kb = t - this.bannerT;
        let warn = this.banner == "WARNING!";
        if (kb >= 0 && kb < (warn ? 2.0 : 1.4) && this.state != OVER) {
            if (!warn || Math.floor(kb * 6) % 2 == 0) {
                api.textCentered(h * 0.2, this.banner, warn ? red : gold, 2, ink);
            }
        }

        if (this.state == READY) {
            api.textCentered(h * 0.3, "SKY RAID", cream, 3, ink);
            api.textCentered(h - 22, "CLICK OR TAP TO TAKE OFF", gold, 1, ink);
            api.textCentered(h - 13, "STEER WITH THE POINTER - IT FIRES BY ITSELF", cream, 1, ink);
        } else if (this.state == OVER) {
            let k = t - this.overT;
            if (k > 0.5) {
                api.textCentered(h * 0.5 - 24, "GAME OVER", cream, 2, ink);
                api.textCentered(h * 0.5 - 8, "SCORE " + this.score.toString(), gold, 1, ink);
                api.textCentered(h * 0.5 + 1, "BEST " + (api.demo ? this.demoBest : this.best).toString(), gold, 1, ink);
                if (!api.demo && k > 0.8) api.textCentered(h - 13, "CLICK OR TAP TO FLY AGAIN", cream, 1, ink);
            }
        }
        if (api.demo) api.text(4, h - 9, "DEMO", teal, 1, ink);
    }
}
