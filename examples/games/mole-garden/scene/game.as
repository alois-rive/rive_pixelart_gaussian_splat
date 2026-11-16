// Mole Garden: moles pop out of nine molehills in a vegetable bed; click them before they duck back.
// Rabbits pop up too: spare them (a bonked rabbit costs 3 points). 45 seconds a run, faster and
// busier towards the end. One verb: click (the mallet follows the pointer).
import { GameApi, POINTER_DOWN, POINTER_MOVE } from "./game_api";

const HOLES: i32 = 9;
const RABBITS: i32 = 3;
const BONKS: i32 = 3;
const RUN_T: f64 = 45;
const DOWN_Y: f64 = -0.68;      // fully in the hole
const UP_Y: f64 = -0.04;
const RISE_T: f64 = 0.13;
const SINK_T: f64 = 0.16;
const HIT_T: f64 = 0.42;
const MALLET_L: f64 = 1.35;     // grip to head (0.9 m model x 1.5)
const MALLET_YAW: f64 = 75;     // the handle comes from the right: the swing crosses the screen, the target stays in view
const RAISED: f64 = 62;
const STRIKE: f64 = -4;
const HEAD_H: f64 = 0.62;       // the head's centre above a target's base at the strike

// hole states
const EMPTY: i32 = 0;
const RISE: i32 = 1;
const UP: i32 = 2;
const HIT: i32 = 3;
const SINK: i32 = 4;

// run states
const READY: i32 = 0;
const PLAY: i32 = 1;
const OVER: i32 = 2;

function holeX(i: i32): f64 { return -1.5 + 1.5 * <f64>(i % 3); }
function holeZ(i: i32): f64 { return -1.3 + 1.3 * <f64>(i / 3); }

function ease(t: f64): f64 {
    let u = Math.min(Math.max(t, 0), 1);
    return u * u * (3 - 2 * u);
}

// The fixed (or climbing) orthographic camera's target; the renderer snaps it to the art grid.
function aim(api: GameApi, tx: f64, ty: f64, tz: f64): void {
    api.useTarget = true;
    api.targetX = tx;
    api.targetY = ty;
    api.targetZ = tz;
}

export class Game {
    mole: StaticArray<i32> = new StaticArray<i32>(HOLES);
    rabbit: StaticArray<i32> = new StaticArray<i32>(RABBITS);
    bonk: StaticArray<i32> = new StaticArray<i32>(BONKS);
    mallet: i32 = -1;
    // holes: who is in it (-1 a mole, 0..2 a rabbit), its state and clock
    hState: StaticArray<i32> = new StaticArray<i32>(HOLES);
    hWho: StaticArray<i32> = new StaticArray<i32>(HOLES);
    hT: StaticArray<f64> = new StaticArray<f64>(HOLES);
    hStay: StaticArray<f64> = new StaticArray<f64>(HOLES);
    hYaw: StaticArray<f64> = new StaticArray<f64>(HOLES);
    hFrom: StaticArray<f64> = new StaticArray<f64>(HOLES);   // the y a sink starts from
    hLast: StaticArray<f64> = new StaticArray<f64>(HOLES);   // time since the hole was last used
    spawnT: f64 = 0.15;
    // the run
    state: i32 = READY;
    stateT: f64 = 0;
    left: f64 = RUN_T;
    score: i32 = 0;
    best: i32 = 0;
    moles: i32 = 0;
    streak: i32 = 0;
    shakeT: f64 = 9;
    // the mallet
    mx: f64 = 0.4;
    mz: f64 = 0.9;
    goalX: f64 = 0.4;
    goalZ: f64 = 0.9;
    swingT: f64 = 9;
    // effects
    bX: StaticArray<f64> = new StaticArray<f64>(BONKS);
    bY: StaticArray<f64> = new StaticArray<f64>(BONKS);
    bZ: StaticArray<f64> = new StaticArray<f64>(BONKS);
    bT: StaticArray<f64> = new StaticArray<f64>(BONKS);
    nextBonk: i32 = 0;
    popText: Array<string> = new Array<string>();
    popX: Array<f64> = new Array<f64>();
    popY: Array<f64> = new Array<f64>();
    popZ: Array<f64> = new Array<f64>();
    popT: Array<f64> = new Array<f64>();
    popBad: Array<bool> = new Array<bool>();
    // demo
    wasDemo: bool = false;
    dTarget: i32 = -1;
    dWait: f64 = 0;
    dErrX: f64 = 0;
    dErrZ: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < HOLES; i++) {
            this.mole[i] = api.bone("mole" + i.toString());
            this.hState[i] = EMPTY;
            this.hWho[i] = -1;
            this.hLast[i] = 9;
        }
        for (let i = 0; i < RABBITS; i++) this.rabbit[i] = api.bone("rabbit" + i.toString());
        for (let i = 0; i < BONKS; i++) {
            this.bonk[i] = api.bone("bonk" + i.toString());
            this.bT[i] = 9;
        }
        this.mallet = api.bone("mallet");
        this.wasDemo = api.demo;
        this.reset(api);
    }

    // A fresh run: in demo mode it starts at once, otherwise on the first click.
    reset(api: GameApi): void {
        this.popText.length = 0; this.popX.length = 0; this.popY.length = 0; this.popZ.length = 0; this.popT.length = 0;
        this.popBad.length = 0;
        this.state = api.demo ? PLAY : READY;
        this.stateT = 0;
        this.left = RUN_T;
        this.score = 0;
        this.moles = 0;
        this.streak = 0;
        this.spawnT = 0.15;
        this.dTarget = -1;
        for (let i = 0; i < HOLES; i++) {
            if (this.hState[i] != EMPTY) {
                this.hState[i] = SINK;
                this.hT[i] = 0;
                this.hFrom[i] = this.occupantY(i);
            }
        }
    }

    // ------------------------------------------------------------------ spawning

    progress(): f64 { return this.state == PLAY ? 1 - this.left / RUN_T : 0.0; }

    spawn(api: GameApi): void {
        // pick a free hole that has rested a little, starting from a random one
        let start = <i32>Math.floor(api.range(0, 8.999));
        let hole = -1;
        for (let k = 0; k < HOLES; k++) {
            let i = (start + k) % HOLES;
            if (this.hState[i] == EMPTY && this.hLast[i] > 0.4) { hole = i; break; }
        }
        if (hole < 0) return;
        let who = -1;
        if (this.state == PLAY && api.rand() < 0.2) {
            for (let r = 0; r < RABBITS; r++) {
                let busy = false;
                for (let i = 0; i < HOLES; i++) {
                    if (this.hWho[i] == r && this.hState[i] != EMPTY) busy = true;
                }
                if (!busy) { who = r; break; }
            }
        }
        let p = this.progress();
        this.hWho[hole] = who;
        this.hState[hole] = RISE;
        this.hT[hole] = 0;
        this.hStay[hole] = (1.25 - 0.55 * p) * api.range(0.85, 1.15) + (who >= 0 ? 0.3 : 0.0);
        this.hYaw[hole] = api.range(-18, 18);
    }

    occupantY(i: i32): f64 {
        let s = this.hState[i], t = this.hT[i];
        if (s == RISE) return DOWN_Y + (UP_Y - DOWN_Y) * ease(t / RISE_T);
        if (s == UP) return UP_Y;
        if (s == SINK) return this.hFrom[i] + (DOWN_Y - this.hFrom[i]) * ease(t / SINK_T);
        if (s == HIT) return t < 0.12 ? UP_Y : UP_Y + (DOWN_Y - UP_Y) * ease((t - 0.12) / (HIT_T - 0.12));
        return DOWN_Y;
    }

    // ------------------------------------------------------------------ whacking

    whack(api: GameApi, hx: f32, hy: f32): void {
        if (this.state == OVER) {
            if (this.stateT > 0.8) {
                this.reset(api);
                this.state = PLAY; // the click that restarts also starts the clock
            }
            return;
        }
        if (this.state == READY) {
            this.state = PLAY;
            this.stateT = 0;
        }
        this.swingT = 0;
        // the nearest occupant whose head is under the pointer
        let bestI = -1;
        let bestD: f32 = 13;
        for (let i = 0; i < HOLES; i++) {
            let s = this.hState[i];
            if (s != RISE && s != UP) continue;
            let headY = this.hWho[i] >= 0 ? 0.55 : 0.4;
            if (!api.project(<f32>holeX(i), <f32>(this.occupantY(i) + headY), <f32>holeZ(i))) continue;
            let dx = api.screenX - hx, dy = api.screenY - hy;
            let d = Mathf.sqrt(dx * dx + dy * dy);
            if (d < bestD) { bestD = d; bestI = i; }
        }
        if (bestI < 0) {
            // a miss: the mallet thumps the earth where the pointer is
            if (api.pick(hx, hy, 0.3)) { this.mx = api.hitX; this.mz = api.hitZ; this.goalX = this.mx; this.goalZ = this.mz; }
            this.streak = 0;
            return;
        }
        let i = bestI;
        this.mx = holeX(i); this.mz = holeZ(i); this.goalX = this.mx; this.goalZ = this.mz;
        this.hState[i] = HIT;
        this.hT[i] = 0;
        this.hLast[i] = 0;
        if (this.hWho[i] >= 0) {
            this.score = max<i32>(0, this.score - 3);
            this.streak = 0;
            this.shakeT = 0;
            this.pop(holeX(i), 1.0, holeZ(i), "-3 NOT THE BUNNY!", true);
        } else {
            this.moles++;
            this.streak++;
            let gain = this.streak >= 5 ? 2 : 1;
            this.score += gain;
            this.pop(holeX(i), 0.95, holeZ(i), gain > 1 ? "+2 STREAK" : "+1", false);
            let b = this.nextBonk;
            this.nextBonk = (b + 1) % BONKS;
            this.bX[b] = holeX(i); this.bY[b] = 0.55; this.bZ[b] = holeZ(i); this.bT[b] = 0;
        }
    }

    pop(x: f64, y: f64, z: f64, text: string, bad: bool): void {
        this.popText.push(text); this.popX.push(x); this.popY.push(y); this.popZ.push(z); this.popT.push(0); this.popBad.push(bad);
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.reset(api);
        }
        this.stateT += dt;
        if (this.state == PLAY) {
            this.left -= dt;
            if (this.left <= 0) {
                this.left = 0;
                this.state = OVER;
                this.stateT = 0;
                if (this.score > this.best) this.best = this.score;
                for (let i = 0; i < HOLES; i++) {
                    if (this.hState[i] == RISE || this.hState[i] == UP) {
                        this.hFrom[i] = this.occupantY(i);
                        this.hState[i] = SINK;
                        this.hT[i] = 0;
                    }
                }
            }
        }
        // pops: during a run faster and sometimes two at once; before it, a lazy peek now and then
        if (this.state != OVER) {
            this.spawnT -= dt;
            if (this.spawnT <= 0) {
                let p = this.progress();
                this.spawn(api);
                if (this.state == PLAY && api.rand() < 0.15 + 0.35 * p) this.spawn(api);
                this.spawnT = this.state == PLAY ? (0.95 - 0.45 * p) * api.range(0.75, 1.25) : api.range(1.2, 2.2);
            }
        }
        for (let i = 0; i < HOLES; i++) {
            this.hT[i] += dt;
            this.hLast[i] += dt;
            let s = this.hState[i];
            if (s == RISE && this.hT[i] >= RISE_T) { this.hState[i] = UP; this.hT[i] = 0; }
            else if (s == UP && this.hT[i] >= this.hStay[i]) {
                this.hState[i] = SINK; this.hT[i] = 0; this.hFrom[i] = UP_Y; this.hLast[i] = 0;
                if (this.hWho[i] < 0 && this.state == PLAY) this.streak = 0;
            }
            else if ((s == SINK && this.hT[i] >= SINK_T) || (s == HIT && this.hT[i] >= HIT_T)) {
                this.hState[i] = EMPTY; this.hT[i] = 0; this.hLast[i] = 0;
            }
        }
        if (this.state == OVER && api.demo && this.stateT > 2.0) {
            this.reset(api);
        }
        if (api.demo) this.playDemo(api);
        // the mallet glides after its goal
        let a = 1 - Math.exp(-dt * 18);
        this.mx += (this.goalX - this.mx) * a;
        this.mz += (this.goalZ - this.mz) * a;
        this.swingT += dt;
        for (let b = 0; b < BONKS; b++) this.bT[b] += dt;
        let shake = this.shakeT < 0.3 ? (Math.floor(this.shakeT * 30) % 2 == 0 ? 1.0 : -1.0) * 0.05 : 0.0;
        this.shakeT += dt;
        aim(api, shake, 0.2, -0.35);
        for (let i = this.popT.length - 1; i >= 0; i--) {
            this.popT[i] += dt;
            if (this.popT[i] > 0.9) {
                this.popT.splice(i, 1); this.popText.splice(i, 1); this.popX.splice(i, 1);
                this.popY.splice(i, 1); this.popZ.splice(i, 1); this.popBad.splice(i, 1);
            }
        }
        this.place(api);
    }

    // A decent player: notices a mole after a human reaction time, glides over, whacks; leaves rabbits
    // alone (mostly); now and then too slow or a little off.
    playDemo(api: GameApi): void {
        if (this.state != PLAY) return;
        if (this.dTarget >= 0) {
            let i = this.dTarget;
            let s = this.hState[i];
            if (s != RISE && s != UP) { this.dTarget = -1; return; }
            this.goalX = holeX(i) + this.dErrX;
            this.goalZ = holeZ(i) + this.dErrZ;
            this.dWait -= api.dt;
            if (this.dWait <= 0) {
                if (api.project(<f32>(holeX(i) + this.dErrX), <f32>(UP_Y + 0.4), <f32>(holeZ(i) + this.dErrZ))) {
                    this.whack(api, api.screenX, api.screenY);
                }
                this.dTarget = -1;
            }
            return;
        }
        if (this.swingT < 0.18) return;
        // the oldest visible mole (a rabbit only by mistake)
        let pick = -1;
        let oldest = -1.0;
        for (let i = 0; i < HOLES; i++) {
            let s = this.hState[i];
            if (s != UP && s != RISE) continue;
            let age = s == UP ? this.hT[i] + RISE_T : this.hT[i];
            if (this.hWho[i] >= 0 && api.rand() > 0.004) continue;
            if (age > oldest) { oldest = age; pick = i; }
        }
        if (pick < 0) return;
        this.dTarget = pick;
        this.dWait = api.range(0.28, 0.6);
        let off = api.rand() < 0.18;
        this.dErrX = off ? api.range(-0.7, 0.7) : api.range(-0.08, 0.08);
        this.dErrZ = off ? api.range(-0.5, 0.5) : api.range(-0.06, 0.06);
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_MOVE || kind == POINTER_DOWN) {
            if (api.pick(x, y, 0.3)) {
                this.goalX = Math.min(Math.max(api.hitX, -3.2), 3.2);
                this.goalZ = Math.min(Math.max(api.hitZ, -2.4), 2.6);
            }
        }
        if (kind == POINTER_DOWN) this.whack(api, x, y);
        return true;
    }

    // ------------------------------------------------------------------ bones

    place(api: GameApi): void {
        let t = api.time;
        let usedRabbit = new StaticArray<bool>(RABBITS);
        for (let i = 0; i < HOLES; i++) {
            let s = this.hState[i];
            let who = this.hWho[i];
            let b = who >= 0 ? this.rabbit[who] : this.mole[i];
            if (s == EMPTY) { api.hide(this.mole[i]); continue; }
            if (who >= 0) {
                usedRabbit[who] = true;
                api.hide(this.mole[i]);
            }
            let y = this.occupantY(i);
            let sx = 1.0, sy = 1.0, yaw = this.hYaw[i];
            let ht = this.hT[i];
            if (s == RISE) {
                let u = ht / RISE_T;
                sy = 1 + 0.18 * (1 - u); sx = 1 - 0.1 * (1 - u);
            } else if (s == UP) {
                // pop overshoot, then a stepped look-around (8 fps) so it reads hand-animated
                if (ht < 0.14) { let k = Math.sin(ht / 0.14 * Math.PI); sy = 1 - 0.12 * k; sx = 1 + 0.08 * k; }
                let step = Math.floor((t + <f64>i * 0.37) * 8) % 16;
                yaw += step < 8 ? 0.0 : (step < 12 ? 14.0 : -14.0);
                if (who >= 0) { sy *= 1 + 0.03 * Math.sin(t * 9 + <f64>i); }
            } else if (s == HIT) {
                if (who < 0) {
                    // flattened by the mallet, then pressed down into the hole
                    let k = ht < 0.08 ? ht / 0.08 : 1.0;
                    sy = 1 - 0.55 * k; sx = 1 + 0.38 * k;
                } else {
                    // a startled rabbit leaps and spins before diving back
                    let u = Math.min(ht / HIT_T, 1);
                    y = UP_Y + 0.6 * 4 * u * (1 - u) - (u > 0.7 ? (u - 0.7) / 0.3 * 0.68 : 0.0);
                    yaw += 360 * u;
                }
            }
            api.placeScaled(b, holeX(i), y, holeZ(i), yaw, sx, sy, sx);
        }
        for (let r = 0; r < RABBITS; r++) {
            if (!usedRabbit[r]) api.hide(this.rabbit[r]);
        }
        // the mallet: raised over its goal, it smashes down on a click and springs back up
        let p = RAISED + Math.sin(t * 3) * 3;
        let st = this.swingT;
        if (st < 0.05) p = RAISED + (STRIKE - RAISED) * (st / 0.05);
        else if (st < 0.11) p = STRIKE;
        else if (st < 0.32) p = STRIKE + (RAISED + 8 - STRIKE) * ease((st - 0.11) / 0.21);
        else if (st < 0.42) p = RAISED + 8 - 8 * ease((st - 0.32) / 0.1);
        let ys = MALLET_YAW * Math.PI / 180;
        let ps = STRIKE * Math.PI / 180;
        // the grip sits where the head lands on the goal at the strike
        let gx = this.mx + MALLET_L * Math.cos(ps) * Math.sin(ys);
        let gy = HEAD_H - MALLET_L * Math.sin(ps);
        let gz = this.mz + MALLET_L * Math.cos(ps) * Math.cos(ys);
        api.place(this.mallet, gx, gy, gz, MALLET_YAW, p);
        // bonks: a ring of stars spins out over a whacked mole
        for (let b = 0; b < BONKS; b++) {
            let bt = this.bT[b];
            if (bt > 0.45) { api.hide(this.bonk[b]); continue; }
            let u = bt / 0.45;
            api.place(this.bonk[b], this.bX[b], this.bY[b] + 0.3 * u, this.bZ[b], Math.floor(u * 8) * 22.5, 0, 0, 0.5 + 1.0 * u);
        }
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let ink = api.rampColor(0, 0);      // #170e19
        let pale = api.rampColor(8, 1);     // #c0d1cc
        let straw = api.rampColor(4, 2);    // #a19f7c
        let red = api.rampColor(1, 2);      // #775c4f
        let w = <f32>api.hudW;
        let h = <f32>api.hudH;
        api.text(4, 4, "SCORE " + this.score.toString(), pale, 2, ink);
        let b = "BEST " + this.best.toString();
        api.text(w - api.textWidth(b, 1) - 4, 5, b, straw, 1, ink);
        if (api.demo) api.text(w - api.textWidth("DEMO", 1) - 4, 13, "DEMO", pale, 1, ink);
        let secs = <i32>Math.ceil(this.left);
        let tt = "TIME " + secs.toString();
        let hurry = this.state == PLAY && this.left < 6;
        if (!hurry || Math.floor(api.time * 4) % 2 == 0) {
            api.text(Mathf.floor((w - api.textWidth(tt, 2)) * 0.5), 4, tt, hurry ? straw : pale, 2, ink);
        }
        // a time bar under the clock
        let bw: f32 = 60;
        let bx = Mathf.floor((w - bw) * 0.5);
        api.rect(bx, 16, bw, 2, ink);
        api.rect(bx, 16, Mathf.round(bw * <f32>(this.left / RUN_T)), 2, hurry ? straw : pale);
        for (let i = 0; i < this.popT.length; i++) {
            let u = this.popT[i];
            if (api.project(<f32>this.popX[i], <f32>(this.popY[i] + u * 0.6), <f32>this.popZ[i])) {
                let s = this.popText[i];
                if (u < 0.7 || Math.floor(u * 20) % 2 == 0) {
                    let px = Mathf.min(Mathf.max(Mathf.round(api.screenX - api.textWidth(s, 1) * 0.5), 2), w - api.textWidth(s, 1) - 2);
                    api.text(px, Mathf.max(Mathf.round(api.screenY), 22), s, this.popBad[i] ? straw : pale, 1, ink);
                }
            }
        }
        if (this.state == READY && !api.demo) {
            if (Math.floor(api.time * 2) % 4 != 3) api.textCentered(h - 9, "CLICK THE MOLES - SPARE THE RABBITS", pale, 1, ink);
        }
        if (this.state == OVER) {
            api.textCentered(36, "TIME'S UP!", pale, 3, ink);
            api.textCentered(56, this.moles.toString() + " MOLES   SCORE " + this.score.toString() + "   BEST " + this.best.toString(), straw, 1, ink);
            if (!api.demo && this.stateT > 0.8) api.textCentered(h - 9, "CLICK TO PLAY AGAIN", pale, 1, ink);
        }
    }
}
