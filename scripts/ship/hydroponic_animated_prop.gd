extends AnimatedSprite2D

@export var animation_frames: Array[Texture2D] = []
@export_range(0.5, 12.0, 0.1) var frames_per_second: float = 3.5
@export var phase_offset: int = 0
@export var frame_offset_corrections: Array[Vector2] = []
@export var frame_scale_corrections: Array[Vector2] = []

var _base_offset: Vector2
var _base_scale: Vector2


func _ready() -> void:
	_base_offset = offset
	_base_scale = scale

	if animation_frames.is_empty():
		push_warning("Hydroponic prop has no animation frames: %s" % name)
		return

	var frame_set := SpriteFrames.new()
	frame_set.clear(&"default")
	frame_set.set_animation_loop(&"default", true)
	frame_set.set_animation_speed(&"default", frames_per_second)
	for texture in animation_frames:
		if texture != null:
			frame_set.add_frame(&"default", texture)

	if frame_set.get_frame_count(&"default") == 0:
		push_warning("Hydroponic prop has no valid animation textures: %s" % name)
		return

	sprite_frames = frame_set
	animation = &"default"
	set_frame_and_progress(posmod(phase_offset, frame_set.get_frame_count(&"default")), 0.0)
	# Keep the prop artwork on one pose so its footprint never shifts between frames.
	_apply_frame_correction()


func _apply_frame_correction() -> void:
	offset = _base_offset
	scale = _base_scale

	if frame < frame_offset_corrections.size():
		offset += frame_offset_corrections[frame]
	if frame < frame_scale_corrections.size():
		scale = _base_scale * frame_scale_corrections[frame]
