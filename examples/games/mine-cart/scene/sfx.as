// Procedural chiptune sound effects on Rive's audio thread. Owned by the renderer (synced from the
// skill like game_api.as): a game never edits it, it calls api.sound / api.soundAt / api.note.
//
// SfxSynth is an AudioProcessor fed by a Ring<SfxEvent>: splat_scene.as starts it on the first
// sound and sends one event per api.sound call, stamped with the audio clock (Audio.timeFrame) so
// every sound starts on the frame the game asked for (also in `rive --render-audio`). A pool of
// voices plays presets built from a square (with duty), a triangle, a sine, or sample-and-hold
// noise, each with a pitch slide or an arpeggio, a soft one-pole low-pass and a click-free
// envelope. process() never allocates.
import { AudioProcessor } from "rive/audio";
import { Ring } from "rive/shared";

export class SfxEvent {
    kind: f64 = 0;
    pitch: f64 = 1;     // frequency multiplier (api.note sets it from a MIDI note)
    volume: f64 = 1;
    pan: f64 = 0;       // -1 left .. 1 right
    at: f64 = 0;        // engine frame to start on (0: at once)
}

const VOICES: i32 = 24;
const SQUARE: i32 = 0;
const TRIANGLE: i32 = 1;
const SINE: i32 = 2;
const NOISE: i32 = 3;

// presets, by kind (game_api.as names them SFX_*): wave, f0 Hz, f1 Hz, seconds, attack s, volume,
// duty, low-pass Hz, arpeggio step s (0: none), vibrato depth
const P_WAVE: StaticArray<i32> = [SQUARE, SQUARE, SQUARE, NOISE, NOISE, SQUARE, SQUARE, SINE, NOISE, NOISE,
    TRIANGLE, SINE, SQUARE, TRIANGLE, SQUARE, SINE, NOISE, SQUARE];
const P_F0: StaticArray<f64> = [880, 300, 988, 3500, 1800, 1400, 523, 170, 7000, 700,
    440, 440, 440, 523, 2200, 520, 9000, 2400];
const P_F1: StaticArray<f64> = [880, 760, 988, 500, 90, 220, 523, 48, 900, 3200,
    440, 440, 440, 523, 2200, 1250, 9000, 260];
const P_DUR: StaticArray<f64> = [0.07, 0.2, 0.28, 0.22, 0.75, 0.17, 0.42, 0.18, 0.5, 0.34,
    0.45, 1.3, 0.85, 0.55, 0.025, 0.08, 0.018, 0.22];
const P_ATT: StaticArray<f64> = [0.002, 0.004, 0.002, 0.002, 0.004, 0.002, 0.003, 0.002, 0.01, 0.12,
    0.004, 0.003, 0.004, 0.004, 0.001, 0.002, 0.001, 0.002];
const P_VOL: StaticArray<f64> = [0.32, 0.36, 0.3, 0.42, 0.62, 0.3, 0.3, 0.9, 0.36, 0.26,
    0.4, 0.34, 0.32, 0.34, 0.16, 0.42, 0.22, 0.26];
const P_DUTY: StaticArray<f64> = [0.25, 0.5, 0.25, 0.5, 0.5, 0.5, 0.25, 0.5, 0.5, 0.5,
    0.5, 0.5, 0.5, 0.5, 0.125, 0.5, 0.5, 0.125];
const P_LP: StaticArray<f64> = [5000, 4000, 6000, 5000, 2600, 4200, 5000, 900, 4200, 3000,
    6000, 7000, 3200, 6000, 7000, 5000, 9000, 5200];
const P_ARP: StaticArray<f64> = [0, 0, 0.075, 0, 0, 0, 0.055, 0, 0, 0,
    0, 0, 0.15, 0.075, 0, 0, 0, 0];
const P_VIB: StaticArray<f64> = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0.004, 0.003, 0, 0, 0, 0, 0, 0.02];
// arpeggio steps in semitones per kind with one (8 slots, the list ends at 99)
const ARP: StaticArray<f64> = [
    0, 7, 99, 0, 0, 0, 0, 0,        // COIN
    0, 4, 7, 12, 99, 0, 0, 0,       // POWERUP
    0, -3, -7, -12, 99, 0, 0, 0,    // LOSE
    0, 4, 7, 12, 16, 99, 0, 0,      // WIN
];

export class SfxSynth extends AudioProcessor<Ring<SfxEvent>> {
    ring: Ring<SfxEvent>? = null;
    ev: SfxEvent = new SfxEvent();
    rate: f64 = 48000;
    channels: i32 = 2;
    seed: u32 = 22222;
    // the queue of events not started yet (their frame is ahead)
    qKind: StaticArray<f64> = new StaticArray<f64>(64);
    qPitch: StaticArray<f64> = new StaticArray<f64>(64);
    qVol: StaticArray<f64> = new StaticArray<f64>(64);
    qPan: StaticArray<f64> = new StaticArray<f64>(64);
    qAt: StaticArray<f64> = new StaticArray<f64>(64);
    qn: i32 = 0;
    // voices
    on: StaticArray<bool> = new StaticArray<bool>(VOICES);
    kind: StaticArray<i32> = new StaticArray<i32>(VOICES);
    t: StaticArray<f64> = new StaticArray<f64>(VOICES);
    phase: StaticArray<f64> = new StaticArray<f64>(VOICES);
    pitch: StaticArray<f64> = new StaticArray<f64>(VOICES);
    gainL: StaticArray<f64> = new StaticArray<f64>(VOICES);
    gainR: StaticArray<f64> = new StaticArray<f64>(VOICES);
    held: StaticArray<f64> = new StaticArray<f64>(VOICES);
    lp: StaticArray<f64> = new StaticArray<f64>(VOICES);

    override init(sampleRate: f64, maxFrames: i32, channels: i32, ring: Ring<SfxEvent>): void {
        this.ring = ring;
        this.rate = sampleRate > 0 ? sampleRate : 48000;
        this.channels = channels;
    }

    private noise(): f64 {
        this.seed = this.seed * 1664525 + 1013904223;
        return <f64>(this.seed >> 8) / 8388608.0 - 1.0;
    }

    private startVoice(kind: f64, pitch: f64, volume: f64, pan: f64): void {
        let k = <i32>kind;
        if (k < 0 || k >= P_WAVE.length) {
            return;
        }
        // a free voice, or the oldest one
        let v = -1;
        let oldest = -1.0;
        for (let i = 0; i < VOICES; i++) {
            if (!this.on[i]) {
                v = i;
                break;
            }
            if (this.t[i] > oldest) {
                oldest = this.t[i];
                v = i;
            }
        }
        let p = Math.min(Math.max(pan, -1), 1);
        let g = P_VOL[k] * Math.min(Math.max(volume, 0), 2);
        this.on[v] = true;
        this.kind[v] = k;
        this.t[v] = 0;
        this.phase[v] = 0;
        this.pitch[v] = pitch > 0 ? pitch : 1;
        this.gainL[v] = g * Math.sqrt(0.5 * (1 - p));
        this.gainR[v] = g * Math.sqrt(0.5 * (1 + p));
        this.held[v] = 0;
        this.lp[v] = 0;
    }

    private arpOffset(k: i32, t: f64): f64 {
        let row = -1;
        if (k == 2) { row = 0; } else if (k == 6) { row = 1; } else if (k == 12) { row = 2; } else if (k == 13) { row = 3; }
        if (row < 0 || P_ARP[k] <= 0) {
            return 0;
        }
        let step = <i32>Math.floor(t / P_ARP[k]);
        let i = row * 8;
        let last = 0.0;
        for (let s = 0; s < 8; s++) {
            let v = ARP[i + s];
            if (v == 99) {
                break;
            }
            last = v;
            if (s == step) {
                return v;
            }
        }
        return last;
    }

    override process(out: StaticArray<f32>, frames: i32, startFrame: f64): void {
        let ring = this.ring;
        if (ring != null) {
            while (this.qn < 64 && ring.receiveInto(this.ev)) {
                let n = this.qn;
                this.qKind[n] = this.ev.kind; this.qPitch[n] = this.ev.pitch; this.qVol[n] = this.ev.volume;
                this.qPan[n] = this.ev.pan; this.qAt[n] = this.ev.at;
                this.qn = n + 1;
            }
        }
        let any = this.qn > 0;
        for (let v = 0; v < VOICES && !any; v++) {
            if (this.on[v]) {
                any = true;
            }
        }
        if (!any) {
            return; // silence: out arrives zeroed
        }
        let ch = this.channels;
        let dt = 1.0 / this.rate;
        for (let i = 0; i < frames; i++) {
            let frame = startFrame + <f64>i;
            // start the events whose frame has come
            let q = 0;
            while (q < this.qn) {
                if (this.qAt[q] <= frame) {
                    this.startVoice(this.qKind[q], this.qPitch[q], this.qVol[q], this.qPan[q]);
                    let last = this.qn - 1;
                    this.qKind[q] = this.qKind[last]; this.qPitch[q] = this.qPitch[last]; this.qVol[q] = this.qVol[last];
                    this.qPan[q] = this.qPan[last]; this.qAt[q] = this.qAt[last];
                    this.qn = last;
                } else {
                    q++;
                }
            }
            let l = 0.0, r = 0.0;
            for (let v = 0; v < VOICES; v++) {
                if (!this.on[v]) {
                    continue;
                }
                let k = this.kind[v];
                let t = this.t[v];
                let dur = P_DUR[k];
                if (t >= dur) {
                    this.on[v] = false;
                    continue;
                }
                let u = t / dur;
                // pitch: an exponential slide from f0 to f1, an arpeggio, a vibrato
                let f = P_F0[k] * Math.pow(P_F1[k] / P_F0[k], u) * this.pitch[v];
                let semis = this.arpOffset(k, t);
                if (semis != 0) {
                    f *= Math.pow(2, semis / 12);
                }
                if (P_VIB[k] > 0) {
                    f *= 1 + P_VIB[k] * Math.sin(2 * Math.PI * 6 * t);
                }
                let ph = this.phase[v] + f * dt;
                let wrapped = ph - Math.floor(ph);
                let s = 0.0;
                let w = P_WAVE[k];
                if (w == SQUARE) {
                    s = wrapped < P_DUTY[k] ? 1 : -1;
                } else if (w == TRIANGLE) {
                    s = 1 - 4 * Math.abs(wrapped - 0.5);
                } else if (w == SINE) {
                    s = Math.sin(2 * Math.PI * wrapped);
                } else {
                    // sample-and-hold noise at f
                    if (Math.floor(ph) != Math.floor(this.phase[v])) {
                        this.held[v] = this.noise();
                    }
                    s = this.held[v];
                }
                this.phase[v] = ph;
                // soft one-pole low-pass
                let a = 1 - Math.exp(-2 * Math.PI * P_LP[k] * dt);
                let y = this.lp[v] + a * (s - this.lp[v]);
                this.lp[v] = y;
                // envelope: a short attack, a smooth fall to 0 at the end
                let att = P_ATT[k];
                let e = (t < att ? t / att : 1.0) * (1 - u) * (1 - u);
                l += y * e * this.gainL[v];
                r += y * e * this.gainR[v];
                this.t[v] = t + dt;
            }
            // a soft ceiling, allocation free
            l = l / (1 + Math.abs(l));
            r = r / (1 + Math.abs(r));
            if (ch >= 2) {
                out[i * ch] = <f32>l;
                out[i * ch + 1] = <f32>r;
            } else if (ch == 1) {
                out[i] = <f32>(0.5 * (l + r));
            }
        }
    }
}
