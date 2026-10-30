#!/usr/bin/env python3
"""
tools/generate_sfx.py
High-fidelity DSP sound generator for Echoes in the Ore.
Generates gritty industrial sci-fi & cosmic horror SFX using pure Python standard library.
Output format: 44100 Hz, 16-bit PCM WAV.
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100
SFX_DIR = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx")


def clamp(val, low=-1.0, high=1.0):
    return max(low, min(high, val))


def soft_clip(val, drive=1.5):
    """Soft saturation curve for gritty, analog overdrive."""
    x = val * drive
    return math.tanh(x)


def write_wav(filename: str, samples: list[float], sample_rate: int = SAMPLE_RATE):
    os.makedirs(SFX_DIR, exist_ok=True)
    filepath = os.path.join(SFX_DIR, filename)

    # Peak normalization to -0.5 dB
    max_amp = max(abs(s) for s in samples) if samples else 0.0
    target_peak = 0.944  # approx -0.5 dB
    norm_factor = (target_peak / max_amp) if max_amp > 1e-4 else 1.0

    raw_data = bytearray()
    for s in samples:
        norm_s = clamp(s * norm_factor)
        sample_int = int(norm_s * 32767.0)
        raw_data.extend(struct.pack("<h", sample_int))

    with wave.open(filepath, "wb") as wf:
        wf.setnchannels(1)  # Mono
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(sample_rate)
        wf.writeframes(raw_data)

    print(f"  [+] Generated {filename} ({len(samples)} samples, {len(samples)/sample_rate:.2f}s)")


# ==============================================================================
# HORROR & RESONANCE ORE SFX
# ==============================================================================

def gen_tank_crack():
    """Crystalline stress fracture with high-tensile metallic snap & low strain."""
    duration = 0.45
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4001)

    # 3 sharp fracture snaps
    cracks = [0.0, 0.08, 0.22]
    for c_start in cracks:
        s_idx = int(c_start * SAMPLE_RATE)
        for i in range(s_idx, n_samples):
            t = (i - s_idx) / SAMPLE_RATE
            env = math.exp(-35.0 * t)
            # High resonant crystalline chime + ping
            ping1 = math.sin(2.0 * math.pi * 3200.0 * t) * 0.4
            ping2 = math.sin(2.0 * math.pi * 5800.0 * t) * 0.3
            noise = rng.uniform(-1.0, 1.0) * math.exp(-70.0 * t) * 0.5
            samples[i] += (ping1 + ping2 + noise) * env

    # Low frequency structural strain creak
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        groan = math.sin(2.0 * math.pi * (45.0 + 10.0 * math.sin(2.0 * math.pi * 8.0 * t)) * t) * 0.25 * math.exp(-4.0 * t)
        samples[i] = soft_clip(samples[i] + groan, 1.2)

    write_wav("tank_crack.wav", samples)


def gen_tank_rupture():
    """Catastrophic containment breach: shattering glass, explosive gas decompression, sub-bass blast."""
    duration = 1.35
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4002)

    lp = 0.0
    for i in range(n_samples):
        t = i / SAMPLE_RATE

        # Sub-bass seismic rupture drop (110 Hz down to 28 Hz)
        sub_freq = 110.0 * math.exp(-6.0 * t) + 28.0
        sub_env = math.exp(-3.2 * t)
        sub = math.sin(2.0 * math.pi * sub_freq * t) * 0.75 * sub_env

        # Violent shattered fragments (burst of randomized metallic pings)
        shatter_env = math.exp(-12.0 * t)
        raw_noise = rng.uniform(-1.0, 1.0)
        lp = lp * 0.4 + raw_noise * 0.6
        shatter = lp * shatter_env * 0.65

        # Crystalline ringing harmonics
        ring = (math.sin(2.0 * math.pi * 1480.0 * t) * 0.3 + math.sin(2.0 * math.pi * 2240.0 * t) * 0.2) * math.exp(-5.0 * t)

        # High-pressure gas decompression surge
        gas_env = (1.0 - math.exp(-15.0 * t)) * math.exp(-3.5 * t)
        gas = rng.uniform(-0.5, 0.5) * gas_env * 0.55

        combined = sub + shatter + ring + gas
        samples[i] = soft_clip(combined, 1.4)

    write_wav("tank_rupture.wav", samples)


def gen_villain_emerge():
    """Terrifying eldritch emergence: guttural sub-vocal growl mutating into a visceral screech."""
    duration = 1.10
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4003)

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * min(1.0, t / duration))

        # Modulated FM growl
        fm_mod = math.sin(2.0 * math.pi * 42.0 * t) * 95.0
        carrier = math.sin(2.0 * math.pi * (130.0 + fm_mod) * t) * 0.55

        # High resonant alien screech that rises then breaks
        screech_freq = 600.0 + 800.0 * (t / duration) + math.sin(2.0 * math.pi * 65.0 * t) * 120.0
        screech = math.sin(2.0 * math.pi * screech_freq * t) * 0.35

        # Visceral wet rasp / breathing noise
        wet_noise = rng.uniform(-0.4, 0.4) * (0.5 + 0.5 * math.sin(2.0 * math.pi * 18.0 * t))

        combined = (carrier + screech + wet_noise) * env
        samples[i] = soft_clip(combined, 1.6)

    write_wav("villain_emerge.wav", samples)


def gen_villain_attack():
    """Sudden aggressive ambush pounce: roaring lunge, displaced air, savage claw strike."""
    duration = 0.65
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4004)

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-4.5 * t)

        # Heavy downward pitch dive (predatory roar)
        dive_freq = 380.0 * math.exp(-8.0 * t) + 75.0
        roar = math.sin(2.0 * math.pi * dive_freq * t) * 0.65

        # Harsh claw tearing impact noise
        claw = rng.uniform(-0.8, 0.8) * math.exp(-14.0 * t) * 0.6

        # Sub-bass impact thud on landing
        thud = math.sin(2.0 * math.pi * 55.0 * t) * math.exp(-9.0 * t) * 0.7

        samples[i] = soft_clip((roar + claw + thud) * env, 1.5)

    write_wav("villain_attack.wav", samples)


def gen_villain_hurt():
    """Agonized alien shriek when hit by gunfire or plasma: high dissonant frequency dive."""
    duration = 0.55
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4005)

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-6.5 * t)

        # Dissonant dual pitch dive
        freq1 = 1450.0 * math.exp(-12.0 * t) + 240.0
        freq2 = 1890.0 * math.exp(-10.0 * t) + 310.0
        scream = (math.sin(2.0 * math.pi * freq1 * t) * 0.45 + math.sin(2.0 * math.pi * freq2 * t) * 0.4)

        # Boiling sizzle (plasma burn on carapace)
        sizzle = rng.uniform(-0.5, 0.5) * math.exp(-8.0 * t) * 0.45

        samples[i] = soft_clip((scream + sizzle) * env, 1.4)

    write_wav("villain_hurt.wav", samples)


def gen_villain_duct():
    """Distant unsettling clatter: metallic claws scraping and crawling through hollow sheet-metal vents."""
    duration = 0.75
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4006)

    # Scrapes at distinct time stamps
    scrapes = [0.0, 0.18, 0.38, 0.52]
    for s_start in scrapes:
        s_idx = int(s_start * SAMPLE_RATE)
        freq = rng.uniform(160.0, 240.0)
        for i in range(s_idx, n_samples):
            t = (i - s_idx) / SAMPLE_RATE
            env = math.exp(-18.0 * t)
            # Metallic sheet vibration
            hollow = math.sin(2.0 * math.pi * freq * t) * 0.4
            scrape = rng.uniform(-0.5, 0.5) * math.exp(-32.0 * t) * 0.5
            samples[i] += (hollow + scrape) * env * 0.45

    write_wav("villain_duct.wav", samples)


# ==============================================================================
# WEAPONS & EQUIPMENT SFX
# ==============================================================================

def gen_revolver_shot():
    """Deafening hand cannon punch: sub-bass recoil blast, gunpowder crack, mechanical hammer rebound."""
    duration = 0.55
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4007)

    lp = 0.0
    for i in range(n_samples):
        t = i / SAMPLE_RATE

        # Massive initial supersonic crack (first 25ms)
        crack_env = math.exp(-75.0 * t)
        noise = rng.uniform(-1.0, 1.0)
        lp = lp * 0.3 + noise * 0.7
        crack = lp * crack_env * 0.9

        # Sub-bass concussion wave (140 Hz diving to 35 Hz)
        sub_freq = 140.0 * math.exp(-22.0 * t) + 35.0
        sub = math.sin(2.0 * math.pi * sub_freq * t) * math.exp(-7.5 * t) * 0.85

        # Metallic chamber ring
        ring = math.sin(2.0 * math.pi * 640.0 * t) * math.exp(-14.0 * t) * 0.25

        samples[i] = soft_clip(crack + sub + ring, 1.5)

    write_wav("revolver_shot.wav", samples)


def gen_dry_fire():
    """Heavy steel hammer striking an empty firing pin: sharp double mechanical click."""
    duration = 0.12
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    # Firing pin strike
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env1 = math.exp(-85.0 * t)
        click1 = math.sin(2.0 * math.pi * 1850.0 * t) * 0.6 + math.sin(2.0 * math.pi * 780.0 * t) * 0.4
        rebound = 0.0
        if t > 0.025:
            tr = t - 0.025
            rebound = math.sin(2.0 * math.pi * 1150.0 * tr) * math.exp(-95.0 * tr) * 0.4
        samples[i] = (click1 * env1 + rebound) * 0.65

    write_wav("dry_fire.wav", samples)


def gen_plasma_pulse():
    """High-voltage ionized beam: searing electric hum, crackle, thermal sizzle."""
    duration = 0.28
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4008)

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * min(1.0, t / duration))

        # Modulated arc hum
        mod = math.sin(2.0 * math.pi * 360.0 * t) * 80.0
        carrier = math.sin(2.0 * math.pi * (180.0 + mod) * t) * 0.55

        # Electrical sizzle
        spark = rng.uniform(-0.5, 0.5) * 0.4

        samples[i] = soft_clip((carrier + spark) * env, 1.4)

    write_wav("plasma_pulse.wav", samples)


def gen_flare_launch():
    """Pneumatic flare pistol launch: pressurized gas 'thump-whoosh' and ignition."""
    duration = 0.42
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4009)

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * min(1.0, t / duration))

        # Upward whoosh frequency sweep
        sweep = 90.0 + 380.0 * (t / duration)
        tone = math.sin(2.0 * math.pi * sweep * t) * 0.45

        # Gas hiss
        hiss = rng.uniform(-0.5, 0.5) * 0.45

        # Initial launch thud
        thud = math.sin(2.0 * math.pi * 75.0 * t) * math.exp(-25.0 * t) * 0.6

        samples[i] = (tone + hiss) * env * 0.65 + thud

    write_wav("flare_launch.wav", samples)


def gen_flare_burn():
    """Roaring magnesium pyrotechnic flare burning brightly."""
    duration = 0.85
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4010)

    lp = 0.0
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        noise = rng.uniform(-1.0, 1.0)
        lp = lp * 0.6 + noise * 0.4

        # Modulating flame rumble
        flame_mod = 1.0 + 0.3 * math.sin(2.0 * math.pi * 9.5 * t) + 0.15 * math.sin(2.0 * math.pi * 23.0 * t)
        sub_rumble = math.sin(2.0 * math.pi * 65.0 * t) * 0.35

        samples[i] = (lp * 0.5 + sub_rumble) * flame_mod * 0.6

    write_wav("flare_burn.wav", samples)


def gen_scanner_ping():
    """Deep space radar/sonar ping: crystalline sweep with hollow echoing ring."""
    duration = 0.65
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-6.5 * t)

        # Primary dual sonar harmonic
        ping = math.sin(2.0 * math.pi * 1280.0 * t) * 0.6 + math.sin(2.0 * math.pi * 2560.0 * t) * 0.25

        # Echo response delayed by 180ms
        echo = 0.0
        if t > 0.18:
            te = t - 0.18
            echo = math.sin(2.0 * math.pi * 960.0 * te) * math.exp(-12.0 * te) * 0.35

        samples[i] = (ping * env + echo) * 0.65

    write_wav("scanner_ping.wav", samples)


def gen_beacon_deploy():
    """Deployable nav beacon: heavy magnetic clamp clunk and electronic arming beep."""
    duration = 0.38
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE

        # Metallic magnetic clamp thunk
        clamp_env = math.exp(-24.0 * t)
        clamp_tone = math.sin(2.0 * math.pi * 110.0 * t) * 0.7 + math.sin(2.0 * math.pi * 480.0 * t) * 0.35
        clamp_s = clamp_tone * clamp_env

        # Arming confirmation chirp
        chirp = 0.0
        if t > 0.14:
            tc = t - 0.14
            chirp_freq = 880.0 + 440.0 * (tc / 0.15)
            chirp = math.sin(2.0 * math.pi * chirp_freq * tc) * math.exp(-15.0 * tc) * 0.5

        samples[i] = clamp_s * 0.7 + chirp * 0.5

    write_wav("beacon_deploy.wav", samples)


def gen_beacon_pulse():
    """Repeating electronic locator pulse."""
    duration = 0.24
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-12.0 * t)
        p = math.sin(2.0 * math.pi * 620.0 * t) * 0.6 + math.sin(2.0 * math.pi * 1240.0 * t) * 0.35
        samples[i] = p * env * 0.5

    write_wav("beacon_pulse.wav", samples)


def gen_med_inject():
    """Pneumatic auto-injector: air hiss, sharp needle actuation, vital signs confirmation chime."""
    duration = 0.52
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4011)

    for i in range(n_samples):
        t = i / SAMPLE_RATE

        # Pneumatic hiss (first 160ms)
        hiss = 0.0
        if t < 0.16:
            hiss = rng.uniform(-0.6, 0.6) * math.exp(-12.0 * t) * 0.6

        # Plunger click
        click = 0.0
        if 0.08 <= t <= 0.12:
            tc = t - 0.08
            click = math.sin(2.0 * math.pi * 2100.0 * tc) * math.exp(-70.0 * tc) * 0.5

        # Gentle medical confirmation chime
        chime = 0.0
        if t >= 0.14:
            tch = t - 0.14
            chime = (math.sin(2.0 * math.pi * 784.0 * tch) * 0.45 + math.sin(2.0 * math.pi * 1174.66 * tch) * 0.35) * math.exp(-8.0 * tch)

        samples[i] = hiss + click + chime * 0.6

    write_wav("med_inject.wav", samples)


def gen_sealant_spray():
    """Pressurized chemical sealant foam aerosol can discharge."""
    duration = 0.28
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4012)

    lp = 0.0
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * min(1.0, t / duration))
        noise = rng.uniform(-1.0, 1.0)
        lp = lp * 0.5 + noise * 0.5
        samples[i] = lp * env * 0.5

    write_wav("sealant_spray.wav", samples)


def gen_flashlight_click():
    """Heavy industrial rotary/toggle flashlight switch."""
    duration = 0.08
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-65.0 * t)
        snap = math.sin(2.0 * math.pi * 2400.0 * t) * 0.55 + math.sin(2.0 * math.pi * 820.0 * t) * 0.45
        samples[i] = snap * env * 0.6

    write_wav("flashlight_click.wav", samples)


def gen_item_equip():
    """Tactile tactical holster snap / strap adjustment."""
    duration = 0.12
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-42.0 * t)
        snap = math.sin(2.0 * math.pi * 920.0 * t) * 0.55 + math.sin(2.0 * math.pi * 1580.0 * t) * 0.35
        samples[i] = snap * env * 0.5

    write_wav("item_equip.wav", samples)


# ==============================================================================
# SHIP ENVIRONMENT & MACHINERY SFX
# ==============================================================================

def gen_door_close():
    """Heavy airtight bulkhead door: hydraulic glide followed by massive locking bolt thunk."""
    duration = 0.52
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE

        # Hydraulic motor glide (0.0 to 0.35s)
        motor = 0.0
        if t < 0.38:
            freq = 140.0 - 80.0 * (t / 0.38)
            motor = math.sin(2.0 * math.pi * freq * t) * 0.45 * (1.0 - t / 0.38)

        # Heavy steel door slam and bolt lock
        thunk = 0.0
        if t >= 0.32:
            tt = t - 0.32
            thunk_env = math.exp(-22.0 * tt)
            sub_thud = math.sin(2.0 * math.pi * 68.0 * tt) * 0.75
            metal_ring = math.sin(2.0 * math.pi * 420.0 * tt) * 0.35
            thunk = (sub_thud + metal_ring) * thunk_env

        samples[i] = soft_clip(motor * 0.6 + thunk, 1.3)

    write_wav("door_close.wav", samples)


def gen_door_open():
    """Heavy airtight bulkhead door opening: seal hiss and pneumatic release."""
    duration = 0.48
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4013)

    for i in range(n_samples):
        t = i / SAMPLE_RATE

        # Initial seal break hiss
        hiss = rng.uniform(-0.5, 0.5) * math.exp(-18.0 * t) * 0.55

        # Motor slide up
        motor_env = math.sin(math.pi * min(1.0, t / duration))
        freq = 60.0 + 90.0 * (t / duration)
        motor = math.sin(2.0 * math.pi * freq * t) * 0.4 * motor_env

        samples[i] = (hiss + motor) * 0.65

    write_wav("door_open.wav", samples)


def gen_airlock_cycle():
    """Airlock chamber equalization: rushing atmospheric purge, compressor whine, pressure vents."""
    duration = 1.15
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4014)

    lp = 0.0
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * min(1.0, t / duration))

        noise = rng.uniform(-1.0, 1.0)
        lp = lp * 0.45 + noise * 0.55

        # Deep sub-frequency chamber resonance
        sub = math.sin(2.0 * math.pi * 48.0 * t) * 0.45

        # High pressure vent hiss
        vent = lp * 0.6

        samples[i] = soft_clip((sub + vent) * env, 1.3)

    write_wav("airlock_cycle.wav", samples)


def gen_lift_move():
    """Subdeck cargo lift in motion: heavy motor hum and rumbling gear teeth."""
    duration = 0.95
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * min(1.0, t / duration))

        hum1 = math.sin(2.0 * math.pi * 78.0 * t) * 0.55
        hum2 = math.sin(2.0 * math.pi * 156.0 * t) * 0.3
        hum3 = math.sin(2.0 * math.pi * 234.0 * t) * 0.15

        samples[i] = (hum1 + hum2 + hum3) * env * 0.6

    write_wav("lift_move.wav", samples)


def gen_lift_arrive():
    """Subdeck cargo lift docking: pneumatic brake release and heavy platform impact."""
    duration = 0.45
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4015)

    for i in range(n_samples):
        t = i / SAMPLE_RATE

        # Impact thunk
        thud = math.sin(2.0 * math.pi * 58.0 * t) * math.exp(-14.0 * t) * 0.75

        # Brake pneumatic air release
        air = rng.uniform(-0.5, 0.5) * math.exp(-16.0 * t) * 0.4

        # Arrival chime
        chime = math.sin(2.0 * math.pi * 880.0 * t) * math.exp(-8.0 * t) * 0.35

        samples[i] = (thud + air + chime) * 0.65

    write_wav("lift_arrive.wav", samples)


def gen_welding_spark():
    """High-voltage arc welding: intense electrical hum and scattering molten sparks."""
    duration = 0.25
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4016)

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * min(1.0, t / duration))

        # 60Hz AC line buzz harmonics
        buzz = (math.sin(2.0 * math.pi * 60.0 * t) * 0.5 + math.sin(2.0 * math.pi * 120.0 * t) * 0.3)

        # Crackling arc sparks
        crackle = rng.uniform(-0.6, 0.6) * 0.5

        samples[i] = soft_clip((buzz + crackle) * env, 1.4)

    write_wav("welding_spark.wav", samples)


def gen_steam_burst():
    """Violent steam pipe pressure vent burst."""
    duration = 0.45
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4017)

    lp = 0.0
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-6.0 * t)
        noise = rng.uniform(-1.0, 1.0)
        lp = lp * 0.35 + noise * 0.65
        samples[i] = lp * env * 0.65

    write_wav("steam_burst.wav", samples)


# ==============================================================================
# ENGINEERING MINIGAMES & STATIONS
# ==============================================================================

def gen_capacitor_tune():
    """Capacitor frequency tuning: smooth oscillating inductive pitch sweep."""
    duration = 0.32
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * min(1.0, t / duration))
        freq = 320.0 + 240.0 * math.sin(2.0 * math.pi * 4.0 * t)
        tone = math.sin(2.0 * math.pi * freq * t) * 0.55 + math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.25
        samples[i] = tone * env * 0.55

    write_wav("capacitor_tune.wav", samples)


def gen_bus_sync():
    """Power bus synchronization: massive high-voltage arc surge and harmonic alignment blast."""
    duration = 0.75
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-4.5 * t)

        # Huge sub-bass energy blast
        sub = math.sin(2.0 * math.pi * 65.0 * t) * 0.8 * env

        # Harmonic power chord
        chord = (math.sin(2.0 * math.pi * 220.0 * t) * 0.4 +
                 math.sin(2.0 * math.pi * 330.0 * t) * 0.3 +
                 math.sin(2.0 * math.pi * 440.0 * t) * 0.25) * env

        samples[i] = soft_clip(sub + chord, 1.35)

    write_wav("bus_sync.wav", samples)


def gen_latch_release():
    """Heavy mechanical spring-loaded dog latch release clack."""
    duration = 0.16
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-55.0 * t)
        snap = math.sin(2.0 * math.pi * 750.0 * t) * 0.6 + math.sin(2.0 * math.pi * 1850.0 * t) * 0.4
        samples[i] = snap * env * 0.65

    write_wav("latch_release.wav", samples)


def gen_cartridge_seat():
    """Heavy life-support filter cartridge seating & locking chunk."""
    duration = 0.28
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Slide followed by heavy lock
        slide = math.sin(2.0 * math.pi * 280.0 * t) * math.exp(-18.0 * t) * 0.35
        chunk = 0.0
        if t > 0.08:
            tc = t - 0.08
            chunk = (math.sin(2.0 * math.pi * 85.0 * tc) * 0.75 + math.sin(2.0 * math.pi * 440.0 * tc) * 0.4) * math.exp(-24.0 * tc)
        samples[i] = (slide + chunk) * 0.7

    write_wav("cartridge_seat.wav", samples)


def gen_mining_drill():
    """Diamond rotary mining drill chewing into dense asteroid ore."""
    duration = 0.55
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4018)

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * min(1.0, t / duration))

        # Motor rotary rumble
        motor = math.sin(2.0 * math.pi * 84.0 * t) * 0.55

        # Ore fracture grinding crunch
        grind = rng.uniform(-0.6, 0.6) * 0.45

        samples[i] = soft_clip((motor + grind) * env, 1.4)

    write_wav("mining_drill.wav", samples)


def gen_laser_cannon():
    """Heavy ship point-defense mining laser cannon discharge."""
    duration = 0.32
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-12.0 * t)
        freq = 1600.0 * math.exp(-25.0 * t) + 120.0
        laser = math.sin(2.0 * math.pi * freq * t) * 0.75
        samples[i] = soft_clip(laser * env, 1.3)

    write_wav("laser_cannon.wav", samples)


def gen_coolant_flush():
    """High-speed cryogenic coolant purge through ship manifolds."""
    duration = 0.65
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4019)

    lp = 0.0
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * min(1.0, t / duration))
        noise = rng.uniform(-1.0, 1.0)
        lp = lp * 0.6 + noise * 0.4
        samples[i] = lp * env * 0.55

    write_wav("coolant_flush.wav", samples)


# ==============================================================================
# TACTILE UI & CREW INTERFACE
# ==============================================================================

def gen_terminal_open():
    """CRT terminal initialization: degauss thud, high-voltage flyback whistle, phosphor chirp."""
    duration = 0.22
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE

        # Flyback transformer whistle (15.7 kHz simulated down to crisp 2.8kHz chirp)
        freq = 420.0 + 1800.0 * (t / duration)
        whistle = math.sin(2.0 * math.pi * freq * t) * math.exp(-12.0 * t) * 0.45

        # Degauss sub-thud
        thud = math.sin(2.0 * math.pi * 60.0 * t) * math.exp(-25.0 * t) * 0.5

        samples[i] = (whistle + thud) * 0.6

    write_wav("terminal_open.wav", samples)


def gen_button_click():
    """Tactile heavy mechanical switch actuation."""
    duration = 0.06
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-85.0 * t)
        click = math.sin(2.0 * math.pi * 720.0 * t) * 0.65 + math.sin(2.0 * math.pi * 1440.0 * t) * 0.35
        samples[i] = click * env * 0.6

    write_wav("button_click.wav", samples)


def gen_button_hover():
    """Subtle high-tech HUD element hover chirp."""
    duration = 0.035
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-75.0 * t)
        samples[i] = math.sin(2.0 * math.pi * 1150.0 * t) * env * 0.35

    write_wav("button_hover.wav", samples)


def gen_switch_toggle():
    """Chunky metallic toggle switch flip."""
    duration = 0.055
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-80.0 * t)
        snap = math.sin(2.0 * math.pi * 980.0 * t) * 0.6 + math.sin(2.0 * math.pi * 2100.0 * t) * 0.4
        samples[i] = snap * env * 0.5

    write_wav("switch_toggle.wav", samples)


def gen_slider_tick():
    """Fine potentiometer detent notch click."""
    duration = 0.03
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-110.0 * t)
        samples[i] = math.sin(2.0 * math.pi * 1420.0 * t) * env * 0.4

    write_wav("slider_tick.wav", samples)


def gen_access_denied():
    """Harsh retro-industrial double-buzz error klaxon."""
    duration = 0.28
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Pulse 1 (0 to 0.1s), Pulse 2 (0.14 to 0.24s)
        active = (t < 0.10) or (0.14 <= t < 0.24)
        if active:
            # Low harsh square/saw buzz (115 Hz)
            val = 0.6 if math.sin(2.0 * math.pi * 115.0 * t) > 0.0 else -0.6
            samples[i] = val * 0.6

    write_wav("access_denied.wav", samples)


def gen_task_complete():
    """Satisfying multi-tone retro-industrial confirmation chime."""
    duration = 0.65
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    notes = [440.0, 554.37, 659.25, 880.0]  # A major arpeggio
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        s = 0.0
        for idx, freq in enumerate(notes):
            start_t = idx * 0.09
            if t >= start_t:
                lt = t - start_t
                env = math.exp(-7.0 * lt)
                s += math.sin(2.0 * math.pi * freq * lt) * env * 0.35
        samples[i] = s * 0.65

    write_wav("task_complete.wav", samples)


def gen_radio_squelch():
    """Tactical comlink radio burst & filter cutoff."""
    duration = 0.11
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples
    rng = random.Random(4020)

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-28.0 * t)
        noise = rng.uniform(-0.6, 0.6) * 0.5
        carrier = math.sin(2.0 * math.pi * 920.0 * t) * 0.35
        samples[i] = (noise + carrier) * env * 0.55

    write_wav("radio_squelch.wav", samples)


def gen_unlock_chime():
    """Clear pristine acoustic chime on system/door unlock."""
    duration = 0.55
    n_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * n_samples

    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-7.5 * t)
        n1 = math.sin(2.0 * math.pi * 659.25 * t) * 0.4
        n2 = math.sin(2.0 * math.pi * 987.77 * t) * 0.35
        n3 = math.sin(2.0 * math.pi * 1318.51 * t) * 0.25 * math.exp(-12.0 * t)
        samples[i] = (n1 + n2 + n3) * env * 0.6

    write_wav("unlock_chime.wav", samples)


def main():
    print(f"[*] Generating Gritty Industrial Sci-Fi & Cosmic Horror SFX library into {SFX_DIR}...")

    # Horror & Ore
    gen_tank_crack()
    gen_tank_rupture()
    gen_villain_emerge()
    gen_villain_attack()
    gen_villain_hurt()
    gen_villain_duct()

    # Weapons & Gear
    gen_revolver_shot()
    gen_dry_fire()
    gen_plasma_pulse()
    gen_flare_launch()
    gen_flare_burn()
    gen_scanner_ping()
    gen_beacon_deploy()
    gen_beacon_pulse()
    gen_med_inject()
    gen_sealant_spray()
    gen_flashlight_click()
    gen_item_equip()

    # Ship Environment & Machinery
    gen_door_close()
    gen_door_open()
    gen_airlock_cycle()
    gen_lift_move()
    gen_lift_arrive()
    gen_welding_spark()
    gen_steam_burst()

    # Engineering Minigames
    gen_capacitor_tune()
    gen_bus_sync()
    gen_latch_release()
    gen_cartridge_seat()
    gen_mining_drill()
    gen_laser_cannon()
    gen_coolant_flush()

    # UI & Interface
    gen_terminal_open()
    gen_button_click()
    gen_button_hover()
    gen_switch_toggle()
    gen_slider_tick()
    gen_access_denied()
    gen_task_complete()
    gen_radio_squelch()
    gen_unlock_chime()

    print("[*] Sound generation complete. All WAV files ready.")


if __name__ == "__main__":
    main()
