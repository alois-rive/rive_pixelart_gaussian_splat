// Lawn Mower: a ride-on mower follows the pointer over a shaggy lawn. Every tile it drives over is cut
// down to the striped lawn underneath. Mow the whole lawn before the clock runs out; bumping a garden
// gnome (-3 s) or a flower bed (-2 s) costs time. A cleared lawn scores a bonus, adds time, grows back
// and the gnomes move (one more each lawn). Pointer only; demo mode plays itself.
import { GameApi, POINTER_DOWN, POINTER_MOVE, SFX_WIN, SFX_THUD, SFX_CLICK, SFX_NOTE, SFX_HIT, SFX_POP, SFX_ZAP,
         SFX_TICK, SFX_POWERUP, SFX_JUMP, SFX_LOSE } from "./game_api";

// sound: a little two-stroke and a lawn that plays a scale. The engine putts (low thuds, faster and
// higher with speed); each cut tile snips and plucks a note that climbs a major scale as the lawn
// fills; a gnome bump is a crunch and a ceramic clink, a bed bump a crunch and a pop, both with a
// falling zap for the seconds lost; the clock ticks its last eight seconds; a clear lawn rings a
// fanfare and the gnomes hop.
const MAJOR: StaticArray<i32> = [0, 2, 4, 5, 7, 9, 11, 12, 14, 16, 17, 19, 21, 23, 24];

const ST_IDLE: i32 = 0;
const ST_PLAY: i32 = 1;
const ST_OVER: i32 = 2;

// tile states
const T_TALL: i32 = 0;
const T_CUT: i32 = 1;      // squashing down (then hidden)
const T_GONE: i32 = 2;     // mowed: the stripe shows
const T_GROW: i32 = 3;     // growing back after a cleared lawn

// the grid (glTF metres; models/env/make_env.py writes the same numbers)
const TS: f64 = 0.85;
const COLS: i32 = 8;
const ROWS: i32 = 6;
const X0: f64 = -3.4;      // the lawn's back-left corner
const Z0: f64 = -2.55;
const NTILE: i32 = 44;     // 48 cells less the 4 under the flower beds
const NGNOME: i32 = 4;
const NCLIP: i32 = 8;
const NPETAL: i32 = 4;
const START_TIME: f64 = 40.0;
const LAWN_TIME: f64 = 16.0;   // seconds added for a cleared lawn
const MAXV: f64 = 2.7;         // m/s
const TURN: f64 = 250.0;       // degrees a second
const CUT_R: f64 = 0.58;       // a tile is cut when the deck's centre comes this near its centre
const MOW_R: f64 = 0.4;        // the mower's bumper radius
const GNOME_R: f64 = 0.24;     // the gnome (baked at 1.4 x its model): a tile beside one is cut only off-centre
const LIM_X: f64 = 3.75;       // the mower stays on the lawn and the path round it
const LIM_Z: f64 = 2.9;
// the two flower beds: x0, x1, z0, z1 (their stone kerbs)
const BED_X0: StaticArray<f64> = [-2.55, 0.85];
const BED_X1: StaticArray<f64> = [-0.85, 2.55];
const BED_Z0: StaticArray<f64> = [-1.7, 0.85];
const BED_Z1: StaticArray<f64> = [-0.85, 1.7];

// palette indices (art/palette.json "colors")
const P_TAN: i32 = 0;
const P_DARK: i32 = 3;
const P_RED: i32 = 5;
const P_ORANGE: i32 = 6;
const P_YELLOW: i32 = 7;
const P_GREEN: i32 = 8;
const P_MID: i32 = 9;
const P_DEEP: i32 = 10;
const P_WHITE: i32 = 13;
const P_PALE: i32 = 12;
const P_CYAN: i32 = 14;

export class Game {
    state: i32 = ST_IDLE;
    stateT: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    clock: f64 = START_TIME;
    lawn: i32 = 1;
    mowed: i32 = 0;
    wasDemo: bool = false;

    // bones
    mower: i32 = -1;
    tileBone: StaticArray<i32> = new StaticArray<i32>(NTILE);
    gnomeBone: StaticArray<i32> = new StaticArray<i32>(NGNOME);
    clipBone: StaticArray<i32> = new StaticArray<i32>(NCLIP);
    petalBone: StaticArray<i32> = new StaticArray<i32>(NPETAL);

    // tiles
    tX: StaticArray<f64> = new StaticArray<f64>(NTILE);
    tZ: StaticArray<f64> = new StaticArray<f64>(NTILE);
    tYaw: StaticArray<f64> = new StaticArray<f64>(NTILE);
    tSt: StaticArray<i32> = new StaticArray<i32>(NTILE);
    tT: StaticArray<f64> = new StaticArray<f64>(NTILE);

    // gnomes (on grid corners)
    gOn: StaticArray<bool> = new StaticArray<bool>(NGNOME);
    gX: StaticArray<f64> = new StaticArray<f64>(NGNOME);
    gZ: StaticArray<f64> = new StaticArray<f64>(NGNOME);
    gFromX: StaticArray<f64> = new StaticArray<f64>(NGNOME);
    gFromZ: StaticArray<f64> = new StaticArray<f64>(NGNOME);
    gYaw: StaticArray<f64> = new StaticArray<f64>(NGNOME);
    gHit: StaticArray<f64> = new StaticArray<f64>(NGNOME);     // > 0: knocked, wobbling
    gHitDir: StaticArray<f64> = new StaticArray<f64>(NGNOME);
    gHop: StaticArray<f64> = new StaticArray<f64>(NGNOME);     // >= 0: hopping to a new corner
    gnomes: i32 = 2;

    // the mower
    mx: f64 = -3.7;
    mz: f64 = 2.85;
    myaw: f64 = 180;
    mv: f64 = 0;
    tx: f64 = -3.7;
    tz: f64 = 2.85;
    stun: f64 = 0;
    guard: f64 = 0;        // > 0: just bumped; touching again only slides (no second penalty)
    cutGlow: f64 = 0;      // > 0: just cut grass (engine shakes, clippings fly)
    enginePh: f64 = 0;     // the engine's putt phase (sound only)
    clipT: f64 = 0;

    // particles
    cT: StaticArray<f64> = new StaticArray<f64>(NCLIP);
    cX: StaticArray<f64> = new StaticArray<f64>(NCLIP);
    cY: StaticArray<f64> = new StaticArray<f64>(NCLIP);
    cZ: StaticArray<f64> = new StaticArray<f64>(NCLIP);
    cVX: StaticArray<f64> = new StaticArray<f64>(NCLIP);
    cVY: StaticArray<f64> = new StaticArray<f64>(NCLIP);
    cVZ: StaticArray<f64> = new StaticArray<f64>(NCLIP);
    cNext: i32 = 0;
    pT: StaticArray<f64> = new StaticArray<f64>(NPETAL);
    pX: StaticArray<f64> = new StaticArray<f64>(NPETAL);
    pY: StaticArray<f64> = new StaticArray<f64>(NPETAL);
    pZ: StaticArray<f64> = new StaticArray<f64>(NPETAL);
    pVX: StaticArray<f64> = new StaticArray<f64>(NPETAL);
    pVY: StaticArray<f64> = new StaticArray<f64>(NPETAL);
    pVZ: StaticArray<f64> = new StaticArray<f64>(NPETAL);

    // juice
    popT: f64 = -1;
    popX: f32 = 0;
    popY: f32 = 0;
    popText: string = "";
    popCol: i32 = P_YELLOW;
    bannerT: f64 = -1;     // LAWN CLEAR! banner
    shakeT: f64 = 0;
    flashT: f64 = 0;       // the clock flashes after a penalty
    camTX: f64 = 0;
    camTZ: f64 = 0;

    // the demo player
    dThink: f64 = 0;
    dTile: i32 = -1;
    dErrX: f64 = 0;
    dErrZ: f64 = 0;
    dSkip: i32 = -1;
    dSkipT: f64 = 0;
    dIdle: f64 = 0;        // seconds since the demo last cut a tile
    dMowed: i32 = 0;

    start(api: GameApi): void {
        api.playable = true;
        this.mower = api.bone("mower");
        for (let i = 0; i < NTILE; i++) {
            this.tileBone[i] = api.bone("tile" + i.toString());
        }
        for (let i = 0; i < NGNOME; i++) {
            this.gnomeBone[i] = api.bone("gnome" + i.toString());
        }
        for (let i = 0; i < NCLIP; i++) {
            this.clipBone[i] = api.bone("clip" + i.toString());
            this.cT[i] = -1;
        }
        for (let i = 0; i < NPETAL; i++) {
            this.petalBone[i] = api.bone("petal" + i.toString());
            this.pT[i] = -1;
        }
        // the 44 tiles: every cell but the four under the beds, row by row
        let k = 0;
        for (let r = 0; r < ROWS; r++) {
            for (let c = 0; c < COLS; c++) {
                if ((r == 1 && (c == 1 || c == 2)) || (r == 4 && (c == 5 || c == 6))) {
                    continue;
                }
                this.tX[k] = X0 + (<f64>c + 0.5) * TS;
                this.tZ[k] = Z0 + (<f64>r + 0.5) * TS;
                this.tYaw[k] = <f64>((c * 7 + r * 3) % 4) * 90.0;
                k++;
            }
        }
        this.camTX = api.targetX;
        this.camTZ = api.targetZ;
        this.wasDemo = api.demo;
        this.resetWorld(api);
        if (api.demo) {
            this.beginRun(api);
        }
    }

    // ------------------------------------------------------------------ run control

    resetWorld(api: GameApi): void {
        for (let i = 0; i < NTILE; i++) {
            this.tSt[i] = T_TALL;
            this.tT[i] = 0;
        }
        this.mowed = 0;
        this.score = 0;
        this.clock = START_TIME;
        this.lawn = 1;
        this.gnomes = 2;
        this.mx = -3.7; this.mz = 2.85; this.myaw = 180; this.mv = 0;
        this.tx = this.mx; this.tz = this.mz - 0.5;
        this.stun = 0;
        this.state = ST_IDLE;
        this.stateT = 0;
        this.bannerT = -1;
        this.popT = -1;
        this.shakeT = 0;
        this.flashT = 0;
        this.guard = 0;
        this.placeGnomes(api, false);
    }

    beginRun(api: GameApi): void {
        if (this.state == ST_OVER) {
            // the lawn grows back for the new run, the mower is back at its corner
            for (let i = 0; i < NTILE; i++) {
                if (this.tSt[i] != T_TALL) {
                    this.tSt[i] = T_GROW;
                    this.tT[i] = -this.growDelay(i);
                }
            }
            api.sound(SFX_JUMP, 0.8, 0.5);
            this.mowed = 0;
            this.score = 0;
            this.clock = START_TIME;
            this.lawn = 1;
            this.gnomes = 2;
            this.placeGnomes(api, true);
        }
        this.state = ST_PLAY;
        this.stateT = 0;
        this.dThink = 0;
        this.dTile = -1;
        api.sound(SFX_WIN, 1.0, 0.55);
    }

    endRun(): void {
        this.state = ST_OVER;
        this.stateT = 0;
        this.mv = 0;
        if (this.score > this.best) {
            this.best = this.score;
        }
    }

    growDelay(i: i32): f64 {
        // the regrowth runs as a wave from the back-right corner
        let dx = this.tX[i] - 3.4, dz = this.tZ[i] + 2.55;
        return Math.sqrt(dx * dx + dz * dz) * 0.12;
    }

    // gnomes stand on inner grid corners, so a tile beside one is cut only off-centre. Every gap round a
    // gnome (to a bed, to another gnome) is wider than the mower, so nothing can be walled in.
    placeGnomes(api: GameApi, hop: bool): void {
        let cx = new StaticArray<f64>(35);
        let cz = new StaticArray<f64>(35);
        for (let g = 0; g < NGNOME; g++) {
            this.gFromX[g] = this.gX[g];
            this.gFromZ[g] = this.gZ[g];
            let wasOn = this.gOn[g];
            this.gOn[g] = false;
            if (g >= this.gnomes) {
                continue;
            }
            let n = 0;
            for (let c = 1; c < COLS; c++) {
                for (let r = 1; r < ROWS; r++) {
                    let x = X0 + <f64>c * TS, z = Z0 + <f64>r * TS;
                    if (this.nearBed(x, z, 1.1)) {
                        continue;
                    }
                    let ok = true;
                    for (let o = 0; o < g; o++) {
                        let ox = this.gX[o] - x, oz = this.gZ[o] - z;
                        if (this.gOn[o] && ox * ox + oz * oz < 1.75 * 1.75) {
                            ok = false;
                        }
                    }
                    let dx = x - this.mx, dz = z - this.mz;
                    if (ok && dx * dx + dz * dz > 1.4 * 1.4) {
                        cx[n] = x;
                        cz[n] = z;
                        n++;
                    }
                }
            }
            if (n == 0) {
                continue;
            }
            let k = <i32>Math.floor(api.rand() * <f64>n) % n;
            this.gX[g] = cx[k];
            this.gZ[g] = cz[k];
            this.gOn[g] = true;
            this.gYaw[g] = api.range(-30, 30);
            this.gHit[g] = 0;
            this.gHop[g] = hop ? 0.0 : -1.0;
            if (hop && !wasOn) {
                // a new gnome hops in from the border
                this.gFromX[g] = this.gX[g] < 0 ? -5.0 : 5.0;
                this.gFromZ[g] = this.gZ[g];
            }
        }
    }

    nearBed(x: f64, z: f64, m: f64): bool {
        for (let b = 0; b < 2; b++) {
            if (x > BED_X0[b] - m && x < BED_X1[b] + m && z > BED_Z0[b] - m && z < BED_Z1[b] + m) {
                return true;
            }
        }
        return false;
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged || api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.resetWorld(api);
            if (api.demo) {
                this.beginRun(api);
            }
        }
        this.stateT += dt;
        if (api.demo) {
            this.demoThink(api, dt);
            if (this.state == ST_OVER && this.stateT > 2.0) {
                this.beginRun(api);
            }
        }
        if (this.state == ST_PLAY) {
            let was = Math.ceil(this.clock);
            this.clock -= dt;
            if (this.clock <= 0) {
                this.clock = 0;
                this.endRun();
                api.sound(SFX_LOSE, 1.0, 0.7);
            } else if (this.clock < 8.0 && Math.ceil(this.clock) != was) {
                api.sound(SFX_TICK, 0.45 + 0.04 * (8.0 - Math.ceil(this.clock)), 0.9);
            }
        }
        this.updateMower(api, dt);
        this.updateTiles(api, dt);
        this.updateGnomes(api, dt);
        this.updateBits(api, dt);
        // a bump shakes the view by whole texels (the view's up is tilted by the pitch)
        let texel = api.orthoHeight / 136.0;
        if (this.shakeT > 0) {
            this.shakeT -= dt;
            let k = Math.floor(api.time * 30.0);
            let ox = Math.sin(k * 12.9898) * 43758.5453;
            ox = ox - Math.floor(ox);
            let oz = Math.sin(k * 78.233) * 12543.1234;
            oz = oz - Math.floor(oz);
            api.targetX = this.camTX + Math.round(ox * 2.0 - 1.0) * texel;
            api.targetZ = this.camTZ + Math.round(oz * 2.0 - 1.0) * texel / Math.sin(api.pitch * Math.PI / 180.0);
        } else {
            api.targetX = this.camTX;
            api.targetZ = this.camTZ;
        }
        if (this.popT >= 0) {
            this.popT += dt;
            if (this.popT > 0.9) {
                this.popT = -1;
            }
        }
        if (this.bannerT >= 0) {
            this.bannerT += dt;
            if (this.bannerT > 1.8) {
                this.bannerT = -1;
            }
        }
        if (this.flashT > 0) {
            this.flashT -= dt;
        }
    }

    updateMower(api: GameApi, dt: f64): void {
        let playing = this.state == ST_PLAY;
        if (this.state == ST_IDLE && !api.demo) {
            // waiting for the first click: the engine idles, the mower creeps round its corner
            this.tx = -3.7 + 0.15 * Math.sin(api.time * 0.7);
            this.tz = 2.85;
        }
        if (this.guard > 0) {
            this.guard -= dt;
        }
        if (this.stun > 0) {
            this.stun -= dt;
            // knocked back: it rolls backwards, slowing
            this.mv *= Math.pow(0.02, dt);
        } else if (playing) {
            let dx = this.tx - this.mx, dz = this.tz - this.mz;
            let dist = Math.sqrt(dx * dx + dz * dz);
            let want = 0.0;
            if (dist > 0.18) {
                let head = Math.atan2(dx, dz) * 180.0 / Math.PI;
                let diff = head - this.myaw;
                while (diff > 180.0) { diff -= 360.0; }
                while (diff < -180.0) { diff += 360.0; }
                let turn = TURN * dt;
                this.myaw += Math.max(-turn, Math.min(turn, diff));
                // full speed when facing the target, slow while turning hard
                let align = Math.max(0.0, Math.cos(diff * Math.PI / 180.0));
                // (the demo driver is a little more cautious than the engine allows)
                want = Math.min(api.demo ? MAXV * 0.85 : MAXV, dist * 3.0) * (0.25 + 0.75 * align);
            }
            this.mv += (want - this.mv) * Math.min(1.0, dt * 5.0);
        } else {
            this.mv *= Math.pow(0.05, dt);
        }
        let yr = this.myaw * Math.PI / 180.0;
        this.mx += Math.sin(yr) * this.mv * dt;
        this.mz += Math.cos(yr) * this.mv * dt;
        this.mx = Math.max(-LIM_X, Math.min(LIM_X, this.mx));
        this.mz = Math.max(-LIM_Z, Math.min(LIM_Z, this.mz));
        if (playing) {
            // the engine: a putt a phase step, 3 a second at idle to 7 at full speed
            let ph = this.enginePh;
            this.enginePh += dt * (3.0 + 1.5 * Math.abs(this.mv));
            if (Math.floor(this.enginePh) != Math.floor(ph) && this.stun <= 0) {
                api.soundAt(SFX_THUD, this.mx, 0.3, this.mz, 1.4 + 0.25 * Math.abs(this.mv), 0.35);
            }
            this.collide(api);
            this.cut(api);
        }
        // the engine: a stepped 12 fps judder, stronger while cutting; a hop after a bump
        let k = Math.floor(api.time * 12.0);
        let jud = (k % 2 == 0 ? 1.0 : -1.0) * (this.cutGlow > 0 ? 1.5 : 0.7);
        let hop = this.stun > 0 ? Math.sin(Math.max(0.0, this.stun) / 0.4 * Math.PI) * 0.18 : 0.0;
        let y = (k % 2 == 0 ? 0.015 : 0.0) + hop;
        let pitch = -this.mv * 1.2;
        api.place(this.mower, this.mx, y, this.mz, this.myaw, pitch, jud + (this.stun > 0 ? 8.0 * Math.sin(this.stun * 40.0) : 0.0));
        if (this.cutGlow > 0) {
            this.cutGlow -= dt;
        }
    }

    collide(api: GameApi): void {
        let hard = this.stun <= 0 && this.guard <= 0 && this.mv > 1.0;
        // flower beds: the bumper against the kerb
        for (let b = 0; b < 2; b++) {
            let cx = Math.max(BED_X0[b], Math.min(BED_X1[b], this.mx));
            let cz = Math.max(BED_Z0[b], Math.min(BED_Z1[b], this.mz));
            let dx = this.mx - cx, dz = this.mz - cz;
            let d2 = dx * dx + dz * dz;
            if (d2 < MOW_R * MOW_R) {
                let d = Math.sqrt(d2);
                let nx = d > 1e-4 ? dx / d : 0.0, nz = d > 1e-4 ? dz / d : 1.0;
                this.mx = cx + nx * (MOW_R + 0.02);
                this.mz = cz + nz * (MOW_R + 0.02);
                if (hard) {
                    this.bump(api, 2.0, cx, cz, true);
                }
                return;
            }
        }
        for (let g = 0; g < NGNOME; g++) {
            if (!this.gOn[g] || this.gHop[g] >= 0) {
                continue;
            }
            let dx = this.mx - this.gX[g], dz = this.mz - this.gZ[g];
            let rr = MOW_R + GNOME_R;
            let d2 = dx * dx + dz * dz;
            if (d2 < rr * rr) {
                let d = Math.max(1e-4, Math.sqrt(d2));
                this.mx = this.gX[g] + dx / d * (rr + 0.02);
                this.mz = this.gZ[g] + dz / d * (rr + 0.02);
                if (hard) {
                    this.gHit[g] = 0.9;
                    this.gHitDir[g] = Math.atan2(-dx, -dz) * 180.0 / Math.PI;
                    this.bump(api, 3.0, this.gX[g], this.gZ[g], false);
                }
                return;
            }
        }
    }

    bump(api: GameApi, cost: f64, x: f64, z: f64, bed: bool): void {
        this.clock = Math.max(0.0, this.clock - cost);
        api.soundAt(SFX_HIT, x, 0.3, z, bed ? 0.7 : 0.9, 0.9);
        if (bed) {
            api.soundAt(SFX_POP, x, 0.3, z, 0.8, 0.7);
        } else {
            api.note(88, 0.45, 0, SFX_NOTE); // the gnome's ceramic clink
        }
        api.sound(SFX_ZAP, 0.5, 0.45);
        // the demo gives up on that patch for a while (a player would go round and come back)
        this.dSkip = this.dTile;
        this.dSkipT = 3.0;
        this.dTile = -1;
        this.stun = 0.4;
        this.guard = 2.0;
        this.mv = -1.6;
        this.shakeT = 0.25;
        this.flashT = 0.8;
        this.pop(api, x, z, "-" + (<i32>cost).toString() + "S", P_RED);
        if (bed) {
            for (let k = 0; k < NPETAL; k++) {
                this.pT[k] = 0;
                this.pX[k] = x; this.pY[k] = 0.35; this.pZ[k] = z;
                this.pVX[k] = api.range(-1.5, 1.5); this.pVY[k] = api.range(2.0, 3.2); this.pVZ[k] = api.range(-1.5, 1.5);
            }
        }
    }

    pop(api: GameApi, x: f64, z: f64, s: string, col: i32): void {
        if (api.project(<f32>x, 1.2, <f32>z)) {
            this.popX = api.screenX;
            this.popY = api.screenY;
            this.popText = s;
            this.popCol = col;
            this.popT = 0;
        }
    }

    cut(api: GameApi): void {
        for (let i = 0; i < NTILE; i++) {
            if (this.tSt[i] != T_TALL) {
                continue;
            }
            let dx = this.tX[i] - this.mx, dz = this.tZ[i] - this.mz;
            if (dx * dx + dz * dz < CUT_R * CUT_R) {
                this.tSt[i] = T_CUT;
                this.tT[i] = 0;
                this.mowed++;
                this.score += 10;
                api.soundAt(SFX_CLICK, this.tX[i], 0, this.tZ[i], 0.6, 0.7);
                api.note(<f64>(60 + MAJOR[min<i32>(14, (this.mowed - 1) * 15 / NTILE)]), 0.55, 0, SFX_NOTE);
                this.cutGlow = 0.3;
                for (let s = 0; s < 3; s++) {
                    this.clip(api);
                }
            }
        }
        if (this.mowed >= NTILE) {
            // the whole lawn: a bonus, more time, it grows back and the gnomes move (one more)
            let bonus = 100 + <i32>Math.floor(this.clock) * 2;
            this.score += bonus;
            this.clock += LAWN_TIME;
            this.lawn++;
            this.gnomes = min<i32>(NGNOME, this.gnomes + 1);
            this.mowed = 0;
            this.bannerT = 0;
            this.popText = "+" + bonus.toString();
            for (let i = 0; i < NTILE; i++) {
                this.tSt[i] = T_GROW;
                this.tT[i] = -0.9 - this.growDelay(i);
            }
            this.placeGnomes(api, true);
            this.dTile = -1;
            api.sound(SFX_POWERUP, 1.0, 0.8);
            api.sound(SFX_WIN, 1.5, 0.6);
            api.sound(SFX_JUMP, 0.8, 0.5);
        }
    }

    clip(api: GameApi): void {
        // clippings fly out of the chute on the mower's own right side
        let k = this.cNext;
        this.cNext = (this.cNext + 1) % NCLIP;
        let yr = this.myaw * Math.PI / 180.0;
        let rx = -Math.cos(yr), rz = Math.sin(yr);
        this.cT[k] = 0;
        this.cX[k] = this.mx + rx * 0.55;
        this.cY[k] = 0.2;
        this.cZ[k] = this.mz + rz * 0.55;
        let sp = api.range(1.4, 2.6);
        this.cVX[k] = rx * sp + api.range(-0.4, 0.4);
        this.cVY[k] = api.range(1.6, 2.6);
        this.cVZ[k] = rz * sp + api.range(-0.4, 0.4);
    }

    updateTiles(api: GameApi, dt: f64): void {
        for (let i = 0; i < NTILE; i++) {
            let b = this.tileBone[i];
            let st = this.tSt[i];
            this.tT[i] += dt;
            let t = this.tT[i];
            if (st == T_TALL) {
                // a breeze ruffles the long grass: a stepped lean, out of step tile to tile
                let w = Math.floor(api.time * 4.0 + <f64>i * 0.37) % 4 == 0 ? 3.0 : 0.0;
                api.place(b, this.tX[i], 0, this.tZ[i], this.tYaw[i], w, 0);
            } else if (st == T_CUT) {
                // squashed flat under the deck (stepped at 15 fps), then gone
                let k = Math.floor(t * 15.0) / 15.0 / 0.2;
                if (k >= 1.0) {
                    this.tSt[i] = T_GONE;
                    api.hide(b);
                } else {
                    api.placeScaled(b, this.tX[i], 0, this.tZ[i], this.tYaw[i], 1.0 + k * 0.12, 1.0 - k * 0.85, 1.0 + k * 0.12);
                }
            } else if (st == T_GONE) {
                api.hide(b);
            } else {
                if (t < 0) {
                    api.hide(b);
                } else {
                    // sprouts up with an overshoot
                    let k = Math.floor(t * 15.0) / 15.0 / 0.35;
                    if (k >= 1.0) {
                        this.tSt[i] = T_TALL;
                        api.place(b, this.tX[i], 0, this.tZ[i], this.tYaw[i]);
                    } else {
                        let sy = k < 0.7 ? 0.12 + k / 0.7 * 1.08 : 1.2 - (k - 0.7) / 0.3 * 0.2;
                        api.placeScaled(b, this.tX[i], 0, this.tZ[i], this.tYaw[i], 1.0, sy, 1.0);
                    }
                }
            }
        }
    }

    updateGnomes(api: GameApi, dt: f64): void {
        for (let g = 0; g < NGNOME; g++) {
            let b = this.gnomeBone[g];
            if (!this.gOn[g]) {
                api.hide(b);
                continue;
            }
            if (this.gHop[g] >= 0) {
                // hops (three stepped bounces) from where it stood to its new corner
                this.gHop[g] += dt;
                let k = Math.min(1.0, Math.floor(this.gHop[g] * 15.0) / 15.0 / 0.9);
                let x = this.gFromX[g] + (this.gX[g] - this.gFromX[g]) * k;
                let z = this.gFromZ[g] + (this.gZ[g] - this.gFromZ[g]) * k;
                let y = Math.abs(Math.sin(k * Math.PI * 3.0)) * 0.35;
                api.place(b, x, y, z, this.gYaw[g] + (1.0 - k) * 180.0);
                if (k >= 1.0) {
                    this.gHop[g] = -1;
                }
                continue;
            }
            if (this.gHit[g] > 0) {
                // knocked: it topples away from the mower, rocks, and stands back up
                this.gHit[g] -= dt;
                let k = 1.0 - this.gHit[g] / 0.9;
                let tilt = k < 0.25 ? k / 0.25 * 70.0 : 70.0 * (1.0 - (k - 0.25) / 0.75) + Math.sin(k * 30.0) * 10.0 * (1.0 - k);
                tilt = Math.round(tilt / 7.0) * 7.0;
                api.place(b, this.gX[g], 0, this.gZ[g], this.gHitDir[g], tilt, 0);
                continue;
            }
            // a tiny idle sway
            let s = Math.floor(api.time * 3.0 + <f64>g) % 6 == 0 ? 4.0 : 0.0;
            api.place(b, this.gX[g], 0, this.gZ[g], this.gYaw[g], 0, s);
        }
    }

    updateBits(api: GameApi, dt: f64): void {
        if (this.cutGlow > 0 && this.state == ST_PLAY) {
            this.clipT -= dt;
            if (this.clipT <= 0) {
                this.clip(api);
                this.clipT = 0.05;
            }
        }
        for (let k = 0; k < NCLIP; k++) {
            let b = this.clipBone[k];
            if (this.cT[k] < 0) {
                api.hide(b);
                continue;
            }
            this.cT[k] += dt;
            this.cVY[k] -= 9.0 * dt;
            this.cX[k] += this.cVX[k] * dt;
            this.cY[k] += this.cVY[k] * dt;
            this.cZ[k] += this.cVZ[k] * dt;
            if (this.cY[k] < 0.03 || this.cT[k] > 0.8) {
                this.cT[k] = -1;
                api.hide(b);
                continue;
            }
            api.place(b, this.cX[k], this.cY[k], this.cZ[k], Math.floor(this.cT[k] * 12.0) * 50.0, 30, 0);
        }
        for (let k = 0; k < NPETAL; k++) {
            let b = this.petalBone[k];
            if (this.pT[k] < 0) {
                api.hide(b);
                continue;
            }
            this.pT[k] += dt;
            this.pVY[k] -= 9.0 * dt;
            this.pX[k] += this.pVX[k] * dt;
            this.pY[k] += this.pVY[k] * dt;
            this.pZ[k] += this.pVZ[k] * dt;
            if (this.pY[k] < 0.03 || this.pT[k] > 1.0) {
                this.pT[k] = -1;
                api.hide(b);
                continue;
            }
            api.place(b, this.pX[k], this.pY[k], this.pZ[k], Math.floor(this.pT[k] * 12.0) * 40.0, 20, 0);
        }
    }

    // ------------------------------------------------------------------ the demo player

    // true when the straight drive from the mower to (x, z) clips a bed or a gnome
    blocked(x: f64, z: f64): bool {
        for (let s = 1; s <= 8; s++) {
            let f = <f64>s / 8.0;
            let px = this.mx + (x - this.mx) * f, pz = this.mz + (z - this.mz) * f;
            if (this.nearBed(px, pz, MOW_R - 0.05)) {
                return true;
            }
            for (let g = 0; g < NGNOME; g++) {
                if (!this.gOn[g]) {
                    continue;
                }
                let dx = px - this.gX[g], dz = pz - this.gZ[g];
                if (dx * dx + dz * dz < (MOW_R + GNOME_R - 0.05) * (MOW_R + GNOME_R - 0.05)) {
                    return true;
                }
            }
        }
        return false;
    }

    // a spot the mower's centre can stand on without touching a bed or a gnome (with a margin)
    clear(x: f64, z: f64): bool {
        if (this.nearBed(x, z, MOW_R + 0.08)) {
            return false;
        }
        for (let g = 0; g < NGNOME; g++) {
            if (!this.gOn[g]) {
                continue;
            }
            let dx = x - this.gX[g], dz = z - this.gZ[g];
            if (dx * dx + dz * dz < (MOW_R + GNOME_R + 0.08) * (MOW_R + GNOME_R + 0.08)) {
                return false;
            }
        }
        return true;
    }

    demoThink(api: GameApi, dt: f64): void {
        if (this.state != ST_PLAY) {
            return;
        }
        this.dThink -= dt;
        if (this.dSkipT > 0) {
            this.dSkipT -= dt;
        }
        this.dIdle = this.mowed != this.dMowed ? 0.0 : this.dIdle + dt;
        this.dMowed = this.mowed;
        if (this.dIdle > 3.0) {
            // stuck: drive off to some other long grass for a while
            this.dIdle = 0;
            this.dSkip = this.dTile;
            this.dSkipT = 2.5;
            this.dTile = -1;
        }
        let cur = this.dTile;
        if (cur >= 0 && this.tSt[cur] != T_TALL) {
            cur = -1;
        }
        if (this.dThink <= 0 || cur < 0) {
            // a mower's plan: the nearest long grass, along the current row's direction, round obstacles
            this.dThink = api.range(0.25, 0.5);
            let bestI = -1;
            let bestV = 1e9;
            let yr = this.myaw * Math.PI / 180.0;
            let fx = Math.sin(yr), fz = Math.cos(yr);
            for (let i = 0; i < NTILE; i++) {
                if (this.tSt[i] != T_TALL || (i == this.dSkip && this.dSkipT > 0)) {
                    continue;
                }
                let dx = this.tX[i] - this.mx, dz = this.tZ[i] - this.mz;
                let d = Math.sqrt(dx * dx + dz * dz);
                let v = d;
                // prefer what is ahead (fewer U-turns) and the same row
                if (d > 0.01) {
                    v -= (dx * fx + dz * fz) / d * 0.45;
                }
                v += Math.abs(dz) * 0.6;
                if (this.blocked(this.tX[i], this.tZ[i])) {
                    v += 2.5;
                }
                if (v < bestV) {
                    bestV = v;
                    bestI = i;
                }
            }
            // now and then a sloppier choice
            if (bestI >= 0 && api.rand() < 0.14) {
                let j = <i32>Math.floor(api.rand() * <f64>NTILE) % NTILE;
                if (this.tSt[j] == T_TALL) {
                    bestI = j;
                }
            }
            if (cur < 0 || bestI != cur) {
                this.dErrX = api.range(-0.18, 0.18);
                this.dErrZ = api.range(-0.18, 0.18);
            }
            this.dTile = bestI;
            cur = bestI;
        }
        if (cur < 0) {
            this.tx = this.mx;
            this.tz = this.mz;
            return;
        }
        // aim a little past the tile, so the mower drives through it rather than stopping on it, and
        // steer round a bed or a gnome ahead (a player's eye): a sideways push away from it
        let ax = this.tX[cur] + this.dErrX, az = this.tZ[cur] + this.dErrZ;
        let over = 0.5;
        if (!this.clear(this.tX[cur], this.tZ[cur])) {
            // a tile hemmed in by a bed or a gnome: cut it from a clear spot inside it, the one nearest
            // the mower, and do not run on past it
            let bestD = 1e9;
            for (let k = 0; k < 16; k++) {
                let a = <f64>k * Math.PI / 8.0;
                let r = k % 2 == 0 ? 0.3 : 0.4;
                let px = this.tX[cur] + Math.sin(a) * r, pz = this.tZ[cur] + Math.cos(a) * r;
                if (!this.clear(px, pz)) {
                    continue;
                }
                let qx = px - this.mx, qz = pz - this.mz;
                let qd = qx * qx + qz * qz;
                if (qd < bestD) {
                    bestD = qd;
                    ax = px;
                    az = pz;
                }
            }
            over = 0.05;
        }
        let dx = ax - this.mx, dz = az - this.mz;
        let d = Math.max(0.01, Math.sqrt(dx * dx + dz * dz));
        let ux = dx / d, uz = dz / d;
        let px = uz, pz = -ux;
        let sx = 0.0, sz = 0.0;
        for (let b = 0; b < 3 + NGNOME; b++) {
            let ox = 0.0, oz = 0.0, reach = 1.25;
            if (b < 2) {
                ox = Math.max(BED_X0[b], Math.min(BED_X1[b], this.mx));
                oz = Math.max(BED_Z0[b], Math.min(BED_Z1[b], this.mz));
            } else if (b >= 3 && this.gOn[b - 3] && this.gHop[b - 3] < 0) {
                ox = this.gX[b - 3];
                oz = this.gZ[b - 3];
                reach = 1.05;
            } else {
                continue;
            }
            let qx = ox - this.mx, qz = oz - this.mz;
            let qd = Math.sqrt(qx * qx + qz * qz);
            let ahead = qx * ux + qz * uz;
            if (qd < reach && ahead > -0.1 && ahead < d + 0.4) {
                let side = qx * px + qz * pz;
                let sgn = side > 0.0 ? -1.0 : 1.0;
                let k = (reach - qd) * 2.4;
                sx += px * sgn * k;
                sz += pz * sgn * k;
            }
        }
        this.tx = ax + ux * over + sx;
        this.tz = az + uz * over + sz;
    }

    // ------------------------------------------------------------------ input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.state == ST_IDLE) {
                this.beginRun(api);
            } else if (this.state == ST_OVER && this.stateT > 0.8) {
                this.beginRun(api);
            }
        }
        if ((kind == POINTER_DOWN || kind == POINTER_MOVE) && this.state == ST_PLAY && api.pick(x, y, 0)) {
            this.tx = <f64>api.hitX;
            this.tz = <f64>api.hitZ;
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let dark = api.paletteColor(P_DARK);
        let white = api.paletteColor(P_WHITE);
        let pale = api.paletteColor(P_PALE);
        let yellow = api.paletteColor(P_YELLOW);
        let red = api.paletteColor(P_RED);
        let orange = api.paletteColor(P_ORANGE);
        let green = api.paletteColor(P_GREEN);
        let mid = api.paletteColor(P_MID);
        let deep = api.paletteColor(P_DEEP);
        let cyan = api.paletteColor(P_CYAN);
        let tan = api.paletteColor(P_TAN);
        let w = <f32>api.hudW, h = <f32>api.hudH;
        // score and best, top left
        api.text(4, 4, this.score.toString(), yellow, 2, dark);
        api.text(4, 16, "BEST " + this.best.toString(), pale, 1, dark);
        // the clock, top right: whole seconds, red and blinking when short or just cut
        let secs = <i32>Math.ceil(this.clock);
        let ts = secs.toString() + "S";
        let tw = api.textWidth(ts, 2);
        let low = this.clock < 8.0 && this.state == ST_PLAY;
        let tc = (this.flashT > 0 && Math.floor(this.flashT * 10.0) % 2 == 0) || (low && Math.floor(api.time * 4.0) % 2 == 0) ? red : white;
        api.text(w - 4 - tw, 4, ts, tc, 2, dark);
        api.text(w - 4 - api.textWidth("LAWN " + this.lawn.toString(), 1), 16, "LAWN " + this.lawn.toString(), pale, 1, dark);
        // the mowing bar, top middle
        let bw: f32 = 60;
        let bx = Mathf.floor((w - bw) * 0.5);
        api.rect(bx - 1, 5, bw + 2, 6, dark);
        api.rect(bx, 6, bw, 4, deep);
        let frac = <f32>this.mowed / <f32>NTILE;
        api.rect(bx, 6, Mathf.round(bw * frac), 4, green);
        api.rect(bx, 6, Mathf.round(bw * frac), 1, yellow);
        if (this.popT >= 0) {
            let rise = <f32>(Math.floor(this.popT * 12.0) * 1.5);
            let pw = api.textWidth(this.popText, 1);
            api.text(Mathf.round(this.popX - pw * 0.5), Mathf.round(this.popY - rise), this.popText, api.paletteColor(this.popCol), 1, dark);
        }
        if (this.bannerT >= 0 && this.state == ST_PLAY) {
            let blink = Math.floor(this.bannerT * 6.0) % 2 == 0;
            api.textCentered(h * 0.5 - 14, "LAWN CLEAR!", blink ? yellow : white, 2, dark);
            api.textCentered(h * 0.5, this.popText + " AND +" + (<i32>LAWN_TIME).toString() + "S", white, 1, dark);
        }
        if (this.state == ST_IDLE) {
            let blink = Math.floor(api.time * 2.0) % 2 == 0;
            api.textCentered(h - 22, "CLICK TO START MOWING", blink ? yellow : white, 2, dark);
            api.textCentered(h - 9, "STEER WITH THE POINTER - MISS THE GNOMES AND BEDS", white, 1, dark);
        } else if (this.state == ST_OVER) {
            let pw: f32 = 124, ph: f32 = 42;
            let px = Mathf.floor((w - pw) * 0.5), py = Mathf.floor(h * 0.5 - 26);
            api.rect(px - 1, py - 1, pw + 2, ph + 2, tan);
            api.rect(px, py, pw, ph, deep);
            api.rect(px, py + ph - 2, pw, 2, mid);
            api.textCentered(py + 5, "TIME'S UP!", yellow, 2, dark);
            let line = "SCORE " + this.score.toString() + "   BEST " + this.best.toString();
            api.textCentered(py + 20, line, this.score >= this.best && this.score > 0 ? orange : white, 1, dark);
            if (this.stateT > 0.8 && !api.demo) {
                let blink = Math.floor(api.time * 2.0) % 2 == 0;
                api.textCentered(py + 31, "CLICK TO MOW AGAIN", blink ? cyan : white, 1, dark);
            }
        } else if (this.stateT < 4.0 && !api.demo) {
            api.textCentered(h - 9, "MOW EVERY PATCH OF LONG GRASS", white, 1, dark);
        }
    }
}
