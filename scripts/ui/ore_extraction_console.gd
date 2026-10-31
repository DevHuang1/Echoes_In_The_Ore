class_name OreExtractionConsole
extends CanvasLayer

signal extraction_completed(site_id: StringName, is_pristine: bool)
signal machine_test_failed(site_id: StringName)
signal modal_state_changed(is_open: bool)

const PIXEL_THEME := preload("res://themes/ship_pixel_theme.tres")
const PALE := Color(0.94, 0.91, 0.82)
const MUTED := Color(0.59, 0.69, 0.73)
const CYAN := Color(0.36, 0.90, 1.0)
const GREEN := Color(0.48, 0.93, 0.64)
const ORANGE := Color(1.0, 0.68, 0.32)
const RED := Color(1.0, 0.35, 0.28)
const GOLD := Color(1.0, 0.78, 0.38)
const PANEL := Color(0.015, 0.032, 0.042, 0.98)
const PANEL_INNER := Color(0.008, 0.018, 0.025, 0.95)
const DRILL_CUTAWAY_TEXTURE := preload("res://art/planet/erebos_drill_cutaway.png")
const RESONANCE_CORE_TEXTURE := preload("res://art/planet/resonance_ore_intact.png")
const TARGET_FREQUENCY: float = 432.0
const FREQUENCY_TOLERANCE: float = 18.0
const TARGET_DEPTH_METERS: float = 58.0
const SAMPLE_RATE: float = 22050.0

# Embedded interactive oscilloscope screen
class OscilloscopeScreen extends Control:
	var target_freq: float = TARGET_FREQUENCY
	var current_freq: float = 240.0
	var drill_rpm: float = 0.0
	var in_harmonic_lock: bool = false
	var lock_strength: float = 0.0
	var pulse_count: int = 0
	var is_breaker_tripped: bool = false
	var time_accum: float = 0.0

	func _process(delta: float) -> void:
		time_accum += delta
		queue_redraw()

	func _draw() -> void:
		# CRT Monitor frame
		var frame_rect := Rect2(Vector2.ZERO, size)
		draw_rect(frame_rect, PANEL_INNER, true)
		draw_rect(frame_rect, Color(0.18, 0.32, 0.36), false, 2.0)

		# Phosphor Reticle Grid
		var cols := 8
		var rows := 6
		var col_w := size.x / float(cols)
		var row_h := size.y / float(rows)
		for c in range(1, cols):
			var x := c * col_w
			draw_line(Vector2(x, 0.0), Vector2(x, size.y), Color(0.12, 0.22, 0.25, 0.35), 1.0)
		for r in range(1, rows):
			var y := r * row_h
			draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(0.12, 0.22, 0.25, 0.35), 1.0)
		# Center crosshairs
		var center_y := size.y * 0.5
		var center_x := size.x * 0.5
		draw_line(Vector2(0.0, center_y), Vector2(size.x, center_y), Color(0.25, 0.45, 0.48, 0.65), 1.0)
		draw_line(Vector2(center_x, 0.0), Vector2(center_x, size.y), Color(0.25, 0.45, 0.48, 0.65), 1.0)

		# 4-Pulse Status Header
		var font := ThemeDB.fallback_font
		var compact := size.x < 240.0
		draw_string(font, Vector2(8.0, 18.0), "SIGNAL" if compact else "HARMONIC SENSOR TRACE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8 if compact else 10, MUTED)

		for p in range(4):
			var led_x := size.x - (96.0 if compact else 110.0) + float(p) * (21.0 if compact else 26.0)
			var led_y := 12.0
			var led_active: bool = in_harmonic_lock and (pulse_count > p)
			var led_color := GREEN if led_active else Color(0.18, 0.26, 0.28)
			draw_circle(Vector2(led_x, led_y), 5.5, led_color)
			if led_active:
				draw_circle(Vector2(led_x, led_y), 7.5, Color(GREEN.r, GREEN.g, GREEN.b, 0.35))
			draw_string(font, Vector2(led_x - 3.0, led_y + 3.0), str(p + 1), HORIZONTAL_ALIGNMENT_CENTER, -1.0, 8, PALE)

		if is_breaker_tripped:
			var flash: bool = fposmod(time_accum, 0.4) < 0.2
			if flash:
				draw_rect(frame_rect, Color(RED.r, RED.g, RED.b, 0.2), true)
			draw_string(font, Vector2(center_x - 150.0, center_y - 10.0), "! BREAKER TRIPPED  /  OVERHEAT PROTECTION !", HORIZONTAL_ALIGNMENT_CENTER, 300.0, 14, RED)
			draw_string(font, Vector2(center_x - 120.0, center_y + 16.0), "VENTING COOLANT  /  STANDBY", HORIZONTAL_ALIGNMENT_CENTER, 240.0, 11, ORANGE)
			return

		# Draw Target Ore Waveform (Cyan Trace with 4-pulse amplitude modulation)
		var points_target := PackedVector2Array()
		var points_drill := PackedVector2Array()
		var points_lock := PackedVector2Array()

		var step_px := 2.0
		var num_samples := int(size.x / step_px)
		var phase_base := time_accum * 4.0

		# 4-pulse envelope period
		var pulse_cycle := fposmod(time_accum * 1.25, 4.0)

		for i in range(num_samples):
			var x := float(i) * step_px
			var norm_x := x / size.x

			# Target acoustic wave: 4 distinct pulse bursts
			var pulse_wave := sin(norm_x * TAU * 4.0 - phase_base)
			var pulse_envelope := 0.25 + 0.75 * maxf(0.0, sin((norm_x * 4.0 + pulse_cycle) * PI))
			var y_target := center_y + pulse_wave * 42.0 * pulse_envelope
			points_target.append(Vector2(x, y_target))

			# Current Drill frequency wave
			if drill_rpm > 0.0:
				var freq_ratio := current_freq / TARGET_FREQUENCY
				var drill_amp := (drill_rpm / 100.0) * 36.0
				var drill_wave := sin(norm_x * TAU * 4.0 * freq_ratio - time_accum * (drill_rpm * 0.12))
				var y_drill := center_y + drill_wave * drill_amp
				points_drill.append(Vector2(x, y_drill))

				# If in lock, draw glowing interference wave
				if in_harmonic_lock:
					var y_lock := (y_target + y_drill) * 0.5
					points_lock.append(Vector2(x, y_lock))

		# Draw traces
		if points_target.size() > 1:
			draw_polyline(points_target, Color(CYAN.r, CYAN.g, CYAN.b, 0.45), 1.5, true)

		if points_drill.size() > 1:
			var drill_col := GREEN if in_harmonic_lock else GOLD
			draw_polyline(points_drill, Color(drill_col.r, drill_col.g, drill_col.b, 0.85), 2.0, true)

		if points_lock.size() > 1:
			draw_polyline(points_lock, Color(GREEN.r, GREEN.g, GREEN.b, 0.95), 2.5, true)

		# Screen footer readout
		var lock_pct := int(roundf(lock_strength * 100.0))
		var status_str := ("LOCK %d%%" % lock_pct if in_harmonic_lock else "SEEK 432 HZ") if compact else ("LOCK: %d%%  [HARMONIC SYNC]" % lock_pct if in_harmonic_lock else "LOCK: 0%  [OFF-RESONANCE  ·  ADJUST FREQUENCY]")
		var col_status := GREEN if in_harmonic_lock else (GOLD if drill_rpm > 0.0 else MUTED)
		draw_string(font, Vector2(8.0, size.y - 8.0), status_str, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8 if compact else 11, col_status)


# Side-view mining cutaway with an arcade-style status HUD.
class MiningActionPreview extends Control:
	var is_drilling: bool = false
	var in_harmonic_lock: bool = false
	var is_venting: bool = false
	var breaker_tripped: bool = false
	var drill_rpm: float = 0.0
	var heat: float = 12.0
	var depth_m: float = 0.0
	var core_integrity: float = 100.0
	var mission_elapsed: float = 0.0
	var pulse_count: int = 0
	var core_exposed: bool = false
	var time_accum: float = 0.0

	func _process(delta: float) -> void:
		time_accum += delta
		queue_redraw()

	func _draw() -> void:
		var bounds := Rect2(Vector2.ZERO, size)
		var depth_ratio := clampf(depth_m / TARGET_DEPTH_METERS, 0.0, 1.0)
		var field_size := DRILL_CUTAWAY_TEXTURE.get_size()
		var crop_width := minf(float(field_size.x), float(field_size.y) * size.x / size.y) * 0.94
		var crop_height := crop_width * size.y / size.x
		var max_scroll := maxf(0.0, float(field_size.y) - crop_height)
		var field_scroll := max_scroll * depth_ratio
		var field_source := Rect2((float(field_size.x) - crop_width) * 0.5, field_scroll, crop_width, crop_height)
		draw_texture_rect_region(DRILL_CUTAWAY_TEXTURE, bounds, field_source, Color.WHITE, false, true)

		# Side cutaway: the bore is created only as the drill advances from the surface.
		var surface_y := size.y * 0.255
		var rig_x := size.x * 0.695
		var bore_bottom := size.y - 34.0
		var drill_y := lerpf(surface_y + 13.0, bore_bottom - 18.0, depth_ratio)
		if is_drilling and not breaker_tripped:
			drill_y += sin(time_accum * 13.0) * 1.2
		var bore_top := surface_y - 2.0
		var bore_height := maxf(1.0, drill_y - bore_top + 13.0)
		# Freshly cut bore walls and a narrow dark void around the drill string.
		draw_rect(Rect2(rig_x - 4.5, bore_top, 9.0, bore_height), Color(0.035, 0.030, 0.028), true)
		draw_rect(Rect2(rig_x - 3.5, bore_top, 1.0, bore_height), Color(0.54, 0.34, 0.22, 0.8), true)
		draw_rect(Rect2(rig_x + 2.5, bore_top, 1.0, bore_height), Color(0.42, 0.27, 0.20, 0.8), true)
		# Drill string lowers into the bore in connected armored sections.
		var rod_top := surface_y - 10.0
		var rod_bottom := drill_y - 14.0
		var rod_length := maxf(1.0, rod_bottom - rod_top)
		draw_rect(Rect2(rig_x - 2.0, rod_top, 4.0, rod_length), Color(0.09, 0.20, 0.25), true)
		draw_rect(Rect2(rig_x - 1.2, rod_top, 1.3, rod_length), Color(0.31, 0.63, 0.69), true)
		draw_rect(Rect2(rig_x + 0.8, rod_top, 0.7, rod_length), Color(0.67, 0.78, 0.73), true)
		for joint_index in range(int(rod_length / 17.0) + 1):
			var joint_y := rod_top + float(joint_index) * 17.0
			if joint_y < rod_bottom:
				draw_rect(Rect2(rig_x - 3.2, joint_y, 6.4, 2.5), Color(0.58, 0.69, 0.67), true)
				draw_line(Vector2(rig_x - 2.5, joint_y + 1.0), Vector2(rig_x + 2.5, joint_y + 1.0), Color(0.08, 0.15, 0.17), 1.0)
		# Heavy cutting head, rotating cutter face, and debris at the bore tip.
		var bit_color := GREEN if in_harmonic_lock else (RED if breaker_tripped else GOLD)
		var bit_center := Vector2(rig_x, drill_y)
		draw_rect(Rect2(rig_x - 4.5, drill_y - 7.0, 9.0, 6.0), Color(0.10, 0.15, 0.17), true)
		draw_rect(Rect2(rig_x - 3.5, drill_y - 6.0, 7.0, 3.0), Color(0.42, 0.52, 0.51), true)
		draw_rect(Rect2(rig_x - 5.5, drill_y - 3.0, 11.0, 3.0), Color(0.20, 0.27, 0.27), true)
		draw_line(Vector2(rig_x - 4.0, drill_y - 2.0), Vector2(rig_x + 4.0, drill_y - 2.0), Color(0.69, 0.73, 0.66), 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(rig_x - 5.0, drill_y), Vector2(rig_x + 5.0, drill_y), Vector2(rig_x + 3.5, drill_y + 4.0), Vector2(rig_x, drill_y + 6.0), Vector2(rig_x - 3.5, drill_y + 4.0)]), Color(0.32, 0.38, 0.35))
		var cutter_angle := time_accum * (drill_rpm * 0.30 if is_drilling and not breaker_tripped else 0.0)
		draw_circle(bit_center + Vector2(0.0, 5.0), 3.4, Color(0.08, 0.11, 0.12))
		draw_circle(bit_center + Vector2(0.0, 5.0), 2.0, Color(0.43, 0.50, 0.48))
		draw_circle(bit_center + Vector2(0.0, 5.0), 1.0, bit_color)
		for tooth in range(6):
			var tooth_angle := cutter_angle + float(tooth) * TAU / 6.0
			var tooth_direction := Vector2(cos(tooth_angle), sin(tooth_angle))
			var cutter_origin := bit_center + Vector2(0.0, 5.0)
			draw_line(cutter_origin + tooth_direction * 1.8, cutter_origin + tooth_direction * 4.0, bit_color, 1.0)
		# Rock chips spray out from the rotating bit; coolant creates a cold vapor plume.
		if is_drilling and not breaker_tripped:
			for chip in range(6):
				var chip_phase := fposmod(time_accum * 2.8 + float(chip) / 6.0, 1.0)
				var chip_angle := PI + float(chip) * PI / 5.0
				var chip_pos := bit_center + Vector2(cos(chip_angle), sin(chip_angle)) * (3.0 + chip_phase * 6.0)
				var chip_color := Color(0.32, 0.88, 0.97) if in_harmonic_lock else Color(0.95, 0.58, 0.29)
				draw_circle(chip_pos, 1.2 + float(chip % 2), Color(chip_color.r, chip_color.g, chip_color.b, 1.0 - chip_phase * 0.7))
		if is_venting:
			for puff in range(5):
				var puff_phase := fposmod(time_accum * 1.5 + float(puff) * 0.2, 1.0)
				var puff_pos := bit_center + Vector2(sin(time_accum + float(puff)) * 11.0, -puff_phase * 24.0 - 5.0)
				draw_circle(puff_pos, 2.0 + puff_phase * 3.0, Color(0.46, 0.88, 0.96, 0.45 * (1.0 - puff_phase)))
		if breaker_tripped and fposmod(time_accum, 0.5) < 0.25:
			draw_circle(bit_center, 12.0, Color(1.0, 0.13, 0.07, 0.15))
			draw_arc(bit_center, 12.0, 0.0, TAU, 32, RED, 1.5, true)

		# Reveal the mission's resonance core near the end of the bore.
		var core_reveal := clampf((depth_ratio - 0.72) / 0.28, 0.0, 1.0)
		var core_pos := Vector2(rig_x + 31.0, bore_bottom - 32.0)
		var core_pulse := 0.5 + 0.5 * sin(time_accum * 2.6)
		var core_size := Vector2(32.0, 38.0).lerp(Vector2(50.0, 58.0), core_reveal)
		if core_exposed:
			core_pos += Vector2(14.0, -20.0 + sin(time_accum * 2.0) * 2.0)
		# A faint locator appears early; its glow and reticle strengthen as the bit nears the target.
		var marker_alpha := 0.12 + core_reveal * 0.45
		var marker_radius := core_size.x * 0.65 + core_pulse * 4.0
		draw_circle(core_pos, marker_radius, Color(0.12, 0.72, 0.96, marker_alpha * 0.35))
		draw_arc(core_pos, marker_radius + 4.0, time_accum * 0.5, time_accum * 0.5 + TAU * 0.82, 40, Color(0.40, 0.89, 1.0, marker_alpha), 1.3, true)
		draw_line(core_pos + Vector2(-marker_radius - 5.0, 0.0), core_pos + Vector2(-marker_radius + 1.0, 0.0), Color(0.55, 0.91, 1.0, marker_alpha), 1.2)
		draw_line(core_pos + Vector2(marker_radius - 1.0, 0.0), core_pos + Vector2(marker_radius + 5.0, 0.0), Color(0.55, 0.91, 1.0, marker_alpha), 1.2)
		if core_reveal > 0.0:
			var core_rect := Rect2(core_pos - core_size * 0.5, core_size)
			draw_texture_rect(RESONANCE_CORE_TEXTURE, core_rect, false, Color(1.0, 1.0, 1.0, core_reveal))
		if core_reveal > 0.2 or core_exposed:
			var target_box := Rect2(Vector2(core_pos.x + 21.0, core_pos.y - core_size.y * 0.5 - 20.0), Vector2(84.0, 17.0))
			draw_rect(target_box, Color(0.015, 0.035, 0.043, 0.9), true)
			draw_rect(target_box, Color(0.25, 0.73, 0.82, 0.75), false, 1.0)
			draw_string(ThemeDB.fallback_font, target_box.position + Vector2(4.0, 12.0), "CORE SECURED" if core_exposed else "TARGET  /  58 m", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, CYAN)
		if core_exposed:
			for sparkle in range(6):
				var sparkle_angle := time_accum * 1.8 + float(sparkle) * TAU / 6.0
				var sparkle_pos := core_pos + Vector2(cos(sparkle_angle), sin(sparkle_angle)) * (core_size.x * 0.6)
				draw_circle(sparkle_pos, 1.5 + core_pulse, Color(0.62, 0.95, 1.0, 0.85))

		var font := ThemeDB.fallback_font
		# Arcade HUD overlay, inspired by the reference layout.
		draw_rect(Rect2(Vector2(7.0, 7.0), Vector2(139.0, 83.0)), Color(0.025, 0.018, 0.014, 0.80), true)
		_draw_hud_bar("DEPTH", depth_m / TARGET_DEPTH_METERS, CYAN, Rect2(13.0, 24.0, 126.0, 17.0))
		_draw_hud_bar("CORE", core_integrity / 100.0, GREEN if core_integrity >= 45.0 else RED, Rect2(13.0, 45.0, 126.0, 17.0))
		_draw_hud_bar("HEAT", heat / 100.0, RED if heat >= 70.0 else ORANGE, Rect2(13.0, 66.0, 126.0, 17.0))
		var timer_text := "%02d:%02d" % [int(mission_elapsed / 60.0), int(mission_elapsed) % 60]
		draw_rect(Rect2(Vector2(size.x * 0.5 - 29.0, 7.0), Vector2(58.0, 20.0)), Color(0.025, 0.018, 0.014, 0.82), true)
		draw_string(font, Vector2(size.x * 0.5 - 20.0, 21.0), timer_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, PALE)
		draw_rect(Rect2(Vector2(size.x - 103.0, 7.0), Vector2(96.0, 20.0)), Color(0.025, 0.018, 0.014, 0.82), true)
		draw_string(font, Vector2(size.x - 97.0, 21.0), "432 Hz  /  %d-4" % pulse_count, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, GOLD if in_harmonic_lock else PALE)
		var status := "BREAKER TRIPPED" if breaker_tripped else ("RESONANCE CORE SECURED" if core_exposed else ("VENTING COOLANT" if is_venting else ("HARMONIC LOCK" if in_harmonic_lock else ("OFF-RESONANCE" if is_drilling else "RIG STANDBY"))))
		var status_color := RED if breaker_tripped else (CYAN if core_exposed or is_venting else (GREEN if in_harmonic_lock else (ORANGE if is_drilling else MUTED)))
		draw_rect(Rect2(0.0, size.y - 20.0, size.x, 20.0), Color(0.025, 0.018, 0.014, 0.84), true)
		draw_string(font, Vector2(8.0, size.y - 6.0), "%s   /   %.1f m DEEP" % [status, depth_m], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, status_color)
		draw_rect(bounds, Color(0.18, 0.32, 0.36, 0.85), false, 1.0)

	func _draw_hud_bar(label: String, value: float, color: Color, rect: Rect2) -> void:
		draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + 8.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 7, PALE)
		var bar := Rect2(rect.position.x + 39.0, rect.position.y, rect.size.x - 39.0, 9.0)
		draw_rect(bar, Color(0.02, 0.02, 0.02, 0.9), true)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(value, 0.0, 1.0), bar.size.y)), color, true)
		draw_rect(bar, Color(0.70, 0.68, 0.59, 0.75), false, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(bar.position.x + bar.size.x - 23.0, rect.position.y + 8.0), "%d%%" % int(roundf(value * 100.0)), HORIZONTAL_ALIGNMENT_RIGHT, 22.0, 7, PALE)


# Main Console State
var _site: Dictionary = {}
var _test_only: bool = false
var _bypass_installed: bool = false
var _is_drilling: bool = false
var _completed: bool = false
var _extraction_succeeded: bool = false

var _current_freq: float = 380.0
var _drill_rpm: float = 0.0
var _depth_m: float = 0.0
var _thermal_heat: float = 12.0
var _core_integrity: float = 100.0
var _venting_coolant: bool = false
var _mining_elapsed: float = 0.0

var _is_breaker_tripped: bool = false
var _breaker_timer: float = 0.0
var _lock_hold_time: float = 0.0
var _pulse_index: int = 0

# UI Controls
var _oscilloscope: OscilloscopeScreen
var _mining_preview: MiningActionPreview
var _freq_slider: HSlider
var _freq_label: Label
var _rpm_slider: HSlider
var _rpm_label: Label
var _depth_label: Label
var _depth_bar: ProgressBar
var _heat_bar: ProgressBar
var _heat_label: Label
var _integrity_bar: ProgressBar
var _integrity_label: Label
var _status_label: Label
var _drill_button: Button
var _vent_button: Button
var _close_button: Button
var _mode_tag: Label

# Audio Engine
var _audio_player: AudioStreamPlayer
var _audio_generator: AudioStreamGenerator
var _audio_playback: AudioStreamGeneratorPlayback
var _motor_phase: float = 0.0
var _alarm_phase: float = 0.0
var _pulse_audio_phase: float = 0.0


func open(site: Dictionary) -> void:
	_site = site.duplicate(true)
	_mining_elapsed = 0.0
	_extraction_succeeded = false
	# Check if player unlocked/equipped harmonic bypass coupler
	_bypass_installed = Engine.has_meta(&"harmonic_bypass_coupler_unlocked") or bool(_site.get("bypass_active", false))
	_test_only = bool(_site.get("test_only", false)) and not _bypass_installed

	layer = 20
	_build_interface()
	_init_audio()
	modal_state_changed.emit(true)


func _exit_tree() -> void:
	if is_instance_valid(_audio_player):
		_audio_player.stop()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_console()


func _process(delta: float) -> void:
	if _is_drilling:
		_mining_elapsed += delta
	# Breaker recovery
	if _is_breaker_tripped:
		_breaker_timer -= delta
		_thermal_heat = maxf(15.0, _thermal_heat - delta * 25.0)
		_depth_m = maxf(0.0, _depth_m - delta * 0.8)
		if _breaker_timer <= 0.0:
			_is_breaker_tripped = false
			_status_label.text = "BREAKER RESET  /  READY TO ENGAGE"
			_status_label.add_theme_color_override("font_color", GREEN)
		_update_ui_meters()
		_sync_mining_preview()
		_fill_audio_buffer()
		return

	# Coolant venting
	if _venting_coolant:
		_thermal_heat = maxf(10.0, _thermal_heat - delta * 45.0)
		_drill_rpm = maxf(0.0, _drill_rpm - delta * 30.0)
		if is_instance_valid(_rpm_slider):
			_rpm_slider.value = _drill_rpm
		_status_label.text = "PURGING CRYOGENIC COOLANT  /  TEMPERATURE DROPPING"
		_status_label.add_theme_color_override("font_color", CYAN)

	if not _is_drilling:
		# Ambient cooling
		if not _venting_coolant:
			_thermal_heat = maxf(12.0, _thermal_heat - delta * 6.0)
		_update_ui_meters()
		_sync_mining_preview()
		_fill_audio_buffer()
		return

	# Machine test only sequence (initial pre-bypass failure)
	if _test_only:
		_depth_m += delta * 4.0
		_thermal_heat += delta * 12.0
		_drill_rpm = 40.0
		if _depth_m >= 14.0:
			_is_drilling = false
			_completed = true
			_status_label.text = "TEST FAILED  /  BORE MOTOR WILL NOT IGNITE"
			_status_label.add_theme_color_override("font_color", ORANGE)
			_drill_button.text = "TEST FAILED"
			_drill_button.disabled = true
			_close_button.text = "CLOSE REPORT"
			machine_test_failed.emit(StringName(_site.get("id", &"")))
		_update_ui_meters()
		_sync_mining_preview()
		_fill_audio_buffer()
		return

	# Active Drilling Simulation
	var freq_diff := absf(_current_freq - TARGET_FREQUENCY)
	var in_lock := freq_diff <= FREQUENCY_TOLERANCE and _drill_rpm > 5.0
	var lock_strength := clampf(1.0 - (freq_diff / FREQUENCY_TOLERANCE), 0.0, 1.0) if in_lock else 0.0

	if in_lock:
		_lock_hold_time += delta
		_pulse_index = mini(4, int(_lock_hold_time / 0.8) + 1)
	else:
		_lock_hold_time = maxf(0.0, _lock_hold_time - delta * 1.5)
		_pulse_index = maxi(0, int(_lock_hold_time / 0.8))

	# Thermal heat accumulation: increases with RPM, reduced if in harmonic lock
	var heat_rate := (_drill_rpm / 100.0) * (14.0 if in_lock else 24.0)
	_thermal_heat += heat_rate * delta

	# Check overheat trip
	if _thermal_heat >= 100.0:
		_trip_breaker()
		return

	# Depth progression: requires RPM > 0
	if in_lock:
		var advance_speed := (_drill_rpm / 100.0) * (3.8 + lock_strength * 2.2)
		_depth_m = minf(TARGET_DEPTH_METERS, _depth_m + advance_speed * delta)
		_status_label.text = "HARMONIC LOCK ACTIVE  /  DRILLING BASALT SEAM (%d/4 PULSES)" % _pulse_index
		_status_label.add_theme_color_override("font_color", GREEN)
	elif _drill_rpm > 10.0:
		# Drilling out of resonance: slow advance, lattice integrity damage
		_depth_m = minf(TARGET_DEPTH_METERS, _depth_m + (_drill_rpm / 100.0) * 0.9 * delta)
		var integrity_damage := (_drill_rpm / 100.0) * 6.5 * delta
		_core_integrity = maxf(20.0, _core_integrity - integrity_damage)
		_status_label.text = "WARNING: OFF-RESONANCE VIBRATIONS  /  CORE DAMAGE DETECTED"
		_status_label.add_theme_color_override("font_color", ORANGE)
	else:
		_status_label.text = "DRILL MOTOR IDLE  /  INCREASE RPM DRIVE"
		_status_label.add_theme_color_override("font_color", MUTED)

	# Update oscilloscope state
	if is_instance_valid(_oscilloscope):
		_oscilloscope.current_freq = _current_freq
		_oscilloscope.drill_rpm = _drill_rpm
		_oscilloscope.in_harmonic_lock = in_lock
		_oscilloscope.lock_strength = lock_strength
		_oscilloscope.pulse_count = _pulse_index
		_oscilloscope.is_breaker_tripped = false
	_sync_mining_preview(in_lock)

	# Check depth completion
	if _depth_m >= TARGET_DEPTH_METERS and not _completed:
		_completed = true
		_extraction_succeeded = true
		_is_drilling = false
		_drill_rpm = 0.0
		var is_pristine := _core_integrity >= 70.0
		var grade_name := "PRISTINE RESONANCE CORE" if is_pristine else "FRACTURED RESONANCE CORE"
		_status_label.text = "EXTRACTION COMPLETE  /  %s SECURED" % grade_name
		_status_label.add_theme_color_override("font_color", GREEN if is_pristine else GOLD)
		_drill_button.text = "SAMPLE SECURED"
		_drill_button.disabled = true
		_close_button.text = "RETURN TO SHIP"
		extraction_completed.emit(StringName(_site.get("id", &"")), is_pristine)

	_update_ui_meters()
	_fill_audio_buffer()


func _trip_breaker() -> void:
	_is_breaker_tripped = true
	_breaker_timer = 3.5
	_is_drilling = false
	_drill_rpm = 0.0
	if is_instance_valid(_rpm_slider):
		_rpm_slider.value = 0.0
	_lock_hold_time = 0.0
	_pulse_index = 0
	_status_label.text = "! EMERGENCY BREAKER TRIPPED  /  OVERHEAT PROTECTION ENGAGED !"
	_status_label.add_theme_color_override("font_color", RED)
	if is_instance_valid(_oscilloscope):
		_oscilloscope.is_breaker_tripped = true
		_oscilloscope.drill_rpm = 0.0
		_oscilloscope.in_harmonic_lock = false
	_sync_mining_preview()


func _sync_mining_preview(in_lock: bool = false) -> void:
	if not is_instance_valid(_mining_preview):
		return
	_mining_preview.is_drilling = _is_drilling
	_mining_preview.in_harmonic_lock = in_lock
	_mining_preview.is_venting = _venting_coolant
	_mining_preview.breaker_tripped = _is_breaker_tripped
	_mining_preview.drill_rpm = _drill_rpm
	_mining_preview.heat = _thermal_heat
	_mining_preview.depth_m = _depth_m
	_mining_preview.core_integrity = _core_integrity
	_mining_preview.mission_elapsed = _mining_elapsed
	_mining_preview.pulse_count = _pulse_index
	_mining_preview.core_exposed = _extraction_succeeded


func _update_ui_meters() -> void:
	if is_instance_valid(_depth_bar):
		var pct := int(roundf((_depth_m / TARGET_DEPTH_METERS) * 100.0))
		_depth_bar.value = pct
		_depth_label.text = "BORE DEPTH: %.1f m / %.0f m  (%d%%)" % [_depth_m, TARGET_DEPTH_METERS, pct]

	if is_instance_valid(_heat_bar):
		_heat_bar.value = _thermal_heat
		var heat_col := RED if _thermal_heat >= 90.0 else (ORANGE if _thermal_heat >= 70.0 else CYAN)
		_heat_label.text = "THERMAL LOAD: %d%%  %s" % [int(_thermal_heat), "! OVERHEAT !" if _thermal_heat >= 90.0 else ("WARN" if _thermal_heat >= 70.0 else "NOMINAL")]
		_heat_label.add_theme_color_override("font_color", heat_col)

	if is_instance_valid(_integrity_bar):
		_integrity_bar.value = _core_integrity
		var integ_col := GREEN if _core_integrity >= 70.0 else (GOLD if _core_integrity >= 45.0 else RED)
		_integrity_label.text = "CORE INTEGRITY: %d%%  [%s]" % [int(_core_integrity), "PRISTINE" if _core_integrity >= 70.0 else "FRACTURED"]
		_integrity_label.add_theme_color_override("font_color", integ_col)


func _build_interface() -> void:
	var overlay := Control.new()
	overlay.name = "ExtractionConsoleOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = PIXEL_THEME
	add_child(overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.012, 0.02, 0.85)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "MiningControlPanel"
	panel.custom_minimum_size = Vector2(920.0, 560.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL
	panel_style.border_color = Color(0.24, 0.52, 0.58)
	panel_style.set_border_width_all(2)
	panel_style.content_margin_left = 24.0
	panel_style.content_margin_right = 24.0
	panel_style.content_margin_top = 20.0
	panel_style.content_margin_bottom = 20.0
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	panel.add_child(root_vbox)

	# Header Strip
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	var title_vbox := VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_vbox)

	var title_lbl := Label.new()
	title_lbl.text = "MACHINE TEST  /  FIELD RIG DIAGNOSTIC" if _test_only else "EXTRACTION CONTROL  /  CENTRAL RESONANCE CORE DRILL"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", PALE)
	title_vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "EREBOS SURVEY ZONE · SITE K-12 · TARGET FREQ: 432 Hz [4-PULSE HARMONIC]"
	sub_lbl.add_theme_font_size_override("font_size", 10)
	sub_lbl.add_theme_color_override("font_color", MUTED)
	title_vbox.add_child(sub_lbl)

	_mode_tag = Label.new()
	_mode_tag.text = "[BYPASS COUPLER ENGAGED]" if _bypass_installed else ("[TEST ONLY // LOCKED]" if _test_only else "[ONLINE]")
	_mode_tag.add_theme_font_size_override("font_size", 11)
	_mode_tag.add_theme_color_override("font_color", GREEN if _bypass_installed else ORANGE)
	header.add_child(_mode_tag)

	var close_x := Button.new()
	close_x.text = "X"
	close_x.custom_minimum_size = Vector2(38.0, 32.0)
	close_x.pressed.connect(_close_console)
	header.add_child(close_x)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	rule.color = Color(0.18, 0.38, 0.44)
	root_vbox.add_child(rule)

	# Main Body: Mining field at left, mission telemetry at right.
	var body_hbox := HBoxContainer.new()
	body_hbox.add_theme_constant_override("separation", 20)
	root_vbox.add_child(body_hbox)

	# Side-view drill cutaway with a compact harmonic monitor overlay.
	var drill_viewport := Control.new()
	drill_viewport.custom_minimum_size = Vector2(460.0, 260.0)
	drill_viewport.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drill_viewport.clip_contents = true
	body_hbox.add_child(drill_viewport)
	_mining_preview = MiningActionPreview.new()
	_mining_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drill_viewport.add_child(_mining_preview)
	_oscilloscope = OscilloscopeScreen.new()
	_oscilloscope.custom_minimum_size = Vector2(152.0, 70.0)
	_oscilloscope.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_oscilloscope.offset_left = 8.0
	_oscilloscope.offset_top = -78.0
	_oscilloscope.offset_right = 160.0
	_oscilloscope.offset_bottom = -8.0
	_oscilloscope.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drill_viewport.add_child(_oscilloscope)

	# Right Column: Telemetry Gauges
	var right_vbox := VBoxContainer.new()
	right_vbox.custom_minimum_size.x = 380.0
	right_vbox.add_theme_constant_override("separation", 10)
	body_hbox.add_child(right_vbox)

	# Depth Bar
	_depth_label = Label.new()
	_depth_label.text = "BORE DEPTH: 0.0 m / 58.0 m  (0%)"
	_depth_label.add_theme_font_size_override("font_size", 11)
	_depth_label.add_theme_color_override("font_color", PALE)
	right_vbox.add_child(_depth_label)

	_depth_bar = ProgressBar.new()
	_depth_bar.min_value = 0.0
	_depth_bar.max_value = 100.0
	_depth_bar.value = 0.0
	_depth_bar.show_percentage = false
	_depth_bar.custom_minimum_size = Vector2(0.0, 16.0)
	var depth_fill := StyleBoxFlat.new()
	depth_fill.bg_color = CYAN
	_depth_bar.add_theme_stylebox_override("fill", depth_fill)
	right_vbox.add_child(_depth_bar)

	# Core Integrity Bar
	_integrity_label = Label.new()
	_integrity_label.text = "CORE INTEGRITY: 100%  [PRISTINE]"
	_integrity_label.add_theme_font_size_override("font_size", 11)
	_integrity_label.add_theme_color_override("font_color", GREEN)
	right_vbox.add_child(_integrity_label)

	_integrity_bar = ProgressBar.new()
	_integrity_bar.min_value = 0.0
	_integrity_bar.max_value = 100.0
	_integrity_bar.value = 100.0
	_integrity_bar.show_percentage = false
	_integrity_bar.custom_minimum_size = Vector2(0.0, 16.0)
	var integ_fill := StyleBoxFlat.new()
	integ_fill.bg_color = GREEN
	_integrity_bar.add_theme_stylebox_override("fill", integ_fill)
	right_vbox.add_child(_integrity_bar)

	# Thermal Heat Bar
	_heat_label = Label.new()
	_heat_label.text = "THERMAL LOAD: 12%  NOMINAL"
	_heat_label.add_theme_font_size_override("font_size", 11)
	_heat_label.add_theme_color_override("font_color", CYAN)
	right_vbox.add_child(_heat_label)

	_heat_bar = ProgressBar.new()
	_heat_bar.min_value = 0.0
	_heat_bar.max_value = 100.0
	_heat_bar.value = 12.0
	_heat_bar.show_percentage = false
	_heat_bar.custom_minimum_size = Vector2(0.0, 16.0)
	var heat_fill := StyleBoxFlat.new()
	heat_fill.bg_color = ORANGE
	_heat_bar.add_theme_stylebox_override("fill", heat_fill)
	right_vbox.add_child(_heat_bar)

	# Live Status Message Card
	var status_card := PanelContainer.new()
	var sc_style := StyleBoxFlat.new()
	sc_style.bg_color = PANEL_INNER
	sc_style.border_color = Color(0.18, 0.32, 0.36)
	sc_style.set_border_width_all(1)
	sc_style.content_margin_left = 12.0
	sc_style.content_margin_right = 12.0
	sc_style.content_margin_top = 8.0
	sc_style.content_margin_bottom = 8.0
	status_card.add_theme_stylebox_override("panel", sc_style)
	right_vbox.add_child(status_card)

	_status_label = Label.new()
	_status_label.text = "RIG STANDBY  /  CALIBRATE FREQUENCY & THROTTLE"
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", MUTED)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_card.add_child(_status_label)

	# Bottom Controls: Frequency Slider & RPM Controls
	var ctrl_box := VBoxContainer.new()
	ctrl_box.add_theme_constant_override("separation", 10)
	root_vbox.add_child(ctrl_box)

	# Frequency Control Row
	var freq_row := HBoxContainer.new()
	freq_row.add_theme_constant_override("separation", 10)
	ctrl_box.add_child(freq_row)

	_freq_label = Label.new()
	_freq_label.text = "ULTRASONIC FREQ: %d Hz" % int(_current_freq)
	_freq_label.custom_minimum_size.x = 210.0
	_freq_label.add_theme_font_size_override("font_size", 12)
	_freq_label.add_theme_color_override("font_color", PALE)
	freq_row.add_child(_freq_label)

	var btn_f_minus := Button.new()
	btn_f_minus.text = "—"
	btn_f_minus.custom_minimum_size = Vector2(36.0, 30.0)
	btn_f_minus.pressed.connect(func(): _adjust_freq(-5.0))
	freq_row.add_child(btn_f_minus)

	_freq_slider = HSlider.new()
	_freq_slider.min_value = 160.0
	_freq_slider.max_value = 750.0
	_freq_slider.step = 1.0
	_freq_slider.value = _current_freq
	_freq_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_freq_slider.value_changed.connect(_on_freq_changed)
	freq_row.add_child(_freq_slider)

	var btn_f_plus := Button.new()
	btn_f_plus.text = "+"
	btn_f_plus.custom_minimum_size = Vector2(36.0, 30.0)
	btn_f_plus.pressed.connect(func(): _adjust_freq(5.0))
	freq_row.add_child(btn_f_plus)

	# RPM Throttle Row
	var rpm_row := HBoxContainer.new()
	rpm_row.add_theme_constant_override("separation", 10)
	ctrl_box.add_child(rpm_row)

	_rpm_label = Label.new()
	_rpm_label.text = "DRILL RPM DRIVE: %d%%" % int(_drill_rpm)
	_rpm_label.custom_minimum_size.x = 210.0
	_rpm_label.add_theme_font_size_override("font_size", 12)
	_rpm_label.add_theme_color_override("font_color", PALE)
	rpm_row.add_child(_rpm_label)

	var btn_rpm_zero := Button.new()
	btn_rpm_zero.text = "0"
	btn_rpm_zero.custom_minimum_size = Vector2(36.0, 30.0)
	btn_rpm_zero.pressed.connect(func(): _set_rpm(0.0))
	rpm_row.add_child(btn_rpm_zero)

	_rpm_slider = HSlider.new()
	_rpm_slider.min_value = 0.0
	_rpm_slider.max_value = 100.0
	_rpm_slider.step = 2.0
	_rpm_slider.value = _drill_rpm
	_rpm_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rpm_slider.value_changed.connect(_on_rpm_changed)
	rpm_row.add_child(_rpm_slider)

	var btn_rpm_max := Button.new()
	btn_rpm_max.text = "MAX"
	btn_rpm_max.custom_minimum_size = Vector2(48.0, 30.0)
	btn_rpm_max.pressed.connect(func(): _set_rpm(100.0))
	rpm_row.add_child(btn_rpm_max)

	# Action Buttons
	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_END
	action_row.add_theme_constant_override("separation", 14)
	root_vbox.add_child(action_row)

	_vent_button = Button.new()
	_vent_button.text = "VENT COOLANT [HOLD]"
	_vent_button.custom_minimum_size = Vector2(200.0, 42.0)
	_vent_button.button_down.connect(func(): _venting_coolant = true)
	_vent_button.button_up.connect(func(): _venting_coolant = false)
	action_row.add_child(_vent_button)

	_drill_button = Button.new()
	_drill_button.text = "RUN MACHINE TEST" if _test_only else "START EXTRACTION"
	_drill_button.custom_minimum_size = Vector2(220.0, 42.0)
	_drill_button.pressed.connect(_toggle_drill)
	action_row.add_child(_drill_button)

	_close_button = Button.new()
	_close_button.text = "CANCEL"
	_close_button.custom_minimum_size = Vector2(130.0, 42.0)
	_close_button.pressed.connect(_close_console)
	action_row.add_child(_close_button)


func _on_freq_changed(val: float) -> void:
	_current_freq = val
	if is_instance_valid(_freq_label):
		_freq_label.text = "ULTRASONIC FREQ: %d Hz" % int(_current_freq)


func _adjust_freq(delta_f: float) -> void:
	if is_instance_valid(_freq_slider):
		_freq_slider.value = clampf(_freq_slider.value + delta_f, _freq_slider.min_value, _freq_slider.max_value)


func _on_rpm_changed(val: float) -> void:
	_drill_rpm = val
	if is_instance_valid(_rpm_label):
		_rpm_label.text = "DRILL RPM DRIVE: %d%%" % int(_drill_rpm)


func _set_rpm(val: float) -> void:
	if is_instance_valid(_rpm_slider):
		_rpm_slider.value = val


func _toggle_drill() -> void:
	if _completed:
		return
	if _is_breaker_tripped:
		return
	_is_drilling = not _is_drilling
	if _is_drilling:
		if _drill_rpm <= 0.0:
			_set_rpm(50.0)
		_drill_button.text = "PAUSE DRILL"
		_close_button.text = "ABORT"
	else:
		_drill_button.text = "RESUME DRILL"


func _close_console() -> void:
	if _is_drilling:
		_is_drilling = false
		_status_label.text = "DRILL PAUSED  /  CYCLE INCOMPLETE"
		_drill_button.text = "RESUME DRILL"
		_close_button.text = "CLOSE"
		return
	if is_instance_valid(_audio_player):
		_audio_player.stop()
	modal_state_changed.emit(false)
	queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		if is_instance_valid(_audio_player) and not _audio_player.playing:
			_audio_player.play()
			_audio_playback = _audio_player.get_stream_playback() as AudioStreamGeneratorPlayback


# Audio Synthesis Engine
func _init_audio() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = &"Master"
	_audio_generator = AudioStreamGenerator.new()
	_audio_generator.mix_rate = SAMPLE_RATE
	_audio_generator.buffer_length = 0.15
	_audio_player.stream = _audio_generator
	add_child(_audio_player)
	if is_inside_tree():
		_audio_player.play()
		_audio_playback = _audio_player.get_stream_playback() as AudioStreamGeneratorPlayback


func _fill_audio_buffer() -> void:
	if _audio_playback == null:
		return
	var frames_avail: int = _audio_playback.get_frames_available()
	if frames_avail <= 0:
		return

	var motor_vol := (_drill_rpm / 100.0) * 0.14 if (_is_drilling and not _is_breaker_tripped) else 0.0
	var motor_hz := 55.0 + (_drill_rpm / 100.0) * 160.0
	var motor_step := TAU * motor_hz / SAMPLE_RATE

	var in_lock: bool = is_instance_valid(_oscilloscope) and _oscilloscope.in_harmonic_lock
	var pulse_vol: float = 0.12 if (in_lock and _is_drilling) else 0.0
	var pulse_step := TAU * TARGET_FREQUENCY / SAMPLE_RATE

	var hiss_vol: float = 0.18 if _venting_coolant else 0.0
	var alarm_vol: float = 0.22 if (_is_breaker_tripped or _thermal_heat >= 90.0) else 0.0
	var alarm_hz: float = 880.0 if fposmod(_alarm_phase, TAU * 2.0) < TAU else 660.0
	var alarm_step := TAU * alarm_hz / SAMPLE_RATE

	for _i in range(frames_avail):
		var sample: float = 0.0
		# Motor hum
		if motor_vol > 0.0:
			_motor_phase = fposmod(_motor_phase + motor_step, TAU)
			var wave: float = sin(_motor_phase) + 0.3 * sin(_motor_phase * 2.0)
			sample += wave * motor_vol

		# Harmonic pulse tone
		if pulse_vol > 0.0:
			_pulse_audio_phase = fposmod(_pulse_audio_phase + pulse_step, TAU)
			var p_wave: float = sin(_pulse_audio_phase)
			sample += p_wave * pulse_vol

		# Coolant hiss
		if hiss_vol > 0.0:
			var noise := randf() * 2.0 - 1.0
			sample += noise * hiss_vol

		# Alarm beep
		if alarm_vol > 0.0:
			_alarm_phase = fposmod(_alarm_phase + alarm_step, TAU)
			sample += sin(_alarm_phase) * alarm_vol

		sample = clampf(sample, -1.0, 1.0)
		_audio_playback.push_frame(Vector2(sample, sample))
