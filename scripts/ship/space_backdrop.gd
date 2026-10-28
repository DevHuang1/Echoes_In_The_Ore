@tool
extends AnimatedSprite2D

const FRAMES: Array = [
	preload("res://art/overview/space_frames/asteria_space_backdrop_00.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_01.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_02.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_03.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_04.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_05.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_06.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_07.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_08.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_09.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_10.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_11.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_12.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_13.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_14.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_15.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_16.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_17.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_18.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_19.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_20.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_21.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_22.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_23.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_24.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_25.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_26.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_27.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_28.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_29.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_30.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_31.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_32.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_33.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_34.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_35.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_36.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_37.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_38.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_39.jpg"),
]

const ANIMATION_NAME: StringName = &"drift"
const FRAMES_PER_SECOND: float = 10.0
const FIELD_EXTENTS: Vector2 = Vector2(2800.0, 1600.0)

var _overlay_canvas: Node2D = null
var _time: float = 0.0
var _base_origin: Vector2 = Vector2(887.0, 443.5)
var _far_stars: Array = []
var _mid_stars: Array = []
var _near_stars: Array = []
var _nebula_clouds: Array = []
var _shooting_stars: Array = []


func _ready() -> void:
	_base_origin = position
	var frame_set: SpriteFrames = SpriteFrames.new()
	frame_set.add_animation(ANIMATION_NAME)
	frame_set.set_animation_speed(ANIMATION_NAME, FRAMES_PER_SECOND)
	frame_set.set_animation_loop(ANIMATION_NAME, true)
	for frame_texture in FRAMES:
		frame_set.add_frame(ANIMATION_NAME, frame_texture)
	sprite_frames = frame_set
	play(ANIMATION_NAME)
	modulate = Color(0.84, 0.90, 1.0, 1.0)

	_init_parallax_space_layers()

	for child in get_children():
		child.queue_free()
	_overlay_canvas = Node2D.new()
	_overlay_canvas.name = "DeepSpaceParallaxCanvas"
	_overlay_canvas.draw.connect(_on_overlay_canvas_draw)
	add_child(_overlay_canvas)
	set_process(true)


func _hash_unit(index: int, salt: float) -> float:
	var v: float = sin(float(index) * 12.9898 + salt * 78.233) * 43758.5453
	return v - floorf(v)


func _init_parallax_space_layers() -> void:
	_far_stars.clear()
	_mid_stars.clear()
	_near_stars.clear()
	_nebula_clouds.clear()
	_shooting_stars.clear()

	var star_palette: Array = [
		Color(0.76, 0.88, 1.0, 1.0),
		Color(0.95, 0.97, 1.0, 1.0),
		Color(0.60, 0.82, 1.0, 1.0),
		Color(1.0, 0.88, 0.72, 1.0),
		Color(0.78, 0.70, 1.0, 1.0),
	]

	# 110 Far deep-space dust stars (slow drift)
	for i in range(110):
		var col: Color = star_palette[i % star_palette.size()]
		_far_stars.append({
			"pos": Vector2((_hash_unit(i, 1.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 2.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 4.5 + _hash_unit(i, 3.3) * 3.5,
			"size": 0.75 + _hash_unit(i, 4.4) * 0.75,
			"phase": _hash_unit(i, 5.5) * TAU,
			"color": col,
		})

	# 70 Mid-plane twinkling stars (medium drift)
	for i in range(70):
		var col: Color = star_palette[(i + 2) % star_palette.size()]
		_mid_stars.append({
			"pos": Vector2((_hash_unit(i, 6.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 7.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 11.5 + _hash_unit(i, 8.3) * 6.5,
			"size": 1.15 + _hash_unit(i, 9.4) * 1.15,
			"phase": _hash_unit(i, 10.5) * TAU,
			"color": col,
		})

	# 34 Near bright stars with diffraction cross-spikes & motion trails (fast parallax drift)
	for i in range(34):
		var col: Color = star_palette[(i + 1) % star_palette.size()]
		_near_stars.append({
			"pos": Vector2((_hash_unit(i, 11.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 12.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 24.0 + _hash_unit(i, 13.3) * 14.0,
			"size": 1.65 + _hash_unit(i, 14.4) * 1.35,
			"phase": _hash_unit(i, 15.5) * TAU,
			"color": col,
		})

	# 16 Volumetric drifting nebula bands
	var nebula_palette: Array = [
		Color(0.10, 0.42, 0.78, 0.055),
		Color(0.28, 0.20, 0.68, 0.050),
		Color(0.08, 0.58, 0.76, 0.045),
		Color(0.42, 0.18, 0.58, 0.042),
	]
	for i in range(16):
		_nebula_clouds.append({
			"pos": Vector2((_hash_unit(i, 21.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 22.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 6.5 + _hash_unit(i, 23.3) * 5.0,
			"radius": 150.0 + _hash_unit(i, 24.4) * 180.0,
			"phase": _hash_unit(i, 25.5) * TAU,
			"color": nebula_palette[i % nebula_palette.size()],
		})

	# 3 Periodic shooting stars / micro-meteorites streaking across deep space
	for i in range(3):
		_shooting_stars.append({
			"start": Vector2((_hash_unit(i, 31.1) - 0.3) * FIELD_EXTENTS.x * 0.7, (_hash_unit(i, 32.2) - 0.5) * FIELD_EXTENTS.y * 0.7),
			"dir": Vector2(-0.92, 0.24 + (_hash_unit(i, 33.3) - 0.5) * 0.35).normalized(),
			"period": 6.5 + float(i) * 3.8,
			"offset": float(i) * 2.7,
			"speed": 580.0 + float(i) * 110.0,
		})


func _process(delta: float) -> void:
	_time = fposmod(_time + delta, 10000.0)
	position = _base_origin
	scale = Vector2.ONE

	if is_instance_valid(_overlay_canvas):
		_overlay_canvas.queue_redraw()


func _wrap_coord(val: float, half_span: float) -> float:
	var span: float = half_span * 2.0
	return fposmod(val + half_span, span) - half_span


func _get_camera_parallax_offset() -> Vector2:
	return Vector2.ZERO


func _on_overlay_canvas_draw() -> void:
	if not is_instance_valid(_overlay_canvas):
		return

	var half_w: float = FIELD_EXTENTS.x * 0.5
	var half_h: float = FIELD_EXTENTS.y * 0.5
	var cam_off: Vector2 = _get_camera_parallax_offset()

	# 1. Soft drifting volumetric nebula clouds
	for i in range(_nebula_clouds.size()):
		var neb: Dictionary = _nebula_clouds[i]
		var bpos: Vector2 = neb["pos"]
		var spd: float = float(neb["speed"])
		var rad: float = float(neb["radius"])
		var phase: float = float(neb["phase"])
		var col: Color = neb["color"]

		var nx: float = _wrap_coord(bpos.x - _time * spd - cam_off.x * 0.05, half_w)
		var ny: float = _wrap_coord(bpos.y + sin(_time * 0.25 + phase) * 16.0 - cam_off.y * 0.05, half_h)
		var npos: Vector2 = Vector2(nx, ny)
		var breathe: float = 0.85 + 0.25 * sin(_time * 0.6 + phase)
		_overlay_canvas.draw_circle(npos, rad * breathe, col)
		_overlay_canvas.draw_circle(npos + Vector2(rad * 0.28, -rad * 0.12), rad * 0.68 * breathe, Color(col.r * 1.15, col.g * 1.15, col.b * 1.15, col.a * 1.25))

	# 2. Far deep-space starfield layer (slow leftward stellar drift as ship cruises forward)
	for i in range(_far_stars.size()):
		var st: Dictionary = _far_stars[i]
		var bpos: Vector2 = st["pos"]
		var spd: float = float(st["speed"])
		var sz: float = float(st["size"])
		var phase: float = float(st["phase"])
		var col: Color = st["color"]

		var sx: float = _wrap_coord(bpos.x - _time * spd - cam_off.x * 0.04, half_w)
		var sy: float = _wrap_coord(bpos.y - _time * (spd * 0.08) - cam_off.y * 0.04, half_h)
		var twinkle: float = 0.45 + 0.55 * (0.5 + 0.5 * sin(_time * 1.8 + phase))
		_overlay_canvas.draw_circle(Vector2(sx, sy), sz, Color(col.r, col.g, col.b, 0.58 * twinkle))

	# 3. Mid-plane twinkling stars
	for i in range(_mid_stars.size()):
		var st: Dictionary = _mid_stars[i]
		var bpos: Vector2 = st["pos"]
		var spd: float = float(st["speed"])
		var sz: float = float(st["size"])
		var phase: float = float(st["phase"])
		var col: Color = st["color"]

		var sx: float = _wrap_coord(bpos.x - _time * spd - cam_off.x * 0.10, half_w)
		var sy: float = _wrap_coord(bpos.y - _time * (spd * 0.08) - cam_off.y * 0.10, half_h)
		var spos: Vector2 = Vector2(sx, sy)
		var twinkle: float = 0.55 + 0.45 * (0.5 + 0.5 * sin(_time * 3.1 + phase))
		_overlay_canvas.draw_circle(spos, sz * 1.8, Color(col.r, col.g, col.b, 0.18 * twinkle))
		_overlay_canvas.draw_circle(spos, sz, Color(col.r, col.g, col.b, 0.85 * twinkle))

	# 4. Near bright parallax stars with subtle motion streaks & diffraction spikes
	for i in range(_near_stars.size()):
		var st: Dictionary = _near_stars[i]
		var bpos: Vector2 = st["pos"]
		var spd: float = float(st["speed"])
		var sz: float = float(st["size"])
		var phase: float = float(st["phase"])
		var col: Color = st["color"]

		var sx: float = _wrap_coord(bpos.x - _time * spd - cam_off.x * 0.20, half_w)
		var sy: float = _wrap_coord(bpos.y - _time * (spd * 0.08) - cam_off.y * 0.20, half_h)
		var spos: Vector2 = Vector2(sx, sy)
		var twinkle: float = 0.65 + 0.35 * (0.5 + 0.5 * sin(_time * 4.2 + phase))

		# Motion trail behind fast-moving foreground stars
		var trail_len: float = spd * 0.26
		_overlay_canvas.draw_line(spos, spos + Vector2(trail_len, trail_len * 0.08), Color(col.r, col.g, col.b, 0.28 * twinkle), 1.2, true)
		# Soft halo + bright core
		_overlay_canvas.draw_circle(spos, sz * 2.4, Color(col.r, col.g, col.b, 0.22 * twinkle))
		_overlay_canvas.draw_circle(spos, sz, Color(1.0, 0.98, 0.95, 0.95 * twinkle))
		# 4-point stellar diffraction cross-spikes
		var spike: float = sz * (2.6 + 0.8 * twinkle)
		var spike_col: Color = Color(col.r, col.g, col.b, 0.52 * twinkle)
		_overlay_canvas.draw_line(spos - Vector2(spike, 0.0), spos + Vector2(spike, 0.0), spike_col, 1.0, true)
		_overlay_canvas.draw_line(spos - Vector2(0.0, spike), spos + Vector2(0.0, spike), spike_col, 1.0, true)

	# 5. Shooting stars / micro-meteorites streaking across deep space
	for i in range(_shooting_stars.size()):
		var m: Dictionary = _shooting_stars[i]
		var period: float = float(m["period"])
		var offset: float = float(m["offset"])
		var local_t: float = fposmod(_time + offset, period)
		if local_t <= 0.85:
			var prog: float = local_t / 0.85
			var fade: float = sin(prog * PI)
			var start_p: Vector2 = m["start"]
			var dir: Vector2 = m["dir"]
			var spd: float = float(m["speed"])
			var head: Vector2 = start_p + dir * (local_t * spd)
			var tail: Vector2 = head - dir * (68.0 * fade)
			_overlay_canvas.draw_line(tail, head, Color(0.55, 0.88, 1.0, 0.55 * fade), 2.0, true)
			_overlay_canvas.draw_line(head - dir * 18.0, head, Color(0.95, 0.99, 1.0, 0.92 * fade), 2.4, true)
			_overlay_canvas.draw_circle(head, 2.2, Color(1.0, 1.0, 1.0, 0.95 * fade))
