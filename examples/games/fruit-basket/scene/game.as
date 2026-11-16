// Fruit Basket: move the cart under the orchard and catch the falling fruit; rotten apples cost a
// life, and so does a good fruit that hits the ground. Three lives. The pointer's x steers the cart
// (move, or press and drag on touch); a click starts a run and, after a game over, the next one.
//
// Everything here drives game bones baked by scene.bake.json ("bone" / "copies"): the cart and its
// wheels, three tree canopies (they shake before a fruit drops), fruit pools per kind and a pool of
// sparks. Deterministic: api.rand() only.
import { GameApi, POINTER_DOWN } from "./game_api";

// ramps in art/palette.json order
const R_LEAF: i32 = 1;
const R_WOOD: i32 = 2;
const R_RED: i32 = 3;
const R_ORANGE: i32 = 4;
const R_PEAR: i32 = 5;
const R_PLUM: i32 = 6;
const R_ROT: i32 = 7;
const R_BLUE: i32 = 8;
const R_STONE: i32 = 9;

// fruit kinds
const APPLE: i32 = 0;
const ORANGE: i32 = 1;
const PLUM: i32 = 2;
const PEAR: i32 = 3;
const ROTTEN: i32 = 4;

// fruit states
const FREE: i32 = 0;
const HANG: i32 = 1;    // grows on the branch, then wobbles (the anticipation)
const FALL: i32 = 2;
const CAUGHT: i32 = 3;  // drops into the cart and vanishes
const GROUND: i32 = 4;  // splats on the ground, fades

// run modes
const IDLE: i32 = 0;    // the hint, before the first click
const PLAY: i32 = 1;
const OVER: i32 = 2;

const LANE_Z: f64 = 0.3;      // where the cart rolls and the fruit falls
const CART_Y: f64 = 0.0;
const RIM_Y: f64 = 0.86;      // the cart's rim: a fruit crossing it over the tray is caught
const HALF_W: f64 = 0.74;     // half the tray's catching width
const GROUND_Y: f64 = 0.24;   // a fruit's centre when it lies on the grass
const X_MIN: f64 = -4.3;
const X_MAX: f64 = 4.3;
const WHEEL_R: f64 = 0.32;
const MAX_FRUIT: i32 = 19;
const MAX_SPARK: i32 = 8;
const MAX_POP: i32 = 8;

export class Game {
    // bones
    cart: i32 = -1;
    wheels: i32 = -1;
    canopy: StaticArray<i32> = new StaticArray<i32>(3);
    canopyShake: StaticArray<f64> = new StaticArray<f64>(3);

    // fruit pool
    fBone: StaticArray<i32> = new StaticArray<i32>(MAX_FRUIT);
    fKind: StaticArray<i32> = new StaticArray<i32>(MAX_FRUIT);
    fState: StaticArray<i32> = new StaticArray<i32>(MAX_FRUIT);
    fX: StaticArray<f64> = new StaticArray<f64>(MAX_FRUIT);
    fY: StaticArray<f64> = new StaticArray<f64>(MAX_FRUIT);
    fVY: StaticArray<f64> = new StaticArray<f64>(MAX_FRUIT);
    fT: StaticArray<f64> = new StaticArray<f64>(MAX_FRUIT);
    fHang: StaticArray<f64> = new StaticArray<f64>(MAX_FRUIT);
    fSpin: StaticArray<f64> = new StaticArray<f64>(MAX_FRUIT);
    fTree: StaticArray<i32> = new StaticArray<i32>(MAX_FRUIT);
    nFruit: i32 = 0;

    // sparks
    sBone: StaticArray<i32> = new StaticArray<i32>(MAX_SPARK);
    sX: StaticArray<f64> = new StaticArray<f64>(MAX_SPARK);
    sY: StaticArray<f64> = new StaticArray<f64>(MAX_SPARK);
    sZ: StaticArray<f64> = new StaticArray<f64>(MAX_SPARK);
    sVX: StaticArray<f64> = new StaticArray<f64>(MAX_SPARK);
    sVY: StaticArray<f64> = new StaticArray<f64>(MAX_SPARK);
    sLife: StaticArray<f64> = new StaticArray<f64>(MAX_SPARK);
    sNext: i32 = 0;

    // floating score texts
    pText: Array<string> = new Array<string>(MAX_POP);
    pX: StaticArray<f64> = new StaticArray<f64>(MAX_POP);
    pY: StaticArray<f64> = new StaticArray<f64>(MAX_POP);
    pLife: StaticArray<f64> = new StaticArray<f64>(MAX_POP);
    pRamp: StaticArray<i32> = new StaticArray<i32>(MAX_POP);
    pNext: i32 = 0;

    // the run
    mode: i32 = IDLE;
    score: i32 = 0;
    best: i32 = 0;
    bestDemo: i32 = 0;   // the demo's own best, so a visitor's best starts clean
    lives: i32 = 3;
    runTime: f64 = 0;
    overTime: f64 = 0;
    spawnIn: f64 = 0.3;
    caughtCount: i32 = 0;
    wasDemo: bool = false;
    hurtTime: f64 = 9;
    lifeLostAt: f64 = -9;

    // the cart
    cartX: f64 = 0;
    cartV: f64 = 0;
    targetX: f64 = 0;
    squash: f64 = 0;      // a damped bounce after a catch
    squashT: f64 = 9;
    shakeT: f64 = 9;      // a shudder after a rotten apple
    roll: f64 = 0;

    // the demo player
    aiNext: f64 = 0;
    aiAim: f64 = 0;
    aiErr: f64 = 0;
    aiSkip: i32 = -1;

    start(api: GameApi): void {
        api.playable = true;
        this.cart = api.bone("cart");
        this.wheels = api.bone("wheels");
        this.canopy[0] = api.bone("canopyL");
        this.canopy[1] = api.bone("canopyM");
        this.canopy[2] = api.bone("canopyR");
        let n = 0;
        n = this.addPool(api, "apple", 6, APPLE, n);
        n = this.addPool(api, "orange", 3, ORANGE, n);
        n = this.addPool(api, "plum", 3, PLUM, n);
        n = this.addPool(api, "pear", 2, PEAR, n);
        n = this.addPool(api, "rotten", 5, ROTTEN, n);
        this.nFruit = n;
        for (let i = 0; i < MAX_SPARK; i++) {
            this.sBone[i] = api.bone("spark" + i.toString());
            this.sLife[i] = 0;
            api.hide(this.sBone[i]);
        }
        for (let i = 0; i < MAX_POP; i++) {
            this.pText[i] = "";
            this.pLife[i] = 0;
        }
        for (let i = 0; i < this.nFruit; i++) {
            this.fState[i] = FREE;
            api.hide(this.fBone[i]);
        }
        this.wasDemo = api.demo;
        if (api.demo) {
            this.newRun(api);
            this.seedOpening(api);
            this.spawnIn = 0.6;
        } else {
            this.decorate(api);
        }
    }

    private addPool(api: GameApi, name: string, count: i32, kind: i32, n: i32): i32 {
        for (let i = 0; i < count; i++) {
            this.fBone[n] = api.bone(name + i.toString());
            this.fKind[n] = kind;
            n++;
        }
        return n;
    }

    // ------------------------------------------------------------------ the run

    private newRun(api: GameApi): void {
        this.mode = PLAY;
        this.score = 0;
        this.lives = 3;
        this.runTime = 0;
        this.caughtCount = 0;
        this.overTime = 0;
        // fruit already hanging stays and falls in turn, one after another: the world goes on, and
        // a new run opens gently
        let k = 0;
        for (let i = 0; i < this.nFruit; i++) {
            if (this.fState[i] == HANG) {
                this.fT[i] = 0;
                this.fHang[i] = 1.0 + 1.4 * <f64>k;
                k++;
            }
        }
        this.spawnIn = 1.0 + 1.4 * <f64>k;
    }

    // a couple of fruits already on the move so a demo shows action in its first second
    private seedOpening(api: GameApi): void {
        let a = this.spawn(api, APPLE, 1.6, 0);
        if (a >= 0) {
            this.fState[a] = FALL;
            this.fY[a] = 1.9;
            this.fVY[a] = -1.0;
        }
        let b = this.spawn(api, ORANGE, -2.6, 0);
        if (b >= 0) {
            this.fT[b] = 0.2;
        }
    }

    // the idle orchard: a few fruits ripen and wobble, nothing falls
    private decorate(api: GameApi): void {
        this.spawn(api, APPLE, -2.9, 0);
        this.spawn(api, PEAR, 0.6, 0);
        this.spawn(api, PLUM, 3.1, 0);
    }

    private gameOver(api: GameApi): void {
        this.mode = OVER;
        this.overTime = 0;
        if (api.demo) {
            this.bestDemo = max<i32>(this.bestDemo, this.score);
        } else {
            this.best = max<i32>(this.best, this.score);
        }
    }

    // ------------------------------------------------------------------ spawning

    private freeSlot(kind: i32): i32 {
        for (let i = 0; i < this.nFruit; i++) {
            if (this.fKind[i] == kind && this.fState[i] == FREE) {
                return i;
            }
        }
        return -1;
    }

    private treeOf(x: f64): i32 {
        return x < -1.7 ? 0 : (x > 1.7 ? 2 : 1);
    }

    private spawn(api: GameApi, kind: i32, x: f64, hang: f64): i32 {
        let i = this.freeSlot(kind);
        if (i < 0) {
            i = this.freeSlot(APPLE);
            if (i < 0) {
                return -1;
            }
        }
        this.fState[i] = HANG;
        this.fX[i] = x;
        let tree = this.treeOf(x);
        let cx = tree == 0 ? -3.4 : (tree == 2 ? 3.4 : 0.0);
        let dx = Math.abs(x - cx);
        this.fY[i] = 2.05 + dx * 0.22 + api.range(0, 0.25);
        this.fVY[i] = 0;
        this.fT[i] = 0;
        this.fHang[i] = hang > 0 ? hang : 0.9;
        this.fSpin[i] = api.range(-30, 30);
        this.fTree[i] = tree;
        return i;
    }

    private spawnRandom(api: GameApi): void {
        let level = Math.min(1.0, this.runTime / 50.0);
        let r = api.rand();
        let kind = APPLE;
        let rottenP = 0.17 + 0.15 * level;
        if (r < rottenP) {
            kind = ROTTEN;
        } else if (r < rottenP + 0.05) {
            kind = PEAR;
        } else if (r < rottenP + 0.2) {
            kind = PLUM;
        } else if (r < rottenP + 0.4) {
            kind = ORANGE;
        }
        // not straight above a fruit that is already falling there
        let x = api.range(X_MIN + 0.2, X_MAX - 0.2);
        for (let tries = 0; tries < 4; tries++) {
            let clash = false;
            for (let i = 0; i < this.nFruit; i++) {
                if ((this.fState[i] == HANG || this.fState[i] == FALL) && Math.abs(this.fX[i] - x) < 0.5) {
                    clash = true;
                }
            }
            if (!clash) {
                break;
            }
            x = api.range(X_MIN + 0.2, X_MAX - 0.2);
        }
        let hang = 0.95 - 0.45 * level + api.range(0, 0.3);
        this.spawn(api, kind, x, hang);
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        // demo switched off by a visitor: a fresh run, theirs
        if (this.wasDemo && !api.demo) {
            this.newRun(api);
        }
        this.wasDemo = api.demo;

        if (this.mode == PLAY) {
            this.runTime += dt;
            let level = Math.min(1.0, this.runTime / 50.0);
            this.spawnIn -= dt;
            if (this.spawnIn <= 0) {
                this.spawnRandom(api);
                this.spawnIn = (1.1 - 0.5 * level) * api.range(0.75, 1.25);
            }
        } else if (this.mode == OVER) {
            this.overTime += dt;
            if (api.demo && this.overTime > 2.0) {
                this.newRun(api);
            }
        } else {
            // idle: keep a few fruits ripening on the branches
            let hanging = 0;
            for (let i = 0; i < this.nFruit; i++) {
                if (this.fState[i] == HANG) {
                    hanging++;
                }
            }
            if (hanging == 0) {
                this.decorate(api);
            }
        }

        if (api.demo && this.mode == PLAY) {
            this.think(api);
        }
        this.moveCart(api, dt);
        this.moveFruit(api, dt);
        this.moveSparks(api, dt);
        this.shakeTrees(api, dt);
        for (let i = 0; i < MAX_POP; i++) {
            if (this.pLife[i] > 0) {
                this.pLife[i] -= dt;
                this.pY[i] += dt * 0.9;
            }
        }
        this.hurtTime += dt;
    }

    private moveCart(api: GameApi, dt: f64): void {
        // a stiff spring towards the target, capped speed: the cart has weight but answers at once
        let tx = Math.max(X_MIN, Math.min(X_MAX, this.targetX));
        let acc = (tx - this.cartX) * 90.0 - this.cartV * 17.0;
        this.cartV += acc * dt;
        let vmax = 8.5;
        this.cartV = Math.max(-vmax, Math.min(vmax, this.cartV));
        this.cartX += this.cartV * dt;
        // lean into the motion, stepped to whole degrees so it reads hand-animated
        let lean = Math.max(-7.0, Math.min(7.0, -acc * 0.06));
        this.roll += (lean - this.roll) * Math.min(1.0, dt * 10.0);
        this.squashT += dt;
        this.shakeT += dt;
        let s = 0.0;
        if (this.squashT < 0.6) {
            s = this.squash * Math.exp(-this.squashT * 7.0) * Math.cos(this.squashT * 26.0);
        }
        let shake = 0.0;
        if (this.shakeT < 0.45) {
            shake = Math.sin(this.shakeT * 60.0) * 0.08 * (1.0 - this.shakeT / 0.45);
        }
        let x = this.cartX + shake;
        let rollDeg = Math.round(this.roll) + shake * 60.0;
        this.placeCart(api, this.cart, x, CART_Y, LANE_Z, rollDeg, 1.0 + s * 0.5, 1.0 - s, 1.0 + s * 0.5);
        // wheels roll with the distance travelled
        let wheelDeg = -(this.cartX / WHEEL_R) * 180.0 / Math.PI;
        api.place(this.wheels, x, 0.32 - s * 0.1, LANE_Z, 0, 0, Math.round(wheelDeg / 15.0) * 15.0);
    }

    // T(x,y,z) * Rz(roll) * S(sx,sy,sz) * T(-pivot): a lean and a squash about the cart's foot
    // (GameApi's placeScaled has no roll, place has no per-axis scale)
    private placeCart(api: GameApi, b: i32, x: f64, y: f64, z: f64, rollDeg: f64, sx: f64, sy: f64, sz: f64): void {
        if (b <= 0) {
            return;
        }
        let r = rollDeg * Math.PI / 180.0;
        let c = Math.cos(r), s = Math.sin(r);
        let px = <f64>api.restX[b], py = <f64>api.restY[b], pz = <f64>api.restZ[b];
        let a00 = c * sx, a01 = -s * sy, a10 = s * sx, a11 = c * sy, a22 = sz;
        let m = b * 12;
        api.mats[m] = <f32>a00; api.mats[m + 1] = <f32>a01; api.mats[m + 2] = 0;
        api.mats[m + 3] = <f32>(x - (a00 * px + a01 * py));
        api.mats[m + 4] = <f32>a10; api.mats[m + 5] = <f32>a11; api.mats[m + 6] = 0;
        api.mats[m + 7] = <f32>(y - (a10 * px + a11 * py));
        api.mats[m + 8] = 0; api.mats[m + 9] = 0; api.mats[m + 10] = <f32>a22;
        api.mats[m + 11] = <f32>(z - a22 * pz);
        api.dirty[b] = true;
        api.anyDirty = true;
    }

    private moveFruit(api: GameApi, dt: f64): void {
        let level = Math.min(1.0, this.runTime / 50.0);
        let g = 7.0 + 6.0 * level;
        for (let i = 0; i < this.nFruit; i++) {
            let st = this.fState[i];
            if (st == FREE) {
                continue;
            }
            let b = this.fBone[i];
            this.fT[i] += dt;
            let t = this.fT[i];
            if (st == HANG) {
                // pop in, then wobble harder and harder: the anticipation before the drop
                let grow = Math.min(1.0, t / 0.18);
                let pop = grow < 1.0 ? grow * 1.25 : 1.0 + 0.25 * Math.max(0.0, 1.0 - (t - 0.18) / 0.12);
                let hang = this.fHang[i];
                let w = 0.0;
                if (t > hang * 0.35) {
                    let k = (t - hang * 0.35) / (hang * 0.65);
                    w = Math.sin(t * 34.0) * 14.0 * k;
                    this.canopyShake[this.fTree[i]] = Math.max(this.canopyShake[this.fTree[i]], k);
                }
                // hanging fruit stretches a little on its stalk just before letting go
                let stretch = t > hang * 0.8 ? 1.0 + 0.12 * (t - hang * 0.8) / (hang * 0.2) : 1.0;
                api.placeScaled(b, this.fX[i], this.fY[i], LANE_Z, this.fSpin[i] + w, pop / Math.sqrt(stretch), pop * stretch, pop / Math.sqrt(stretch));
                if (t >= hang && this.mode == PLAY) {
                    this.fState[i] = FALL;
                    this.fT[i] = 0;
                    this.fVY[i] = 0.0;
                }
                if (t >= hang && this.mode != PLAY) {
                    this.fT[i] = hang * 0.2; // idle orchard: ripen again, never fall
                }
            } else if (st == FALL) {
                let oldY = this.fY[i];
                this.fVY[i] -= g * dt;
                this.fY[i] += this.fVY[i] * dt;
                this.fSpin[i] += dt * 200.0;
                // stretched along the fall
                let v = Math.min(1.0, -this.fVY[i] / 9.0);
                let sy = 1.0 + 0.22 * v;
                let sx = 1.0 / Math.sqrt(sy);
                // the catch: crossing the rim over the tray
                if (oldY >= RIM_Y && this.fY[i] < RIM_Y && Math.abs(this.fX[i] - this.cartX) < HALF_W && this.mode == PLAY) {
                    this.catchFruit(api, i);
                    continue;
                }
                if (this.fY[i] <= GROUND_Y) {
                    this.fY[i] = GROUND_Y;
                    this.fState[i] = GROUND;
                    this.fT[i] = 0;
                    this.dropped(api, i);
                    continue;
                }
                api.placeScaled(b, this.fX[i], this.fY[i], LANE_Z, Math.round(this.fSpin[i] / 30.0) * 30.0, sx, sy, sx);
            } else if (st == CAUGHT) {
                // sinks into the tray and is gone
                this.fY[i] -= dt * 2.2;
                let fx = this.fX[i] - (this.cartX - this.fX[i]) * 0.0;
                if (t > 0.18) {
                    this.fState[i] = FREE;
                    api.hide(b);
                } else {
                    let k = 1.0 - t / 0.18;
                    api.placeScaled(b, fx + (this.cartX - fx) * 0.3, this.fY[i], LANE_Z, this.fSpin[i], k, k, k);
                }
            } else if (st == GROUND) {
                // a squashed splat (good fruit) or a bounce (rotten) that fades away
                if (t > 0.9) {
                    this.fState[i] = FREE;
                    api.hide(b);
                } else {
                    let sq = this.fKind[i] == ROTTEN ? 0.75 : 0.45;
                    let k = Math.min(1.0, t / 0.08);
                    let sy = 1.0 - (1.0 - sq) * k * Math.exp(-t * 2.0);
                    let sx = 1.0 + (1.0 - sy) * 0.9;
                    let blink = t > 0.55 && Math.floor(t * 14.0) % 2.0 == 0.0;
                    if (blink) {
                        api.hide(b);
                    } else {
                        api.placeScaled(b, this.fX[i], GROUND_Y * sy, LANE_Z, this.fSpin[i], sx, sy, sx);
                    }
                }
            }
        }
    }

    private catchFruit(api: GameApi, i: i32): void {
        this.fState[i] = CAUGHT;
        this.fT[i] = 0;
        let kind = this.fKind[i];
        if (kind == ROTTEN) {
            this.lives--;
            this.shakeT = 0;
            this.hurtTime = 0;
            this.lifeLostAt = api.time;
            this.pop(api, "YUCK!", this.fX[i], RIM_Y + 0.4, R_PLUM);
            this.burst(api, this.fX[i], RIM_Y + 0.1, 3);
            if (this.lives <= 0) {
                this.gameOver(api);
            }
            return;
        }
        let pts = kind == PEAR ? 5 : (kind == PLUM ? 2 : 1);
        this.score += pts;
        this.caughtCount++;
        this.squash = kind == PEAR ? 0.3 : 0.2;
        this.squashT = 0;
        let ramp = kind == PEAR ? R_PEAR : (kind == PLUM ? R_PLUM : (kind == ORANGE ? R_ORANGE : R_RED));
        this.pop(api, "+" + pts.toString(), this.fX[i], RIM_Y + 0.45, ramp);
        this.burst(api, this.fX[i], RIM_Y + 0.1, kind == PEAR ? 8 : 4);
    }

    private dropped(api: GameApi, i: i32): void {
        if (this.mode != PLAY) {
            return;
        }
        if (this.fKind[i] == ROTTEN) {
            return; // dodged
        }
        this.lives--;
        this.hurtTime = 0;
        this.lifeLostAt = api.time;
        this.pop(api, "SPLAT", this.fX[i], 0.8, R_RED);
        if (this.lives <= 0) {
            this.gameOver(api);
        }
    }

    private pop(api: GameApi, text: string, x: f64, y: f64, ramp: i32): void {
        let k = this.pNext;
        this.pNext = (this.pNext + 1) % MAX_POP;
        this.pText[k] = text;
        this.pX[k] = x;
        this.pY[k] = y;
        this.pLife[k] = 0.9;
        this.pRamp[k] = ramp;
    }

    private burst(api: GameApi, x: f64, y: f64, n: i32): void {
        for (let j = 0; j < n; j++) {
            let k = this.sNext;
            this.sNext = (this.sNext + 1) % MAX_SPARK;
            let a = (<f64>j + api.range(0, 0.6)) / <f64>n * Math.PI + 0.1;
            let sp = api.range(2.0, 3.2);
            this.sX[k] = x;
            this.sY[k] = y;
            this.sZ[k] = LANE_Z + 0.25;
            this.sVX[k] = Math.cos(a) * sp;
            this.sVY[k] = Math.sin(a) * sp + 1.0;
            this.sLife[k] = api.range(0.35, 0.5);
        }
    }

    private moveSparks(api: GameApi, dt: f64): void {
        for (let k = 0; k < MAX_SPARK; k++) {
            let b = this.sBone[k];
            if (this.sLife[k] <= 0) {
                continue;
            }
            this.sLife[k] -= dt;
            if (this.sLife[k] <= 0) {
                api.hide(b);
                continue;
            }
            this.sVY[k] -= 9.0 * dt;
            this.sX[k] += this.sVX[k] * dt;
            this.sY[k] += this.sVY[k] * dt;
            let s = Math.min(1.0, this.sLife[k] / 0.25);
            api.place(b, this.sX[k], this.sY[k], this.sZ[k], 0, 0, 0, s);
        }
    }

    private shakeTrees(api: GameApi, dt: f64): void {
        for (let t = 0; t < 3; t++) {
            let b = this.canopy[t];
            let k = this.canopyShake[t];
            if (k > 0.01) {
                let w = Math.sin(api.time * 38.0 + <f64>t) * k;
                api.place(b, <f64>api.restX[b] + w * 0.05, <f64>api.restY[b] + Math.abs(w) * 0.02, <f64>api.restZ[b],
                    <f64>api.restYaw[b] + w * 2.5);
            } else {
                api.reset(b);
            }
            this.canopyShake[t] = Math.max(0.0, k - dt * 3.0);
        }
    }

    // ------------------------------------------------------------------ the demo player

    // Aims at the good fruit that lands first, a beat late and a little off, steps aside from rotten
    // apples, and now and then lets one go: a decent human, not a machine.
    private think(api: GameApi): void {
        if (api.time < this.aiNext) {
            return;
        }
        this.aiNext = api.time + api.range(0.12, 0.24);
        let bestT = 1e9;
        let bestX = this.aiAim;
        let found = false;
        let level = Math.min(1.0, this.runTime / 50.0);
        let g = 7.0 + 6.0 * level;
        for (let i = 0; i < this.nFruit; i++) {
            let st = this.fState[i];
            if (this.fKind[i] == ROTTEN || i == this.aiSkip) {
                continue;
            }
            let tl = 0.0;
            if (st == FALL) {
                // time to reach the rim: y + v t - g t^2 / 2 = RIM_Y
                let v = -this.fVY[i];
                let h = this.fY[i] - RIM_Y;
                if (h < 0) {
                    continue;
                }
                tl = (-v + Math.sqrt(v * v + 2.0 * g * h)) / g;
            } else if (st == HANG) {
                let h = this.fY[i] - RIM_Y;
                tl = Math.max(0.0, this.fHang[i] - this.fT[i]) + Math.sqrt(2.0 * h / g);
            } else {
                continue;
            }
            // can the cart get there? prefer the soonest reachable one
            let reach = Math.abs(this.fX[i] - this.cartX) / 7.0;
            if (reach > tl + 0.1 && st == FALL) {
                continue;
            }
            if (tl < bestT) {
                bestT = tl;
                bestX = this.fX[i];
                found = true;
            }
        }
        if (found && Math.abs(bestX - this.aiAim) > 0.3) {
            // a new aim: a fresh error, and once in a while a lapse that lets this one fall
            this.aiErr = api.range(-0.5, 0.5);
            if (api.rand() < 0.12) {
                this.aiErr = api.rand() < 0.5 ? -1.3 : 1.3;
            }
        }
        let aim = found ? bestX + this.aiErr : this.aiAim * 0.9;
        // a rotten apple about to land in the tray: step aside (most of the time)
        for (let i = 0; i < this.nFruit; i++) {
            if (this.fKind[i] != ROTTEN || this.fState[i] != FALL) {
                continue;
            }
            let h = this.fY[i] - RIM_Y;
            if (h > 0 && h < 1.4 && Math.abs(this.fX[i] - aim) < HALF_W + 0.25 && api.rand() < 0.85) {
                aim = this.fX[i] + (aim < this.fX[i] ? -1.0 : 1.0) * (HALF_W + 0.45);
            }
        }
        this.aiAim = aim;
        this.targetX = aim;
    }

    // ------------------------------------------------------------------ input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (api.pick(x, y, <f32>0.5)) {
            this.targetX = <f64>api.hitX;
        }
        if (kind == POINTER_DOWN) {
            if (this.mode == IDLE) {
                this.newRun(api);
            } else if (this.mode == OVER && this.overTime > 0.6) {
                this.newRun(api);
            }
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let ink = api.rampColor(R_ROT, 1);       // #352b42, the shadow under every text
        let cream = api.rampColor(R_STONE, 5);   // #f2f0e5
        let gold = api.rampColor(R_PEAR, 2);     // #ede19e
        let W = <f32>api.hudW;
        let H = <f32>api.hudH;

        // score and best, top left
        api.text(6, 5, "SCORE " + this.score.toString(), cream, 2, ink);
        let best = api.demo ? this.bestDemo : this.best;
        api.text(6, 19, "BEST " + best.toString(), gold, 1, ink);

        // lives: three little apples, top right; a lost one turns rotten grey
        for (let i = 0; i < 3; i++) {
            let x = W - 12.0 - <f32>(2 - i) * 11.0;
            let alive = i < this.lives;
            let flash = !alive && i == this.lives && this.hurtTime < 0.6 && Math.floor(this.hurtTime * 10.0) % 2.0 == 0.0;
            this.apple(api, x, 6, alive || flash ? api.rampColor(R_RED, 2) : api.rampColor(R_ROT, 3),
                alive || flash ? api.rampColor(R_RED, 3) : api.rampColor(R_ROT, 4), ink);
        }

        // floating score texts
        for (let i = 0; i < MAX_POP; i++) {
            if (this.pLife[i] <= 0) {
                continue;
            }
            if (api.project(<f32>this.pX[i], <f32>this.pY[i], <f32>LANE_Z)) {
                let s = this.pText[i];
                let w = api.textWidth(s, 1);
                let c = api.rampColor(this.pRamp[i], 3);
                api.text(Mathf.round(api.screenX - w * 0.5), Mathf.round(api.screenY), s, c, 1, ink);
            }
        }

        if (this.mode == IDLE) {
            let blink = Math.floor(api.time * 2.0) % 2.0 == 0.0;
            api.textCentered(H - 40.0, "MOVE THE CART: CATCH THE FRUIT", cream, 1, ink);
            api.textCentered(H - 31.0, "DODGE THE ROTTEN APPLES", api.rampColor(R_ROT, 4), 1, ink);
            if (blink) {
                api.textCentered(H - 20.0, "CLICK TO START", gold, 2, ink);
            }
        } else if (this.mode == OVER) {
            api.rect(0, H * 0.5 - 30.0, W, 50, ink);
            api.textCentered(H * 0.5 - 24.0, "GAME OVER", cream, 3, 0);
            api.textCentered(H * 0.5 - 4.0, "SCORE " + this.score.toString() + "   BEST " + best.toString(), gold, 1, 0);
            if (this.overTime > 0.6 && Math.floor(this.overTime * 2.0) % 2.0 == 0.0) {
                api.textCentered(H * 0.5 + 8.0, api.demo ? "DEMO" : "CLICK TO PLAY AGAIN", api.rampColor(R_BLUE, 4), 1, 0);
            }
        } else if (this.runTime < 2.5 && !api.demo) {
            api.textCentered(H - 16.0, "MOVE TO CATCH - 3 LIVES", cream, 1, ink);
        }
        if (api.demo && this.mode != OVER) {
            api.text(W - 22.0, H - 9.0, "DEMO", api.rampColor(R_BLUE, 4), 1, ink);
        }
    }

    // a 7 x 7 pixel apple with a stalk: the lives
    private apple(api: GameApi, x: f32, y: f32, body: u32, light: u32, ink: u32): void {
        api.rect(x + 1, y + 2, 7, 6, ink);
        api.rect(x, y + 1, 7, 5, body);
        api.rect(x + 1, y + 6, 5, 1, body);
        api.rect(x + 1, y + 2, 2, 2, light);
        api.rect(x + 3, y - 1, 1, 2, api.rampColor(R_WOOD, 1));
        api.rect(x + 4, y - 1, 2, 1, api.rampColor(R_LEAF, 3));
    }
}
