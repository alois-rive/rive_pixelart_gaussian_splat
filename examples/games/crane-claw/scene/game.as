// Crane Claw: move the pointer to steer the claw over the toy pile, click to drop it. The claw closes
// on whatever is under it; a grab near a toy's middle holds, an edge grab wobbles and may slip on the
// way to the chute. Prizes in the chute score (duck and ball 10, bear and bunny 20, the gem 50).
// 60 seconds a run, the last grab always finishes. One verb (point and click), one machine.
// Demo mode (api.demo) plays itself: it picks a good toy, steers with a little aim error, and now and
// then grabs an edge (a slip) or misses.
import { GameApi, POINTER_DOWN } from "./game_api";

const NT: i32 = 13;              // toys
const NCONF: i32 = 8;            // confetti
const RUN: f64 = 60;             // seconds a run
const Y_TOP: f64 = 2.05;         // the hub's height when it travels
const TIP: f64 = 0.515;          // prong tips below the hub's origin (open)
const HINGE_R: f64 = 0.15;
const HINGE_Y: f64 = 0.015;
const CABLE_LEN: f64 = 3.5;      // the baked cable (scaled down to reach the trolley)
const TROLLEY_Y: f64 = 2.8;
const CABLE_FOOT: f64 = 0.33;    // the cable's foot above the hub's origin
const GRAB_R: f64 = 0.26;        // how far from a toy's middle the claw still takes hold
const SPEED: f64 = 2.3;          // gantry speed, m/s
const CHUTE_X: f64 = -1.75;
const CHUTE_Z: f64 = 0.7;
const XMIN: f64 = -1.95;
const XMAX: f64 = 1.95;
const ZMIN: f64 = -0.7;
const ZMAX: f64 = 1.0;

const S_IDLE: i32 = 0;
const S_DROP: i32 = 1;
const S_CLOSE: i32 = 2;
const S_LIFT: i32 = 3;
const S_CARRY: i32 = 4;
const S_RELEASE: i32 = 5;
const S_EMPTY: i32 = 6;          // came up empty: open the prongs again

const T_REST: i32 = 0;           // toy states
const T_HELD: i32 = 1;
const T_FALL: i32 = 2;
const T_CHUTE: i32 = 3;
const T_GONE: i32 = 4;

// kinds: duck 0, bear 1, bunny 2, ball 3, gem 4
const KIND_H: StaticArray<f64> = [0.62, 0.72, 0.86, 0.54, 0.43];
const KIND_PTS: StaticArray<i32> = [10, 20, 20, 10, 50];
const KIND_HOLD: StaticArray<f64> = [1.0, 1.0, 0.95, 0.85, 0.75];
const KIND_NAME: StaticArray<string> = ["DUCK", "BEAR", "BUNNY", "BALL", "GEM"];

function clamp(v: f64, a: f64, b: f64): f64 {
    return v < a ? a : (v > b ? b : v);
}

// The pile's top (the balls' tops) at x, z: the mound make_env.py laid the balls on.
function surface(x: f64, z: f64): f64 {
    let dx = x - 0.25, dz = z + 0.15;
    return 0.12 + 0.36 * Math.exp(-(dx * dx / 2.4 + dz * dz / 1.1)) + 0.09;
}

function inChute(x: f64, z: f64): bool {
    return x < -1.28 && z > 0.38;
}

export class Game {
    hub: i32 = -1;
    prong: StaticArray<i32> = new StaticArray<i32>(3);
    cable: i32 = -1;
    bridge: i32 = -1;
    trolley: i32 = -1;
    bulbsA: i32 = -1;
    bulbsB: i32 = -1;
    toy: StaticArray<i32> = new StaticArray<i32>(NT);
    kind: StaticArray<i32> = new StaticArray<i32>(NT);
    conf: StaticArray<i32> = new StaticArray<i32>(NCONF);

    // toys
    tx: StaticArray<f64> = new StaticArray<f64>(NT);
    ty: StaticArray<f64> = new StaticArray<f64>(NT);
    tz: StaticArray<f64> = new StaticArray<f64>(NT);
    tvx: StaticArray<f64> = new StaticArray<f64>(NT);
    tvy: StaticArray<f64> = new StaticArray<f64>(NT);
    tvz: StaticArray<f64> = new StaticArray<f64>(NT);
    tyaw: StaticArray<f64> = new StaticArray<f64>(NT);
    tpitch: StaticArray<f64> = new StaticArray<f64>(NT);
    troll: StaticArray<f64> = new StaticArray<f64>(NT);
    tstate: StaticArray<i32> = new StaticArray<i32>(NT);
    tT: StaticArray<f64> = new StaticArray<f64>(NT);
    tSquash: StaticArray<f64> = new StaticArray<f64>(NT);

    // the claw
    cx: f64 = 0.3;
    cz: f64 = 0.0;
    cy: f64 = Y_TOP;
    aimX: f64 = 0.3;
    aimZ: f64 = 0.0;
    queued: bool = false;       // a drop asked for: it falls once the claw reaches the aim
    state: i32 = S_IDLE;
    st: f64 = 0;                // seconds in this state
    dropTo: f64 = 1.0;          // the hub's height at the bottom of this drop
    close: f64 = 0;             // 0 open .. 1 shut
    held: i32 = -1;
    quality: f64 = 0;
    slipAt: f64 = -1;           // seconds into the lift and carry when the toy slips (-1: it holds)
    carryT: f64 = 0;
    wob: f64 = 0;               // the swing's amplitude, degrees
    wobT: f64 = 0;
    swayX: f64 = 0;
    swayZ: f64 = 0;

    // the run
    started: bool = false;
    timeLeft: f64 = RUN;
    over: bool = false;
    overT: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    prizes: i32 = 0;
    lastGrab: bool = false;

    popText: string = "";
    popText2: string = "";
    popT: f64 = 9;
    popX: f64 = 0;
    popY: f64 = 0;
    popZ: f64 = 0;
    popGood: bool = true;

    fx: StaticArray<f64> = new StaticArray<f64>(NCONF);
    fy: StaticArray<f64> = new StaticArray<f64>(NCONF);
    fz: StaticArray<f64> = new StaticArray<f64>(NCONF);
    fvx: StaticArray<f64> = new StaticArray<f64>(NCONF);
    fvy: StaticArray<f64> = new StaticArray<f64>(NCONF);
    fvz: StaticArray<f64> = new StaticArray<f64>(NCONF);
    fT: StaticArray<f64> = new StaticArray<f64>(NCONF);

    // the demo player
    demoTarget: i32 = -1;
    demoErrX: f64 = 0;
    demoErrZ: f64 = 0;
    demoPause: f64 = 0;
    demoGrabs: i32 = 0;         // grabs this run: the first one is careful and holds (the showcase sees a prize)

    start(api: GameApi): void {
        api.playable = true;
        this.hub = api.bone("hub");
        for (let i = 0; i < 3; i++) this.prong[i] = api.bone("prong" + i.toString());
        this.cable = api.bone("cable");
        this.bridge = api.bone("bridge");
        this.trolley = api.bone("trolley");
        this.bulbsA = api.bone("bulbsA");
        this.bulbsB = api.bone("bulbsB");
        let n = 0;
        let names: StaticArray<string> = ["duck", "bear", "bunny", "ball", "gem"];
        let counts: StaticArray<i32> = [4, 3, 2, 3, 1];
        for (let k = 0; k < 5; k++) {
            for (let c = 0; c < counts[k]; c++) {
                this.toy[n] = api.bone(k == 4 ? "gem" : names[k] + c.toString());
                this.kind[n] = k;
                n++;
            }
        }
        for (let i = 0; i < 4; i++) {
            this.conf[i] = api.bone("confy" + i.toString());
            this.conf[i + 4] = api.bone("confm" + i.toString());
        }
        for (let i = 0; i < NCONF; i++) this.fT[i] = 99;
        // the pile: every toy somewhere on it, apart from the others
        for (let i = 0; i < NT; i++) this.tstate[i] = T_GONE;
        for (let i = 0; i < NT; i++) {
            this.spot(api, i);
            this.tstate[i] = T_REST;
            this.ty[i] = surface(this.tx[i], this.tz[i]) - 0.05;
        }
        this.newRun(api);
    }

    // A free place on the pile for toy i (away from the others, out of the chute), and a pose.
    spot(api: GameApi, i: i32): void {
        let bx: f64 = 0, bz: f64 = 0, bestD: f64 = -1;
        for (let tries = 0; tries < 24; tries++) {
            let x = api.range(-1.05, 1.85), z = api.range(-0.62, 0.78);
            if (inChute(x, z) || x < -1.15) continue;
            let dmin: f64 = 9;
            for (let j = 0; j < NT; j++) {
                if (j == i || this.tstate[j] == T_GONE || this.tstate[j] == T_CHUTE) continue;
                let dx = this.tx[j] - x, dz = this.tz[j] - z;
                dmin = Math.min(dmin, Math.sqrt(dx * dx + dz * dz));
            }
            if (dmin > bestD) {
                bestD = dmin;
                bx = x;
                bz = z;
            }
            if (dmin > 0.62) break;
        }
        this.tx[i] = bx;
        this.tz[i] = bz;
        this.tyaw[i] = api.range(-35, 35);
        this.tpitch[i] = api.range(-10, 10);
        this.troll[i] = api.range(-12, 12);
    }

    newRun(api: GameApi): void {
        this.started = api.demo;
        this.timeLeft = RUN;
        this.over = false;
        this.overT = 0;
        this.score = 0;
        this.prizes = 0;
        this.lastGrab = false;
        this.queued = false;
        this.popT = 9;
        if (this.state != S_IDLE) {
            // a toy on its way falls back onto the pile; the claw goes home
            if (this.held >= 0) this.slip(api);
            this.state = S_IDLE;
            this.popT = 9;
        }
        this.close = 0;
        this.cy = Y_TOP;
        this.demoTarget = -1;
        this.demoGrabs = 0;
        if (api.demo) {
            // start right above a toy (action within the first second)
            let t = this.demoPick(api);
            if (t >= 0) {
                this.cx = this.tx[t] + 0.35;
                this.cz = this.tz[t];
                this.aimX = this.cx;
                this.aimZ = this.cz;
            }
            this.demoPause = 0.1;
        }
    }

    // ---------------------------------------------------------------- the loop

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged) {
            this.best = 0;
            this.newRun(api);
        }
        if (this.started && !this.over) {
            this.timeLeft = Math.max(0, this.timeLeft - dt);
            if (this.timeLeft <= 0) {
                if (this.state == S_IDLE) {
                    this.finish();
                } else {
                    this.lastGrab = true;   // the claw is working: this grab still counts
                }
            }
        }
        if (this.over) {
            this.overT += dt;
            if (api.demo && this.overT > 2.0) this.newRun(api);
        }
        if (api.demo && !this.over) this.demoPlay(api, dt);
        this.claw(api, dt);
        this.toys(api, dt);
        this.confetti(api, dt);
        this.popT += dt;
        this.draw(api);
    }

    finish(): void {
        this.over = true;
        this.overT = 0;
        this.lastGrab = false;
        if (this.score > this.best) this.best = this.score;
    }

    moveTo(x: f64, z: f64, dt: f64): bool {
        let dx = x - this.cx, dz = z - this.cz;
        let d = Math.sqrt(dx * dx + dz * dz);
        let step = SPEED * dt;
        if (d <= step) {
            this.cx = x;
            this.cz = z;
            return true;
        }
        // ease in the last few centimetres
        let s = Math.min(step, Math.max(d * 0.25, step * 0.35));
        this.cx += dx / d * s;
        this.cz += dz / d * s;
        return false;
    }

    claw(api: GameApi, dt: f64): void {
        this.st += dt;
        this.wobT += dt;
        let st = this.state;
        if (st == S_IDLE) {
            this.close = Math.max(0, this.close - dt * 3);
            let arrived = this.moveTo(this.aimX, this.aimZ, dt);
            this.cy = Y_TOP + Math.sin(api.time * 2.0) * 0.015;
            if (this.queued && arrived && !this.over) {
                this.queued = false;
                this.drop(api);
            }
        } else if (st == S_DROP) {
            this.cy -= 2.1 * dt;
            if (this.cy <= this.dropTo) {
                this.cy = this.dropTo;
                this.state = S_CLOSE;
                this.st = 0;
            }
        } else if (st == S_CLOSE) {
            this.close = Math.min(1, this.st / 0.32);
            if (this.st >= 0.4) this.grab(api);
        } else if (st == S_LIFT) {
            this.cy += 1.7 * dt;
            this.carryT += dt;
            if (this.cy >= Y_TOP) {
                this.cy = Y_TOP;
                this.state = this.held >= 0 ? S_CARRY : S_EMPTY;
                this.st = 0;
            }
        } else if (st == S_CARRY) {
            this.carryT += dt;
            if (this.moveTo(CHUTE_X, CHUTE_Z, dt)) {
                this.state = S_RELEASE;
                this.st = 0;
            }
        } else if (st == S_RELEASE) {
            this.close = Math.max(0, 1 - this.st / 0.25);
            if (this.held >= 0 && this.st > 0.08) {
                let h = this.held;
                this.held = -1;
                this.tstate[h] = T_CHUTE;
                this.tvx[h] = 0; this.tvy[h] = -0.5; this.tvz[h] = 0;
            }
            if (this.st > 0.45) this.home();
        } else if (st == S_EMPTY) {
            this.close = Math.max(0, 1 - this.st / 0.3);
            if (this.st > 0.35) this.home();
        }
        // the slip: an edge grab lets go somewhere along the way
        if (this.held >= 0 && this.slipAt >= 0 && this.carryT >= this.slipAt) this.slip(api);
        // the swing: a pendulum (the held toy) and a little sway of the claw, damped
        this.wob *= Math.exp(-dt * (this.held >= 0 ? 0.35 : 2.5));
        let ph = this.wobT * 2.0 * Math.PI * 1.35;
        this.swayX = Math.sin(ph) * this.wob * 0.004;
        this.swayZ = Math.cos(ph * 0.83) * this.wob * 0.002;
    }

    home(): void {
        this.state = S_IDLE;
        this.st = 0;
        if (this.lastGrab) this.finish();
    }

    drop(api: GameApi): void {
        if (!this.started) {
            this.started = true;
            this.timeLeft = RUN;
        }
        // how far down: onto the toy under the claw (or the pile)
        let ground = surface(this.cx, this.cz);
        let target = -1;
        let bestD: f64 = GRAB_R + 0.2;
        for (let i = 0; i < NT; i++) {
            if (this.tstate[i] != T_REST) continue;
            let dx = this.tx[i] - this.cx, dz = this.tz[i] - this.cz;
            let d = Math.sqrt(dx * dx + dz * dz);
            if (d < bestD) {
                bestD = d;
                target = i;
            }
        }
        this.dropTo = ground + 0.42;
        if (target >= 0) {
            let h = KIND_H[this.kind[target]];
            let top = this.ty[target] + Math.min(h, 0.62) * 0.62 + 0.42;
            this.dropTo = Math.max(this.dropTo, top);
        }
        this.state = S_DROP;
        this.st = 0;
        this.carryT = 0;
    }

    grab(api: GameApi): void {
        let best = -1;
        let bestD: f64 = GRAB_R;
        for (let i = 0; i < NT; i++) {
            if (this.tstate[i] != T_REST) continue;
            let dx = this.tx[i] - this.cx, dz = this.tz[i] - this.cz;
            let d = Math.sqrt(dx * dx + dz * dz);
            // only a toy whose top the prongs reached
            let top = this.ty[i] + KIND_H[this.kind[i]] * 0.75;
            if (d < bestD && this.cy - TIP < top) {
                bestD = d;
                best = i;
            }
        }
        this.state = S_LIFT;
        this.st = 0;
        this.carryT = 0;
        this.wobT = 0;
        if (best < 0) {
            this.held = -1;
            this.wob = 4;
            this.pop("MISS", "", this.cx, this.cy - 0.3, this.cz, false);
            return;
        }
        let q = 1 - bestD / GRAB_R;
        this.quality = q;
        this.held = best;
        this.tstate[best] = T_HELD;
        let p = clamp(0.12 + 0.8 * q, 0, 0.9) * KIND_HOLD[this.kind[best]];
        this.slipAt = api.rand() < p ? -1 : api.range(0.25, 1.6);
        if (api.demo && this.demoGrabs == 0) this.slipAt = -1;
        if (api.demo) this.demoGrabs++;
        this.wob = 5 + (1 - q) * 24;
    }

    slip(api: GameApi): void {
        let h = this.held;
        if (h < 0) return;
        this.held = -1;
        this.slipAt = -1;
        this.tstate[h] = T_FALL;
        this.tvx[h] = (this.swayX) * 6 + api.range(-0.4, 0.4);
        this.tvy[h] = 0.4;
        this.tvz[h] = api.range(-0.3, 0.3);
        this.wob = 6;
        this.pop("SLIPPED!", "", this.tx[h], this.ty[h] + 0.8, this.tz[h], false);
    }

    pop(a: string, b: string, x: f64, y: f64, z: f64, good: bool): void {
        this.popText = a;
        this.popText2 = b;
        this.popT = 0;
        this.popX = x; this.popY = y; this.popZ = z;
        this.popGood = good;
    }

    toys(api: GameApi, dt: f64): void {
        for (let i = 0; i < NT; i++) {
            let s = this.tstate[i];
            this.tSquash[i] = Math.max(0, this.tSquash[i] - dt * 4);
            if (s == T_HELD) {
                // hangs in the prongs, swinging about the hub
                let h = KIND_H[this.kind[i]];
                let a = this.wob * Math.sin(this.wobT * 2.0 * Math.PI * 1.35);
                let b = this.wob * 0.5 * Math.cos(this.wobT * 2.0 * Math.PI * 1.12);
                let len = TIP + Math.min(h, 0.62) * 0.42;
                let ar = a * Math.PI / 180, br = b * Math.PI / 180;
                this.tx[i] = this.cx + this.swayX + Math.sin(ar) * len;
                this.tz[i] = this.cz + this.swayZ - Math.sin(br) * len;
                this.ty[i] = this.cy - Math.cos(ar) * Math.cos(br) * len;
                this.troll[i] = a;
                this.tpitch[i] = b;
            } else if (s == T_FALL || s == T_CHUTE) {
                this.tvy[i] -= 9.0 * dt;
                this.tx[i] += this.tvx[i] * dt;
                this.ty[i] += this.tvy[i] * dt;
                this.tz[i] += this.tvz[i] * dt;
                this.troll[i] *= Math.exp(-dt * 3);
                this.tpitch[i] *= Math.exp(-dt * 3);
                if (s == T_FALL && inChute(this.tx[i], this.tz[i]) && this.ty[i] < 0.9) {
                    this.tstate[i] = T_CHUTE;   // a lucky slip into the chute still counts
                    s = T_CHUTE;
                }
                if (s == T_CHUTE) {
                    if (this.ty[i] < 0.05) this.prize(api, i);
                    continue;
                }
                this.tx[i] = clamp(this.tx[i], -1.1, 1.95);
                this.tz[i] = clamp(this.tz[i], -0.7, 0.85);
                let g = surface(this.tx[i], this.tz[i]) - 0.05;
                if (this.ty[i] <= g) {
                    this.ty[i] = g;
                    if (this.tvy[i] < -1.2) {
                        this.tvy[i] = -this.tvy[i] * 0.3;
                        this.tvx[i] *= 0.5;
                        this.tvz[i] *= 0.5;
                        this.tSquash[i] = 1;
                    } else {
                        this.tstate[i] = T_REST;
                        this.tSquash[i] = 1;
                        this.tvy[i] = 0;
                    }
                }
            } else if (s == T_GONE) {
                this.tT[i] += dt;
                if (this.tT[i] > (this.kind[i] == 4 ? 14.0 : 1.3)) {   // the gem takes its time to come back
                    // a new prize drops in from the top
                    this.spot(api, i);
                    this.ty[i] = 3.0;
                    this.tvx[i] = 0; this.tvy[i] = 0; this.tvz[i] = 0;
                    this.tstate[i] = T_FALL;
                }
            }
        }
    }

    prize(api: GameApi, i: i32): void {
        this.tstate[i] = T_GONE;
        this.tT[i] = 0;
        if (this.over) return;
        let k = this.kind[i];
        this.score += KIND_PTS[k];
        this.prizes++;
        if (this.score > this.best) this.best = this.score;
        this.pop("+" + KIND_PTS[k].toString(), KIND_NAME[k] + "!", CHUTE_X, 1.25, CHUTE_Z, true);
        for (let j = 0; j < NCONF; j++) {
            this.fx[j] = CHUTE_X + api.range(-0.25, 0.25);
            this.fy[j] = 0.8;
            this.fz[j] = CHUTE_Z + api.range(-0.25, 0.25);
            let a = api.range(0, 2 * Math.PI);
            this.fvx[j] = Math.cos(a) * api.range(0.4, 1.1);
            this.fvz[j] = Math.sin(a) * api.range(0.2, 0.6);
            this.fvy[j] = api.range(2.6, 4.0);
            this.fT[j] = 0;
        }
    }

    confetti(api: GameApi, dt: f64): void {
        for (let j = 0; j < NCONF; j++) {
            if (this.fT[j] > 1.1) {
                api.hide(this.conf[j]);
                continue;
            }
            this.fT[j] += dt;
            this.fvy[j] -= 6.0 * dt;
            this.fx[j] += this.fvx[j] * dt;
            this.fy[j] += this.fvy[j] * dt;
            this.fz[j] += this.fvz[j] * dt;
            let spin = Math.floor(this.fT[j] * 12) * 40 + <f64>j * 50;
            api.place(this.conf[j], this.fx[j], this.fy[j], this.fz[j], spin, spin * 0.7, 0, 1);
        }
    }

    // ---------------------------------------------------------------- the demo player

    demoPick(api: GameApi): i32 {
        let best = -1;
        let bestV: f64 = -1;
        for (let i = 0; i < NT; i++) {
            if (this.tstate[i] != T_REST) continue;
            let dx = this.tx[i] - this.cx, dz = this.tz[i] - this.cz;
            let d = Math.sqrt(dx * dx + dz * dz);
            let v = Math.sqrt(<f64>KIND_PTS[this.kind[i]]) / (1.0 + d * 1.5) * api.range(0.6, 1.4);
            if (v > bestV) {
                bestV = v;
                best = i;
            }
        }
        if (best >= 0) {
            let r = api.rand();
            // a fair hand: most grabs land near the middle, about one in three on an edge or beside the toy
            let e = r < 0.33 ? api.range(0.17, 0.38) : api.range(0.0, 0.13);
            if (this.demoGrabs == 0) e = api.range(0.0, 0.04);
            let a = api.range(0, 2 * Math.PI);
            this.demoErrX = Math.cos(a) * e;
            this.demoErrZ = Math.sin(a) * e * 0.7;
        }
        return best;
    }

    demoPlay(api: GameApi, dt: f64): void {
        if (this.state != S_IDLE) {
            this.demoTarget = -1;
            return;
        }
        if (this.demoTarget < 0 || this.tstate[this.demoTarget] != T_REST) {
            this.demoTarget = this.demoPick(api);
            this.demoPause = api.range(0.2, 0.55);
            if (this.demoTarget < 0) return;
        }
        let t = this.demoTarget;
        this.aimX = clamp(this.tx[t] + this.demoErrX, XMIN, XMAX);
        this.aimZ = clamp(this.tz[t] + this.demoErrZ, ZMIN, ZMAX);
        let dx = this.aimX - this.cx, dz = this.aimZ - this.cz;
        if (dx * dx + dz * dz < 0.0009) {
            this.demoPause -= dt;
            if (this.demoPause <= 0) {
                this.drop(api);
                this.demoTarget = -1;
            }
        }
    }

    // ---------------------------------------------------------------- drawing

    draw(api: GameApi): void {
        let x = this.cx + this.swayX, z = this.cz + this.swayZ, y = this.cy;
        api.place(this.hub, x, y, z, 0);
        // three prongs round the collar, swung shut by `close` (stepped: 8 poses)
        let c = Math.floor(this.close * 8) / 8;
        let ang = -c * 30;
        let yaws: StaticArray<f64> = [90, 210, -30];
        for (let k = 0; k < 3; k++) {
            let yr = yaws[k] * Math.PI / 180;
            api.place(this.prong[k], x + HINGE_R * Math.cos(yr), y + HINGE_Y, z - HINGE_R * Math.sin(yr), yaws[k], 0, ang);
        }
        let foot = y + CABLE_FOOT;
        let len = Math.max(0.05, TROLLEY_Y + 0.05 - foot);
        api.placeScaled(this.cable, x, foot, z, 0, 1, len / CABLE_LEN, 1);
        api.place(this.bridge, this.cx, 3.06, 0);
        api.place(this.trolley, this.cx, TROLLEY_Y, this.cz);

        // chase lights: the two sets swap four times a second (faster when time runs short)
        let rate: f64 = this.started && !this.over && this.timeLeft < 10 ? 8 : 4;
        if (this.over && Math.floor(this.overT * 6) % 2 == 0) {
            api.reset(this.bulbsA);
            api.reset(this.bulbsB);
        } else if (Math.floor(api.time * rate) % 2 == 0) {
            api.reset(this.bulbsA);
            api.hide(this.bulbsB);
        } else {
            api.hide(this.bulbsA);
            api.reset(this.bulbsB);
        }

        for (let i = 0; i < NT; i++) {
            let s = this.tstate[i];
            if (s == T_GONE) {
                api.hide(this.toy[i]);
                continue;
            }
            let q = this.tSquash[i];
            let sq = q > 0 ? Math.sin(q * Math.PI) * 0.18 : 0;
            api.placeScaled(this.toy[i], this.tx[i], this.ty[i], this.tz[i], this.tyaw[i], 1 + sq * 0.6, 1 - sq, 1 + sq * 0.6,
                            this.tpitch[i], this.troll[i]);
        }
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (this.over) {
            if (kind == POINTER_DOWN && this.overT > 0.6) this.newRun(api);
            return true;
        }
        if (api.pick(x, y, 0.62)) {
            this.aimX = clamp(<f64>api.hitX, XMIN, XMAX);
            this.aimZ = clamp(<f64>api.hitZ, ZMIN, ZMAX);
        }
        if (kind == POINTER_DOWN && this.state == S_IDLE) {
            this.queued = true;
        }
        return true;
    }

    // ---------------------------------------------------------------- HUD

    hud(api: GameApi): void {
        let white = api.paletteColor(0);
        let pink = api.paletteColor(1);
        let hot = api.paletteColor(2);
        let dark = api.paletteColor(5);
        let yellow = api.paletteColor(13);
        let mint = api.paletteColor(11);
        let peri = api.paletteColor(7);
        let W = <f32>api.hudW, H = <f32>api.hudH;

        // where the claw will land: a little cross on the pile under it (while it waits)
        if (this.state == S_IDLE && !this.over) {
            let gy = surface(this.cx, this.cz);
            if (api.project(<f32>this.cx, <f32>gy, <f32>this.cz)) {
                let sx = Mathf.round(api.screenX), sy = Mathf.round(api.screenY);
                api.rect(sx - 2, sy, 5, 1, white);
                api.rect(sx, sy - 2, 1, 5, white);
            }
        }
        // the chute's label
        if (api.project(<f32>CHUTE_X, 1.02, <f32>CHUTE_Z)) {
            let tw = api.textWidth("PRIZE", 1);
            let bx = Mathf.round(api.screenX - tw * 0.5);
            let blink = this.state == S_CARRY && Math.floor(api.time * 4) % 2 == 0;
            api.text(bx, api.screenY, "PRIZE", blink ? white : yellow, 1, dark);
        }

        api.text(4, 4, "SCORE " + this.score.toString(), white, 1, dark);
        let bs = "BEST " + this.best.toString();
        api.text(W - 4 - api.textWidth(bs, 1), 4, bs, yellow, 1, dark);
        let secs = <i32>Math.ceil(this.timeLeft);
        let ts = (secs < 10 ? "0:0" : "0:") + secs.toString();
        if (secs >= 60) ts = "1:00";
        let low = this.started && secs <= 10 && !this.over;
        if (!low || Math.floor(api.time * 4) % 2 == 0) {
            api.textCentered(4, ts, low ? hot : white, 2, dark);
        }
        if (this.prizes > 0) api.text(4, 12, "PRIZES " + this.prizes.toString(), mint, 1, dark);
        if (api.demo) api.text(W - 4 - api.textWidth("DEMO", 1), 12, "DEMO", peri, 1, dark);
        if (this.lastGrab && !this.over) api.textCentered(18, "LAST GRAB!", hot, 1, dark);

        if (this.popT < 1.2 && api.project(<f32>this.popX, <f32>(this.popY + this.popT * 0.5), <f32>this.popZ)) {
            let sc = this.popGood ? 2 : 1;
            let x = Mathf.round(api.screenX - api.textWidth(this.popText, sc) * 0.5);
            api.text(x, api.screenY, this.popText, this.popGood ? yellow : pink, sc, dark);
            if (this.popText2.length > 0) {
                let x2 = Mathf.round(api.screenX - api.textWidth(this.popText2, 1) * 0.5);
                api.text(x2, api.screenY + 12, this.popText2, white, 1, dark);
            }
        }

        if (!this.started && !api.demo && !this.over) {
            api.rect(W * 0.5 - 66, H - 26, 132, 20, dark);
            api.textCentered(H - 23, "MOVE TO AIM THE CLAW", white, 1, 0);
            api.textCentered(H - 15, "CLICK TO DROP IT - 60 SECONDS", yellow, 1, 0);
        }
        if (this.over) {
            let y: f32 = 36;
            let tall: f32 = !api.demo && this.overT > 0.6 ? 52 : 42;
            api.rect(W * 0.5 - 64, y - 6, 128, tall, dark);
            api.textCentered(y, "TIME UP!", hot, 2, 0);
            api.textCentered(y + 14, "PRIZES " + this.prizes.toString(), mint, 1, 0);
            api.textCentered(y + 24, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), yellow, 1, 0);
            if (!api.demo && this.overT > 0.6) api.textCentered(y + 34, "CLICK TO PLAY AGAIN", white, 1, 0);
        }
    }
}
