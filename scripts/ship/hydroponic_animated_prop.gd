extends AnimatedSprite2D

const INDICATOR_LIGHT_SCENE: PackedScene = preload("res://scenes/ship/props/warm_ship_light.tscn")

@export var animation_frames: Array[Texture2D] = []
# Use pre-aligned frame textures when enabled; frame changes never alter this node's transform.
@export var lock_transform_during_animation: bool = false
@export var animate_frames: bool = true
@export_range(0.5, 12.0, 0.1) var frames_per_second: float = 3.5
@export var phase_offset: int = 0
@export var frame_offset_corrections: Array[Vector2] = []
@export var frame_scale_corrections: Array[Vector2] = []
@export var indicator_color: Color = Color(0.36, 0.86, 1.0, 1.0)
@export var indicator_offset: Vector2 = Vector2.ZERO
@export_range(0.0, 1.0, 0.01) var indicator_base_energy: float = 0.0
@export_range(0.0, 0.5, 0.01) var indicator_pulse_amount: float = 0.12
@export_range(0.1, 8.0, 0.1) var indicator_pulse_speed: float = 1.6
@export_range(0.01, 0.5, 0.01) var indicator_texture_scale: float = 0.1

var _base_offset: Vector2
var _base_scale: Vector2
var _indicator_light: PointLight2D
var _indicator_phase: float = 0.0


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

	_create_prop_collision(animation_frames[0])
	_create_indicator_light()
	sprite_frames = frame_set
	animation = &"default"
	var first_frame := posmod(phase_offset, frame_set.get_frame_count(&"default")) if animate_frames else 0
	set_frame_and_progress(first_frame, 0.0)
	if animate_frames:
		if not lock_transform_during_animation:
			frame_changed.connect(_apply_frame_correction)
			_apply_frame_correction()
		play(&"default")
	else:
		stop()


func _create_prop_collision(texture: Texture2D) -> void:
	var image := texture.get_image()
	if image == null or image.is_empty():
		push_warning("Could not read hydroponic prop texture for collision: %s" % name)
		return
	if image.is_compressed():
		image.decompress()

	var visible_bounds := _get_visible_alpha_bounds(image)
	if visible_bounds.size.x <= 0 or visible_bounds.size.y <= 0:
		return

	var body := StaticBody2D.new()
	body.name = "PropCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	collision.name = "VisibleFootprint"
	var footprint := RectangleShape2D.new()
	footprint.size = Vector2(
		float(visible_bounds.size.x) * 0.65,
		float(visible_bounds.size.y) * 0.45
	)
	collision.shape = footprint
	collision.position = (
		Vector2(
			float(visible_bounds.position.x) + float(visible_bounds.size.x) * 0.5,
			float(visible_bounds.position.y) + float(visible_bounds.size.y) * 0.72
		)
		- Vector2(texture.get_size()) * 0.5
	)
	body.add_child(collision)
	add_child(body)


func _get_visible_alpha_bounds(image: Image) -> Rect2i:
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return used
	const ALPHA_THRESHOLD := 0.05
	var x0 := used.position.x
	var y0 := used.position.y
	var x1 := used.end.x - 1
	var y1 := used.end.y - 1

	var top := y0
	var found_top := false
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1, 2):
			if image.get_pixel(x, y).a >= ALPHA_THRESHOLD:
				top = y
				found_top = true
				break
		if found_top:
			break
	if not found_top:
		return used

	var bottom := y1
	for y in range(y1, top - 1, -1):
		var row_hit := false
		for x in range(x0, x1 + 1, 2):
			if image.get_pixel(x, y).a >= ALPHA_THRESHOLD:
				bottom = y
				row_hit = true
				break
		if row_hit:
			break

	var left := x0
	for x in range(x0, x1 + 1):
		var col_hit := false
		for y in range(top, bottom + 1, 2):
			if image.get_pixel(x, y).a >= ALPHA_THRESHOLD:
				left = x
				col_hit = true
				break
		if col_hit:
			break

	var right := x1
	for x in range(x1, left - 1, -1):
		var col_hit := false
		for y in range(top, bottom + 1, 2):
			if image.get_pixel(x, y).a >= ALPHA_THRESHOLD:
				right = x
				col_hit = true
				break
		if col_hit:
			break

	return Rect2i(left, top, right - left + 1, bottom - top + 1)


func _process(delta: float) -> void:
	if _indicator_light == null:
		return

	_indicator_phase += delta * indicator_pulse_speed
	var pulse := 1.0 + indicator_pulse_amount * sin(_indicator_phase + float(phase_offset))
	_indicator_light.energy = indicator_base_energy * pulse


func _create_indicator_light() -> void:
	if indicator_base_energy <= 0.0:
		return

	_indicator_light = INDICATOR_LIGHT_SCENE.instantiate() as PointLight2D
	if _indicator_light == null:
		return

	_indicator_light.name = "AnimatedIndicatorGlow"
	_indicator_light.position = indicator_offset
	_indicator_light.color = indicator_color
	_indicator_light.energy = indicator_base_energy
	_indicator_light.texture_scale = indicator_texture_scale
	_indicator_light.shadow_enabled = false
	add_child(_indicator_light)


func _apply_frame_correction() -> void:
	offset = _base_offset
	scale = _base_scale

	if frame < frame_offset_corrections.size():
		offset += frame_offset_corrections[frame]
	if frame < frame_scale_corrections.size():
		scale = _base_scale * frame_scale_corrections[frame]
