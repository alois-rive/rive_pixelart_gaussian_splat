// Sky Stacker: storeys of a pagoda slide over the tower; click to drop one. The part hanging over the
// storey below is sliced off and tumbles into the clouds; the next storey is only as big as what
// stayed. A drop within a hair of the one below is PERFECT (no cut, +1 more; three in a row grow the
// storey back a little). Miss the tower and the storey falls: the run ends. One verb: click.
import { GameApi, POINTER_DOWN, SFX_THUD, SFX_CLICK, SFX_BELL, SFX_POWERUP, SFX_WHOOSH, SFX_LOSE, SFX_TICK, SFX_NOTE } from "./game_api";

// a perfect streak climbs a pentatonic scale of chimes
const CHIME: StaticArray<f64> = [76, 79, 81, 84, 86, 88, 91, 93];

const POOL: i32 = 18;           // storeys on screen at most; the lowest is recycled to the top
const CHUNKS: i32 = 4;
const CLOUDS: i32 = 6;
const BASE_Y: f64 = 0.4;        // the plinth's top
const H: f64 = 0.67;            // a storey's height (models/storey/p3_splat_fit.txt)
const FULL: f64 = 2.0;          // a storey's footprint
const RANGE: f64 = 2.9;         // the slide reaches this far either side
const HOVER: f64 = 0.22;        // the sliding storey floats this high above its place
const PERFECT: f64 = 0.07;
const DROP_T: f64 = 0.07;

const SLIDE: i32 = 0;
const SETTLE: i32 = 1;          // the dropped storey lands; the next one appears after it
const FALL: i32 = 2;            // missed: the storey falls
const OVER: i32 = 3;

function ease(t: f64): f64 {
    let u = Math.min(Math.max(t, 0), 1);
    return u * u * (3 - 2 * u);
}

// The fixed (or climbing) orthographic camera's target; the renderer snaps it to the art grid.
function aim(api: GameApi, tx: f64, ty: f64, tz: f64): void {
    api.useTarget = true;
    api.targetX = tx;
    api.targetY = ty;
    api.targetZ = tz;
}

// An offcut falls and tumbles about its own middle (placeScaled turns it about its foot, the pivot):
// shift the foot so the middle stays on the falling point.
function placeTumble(api: GameApi, b: i32, x: f64, y: f64, z: f64, sx: f64, sz: f64, aboutZ: bool, ang: f64): void {
    let h = H * 0.5;
    if (aboutZ) {
        api.placeScaled(b, x + h * Math.sin(ang), y + h - h * Math.cos(ang), z, 0, sx, 1, sz, 0, ang * 180 / Math.PI);
    } else {
        api.placeScaled(b, x, y + h - h * Math.cos(ang), z - h * Math.sin(ang), 0, sx, 1, sz, ang * 180 / Math.PI, 0);
    }
}

export class Game {
    floor: StaticArray<i32> = new StaticArray<i32>(POOL);
    chunk: StaticArray<i32> = new StaticArray<i32>(CHUNKS);
    cloud: StaticArray<i32> = new StaticArray<i32>(CLOUDS);
    spire: i32 = -1;
    // the stack: centre and size of every storey placed (index 0 is the ground storey)
    cx: Array<f64> = new Array<f64>();
    cz: Array<f64> = new Array<f64>();
    sx: Array<f64> = new Array<f64>();
    sz: Array<f64> = new Array<f64>();
    landT: Array<f64> = new Array<f64>();
    // the sliding storey
    state: i32 = SLIDE;
    stateT: f64 = 0;
    pos: f64 = 0;               // along its axis
    vel: f64 = 2;
    slideT: f64 = 0;
    combo: i32 = 0;
    // offcuts
    chX: StaticArray<f64> = new StaticArray<f64>(CHUNKS);
    chY: StaticArray<f64> = new StaticArray<f64>(CHUNKS);
    chZ: StaticArray<f64> = new StaticArray<f64>(CHUNKS);
    chSX: StaticArray<f64> = new StaticArray<f64>(CHUNKS);
    chSZ: StaticArray<f64> = new StaticArray<f64>(CHUNKS);
    chVX: StaticArray<f64> = new StaticArray<f64>(CHUNKS);
    chVY: StaticArray<f64> = new StaticArray<f64>(CHUNKS);
    chVZ: StaticArray<f64> = new StaticArray<f64>(CHUNKS);
    chA: StaticArray<f64> = new StaticArray<f64>(CHUNKS);
    chW: StaticArray<f64> = new StaticArray<f64>(CHUNKS);
    chT: StaticArray<f64> = new StaticArray<f64>(CHUNKS);
    chZaxis: StaticArray<bool> = new StaticArray<bool>(CHUNKS);
    nextChunk: i32 = 0;
    // clouds drifting behind the tower
    clLat: StaticArray<f64> = new StaticArray<f64>(CLOUDS);
    clDist: StaticArray<f64> = new StaticArray<f64>(CLOUDS);
    clY: StaticArray<f64> = new StaticArray<f64>(CLOUDS);
    clV: StaticArray<f64> = new StaticArray<f64>(CLOUDS);
    // the run
    score: i32 = 0;
    best: i32 = 0;
    camY: f64 = 1.6;
    camH: f64 = 8.5;
    baseH: f64 = 8.5;
    spireT: f64 = -1;
    popText: Array<string> = new Array<string>();
    popY: Array<f64> = new Array<f64>();
    popX: Array<f64> = new Array<f64>();
    popZ: Array<f64> = new Array<f64>();
    popT: Array<f64> = new Array<f64>();
    // demo
    wasDemo: bool = false;
    intent: f64 = 0;
    lastD: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < POOL; i++) this.floor[i] = api.bone("floor" + i.toString());
        for (let i = 0; i < CHUNKS; i++) {
            this.chunk[i] = api.bone("chunk" + i.toString());
            this.chT[i] = 99;
        }
        for (let i = 0; i < CLOUDS; i++) {
            this.cloud[i] = api.bone("cloud" + i.toString());
            this.clLat[i] = api.range(-9, 9);
            this.clDist[i] = api.range(4.5, 8);
            this.clY[i] = 3.0 + <f64>i * 3.4 + api.range(-0.8, 0.8);
            this.clV[i] = api.range(0.25, 0.6) * (i % 2 == 0 ? 1.0 : -1.0);
        }
        this.spire = api.bone("spire");
        this.baseH = api.orthoHeight;
        this.camH = this.baseH;
        this.wasDemo = api.demo;
        this.newRun(api);
    }

    newRun(api: GameApi): void {
        this.popText.length = 0; this.popX.length = 0; this.popY.length = 0; this.popZ.length = 0; this.popT.length = 0;
        this.cx.length = 0; this.cz.length = 0; this.sx.length = 0; this.sz.length = 0; this.landT.length = 0;
        this.cx.push(0); this.cz.push(0); this.sx.push(FULL); this.sz.push(FULL); this.landT.push(9);
        this.score = 0;
        this.combo = 0;
        this.spireT = -1;
        // a run starts: a low gong and its fifth
        api.note(55, 0.5, 0, SFX_BELL);
        api.note(62, 0.35, 0, SFX_BELL);
        this.beginSlide(api, true);
    }

    count(): i32 { return this.cx.length; }

    axisX(k: i32): bool { return k % 2 == 1; }

    beginSlide(api: GameApi, first: bool): void {
        let k = this.count();
        let prev = this.axisX(k) ? this.cx[k - 1] : this.cz[k - 1];
        this.state = SLIDE;
        this.stateT = 0;
        this.slideT = 0;
        this.vel = Math.min(2.0 + 0.09 * <f64>(k - 1), 4.6);
        // the first storey of a run starts near the middle so the first drop comes within a second
        let from = first ? 1.5 : RANGE;
        let side = k % 4 < 2 ? -1.0 : 1.0;
        this.pos = prev + side * from;
        this.vel = -side * this.vel;
        this.lastD = this.pos - prev;
        // the demo player's intent for this drop: a small error, now and then a clumsy one
        let sigma = 0.11 + 0.012 * <f64>k;
        let r = api.rand();
        this.intent = (api.rand() + api.rand() + api.rand() - 1.5) * sigma * 2;
        if (r < 0.05 + 0.004 * <f64>k) this.intent = (api.rand() < 0.5 ? -1.0 : 1.0) * api.range(0.5, 1.6);
    }

    drop(api: GameApi): void {
        if (this.state != SLIDE) return;
        let k = this.count();
        let alongX = this.axisX(k);
        let c = alongX ? this.cx[k - 1] : this.cz[k - 1];
        let w = alongX ? this.sx[k - 1] : this.sz[k - 1];
        let other = alongX ? this.cz[k - 1] : this.cx[k - 1];
        let otherW = alongX ? this.sz[k - 1] : this.sx[k - 1];
        let d = this.pos - c;
        let y = BASE_Y + <f64>k * H;
        if (Math.abs(d) >= w - 0.04) {
            // missed the tower: this storey falls, the run is over
            this.spawnChunk(alongX ? this.pos : other, y + HOVER, alongX ? other : this.pos,
                alongX ? w : otherW, alongX ? otherW : w, alongX, d);
            this.state = FALL;
            this.stateT = 0;
            if (this.score > this.best) this.best = this.score;
            // the storey slides off into the clouds
            api.soundAt(SFX_WHOOSH, alongX ? this.pos : other, y, alongX ? other : this.pos, 0.45, 0.8);
            return;
        }
        let perfect = Math.abs(d) < PERFECT;
        let keep = w - Math.abs(d);
        let mid = c + d * 0.5;
        if (perfect) {
            this.combo++;
            keep = w;
            mid = c;
            if (this.combo >= 3) keep = Math.min(w + 0.15, FULL);
            this.score += 2;
            this.pop(alongX ? mid : other, y + 1.0, alongX ? other : mid, this.combo >= 3 ? "PERFECT! WIDER" : "PERFECT!");
        } else {
            this.combo = 0;
            this.score += 1;
            let cutC = c + (d > 0 ? 1.0 : -1.0) * (w * 0.5 + Math.abs(d) * 0.5);
            this.spawnChunk(alongX ? cutC : other, y + HOVER, alongX ? other : cutC,
                alongX ? Math.abs(d) : otherW, alongX ? otherW : Math.abs(d), alongX, d);
        }
        this.cx.push(alongX ? mid : other);
        this.cz.push(alongX ? other : mid);
        this.sx.push(alongX ? keep : otherW);
        this.sz.push(alongX ? otherW : keep);
        this.landT.push(0);
        // a placed storey: a thud whose pitch climbs with the height (k floors), a chime on a perfect
        let cxN = this.cx[k], czN = this.cz[k];
        api.soundAt(SFX_THUD, cxN, y, czN, Math.min(0.8 + 0.06 * <f64>(k - 1), 2.6), 0.9);
        if (perfect) {
            let m = CHIME[min<i32>(this.combo - 1, CHIME.length - 1)];
            api.note(m, 0.7, 0, SFX_BELL);
            if (this.combo >= 3) api.sound(SFX_POWERUP, 1.0 + 0.05 * <f64>min<i32>(this.combo - 3, 8), 0.5);
        } else {
            // the overhang is sliced off: a sharp chop, higher for a thin sliver
            api.soundAt(SFX_CLICK, alongX ? this.pos : other, y, alongX ? other : this.pos, 0.35, 0.8);
            api.note(Math.max(40, 52 - Math.abs(d) * 6), 0.4, 0, SFX_NOTE);
        }
        this.state = SETTLE;
        this.stateT = 0;
    }

    // the sliding storey turns at the end of its run: a quiet tick, panned to that side
    edgeTick(api: GameApi): void {
        let n = this.count();
        let alongX = this.axisX(n);
        let x = alongX ? this.pos : this.cx[n - 1];
        let z = alongX ? this.cz[n - 1] : this.pos;
        api.soundAt(SFX_TICK, x, BASE_Y + <f64>n * H, z, 0.5 + 0.03 * <f64>min<i32>(n, 20), 0.45);
    }

    spawnChunk(x: f64, y: f64, z: f64, sx: f64, sz: f64, alongX: bool, d: f64): void {
        let i = this.nextChunk;
        this.nextChunk = (i + 1) % CHUNKS;
        let dir = d >= 0 ? 1.0 : -1.0;
        this.chX[i] = x; this.chY[i] = y; this.chZ[i] = z;
        this.chSX[i] = sx; this.chSZ[i] = sz;
        this.chVX[i] = alongX ? dir * 1.2 : 0.0;
        this.chVZ[i] = alongX ? 0.0 : dir * 1.2;
        this.chVY[i] = 0.8;
        this.chA[i] = 0;
        // tumble outward: about Z for a cut along X, about X for a cut along Z
        this.chW[i] = alongX ? -dir * 3.2 : dir * 3.2;
        this.chZaxis[i] = alongX;
        this.chT[i] = 0;
    }

    pop(x: f64, y: f64, z: f64, text: string): void {
        this.popText.push(text); this.popX.push(x); this.popY.push(y); this.popZ.push(z); this.popT.push(0);
    }

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.newRun(api);
        }
        this.stateT += dt;
        let k = this.count();
        if (this.state == SLIDE) {
            this.slideT += dt;
            let prev = this.axisX(k) ? this.cx[k - 1] : this.cz[k - 1];
            this.pos += this.vel * dt;
            if (this.pos > prev + RANGE) { this.pos = prev + RANGE; this.vel = -Math.abs(this.vel); this.edgeTick(api); }
            if (this.pos < prev - RANGE) { this.pos = prev - RANGE; this.vel = Math.abs(this.vel); this.edgeTick(api); }
            if (api.demo) {
                let d = this.pos - prev;
                // drop when the storey crosses the spot it meant to hit (not in the first moment)
                if (this.slideT > 0.3 && (d - this.intent) * (this.lastD - this.intent) <= 0) this.drop(api);
                this.lastD = d;
            }
        } else if (this.state == SETTLE) {
            if (this.stateT > 0.18) this.beginSlide(api, false);
        } else if (this.state == FALL) {
            if (this.stateT > 0.6) {
                this.state = OVER;
                this.stateT = 0;
                this.spireT = 0;
                api.sound(SFX_LOSE, 0.9, 0.7);
            }
        } else if (this.state == OVER) {
            if (api.demo && this.stateT > 2.0) this.newRun(api);
        }
        for (let i = 0; i < this.landT.length; i++) this.landT[i] += dt;
        if (this.spireT >= 0) {
            let was = this.spireT;
            this.spireT += dt;
            // the gold spire lands on the top (place(): it drops for 0.3 s after 0.25 s)
            if (was < 0.55 && this.spireT >= 0.55 && this.count() > 1) {
                api.sound(SFX_THUD, 1.6, 0.6);
                api.note(<f64>min<i32>(72 + this.count(), 96), 0.6, 0, SFX_BELL);
            }
        }
        // offcuts fall and tumble
        for (let i = 0; i < CHUNKS; i++) {
            if (this.chT[i] > 3) continue;
            this.chT[i] += dt;
            this.chVY[i] -= 9.0 * dt;
            this.chX[i] += this.chVX[i] * dt;
            this.chY[i] += this.chVY[i] * dt;
            this.chZ[i] += this.chVZ[i] * dt;
            this.chA[i] += this.chW[i] * dt;
        }
        // the camera climbs with the tower; at the end it backs off to show it
        let topY = BASE_Y + <f64>this.count() * H;
        let goalY = Math.max(1.6, topY - 0.6);
        let goalH = this.baseH;
        if (this.state == OVER || this.state == FALL) {
            let shown = Math.min(<f64>this.count(), 15.0);
            goalH = Math.min(Math.max(this.baseH + 1.0, shown * H + 5.5), 13.5);
            goalY = Math.max(2.4, topY - shown * H * 0.5 + 1.5);
        }
        let a = 1 - Math.exp(-dt * 3.5);
        this.camY += (goalY - this.camY) * a;
        this.camH += (goalH - this.camH) * a;
        api.orthoHeight = this.camH;
        aim(api, 0, this.camY, 0);
        // clouds drift behind the tower; the ones the camera left below come back above it
        for (let i = 0; i < CLOUDS; i++) {
            this.clLat[i] += this.clV[i] * dt;
            if (this.clLat[i] > 9) this.clLat[i] -= 18;
            if (this.clLat[i] < -9) this.clLat[i] += 18;
            if (this.clY[i] < this.camY - 7) {
                this.clY[i] += 6 * 3.4;
                this.clDist[i] = api.range(4.5, 8);
            }
            if (this.clY[i] > this.camY + 14) this.clY[i] -= 6 * 3.4;
        }
        for (let i = this.popT.length - 1; i >= 0; i--) {
            this.popT[i] += dt;
            if (this.popT[i] > 1.0) {
                this.popT.splice(i, 1); this.popText.splice(i, 1); this.popX.splice(i, 1);
                this.popY.splice(i, 1); this.popZ.splice(i, 1);
            }
        }
        this.place(api);
    }

    place(api: GameApi): void {
        let n = this.count();
        let lo: i32 = max<i32>(0, n - POOL + 1);
        let used = new StaticArray<bool>(POOL);
        for (let k = lo; k < n; k++) {
            let b = this.floor[k % POOL];
            used[k % POOL] = true;
            let y = BASE_Y + <f64>k * H;
            let t = this.landT[k];
            let sy = 1.0, sw = 1.0;
            if (t < DROP_T) {
                y += HOVER * (1 - t / DROP_T);
            } else if (t < DROP_T + 0.22) {
                let u = (t - DROP_T) / 0.22;
                let s = Math.sin(u * Math.PI) * (1 - u);
                sy = 1 - 0.22 * s; sw = 1 + 0.07 * s;
            }
            api.placeScaled(b, this.cx[k], y, this.cz[k], 0, this.sx[k] / FULL * sw, sy, this.sz[k] / FULL * sw);
        }
        // the sliding storey (the next pool slot), with a little anticipation bob
        if (this.state == SLIDE) {
            let i = n % POOL;
            used[i] = true;
            let alongX = this.axisX(n);
            let x = alongX ? this.pos : this.cx[n - 1];
            let z = alongX ? this.cz[n - 1] : this.pos;
            let appear = Math.min(this.slideT / 0.15, 1);
            let s = 0.7 + 0.3 * ease(appear);
            let y = BASE_Y + <f64>n * H + HOVER + Math.sin(this.slideT * 6) * 0.03;
            api.placeScaled(this.floor[i], x, y, z, 0, this.sx[n - 1] / FULL * s, s, this.sz[n - 1] / FULL * s);
        }
        for (let i = 0; i < POOL; i++) {
            if (!used[i]) api.hide(this.floor[i]);
        }
        for (let i = 0; i < CHUNKS; i++) {
            let b = this.chunk[i];
            if (this.chT[i] > 3) {
                api.hide(b);
            } else {
                placeTumble(api, b, this.chX[i], this.chY[i], this.chZ[i], this.chSX[i] / FULL, this.chSZ[i] / FULL,
                    this.chZaxis[i], this.chA[i]);
            }
        }
        // clouds behind the tower (away from the camera at yaw 45), drifting across
        for (let i = 0; i < CLOUDS; i++) {
            let bx = -0.7071 * this.clDist[i], bz = -0.7071 * this.clDist[i];
            let x = bx + 0.7071 * this.clLat[i], z = bz - 0.7071 * this.clLat[i];
            api.place(this.cloud[i], x, this.clY[i], z, <f64>i * 50);
        }
        // the spire drops onto the finished tower and bounces
        if (this.spireT >= 0 && n > 0) {
            let top = BASE_Y + <f64>n * H;
            let t = this.spireT - 0.25;
            if (t < 0) {
                api.hide(this.spire);
            } else if (t < 0.3) {
                let u = t / 0.3;
                api.place(this.spire, this.cx[n - 1], top + 3.0 * (1 - u * u), this.cz[n - 1], 0);
            } else {
                let u = Math.min((t - 0.3) / 0.3, 1);
                let s = Math.sin(u * Math.PI) * (1 - u);
                api.placeScaled(this.spire, this.cx[n - 1], top, this.cz[n - 1], 0, 1 + 0.25 * s, 1 - 0.35 * s, 1 + 0.25 * s);
            }
        } else {
            api.hide(this.spire);
        }
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind != POINTER_DOWN) return true;
        if (this.state == OVER) {
            if (this.stateT > 0.6) this.newRun(api);
            return true;
        }
        this.drop(api);
        return true;
    }

    hud(api: GameApi): void {
        let ink = api.rampColor(0, 0);      // #1f0e1c
        let cream = api.rampColor(2, 3);    // #f5edba
        let gold = api.rampColor(2, 2);     // #e4943a
        let teal = api.rampColor(1, 3);     // #7ec4c1
        let w = <f32>api.hudW;
        let h = <f32>api.hudH;
        let floors = this.count() - 1;
        api.text(4, 4, "FLOORS " + floors.toString(), cream, 2, ink);
        api.text(4, 16, "SCORE " + this.score.toString(), gold, 1, ink);
        let b = "BEST " + this.best.toString();
        api.text(w - api.textWidth(b, 1) - 4, 5, b, gold, 1, ink);
        if (api.demo) api.text(w - api.textWidth("DEMO", 1) - 4, 13, "DEMO", teal, 1, ink);
        for (let i = 0; i < this.popT.length; i++) {
            let u = this.popT[i];
            if (api.project(<f32>this.popX[i], <f32>(this.popY[i] + u * 0.7), <f32>this.popZ[i])) {
                let s = this.popText[i];
                if (u < 0.8 || Math.floor(u * 20) % 2 == 0) {
                    let px = Mathf.min(Mathf.max(Mathf.round(api.screenX - api.textWidth(s, 1) * 0.5), 2), w - api.textWidth(s, 1) - 2);
                    api.text(px, Mathf.max(Mathf.round(api.screenY), 26), s, cream, 1, ink);
                }
            }
        }
        if (this.state == SLIDE && floors == 0 && !api.demo) {
            if (Math.floor(api.time * 2) % 4 != 3) api.textCentered(h - 9, "CLICK TO DROP THE FLOOR - STACK IT HIGH", cream, 1, ink);
        }
        if (this.state == OVER) {
            api.textCentered(30, "MISSED!", cream, 3, ink);
            api.textCentered(50, "FLOORS " + floors.toString() + "   SCORE " + this.score.toString() + "   BEST " + this.best.toString(), gold, 1, ink);
            if (!api.demo && this.stateT > 0.6) api.textCentered(h - 9, "CLICK TO BUILD AGAIN", cream, 1, ink);
        }
    }
}
