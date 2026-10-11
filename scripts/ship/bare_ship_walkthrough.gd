extends Node2D

const FLOOR_TEXTURE := preload("res://art/overview/asteria_overview_floor.png")
const ARRIVAL_BRIEFING_SCENE := preload("res://scenes/ui/arrival_briefing.tscn")
const SERVICE_TASK_CONSOLE_SCENE := preload("res://scenes/ui/service_task_console.tscn")
const WALK_HUD_SCENE := preload("res://scenes/ui/walk_hud.tscn")
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
		"prompt": "HYDROPONICS CONSOLE   /   [E] ROUTE NUTRIENTS",
		"completion": "Nutrient manifold aligned. The grow beds are irrigating.",
	},
]
const ROOM_TASK_INTERACTION_RADIUS := 44.0

@export var player_spawn: Vector2 = Vector2(900.0, 500.0)

@onready var floor_layer: Sprite2D = $FloorLayer
@onready var player: ShipPlayer = $Player

var _completed_room_tasks: Dictionary = {}
var _active_room_task_id: StringName = &""
var _task_console_open := false
var _arrival_briefing_open := true
var _hud_modal_open := false
var _room_task_feedback := ""
var _pending_room_task_feedback := ""
var _room_task_feedback_timer := 0.0
var _walk_hud: WalkHud


func _ready() -> void:
	player.set_walkable_floor_mask(FLOOR_TEXTURE, floor_layer.position, 8.0)
	var map_size: Vector2 = FLOOR_TEXTURE.get_size()
	var camera_bounds := Rect2(floor_layer.position - map_size * 0.5, map_size * 2.0)
	player.set_camera_bounds(camera_bounds)
	player.global_position = player_spawn
	player.camera.make_current()
	player.camera.reset_smoothing()
	player.set_physics_process(false)
	var hud_task_entries: Array[Dictionary] = []
	for task in ROOM_TASKS:
		var station := get_node_or_null(task["station_path"]) as Node2D
		if station == null:
			continue
		hud_task_entries.append({
			"id": task["id"],
			"title": task["title"],
			"marker_label": task["marker_label"],
			"position": station.global_position,
		})
	_walk_hud = WALK_HUD_SCENE.instantiate() as WalkHud
	_walk_hud.setup(player, hud_task_entries, floor_layer.global_position, FLOOR_TEXTURE.get_size())
	_walk_hud.modal_state_changed.connect(_on_hud_modal_state_changed)
	add_child(_walk_hud)
	_walk_hud.set_walking_visible(false)
	var arrival_briefing := ARRIVAL_BRIEFING_SCENE.instantiate()
	arrival_briefing.connect(&"dismissed", _on_arrival_briefing_dismissed)
	add_child(arrival_briefing)


func _process(delta: float) -> void:
	if _room_task_feedback_timer > 0.0:
		_room_task_feedback_timer = maxf(_room_task_feedback_timer - delta, 0.0)
		if is_zero_approx(_room_task_feedback_timer):
			_room_task_feedback = ""
	_refresh_room_task_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if _arrival_briefing_open or _hud_modal_open or _task_console_open or not event.is_action_pressed(&"interact") or _active_room_task_id == &"":
		return
	_open_room_task_console(_active_room_task_id)
	get_viewport().set_input_as_handled()


func _open_room_task_console(task_id: StringName) -> void:
	if _task_console_open:
		return
	_task_console_open = true
	_walk_hud.set_walking_visible(false)
	_update_player_walk_state()
	var console := SERVICE_TASK_CONSOLE_SCENE.instantiate() as ServiceTaskConsole
	console.setup(task_id, _completed_room_tasks.size(), ROOM_TASKS.size())
	console.task_completed.connect(_on_room_task_completed)
	console.console_closed.connect(_on_room_task_console_closed)
	add_child(console)


func _on_room_task_completed(task_id: StringName) -> void:
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
	_task_console_open = false
	_walk_hud.set_walking_visible(not _arrival_briefing_open)
	_update_player_walk_state()
	if not _pending_room_task_feedback.is_empty():
		_room_task_feedback = _pending_room_task_feedback
		_room_task_feedback_timer = 3.5
		_pending_room_task_feedback = ""

func _refresh_room_task_prompt() -> void:
	_active_room_task_id = &""
	var closest_task: Dictionary = {}
	var closest_distance := ROOM_TASK_INTERACTION_RADIUS
	for task in ROOM_TASKS:
		var task_id: StringName = task["id"]
		if _completed_room_tasks.has(task_id):
			continue
		var station_path: NodePath = task["station_path"]
		var station := get_node_or_null(station_path) as Node2D
		if station == null:
			continue
		var distance := player.global_position.distance_to(station.global_position)
		if distance <= closest_distance:
			closest_distance = distance
			closest_task = task

	if not closest_task.is_empty():
		_active_room_task_id = closest_task["id"]
		_walk_hud.set_interaction_prompt(closest_task["prompt"], true)
	elif _room_task_feedback_timer > 0.0:
		_walk_hud.set_interaction_prompt(_room_task_feedback, true)
	else:
		_walk_hud.set_interaction_prompt("", false)


func _on_arrival_briefing_dismissed() -> void:
	_arrival_briefing_open = false
	_walk_hud.set_walking_visible(true)
	_update_player_walk_state()


func _on_hud_modal_state_changed(is_open: bool) -> void:
	_hud_modal_open = is_open
	_update_player_walk_state()


func _update_player_walk_state() -> void:
	player.set_physics_process(not (_arrival_briefing_open or _hud_modal_open or _task_console_open))
