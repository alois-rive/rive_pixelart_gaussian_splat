// Kite Day: a kid flies a kite over a hill at dusk. Hold the pointer to lift the kite, let go to
// let it dip; catch the stars drifting in on the wind, dodge the birds. A bird or the ground costs
// one of three hearts. Pointer only; a run starts on the first press; demo mode plays itself.
import { GameApi, POINTER_DOWN, POINTER_UP, SFX_BELL, SFX_NOTE, SFX_WHOOSH, SFX_HIT, SFX_THUD, SFX_SHOOT,
         SFX_LOSE, SFX_WIN } from "./game_api";

// sound: airy and chiming. A star is a bell climbing a pentatonic scale with the streak of stars
// caught since the last hit; the wind blows a soft gust every two seconds (higher as it picks up)
// and a press lifts with a whoosh; a gull cries as it comes in, a hit is a crunch and its cry.
const PENTA: StaticArray<i32> = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24, 26, 28, 31];

const ST_IDLE: i32 = 0;
const ST_PLAY: i32 = 1;
const ST_OVER: i32 = 2;

const NSTAR: i32 = 6;
const NBIRD: i32 = 4;
const NBOW: i32 = 5;
const NSPARK: i32 = 8;
const NCLOUD: i32 = 3;
const NPOP: i32 = 4;

const KX: f64 = -1.0;        // the kite's x (it sways a little about it)
const KZ: f64 = 0.5;         // the kite's depth (the bake's)
const YMIN: f64 = 2.6;       // below this the kite's tip touches the knoll
const YMAX: f64 = 8.4;       // the string's length
const TIP: f64 = 1.62;       // pivot (spar crossing) to the tail stub, at that scale
const SPAWN_X: f64 = 9.6;    // things enter beyond the right edge (the view is x -8..8)
const GONE_X: f64 = -9.6;
const LINK: f64 = 0.62;      // tail link length
const HAND_X: f64 = -5.74;   // the kid's raised hand (kid at -6.5, 2.62, scale 1.4)
const HAND_Y: f64 = 4.25;

// palette indices (art/palette.json "colors"): peach, pink, haze, dusk, night
const C_PEACH: i32 = 0;
const C_PINK: i32 = 1;
const C_HAZE: i32 = 2;
const C_DUSK: i32 = 3;
const C_NIGHT: i32 = 4;

export class Game {
    state: i32 = ST_IDLE;
    stateT: f64 = 0;
    runT: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    hearts: i32 = 3;
    wasDemo: bool = false;
    holding: bool = false;
    hurtT: f64 = 9;       // time since the last hit (blink while < 1.2)
    popT: f64 = 9;        // time since the last star (the kite's pop)
    lean: f64 = 0;
    streak: i32 = 0;      // stars since the last hit (the bell's step)

    kite: i32 = -1;
    kid: i32 = -1;
    bowB: StaticArray<i32> = new StaticArray<i32>(NBOW);
    starB: StaticArray<i32> = new StaticArray<i32>(NSTAR);
    birdB: StaticArray<i32> = new StaticArray<i32>(NBIRD);
    sparkB: StaticArray<i32> = new StaticArray<i32>(NSPARK);
    cloudB: StaticArray<i32> = new StaticArray<i32>(NCLOUD);

    // kite
    ky: f64 = 5.5;
    vy: f64 = 0;
    kx: f64 = KX;
    roll: f64 = 0;

    // tail (verlet chain hanging from the kite's stub)
    tx: StaticArray<f64> = new StaticArray<f64>(NBOW + 1);
    ty: StaticArray<f64> = new StaticArray<f64>(NBOW + 1);
    px: StaticArray<f64> = new StaticArray<f64>(NBOW + 1);
    py: StaticArray<f64> = new StaticArray<f64>(NBOW + 1);

    // stars: active, position, phase, popping (time since caught, < 0 not caught)
    sOn: StaticArray<bool> = new StaticArray<bool>(NSTAR);
    sX: StaticArray<f64> = new StaticArray<f64>(NSTAR);
    sY: StaticArray<f64> = new StaticArray<f64>(NSTAR);
    sPh: StaticArray<f64> = new StaticArray<f64>(NSTAR);
    sPop: StaticArray<f64> = new StaticArray<f64>(NSTAR);
    sSkip: StaticArray<bool> = new StaticArray<bool>(NSTAR);   // demo: this one is let go

    // birds: active, position, base height, phase, hit (tumbling) time
    bOn: StaticArray<bool> = new StaticArray<bool>(NBIRD);
    bX: StaticArray<f64> = new StaticArray<f64>(NBIRD);
    bY: StaticArray<f64> = new StaticArray<f64>(NBIRD);
    bBase: StaticArray<f64> = new StaticArray<f64>(NBIRD);
    bPh: StaticArray<f64> = new StaticArray<f64>(NBIRD);
    bHit: StaticArray<f64> = new StaticArray<f64>(NBIRD);
    bVY: StaticArray<f64> = new StaticArray<f64>(NBIRD);
    bBlind: StaticArray<bool> = new StaticArray<bool>(NBIRD);  // demo: this one is not noticed

    // sparks
    kT: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    kX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    kY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    kVX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    kVY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    nextSpark: i32 = 0;

    cX: StaticArray<f64> = [-4.5, 3.0, 9.5];
    cY: StaticArray<f64> = [7.9, 8.8, 6.9];

    // "+1" popups (world position, age)
    pX: StaticArray<f64> = new StaticArray<f64>(NPOP);
    pY: StaticArray<f64> = new StaticArray<f64>(NPOP);
    pT: StaticArray<f64> = new StaticArray<f64>(NPOP);
    pS: StaticArray<i32> = new StaticArray<i32>(NPOP);
    nextPop: i32 = 0;

    starT: f64 = 0;     // time to the next star group
    birdT: f64 = 0;     // time to the next bird

    // demo pilot
    aiT: f64 = 0;
    aiTarget: f64 = 5.5;
    aiErr: f64 = 0;

    // ------------------------------------------------------------------ setup

    start(api: GameApi): void {
        api.playable = true;
        this.kite = api.bone("kite");
        this.kid = api.bone("kid");
        for (let i = 0; i < NBOW; i++) this.bowB[i] = api.bone("bow" + i.toString());
        for (let i = 0; i < NSTAR; i++) this.starB[i] = api.bone("star" + i.toString());
        for (let i = 0; i < NBIRD; i++) this.birdB[i] = api.bone("bird" + i.toString());
        for (let i = 0; i < NSPARK; i++) { this.sparkB[i] = api.bone("spark" + i.toString()); this.kT[i] = -1; }
        for (let i = 0; i < NCLOUD; i++) this.cloudB[i] = api.bone("cloud" + i.toString());
        for (let i = 0; i < NPOP; i++) this.pT[i] = -1;
        this.resetTail();
        this.clearWorld();
        this.wasDemo = api.demo;
        if (api.demo) {
            this.startRun(api);
        } else {
            this.state = ST_IDLE;
            this.seedStars(api, false);
        }
    }

    private resetTail(): void {
        for (let i = 0; i <= NBOW; i++) {
            this.tx[i] = this.kx + 0.4 * <f64>i;
            this.ty[i] = this.ky - TIP - 0.45 * <f64>i;
            this.px[i] = this.tx[i];
            this.py[i] = this.ty[i];
        }
    }

    private clearWorld(): void {
        for (let i = 0; i < NSTAR; i++) { this.sOn[i] = false; this.sPop[i] = -1; }
        for (let i = 0; i < NBIRD; i++) { this.bOn[i] = false; this.bHit[i] = -1; }
    }

    // a few stars (and a bird when playing) already on their way, so the first second has action
    private seedStars(api: GameApi, bird: bool): void {
        this.addStar(api, 1.6, 6.3);
        this.addStar(api, 3.0, 6.9);
        this.addStar(api, 4.4, 7.2);
        if (bird) {
            this.addBird(api, 7.8, 4.4);
        }
        this.starT = 1.6;
        this.birdT = 2.2;
    }

    private startRun(api: GameApi): void {
        this.state = ST_PLAY;
        this.stateT = 0;
        this.runT = 0;
        this.score = 0;
        this.hearts = 3;
        this.hurtT = 9;
        this.ky = 5.5;
        this.vy = 0;
        this.clearWorld();
        this.seedStars(api, true);
        this.aiT = 0;
        this.streak = 0;
        api.sound(SFX_WIN, 1.0, 0.55);
    }

    private gameOver(): void {
        this.state = ST_OVER;
        this.stateT = 0;
        this.holding = false;
        if (this.score > this.best) {
            this.best = this.score;
        }
    }

    // ------------------------------------------------------------------ spawning

    private addStar(api: GameApi, x: f64, y: f64): void {
        for (let i = 0; i < NSTAR; i++) {
            if (!this.sOn[i] && this.sPop[i] < 0) {
                this.sOn[i] = true;
                this.sX[i] = x;
                this.sY[i] = y;
                this.sPh[i] = api.range(0, 6.28);
                this.sSkip[i] = api.rand() < 0.15;
                return;
            }
        }
    }

    private addBird(api: GameApi, x: f64, y: f64): void {
        for (let i = 0; i < NBIRD; i++) {
            if (!this.bOn[i]) {
                this.bOn[i] = true;
                this.bX[i] = x;
                this.bBase[i] = y;
                this.bY[i] = y;
                this.bPh[i] = api.range(0, 6.28);
                this.bHit[i] = -1;
                this.bVY[i] = 0;
                this.bBlind[i] = api.rand() < 0.2;
                return;
            }
        }
    }

    private speed(): f64 {
        return Math.min(2.8 + 0.055 * this.runT, 6.0);
    }

    private spawn(api: GameApi, dt: f64, birds: bool): void {
        this.starT -= dt;
        if (this.starT <= 0) {
            // a group of one to three stars in a gentle arc
            let n = 1 + <i32>Math.floor(api.rand() * 3);
            let y0 = api.range(3.4, 8.0);
            let dy = api.range(-0.6, 0.6);
            for (let k = 0; k < n; k++) {
                this.addStar(api, SPAWN_X + 1.3 * <f64>k, Math.min(Math.max(y0 + dy * <f64>k, 3.3), 8.4));
            }
            this.starT = api.range(1.3, 2.2) * 3.2 / this.speed() + 0.25 * <f64>n;
        }
        if (!birds) {
            return;
        }
        this.birdT -= dt;
        if (this.birdT <= 0) {
            // half the birds come at the kite's height, the others anywhere
            let y = api.rand() < 0.5 ? this.ky + api.range(-1.0, 1.0) : api.range(3.2, 8.4);
            this.addBird(api, SPAWN_X + 0.5, Math.min(Math.max(y, 3.2), 8.5));
            api.sound(SFX_SHOOT, 1.9, 0.4, 0.8);
            let gap = Math.max(0.85, 2.6 - 0.035 * this.runT);
            this.birdT = gap + api.range(0, 0.9);
        }
    }

    private burst(api: GameApi, x: f64, y: f64, n: i32): void {
        for (let k = 0; k < n; k++) {
            let i = this.nextSpark;
            this.nextSpark = (this.nextSpark + 1) % NSPARK;
            let a = <f64>k / <f64>n * 6.283 + api.range(-0.3, 0.3);
            let v = api.range(2.6, 4.0);
            this.kT[i] = 0;
            this.kX[i] = x;
            this.kY[i] = y;
            this.kVX[i] = Math.cos(a) * v;
            this.kVY[i] = Math.sin(a) * v + 1.0;
        }
    }

    private popup(x: f64, y: f64, s: i32): void {
        let i = this.nextPop;
        this.nextPop = (this.nextPop + 1) % NPOP;
        this.pX[i] = x;
        this.pY[i] = y;
        this.pT[i] = 0;
        this.pS[i] = s;
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        let t = api.time;

        // demo switched off by a visitor: a fresh run at once; switched on: the pilot takes over
        if (this.wasDemo != api.demo) {
            this.wasDemo = api.demo;
            this.holding = false;
            this.startRun(api);
        }

        this.stateT += dt;
        if (this.state == ST_PLAY) {
            this.runT += dt;
        }
        if (api.demo) {
            this.pilot(api, dt);
            if (this.state == ST_OVER && this.stateT > 2.0) {
                this.startRun(api);
            }
        }

        // the kite: lift while held, sink when let go; idle hovers; a lost kite flutters down
        if (this.state == ST_PLAY) {
            let ay = this.holding ? 12.5 : -8.5;
            this.vy += ay * dt;
            this.vy *= Math.exp(-1.3 * dt);
            this.vy = Math.min(Math.max(this.vy, -5.5), 5.5);
            this.ky += this.vy * dt;
            if (this.ky > YMAX) {
                this.ky = YMAX;
                this.vy = Math.min(this.vy, 0);
            }
            if (this.ky < YMIN) {
                // the tip touches the hill: a bounce and a heart
                api.soundAt(SFX_THUD, this.kx, YMIN, KZ, 1.1, 0.9);
                this.ky = YMIN;
                this.vy = 6.0;
                this.hurt(api);
            }
        } else if (this.state == ST_IDLE) {
            let goal = 5.6 + 0.5 * Math.sin(t * 0.9);
            this.vy += ((goal - this.ky) * 6.0 - this.vy * 3.0) * dt;
            this.ky += this.vy * dt;
        } else {
            // game over: the kite spins down onto the knoll and rests there
            this.vy = Math.max(this.vy - 4.0 * dt, -2.2);
            let wasUp = this.ky > 2.25;
            this.ky = Math.max(this.ky + this.vy * dt, 2.25);
            if (wasUp && this.ky <= 2.25) api.soundAt(SFX_THUD, this.kx, 2.25, KZ, 1.3, 0.6);
        }
        this.kx = KX + 0.3 * Math.sin(t * 1.1) + 0.12 * Math.sin(t * 2.7);
        let wobble = 5.0 * Math.sin(t * 2.3) + 2.0 * Math.sin(t * 5.1);
        let goalRoll = this.state == ST_OVER ? 70.0 + 20.0 * Math.sin(this.stateT * 3.0) : -this.vy * 4.0 + wobble;
        if (this.hurtT < 0.5) {
            goalRoll += 35.0 * Math.sin(this.hurtT * 40.0) * (0.5 - this.hurtT) * 2.0;
        }
        this.roll += (goalRoll - this.roll) * Math.min(1.0, dt * 10.0);
        this.hurtT += dt;
        this.popT += dt;

        // pop on a catch: squash then stretch; a stretch with speed
        let sx = 1.0, sy = 1.0;
        if (this.popT < 0.3) {
            let k = Math.sin(this.popT / 0.3 * Math.PI);
            sx = 1.0 + 0.22 * k;
            sy = 1.0 - 0.14 * k;
        } else {
            let s = Math.min(Math.abs(this.vy) / 5.5, 1.0) * 0.08;
            sy = 1.0 + s;
            sx = 1.0 - s * 0.5;
        }
        let yawK = 14.0 * Math.sin(t * 0.8);
        let blink = this.hurtT < 1.2 && this.state == ST_PLAY && Math.floor(this.hurtT * 12.0) % 2 == 1;
        if (blink) {
            api.hide(this.kite);
        } else {
            this.placeKite(api, this.kite, this.kx, this.ky, KZ, yawK, this.roll, sx, sy);
        }

        this.updateTail(api, dt, t);
        this.updateKid(api, dt);
        this.updateClouds(api, dt);

        let sp = this.speed();
        if (this.state == ST_PLAY && api.frame % 120 == 60) {
            api.sound(SFX_WHOOSH, 0.7 + 0.1 * sp, 0.45, 0.3);
        }
        if (this.state != ST_OVER) {
            this.spawn(api, dt, this.state == ST_PLAY);
        }
        this.updateStars(api, dt, t, sp);
        this.updateBirds(api, dt, t, sp);
        this.updateSparks(api, dt);
        for (let i = 0; i < NPOP; i++) {
            if (this.pT[i] >= 0) {
                this.pT[i] += dt;
                if (this.pT[i] > 0.9) this.pT[i] = -1;
            }
        }
    }

    private hurt(api: GameApi): void {
        if (this.hurtT < 1.2 || this.state != ST_PLAY) {
            return;
        }
        this.hurtT = 0;
        this.hearts -= 1;
        this.streak = 0;
        api.soundAt(SFX_HIT, this.kx, this.ky, KZ, 0.7 + 0.15 * <f64>this.hearts, 0.9);
        if (this.hearts <= 0) {
            this.hearts = 0;
            this.gameOver();
            api.sound(SFX_LOSE, 1.0, 0.7);
        }
    }

    // M = T(x,y,z) * Ry(yaw) * Rz(roll) * S(sx,sy,1) * T(-rest): game_api's place has no per-axis scale
    // with a roll, so the kite's matrix is written here (api.mats is the bone buffer place() fills).
    private placeKite(api: GameApi, b: i32, x: f64, y: f64, z: f64, yawDeg: f64, rollDeg: f64, sx: f64, sy: f64): void {
        if (b <= 0) {
            return;
        }
        let cy = Math.cos(yawDeg * Math.PI / 180), syw = Math.sin(yawDeg * Math.PI / 180);
        let cr = Math.cos(rollDeg * Math.PI / 180), sr = Math.sin(rollDeg * Math.PI / 180);
        let a00 = cy * cr * sx, a01 = -cy * sr * sy, a02 = syw;
        let a10 = sr * sx, a11 = cr * sy, a12 = 0.0;
        let a20 = -syw * cr * sx, a21 = syw * sr * sy, a22 = cy;
        let rx = <f64>api.restX[b], ry = <f64>api.restY[b], rz = <f64>api.restZ[b];
        let m = b * 12;
        api.mats[m] = <f32>a00; api.mats[m + 1] = <f32>a01; api.mats[m + 2] = <f32>a02;
        api.mats[m + 3] = <f32>(x - (a00 * rx + a01 * ry + a02 * rz));
        api.mats[m + 4] = <f32>a10; api.mats[m + 5] = <f32>a11; api.mats[m + 6] = <f32>a12;
        api.mats[m + 7] = <f32>(y - (a10 * rx + a11 * ry + a12 * rz));
        api.mats[m + 8] = <f32>a20; api.mats[m + 9] = <f32>a21; api.mats[m + 10] = <f32>a22;
        api.mats[m + 11] = <f32>(z - (a20 * rx + a21 * ry + a22 * rz));
        api.dirty[b] = true;
        api.anyDirty = true;
    }

    private updateTail(api: GameApi, dt: f64, t: f64): void {
        // the anchor: the kite's stub, turned with the kite's roll
        let r = this.roll * Math.PI / 180;
        this.tx[0] = this.kx + Math.sin(r) * TIP;
        this.ty[0] = this.ky - Math.cos(r) * TIP;
        let h = Math.max(dt, 0.001);
        for (let i = 1; i <= NBOW; i++) {
            let vx = (this.tx[i] - this.px[i]) * 0.94;
            let vy = (this.ty[i] - this.py[i]) * 0.94;
            this.px[i] = this.tx[i];
            this.py[i] = this.ty[i];
            let wind = 4.5 + 2.5 * Math.sin(t * 3.1 + <f64>i * 0.9);
            this.tx[i] += vx + wind * h * h;
            this.ty[i] += vy - 7.0 * h * h;
        }
        for (let it = 0; it < 4; it++) {
            for (let i = 1; i <= NBOW; i++) {
                let dx = this.tx[i] - this.tx[i - 1], dy = this.ty[i] - this.ty[i - 1];
                let d = Math.sqrt(dx * dx + dy * dy) + 1e-6;
                let k = (d - LINK) / d;
                if (i == 1) {
                    this.tx[i] -= dx * k;
                    this.ty[i] -= dy * k;
                } else {
                    this.tx[i] -= dx * k * 0.5;
                    this.ty[i] -= dy * k * 0.5;
                    this.tx[i - 1] += dx * k * 0.5;
                    this.ty[i - 1] += dy * k * 0.5;
                }
            }
            this.tx[0] = this.kx + Math.sin(r) * TIP;
            this.ty[0] = this.ky - Math.cos(r) * TIP;
        }
        let hidden = this.hurtT < 1.2 && this.state == ST_PLAY && Math.floor(this.hurtT * 12.0) % 2 == 1;
        for (let i = 0; i < NBOW; i++) {
            let b = this.bowB[i];
            if (hidden) {
                api.hide(b);
                continue;
            }
            let dx = this.tx[i + 1] - this.tx[i], dy = this.ty[i + 1] - this.ty[i];
            let ang = Math.atan2(dy, dx) * 180 / Math.PI + 90.0;
            api.place(b, this.tx[i + 1], this.ty[i + 1], KZ - 0.05, 0, 0, ang, 1);
        }
    }

    private updateKid(api: GameApi, dt: f64): void {
        // the kid leans back while the string pulls, and hops when a star is caught
        let goal = this.holding ? 9.0 : 2.0;
        if (this.state == ST_OVER) goal = -4.0;
        this.lean += (goal - this.lean) * Math.min(1.0, dt * 6.0);
        let hop = this.popT < 0.35 ? 0.18 * Math.sin(this.popT / 0.35 * Math.PI) : 0.0;
        api.place(this.kid, <f64>api.restX[this.kid], <f64>api.restY[this.kid] + hop, <f64>api.restZ[this.kid], 0, 0, this.lean, 1);
    }

    private updateClouds(api: GameApi, dt: f64): void {
        for (let i = 0; i < NCLOUD; i++) {
            this.cX[i] -= (0.25 + 0.08 * <f64>i) * dt;
            if (this.cX[i] < -12.5) this.cX[i] += 25.0;
            api.place(this.cloudB[i], this.cX[i], this.cY[i], -7.5 - <f64>i * 0.6, 0, 0, 0, 1.0 - 0.15 * <f64>i);
        }
    }

    private updateStars(api: GameApi, dt: f64, t: f64, sp: f64): void {
        for (let i = 0; i < NSTAR; i++) {
            let b = this.starB[i];
            if (this.sPop[i] >= 0) {
                // caught: a quick swell, then gone
                this.sPop[i] += dt;
                let k = this.sPop[i] / 0.18;
                if (k >= 1) {
                    this.sPop[i] = -1;
                    api.hide(b);
                } else {
                    api.place(b, this.sX[i], this.sY[i], 0.6, 0, 0, 0, 1.0 + 0.8 * k);
                }
                continue;
            }
            if (!this.sOn[i]) {
                api.hide(b);
                continue;
            }
            this.sX[i] -= sp * dt;
            let y = this.sY[i] + 0.18 * Math.sin(t * 2.0 + this.sPh[i]);
            if (this.sX[i] < GONE_X) {
                this.sOn[i] = false;
                api.hide(b);
                continue;
            }
            // a stepped turn in the picture plane (8 fps, 9 degrees a step), like a sprite's
            let spin = Math.floor((t + this.sPh[i]) * 8.0) * 9.0;
            api.place(b, this.sX[i], y, 0.6, 0, 0, spin, 1);
            if (this.state != ST_OVER) {
                let dx = (this.sX[i] - this.kx) / 1.35, dy = (y - (this.ky - 0.2)) / 1.45;
                if (dx * dx + dy * dy < 1.0) {
                    this.sOn[i] = false;
                    this.sPop[i] = 0;
                    this.sY[i] = y;
                    this.popT = 0;
                    this.burst(api, this.sX[i], y, 5);
                    if (this.state == ST_PLAY) {
                        this.score += 1;
                        this.popup(this.sX[i], y + 0.6, 1);
                        let step = min<i32>(this.streak, PENTA.length - 1);
                        api.note(<f64>(72 + PENTA[step]), 0.8, 0, SFX_BELL);
                        api.note(<f64>(60 + PENTA[step]), 0.4, 0, SFX_NOTE);
                        this.streak += 1;
                    }
                }
            }
        }
    }

    private updateBirds(api: GameApi, dt: f64, t: f64, sp: f64): void {
        for (let i = 0; i < NBIRD; i++) {
            let b = this.birdB[i];
            if (!this.bOn[i]) {
                api.hide(b);
                continue;
            }
            if (this.bHit[i] >= 0) {
                // knocked: it tumbles away down and to the left
                this.bHit[i] += dt;
                this.bVY[i] -= 9.0 * dt;
                this.bY[i] += this.bVY[i] * dt;
                this.bX[i] -= (sp + 2.0) * dt;
                if (this.bY[i] < -1.0 || this.bX[i] < GONE_X) {
                    this.bOn[i] = false;
                    api.hide(b);
                    continue;
                }
                api.place(b, this.bX[i], this.bY[i], 0.7, 0, 0, this.bHit[i] * 540.0, 1);
                continue;
            }
            this.bX[i] -= (sp + 1.3) * dt;
            this.bY[i] = this.bBase[i] + 0.45 * Math.sin(t * 2.6 + this.bPh[i]);
            if (this.bX[i] < GONE_X) {
                this.bOn[i] = false;
                api.hide(b);
                continue;
            }
            // a stepped flap: four poses at 10 fps (wings up, level, down, level)
            let f = <i32>Math.floor((t + this.bPh[i]) * 10.0) % 4;
            let sy = f == 0 ? 1.25 : (f == 2 ? 0.2 : 0.7);
            api.placeScaled(b, this.bX[i], this.bY[i] + (f == 2 ? 0.08 : 0.0), 0.7, 0, 1.0, sy, 1.0);
            if (this.state == ST_PLAY && this.hurtT >= 1.2) {
                let dx = (this.bX[i] - this.kx) / 1.25, dy = (this.bY[i] - (this.ky - 0.15)) / 1.35;
                if (dx * dx + dy * dy < 1.0) {
                    this.bHit[i] = 0;
                    this.bVY[i] = 3.0;
                    this.vy = Math.min(this.vy, 0) - 2.5;
                    this.burst(api, this.bX[i], this.bY[i], 4);
                    api.soundAt(SFX_SHOOT, this.bX[i], this.bY[i], 0.7, 1.4, 0.7);
                    this.hurt(api);
                }
            }
        }
    }

    private updateSparks(api: GameApi, dt: f64): void {
        for (let i = 0; i < NSPARK; i++) {
            let b = this.sparkB[i];
            if (this.kT[i] < 0) {
                api.hide(b);
                continue;
            }
            this.kT[i] += dt;
            if (this.kT[i] > 0.45) {
                this.kT[i] = -1;
                api.hide(b);
                continue;
            }
            this.kVY[i] -= 6.0 * dt;
            this.kX[i] += this.kVX[i] * dt;
            this.kY[i] += this.kVY[i] * dt;
            api.place(b, this.kX[i], this.kY[i], 0.8, this.kT[i] * 400.0, 0, 0, 1.0 - this.kT[i] * 1.4);
        }
    }

    // ------------------------------------------------------------------ the demo pilot

    // Plays like a decent human: steers for the next star, climbs or dives round birds it notices
    // (one in five slips past its attention), lets some stars go, and re-plans only every 0.15 s.
    private pilot(api: GameApi, dt: f64): void {
        if (this.state != ST_PLAY) {
            this.holding = false;
            return;
        }
        this.aiT -= dt;
        if (this.aiT <= 0) {
            this.aiT = 0.15;
            let target = 5.6;
            let bestX = 99.0;
            for (let i = 0; i < NSTAR; i++) {
                if (this.sOn[i] && !this.sSkip[i] && this.sX[i] > this.kx - 0.4 && this.sX[i] < bestX) {
                    bestX = this.sX[i];
                    target = this.sY[i];
                }
            }
            // a bird ahead at about the kite's height: get out of its way
            let threat = -1;
            let tx = 99.0;
            for (let i = 0; i < NBIRD; i++) {
                if (!this.bOn[i] || this.bHit[i] >= 0 || this.bBlind[i]) continue;
                let ahead = this.bX[i] - this.kx;
                if (ahead > -1.2 && ahead < 4.2 && ahead < tx) {
                    let d = this.bBase[i] - target;
                    if (Math.abs(d) < 2.2 || Math.abs(this.bBase[i] - this.ky) < 2.0) {
                        tx = ahead;
                        threat = i;
                    }
                }
            }
            if (threat >= 0) {
                let by = this.bBase[threat];
                let up = by + 2.6, down = by - 2.6;
                target = (up <= 8.3 && (Math.abs(up - this.ky) < Math.abs(down - this.ky) || down < 3.3)) ? up : down;
            }
            if (api.rand() < 0.1) {
                this.aiErr = api.range(-0.6, 0.6);
            }
            this.aiTarget = Math.min(Math.max(target + this.aiErr, 3.2), 8.3);
        }
        let want = (this.aiTarget - this.ky) - 0.42 * this.vy;
        if (this.holding) {
            this.holding = want > -0.1;
        } else {
            this.holding = want > 0.15;
        }
    }

    // ------------------------------------------------------------------ input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.state == ST_IDLE) {
                this.startRun(api);
            } else if (this.state == ST_OVER) {
                if (this.stateT < 0.6) {
                    return true;
                }
                this.startRun(api);
            }
            if (!this.holding) api.sound(SFX_WHOOSH, 1.2, 0.6, -0.3);
            this.holding = true;
        } else if (kind == POINTER_UP) {
            this.holding = false;
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let peach = api.paletteColor(C_PEACH);
        let pink = api.paletteColor(C_PINK);
        let dusk = api.paletteColor(C_DUSK);
        let night = api.paletteColor(C_NIGHT);
        let haze = api.paletteColor(C_HAZE);

        // The renderer draws the HUD one colour at a time, in the order each colour FIRST appears
        // (not rect by rect): prime the order back to front (bands, shadows, then the bright
        // colours) with off-screen rects, so a text shadow or a backing never covers its text.
        api.rect(-4, -4, 1, 1, dusk);
        api.rect(-4, -4, 1, 1, night);
        api.rect(-4, -4, 1, 1, haze);
        api.rect(-4, -4, 1, 1, pink);
        api.rect(-4, -4, 1, 1, peach);

        this.drawString(api, peach);

        // "+1" popups rising from caught stars
        for (let i = 0; i < NPOP; i++) {
            if (this.pT[i] < 0) continue;
            if (api.project(<f32>this.pX[i], <f32>(this.pY[i] + this.pT[i] * 1.2), 0.6)) {
                api.text(Mathf.round(api.screenX) - 3, Mathf.round(api.screenY) - 2, "+" + this.pS[i].toString(), peach, 1, night);
            }
        }

        let W = <f32>api.hudW;
        api.text(3, 3, "STARS " + this.score.toString(), peach, 1, night);
        let bs = "BEST " + this.best.toString();
        api.text(W - 3 - api.textWidth(bs, 1), 3, bs, peach, 1, night);
        // three hearts, top centre, on a dark backing so they read over the clouds
        let hx0 = Mathf.floor(W * 0.5) - 12;
        api.rect(hx0 - 1, 2, 25, 7, night);
        for (let i = 0; i < 3; i++) {
            let c = i < this.hearts ? pink : haze;
            let hx = hx0 + <f32>i * 8, hy: f32 = 3;
            api.rect(hx, hy, 2, 2, c);
            api.rect(hx + 3, hy, 2, 2, c);
            api.rect(hx, hy + 1, 5, 2, c);
            api.rect(hx + 1, hy + 3, 3, 1, c);
            api.rect(hx + 2, hy + 4, 1, 1, c);
        }

        let H = <f32>api.hudH;
        if (this.state == ST_IDLE) {
            this.banner(api, 12, 2);
            api.textCentered(14, "HOLD TO RISE, LET GO TO DIP", peach, 1, night);
            api.textCentered(21, "CATCH STARS - DODGE BIRDS", pink, 1, night);
            if (Math.floor(this.stateT * 2.0) % 2 == 0) {
                api.textCentered(H - 9, "PRESS TO START", peach, 1, night);
            }
        } else if (this.state == ST_PLAY && this.runT < 2.5 && !api.demo) {
            this.banner(api, 12, 1);
            api.textCentered(14, "HOLD TO RISE, LET GO TO DIP", peach, 1, night);
        } else if (this.state == ST_OVER) {
            api.textCentered(24, "GAME OVER", peach, 2, night);
            let s = this.score.toString() + (this.score == 1 ? " STAR" : " STARS");
            api.textCentered(39, s, pink, 1, night);
            if (this.stateT > 0.6) {
                api.textCentered(48, api.demo ? "HERE WE GO AGAIN..." : "CLICK TO FLY AGAIN", peach, 1, night);
            }
        }
    }

    // a dusk-blue band behind one or two hint lines, so they read over the pink clouds
    private banner(api: GameApi, y: f32, lines: i32): void {
        let w = api.textWidth("HOLD TO RISE, LET GO TO DIP", 1) + 6;
        let x = Mathf.floor((<f32>api.hudW - w) * 0.5);
        api.rect(x, y, w, <f32>(lines * 7 + 3), api.paletteColor(C_DUSK));
    }

    // the string: a sagging curve from the kid's hand to the kite's spar crossing, one art pixel wide
    private drawString(api: GameApi, color: u32): void {
        if (!api.project(<f32>HAND_X, <f32>HAND_Y, 0.3)) return;
        let ax = api.screenX, ay = api.screenY;
        if (!api.project(<f32>this.kx, <f32>(this.ky - 0.25), <f32>KZ)) return;
        let bx = api.screenX, by = api.screenY;
        let sag = <f32>(this.state == ST_OVER ? 10.0 : (this.holding ? 2.0 : 6.0));
        let cx = (ax + bx) * 0.5, cy = (ay + by) * 0.5 + sag;
        let lastX: f32 = -999, lastY: f32 = -999;
        let n = 64;
        for (let i = 0; i <= n; i++) {
            let u = <f32>i / <f32>n;
            let v = 1 - u;
            let x = Mathf.floor(v * v * ax + 2 * v * u * cx + u * u * bx);
            let y = Mathf.floor(v * v * ay + 2 * v * u * cy + u * u * by);
            if (x != lastX || y != lastY) {
                api.rect(x, y, 1, 1, color);
                lastX = x;
                lastY = y;
            }
        }
    }
}
