class_name ShipPilotingConsole
extends CanvasLayer

signal piloting_completed(encounter_id: StringName, hull_remaining: float)
signal piloting_closed()

const SKIN := preload("res://scripts/ui/pixel_ui.gd")

const GOLD: Color = Color(1.0, 0.78, 0.38, 1.0)
const PALE: Color = Color(0.95, 0.92, 0.84, 1.0)
const MUTED: Color = Color(0.66, 0.76, 0.80, 1.0)
const CYAN: Color = Color(0.36, 0.90, 1.0, 1.0)
const ORANGE: Color = Color(1.0, 0.68, 0.32, 1.0)
const GREEN: Color = Color(0.48, 0.93, 0.64, 1.0)
const ALERT_RED: Color = Color(1.0, 0.34, 0.30, 1.0)

# Phases: 0 = Autopilot Cruise, 1 = Asteroid Cutscene Alert, 2 = Manual Evasion Driving, 3 = Autopilot Restored
var _phase: int = 0
var _encounter_id: StringName = &"bridge_flight_piloting"
var _is_emergency_interception: bool = false
var _phase_timer: float = 0.0
var _total_time: float = 0.0
var _evasion_duration: float = 18.0
var _evasion_elapsed: float = 0.0

var _root: Control = null
var _viewport_ctrl: Control = null
var _mode_badge: Label = null
var _comms_speaker_label: Label = null
var _comms_text_label: Label = null
var _hull_bar: ProgressBar = null
var _hull_label: Label = null
var _progress_bar: ProgressBar = null
var _progress_label: Label = null
var _controls_hint_label: Label = null
var _action_button: Button = null
var _close_button: Button = null

# Ship driving state inside the 860x360 cockpit flight corridor
const VIEW_SIZE: Vector2 = Vector2(860.0, 360.0)
var _ship_pos: Vector2 = Vector2(145.0, 180.0)
var _ship_vel: Vector2 = Vector2.ZERO
var _ship_tilt: float = 0.0
var _hull_integrity: float = 100.0
var _hit_flash_timer: float = 0.0
var _pulse_cooldown: float = 0.0

var _stars: Array[Dictionary] = []
var _asteroids: Array[Dictionary] = []
var _pulses: Array[Dictionary] = []
var _debris_particles: Array[Dictionary] = []
var _spawn_accum: float = 0.0


func setup(encounter_id: StringName = &"bridge_flight_piloting", emergency_interception: bool = false) -> void:
	_encounter_id = encounter_id
	_is_emergency_interception = emergency_interception
	_evasion_duration = 16.0 if emergency_interception else 18.0


func _ready() -> void:
	layer = 26
	_init_starfield()
	_build_ui()
	_start_autopilot_or_alert_sequence()
	set_process(true)
	set_process_unhandled_input(true)


func _hash_unit(index: int, salt: float) -> float:
	var v: float = sin(float(index) * 12.9898 + salt * 78.233) * 43758.5453
	return v - floorf(v)


func _init_starfield() -> void:
	_stars.clear()
	for i in range(95):
		var layer_idx: int = i % 3
		var spd: float = 55.0 if layer_idx == 0 else (125.0 if layer_idx == 1 else 240.0)
		var sz: float = 1.0 if layer_idx == 0 else (1.5 if layer_idx == 1 else 2.2)
		_stars.append({
			"pos": Vector2(_hash_unit(i, 1.3) * VIEW_SIZE.x, _hash_unit(i, 2.7) * VIEW_SIZE.y),
			"speed": spd,
			"size": sz,
			"layer": layer_idx,
		})


func _build_ui() -> void:
	_root = Control.new()
	SKIN.apply(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dimmer: ColorRect = ColorRect.new()
	dimmer.color = Color(0.005, 0.012, 0.022, 0.90)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dimmer)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(920.0, 610.0)
	panel.add_theme_stylebox_override("panel", SKIN.panel(20.0))
	center.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Header bar
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	var title_lbl: Label = _make_label("ASTERIA-1 // BRIDGE HELM & AUTOPILOT NAVIGATION", 16, GOLD)
	header.add_child(title_lbl)
	header.add_spacer(false)
	_mode_badge = _make_label("[ AUTOPILOT: ENGAGED ]", 14, GREEN)
	header.add_child(_mode_badge)
	_close_button = Button.new()
	_close_button.text = "[ LEAVE HELM ]"
	_close_button.custom_minimum_size = Vector2(130.0, 32.0)
	_close_button.add_theme_font_size_override("font_size", 12)
	_close_button.pressed.connect(_on_close_pressed)
	header.add_child(_close_button)
	vbox.add_child(header)

	# Telemetry bars row (Hull Integrity & Corridor Progress)
	var telem_row: HBoxContainer = HBoxContainer.new()
	telem_row.add_theme_constant_override("separation", 18)

	var hull_box: HBoxContainer = HBoxContainer.new()
	hull_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hull_box.add_theme_constant_override("separation", 8)
	hull_box.add_child(_make_label("HULL INTEGRITY:", 12, PALE))
	_hull_bar = ProgressBar.new()
	_hull_bar.min_value = 0.0
	_hull_bar.max_value = 100.0
	_hull_bar.value = 100.0
	_hull_bar.show_percentage = false
	_hull_bar.custom_minimum_size = Vector2(160.0, 18.0)
	_hull_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hull_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hull_box.add_child(_hull_bar)
	_hull_label = _make_label("100%", 12, GREEN)
	hull_box.add_child(_hull_label)
	telem_row.add_child(hull_box)

	var prog_box: HBoxContainer = HBoxContainer.new()
	prog_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_box.add_theme_constant_override("separation", 8)
	prog_box.add_child(_make_label("DEBRIS CORRIDOR:", 12, PALE))
	_progress_bar = ProgressBar.new()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(160.0, 18.0)
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prog_box.add_child(_progress_bar)
	_progress_label = _make_label("AUTOPILOT CRUISE", 12, CYAN)
	prog_box.add_child(_progress_label)
	telem_row.add_child(prog_box)

	vbox.add_child(telem_row)

	# Forward Bridge Cockpit Viewport Frame
	var view_frame: PanelContainer = PanelContainer.new()
	view_frame.custom_minimum_size = VIEW_SIZE + Vector2(16.0, 16.0)
	view_frame.add_theme_stylebox_override("panel", SKIN.panel(8.0, true))
	vbox.add_child(view_frame)

	_viewport_ctrl = Control.new()
	_viewport_ctrl.custom_minimum_size = VIEW_SIZE
	_viewport_ctrl.size = VIEW_SIZE
	_viewport_ctrl.clip_contents = true
	_viewport_ctrl.draw.connect(_on_viewport_draw)
	view_frame.add_child(_viewport_ctrl)

	# Bridge Comms & Cutscene Narrative Box
	var comms_panel: PanelContainer = PanelContainer.new()
	comms_panel.custom_minimum_size = Vector2(0.0, 92.0)
	comms_panel.add_theme_stylebox_override("panel", SKIN.panel(12.0, true))
	vbox.add_child(comms_panel)

	var comms_vbox: VBoxContainer = VBoxContainer.new()
	comms_vbox.add_theme_constant_override("separation", 4)
	comms_panel.add_child(comms_vbox)

	_comms_speaker_label = _make_label("ELIAS WARD // PILOT & NAVIGATION OFFICER", 12, CYAN)
	comms_vbox.add_child(_comms_speaker_label)

	_comms_text_label = _make_label("", 14, PALE)
	_comms_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comms_vbox.add_child(_comms_text_label)

	# Footer controls & action button
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	_controls_hint_label = _make_label("STEER: [WASD / ARROWS]   ·   PULSE DEFLECTOR: [SPACE / LEFT CLICK]", 12, GOLD)
	footer.add_child(_controls_hint_label)
	footer.add_spacer(false)
	_action_button = Button.new()
	_action_button.text = "[ ENGAGE MANUAL OVERRIDE ]"
	_action_button.custom_minimum_size = Vector2(240.0, 40.0)
	_action_button.add_theme_font_size_override("font_size", 13)
	_action_button.pressed.connect(_on_action_button_pressed)
	footer.add_child(_action_button)
	vbox.add_child(footer)


func _start_autopilot_or_alert_sequence() -> void:
	_ship_pos = Vector2(145.0, VIEW_SIZE.y * 0.5)
	_ship_vel = Vector2.ZERO
	_hull_integrity = 100.0
	_evasion_elapsed = 0.0
	_asteroids.clear()
	_pulses.clear()
	_debris_particles.clear()

	if _is_emergency_interception:
		# Jump straight into the Asteroid Cutscene Alert when triggered mid-cruise!
		_enter_phase(1)
	else:
		# Start in smooth Autopilot Cruise for 3.2 seconds, then trigger the Asteroid Cutscene Alert!
		_enter_phase(0)


func _enter_phase(new_phase: int) -> void:
	_phase = new_phase
	_phase_timer = 0.0
	match _phase:
		0:
			_mode_badge.text = "[ AUTOPILOT: CRUISE LOCKED ]"
			_mode_badge.add_theme_color_override("font_color", GREEN)
			_comms_speaker_label.text = "ELIAS WARD // BRIDGE FLIGHT DECK"
			_comms_speaker_label.add_theme_color_override("font_color", CYAN)
			_comms_text_label.text = "\"Autopilot is holding Asteria-1 on the orbital approach vector toward Erebos. Velocity steady at 14.2 km/s... Wait — lidar is picking up high-velocity Shearwater belt fragments ahead!\""
			_action_button.visible = true
			_action_button.text = "[ TAKE MANUAL HELM NOW ]"
			_close_button.visible = true
		1:
			_mode_badge.text = "[ ⚠ PROXIMITY ALERT — AUTOPILOT DISENGAGED ]"
			_mode_badge.add_theme_color_override("font_color", ALERT_RED)
			_comms_speaker_label.text = "⚠ COLLISION WARNING // ASTEROID SWARM CUTSCENE"
			_comms_speaker_label.add_theme_color_override("font_color", ALERT_RED)
			_comms_text_label.text = "DENSE EREBOS ASTEROID SWARM DETECTED IN FLIGHT CORRIDOR!\nAutopilot thrusters cannot compute a safe path through the tumbling ore fragments.\nELIAS WARD: \"Thura, grab the auxiliary helm controls! Steer us clear with [WASD / Arrows] and fire the bow deflector with [Space / Click]!\""
			_action_button.visible = true
			_action_button.text = "[ ENGAGE MANUAL EVASION  › ]"
			_close_button.visible = false
		2:
			_mode_badge.text = "[ MANUAL HELM CONTROL ACTIVE ]"
			_mode_badge.add_theme_color_override("font_color", ORANGE)
			_comms_speaker_label.text = "MANUAL EVASION // DODGE & SHATTER INCOMING ASTEROIDS"
			_comms_speaker_label.add_theme_color_override("font_color", GOLD)
			_comms_text_label.text = "Use [W/A/S/D] or [Arrow Keys] to steer Asteria-1 around incoming asteroids! Press [Space] or [Left Click] to fire the bow Pulse Deflector and shatter rocks in your path!"
			_action_button.visible = false
			_close_button.visible = false
		3:
			_mode_badge.text = "[ AUTOPILOT: RESTORED & NOMINAL ]"
			_mode_badge.add_theme_color_override("font_color", GREEN)
			_comms_speaker_label.text = "ELIAS WARD & COMMANDER CHEN // BRIDGE INTERCOM"
			_comms_speaker_label.add_theme_color_override("font_color", GREEN)
			_comms_text_label.text = "\"We're clear of the asteroid swarm! Autopilot has re-acquired the Erebos orbital lock and resumed steady cruise. Outstanding flying, Thura.\""
			_action_button.visible = true
			_action_button.text = "[ RETURN TO SHIP DECK  → ]"
			_close_button.visible = true


func _on_action_button_pressed() -> void:
	if _phase == 0:
		_enter_phase(1)
	elif _phase == 1:
		_enter_phase(2)
	elif _phase == 3:
		_finish_and_close()


func _on_close_pressed() -> void:
	if _phase == 3:
		_finish_and_close()
	else:
		piloting_closed.emit()
		queue_free()


func _finish_and_close() -> void:
	piloting_completed.emit(_encounter_id, _hull_integrity)
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if _phase == 0 or _phase == 1 or _phase == 3:
				_on_action_button_pressed()
				get_viewport().set_input_as_handled()
				return
			elif _phase == 2:
				_fire_bow_deflector()
				get_viewport().set_input_as_handled()
				return
		elif event.keycode == KEY_ESCAPE and _phase != 2:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _phase == 2:
			_fire_bow_deflector()


func _fire_bow_deflector() -> void:
	if _pulse_cooldown > 0.0:
		return
	_pulse_cooldown = 0.28
	_pulses.append({
		"pos": _ship_pos + Vector2(36.0, 0.0),
		"vel": Vector2(540.0, 0.0),
		"radius": 8.0,
	})


func _spawn_asteroid() -> void:
	var radius: float = 14.0 + _hash_unit(int(_total_time * 37.0) + _asteroids.size(), 4.1) * 18.0
	var spawn_y: float = clampf(
		28.0 + _hash_unit(int(_total_time * 53.0) + _asteroids.size() * 7, 6.3) * (VIEW_SIZE.y - 56.0),
		radius + 10.0,
		VIEW_SIZE.y - radius - 10.0
	)
	# Aim 40% of asteroids roughly toward the ship's current lane so the player is forced to actively dodge!
	if _asteroids.size() % 2 == 0:
		spawn_y = clampf(_ship_pos.y + (fposmod(_total_time * 83.0, 90.0) - 45.0), radius + 12.0, VIEW_SIZE.y - radius - 12.0)

	var spd_x: float = -(210.0 + _hash_unit(_asteroids.size(), _total_time) * 145.0)
	var spd_y: float = (_hash_unit(_asteroids.size() + 3, _total_time * 1.7) - 0.5) * 55.0

	var pts: PackedVector2Array = PackedVector2Array()
	var verts: int = 9
	for v in range(verts):
		var ang: float = float(v) * (TAU / float(verts))
		var r_var: float = radius * (0.76 + 0.34 * _hash_unit(v + _asteroids.size() * 5, float(v) * 1.9))
		pts.append(Vector2(cos(ang) * r_var, sin(ang) * r_var))

	_asteroids.append({
		"pos": Vector2(VIEW_SIZE.x + radius + 24.0, spawn_y),
		"vel": Vector2(spd_x, spd_y),
		"radius": radius,
		"rot": 0.0,
		"rot_speed": (_hash_unit(_asteroids.size(), 9.2) - 0.5) * 3.8,
		"points": pts,
		"ore_color": CYAN if (_asteroids.size() % 3 == 0) else ORANGE,
	})


func _process(delta: float) -> void:
	_total_time += delta
	_phase_timer += delta
	if _hit_flash_timer > 0.0:
		_hit_flash_timer = maxf(_hit_flash_timer - delta * 3.2, 0.0)
	if _pulse_cooldown > 0.0:
		_pulse_cooldown = maxf(_pulse_cooldown - delta, 0.0)

	# Advance stars
	var speed_mult: float = 1.65 if _phase == 2 else 1.0
	for i in range(_stars.size()):
		var st: Dictionary = _stars[i]
		var spos: Vector2 = st["pos"]
		spos.x -= float(st["speed"]) * speed_mult * delta
		if spos.x < 0.0:
			spos.x += VIEW_SIZE.x
			spos.y = _hash_unit(i + int(_total_time * 10.0), 3.7) * VIEW_SIZE.y
		st["pos"] = spos

	if _phase == 0:
		# Smooth autopilot cruise bobbing
		var target_y: float = VIEW_SIZE.y * 0.5 + sin(_total_time * 1.5) * 18.0
		_ship_pos.y = lerpf(_ship_pos.y, target_y, delta * 3.0)
		_ship_tilt = sin(_total_time * 1.5) * 0.06
		_progress_bar.value = minf((_phase_timer / 3.4) * 20.0, 20.0)
		_progress_label.text = "AUTOPILOT CRUISE"
		if _phase_timer >= 3.4:
			_enter_phase(1)

	elif _phase == 1:
		# Cutscene alert klaxon — spawn preview asteroids at far right edge
		_ship_pos.y = lerpf(_ship_pos.y, VIEW_SIZE.y * 0.5, delta * 4.0)
		_ship_tilt = sin(_total_time * 8.0) * 0.05
		if _phase_timer >= 2.8:
			_enter_phase(2)

	elif _phase == 2:
		_evasion_elapsed += delta
		var pct: float = clampf((_evasion_elapsed / _evasion_duration) * 100.0, 0.0, 100.0)
		_progress_bar.value = pct
		_progress_label.text = "%d%% CLEARED" % roundi(pct)

		# Player steering input (WASD / Arrow keys)
		var input_dir: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		var target_vel: Vector2 = input_dir * 235.0
		_ship_vel = _ship_vel.lerp(target_vel, delta * 10.0)
		_ship_pos += _ship_vel * delta
		_ship_pos.x = clampf(_ship_pos.x, 70.0, 380.0)
		_ship_pos.y = clampf(_ship_pos.y, 38.0, VIEW_SIZE.y - 38.0)
		_ship_tilt = clampf(_ship_vel.y / 235.0, -1.0, 1.0) * 0.28

		if Input.is_key_pressed(KEY_SPACE) and _pulse_cooldown <= 0.0:
			_fire_bow_deflector()

		# Spawn asteroids during manual evasion
		_spawn_accum += delta
		var spawn_interval: float = 0.52
		if _spawn_accum >= spawn_interval and _evasion_elapsed < _evasion_duration - 1.5:
			_spawn_accum = 0.0
			_spawn_asteroid()

		_update_asteroids_and_collisions(delta)

		if _evasion_elapsed >= _evasion_duration and _asteroids.is_empty():
			_enter_phase(3)
		elif _evasion_elapsed >= _evasion_duration + 2.2:
			_asteroids.clear()
			_enter_phase(3)

	elif _phase == 3:
		_ship_pos = _ship_pos.lerp(Vector2(165.0, VIEW_SIZE.y * 0.5), delta * 3.5)
		_ship_tilt = lerpf(_ship_tilt, 0.0, delta * 5.0)
		_progress_bar.value = 100.0
		_progress_label.text = "AUTOPILOT LOCKED"
		_update_asteroids_and_collisions(delta)

	if is_instance_valid(_viewport_ctrl):
		_viewport_ctrl.queue_redraw()


func _update_asteroids_and_collisions(delta: float) -> void:
	# Update bow deflector pulses
	var p_idx: int = _pulses.size() - 1
	while p_idx >= 0:
		var p: Dictionary = _pulses[p_idx]
		var ppos: Vector2 = (p["pos"] as Vector2) + (p["vel"] as Vector2) * delta
		p["pos"] = ppos
		if ppos.x > VIEW_SIZE.x + 20.0:
			_pulses.remove_at(p_idx)
		p_idx -= 1

	# Update asteroids
	var a_idx: int = _asteroids.size() - 1
	while a_idx >= 0:
		var ast: Dictionary = _asteroids[a_idx]
		var apos: Vector2 = (ast["pos"] as Vector2) + (ast["vel"] as Vector2) * delta
		var arad: float = float(ast["radius"])
		ast["pos"] = apos
		ast["rot"] = float(ast["rot"]) + float(ast["rot_speed"]) * delta

		# Check pulse deflector hit
		var destroyed: bool = false
		var k: int = _pulses.size() - 1
		while k >= 0:
			var p: Dictionary = _pulses[k]
			var ppos: Vector2 = p["pos"]
			if apos.distance_to(ppos) <= arad + 12.0:
				_spawn_debris_burst(apos, ast["ore_color"])
				_pulses.remove_at(k)
				_asteroids.remove_at(a_idx)
				destroyed = true
				break
			k -= 1
		if destroyed:
			a_idx -= 1
			continue

		# Check collision with Asteria-1 hull
		if apos.distance_to(_ship_pos) <= arad + 20.0:
			_spawn_debris_burst(apos, ALERT_RED)
			_asteroids.remove_at(a_idx)
			_hit_flash_timer = 1.0
			_hull_integrity = maxf(_hull_integrity - 16.0, 15.0)
			_hull_bar.value = _hull_integrity
			_hull_label.text = "%d%%" % roundi(_hull_integrity)
			_hull_label.add_theme_color_override("font_color", ALERT_RED if _hull_integrity < 50.0 else ORANGE)
			if _hull_integrity <= 20.0:
				_comms_text_label.text = "⚠ HULL SHIELD CRITICAL! Emergency thrusters stabilizing — evade the remaining rocks!"
			a_idx -= 1
			continue

		if apos.x < -arad - 30.0:
			_asteroids.remove_at(a_idx)
		a_idx -= 1

	# Update debris burst particles
	var d_idx: int = _debris_particles.size() - 1
	while d_idx >= 0:
		var dp: Dictionary = _debris_particles[d_idx]
		var t: float = float(dp["timer"]) - delta
		if t <= 0.0:
			_debris_particles.remove_at(d_idx)
		else:
			dp["timer"] = t
			dp["pos"] = (dp["pos"] as Vector2) + (dp["vel"] as Vector2) * delta
		d_idx -= 1


func _spawn_debris_burst(origin_pos: Vector2, accent_col: Color) -> void:
	for i in range(10):
		var ang: float = float(i) * (TAU / 10.0) + _total_time
		var spd: float = 45.0 + float(i % 4) * 32.0
		_debris_particles.append({
			"pos": origin_pos,
			"vel": Vector2(cos(ang) * spd, sin(ang) * spd),
			"color": accent_col,
			"timer": 0.45,
			"max_timer": 0.45,
		})


func _on_viewport_draw() -> void:
	if not is_instance_valid(_viewport_ctrl):
		return

	# 1. Deep-space background & nebula haze
	_viewport_ctrl.draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.012, 0.022, 0.038, 1.0), true)
	_viewport_ctrl.draw_circle(Vector2(VIEW_SIZE.x * 0.72, VIEW_SIZE.y * 0.42), 185.0, Color(0.08, 0.26, 0.44, 0.14))
	_viewport_ctrl.draw_circle(Vector2(VIEW_SIZE.x * 0.35, VIEW_SIZE.y * 0.68), 145.0, Color(0.22, 0.14, 0.38, 0.10))

	# Distant minor planet Erebos on the right horizon
	var erebos_center: Vector2 = Vector2(VIEW_SIZE.x - 115.0, VIEW_SIZE.y * 0.5)
	_viewport_ctrl.draw_circle(erebos_center, 68.0, Color(0.08, 0.12, 0.16, 0.95))
	_viewport_ctrl.draw_arc(erebos_center, 69.0, PI * 0.55, PI * 1.45, 28, Color(0.36, 0.84, 0.96, 0.45), 2.2, true)
	# Pulsing Site K-12 beacon on Erebos
	var k12_pos: Vector2 = erebos_center + Vector2(-24.0, -12.0)
	var k12_pulse: float = 0.5 + 0.5 * sin(_total_time * 4.0)
	_viewport_ctrl.draw_circle(k12_pos, 3.0 + 2.5 * k12_pulse, Color(1.0, 0.44, 0.24, 0.35 * k12_pulse))
	_viewport_ctrl.draw_circle(k12_pos, 1.8, Color(1.0, 0.68, 0.32, 0.92))

	# 2. Parallax stars
	for st in _stars:
		var spos: Vector2 = st["pos"]
		var sz: float = float(st["size"])
		var l_idx: int = int(st["layer"])
		var scol: Color = Color(0.68, 0.84, 1.0, 0.45 if l_idx == 0 else (0.72 if l_idx == 1 else 0.95))
		if _phase == 2 and l_idx == 2:
			_viewport_ctrl.draw_line(spos, spos + Vector2(12.0, 0.0), Color(scol.r, scol.g, scol.b, 0.42), 1.2, true)
		_viewport_ctrl.draw_circle(spos, sz, scol)

	# 3. Autopilot guidance corridor lanes (green/cyan when autopilot, flashing orange/red during asteroid override)
	var lane_col: Color = Color(0.28, 0.88, 0.72, 0.22) if (_phase == 0 or _phase == 3) else Color(1.0, 0.52, 0.24, 0.24)
	_viewport_ctrl.draw_line(Vector2(0.0, 32.0), Vector2(VIEW_SIZE.x, 32.0), lane_col, 1.2, false)
	_viewport_ctrl.draw_line(Vector2(0.0, VIEW_SIZE.y - 32.0), Vector2(VIEW_SIZE.x, VIEW_SIZE.y - 32.0), lane_col, 1.2, false)
	if _phase == 0 or _phase == 3:
		var chevron_x: float = fposmod(-_total_time * 120.0, 90.0)
		while chevron_x < VIEW_SIZE.x:
			var cy: float = VIEW_SIZE.y * 0.5
			_viewport_ctrl.draw_line(Vector2(chevron_x, cy - 12.0), Vector2(chevron_x + 12.0, cy), lane_col, 1.5, true)
			_viewport_ctrl.draw_line(Vector2(chevron_x + 12.0, cy), Vector2(chevron_x, cy + 12.0), lane_col, 1.5, true)
			chevron_x += 90.0

	# 4. Bow Pulse Deflector projectiles
	for p in _pulses:
		var ppos: Vector2 = p["pos"]
		_viewport_ctrl.draw_circle(ppos, 9.0, Color(0.36, 0.92, 1.0, 0.28))
		_viewport_ctrl.draw_arc(ppos, 7.5, -0.8, 0.8, 12, Color(0.55, 0.96, 1.0, 0.95), 2.4, true)
		_viewport_ctrl.draw_circle(ppos, 3.2, Color(0.96, 1.0, 1.0, 0.98))

	# 5. Incoming Asteroids with warning trajectory vectors & ore veins
	for ast in _asteroids:
		var apos: Vector2 = ast["pos"]
		var arot: float = float(ast["rot"])
		var arad: float = float(ast["radius"])
		var raw_pts: PackedVector2Array = ast["points"]
		var ocol: Color = ast["ore_color"]

		# Red collision vector line ahead of incoming asteroid
		_viewport_ctrl.draw_line(apos - Vector2(arad + 48.0, 0.0), apos - Vector2(arad + 4.0, 0.0), Color(1.0, 0.34, 0.28, 0.26), 1.0, false)

		var xform_pts: PackedVector2Array = PackedVector2Array()
		for pt in raw_pts:
			xform_pts.append(apos + pt.rotated(arot))
		_viewport_ctrl.draw_colored_polygon(xform_pts, Color(0.22, 0.24, 0.28, 1.0))
		xform_pts.append(xform_pts[0])
		_viewport_ctrl.draw_polyline(xform_pts, Color(0.46, 0.50, 0.56, 0.95), 2.0, true)

		# Glowing Erebos mineral vein & crater inside the asteroid
		var vein_a: Vector2 = apos + Vector2(-arad * 0.35, -arad * 0.2).rotated(arot)
		var vein_b: Vector2 = apos + Vector2(arad * 0.3, arad * 0.25).rotated(arot)
		_viewport_ctrl.draw_line(vein_a, vein_b, Color(ocol.r, ocol.g, ocol.b, 0.85), 2.0, true)
		_viewport_ctrl.draw_circle(apos + Vector2(arad * 0.2, -arad * 0.25).rotated(arot), arad * 0.22, Color(0.12, 0.14, 0.18, 0.92))

	# 6. Shattered asteroid debris particles
	for dp in _debris_particles:
		var dpos: Vector2 = dp["pos"]
		var dcol: Color = dp["color"]
		var dnorm: float = clampf(float(dp["timer"]) / float(dp["max_timer"]), 0.0, 1.0)
		_viewport_ctrl.draw_circle(dpos, 2.6 * dnorm, Color(dcol.r, dcol.g, dcol.b, dnorm))

	# 7. Draw Spacecraft Asteria-1 (with banking tilt, engine plumes, hull plating, and deflector shield)
	_draw_asteria_ship()

	# 8. Emergency klaxon border flash during Phase 1 (Asteroid Cutscene Alert) or hull impact
	if _phase == 1 or _hit_flash_timer > 0.01:
		var klaxon_alpha: float = (0.35 + 0.35 * sin(_total_time * 10.0)) if _phase == 1 else (_hit_flash_timer * 0.55)
		_viewport_ctrl.draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(1.0, 0.22, 0.18, klaxon_alpha * 0.22), true)
		_viewport_ctrl.draw_rect(Rect2(Vector2(2.0, 2.0), VIEW_SIZE - Vector2(4.0, 4.0)), Color(1.0, 0.28, 0.22, klaxon_alpha), false, 3.0)


func _draw_asteria_ship() -> void:
	var p: Vector2 = _ship_pos
	var t_ang: float = _ship_tilt

	# Twin aft plasma engine plumes
	var plume_len: float = 28.0 + 10.0 * sin(_total_time * 24.0) + (_ship_vel.x * 0.05)
	var u_eng: Vector2 = p + Vector2(-28.0, -9.0).rotated(t_ang)
	var l_eng: Vector2 = p + Vector2(-28.0, 9.0).rotated(t_ang)
	var back_dir: Vector2 = Vector2(-1.0, 0.0).rotated(t_ang)
	_viewport_ctrl.draw_line(u_eng, u_eng + back_dir * plume_len, Color(0.28, 0.84, 1.0, 0.45), 6.0, true)
	_viewport_ctrl.draw_line(u_eng, u_eng + back_dir * (plume_len * 0.65), Color(0.92, 0.98, 1.0, 0.95), 2.8, true)
	_viewport_ctrl.draw_line(l_eng, l_eng + back_dir * plume_len, Color(0.28, 0.84, 1.0, 0.45), 6.0, true)
	_viewport_ctrl.draw_line(l_eng, l_eng + back_dir * (plume_len * 0.65), Color(0.92, 0.98, 1.0, 0.95), 2.8, true)

	# Asteria-1 Valkyrie hull silhouette
	var hull_local: Array[Vector2] = [
		Vector2(32.0, 0.0),
		Vector2(14.0, -12.0),
		Vector2(-18.0, -16.0),
		Vector2(-28.0, -11.0),
		Vector2(-24.0, 0.0),
		Vector2(-28.0, 11.0),
		Vector2(-18.0, 16.0),
		Vector2(14.0, 12.0),
	]
	var hull_pts: PackedVector2Array = PackedVector2Array()
	for hp in hull_local:
		hull_pts.append(p + hp.rotated(t_ang))
	_viewport_ctrl.draw_colored_polygon(hull_pts, Color(0.76, 0.80, 0.86, 1.0))
	hull_pts.append(hull_pts[0])
	_viewport_ctrl.draw_polyline(hull_pts, Color(0.22, 0.28, 0.34, 1.0), 2.0, true)

	# Bridge cockpit canopy glow & forward deflector emitter
	var bridge_pt: Vector2 = p + Vector2(14.0, 0.0).rotated(t_ang)
	_viewport_ctrl.draw_circle(bridge_pt, 4.5, Color(0.24, 0.78, 0.96, 0.95))
	_viewport_ctrl.draw_arc(p, 34.0, -0.65, 0.65, 16, Color(0.36, 0.90, 1.0, 0.25), 1.4, true)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", maxi(12, font_size))
	lbl.add_theme_color_override("font_color", color)
	return lbl
