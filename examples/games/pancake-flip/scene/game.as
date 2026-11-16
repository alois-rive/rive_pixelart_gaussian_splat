// Pancake Flip: three pans on a pastel stove, each cooking a pancake from pale batter to golden to
// browned to burnt. Click a pan to flip its pancake: golden is perfect (+3), browned is fine (+1),
// raw flops (0). A pancake left to burn is a strike; three strikes and the kitchen closes. Served
// pancakes stack up on the plate. Pointer only; a run starts on the first click; demo plays itself.
import { GameApi, POINTER_DOWN } from "./game_api";

const ST_IDLE: i32 = 0;
const ST_PLAY: i32 = 1;
const ST_OVER: i32 = 2;

// pan states
const P_EMPTY: i32 = 0;   // waiting for batter
const P_POUR: i32 = 1;    // batter spreads in
const P_COOK: i32 = 2;    // cooking: raw -> golden -> browned -> burnt
const P_FLIP: i32 = 3;    // in the air
const P_SERVE: i32 = 4;   // hopping onto the plate
const P_FLOP: i32 = 5;    // a raw flop or a burnt one: it shrinks away

// looks (bone sets)
const L_RAW: i32 = 0;
const L_GOLD: i32 = 1;
const L_DARK: i32 = 2;
const L_BURNT: i32 = 3;

const NPAN: i32 = 3;
const NSTACK: i32 = 10;
const NSMOKE: i32 = 6;
const NSTAR: i32 = 6;
const PAN_Y: f64 = 0.05;
const CAKE_Y: f64 = 0.1;
const PLATE_X: f64 = -2.35;
const PLATE_Z: f64 = 0.1;
const STACK_DY: f64 = 0.055;
const POUR_T: f64 = 0.35;
const FLIP_T: f64 = 0.72;

// palette indices (art/palette.json "colors")
const C_INK: i32 = 0;
const C_MAUVE: i32 = 1;
const C_OAT: i32 = 2;
const C_CORAL: i32 = 3;
const C_LILAC: i32 = 4;
const C_APRICOT: i32 = 13;
const C_MILK: i32 = 15;

export class Game {
    state: i32 = ST_IDLE;
    stateT: f64 = 0;
    runT: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    strikes: i32 = 0;
    served: i32 = 0;
    wasDemo: bool = false;

    panBone: StaticArray<i32> = new StaticArray<i32>(NPAN);
    lookBone: StaticArray<i32> = new StaticArray<i32>(NPAN * 4);   // pan * 4 + look
    stackBone: StaticArray<i32> = new StaticArray<i32>(NSTACK);
    smokeBone: StaticArray<i32> = new StaticArray<i32>(NSMOKE);
    starBone: StaticArray<i32> = new StaticArray<i32>(NSTAR);

    px: StaticArray<f64> = [-1.0, 0.0, 1.0];
    pState: StaticArray<i32> = new StaticArray<i32>(NPAN);
    pT: StaticArray<f64> = new StaticArray<f64>(NPAN);       // time in the state
    pCook: StaticArray<f64> = new StaticArray<f64>(NPAN);    // cooking seconds (scaled by the pace)
    pG: StaticArray<f64> = new StaticArray<f64>(NPAN);       // cook time when it turns golden
    pW: StaticArray<f64> = new StaticArray<f64>(NPAN);       // golden window
    pD: StaticArray<f64> = new StaticArray<f64>(NPAN);       // browned window
    pLook: StaticArray<i32> = new StaticArray<i32>(NPAN);    // the look when flipped
    pWob: StaticArray<f64> = new StaticArray<f64>(NPAN);     // a clicked-empty wobble
    pSmoke: StaticArray<f64> = new StaticArray<f64>(NPAN);
    pPlan: StaticArray<f64> = new StaticArray<f64>(NPAN);    // demo: cook time it means to flip at (-1: never)

    sT: StaticArray<f64> = new StaticArray<f64>(NSMOKE);     // < 0 idle
    sX: StaticArray<f64> = new StaticArray<f64>(NSMOKE);
    sZ: StaticArray<f64> = new StaticArray<f64>(NSMOKE);
    sBig: StaticArray<f64> = new StaticArray<f64>(NSMOKE);
    aT: StaticArray<f64> = new StaticArray<f64>(NSTAR);
    aX: StaticArray<f64> = new StaticArray<f64>(NSTAR);
    aY: StaticArray<f64> = new StaticArray<f64>(NSTAR);
    aZ: StaticArray<f64> = new StaticArray<f64>(NSTAR);
    aVX: StaticArray<f64> = new StaticArray<f64>(NSTAR);
    aVY: StaticArray<f64> = new StaticArray<f64>(NSTAR);
    aVZ: StaticArray<f64> = new StaticArray<f64>(NSTAR);

    popT: f64 = -1;
    popX: f32 = 0;
    popY: f32 = 0;
    popText: string = "";
    popColor: i32 = 0;
    stackPop: f64 = 0;
    shakeT: f64 = 0;
    flashT: f64 = 0;
    camTX: f64 = 0;
    texel: f64 = 0.03;
    demoNext: f64 = 0;      // the demo's hand needs a moment between clicks

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < NPAN; i++) {
            this.panBone[i] = api.bone("pan" + i.toString());
            this.lookBone[i * 4 + L_RAW] = api.bone("raw" + i.toString());
            this.lookBone[i * 4 + L_GOLD] = api.bone("gold" + i.toString());
            this.lookBone[i * 4 + L_DARK] = api.bone("dark" + i.toString());
            this.lookBone[i * 4 + L_BURNT] = api.bone("burnt" + i.toString());
        }
        for (let i = 0; i < NSTACK; i++) {
            this.stackBone[i] = api.bone("stack" + i.toString());
        }
        for (let i = 0; i < NSMOKE; i++) {
            this.smokeBone[i] = api.bone("smoke" + i.toString());
        }
        for (let i = 0; i < NSTAR; i++) {
            this.starBone[i] = api.bone("star" + i.toString());
        }
        this.camTX = api.targetX;
        // the art grid's texel (orthoHeight over the art rows incl. the two spare ones): a shake
        // moves the camera by whole texels so the HUD stays on the scene's pixel grid
        this.texel = api.orthoHeight / 136.0;
        this.wasDemo = api.demo;
        this.resetWorld(api);
        if (api.demo) {
            this.beginRun(api);
        }
    }

    // ------------------------------------------------------------------ run control

    pace(): f64 {
        return Math.min(2.6, 1.0 + this.runT / 40.0);
    }

    newCake(api: GameApi, i: i32): void {
        let p = this.pace();
        this.pCook[i] = 0;
        this.pG[i] = api.range(2.0, 3.4);
        this.pW[i] = Math.max(0.6, 1.5 / Math.sqrt(p));
        this.pD[i] = Math.max(0.45, 1.0 / Math.sqrt(p));
        this.pSmoke[i] = 0;
        // the demo decides when it will flip this one: mostly in the golden window, sometimes not
        let r = api.rand();
        if (r < 0.06) {
            this.pPlan[i] = -1;                                              // forgets it
        } else if (r < 0.12) {
            this.pPlan[i] = this.pG[i] - api.range(0.2, 0.6);                // too eager: raw
        } else if (r < 0.26) {
            this.pPlan[i] = this.pG[i] + this.pW[i] + api.range(0.05, 0.6) * this.pD[i];  // a bit late
        } else {
            this.pPlan[i] = this.pG[i] + this.pW[i] * api.range(0.2, 0.8);
        }
    }

    resetWorld(api: GameApi): void {
        this.score = 0;
        this.strikes = 0;
        this.served = 0;
        this.runT = 0;
        for (let i = 0; i < NSMOKE; i++) {
            this.sT[i] = -1;
        }
        for (let i = 0; i < NSTAR; i++) {
            this.aT[i] = -1;
        }
        // the stove is busy from the first frame: one pan golden, one raw, one pouring
        for (let i = 0; i < NPAN; i++) {
            this.newCake(api, i);
            this.pState[i] = P_COOK;
            this.pT[i] = 1;
            this.pWob[i] = 0;
        }
        this.pCook[1] = this.pG[1] + 0.15;
        this.pW[1] = 1.6;
        this.pPlan[1] = this.pG[1] + 0.5;
        this.pCook[0] = 0.9;
        this.pState[2] = P_POUR;
        this.pT[2] = 0;
        this.popT = -1;
    }

    beginRun(api: GameApi): void {
        if (this.state == ST_OVER) {
            this.resetWorld(api);
        }
        this.state = ST_PLAY;
        this.stateT = 0;
        this.runT = 0;
        this.demoNext = 0.25;
    }

    endRun(): void {
        this.state = ST_OVER;
        this.stateT = 0;
        if (this.score > this.best) {
            this.best = this.score;
        }
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            // the host turned demo off (a visitor) or on: a fresh run either way
            this.wasDemo = api.demo;
            this.state = ST_OVER;
            this.beginRun(api);
        }
        this.stateT += dt;
        if (this.state == ST_PLAY) {
            this.runT += dt;
        }
        if (api.demo) {
            if (this.state == ST_OVER && this.stateT > 2.0) {
                this.beginRun(api);
            } else if (this.state == ST_PLAY) {
                this.demoThink(api, dt);
            }
        }
        for (let i = 0; i < NPAN; i++) {
            this.updatePan(api, i, dt);
        }
        this.updateStack(api, dt);
        this.updateSmoke(api, dt);
        this.updateStars(api, dt);
        if (this.popT >= 0) {
            this.popT += dt;
            if (this.popT > 0.9) {
                this.popT = -1;
            }
        }
        if (this.flashT > 0) {
            this.flashT -= dt;
        }
        if (this.shakeT > 0) {
            this.shakeT -= dt;
            let k = <i32>Math.floor(this.shakeT * 30) % 3;
            api.targetX = this.camTX + <f64>(k - 1) * this.texel;
        } else {
            api.targetX = this.camTX;
        }
    }

    // The look a cooking pancake shows at cook time c.
    lookAt(i: i32, c: f64): i32 {
        if (c < this.pG[i]) {
            return L_RAW;
        }
        if (c < this.pG[i] + this.pW[i]) {
            return L_GOLD;
        }
        if (c < this.pG[i] + this.pW[i] + this.pD[i]) {
            return L_DARK;
        }
        return L_BURNT;
    }

    showLook(api: GameApi, i: i32, look: i32, x: f64, y: f64, z: f64, pitch: f64, sx: f64, sy: f64): void {
        for (let l = 0; l < 4; l++) {
            let b = this.lookBone[i * 4 + l];
            if (l != look) {
                api.hide(b);
            } else if (pitch != 0) {
                api.place(b, x, y, z, 0, pitch, 0, sx);
            } else {
                api.placeScaled(b, x, y, z, 0, sx, sy, sx);
            }
        }
    }

    hideLooks(api: GameApi, i: i32): void {
        for (let l = 0; l < 4; l++) {
            api.hide(this.lookBone[i * 4 + l]);
        }
    }

    updatePan(api: GameApi, i: i32, dt: f64): void {
        let x = this.px[i];
        let st = this.pState[i];
        this.pT[i] += dt;
        let t = this.pT[i];
        let playing = this.state == ST_PLAY;
        // the pan itself: still, a little wobble after an empty click, a dip and flick when flipping
        let panY = PAN_Y, panPitch = 0.0, panRoll = 0.0;
        if (this.pWob[i] > 0) {
            this.pWob[i] -= dt;
            panRoll = Math.sin(this.pWob[i] * 40) * 6 * this.pWob[i] / 0.3;
        }
        if (st == P_EMPTY) {
            this.hideLooks(api, i);
            if (t > 0.45) {
                this.pState[i] = P_POUR;
                this.pT[i] = 0;
                this.newCake(api, i);
            }
        } else if (st == P_POUR) {
            // a blob of batter spreads out (stepped)
            let k = Math.min(1.0, Math.floor(t * 15) / 15 / POUR_T);
            let s = 0.25 + 0.85 * k - (k > 0.8 ? (k - 0.8) * 0.5 : 0);
            this.showLook(api, i, L_RAW, x, CAKE_Y + 0.08 * (1 - k), 0, 0, s, 1.6 - 0.6 * k);
            if (t >= POUR_T) {
                this.pState[i] = P_COOK;
                this.pT[i] = 0;
            }
        } else if (st == P_COOK) {
            if (playing) {
                this.pCook[i] += dt * this.pace();
            }
            let c = this.pCook[i];
            let look = this.lookAt(i, c);
            // sizzle: the cake breathes a little, browned ones smoke as a warning
            let breathe = Math.floor(api.time * 6 + <f64>i) % 2 == 0 ? 1.0 : 1.03;
            this.showLook(api, i, look, x, CAKE_Y, 0, 0, breathe, 2.0 - breathe);
            if (look == L_DARK && playing) {
                this.pSmoke[i] -= dt;
                if (this.pSmoke[i] <= 0) {
                    this.pSmoke[i] = 0.35;
                    this.puff(api, x + api.range(-0.15, 0.15), 0.6);
                }
            }
            if (look == L_BURNT && playing) {
                // burnt in the pan: a strike, a cloud of smoke, and it shrinks away
                this.pLook[i] = L_BURNT;
                this.pState[i] = P_FLOP;
                this.pT[i] = 0;
                this.puff(api, x - 0.15, 1.1);
                this.puff(api, x + 0.15, 1.1);
                this.strike(api, i);
            }
        } else if (st == P_FLIP) {
            let look = this.pLook[i];
            // the pan: dip (anticipation), flick up, settle
            if (t < 0.1) {
                panY = PAN_Y - 0.04 * (t / 0.1);
                panPitch = 6 * (t / 0.1);
            } else if (t < 0.22) {
                panY = PAN_Y + 0.06;
                panPitch = -14;
            } else if (t < 0.4) {
                panPitch = -14 * (1 - (t - 0.22) / 0.18);
            }
            // the pancake: rides the dip, flies up turning over once, lands with a squash
            if (t < 0.12) {
                this.showLook(api, i, look, x, CAKE_Y - 0.04 * (t / 0.1), 0, 0, 1, 1);
            } else if (t < 0.6) {
                let s = (t - 0.12) / 0.48;
                let y = CAKE_Y + 1.25 * 4 * s * (1 - s);
                let spin = Math.floor(s * 12) / 12 * 360;
                let stretch = s < 0.25 ? 1.12 : 1.0;
                this.showLook(api, i, look, x, y, 0, spin == 0 ? 0.001 : spin, stretch, 1);
            } else {
                let k = Math.min(1.0, (t - 0.6) / 0.12);
                let raw = look == L_RAW;
                let sq = raw ? 0.45 : 0.6 + 0.4 * k;
                let wide = raw ? 1.35 : 1.25 - 0.25 * k;
                this.showLook(api, i, look, x, CAKE_Y - 0.01, 0, 0, wide, sq);
            }
            if (t >= FLIP_T) {
                this.landed(api, i);
            }
        } else if (st == P_SERVE) {
            // a hop from the pan onto the top of the stack
            let k = Math.min(1.0, t / 0.45);
            let top = CAKE_Y + <f64>Math.min(this.served, NSTACK - 1) * STACK_DY;
            let xx = x + (PLATE_X - x) * k;
            let zz = PLATE_Z * k;
            let y = CAKE_Y + (top - CAKE_Y) * k + Math.sin(k * Math.PI) * 0.7;
            this.showLook(api, i, this.pLook[i], xx, y, zz, 0, 1, 1);
            if (k >= 1.0) {
                this.hideLooks(api, i);
                this.served++;
                this.stackPop = 0.2;
                this.pState[i] = P_EMPTY;
                this.pT[i] = 0;
            }
        } else if (st == P_FLOP) {
            let k = Math.min(1.0, Math.floor(t * 15) / 15 / 0.6);
            let raw = this.pLook[i] == L_RAW;
            this.showLook(api, i, this.pLook[i], x, CAKE_Y - 0.02, 0, 0, (raw ? 1.35 : 1.0) * (1 - k * 0.9), (raw ? 0.45 : 1.0) * (1 - k * 0.9));
            if (t >= 0.6) {
                this.hideLooks(api, i);
                this.pState[i] = P_EMPTY;
                this.pT[i] = 0;
            }
        }
        api.place(this.panBone[i], x, panY, 0, 0, panPitch, panRoll, 1.0);
    }

    // A pan was clicked.
    flip(api: GameApi, i: i32): void {
        let st = this.pState[i];
        if (st != P_COOK) {
            this.pWob[i] = 0.3;
            return;
        }
        let look = this.lookAt(i, this.pCook[i]);
        this.pLook[i] = look;
        this.pState[i] = P_FLIP;
        this.pT[i] = 0;
    }

    landed(api: GameApi, i: i32): void {
        let look = this.pLook[i];
        let x = this.px[i];
        this.pT[i] = 0;
        if (look == L_GOLD) {
            this.score += 3;
            this.pState[i] = P_SERVE;
            this.burst(api, x);
            this.pop(api, x, "PERFECT!", C_CORAL);
        } else if (look == L_DARK) {
            this.score += 1;
            this.pState[i] = P_SERVE;
            this.pop(api, x, "OK", C_MAUVE);
        } else if (look == L_RAW) {
            this.pState[i] = P_FLOP;
            this.pop(api, x, "RAW!", C_MAUVE);
        } else {
            this.pState[i] = P_FLOP;
            this.puff(api, x, 1.0);
            this.strike(api, i);
        }
    }

    strike(api: GameApi, i: i32): void {
        this.pop(api, this.px[i], "BURNT!", C_INK);
        if (this.state != ST_PLAY) {
            return;
        }
        this.strikes++;
        this.flashT = 0.6;
        this.shakeT = 0.25;
        if (this.strikes >= 3) {
            this.endRun();
        }
    }

    pop(api: GameApi, x: f64, s: string, c: i32): void {
        if (api.project(<f32>x, <f32>0.75, 0)) {
            this.popX = api.screenX;
            this.popY = api.screenY;
            this.popT = 0;
            this.popText = s;
            this.popColor = c;
        }
    }

    // ------------------------------------------------------------------ the plate, smoke, stars

    updateStack(api: GameApi, dt: f64): void {
        if (this.stackPop > 0) {
            this.stackPop -= dt;
        }
        let n = Math.min(this.served, NSTACK);
        for (let k = 0; k < NSTACK; k++) {
            let b = this.stackBone[k];
            if (k >= n) {
                api.hide(b);
                continue;
            }
            let y = CAKE_Y + <f64>k * STACK_DY;
            let top = k == n - 1;
            if (top && this.stackPop > 0) {
                let s = this.stackPop / 0.2;
                api.placeScaled(b, PLATE_X, y, PLATE_Z, <f64>k * 37, 1 + 0.25 * s, 1 - 0.4 * s, 1 + 0.25 * s);
            } else {
                // a slightly wobbly stack, each one turned a little
                api.place(b, PLATE_X + Math.sin(<f64>k * 2.1) * 0.025, y, PLATE_Z + Math.cos(<f64>k * 1.7) * 0.02, <f64>k * 37, 0, 0, 1);
            }
        }
    }

    puff(api: GameApi, x: f64, big: f64): void {
        for (let i = 0; i < NSMOKE; i++) {
            if (this.sT[i] < 0) {
                this.sT[i] = 0;
                this.sX[i] = x;
                this.sZ[i] = api.range(-0.1, 0.1);
                this.sBig[i] = big;
                return;
            }
        }
    }

    updateSmoke(api: GameApi, dt: f64): void {
        for (let i = 0; i < NSMOKE; i++) {
            let b = this.smokeBone[i];
            if (this.sT[i] < 0) {
                api.hide(b);
                continue;
            }
            this.sT[i] += dt;
            let t = this.sT[i];
            if (t > 1.0) {
                this.sT[i] = -1;
                api.hide(b);
                continue;
            }
            let s = (t < 0.3 ? t / 0.3 : 1.0 - (t - 0.3) / 0.7 * 0.8) * this.sBig[i];
            let q = Math.floor(t * 12) / 12;
            api.place(b, this.sX[i] + Math.sin(q * 6) * 0.08, 0.3 + q * 0.9, this.sZ[i], q * 90, 0, 0, Math.max(0.15, s));
        }
    }

    burst(api: GameApi, x: f64): void {
        let made = 0;
        for (let i = 0; i < NSTAR && made < 5; i++) {
            if (this.aT[i] >= 0) {
                continue;
            }
            let a = <f64>made / 5.0 * Math.PI * 2 + api.range(-0.3, 0.3);
            this.aT[i] = 0;
            this.aX[i] = x; this.aY[i] = 0.35; this.aZ[i] = 0;
            this.aVX[i] = Math.cos(a) * api.range(1.0, 1.6);
            this.aVZ[i] = Math.sin(a) * api.range(0.6, 1.0);
            this.aVY[i] = api.range(1.8, 2.6);
            made++;
        }
    }

    updateStars(api: GameApi, dt: f64): void {
        for (let i = 0; i < NSTAR; i++) {
            let b = this.starBone[i];
            if (this.aT[i] < 0) {
                api.hide(b);
                continue;
            }
            this.aT[i] += dt;
            if (this.aT[i] > 0.65) {
                this.aT[i] = -1;
                api.hide(b);
                continue;
            }
            this.aVY[i] -= 6.5 * dt;
            this.aX[i] += this.aVX[i] * dt;
            this.aY[i] += this.aVY[i] * dt;
            this.aZ[i] += this.aVZ[i] * dt;
            api.place(b, this.aX[i], this.aY[i], this.aZ[i], Math.floor(this.aT[i] * 12) * 45, 0, 0, Math.max(0.3, 1.5 - this.aT[i] * 1.8));
        }
    }

    // ------------------------------------------------------------------ the demo cook

    demoThink(api: GameApi, dt: f64): void {
        this.demoNext -= dt;
        if (this.demoNext > 0) {
            return;
        }
        // the pan whose planned moment came first; one click at a time, with a short recovery
        let pick = -1;
        let late = 0.0;
        for (let i = 0; i < NPAN; i++) {
            if (this.pState[i] != P_COOK || this.pPlan[i] < 0) {
                continue;
            }
            let over = this.pCook[i] - this.pPlan[i];
            if (over >= 0 && over >= late) {
                late = over;
                pick = i;
            }
        }
        if (pick >= 0) {
            this.flip(api, pick);
            this.demoNext = api.range(0.22, 0.4);
        }
    }

    // ------------------------------------------------------------------ input

    // The pan under the pointer (its body or its handle), or -1.
    panAt(api: GameApi, x: f32, y: f32): i32 {
        let best = -1;
        let bestD: f32 = 1e9;
        for (let i = 0; i < NPAN; i++) {
            for (let h = 0; h < 2; h++) {
                if (!api.project(<f32>this.px[i], <f32>0.1, h == 0 ? <f32>0 : <f32>0.62)) {
                    continue;
                }
                let dx = api.screenX - x, dy = api.screenY - y;
                let d = Mathf.sqrt(dx * dx + dy * dy);
                if (d < (h == 0 ? <f32>19 : <f32>9) && d < bestD) {
                    bestD = d;
                    best = i;
                }
            }
        }
        return best;
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind != POINTER_DOWN) {
            return true;
        }
        if (this.state == ST_OVER) {
            if (this.stateT > 0.8) {
                this.beginRun(api);
            }
            return true;
        }
        if (this.state == ST_IDLE) {
            this.beginRun(api);
        }
        let i = this.panAt(api, x, y);
        if (i >= 0) {
            this.flip(api, i);
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let ink = api.paletteColor(C_INK);
        let milk = api.paletteColor(C_MILK);
        let oat = api.paletteColor(C_OAT);
        let coral = api.paletteColor(C_CORAL);
        let mauve = api.paletteColor(C_MAUVE);
        let lilac = api.paletteColor(C_LILAC);
        let apricot = api.paletteColor(C_APRICOT);
        if (this.popT >= 0) {
            let rise = <f32>(Math.min(this.popT, 0.4) * 30.0);
            let w = api.textWidth(this.popText, 1);
            api.text(Mathf.round(this.popX - w * 0.5), this.popY - 4 - rise, this.popText, api.paletteColor(this.popColor), 1, milk);
        }
        api.text(4, 4, this.score.toString(), ink, 2, milk);
        api.text(4, 16, "BEST " + this.best.toString(), mauve, 1, milk);
        // strikes: three X, struck ones in coral
        for (let s = 0; s < 3; s++) {
            let x = <f32>(api.hudW - 12 - s * 10);
            let c = s < this.strikes ? coral : oat;
            if (s == this.strikes - 1 && this.flashT > 0 && Math.floor(this.flashT * 10) % 2 == 0) {
                c = ink;
            }
            api.text(x, 4, "X", c, 2, s < this.strikes ? ink : milk);
        }
        let h = <f32>api.hudH;
        if (this.state == ST_IDLE) {
            let blink = Math.floor(api.time * 2) % 2 == 0;
            this.band(api, h - 26, 25, milk, lilac);
            api.textCentered(h - 22, "CLICK A GOLDEN PANCAKE", blink ? ink : coral, 2, 0);
            api.textCentered(h - 8, "FLIP THEM GOLDEN - BURNT ONES ARE STRIKES", mauve, 1, 0);
        } else if (this.state == ST_OVER) {
            let pw: f32 = 120, ph: f32 = 40;
            let px = Mathf.floor((<f32>api.hudW - pw) * 0.5), py = Mathf.floor(h * 0.5 - 30);
            api.rect(px, py, pw, ph, milk);
            api.rect(px - 1, py - 1, pw + 2, 1, lilac);
            api.rect(px - 1, py + ph, pw + 2, 1, lilac);
            api.rect(px - 1, py, 1, ph, lilac);
            api.rect(px + pw, py, 1, ph, lilac);
            api.textCentered(py + 5, "KITCHEN CLOSED", ink, 2, 0);
            api.textCentered(py + 20, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), mauve, 1, 0);
            if (this.stateT > 0.8 && !api.demo) {
                api.textCentered(py + 30, "CLICK TO COOK AGAIN", coral, 1, 0);
            }
        } else if (this.runT < 4.0 && !api.demo) {
            this.band(api, h - 12, 11, milk, lilac);
            api.textCentered(h - 9, "CLICK A PAN WHEN ITS PANCAKE IS GOLDEN", ink, 1, 0);
        }
    }

    // A full-width strip with a one-pixel top edge, for hint lines over the busy stove front.
    band(api: GameApi, y: f32, hgt: f32, fill: u32, edge: u32): void {
        api.rect(0, y, <f32>api.hudW, hgt, fill);
        api.rect(0, y - 1, <f32>api.hudW, 1, edge);
    }
}
