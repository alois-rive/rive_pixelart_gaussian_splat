// Sprout Jump: a platformer. Pip, a radish sprout, climbs from a garden into the treetops: run toward
// the pointer, press above Pip to jump (hold to jump higher, let go to cut it), a quick second press
// in the air jumps again. Seeds to collect, critters to stomp, three lives, checkpoints, a flag at the
// top. The whole game is in this file (the renderer, splat_scene.as and game_api.as, is the skill's).
//
// World: metres, Y up; Pip runs along X at z 0, the camera looks along -Z from a 10 degree pitch,
// orthographic, 5.44 m tall (a texel of exactly 0.04 m). The level (beds, pots, walls, crates, the
// sunflowers, the branches) is one static bake; what moves is a game bone: Pip's body, sprout and two
// feet, pools of seeds and critters (given to the ones near the camera), the springs, the leaf rafts,
// the bridge planks, the checkpoint blooms, the pennant, puffs, the water band and the parallax
// backdrops. Every bone is put on the texel grid (x by 0.04, y by 0.04 / cos 10), so nothing crawls.
//
// Physics: a fixed 1/120 s step against an axis-aligned map (the tables below): solid blocks, one-way
// platforms (branches, flowers, rafts, planks), springs; coyote time, jump buffering, a variable jump
// (gravity is lighter while the press is held), a double jump for a quick second press. The demo
// player predicts with the same step function: it runs right, and when running on would hurt, fall
// or stall, it simulates 20 jumps (hold, double jump, steering) and takes the best safe one, correcting
// in the air; now and then it hesitates, and sometimes it fumbles a jump (no correction), so it falls.
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP, SFX_BELL, SFX_CLICK, SFX_COIN, SFX_HIT,
    SFX_JUMP, SFX_LOSE, SFX_NOTE, SFX_POP, SFX_SHOOT, SFX_SPLASH, SFX_THUD, SFX_TICK, SFX_WHOOSH, SFX_WIN } from "./game_api";

// LEVEL BEGIN (written by models/level/make_level.py --as from layout.py)
const WATER_Y: f64 = -0.90;
const WATER_END: f64 = 104.00;
const SOL: StaticArray<f64> = [-6.00, 8.00, 0.00, 4.60, 5.60, 0.80, 10.00, 19.00, 0.00, 16.40, 17.60, 1.30, 21.40, 28.00, 0.60, 28.00, 29.60, 1.50, 29.60, 31.20, 2.40, 35.60, 43.00, 2.60, 50.00, 58.50, 1.20, 66.50, 72.00, 1.00, 72.00, 75.00, 2.20, 77.40, 78.60, 2.00, 80.20, 81.40, 2.80, 86.40, 90.00, 2.60, 92.20, 97.00, 1.60, 97.00, 100.00, 2.20, 100.00, 103.00, 3.20];
const ONE: StaticArray<f64> = [59.60, 60.90, 2.60, 62.00, 63.30, 3.60, 64.50, 65.80, 2.80, 103.80, 107.20, 6.40, 108.80, 112.00, 7.20, 115.80, 119.60, 8.80, 121.00, 123.20, 8.20, 125.80, 130.50, 8.60, 135.60, 139.40, 9.40, 140.60, 144.40, 12.40, 146.00, 147.40, 11.80, 149.60, 151.00, 12.60, 154.80, 158.40, 13.80, 164.00, 167.00, 14.80, 168.60, 170.00, 15.60, 171.60, 180.00, 16.20];
const MOV: StaticArray<f64> = [33.40, 2.40, 0, 1.00, 4.00, 83.80, 2.80, 0, 1.10, 3.80, 113.90, 7.60, 1, 1.10, 3.60, 133.00, 9.00, 0, 1.20, 4.40, 152.90, 13.20, 1, 0.90, 3.20, 161.20, 14.20, 0, 1.20, 4.00];
const BRIDGE: StaticArray<f64> = [43.00, 7, 1.00, 2.50];
const SPR: StaticArray<f64> = [25.00, 0.60, 102.00, 3.20, 138.80, 9.40];
const BUG: StaticArray<f64> = [11.40, 15.20, 0.00, 38.40, 42.40, 2.60, 52.00, 56.40, 1.20, 87.90, 89.80, 2.60, 109.20, 111.60, 7.20, 135.90, 138.00, 9.40, 164.30, 166.70, 14.80];
const MOTH: StaticArray<f64> = [124.50, 9.30, 1, 0.90, 2.60, 148.30, 12.90, 0, 0.70, 3.00];
const CP: StaticArray<f64> = [0.50, 0.00, 36.60, 2.60, 67.60, 1.00, 86.80, 2.60, 127.00, 8.60];
const FLAG_X: f64 = 177.50;
const FLAG_Y: f64 = 16.20;
const SEED: StaticArray<f64> = [2.40, 0.45, 3.20, 0.45, 5.10, 1.55, 8.70, 1.40, 9.40, 1.40, 12.60, 1.50, 13.40, 1.80, 14.20, 1.50, 17.00, 2.15, 20.20, 1.80, 25.00, 2.60, 25.00, 3.50, 25.00, 4.40, 29.60, 3.10, 33.40, 3.20, 39.40, 3.30, 40.40, 3.70, 41.40, 3.30, 44.50, 3.30, 46.50, 3.30, 48.50, 3.30, 53.40, 2.60, 55.00, 2.60, 60.25, 3.30, 62.65, 4.30, 65.15, 3.50, 69.00, 1.70, 73.50, 2.90, 76.20, 2.90, 78.00, 2.70, 79.40, 3.60, 80.80, 3.50, 83.80, 3.50, 88.20, 3.90, 91.10, 3.00, 94.00, 2.30, 95.00, 2.30, 98.50, 2.90, 102.00, 5.00, 103.20, 7.00, 105.50, 7.10, 110.40, 8.60, 113.90, 9.80, 116.60, 9.50, 117.70, 9.50, 118.80, 9.50, 124.50, 10.90, 128.40, 9.30, 133.00, 10.00, 138.80, 11.60, 138.80, 12.60, 142.50, 13.10, 148.30, 14.20, 152.90, 15.00, 156.60, 14.50, 161.20, 15.00, 165.50, 16.30, 169.30, 16.40, 174.00, 16.90, 175.20, 16.90];
// LEVEL END

const NSOL: i32 = SOL.length / 3;
const NONE: i32 = ONE.length / 3;
const NMOV: i32 = MOV.length / 5;
const NPL: i32 = 7;
const NSPR: i32 = SPR.length / 2;
const NBUG: i32 = BUG.length / 3;
const NMOTH: i32 = MOTH.length / 5;
const NCP: i32 = CP.length / 2;
const NSEED: i32 = SEED.length / 2;

// physics (metres, seconds); the Python port these were tuned in is described in the README
const STEP: f64 = 1.0 / 120.0;
const HW: f64 = 0.26;          // Pip's half width and height (the bulb; the leaves do not collide)
const HH: f64 = 0.75;
const VMAX: f64 = 4.2;
const ACC_G: f64 = 30.0;
const ACC_A: f64 = 18.0;
const DEC_G: f64 = 40.0;
const GU_HELD: f64 = 24.0;     // rising with the press held: a high, floaty jump
const GU: f64 = 60.0;          // rising after a release: the jump is cut
const GD: f64 = 36.0;          // falling
const VFALL: f64 = 13.0;
const JUMP_V: f64 = 9.4;       // held: 1.84 m; tapped: about 0.75 m
const DJ_V: f64 = 8.0;
const SPRING_V: f64 = 14.2;    // about 4.2 m
const STOMP_V: f64 = 8.0;
const COYOTE: f64 = 0.10;
const BUFFER: f64 = 0.14;
const DJ_WIN: f64 = 0.5;       // a second press this soon after the first is a double jump
const MOVER_W: f64 = 1.6;
const SPRING_W: f64 = 0.5;
const SPRING_H: f64 = 0.5;
const BUG_HW: f64 = 0.32;
const BUG_H: f64 = 0.42;
const BUG_V: f64 = 1.1;
const MOTH_HW: f64 = 0.3;
const MOTH_HH: f64 = 0.26;
const PLANK_DELAY: f64 = 0.45;
const PLANK_BACK: f64 = 3.0;

// the art grid
const TEXEL: f64 = 0.04;
const TEXEL_Y: f64 = 0.04 / 0.984807753;   // a whole texel on screen for a vertical move at pitch 10

// events a real run reports (predictions record nothing)
const EV_JUMP: i32 = 1;
const EV_DJ: i32 = 2;
const EV_LAND: i32 = 3;
const EV_BOING: i32 = 4;
const EV_STOMP: i32 = 5;   // a: 0 bug, 1 moth; b: index
const EV_CREAK: i32 = 6;
const EV_SEED: i32 = 7;
const EV_CP: i32 = 8;

// game states
const READY: i32 = 0;
const PLAY: i32 = 1;
const DYING: i32 = 2;
const OVER: i32 = 3;
const CLEAR: i32 = 4;

// HUD ramps (palette.json order)
const R_RADISH: i32 = 7;
const R_CREAM: i32 = 8;
const R_SPROUT: i32 = 9;
const R_INK: i32 = 10;
const R_GOLD: i32 = 13;
const R_PETAL: i32 = 14;
const R_CLOUD: i32 = 15;

function moverX(i: i32, t: f64): f64 {
    let o = i * 5;
    if (MOV[o + 2] != 0) return MOV[o];
    return MOV[o] + MOV[o + 3] * Math.sin(2 * Math.PI * t / MOV[o + 4]);
}
function moverY(i: i32, t: f64): f64 {
    let o = i * 5;
    if (MOV[o + 2] == 0) return MOV[o + 1];
    return MOV[o + 1] + MOV[o + 3] * Math.sin(2 * Math.PI * t / MOV[o + 4]);
}
function bugU(i: i32, t: f64): f64 {     // 0..2: there and back
    let span = BUG[i * 3 + 1] - BUG[i * 3];
    let u = (t * BUG_V / span) % 2.0;
    return u;
}
function bugX(i: i32, t: f64): f64 {
    let a = BUG[i * 3], span = BUG[i * 3 + 1] - a;
    let u = bugU(i, t);
    return a + span * (u < 1 ? u : 2 - u);
}
function mothX(i: i32, t: f64): f64 {
    let o = i * 5;
    if (MOTH[o + 2] != 0) return MOTH[o];
    return MOTH[o] + MOTH[o + 3] * Math.sin(2 * Math.PI * t / MOTH[o + 4]);
}
function mothY(i: i32, t: f64): f64 {
    let o = i * 5;
    if (MOTH[o + 2] == 0) return MOTH[o + 1];
    return MOTH[o + 1] + MOTH[o + 3] * Math.sin(2 * Math.PI * t / MOTH[o + 4]);
}
function snapX(x: f64): f64 { return Math.round(x / TEXEL) * TEXEL; }
function snapY(y: f64): f64 { return Math.round(y / TEXEL_Y) * TEXEL_Y; }
function clamp(v: f64, a: f64, b: f64): f64 { return v < a ? a : (v > b ? b : v); }

// ---------------------------------------------------------------------------------------- the run
// Everything the physics needs; copied for the demo player's predictions.
class Run {
    t: f64 = 0;
    x: f64 = 0; y: f64 = 0; vx: f64 = 0; vy: f64 = 0;
    ground: bool = true; on: i32 = -1; lastG: f64 = 0; jumped: bool = false;
    held: bool = false; spring: bool = false; dj: bool = true; pressT: f64 = -9; bufT: f64 = -9;
    plank: StaticArray<f64> = new StaticArray<f64>(NPL);
    bugDead: StaticArray<bool> = new StaticArray<bool>(NBUG);
    mothDead: StaticArray<bool> = new StaticArray<bool>(NMOTH);
    got: StaticArray<bool> = new StaticArray<bool>(NSEED);
    dead: bool = false; hurt: bool = false; inv: f64 = -9; win: bool = false; seeds: i32 = 0; cp: i32 = 0;
    landV: f64 = 0;
    rec: bool = false;              // record events (the real run only)
    evK: Array<i32> = new Array<i32>();
    evA: Array<f64> = new Array<f64>();
    evB: Array<f64> = new Array<f64>();

    reset(): void {
        this.t = 0; this.x = CP[0]; this.y = CP[1]; this.vx = 0; this.vy = 0;
        this.ground = true; this.on = -1; this.lastG = 0; this.jumped = false;
        this.held = false; this.spring = false; this.dj = true; this.pressT = -9; this.bufT = -9;
        for (let i = 0; i < NPL; i++) this.plank[i] = -1;
        for (let i = 0; i < NBUG; i++) this.bugDead[i] = false;
        for (let i = 0; i < NMOTH; i++) this.mothDead[i] = false;
        for (let i = 0; i < NSEED; i++) this.got[i] = false;
        this.dead = false; this.hurt = false; this.inv = -9; this.win = false; this.seeds = 0; this.cp = 0;
        this.evK.length = 0; this.evA.length = 0; this.evB.length = 0;
    }

    copyFrom(o: Run): void {
        this.t = o.t; this.x = o.x; this.y = o.y; this.vx = o.vx; this.vy = o.vy;
        this.ground = o.ground; this.on = o.on; this.lastG = o.lastG; this.jumped = o.jumped;
        this.held = o.held; this.spring = o.spring; this.dj = o.dj; this.pressT = o.pressT; this.bufT = o.bufT;
        for (let i = 0; i < NPL; i++) this.plank[i] = o.plank[i];
        for (let i = 0; i < NBUG; i++) this.bugDead[i] = o.bugDead[i];
        for (let i = 0; i < NMOTH; i++) this.mothDead[i] = o.mothDead[i];
        for (let i = 0; i < NSEED; i++) this.got[i] = o.got[i];
        this.dead = o.dead; this.hurt = o.hurt; this.inv = o.inv; this.win = o.win; this.seeds = o.seeds; this.cp = o.cp;
        this.rec = false;
    }

    ev(k: i32, a: f64, b: f64): void {
        if (!this.rec) return;
        this.evK.push(k); this.evA.push(a); this.evB.push(b);
    }

    jump(v: f64): void {
        this.vy = v; this.ground = false; this.on = -1; this.jumped = true; this.spring = false; this.dj = true;
        this.ev(EV_JUMP, this.y, 0);
    }

    // a press: a jump (on the ground or just off it), a double jump (soon after the first press),
    // or kept for a moment and used on landing. True when it jumped.
    press(): bool {
        this.held = true;
        let did = false;
        if (this.ground || (this.t - this.lastG < COYOTE && !this.jumped)) {
            this.jump(JUMP_V);
            did = true;
        } else if (this.dj && this.t - this.pressT < DJ_WIN) {
            this.dj = false; this.vy = DJ_V; this.spring = false;
            this.ev(EV_DJ, this.y, 0);
            did = true;
        } else {
            this.bufT = this.t;
        }
        this.pressT = this.t;
        return did;
    }

    release(): void { this.held = false; }

    plankUp(i: i32): bool {
        let st = this.plank[i];
        return st < 0 || this.t - st < PLANK_DELAY;
    }

    step(tv: f64): void {
        let t0 = this.t;
        this.t += STEP;
        let t = this.t;
        // carried by a raft
        if (this.ground && this.on >= 100 && this.on < 200) {
            let i = this.on - 100;
            this.x += moverX(i, t) - moverX(i, t0);
            this.y = moverY(i, t);
        }
        // run
        let a = ACC_A;
        if (this.ground) a = (tv * this.vx >= 0 && Math.abs(tv) > Math.abs(this.vx)) ? ACC_G : DEC_G;
        let dv = tv - this.vx;
        this.vx += clamp(dv, -a * STEP, a * STEP);
        // gravity
        let g = this.vy > 0 ? ((this.held || this.spring) ? GU_HELD : GU) : GD;
        this.vy = Math.max(this.vy - g * STEP, -VFALL);
        let px = this.x, py = this.y;
        // x against the solids and the springs' stems
        this.x += this.vx * STEP;
        for (let k = 0; k < NSOL; k++) {
            let x0 = SOL[k * 3], x1 = SOL[k * 3 + 1], top = SOL[k * 3 + 2];
            if (this.y < top - 0.001 && this.x + HW > x0 && this.x - HW < x1) {
                if (px + HW <= x0 + 0.001) this.x = x0 - HW;
                else if (px - HW >= x1 - 0.001) this.x = x1 + HW;
                this.vx = 0;
            }
        }
        for (let k = 0; k < NSPR; k++) {
            let sx = SPR[k * 2], base = SPR[k * 2 + 1], top = base + SPRING_H;
            if (this.y < top - 0.001 && this.y + HH > base && this.x + HW > sx - SPRING_W / 2 && this.x - HW < sx + SPRING_W / 2) {
                this.x = px <= sx ? sx - SPRING_W / 2 - HW : sx + SPRING_W / 2 + HW;
                this.vx = 0;
            }
        }
        // y: landing on whatever is under the feet
        this.y += this.vy * STEP;
        let was = this.ground;
        this.ground = false;
        let land = false, landY = 0.0, landOn = -1;
        if (this.vy <= 0) {
            for (let k = 0; k < NSOL; k++) {
                let x0 = SOL[k * 3], x1 = SOL[k * 3 + 1], top = SOL[k * 3 + 2];
                if (this.x + HW > x0 && this.x - HW < x1 && py >= top - 0.02 && this.y <= top) {
                    land = true; landY = top; landOn = -1;
                }
            }
            for (let k = 0; k < NONE; k++) {
                let x0 = ONE[k * 3], x1 = ONE[k * 3 + 1], top = ONE[k * 3 + 2];
                if (this.x + HW * 0.6 > x0 && this.x - HW * 0.6 < x1 && py >= top - 0.02 && this.y <= top) {
                    land = true; landY = top; landOn = -1;
                }
            }
            for (let i = 0; i < NMOV; i++) {
                let nx = moverX(i, t), oy = moverY(i, t0), ny = moverY(i, t);
                if (this.x + HW * 0.6 > nx - MOVER_W / 2 && this.x - HW * 0.6 < nx + MOVER_W / 2 && py >= oy - 0.02 && this.y <= ny) {
                    land = true; landY = ny; landOn = 100 + i;
                }
            }
            let bx = BRIDGE[0], bw = BRIDGE[2], btop = BRIDGE[3];
            for (let i = 0; i < NPL; i++) {
                if (this.plankUp(i) && this.x + HW * 0.6 > bx + <f64>i * bw && this.x - HW * 0.6 < bx + <f64>(i + 1) * bw
                    && py >= btop - 0.02 && this.y <= btop) {
                    land = true; landY = btop; landOn = 200 + i;
                    if (this.plank[i] < 0) {
                        this.plank[i] = this.t;
                        this.ev(EV_CREAK, <f64>i, 0);
                    }
                }
            }
            for (let k = 0; k < NSPR; k++) {
                let sx = SPR[k * 2], top = SPR[k * 2 + 1] + SPRING_H;
                if (Math.abs(this.x - sx) < SPRING_W / 2 + HW * 0.6 && py >= top - 0.02 && this.y <= top) {
                    this.y = top; this.vy = SPRING_V; this.spring = true; this.dj = true; this.jumped = true;
                    this.ev(EV_BOING, <f64>k, 0);
                    land = false;
                    break;
                }
            }
        }
        if (land) {
            this.landV = -this.vy;
            this.y = landY; this.vy = 0; this.ground = true; this.on = landOn; this.lastG = this.t;
            this.jumped = false; this.spring = false;
            if (!was) {
                this.ev(EV_LAND, this.landV, 0);
                if (this.t - this.bufT < BUFFER) {
                    this.bufT = -9;
                    this.jump(JUMP_V);
                }
            }
        } else if (was && this.vy <= 0) {
            this.lastG = this.t;
        }
        // planks come back
        for (let i = 0; i < NPL; i++) {
            if (this.plank[i] >= 0 && this.t - this.plank[i] > PLANK_DELAY + PLANK_BACK) this.plank[i] = -1;
        }
        // critters: from above a stomp, from the side a hurt
        for (let i = 0; i < NBUG; i++) {
            if (this.bugDead[i]) continue;
            let bx = bugX(i, t), by = BUG[i * 3 + 2];
            if (this.x + HW > bx - BUG_HW && this.x - HW < bx + BUG_HW && this.y < by + BUG_H && this.y + HH > by) {
                if (this.vy < 0 && py >= by + BUG_H - 0.22) {
                    this.bugDead[i] = true; this.vy = STOMP_V; this.spring = false; this.dj = true; this.ground = false;
                    this.ev(EV_STOMP, 0, <f64>i);
                } else if (this.t > this.inv) {
                    this.hurt = true;
                }
            }
        }
        for (let i = 0; i < NMOTH; i++) {
            if (this.mothDead[i]) continue;
            let mx = mothX(i, t), my = mothY(i, t);
            if (this.x + HW > mx - MOTH_HW && this.x - HW < mx + MOTH_HW && this.y < my + MOTH_HH && this.y + HH > my - MOTH_HH) {
                if (this.vy < 0 && py >= my + MOTH_HH - 0.25) {
                    this.mothDead[i] = true; this.vy = STOMP_V; this.spring = false; this.dj = true; this.ground = false;
                    this.ev(EV_STOMP, 1, <f64>i);
                } else if (this.t > this.inv) {
                    this.hurt = true;
                }
            }
        }
        // seeds
        for (let i = 0; i < NSEED; i++) {
            if (this.got[i]) continue;
            let sx = SEED[i * 2], sy = SEED[i * 2 + 1];
            if (Math.abs(this.x - sx) < 0.42 && sy > this.y - 0.2 && sy < this.y + HH + 0.25) {
                this.got[i] = true; this.seeds++;
                this.ev(EV_SEED, <f64>i, 0);
            }
        }
        // checkpoints, the flag, the water
        for (let i = this.cp + 1; i < NCP; i++) {
            if (this.x >= CP[i * 2] && Math.abs(this.y - CP[i * 2 + 1]) < 1.5) {
                this.cp = i;
                this.ev(EV_CP, <f64>i, 0);
            }
        }
        if (this.x >= FLAG_X && this.y >= FLAG_Y - 0.1) this.win = true;
        if (this.x < WATER_END && this.y < WATER_Y - 0.25) this.dead = true;
    }

    // time passes while Pip is away (a death, a respawn): the rafts, critters and planks go on
    tick(dt: f64): void {
        this.t += dt;
        for (let i = 0; i < NPL; i++) {
            if (this.plank[i] >= 0 && this.t - this.plank[i] > PLANK_DELAY + PLANK_BACK) this.plank[i] = -1;
        }
    }

    respawn(): void {
        this.x = CP[this.cp * 2]; this.y = CP[this.cp * 2 + 1]; this.vx = 0; this.vy = 0;
        this.ground = true; this.on = -1; this.dead = false; this.hurt = false; this.held = false;
        this.spring = false; this.jumped = false; this.lastG = this.t; this.inv = this.t + 1.5;
        for (let i = 0; i < NPL; i++) this.plank[i] = -1;
    }
}

// ---------------------------------------------------------------------------------------- the demo player
const NHOLD: i32 = 5;
const HOLDS: StaticArray<f64> = [0.05, 0.14, 0.24, 0.36, 0.6];
const HORIZON: f64 = 2.4;

class Bot {
    c: Run = new Run();
    active: bool = false;      // a jump plan is running
    hold: f64 = 0; dj: f64 = -1; steer: f64 = 1; t0: f64 = 0; x0: f64 = 0; y0: f64 = 0;
    relDone: bool = false; djDone: bool = false; fumbled: bool = false; tick: i32 = 0;
    cool: i32 = 0; back: i32 = 0; pause: i32 = 0; waited: i32 = 0;
    score: f64 = 0;
    camY: f64 = 0;

    reset(): void {
        this.active = false; this.cool = 0; this.back = 0; this.pause = 0; this.waited = 0;
    }

    fellOff(r: Run): bool { return r.x >= WATER_END && r.y < this.camY - 3.3; }

    runAheadBad(s: Run): bool {
        let c = this.c;
        c.copyFrom(s); c.held = false;
        let x0 = c.x, y0 = c.y;
        for (let k = 0; k < 36; k++) {
            c.step(VMAX);
            if (c.dead || c.hurt || this.fellOff(c)) return true;
            if (!c.ground && c.y < y0 - 0.25) return true;
        }
        return c.x - x0 < 0.03 * VMAX;
    }

    // follows a jump to its landing; true when safe (the score is in this.score)
    follow(hold: f64, dj: f64, steer: f64, t0: f64, x0: f64, y0: f64, released0: bool, djdone0: bool, airborne0: bool): bool {
        let c = this.c;
        let seeds0 = c.seeds;
        let released = released0, djdone = djdone0, djrel = false, airborne = airborne0;
        let n = <i32>(HORIZON / STEP);
        for (let k = 0; k < n; k++) {
            if (k % 2 == 0) {
                let el = c.t - t0 + 1e-9;
                if (!released && el >= hold) { c.release(); released = true; }
                if (!djdone && el >= dj) { c.press(); djdone = true; }
                if (djdone && dj >= 0 && !djrel && el >= dj + 0.3) { c.release(); djrel = true; }
            }
            c.step(steer * VMAX);
            if (c.dead || c.hurt || this.fellOff(c)) return false;
            if (c.win) { this.score = 1000; return true; }
            if (!c.ground) airborne = true;
            if (airborne && c.ground && c.t - t0 > 0.12) {
                for (let j = 0; j < 18; j++) {
                    c.step(0);
                    if (c.dead || c.hurt) return false;
                }
                if (c.x < x0 + 0.4 && c.y < y0 + 0.5) return false;
                this.score = c.x + 2.0 * <f64>(c.seeds - seeds0) + 0.8 * (c.y - y0) - (dj >= 0 ? 1.5 : 0);
                return true;
            }
        }
        return false;
    }

    tryJump(s: Run, hold: f64, dj: f64, steer: f64): bool {
        let c = this.c;
        c.copyFrom(s);
        if (!c.press()) return false;
        return this.follow(hold, dj, steer, c.t, c.x, c.y, false, dj < 0, false);
    }

    tryRest(s: Run, hold: f64, dj: f64, steer: f64): bool {
        this.c.copyFrom(s);
        return this.follow(hold, dj, steer, this.t0, this.x0, this.y0, this.relDone || !s.held, this.djDone || dj < 0, true);
    }

    // one frame of the demo player: presses and releases on s, returns the steering (-1..1)
    decide(api: GameApi, s: Run, camY: f64): f64 {
        this.camY = camY;
        if (this.active) {
            let el = s.t - this.t0 + 1e-9;
            this.tick++;
            if (!s.ground && !this.fumbled && this.tick % 4 == 0 && el > 0.1) {
                if (!this.tryRest(s, this.hold, this.dj, this.steer)) {
                    let found = false, bs = 0.0, bh = 0.0, bd = 0.0, bst = 0.0;
                    for (let si = 0; si < 4; si++) {
                        let st = 1.0 - 0.5 * <f64>si;
                        let nd = (this.djDone || this.dj >= 0 || !s.dj) ? 1 : 2;
                        for (let di = 0; di < nd; di++) {
                            let d2 = di == 0 ? this.dj : el;
                            let nh = this.relDone ? 1 : 2;
                            for (let hi = 0; hi < nh; hi++) {
                                let h2 = hi == 0 ? this.hold : el;
                                if (this.tryRest(s, h2, d2, st) && (!found || this.score > bs)) {
                                    found = true; bs = this.score; bh = h2; bd = d2; bst = st;
                                }
                            }
                        }
                    }
                    if (found) { this.hold = bh; this.dj = bd; this.steer = bst; }
                }
            }
            if (s.held && el >= this.hold && !this.relDone) { s.release(); this.relDone = true; }
            if (this.dj >= 0 && !this.djDone && el >= this.dj) { s.press(); this.djDone = true; }
            if (this.dj >= 0 && this.djDone && s.held && el >= this.dj + 0.3) s.release();
            if ((s.ground && el > 0.12) || el > HORIZON) {
                this.active = false;
                if (s.held) s.release();
            } else {
                return this.steer;
            }
        }
        if (!s.ground) return 1;
        if (this.back > 0) {                     // backing off for a run-up (a spring behind)
            this.back--;
            return this.back > 6 ? -1 : 0;
        }
        if (this.pause > 0) { this.pause--; return 0; }
        this.cool--;
        if (!this.runAheadBad(s)) { this.waited = 0; return 1; }
        if (this.cool > 0) { this.waited++; return 0; }
        if (this.waited == 0 && api.rand() < 0.35) {          // a look before the leap
            this.pause = <i32>api.range(12, 36); this.waited = 1;
            return 0;
        }
        let found = false, bs = 0.0, bh = 0.0, bd = 0.0, bst = 0.0;
        for (let hi = 0; hi < NHOLD; hi++) {
            for (let di = 0; di < 2; di++) {
                for (let si = 0; si < 2; si++) {
                    let h = HOLDS[hi], d = di == 0 ? -1.0 : 0.3, st = si == 0 ? 1.0 : 0.55;
                    if (this.tryJump(s, h, d, st) && (!found || this.score > bs)) {
                        found = true; bs = this.score; bh = h; bd = d; bst = st;
                    }
                }
            }
        }
        if (!found) {
            this.cool = 3; this.waited += 4;
            if (this.waited > 150) { this.back = 36; this.waited = 0; }
            return 0;
        }
        this.fumbled = false;
        if (api.rand() < 0.12) {                 // a slip: the hold far off, and no correcting it
            bh *= api.rand() < 0.5 ? 0.35 : 1.9;
            this.fumbled = true;
        }
        this.active = true; this.hold = bh; this.dj = bd; this.steer = bst; this.t0 = s.t; this.x0 = s.x; this.y0 = s.y;
        this.relDone = false; this.djDone = false; this.tick = 0;
        s.press();
        return bst;
    }
}

// ---------------------------------------------------------------------------------------- the game
const NSEEDB: i32 = 12;
const NPOP: i32 = 2;
const NBUGB: i32 = 3;
const NMOTHB: i32 = 2;
const NPUFF: i32 = 3;
const NCLOUD: i32 = 3;

export class Game {
    run: Run = new Run();
    bot: Bot = new Bot();
    // bones
    body: i32 = -1; sprout: i32 = -1; footR: i32 = -1; footL: i32 = -1;
    seedB: StaticArray<i32> = new StaticArray<i32>(NSEEDB);
    popB: StaticArray<i32> = new StaticArray<i32>(NPOP);
    bugB: StaticArray<i32> = new StaticArray<i32>(NBUGB);
    mothB: StaticArray<i32> = new StaticArray<i32>(NMOTHB);
    springB: StaticArray<i32> = new StaticArray<i32>(3);
    raftB: StaticArray<i32> = new StaticArray<i32>(6);
    plankB: StaticArray<i32> = new StaticArray<i32>(NPL);
    bloomB: StaticArray<i32> = new StaticArray<i32>(4);
    puffB: StaticArray<i32> = new StaticArray<i32>(NPUFF);
    cloudB: StaticArray<i32> = new StaticArray<i32>(NCLOUD);
    hillsB: StaticArray<i32> = new StaticArray<i32>(2);
    groveB: StaticArray<i32> = new StaticArray<i32>(2);
    pennant: i32 = -1; water: i32 = -1;

    // state
    state: i32 = READY;
    lives: i32 = 3;
    acc: f64 = 0;
    stateT: f64 = 0;          // api.time the state began
    deathKind: i32 = 0;       // 1 splash, 2 fall, 3 hurt
    deadX: f64 = 0; deadY: f64 = 0; deadVX: f64 = 0;
    endTime: f64 = 0;         // the run's time at the flag or the game over
    bestTime: f64 = -1;
    bestSeeds: i32 = 0;
    newBest: bool = false;
    wasDemo: bool = false;
    runs: i32 = 0;
    // camera
    camX: f64 = 3.2; camY: f64 = 1.1; groundY: f64 = 0; lead: f64 = 1.2;
    // Pip's look
    face: f64 = 1; turnT: f64 = -9; idleT: f64 = 0; stride: f64 = 0;
    jumpT: f64 = -9; landT: f64 = -9; landV: f64 = 0; djT: f64 = -9; boingT: f64 = -9; spawnT: f64 = -9;
    sAng: f64 = 0; sVel: f64 = 0;
    // pickups and critters
    seedSlot: StaticArray<i32> = new StaticArray<i32>(NSEEDB);
    gotT: StaticArray<f64> = new StaticArray<f64>(NSEED);
    popX: StaticArray<f64> = new StaticArray<f64>(NPOP);
    popY: StaticArray<f64> = new StaticArray<f64>(NPOP);
    popT: StaticArray<f64> = new StaticArray<f64>(NPOP);
    nextPop: i32 = 0;
    stompT: StaticArray<f64> = new StaticArray<f64>(NBUG + NMOTH);
    stompX: StaticArray<f64> = new StaticArray<f64>(NBUG + NMOTH);
    stompY: StaticArray<f64> = new StaticArray<f64>(NBUG + NMOTH);
    springT: StaticArray<f64> = new StaticArray<f64>(3);
    cpT: StaticArray<f64> = new StaticArray<f64>(NCP);
    plankFallX: StaticArray<f64> = new StaticArray<f64>(NPL);
    puffX: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    puffY: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    puffT: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    puffS: StaticArray<f64> = new StaticArray<f64>(NPUFF);
    nextPuff: i32 = 0;
    streak: i32 = 0; lastSeedT: f64 = -9;
    msg: string = ""; msgT: f64 = -9;
    // input (HUD pixels): a press above Pip's feet jumps at once; held or dragged it steers
    pressed: bool = false; jumpPress: bool = false; downT: f64 = 0; downX: f32 = 0; downY: f32 = 0;
    moved: f32 = 0; hover: bool = false; tapT: f64 = -9; upX: f32 = -99; upY: f32 = -99;
    steer: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        this.body = api.bone("pip"); this.sprout = api.bone("sprout");
        this.footR = api.bone("footR"); this.footL = api.bone("footL");
        for (let i = 0; i < NSEEDB; i++) this.seedB[i] = api.bone("seed" + i.toString());
        for (let i = 0; i < NPOP; i++) this.popB[i] = api.bone("pop" + i.toString());
        for (let i = 0; i < NBUGB; i++) this.bugB[i] = api.bone("bug" + i.toString());
        for (let i = 0; i < NMOTHB; i++) this.mothB[i] = api.bone("moth" + i.toString());
        for (let i = 0; i < 3; i++) this.springB[i] = api.bone("spring" + i.toString());
        for (let i = 0; i < 6; i++) this.raftB[i] = api.bone("raft" + i.toString());
        for (let i = 0; i < NPL; i++) this.plankB[i] = api.bone("plank" + i.toString());
        for (let i = 0; i < 4; i++) this.bloomB[i] = api.bone("bloom" + i.toString());
        for (let i = 0; i < NPUFF; i++) this.puffB[i] = api.bone("puff" + i.toString());
        for (let i = 0; i < NCLOUD; i++) this.cloudB[i] = api.bone("cloud" + i.toString());
        for (let i = 0; i < 2; i++) { this.hillsB[i] = api.bone("hills" + i.toString()); this.groveB[i] = api.bone("grove" + i.toString()); }
        this.pennant = api.bone("pennant"); this.water = api.bone("water");
        this.run.rec = true;
        this.wasDemo = api.demo;
        this.newRun(api, api.demo);
    }

    newRun(api: GameApi, go: bool): void {
        this.run.reset();
        this.run.rec = true;
        this.bot.reset();
        this.lives = 3; this.acc = 0;
        this.state = go ? PLAY : READY;
        this.stateT = api.time;
        this.camX = this.run.x + 1.2; this.camY = 1.1; this.groundY = 0; this.lead = 1.2;
        this.face = 1; this.turnT = -9; this.idleT = 0; this.stride = 0;
        this.jumpT = -9; this.landT = -9; this.djT = -9; this.boingT = -9; this.spawnT = -9; this.sAng = 0; this.sVel = 0;
        for (let i = 0; i < NSEED; i++) this.gotT[i] = -9;
        for (let i = 0; i < NPOP; i++) this.popT[i] = -9;
        for (let i = 0; i < NBUG + NMOTH; i++) this.stompT[i] = -9;
        for (let i = 0; i < 3; i++) this.springT[i] = -9;
        for (let i = 0; i < NCP; i++) this.cpT[i] = -9;
        for (let i = 0; i < NPUFF; i++) this.puffT[i] = -9;
        this.streak = 0; this.msg = ""; this.msgT = -9;
        this.pressed = false; this.jumpPress = false; this.hover = false; this.tapT = -9; this.steer = 0;
        this.newBest = false;
        if (go && !api.demo) this.startJingle(api);
    }

    startJingle(api: GameApi): void {
        api.note(72, 0.5, 0, SFX_NOTE, 0);
        api.note(76, 0.5, 0, SFX_NOTE, 0.08);
        api.note(79, 0.6, 0, SFX_NOTE, 0.16);
    }

    // ------------------------------------------------------------------ input
    feetY(api: GameApi): f32 {
        api.project(<f32>this.run.x, <f32>this.run.y, 0);
        return api.screenY;
    }

    steerFrom(api: GameApi, hx: f32, hy: f32): f64 {
        if (!api.pickPlane(hx, hy, 0, 0, 1, 0)) return 0;
        let dx = <f64>api.hitX - this.run.x;
        let ad = Math.abs(dx);
        if (ad < 0.35) return 0;                       // the dead zone round Pip
        return (dx > 0 ? 1 : -1) * clamp((ad - 0.35) / 1.6, 0.25, 1);
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (api.demo) return true;
        if (kind == POINTER_DOWN) {
            if (this.state == READY) {
                this.state = PLAY; this.stateT = api.time; this.startJingle(api);
            } else if (this.state == OVER || this.state == CLEAR) {
                if (api.time - this.stateT > 0.8) { this.newRun(api, true); }
                return true;
            }
            this.pressed = true; this.downT = api.time; this.downX = x; this.downY = y; this.moved = 0; this.hover = false;
            this.jumpPress = false;
            if (this.state == PLAY && y < this.feetY(api) - 3) {   // above Pip's feet: jump now
                this.jumpPress = true;
                this.run.press();
            }
        } else if (kind == POINTER_MOVE) {
            if (this.pressed) {
                let d = Mathf.abs(x - this.downX) + Mathf.abs(y - this.downY);
                if (d > this.moved) this.moved = d;
                if (!this.jumpPress && y > this.downY) this.downY = y;   // a flick counts from the finger's lowest point
                // a drag that rises above Pip's feet (a flick up while running) jumps too
                if (!this.jumpPress && this.state == PLAY && y < this.feetY(api) - 3 && this.downY - y >= 6) {
                    this.jumpPress = true; this.run.press();
                    this.downY = y;
                }
                if (this.jumpPress && y >= this.feetY(api) + 2) {
                    if (this.run.held) this.run.release();
                    this.jumpPress = false; this.downY = y;      // a new flick up jumps again (a double jump)
                }
            } else if (api.hoverSeen && Mathf.abs(x - this.upX) + Mathf.abs(y - this.upY) > 2) {
                this.hover = true;                  // a mouse moving unpressed: steering follows the hover
            }
        } else if (kind == POINTER_UP) {
            if (this.pressed && this.state == PLAY) {
                if (this.jumpPress) {
                    this.run.release();
                } else if (api.time - this.downT < 0.2 && this.moved < 5) {
                    this.run.press();                // a quick tap below Pip: a short hop
                    this.tapT = api.time;
                }
            }
            this.pressed = false; this.jumpPress = false;
            this.upX = x; this.upY = y;             // a finger's lift sends a move here: not a hover
        }
        return true;
    }

    // ------------------------------------------------------------------ update
    update(api: GameApi): void {
        if (api.demoChanged || api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.newRun(api, api.demo);
        }
        let dt = api.dt;
        let r = this.run;
        if (this.state == PLAY) {
            // steering: the bot, the held finger, the hover, or (in the air) keep the momentum
            let tv = 0.0;
            if (api.demo) {
                tv = this.bot.decide(api, r, this.camY) * VMAX;
            } else {
                if (this.tapT > 0 && api.time - this.tapT > 0.1 && r.held && !this.pressed) { r.release(); this.tapT = -9; }
                // a mouse (the renderer saw a move with nothing pressed) steers by its hover too
                if (!this.pressed && api.hoverSeen && Mathf.abs(api.pointerX - this.upX) + Mathf.abs(api.pointerY - this.upY) > 2) this.hover = true;
                let s = 0.0;
                let has = false;
                if (this.pressed || this.hover) {
                    s = this.steerFrom(api, api.pointerX, api.pointerY); has = true;
                }
                tv = s * VMAX;
                if (!has && !r.ground) tv = r.vx;
                if (!has && r.ground) tv = 0;
            }
            this.steer = tv;
            this.acc += dt;
            let n = 0;
            while (this.acc >= STEP && n < 12) {
                this.acc -= STEP; n++;
                r.step(tv);
                if (r.dead || r.hurt || r.win || this.fell()) break;
            }
            if (n == 12) this.acc = 0;
            this.events(api);
            if (r.win) this.win(api);
            else if (r.dead) this.die(api, 1);
            else if (r.hurt) this.die(api, 3);
            else if (this.fell()) this.die(api, 2);
        } else if (this.state == DYING) {
            r.tick(dt);
            if (api.time - this.stateT > 1.1) {
                if (this.lives <= 0) {
                    this.state = OVER; this.stateT = api.time; this.endTime = r.t;
                    if (r.seeds > this.bestSeeds) this.bestSeeds = r.seeds;
                    api.sound(SFX_LOSE, 1, 0.6);
                    api.note(52, 0.5, 0, SFX_NOTE, 0.6); api.note(48, 0.5, 0, SFX_NOTE, 0.78);
                } else {
                    r.respawn(); this.bot.reset();
                    this.state = PLAY; this.stateT = api.time; this.spawnT = api.time; this.acc = 0;
                    this.groundY = r.y; this.camX = r.x + 1.2; this.camY = r.y + 1.1;
                    api.soundAt(SFX_POP, r.x, r.y, 0, 1.3, 0.6);
                    api.note(79, 0.4, 0, SFX_NOTE, 0.06);
                }
            }
        } else if (this.state == OVER || this.state == CLEAR) {
            r.tick(dt);
            if (api.demo && api.time - this.stateT > 2.2) this.newRun(api, true);
        } else {
            r.tick(0);
        }
        this.camera(api, dt);
        this.pose(api, dt);
        this.world(api);
    }

    fell(): bool { return this.run.x >= WATER_END && this.run.y < this.camY - 3.3; }

    events(api: GameApi): void {
        let r = this.run;
        for (let k = 0; k < r.evK.length; k++) {
            let e = r.evK[k], a = r.evA[k], b = r.evB[k];
            if (e == EV_JUMP) {
                this.jumpT = api.time;
                let p = 0.92 + clamp(a, 0, 17) * 0.022;              // higher in the garden, higher pitch
                api.soundAt(SFX_JUMP, r.x, r.y, 0, p, 0.7);
                this.puff(r.x - this.face * 0.2, r.y, 0.8);
            } else if (e == EV_DJ) {
                this.djT = api.time;
                api.soundAt(SFX_JUMP, r.x, r.y, 0, 1.35 + clamp(a, 0, 17) * 0.022, 0.6);
                api.soundAt(SFX_WHOOSH, r.x, r.y, 0, 1.6, 0.35);
                this.puff(r.x, r.y - 0.1, 0.7);
            } else if (e == EV_LAND) {
                this.landT = api.time; this.landV = a;
                if (a > 3) {
                    api.soundAt(SFX_THUD, r.x, r.y, 0, 1.1, clamp(a / 13, 0.25, 0.9));
                    api.soundAt(SFX_TICK, r.x, r.y, 0, 0.6, 0.5);
                    this.puff(r.x - 0.25, r.y, 0.7); this.puff(r.x + 0.25, r.y, 0.7);
                }
            } else if (e == EV_BOING) {
                let i = <i32>a;
                this.springT[i] = api.time; this.boingT = api.time;
                api.soundAt(SFX_JUMP, SPR[i * 2], SPR[i * 2 + 1], 0, 0.5, 0.8);
                api.soundAt(SFX_JUMP, SPR[i * 2], SPR[i * 2 + 1], 0, 0.75, 0.6, 0.07);
                api.noteAt(67, SPR[i * 2], SPR[i * 2 + 1], 0, 0.35, SFX_NOTE, 0.14);
            } else if (e == EV_STOMP) {
                let j = <i32>b + (a > 0 ? NBUG : 0);
                this.stompT[j] = api.time;
                this.stompX[j] = a > 0 ? mothX(<i32>b, r.t) : bugX(<i32>b, r.t);
                this.stompY[j] = a > 0 ? mothY(<i32>b, r.t) : BUG[<i32>b * 3 + 2];
                api.soundAt(SFX_POP, r.x, r.y, 0, 0.6, 0.9);
                api.soundAt(SFX_THUD, r.x, r.y, 0, 1.4, 0.5);
                this.jumpT = api.time;
                this.popAt(this.stompX[j], this.stompY[j] + 0.3);
            } else if (e == EV_CREAK) {
                let i = <i32>a;
                api.soundAt(SFX_CLICK, BRIDGE[0] + a + 0.5, BRIDGE[3], 0, 0.45 + 0.04 * a, 0.8);
                api.soundAt(SFX_WHOOSH, BRIDGE[0] + a + 0.5, BRIDGE[3], 0, 0.5, 0.4, PLANK_DELAY);
                this.plankFallX[i] = 0;
            } else if (e == EV_SEED) {
                let i = <i32>a;
                this.gotT[i] = api.time;
                if (api.time - this.lastSeedT < 1.2) this.streak = min<i32>(this.streak + 1, 12); else this.streak = 0;
                this.lastSeedT = api.time;
                api.soundAt(SFX_COIN, SEED[i * 2], SEED[i * 2 + 1], 0, Math.pow(2, <f64>this.streak / 12), 0.6);
                this.popAt(SEED[i * 2], SEED[i * 2 + 1]);
            } else if (e == EV_CP) {
                let i = <i32>a;
                this.cpT[i] = api.time;
                this.msg = "CHECKPOINT!"; this.msgT = api.time;
                api.note(84, 0.45, 0, SFX_BELL, 0); api.note(88, 0.45, 0, SFX_BELL, 0.1); api.note(91, 0.5, 0, SFX_BELL, 0.2);
            }
        }
        r.evK.length = 0; r.evA.length = 0; r.evB.length = 0;
    }

    die(api: GameApi, kind: i32): void {
        let r = this.run;
        this.lives--;
        this.state = DYING; this.stateT = api.time; this.deathKind = kind;
        this.deadX = r.x; this.deadY = r.y; this.deadVX = r.vx;
        this.jumpPress = false; r.held = false;      // a finger still down keeps steering after the respawn
        if (kind == 1) {
            this.msg = "SPLASH!";
            api.soundAt(SFX_SPLASH, r.x, WATER_Y, 0, 1, 0.8);
            this.puff(r.x - 0.2, WATER_Y, 1.0); this.puff(r.x + 0.2, WATER_Y, 1.0); this.puff(r.x, WATER_Y + 0.2, 1.2);
        } else if (kind == 2) {
            this.msg = "WHOOPS!";
            api.soundAt(SFX_SHOOT, r.x, r.y, 0, 0.45, 0.6);
        } else {
            this.msg = "OUCH!";
            api.soundAt(SFX_HIT, r.x, r.y, 0, 1, 0.8);
            api.note(64, 0.35, 0, SFX_NOTE, 0.12); api.note(59, 0.35, 0, SFX_NOTE, 0.24);
        }
        this.msgT = api.time;
        if (this.lives <= 0) this.msg = "";
    }

    win(api: GameApi): void {
        let r = this.run;
        this.state = CLEAR; this.stateT = api.time; this.endTime = r.t;
        this.runs++;
        this.newBest = this.bestTime < 0 || r.t < this.bestTime;
        if (this.newBest) this.bestTime = r.t;
        if (r.seeds > this.bestSeeds) this.bestSeeds = r.seeds;
        api.sound(SFX_WIN, 1, 0.6);
        let m: StaticArray<f64> = [72, 76, 79, 84, 79, 84];
        for (let k = 0; k < 6; k++) api.note(m[k], 0.5, 0, SFX_NOTE, 0.45 + <f64>k * 0.11);
        api.note(96, 0.4, 0, SFX_BELL, 1.15);
        if (this.newBest) api.note(91, 0.4, 0, SFX_BELL, 1.35);
    }

    puff(x: f64, y: f64, s: f64): void {
        let i = this.nextPuff; this.nextPuff = (i + 1) % NPUFF;
        this.puffX[i] = x; this.puffY[i] = y; this.puffT[i] = this.run.t; this.puffS[i] = s;
    }

    popAt(x: f64, y: f64): void {
        let i = this.nextPop; this.nextPop = (i + 1) % NPOP;
        this.popX[i] = x; this.popY[i] = y; this.popT[i] = this.run.t;
    }

    // ------------------------------------------------------------------ camera
    camera(api: GameApi, dt: f64): void {
        let r = this.run;
        if (this.state == PLAY || this.state == CLEAR) {
            if (Math.abs(r.vx) > 0.5) this.face = r.vx > 0 ? 1 : -1;
            let want = this.face * 1.2;
            this.lead += clamp(want - this.lead, -2.5 * dt, 2.5 * dt);
            if (r.ground) this.groundY = r.y;
        }
        let tx = (this.state == DYING ? this.deadX : r.x) + this.lead;
        let ty = this.groundY + 1.1;
        if (this.state == PLAY && r.y + 0.4 > ty + 1.7) ty = r.y + 0.4 - 1.7;
        if (ty < 1.1) ty = 1.1;
        this.camX += (tx - this.camX) * Math.min(1, dt * 6);
        this.camY += (ty - this.camY) * Math.min(1, dt * 4);
        api.useTarget = true;
        api.targetX = this.camX; api.targetY = this.camY; api.targetZ = 0;
        // the higher Pip climbs, the lower the horizon: deep sky at the treetops
        api.horizon = clamp(0.62 + (this.camY - 1.1) * 0.03, 0.62, 2.0);
    }

    // ------------------------------------------------------------------ Pip
    pose(api: GameApi, dt: f64): void {
        let r = this.run;
        let t = api.time;
        let st = Math.floor(t * 12) / 12;                   // stepped animation clock (12 fps)
        let x = r.x, y = r.y;
        if (this.state == DYING) {
            let e = t - this.stateT;
            if (this.deathKind == 1) { x = this.deadX; y = WATER_Y - 0.25 - e * 0.8; }
            else if (this.deathKind == 3) { x = this.deadX - this.face * e * 1.8; y = this.deadY + 4 * e - 14 * e * e; }
            else { x = this.deadX; y = this.deadY - 6 * e; }
        }
        if (this.state == READY || this.state == OVER) { x = r.x; y = r.y; }
        // facing and turning
        let want = this.face;
        if (Math.abs(this.steer) > 0.1 && this.state == PLAY) want = this.steer > 0 ? 1 : -1;
        if (want != this.face && this.state == PLAY) { this.face = want; this.turnT = t; }
        let moving = Math.abs(r.vx) > 0.3;
        if (moving || !r.ground || Math.abs(this.steer) > 0.1) this.idleT = t;
        let yaw = this.face * 90;
        if (t - this.turnT < 0.09) yaw = this.face * 25;                       // a quick turn through the front
        else if (t - this.idleT > 1.2 && this.state != DYING) yaw = this.face * 35;   // idle: turns to look at us
        if (this.state == CLEAR) yaw = (Math.floor((t - this.stateT) * 3) % 2 == 0) ? 20 : -20;
        // squash and stretch
        let sx = 1.0, sy = 1.0, pitch = 0.0, roll = 0.0;
        let ej = t - this.jumpT, el = t - this.landT;
        if (!r.ground && this.state == PLAY) {
            sy = r.vy > 2 ? 1.1 : (r.vy < -4 ? 0.96 : 1.0);
            sx = 1 / Math.sqrt(sy);
        }
        if (ej < 0.16 && this.state == PLAY) { let k = 1 - ej / 0.16; sy = 1 + 0.2 * k; sx = 1 - 0.14 * k; }
        if (t - this.boingT < 0.25) { let k = 1 - (t - this.boingT) / 0.25; sy = 1 + 0.32 * k; sx = 1 - 0.2 * k; }
        if (el < 0.16 && r.ground) {
            let k = 1 - el / 0.16, a = clamp(this.landV / 12, 0.3, 1);
            sy = 1 - 0.28 * a * k; sx = 1 + 0.25 * a * k;
        }
        if (t - this.djT < 0.3) pitch = 360 * Math.floor((t - this.djT) / 0.3 * 8) / 8;   // a stepped forward flip
        if (moving && r.ground) pitch = 7 * Math.abs(r.vx) / VMAX;                       // leaning into the run
        if (this.state == DYING && this.deathKind == 3) roll = Math.floor((t - this.stateT) * 10) * 45;
        if (this.state == CLEAR && r.ground) {                                           // happy hops
            let ph = ((t - this.stateT) * 2.2) % 1;
            y = r.y + Math.max(0, Math.sin(ph * Math.PI)) * 0.45;
            if (ph < 0.12) { sy = 0.82; sx = 1.12; }
        }
        let sc = 1.0;
        if (t - this.spawnT < 0.35) sc = 0.3 + 0.7 * Math.min(1, (t - this.spawnT) / 0.25) + 0.12 * Math.sin((t - this.spawnT) * 18) * (1 - (t - this.spawnT) / 0.35);
        sx *= sc; sy *= sc;
        // blink while invulnerable; gone under the water
        let show = true;
        if (this.state == PLAY && r.t < r.inv && Math.floor(t * 12) % 2 == 0) show = false;
        if (this.state == DYING && (this.deathKind == 1 || y < this.camY - 3.6)) show = false;
        if (this.state == OVER) show = false;
        if (!show) {
            api.hide(this.body); api.hide(this.sprout); api.hide(this.footR); api.hide(this.footL);
            return;
        }
        let px = snapX(x), py = snapY(y);
        api.placeScaled(this.body, px, py, 0, yaw, sx, sy, sx, pitch, roll);
        // feet: a stepped run cycle by distance, tucked in the air
        if (r.ground && moving) this.stride += Math.abs(r.vx) * dt / 0.62;
        let ph = Math.floor((this.stride % 1) * 8) / 8 * 2 * Math.PI;
        let fwdR = 0.0, liftR = 0.0, fwdL = 0.0, liftL = 0.0;
        if (r.ground && moving && this.state == PLAY) {
            fwdR = 0.13 * Math.sin(ph); liftR = Math.max(0, Math.cos(ph)) * 0.08;
            fwdL = -fwdR; liftL = Math.max(0, -Math.cos(ph)) * 0.08;
        } else if (!r.ground && this.state == PLAY) {
            fwdR = 0.07; liftR = 0.08; fwdL = -0.05; liftL = 0.04;
        }
        let bx = <f64>api.restX[this.body], bz = <f64>api.restZ[this.body];
        api.transform(this.body, bx + 0.07 + fwdR, liftR, bz + 0.128);
        api.place(this.footR, snapX(api.tx), snapY(api.ty), api.tz, yaw, pitch, roll, sc);
        api.transform(this.body, bx + 0.07 + fwdL, liftL, bz - 0.128);
        api.place(this.footL, snapX(api.tx), snapY(api.ty), api.tz, yaw, pitch, roll, sc);
        // the sprout: a damped spring that lags behind the run and flops on landings
        let target = -this.face * 0 - Math.abs(r.vx) * 3.5 + (r.ground ? 0 : (r.vy > 0 ? -16 : 18));
        if (el < 0.1) this.sVel += 140 * dt;
        this.sVel += (120 * (target - this.sAng) - 9 * this.sVel) * dt;
        this.sAng += this.sVel * dt;
        let sa = Math.round(this.sAng / 6) * 6 + 4 * Math.sin(st * 5);
        api.transform(this.body, bx, 0.76, bz);
        api.place(this.sprout, snapX(api.tx), snapY(api.ty), api.tz, yaw, pitch - sa, roll, sc);
    }

    // ------------------------------------------------------------------ the world
    world(api: GameApi): void {
        let r = this.run;
        let t = api.time, rt = r.t;
        let st = Math.floor(t * 12) / 12;
        let cx = this.camX;
        // seeds: the pool goes to the uncollected seeds near the camera (and to ones still flying off)
        let slot = 0;
        for (let i = 0; i < NSEED && slot < NSEEDB; i++) {
            let sx = SEED[i * 2], sy = SEED[i * 2 + 1];
            if (Math.abs(sx - cx) > 6.2) continue;
            let g = t - this.gotT[i];
            if (r.got[i] && g > 0.3) continue;
            let b = this.seedB[slot++];
            let yaw = Math.floor(st * 4) * 30 + <f64>i * 40;
            let bob = Math.round(Math.sin(st * 3 + <f64>i) * 1.5) * TEXEL_Y;
            if (r.got[i]) {
                let k = g / 0.3;
                api.place(b, snapX(sx), snapY(sy + k * 0.6), 0, yaw * 3, 0, 0, Math.max(0.05, 1 - k));
            } else {
                api.place(b, snapX(sx), snapY(sy) + bob, 0, yaw);
            }
        }
        while (slot < NSEEDB) api.hide(this.seedB[slot++]);
        // pops
        for (let i = 0; i < NPOP; i++) {
            let e = rt - this.popT[i];
            if (e >= 0 && e < 0.28) {
                let k = Math.floor(e / 0.28 * 4) / 4;
                api.place(this.popB[i], snapX(this.popX[i]), snapY(this.popY[i]), 0.3, 0, 0, k * 45, 0.6 + k * 0.7);
            } else api.hide(this.popB[i]);
        }
        // shellbugs
        slot = 0;
        for (let i = 0; i < NBUG && slot < NBUGB; i++) {
            let bxx = bugX(i, rt);
            if (Math.abs(bxx - cx) > 7.5 && Math.abs(this.stompX[i] - cx) > 7.5) continue;
            let e = t - this.stompT[i];
            if (r.bugDead[i] && e > 0.45) continue;
            let b = this.bugB[slot++];
            if (r.bugDead[i]) {
                api.placeScaled(b, snapX(this.stompX[i]), snapY(this.stompY[i]), 0, 90, 1.3, Math.max(0.25, 0.35 - e * 0.2), 1.3);
            } else {
                let dir = bugU(i, rt) < 1 ? 90.0 : -90.0;
                let wob = (Math.floor(st * 8) % 2 == 0) ? 4.0 : -4.0;
                api.place(b, snapX(bxx), snapY(BUG[i * 3 + 2]), 0, dir, 0, wob);
            }
        }
        while (slot < NBUGB) api.hide(this.bugB[slot++]);
        // moths: wings flap by a stepped vertical squash
        slot = 0;
        for (let i = 0; i < NMOTH && slot < NMOTHB; i++) {
            let mx = mothX(i, rt), my = mothY(i, rt);
            if (Math.abs(mx - cx) > 7.5) continue;
            let e = t - this.stompT[NBUG + i];
            if (r.mothDead[i] && e > 0.6) continue;
            let b = this.mothB[slot++];
            if (r.mothDead[i]) {
                api.place(b, snapX(this.stompX[NBUG + i]), snapY(this.stompY[NBUG + i] - e * e * 6), 0, 90, 180 * Math.floor(e * 8) / 8, 0, 1);
            } else {
                let flap = (Math.floor(st * 10) % 2 == 0) ? 1.0 : 0.55;
                let dir = MOTH[i * 5 + 2] == 0 && Math.cos(2 * Math.PI * rt / MOTH[i * 5 + 4]) < 0 ? -90.0 : 90.0;
                api.placeScaled(b, snapX(mx), snapY(my), 0, dir, 1, flap, 1);
            }
        }
        while (slot < NMOTHB) api.hide(this.mothB[slot++]);
        // springs
        for (let i = 0; i < 3; i++) {
            let e = t - this.springT[i];
            let sy = 1.0;
            if (e < 0.5) sy = 1 - 0.45 * Math.exp(-e * 9) * Math.cos(e * 30);
            sy = Math.round(sy * 10) / 10;
            api.placeScaled(this.springB[i], SPR[i * 2], snapY(SPR[i * 2 + 1]), 0, 0, 1 + (1 - sy) * 0.5, sy, 1 + (1 - sy) * 0.5);
        }
        // leaf rafts
        for (let i = 0; i < NMOV; i++) {
            let mx = moverX(i, rt);
            if (Math.abs(mx - cx) > 9) { api.hide(this.raftB[i]); continue; }
            api.place(this.raftB[i], snapX(mx), snapY(moverY(i, rt)), 0);
        }
        // the bridge: planks shake, drop, come back
        for (let i = 0; i < NPL; i++) {
            let px = BRIDGE[0] + (<f64>i + 0.5) * BRIDGE[2], s0 = r.plank[i];
            if (Math.abs(px - cx) > 9) { api.hide(this.plankB[i]); continue; }
            if (s0 < 0) { api.place(this.plankB[i], snapX(px), snapY(BRIDGE[3]), 0); continue; }
            let e = rt - s0;
            if (e < PLANK_DELAY) {
                let sh = (Math.floor(e * 24) % 2 == 0) ? TEXEL : -TEXEL;
                api.place(this.plankB[i], snapX(px) + sh, snapY(BRIDGE[3]), 0);
            } else if (e < PLANK_DELAY + 1.2) {
                let f = e - PLANK_DELAY;
                api.place(this.plankB[i], snapX(px), snapY(BRIDGE[3] - 9 * f * f), 0, 0, 0, (i % 2 == 0 ? 1 : -1) * Math.floor(f * 10) * 12);
            } else if (e > PLANK_DELAY + PLANK_BACK - 0.25) {
                let k = clamp((e - (PLANK_DELAY + PLANK_BACK - 0.25)) / 0.25, 0.1, 1);
                api.place(this.plankB[i], snapX(px), snapY(BRIDGE[3]), 0, 0, 0, 0, k);
            } else api.hide(this.plankB[i]);
        }
        // checkpoint blooms: a bud until Pip passes, then they burst open
        for (let i = 1; i < NCP; i++) {
            let b = this.bloomB[i - 1];
            let bxx = CP[i * 2], byy = CP[i * 2 + 1] + 0.85;
            if (Math.abs(bxx - cx) > 9) { api.hide(b); continue; }
            let open = r.cp >= i;
            let e = t - this.cpT[i];
            let sc = open ? (e < 0.4 ? 0.4 + 0.6 * Math.min(1, e / 0.2) + 0.2 * Math.sin(e * 20) * (1 - e / 0.4) : 1.0) : 0.4;
            let yaw = open && e < 0.5 ? Math.floor(e * 16) * 45 : 0;
            api.placeScaled(b, snapX(bxx), snapY(byy), -0.3, yaw, sc, open ? sc : 0.55, sc);
        }
        // the pennant: hoisted on a win, flapping in steps
        {
            let e = this.state == CLEAR ? t - this.stateT : -1.0;
            let h = e < 0 ? 0.35 : 0.35 + 2.3 * Math.min(1, e / 1.0);
            let flap = (Math.floor(st * 6) % 2 == 0) ? 1.0 : 0.9;
            if (Math.abs(FLAG_X - cx) > 10) api.hide(this.pennant);
            else api.placeScaled(this.pennant, FLAG_X + 0.07, snapY(FLAG_Y + h), -0.1, 0, flap, 1, 1);
        }
        // puffs
        for (let i = 0; i < NPUFF; i++) {
            let e = rt - this.puffT[i];
            if (e < 0 || e > 0.36) { api.hide(this.puffB[i]); continue; }
            let k = Math.floor(e / 0.36 * 4) / 4;
            api.place(this.puffB[i], snapX(this.puffX[i]), snapY(this.puffY[i] + 0.1 + k * 0.25), 0.25, k * 60, 0, 0,
                this.puffS[i] * (0.7 + k * 0.6) * (1 - k * 0.5));
        }
        // the water band in whole ripple tiles; the backdrops in parallax
        if (this.camY < 7.5) api.place(this.water, Math.round(cx / 4.8) * 4.8, 0, 0);
        else api.hide(this.water);
        let cy = this.camY - 1.1;
        this.strip(api, this.hillsB, cx, 0.82, 24, snapY(-1.25 + cy * 0.45), -9.0);
        this.strip(api, this.groveB, cx, 0.6, 24, snapY(-2.0 + cy * 0.3), -5.5);
        for (let i = 0; i < NCLOUD; i++) {
            let base = cx * 0.93;
            let w = 33.0;
            let ox = <f64>i * 11 + 3;
            let rel = ((cx - base - ox) % w + w) % w - w * 0.5;
            api.place(this.cloudB[i], snapX(cx - rel), snapY(2.5 + <f64>(i % 2) * 0.7 + cy * 0.9), -12.0);
        }
    }

    // two copies of a strip `w` long, moving at `f` of the camera, covering the view
    strip(api: GameApi, b: StaticArray<i32>, cx: f64, f: f64, w: f64, y: f64, z: f64): void {
        let base = cx * f;
        let k = Math.round((cx - base) / w);
        let c0 = base + k * w;
        let c1 = c0 + (cx > c0 ? w : -w);
        api.place(b[0], snapX(c0), y, z);
        api.place(b[1], snapX(c1), y, z);
    }

    // ------------------------------------------------------------------ HUD
    hud(api: GameApi): void {
        let r = this.run;
        let W = <f32>api.hudW, H = <f32>api.hudH;
        let ink = api.rampColor(R_INK, 1), cream = api.rampColor(R_CREAM, 2), white = api.rampColor(R_CREAM, 3);
        let gold = api.rampColor(R_GOLD, 2), red = api.rampColor(R_RADISH, 2), green = api.rampColor(R_SPROUT, 2);
        // lives: little radishes
        for (let i = 0; i < 3; i++) {
            let x = 4 + <f32>i * 9, y: f32 = 5;
            let c = i < this.lives ? red : api.rampColor(R_INK, 2);
            api.rect(x + 1, y + 2, 5, 4, ink); api.rect(x, y + 1, 5, 4, c); api.rect(x + 1, y, 3, 6, c);
            api.rect(x + 1, y - 2, 1, 2, i < this.lives ? green : c); api.rect(x + 3, y - 2, 1, 2, i < this.lives ? green : c);
        }
        // seeds
        api.rect(33, 4, 3, 5, ink); api.rect(32, 3, 3, 5, gold); api.rect(33, 2, 1, 1, gold);
        api.text(38, 4, r.seeds.toString() + "/" + NSEED.toString(), cream, 1, ink);
        // time
        if (this.state != READY) {
            let tt = this.state == OVER || this.state == CLEAR ? this.endTime : r.t;
            let s = this.clock(tt);
            api.text(W - api.textWidth(s, 1) - 4, 4, s, cream, 1, ink);
        }
        if (this.state == READY && !api.demo) {
            let blink = Math.floor(api.time * 2) % 2 == 0;
            this.panel(api, 34, 44);
            api.textCentered(38, "SPROUT JUMP", gold, 2, ink);
            api.textCentered(54, "HOLD BELOW PIP TO RUN", cream, 1, ink);
            api.textCentered(62, "TAP ABOVE PIP TO JUMP", cream, 1, ink);
            api.textCentered(70, "HOLD LONGER: JUMP HIGHER", api.rampColor(R_CLOUD, 0), 1, ink);
            if (blink) api.textCentered(H - 14, "TAP TO START", white, 1, ink);
            return;
        }
        if (this.msg.length > 0 && api.time - this.msgT < 1.1 && this.state != OVER && this.state != CLEAR) {
            let c = this.msg == "CHECKPOINT!" ? green : white;
            api.textCentered(30, this.msg, c, 2, ink);
        }
        if (this.state == OVER || this.state == CLEAR) {
            let e = api.time - this.stateT;
            if (e < 0.4) return;
            this.panel(api, 16, 52);
            if (this.state == CLEAR) api.textCentered(21, this.newBest ? "NEW BEST!" : "TOP OF THE TREE!", gold, 2, ink);
            else api.textCentered(21, "GAME OVER", red, 2, ink);
            api.textCentered(37, "TIME " + this.clock(this.endTime) + "   SEEDS " + r.seeds.toString() + "/" + NSEED.toString(), cream, 1, ink);
            let best = this.bestTime < 0 ? "BEST -   MOST SEEDS " + this.bestSeeds.toString()
                : "BEST " + this.clock(this.bestTime) + "   MOST SEEDS " + this.bestSeeds.toString();
            api.textCentered(46, best, api.rampColor(R_CLOUD, 1), 1, ink);
            if (!api.demo && e > 0.8 && Math.floor(api.time * 2) % 2 == 0) api.textCentered(58, "TAP TO PLAY AGAIN", white, 1, ink);
        }
    }

    panel(api: GameApi, y: f32, h: f32): void {
        let W = <f32>api.hudW;
        api.rect(14, y, W - 28, h, api.rampColor(R_INK, 1));
        api.rect(15, y + 1, W - 30, h - 2, api.rampColor(R_INK, 2));
        api.rect(15, y + 1, W - 30, 1, api.rampColor(R_PETAL, 1));
    }

    clock(t: f64): string {
        let tenths = <i32>Math.floor(t * 10);
        let m = tenths / 600, s = (tenths / 10) % 60, d = tenths % 10;
        return m.toString() + ":" + (s < 10 ? "0" : "") + s.toString() + "." + d.toString();
    }
}
