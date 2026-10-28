class_name CrewMemberNPC
extends CharacterBody2D

const WALK_ATLAS := preload("res://art/characters/runtime/amara_walk_4dir.png")
const ANIMATION_ROWS := {
	&"walk_down": 0,
	&"walk_left": 1,
	&"walk_right": 2,
	&"walk_up": 3,
}

@export var move_speed: float = 42.0
@export var patrol_points: Array[Vector2] = []
@export var idle_duration_range: Vector2 = Vector2(2.2, 4.2)

var sprite: Node2D = null
var _anim_sprite: AnimatedSprite2D = null
var _base_scale: Vector2 = Vector2(0.11, 0.11)
var _in_dialogue: bool = false
var _patrol_index: int = 0
var _idle_timer: float = 1.2
var _facing_anim: StringName = &"walk_down"
var _rng := RandomNumberGenerator.new()
var _walk_bob_time: float = 0.0


func _ready() -> void:
	_rng.randomize()
	add_to_group(&"ship_crew")
	sprite = get_node_or_null("Sprite2D") as Node2D
	if is_instance_valid(sprite):
		_base_scale = sprite.scale
		if sprite is Sprite2D:
			var sp2d := sprite as Sprite2D
			sp2d.visible = false
			_setup_animated_sprite(sp2d.modulate, sp2d.position)
	_idle_timer = _rng.randf_range(0.6, 1.8)
	set_physics_process(true)


func _setup_animated_sprite(tint: Color, offset_pos: Vector2) -> void:
	_anim_sprite = AnimatedSprite2D.new()
	_anim_sprite.name = "AnimatedSprite2D"
	_anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_anim_sprite.scale = _base_scale
	_anim_sprite.modulate = tint
	_anim_sprite.position = offset_pos
	_anim_sprite.z_index = 3

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var cell_size := Vector2(float(WALK_ATLAS.get_width()) / 4.0, float(WALK_ATLAS.get_height()) / 4.0)
	for anim_name in ANIMATION_ROWS:
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, 5.5)
		frames.set_animation_loop(anim_name, true)
		var row: int = int(ANIMATION_ROWS[anim_name])
		for col in range(4):
			var atlas_frame := AtlasTexture.new()
			atlas_frame.atlas = WALK_ATLAS
			atlas_frame.region = Rect2(Vector2(float(col) * cell_size.x, float(row) * cell_size.y), cell_size)
			frames.add_frame(anim_name, atlas_frame)
	_anim_sprite.sprite_frames = frames
	_anim_sprite.animation = _facing_anim
	_anim_sprite.stop()
	add_child(_anim_sprite)


func setup_patrol(points: Array[Vector2], speed: float = 42.0) -> void:
	patrol_points = points.duplicate()
	move_speed = speed
	_patrol_index = 1 if patrol_points.size() > 1 else 0


func _physics_process(delta: float) -> void:
	if _in_dialogue:
		velocity = Vector2.ZERO
		_stop_walk_anim()
		return

	# Check if player is very close -> pause and face player naturally
	var players := get_tree().get_nodes_in_group(&"ship_player")
	if not players.is_empty():
		var player := players[0] as Node2D
		if is_instance_valid(player) and global_position.distance_to(player.global_position) <= 56.0:
			velocity = Vector2.ZERO
			_stop_walk_anim()
			face_toward(player.global_position)
			return

	if patrol_points.size() < 2:
		_walk_bob_time += delta * 2.2
		if is_instance_valid(_anim_sprite):
			var breathe := 1.0 + 0.02 * sin(_walk_bob_time)
			_anim_sprite.scale = _base_scale * Vector2(breathe, 2.0 - breathe)
		return

	if _idle_timer > 0.0:
		_idle_timer = maxf(_idle_timer - delta, 0.0)
		velocity = Vector2.ZERO
		_stop_walk_anim()
		_walk_bob_time += delta * 2.2
		if is_instance_valid(_anim_sprite):
			var breathe := 1.0 + 0.018 * sin(_walk_bob_time)
			_anim_sprite.scale = _base_scale * Vector2(breathe, 2.0 - breathe)
		return

	var target: Vector2 = patrol_points[_patrol_index]
	var to_target: Vector2 = target - global_position
	var dist: float = to_target.length()
	if dist <= 3.5:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		_idle_timer = _rng.randf_range(idle_duration_range.x, idle_duration_range.y)
		velocity = Vector2.ZERO
		_stop_walk_anim()
		return

	var dir: Vector2 = to_target / dist
	_update_facing(dir)
	var step := minf(move_speed * delta, dist)
	velocity = dir * move_speed
	var col := move_and_collide(dir * step)
	if col != null:
		# Advance to next patrol point if blocked by player or prop
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		_idle_timer = _rng.randf_range(1.2, 2.4)
		velocity = Vector2.ZERO
		_stop_walk_anim()
	else:
		if is_instance_valid(_anim_sprite):
			_anim_sprite.scale = _base_scale
			if not _anim_sprite.is_playing():
				_anim_sprite.play(_facing_anim)


func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		_facing_anim = &"walk_right" if dir.x > 0.0 else &"walk_left"
	else:
		_facing_anim = &"walk_down" if dir.y > 0.0 else &"walk_up"
	if is_instance_valid(_anim_sprite):
		if _anim_sprite.animation != _facing_anim:
			_anim_sprite.animation = _facing_anim
	if is_instance_valid(sprite) and sprite is Sprite2D:
		(sprite as Sprite2D).flip_h = dir.x < 0.0


func _stop_walk_anim() -> void:
	if is_instance_valid(_anim_sprite) and _anim_sprite.is_playing():
		_anim_sprite.stop()
		_anim_sprite.frame = 0


func face_toward(target_pos: Vector2) -> void:
	var dir := target_pos - global_position
	if not dir.is_zero_approx():
		_update_facing(dir)
		_stop_walk_anim()


func set_in_dialogue(in_dialogue: bool) -> void:
	_in_dialogue = in_dialogue
	if in_dialogue:
		velocity = Vector2.ZERO
		_stop_walk_anim()
