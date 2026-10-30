class_name PlayerFootstepFX
extends Node2D

const HYDROPONICS_BOUNDS := Rect2(Vector2(60.0, 640.0), Vector2(440.0, 195.0))
const SHADOW_OFFSET := Vector2(0.0, 11.5)
const STEP_INTERVAL := 0.16
const MAX_PARTICLES := 120

var _player: CharacterBody2D
var _sprite: AnimatedSprite2D
var _particles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _step_timer := 0.0
var _step_side := 1.0
var _last_player_pos := Vector2.ZERO
var _has_last_pos := false
var _walk_blend := 0.0
var _stride_phase := 0.0
var _move_dir := Vector2.DOWN


func _ready() -> void:
	_rng.randomize()
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_player = get_parent() as CharacterBody2D
	if _player != null:
		_sprite = _player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		_last_player_pos = _player.global_position
		_has_last_pos = true


func _process(delta: float) -> void:
	if _player == null:
		return
	if _sprite != null and not _sprite.visible:
		visible = false
		return
	visible = true

	var current_pos := _player.global_position
	var frame_delta := current_pos - _last_player_pos if _has_last_pos else Vector2.ZERO
	_last_player_pos = current_pos
	_has_last_pos = true

	var speed := frame_delta.length() / maxf(delta, 0.0001)
	var is_moving := speed > 8.0 and (_sprite == null or _sprite.is_playing())
	_walk_blend = move_toward(_walk_blend, 1.0 if is_moving else 0.0, delta * 9.0)

	if is_moving:
		var new_dir := frame_delta.normalized()
		if _walk_blend > 0.4 and _move_dir.dot(new_dir) < 0.35:
			_step_side = -_step_side
			_spawn_footstep_burst(current_pos, new_dir, _step_side)
			_step_timer = STEP_INTERVAL * 0.75
		_move_dir = new_dir
		_stride_phase += delta * 11.5
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = STEP_INTERVAL
			_step_side = -_step_side
			_spawn_footstep_burst(current_pos, _move_dir, _step_side)
	else:
		_step_timer = minf(_step_timer, 0.04)

	_update_particles(delta)
	queue_redraw()


func _spawn_footstep_burst(player_pos: Vector2, move_dir: Vector2, side: float) -> void:
	var perp := Vector2(-move_dir.y, move_dir.x)
	var foot_world := player_pos + SHADOW_OFFSET + perp * (3.2 * side) - move_dir * 2.0
	var in_hydro := HYDROPONICS_BOUNDS.has_point(player_pos)
	var is_sprint := _player.has_method(&"is_sprinting") and bool(_player.call(&"is_sprinting"))

	# 1. Expanding floor contact shockwave ring at boot strike point
	var ring_color := (
		Color(0.42, 0.96, 0.72, 0.65)
		if in_hydro
		else (Color(0.45, 0.88, 1.0, 0.60) if is_sprint else Color(0.58, 0.72, 0.84, 0.38))
	)
	_push_particle({
		"kind": 0,
		"world_pos": foot_world,
		"vel": -move_dir * (8.0 if is_sprint else 4.0),
		"age": 0.0,
		"lifetime": 0.38 if is_sprint else 0.34,
		"size": 4.5 if is_sprint else 3.5,
		"color": ring_color,
	})

	# 2. Layered pixel-art dust puffs trailing behind the boot
	var dust_count := 6 if is_sprint else 4
	for i in range(dust_count):
		var spread_angle := _rng.randf_range(-0.75, 0.75)
		var backward := (-move_dir).rotated(spread_angle)
		var speed := _rng.randf_range(14.0, 36.0) if is_sprint else _rng.randf_range(9.0, 22.0)
		var lift := Vector2(0.0, _rng.randf_range(-12.0, -4.0))
		var base_color := (
			Color(0.62, 0.74, 0.60, 0.56)
			if in_hydro
			else Color(0.66, 0.73, 0.82, 0.54)
		)
		if i == 0:
			base_color = base_color.lightened(0.24)
		_push_particle({
			"kind": 1,
			"world_pos": foot_world + Vector2(_rng.randf_range(-2.0, 2.0), _rng.randf_range(-1.2, 1.2)),
			"vel": backward * speed + lift,
			"swirl": side * _rng.randf_range(2.0, 4.5),
			"age": 0.0,
			"lifetime": _rng.randf_range(0.35, 0.60),
			"size": _rng.randf_range(1.8, 3.4) if is_sprint else _rng.randf_range(1.6, 2.8),
			"color": base_color,
		})

	# 3. Micro-motes & static glints
	var glint_color := (
		Color(0.48, 0.98, 0.54, 0.78)
		if in_hydro
		else Color(0.36, 0.88, 0.98, 0.72)
	)
	_push_particle({
		"kind": 2,
		"world_pos": foot_world + perp * (_rng.randf_range(-2.5, 2.5)),
		"vel": -move_dir * _rng.randf_range(6.0, 18.0) + Vector2(0.0, _rng.randf_range(-16.0, -7.0)),
		"age": 0.0,
		"lifetime": _rng.randf_range(0.38, 0.58),
		"size": 1.5,
		"color": glint_color,
	})

	# 4. CRAZY magnetic boot contact sparks (on metal deck) or bio-fluid droplets (in Hydroponics)
	if in_hydro:
		# Hydroponic bio-splash droplets
		var splash_count := 4 if is_sprint else 2
		for s in range(splash_count):
			var s_angle := _rng.randf_range(-PI * 0.8, -PI * 0.2)
			var s_spd := _rng.randf_range(20.0, 45.0)
			_push_particle({
				"kind": 4,
				"world_pos": foot_world,
				"vel": Vector2(cos(s_angle), sin(s_angle)) * s_spd - move_dir * 8.0,
				"gravity": 70.0,
				"age": 0.0,
				"lifetime": _rng.randf_range(0.25, 0.42),
				"size": 1.8,
				"color": Color(0.35, 0.98, 0.75, 0.90),
			})
	else:
		# Metallic magnetic boot sparks arc out when walking on ship floor plating
		var spark_count := 5 if is_sprint else 2
		for s in range(spark_count):
			var sp_dir := (-move_dir).rotated(_rng.randf_range(-1.2, 1.2))
			var sp_speed := _rng.randf_range(30.0, 68.0) if is_sprint else _rng.randf_range(18.0, 42.0)
			var sp_col := Color(1.0, 0.84, 0.38, 0.95) if s % 2 == 0 else Color(0.42, 0.92, 1.0, 0.95)
			_push_particle({
				"kind": 3,
				"world_pos": foot_world,
				"vel": sp_dir * sp_speed + Vector2(0.0, _rng.randf_range(-22.0, -8.0)),
				"gravity": 60.0,
				"age": 0.0,
				"lifetime": _rng.randf_range(0.18, 0.35),
				"size": 1.4,
				"color": sp_col,
			})


func _push_particle(p: Dictionary) -> void:
	if _particles.size() >= MAX_PARTICLES:
		_particles.pop_front()
	_particles.append(p)


func _update_particles(delta: float) -> void:
	var idx := _particles.size() - 1
	while idx >= 0:
		var p: Dictionary = _particles[idx]
		var age: float = float(p["age"]) + delta
		var life: float = float(p["lifetime"])
		if age >= life:
			_particles.remove_at(idx)
		else:
			p["age"] = age
			var vel: Vector2 = p["vel"]
			if p.has("swirl"):
				vel = vel.rotated(float(p["swirl"]) * delta)
			if p.has("gravity"):
				vel.y += float(p["gravity"]) * delta
			vel *= pow(0.24 if p.has("gravity") else 0.18, delta)
			p["vel"] = vel
			var wp: Vector2 = p["world_pos"]
			p["world_pos"] = wp + vel * delta
			_particles[idx] = p
		idx -= 1


func _draw() -> void:
	_draw_player_shadow()
	_draw_dust_particles()


func _draw_player_shadow() -> void:
	var pulse := sin(_stride_phase * 2.0) * _walk_blend
	var shift := -_move_dir * (1.2 * _walk_blend)
	var center := SHADOW_OFFSET + Vector2(shift.x, shift.y * 0.45)

	var rx := 9.2 + pulse * 0.9
	var ry := 4.4 - absf(pulse) * 0.35

	# Subtle futuristic suit rim-glow reflection on deck
	_draw_ellipse(center, rx + 2.2, ry + 1.1, Color(0.24, 0.76, 0.90, 0.08 + 0.04 * _walk_blend))
	# Soft outer penumbra shadow
	_draw_ellipse(center, rx + 0.8, ry + 0.4, Color(0.01, 0.02, 0.035, 0.24))
	# Mid contact shadow
	_draw_ellipse(center, rx * 0.78, ry * 0.78, Color(0.01, 0.015, 0.03, 0.36))
	# Deep core shadow directly under boots
	_draw_ellipse(center + Vector2(0.0, 0.3), rx * 0.50, ry * 0.52, Color(0.005, 0.01, 0.02, 0.48))

	# Alternating left/right boot contact shadow blobs during walk cycle
	var left_lift := maxf(0.0, sin(_stride_phase)) * _walk_blend
	var right_lift := maxf(0.0, -sin(_stride_phase)) * _walk_blend
	var left_pos := center + Vector2(-3.1, -0.4 - left_lift * 1.4)
	var right_pos := center + Vector2(3.1, -0.4 - right_lift * 1.4)
	_draw_ellipse(left_pos, 2.7 - left_lift * 0.5, 1.45 - left_lift * 0.25, Color(0.005, 0.01, 0.02, 0.34 * (1.0 - left_lift * 0.45)))
	_draw_ellipse(right_pos, 2.7 - right_lift * 0.5, 1.45 - right_lift * 0.25, Color(0.005, 0.01, 0.02, 0.34 * (1.0 - right_lift * 0.45)))


func _draw_dust_particles() -> void:
	for p in _particles:
		var t := clampf(float(p["age"]) / maxf(float(p["lifetime"]), 0.001), 0.0, 1.0)
		var wp_draw: Vector2 = p["world_pos"]
		var local_pos: Vector2 = to_local(wp_draw)
		var base_col: Color = p["color"]
		var kind: int = int(p["kind"])

		if kind == 0:
			# Expanding low-G boot strike ring
			var ring_rx := lerpf(2.2, 7.6, t)
			var ring_ry := lerpf(1.1, 3.6, t)
			var ring_col := Color(base_col.r, base_col.g, base_col.b, base_col.a * pow(1.0 - t, 1.5))
			_draw_ellipse_outline(local_pos, ring_rx, ring_ry, ring_col, 1.1)
		elif kind == 1:
			# Crisp pixel-art dust puff with soft core
			var fade := sin(t * PI) if t < 0.25 else pow(1.0 - t, 1.25)
			var alpha := clampf(base_col.a * fade, 0.0, 1.0)
			if alpha <= 0.01:
				continue
			var sz := float(p["size"]) * lerpf(0.85, 1.45, t)
			var puff_col := Color(base_col.r, base_col.g, base_col.b, alpha)
			var shadow_col := Color(0.08, 0.11, 0.15, alpha * 0.45)
			draw_rect(Rect2(local_pos + Vector2(-sz * 0.5, -sz * 0.5 + 1.0), Vector2(sz, sz)), shadow_col)
			draw_rect(Rect2(local_pos - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), puff_col)
		elif kind == 2:
			# Twinkling static / bio-spore mote
			var twinkle := 0.65 + 0.35 * sin(t * 22.0)
			var alpha := base_col.a * (1.0 - t * t) * twinkle
			if alpha <= 0.01:
				continue
			var mote_col := Color(base_col.r, base_col.g, base_col.b, alpha)
			var glow_col := Color(base_col.r, base_col.g, base_col.b, alpha * 0.32)
			draw_rect(Rect2(local_pos - Vector2(1.6, 1.6), Vector2(3.2, 3.2)), glow_col)
			draw_rect(Rect2(local_pos - Vector2(0.8, 0.8), Vector2(1.6, 1.6)), mote_col)
		elif kind == 3:
			# Flying magnetic boot sparks with bright streak
			var s_alpha := (1.0 - t) * base_col.a
			if s_alpha <= 0.01:
				continue
			var s_vel: Vector2 = p.get("vel", Vector2.ZERO)
			var s_head := local_pos
			var s_tail := local_pos - s_vel.normalized() * (2.8 * (1.0 - t))
			draw_line(s_tail, s_head, Color(base_col.r, base_col.g, base_col.b, s_alpha), 1.3, false)
			draw_circle(s_head, 1.2 * (1.0 - t * 0.5), Color(1.0, 1.0, 1.0, s_alpha))
		elif kind == 4:
			# Bioluminescent liquid splash droplet
			var d_alpha := (1.0 - t * t) * base_col.a
			if d_alpha <= 0.01:
				continue
			draw_circle(local_pos, 1.4 * (1.0 - t * 0.4), Color(base_col.r, base_col.g, base_col.b, d_alpha))
			draw_circle(local_pos, 0.7, Color(1.0, 1.0, 1.0, d_alpha * 0.8))


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	if rx <= 0.05 or ry <= 0.05 or color.a <= 0.005:
		return
	var pts := PackedVector2Array()
	const STEPS := 16
	for i in range(STEPS):
		var angle := TAU * float(i) / float(STEPS)
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(pts, color)


func _draw_ellipse_outline(center: Vector2, rx: float, ry: float, color: Color, width: float) -> void:
	if rx <= 0.05 or ry <= 0.05 or color.a <= 0.005:
		return
	var pts := PackedVector2Array()
	const STEPS := 16
	for i in range(STEPS + 1):
		var angle := TAU * float(i) / float(STEPS)
		pts.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_polyline(pts, color, width, false)
