#!/usr/bin/env python3
"""Procedural audio synthesizer for Higher Ground.

Generates high quality 16-bit 44.1kHz WAV sound effects and ambient/music loops:
- wind_ambience.wav (looping arctic wind)
- snow_step.wav (crunchy snow step)
- jump.wav (cheerful jump swoosh)
- land.wav (soft snow landing)
- ice_crack.wav (sharp ice fracture)
- pickup.wav (crystalline 3-note pickup chime)
- sort_ok.wav (uplifting correct sort chime)
- sort_bad.wav (soft low incorrect sort tone)
- ui_click.wav (crisp UI click)
- calm_music.wav (serene looping ambient piano/pad track)

All generated assets are CC0 original audio created for this project.
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100


def clamp(val, min_val=-1.0, max_val=1.0):
    return max(min_val, min(max_val, val))


def write_wav(path: str, samples: list, channels: int = 1, sample_rate: int = SAMPLE_RATE, target_peak: float = 0.16):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(sample_rate)
        
        # Normalize to gentle target peak so audio is never harsh
        peak = max(abs(s) for s in samples) if samples else 0.0
        gain = target_peak / peak if peak > 0.001 else 1.0
        
        packed = bytearray()
        for s in samples:
            val = int(clamp(s * gain) * 32767.0)
            packed.extend(struct.pack("<h", val))
        wf.writeframes(packed)
    print(f"Generated {path} ({len(samples) // channels / sample_rate:.2f}s, {channels}ch)")


def gen_wind_ambience(duration: float = 6.0) -> list:
    total_frames = int(SAMPLE_RATE * duration)
    rng = random.Random(42)
    
    # Generate pink/filtered white noise with two resonant filters and slow LFO modulation
    # Stereo output (interleaved L, R)
    out = [0.0] * (total_frames * 2)
    
    # 2-pole resonant low-pass filter state
    lp_l1, lp_l2 = 0.0, 0.0
    lp_r1, lp_r2 = 0.0, 0.0
    
    for i in range(total_frames):
        t = i / SAMPLE_RATE
        
        # Wind gust modulation (slow LFOs)
        gust1 = 0.5 + 0.5 * math.sin(2.0 * math.pi * 0.22 * t)
        gust2 = 0.5 + 0.5 * math.sin(2.0 * math.pi * 0.41 * t + 1.2)
        gust = 0.35 + 0.45 * (gust1 * 0.6 + gust2 * 0.4)
        
        # Cutoff frequency modulated by gusts
        cutoff = 260.0 + 450.0 * gust
        f_norm = 2.0 * math.sin(math.pi * cutoff / SAMPLE_RATE)
        q_res = 0.4
        
        # Noise samples
        noise_l = rng.uniform(-1.0, 1.0)
        noise_r = rng.uniform(-1.0, 1.0)
        
        # Filter L
        lp_l1 += f_norm * (noise_l - lp_l1 + q_res * (lp_l1 - lp_l2))
        lp_l2 += f_norm * (lp_l1 - lp_l2)
        
        # Filter R
        lp_r1 += f_norm * (noise_r - lp_r1 + q_res * (lp_r1 - lp_r2))
        lp_r2 += f_norm * (lp_r1 - lp_r2)
        
        # Subtle gentle high whistle in the wind (arctic howl)
        howl_freq = 480.0 + 80.0 * math.sin(2.0 * math.pi * 0.18 * t)
        howl = 0.06 * gust * math.sin(2.0 * math.pi * howl_freq * t)
        
        out[i * 2] = (lp_l2 * gust + howl)
        out[i * 2 + 1] = (lp_r2 * gust + howl)
        
    # Crossfade loop boundary (0.8s) for seamless looping
    xfade_len = int(SAMPLE_RATE * 0.8)
    for i in range(xfade_len):
        w = i / float(xfade_len)
        # Head fades in, tail fades out
        head_idx_l = i * 2
        head_idx_r = i * 2 + 1
        tail_idx_l = (total_frames - xfade_len + i) * 2
        tail_idx_r = (total_frames - xfade_len + i) * 2 + 1
        
        blended_l = out[head_idx_l] * w + out[tail_idx_l] * (1.0 - w)
        blended_r = out[head_idx_r] * w + out[tail_idx_r] * (1.0 - w)
        out[head_idx_l] = blended_l
        out[tail_idx_l] = blended_l
        
    return out


def gen_snow_step(duration: float = 0.16) -> list:
    total_frames = int(SAMPLE_RATE * duration)
    rng = random.Random(101)
    samples = []
    
    # Low frequency thump + crunch noise
    lp1, lp2 = 0.0, 0.0
    cutoff = 1900.0
    f_norm = 2.0 * math.sin(math.pi * cutoff / SAMPLE_RATE)
    q_res = 0.3
    
    for i in range(total_frames):
        t = i / SAMPLE_RATE
        
        # Envelope: fast attack (5ms), exponential decay
        env = (t / 0.006) if t < 0.006 else math.exp(-(t - 0.006) / 0.045)
        
        # Thud (low sine)
        thud = math.sin(2.0 * math.pi * 75.0 * (1.0 - t * 3.0) * t) * math.exp(-t / 0.03)
        
        # Noise crunch
        noise = rng.uniform(-1.0, 1.0)
        lp1 += f_norm * (noise - lp1 + q_res * (lp1 - lp2))
        lp2 += f_norm * (lp1 - lp2)
        
        # Additional crunch crackles
        crackle = 0.0
        if rng.random() < 0.08:
            crackle = rng.uniform(-0.8, 0.8) * env
            
        s = (thud * 0.5 + (lp2 * 0.7 + crackle) * env)
        samples.append(s)
    return samples


def gen_jump(duration: float = 0.22) -> list:
    total_frames = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total_frames):
        t = i / SAMPLE_RATE
        
        # Frequency sweep from 240Hz to 520Hz
        freq = 240.0 + 280.0 * (t / duration) ** 0.8
        
        # Amplitude envelope
        env = math.sin(math.pi * (t / duration) ** 0.6)
        
        phase = 2.0 * math.pi * (240.0 * t + 140.0 * (t ** 1.8) / (duration ** 0.8))
        tone = math.sin(phase) + 0.25 * math.sin(2.0 * phase)
        samples.append(tone * env)
    return samples


def gen_land(duration: float = 0.18) -> list:
    total_frames = int(SAMPLE_RATE * duration)
    rng = random.Random(202)
    samples = []
    
    lp1, lp2 = 0.0, 0.0
    cutoff = 950.0
    f_norm = 2.0 * math.sin(math.pi * cutoff / SAMPLE_RATE)
    
    for i in range(total_frames):
        t = i / SAMPLE_RATE
        
        # Impact thud (low damped sine)
        thud = math.sin(2.0 * math.pi * 85.0 * t) * math.exp(-t / 0.035)
        
        # Snow compression crunch
        noise = rng.uniform(-1.0, 1.0)
        lp1 += f_norm * (noise - lp1)
        lp2 += f_norm * (lp1 - lp2)
        env = math.exp(-t / 0.055)
        
        samples.append(thud * 0.7 + lp2 * 0.5 * env)
    return samples


def gen_ice_crack(duration: float = 0.32) -> list:
    total_frames = int(SAMPLE_RATE * duration)
    rng = random.Random(303)
    samples = []
    
    for i in range(total_frames):
        t = i / SAMPLE_RATE
        
        # Sharp initial snap (first 8ms)
        snap = 0.0
        if t < 0.008:
            snap = rng.uniform(-1.0, 1.0) * (1.0 - t / 0.008)
            
        # Resonant fracture creaks
        creak1 = math.sin(2.0 * math.pi * 780.0 * t) * math.exp(-t / 0.08)
        creak2 = math.sin(2.0 * math.pi * 1250.0 * t) * math.exp(-t / 0.05)
        
        # Secondary micro-cracks
        micro = 0.0
        if 0.03 < t < 0.036:
            micro += rng.uniform(-0.8, 0.8)
        if 0.07 < t < 0.075:
            micro += rng.uniform(-0.6, 0.6)
        if 0.12 < t < 0.124:
            micro += rng.uniform(-0.4, 0.4)
            
        s = snap * 0.9 + (creak1 * 0.4 + creak2 * 0.3 + micro * 0.5)
        samples.append(s)
    return samples


def gen_pickup(duration: float = 0.30) -> list:
    total_frames = int(SAMPLE_RATE * duration)
    samples = []
    
    # 3 ascending tones: C6 (1046.5Hz), E6 (1318.5Hz), G6 (1568.0Hz)
    notes = [
        (0.00, 1046.5),
        (0.06, 1318.5),
        (0.12, 1568.0),
    ]
    
    for i in range(total_frames):
        t = i / SAMPLE_RATE
        val = 0.0
        for start_t, freq in notes:
            if t >= start_t:
                dt = t - start_t
                env = math.exp(-dt / 0.09)
                tone = math.sin(2.0 * math.pi * freq * dt) + 0.2 * math.sin(4.0 * math.pi * freq * dt)
                val += tone * env * 0.5
        samples.append(val)
    return samples


def gen_sort_ok(duration: float = 0.35) -> list:
    total_frames = int(SAMPLE_RATE * duration)
    samples = []
    
    # Uplifting two-tone: G5 (784.0Hz) -> C6 (1046.5Hz)
    notes = [
        (0.00, 784.0),
        (0.09, 1046.5),
    ]
    
    for i in range(total_frames):
        t = i / SAMPLE_RATE
        val = 0.0
        for start_t, freq in notes:
            if t >= start_t:
                dt = t - start_t
                env = math.exp(-dt / 0.12)
                tone = math.sin(2.0 * math.pi * freq * dt) + 0.15 * math.sin(4.0 * math.pi * freq * dt)
                val += tone * env * 0.55
        samples.append(val)
    return samples


def gen_sort_bad(duration: float = 0.35) -> list:
    total_frames = int(SAMPLE_RATE * duration)
    samples = []
    
    # Muted descending dissonance: Eb3 (155.6Hz) -> C3 (130.8Hz)
    notes = [
        (0.00, 155.6),
        (0.10, 130.8),
    ]
    
    for i in range(total_frames):
        t = i / SAMPLE_RATE
        val = 0.0
        for start_t, freq in notes:
            if t >= start_t:
                dt = t - start_t
                env = math.exp(-dt / 0.11)
                # Soft triangle / sine mix
                tone = math.sin(2.0 * math.pi * freq * dt) + 0.3 * math.sin(6.0 * math.pi * freq * dt)
                val += tone * env * 0.5
        samples.append(val)
    return samples


def gen_ui_click(duration: float = 0.04) -> list:
    total_frames = int(SAMPLE_RATE * duration)
    samples = []
    for i in range(total_frames):
        t = i / SAMPLE_RATE
        env = math.exp(-t / 0.007)
        click = math.sin(2.0 * math.pi * 2600.0 * t) * env
        samples.append(click)
    return samples


def gen_calm_music(duration: float = 16.0) -> list:
    total_frames = int(SAMPLE_RATE * duration)
    out = [0.0] * (total_frames * 2)
    
    # Frequencies in Hz for warm, dreamy lo-fi chords
    freqs = {
        "F1": 43.65, "G1": 49.00, "A1": 55.00, "B1": 61.74,
        "C2": 65.41, "D2": 73.42, "E2": 82.41, "F2": 87.31, "G2": 98.00, "A2": 110.00, "B2": 123.47,
        "C3": 130.81, "D3": 146.83, "E3": 164.81, "F3": 174.61, "G3": 196.00, "A3": 220.00, "B3": 246.94,
        "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00, "A4": 440.00, "B4": 493.88,
        "C5": 523.25, "D5": 587.33, "E5": 659.25, "G5": 783.99, "A5": 880.00, "B5": 987.77,
    }

    # Warm Lo-Fi electric piano chords (Cmaj9 -> Am9 -> Fmaj7 -> G13)
    epiano_events = [
        # Bar 1: Cmaj9 (0.0s - 4.0s)
        (0.0, "C3", -0.15, 3.8),
        (0.04, "G3", 0.10, 3.7),
        (0.08, "B3", -0.08, 3.6),
        (0.12, "D4", 0.14, 3.5),
        (0.16, "E4", 0.0, 3.4),
        (1.5, "G3", -0.10, 2.0),
        (2.0, "D4", 0.12, 1.8),
        (2.8, "B3", -0.06, 1.2),
        
        # Bar 2: Am9 (4.0s - 8.0s)
        (4.0, "A2", -0.15, 3.8),
        (4.04, "E3", 0.10, 3.7),
        (4.08, "G3", -0.08, 3.6),
        (4.12, "B3", 0.14, 3.5),
        (4.16, "C4", 0.0, 3.4),
        (5.5, "E3", -0.10, 2.0),
        (6.0, "C4", 0.12, 1.8),
        (6.8, "G3", -0.06, 1.2),
        
        # Bar 3: Fmaj7 (8.0s - 12.0s)
        (8.0, "F2", -0.15, 3.8),
        (8.04, "C3", 0.10, 3.7),
        (8.08, "E3", -0.08, 3.6),
        (8.12, "G3", 0.14, 3.5),
        (8.16, "A3", 0.0, 3.4),
        (9.5, "C3", -0.10, 2.0),
        (10.0, "G3", 0.12, 1.8),
        (10.8, "E3", -0.06, 1.2),
        
        # Bar 4: G13 / Gsus (12.0s - 16.0s)
        (12.0, "G2", -0.15, 3.8),
        (12.04, "D3", 0.10, 3.7),
        (12.08, "F3", -0.08, 3.6),
        (12.12, "A3", 0.14, 3.5),
        (12.16, "B3", 0.0, 3.4),
        (13.5, "D3", -0.10, 2.0),
        (14.0, "A3", 0.12, 1.8),
        (14.8, "F3", -0.06, 1.2),
    ]

    # Warm lo-fi Rhodes rendering
    for start_t, n_name, pan, note_dur in epiano_events:
        freq = freqs[n_name]
        start_frame = int(start_t * SAMPLE_RATE)
        event_frames = int(note_dur * SAMPLE_RATE)
        pan_l = 0.5 * (1.0 - pan)
        pan_r = 0.5 * (1.0 + pan)
        
        for k in range(event_frames):
            idx = (start_frame + k) % total_frames
            t_note = k / SAMPLE_RATE
            att = min(1.0, t_note / 0.025)
            decay = math.exp(-t_note / (note_dur * 0.52))
            env = att * decay
            
            # Warm detuned dual-harmonic tone (Rhodes chill vibe)
            w1 = 2.0 * math.pi * (freq * 0.9995) * t_note
            w2 = 2.0 * math.pi * (freq * 1.0005) * t_note
            tone = (math.sin(w1) + math.sin(w2)) * 0.5 + 0.18 * math.sin(2.0 * w1) + 0.04 * math.sin(3.0 * w1)
            val = tone * env * 0.28
            out[idx * 2] += val * pan_l
            out[idx * 2 + 1] += val * pan_r

    # Cozy sub-bass foundation
    sub_bass = [
        (0.0, "C2", 3.8),
        (4.0, "A1", 3.8),
        (8.0, "F1", 3.8),
        (12.0, "G1", 3.8),
    ]
    for start_t, n_name, b_dur in sub_bass:
        freq = freqs[n_name]
        start_frame = int(start_t * SAMPLE_RATE)
        event_frames = int(b_dur * SAMPLE_RATE)
        for k in range(event_frames):
            idx = (start_frame + k) % total_frames
            t_note = k / SAMPLE_RATE
            att = min(1.0, t_note / 0.03)
            decay = math.exp(-t_note / (b_dur * 0.65))
            w = 2.0 * math.pi * freq * t_note
            val = (math.sin(w) + 0.10 * math.sin(2.0 * w)) * att * decay * 0.22
            out[idx * 2] += val * 0.5
            out[idx * 2 + 1] += val * 0.5

    # Gentle, soothing celeste / bell drops over the chords
    melody_events = [
        (0.6, "G4", 0.18, 1.8),
        (1.8, "E4", -0.12, 1.5),
        (2.6, "D4", 0.10, 1.2),
        (4.6, "B4", 0.16, 1.8),
        (5.8, "G4", -0.14, 1.5),
        (6.6, "E4", 0.12, 1.2),
        (8.6, "A4", 0.15, 1.8),
        (9.8, "E4", -0.10, 1.5),
        (10.6, "C4", 0.12, 1.2),
        (12.6, "D4", 0.14, 1.8),
        (13.8, "B3", -0.12, 1.5),
        (14.6, "D4", 0.08, 1.2),
    ]
    for start_t, n_name, pan, m_dur in melody_events:
        freq = freqs[n_name]
        start_frame = int(start_t * SAMPLE_RATE)
        event_frames = int(m_dur * SAMPLE_RATE)
        pan_l = 0.5 * (1.0 - pan)
        pan_r = 0.5 * (1.0 + pan)
        for k in range(event_frames):
            idx = (start_frame + k) % total_frames
            t_note = k / SAMPLE_RATE
            att = min(1.0, t_note / 0.012)
            decay = math.exp(-t_note / (m_dur * 0.42))
            w = 2.0 * math.pi * freq * t_note
            # Pure soothing chime tone
            val = (math.sin(w) + 0.08 * math.sin(3.0 * w)) * att * decay * 0.14
            out[idx * 2] += val * pan_l
            out[idx * 2 + 1] += val * pan_r

    # Clean, artifact-free seamless loop crossfade (1.2s)
    xfade_len = int(SAMPLE_RATE * 1.2)
    for i in range(xfade_len):
        w = i / float(xfade_len)
        head_l = i * 2
        head_r = i * 2 + 1
        tail_l = (total_frames - xfade_len + i) * 2
        tail_r = (total_frames - xfade_len + i) * 2 + 1
        
        blended_l = out[head_l] * w + out[tail_l] * (1.0 - w)
        blended_r = out[head_r] * w + out[tail_r] * (1.0 - w)
        out[head_l] = blended_l
        out[tail_l] = blended_l
        out[head_r] = blended_r
        out[tail_r] = blended_r
        
    return out


def main():
    target_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")
    os.makedirs(target_dir, exist_ok=True)
    
    write_wav(os.path.join(target_dir, "snow_step.wav"), gen_snow_step(0.16), channels=1, target_peak=0.035)
    write_wav(os.path.join(target_dir, "jump.wav"), gen_jump(0.22), channels=1, target_peak=0.15)
    write_wav(os.path.join(target_dir, "land.wav"), gen_land(0.18), channels=1, target_peak=0.14)
    write_wav(os.path.join(target_dir, "ice_crack.wav"), gen_ice_crack(0.32), channels=1, target_peak=0.16)
    write_wav(os.path.join(target_dir, "pickup.wav"), gen_pickup(0.30), channels=1, target_peak=0.15)
    write_wav(os.path.join(target_dir, "sort_ok.wav"), gen_sort_ok(0.35), channels=1, target_peak=0.15)
    write_wav(os.path.join(target_dir, "sort_bad.wav"), gen_sort_bad(0.35), channels=1, target_peak=0.14)
    write_wav(os.path.join(target_dir, "ui_click.wav"), gen_ui_click(0.04), channels=1, target_peak=0.12)
    write_wav(os.path.join(target_dir, "calm_music.wav"), gen_calm_music(16.0), channels=2, target_peak=0.28)
    print("All audio assets successfully synthesized.")
    print("All audio assets successfully synthesized.")


if __name__ == "__main__":
    main()
