extends Node2D

const FLOOR_TEXTURE := preload("res://art/overview/asteria_overview_floor.png")
const ARRIVAL_BRIEFING_SCENE := preload("res://scenes/ui/arrival_briefing.tscn")
const ROOM_TASKS := [
	{
		"id": &"auxiliary_power",
		"station_path": NodePath("PowerMaintenanceRoomProps/PowerCellModule"),
		"prompt": "AUXILIARY POWER CELL\nE  Reconnect the power cell",
		"completion": "Power cell reconnected. Auxiliary power is restored.",
	},
	{
		"id": &"air_filter",
		"station_path": NodePath("LifeSupportRoomProps/FilterCartridge"),
		"prompt": "LIFE SUPPORT FILTER\nE  Replace the clogged cartridge",
		"completion": "Filter replaced. Life-support airflow is clear.",
	},
]
const ROOM_TASK_INTERACTION_RADIUS := 44.0

@export var player_spawn: Vector2 = Vector2(900.0, 500.0)

@onready var floor_layer: Sprite2D = $FloorLayer
@onready var player: ShipPlayer = $Player

var _completed_room_tasks: Dictionary = {}
var _active_room_task_id: StringName = &""
var _room_task_feedback := ""
var _room_task_feedback_timer := 0.0
var _room_task_panel: PanelContainer
var _room_task_label: Label


func _ready() -> void:
	_create_room_task_hud()
	player.set_walkable_floor_mask(FLOOR_TEXTURE, floor_layer.position, 8.0)
	var map_size: Vector2 = FLOOR_TEXTURE.get_size()
	var camera_bounds := Rect2(floor_layer.position - map_size * 0.5, map_size * 2.0)
	player.set_camera_bounds(camera_bounds)
	player.global_position = player_spawn
	player.camera.make_current()
	player.camera.reset_smoothing()
	player.set_physics_process(false)
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
	if not event.is_action_pressed(&"interact") or _active_room_task_id == &"":
		return
	for task in ROOM_TASKS:
		if task["id"] != _active_room_task_id:
			continue
		_completed_room_tasks[_active_room_task_id] = true
		_room_task_feedback = "%s\nSERVICE TASKS  %d / %d COMPLETE" % [
			task["completion"],
			_completed_room_tasks.size(),
			ROOM_TASKS.size(),
		]
		if _completed_room_tasks.size() == ROOM_TASKS.size():
			_room_task_feedback = "AUXILIARY POWER AND LIFE SUPPORT ONLINE\nSHIP SERVICE TASKS COMPLETE"
		_room_task_feedback_timer = 3.5
		_active_room_task_id = &""
		get_viewport().set_input_as_handled()
		return


func _create_room_task_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "RoomTaskHUD"
	canvas.layer = 10
	add_child(canvas)

	_room_task_panel = PanelContainer.new()
	_room_task_panel.name = "ServiceTaskPrompt"
	_room_task_panel.anchor_left = 0.5
	_room_task_panel.anchor_right = 0.5
	_room_task_panel.anchor_top = 1.0
	_room_task_panel.anchor_bottom = 1.0
	_room_task_panel.offset_left = -235.0
	_room_task_panel.offset_top = -91.0
	_room_task_panel.offset_right = 235.0
	_room_task_panel.offset_bottom = -20.0
	_room_task_panel.custom_minimum_size = Vector2(470.0, 70.0)
	_room_task_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.045, 0.055, 0.94)
	panel_style.border_color = Color(1.0, 0.62, 0.28, 0.92)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(12.0)
	_room_task_panel.add_theme_stylebox_override("panel", panel_style)
	canvas.add_child(_room_task_panel)

	_room_task_label = Label.new()
	_room_task_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_room_task_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_room_task_label.add_theme_font_size_override("font_size", 15)
	_room_task_label.add_theme_color_override("font_color", Color(0.96, 0.91, 0.82))
	_room_task_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_room_task_panel.add_child(_room_task_label)


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
		_room_task_label.text = closest_task["prompt"]
		_room_task_panel.visible = true
	elif _room_task_feedback_timer > 0.0:
		_room_task_label.text = _room_task_feedback
		_room_task_panel.visible = true
	else:
		_room_task_panel.visible = false


func _on_arrival_briefing_dismissed() -> void:
	player.set_physics_process(true)
