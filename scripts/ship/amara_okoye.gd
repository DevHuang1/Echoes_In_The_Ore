class_name AmaraOkoye
extends CharacterBody2D

signal sample_study_started

const WALK_ATLAS := preload("res://art/characters/runtime/amara_okoye_lab_walk_4dir.png")
const SAMPLE_ATLAS := preload("res://art/planet/resonance_ore_intact.png")
const SEATED_POSE_PATH := "res://art/characters/runtime/amara_okoye_seated_console.png"
const FLOOR_ALPHA_THRESHOLD := 0.15
const NAV_CELL_SIZE := 24.0
const BODY_RADIUS := 7.0
const DISPLAY_SCALE := 0.11
const SEATED_DISPLAY_SCALE := 0.030

# Keep local patrols inside Hydroponics and out of the east access corridor.
const HYDROPONICS_AREA := Rect2(Vector2(60.0, 650.0), Vector2(420.0, 190.0))
const SHIP_ROAM_AREAS := [
	Rect2(Vector2(45.0, 205.0), Vector2(570.0, 270.0)),
	Rect2(Vector2(585.0, 35.0), Vector2(545.0, 255.0)),
	Rect2(Vector2(575.0, 420.0), Vector2(610.0, 235.0)),
	Rect2(Vector2(1170.0, 185.0), Vector2(560.0, 520.0)),
]
const ANIMATION_ROWS := {
	&"walk_down": 0,
	&"walk_left": 1,
	&"walk_right": 2,
	&"walk_up": 3,
}

# Key inspection stations in Hydroponics with specific target approach points and barks.
const HYDROPONICS_STATIONS: Array[Dictionary] = [
	{
		"id": &"control_console",
		"name": "Control Console",
		"target": Vector2(122.0, 748.0),
		"facing": Vector2.LEFT,
		"tag": "LOGGING CONSOLE",
		"barks": [
			"Nutrient telemetry nominal. Bio-sensors online.",
			"Checking greenhouse oxygen output levels.",
			"Logging growth cycle data to Asteria-1 log.",
		]
	},
	{
		"id": &"nutrient_pump",
		"name": "Nutrient Pump",
		"target": Vector2(204.0, 768.0),
		"facing": Vector2.LEFT,
		"tag": "CHECKING PUMP",
		"barks": [
			"Manifold pressure steady at 3.2 bar.",
			"No sediment in the filter screen. Flow is clean.",
			"Bubble agitation rate looks perfect.",
		]
	},
	{
		"id": &"seedling_rack",
		"name": "Seedling Rack",
		"target": Vector2(310.0, 736.0),
		"facing": Vector2.LEFT,
		"tag": "INSPECTING SEEDLINGS",
		"barks": [
			"Tray humidity steady at 68%. Roots look vibrant.",
			"Sprouts germinating on schedule under the LED glow.",
			"Adjusting seedling micro-misters.",
		]
	},
	{
		"id": &"grow_tray_north",
		"name": "North Grow Tray",
		"target": Vector2(195.0, 642.0),
		"facing": Vector2.DOWN,
		"tag": "EXAMINING CANOPY",
		"barks": [
			"North canopy leaves are absorbing maximum spectrum.",
			"No fungal discoloration. Crisp emerald stems.",
			"Checking sub-surface hydration pads.",
		]
	},
	{
		"id": &"grow_tray_south",
		"name": "South Grow Tray",
		"target": Vector2(204.0, 744.0),
		"facing": Vector2.UP,
		"tag": "CHECKING CROP TRAY",
		"barks": [
			"South tray root mats are expanding nicely.",
			"Nutrient uptake is within ideal parameters.",
			"Leaves are firm and fragrant.",
		]
	},
	{
		"id": &"wall_herb_shelf",
		"name": "Wall Herb Shelf",
		"target": Vector2(400.0, 712.0),
		"facing": Vector2.UP,
		"tag": "PRUNING HERBS",
		"barks": [
			"Pruning dry tips off the medicinal thyme.",
			"Fresh mint aroma always clears my head.",
			"Basil specimen is thriving in zero-g soil blend.",
		]
	},
	{
		"id": &"bio_vapor",
		"name": "Bio-Vapor Vent",
		"target": Vector2(280.0, 768.0),
		"facing": Vector2.LEFT,
		"tag": "CHECKING BIO-MIST",
		"barks": [
			"Atmospheric humidity balance is spot on.",
			"Bio-vapor scrubbers trapping airborne particulates.",
			"Air in here is the sweetest on the entire ship.",
		]
	},
	{
		"id": &"center_moss_aisle",
		"name": "Center Aisle",
		"target": Vector2(320.0, 746.0),
		"facing": Vector2.DOWN,
		"tag": "EXAMINING FLOOR MOSS",
		"barks": [
			"Bio-moss grip tiles preventing slip hazards.",
			"Walking the center aisle to inspect row alignment.",
			"Everything in this room is breathing.",
		]
	},
]

const SHIP_PATROL_BARKS: Array[Dictionary] = [
	{
		"tag": "PATROLLING SPINE",
		"barks": [
			"Spine airflow feels brisk today.",
			"Central corridor lights running on low auxiliary draw.",
			"Hull acoustic resonance is normal along the spine.",
		]
	},
	{
		"tag": "INSPECTING SHIP VENTS",
		"barks": [
			"Checking main corridor ventilation flow.",
			"Return duct pressure is balanced.",
			"Oxygen recycling lines humming steadily.",
		]
	},
	{
		"tag": "MONITORING BULKHEADS",
		"barks": [
			"Pressure seals look tight and secure.",
			"Taking a quick walk outside the grow room.",
			"Checking atmosphere levels between compartments.",
		]
	},
	{
		"tag": "CHECKING CONDUITS",
		"barks": [
			"Auxiliary conduits have steady current flow.",
			"Good to stretch my legs across the ship.",
			"Ship structure feels steady as a rock.",
		]
	},
]

const PLAYER_GREETING_BARKS: Array[String] = [
	"Hey Thura! Glad to see you up and moving.",
	"Don't worry, the crops are breathing easy today.",
	"Watch your footing near the bio-vapor mist!",
	"Fresh mint tea will be ready soon if you want some.",
	"Good to see another soul on this watch.",
	"Need a hand with anything, Thura?",
]

enum RoamPhase { HYDROPONICS, SHIP_EXCURSION, RETURNING }

@export_range(20.0, 240.0, 1.0) var move_speed: float = 62.0
@export var movement_burst_range := Vector2(0.90, 1.05)
@export var local_idle_seconds := Vector2(5.5, 9.0)
@export var ship_idle_seconds := Vector2(4.5, 7.5)
@export var room_roam_stops := Vector2i(10, 15)
@export var excursion_stops := Vector2i(8, 14)
@export_range(30.0, 180.0, 1.0) var ship_excursion_max_seconds := 140.0
@export_range(40.0, 240.0, 1.0) var notice_player_distance: float = 68.0
@export_range(0.0, 1.0, 0.05) var bark_chance: float = 0.28
@export_range(5.0, 90.0, 1.0) var routine_bark_cooldown_seconds: float = 26.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _random := RandomNumberGenerator.new()
var _floor_mask: Image
var _floor_origin := Vector2.ZERO
var _grid := AStarGrid2D.new()
var _hydroponics_grid := AStarGrid2D.new()
var _grid_region := Rect2i()
var _navigation_ready := false
var _hydroponics_cells: Array[Vector2i] = []
var _ship_zone_cells: Array = []
var _path: Array[Vector2] = []
var _path_index := 0
var _destination := Vector2.ZERO
var _current_speed := 62.0
var _has_destination := false
var _idle_remaining := 0.0
var _phase := RoamPhase.HYDROPONICS
var _excursion_seconds := 0.0
var _excursion_stops_remaining := 0
var _room_stops_remaining := 0
var _facing_animation: StringName = &"walk_down"
var _station_index := 0
var _current_station_info: Dictionary = {}
var _door_wait_retries := 0

# Unique NPC Overhead HUD Bubble
var _bubble_root: Node2D
var _bubble_panel: PanelContainer
var _bubble_tag_label: Label
var _bubble_text_label: Label
var _bubble_tween: Tween
var _player_nearby := false
var _greeting_cooldown := 12.0
var _bark_cooldown := 10.0
var _interaction_locks := {}
var _sample_watch_active := false
var _sample_watch_timer := 0.0
var _is_missing := false
var _lab_route_active := false
var _is_seated_at_console := false
var _carried_sample_sprite: Sprite2D
var _seated_pose_sprite: Sprite2D


func _ready() -> void:
	_random.randomize()
	add_to_group("ship_crew")
	_configure_sprite_animations()
	_build_overhead_bubble()
	var amara_badge := Label.new()
	amara_badge.name = "AmaraBadge"
	amara_badge.text = "[ DR. AMARA OKOYE / ASTROBIOLOGY ]"
	amara_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amara_badge.add_theme_font_size_override("font_size", 8)
	amara_badge.add_theme_color_override("font_color", Color(0.38, 0.88, 0.98, 0.9))
	amara_badge.autowrap_mode = TextServer.AUTOWRAP_OFF
	amara_badge.clip_text = false
	amara_badge.size = Vector2.ZERO
	amara_badge.custom_minimum_size = Vector2(200.0, 12.0)
	amara_badge.position = Vector2(-100.0, -36.0)
	add_child(amara_badge)

	var returning_to_ship := Engine.has_meta(&"returning_from_planet") and bool(Engine.get_meta(&"returning_from_planet"))
	var ore_stored := Engine.has_meta(&"resonance_ore_sample_stored") and bool(Engine.get_meta(&"resonance_ore_sample_stored"))
	var ore_collected := Engine.has_meta(&"resonance_ore_sample_collected") and bool(Engine.get_meta(&"resonance_ore_sample_collected"))
	var rig_failed := Engine.has_meta(&"erebos_rig_test_failed") and bool(Engine.get_meta(&"erebos_rig_test_failed"))
	var in_lab_story_phase := ore_stored or ore_collected or rig_failed or returning_to_ship

	if returning_to_ship and Engine.has_meta(&"lab_doctor_missing") and bool(Engine.get_meta(&"lab_doctor_missing")):
		visible = false
		set_physics_process(false)
		set_process(false)
		collision_layer = 0
		collision_mask = 0
		remove_from_group("ship_crew")
		return

	if in_lab_story_phase:
		var console_station := get_parent().get_node_or_null("LabRoom/ConsoleStation") as Node2D
		if console_station != null:
			global_position = console_station.global_position + Vector2(0.0, 32.0)
	else:
		global_position = Vector2(300.0, 740.0)

	await get_tree().physics_frame
	_build_navigation()

	if in_lab_story_phase:
		set_physics_process(false)
		_show_seated_pose()
		return

	if not _navigation_ready:
		set_physics_process(false)
		return
	var spawn_cell := _world_to_cell(global_position)
	if _grid_region.has_point(spawn_cell) and _hydroponics_grid.is_point_solid(spawn_cell):
		spawn_cell = _find_nearest_clear_cell(spawn_cell, true)
		if _grid_region.has_point(spawn_cell) and not _hydroponics_grid.is_point_solid(spawn_cell):
			global_position = _cell_to_world(spawn_cell)

	_room_stops_remaining = _random.randi_range(room_roam_stops.x, room_roam_stops.y)
	_choose_next_destination()


func begin_sample_watch() -> void:
	_sample_watch_active = true
	_sample_watch_timer = 11.0
	set_process(true)
	_show_overhead_bark("SAMPLE WATCH ACTIVE", "Ore secured. I'm monitoring the chamber and maintaining its pressure.", 5.0)


func carry_sample_to_tank(tank_position: Vector2) -> void:
	var sample_texture := AtlasTexture.new()
	sample_texture.atlas = SAMPLE_ATLAS
	sample_texture.region = Rect2(140.0, 120.0, 974.0, 1014.0)
	_carried_sample_sprite = Sprite2D.new()
	_carried_sample_sprite.name = "CarriedErebosSample"
	_carried_sample_sprite.texture = sample_texture
	_carried_sample_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_carried_sample_sprite.scale = Vector2.ONE * 0.012
	_carried_sample_sprite.position = Vector2(13.0, -8.0)
	_carried_sample_sprite.z_index = 4
	add_child(_carried_sample_sprite)
	_show_overhead_bark("SAMPLE TRANSFER", "I'll secure the ore in containment.", 2.5)
	await _walk_to_lab_point(tank_position)
	if not is_inside_tree():
		return
	if is_instance_valid(_carried_sample_sprite):
		_carried_sample_sprite.queue_free()
	_carried_sample_sprite = null
	_show_overhead_bark("CONTAINMENT LOADED", "Sample secured. Starting the chamber watch.", 3.0)
	await get_tree().create_timer(0.8).timeout


func walk_to_research_console_and_sit(console_position: Vector2) -> void:
	await _walk_to_lab_point(console_position)
	if not is_inside_tree():
		return
	_show_seated_pose()
	_show_overhead_bark("RESEARCH CONSOLE", "I'm running the ore telemetry from here.", 4.0)
	Engine.set_meta(&"resonance_ore_chamber_pressure", 1.0)
	Engine.set_meta(&"resonance_ore_atmosphere_test_passed", true)
	_show_overhead_bark("ATMOSPHERE SET", "Earth-normal pressure verified. Applying the study pulse.", 4.0)
	await get_tree().create_timer(1.2).timeout
	if is_inside_tree():
		Engine.set_meta(&"resonance_ore_stimulated", true)
		sample_study_started.emit()


func _show_seated_pose() -> void:
	_is_seated_at_console = true
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	_stop_walking()
	if not is_instance_valid(_seated_pose_sprite):
		var pose_image := Image.load_from_file(ProjectSettings.globalize_path(SEATED_POSE_PATH))
		if pose_image != null and not pose_image.is_empty():
			_seated_pose_sprite = Sprite2D.new()
			_seated_pose_sprite.name = "AmaraSeatedAtResearchConsole"
			_seated_pose_sprite.texture = ImageTexture.create_from_image(pose_image)
			_seated_pose_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_seated_pose_sprite.scale = Vector2.ONE * SEATED_DISPLAY_SCALE
			_seated_pose_sprite.position = Vector2(0.0, -3.0)
			_seated_pose_sprite.z_index = 3
			add_child(_seated_pose_sprite)
	if is_instance_valid(_seated_pose_sprite):
		sprite.visible = false
		_seated_pose_sprite.visible = true


func _walk_to_lab_point(target_position: Vector2) -> void:
	if _is_seated_at_console:
		_is_seated_at_console = false
		collision_layer = 4
		collision_mask = 1
		if is_instance_valid(_seated_pose_sprite):
			_seated_pose_sprite.visible = false
		sprite.visible = true
	if not _navigation_ready:
		return
	var target_cell := _world_to_cell(target_position)
	if _grid_region.has_point(target_cell) and _grid.is_point_solid(target_cell):
		target_cell = _find_nearest_clear_cell(target_cell)
	if not _set_destination(target_cell):
		return
	_lab_route_active = true
	set_physics_process(true)
	while _lab_route_active and is_inside_tree():
		await get_tree().physics_frame
	set_physics_process(false)


func _process_lab_route(delta: float) -> void:
	if _path_index >= _path.size():
		global_position = _destination
		_lab_route_active = false
		_has_destination = false
		velocity = Vector2.ZERO
		_stop_walking()
		return
	var target := _path[_path_index]
	var direction := target - global_position
	if direction.length() <= 2.5:
		_path_index += 1
		if _path_index >= _path.size():
			global_position = _destination
			_lab_route_active = false
			_has_destination = false
			velocity = Vector2.ZERO
			_stop_walking()
			return
		target = _path[_path_index]
		direction = target - global_position
	_update_facing(direction)
	velocity = direction.normalized() * move_speed
	var collision := move_and_collide(velocity * delta)
	if collision != null:
		_handle_unmapped_obstacle()


func become_missing() -> void:
	if _is_missing:
		return
	_is_missing = true
	_sample_watch_active = false
	Engine.set_meta(&"lab_doctor_missing", true)
	_show_overhead_bark("DR OKOYE / SIGNAL LOST", "Thura—the Echo is inside my suit!", 2.0)
	await get_tree().create_timer(1.6).timeout
	if not is_inside_tree():
		return
	remove_from_group("ship_crew")
	set_physics_process(false)
	set_process(false)
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade.finished
	if is_inside_tree():
		visible = false
		collision_layer = 0
		collision_mask = 0


func _process(delta: float) -> void:
	if not _sample_watch_active or _is_missing:
		return
	_sample_watch_timer -= delta
	if _sample_watch_timer > 0.0:
		return
	_sample_watch_timer = 17.0
	var watch_lines: Array[String] = [
		"Chamber pressure is holding. I'm checking the seal readings.",
		"The ore is reacting to the power cycle. Keep the sample under observation.",
		"Atmosphere stable for now. I'm logging each change.",
	]
	var line := watch_lines[_random.randi_range(0, watch_lines.size() - 1)]
	_show_overhead_bark("SAMPLE WATCH", line, 3.8)


func _physics_process(delta: float) -> void:
	if not _interaction_locks.is_empty(): return
	if not _navigation_ready:
		return
	if _lab_route_active:
		_process_lab_route(delta)
		return

	if _greeting_cooldown > 0.0:
		_greeting_cooldown = maxf(_greeting_cooldown - delta, 0.0)
	if _bark_cooldown > 0.0:
		_bark_cooldown = maxf(_bark_cooldown - delta, 0.0)

	if _phase == RoamPhase.SHIP_EXCURSION:
		_excursion_seconds += delta

	_check_player_proximity()

	if _idle_remaining > 0.0:
		_idle_remaining = maxf(_idle_remaining - delta, 0.0)
		velocity = Vector2.ZERO
		_stop_walking()
		if not _player_nearby and not _current_station_info.is_empty():
			var preferred_facing: Vector2 = _current_station_info.get("facing", Vector2.ZERO)
			if preferred_facing != Vector2.ZERO:
				_update_facing(preferred_facing)
		return

	if not _has_destination:
		_choose_next_destination()
		return

	if _path_index >= _path.size():
		_arrive_at_destination()
		return

	var waypoint := _path[_path_index]
	var to_waypoint := waypoint - global_position
	var distance := to_waypoint.length()
	if distance <= 2.0:
		_path_index += 1
		if _path_index >= _path.size():
			_arrive_at_destination()
		return

	var direction := to_waypoint / distance
	_update_facing(direction)
	var step_distance := minf(_current_speed * delta, distance)
	var motion := direction * step_distance

	if _is_blocked_by_closed_door(global_position + motion):
		# Door is currently opening; pause briefly so it can open instead of aborting the path
		velocity = Vector2.ZERO
		_stop_walking()
		_door_wait_retries += 1
		if _door_wait_retries < 4:
			_idle_remaining = 0.35
			return
		_door_wait_retries = 0
		_path.clear()
		_path_index = 0
		_has_destination = false
		_idle_remaining = 0.2
		return
	else:
		_door_wait_retries = 0

	velocity = direction * _current_speed
	var collision := move_and_collide(motion)
	if collision != null:
		_handle_unmapped_obstacle()
	elif not sprite.is_playing():
		sprite.play(_facing_animation)


func _build_overhead_bubble() -> void:
	_bubble_root = Node2D.new()
	_bubble_root.name = "OverheadBubble"
	_bubble_root.position = Vector2(0.0, -38.0)
	_bubble_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_bubble_root.z_index = 10
	add_child(_bubble_root)

	_bubble_panel = PanelContainer.new()
	_bubble_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_panel.custom_minimum_size = Vector2(160.0, 0.0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.035, 0.055, 0.90)
	style.border_color = Color(0.24, 0.72, 0.82, 0.90)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	_bubble_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_bubble_panel.add_child(vbox)

	_bubble_tag_label = Label.new()
	_bubble_tag_label.add_theme_font_size_override("font_size", 9)
	_bubble_tag_label.add_theme_color_override("font_color", Color(0.92, 0.72, 0.38))
	vbox.add_child(_bubble_tag_label)

	_bubble_text_label = Label.new()
	_bubble_text_label.add_theme_font_size_override("font_size", 11)
	_bubble_text_label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.96))
	_bubble_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_text_label.custom_minimum_size = Vector2(160.0, 0.0)
	vbox.add_child(_bubble_text_label)

	_bubble_root.add_child(_bubble_panel)
	# Center the bubble above Amara
	_bubble_panel.position = Vector2(-90.0, -42.0)


func _show_overhead_bark(tag: String, text: String, duration: float = 2.4) -> void:
	if not _interaction_locks.is_empty(): return
	var status: Dictionary = get_parent().get_meta("ship_system_state", {})
	if status.has("hydro") and tag == "CREW GREETING":
		text = "Hello, Thura. I'm watching the delivery readings today." if float(status.hydro.flow)<90 else "Good to see you, Thura. Delivery is holding steady."
	if status.has("hydro") and tag != "CREW GREETING":
		var hydro: Dictionary = status.hydro
		text = "Delivery is low. I'll compare the pump and reservoir readings." if float(hydro.flow) < 90.0 else "Delivery is steady. I'll keep an eye on the beds."
		if float(hydro.ec) > 2.4: text = "The reservoir reading has changed. We should check it before adding anything."
	if not is_instance_valid(_bubble_root):
		return
	_bubble_tag_label.text = "AMARA OKOYE  •  " + tag.to_upper()
	_bubble_text_label.text = text

	if is_instance_valid(_bubble_tween) and _bubble_tween.is_running():
		_bubble_tween.kill()

	_bubble_tween = create_tween()
	_bubble_tween.tween_property(_bubble_root, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_bubble_tween.tween_interval(maxf(duration - 0.5, 1.1))
	_bubble_tween.tween_property(_bubble_root, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _hide_overhead_bark() -> void:
	if not is_instance_valid(_bubble_root):
		return
	if is_instance_valid(_bubble_tween) and _bubble_tween.is_running():
		_bubble_tween.kill()
	_bubble_tween = create_tween()
	_bubble_tween.tween_property(_bubble_root, "modulate:a", 0.0, 0.20)


func _check_player_proximity() -> void:
	var players := get_tree().get_nodes_in_group("ship_player")
	if players.is_empty():
		_player_nearby = false
		return
	var player := players[0] as Node2D
	if not is_instance_valid(player):
		_player_nearby = false
		return

	var distance := global_position.distance_to(player.global_position)
	if distance <= notice_player_distance:
		var direction := player.global_position - global_position
		if not direction.is_zero_approx():
			_update_facing(direction)
		if not _player_nearby and _greeting_cooldown <= 0.0:
			_player_nearby = true
			_greeting_cooldown = 60.0
			_bark_cooldown = maxf(_bark_cooldown, 18.0)
			var greeting: String = PLAYER_GREETING_BARKS[_random.randi_range(0, PLAYER_GREETING_BARKS.size() - 1)]
			_show_overhead_bark("CREW GREETING", greeting, 2.5)
	else:
		_player_nearby = false


func _choose_next_destination() -> void:
	var found_destination := false
	match _phase:
		RoamPhase.HYDROPONICS:
			if _room_stops_remaining <= 0:
				# Completed thorough inspection of hydroponics room; transition to ship excursion
				_phase = RoamPhase.SHIP_EXCURSION
				_excursion_seconds = 0.0
				_excursion_stops_remaining = _random.randi_range(excursion_stops.x, excursion_stops.y)
				found_destination = _choose_ship_destination()
				if not found_destination:
					_phase = RoamPhase.RETURNING
					found_destination = _choose_local_destination()
			else:
				found_destination = _choose_hydroponics_station_or_cell()
		RoamPhase.SHIP_EXCURSION:
			if _excursion_stops_remaining <= 0 or _excursion_seconds >= ship_excursion_max_seconds:
				_phase = RoamPhase.RETURNING
				found_destination = _choose_local_destination()
			else:
				found_destination = _choose_ship_destination()
		RoamPhase.RETURNING:
			found_destination = _choose_local_destination()

	if not found_destination:
		_idle_remaining = 0.25


func _choose_hydroponics_station_or_cell() -> bool:
	# Prioritize systematic station inspection across her room, with occasional room patrols
	var use_station := _random.randf() < 0.75 and not HYDROPONICS_STATIONS.is_empty()
	if use_station:
		_station_index = (_station_index + _random.randi_range(1, 3)) % HYDROPONICS_STATIONS.size()
		var station := HYDROPONICS_STATIONS[_station_index]
		var target_pos: Vector2 = station["target"]
		var target_cell := _world_to_cell(target_pos)
		if _set_destination(target_cell, true):
			_current_station_info = station
			return true

	# Fallback to general patrol within Hydroponics room
	_current_station_info = {}
	return _choose_local_destination()


func _choose_local_destination() -> bool:
	var local_only := _should_use_hydroponics_grid()
	return _choose_destination_from(_hydroponics_cells, 64.0, local_only)


func _choose_ship_destination() -> bool:
	_current_station_info = {}
	for _attempt in range(12):
		var zone_index := _random.randi_range(0, _ship_zone_cells.size() - 1)
		var candidates: Array = _ship_zone_cells[zone_index]
		if _choose_destination_from(candidates, 110.0):
			return true
	return false


func _choose_destination_from(candidates: Array, minimum_distance: float, local_only: bool = false) -> bool:
	if candidates.is_empty():
		return false
	var navigation_grid: AStarGrid2D = _hydroponics_grid if local_only else _grid
	var attempts := mini(40, candidates.size())
	for _attempt in range(attempts):
		var target_cell: Vector2i = candidates[_random.randi_range(0, candidates.size() - 1)]
		if navigation_grid.is_point_solid(target_cell):
			continue
		var target_position := _cell_to_world(target_cell)
		if global_position.distance_to(target_position) < minimum_distance:
			continue
		if _set_destination(target_cell, local_only):
			return true
	return false


func _set_destination(target_cell: Vector2i, local_only: bool = false) -> bool:
	var navigation_grid: AStarGrid2D = _hydroponics_grid if local_only else _grid
	if not _grid_region.has_point(target_cell) or navigation_grid.is_point_solid(target_cell):
		return false
	var start_cell := _world_to_cell(global_position)
	if not _grid_region.has_point(start_cell):
		return false
	if navigation_grid.is_point_solid(start_cell):
		start_cell = _find_nearest_clear_cell(start_cell, local_only)
		if not _grid_region.has_point(start_cell) or navigation_grid.is_point_solid(start_cell):
			return false
	var id_path := navigation_grid.get_id_path(start_cell, target_cell)
	if id_path.is_empty():
		return false

	_path.clear()
	for cell in id_path:
		if cell != start_cell:
			_path.append(_cell_to_world(cell))
	if _path.is_empty():
		return false
	_path_index = 0
	_destination = _cell_to_world(target_cell)
	_current_speed = move_speed * _random.randf_range(movement_burst_range.x, movement_burst_range.y)
	_has_destination = true
	_hide_overhead_bark()
	return true


func _find_nearest_clear_cell(origin: Vector2i, local_only: bool = false) -> Vector2i:
	var navigation_grid: AStarGrid2D = _hydroponics_grid if local_only else _grid
	for radius in range(1, 5):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if absi(x) + absi(y) != radius:
					continue
				var candidate := origin + Vector2i(x, y)
				if _grid_region.has_point(candidate) and not navigation_grid.is_point_solid(candidate):
					return candidate
	return Vector2i(-1, -1)


func _should_use_hydroponics_grid() -> bool:
	return (
		_phase == RoamPhase.HYDROPONICS
		or (_phase == RoamPhase.RETURNING and HYDROPONICS_AREA.has_point(global_position))
	)


func _arrive_at_destination() -> void:
	_has_destination = false
	_path.clear()
	_path_index = 0
	velocity = Vector2.ZERO
	_stop_walking()

	if _phase == RoamPhase.HYDROPONICS:
		_room_stops_remaining -= 1
		_idle_remaining = _random.randf_range(local_idle_seconds.x, local_idle_seconds.y)
		if not _current_station_info.is_empty() and _bark_cooldown <= 0.0 and _random.randf() < bark_chance:
			var barks: Array = _current_station_info.get("barks", [])
			var tag: String = _current_station_info.get("tag", "INSPECTING")
			if not barks.is_empty():
				_bark_cooldown = routine_bark_cooldown_seconds
				var bark: String = barks[_random.randi_range(0, barks.size() - 1)]
				_show_overhead_bark(tag, bark, 2.4)
	elif _phase == RoamPhase.SHIP_EXCURSION:
		_excursion_stops_remaining -= 1
		_idle_remaining = _random.randf_range(ship_idle_seconds.x, ship_idle_seconds.y)
		if _bark_cooldown <= 0.0 and _random.randf() < bark_chance:
			_bark_cooldown = routine_bark_cooldown_seconds
			var patrol_info: Dictionary = SHIP_PATROL_BARKS[_random.randi_range(0, SHIP_PATROL_BARKS.size() - 1)]
			var barks: Array = patrol_info["barks"]
			var tag: String = patrol_info["tag"]
			var bark: String = barks[_random.randi_range(0, barks.size() - 1)]
			_show_overhead_bark(tag, bark, 2.4)
	elif _phase == RoamPhase.RETURNING:
		if HYDROPONICS_AREA.has_point(global_position):
			_phase = RoamPhase.HYDROPONICS
			_room_stops_remaining = _random.randi_range(room_roam_stops.x, room_roam_stops.y)
			_idle_remaining = 4.5
		else:
			_idle_remaining = 0.8


func _handle_unmapped_obstacle() -> void:
	velocity = Vector2.ZERO
	_stop_walking()
	if _path_index < _path.size():
		var blocked_cell := _world_to_cell(_path[_path_index])
		if _grid_region.has_point(blocked_cell):
			_grid.set_point_solid(blocked_cell, true)
			_hydroponics_grid.set_point_solid(blocked_cell, true)
	var target_cell := _world_to_cell(_destination)
	var local_only := _should_use_hydroponics_grid() and not _lab_route_active
	if not _set_destination(target_cell, local_only):
		_has_destination = false
		_idle_remaining = 0.25
		if _lab_route_active:
			_lab_route_active = false


func _is_blocked_by_closed_door(position_to_check: Vector2) -> bool:
	for door in get_tree().get_nodes_in_group("ship_door"):
		if door.has_method("blocks_position") and bool(door.call("blocks_position", position_to_check, BODY_RADIUS)):
			return true
	return false


func _position_is_walkable(world_position: Vector2) -> bool:
	var local_position := world_position - _floor_origin
	var pixel_x := floori(local_position.x)
	var pixel_y := floori(local_position.y)
	if pixel_x < 0 or pixel_y < 0 or pixel_x >= _floor_mask.get_width() or pixel_y >= _floor_mask.get_height():
		return false
	return _floor_mask.get_pixel(pixel_x, pixel_y).a >= FLOOR_ALPHA_THRESHOLD


func _world_to_cell(world_position: Vector2) -> Vector2i:
	var local_position := world_position - _floor_origin
	return Vector2i(floori(local_position.x / NAV_CELL_SIZE), floori(local_position.y / NAV_CELL_SIZE))


func _cell_to_world(cell: Vector2i) -> Vector2:
	return _floor_origin + Vector2((float(cell.x) + 0.5) * NAV_CELL_SIZE, (float(cell.y) + 0.5) * NAV_CELL_SIZE)


func _configure_sprite_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var cell_size := Vector2(float(WALK_ATLAS.get_width()) / 4.0, float(WALK_ATLAS.get_height()) / 4.0)
	for animation_name in ANIMATION_ROWS:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 5.0)
		frames.set_animation_loop(animation_name, true)
		var row: int = ANIMATION_ROWS[animation_name]
		for column in range(4):
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = WALK_ATLAS
			atlas_frame.region = Rect2(Vector2(column * cell_size.x, row * cell_size.y), cell_size)
			frames.add_frame(animation_name, atlas_frame)
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * DISPLAY_SCALE
	sprite.animation = _facing_animation
	sprite.stop()


func _update_facing(direction: Vector2) -> void:
	if not is_instance_valid(sprite):
		return
	if absf(direction.x) > absf(direction.y):
		_facing_animation = &"walk_right" if direction.x > 0.0 else &"walk_left"
	else:
		_facing_animation = &"walk_down" if direction.y > 0.0 else &"walk_up"
	if sprite.animation != _facing_animation or not sprite.is_playing():
		sprite.play(_facing_animation)


func _stop_walking() -> void:
	if is_instance_valid(sprite) and sprite.is_playing():
		sprite.stop()
		sprite.frame = 0


func _build_navigation() -> void:
	var floor_layer := get_parent().get_node_or_null("FloorLayer") as Sprite2D
	if floor_layer == null or floor_layer.texture == null:
		push_warning("Amara could not find the ship floor for navigation.")
		return

	# Use the same authoritative mask and origin as Thura, not the replacement
	# visual floor texture. Furniture clearance is included in the route grid.
	var actor := get_parent().get_node_or_null("Player") as ShipPlayer
	_floor_mask = actor._walkable_floor_mask if actor != null and actor._walkable_floor_mask != null else floor_layer.texture.get_image()
	if _floor_mask.is_compressed() and _floor_mask.decompress() != OK:
		push_warning("Amara could not read the ship floor mask.")
		_floor_mask = null
		return
	_floor_origin = floor_layer.global_position

	var columns := ceili(float(_floor_mask.get_width()) / NAV_CELL_SIZE)
	var rows := ceili(float(_floor_mask.get_height()) / NAV_CELL_SIZE)
	_grid_region = Rect2i(Vector2i.ZERO, Vector2i(columns, rows))
	_grid.region = _grid_region
	_grid.cell_size = Vector2.ONE
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_grid.update()
	_hydroponics_grid.region = _grid_region
	_hydroponics_grid.cell_size = Vector2.ONE
	_hydroponics_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_hydroponics_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_hydroponics_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	_hydroponics_grid.update()

	var clearance_samples: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(BODY_RADIUS, 0.0),
		Vector2(-BODY_RADIUS, 0.0),
		Vector2(0.0, BODY_RADIUS),
		Vector2(0.0, -BODY_RADIUS),
	]
	_ship_zone_cells.clear()
	for _zone in SHIP_ROAM_AREAS:
		_ship_zone_cells.append([])
	var navigation_exclusions: Array[RID] = []

	var space_state := get_world_2d().direct_space_state
	var nav_shape := CircleShape2D.new()
	nav_shape.radius = BODY_RADIUS

	for y in range(rows):
		for x in range(columns):
			var cell := Vector2i(x, y)
			var center := _cell_to_world(cell)
			var clear := true
			if get_parent().has_method("_ship_body_clear") and not get_parent()._ship_body_clear(center, navigation_exclusions, true):
				clear = false
			if clear and space_state != null:
				var q := PhysicsShapeQueryParameters2D.new()
				q.shape = nav_shape
				q.transform = Transform2D(0.0, center)
				q.collision_mask = 1
				if not space_state.intersect_shape(q, 1).is_empty():
					clear = false
			for sample_offset in clearance_samples:
				if not _position_is_walkable(center + sample_offset):
					clear = false
					break
			if not clear:
				_grid.set_point_solid(cell, true)
				_hydroponics_grid.set_point_solid(cell, true)
				continue
			if HYDROPONICS_AREA.has_point(center):
				_hydroponics_cells.append(cell)
			else:
				_hydroponics_grid.set_point_solid(cell, true)
			for zone_index in range(SHIP_ROAM_AREAS.size()):
				if SHIP_ROAM_AREAS[zone_index].has_point(center):
					var zone_cells: Array = _ship_zone_cells[zone_index]
					zone_cells.append(cell)

	_navigation_ready = not _hydroponics_cells.is_empty()
	if not _navigation_ready:
		push_warning("Amara could not find a clear hydroponics patrol route.")


func face_toward(target_pos: Vector2) -> void:
	if _is_seated_at_console:
		return
	var direction := target_pos - global_position
	if not direction.is_zero_approx():
		_update_facing(direction)


func set_in_dialogue(in_dialogue: bool) -> void:
	set_interaction_lock(&"dialogue", in_dialogue)
	if in_dialogue:
		_hide_overhead_bark()
		velocity = Vector2.ZERO
		_stop_walking()
		if is_inside_tree():
			var players := get_tree().get_nodes_in_group("ship_player")
			if not players.is_empty():
				var player := players[0] as Node2D
				if is_instance_valid(player):
					var direction := player.global_position - global_position
					if not direction.is_zero_approx():
						_update_facing(direction)

func set_interaction_lock(reason: StringName, locked: bool) -> void:
	if locked:
		_interaction_locks[reason] = true
		_hide_overhead_bark()
		velocity = Vector2.ZERO
		_stop_walking()
	else:
		_interaction_locks.erase(reason)
