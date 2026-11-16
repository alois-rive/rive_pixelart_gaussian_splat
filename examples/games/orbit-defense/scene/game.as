// Orbit Defense: a tiny planet, four houses on it, meteors falling in from every side. Click to fire:
// the orbital cannon (the satellite) swings round the planet towards the pointer and shoots a bolt at
// it. A bolt pops a meteor (+1); a big meteor splits in two. A meteor that reaches a house flattens it;
// when all four are gone the run is over. The next click starts a new run in the same world.
//
// The play plane is z = 0 (the camera looks at it face-on). The pointer arrives in HUD pixels and is
// turned into a point on that plane here (toPlane), because api.pick only meets horizontal planes.
import { GameApi, POINTER_DOWN, POINTER_MOVE } from "./game_api";

const R: f64 = 1.4;          // planet radius
const RS: f64 = 2.75;        // the satellite's orbit (its body centre)
const MUZZLE: f64 = 0.85;    // body centre to muzzle tip (the satellite is baked at scale 1.25)
const BOLT_SPEED: f64 = 8.0;
const NSMALL: i32 = 6;
const NBIG: i32 = 3;
const NMET: i32 = 9;         // slots 0-5 small, 6-8 big; trail i belongs to slot i
const NBOLT: i32 = 6;
const NBURST: i32 = 5;
const NDEBRIS: i32 = 12;
const NPUFF: i32 = 2;
const NLABEL: i32 = 6;

const READY: i32 = 0;
const PLAY: i32 = 1;
const OVER: i32 = 2;

function wrap180(a: f64): f64 {
    let x = a % 360.0;
    if (x > 180) x -= 360;
    if (x < -180) x += 360;
    return x;
}
function deg(r: f64): f64 { return r * 180.0 / Math.PI; }
function rad(d: f64): f64 { return d * Math.PI / 180.0; }
function clamp(x: f64, a: f64, b: f64): f64 { return x < a ? a : (x > b ? b : x); }

export class Game {
    // bones
    sat: i32 = -1;
    flash: i32 = -1;
    house: StaticArray<i32> = new StaticArray<i32>(4);
    rubble: StaticArray<i32> = new StaticArray<i32>(4);
    metB: StaticArray<i32> = new StaticArray<i32>(NMET);
    trailB: StaticArray<i32> = new StaticArray<i32>(NMET);
    boltB: StaticArray<i32> = new StaticArray<i32>(NBOLT);
    burstB: StaticArray<i32> = new StaticArray<i32>(NBURST);
    debrisB: StaticArray<i32> = new StaticArray<i32>(NDEBRIS);
    puffB: StaticArray<i32> = new StaticArray<i32>(NPUFF);

    // houses: angle on the rim, alive, the time of the last change (pop-in, wobble)
    hAng: StaticArray<f64> = [135.0, 45.0, 225.0, 315.0];
    hAlive: StaticArray<bool> = new StaticArray<bool>(4);
    hBorn: StaticArray<f64> = new StaticArray<f64>(4);
    hShake: StaticArray<f64> = new StaticArray<f64>(4);

    // meteors
    mOn: StaticArray<bool> = new StaticArray<bool>(NMET);
    mX: StaticArray<f64> = new StaticArray<f64>(NMET);
    mY: StaticArray<f64> = new StaticArray<f64>(NMET);
    mVX: StaticArray<f64> = new StaticArray<f64>(NMET);
    mVY: StaticArray<f64> = new StaticArray<f64>(NMET);
    mSpin: StaticArray<f64> = new StaticArray<f64>(NMET);
    mRate: StaticArray<f64> = new StaticArray<f64>(NMET);
    mHit: StaticArray<f64> = new StaticArray<f64>(NMET);
    mBorn: StaticArray<f64> = new StaticArray<f64>(NMET);

    // bolts
    bOn: StaticArray<bool> = new StaticArray<bool>(NBOLT);
    bX: StaticArray<f64> = new StaticArray<f64>(NBOLT);
    bY: StaticArray<f64> = new StaticArray<f64>(NBOLT);
    bVX: StaticArray<f64> = new StaticArray<f64>(NBOLT);
    bVY: StaticArray<f64> = new StaticArray<f64>(NBOLT);

    // effects
    uT: StaticArray<f64> = new StaticArray<f64>(NBURST);     // burst start (-1 off)
    uX: StaticArray<f64> = new StaticArray<f64>(NBURST);
    uY: StaticArray<f64> = new StaticArray<f64>(NBURST);
    uS: StaticArray<f64> = new StaticArray<f64>(NBURST);
    dT: StaticArray<f64> = new StaticArray<f64>(NDEBRIS);
    dX: StaticArray<f64> = new StaticArray<f64>(NDEBRIS);
    dY: StaticArray<f64> = new StaticArray<f64>(NDEBRIS);
    dVX: StaticArray<f64> = new StaticArray<f64>(NDEBRIS);
    dVY: StaticArray<f64> = new StaticArray<f64>(NDEBRIS);
    pT: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    pA: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    lT: StaticArray<f64> = new StaticArray<f64>(NLABEL);
    lX: StaticArray<f64> = new StaticArray<f64>(NLABEL);
    lY: StaticArray<f64> = new StaticArray<f64>(NLABEL);
    lS: Array<string> = ["", "", "", "", "", ""];
    nextBurst: i32 = 0;
    nextDebris: i32 = 0;
    nextPuff: i32 = 0;
    nextLabel: i32 = 0;

    // the satellite
    satA: f64 = 90.0;        // degrees round the planet (90 = on top)
    satW: f64 = 0.0;         // angular velocity, deg/s
    aimA: f64 = 90.0;        // where it is turning to
    wantFire: bool = false;
    fireX: f64 = 0;
    fireY: f64 = 0;
    cool: f64 = 0;
    lastShot: f64 = -9;
    stun: f64 = -9;

    // the run
    state: i32 = READY;
    t: f64 = 0;              // api.time
    runT: f64 = 0;           // seconds into the run
    overT: f64 = 0;
    spawnT: f64 = 0;         // the next spawn, in run seconds
    score: i32 = 0;
    best: i32 = 0;
    demoBest: i32 = 0;      // the demo keeps its own best: a visitor's best is theirs
    shake: f64 = -9;
    wasDemo: bool = false;
    started: bool = false;

    // the demo player
    aiNext: f64 = 0.3;

    // the plane point of the last pointer conversion
    px: f64 = 0;
    py: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        this.sat = api.bone("sat");
        this.flash = api.bone("flash");
        this.house[0] = api.bone("hut0");
        this.house[1] = api.bone("dome0");
        this.house[2] = api.bone("hut1");
        this.house[3] = api.bone("dome1");
        for (let i = 0; i < 4; i++) this.rubble[i] = api.bone("rubble" + i.toString());
        for (let i = 0; i < NSMALL; i++) this.metB[i] = api.bone("meteor" + i.toString());
        for (let i = 0; i < NBIG; i++) this.metB[NSMALL + i] = api.bone("boulder" + i.toString());
        for (let i = 0; i < NMET; i++) this.trailB[i] = api.bone("trail" + i.toString());
        for (let i = 0; i < NBOLT; i++) this.boltB[i] = api.bone("bolt" + i.toString());
        for (let i = 0; i < NBURST; i++) this.burstB[i] = api.bone("burst" + i.toString());
        for (let i = 0; i < NDEBRIS; i++) this.debrisB[i] = api.bone("debris" + i.toString());
        for (let i = 0; i < NPUFF; i++) this.puffB[i] = api.bone("puff" + i.toString());
        this.wasDemo = api.demo;
        this.reset(api, false);
        if (api.demo) this.begin(api);
    }

    // ------------------------------------------------------------ run control

    reset(api: GameApi, popIn: bool): void {
        for (let i = 0; i < 4; i++) {
            this.hAlive[i] = true;
            this.hBorn[i] = popIn ? api.time + <f64>i * 0.12 : -9;
            this.hShake[i] = -9;
        }
        for (let i = 0; i < NMET; i++) this.mOn[i] = false;
        for (let i = 0; i < NBOLT; i++) this.bOn[i] = false;
        for (let i = 0; i < NBURST; i++) this.uT[i] = -9;
        for (let i = 0; i < NDEBRIS; i++) this.dT[i] = -9;
        for (let i = 0; i < NPUFF; i++) this.pT[i] = -9;
        for (let i = 0; i < NLABEL; i++) this.lT[i] = -9;
        this.score = 0;
        this.runT = 0;
        this.wantFire = false;
        this.state = READY;
    }

    begin(api: GameApi): void {
        this.state = PLAY;
        this.runT = 0;
        // the first meteor comes in at once, already on screen, so a run (and the demo) opens with action
        this.spawn(api, false, 5.2);
        this.spawnT = 0.8;
        this.aiNext = 0.35;
    }

    // ------------------------------------------------------------ the pointer on the play plane

    toPlane(api: GameApi, hx: f32, hy: f32): bool {
        let nx = <f64>(((hx - api.gridOX) / api.gridW) * 2 - 1);
        let ny = <f64>(1 - ((hy - api.gridOY) / api.gridH) * 2);
        let ox = <f64>api.camEX, oy = <f64>api.camEY, oz = <f64>api.camEZ;
        let dx = <f64>api.camFX, dy = <f64>api.camFY, dz = <f64>api.camFZ;
        let hw = <f64>api.camHW, hh = <f64>api.camHH;
        if (api.camPersp) {
            dx += <f64>api.camRX * nx * hw + <f64>api.camUX * ny * hh;
            dy += <f64>api.camRY * nx * hw + <f64>api.camUY * ny * hh;
            dz += <f64>api.camRZ * nx * hw + <f64>api.camUZ * ny * hh;
        } else {
            ox += <f64>api.camRX * nx * hw + <f64>api.camUX * ny * hh;
            oy += <f64>api.camRY * nx * hw + <f64>api.camUY * ny * hh;
            oz += <f64>api.camRZ * nx * hw + <f64>api.camUZ * ny * hh;
        }
        if (Math.abs(dz) < 1e-6) return false;
        let t = -oz / dz;
        this.px = ox + dx * t;
        this.py = oy + dy * t;
        return true;
    }

    // ------------------------------------------------------------ placing bones

    // A bone at (x, y, z), turned rollDeg in the play plane, scaled per axis in its own frame
    // (api.placeScaled only turns about Y). Every bone here is baked with yaw 0.
    placeRoll(api: GameApi, b: i32, x: f64, y: f64, z: f64, rollDeg: f64, sx: f64, sy: f64, sz: f64): void {
        if (b <= 0 || b >= 64) return;
        let c = Math.cos(rad(rollDeg)), s = Math.sin(rad(rollDeg));
        let a00 = c * sx, a01 = -s * sy, a10 = s * sx, a11 = c * sy, a22 = sz;
        let p0 = <f64>api.restX[b], p1 = <f64>api.restY[b], p2 = <f64>api.restZ[b];
        let m = b * 12;
        api.mats[m] = <f32>a00; api.mats[m + 1] = <f32>a01; api.mats[m + 2] = 0;
        api.mats[m + 3] = <f32>(x - (a00 * p0 + a01 * p1));
        api.mats[m + 4] = <f32>a10; api.mats[m + 5] = <f32>a11; api.mats[m + 6] = 0;
        api.mats[m + 7] = <f32>(y - (a10 * p0 + a11 * p1));
        api.mats[m + 8] = 0; api.mats[m + 9] = 0; api.mats[m + 10] = <f32>a22;
        api.mats[m + 11] = <f32>(z - a22 * p2);
        api.dirty[b] = true;
        api.anyDirty = true;
    }

    // ------------------------------------------------------------ spawning

    freeSlot(big: bool): i32 {
        let a = big ? NSMALL : 0, n = big ? NBIG : NSMALL;
        for (let i = a; i < a + n; i++) if (!this.mOn[i]) return i;
        return -1;
    }

    livingHouse(api: GameApi): i32 {
        let n = 0;
        for (let i = 0; i < 4; i++) if (this.hAlive[i]) n++;
        if (n == 0) return <i32>Math.floor(api.rand() * 4);
        let k = <i32>Math.floor(api.rand() * <f64>n);
        for (let i = 0; i < 4; i++) {
            if (this.hAlive[i]) {
                if (k == 0) return i;
                k--;
            }
        }
        return 0;
    }

    // A meteor from beyond the frame's edge (or `dist` metres out), aimed at a living house.
    spawn(api: GameApi, big: bool, dist: f64): void {
        let i = this.freeSlot(big);
        if (i < 0) return;
        let h = this.livingHouse(api);
        let ha = rad(this.hAng[h] + api.range(-7, 7));
        let tx = Math.cos(ha) * (R + 0.3), ty = Math.sin(ha) * (R + 0.3);
        // come from roughly the house's side of the sky, so the threat reads
        let a = rad(this.hAng[h] + api.range(-70, 70));
        let sx: f64, sy: f64;
        if (dist > 0) {
            sx = Math.cos(a) * dist; sy = Math.sin(a) * dist * 0.62;
        } else {
            sx = Math.cos(a) * 7.4; sy = Math.sin(a) * 4.9;
        }
        let speed = (big ? 0.6 : 0.75) + this.runT * 0.012 + api.range(0, 0.3);
        let dx = tx - sx, dy = ty - sy, l = Math.sqrt(dx * dx + dy * dy);
        this.mOn[i] = true;
        this.mX[i] = sx; this.mY[i] = sy;
        this.mVX[i] = dx / l * speed; this.mVY[i] = dy / l * speed;
        this.mSpin[i] = api.range(0, 360);
        this.mRate[i] = api.range(60, 160) * (api.rand() < 0.5 ? -1 : 1);
        this.mHit[i] = -9;
        this.mBorn[i] = this.t;
    }

    // ------------------------------------------------------------ effects

    burst(x: f64, y: f64, size: f64): void {
        let k = this.nextBurst;
        this.nextBurst = (k + 1) % NBURST;
        this.uT[k] = this.t; this.uX[k] = x; this.uY[k] = y; this.uS[k] = size;
    }

    debris(api: GameApi, x: f64, y: f64, n: i32, vx: f64, vy: f64): void {
        for (let j = 0; j < n; j++) {
            let k = this.nextDebris;
            this.nextDebris = (k + 1) % NDEBRIS;
            let a = api.range(0, Math.PI * 2), s = api.range(1.5, 3.2);
            this.dT[k] = this.t; this.dX[k] = x; this.dY[k] = y;
            this.dVX[k] = Math.cos(a) * s + vx * 0.4; this.dVY[k] = Math.sin(a) * s + vy * 0.4;
        }
    }

    label(api: GameApi, x: f64, y: f64, s: string): void {
        let k = this.nextLabel;
        this.nextLabel = (k + 1) % NLABEL;
        this.lT[k] = this.t; this.lX[k] = x; this.lY[k] = y; this.lS[k] = s;
    }

    // ------------------------------------------------------------ the frame

    update(api: GameApi): void {
        this.t = api.time;
        let dt = api.dt;

        // demo switched: off -> a fresh run at once; on -> the demo plays from a fresh run
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.reset(api, true);
            this.begin(api);
        }

        if (this.state == PLAY) this.runT += dt;
        if (this.state == OVER && api.demo && this.t - this.overT > 2.0) {
            this.reset(api, true);
            this.begin(api);
        }

        if (api.demo && this.state == PLAY) this.think(api);
        if (this.state == READY) {
            // idle: the satellite drifts round, waiting
            this.aimA = 90 + 25 * Math.sin(this.t * 0.7);
        }

        this.stepSatellite(api, dt);
        this.stepBolts(api, dt);
        this.stepMeteors(api, dt);
        if (this.state == PLAY) {
            if (this.runT >= this.spawnT) {
                let big = this.runT > 4 && api.rand() < 0.3;
                this.spawn(api, big, 0);
                // now and then a pair: a second rock from another side
                if (this.runT > 12 && api.rand() < 0.25) this.spawn(api, false, 0);
                let gap = Math.max(0.55, 1.2 - this.runT * 0.012);
                this.spawnT = this.runT + gap * api.range(0.75, 1.25);
            }
        }
        this.drawWorld(api);

        // a little shake when a house is hit: the camera slides by whole art pixels (it snaps)
        let k = this.t - this.shake;
        if (k < 0.35) {
            let amp = 0.12 * (1 - k / 0.35);
            api.targetX = Math.sin(k * 90) * amp;
            api.targetY = Math.cos(k * 70) * amp * 0.6;
        } else {
            api.targetX = 0; api.targetY = 0;
        }
    }

    stepSatellite(api: GameApi, dt: f64): void {
        let diff = wrap180(this.aimA - this.satA);
        let w = clamp(diff * 14, -720, 720);
        // a little inertia: ease the angular speed towards the wanted one
        this.satW += (w - this.satW) * Math.min(1, dt * 18);
        this.satA = wrap180(this.satA + this.satW * dt);
        this.cool -= dt;
        if (this.wantFire && Math.abs(wrap180(this.aimA - this.satA)) < 9 && this.cool <= 0) {
            this.fire(api);
        }
    }

    // aim at a plane point: the satellite turns to its angle and fires when it gets there
    aimAt(x: f64, y: f64, fire: bool): void {
        this.aimA = deg(Math.atan2(y, x));
        if (fire) {
            this.wantFire = true;
            this.fireX = x; this.fireY = y;
        }
    }

    fire(api: GameApi): void {
        this.wantFire = false;
        this.cool = 0.16;
        let a = rad(this.satA);
        let mx = Math.cos(a) * (RS + MUZZLE), my = Math.sin(a) * (RS + MUZZLE);
        let dx = this.fireX - mx, dy = this.fireY - my;
        let l = Math.sqrt(dx * dx + dy * dy);
        // a click inside the orbit (or behind the barrel) fires straight out
        if (l < 0.5 || (dx * Math.cos(a) + dy * Math.sin(a)) / l < 0.15) {
            dx = Math.cos(a); dy = Math.sin(a); l = 1;
        }
        for (let i = 0; i < NBOLT; i++) {
            if (!this.bOn[i]) {
                this.bOn[i] = true;
                this.bX[i] = mx; this.bY[i] = my;
                this.bVX[i] = dx / l * BOLT_SPEED; this.bVY[i] = dy / l * BOLT_SPEED;
                break;
            }
        }
        this.lastShot = this.t;
    }

    stepBolts(api: GameApi, dt: f64): void {
        for (let i = 0; i < NBOLT; i++) {
            if (!this.bOn[i]) continue;
            this.bX[i] += this.bVX[i] * dt;
            this.bY[i] += this.bVY[i] * dt;
            let x = this.bX[i], y = this.bY[i];
            if (Math.abs(x) > 8.5 || Math.abs(y) > 5.5 || x * x + y * y < R * R) {
                this.bOn[i] = false;
                continue;
            }
            for (let j = 0; j < NMET; j++) {
                if (!this.mOn[j]) continue;
                let r = j >= NSMALL ? 0.58 : 0.42;
                let ex = this.mX[j] - x, ey = this.mY[j] - y;
                if (ex * ex + ey * ey < r * r) {
                    this.bOn[i] = false;
                    this.hitMeteor(api, j, this.bVX[i], this.bVY[i]);
                    break;
                }
            }
        }
    }

    hitMeteor(api: GameApi, j: i32, bvx: f64, bvy: f64): void {
        let x = this.mX[j], y = this.mY[j];
        if (j >= NSMALL) {
            // a big one splits: two small halves veer off to either side
            this.mOn[j] = false;
            this.burst(x, y, 1.0);
            this.debris(api, x, y, 5, this.mVX[j], this.mVY[j]);
            let sp = Math.sqrt(this.mVX[j] * this.mVX[j] + this.mVY[j] * this.mVY[j]) * 1.25;
            let base = Math.atan2(this.mVY[j], this.mVX[j]);
            for (let s = -1; s <= 1; s += 2) {
                let k = this.freeSlot(false);
                if (k < 0) break;
                let a = base + <f64>s * rad(api.range(28, 40));
                this.mOn[k] = true;
                this.mX[k] = x + Math.cos(a) * 0.3; this.mY[k] = y + Math.sin(a) * 0.3;
                this.mVX[k] = Math.cos(a) * sp; this.mVY[k] = Math.sin(a) * sp;
                this.mSpin[k] = api.range(0, 360);
                this.mRate[k] = api.range(120, 220) * <f64>s;
                this.mHit[k] = this.t;
                this.mBorn[k] = this.t;
            }
            this.score += 1;
            this.label(api, x, y, "+1");
        } else {
            this.mOn[j] = false;
            this.burst(x, y, 0.75);
            this.debris(api, x, y, 4, this.mVX[j], this.mVY[j]);
            this.score += 1;
            this.label(api, x, y, "+1");
        }
        this.bumpBest();
    }

    bumpBest(): void {
        if (this.wasDemo) {
            if (this.score > this.demoBest) this.demoBest = this.score;
        } else if (this.score > this.best) {
            this.best = this.score;
        }
    }

    stepMeteors(api: GameApi, dt: f64): void {
        let sa = rad(this.satA);
        let sx = Math.cos(sa) * RS, sy = Math.sin(sa) * RS;
        for (let j = 0; j < NMET; j++) {
            if (!this.mOn[j]) continue;
            this.mX[j] += this.mVX[j] * dt;
            this.mY[j] += this.mVY[j] * dt;
            this.mSpin[j] += this.mRate[j] * dt;
            let x = this.mX[j], y = this.mY[j];
            let rm = j >= NSMALL ? 0.46 : 0.3;
            // the satellite's body blocks a meteor (no score, and it reels)
            let ex = x - sx, ey = y - sy;
            if (ex * ex + ey * ey < (0.42 + rm) * (0.42 + rm)) {
                this.mOn[j] = false;
                this.burst(x, y, 0.6);
                this.debris(api, x, y, 3, this.mVX[j], this.mVY[j]);
                this.stun = this.t;
                continue;
            }
            let d = Math.sqrt(x * x + y * y);
            if (d < R + 0.12 + rm * 0.5) {
                this.mOn[j] = false;
                this.impact(api, deg(Math.atan2(y, x)), x, y, j >= NSMALL);
                continue;
            }
            // gone far past the frame (a split half flung away)
            if (Math.abs(x) > 9.5 || Math.abs(y) > 7) this.mOn[j] = false;
        }
    }

    impact(api: GameApi, a: f64, x: f64, y: f64, big: bool): void {
        this.burst(x, y, big ? 0.9 : 0.65);
        this.debris(api, x, y, 3, 0, 0);
        let k = this.nextPuff;
        this.nextPuff = (k + 1) % NPUFF;
        this.pT[k] = this.t; this.pA[k] = a;
        this.shake = this.t;
        for (let i = 0; i < 4; i++) {
            let off = Math.abs(wrap180(a - this.hAng[i]));
            if (this.hAlive[i] && off < 24 && this.state == PLAY) {
                this.hAlive[i] = false;
                this.hBorn[i] = this.t;
            } else if (this.hAlive[i] && off < 60) {
                this.hShake[i] = this.t;
            }
        }
        if (this.state == PLAY) {
            let alive = 0;
            for (let i = 0; i < 4; i++) if (this.hAlive[i]) alive++;
            if (alive == 0) {
                this.state = OVER;
                this.overT = this.t;
                this.wantFire = false;
            }
        }
    }

    // ------------------------------------------------------------ the demo player

    think(api: GameApi): void {
        if (this.runT < this.aiNext) return;
        // the most urgent meteor that has been on screen a moment (a reaction time)
        let best = -1;
        let bestT = 1e9;
        for (let j = 0; j < NMET; j++) {
            if (!this.mOn[j] || this.t - this.mBorn[j] < 0.25) continue;
            // a person waits until it is well inside the frame and coming close
            if (Math.abs(this.mX[j]) > 5.6 || Math.abs(this.mY[j]) > 3.7) continue;
            let dc = Math.sqrt(this.mX[j] * this.mX[j] + this.mY[j] * this.mY[j]);
            if (dc > 4.8 && this.runT > 1.0) continue;
            let d = Math.sqrt(this.mX[j] * this.mX[j] + this.mY[j] * this.mY[j]);
            let v = Math.sqrt(this.mVX[j] * this.mVX[j] + this.mVY[j] * this.mVY[j]);
            let tt = (d - R) / Math.max(0.1, v);
            if (tt < bestT) { bestT = tt; best = j; }
        }
        if (best < 0) {
            this.aiNext = this.runT + 0.15;
            return;
        }
        // lead: where the meteor will be when a bolt from the muzzle gets there (two passes)
        let a = rad(this.satA);
        let mx = Math.cos(a) * (RS + MUZZLE), my = Math.sin(a) * (RS + MUZZLE);
        let x = this.mX[best], y = this.mY[best];
        for (let it = 0; it < 2; it++) {
            let dd = Math.sqrt((x - mx) * (x - mx) + (y - my) * (y - my));
            let tt = dd / BOLT_SPEED + 0.12;            // plus the turn
            x = this.mX[best] + this.mVX[best] * tt;
            y = this.mY[best] + this.mVY[best] * tt;
        }
        // a human hand: a small aim error, now and then a clear miss
        let err = api.rand() < 0.22 ? api.range(0.5, 0.9) : api.range(0, 0.2);
        let ea = api.range(0, Math.PI * 2);
        x += Math.cos(ea) * err; y += Math.sin(ea) * err;
        this.aimAt(x, y, true);
        // the cadence of someone clicking: slower when nothing is close, and slower as they tire
        let pace = bestT < 2.0 ? api.range(0.28, 0.5) : api.range(0.45, 0.8);
        this.aiNext = this.runT + pace * (1 + this.runT * 0.006);
    }

    // ------------------------------------------------------------ drawing the world

    drawWorld(api: GameApi): void {
        let t = this.t;
        // the satellite: on its orbit, barrel out; recoil (dips in, squashes) after a shot, reels when hit
        let ks = t - this.lastShot;
        let recoil = ks < 0.16 ? Math.sin(ks / 0.16 * Math.PI) : 0;
        let bob = Math.sin(t * 2.3) * 0.04;
        let rr = RS - recoil * 0.14 + bob;
        let kst = t - this.stun;
        let reel = kst < 0.6 ? Math.sin(kst * 30) * 25 * (1 - kst / 0.6) : 0;
        let droop = this.state == OVER ? Math.min(1, (t - this.overT) * 1.5) : 0;
        let a = this.satA + reel;
        let sa = rad(a);
        this.placeRoll(api, this.sat, Math.cos(sa) * rr, Math.sin(sa) * rr, 0.3,
            a - 90 + droop * 25, 1 + recoil * 0.12, 1 - recoil * 0.16, 1);
        if (ks < 0.07) {
            let mr = rr + MUZZLE + 0.12;
            this.placeRoll(api, this.flash, Math.cos(sa) * mr, Math.sin(sa) * mr, 0.4, a + 45 * Math.floor(ks * 60),
                1, 1, 1);
        } else {
            api.hide(this.flash);
        }

        // houses: pop in with an overshoot, wobble when a meteor lands near, rubble when flattened
        for (let i = 0; i < 4; i++) {
            let ha = rad(this.hAng[i]);
            let hx = Math.cos(ha) * (R - 0.06), hy = Math.sin(ha) * (R - 0.06);
            let roll = this.hAng[i] - 90;
            if (this.hAlive[i]) {
                let kb = t - this.hBorn[i];
                let sx = 1.0, sy = 1.0;
                if (kb < 0) {
                    api.hide(this.house[i]);
                } else {
                    if (kb < 0.35) {
                        let u = kb / 0.35;
                        sy = Math.min(1.0, u * 1.6) + Math.sin(u * Math.PI) * 0.25;
                        sx = Math.min(1.0, 0.4 + u * 1.2) - Math.sin(u * Math.PI) * 0.1;
                    }
                    let kh = t - this.hShake[i];
                    if (kh < 0.4) {
                        let w = Math.sin(kh * 40) * (1 - kh / 0.4);
                        sy *= 1 - w * 0.15; sx *= 1 + w * 0.1;
                    }
                    this.placeRoll(api, this.house[i], hx, hy, 0, roll, sx, sy, sx);
                }
                api.hide(this.rubble[i]);
            } else {
                api.hide(this.house[i]);
                let kb = t - this.hBorn[i];
                let s = kb < 0.2 ? 0.5 + kb * 2.5 : 1.0;
                this.placeRoll(api, this.rubble[i], hx, hy, 0, roll, s, s, s);
            }
        }

        // meteors and their tails (the tail flickers in length at 12 fps)
        for (let j = 0; j < NMET; j++) {
            if (!this.mOn[j]) {
                api.hide(this.metB[j]);
                api.hide(this.trailB[j]);
                continue;
            }
            let x = this.mX[j], y = this.mY[j];
            let kh = t - this.mHit[j];
            let s = kh < 0.12 ? 0.7 + kh * 2.5 : 1.0;
            api.place(this.metB[j], x, y, 0, this.mSpin[j] * 0.7, this.mSpin[j], this.mSpin[j] * 0.4, s);
            let tr = deg(Math.atan2(-this.mVY[j], -this.mVX[j])) - 90;
            let step = Math.floor(t * 12 + <f64>j * 3);
            let flick = 0.85 + 0.15 * Math.abs(Math.sin(step * 1.7));
            let big = j >= NSMALL ? 1.05 : 0.8;
            this.placeRoll(api, this.trailB[j], x, y, -0.1, tr, big, big * flick, big);
        }

        // bolts, stretched along their flight
        for (let i = 0; i < NBOLT; i++) {
            if (!this.bOn[i]) {
                api.hide(this.boltB[i]);
                continue;
            }
            let r = deg(Math.atan2(this.bVY[i], this.bVX[i])) - 90;
            this.placeRoll(api, this.boltB[i], this.bX[i], this.bY[i], 0.2, r, 0.9, 1.15, 0.9);
        }

        // bursts: a quick pop (grow to full, then shrink away), stepped
        for (let i = 0; i < NBURST; i++) {
            let k = t - this.uT[i];
            if (k < 0 || k > 0.28) {
                api.hide(this.burstB[i]);
                continue;
            }
            let ks2 = Math.floor(k * 30) / 30;
            let s = ks2 < 0.08 ? 0.35 + ks2 / 0.08 * 0.65 : 1.0 - (ks2 - 0.08) / 0.2 * 0.9;
            s *= this.uS[i];
            this.placeRoll(api, this.burstB[i], this.uX[i], this.uY[i], 0.3, ks2 * 200, s, s, s);
        }

        // debris: flung out, slowing, tumbling, shrinking
        for (let i = 0; i < NDEBRIS; i++) {
            let k = t - this.dT[i];
            if (k < 0 || k > 0.7) {
                api.hide(this.debrisB[i]);
                continue;
            }
            let slow = (1 - Math.exp(-k * 3)) / 3;
            let x = this.dX[i] + this.dVX[i] * slow, y = this.dY[i] + this.dVY[i] * slow;
            let s = k > 0.45 ? 1 - (k - 0.45) / 0.25 * 0.7 : 1;
            api.place(this.debrisB[i], x, y, 0.2, k * 500, k * 300, <f64>i * 40, s);
        }

        // dust puffs on the planet where a meteor struck
        for (let i = 0; i < NPUFF; i++) {
            let k = t - this.pT[i];
            if (k < 0 || k > 0.7) {
                api.hide(this.puffB[i]);
                continue;
            }
            let pa = rad(this.pA[i]);
            let rise = R - 0.1 + k * 0.5;
            let s = k < 0.15 ? 0.5 + k / 0.15 * 0.5 : 1 - (k - 0.15) / 0.55 * 0.8;
            this.placeRoll(api, this.puffB[i], Math.cos(pa) * rise, Math.sin(pa) * rise, 0.3, this.pA[i] - 90,
                s * 1.1, s * 0.9, s);
        }
    }

    // ------------------------------------------------------------ input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (!this.toPlane(api, x, y)) return true;
        if (kind == POINTER_MOVE) {
            if (this.state != OVER) this.aimAt(this.px, this.py, false);
            return true;
        }
        if (kind == POINTER_DOWN) {
            if (this.state == OVER) {
                if (this.t - this.overT > 0.8) {
                    this.reset(api, true);
                    this.begin(api);
                }
                return true;
            }
            if (this.state == READY) this.begin(api);
            this.aimAt(this.px, this.py, true);
        }
        return true;
    }

    // ------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let ink = api.rampColor(0, 0);          // #0d001a
        let hi = api.rampColor(7, 1);           // #6ceded
        let mid = api.rampColor(7, 0);          // #6cb9c9
        let dim = api.rampColor(8, 0);          // #6d85a5
        let warm = api.rampColor(3, 4);         // #6e5181
        api.text(4, 4, "SCORE " + this.score.toString(), hi, 2, ink);
        let b = "BEST " + (api.demo ? this.demoBest : this.best).toString();
        api.text(<f32>api.hudW - api.textWidth(b, 1) - 4, 4, b, mid, 1, ink);
        // houses left, as small blocks under the best score
        for (let i = 0; i < 4; i++) {
            let c = this.hAlive[i] ? mid : warm;
            api.rect(<f32>api.hudW - 4 - <f32>(4 - i) * 5 + 1, 12, 3, 3, c);
        }
        // floating +1s where meteors popped
        for (let i = 0; i < NLABEL; i++) {
            let k = this.t - this.lT[i];
            if (k < 0 || k > 0.7) continue;
            if (api.project(<f32>this.lX[i], <f32>this.lY[i], 0)) {
                let yy = api.screenY - 6 - <f32>Math.floor(k * 14);
                api.text(api.screenX - 3, yy, this.lS[i], k < 0.5 ? hi : mid, 1, ink);
            }
        }
        let h = <f32>api.hudH;
        if (this.state == READY) {
            api.textCentered(h - 12, "CLICK TO FIRE AT THE METEORS", hi, 1, ink);
        } else if (this.state == PLAY && this.runT < 3.5 && !api.demo) {
            api.textCentered(h - 12, "SAVE THE HOUSES!", mid, 1, ink);
        } else if (this.state == OVER) {
            let k = this.t - this.overT;
            if (k > 0.3) {
                api.textCentered(h * 0.5 - 22, "GAME OVER", hi, 2, ink);
                api.textCentered(h * 0.5 - 8, "SCORE " + this.score.toString(), mid, 1, ink);
                if (!api.demo && k > 0.8) api.textCentered(h - 12, "CLICK TO PLAY AGAIN", hi, 1, ink);
            }
        }
        if (api.demo) api.text(4, h - 9, "DEMO", dim, 1, ink);
    }
}
