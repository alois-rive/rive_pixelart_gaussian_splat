// Hoop Alley: a 60-second shooting run on an evening street court. Press on the ball (anywhere near
// it or below it) and flick upward: the flick's speed is the power, its slant aims left or right;
// let go to shoot. 2 points inside the arc, 3 from the far spots; Juno walks to the next spot every
// three baskets. Three in a row and she is ON FIRE: the ball glows and baskets count double (triple
// from six in a row). In the last 20 seconds the hoop slides along its wall rail. Pointer only.
import { GameApi, POINTER_DOWN, POINTER_MOVE, POINTER_UP, SFX_THUD, SFX_WHOOSH, SFX_HIT, SFX_SPLASH, SFX_CLICK,
    SFX_TICK, SFX_POP, SFX_POWERUP, SFX_WIN, SFX_NOTE, SFX_BELL, SFX_BLIP, SFX_ZAP } from "./game_api";

// ---------------------------------------------------------------- the court's numbers (art/assets.md)
const G: f64 = 9.8;
const R: f64 = 0.15;            // ball radius
const RIM_Y: f64 = 3.05;        // rim centre height (the hoop bone's pivot)
const RR: f64 = 0.335;          // rim ring radius
const TUBE: f64 = 0.045;        // rim tube radius
const BZ0: f64 = -0.54;         // backboard back face
const BZ1: f64 = -0.43;         // backboard front face
const BW: f64 = 0.9;            // backboard half width
const BY0: f64 = 2.83;          // backboard bottom, top
const BY1: f64 = 3.96;
const WALL_Z: f64 = -1.52;      // the back wall's face
const WALL_X: f64 = 4.6;        // the side walls' faces
const NET_TOP: f64 = 0.045;     // the net hangs from 0.045 under the rim centre ...
const NET_H: f64 = 0.4850;      // ... 0.485 m deep in three bands
const NET_R0: f64 = 0.33;
const NET_R1: f64 = 0.215;
const BAND_H: f64 = 0.16167;
const THETA: f64 = 60.0 * Math.PI / 180.0;   // launch elevation: a high arc drops in steeply
const RUN_T: f64 = 60.0;
const MOVE_T: f64 = 20.0;       // the hoop moves in the last 20 s
const HOOP_A: f64 = 1.25;       // ... this far each way (the rail is 5.2 m long)
const HOOP_W: f64 = 0.95;
const SPD0: f64 = 150.0;        // flick speed (HUD px/s) at power 0
const SPD_SPAN: f64 = 900.0;    // ... more at power 1; power 0.5 (600 px/s) lands on the rim's centre
const AIM_K: f64 = 0.25;        // degrees of shot per degree of flick slant
const POOL: i32 = 4;            // balls (and fire balls) in play at once
const SPARKS: i32 = 6;

const SPOT_X: StaticArray<f64> = [0.0, 1.8, -1.8, 2.6, -2.6, 0.0];
const SPOT_Z: StaticArray<f64> = [4.0, 3.6, 3.6, 5.4, 5.4, 6.2];
const SPOT_PTS: StaticArray<i32> = [2, 2, 2, 3, 3, 3];
const STREAK_NOTE: StaticArray<f64> = [67, 69, 72, 74, 76, 79, 81, 84, 86, 88, 91, 93];

// ramps (palette.json order)
const R_ASPHALT: i32 = 0;
const R_PAINT: i32 = 1;
const R_BALL: i32 = 3;
const R_KIT: i32 = 7;
const R_BLUE: i32 = 8;
const R_DUSK: i32 = 9;

// run states
const READY: i32 = 0;   // the hint; the clock waits for the first shot
const PLAY: i32 = 1;
const ENDING: i32 = 2;  // the buzzer went: balls already in the air still count
const OVER: i32 = 3;
// shooter states
const S_EMPTY: i32 = 0; // waiting for the next ball from the cart
const S_HOLD: i32 = 1;
const S_AIM: i32 = 2;   // pressed: dipping, the flick is drawn
const S_SHOT: i32 = 3;  // the jump and follow-through
const S_WALK: i32 = 4;  // to the next spot
// ball states
const B_FREE: i32 = 0;
const B_TOSS: i32 = 1;  // from the cart into Juno's hands
const B_HELD: i32 = 2;
const B_FLY: i32 = 3;

export class Game {
    run: i32 = READY;
    clock: f64 = RUN_T;
    overAt: f64 = 0;
    endT: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    made: i32 = 0;
    shots: i32 = 0;
    streak: i32 = 0;
    spot: i32 = 0;
    spotMade: i32 = 0;
    moving: bool = false;
    moveT: f64 = 0;
    hx: f64 = 0;            // the hoop's slide along the rail
    lastTick: i32 = 99;

    // bones
    hoopB: i32 = -1;
    netB: StaticArray<i32> = new StaticArray<i32>(3);
    rackB: i32 = -1;
    bodyB: i32 = -1;
    headB: i32 = -1;
    armB: StaticArray<i32> = new StaticArray<i32>(2);
    ballB: StaticArray<i32> = new StaticArray<i32>(POOL);
    fireB: StaticArray<i32> = new StaticArray<i32>(POOL);
    sparkB: StaticArray<i32> = new StaticArray<i32>(SPARKS);
    emberB: StaticArray<i32> = new StaticArray<i32>(SPARKS);

    // the shooter
    st: i32 = S_EMPTY;
    sT: f64 = 0;
    sx: f64 = 0;            // where she stands
    sz: f64 = 4.0;
    fromX: f64 = 0;
    fromZ: f64 = 4.0;
    yaw: f64 = 180;
    held: i32 = -1;
    tossWait: f64 = 0;
    cheer: f64 = 9;
    // the camera, eased to the spot's view
    cx: f64 = 0.9; cy: f64 = 2.9; cz: f64 = 10.4;
    ctx: f64 = 0.15; cty: f64 = 1.9; ctz: f64 = 0;
    snapCam: bool = true;

    // the balls
    bs: StaticArray<i32> = new StaticArray<i32>(POOL);
    px: StaticArray<f64> = new StaticArray<f64>(POOL);
    py: StaticArray<f64> = new StaticArray<f64>(POOL);
    pz: StaticArray<f64> = new StaticArray<f64>(POOL);
    vx: StaticArray<f64> = new StaticArray<f64>(POOL);
    vy: StaticArray<f64> = new StaticArray<f64>(POOL);
    vz: StaticArray<f64> = new StaticArray<f64>(POOL);
    fire: StaticArray<bool> = new StaticArray<bool>(POOL);
    spin: StaticArray<f64> = new StaticArray<f64>(POOL);
    life: StaticArray<f64> = new StaticArray<f64>(POOL);
    rimHits: StaticArray<i32> = new StaticArray<i32>(POOL);
    boardHit: StaticArray<bool> = new StaticArray<bool>(POOL);
    scored: StaticArray<bool> = new StaticArray<bool>(POOL);
    judged: StaticArray<bool> = new StaticArray<bool>(POOL);   // made or missed: decided
    inNet: StaticArray<bool> = new StaticArray<bool>(POOL);
    landed: StaticArray<bool> = new StaticArray<bool>(POOL);
    pts: StaticArray<i32> = new StaticArray<i32>(POOL);
    dirX: StaticArray<f64> = new StaticArray<f64>(POOL);       // the shot's horizontal direction
    dirZ: StaticArray<f64> = new StaticArray<f64>(POOL);
    miss: StaticArray<i32> = new StaticArray<i32>(POOL);       // 0 none, 1 short, 2 long, 3 wide
    tossX: StaticArray<f64> = new StaticArray<f64>(POOL);
    tossY: StaticArray<f64> = new StaticArray<f64>(POOL);
    tossZ: StaticArray<f64> = new StaticArray<f64>(POOL);
    rimSnd: StaticArray<f64> = new StaticArray<f64>(POOL);     // time since the last rim sound (no machine-gun)

    // the net: a damped swing (pitch, roll in degrees) and a stretch
    nP: f64 = 0; nPv: f64 = 0;
    nR: f64 = 0; nRv: f64 = 0;
    nS: f64 = 0; nSv: f64 = 0;

    // sparks (yellow: a swish burst) and embers (orange: a fire ball's trail)
    spT: StaticArray<f64> = new StaticArray<f64>(SPARKS);
    spX: StaticArray<f64> = new StaticArray<f64>(SPARKS);
    spY: StaticArray<f64> = new StaticArray<f64>(SPARKS);
    spZ: StaticArray<f64> = new StaticArray<f64>(SPARKS);
    spVX: StaticArray<f64> = new StaticArray<f64>(SPARKS);
    spVY: StaticArray<f64> = new StaticArray<f64>(SPARKS);
    spVZ: StaticArray<f64> = new StaticArray<f64>(SPARKS);
    emT: StaticArray<f64> = new StaticArray<f64>(SPARKS);
    emX: StaticArray<f64> = new StaticArray<f64>(SPARKS);
    emY: StaticArray<f64> = new StaticArray<f64>(SPARKS);
    emZ: StaticArray<f64> = new StaticArray<f64>(SPARKS);
    emNext: i32 = 0;
    emClock: f64 = 0;

    // the flick (HUD pixels)
    downX: f32 = 0; downY: f32 = 0;
    curX: f32 = 0; curY: f32 = 0;
    hT: StaticArray<f64> = new StaticArray<f64>(16);
    hX: StaticArray<f32> = new StaticArray<f32>(16);
    hY: StaticArray<f32> = new StaticArray<f32>(16);
    hN: i32 = 0;
    liveSpeed: f64 = 0;
    lastP: f64 = -1;        // the last shot's power, for the meter's ghost

    // labels over the hoop
    popT: f64 = 9;
    popS: string = "";
    popC: i32 = 0;          // 0 white, 1 yellow, 2 orange, 3 grey
    popX: f32 = 0; popY: f32 = 0;
    bannerT: f64 = 9;
    bannerS: string = "";

    // demo
    dWait: f64 = 0.5;
    dP: f64 = 0.5;
    dAng: f64 = 0;
    dAim: bool = false;
    dFlickT: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        this.hoopB = api.bone("hoop");
        this.rackB = api.bone("rack");
        this.bodyB = api.bone("body");
        this.headB = api.bone("head");
        for (let k = 0; k < 3; k++) {
            this.netB[k] = api.bone("net" + k.toString());
        }
        this.armB[0] = api.bone("arm0");
        this.armB[1] = api.bone("arm1");
        for (let i = 0; i < POOL; i++) {
            this.ballB[i] = api.bone("ball" + i.toString());
            this.fireB[i] = api.bone("fire" + i.toString());
        }
        for (let i = 0; i < SPARKS; i++) {
            this.sparkB[i] = api.bone("spark" + i.toString());
            this.emberB[i] = api.bone("ember" + i.toString());
            this.spT[i] = 9;
            this.emT[i] = 9;
        }
        this.newRun(api);
    }

    // ---------------------------------------------------------------- runs

    newRun(api: GameApi): void {
        this.run = api.demo ? PLAY : READY;
        this.clock = RUN_T;
        this.score = 0;
        this.made = 0;
        this.shots = 0;
        this.streak = 0;
        this.spot = 0;
        this.spotMade = 0;
        this.moving = false;
        this.moveT = 0;
        this.lastTick = 99;
        this.sx = SPOT_X[0];
        this.sz = SPOT_Z[0];
        this.fromX = this.sx;
        this.fromZ = this.sz;
        this.popT = 9;
        this.bannerT = 9;
        this.lastP = -1;
        this.hN = 0;
        for (let i = 0; i < POOL; i++) {
            this.bs[i] = B_FREE;
        }
        this.held = 0;
        this.bs[0] = B_HELD;
        this.fire[0] = false;
        this.st = S_HOLD;
        this.sT = 0;
        this.dWait = 0.15;
        this.dAim = false;
        this.snapCam = true;
        if (api.demo) {
            // the demo opens with a ball already on its way: action in the first second
            this.demoShot(api, 0.53, 0.4);
            this.sT = 0.22;
            let b = this.lastShot;
            for (let k = 0; k < 20; k++) {
                this.stepBall(api, b, 1.0 / 60.0);
            }
            this.tossWait = 0.05;
        }
    }

    finish(api: GameApi): void {
        this.run = OVER;
        this.overAt = api.time;
        if (this.score > this.best && !api.demo) {     // the demo's runs never set a visitor's best
            this.best = this.score;
            if (this.score > 0) {
                api.sound(SFX_WIN, 1.0, 0.7, 0, 0.1);
            }
        }
    }

    // ---------------------------------------------------------------- the frame

    update(api: GameApi): void {
        if (api.demoChanged) {
            this.newRun(api);
        }
        let dt = api.dt;
        // the clock
        if (this.run == PLAY) {
            this.clock -= dt;
            if (!this.moving && this.clock <= MOVE_T) {
                this.moving = true;
                this.moveT = 0;
                this.banner("MOVING HOOP!");
                api.soundAt(SFX_ZAP, this.hx, RIM_Y, 0, 0.5, 0.45);
                api.note(76, 0.4, 0, SFX_BELL, 0.1);
            }
            let sec = <i32>Math.ceil(this.clock);
            if (sec <= 5 && sec >= 1 && sec != this.lastTick) {
                this.lastTick = sec;
                api.sound(SFX_TICK, 0.5, 0.9);
            }
            if (this.clock <= 0) {
                this.clock = 0;
                this.run = ENDING;
                this.endT = 0;
                this.buzzer(api);
            }
        } else if (this.run == ENDING) {
            this.endT += dt;
            let flying = false;
            for (let i = 0; i < POOL; i++) {
                if (this.bs[i] == B_FLY && !this.judged[i]) {
                    flying = true;
                }
            }
            if ((!flying && this.endT > 0.8) || this.endT > 3.0) {
                this.finish(api);
            }
        } else if (this.run == OVER) {
            if (api.demo && api.time - this.overAt > 2.0) {
                this.newRun(api);
            }
        }
        // the hoop slides in the last 20 s, and back to the middle after
        if (this.moving && this.run == PLAY) {
            this.moveT += dt;
            this.hx = HOOP_A * Math.sin(HOOP_W * this.moveT);
        } else {
            this.hx += (0 - this.hx) * Math.min(1, dt * 2.0);
        }
        this.cheer += dt;
        this.popT += dt;
        this.bannerT += dt;
        this.updateShooter(api, dt);
        for (let i = 0; i < POOL; i++) {
            for (let k = 0; k < 4; k++) {
                this.stepBall(api, i, dt * 0.25);
            }
            this.rimSnd[i] += dt;
        }
        this.updateNet(dt);
        this.updateSparks(api, dt);
        if (api.demo) {
            this.demoPlay(api, dt);
        }
        this.updateCamera(api, dt);
        this.draw(api);
    }

    banner(s: string): void {
        this.bannerS = s;
        this.bannerT = 0;
    }

    // the buzzer: low square blips back to back (a raw 167 Hz drone, 0.9 s) over a rasp of ticks
    buzzer(api: GameApi): void {
        for (let k = 0; k < 15; k++) {
            api.sound(SFX_BLIP, 0.19, 1.0, 0, <f64>k * 0.06);
            api.sound(SFX_TICK, 0.075, 1.0, 0, <f64>k * 0.06 + 0.03);
        }
    }

    // ---------------------------------------------------------------- the shooter

    rackX(): f64 {
        return this.sx - 1.15;
    }

    rackZ(): f64 {
        return this.sz + 0.55;
    }

    faceYaw(): f64 {
        return Math.atan2(this.hx - this.sx, 0 - this.sz) * 180.0 / Math.PI;
    }

    updateShooter(api: GameApi, dt: f64): void {
        this.sT += dt;
        let st = this.st;
        if (st == S_WALK) {
            let u = Math.min(1, this.sT / 1.0);
            let e = u * u * (3 - 2 * u);
            this.sx = this.fromX + (SPOT_X[this.spot] - this.fromX) * e;
            this.sz = this.fromZ + (SPOT_Z[this.spot] - this.fromZ) * e;
            if (api.frame % 7 == 0) {
                api.soundAt(SFX_TICK, this.rackX(), 0.2, this.rackZ(), 0.3, 0.35);   // the cart's wheels
            }
            if (u >= 1) {
                this.st = S_HOLD;
                this.sT = 0;
                this.dWait = 0.25;
                let p3 = SPOT_PTS[this.spot] == 3;
                this.banner(p3 ? "3 POINT SPOT" : "2 POINT SPOT");
                api.sound(SFX_BLIP, p3 ? 1.2 : 0.9, 0.4);
            }
        } else if (st == S_SHOT) {
            if (this.sT > 0.42) {
                this.st = S_EMPTY;
                this.sT = 0;
                this.tossWait = 0.12;
            }
        } else if (st == S_EMPTY) {
            if (this.run == PLAY || this.run == READY) {
                this.tossWait -= dt;
                if (this.tossWait <= 0) {
                    this.toss(api);
                }
            }
        } else if (st == S_HOLD) {
            // three baskets from one spot: walk to the next
            if (this.run == PLAY && this.spotMade >= 3) {
                this.spotMade = 0;
                this.fromX = this.sx;
                this.fromZ = this.sz;
                this.spot = (this.spot + 1) % 6;
                this.st = S_WALK;
                this.sT = 0;
            }
        }
        this.yaw = this.faceYaw();
        // a ball on its way from the cart
        for (let i = 0; i < POOL; i++) {
            if (this.bs[i] == B_TOSS) {
                this.life[i] += dt;
                if (this.life[i] >= 0.36) {
                    this.bs[i] = B_HELD;
                    this.held = i;
                    this.st = S_HOLD;
                    this.sT = 0;
                    this.dWait = api.range(0.15, 0.35);
                    api.soundAt(SFX_POP, this.sx, 1.8, this.sz, 0.5, 0.45);   // the catch
                }
            }
        }
    }

    // the cart lobs the next ball into her hands
    toss(api: GameApi): void {
        let b = -1;
        for (let i = 0; i < POOL; i++) {
            if (this.bs[i] == B_FREE) {
                b = i;
                break;
            }
        }
        if (b < 0) {
            // every ball is out: take back the one that has been rolling longest
            let oldest = -1.0;
            for (let i = 0; i < POOL; i++) {
                if (this.bs[i] == B_FLY && this.judged[i] && this.life[i] > oldest) {
                    oldest = this.life[i];
                    b = i;
                }
            }
            if (b < 0) {
                this.tossWait = 0.1;
                return;
            }
        }
        this.bs[b] = B_TOSS;
        this.life[b] = 0;
        this.tossX[b] = this.rackX();
        this.tossY[b] = 0.95;
        this.tossZ[b] = this.rackZ();
        this.fire[b] = false;
        this.st = S_EMPTY;
        this.tossWait = 99;
        api.soundAt(SFX_THUD, this.rackX(), 0.5, this.rackZ(), 1.6, 0.3);
    }

    // the ball's hold point in her own frame (feet at the origin, facing +Z, her right at -X)
    holdY(): f64 {
        if (this.st == S_AIM) {
            return 1.8;
        }
        return 1.92;
    }

    // ---------------------------------------------------------------- shooting

    power(speed: f64): f64 {
        return (speed - SPD0) / SPD_SPAN;
    }

    lastShot: i32 = 0;

    // launches the held ball: p the power (0.5 lands on the rim's centre), ang a yaw offset in degrees
    shoot(api: GameApi, p: f64, ang: f64): void {
        let b = this.held;
        if (b < 0) {
            return;
        }
        this.lastShot = b;
        let x0 = this.px[b], y0 = this.py[b], z0 = this.pz[b];
        let dx = this.hx - x0, dz = 0 - z0;
        let D = Math.sqrt(dx * dx + dz * dz);
        let span = 1.6 + 0.25 * D;
        let pp = Math.min(1.25, Math.max(-0.2, p));
        let rint = Math.max(1.2, D + (pp - 0.5) * span);
        let h = RIM_Y - y0;
        let c = Math.cos(THETA);
        let den = 2 * c * c * (rint * Math.tan(THETA) - h);
        let v = Math.sqrt(G * rint * rint / Math.max(0.2, den));
        let yw = Math.atan2(dx, -dz) + ang * Math.PI / 180.0;
        let vh = v * c;
        this.vx[b] = vh * Math.sin(yw);
        this.vy[b] = v * Math.sin(THETA);
        this.vz[b] = -vh * Math.cos(yw);
        this.dirX[b] = Math.sin(yw);
        this.dirZ[b] = -Math.cos(yw);
        this.bs[b] = B_FLY;
        this.fire[b] = this.streak >= 3;
        this.life[b] = 0;
        this.rimHits[b] = 0;
        this.boardHit[b] = false;
        this.scored[b] = false;
        this.judged[b] = false;
        this.inNet[b] = false;
        this.landed[b] = false;
        this.miss[b] = 0;
        this.rimSnd[b] = 9;
        this.pts[b] = SPOT_PTS[this.spot];
        this.held = -1;
        this.st = S_SHOT;
        this.sT = 0;
        this.shots++;
        this.lastP = pp;
        if (this.run == READY) {
            this.run = PLAY;     // the first shot starts the clock
        }
        api.soundAt(SFX_WHOOSH, x0, y0, z0, 0.8 + 0.5 * Math.max(0, pp), 0.5);
    }

    // the physics of one ball, one sub-step
    stepBall(api: GameApi, i: i32, dt: f64): void {
        if (this.bs[i] != B_FLY) {
            return;
        }
        this.life[i] += dt;
        let hx = this.hx;
        let oy = this.py[i];
        this.vy[i] -= G * dt;
        // rolling back: after the first bounce the ball drifts back to the cart
        if (this.landed[i]) {
            let ax = this.rackX() - this.px[i], az = this.rackZ() - this.pz[i];
            let d = Math.sqrt(ax * ax + az * az);
            if (d < 0.55 || this.life[i] > 7.0) {
                this.bs[i] = B_FREE;
                return;
            }
            let k = 1.6 * dt / Math.max(0.3, d);
            this.vx[i] += ax * k;
            this.vz[i] += az * k;
            let sp = Math.sqrt(this.vx[i] * this.vx[i] + this.vz[i] * this.vz[i]);
            if (sp > 3.0) {
                this.vx[i] *= 3.0 / sp;
                this.vz[i] *= 3.0 / sp;
            }
        }
        this.px[i] += this.vx[i] * dt;
        this.py[i] += this.vy[i] * dt;
        this.pz[i] += this.vz[i] * dt;
        let x = this.px[i], y = this.py[i], z = this.pz[i];
        // the rim: a torus round (hx, RIM_Y, 0)
        let rx = x - hx, rz = z;
        let rh = Math.sqrt(rx * rx + rz * rz);
        let qx = hx + (rh > 1e-6 ? rx / rh * RR : RR), qz = rh > 1e-6 ? rz / rh * RR : 0.0;
        let nx = x - qx, ny = y - RIM_Y, nz = z - qz;
        let d = Math.sqrt(nx * nx + ny * ny + nz * nz);
        if (d < R + TUBE && d > 1e-6) {
            nx /= d; ny /= d; nz /= d;
            let pen = R + TUBE - d;
            this.px[i] += nx * pen; this.py[i] += ny * pen; this.pz[i] += nz * pen;
            let vn = this.vx[i] * nx + this.vy[i] * ny + this.vz[i] * nz;
            if (vn < 0) {
                this.bounce(i, nx, ny, nz, vn, 0.5, 0.85);
                this.rimHits[i]++;
                this.nPv += nz * vn * 60.0;
                this.nRv -= nx * vn * 60.0;
                if (-vn > 0.6 && this.rimSnd[i] > 0.08) {
                    this.rimSnd[i] = 0;
                    let vol = Math.min(1.0, -vn / 5.0);
                    api.soundAt(SFX_HIT, qx, RIM_Y, qz, 2.3, 0.3 + 0.4 * vol);     // the clang
                    api.noteAt(86, qx, RIM_Y, qz, 0.25 + 0.3 * vol, SFX_NOTE);
                    this.rattle(api, 0.25 + 0.2 * vol);
                }
            }
        }
        // the backboard: a box
        x = this.px[i]; y = this.py[i]; z = this.pz[i];
        let bx = Math.min(Math.max(x, hx - BW), hx + BW);
        let by = Math.min(Math.max(y, BY0), BY1);
        let bz = Math.min(Math.max(z, BZ0), BZ1);
        nx = x - bx; ny = y - by; nz = z - bz;
        d = Math.sqrt(nx * nx + ny * ny + nz * nz);
        if (d < R && d > 1e-6) {
            nx /= d; ny /= d; nz /= d;
            let pen = R - d;
            this.px[i] += nx * pen; this.py[i] += ny * pen; this.pz[i] += nz * pen;
            let vn = this.vx[i] * nx + this.vy[i] * ny + this.vz[i] * nz;
            if (vn < 0) {
                this.bounce(i, nx, ny, nz, vn, 0.55, 0.9);
                if (-vn > 0.8) {
                    this.boardHit[i] = true;
                    api.soundAt(SFX_THUD, bx, by, bz, 0.75, 0.25 + 0.4 * Math.min(1.0, -vn / 6.0));   // the board
                }
            }
        }
        // the walls
        if (this.pz[i] < WALL_Z + R) {
            this.pz[i] = WALL_Z + R;
            if (this.vz[i] < 0) {
                this.vz[i] = -this.vz[i] * 0.6;
                api.soundAt(SFX_THUD, this.px[i], this.py[i], WALL_Z, 1.1, 0.3);
            }
        }
        if (this.px[i] < -WALL_X + R) {
            this.px[i] = -WALL_X + R;
            this.vx[i] = Math.abs(this.vx[i]) * 0.6;
        }
        if (this.px[i] > WALL_X - R) {
            this.px[i] = WALL_X - R;
            this.vx[i] = -Math.abs(this.vx[i]) * 0.6;
        }
        // through the hoop: down across the rim's plane, inside the ring
        x = this.px[i]; y = this.py[i]; z = this.pz[i];
        let rd = Math.sqrt((x - hx) * (x - hx) + z * z);
        if (oy >= RIM_Y && y < RIM_Y) {
            if (rd < RR && !this.judged[i]) {
                this.inNet[i] = true;
                this.score1(api, i);
            } else if (!this.judged[i] && this.miss[i] == 0) {
                // a miss to come: how it went past (for the label)
                let ax = x - hx, az = z;
                let along = ax * this.dirX[i] + az * this.dirZ[i];
                let side = ax * this.dirZ[i] - az * this.dirX[i];
                this.miss[i] = Math.abs(side) > Math.abs(along) ? 3 : (along < 0 ? 1 : 2);
            }
        }
        // the net: a funnel that slows the ball
        if (this.inNet[i]) {
            let depth = RIM_Y - NET_TOP - y;
            if (depth > -0.1 && depth < NET_H) {
                let rn = NET_R0 + (NET_R1 - NET_R0) * Math.max(0, depth) / NET_H - R + 0.02;
                let ax = x - hx, az = z;
                let ad = Math.sqrt(ax * ax + az * az);
                if (ad > rn && ad > 1e-6) {
                    this.px[i] = hx + ax / ad * rn;
                    this.pz[i] = az / ad * rn;
                    let vr = (this.vx[i] * ax + this.vz[i] * az) / ad;
                    if (vr > 0) {
                        this.vx[i] -= vr * ax / ad * 1.2;
                        this.vz[i] -= vr * az / ad * 1.2;
                    }
                }
                let k = Math.exp(-5.0 * dt);
                this.vx[i] *= k;
                this.vz[i] *= k;
                if (this.vy[i] < -1.2) {
                    this.vy[i] *= Math.exp(-7.0 * dt);
                }
                this.nSv += 1.6 * dt * 60.0 * 0.05;
            } else if (depth >= NET_H) {
                this.inNet[i] = false;
            }
        }
        // the ground
        if (this.py[i] < R) {
            this.py[i] = R;
            if (this.vy[i] < 0) {
                let imp = -this.vy[i];
                if (imp > 0.5) {
                    api.soundAt(SFX_THUD, this.px[i], 0, this.pz[i], 1.5, Math.min(0.8, 0.15 + imp * 0.1));   // the bounce
                }
                this.vy[i] = imp > 0.6 ? imp * 0.7 : 0;
                this.vx[i] *= 0.88;
                this.vz[i] *= 0.88;
                if (!this.judged[i]) {
                    this.missed(api, i);
                }
                this.landed[i] = true;
            }
        }
        // spin: backspin in flight, rolling on the ground
        let hs = Math.sqrt(this.vx[i] * this.vx[i] + this.vz[i] * this.vz[i]);
        this.spin[i] += (this.landed[i] && this.py[i] < R + 0.02 ? hs / R * 57.3 : 540.0) * dt;
    }

    bounce(i: i32, nx: f64, ny: f64, nz: f64, vn: f64, e: f64, keep: f64): void {
        let tx = this.vx[i] - vn * nx, ty = this.vy[i] - vn * ny, tz = this.vz[i] - vn * nz;
        this.vx[i] = tx * keep - e * vn * nx;
        this.vy[i] = ty * keep - e * vn * ny;
        this.vz[i] = tz * keep - e * vn * nz;
    }

    // the chain net rattles: clicks at fixed little intervals
    rattle(api: GameApi, vol: f64): void {
        api.soundAt(SFX_CLICK, this.hx, RIM_Y - 0.2, 0, 1.4, vol);
        api.soundAt(SFX_CLICK, this.hx, RIM_Y - 0.2, 0, 1.1, vol * 0.8, 0.05);
        api.soundAt(SFX_CLICK, this.hx, RIM_Y - 0.2, 0, 1.3, vol * 0.7, 0.11);
        api.soundAt(SFX_CLICK, this.hx, RIM_Y - 0.2, 0, 1.0, vol * 0.5, 0.18);
    }

    score1(api: GameApi, i: i32): void {
        this.judged[i] = true;
        this.scored[i] = true;
        let mult = this.fire[i] ? (this.streak >= 6 ? 3 : 2) : 1;
        let p = this.pts[i] * mult;
        this.score += p;
        this.made++;
        this.streak++;
        this.spotMade++;
        this.cheer = 0;
        let swish = this.rimHits[i] == 0 && !this.boardHit[i];
        let s = "+" + p.toString();
        if (swish) {
            s = "SWISH +" + p.toString();
        } else if (this.boardHit[i]) {
            s = "BANK +" + p.toString();
        }
        this.pop(api, s, mult > 1 ? 2 : (swish ? 1 : 0));
        this.nSv += 2.4;
        this.nPv += this.vz[i] * -40.0;
        this.nRv += this.vx[i] * 40.0;
        // sounds: the swish (soft noise), the chains, a note that climbs with the streak
        if (swish) {
            api.soundAt(SFX_SPLASH, this.hx, RIM_Y, 0, 1.7, 0.32);
        }
        this.rattle(api, 0.55);
        let n = STREAK_NOTE[min<i32>(this.streak - 1, 11)];
        api.noteAt(n, this.hx, RIM_Y, 0, 0.5, SFX_NOTE, 0.06);
        if (this.streak == 3) {
            this.banner("ON FIRE!");
            api.sound(SFX_POWERUP, 1.0, 0.6, 0, 0.12);
        } else if (this.streak == 6) {
            this.banner("BLAZING x3!");
            api.sound(SFX_POWERUP, 1.33, 0.6, 0, 0.12);
        }
        if (this.run == ENDING) {
            this.banner("BUZZER BEATER!");
            api.note(84, 0.5, 0, SFX_BELL, 0.1);
        }
        // a burst of sparks under the net for a swish or a fire ball
        if (swish || this.fire[i]) {
            for (let k = 0; k < SPARKS; k++) {
                let a = <f64>k * Math.PI * 2.0 / <f64>SPARKS + api.time;
                this.spT[k] = 0;
                this.spX[k] = this.hx;
                this.spY[k] = RIM_Y - 0.4;
                this.spZ[k] = 0;
                this.spVX[k] = Math.cos(a) * 1.4;
                this.spVY[k] = 1.2 + 0.3 * <f64>(k % 3);
                this.spVZ[k] = Math.sin(a) * 1.4;
            }
        }
    }

    missed(api: GameApi, i: i32): void {
        this.judged[i] = true;
        let s = "MISS";
        if (this.rimHits[i] > 0) {
            s = "RIM OUT";
        } else if (this.miss[i] == 1 || (this.miss[i] == 0 && !this.boardHit[i])) {
            s = this.boardHit[i] ? "OFF THE BOARD" : (this.miss[i] == 0 ? "AIRBALL" : "SHORT");
        } else if (this.miss[i] == 2) {
            s = this.boardHit[i] ? "OFF THE BOARD" : "LONG";
        } else if (this.miss[i] == 3) {
            s = "WIDE";
        }
        if (this.streak >= 3) {
            api.sound(SFX_BLIP, 0.5, 0.4);   // the fire goes out
        }
        this.streak = 0;
        this.pop(api, s, 3);
    }

    pop(api: GameApi, s: string, c: i32): void {
        this.popS = s;
        this.popC = c;
        this.popT = 0;
        if (api.project(<f32>this.hx, <f32>(RIM_Y + 1.1), -0.4)) {
            this.popX = api.screenX;
            this.popY = api.screenY;
        }
    }

    // ---------------------------------------------------------------- the net and the sparks

    updateNet(dt: f64): void {
        let k = 90.0, c = 7.0;
        this.nPv += (-k * this.nP - c * this.nPv) * dt;
        this.nP += this.nPv * dt;
        this.nRv += (-k * this.nR - c * this.nRv) * dt;
        this.nR += this.nRv * dt;
        this.nSv += (-140.0 * this.nS - 10.0 * this.nSv) * dt;
        this.nS += this.nSv * dt;
        this.nP = Math.min(30, Math.max(-30, this.nP));
        this.nR = Math.min(30, Math.max(-30, this.nR));
        this.nS = Math.min(0.6, Math.max(-0.2, this.nS));
    }

    updateSparks(api: GameApi, dt: f64): void {
        for (let k = 0; k < SPARKS; k++) {
            this.spT[k] += dt;
            this.spVY[k] -= G * 0.5 * dt;
            this.spX[k] += this.spVX[k] * dt;
            this.spY[k] += this.spVY[k] * dt;
            this.spZ[k] += this.spVZ[k] * dt;
            this.emT[k] += dt;
            this.emY[k] += 0.4 * dt;
        }
        // embers trail the fire balls in flight
        this.emClock += dt;
        if (this.emClock > 0.05) {
            this.emClock = 0;
            for (let i = 0; i < POOL; i++) {
                if (this.bs[i] == B_FLY && this.fire[i] && !this.landed[i]) {
                    let e = this.emNext;
                    this.emNext = (this.emNext + 1) % SPARKS;
                    this.emT[e] = 0;
                    this.emX[e] = this.px[i] - this.vx[i] * 0.03;
                    this.emY[e] = this.py[i] - this.vy[i] * 0.03;
                    this.emZ[e] = this.pz[i] - this.vz[i] * 0.03;
                }
            }
        }
    }

    // ---------------------------------------------------------------- camera

    updateCamera(api: GameApi, dt: f64): void {
        let ex = Math.min(3.0, Math.max(-3.0, this.sx * 0.65 + 0.9));
        let ez = this.sz + 6.4;
        let tx = this.sx * 0.28 + 0.15;
        let k = this.snapCam ? 1.0 : Math.min(1, dt * 3.0);
        this.snapCam = false;
        this.cx += (ex - this.cx) * k;
        this.cz += (ez - this.cz) * k;
        this.ctx += (tx - this.ctx) * k;
        api.lookAt = true;
        api.perspective = true;
        api.eyeX = this.cx;
        api.eyeY = this.cy;
        api.eyeZ = this.cz;
        api.useTarget = true;
        api.targetX = this.ctx;
        api.targetY = this.cty;
        api.targetZ = this.ctz;
    }

    // ---------------------------------------------------------------- placing everything

    draw(api: GameApi): void {
        let yaw = this.yaw;
        let st = this.st;
        // the body: a dip while aiming, a jump on the shot, a bob while walking (stepped at 12 fps)
        let jump = 0.0, sq = 1.0;
        if (st == S_AIM) {
            sq = 0.93;
        } else if (st == S_SHOT) {
            let u = stepped(this.sT, 1.0 / 12.0) / 0.42;
            jump = 0.26 * Math.sin(Math.min(1, u) * Math.PI);
            sq = u < 0.15 ? 0.95 : 1.04;
        } else if (st == S_WALK) {
            jump = 0.05 * Math.abs(Math.sin(stepped(this.sT, 1.0 / 12.0) * 9.0));
        } else if (this.cheer < 0.5 && st == S_EMPTY) {
            jump = 0.12 * Math.sin(Math.min(1.0, this.cheer / 0.5) * Math.PI);
        }
        let b = this.bodyB;
        let rx = <f64>api.restX[b], ry = <f64>api.restY[b], rz = <f64>api.restZ[b];
        api.placeScaled(b, this.sx, jump, this.sz, yaw, 1, sq, 1);
        api.transform(b, rx, ry + 1.36, rz);
        let lean = st == S_AIM ? -4.0 : (st == S_SHOT ? 6.0 : 0.0);
        api.place(this.headB, api.tx, api.ty, api.tz, yaw, lean);
        // the ball in her hands (her frame): above her right brow; lower in the dip
        let hbx = -0.06, hby = this.holdY(), hbz = 0.16;
        // hand targets, per pose
        let lx = 0.0, ly = 0.0, lz = 0.0, qx = 0.0, qy = 0.0, qz = 0.0;
        let hasBall = st == S_HOLD || st == S_AIM || st == S_WALK;
        if (hasBall) {
            qx = hbx - 0.1; qy = hby - 0.1; qz = hbz - 0.04;    // right hand under and behind the ball
            lx = hbx + 0.15; ly = hby; lz = hbz;                 // left hand on its side
        } else if (st == S_SHOT) {
            // follow-through: both arms up, the shooting hand forward
            qx = -0.2; qy = 1.95; qz = 0.32;
            lx = 0.2; ly = 1.85; lz = 0.18;
        } else {
            // empty: arms down and a little out; raised to catch the cart's ball as it comes
            let up = 0.0;
            for (let i = 0; i < POOL; i++) {
                if (this.bs[i] == B_TOSS) {
                    up = Math.min(1.0, this.life[i] / 0.3);
                }
            }
            if (this.cheer < 0.6) {
                qx = -0.38; qy = 1.95; qz = 0.1;   // a fist up for a basket
            } else {
                qx = -0.4 + 0.3 * up; qy = 0.75 + 1.0 * up; qz = 0.1 + 0.1 * up;
            }
            lx = 0.4 - 0.25 * up; ly = 0.75 + 1.1 * up; lz = 0.1 + 0.1 * up;
        }
        if (st == S_WALK) {
            let sw = Math.sin(stepped(this.sT, 1.0 / 12.0) * 9.0) * 0.06;
            qz += sw;
            lz -= sw;
        }
        this.aimArm(api, this.armB[0], -0.29, 1.25, qx, qy, qz, yaw);
        this.aimArm(api, this.armB[1], 0.29, 1.25, lx, ly, lz, yaw);
        // the cart
        api.place(this.rackB, this.rackX(), 0, this.rackZ(), (yaw - 180.0) * 0.5);
        // the hoop and its net
        api.place(this.hoopB, this.hx, RIM_Y, 0);
        let hy = RIM_Y - NET_TOP, hxx = this.hx, hz = 0.0;
        let sy = 1.0 + this.nS;
        for (let k = 0; k < 3; k++) {
            let nb = this.netB[k];
            let f = <f64>(k + 1) * 0.6;
            api.placeScaled(nb, hxx, hy, hz, 0, 1.0 - this.nS * 0.15 * <f64>k, sy, 1.0 - this.nS * 0.15 * <f64>k,
                stepped(this.nP * f, 2.0), stepped(this.nR * f, 2.0));
            api.transform(nb, <f64>api.restX[nb], <f64>api.restY[nb] - BAND_H, <f64>api.restZ[nb]);
            hxx = api.tx; hy = api.ty; hz = api.tz;
        }
        // the balls
        for (let i = 0; i < POOL; i++) {
            let s = this.bs[i];
            let nb = this.ballB[i], fb = this.fireB[i];
            if (s == B_FREE) {
                api.hide(nb);
                api.hide(fb);
                continue;
            }
            if (s == B_HELD) {
                api.transform(b, rx + hbx, ry + hby, rz + hbz);   // her baked frame: transform turns it
                this.px[i] = api.tx; this.py[i] = api.ty; this.pz[i] = api.tz;
                this.fire[i] = this.streak >= 3;
            } else if (s == B_TOSS) {
                let u = Math.min(1.0, this.life[i] / 0.36);
                api.transform(b, rx + hbx, ry + hby, rz + hbz);
                this.px[i] = this.tossX[i] + (api.tx - this.tossX[i]) * u;
                this.py[i] = this.tossY[i] + (api.ty - this.tossY[i]) * u + Math.sin(u * Math.PI) * 0.7;
                this.pz[i] = this.tossZ[i] + (api.tz - this.tossZ[i]) * u;
                this.spin[i] += 600.0 * api.dt;
            }
            let on = this.fire[i] ? fb : nb;
            let off = this.fire[i] ? nb : fb;
            api.hide(off);
            api.place(on, this.px[i], this.py[i], this.pz[i], 0, stepped(this.spin[i], 30.0));
        }
        // sparks and embers
        for (let k = 0; k < SPARKS; k++) {
            if (this.spT[k] < 0.6) {
                api.place(this.sparkB[k], this.spX[k], this.spY[k], this.spZ[k]);
            } else {
                api.hide(this.sparkB[k]);
            }
            if (this.emT[k] < 0.25) {
                let s = 1.0 - this.emT[k] * 2.4;
                api.place(this.emberB[k], this.emX[k], this.emY[k], this.emZ[k], 0, 0, 0, Math.max(0.3, s));
            } else {
                api.hide(this.emberB[k]);
            }
        }
    }

    // points an arm (pivot at the shoulder, hanging along -Y at rest) from her shoulder (her frame)
    // at a hand target (her frame); the body's transform carries both into the world
    aimArm(api: GameApi, arm: i32, sx: f64, sy: f64, tx: f64, ty: f64, tz: f64, yaw: f64): void {
        let b = this.bodyB;
        let rx = <f64>api.restX[b], ry = <f64>api.restY[b], rz = <f64>api.restZ[b];
        let dx = tx - sx, dy = ty - sy, dz = tz;
        let l = Math.sqrt(dx * dx + dy * dy + dz * dz);
        if (l < 1e-4) {
            l = 1e-4;
        }
        dx /= l; dy /= l; dz /= l;
        // her frame -> the arm's rotation: dir = (sin r, -cos r cos p, -cos r sin p)
        let r = Math.asin(Math.min(1, Math.max(-1, dx)));
        let p = Math.atan2(-dz, -dy);
        api.transform(b, rx + sx, ry + sy, rz);
        api.place(arm, api.tx, api.ty, api.tz, yaw, stepped(p * 180.0 / Math.PI, 7.5), stepped(r * 180.0 / Math.PI, 7.5));
    }

    // ---------------------------------------------------------------- the pointer

    ballScreen(api: GameApi): bool {
        let b = this.held;
        if (b < 0) {
            return false;
        }
        return api.project(<f32>this.px[b], <f32>this.py[b], <f32>this.pz[b]);
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) {
            if (this.run == OVER) {
                if (api.time - this.overAt > 0.8) {
                    this.newRun(api);
                    api.note(88, 0.4, 0, SFX_NOTE);       // a whistle: a new run
                    api.note(91, 0.4, 0, SFX_NOTE, 0.09);
                }
                return true;
            }
            if (this.st == S_HOLD && (this.run == READY || this.run == PLAY) && this.ballScreen(api)) {
                // a generous grab: near the ball, or anywhere below it
                let dx = x - api.screenX, dy = y - api.screenY;
                if (dx * dx + dy * dy < 48 * 48 || y > api.screenY - 8) {
                    this.st = S_AIM;
                    this.sT = 0;
                    this.downX = x; this.downY = y;
                    this.curX = x; this.curY = y;
                    this.hN = 0;
                    this.liveSpeed = 0;
                    this.sample(api, x, y);
                    api.sound(SFX_CLICK, 0.6, 0.4);   // the ball in hand
                }
            }
        } else if (kind == POINTER_MOVE) {
            if (this.st == S_AIM) {
                this.curX = x; this.curY = y;
                this.sample(api, x, y);
            }
        } else if (kind == POINTER_UP) {
            if (this.st == S_AIM) {
                this.curX = x; this.curY = y;
                // a lift right after the last move (the up event often comes a frame later at the same
                // spot) is not a pause: only a lift that moved, or came later, is a new sample
                let li = (this.hN - 1) % 16;
                if (this.hN == 0 || this.hX[li] != x || this.hY[li] != y || api.time - this.hT[li] > 0.034) {
                    this.sample(api, x, y);
                }
                let sp = this.flickSpeed(api);
                let up = this.downY - y;
                if (up < 8 || this.fvy > -20) {
                    this.st = S_HOLD;            // not a flick: put the ball back up
                    this.sT = 0;
                } else {
                    let ang = Math.atan2(this.fvx, -this.fvy) * 180.0 / Math.PI;
                    ang = Math.min(40, Math.max(-40, ang));
                    this.shoot(api, this.power(sp), ang * AIM_K);
                }
            }
        }
        return true;
    }

    sample(api: GameApi, x: f32, y: f32): void {
        let k = this.hN % 16;
        this.hT[k] = api.time;
        this.hX[k] = x;
        this.hY[k] = y;
        this.hN++;
        this.liveSpeed = this.flickSpeed(api);
    }

    fvx: f64 = 0;
    fvy: f64 = 0;

    // the pointer's velocity over the last ~0.08 s (HUD px/s): fvx, fvy; returns its length
    flickSpeed(api: GameApi): f64 {
        let n = min<i32>(this.hN, 16);
        if (n < 2) {
            this.fvx = 0; this.fvy = 0;
            return 0;
        }
        let last = (this.hN - 1) % 16;
        let t1 = this.hT[last];
        let j = last;
        for (let k = 1; k < n; k++) {
            let i = (this.hN - 1 - k) % 16;
            j = i;
            if (t1 - this.hT[i] >= 0.08) {
                break;
            }
        }
        let dtt = Math.max(1.0 / 60.0, t1 - this.hT[j]);
        this.fvx = <f64>(this.hX[last] - this.hX[j]) / dtt;
        this.fvy = <f64>(this.hY[last] - this.hY[j]) / dtt;
        return Math.sqrt(this.fvx * this.fvx + this.fvy * this.fvy);
    }

    // ---------------------------------------------------------------- the demo player

    demoShot(api: GameApi, p: f64, ang: f64): void {
        if (this.held < 0) {
            return;
        }
        // the hold point (her frame: -0.06, 1.92, 0.16) turned by her yaw
        let b = this.held;
        let yw = this.faceYaw() * Math.PI / 180.0;
        let c = Math.cos(yw), s = Math.sin(yw);
        this.px[b] = this.sx + c * -0.06 + s * 0.16;
        this.py[b] = 1.92;
        this.pz[b] = this.sz - s * -0.06 + c * 0.16;
        this.shoot(api, p, ang);
    }

    demoPlay(api: GameApi, dt: f64): void {
        // a decent player: a steady touch with a little error in power and aim; leads the moving hoop
        if (this.run != PLAY) {
            return;
        }
        if (this.st == S_HOLD) {
            this.dWait -= dt;
            if (this.dWait > 0) {
                return;
            }
            let e = (api.rand() + api.rand() + api.rand() - 1.5) * 0.09;      // power error, sd ~0.045
            this.dP = 0.53 + e;
            let lead = 0.0;
            if (this.moving) {
                // where the hoop will be when the ball gets there (about a second), misjudged a bit
                let tf = 0.85 + 0.08 * Math.sqrt(this.sx * this.sx + this.sz * this.sz);
                let fut = HOOP_A * Math.sin(HOOP_W * (this.moveT + tf + 0.25)) * api.range(0.85, 1.1);
                let D = Math.sqrt(this.sx * this.sx + this.sz * this.sz);
                lead = Math.atan2(fut - this.hx, D) * 180.0 / Math.PI;
            }
            this.dAng = lead + (api.rand() + api.rand() - 1.0) * 2.8;            // aim error, sd ~1.1 deg
            this.st = S_AIM;
            this.sT = 0;
            this.dAim = true;
            if (this.ballScreen(api)) {
                this.downX = api.screenX;
                this.downY = api.screenY + 14;
            }
            this.curX = this.downX;
            this.curY = this.downY;
            this.lastP = -1;
            return;
        }
        if (this.st == S_AIM && this.dAim) {
            // the drag a player's finger would make, shown like one
            let u = <f32>Math.min(1.0, this.sT / 0.28);
            let len = <f32>(30.0 + 40.0 * this.dP);
            let a = <f32>(this.dAng / AIM_K * Math.PI / 180.0);
            this.curX = this.downX + Mathf.sin(a) * len * u * u;
            this.curY = this.downY - Mathf.cos(a) * len * u * u;
            this.liveSpeed = (SPD0 + SPD_SPAN * this.dP) * <f64>u;
            if (this.sT >= 0.28) {
                this.dAim = false;
                this.shoot(api, this.dP, this.dAng);
            }
        }
    }

    // ---------------------------------------------------------------- HUD

    hud(api: GameApi): void {
        let ink = api.rampColor(R_ASPHALT, 0);
        let dark = api.rampColor(R_ASPHALT, 1);
        let grey = api.rampColor(R_ASPHALT, 3);
        let white = api.rampColor(R_PAINT, 3);
        let yellow = api.rampColor(R_BALL, 3);
        let orange = api.rampColor(R_BALL, 2);
        let red = api.rampColor(R_BALL, 1);
        let green = api.rampColor(R_KIT, 2);
        let blue = api.rampColor(R_BLUE, 2);
        let purple = api.rampColor(R_DUSK, 3);
        let w = <f32>api.hudW;
        let h = <f32>api.hudH;
        // the top bar: score, clock, best
        api.rect(0, 0, w, 15, ink);
        api.rect(0, 15, w, 1, purple);
        api.text(4, 5, "SCORE", grey, 1, 0);
        api.text(26, 3, this.score.toString(), yellow, 2, 0);
        let sec = <i32>Math.ceil(this.clock);
        let ts = (sec >= 60 ? "1:00" : "0:" + (sec < 10 ? "0" : "") + sec.toString());
        let tc = sec <= 5 && this.run == PLAY ? ((<i32>(this.clock * 4.0)) % 2 == 0 ? red : white) : (this.moving ? orange : white);
        api.text(Mathf.floor(w * 0.5 - api.textWidth(ts, 2) * 0.5), 3, ts, tc, 2, 0);
        let bs = "BEST " + this.best.toString();
        api.text(w - 4 - api.textWidth(bs, 1), 5, bs, grey, 1, 0);
        // the streak: three pips fill, then ON FIRE
        let fx = <f32>70;
        if (this.streak >= 3) {
            let fc = (<i32>(api.time * 6.0)) % 2 == 0 ? orange : yellow;
            api.text(fx, 5, this.streak >= 6 ? "x3 FIRE" : "x2 FIRE", fc, 1, 0);
        } else {
            for (let k = 0; k < 3; k++) {
                api.rect(fx + <f32>k * 6, 5, 4, 5, k < this.streak ? orange : dark);
            }
        }
        // the spot's value under the clock
        let pv = SPOT_PTS[this.spot] == 3 ? "3 PT" : "2 PT";
        api.text(Mathf.floor(w * 0.5 + 24), 5, pv, SPOT_PTS[this.spot] == 3 ? blue : green, 1, 0);
        // the flick: a dotted line from the press, and the power meter with its sweet band
        if (this.st == S_AIM) {
            let n = 7;
            for (let k = 1; k <= n; k++) {
                let f = <f32>k / <f32>n;
                let qx = this.downX + (this.curX - this.downX) * f;
                let qy = this.downY + (this.curY - this.downY) * f;
                api.rect(Mathf.round(qx) - 1, Mathf.round(qy) - 1, 3, 3, ink);
                api.rect(Mathf.round(qx), Mathf.round(qy), 1, 1, white);
            }
        }
        if (this.run != OVER) {
            this.meter(api, w - 16, h - 78, ink, dark, white, yellow, orange, green);
        }
        // the last shot's label over the hoop
        if (this.popT < 1.1) {
            let c = this.popC == 1 ? yellow : (this.popC == 2 ? orange : (this.popC == 3 ? grey : white));
            if (this.popC != 3 && (<i32>(this.popT * 10.0)) % 2 == 1) {
                c = white;
            }
            let ty = this.popY - <f32>(this.popT * 8.0);
            let sc = this.popC == 3 ? 1 : 2;
            api.text(Mathf.floor(this.popX - api.textWidth(this.popS, sc) * 0.5), Mathf.floor(ty), this.popS, c, sc, ink);
        }
        if (this.bannerT < 1.6 && this.run != OVER) {
            let c = (<i32>(this.bannerT * 8.0)) % 2 == 0 ? orange : yellow;
            api.textCentered(26, this.bannerS, c, 2, ink);
        }
        if (this.run == READY) {
            let bob = (<i32>(api.time * 3.0)) % 2 == 0 ? 0 : 2;
            if (this.ballScreen(api)) {
                let ax = Mathf.round(api.screenX), ay = Mathf.round(api.screenY) - 14 - <f32>bob;
                api.rect(ax, ay - 10, 1, 10, yellow);
                api.rect(ax - 1, ay - 9, 3, 1, yellow);
                api.rect(ax - 2, ay - 8, 5, 1, yellow);
            }
            api.rect(0, h - 25, w, 19, ink);
            api.textCentered(h - 22, "PRESS THE BALL AND FLICK IT UP", white, 1, ink);
            api.textCentered(h - 13, "FASTER FLICKS GO FARTHER - 60 SECONDS", grey, 1, ink);
        } else if (this.run == ENDING) {
            api.textCentered(h * 0.5 - 30, "TIME!", red, 3, ink);
        } else if (this.run == OVER) {
            api.rect(0, h * 0.5 - 34, w, 52, ink);
            api.rect(0, h * 0.5 - 35, w, 1, purple);
            api.rect(0, h * 0.5 + 18, w, 1, purple);
            api.textCentered(h * 0.5 - 30, "FINAL " + this.score.toString(), yellow, 3, 0);
            let pct = this.shots > 0 ? this.made * 100 / this.shots : 0;
            api.textCentered(h * 0.5 - 8, this.made.toString() + " OF " + this.shots.toString() + " SHOTS  " + pct.toString() + "%", white, 1, 0);
            if (this.score >= this.best && this.score > 0 && !api.demo) {
                let c = (<i32>(api.time * 5.0)) % 2 == 0 ? orange : yellow;
                api.textCentered(h * 0.5 + 3, "NEW BEST!", c, 1, 0);
            } else {
                api.textCentered(h * 0.5 + 3, "BEST " + this.best.toString(), grey, 1, 0);
            }
            if (!api.demo && api.time - this.overAt > 0.8) {
                api.textCentered(h - 13, "CLICK TO PLAY AGAIN", white, 1, ink);
            }
        }
    }

    // a vertical meter: the live flick speed while aiming, the sweet band, the last shot's mark
    meter(api: GameApi, x: f32, y: f32, ink: u32, dark: u32, white: u32, yellow: u32, orange: u32, green: u32): void {
        let H: f32 = 60;
        api.rect(x - 1, y - 1, 8, H + 2, ink);
        api.rect(x, y, 6, H, dark);
        // the sweet band: powers 0.46 .. 0.6
        let b0 = H * 0.46 / 1.2, b1 = H * 0.6 / 1.2;
        api.rect(x, y + H - b1, 6, b1 - b0, green);
        if (this.st == S_AIM) {
            let p = <f32>Math.min(1.2, Math.max(0, this.power(this.liveSpeed)));
            let ph = Mathf.round(H * p / 1.2);
            let c = p < 0.46 ? white : (p <= 0.6 ? yellow : orange);
            api.rect(x + 1, y + H - ph, 4, ph, c);
        }
        if (this.lastP >= 0) {
            let m = Mathf.round(H * <f32>Math.min(1.2, this.lastP) / 1.2);
            api.rect(x - 2, y + H - m, 10, 1, white);
        }
        api.text(x - 3, y + H + 3, "PWR", white, 1, ink);
    }
}

function stepped(v: f64, step: f64): f64 {
    return Math.floor(v / step) * step;
}
