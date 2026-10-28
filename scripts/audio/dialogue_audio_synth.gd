class_name DialogueAudioSynth
extends RefCounted

## Procedural retro-futuristic sound synthesis for dialogue, voice blips, and UI feedback.
## Zero external file dependencies; synthesized on-demand in pure GDScript.

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


static func create_speech_amara() -> AudioStreamWAV:
	# Warm astrobiologist voice blip: gentle two-tone tone ~310 Hz
	return generate_tone(310.0, 0.042, 0.006, 0.028, "two_tone", 0.38)


static func create_speech_thura() -> AudioStreamWAV:
	# Alert engineer voice blip: octave overtone ~430 Hz
	return generate_tone(430.0, 0.038, 0.004, 0.025, "octave", 0.36)


static func create_speech_terminal() -> AudioStreamWAV:
	# Synthesized digital frequency chirp ~580 Hz
	return generate_tone(580.0, 0.035, 0.003, 0.022, "fm", 0.32)


static func create_open_cutscene() -> AudioStreamWAV:
	# Cinematic comms open chime: rising dual tone ~340 Hz to ~540 Hz
	return generate_tone(340.0, 0.28, 0.03, 0.16, "chirp", 0.45)


static func create_close_cutscene() -> AudioStreamWAV:
	# Comms channel power down: falling soft tone ~480 Hz to ~240 Hz
	return generate_tone(480.0, 0.18, 0.015, 0.12, "down_chirp", 0.35)


static func create_button_hover() -> AudioStreamWAV:
	# Subtle, delicate sci-fi interface tick ~940 Hz
	return generate_tone(940.0, 0.032, 0.002, 0.024, "sine", 0.22)


static func create_button_click() -> AudioStreamWAV:
	# Punchy, tactile confirmation chime: harmonic octave ~520 Hz
	return generate_tone(520.0, 0.095, 0.004, 0.065, "octave", 0.48)


static func create_page_advance() -> AudioStreamWAV:
	# Soft tactile page / text advance tick ~460 Hz
	return generate_tone(460.0, 0.045, 0.003, 0.032, "two_tone", 0.34)
