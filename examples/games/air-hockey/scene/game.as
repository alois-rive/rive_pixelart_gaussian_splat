// Air Hockey: the pointer is your mallet on a glowing arcade rink; first to 7 against the computer.
// One verb (move the pointer), one world. The puck slides on a frictionless-ish table, bounces off
// the rails and the goal posts, and drops into a goal pocket for a point. Your goals score 100 plus
// a power bonus for a fast shot; winning the match adds 300. Game over shows the result, the score
// and the session's best; the next click starts a new match at the same table.
// Demo mode (api.demo) plays the left mallet with the same bot as the computer, a little slower and
// a little less accurate, so the matches are close and both sides miss.
import { GameApi, POINTER_DOWN, SFX_BLIP, SFX_CLICK, SFX_TICK, SFX_ZAP, SFX_WHOOSH, SFX_COIN, SFX_POWERUP,
    SFX_HIT, SFX_THUD, SFX_LOSE, SFX_WIN, SFX_NOTE, SFX_BELL } from "./game_api";

// ---------------------------------------------------------------- the table (world metres, Y up)
const SURF: f64 = 1.06;      // the playing surface's height
const IX: f64 = 2.16;        // its half length (x) and half width (z), inside the rails
const IZ: f64 = 1.035;
const MOUTH: f64 = 0.38;     // the goal mouths' half width
const PR: f64 = 0.14;        // puck radius
const MR: f64 = 0.19;        // mallet radius (the model's 0.22 baked at scale 0.86)
const VMAX: f64 = 10.0;      // the fastest a puck slides
const WIN: i32 = 7;

const MODE_READY: i32 = 0;   // the hint, waiting for a click
const MODE_PLAY: i32 = 1;
const MODE_GOAL: i32 = 2;    // the puck in a pocket; the next face-off follows
const MODE_OVER: i32 = 3;

const NGHOST: i32 = 4;
const NSPARK: i32 = 10;
const NTRAIL: i32 = 12;

// palette indices (art/palette.json order)
const C_INK: i32 = 0;
const C_SLATE: i32 = 1;
const C_MINT: i32 = 4;
const C_YELLOW: i32 = 10;
const C_ORANGE: i32 = 11;
const C_PLUM: i32 = 13;
const C_PINK: i32 = 15;
const C_ICE: i32 = 16;

function clamp(v: f64, a: f64, b: f64): f64 {
    return v < a ? a : (v > b ? b : v);
}

// z after a straight slide that bounces between the side rails (a fold into [-lim, lim]).
function fold(z: f64, lim: f64): f64 {
    let p = 4 * lim;
    let w = (z + lim) % p;
    if (w < 0) w += p;
    if (w > 2 * lim) w = p - w;
    return w - lim;
}

// A mallet driven by a bot: the computer on the right (side +1) and the demo player on the left
// (side -1). It defends its goal on the puck's predicted line, sets up behind a slow puck in its
// half and strikes through it towards the other goal, and drifts home otherwise. It re-decides a
// few times a second with an aim error, and is speed-limited, so fast shots and bad bounces beat it.
class Bot {
    side: f64 = 1;
    speed: f64 = 3.2;        // m/s
    err: f64 = 0.2;          // aim error scale (m)
    think: f64 = 0;          // seconds to the next decision
    thinkMin: f64 = 0.12;
    thinkMax: f64 = 0.22;
    mode: i32 = 0;           // 0 home, 1 defend, 2 set up, 3 strike
    modeT: f64 = 0;
    tx: f64 = 0;
    tz: f64 = 0;
    aimZ: f64 = 0;           // where in the other goal it aims
    offZ: f64 = 0;           // its defending error
    defZ: f64 = 0;           // where it last read the puck's line (a stale read: it reacts late)
    defT: f64 = 0;
    react: f64 = 0.3;        // seconds between reads of the line
    warm: f64 = 0;           // extra reaction time at a match's start (it warms up)
    lapse: f64 = 0.2;        // the chance that it reads an incoming shot late and wide
    wide: f64 = 1;
    late: f64 = 0;           // a strike's extra delay (a fumble)

    constructor(side: f64) {
        this.side = side;
    }

    reset(): void {
        this.mode = 0;
        this.modeT = 0;
        this.think = 0;
    }

    update(api: GameApi, g: Game, dt: f64): void {
        let s = this.side;
        let homeX = s * (IX - 0.55);
        let px = g.px, pz = g.pz, vx = g.vx, vz = g.vz;
        let ownHalf = px * s > 0;
        let coming = vx * s > 0.4;                       // sliding towards this goal
        let speed = Math.sqrt(vx * vx + vz * vz);
        this.think -= dt;
        this.modeT += dt;
        if (this.think <= 0) {
            this.think = api.range(this.thinkMin, this.thinkMax);
            let next = 0;
            if (ownHalf && (speed < 3.4 || !coming)) {
                next = this.mode == 3 ? 3 : 2;           // a slow puck here: go round it and shoot
            } else if (coming) {
                next = 1;
            }
            if (this.mode == 3 && this.modeT > 0.32) {
                next = coming ? 1 : 0;
            }
            if (next != this.mode) {
                if (next == 2) {
                    this.aimZ = api.range(-1, 1) * (MOUTH * 0.5 + this.err);
                    // now and then a bank shot off a side rail
                    if (api.rand() < 0.25) {
                        this.aimZ = (pz > 0 ? -1 : 1) * api.range(1.4, 1.9);
                    }
                    this.late = api.rand() < 0.2 ? api.range(0.1, 0.35) : 0;
                }
                if (next == 1) {
                    // now and then it is caught out: a late, wide first read
                    let caught = api.rand() < this.lapse;
                    this.defT = caught ? api.range(0.25, 0.45) : 0;
                    this.wide = caught ? 2.2 : 1.0;
                }
                this.mode = next;
                this.modeT = 0;
            }
        }
        if (this.mode == 0) {
            this.tx = homeX;
            this.tz = clamp(pz * 0.35, -MOUTH, MOUTH);
        } else if (this.mode == 1) {
            // stand on the puck's line, a little in front of the goal
            let lineX = s * (IX - 0.6);
            this.defT -= dt;
            if (this.defT <= 0) {
                // read the line now and then, with an error that grows with the puck's speed
                this.defT = (this.react + this.warm) * api.range(0.8, 1.3);
                let zz = pz;
                if (Math.abs(vx) > 0.05) {
                    let t = (lineX - px) / vx;
                    if (t > 0) zz = fold(pz + vz * t, IZ - PR);
                }
                this.defZ = zz + api.range(-1, 1) * this.err * this.wide * (0.5 + speed * 0.2);
                this.wide = 1.0;
            }
            this.tx = lineX;
            this.tz = clamp(this.defZ, -MOUTH - 0.15, MOUTH + 0.15);
            if (ownHalf && Math.abs(px - lineX) < 0.9 && speed < 3.5) {
                this.mode = 2;   // it slowed down near the goal: clear it
                this.modeT = 0;
            }
        } else {
            // the line from the puck to the aim point in the other goal (a bank aim is a mirrored goal)
            let gx = -s * IX, gz = this.aimZ;
            let dx = gx - px, dz = gz - pz;
            let dl = Math.max(0.001, Math.sqrt(dx * dx + dz * dz));
            dx /= dl; dz /= dl;
            let lead = 0.08;
            let qx = px + vx * lead, qz = pz + vz * lead;
            if (this.mode == 2) {
                let back = MR + PR + 0.14;
                let bx = qx - dx * back, bz = qz - dz * back;
                // on the wrong side of the puck: go round it, not through it
                let mx = g.cx(this), mz = g.cz(this);
                if ((mx - qx) * dx + (mz - qz) * dz > -0.05) {
                    let side = (mz - qz) * dx - (mx - qx) * dz > 0 ? 1.0 : -1.0;
                    bx += -dz * side * (MR + PR) * 0.9;
                    bz += dx * side * (MR + PR) * 0.9;
                }
                this.tx = bx;
                this.tz = bz;
                let ex = mx - bx, ez = mz - bz;
                if ((ex * ex + ez * ez < 0.02 && this.modeT > this.late) || this.modeT > 1.1) {
                    this.mode = 3;
                    this.modeT = 0;
                }
            } else {
                this.tx = qx + dx * 0.55;
                this.tz = qz + dz * 0.55;
            }
        }
    }
}

export class Game {
    malletP: i32 = -1;
    malletC: i32 = -1;
    puck: i32 = -1;
    ghost: StaticArray<i32> = new StaticArray<i32>(NGHOST);
    spark: StaticArray<i32> = new StaticArray<i32>(NSPARK);
    pspark: StaticArray<i32> = new StaticArray<i32>(NSPARK);

    mode: i32 = MODE_READY;
    t: f64 = 0;               // seconds in this mode
    runT: f64 = 0;

    // the puck
    px: f64 = 0;
    pz: f64 = 0;
    vx: f64 = 0;
    vz: f64 = 0;
    py: f64 = SURF;
    spinA: f64 = 0;
    stillT: f64 = 0;          // seconds the puck has stayed within 0.3 m of the anchor
    anchorX: f64 = 0;
    anchorZ: f64 = 0;
    popS: f64 = 1;            // the face-off pop
    lastHit: i32 = 0;         // -1 player, +1 computer

    // the mallets: player (left) and computer (right); targets and velocities
    mx: f64 = -1.7;
    mz: f64 = 0;
    mvx: f64 = 0;
    mvz: f64 = 0;
    ptx: f64 = -1.7;
    ptz: f64 = 0;
    cxp: f64 = 1.7;
    czp: f64 = 0;
    cvx: f64 = 0;
    cvz: f64 = 0;
    squashP: f64 = 0;
    squashC: f64 = 0;

    cpu: Bot = new Bot(1);
    demoBot: Bot = new Bot(-1);

    goalsP: i32 = 0;
    goalsC: i32 = 0;
    score: i32 = 0;
    best: i32 = 0;
    lastGoal: i32 = 0;        // -1 the player scored, +1 the computer
    goalSpeed: f64 = 0;

    // effects
    trX: StaticArray<f64> = new StaticArray<f64>(NTRAIL);
    trZ: StaticArray<f64> = new StaticArray<f64>(NTRAIL);
    trV: StaticArray<f64> = new StaticArray<f64>(NTRAIL);
    trHead: i32 = 0;
    trTimer: f64 = 0;
    sX: StaticArray<f64> = new StaticArray<f64>(NSPARK * 2);
    sY: StaticArray<f64> = new StaticArray<f64>(NSPARK * 2);
    sZ: StaticArray<f64> = new StaticArray<f64>(NSPARK * 2);
    sVX: StaticArray<f64> = new StaticArray<f64>(NSPARK * 2);
    sVY: StaticArray<f64> = new StaticArray<f64>(NSPARK * 2);
    sVZ: StaticArray<f64> = new StaticArray<f64>(NSPARK * 2);
    sT: StaticArray<f64> = new StaticArray<f64>(NSPARK * 2);
    sNext: i32 = 0;
    pNext: i32 = 0;
    shake: f64 = 0;
    shakeX: f64 = 0;
    shakeZ: f64 = 0;
    camX: f64 = 0;
    camZ: f64 = 0;
    popText: string = "";
    popSub: string = "";
    popT: f64 = 9;
    popWX: f64 = 0;
    flash: f64 = 0;

    started: bool = false;

    // sound (never decided by a random draw): the contacts of this frame's sub-steps, played once
    hitHard: f64 = 0;         // the hardest mallet strike this frame
    hitWho: i32 = 0;
    hitX: f64 = 0;
    hitZ: f64 = 0;
    railSp: f64 = 0;          // the fastest rail or post bounce this frame
    railX: f64 = 0;
    railZ: f64 = 0;
    sndHitF: i32 = -99;       // the frame of the last strike sound (a pinned puck must not buzz)
    sndRailF: i32 = -99;
    tune: StaticArray<f64> = new StaticArray<f64>(8);   // a short melody, one note every tuneStep frames
    tuneN: i32 = 0;
    tuneI: i32 = 0;
    tuneAt: i32 = 0;
    tuneStep: i32 = 6;
    tuneKind: i32 = SFX_NOTE;

    start(api: GameApi): void {
        api.playable = true;
        this.malletP = api.bone("malletP");
        this.malletC = api.bone("malletC");
        this.puck = api.bone("puck");
        for (let i = 0; i < NGHOST; i++) {
            this.ghost[i] = api.bone("ghost" + i.toString());
            api.hide(this.ghost[i]);
        }
        for (let i = 0; i < NSPARK; i++) {
            this.spark[i] = api.bone("spark" + i.toString());
            this.pspark[i] = api.bone("pspark" + i.toString());
            api.hide(this.spark[i]);
            api.hide(this.pspark[i]);
        }
        for (let i = 0; i < NSPARK * 2; i++) {
            this.sT[i] = 99;
        }
        this.camX = api.targetX;
        this.camZ = api.targetZ;
        this.cpu.speed = 2.7;
        this.cpu.err = 0.27;
        this.cpu.react = 0.34;
        this.demoBot.speed = 2.85;
        this.demoBot.err = 0.27;
        this.demoBot.react = 0.32;
        this.demoBot.lapse = 0.22;
        this.demoBot.thinkMin = 0.14;
        this.demoBot.thinkMax = 0.28;
        this.newRun(api, api.demo);
        this.started = true;
    }

    // a fresh match: play at once (demo) or wait for a click (the hint)
    newRun(api: GameApi, play: bool): void {
        this.mode = play ? MODE_PLAY : MODE_READY;
        this.t = 0;
        this.runT = 0;
        this.goalsP = 0;
        this.goalsC = 0;
        this.score = 0;
        this.popT = 9;
        this.shake = 0;
        this.mx = -1.75; this.mz = 0; this.ptx = -1.75; this.ptz = 0;
        this.cxp = 1.75; this.czp = 0;
        this.mvx = 0; this.mvz = 0; this.cvx = 0; this.cvz = 0;
        this.cpu.reset();
        this.demoBot.reset();
        this.toughen();
        if (play) {
            // the opening face-off: the puck already sliding towards the left mallet
            this.faceOff(api, -0.2, api.range(-0.25, 0.25), -1.6, api.range(-0.7, 0.7));
        } else {
            this.faceOff(api, 0.0, 0.0, 0.0, 0.0);
        }
        for (let i = 0; i < NTRAIL; i++) {
            this.trX[i] = this.px; this.trZ[i] = this.pz; this.trV[i] = 0;
        }
    }

    faceOff(api: GameApi, x: f64, z: f64, vx: f64, vz: f64): void {
        this.px = x; this.pz = z; this.vx = vx; this.vz = vz;
        this.py = SURF;
        this.popS = 0;
        this.stillT = 0;
        this.anchorX = x;
        this.anchorZ = z;
        this.lastHit = 0;
    }

    playTune(api: GameApi, notes: Array<f64>, step: i32, kind: i32): void {
        this.tuneN = min<i32>(notes.length, 8);
        for (let i = 0; i < this.tuneN; i++) this.tune[i] = notes[i];
        this.tuneI = 0;
        this.tuneAt = api.frame;
        this.tuneStep = step;
        this.tuneKind = kind;
    }

    sounds(api: GameApi): void {
        // the puck's contacts: a plastic clack for a strike (brighter and louder the harder), a
        // neon zap on a slap shot, a dry tick off the rails and posts
        if (this.hitHard > 0.6 && api.frame - this.sndHitF >= 4) {
            let hd = this.hitHard;
            let side = this.hitWho < 0 ? 1.0 : 0.94;
            api.soundAt(SFX_CLICK, this.hitX, SURF, this.hitZ, clamp(0.28 + hd * 0.07, 0.3, 0.85) * side,
                clamp(0.5 + hd * 0.07, 0.5, 0.95));
            api.soundAt(SFX_TICK, this.hitX, SURF, this.hitZ, this.hitWho < 0 ? 0.36 : 0.32, 0.5);
            if (hd > 6.0) {
                api.soundAt(SFX_ZAP, this.hitX, SURF, this.hitZ, 1.0 + (hd - 6.0) * 0.08, 0.45);
            }
            this.sndHitF = api.frame;
        } else if (this.railSp > 1.2 && api.frame - this.sndRailF >= 4 && api.frame - this.sndHitF >= 2) {
            api.soundAt(SFX_TICK, this.railX, SURF, this.railZ, 0.45 + this.railSp * 0.025,
                clamp(0.35 + this.railSp * 0.06, 0.4, 0.8));
            this.sndRailF = api.frame;
        }
        this.hitHard = 0;
        this.railSp = 0;
        // the melody in progress
        if (this.tuneI < this.tuneN && api.frame >= this.tuneAt) {
            let m = this.tune[this.tuneI];
            if (m > 0) api.note(m, this.tuneKind == SFX_BELL ? 0.6 : 0.7, 0, this.tuneKind);
            this.tuneI++;
            this.tuneAt = api.frame + this.tuneStep;
        }
    }

    cx(b: Bot): f64 {
        return b.side > 0 ? this.cxp : this.mx;
    }

    cz(b: Bot): f64 {
        return b.side > 0 ? this.czp : this.mz;
    }

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged) {
            this.best = 0;          // the visitor's best is their own, not the demo's
            this.newRun(api, api.demo);
        }
        this.t += dt;
        if (this.mode == MODE_PLAY) {
            this.runT += dt;
        }

        // the player's mallet target: the pointer on the table (pointer()), or the demo bot
        if (api.demo) {
            if (this.mode == MODE_PLAY) {
                this.demoBot.update(api, this, dt);
                this.ptx = this.demoBot.tx;
                this.ptz = this.demoBot.tz;
            } else {
                this.ptx = -1.75;
                this.ptz = 0;
            }
        }
        if (this.mode == MODE_PLAY) {
            // the computer warms up over a match's first seconds: an early goal is there to take
            this.cpu.warm = this.runT < 9.0 ? 0.75 * (1.0 - this.runT / 9.0) : 0.0;
            this.cpu.update(api, this, dt);
        } else {
            this.cpu.tx = 1.75;
            this.cpu.tz = this.mode == MODE_READY ? 0.25 * Math.sin(api.time * 1.3) : 0;
        }

        // physics in sub-steps (a quick mallet must not pass through the puck)
        let n = 6;
        let h = dt / <f64>n;
        let pvx = 0.0, pvz = 0.0, cvx = 0.0, cvz = 0.0;
        for (let k = 0; k < n; k++) {
            // the player's mallet: the pointer is followed fast (12 m/s), a bot at its own speed
            let lim = api.demo ? this.demoBot.speed : 12.0;
            let ox = this.mx, oz = this.mz;
            let tx = clamp(this.ptx, -IX + MR, -MR), tz = clamp(this.ptz, -IZ + MR, IZ - MR);
            let dx = tx - this.mx, dz = tz - this.mz;
            let dl = Math.sqrt(dx * dx + dz * dz);
            let step = lim * h;
            if (api.demo && this.demoBot.mode == 3) step *= 1.7;   // a strike is a lunge
            if (dl > step) { dx *= step / dl; dz *= step / dl; }
            this.mx += dx; this.mz += dz;
            pvx = (this.mx - ox) / h; pvz = (this.mz - oz) / h;
            // the computer's mallet
            ox = this.cxp; oz = this.czp;
            tx = clamp(this.cpu.tx, MR, IX - MR); tz = clamp(this.cpu.tz, -IZ + MR, IZ - MR);
            dx = tx - this.cxp; dz = tz - this.czp;
            dl = Math.sqrt(dx * dx + dz * dz);
            step = this.cpu.speed * h * (this.cpu.mode == 3 ? 1.7 : 1.0);
            if (dl > step) { dx *= step / dl; dz *= step / dl; }
            this.cxp += dx; this.czp += dz;
            cvx = (this.cxp - ox) / h; cvz = (this.czp - oz) / h;
            if (this.mode == MODE_PLAY || this.mode == MODE_READY) {
                this.stepPuck(api, h, pvx, pvz, cvx, cvz);
            }
        }
        this.mvx = pvx; this.mvz = pvz; this.cvx = cvx; this.cvz = cvz;
        this.sounds(api);

        if (this.mode == MODE_PLAY) {
            // a puck that dies somewhere, or is pinned in a corner, gets a puff of air towards the middle
            let ax = this.px - this.anchorX, az = this.pz - this.anchorZ;
            if (ax * ax + az * az > 0.09) {
                this.anchorX = this.px;
                this.anchorZ = this.pz;
                this.stillT = 0;
            } else {
                this.stillT += dt;
            }
            if (this.stillT > 2.5) {
                let dx = -this.px * 0.5, dz = -this.pz;
                let dl = Math.max(0.1, Math.sqrt(dx * dx + dz * dz));
                this.vx = dx / dl * 2.2 + api.range(-0.3, 0.3);
                this.vz = dz / dl * 2.2 + api.range(-0.3, 0.3);
                this.px += this.vx * 0.05;
                this.pz += this.vz * 0.05;
                this.stillT = 0;
                this.burst(api, this.px, SURF + 0.05, this.pz, this.px < 0 ? 0 : 1, 2, 0.6);
                api.soundAt(SFX_WHOOSH, this.px, SURF, this.pz, 0.8, 0.5);
            }
        } else if (this.mode == MODE_GOAL) {
            // the puck drops into the pocket, then the next face-off on the side that conceded
            this.py = SURF - Math.min(0.35, this.t * 1.6);
            if (this.t >= 0.2 && this.t - dt < 0.2) {
                // the puck lands in the pocket
                api.soundAt(SFX_THUD, this.px, SURF, this.pz, 1.2, 0.6);
            }
            if (this.t > 1.3) {
                if (this.goalsP >= WIN || this.goalsC >= WIN) {
                    this.gameOver(api);
                } else {
                    this.mode = MODE_PLAY;
                    this.t = 0;
                    let s = this.lastGoal < 0 ? 1.0 : -1.0;   // the side that conceded serves
                    let z = api.range(-0.4, 0.4);
                    this.faceOff(api, s * 0.9, z, 0.0, 0.0);
                    api.soundAt(SFX_BLIP, s * 0.9, SURF, z, 1.0, 0.5);
                    this.cpu.reset();
                    this.demoBot.reset();
                }
            }
        } else if (this.mode == MODE_OVER) {
            if (api.demo && this.t > 2.0) {
                this.newRun(api, true);
            }
        }

        this.effects(api, dt);
        this.draw(api, dt);
    }

    stepPuck(api: GameApi, h: f64, pvx: f64, pvz: f64, cvx: f64, cvz: f64): void {
        // the air table: almost no friction
        let damp = Math.exp(-0.22 * h);
        this.vx *= damp;
        this.vz *= damp;
        this.px += this.vx * h;
        this.pz += this.vz * h;
        // the mallets
        this.collide(api, this.mx, this.mz, pvx, pvz, -1);
        this.collide(api, this.cxp, this.czp, cvx, cvz, 1);
        // the side rails
        if (this.pz > IZ - PR) {
            this.pz = IZ - PR;
            if (this.vz > 0) { this.vz = -this.vz * 0.9; this.railHit(api); }
        } else if (this.pz < -IZ + PR) {
            this.pz = -IZ + PR;
            if (this.vz < 0) { this.vz = -this.vz * 0.9; this.railHit(api); }
        }
        // the ends: through the mouth is a goal, the posts and the end rails bounce
        let ax = Math.abs(this.px);
        let s = this.px > 0 ? 1.0 : -1.0;
        if (Math.abs(this.pz) < MOUTH - PR * 0.4 && this.mode == MODE_PLAY) {
            if (ax > IX + PR * 0.6) {
                this.goal(api, s > 0 ? -1 : 1);
                return;
            }
        } else if (ax > IX - PR) {
            this.px = s * (IX - PR);
            if (this.vx * s > 0) { this.vx = -this.vx * 0.9; this.railHit(api); }
        }
        // the posts: the rail ends beside the mouth
        for (let k = 0; k < 2; k++) {
            let qz = k == 0 ? MOUTH : -MOUTH;
            let dx = this.px - s * IX, dz = this.pz - qz;
            let d = Math.sqrt(dx * dx + dz * dz);
            if (d < PR && d > 1e-6) {
                let nx = dx / d, nz = dz / d;
                this.px = s * IX + nx * PR;
                this.pz = qz + nz * PR;
                let vn = this.vx * nx + this.vz * nz;
                if (vn < 0) {
                    this.vx -= 1.8 * vn * nx;
                    this.vz -= 1.8 * vn * nz;
                    this.railHit(api);
                }
            }
        }
        // never leave the table sideways in a pocket
        if (ax > IX + 0.4) {
            this.px = s * (IX + 0.4);
        }
    }

    collide(api: GameApi, x: f64, z: f64, vx: f64, vz: f64, who: i32): void {
        let dx = this.px - x, dz = this.pz - z;
        let d = Math.sqrt(dx * dx + dz * dz);
        let rr = PR + MR;
        if (d >= rr) {
            return;
        }
        let nx = d > 1e-6 ? dx / d : (who < 0 ? 1.0 : -1.0), nz = d > 1e-6 ? dz / d : 0.0;
        this.px = x + nx * rr;
        this.pz = z + nz * rr;
        let rvx = this.vx - vx, rvz = this.vz - vz;
        let vn = rvx * nx + rvz * nz;
        if (vn < 0) {
            this.vx -= 1.85 * vn * nx;
            this.vz -= 1.85 * vn * nz;
            let sp = Math.sqrt(this.vx * this.vx + this.vz * this.vz);
            if (sp > VMAX) {
                this.vx *= VMAX / sp;
                this.vz *= VMAX / sp;
            }
            let hard = -vn;
            if (hard > this.hitHard) {
                this.hitHard = hard;
                this.hitWho = who;
                this.hitX = this.px;
                this.hitZ = this.pz;
            }
            if (who < 0) this.squashP = Math.min(1, hard / 4); else this.squashC = Math.min(1, hard / 4);
            this.lastHit = who;
            if (hard > 3.0) {
                this.burst(api, x + nx * MR, SURF + 0.08, z + nz * MR, who < 0 ? 0 : 1, 3, 1.2);
            }
        }
    }

    railHit(api: GameApi): void {
        let sp = Math.sqrt(this.vx * this.vx + this.vz * this.vz);
        if (sp > this.railSp) {
            this.railSp = sp;
            this.railX = this.px;
            this.railZ = this.pz;
        }
        if (sp > 4.5) {
            this.burst(api, this.px, SURF + 0.06, this.pz, this.lastHit < 0 ? 0 : 1, 2, 0.8);
        }
    }

    goal(api: GameApi, scorer: i32): void {
        // scorer: -1 the player (left) scored in the right goal, +1 the computer
        this.mode = MODE_GOAL;
        this.t = 0;
        this.lastGoal = scorer;
        let sp = Math.sqrt(this.vx * this.vx + this.vz * this.vz);
        this.goalSpeed = sp;
        this.vx *= 0.15;
        this.vz *= 0.15;
        let s = scorer < 0 ? 1.0 : -1.0;     // which end
        this.px = s * (IX + 0.2);
        this.popT = 0;
        this.popWX = s * (IX - 0.4);
        if (scorer < 0) {
            this.goalsP++;
            let pts = 100 + <i32>Math.round(clamp((sp - 2.5) * 11, 0, 60));
            this.score += pts;
            this.popText = "GOAL!";
            this.popSub = "+" + pts.toString() + (sp > 6.5 ? " SLAP SHOT" : "");
            this.toughen();
            // your goal: a coin that climbs a whole tone with each goal, a fanfare on a slap shot
            api.sound(SFX_COIN, Math.pow(2, <f64>(this.goalsP - 1) * 2 / 12), 0.85, 0.6);
            if (sp > 6.5) api.sound(SFX_POWERUP, 1.25, 0.6, 0.6);
        } else {
            this.goalsC++;
            this.toughen();
            this.popText = "CPU SCORES";
            this.popSub = "";
            // conceded: a crunch in your goal and two falling notes, lower as the computer closes in
            api.sound(SFX_HIT, 0.55, 0.6, -0.6);
            let base = 64.0 - <f64>this.goalsC;
            this.playTune(api, [0, base, base - 4], 7, SFX_NOTE);
        }
        if (this.score > this.best) {
            this.best = this.score;
        }
        this.shake = 0.5;
        this.flash = 1;
        for (let i = 0; i < 8; i++) {
            this.burst(api, s * (IX + 0.1), SURF + 0.15, api.range(-MOUTH, MOUTH), scorer < 0 ? 0 : 1, 1, 2.6);
        }
    }

    // the computer plays tighter the further you lead (and eases off when it leads)
    toughen(): void {
        let lead = <f64>(this.goalsP - this.goalsC);
        this.cpu.speed = clamp(2.7 + lead * 0.15, 2.5, 3.5);
        this.cpu.err = clamp(0.27 - lead * 0.025, 0.17, 0.32);
        this.cpu.react = clamp(0.34 - lead * 0.02, 0.26, 0.4);
        this.cpu.lapse = clamp(0.22 - lead * 0.03, 0.08, 0.3);
    }

    gameOver(api: GameApi): void {
        this.mode = MODE_OVER;
        this.t = 0;
        if (this.goalsP >= WIN) {
            this.score += 300;
            // the win: a rising arcade fanfare, then a bell
            api.sound(SFX_WIN, 1.0, 0.8);
            this.playTune(api, [0, 0, 72, 76, 79, 84, 0, 88], 6, SFX_NOTE);
        } else {
            api.sound(SFX_LOSE, 0.9, 0.8);
        }
        if (this.score > this.best) {
            this.best = this.score;
        }
        this.faceOff(api, 0, 0, 0, 0);
        this.popS = 1;
    }

    // sparks: kind 0 the player's yellow, 1 the computer's pink
    burst(api: GameApi, x: f64, y: f64, z: f64, kind: i32, count: i32, power: f64): void {
        for (let c = 0; c < count; c++) {
            let i: i32;
            if (kind == 0) { i = this.sNext; this.sNext = (this.sNext + 1) % NSPARK; }
            else { i = NSPARK + this.pNext; this.pNext = (this.pNext + 1) % NSPARK; }
            this.sX[i] = x; this.sY[i] = y; this.sZ[i] = z;
            let a = api.range(0, Math.PI * 2);
            let r = api.range(0.4, 1.0) * power;
            this.sVX[i] = Math.cos(a) * r;
            this.sVZ[i] = Math.sin(a) * r;
            this.sVY[i] = api.range(1.0, 2.2) * power * 0.8;
            this.sT[i] = 0;
        }
    }

    effects(api: GameApi, dt: f64): void {
        for (let i = 0; i < NSPARK * 2; i++) {
            if (this.sT[i] > 0.7) continue;
            this.sT[i] += dt;
            this.sVY[i] -= 7.0 * dt;
            this.sX[i] += this.sVX[i] * dt;
            this.sY[i] += this.sVY[i] * dt;
            this.sZ[i] += this.sVZ[i] * dt;
            if (this.sY[i] < SURF + 0.03 && Math.abs(this.sX[i]) < IX && Math.abs(this.sZ[i]) < IZ) {
                this.sY[i] = SURF + 0.03;
                this.sVY[i] = Math.abs(this.sVY[i]) * 0.4;
            }
        }
        this.squashP = Math.max(0, this.squashP - dt * 6);
        this.squashC = Math.max(0, this.squashC - dt * 6);
        this.popT += dt;
        this.flash = Math.max(0, this.flash - dt * 1.5);
        this.popS = Math.min(1, this.popS + dt * 5);
        // the trail: the puck's recent places, sampled at 20 fps (stepped)
        this.trTimer += dt;
        if (this.trTimer >= 0.05) {
            this.trTimer -= 0.05;
            this.trHead = (this.trHead + 1) % NTRAIL;
            this.trX[this.trHead] = this.px;
            this.trZ[this.trHead] = this.pz;
            this.trV[this.trHead] = this.mode == MODE_PLAY ? Math.sqrt(this.vx * this.vx + this.vz * this.vz) : 0;
        }
        // camera shake, stepped at 15 fps (the camera snaps to whole art pixels)
        this.shake = Math.max(0, this.shake - dt * 0.8);
        if (Math.floor(api.time * 15) != Math.floor((api.time - dt) * 15)) {
            this.shakeX = (api.rand() - 0.5) * this.shake * 0.5;
            this.shakeZ = (api.rand() - 0.5) * this.shake * 0.5;
        }
        api.targetX = this.camX + this.shakeX;
        api.targetZ = this.camZ + this.shakeZ;
    }

    draw(api: GameApi, dt: f64): void {
        // the puck: spins with its speed, pops in at a face-off
        let sp = Math.sqrt(this.vx * this.vx + this.vz * this.vz);
        this.spinA += sp * dt * 120 * (this.vz >= 0 ? 1 : -1);
        if (this.mode == MODE_GOAL && this.t > 0.3) {
            api.hide(this.puck);
        } else {
            let k = Math.floor(this.popS * 4) / 4;                  // a stepped pop
            let sc = k < 1 ? 0.4 + k * 0.8 : 1.0;
            api.place(this.puck, this.px, this.py, this.pz, this.spinA, 0, 0, sc);
        }
        // the trail: ghosts at older samples when the puck is fast
        for (let g = 0; g < NGHOST; g++) {
            let idx = (this.trHead - (g + 1) * 2 + NTRAIL * 4) % NTRAIL;
            let v = this.trV[idx];
            if (v > 3.0 && this.mode == MODE_PLAY) {
                let sc = 0.8 - <f64>g * 0.15;
                api.place(this.ghost[g], this.trX[idx], SURF - 0.01, this.trZ[idx], 0, 0, 0, sc);
            } else {
                api.hide(this.ghost[g]);
            }
        }
        // the mallets: lean into their motion, squash when they hit
        this.placeMallet(api, this.malletP, this.mx, this.mz, this.mvx, this.mvz, this.squashP);
        this.placeMallet(api, this.malletC, this.cxp, this.czp, this.cvx, this.cvz, this.squashC);
        // sparks
        for (let i = 0; i < NSPARK * 2; i++) {
            let b = i < NSPARK ? this.spark[i] : this.pspark[i - NSPARK];
            if (this.sT[i] > 0.6) {
                api.hide(b);
                continue;
            }
            let sc = this.sT[i] < 0.35 ? 1.0 : (this.sT[i] < 0.5 ? 0.75 : 0.5);
            api.place(b, this.sX[i], this.sY[i], this.sZ[i], this.sT[i] * 720, 0, 0, sc);
        }
    }

    placeMallet(api: GameApi, b: i32, x: f64, z: f64, vx: f64, vz: f64, sq: f64): void {
        let lean = 2.2;
        let roll = clamp(-vx * lean, -14, 14);
        let pitch = clamp(vz * lean, -14, 14);
        let q = Math.floor(sq * 4) / 4;              // stepped squash
        let sy = 1 - 0.3 * q, sxz = 1 + 0.18 * q;
        api.placeScaled(b, x, SURF, z, 0, sxz, sy, sxz, pitch, roll);
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (api.pick(x, y, <f32>(SURF + 0.1))) {
            this.ptx = <f64>api.hitX;
            this.ptz = <f64>api.hitZ;
        }
        if (kind == POINTER_DOWN) {
            if (this.mode == MODE_READY) {
                this.mode = MODE_PLAY;
                this.t = 0;
                // the face-off: the puck drifts to your side
                this.faceOff(api, 0, 0, -1.4, api.range(-0.6, 0.6));
                api.sound(SFX_WHOOSH, 0.6, 0.55);      // the air table switches on
                api.sound(SFX_BLIP, 1.0, 0.6);
            } else if (this.mode == MODE_OVER && this.t > 0.6) {
                this.newRun(api, true);
                api.sound(SFX_WHOOSH, 0.6, 0.55);
                api.sound(SFX_BLIP, 1.0, 0.6);
            }
        }
        return true;
    }

    hud(api: GameApi): void {
        let ink = api.paletteColor(C_INK);
        let slate = api.paletteColor(C_SLATE);
        let yellow = api.paletteColor(C_YELLOW);
        let orange = api.paletteColor(C_ORANGE);
        let pink = api.paletteColor(C_PINK);
        let plum = api.paletteColor(C_PLUM);
        let ice = api.paletteColor(C_ICE);
        let mint = api.paletteColor(C_MINT);
        let w = <f32>api.hudW, h = <f32>api.hudH;
        let cxm = Mathf.floor(w * 0.5);

        // the scoreboard: a panel top centre, your goals left in orange, the computer's right in pink
        let pw: f32 = 54, ph: f32 = 15;
        let px0 = cxm - pw * 0.5;
        api.rect(px0, 2, pw, ph, ink);
        api.rect(px0, 2 + ph, pw, 1, plum);
        let flashOn = this.flash > 0 && Math.floor(this.flash * 10) % 2 == 0;
        let gp = this.goalsP.toString(), gc = this.goalsC.toString();
        api.text(cxm - 6 - api.textWidth(gp, 2), 5, gp, flashOn && this.lastGoal < 0 ? ice : yellow, 2, 0);
        api.text(cxm - 1, 5, ":", slate, 2, 0);
        api.text(cxm + 6, 5, gc, flashOn && this.lastGoal > 0 ? ice : pink, 2, 0);
        api.text(px0 - 16, 7, "YOU", orange, 1, ink);
        api.text(px0 + pw + 4, 7, "CPU", pink, 1, ink);
        // points and the session's best
        api.text(4, 4, this.score.toString(), yellow, 2, ink);
        api.text(4, 16, "BEST " + this.best.toString(), ice, 1, ink);
        api.text(w - api.textWidth("FIRST TO 7", 1) - 4, 4, "FIRST TO 7", mint, 1, ink);

        if (this.popT < 1.4 && this.mode != MODE_OVER) {
            let blink = this.popT < 0.6 && Math.floor(this.popT * 10) % 2 == 1;
            let c = this.lastGoal < 0 ? yellow : pink;
            // over the rink's middle (teal: both the yellow and the pink read on it)
            api.project(0, <f32>SURF, 0);
            let ry = Mathf.round(api.screenY);
            api.textCentered(ry - 13, this.popText, blink ? ice : c, 2, ink);
            if (this.popSub.length > 0) {
                api.textCentered(ry + 1, this.popSub, ice, 1, ink);
            }
        }
        if (this.mode == MODE_READY) {
            let blink = Math.floor(api.time * 2) % 2 == 0;
            api.rect(0, h - 24, w, 24, ink);
            api.rect(0, h - 25, w, 1, plum);
            api.textCentered(h - 21, "CLICK TO FACE OFF", blink ? ice : mint, 2, ink);
            api.textCentered(h - 8, "THE POINTER IS YOUR MALLET - FIRST TO 7 WINS", ice, 1, ink);
        } else if (this.mode == MODE_OVER) {
            let bw: f32 = 124, bh: f32 = 42;
            let bx = Mathf.floor((w - bw) * 0.5), by = Mathf.floor(h * 0.5 - 24);
            api.rect(bx, by, bw, bh, ink);
            api.rect(bx - 1, by - 1, bw + 2, 1, plum);
            api.rect(bx - 1, by + bh, bw + 2, 1, plum);
            api.rect(bx - 1, by, 1, bh, plum);
            api.rect(bx + bw, by, 1, bh, plum);
            let won = this.goalsP >= WIN;
            let line = (won ? "YOU WIN " : "CPU WINS ") + this.goalsP.toString() + "-" + this.goalsC.toString();
            api.textCentered(by + 4, line, won ? yellow : pink, 2, plum);
            api.textCentered(by + 20, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), ice, 1, ink);
            if (this.t > 0.6 && !api.demo) {
                api.textCentered(by + 31, "CLICK TO PLAY AGAIN", mint, 1, ink);
            }
        }
    }
}
