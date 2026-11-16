// Memory Shrine: four bells hang from a torii on a mountain top at night. The shrine rings a
// sequence; ring it back in order by clicking the bells. Each round adds one note and plays a
// little faster. A wrong bell (or a long silence) ends the run. Pointer only; a run starts on the
// first click; demo mode plays itself.
import { GameApi, POINTER_DOWN } from "./game_api";

const ST_IDLE: i32 = 0;   // before the first click: the bells stir in the wind
const ST_WAIT: i32 = 1;   // a short breath before the shrine plays
const ST_SHOW: i32 = 2;   // the shrine rings the sequence
const ST_INPUT: i32 = 3;  // the player rings it back
const ST_CLEAR: i32 = 4;  // a round done: a little chime
const ST_FAIL: i32 = 5;   // the wrong bell clanks, the right one flashes
const ST_OVER: i32 = 6;

const NBELL: i32 = 4;
const NNOTE: i32 = 10;
const MAXSEQ: i32 = 64;
const HANG_Y: f64 = 4.45;   // the bells' hang point (the top of the loop), world y
const BELL_Z: f64 = -1.0;   // the gate's plane
const BELL_H: f64 = 1.78;   // the hero bell's height at scale 1
const RING_T: f64 = 0.42;   // how long a bell glows when rung
const PATIENCE: f64 = 6.0;  // seconds the shrine waits for the next bell

// palette indices (art/palette.json "colors")
const C_WHITE: i32 = 0;
const C_YELLOW: i32 = 1;
const C_LIME: i32 = 2;
const C_GREEN: i32 = 3;
const C_TEAL: i32 = 4;
const C_STEEL: i32 = 5;
const C_INK: i32 = 7;

export class Game {
    state: i32 = ST_IDLE;
    stateT: f64 = 0;
    score: i32 = 0;       // rounds repeated in full
    best: i32 = 0;
    wasDemo: bool = false;

    bellX: StaticArray<f64> = [-3.6, -1.2, 1.2, 3.5];
    bellS: StaticArray<f64> = [1.35, 1.2, 1.08, 0.96];
    bell: StaticArray<i32> = new StaticArray<i32>(NBELL);
    glow: StaticArray<i32> = new StaticArray<i32>(NBELL);
    ripple: StaticArray<i32> = new StaticArray<i32>(NBELL);
    noteB: StaticArray<i32> = new StaticArray<i32>(NNOTE);

    // each bell's swing: time since it was struck (< 0: at rest), strength, and kind (0 ring, 1 clank)
    ringT: StaticArray<f64> = new StaticArray<f64>(NBELL);
    ringA: StaticArray<f64> = new StaticArray<f64>(NBELL);
    ringDull: StaticArray<bool> = new StaticArray<bool>(NBELL);
    flashT: StaticArray<f64> = new StaticArray<f64>(NBELL);   // glow only (the fail hint)
    phase: StaticArray<f64> = new StaticArray<f64>(NBELL);

    seq: StaticArray<i32> = new StaticArray<i32>(MAXSEQ);
    len: i32 = 0;
    pos: i32 = 0;         // the note being played (SHOW) or expected (INPUT)
    gap: f64 = 0.6;       // seconds between the shrine's notes
    nextT: f64 = 0;
    quiet: f64 = 0;       // seconds since the player's last bell
    failBell: i32 = -1;
    wantBell: i32 = -1;
    failSlow: bool = false;
    hover: i32 = -1;
    entered: StaticArray<i32> = new StaticArray<i32>(MAXSEQ);

    // notes: little sparks rising from a struck bell
    nT: StaticArray<f64> = new StaticArray<f64>(NNOTE);
    nX: StaticArray<f64> = new StaticArray<f64>(NNOTE);
    nY: StaticArray<f64> = new StaticArray<f64>(NNOTE);
    nVX: StaticArray<f64> = new StaticArray<f64>(NNOTE);
    nNext: i32 = 0;

    popT: f64 = -1;
    popText: string = "";
    camTX: f64 = 0;
    camTY: f64 = 0;
    shakeT: f64 = 0;

    // the demo player
    dNext: f64 = 0;

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < NBELL; i++) {
            this.bell[i] = api.bone("bell" + i.toString());
            this.glow[i] = api.bone("glow" + i.toString());
            this.ripple[i] = api.bone("ripple" + i.toString());
            this.ringT[i] = -1;
            this.flashT[i] = -1;
            this.phase[i] = api.range(0, 6.28);
        }
        for (let i = 0; i < NNOTE; i++) {
            this.noteB[i] = api.bone("note" + i.toString());
            this.nT[i] = -1;
        }
        this.camTX = api.targetX;
        this.camTY = api.targetY;
        this.wasDemo = api.demo;
        if (api.demo) {
            this.beginRun(api);
        }
    }

    // ------------------------------------------------------------------ run control

    beginRun(api: GameApi): void {
        this.score = 0;
        this.len = 0;
        this.gap = 0.62;
        this.failBell = -1;
        this.wantBell = -1;
        this.addNote(api);
        this.state = ST_WAIT;
        // the demo (and the video) hears its first bell at once
        this.stateT = api.demo ? 0.35 : 0.0;
    }

    addNote(api: GameApi): void {
        if (this.len < MAXSEQ) {
            // no bell three times in a row: a run of one bell is dull to listen to
            let b = <i32>Math.floor(api.rand() * 4.0) % 4;
            if (this.len >= 2 && this.seq[this.len - 1] == b && this.seq[this.len - 2] == b) {
                b = (b + 1 + <i32>Math.floor(api.rand() * 3.0)) % 4;
            }
            this.seq[this.len] = b;
            this.len++;
        }
        this.gap = Math.max(0.3, 0.64 - 0.028 * <f64>(this.len - 1));
    }

    endRun(): void {
        this.state = ST_OVER;
        this.stateT = 0;
        if (this.score > this.best) {
            this.best = this.score;
        }
    }

    strike(api: GameApi, i: i32, dull: bool): void {
        this.ringT[i] = 0;
        this.ringA[i] = dull ? 1.0 : 0.7 + 0.25 * api.rand();
        this.ringDull[i] = dull;
        if (!dull) {
            // two or three notes rise from the lip
            let n = 2 + (api.rand() < 0.5 ? 1 : 0);
            let s = this.bellS[i];
            for (let k = 0; k < n; k++) {
                let j = this.nNext;
                this.nNext = (this.nNext + 1) % NNOTE;
                this.nT[j] = 0 - <f64>k * 0.08;
                this.nX[j] = this.bellX[i] + api.range(-0.5, 0.5) * s;
                this.nY[j] = HANG_Y - BELL_H * s * 0.75;
                this.nVX[j] = api.range(-0.5, 0.5);
            }
        } else {
            this.shakeT = 0.25;
        }
    }

    // ------------------------------------------------------------------ update

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demoChanged || api.demo != this.wasDemo) {
            // the host switched demo off (a visitor took over) or on: a fresh run either way
            this.wasDemo = api.demo;
            for (let i = 0; i < NBELL; i++) {
                this.ringT[i] = -1;
                this.flashT[i] = -1;
            }
            this.beginRun(api);
        }
        this.stateT += dt;
        let st = this.state;
        if (st == ST_WAIT) {
            if (this.stateT > 0.75) {
                this.state = ST_SHOW;
                this.stateT = 0;
                this.pos = 0;
                this.nextT = 0;
            }
        } else if (st == ST_SHOW) {
            this.nextT -= dt;
            if (this.nextT <= 0) {
                if (this.pos < this.len) {
                    this.strike(api, this.seq[this.pos], false);
                    this.pos++;
                    this.nextT = this.gap;
                } else if (this.nextT <= -0.15) {
                    this.state = ST_INPUT;
                    this.stateT = 0;
                    this.pos = 0;
                    this.quiet = 0;
                    this.dNext = api.range(0.45, 0.8);
                }
            }
        } else if (st == ST_INPUT) {
            this.quiet += dt;
            if (this.quiet > PATIENCE) {
                this.failSlow = true;
                this.fail(this.seq[this.pos], -1);
            }
        } else if (st == ST_CLEAR) {
            if (this.stateT > 1.0) {
                this.addNote(api);
                this.state = ST_WAIT;
                this.stateT = 0.2;
            }
        } else if (st == ST_FAIL) {
            // the right bell flashes three times, then the run ends
            if (this.stateT > 1.6) {
                this.endRun();
            }
        } else if (st == ST_OVER) {
            if (api.demo && this.stateT > 2.0) {
                this.beginRun(api);
            }
        }
        if (api.demo) {
            this.demoThink(api, dt);
        }
        // swings and glows
        for (let i = 0; i < NBELL; i++) {
            if (this.ringT[i] >= 0) {
                this.ringT[i] += dt;
                if (this.ringT[i] > 2.2) {
                    this.ringT[i] = -1;
                }
            }
            if (this.flashT[i] >= 0) {
                this.flashT[i] += dt;
                if (this.flashT[i] > 1.5) {
                    this.flashT[i] = -1;
                }
            }
        }
        for (let j = 0; j < NNOTE; j++) {
            if (this.nT[j] > -1) {
                this.nT[j] += dt;
                if (this.nT[j] > 1.1) {
                    this.nT[j] = -1;
                }
            }
        }
        if (this.popT >= 0) {
            this.popT += dt;
            if (this.popT > 1.1) {
                this.popT = -1;
            }
        }
        // a clank shakes the view by whole art pixels
        if (this.shakeT > 0) {
            this.shakeT -= dt;
            let texel = api.orthoHeight / 136.0;
            let k = Math.floor(api.time * 30.0);
            api.targetX = this.camTX + (k % 2 == 0 ? texel : -texel);
        } else {
            api.targetX = this.camTX;
        }
        this.pose(api);
    }

    // the player (or the demo) rings bell i
    ring(api: GameApi, i: i32): void {
        if (this.state != ST_INPUT) {
            return;
        }
        this.quiet = 0;
        let want = this.seq[this.pos];
        if (i != want) {
            this.failSlow = false;
            this.fail(want, i);
            return;
        }
        this.strike(api, i, false);
        this.entered[this.pos] = i;
        this.pos++;
        if (this.pos >= this.len) {
            this.score = this.len;
            this.state = ST_CLEAR;
            this.stateT = 0;
            this.popText = this.len % 5 == 0 ? "WONDERFUL!" : "ROUND " + this.len.toString() + " CLEAR";
            this.popT = 0;
        }
    }

    fail(want: i32, wrong: i32): void {
        this.state = ST_FAIL;
        this.stateT = 0;
        this.wantBell = want;
        this.failBell = wrong;
        if (wrong >= 0) {
            this.ringT[wrong] = 0;
            this.ringA[wrong] = 1.0;
            this.ringDull[wrong] = true;
        }
        this.shakeT = 0.25;
        this.flashT[want] = 0.1;
    }

    // ------------------------------------------------------------------ the demo player

    demoThink(api: GameApi, dt: f64): void {
        if (this.state != ST_INPUT) {
            return;
        }
        this.dNext -= dt;
        if (this.dNext > 0) {
            return;
        }
        // a person's pace: quick at first, a little hesitation on the later notes of a long tune
        this.dNext = api.range(0.32, 0.55) + (this.pos > 4 ? api.range(0.0, 0.25) : 0.0);
        let want = this.seq[this.pos];
        // memory slips: none on short tunes, more as the tune grows (a run of about 6 to 11 rounds)
        let slip = Math.max(0.0, <f64>(this.len - 5) * 0.03);
        let b = want;
        if (api.rand() < slip) {
            // usually the neighbour, sometimes the bell heard just before
            b = api.rand() < 0.6 ? (want + (api.rand() < 0.5 ? 1 : 3)) % 4 : (this.pos > 0 ? this.seq[this.pos - 1] : (want + 2) % 4);
            if (b == want) {
                b = (want + 1) % 4;
            }
        }
        this.hover = b;
        this.ring(api, b);
    }

    // ------------------------------------------------------------------ pointer

    // which bell a HUD point is over: the bell's column on the gate's plane, from the beam down to the
    // terrace (generous: a bell is a big target)
    bellAt(api: GameApi, x: f32, y: f32): i32 {
        if (!api.pickPlane(x, y, 0, 0, 1, <f32>BELL_Z)) {
            return -1;
        }
        let hx = <f64>api.hitX, hy = <f64>api.hitY;
        if (hy < 0.6 || hy > HANG_Y + 0.5) {
            return -1;
        }
        let best = -1;
        let bd = 1e9;
        for (let i = 0; i < NBELL; i++) {
            let d = Math.abs(hx - this.bellX[i]);
            if (d < bd) {
                bd = d;
                best = i;
            }
        }
        return bd < 1.2 ? best : -1;
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        this.hover = this.bellAt(api, x, y);
        if (kind != POINTER_DOWN) {
            return true;
        }
        if (this.state == ST_IDLE) {
            this.beginRun(api);
        } else if (this.state == ST_OVER) {
            if (this.stateT > 0.6) {
                this.beginRun(api);
            }
        } else if (this.state == ST_INPUT && this.hover >= 0) {
            this.ring(api, this.hover);
        }
        return true;
    }

    // ------------------------------------------------------------------ posing the bones

    pose(api: GameApi): void {
        let t = api.time;
        for (let i = 0; i < NBELL; i++) {
            let s = this.bellS[i];
            let L = BELL_H * s;
            // the swing: a damped pendulum, stepped at 15 fps; at rest a slow stir in the wind
            let ang = Math.sin(t * 0.9 + this.phase[i]) * 1.2;
            let rt = this.ringT[i];
            if (rt >= 0) {
                let k = Math.floor(rt * 15.0) / 15.0;
                let amp = this.ringDull[i] ? 7.0 : 13.0 * this.ringA[i];
                let per = this.ringDull[i] ? 0.16 : 0.5 + 0.08 * s;
                ang += amp * Math.exp(-k / (this.ringDull[i] ? 0.25 : 0.55)) * Math.sin(k / per * Math.PI * 2.0);
            }
            ang = Math.round(ang);
            let a = ang * Math.PI / 180.0;
            let ox = this.bellX[i] + L * Math.sin(a);
            let oy = HANG_Y - L * Math.cos(a);
            let lit = rt >= 0 && rt < RING_T && !this.ringDull[i];
            let fl = this.flashT[i];
            if (fl >= 0 && Math.floor(fl * 4.0) % 2 == 0) {
                lit = true;
            }
            // a struck bell drops a hair on its cord and pops back (squash at the hit)
            let sq = 1.0;
            if (rt >= 0 && rt < 0.12 && !this.ringDull[i]) {
                sq = 0.94;
            }
            if (lit) {
                api.hide(this.bell[i]);
                api.placeScaled(this.glow[i], ox, oy + L * (1.0 - sq), BELL_Z, 0, 1.0 + (1.0 - sq), sq, 1.0 + (1.0 - sq), 0, ang);
            } else {
                api.hide(this.glow[i]);
                api.place(this.bell[i], ox, oy, BELL_Z, 0, 0, ang);
            }
            // the ring wave: grows from the bell and is gone
            let rb = this.ripple[i];
            if (rt >= 0 && rt < 0.5 && !this.ringDull[i]) {
                let k = Math.floor(rt * 15.0) / 15.0 / 0.5;
                let cy = HANG_Y - L * 0.52;
                api.place(rb, this.bellX[i], cy, BELL_Z - 0.6, 0, 0, 0, (0.45 + 0.75 * k) * s);
            } else {
                api.hide(rb);
            }
        }
        for (let j = 0; j < NNOTE; j++) {
            let nt = this.nT[j];
            if (nt < 0) {
                api.hide(this.noteB[j]);
                continue;
            }
            let k = Math.floor(nt * 12.0) / 12.0;
            let x = this.nX[j] + this.nVX[j] * k + Math.sin(k * 9.0 + <f64>j) * 0.18;
            let y = this.nY[j] + k * 2.2;
            api.place(this.noteB[j], x, y, BELL_Z + 0.7, k * 300.0, 0, 0, 1.0 - k * 0.5);
        }
    }

    // ------------------------------------------------------------------ HUD

    bellColor(api: GameApi, i: i32): u32 {
        return i == 0 ? api.paletteColor(C_GREEN) : (i == 1 ? api.paletteColor(C_LIME) : (i == 2 ? api.paletteColor(C_YELLOW) : api.paletteColor(C_WHITE)));
    }

    hud(api: GameApi): void {
        let white = api.paletteColor(C_WHITE);
        let yellow = api.paletteColor(C_YELLOW);
        let lime = api.paletteColor(C_LIME);
        let teal = api.paletteColor(C_TEAL);
        let steel = api.paletteColor(C_STEEL);
        let ink = api.paletteColor(C_INK);
        let w = <f32>api.hudW, h = <f32>api.hudH;
        // round and best
        api.rect(2, 2, 40, 20, ink);
        api.text(4, 4, "ROUND", lime, 1, ink);
        api.text(26, 3, (this.state == ST_IDLE ? 0 : this.len).toString(), white, 2, ink);
        api.text(4, 15, "BEST " + this.best.toString(), teal, 1, ink);
        // the hovered bell: a small mark under its lip
        if (this.state == ST_INPUT && this.hover >= 0 && !api.demo) {
            let s = this.bellS[this.hover];
            if (api.project(<f32>this.bellX[this.hover], <f32>(HANG_Y - BELL_H * s - 0.25), <f32>BELL_Z)) {
                let x = Mathf.round(api.screenX), y = Mathf.round(api.screenY);
                api.rect(x - 4, y, 9, 3, ink);
                api.rect(x - 3, y + 1, 7, 1, this.bellColor(api, this.hover));
            }
        }
        if (this.popT >= 0) {
            let rise = <f32>(Math.floor(this.popT * 10.0));
            api.textCentered(26 - rise, this.popText, yellow, 1, ink);
        }
        let st = this.state;
        if (st == ST_IDLE) {
            let blink = Math.floor(api.time * 2) % 2 == 0;
            api.textCentered(h - 20, "CLICK TO WAKE THE BELLS", blink ? white : yellow, 1, ink);
            api.textCentered(h - 11, "LISTEN, THEN RING THEM BACK IN ORDER", lime, 1, ink);
            return;
        }
        if (st == ST_OVER) {
            let pw: f32 = 128, ph: f32 = 42;
            let px = Mathf.floor((w - pw) * 0.5), py = Mathf.floor(h * 0.5 - 24);
            api.rect(px - 1, py - 1, pw + 2, ph + 2, teal);
            api.rect(px, py, pw, ph, ink);
            api.textCentered(py + 4, this.failSlow ? "TOO SLOW" : "WRONG BELL", yellow, 2);
            api.textCentered(py + 18, "ROUNDS " + this.score.toString() + "   BEST " + this.best.toString(), white, 1);
            if (this.stateT > 0.6 && !api.demo) {
                let blink = Math.floor(api.time * 2) % 2 == 0;
                api.textCentered(py + 30, "CLICK TO RING AGAIN", blink ? lime : white, 1);
            }
            return;
        }
        // the tune's pips: rung notes in their bell's colour, the rest hollow
        let n = this.len;
        let pip: f32 = 5;
        let gapPx: f32 = 2;
        let total = <f32>n * (pip + gapPx) - gapPx;
        let scale: f32 = total > w - 20 ? (w - 20) / total : 1;
        let x0 = Mathf.floor((w - total * scale) * 0.5);
        let y0 = h - 10;
        api.rect(x0 - 2, y0 - 2, total * scale + 4, pip + 4, ink);
        for (let k = 0; k < n; k++) {
            let x = x0 + Mathf.floor(<f32>k * (pip + gapPx) * scale);
            let filled = false;
            let c = steel;
            if (st == ST_SHOW && k < this.pos) {
                filled = true;
                c = teal;
            } else if ((st == ST_INPUT || st == ST_FAIL) && k < this.pos) {
                filled = true;
                c = this.bellColor(api, this.entered[k]);
            } else if (st == ST_CLEAR) {
                filled = true;
                c = this.bellColor(api, this.entered[k]);
            }
            if (filled) {
                api.rect(x, y0, pip, pip, c);
            } else {
                api.rect(x, y0, pip, 1, c);
                api.rect(x, y0 + pip - 1, pip, 1, c);
                api.rect(x, y0, 1, pip, c);
                api.rect(x + pip - 1, y0, 1, pip, c);
            }
        }
        let label = "";
        let lc = white;
        if (st == ST_WAIT || st == ST_SHOW) {
            label = "LISTEN...";
            lc = lime;
        } else if (st == ST_INPUT) {
            label = "YOUR TURN";
            lc = yellow;
        } else if (st == ST_FAIL) {
            label = this.failSlow ? "THE SHRINE GREW TIRED OF WAITING" : "THAT WAS NOT THE BELL";
            lc = white;
        }
        if (label.length > 0) {
            api.textCentered(y0 - 10, label, lc, 1, ink);
        }
        // patience: a thin bar under the pips once the player hesitates
        if (st == ST_INPUT && this.quiet > 2.0 && !api.demo) {
            let f = <f32>Math.max(0.0, 1.0 - (this.quiet - 2.0) / (PATIENCE - 2.0));
            let bw: f32 = 40;
            api.rect(Mathf.floor((w - bw) * 0.5), y0 + pip + 3, Mathf.round(bw * f), 1, teal);
        }
    }
}
