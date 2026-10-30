class_name DialogueAudioSynth
extends RefCounted

## Procedural retro-futuristic sound synthesis for dialogue, voice blips, weapons, tools, ship systems, and UI feedback.
## Zero external file dependencies; synthesized on-demand in pure GDScript.

static var _sfx_cache: Dictionary = {}


static func generate_tone(freq: float, duration: float, attack: float = 0.005, decay: float = 0.03, waveform: String = "sine", volume: float = 0.45) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := maxi(1, int(sample_rate * duration))
	var byte_array := PackedByteArray()
	byte_array.resize(total_samples * 2)
	
	var attack_samples := mini(total_samples / 2, int(sample_rate * attack))
	var decay_samples := mini(total_samples - attack_samples, int(sample_rate * decay))
	
	for i in range(total_samples):
		var env := 1.0
		if i < attack_samples:
			env = float(i) / maxf(1.0, float(attack_samples))
		elif i >= total_samples - decay_samples:
			env = float(total_samples - 1 - i) / maxf(1.0, float(decay_samples))
		
		var t := float(i) / float(sample_rate)
		var val := 0.0
		match waveform:
			"sine":
				val = sin(TAU * freq * t)
			"two_tone":
				val = 0.65 * sin(TAU * freq * t) + 0.35 * sin(TAU * freq * 1.5 * t)
			"octave":
				val = 0.6 * sin(TAU * freq * t) + 0.4 * sin(TAU * freq * 2.0 * t)
			"chirp":
				var cur_freq := lerpf(freq, freq * 1.6, float(i) / float(total_samples))
				val = sin(TAU * cur_freq * t)
			"down_chirp":
				var cur_freq := lerpf(freq, freq * 0.55, float(i) / float(total_samples))
				val = sin(TAU * cur_freq * t)
			"fm":
				var mod := sin(TAU * 40.0 * t) * 60.0
				val = sin(TAU * (freq + mod) * t)
			"saw":
				val = fposmod(freq * t, 1.0) * 2.0 - 1.0
			"square":
				val = 0.8 if sin(TAU * freq * t) >= 0.0 else -0.8
			_:
				val = sin(TAU * freq * t)
		
		val = clampf(val * env * volume, -1.0, 1.0)
		var sample_int := int(val * 32767.0)
		byte_array.encode_s16(i * 2, sample_int)
	
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav


static func _make_wav_from_samples(samples: PackedFloat32Array, sample_rate: int = 22050) -> AudioStreamWAV:
	var byte_array := PackedByteArray()
	byte_array.resize(samples.size() * 2)
	for i in range(samples.size()):
		var sample_int := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_int)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav


# --- CREW DIALOGUE BLIPS ---

static func create_speech_amara() -> AudioStreamWAV:
	return generate_tone(310.0, 0.042, 0.006, 0.028, "two_tone", 0.38)

static func create_speech_thura() -> AudioStreamWAV:
	return generate_tone(430.0, 0.038, 0.004, 0.025, "octave", 0.36)

static func create_speech_chen() -> AudioStreamWAV:
	return generate_tone(260.0, 0.040, 0.005, 0.026, "two_tone", 0.40)

static func create_speech_mateo() -> AudioStreamWAV:
	return generate_tone(210.0, 0.044, 0.006, 0.030, "octave", 0.42)

static func create_speech_ward() -> AudioStreamWAV:
	return generate_tone(360.0, 0.036, 0.004, 0.024, "sine", 0.35)

static func create_speech_leila() -> AudioStreamWAV:
	return generate_tone(390.0, 0.038, 0.004, 0.025, "chirp", 0.36)

static func create_speech_terminal() -> AudioStreamWAV:
	return generate_tone(580.0, 0.035, 0.003, 0.022, "fm", 0.32)


# --- CINEMATIC & UI SFX ---

static func create_open_cutscene() -> AudioStreamWAV:
	return generate_tone(340.0, 0.28, 0.03, 0.16, "chirp", 0.45)

static func create_close_cutscene() -> AudioStreamWAV:
	return generate_tone(480.0, 0.18, 0.015, 0.12, "down_chirp", 0.35)

static func create_button_hover() -> AudioStreamWAV:
	return generate_tone(940.0, 0.032, 0.002, 0.024, "sine", 0.22)

static func create_button_click() -> AudioStreamWAV:
	return generate_tone(520.0, 0.095, 0.004, 0.065, "octave", 0.48)

static func create_page_advance() -> AudioStreamWAV:
	return generate_tone(460.0, 0.045, 0.003, 0.032, "two_tone", 0.34)

static func create_switch_toggle() -> AudioStreamWAV:
	return generate_tone(840.0, 0.038, 0.002, 0.028, "octave", 0.36)

static func create_slider_tick() -> AudioStreamWAV:
	return generate_tone(1120.0, 0.022, 0.002, 0.016, "sine", 0.24)

static func create_terminal_open() -> AudioStreamWAV:
	return generate_tone(720.0, 0.14, 0.008, 0.08, "chirp", 0.38)

static func create_unlock_chime() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.45)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-7.5 * t)
		var note1 := sin(TAU * 659.25 * t) * 0.4
		var note2 := sin(TAU * 987.77 * t) * 0.35
		var note3 := sin(TAU * 1318.51 * t) * 0.25 * exp(-12.0 * t)
		samples[i] = (note1 + note2 + note3) * env * 0.55
	return _make_wav_from_samples(samples, sample_rate)

static func create_radio_squelch() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.09)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3344
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-24.0 * t)
		var noise := rng.randf_range(-0.5, 0.5)
		var tone := sin(TAU * 880.0 * t) * 0.3
		samples[i] = (noise + tone) * env * 0.4
	return _make_wav_from_samples(samples, sample_rate)


static func create_tremor_pulse() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.38)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4411
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-8.0 * t) * sin(PI * clampf(t / 0.38, 0.0, 1.0))
		var sub := sin(TAU * 48.0 * t) * 0.75
		var sub_harm := sin(TAU * 96.0 * t) * 0.35 * exp(-12.0 * t)
		var metallic := (rng.randf_range(-0.2, 0.2)) * exp(-28.0 * t)
		samples[i] = clampf((sub + sub_harm + metallic) * env * 0.85, -1.0, 1.0)
	return _make_wav_from_samples(samples, sample_rate)


static func create_landing_thud() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.55)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8821
	var hull_rumble := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-6.5 * t)
		var punch := sin(TAU * 55.0 * exp(-15.0 * t) * t) * 0.8
		var crunch := rng.randf_range(-0.6, 0.6) * exp(-25.0 * t)
		hull_rumble = lerpf(hull_rumble, rng.randf_range(-0.4, 0.4), 0.4)
		var resonance := sin(TAU * 110.0 * t) * 0.3 * exp(-8.0 * t)
		samples[i] = clampf((punch + crunch + hull_rumble * 0.5 + resonance) * env * 0.9, -1.0, 1.0)
	return _make_wav_from_samples(samples, sample_rate)


static func create_echo_mimic_whisper() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.45)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * clampf(t / 0.45, 0.0, 1.0))
		var fm := sin(TAU * 18.0 * t) * 45.0
		var tone := sin(TAU * (310.0 + fm) * t) * 0.4
		var drone := sin(TAU * 155.0 * t) * 0.35
		samples[i] = clampf((tone + drone) * env * 0.6, -1.0, 1.0)
	return _make_wav_from_samples(samples, sample_rate)



# --- WEAPONS & EQUIPMENT SFX ---

static func create_revolver_shot() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.38)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4589
	var filtered_noise := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-10.5 * t)
		var bass_freq := 160.0 * exp(-20.0 * t) + 38.0
		var bass := sin(TAU * bass_freq * t) * 0.75
		var raw_noise := rng.randf_range(-1.0, 1.0)
		filtered_noise = lerpf(filtered_noise, raw_noise, 0.6)
		var crack := filtered_noise * exp(-32.0 * t) * 0.9
		var metallic := sin(TAU * 480.0 * t) * 0.22 * exp(-18.0 * t)
		samples[i] = clampf((bass + crack + metallic) * env * 0.72, -1.0, 1.0)
	return _make_wav_from_samples(samples, sample_rate)

static func create_dry_fire() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.06)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-75.0 * t)
		var click := sin(TAU * 1680.0 * t) * 0.6 + sin(TAU * 820.0 * t) * 0.4
		samples[i] = click * env * 0.45
	return _make_wav_from_samples(samples, sample_rate)

static func create_flare_launch() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.30)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7711
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * clampf(t / 0.30, 0.0, 1.0))
		var sweep := lerpf(90.0, 420.0, t / 0.30)
		var tone := sin(TAU * sweep * t) * 0.45
		var hiss := rng.randf_range(-0.5, 0.5) * 0.35
		samples[i] = (tone + hiss) * env * 0.55
	return _make_wav_from_samples(samples, sample_rate)

static func create_flare_burn() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.45)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9922
	var smooth := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := 1.0 - 0.2 * sin(TAU * 8.0 * t)
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.5)
		var rumble := sin(TAU * 80.0 * t) * 0.25
		samples[i] = (smooth * 0.45 + rumble) * env * 0.38
	return _make_wav_from_samples(samples, sample_rate)

static func create_scanner_ping() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.42)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-8.5 * t)
		var ping := sin(TAU * 1320.0 * t) * 0.6 + sin(TAU * 2640.0 * t) * 0.25
		var echo := 0.0
		if t > 0.16:
			var te := t - 0.16
			echo = sin(TAU * 880.0 * te) * exp(-16.0 * te) * 0.35
		samples[i] = (ping * env + echo) * 0.5
	return _make_wav_from_samples(samples, sample_rate)

static func create_beacon_deploy() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.22)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var freq := lerpf(480.0, 880.0, minf(t / 0.12, 1.0))
		var env := exp(-12.0 * t)
		var tone := sin(TAU * freq * t) * 0.5
		var click := 0.0
		if t > 0.12:
			var tc := t - 0.12
			click = sin(TAU * 1400.0 * tc) * exp(-60.0 * tc) * 0.4
		samples[i] = (tone * env + click) * 0.5
	return _make_wav_from_samples(samples, sample_rate)

static func create_beacon_pulse() -> AudioStreamWAV:
	return generate_tone(520.0, 0.18, 0.015, 0.10, "octave", 0.35)

static func create_med_inject() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.34)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5566
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var hiss := 0.0
		if t < 0.14:
			hiss = rng.randf_range(-0.6, 0.6) * exp(-14.0 * t) * 0.5
		var chime := 0.0
		if t >= 0.08:
			var tc := t - 0.08
			chime = (sin(TAU * 680.0 * tc) * 0.4 + sin(TAU * 1020.0 * tc) * 0.3) * exp(-10.0 * tc)
		samples[i] = (hiss + chime) * 0.52
	return _make_wav_from_samples(samples, sample_rate)

static func create_plasma_pulse() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.14)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2390
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var mod := sin(TAU * 380.0 * t) * 75.0
		var saw := (fposmod((105.0 + mod) * t, 1.0) * 2.0 - 1.0) * 0.5
		var sizzle := rng.randf_range(-0.4, 0.4) * 0.3
		var env := sin(PI * clampf(t / 0.14, 0.0, 1.0))
		samples[i] = (saw + sizzle) * env * 0.48
	return _make_wav_from_samples(samples, sample_rate)

static func create_sealant_spray() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.16)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8812
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var raw := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, raw, 0.75)
		var env := sin(PI * clampf(t / 0.16, 0.0, 1.0))
		samples[i] = lp * env * 0.38
	return _make_wav_from_samples(samples, sample_rate)

static func create_flashlight_click() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.045)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-85.0 * t)
		var click := sin(TAU * 1920.0 * t) * 0.55 + sin(TAU * 780.0 * t) * 0.45
		samples[i] = click * env * 0.42
	return _make_wav_from_samples(samples, sample_rate)

static func create_item_equip() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.09)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-45.0 * t)
		var snap := sin(TAU * 780.0 * t) * 0.5 + sin(TAU * 1350.0 * t) * 0.4
		samples[i] = snap * env * 0.38
	return _make_wav_from_samples(samples, sample_rate)

static func create_footstep(is_planet: bool = false) -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.075)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4455
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-48.0 * t)
		var sample := 0.0
		if is_planet:
			var crunch := rng.randf_range(-0.6, 0.6) * 0.45
			var thud := sin(TAU * 85.0 * t) * 0.55
			sample = (crunch + thud) * env
		else:
			var thud := sin(TAU * 105.0 * t) * 0.65
			var metallic := sin(TAU * 880.0 * t) * 0.22 * exp(-65.0 * t)
			sample = (thud + metallic) * env
		samples[i] = sample * 0.32
	return _make_wav_from_samples(samples, sample_rate)


# --- SHIP ENVIRONMENT & INTERACTION SFX ---

static func create_door_close() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.32)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var freq := lerpf(180.0, 55.0, t / 0.32)
		var motor := sin(TAU * freq * t) * 0.4 * (1.0 - t / 0.32)
		var thunk := 0.0
		if t > 0.22:
			var tt := t - 0.22
			thunk = sin(TAU * 72.0 * tt) * exp(-28.0 * tt) * 0.7
		samples[i] = (motor + thunk) * 0.52
	return _make_wav_from_samples(samples, sample_rate)

static func create_access_denied() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.24)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var active := (t < 0.08) or (t > 0.12 and t < 0.20)
		if active:
			var saw := (fposmod(115.0 * t, 1.0) * 2.0 - 1.0) * 0.55
			samples[i] = saw
		else:
			samples[i] = 0.0
	return _make_wav_from_samples(samples, sample_rate)

static func create_airlock_cycle() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.85)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6677
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * clampf(t / 0.85, 0.0, 1.0))
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.45)
		var sub := sin(TAU * 52.0 * t) * 0.35
		samples[i] = (lp * 0.55 + sub) * env * 0.58
	return _make_wav_from_samples(samples, sample_rate)

static func create_lift_move() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.70)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * clampf(t / 0.70, 0.0, 1.0))
		var hum := sin(TAU * 82.0 * t) * 0.45 + sin(TAU * 164.0 * t) * 0.25
		samples[i] = hum * env * 0.46
	return _make_wav_from_samples(samples, sample_rate)

static func create_lift_arrive() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.32)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var thud := sin(TAU * 62.0 * t) * exp(-16.0 * t) * 0.6
		var chime := sin(TAU * 784.0 * t) * exp(-8.0 * t) * 0.35
		samples[i] = (thud + chime) * 0.5
	return _make_wav_from_samples(samples, sample_rate)

static func create_welding_spark() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.16)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1209
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * clampf(t / 0.16, 0.0, 1.0))
		var hum := (fposmod(60.0 * t, 1.0) * 2.0 - 1.0) * 0.4
		var crackle := rng.randf_range(-0.6, 0.6) * 0.45
		samples[i] = (hum + crackle) * env * 0.48
	return _make_wav_from_samples(samples, sample_rate)

static func create_task_complete() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.55)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var notes := [440.0, 554.37, 659.25, 880.0]
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var sum := 0.0
		for n_idx in range(notes.size()):
			var start_t := float(n_idx) * 0.08
			if t >= start_t:
				var local_t := t - start_t
				var env := exp(-6.5 * local_t)
				sum += sin(TAU * notes[n_idx] * local_t) * env * 0.28
		samples[i] = clampf(sum * 0.65, -1.0, 1.0)
	return _make_wav_from_samples(samples, sample_rate)


# --- CONTAINMENT TANK & ENTITY SFX ---

static func create_tank_crack() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.22)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-18.0 * t)
		var ping := sin(TAU * (2200.0 + sin(TAU * 45.0 * t) * 600.0) * t) * 0.6
		samples[i] = ping * env * 0.45
	return _make_wav_from_samples(samples, sample_rate)

static func create_tank_rupture() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.85)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9901
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-5.0 * t)
		var sub := sin(TAU * (70.0 * exp(-8.0 * t) + 24.0) * t) * 0.65
		var shatter := rng.randf_range(-1.0, 1.0) * exp(-12.0 * t) * 0.55
		var ring := sin(TAU * 1150.0 * t) * exp(-4.0 * t) * 0.28
		samples[i] = clampf((sub + shatter + ring) * env * 0.75, -1.0, 1.0)
	return _make_wav_from_samples(samples, sample_rate)

static func create_villain_emerge() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.65)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * clampf(t / 0.65, 0.0, 1.0))
		var vib := sin(TAU * 55.0 * t) * 80.0
		var tone1 := sin(TAU * (440.0 + vib) * t) * 0.4
		var tone2 := sin(TAU * (660.0 + vib * 1.5) * t) * 0.35
		var growl := (fposmod(85.0 * t, 1.0) * 2.0 - 1.0) * 0.25
		samples[i] = (tone1 + tone2 + growl) * env * 0.58
	return _make_wav_from_samples(samples, sample_rate)

static func create_villain_attack() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.52)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-6.0 * t)
		var sweep := lerpf(120.0, 480.0, minf(t / 0.25, 1.0))
		var roar := sin(TAU * sweep * t) * 0.5 + (fposmod(95.0 * t, 1.0) * 2.0 - 1.0) * 0.3
		samples[i] = roar * env * 0.62
	return _make_wav_from_samples(samples, sample_rate)

static func create_villain_hurt() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.42)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6611
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-8.0 * t)
		var dive := 920.0 * exp(-14.0 * t) + 200.0
		var screech := sin(TAU * dive * t) * 0.5
		var sizzle := rng.randf_range(-0.5, 0.5) * exp(-10.0 * t) * 0.35
		samples[i] = (screech + sizzle) * env * 0.55
	return _make_wav_from_samples(samples, sample_rate)

static func create_villain_duct() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.35)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7788
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-10.0 * t)
		var scrape := rng.randf_range(-0.5, 0.5) * 0.4
		var hollow := sin(TAU * 140.0 * t) * 0.4
		samples[i] = (scrape + hollow) * env * 0.45
	return _make_wav_from_samples(samples, sample_rate)


# --- 3D FLIGHT & MINING SFX ---

static func create_laser_cannon() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.18)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-15.0 * t)
		var freq := 1250.0 * exp(-24.0 * t) + 160.0
		var laser := sin(TAU * freq * t) * 0.65
		samples[i] = laser * env * 0.55
	return _make_wav_from_samples(samples, sample_rate)

static func create_coolant_flush() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.55)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1133
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * clampf(t / 0.55, 0.0, 1.0))
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.65)
		samples[i] = lp * env * 0.48
	return _make_wav_from_samples(samples, sample_rate)

static func create_mining_drill() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.35)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4499
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * clampf(t / 0.35, 0.0, 1.0))
		var grind := rng.randf_range(-0.4, 0.4) * 0.35
		var motor := sin(TAU * 78.0 * t) * 0.45
		samples[i] = (grind + motor) * env * 0.5
	return _make_wav_from_samples(samples, sample_rate)


static func create_door_open() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.38)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3388
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var hiss := rng.randf_range(-0.5, 0.5) * exp(-16.0 * t) * 0.5
		var motor := sin(TAU * (70.0 + 90.0 * (t / 0.38)) * t) * 0.35 * sin(PI * clampf(t / 0.38, 0.0, 1.0))
		samples[i] = (hiss + motor) * 0.6
	return _make_wav_from_samples(samples, sample_rate)


static func create_steam_burst() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.35)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2211
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-7.0 * t)
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.6)
		samples[i] = lp * env * 0.55
	return _make_wav_from_samples(samples, sample_rate)


static func create_capacitor_tune() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.28)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * clampf(t / 0.28, 0.0, 1.0))
		var freq := 340.0 + 200.0 * sin(TAU * 4.0 * t)
		var tone := sin(TAU * freq * t) * 0.55 + sin(TAU * freq * 2.0 * t) * 0.25
		samples[i] = tone * env * 0.5
	return _make_wav_from_samples(samples, sample_rate)


static func create_bus_sync() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.55)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-5.0 * t)
		var sub := sin(TAU * 65.0 * t) * 0.75 * env
		var chord := (sin(TAU * 220.0 * t) * 0.35 + sin(TAU * 330.0 * t) * 0.25 + sin(TAU * 440.0 * t) * 0.2) * env
		samples[i] = clampf((sub + chord) * 0.75, -1.0, 1.0)
	return _make_wav_from_samples(samples, sample_rate)


static func create_latch_release() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.12)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-60.0 * t)
		var snap := sin(TAU * 750.0 * t) * 0.6 + sin(TAU * 1850.0 * t) * 0.4
		samples[i] = snap * env * 0.55
	return _make_wav_from_samples(samples, sample_rate)


static func create_cartridge_seat() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.22)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var slide := sin(TAU * 260.0 * t) * exp(-20.0 * t) * 0.35
		var chunk := 0.0
		if t > 0.06:
			var tc := t - 0.06
			chunk = (sin(TAU * 85.0 * tc) * 0.75 + sin(TAU * 420.0 * tc) * 0.35) * exp(-28.0 * tc)
		samples[i] = (slide + chunk) * 0.65
	return _make_wav_from_samples(samples, sample_rate)


static func create_heartbeat() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.45)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var beat1 := sin(TAU * 52.0 * t) * exp(-28.0 * t) * 0.95
		var beat2 := 0.0
		if t > 0.14:
			var t2 := t - 0.14
			beat2 = sin(TAU * 46.0 * t2) * exp(-24.0 * t2) * 0.85
		samples[i] = clampf((beat1 + beat2) * 0.85, -1.0, 1.0)
	return _make_wav_from_samples(samples, sample_rate)


static func create_flatline() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 2.2)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := 1.0
		if t < 0.02:
			env = t / 0.02
		elif t > 1.9:
			env = (2.2 - t) / 0.3
		var tone := sin(TAU * 920.0 * t) * 0.42 + sin(TAU * 1840.0 * t) * 0.06
		samples[i] = clampf(tone * env, -1.0, 1.0)
	return _make_wav_from_samples(samples, sample_rate)


static func create_suit_breach() -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(sample_rate * 0.55)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var env := exp(-10.0 * t)
		var beep := sin(TAU * lerpf(1200.0, 600.0, t / 0.55) * t) * 0.4
		var hiss := (randf() * 2.0 - 1.0) * 0.28
		samples[i] = clampf((beep + hiss) * env, -1.0, 1.0)
	return _make_wav_from_samples(samples, sample_rate)


# --- GENERAL SFX RETRIEVAL & PLAYBACK ---

static func get_default_bus(sfx_name: String) -> StringName:
	match sfx_name:
		"heartbeat", "flatline", "suit_breach":
			return &"Horror"
		"tank_crack", "tank_rupture", "villain_emerge", "villain_attack", "villain_hurt", "villain_duct", "tremor_pulse", "echo_mimic_whisper":
			return &"Horror"
		"landing_thud":
			return &"Environment"
		"terminal_open", "button_click", "button_hover", "switch_toggle", "slider_tick", "access_denied", "task_complete", "radio_squelch", "unlock_chime":
			return &"UI"
		"door_close", "door_open", "airlock_cycle", "lift_move", "lift_arrive", "welding_spark", "steam_burst":
			return &"Environment"
		_:
			return &"SFX"


static func get_sfx(sfx_name: String) -> AudioStream:
	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name] as AudioStream

	# Check for high-fidelity pre-rendered WAV on disk
	var wav_path := "res://audio/sfx/" + sfx_name + ".wav"
	if ResourceLoader.exists(wav_path):
		var disk_stream := load(wav_path) as AudioStream
		if disk_stream != null:
			_sfx_cache[sfx_name] = disk_stream
			return disk_stream

	# Procedural fallback
	var stream: AudioStreamWAV = null
	match sfx_name:
		"revolver_shot": stream = create_revolver_shot()
		"dry_fire": stream = create_dry_fire()
		"flare_launch": stream = create_flare_launch()
		"flare_burn": stream = create_flare_burn()
		"scanner_ping": stream = create_scanner_ping()
		"beacon_deploy": stream = create_beacon_deploy()
		"beacon_pulse": stream = create_beacon_pulse()
		"med_inject": stream = create_med_inject()
		"plasma_pulse": stream = create_plasma_pulse()
		"sealant_spray": stream = create_sealant_spray()
		"flashlight_click": stream = create_flashlight_click()
		"item_equip": stream = create_item_equip()
		"footstep": stream = create_footstep(false)
		"footstep_planet": stream = create_footstep(true)
		"door_close": stream = create_door_close()
		"door_open": stream = create_door_open()
		"access_denied": stream = create_access_denied()
		"airlock_cycle": stream = create_airlock_cycle()
		"lift_move": stream = create_lift_move()
		"lift_arrive": stream = create_lift_arrive()
		"welding_spark": stream = create_welding_spark()
		"steam_burst": stream = create_steam_burst()
		"capacitor_tune": stream = create_capacitor_tune()
		"bus_sync": stream = create_bus_sync()
		"latch_release": stream = create_latch_release()
		"cartridge_seat": stream = create_cartridge_seat()
		"task_complete": stream = create_task_complete()
		"tank_crack": stream = create_tank_crack()
		"tank_rupture": stream = create_tank_rupture()
		"villain_emerge": stream = create_villain_emerge()
		"villain_attack": stream = create_villain_attack()
		"villain_hurt": stream = create_villain_hurt()
		"villain_duct": stream = create_villain_duct()
		"terminal_open": stream = create_terminal_open()
		"switch_toggle": stream = create_switch_toggle()
		"slider_tick": stream = create_slider_tick()
		"unlock_chime": stream = create_unlock_chime()
		"laser_cannon": stream = create_laser_cannon()
		"coolant_flush": stream = create_coolant_flush()
		"mining_drill": stream = create_mining_drill()
		"radio_squelch": stream = create_radio_squelch()
		"tremor_pulse": stream = create_tremor_pulse()
		"landing_thud": stream = create_landing_thud()
		"echo_mimic_whisper": stream = create_echo_mimic_whisper()
		"button_click": stream = create_button_click()
		"button_hover": stream = create_button_hover()
		"heartbeat": stream = create_heartbeat()
		"flatline": stream = create_flatline()
		"suit_breach": stream = create_suit_breach()
		_: stream = create_button_click()

	if stream != null:
		_sfx_cache[sfx_name] = stream
	return stream


static func play_sfx(sfx_name: String, parent_node: Node = null, volume_db: float = 0.0, bus: StringName = &"", pitch_randomness: float = 0.08) -> AudioStreamPlayer:
	var stream := get_sfx(sfx_name)
	if stream == null:
		return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db + randf_range(-0.35, 0.35)
	if pitch_randomness > 0.001:
		player.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
	player.bus = bus if (bus != &"" and bus != &"Master") else get_default_bus(sfx_name)
	
	var target: Node = parent_node if (is_instance_valid(parent_node) and parent_node.is_inside_tree()) else null
	if target == null:
		var main_loop := Engine.get_main_loop()
		if main_loop is SceneTree and (main_loop as SceneTree).current_scene != null:
			target = (main_loop as SceneTree).current_scene
		elif main_loop is SceneTree and (main_loop as SceneTree).root != null:
			target = (main_loop as SceneTree).root
	if target != null:
		target.add_child(player)
		player.finished.connect(player.queue_free)
		player.play()
		return player
	return null


static func play_sfx_2d(sfx_name: String, global_pos: Vector2, parent_node: Node = null, volume_db: float = 0.0, max_distance: float = 650.0, bus: StringName = &"", pitch_randomness: float = 0.08) -> AudioStreamPlayer2D:
	var stream := get_sfx(sfx_name)
	if stream == null:
		return null
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db + randf_range(-0.35, 0.35)
	if pitch_randomness > 0.001:
		player.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
	player.bus = bus if (bus != &"" and bus != &"Master") else get_default_bus(sfx_name)
	player.max_distance = max_distance
	player.global_position = global_pos
	
	var target: Node = parent_node if (is_instance_valid(parent_node) and parent_node.is_inside_tree()) else null
	if target == null:
		var main_loop := Engine.get_main_loop()
		if main_loop is SceneTree and (main_loop as SceneTree).current_scene != null:
			target = (main_loop as SceneTree).current_scene
	if target != null:
		target.add_child(player)
		player.finished.connect(player.queue_free)
		player.play()
		return player
	return null


static func play_footstep(parent_node: Node = null, is_planet: bool = false, volume_db: float = -8.0) -> AudioStreamPlayer:
	var sfx_name := "footstep_planet" if is_planet else "footstep"
	return play_sfx(sfx_name, parent_node, volume_db, &"SFX", 0.12)
