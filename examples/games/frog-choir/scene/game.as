// Frog Choir: five frogs sing at dawn on a marsh pond. A beat ring closes on one frog after another;
// click the frog as its ring closes on it: PERFECT or GOOD, its throat sac puffs up, a ripple runs out
// and a note floats up. A ring left to close, a click far too early or a click on a frog with no ring
// is a sour note: three sour notes and the choir stops. The tempo rises, rings overlap; a run of good
// notes builds a combo that multiplies the score and wins a lost voice back. Pointer only; a run
// starts on the first click; demo mode plays itself.
import { GameApi, POINTER_DOWN } from "./game_api";

const ST_IDLE: i32 = 0;
const ST_PLAY: i32 = 1;
const ST_OVER: i32 = 2;

const NF: i32 = 5;             // frogs
const NN: i32 = 12;            // note pool (pending rings)
const NRIP: i32 = 8;           // ripple pool
const NMIST: i32 = 4;
const NGLYPH: i32 = 10;        // floating note glyphs (HUD)
const FROG_S: f64 = 1.2;       // the frogs' bake scale
const CHIN_Y: f64 = 0.36;      // the sac's pivot (the chin), glTF metres off the frog's pivot, unscaled
const CHIN_Z: f64 = 0.24;
const RING_Y: f64 = 0.42;      // the ring's centre above a frog's feet (scaled)
const PERFECT: f64 = 0.075;    // timing windows, seconds either side of the beat
const GOOD: f64 = 0.17;
const R_TARGET: f32 = 13;      // ring radius on the beat, HUD pixels
const R_START: f32 = 40;
const HIT_R: f32 = 17;         // how near a frog's centre a click must land

// palette indices (art/palette.json "colors")
const C_BLACK: i32 = 1;
const C_INDIGO: i32 = 2;
const C_SLATE: i32 = 3;
const C_CREAM: i32 = 4;
const C_MAGENTA: i32 = 7;
const C_PINK: i32 = 9;
const C_CYAN: i32 = 10;
const C_ORANGE: i32 = 11;
const C_LIME: i32 = 12;
const C_BONE: i32 = 13;
const C_YELLOW: i32 = 14;

export class Game {
    state: i32 = ST_IDLE;
    stateT: f64 = 0;
    runT: f64 = 0;            // song time: notes are timed on it
    score: i32 = 0;
    best: i32 = 0;
    lives: i32 = 3;
    combo: i32 = 0;
    bestCombo: i32 = 0;
    perfects: i32 = 0;
    started: bool = false;

    // frogs: where they sit, which way they face, their ring colour
    fx: StaticArray<f64> = [-3.5, -1.8, 0.0, 1.8, 3.5];
    fy: StaticArray<f64> = [0.05, 0.05, 0.31, 0.05, 0.05];
    fz: StaticArray<f64> = [0.8, -0.15, -0.7, -0.15, 0.8];
    fyaw: StaticArray<f64> = [14, 7, 0, -7, -14];
    fcol: StaticArray<i32> = [C_LIME, C_PINK, C_YELLOW, C_CYAN, C_MAGENTA];
    frogB: StaticArray<i32> = new StaticArray<i32>(NF);
    sacB: StaticArray<i32> = new StaticArray<i32>(NF);
    singT: StaticArray<f64> = new StaticArray<f64>(NF);   // >= 0: singing (time since the hit)
    singQ: StaticArray<f64> = new StaticArray<f64>(NF);   // how big the puff (1 perfect, 0.75 good)
    sourT: StaticArray<f64> = new StaticArray<f64>(NF);   // >= 0: a sour note (time since)
    fsx: StaticArray<f32> = new StaticArray<f32>(NF);     // the frogs' ring centres on screen
    fsy: StaticArray<f32> = new StaticArray<f32>(NF);
    bobT: f64 = 1;            // time since the last beat: every frog dips on it

    // notes: a beat ring closing on frog nF at song time nT
    nOn: StaticArray<bool> = new StaticArray<bool>(NN);
    nF: StaticArray<i32> = new StaticArray<i32>(NN);
    nT: StaticArray<f64> = new StaticArray<f64>(NN);
    nLead: StaticArray<f64> = new StaticArray<f64>(NN);
    nPlan: StaticArray<f64> = new StaticArray<f64>(NN);  // the demo player's click time (-1: it will not click)
    nextT: f64 = 0;           // when the next note is due
    lastF: i32 = 2;
    lastSung: StaticArray<f64> = new StaticArray<f64>(NF);   // song time of each frog's last note

    // ripples, mist, glyphs
    ripB: StaticArray<i32> = new StaticArray<i32>(NRIP);
    ripT: StaticArray<f64> = new StaticArray<f64>(NRIP);
    ripX: StaticArray<f64> = new StaticArray<f64>(NRIP);
    ripZ: StaticArray<f64> = new StaticArray<f64>(NRIP);
    ripS: StaticArray<f64> = new StaticArray<f64>(NRIP);
    mistB: StaticArray<i32> = new StaticArray<i32>(NMIST);
    mistX: StaticArray<f64> = [-4.5, -0.8, 2.6, 6.0];
    mistZ: StaticArray<f64> = [-4.0, -3.7, -4.15, -3.85];
    mistV: StaticArray<f64> = [0.22, 0.16, 0.19, 0.13];
    gT: StaticArray<f64> = new StaticArray<f64>(NGLYPH);  // < 0: free
    gX: StaticArray<f32> = new StaticArray<f32>(NGLYPH);
    gY: StaticArray<f32> = new StaticArray<f32>(NGLYPH);
    gC: StaticArray<i32> = new StaticArray<i32>(NGLYPH);
    gK: StaticArray<i32> = new StaticArray<i32>(NGLYPH);  // 0 a quaver, 1 two beamed quavers, 2 a sour cross

    // the judgement word over a frog
    wordT: f64 = -1;
    wordF: i32 = 0;
    word: string = "";
    wordC: i32 = C_CREAM;

    // juice
    shakeT: f64 = 0;
    flashT: f64 = 0;          // a life lost: the icon blinks
    gainT: f64 = 0;           // a life won back
    camTX: f64 = 0;
    wasDemo: bool = false;

    // the demo player's cursor (HUD pixels)
    curX: f32 = 106;
    curY: f32 = 100;
    curTap: f64 = 1;

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < NF; i++) {
            this.frogB[i] = api.bone("frog" + i.toString());
            this.sacB[i] = api.bone("sac" + i.toString());
            this.singT[i] = -1;
            this.sourT[i] = -1;
        }
        for (let i = 0; i < NRIP; i++) {
            this.ripB[i] = api.bone("ripple" + i.toString());
            this.ripT[i] = -1;
        }
        for (let i = 0; i < NMIST; i++) {
            this.mistB[i] = api.bone("mist" + i.toString());
        }
        for (let i = 0; i < NGLYPH; i++) {
            this.gT[i] = -1;
        }
        this.camTX = api.targetX;
        this.wasDemo = api.demo;
        this.resetRun();
        if (api.demo) {
            this.beginRun(api, 0.45);
        }
    }

    // ------------------------------------------------------------------ run control

    resetRun(): void {
        for (let i = 0; i < NN; i++) {
            this.nOn[i] = false;
        }
        this.score = 0;
        this.lives = 3;
        this.combo = 0;
        this.bestCombo = 0;
        this.perfects = 0;
        this.runT = 0;
        this.lastF = 2;
        for (let i = 0; i < NF; i++) {
            this.lastSung[i] = -2.0;
        }
    }

    // a fresh run; the first note closes `first` seconds in (its ring already under way)
    beginRun(api: GameApi, first: f64): void {
        this.resetRun();
        this.state = ST_PLAY;
        this.stateT = 0;
        this.started = true;
        this.nextT = first;
        this.lastF = <i32>Math.floor(api.rand() * 5.0) % NF;
        this.wordT = -1;
    }

    endRun(): void {
        this.state = ST_OVER;
        this.stateT = 0;
        if (this.score > this.best) {
            this.best = this.score;
        }
        for (let i = 0; i < NN; i++) {
            this.nOn[i] = false;
        }
    }

    // seconds between beats: 0.85 at the start, down to 0.4 after about a minute
    interval(): f64 {
        return Math.max(0.4, 0.85 - this.runT * 0.0075);
    }

    // seconds a ring takes to close
    lead(): f64 {
        return Math.max(0.95, 1.5 - this.runT * 0.009);
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged || api.demo != this.wasDemo) {
            // the host switched demo on or off: a fresh run either way (a gentle count-in for a person)
            this.wasDemo = api.demo;
            this.beginRun(api, api.demo ? 0.45 : 1.9);
        }
        this.stateT += dt;
        if (this.state == ST_PLAY) {
            this.runT += dt;
            this.schedule(api);
            this.judgeLate(api);
            if (api.demo) {
                this.demoPlay(api);
            }
        } else if (this.state == ST_OVER && api.demo && this.stateT > 2.0) {
            this.beginRun(api, 0.45);
        }
        this.bobT += dt;
        this.updateFrogs(api, dt);
        this.updateRipples(api, dt);
        this.updateMist(api, dt);
        for (let i = 0; i < NGLYPH; i++) {
            if (this.gT[i] >= 0) {
                this.gT[i] += dt;
                if (this.gT[i] > 1.1) {
                    this.gT[i] = -1;
                }
            }
        }
        if (this.wordT >= 0) {
            this.wordT += dt;
            if (this.wordT > 0.6) {
                this.wordT = -1;
            }
        }
        if (this.flashT > 0) {
            this.flashT -= dt;
        }
        if (this.gainT > 0) {
            this.gainT -= dt;
        }
        this.curTap += dt;
        // camera shake on a sour note: whole texels sideways, stepped
        if (this.shakeT > 0) {
            this.shakeT -= dt;
            let k = Math.floor(api.time * 30);
            let o = Math.sin(k * 12.9898) * 43758.5453 % 1.0;
            api.targetX = this.camTX + Math.round(o * 1.5) * (api.orthoHeight / 136.0);
        } else {
            api.targetX = this.camTX;
        }
        // where each frog's ring sits on screen (for the HUD and for hits)
        for (let i = 0; i < NF; i++) {
            if (api.project(<f32>this.fx[i], <f32>(this.fy[i] + RING_Y), <f32>this.fz[i])) {
                this.fsx[i] = Mathf.round(api.screenX);
                this.fsy[i] = Mathf.round(api.screenY);
            }
        }
    }

    // keeps the notes coming: a walk along the choir, mostly to a neighbour, now and then a leap,
    // and from 15 s on a quick pair (half a beat apart)
    schedule(api: GameApi): void {
        let horizon = this.runT + this.lead() + 0.05;
        while (this.nextT <= horizon) {
            let slot = -1;
            for (let i = 0; i < NN; i++) {
                if (!this.nOn[i]) {
                    slot = i;
                    break;
                }
            }
            if (slot < 0) {
                return;
            }
            // the next singer: a neighbour or a leap of two, never the same frog twice, weighted
            // towards frogs that have not sung for a while (so the whole choir takes part)
            let f = this.pickNext(api);
            this.lastF = f;
            this.lastSung[f] = this.nextT;
            let ld = this.lead();
            this.nOn[slot] = true;
            this.nF[slot] = f;
            this.nT[slot] = this.nextT;
            this.nLead[slot] = ld;
            // the demo player decides now how well it will hit this one
            let sigma = 0.035 + this.runT * 0.0011;
            let err = (api.rand() + api.rand() + api.rand() - 1.5) * sigma * 2.0;
            let u = api.rand();
            if (u < 0.03) {
                err = api.rand() < 0.5 ? -0.26 : 0.21;           // a fumble
            }
            this.nPlan[slot] = u > 0.99 ? -1.0 : this.nextT + err; // now and then it simply misses one
            let iv = this.interval();
            let gap = iv;
            if (this.runT > 15.0 && api.rand() < 0.18) {
                gap = iv * 0.5;
            } else if (api.rand() < 0.1) {
                gap = iv * 2.0;                                       // a rest
            }
            this.nextT += Math.max(0.3, gap);
        }
    }

    pickNext(api: GameApi): i32 {
        let total = 0.0;
        for (let pass = 0; pass < 2; pass++) {
            let r = api.rand() * total;
            for (let d = -2; d <= 2; d++) {
                let g = this.lastF + d;
                if (d == 0 || g < 0 || g >= NF) {
                    continue;
                }
                let age = Math.min(4.0, this.nextT - this.lastSung[g]);
                let w = (d == 1 || d == -1 ? 1.0 : 0.45) * (0.4 + age);
                if (pass == 0) {
                    total += w;
                } else {
                    r -= w;
                    if (r <= 0) {
                        return g;
                    }
                }
            }
        }
        return this.lastF == 0 ? 1 : this.lastF - 1;
    }

    // rings that closed without a click
    judgeLate(api: GameApi): void {
        for (let i = 0; i < NN; i++) {
            if (this.nOn[i] && this.runT > this.nT[i] + GOOD) {
                this.nOn[i] = false;
                this.sour(api, this.nF[i], "LATE");
                if (this.state != ST_PLAY) {
                    return;
                }
            }
        }
    }

    // a click on frog f at the current song time
    hitFrog(api: GameApi, f: i32): void {
        // the frog's pending note closing soonest
        let best = -1;
        let bestT = 1e9;
        for (let i = 0; i < NN; i++) {
            if (this.nOn[i] && this.nF[i] == f && this.nT[i] < bestT) {
                bestT = this.nT[i];
                best = i;
            }
        }
        if (best < 0) {
            this.sour(api, f, "SOUR");
            return;
        }
        let d = this.runT - this.nT[best];
        let ad = Math.abs(d);
        this.nOn[best] = false;
        if (ad <= GOOD) {
            this.sing(api, f, ad <= PERFECT);
        } else {
            this.sour(api, f, d < 0 ? "EARLY" : "LATE");
        }
    }

    sing(api: GameApi, f: i32, perfect: bool): void {
        this.combo++;
        if (this.combo > this.bestCombo) {
            this.bestCombo = this.combo;
        }
        let mult = this.mult();
        this.score += (perfect ? 100 : 50) * mult;
        if (perfect) {
            this.perfects++;
        }
        // every 16 in a row wins a lost voice back
        if (this.combo % 16 == 0 && this.lives < 3) {
            this.lives++;
            this.gainT = 0.8;
        }
        this.singT[f] = 0;
        this.singQ[f] = perfect ? 1.0 : 0.75;
        this.sourT[f] = -1;
        this.bobT = 0;
        this.ripple(f, perfect ? 1.0 : 0.85);
        this.glyph(f, this.combo >= 8 && perfect ? 1 : 0, this.fcol[f]);
        this.say(f, perfect ? "PERFECT" : "GOOD", perfect ? C_YELLOW : C_CREAM);
    }

    sour(api: GameApi, f: i32, why: string): void {
        if (this.state != ST_PLAY) {
            return;
        }
        this.combo = 0;
        this.lives--;
        this.flashT = 0.6;
        this.shakeT = 0.25;
        this.sourT[f] = 0;
        this.singT[f] = -1;
        this.glyph(f, 2, C_SLATE);
        this.say(f, why, C_PINK);
        if (this.lives <= 0) {
            this.lives = 0;
            this.endRun();
        }
    }

    mult(): i32 {
        return min<i32>(4, 1 + this.combo / 8);
    }

    say(f: i32, s: string, c: i32): void {
        this.word = s;
        this.wordF = f;
        this.wordC = c;
        this.wordT = 0;
    }

    glyph(f: i32, kind: i32, c: i32): void {
        for (let i = 0; i < NGLYPH; i++) {
            if (this.gT[i] < 0) {
                this.gT[i] = 0;
                this.gX[i] = this.fsx[f] + 6;
                this.gY[i] = this.fsy[f] - 12;
                this.gC[i] = c;
                this.gK[i] = kind;
                return;
            }
        }
    }

    ripple(f: i32, s: f64): void {
        for (let i = 0; i < NRIP; i++) {
            if (this.ripT[i] < 0) {
                this.ripT[i] = 0;
                this.ripX[i] = this.fx[f];
                this.ripZ[i] = this.fz[f];
                this.ripS[i] = s;
                return;
            }
        }
    }

    // ------------------------------------------------------------------ the frogs

    updateFrogs(api: GameApi, dt: f64): void {
        let over = this.state == ST_OVER;
        let groove = this.state == ST_PLAY && this.combo >= 8;
        for (let f = 0; f < NF; f++) {
            let b = this.frogB[f];
            let x = this.fx[f], y = this.fy[f], z = this.fz[f], yaw = this.fyaw[f];
            let sx = 1.0, sy = 1.0, pitch = 0.0, roll = 0.0, lift = 0.0;
            let sac = -1.0;  // the sac's scale (< 0: hidden)
            // breathing: a slow stepped swell of the throat while idle
            let breath = Math.floor((Math.sin(api.time * 2.4 + <f64>f * 1.7) * 0.5 + 0.5) * 3.0) / 3.0;
            // the beat: everyone dips a little on it
            if (this.bobT < 0.16) {
                let k = Math.floor(this.bobT * 15) / 15 / 0.16;
                sy -= 0.05 * (1.0 - k);
                sx += 0.03 * (1.0 - k);
            }
            // a ring about to close: draw breath (lean back, squash)
            let soon = 9.0;
            for (let i = 0; i < NN; i++) {
                if (this.nOn[i] && this.nF[i] == f) {
                    soon = Math.min(soon, this.nT[i] - this.runT);
                }
            }
            if (soon < 0.3 && soon > -GOOD) {
                let k = 1.0 - Math.max(0.0, soon) / 0.3;
                k = Math.floor(k * 4) / 4;
                sy -= 0.07 * k;
                sx += 0.04 * k;
                pitch -= 6.0 * k;
            }
            if (this.singT[f] >= 0) {
                // the song: stretch up, head back, sac puffed; settle with a wobble
                this.singT[f] += dt;
                let t = this.singT[f];
                let q = this.singQ[f];
                if (t < 0.5) {
                    let k = Math.floor(t * 15) / 15;
                    let up = k < 0.1 ? k / 0.1 : 1.0 - (k - 0.1) / 0.4;
                    sy = 1.0 + 0.16 * up * q;
                    sx = 1.0 - 0.06 * up * q;
                    lift = 0.07 * up * q;
                    pitch = -14.0 * up * q;
                    sac = 0.45 + 0.9 * q * (k < 0.08 ? k / 0.08 : Math.max(0.0, 1.0 - (k - 0.25) / 0.25));
                    roll = Math.sin(k * 40.0) * 3.0 * q;
                } else {
                    this.singT[f] = -1;
                }
            } else if (this.sourT[f] >= 0) {
                // a sour note: squash down and shake the head
                this.sourT[f] += dt;
                let t = this.sourT[f];
                if (t < 0.5) {
                    let k = Math.floor(t * 15) / 15;
                    sy = 0.84 + 0.16 * (k / 0.5);
                    sx = 1.08 - 0.08 * (k / 0.5);
                    roll = (Math.floor(k * 15) % 2 == 0 ? 7.0 : -7.0) * (1.0 - k / 0.5);
                    pitch = 8.0;
                    sac = 0.35;
                } else {
                    this.sourT[f] = -1;
                }
            } else if (over) {
                // the choir has stopped: heads down, sulking
                let k = Math.min(1.0, this.stateT / 0.4);
                sy = 1.0 - 0.1 * k;
                sx = 1.0 + 0.05 * k;
                pitch = 14.0 * k;
            } else {
                if (groove) {
                    roll = (Math.floor((api.time * 2.0 + <f64>f * 0.5)) % 2 == 0 ? 4.0 : -4.0);
                }
                sac = breath > 0.6 ? 0.3 + 0.12 * breath : -1.0;
            }
            api.placeScaled(b, x, y + lift, z, yaw, sx, sy, sx, pitch, roll);
            let sb = this.sacB[f];
            if (sac > 0) {
                // the sac hangs from the chin: the chin's point at rest (turned by the frog's rest yaw),
                // carried by the frog's pose
                let ry = <f64>api.restYaw[b] * Math.PI / 180.0;
                api.transform(b, <f64>api.restX[b] + Math.sin(ry) * CHIN_Z * FROG_S,
                              <f64>api.restY[b] + CHIN_Y * FROG_S,
                              <f64>api.restZ[b] + Math.cos(ry) * CHIN_Z * FROG_S);
                api.place(sb, api.tx, api.ty, api.tz, yaw, pitch, roll, sac);
            } else {
                api.hide(sb);
            }
        }
    }

    updateRipples(api: GameApi, dt: f64): void {
        for (let i = 0; i < NRIP; i++) {
            let b = this.ripB[i];
            if (this.ripT[i] < 0) {
                api.hide(b);
                continue;
            }
            this.ripT[i] += dt;
            let t = this.ripT[i];
            if (t > 0.75) {
                this.ripT[i] = -1;
                api.hide(b);
                continue;
            }
            let k = Math.floor(t * 12) / 12 / 0.75;
            api.place(b, this.ripX[i], 0.02, this.ripZ[i], 0, 0, 0, (0.5 + 0.55 * k) * this.ripS[i]);
        }
    }

    updateMist(api: GameApi, dt: f64): void {
        for (let i = 0; i < NMIST; i++) {
            this.mistX[i] += this.mistV[i] * dt;
            if (this.mistX[i] > 7.5) {
                this.mistX[i] -= 15.0;
            }
            // stepped drift: whole 5 cm steps, so the wisps slide like hand-animated sprites
            let x = Math.floor(this.mistX[i] * 20.0) / 20.0;
            api.place(this.mistB[i], x, 0.22, this.mistZ[i], 0, 0, 0, 0.75);
        }
    }

    // ------------------------------------------------------------------ the demo player

    demoPlay(api: GameApi): void {
        // the next note it means to click, for its cursor
        let next = -1;
        let nextT = 1e9;
        for (let i = 0; i < NN; i++) {
            if (!this.nOn[i]) {
                continue;
            }
            let plan = this.nPlan[i];
            if (plan >= 0 && this.runT >= plan) {
                let f = this.nF[i];
                this.curX = this.fsx[f] + 2;
                this.curY = this.fsy[f] + 3;
                this.curTap = 0;
                this.hitFrog(api, f);
                if (this.state != ST_PLAY) {
                    return;
                }
                continue;
            }
            if (plan >= 0 && plan < nextT) {
                nextT = plan;
                next = i;
            }
        }
        if (next >= 0 && this.curTap > 0.12) {
            // glide the cursor towards the next frog (a hand moving ahead of the beat)
            let f = this.nF[next];
            let k = <f32>Math.min(1.0, api.dt * 9.0);
            this.curX += (this.fsx[f] + 2 - this.curX) * k;
            this.curY += (this.fsy[f] + 3 - this.curY) * k;
        }
    }

    // ------------------------------------------------------------------ input

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind != POINTER_DOWN) {
            return true;
        }
        if (this.state == ST_IDLE) {
            this.beginRun(api, 1.6);
            return true;
        }
        if (this.state == ST_OVER) {
            if (this.stateT > 0.8) {
                this.beginRun(api, 1.6);
            }
            return true;
        }
        // which frog: the nearest ring centre within reach
        let best = -1;
        let bestD: f32 = HIT_R * HIT_R;
        for (let f = 0; f < NF; f++) {
            let dx = x - this.fsx[f], dy = y - this.fsy[f];
            let d = dx * dx + dy * dy;
            if (d < bestD) {
                bestD = d;
                best = f;
            }
        }
        if (best >= 0) {
            this.hitFrog(api, best);
        } else {
            // a click on the water: a plop, and the combo is broken
            this.combo = 0;
        }
        return true;
    }

    // ------------------------------------------------------------------ HUD

    ring(api: GameApi, cx: f32, cy: f32, r: f32, c: u32, dotted: bool): void {
        let n = <i32>Mathf.max(12, Mathf.round(r * 0.9));
        let px = cx + r, py = cy;
        for (let k = 1; k <= n; k++) {
            let a = <f32>k / <f32>n * 6.2831853;
            // a ring seen on the pond is a little flattened
            let qx = cx + r * Mathf.cos(a), qy = cy + r * 0.82 * Mathf.sin(a);
            if (!dotted || k % 2 == 0) {
                api.line(px, py, qx, qy, c);
            }
            px = qx;
            py = qy;
        }
    }

    // a small note sprite: kind 0 a quaver, 1 two beamed quavers, 2 a cross
    noteSprite(api: GameApi, x: f32, y: f32, kind: i32, c: u32, sh: u32): void {
        for (let pass = 0; pass < 2; pass++) {
            let o: f32 = pass == 0 ? 1 : 0;
            let col = pass == 0 ? sh : c;
            if (kind == 2) {
                api.line(x + o, y + o, x + 4 + o, y + 4 + o, col);
                api.line(x + 4 + o, y + o, x + o, y + 4 + o, col);
                continue;
            }
            api.rect(x + o, y + 5 + o, 3, 2, col);
            api.rect(x + 2 + o, y + o, 1, 6, col);
            if (kind == 0) {
                api.rect(x + 3 + o, y + 1 + o, 1, 2, col);
                api.rect(x + 4 + o, y + 2 + o, 1, 2, col);
            } else {
                api.rect(x + 5 + o, y + 5 + o, 3, 2, col);
                api.rect(x + 7 + o, y + o, 1, 6, col);
                api.rect(x + 2 + o, y + o, 6, 2, col);
            }
        }
    }

    hud(api: GameApi): void {
        let black = api.paletteColor(C_BLACK);
        let cream = api.paletteColor(C_CREAM);
        let yellow = api.paletteColor(C_YELLOW);
        let slate = api.paletteColor(C_SLATE);
        let pink = api.paletteColor(C_PINK);
        let bone = api.paletteColor(C_BONE);
        let indigo = api.paletteColor(C_INDIGO);
        let orange = api.paletteColor(C_ORANGE);

        // the beat rings: a dotted target round each frog with a ring coming, the ring closing on it
        if (this.state == ST_PLAY) {
            for (let i = 0; i < NN; i++) {
                if (!this.nOn[i]) {
                    continue;
                }
                let f = this.nF[i];
                let left = this.nT[i] - this.runT;
                let p = 1.0 - left / this.nLead[i];
                if (p < 0) {
                    continue;
                }
                let cx = this.fsx[f], cy = this.fsy[f];
                this.ring(api, cx, cy, R_TARGET, bone, true);
                let r = R_TARGET + (R_START - R_TARGET) * <f32>Math.max(0.0, 1.0 - p);
                let c = api.paletteColor(this.fcol[f]);
                let inWindow = Math.abs(left) <= GOOD;
                this.ring(api, cx, cy + 1, r, black, false);
                this.ring(api, cx, cy, r, inWindow ? cream : c, false);
                if (inWindow) {
                    this.ring(api, cx, cy, r + 1, c, false);
                }
            }
        } else if (this.state == ST_IDLE) {
            // a practice ring on the lead singer, looping, to show the idea
            let ph = (api.time % 1.4) / 1.4;
            let f = 2;
            let cx = this.fsx[f], cy = this.fsy[f];
            this.ring(api, cx, cy, R_TARGET, bone, true);
            let r = R_TARGET + (R_START - R_TARGET) * <f32>(1.0 - ph);
            this.ring(api, cx, cy + 1, r, black, false);
            this.ring(api, cx, cy, r, ph > 0.88 ? cream : yellow, false);
        }

        // floating notes
        for (let i = 0; i < NGLYPH; i++) {
            if (this.gT[i] < 0) {
                continue;
            }
            let t = this.gT[i];
            let k = <f32>(Math.floor(t * 12) / 12);
            let gx = this.gX[i] + Mathf.round(Mathf.sin(k * 7.0) * 2.0);
            let gy = this.gY[i] - Mathf.round(k * 16.0);
            this.noteSprite(api, gx, gy, this.gK[i], api.paletteColor(this.gC[i]), black);
        }
        // the judgement word
        if (this.wordT >= 0) {
            let w = api.textWidth(this.word, 1);
            let rise = <f32>Math.floor(Math.min(this.wordT, 0.15) * 30);
            let x = Mathf.round(this.fsx[this.wordF] - w * 0.5);
            let y = this.fsy[this.wordF] - 24 - rise;
            api.text(x, y, this.word, api.paletteColor(this.wordC), 1, black);
        }
        // the demo player's hand: an arrow cursor that presses on each click
        if (api.demo && this.state == ST_PLAY) {
            let x = Mathf.round(this.curX), y = Mathf.round(this.curY);
            let press = this.curTap < 0.1;
            if (press) {
                this.ring(api, x, y, 3, cream, false);
            }
            let o: f32 = press ? 1 : 0;
            api.rect(x + o, y + o, 1, 7, black);
            api.rect(x + 1 + o, y + 1 + o, 1, 6, black);
            api.rect(x + 2 + o, y + 2 + o, 1, 4, black);
            api.rect(x + 3 + o, y + 3 + o, 1, 3, black);
            api.rect(x + 4 + o, y + 4 + o, 1, 1, black);
            api.rect(x + 1 + o, y + 2 + o, 1, 4, cream);
            api.rect(x + 2 + o, y + 3 + o, 1, 2, cream);
            api.rect(x + o, y + 7 + o, 2, 1, black);
            api.rect(x + 2 + o, y + 6 + o, 1, 3, black);
            api.rect(x + 3 + o, y + 8 + o, 1, 1, black);
        }

        // score, best, combo
        api.text(4, 4, this.score.toString(), yellow, 2, black);
        api.text(4, 16, "BEST " + this.best.toString(), cream, 1, black);
        if (this.state == ST_PLAY && this.combo >= 2) {
            let m = this.mult();
            let s = this.combo.toString() + " IN TUNE" + (m > 1 ? "  x" + m.toString() : "");
            api.text(4, 24, s, m > 1 ? orange : bone, 1, black);
        }
        // voices left: three notes, top right
        for (let l = 0; l < 3; l++) {
            let x: f32 = <f32>(api.hudW - 12 - l * 10);
            let c = l < this.lives ? cream : slate;
            if (l == this.lives && this.flashT > 0 && Math.floor(this.flashT * 10) % 2 == 0) {
                c = pink;
            }
            if (l == this.lives - 1 && this.gainT > 0 && Math.floor(this.gainT * 10) % 2 == 0) {
                c = yellow;
            }
            this.noteSprite(api, x, 4, 0, c, black);
        }

        let h = <f32>api.hudH;
        if (this.state == ST_IDLE) {
            let blink = Math.floor(api.time * 2) % 2 == 0;
            api.textCentered(h - 20, "CLICK TO SING", blink ? cream : yellow, 2, black);
            api.textCentered(h - 8, "CLICK EACH FROG AS ITS RING CLOSES ON IT", cream, 1, black);
        } else if (this.state == ST_OVER) {
            let pw: f32 = 120, ph: f32 = 44;
            let px = Mathf.floor((<f32>api.hudW - pw) * 0.5), py = Mathf.floor(h * 0.5 - 30);
            api.rect(px, py, pw, ph, indigo);
            api.rect(px - 1, py - 1, pw + 2, 1, pink);
            api.rect(px - 1, py + ph, pw + 2, 1, pink);
            api.rect(px - 1, py, 1, ph, pink);
            api.rect(px + pw, py, 1, ph, pink);
            api.textCentered(py + 5, "GAME OVER", cream, 2, black);
            api.textCentered(py + 19, "SCORE " + this.score.toString() + "   BEST " + this.best.toString(), yellow, 1, black);
            api.textCentered(py + 27, "LONGEST RUN " + this.bestCombo.toString() + " NOTES", bone, 1, black);
            if (this.stateT > 0.8 && !api.demo) {
                api.textCentered(py + 35, "CLICK TO SING AGAIN", orange, 1, black);
            }
        } else if (this.runT < 5.0 && !api.demo) {
            api.textCentered(h - 8, "CLICK EACH FROG AS ITS RING CLOSES ON IT", cream, 1, black);
        }
    }
}
