// Dragon Tower: knights climb three ladders up the dragon's tower. Hold the pointer to breathe fire
// where it points; the fire burns out after about two seconds and must recharge (overheat it and the
// dragon only smokes until half the fire is back). A knight that reaches the top costs a heart; three
// hearts. Burnt knights score 1, knights burnt in the top third score 2.
//
// Every moving thing is a game bone from scene.bake.json: the dragon's body and head (the head turns
// and dips towards the aim), a pool of 9 knights, 16 fireballs, 6 puffs and 3 clouds.
// Deterministic: api.rand() only. Demo mode (api.demo) plays itself like a decent human.
import { GameApi, POINTER_DOWN } from "./game_api";

// ramps in art/palette.json order
const R_STONE: i32 = 0;   // purple, thistle, yellow
const R_SCALE: i32 = 1;   // purple, mint, yellow
const R_BLUSH: i32 = 2;   // purple, pink, yellow

// the world (metres, Y up; the camera looks at the origin from +Z, 10 degrees above)
const GROUND: f64 = -4.4;
const WALK_Y: f64 = 0.3;        // the tower's walk, where the dragon sits
const NECK_Y: f64 = 1.56;       // the head's pivot above the dragon's feet (baked at scale 1.2)
const NECK_Z: f64 = 0.06;
const KR: f64 = 1.68;           // a climbing knight's distance from the tower's axis
const TOP_H: f64 = 4.3;        // a knight this high on its ladder steps onto the walk
const RUNG: f64 = 0.42;
const AIM_Z: f64 = 2.3;         // the fire flies towards the pointer on this vertical plane, in front of the ladders
const FIRE_SPEED: f64 = 10.5;

const IDLE: i32 = 0;
const PLAY: i32 = 1;
const OVER: i32 = 2;

// knight states
const K_OFF: i32 = 0;
const K_WALK: i32 = 1;
const K_CLIMB: i32 = 2;
const K_BREACH: i32 = 3;   // hops onto the walk and gloats, then the dragon swats it off
const K_BURN: i32 = 4;     // hit: a quick pop
const K_FLY: i32 = 5;      // tumbling off, until it lands in a puff
const K_CHEER: i32 = 6;    // after the game over

const NK: i32 = 9;
const NF: i32 = 16;
const NP: i32 = 6;
const NC: i32 = 3;
const NPOP: i32 = 6;

export class Game {
    body: i32 = -1;
    head: i32 = -1;

    kBone: StaticArray<i32> = new StaticArray<i32>(NK);
    kState: StaticArray<i32> = new StaticArray<i32>(NK);
    kLad: StaticArray<i32> = new StaticArray<i32>(NK);
    kX: StaticArray<f64> = new StaticArray<f64>(NK);
    kY: StaticArray<f64> = new StaticArray<f64>(NK);
    kZ: StaticArray<f64> = new StaticArray<f64>(NK);
    kH: StaticArray<f64> = new StaticArray<f64>(NK);
    kT: StaticArray<f64> = new StaticArray<f64>(NK);
    kV: StaticArray<f64> = new StaticArray<f64>(NK);
    kVX: StaticArray<f64> = new StaticArray<f64>(NK);
    kVY: StaticArray<f64> = new StaticArray<f64>(NK);
    kVZ: StaticArray<f64> = new StaticArray<f64>(NK);
    kSpin: StaticArray<f64> = new StaticArray<f64>(NK);
    kYaw: StaticArray<f64> = new StaticArray<f64>(NK);
    kFromX: StaticArray<f64> = new StaticArray<f64>(NK);

    fBone: StaticArray<i32> = new StaticArray<i32>(NF);
    fX: StaticArray<f64> = new StaticArray<f64>(NF);
    fY: StaticArray<f64> = new StaticArray<f64>(NF);
    fZ: StaticArray<f64> = new StaticArray<f64>(NF);
    fVX: StaticArray<f64> = new StaticArray<f64>(NF);
    fVY: StaticArray<f64> = new StaticArray<f64>(NF);
    fVZ: StaticArray<f64> = new StaticArray<f64>(NF);
    fAge: StaticArray<f64> = new StaticArray<f64>(NF);
    fLife: StaticArray<f64> = new StaticArray<f64>(NF);
    fRoll: StaticArray<f64> = new StaticArray<f64>(NF);
    fNext: i32 = 0;

    pBone: StaticArray<i32> = new StaticArray<i32>(NP);
    pX: StaticArray<f64> = new StaticArray<f64>(NP);
    pY: StaticArray<f64> = new StaticArray<f64>(NP);
    pZ: StaticArray<f64> = new StaticArray<f64>(NP);
    pAge: StaticArray<f64> = new StaticArray<f64>(NP);
    pSize: StaticArray<f64> = new StaticArray<f64>(NP);
    pNext: i32 = 0;

    cBone: StaticArray<i32> = new StaticArray<i32>(NC);
    cX: StaticArray<f64> = new StaticArray<f64>(NC);

    // floating score texts (world position, projected in hud())
    tText: Array<string> = new Array<string>(NPOP);
    tX: StaticArray<f64> = new StaticArray<f64>(NPOP);
    tY: StaticArray<f64> = new StaticArray<f64>(NPOP);
    tZ: StaticArray<f64> = new StaticArray<f64>(NPOP);
    tAge: StaticArray<f64> = new StaticArray<f64>(NPOP);
    tNext: i32 = 0;

    mode: i32 = IDLE;
    wasDemo: bool = false;
    score: i32 = 0;
    best: i32 = 0;
    bestDemo: i32 = 0;
    hearts: i32 = 3;
    runTime: f64 = 0;
    overTime: f64 = 0;
    spawnIn: f64 = 0;

    // the fire
    fuel: f64 = 1;
    hot: bool = false;          // overheated: no fire until fuel is back over half
    held: bool = false;         // the pointer (or the demo's finger) is down
    breath: f64 = -1;           // seconds into the current breath (-1: not breathing)
    sinceBreath: f64 = 9;
    emitIn: f64 = 0;
    smokeIn: f64 = 0;
    aimX: f64 = 0;
    aimY: f64 = -1;
    aimZ: f64 = AIM_Z;

    // the dragon's pose
    headYaw: f64 = 0;
    headPitch: f64 = 10;
    hurtT: f64 = 9;

    // the demo's finger
    dX: f64 = 160;
    dY: f64 = 120;
    dHold: bool = false;
    dErrX: f64 = 0;
    dErrY: f64 = 0;
    dErrIn: f64 = 0;
    dTarget: i32 = -1;
    dReact: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        this.body = api.bone("dragon");
        this.head = api.bone("head");
        for (let i = 0; i < NK; i++) {
            this.kBone[i] = api.bone("knight" + i.toString());
            this.kState[i] = K_OFF;
            api.hide(this.kBone[i]);
        }
        for (let i = 0; i < NF; i++) {
            this.fBone[i] = api.bone("fire" + i.toString());
            this.fLife[i] = 0;
            api.hide(this.fBone[i]);
        }
        for (let i = 0; i < NP; i++) {
            this.pBone[i] = api.bone("poof" + i.toString());
            this.pAge[i] = 9;
            api.hide(this.pBone[i]);
        }
        for (let i = 0; i < NC; i++) {
            this.cBone[i] = api.bone("cloud" + i.toString());
            this.cX[i] = -7.5 + 6.5 * <f64>i + api.range(-1, 1);
        }
        for (let i = 0; i < NPOP; i++) {
            this.tText[i] = "";
            this.tAge[i] = 9;
        }
        this.wasDemo = api.demo;
        if (api.demo) {
            this.newRun(api);
            this.opening(api);
        }
    }

    // ------------------------------------------------------------------ runs

    private newRun(api: GameApi): void {
        this.mode = PLAY;
        this.score = 0;
        this.hearts = 3;
        this.runTime = 0;
        this.overTime = 0;
        this.fuel = 1;
        this.hot = false;
        this.hurtT = 9;
        this.spawnIn = 0.4;
        for (let i = 0; i < NK; i++) {
            if (this.kState[i] == K_CHEER || this.kState[i] == K_CLIMB || this.kState[i] == K_WALK || this.kState[i] == K_BREACH) {
                this.knockOff(api, i, false);
            }
        }
    }

    // knights already on the ladders, so the demo shows action in its first second
    private opening(api: GameApi): void {
        this.spawnKnight(api, 1, 2.2);
        this.spawnKnight(api, 0, 0.9);
        let k = this.spawnKnight(api, 2, -1);
        if (k >= 0) {
            this.kX[k] = 3.6;
        }
        this.spawnIn = 2.2;
    }

    private gameOver(api: GameApi): void {
        this.mode = OVER;
        this.overTime = 0;
        this.breath = -1;
        if (api.demo) {
            this.bestDemo = max<i32>(this.bestDemo, this.score);
        } else {
            this.best = max<i32>(this.best, this.score);
        }
        for (let i = 0; i < NK; i++) {
            if (this.kState[i] == K_CLIMB || this.kState[i] == K_WALK) {
                this.kState[i] = K_CHEER;
                this.kT[i] = api.range(0, 0.3);
            }
        }
    }

    // ------------------------------------------------------------------ knights

    private ladderAngle(l: i32): f64 {
        return <f64>(l - 1) * 45.0;
    }

    // a knight on ladder l: h >= 0 starts it climbing at that height, h < 0 walks it in from the side
    private spawnKnight(api: GameApi, l: i32, h: f64): i32 {
        let k = -1;
        for (let i = 0; i < NK; i++) {
            if (this.kState[i] == K_OFF) {
                k = i;
                break;
            }
        }
        if (k < 0) {
            return -1;
        }
        let a = this.ladderAngle(l) * Math.PI / 180;
        this.kLad[k] = l;
        this.kT[k] = api.range(0, 1);
        let lvl = Math.min(this.runTime, 90.0);
        this.kV[k] = (0.72 + lvl * 0.012) * api.range(0.85, 1.15);
        if (h >= 0) {
            this.kState[k] = K_CLIMB;
            this.kH[k] = h;
        } else {
            this.kState[k] = K_WALK;
            let side = l == 0 ? -1.0 : (l == 2 ? 1.0 : (api.rand() < 0.5 ? -1.0 : 1.0));
            this.kFromX[k] = side * 8.4;
            this.kX[k] = side * 8.4;
            this.kZ[k] = KR * Math.cos(a) + 0.5;
            this.kH[k] = 0;
        }
        return k;
    }

    private spawnRandom(api: GameApi): void {
        let active = 0;
        let onLadder = new StaticArray<i32>(3);
        for (let i = 0; i < NK; i++) {
            let s = this.kState[i];
            if (s == K_WALK || s == K_CLIMB) {
                active++;
                onLadder[this.kLad[i]]++;
            }
        }
        let cap = <i32>Math.min(<f64>NK, 2.0 + this.runTime / 7.0);
        if (active >= cap) {
            return;
        }
        // the least crowded ladder, ties broken at random
        let l = <i32>Math.floor(api.rand() * 3.0);
        for (let j = 0; j < 3; j++) {
            if (onLadder[j] < onLadder[l]) {
                l = j;
            }
        }
        this.spawnKnight(api, l, -1);
    }

    private knockOff(api: GameApi, k: i32, hit: bool): void {
        let a = this.ladderAngle(this.kLad[k]) * Math.PI / 180;
        this.kState[k] = hit ? K_BURN : K_FLY;
        this.kT[k] = 0;
        let out = hit ? api.range(2.2, 3.2) : api.range(3.0, 4.0);
        this.kVX[k] = Math.sin(a) * out + api.range(-0.8, 0.8);
        this.kVZ[k] = Math.cos(a) * out + 1.2;
        this.kVY[k] = api.range(3.0, 4.5);
        this.kSpin[k] = api.range(500, 800) * (api.rand() < 0.5 ? -1.0 : 1.0);
    }

    private knightPos(k: i32): void {
        // kX, kY, kZ from the state (for climbing knights)
        let a = this.ladderAngle(this.kLad[k]) * Math.PI / 180;
        let s = this.kState[k];
        if (s == K_CLIMB || s == K_CHEER) {
            this.kX[k] = KR * Math.sin(a);
            this.kZ[k] = KR * Math.cos(a);
            this.kY[k] = GROUND + this.shownH(k);
        }
    }

    // the height drawn: the knight pulls itself up one rung at a time (a quick tug, then a rest),
    // stepped at 12 fps
    private shownH(k: i32): f64 {
        let h = this.kH[k];
        let r = Math.floor(h / RUNG);
        let f = (h - r * RUNG) / RUNG;
        let e = f < 0.45 ? 0.0 : Math.min(1.0, (f - 0.45) / 0.4);
        e = Math.floor(e * 4.0) / 4.0;
        return (r + e) * RUNG;
    }

    private updateKnights(api: GameApi, dt: f64): void {
        for (let k = 0; k < NK; k++) {
            let s = this.kState[k];
            let b = this.kBone[k];
            if (s == K_OFF) {
                continue;
            }
            this.kT[k] += dt;
            let a = this.ladderAngle(this.kLad[k]);
            let ar = a * Math.PI / 180;
            if (s == K_WALK) {
                let fx = KR * Math.sin(ar);
                let fz = KR * Math.cos(ar);
                let dir = fx > this.kX[k] ? 1.0 : -1.0;
                let speed = 2.3;
                this.kX[k] += dir * speed * dt;
                let total = Math.abs(fx - this.kFromX[k]);
                let left = Math.abs(fx - this.kX[k]);
                this.kZ[k] = fz + 0.5 * Math.min(1.0, left / Math.max(total, 0.01));
                if ((dir > 0 && this.kX[k] >= fx) || (dir < 0 && this.kX[k] <= fx)) {
                    this.kState[k] = K_CLIMB;
                    this.kH[k] = 0;
                    this.kT[k] = 0;
                }
                let hop = Math.abs(Math.sin(this.kT[k] * 9.0));
                hop = Math.floor(hop * 3.0) / 3.0 * 0.12;
                api.place(b, this.kX[k], GROUND + hop, this.kZ[k], dir > 0 ? 90.0 : -90.0, 0, 0, 1);
            } else if (s == K_CLIMB) {
                if (this.mode == PLAY) {
                    this.kH[k] += this.kV[k] * dt;
                }
                this.knightPos(k);
                let rung = <i32>Math.floor(this.kH[k] / RUNG);
                let roll = (rung % 2 == 0 ? 6.0 : -6.0);
                api.place(b, this.kX[k], this.kY[k], this.kZ[k], a + 180.0, 0, roll, 1);
                if (this.kH[k] >= TOP_H && this.mode == PLAY) {
                    this.kState[k] = K_BREACH;
                    this.kT[k] = 0;
                }
            } else if (s == K_BREACH) {
                // hop from the ladder's top onto the merlons (0.35 s), gloat (0.45 s), then get swatted
                let t = this.kT[k];
                let u = Math.min(1.0, t / 0.35);
                let r = KR - 0.3 * u;
                let y = GROUND + TOP_H + (WALK_Y + 0.55 - GROUND - TOP_H) * u + Math.sin(u * Math.PI) * 0.45;
                let sq = t < 0.35 ? 1.0 : (t < 0.45 ? 0.8 : 1.0 + 0.08 * Math.sin((t - 0.45) * 30.0));
                api.placeScaled(b, r * Math.sin(ar), y, r * Math.cos(ar), a, 1.0 / Math.sqrt(sq), sq, 1.0 / Math.sqrt(sq));
                if (t >= 0.8) {
                    this.kX[k] = r * Math.sin(ar);
                    this.kY[k] = y;
                    this.kZ[k] = r * Math.cos(ar);
                    this.knockOff(api, k, false);
                    this.hurt(api);
                }
            } else if (s == K_BURN) {
                // a pop: swell and flatten for a tenth of a second, then tumble
                let t = this.kT[k];
                let sq = 1.0 + 0.35 * Math.sin(Math.min(1.0, t / 0.12) * Math.PI);
                api.placeScaled(b, this.kX[k], this.kY[k], this.kZ[k], a + 180.0, sq, 1.0 / sq, sq);
                if (t >= 0.12) {
                    this.kState[k] = K_FLY;
                    this.kT[k] = 0;
                }
            } else if (s == K_FLY) {
                this.kVY[k] -= 13.0 * dt;
                this.kX[k] += this.kVX[k] * dt;
                this.kY[k] += this.kVY[k] * dt;
                this.kZ[k] += this.kVZ[k] * dt;
                let spin = Math.floor(this.kT[k] * this.kSpin[k] / 45.0) * 45.0;
                api.place(b, this.kX[k], this.kY[k], this.kZ[k], a + 180.0, spin, spin * 0.3, 1);
                if (this.kY[k] < GROUND + 0.2 || Math.abs(this.kX[k]) > 10.0) {
                    if (this.kY[k] < GROUND + 0.2) {
                        this.puff(api, this.kX[k], GROUND + 0.35, this.kZ[k], 1.2);
                    }
                    this.kState[k] = K_OFF;
                    api.hide(b);
                }
            } else if (s == K_CHEER) {
                this.knightPos(k);
                let t = this.kT[k];
                let jump = Math.abs(Math.sin(t * 6.0));
                jump = Math.floor(jump * 4.0) / 4.0 * 0.18;
                api.place(b, this.kX[k], this.kY[k] + jump, this.kZ[k], a + 180.0, 0, jump > 0.1 ? 10.0 : -10.0, 1);
            }
        }
    }

    private hurt(api: GameApi): void {
        if (this.mode != PLAY) {
            return;
        }
        this.hearts--;
        this.hurtT = 0;
        if (this.hearts <= 0) {
            this.gameOver(api);
        }
    }

    // ------------------------------------------------------------------ fire

    // the pointer (HUD pixels) to the point on the aim plane
    private aimFrom(api: GameApi, hx: f64, hy: f64): void {
        let nx = ((<f32>hx - api.gridOX) / api.gridW) * 2.0 - 1.0;
        let ny = 1.0 - ((<f32>hy - api.gridOY) / api.gridH) * 2.0;
        let ox = <f64>(api.camEX + api.camRX * nx * api.camHW + api.camUX * ny * api.camHH);
        let oy = <f64>(api.camEY + api.camRY * nx * api.camHW + api.camUY * ny * api.camHH);
        let oz = <f64>(api.camEZ + api.camRZ * nx * api.camHW + api.camUZ * ny * api.camHH);
        let fz = <f64>api.camFZ;
        if (Math.abs(fz) < 1e-4) {
            return;
        }
        let t = (AIM_Z - oz) / fz;
        this.aimX = ox + <f64>api.camFX * t;
        this.aimY = oy + <f64>api.camFY * t;
        this.aimZ = AIM_Z;
    }

    private headPivotY(sy: f64): f64 {
        return WALK_Y + NECK_Y * sy;
    }

    private updateFire(api: GameApi, dt: f64, sy: f64): void {
        let canFire = this.mode == PLAY && !this.hot;
        let breathing = this.held && canFire && this.fuel > 0;
        if (breathing) {
            if (this.breath < 0) {
                this.breath = 0;
                this.emitIn = 0.14;   // the inhale before the flame
            }
            this.breath += dt;
            this.sinceBreath = 0;
            this.fuel -= 0.5 * dt;
            if (this.fuel <= 0) {
                this.fuel = 0;
                this.hot = true;
                this.breath = -1;
                this.smokeIn = 0;
            }
        } else {
            this.breath = -1;
            this.sinceBreath += dt;
            if (this.sinceBreath > 0.2 || this.hot) {
                this.fuel = Math.min(1.0, this.fuel + 0.34 * dt);
            }
            if (this.hot && this.fuel >= 0.5) {
                this.hot = false;
            }
        }
        // the mouth: the snout's tip turned with the head
        let hy = this.headPivotY(sy);
        let yr = this.headYaw * Math.PI / 180;
        let pr = this.headPitch * Math.PI / 180;
        let ly = 0.24 * Math.cos(pr) - 0.97 * Math.sin(pr);
        let lz = 0.24 * Math.sin(pr) + 0.97 * Math.cos(pr);
        let mx = lz * Math.sin(yr);
        let my = hy + ly;
        let mz = NECK_Z + lz * Math.cos(yr);
        if (this.breath >= 0) {
            this.emitIn -= dt;
            while (this.emitIn <= 0) {
                this.emitIn += 0.055;
                this.emit(api, mx, my, mz);
            }
        }
        if (this.hot) {
            this.smokeIn -= dt;
            if (this.smokeIn <= 0) {
                this.smokeIn = 0.32;
                this.puff(api, mx, my + 0.15, mz, 0.55);
            }
        }
        // fireballs fly, grow and flicker; each one tests the knights on screen
        for (let i = 0; i < NF; i++) {
            if (this.fLife[i] <= 0) {
                continue;
            }
            this.fAge[i] += dt;
            let b = this.fBone[i];
            if (this.fAge[i] >= this.fLife[i]) {
                this.fLife[i] = 0;
                api.hide(b);
                continue;
            }
            this.fX[i] += this.fVX[i] * dt;
            this.fY[i] += this.fVY[i] * dt;
            this.fZ[i] += this.fVZ[i] * dt;
            let u = this.fAge[i] / this.fLife[i];
            let size = 0.6 + 1.0 * Math.min(1.0, u * 1.6);
            if (u > 0.82) {
                size *= (1.0 - u) / 0.18 * 0.8 + 0.2;
            }
            size = Math.floor(size * 8.0) / 8.0;
            let flick = Math.floor(this.fAge[i] * 14.0 + this.fRoll[i]) * 47.0;
            api.place(b, this.fX[i], this.fY[i], this.fZ[i], flick, flick * 0.7, this.fRoll[i] * 40.0, size);
            if (this.mode == PLAY && u > 0.08 && api.time > 0.25) {
                this.burnTest(api, i, size);
            }
        }
    }

    private emit(api: GameApi, mx: f64, my: f64, mz: f64): void {
        let i = this.fNext;
        this.fNext = (this.fNext + 1) % NF;
        let dx = this.aimX - mx;
        let dy = this.aimY - my;
        let dz = this.aimZ - mz;
        let d = Math.sqrt(dx * dx + dy * dy + dz * dz);
        if (d < 0.3) {
            d = 0.3;
        }
        let j = 0.07;
        let vx = dx / d + api.range(-j, j);
        let vy = dy / d + api.range(-j, j);
        let vz = dz / d + api.range(-j, j);
        let n = Math.sqrt(vx * vx + vy * vy + vz * vz);
        this.fVX[i] = vx / n * FIRE_SPEED;
        this.fVY[i] = vy / n * FIRE_SPEED;
        this.fVZ[i] = vz / n * FIRE_SPEED;
        this.fX[i] = mx;
        this.fY[i] = my;
        this.fZ[i] = mz;
        this.fAge[i] = 0;
        this.fLife[i] = Math.min(1.1, d / FIRE_SPEED + 0.12);
        this.fRoll[i] = api.range(0, 8);
    }

    // a fireball hits a knight when they overlap on screen (what the player sees)
    private burnTest(api: GameApi, f: i32, size: f64): void {
        if (!api.project(<f32>this.fX[f], <f32>this.fY[f], <f32>this.fZ[f])) {
            return;
        }
        let fx = api.screenX;
        let fy = api.screenY;
        let r = <f32>(3.0 + 4.5 * size);
        for (let k = 0; k < NK; k++) {
            let s = this.kState[k];
            if (s != K_CLIMB && s != K_WALK && s != K_BREACH) {
                continue;
            }
            if (s == K_BREACH && this.kT[k] > 0.5) {
                continue;
            }
            let y = s == K_WALK ? GROUND : this.kY[k];
            if (s == K_BREACH) {
                y = GROUND + TOP_H;
            }
            if (!api.project(<f32>this.kX[k], <f32>(y + 0.56), <f32>this.kZ[k])) {
                continue;
            }
            if (Mathf.abs(api.screenX - fx) < r * 0.8 && Mathf.abs(api.screenY - fy) < r) {
                let high = s == K_BREACH || this.kH[k] > TOP_H * 0.66;
                let pts = high ? 2 : 1;
                this.score += pts;
                this.popText(high ? "+2!" : "+1", this.kX[k], y + 1.0, this.kZ[k]);
                this.puff(api, this.kX[k], y + 0.45, this.kZ[k] + 0.3, 0.8);
                if (s == K_WALK) {
                    this.kY[k] = GROUND;
                    this.kLad[k] = this.kX[k] < 0 ? 0 : 2;
                } else if (s == K_BREACH) {
                    this.kY[k] = y;
                }
                this.knockOff(api, k, true);
            }
        }
    }

    private puff(api: GameApi, x: f64, y: f64, z: f64, size: f64): void {
        let i = this.pNext;
        this.pNext = (this.pNext + 1) % NP;
        this.pX[i] = x;
        this.pY[i] = y;
        this.pZ[i] = z;
        this.pAge[i] = 0;
        this.pSize[i] = size;
    }

    private updatePuffs(api: GameApi, dt: f64): void {
        for (let i = 0; i < NP; i++) {
            if (this.pAge[i] >= 0.6) {
                continue;
            }
            this.pAge[i] += dt;
            let b = this.pBone[i];
            if (this.pAge[i] >= 0.6) {
                api.hide(b);
                continue;
            }
            let u = this.pAge[i] / 0.6;
            let s = this.pSize[i] * (u < 0.3 ? 0.5 + u / 0.3 * 0.6 : 1.1 * (1.0 - (u - 0.3) / 0.7) + 0.1);
            s = Math.floor(s * 6.0) / 6.0;
            api.place(b, this.pX[i], this.pY[i] + u * 0.6, this.pZ[i], u * 90.0, 0, 0, Math.max(s, 0.05));
        }
    }

    private popText(s: string, x: f64, y: f64, z: f64): void {
        let i = this.tNext;
        this.tNext = (this.tNext + 1) % NPOP;
        this.tText[i] = s;
        this.tX[i] = x;
        this.tY[i] = y;
        this.tZ[i] = z;
        this.tAge[i] = 0;
    }

    // ------------------------------------------------------------------ the demo's finger

    private updateDemo(api: GameApi, dt: f64): void {
        if (this.mode == OVER) {
            this.dHold = false;
            if (this.overTime > 2.0) {
                this.newRun(api);
                this.opening(api);
            }
            return;
        }
        // the target: the highest climber (a breach in progress first), else a walker near its ladder
        let best = -1;
        let bestH = -1.0;
        for (let k = 0; k < NK; k++) {
            let s = this.kState[k];
            let h = -1.0;
            if (s == K_CLIMB) {
                h = this.kH[k];
            } else if (s == K_BREACH && this.kT[k] < 0.4) {
                h = TOP_H + 1;
            } else if (s == K_WALK) {
                h = -Math.abs(this.kX[k]) * 0.1;
            }
            if (h > bestH) {
                bestH = h;
                best = k;
            }
        }
        if (best != this.dTarget) {
            this.dTarget = best;
            this.dReact = api.range(0.15, 0.35);
        }
        this.dReact -= dt;
        this.dErrIn -= dt;
        if (this.dErrIn <= 0) {
            this.dErrIn = api.range(0.4, 0.8);
            let big = api.rand() < 0.3;
            let e = big ? 1.3 : 0.45;
            this.dErrX = api.range(-e, e);
            this.dErrY = api.range(-e, e);
        }
        let wantX = 160.0;
        let wantY = 110.0;
        if (best >= 0) {
            let s = this.kState[best];
            let y = s == K_WALK ? GROUND : (s == K_BREACH ? GROUND + TOP_H : this.kY[best]);
            // lead a climber a little, as a player does
            let lead = s == K_CLIMB ? this.kV[best] * 0.45 : 0.0;
            if (api.project(<f32>(this.kX[best] + this.dErrX), <f32>(y + 0.56 + lead + this.dErrY), <f32>this.kZ[best])) {
                wantX = <f64>api.screenX;
                wantY = <f64>api.screenY;
            }
        }
        // the finger moves at a hand's speed, with a little lag
        let k = 1.0 - Math.exp(-dt * 7.0);
        let mx = (wantX - this.dX) * k;
        let my = (wantY - this.dY) * k;
        let m = Math.sqrt(mx * mx + my * my);
        let lim = 260.0 * dt;
        if (m > lim) {
            mx *= lim / m;
            my *= lim / m;
        }
        this.dX += mx;
        this.dY += my;
        // hold when a climber is worth it and the fire is there; let go to recharge
        let worth = best >= 0 && (this.kState[best] == K_BREACH || (this.kState[best] == K_CLIMB && bestH > 0.7));
        if (this.dHold) {
            if (!worth || this.fuel < 0.06 || this.hot) {
                this.dHold = false;
            }
        } else if (worth && this.dReact <= 0 && !this.hot && (this.fuel > 0.35 || bestH > TOP_H * 0.7)) {
            this.dHold = true;
        }
    }

    // ------------------------------------------------------------------ the frame

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.newRun(api);
            if (api.demo) {
                this.opening(api);
            }
        }
        if (this.mode == PLAY) {
            this.runTime += dt;
            this.spawnIn -= dt;
            if (this.spawnIn <= 0) {
                let lvl = Math.min(this.runTime, 90.0);
                this.spawnIn = Math.max(0.55, 2.0 - lvl * 0.025) * api.range(0.75, 1.25);
                this.spawnRandom(api);
            }
        } else if (this.mode == OVER) {
            this.overTime += dt;
        }
        this.hurtT += dt;

        // the finger: the demo's, or the pointer
        if (api.demo) {
            this.updateDemo(api, dt);
            this.held = this.dHold;
            this.aimFrom(api, this.dX, this.dY);
        } else {
            this.held = api.pointerDown;
            if (api.pointerX >= 0) {
                this.aimFrom(api, <f64>api.pointerX, <f64>api.pointerY);
            }
        }

        // the dragon: breathes when idle, squashes on the inhale, stretches into the flame, flinches
        // when a knight gets onto the walk, slumps after the game over
        let t = api.time;
        let sy = 1.0 + 0.025 * Math.sin(Math.floor(t * 8.0) / 8.0 * 3.8);
        let bodyYaw = 0.0;
        if (this.breath >= 0 && this.breath < 0.14) {
            sy = 0.9;
        } else if (this.breath >= 0) {
            sy = 1.05 + (Math.floor(t * 12.0) % 2.0 == 0.0 ? 0.012 : -0.012);
        }
        if (this.hurtT < 0.45) {
            bodyYaw = (Math.floor(this.hurtT * 16.0) % 2.0 == 0.0 ? 9.0 : -9.0);
            sy = 0.9;
        }
        if (this.mode == OVER) {
            sy = 0.92;
        }
        // where the head looks: the aim (also while idle: it follows the pointer), down when sad
        let hy = this.headPivotY(sy);
        let dx = this.aimX;
        let dy = this.aimY - hy;
        let dz = this.aimZ - NECK_Z;
        let wantYaw = Math.atan2(dx, dz) * 180 / Math.PI;
        let wantPitch = Math.atan2(-dy, Math.sqrt(dx * dx + dz * dz)) * 180 / Math.PI;
        if (this.mode == IDLE && api.pointerX < 0) {
            wantYaw = 18.0 * Math.sin(t * 0.7);
            wantPitch = 12.0 + 6.0 * Math.sin(t * 1.1);
        }
        if (this.mode == OVER) {
            wantYaw = 0;
            wantPitch = 45;
        }
        if (this.breath >= 0 && this.breath < 0.14) {
            wantPitch -= 22.0;   // rear back before the flame
        }
        wantYaw = Math.max(-75.0, Math.min(75.0, wantYaw));
        wantPitch = Math.max(-25.0, Math.min(28.0, wantPitch));
        let kk = 1.0 - Math.exp(-dt * 12.0);
        this.headYaw += (wantYaw - this.headYaw) * kk;
        this.headPitch += (wantPitch - this.headPitch) * kk;
        bodyYaw += this.headYaw * 0.3;
        let sx = 1.0 / Math.sqrt(sy);
        api.placeScaled(this.body, 0, WALK_Y, 0, bodyYaw, sx, sy, sx);
        let br = bodyYaw * Math.PI / 180;
        api.place(this.head, NECK_Z * Math.sin(br), hy, NECK_Z * Math.cos(br), this.headYaw, this.headPitch, 0, 1);

        this.updateFire(api, dt, sy);
        this.updateKnights(api, dt);
        this.updatePuffs(api, dt);
        for (let i = 0; i < NPOP; i++) {
            this.tAge[i] += dt;
        }
        // clouds drift right and wrap round
        for (let i = 0; i < NC; i++) {
            this.cX[i] += dt * (0.18 + 0.06 * <f64>i);
            if (this.cX[i] > 11.0) {
                this.cX[i] -= 22.0;
            }
            let cy = i == 0 ? 3.6 : (i == 1 ? 2.5 : 4.3);
            let cs = i == 0 ? 1.0 : (i == 1 ? 0.75 : 0.6);
            api.place(this.cBone[i], Math.round(this.cX[i] / 0.05) * 0.05, cy, -6.0 - <f64>i, 0, 0, 0, cs);
        }
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.mode == IDLE) {
                this.newRun(api);
            } else if (this.mode == OVER && this.overTime > 0.7) {
                this.newRun(api);
            }
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let P = api.rampColor(R_STONE, 0);
        let T = api.rampColor(R_STONE, 1);
        let Y = api.rampColor(R_STONE, 2);
        let K = api.rampColor(R_BLUSH, 1);
        let M = api.rampColor(R_SCALE, 1);
        let W = <f32>api.hudW;
        let H = <f32>api.hudH;
        let best = api.demo ? this.bestDemo : this.best;

        api.text(6, 6, "SCORE " + this.score.toString(), Y, 2, P);
        api.text(6, 20, "BEST " + best.toString(), Y, 1, P);

        // hearts, top right; the one just lost blinks
        for (let i = 0; i < 3; i++) {
            let x = W - 39.0 + <f32>(i * 9);
            let alive = i < this.hearts;
            let blink = !alive && i == this.hearts && this.hurtT < 0.9 && Math.floor(this.hurtT * 8.0) % 2.0 == 0.0;
            this.heart(api, x, 6, alive || blink ? Y : K, P);
        }
        // the fire gauge under the hearts: yellow, pink when low, purple and blinking when overheated
        let gx = W - 52.0;
        let gy: f32 = 17;
        api.rect(gx - 1, gy - 1, 48, 7, P);
        let fill = <f32>Math.round(46.0 * this.fuel);
        let col = this.fuel > 0.3 ? Y : K;
        if (this.hot) {
            col = Math.floor(api.time * 6.0) % 2.0 == 0.0 ? K : T;
        }
        if (fill > 0) {
            api.rect(gx, gy, fill, 5, col);
        }
        if (this.hot) {
            api.text(gx + 4.0, gy + 9.0, "TOO HOT!", K, 1, P);
        } else {
            api.text(gx + 14.0, gy + 9.0, "FIRE", Y, 1, P);
        }

        // floating scores
        for (let i = 0; i < NPOP; i++) {
            if (this.tAge[i] >= 0.9) {
                continue;
            }
            let rise = this.tAge[i] * 0.9;
            if (api.project(<f32>this.tX[i], <f32>(this.tY[i] + rise), <f32>this.tZ[i])) {
                let s = this.tText[i];
                let w = api.textWidth(s, 1);
                api.text(Mathf.round(api.screenX - w * 0.5), Mathf.round(api.screenY), s, Y, 1, P);
            }
        }

        if (this.mode == IDLE) {
            api.textCentered(H - 22.0, "HOLD TO BREATHE FIRE", Y, 2, P);
            api.textCentered(H - 9.0, "BURN THE KNIGHTS BEFORE THEY REACH THE TOP", P, 1, 0);
        } else if (this.mode == OVER) {
            api.rect(0, 62, W, 46, P);
            api.textCentered(68, "THE TOWER FELL!", Y, 3, 0);
            api.textCentered(88, "SCORE " + this.score.toString() + "   BEST " + best.toString(), K, 1, 0);
            if (this.overTime > 0.7 && Math.floor(this.overTime * 2.0) % 2.0 == 0.0) {
                api.textCentered(98, api.demo ? "DEMO" : "CLICK TO PLAY AGAIN", M, 1, 0);
            }
        } else if (this.runTime < 3.0 && !api.demo) {
            api.textCentered(H - 12.0, "HOLD TO BREATHE FIRE - LET GO TO RECHARGE", P, 1, 0);
        }
        if (api.demo && this.mode != OVER) {
            api.text(W - 22.0, H - 9.0, "DEMO", P, 1, 0);
        }
    }

    // a 7 x 6 pixel heart with a shadow
    private heart(api: GameApi, x: f32, y: f32, c: u32, ink: u32): void {
        for (let pass = 0; pass < 2; pass++) {
            let o: f32 = pass == 0 ? 1 : 0;
            let col = pass == 0 ? ink : c;
            api.rect(x + 1 + o, y + o, 2, 1, col);
            api.rect(x + 4 + o, y + o, 2, 1, col);
            api.rect(x + o, y + 1 + o, 7, 2, col);
            api.rect(x + 1 + o, y + 3 + o, 5, 1, col);
            api.rect(x + 2 + o, y + 4 + o, 3, 1, col);
            api.rect(x + 3 + o, y + 5 + o, 1, 1, col);
        }
    }
}
