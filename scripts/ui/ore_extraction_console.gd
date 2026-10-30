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
		draw_string(font, Vector2(10.0, 18.0), "HARMONIC SENSOR TRACE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, MUTED)

		for p in range(4):
			var led_x := size.x - 110.0 + float(p) * 26.0
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
		var status_str := "LOCK: %d%%  [HARMONIC SYNC]" % lock_pct if in_harmonic_lock else "LOCK: 0%  [OFF-RESONANCE  ·  ADJUST FREQUENCY]"
		var col_status := GREEN if in_harmonic_lock else (GOLD if drill_rpm > 0.0 else MUTED)
		draw_string(font, Vector2(10.0, size.y - 10.0), status_str, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, col_status)


# Main Console State
var _site: Dictionary = {}
var _test_only: bool = false
var _bypass_installed: bool = false
var _is_drilling: bool = false
var _completed: bool = false

var _current_freq: float = 380.0
var _drill_rpm: float = 0.0
var _depth_m: float = 0.0
var _thermal_heat: float = 12.0
var _core_integrity: float = 100.0
var _venting_coolant: bool = false

var _is_breaker_tripped: bool = false
var _breaker_timer: float = 0.0
var _lock_hold_time: float = 0.0
var _pulse_index: int = 0

# UI Controls
var _oscilloscope: OscilloscopeScreen
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

	# Check depth completion
	if _depth_m >= TARGET_DEPTH_METERS and not _completed:
		_completed = true
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

	# Main Body: Split into Left (Oscilloscope) and Right (Gauges)
	var body_hbox := HBoxContainer.new()
	body_hbox.add_theme_constant_override("separation", 20)
	root_vbox.add_child(body_hbox)

	# Left Column: Oscilloscope
	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 8)
	body_hbox.add_child(left_vbox)

	_oscilloscope = OscilloscopeScreen.new()
	_oscilloscope.custom_minimum_size = Vector2(460.0, 230.0)
	_oscilloscope.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(_oscilloscope)

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


# Audio Synthesis Engine
func _init_audio() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = &"Master"
	_audio_generator = AudioStreamGenerator.new()
	_audio_generator.mix_rate = SAMPLE_RATE
	_audio_generator.buffer_length = 0.15
	_audio_player.stream = _audio_generator
	add_child(_audio_player)
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
