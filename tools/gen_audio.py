"""Generate original royalty-free audio (SFX + ambient music) for HumanityLedger.

All sound is synthesized from scratch with numpy -> no third-party samples, no
license concerns (original work, effectively CC0). Output: .ogg (Vorbis).

Run from project root:  python tools/gen_audio.py
Re-run after tweaking parameters; Godot re-imports on next open.
"""
import numpy as np
import soundfile as sf
import os
from scipy.signal import fftconvolve, butter, lfilter

SR = 44100
SFX_DIR = "Assets/audio/sfx"
MUS_DIR = "Assets/audio/music"


# ---------- helpers ----------
def midi(n):
    return 440.0 * 2.0 ** ((n - 69) / 12.0)


def adsr(n, a, d, s, r, sustain=0.7):
    a = max(1, int(a * SR)); d = max(1, int(d * SR)); r = max(1, int(r * SR))
    s_len = max(0, n - a - d - r)
    env = np.concatenate([
        np.linspace(0, 1, a),
        np.linspace(1, sustain, d),
        np.full(s_len, sustain),
        np.linspace(sustain, 0, r),
    ])
    if len(env) < n:
        env = np.pad(env, (0, n - len(env)))
    return env[:n]


def sine(f, n, phase=0.0):
    t = np.arange(n) / SR
    return np.sin(2 * np.pi * f * t + phase)


def bell(f, dur, decay=2.5, partials=(1, 2.01, 3.01, 4.2, 5.4), gains=(1, .6, .4, .25, .15)):
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for p, g in zip(partials, gains):
        out += g * np.sin(2 * np.pi * f * p * t) * np.exp(-decay * t * (0.6 + 0.4 * p))
    return out


def lowpass(x, cutoff, order=4):
    b, a = butter(order, min(cutoff / (SR / 2), 0.99), btype="low")
    return lfilter(b, a, x)


def reverb(x, dur=0.8, wet=0.22, cutoff=4500):
    n = int(dur * SR)
    ir = np.random.randn(n) * np.exp(-np.linspace(0, 6, n))
    ir = lowpass(ir, cutoff)
    ir /= np.max(np.abs(ir)) + 1e-9
    wetsig = fftconvolve(x, ir)[:len(x)]
    return (1 - wet) * x + wet * wetsig


def norm(x, peak=0.85):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak


def fade(x, ms=8):
    k = int(SR * ms / 1000)
    if len(x) > 2 * k:
        x[:k] *= np.linspace(0, 1, k)
        x[-k:] *= np.linspace(1, 0, k)
    return x


def overlay(base, sig, offset_s):
    off = int(offset_s * SR)
    end = off + len(sig)
    if end > len(base):
        base = np.pad(base, (0, end - len(base)))
    base[off:end] += sig
    return base


def _write_ogg(path, data):
    # chunked write: libsndfile's Vorbis encoder overflows the stack on large
    # single-shot writes on Windows, so stream it in blocks.
    data = np.ascontiguousarray(data.astype(np.float32))
    ch = 1 if data.ndim == 1 else data.shape[1]
    with sf.SoundFile(path, mode="w", samplerate=SR, channels=ch, format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(data), 16384):
            f.write(data[i:i + 16384])


def save_sfx(name, x, peak=0.8):
    x = fade(norm(np.asarray(x, dtype=np.float64), peak))
    _write_ogg(os.path.join(SFX_DIR, name + ".ogg"), x)
    print(f"sfx {name:16s} {len(x)/SR:.2f}s")


# ---------- SFX ----------
def gen_sfx():
    os.makedirs(SFX_DIR, exist_ok=True)
    # drag_pickup: soft wooden tick
    n = int(0.09 * SR)
    x = sine(520, n) * adsr(n, .002, .02, .3, .05, .4)
    x += 0.4 * sine(780, n) * adsr(n, .001, .015, .2, .04, .3)
    save_sfx("drag_pickup", x, 0.5)

    # drag_hover: very subtle high blip
    n = int(0.05 * SR)
    x = sine(1040, n) * adsr(n, .001, .01, .2, .03, .25)
    save_sfx("drag_hover", x, 0.32)

    # drop_success: gentle two-note rise C5->G5, soft bell
    x = np.zeros(int(0.65 * SR))
    x = overlay(x, bell(midi(72), .3, 4.0), 0.0)
    x = overlay(x, bell(midi(79), .5, 3.2), 0.1)
    x = reverb(x, 0.6, 0.2)
    save_sfx("drop_success", x, 0.7)

    # drop_fail: low muted thud, slightly dissonant
    n = int(0.22 * SR)
    x = sine(150, n) * adsr(n, .002, .06, .2, .12, .5)
    x += 0.5 * sine(158, n) * adsr(n, .002, .05, .2, .1, .4)
    x += 0.25 * np.random.randn(n) * np.exp(-np.linspace(0, 9, n))
    x = lowpass(x, 900)
    save_sfx("drop_fail", x, 0.6)

    # stat_up: short ascending chime (E5 G5 B5)
    x = np.zeros(int(.5 * SR))
    for i, nn in enumerate([76, 79, 83]):
        b = bell(midi(nn), .4, 4.5)
        off = int(i * .06 * SR)
        x = np.pad(x, (0, max(0, off + len(b) - len(x))))
        x[off:off + len(b)] += b * (0.9 ** i)
    save_sfx("stat_up", reverb(x, .5, .18), 0.55)

    # stat_down: short descending (B4 G4 E4), darker
    x = np.zeros(int(.5 * SR))
    for i, nn in enumerate([71, 67, 64]):
        b = bell(midi(nn), .4, 4.5)
        off = int(i * .06 * SR)
        x = np.pad(x, (0, max(0, off + len(b) - len(x))))
        x[off:off + len(b)] += b * (0.9 ** i)
    save_sfx("stat_down", reverb(x, .5, .18), 0.5)

    # quest_complete: gentle triumphant arpeggio C E G C (major)
    x = np.zeros(int(1.1 * SR))
    for i, nn in enumerate([72, 76, 79, 84]):
        b = bell(midi(nn), .8, 2.6)
        off = int(i * .1 * SR)
        x = np.pad(x, (0, max(0, off + len(b) - len(x))))
        x[off:off + len(b)] += b * (0.95 ** i)
    save_sfx("quest_complete", reverb(x, .9, .25), 0.75)

    # ledger_unlock: soft shimmer (high bell + slow sparkle)
    x = np.zeros(int(1.0 * SR))
    for i, nn in enumerate([84, 88, 91]):
        b = bell(midi(nn), .9, 3.0)
        off = int(i * .12 * SR)
        x = np.pad(x, (0, max(0, off + len(b) - len(x))))
        x[off:off + len(b)] += b * (0.8 ** i)
    save_sfx("ledger_unlock", reverb(x, 1.0, 0.3), 0.55)

    # era_transition: slow rising swell + low gong
    n = int(2.4 * SR)
    t = np.arange(n) / SR
    swell = adsr(n, 1.4, .3, .8, .6, .85)
    x = np.zeros(n)
    for nn, g in [(36, 1.0), (48, 0.5), (55, 0.35), (60, 0.25)]:
        f = midi(nn)
        x += g * np.sin(2 * np.pi * f * t * (1 + 0.0008 * t))
    x *= swell
    x += 0.3 * bell(midi(48), 2.4, 1.2)
    x = reverb(lowpass(x, 3500), 1.2, 0.35)
    save_sfx("era_transition", x, 0.8)


# ---------- ambient music ----------
def pad_chord(notes, dur, detune=0.12, bright=0.5):
    n = int(dur * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for nn in notes:
        f = midi(nn)
        for dt in (-detune, 0.0, detune):
            ff = f * 2 ** (dt / 12)
            out += np.sin(2 * np.pi * ff * t)
            out += bright * 0.3 * np.sin(2 * np.pi * ff * 2 * t)
    return out / (len(notes) * 3)


def progression(chords, chord_dur, detune=0.12, bright=0.5):
    parts = [pad_chord(c, chord_dur, detune, bright) for c in chords]
    return np.concatenate(parts)


def slow_lfo(n, rate, lo, hi):
    t = np.arange(n) / SR
    return lo + (hi - lo) * (0.5 + 0.5 * np.sin(2 * np.pi * rate * t))


def sparkle(notes_pool, total_dur, count, decay=3.0, gain=0.18, seed=0):
    rng = np.random.default_rng(seed)
    n = int(total_dur * SR)
    x = np.zeros(n)
    for _ in range(count):
        nn = rng.choice(notes_pool)
        b = bell(midi(nn), 1.2, decay) * gain
        off = int(rng.uniform(0, total_dur - 1.3) * SR)
        x[off:off + len(b)] += b
    return x


def make_loop(x, xfade=0.12):
    k = int(xfade * SR)
    if len(x) > 2 * k:
        head = x[:k] * np.linspace(0, 1, k)
        tail = x[-k:] * np.linspace(1, 0, k)
        x = x.copy()
        x[:k] = head + tail
        x = x[:-k]
    return x


def save_music(name, left, right=None, peak=0.5):
    left = np.asarray(left, dtype=np.float64)
    if right is None:
        right = left
    m = max(np.max(np.abs(left)), np.max(np.abs(right))) + 1e-9
    stereo = np.stack([left / m * peak, right / m * peak], axis=1)
    _write_ogg(os.path.join(MUS_DIR, name + ".ogg"), stereo)
    print(f"music {name:14s} {len(left)/SR:.1f}s peak={peak}")


def gen_music():
    os.makedirs(MUS_DIR, exist_ok=True)
    cd = 6.0  # chord duration

    # menu: warm, contemplative minor (Am - F - C - G)
    chords = [[57, 60, 64, 67], [53, 57, 60, 65], [48, 55, 60, 64], [55, 59, 62, 67]]
    base = progression(chords, cd, detune=0.1, bright=0.45)
    base = lowpass(base, 2600)
    n = len(base)
    base *= slow_lfo(n, 0.05, 0.7, 1.0)
    spk = sparkle([72, 76, 79, 84, 81], n / SR, 10, decay=3.2, gain=0.14, seed=1)
    mix = base + spk
    mix = reverb(mix, 1.4, 0.3, 3500)
    L = make_loop(mix)
    Rr = make_loop(reverb(mix, 1.6, 0.34, 3200))[:len(L)]
    save_music("menu", L, Rr, 0.5)

    # era1: dark, sparse, primal drone (Dm pedal, slow)
    chords = [[38, 50, 57], [38, 50, 56], [36, 48, 55], [38, 50, 57]]
    base = progression(chords, cd, detune=0.08, bright=0.25)
    base = lowpass(base, 1500)
    n = len(base)
    base *= slow_lfo(n, 0.035, 0.55, 0.95)
    # soft low pulse (heartbeat-ish)
    pulse = np.zeros(n)
    step = int(cd / 2 * SR)
    for off in range(0, n, step):
        seg = sine(70, int(0.3 * SR)) * adsr(int(0.3 * SR), .01, .1, .2, .15, .4)
        pulse[off:off + len(seg)] += seg * 0.4
    mix = base + lowpass(pulse, 200)
    mix = reverb(mix, 1.8, 0.3, 2200)
    L = make_loop(mix)
    Rr = make_loop(reverb(mix, 2.0, 0.34, 2000))[:len(L)]
    save_music("era1", L, Rr, 0.5)

    # era2: warmer, fuller, regal (Cmaj feel: C - Am - F - G with richer voicing)
    chords = [[48, 55, 60, 64, 67], [57, 60, 64, 69], [53, 60, 65, 69], [55, 59, 62, 67, 71]]
    base = progression(chords, cd, detune=0.12, bright=0.6)
    base = lowpass(base, 3200)
    n = len(base)
    base *= slow_lfo(n, 0.05, 0.75, 1.0)
    spk = sparkle([72, 76, 79, 83, 84, 88], n / SR, 14, decay=2.8, gain=0.16, seed=2)
    mix = base + spk
    mix = reverb(mix, 1.5, 0.32, 4200)
    L = make_loop(mix)
    Rr = make_loop(reverb(mix, 1.7, 0.36, 4000))[:len(L)]
    save_music("era2", L, Rr, 0.5)

    # ending: resolved, calm, slow major (F - C - G - C)
    chords = [[53, 57, 60, 65], [48, 55, 60, 64], [55, 59, 62, 67], [48, 55, 60, 64, 72]]
    base = progression(chords, cd * 1.3, detune=0.1, bright=0.5)
    base = lowpass(base, 3000)
    n = len(base)
    base *= slow_lfo(n, 0.04, 0.7, 1.0)
    spk = sparkle([72, 76, 79, 84], n / SR, 8, decay=2.4, gain=0.13, seed=3)
    mix = reverb(base + spk, 1.8, 0.34, 3800)
    L = make_loop(mix)
    Rr = make_loop(reverb(mix, 2.0, 0.38, 3600))[:len(L)]
    save_music("ending", L, Rr, 0.48)


if __name__ == "__main__":
    gen_sfx()
    gen_music()
    print("done")
