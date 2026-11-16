// Planet Hop: a little rocket orbits a planet; click to let go and fly off along the tangent. Fly into
// the next planet's pull (the dotted ring) and it catches you in a new orbit. One verb (click), one
// endless chain of planets. An orbit decays after a few seconds (the rocket sinks towards the ground),
// and a rocket that misses every ring is lost in space: game over. Stars on the way are a bonus.
// Demo mode (api.demo) flies itself: it times its launches by looking ahead along the tangent, with a
// little error, and now and then lets go too early or too late.
import { GameApi, POINTER_DOWN } from "./game_api";

const TEX: f64 = 10.0 / 136.0;   // the texel (orthoHeight / art rows): the world scrolls in whole texels
const NP: i32 = 6;               // planet bones, used in turn
const NS: i32 = 3;               // collectable stars
const NPUFF: i32 = 8;
const NSPARK: i32 = 8;
const NCHUNK: i32 = 6;
const PR: f64 = 1.5;             // the planets' baked radius
const ROCKET_HALF: f64 = 0.7;    // the rocket's pivot is its base; its middle is 0.7 m up its axis
const MAXK: i32 = 64;            // planets remembered (a ring buffer by absolute index)

const MODE_READY: i32 = 0;       // orbiting the home planet, waiting for the first click
const MODE_ORBIT: i32 = 1;
const MODE_FLY: i32 = 2;
const MODE_OVER: i32 = 3;

const NAMES: StaticArray<string> = ["meadow", "dune", "ice", "mushroom", "lava", "giant"];
const TITLES: StaticArray<string> = ["MEADOW", "DUNE", "ICE", "MUSHROOM", "LAVA", "GIANT"];

function clamp(v: f64, a: f64, b: f64): f64 {
    return v < a ? a : (v > b ? b : v);
}

export class Game {
    pBone: StaticArray<i32> = new StaticArray<i32>(NP);
    rocket: i32 = -1;
    flame: i32 = -1;
    star: StaticArray<i32> = new StaticArray<i32>(NS);
    puff: StaticArray<i32> = new StaticArray<i32>(NPUFF);
    spark: StaticArray<i32> = new StaticArray<i32>(NSPARK);
    chunk: StaticArray<i32> = new StaticArray<i32>(NCHUNK);
    sky0: i32 = -1;
    sky1: i32 = -1;
    neb0: i32 = -1;
    neb1: i32 = -1;

    // planets by absolute index k (k % MAXK): centre, scale, spin
    px: StaticArray<f64> = new StaticArray<f64>(MAXK);
    py: StaticArray<f64> = new StaticArray<f64>(MAXK);
    ps: StaticArray<f64> = new StaticArray<f64>(MAXK);
    pSpin: StaticArray<f64> = new StaticArray<f64>(MAXK);
    pRot: StaticArray<f64> = new StaticArray<f64>(MAXK);
    pPop: StaticArray<f64> = new StaticArray<f64>(MAXK);   // a squash when the rocket arrives
    built: i32 = 0;            // planets 0..built-1 exist
    cur: i32 = 0;              // the planet the rocket orbits (or last left)

    // stars: the gap they sit in (between planet g and g+1), position, taken
    sGap: StaticArray<i32> = new StaticArray<i32>(NS);
    sx: StaticArray<f64> = new StaticArray<f64>(NS);
    sy: StaticArray<f64> = new StaticArray<f64>(NS);
    sOn: StaticArray<bool> = new StaticArray<bool>(NS);

    mode: i32 = MODE_READY;
    t: f64 = 0;                // seconds in this mode
    // the rocket: in orbit, polar about planet cur (ang, rad, angular speed w); in flight, x y vx vy
    ang: f64 = 0;
    rad: f64 = 2.5;
    w: f64 = 1.9;
    wDir: f64 = 1;
    rx: f64 = 0;
    ry: f64 = 0;
    vx: f64 = 0;
    vy: f64 = 0;
    heading: f64 = 0;          // radians, the way the nose points
    stretch: f64 = 0;          // 1 at a launch, decays
    squash: f64 = 0;           // 1 at a capture, decays
    orbitT: f64 = 0;           // seconds in this orbit (the decay clock)
    hold: f64 = 6;             // seconds an orbit lasts before the rocket touches down

    score: i32 = 0;
    best: i32 = 0;
    hops: i32 = 0;
    stars: i32 = 0;
    reason: string = "";

    camX: f64 = 0;
    camY: f64 = 0;
    qx: f64 = 0;               // the camera snapped to whole texels
    qy: f64 = 0;
    shake: f64 = 0;
    shakeX: f64 = 0;
    shakeY: f64 = 0;

    fX: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    fY: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    fVX: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    fVY: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    fT: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    fNext: i32 = 0;
    fTimer: f64 = 0;

    kX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    kY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    kVX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    kVY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    kT: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    kNext: i32 = 0;

    cX: StaticArray<f64> = new StaticArray<f64>(NCHUNK);
    cY: StaticArray<f64> = new StaticArray<f64>(NCHUNK);
    cVX: StaticArray<f64> = new StaticArray<f64>(NCHUNK);
    cVY: StaticArray<f64> = new StaticArray<f64>(NCHUNK);
    cR: StaticArray<f64> = new StaticArray<f64>(NCHUNK);
    cOn: bool = false;

    popText: string = "";
    popText2: string = "";
    popT: f64 = 9;
    popX: f64 = 0;
    popY: f64 = 0;

    demoF: f64 = 0.3;          // the demo's launch tolerance this orbit (fraction of the pull radius)
    demoWait: f64 = 0;         // a demo reaction delay
    demoArmed: bool = false;

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < NP; i++) {
            this.pBone[i] = api.bone(NAMES[i]);
        }
        this.rocket = api.bone("rocket");
        this.flame = api.bone("flame");
        for (let i = 0; i < NS; i++) this.star[i] = api.bone("star" + i.toString());
        for (let i = 0; i < NPUFF; i++) { this.puff[i] = api.bone("puff" + i.toString()); this.fT[i] = 99; }
        for (let i = 0; i < NSPARK; i++) { this.spark[i] = api.bone("spark" + i.toString()); this.kT[i] = 99; }
        for (let i = 0; i < NCHUNK; i++) this.chunk[i] = api.bone("chunk" + i.toString());
        this.sky0 = api.bone("sky0");
        this.sky1 = api.bone("sky1");
        this.neb0 = api.bone("nebula0");
        this.neb1 = api.bone("nebula1");
        this.newRun(api);
    }

    // ---------------------------------------------------------------- the world

    pR(k: i32): f64 { return PR * this.ps[k % MAXK]; }                       // the ball's radius
    orbitR(k: i32): f64 { return this.pR(k) + 0.55 * this.ps[k % MAXK] + 0.75; }
    pullR(k: i32): f64 {
        let extra = clamp(1.1 - <f64>this.hops * 0.03, 0.6, 1.1);
        return this.orbitR(k) + extra;
    }

    addPlanet(api: GameApi): void {
        let k = this.built;
        let i = k % MAXK;
        if (k == 0) {
            this.px[i] = -3.2; this.py[i] = -0.6; this.ps[i] = 1.0;
        } else {
            let j = (k - 1) % MAXK;
            let s = api.range(0.72, 1.0);
            if (k % NP == 5) s = api.range(0.8, 0.95);                       // the giant's ring stays inside its pull
            this.ps[i] = s;
            let gap = api.range(1.3, 2.3) + Math.min(1.3, <f64>(k) * 0.05);
            let d = this.orbitR(k - 1) + this.orbitR(k) + gap;
            let th = api.range(-38, 38) - this.py[j] * 9;
            th = clamp(th, -42, 42) * Math.PI / 180;
            this.px[i] = this.px[j] + d * Math.cos(th);
            this.py[i] = clamp(this.py[j] + d * Math.sin(th), -2.3, 2.3);
        }
        this.pSpin[i] = (k % NP == 5) ? 0 : (api.rand() < 0.5 ? -1.0 : 1.0) * api.range(6, 13);
        this.pRot[i] = api.range(-40, 40);
        this.pPop[i] = 9;
        // a star in the gap before this planet (most gaps), a little off the straight line
        if (k >= 2 && api.rand() < 0.75) {
            let g = k - 1;
            let n = g % NS;
            let a = (g - 1) % MAXK, b = (g) % MAXK;
            let dx = this.px[b] - this.px[a], dy = this.py[b] - this.py[a];
            let dl = Math.sqrt(dx * dx + dy * dy);
            let u = (this.orbitR(g - 1) + 0.5 * (dl - this.orbitR(g - 1) - this.orbitR(g))) / dl;
            let off = api.range(-0.9, 0.9);
            this.sGap[n] = g;
            this.sx[n] = this.px[a] + dx * u - dy / dl * off;
            this.sy[n] = this.py[a] + dy * u + dx / dl * off;
            this.sOn[n] = true;
        }
        this.built++;
    }

    newRun(api: GameApi): void {
        this.built = 0;
        this.cur = 0;
        this.hops = 0;
        this.stars = 0;
        this.score = 0;
        for (let i = 0; i < NS; i++) this.sOn[i] = false;
        for (let k = 0; k < 5; k++) this.addPlanet(api);
        this.mode = api.demo ? MODE_ORBIT : MODE_READY;
        this.t = 0;
        this.wDir = 1;
        this.w = 1.75;
        this.rad = this.orbitR(0);
        // start where the tangent will point at the next planet in about half a second (demo: action
        // from the first second)
        let a = this.aimAngle(0, 1, this.wDir);
        this.ang = a - this.wDir * 0.9;
        this.orbitT = 0;
        this.hold = 6.5;
        this.squash = 0;
        this.stretch = 0;
        this.cOn = false;
        this.popT = 9;
        this.demoArm(api);
        this.camX = (this.px[0] + this.px[1]) * 0.5;
        this.camY = (this.py[0] + this.py[1]) * 0.5;
        this.updateRocketFromOrbit();
    }

    // The orbit angle at which the tangent (turning wDir) points straight at planet b.
    aimAngle(a: i32, b: i32, dir: f64): f64 {
        let dx = this.px[b % MAXK] - this.px[a % MAXK], dy = this.py[b % MAXK] - this.py[a % MAXK];
        let to = Math.atan2(dy, dx);
        let r = this.orbitR(a), d = Math.sqrt(dx * dx + dy * dy);
        // tangent at angle t (ccw): direction t + pi/2; the line from the orbit point must pass the centre:
        // at d >> r the launch angle is to - pi/2 (ccw), corrected by asin(r/d)
        return to - dir * (Math.PI / 2) + dir * Math.asin(clamp(r / d, -1, 1));
    }

    updateRocketFromOrbit(): void {
        let c = this.cur % MAXK;
        this.rx = this.px[c] + this.rad * Math.cos(this.ang);
        this.ry = this.py[c] + this.rad * Math.sin(this.ang);
        let sp = this.w * this.rad;
        this.vx = -Math.sin(this.ang) * sp * this.wDir;
        this.vy = Math.cos(this.ang) * sp * this.wDir;
        this.heading = Math.atan2(this.vy, this.vx);
    }

    // ---------------------------------------------------------------- the loop

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged) {
            this.best = 0;
            this.newRun(api);
        }
        this.t += dt;

        if (this.mode == MODE_READY || this.mode == MODE_ORBIT) {
            this.orbit(api, dt);
            if (api.demo && this.mode == MODE_ORBIT && this.demoLaunch(api, dt)) {
                this.launch(api);
            }
        } else if (this.mode == MODE_FLY) {
            this.fly(api, dt);
        } else if (this.mode == MODE_OVER) {
            if (!this.cOn) {
                // lost: the rocket drifts on out of the picture, slowly turning
                this.rx += this.vx * dt;
                this.ry += this.vy * dt;
                this.heading += dt * 1.5;
            }
            if (api.demo && this.t > 2.0) {
                this.newRun(api);
            }
        }

        // the camera: between this planet and the next while orbiting, after the rocket in flight
        let c = this.cur % MAXK, n = (this.cur + 1) % MAXK;
        let tx = (this.px[c] + this.px[n]) * 0.5, ty = (this.py[c] + this.py[n]) * 0.5;
        if (this.mode == MODE_FLY) {
            // after the rocket, but never past the next planet: a rocket that misses flies out of the picture
            tx = Math.min(this.rx + this.vx * 0.25, this.px[n] + 1.0);
            ty = clamp(this.ry * 0.5 + (this.py[c] + this.py[n]) * 0.25, Math.min(this.py[c], this.py[n]) - 1, Math.max(this.py[c], this.py[n]) + 1);
        } else if (this.mode == MODE_OVER) {
            tx = this.camX;
            ty = this.camY;
        }
        let kc = Math.min(1, dt * (this.mode == MODE_FLY ? 2.2 : 1.6));
        this.camX += (tx - this.camX) * kc;
        this.camY += (ty - this.camY) * kc;
        this.shake = Math.max(0, this.shake - dt * 0.8);
        if (Math.floor(api.time * 15) != Math.floor((api.time - dt) * 15)) {
            this.shakeX = (api.rand() - 0.5) * this.shake;
            this.shakeY = (api.rand() - 0.5) * this.shake;
        }
        this.qx = Math.round((this.camX + this.shakeX) / TEX) * TEX;
        this.qy = Math.round((this.camY + this.shakeY) / TEX) * TEX;

        this.stretch = Math.max(0, this.stretch - dt * 3.5);
        this.squash = Math.max(0, this.squash - dt * 3.0);
        this.popT += dt;
        this.updatePuffs(api, dt);
        this.updateSparks(api, dt);
        this.updateChunks(api, dt);
        this.collectStars(api);
        this.draw(api);
    }

    orbit(api: GameApi, dt: f64): void {
        // the arrival: the radius and the turn settle onto this planet's orbit
        let target = this.orbitR(this.cur);
        let wT = this.mode == MODE_READY ? 1.75 : clamp(1.75 + <f64>this.hops * 0.06, 1.75, 2.9);
        this.w += (wT - this.w) * Math.min(1, dt * 3);
        if (this.mode == MODE_ORBIT) {
            this.orbitT += dt;
            let decayStart = this.hold * 0.45;
            if (this.orbitT > decayStart) {
                let u = (this.orbitT - decayStart) / (this.hold - decayStart);
                target = target - u * (target - this.pR(this.cur) - 0.62 * this.ps[this.cur % MAXK]);
            }
        }
        this.rad += (target - this.rad) * Math.min(1, dt * 5);
        this.ang += this.wDir * this.w * dt;
        this.updateRocketFromOrbit();
        if (this.mode == MODE_ORBIT && this.orbitT >= this.hold) {
            this.reason = "THE ORBIT DECAYED";
            this.crash(api);
        }
    }

    launch(api: GameApi): void {
        this.mode = MODE_FLY;
        this.t = 0;
        let sp = this.w * this.rad * 1.18 + 1.2;
        let d = Math.sqrt(this.vx * this.vx + this.vy * this.vy);
        this.vx = this.vx / d * sp;
        this.vy = this.vy / d * sp;
        this.stretch = 1;
        this.fTimer = 0;
    }

    fly(api: GameApi, dt: f64): void {
        // the pull of the planets ahead bends the path a little near their rings
        let ax: f64 = 0, ay: f64 = 0;
        for (let k = this.cur + 1; k < this.built; k++) {
            let i = k % MAXK;
            let dx = this.px[i] - this.rx, dy = this.py[i] - this.ry;
            let d2 = dx * dx + dy * dy, d = Math.sqrt(d2);
            let pr = this.pullR(k);
            if (d < pr * 1.7) {
                let g = 7.0 * this.ps[i] / Math.max(d2, 1.0);
                ax += dx / d * g;
                ay += dy / d * g;
            }
        }
        this.vx += ax * dt;
        this.vy += ay * dt;
        this.rx += this.vx * dt;
        this.ry += this.vy * dt;
        this.heading = Math.atan2(this.vy, this.vx);
        // caught by a pull ring ahead?
        for (let k = this.cur + 1; k < this.built; k++) {
            let i = k % MAXK;
            let dx = this.rx - this.px[i], dy = this.ry - this.py[i];
            let d = Math.sqrt(dx * dx + dy * dy);
            if (d < this.pullR(k)) {
                this.capture(api, k, dx, dy, d);
                return;
            }
        }
        // hitting a planet behind (flying back through it)
        for (let k = max<i32>(0, this.cur - 1); k <= this.cur; k++) {
            let i = k % MAXK;
            let dx = this.rx - this.px[i], dy = this.ry - this.py[i];
            if (dx * dx + dy * dy < (this.pR(k) + 0.25) * (this.pR(k) + 0.25)) {
                this.reason = "CRASHED INTO " + TITLES[k % NP];
                this.crash(api);
                return;
            }
        }
        if (this.t > 3.0 || Math.abs(this.rx - this.camX) > 9.6 || Math.abs(this.ry - this.camY) > 6.2) {
            this.reason = "LOST IN SPACE";
            this.over(api);
        }
    }

    capture(api: GameApi, k: i32, dx: f64, dy: f64, d: f64): void {
        let skipped = k - this.cur;
        this.cur = k;
        this.mode = MODE_ORBIT;
        this.t = 0;
        this.orbitT = 0;
        this.hold = clamp(6.5 - <f64>this.hops * 0.12, 4.2, 6.5);
        let cross = dx * this.vy - dy * this.vx;
        this.wDir = cross >= 0 ? 1 : -1;
        this.ang = Math.atan2(dy, dx);
        this.rad = d;
        this.w = Math.abs(cross) / (d * d);
        this.hops += skipped;
        let pts = skipped == 1 ? 1 : skipped * 2;
        this.score += pts;
        if (this.score > this.best) this.best = this.score;
        this.squash = 1;
        this.pPop[k % MAXK] = 0;
        this.popText = "+" + pts.toString();
        this.popText2 = skipped > 1 ? "SKIP!" : TITLES[k % NP];
        this.popT = 0;
        this.popX = this.px[k % MAXK];
        this.popY = this.py[k % MAXK] + this.pR(k) + 0.6;
        this.burst(api, this.rx, this.ry, 4);
        while (this.built < this.cur + 4) this.addPlanet(api);
        this.demoArm(api);
    }

    crash(api: GameApi): void {
        this.cOn = true;
        for (let i = 0; i < NCHUNK; i++) {
            this.cX[i] = this.rx + api.range(-0.3, 0.3);
            this.cY[i] = this.ry + api.range(-0.3, 0.3);
            let a = api.range(0, 2 * Math.PI), s = api.range(1.5, 4.0);
            this.cVX[i] = Math.cos(a) * s + this.vx * 0.2;
            this.cVY[i] = Math.sin(a) * s + this.vy * 0.2;
            this.cR[i] = api.range(0, 360);
        }
        this.burst(api, this.rx, this.ry, 8);
        this.shake = 0.5;
        this.over(api);
    }

    over(api: GameApi): void {
        this.mode = MODE_OVER;
        this.t = 0;
        if (this.score > this.best) this.best = this.score;
    }

    collectStars(api: GameApi): void {
        if (this.mode == MODE_OVER || (this.mode == MODE_READY)) return;
        for (let i = 0; i < NS; i++) {
            if (!this.sOn[i]) continue;
            let dx = this.rx - this.sx[i], dy = this.ry - this.sy[i];
            if (dx * dx + dy * dy < 0.9 * 0.9) {
                this.sOn[i] = false;
                this.stars++;
                this.score += 1;
                if (this.score > this.best) this.best = this.score;
                this.popText = "+1";
                this.popText2 = "STAR!";
                this.popT = 0;
                this.popX = this.sx[i];
                this.popY = this.sy[i] + 0.7;
                this.burst(api, this.sx[i], this.sy[i], 5);
            }
        }
    }

    // ---------------------------------------------------------------- effects

    burst(api: GameApi, x: f64, y: f64, n: i32): void {
        for (let j = 0; j < n; j++) {
            let k = this.kNext;
            this.kNext = (this.kNext + 1) % NSPARK;
            let a = api.range(0, 2 * Math.PI), s = api.range(2.0, 4.2);
            this.kX[k] = x; this.kY[k] = y;
            this.kVX[k] = Math.cos(a) * s; this.kVY[k] = Math.sin(a) * s;
            this.kT[k] = 0;
        }
    }

    updatePuffs(api: GameApi, dt: f64): void {
        this.fTimer -= dt;
        if (this.mode == MODE_FLY && this.fTimer <= 0) {
            this.fTimer = 0.07;
            let k = this.fNext;
            this.fNext = (this.fNext + 1) % NPUFF;
            let hx = Math.cos(this.heading), hy = Math.sin(this.heading);
            this.fX[k] = this.rx - hx * 0.85 + api.range(-0.08, 0.08);
            this.fY[k] = this.ry - hy * 0.85 + api.range(-0.08, 0.08);
            this.fVX[k] = -hx * 0.6 + api.range(-0.3, 0.3);
            this.fVY[k] = -hy * 0.6 + api.range(-0.3, 0.3);
            this.fT[k] = 0;
        }
        for (let i = 0; i < NPUFF; i++) {
            if (this.fT[i] > 0.6) {
                api.hide(this.puff[i]);
                continue;
            }
            this.fT[i] += dt;
            this.fX[i] += this.fVX[i] * dt;
            this.fY[i] += this.fVY[i] * dt;
            let u = this.fT[i] / 0.6;
            let s = u < 0.25 ? 0.6 + u * 2.0 : 1.1 * (1 - (u - 0.25) / 0.75) + 0.1;
            s = Math.floor(s * 6) / 6;   // stepped: reads hand-animated
            if (s < 0.2) {
                api.hide(this.puff[i]);
                continue;
            }
            api.place(this.puff[i], this.fX[i] - this.qx, this.fY[i] - this.qy, -0.3, 0, 0, 0, s);
        }
    }

    updateSparks(api: GameApi, dt: f64): void {
        for (let i = 0; i < NSPARK; i++) {
            if (this.kT[i] > 0.5) {
                api.hide(this.spark[i]);
                continue;
            }
            this.kT[i] += dt;
            this.kX[i] += this.kVX[i] * dt;
            this.kY[i] += this.kVY[i] * dt;
            this.kVX[i] *= Math.exp(-dt * 3);
            this.kVY[i] *= Math.exp(-dt * 3);
            let s = this.kT[i] < 0.3 ? 1.0 : 0.6;
            api.place(this.spark[i], this.kX[i] - this.qx, this.kY[i] - this.qy, 0.6, 0, 0, 45, s);
        }
    }

    updateChunks(api: GameApi, dt: f64): void {
        for (let i = 0; i < NCHUNK; i++) {
            if (!this.cOn || this.t > 1.6) {
                api.hide(this.chunk[i]);
                continue;
            }
            this.cX[i] += this.cVX[i] * dt;
            this.cY[i] += this.cVY[i] * dt;
            this.cR[i] += 400 * dt;
            let s = this.t > 1.2 ? 0.6 : 1.0;
            api.place(this.chunk[i], this.cX[i] - this.qx, this.cY[i] - this.qy, 0.3, this.cR[i] * 0.5, 0, this.cR[i], s);
        }
    }

    // ---------------------------------------------------------------- the demo pilot

    demoArm(api: GameApi): void {
        let r = api.rand();
        // most launches near the middle of the window; about one in nine early or late (a miss,
        // unless a pull saves it)
        this.demoF = r < 0.11 ? api.range(1.15, 1.45) : api.range(0.05, 0.55);
        this.demoWait = 0;
        this.demoArmed = false;
    }

    // Looks ahead along the tangent (with the pulls): would a launch now be caught by the next planet,
    // and how close to its middle does the path pass?
    predict(): f64 {
        let x = this.rx, y = this.ry;
        let sp = this.w * this.rad * 1.18 + 1.2;
        let d0 = Math.sqrt(this.vx * this.vx + this.vy * this.vy);
        let vx = this.vx / d0 * sp, vy = this.vy / d0 * sp;
        let k = this.cur + 1;
        let i = k % MAXK;
        let best: f64 = 99;
        let h: f64 = 1.0 / 30.0;
        for (let s = 0; s < 75; s++) {
            let dx = this.px[i] - x, dy = this.py[i] - y;
            let d = Math.sqrt(dx * dx + dy * dy);
            if (d < best) best = d;
            if (d < this.pullR(k) * 1.7) {
                let g = 7.0 * this.ps[i] / Math.max(d * d, 1.0);
                vx += dx / d * g * h;
                vy += dy / d * g * h;
            }
            x += vx * h;
            y += vy * h;
        }
        return best / this.pullR(k);
    }

    demoLaunch(api: GameApi, dt: f64): bool {
        if (this.t < 0.25) return false;
        let f = this.predict();
        if (!this.demoArmed) {
            if (f < this.demoF) {
                this.demoArmed = true;
                this.demoWait = api.range(0.0, 0.06);
            }
            return false;
        }
        this.demoWait -= dt;
        return this.demoWait <= 0;
    }

    // ---------------------------------------------------------------- drawing

    draw(api: GameApi): void {
        // the planets near the camera; the others hidden
        for (let b = 0; b < NP; b++) api.hide(this.pBone[b]);
        let lo = max<i32>(0, this.cur - 2), hi = this.built - 1;
        for (let k = lo; k <= hi; k++) {
            if (k < this.built - NP) continue;
            let i = k % MAXK;
            this.pRot[i] += this.pSpin[i] * api.dt;
            this.pPop[i] += api.dt;
            let s = this.ps[i];
            let sx = s, sy = s;
            if (this.pPop[i] < 0.35) {
                let q = Math.sin(this.pPop[i] / 0.35 * Math.PI) * 0.07;
                sx = s * (1 + q);
                sy = s * (1 - q);
            }
            let x = this.px[i] - this.qx, y = this.py[i] - this.qy;
            if (Math.abs(x) > 14) continue;
            api.placeScaled(this.pBone[k % NP], x, y, 0, 0, sx, sy, s, 0, this.pRot[i]);
        }
        // the stars to collect: they turn and bob
        for (let n = 0; n < NS; n++) {
            if (!this.sOn[n] || this.sGap[n] < this.cur - 1) {
                api.hide(this.star[n]);
                continue;
            }
            let bob = Math.sin(api.time * 3 + <f64>n) * 0.12;
            // turns in the play plane in stepped 12-degree ticks, and pulses
            let tick = Math.floor(api.time * 8);
            let pulse = tick % 4 == 0 ? 1.12 : 1.0;
            api.place(this.star[n], this.sx[n] - this.qx, this.sy[n] + bob - this.qy, 0.2, 0, 0, tick * 12 + <f64>n * 30, pulse);
        }
        // the sky: two tiles of stars (parallax 0.15) and of nebula (0.35), leapfrogging
        this.tiles(api, this.sky0, this.sky1, 0.15, -12);
        this.tiles(api, this.neb0, this.neb1, 0.35, -11);

        // the rocket: nose along its heading; a stretch at launch, a squash at capture
        if (this.mode == MODE_OVER && this.cOn) {
            api.hide(this.rocket);
            api.hide(this.flame);
            return;
        }
        let hx = Math.cos(this.heading), hy = Math.sin(this.heading);
        let roll = this.heading * 180 / Math.PI - 90;
        let st = Math.sin(Math.min(1, this.stretch) * Math.PI * 0.5) * 0.22 * this.stretch;
        let sq = Math.sin(Math.min(1, this.squash) * Math.PI) * 0.16;
        let ly = 1 + st - sq, lx = 1 - st * 0.4 + sq * 0.5;
        let dec = this.decay();
        // a rocket sinking out of a decaying orbit shudders (stepped, whole texels)
        let jit = dec > 0.3 && Math.floor(api.time * 20) % 2 == 0 ? TEX * (dec > 0.7 ? 1.0 : 0.6) : 0;
        let bx = this.rx - hx * ROCKET_HALF * ly - this.qx + jit * hy;
        let by = this.ry - hy * ROCKET_HALF * ly - this.qy - jit * hx;
        api.placeScaled(this.rocket, bx, by, 0, 0, lx, ly, lx, 0, roll);
        let flying = this.mode == MODE_FLY;
        let k = Math.floor(api.time * 12);
        let fl = 0.75 + 0.3 * <f64>((<i32>k * 7919) % 5) / 4.0;
        let fs = flying ? fl * (1.0 + this.stretch * 0.5) : (this.mode == MODE_READY ? 0.0 : fl * 0.45);
        if (fs < 0.2) {
            api.hide(this.flame);
        } else {
            api.placeScaled(this.flame, bx + hx * 0.06, by + hy * 0.06, 0, 0, 0.9, fs, 0.9, 0, roll);
        }
    }

    decay(): f64 {
        if (this.mode != MODE_ORBIT) return 0;
        let s = this.hold * 0.45;
        return this.orbitT > s ? (this.orbitT - s) / (this.hold - s) : 0;
    }

    // The sky's two tiles (20 m wide, baked at x 0) leapfrog with parallax f, in whole texels.
    tiles(api: GameApi, a: i32, b: i32, f: f64, z: f64): void {
        let ox = this.qx * f, oy = this.qy * f * 0.5;
        let base = Math.round(-(ox - Math.floor(ox / 20) * 20) / TEX) * TEX;
        let y = Math.round(-oy / TEX) * TEX;
        api.place(a, base, y, z);
        api.place(b, base + 20, y, z);
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind != POINTER_DOWN) return true;
        if (this.mode == MODE_READY) {
            this.mode = MODE_ORBIT;
            this.launch(api);
        } else if (this.mode == MODE_ORBIT) {
            this.launch(api);
        } else if (this.mode == MODE_OVER && this.t > 0.6) {
            this.newRun(api);
        }
        return true;
    }

    // ---------------------------------------------------------------- HUD

    // A dashed circle at planet k's pull radius: n dashes (two fifths of the circle drawn), turning with phase.
    ring(api: GameApi, k: i32, col: u32, n: i32, phase: f64): void {
        let i = k % MAXK;
        let r = this.pullR(k);
        let cx = this.px[i] - this.qx, cy = this.py[i] - this.qy;
        for (let j = 0; j < n; j++) {
            let a0 = phase + <f64>j * 2 * Math.PI / <f64>n;
            let a1 = a0 + 0.8 * Math.PI / <f64>n;
            if (!api.project(<f32>(cx + r * Math.cos(a0)), <f32>(cy + r * Math.sin(a0)), 0)) continue;
            let x0 = api.screenX, y0 = api.screenY;
            if (!api.project(<f32>(cx + r * Math.cos(a1)), <f32>(cy + r * Math.sin(a1)), 0)) continue;
            api.line(x0, y0, api.screenX, api.screenY, col);
        }
    }

    hud(api: GameApi): void {
        let white = api.paletteColor(6);
        let ink = api.paletteColor(1);
        let cyan = api.paletteColor(7);
        let gold = api.paletteColor(26);
        let pink = api.paletteColor(28);
        let W = <f32>api.hudW, H = <f32>api.hudH;

        // the next planet's pull: a dashed ring, turning
        if (this.mode != MODE_OVER) {
            let ph = api.time * 0.6;
            this.ring(api, this.cur + 1, cyan, 22, ph);
        }
        // the aim: dots along the tangent while in orbit
        if (this.mode == MODE_READY || this.mode == MODE_ORBIT) {
            let hx = Math.cos(this.heading), hy = Math.sin(this.heading);
            let n = this.mode == MODE_READY ? 5 : 3;
            for (let j = 1; j <= n; j++) {
                let d = 0.9 + <f64>j * 0.55;
                if (api.project(<f32>(this.rx + hx * d - this.qx), <f32>(this.ry + hy * d - this.qy), 0)) {
                    api.rect(Mathf.round(api.screenX), Mathf.round(api.screenY), 1, 1, j == 1 ? white : cyan);
                }
            }
        }
        // a decaying orbit: a blinking warning over the rocket
        let dec = this.decay();
        if (dec > 0.05 && Math.floor(api.time * (dec > 0.6 ? 8 : 4)) % 2 == 0) {
            if (api.project(<f32>(this.rx - this.qx), <f32>(this.ry - this.qy + 1.1), 0)) {
                api.text(api.screenX - 1, api.screenY - 3, "!", pink, 1, ink);
            }
        }

        api.text(4, 4, "SCORE " + this.score.toString(), white, 1, ink);
        let bs = "BEST " + this.best.toString();
        api.text(W - 4 - api.textWidth(bs, 1), 4, bs, gold, 1, ink);
        if (this.stars > 0) {
            api.text(4, 12, "* " + this.stars.toString(), gold, 1, ink);
        }
        if (api.demo) {
            api.textCentered(4, "DEMO", cyan, 1, ink);
        }

        if (this.popT < 1.2) {
            if (api.project(<f32>(this.popX - this.qx), <f32>(this.popY - this.qy + this.popT * 0.7), 0)) {
                let x = Mathf.round(api.screenX - api.textWidth(this.popText, 2) * 0.5);
                api.text(x, api.screenY - 6, this.popText, gold, 2, ink);
                let x2 = Mathf.round(api.screenX - api.textWidth(this.popText2, 1) * 0.5);
                api.text(x2, api.screenY + 6, this.popText2, white, 1, ink);
            }
        }

        if (this.mode == MODE_READY && !api.demo) {
            api.rect(W * 0.5 - 66, H - 26, 132, 20, ink);
            api.textCentered(H - 23, "CLICK TO LAUNCH", white, 1, 0);
            api.textCentered(H - 15, "FLY INTO THE NEXT PLANET'S PULL", cyan, 1, 0);
        }
        if (this.mode == MODE_OVER) {
            let y: f32 = 34;
            api.rect(W * 0.5 - 70, y - 6, 140, this.t > 0.6 && !api.demo ? 52 : 42, ink);
            api.textCentered(y, this.reason == "LOST IN SPACE" ? "LOST IN SPACE!" : "CRASHED!", pink, 2, ink);
            if (this.reason != "LOST IN SPACE") api.textCentered(y + 14, this.reason, white, 1, ink);
            api.textCentered(y + 24, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), gold, 1, ink);
            if (!api.demo && this.t > 0.6) api.textCentered(y + 34, "CLICK TO FLY AGAIN", white, 1, ink);
        }
    }
}
