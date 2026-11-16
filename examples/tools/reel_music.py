#!/usr/bin/env python3
"""Synthesize a subtle soundtrack for a reel whose beats land on its transitions, and mux it in.

  (from examples/)
  python3 tools/reel_music.py --timeline ../showcase.timeline.json -o ../showcase.wav --mux ../showcase.mp4
  python3 tools/reel_music.py --tour 13 --seconds 10 --hold 1.5 --demos 36 --demo-seconds 8 -o music.wav

The music is built on the reel's own clock: every scene starts a new bar on its first frame (the
moment its dithered fade begins), so each hand-over falls on a downbeat, with a soft accent (a
low kick, a shimmer of the new chord, a hushed cymbal) and a short riser into it. At the default
120 BPM a 10 s scene is exactly 5 bars and an 8 s one 4; a scene of another length simply ends on
a shorter bar.

The sound: A minor, warm and quiet, all additive synthesis (no samples):
  - toured scenes (dioramas): a slow pad, a sine bass on each bar, a soft triangle arpeggio in
    quarters with a dotted-eighth echo, brushed hats;
  - demo scenes (games): the same palette with a gentle groove (kick, a soft clap, eighth hats, a
    walking bass, the arpeggio in eighths);
  - a fade-in at the start, and the last chord ringing out over the end.
Each scene takes two chords from a progression (one per half), so the harmony moves with the reel.

--timeline reads the JSON record_tour.py writes next to its video ({"segments": [{"start", "duration",
"kind"}], "total"}). --mux replaces the video's audio track (the video stream is copied). Needs
NumPy (and ffmpeg for --mux).
"""
import argparse
import json
import math
import os
import shutil
import subprocess
import sys
import tempfile
import wave

import numpy as np

SR = 44100

# chords as MIDI notes (voicings kept between E2 and G4); roots for the bass
CHORDS = {
    "Am7": ([57, 60, 64, 67], 45), "Fmaj7": ([53, 57, 60, 64], 41), "Cmaj7": ([55, 59, 60, 64], 48),
    "G6": ([55, 59, 62, 64], 43), "Dm7": ([53, 57, 60, 62], 38), "Em7": ([52, 55, 59, 62], 40),
    "Fmaj9": ([53, 57, 64, 67], 41), "Gsus": ([55, 60, 62, 67], 43),
}
PROG_TOUR = ["Am7", "Fmaj7", "Cmaj7", "G6", "Dm7", "Am7", "Fmaj9", "Em7"]
PROG_DEMO = ["Fmaj7", "G6", "Em7", "Am7", "Dm7", "Gsus", "Cmaj7", "Am7"]
ARPS = [[0, 1, 2, 3, 2, 1, 0, 2], [0, 2, 1, 3, 2, 0, 3, 1], [3, 2, 1, 0, 1, 2, 3, 2], [0, 1, 3, 2, 0, 2, 1, 3]]


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def env(n, attack, release, total=None):
    """Attack / sustain / release envelope over n samples (seconds)."""
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    dur = n / SR if total is None else total
    r = np.clip((dur - t) / max(release, 1e-4), 0, 1)
    return a * r


def tone(freq, dur, harmonics, detune=0.0, phase=0.0):
    t = np.arange(int(dur * SR)) / SR
    out = np.zeros_like(t)
    for k, amp in harmonics:
        out += amp * np.sin(2 * np.pi * freq * k * (1 + detune) * t + phase * k)
    return out


class Mix:
    def __init__(self, seconds):
        self.n = int(seconds * SR) + SR * 4
        self.l = np.zeros(self.n)
        self.r = np.zeros(self.n)

    def add(self, at, sig, gain=1.0, pan=0.0):
        i = int(at * SR)
        if i >= self.n or len(sig) == 0:
            return
        if i < 0:
            sig = sig[-i:]
            i = 0
        j = min(self.n, i + len(sig))
        s = sig[: j - i] * gain
        self.l[i:j] += s * math.sqrt(0.5 * (1 - pan))
        self.r[i:j] += s * math.sqrt(0.5 * (1 + pan))


def box(x, w):
    """A moving average (a cheap low-pass)."""
    if w <= 1:
        return x
    c = np.cumsum(np.concatenate([[0.0], x]))
    y = (c[w:] - c[:-w]) / w
    return np.concatenate([np.full(w - 1, y[0] if len(y) else 0.0), y])


# --- instruments

def pad(m, start, dur, notes, gain):
    for k, note in enumerate(notes):
        f = hz(note)
        n = int((dur + 1.4) * SR)
        sig = (tone(f, n / SR, [(1, 1.0), (2, 0.18), (3, 0.06)], detune=-0.0025)
               + tone(f, n / SR, [(1, 1.0), (2, 0.12)], detune=0.0031, phase=1.3))
        sig *= env(n, 0.45, 1.3)
        # a slow swell, so long chords breathe
        t = np.arange(n) / SR
        sig *= 0.85 + 0.15 * np.sin(2 * np.pi * (0.11 + 0.03 * k) * t + k)
        m.add(start, sig, gain * 0.055, pan=(k - 1.5) * 0.35)


def bass(m, at, note, dur, gain):
    n = int(dur * SR)
    sig = tone(hz(note), dur, [(1, 1.0), (2, 0.25), (3, 0.05)])
    t = np.arange(n) / SR
    sig *= np.minimum(1, t / 0.008) * np.exp(-t / max(dur * 0.9, 0.05)) * env(n, 0.005, 0.06)
    m.add(at, sig, gain * 0.22)


def pluck(m, at, note, gain, pan, decay=0.45):
    dur = decay * 3
    n = int(dur * SR)
    # a soft triangle: odd harmonics falling as 1/k^2
    sig = tone(hz(note), dur, [(1, 1.0), (3, 1 / 9), (5, 1 / 25), (7, 1 / 49)])
    t = np.arange(n) / SR
    sig *= np.minimum(1, t / 0.004) * np.exp(-t / decay)
    m.add(at, sig, gain, pan)
    # a dotted-eighth echo, panned across
    m.add(at + 0.375, sig, gain * 0.35, -pan)
    m.add(at + 0.75, sig, gain * 0.14, pan)


def kick(m, at, gain):
    dur = 0.35
    t = np.arange(int(dur * SR)) / SR
    f = 45 + 75 * np.exp(-t / 0.035)
    sig = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.13)
    m.add(at, sig, gain * 0.42)


def hat(m, at, gain, rng, open_=False):
    dur = 0.18 if open_ else 0.05
    n = int(dur * SR)
    x = rng.standard_normal(n)
    x = np.diff(np.diff(x, prepend=0), prepend=0)  # bright
    t = np.arange(n) / SR
    x *= np.exp(-t / (0.06 if open_ else 0.014))
    m.add(at, x, gain * 0.022, pan=0.25)


def clap(m, at, gain, rng):
    n = int(0.25 * SR)
    x = rng.standard_normal(n)
    x = np.diff(x, prepend=0) - box(np.diff(x, prepend=0), 30)
    t = np.arange(n) / SR
    e = np.exp(-t / 0.07) * (1 + 0.6 * (np.abs(t - 0.012) < 0.004) + 0.4 * (np.abs(t - 0.024) < 0.004))
    m.add(at, x * e, gain * 0.05, pan=-0.1)


def riser(m, end, length, gain, rng):
    n = int(length * SR)
    x = rng.standard_normal(n)
    t = np.linspace(0, 1, n)
    dark = box(x, 60)
    bright = np.diff(x, prepend=0)
    sig = (dark * (1 - t) * 3 + bright * t * 0.5) * t ** 2.2
    m.add(end - length, sig, gain * 0.05)


def accent(m, at, notes, gain, rng):
    """The downbeat of a transition: a low kick, a hushed cymbal, a rising shimmer of the chord."""
    kick(m, at, gain * 1.1)
    n = int(1.8 * SR)
    x = np.diff(rng.standard_normal(n), prepend=0)
    t = np.arange(n) / SR
    m.add(at, x * np.exp(-t / 0.5) * np.minimum(1, t / 0.01), gain * 0.03, pan=0.15)
    for k, note in enumerate(sorted(notes)):
        f = hz(note + 24)
        sig = tone(f, 1.6, [(1, 1.0), (2.76, 0.18), (5.4, 0.05)])  # a bell's partials
        tt = np.arange(len(sig)) / SR
        sig *= np.minimum(1, tt / 0.003) * np.exp(-tt / 0.6)
        m.add(at + 0.045 * k, sig, gain * 0.03, pan=-0.5 + 0.33 * k)


# --- the score

def compose(segments, total, bpm, seed):
    m = Mix(total)
    rng = np.random.default_rng(seed)
    beat = 60.0 / bpm
    bar = beat * 4
    ti = di = 0
    for idx, seg in enumerate(segments):
        start, dur, kind = seg["start"], seg["duration"], seg["kind"]
        demo = kind == "demo"
        if demo:
            c1, c2 = PROG_DEMO[(2 * di) % 8], PROG_DEMO[(2 * di + 1) % 8]
            di += 1
        else:
            c1, c2 = PROG_TOUR[(2 * ti) % 8], PROG_TOUR[(2 * ti + 1) % 8]
            ti += 1
        bars = max(1, int(math.ceil(dur / bar - 1e-6)))
        half = max(1, bars // 2 + (bars % 2))
        arp = ARPS[(idx * 7 + 3) % len(ARPS)]
        first_demo = demo and (idx == 0 or segments[idx - 1]["kind"] != "demo")
        last = idx == len(segments) - 1
        for b in range(bars):
            t0 = start + b * bar
            if t0 >= start + dur - 1e-6:
                break
            chord = c1 if b < half else c2
            notes, root = CHORDS[chord]
            bar_len = min(bar, start + dur - t0)
            if b == 0 or b == half:
                pad(m, t0, (half if b == 0 else bars - half) * bar, notes, 1.0 if not demo else 0.8)
            # bass
            if demo:
                pattern = [(0, root, 0.45), (1.5, root, 0.2), (2, root + 7, 0.4), (3.5, root + 12, 0.2)]
            else:
                pattern = [(0, root, 1.8), (2.5, root + 7, 0.6)]
            for at_beats, note, d in pattern:
                if at_beats * beat < bar_len - 0.01:
                    bass(m, t0 + at_beats * beat, note, d, 1.0 if demo else 0.8)
            # arpeggio: quarters in the tour, eighths in the games
            step = beat / 2 if demo else beat
            steps = int(round(bar_len / step))
            for s in range(steps):
                k = arp[(b * steps + s) % len(arp)]
                note = notes[k % len(notes)] + 12
                pluck(m, t0 + s * step, note, 0.035 if demo else 0.04,
                      pan=0.35 if s % 2 else -0.35, decay=0.35 if demo else 0.6)
            # drums
            for q in range(int(round(bar_len / beat))):
                tq = t0 + q * beat
                if demo:
                    if q in (0, 2):
                        kick(m, tq, 0.55)
                    if q in (1, 3):
                        clap(m, tq, 0.6, rng)
                    hat(m, tq + beat / 2, 0.8, rng, open_=(q == 3))
                    hat(m, tq, 0.35, rng)
                else:
                    if q == 0 and b > 0:
                        kick(m, tq, 0.3)
                    if q % 2 == 1:
                        hat(m, tq + beat / 2, 0.45, rng)
        # the transition into this scene: a riser before, an accent on its first frame
        if idx > 0:
            notes, _ = CHORDS[c1]
            riser(m, start, beat * 2, 1.4 if first_demo else 1.0, rng)
            accent(m, start, notes, 1.4 if first_demo else 1.0, rng)
        if last:
            notes, root = CHORDS[c2]
            pad(m, start + dur - 0.01, 3.5, notes, 0.6)  # the last chord rings out
    return m, rng


def reverb(x, rng, seconds=2.2, wet=0.22):
    n = int(seconds * SR)
    t = np.arange(n) / SR
    ir = rng.standard_normal(n) * np.exp(-t / (seconds / 5.5))
    ir = box(ir, 6)
    ir[: int(0.012 * SR)] = 0  # a little pre-delay
    ir /= np.sqrt(np.sum(ir ** 2))
    size = 1 << 18
    blk = size - n + 1
    out = np.zeros(len(x) + n)
    H = np.fft.rfft(ir, size)
    for i in range(0, len(x), blk):
        seg = x[i:i + blk]
        y = np.fft.irfft(np.fft.rfft(seg, size) * H, size)[: len(seg) + n - 1]
        out[i:i + len(y)] += y
    return x + wet * out[: len(x)]


def render(segments, total, out, bpm=120, seed=7):
    m, rng = compose(segments, total, bpm, seed)
    l = reverb(m.l, rng)
    r = reverb(m.r, np.random.default_rng(seed + 1))
    n = int(total * SR)
    l, r = l[:n], r[:n]
    # fade in over 2 s, out over the last 2.5 s
    fi = np.minimum(1, np.arange(n) / (2.0 * SR))
    fo = np.minimum(1, (n - np.arange(n)) / (2.5 * SR))
    l *= fi * fo
    r *= fi * fo
    st = np.stack([l, r], 1)
    st /= max(1e-9, np.sqrt(np.mean(st ** 2))) / 0.09   # quiet: about -21 dB RMS
    st = np.tanh(st * 1.2) / np.tanh(1.2)               # soft ceiling
    st *= 0.89 / max(1e-9, np.max(np.abs(st)))          # peaks at -1 dB
    pcm = (st * 32767).astype("<i2")
    with wave.open(out, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    return n / SR


def segments_from_args(a):
    if a.timeline:
        d = json.load(open(a.timeline))
        return d["segments"], d["total"]
    segs, t = [], 0.0
    for i in range(a.tour):
        dur = a.seconds + (a.hold if i == a.tour - 1 else 0)
        segs.append({"start": i * a.seconds, "duration": dur, "kind": "tour"})
    t = a.tour * a.seconds + (a.hold if a.tour else 0)
    for k in range(a.demos):
        segs.append({"start": t + k * a.demo_seconds, "duration": a.demo_seconds, "kind": "demo"})
    total = segs[-1]["start"] + segs[-1]["duration"]
    return segs, total


def mux(video, audio):
    tmp = video + ".music.mp4"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", video, "-i", audio, "-map", "0:v", "-map", "1:a",
                    "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", tmp],
                   check=True)
    os.replace(tmp, video)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--timeline", help="the .timeline.json record_tour.py writes")
    ap.add_argument("--tour", type=int, default=0)
    ap.add_argument("--seconds", type=float, default=10)
    ap.add_argument("--hold", type=float, default=1.5)
    ap.add_argument("--demos", type=int, default=0)
    ap.add_argument("--demo-seconds", type=float, default=8)
    ap.add_argument("--bpm", type=float, default=120)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("-o", "--out", required=True, help="the .wav to write")
    ap.add_argument("--mux", help="a video to put the music into (its video stream is copied)")
    a = ap.parse_args()
    segs, total = segments_from_args(a)
    secs = render(segs, total, a.out, a.bpm, a.seed)
    print(f"wrote {a.out}: {secs:.1f} s, {len(segs)} scenes, {len(segs) - 1} transitions on downbeats at {a.bpm:g} BPM")
    if a.mux:
        if not shutil.which("ffmpeg"):
            raise SystemExit("ffmpeg not found")
        mux(a.mux, a.out)
        print(f"muxed into {a.mux}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
