@tool
class_name ShipExteriorAirlockGate
extends Node2D

signal opened
signal closed

const DOOR_IMAGE_PATH := "res://art/concepts/exterior_airlock_door_valkyrie.png"
const SPRITE_SIZE := Vector2(384.0, 120.0)
const PANEL_TEX_WIDTH := 192.0
const TRANSITION_TIME := 0.34

@export_range(60.0, 180.0, 1.0) var opening_width: float = 96.0:
	set(value):
		opening_width = value
		_refresh_preview()
@export_range(20.0, 64.0, 1.0) var wall_depth: float = 34.0:
	set(value):
		wall_depth = value
		_refresh_preview()
@export_range(32.0, 160.0, 1.0) var activation_distance: float = 84.0
@export_range(0.2, 5.0, 0.1) var close_delay: float = 1.4

@onready var left_door_panel: Sprite2D = $LeftDoorPanel
@onready var right_door_panel: Sprite2D = $RightDoorPanel
@onready var opening_sound: AudioStreamPlayer2D = $OpenSFX

var _is_open: bool = false
var _target_open: bool = false
var _transitioning: bool = false
var _close_timer: float = 0.0
var _open_progress: float = 0.0
var _transition: Tween


func _ready() -> void:
	z_index = 0
	var door_img: Image = Image.load_from_file(ProjectSettings.globalize_path(DOOR_IMAGE_PATH))
	if door_img != null and not door_img.is_empty():
		var door_tex: ImageTexture = ImageTexture.create_from_image(door_img)
		if is_instance_valid(left_door_panel):
			left_door_panel.texture = door_tex
		if is_instance_valid(right_door_panel):
			right_door_panel.texture = door_tex
	_refresh_preview()
	queue_redraw()
	if Engine.is_editor_hint():
		set_physics_process(false)
	else:
		set_physics_process(true)


func is_open() -> bool:
	return _is_open or _target_open


func _draw() -> void:
	# Draw the dark recessed airlock threshold & frame so opening the door reveals the airlock shaft
	var half_w: float = opening_width * 0.5
	var half_h: float = wall_depth * 0.5
	var outer_rect: Rect2 = Rect2(Vector2(-half_w - 3.0, -half_h - 2.0), Vector2(opening_width + 6.0, wall_depth + 4.0))
	var shaft_rect: Rect2 = Rect2(Vector2(-half_w + 2.0, -half_h + 2.0), Vector2(opening_width - 4.0, wall_depth - 4.0))
	draw_rect(outer_rect, Color(0.11, 0.14, 0.18, 0.98), true)
	draw_rect(shaft_rect, Color(0.02, 0.04, 0.07, 0.98), true)
	# Threshold floor grate bars & status LEDs
	for i in range(-3, 4):
		var gx: float = float(i) * (opening_width * 0.12)
		draw_line(Vector2(gx, -half_h + 4.0), Vector2(gx, half_h - 4.0), Color(0.16, 0.24, 0.30, 0.75), 1.5)
	var led_col: Color = Color(0.32, 0.96, 0.62, 0.95) if is_open() else Color(1.0, 0.64, 0.24, 0.92)
	draw_rect(Rect2(Vector2(-half_w - 1.0, -3.0), Vector2(3.0, 6.0)), led_col, true)
	draw_rect(Rect2(Vector2(half_w - 2.0, -3.0), Vector2(3.0, 6.0)), led_col, true)
	draw_rect(outer_rect, Color(0.30, 0.42, 0.48, 0.92), false, 1.5)


func _refresh_preview() -> void:
	if not is_node_ready():
		return
	var panel_scale: Vector2 = Vector2(
		opening_width / SPRITE_SIZE.x,
		wall_depth / SPRITE_SIZE.y
	)
	if is_instance_valid(left_door_panel):
		left_door_panel.scale = panel_scale
	if is_instance_valid(right_door_panel):
		right_door_panel.scale = panel_scale
	_apply_open_progress(_open_progress)
	queue_redraw()


func _apply_open_progress(progress: float) -> void:
	_open_progress = clampf(progress, 0.0, 1.0)
	if not is_node_ready():
		return
	var half_width: float = opening_width * 0.25
	var slide_travel: float = (opening_width * 0.46) * _open_progress
	if is_instance_valid(left_door_panel):
		left_door_panel.visible = true
		left_door_panel.region_rect = Rect2(0.0, 0.0, PANEL_TEX_WIDTH, SPRITE_SIZE.y)
		left_door_panel.position = Vector2(-half_width - slide_travel, 0.0)
	if is_instance_valid(right_door_panel):
		right_door_panel.visible = true
		right_door_panel.region_rect = Rect2(PANEL_TEX_WIDTH, 0.0, PANEL_TEX_WIDTH, SPRITE_SIZE.y)
		right_door_panel.position = Vector2(half_width + slide_travel, 0.0)
	queue_redraw()


func _physics_process(delta: float) -> void:
	var actor_near: bool = _is_actor_near()
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

	var target_progress: float = 1.0 if open else 0.0
	_transition = create_tween()
	_transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_transition.tween_method(_apply_open_progress, _open_progress, target_progress, TRANSITION_TIME)
	_transition.finished.connect(_finish_transition.bind(open))


func _finish_transition(open: bool) -> void:
	_transitioning = false
	_is_open = open
	_apply_open_progress(1.0 if open else 0.0)
	if open:
		opened.emit()
	else:
		closed.emit()


func _is_actor_near() -> bool:
	for group_name in [&"ship_player", &"ship_crew"]:
		for actor_node in get_tree().get_nodes_in_group(group_name):
			var actor: Node2D = actor_node as Node2D
			if not is_instance_valid(actor):
				continue
			var local_position: Vector2 = to_local(actor.global_position)
			var beyond_span: float = maxf(absf(local_position.x) - opening_width * 0.5, 0.0)
			var beyond_wall: float = maxf(absf(local_position.y) - wall_depth * 0.5, 0.0)
			if Vector2(beyond_span, beyond_wall).length() <= activation_distance:
				return true
	return false
