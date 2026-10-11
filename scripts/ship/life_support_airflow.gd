extends Node2D

const FLOW_LENGTH := 42.0
const FLOW_DASH_SPACING := 18.0
const FLOW_SPEED := 30.0
const LANE_OFFSETS := [-5.5, 0.0, 5.5]
const TRACE_COLOR := Color(0.42, 0.82, 0.9, 0.14)
const FLOW_COLOR := Color(0.62, 0.91, 0.94, 1.0)
const FLOW_GLOW := Color(0.78, 0.96, 0.96, 1.0)
const AUDIO_SAMPLE_RATE := 22050.0
const AUDIO_BUFFER_LENGTH := 0.35
const AIR_SOUND_GAIN := 0.5
const AIR_SOUND_BREATHING_HZ := 0.22
const GLOW_BASE_ENERGY := 0.5
const GLOW_PULSE_AMOUNT := 0.07
const GLOW_PULSE_SPEED := 0.58
const SPILL_GLOW_BASE_ENERGY := 0.22
const SPILL_GLOW_PULSE_AMOUNT := 0.035
const SPILL_GLOW_PHASE_LAG := 0.7

var _flow_distance := 0.0
var _glow_phase := 0.0
var _air_sound_time := 0.0
var _air_lowpass := 0.0
var _air_bass := 0.0
var _air_rng := RandomNumberGenerator.new()
var _air_playback: AudioStreamGeneratorPlayback

@onready var _vent_glow: PointLight2D = $VentGlow
@onready var _airflow_spill_glow: PointLight2D = $AirflowSpillGlow


func _process(delta: float) -> void:
	_flow_distance = fposmod(_flow_distance + delta * FLOW_SPEED, FLOW_DASH_SPACING)
	_glow_phase += delta * GLOW_PULSE_SPEED
	_vent_glow.energy = GLOW_BASE_ENERGY + sin(_glow_phase) * GLOW_PULSE_AMOUNT
	var spill_pulse := sin(_glow_phase - SPILL_GLOW_PHASE_LAG)
	_airflow_spill_glow.energy = SPILL_GLOW_BASE_ENERGY + spill_pulse * SPILL_GLOW_PULSE_AMOUNT
	queue_redraw()
	_fill_air_sound_buffer()


func _ready() -> void:
	_air_rng.randomize()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = AUDIO_SAMPLE_RATE
	generator.buffer_length = AUDIO_BUFFER_LENGTH

	var air_player := AudioStreamPlayer2D.new()
	air_player.name = "AirflowSound"
	air_player.stream = generator
	air_player.volume_db = -8.0
	air_player.max_distance = 480.0
	air_player.attenuation = 1.2
	add_child(air_player)
	air_player.play()
	_air_playback = air_player.get_stream_playback() as AudioStreamGeneratorPlayback


func _draw() -> void:
	for lane_index in range(LANE_OFFSETS.size()):
		var lane_offset: float = LANE_OFFSETS[lane_index]
		var lane_phase := float(lane_index) * 0.65
		var trace := PackedVector2Array()
		for sample_index in range(13):
			var progress := float(sample_index) / 12.0
			trace.append(_point_on_stream(progress, lane_offset, lane_phase))
		draw_polyline(trace, TRACE_COLOR, 0.8, true)

		for dash_index in range(3):
			var distance := fposmod(
				_flow_distance + float(dash_index) * FLOW_DASH_SPACING / 3.0 + float(lane_index) * 4.0,
				FLOW_LENGTH
			)
			var progress := distance / FLOW_LENGTH
			var point := _point_on_stream(progress, lane_offset, lane_phase)
			var alpha := sin(progress * PI) * 0.72
			var direction := _stream_direction(progress, lane_phase)
			var tail := point - direction * 2.8
			var tip := point + direction * 2.0

			var glow := FLOW_COLOR
			glow.a = alpha * 0.35
			draw_line(tail, tip, glow, 2.2, true)
			var streak := FLOW_GLOW if dash_index == 0 else FLOW_COLOR
			streak.a = alpha
			draw_line(tail, tip, streak, 1.0, true)


func _point_on_stream(progress: float, lane_offset: float, lane_phase: float) -> Vector2:
	var x := progress * FLOW_LENGTH
	var wave := sin(progress * TAU * 0.7 + lane_phase) * 2.0
	return Vector2(x, lane_offset + wave)


func _stream_direction(progress: float, lane_phase: float) -> Vector2:
	var slope := cos(progress * TAU * 0.7 + lane_phase) * 2.0 * TAU * 0.7
	return Vector2(1.0, slope).normalized()


func _fill_air_sound_buffer() -> void:
	if _air_playback == null:
		return

	var frames_available := _air_playback.get_frames_available()
	for frame_index in range(frames_available):
		var white_noise := _air_rng.randf_range(-1.0, 1.0)
		_air_lowpass += (white_noise - _air_lowpass) * 0.34
		_air_bass += (_air_lowpass - _air_bass) * 0.02
		var filtered_air := _air_lowpass - _air_bass
		var breathing := 0.88 + 0.12 * sin(_air_sound_time * TAU * AIR_SOUND_BREATHING_HZ)
		var sample := filtered_air * AIR_SOUND_GAIN * breathing
		_air_sound_time += 1.0 / AUDIO_SAMPLE_RATE
		_air_playback.push_frame(Vector2(sample, sample))
