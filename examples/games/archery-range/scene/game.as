// Archery Range: hold to draw the bow, release to shoot at straw targets sliding across a meadow on
// three lanes. The pointer aims (the arrow flies to where it points, if the draw is full); a short
// draw drops short, a draw held too long trembles; the wind flag shows the drift for this arrow.
// Rings score 10 / 8 / 6 / 4 / 2, times the lane (near x1, middle x2, far x3). Ten arrows a run.
//
// Everything is in this file (references/games.md, "The game hook"); the bones come from
// scene.bake.json: archer, bow, flag, target0..3, arrow0..10, chip0..7.
import { GameApi, POINTER_DOWN, POINTER_UP, SFX_BLIP, SFX_CLICK, SFX_TICK, SFX_WHOOSH, SFX_THUD, SFX_COIN,
    SFX_NOTE, SFX_BELL, SFX_WIN, SFX_LOSE } from "./game_api";

const LANE_Z: StaticArray<f64> = [-3.0, -6.5, -10.0];
const LANE_SPEED: StaticArray<f64> = [1.35, 1.85, 2.35];
const RING_PTS: StaticArray<i32> = [10, 8, 6, 4, 2];
// sound: the chime of each ring (a major pentatonic, the bullseye on top), MIDI
const RING_NOTE: StaticArray<f64> = [79, 76, 74, 72, 69];
const PENTA: StaticArray<f64> = [0, 2, 4, 7, 9, 12, 14, 16];
const NT: i32 = 6;            // targets in the pool (up to two a lane)
const NA: i32 = 11;           // arrows in the pool (ten a run, one spare for the reload slide)
const NC: i32 = 8;            // straw chips
const NP: i32 = 6;            // score popups
const ARROWS: i32 = 10;
const TS: f64 = 1.25;         // targets are baked at 1.25 x the sheet
const FACE_Y: f64 = 1.08 * TS;  // boss centre height
const FACE_DZ: f64 = 0.17;    // the painted face, in front of the target's pivot
const FACE_R: f64 = 0.6 * TS; // rings: five of FACE_R / 5
const AX: f64 = 0.0;          // the archer's feet
const AZ: f64 = 2.6;
const ASCALE: f64 = 1.3;
const BOW_LX: f64 = -0.34 * ASCALE;  // the bow's grip in the archer's frame (facing +Z)
const BOW_LY: f64 = 1.32 * ASCALE;
const BOW_LZ: f64 = 0.72 * ASCALE;
const GRAV: f64 = 9.8;
const FLAG_X: f64 = -5.6;
const FLAG_Y: f64 = 3.05;
const FLAG_Z: f64 = 1.4;

// arrow states
const A_IDLE: i32 = 0;
const A_NOCKED: i32 = 1;
const A_FLYING: i32 = 2;
const A_TARGET: i32 = 3;
const A_GROUND: i32 = 4;

// run modes
const M_READY: i32 = 0;      // the world plays; the first press starts a run
const M_PLAY: i32 = 1;
const M_OVER: i32 = 2;

function clamp(v: f64, a: f64, b: f64): f64 { return v < a ? a : (v > b ? b : v); }
function deg(r: f64): f64 { return r * 180.0 / Math.PI; }
function rad(d: f64): f64 { return d * Math.PI / 180.0; }

export class Game {
    // bones
    bArcher: i32 = -1; bBow: i32 = -1; bFlag: i32 = -1;
    bTarget: StaticArray<i32> = new StaticArray<i32>(NT);
    bArrow: StaticArray<i32> = new StaticArray<i32>(NA);
    bChip: StaticArray<i32> = new StaticArray<i32>(NC);

    // run
    mode: i32 = M_READY;
    score: i32 = 0;
    best: i32 = 0;
    left: i32 = ARROWS;       // arrows not yet shot
    shot: i32 = 0;            // arrows shot this run
    overT: f64 = 0;
    wasDemo: bool = false;
    hits: i32 = 0;

    // the bow
    drawing: bool = false;
    drawT: f64 = 0;
    releaseT: f64 = 9;        // seconds since the last release (the recoil)
    nockT: f64 = 9;           // seconds since an arrow was nocked (it slides in)
    nocked: i32 = -1;         // the arrow on the string
    aimX: f64 = 0; aimZ: f64 = -6.5; aimY: f64 = FACE_Y;
    aimValid: bool = false;
    yawNow: f64 = 180;

    // wind (m/s sideways, + to the right), and the flag's smoothed heading
    wind: f64 = 0;
    flagYaw: f64 = 0;
    flagLift: f64 = 0;

    // targets
    tOn: StaticArray<bool> = new StaticArray<bool>(NT);
    tLane: StaticArray<i32> = new StaticArray<i32>(NT);
    tX: StaticArray<f64> = new StaticArray<f64>(NT);
    tDir: StaticArray<f64> = new StaticArray<f64>(NT);
    tHit: StaticArray<f64> = new StaticArray<f64>(NT);   // seconds since hit (the wobble)
    laneWait: StaticArray<f64> = new StaticArray<f64>(3);
    laneLast: StaticArray<i32> = [-1, -1, -1];   // the newest target on each lane
    laneDir: StaticArray<f64> = [1, -1, 1];

    // arrows
    aState: StaticArray<i32> = new StaticArray<i32>(NA);
    aX: StaticArray<f64> = new StaticArray<f64>(NA);
    aY: StaticArray<f64> = new StaticArray<f64>(NA);
    aZ: StaticArray<f64> = new StaticArray<f64>(NA);
    aVX: StaticArray<f64> = new StaticArray<f64>(NA);
    aVY: StaticArray<f64> = new StaticArray<f64>(NA);
    aVZ: StaticArray<f64> = new StaticArray<f64>(NA);
    aYaw: StaticArray<f64> = new StaticArray<f64>(NA);
    aPitch: StaticArray<f64> = new StaticArray<f64>(NA);
    aWind: StaticArray<f64> = new StaticArray<f64>(NA);
    aTgt: StaticArray<i32> = new StaticArray<i32>(NA);
    aOff: StaticArray<f64> = new StaticArray<f64>(NA);   // x offset from its target's pivot
    aAge: StaticArray<f64> = new StaticArray<f64>(NA);
    nextArrow: i32 = 0;

    // chips
    cLife: StaticArray<f64> = new StaticArray<f64>(NC);
    cX: StaticArray<f64> = new StaticArray<f64>(NC);
    cY: StaticArray<f64> = new StaticArray<f64>(NC);
    cZ: StaticArray<f64> = new StaticArray<f64>(NC);
    cVX: StaticArray<f64> = new StaticArray<f64>(NC);
    cVY: StaticArray<f64> = new StaticArray<f64>(NC);
    cVZ: StaticArray<f64> = new StaticArray<f64>(NC);
    cSpin: StaticArray<f64> = new StaticArray<f64>(NC);
    nextChip: i32 = 0;

    // popups (world point, text, colour kind, age)
    pOn: StaticArray<bool> = new StaticArray<bool>(NP);
    pX: StaticArray<f64> = new StaticArray<f64>(NP);
    pY: StaticArray<f64> = new StaticArray<f64>(NP);
    pZ: StaticArray<f64> = new StaticArray<f64>(NP);
    pAge: StaticArray<f64> = new StaticArray<f64>(NP);
    pKind: StaticArray<i32> = new StaticArray<i32>(NP);
    pText: Array<string> = ["", "", "", "", "", ""];
    nextPop: i32 = 0;

    // sound (never decided by a random draw)
    streak: i32 = 0;          // arrows on target in a row: the chime climbs the scale
    tune: StaticArray<f64> = new StaticArray<f64>(8);
    tuneN: i32 = 0;
    tuneI: i32 = 0;
    tuneAt: i32 = 0;
    tuneStep: i32 = 6;
    tuneKind: i32 = SFX_NOTE;

    // demo player
    dWait: f64 = 0.1;
    dHold: f64 = 0.7;
    dTgt: i32 = -1;
    dErrX: f64 = 0; dErrZ: f64 = 0;
    dWindK: f64 = 1;

    start(api: GameApi): void {
        api.playable = true;
        this.bArcher = api.bone("archer");
        this.bBow = api.bone("bow");
        this.bFlag = api.bone("flag");
        for (let i = 0; i < NT; i++) this.bTarget[i] = api.bone("target" + i.toString());
        for (let i = 0; i < NA; i++) this.bArrow[i] = api.bone("arrow" + i.toString());
        for (let i = 0; i < NC; i++) this.bChip[i] = api.bone("chip" + i.toString());
        for (let i = 0; i < NC; i++) api.hide(this.bChip[i]);
        // three targets already crossing when the world appears
        for (let l = 0; l < 3; l++) {
            this.spawn(api, l, api.range(-5.5, 5.5));
        }
        this.wasDemo = api.demo;
        this.newRun(api);
        this.mode = api.demo ? M_PLAY : M_READY;
    }

    // ------------------------------------------------------------------ run

    newRun(api: GameApi): void {
        this.streak = 0;
        this.score = 0;
        this.left = ARROWS;
        this.shot = 0;
        this.hits = 0;
        this.drawing = false;
        this.drawT = 0;
        this.releaseT = 9;
        for (let i = 0; i < NA; i++) {
            this.aState[i] = A_IDLE;
            api.hide(this.bArrow[i]);
        }
        this.nextArrow = 0;
        this.nocked = -1;
        this.newWind(api);
        this.nock();
        this.dWait = 0.1;
    }

    newWind(api: GameApi): void {
        let w = api.range(-2.6, 2.6);
        if (Math.abs(w) < 0.4) w = w < 0 ? -0.4 : 0.4;
        this.wind = Math.round(w * 2) / 2;
    }

    nock(): void {
        // (the slide-in restarts with nockT)
        if (this.left <= 0) { this.nocked = -1; return; }
        let i = this.nextArrow;
        this.nextArrow = (this.nextArrow + 1) % NA;
        this.aState[i] = A_NOCKED;
        this.nocked = i;
        this.nockT = 0;
    }

    // ------------------------------------------------------------------ targets

    spawn(api: GameApi, lane: i32, x0: f64): void {
        let t = -1;
        for (let i = 0; i < NT; i++) {
            if (!this.tOn[i]) { t = i; break; }
        }
        if (t < 0) return;
        // a lane keeps its direction while a target is on it; an empty lane may turn round
        let last = this.laneLast[lane];
        if (last < 0 || !this.tOn[last]) {
            if (api.rand() < 0.35) this.laneDir[lane] = -this.laneDir[lane];
        }
        let dir = this.laneDir[lane];
        this.tOn[t] = true;
        this.tLane[t] = lane;
        this.tDir[t] = dir;
        this.tX[t] = x0 == 99 ? -dir * 10.2 : x0;
        this.tHit[t] = 9;
        this.laneLast[lane] = t;
        this.laneWait[lane] = api.range(0.6, 2.2);
    }

    tSpeed(t: i32): f64 {
        return LANE_SPEED[this.tLane[t]] * (1 + 0.035 * <f64>this.shot);
    }

    updateTargets(api: GameApi, dt: f64): void {
        // a lane sends its next target once the last one is past the middle (or gone)
        for (let l = 0; l < 3; l++) {
            let last = this.laneLast[l];
            let free = last < 0 || !this.tOn[last] || this.tX[last] * this.tDir[last] > 1.5;
            if (free) {
                this.laneWait[l] -= dt;
                if (this.laneWait[l] <= 0) this.spawn(api, l, 99);
            }
        }
        for (let t = 0; t < NT; t++) {
            let b = this.bTarget[t];
            if (!this.tOn[t]) { api.hide(b); continue; }
            this.tX[t] += this.tDir[t] * this.tSpeed(t) * dt;
            this.tHit[t] += dt;
            let x = this.tX[t];
            if (Math.abs(x) > 10.4) {
                this.tOn[t] = false;
                api.hide(b);
                for (let a = 0; a < NA; a++) {
                    if (this.aState[a] == A_TARGET && this.aTgt[a] == t) {
                        this.aState[a] = A_IDLE;
                        api.hide(this.bArrow[a]);
                    }
                }
                continue;
            }
            // the sled bumps along (stepped, 8 fps), and a hit rocks the boss back and pops it
            let bump = Math.sin(Math.floor((api.time + <f64>t * 0.37) * 8) * 2.1) * 1.2;
            let h = this.tHit[t];
            let rock = h < 1.2 ? -16 * Math.exp(-h * 5) * Math.cos(h * 22) : 0;
            let pop = h < 0.5 ? 1 + 0.12 * Math.exp(-h * 9) : 1;
            api.place(b, x, 0, LANE_Z[this.tLane[t]], 0, rock, bump, pop);
        }
    }

    // ------------------------------------------------------------------ the bow

    bowPos(yawDeg: f64): StaticArray<f64> {
        let c = Math.cos(rad(yawDeg)), s = Math.sin(rad(yawDeg));
        let r = new StaticArray<f64>(3);
        r[0] = AX + BOW_LX * c + BOW_LZ * s;
        r[1] = BOW_LY;
        r[2] = AZ - BOW_LX * s + BOW_LZ * c;
        return r;
    }

    beginDraw(): void {
        if (this.nocked < 0 || this.drawing || this.nockT < 0.2) return;
        this.drawing = true;
        this.drawT = 0;
    }

    // the aim point this frame: the pointer's, trembling when the draw is held too long
    aimPoint(api: GameApi): StaticArray<f64> {
        let r = new StaticArray<f64>(2);
        let over = this.drawing ? Math.max(0, this.drawT - 1.5) : 0;
        let k = Math.min(over * 0.9, 1.4);
        r[0] = this.aimX + k * Math.sin(api.time * 13.1);
        r[1] = this.aimZ + k * 0.6 * Math.cos(api.time * 9.7);
        return r;
    }

    release(api: GameApi): void {
        if (!this.drawing) return;
        this.drawing = false;
        let a = this.nocked;
        if (a < 0) return;
        let d = clamp(this.drawT / 0.65, 0, 1);
        let aim = this.aimPoint(api);
        let px = aim[0], pz = aim[1], py = FACE_Y;
        let bp = this.bowPos(this.yawNow);
        let lx = bp[0], ly = bp[1] + 0.05, lz = bp[2];
        let dx = px - lx, dz = pz - lz;
        let R = Math.max(0.5, Math.sqrt(dx * dx + dz * dz));
        let ux = dx / R, uz = dz / R;
        let v = 7 + 19 * d;
        let dh = py - ly;
        let disc = v * v * v * v - GRAV * (GRAV * R * R + 2 * dh * v * v);
        let th: f64;
        if (disc < 0) {
            th = rad(42);
        } else {
            th = Math.atan((v * v - Math.sqrt(disc)) / (GRAV * R));
        }
        this.aState[a] = A_FLYING;
        this.aX[a] = lx; this.aY[a] = ly; this.aZ[a] = lz;
        this.aVX[a] = ux * v * Math.cos(th);
        this.aVY[a] = v * Math.sin(th);
        this.aVZ[a] = uz * v * Math.cos(th);
        this.aWind[a] = this.wind * 1.6;
        this.aAge[a] = 0;
        this.nocked = -1;
        this.left -= 1;
        this.shot += 1;
        this.releaseT = 0;
        // the bowstring's twang (a plucked note, higher with the draw) and the arrow's whoosh
        api.note(43 + 9 * d, 0.75, -0.2);
        api.sound(SFX_WHOOSH, 0.7 + 0.6 * d, 0.35 + 0.3 * d, -0.1);
        this.drawT = 0;
    }

    // ------------------------------------------------------------------ arrows

    updateArrows(api: GameApi, dt: f64): void {
        for (let a = 0; a < NA; a++) {
            let st = this.aState[a];
            let b = this.bArrow[a];
            if (st == A_IDLE) { api.hide(b); continue; }
            if (st == A_NOCKED) {
                // on the string: tip ahead of the grip, pulled back with the draw; slides in after a shot
                let d = this.drawing ? clamp(this.drawT / 0.65, 0, 1) : 0;
                let slide = clamp(this.nockT / 0.3, 0, 1);
                if (this.mode == M_OVER) { api.hide(b); continue; }
                let bp = this.bowPos(this.yawNow);
                let fx = Math.sin(rad(this.yawNow)), fz = Math.cos(rad(this.yawNow));
                let ahead = 0.42 - 0.62 * d - (1 - slide) * 0.8;
                let tx = bp[0] + fx * ahead, ty = bp[1] + 0.05 - (1 - slide) * 0.3, tz = bp[2] + fz * ahead;
                api.place(b, tx, ty, tz, this.yawNow, -4);
                continue;
            }
            if (st == A_FLYING) {
                this.aAge[a] += dt;
                let n = 4;
                let h = dt / <f64>n;
                for (let k = 0; k < n; k++) {
                    let ox = this.aX[a], oy = this.aY[a], oz = this.aZ[a];
                    this.aVY[a] -= GRAV * h;
                    this.aVX[a] += this.aWind[a] * h;
                    this.aX[a] += this.aVX[a] * h;
                    this.aY[a] += this.aVY[a] * h;
                    this.aZ[a] += this.aVZ[a] * h;
                    if (this.hitTargets(api, a, ox, oy, oz)) break;
                    if (this.aY[a] <= 0.02) {
                        this.land(api, a);
                        break;
                    }
                    if (this.aZ[a] < -14.5 || Math.abs(this.aX[a]) > 11) {
                        this.aState[a] = A_IDLE;
                        this.resolve(api, false);
                        break;
                    }
                }
                if (this.aState[a] == A_IDLE) {
                    api.sound(SFX_BLIP, 0.45, 0.4);      // gone over the range: a low blip
                }
                if (this.aState[a] == A_FLYING) {
                    let vx = this.aVX[a], vy = this.aVY[a], vz = this.aVZ[a];
                    let sp = Math.sqrt(vx * vx + vy * vy + vz * vz);
                    this.aYaw[a] = deg(Math.atan2(vx, vz));
                    this.aPitch[a] = -deg(Math.asin(clamp(vy / sp, -1, 1)));
                }
            }
            if (this.aState[a] == A_TARGET) {
                let t = this.aTgt[a];
                api.place(b, this.tX[t] + this.aOff[a], this.aY[a], this.aZ[a], this.aYaw[a], this.aPitch[a]);
                continue;
            }
            if (this.aState[a] == A_IDLE) { api.hide(b); continue; }
            // flying or in the ground: a stuck arrow quivers for a moment
            let q = 0.0;
            if (this.aState[a] == A_GROUND) {
                this.aAge[a] += dt;
                q = this.aAge[a] < 0.5 ? 7 * Math.exp(-this.aAge[a] * 7) * Math.sin(this.aAge[a] * 60) : 0;
            }
            api.place(b, this.aX[a], this.aY[a], this.aZ[a], this.aYaw[a], this.aPitch[a] + q);
        }
    }

    hitTargets(api: GameApi, a: i32, ox: f64, oy: f64, oz: f64): bool {
        for (let t = 0; t < NT; t++) {
            if (!this.tOn[t]) continue;
            let fz = LANE_Z[this.tLane[t]] + FACE_DZ;
            let nz = this.aZ[a];
            if (!(oz > fz && nz <= fz)) continue;
            let f = (oz - fz) / (oz - nz);
            let hx = ox + (this.aX[a] - ox) * f;
            let hy = oy + (this.aY[a] - oy) * f;
            let rx = hx - this.tX[t], ry = hy - FACE_Y;
            let r = Math.sqrt(rx * rx + ry * ry);
            if (r > FACE_R) continue;
            let ring = <i32>Math.min(4, Math.floor(r / (FACE_R / 5)));
            let mult = this.tLane[t] + 1;
            let pts = RING_PTS[ring] * mult;
            // stick: the tip 0.3 m into the boss along the flight
            let vx = this.aVX[a], vy = this.aVY[a], vz = this.aVZ[a];
            let sp = Math.sqrt(vx * vx + vy * vy + vz * vz);
            this.aYaw[a] = deg(Math.atan2(vx, vz));
            this.aPitch[a] = -deg(Math.asin(clamp(vy / sp, -1, 1)));
            this.aState[a] = A_TARGET;
            this.aTgt[a] = t;
            this.aOff[a] = hx + vx / sp * 0.3 - this.tX[t];
            this.aY[a] = hy + vy / sp * 0.3;
            this.aZ[a] = fz + vz / sp * 0.3;
            this.tHit[t] = 0;
            this.score += pts;
            this.hits += 1;
            this.burst(api, hx, hy, fz + 0.1, 5);
            // a straw thump (lighter on a farther lane) and the ring's chime, climbing with the streak
            api.soundAt(SFX_THUD, hx, hy, fz, 1.6 + 0.35 * <f64>this.tLane[t], 0.85);
            let up = PENTA[min<i32>(this.streak, 7)];
            api.note(RING_NOTE[ring] + up, ring == 0 ? 0.6 : 0.45, 0, ring == 0 ? SFX_BELL : SFX_NOTE);
            if (ring == 0) api.soundAt(SFX_COIN, hx, hy, fz, 1.0 + 0.06 * <f64>min<i32>(this.streak, 6), 0.7);
            this.streak++;
            this.popup(hx, hy + 0.9, fz, ring == 0 ? "BULLSEYE +" + pts.toString() : "+" + pts.toString(), ring == 0 ? 2 : 1);
            this.resolve(api, true);
            return true;
        }
        return false;
    }

    land(api: GameApi, a: i32): void {
        let vx = this.aVX[a], vy = this.aVY[a], vz = this.aVZ[a];
        let sp = Math.sqrt(vx * vx + vy * vy + vz * vz);
        this.aYaw[a] = deg(Math.atan2(vx, vz));
        this.aPitch[a] = clamp(-deg(Math.asin(clamp(vy / sp, -1, 1))), 18, 70);
        this.aX[a] += vx / sp * 0.15;
        this.aZ[a] += vz / sp * 0.15;
        this.aY[a] = -0.12;
        this.aState[a] = A_GROUND;
        this.aAge[a] = 0;
        this.burst(api, this.aX[a], 0.05, this.aZ[a], 2);
        this.popup(this.aX[a], 0.9, this.aZ[a], "MISS", 0);
        api.soundAt(SFX_THUD, this.aX[a], 0, this.aZ[a], 0.7, 0.6);   // a dull thunk in the turf
        this.streak = 0;
        this.resolve(api, false);
    }

    // an arrow came down: the next one, a new wind, or the end of the run
    resolve(api: GameApi, hit: bool): void {
        if (this.mode == M_READY) this.mode = M_PLAY;
        if (!hit) this.streak = 0;
        if (this.left > 0) {
            this.newWind(api);
            this.nock();
            api.sound(SFX_CLICK, 0.45, 0.4, -0.2);       // the next arrow clicks onto the string
        } else if (this.mode == M_PLAY) {
            this.mode = M_OVER;
            this.overT = 0;
            let record = this.score > this.best && this.score > 0;
            if (this.score > this.best) this.best = this.score;
            // the quiver is empty: a fanfare for a good round, a short call for a fair one, a sigh otherwise
            if (this.hits >= 7) {
                api.sound(SFX_WIN, 1.0, 0.8);
                this.playTune(api, [0, 0, 0, 67, 72, 76, 79, record ? 84 : 0], 7, SFX_NOTE);
            } else if (this.hits >= 4) {
                this.playTune(api, [67, 72, 76, record ? 84 : 0], 8, SFX_BELL);
            } else {
                api.sound(SFX_LOSE, 1.0, 0.7);
            }
        }
    }

    // ------------------------------------------------------------------ sound

    playTune(api: GameApi, notes: Array<f64>, step: i32, kind: i32): void {
        this.tuneN = min<i32>(notes.length, 8);
        for (let i = 0; i < this.tuneN; i++) this.tune[i] = notes[i];
        this.tuneI = 0;
        this.tuneAt = api.frame;
        this.tuneStep = step;
        this.tuneKind = kind;
    }

    sounds(api: GameApi, dt: f64): void {
        if (this.drawing) {
            // a tick when the draw is full (the meter turns mint), then a nervous tick while it trembles
            if (this.drawT >= 0.65 && this.drawT - dt < 0.65) api.sound(SFX_TICK, 0.8, 0.8, -0.2);
            if (this.drawT > 1.5 && api.frame % 10 == 0) api.sound(SFX_TICK, 0.5, 0.5, -0.2);
        }
        if (this.tuneI < this.tuneN && api.frame >= this.tuneAt) {
            let m = this.tune[this.tuneI];
            if (m > 0) api.note(m, 0.65, 0, this.tuneKind);
            this.tuneI++;
            this.tuneAt = api.frame + this.tuneStep;
        }
    }

    // ------------------------------------------------------------------ chips and popups

    burst(api: GameApi, x: f64, y: f64, z: f64, n: i32): void {
        for (let k = 0; k < n; k++) {
            let c = this.nextChip;
            this.nextChip = (this.nextChip + 1) % NC;
            this.cLife[c] = 0.7;
            this.cX[c] = x; this.cY[c] = y; this.cZ[c] = z;
            let ang = api.range(0, Math.PI * 2);
            let sp = api.range(1.5, 3.2);
            this.cVX[c] = Math.cos(ang) * sp;
            this.cVZ[c] = Math.abs(Math.sin(ang)) * sp * 0.6 + 0.6;
            this.cVY[c] = api.range(2.0, 4.0);
            this.cSpin[c] = api.range(-600, 600);
        }
    }

    updateChips(api: GameApi, dt: f64): void {
        for (let c = 0; c < NC; c++) {
            let b = this.bChip[c];
            if (this.cLife[c] <= 0) { api.hide(b); continue; }
            this.cLife[c] -= dt;
            this.cVY[c] -= GRAV * dt;
            this.cX[c] += this.cVX[c] * dt;
            this.cY[c] += this.cVY[c] * dt;
            this.cZ[c] += this.cVZ[c] * dt;
            if (this.cY[c] < 0.05) { this.cY[c] = 0.05; this.cVY[c] = 0; this.cVX[c] *= 0.5; this.cVZ[c] *= 0.5; }
            let s = this.cLife[c] < 0.2 ? this.cLife[c] / 0.2 : 1;
            api.place(b, this.cX[c], this.cY[c], this.cZ[c], this.cSpin[c] * this.cLife[c], 30, 0, Math.max(0.3, s));
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
            if (this.overT > 2.0) {
                this.newRun(api);
                this.mode = M_PLAY;
            }
            return;
        }
        if (!this.drawing) {
            if (this.nocked < 0) return;
            this.dWait -= dt;
            if (this.dWait > 0) return;
            // choose a target that will be well inside the frame when the arrow arrives
            let bestT = -1;
            let bestScore = -1e9;
            for (let t = 0; t < NT; t++) {
                if (!this.tOn[t]) continue;
                let xa = this.tX[t] + this.tDir[t] * this.tSpeed(t) * 1.3;
                if (Math.abs(xa) > 5.5) continue;
                let sc = <f64>this.tLane[t] * 1.2 - Math.abs(xa) * 0.4 + api.range(0, 1.5);
                if (sc > bestScore) { bestScore = sc; bestT = t; }
            }
            if (bestT < 0) { this.dWait = 0.15; return; }
            this.dTgt = bestT;
            let r = api.rand();
            this.dHold = r < 0.1 ? api.range(0.22, 0.35) : (r > 0.94 ? api.range(1.9, 2.3) : api.range(0.6, 1.0));
            let g = (api.rand() + api.rand() + api.rand() - 1.5);
            this.dErrX = g * 1.45;
            this.dErrZ = (api.rand() - 0.5) * 2.0;
            this.dWindK = api.range(0.55, 1.15);
            this.aimX = this.tX[bestT];
            this.aimZ = LANE_Z[this.tLane[bestT]];
            this.beginDraw();
            this.aimValid = true;
            return;
        }
        // tracking: lead the target by the time left to hold plus the flight, lean into the wind
        let t = this.dTgt;
        if (t >= 0 && this.tOn[t]) {
            let tz = LANE_Z[this.tLane[t]];
            let flight = (AZ - tz) / 24.0;
            let left = Math.max(0, this.dHold - this.drawT);
            let lead = this.tDir[t] * this.tSpeed(t) * (left + flight);
            let drift = 0.5 * this.wind * 1.6 * flight * flight * this.dWindK;
            let gx = this.tX[t] + lead - drift + this.dErrX;
            let gz = tz + this.dErrZ;
            let k = Math.min(1, dt * 8);
            this.aimX += (gx - this.aimX) * k;
            this.aimZ += (gz - this.aimZ) * k;
        }
        if (this.drawT >= this.dHold) {
            this.release(api);
            this.dWait = api.range(0.35, 0.8);
        }
    }

    // ------------------------------------------------------------------ frame

    update(api: GameApi): void {
        let dt = api.dt;
        if (this.wasDemo != api.demo) {
            // demo switched off (a visitor clicked the tile) or on: a fresh run
            this.wasDemo = api.demo;
            this.newRun(api);
            this.mode = api.demo ? M_PLAY : M_READY;
        }
        if (this.mode == M_OVER) this.overT += dt;
        this.releaseT += dt;
        this.nockT += dt;
        if (this.drawing) this.drawT += dt;
        if (api.demo) this.demoPlay(api, dt);
        this.sounds(api, dt);

        this.updateTargets(api, dt);

        // the archer turns towards the aim (within 40 degrees), leans into the draw, recoils on release
        let bp0 = this.bowPos(180);
        let want = 180.0;
        if (this.aimValid) {
            want = deg(Math.atan2(this.aimX - bp0[0], this.aimZ - bp0[2]));
            if (want < 0) want += 360;
            want = clamp(want, 140, 220);
        }
        this.yawNow += (want - this.yawNow) * Math.min(1, dt * 10);
        let d = this.drawing ? clamp(this.drawT / 0.65, 0, 1) : 0;
        let rec = this.releaseT < 0.4 ? Math.exp(-this.releaseT * 9) : 0;
        let shake = (this.drawing && this.drawT > 1.5) ? 0.025 * Math.sin(Math.floor(api.time * 24) * 2.7) : 0;
        let sx = 1 + 0.035 * d - 0.03 * rec;
        let sy = 1 - 0.045 * d + 0.06 * rec;
        api.placeScaled(this.bArcher, AX + shake, 0, AZ, this.yawNow, sx, sy, sx);
        let bp = this.bowPos(this.yawNow);
        let bend = 1 + 0.7 * d - 0.25 * rec * Math.cos(this.releaseT * 40);
        // the bow, canted 20 degrees so its belly shows from behind; it bends as the string comes back
        api.placeScaled(this.bBow, bp[0] + shake, bp[1] + 0.03 * rec, bp[2], this.yawNow, 1, 1, bend, 0, -20);

        this.updateArrows(api, dt);
        this.updateChips(api, dt);
        for (let p = 0; p < NP; p++) {
            if (this.pOn[p]) {
                this.pAge[p] += dt;
                if (this.pAge[p] > 1.3) this.pOn[p] = false;
            }
        }

        // the wind flag: turns downwind, lifts with the strength, flutters (stepped, 10 fps)
        let s = clamp(Math.abs(this.wind) / 2.6, 0, 1);
        let fy = this.wind >= 0 ? 0.0 : 180.0;
        this.flagYaw += (fy - this.flagYaw) * Math.min(1, dt * 4);
        this.flagLift += (s - this.flagLift) * Math.min(1, dt * 4);
        let flutter = Math.sin(Math.floor(api.time * 10) * 1.9) * (4 + 6 * this.flagLift);
        api.place(this.bFlag, FLAG_X, FLAG_Y, FLAG_Z, this.flagYaw, 0, -(1 - this.flagLift) * 45 + flutter, 1.25);
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (api.pick(x, y, <f32>FACE_Y)) {
            this.aimX = clamp(<f64>api.hitX, -9, 9);
            this.aimZ = clamp(<f64>api.hitZ, -13, 1.0);
            this.aimValid = true;
        }
        if (kind == POINTER_DOWN) {
            if (this.mode == M_OVER) {
                if (this.overT > 0.6) {
                    this.newRun(api);
                    this.mode = M_PLAY;
                    api.sound(SFX_BLIP, 1.0, 0.6);       // a fresh quiver
                }
                return true;
            }
            if (this.mode == M_READY) {
                this.mode = M_PLAY;
                api.sound(SFX_BLIP, 1.0, 0.6);
            }
            let was = this.drawing;
            this.beginDraw();
            if (this.drawing && !was) api.sound(SFX_WHOOSH, 0.45, 0.4, -0.2);   // the string comes back
        } else if (kind == POINTER_UP) {
            this.release(api);
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let white = api.rampColor(3, 3);
        let gold = api.rampColor(3, 2);
        let ink = api.rampColor(6, 0);
        let mint = api.rampColor(5, 3);
        let crim = api.rampColor(4, 2);
        let pink = api.rampColor(4, 3);
        let slate = api.rampColor(6, 1);
        let W = <f32>api.hudW;

        api.text(4, 4, "SCORE " + this.score.toString(), white, 1, ink);
        api.text(4, 11, "BEST " + this.best.toString(), gold, 1, ink);

        // arrows left: little arrows standing in a row (top right)
        for (let i = 0; i < ARROWS; i++) {
            let x = W - 6 - <f32>i * 4;
            let on = i < this.left;
            let c = on ? white : slate;
            api.rect(x + 1, 5, 1, 7, ink);
            api.rect(x, 4, 1, 7, c);
            api.rect(x - 1, 4, 3, 1, on ? slate : ink);
            api.rect(x - 1, 10, 3, 2, on ? crim : ink);
        }

        // the wind: arrows' count by strength, beside the flag's word
        let n = <i32>Math.max(1, Math.round(Math.abs(this.wind) / 0.9));
        let ws = "";
        for (let i = 0; i < n; i++) ws += this.wind >= 0 ? ">" : "<";
        let wl = "WIND " + ws;
        api.text(Mathf.floor((W - api.textWidth("WIND >>>", 1)) * 0.5), 4, wl, white, 1, ink);

        // the aim mark and the draw meter
        if (this.mode != M_OVER && this.aimValid && (this.drawing || !api.demo)) {
            let aim = this.aimPoint(api);
            if (api.project(<f32>aim[0], <f32>FACE_Y, <f32>aim[1])) {
                let sx = Mathf.round(api.screenX), sy = Mathf.round(api.screenY);
                let c = this.drawing ? (this.drawT > 1.5 ? crim : white) : gold;
                for (let k = 0; k < 2; k++) {
                    let o = <f32>(1 - k);
                    let cc = k == 0 ? ink : c;
                    api.rect(sx - 4 + o, sy + o, 3, 1, cc); api.rect(sx + 2 + o, sy + o, 3, 1, cc);
                    api.rect(sx + o, sy - 4 + o, 1, 3, cc); api.rect(sx + o, sy + 2 + o, 1, 3, cc);
                }
            }
        }
        if (this.drawing) {
            if (api.project(<f32>AX, 0, <f32>(AZ + 0.6))) {
                let mx = Mathf.round(api.screenX) - 10, my = Mathf.round(api.screenY) + 3;
                let f = <f32>clamp(this.drawT / 0.65, 0, 1);
                api.rect(mx - 1, my - 1, 22, 4, ink);
                let c = this.drawT >= 0.65 ? (this.drawT > 1.5 ? (Math.floor(api.time * 8) % 2 == 0 ? crim : pink) : mint) : white;
                api.rect(mx, my, Mathf.round(20 * f), 2, c);
            }
        }

        // popups rise and blink out
        for (let p = 0; p < NP; p++) {
            if (!this.pOn[p]) continue;
            let age = this.pAge[p];
            if (api.project(<f32>this.pX[p], <f32>(this.pY[p] + age * 0.8), <f32>this.pZ[p])) {
                if (age > 1.0 && Math.floor(age * 12) % 2 == 0) continue;
                let s = this.pText[p];
                let k = this.pKind[p];
                let c = k == 2 ? gold : (k == 1 ? white : slate);
                let tw = api.textWidth(s, 1);
                api.text(Mathf.round(api.screenX - tw * 0.5), Mathf.round(api.screenY), s, c, 1, ink);
            }
        }

        let H = <f32>api.hudH;
        if (this.mode == M_OVER) {
            let y = Mathf.floor(H * 0.32);
            api.rect(0, y - 4, W, 34, ink);
            api.textCentered(y, "QUIVER EMPTY - " + this.hits.toString() + " OF 10 ON TARGET", mint, 1, 0);
            api.textCentered(y + 9, "SCORE " + this.score.toString(), white, 2, 0);
            if (!api.demo && this.overT > 0.6) {
                api.textCentered(y + 22, "CLICK TO SHOOT AGAIN", gold, 1, 0);
            }
        } else if (this.mode == M_READY && !api.demo) {
            api.textCentered(H - 10, "HOLD TO DRAW, RELEASE TO SHOOT", white, 1, ink);
        } else if (!api.demo && this.shot == 0 && !this.drawing) {
            api.textCentered(H - 10, "HOLD TO DRAW, RELEASE TO SHOOT", white, 1, ink);
        }
    }
}
