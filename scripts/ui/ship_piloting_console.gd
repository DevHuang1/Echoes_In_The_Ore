class_name ShipPilotingConsole
extends CanvasLayer

signal piloting_completed(encounter_id: StringName, hull_remaining: float)
signal piloting_closed()

const THEME_RES: Theme = preload("res://themes/ship_pixel_theme.tres")

const GOLD: Color = Color(1.0, 0.78, 0.38, 1.0)
const PALE: Color = Color(0.95, 0.92, 0.84, 1.0)
const MUTED: Color = Color(0.66, 0.76, 0.80, 1.0)
const CYAN: Color = Color(0.36, 0.90, 1.0, 1.0)
const ORANGE: Color = Color(1.0, 0.68, 0.32, 1.0)
const GREEN: Color = Color(0.48, 0.93, 0.64, 1.0)
const ALERT_RED: Color = Color(1.0, 0.34, 0.30, 1.0)

# Mission IDs
const MISSION_ASTEROIDS: StringName = &"bridge_flight_piloting"
const MISSION_STAR_VEER: StringName = &"star_veering"
const MISSION_BLACK_HOLE: StringName = &"black_hole_slingshot"
const MISSION_LANDING: StringName = &"erebos_orbital_landing"

class CockpitHudCanvas extends Control:
	var console: ShipPilotingConsole = null
	func _draw() -> void:
		if is_instance_valid(console):
			console.render_hud_elements(self)

# Phases: 0 = Autopilot Cruise, 1 = Encounter Alert / Cutscene, 2 = 3D Manual Flight, 3 = Cleared / Success, 4 = Emergency Reset Prompt
var _phase: int = 0
var _encounter_id: StringName = MISSION_ASTEROIDS
var _is_emergency_interception: bool = false
var _phase_timer: float = 0.0
var _total_time: float = 0.0
var _flight_duration: float = 20.0
var _flight_elapsed: float = 0.0

# UI Controls
var _root: Control = null
var _vp_container: SubViewportContainer = null
var _sub_vp: SubViewport = null
var _hud_overlay: Control = null
var _mode_badge: Label = null
var _comms_speaker_label: Label = null
var _comms_text_label: Label = null
var _hull_bar: ProgressBar = null
var _hull_label: Label = null
var _metric_bar: ProgressBar = null
var _metric_title_label: Label = null
var _metric_value_label: Label = null
var _controls_hint_label: Label = null
var _action_button: Button = null
var _close_button: Button = null
var _mission_select_btn: Button = null
var _mission_select_menu: PopupMenu = null

# Viewport sizing
const VIEW_SIZE: Vector2 = Vector2(860.0, 360.0)

# 3D Flight & Camera State
var _world_3d: Node3D = null
var _cam_3d: Camera3D = null
var _dir_light: DirectionalLight3D = null
var _flight_pos: Vector3 = Vector3.ZERO # Lateral X, Vertical Y, Forward Z (virtual)
var _flight_vel: Vector3 = Vector3.ZERO
var _cam_rot: Vector3 = Vector3.ZERO # Pitch X, Yaw Y, Roll Z
var _hull_integrity: float = 100.0
var _hit_flash_timer: float = 0.0
var _pulse_cooldown: float = 0.0
var _thruster_boost: float = 1.0

# Task Specific Mechanics
# Star Veering:
var _core_heat: float = 20.0 # 0% - 100%
var _coolant_cooldown: float = 0.0
# Black Hole:
var _gravity_drag: float = 0.0
var _escape_velocity_pct: float = 0.0
# Asteroids:
var _asteroids_shattered: int = 0

# 3D Objects in Scene
var _stars_3d: Array[Dictionary] = []
var _asteroids_3d: Array[Dictionary] = []
var _pulses_3d: Array[Dictionary] = []
var _gates_3d: Array[Dictionary] = []
var _sun_mesh: MeshInstance3D = null
var _black_hole_root: Node3D = null
var _sun_flares: Array[Node3D] = []
var _debris_bursts: Array[Dictionary] = []
var _spawn_timer: float = 0.0


func setup(encounter_id: StringName = MISSION_ASTEROIDS, emergency_interception: bool = false) -> void:
	_encounter_id = encounter_id
	_is_emergency_interception = emergency_interception
	_flight_duration = 18.0 if emergency_interception else 22.0
	if _world_3d != null:
		_start_encounter_sequence()


func _ready() -> void:
	layer = 26
	_build_ui()
	_init_3d_flight_scene()
	_start_encounter_sequence()
	set_process(true)
	set_process_unhandled_input(true)


func _make_panel_style(bg_col: Color, border_col: Color, pad: float) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(2)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	return sb


func _make_label(txt: String, f_size: int, col: Color) -> Label:
	var lbl: Label = Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", f_size)
	lbl.add_theme_color_override("font_color", col)
	return lbl


func _build_ui() -> void:
	_root = Control.new()
	_root.theme = THEME_RES
	_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	panel.custom_minimum_size = Vector2(920.0, 620.0)
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.024, 0.046, 0.068, 0.98), Color(0.34, 0.54, 0.62, 0.96), 18.0))
	center.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Header bar with Mission Log Selector
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	var title_lbl: Label = _make_label("ASTERIA-1 // 3D FIRST-PERSON BRIDGE HELM", 15, GOLD)
	header.add_child(title_lbl)
	header.add_spacer(false)

	_mission_select_btn = Button.new()
	_mission_select_btn.text = "[ FLIGHT SECTOR LOG ▾ ]"
	_mission_select_btn.focus_mode = Control.FOCUS_NONE
	_mission_select_btn.custom_minimum_size = Vector2(170.0, 30.0)
	_mission_select_btn.add_theme_font_size_override("font_size", 11)
	_mission_select_btn.pressed.connect(_on_mission_select_pressed)
	header.add_child(_mission_select_btn)

	_mission_select_menu = PopupMenu.new()
	_mission_select_menu.add_item("1. Shearwater Asteroids (Evasion & Shatter)", 0)
	_mission_select_menu.add_item("2. Helios Corona (Star Veering & Coolant)", 1)
	_mission_select_menu.add_item("3. Gargantua Singularity (Vortex Slingshot)", 2)
	_mission_select_menu.add_item("4. Erebos Descent (Atmospheric Landing)", 3)
	_mission_select_menu.id_pressed.connect(_on_mission_menu_item_selected)
	add_child(_mission_select_menu)

	_mode_badge = _make_label("[ 3D COCKPIT: AUTOPILOT ]", 13, GREEN)
	header.add_child(_mode_badge)

	_close_button = Button.new()
	_close_button.text = "[ LEAVE HELM ]"
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.custom_minimum_size = Vector2(120.0, 30.0)
	_close_button.add_theme_font_size_override("font_size", 11)
	_close_button.pressed.connect(_on_close_pressed)
	header.add_child(_close_button)
	vbox.add_child(header)

	# Telemetry row (Hull Integrity & Task Specific Metric)
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
	_hull_bar.custom_minimum_size = Vector2(150.0, 16.0)
	_hull_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hull_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hull_box.add_child(_hull_bar)
	_hull_label = _make_label("100%", 12, GREEN)
	hull_box.add_child(_hull_label)
	telem_row.add_child(hull_box)

	var metric_box: HBoxContainer = HBoxContainer.new()
	metric_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metric_box.add_theme_constant_override("separation", 8)
	_metric_title_label = _make_label("TASK TELEMETRY:", 12, PALE)
	metric_box.add_child(_metric_title_label)
	_metric_bar = ProgressBar.new()
	_metric_bar.min_value = 0.0
	_metric_bar.max_value = 100.0
	_metric_bar.value = 0.0
	_metric_bar.show_percentage = false
	_metric_bar.custom_minimum_size = Vector2(150.0, 16.0)
	_metric_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_metric_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	metric_box.add_child(_metric_bar)
	_metric_value_label = _make_label("CRUISE", 12, CYAN)
	metric_box.add_child(_metric_value_label)
	telem_row.add_child(metric_box)

	vbox.add_child(telem_row)

	# 3D Forward Bridge Cockpit Viewport Frame
	var view_frame: PanelContainer = PanelContainer.new()
	view_frame.custom_minimum_size = VIEW_SIZE + Vector2(16.0, 16.0)
	view_frame.add_theme_stylebox_override("panel", _make_panel_style(Color(0.008, 0.016, 0.028, 1.0), CYAN, 8.0))
	vbox.add_child(view_frame)

	# SubViewportContainer holding true 3D Cockpit
	_vp_container = SubViewportContainer.new()
	_vp_container.custom_minimum_size = VIEW_SIZE
	_vp_container.size = VIEW_SIZE
	_vp_container.stretch = true
	_vp_container.mouse_filter = Control.MOUSE_FILTER_PASS
	view_frame.add_child(_vp_container)

	_sub_vp = SubViewport.new()
	_sub_vp.size = Vector2i(int(VIEW_SIZE.x), int(VIEW_SIZE.y))
	_sub_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub_vp.own_world_3d = true
	_vp_container.add_child(_sub_vp)

	# Holographic Vector Cockpit HUD Overlay
	var hud_c: CockpitHudCanvas = CockpitHudCanvas.new()
	hud_c.console = self
	hud_c.custom_minimum_size = VIEW_SIZE
	hud_c.size = VIEW_SIZE
	hud_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_overlay = hud_c
	view_frame.add_child(_hud_overlay)

	# Bridge Comms & Narrative Box
	var comms_panel: PanelContainer = PanelContainer.new()
	comms_panel.custom_minimum_size = Vector2(0.0, 88.0)
	comms_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.016, 0.032, 0.050, 0.98), Color(0.28, 0.46, 0.54, 0.95), 12.0))
	vbox.add_child(comms_panel)

	var comms_vbox: VBoxContainer = VBoxContainer.new()
	comms_vbox.add_theme_constant_override("separation", 3)
	comms_panel.add_child(comms_vbox)

	_comms_speaker_label = _make_label("ELIAS WARD // PILOT & NAVIGATION OFFICER", 12, CYAN)
	comms_vbox.add_child(_comms_speaker_label)

	_comms_text_label = _make_label("", 13, PALE)
	_comms_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comms_vbox.add_child(_comms_text_label)

	# Footer controls & action button
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	_controls_hint_label = _make_label("STEER: [WASD / ARROWS / MOUSE]   ·   FIRE LASERS: [SPACE / LMB]   ·   THRUSTER BURST: [SHIFT]", 11, GOLD)
	footer.add_child(_controls_hint_label)
	footer.add_spacer(false)

	_action_button = Button.new()
	_action_button.text = "[ ENGAGE 3D MANUAL OVERRIDE ]"
	_action_button.focus_mode = Control.FOCUS_NONE
	_action_button.custom_minimum_size = Vector2(230.0, 36.0)
	_action_button.add_theme_font_size_override("font_size", 12)
	_action_button.pressed.connect(_on_action_button_pressed)
	footer.add_child(_action_button)
	vbox.add_child(footer)


func _on_mission_select_pressed() -> void:
	if is_instance_valid(_mission_select_menu):
		var pos: Vector2 = _mission_select_btn.global_position + Vector2(0.0, _mission_select_btn.size.y + 4.0)
		_mission_select_menu.position = Vector2i(int(pos.x), int(pos.y))
		_mission_select_menu.popup()


func _on_mission_menu_item_selected(id: int) -> void:
	match id:
		0: setup(MISSION_ASTEROIDS, false)
		1: setup(MISSION_STAR_VEER, false)
		2: setup(MISSION_BLACK_HOLE, false)
		3: setup(MISSION_LANDING, true)
	_start_encounter_sequence()


func _init_3d_flight_scene() -> void:
	_world_3d = Node3D.new()
	_world_3d.name = "FlightWorld3D"
	_sub_vp.add_child(_world_3d)

	# Camera looking along -Z
	_cam_3d = Camera3D.new()
	_cam_3d.fov = 76.0
	_cam_3d.near = 0.1
	_cam_3d.far = 2800.0
	_cam_3d.position = Vector3(0.0, 0.0, 0.0)
	_world_3d.add_child(_cam_3d)

	# Directional Light for 3D asteroids & ship
	_dir_light = DirectionalLight3D.new()
	_dir_light.rotation_degrees = Vector3(-35.0, -45.0, 0.0)
	_dir_light.light_energy = 1.3
	_world_3d.add_child(_dir_light)

	# 3D Starfield: 240 3D Stars streaming toward +Z
	_stars_3d.clear()
	var star_mesh: BoxMesh = BoxMesh.new()
	star_mesh.size = Vector3(0.65, 0.65, 3.2)
	var star_mat: StandardMaterial3D = StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.albedo_color = Color(0.85, 0.94, 1.0, 0.95)
	star_mesh.material = star_mat

	for i in range(240):
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = star_mesh
		var sx: float = (randf() - 0.5) * 550.0
		var sy: float = (randf() - 0.5) * 320.0
		var sz: float = -randf() * 1400.0
		mi.position = Vector3(sx, sy, sz)
		_world_3d.add_child(mi)
		_stars_3d.append({
			"node": mi,
			"speed": 180.0 + randf() * 220.0,
			"base_pos": Vector2(sx, sy),
		})


func _start_encounter_sequence() -> void:
	_flight_pos = Vector3.ZERO
	_flight_vel = Vector3.ZERO
	_cam_rot = Vector3.ZERO
	_hull_integrity = 100.0
	_flight_elapsed = 0.0
	_core_heat = 20.0
	_coolant_cooldown = 0.0
	_gravity_drag = 0.0
	_escape_velocity_pct = 0.0
	_asteroids_shattered = 0
	_spawn_timer = 0.0

	_clear_encounter_objects()
	_setup_encounter_3d_environment()

	if _is_emergency_interception:
		_enter_phase(1)
	else:
		_enter_phase(0)


func _clear_encounter_objects() -> void:
	for a in _asteroids_3d:
		if is_instance_valid(a.get("node")):
			a["node"].queue_free()
	_asteroids_3d.clear()

	for p in _pulses_3d:
		if is_instance_valid(p.get("node")):
			p["node"].queue_free()
	_pulses_3d.clear()

	for g in _gates_3d:
		if is_instance_valid(g.get("node")):
			g["node"].queue_free()
	_gates_3d.clear()

	if is_instance_valid(_sun_mesh):
		_sun_mesh.queue_free()
		_sun_mesh = null

	if is_instance_valid(_black_hole_root):
		_black_hole_root.queue_free()
		_black_hole_root = null

	_sun_flares.clear()
	_debris_bursts.clear()


func _setup_encounter_3d_environment() -> void:
	match _encounter_id:
		MISSION_ASTEROIDS:
			_dir_light.light_color = Color(0.85, 0.92, 1.0)
			_dir_light.light_energy = 1.2
			_metric_title_label.text = "DEBRIS CORRIDOR:"
			_metric_bar.max_value = 100.0
			_metric_bar.value = 0.0

		MISSION_STAR_VEER:
			_dir_light.light_color = Color(1.0, 0.72, 0.35)
			_dir_light.light_energy = 2.4
			_metric_title_label.text = "CORE TEMPERATURE:"
			_metric_bar.max_value = 100.0
			_metric_bar.value = _core_heat

			# Giant 3D Blazing Sun ahead on left
			_sun_mesh = MeshInstance3D.new()
			var sm: SphereMesh = SphereMesh.new()
			sm.radius = 280.0
			sm.height = 560.0
			_sun_mesh.mesh = sm
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color(1.0, 0.90, 0.65)
			_sun_mesh.material_override = override_or_new_mat(mat)
			_sun_mesh.position = Vector3(-420.0, 0.0, -1100.0)
			_world_3d.add_child(_sun_mesh)

			# Coronal Prominence Rings
			for i in range(3):
				var tor: MeshInstance3D = MeshInstance3D.new()
				var tm: TorusMesh = TorusMesh.new()
				tm.inner_radius = 290.0 + float(i) * 30.0
				tm.outer_radius = 310.0 + float(i) * 35.0
				tor.mesh = tm
				var tmat: StandardMaterial3D = StandardMaterial3D.new()
				tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				tmat.albedo_color = Color(1.0, 0.45 + float(i) * 0.2, 0.15, 0.75)
				tor.material_override = tmat
				tor.rotation_degrees = Vector3(15.0 + float(i) * 25.0, 30.0, 0.0)
				_sun_mesh.add_child(tor)
				_sun_flares.append(tor)

		MISSION_BLACK_HOLE:
			_dir_light.light_color = Color(0.55, 0.45, 0.85)
			_dir_light.light_energy = 0.9
			_metric_title_label.text = "ESCAPE VELOCITY:"
			_metric_bar.max_value = 100.0
			_metric_bar.value = 0.0

			# 3D Black Hole Singularity
			_black_hole_root = Node3D.new()
			_black_hole_root.position = Vector3(0.0, 0.0, -1200.0)
			_world_3d.add_child(_black_hole_root)

			# Event Horizon sphere (pitch black)
			var bh_sphere: MeshInstance3D = MeshInstance3D.new()
			var bs: SphereMesh = SphereMesh.new()
			bs.radius = 80.0
			bs.height = 160.0
			bh_sphere.mesh = bs
			var bh_mat: StandardMaterial3D = StandardMaterial3D.new()
			bh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			bh_mat.albedo_color = Color(0.002, 0.003, 0.008)
			bh_sphere.material_override = bh_mat
			_black_hole_root.add_child(bh_sphere)

			# Tilted Accretion Disk Rings
			for i in range(4):
				var tor: MeshInstance3D = MeshInstance3D.new()
				var tm: TorusMesh = TorusMesh.new()
				tm.inner_radius = 95.0 + float(i) * 32.0
				tm.outer_radius = 115.0 + float(i) * 38.0
				tor.mesh = tm
				var tmat: StandardMaterial3D = StandardMaterial3D.new()
				tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				tmat.albedo_color = Color(0.72, 0.28, 1.0, 0.85) if (i % 2 == 0) else Color(1.0, 0.52, 0.20, 0.85)
				tor.material_override = tmat
				tor.rotation_degrees = Vector3(65.0, 15.0, 0.0)
				_black_hole_root.add_child(tor)

		MISSION_LANDING:
			_dir_light.light_color = Color(0.95, 0.65, 0.45)
			_dir_light.light_energy = 1.8
			_metric_title_label.text = "DESCENT VECTOR:"
			_metric_bar.max_value = 100.0
			_metric_bar.value = 0.0


func override_or_new_mat(m: StandardMaterial3D) -> StandardMaterial3D:
	return m


func _enter_phase(new_phase: int) -> void:
	_phase = new_phase
	_phase_timer = 0.0

	match _phase:
		0: # Cruise
			_mode_badge.text = "[ 3D AUTOPILOT: LOCKED ]"
			_mode_badge.add_theme_color_override("font_color", GREEN)
			_close_button.visible = true
			_action_button.visible = true
			_action_button.text = "[ TAKE MANUAL HELM NOW ]"

			match _encounter_id:
				MISSION_ASTEROIDS:
					_comms_speaker_label.text = "ELIAS WARD // BRIDGE FLIGHT DECK"
					_comms_speaker_label.add_theme_color_override("font_color", CYAN)
					_comms_text_label.text = "\"Approaching the Shearwater asteroid swarm in the Erebos corridor. Forward 3D sensors are tracking tumbling ore boulders. Take manual helm to navigate!\""
				MISSION_STAR_VEER:
					_comms_speaker_label.text = "ELIAS WARD // NAVIGATION BRIDGE"
					_comms_speaker_label.add_theme_color_override("font_color", GOLD)
					_comms_text_label.text = "\"We are skirting the outer corona of star Helios-4! Hull temperatures rising rapidly. Veer along the thermal escape trajectory and flush coolant [C / Shift]!\""
				MISSION_BLACK_HOLE:
					_comms_speaker_label.text = "COMMANDER MAYA CHEN // BRIDGE HELM"
					_comms_speaker_label.add_theme_color_override("font_color", CYAN)
					_comms_text_label.text = "\"Asteria-1 has entered the outer gravity well of singularity Gargantua! Counter-thrust away from the event horizon and slingshot through warp gates!\""
				MISSION_LANDING:
					_comms_speaker_label.text = "COMMANDER MAYA CHEN // DESCENT HELM"
					_comms_speaker_label.add_theme_color_override("font_color", GOLD)
					_comms_text_label.text = "\"Atmospheric insertion confirmed. Steer Asteria-1 through rising dust crags and align retro-thrusters for touchdown at Site K-12!\""

		1: # Alert Cutscene
			_mode_badge.text = "[ ⚠ PROXIMITY ALERT — AUTOPILOT DISENGAGED ]"
			_mode_badge.add_theme_color_override("font_color", ALERT_RED)
			_close_button.visible = true
			_action_button.visible = true
			_action_button.text = "[ ENGAGE 3D FLIGHT  › ]"

			match _encounter_id:
				MISSION_ASTEROIDS:
					_comms_speaker_label.text = "⚠ COLLISION WARNING // SHEARWATER SWARM"
					_comms_speaker_label.add_theme_color_override("font_color", ALERT_RED)
					_comms_text_label.text = "DENSE ORE BOULDERS IN FLIGHT VECTOR!\nSteer with [WASD / Mouse] to dodge boulders, and tap [Space / LMB] to blast ore rocks with bow pulse cannons!"
				MISSION_STAR_VEER:
					_comms_speaker_label.text = "⚠ THERMAL SURGE WARNING // HELIOS CORONA"
					_comms_speaker_label.add_theme_color_override("font_color", ALERT_RED)
					_comms_text_label.text = "SOLAR FLARES ERUPTING ALONG THE VECTOR!\nVeer ship away from coronal loops with [WASD] and flush emergency coolant with [C / Shift]!"
				MISSION_BLACK_HOLE:
					_comms_speaker_label.text = "⚠ GRAVITATIONAL SINGULARITY PULL // 5.2G"
					_comms_speaker_label.add_theme_color_override("font_color", ALERT_RED)
					_comms_text_label.text = "CENTRIPETAL FORCE DRAGGING SHIP INWARD!\nCounter-steer against the vortex with [WASD], avoid relativistic accretion fragments, and hit escape velocity gates!"
				MISSION_LANDING:
					_comms_speaker_label.text = "⚠ GRAVITATIONAL TURBULENCE & CRAGS"
					_comms_speaker_label.add_theme_color_override("font_color", ALERT_RED)
					_comms_text_label.text = "ALIGN WITH SITE K-12 BEACON!\nDodge dust pillars and fire retro-pulses to clear landing approach."

		2: # 3D Manual Flight Active
			_mode_badge.text = "[ 3D MANUAL FLIGHT: ENGAGED ]"
			_mode_badge.add_theme_color_override("font_color", ORANGE)
			_close_button.visible = true
			_action_button.visible = true
			_action_button.text = "[ FIRE PULSE CANNONS ]"

			match _encounter_id:
				MISSION_ASTEROIDS:
					_comms_speaker_label.text = "MANUAL EVASION // DODGE & SHATTER ORE ASTEROIDS"
					_comms_speaker_label.add_theme_color_override("font_color", GOLD)
					_comms_text_label.text = "Aim with [WASD / Mouse], blast asteroids with [Space / LMB], and boost with [Shift]!"
				MISSION_STAR_VEER:
					_comms_speaker_label.text = "SOLAR VEERING // MONITOR HEAT & FLY ESCAPE CORRIDOR"
					_comms_speaker_label.add_theme_color_override("font_color", GOLD)
					_comms_text_label.text = "Fly through green thermal clearance gates to cool core! Tap [C / Shift] to flush coolant!"
					_action_button.text = "[ FLUSH EMERGENCY COOLANT ]"
				MISSION_BLACK_HOLE:
					_comms_speaker_label.text = "SINGULARITY SLINGSHOT // ACCELERATE TO ESCAPE VELOCITY"
					_comms_speaker_label.add_theme_color_override("font_color", CYAN)
					_comms_text_label.text = "Counter-thrust away from the center! Pass through warp gates to build escape velocity!"
					_action_button.text = "[ THRUSTER BOOST ]"
				MISSION_LANDING:
					_comms_speaker_label.text = "RETRO-BURN // SITE K-12 TOUCHDOWN"
					_comms_speaker_label.add_theme_color_override("font_color", GREEN)
					_comms_text_label.text = "Stabilize descent and fire retro-pulses to secure touchdown."

		3: # Mission Completed
			_mode_badge.text = "[ SECTOR CLEARED // AUTOPILOT RESTORED ]"
			_mode_badge.add_theme_color_override("font_color", GREEN)
			_close_button.visible = true
			_action_button.visible = true
			_action_button.text = "[ COMPLETE & RETURN TO BRIDGE  → ]"

			match _encounter_id:
				MISSION_ASTEROIDS:
					_comms_speaker_label.text = "ELIAS WARD // BRIDGE HELM"
					_comms_speaker_label.add_theme_color_override("font_color", GREEN)
					_comms_text_label.text = "\"We are clear of the asteroid swarm! Asteria-1 suffered zero fatal damage. Outstanding 3D piloting, Thura.\""
				MISSION_STAR_VEER:
					_comms_speaker_label.text = "ELIAS WARD // NAVIGATION BRIDGE"
					_comms_speaker_label.add_theme_color_override("font_color", GREEN)
					_comms_text_label.text = "\"Thermal core temperatures stabilized! We've cleared Helios-4's corona and resumed course.\""
				MISSION_BLACK_HOLE:
					_comms_speaker_label.text = "COMMANDER MAYA CHEN // BRIDGE INTERCOM"
					_comms_speaker_label.add_theme_color_override("font_color", GREEN)
					_comms_text_label.text = "\"Singularity escape velocity reached! Slingshot vector successful. We are safely back in deep cruise.\""
				MISSION_LANDING:
					_comms_speaker_label.text = "COMMANDER MAYA CHEN // SHIPWIDE INTERCOM"
					_comms_speaker_label.add_theme_color_override("font_color", GREEN)
					_comms_text_label.text = "\"Touchdown confirmed! Hydraulic struts locked into bedrock. Welcome to Erebos Site K-12!\""

		4: # Soft-Fail Emergency Reset
			_mode_badge.text = "[ ⚠ EMERGENCY RETRO-BURN RETREAT ]"
			_mode_badge.add_theme_color_override("font_color", ALERT_RED)
			_close_button.visible = true
			_action_button.visible = true
			_action_button.text = "[ RETRY FLIGHT SEQUENCE ]"
			_comms_speaker_label.text = "AUTOPILOT SAFETY SYSTEM // SECTOR RETREAT"
			_comms_speaker_label.add_theme_color_override("font_color", ALERT_RED)
			_comms_text_label.text = "Critical hazard threshold exceeded! Autopilot triggered an emergency thruster retreat back to sector entry. Tap RETRY to re-engage with restored systems."


func _on_action_button_pressed() -> void:
	if _phase == 0 or _phase == 1:
		_enter_phase(2)
	elif _phase == 2:
		if _encounter_id == MISSION_STAR_VEER:
			_trigger_coolant_flush()
		elif _encounter_id == MISSION_BLACK_HOLE:
			_thruster_boost = 2.2
		else:
			_fire_3d_pulse_cannon()
	elif _phase == 3:
		_finish_and_close()
	elif _phase == 4:
		_start_encounter_sequence()


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
	if event is InputEventKey:
		var key_ev: InputEventKey = event as InputEventKey
		if key_ev.pressed and not key_ev.echo:
			if key_ev.keycode == KEY_SPACE:
				if _phase == 0 or _phase == 1:
					_enter_phase(2)
				elif _phase == 2:
					_fire_3d_pulse_cannon()
				elif _phase == 3:
					_finish_and_close()
				elif _phase == 4:
					_start_encounter_sequence()
				get_viewport().set_input_as_handled()
				return
			elif key_ev.keycode == KEY_C:
				if _phase == 2 and _encounter_id == MISSION_STAR_VEER:
					_trigger_coolant_flush()
					get_viewport().set_input_as_handled()
					return
			elif key_ev.keycode == KEY_ESCAPE:
				_on_close_pressed()
				get_viewport().set_input_as_handled()
				return

	if event is InputEventMouseButton:
		var mb_ev: InputEventMouseButton = event as InputEventMouseButton
		if mb_ev.pressed and mb_ev.button_index == MOUSE_BUTTON_LEFT:
			if _phase == 0 or _phase == 1:
				_enter_phase(2)
			elif _phase == 2:
				_fire_3d_pulse_cannon()
			elif _phase == 3:
				_finish_and_close()
			elif _phase == 4:
				_start_encounter_sequence()


func _trigger_coolant_flush() -> void:
	if _coolant_cooldown > 0.0:
		return
	_coolant_cooldown = 4.5
	_core_heat = maxf(_core_heat - 35.0, 5.0)
	_hit_flash_timer = 0.5
	DialogueAudioSynth.play_sfx("coolant_flush", self, -2.0)


func _fire_3d_pulse_cannon() -> void:
	if _pulse_cooldown > 0.0:
		return
	_pulse_cooldown = 0.22
	DialogueAudioSynth.play_sfx("laser_cannon", self, -3.0)

	# Twin 3D Laser Pulses shooting along -Z from left and right gun mounts
	var pulse_mesh: CylinderMesh = CylinderMesh.new()
	pulse_mesh.top_radius = 0.8
	pulse_mesh.bottom_radius = 0.8
	pulse_mesh.height = 7.5
	var pmat: StandardMaterial3D = StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.albedo_color = Color(0.40, 0.95, 1.0)
	pulse_mesh.material = pmat

	for mount_x in [-7.5, 7.5]:
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = pulse_mesh
		mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		mi.position = _flight_pos + Vector3(mount_x, -2.5, -4.0)
		_world_3d.add_child(mi)
		_pulses_3d.append({
			"node": mi,
			"vel": Vector3(0.0, 0.0, -680.0),
			"life": 1.4,
		})


func _spawn_3d_asteroid() -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var rad: float = 8.0 + randf() * 18.0
	var sm: SphereMesh = SphereMesh.new()
	sm.radius = rad
	sm.height = rad * 2.0
	mi.mesh = sm

	var amat: StandardMaterial3D = StandardMaterial3D.new()
	var is_ore: bool = (randf() < 0.40)
	amat.albedo_color = Color(0.18, 0.20, 0.25)
	if is_ore:
		amat.emission_enabled = true
		amat.emission = Color(0.36, 0.90, 1.0) if (randf() < 0.5) else Color(1.0, 0.65, 0.25)
		amat.emission_energy_multiplier = 1.8
	mi.material_override = amat

	var sx: float = (randf() - 0.5) * 260.0
	var sy: float = (randf() - 0.5) * 140.0
	var sz: float = -1100.0 - randf() * 200.0
	mi.position = Vector3(sx, sy, sz)
	_world_3d.add_child(mi)

	var spd: float = 230.0 + randf() * 140.0
	_asteroids_3d.append({
		"node": mi,
		"radius": rad,
		"vel": Vector3(0.0, 0.0, spd),
		"rot_axis": Vector3(randf(), randf(), randf()).normalized(),
		"rot_speed": 1.0 + randf() * 2.5,
		"is_ore": is_ore,
	})


func _spawn_3d_gate(color: Color) -> void:
	var tor: MeshInstance3D = MeshInstance3D.new()
	var tm: TorusMesh = TorusMesh.new()
	tm.inner_radius = 28.0
	tm.outer_radius = 34.0
	tor.mesh = tm
	var gmat: StandardMaterial3D = StandardMaterial3D.new()
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gmat.albedo_color = color
	tor.material_override = gmat

	var gx: float = (randf() - 0.5) * 120.0
	var gy: float = (randf() - 0.5) * 70.0
	tor.position = Vector3(gx, gy, -1150.0)
	_world_3d.add_child(tor)

	_gates_3d.append({
		"node": tor,
		"radius": 32.0,
		"speed": 280.0,
	})


func _process(delta: float) -> void:
	_total_time += delta
	_phase_timer += delta

	if _hit_flash_timer > 0.0:
		_hit_flash_timer = maxf(_hit_flash_timer - delta * 2.5, 0.0)
	if _pulse_cooldown > 0.0:
		_pulse_cooldown = maxf(_pulse_cooldown - delta, 0.0)
	if _coolant_cooldown > 0.0:
		_coolant_cooldown = maxf(_coolant_cooldown - delta, 0.0)

	_update_3d_stars(delta)

	if _phase == 0: # Cruise
		_flight_elapsed = minf(_flight_elapsed + delta * 0.4, 2.0)
		_metric_bar.value = 10.0
		if _phase_timer >= 2.0:
			_enter_phase(1)

	elif _phase == 1: # Alert
		if _phase_timer >= 1.8:
			_enter_phase(2)

	elif _phase == 2: # 3D Manual Flight
		_flight_elapsed += delta
		_process_3d_flight_controls(delta)
		_update_3d_encounter_hazards(delta)

		# Check Win Condition
		if _flight_elapsed >= _flight_duration:
			_enter_phase(3)

		# Check Soft-Fail Conditions
		if _hull_integrity <= 0.0 or _core_heat >= 100.0:
			_enter_phase(4)

	elif _phase == 3: # Success
		_flight_vel = _flight_vel.lerp(Vector3.ZERO, delta * 4.0)
		_cam_rot = _cam_rot.lerp(Vector3.ZERO, delta * 3.0)

	_cam_3d.position = _flight_pos
	_cam_3d.rotation = _cam_rot

	# Rotate celestial objects
	if is_instance_valid(_sun_mesh):
		_sun_mesh.rotation.y += delta * 0.15
		for f in _sun_flares:
			f.rotation.z += delta * 0.35
	if is_instance_valid(_black_hole_root):
		_black_hole_root.rotation.z += delta * 0.45

	if is_instance_valid(_hud_overlay):
		_hud_overlay.queue_redraw()


func _update_3d_stars(delta: float) -> void:
	var spd_mult: float = 2.4 if (_phase == 2 and _thruster_boost > 1.2) else (1.6 if _phase == 2 else 1.0)
	for st in _stars_3d:
		var mi: MeshInstance3D = st["node"]
		var p: Vector3 = mi.position
		p.z += float(st["speed"]) * spd_mult * delta
		if p.z > 20.0:
			p.z = -1350.0
			p.x = (randf() - 0.5) * 550.0
			p.y = (randf() - 0.5) * 320.0
		mi.position = p


func _process_3d_flight_controls(delta: float) -> void:
	# WASD / Arrow Keys steering
	var input_x: float = 0.0
	var input_y: float = 0.0

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_y -= 1.0

	if Input.is_key_pressed(KEY_SHIFT):
		_thruster_boost = lerpf(_thruster_boost, 1.8, delta * 6.0)
	else:
		_thruster_boost = lerpf(_thruster_boost, 1.0, delta * 4.0)

	# Target flight velocity (X = lateral, Y = vertical)
	var max_speed: float = 140.0 * _thruster_boost
	var target_vel: Vector3 = Vector3(input_x * max_speed, input_y * max_speed, 0.0)

	# Black Hole Gravitational Pull towards (0, 0)
	if _encounter_id == MISSION_BLACK_HOLE:
		var pull_strength: float = 48.0
		target_vel += -_flight_pos.normalized() * pull_strength

	_flight_vel = _flight_vel.lerp(target_vel, delta * 9.0)
	_flight_pos += _flight_vel * delta

	# Clamp to flight corridor boundaries
	_flight_pos.x = clampf(_flight_pos.x, -110.0, 110.0)
	_flight_pos.y = clampf(_flight_pos.y, -55.0, 55.0)

	# Banking roll and pitch/yaw aiming tilt
	var target_pitch: float = -(_flight_vel.y / max_speed) * 0.18
	var target_yaw: float = -(_flight_vel.x / max_speed) * 0.22
	var target_roll: float = -(_flight_vel.x / max_speed) * 0.32
	_cam_rot = _cam_rot.lerp(Vector3(target_pitch, target_yaw, target_roll), delta * 8.0)


func _update_3d_encounter_hazards(delta: float) -> void:
	_spawn_timer += delta

	# Advance 3D Pulses
	var p_idx: int = _pulses_3d.size() - 1
	while p_idx >= 0:
		var p: Dictionary = _pulses_3d[p_idx]
		var mi: MeshInstance3D = p["node"]
		mi.position += p["vel"] * delta
		p["life"] = float(p["life"]) - delta
		_pulses_3d[p_idx] = p
		if float(p["life"]) <= 0.0 or mi.position.z < -1400.0:
			mi.queue_free()
			_pulses_3d.remove_at(p_idx)
		p_idx -= 1

	# Advance 3D Navigation Clearance Gates
	var g_idx: int = _gates_3d.size() - 1
	while g_idx >= 0:
		var g: Dictionary = _gates_3d[g_idx]
		var tor: MeshInstance3D = g["node"]
		tor.position.z += float(g["speed"]) * delta
		_gates_3d[g_idx] = g

		# Check player passing through gate
		if absf(tor.position.z - _flight_pos.z) < 16.0:
			if Vector2(tor.position.x, tor.position.y).distance_to(Vector2(_flight_pos.x, _flight_pos.y)) < float(g["radius"]):
				# Passed gate bonus!
				if _encounter_id == MISSION_STAR_VEER:
					_core_heat = maxf(_core_heat - 14.0, 0.0)
				elif _encounter_id == MISSION_BLACK_HOLE:
					_escape_velocity_pct = minf(_escape_velocity_pct + 18.0, 100.0)

		if tor.position.z > 20.0:
			tor.queue_free()
			_gates_3d.remove_at(g_idx)
		g_idx -= 1

	# Encounter Specific Hazard Management
	match _encounter_id:
		MISSION_ASTEROIDS:
			var pct: float = clampf((_flight_elapsed / _flight_duration) * 100.0, 0.0, 100.0)
			_metric_bar.value = pct
			_metric_value_label.text = "%d%% CLEARED" % roundi(pct)

			if _spawn_timer >= 0.45 and _flight_elapsed < _flight_duration - 1.5:
				_spawn_timer = 0.0
				_spawn_3d_asteroid()

			_update_3d_asteroids(delta)

		MISSION_STAR_VEER:
			# Heat increases naturally as you fly near the solar corona
			var dist_to_sun: float = _flight_pos.distance_to(Vector3(-420.0, 0.0, -1100.0))
			var heat_rate: float = 6.5 + (1.0 - clampf(_flight_pos.x / 110.0, 0.0, 1.0)) * 4.5
			_core_heat = clampf(_core_heat + heat_rate * delta, 0.0, 100.0)
			_metric_bar.value = _core_heat
			_metric_value_label.text = "%d%% (%d K)" % [roundi(_core_heat), 850 + roundi(_core_heat * 18.0)]

			if _core_heat > 75.0:
				_metric_value_label.add_theme_color_override("font_color", ALERT_RED)
			else:
				_metric_value_label.add_theme_color_override("font_color", GOLD)

			if _spawn_timer >= 1.6 and _flight_elapsed < _flight_duration - 1.0:
				_spawn_timer = 0.0
				_spawn_3d_gate(Color(0.35, 1.0, 0.55))

		MISSION_BLACK_HOLE:
			_escape_velocity_pct = minf(_escape_velocity_pct + delta * 4.5, 100.0)
			_metric_bar.value = _escape_velocity_pct
			_metric_value_label.text = "%d%% ESCAPED" % roundi(_escape_velocity_pct)

			if _spawn_timer >= 1.4 and _flight_elapsed < _flight_duration - 1.0:
				_spawn_timer = 0.0
				_spawn_3d_gate(Color(0.40, 0.85, 1.0))

			if _spawn_timer >= 0.70 and _flight_elapsed < _flight_duration - 1.0:
				_spawn_3d_asteroid()
			_update_3d_asteroids(delta)

		MISSION_LANDING:
			var pct: float = clampf((_flight_elapsed / _flight_duration) * 100.0, 0.0, 100.0)
			_metric_bar.value = pct
			_metric_value_label.text = "%d%% DESCENT" % roundi(pct)
			if _spawn_timer >= 0.55 and _flight_elapsed < _flight_duration - 1.0:
				_spawn_timer = 0.0
				_spawn_3d_asteroid()
			_update_3d_asteroids(delta)


func _update_3d_asteroids(delta: float) -> void:
	var a_idx: int = _asteroids_3d.size() - 1
	while a_idx >= 0:
		var ast: Dictionary = _asteroids_3d[a_idx]
		var mi: MeshInstance3D = ast["node"]
		var vel: Vector3 = ast["vel"]
		mi.position += vel * delta
		mi.rotation += ast["rot_axis"] * float(ast["rot_speed"]) * delta

		var arad: float = float(ast["radius"])
		var destroyed: bool = false

		# Check collision with pulses
		var p_k: int = _pulses_3d.size() - 1
		while p_k >= 0:
			var p: Dictionary = _pulses_3d[p_k]
			var p_mi: MeshInstance3D = p["node"]
			if mi.position.distance_to(p_mi.position) <= arad + 4.5:
				_asteroids_shattered += 1
				p_mi.queue_free()
				_pulses_3d.remove_at(p_k)
				mi.queue_free()
				_asteroids_3d.remove_at(a_idx)
				destroyed = true
				break
			p_k -= 1

		if not destroyed:
			# Check collision with ship cockpit
			if absf(mi.position.z - _flight_pos.z) < arad + 8.0:
				if Vector2(mi.position.x, mi.position.y).distance_to(Vector2(_flight_pos.x, _flight_pos.y)) <= arad + 12.0:
					_hull_integrity = maxf(_hull_integrity - 16.0, 0.0)
					_hit_flash_timer = 1.0
					_hull_bar.value = _hull_integrity
					_hull_label.text = "%d%%" % roundi(_hull_integrity)
					mi.queue_free()
					_asteroids_3d.remove_at(a_idx)
					destroyed = true

		if not destroyed and mi.position.z > 25.0:
			mi.queue_free()
			_asteroids_3d.remove_at(a_idx)

		a_idx -= 1


func render_hud_elements(canvas: Control) -> void:
	if not is_instance_valid(canvas):
		return

	# 1. Industrial Retro-Futuristic Cockpit Window Frame Struts
	var w: float = VIEW_SIZE.x
	var h: float = VIEW_SIZE.y

	# Corner diagonal struts
	var strut_col: Color = Color(0.12, 0.16, 0.22, 0.95)
	var rivet_col: Color = Color(0.42, 0.52, 0.62, 0.90)

	# Top-left strut
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(70.0, 0.0), Vector2(0.0, 70.0)
	]), strut_col)
	canvas.draw_circle(Vector2(24.0, 24.0), 3.0, rivet_col)

	# Top-right strut
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(w, 0.0), Vector2(w - 70.0, 0.0), Vector2(w, 70.0)
	]), strut_col)
	canvas.draw_circle(Vector2(w - 24.0, 24.0), 3.0, rivet_col)

	# Bottom-left strut
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, h), Vector2(85.0, h), Vector2(0.0, h - 85.0)
	]), strut_col)
	canvas.draw_circle(Vector2(28.0, h - 28.0), 3.0, rivet_col)

	# Bottom-right strut
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(w, h), Vector2(w - 85.0, h), Vector2(w, h - 85.0)
	]), strut_col)
	canvas.draw_circle(Vector2(w - 28.0, h - 28.0), 3.0, rivet_col)

	# Visor border lines
	canvas.draw_line(Vector2(70.0, 2.0), Vector2(w - 70.0, 2.0), strut_col, 4.0)
	canvas.draw_line(Vector2(85.0, h - 2.0), Vector2(w - 85.0, h - 2.0), strut_col, 5.0)

	# 2. Holographic Vector Flight Reticle & Artificial Horizon Pitch Ladder
	var center: Vector2 = Vector2(w * 0.5, h * 0.5)
	var reticle_pos: Vector2 = center + Vector2(-_cam_rot.y * 380.0, _cam_rot.x * 380.0)
	var hud_c: Color = Color(0.36, 0.90, 1.0, 0.82) if _phase == 2 else Color(0.48, 0.93, 0.64, 0.75)

	# Aiming brackets & crosshair
	canvas.draw_circle(reticle_pos, 4.0, hud_c)
	canvas.draw_arc(reticle_pos, 22.0, 0.2, PI * 0.45, 12, hud_c, 1.8, true)
	canvas.draw_arc(reticle_pos, 22.0, PI * 0.55, PI * 0.8, 12, hud_c, 1.8, true)
	canvas.draw_arc(reticle_pos, 22.0, PI * 1.05, PI * 1.3, 12, hud_c, 1.8, true)
	canvas.draw_arc(reticle_pos, 22.0, PI * 1.55, PI * 1.8, 12, hud_c, 1.8, true)

	# Pitch ladder rungs
	for ladder_i in [-1, 1]:
		var rung_y: float = reticle_pos.y + float(ladder_i) * 32.0
		canvas.draw_line(Vector2(reticle_pos.x - 38.0, rung_y), Vector2(reticle_pos.x - 14.0, rung_y), hud_c, 1.2)
		canvas.draw_line(Vector2(reticle_pos.x + 14.0, rung_y), Vector2(reticle_pos.x + 38.0, rung_y), hud_c, 1.2)

	# 3. 3D Proximity Radar / Hazard Compass (Bottom-Left)
	var radar_c: Vector2 = Vector2(58.0, h - 48.0)
	canvas.draw_circle(radar_c, 24.0, Color(0.01, 0.02, 0.04, 0.85))
	canvas.draw_arc(radar_c, 24.0, 0.0, TAU, 24, hud_c, 1.2, true)
	canvas.draw_circle(radar_c, 2.5, Color.WHITE)

	for ast in _asteroids_3d:
		var mi: MeshInstance3D = ast["node"]
		var diff_x: float = (mi.position.x - _flight_pos.x) * 0.12
		var diff_z: float = (mi.position.z - _flight_pos.z) * 0.025
		var r_pt: Vector2 = radar_c + Vector2(diff_x, diff_z)
		if r_pt.distance_to(radar_c) < 22.0:
			canvas.draw_circle(r_pt, 2.0, ALERT_RED)

	# 4. Emergency Hull Impact Flashes
	if _hit_flash_timer > 0.01:
		canvas.draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(1.0, 0.25, 0.20, 0.35 * _hit_flash_timer), true)
