// Gust Regatta: sail a dinghy round a course of buoy gates in a sunlit bay, against the clock and the
// ghost of your best race. The boat steers towards the pointer (on touch: towards the finger while it is
// down, and it keeps its heading when the finger lifts); holding the pointer down turns harder. The sail
// trims itself, but the wind decides the speed: nothing straight into it (the no-go zone), best across it,
// so going upwind means tacking. The wind swings and breathes; dark gust patches drift downwind and speed
// you up. Two laps of five gates; a gate passed out of order does not count. All of the game is here.
import { GameApi, POINTER_DOWN, POINTER_MOVE,
         SFX_SPLASH, SFX_WHOOSH, SFX_NOTE, SFX_BELL, SFX_THUD, SFX_TICK, SFX_CLICK, SFX_WIN, SFX_POP,
         SFX_POWERUP, SFX_BLIP } from "./game_api";

const D2R: f64 = Math.PI / 180;
const R2D: f64 = 180 / Math.PI;

// ---- the course and the bay (the same numbers as models/env/make_bay.py)
const NG: i32 = 5;                       // gates a lap
const LAPS: i32 = 2;
const GX: StaticArray<f64> = [0.0, -24.0, -12.0, 14.0, 26.0];
const GZ: StaticArray<f64> = [20.0, 8.0, -23.0, -22.0, 0.0];
const GATE_HALF: f64 = 3.4;              // buoys 6.8 m apart
const IX: StaticArray<f64> = [-2.0, -30.0, 18.0];       // islets: centre, beach radius (max)
const IZ: StaticArray<f64> = [-4.0, -6.0, 14.0];
const IR: StaticArray<f64> = [7.7, 3.5, 3.9];
const BAY_CX: f64 = 0.0;
const BAY_CZ: f64 = -0.5;
const BAY_AX: f64 = 40.0;
const BAY_AZ: f64 = 31.5;
const MOOR_X: StaticArray<f64> = [-7.0, -1.5, 9.5];
const MOOR_Z: StaticArray<f64> = [-27.4, -26.8, -27.6];

// ---- the boat
const VMAX: f64 = 6.5;                   // m/s at full wind on the best point of sail
const START_X: f64 = 7.0;
const START_Z: f64 = 20.2;
const START_H: f64 = -90.0;              // heading west, across the wind, towards the start gate
const BOAT_SCALE: f64 = 1.35;            // the bake's scale of the hull, the rig and the ghost
const MAST_Y: f64 = 0.5 * BOAT_SCALE;    // the mast's foot in the rig's baked frame (from the hull's origin)
const MAST_Z: f64 = 0.98 * BOAT_SCALE;

const NGUST: i32 = 4;
const GUST_PERIOD: f64 = 22.0;
const GUST_R: f64 = 6.0;
const NSTREAK: i32 = 14;
const NFOAM: i32 = 12;
const GHOST_DT: f64 = 0.1;

const MODE_IDLE: i32 = 0;
const MODE_RACE: i32 = 1;
const MODE_DONE: i32 = 2;

// a pentatonic climb for the gate chimes (semitones over C5)
const CHIME: StaticArray<i32> = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24];

function wrap(a: f64): f64 {
    let r = a;
    while (r > 180) { r -= 360; }
    while (r < -180) { r += 360; }
    return r;
}

function hashf(a: f64, b: f64): f64 {
    let v = Math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - Math.floor(v);
}

function clampf(v: f64, a: f64, b: f64): f64 {
    return v < a ? a : (v > b ? b : v);
}

// the polar: the share of full speed at an angle off the wind (degrees from where it blows from)
function polar(a: f64): f64 {
    if (a < 40) { return 0; }
    if (a < 55) { return 0.78 * (a - 40) / 15; }
    if (a < 95) { return 0.78 + 0.22 * (a - 55) / 40; }
    if (a < 135) { return 1.0 - 0.08 * (a - 95) / 40; }
    return 0.92 - 0.24 * (a - 135) / 45;
}

// the wind: the direction it blows TOWARDS (yaw, 0 = towards +z, i.e. from the north) and its strength,
// a function of the race clock so every race (and the ghost) meets the same wind
function windDir(t: f64): f64 {
    return 24 * Math.sin(0.07 * t + 0.4) + 11 * Math.sin(0.19 * t + 1.3);
}
function windStr(t: f64): f64 {
    return 1 + 0.12 * Math.sin(0.11 * t + 2) + 0.06 * Math.sin(0.31 * t);
}

function bayE(x: f64, z: f64, shrink: f64): f64 {
    let u = Math.abs(x - BAY_CX) / (BAY_AX - shrink), v = Math.abs(z - BAY_CZ) / (BAY_AZ - shrink);
    return u * u * u * u + v * v * v * v;
}

function fmtTime(t: f64): string {
    let ds = <i32>Math.floor(t * 10);
    let m = ds / 600, s = (ds / 10) % 60, d = ds % 10;
    return m.toString() + ":" + (s < 10 ? "0" : "") + s.toString() + "." + d.toString();
}

export class Game {
    // bones
    hull: i32 = -1; rig: i32 = -1; ghost: i32 = -1; marker: i32 = -1; flag: i32 = -1;
    buoys: StaticArray<i32> = new StaticArray<i32>(10);
    gusts: StaticArray<i32> = new StaticArray<i32>(NGUST);
    streaks: StaticArray<i32> = new StaticArray<i32>(NSTREAK);
    foams: StaticArray<i32> = new StaticArray<i32>(NFOAM);
    moors: StaticArray<i32> = new StaticArray<i32>(3);

    // race state
    mode: i32 = MODE_IDLE;
    clock: f64 = 0;          // the wind's clock (from the race start)
    raceTime: f64 = 0;       // the timed part (from crossing the start gate)
    running: bool = false;
    k: i32 = 0;              // gates crossed this race (0: the start is next; LAPS*NG + 1 finishes)
    doneAt: f64 = 0;
    finishTime: f64 = 0;
    newBest: bool = false;
    bestPlay: f64 = 0;
    bestDemo: f64 = 0;
    lastGateTime: f64 = 0;
    msg: string = "";
    msg2: string = "";
    msgUntil: f64 = 0;
    msgColor: i32 = 3;
    wrongUntil: f64 = 0;
    wrongGate: i32 = 0;
    popGate: i32 = -1;
    popAt: f64 = -10;

    // the boat
    x: f64 = START_X; z: f64 = START_Z; h: f64 = START_H; v: f64 = 0; w: f64 = 0;
    hd: f64 = START_H;
    hold: bool = false;
    side: i32 = -1;
    boom: f64 = 0;           // the boom's angle off the centre line (degrees, + to starboard)
    heel: f64 = 0;
    angleOff: f64 = 90;      // the angle off the wind
    gustMul: f64 = 1;
    inGust: bool = false;
    stall: f64 = 0;          // seconds spent slow in the no-go zone
    bumpCool: f64 = 0;

    // camera
    camX: f64 = 4; camZ: f64 = 18;

    // effects
    fx: StaticArray<f64> = new StaticArray<f64>(NFOAM);
    fz: StaticArray<f64> = new StaticArray<f64>(NFOAM);
    fvx: StaticArray<f64> = new StaticArray<f64>(NFOAM);
    fvz: StaticArray<f64> = new StaticArray<f64>(NFOAM);
    fage: StaticArray<f64> = new StaticArray<f64>(NFOAM);
    flife: StaticArray<f64> = new StaticArray<f64>(NFOAM);
    fsize: StaticArray<f64> = new StaticArray<f64>(NFOAM);
    fnext: i32 = 0;
    foamClock: f64 = 0;
    sprayClock: f64 = 0;
    foamSide: f64 = 1;
    moorYaw: StaticArray<f64> = new StaticArray<f64>(3);

    // sound clocks (frame-keyed, never random)
    slapDist: f64 = 0;
    slapCount: i32 = 0;
    flapClock: f64 = 0;

    // the ghost: (x, z, heading, boom) every GHOST_DT of race time
    recPlay: Array<f64> = new Array<f64>();
    recDemo: Array<f64> = new Array<f64>();
    rec: Array<f64> = new Array<f64>();
    recNext: f64 = 0;
    splits: Array<f64> = new Array<f64>();       // race time at each gate (index k)
    splitsPlay: Array<f64> = new Array<f64>();
    splitsDemo: Array<f64> = new Array<f64>();

    // demo pilot
    planAt: f64 = 0;
    corr: f64 = 28;
    missGate: i32 = -1;      // the race index k of a gate the pilot means to sail past
    missSide: f64 = 1;
    missing: bool = false;
    demoRestartAt: f64 = -1;

    // ------------------------------------------------------------------ lifecycle
    start(api: GameApi): void {
        api.playable = true;
        this.hull = api.bone("hull");
        this.rig = api.bone("rig");
        this.ghost = api.bone("ghost");
        this.marker = api.bone("marker");
        this.flag = api.bone("flag");
        for (let i = 0; i < 10; i++) { this.buoys[i] = api.bone("buoy" + i.toString()); }
        for (let i = 0; i < NGUST; i++) { this.gusts[i] = api.bone("gust" + i.toString()); }
        for (let i = 0; i < NSTREAK; i++) { this.streaks[i] = api.bone("streak" + i.toString()); }
        for (let i = 0; i < NFOAM; i++) { this.foams[i] = api.bone("foam" + i.toString()); this.fage[i] = 99; this.flife[i] = 1; }
        this.moors[0] = api.bone("moorA"); this.moors[1] = api.bone("moorB"); this.moors[2] = api.bone("moorC");
        for (let i = 0; i < 3; i++) { this.moorYaw[i] = 180; }
        if (api.demo) {
            this.newRace(api);
        } else {
            this.idle(api);
        }
        this.camX = this.x - 1; this.camZ = this.z - 2;
        this.placeAll(api);
    }

    idle(api: GameApi): void {
        this.mode = MODE_IDLE;
        this.x = START_X; this.z = START_Z; this.h = START_H; this.hd = START_H; this.v = 0; this.w = 0;
        this.clock = 0; this.raceTime = 0; this.running = false; this.k = 0;
        this.msgUntil = 0;
    }

    newRace(api: GameApi): void {
        this.mode = MODE_RACE;
        this.x = START_X; this.z = START_Z; this.h = START_H; this.hd = START_H;
        this.v = 4.2; this.w = 0;
        this.clock = 0; this.raceTime = 0; this.running = false; this.k = 0;
        this.side = -1; this.stall = 0;
        this.msgUntil = 0; this.wrongUntil = 0;
        this.rec = new Array<f64>();
        this.recNext = 0;
        this.planAt = 0; this.missing = false; this.missGate = -1;
        this.demoRestartAt = -1;
        this.camX = clampf(this.x - 2, -33, 33); this.camZ = clampf(this.z - 1, -28, 25);   // a cut, not a long pan
        this.newBest = false;
        if (!api.demo) {
            api.sound(SFX_BLIP, 1.2, 0.5);
        }
    }

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged) {
            this.newRace(api); // demo on, or a visitor took over: a fresh race either way
            this.recDemo = new Array<f64>();
        }
        if (api.demo && this.mode == MODE_DONE && this.demoRestartAt >= 0 && api.time >= this.demoRestartAt) {
            this.newRace(api);
        }
        if (api.demo && this.mode == MODE_IDLE) {
            this.newRace(api);
        }
        if (this.mode != MODE_IDLE) {
            if (api.demo) {
                this.pilot(api);
            } else {
                this.hold = api.pointerDown;
                if (api.pointerDown) {
                    this.steerTo(api, api.pointerX, api.pointerY);
                }
            }
            this.physics(api, dt);
            this.clock += dt;
        } else {
            this.clock += dt;    // the wind and the gusts live on while waiting at the start
        }
        this.effects(api, dt);
        this.camera(api, dt);
        this.placeAll(api);
    }

    // ------------------------------------------------------------------ steering by the pointer
    steerTo(api: GameApi, px: f32, py: f32): void {
        if (!api.pick(px, py, 0)) { return; }
        let dx = <f64>api.hitX - this.x, dz = <f64>api.hitZ - this.z;
        if (Math.sqrt(dx * dx + dz * dz) < 1.2) { return; }
        this.hd = Math.atan2(dx, dz) * R2D;
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.mode == MODE_IDLE || (this.mode == MODE_DONE && api.time - this.doneAt > 0.8)) {
                this.newRace(api);
            }
            this.steerTo(api, x, y);
        } else if (kind == POINTER_MOVE) {
            this.steerTo(api, x, y);   // a mouse steers by hovering; a finger only moves while down
        }
        return true;
    }

    // ------------------------------------------------------------------ the sailing model
    gustAt(g: i32, t: f64, W: f64, S: f64): StaticArray<f64> {
        let out = new StaticArray<f64>(3);
        let tt = t + 50 + <f64>g * GUST_PERIOD / <f64>NGUST;
        let k = Math.floor(tt / GUST_PERIOD), u = tt - k * GUST_PERIOD;
        let sx = -26 + 52 * hashf(k, <f64>g + 1), sz = -24 + 42 * hashf(<f64>g + 3, k + 7);
        let wx = Math.sin(W * D2R), wz = Math.cos(W * D2R);
        let sp = 1.5 * S;
        let x = sx - wx * sp * GUST_PERIOD * 0.45 + wx * sp * u;
        let z = sz - wz * sp * GUST_PERIOD * 0.45 + wz * sp * u;
        let sc = Math.min(1.0, Math.min(u / 2.0, (GUST_PERIOD - u) / 3.0));
        for (let i = 0; i < 3; i++) {
            let d = Math.sqrt((x - IX[i]) * (x - IX[i]) + (z - IZ[i]) * (z - IZ[i])) - IR[i] - 2.6;
            sc = Math.min(sc, d / GUST_R);
        }
        let e = Math.pow(bayE(x, z, 3.0), 0.25);
        sc = Math.min(sc, (1 - e) * 40 / GUST_R);
        out[0] = x; out[1] = z; out[2] = Math.max(sc, 0);
        return out;
    }

    physics(api: GameApi, dt: f64): void {
        let W = windDir(this.clock), S = windStr(this.clock);
        // gusts
        let gm = 1.0;
        for (let g = 0; g < NGUST; g++) {
            let q = this.gustAt(g, this.clock, W, S);
            if (q[2] <= 0.05) { continue; }
            let d = Math.sqrt((this.x - q[0]) * (this.x - q[0]) + (this.z - q[1]) * (this.z - q[1])) / (GUST_R * q[2]);
            if (d < 1) { gm = Math.max(gm, 1 + 0.5 * Math.min(1, (1 - d) / 0.3)); }
        }
        let wasGust = this.inGust;
        this.inGust = gm > 1.15;
        this.gustMul = gm;
        if (this.inGust && !wasGust && !api.demo) {
            api.sound(SFX_WHOOSH, 0.55, 0.45);
            api.sound(SFX_WHOOSH, 0.72, 0.35, 0, 0.16);
        }
        let Se = S * gm;
        // rudder: turn towards the wanted heading at a limited rate, with some inertia
        let err = wrap(this.hd - this.h);
        let mr = Math.min(85, 30 + 14 * this.v);
        if (this.hold) { mr = Math.min(140, mr * 1.7); }
        let tr = clampf(err * 3.0, -mr, mr);
        this.w += (tr - this.w) * Math.min(1, dt * 6);
        this.h = wrap(this.h + this.w * dt);
        // the wind on the boat
        let src = W + 180;
        let rel = wrap(src - this.h);          // < 0: the wind comes over the starboard side
        let a = Math.abs(rel);
        this.angleOff = a;
        let sd: i32 = rel > 0 ? 1 : -1;
        if (sd != this.side) {
            if (this.mode != MODE_IDLE && !api.demo && this.v > 0.3) {
                if (a < 90) {
                    api.soundAt(SFX_WHOOSH, this.x, 0.5, this.z, 1.15, 0.7);
                } else {
                    api.soundAt(SFX_WHOOSH, this.x, 0.5, this.z, 0.8, 0.7);
                    api.soundAt(SFX_THUD, this.x, 0.5, this.z, 1.4, 0.35, 0.12);
                }
            }
            this.side = sd;
        }
        let f = polar(a);
        let tgt = VMAX * Se * f;
        if (this.hold && Math.abs(this.w) > 50) { tgt *= 0.75; }
        let rate = tgt > this.v ? 0.55 : (a < 40 ? 0.9 : 0.35);
        this.v += (tgt - this.v) * Math.min(1, dt * rate);
        if (a < 40 && this.v < 0.8) { this.stall += dt; } else { this.stall = 0; }
        // trim and heel (the sail on the leeward side; luffing in the no-go zone)
        let mag = a < 40 ? a + 9 * Math.sin(Math.floor(api.time * 9) * 2.3) : clampf((a - 25) * 0.55, 6, 82);
        let bt = rel < 0 ? -mag : mag;          // + swings the boom to starboard
        let bd = wrap(bt - this.boom);
        let bmax = 220 * dt;
        this.boom += clampf(bd, -bmax, bmax);
        let heelT = a < 40 ? 0 : 15 * Math.min(1.3, Se) * f * Math.pow(Math.sin(Math.min(a, 120) * D2R), 0.7);
        heelT *= rel < 0 ? -1.0 : 1.0;
        this.heel += (heelT - this.heel) * Math.min(1, dt * 2.5);
        // move: forward, plus a little drift downwind
        let fx = Math.sin(this.h * D2R), fz = Math.cos(this.h * D2R);
        let wx = Math.sin(W * D2R), wz = Math.cos(W * D2R);
        let ox = this.x, oz = this.z;
        this.x += (fx * this.v + wx * 0.15 * S) * dt;
        this.z += (fz * this.v + wz * 0.15 * S) * dt;
        this.collide(api, dt);
        this.gates(api, ox, oz);
        // the clock and the ghost recording
        if (this.mode == MODE_RACE && this.running) {
            this.raceTime += dt;
            while (this.recNext <= this.raceTime) {
                this.rec.push(this.x); this.rec.push(this.z); this.rec.push(this.h); this.rec.push(this.boom);
                this.recNext += GHOST_DT;
            }
        }
        // sounds keyed to the motion (never to api.rand)
        if (!api.demo && this.mode != MODE_IDLE) {
            this.slapDist += this.v * dt;
            if (this.slapDist > 3.4 && this.v > 1.2) {
                this.slapDist = 0;
                this.slapCount++;
                let p = 0.75 + 0.06 * <f64>(this.slapCount % 3) + 0.05 * this.v;
                api.soundAt(SFX_SPLASH, this.x, 0, this.z, p, 0.1 + 0.05 * this.v);
            }
            if (a < 40) {
                this.flapClock -= dt;
                if (this.flapClock <= 0) {
                    this.flapClock = 0.32;
                    api.soundAt(SFX_CLICK, this.x, 2, this.z, 0.55, 0.55);
                    api.soundAt(SFX_TICK, this.x, 2, this.z, 0.7, 0.6, 0.07);
                }
            } else {
                this.flapClock = 0;
            }
        }
    }

    collide(api: GameApi, dt: f64): void {
        this.bumpCool -= dt;
        let hit = false;
        for (let i = 0; i < 3; i++) {
            let R = IR[i] + 1.0;
            let dx = this.x - IX[i], dz = this.z - IZ[i];
            let d = Math.sqrt(dx * dx + dz * dz);
            if (d < R) {
                this.x = IX[i] + dx / d * R; this.z = IZ[i] + dz / d * R;
                hit = true;
            }
        }
        let e = Math.pow(bayE(this.x, this.z, 1.6), 0.25);
        if (e > 1) {
            this.x = BAY_CX + (this.x - BAY_CX) / e; this.z = BAY_CZ + (this.z - BAY_CZ) / e;
            hit = true;
        }
        // the buoys
        for (let g = 0; g < NG; g++) {
            for (let s = -1; s <= 1; s += 2) {
                let bx = this.gateEndX(g, <f64>s), bz = this.gateEndZ(g, <f64>s);
                let dx = this.x - bx, dz = this.z - bz;
                let d = Math.sqrt(dx * dx + dz * dz);
                if (d < 1.3 && d > 0.001) {
                    this.x = bx + dx / d * 1.3; this.z = bz + dz / d * 1.3;
                    if (this.bumpCool <= 0 && this.v > 1) {
                        this.v *= 0.6; this.bumpCool = 0.5;
                        if (!api.demo) { api.soundAt(SFX_POP, bx, 0.5, bz, 0.8, 0.7); }
                        this.popGate = g; this.popAt = api.time;
                    }
                }
            }
        }
        if (hit) {
            if (this.bumpCool <= 0 && this.v > 0.6) {
                if (!api.demo) {
                    api.soundAt(SFX_THUD, this.x, 0, this.z, 0.9, 0.9);
                    api.soundAt(SFX_SPLASH, this.x, 0, this.z, 0.7, 0.5, 0.05);
                }
                this.burst(1.0);
                this.bumpCool = 0.6;
            }
            this.v *= 0.35;
        }
    }

    gateDX(g: i32): f64 {      // a gate faces the leg that leads to it
        let p = (g + NG - 1) % NG;
        let ax = GX[g] - GX[p], az = GZ[g] - GZ[p];
        return ax / Math.sqrt(ax * ax + az * az);
    }
    gateDZ(g: i32): f64 {      // a gate faces the leg that leads to it
        let p = (g + NG - 1) % NG;
        let ax = GX[g] - GX[p], az = GZ[g] - GZ[p];
        return az / Math.sqrt(ax * ax + az * az);
    }
    gateEndX(g: i32, s: f64): f64 { return GX[g] - this.gateDZ(g) * GATE_HALF * s; }
    gateEndZ(g: i32, s: f64): f64 { return GZ[g] + this.gateDX(g) * GATE_HALF * s; }

    nextGate(): i32 {
        return this.k < LAPS * NG ? this.k % NG : 0;
    }

    crosses(ox: f64, oz: f64, g: i32): bool {
        let ax = this.gateEndX(g, -1), az = this.gateEndZ(g, -1);
        let bx = this.gateEndX(g, 1), bz = this.gateEndZ(g, 1);
        let d1 = (bx - ax) * (oz - az) - (bz - az) * (ox - ax);
        let d2 = (bx - ax) * (this.z - az) - (bz - az) * (this.x - ax);
        let d3 = (this.x - ox) * (az - oz) - (this.z - oz) * (ax - ox);
        let d4 = (this.x - ox) * (bz - oz) - (this.z - oz) * (bx - ox);
        return ((d1 > 0) != (d2 > 0)) && ((d3 > 0) != (d4 > 0));
    }

    // crossing the gate's line beyond its buoys (up to 12 m out on either side)
    crossesWide(ox: f64, oz: f64, g: i32): bool {
        let dx = this.gateDX(g), dz = this.gateDZ(g);
        let a0 = (ox - GX[g]) * dx + (oz - GZ[g]) * dz;
        let a1 = (this.x - GX[g]) * dx + (this.z - GZ[g]) * dz;
        if ((a0 > 0) == (a1 > 0)) { return false; }
        let f = a0 / (a0 - a1);
        let px = ox + (this.x - ox) * f, pz = oz + (this.z - oz) * f;
        let lat = Math.abs((px - GX[g]) * (-dz) + (pz - GZ[g]) * dx);
        return lat > GATE_HALF && lat < 12;
    }

    gates(api: GameApi, ox: f64, oz: f64): void {
        if (this.mode != MODE_RACE) { return; }
        let g = this.nextGate();
        if (this.crosses(ox, oz, g)) {
            let lapGate = this.k % NG;
            this.popGate = g; this.popAt = api.time;
            if (this.k == 0) {
                this.running = true;
                this.raceTime = 0;
                this.splits = new Array<f64>();
                this.splits.push(0);
                this.msg = "GO!"; this.msg2 = ""; this.msgColor = 3; this.msgUntil = api.time + 1.6;
                if (!api.demo) {
                    api.noteAt(60 + CHIME[0], this.x, 0, this.z, 0.7, SFX_BELL);
                    api.noteAt(67, this.x, 0, this.z, 0.5, SFX_NOTE, 0.12);
                }
            } else {
                // a split against the ghost
                let delta = 0.0, hasDelta = false;
                let bs = api.demo ? this.splitsDemo : this.splitsPlay;
                if (bs.length > this.k) { delta = this.raceTime - bs[this.k]; hasDelta = true; }
                this.splits.push(this.raceTime);
                if (this.k == LAPS * NG) {
                    this.finish(api);
                } else if (lapGate == 0) {
                    this.msg = "LAP 2"; this.msgColor = 3;
                    if (!api.demo) {
                        api.note(72, 0.6, 0, SFX_NOTE); api.note(76, 0.6, 0, SFX_NOTE, 0.1);
                        api.note(79, 0.6, 0, SFX_NOTE, 0.2); api.note(84, 0.7, 0, SFX_BELL, 0.3);
                    }
                } else {
                    this.msg = "GATE " + lapGate.toString(); this.msgColor = 3;
                    if (!api.demo) {
                        api.noteAt(72 + CHIME[min<i32>(this.k, 10)], this.x, 0, this.z, 0.6, SFX_BELL);
                        api.noteAt(60 + CHIME[min<i32>(this.k, 10)], this.x, 0, this.z, 0.35, SFX_NOTE, 0.04);
                    }
                }
                if (this.mode == MODE_RACE) {
                    this.msg2 = hasDelta ? ((delta <= 0 ? "-" : "+") + fmtTime(Math.abs(delta))) : fmtTime(this.raceTime);
                    this.msgUntil = api.time + 1.8;
                }
            }
            this.k++;
            this.lastGateTime = this.raceTime;
            this.burst(0.6);
            return;
        }
        // passing the next gate outside its buoys: go back
        if (this.k > 0 && this.crossesWide(ox, oz, g)) {
            this.wrongUntil = api.time + 2.6;
            this.wrongGate = g;
            if (!api.demo) {
                api.note(55, 0.5, 0, SFX_NOTE); api.note(50, 0.5, 0, SFX_NOTE, 0.14);
            }
            return;
        }
        // a gate out of order: it does not count, go back
        for (let j = 0; j < NG; j++) {
            if (j == g) { continue; }
            if (this.k == 0) { continue; }
            if (this.crosses(ox, oz, j)) {
                let prev = (g + NG - 1) % NG;
                if (j == prev) { continue; }    // sailing back through the gate just taken is fine
                this.wrongUntil = api.time + 2.6;
                this.wrongGate = g;
                if (!api.demo) {
                    api.note(55, 0.5, 0, SFX_NOTE); api.note(50, 0.5, 0, SFX_NOTE, 0.14);
                }
            }
        }
    }

    finish(api: GameApi): void {
        this.mode = MODE_DONE;
        this.doneAt = api.time;
        this.finishTime = this.raceTime;
        this.running = false;
        let best = api.demo ? this.bestDemo : this.bestPlay;
        this.newBest = best <= 0 || this.raceTime < best;
        if (this.newBest) {
            if (api.demo) { this.bestDemo = this.raceTime; this.recDemo = this.rec; this.splitsDemo = this.splits; }
            else { this.bestPlay = this.raceTime; this.recPlay = this.rec; this.splitsPlay = this.splits; }
        }
        this.msgUntil = 0;
        if (api.demo) {
            this.demoRestartAt = api.time + 2.0;
        } else {
            api.sound(SFX_WIN, 1, 0.8);
            api.note(72, 0.6, 0, SFX_BELL, 0.25); api.note(76, 0.6, 0, SFX_BELL, 0.37);
            api.note(79, 0.6, 0, SFX_BELL, 0.49); api.note(84, 0.8, 0, SFX_BELL, 0.61);
            if (this.newBest) { api.sound(SFX_POWERUP, 1, 0.6, 0, 0.9); }
        }
    }

    // ------------------------------------------------------------------ the demo pilot
    blocked(hd: f64, dist: f64): bool {
        let fx = Math.sin(hd * D2R), fz = Math.cos(hd * D2R);
        let r = 1.5;
        while (r <= dist) {
            let x = this.x + fx * r, z = this.z + fz * r;
            for (let i = 0; i < 3; i++) {
                let dx = x - IX[i], dz = z - IZ[i];
                if (Math.sqrt(dx * dx + dz * dz) < IR[i] + 1.4) { return true; }
            }
            if (bayE(x, z, 1.6) > 0.85) { return true; }
            r += 1.5;
        }
        return false;
    }

    pilot(api: GameApi): void {
        if (api.time < this.planAt) { return; }
        this.planAt = api.time + 0.25;
        let W = windDir(this.clock), S = windStr(this.clock);
        let g = this.nextGate();
        // now and then the pilot means to miss a gate (once it is the target): it sails past outside
        // the buoys, sees the mistake, and comes back
        if (this.missGate != this.k) {
            this.missGate = this.k;
            this.missing = this.mode == MODE_RACE && this.k >= 2 && api.rand() < 0.1;
            this.missSide = api.rand() < 0.5 ? 1 : -1;
        }
        let gx = GX[g], gz = GZ[g], dx = this.gateDX(g), dz = this.gateDZ(g);
        let ddx = gx - this.x, ddz = gz - this.z;
        let d = Math.sqrt(ddx * ddx + ddz * ddz);
        let along = (this.x - gx) * dx + (this.z - gz) * dz;
        let lat = (this.x - gx) * (-dz) + (this.z - gz) * dx;
        let tx = gx, tz = gz;
        if (this.mode == MODE_DONE) {
            tx = GX[1]; tz = GZ[1];
        } else if (this.missing) {
            let off = 4.8 * this.missSide;
            tx = gx - dz * off + dx * 4; tz = gz + dx * off + dz * 4;
            if (along > 2.5) { this.missing = false; }
        } else if (along >= 1.5 && Math.abs(lat) < 10) {
            tx = gx; tz = gz;                       // past it outside the buoys: come back through it
        } else if (along > -2.0 && Math.abs(lat) < 2.6) {
            tx = gx + dx * 6; tz = gz + dz * 6;     // lined up: sail on through
        } else if (along > -1.0 && Math.abs(lat) >= 2.6 && Math.abs(lat) < 9) {
            tx = gx - dx * 7; tz = gz - dz * 7;     // too wide and too close: back off and line up
        }
        // a gust ahead and on the way: go for it
        let gbx = 0.0, gbz = 0.0, gb = false;
        for (let q = 0; q < NGUST; q++) {
            let s = this.gustAt(q, this.clock, W, S);
            if (s[2] < 0.5) { continue; }
            let qx = s[0], qz = s[1];
            let dd = Math.sqrt((qx - this.x) * (qx - this.x) + (qz - this.z) * (qz - this.z));
            if (dd < 14 && dd > GUST_R * s[2] * 0.5) {
                let bt = Math.atan2(tx - this.x, tz - this.z) * R2D;
                let bg = Math.atan2(qx - this.x, qz - this.z) * R2D;
                let dT = Math.sqrt((tx - qx) * (tx - qx) + (tz - qz) * (tz - qz));
                let dB = Math.sqrt((tx - this.x) * (tx - this.x) + (tz - this.z) * (tz - this.z));
                if (Math.abs(wrap(bg - bt)) < 35 && dT < dB) { gbx = qx; gbz = qz; gb = true; }
            }
        }
        if (gb && d > 10) { tx = gbx; tz = gbz; }
        // round an islet in the way
        for (let i = 0; i < 3; i++) {
            let vx = tx - this.x, vz = tz - this.z;
            let L = Math.sqrt(vx * vx + vz * vz);
            if (L < 0.001) { continue; }
            let ux = vx / L, uz = vz / L;
            let px = IX[i] - this.x, pz = IZ[i] - this.z;
            let proj = px * ux + pz * uz;
            if (proj > 0 && proj < L) {
                let perp = -uz * px + ux * pz;
                let R = IR[i] + 3.2;
                if (Math.abs(perp) < R) {
                    let sg = perp > 0 ? 1.0 : -1.0;
                    tx = IX[i] + uz * sg * (R + 1.5); tz = IZ[i] - ux * sg * (R + 1.5);
                }
            }
        }
        let bear = Math.atan2(tx - this.x, tz - this.z) * R2D;
        let src = W + 180;
        let rel = wrap(bear - src);
        const CH: f64 = 50;
        let hd: f64;
        if (Math.abs(rel) < CH) {
            let cur: f64 = wrap(this.h - src) > 0 ? 1 : -1;
            if (rel * cur < 0 && Math.abs(rel) > this.corr) {
                cur = -cur; this.corr = 20 + 16 * api.rand();
            }
            hd = src + cur * CH;
            if (this.blocked(hd, 9) && !this.blocked(src - cur * CH, 9)) {
                hd = src - cur * CH; this.corr = 20 + 16 * api.rand();
            }
        } else {
            hd = bear;
            if (this.blocked(hd, 9)) {
                let found = false;
                for (let kk = 1; kk < 10 && !found; kk++) {
                    for (let sg = -1; sg <= 1; sg += 2) {
                        let c = bear + <f64>(sg * kk * 12);
                        if (Math.abs(wrap(c - src)) >= CH && !this.blocked(c, 9)) { hd = c; found = true; break; }
                    }
                }
            }
        }
        hd += (api.rand() - 0.5) * 8;
        this.hd = wrap(hd);
        this.hold = Math.abs(wrap(this.hd - this.h)) > 60;
    }

    // ------------------------------------------------------------------ effects, camera, bones
    burst(power: f64): void {
        let fx = Math.sin(this.h * D2R), fz = Math.cos(this.h * D2R);
        for (let i = 0; i < 5; i++) {
            let a = <f64>i * 1.2566 + this.h * D2R;
            this.spawnFoam(this.x + fx * 1.6 + Math.cos(a) * 0.6, this.z + fz * 1.6 + Math.sin(a) * 0.6,
                           Math.cos(a) * 1.4 * power, Math.sin(a) * 1.4 * power, 0.9, 0.9 * power + 0.3);
        }
    }

    spawnFoam(x: f64, z: f64, vx: f64, vz: f64, life: f64, size: f64): void {
        let i = this.fnext;
        this.fnext = (this.fnext + 1) % NFOAM;
        this.fx[i] = x; this.fz[i] = z; this.fvx[i] = vx; this.fvz[i] = vz;
        this.fage[i] = 0; this.flife[i] = life; this.fsize[i] = size;
    }

    effects(api: GameApi, dt: f64): void {
        let fx = Math.sin(this.h * D2R), fz = Math.cos(this.h * D2R);
        let sx = -fz, sz = fx;   // to port... (a sideways unit vector)
        if (this.mode != MODE_IDLE && this.v > 1.0) {
            this.foamClock -= dt;
            if (this.foamClock <= 0) {
                this.foamClock = 0.13;
                this.foamSide = -this.foamSide;
                let s = this.foamSide;
                let k = Math.min(1, this.v / 4.5);
                this.spawnFoam(this.x - fx * 2.5 + sx * 0.5 * s, this.z - fz * 2.5 + sz * 0.5 * s,
                               sx * 0.8 * s * k, sz * 0.8 * s * k, 1.1, 0.3 + 0.35 * k);
            }
            if (this.v > 4.2) {
                this.sprayClock -= dt;
                if (this.sprayClock <= 0) {
                    this.sprayClock = 0.27;
                    let s = this.foamSide;
                    this.spawnFoam(this.x + fx * 1.7 + sx * 0.7 * s, this.z + fz * 1.7 + sz * 0.7 * s,
                                   sx * 1.6 * s, sz * 1.6 * s, 0.6, 0.4);
                }
            }
        }
        for (let i = 0; i < NFOAM; i++) {
            this.fage[i] += dt;
            this.fx[i] += this.fvx[i] * dt; this.fz[i] += this.fvz[i] * dt;
            this.fvx[i] *= 1 - Math.min(1, dt * 1.5); this.fvz[i] *= 1 - Math.min(1, dt * 1.5);
        }
    }

    camera(api: GameApi, dt: f64): void {
        let fx = Math.sin(this.h * D2R), fz = Math.cos(this.h * D2R);
        let tx = this.x + fx * this.v * 1.1, tz = this.z + fz * this.v * 1.1 - 1.0;
        let k = Math.min(1, dt * 2.2);
        this.camX += (tx - this.camX) * k;
        this.camZ += (tz - this.camZ) * k;
        this.camX = clampf(this.camX, -33, 33);
        this.camZ = clampf(this.camZ, -28, 25);
        api.useTarget = true;
        api.targetX = this.camX; api.targetY = 0; api.targetZ = this.camZ;
    }

    // writes a bone's matrix: rest point p0 goes to (px, py, pz), rotated by r (row-major 3x3)
    setBone(api: GameApi, b: i32, r: StaticArray<f64>, px: f64, py: f64, pz: f64): void {
        if (b <= 0) { return; }
        let x0 = <f64>api.restX[b], y0 = <f64>api.restY[b], z0 = <f64>api.restZ[b];
        let m = b * 12;
        for (let row = 0; row < 3; row++) {
            let a0 = r[row * 3], a1 = r[row * 3 + 1], a2 = r[row * 3 + 2];
            api.mats[m + row * 4] = <f32>a0; api.mats[m + row * 4 + 1] = <f32>a1; api.mats[m + row * 4 + 2] = <f32>a2;
            let t = (row == 0 ? px : (row == 1 ? py : pz)) - (a0 * x0 + a1 * y0 + a2 * z0);
            api.mats[m + row * 4 + 3] = <f32>t;
        }
        api.dirty[b] = true;
        api.anyDirty = true;
    }

    // R = Ry(yaw) * Rx(pitch) * Rz(roll)
    rot(yaw: f64, pitch: f64, roll: f64): StaticArray<f64> {
        let cy = Math.cos(yaw * D2R), sy = Math.sin(yaw * D2R);
        let cp = Math.cos(pitch * D2R), sp = Math.sin(pitch * D2R);
        let cr = Math.cos(roll * D2R), sr = Math.sin(roll * D2R);
        let r = new StaticArray<f64>(9);
        r[0] = cy * cr + sy * sp * sr; r[1] = -cy * sr + sy * sp * cr; r[2] = sy * cp;
        r[3] = cp * sr;                r[4] = cp * cr;                 r[5] = -sp;
        r[6] = -sy * cr + cy * sp * sr; r[7] = sy * sr + cy * sp * cr; r[8] = cy * cp;
        return r;
    }

    mul(a: StaticArray<f64>, b: StaticArray<f64>): StaticArray<f64> {
        let r = new StaticArray<f64>(9);
        for (let i = 0; i < 3; i++) {
            for (let j = 0; j < 3; j++) {
                r[i * 3 + j] = a[i * 3] * b[j] + a[i * 3 + 1] * b[3 + j] + a[i * 3 + 2] * b[6 + j];
            }
        }
        return r;
    }

    // the boat: the hull at (x, bob, z) turned, pitched and heeled; the rig on the mast's foot, swung by
    // the boom angle about the mast, heeling with the hull
    placeBoat(api: GameApi, hull: i32, rig: i32, x: f64, z: f64, h: f64, boom: f64, heel: f64, t: f64): void {
        let bob = 0.035 * Math.sin(t * 2.3 + x * 0.3);
        let pitch = 1.6 * Math.sin(Math.floor(t * 10) / 10 * 2.9 + z * 0.2);
        let R = this.rot(h, pitch, heel);
        this.setBone(api, hull, R, x, bob, z);
        if (rig > 0) {
            // world = P + R * (M + Rb * (p - rest - M)), M = the mast foot from the rest pivot
            let Rb = this.rot(boom, 0, 0);
            let Rr = this.mul(R, Rb);
            let mx = R[1] * MAST_Y + R[2] * MAST_Z, my = R[4] * MAST_Y + R[5] * MAST_Z, mz = R[7] * MAST_Y + R[8] * MAST_Z;
            // setBone maps the rest pivot to q: q = P + R M - Rr M
            let qx = x + mx - (Rr[1] * MAST_Y + Rr[2] * MAST_Z);
            let qy = bob + my - (Rr[4] * MAST_Y + Rr[5] * MAST_Z);
            let qz = z + mz - (Rr[7] * MAST_Y + Rr[8] * MAST_Z);
            this.setBone(api, rig, Rr, qx, qy, qz);
        }
    }

    placeAll(api: GameApi): void {
        let t = api.time;
        let W = windDir(this.clock), S = windStr(this.clock);
        this.placeBoat(api, this.hull, this.rig, this.x, this.z, this.h, this.boom, this.heel, t);
        // the ghost
        let rec = api.demo ? this.recDemo : this.recPlay;
        let n = rec.length / 4;
        if (this.mode == MODE_RACE && this.running && n > 1 && this.raceTime / GHOST_DT < <f64>(n - 1)) {
            let u = this.raceTime / GHOST_DT;
            let i = <i32>Math.floor(u), f = u - <f64>i;
            let gx = rec[i * 4] + (rec[i * 4 + 4] - rec[i * 4]) * f;
            let gz = rec[i * 4 + 1] + (rec[i * 4 + 5] - rec[i * 4 + 1]) * f;
            let gh = rec[i * 4 + 2] + wrap(rec[i * 4 + 6] - rec[i * 4 + 2]) * f;
            this.placeBoat(api, this.ghost, -1, gx, gz, gh, 0, 0, t + 1.3);
        } else {
            api.hide(this.ghost);
        }
        // buoys, with a pop when a gate is taken (or bumped)
        let ng = this.nextGate();
        for (let g = 0; g < NG; g++) {
            for (let s = 0; s < 2; s++) {
                let b = this.buoys[g * 2 + s];
                let sg: f64 = s == 0 ? -1 : 1;
                let bx = this.gateEndX(g, sg), bz = this.gateEndZ(g, sg);
                let ph = <f64>(g * 2 + s) * 1.7;
                let y = 0.05 * Math.sin(t * 2.0 + ph) - 0.05;
                let roll = 4 * Math.sin(Math.floor(t * 8) / 8 * 1.6 + ph);
                let pop = t - this.popAt;
                if (g == this.popGate && pop < 0.45) {
                    let q = Math.floor(pop * 12) / 12;
                    let sy = 1 + 0.35 * Math.sin(q / 0.45 * Math.PI) ;
                    api.placeScaled(b, bx, y, bz, ph * 20, 1 / Math.sqrt(sy), sy, 1 / Math.sqrt(sy));
                } else {
                    api.place(b, bx, y, bz, ph * 20, 0, roll);
                }
            }
        }
        // the marker over the next gate
        if (this.mode == MODE_DONE) {
            api.hide(this.marker);
        } else {
            let my = 2.5 + 0.25 * Math.sin(Math.floor(t * 8) / 8 * 3.1);
            api.place(this.marker, GX[ng], my, GZ[ng], Math.floor(t * 6) * 22.5);
        }
        // gusts
        for (let g = 0; g < NGUST; g++) {
            let q = this.gustAt(g, this.clock, W, S);
            if (q[2] < 0.06) {
                api.hide(this.gusts[g]);
            } else {
                let sc = Math.floor(q[2] * 8) / 8 + 0.06;
                api.place(this.gusts[g], q[0], 0, q[1], <f64>g * 67 + this.clock * 2, 0, 0, Math.min(1, sc));
            }
        }
        // wind streaks: wavelets drifting downwind round the camera, crests across the wind
        let wx = Math.sin(W * D2R), wz = Math.cos(W * D2R);
        for (let i = 0; i < NSTREAK; i++) {
            let T = 3.2;
            let tt = this.clock + <f64>i * 0.731;
            let c = Math.floor(tt / T), u = tt - c * T;
            let sp = 2.2 * S;
            let x0 = this.camX + hashf(<f64>i + 0.5, c) * 34 - 17;
            let z0 = this.camZ + hashf(c + 3.1, <f64>i * 1.7) * 26 - 13;
            let x = x0 + wx * sp * (u - T / 2), z = z0 + wz * sp * (u - T / 2);
            let vis = u > 0.25 && u < T - 0.3 && bayE(x, z, 4.5) < 1;
            for (let j = 0; j < 3 && vis; j++) {
                let dx = x - IX[j], dz = z - IZ[j];
                if (Math.sqrt(dx * dx + dz * dz) < IR[j] + 3.2) { vis = false; }
            }
            if (!vis) {
                api.hide(this.streaks[i]);
            } else {
                let grow = Math.min(1, Math.min(u / 0.8, (T - u) / 0.8));
                let sx = 0.5 + 0.5 * Math.floor(grow * 3) / 3;
                api.placeScaled(this.streaks[i], x, 0.1, z, W + 6 * Math.sin(<f64>i), sx * (0.85 + 0.25 * S), 1, 1);
            }
        }
        // foam
        for (let i = 0; i < NFOAM; i++) {
            let b = this.foams[i];
            let a = this.fage[i] / this.flife[i];
            if (a >= 1) {
                api.hide(b);
            } else {
                let s = this.fsize[i] * (1 - Math.floor(a * 4) / 4 * 0.8);
                api.place(b, this.fx[i], 0.08, this.fz[i], <f64>i * 47, 0, 0, s);
            }
        }
        // the lighthouse's windsock streams downwind, droops when the wind eases, and flutters
        let flutter = 8 * Math.sin(Math.floor(t * 8) * 1.7) * (0.6 + 0.4 * S);
        let droop = clampf((1.2 - S) * 70, 0, 35) + 3 * Math.sin(Math.floor(t * 8) * 2.9);
        api.place(this.flag, <f64>api.restX[this.flag], <f64>api.restY[this.flag], <f64>api.restZ[this.flag],
                  W + flutter, droop, 0);
        // moored dinghies swing their bows into the wind
        for (let i = 0; i < 3; i++) {
            let want = W + 180 + <f64>(i - 1) * 9;
            this.moorYaw[i] += wrap(want - this.moorYaw[i]) * Math.min(1, api.dt * 0.5);
            let ph = <f64>i * 2.1;
            api.place(this.moors[i], MOOR_X[i], 0.03 * Math.sin(t * 1.9 + ph), MOOR_Z[i], this.moorYaw[i],
                      1.2 * Math.sin(t * 1.3 + ph), 2.5 * Math.sin(Math.floor(t * 8) / 8 * 1.1 + ph));
        }
    }

    // ------------------------------------------------------------------ the HUD
    hud(api: GameApi): void {
        let ink = api.paletteColor(19);      // #1f102a
        let white = api.paletteColor(24);
        let pale = api.paletteColor(23);
        let yellow = api.paletteColor(3);
        let pink = api.paletteColor(16);
        let red = api.paletteColor(5);
        let green = api.paletteColor(2);
        let cyan = api.paletteColor(25);
        let W = windDir(this.clock), S = windStr(this.clock);
        let hw = <f32>api.hudW, hh = <f32>api.hudH;
        let t = api.time;

        // the next gate: a dashed line between its buoys, or an arrow at the edge pointing to it
        if (this.mode == MODE_RACE) {
            let g = this.nextGate();
            api.project(<f32>this.gateEndX(g, -1), 0.6, <f32>this.gateEndZ(g, -1));
            let ax = api.screenX, ay = api.screenY;
            api.project(<f32>this.gateEndX(g, 1), 0.6, <f32>this.gateEndZ(g, 1));
            let bx = api.screenX, by = api.screenY;
            api.project(<f32>GX[g], 0.6, <f32>GZ[g]);
            let cx = api.screenX, cy = api.screenY;
            let onScreen = cx > 4 && cx < hw - 4 && cy > 4 && cy < hh - 4;
            if (onScreen) {
                let steps = 14;
                for (let i = 0; i < steps; i += 2) {
                    let u0 = <f32>i / <f32>steps, u1 = <f32>(i + 1) / <f32>steps;
                    api.line(ax + (bx - ax) * u0, ay + (by - ay) * u0, ax + (bx - ax) * u1, ay + (by - ay) * u1,
                             (Math.floor(t * 4) % 2 == 0) ? yellow : white);
                }
            } else {
                let mx = hw * 0.5, my = hh * 0.5;
                let dx = cx - mx, dy = cy - my;
                let sx = (hw * 0.5 - 10) / Mathf.max(Mathf.abs(dx), 0.001);
                let sy = (hh * 0.5 - 10) / Mathf.max(Mathf.abs(dy), 0.001);
                let s = Mathf.min(sx, sy);
                let px = mx + dx * s, py = my + dy * s;
                let l = Mathf.sqrt(dx * dx + dy * dy);
                let ux = dx / l, uy = dy / l;
                let tipx = px + ux * 5, tipy = py + uy * 5;
                for (let k = 0; k < 2; k++) {
                    let c = k == 0 ? ink : yellow;
                    let o = <f32>(k == 0 ? 1 : 0);
                    api.line(px + o - ux * 3, py + o - uy * 3, tipx + o, tipy + o, c);
                    api.line(tipx + o, tipy + o, tipx + o - ux * 4 + uy * 3, tipy + o - uy * 4 - ux * 3, c);
                    api.line(tipx + o, tipy + o, tipx + o - ux * 4 - uy * 3, tipy + o - uy * 4 + ux * 3, c);
                }
                let label = (g == 0 && this.k > 0) ? "F" : g.toString();
                if (g == 0 && this.k == 0) { label = "S"; }
                api.text(px - ux * 9 - 1, py - uy * 9 - 2, label, yellow, 1, ink);
            }
        }

        // no-go warning over the boat
        if (this.mode != MODE_IDLE && this.angleOff < 40 && Math.floor(t * 3) % 2 == 0) {
            api.project(<f32>this.x, 3.6, <f32>this.z);
            let s = "NO GO";
            api.text(api.screenX - api.textWidth(s, 1) * 0.5, api.screenY - 8, s, pink, 1, ink);
        }

        // top left: lap, gate, time, best
        if (this.mode != MODE_IDLE) {
            let lap = min<i32>(max<i32>(this.k - 1, 0) / NG + 1, LAPS);
            let ng = this.nextGate();
            if (this.k == 0) {
                api.text(3, 3, "SAIL THROUGH THE START", pale, 1, ink);
            } else if (this.mode == MODE_RACE) {
                api.text(3, 3, "LAP " + lap.toString() + "/" + LAPS.toString() + "  NEXT: " + (ng == 0 ? "LINE" : "GATE " + ng.toString()),
                         pale, 1, ink);
            }
            api.text(3, 10, fmtTime(this.mode == MODE_DONE ? this.finishTime : this.raceTime), white, 2, ink);
            let best = api.demo ? this.bestDemo : this.bestPlay;
            if (best > 0) {
                api.text(3, 23, "BEST " + fmtTime(best), cyan, 1, ink);
            }
        }

        // top right: the wind dial (an arrow blowing the way the wind goes, longer when stronger)
        let dcx: f32 = hw - 15, dcy: f32 = 15;
        for (let i = 0; i < 16; i++) {
            let a = <f32>i * 0.3927;
            api.rect(Mathf.round(dcx + Mathf.cos(a) * 11), Mathf.round(dcy + Mathf.sin(a) * 11), 1, 1, i % 4 == 0 ? white : pale);
        }
        let wl = <f32>(5.0 + 4.0 * (S - 0.8) / 0.4) * <f32>(this.inGust ? 1.25 : 1.0);
        let wdx = <f32>Math.sin(W * D2R), wdy = <f32>Math.cos(W * D2R);
        let col = this.inGust ? pink : white;
        for (let k = 0; k < 2; k++) {
            let c = k == 0 ? ink : col;
            let o = <f32>(k == 0 ? 1 : 0);
            let x0 = dcx - wdx * wl + o, y0 = dcy - wdy * wl + o, x1 = dcx + wdx * wl + o, y1 = dcy + wdy * wl + o;
            api.line(x0, y0, x1, y1, c);
            api.line(x1, y1, x1 - wdx * 3 + wdy * 3, y1 - wdy * 3 - wdx * 3, c);
            api.line(x1, y1, x1 - wdx * 3 - wdy * 3, y1 - wdy * 3 + wdx * 3, c);
        }
        let lbl = this.inGust ? "GUST!" : "WIND";
        api.text(dcx - api.textWidth(lbl, 1) * 0.5, dcy + 14, lbl, this.inGust ? pink : pale, 1, ink);
        let kn = Math.round(this.v * 19.4) / 10;
        let ks = kn.toString();
        if (ks.indexOf(".") < 0) { ks += ".0"; }
        ks += " KN";
        api.text(hw - 3 - api.textWidth(ks, 1), dcy + 21, ks, white, 1, ink);

        // messages
        if (t < this.msgUntil && this.mode == MODE_RACE) {
            api.textCentered(30, this.msg, yellow, 2, ink);
            if (this.msg2.length > 0) {
                let c = this.msg2.charAt(0) == "-" ? green : (this.msg2.charAt(0) == "+" ? red : white);
                api.textCentered(43, this.msg2, c, 1, ink);
            }
        }
        if (t < this.wrongUntil && this.mode == MODE_RACE) {
            let s = this.wrongGate == 0 ? "MISSED THE LINE: GO BACK" : "MISSED GATE " + this.wrongGate.toString() + ": GO BACK";
            api.textCentered(hh - 26, s, pink, 1, ink);
        }
        if (this.mode == MODE_RACE && this.stall > 1.5) {
            api.textCentered(hh - 18, "IN IRONS: TURN AWAY FROM THE WIND", pink, 1, ink);
        }

        if (this.mode == MODE_IDLE) {
            api.textCentered(hh - 31, "STEER: POINT OR DRAG.  HOLD: HARD TURN", white, 1, ink);
            api.textCentered(hh - 23, "NO SAILING STRAIGHT INTO THE WIND: TACK!", pale, 1, ink);
            if (Math.floor(t * 2) % 2 == 0) {
                api.textCentered(hh - 13, "CLICK TO START", yellow, 2, ink);
            }
            api.textCentered(30, "GUST REGATTA", white, 2, ink);
            api.textCentered(43, "2 LAPS: 4 GATES AND THE LINE", pale, 1, ink);
        } else if (this.mode == MODE_DONE) {
            api.textCentered(32, "FINISH " + fmtTime(this.finishTime), yellow, 2, ink);
            if (this.newBest) {
                api.textCentered(46, "NEW BEST!", green, 1, ink);
            } else {
                let best = api.demo ? this.bestDemo : this.bestPlay;
                api.textCentered(46, "BEST " + fmtTime(best), cyan, 1, ink);
            }
            if (!api.demo && t - this.doneAt > 0.8) {
                api.textCentered(hh - 13, "CLICK TO RACE AGAIN", white, 1, ink);
            }
        }
    }
}
