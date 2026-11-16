"""Renders the prototype's Web Audio sound effects (tone(), the 'bubbly'
pack and CONFIRM) to WAV files, offline: the same oscillators, envelopes,
the 3.2 kHz low-pass (Q .4 dB) and the -20 dB 3:1 compressor."""
import math, struct, sys, wave

SR = 44100

def bloop(f, st=0, v=.07): return [[f, st, .16, 'sine', v, f*1.9], [f*2, st, .08, 'sine', v*.25, f*3.2]]
def bell(f, st=0, du=.6, v=.06): return [[f, st, du, 'sine', v], [f*2.76, st, du*.45, 'sine', v*.22], [f*5.4, st, du*.2, 'sine', v*.08]]
def pad(f, st=0, du=.9, v=.04): return [[f, st, du, 'sine', v, 0, 5, .12], [f*1.5, st, du, 'sine', v*.5, 0, 0, .15]]
def seq_of(fn, fs, gap, *a):
    out = []
    for i, f in enumerate(fs): out += fn(f, i*gap, *a)
    return out

BUBBLY = {
    'snap': bloop(523, 0, .08) + bloop(784, .07, .07),
    'right': bloop(659, 0, .06) + bloop(880, .09, .06) + bell(1319, .18, .5, .05),
    'soft': [[392, 0, .28, 'sine', .05, 349, 0, .03]],
    'win': seq_of(bloop, [523, 659, 784], .1, .06) + bell(1047, .3, .9, .06) + bell(1568, .42, .8, .03),
    'boing': [[330, 0, .35, 'sine', .06, 262, 6, .02]],
    'badge': seq_of(bell, [784, 988, 1175, 1568], .11, .7, .05) + pad(523, .2, 1.2, .035),
}
CONFIRM = [[880, 0, .07, 'sine', .035], [1320, .045, .09, 'sine', .025]]
SOUNDS = dict(BUBBLY, tap=CONFIRM)


def render(seq):
    t0 = .01
    end = max(t0 + v[1] + v[2] + .06 for v in seq)
    n = int(end * SR) + 1
    buf = [0.0] * n
    for v in seq:
        v = v + [None] * (8 - len(v))
        f, st, du, typ, vol, f2, vib, atk = v
        typ = typ or 'sine'; vol = vol or .08; A = atk or .012
        s0, ramp = t0 + st, min(du, .12)
        phase = 0.0; lphase = 0.0
        i0, i1 = int(s0 * SR), int((s0 + du + .05) * SR)
        for i in range(i0, min(i1, n)):
            t = i / SR - s0
            # frequency: exponential ramp to f2 over min(du, .12)
            fr = f * (f2 / f) ** min(t / ramp, 1) if f2 else f
            if vib:
                fr += f * .04 * math.sin(lphase); lphase += 2 * math.pi * vib / SR
            # gain: 0 → vol linear over A, then exponential to .0001 at du
            if t < A: g = vol * t / A
            elif t < du: g = vol * (.0001 / vol) ** ((t - A) / (du - A))
            else: g = .0001
            x = math.sin(phase) if typ == 'sine' else (2 / math.pi) * math.asin(math.sin(phase))
            phase += 2 * math.pi * fr / SR
            buf[i] += g * x
    # biquad low-pass, Web Audio's: Q in dB
    fc, q = 3200, 10 ** (.4 / 20)
    w = 2 * math.pi * fc / SR; alpha = math.sin(w) / (2 * q); c = math.cos(w)
    b0, b1, b2 = (1 - c) / 2, 1 - c, (1 - c) / 2
    a0, a1, a2 = 1 + alpha, -2 * c, 1 - alpha
    x1 = x2 = y1 = y2 = 0.0
    for i, x in enumerate(buf):
        y = (b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1, y2, y1 = x1, x, y1, y
        buf[i] = y
    # compressor: threshold -20 dB, ratio 3, knee 30 dB, attack 3 ms,
    # release 250 ms, and Web Audio's automatic make-up gain
    th, ratio, knee = -20.0, 3.0, 30.0
    def curve_db(db):
        if db < th:
            return db
        if db < th + knee:  # the soft knee
            k = db - th
            return db + (1 / ratio - 1) * k * k / (2 * knee)
        y_end = th + knee + (1 / ratio - 1) * knee / 2
        return y_end + (db - th - knee) / ratio
    full = 10 ** ((curve_db(0) - 0) / 20)
    makeup = (1 / full) ** .6
    env = 0.0
    att, rel = math.exp(-1 / (.003 * SR)), math.exp(-1 / (.25 * SR))
    for i, x in enumerate(buf):
        a = abs(x)
        env = att * env + (1 - att) * a if a > env else rel * env + (1 - rel) * a
        db = 20 * math.log10(max(env, 1e-9))
        gain = 10 ** ((curve_db(db) - db) / 20)
        buf[i] = x * gain * makeup
    return buf


def write(name, buf, out):
    with wave.open(f'{out}/{name}.wav', 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s)) * 32767)) for s in buf))
    return max(abs(s) for s in buf)


if __name__ == '__main__':
    out = sys.argv[1]
    for k, seq in SOUNDS.items():
        b = render(seq)
        print(k, f'{len(b)/SR:.2f}s peak {write(k, b, out):.3f}')
