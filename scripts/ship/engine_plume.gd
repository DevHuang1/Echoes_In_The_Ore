@tool
extends AnimatedSprite2D

const PLUME_SHEET: Texture2D = preload("res://art/vfx/asteria_engine_plume_sheet.png")
const FRAME_SIZE := Vector2(434.0, 362.0)
const FRAME_COLUMNS := 5
const FRAME_COUNT := 10
const ANIMATION_NAME := &"plume"

@export_range(1.0, 30.0, 1.0) var frames_per_second := 12.0

var _time: float = 0.0


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
	set_process(true)


func _process(delta: float) -> void:
	_time = fposmod(_time + delta, 1000.0)
	queue_redraw()


func _draw() -> void:
	# 1. Radiant engine nozzle throat glow
	var throat_pulse: float = 0.82 + 0.18 * sin(_time * 28.0)
	draw_circle(Vector2(12.0, 0.0), 38.0 * throat_pulse, Color(0.25, 0.72, 1.0, 0.16 * throat_pulse))
	draw_circle(Vector2(12.0, 0.0), 18.0 * throat_pulse, Color(0.45, 0.92, 1.0, 0.35 * throat_pulse))
	draw_circle(Vector2(12.0, 0.0), 7.0, Color(1.0, 1.0, 1.0, 0.85))

	# 2. Supersonic Mach Diamond shockwave nodes along exhaust plume axis
	for diamond_i in range(5):
		var d_x: float = 35.0 + float(diamond_i) * 36.0
		var d_phase: float = sin(_time * 32.0 + float(diamond_i) * 1.5) * 2.2
		var d_w: float = 14.0 - float(diamond_i) * 2.0
		var d_h: float = 8.0 - float(diamond_i) * 1.0 + d_phase
		var d_col: Color = Color(0.48, 0.95, 1.0, 0.75 - float(diamond_i) * 0.11)
		var pts := PackedVector2Array([
			Vector2(d_x - d_w * 0.5, 0.0),
			Vector2(d_x, -d_h),
			Vector2(d_x + d_w * 0.5, 0.0),
			Vector2(d_x, d_h),
		])
		draw_colored_polygon(pts, Color(d_col.r, d_col.g, d_col.b, 0.35))
		draw_polyline(pts, d_col, 1.4, true)
		draw_circle(Vector2(d_x, 0.0), 2.2, Color(1.0, 1.0, 1.0, 0.95))

	# 3. High-velocity cosmic ion plasma spark streams rushing into deep space (+X)
	for s_i in range(24):
		var s_phase: float = fposmod(_time * 1.6 + float(s_i) * 0.042, 1.0)
		var sp_x: float = 20.0 + s_phase * 340.0
		var sp_y: float = sin(_time * 4.0 + float(s_i) * 2.1) * (6.0 + s_phase * 32.0)
		var s_fade: float = sin(s_phase * PI)
		var s_col: Color = (
			Color(0.35, 0.88, 1.0, 0.95 * s_fade)
			if s_i % 2 == 0
			else Color(1.0, 0.68, 0.28, 0.95 * s_fade)
		)
		var tail_len: float = 4.0 + s_phase * 16.0
		draw_line(Vector2(sp_x - tail_len, sp_y), Vector2(sp_x, sp_y), s_col, 1.5, false)
		draw_circle(Vector2(sp_x, sp_y), 1.2, Color(1.0, 1.0, 1.0, s_fade * 0.95))
