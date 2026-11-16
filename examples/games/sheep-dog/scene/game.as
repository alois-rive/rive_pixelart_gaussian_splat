// Sheep dog: the pointer is the dog. Herd six skittish sheep through the pen's gate before the
// timer runs out. Sheep flee the dog, flock a little and graze when left alone; a sheep that walks
// through the gate is penned (+100, +50 more when it follows another within 3 s). Pen all six and
// every second left is worth 10; the gate swings shut. One run, one meadow, pointer only.
import { GameApi, POINTER_DOWN, POINTER_MOVE, SFX_NOTE, SFX_COIN, SFX_TICK, SFX_WIN, SFX_LOSE, SFX_CLICK } from "./game_api";

// the meadow (world metres; models/env/make_env.py builds the same fence)
const X0: f64 = -6.4;
const X1: f64 = 6.4;
const Z0: f64 = -4.2;
const Z1: f64 = 4.4;
const PX0: f64 = 3.0;      // the pen: x PX0..X1, z Z0..PZ1
const PZ1: f64 = -1.6;
const GATE0: f64 = 3.7;    // the gate gap along z = PZ1
const GATE1: f64 = 5.5;
const ENTRY_X: f64 = 4.6;  // just outside the gate
const ENTRY_Z: f64 = -0.9;

const N: i32 = 6;
const SHEEP_R: f64 = 0.42;
const DOG_R: f64 = 0.35;
const FLEE_R: f64 = 2.7;
const SHEEP_MAX: f64 = 3.6;
const DOG_MAX: f64 = 7.0;
const RUN_TIME: f64 = 45;

// round obstacles: pond, three rocks (x, z, r)
const OBS: StaticArray<f64> = [-4.6, -2.6, 1.55, -0.8, 0.9, 0.55, 1.9, 2.7, 0.45, -5.5, 3.3, 0.4];

// where the sheep start (scattered over the left and middle of the meadow)
const START: StaticArray<f64> = [-3.4, 0.6, -2.2, 2.6, -4.6, 1.9, -1.6, -1.6, -0.4, 2.2, -2.8, -0.3];

// ramps, in art/palette.json order
const R_WOOL: i32 = 2;
const R_FACE: i32 = 3;
const R_FUR: i32 = 4;
const R_CREAM: i32 = 5;
const R_RED: i32 = 9;

const READY: i32 = 0;
const PLAY: i32 = 1;
const OVER: i32 = 2;

export class Game {
    state: i32 = READY;
    wasDemo: bool = false;
    timeLeft: f64 = RUN_TIME;
    overAt: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    penned: i32 = 0;
    lastPen: f64 = -10;
    won: bool = false;

    dogB: i32 = -1;
    gateB: i32 = -1;
    dx: f64 = 0;
    dz: f64 = 3.0;
    dvx: f64 = 0;
    dvz: f64 = 0;
    dyaw: f64 = 180;
    dphase: f64 = 0;
    dsquash: f64 = 0;
    tx: f64 = 0;       // where the dog is heading
    tz: f64 = 3.0;
    hasTarget: bool = false;
    gateYaw: f64 = 0;

    sb: StaticArray<i32> = new StaticArray<i32>(N);
    sx: StaticArray<f64> = new StaticArray<f64>(N);
    sz: StaticArray<f64> = new StaticArray<f64>(N);
    svx: StaticArray<f64> = new StaticArray<f64>(N);
    svz: StaticArray<f64> = new StaticArray<f64>(N);
    syaw: StaticArray<f64> = new StaticArray<f64>(N);
    sphase: StaticArray<f64> = new StaticArray<f64>(N);
    spanic: StaticArray<f64> = new StaticArray<f64>(N);   // seconds of fright left
    sstartle: StaticArray<f64> = new StaticArray<f64>(N); // anticipation squash, counts down
    spop: StaticArray<f64> = new StaticArray<f64>(N);     // the hop when penned, counts down
    sin_: StaticArray<bool> = new StaticArray<bool>(N);   // penned
    swx: StaticArray<f64> = new StaticArray<f64>(N);      // wander heading
    swz: StaticArray<f64> = new StaticArray<f64>(N);
    sgraze: StaticArray<f64> = new StaticArray<f64>(N);   // grazing clock

    // "+100" popups: world position and age
    px: StaticArray<f64> = new StaticArray<f64>(8);
    pz: StaticArray<f64> = new StaticArray<f64>(8);
    page: StaticArray<f64> = new StaticArray<f64>(8);
    ptext: StaticArray<i32> = new StaticArray<i32>(8);
    pnext: i32 = 0;

    // sound: notes queued for a later frame (a bleat, a whistle), the last startle, the last second shown
    qAt: Array<i32> = new Array<i32>();
    qMidi: Array<f64> = new Array<f64>();
    qVol: Array<f64> = new Array<f64>();
    qPan: Array<f64> = new Array<f64>();
    lastStartle: i32 = -100;
    lastSec: i32 = 99;
    latchIn: i32 = -1;

    // demo player
    aimT: f64 = 0;
    aimOX: f64 = 0;
    aimOZ: f64 = 0;
    focus: i32 = -1;

    start(api: GameApi): void {
        api.playable = true;
        this.dogB = api.bone("dog");
        this.gateB = api.bone("gate");
        for (let i = 0; i < N; i++) {
            this.sb[i] = api.bone("sheep" + i.toString());
        }
        for (let i = 0; i < 8; i++) {
            this.page[i] = 99;
        }
        this.reset(api);
        this.wasDemo = api.demo;
        if (api.demo) {
            this.state = PLAY;
        }
    }

    reset(api: GameApi): void {
        for (let i = 0; i < N; i++) {
            this.sx[i] = START[i * 2] + api.range(-0.4, 0.4);
            this.sz[i] = START[i * 2 + 1] + api.range(-0.4, 0.4);
            this.svx[i] = 0;
            this.svz[i] = 0;
            this.syaw[i] = api.range(-180, 180);
            this.sphase[i] = api.range(0, 6);
            this.spanic[i] = 0;
            this.sstartle[i] = 0;
            this.spop[i] = 0.35; // everyone hops in place when a run starts
            this.sin_[i] = false;
            let a = api.range(0, Math.PI * 2);
            this.swx[i] = Math.cos(a);
            this.swz[i] = Math.sin(a);
            this.sgraze[i] = api.range(0, 4);
        }
        this.dx = 0;
        this.dz = 3.0;
        this.dvx = 0;
        this.dvz = 0;
        this.dyaw = 180;
        this.tx = this.dx;
        this.tz = this.dz;
        this.hasTarget = false;
        this.timeLeft = RUN_TIME;
        this.score = 0;
        this.penned = 0;
        this.lastPen = -10;
        this.won = false;
        this.focus = -1;
        this.aimT = 0;
    }

    begin(api: GameApi): void {
        this.reset(api);
        this.state = PLAY;
        this.whistle(api);
    }

    // ---------------------------------------------------------------- sound

    // the shepherd's whistle that starts a run: a rising two-note call
    whistle(api: GameApi): void {
        this.later(api, 0, 81, 0.55, 0);
        this.later(api, 7, 88, 0.6, 0);
        this.lastSec = 99;
    }

    // a note played `frames` from now (frames 0: this frame)
    later(api: GameApi, frames: i32, midi: f64, vol: f64, pan: f64): void {
        this.qAt.push(api.frame + frames);
        this.qMidi.push(midi);
        this.qVol.push(vol);
        this.qPan.push(pan);
    }

    playQueued(api: GameApi): void {
        for (let k = this.qAt.length - 1; k >= 0; k--) {
            if (this.qAt[k] <= api.frame) {
                api.note(this.qMidi[k], this.qVol[k], this.qPan[k], SFX_NOTE);
                this.qAt.splice(k, 1); this.qMidi.splice(k, 1); this.qVol.splice(k, 1); this.qPan.splice(k, 1);
            }
        }
    }

    // where a world point shows, as a pan (-0.8 .. 0.8)
    panAt(api: GameApi, x: f64, z: f64): f64 {
        if (api.project(<f32>x, 0.4, <f32>z) && api.hudW > 0) {
            return Math.min(Math.max((<f64>api.screenX / <f64>api.hudW) * 2 - 1, -1), 1) * 0.8;
        }
        return 0;
    }

    update(api: GameApi): void {
        let dt = api.dt;
        // demo switched: a fresh run either way
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.begin(api);
            if (!api.demo) {
                this.hasTarget = false;
            }
        }
        this.playQueued(api);
        if (this.state == PLAY) {
            this.timeLeft -= dt;
            // the last ten seconds tick, sharper for the last three
            let sec = <i32>Math.ceil(this.timeLeft);
            if (sec < this.lastSec) {
                if (sec <= 10 && sec > 0) {
                    api.sound(SFX_TICK, sec <= 3 ? 1.5 : 1.0, sec <= 3 ? 0.9 : 0.6);
                }
                this.lastSec = sec;
            }
            if (this.timeLeft <= 0) {
                this.timeLeft = 0;
                this.finish(api, false);
            }
        } else if (this.state == OVER && api.demo && api.time - this.overAt > 2.0) {
            this.begin(api);
        }
        if (api.demo && this.state == PLAY) {
            this.demoAim(api, dt);
        }
        this.moveDog(api, dt);
        this.moveSheep(api, dt);
        // the gate: open during a run, swings shut once all six are in
        if (this.latchIn >= 0 && api.frame >= this.latchIn) {
            api.sound(SFX_CLICK, 0.35, 0.8, this.panAt(api, GATE0, PZ1));   // the gate's latch
            this.latchIn = -1;
        }
        let gy = this.won ? 180.0 : 0.0;
        this.gateYaw += (gy - this.gateYaw) * Math.min(1, dt * 5);
        api.place(this.gateB, GATE0, 0, PZ1 + 0.12, this.gateYaw);
        for (let i = 0; i < 8; i++) {
            this.page[i] += dt;
        }
    }

    finish(api: GameApi, won: bool): void {
        this.state = OVER;
        this.overAt = api.time;
        this.won = won;
        if (won) {
            let bonus = <i32>Math.ceil(this.timeLeft) * 10;
            this.score += bonus;
            api.sound(SFX_WIN, 1.0, 0.8);
            this.latchIn = api.frame + 24;
        } else {
            api.sound(SFX_LOSE, 1.0, 0.75);
        }
        if (this.score > this.best) {
            this.best = this.score;
        }
    }

    // ---------------------------------------------------------------- the dog

    moveDog(api: GameApi, dt: f64): void {
        if (this.state == PLAY && this.hasTarget) {
            let ex = this.tx - this.dx, ez = this.tz - this.dz;
            let d = Math.sqrt(ex * ex + ez * ez);
            let want = Math.min(DOG_MAX, d * 5.0);
            let vx = d > 0.01 ? ex / d * want : 0;
            let vz = d > 0.01 ? ez / d * want : 0;
            let k = Math.min(1, dt * 9);
            this.dvx += (vx - this.dvx) * k;
            this.dvz += (vz - this.dvz) * k;
        } else {
            let k = Math.min(1, dt * 6);
            this.dvx -= this.dvx * k;
            this.dvz -= this.dvz * k;
        }
        let before = Math.sqrt(this.dvx * this.dvx + this.dvz * this.dvz);
        this.dx += this.dvx * dt;
        this.dz += this.dvz * dt;
        // the fence, the rocks, the pond, and the pen (the dog stays out of it)
        this.collide(DOG_R, true);
        this.dx = this.cx;
        this.dz = this.cz;
        let sp = Math.sqrt(this.dvx * this.dvx + this.dvz * this.dvz);
        if (before > 2.5 && sp < before * 0.5) {
            this.dsquash = 0.16; // a skid
        }
        if (sp > 0.4) {
            let want = Math.atan2(this.dvx, this.dvz) * 180 / Math.PI;
            this.dyaw = turnTo(this.dyaw, want, dt * 720);
        }
        this.dsquash = Math.max(0, this.dsquash - dt);
        let b = this.dogB;
        if (sp > 0.6) {
            // a gallop: bounds stepped at 12 fps, the body rocking nose-down, nose-up
            this.dphase += dt * (6 + sp * 1.6);
            let ph = stepped(this.dphase, 0.5);
            let hop = Math.abs(Math.sin(ph)) * Math.min(1, sp / 4) * 0.16;
            let rock = Math.cos(ph) * 9 * Math.min(1, sp / 4);
            api.place(b, this.dx, hop, this.dz, this.dyaw, rock);
        } else if (this.dsquash > 0) {
            let s = this.dsquash / 0.16;
            api.placeScaled(b, this.dx, 0, this.dz, this.dyaw, 1 + 0.12 * s, 1 - 0.18 * s, 1 + 0.12 * s);
        } else {
            // panting: a little breathing squash, stepped
            let t = stepped(api.time * 3.5, 0.5);
            let br = 1 + 0.035 * Math.sin(t);
            api.placeScaled(b, this.dx, 0, this.dz, this.dyaw, 1, br, 1);
        }
    }

    // ---------------------------------------------------------------- the sheep

    moveSheep(api: GameApi, dt: f64): void {
        for (let i = 0; i < N; i++) {
            let x = this.sx[i], z = this.sz[i];
            let wx = 0.0, wz = 0.0;     // desired velocity
            let fright = 0.0;
            let playing = this.state == PLAY;
            if (!this.sin_[i]) {
                // flee the dog
                let ex = x - this.dx, ez = z - this.dz;
                let d = Math.sqrt(ex * ex + ez * ez);
                if (playing && d < FLEE_R && d > 0.001) {
                    fright = 1 - d / FLEE_R;
                    if (this.spanic[i] <= 0) {
                        this.sstartle[i] = 0.12; // anticipation: a squash before the dash
                        // a startled sheep: one short note in its own voice (not more than one a third of a second)
                        if (api.frame - this.lastStartle > 20) {
                            this.lastStartle = api.frame;
                            api.note(<f64>(74 + (i % 3) * 2), 0.4, this.panAt(api, x, z), SFX_NOTE);
                        }
                    }
                    this.spanic[i] = 0.7;
                    let s = SHEEP_MAX * (0.45 + 0.55 * fright);
                    wx += ex / d * s;
                    wz += ez / d * s;
                }
                // flock: drift towards the others, keep a little room
                let fx = 0.0, fz = 0.0, fn = 0.0;
                for (let j = 0; j < N; j++) {
                    if (j == i || this.sin_[j]) {
                        continue;
                    }
                    let ox = this.sx[j] - x, oz = this.sz[j] - z;
                    let od = Math.sqrt(ox * ox + oz * oz);
                    if (od < 3.2) {
                        fx += ox;
                        fz += oz;
                        fn += 1;
                    }
                    if (od < 0.95 && od > 0.001) {
                        wx -= ox / od * (0.95 - od) * 4;
                        wz -= oz / od * (0.95 - od) * 4;
                    }
                }
                // fences push a frightened sheep back into the open (sheep peel off walls), except
                // at the pen's gate gap
                if (this.spanic[i] > 0) {
                    let wr = 1.1, wk = 3.2;
                    wx += Math.max(0, wr - (x - X0)) * wk - Math.max(0, wr - (X1 - x)) * wk;
                    wz += Math.max(0, wr - (z - Z0)) * wk - Math.max(0, wr - (Z1 - z)) * wk;
                    if (z < PZ1) {
                        wx -= Math.max(0, wr - Math.abs(PX0 - x)) * wk * (x < PX0 ? 1 : -1);
                    } else if (x > PX0 - 0.3 && (x < GATE0 - 0.2 || x > GATE1 + 0.2)) {
                        wz += Math.max(0, wr - (z - PZ1)) * wk;
                    }
                }
                if (fn > 0 && this.spanic[i] > 0) {
                    wx += fx / fn * 0.35;
                    wz += fz / fn * 0.35;
                }
            } else {
                // penned sheep keep their distance from each other
                for (let j = 0; j < N; j++) {
                    if (j == i || !this.sin_[j]) {
                        continue;
                    }
                    let ox = this.sx[j] - x, oz = this.sz[j] - z;
                    let od = Math.sqrt(ox * ox + oz * oz);
                    if (od < 0.95 && od > 0.001) {
                        wx -= ox / od * (0.95 - od) * 3;
                        wz -= oz / od * (0.95 - od) * 3;
                    }
                }
            }
            // calm: wander slowly, stop to graze
            this.sgraze[i] += dt;
            let grazing = false;
            if (this.spanic[i] <= 0) {
                let cyc = this.sgraze[i] % 5.0;
                if (cyc < 2.2) {
                    grazing = true;
                } else {
                    if (api.rand() < dt * 0.6) {
                        let a = api.range(0, Math.PI * 2);
                        this.swx[i] = Math.cos(a);
                        this.swz[i] = Math.sin(a);
                    }
                    wx += this.swx[i] * 0.45;
                    wz += this.swz[i] * 0.45;
                }
            }
            this.spanic[i] = Math.max(0, this.spanic[i] - dt);
            let k = Math.min(1, dt * (this.spanic[i] > 0 ? 6.0 : 2.5));
            this.svx[i] += (wx - this.svx[i]) * k;
            this.svz[i] += (wz - this.svz[i]) * k;
            let sp = Math.sqrt(this.svx[i] * this.svx[i] + this.svz[i] * this.svz[i]);
            if (sp > SHEEP_MAX) {
                this.svx[i] *= SHEEP_MAX / sp;
                this.svz[i] *= SHEEP_MAX / sp;
                sp = SHEEP_MAX;
            }
            this.dx2 = x + this.svx[i] * dt;
            this.dz2 = z + this.svz[i] * dt;
            this.sheepWalls(i);
            // a wall stops the part of the velocity that runs into it
            if (dt > 0) {
                this.svx[i] = (this.cx - x) / dt;
                this.svz[i] = (this.cz - z) / dt;
            }
            this.sx[i] = this.cx;
            this.sz[i] = this.cz;
            if (!this.sin_[i] && this.cz < PZ1 - 0.45 && this.cx > PX0) {
                this.pen(api, i);
            }
            // turn towards where it goes
            if (sp > 0.25) {
                let want = Math.atan2(this.svx[i], this.svz[i]) * 180 / Math.PI;
                this.syaw[i] = turnTo(this.syaw[i], want, dt * (this.spanic[i] > 0 ? 540 : 160));
            }
            this.drawSheep(api, i, sp, grazing, dt);
        }
    }

    drawSheep(api: GameApi, i: i32, sp: f64, grazing: bool, dt: f64): void {
        let b = this.sb[i];
        let x = this.sx[i], z = this.sz[i], yaw = this.syaw[i];
        if (this.sstartle[i] > 0) {
            this.sstartle[i] -= dt;
            api.placeScaled(b, x, 0, z, yaw, 1.12, 0.8, 1.12);
            return;
        }
        if (this.spop[i] > 0) {
            this.spop[i] -= dt;
            let u = 1 - Math.max(0, this.spop[i]) / 0.35;
            let h = Math.sin(u * Math.PI) * 0.55;
            let st = 1 + 0.18 * Math.sin(u * Math.PI);
            api.placeScaled(b, x, h, z, yaw, 1 / Math.sqrt(st), st, 1 / Math.sqrt(st));
            return;
        }
        if (sp > 0.9) {
            // bouncing trot, stepped
            this.sphase[i] += dt * (5 + sp * 2.2);
            let ph = stepped(this.sphase[i], 0.5);
            let h = Math.abs(Math.sin(ph)) * 0.18 * Math.min(1, sp / 2.5);
            let st = 1 + 0.1 * Math.sin(ph * 2) * Math.min(1, sp / 2.5);
            api.placeScaled(b, x, h, z, yaw, 1 / Math.sqrt(st), st, 1 / Math.sqrt(st) * 1.03);
            return;
        }
        if (grazing) {
            // nose down to the grass, chewing (stepped)
            let t = stepped(this.sgraze[i] * 4, 0.6);
            api.place(b, x, 0, z, yaw, 9 + 3 * Math.sin(t));
            return;
        }
        api.place(b, x, 0, z, yaw);
    }

    pen(api: GameApi, i: i32): void {
        this.sin_[i] = true;
        this.spop[i] = 0.35;
        this.spanic[i] = 0;
        this.penned++;
        let pts = 100;
        if (this.state == PLAY && api.time - this.lastPen < 3.0) {
            pts = 150;
        }
        this.lastPen = api.time;
        if (this.state == PLAY) {
            this.score += pts;
            // penned: a coin that climbs with every sheep in, brighter for a quick follow-up
            api.sound(SFX_COIN, (pts > 100 ? 1.19 : 1.0) * (1.0 + 0.06 * <f64>this.penned), 0.6, this.panAt(api, this.sx[i], this.sz[i]));
        }
        // and the sheep bleats: three soft high notes in its own voice, the last one falling
        let v = <f64>(81 + (i % 3) * 2);
        let pan = this.panAt(api, this.sx[i], this.sz[i]);
        this.later(api, 2, v, 0.45, pan);
        this.later(api, 6, v, 0.4, pan);
        this.later(api, 10, v - 2, 0.35, pan);
        let p = this.pnext;
        this.pnext = (this.pnext + 1) % 8;
        this.px[p] = this.sx[i];
        this.pz[p] = this.sz[i];
        this.page[p] = 0;
        this.ptext[p] = pts;
        // send the sheep a little deeper into the pen
        this.svz[i] = -2.0;
        if (this.penned == N && this.state == PLAY) {
            this.finish(api, true);
        }
    }

    // ---------------------------------------------------------------- collisions

    cx: f64 = 0;
    cz: f64 = 0;
    dx2: f64 = 0;
    dz2: f64 = 0;

    sheepWalls(i: i32): void {
        let r = SHEEP_R;
        let x = this.dx2, z = this.dz2;
        if (this.sin_[i]) {
            x = clamp(x, PX0 + r, X1 - r);
            z = clamp(z, Z0 + r, PZ1 - r);
            // the hay bale and the trough
            this.cx = x;
            this.cz = z;
            this.pushCircle(5.6, -3.5, 0.55, r);
            this.pushCircle(3.9, -3.7, 0.55, r);
            return;
        }
        this.cx = x;
        this.cz = z;
        this.collideFree(r, false);
    }

    // the dog, or a sheep outside the pen: fence, obstacles, the pen's walls with its gate gap
    collide(r: f64, isDog: bool): void {
        this.cx = this.dx;
        this.cz = this.dz;
        this.collideFree(r, isDog);
    }

    collideFree(r: f64, isDog: bool): void {
        let x = clamp(this.cx, X0 + r, X1 - r);
        let z = clamp(this.cz, Z0 + r, Z1 - r);
        this.cx = x;
        this.cz = z;
        for (let k = 0; k < OBS.length; k += 3) {
            this.pushCircle(OBS[k], OBS[k + 1], OBS[k + 2], r);
        }
        // the open gate lies along the fence line, left of the gap (x 1.9..3.7)
        this.pushBox(1.9, 3.7, PZ1 - 0.02, PZ1 + 0.24, r);
        x = this.cx;
        z = this.cz;
        if (x > PX0 - r && z < PZ1 + r) {
            let through = !isDog && x > GATE0 + 0.05 && x < GATE1 - 0.05;
            if (through) {
                // inside the gap: keep clear of the gate posts
                this.cx = clamp(x, GATE0 + r * 0.7, GATE1 - r * 0.7);
            } else {
                let inX = x - (PX0 - r);
                let inZ = (PZ1 + r) - z;
                if (inX < inZ) {
                    this.cx = PX0 - r;
                } else {
                    this.cz = PZ1 + r;
                }
            }
        }
    }

    pushCircle(ox: f64, oz: f64, orad: f64, r: f64): void {
        let ex = this.cx - ox, ez = this.cz - oz;
        let d = Math.sqrt(ex * ex + ez * ez);
        let m = orad + r;
        if (d < m && d > 0.0001) {
            this.cx = ox + ex / d * m;
            this.cz = oz + ez / d * m;
        }
    }

    pushBox(x0: f64, x1: f64, z0: f64, z1: f64, r: f64): void {
        let x = this.cx, z = this.cz;
        if (x > x0 - r && x < x1 + r && z > z0 - r && z < z1 + r) {
            let a = x - (x0 - r), b = (x1 + r) - x, c = z - (z0 - r), d = (z1 + r) - z;
            let m = Math.min(Math.min(a, b), Math.min(c, d));
            if (m == a) { this.cx = x0 - r; }
            else if (m == b) { this.cx = x1 + r; }
            else if (m == c) { this.cz = z0 - r; }
            else { this.cz = z1 + r; }
        }
    }

    // ---------------------------------------------------------------- the demo player

    demoAim(api: GameApi, dt: f64): void {
        // a decent shepherd: picks the free sheep nearest the gate, runs round behind it and
        // pushes it at the gate; aims a little off and re-thinks only every 0.3 s
        this.aimT -= dt;
        if (this.aimT > 0) {
            return;
        }
        this.aimT = 0.3;
        if (api.rand() < 0.3) {
            this.aimOX = api.range(-0.8, 0.8);
            this.aimOZ = api.range(-0.8, 0.8);
        }
        let best = -1;
        let bestD = 1e9;
        for (let i = 0; i < N; i++) {
            if (this.sin_[i]) {
                continue;
            }
            let ex = this.sx[i] - ENTRY_X, ez = this.sz[i] - ENTRY_Z;
            let d = Math.sqrt(ex * ex + ez * ez);
            if (i == this.focus) {
                d -= 1.5; // stay with the one being worked
            }
            if (d < bestD) {
                bestD = d;
                best = i;
            }
        }
        if (best < 0) {
            return;
        }
        this.focus = best;
        let x = this.sx[best], z = this.sz[best];
        // the way the sheep should go: at the gate's mouth, then up through it
        let gx = ENTRY_X - x, gz = ENTRY_Z - z;
        if (x < GATE0 && z < ENTRY_Z + 0.4) {
            // behind the pen's corner: out of the pocket first, down and round
            gx = (GATE0 - 0.4) - x;
            gz = (ENTRY_Z + 1.2) - z;
        }
        let gd = Math.sqrt(gx * gx + gz * gz);
        if (gd < 1.3 || (x > GATE0 && x < GATE1 && z < ENTRY_Z + 1.0)) {
            gx = (GATE0 + GATE1) * 0.5 - x;
            gz = -1.0;
            gd = Math.sqrt(gx * gx + gz * gz);
        }
        gx /= gd;
        gz /= gd;
        // behind the sheep, opposite the way it should go
        let bx = x - gx * 1.7, bz = z - gz * 1.7;
        // on the wrong side: run round it first
        let ox = this.dx - x, oz = this.dz - z;
        if (ox * gx + oz * gz > -0.3) {
            // the flank on the dog's side, unless the pen or a fence is in the way
            let side = (ox * -gz + oz * gx) >= 0 ? 1.0 : -1.0;
            let best2 = 1e9;
            for (let k = 0; k < 2; k++) {
                let sd = k == 0 ? side : -side;
                let cx = x - gx * 0.8 + -gz * sd * 2.4;
                let cz = z - gz * 0.8 + gx * sd * 2.4;
                let cost = k == 0 ? 0.0 : 2.0;
                if (cx > PX0 - 0.4 && cz < PZ1 + 0.4) {
                    cost += 100; // in the pen
                }
                if (cx < X0 + 0.3 || cx > X1 - 0.3 || cz < Z0 + 0.3 || cz > Z1 - 0.3) {
                    cost += 50;  // over the fence
                }
                if (cost < best2) {
                    best2 = cost;
                    bx = cx;
                    bz = cz;
                }
            }
        }
        let ax = clamp(bx + this.aimOX, X0 + 0.5, X1 - 0.5);
        let az = clamp(bz + this.aimOZ, Z0 + 0.5, Z1 - 0.5);
        if (ax > PX0 - 0.4 && az < PZ1 + 0.4) {
            az = PZ1 + 0.4; // never inside the pen
        }
        this.tx = ax;
        this.tz = az;
        this.hasTarget = true;
    }

    // ---------------------------------------------------------------- input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.state == READY) {
                this.state = PLAY;
                this.whistle(api);
            } else if (this.state == OVER) {
                if (api.time - this.overAt < 0.6) {
                    return true;
                }
                this.begin(api);
            }
        }
        if (this.state == PLAY && (kind == POINTER_DOWN || kind == POINTER_MOVE)) {
            // touch: while a finger is down the dog runs to a point a few art pixels above it, so
            // the finger hides neither the dog nor the sheep next to it (a mouse: the pointer itself)
            let lift: f32 = api.pointerDown ? <f32>(24.0 / Math.max(1.0, api.pixelSize)) : 0;
            if (api.pick(x, y - lift, 0)) {
                this.tx = <f64>api.hitX;
                this.tz = <f64>api.hitZ;
                this.hasTarget = true;
            }
        }
        return true;
    }

    // ---------------------------------------------------------------- HUD

    hud(api: GameApi): void {
        let ink = api.rampColor(R_FACE, 0);
        let white = api.rampColor(R_CREAM, 2);
        let gold = api.rampColor(R_FUR, 3);
        let red = api.rampColor(R_RED, 1);
        let w = <f32>api.hudW;
        // the sheep counter: one wool block per sheep, filled when penned
        api.text(4, 4, "PEN", white, 1, ink);
        for (let i = 0; i < N; i++) {
            let bx = <f32>(18 + i * 7);
            api.rect(bx + 1, 5, 6, 5, ink);
            api.rect(bx, 4, 6, 5, i < this.penned ? white : api.rampColor(R_WOOL, 0));
        }
        let secs = <i32>Math.ceil(this.timeLeft);
        let ts = secs.toString();
        let tc = (this.state == PLAY && secs <= 10) ? red : white;
        if (this.state == PLAY && secs <= 10 && (<i32>(api.time * 4)) % 2 == 0) {
            tc = gold;
        }
        api.text(Mathf.floor((w - api.textWidth(ts, 2)) * 0.5), 3, ts, tc, 2, ink);
        let sc = "SCORE " + this.score.toString();
        api.text(w - 4 - api.textWidth(sc, 1), 4, sc, gold, 1, ink);
        let bs = "BEST " + this.best.toString();
        api.text(w - 4 - api.textWidth(bs, 1), 11, bs, white, 1, ink);
        // "+100" popups over the gate
        for (let p = 0; p < 8; p++) {
            let age = this.page[p];
            if (age > 1.0) {
                continue;
            }
            if (api.project(<f32>this.px[p], 1.2 + <f32>age * 0.8, <f32>this.pz[p])) {
                let s = "+" + this.ptext[p].toString();
                let c = this.ptext[p] > 100 ? gold : white;
                api.text(Mathf.floor(api.screenX - api.textWidth(s, 1) * 0.5), Mathf.floor(api.screenY), s, c, 1, ink);
            }
        }
        let h = <f32>api.hudH;
        if (this.state == READY) {
            api.textCentered(h - 12, "CLICK, THEN STEER THE DOG: PEN ALL 6 SHEEP", white, 1, ink);
        } else if (this.state == OVER) {
            let title = this.won ? "ALL PENNED!" : "TIME UP!";
            api.textCentered(h * 0.5 - 22, title, this.won ? gold : white, 3, ink);
            let line = this.penned.toString() + " OF 6 SHEEP   SCORE " + this.score.toString();
            api.textCentered(h * 0.5 - 2, line, white, 1, ink);
            if (this.score >= this.best && this.score > 0) {
                api.textCentered(h * 0.5 + 7, "NEW BEST!", gold, 1, ink);
            }
            if (!api.demo && api.time - this.overAt > 0.6) {
                api.textCentered(h - 12, "CLICK TO PLAY AGAIN", white, 1, ink);
            }
        }
    }
}

function clamp(v: f64, a: f64, b: f64): f64 {
    return v < a ? a : (v > b ? b : v);
}

// a phase advanced in whole steps (the 12 fps hand-animated feel): step in radians
function stepped(phase: f64, step: f64): f64 {
    return Math.floor(phase / step) * step;
}

function turnTo(from: f64, to: f64, maxStep: f64): f64 {
    let d = to - from;
    while (d > 180) { d -= 360; }
    while (d < -180) { d += 360; }
    if (d > maxStep) { d = maxStep; }
    if (d < -maxStep) { d = -maxStep; }
    return from + d;
}
