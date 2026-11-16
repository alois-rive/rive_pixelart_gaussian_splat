// Sorting Belt: parcels drop out of the intake hopper onto a conveyor and ride to its end. Drag a
// parcel towards the chute whose sign has its colour and let go: it is flicked along the drag, into
// the chute it points at. A wrong chute spits it back out, a flick at nothing lands on the floor, a
// parcel left on the belt falls off its end: each costs one of three stamps. The belt speeds up;
// every 8 sorted parcels the chute signs swap places. One verb (drag and release), one world.
// Demo mode (api.demo) sorts by itself like a decent clerk with a few slips.
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP } from "./game_api";

const N: i32 = 18;              // parcel bones: red0-5, green0-5, cream0-5
const PER: i32 = 6;
const CLEATS: i32 = 12;
const BITS: i32 = 10;

const BELT_Y: f64 = 0.85;       // the belt's top
const BELT_Z: f64 = 0.5;        // the belt's middle (it runs along X)
const BELT_X0: f64 = -5.8;
const BELT_X1: f64 = 5.2;
const DROP_X: f64 = -5.0;       // under the intake hopper
const DROP_Y: f64 = 2.3;
const END_X: f64 = 5.1;         // past this a parcel tips off the end
const CHUTE_Z: f64 = -2.0;
const MOUTH_Y: f64 = 1.62;
const SIGN_Y: f64 = 2.16;
const SIGN_Z: f64 = -2.75;
const AIM_R: f64 = 1.0;         // how far off a chute's middle a flick still goes in (the mouth is 1.5 wide)
const GRAV: f64 = 9.0;

const S_FREE: i32 = 0;
const S_DROP: i32 = 1;
const S_RIDE: i32 = 2;
const S_FLY: i32 = 3;
const S_SINK: i32 = 4;
const S_REJECT: i32 = 5;
const S_FALL: i32 = 6;
const S_FLOOR: i32 = 7;

const M_READY: i32 = 0;
const M_PLAY: i32 = 1;
const M_OVER: i32 = 2;

function clamp(v: f64, a: f64, b: f64): f64 {
    return v < a ? a : (v > b ? b : v);
}

function chuteX(i: i32): f64 {
    return <f64>(i - 1) * 3.4;
}

export class Game {
    bones: StaticArray<i32> = new StaticArray<i32>(N);
    signs: StaticArray<i32> = new StaticArray<i32>(3);
    cleats: StaticArray<i32> = new StaticArray<i32>(CLEATS);
    bits: StaticArray<i32> = new StaticArray<i32>(BITS);
    hand: i32 = -1;

    // parcels (colour = index / PER: 0 red, 1 green, 2 cream)
    st: StaticArray<i32> = new StaticArray<i32>(N);
    px: StaticArray<f64> = new StaticArray<f64>(N);
    py: StaticArray<f64> = new StaticArray<f64>(N);
    pz: StaticArray<f64> = new StaticArray<f64>(N);
    vx: StaticArray<f64> = new StaticArray<f64>(N);
    vy: StaticArray<f64> = new StaticArray<f64>(N);
    vz: StaticArray<f64> = new StaticArray<f64>(N);
    t: StaticArray<f64> = new StaticArray<f64>(N);       // seconds in the state
    dur: StaticArray<f64> = new StaticArray<f64>(N);
    ax: StaticArray<f64> = new StaticArray<f64>(N);      // a flight's start and end
    ay: StaticArray<f64> = new StaticArray<f64>(N);
    az: StaticArray<f64> = new StaticArray<f64>(N);
    bx: StaticArray<f64> = new StaticArray<f64>(N);
    by: StaticArray<f64> = new StaticArray<f64>(N);
    bz: StaticArray<f64> = new StaticArray<f64>(N);
    tgt: StaticArray<i32> = new StaticArray<i32>(N);     // the chute a flight goes into, -1 none
    yaw: StaticArray<f64> = new StaticArray<f64>(N);
    roll: StaticArray<f64> = new StaticArray<f64>(N);
    pitch: StaticArray<f64> = new StaticArray<f64>(N);
    size: StaticArray<f64> = new StaticArray<f64>(N);
    skip: StaticArray<bool> = new StaticArray<bool>(N); // the demo clerk lets this one go
    reach: StaticArray<f64> = new StaticArray<f64>(N);   // where the demo clerk starts to want it
    seq: StaticArray<i32> = new StaticArray<i32>(N);     // spawn order

    // which chute each colour's sign hangs over
    slotOf: StaticArray<i32> = new StaticArray<i32>(3);
    nextSlot: StaticArray<i32> = new StaticArray<i32>(3);
    swapT: f64 = 9;
    swapped: bool = false;
    wiggle: StaticArray<f64> = new StaticArray<f64>(3);

    mode: i32 = M_READY;
    mt: f64 = 0;
    beltPos: f64 = 0;
    speed: f64 = 0.9;
    spawnT: f64 = 0;
    spawnN: i32 = 0;
    sorted: i32 = 0;
    score: i32 = 0;
    best: i32 = 0;
    streak: i32 = 0;
    lives: i32 = 3;
    lastColour: i32 = -1;
    shake: f64 = 0;
    shakeX: f64 = 0;
    flash: f64 = 9;

    // pointer drag
    held: i32 = -1;
    hx: f32 = 0;
    hy: f32 = 0;

    // confetti
    cx: StaticArray<f64> = new StaticArray<f64>(BITS);
    cy: StaticArray<f64> = new StaticArray<f64>(BITS);
    cz: StaticArray<f64> = new StaticArray<f64>(BITS);
    cvx: StaticArray<f64> = new StaticArray<f64>(BITS);
    cvy: StaticArray<f64> = new StaticArray<f64>(BITS);
    cvz: StaticArray<f64> = new StaticArray<f64>(BITS);
    cr: StaticArray<f64> = new StaticArray<f64>(BITS);
    ct: StaticArray<f64> = new StaticArray<f64>(BITS);
    cNext: i32 = 0;

    // pop-up words in the world
    popS: Array<string> = ["", "", "", ""];
    popC: StaticArray<i32> = new StaticArray<i32>(4);
    popX: StaticArray<f64> = new StaticArray<f64>(4);
    popY: StaticArray<f64> = new StaticArray<f64>(4);
    popZ: StaticArray<f64> = new StaticArray<f64>(4);
    popT: StaticArray<f64> = new StaticArray<f64>(4);
    popNext: i32 = 0;
    banner: string = "";
    bannerT: f64 = 9;

    // the demo clerk
    wasDemo: bool = false;
    dPhase: i32 = 0;            // 0 looking, 1 reaching for a parcel, 2 dragging, 3 resting
    dT: f64 = 0;
    dWait: f64 = 0;
    dTarget: i32 = -1;
    dAimX: f64 = 0;
    dAimZ: f64 = 0;
    dCurX: f32 = 150;
    dCurY: f32 = 110;
    dFromX: f32 = 0;
    dFromY: f32 = 0;
    dToX: f32 = 0;
    dToY: f32 = 0;

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < N; i++) {
            let c = i / PER;
            let name = c == 0 ? "red" : (c == 1 ? "green" : "cream");
            this.bones[i] = api.bone(name + (i % PER).toString());
            this.st[i] = S_FREE;
            api.hide(this.bones[i]);
        }
        this.signs[0] = api.bone("signRed");
        this.signs[1] = api.bone("signGreen");
        this.signs[2] = api.bone("signCream");
        for (let k = 0; k < CLEATS; k++) {
            this.cleats[k] = api.bone("cleat" + k.toString());
        }
        for (let k = 0; k < BITS; k++) {
            this.bits[k] = api.bone("bit" + k.toString());
            this.ct[k] = 99;
            api.hide(this.bits[k]);
        }
        this.hand = api.bone("hand");
        this.wasDemo = api.demo;
        this.newRun(api, api.demo ? M_PLAY : M_READY);
    }

    newRun(api: GameApi, mode: i32): void {
        this.mode = mode;
        this.mt = 0;
        this.speed = 0.9;
        this.sorted = 0;
        this.score = 0;
        this.streak = 0;
        this.lives = 3;
        this.held = -1;
        this.swapT = 9;
        this.bannerT = 9;
        this.flash = 9;
        this.spawnN = 0;
        this.lastColour = -1;
        for (let c = 0; c < 3; c++) {
            this.slotOf[c] = c;
            this.wiggle[c] = 9;
        }
        for (let i = 0; i < N; i++) {
            this.st[i] = S_FREE;
            api.hide(this.bones[i]);
        }
        for (let k = 0; k < 4; k++) {
            this.popT[k] = 9;
        }
        this.dPhase = 0;
        this.dT = 0;
        this.dWait = 0.1;
        this.dTarget = -1;
        if (mode == M_READY) {
            // the hint: one parcel waits on the stopped belt
            this.spawn(api, 0, -1.6, BELT_Y, S_RIDE);
            this.spawnT = 0.2;
        } else if (api.demo) {
            // the demo opens mid-shift: two parcels already riding, one dropping
            let k0 = this.spawn(api, 1, -2.2, BELT_Y, S_RIDE);
            if (k0 >= 0) {
                this.reach[k0] = -9;   // the clerk goes for it at once: action in the first second
                this.skip[k0] = false;
            }
            this.spawn(api, 0, -3.8, BELT_Y, S_RIDE);
            this.spawnT = 0.5;
        } else {
            this.spawnT = 0.0;
        }
    }

    // A free parcel of colour c (or of another colour when the pool is empty) put at x, y on the belt.
    spawn(api: GameApi, c: i32, x: f64, y: f64, state: i32): i32 {
        let k = -1;
        for (let j = 0; j < 3 && k < 0; j++) {
            let cc = (c + j) % 3;
            for (let i = cc * PER; i < cc * PER + PER; i++) {
                if (this.st[i] == S_FREE) {
                    k = i;
                    break;
                }
            }
        }
        if (k < 0) {
            return -1;
        }
        this.st[k] = state;
        this.px[k] = x;
        this.py[k] = y;
        this.pz[k] = BELT_Z + api.range(-0.12, 0.12);
        this.vy[k] = 0;
        this.t[k] = 0;
        this.yaw[k] = api.range(-12, 12);
        this.roll[k] = 0;
        this.pitch[k] = 0;
        this.size[k] = api.range(0.86, 1.0);
        this.skip[k] = api.rand() < 0.03;
        this.reach[k] = api.range(-3.6, 1.0);
        this.seq[k] = this.spawnN++;
        return k;
    }

    colourOf(i: i32): i32 {
        return i / PER;
    }

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo || api.demoChanged) {
            this.wasDemo = api.demo;
            this.best = 0;          // the visitor's best is their own, not the demo's
            this.newRun(api, api.demo ? M_PLAY : M_READY);
        }
        this.mt += dt;

        if (this.mode == M_PLAY) {
            this.speed = Math.min(2.2, 0.9 + 0.04 * <f64>this.sorted);
            this.beltPos += this.speed * dt;
            this.spawnT -= dt;
            if (this.spawnT <= 0 && this.clearUnderHopper()) {
                // colours: random, but never four of one in a row
                let c = <i32>Math.floor(api.rand() * 3) % 3;
                if (c == this.lastColour && api.rand() < 0.5) {
                    c = (c + 1 + <i32>Math.floor(api.rand() * 2)) % 3;
                }
                this.lastColour = c;
                this.spawn(api, c, DROP_X, DROP_Y, S_DROP);
                this.spawnT = Math.max(0.8, 1.9 - 0.045 * <f64>this.sorted) * api.range(0.85, 1.15);
            }
        } else if (this.mode == M_OVER) {
            if (api.demo && this.mt > 2.0) {
                this.newRun(api, M_PLAY);
            }
        }

        this.updateParcels(api, dt);
        this.updateSigns(api, dt);
        this.updateConfetti(api, dt);
        if (api.demo) {
            this.demo(api, dt);
        }
        for (let k = 0; k < 4; k++) {
            this.popT[k] += dt;
        }
        this.bannerT += dt;
        this.flash += dt;

        // the belt's cleats ride with it, round the drums
        let span = BELT_X1 - BELT_X0;
        for (let k = 0; k < CLEATS; k++) {
            let x = BELT_X0 + ((<f64>k * span / <f64>CLEATS + this.beltPos) % span);
            if (x < BELT_X0 + 0.08 || x > BELT_X1 - 0.08) {
                api.hide(this.cleats[k]);
            } else {
                api.place(this.cleats[k], x, BELT_Y, BELT_Z);
            }
        }
        // the clock: its minute hand ticks round once a minute (a second a minute: a busy shift)
        let tick = Math.floor(api.time);
        api.place(this.hand, 0, 3.75, -3.15, 0, 0, -(tick * 6 + 90) % 360);

        // shake (a life lost): whole texels, stepped at 15 fps
        this.shake = Math.max(0, this.shake - dt * 1.5);
        if (Math.floor(api.time * 15) != Math.floor((api.time - dt) * 15)) {
            this.shakeX = this.shake > 0.05 ? (api.rand() < 0.5 ? -1.0 : 1.0) * Math.round(this.shake * 3) * (8.0 / 136.0) : 0;
        }
        api.targetX = this.shakeX;
    }

    clearUnderHopper(): bool {
        for (let i = 0; i < N; i++) {
            let s = this.st[i];
            if ((s == S_DROP || s == S_RIDE) && this.px[i] < DROP_X + 1.15) {
                return false;
            }
        }
        return true;
    }

    updateParcels(api: GameApi, dt: f64): void {
        let moving = this.mode == M_PLAY;
        for (let i = 0; i < N; i++) {
            let s = this.st[i];
            let b = this.bones[i];
            if (s == S_FREE) {
                api.hide(b);
                continue;
            }
            this.t[i] += dt;
            let sx = 1.0, sy = 1.0;
            let lift = 0.0;
            if (s == S_DROP) {
                this.vy[i] -= GRAV * dt;
                this.py[i] += this.vy[i] * dt;
                if (this.py[i] <= BELT_Y) {
                    this.py[i] = BELT_Y;
                    this.st[i] = S_RIDE;
                    this.t[i] = 0;
                }
            } else if (s == S_RIDE) {
                if (moving) {
                    this.px[i] += this.speed * dt;
                }
                // landing squash after the drop, stepped
                if (this.t[i] < 0.24 && this.seq[i] > 0) {
                    let u = Math.floor(this.t[i] * 12) / 3.0;
                    let q = Math.sin(Math.min(1, u) * Math.PI) * 0.22;
                    sy = 1 - q;
                    sx = 1 + q * 0.6;
                }
                if (i == this.held) {
                    lift = 0.18 + 0.04 * Math.sin(api.time * 18);
                }
                if (this.px[i] > END_X && moving) {
                    if (i == this.held) {
                        this.held = -1;
                    }
                    if (this.dTarget == i) {
                        this.dTarget = -1;
                        this.dPhase = 0;
                    }
                    this.st[i] = S_FALL;
                    this.t[i] = 0;
                    this.vx[i] = this.speed;
                    this.vy[i] = 0.4;
                    this.lose(api, this.px[i] + 0.4, 1.4, BELT_Z, "DROPPED!");
                }
            } else if (s == S_FLY) {
                let u = clamp(this.t[i] / this.dur[i], 0, 1);
                let h = this.tgt[i] >= 0 ? 1.1 : 0.9;
                this.px[i] = this.ax[i] + (this.bx[i] - this.ax[i]) * u;
                this.pz[i] = this.az[i] + (this.bz[i] - this.az[i]) * u;
                this.py[i] = this.ay[i] + (this.by[i] - this.ay[i]) * u + h * 4 * u * (1 - u);
                this.pitch[i] = -Math.floor(u * 8) * 45;   // a stepped tumble, end over end
                if (u >= 1) {
                    this.pitch[i] = 0;
                    this.land(api, i);
                }
            } else if (s == S_SINK) {
                let u = clamp(this.t[i] / 0.28, 0, 1);
                this.py[i] = MOUTH_Y - u * 0.75;
                sx = 1 - u * 0.4;
                sy = sx;
                if (u >= 1) {
                    this.st[i] = S_FREE;
                    api.hide(b);
                    continue;
                }
            } else if (s == S_REJECT || s == S_FALL) {
                this.vy[i] -= GRAV * dt;
                this.px[i] += this.vx[i] * dt;
                this.py[i] += this.vy[i] * dt;
                this.pz[i] += this.vz[i] * dt;
                this.roll[i] -= (s == S_FALL ? 260 : 420) * dt;
                if (this.py[i] <= 0.0) {
                    this.py[i] = 0;
                    this.roll[i] = Math.round(this.roll[i] / 90) * 90;
                    this.st[i] = S_FLOOR;
                    this.t[i] = 0;
                }
            } else if (s == S_FLOOR) {
                if (this.t[i] < 0.12) {
                    sy = 0.75;
                    sx = 1.15;
                }
                if (this.t[i] > 1.4) {
                    this.st[i] = S_FREE;
                    api.hide(b);
                    continue;
                }
                if (this.t[i] > 0.9 && Math.floor(this.t[i] * 10) % 2 == 0) {
                    api.hide(b);
                    continue;
                }
            }
            let z = this.size[i];
            let rollNow = Math.floor(this.roll[i] / 30) * 30;   // stepped turns read hand-animated
            if (this.pitch[i] != 0 || rollNow != 0) {
                // turn about the parcel's middle, not its foot
                let rp = this.pitch[i] * Math.PI / 180, rr = rollNow * Math.PI / 180;
                let hgt = 0.28 * z;
                // the pivot is the foot: offset it so the box turns about its centre
                let ox = Math.sin(rr) * hgt, oy = hgt - Math.cos(rr) * Math.cos(rp) * hgt, oz = -Math.sin(rp) * Math.cos(rr) * hgt;
                api.placeScaled(b, this.px[i] + ox, this.py[i] + oy + lift, this.pz[i] - oz, this.yaw[i],
                                z * sx, z * sy, z * sx, this.pitch[i], rollNow);
            } else {
                api.placeScaled(b, this.px[i], this.py[i] + lift, this.pz[i], this.yaw[i], z * sx, z * sy, z * sx);
            }
        }
    }

    // A flight ends: into a chute (right or wrong), back on the belt, or on the floor.
    land(api: GameApi, i: i32): void {
        let c = this.tgt[i];
        if (c >= 0) {
            let colour = this.colourOf(i);
            if (this.slotOf[colour] == c) {
                this.st[i] = S_SINK;
                this.t[i] = 0;
                this.sorted++;
                this.streak++;
                let pts = 1 + this.streak / 5;
                this.score += pts;
                if (this.score > this.best) {
                    this.best = this.score;
                }
                this.wiggle[colour] = 0;
                this.burst(api, chuteX(c), MOUTH_Y + 0.2, CHUTE_Z);
                this.pop(api, chuteX(c), 2.9, CHUTE_Z, pts > 1 ? "+" + pts.toString() + " STREAK" : "+1", 4);
                if (this.sorted % 8 == 0) {
                    this.shuffle(api);
                }
            } else {
                // the wrong chute spits it back out
                this.st[i] = S_REJECT;
                this.t[i] = 0;
                this.vx[i] = api.range(-1.2, 1.2);
                this.vy[i] = 4.2;
                this.vz[i] = 1.25;
                this.lose(api, chuteX(c), 2.9, CHUTE_Z, "WRONG CHUTE!");
            }
            return;
        }
        if (this.py[i] > 0.5) {
            // back on the belt: a fumble, no harm done
            this.st[i] = S_RIDE;
            this.t[i] = 0;
            this.py[i] = BELT_Y;
            return;
        }
        this.st[i] = S_FLOOR;
        this.t[i] = 0;
        this.lose(api, this.px[i], 1.2, this.pz[i], "MISSED!");
    }

    lose(api: GameApi, x: f64, y: f64, z: f64, why: string): void {
        if (this.mode != M_PLAY) {
            return;
        }
        this.lives--;
        this.streak = 0;
        this.shake = 1.0;
        this.flash = 0;
        this.pop(api, x, y, z, why, 2);
        if (this.lives <= 0) {
            this.mode = M_OVER;
            this.mt = 0;
            this.held = -1;
            if (this.score > this.best) {
                this.best = this.score;
            }
        }
    }

    pop(api: GameApi, x: f64, y: f64, z: f64, s: string, colour: i32): void {
        let k = this.popNext;
        this.popNext = (this.popNext + 1) % 4;
        this.popS[k] = s;
        this.popC[k] = colour;
        this.popX[k] = x;
        this.popY[k] = y;
        this.popZ[k] = z;
        this.popT[k] = 0;
    }

    // Every 8 parcels the three signs trade places (never one staying put).
    shuffle(api: GameApi): void {
        let r = api.rand() < 0.5 ? 1 : 2;
        for (let c = 0; c < 3; c++) {
            this.nextSlot[c] = (this.slotOf[c] + r) % 3;
        }
        this.swapT = 0;
        this.swapped = false;
        this.banner = "THE CHUTES SWAP!";
        this.bannerT = 0;
    }

    updateSigns(api: GameApi, dt: f64): void {
        this.swapT += dt;
        // the flip: edge-on by 0.3 s, the signs trade places, face on again by 0.6 s (stepped, 12 fps)
        let turn = 0.0;
        if (this.swapT < 0.6) {
            let u = Math.floor(this.swapT * 12) / 12.0;
            turn = u < 0.3 ? u / 0.3 * 90 : (0.6 - u) / 0.3 * 90;
            if (u >= 0.3 && !this.swapped) {
                this.swapped = true;
                for (let c = 0; c < 3; c++) {
                    this.slotOf[c] = this.nextSlot[c];
                }
            }
        }
        for (let c = 0; c < 3; c++) {
            this.wiggle[c] += dt;
            let s = 1.0, lift = 0.0;
            if (this.wiggle[c] < 0.4) {
                let u = Math.floor(this.wiggle[c] * 12) / 12.0 / 0.4;
                s = 1 + 0.12 * Math.sin(u * Math.PI);
                lift = 0.12 * Math.sin(u * Math.PI);
            }
            api.place(this.signs[c], chuteX(this.slotOf[c]), SIGN_Y + lift, SIGN_Z, turn, 0, 0, s);
        }
    }

    burst(api: GameApi, x: f64, y: f64, z: f64): void {
        for (let n = 0; n < 6; n++) {
            let k = this.cNext;
            this.cNext = (this.cNext + 1) % BITS;
            this.cx[k] = x + api.range(-0.4, 0.4);
            this.cy[k] = y;
            this.cz[k] = z + api.range(-0.3, 0.3);
            this.cvx[k] = api.range(-1.8, 1.8);
            this.cvy[k] = api.range(3.0, 4.6);
            this.cvz[k] = api.range(0.2, 1.4);
            this.cr[k] = api.range(0, 360);
            this.ct[k] = 0;
        }
    }

    updateConfetti(api: GameApi, dt: f64): void {
        for (let k = 0; k < BITS; k++) {
            if (this.ct[k] > 1.1) {
                api.hide(this.bits[k]);
                continue;
            }
            this.ct[k] += dt;
            this.cvy[k] -= 7.0 * dt;
            this.cvx[k] *= Math.exp(-dt * 1.5);
            this.cx[k] += this.cvx[k] * dt;
            this.cy[k] += this.cvy[k] * dt;
            this.cz[k] += this.cvz[k] * dt;
            this.cr[k] += 400 * dt;
            if (this.cy[k] < 0.05) {
                api.hide(this.bits[k]);
                this.ct[k] = 9;
                continue;
            }
            let r = Math.floor(this.cr[k] / 45) * 45;
            api.place(this.bits[k], this.cx[k], this.cy[k], this.cz[k], r, r * 0.7, 0, 1);
        }
    }

    // The chute a flick from (x, z) along (dx, dz) goes into, or -1.
    aimChute(x: f64, z: f64, dx: f64, dz: f64): i32 {
        let len = Math.sqrt(dx * dx + dz * dz);
        if (len < 1e-6) {
            return -1;
        }
        dx /= len;
        dz /= len;
        let best = -1;
        let bestD = AIM_R;
        for (let c = 0; c < 3; c++) {
            let vx = chuteX(c) - x, vz = CHUTE_Z - z;
            let t = vx * dx + vz * dz;
            if (t <= 0.5) {
                continue;
            }
            let d = Math.abs(vx * dz - vz * dx);
            if (d < bestD) {
                bestD = d;
                best = c;
            }
        }
        return best;
    }

    // Flicks parcel i along (dx, dz) on the floor plane.
    flick(api: GameApi, i: i32, dx: f64, dz: f64): void {
        let len = Math.sqrt(dx * dx + dz * dz);
        if (len < 0.3 || this.st[i] != S_RIDE) {
            return;   // a tap, not a flick
        }
        let c = this.aimChute(this.px[i], this.pz[i], dx, dz);
        this.st[i] = S_FLY;
        this.t[i] = 0;
        this.tgt[i] = c;
        this.ax[i] = this.px[i];
        this.ay[i] = this.py[i] + 0.15;
        this.az[i] = this.pz[i];
        if (c >= 0) {
            this.bx[i] = chuteX(c);
            this.by[i] = MOUTH_Y;
            this.bz[i] = CHUTE_Z;
        } else {
            let ex = this.px[i] + dx / len * 2.4, ez = this.pz[i] + dz / len * 2.4;
            ex = clamp(ex, -6.6, 6.6);
            ez = clamp(ez, -2.9, 3.4);
            let onBelt = Math.abs(ez - BELT_Z) < 0.55 && ex > BELT_X0 + 0.4 && ex < END_X - 0.2;
            this.bx[i] = ex;
            this.bz[i] = onBelt ? BELT_Z : ez;
            this.by[i] = onBelt ? BELT_Y : 0.0;
        }
        let dist = Math.sqrt((this.bx[i] - this.ax[i]) * (this.bx[i] - this.ax[i]) + (this.bz[i] - this.az[i]) * (this.bz[i] - this.az[i]));
        this.dur[i] = 0.3 + dist * 0.045;
    }

    // ---------------------------------------------------------------- the demo clerk
    demo(api: GameApi, dt: f64): void {
        if (this.mode != M_PLAY) {
            this.dPhase = 0;
            return;
        }
        this.dT += dt;
        if (this.dPhase == 0) {
            this.dWait -= dt;
            if (this.dWait > 0) {
                return;
            }
            // the parcel nearest the end that is in reach and not given up on
            let pick = -1;
            for (let i = 0; i < N; i++) {
                if (this.st[i] == S_RIDE && this.px[i] > this.reach[i] && !this.skip[i]) {
                    if (pick < 0 || this.px[i] > this.px[pick]) {
                        pick = i;
                    }
                }
            }
            if (pick < 0) {
                this.dWait = 0.08;
                return;
            }
            this.dTarget = pick;
            this.dPhase = 1;
            this.dT = 0;
            this.dWait = api.range(0.14, 0.32) + (this.swapT < 1.2 ? 0.25 : 0);   // reach time
            this.dFromX = this.dCurX;
            this.dFromY = this.dCurY;
            // which chute: the right one mostly; a slip now and then, more just after a swap
            let colour = this.colourOf(pick);
            let slot = this.slotOf[colour];
            let slip = this.swapT < 2.0 ? 0.14 : 0.03;
            if (api.rand() < slip) {
                slot = (slot + (api.rand() < 0.5 ? 1 : 2)) % 3;
            }
            // aim: a small error mostly, a wild one about one flick in ten
            let err = api.rand() < 0.07 ? (api.rand() < 0.5 ? -1.0 : 1.0) * api.range(0.9, 1.5) : api.range(-0.35, 0.35);
            this.dAimX = chuteX(slot) + err;
            this.dAimZ = CHUTE_Z;
        } else if (this.dPhase == 1) {
            // the cursor moves onto the parcel (it keeps riding)
            let i = this.dTarget;
            if (i < 0 || this.st[i] != S_RIDE) {
                this.dPhase = 0;
                this.dWait = 0.1;
                return;
            }
            if (api.project(<f32>this.px[i], <f32>(this.py[i] + 0.3), <f32>this.pz[i])) {
                let u = <f32>clamp(this.dT / this.dWait, 0, 1);
                u = u * u * (3 - 2 * u);
                this.dCurX = this.dFromX + (api.screenX - this.dFromX) * u;
                this.dCurY = this.dFromY + (api.screenY - this.dFromY) * u;
            }
            if (this.dT >= this.dWait) {
                this.dPhase = 2;
                this.dT = 0;
                this.dWait = api.range(0.16, 0.26);   // the drag
                this.dFromX = this.dCurX;
                this.dFromY = this.dCurY;
            }
        } else if (this.dPhase == 2) {
            let i = this.dTarget;
            if (i < 0 || this.st[i] != S_RIDE) {
                this.dPhase = 0;
                this.dWait = 0.1;
                return;
            }
            // drag from the parcel a third of the way towards the aim
            let dx = this.dAimX - this.px[i], dz = this.dAimZ - this.pz[i];
            if (api.project(<f32>(this.px[i] + dx * 0.4), <f32>(this.py[i] + 0.3), <f32>(this.pz[i] + dz * 0.4))) {
                let u = <f32>clamp(this.dT / this.dWait, 0, 1);
                this.dCurX = this.dFromX + (api.screenX - this.dFromX) * u;
                this.dCurY = this.dFromY + (api.screenY - this.dFromY) * u;
            }
            if (this.dT >= this.dWait) {
                this.flick(api, i, dx, dz);
                this.dPhase = 3;
                this.dT = 0;
                this.dWait = api.range(0.15, 0.45);
                this.dTarget = -1;
            }
        } else {
            if (this.dT >= this.dWait) {
                this.dPhase = 0;
                this.dWait = 0;
            }
        }
    }

    // ---------------------------------------------------------------- the pointer
    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.mode == M_OVER) {
                if (this.mt > 0.6) {
                    this.newRun(api, M_PLAY);
                }
                return true;
            }
            if (this.mode == M_READY) {
                this.mode = M_PLAY;
                this.mt = 0;
                this.spawnT = 0.6;
            }
            // grab the parcel under the pointer (the nearest within a few pixels)
            let pick = -1;
            let bestD: f32 = 11;
            for (let i = 0; i < N; i++) {
                if (this.st[i] != S_RIDE) {
                    continue;
                }
                if (api.project(<f32>this.px[i], <f32>(this.py[i] + 0.3), <f32>this.pz[i])) {
                    let dx = api.screenX - x, dy = api.screenY - y;
                    let d = Mathf.sqrt(dx * dx + dy * dy);
                    if (d < bestD) {
                        bestD = d;
                        pick = i;
                    }
                }
            }
            this.held = pick;
            this.hx = x;
            this.hy = y;
        } else if (kind == POINTER_MOVE) {
            this.hx = x;
            this.hy = y;
        } else if (kind == POINTER_UP) {
            this.hx = x;
            this.hy = y;
            let i = this.held;
            this.held = -1;
            if (i >= 0 && this.st[i] == S_RIDE && api.pick(x, y, <f32>(this.py[i] + 0.3))) {
                this.flick(api, i, <f64>api.hitX - this.px[i], <f64>api.hitZ - this.pz[i]);
            }
        }
        return true;
    }

    // ---------------------------------------------------------------- HUD
    hud(api: GameApi): void {
        let navy = api.paletteColor(0);
        let plum = api.paletteColor(1);
        let brick = api.paletteColor(2);
        let tan = api.paletteColor(3);
        let cream = api.paletteColor(4);
        let pale = api.paletteColor(5);
        let green = api.paletteColor(6);
        let W = <f32>api.hudW;
        let H = <f32>api.hudH;

        // the aim: a dotted line from the held parcel to the pointer, and the chute it points at
        let aimI = -1;
        let ex: f32 = 0, ey: f32 = 0;
        if (this.held >= 0 && this.st[this.held] == S_RIDE) {
            aimI = this.held;
            ex = this.hx;
            ey = this.hy;
        } else if (api.demo && this.dPhase == 2 && this.dTarget >= 0) {
            aimI = this.dTarget;
            ex = this.dCurX;
            ey = this.dCurY;
        }
        if (aimI >= 0 && api.project(<f32>this.px[aimI], <f32>(this.py[aimI] + 0.45), <f32>this.pz[aimI])) {
            let sx = api.screenX, sy = api.screenY;
            let steps = <i32>Mathf.max(Mathf.abs(ex - sx), Mathf.abs(ey - sy));
            for (let k = 0; k <= steps; k += 3) {
                let u = steps > 0 ? <f32>k / <f32>steps : 0;
                api.rect(Mathf.round(sx + (ex - sx) * u), Mathf.round(sy + (ey - sy) * u), 1, 1, cream);
            }
            let ok = api.pick(ex, ey, <f32>(this.py[aimI] + 0.3));
            if (ok) {
                let c = this.aimChute(this.px[aimI], this.pz[aimI], <f64>api.hitX - this.px[aimI], <f64>api.hitZ - this.pz[aimI]);
                if (c >= 0 && api.project(<f32>chuteX(c), <f32>SIGN_Y, <f32>SIGN_Z)) {
                    // brackets round the sign it would go into
                    let bx = Mathf.round(api.screenX), by = Mathf.round(api.screenY);
                    let r: f32 = 11;
                    let col = (Math.floor(api.time * 8) % 2 == 0) ? cream : tan;
                    api.rect(bx - r, by - r, 4, 1, col); api.rect(bx - r, by - r, 1, 4, col);
                    api.rect(bx + r - 3, by - r, 4, 1, col); api.rect(bx + r, by - r, 1, 4, col);
                    api.rect(bx - r, by + r, 4, 1, col); api.rect(bx - r, by + r - 3, 1, 4, col);
                    api.rect(bx + r - 3, by + r, 4, 1, col); api.rect(bx + r, by + r - 3, 1, 4, col);
                }
            }
        }

        // pop-up words rise from where they happened
        for (let k = 0; k < 4; k++) {
            if (this.popT[k] > 1.1) {
                continue;
            }
            if (api.project(<f32>this.popX[k], <f32>(this.popY[k] + this.popT[k] * 0.9), <f32>this.popZ[k])) {
                let s = this.popS[k];
                let col = this.popC[k] == 2 ? brick : cream;
                api.text(Mathf.round(api.screenX - api.textWidth(s, 1) * 0.5), Mathf.round(api.screenY), s, col, 1, navy);
            }
        }

        // score, stamps (lives), best
        api.rect(2, 2, 62, 17, navy);
        api.text(5, 4, "SCORE " + this.score.toString(), cream, 1, 0);
        for (let k = 0; k < 3; k++) {
            let x = <f32>(5 + k * 10);
            let on = k < this.lives;
            let lostNow = !on && k == this.lives && this.flash < 0.6 && Math.floor(this.flash * 10) % 2 == 0;
            api.rect(x, 11, 8, 6, on || lostNow ? brick : plum);
            api.rect(x + 3, 11, 2, 6, on || lostNow ? cream : navy);
            api.rect(x, 13, 8, 2, on || lostNow ? cream : navy);
        }
        if (this.streak >= 3 && this.mode == M_PLAY) {
            api.text(37, 12, "X" + this.streak.toString(), tan, 1, 0);
        }
        let bs = "BEST " + this.best.toString();
        let bw = api.textWidth(bs, 1);
        api.rect(W - bw - 8, 2, bw + 6, 9, navy);
        api.text(W - bw - 5, 4, bs, tan, 1, 0);

        if (this.bannerT < 1.6 && this.mode == M_PLAY) {
            if (Math.floor(this.bannerT * 6) % 2 == 0 || this.bannerT > 0.6) {
                api.textCentered(24, this.banner, cream, 1, navy);
            }
        }

        if (this.mode == M_READY) {
            let y = H - 26;
            api.rect(18, y - 3, W - 36, 21, navy);
            api.textCentered(y, "DRAG EACH PARCEL TO THE CHUTE", cream, 1, 0);
            api.textCentered(y + 9, "WITH ITS COLOUR, THEN LET GO", pale, 1, 0);
        }
        if (api.demo) {
            api.textCentered(H - 9, "DEMO", tan, 1, navy);
        }

        if (this.mode == M_OVER) {
            let y: f32 = 40;
            api.rect(46, y - 5, W - 92, 50, navy);
            api.rect(46, y - 5, W - 92, 1, tan);
            api.rect(46, y + 44, W - 92, 1, tan);
            api.textCentered(y, "SHIFT OVER", cream, 2, plum);
            api.textCentered(y + 15, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), tan, 1, 0);
            if (!api.demo && this.mt > 0.6) {
                api.textCentered(y + 26, "CLICK TO SORT AGAIN", pale, 1, 0);
            }
        }

        // the demo's hand: an arrow cursor
        if (api.demo && this.mode == M_PLAY) {
            let x = Mathf.round(this.dCurX), y = Mathf.round(this.dCurY);
            let grab = this.dPhase == 2;
            for (let r = 0; r < 7; r++) {
                let w = <f32>(r < 5 ? r + 1 : 7 - r);
                api.rect(x - 1, y + <f32>r - 1, w + 2, 1, navy);
            }
            for (let r = 0; r < 6; r++) {
                let w = <f32>(r < 5 ? r : 6 - r);
                if (w > 0) {
                    api.rect(x, y + <f32>r, w, 1, grab ? pale : cream);
                }
            }
            if (grab) {
                api.rect(x - 1, y - 1, 1, 1, green);
            }
        }
    }
}
