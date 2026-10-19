@tool
extends AnimatedSprite2D

const PLUME_SHEET: Texture2D = preload("res://art/vfx/asteria_engine_plume_sheet.png")
const FRAME_SIZE := Vector2(434.0, 362.0)
const FRAME_COLUMNS := 5
const FRAME_COUNT := 10
const ANIMATION_NAME := &"plume"

@export_range(1.0, 30.0, 1.0) var frames_per_second := 12.0


func _ready() -> void:
	centered = false
	offset = Vector2(0.0, -FRAME_SIZE.y * 0.5)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(ANIMATION_NAME)
	frames.set_animation_speed(ANIMATION_NAME, frames_per_second)
	frames.set_animation_loop(ANIMATION_NAME, true)
	for frame_index in FRAME_COUNT:
		var column := frame_index % FRAME_COLUMNS
		var row := floori(float(frame_index) / float(FRAME_COLUMNS))
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = PLUME_SHEET
		atlas_frame.region = Rect2(Vector2(column, row) * FRAME_SIZE, FRAME_SIZE)
		atlas_frame.filter_clip = true
		frames.add_frame(ANIMATION_NAME, atlas_frame)
	sprite_frames = frames
	play(ANIMATION_NAME)
