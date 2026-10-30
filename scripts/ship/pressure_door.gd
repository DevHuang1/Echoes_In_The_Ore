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
const PANEL_TEX_WIDTH := 500.0
const WALL_DEPTH_INSET := 0.90

@onready var left_door_panel: Sprite2D = $LeftDoorPanel
@onready var right_door_panel: Sprite2D = $RightDoorPanel
@onready var opening_sound: AudioStreamPlayer2D = $OpenSFX

var _is_open := false
var _target_open := false
var _transitioning := false
var _close_timer := 0.0
var _open_progress := 0.0
var _transition: Tween
var _vapor_particles: Array[Dictionary] = []
var _slam_shockwave_timer := 0.0
var _led_pulse_time := 0.0


func _ready() -> void:
	_refresh_preview()
	if Engine.is_editor_hint():
		set_physics_process(false)
	else:
		add_to_group("ship_door")
		set_physics_process(true)
		set_process(true)


func _process(delta: float) -> void:
	_led_pulse_time = fposmod(_led_pulse_time + delta * 6.0, 1000.0)
	if _slam_shockwave_timer > 0.0:
		_slam_shockwave_timer = maxf(_slam_shockwave_timer - delta, 0.0)

	var idx := _vapor_particles.size() - 1
	while idx >= 0:
		var p: Dictionary = _vapor_particles[idx]
		var t: float = float(p["timer"]) - delta
		if t <= 0.0:
			_vapor_particles.remove_at(idx)
		else:
			p["timer"] = t
			var p_pos: Vector2 = p["pos"]
			var p_vel: Vector2 = p["vel"]
			p["pos"] = p_pos + p_vel * delta
			p["vel"] = p_vel * pow(0.35, delta)
			_vapor_particles[idx] = p
		idx -= 1
	queue_redraw()


func _refresh_preview() -> void:
	if not is_node_ready():
		return
	rotation = PI * 0.5 if orientation == 1 else 0.0
	var panel_scale := Vector2(
		opening_width / SPRITE_SIZE.x, wall_depth * WALL_DEPTH_INSET / SPRITE_SIZE.y
	)
	left_door_panel.scale = panel_scale
	right_door_panel.scale = panel_scale
	_apply_open_progress(_open_progress)


func _apply_open_progress(progress: float) -> void:
	_open_progress = clampf(progress, 0.0, 1.0)
	if not is_node_ready():
		return
	var vis_frac := 1.0 - _open_progress
	if vis_frac <= 0.005:
		left_door_panel.visible = false
		right_door_panel.visible = false
		return

	left_door_panel.visible = true
	right_door_panel.visible = true
	var region_w := maxf(PANEL_TEX_WIDTH * vis_frac, 1.0)
	left_door_panel.region_rect = Rect2(
		PANEL_TEX_WIDTH * _open_progress,
		0.0,
		region_w,
		SPRITE_SIZE.y
	)
	right_door_panel.region_rect = Rect2(
		PANEL_TEX_WIDTH,
		0.0,
		region_w,
		SPRITE_SIZE.y
	)
	var center_offset := opening_width * 0.25 * (1.0 + _open_progress)
	left_door_panel.position = Vector2(-center_offset, 0.0)
	right_door_panel.position = Vector2(center_offset, 0.0)


func _physics_process(delta: float) -> void:
	var actor_near := _is_actor_near()
	if locked:
		_close_timer = 0.0
		if _target_open:
			_set_open_target(false)
		return

	if actor_near:
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
		_spawn_decompression_vapor()
	else:
		DialogueAudioSynth.play_sfx_2d("door_close", global_position, self, -3.0)
	if is_instance_valid(_transition) and _transition.is_running():
		_transition.kill()

	var target_progress := 1.0 if open else 0.0
	_transition = create_tween()
	_transition.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_transition.tween_method(_apply_open_progress, _open_progress, target_progress, TRANSITION_TIME)
	_transition.finished.connect(_finish_transition.bind(open))


func _finish_transition(open: bool) -> void:
	_transitioning = false
	_is_open = open
	_apply_open_progress(1.0 if open else 0.0)
	if open:
		opened.emit(door_id)
	else:
		_slam_shockwave_timer = 0.35
		closed.emit(door_id)


func _spawn_decompression_vapor() -> void:
	# Twin horizontal pneumatic decompression gas bursts from door jambs
	for side in [-1.0, 1.0]:
		for i in range(8):
			var spd := randf_range(38.0, 85.0)
			var angle := (0.0 if side > 0.0 else PI) + randf_range(-0.35, 0.35)
			_vapor_particles.append({
				"pos": Vector2(side * (opening_width * 0.22), randf_range(-wall_depth * 0.25, wall_depth * 0.25)),
				"vel": Vector2(cos(angle), sin(angle)) * spd,
				"timer": randf_range(0.28, 0.48),
				"max_timer": 0.48,
				"size": randf_range(2.5, 5.0),
				"color": Color(0.72, 0.92, 1.0, 0.65),
			})


func _draw() -> void:
	# 1. Door status LED indicator strip above frame
	var led_pos := Vector2(0.0, -wall_depth * 0.5 - 2.5)
	var led_col := Color(0.28, 0.92, 0.65)
	if locked:
		var blink := 0.5 + 0.5 * sin(_led_pulse_time * 1.5)
		led_col = Color(1.0, 0.18, 0.12, 0.95 * blink)
	elif _transitioning:
		var blink := 0.5 + 0.5 * sin(_led_pulse_time * 3.0)
		led_col = Color(1.0, 0.72, 0.22, 0.95 * blink)
	elif not _is_open:
		led_col = Color(0.35, 0.82, 0.95, 0.65)
	draw_circle(led_pos, 3.2, Color(led_col.r, led_col.g, led_col.b, 0.25))
	draw_circle(led_pos, 1.4, led_col)

	# 2. Decompression steam vapor bursts
	for p in _vapor_particles:
		var p_t: float = clampf(float(p["timer"]) / float(p["max_timer"]), 0.0, 1.0)
		var p_pos: Vector2 = p["pos"]
		var p_sz: float = float(p["size"]) * (1.8 - 0.8 * p_t)
		var p_col: Color = p["color"]
		p_col.a *= pow(p_t, 1.2)
		draw_circle(p_pos, p_sz, p_col)
		draw_circle(p_pos + Vector2(p_sz * 0.3, -1.0), p_sz * 0.6, Color(1.0, 1.0, 1.0, p_col.a * 0.6))

	# 3. Bulkhead slam floor contact shockwave ring
	if _slam_shockwave_timer > 0.0:
		var s_norm := 1.0 - (_slam_shockwave_timer / 0.35)
		var ring_rx := opening_width * 0.3 + s_norm * 24.0
		var ring_ry := wall_depth * 0.4 + s_norm * 12.0
		var slam_col := Color(0.68, 0.82, 0.95, (1.0 - s_norm) * 0.65)
		var pts := PackedVector2Array()
		for i in range(17):
			var a := TAU * float(i) / 16.0
			pts.append(Vector2(cos(a) * ring_rx, sin(a) * ring_ry))
		draw_polyline(pts, slam_col, 1.4, false)


func _is_actor_near() -> bool:
	for group_name in [&"ship_player", &"ship_crew", &"ship_villain", &"resonance_ore_villain"]:
		for actor_node in get_tree().get_nodes_in_group(group_name):
			var actor := actor_node as Node2D
			if not is_instance_valid(actor) or not actor.visible:
				continue
			var local_position := to_local(actor.global_position)
			var beyond_span := maxf(absf(local_position.x) - opening_width * 0.5, 0.0)
			var beyond_wall := maxf(absf(local_position.y) - wall_depth * 0.5, 0.0)
			var threshold := activation_distance + (16.0 if (group_name == &"ship_villain" or group_name == &"resonance_ore_villain") else 0.0)
			if Vector2(beyond_span, beyond_wall).length() <= threshold:
				return true
	return false
