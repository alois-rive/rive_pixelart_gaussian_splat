// Corner Pocket: a frame of pool at the Crooked Lamp, against Nell, the pub's regular.
// One verb, drag: when it is your shot, press anywhere and drag back behind the cue ball: the cue
// follows the pointer (it aims from the pointer through the ball), the drag's length is the power
// (the meter), release to strike. A dotted line shows the shot, a ghost ball where the cue ball first
// touches another, the line that ball takes and where the cue ball glances off. With ball in hand,
// tap (or drag and release) to put the cue ball down.
// The rules (house rules of the Crooked Lamp): seven SUNS (yellow), seven MOONS (blue) and the
// NIGHT ball (dark). The first ball you pot claims its set, then pot your seven and finally the night
// ball. Pot one of yours and you shoot again. A foul (the cue ball potted, nothing hit, or the first
// ball hit not yours) gives the other side ball in hand. Pot the night ball after your seven to win
// the frame; pot it early, or foul while potting it, and you lose it. On the break it is put back.
// The frame's result, the frames won and the best run of frames show at the end; the next click
// racks a new frame. Demo mode (api.demo): Nell plays both sides, a frame after frame, from a break
// in the first second.
import { GameApi, POINTER_DOWN, POINTER_UP, SFX_CLICK, SFX_TICK, SFX_THUD, SFX_ZAP,
    SFX_COIN, SFX_WIN, SFX_LOSE, SFX_NOTE, SFX_BELL, SFX_BLIP, SFX_WHOOSH } from "./game_api";

// ---------------------------------------------------------------- the table (world metres, Y up)
const R: f64 = 0.045;          // ball radius (pixel-art large: 9 cm balls on a 2 x 1 m bed)
const BY: f64 = 0.755;         // ball centres: the felt is at 0.71
const LX: f64 = 1.0;           // cushion noses
const LZ: f64 = 0.5;
const CM: f64 = 0.13;          // a corner pocket's mouth: the cushions stop this far from the corner
const SM: f64 = 0.085;         // a side pocket's mouth: half its width
const DECEL: f64 = 0.62;       // rolling friction, m/s^2
const DRAG: f64 = 0.12;        // a little air and cloth drag, 1/s
const E_BALL: f64 = 0.94;      // ball-ball restitution
const E_CUSH: f64 = 0.72;      // cushion restitution
const VMAX: f64 = 3.1;         // the hardest shot
const VBREAK: f64 = 3.7;       // a break
const SUBHZ: f64 = 480;        // physics sub-steps a second

const NB: i32 = 16;            // 0 cue, 1..7 suns, 8 night, 9..15 moons
const OPEN: i32 = 0;
const SUNS: i32 = 1;
const MOONS: i32 = 2;

const MODE_AIM: i32 = 0;       // a side lines up its shot
const MODE_PLACE: i32 = 1;     // ball in hand
const MODE_STRIKE: i32 = 2;    // the cue's forward stroke
const MODE_ROLL: i32 = 3;      // balls rolling
const MODE_OVER: i32 = 4;      // the frame's result

const YOU: i32 = 0;
const NELL: i32 = 1;

// palette indices (art/palette.json order)
const C_BLACK: i32 = 0;
const C_GREY: i32 = 1;
const C_WHITE: i32 = 2;
const C_MAROON: i32 = 3;
const C_RED: i32 = 4;
const C_ORANGE: i32 = 6;
const C_PEACH: i32 = 7;
const C_YELLOW: i32 = 8;
const C_LIME: i32 = 10;
const C_NAVY: i32 = 11;
const C_BLUE: i32 = 12;
const C_CYAN: i32 = 13;
const C_PINK: i32 = 15;

function clamp(v: f64, a: f64, b: f64): f64 {
    return v < a ? a : (v > b ? b : v);
}

function groupOf(i: i32): i32 {
    return i == 0 ? -1 : (i <= 7 ? SUNS : (i == 8 ? 3 : MOONS));
}

function groupName(g: i32): string {
    return g == SUNS ? "SUNS" : "MOONS";
}

export class Game {
    bones: StaticArray<i32> = new StaticArray<i32>(NB);
    cue: i32 = -1;
    lamp: i32 = -1;
    tail: i32 = -1;

    // the balls
    x: StaticArray<f64> = new StaticArray<f64>(NB);
    z: StaticArray<f64> = new StaticArray<f64>(NB);
    vx: StaticArray<f64> = new StaticArray<f64>(NB);
    vz: StaticArray<f64> = new StaticArray<f64>(NB);
    on: StaticArray<bool> = new StaticArray<bool>(NB);      // on the table
    sinkT: StaticArray<f64> = new StaticArray<f64>(NB);     // >= 0: dropping into a pocket
    sinkX: StaticArray<f64> = new StaticArray<f64>(NB);
    sinkZ: StaticArray<f64> = new StaticArray<f64>(NB);
    rot: StaticArray<f64> = new StaticArray<f64>(NB * 9);  // each ball's orientation (row-major 3x3)
    // pockets: centres (where a ball is caught) and aim points (where a shot aims), and the cushions
    pX: StaticArray<f64> = [-LX - 0.015, 0, LX + 0.015, -LX - 0.015, 0, LX + 0.015];
    pZ: StaticArray<f64> = [-LZ - 0.015, -LZ - 0.045, -LZ - 0.015, LZ + 0.015, LZ + 0.045, LZ + 0.015];
    pCap: StaticArray<f64> = [0.075, 0.068, 0.075, 0.075, 0.068, 0.075];
    aX: StaticArray<f64> = [-LX + 0.012, 0, LX - 0.012, -LX + 0.012, 0, LX - 0.012];
    aZ: StaticArray<f64> = [-LZ + 0.012, -LZ - 0.01, -LZ + 0.012, LZ - 0.012, LZ + 0.01, LZ - 0.012];
    sX0: StaticArray<f64> = [-LX + CM, SM, -LX + CM, SM, -LX, LX];
    sZ0: StaticArray<f64> = [-LZ, -LZ, LZ, LZ, -LZ + CM, -LZ + CM];
    sX1: StaticArray<f64> = [-SM, LX - CM, -SM, LX - CM, -LX, LX];
    sZ1: StaticArray<f64> = [-LZ, -LZ, LZ, LZ, LZ - CM, LZ - CM];

    // the frame
    mode: i32 = MODE_AIM;
    t: f64 = 0;                 // seconds in this mode
    turn: i32 = YOU;
    breaker: i32 = YOU;
    groups: StaticArray<i32> = new StaticArray<i32>(2);
    isBreak: bool = true;
    onNight: bool = false;      // the shooter had cleared its set before this shot
    firstHit: i32 = -1;
    pots: Array<i32> = new Array<i32>();
    cushionHits: i32 = 0;
    winner: i32 = -1;
    overWhy: string = "";
    frames: StaticArray<i32> = new StaticArray<i32>(2);
    run: i32 = 0;               // frames you won in a row
    best: i32 = 0;
    frameNo: i32 = 1;
    hinted: bool = false;       // the first shot was taken (the hint goes)

    // aiming
    aimA: f64 = 0;              // the shot's direction, radians in the x-z plane (atan2(dz, dx))
    power: f64 = 0;             // 0..1
    dragging: bool = false;
    pressX: f32 = 0;
    pressY: f32 = 0;
    // the computer (Nell, and both sides in demo)
    aiA: f64 = 0;               // where it means to aim
    aiFromA: f64 = 0;
    aiV: f64 = 0;               // the speed it means to hit
    aiThink: f64 = 0.8;
    aiPlaced: bool = false;
    placeOk: bool = true;
    placeDrag: bool = false;    // ball in hand: the press became a drag
    strikeV: f64 = 0;
    // the stroke
    pull: f64 = 0;              // the cue's draw back (m)

    // feedback
    msg: string = "";
    msg2: string = "";
    msgT: f64 = 9;
    msgCol: i32 = C_WHITE;
    clackV: f64 = 0;            // this frame's hardest impacts (for sound)
    clackX: f64 = 0;
    clackZ: f64 = 0;
    cushV: f64 = 0;
    cushX: f64 = 0;
    cushZ: f64 = 0;
    soundGap: f64 = 0;          // throttles clacks
    lampSwing: f64 = 0;
    lampT: f64 = 0;
    tailFlick: f64 = 0;
    ownPotsThisTurn: i32 = 0;

    // ---------------------------------------------------------------- set up
    start(api: GameApi): void {
        api.playable = true;
        this.bones[0] = api.bone("cueball");
        for (let i = 1; i <= 7; i++) this.bones[i] = api.bone("sun" + (i - 1).toString());
        this.bones[8] = api.bone("night");
        for (let i = 9; i <= 15; i++) this.bones[i] = api.bone("moon" + (i - 9).toString());
        this.cue = api.bone("cue");
        this.lamp = api.bone("lamp");
        this.tail = api.bone("tail");
        this.newMatch(api);
    }

    newMatch(api: GameApi): void {
        this.frames[0] = 0;
        this.frames[1] = 0;
        this.run = 0;
        this.frameNo = 1;
        this.breaker = YOU;
        this.hinted = false;
        this.newFrame(api);
    }

    newFrame(api: GameApi): void {
        // the rack: a triangle at the foot spot, the night ball in the middle of the third row, one
        // sun and one moon in the back corners, the rest shuffled (api.rand: a demo repeats)
        let order = new Array<i32>();
        for (let i = 1; i < NB; i++) if (i != 8) order.push(i);
        let suns = new Array<i32>(), moons = new Array<i32>();
        for (let k = 0; k < order.length; k++) {
            if (order[k] <= 7) suns.push(order[k]); else moons.push(order[k]);
        }
        this.shuffle(api, suns);
        this.shuffle(api, moons);
        let ids = new StaticArray<i32>(15);
        for (let k = 0; k < 15; k++) ids[k] = -1;
        ids[4] = 8;
        ids[10] = suns.pop();
        ids[14] = moons.pop();
        let rest = new Array<i32>();
        for (let k = 0; k < suns.length; k++) rest.push(suns[k]);
        for (let k = 0; k < moons.length; k++) rest.push(moons[k]);
        this.shuffle(api, rest);
        let d = 2 * R + 0.002;
        let k = 0;
        for (let row = 0; row < 5; row++) {
            for (let c = 0; c <= row; c++) {
                if (ids[k] < 0) ids[k] = rest.pop();
                let i = ids[k];
                this.x[i] = 0.5 + <f64>row * d * 0.8660254 + api.range(-0.001, 0.001);
                this.z[i] = (<f64>c - <f64>row * 0.5) * d + api.range(-0.001, 0.001);
                k++;
            }
        }
        this.x[0] = -0.5;
        this.z[0] = api.range(-0.06, 0.06);
        for (let i = 0; i < NB; i++) {
            this.vx[i] = 0;
            this.vz[i] = 0;
            this.on[i] = true;
            this.sinkT[i] = -1;
            this.randomTurn(api, i);
        }
        this.groups[0] = OPEN;
        this.groups[1] = OPEN;
        this.isBreak = true;
        this.turn = this.breaker;
        this.winner = -1;
        this.aimA = 0;
        this.power = 0;
        this.pull = 0;
        this.dragging = false;
        this.ownPotsThisTurn = 0;
        this.beginTurn(api, false);
        this.say(this.turn == YOU ? (api.demo ? "ALF BREAKS" : "YOUR BREAK") : "NELL BREAKS", "", C_YELLOW);
    }

    shuffle(api: GameApi, a: Array<i32>): void {
        for (let k = a.length - 1; k > 0; k--) {
            let j = <i32>(api.rand() * <f64>(k + 1));
            if (j > k) j = k;
            let t = a[k]; a[k] = a[j]; a[j] = t;
        }
    }

    randomTurn(api: GameApi, i: i32): void {
        let o = i * 9;
        for (let k = 0; k < 9; k++) this.rot[o + k] = 0;
        this.rot[o] = 1; this.rot[o + 4] = 1; this.rot[o + 8] = 1;
        this.rollBy(i, api.range(-1, 1), 0, api.range(-1, 1), api.range(0, 3.1));
    }

    // the ball's orientation turned by angle about the unit-ish axis (ax, ay, az): R' = Rot * R
    rollBy(i: i32, ax: f64, ay: f64, az: f64, ang: f64): void {
        let l = Math.sqrt(ax * ax + ay * ay + az * az);
        if (l < 1e-9 || Math.abs(ang) < 1e-9) return;
        ax /= l; ay /= l; az /= l;
        let c = Math.cos(ang), s = Math.sin(ang), u = 1 - c;
        let m00 = c + ax * ax * u, m01 = ax * ay * u - az * s, m02 = ax * az * u + ay * s;
        let m10 = ay * ax * u + az * s, m11 = c + ay * ay * u, m12 = ay * az * u - ax * s;
        let m20 = az * ax * u - ay * s, m21 = az * ay * u + ax * s, m22 = c + az * az * u;
        let o = i * 9;
        for (let col = 0; col < 3; col++) {
            let r0 = this.rot[o + col], r1 = this.rot[o + 3 + col], r2 = this.rot[o + 6 + col];
            this.rot[o + col] = m00 * r0 + m01 * r1 + m02 * r2;
            this.rot[o + 3 + col] = m10 * r0 + m11 * r1 + m12 * r2;
            this.rot[o + 6 + col] = m20 * r0 + m21 * r1 + m22 * r2;
        }
    }

    // ---------------------------------------------------------------- turns
    isAI(api: GameApi): bool {
        return api.demo || this.turn == NELL;
    }

    beginTurn(api: GameApi, inHand: bool): void {
        this.mode = inHand ? MODE_PLACE : MODE_AIM;
        this.t = 0;
        this.dragging = false;
        this.power = 0;
        this.pull = 0;
        this.aiPlaced = false;
        this.placeOk = true;
        let g = this.groups[this.turn];
        this.onNight = g != OPEN && this.remaining(g) == 0;
        if (inHand) {
            this.on[0] = true;
            this.sinkT[0] = -1;
            this.vx[0] = 0;
            this.vz[0] = 0;
            if (!this.freeSpot(this.x[0], this.z[0])) {
                this.x[0] = -0.5;
                this.z[0] = 0;
                while (!this.freeSpot(this.x[0], this.z[0]) && this.x[0] < 0.9) this.x[0] += 0.03;
            }
        }
        // the computer's think time: a break goes at once (the demo shows action in its first second)
        this.aiThink = this.isBreak ? 0.25 : api.range(0.7, 1.2);
        if (this.isAI(api) && !inHand) this.planShot(api);
    }

    remaining(g: i32): i32 {
        let n = 0;
        for (let i = 1; i < NB; i++) if (this.on[i] && this.sinkT[i] < 0 && groupOf(i) == g) n++;
        return n;
    }

    say(a: string, b: string, c: i32): void {
        this.msg = a;
        this.msg2 = b;
        this.msgT = 0;
        this.msgCol = c;
    }

    // ---------------------------------------------------------------- the computer player
    targets(g: i32): Array<i32> {
        let out = new Array<i32>();
        for (let i = 1; i < NB; i++) {
            if (!this.on[i]) continue;
            if (g == OPEN) {
                if (i != 8) out.push(i);
            } else if (groupOf(i) == g) {
                out.push(i);
            }
        }
        if (g != OPEN && out.length == 0 && this.on[8]) out.push(8);
        return out;
    }

    clearPath(ax: f64, az: f64, bx: f64, bz: f64, skipA: i32, skipB: i32, rad: f64): bool {
        let ex = bx - ax, ez = bz - az;
        let l2 = ex * ex + ez * ez;
        if (l2 < 1e-9) return true;
        for (let k = 0; k < NB; k++) {
            if (!this.on[k] || k == skipA || k == skipB) continue;
            let t = ((this.x[k] - ax) * ex + (this.z[k] - az) * ez) / l2;
            if (t < 0 || t > 1) continue;
            let px = ax + ex * t, pz = az + ez * t;
            let dx = this.x[k] - px, dz = this.z[k] - pz;
            if (dx * dx + dz * dz < rad * rad * 0.98) return false;
        }
        return true;
    }

    freeSpot(x: f64, z: f64): bool {
        if (Math.abs(x) > LX - R || Math.abs(z) > LZ - R) return false;
        for (let k = 1; k < NB; k++) {
            if (!this.on[k]) continue;
            let dx = this.x[k] - x, dz = this.z[k] - z;
            if (dx * dx + dz * dz < (2 * R + 0.004) * (2 * R + 0.004)) return false;
        }
        return true;
    }

    // the best pot from (cx, cz) for set g: sets bsScore, bsA (direction), bsV (speed); false if none
    bsScore: f64 = 0;
    bsA: f64 = 0;
    bsV: f64 = 0;
    bestShot(g: i32, cx: f64, cz: f64, loose: bool): bool {
        let found = false;
        this.bsScore = -1;
        let tg = this.targets(g);
        let f = loose ? 0.8 : 1.0;
        for (let q = 0; q < tg.length; q++) {
            let b = tg[q];
            let bx = this.x[b], bz = this.z[b];
            for (let p = 0; p < 6; p++) {
                let dx = this.aX[p] - bx, dz = this.aZ[p] - bz;
                let d2 = Math.sqrt(dx * dx + dz * dz);
                if (d2 < 1e-4) continue;
                let ux = dx / d2, uz = dz / d2;
                if ((p == 1 || p == 4) && Math.abs(uz) < 0.55) continue;   // a side pocket wants a square entry
                let gx = bx - ux * 2 * R, gz = bz - uz * 2 * R;
                if (Math.abs(gx) > LX - R + 0.01 || Math.abs(gz) > LZ - R + 0.01) continue;
                let sx = gx - cx, sz = gz - cz;
                let d1 = Math.sqrt(sx * sx + sz * sz);
                if (d1 < 1e-4) continue;
                sx /= d1; sz /= d1;
                let cs = sx * ux + sz * uz;
                if (cs < (loose ? 0.12 : 0.25)) continue;
                if (!this.clearPath(cx, cz, gx, gz, 0, b, 2 * R * f)) continue;
                if (!this.clearPath(bx, bz, this.aX[p], this.aZ[p], 0, b, 2 * R * f)) continue;
                let score = cs * cs / (1 + 0.5 * d1 + 0.9 * d2);
                if (score > this.bsScore) {
                    let vobj = Math.sqrt(2 * DECEL * (d2 + 0.25)) + 0.25;
                    let vv = vobj / Math.max(cs, 0.3) / 0.97;
                    let v = Math.sqrt(vv * vv + 2 * DECEL * d1) * 1.15;
                    this.bsScore = score;
                    this.bsA = Math.atan2(sz, sx);
                    this.bsV = clamp(v, 0.6, VMAX);
                    found = true;
                }
            }
        }
        return found;
    }

    planShot(api: GameApi): void {
        let g = this.groups[this.turn];
        let skill = api.demo && this.turn == YOU ? 0.024 : 0.022;
        let cx = this.x[0], cz = this.z[0];
        this.aiFromA = this.aimA;
        if (this.isBreak) {
            let a = Math.atan2(0 - cz, 0.5 - cx) + api.range(-1, 1) * 0.01;
            this.aiA = a;
            this.aiV = VBREAK * api.range(0.94, 1.0);
            return;
        }
        let ok = this.bestShot(g, cx, cz, false);
        if (!ok) ok = this.bestShot(g, cx, cz, true);
        if (!ok || (this.bsScore < 0.05 && api.rand() < 0.5) || api.rand() < 0.04) {
            // a safety: roll up to one of its own balls, a half-ball hit, gently
            let tg = this.targets(g);
            let cands = new Array<i32>();
            for (let q = 0; q < tg.length; q++) {
                let b = tg[q];
                if (this.clearPath(cx, cz, this.x[b], this.z[b], 0, b, 2 * R)) cands.push(b);
            }
            if (cands.length == 0) cands = tg;
            let b = cands[min<i32>(cands.length - 1, <i32>(api.rand() * <f64>cands.length))];
            let dx = this.x[b] - cx, dz = this.z[b] - cz;
            let d = Math.max(0.001, Math.sqrt(dx * dx + dz * dz));
            let side = api.rand() < 0.5 ? 1.0 : -1.0;
            let tx = this.x[b] - dz / d * R * side, tz = this.z[b] + dx / d * R * side;
            this.aiA = Math.atan2(tz - cz, tx - cx) + api.range(-1, 1) * skill * 0.5;
            this.aiV = Math.min(1.6, 0.7 + d * 0.5);
            return;
        }
        let err = (api.rand() + api.rand() - 1) * skill;
        this.aiA = this.bsA + err;
        this.aiV = this.bsV * api.range(0.95, 1.1);
    }

    placeInHand(api: GameApi): void {
        let g = this.groups[this.turn];
        let bestS = -2.0, bx = -0.5, bz = 0.0;
        for (let k = 0; k < 40; k++) {
            let x = api.range(-LX + R + 0.02, LX - R - 0.02);
            let z = api.range(-LZ + R + 0.02, LZ - R - 0.02);
            if (!this.freeSpot(x, z)) continue;
            let s = this.bestShot(g, x, z, false) ? this.bsScore : -1.0;
            if (s > bestS) {
                bestS = s;
                bx = x;
                bz = z;
            }
        }
        this.x[0] = bx;
        this.z[0] = bz;
    }

    // ---------------------------------------------------------------- every frame
    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged) {
            this.best = 0;
            this.newMatch(api);
        }
        this.t += dt;
        this.msgT += dt;
        this.soundGap -= dt;

        if (this.mode == MODE_PLACE) {
            if (this.isAI(api)) {
                if (!this.aiPlaced && this.t > 0.5) {
                    this.placeInHand(api);
                    this.aiPlaced = true;
                    api.soundAt(SFX_CLICK, this.x[0], BY, this.z[0], 0.7, 0.6);
                }
                if (this.aiPlaced && this.t > 0.9) {
                    this.mode = MODE_AIM;
                    this.t = 0;
                    this.aiThink = api.range(0.5, 0.9);
                    this.planShot(api);
                }
            }
        } else if (this.mode == MODE_AIM) {
            if (this.isAI(api)) {
                // turn the cue towards the planned line, draw it back, strike
                let turnT = Math.max(0.05, this.aiThink * 0.6);
                let k = clamp(this.t / turnT, 0, 1);
                k = k * k * (3 - 2 * k);
                let da = this.aiA - this.aiFromA;
                while (da > Math.PI) da -= 2 * Math.PI;
                while (da < -Math.PI) da += 2 * Math.PI;
                this.aimA = this.aiFromA + da * k;
                let pk = clamp((this.t - turnT) / (this.aiThink * 0.4 + 0.1), 0, 1);
                this.power = (this.aiV - 0.2) / (VMAX - 0.2) * pk;
                if (this.t > turnT + this.aiThink * 0.4 + 0.15) {
                    this.aimA = this.aiA;
                    this.shoot(api, this.aiV);
                }
            }
        } else if (this.mode == MODE_STRIKE) {
            if (this.t >= 0.07) {
                this.launch(api);
            }
        } else if (this.mode == MODE_ROLL) {
            this.physics(api, dt);
            this.shotSounds(api);
            if (!this.moving() && this.t > 0.2) {
                this.endShot(api);
            }
        } else if (this.mode == MODE_OVER) {
            if (api.demo && this.t > 2.0) {
                this.nextFrame(api);
            }
        }
        if (this.mode != MODE_ROLL) {
            // a ball still dropping into a pocket when the shot is judged finishes its fall
            this.sinkOnly(dt);
        }
        this.place(api, dt);
    }

    nextFrame(api: GameApi): void {
        this.frameNo++;
        this.breaker = 1 - this.breaker;
        this.newFrame(api);
        api.sound(SFX_WHOOSH, 0.7, 0.5);
        for (let k = 0; k < 6; k++) {
            api.sound(SFX_TICK, 0.7 + <f64>k * 0.05, 0.35, 0.3, 0.05 + <f64>k * 0.05);   // the rack clicked together
        }
    }

    shoot(api: GameApi, v: f64): void {
        this.strikeV = v;
        this.mode = MODE_STRIKE;
        this.t = 0;
    }

    launch(api: GameApi): void {
        let v = this.strikeV;
        this.vx[0] = Math.cos(this.aimA) * v;
        this.vz[0] = Math.sin(this.aimA) * v;
        let p = clamp(v / VMAX, 0, 1.2);
        api.soundAt(SFX_CLICK, this.x[0], BY, this.z[0], 0.75 + p * 0.5, 0.45 + p * 0.5);
        api.soundAt(SFX_THUD, this.x[0], BY, this.z[0], 1.7 + p * 0.6, 0.15 + p * 0.45);
        if (this.isBreak) {
            api.soundAt(SFX_WHOOSH, this.x[0], BY, this.z[0], 1.4, 0.35);
            this.lampSwing = 1.6;
        }
        this.firstHit = -1;
        this.pots.length = 0;
        this.cushionHits = 0;
        this.onNight = this.groups[this.turn] != OPEN && this.remaining(this.groups[this.turn]) == 0;
        this.mode = MODE_ROLL;
        this.t = 0;
        this.hinted = true;
        this.power = 0;
    }

    moving(): bool {
        for (let i = 0; i < NB; i++) {
            if (this.sinkT[i] >= 0) return true;
            if (this.on[i] && (this.vx[i] != 0 || this.vz[i] != 0)) return true;
        }
        return false;
    }

    // ---------------------------------------------------------------- physics
    physics(api: GameApi, dt: f64): void {
        let n = <i32>Math.ceil(dt * SUBHZ);
        if (n < 1) n = 1;
        if (n > 48) n = 48;
        let h = dt / <f64>n;
        for (let s = 0; s < n; s++) {
            this.subStep(h);
        }
        // the balls roll: each turns about the horizontal axis across its motion
        for (let i = 0; i < NB; i++) {
            if (!this.on[i]) continue;
            let sp = Math.sqrt(this.vx[i] * this.vx[i] + this.vz[i] * this.vz[i]);
            if (sp > 0) this.rollBy(i, this.vz[i], 0, -this.vx[i], sp * dt / R);
        }
        this.sinkOnly(dt);
    }

    sinkOnly(dt: f64): void {
        for (let i = 0; i < NB; i++) {
            if (this.sinkT[i] >= 0) {
                this.sinkT[i] += dt;
                if (this.sinkT[i] > 0.32) this.sinkT[i] = -1;
            }
        }
    }

    subStep(h: f64): void {
        for (let i = 0; i < NB; i++) {
            if (!this.on[i]) continue;
            let sp = Math.sqrt(this.vx[i] * this.vx[i] + this.vz[i] * this.vz[i]);
            if (sp > 0) {
                let ns = Math.max(0, sp - DECEL * h - DRAG * sp * h);
                if (ns < 0.008) ns = 0;
                this.vx[i] *= ns / sp;
                this.vz[i] *= ns / sp;
            }
            this.x[i] += this.vx[i] * h;
            this.z[i] += this.vz[i] * h;
        }
        // ball against ball: equal masses, nearly elastic, along the line of centres
        for (let i = 0; i < NB; i++) {
            if (!this.on[i]) continue;
            for (let j = i + 1; j < NB; j++) {
                if (!this.on[j]) continue;
                let dx = this.x[j] - this.x[i], dz = this.z[j] - this.z[i];
                let d2 = dx * dx + dz * dz;
                if (d2 < 4 * R * R && d2 > 1e-12) {
                    let d = Math.sqrt(d2);
                    let nx = dx / d, nz = dz / d;
                    let rv = (this.vx[i] - this.vx[j]) * nx + (this.vz[i] - this.vz[j]) * nz;
                    if (rv > 0) {
                        let jj = (1 + E_BALL) * 0.5 * rv;
                        this.vx[i] -= jj * nx; this.vz[i] -= jj * nz;
                        this.vx[j] += jj * nx; this.vz[j] += jj * nz;
                        if (rv > this.clackV) {
                            this.clackV = rv;
                            this.clackX = this.x[i] + nx * R;
                            this.clackZ = this.z[i] + nz * R;
                        }
                        if (this.firstHit < 0 && (i == 0 || j == 0)) this.firstHit = i == 0 ? j : i;
                    }
                    let ov = (2 * R - d) * 0.5;
                    this.x[i] -= nx * ov; this.z[i] -= nz * ov;
                    this.x[j] += nx * ov; this.z[j] += nz * ov;
                }
            }
        }
        // cushions (segments between the pocket mouths; their ends are the jaws) and pockets
        for (let i = 0; i < NB; i++) {
            if (!this.on[i]) continue;
            for (let c = 0; c < 6; c++) {
                let x0 = this.sX0[c], z0 = this.sZ0[c];
                let ex = this.sX1[c] - x0, ez = this.sZ1[c] - z0;
                let t = ((this.x[i] - x0) * ex + (this.z[i] - z0) * ez) / (ex * ex + ez * ez);
                t = clamp(t, 0, 1);
                let dx = this.x[i] - (x0 + ex * t), dz = this.z[i] - (z0 + ez * t);
                let d2 = dx * dx + dz * dz;
                if (d2 < R * R && d2 > 1e-12) {
                    let d = Math.sqrt(d2);
                    let nx = dx / d, nz = dz / d;
                    let vn = this.vx[i] * nx + this.vz[i] * nz;
                    if (vn < 0) {
                        this.vx[i] -= (1 + E_CUSH) * vn * nx;
                        this.vz[i] -= (1 + E_CUSH) * vn * nz;
                        this.vx[i] *= 0.97;
                        this.vz[i] *= 0.97;
                        this.cushionHits++;
                        if (-vn > this.cushV) {
                            this.cushV = -vn;
                            this.cushX = this.x[i];
                            this.cushZ = this.z[i];
                        }
                    }
                    this.x[i] += nx * (R - d);
                    this.z[i] += nz * (R - d);
                }
            }
            let caught = -1;
            for (let p = 0; p < 6; p++) {
                let dx = this.x[i] - this.pX[p], dz = this.z[i] - this.pZ[p];
                if (dx * dx + dz * dz < this.pCap[p] * this.pCap[p]) {
                    caught = p;
                    break;
                }
            }
            if (caught < 0 && (Math.abs(this.x[i]) > LX + 0.06 || Math.abs(this.z[i]) > LZ + 0.06)) {
                // past the jaws: into the nearest pocket
                let bd = 1e9;
                for (let p = 0; p < 6; p++) {
                    let dx = this.x[i] - this.pX[p], dz = this.z[i] - this.pZ[p];
                    if (dx * dx + dz * dz < bd) { bd = dx * dx + dz * dz; caught = p; }
                }
            }
            if (caught >= 0) {
                this.on[i] = false;
                this.vx[i] = 0;
                this.vz[i] = 0;
                this.sinkT[i] = 0;
                this.sinkX[i] = this.pX[caught];
                this.sinkZ[i] = this.pZ[caught];
                this.pots.push(i);
                this.potEvent = true;
            }
        }
    }
    potEvent: bool = false;

    shotSounds(api: GameApi): void {
        // the hardest clack and cushion thud of this frame (rate limited), each pocket's rattle
        if (this.clackV > 0.04 && this.soundGap <= 0) {
            let v = clamp(this.clackV / 3.0, 0, 1);
            api.soundAt(SFX_TICK, this.clackX, BY, this.clackZ, 1.25 + v * 0.35, 0.3 + v * 0.7);
            api.soundAt(SFX_CLICK, this.clackX, BY, this.clackZ, 0.8 + v * 0.4, 0.25 + v * 0.6);
            this.soundGap = 0.035;
        }
        if (this.cushV > 0.15) {
            let v = clamp(this.cushV / 3.0, 0, 1);
            api.soundAt(SFX_THUD, this.cushX, BY, this.cushZ, 1.15 + v * 0.3, 0.2 + v * 0.55);
            if (this.cushV > 1.6) this.lampSwing = Math.max(this.lampSwing, 0.6);
        }
        this.clackV = 0;
        this.cushV = 0;
        if (this.potEvent) {
            this.potEvent = false;
            for (let k = 0; k < this.pots.length; k++) {
                let i = this.pots[k];
                if (this.sinkT[i] != 0) continue;          // only the ones that dropped this frame
                let px = this.sinkX[i], pz = this.sinkZ[i];
                // the rattle: the ball knocks round the pocket's iron, then drops
                api.soundAt(SFX_TICK, px, BY, pz, 1.1, 0.8);
                api.soundAt(SFX_TICK, px, BY, pz, 0.95, 0.6, 0.06);
                api.soundAt(SFX_TICK, px, BY, pz, 1.05, 0.45, 0.11);
                api.soundAt(SFX_CLICK, px, BY, pz, 0.6, 0.35, 0.15);
                api.soundAt(SFX_THUD, px, BY, pz, 0.85, 0.7, 0.2);
                this.tailFlick = 1;
            }
        }
    }

    // ---------------------------------------------------------------- the rules
    endShot(api: GameApi): void {
        let g = this.groups[this.turn];
        let scratch = false, night = false;
        for (let k = 0; k < this.pots.length; k++) {
            if (this.pots[k] == 0) scratch = true;
            if (this.pots[k] == 8) night = true;
        }
        let foul = scratch || this.firstHit < 0;
        let why = scratch ? "THE CUE BALL WENT DOWN" : (this.firstHit < 0 ? "NO BALL HIT" : "");
        if (!foul) {
            if (g == OPEN) {
                if (this.firstHit == 8 && !this.isBreak) { foul = true; why = "THE NIGHT BALL HIT FIRST"; }
            } else if (this.onNight) {
                if (this.firstHit != 8) { foul = true; why = "THE NIGHT BALL MUST BE HIT FIRST"; }
            } else if (groupOf(this.firstHit) != g) {
                foul = true;
                why = this.firstHit == 8 ? "THE NIGHT BALL HIT FIRST" : "HIT THE " + groupName(3 - g) + " FIRST";
            }
        }
        let who = this.turn == YOU ? (api.demo ? "ALF" : "YOU") : "NELL";
        if (night) {
            if (this.isBreak && !foul) {
                // the night ball off the break comes back to the foot spot
                let nx = 0.5;
                while (!this.freeSpot(nx, 0) && nx < 0.9) nx += 0.02;
                this.x[8] = nx;
                this.z[8] = 0;
                this.on[8] = true;
                this.sinkT[8] = -1;
                this.say("NIGHT BALL ON THE BREAK", "IT GOES BACK ON THE SPOT", C_CYAN);
            } else {
                let win = this.onNight && !foul;
                this.endFrame(api, win ? this.turn : 1 - this.turn,
                    win ? "THE NIGHT BALL, CLEAN" : (foul ? "A FOUL ON THE NIGHT BALL" : "THE NIGHT BALL TOO EARLY"));
                return;
            }
        }
        // the first pot claims a set
        let firstCol = -1;
        for (let k = 0; k < this.pots.length; k++) {
            let i = this.pots[k];
            if (i != 0 && i != 8 && this.on[i] == false) { firstCol = i; break; }
        }
        let claimed = false;
        if (g == OPEN && !foul && firstCol > 0) {
            g = groupOf(firstCol);
            this.groups[this.turn] = g;
            this.groups[1 - this.turn] = 3 - g;
            claimed = true;
        }
        let own = 0;
        if (g != OPEN) {
            for (let k = 0; k < this.pots.length; k++) if (groupOf(this.pots[k]) == g) own++;
        }
        let wasBreak = this.isBreak;
        this.isBreak = false;
        if (foul) {
            this.turn = 1 - this.turn;
            api.sound(SFX_ZAP, 0.32, 0.55);
            api.sound(SFX_ZAP, 0.28, 0.5, 0, 0.13);
            let next = this.turn == YOU ? (api.demo ? "ALF HAS" : "YOU HAVE") : "NELL HAS";
            this.say("FOUL - " + why, next + " BALL IN HAND", C_PINK);
            this.beginTurn(api, true);
            return;
        }
        if (claimed) {
            this.say(who + (this.turn == YOU && !api.demo ? " TAKE THE " : " TAKES THE ") + groupName(g), "", g == SUNS ? C_YELLOW : C_CYAN);
            api.sound(SFX_COIN, 1.0, 0.6);
        }
        if (own > 0) {
            // a rising note per ball of yours this visit
            for (let k = 0; k < own; k++) {
                api.note(<f64>(72 + min<i32>(this.ownPotsThisTurn, 7) * 2), 0.35, 0, SFX_BELL, <f64>k * 0.1);
                this.ownPotsThisTurn++;
            }
            if (!claimed) {
                if (this.remaining(g) == 0) {
                    this.say(who + (this.turn == YOU && !api.demo ? " ARE" : " IS") + " ON THE NIGHT BALL", "", C_CYAN);
                } else if (this.msgT > 1.0) {
                    this.say(this.turn == YOU ? (api.demo ? "ALF AGAIN" : "SHOOT AGAIN") : "NELL AGAIN", "", C_LIME);
                }
            }
            this.beginTurn(api, false);
            return;
        }
        // no ball of yours: the other side's turn
        this.turn = 1 - this.turn;
        this.ownPotsThisTurn = 0;
        if (!claimed || wasBreak) {
            if (this.turn == YOU && !api.demo) {
                this.say("YOUR SHOT", "", C_YELLOW);
                api.sound(SFX_BLIP, 1.2, 0.35);
            } else if (this.turn == NELL) {
                this.say("NELL'S SHOT", "", C_PINK);
            } else {
                this.say("ALF'S SHOT", "", C_YELLOW);
            }
        }
        this.beginTurn(api, false);
    }

    endFrame(api: GameApi, w: i32, why: string): void {
        this.winner = w;
        this.overWhy = why;
        this.frames[w]++;
        if (w == YOU) {
            this.run++;
            if (this.run > this.best) this.best = this.run;
            api.sound(SFX_WIN, 1.0, 0.7);
            let tune: StaticArray<i32> = [72, 76, 79, 84, 79, 84];
            for (let k = 0; k < tune.length; k++) api.note(<f64>tune[k], 0.55, 0, SFX_NOTE, 0.35 + <f64>k * 0.12);
        } else {
            this.run = 0;
            api.sound(SFX_LOSE, 0.9, 0.7);
            let tune: StaticArray<i32> = [67, 63, 60, 55];
            for (let k = 0; k < tune.length; k++) api.note(<f64>tune[k], 0.5, 0, SFX_NOTE, 0.5 + <f64>k * 0.16);
        }
        this.msgT = 9;
        this.mode = MODE_OVER;
        this.t = 0;
        this.tailFlick = 1;
    }

    // ---------------------------------------------------------------- the pointer (never in demo)
    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (this.mode == MODE_OVER) {
            if (kind == POINTER_DOWN && this.t > 0.6) this.nextFrame(api);
            return true;
        }
        if (this.turn != YOU) return true;
        if (this.mode == MODE_PLACE) {
            // ball in hand: a tap puts the cue ball where it taps; a drag carries it, held a few art
            // pixels above the finger (24 / pixelSize) so the finger does not hide it, and leaves it
            // where it is let go
            if (kind == POINTER_DOWN) {
                this.dragging = true;
                this.pressX = x;
                this.pressY = y;
                this.placeDrag = false;
            }
            if (this.dragging && Math.abs(<f64>(x - this.pressX)) + Math.abs(<f64>(y - this.pressY)) > 3) this.placeDrag = true;
            let lift = this.placeDrag ? <f32>(24.0 / api.pixelSize) : <f32>0;
            if (this.dragging && api.pick(x, y - lift, <f32>BY)) {
                this.x[0] = clamp(<f64>api.hitX, -LX + R, LX - R);
                this.z[0] = clamp(<f64>api.hitZ, -LZ + R, LZ - R);
                this.placeOk = this.freeSpot(this.x[0], this.z[0]);
            }
            if (kind == POINTER_UP && this.dragging) {
                this.dragging = false;
                if (this.placeOk) {
                    api.soundAt(SFX_CLICK, this.x[0], BY, this.z[0], 0.7, 0.6);
                    this.mode = MODE_AIM;
                    this.t = 0;
                } else {
                    api.sound(SFX_TICK, 0.5, 0.5);
                }
            }
            return true;
        }
        if (this.mode != MODE_AIM) return true;
        if (kind == POINTER_DOWN) {
            this.dragging = true;
            this.pressX = x;
            this.pressY = y;
            this.power = 0;
        }
        if (!this.dragging) return true;
        // the cue follows the pointer: it aims from the pointer through the cue ball
        if (api.pick(x, y, <f32>BY)) {
            let dx = this.x[0] - <f64>api.hitX, dz = this.z[0] - <f64>api.hitZ;
            if (dx * dx + dz * dz > 0.03 * 0.03) this.aimA = Math.atan2(dz, dx);
        }
        let ddx = <f64>(x - this.pressX), ddy = <f64>(y - this.pressY);
        this.power = clamp(Math.sqrt(ddx * ddx + ddy * ddy) / 70.0, 0, 1);
        if (kind == POINTER_UP) {
            this.dragging = false;
            if (this.power > 0.05) {
                this.shoot(api, 0.2 + this.power * (VMAX - 0.2));
            } else {
                this.power = 0;
            }
        }
        return true;
    }

    // ---------------------------------------------------------------- the picture
    place(api: GameApi, dt: f64): void {
        for (let i = 0; i < NB; i++) {
            let b = this.bones[i];
            let x = this.x[i], y = BY, z = this.z[i];
            if (this.sinkT[i] >= 0) {
                // dropping: slides to the pocket's middle and sinks under its rim
                let k = clamp(this.sinkT[i] / 0.32, 0, 1);
                x = this.sinkX[i] + (this.x[i] - this.sinkX[i]) * (1 - k);
                z = this.sinkZ[i] + (this.z[i] - this.sinkZ[i]) * (1 - k);
                y = BY - k * k * 0.12;
            } else if (!this.on[i]) {
                api.hide(b);
                continue;
            }
            if (i == 0 && this.mode == MODE_PLACE && !this.placeOk && Math.floor(api.time * 8) % 2 == 0) {
                api.hide(b);           // a spot where it cannot go: it blinks
                continue;
            }
            let o = i * 9;
            let r02 = this.rot[o + 2], r22 = this.rot[o + 8], r12 = this.rot[o + 5];
            let r10 = this.rot[o + 3], r11 = this.rot[o + 4];
            let pitch = Math.asin(clamp(-r12, -1, 1));
            let yaw = Math.atan2(r02, r22);
            let roll = Math.atan2(r10, r11);
            api.place(b, x, y, z, yaw * 180 / Math.PI, pitch * 180 / Math.PI, roll * 180 / Math.PI);
        }
        // the cue: behind the cue ball on the aim line, drawn back with the power, a quick stroke
        let showCue = this.mode == MODE_AIM || this.mode == MODE_STRIKE;
        if (showCue && this.on[0]) {
            let target = 0.03 + this.power * 0.28;
            if (this.mode == MODE_STRIKE) {
                target = -0.004;
                this.pull += (target - this.pull) * Math.min(1, dt * 40);
            } else {
                this.pull += (target - this.pull) * Math.min(1, dt * 18);
            }
            let dx = Math.cos(this.aimA), dz = Math.sin(this.aimA);
            let d = R + this.pull;
            let yaw = Math.atan2(dx, dz) * 180 / Math.PI;
            api.place(this.cue, this.x[0] - dx * d, BY + 0.012, this.z[0] - dz * d, yaw, 7);
        } else {
            api.hide(this.cue);
        }
        // the lamp swings a little after a break or a hard shot (stepped, 10 a second)
        this.lampSwing *= Math.exp(-dt * 0.9);
        this.lampT += dt;
        let st = Math.floor(this.lampT * 10) / 10;
        let sw = this.lampSwing * Math.sin(st * 2.6);
        api.place(this.lamp, api.restX[this.lamp], api.restY[this.lamp], api.restZ[this.lamp], 0, sw * 0.5, sw);
        // Biscuit's tail: a slow sway in its sleep, a flick when a ball drops (stepped, 8 a second)
        this.tailFlick = Math.max(0, this.tailFlick - dt * 1.2);
        let tt = Math.floor(api.time * 8) / 8;
        let tail = 10 * Math.sin(tt * 1.3) + 28 * this.tailFlick * Math.sin(tt * 18);
        api.place(this.tail, api.restX[this.tail], api.restY[this.tail], api.restZ[this.tail],
            <f64>api.restYaw[this.tail] + tail);
    }

    // first contact along the aim (for the guide): sets gdT (distance), gdBall (-1: a cushion)
    gdT: f64 = 0;
    gdBall: i32 = -1;
    guideRay(): void {
        let cx = this.x[0], cz = this.z[0];
        let dx = Math.cos(this.aimA), dz = Math.sin(this.aimA);
        let best = 1e9;
        this.gdBall = -1;
        for (let b = 1; b < NB; b++) {
            if (!this.on[b]) continue;
            let ox = this.x[b] - cx, oz = this.z[b] - cz;
            let along = ox * dx + oz * dz;
            if (along <= 0) continue;
            let perp2 = ox * ox + oz * oz - along * along;
            if (perp2 >= 4 * R * R) continue;
            let t = along - Math.sqrt(4 * R * R - perp2);
            if (t < best) {
                best = t;
                this.gdBall = b;
            }
        }
        // the cushion box the cue ball's centre stays in
        let tx = dx > 1e-6 ? (LX - R - cx) / dx : (dx < -1e-6 ? (-LX + R - cx) / dx : 1e9);
        let tz = dz > 1e-6 ? (LZ - R - cz) / dz : (dz < -1e-6 ? (-LZ + R - cz) / dz : 1e9);
        let tc = Math.max(0, Math.min(tx, tz));
        if (tc < best) {
            best = tc;
            this.gdBall = -1;
        }
        this.gdT = best;
    }

    hud(api: GameApi): void {
        let black = api.paletteColor(C_BLACK);
        let white = api.paletteColor(C_WHITE);
        let grey = api.paletteColor(C_GREY);
        let yellow = api.paletteColor(C_YELLOW);
        let cyan = api.paletteColor(C_CYAN);
        let navy = api.paletteColor(C_NAVY);
        let pink = api.paletteColor(C_PINK);
        let peach = api.paletteColor(C_PEACH);
        let maroon = api.paletteColor(C_MAROON);
        let w = <f32>api.hudW, h = <f32>api.hudH;
        let cxm = Mathf.floor(w * 0.5);

        // the aim guide: a dotted line to the first ball, its ghost, where both balls go next
        let aiming = this.mode == MODE_AIM && this.on[0] && (this.dragging || this.isAI(api) || this.power > 0);
        if (this.mode == MODE_AIM && this.on[0] && this.turn == YOU && !api.demo) aiming = true;
        if (aiming) {
            this.guideRay();
            let cx = this.x[0], cz = this.z[0];
            let dx = Math.cos(this.aimA), dz = Math.sin(this.aimA);
            let gx = cx + dx * this.gdT, gz = cz + dz * this.gdT;
            let lineC = this.isAI(api) ? grey : white;
            let steps = <i32>(this.gdT / 0.03);
            for (let k = 1; k <= steps; k++) {
                if (k % 2 == 1) continue;
                let px = cx + dx * <f64>k * 0.03, pz = cz + dz * <f64>k * 0.03;
                api.project(<f32>px, <f32>BY, <f32>pz);
                api.rect(Mathf.round(api.screenX), Mathf.round(api.screenY), 1, 1, lineC);
            }
            // the ghost ball: a ring where the cue ball will be at the contact
            let seg = 12;
            for (let k = 0; k < seg; k++) {
                let a0 = <f64>k / <f64>seg * 2 * Math.PI, a1 = <f64>(k + 1) / <f64>seg * 2 * Math.PI;
                api.project(<f32>(gx + Math.cos(a0) * R), <f32>BY, <f32>(gz + Math.sin(a0) * R));
                let sx0 = api.screenX, sy0 = api.screenY;
                api.project(<f32>(gx + Math.cos(a1) * R), <f32>BY, <f32>(gz + Math.sin(a1) * R));
                api.line(sx0, sy0, api.screenX, api.screenY, lineC);
            }
            if (this.gdBall > 0) {
                let b = this.gdBall;
                let nx = this.x[b] - gx, nz = this.z[b] - gz;
                let nl = Math.max(1e-6, Math.sqrt(nx * nx + nz * nz));
                nx /= nl; nz /= nl;
                let cs = dx * nx + dz * nz;
                // the object ball's line, longer the fuller the hit
                let ol = 0.08 + 0.32 * cs;
                let legal = this.legalFirst(b);
                api.project(<f32>this.x[b], <f32>BY, <f32>this.z[b]);
                let ax = api.screenX, ay = api.screenY;
                api.project(<f32>(this.x[b] + nx * ol), <f32>BY, <f32>(this.z[b] + nz * ol));
                api.line(ax, ay, api.screenX, api.screenY, legal ? (groupOf(b) == MOONS ? cyan : (b == 8 ? peach : yellow)) : pink);
                // the cue ball glances off along the tangent
                let tx = dx - cs * nx, tz = dz - cs * nz;
                let tl = Math.sqrt(tx * tx + tz * tz);
                if (tl > 0.05) {
                    let ll = 0.05 + 0.2 * tl;
                    tx /= tl; tz /= tl;
                    api.project(<f32>gx, <f32>BY, <f32>gz);
                    let bx = api.screenX, by = api.screenY;
                    api.project(<f32>(gx + tx * ll), <f32>BY, <f32>(gz + tz * ll));
                    let ex = api.screenX, ey = api.screenY;
                    let n = 8;
                    for (let k = 0; k <= n; k++) {
                        if (k % 2 == 1) continue;
                        let f = <f32>k / <f32>n;
                        api.rect(Mathf.round(bx + (ex - bx) * f), Mathf.round(by + (ey - by) * f), 1, 1, grey);
                    }
                }
                if (!legal && !this.isAI(api)) {
                    api.project(<f32>this.x[b], <f32>BY, <f32>this.z[b]);
                    api.text(Mathf.round(api.screenX) - 8, Mathf.round(api.screenY) - 12, "FOUL", pink, 1, black);
                }
            }
        }

        // the scoreboard: frames won, each side's set (a dot per ball left), whose shot
        api.rect(0, 0, w, 13, black);
        api.rect(0, 13, w, 1, maroon);
        let youName = api.demo ? "ALF" : "YOU";
        api.text(4, 4, youName, this.turn == YOU && this.mode != MODE_OVER ? white : grey, 1, 0);
        api.text(w - 4 - api.textWidth("NELL", 1), 4, "NELL", this.turn == NELL && this.mode != MODE_OVER ? white : grey, 1, 0);
        if (this.mode != MODE_OVER && Math.floor(api.time * 3) % 2 == 0) {
            if (this.turn == YOU) api.text(4 + api.textWidth(youName, 1) + 3, 4, "<", white, 1, 0);
            else api.text(w - 4 - api.textWidth("NELL", 1) - 7, 4, ">", white, 1, 0);
        }
        this.setDots(api, 0, 4 + api.textWidth(youName, 1) + 10, false);
        this.setDots(api, 1, w - 4 - api.textWidth("NELL", 1) - 10, true);
        let score = this.frames[0].toString() + " - " + this.frames[1].toString();
        api.text(cxm - Mathf.floor(api.textWidth(score, 2) * 0.5), 2, score, peach, 2, 0);
        api.text(cxm - 50, 4, "FRAMES", grey, 1, 0);
        api.text(cxm + 27, 4, "BEST " + this.best.toString(), grey, 1, 0);

        // the power meter while a shot is drawn back
        if (this.mode == MODE_AIM && this.power > 0.0) {
            let mw: f32 = 80;
            let mx = cxm - mw * 0.5, my = h - 12;
            api.rect(mx - 1, my - 1, mw + 2, 7, black);
            let fill = Mathf.round(<f32>clamp(this.power, 0, 1) * mw);
            let pc = this.power < 0.45 ? yellow : (this.power < 0.8 ? api.paletteColor(C_ORANGE) : api.paletteColor(C_RED));
            api.rect(mx, my, fill, 5, pc);
            api.text(mx - 26, my, "POWER", grey, 1, black);
        }

        // messages over the table
        if (this.msgT < 2.2 && this.mode != MODE_OVER && this.msg.length > 0) {
            let blink = this.msgT < 0.5 && Math.floor(this.msgT * 10) % 2 == 1;
            let c = api.paletteColor(this.msgCol);
            api.textCentered(26, this.msg, blink ? white : c, 1, black);
            if (this.msg2.length > 0) api.textCentered(34, this.msg2, white, 1, black);
        }
        if (this.mode == MODE_PLACE && this.turn == YOU && !api.demo) {
            api.textCentered(h - 20, "BALL IN HAND", white, 1, black);
            api.textCentered(h - 11, "TAP OR DRAG TO PLACE THE CUE BALL", Math.floor(api.time * 2) % 2 == 0 ? peach : white, 1, black);
        } else if (this.mode == MODE_AIM && this.turn == YOU && !api.demo && !this.hinted && this.power <= 0) {
            api.rect(0, h - 25, w, 25, black);
            api.rect(0, h - 26, w, 1, maroon);
            api.textCentered(h - 22, "PRESS, DRAG BACK FROM THE CUE BALL, RELEASE", Math.floor(api.time * 2) % 2 == 0 ? peach : white, 1, black);
            api.textCentered(h - 13, "SUNS OR MOONS, THEN THE NIGHT BALL - FIRST TO POT ONE CLAIMS A SET", grey, 1, black);
        }
        if (this.mode == MODE_OVER) {
            let bw: f32 = 170, bh: f32 = 46;
            let bx = Mathf.floor((w - bw) * 0.5), by = Mathf.floor(h * 0.5 - 30);
            api.rect(bx, by, bw, bh, black);
            api.rect(bx - 1, by - 1, bw + 2, 1, maroon);
            api.rect(bx - 1, by + bh, bw + 2, 1, maroon);
            api.rect(bx - 1, by, 1, bh, maroon);
            api.rect(bx + bw, by, 1, bh, maroon);
            let won = this.winner == YOU;
            let line = api.demo ? (won ? "ALF TAKES THE FRAME" : "NELL TAKES THE FRAME") : (won ? "YOU WIN THE FRAME" : "NELL WINS THE FRAME");
            api.textCentered(by + 4, line, won ? yellow : pink, 2, maroon);
            api.textCentered(by + 18, this.overWhy, white, 1, black);
            api.textCentered(by + 27, "FRAMES " + this.frames[0].toString() + " - " + this.frames[1].toString() + "   BEST RUN " + this.best.toString(), peach, 1, black);
            if (this.t > 0.6 && !api.demo) api.textCentered(by + 37, "CLICK TO RACK THE NEXT FRAME", cyan, 1, black);
        }
    }

    legalFirst(b: i32): bool {
        let g = this.groups[this.turn];
        if (g == OPEN) return b != 8 || this.isBreak;
        if (this.remaining(g) == 0) return b == 8;
        return groupOf(b) == g;
    }

    // a row of dots: one per ball of the side's set still on the table (grey while the table is open)
    setDots(api: GameApi, side: i32, x0: f32, leftwards: bool): void {
        let g = this.groups[side];
        let c = g == SUNS ? api.paletteColor(C_YELLOW) : (g == MOONS ? api.paletteColor(C_CYAN) : api.paletteColor(C_GREY));
        let dim = api.paletteColor(C_NAVY);
        let left = g == OPEN ? 7 : this.remaining(g);
        for (let k = 0; k < 7; k++) {
            let x = leftwards ? x0 - <f32>k * 5 - 3 : x0 + <f32>k * 5;
            api.rect(x, 5, 3, 3, k < left ? c : dim);
        }
        // on the night ball: a dark dot with a pale ring
        if (g != OPEN && left == 0) {
            let x = leftwards ? x0 - 3 : x0;
            api.rect(x - 1, 4, 5, 5, api.paletteColor(C_PEACH));
            api.rect(x, 5, 3, 3, api.paletteColor(C_BLUE));
        }
    }
}
