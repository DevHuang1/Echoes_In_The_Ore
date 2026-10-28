@tool
class_name SpaceBackdrop
extends AnimatedSprite2D

const FRAMES: Array[Texture2D] = [
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

const ANIMATION_NAME := &"drift"
const FRAMES_PER_SECOND := 10.0

const FIELD_SIZE := Vector2(3600.0, 2000.0)
const FAR_STAR_COUNT := 440
const MID_STAR_COUNT := 160
const BRIGHT_STAR_COUNT := 28
const DUST_BAND_COUNT := 20
const DEBRIS_MOTE_COUNT := 56

const SPECTRAL_PALETTE := [
	Color(0.72, 0.85, 1.0, 1.0),   # O/B blue-white
	Color(0.92, 0.96, 1.0, 1.0),   # A white-blue
	Color(1.0, 0.98, 0.94, 1.0),   # F pure stellar white
	Color(1.0, 0.91, 0.76, 1.0),   # G solar warm gold
	Color(1.0, 0.78, 0.56, 1.0),   # K orange-amber
	Color(0.98, 0.64, 0.48, 1.0),  # M muted red dwarf
]

const NEBULA_WISP_COLORS := [
	Color(0.05, 0.12, 0.22, 0.042),
	Color(0.07, 0.09, 0.20, 0.036),
	Color(0.13, 0.06, 0.15, 0.026),
	Color(0.04, 0.14, 0.18, 0.032),
]

var _elapsed := 0.0
var _cosmos_overlay: Node2D
var _far_stars: Array[Dictionary] = []
var _mid_stars: Array[Dictionary] = []
var _bright_stars: Array[Dictionary] = []
var _dust_bands: Array[Dictionary] = []
var _debris_motes: Array[Dictionary] = []


func _ready() -> void:
	var frame_set := SpriteFrames.new()
	frame_set.add_animation(ANIMATION_NAME)
	frame_set.set_animation_speed(ANIMATION_NAME, FRAMES_PER_SECOND)
	frame_set.set_animation_loop(ANIMATION_NAME, true)
	for frame_texture in FRAMES:
		frame_set.add_frame(ANIMATION_NAME, frame_texture)
	sprite_frames = frame_set
	play(ANIMATION_NAME)

	# Attenuate the bright blue painted nebula frames into a deep vacuum backdrop
	# so the crisp multi-layer parallax stars and dark molecular dust lanes stand out.
	self_modulate = Color(0.18, 0.21, 0.28, 1.0)
	_generate_cosmos()

	_cosmos_overlay = get_node_or_null("CosmosOverlay") as Node2D
	if _cosmos_overlay == null:
		_cosmos_overlay = Node2D.new()
		_cosmos_overlay.name = "CosmosOverlay"
		add_child(_cosmos_overlay)
	if not _cosmos_overlay.draw.is_connected(_draw_cosmos_overlay):
		_cosmos_overlay.draw.connect(_draw_cosmos_overlay)
	_cosmos_overlay.queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	if is_instance_valid(_cosmos_overlay):
		_cosmos_overlay.queue_redraw()


func _generate_cosmos() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xA57E81A1

	_far_stars.clear()
	for i in range(FAR_STAR_COUNT):
		var spectral: Color = SPECTRAL_PALETTE[rng.randi_range(0, SPECTRAL_PALETTE.size() - 1)]
		_far_stars.append({
			"pos": Vector2(
				rng.randf_range(-FIELD_SIZE.x * 0.5, FIELD_SIZE.x * 0.5),
				rng.randf_range(-FIELD_SIZE.y * 0.5, FIELD_SIZE.y * 0.5)
			),
			"radius": rng.randf_range(0.45, 0.92),
			"alpha": rng.randf_range(0.24, 0.76),
			"color": spectral,
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.4, 1.3),
		})

	_mid_stars.clear()
	for i in range(MID_STAR_COUNT):
		var spectral: Color = SPECTRAL_PALETTE[rng.randi_range(0, SPECTRAL_PALETTE.size() - 1)]
		_mid_stars.append({
			"pos": Vector2(
				rng.randf_range(-FIELD_SIZE.x * 0.5, FIELD_SIZE.x * 0.5),
				rng.randf_range(-FIELD_SIZE.y * 0.5, FIELD_SIZE.y * 0.5)
			),
			"radius": rng.randf_range(0.82, 1.48),
			"alpha": rng.randf_range(0.50, 0.94),
			"color": spectral,
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(0.8, 2.2),
		})

	_bright_stars.clear()
	for i in range(BRIGHT_STAR_COUNT):
		var spectral: Color = SPECTRAL_PALETTE[rng.randi_range(0, 4)]
		_bright_stars.append({
			"pos": Vector2(
				rng.randf_range(-FIELD_SIZE.x * 0.46, FIELD_SIZE.x * 0.46),
				rng.randf_range(-FIELD_SIZE.y * 0.46, FIELD_SIZE.y * 0.46)
			),
			"radius": rng.randf_range(1.25, 2.10),
			"spike": rng.randf_range(5.0, 10.5),
			"alpha": rng.randf_range(0.76, 1.0),
			"color": spectral,
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(1.1, 2.5),
		})

	_dust_bands.clear()
	for i in range(DUST_BAND_COUNT):
		var is_dark_lane := (i % 3 != 0)
		var col: Color = Color(0.004, 0.007, 0.013, rng.randf_range(0.35, 0.58)) if is_dark_lane else NEBULA_WISP_COLORS[i % NEBULA_WISP_COLORS.size()]
		_dust_bands.append({
			"pos": Vector2(
				rng.randf_range(-FIELD_SIZE.x * 0.42, FIELD_SIZE.x * 0.42),
				rng.randf_range(-FIELD_SIZE.y * 0.42, FIELD_SIZE.y * 0.42)
			),
			"radius": rng.randf_range(160.0, 360.0),
			"color": col,
		})

	_debris_motes.clear()
	for i in range(DEBRIS_MOTE_COUNT):
		_debris_motes.append({
			"pos": Vector2(
				rng.randf_range(-FIELD_SIZE.x * 0.5, FIELD_SIZE.x * 0.5),
				rng.randf_range(-FIELD_SIZE.y * 0.5, FIELD_SIZE.y * 0.5)
			),
			"vel": Vector2(rng.randf_range(-6.0, -2.0), rng.randf_range(-1.0, 1.0)),
			"alpha": rng.randf_range(0.14, 0.34),
			"size": rng.randf_range(0.55, 1.15),
		})


func _wrap_offset(pos: Vector2, shift: Vector2) -> Vector2:
	var half := FIELD_SIZE * 0.5
	var p := pos + shift
	p.x = fposmod(p.x + half.x, FIELD_SIZE.x) - half.x
	p.y = fposmod(p.y + half.y, FIELD_SIZE.y) - half.y
	return p


func _camera_delta() -> Vector2:
	if Engine.is_editor_hint():
		return Vector2.ZERO
	var vp := get_viewport()
	if vp == null:
		return Vector2.ZERO
	var cam := vp.get_camera_2d()
	if cam == null:
		return Vector2.ZERO
	return cam.get_screen_center_position() - global_position


func _draw_cosmos_overlay() -> void:
	if not is_instance_valid(_cosmos_overlay):
		return
	var cam_offset := _camera_delta()

	# 1. Deep cosmic vacuum veil so outer space reads as true abyssal darkness.
	_cosmos_overlay.draw_rect(
		Rect2(-FIELD_SIZE * 0.5, FIELD_SIZE),
		Color(0.003, 0.006, 0.012, 0.64),
		true
	)

	# 2. Interstellar dark molecular clouds and subtle ionized gas wisps.
	var dust_shift := -cam_offset * 0.04 + Vector2(-_elapsed * 0.32, 0.0)
	for band in _dust_bands:
		var center := _wrap_offset(band["pos"], dust_shift)
		var rad: float = band["radius"]
		var col: Color = band["color"]
		_cosmos_overlay.draw_circle(center, rad, col)
		_cosmos_overlay.draw_circle(center + Vector2(rad * 0.28, -rad * 0.12), rad * 0.68, Color(col.r, col.g, col.b, col.a * 0.7))

	# 3. Distant shadowed planetary body (Erebos orbital horizon) with thin atmospheric rim light.
	var planet_pos := Vector2(-640.0, 295.0) - cam_offset * 0.05
	var planet_radius := 142.0
	_cosmos_overlay.draw_circle(planet_pos, planet_radius + 10.0, Color(0.12, 0.26, 0.42, 0.045))
	_cosmos_overlay.draw_circle(planet_pos, planet_radius + 4.0, Color(0.20, 0.42, 0.62, 0.08))
	_cosmos_overlay.draw_circle(planet_pos, planet_radius, Color(0.010, 0.015, 0.024, 0.97))
	_cosmos_overlay.draw_arc(planet_pos, planet_radius - 0.5, PI * 0.72, PI * 1.48, 48, Color(0.44, 0.70, 0.90, 0.42), 2.0, true)
	_cosmos_overlay.draw_arc(planet_pos, planet_radius - 2.0, PI * 0.78, PI * 1.42, 48, Color(0.24, 0.44, 0.62, 0.22), 3.2, true)

	# 4. Far-field background stars (slowest parallax, pinpoint sub-pixel/1px stars).
	var far_shift := -cam_offset * 0.06 + Vector2(-_elapsed * 0.42, 0.0)
	for star in _far_stars:
		var p := _wrap_offset(star["pos"], far_shift)
		var twinkle := 0.84 + 0.16 * sin(_elapsed * float(star["speed"]) + float(star["phase"]))
		var c: Color = star["color"]
		var a := float(star["alpha"]) * twinkle
		_cosmos_overlay.draw_circle(p, float(star["radius"]), Color(c.r, c.g, c.b, a))

	# 5. Mid-field spectral stars with soft optical Airy corona.
	var mid_shift := -cam_offset * 0.13 + Vector2(-_elapsed * 0.90, 0.0)
	for star in _mid_stars:
		var p := _wrap_offset(star["pos"], mid_shift)
		var twinkle := 0.78 + 0.22 * sin(_elapsed * float(star["speed"]) + float(star["phase"]))
		var c: Color = star["color"]
		var a := float(star["alpha"]) * twinkle
		var r := float(star["radius"])
		_cosmos_overlay.draw_circle(p, r * 2.4, Color(c.r, c.g, c.b, a * 0.14))
		_cosmos_overlay.draw_circle(p, r, Color(c.r, c.g, c.b, a))

	# 6. Bright navigational reference stars with delicate 4-point diffraction spikes.
	var bright_shift := -cam_offset * 0.20 + Vector2(-_elapsed * 1.38, 0.0)
	for star in _bright_stars:
		var p := _wrap_offset(star["pos"], bright_shift)
		var twinkle := 0.82 + 0.18 * sin(_elapsed * float(star["speed"]) + float(star["phase"]))
		var c: Color = star["color"]
		var a := float(star["alpha"]) * twinkle
		var r := float(star["radius"])
		var spike := float(star["spike"]) * (0.92 + 0.08 * twinkle)
		_cosmos_overlay.draw_circle(p, r * 3.2, Color(c.r, c.g, c.b, a * 0.16))
		_cosmos_overlay.draw_line(p - Vector2(spike, 0.0), p + Vector2(spike, 0.0), Color(c.r, c.g, c.b, a * 0.36), 1.0, true)
		_cosmos_overlay.draw_line(p - Vector2(0.0, spike), p + Vector2(0.0, spike), Color(c.r, c.g, c.b, a * 0.36), 1.0, true)
		_cosmos_overlay.draw_circle(p, r, Color(1.0, 0.99, 0.97, a))

	# 7. Subtle cryogenic ice / orbital dust motes drifting across the exterior vacuum.
	var mote_cam_shift := -cam_offset * 0.28
	for mote in _debris_motes:
		var drift: Vector2 = mote["vel"] * _elapsed
		var p := _wrap_offset(mote["pos"], mote_cam_shift + drift)
		var a := float(mote["alpha"]) * (0.75 + 0.25 * sin(_elapsed * 1.7 + p.x * 0.02))
		_cosmos_overlay.draw_circle(p, float(mote["size"]), Color(0.76, 0.86, 0.94, a))
