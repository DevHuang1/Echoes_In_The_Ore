class_name ShipPlayer
extends CharacterBody2D
signal concealment_changed(concealed: bool, source_id: String)
var is_concealed := false
var concealment_source := ""

const THURA_ATLAS := preload("res://art/characters/runtime/thura_walk_4dir.png")
const CELL_SIZE := Vector2(313.5, 313.5)
const ANIMATION_ROWS := {
	&"walk_down": 0,
	&"walk_left": 1,
	&"walk_right": 2,
	&"walk_up": 3,
}

@export var move_speed: float = 150.0
@export var sprite_scale: Vector2 = Vector2(0.12, 0.12)

@onready var camera: Camera2D = $Camera2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _facing_animation: StringName = &"walk_down"
var _camera_bounds := Rect2(Vector2.ZERO, Vector2(1774.0, 887.0))
var _walkable_floor_mask: Image
var _walkable_floor_origin := Vector2.ZERO
var _walkable_body_margin := 8.0


func _ready() -> void:
	add_to_group("ship_player")
	_configure_sprite_animations()
	sprite.scale = sprite_scale
	sprite.play(_facing_animation)
	sprite.stop()
	get_viewport().size_changed.connect(_update_camera_limits)
	_update_camera_limits()


func _physics_process(delta: float) -> void:
	if is_concealed: return
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var movement := direction * move_speed * delta
	if _has_walkable_floor_mask():
		_move_on_walkable_floor(movement)
	elif not movement.is_zero_approx():
		move_and_collide(movement)
	if direction.length_squared() > 0.0:
		_update_facing(direction)
		if not sprite.is_playing():
			sprite.play(_facing_animation)
	elif sprite.is_playing():
		sprite.stop()
		sprite.frame = 0


func set_camera_bounds(bounds: Rect2) -> void:
	_camera_bounds = bounds
	_update_camera_limits()
	camera.reset_smoothing()


func face_toward(target_position: Vector2) -> void:
	var direction := target_position - global_position
	if direction.is_zero_approx():
		return
	if absf(direction.x) > absf(direction.y):
		_facing_animation = &"walk_right" if direction.x > 0.0 else &"walk_left"
	else:
		_facing_animation = &"walk_down" if direction.y > 0.0 else &"walk_up"
	sprite.animation = _facing_animation
	sprite.stop()
	sprite.frame = 0


func set_concealment(value: bool, source_id: String) -> void:
	is_concealed=value;concealment_source=source_id if value else ""
	if is_instance_valid(sprite): sprite.visible=not value
	if value: add_to_group("concealed_players")
	elif is_in_group("concealed_players"): remove_from_group("concealed_players")
	set_meta("concealed",value);set_meta("concealment_source",concealment_source)
	concealment_changed.emit(value,concealment_source)


func set_walkable_floor_mask(floor_texture: Texture2D, floor_origin: Vector2 = Vector2.ZERO, body_margin: float = 8.0) -> void:
	_walkable_floor_mask = floor_texture.get_image()
	if _walkable_floor_mask.is_compressed():
		var error := _walkable_floor_mask.decompress()
		if error != OK:
			push_error("Could not decompress the walkable floor mask.")
			_walkable_floor_mask = null
			return
	_walkable_floor_origin = floor_origin
	_walkable_body_margin = maxf(body_margin, 0.0)


func _has_walkable_floor_mask() -> bool:
	return _walkable_floor_mask != null and not _walkable_floor_mask.is_empty()


func _move_on_walkable_floor(movement: Vector2) -> void:
	if not is_zero_approx(movement.x):
		var horizontal_position := global_position + Vector2(movement.x, 0.0)
		if _is_body_over_floor(horizontal_position):
			move_and_collide(Vector2(movement.x, 0.0))
	if not is_zero_approx(movement.y):
		var vertical_position := global_position + Vector2(0.0, movement.y)
		if _is_body_over_floor(vertical_position):
			move_and_collide(Vector2(0.0, movement.y))


func _is_body_over_floor(center: Vector2, ignore_doors_for_access_planning := false) -> bool:
	if not ignore_doors_for_access_planning:
		for door in get_tree().get_nodes_in_group("ship_door"):
			if door.has_method("blocks_position") and bool(door.call("blocks_position", center, _walkable_body_margin)):
				return false
	var diagonal := _walkable_body_margin * 0.70710678
	var offsets: Array[Vector2] = [
		Vector2.ZERO,
		Vector2(_walkable_body_margin, 0.0),
		Vector2(-_walkable_body_margin, 0.0),
		Vector2(0.0, _walkable_body_margin),
		Vector2(0.0, -_walkable_body_margin),
		Vector2(diagonal, diagonal),
		Vector2(diagonal, -diagonal),
		Vector2(-diagonal, diagonal),
		Vector2(-diagonal, -diagonal),
	]
	for offset in offsets:
		var sample: Vector2 = center + offset - _walkable_floor_origin
		var pixel_x := floori(sample.x)
		var pixel_y := floori(sample.y)
		if pixel_x < 0 or pixel_y < 0 or pixel_x >= _walkable_floor_mask.get_width() or pixel_y >= _walkable_floor_mask.get_height():
			return false
		if _walkable_floor_mask.get_pixel(pixel_x, pixel_y).a < 0.15:
			return false
	return true


func _configure_sprite_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation_name in ANIMATION_ROWS:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 8.0)
		frames.set_animation_loop(animation_name, true)
		var row: int = ANIMATION_ROWS[animation_name]
		for column in range(4):
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = THURA_ATLAS
			atlas_frame.region = Rect2(Vector2(column * CELL_SIZE.x, row * CELL_SIZE.y), CELL_SIZE)
			frames.add_frame(animation_name, atlas_frame)
	sprite.sprite_frames = frames
	sprite.animation = _facing_animation


func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		_facing_animation = &"walk_right" if direction.x > 0.0 else &"walk_left"
	else:
		_facing_animation = &"walk_down" if direction.y > 0.0 else &"walk_up"
	if sprite.animation != _facing_animation:
		sprite.play(_facing_animation)


func _update_camera_limits() -> void:
	if not is_instance_valid(camera):
		return
	var view_size := get_viewport_rect().size
	var half_view := view_size / camera.zoom * 0.5
	var minimum := _camera_bounds.position + half_view
	var maximum := _camera_bounds.end - half_view
	if minimum.x > maximum.x:
		minimum.x = _camera_bounds.get_center().x
		maximum.x = minimum.x
	if minimum.y > maximum.y:
		minimum.y = _camera_bounds.get_center().y
		maximum.y = minimum.y
	camera.limit_left = floori(minimum.x)
	camera.limit_top = floori(minimum.y)
	camera.limit_right = ceili(maximum.x)
	camera.limit_bottom = ceili(maximum.y)
