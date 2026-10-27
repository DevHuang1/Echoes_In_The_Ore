@tool
extends "res://scripts/ship/ship_mission_walkthrough.gd"

const FLOOR_TEXTURE := preload("res://art/overview/asteria_overview_floor.png")
const ARRIVAL_BRIEFING_SCENE := preload("res://scenes/ui/arrival_briefing.tscn")
const SERVICE_TASK_CONSOLE_SCENE := preload("res://scenes/ui/service_task_console.tscn")
const WALK_HUD_SCENE := preload("res://scenes/ui/walk_hud.tscn")
const CREW_DIALOGUE_SCENE := preload("res://scenes/ui/crew_dialogue.tscn")
const MOCK_PLANET_SCENE_PATH := "res://scenes/planet/mock_planet_exterior.tscn"
const AIRLOCK_INTERACTION_RADIUS := 74.0
const AIRLOCK_RETURN_FLOOR_POS := Vector2(478.5, 294.0)
const ROOM_TASKS := [
	{
		"id": &"auxiliary_power",
		"title": "Reconnect auxiliary power",
		"marker_label": "AUX POWER",
		"station_path": NodePath("PowerMaintenanceRoomProps/PowerCellModule"),
		"prompt": "AUXILIARY POWER CELL   /   [E] RECONNECT",
		"completion": "Power cell reconnected. Auxiliary power is restored.",
	},
	{
		"id": &"air_filter",
		"title": "Replace life-support filter",
		"marker_label": "LIFE SUPPORT",
		"station_path": NodePath("LifeSupportRoomProps/FilterCartridge"),
		"prompt": "LIFE-SUPPORT FILTER   /   [E] REPLACE",
		"completion": "Filter replaced. Life-support airflow is clear.",
	},
	{
		"id": &"nutrient_flow",
		"title": "Restore hydroponic nutrient flow",
		"marker_label": "HYDROPONICS",
		"station_path": NodePath("HydroponicsRoomProps/ControlConsole"),
		"interaction_offset": Vector2(32.0, 0.0),
		"interaction_radius": 65.0,
		"prompt": "HYDROPONICS CONSOLE   /   [E] ROUTE NUTRIENTS",
		"completion": "Nutrient manifold aligned. The grow beds are irrigating.",
	},
]
const LAB_DEVICES := [
	{
		"id": &"lab_specimen",
		"station_path": NodePath("LabRoom/NorthWorkstation"),
		"interaction_offset": Vector2(-34.0, 27.0),
		"prompt": "SPECIMEN ANALYSIS TABLE   /   [E] OPEN ANALYZER",
	},
	{
		"id": &"lab_earth_comms",
		"station_path": NodePath("LabRoom/ConsoleStation"),
		"interaction_offset": Vector2(39.0, 18.0),
		"prompt": "RESEARCH CONSOLE   /   [E] OPEN TERMINAL",
	},
	{
		"id": &"lab_containment",
		"station_path": NodePath("LabRoom/OreContainment"),
		"interaction_offset": Vector2(-28.0, 28.0),
		"prompt": "SAMPLE CONTAINMENT   /   [E] OPEN CONTROLS",
	},
	{
		"id": &"lab_trolley",
		"station_path": NodePath("LabRoom/MicroscopeCart"),
		"interaction_offset": Vector2(0.0, 38.0),
		"prompt": "INSTRUMENT TROLLEY   /   [E] OPEN INSTRUMENTS",
	},
	{
		"id": &"lab_archive_01",
		"station_path": NodePath("LabRoom/ArchiveStationLeft"),
		"interaction_offset": Vector2(-18.0, 34.0),
		"prompt": "PERSONNEL ARCHIVE   /   [E] BROWSE RECORDS",
	},
	{
		"id": &"lab_archive_02",
		"station_path": NodePath("LabRoom/ArchiveStationCenter"),
		"interaction_offset": Vector2(0.0, 34.0),
		"prompt": "SPECIMEN ARCHIVE   /   [E] BROWSE RECORDS",
	},
	{
		"id": &"lab_archive_03",
		"station_path": NodePath("LabRoom/ArchiveStationRight"),
		"interaction_offset": Vector2(18.0, 34.0),
		"prompt": "CONTAINMENT ARCHIVE   /   [E] BROWSE RECORDS",
	},
	{
		"id": &"lab_robot_arm",
		"station_path": NodePath("LabRoom/SampleManipulator"),
		"interaction_offset": Vector2(0.0, 36.0),
		"prompt": "SAMPLE MANIPULATOR   /   [E] OPEN CONTROLS",
	},
]
const ROOM_TASK_INTERACTION_RADIUS := 44.0
const AMARA_INTERACTION_RADIUS := 66.0
const CREW_TASK_INTERACTION_RADIUS := 64.0
# Keep these task points in the clear aisle beside each collidable prop.
const AMARA_CREW_TASKS := [
	{
		"id": &"amara_nutrient_pump",
		"title": "Amara: inspect the nutrient pump",
		"marker_label": "AMARA / PUMP",
		"station_path": NodePath("HydroponicsRoomProps/NutrientPump"),
		"interaction_offset": Vector2(36.0, 0.0),
		"prompt": "NUTRIENT PUMP   /   [E] INSPECT",
		"completion": "Pump inspection recorded. Verify actual delivery separately at the console.",
	},
	{
		"id": &"amara_seedling_sensor",
		"title": "Amara: recalibrate the seedling sensor",
		"marker_label": "AMARA / SEEDLINGS",
		"station_path": NodePath("HydroponicsRoomProps/SeedlingRack"),
		"interaction_offset": Vector2(44.0, 0.0),
		"prompt": "SEEDLING RACK   /   [E] CALIBRATE SENSOR",
		"completion": "Seedling sensor check recorded; the irrigation repair remains a separate procedure.",
	},
]

@export var player_spawn: Vector2 = Vector2(900.0, 500.0)
@export_file("*.tscn") var mock_planet_scene_path := MOCK_PLANET_SCENE_PATH

@onready var floor_layer: Sprite2D = $FloorLayer
@onready var wall_layer: Sprite2D = $WallLayer
@onready var exterior_airlock: Node2D = $ExteriorAirlockGate
@onready var player: ShipPlayer = $Player
@onready var amara: AmaraOkoye = $AmaraOkoye

var _completed_room_tasks: Dictionary = {}
var _active_room_task_id: StringName = &""
var _active_lab_device_id: StringName = &""
var _task_console_open := false
var _arrival_briefing_open := true
var _hud_modal_open := false
var _room_task_feedback := ""
var _pending_room_task_feedback := ""
var _room_task_feedback_timer := 0.0
var _walk_hud: WalkHud
var _crew_dialogue: CrewDialogue
var _crew_dialogue_open := false
var _amara_intro_seen := false
var _crew_tasks_unlocked := false
var _completed_crew_tasks: Dictionary = {}
var _active_amara_interaction := false
var _active_crew_task_id: StringName = &""
var _active_airlock_exit := false
var _transitioning_to_planet := false


func _load_sprite_png(sprite: Sprite2D, res_path: String) -> void:
	if not is_instance_valid(sprite):
		return
	var img := Image.load_from_file(ProjectSettings.globalize_path(res_path))
	if img != null and not img.is_empty():
		sprite.texture = ImageTexture.create_from_image(img)


func _ready() -> void:
	_load_sprite_png(floor_layer, "res://art/concepts/Refined pixel-art spacecraft floor.png")
	_load_sprite_png(wall_layer, "res://art/concepts/ship_walls_valkyrie.png")
	_load_sprite_png(get_node_or_null("CenterRecessRoom/FloorVisual") as Sprite2D, "res://art/overview/floor_modules/rooms/r03_center_recess_floor.png")
	_load_sprite_png(get_node_or_null("PowerMaintenanceRoomProps/FloorDetail/UpperDeckPanel") as Sprite2D, "res://art/overview/floor_modules/tiles/floor_tile_upper_plate.png")
	_load_sprite_png(get_node_or_null("PowerMaintenanceRoomProps/FloorDetail/PowerCellCautionInset") as Sprite2D, "res://art/overview/floor_modules/tiles/floor_tile_hazard_zone.png")
	_load_sprite_png(get_node_or_null("LifeSupportRoomProps/FloorDetail/LifeSupportDeckPanel") as Sprite2D, "res://art/overview/floor_modules/tiles/floor_tile_lower_panel.png")
	_load_sprite_png(get_node_or_null("LifeSupportRoomProps/FloorDetail/AirflowServiceGrate") as Sprite2D, "res://art/overview/floor_modules/tiles/floor_tile_small_grate.png")
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return

	# Movement samples global positions; include any saved ship-root translation.
	player.set_walkable_floor_mask(FLOOR_TEXTURE, floor_layer.global_position, 8.0)
	var map_size: Vector2 = FLOOR_TEXTURE.get_size()
	var camera_bounds := Rect2(floor_layer.position - map_size * 0.5, map_size * 2.0)
	player.set_camera_bounds(camera_bounds)

	var returning_from_planet := Engine.has_meta(&"returning_from_planet") and bool(Engine.get_meta(&"returning_from_planet"))
	if returning_from_planet:
		Engine.remove_meta(&"returning_from_planet")
		player.global_position = floor_layer.to_global(AIRLOCK_RETURN_FLOOR_POS)
	else:
		player.global_position = player_spawn

	player.camera.make_current()
	player.camera.reset_smoothing()
	player.set_physics_process(false)
	var hud_task_entries: Array[Dictionary] = []
	for task in ROOM_TASKS:
		var station := get_node_or_null(task["station_path"]) as Node2D
		if station == null:
			continue
		var interaction_pos := _room_task_interaction_position(task, station)
		hud_task_entries.append({
			"id": task["id"],
			"title": task["title"],
			"marker_label": task["marker_label"],
			"position": interaction_pos,
			"marker_position": _task_marker_position(station, task.get("interaction_offset", Vector2.ZERO)),
		})
	_walk_hud = WALK_HUD_SCENE.instantiate() as WalkHud
	_walk_hud.setup(player, hud_task_entries, floor_layer.global_position, FLOOR_TEXTURE.get_size())
	_walk_hud.modal_state_changed.connect(_on_hud_modal_state_changed)
	add_child(_walk_hud)
	_crew_dialogue = CREW_DIALOGUE_SCENE.instantiate() as CrewDialogue
	_crew_dialogue.dialogue_finished.connect(_on_amara_dialogue_finished)
	add_child(_crew_dialogue)
	ship_begin(_walk_hud,player)

	if returning_from_planet or ship_story_continuing():
		_arrival_briefing_open = false
		_walk_hud.set_walking_visible(true)
		_room_task_feedback = "AIRLOCK CYCLE COMPLETE  //  ABOARD ASTERIA-1"
		_room_task_feedback_timer = 3.5
		_update_player_walk_state()
	else:
		_walk_hud.set_walking_visible(false)
		var arrival_briefing := ARRIVAL_BRIEFING_SCENE.instantiate()
		arrival_briefing.connect(&"dismissed", _on_arrival_briefing_dismissed)
		add_child(arrival_briefing)


func _process(delta: float) -> void:
	ship_process(delta)
	if ship_control_locked():
		ship_refresh_prompt()
		return
	if _transitioning_to_planet:
		return
	if _room_task_feedback_timer > 0.0:
		_room_task_feedback_timer = maxf(_room_task_feedback_timer - delta, 0.0)
		if is_zero_approx(_room_task_feedback_timer):
			_room_task_feedback = ""

	# Allow walking straight through the huge open airlock door to exit to the planet
	if not _arrival_briefing_open and not _hud_modal_open and not _task_console_open and not _crew_dialogue_open:
		if is_instance_valid(exterior_airlock) and exterior_airlock.has_method("is_open") and bool(exterior_airlock.call("is_open")):
			var local_floor_pos := floor_layer.to_local(player.global_position)
			if local_floor_pos.x >= 434.0 and local_floor_pos.x <= 523.0 and local_floor_pos.y <= 278.0 and Input.is_action_pressed(&"move_up"):
				_exit_ship_to_planet()
				return

	_refresh_room_task_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if _transitioning_to_planet or _arrival_briefing_open or _hud_modal_open or _task_console_open or _crew_dialogue_open or not event.is_action_pressed(&"interact"):
		return
	if ship_handle_interact(event):
		return
	if _active_airlock_exit:
		get_viewport().set_input_as_handled()
		_exit_ship_to_planet()
		return
	if _active_amara_interaction:
		_begin_amara_dialogue()
	elif _active_crew_task_id != &"":
		_complete_crew_task(_active_crew_task_id)
	elif _active_lab_device_id != &"":
		_open_lab_device_console(_active_lab_device_id)
	elif _active_room_task_id != &"":
		_open_room_task_console(_active_room_task_id)
	else:
		return
	get_viewport().set_input_as_handled()


func _exit_ship_to_planet() -> void:
	if _transitioning_to_planet:
		return
	if ship_story_active():
		_ship_status = "Await the Erebos survey briefing. This watch does not authorize surface deployment."
		_ship_status_time = 7.0
		return
	_transitioning_to_planet = true
	ship_store_transit()
	var result := get_tree().change_scene_to_file(mock_planet_scene_path)
	if result != OK:
		_transitioning_to_planet = false
		Engine.remove_meta("ship_mission_transit"); Engine.remove_meta("ship_mission_transit_save_path")
		_ship_status = "The development surface could not load. You remain aboard; retry when its scene is available."
		_ship_status_time = 8.0
		_update_player_walk_state()


func _open_lab_device_console(device_id: StringName) -> void:
	if _task_console_open:
		return
	for device in LAB_DEVICES:
		if device["id"] != device_id:
			continue
		var station := get_node_or_null(device["station_path"]) as Node2D
		if station != null:
			player.face_toward(station.global_position)
		break
	_task_console_open = true
	_walk_hud.set_walking_visible(false)
	_update_player_walk_state()
	var console := SERVICE_TASK_CONSOLE_SCENE.instantiate() as ServiceTaskConsole
	console.setup(device_id, 0, 1)
	console.console_closed.connect(_on_room_task_console_closed)
	add_child(console)


func _open_room_task_console(task_id: StringName) -> void:
	if _task_console_open:
		return
	_task_console_open = true
	_walk_hud.set_walking_visible(false)
	_update_player_walk_state()
	var console := SERVICE_TASK_CONSOLE_SCENE.instantiate() as ServiceTaskConsole
	console.setup(task_id, _completed_room_tasks.size(), ROOM_TASKS.size())
	if ship_is_initialized(): ship_attach_service_console(console,task_id)
	console.task_completed.connect(_on_room_task_completed)
	console.console_closed.connect(_on_room_task_console_closed)
	add_child(console)


func _on_room_task_completed(task_id: StringName) -> void:
	if ship_is_initialized():
		ship_legacy_completed(task_id)
		return
	if _completed_room_tasks.has(task_id):
		return
	var completion := "Service task complete."
	for task in ROOM_TASKS:
		if task["id"] == task_id:
			completion = task["completion"]
			break
	_completed_room_tasks[task_id] = true
	_walk_hud.set_task_completed(task_id)
	_room_task_feedback = "%s\nSERVICE TASKS  %d / %d COMPLETE" % [
		completion,
		_completed_room_tasks.size(),
		ROOM_TASKS.size(),
	]
	if _completed_room_tasks.size() == ROOM_TASKS.size():
		_room_task_feedback = "POWER, LIFE SUPPORT, AND HYDROPONICS ONLINE\nSHIP SERVICE TASKS COMPLETE"
	_pending_room_task_feedback = _room_task_feedback


func _on_room_task_console_closed() -> void:
	ship_service_closed()
	_task_console_open = false
	_walk_hud.set_walking_visible(not _arrival_briefing_open)
	_update_player_walk_state()
	if not _pending_room_task_feedback.is_empty():
		_room_task_feedback = _pending_room_task_feedback
		_room_task_feedback_timer = 3.5
		_pending_room_task_feedback = ""


func _refresh_room_task_prompt() -> void:
	if ship_is_initialized():
		ship_refresh_prompt()
		return
	_active_room_task_id = &""
	_active_lab_device_id = &""
	_active_crew_task_id = &""
	_active_amara_interaction = false
	_active_airlock_exit = false
	if _crew_dialogue_open or not _arrival_briefing_open and (_hud_modal_open or _task_console_open):
		_walk_hud.set_interaction_prompt("", false)
		return
	if is_instance_valid(exterior_airlock):
		var airlock_access_pos := exterior_airlock.global_position + Vector2(0.0, 28.0)
		if player.global_position.distance_to(airlock_access_pos) <= AIRLOCK_INTERACTION_RADIUS:
			_active_airlock_exit = true
			_walk_hud.set_interaction_prompt("EXTERIOR AIRLOCK   /   [E] EXIT TO PLANET SURFACE", true)
			return
	if is_instance_valid(amara) and player.global_position.distance_to(amara.global_position) <= AMARA_INTERACTION_RADIUS:
		_active_amara_interaction = true
		_walk_hud.set_interaction_prompt("AMARA OKOYE   /   [E] TALK", true)
		return
	var closest_crew_task: Dictionary = {}
	var closest_crew_distance := CREW_TASK_INTERACTION_RADIUS
	for task in AMARA_CREW_TASKS:
		var task_id: StringName = task["id"]
		if _completed_crew_tasks.has(task_id):
			continue
		var station := get_node_or_null(task["station_path"]) as Node2D
		if station == null:
			continue
		var interaction_position := _crew_task_interaction_position(task, station)
		var distance := minf(
			player.global_position.distance_to(interaction_position),
			player.global_position.distance_to(station.global_position)
		)
		if distance <= closest_crew_distance:
			closest_crew_distance = distance
			closest_crew_task = task
	if not closest_crew_task.is_empty():
		_active_crew_task_id = closest_crew_task["id"]
		_walk_hud.set_interaction_prompt(closest_crew_task["prompt"], true)
		return
	var closest_device: Dictionary = {}
	var closest_device_distance := ROOM_TASK_INTERACTION_RADIUS
	for device in LAB_DEVICES:
		var station := get_node_or_null(device["station_path"]) as Node2D
		if station == null:
			continue
		var interaction_position := _room_task_interaction_position(device, station)
		var distance := player.global_position.distance_to(interaction_position)
		if distance <= closest_device_distance:
			closest_device_distance = distance
			closest_device = device
	if not closest_device.is_empty():
		_active_lab_device_id = closest_device["id"]
		_walk_hud.set_interaction_prompt(closest_device["prompt"], true)
		return
	var closest_task: Dictionary = {}
	var closest_distance := 999999.0
	for task in ROOM_TASKS:
		var task_id: StringName = task["id"]
		if _completed_room_tasks.has(task_id):
			continue
		var station_path: NodePath = task["station_path"]
		var station := get_node_or_null(station_path) as Node2D
		if station == null:
			continue
		var interaction_pos := _room_task_interaction_position(task, station)
		var max_dist: float = task.get("interaction_radius", ROOM_TASK_INTERACTION_RADIUS)
		var distance := minf(
			player.global_position.distance_to(interaction_pos),
			player.global_position.distance_to(station.global_position)
		)
		if distance <= max_dist and distance <= closest_distance:
			closest_distance = distance
			closest_task = task

	if not closest_task.is_empty():
		_active_room_task_id = closest_task["id"]
		_walk_hud.set_interaction_prompt(closest_task["prompt"], true)
	elif _room_task_feedback_timer > 0.0:
		_walk_hud.set_interaction_prompt(_room_task_feedback, true)
	else:
		_walk_hud.set_interaction_prompt("", false)


func _begin_amara_dialogue() -> void:
	if _crew_dialogue_open:
		return
	if ship_story_amara_dialogue(): return
	var first_meeting := not _amara_intro_seen
	_crew_dialogue_open = true
	_amara_intro_seen = true
	if is_instance_valid(amara) and amara.has_method("set_in_dialogue"):
		amara.set_in_dialogue(true)
	_update_player_walk_state()
	_walk_hud.set_interaction_prompt("", false)
	var lines: Array[String] = []
	var offer_tasks := not _crew_tasks_unlocked
	if offer_tasks:
		if first_meeting:
			lines.append("I'm Amara Okoye, the medic. I also tend the grow beds, and I know this section of the ship inside out.")
			lines.append("The nutrient pump needs an inspection, and the seedling rack's humidity sensor needs recalibrating.")
		else:
			lines.append("I've got two hydroponics jobs that could use another set of hands: the nutrient pump and the seedling rack sensor.")
		lines.append("Want to take them? I'll add both jobs to your duty tracker. Use the clear service point beside each station.")
	else:
		var completed_count := _completed_crew_tasks.size()
		if completed_count >= AMARA_CREW_TASKS.size():
			lines.append("Thank you for recording those checks. Delivery is currently in range." if _ship_state.systems.hydro.flow>=90 else "Thank you for recording those checks. Delivery is still low; those observations do not replace the irrigation repair.")
		elif completed_count == 1:
			for task in AMARA_CREW_TASKS:
				if not _completed_crew_tasks.has(task["id"]):
					lines.append("Good work on the first job. %s still needs attention when you have a moment." % str(task["title"]).replace("Amara: ", ""))
					break
		else:
			lines.append("The nutrient pump and seedling sensor are both in your duty tracker. Check in with me if anything looks off.")
	var observation := ship_amara_observation()
	if not observation.is_empty(): lines.append(observation)
	_crew_dialogue.start_dialogue(lines, offer_tasks)


func _on_amara_dialogue_finished(accepted_tasks: bool) -> void:
	_crew_dialogue_open = false
	if is_instance_valid(amara) and amara.has_method("set_in_dialogue"):
		amara.set_in_dialogue(false)
	if accepted_tasks and not _crew_tasks_unlocked:
		_unlock_crew_tasks_on_hud()
		_room_task_feedback = "Amara's jobs are in your duty tracker. Approach each station's clear service point."
		_room_task_feedback_timer = 4.0
	_update_player_walk_state()


func _unlock_crew_tasks_on_hud() -> void:
	if _crew_tasks_unlocked:
		return
	_crew_tasks_unlocked = true
	for task in AMARA_CREW_TASKS:
		var station := get_node_or_null(task["station_path"]) as Node2D
		if station == null:
			continue
		_walk_hud.add_task_entry({
			"id": task["id"],
			"title": task["title"],
			"description": "Optional / "+str(task["title"]),
			"marker_label": "OPTIONAL",
			"position": _crew_task_interaction_position(task, station),
			"marker_position": _task_marker_position(station),
		})


func _room_task_interaction_position(task: Dictionary, station: Node2D) -> Vector2:
	var offset: Vector2 = task.get("interaction_offset", Vector2.ZERO)
	var parent := station.get_parent() as Node2D
	if parent == null:
		return station.global_position + offset
	return parent.to_global(station.position + offset)


func _crew_task_interaction_position(task: Dictionary, station: Node2D) -> Vector2:
	if ship_is_initialized():
		for entry in _ship_points.values():
			if entry.host==station and is_instance_valid(entry.marker): return entry.marker.global_position
	var offset: Vector2 = task.get("interaction_offset", Vector2.ZERO)
	var parent := station.get_parent() as Node2D
	if parent == null:
		return station.global_position + offset
	return parent.to_global(station.position + offset)


func _task_marker_position(station: Node2D, offset: Vector2 = Vector2.ZERO) -> Vector2:
	if station is AnimatedSprite2D:
		var animated_station := station as AnimatedSprite2D
		if animated_station.sprite_frames != null:
			var texture := animated_station.sprite_frames.get_frame_texture(animated_station.animation, animated_station.frame)
			if texture != null:
				var top_offset := animated_station.offset + Vector2(0.0, -texture.get_height() * 0.5 - 12.0) + offset
				return animated_station.to_global(top_offset)
	return station.global_position + Vector2(0.0, -36.0) + offset


func _complete_crew_task(task_id: StringName) -> void:
	if _completed_crew_tasks.has(task_id):
		return
	if not _crew_tasks_unlocked:
		_unlock_crew_tasks_on_hud()
	var completion := "Hydroponics check complete."
	for task in AMARA_CREW_TASKS:
		if task["id"] == task_id:
			completion = task["completion"]
			break
	_completed_crew_tasks[task_id] = true
	_walk_hud.set_task_completed(task_id)
	_room_task_feedback = "%s\nAMARA'S JOBS  %d / %d COMPLETE" % [completion, _completed_crew_tasks.size(), AMARA_CREW_TASKS.size()]
	_room_task_feedback_timer = 4.0


func _on_arrival_briefing_dismissed() -> void:
	_arrival_briefing_open = false
	if ship_story_active() and _ship_cue_active.get("cue_id") == "cue.asteria.arrival":
		ship_finish_story_cue("cue.asteria.arrival", str(_ship_cue_active.request_token), "completed")
	_walk_hud.set_walking_visible(true)
	_update_player_walk_state()


func _on_hud_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	_update_player_walk_state()


func _update_player_walk_state() -> void:
	player.set_physics_process(not (_arrival_briefing_open or _hud_modal_open or _task_console_open or _crew_dialogue_open or ship_control_locked()))
