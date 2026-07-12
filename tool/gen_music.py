#!/usr/bin/env python3
"""Sintetizador chiptune sin dependencias (solo stdlib).

Genera un WAV corto y en bucle por cada canción del catálogo de mundos.
Cada mundo define escala/tonalidad/progresión; cada canción define un estilo
(tempo, timbre, percusión) y una semilla, así las pistas de un mismo mundo
suenan emparentadas pero distintas.
"""
import wave, math, random, os

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
               "assets", "audio", "music")

SCALES = {
    'major':          [0, 2, 4, 5, 7, 9, 11],
    'minor':          [0, 2, 3, 5, 7, 8, 10],
    'dorian':         [0, 2, 3, 5, 7, 9, 10],
    'phrygian':       [0, 1, 3, 5, 7, 8, 10],
    'lydian':         [0, 2, 4, 6, 7, 9, 11],
    'harmonic_minor': [0, 2, 3, 5, 7, 8, 11],
    'majpent':        [0, 2, 4, 7, 9],
    'minpent':        [0, 3, 5, 7, 10],
}


def midi_to_freq(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


def scale_note(root, scale, degree):
    s = SCALES[scale]
    L = len(s)
    octave = degree // L
    idx = degree % L
    return root + 12 * octave + s[idx]


def render_note(buf, start, dur, freq, wave='pulse', duty=0.5, vol=0.3,
                attack=0.006, decay=0.05, sustain=0.65, release=0.06,
                vibrato=0.0):
    n = len(buf)
    a = max(1, int(attack * SR))
    d = max(1, int(decay * SR))
    r = max(1, int(release * SR))
    for i in range(dur):
        idx = start + i
        if idx >= n:
            break
        if i < a:
            env = i / a
        elif i < a + d:
            env = 1 - (1 - sustain) * ((i - a) / d)
        elif i < dur - r:
            env = sustain
        else:
            env = sustain * max(0.0, (dur - i) / r)
        t = i / SR
        f = freq * (1 + vibrato * math.sin(2 * math.pi * 5.5 * t)) if vibrato else freq
        ph = (f * t) % 1.0
        if wave == 'pulse':
            s = 1.0 if ph < duty else -1.0
        elif wave == 'tri':
            s = 4 * abs(ph - 0.5) - 1
        elif wave == 'sine':
            s = math.sin(2 * math.pi * ph)
        elif wave == 'saw':
            s = 2 * ph - 1
        else:
            s = 0.0
        buf[idx] += s * vol * env


def render_kick(buf, start, vol=0.55):
    dur = int(0.13 * SR)
    for i in range(dur):
        idx = start + i
        if idx >= len(buf):
            break
        t = i / SR
        env = max(0.0, 1 - i / dur)
        f = max(45.0, 130.0 - (i / dur) * 90.0)
        buf[idx] += math.sin(2 * math.pi * f * t) * vol * env * env


def render_hat(buf, start, vol=0.22, length=0.03):
    dur = int(length * SR)
    for i in range(dur):
        idx = start + i
        if idx >= len(buf):
            break
        env = max(0.0, 1 - i / dur)
        buf[idx] += random.uniform(-1, 1) * vol * env


def render_snare(buf, start, vol=0.4):
    dur = int(0.10 * SR)
    for i in range(dur):
        idx = start + i
        if idx >= len(buf):
            break
        env = max(0.0, 1 - i / dur)
        s = random.uniform(-1, 1) * 0.8 + math.sin(2 * math.pi * 190 * i / SR) * 0.2
        buf[idx] += s * vol * env


def lowpass(buf, alpha):
    y = 0.0
    for i in range(len(buf)):
        y += alpha * (buf[i] - y)
        buf[i] = y


# ── Presets ─────────────────────────────────────────────────────────────────

WORLDS = {
    'lego_city':  dict(scale='major',   root=60, prog=[0, 4, 5, 3]),
    'medieval':   dict(scale='minor',   root=57, prog=[0, 5, 3, 4]),
    'galaxy':     dict(scale='lydian',  root=62, prog=[0, 3, 4, 1]),
    'jungle':     dict(scale='dorian',  root=52, prog=[0, 3, 0, 4]),
    'dark_city':  dict(scale='phrygian', root=57, prog=[0, 1, 4, 0]),
    'ocean':      dict(scale='majpent', root=55, prog=[0, 3, 4, 3]),
    'tundra':     dict(scale='lydian',  root=67, prog=[0, 4, 1, 5]),
    'robot_city': dict(scale='minor',   root=48, prog=[0, 0, 3, 4]),
}

STYLES = {
    'neon':  dict(bpm=112, bars=4, lead='pulse', duty=0.5,  lead_oct=1,
                  arp=True,  perc='soft',  bass='tri',   vib=0.006, lp=None),
    'rat':   dict(bpm=150, bars=4, lead='pulse', duty=0.25, lead_oct=1,
                  arp=False, perc='busy',  bass='pulse', vib=0.0,   lp=None),
    'chip':  dict(bpm=128, bars=4, lead='pulse', duty=0.5,  lead_oct=1,
                  arp=False, perc='light', bass='pulse', vib=0.0,   lp=None),
    'chill': dict(bpm=82,  bars=4, lead='sine',  duty=0.5,  lead_oct=0,
                  arp=False, perc='none',  bass='tri',   vib=0.01,  lp=0.35),
}

# Orden EXACTO del catálogo en world_music.dart -> (worldId, [estilos por índice])
CATALOG = [
    ('lego_city',  ['neon', 'rat', 'chip', 'chill']),
    ('medieval',   ['neon', 'rat', 'chip', 'chill']),
    ('galaxy',     ['neon', 'rat', 'chip']),
    ('jungle',     ['rat', 'chill', 'chip']),
    ('dark_city',  ['neon', 'rat', 'chip']),
    ('ocean',      ['chill', 'neon', 'chip']),
    ('tundra',     ['neon', 'rat', 'chill']),
    ('robot_city', ['neon', 'rat', 'chip']),
]


def beats(bpm):
    return 60.0 / bpm


def build(world_id, style_name, seed):
    random.seed(seed)
    w = WORLDS[world_id]
    st = STYLES[style_name]
    scale = w['scale']
    root = w['root']
    prog = w['prog']
    bpm = st['bpm']
    beat = beats(bpm)
    bar = beat * 4
    bars = st['bars']
    N = int(bar * bars * SR)
    buf = [0.0] * N

    def at(time_s):
        return int(time_s * SR)

    lead_root = root + 12 * st['lead_oct']

    for b in range(bars):
        deg = prog[b % len(prog)]
        bar_t = b * bar
        chord = [deg, deg + 2, deg + 4]  # tríada diatónica

        # ── BASS ────────────────────────────────────────────────────────────
        bass_note = scale_note(root - 12, scale, deg)
        if st['bass'] == 'tri':
            if style_name == 'chill':
                render_note(buf, at(bar_t), int(bar * 0.98 * SR),
                            midi_to_freq(bass_note), wave='tri', vol=0.34,
                            attack=0.02, decay=0.3, sustain=0.6, release=0.2)
            else:  # neon: pulso de corcheas
                for k in range(8):
                    render_note(buf, at(bar_t + k * beat / 2),
                                int(beat / 2 * 0.9 * SR),
                                midi_to_freq(bass_note), wave='tri', vol=0.3,
                                attack=0.004, decay=0.06, sustain=0.5,
                                release=0.03)
        else:  # pulse bass, más marcado
            for k in range(8):
                nt = bass_note if k % 4 != 2 else scale_note(root - 12, scale, deg + 4)
                render_note(buf, at(bar_t + k * beat / 2),
                            int(beat / 2 * 0.85 * SR), midi_to_freq(nt),
                            wave='pulse', duty=0.5, vol=0.26,
                            attack=0.003, decay=0.05, sustain=0.45, release=0.02)

        # ── ARP (opcional) ──────────────────────────────────────────────────
        if st['arp']:
            steps = 16
            for k in range(steps):
                ctone = chord[k % 3]
                nt = scale_note(root, scale, ctone)
                render_note(buf, at(bar_t + k * beat / 4),
                            int(beat / 4 * 0.9 * SR), midi_to_freq(nt),
                            wave='pulse', duty=0.5, vol=0.12,
                            attack=0.002, decay=0.03, sustain=0.3, release=0.02)

        # ── MELODÍA ─────────────────────────────────────────────────────────
        # Ritmo: secuencia de duraciones (en pulsos) que suman 4.
        patterns = {
            'neon':  [[1, 1, 0.5, 0.5, 1], [1, 0.5, 0.5, 1, 1], [2, 1, 1]],
            'rat':   [[0.5, 0.5, 0.5, 0.5, 1, 1], [0.5, 0.5, 1, 0.5, 0.5, 1],
                      [1, 0.5, 0.5, 0.5, 0.5, 1]],
            'chip':  [[1, 1, 1, 1], [0.5, 0.5, 1, 1, 1], [1, 0.5, 0.5, 1, 1]],
            'chill': [[2, 2], [2, 1, 1], [3, 1]],
        }
        rhythm = random.choice(patterns[style_name])
        # empieza en un tono del acorde cerca del centro
        cur = chord[random.randint(0, 2)] + 7  # una octava arriba de la base
        t = bar_t
        for durbeats in rhythm:
            if random.random() < (0.12 if style_name != 'chill' else 0.05):
                t += durbeats * beat  # silencio ocasional
                continue
            # en pulso fuerte, tiende a tono del acorde
            strong = abs((t - bar_t) / beat - round((t - bar_t) / beat)) < 1e-6
            if strong and random.random() < 0.7:
                target = random.choice(chord) + 7
                cur = target
            else:
                cur += random.choice([-2, -1, -1, 1, 1, 2])
                cur = max(0, min(20, cur))
            nt = scale_note(lead_root, scale, cur)
            dur = int(durbeats * beat * 0.92 * SR)
            render_note(buf, at(t), dur, midi_to_freq(nt), wave=st['lead'],
                        duty=st['duty'], vol=0.32,
                        attack=0.006, decay=0.06,
                        sustain=0.6 if style_name != 'chill' else 0.75,
                        release=0.08 if style_name != 'chill' else 0.25,
                        vibrato=st['vib'])
            t += durbeats * beat

        # ── PERCUSIÓN ───────────────────────────────────────────────────────
        perc = st['perc']
        if perc != 'none':
            for beatn in range(4):
                bt = bar_t + beatn * beat
                if beatn in (0, 2):
                    render_kick(buf, at(bt))
                if perc == 'busy' and beatn in (1, 3):
                    render_snare(buf, at(bt))
                # hats
                if perc == 'busy':
                    for h in range(4):
                        render_hat(buf, at(bt + h * beat / 4), vol=0.16)
                elif perc == 'soft':
                    render_hat(buf, at(bt + beat / 2), vol=0.16)
                elif perc == 'light':
                    render_hat(buf, at(bt), vol=0.14)

    if st['lp']:
        lowpass(buf, st['lp'])

    return buf


def normalize_and_write(buf, path):
    peak = max(1e-6, max(abs(x) for x in buf))
    g = 0.85 / peak
    # fade de 5 ms en extremos para un bucle sin clic
    fade = int(0.005 * SR)
    n = len(buf)
    frames = bytearray(n)
    for i in range(n):
        s = buf[i] * g
        if i < fade:
            s *= i / fade
        elif i > n - fade:
            s *= (n - i) / fade
        if s > 1:
            s = 1
        elif s < -1:
            s = -1
        frames[i] = int(s * 127 + 128) & 0xFF
    with wave.open(path, 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(1)   # 8-bit unsigned PCM
        wf.setframerate(SR)
        wf.writeframes(bytes(frames))


def main():
    os.makedirs(OUT, exist_ok=True)
    total = 0
    for world_id, styles in CATALOG:
        for i, style in enumerate(styles, start=1):
            name = f"{world_id}_{i}.wav"
            seed = f"{world_id}-{i}-{style}"
            buf = build(world_id, style, seed)
            path = os.path.join(OUT, name)
            normalize_and_write(buf, path)
            sz = os.path.getsize(path)
            total += sz
            print(f"  {name:22s} {style:5s} {sz//1024:4d} KB")
    print(f"TOTAL {total//1024} KB en {sum(len(s) for _, s in CATALOG)} pistas")


if __name__ == '__main__':
    main()
