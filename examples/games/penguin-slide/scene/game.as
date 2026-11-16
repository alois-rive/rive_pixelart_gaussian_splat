// Penguin Slide: click to jump. A penguin belly-slides along an endless ice run; jump the holes
// between the floes and the seals lying on them; fish over the holes are a bonus. The whole game is
// in this file (the renderer, splat_scene.as and game_api.as, is the skill's and never edited).
//
// World (metres, Y up, the camera looks along -Z from a 12 degree pitch): the run is a line of ice
// floes along X at z 0 (top y 0), the sea 0.3 m below. Everything that moves is a game bone. The
// course lives in "logical" metres (the penguin's distance); every bone is placed at
// logical - origin, and the origin jumps by 12 m whenever the penguin passes +4 m, so the play stays
// inside the bake's bounds (the shadow map's reach) and every position stays small. 12 m and the
// camera's 1.6 m lead are whole texels (orthoHeight 4.352 / 136 rows = 0.032 m), so a wrap changes
// no pixel. Things that travel with the camera (the penguin, the sea, the parallax backdrop) are put
// on the snapped camera's grid, so they do not crawl.
import { GameApi, POINTER_DOWN, SFX_BELL, SFX_COIN, SFX_HIT, SFX_JUMP, SFX_LOSE, SFX_POP, SFX_SHOOT, SFX_SPLASH, SFX_THUD,
    SFX_WHOOSH, SFX_WIN } from "./game_api";

const IDLE: i32 = 0;
const RUN: i32 = 1;
const DEAD: i32 = 2;

const WRAP: f64 = 12.0;       // the origin shift
const LEAD: f64 = 1.6;        // the camera looks this far ahead of the penguin
const CAMY: f64 = 0.92;
const GRAV: f64 = 15.0;
const JUMPV: f64 = 4.6;       // apex 0.71 m, 0.61 s in the air
const PREP: f64 = 0.05;       // anticipation: the squash before take-off
const SEA: f64 = -0.3;
const SEAL_HALF: f64 = 0.55;  // the seal's reach along the run, plus the penguin's
const SEAL_TOP: f64 = 0.3;

// floe pools: lengths and bone-name prefixes (3 copies each)
const NTYPE: i32 = 3;
const NCOPY: i32 = 3;
const NSEAL: i32 = 3;
const NFISH: i32 = 4;
const NPUFF: i32 = 5;
const NCHUNK: i32 = 5;
const NBERG: i32 = 4;

// HUD ramps (palette.json order): snow 0 (teal, mint, pale), ice 1, water 2, feather 3 (dark), ...
const R_SNOW: i32 = 0;
const R_FEATHER: i32 = 3;

export class Game {
    // bones
    penguin: i32 = -1;
    sea: i32 = -1;
    splash: i32 = -1;
    floeBone: StaticArray<i32> = new StaticArray<i32>(9);
    floeLen: StaticArray<f64> = new StaticArray<f64>(9);
    floeX: StaticArray<f64> = new StaticArray<f64>(9);     // logical start (left end); -1e9: free
    sealBone: StaticArray<i32> = new StaticArray<i32>(3);
    sealX: StaticArray<f64> = new StaticArray<f64>(3);
    sealHit: StaticArray<f64> = new StaticArray<f64>(3);  // time of a bonk (its startle)
    fishBone: StaticArray<i32> = new StaticArray<i32>(4);
    fishX: StaticArray<f64> = new StaticArray<f64>(4);
    fishY: StaticArray<f64> = new StaticArray<f64>(4);
    fishGot: StaticArray<f64> = new StaticArray<f64>(4);  // time collected (-1: not)
    puffBone: StaticArray<i32> = new StaticArray<i32>(5);
    puffX: StaticArray<f64> = new StaticArray<f64>(5);
    puffZ: StaticArray<f64> = new StaticArray<f64>(5);
    puffT: StaticArray<f64> = new StaticArray<f64>(5);    // birth time
    puffS: StaticArray<f64> = new StaticArray<f64>(5);    // size
    nextPuff: i32 = 0;
    chunkBone: StaticArray<i32> = new StaticArray<i32>(5);
    chunkX: StaticArray<f64> = new StaticArray<f64>(5);
    chunkZ: StaticArray<f64> = new StaticArray<f64>(5);
    chunkYaw: StaticArray<f64> = new StaticArray<f64>(5);
    bergBone: StaticArray<i32> = new StaticArray<i32>(4);
    bergX: StaticArray<f64> = new StaticArray<f64>(4);    // parallax space
    bergZ: StaticArray<f64> = new StaticArray<f64>(4);
    bergS: StaticArray<f64> = new StaticArray<f64>(4);
    bergYaw: StaticArray<f64> = new StaticArray<f64>(4);
    ridgeBone: StaticArray<i32> = new StaticArray<i32>(2);
    waveBone: StaticArray<i32> = new StaticArray<i32>(2);

    // the course
    genX: f64 = 0;          // logical end of the last floe generated
    made: i32 = 0;          // floes generated this run
    origin: f64 = 0;        // logical x of local 0

    // the run
    state: i32 = IDLE;
    x: f64 = 0;             // the penguin's logical x
    y: f64 = 0;
    vy: f64 = 0;
    v: f64 = 0;
    air: bool = false;
    prepT: f64 = -1;        // click time of a pending take-off
    jumpT: f64 = -10;       // take-off time
    landT: f64 = -10;       // landing time
    buffered: f64 = -10;    // a click in the air, kept for the landing
    runT: f64 = 0;          // seconds into the run
    startT: f64 = 0;
    deadT: f64 = 0;
    cause: i32 = 0;         // 1 splash, 2 bonk
    deadX: f64 = 0;
    deadVX: f64 = 0;
    spin: f64 = 0;
    fish: i32 = 0;
    score: i32 = 0;
    best: i32 = 0;
    runs: i32 = 0;
    camX: f64 = 0;          // logical camera target x
    shake: f64 = -10;
    lastPuff: f64 = 0;
    popT: f64 = -10;        // "+5" label
    popX: f64 = 0;
    popY: f64 = 0;
    wasDemo: bool = false;
    mark: i32 = 0;          // sound: the last 50 m mark chimed

    // demo player
    aimFor: f64 = 1e9;      // logical x of the hazard being planned for
    aimClick: f64 = 1e9;    // logical x to click at
    skill: f64 = 1;

    start(api: GameApi): void {
        api.playable = true;
        this.penguin = api.bone("penguin");
        this.sea = api.bone("sea");
        this.splash = api.bone("splash");
        let names = ["floeS", "floeM", "floeL"];
        let lens: StaticArray<f64> = [3.0, 5.0, 8.0];
        for (let t = 0; t < NTYPE; t++) {
            for (let c = 0; c < NCOPY; c++) {
                let i = t * NCOPY + c;
                this.floeBone[i] = api.bone(names[t] + c.toString());
                this.floeLen[i] = lens[t];
            }
        }
        for (let i = 0; i < NSEAL; i++) this.sealBone[i] = api.bone("seal" + i.toString());
        for (let i = 0; i < NFISH; i++) this.fishBone[i] = api.bone("fish" + i.toString());
        for (let i = 0; i < NPUFF; i++) this.puffBone[i] = api.bone("puff" + i.toString());
        for (let i = 0; i < NCHUNK; i++) this.chunkBone[i] = api.bone("chunk" + i.toString());
        for (let i = 0; i < NBERG; i++) this.bergBone[i] = api.bone("berg" + i.toString());
        for (let i = 0; i < 2; i++) this.ridgeBone[i] = api.bone("ridge" + i.toString());
        for (let i = 0; i < 2; i++) this.waveBone[i] = api.bone("waves" + i.toString());
        this.wasDemo = api.demo;
        this.reset(api, api.demo);
    }

    // ------------------------------------------------------------------ the course

    reset(api: GameApi, running: bool): void {
        this.origin = 0;
        this.x = 0; this.y = 0; this.vy = 0; this.air = false;
        this.prepT = -1; this.jumpT = -10; this.landT = -10; this.buffered = -10;
        this.fish = 0; this.score = 0; this.spin = 0;
        this.runT = 0; this.startT = api.time;
        this.camX = this.x + LEAD;
        this.aimFor = 1e9; this.aimClick = 1e9;
        this.skill = 0.8 + 0.4 * api.rand();
        for (let i = 0; i < 9; i++) this.floeX[i] = -1e9;
        for (let i = 0; i < NSEAL; i++) this.sealX[i] = -1e9;
        for (let i = 0; i < NFISH; i++) { this.fishX[i] = -1e9; this.fishGot[i] = -1; }
        for (let i = 0; i < NPUFF; i++) this.puffT[i] = -10;
        // the first floe: a long one under the penguin. In demo mode its end comes up within a second
        // (the showcase records from frame 0); a player gets 1.5 s to read the hint
        let first = running ? 2.4 : 6.0;
        let fi = this.freeFloe(8.0, -1e9);
        this.floeX[fi] = first - this.floeLen[fi];
        this.genX = first;
        this.made = 0;
        this.generate(api);
        // the sea's floating chunks and the backdrop
        for (let i = 0; i < NCHUNK; i++) {
            this.chunkX[i] = -4 + <f64>i * 3.2 + api.range(-0.8, 0.8);
            this.chunkZ[i] = (i % 2 == 0) ? api.range(1.7, 3.2) : api.range(-3.8, -1.9);
            this.chunkYaw[i] = api.range(0, 360);
        }
        for (let i = 0; i < NBERG; i++) {
            this.bergX[i] = -5 + <f64>i * 4.2 + api.range(-0.6, 0.6);
            this.bergZ[i] = api.range(-7.2, -5.6);
            this.bergS[i] = api.range(0.32, 0.55);
            this.bergYaw[i] = api.range(-30, 30);
        }
        this.state = running ? RUN : IDLE;
        this.v = running ? 4.0 : 0;
    }

    freeFloe(want: f64, leftEdge: f64): i32 {
        // a copy of the wanted length that is behind the camera, else any free copy
        let best = -1;
        for (let i = 0; i < 9; i++) {
            let free = this.floeX[i] < -1e8 || this.floeX[i] + this.floeLen[i] < leftEdge;
            if (!free) continue;
            if (this.floeLen[i] == want) return i;
            if (best < 0) best = i;
        }
        return best;
    }

    generate(api: GameApi): void {
        let left = this.x - 3.0;
        while (this.genX < this.x + 14) {
            let v = Math.max(this.v, 4.0);
            let jump = v * 0.61;
            let gmax = Math.min(jump - 1.0, 2.8);
            let gmin = Math.min(0.9, gmax);
            let gap = api.range(gmin, gmax);
            let r = api.rand();
            let want: f64 = r < 0.35 ? 3.0 : (r < 0.75 ? 5.0 : 8.0);
            this.made++;
            if (this.made == 2) want = 5.0; // an early seal: the second floe always has one
            let fi = this.freeFloe(want, left);
            if (fi < 0) return; // every copy on screen: try next frame
            let start = this.genX + gap;
            this.floeX[fi] = start;
            let L = this.floeLen[fi];
            this.genX = start + L;
            // a fish over the gap, sometimes
            if (api.rand() < 0.45 || this.made == 1) this.addFish(start - gap * 0.5, 0.78);
            // a seal on a long floe, more often as the run goes on
            let sealChance = Math.min(0.75, 0.35 + this.runT * 0.01);
            if (L >= 5 && (api.rand() < sealChance || this.made == 2)) {
                let sx = start + api.range(2.2, L - 2.2);
                this.addSeal(sx);
                if (api.rand() < 0.3) this.addFish(sx, 0.95);
            }
        }
    }

    addFish(fx: f64, fy: f64): void {
        for (let i = 0; i < NFISH; i++) {
            if (this.fishX[i] < this.x - 4) {
                this.fishX[i] = fx; this.fishY[i] = fy; this.fishGot[i] = -1;
                return;
            }
        }
    }

    addSeal(sx: f64): void {
        for (let i = 0; i < NSEAL; i++) {
            if (this.sealX[i] < this.x - 5) {
                this.sealX[i] = sx; this.sealHit[i] = -10;
                return;
            }
        }
    }

    // the floe under logical x (with a grace margin at its ends), or -1
    floeAt(px: f64, grace: f64): i32 {
        for (let i = 0; i < 9; i++) {
            let a = this.floeX[i];
            if (px >= a - grace && px <= a + this.floeLen[i] + grace) return i;
        }
        return -1;
    }

    // ------------------------------------------------------------------ input

    click(api: GameApi): void {
        if (this.state == IDLE) {
            this.state = RUN;
            this.v = 4.0;
            this.startT = api.time;
            this.landT = api.time; // a push-off squash
            this.mark = 0;
            api.sound(SFX_WIN, 1.0, 0.6);
            api.sound(SFX_WHOOSH, 1.2, 0.5);   // the push-off
            return;
        }
        if (this.state == DEAD) {
            if (api.time - this.deadT > 0.6) {
                this.reset(api, false);
                this.click(api);
            }
            return;
        }
        if (!this.air && this.prepT < 0) {
            this.prepT = api.time;
        } else if (this.air) {
            this.buffered = api.time;
        }
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind == POINTER_DOWN) this.click(api);
        return true;
    }

    // ------------------------------------------------------------------ the demo player

    demoThink(api: GameApi): void {
        if (this.state == DEAD) {
            if (api.time - this.deadT > 2.0) this.reset(api, true);
            return;
        }
        if (this.state != RUN || this.air || this.prepT >= 0) return;
        // the next hazard: the end of this floe, or a seal on it
        let fi = this.floeAt(this.x, 0);
        let hz: f64 = 1e9;
        let lo: f64 = 0, hi: f64 = 0;
        let v = this.v;
        let tAir = 2 * JUMPV / GRAV;
        let lead = v * PREP;
        if (fi >= 0) {
            let edge = this.floeX[fi] + this.floeLen[fi];
            // next floe start
            let next: f64 = 1e9;
            for (let i = 0; i < 9; i++) {
                if (this.floeX[i] > edge - 0.01 && this.floeX[i] < next) next = this.floeX[i];
            }
            hz = edge;
            // take-off between (land 0.2 past the next start) and (the edge)
            lo = next + 0.2 - v * tAir - lead;
            hi = edge + 0.05 - lead;
        }
        for (let i = 0; i < NSEAL; i++) {
            let s = this.sealX[i];
            if (s > this.x && s - SEAL_HALF < hz) {
                // airborne above SEAL_TOP between t1 and t2
                let d = Math.sqrt(JUMPV * JUMPV - 2 * GRAV * SEAL_TOP);
                let t1 = (JUMPV - d) / GRAV, t2 = (JUMPV + d) / GRAV;
                hz = s - SEAL_HALF;
                lo = s + SEAL_HALF - v * t2 - lead;
                hi = s - SEAL_HALF - v * t1 - lead;
            }
        }
        if (hz > 1e8) return;
        if (this.aimFor != hz) {
            // plan this one: a human aims a bit late in the window, with an error that grows with the run
            this.aimFor = hz;
            let err = (api.rand() + api.rand() + api.rand() - 1.5) * (0.2 + this.runT * 0.01) / this.skill;
            let fumble = this.runT < 4 ? 0.0 : 0.05 + this.runT * 0.004;
            if (api.rand() < fumble) err += (api.rand() < 0.5 ? -1 : 1) * 0.6; // a fumble: way early or late
            this.aimClick = lo + (hi - lo) * api.range(0.45, 0.75) + err;
        }
        if (this.x >= this.aimClick) {
            this.click(api);
        }
    }

    // ------------------------------------------------------------------ the frame

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.reset(api, api.demo);
        }
        if (api.demo) this.demoThink(api);

        let t = api.time;
        if (this.state == RUN) {
            this.runT = t - this.startT;
            this.v = Math.min(8.5, 4.0 + this.runT * 0.06);
            // a pending take-off
            if (this.prepT >= 0 && t - this.prepT >= PREP) {
                this.prepT = -1;
                this.air = true;
                this.vy = JUMPV;
                this.jumpT = t;
                // a hop, a little higher as the run gets faster
                api.soundAt(SFX_JUMP, this.x - this.origin, 0.3, 0, 1.0 + (this.v - 4.0) * 0.05, 0.6);
            }
            this.x += this.v * dt;
            if (this.air) {
                this.vy -= GRAV * dt;
                this.y += this.vy * dt;
                if (this.y <= 0 && this.vy < 0) {
                    if (this.floeAt(this.x, 0.12) >= 0) {
                        this.y = 0; this.vy = 0; this.air = false; this.landT = t;
                        this.puffBurst(api, 2);
                        api.soundAt(SFX_THUD, this.x - this.origin, 0, 0, 1.8, 0.5);    // belly on the ice
                        api.soundAt(SFX_HIT, this.x - this.origin, 0, 0, 2.2, 0.3);     // a crunch of snow
                        if (t - this.buffered < 0.16) { this.prepT = t; this.buffered = -10; }
                    } else if (this.y < -0.05) {
                        this.die(api, 1);
                    }
                }
            } else if (this.floeAt(this.x, 0.05) < 0 && this.prepT < 0) {
                // slid off the edge: drop
                this.air = true; this.vy = 0; this.jumpT = t - 1;
                api.soundAt(SFX_SHOOT, this.x - this.origin, 0, 0, 0.45, 0.55);   // over the edge: uh-oh
            }
            // seals
            for (let i = 0; i < NSEAL; i++) {
                if (Math.abs(this.x - this.sealX[i]) < SEAL_HALF && this.y < SEAL_TOP) {
                    this.sealHit[i] = t;
                    this.die(api, 2);
                    break;
                }
            }
            // fish
            for (let i = 0; i < NFISH; i++) {
                if (this.fishGot[i] < 0 && Math.abs(this.x - this.fishX[i]) < 0.45
                    && Math.abs(this.y + 0.18 - this.fishY[i]) < 0.42) {
                    this.fishGot[i] = t;
                    this.fish++;
                    // a coin a semitone higher for each fish this run (an octave at most)
                    api.soundAt(SFX_COIN, this.fishX[i] - this.origin, this.fishY[i], 0,
                        Math.pow(2, <f64>min<i32>(this.fish - 1, 12) / 12), 0.75);
                    this.popT = t; this.popX = this.fishX[i]; this.popY = this.fishY[i];
                }
            }
            this.score = <i32>Math.floor(this.x) + this.fish * 5;
            let m = <i32>Math.floor(this.x / 50);
            if (m > this.mark) {
                // every 50 m: a bell, a step higher each time (the run is getting faster)
                this.mark = m;
                api.note(<f64>(76 + min<i32>(m - 1, 8) * 2), 0.5, 0, SFX_BELL);
            }
            if (!this.air && t - this.lastPuff > 0.13) { this.lastPuff = t; this.puffBurst(api, 1); }
            this.camX = this.x + LEAD;
            this.generate(api);
        } else if (this.state == DEAD) {
            let k = t - this.deadT;
            if (this.cause == 1) {
                // into the sea: on a little, down, gone
                this.x += this.deadVX * dt;
                this.deadVX *= Math.pow(0.05, dt);
                this.vy -= GRAV * dt;
                this.y = Math.max(this.y + this.vy * dt, SEA - 0.8);
            } else {
                // bonked: bounced back, tumbling, onto the ice on its back
                if (this.air) {
                    this.x += this.deadVX * dt;
                    this.vy -= GRAV * dt;
                    this.y += this.vy * dt;
                    this.spin += 600 * dt;
                    if (this.y <= 0 && this.vy < 0) {
                        if (this.floeAt(this.x, 0.1) >= 0) {
                            this.y = 0; this.air = false; this.landT = t; this.spin = 180;
                            this.puffBurst(api, 2);
                            api.soundAt(SFX_THUD, this.x - this.origin, 0, 0, 1.2, 0.6);
                        } else if (this.y < -0.05) {
                            this.cause = 1; this.deadVX = 0; // into a hole after all
                        }
                    }
                }
            }
        }

        // the origin follows the penguin in 12 m steps
        while (this.x - this.origin > 4.0) this.origin += WRAP;
        while (this.x - this.origin < -8.0) this.origin -= WRAP;

        this.layout(api);
    }

    die(api: GameApi, cause: i32): void {
        this.state = DEAD;
        this.cause = cause;
        this.deadT = api.time;
        this.prepT = -1;
        this.shake = api.time;
        this.splashT = -10;
        if (cause == 1) {
            this.deadVX = this.v * 0.5;
            if (this.vy > 0) this.vy = 0;
        } else {
            this.deadVX = -1.8;
            this.vy = 3.6;
            this.air = true;
        }
        this.runs++;
        if (cause == 2) {
            api.soundAt(SFX_POP, this.x - this.origin, 0.3, 0, 0.32, 1.0);   // BONK!
            api.soundAt(SFX_HIT, this.x - this.origin, 0.3, 0, 0.9, 0.6);
        }
        api.sound(SFX_LOSE, 1.0, 0.8);
        if (this.score > this.best && this.best > 0) {
            api.note(84, 0.45, 0, SFX_BELL);   // a new best
        }
        if (this.score > this.best) this.best = this.score;
    }

    puffBurst(api: GameApi, n: i32): void {
        for (let k = 0; k < n; k++) {
            let i = this.nextPuff;
            this.nextPuff = (this.nextPuff + 1) % NPUFF;
            this.puffX[i] = this.x - 0.42 + api.range(-0.08, 0.08) + (n > 1 ? <f64>k * 0.5 - 0.1 : 0);
            this.puffZ[i] = api.range(-0.25, 0.3);
            this.puffT[i] = api.time;
            this.puffS[i] = n > 1 ? 1.2 : api.range(0.65, 1.0);
        }
    }

    // ------------------------------------------------------------------ placing the bones

    // M = T(x,y,z) * T(c) * Ry(yaw) Rx(pitch) Rz(roll) * S(sx,sy,sz) * T(-c) * Ry(-yaw0) * T(-p0):
    // a turn and a per-axis squash together about a pivot cy above the object's base (the API's
    // place() turns without squash, placeScaled() squashes without pitch or roll).
    put(api: GameApi, b: i32, x: f64, y: f64, z: f64, yawDeg: f64, pitchDeg: f64, rollDeg: f64,
        sx: f64, sy: f64, sz: f64, cy: f64): void {
        if (b <= 0 || b >= 64) return;
        let d2r = Math.PI / 180;
        let cyw = Math.cos(yawDeg * d2r), syw = Math.sin(yawDeg * d2r);
        let cp = Math.cos(pitchDeg * d2r), sp = Math.sin(pitchDeg * d2r);
        let cr = Math.cos(rollDeg * d2r), sr = Math.sin(rollDeg * d2r);
        let r00 = cyw * cr + syw * sp * sr, r01 = -cyw * sr + syw * sp * cr, r02 = syw * cp;
        let r10 = cp * sr, r11 = cp * cr, r12 = -sp;
        let r20 = -syw * cr + cyw * sp * sr, r21 = syw * sr + cyw * sp * cr, r22 = cyw * cp;
        // R * S
        let a00 = r00 * sx, a01 = r01 * sy, a02 = r02 * sz;
        let a10 = r10 * sx, a11 = r11 * sy, a12 = r12 * sz;
        let a20 = r20 * sx, a21 = r21 * sy, a22 = r22 * sz;
        // * Ry(-yaw0) = [[c0, 0, -s0], [0, 1, 0], [s0, 0, c0]]
        let y0 = <f64>api.restYaw[b] * d2r;
        let c0 = Math.cos(y0), s0 = Math.sin(y0);
        let m00 = a00 * c0 + a02 * s0, m01 = a01, m02 = -a00 * s0 + a02 * c0;
        let m10 = a10 * c0 + a12 * s0, m11 = a11, m12 = -a10 * s0 + a12 * c0;
        let m20 = a20 * c0 + a22 * s0, m21 = a21, m22 = -a20 * s0 + a22 * c0;
        // translation: x + c - (R S) c - M p0, with c = (0, cy, 0) in the turned frame
        let px = <f64>api.restX[b], py = <f64>api.restY[b] + cy, pz = <f64>api.restZ[b];
        let tx = x - (m00 * px + m01 * py + m02 * pz) + 0;
        let ty = y + cy - (m10 * px + m11 * py + m12 * pz);
        let tz = z - (m20 * px + m21 * py + m22 * pz);
        // the pivot terms: M p0 above used p0 + c; the c offset was added back through y + cy
        let m = b * 12;
        api.mats[m] = <f32>m00; api.mats[m + 1] = <f32>m01; api.mats[m + 2] = <f32>m02; api.mats[m + 3] = <f32>tx;
        api.mats[m + 4] = <f32>m10; api.mats[m + 5] = <f32>m11; api.mats[m + 6] = <f32>m12; api.mats[m + 7] = <f32>ty;
        api.mats[m + 8] = <f32>m20; api.mats[m + 9] = <f32>m21; api.mats[m + 10] = <f32>m22; api.mats[m + 11] = <f32>tz;
        api.dirty[b] = true;
        api.anyDirty = true;
    }

    layout(api: GameApi): void {
        let t = api.time;
        // the art grid's texel (gridH is known from the second frame on: the camera of the last drawn frame)
        let tex = api.orthoHeight / (api.gridH > 2 ? <f64>api.gridH : 136.0);
        // the camera: a small shake on a crash (whole texels)
        let camL = this.camX - this.origin;
        let sk = t - this.shake;
        let shakeX: f64 = 0;
        if (sk < 0.25) shakeX = (Math.floor(sk * 30) % 2 == 0 ? 2 : -2) * tex * (1 - sk / 0.25);
        api.targetX = camL + shakeX;
        api.targetY = CAMY;
        api.targetZ = 0;
        let snapCam = Math.round(camL / tex) * tex;
        let step = Math.floor(t * 12) / 12; // stepped animation clock (12 fps)

        // the floes
        for (let i = 0; i < 9; i++) {
            let a = this.floeX[i];
            if (a < -1e8 || a + this.floeLen[i] < this.camX - 6 || a > this.camX + 6) {
                api.hide(this.floeBone[i]);
            } else {
                api.place(this.floeBone[i], a + this.floeLen[i] * 0.5 - this.origin, 0, 0, 0);
            }
        }
        // the sea and its chunks, the backdrop
        api.place(this.sea, snapCam, 0, 0, 0);
        for (let i = 0; i < NCHUNK; i++) {
            if (this.chunkX[i] < this.camX - 5.5) {
                this.chunkX[i] += 16 + api.range(-1, 1);
                this.chunkYaw[i] = api.range(0, 360);
            }
            let bob = (Math.floor(t * 4 + <f64>i * 1.7) % 2 == 0) ? 0 : -0.02;
            api.place(this.chunkBone[i], this.chunkX[i] - this.origin, SEA + bob, this.chunkZ[i], this.chunkYaw[i]);
        }
        // two 8 m strips of wave crests, still in the world
        let wbase = Math.floor(this.camX / 8) * 8;
        for (let i = 0; i < 2; i++) api.place(this.waveBone[i], wbase + <f64>i * 8 - this.origin, 0, 0, 0);
        let par = this.camX * 0.35;
        for (let i = 0; i < NBERG; i++) {
            let off = this.bergX[i] - par;
            if (off < -6.5) { this.bergX[i] += 16.8; off += 16.8; this.bergZ[i] = api.range(-7.2, -5.6); }
            let bx = snapCam + Math.round(off / tex) * tex;
            api.place(this.bergBone[i], bx, SEA, this.bergZ[i], this.bergYaw[i], 0, 0, this.bergS[i]);
        }
        let rp = this.camX * 0.12;
        for (let i = 0; i < 2; i++) {
            let off = (<f64>i * 16.0 - rp) % 32.0;
            if (off < -16) off += 32;
            let rx = snapCam + Math.round(off / tex) * tex;
            this.put(api, this.ridgeBone[i], rx, SEA, -8.5, 0, 0, 0, 1, 0.42, 1, 0);
        }

        // seals: breathing, a look up as the penguin comes, a startled hop when bonked
        for (let i = 0; i < NSEAL; i++) {
            let s = this.sealX[i];
            if (s < this.camX - 6 || s > this.camX + 6) { api.hide(this.sealBone[i]); continue; }
            let hk = t - this.sealHit[i];
            let breathe = 1 + 0.04 * Math.sin(step * 4 + <f64>i);
            let look = (this.x < s && s - this.x < 2.2 && this.state == RUN) ? -14.0 : 0.0;
            let hop: f64 = 0;
            let sq: f64 = 1;
            if (hk < 0.5) { hop = Math.max(0, Math.sin(hk / 0.5 * Math.PI)) * 0.25; sq = hk < 0.08 ? 0.75 : 1.1; }
            this.put(api, this.sealBone[i], s - this.origin, hop, 0, -90, look, 0, 1 / Math.sqrt(sq * breathe), sq * breathe, 1 / Math.sqrt(sq * breathe), 0.2);
        }
        // fish: spinning, bobbing; a pop when caught
        for (let i = 0; i < NFISH; i++) {
            let fx = this.fishX[i];
            if (fx < this.camX - 6 || fx > this.camX + 6) { api.hide(this.fishBone[i]); continue; }
            let g = this.fishGot[i];
            if (g >= 0) {
                let k = t - g;
                if (k > 0.16) { api.hide(this.fishBone[i]); continue; }
                let s = 1 + k * 5;
                api.place(this.fishBone[i], fx - this.origin, this.fishY[i] + k * 1.2, 0, step * 360, 0, 0, s);
                continue;
            }
            let bob = 0.05 * Math.sin(step * 5 + <f64>i * 2);
            api.place(this.fishBone[i], fx - this.origin, this.fishY[i] + bob, 0, step * 240 + <f64>i * 50, 0, 25 * Math.sin(step * 3));
        }
        // snow puffs: pop up, drift, shrink
        for (let i = 0; i < NPUFF; i++) {
            let k = t - this.puffT[i];
            if (k > 0.45) { api.hide(this.puffBone[i]); continue; }
            let u = Math.floor(k * 12) / 12 / 0.45;
            let s = this.puffS[i] * (u < 0.25 ? 0.5 + u * 2 : 1 - (u - 0.25) / 0.75 * 0.85);
            api.place(this.puffBone[i], this.puffX[i] - this.origin, 0.02 + u * 0.12, this.puffZ[i], <f64>i * 70, 0, 0, s);
        }
        // the splash
        if (this.state == DEAD && this.cause == 1 && this.splashT > 0) {
            let k = t - this.splashT;
            let u = Math.floor(k * 12) / 12;
            let s = u < 0.15 ? 0.4 + u / 0.15 * 0.9 : Math.max(0, 1.3 - (u - 0.15) * 1.6);
            if (s > 0.05) {
                this.put(api, this.splash, this.splashX - this.origin, SEA, 0, 0, 0, 0, s, s * (u < 0.15 ? 1.2 : 1), s, 0);
            } else api.hide(this.splash);
        } else api.hide(this.splash);

        this.placePenguin(api, tex, snapCam);
    }

    splashX: f64 = 0;
    splashT: f64 = -10;     // when the penguin hit the water

    placePenguin(api: GameApi, tex: f64, snapCam: f64): void {
        let t = api.time;
        let px: f64;
        if (this.state == DEAD) {
            px = this.x - this.origin;
        } else {
            px = snapCam - LEAD; // on the snapped grid: no crawl while the camera follows
        }
        let pitch: f64 = 0, roll: f64 = 0;
        let sx: f64 = 1, sy: f64 = 1, sz: f64 = 1;
        let y = this.y;
        let step = Math.floor(t * 12) / 12;
        if (this.state == IDLE) {
            // waiting: a little breathing rock
            let b = Math.sin(step * 3);
            sy = 1 + 0.04 * b; sx = 1 / Math.sqrt(sy); sz = sx;
            pitch = -4 + 3 * b;
        } else if (this.state == RUN) {
            if (this.prepT >= 0) {
                // anticipation: squash down, nose dips
                sy = 0.72; sx = 1.12; sz = 1.15; pitch = 6;
            } else if (this.air) {
                let k = t - this.jumpT;
                let T = 2 * JUMPV / GRAV;
                let st = Math.max(0, 1 - k / 0.18);
                sy = 1 + 0.3 * st; sx = 1 / Math.sqrt(sy); sz = 1 - 0.12 * st;
                pitch = -22 + 40 * Math.min(1.2, Math.floor(k * 12) / 12 / T);
            } else {
                let k = t - this.landT;
                if (k < 0.25) {
                    let u = Math.floor(k * 24) / 24 / 0.25;
                    sy = 1 - 0.3 * Math.cos(u * Math.PI * 1.5) * (1 - u);
                    sx = 1 / Math.sqrt(sy); sz = 1 + (1 - sy) * 0.6;
                } else {
                    // sliding: a stepped wobble
                    roll = (Math.floor(t * 8) % 2 == 0) ? 3 : -3;
                    y += (Math.floor(t * 8) % 2 == 0) ? 0.0 : tex;
                }
            }
        } else {
            let k = t - this.deadT;
            if (this.cause == 1) {
                pitch = Math.min(70, 30 + k * 120);
                if (this.y < SEA + 0.1 && this.splashT < 0) {
                    this.splashT = t; this.splashX = this.x; this.shake = t;
                    api.soundAt(SFX_SPLASH, this.x - this.origin, SEA, 0, 0.8, 0.9);   // SPLASH!
                }
                if (this.y < SEA - 0.45) { api.hide(this.penguin); return; }
            } else {
                if (this.air) {
                    pitch = -this.spin;
                } else {
                    // on its back, flippers wiggling
                    roll = 180 + ((Math.floor(t * 6) % 2 == 0) ? 6 : -6);
                    let kk = t - this.landT;
                    if (kk < 0.2) { sy = 0.75; sx = 1.15; sz = 1.1; }
                }
            }
        }
        this.put(api, this.penguin, px, y, 0, 90, pitch, roll, sx, sy, sz, 0.17);
    }

    // ------------------------------------------------------------------ the HUD

    hud(api: GameApi): void {
        let dark = api.rampColor(R_FEATHER, 0);
        let mint = api.rampColor(R_SNOW, 1);
        let pale = api.rampColor(R_SNOW, 2);
        let teal = api.rampColor(R_SNOW, 0);
        let t = api.time;
        let W = <f32>api.hudW;
        let shown = this.state == IDLE ? this.best : this.score;
        api.text(5, 5, shown.toString() + " M", dark, 2, mint);
        let bs = "BEST " + this.best.toString();
        api.text(W - api.textWidth(bs, 1) - 5, 5, bs, teal, 1, pale);
        if (this.fish > 0 || this.state == RUN) {
            let fs = "FISH " + this.fish.toString();
            api.text(W - api.textWidth(fs, 1) - 5, 13, fs, teal, 1, pale);
        }
        if (this.state == IDLE) {
            api.textCentered(8, "CLICK TO JUMP", dark, 2, mint);
            api.textCentered(22, "OVER HOLES AND SEALS", dark, 1, mint);
        } else if (this.state == RUN && this.runT < 2.0 && !api.demo) {
            api.textCentered(8, "CLICK TO JUMP", dark, 2, mint);
        } else if (this.state == DEAD) {
            let k = t - this.deadT;
            if (k > 0.25) {
                api.textCentered(6, this.cause == 1 ? "SPLASH!" : "BONK!", dark, 3, mint);
                let line = this.score.toString() + " M   " + this.fish.toString() + " FISH";
                api.textCentered(25, line, dark, 1, mint);
                if (!api.demo && k > 0.6 && Math.floor(t * 2) % 2 == 0) {
                    api.textCentered(33, "CLICK TO SLIDE AGAIN", dark, 1, mint);
                }
            }
        }
        if (api.demo) {
            api.textCentered(<f32>api.hudH - 10, "CLICK TO JUMP", pale, 1, dark);
        }
        // "+5" over a caught fish
        let pk = t - this.popT;
        if (pk < 0.6 && api.project(<f32>(this.popX - this.origin), <f32>(this.popY + 0.3 + pk * 0.6), 0)) {
            api.text(api.screenX - 3, api.screenY - 3, "+5", dark, 1, pale);
        }
    }
}
