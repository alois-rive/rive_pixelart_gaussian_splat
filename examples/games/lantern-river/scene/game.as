// Lantern river: paper lanterns are set afloat on a night river and drift up into the sky. Click a
// dark lantern to light it: +10 times the chain (up to x8), and the chain grows while each light
// follows the last within 0.9 s (a click on nothing breaks it). A dark lantern that drifts out of the
// sky costs one of three flames; the river launches them faster and faster. One run, one river,
// pointer only.
import { GameApi, POINTER_DOWN, SFX_BELL, SFX_NOTE, SFX_POP, SFX_TICK, SFX_WHOOSH, SFX_LOSE, SFX_WIN } from "./game_api";

const ND: i32 = 16;          // dark lanterns (the "lantern" pool)
const NL: i32 = 10;          // lit lanterns (the "lit" pool)
const NS: i32 = 10;          // their light on the water (the "shine" pool)
const LIVES: i32 = 3;
const CHAIN_T: f64 = 0.9;    // seconds a chain waits for the next light
const CHAIN_MAX: i32 = 8;    // the multiplier stops growing here
const HIT_W: f32 = 6;        // hit box half size around a lantern's centre, HUD pixels
const HIT_H: f32 = 10;
const CENTRE: f32 = 0.66;    // the lantern's centre above its pivot (the fuel block's bottom), metres

// ramps, in art/palette.json order
// sound: bells on a quiet night. A lit lantern chimes a bell (with a paper pop) that climbs a
// pentatonic scale with the chain, and rings an octave chord at the chain's top; a launch is a soft
// plop on the water, a click on empty sky a dry tick (a low pluck if it broke a chain), a dark lantern
// lost into the sky a gust and a low bell.
const PENTA: StaticArray<i32> = [0, 2, 4, 7, 9, 12, 14, 16];

const R_NIGHT: i32 = 0;
const R_PAPER: i32 = 3;
const R_GLOW: i32 = 4;

const READY: i32 = 0;
const PLAY: i32 = 1;
const OVER: i32 = 2;

export class Game {
    state: i32 = READY;
    wasDemo: bool = false;
    runTime: f64 = 0;
    overAt: f64 = 0;
    score: i32 = 0;
    best: i32 = 0;
    lives: i32 = LIVES;
    chain: i32 = 0;
    bestChain: i32 = 0;
    lastLight: f64 = -10;
    spawnT: f64 = 0;

    db: StaticArray<i32> = new StaticArray<i32>(ND);
    don: StaticArray<bool> = new StaticArray<bool>(ND);
    dx: StaticArray<f64> = new StaticArray<f64>(ND);
    dy: StaticArray<f64> = new StaticArray<f64>(ND);
    dz: StaticArray<f64> = new StaticArray<f64>(ND);
    dv: StaticArray<f64> = new StaticArray<f64>(ND);   // rise speed
    dd: StaticArray<f64> = new StaticArray<f64>(ND);   // own drift
    dage: StaticArray<f64> = new StaticArray<f64>(ND);
    dph: StaticArray<f64> = new StaticArray<f64>(ND);

    lb: StaticArray<i32> = new StaticArray<i32>(NL);
    lon: StaticArray<bool> = new StaticArray<bool>(NL);
    lx: StaticArray<f64> = new StaticArray<f64>(NL);
    ly: StaticArray<f64> = new StaticArray<f64>(NL);
    lz: StaticArray<f64> = new StaticArray<f64>(NL);
    lv: StaticArray<f64> = new StaticArray<f64>(NL);
    lage: StaticArray<f64> = new StaticArray<f64>(NL);
    lph: StaticArray<f64> = new StaticArray<f64>(NL);
    lnext: i32 = 0;

    sb: StaticArray<i32> = new StaticArray<i32>(NS);

    // HUD effects: sparks where a lantern was lit, "x3" chain labels, misses, lost flames
    fxX: StaticArray<f32> = new StaticArray<f32>(12);
    fxY: StaticArray<f32> = new StaticArray<f32>(12);
    fxAge: StaticArray<f64> = new StaticArray<f64>(12);
    fxKind: StaticArray<i32> = new StaticArray<i32>(12);   // 0 spark, 1 miss, 2 lost
    fxN: StaticArray<i32> = new StaticArray<i32>(12);
    fxNext: i32 = 0;
    lostFlash: f64 = 9;

    // the demo player's hand
    thinkT: f64 = 0.35;
    curX: f32 = 80;
    curY: f32 = 70;
    curAge: f64 = 9;

    start(api: GameApi): void {
        api.playable = true;
        for (let i = 0; i < ND; i++) {
            this.db[i] = api.bone("lantern" + i.toString());
            api.hide(this.db[i]);
        }
        for (let i = 0; i < NL; i++) {
            this.lb[i] = api.bone("lit" + i.toString());
            api.hide(this.lb[i]);
        }
        for (let i = 0; i < NS; i++) {
            this.sb[i] = api.bone("shine" + i.toString());
            api.hide(this.sb[i]);
        }
        for (let i = 0; i < 12; i++) {
            this.fxAge[i] = 99;
        }
        this.wasDemo = api.demo;
        this.seedSky(api);
        if (api.demo) {
            this.begin(api);
        }
    }

    // a few lanterns already on their way, so the river is alive from the first frame
    seedSky(api: GameApi): void {
        let hs: StaticArray<f64> = [0.5, 1.5, 2.6];
        for (let k = 0; k < 3; k++) {
            let i = this.spawn(api);
            if (i >= 0) {
                this.dy[i] = hs[k];
                this.dage[i] = 2;
                this.dx[i] = -3.5 + <f64>k * 3.2 + api.range(-0.5, 0.5);
            }
        }
        this.spawnT = 1.0;
    }

    begin(api: GameApi): void {
        this.state = PLAY;
        this.runTime = 0;
        this.score = 0;
        this.lives = LIVES;
        this.chain = 0;
        this.bestChain = 0;
        this.lastLight = -10;
        this.thinkT = 0.3;
        api.sound(SFX_WIN, 0.9, 0.45);
    }

    level(): f64 {
        return Math.min(1, this.runTime / 50);
    }

    spawn(api: GameApi): i32 {
        for (let i = 0; i < ND; i++) {
            if (!this.don[i]) {
                this.don[i] = true;
                this.dx[i] = api.range(-5.2, 5.2);
                this.dz[i] = api.range(-1.6, 2.8);
                this.dy[i] = 0.05;
                let lv = this.state == PLAY ? this.level() : 0.15;
                this.dv[i] = (0.4 + lv * 0.55) * api.range(0.8, 1.5);
                this.dd[i] = api.range(-0.12, 0.12);
                this.dage[i] = 0;
                this.dph[i] = api.range(0, 6.3);
                return i;
            }
        }
        return -1;
    }

    wind(t: f64): f64 {
        return 0.22 * Math.sin(t * 0.13) + 0.1 * Math.sin(t * 0.41 + 1.0);
    }

    update(api: GameApi): void {
        let dt = api.dt;
        if (api.demo != this.wasDemo) {
            this.wasDemo = api.demo;
            this.begin(api);
        }
        if (this.state == PLAY) {
            this.runTime += dt;
            if (api.time - this.lastLight > CHAIN_T) {
                this.chain = 0;
            }
        } else if (this.state == OVER && api.demo && api.time - this.overAt > 2.0) {
            this.clearDark(api);
            this.begin(api);
            this.seedSky(api);
        }
        // launches: slow and gentle before the first click, faster as the run goes on
        this.spawnT -= dt;
        if (this.spawnT <= 0) {
            let first = this.spawn(api);
            if (first >= 0 && this.state == PLAY) {
                api.soundAt(SFX_POP, this.dx[first], 0, this.dz[first], 0.35, 0.4);
            }
            if (this.state == PLAY && api.rand() < 0.15 + 0.3 * this.level()) {
                this.spawn(api); // two at once
            }
            let gap = this.state == PLAY ? 1.3 - 0.95 * this.level() : 1.6;
            this.spawnT = gap * api.range(0.75, 1.25);
        }
        let w = this.wind(api.time);
        // dark lanterns: set afloat (a squash on the water), lift off, drift, sway
        for (let i = 0; i < ND; i++) {
            if (!this.don[i]) {
                continue;
            }
            this.dage[i] += dt;
            let a = this.dage[i];
            let b = this.db[i];
            if (a < 0.6) {
                // growing out of the launch: a squash, then a stretch as it lifts
                let u = a / 0.6;
                let s = 0.35 + 0.65 * u;
                let st = u < 0.6 ? 0.8 : 1.15;
                api.placeScaled(b, this.dx[i], this.dy[i], this.dz[i], 0, s / Math.sqrt(st), s * st, s / Math.sqrt(st));
                continue;
            }
            this.dy[i] += this.dv[i] * dt * Math.min(1, (a - 0.6) * 2 + 0.3);
            this.dx[i] += (w + this.dd[i]) * dt;
            let roll = 6 * Math.sin(stepped(a * 2.2 + this.dph[i], 0.4));
            api.place(b, this.dx[i], this.dy[i], this.dz[i], 0, 0, roll);
            // out of the sky?
            if (api.project(<f32>this.dx[i], <f32>this.dy[i], <f32>this.dz[i]) && api.screenY < -1) {
                this.don[i] = false;
                api.hide(b);
                if (this.state == PLAY) {
                    this.lives--;
                    this.chain = 0;
                    this.lostFlash = 0;
                    let pan = Math.min(Math.max(<f64>api.screenX / <f64>api.hudW * 2 - 1, -1), 1) * 0.8;
                    this.addFx(Mathf.max(6, Mathf.min(<f32>api.hudW - 6, api.screenX)), 4, 2, 0);
                    api.sound(SFX_WHOOSH, 0.6, 0.8, pan);
                    api.note(<f64>(50 + this.lives), 0.7, pan, SFX_BELL);
                    if (this.lives <= 0) {
                        this.state = OVER;
                        this.overAt = api.time;
                        api.sound(SFX_LOSE, 0.75, 0.7);
                        if (this.score > this.best) {
                            this.best = this.score;
                        }
                    }
                }
            }
        }
        // lit lanterns: a pop, then up and away, their light on the water fading as they climb
        for (let i = 0; i < NL; i++) {
            let sh = this.sb[i];
            if (!this.lon[i]) {
                continue;
            }
            this.lage[i] += dt;
            let a = this.lage[i];
            this.lv[i] = Math.min(2.4, this.lv[i] + dt * 1.2);
            this.ly[i] += this.lv[i] * dt;
            this.lx[i] += w * 1.5 * dt;
            let b = this.lb[i];
            if (a < 0.3) {
                let u = a / 0.3;
                let s = 1.0 + 0.45 * (1 - u) * (1 - u);
                let st = 1 + 0.25 * Math.sin(u * Math.PI);
                api.placeScaled(b, this.lx[i], this.ly[i], this.lz[i], 0, s / Math.sqrt(st), s * st, s / Math.sqrt(st));
            } else {
                let roll = 4 * Math.sin(stepped(a * 3 + this.lph[i], 0.4));
                api.place(b, this.lx[i], this.ly[i], this.lz[i], 0, 0, roll);
            }
            if (this.ly[i] < 3.2) {
                api.place(sh, this.lx[i], 0, this.lz[i], 0, 0, 0, 1.15 - this.ly[i] / 3.2);
            } else {
                api.hide(sh);
            }
            if (this.ly[i] > 12) {
                this.lon[i] = false;
                api.hide(b);
                api.hide(sh);
            }
        }
        for (let i = 0; i < 12; i++) {
            this.fxAge[i] += dt;
        }
        this.lostFlash += dt;
        this.curAge += dt;
        if (api.demo && this.state == PLAY) {
            this.demoPlay(api, dt);
        }
    }

    clearDark(api: GameApi): void {
        for (let i = 0; i < ND; i++) {
            this.don[i] = false;
            api.hide(this.db[i]);
        }
    }

    // ---------------------------------------------------------------- clicks

    // the dark lantern under HUD point (x, y), or -1
    under(api: GameApi, x: f32, y: f32): i32 {
        let best = -1;
        let bestD: f32 = 1e9;
        for (let i = 0; i < ND; i++) {
            if (!this.don[i] || this.dage[i] < 0.25) {
                continue;
            }
            if (!api.project(<f32>this.dx[i], <f32>this.dy[i] + CENTRE, <f32>this.dz[i])) {
                continue;
            }
            let ex = Mathf.abs(api.screenX - x), ey = Mathf.abs(api.screenY - y);
            if (ex <= HIT_W && ey <= HIT_H) {
                let d = ex * ex + ey * ey * 0.5;
                if (d < bestD) {
                    bestD = d;
                    best = i;
                }
            }
        }
        return best;
    }

    click(api: GameApi, x: f32, y: f32): void {
        let i = this.under(api, x, y);
        if (i < 0) {
            let pan = Math.min(Math.max(<f64>x / <f64>api.hudW * 2 - 1, -1), 1) * 0.8;
            api.sound(SFX_TICK, 0.45, 0.7, pan);
            if (this.chain >= 2) {
                api.note(45, 0.6, pan, SFX_NOTE); // the chain is broken
            }
            this.chain = 0;
            this.addFx(x, y, 1, 0);
            return;
        }
        this.light(api, i);
    }

    light(api: GameApi, i: i32): void {
        this.don[i] = false;
        api.hide(this.db[i]);
        let k = this.lnext;
        this.lnext = (this.lnext + 1) % NL;
        this.lon[k] = true;
        this.lx[k] = this.dx[i];
        this.ly[k] = this.dy[i];
        this.lz[k] = this.dz[i];
        this.lv[k] = this.dv[i];
        this.lage[k] = 0;
        this.lph[k] = this.dph[i];
        if (this.state == PLAY) {
            if (api.time - this.lastLight <= CHAIN_T) {
                this.chain++;
            } else {
                this.chain = 1;
            }
            this.lastLight = api.time;
            if (this.chain > this.bestChain) {
                this.bestChain = this.chain;
            }
            this.score += 10 * imin(this.chain, CHAIN_MAX);
            let pan = 0.0;
            if (api.project(<f32>this.dx[i], <f32>this.dy[i] + CENTRE, <f32>this.dz[i])) {
                pan = Math.min(Math.max(<f64>api.screenX / <f64>api.hudW * 2 - 1, -1), 1) * 0.8;
            }
            let c = imin(this.chain, CHAIN_MAX);
            api.note(<f64>(69 + PENTA[c - 1]), 0.85, pan, SFX_BELL);
            api.sound(SFX_POP, 0.9 + 0.06 * <f64>c, 0.55, pan);
            if (c == CHAIN_MAX) {
                api.note(<f64>(69 + 12 + PENTA[c - 1]), 0.5, pan, SFX_BELL);
                api.note(<f64>(69 + 4 + PENTA[c - 1]), 0.4, pan, SFX_BELL);
            }
        }
        if (api.project(<f32>this.dx[i], <f32>this.dy[i] + CENTRE, <f32>this.dz[i])) {
            this.addFx(api.screenX, api.screenY, 0, this.state == PLAY ? imin(this.chain, CHAIN_MAX) : 0);
        }
    }

    addFx(x: f32, y: f32, kind: i32, n: i32): void {
        let k = this.fxNext;
        this.fxNext = (this.fxNext + 1) % 12;
        this.fxX[k] = x;
        this.fxY[k] = y;
        this.fxAge[k] = 0;
        this.fxKind[k] = kind;
        this.fxN[k] = n;
    }

    pointer(api: GameApi, kind: i32, x: f32, y: f32): bool {
        if (kind != POINTER_DOWN) {
            return true;
        }
        if (this.state == READY) {
            this.begin(api);
        } else if (this.state == OVER) {
            if (api.time - this.overAt < 0.8) {
                return true;
            }
            this.clearDark(api);
            this.begin(api);
            this.seedSky(api);
            return true;
        }
        this.click(api, x, y);
        return true;
    }

    // ---------------------------------------------------------------- the demo player

    demoPlay(api: GameApi, dt: f64): void {
        // a quick but human hand: goes for the lantern closest to escaping (now and then the one
        // nearest its last click, to keep a chain going), aims a few pixels off, waits 0.4-0.85 s
        // and needs a second to notice a new lantern
        this.thinkT -= dt;
        if (this.thinkT > 0) {
            return;
        }
        this.thinkT = api.range(0.4, 0.85);
        let pick = -1;
        let bestV: f64 = -1e9;
        let chainy = api.rand() < 0.35;
        for (let i = 0; i < ND; i++) {
            if (!this.don[i] || this.dage[i] < 1.0) {
                continue;
            }
            if (!api.project(<f32>this.dx[i], <f32>this.dy[i] + CENTRE, <f32>this.dz[i])) {
                continue;
            }
            if (api.screenY < 6) {
                continue; // too late to reach
            }
            let v: f64 = chainy
                ? -<f64>(Mathf.abs(api.screenX - this.curX) + Mathf.abs(api.screenY - this.curY))
                : -<f64>api.screenY;
            if (v > bestV) {
                bestV = v;
                pick = i;
            }
        }
        if (pick < 0) {
            return;
        }
        api.project(<f32>this.dx[pick], <f32>this.dy[pick] + CENTRE, <f32>this.dz[pick]);
        let ex = <f32>(api.range(-1, 1) + api.range(-1, 1)) * 3.6;
        let ey = <f32>(api.range(-1, 1) + api.range(-1, 1)) * 4.0;
        this.curX = api.screenX + ex;
        this.curY = api.screenY + ey;
        this.curAge = 0;
        this.click(api, this.curX, this.curY);
    }

    // ---------------------------------------------------------------- HUD

    hud(api: GameApi): void {
        let ink = api.rampColor(R_NIGHT, 0);
        let hot = api.rampColor(R_GLOW, 2);
        let rose = api.rampColor(R_GLOW, 1);
        let dim = api.rampColor(R_PAPER, 3);
        let w = <f32>api.hudW;
        let h = <f32>api.hudH;
        api.text(3, 3, this.score.toString(), hot, 2, ink);
        api.text(3, 15, "BEST " + this.best.toString(), dim, 1, ink);
        // flames: one small lantern icon per life
        for (let i = 0; i < LIVES; i++) {
            let x = w - 10 - <f32>i * 8;
            let on = i < this.lives;
            let c = on ? hot : api.rampColor(R_PAPER, 1);
            if (!on && i == this.lives && this.lostFlash < 0.6 && (<i32>(this.lostFlash * 10)) % 2 == 0) {
                c = rose;
            }
            api.rect(x + 1, 4, 5, 6, ink);
            api.rect(x, 3, 5, 6, c);
            api.rect(x + 1, 9, 3, 1, on ? rose : ink);
            api.rect(x + 2, 10, 1, 1, c);
        }
        if (this.state == PLAY && this.chain >= 2) {
            let s = "CHAIN X" + imin(this.chain, CHAIN_MAX).toString() + (this.chain >= CHAIN_MAX ? " MAX" : "");
            api.textCentered(4, s, (<i32>(api.time * 6)) % 2 == 0 ? hot : rose, 1, ink);
        }
        // effects
        for (let k = 0; k < 12; k++) {
            let a = this.fxAge[k];
            let x = this.fxX[k], y = this.fxY[k];
            if (this.fxKind[k] == 0 && a < 0.7) {
                // a burst of sparks, then the points rising
                if (a < 0.3) {
                    let r = <f32>(3 + a * 30);
                    let c = a < 0.12 ? hot : rose;
                    for (let j = 0; j < 8; j++) {
                        let an = <f32>j * 0.785 + 0.39;
                        api.rect(Mathf.round(x + Mathf.cos(an) * r), Mathf.round(y + Mathf.sin(an) * r), 1, 1, c);
                    }
                }
                if (this.fxN[k] > 0) {
                    let s = "+" + (this.fxN[k] * 10).toString();
                    let ty = y - 14 - <f32>a * 16;
                    api.text(Mathf.floor(x - api.textWidth(s, 1) * 0.5), Mathf.floor(ty), s, hot, 1, ink);
                }
            } else if (this.fxKind[k] == 1 && a < 0.35) {
                // a miss: a small dim puff
                api.rect(x - 1, y, 3, 1, dim);
                api.rect(x, y - 1, 1, 3, dim);
            } else if (this.fxKind[k] == 2 && a < 1.0) {
                api.text(Mathf.floor(x - 3), 12 + <f32>a * 4, "-1", rose, 1, ink);
            }
        }
        // the demo's hand: a small cross where it clicked
        if (api.demo && this.curAge < 0.35) {
            let c = this.curAge < 0.1 ? hot : dim;
            api.rect(this.curX - 3, this.curY, 2, 1, c);
            api.rect(this.curX + 2, this.curY, 2, 1, c);
            api.rect(this.curX, this.curY - 3, 1, 2, c);
            api.rect(this.curX, this.curY + 2, 1, 2, c);
        }
        if (this.state == READY) {
            api.textCentered(h - 16, "CLICK THE LANTERNS TO LIGHT THEM", hot, 1, ink);
            api.textCentered(h - 9, "QUICK CHAINS SCORE MORE", rose, 1, ink);
        } else if (this.state == OVER) {
            api.textCentered(h * 0.5 - 20, "THE RIVER", hot, 2, ink);
            api.textCentered(h * 0.5 - 8, "WENT DARK", hot, 2, ink);
            api.textCentered(h * 0.5 + 6, "SCORE " + this.score.toString() + "  LONGEST CHAIN " + this.bestChain.toString(), rose, 1, ink);
            if (this.score >= this.best && this.score > 0) {
                api.textCentered(h * 0.5 + 13, "NEW BEST!", hot, 1, ink);
            }
            if (!api.demo && api.time - this.overAt > 0.8) {
                api.textCentered(h - 9, "CLICK TO LIGHT AGAIN", rose, 1, ink);
            }
        }
    }
}

function stepped(phase: f64, step: f64): f64 {
    return Math.floor(phase / step) * step;
}

function imin(a: i32, b: i32): i32 {
    return a < b ? a : b;
}
