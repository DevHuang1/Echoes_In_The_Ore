class_name CrewMemberNPC
extends CharacterBody2D

var sprite: Sprite2D = null
var _base_scale: Vector2 = Vector2(0.11, 0.11)
var _idle_tween: Tween = null


func _ready() -> void:
	add_to_group(&"ship_crew")
	sprite = get_node_or_null("Sprite2D") as Sprite2D
	if is_instance_valid(sprite):
		_base_scale = sprite.scale
		_start_idle_breathe()


func face_toward(target_pos: Vector2) -> void:
	if is_instance_valid(sprite):
		sprite.flip_h = target_pos.x < global_position.x


func set_in_dialogue(in_dialogue: bool) -> void:
	if in_dialogue:
		if is_instance_valid(_idle_tween):
			_idle_tween.pause()
	else:
		if is_instance_valid(_idle_tween):
			_idle_tween.play()


func _start_idle_breathe() -> void:
	if not is_instance_valid(sprite):
		return
	if is_instance_valid(_idle_tween):
		_idle_tween.kill()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(sprite, "scale", _base_scale * Vector2(1.025, 0.975), 1.6).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(sprite, "scale", _base_scale, 1.6).set_trans(Tween.TRANS_SINE)
