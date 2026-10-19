@tool
class_name ShipExteriorAirlockGate
extends Node2D

signal opened
signal closed

const DOOR_IMAGE_PATH := "res://art/concepts/exterior_airlock_door_valkyrie.png"
const SPRITE_SIZE := Vector2(384.0, 120.0)
const TRANSITION_TIME := 0.34

@export_range(60.0, 180.0, 1.0) var opening_width: float = 96.0:
	set(value):
		opening_width = value
		_refresh_preview()
@export_range(20.0, 64.0, 1.0) var wall_depth: float = 34.0:
	set(value):
		wall_depth = value
		_refresh_preview()
@export_range(32.0, 160.0, 1.0) var activation_distance: float = 76.0
@export_range(0.2, 5.0, 0.1) var close_delay: float = 1.4

@onready var left_door_panel: Sprite2D = $LeftDoorPanel
@onready var right_door_panel: Sprite2D = $RightDoorPanel
@onready var opening_sound: AudioStreamPlayer2D = $OpenSFX

var _is_open := false
var _target_open := false
var _transitioning := false
var _close_timer := 0.0
var _transition: Tween


func _ready() -> void:
	var door_img := Image.load_from_file(ProjectSettings.globalize_path(DOOR_IMAGE_PATH))
	if door_img != null and not door_img.is_empty():
		var door_tex := ImageTexture.create_from_image(door_img)
		if is_instance_valid(left_door_panel):
			left_door_panel.texture = door_tex
		if is_instance_valid(right_door_panel):
			right_door_panel.texture = door_tex
	_refresh_preview()
	if Engine.is_editor_hint():
		set_physics_process(false)
	else:
		set_physics_process(true)


func is_open() -> bool:
	return _is_open or _target_open


func _refresh_preview() -> void:
	if not is_node_ready():
		return
	var panel_scale := Vector2(
		opening_width / SPRITE_SIZE.x,
		wall_depth / SPRITE_SIZE.y
	)
	var half_width := opening_width * 0.25
	if is_instance_valid(left_door_panel):
		left_door_panel.scale = panel_scale
		left_door_panel.position = Vector2(-half_width, 0.0)
	if is_instance_valid(right_door_panel):
		right_door_panel.scale = panel_scale
		right_door_panel.position = Vector2(half_width, 0.0)


func _physics_process(delta: float) -> void:
	var actor_near := _is_actor_near()
	if actor_near:
		_close_timer = close_delay
		if not _target_open:
			_set_open_target(true)
	elif _is_open:
		_close_timer = maxf(_close_timer - delta, 0.0)
		if is_zero_approx(_close_timer):
			_set_open_target(false)


func _set_open_target(open: bool) -> void:
	if _target_open == open and (_transitioning or _is_open == open):
		return
	_target_open = open
	_transitioning = true
	_is_open = false
	if open and is_instance_valid(opening_sound):
		opening_sound.play()
	if is_instance_valid(_transition) and _transition.is_running():
		_transition.kill()

	_transition = create_tween()
	_transition.set_parallel(true)
	_transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var half_width := opening_width * 0.25
	var opening_travel := opening_width * 0.52 if open else 0.0
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
		opened.emit()
	else:
		closed.emit()


func _is_actor_near() -> bool:
	for group_name in [&"ship_player", &"ship_crew"]:
		for actor_node in get_tree().get_nodes_in_group(group_name):
			var actor := actor_node as Node2D
			if not is_instance_valid(actor):
				continue
			var local_position := to_local(actor.global_position)
			var beyond_span := maxf(absf(local_position.x) - opening_width * 0.5, 0.0)
			var beyond_wall := maxf(absf(local_position.y) - wall_depth * 0.5, 0.0)
			if Vector2(beyond_span, beyond_wall).length() <= activation_distance:
				return true
	return false
