// Bath Navy: a rubber duck holds the end of the tub against a fleet of toy boats sailing out from
// under the faucet. Click to fire a soap bubble where you point; a bubble pops a sailboat (10) or a
// speedboat (20), a tugboat takes two (30). A boat that reaches the duck bonks it: three bonks and
// the run is over. The fleet comes faster and faster.
//
// Everything is in this file (references/games.md, "The game hook"); the bones come from
// scene.bake.json: duck, sail0..3, tug0..2, speed0..2, bubble0..5, drop0..9.
import { GameApi, POINTER_DOWN, SFX_POP, SFX_SPLASH, SFX_JUMP, SFX_THUD, SFX_HIT, SFX_BLIP, SFX_LOSE,
    SFX_NOTE, SFX_BELL } from "./game_api";

const WATER: f64 = 0.85;          // the water's height
const DUCK_X: f64 = -3.3;
const DUCK_Z: f64 = 0.0;
const DUCK_Y: f64 = 0.78;
const BEAK: f64 = 0.82;           // the beak tip ahead of the duck's pivot (scaled)
const NB: i32 = 10;               // boats: sail 0-3, tug 4-6, speed 7-9
const NU: i32 = 6;                // bubbles
const ND: i32 = 10;               // drops
const NP: i32 = 6;                // popups
const LIVES: i32 = 3;
const BONK_X: f64 = -2.35;        // a boat this far reaches the duck
const SPAWN_X: f64 = 3.3;
const BUBBLE_V: f64 = 6.5;
const HIT_R: f64 = 0.52;

// boat kinds
const K_SAIL: i32 = 0;
const K_TUG: i32 = 1;
const K_SPEED: i32 = 2;
// boat states
const B_OFF: i32 = 0;
const B_RISE: i32 = 1;            // popping up out of the water at the faucet end
const B_SAIL: i32 = 2;
const B_SINK: i32 = 3;
// run modes
const M_READY: i32 = 0;
const M_PLAY: i32 = 1;
const M_OVER: i32 = 2;

function clamp(v: f64, a: f64, b: f64): f64 { return v < a ? a : (v > b ? b : v); }
function deg(r: f64): f64 { return r * 180.0 / Math.PI; }
function rad(d: f64): f64 { return d * Math.PI / 180.0; }

export class Game {
    bDuck: i32 = -1;
    bBoat: StaticArray<i32> = new StaticArray<i32>(NB);
    bBub: StaticArray<i32> = new StaticArray<i32>(NU);
    bDrop: StaticArray<i32> = new StaticArray<i32>(ND);

    mode: i32 = M_READY;
    wasDemo: bool = false;
    score: i32 = 0;
    best: i32 = 0;
    lives: i32 = LIVES;
    popped: i32 = 0;
    overT: f64 = 0;
    runT: f64 = 0;

    // the duck
    aimX: f64 = 0; aimZ: f64 = 0;
    duckYaw: f64 = 90;
    fireT: f64 = 9;               // since the last shot (recoil)
    bonkT: f64 = 9;               // since the last bonk (a big squash, a flash)

    // the fleet
    kind: StaticArray<i32> = [0, 0, 0, 0, 1, 1, 1, 2, 2, 2];
    bState: StaticArray<i32> = new StaticArray<i32>(NB);
    bX: StaticArray<f64> = new StaticArray<f64>(NB);
    bZ: StaticArray<f64> = new StaticArray<f64>(NB);
    bZ0: StaticArray<f64> = new StaticArray<f64>(NB);
    bT: StaticArray<f64> = new StaticArray<f64>(NB);       // age in its state
    bV: StaticArray<f64> = new StaticArray<f64>(NB);
    bHp: StaticArray<i32> = new StaticArray<i32>(NB);
    bHitT: StaticArray<f64> = new StaticArray<f64>(NB);    // since the last hit (the wobble)
    bPhase: StaticArray<f64> = new StaticArray<f64>(NB);
    bYaw: StaticArray<f64> = new StaticArray<f64>(NB);
    spawnT: f64 = 0;
    spawned: i32 = 0;

    // bubbles
    uOn: StaticArray<bool> = new StaticArray<bool>(NU);
    uX: StaticArray<f64> = new StaticArray<f64>(NU);
    uZ: StaticArray<f64> = new StaticArray<f64>(NU);
    uVX: StaticArray<f64> = new StaticArray<f64>(NU);
    uVZ: StaticArray<f64> = new StaticArray<f64>(NU);
    uT: StaticArray<f64> = new StaticArray<f64>(NU);
    uFor: StaticArray<i32> = new StaticArray<i32>(NU);     // the boat the demo aimed it at
    nextBub: i32 = 0;

    // drops
    dLife: StaticArray<f64> = new StaticArray<f64>(ND);
    dX: StaticArray<f64> = new StaticArray<f64>(ND);
    dY: StaticArray<f64> = new StaticArray<f64>(ND);
    dZ: StaticArray<f64> = new StaticArray<f64>(ND);
    dVX: StaticArray<f64> = new StaticArray<f64>(ND);
    dVY: StaticArray<f64> = new StaticArray<f64>(ND);
    dVZ: StaticArray<f64> = new StaticArray<f64>(ND);
    nextDrop: i32 = 0;

    // popups
    pOn: StaticArray<bool> = new StaticArray<bool>(NP);
    pX: StaticArray<f64> = new StaticArray<f64>(NP);
    pY: StaticArray<f64> = new StaticArray<f64>(NP);
    pZ: StaticArray<f64> = new StaticArray<f64>(NP);
    pAge: StaticArray<f64> = new StaticArray<f64>(NP);
    pKind: StaticArray<i32> = new StaticArray<i32>(NP);
    pText: Array<string> = ["", "", "", "", "", ""];
    nextPop: i32 = 0;

    // sound (never decided by a random draw)
    chain: i32 = 0;               // boats popped without a wasted bubble or a bonk: the pops climb
    sndRiseF: i32 = -99;          // the frame of the last faucet bloop

    // the demo player
    dWait: f64 = 0.3;

    start(api: GameApi): void {
        api.playable = true;
        this.bDuck = api.bone("duck");
        for (let i = 0; i < 4; i++) this.bBoat[i] = api.bone("sail" + i.toString());
        for (let i = 0; i < 3; i++) this.bBoat[4 + i] = api.bone("tug" + i.toString());
        for (let i = 0; i < 3; i++) this.bBoat[7 + i] = api.bone("speed" + i.toString());
        for (let i = 0; i < NU; i++) this.bBub[i] = api.bone("bubble" + i.toString());
        for (let i = 0; i < ND; i++) this.bDrop[i] = api.bone("drop" + i.toString());
        this.wasDemo = api.demo;
        this.reset(api);
    }

    reset(api: GameApi): void {
        this.chain = 0;
        this.score = 0;
        this.lives = LIVES;
        this.popped = 0;
        this.runT = 0;
        this.spawned = 0;
        this.bonkT = 9;
        for (let i = 0; i < NB; i++) { this.bState[i] = B_OFF; api.hide(this.bBoat[i]); }
        for (let i = 0; i < NU; i++) { this.uOn[i] = false; api.hide(this.bBub[i]); }
        if (api.demo) {
            // the demo starts mid-battle: two boats already out, the first one well on its way
            this.mode = M_PLAY;
            this.launch(api, K_SAIL, 0.9, -0.6);
            this.launch(api, K_SPEED, 2.6, 1.1);
            this.spawnT = 1.0;
            this.dWait = 0.25;
        } else {
            this.mode = M_READY;
            // the fleet waits under the faucet until the first click
            this.launch(api, K_SAIL, 2.7, -0.9);
            this.launch(api, K_TUG, 3.1, 0.9);
            this.spawnT = 1.0;
        }
    }

    // ------------------------------------------------------------------ the fleet

    launch(api: GameApi, k: i32, x: f64, z: f64): void {
        let lo = k == K_SAIL ? 0 : (k == K_TUG ? 4 : 7);
        let hi = k == K_SAIL ? 4 : (k == K_TUG ? 7 : 10);
        let b = -1;
        for (let i = lo; i < hi; i++) {
            if (this.bState[i] == B_OFF) { b = i; break; }
        }
        if (b < 0) return;
        this.bState[b] = x < SPAWN_X - 0.1 ? B_SAIL : B_RISE;
        this.bX[b] = x;
        this.bZ[b] = z;
        this.bZ0[b] = z;
        this.bT[b] = 0;
        let pace = 1 + 0.04 * <f64>this.spawned;
        this.bV[b] = (k == K_SAIL ? 0.5 : (k == K_TUG ? 0.36 : 0.95)) * Math.min(pace, 2.6);
        this.bHp[b] = k == K_TUG ? 2 : 1;
        this.bHitT[b] = 9;
        if (this.bState[b] == B_RISE && this.mode == M_PLAY && api.frame - this.sndRiseF > 12) {
            // a low bloop under the faucet as a boat bobs up (a tug lower, a speedboat higher)
            api.soundAt(SFX_POP, x, WATER, z, k == K_TUG ? 0.35 : (k == K_SPEED ? 0.55 : 0.45), 0.4);
            this.sndRiseF = api.frame;
        }
        this.bPhase[b] = api.range(0, 6.28);
        this.bYaw[b] = 270;
        this.spawned += 1;
    }

    spawnNext(api: GameApi): void {
        let r = api.rand();
        let k = r < 0.55 ? K_SAIL : (r < 0.8 ? K_SPEED : K_TUG);
        if (this.spawned < 3) k = K_SAIL;
        this.launch(api, k, SPAWN_X, api.range(-1.2, 1.2));
    }

    updateBoats(api: GameApi, dt: f64): void {
        if (this.mode == M_PLAY) {
            this.spawnT -= dt;
            if (this.spawnT <= 0) {
                this.spawnNext(api);
                this.spawnT = Math.max(0.55, 2.0 - 0.07 * <f64>this.spawned) * api.range(0.8, 1.2);
            }
        }
        for (let b = 0; b < NB; b++) {
            let bone = this.bBoat[b];
            let st = this.bState[b];
            if (st == B_OFF) { api.hide(bone); continue; }
            this.bT[b] += dt;
            this.bHitT[b] += dt;
            let t = this.bT[b];
            let y = WATER;
            let roll = 0.0, pitch = 0.0, scale = 1.0;
            if (st == B_RISE) {
                // up out of the water under the faucet, with an overshoot
                let u = clamp(t / 0.5, 0, 1);
                y = WATER - 0.9 * (1 - u) * (1 - u) + 0.15 * Math.sin(u * Math.PI);
                scale = 0.6 + 0.4 * u;
                if (u >= 1 && this.mode == M_PLAY) { this.bState[b] = B_SAIL; this.bT[b] = 0; }
            } else if (st == B_SAIL) {
                if (this.mode == M_PLAY) {
                    let v = this.bV[b];
                    // a stagger after a hit
                    if (this.bHitT[b] < 0.5) v *= -0.6 * (1 - this.bHitT[b] * 2);
                    this.bX[b] -= v * dt;
                    // weave across the tub, then home in on the duck for the last stretch
                    let weave = this.bZ0[b] + 0.45 * Math.sin(t * 0.9 + this.bPhase[b]);
                    let home = clamp((0.8 - this.bX[b]) / 3.0, 0, 1);
                    let want = weave * (1 - home) + DUCK_Z * home;
                    let dz = (want - this.bZ[b]) * Math.min(1, dt * 1.6);
                    this.bZ[b] += dz;
                    this.bYaw[b] = 270 + deg(Math.atan2(dz / Math.max(dt, 1e-4), v)) * 0.6;
                    if (this.bX[b] < BONK_X) this.bonk(api, b);
                }
                let k = Math.floor(api.time * 8 + this.bPhase[b]);
                roll = 4 * Math.sin(k * 1.3);
                pitch = 3 * Math.sin(k * 0.9 + 1);
                if (this.bHitT[b] < 0.4) {
                    roll += 18 * Math.exp(-this.bHitT[b] * 8) * Math.sin(this.bHitT[b] * 40);
                    scale = 1 + 0.15 * Math.exp(-this.bHitT[b] * 10);
                }
            } else if (st == B_SINK) {
                // popped: a jump, a roll onto its side, down it goes
                let u = clamp(t / 0.9, 0, 1);
                y = WATER + 0.45 * Math.sin(Math.min(u * 3, 1) * Math.PI) - 1.4 * u * u;
                roll = 100 * Math.min(1, u * 2.2);
                scale = 1 + 0.12 * Math.max(0, 1 - u * 4);
                if (u >= 1) { this.bState[b] = B_OFF; api.hide(bone); continue; }
            }
            api.place(bone, this.bX[b], y, this.bZ[b], this.bYaw[b], pitch, roll, scale);
        }
    }

    bonk(api: GameApi, b: i32): void {
        this.sink(api, b);
        this.bonkT = 0;
        this.lives -= 1;
        this.chain = 0;
        // the duck squeaks (lower with each life lost) as the boat thumps it
        api.soundAt(SFX_JUMP, DUCK_X, DUCK_Y, DUCK_Z, 1.7 - 0.2 * <f64>(LIVES - 1 - this.lives), 0.85);
        api.soundAt(SFX_THUD, DUCK_X, DUCK_Y, DUCK_Z, 1.4, 0.7);
        this.popup(DUCK_X, 2.3, DUCK_Z, "BONK!", 3);
        this.splash(api, DUCK_X + 0.9, this.bZ[b], 6);
        if (this.lives <= 0 && this.mode == M_PLAY) {
            this.mode = M_OVER;
            this.overT = 0;
            if (this.score > this.best) this.best = this.score;
            api.sound(SFX_LOSE, 1.0, 0.75);
            api.sound(SFX_SPLASH, 0.6, 0.6);
            for (let i = 0; i < NB; i++) {
                if (this.bState[i] == B_SAIL || this.bState[i] == B_RISE) this.sink(api, i);
            }
        }
    }

    sink(api: GameApi, b: i32): void {
        this.bState[b] = B_SINK;
        this.bT[b] = 0;
    }

    // ------------------------------------------------------------------ bubbles

    fire(api: GameApi, tx: f64, tz: f64, forBoat: i32): bool {
        if (this.fireT < 0.18) return false;
        let n = 0;
        for (let i = 0; i < NU; i++) if (this.uOn[i]) n++;
        if (n >= 4) return false;
        let u = this.nextBub;
        this.nextBub = (this.nextBub + 1) % NU;
        let bx = DUCK_X + Math.sin(rad(this.duckYaw)) * BEAK;
        let bz = DUCK_Z + Math.cos(rad(this.duckYaw)) * BEAK;
        // the bubble flies the way the duck faces (it has turned towards the aim already)
        let dx = tx - bx, dz = tz - bz;
        let d = Math.sqrt(dx * dx + dz * dz);
        if (d < 0.3) { dx = 1; dz = 0; d = 1; }
        this.uOn[u] = true;
        this.uX[u] = bx; this.uZ[u] = bz;
        this.uVX[u] = dx / d * BUBBLE_V;
        this.uVZ[u] = dz / d * BUBBLE_V;
        this.uT[u] = 0;
        this.uFor[u] = forBoat;
        this.fireT = 0;
        api.soundAt(SFX_POP, bx, WATER, bz, 0.8, 0.5);    // a bloop out of the beak
        return true;
    }

    updateBubbles(api: GameApi, dt: f64): void {
        for (let u = 0; u < NU; u++) {
            let bone = this.bBub[u];
            if (!this.uOn[u]) { api.hide(bone); continue; }
            this.uT[u] += dt;
            this.uX[u] += this.uVX[u] * dt;
            this.uZ[u] += this.uVZ[u] * dt;
            let x = this.uX[u], z = this.uZ[u];
            // a boat?
            let hit = false;
            for (let b = 0; b < NB; b++) {
                if (this.bState[b] != B_SAIL && this.bState[b] != B_RISE) continue;
                let ex = this.bX[b] - x, ez = this.bZ[b] - z;
                if (ex * ex + ez * ez < HIT_R * HIT_R) {
                    this.hitBoat(api, b);
                    hit = true;
                    break;
                }
            }
            // the tub's wall (a rounded box: inner half sizes 4.25 x 2.35, corners r 0.65)
            let cx = Math.max(Math.abs(x) - (4.0 - 0.65), 0), cz = Math.max(Math.abs(z) - (2.1 - 0.65), 0);
            let out = cx * cx + cz * cz > 0.65 * 0.65;
            if (hit || out || this.uT[u] > 2.0) {
                this.uOn[u] = false;
                api.hide(bone);
                this.splash(api, x, z, hit ? 0 : 3);
                if (!hit) {
                    // a wasted bubble: a soft plip on the water, and the chain is broken
                    api.soundAt(SFX_SPLASH, x, WATER, z, 1.6, 0.4);
                    if (this.uFor[u] < 0) this.chain = 0;
                }
                continue;
            }
            let wob = 1 + 0.08 * Math.sin(Math.floor(this.uT[u] * 12) * 1.7);
            let grow = Math.min(1, 0.4 + this.uT[u] * 6);
            api.placeScaled(bone, x, WATER + 0.28 + 0.05 * Math.sin(this.uT[u] * 9), z, 0,
                grow * wob, grow / wob, grow * wob);
        }
    }

    hitBoat(api: GameApi, b: i32): void {
        this.bHp[b] -= 1;
        this.bHitT[b] = 0;
        let k = this.kind[b];
        if (this.bHp[b] > 0) {
            this.splash(api, this.bX[b], this.bZ[b], 3);
            this.popup(this.bX[b], 1.9, this.bZ[b], "CLANG", 0);
            // the tug's tin hull rings
            api.soundAt(SFX_HIT, this.bX[b], WATER, this.bZ[b], 1.5, 0.5);
            api.note(81, 0.45, 0, SFX_NOTE);
            return;
        }
        let pts = k == K_SAIL ? 10 : (k == K_TUG ? 30 : 20);
        let before = this.score;
        if (this.mode == M_PLAY) {
            this.score += pts;
            this.popped += 1;
        }
        // the pop: higher for a speedboat, lower for a tug, a whole tone up with each boat in the chain
        let base = k == K_SAIL ? 1.0 : (k == K_TUG ? 0.8 : 1.2);
        api.soundAt(SFX_POP, this.bX[b], WATER, this.bZ[b], base * Math.pow(2, <f64>min<i32>(this.chain, 8) / 6.0), 0.85);
        api.soundAt(SFX_SPLASH, this.bX[b], WATER, this.bZ[b], 1.0, 0.45);
        this.chain++;
        if (this.mode == M_PLAY && before / 100 != this.score / 100) {
            api.note(84 + 2 * <f64>min<i32>(this.score / 100, 6), 0.55, 0, SFX_BELL);   // every 100: a bell
        }
        this.sink(api, b);
        this.splash(api, this.bX[b], this.bZ[b], 7);
        this.popup(this.bX[b], 1.9, this.bZ[b], "+" + pts.toString(), k == K_SAIL ? 1 : 2);
    }

    // ------------------------------------------------------------------ splashes and popups

    splash(api: GameApi, x: f64, z: f64, n: i32): void {
        for (let k = 0; k < n; k++) {
            let d = this.nextDrop;
            this.nextDrop = (this.nextDrop + 1) % ND;
            let a = api.range(0, Math.PI * 2);
            let s = api.range(0.8, 2.2);
            this.dLife[d] = 0.8;
            this.dX[d] = x; this.dY[d] = WATER + 0.2; this.dZ[d] = z;
            this.dVX[d] = Math.cos(a) * s;
            this.dVZ[d] = Math.sin(a) * s;
            this.dVY[d] = api.range(2.5, 4.5);
        }
    }

    updateDrops(api: GameApi, dt: f64): void {
        for (let d = 0; d < ND; d++) {
            let bone = this.bDrop[d];
            if (this.dLife[d] <= 0) { api.hide(bone); continue; }
            this.dLife[d] -= dt;
            this.dVY[d] -= 9.8 * dt;
            this.dX[d] += this.dVX[d] * dt;
            this.dY[d] += this.dVY[d] * dt;
            this.dZ[d] += this.dVZ[d] * dt;
            if (this.dY[d] < WATER - 0.05 || this.dLife[d] <= 0) { this.dLife[d] = 0; api.hide(bone); continue; }
            api.place(bone, this.dX[d], this.dY[d], this.dZ[d], 0, 0, 0, 1.4);
        }
    }

    popup(x: f64, y: f64, z: f64, s: string, kind: i32): void {
        let p = this.nextPop;
        this.nextPop = (this.nextPop + 1) % NP;
        this.pOn[p] = true;
        this.pX[p] = x; this.pY[p] = y; this.pZ[p] = z;
        this.pAge[p] = 0;
        this.pKind[p] = kind;
        this.pText[p] = s;
    }

    // ------------------------------------------------------------------ the demo player

    demoPlay(api: GameApi, dt: f64): void {
        if (this.mode == M_OVER) {
            if (this.overT > 2.0) this.reset(api);
            return;
        }
        this.dWait -= dt;
        // track the most urgent boat that no bubble is already on its way to
        let best = -1;
        let bestX = 1e9;
        for (let b = 0; b < NB; b++) {
            if (this.bState[b] != B_SAIL || this.bX[b] > 1.4) continue;
            let taken = 0;
            for (let u = 0; u < NU; u++) if (this.uOn[u] && this.uFor[u] == b) taken++;
            if (taken >= this.bHp[b]) continue;
            if (this.bX[b] < bestX) { bestX = this.bX[b]; best = b; }
        }
        if (best < 0) return;
        // lead: where the boat will be when a bubble gets there (three refinements)
        let bx = DUCK_X + BEAK, bz = DUCK_Z;
        let px = this.bX[best], pz = this.bZ[best];
        for (let i = 0; i < 3; i++) {
            let t = Math.sqrt((px - bx) * (px - bx) + (pz - bz) * (pz - bz)) / BUBBLE_V;
            px = this.bX[best] - this.bV[best] * t;
            pz = this.bZ[best];
        }
        let k = Math.min(1, dt * 7);
        this.aimX += (px - this.aimX) * k;
        this.aimZ += (pz - this.aimZ) * k;
        if (this.dWait <= 0) {
            // a decent player: a little error, now and then a wild one
            let e = (api.rand() + api.rand() + api.rand() - 1.5) * 0.9;
            if (api.rand() < 0.1) e *= 3;
            if (this.fire(api, this.aimX, this.aimZ + e, best)) {
                this.dWait = api.range(0.42, 0.75);
            }
        }
    }

    // ------------------------------------------------------------------ frame

    update(api: GameApi): void {
        let dt = api.dt;
        if (this.wasDemo != api.demo) {
            this.wasDemo = api.demo;
            this.reset(api);
        }
        this.fireT += dt;
        this.bonkT += dt;
        if (this.mode == M_OVER) this.overT += dt;
        if (this.mode == M_PLAY) this.runT += dt;
        if (api.demo) this.demoPlay(api, dt);

        // the duck turns to the aim (within 75 degrees of straight down the tub)
        let want = deg(Math.atan2(this.aimX - DUCK_X, this.aimZ - DUCK_Z));
        if (this.aimX == 0 && this.aimZ == 0) want = 90;
        want = clamp(want, 15, 165);
        this.duckYaw += (want - this.duckYaw) * Math.min(1, dt * 14);

        this.updateBoats(api, dt);
        this.updateBubbles(api, dt);
        this.updateDrops(api, dt);

        // the duck: bobs (stepped, 8 fps), squashes back when it fires, squashes hard when bonked
        let k = Math.floor(api.time * 8);
        let bob = 0.04 * Math.sin(k * 0.8);
        let f = this.fireT < 0.3 ? Math.exp(-this.fireT * 14) : 0;
        let h = this.bonkT < 0.8 ? Math.exp(-this.bonkT * 5) * Math.cos(this.bonkT * 18) : 0;
        let sy = 1 - 0.18 * f - 0.3 * h;
        let sxz = 1 + 0.12 * f + 0.2 * h;
        let back = 0.18 * f;
        let dx = -Math.sin(rad(this.duckYaw)) * back, dz = -Math.cos(rad(this.duckYaw)) * back;
        if (this.mode == M_OVER) sy = 1 - 0.25 * Math.min(1, this.overT * 3);
        api.placeScaled(this.bDuck, DUCK_X + dx, DUCK_Y + bob, DUCK_Z + dz, this.duckYaw, sxz, sy, sxz);

        for (let p = 0; p < NP; p++) {
            if (this.pOn[p]) {
                this.pAge[p] += dt;
                if (this.pAge[p] > 1.2) this.pOn[p] = false;
            }
        }
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (api.pick(x, y, <f32>(WATER + 0.28))) {
            this.aimX = <f64>api.hitX;
            this.aimZ = <f64>api.hitZ;
        }
        if (kind == POINTER_DOWN) {
            if (this.mode == M_OVER) {
                if (this.overT > 0.6) {
                    this.reset(api);
                    api.sound(SFX_BLIP, 1.0, 0.6);
                }
                return true;
            }
            if (this.mode == M_READY) {
                this.mode = M_PLAY;
                this.spawnT = 1.2;
                api.soundAt(SFX_JUMP, DUCK_X, DUCK_Y, DUCK_Z, 2.0, 0.6);   // a cheerful squeak: battle stations
            }
            // turn at once, then fire
            this.duckYaw = clamp(deg(Math.atan2(this.aimX - DUCK_X, this.aimZ - DUCK_Z)), 15, 165);
            this.fire(api, this.aimX, this.aimZ, -1);
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let cream = api.rampColor(0, 3);
        let dark = api.rampColor(1, 0);
        let yellow = api.rampColor(2, 2);
        let ochre = api.rampColor(2, 1);
        let orange = api.rampColor(3, 3);
        let rust = api.rampColor(3, 2);
        let sage = api.rampColor(1, 2);
        let plum = api.rampColor(0, 0);
        let W = <f32>api.hudW, H = <f32>api.hudH;

        api.text(4, 4, "SCORE " + this.score.toString(), cream, 1, dark);
        api.text(4, 11, "BEST " + this.best.toString(), yellow, 1, dark);

        // lives: little ducks (top right); a lost one is a dark outline
        for (let i = 0; i < LIVES; i++) {
            let x = W - 12 - <f32>i * 11;
            let on = i < this.lives;
            if (on) {
                api.rect(x + 1, 6, 7, 4, dark);
                api.rect(x, 5, 7, 4, yellow);
                api.rect(x + 3, 2, 4, 4, yellow);
                api.rect(x + 7, 4, 2, 1, orange);
                api.rect(x + 5, 3, 1, 1, dark);
            } else {
                api.rect(x, 8, 7, 1, plum);
                api.rect(x + 3, 2, 1, 4, plum);
                api.rect(x + 6, 2, 1, 4, plum);
                api.rect(x + 3, 2, 4, 1, plum);
            }
        }

        // the aim mark at the pointer (play)
        if (!api.demo && this.mode != M_OVER && api.pointerX >= 0) {
            let sx = Mathf.round(api.pointerX), sy = Mathf.round(api.pointerY);
            for (let k = 0; k < 2; k++) {
                let o = <f32>(1 - k);
                let c = k == 0 ? dark : cream;
                api.rect(sx - 3 + o, sy - 3 + o, 2, 1, c); api.rect(sx + 2 + o, sy - 3 + o, 2, 1, c);
                api.rect(sx - 3 + o, sy + 3 + o, 2, 1, c); api.rect(sx + 2 + o, sy + 3 + o, 2, 1, c);
            }
        }

        for (let p = 0; p < NP; p++) {
            if (!this.pOn[p]) continue;
            let age = this.pAge[p];
            if (age > 0.9 && Math.floor(age * 12) % 2 == 0) continue;
            if (api.project(<f32>this.pX[p], <f32>(this.pY[p] + age * 0.9), <f32>this.pZ[p])) {
                let s = this.pText[p];
                let k = this.pKind[p];
                let c = k == 3 ? orange : (k == 2 ? yellow : (k == 1 ? cream : sage));
                let sc = k == 3 ? 2 : 1;
                let tw = api.textWidth(s, sc);
                api.text(Mathf.round(api.screenX - tw * 0.5), Mathf.round(api.screenY), s, c, sc, dark);
            }
        }

        if (this.mode == M_OVER) {
            let y = Mathf.floor(H * 0.34);
            api.rect(0, y - 4, W, 34, dark);
            let n = this.popped.toString() + (this.popped == 1 ? " BOAT" : " BOATS");
            api.textCentered(y, "THE FLEET GOT THROUGH - " + n + " POPPED", sage, 1, 0);
            api.textCentered(y + 9, "SCORE " + this.score.toString(), cream, 2, 0);
            if (!api.demo && this.overT > 0.6) api.textCentered(y + 22, "CLICK TO PLAY AGAIN", yellow, 1, 0);
        } else if (this.mode == M_READY && !api.demo) {
            api.rect(0, H - 13, W, 9, dark);
            api.textCentered(H - 11, "CLICK TO FIRE BUBBLES AT THE BOATS", cream, 1, 0);
        } else if (!api.demo && this.runT < 4) {
            api.textCentered(H - 11, "DON'T LET THEM REACH THE DUCK!", cream, 1, dark);
        }
    }
}
