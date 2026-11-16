// Pocket Cup: a village 3-a-side football match, Bramblecombe (you, coral shirts, attacking right)
// against Fernley (the computer, sky-blue shirts). Two minutes on the clock.
//
// The pointer only (a gallery forwards nothing else, and phones send it only while a finger is down):
// you control the Bramblecombe outfield player nearest the ball (a gold ring under him; it switches
// by itself, and to the receiver of your pass). He runs toward the pointer (the mouse, or the finger
// while it drags) and dribbles the ball when he has it. A tap (a short press that does not drag)
// passes toward that point, to the teammate nearest that direction when one is close to it; without
// the ball a tap lunges at it. Press and hold (still) and release to shoot toward the point: the power
// grows with the hold (a bar over his head). A drag only runs: it never passes or shoots. Running into
// an opponent who has the ball tackles it; a missed tackle staggers you for a moment.
//
// The ball rolls with friction, flies with gravity (a lofted shot shows its shadow), bounces off the
// posts, the crossbar, the nets and the fence round the pitch (there is no out of play). Keepers
// position themselves on the ball's angle, come for loose balls in their box, dive at shots (a roll
// that reaches the corners only if they react in time), catch or parry, then throw or kick it out.
// The computer's outfield pair presses, covers, dribbles past, passes and shoots with errors; your
// uncontrolled teammate makes runs when you have the ball and drops back to defend when you do not.
// A goal stops the clock: GOAL!, a cheer, then the conceding side kicks off. Full time shows the
// result, the score and the session's best goal difference; the next click starts a new match.
//
// Demo (api.demo): both sides are the computer, Bramblecombe's a little sharper; it opens mid-attack
// with a shot coming, plays full matches and restarts two seconds after full time.
//
// Bones (scene.bake.json): p0..p5 (bodies) with p0L/p0R..p5L/p5R (legs, pivoting at the hip), ball,
// ring, fan0..fan7 (the supporters behind the far fence).
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP, SFX_BLIP, SFX_CLICK, SFX_TICK, SFX_THUD, SFX_WHOOSH,
         SFX_SPLASH, SFX_HIT, SFX_POP, SFX_NOTE, SFX_BELL, SFX_WIN, SFX_LOSE, SFX_COIN } from "./game_api";

// ---------------------------------------------------------------- the pitch (metres, Y up)
const PX: f64 = 11.0;        // goal lines at x = +-PX
const PZ: f64 = 6.0;         // touchlines
const FXW: f64 = 12.54;      // the fence's inner faces (the ball's walls)
const FZW: f64 = 7.14;
const GW: f64 = 1.6;         // post centres at z = +-GW
const GH: f64 = 1.5;         // the crossbar
const GD: f64 = 0.9;         // net depth
const POSTR: f64 = 0.06;
const BR: f64 = 0.2;         // ball radius (exaggerated: 6 art pixels)
const PR: f64 = 0.3;         // a player's radius
const MATCH: f64 = 120.0;
const HIP: f64 = 0.6;
const LEGX: f64 = 0.112;
const NP: i32 = 6;           // p0 keeper, p1 p2 (Bramblecombe); p3 keeper, p4 p5 (Fernley)
const NFAN: i32 = 8;
const GRAV: f64 = 9.8;

const M_READY: i32 = 0;      // the hint before the first click
const M_KICKOFF: i32 = 1;    // whistle, a short freeze
const M_PLAY: i32 = 2;
const M_GOAL: i32 = 3;       // GOAL!, the cheer
const M_OVER: i32 = 4;       // full time

const K_POS: i32 = 0;        // keeper states
const K_DIVE: i32 = 1;
const K_DOWN: i32 = 2;
const K_HOLD: i32 = 3;
const K_RUSH: i32 = 4;

const R_CARRY: i32 = 0;      // outfield roles
const R_SUPPORT: i32 = 1;
const R_PRESS: i32 = 2;
const R_COVER: i32 = 3;
const R_CHASE: i32 = 4;

const TAP: f64 = 0.22;       // a press shorter than this is a tap (a pass)
const DRAG: f32 = 6;         // HUD pixels a press may wander before it is a drag (run only)

function clamp(v: f64, a: f64, b: f64): f64 { return v < a ? a : (v > b ? b : v); }
function sgn(v: f64): f64 { return v < 0 ? -1.0 : 1.0; }
function team(i: i32): i32 { return i < 3 ? 0 : 1; }
function isKeeper(i: i32): bool { return i == 0 || i == 3; }
function attackDir(t: i32): f64 { return t == 0 ? 1.0 : -1.0; }
function mate(i: i32): i32 { return i == 1 ? 2 : (i == 2 ? 1 : (i == 4 ? 5 : 4)); }
function keeperOf(t: i32): i32 { return t == 0 ? 0 : 3; }

// how a side plays (the demo's Bramblecombe and your teammate a little sharper than Fernley)
class Skill {
    speed: f64 = 5.0;        // m/s running
    carry: f64 = 4.4;        // with the ball
    thinkMin: f64 = 0.18;
    thinkMax: f64 = 0.32;
    shotErr: f64 = 0.36;     // metres of aim error at the goal
    passErr: f64 = 0.1;      // radians
    tackle: f64 = 0.4;       // the chance a tackle wins the ball
    range: f64 = 8.0;        // shoots from this close
    gkReact: f64 = 0.2;      // the keeper's reaction (s)
    gkErr: f64 = 0.3;        // its read error (m at the line)
    gkCatch: f64 = 0.8;
}

export class Game {
    body: StaticArray<i32> = new StaticArray<i32>(NP);
    legL: StaticArray<i32> = new StaticArray<i32>(NP);
    legR: StaticArray<i32> = new StaticArray<i32>(NP);
    fan: StaticArray<i32> = new StaticArray<i32>(NFAN);
    bBall: i32 = -1;
    bRing: i32 = -1;

    inited: bool = false;
    demo: bool = false;
    mode: i32 = M_READY;
    modeT: f64 = 0;
    clock: f64 = MATCH;
    goals: StaticArray<i32> = new StaticArray<i32>(2);
    best: i32 = -999;          // the session's best goal difference
    lastScorer: i32 = 0;       // the team that scored last
    kickTeam: i32 = 0;
    tickSec: i32 = -1;

    skill: Array<Skill> = [new Skill(), new Skill()];

    // players
    x: StaticArray<f64> = new StaticArray<f64>(NP);
    z: StaticArray<f64> = new StaticArray<f64>(NP);
    vx: StaticArray<f64> = new StaticArray<f64>(NP);
    vz: StaticArray<f64> = new StaticArray<f64>(NP);
    face: StaticArray<f64> = new StaticArray<f64>(NP);   // radians: 0 faces +z, pi/2 faces +x
    tx: StaticArray<f64> = new StaticArray<f64>(NP);     // where it wants to go
    tz: StaticArray<f64> = new StaticArray<f64>(NP);
    spd: StaticArray<f64> = new StaticArray<f64>(NP);    // how fast it wants to go there
    think: StaticArray<f64> = new StaticArray<f64>(NP);
    role: StaticArray<i32> = new StaticArray<i32>(NP);
    stag: StaticArray<f64> = new StaticArray<f64>(NP);   // staggered (s)
    tackCool: StaticArray<f64> = new StaticArray<f64>(NP);
    kickCool: StaticArray<f64> = new StaticArray<f64>(NP); // may not touch the ball (s)
    kickT: StaticArray<f64> = new StaticArray<f64>(NP);  // the kick's swing (s left)
    lunge: StaticArray<f64> = new StaticArray<f64>(NP);
    runPh: StaticArray<f64> = new StaticArray<f64>(NP);
    side: StaticArray<f64> = new StaticArray<f64>(NP);   // a support run's side (+-1)
    hop: StaticArray<f64> = new StaticArray<f64>(NP);    // celebration phase offset
    // keepers (indexed by player)
    ks: StaticArray<i32> = new StaticArray<i32>(NP);
    kT: StaticArray<f64> = new StaticArray<f64>(NP);
    kDir: StaticArray<f64> = new StaticArray<f64>(NP);
    kAng: StaticArray<f64> = new StaticArray<f64>(NP);   // the dive's roll (degrees)
    kReact: StaticArray<f64> = new StaticArray<f64>(NP); // counting down to the dive
    kAimZ: StaticArray<f64> = new StaticArray<f64>(NP);
    kShot: StaticArray<i32> = new StaticArray<i32>(NP);  // the shot it has read
    kAimY: StaticArray<f64> = new StaticArray<f64>(NP);  // how high it reads the shot
    kMax: StaticArray<f64> = new StaticArray<f64>(NP);   // how far over the dive rolls (high balls: less)
    pressHold: StaticArray<i32> = new StaticArray<i32>(2); // each team's presser (hysteresis)

    // the ball
    bx: f64 = 0; by: f64 = BR; bz: f64 = 0;
    bvx: f64 = 0; bvy: f64 = 0; bvz: f64 = 0;
    owner: i32 = -1;
    lastKick: i32 = -1;
    shotId: i32 = 0;           // counts kicks, so a keeper reads each shot once
    shotOn: bool = false;      // the last kick was a shot
    roll: f64 = 0;
    rollYaw: f64 = 0;
    touchT: f64 = 0;
    netT: f64 = 0;

    // you
    ctrl: i32 = 1;
    ptrOn: bool = false;       // a pointer position seen (hover on a mouse, a press on touch)
    ptrHX: f32 = 0; ptrHY: f32 = 0;
    goX: f64 = 0; goZ: f64 = 0; // the pointer on the grass
    pressed: bool = false;
    dragged: bool = false;
    downT: f64 = 0;
    downHX: f32 = 0; downHY: f32 = 0;
    chargeTick: i32 = 0;

    // camera
    camX: f64 = 0;
    camZ: f64 = -1;
    shake: f64 = 0;

    // sound bookkeeping (never decided by a random draw)
    sndFence: f64 = 0;
    sndPost: f64 = 0;
    sndBounce: f64 = 0;

    // ---------------------------------------------------------------- setup

    start(api: GameApi): void {
        api.playable = true;
        let names = ["p0", "p1", "p2", "p3", "p4", "p5"];
        for (let i = 0; i < NP; i++) {
            this.body[i] = api.bone(names[i]);
            this.legL[i] = api.bone(names[i] + "L");
            this.legR[i] = api.bone(names[i] + "R");
            this.hop[i] = <f64>i * 0.37;
            this.side[i] = i % 2 == 0 ? 1.0 : -1.0;
        }
        for (let i = 0; i < NFAN; i++) this.fan[i] = api.bone("fan" + i.toString());
        this.bBall = api.bone("ball");
        this.bRing = api.bone("ring");
        this.pressHold[0] = -1;
        this.pressHold[1] = -1;
    }

    setSkills(): void {
        // Bramblecombe's AI (your teammate, the demo): a little sharper than Fernley
        let h = this.skill[0], c = this.skill[1];
        h.speed = 5.05; h.carry = 4.45; h.thinkMin = 0.16; h.thinkMax = 0.3; h.shotErr = 0.3; h.passErr = 0.09;
        h.tackle = 0.48; h.range = 7.6; h.gkReact = 0.1; h.gkErr = 0.14; h.gkCatch = 0.8;
        c.speed = 4.95; c.carry = 4.35; c.thinkMin = 0.18; c.thinkMax = 0.34; c.shotErr = 0.4; c.passErr = 0.12;
        c.tackle = 0.4; c.range = 7.2; c.gkReact = 0.13; c.gkErr = 0.18; c.gkCatch = 0.72;
    }

    newMatch(): void {
        this.setSkills();
        this.goals[0] = 0;
        this.goals[1] = 0;
        this.clock = MATCH;
        this.tickSec = -1;
    }

    // the kick-off line-up; team kt has the ball on the centre spot
    lineUp(kt: i32): void {
        for (let i = 0; i < NP; i++) {
            let t = team(i), s = attackDir(t);
            let px = 0.0, pz = 0.0;
            if (isKeeper(i)) { px = -s * (PX - 0.8); pz = 0; }
            else if (i == 1 || i == 4) { px = -s * 3.2; pz = s * 2.4; }
            else { px = -s * 4.0; pz = -s * 2.6; }
            if (t == kt && (i == 1 || i == 4)) { px = -s * 0.5; pz = 0; }
            this.x[i] = px; this.z[i] = pz; this.vx[i] = 0; this.vz[i] = 0;
            this.face[i] = s > 0 ? Math.PI * 0.5 : -Math.PI * 0.5;
            this.tx[i] = px; this.tz[i] = pz; this.spd[i] = 0;
            this.stag[i] = 0; this.tackCool[i] = 0; this.kickCool[i] = 0; this.kickT[i] = 0; this.lunge[i] = 0;
            this.ks[i] = K_POS; this.kT[i] = 0; this.kAng[i] = 0; this.kReact[i] = -1; this.kShot[i] = -1;
            this.think[i] = 0.3;
        }
        let k = kt == 0 ? 1 : 4;
        this.owner = k;
        this.bx = this.x[k] + attackDir(kt) * 0.4; this.bz = 0; this.by = BR;
        this.bvx = 0; this.bvy = 0; this.bvz = 0;
        this.lastKick = -1;
        this.shotOn = false;
        this.ctrl = 1;
        this.kickTeam = kt;
    }

    // the demo's opening: Bramblecombe already breaking into Fernley's half, a shot coming
    demoOpening(): void {
        this.newMatch();
        this.lineUp(0);
        this.x[1] = 6.0; this.z[1] = 1.5; this.vx[1] = 4.2; this.vz[1] = -0.5;
        this.x[2] = 6.8; this.z[2] = -2.6; this.vx[2] = 4.4;
        this.x[4] = 4.4; this.z[4] = 0.8; this.vx[4] = 4.6;
        this.x[5] = 8.4; this.z[5] = -0.4; this.vx[5] = 1.0;
        this.x[3] = PX - 0.8; this.z[3] = 0.4;
        this.x[0] = -PX + 0.8;
        for (let i = 0; i < NP; i++) {
            this.face[i] = Math.atan2(this.vx[i], this.vz[i]);
            if (this.vx[i] == 0 && this.vz[i] == 0) this.face[i] = team(i) == 0 ? Math.PI * 0.5 : -Math.PI * 0.5;
        }
        this.owner = 1;
        this.bx = this.x[1] + Math.sin(this.face[1]) * 0.42;
        this.bz = this.z[1] + Math.cos(this.face[1]) * 0.42;
        this.think[1] = 0.32;          // decides (to shoot) a third of a second in
        this.think[4] = 0.1;
        this.setMode(M_PLAY);
        this.camX = clamp(this.bx * 0.9, -7.4, 7.4);
        this.camZ = clamp(this.bz * 0.5 - 2.0, -3.6, 0.2);
    }

    setMode(m: i32): void {
        this.mode = m;
        this.modeT = 0;
    }

    kickOff(api: GameApi, kt: i32): void {
        this.lineUp(kt);
        this.setMode(M_KICKOFF);
        this.whistle(api, 2, 0.16, 0);
    }

    // ---------------------------------------------------------------- sound

    // a pea whistle: blasts of a fast two-note trill (blips around D7), short or long
    whistle(api: GameApi, blasts: i32, len: f64, delay: f64): void {
        let at = delay;
        for (let b = 0; b < blasts; b++) {
            let l = (b == blasts - 1 && blasts > 1) ? len * 3.0 : len;
            let n = <i32>(l / 0.045) + 1;
            for (let k = 0; k < n; k++) {
                api.note(<f64>(86 + (k & 1)), 0.26, 0, SFX_BLIP, at + <f64>k * 0.045);
            }
            at += l + 0.16;
        }
    }

    // the crowd: layers of noise swelling and falling (a cheer), or a short low groan
    crowd(api: GameApi, cheer: bool): void {
        let n = cheer ? 14 : 6;
        for (let i = 0; i < n; i++) {
            let d = <f64>i * (cheer ? 0.12 : 0.1);
            let env = Math.sin(Math.PI * (<f64>i + 0.5) / <f64>n);
            let pan = <f64>((i % 3) - 1) * 0.5;
            if (cheer) {
                api.sound(SFX_WHOOSH, 0.5 + <f64>(i % 4) * 0.05, 0.2 + 0.4 * env, pan, d);
                api.sound(SFX_SPLASH, 0.32 + <f64>(i % 3) * 0.04, 0.12 + 0.22 * env, -pan, d + 0.05);
            } else {
                api.sound(SFX_WHOOSH, 0.3 + <f64>(i % 2) * 0.03, 0.12 + 0.18 * env, pan, d);
            }
        }
    }

    // ---------------------------------------------------------------- kicks

    kick(api: GameApi, p: i32, dx: f64, dz: f64, speed: f64, vy: f64, shot: bool, power: f64): void {
        let l = Math.sqrt(dx * dx + dz * dz);
        if (l < 0.001) { dx = Math.sin(this.face[p]); dz = Math.cos(this.face[p]); l = 1; }
        dx /= l; dz /= l;
        this.owner = -1;
        this.bx = this.x[p] + dx * 0.42;
        this.bz = this.z[p] + dz * 0.42;
        this.by = BR;
        this.bvx = dx * speed; this.bvz = dz * speed; this.bvy = vy;
        this.kickCool[p] = 0.32;
        this.kickT[p] = 0.3;
        this.face[p] = Math.atan2(dx, dz);
        this.lastKick = p;
        this.shotId++;
        this.shotOn = shot;
        if (shot) {
            api.soundAt(SFX_THUD, this.bx, BR, this.bz, 1.05 - 0.3 * power, 0.55 + 0.45 * power);
            api.soundAt(SFX_CLICK, this.bx, BR, this.bz, 0.55, 0.5 + 0.3 * power);
            if (power > 0.6) api.soundAt(SFX_WHOOSH, this.bx, BR, this.bz, 1.3, 0.3, 0.03);
        } else {
            api.soundAt(SFX_THUD, this.bx, BR, this.bz, 1.45, 0.38);
            api.soundAt(SFX_TICK, this.bx, BR, this.bz, 0.7, 0.45);
        }
    }

    // a pass from p to teammate q (leading him), with an error in radians
    passTo(api: GameApi, p: i32, q: i32, err: f64): void {
        let lead = 0.45;
        let qx = this.x[q] + this.vx[q] * lead, qz = this.z[q] + this.vz[q] * lead;
        let dx = qx - this.x[p], dz = qz - this.z[p];
        let d = Math.sqrt(dx * dx + dz * dz);
        let a = Math.atan2(dx, dz) + err;
        let sp = clamp(5.0 + d * 0.95, 7.0, 15.0);
        this.kick(api, p, Math.sin(a), Math.cos(a), sp, d > 9 ? 2.5 : 0.0, false, 0);
    }

    // a shot from p at the goal of the other side, aimed at z = aimZ, power 0..1
    shootAt(api: GameApi, p: i32, gx: f64, aimZ: f64, power: f64, loft: f64): void {
        let dx = gx - this.x[p], dz = aimZ - this.z[p];
        let sp = 9.0 + 13.0 * power;
        let vy = 0.6 + 4.6 * power * power * loft;
        this.kick(api, p, dx, dz, sp, vy, true, power);
    }

    // ---------------------------------------------------------------- input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        this.ptrHX = x;
        this.ptrHY = y;
        this.ptrOn = true;
        if (kind == POINTER_DOWN) {
            if (this.mode == M_READY) {
                this.newMatch();
                this.kickOff(api, 0);
                this.ptrOn = false;      // the start tap is not a run target
                return true;
            }
            if (this.mode == M_OVER) {
                if (this.modeT > 0.8) {
                    this.newMatch();
                    this.kickOff(api, 0);
                    this.ptrOn = false;
                }
                return true;
            }
            this.pressed = true;
            this.dragged = false;
            this.downT = 0;
            this.downHX = x;
            this.downHY = y;
            this.chargeTick = 0;
        } else if (kind == POINTER_MOVE) {
            if (this.pressed) {
                let dx = x - this.downHX, dy = y - this.downHY;
                if (dx * dx + dy * dy > DRAG * DRAG) this.dragged = true;   // a drag only runs
            }
        } else if (kind == POINTER_UP) {
            if (this.pressed) {
                this.pressed = false;
                if (!this.dragged && (this.mode == M_PLAY || this.mode == M_KICKOFF)) {
                    this.release(api);
                }
            }
        }
        return true;
    }

    // a tap passes (or lunges without the ball), a held press shoots
    release(api: GameApi): void {
        let p = this.ctrl;
        if (this.mode != M_PLAY) return;
        if (!api.pick(this.ptrHX, this.ptrHY, 0)) return;
        let gx = <f64>api.hitX, gz = <f64>api.hitZ;
        let dx = gx - this.x[p], dz = gz - this.z[p];
        if (this.downT < TAP) {
            if (this.owner == p) {
                // the teammate nearest that direction, if one is close to it
                let q = mate(p);
                let mx = this.x[q] - this.x[p], mz = this.z[q] - this.z[p];
                let md = Math.sqrt(mx * mx + mz * mz), dd = Math.sqrt(dx * dx + dz * dz);
                let cosA = dd > 0.3 && md > 0.1 ? (mx * dx + mz * dz) / (md * dd) : -1.0;
                if (cosA > 0.82 && md > 1.5 && md < 18) {
                    this.passTo(api, p, q, 0);
                    this.ctrl = q;                 // control goes with the pass
                } else {
                    let sp = clamp(6.0 + dd * 0.8, 8.0, 13.0);
                    this.kick(api, p, dx, dz, sp, 0, false, 0);
                }
            } else if (this.stag[p] <= 0) {
                this.lunge[p] = 0.32;
                this.face[p] = Math.atan2(dx, dz);
                api.soundAt(SFX_WHOOSH, this.x[p], 0.5, this.z[p], 1.1, 0.3);
            }
        } else if (this.owner == p) {
            let power = clamp((this.downT - 0.12) / 1.0, 0.1, 1.0);
            let sp = 9.0 + 13.0 * power;
            this.kick(api, p, dx, dz, sp, 0.6 + 4.6 * power * power, true, power);
        }
    }

    // ---------------------------------------------------------------- the frame

    update(api: GameApi): void {
        let dt = api.dt;
        if (!this.inited || api.demoChanged) {
            this.inited = true;
            this.demo = api.demo;
            this.pressed = false;
            this.ptrOn = false;
            if (this.demo) {
                this.demoOpening();
            } else {
                this.newMatch();
                this.lineUp(0);
                this.setMode(M_READY);
                this.camX = 0; this.camZ = -2.6;
            }
        }
        this.modeT += dt;
        if (this.pressed) {
            this.downT += dt;
            // a rising tick while the shot charges
            if (!this.dragged && this.owner == this.ctrl && this.downT > TAP) {
                let k = <i32>((this.downT - TAP) / 0.12);
                if (k > this.chargeTick && k < 9) {
                    this.chargeTick = k;
                    api.sound(SFX_TICK, 0.8 + <f64>k * 0.12, 0.35);
                }
            }
        }

        if (this.mode == M_KICKOFF && this.modeT > 1.0) {
            this.setMode(M_PLAY);
            this.think[this.kickTeam == 0 ? 1 : 4] = 0.25;
        }
        if (this.mode == M_PLAY) {
            this.clock -= dt;
            let sec = <i32>Math.ceil(this.clock);
            if (sec <= 10 && sec >= 1 && sec != this.tickSec) {
                this.tickSec = sec;
                api.sound(SFX_TICK, sec <= 3 ? 1.5 : 1.2, 0.45);
            }
            if (this.clock <= 0) {
                this.clock = 0;
                this.fullTime(api);
            }
        }
        if (this.mode == M_GOAL && this.modeT > 3.2) {
            if (this.clock <= 0.05) this.fullTime(api);
            else this.kickOff(api, 1 - this.lastScorer);
        }
        if (this.mode == M_OVER && this.demo && this.modeT > 2.0) {
            this.newMatch();
            this.kickOff(api, this.goals[0] >= this.goals[1] ? 1 : 0);
        }

        let live = this.mode == M_PLAY || this.mode == M_GOAL;
        if (this.mode == M_PLAY) {
            this.chooseControl();
            this.roles();
            for (let i = 0; i < NP; i++) {
                if (isKeeper(i)) this.keeper(api, i, dt);
                else if (!this.demo && i == this.ctrl) this.human(api, i);
                else this.ai(api, i, dt);
            }
        } else if (this.mode == M_GOAL) {
            for (let i = 0; i < NP; i++) {
                // the scorers run to the corner flag of their attack, the others walk back
                let t = team(i), s = attackDir(t);
                if (t == this.lastScorer && !isKeeper(i)) {
                    this.tx[i] = s * 9.0 + <f64>(i % 2) * 0.8; this.tz[i] = (i % 2 == 0 ? 4.6 : 3.4);
                    this.spd[i] = 4.0;
                } else {
                    this.tx[i] = this.x[i] - s * 0.5; this.tz[i] = this.z[i];
                    this.spd[i] = isKeeper(i) ? 0.0 : 1.0;
                }
                if (isKeeper(i) && this.ks[i] == K_DIVE) this.keeper(api, i, dt);
                else if (isKeeper(i) && this.ks[i] == K_DOWN) this.keeper(api, i, dt);
            }
        } else {
            for (let i = 0; i < NP; i++) { this.tx[i] = this.x[i]; this.tz[i] = this.z[i]; this.spd[i] = 0; }
        }

        this.movePlayers(api, dt);
        if (live) {
            this.ballStep(api, dt);
            if (this.mode == M_PLAY) this.tackles(api);
        } else {
            this.dribble(dt);
        }
        this.timers(dt);
        this.cameraFollow(api, dt);
        this.draw(api);
    }

    timers(dt: f64): void {
        for (let i = 0; i < NP; i++) {
            if (this.stag[i] > 0) this.stag[i] -= dt;
            if (this.tackCool[i] > 0) this.tackCool[i] -= dt;
            if (this.kickCool[i] > 0) this.kickCool[i] -= dt;
            if (this.kickT[i] > 0) this.kickT[i] -= dt;
            if (this.lunge[i] > 0) this.lunge[i] -= dt;
        }
        if (this.sndFence > 0) this.sndFence -= dt;
        if (this.sndPost > 0) this.sndPost -= dt;
        if (this.sndBounce > 0) this.sndBounce -= dt;
        if (this.netT > 0) this.netT -= dt;
        if (this.shake > 0) this.shake -= dt;
    }

    fullTime(api: GameApi): void {
        this.setMode(M_OVER);
        this.whistle(api, 3, 0.18, 0);
        let gd = this.goals[0] - this.goals[1];
        if (!this.demo && gd > this.best) this.best = gd;     // the demo's matches are not yours
        if (gd > 0) {
            api.sound(SFX_WIN, 1.0, 0.7, 0, 1.4);
            this.crowd(api, true);
        } else if (gd < 0) {
            api.sound(SFX_LOSE, 0.9, 0.6, 0, 1.4);
        } else {
            api.note(67, 0.5, 0, SFX_BELL, 1.4);
            api.note(67, 0.4, 0, SFX_BELL, 1.75);
        }
    }

    // ---------------------------------------------------------------- who does what

    // your player: the one with the ball, else the nearest to it (with some hysteresis)
    chooseControl(): void {
        if (this.demo) return;
        if (this.owner == 1 || this.owner == 2) { this.ctrl = this.owner; return; }
        if (this.lunge[this.ctrl] > 0 || this.pressed) return;
        let c = this.ctrl, o = mate(c);
        if (this.lastKick == c && this.owner < 0 && this.kickCool[c] > 0) return;
        let dc = this.dist2Ball(c), dd = this.dist2Ball(o);
        if (Math.sqrt(dd) < Math.sqrt(dc) - 1.2) this.ctrl = o;
    }

    dist2Ball(i: i32): f64 {
        let dx = this.bx - this.x[i], dz = this.bz - this.z[i];
        return dx * dx + dz * dz;
    }

    // seconds for player i to reach the rolling ball (a coarse intercept)
    reachTime(i: i32): f64 {
        let sp = this.skill[team(i)].speed;
        for (let k = 1; k <= 20; k++) {
            let t = <f64>k * 0.1;
            let f = t * (1.0 - clamp(t * 0.25, 0, 0.6));
            let px = this.bx + this.bvx * f, pz = this.bz + this.bvz * f;
            let dx = px - this.x[i], dz = pz - this.z[i];
            if (Math.sqrt(dx * dx + dz * dz) < sp * t + 0.4) return t;
        }
        return 2.5;
    }

    roles(): void {
        for (let t = 0; t < 2; t++) {
            let a = t == 0 ? 1 : 4, b = a + 1;
            let ot = this.owner >= 0 ? team(this.owner) : -1;
            if (ot == t) {
                if (this.owner == a) { this.role[a] = R_CARRY; this.role[b] = R_SUPPORT; }
                else if (this.owner == b) { this.role[b] = R_CARRY; this.role[a] = R_SUPPORT; }
                else { this.role[a] = R_SUPPORT; this.role[b] = R_SUPPORT; }
                this.pressHold[t] = -1;
            } else if (ot >= 0) {
                let da = Math.sqrt(this.dist2Ball(a)), db = Math.sqrt(this.dist2Ball(b));
                let pr = this.pressHold[t];
                if (pr < 0) pr = da < db ? a : b;
                else if (pr == a && db < da - 1.2) pr = b;
                else if (pr == b && da < db - 1.2) pr = a;
                if (this.stag[pr] > 0) pr = pr == a ? b : a;
                this.pressHold[t] = pr;
                this.role[pr] = R_PRESS;
                this.role[pr == a ? b : a] = R_COVER;
            } else {
                let ra = this.reachTime(a), rb = this.reachTime(b);
                let ch = ra <= rb ? a : b;
                let mine = ra < rb ? ra : rb;
                let o1 = t == 0 ? 4 : 1;
                let theirs = Math.min(this.reachTime(o1), this.reachTime(o1 + 1));
                this.role[ch] = R_CHASE;
                this.role[ch == a ? b : a] = mine <= theirs ? R_SUPPORT : R_COVER;
                this.pressHold[t] = -1;
            }
        }
    }

    human(api: GameApi, i: i32): void {
        // run toward the pointer on the grass (a mouse's hover, a finger's press and drag)
        if (this.ptrOn && api.pick(this.ptrHX, this.ptrHY, 0)) {
            this.goX = <f64>api.hitX;
            this.goZ = <f64>api.hitZ;
            this.tx[i] = this.goX; this.tz[i] = this.goZ;
        } else if (!this.ptrOn) {
            this.tx[i] = this.x[i]; this.tz[i] = this.z[i];
        }
        this.spd[i] = this.owner == i ? 4.6 : 5.15;
    }

    // the outfield AI: a decision every few tenths of a second, steering in between
    ai(api: GameApi, i: i32, dt: f64): void {
        let t = team(i), s = attackDir(t), sk = this.skill[t];
        let ogx = -s * PX, gx = s * PX;          // own goal, the goal it attacks
        this.think[i] -= dt;
        let decide = this.think[i] <= 0;
        if (decide) this.think[i] = api.range(sk.thinkMin, sk.thinkMax);
        let r = this.role[i];
        this.spd[i] = sk.speed;
        if (r == R_CARRY) {
            this.spd[i] = sk.carry;
            let dgx = gx - this.x[i], dgz = -this.z[i];
            let d = Math.sqrt(dgx * dgx + dgz * dgz);
            // the nearest opponent in front
            let thr = -1, thrD = 99.0;
            for (let q = 0; q < NP; q++) {
                if (team(q) == t || isKeeper(q)) continue;
                let ox = this.x[q] - this.x[i], oz = this.z[q] - this.z[i];
                let od = Math.sqrt(ox * ox + oz * oz);
                if (ox * s > -0.6 && od < thrD) { thrD = od; thr = q; }
            }
            if (decide) {
                let m = mate(i);
                let k = keeperOf(1 - t);
                if ((d < sk.range && Math.abs(this.z[i]) < 4.6) || d < 4.2) {
                    // shoot: the corner away from the keeper, mostly
                    let corner = this.z[k] > 0.15 ? -1.0 : (this.z[k] < -0.15 ? 1.0 : (api.rand() < 0.5 ? -1.0 : 1.0));
                    if (api.rand() < 0.28) corner = -corner;
                    let aim = corner * (GW - 0.32) + api.range(-1, 1) * sk.shotErr;
                    let power = clamp(0.5 + d * 0.035 + api.range(0, 0.3), 0.4, 1.0);
                    let loft = d > 6.5 ? api.range(0.3, 1.0) : api.range(0.1, 0.8);
                    this.shootAt(api, i, gx, aim, power, loft);
                    return;
                }
                let open = this.laneOpen(i, m);
                let ahead = (this.x[m] - this.x[i]) * s;
                if (open && ((thr >= 0 && thrD < 1.7 && api.rand() < 0.75) || (ahead > 2.5 && api.rand() < 0.22))) {
                    this.passTo(api, i, m, api.range(-1, 1) * sk.passErr);
                    return;
                }
            }
            // dribble at the goal, slipping round the man in front
            let txx = gx - s * 2.0, tzz = this.z[i] * 0.6;
            if (thr >= 0 && thrD < 2.6) {
                let off = this.z[i] - this.z[thr];
                let dir = Math.abs(off) < 0.2 ? this.side[i] : sgn(off);
                tzz = clamp(this.z[i] + dir * 2.4, -PZ + 0.8, PZ - 0.8);
                txx = this.x[i] + s * 1.6;
            }
            this.tx[i] = txx; this.tz[i] = tzz;
        } else if (r == R_SUPPORT) {
            let k = this.owner;
            if (k >= 0 && isKeeper(k)) {
                this.tx[i] = ogx + s * 6.0; this.tz[i] = this.side[i] * 3.2;
            } else {
                if (decide && api.rand() < 0.08) this.side[i] = -this.side[i];
                let zs = this.bz > 1.0 ? -2.8 : (this.bz < -1.0 ? 2.8 : this.side[i] * 2.8);
                this.tx[i] = clamp(this.bx + s * 3.6, -PX + 2.0, PX - 2.2);
                this.tz[i] = zs;
            }
        } else if (r == R_PRESS) {
            let ux = ogx - this.bx, uz = -this.bz;
            let ul = Math.max(0.01, Math.sqrt(ux * ux + uz * uz));
            this.tx[i] = this.bx + ux / ul * 0.3; this.tz[i] = this.bz + uz / ul * 0.3;
        } else if (r == R_COVER) {
            // between the ball and the goal, leaning toward the other attacker
            let mx = ogx + (this.bx - ogx) * 0.45, mz = this.bz * 0.45;
            let other = -1;
            for (let q = 0; q < NP; q++) {
                if (team(q) != t && !isKeeper(q) && q != this.owner) other = q;
            }
            if (other >= 0) {
                mx = mx * 0.55 + (this.x[other] - s * 1.2) * 0.45;
                mz = mz * 0.55 + this.z[other] * 0.45;
            }
            let lim = ogx + s * 2.2;
            if ((mx - lim) * s < 0) mx = lim;
            this.tx[i] = mx; this.tz[i] = mz;
            this.spd[i] = sk.speed * 0.92;
        } else {
            let rt = this.reachTime(i);
            let f = rt * (1.0 - clamp(rt * 0.25, 0, 0.6));
            this.tx[i] = this.bx + this.bvx * f; this.tz[i] = this.bz + this.bvz * f;
        }
        this.tx[i] = clamp(this.tx[i], -12.2, 12.2);
        this.tz[i] = clamp(this.tz[i], -6.8, 6.8);
    }

    // no opponent within a metre of the line from i to its teammate m
    laneOpen(i: i32, m: i32): bool {
        let ax = this.x[i], az = this.z[i], dx = this.x[m] - ax, dz = this.z[m] - az;
        let l2 = dx * dx + dz * dz;
        if (l2 < 2.0) return false;
        for (let q = 0; q < NP; q++) {
            if (team(q) == team(i)) continue;
            let t = clamp(((this.x[q] - ax) * dx + (this.z[q] - az) * dz) / l2, 0, 1);
            let px = ax + dx * t - this.x[q], pz = az + dz * t - this.z[q];
            if (px * px + pz * pz < 1.0) return false;
        }
        return true;
    }

    // ---------------------------------------------------------------- keepers

    keeper(api: GameApi, i: i32, dt: f64): void {
        let t = team(i), s = attackDir(t), sk = this.skill[t];
        let gx = -s * PX;
        this.kT[i] += dt;
        let st = this.ks[i];
        this.spd[i] = 4.2;
        if (st == K_DIVE) {
            this.kAng[i] = this.kMax[i] * Math.min(1.0, this.kT[i] / 0.16);
            this.vz[i] = this.kDir[i] * 3.8;
            this.tz[i] = this.z[i] + this.vz[i] * 0.1; this.tx[i] = this.x[i];
            if (this.kT[i] > 0.5) {
                this.ks[i] = K_DOWN; this.kT[i] = 0;
                api.soundAt(SFX_THUD, this.x[i], 0.2, this.z[i], 0.8, 0.55);
            }
            return;
        }
        if (st == K_DOWN) {
            this.vz[i] *= 0.8;
            this.tx[i] = this.x[i]; this.tz[i] = this.z[i]; this.spd[i] = 0;
            this.kAng[i] = this.kT[i] < 0.5 ? 85.0 : 85.0 * Math.max(0.0, 1.0 - (this.kT[i] - 0.5) / 0.25);
            if (this.kT[i] > 0.75) {
                this.ks[i] = this.owner == i ? K_HOLD : K_POS; this.kAng[i] = 0; this.kT[i] = 0;
            }
            return;
        }
        this.kAng[i] = 0;
        if (st == K_HOLD) {
            this.tx[i] = this.x[i]; this.tz[i] = this.z[i]; this.spd[i] = 0;
            this.face[i] = s > 0 ? Math.PI * 0.5 : -Math.PI * 0.5;
            if (this.owner != i) { this.ks[i] = K_POS; return; }
            if (this.kT[i] > 1.0) {
                // distribute: a throw to the freer teammate, or a punt up the pitch
                let a = t == 0 ? 1 : 4, b = a + 1;
                let fa = this.freedom(a), fb = this.freedom(b);
                let q = fa > fb ? a : b;
                this.ks[i] = K_POS; this.kT[i] = 0;
                if ((fa > 2.2 || fb > 2.2) && api.rand() < 0.75) {
                    this.passTo(api, i, q, api.range(-0.06, 0.06));
                } else {
                    this.kick(api, i, s * 1.0, api.range(-0.5, 0.5), api.range(13.0, 16.0), api.range(4.5, 6.0), false, 0);
                }
                this.kickCool[i] = 0.7;
                if (!this.demo && t == 0) this.ctrl = q;
            }
            return;
        }
        // read a shot coming at the goal
        let toward = this.owner < 0 && this.bvx * s < -3.0 && this.shotId != this.kShot[i];
        if (toward) {
            let lineX = this.x[i];
            let tt = (lineX - this.bx) / this.bvx;
            if (tt > 0 && tt < 1.4) {
                let zc = this.bz + this.bvz * tt;
                if (Math.abs(zc) < GW + 0.7) {
                    this.kShot[i] = this.shotId;
                    let sp = Math.sqrt(this.bvx * this.bvx + this.bvz * this.bvz);
                    this.kAimZ[i] = zc + api.range(-1, 1) * sk.gkErr * (0.3 + sp / 25.0);
                    this.kAimY[i] = this.by + this.bvy * tt - 0.5 * GRAV * tt * tt;
                    this.kReact[i] = sk.gkReact * api.range(0.8, 1.3);
                }
            }
        }
        if (this.kReact[i] >= 0) {
            this.kReact[i] -= dt;
            if (this.kReact[i] < 0) {
                let off = this.kAimZ[i] - this.z[i];
                if (Math.abs(off) > 0.5) {
                    this.ks[i] = K_DIVE; this.kT[i] = 0; this.kDir[i] = sgn(off);
                    // roll until the hands meet the ball's height
                    let c = clamp((this.kAimY[i] + 0.1) / 1.95, 0.14, 0.87);
                    this.kMax[i] = Math.acos(c) * 180.0 / Math.PI;
                    this.face[i] = s > 0 ? Math.PI * 0.5 : -Math.PI * 0.5;
                    api.soundAt(SFX_WHOOSH, this.x[i], 0.8, this.z[i], 1.0, 0.45);
                    return;
                }
                this.tz[i] = this.kAimZ[i];
                this.spd[i] = 4.5;
            }
        }
        // a loose ball in the box: come and get it
        let bdx = this.bx - gx, bdz = this.bz;
        let bd = Math.sqrt(bdx * bdx + bdz * bdz);
        if (this.owner < 0 && bd < 4.0 && (this.bx - gx) * s > 0) {
            let mine = this.reachTime(i);
            let o1 = t == 0 ? 4 : 1;
            let theirs = Math.min(this.reachTime(o1), this.reachTime(o1 + 1));
            let sp2 = Math.sqrt(this.bvx * this.bvx + this.bvz * this.bvz);
            if (mine < theirs + 0.15 && sp2 < 9) {
                this.ks[i] = K_RUSH;
                this.tx[i] = this.bx; this.tz[i] = this.bz; this.spd[i] = 4.6;
                return;
            }
        }
        this.ks[i] = K_POS;
        if (this.kReact[i] < 0) {
            // on the ball's angle, a step off the line; further out when an attacker closes in
            let out = 0.8;
            if (this.owner >= 0 && team(this.owner) != t && bd < 6.0) out = 0.8 + (6.0 - bd) * 0.3;
            let ux = bdx / Math.max(bd, 0.1), uz = bdz / Math.max(bd, 0.1);
            this.tx[i] = gx + ux * out;
            this.tz[i] = clamp(uz * out * 1.2 + this.bz * 0.12, -1.25, 1.25);
            if ((this.tx[i] - gx) * s < 0.5) this.tx[i] = gx + s * 0.5;
        }
    }

    // how free a player is: the distance to the nearest opponent outfielder
    freedom(i: i32): f64 {
        let best = 99.0;
        for (let q = 0; q < NP; q++) {
            if (team(q) == team(i) || isKeeper(q)) continue;
            let dx = this.x[q] - this.x[i], dz = this.z[q] - this.z[i];
            best = Math.min(best, Math.sqrt(dx * dx + dz * dz));
        }
        return best;
    }

    // ---------------------------------------------------------------- movement

    movePlayers(api: GameApi, dt: f64): void {
        for (let i = 0; i < NP; i++) {
            let dvx = 0.0, dvz = 0.0;
            if (this.stag[i] <= 0 && !(isKeeper(i) && (this.ks[i] == K_DIVE || this.ks[i] == K_DOWN))) {
                let dx = this.tx[i] - this.x[i], dz = this.tz[i] - this.z[i];
                let d = Math.sqrt(dx * dx + dz * dz);
                if (d > 0.08) {
                    let sp = Math.min(this.spd[i], d * 3.0);
                    dvx = dx / d * sp; dvz = dz / d * sp;
                }
                if (this.lunge[i] > 0) {
                    dvx = Math.sin(this.face[i]) * 7.5; dvz = Math.cos(this.face[i]) * 7.5;
                }
            }
            let acc = Math.min(1.0, (this.lunge[i] > 0 ? 18.0 : 8.0) * dt);
            if (isKeeper(i) && this.ks[i] == K_DIVE) {
                dvx = 0; dvz = this.vz[i]; acc = 1;
            }
            this.vx[i] += (dvx - this.vx[i]) * acc;
            this.vz[i] += (dvz - this.vz[i]) * acc;
            this.x[i] += this.vx[i] * dt;
            this.z[i] += this.vz[i] * dt;
            let sp = Math.sqrt(this.vx[i] * this.vx[i] + this.vz[i] * this.vz[i]);
            // face where it runs; a still player turns to the ball
            if (!(isKeeper(i) && this.ks[i] != K_POS && this.ks[i] != K_RUSH)) {
                let want = this.face[i];
                if (sp > 0.6) want = Math.atan2(this.vx[i], this.vz[i]);
                else if (this.mode == M_PLAY && this.owner != i) want = Math.atan2(this.bx - this.x[i], this.bz - this.z[i]);
                let d = want - this.face[i];
                while (d > Math.PI) d -= 2 * Math.PI;
                while (d < -Math.PI) d += 2 * Math.PI;
                this.face[i] += clamp(d, -12.0 * dt, 12.0 * dt);
            }
            this.runPh[i] += sp * dt / 1.15 * 2 * Math.PI;
            // the pitch's walls: the fence, and the goals' frames and nets
            this.x[i] = clamp(this.x[i], -12.25, 12.25);
            this.z[i] = clamp(this.z[i], -6.85, 6.85);
            let ax = Math.abs(this.x[i]), az = Math.abs(this.z[i]);
            if (ax > PX - 0.05 && ax < PX + GD + 0.3 && az < GW + 0.3) {
                let px = ax - (PX - 0.05), pxb = (PX + GD + 0.3) - ax, pz = (GW + 0.3) - az;
                if (px <= pz && px <= pxb) this.x[i] = sgn(this.x[i]) * (PX - 0.05);
                else if (pxb <= pz) this.x[i] = sgn(this.x[i]) * (PX + GD + 0.3);
                else this.z[i] = sgn(this.z[i]) * (GW + 0.3);
            }
        }
        // players push each other apart
        for (let i = 0; i < NP; i++) {
            for (let j = i + 1; j < NP; j++) {
                if (isKeeper(i) && this.ks[i] != K_POS) continue;
                if (isKeeper(j) && this.ks[j] != K_POS) continue;
                let dx = this.x[j] - this.x[i], dz = this.z[j] - this.z[i];
                let d = Math.sqrt(dx * dx + dz * dz);
                let m = PR * 1.8;
                if (d < m && d > 0.001) {
                    let push = (m - d) * 0.5;
                    this.x[i] -= dx / d * push; this.z[i] -= dz / d * push;
                    this.x[j] += dx / d * push; this.z[j] += dz / d * push;
                }
            }
        }
    }

    // ---------------------------------------------------------------- the ball

    dribble(dt: f64): void {
        let o = this.owner;
        if (o < 0) return;
        if (isKeeper(o) && this.ks[o] == K_DOWN) {
            // caught at full stretch: in his hands on the ground
            this.bx = this.x[o]; this.bz = this.z[o] + this.kDir[o] * 1.2; this.by = 0.3;
            this.bvx = 0; this.bvz = 0; this.bvy = 0;
            return;
        }
        if (isKeeper(o) && this.ks[o] == K_HOLD) {
            let s = attackDir(team(o));
            this.bx = this.x[o] + s * 0.28; this.bz = this.z[o]; this.by = 1.0;
            this.bvx = this.vx[o]; this.bvz = this.vz[o]; this.bvy = 0;
            return;
        }
        let sp = Math.sqrt(this.vx[o] * this.vx[o] + this.vz[o] * this.vz[o]);
        // a touch every stride: the ball runs a little ahead, then he catches up with it
        let ph = this.runPh[o];
        let reach = 0.4 + 0.12 * clamp(sp / 4.0, 0, 1) * (0.5 + 0.5 * Math.sin(ph * 0.5));
        let wx = this.x[o] + Math.sin(this.face[o]) * reach;
        let wz = this.z[o] + Math.cos(this.face[o]) * reach;
        wx = clamp(wx, -FXW + BR, FXW - BR);
        wz = clamp(wz, -FZW + BR, FZW - BR);
        let k = Math.min(1.0, 16.0 * dt);
        let nx = this.bx + (wx - this.bx) * k, nz = this.bz + (wz - this.bz) * k;
        this.bvx = dt > 0 ? (nx - this.bx) / dt : 0;
        this.bvz = dt > 0 ? (nz - this.bz) / dt : 0;
        this.bx = nx; this.bz = nz; this.by = BR; this.bvy = 0;
    }

    ballStep(api: GameApi, dt: f64): void {
        if (this.owner >= 0) {
            this.dribble(dt);
            // a touch sound per stride
            let o = this.owner;
            if (!isKeeper(o)) {
                let sp = Math.sqrt(this.vx[o] * this.vx[o] + this.vz[o] * this.vz[o]);
                this.touchT += sp * dt;
                if (this.touchT > 1.5) {
                    this.touchT = 0;
                    api.soundAt(SFX_TICK, this.bx, BR, this.bz, 0.5, 0.28);
                }
            }
            this.goalCheck(api);
            this.spinBall(dt);
            return;
        }
        let n = <i32>Math.ceil(dt / 0.006);
        if (n < 1) n = 1;
        let h = dt / <f64>n;
        for (let k = 0; k < n; k++) {
            this.ballSub(api, h);
            if (this.owner >= 0) break;
        }
        this.spinBall(dt);
    }

    spinBall(dt: f64): void {
        let sp = Math.sqrt(this.bvx * this.bvx + this.bvz * this.bvz);
        if (sp > 0.3) this.rollYaw = Math.atan2(this.bvx, this.bvz) * 180.0 / Math.PI;
        this.roll += sp * dt / BR * 180.0 / Math.PI;
        if (this.roll > 360) this.roll -= 360;
    }

    ballSub(api: GameApi, h: f64): void {
        let air = this.by > BR + 0.001 || this.bvy > 0;
        if (air) {
            this.bvy -= GRAV * h;
            this.bvx *= 1.0 - 0.08 * h;
            this.bvz *= 1.0 - 0.08 * h;
        } else {
            let sp = Math.sqrt(this.bvx * this.bvx + this.bvz * this.bvz);
            if (sp > 0) {
                let ns = Math.max(0.0, sp - (1.3 + 0.32 * sp) * h);
                this.bvx *= ns / sp; this.bvz *= ns / sp;
            }
        }
        this.bx += this.bvx * h;
        this.by += this.bvy * h;
        this.bz += this.bvz * h;
        if (this.by < BR) {
            this.by = BR;
            if (this.bvy < -1.6) {
                let imp = -this.bvy;
                this.bvy = imp * 0.5;
                this.bvx *= 0.88; this.bvz *= 0.88;
                if (this.sndBounce <= 0 && imp > 2.4) {
                    this.sndBounce = 0.12;
                    api.soundAt(SFX_THUD, this.bx, 0, this.bz, 1.35, clamp(imp * 0.06, 0.12, 0.4));
                }
            } else {
                this.bvy = 0;
            }
        }
        this.collideGoals(api);
        // the fence
        if (Math.abs(this.bx) > FXW - BR) {
            let v = Math.abs(this.bvx);
            this.bx = sgn(this.bx) * (FXW - BR);
            this.bvx = -this.bvx * 0.55;
            this.fenceSound(api, v);
        }
        if (Math.abs(this.bz) > FZW - BR) {
            let v = Math.abs(this.bvz);
            this.bz = sgn(this.bz) * (FZW - BR);
            this.bvz = -this.bvz * 0.55;
            this.fenceSound(api, v);
        }
        this.goalCheck(api);
        if (this.mode == M_PLAY) {
            this.keeperSaves(api);
            if (this.owner < 0) this.pickUp(api);
        }
    }

    fenceSound(api: GameApi, v: f64): void {
        if (v > 1.2 && this.sndFence <= 0) {
            this.sndFence = 0.12;
            api.soundAt(SFX_THUD, this.bx, 0.4, this.bz, 0.7, clamp(0.2 + v * 0.04, 0.2, 0.6));
            api.soundAt(SFX_TICK, this.bx, 0.4, this.bz, 0.35, 0.55);
        }
    }

    postSound(api: GameApi, v: f64): void {
        if (this.sndPost <= 0 && v > 1.0) {
            this.sndPost = 0.15;
            let vol = clamp(0.3 + v * 0.03, 0.3, 0.75);
            api.soundAt(SFX_CLICK, this.bx, this.by, this.bz, 0.4, vol);
            api.noteAt(86, this.bx, this.by, this.bz, vol * 0.6, SFX_NOTE);
            api.noteAt(93, this.bx, this.by, this.bz, vol * 0.35, SFX_NOTE, 0.02);
            this.shake = 0.15;
        }
    }

    collideGoals(api: GameApi): void {
        for (let g = 0; g < 2; g++) {
            let s = g == 0 ? -1.0 : 1.0;
            let lx = s * PX;
            // the posts (vertical bars at the mouth)
            if (this.by < GH + BR) {
                for (let p = 0; p < 2; p++) {
                    let pz = p == 0 ? -GW : GW;
                    let dx = this.bx - lx, dz = this.bz - pz;
                    let d = Math.sqrt(dx * dx + dz * dz);
                    if (d < BR + POSTR && d > 0.0001) {
                        let nx = dx / d, nz = dz / d;
                        let vn = this.bvx * nx + this.bvz * nz;
                        this.bx = lx + nx * (BR + POSTR); this.bz = pz + nz * (BR + POSTR);
                        if (vn < 0) {
                            this.bvx -= 1.75 * vn * nx; this.bvz -= 1.75 * vn * nz;
                            this.postSound(api, -vn);
                        }
                    }
                }
            }
            // the crossbar
            if (Math.abs(this.bz) < GW) {
                let dx = this.bx - lx, dy = this.by - GH;
                let d = Math.sqrt(dx * dx + dy * dy);
                if (d < BR + 0.05 && d > 0.0001) {
                    let nx = dx / d, ny = dy / d;
                    let vn = this.bvx * nx + this.bvy * ny;
                    this.bx = lx + nx * (BR + 0.05); this.by = GH + ny * (BR + 0.05);
                    if (vn < 0) {
                        this.bvx -= 1.7 * vn * nx; this.bvy -= 1.7 * vn * ny;
                        this.postSound(api, -vn);
                    }
                }
            }
            let ax = this.bx * s;   // along this goal's outward axis
            let az = Math.abs(this.bz);
            let back = PX + GD;
            if (ax > PX && ax < back + BR && az < GW + BR) {
                let inside = az < GW && this.by < GH;
                if (inside) {
                    // in the net: soft walls that swallow the ball (it never rolls back out)
                    this.bvx *= 0.985; this.bvz *= 0.985;
                    if (this.bvx * s < 0 && ax < PX + BR + 0.1) this.bvx = 0;
                    if (ax > back - BR) {
                        this.bx = s * (back - BR);
                        if (this.bvx * s > 0) { this.netHit(api, Math.abs(this.bvx)); this.bvx = -this.bvx * 0.08; }
                        this.bvz *= 0.6; this.bvy *= 0.6;
                    }
                    if (az > GW - 0.04 - BR) {
                        this.bz = sgn(this.bz) * (GW - 0.04 - BR);
                        if (this.bvz * sgn(this.bz) > 0) this.bvz = -this.bvz * 0.15;
                    }
                    if (this.by > GH - BR) {
                        this.by = GH - BR;
                        if (this.bvy > 0) this.bvy = -this.bvy * 0.2;
                    }
                } else if (this.by - BR > GH - 0.1) {
                    // on the roof of the net: bounce, and roll off behind the goal
                    if (az < GW && this.bvy < 0 && this.by - BR < GH + 0.02) {
                        this.by = GH + BR + 0.02;
                        this.bvy = Math.abs(this.bvy) * 0.3;
                        this.bvx = s * Math.max(Math.abs(this.bvx) * 0.5, 1.0);
                        this.netHit(api, 2.0);
                    }
                } else if (az >= GW) {
                    // outside the side netting: pushed back out
                    let pen = GW + 0.04 + BR - az;
                    if (pen > 0 && ax < back) {
                        this.bz = sgn(this.bz) * (GW + 0.04 + BR);
                        this.bvz = Math.abs(this.bvz) * 0.3 * sgn(this.bz);
                        this.netHit(api, 1.5);
                    }
                } else if (ax > back - 0.02) {
                    // behind the net
                    this.bx = s * (back + BR);
                    if (this.bvx * s < 0) this.bvx = -this.bvx * 0.3;
                }
            }
        }
    }

    netHit(api: GameApi, v: f64): void {
        if (this.netT <= 0 && v > 0.8) {
            this.netT = 0.3;
            api.soundAt(SFX_SPLASH, this.bx, this.by, this.bz, 1.6, clamp(0.15 + v * 0.02, 0.15, 0.4));
            api.soundAt(SFX_WHOOSH, this.bx, this.by, this.bz, 0.6, 0.25);
        }
    }

    goalCheck(api: GameApi): void {
        if (this.mode != M_PLAY) return;
        if (Math.abs(this.bx) > PX + BR * 0.6 && Math.abs(this.bz) < GW - 0.05 && this.by < GH) {
            let scorer = this.bx > 0 ? 0 : 1;
            this.goals[scorer]++;
            this.lastScorer = scorer;
            if (this.owner >= 0) {
                this.bvx = this.vx[this.owner]; this.bvz = this.vz[this.owner];
                this.owner = -1;
            }
            this.setMode(M_GOAL);
            this.shake = 0.35;
            this.pressed = false;
            this.whistle(api, 1, 0.5, 0.15);
            if (scorer == 0) {
                this.crowd(api, true);
                api.sound(SFX_COIN, 1.0, 0.6, 0.4, 0.05);
                api.note(72, 0.55, 0, SFX_NOTE, 0.9);
                api.note(76, 0.55, 0, SFX_NOTE, 1.02);
                api.note(79, 0.55, 0, SFX_NOTE, 1.14);
                api.note(84, 0.6, 0, SFX_BELL, 1.26);
            } else {
                this.crowd(api, false);
                api.note(67, 0.45, 0, SFX_NOTE, 0.8);
                api.note(62, 0.45, 0, SFX_NOTE, 1.0);
            }
        }
    }

    // the keepers' bodies: a segment from the feet to the hands (standing: arms up, diving: rolled)
    keeperSaves(api: GameApi): void {
        for (let g = 0; g < 2; g++) {
            let k = keeperOf(g);
            if (this.kickCool[k] > 0 || this.ks[k] == K_DOWN || this.ks[k] == K_HOLD) continue;
            let s = attackDir(g);
            if ((this.bx - (-s * PX)) * s > 4.5) continue;
            let a = this.kAng[k] * Math.PI / 180.0;
            let lift = this.ks[k] == K_DIVE ? 0.3 * Math.sin(Math.PI * Math.min(1.0, this.kT[k] / 0.5)) : 0.0;
            let ax = this.x[k], ay = lift, az = this.z[k];
            let ex = ax, ey = lift + 1.95 * Math.cos(a), ez = az + this.kDir[k] * 1.95 * Math.sin(a);
            let dx = ex - ax, dy = ey - ay, dz = ez - az;
            let l2 = dx * dx + dy * dy + dz * dz;
            let t = clamp(((this.bx - ax) * dx + (this.by - ay) * dy + (this.bz - az) * dz) / l2, 0, 1);
            let px = ax + dx * t - this.bx, py = ay + dy * t - this.by, pz = az + dz * t - this.bz;
            let reach = 0.45;
            if (px * px + py * py + pz * pz > reach * reach) continue;
            let sp = Math.sqrt(this.bvx * this.bvx + this.bvz * this.bvz + this.bvy * this.bvy);
            let sk = this.skill[g];
            let catchP = sp < 9.0 ? 1.0 : sk.gkCatch * (1.0 - (sp - 9.0) / 14.0);
            if (this.ks[k] == K_DIVE) catchP *= 0.7;
            if (api.rand() < catchP) {
                this.owner = k;
                this.ks[k] = this.ks[k] == K_DIVE ? K_DOWN : K_HOLD;
                if (this.ks[k] == K_DOWN) this.kT[k] = 0.2;
                else this.kT[k] = 0;
                this.bvx = 0; this.bvy = 0; this.bvz = 0;
                api.soundAt(SFX_POP, this.bx, this.by, this.bz, 0.55, 0.65);
                api.soundAt(SFX_THUD, this.bx, this.by, this.bz, 1.5, 0.35);
            } else {
                // parried: out, away from the goal, up into the air
                let out = Math.abs(this.bvx) * 0.4 + 1.5;
                this.bvx = s * out;
                this.bvz = this.bvz * 0.3 + (this.ks[k] == K_DIVE ? this.kDir[k] : sgn(this.bz)) * 2.2;
                this.bvy = 2.6;
                this.by = Math.max(this.by, BR + 0.05);
                this.kickCool[k] = 0.5;
                this.lastKick = k;
                api.soundAt(SFX_THUD, this.bx, this.by, this.bz, 1.1, 0.6);
                api.soundAt(SFX_CLICK, this.bx, this.by, this.bz, 0.7, 0.5);
            }
            this.shotOn = false;
            return;
        }
    }

    // a loose ball near a player's feet: he takes it, or a fast one bounces off him
    pickUp(api: GameApi): void {
        if (this.by > 0.75) return;
        let best = -1, bestD = 0.55;
        for (let i = 0; i < NP; i++) {
            if (this.kickCool[i] > 0 || this.stag[i] > 0) continue;
            if (isKeeper(i) && this.ks[i] != K_POS && this.ks[i] != K_RUSH) continue;
            let fx = this.x[i] + Math.sin(this.face[i]) * 0.2, fz = this.z[i] + Math.cos(this.face[i]) * 0.2;
            let dx = this.bx - fx, dz = this.bz - fz;
            let d = Math.sqrt(dx * dx + dz * dz);
            if (d < bestD) { bestD = d; best = i; }
        }
        if (best < 0) return;
        let i = best;
        let rx = this.bvx - this.vx[i], rz = this.bvz - this.vz[i];
        let rel = Math.sqrt(rx * rx + rz * rz);
        if (rel < 8.5 || (isKeeper(i) && rel < 12.0)) {
            this.owner = i;
            this.shotOn = false;
            if (isKeeper(i)) { this.ks[i] = K_HOLD; this.kT[i] = 0; }   // a keeper picks it up
            if (rel > 3.0) api.soundAt(SFX_THUD, this.bx, BR, this.bz, 1.6, 0.25);
            if (!this.demo && (i == 1 || i == 2)) this.ctrl = i;
        } else {
            // a block: the ball bounces off his shins
            let dx = this.bx - this.x[i], dz = this.bz - this.z[i];
            let d = Math.max(0.01, Math.sqrt(dx * dx + dz * dz));
            let nx = dx / d, nz = dz / d;
            let vn = this.bvx * nx + this.bvz * nz;
            if (vn < 0) { this.bvx -= 1.5 * vn * nx; this.bvz -= 1.5 * vn * nz; }
            this.bvx *= 0.5; this.bvz *= 0.5;
            this.bvy = 1.5;
            this.kickCool[i] = 0.25;
            this.shotOn = false;
            api.soundAt(SFX_THUD, this.bx, BR, this.bz, 1.2, 0.45);
        }
    }

    // running into the man on the ball tackles it
    tackles(api: GameApi): void {
        let o = this.owner;
        if (o < 0 || (isKeeper(o) && this.ks[o] == K_HOLD)) return;
        for (let q = 0; q < NP; q++) {
            if (team(q) == team(o) || this.stag[q] > 0 || this.tackCool[q] > 0) continue;
            if (isKeeper(q) && this.ks[q] != K_POS && this.ks[q] != K_RUSH) continue;
            let dx = this.bx - this.x[q], dz = this.bz - this.z[q];
            let ox = this.x[o] - this.x[q], oz = this.z[o] - this.z[q];
            if (dx * dx + dz * dz > 0.36 && ox * ox + oz * oz > 0.45) continue;
            this.tackCool[q] = 0.9;
            let human = !this.demo && q == this.ctrl;
            let p = human ? 0.55 : this.skill[team(q)].tackle;
            if (this.lunge[q] > 0) p += 0.15;
            if (isKeeper(q)) p = 0.7;
            if (api.rand() < p) {
                // won: the ball pops loose toward the tackler's way
                this.owner = -1;
                let f = this.face[q];
                this.bvx = Math.sin(f) * 3.2 + this.vx[o] * 0.2;
                this.bvz = Math.cos(f) * 3.2 + this.vz[o] * 0.2;
                this.bvy = 0.8;
                this.kickCool[o] = 0.5;
                this.stag[o] = 0.35;
                this.kickCool[q] = 0.08;
                this.lastKick = q;
                this.shotOn = false;
                api.soundAt(SFX_HIT, this.bx, 0.4, this.bz, 0.75, 0.55);
                api.soundAt(SFX_THUD, this.bx, 0.4, this.bz, 1.0, 0.45);
                if (!this.demo && team(q) == 0 && !isKeeper(q)) this.ctrl = q;
            } else {
                // missed: he stumbles past
                this.stag[q] = 0.7;
                this.vx[q] *= 0.3; this.vz[q] *= 0.3;
                this.lunge[q] = 0;
                api.soundAt(SFX_WHOOSH, this.x[q], 0.5, this.z[q], 0.85, 0.35);
                api.soundAt(SFX_THUD, this.x[q], 0.2, this.z[q], 1.3, 0.25, 0.12);
            }
            return;
        }
    }

    // ---------------------------------------------------------------- camera and drawing

    cameraFollow(api: GameApi, dt: f64): void {
        let wx = this.bx * 0.9 + this.bvx * 0.22, wz = this.bz * 0.5 + this.bvz * 0.08 - 2.0;
        if (this.mode == M_READY) { wx = 0; wz = -2.6; }
        wx = clamp(wx, -7.4, 7.4);
        wz = clamp(wz, -3.6, 0.2);
        let k = Math.min(1.0, dt * 3.0);
        this.camX += (wx - this.camX) * k;
        this.camZ += (wz - this.camZ) * k;
        let sh = 0.0;
        if (this.shake > 0) sh = (this.frameOdd(api) ? 1.0 : -1.0) * 0.07 * Math.min(1.0, this.shake / 0.15);
        api.useTarget = true;
        api.targetX = this.camX + sh;
        api.targetY = 0;
        api.targetZ = this.camZ;
    }

    frameOdd(api: GameApi): bool { return (api.frame & 2) != 0; }

    draw(api: GameApi): void {
        let step = Math.floor(api.time * 12.0) / 12.0;       // poses at 12 fps
        for (let i = 0; i < NP; i++) {
            let b = this.body[i];
            if (b < 0) continue;
            let sp = Math.sqrt(this.vx[i] * this.vx[i] + this.vz[i] * this.vz[i]);
            let sf = clamp(sp / 4.5, 0, 1);
            let ph = Math.floor(this.runPh[i] / (2 * Math.PI) * 8.0) / 8.0 * 2 * Math.PI;  // 8 poses a stride
            let yaw = this.face[i] * 180.0 / Math.PI;
            let lean = 9.0 * sf, roll = 0.0, y = 0.05 * Math.abs(Math.sin(ph)) * sf;
            let swing = 36.0 * sf * Math.sin(ph);
            let sL = swing, sR = -swing;
            let sy = 1.0 - 0.04 * sf * Math.abs(Math.cos(ph));
            if (this.kickT[i] > 0) {
                let k = 1.0 - this.kickT[i] / 0.3;
                let a = k < 0.3 ? 45.0 * k / 0.3 : 45.0 - 115.0 * Math.min(1.0, (k - 0.3) / 0.35);
                sR = a; sL = -8.0; lean = -4.0;
            }
            if (this.lunge[i] > 0) { lean = 26.0; sL = -38.0; sR = 32.0; }
            if (this.stag[i] > 0) {
                roll = 12.0 * Math.sin(step * 25.0); lean = -6.0; sL = 10.0; sR = -10.0;
            }
            if (isKeeper(i) && this.kAng[i] > 0) {
                let lxx = Math.cos(this.face[i]), lxz = -Math.sin(this.face[i]);   // the body's +X in the world
                roll = -(lxz * this.kDir[i]) * this.kAng[i] - lxx * 0.0;
                lean = 0; sL = -10.0; sR = 10.0;
                y = this.ks[i] == K_DIVE ? 0.3 * Math.sin(Math.PI * Math.min(1.0, this.kT[i] / 0.5)) : 0.05;
            }
            if (this.mode == M_GOAL && team(i) == this.lastScorer && !isKeeper(i) && this.modeT > 0.6) {
                // celebrating: hops
                let hp = (step + this.hop[i]) * 9.0;
                y = 0.25 * Math.abs(Math.sin(hp));
            }
            if (this.mode == M_READY || this.mode == M_KICKOFF) {
                y = 0.02 * Math.abs(Math.sin(step * 3.0 + this.hop[i]));    // waiting on their toes
            }
            if (isKeeper(i) && this.ks[i] == K_HOLD) { sL = -6.0; sR = 6.0; }
            api.placeScaled(b, this.x[i], y, this.z[i], yaw, 1.0, sy, 1.0, lean, roll);
            // the legs hang from the hips of the placed body
            let rx = <f64>api.restX[b], rz = <f64>api.restZ[b];
            api.transform(b, rx + LEGX, HIP, rz);
            api.place(this.legL[i], api.tx, api.ty, api.tz, yaw, lean + sL, roll);
            api.transform(b, rx - LEGX, HIP, rz);
            api.place(this.legR[i], api.tx, api.ty, api.tz, yaw, lean + sR, roll);
        }
        // the ball rolls
        api.place(this.bBall, this.bx, this.by, this.bz, this.rollYaw, this.roll, 0);
        // the ring under your player
        let showRing = !this.demo && (this.mode == M_PLAY || this.mode == M_KICKOFF);
        if (showRing && this.bRing > 0) api.place(this.bRing, this.x[this.ctrl], 0.04, this.z[this.ctrl], step * 90.0);
        else if (this.bRing > 0) api.hide(this.bRing);
        // the supporters: a stepped sway, jumping at a goal (Bramblecombe's fans for theirs)
        for (let f = 0; f < NFAN; f++) {
            let b = this.fan[f];
            if (b < 0) continue;
            let y = 0.0, lean = 0.0;
            let home = f % 3 != 2;
            if (this.mode == M_GOAL && (this.lastScorer == 0) == home && this.modeT < 3.0) {
                y = 0.3 * Math.abs(Math.sin((step + <f64>f * 0.13) * 8.0));
            } else if (this.mode == M_OVER && this.modeT < 2.5 && this.goals[0] > this.goals[1] && home) {
                y = 0.25 * Math.abs(Math.sin((step + <f64>f * 0.13) * 7.0));
            } else {
                lean = 4.0 * Math.sin(step * 2.0 + <f64>f);
            }
            let yaw = Math.atan2(this.bx - <f64>api.restX[b], this.bz + 8.0) * 180.0 / Math.PI * 0.5;
            api.place(b, <f64>api.restX[b], y, <f64>api.restZ[b], yaw, 0, lean);
        }
    }

    // ---------------------------------------------------------------- the HUD

    hud(api: GameApi): void {
        let ink = api.rampColor(1, 0);         // chalk's darkest (slate)
        let night = api.paletteColor(7);       // #222a5c
        let white = api.rampColor(1, 3);
        let gold = api.rampColor(9, 2);
        let coral = api.rampColor(6, 2);
        let sky = api.rampColor(7, 2);
        let W = <f32>api.hudW;

        // the scoreboard: BRM 0 - 0 FRN, the clock under it
        let sc = "BRAMBLE " + this.goals[0].toString() + " - " + this.goals[1].toString() + " FERNLEY";
        let tw = api.textWidth(sc, 1);
        let x0 = Mathf.floor((W - tw) * 0.5);
        api.rect(x0 - 8, 2, tw + 16, 9, night);
        api.rect(x0 - 6, 4, 3, 5, coral);
        api.rect(x0 + tw + 3, 4, 3, 5, sky);
        api.text(x0, 4, sc, white);
        let c = <i32>Math.ceil(Math.max(0.0, this.clock));
        let cs = (c / 60).toString() + ":" + ((c % 60) < 10 ? "0" : "") + (c % 60).toString();
        let cw = api.textWidth(cs, 1);
        api.rect(Mathf.floor((W - cw) * 0.5) - 2, 11, cw + 4, 7, night);
        api.text(Mathf.floor((W - cw) * 0.5), 12, cs, c <= 10 && this.mode == M_PLAY ? gold : white);

        if (this.mode == M_READY) {
            api.textCentered(90, "CLICK TO KICK OFF", gold, 2, night);
            api.textCentered(105, "YOUR PLAYER RUNS TO THE POINTER", white, 1, night);
            api.textCentered(113, "TAP: PASS   HOLD + RELEASE: SHOOT", white, 1, night);
            api.textCentered(121, "RUN INTO THE BALL CARRIER TO TACKLE", white, 1, night);
        }
        if (this.mode == M_KICKOFF && this.modeT < 0.9 && this.clock > MATCH - 0.5 && this.goals[0] + this.goals[1] == 0) {
            api.textCentered(40, "KICK OFF!", gold, 2, night);
        }
        if (this.mode == M_GOAL && this.modeT > 0.1) {
            let col = this.lastScorer == 0 ? coral : sky;
            if (this.modeT < 2.8 || ((api.frame >> 3) & 1) == 0) api.textCentered(30, "GOAL!", gold, 4, night);
            api.textCentered(54, this.lastScorer == 0 ? "BRAMBLECOMBE SCORE" : "FERNLEY SCORE", col, 1, night);
        }
        if (this.mode == M_OVER) {
            let g0 = this.goals[0], g1 = this.goals[1];
            let res = g0 > g1 ? "YOU WIN" : (g0 < g1 ? "YOU LOSE" : "A DRAW");
            if (this.demo) res = g0 > g1 ? "BRAMBLECOMBE WIN" : (g0 < g1 ? "FERNLEY WIN" : "A DRAW");
            api.rect(Mathf.floor(W * 0.5) - 62, 26, 124, 50, night);
            api.textCentered(30, "FULL TIME", white, 1);
            api.textCentered(39, res + " " + g0.toString() + "-" + g1.toString(), gold, 2);
            let gd = this.best;
            let bs = gd > -999 ? ("BEST " + (gd > 0 ? "+" : "") + gd.toString()) : "";
            api.textCentered(54, bs, white, 1);
            if (!this.demo && this.modeT > 0.8) api.textCentered(64, "CLICK FOR A NEW MATCH", coral, 1);
        }
        if (this.demo || this.mode != M_PLAY) return;

        // the pointer's spot on the grass (where he runs, passes and shoots)
        if (this.ptrOn) {
            let px = Mathf.round(this.ptrHX), py = Mathf.round(this.ptrHY);
            api.rect(px - 2, py, 5, 1, night);
            api.rect(px, py - 2, 1, 5, night);
            api.rect(px - 1, py, 3, 1, white);
            api.rect(px, py - 1, 1, 3, white);
        }
        // the shot's power over your player's head while the press is held
        let p = this.ctrl;
        if (this.pressed && !this.dragged && this.downT > 0.12 && api.project(<f32>this.x[p], 2.0, <f32>this.z[p])) {
            let pw = clamp((this.downT - 0.12) / 1.0, 0.1, 1.0);
            let bx = Mathf.round(api.screenX) - 8, by = Mathf.round(api.screenY) - 4;
            api.rect(bx - 1, by - 1, 18, 5, night);
            let fill = <f32>Math.round(pw * 16.0);
            api.rect(bx, by, fill, 3, pw > 0.75 ? coral : gold);
        }
    }
}
