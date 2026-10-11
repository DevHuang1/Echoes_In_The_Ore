@tool
class_name ShipPressureDoor
extends Node2D

signal opened(door_id: StringName)
signal closed(door_id: StringName)

@export var door_id: StringName = &"door"
@export_enum("Horizontal", "Vertical") var orientation: int = 0:
	set(value):
		orientation = value
		_refresh_preview()
@export_range(24.0, 80.0, 1.0) var opening_width: float = 44.0:
	set(value):
		opening_width = value
		_refresh_preview()
@export_range(16.0, 36.0, 1.0) var wall_depth: float = 24.0:
	set(value):
		wall_depth = value
		_refresh_preview()
@export_range(24.0, 140.0, 1.0) var activation_distance: float = 24.0
@export_range(0.1, 5.0, 0.1) var close_delay: float = 1.1
@export var locked: bool = false

const TRANSITION_TIME := 0.24
const SPRITE_SIZE := Vector2(1000.0, 600.0)
const WALL_DEPTH_INSET := 0.90

@onready var left_door_panel: Sprite2D = $LeftDoorPanel
@onready var right_door_panel: Sprite2D = $RightDoorPanel
@onready var opening_sound: AudioStreamPlayer2D = $OpenSFX

var _is_open := false
var _target_open := false
var _transitioning := false
var _close_timer := 0.0
var _transition: Tween


func _ready() -> void:
	_refresh_preview()
	if Engine.is_editor_hint():
		set_physics_process(false)
	else:
		add_to_group("ship_door")
		set_physics_process(true)


func _refresh_preview() -> void:
	if not is_node_ready():
		return
	rotation = PI * 0.5 if orientation == 1 else 0.0
	var panel_scale := Vector2(
		opening_width / SPRITE_SIZE.x, wall_depth * WALL_DEPTH_INSET / SPRITE_SIZE.y
	)
	var half_width := opening_width * 0.25
	left_door_panel.scale = panel_scale
	right_door_panel.scale = panel_scale
	left_door_panel.position = Vector2(-half_width, 0.0)
	right_door_panel.position = Vector2(half_width, 0.0)


func _physics_process(delta: float) -> void:
	var player_near := _is_player_near()
	if locked:
		_close_timer = 0.0
		if _target_open:
			_set_open_target(false)
		return

	if player_near:
		_close_timer = close_delay
		if not _target_open:
			_set_open_target(true)
	elif _is_open:
		_close_timer = maxf(_close_timer - delta, 0.0)
		if is_zero_approx(_close_timer):
			_set_open_target(false)


func blocks_position(world_position: Vector2, body_margin: float = 0.0) -> bool:
	if _is_open:
		return false
	var local_position := to_local(world_position)
	return (
		absf(local_position.x) <= opening_width * 0.5 + body_margin
		and absf(local_position.y) <= wall_depth * 0.5 + body_margin
	)


func set_locked(value: bool) -> void:
	locked = value
	if locked:
		_close_timer = 0.0
		_set_open_target(false)


func _set_open_target(open: bool) -> void:
	if _target_open == open and (_transitioning or _is_open == open):
		return
	_target_open = open
	_transitioning = true
	_is_open = false
	if open:
		opening_sound.play()
	if is_instance_valid(_transition) and _transition.is_running():
		_transition.kill()

	_transition = create_tween()
	_transition.set_parallel(true)
	_transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var half_width := opening_width * 0.25
	var opening_travel := opening_width * 0.9 if open else 0.0
	_transition.tween_property(
		left_door_panel,
		"position",
		Vector2(-half_width - opening_travel, 0.0),
		TRANSITION_TIME
	)
	_transition.tween_property(
		right_door_panel,
		"position",
		Vector2(half_width + opening_travel, 0.0),
		TRANSITION_TIME
	)
	_transition.finished.connect(_finish_transition.bind(open))


func _finish_transition(open: bool) -> void:
	_transitioning = false
	_is_open = open
	if open:
		opened.emit(door_id)
	else:
		closed.emit(door_id)


func _is_player_near() -> bool:
	var players := get_tree().get_nodes_in_group("ship_player")
	if players.is_empty():
		return false
	var player := players[0] as Node2D
	if not is_instance_valid(player):
		return false
	var local_position := to_local(player.global_position)
	var beyond_span := maxf(absf(local_position.x) - opening_width * 0.5, 0.0)
	var beyond_wall := maxf(absf(local_position.y) - wall_depth * 0.5, 0.0)
	return Vector2(beyond_span, beyond_wall).length() <= activation_distance
