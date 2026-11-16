// Bee Garden: lead the bee with the pointer to the flowers that bloom on a floating garden and
// pollinate them (hover over one for a moment) before they wilt. A spider guards one flower now
// and then (worth 3): it lunges when the bee comes close. A wilted flower or a spider bite costs
// one of three lives. Pointer only; a run starts on the first click; demo mode plays itself.
import { GameApi, POINTER_DOWN, POINTER_MOVE } from "./game_api";

const ST_IDLE: i32 = 0;
const ST_PLAY: i32 = 1;
const ST_OVER: i32 = 2;

// flower slot states
const F_EMPTY: i32 = 0;
const F_OPEN: i32 = 1;    // blooming, its life running down
const F_HAPPY: i32 = 2;   // pollinated: a pop, then it sinks back into its mound
const F_DROOP: i32 = 3;   // out of time: it bends over, then turns into a wilted flower

const NSLOT: i32 = 7;
const NWILT: i32 = 4;
const NSPARK: i32 = 10;
const FLY_Y: f64 = 1.5;       // the bee's flight height (the bake's bee position)
const BEE_S: f64 = 1.4;       // the bee's bake scale (its wing hinges sit 0.1, 0.2, 0.2 m off its pivot unscaled)
const HEAD_Y: f64 = 1.25;     // a flower head's height (0.95 m at the bake's scale 1.3)
const REACH: f64 = 0.62;      // how near (x/z) the bee must hover to pollinate
const DWELL: f64 = 0.3;       // seconds of hovering it takes
const HIVE_X: f64 = -2.55;
const HIVE_Z: f64 = -1.7;
const DEN_X: f64 = 3.0;       // where the spider waits (by the back-right bush)
const DEN_Z: f64 = -1.6;

// palette indices (art/palette.json "colors")
const C_NAVY: i32 = 0;
const C_PLUM: i32 = 1;
const C_PINK: i32 = 2;
const C_WHITE: i32 = 3;
const C_ORANGE: i32 = 4;
const C_YELLOW: i32 = 5;
const C_CYAN: i32 = 7;

export class Game {
    state: i32 = ST_IDLE;
    stateT: f64 = 0;
    runT: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    lives: i32 = 3;
    wasDemo: bool = false;
    started: bool = false;

    // bones
    bee: i32 = -1;
    wingL: i32 = -1;
    wingR: i32 = -1;
    spider: i32 = -1;
    slotBone: StaticArray<i32> = new StaticArray<i32>(NSLOT);
    wiltBone: StaticArray<i32> = new StaticArray<i32>(NWILT);
    sparkBone: StaticArray<i32> = new StaticArray<i32>(NSPARK);

    // flower slots (world x/z; the island's soil mounds sit under them)
    sx: StaticArray<f64> = [0.0, 2.4, 1.3, -1.2, -2.5, -1.1, 1.4];
    sz: StaticArray<f64> = [0.3, 0.4, 2.4, 2.5, 0.5, -1.7, -1.6];
    sState: StaticArray<i32> = new StaticArray<i32>(NSLOT);
    sT: StaticArray<f64> = new StaticArray<f64>(NSLOT);      // time in the state
    sLife: StaticArray<f64> = new StaticArray<f64>(NSLOT);
    sMax: StaticArray<f64> = new StaticArray<f64>(NSLOT);
    sDwell: StaticArray<f64> = new StaticArray<f64>(NSLOT);
    sCool: StaticArray<f64> = new StaticArray<f64>(NSLOT);
    sYaw: StaticArray<f64> = new StaticArray<f64>(NSLOT);
    guarded: i32 = -1;
    spawnT: f64 = 0;

    wActive: StaticArray<bool> = new StaticArray<bool>(NWILT);
    wT: StaticArray<f64> = new StaticArray<f64>(NWILT);
    wX: StaticArray<f64> = new StaticArray<f64>(NWILT);
    wZ: StaticArray<f64> = new StaticArray<f64>(NWILT);

    pT: StaticArray<f64> = new StaticArray<f64>(NSPARK);     // < 0: idle
    pX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pZ: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pVX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pVY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    pVZ: StaticArray<f64> = new StaticArray<f64>(NSPARK);

    // the bee
    bx: f64 = HIVE_X;
    bz: f64 = HIVE_Z;
    by: f64 = FLY_Y;
    bvx: f64 = 0;
    bvz: f64 = 0;
    byaw: f64 = 30;
    broll: f64 = 0;
    bpop: f64 = 0;        // > 0: the pollination pop
    tx: f64 = HIVE_X;     // where the pointer (or the demo) leads
    tz: f64 = HIVE_Z;
    hurtT: f64 = 0;       // > 0: just bitten (blinks, cannot be bitten again)
    fallT: f64 = 0;

    // the spider
    spx: f64 = DEN_X;
    spz: f64 = DEN_Z;
    spYaw: f64 = 0;
    spAng: f64 = 0;
    spMode: i32 = 0;      // 0 walk/circle, 1 crouch, 2 leap, 3 recover
    spT: f64 = 0;
    spFromX: f64 = 0;
    spFromZ: f64 = 0;
    spToX: f64 = 0;
    spToZ: f64 = 0;
    spWalk: f64 = 0;

    // juice
    shakeT: f64 = 0;
    flashT: f64 = 0;
    popT: f64 = -1;
    popX: f32 = 0;
    popY: f32 = 0;
    popText: string = "";
    camTX: f64 = 0;
    camTY: f64 = 0;
    camTZ: f64 = 0;

    // the demo player
    dThink: f64 = 0;
    dAimX: f64 = 0;
    dAimZ: f64 = 0;
    dErrX: f64 = 0;
    dErrZ: f64 = 0;
    dPick: i32 = -1;
    dGo: f64 = 0;
    dReact: f64 = 0.1;

    start(api: GameApi): void {
        api.playable = true;
        this.bee = api.bone("bee");
        this.wingL = api.bone("wingL");
        this.wingR = api.bone("wingR");
        this.spider = api.bone("spider");
        for (let i = 0; i < NSLOT; i++) {
            let n = i % 2 == 0 ? "rose" + (i / 2).toString() : "daisy" + ((i - 1) / 2).toString();
            this.slotBone[i] = api.bone(n);
            this.sYaw[i] = api.range(-18, 18);
        }
        for (let i = 0; i < NWILT; i++) {
            this.wiltBone[i] = api.bone("wilt" + i.toString());
        }
        for (let i = 0; i < NSPARK; i++) {
            this.sparkBone[i] = api.bone("spark" + i.toString());
        }
        this.camTX = api.targetX;
        this.camTY = api.targetY;
        this.camTZ = api.targetZ;
        this.wasDemo = api.demo;
        this.resetWorld(api);
        if (api.demo) {
            this.beginRun(api);
        }
    }

    // ------------------------------------------------------------------ run control

    resetWorld(api: GameApi): void {
        for (let i = 0; i < NSLOT; i++) {
            this.sState[i] = F_EMPTY;
            this.sT[i] = 0;
            this.sCool[i] = 0;
            this.sDwell[i] = 0;
        }
        for (let i = 0; i < NWILT; i++) {
            this.wActive[i] = false;
        }
        for (let i = 0; i < NSPARK; i++) {
            this.pT[i] = -1;
        }
        this.guarded = -1;
        // the garden is in bloom from the first frame: two flowers open (their clocks wait for the run)
        this.bloom(api, 0, 7.5);
        this.bloom(api, 2, 8.5);
        this.sT[0] = 1;
        this.sT[2] = 1;
        this.bx = HIVE_X; this.bz = HIVE_Z; this.by = FLY_Y;
        this.bvx = 0; this.bvz = 0;
        this.tx = HIVE_X + 0.4; this.tz = HIVE_Z + 0.3;
        this.hurtT = 0; this.fallT = 0; this.bpop = 0;
        this.spx = DEN_X; this.spz = DEN_Z; this.spMode = 0; this.spT = 0;
        this.score = 0;
        this.lives = 3;
        this.runT = 0;
        this.spawnT = 0.6;
    }

    beginRun(api: GameApi): void {
        if (this.state == ST_OVER) {
            this.resetWorld(api);
        }
        this.state = ST_PLAY;
        this.stateT = 0;
        this.runT = 0;
        this.dThink = 0;
    }

    endRun(): void {
        this.state = ST_OVER;
        this.stateT = 0;
        this.fallT = 0.001;
        if (this.score > this.best) {
            this.best = this.score;
        }
    }

    difficulty(): f64 {
        return Math.min(1.0, this.runT / 50.0);
    }

    bloom(api: GameApi, i: i32, life: f64): void {
        this.sState[i] = F_OPEN;
        this.sT[i] = 0;
        this.sLife[i] = life;
        this.sMax[i] = life;
        this.sDwell[i] = 0;
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            // the host switched demo off (a visitor took over) or on: a fresh run either way
            this.wasDemo = api.demo;
            this.state = ST_OVER;
            this.resetWorld(api);
            this.state = ST_IDLE;
            this.beginRun(api);
        }
        this.stateT += dt;
        if (this.state == ST_PLAY) {
            this.runT += dt;
        }
        if (api.demo) {
            this.demoThink(api, dt);
            if (this.state == ST_OVER && this.stateT > 2.0) {
                this.beginRun(api);
            }
        } else if (this.state == ST_IDLE) {
            // before the first click the bee idles by its hive
            this.tx = HIVE_X + 0.5 + 0.35 * Math.sin(api.time * 0.9);
            this.tz = HIVE_Z + 0.6 + 0.25 * Math.sin(api.time * 1.3);
        }
        this.updateFlowers(api, dt);
        this.updateBee(api, dt);
        this.updateSpider(api, dt);
        this.updateSparks(api, dt);
        this.updateWilts(api, dt);
        // camera shake: a stepped offset of the target (whole art pixels after the snap)
        if (this.shakeT > 0) {
            this.shakeT -= dt;
            let k = Math.floor(api.time * 30);
            let ox = (Math.sin(k * 12.9898) * 43758.5453) % 1.0;
            let oy = (Math.sin(k * 78.233) * 12543.1234) % 1.0;
            // whole art pixels only (the view's up is (0, cos 45, -sin 45)), so the frame stays on the HUD grid
            let texel = api.orthoHeight / 136.0;
            api.targetX = this.camTX + Math.round(ox * 1.5) * texel;
            api.targetY = this.camTY + Math.round(oy * 1.5) * texel / Math.cos(api.pitch * Math.PI / 180);
        } else {
            api.targetX = this.camTX;
            api.targetY = this.camTY;
        }
        if (this.popT >= 0) {
            this.popT += dt;
            if (this.popT > 0.8) {
                this.popT = -1;
            }
        }
        if (this.flashT > 0) {
            this.flashT -= dt;
        }
    }

    updateFlowers(api: GameApi, dt: f64): void {
        let playing = this.state == ST_PLAY;
        let d = this.difficulty();
        // spawning
        if (playing) {
            this.spawnT -= dt;
            let open = 0;
            for (let i = 0; i < NSLOT; i++) {
                if (this.sState[i] == F_OPEN) {
                    open++;
                }
            }
            let maxOpen = 2 + <i32>Math.floor(d * 3.5);
            if (this.spawnT <= 0 && open < maxOpen) {
                // a random free slot, not the one the bee hovers over
                let tries = 0;
                while (tries < 12) {
                    let i = <i32>Math.floor(api.rand() * <f64>NSLOT) % NSLOT;
                    tries++;
                    if (this.sState[i] != F_EMPTY || this.sCool[i] > 0) {
                        continue;
                    }
                    let life = 7.5 - 4.0 * d + api.range(-0.4, 0.6);
                    this.bloom(api, i, life);
                    if (this.guarded < 0 && this.runT > 3.0 && api.rand() < 0.6) {
                        this.guarded = i;
                        this.sLife[i] = life * 1.35;
                        this.sMax[i] = this.sLife[i];
                    }
                    break;
                }
                this.spawnT = 2.1 - 1.4 * d + api.range(-0.3, 0.3);
            } else if (this.spawnT <= 0) {
                this.spawnT = 0.3;
            }
        }
        for (let i = 0; i < NSLOT; i++) {
            let b = this.slotBone[i];
            let x = this.sx[i], z = this.sz[i], yaw = this.sYaw[i];
            let st = this.sState[i];
            this.sT[i] += dt;
            let t = this.sT[i];
            if (this.sCool[i] > 0) {
                this.sCool[i] -= dt;
            }
            if (st == F_EMPTY) {
                api.hide(b);
                continue;
            }
            if (st == F_OPEN) {
                if (playing) {
                    this.sLife[i] -= dt;
                    // pollination: the bee hovers over the head
                    let dx = this.bx - x, dz = this.bz - (z + 0.1);
                    if (dx * dx + dz * dz < REACH * REACH && this.hurtT <= 0) {
                        this.sDwell[i] += dt;
                        if (this.sDwell[i] >= DWELL) {
                            this.pollinate(api, i);
                            continue;
                        }
                    } else {
                        this.sDwell[i] = Math.max(0, this.sDwell[i] - dt * 2);
                    }
                    if (this.sLife[i] <= 0) {
                        this.sState[i] = F_DROOP;
                        this.sT[i] = 0;
                        continue;
                    }
                }
                // grow in with an overshoot (stepped at 15 fps: hand-animated), then sway; droop when low
                if (t < 0.5) {
                    let k = Math.floor(t * 15) / 15 / 0.5;
                    let sy = k < 0.6 ? 0.1 + k / 0.6 * 1.1 : 1.2 - (k - 0.6) / 0.4 * 0.2;
                    let sxz = 0.3 + 0.7 * Math.min(1, k * 1.4);
                    api.placeScaled(b, x, 0, z, yaw, sxz, sy, sxz);
                } else {
                    let frac = this.sLife[i] / this.sMax[i];
                    let droop = frac < 0.4 ? (0.4 - frac) / 0.4 * 28.0 : 0.0;
                    let sway = Math.floor(Math.sin(api.time * 2.2 + <f64>i) * 3.0) * 2.0;
                    // a dwelling bee makes the head nod
                    let nod = this.sDwell[i] > 0 ? Math.sin(t * 40.0) * 5.0 : 0.0;
                    api.place(b, x, 0, z, yaw, droop + nod, sway, 1.0);
                }
            } else if (st == F_HAPPY) {
                // pop (squash, stretch), hold, then sink back into the mound
                if (t < 0.36) {
                    let k = Math.floor(t * 15) / 15;
                    let s = k < 0.12 ? 1.0 - k * 2.0 : 0.76 + Math.sin((k - 0.12) / 0.24 * Math.PI) * 0.5;
                    api.placeScaled(b, x, 0, z, yaw + t * 200, 2.0 - s, s, 2.0 - s);
                } else if (t < 1.0) {
                    api.place(b, x, 0, z, yaw + 72, 0, 0, 1.0);
                } else if (t < 1.4) {
                    let k = Math.floor((t - 1.0) * 15) / 15 / 0.4;
                    api.placeScaled(b, x, 0, z, yaw + 72, 1.0 - k * 0.6, 1.0 - k * 0.95, 1.0 - k * 0.6);
                } else {
                    this.sState[i] = F_EMPTY;
                    this.sCool[i] = 1.0;
                    api.hide(b);
                    this.sYaw[i] = api.range(-18, 18);
                }
            } else if (st == F_DROOP) {
                if (t < 0.4) {
                    let k = Math.floor(t * 15) / 15 / 0.4;
                    api.place(b, x, 0, z, yaw, 28 + k * 40, 0, 1.0 - k * 0.15);
                } else {
                    this.wilt(api, i);
                }
            }
        }
    }

    pollinate(api: GameApi, i: i32): void {
        let pts = i == this.guarded ? 3 : 1;
        this.score += pts;
        this.sState[i] = F_HAPPY;
        this.sT[i] = 0;
        this.bpop = 0.3;
        if (i == this.guarded) {
            this.guarded = -1;
        }
        this.burst(api, this.sx[i], HEAD_Y + 0.15, this.sz[i] + 0.1, 6);
        if (api.project(<f32>this.sx[i], <f32>(HEAD_Y + 0.5), <f32>this.sz[i])) {
            this.popX = api.screenX;
            this.popY = api.screenY;
            this.popT = 0;
            this.popText = "+" + pts.toString();
        }
    }

    wilt(api: GameApi, i: i32): void {
        api.hide(this.slotBone[i]);
        this.sState[i] = F_EMPTY;
        this.sCool[i] = 2.8;
        if (i == this.guarded) {
            this.guarded = -1;
        }
        for (let w = 0; w < NWILT; w++) {
            if (!this.wActive[w]) {
                this.wActive[w] = true;
                this.wT[w] = 0;
                this.wX[w] = this.sx[i];
                this.wZ[w] = this.sz[i];
                break;
            }
        }
        this.loseLife(api);
    }

    loseLife(api: GameApi): void {
        if (this.state != ST_PLAY) {
            return;
        }
        this.lives -= 1;
        this.shakeT = 0.3;
        this.flashT = 0.5;
        if (this.lives <= 0) {
            this.lives = 0;
            this.endRun();
        }
    }

    updateWilts(api: GameApi, dt: f64): void {
        for (let w = 0; w < NWILT; w++) {
            let b = this.wiltBone[w];
            if (!this.wActive[w]) {
                api.hide(b);
                continue;
            }
            this.wT[w] += dt;
            let t = this.wT[w];
            if (t < 0.2) {
                // lands with a little squash
                let k = Math.floor(t * 15) / 15 / 0.2;
                api.placeScaled(b, this.wX[w], 0, this.wZ[w], 0, 1.0 + 0.2 * (1 - k), 1.0 - 0.25 * (1 - k), 1.0 + 0.2 * (1 - k));
            } else if (t < 2.4) {
                api.place(b, this.wX[w], 0, this.wZ[w], 0, 0, 0, 1.0);
            } else if (t < 2.9) {
                let k = Math.floor((t - 2.4) * 15) / 15 / 0.5;
                api.placeScaled(b, this.wX[w], 0, this.wZ[w], 0, 1.0 - k * 0.5, 1.0 - k * 0.95, 1.0 - k * 0.5);
            } else {
                this.wActive[w] = false;
                api.hide(b);
            }
        }
    }

    // ------------------------------------------------------------------ the bee

    updateBee(api: GameApi, dt: f64): void {
        let b = this.bee;
        if (this.state == ST_OVER) {
            // bitten out of the air: it tumbles down onto the lawn and lies there, wings twitching
            this.fallT += dt;
            let k = Math.min(1.0, this.fallT / 0.7);
            this.by = FLY_Y - (FLY_Y - 0.42) * k * k;
            this.byaw += dt * 400 * (1 - k);
            this.broll = 70 * k;
            this.placeBee(api, 0, 1.0, Math.floor(api.time * 4) % 2 == 0 ? 10.0 : -10.0);
            return;
        }
        // steer: a damped spring towards the target, capped speed
        let k = 34.0, c = 9.5;
        let ax = k * (this.tx - this.bx) - c * this.bvx;
        let az = k * (this.tz - this.bz) - c * this.bvz;
        this.bvx += ax * dt;
        this.bvz += az * dt;
        let sp = Math.sqrt(this.bvx * this.bvx + this.bvz * this.bvz);
        let maxSp = 6.5;
        if (sp > maxSp) {
            this.bvx *= maxSp / sp;
            this.bvz *= maxSp / sp;
            sp = maxSp;
        }
        this.bx += this.bvx * dt;
        this.bz += this.bvz * dt;
        // stay over the island
        let r = Math.sqrt(this.bx * this.bx + this.bz * this.bz);
        if (r > 4.3) {
            this.bx *= 4.3 / r;
            this.bz *= 4.3 / r;
        }
        // face where it flies, bank into turns
        let prevYaw = this.byaw;
        if (sp > 0.6) {
            let want = Math.atan2(this.bvx, this.bvz) * 180 / Math.PI;
            let d = want - this.byaw;
            while (d > 180) { d -= 360; }
            while (d < -180) { d += 360; }
            this.byaw += d * Math.min(1.0, dt * 10);
        }
        let turn = (this.byaw - prevYaw) / Math.max(dt, 0.001);
        let wantRoll = Math.max(-30, Math.min(30, -turn * 0.08));
        this.broll += (wantRoll - this.broll) * Math.min(1.0, dt * 8);
        // hover bob; dip towards a flower while pollinating
        let dip = 0.0;
        for (let i = 0; i < NSLOT; i++) {
            if (this.sState[i] == F_OPEN && this.sDwell[i] > 0) {
                dip = 0.22;
            }
        }
        let bob = Math.floor(Math.sin(api.time * 7.0) * 2.0) * 0.03;
        this.by += (FLY_Y - dip + bob - this.by) * Math.min(1.0, dt * 12);
        let pitch = Math.min(18.0, sp * 3.0);
        let scale = 1.0;
        if (this.bpop > 0) {
            this.bpop -= dt;
            scale = 1.0 + Math.sin((0.3 - this.bpop) / 0.3 * Math.PI) * 0.25;
        }
        if (this.hurtT > 0) {
            this.hurtT -= dt;
            if (Math.floor(this.hurtT * 12) % 2 == 0) {
                api.hide(b);
                api.hide(this.wingL);
                api.hide(this.wingR);
                return;
            }
        }
        // wings: a stepped buzz between three poses
        let ph = <i32>Math.floor(api.time * 24.0) % 4;
        let flap = ph == 0 ? 26.0 : (ph == 2 ? -18.0 : 4.0);
        this.placeBee(api, pitch, scale, flap);
    }

    // The bee's body and its two wings, hinged at their roots (offsets from the bake, in metres).
    placeBee(api: GameApi, pitch: f64, scale: f64, flap: f64): void {
        let yaw = this.byaw, roll = this.broll;
        api.place(this.bee, this.bx, this.by, this.bz, yaw, pitch, roll, scale);
        // R = Ry(yaw) Rx(pitch) Rz(roll), as GameApi.place builds it
        let cy = Math.cos(yaw * Math.PI / 180), sy = Math.sin(yaw * Math.PI / 180);
        let cp = Math.cos(pitch * Math.PI / 180), sp = Math.sin(pitch * Math.PI / 180);
        let cr = Math.cos(roll * Math.PI / 180), sr = Math.sin(roll * Math.PI / 180);
        let r00 = cy * cr + sy * sp * sr, r01 = -cy * sr + sy * sp * cr, r02 = sy * cp;
        let r10 = cp * sr, r11 = cp * cr, r12 = -sp;
        let r20 = -sy * cr + cy * sp * sr, r21 = sy * sr + cy * sp * cr, r22 = cy * cp;
        for (let s = 0; s < 2; s++) {
            let k = BEE_S * scale;
            let ox = (s == 0 ? -0.1 : 0.1) * k, oy = 0.2 * k, oz = 0.2 * k;
            let wx = this.bx + r00 * ox + r01 * oy + r02 * oz;
            let wy = this.by + r10 * ox + r11 * oy + r12 * oz;
            let wz = this.bz + r20 * ox + r21 * oy + r22 * oz;
            api.place(s == 0 ? this.wingL : this.wingR, wx, wy, wz, yaw, pitch, roll + (s == 0 ? flap : -flap), scale);
        }
    }

    // ------------------------------------------------------------------ the spider

    updateSpider(api: GameApi, dt: f64): void {
        let b = this.spider;
        this.spT += dt;
        let g = this.guarded;
        let playing = this.state == ST_PLAY;
        let dbx = this.bx - this.spx, dbz = this.bz - this.spz;
        let dBee = Math.sqrt(dbx * dbx + dbz * dbz);
        let y = 0.0, sxz = 1.0, sy = 1.0;
        if (this.spMode == 0) {
            // walk to the guarded flower and circle it; without one, home to the den
            let gx = DEN_X, gz = DEN_Z;
            if (g >= 0) {
                this.spAng += dt * 1.3;
                gx = this.sx[g] + Math.cos(this.spAng) * 0.9;
                gz = this.sz[g] + 0.1 + Math.sin(this.spAng) * 0.9;
            }
            let dx = gx - this.spx, dz = gz - this.spz;
            let d = Math.sqrt(dx * dx + dz * dz);
            let walk = g >= 0 ? 2.4 : 1.2;
            if (d > 0.05) {
                let st = Math.min(d, walk * dt);
                this.spx += dx / d * st;
                this.spz += dz / d * st;
                this.spYaw = Math.atan2(dx, dz) * 180 / Math.PI;
                this.spWalk += st;
            }
            // a scuttle: stepped bob while walking
            y = Math.floor(this.spWalk * 9.0) % 2 == 0 ? 0.0 : 0.05;
            // the bee comes close to the guarded flower and to the spider: crouch, then leap at it
            let nearFlower = false;
            if (g >= 0) {
                let fx = this.bx - this.sx[g], fz = this.bz - this.sz[g];
                nearFlower = fx * fx + fz * fz < 1.4 * 1.4;
            }
            if (playing && nearFlower && dBee < 1.05 && this.hurtT <= 0 && this.spT > 0.9) {
                this.spMode = 1;
                this.spT = 0;
                this.spYaw = Math.atan2(dbx, dbz) * 180 / Math.PI;
            }
        } else if (this.spMode == 1) {
            // anticipation: squash down for a beat
            let k = Math.min(1.0, this.spT / 0.36);
            sy = 1.0 - 0.35 * k;
            sxz = 1.0 + 0.2 * k;
            this.spYaw = Math.atan2(dbx, dbz) * 180 / Math.PI;
            if (this.spT >= 0.36) {
                this.spMode = 2;
                this.spT = 0;
                this.spFromX = this.spx;
                this.spFromZ = this.spz;
                // aims where the bee is, a little short
                let reach = Math.min(dBee, 1.2);
                this.spToX = this.spx + dbx / Math.max(dBee, 0.01) * reach;
                this.spToZ = this.spz + dbz / Math.max(dBee, 0.01) * reach;
            }
        } else if (this.spMode == 2) {
            // the leap: an arc, stretched
            let k = Math.min(1.0, this.spT / 0.34);
            this.spx = this.spFromX + (this.spToX - this.spFromX) * k;
            this.spz = this.spFromZ + (this.spToZ - this.spFromZ) * k;
            y = Math.sin(k * Math.PI) * 0.75;
            sy = 1.25;
            sxz = 0.85;
            if (playing && dBee < 0.5 && this.hurtT <= 0) {
                this.bite(api);
            }
            if (k >= 1.0) {
                this.spMode = 3;
                this.spT = 0;
            }
        } else {
            // landing squash, then back to guarding
            let k = Math.min(1.0, this.spT / 0.6);
            sy = 0.7 + 0.3 * k;
            sxz = 1.2 - 0.2 * k;
            if (this.spT >= 0.6) {
                this.spMode = 0;
                this.spT = 0;
            }
        }
        // anyone flying straight into the spider gets bitten too
        if (playing && this.spMode == 0 && g >= 0 && dBee < 0.4 && this.hurtT <= 0) {
            this.bite(api);
        }
        api.placeScaled(b, this.spx, y, this.spz, this.spYaw, sxz, sy, sxz);
    }

    bite(api: GameApi): void {
        let dx = this.bx - this.spx, dz = this.bz - this.spz;
        let d = Math.max(0.01, Math.sqrt(dx * dx + dz * dz));
        this.bvx = dx / d * 9.0;
        this.bvz = dz / d * 9.0;
        this.hurtT = 1.5;
        this.burst(api, this.bx, this.by, this.bz, 4);
        this.loseLife(api);
    }

    // ------------------------------------------------------------------ pollen sparkles

    burst(api: GameApi, x: f64, y: f64, z: f64, n: i32): void {
        let made = 0;
        for (let i = 0; i < NSPARK && made < n; i++) {
            if (this.pT[i] >= 0) {
                continue;
            }
            let a = <f64>made / <f64>n * Math.PI * 2 + api.range(-0.3, 0.3);
            this.pT[i] = 0;
            this.pX[i] = x; this.pY[i] = y; this.pZ[i] = z;
            this.pVX[i] = Math.cos(a) * api.range(1.2, 2.0);
            this.pVZ[i] = Math.sin(a) * api.range(1.2, 2.0);
            this.pVY[i] = api.range(1.6, 2.6);
            made++;
        }
    }

    updateSparks(api: GameApi, dt: f64): void {
        for (let i = 0; i < NSPARK; i++) {
            let b = this.sparkBone[i];
            if (this.pT[i] < 0) {
                api.hide(b);
                continue;
            }
            this.pT[i] += dt;
            if (this.pT[i] > 0.7) {
                this.pT[i] = -1;
                api.hide(b);
                continue;
            }
            this.pVY[i] -= 6.0 * dt;
            this.pX[i] += this.pVX[i] * dt;
            this.pY[i] += this.pVY[i] * dt;
            this.pZ[i] += this.pVZ[i] * dt;
            let s = 1.4 - this.pT[i] * 1.6;
            api.place(b, this.pX[i], this.pY[i], this.pZ[i], Math.floor(this.pT[i] * 12) * 45, 0, 0, Math.max(0.2, s));
        }
    }

    // ------------------------------------------------------------------ the demo player

    demoThink(api: GameApi, dt: f64): void {
        if (this.state != ST_PLAY) {
            this.tx = this.bx;
            this.tz = this.bz;
            return;
        }
        this.dThink -= dt;
        if (this.dThink <= 0) {
            // reaction time: re-decide a few times a second, with a little aim error
            this.dThink = api.range(0.22, 0.42);
            this.dErrX = api.range(-0.3, 0.3);
            this.dErrZ = api.range(-0.3, 0.3);
            let bestI = -1;
            let bestV = 1e9;
            for (let i = 0; i < NSLOT; i++) {
                if (this.sState[i] != F_OPEN) {
                    continue;
                }
                let dx = this.sx[i] - this.bx, dz = this.sz[i] - this.bz;
                let v = this.sLife[i] + Math.sqrt(dx * dx + dz * dz) * 0.45;
                if (i == this.guarded) {
                    v += 1.2;
                }
                if (v < bestV) {
                    bestV = v;
                    bestI = i;
                }
            }
            // now and then a lazier pick (a human's misjudgement)
            if (bestI >= 0 && this.dPick != bestI && api.rand() < 0.18) {
                let j = <i32>Math.floor(api.rand() * <f64>NSLOT) % NSLOT;
                if (this.sState[j] == F_OPEN) {
                    bestI = j;
                }
            }
            this.dPick = bestI;
        }
        let i = this.dPick;
        if (i < 0 || this.sState[i] != F_OPEN) {
            // nothing to do: drift towards the middle
            this.tx = 0.3 * Math.sin(api.time * 0.7);
            this.tz = 0.5;
            return;
        }
        let ax = this.sx[i], az = this.sz[i] + 0.1;
        let near = this.sDwell[i] > 0;
        // hold steadier once over the flower
        this.tx = ax + (near ? this.dErrX * 0.25 : this.dErrX);
        this.tz = az + (near ? this.dErrZ * 0.25 : this.dErrZ);
        if (i == this.guarded) {
            // wait out of reach until the circling spider is on the far side of the flower
            let fx = this.bx - ax, fz = this.bz - az;
            let fd = Math.max(0.01, Math.sqrt(fx * fx + fz * fz));
            let sx = this.spx - ax, sz = this.spz - az;
            let sd = Math.max(0.01, Math.sqrt(sx * sx + sz * sz));
            let far = (fx * sx + fz * sz) / (fd * sd) < -0.35;
            if (this.dGo <= 0 && far && this.spMode == 0) {
                this.dGo = 1.1;
            }
            if (this.dGo > 0) {
                this.dGo -= dt;
            } else if (fd < 2.2) {
                this.tx = ax + fx / fd * 2.2;
                this.tz = az + fz / fd * 2.2;
            }
        }
        // a crouching spider: dart away (usually in time)
        if (this.spMode == 1 && this.spT > this.dReact) {
            let sx = this.bx - this.spx, sz = this.bz - this.spz;
            let sd = Math.max(0.01, Math.sqrt(sx * sx + sz * sz));
            if (sd < 1.8) {
                this.tx = this.bx + sx / sd * 2.0;
                this.tz = this.bz + sz / sd * 2.0;
                this.dGo = 0;
            }
        } else if (this.spMode != 1) {
            this.dReact = api.rand() < 0.2 ? 0.3 : api.range(0.05, 0.15);
        }
    }

    // ------------------------------------------------------------------ input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        let hit = api.pick(x, y, <f32>FLY_Y);
        if (kind == POINTER_DOWN) {
            if (this.state == ST_IDLE) {
                this.beginRun(api);
            } else if (this.state == ST_OVER && this.stateT > 0.8) {
                this.beginRun(api);
            }
        }
        if ((kind == POINTER_DOWN || kind == POINTER_MOVE) && hit && this.state == ST_PLAY) {
            this.tx = <f64>api.hitX;
            this.tz = <f64>api.hitZ;
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let white = api.paletteColor(C_WHITE);
        let navy = api.paletteColor(C_NAVY);
        let yellow = api.paletteColor(C_YELLOW);
        let pink = api.paletteColor(C_PINK);
        let plum = api.paletteColor(C_PLUM);
        let cyan = api.paletteColor(C_CYAN);
        let orange = api.paletteColor(C_ORANGE);
        // life bars over the open flowers
        for (let i = 0; i < NSLOT; i++) {
            if (this.sState[i] != F_OPEN || this.sT[i] < 0.5) {
                continue;
            }
            if (!api.project(<f32>this.sx[i], <f32>(HEAD_Y + 0.62), <f32>this.sz[i])) {
                continue;
            }
            let frac = Math.max(0.0, this.sLife[i] / this.sMax[i]);
            let w: f32 = 11;
            let x0 = Mathf.round(api.screenX - w * 0.5), y0 = Mathf.round(api.screenY);
            let low = frac < 0.3;
            if (low && Math.floor(api.time * 6) % 2 == 0) {
                continue;
            }
            api.rect(x0 - 1, y0 - 1, w + 2, 4, navy);
            let c = frac > 0.55 ? yellow : (frac > 0.3 ? orange : pink);
            api.rect(x0, y0, Mathf.max(1, Mathf.round(w * <f32>frac)), 2, c);
            if (i == this.guarded) {
                api.text(x0 + w + 2, y0 - 2, "X3", pink, 1, navy);
            }
        }
        if (this.popT >= 0) {
            let rise = <f32>(this.popT * 14.0);
            api.text(this.popX - 3, this.popY - 4 - rise, this.popText, yellow, 1, navy);
        }
        // score, best, lives
        api.text(4, 4, this.score.toString(), yellow, 2, navy);
        api.text(4, 16, "BEST " + this.best.toString(), white, 1, navy);
        for (let l = 0; l < 3; l++) {
            let x: f32 = <f32>(api.hudW - 10 - l * 9);
            let c = l < this.lives ? pink : plum;
            if (l == this.lives && this.flashT > 0 && Math.floor(this.flashT * 10) % 2 == 0) {
                c = white;
            }
            // a little flower: four petals round a dot
            api.rect(x + 2, 4, 3, 2, c);
            api.rect(x + 2, 9, 3, 2, c);
            api.rect(x, 6, 2, 3, c);
            api.rect(x + 5, 6, 2, 3, c);
            api.rect(x + 2, 6, 3, 3, l < this.lives ? yellow : navy);
        }
        let h = <f32>api.hudH;
        if (this.state == ST_IDLE) {
            let blink = Math.floor(api.time * 2) % 2 == 0;
            api.textCentered(h - 20, "CLICK TO FLY", blink ? white : cyan, 2, navy);
            api.textCentered(h - 8, "LEAD THE BEE TO THE FLOWERS BEFORE THEY WILT", white, 1, navy);
        } else if (this.state == ST_OVER) {
            let pw: f32 = 112, ph: f32 = 40;
            let px = Mathf.floor((<f32>api.hudW - pw) * 0.5), py = Mathf.floor(h * 0.5 - 27);
            api.rect(px, py, pw, ph, navy);
            api.rect(px - 1, py - 1, pw + 2, 1, plum);
            api.rect(px - 1, py + ph, pw + 2, 1, plum);
            api.rect(px - 1, py, 1, ph, plum);
            api.rect(px + pw, py, 1, ph, plum);
            api.textCentered(h * 0.5 - 22, "GAME OVER", white, 2, plum);
            api.textCentered(h * 0.5 - 6, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), yellow, 1, navy);
            if (this.stateT > 0.8 && !api.demo) {
                api.textCentered(h * 0.5 + 4, "CLICK TO PLAY AGAIN", cyan, 1, navy);
            }
        } else if (this.runT < 4.0 && !api.demo) {
            api.textCentered(h - 8, "HOVER OVER A FLOWER TO POLLINATE IT", white, 1, navy);
        }
    }
}
