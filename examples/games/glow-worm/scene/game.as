// Glow Worm: a glowing worm follows the pointer through a dark cave. Lead it to the crystals: each
// one it eats runs down its body as a bulge and grows it a bead longer (and a little faster). Its
// head must never touch its own body, nor a stalagmite. Pointer only: move to steer, click to start.
// The body is a chain of pooled bead bones laid along the path the head has drawn; every bead and
// the head carry their own stippled pool of light, so the worm lights the cave as it crawls.
import { GameApi, POINTER_DOWN, POINTER_MOVE } from "./game_api";

const ST_IDLE: i32 = 0;   // before the first click: the worm idles round the middle, no deaths
const ST_PLAY: i32 = 1;
const ST_DIE: i32 = 2;    // the worm breaks up, bead by bead, its light going out
const ST_OVER: i32 = 3;

// the arena (models/env/make_env.py): an ellipse round (0, Z0)
const A: f64 = 4.0;
const B: f64 = 2.45;
const Z0: f64 = 0.25;
const WALL: f64 = 0.9;        // past this (normalised radius) the walls turn the worm back in

const NSEG: i32 = 46;         // the bead pool (scene.bake.json "seg", copies 46)
const NGEM: i32 = 4;
const NSPARK: i32 = 8;
const START_LEN: i32 = 6;
const GAP0: f64 = 0.30;       // head to the first bead, along the path
const GAP: f64 = 0.25;        // bead to bead
const PSTEP: f64 = 0.05;      // path samples
const PN: i32 = 420;          // path ring buffer (>= (GAP0 + NSEG * GAP) / PSTEP + margin)
const TURN: f64 = 4.2;        // radians a second at most
const EAT_R: f64 = 0.44;
const BITE_R: f64 = 0.29;     // the head touching a bead (index >= 3)

// palette indices (art/palette.json "colors")
const C_DARK: i32 = 0;
const C_SLATE: i32 = 1;
const C_PALE: i32 = 2;

export class Game {
    state: i32 = ST_IDLE;
    stateT: f64 = 0;
    runT: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    wasDemo: bool = false;
    cause: string = "";

    head: i32 = -1;
    segB: StaticArray<i32> = new StaticArray<i32>(NSEG);
    gemB: StaticArray<i32> = new StaticArray<i32>(NGEM);
    sparkB: StaticArray<i32> = new StaticArray<i32>(NSPARK);

    // pillars (stalagmites): the bake's positions and a hit radius each
    pX: StaticArray<f64> = [-1.8, 1.95, 0.25];
    pZ: StaticArray<f64> = [-0.35, -0.55, 1.5];
    pR: StaticArray<f64> = [0.47, 0.43, 0.41];

    // the worm
    hx: f64 = 0;
    hz: f64 = 0;
    hd: f64 = 0;              // heading (radians; 0 = +z, towards the camera)
    speed: f64 = 2.0;
    len: i32 = START_LEN;     // beads
    tx: f64 = 0;              // where it is led
    tz: f64 = 0;
    gulpT: f64 = 0;           // > 0: the head's gulp
    bulge: StaticArray<f64> = new StaticArray<f64>(6);   // bulges running down the body (bead index), < 0 idle
    growT: f64 = 1;           // < 1: the newest tail bead grows in
    // the path: newest sample at pi
    pathX: StaticArray<f64> = new StaticArray<f64>(PN);
    pathZ: StaticArray<f64> = new StaticArray<f64>(PN);
    pi: i32 = 0;
    pcount: i32 = 0;
    segX: StaticArray<f64> = new StaticArray<f64>(NSEG);
    segZ: StaticArray<f64> = new StaticArray<f64>(NSEG);
    segYaw: StaticArray<f64> = new StaticArray<f64>(NSEG);
    dieK: f64 = 0;            // beads popped so far while dying

    // crystals: 0 hidden, 1 growing in, 2 shining, 3 eaten (shrinks into the mouth)
    gS: StaticArray<i32> = new StaticArray<i32>(NGEM);
    gT: StaticArray<f64> = new StaticArray<f64>(NGEM);
    gX: StaticArray<f64> = new StaticArray<f64>(NGEM);
    gZ: StaticArray<f64> = new StaticArray<f64>(NGEM);
    gYaw: StaticArray<f64> = new StaticArray<f64>(NGEM);
    spawnT: f64 = 0;
    idleGems: bool = false;   // spawning for the idle worm: keep off its loop

    // sparks
    sT: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    sX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    sY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    sZ: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    sVX: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    sVY: StaticArray<f64> = new StaticArray<f64>(NSPARK);
    sVZ: StaticArray<f64> = new StaticArray<f64>(NSPARK);

    // juice
    shakeT: f64 = 0;
    camTX: f64 = 0;
    camTY: f64 = 0;
    popT: f64 = -1;
    popX: f32 = 0;
    popY: f32 = 0;
    popText: string = "";

    // the demo player
    dThink: f64 = 0;
    dLapse: f64 = 0;          // > 0: not looking where it goes (a human's slip)
    dErrX: f64 = 0;
    dErrZ: f64 = 0;
    dGoal: i32 = -1;

    start(api: GameApi): void {
        api.playable = true;
        this.head = api.bone("head");
        for (let i = 0; i < NSEG; i++) {
            this.segB[i] = api.bone("seg" + i.toString());
        }
        for (let i = 0; i < NGEM; i++) {
            this.gemB[i] = api.bone("gem" + i.toString());
        }
        for (let i = 0; i < NSPARK; i++) {
            this.sparkB[i] = api.bone("spark" + i.toString());
        }
        this.camTX = api.targetX;
        this.camTY = api.targetY;
        this.wasDemo = api.demo;
        this.resetWorld(api, api.demo);
        if (api.demo) {
            this.beginRun();
        }
    }

    // ------------------------------------------------------------------ run control

    // forPlay: the first crystal right ahead (a run starts at once); otherwise every crystal clear of
    // the idle worm's loop
    resetWorld(api: GameApi, forPlay: bool): void {
        // the worm lies straight on the left, heading right and a little forward
        this.hx = -2.6;
        this.hz = 0.9;
        this.hd = 1.75;
        this.len = START_LEN;
        this.speed = 2.0;
        this.gulpT = 0;
        this.growT = 1;
        this.dieK = 0;
        for (let k = 0; k < 6; k++) {
            this.bulge[k] = -1;
        }
        let dx = Math.sin(this.hd), dz = Math.cos(this.hd);
        this.pcount = PN;
        this.pi = PN - 1;
        for (let k = 0; k < PN; k++) {
            // sample PN-1 is the head; older samples run straight back
            let back = <f64>(PN - 1 - k) * PSTEP;
            this.pathX[k] = this.hx - dx * back;
            this.pathZ[k] = this.hz - dz * back;
        }
        this.tx = this.hx + dx * 2.0;
        this.tz = this.hz + dz * 2.0;
        for (let i = 0; i < NGEM; i++) {
            this.gS[i] = 0;
        }
        for (let i = 0; i < NSPARK; i++) {
            this.sT[i] = -1;
        }
        this.idleGems = !forPlay;
        if (forPlay) {
            // the first crystal right ahead (action within a second), two more about the cave
            this.placeGem(api, 0, this.hx + dx * 1.5, this.hz + dz * 1.5);
        } else {
            this.spawnGem(api, 0);
        }
        this.spawnGem(api, 1);
        this.spawnGem(api, 2);
        this.idleGems = false;
        this.spawnT = 0;
        this.score = 0;
        this.runT = 0;
        this.cause = "";
        this.dLapse = 0;
        this.dThink = 0;
    }

    beginRun(): void {
        this.state = ST_PLAY;
        this.stateT = 0;
        this.runT = 0;
    }

    die(api: GameApi, cause: string): void {
        this.state = ST_DIE;
        this.stateT = 0;
        this.cause = cause;
        this.shakeT = 0.35;
        this.burst(api, this.hx, 0.3, this.hz, 6);
        if (this.score > this.best) {
            this.best = this.score;
        }
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged || api.demo != this.wasDemo) {
            // the host switched demo on or off: a fresh run either way (demo plays at once, a visitor
            // gets the idle worm and the hint)
            this.wasDemo = api.demo;
            this.resetWorld(api, api.demo);
            this.state = ST_IDLE;
            this.stateT = 0;
            if (api.demo) {
                this.beginRun();
            }
        }
        this.stateT += dt;
        if (this.state == ST_PLAY) {
            this.runT += dt;
        }
        if (this.state == ST_IDLE) {
            // a lazy loop round the middle, clear of the stalagmites
            let t = api.time * 0.55;
            this.tx = 0.1 + 1.25 * Math.sin(t);
            this.tz = 0.35 + 0.75 * Math.cos(t);
        } else if (this.state == ST_PLAY && api.demo) {
            this.demoThink(api, dt);
        }
        if (this.state == ST_IDLE || this.state == ST_PLAY) {
            this.moveHead(api, dt);
        }
        if (this.state == ST_DIE && this.stateT > 1.6) {
            this.state = ST_OVER;
            this.stateT = 0;
        }
        if (this.state == ST_OVER && api.demo && this.stateT > 2.0) {
            this.resetWorld(api, true);
            this.beginRun();
        }
        this.layBody(api, dt);
        this.updateGems(api, dt);
        this.updateSparks(api, dt);
        // camera shake: whole art pixels (the view's up is (0, cos 58, -sin 58))
        if (this.shakeT > 0) {
            this.shakeT -= dt;
            let k = Math.floor(api.time * 30);
            let ox = (Math.sin(k * 12.9898) * 43758.5453) % 1.0;
            let oy = (Math.sin(k * 78.233) * 12543.1234) % 1.0;
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
    }

    // The head turns towards the target at a limited rate and crawls on; the walls turn it back in.
    moveHead(api: GameApi, dt: f64): void {
        let playing = this.state == ST_PLAY;
        let dx = this.tx - this.hx, dz = this.tz - this.hz;
        let want = this.hd;
        if (dx * dx + dz * dz > 0.4 * 0.4) {
            want = Math.atan2(dx, dz);
        }
        // near the wall and heading out: aim back at the middle
        let e = this.ell(this.hx, this.hz);
        if (e > WALL) {
            let nx = -this.hx / (A * A), nz = -(this.hz - Z0) / (B * B);
            let out = Math.sin(this.hd) * nx + Math.cos(this.hd) * nz;
            if (out < 0.2) {
                want = Math.atan2(-this.hx, Z0 - this.hz);
            }
        }
        let d = want - this.hd;
        while (d > Math.PI) { d -= 2 * Math.PI; }
        while (d < -Math.PI) { d += 2 * Math.PI; }
        let mx = TURN * dt;
        this.hd += Math.max(-mx, Math.min(mx, d));
        let sp = this.state == ST_IDLE ? 1.5 : this.speed;
        this.hx += Math.sin(this.hd) * sp * dt;
        this.hz += Math.cos(this.hd) * sp * dt;
        // the wall itself: slide along it
        e = this.ell(this.hx, this.hz);
        if (e > 1.0) {
            this.hx /= e;
            this.hz = Z0 + (this.hz - Z0) / e;
        }
        // record the path
        let lx = this.pathX[this.pi], lz = this.pathZ[this.pi];
        let ddx = this.hx - lx, ddz = this.hz - lz;
        if (ddx * ddx + ddz * ddz >= PSTEP * PSTEP) {
            this.pi = (this.pi + 1) % PN;
            this.pathX[this.pi] = this.hx;
            this.pathZ[this.pi] = this.hz;
        }
        if (!playing) {
            return;
        }
        // eat
        for (let g = 0; g < NGEM; g++) {
            if (this.gS[g] == 1 || this.gS[g] == 2) {
                let gx = this.gX[g] - this.hx, gz = this.gZ[g] - this.hz;
                if (gx * gx + gz * gz < EAT_R * EAT_R) {
                    this.eat(api, g);
                }
            }
        }
        // die: a stalagmite, or the body (skip the first beads: the neck bends)
        for (let p = 0; p < 3; p++) {
            let px = this.pX[p] - this.hx, pz = this.pZ[p] - this.hz;
            if (px * px + pz * pz < this.pR[p] * this.pR[p]) {
                this.die(api, "IT HIT A STALAGMITE");
                return;
            }
        }
        for (let i = 3; i < this.len; i++) {
            let sx = this.segX[i] - this.hx, sz = this.segZ[i] - this.hz;
            if (sx * sx + sz * sz < BITE_R * BITE_R) {
                this.die(api, "IT CROSSED ITS OWN TAIL");
                return;
            }
        }
    }

    ell(x: f64, z: f64): f64 {
        let u = x / A, v = (z - Z0) / B;
        return Math.sqrt(u * u + v * v);
    }

    eat(api: GameApi, g: i32): void {
        this.gS[g] = 3;
        this.gT[g] = 0;
        this.score += 1;
        this.gulpT = 0.3;
        this.speed = Math.min(3.0, 2.0 + 0.04 * <f64>this.score);
        for (let k = 0; k < 6; k++) {
            if (this.bulge[k] < 0) {
                this.bulge[k] = 0;
                break;
            }
        }
        this.burst(api, this.gX[g], 0.45, this.gZ[g], 5);
        if (api.project(<f32>this.gX[g], 0.9, <f32>this.gZ[g])) {
            this.popX = api.screenX;
            this.popY = api.screenY;
            this.popT = 0;
            this.popText = "+1";
        }
        this.spawnT = 0.5;
    }

    // ------------------------------------------------------------------ the body

    // Walks the path back from the head once, dropping a bead every GAP; places the head and beads.
    layBody(api: GameApi, dt: f64): void {
        // bulges run down the body; one reaching the tail adds a bead
        for (let k = 0; k < 6; k++) {
            if (this.bulge[k] >= 0) {
                this.bulge[k] += dt * 11.0;
                if (this.bulge[k] > <f64>this.len + 0.5) {
                    this.bulge[k] = -1;
                    if (this.len < NSEG && this.state == ST_PLAY) {
                        this.len += 1;
                        this.growT = 0;
                    }
                }
            }
        }
        if (this.growT < 1) {
            this.growT = Math.min(1.0, this.growT + dt * 3.0);
        }
        // positions along the path
        let want = GAP0;
        let seg = 0;
        let acc = 0.0;
        let k = this.pi;
        let ax = this.hx, az = this.hz;
        let n = 0;
        while (seg < this.len && n < PN - 1) {
            let bx = this.pathX[k], bz = this.pathZ[k];
            let sx = bx - ax, sz = bz - az;
            let l = Math.sqrt(sx * sx + sz * sz);
            while (seg < this.len && acc + l >= want) {
                let f = l > 1e-6 ? (want - acc) / l : 0.0;
                this.segX[seg] = ax + sx * f;
                this.segZ[seg] = az + sz * f;
                // facing: from this point towards the head (back along the path segment)
                this.segYaw[seg] = Math.atan2(-sx, -sz);
                seg++;
                want += GAP;
            }
            acc += l;
            ax = bx; az = bz;
            k = (k - 1 + PN) % PN;
            n++;
        }
        for (let i = seg; i < this.len; i++) {
            this.segX[i] = ax;
            this.segZ[i] = az;
            this.segYaw[i] = this.hd;
        }
        // stepped crawl (12 fps): a squash-and-stretch wave running back down the body
        let tick = Math.floor(api.time * 12.0) / 12.0;
        let dying = this.state == ST_DIE || this.state == ST_OVER;
        let popRate = 26.0;
        if (dying) {
            this.dieK = (this.stateT - 0.35) * popRate;
        }
        for (let i = 0; i < NSEG; i++) {
            let b = this.segB[i];
            if (i >= this.len) {
                api.hide(b);
                continue;
            }
            // tail taper
            let s = 1.0;
            let fromEnd = this.len - 1 - i;
            if (fromEnd == 0) { s = 0.6; } else if (fromEnd == 1) { s = 0.74; } else if (fromEnd == 2) { s = 0.87; }
            if (fromEnd == 0 && this.growT < 1) {
                s *= 0.3 + 0.7 * Math.floor(this.growT * 6) / 6;
            }
            for (let q = 0; q < 6; q++) {
                if (this.bulge[q] >= 0) {
                    let d = Math.abs(<f64>i - this.bulge[q]);
                    if (d < 1.5) {
                        s *= 1.0 + 0.32 * (1.0 - d / 1.5);
                    }
                }
            }
            let w = Math.sin(tick * 9.0 - <f64>i * 0.85);
            let sxz = 1.0 - 0.07 * w, sl = 1.0 + 0.1 * w;
            let yaw = this.segYaw[i] * 180 / Math.PI;
            if (dying) {
                // the light goes out from the head back: each bead swells, then is gone
                let d = this.dieK - <f64>i;
                if (d > 1.0) {
                    api.hide(b);
                    continue;
                }
                if (d > 0) {
                    s *= 1.0 + 0.45 * d;
                    if (d < 0.08 && i % 3 == 0) {
                        this.burst(api, this.segX[i], 0.25, this.segZ[i], 1);
                    }
                }
                sxz = 1.0; sl = 1.0;
            }
            api.placeScaled(b, this.segX[i], 0, this.segZ[i], yaw, sxz * s, sxz * s, sl * s);
        }
        // the head: a gulp when it eats; nods as it crawls; blinks out when it dies
        let hs = 1.0;
        if (this.gulpT > 0) {
            this.gulpT -= dt;
            let g = Math.floor((0.3 - this.gulpT) * 15) / 15 / 0.3;
            hs = 1.0 + 0.3 * Math.sin(g * Math.PI);
        }
        let nod = Math.floor(Math.sin(tick * 9.0) * 2.0) * 3.0;
        let hy = this.hd * 180 / Math.PI;
        if (dying) {
            if (this.stateT < 0.35 && Math.floor(this.stateT * 14) % 2 == 1) {
                api.hide(this.head);
                return;
            }
            if (this.stateT >= 0.35) {
                // dark: the head sinks a little and dims to a husk (shrinks)
                let fade = Math.min(1.0, (this.stateT - 0.35) / 0.5);
                hs = 1.0 - 0.35 * Math.floor(fade * 5) / 5;
            }
            nod = 12;
        }
        api.place(this.head, this.hx, 0, this.hz, hy, nod, 0, hs);
    }

    // ------------------------------------------------------------------ crystals

    placeGem(api: GameApi, g: i32, x: f64, z: f64): void {
        this.gS[g] = 1;
        this.gT[g] = 0;
        this.gX[g] = x;
        this.gZ[g] = z;
        this.gYaw[g] = api.range(0, 360);
    }

    // A crystal at a random clear spot: inside the walls, off the stalagmites, the worm and the others.
    spawnGem(api: GameApi, g: i32): bool {
        for (let tries = 0; tries < 30; tries++) {
            let a = api.range(0, Math.PI * 2);
            let r = Math.sqrt(api.rand()) * 0.8;
            let x = Math.sin(a) * r * A, z = Z0 + Math.cos(a) * r * B;
            let ok = true;
            for (let p = 0; p < 3 && ok; p++) {
                let px = this.pX[p] - x, pz = this.pZ[p] - z;
                ok = px * px + pz * pz > 1.1 * 1.1;
            }
            let hx = this.hx - x, hz = this.hz - z;
            if (hx * hx + hz * hz < 1.2 * 1.2) {
                ok = false;
            }
            if (this.idleGems) {
                let u = (x - 0.1) / 1.25, v = (z - 0.35) / 0.75;
                let r = Math.sqrt(u * u + v * v);
                if (r > 0.45 && r < 1.7) {
                    ok = false;
                }
            }
            for (let i = 0; i < this.len && ok; i++) {
                let sx = this.segX[i] - x, sz = this.segZ[i] - z;
                ok = sx * sx + sz * sz > 0.55 * 0.55;
            }
            for (let o = 0; o < NGEM && ok; o++) {
                if (o != g && this.gS[o] != 0) {
                    let ox = this.gX[o] - x, oz = this.gZ[o] - z;
                    ok = ox * ox + oz * oz > 1.3 * 1.3;
                }
            }
            if (ok) {
                this.placeGem(api, g, x, z);
                return true;
            }
        }
        return false;
    }

    updateGems(api: GameApi, dt: f64): void {
        // keep three crystals in the cave
        let live = 0;
        for (let g = 0; g < NGEM; g++) {
            if (this.gS[g] == 1 || this.gS[g] == 2) {
                live++;
            }
        }
        if (this.state == ST_PLAY && live < 3) {
            this.spawnT -= dt;
            if (this.spawnT <= 0) {
                for (let g = 0; g < NGEM; g++) {
                    if (this.gS[g] == 0) {
                        if (!this.spawnGem(api, g)) {
                            this.spawnT = 0.2;
                        } else {
                            this.spawnT = 0.35;
                        }
                        break;
                    }
                }
            }
        }
        for (let g = 0; g < NGEM; g++) {
            let b = this.gemB[g];
            let st = this.gS[g];
            this.gT[g] += dt;
            let t = this.gT[g];
            if (st == 0) {
                api.hide(b);
                continue;
            }
            if (st == 1) {
                // grows out of the floor with an overshoot, stepped at 15 fps
                let k = Math.floor(t * 15) / 15 / 0.45;
                if (k >= 1.0) {
                    this.gS[g] = 2;
                    this.gT[g] = 0;
                    k = 1.0;
                }
                let s = k < 0.7 ? 0.15 + k / 0.7 * 1.0 : 1.15 - (k - 0.7) / 0.3 * 0.15;
                api.placeScaled(b, this.gX[g], 0, this.gZ[g], this.gYaw[g], s, s, s);
            } else if (st == 2) {
                // shines: a slow stepped turn and a pulse
                let k = Math.floor((api.time + <f64>g * 0.37) * 8.0) / 8.0;
                let s = 1.0 + 0.06 * Math.sin(k * 5.0);
                api.place(b, this.gX[g], 0, this.gZ[g], this.gYaw[g] + k * 25.0, 0, 0, s);
            } else {
                // eaten: spins, shrinks and sinks towards the mouth
                if (t > 0.3) {
                    this.gS[g] = 0;
                    api.hide(b);
                    continue;
                }
                let k = Math.floor(t * 20) / 20 / 0.3;
                let x = this.gX[g] + (this.hx - this.gX[g]) * k * 0.6;
                let z = this.gZ[g] + (this.hz - this.gZ[g]) * k * 0.6;
                api.place(b, x, 0, z, this.gYaw[g] + k * 200, 0, 0, Math.max(0.12, 1.0 - k * 0.9));
            }
        }
    }

    // ------------------------------------------------------------------ sparks

    burst(api: GameApi, x: f64, y: f64, z: f64, n: i32): void {
        let made = 0;
        for (let i = 0; i < NSPARK && made < n; i++) {
            if (this.sT[i] >= 0) {
                continue;
            }
            let a = <f64>made / <f64>n * Math.PI * 2 + api.range(-0.4, 0.4);
            this.sT[i] = 0;
            this.sX[i] = x; this.sY[i] = y; this.sZ[i] = z;
            let v = api.range(1.0, 1.8);
            this.sVX[i] = Math.cos(a) * v;
            this.sVZ[i] = Math.sin(a) * v;
            this.sVY[i] = api.range(1.8, 2.8);
            made++;
        }
    }

    updateSparks(api: GameApi, dt: f64): void {
        for (let i = 0; i < NSPARK; i++) {
            let b = this.sparkB[i];
            if (this.sT[i] < 0) {
                api.hide(b);
                continue;
            }
            this.sT[i] += dt;
            if (this.sT[i] > 0.65 || this.sY[i] < 0.02) {
                this.sT[i] = -1;
                api.hide(b);
                continue;
            }
            this.sVY[i] -= 7.0 * dt;
            this.sX[i] += this.sVX[i] * dt;
            this.sY[i] += this.sVY[i] * dt;
            this.sZ[i] += this.sVZ[i] * dt;
            let s = 1.3 - this.sT[i] * 1.4;
            api.place(b, this.sX[i], this.sY[i], this.sZ[i], Math.floor(this.sT[i] * 12) * 45, 0, 0, Math.max(0.3, s));
        }
    }

    // ------------------------------------------------------------------ the demo player

    // Steers for the nearest crystal, a few times a second, with a little aim error; looks ahead along
    // a fan of headings and takes the one closest to its goal that keeps clear of its body, the
    // stalagmites and the walls. Now and then it stops looking for a moment (more often the longer
    // it is), and the cave gets it.
    demoThink(api: GameApi, dt: f64): void {
        if (this.dLapse > 0) {
            this.dLapse -= dt;
        }
        this.dThink -= dt;
        if (this.dThink > 0) {
            return;
        }
        this.dThink = api.range(0.07, 0.15);
        if (this.dLapse <= 0 && api.rand() < 0.004 + 0.0008 * <f64>this.len) {
            this.dLapse = api.range(0.5, 0.9);
        }
        // the goal: the nearest crystal (now and then a farther one)
        let best = -1;
        let bestD = 1e9;
        for (let g = 0; g < NGEM; g++) {
            if (this.gS[g] != 1 && this.gS[g] != 2) {
                continue;
            }
            let dx = this.gX[g] - this.hx, dz = this.gZ[g] - this.hz;
            let d = Math.sqrt(dx * dx + dz * dz);
            if (g == this.dGoal) {
                d -= 0.6;   // sticks with its choice
            }
            if (d < bestD) {
                bestD = d;
                best = g;
            }
        }
        if (best != this.dGoal) {
            this.dErrX = api.range(-0.25, 0.25);
            this.dErrZ = api.range(-0.25, 0.25);
        }
        this.dGoal = best;
        let gx = 0.0, gz = Z0;
        if (best >= 0) {
            gx = this.gX[best] + this.dErrX * 0.5;
            gz = this.gZ[best] + this.dErrZ * 0.5;
        }
        let goalA = Math.atan2(gx - this.hx, gz - this.hz);
        if (this.dLapse > 0) {
            // not looking: straight for the crystal
            this.tx = gx;
            this.tz = gz;
            return;
        }
        let bestA = goalA;
        let bestV = 1e9;
        for (let c = -8; c <= 8; c++) {
            // follow the arc the worm would really crawl, turning at its limit towards this heading
            let a = this.hd + <f64>c * 0.26;
            let h = this.hd, x = this.hx, z = this.hz;
            let danger = 0.0;
            for (let j = 1; j <= 8; j++) {
                let st = 0.09;
                let d = a - h;
                h += Math.max(-TURN * st, Math.min(TURN * st, d));
                x += Math.sin(h) * this.speed * st;
                z += Math.cos(h) * this.speed * st;
                let w = 9.0 - <f64>j;
                if (this.ell(x, z) > 0.97) {
                    danger += w * 0.5;
                }
                for (let p = 0; p < 3; p++) {
                    let px = this.pX[p] - x, pz = this.pZ[p] - z;
                    if (px * px + pz * pz < (this.pR[p] + 0.2) * (this.pR[p] + 0.2)) {
                        danger += w;
                    }
                }
                for (let i = 3; i < this.len; i++) {
                    let sx = this.segX[i] - x, sz = this.segZ[i] - z;
                    if (sx * sx + sz * sz < 0.38 * 0.38) {
                        danger += w;
                        break;
                    }
                }
            }
            let off = a - goalA;
            while (off > Math.PI) { off -= 2 * Math.PI; }
            while (off < -Math.PI) { off += 2 * Math.PI; }
            let v = Math.abs(off) + danger * 3.0 + Math.abs(<f64>c) * 0.03;
            if (v < bestV) {
                bestV = v;
                bestA = a;
            }
        }
        // a goal close ahead and clear: aim right at it (the fan's step would overshoot)
        let dg = bestA - goalA;
        while (dg > Math.PI) { dg -= 2 * Math.PI; }
        while (dg < -Math.PI) { dg += 2 * Math.PI; }
        if (Math.abs(dg) < 0.3 && bestV < 1.0) {
            this.tx = gx;
            this.tz = gz;
        } else {
            this.tx = this.hx + Math.sin(bestA) * 1.6;
            this.tz = this.hz + Math.cos(bestA) * 1.6;
        }
    }

    // ------------------------------------------------------------------ input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        let hit = api.pick(x, y, 0.2);
        if (kind == POINTER_DOWN) {
            if (this.state == ST_IDLE) {
                this.beginRun();
            } else if (this.state == ST_OVER && this.stateT > 0.6) {
                this.resetWorld(api, true);
                this.beginRun();
            }
        }
        if ((kind == POINTER_DOWN || kind == POINTER_MOVE) && hit && this.state == ST_PLAY) {
            let px = <f64>api.hitX, pz = <f64>api.hitZ;
            // keep the lead inside the cave
            let e = this.ell(px, pz);
            if (e > 0.95) {
                px *= 0.95 / e;
                pz = Z0 + (pz - Z0) * 0.95 / e;
            }
            this.tx = px;
            this.tz = pz;
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    hud(api: GameApi): void {
        let dark = api.paletteColor(C_DARK);
        let slate = api.paletteColor(C_SLATE);
        let pale = api.paletteColor(C_PALE);
        let w = <f32>api.hudW, h = <f32>api.hudH;
        // where the pointer leads (play only): a small pale cross
        if (this.state == ST_PLAY && !api.demo && api.pointerX >= 0) {
            let px = Mathf.round(api.pointerX), py = Mathf.round(api.pointerY);
            api.rect(px - 2, py, 5, 1, slate);
            api.rect(px, py - 2, 1, 5, slate);
            api.rect(px, py, 1, 1, pale);
        }
        if (this.popT >= 0) {
            let rise = <f32>(this.popT * 14.0);
            api.text(this.popX - 3, this.popY - 6 - rise, this.popText, pale, 1, dark);
        }
        // score (crystals eaten), best, length
        api.text(4, 4, this.score.toString(), pale, 2, dark);
        api.text(4, 16, "BEST " + this.best.toString(), pale, 1, dark);
        let ls = "LENGTH " + (this.len + 1).toString();
        api.text(w - 4 - api.textWidth(ls, 1), 4, ls, pale, 1, dark);
        if (this.state == ST_IDLE) {
            let blink = Math.floor(api.time * 2) % 2 == 0;
            api.rect(0, h - 25, w, 25, dark);
            api.rect(0, h - 26, w, 1, slate);
            api.textCentered(h - 21, "CLICK TO START", blink ? pale : slate, 2, 0);
            api.textCentered(h - 8, "LEAD THE WORM TO THE CRYSTALS - NEVER CROSS ITS TAIL", pale, 1, 0);
        } else if (this.state == ST_OVER) {
            let pw: f32 = 124, ph: f32 = 44;
            let px = Mathf.floor((w - pw) * 0.5), py = Mathf.floor(h * 0.5 - 26);
            api.rect(px, py, pw, ph, dark);
            api.rect(px - 1, py - 1, pw + 2, 1, slate);
            api.rect(px - 1, py + ph, pw + 2, 1, slate);
            api.rect(px - 1, py, 1, ph, slate);
            api.rect(px + pw, py, 1, ph, slate);
            api.textCentered(py + 4, "GAME OVER", pale, 2, slate);
            api.textCentered(py + 17, this.cause, slate, 1, 0);
            api.textCentered(py + 25, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), pale, 1, 0);
            if (this.stateT > 0.6 && !api.demo) {
                api.textCentered(py + 34, "CLICK TO PLAY AGAIN", Math.floor(api.time * 2) % 2 == 0 ? pale : slate, 1, 0);
            }
        } else if (this.state == ST_PLAY && this.runT < 4.0 && !api.demo) {
            api.rect(0, h - 11, w, 11, dark);
            api.rect(0, h - 12, w, 1, slate);
            api.textCentered(h - 8, "MOVE THE POINTER - THE WORM FOLLOWS IT", pale, 1, 0);
        }
    }
}
