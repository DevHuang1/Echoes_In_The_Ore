@tool
extends AnimatedSprite2D

## Procedural Deep-Space Cosmos Backdrop with Dynamic Sector Environments.
## Asteria-1's Bridge/Bow faces LEFT (-X, forward) and Aft Engines face RIGHT (+X, backward).
## All cosmic layers (nebulae, star clusters, pulsars, asteroids, stars, black holes) stream
## BACKWARDS (+X, left to right) at depth-graded parallax speeds!

const FIELD_EXTENTS: Vector2 = Vector2(3400.0, 1900.0)

const SECTOR_NORMAL_SPACE: StringName = &"normal_space"
const SECTOR_ASTEROIDS: StringName = &"asteroid_belt"
const SECTOR_STAR: StringName = &"stellar_corona"
const SECTOR_BLACK_HOLE: StringName = &"black_hole"

var current_sector: StringName = SECTOR_NORMAL_SPACE
var _prev_sector: StringName = SECTOR_NORMAL_SPACE
var _target_sector: StringName = SECTOR_NORMAL_SPACE
var _sector_transition_time: float = 0.0
var _sector_transition_duration: float = 2.5
var _sector_blend: float = 1.0

var _overlay_canvas: Node2D = null
var _time: float = 0.0
var _base_origin: Vector2 = Vector2(887.0, 443.5)

# Normal Space Layers (770+ Stars + Phenomena)
var _nebula_clouds: Array[Dictionary] = []
var _far_stars: Array[Dictionary] = []
var _mid_stars: Array[Dictionary] = []
var _near_stars: Array[Dictionary] = []
var _star_clusters: Array[Dictionary] = []
var _cosmic_filaments: Array[Dictionary] = []
var _pulsars: Array[Dictionary] = []
var _distant_galaxies: Array[Dictionary] = []
var _comets: Array[Dictionary] = []
var _shooting_meteors: Array[Dictionary] = []

# Asteroid Belt Sector Layers
var _belt_asteroids: Array[Dictionary] = []
var _belt_dust_particles: Array[Dictionary] = []
var _collision_sparks: Array[Dictionary] = []

# Star Corona Sector Layers
var _star_prominence_loops: Array[Dictionary] = []
var _solar_wind_particles: Array[Dictionary] = []

# Black Hole Sector Layers
var _infalling_matter: Array[Dictionary] = []


func _ready() -> void:
	_base_origin = position
	stop()
	sprite_frames = null
	modulate = Color(1.0, 1.0, 1.0, 1.0)

	_init_all_cosmos_layers()

	for child in get_children():
		child.queue_free()
	_overlay_canvas = Node2D.new()
	_overlay_canvas.name = "DeepSpaceCosmosCanvas"
	_overlay_canvas.draw.connect(_on_overlay_canvas_draw)
	add_child(_overlay_canvas)
	set_process(true)


func set_cosmic_sector(new_sector: StringName, blend_duration: float = 2.5) -> void:
	if new_sector == current_sector and _target_sector == new_sector:
		return
	_prev_sector = current_sector
	_target_sector = new_sector
	_sector_transition_duration = maxf(blend_duration, 0.2)
	_sector_transition_time = 0.0
	_sector_blend = 0.0


func _hash_unit(index: int, salt: float) -> float:
	var v: float = sin(float(index) * 12.9898 + salt * 78.233) * 43758.5453
	return v - floorf(v)


func _init_all_cosmos_layers() -> void:
	_init_normal_space()
	_init_asteroid_sector()
	_init_star_sector()
	_init_black_hole_sector()


func _init_normal_space() -> void:
	_nebula_clouds.clear()
	_far_stars.clear()
	_mid_stars.clear()
	_near_stars.clear()
	_star_clusters.clear()
	_cosmic_filaments.clear()
	_pulsars.clear()
	_distant_galaxies.clear()
	_comets.clear()

	# 1. 32 Volumetric Color Nebula Clouds
	var nebula_palette: Array[Color] = [
		Color(0.08, 0.28, 0.68, 0.085), # Deep Cobalt
		Color(0.36, 0.12, 0.62, 0.075), # Royal Violet
		Color(0.06, 0.54, 0.68, 0.070), # Shimmering Cyan
		Color(0.55, 0.14, 0.44, 0.060), # Magenta Rose
		Color(0.68, 0.36, 0.14, 0.052), # Solar Amber
		Color(0.08, 0.42, 0.38, 0.065), # Emerald Veil
	]
	for i in range(32):
		var ncol: Color = nebula_palette[i % nebula_palette.size()]
		_nebula_clouds.append({
			"pos": Vector2((_hash_unit(i, 21.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 22.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 8.0 + _hash_unit(i, 23.3) * 8.5,
			"radius": 190.0 + _hash_unit(i, 24.4) * 260.0,
			"phase": _hash_unit(i, 25.5) * TAU,
			"color": ncol,
		})

	# 2. Rich Spectral Star Palette (Blue Giants, Pure Whites, Warm Yellows, Amber Dwarfs, Red Giants)
	var star_palette: Array[Color] = [
		Color(0.72, 0.88, 1.0, 1.0), # Class B Blue-White
		Color(0.96, 0.98, 1.0, 1.0), # Class A Pure White
		Color(0.48, 0.82, 1.0, 1.0), # Class O Electric Blue
		Color(1.0, 0.92, 0.72, 1.0), # Class G Solar Gold
		Color(1.0, 0.76, 0.52, 1.0), # Class K Amber
		Color(1.0, 0.56, 0.48, 1.0), # Class M Red Giant
		Color(0.85, 0.76, 1.0, 1.0), # Violet Flare
	]

	# 420 Far Stars (deep field slow parallax)
	for i in range(420):
		var col: Color = star_palette[i % star_palette.size()]
		_far_stars.append({
			"pos": Vector2((_hash_unit(i, 1.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 2.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 7.5 + _hash_unit(i, 3.3) * 7.0,
			"size": 0.75 + _hash_unit(i, 4.4) * 0.95,
			"phase": _hash_unit(i, 5.5) * TAU,
			"color": col,
		})

	# 240 Mid-Plane Twinkling Stars
	for i in range(240):
		var col: Color = star_palette[(i + 3) % star_palette.size()]
		_mid_stars.append({
			"pos": Vector2((_hash_unit(i, 6.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 7.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 18.0 + _hash_unit(i, 8.3) * 14.0,
			"size": 1.2 + _hash_unit(i, 9.4) * 1.3,
			"phase": _hash_unit(i, 10.5) * TAU,
			"color": col,
		})

	# 110 Near Bright Stars with Motion Streaks & Diffraction Spikes
	for i in range(110):
		var col: Color = star_palette[(i + 1) % star_palette.size()]
		_near_stars.append({
			"pos": Vector2((_hash_unit(i, 11.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 12.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 42.0 + _hash_unit(i, 13.3) * 26.0,
			"size": 1.75 + _hash_unit(i, 14.4) * 1.6,
			"phase": _hash_unit(i, 15.5) * TAU,
			"color": col,
		})

	# 3. Dense Star Clusters (e.g. Pleiades & Globular Clusters)
	for c_idx in range(3):
		var center_pos: Vector2 = Vector2((_hash_unit(c_idx, 81.2) - 0.5) * FIELD_EXTENTS.x * 0.8, (_hash_unit(c_idx, 82.3) - 0.5) * FIELD_EXTENTS.y * 0.7)
		var cluster_stars: Array[Dictionary] = []
		var count: int = 28 + c_idx * 12
		for s in range(count):
			var r_dist: float = pow(_hash_unit(s + c_idx * 50, 83.4), 1.6) * (90.0 + float(c_idx) * 25.0)
			var r_ang: float = _hash_unit(s + c_idx * 50, 84.5) * TAU
			cluster_stars.append({
				"offset": Vector2(cos(r_ang) * r_dist, sin(r_ang) * r_dist),
				"size": 0.8 + _hash_unit(s, 85.6) * 1.2,
				"color": star_palette[s % star_palette.size()],
				"speed": 12.0 + float(c_idx) * 3.0,
			})
		_star_clusters.append({
			"pos": center_pos,
			"speed": 12.0 + float(c_idx) * 3.0,
			"stars": cluster_stars,
		})

	# 4. Pulsars with rotating sweeping light cones
	_pulsars = [
		{
			"pos": Vector2(-750.0, -320.0),
			"speed": 11.0,
			"spin_rate": 3.8,
			"cone_len": 180.0,
			"cone_width": 24.0,
			"color": Color(0.42, 0.88, 1.0, 0.85),
		},
		{
			"pos": Vector2(620.0, 290.0),
			"speed": 14.5,
			"spin_rate": 5.2,
			"cone_len": 140.0,
			"cone_width": 18.0,
			"color": Color(1.0, 0.65, 0.42, 0.85),
		},
	]

	# 5. Distant Spiral Galaxies
	_distant_galaxies = [
		{
			"pos": Vector2(-1100.0, 220.0),
			"speed": 8.0,
			"radius": 75.0,
			"tilt": 0.42,
			"angle": 0.35,
			"core_col": Color(1.0, 0.94, 0.78, 0.95),
			"arm_col": Color(0.38, 0.68, 0.98, 0.45),
		},
		{
			"pos": Vector2(850.0, -360.0),
			"speed": 9.5,
			"radius": 58.0,
			"tilt": 0.55,
			"angle": -0.48,
			"core_col": Color(0.98, 0.82, 0.95, 0.92),
			"arm_col": Color(0.72, 0.38, 0.88, 0.42),
		},
	]

	# 6. Comets with split ion & dust tails
	for i in range(5):
		_comets.append({
			"pos": Vector2((_hash_unit(i, 41.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 42.2) - 0.5) * FIELD_EXTENTS.y * 0.82),
			"vel": Vector2(130.0 + float(i) * 32.0, (_hash_unit(i, 43.3) - 0.5) * 26.0),
			"tail_len": 115.0 + float(i % 3) * 40.0,
			"color": Color(0.48, 0.92, 1.0, 0.95) if (i % 2 == 0) else Color(0.78, 0.86, 1.0, 0.95),
			"phase": float(i) * 1.7,
		})


func _init_asteroid_sector() -> void:
	_belt_asteroids.clear()
	_belt_dust_particles.clear()
	_collision_sparks.clear()

	# 65 Parallax Asteroids with procedural vertices & ore glints
	for i in range(65):
		var rad: float = 12.0 + _hash_unit(i, 91.1) * 48.0
		var spd: float = 24.0 + (1.0 - (rad / 60.0)) * 55.0 # smaller rocks drift faster
		var verts: int = 8 + int(_hash_unit(i, 92.2) * 5.0)
		var pts: PackedVector2Array = PackedVector2Array()
		for v in range(verts):
			var ang: float = float(v) * (TAU / float(verts))
			var r_var: float = rad * (0.75 + 0.35 * _hash_unit(i * 13 + v, 93.3))
			pts.append(Vector2(cos(ang) * r_var, sin(ang) * r_var))

		var ore_c: Color = Color(0.36, 0.90, 1.0, 0.9) if (i % 3 == 0) else (Color(1.0, 0.68, 0.32, 0.9) if (i % 3 == 1) else Color(0.55, 0.55, 0.60, 0.0))
		_belt_asteroids.append({
			"pos": Vector2((_hash_unit(i, 94.4) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 95.5) - 0.5) * FIELD_EXTENTS.y),
			"speed": spd,
			"radius": rad,
			"rot": _hash_unit(i, 96.6) * TAU,
			"rot_speed": (_hash_unit(i, 97.7) - 0.5) * 1.8,
			"points": pts,
			"base_color": Color(0.18 + _hash_unit(i, 98.8) * 0.08, 0.20 + _hash_unit(i, 98.8) * 0.08, 0.24 + _hash_unit(i, 98.8) * 0.08, 0.92),
			"ore_color": ore_c,
			"depth": _hash_unit(i, 99.9),
		})

	# Asteroid belt particulate dust haze
	for i in range(90):
		_belt_dust_particles.append({
			"pos": Vector2((_hash_unit(i, 101.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 102.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 35.0 + _hash_unit(i, 103.3) * 45.0,
			"size": 1.2 + _hash_unit(i, 104.4) * 2.4,
			"color": Color(0.65, 0.72, 0.82, 0.25 + _hash_unit(i, 105.5) * 0.35),
		})


func _init_star_sector() -> void:
	_star_prominence_loops.clear()
	_solar_wind_particles.clear()

	# Coronal loops arching out from the blazing star
	for i in range(7):
		_star_prominence_loops.append({
			"base_angle": -0.8 + float(i) * 0.28,
			"height": 70.0 + _hash_unit(i, 111.1) * 90.0,
			"width": 35.0 + _hash_unit(i, 112.2) * 45.0,
			"phase": float(i) * 1.2,
			"color": Color(1.0, 0.45 + _hash_unit(i, 113.3) * 0.35, 0.15, 0.85),
		})

	# Solar wind plasma streams
	for i in range(120):
		_solar_wind_particles.append({
			"pos": Vector2(-FIELD_EXTENTS.x * 0.5 + _hash_unit(i, 121.1) * 400.0, (_hash_unit(i, 122.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 160.0 + _hash_unit(i, 123.3) * 180.0,
			"length": 25.0 + _hash_unit(i, 124.4) * 45.0,
			"color": Color(1.0, 0.78 + _hash_unit(i, 125.5) * 0.2, 0.25, 0.45 + _hash_unit(i, 126.6) * 0.4),
		})


func _init_black_hole_sector() -> void:
	_infalling_matter.clear()
	for i in range(70):
		_infalling_matter.append({
			"angle": _hash_unit(i, 131.1) * TAU,
			"distance": 80.0 + _hash_unit(i, 132.2) * 260.0,
			"speed": 0.8 + _hash_unit(i, 133.3) * 1.6,
			"spiral_rate": 18.0 + _hash_unit(i, 134.4) * 22.0,
			"size": 1.4 + _hash_unit(i, 135.5) * 2.2,
			"color": Color(0.75, 0.35, 1.0, 0.85) if (i % 2 == 0) else Color(1.0, 0.55, 0.22, 0.85),
		})


func _process(delta: float) -> void:
	_time = fposmod(_time + delta, 100000.0)
	position = _base_origin
	scale = Vector2.ONE

	# Handle smooth transition between sectors
	if _target_sector != current_sector:
		_sector_transition_time += delta
		_sector_blend = clampf(_sector_transition_time / _sector_transition_duration, 0.0, 1.0)
		if _sector_blend >= 1.0:
			current_sector = _target_sector
			_prev_sector = current_sector
			_sector_blend = 1.0
	else:
		_sector_blend = 1.0

	# Spawn shooting meteors occasionally in normal space
	if current_sector == SECTOR_NORMAL_SPACE or _target_sector == SECTOR_NORMAL_SPACE:
		if fposmod(_time, 4.2) < delta and _shooting_meteors.size() < 4:
			var half_w: float = FIELD_EXTENTS.x * 0.5
			var half_h: float = FIELD_EXTENTS.y * 0.5
			_shooting_meteors.append({
				"pos": Vector2(-half_w + randf() * 300.0, -half_h * 0.7 + randf() * half_h * 1.4),
				"vel": Vector2(450.0 + randf() * 250.0, (randf() - 0.5) * 80.0),
				"life": 1.2,
				"max_life": 1.2,
			})

	# Advance shooting meteors
	var m_idx: int = _shooting_meteors.size() - 1
	while m_idx >= 0:
		var met: Dictionary = _shooting_meteors[m_idx]
		met["pos"] = met["pos"] + met["vel"] * delta
		met["life"] = float(met["life"]) - delta
		_shooting_meteors[m_idx] = met
		if float(met["life"]) <= 0.0:
			_shooting_meteors.remove_at(m_idx)
		m_idx -= 1

	if is_instance_valid(_overlay_canvas):
		_overlay_canvas.queue_redraw()


func _wrap_coord(val: float, half_span: float) -> float:
	var span: float = half_span * 2.0
	return fposmod(val + half_span, span) - half_span


func _draw_tilted_ellipse_arc(canvas: Node2D, center: Vector2, rx: float, ry: float, rot: float, start_ang: float, end_ang: float, col: Color, width: float) -> void:
	var steps: int = 32
	var pts: PackedVector2Array = PackedVector2Array()
	for s in range(steps + 1):
		var a: float = lerpf(start_ang, end_ang, float(s) / float(steps))
		var local_pt: Vector2 = Vector2(cos(a) * rx, sin(a) * ry).rotated(rot)
		pts.append(center + local_pt)
	canvas.draw_polyline(pts, col, width, true)


func _on_overlay_canvas_draw() -> void:
	if not is_instance_valid(_overlay_canvas):
		return

	var half_w: float = FIELD_EXTENTS.x * 0.5
	var half_h: float = FIELD_EXTENTS.y * 0.5

	# 0. Deep Cosmic Abyss Background Fill
	var space_bg_color: Color = Color(0.008, 0.014, 0.028, 1.0)
	if current_sector == SECTOR_STAR or _target_sector == SECTOR_STAR:
		var star_weight: float = _sector_blend if (_target_sector == SECTOR_STAR) else (1.0 - _sector_blend)
		space_bg_color = space_bg_color.lerp(Color(0.042, 0.018, 0.010, 1.0), star_weight * 0.7)
	elif current_sector == SECTOR_BLACK_HOLE or _target_sector == SECTOR_BLACK_HOLE:
		var bh_weight: float = _sector_blend if (_target_sector == SECTOR_BLACK_HOLE) else (1.0 - _sector_blend)
		space_bg_color = space_bg_color.lerp(Color(0.014, 0.008, 0.024, 1.0), bh_weight * 0.6)

	_overlay_canvas.draw_rect(Rect2(Vector2(-half_w, -half_h), FIELD_EXTENTS), space_bg_color, true)

	# 1. Volumetric Color Nebulae
	for i in range(_nebula_clouds.size()):
		var neb: Dictionary = _nebula_clouds[i]
		var bpos: Vector2 = neb["pos"]
		var spd: float = float(neb["speed"])
		var rad: float = float(neb["radius"])
		var phase: float = float(neb["phase"])
		var col: Color = neb["color"]

		var nx: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var ny: float = _wrap_coord(bpos.y + sin(_time * 0.22 + phase) * 15.0, half_h)
		var npos: Vector2 = Vector2(nx, ny)
		var breathe: float = 0.88 + 0.20 * sin(_time * 0.45 + phase)
		_overlay_canvas.draw_circle(npos, rad * breathe, col)
		_overlay_canvas.draw_circle(
			npos + Vector2(rad * 0.25, -rad * 0.15),
			rad * 0.65 * breathe,
			Color(minf(col.r * 1.25, 1.0), minf(col.g * 1.25, 1.0), minf(col.b * 1.25, 1.0), col.a * 1.35)
		)

	# 2. Far Deep-Space Starfield (420 stars streaming +X)
	for i in range(_far_stars.size()):
		var st: Dictionary = _far_stars[i]
		var bpos: Vector2 = st["pos"]
		var spd: float = float(st["speed"])
		var sz: float = float(st["size"])
		var phase: float = float(st["phase"])
		var col: Color = st["color"]

		var sx: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var sy: float = _wrap_coord(bpos.y, half_h)
		var twinkle: float = 0.40 + 0.60 * (0.5 + 0.5 * sin(_time * 1.9 + phase))
		_overlay_canvas.draw_circle(Vector2(sx, sy), sz, Color(col.r, col.g, col.b, 0.68 * twinkle))

	# 3. Dense Star Clusters (Pleiades & Globular Clusters)
	for c_idx in range(_star_clusters.size()):
		var cl: Dictionary = _star_clusters[c_idx]
		var bpos: Vector2 = cl["pos"]
		var spd: float = float(cl["speed"])
		var cx: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var cy: float = _wrap_coord(bpos.y, half_h)
		var c_center: Vector2 = Vector2(cx, cy)
		var stars: Array = cl["stars"]
		for s in stars:
			var s_off: Vector2 = s["offset"]
			var s_sz: float = float(s["size"])
			var s_col: Color = s["color"]
			_overlay_canvas.draw_circle(c_center + s_off, s_sz, Color(s_col.r, s_col.g, s_col.b, 0.85))

	# 4. Mid-Plane Twinkling Stars (240 stars)
	for i in range(_mid_stars.size()):
		var st: Dictionary = _mid_stars[i]
		var bpos: Vector2 = st["pos"]
		var spd: float = float(st["speed"])
		var sz: float = float(st["size"])
		var phase: float = float(st["phase"])
		var col: Color = st["color"]

		var sx: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var sy: float = _wrap_coord(bpos.y, half_h)
		var spos: Vector2 = Vector2(sx, sy)
		var twinkle: float = 0.50 + 0.50 * (0.5 + 0.5 * sin(_time * 3.2 + phase))
		_overlay_canvas.draw_circle(spos, sz * 1.8, Color(col.r, col.g, col.b, 0.22 * twinkle))
		_overlay_canvas.draw_circle(spos, sz, Color(col.r, col.g, col.b, 0.90 * twinkle))

	# 5. Pulsars with Sweeping Beams
	for i in range(_pulsars.size()):
		var pul: Dictionary = _pulsars[i]
		var bpos: Vector2 = pul["pos"]
		var spd: float = float(pul["speed"])
		var px: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var py: float = _wrap_coord(bpos.y, half_h)
		var p_pos: Vector2 = Vector2(px, py)
		var spin: float = float(pul["spin_rate"])
		var clen: float = float(pul["cone_len"])
		var ccol: Color = pul["color"]

		var beam_ang: float = _time * spin
		var beam_dir: Vector2 = Vector2(cos(beam_ang), sin(beam_ang))
		# Draw twin sweeping light cones
		_overlay_canvas.draw_line(p_pos, p_pos + beam_dir * clen, Color(ccol.r, ccol.g, ccol.b, 0.40), 3.0, true)
		_overlay_canvas.draw_line(p_pos, p_pos - beam_dir * clen, Color(ccol.r, ccol.g, ccol.b, 0.40), 3.0, true)
		# Pulsar neutron core
		_overlay_canvas.draw_circle(p_pos, 5.0, ccol)
		_overlay_canvas.draw_circle(p_pos, 2.2, Color.WHITE)

	# 6. Distant Spiral Galaxies
	for i in range(_distant_galaxies.size()):
		var gal: Dictionary = _distant_galaxies[i]
		var bpos: Vector2 = gal["pos"]
		var spd: float = float(gal["speed"])
		var gx: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var gy: float = _wrap_coord(bpos.y, half_h)
		var g_center: Vector2 = Vector2(gx, gy)
		var grad: float = float(gal["radius"])
		var tilt: float = float(gal["tilt"])
		var ang: float = float(gal["angle"])
		var ccol: Color = gal["core_col"]
		var acol: Color = gal["arm_col"]
		# Draw galactic core and outer spiral disks
		_draw_tilted_ellipse_arc(_overlay_canvas, g_center, grad, grad * tilt, ang, 0.0, TAU, acol, 4.0)
		_draw_tilted_ellipse_arc(_overlay_canvas, g_center, grad * 0.65, grad * 0.65 * tilt, ang + 0.4, 0.0, TAU, Color(acol.r, acol.g, acol.b, acol.a * 1.4), 3.0)
		_overlay_canvas.draw_circle(g_center, grad * 0.22, ccol)
		_overlay_canvas.draw_circle(g_center, grad * 0.10, Color.WHITE)

	# 7. Comets with Streaming Ion & Dust Tails
	for i in range(_comets.size()):
		var cm: Dictionary = _comets[i]
		var bpos: Vector2 = cm["pos"]
		var vel: Vector2 = cm["vel"]
		var tlen: float = float(cm["tail_len"])
		var ccol: Color = cm["color"]
		var phase: float = float(cm["phase"])

		var cx: float = _wrap_coord(bpos.x + _time * vel.x, half_w)
		var cy: float = _wrap_coord(bpos.y + _time * vel.y, half_h)
		var head: Vector2 = Vector2(cx, cy)
		var dir: Vector2 = vel.normalized()
		var tail_end: Vector2 = head - dir * tlen
		var dust_end: Vector2 = head - (dir.rotated(0.12)) * (tlen * 0.85)

		_overlay_canvas.draw_line(dust_end, head, Color(1.0, 0.82, 0.52, 0.25), 5.5, true)
		_overlay_canvas.draw_line(tail_end, head, Color(ccol.r, ccol.g, ccol.b, 0.38), 4.5, true)
		_overlay_canvas.draw_line(head - dir * (tlen * 0.45), head, Color(0.92, 0.98, 1.0, 0.82), 2.5, true)
		var pulse: float = 0.85 + 0.25 * sin(_time * 6.0 + phase)
		_overlay_canvas.draw_circle(head, 7.8 * pulse, Color(ccol.r, ccol.g, ccol.b, 0.30))
		_overlay_canvas.draw_circle(head, 3.4, Color(0.98, 1.0, 1.0, 0.98))

	# 8. Near Bright Parallax Stars (110 stars with motion streaks & diffraction spikes)
	for i in range(_near_stars.size()):
		var st: Dictionary = _near_stars[i]
		var bpos: Vector2 = st["pos"]
		var spd: float = float(st["speed"])
		var sz: float = float(st["size"])
		var phase: float = float(st["phase"])
		var col: Color = st["color"]

		var sx: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var sy: float = _wrap_coord(bpos.y, half_h)
		var spos: Vector2 = Vector2(sx, sy)
		var twinkle: float = 0.65 + 0.35 * (0.5 + 0.5 * sin(_time * 4.2 + phase))

		var trail_len: float = spd * 0.24
		_overlay_canvas.draw_line(spos - Vector2(trail_len, 0.0), spos, Color(col.r, col.g, col.b, 0.35 * twinkle), 1.4, true)
		_overlay_canvas.draw_circle(spos, sz * 2.5, Color(col.r, col.g, col.b, 0.24 * twinkle))
		_overlay_canvas.draw_circle(spos, sz, Color(1.0, 0.98, 0.95, 0.98 * twinkle))
		var spike: float = sz * (2.8 + 0.8 * twinkle)
		var spike_col: Color = Color(col.r, col.g, col.b, 0.55 * twinkle)
		_overlay_canvas.draw_line(spos - Vector2(spike, 0.0), spos + Vector2(spike, 0.0), spike_col, 1.1, true)
		_overlay_canvas.draw_line(spos - Vector2(0.0, spike), spos + Vector2(0.0, spike), spike_col, 1.1, true)

	# 9. Shooting Meteors
	for met in _shooting_meteors:
		var mpos: Vector2 = met["pos"]
		var mvel: Vector2 = met["vel"]
		var tail: Vector2 = mpos - mvel.normalized() * 65.0
		var life_norm: float = float(met["life"]) / float(met["max_life"])
		_overlay_canvas.draw_line(tail, mpos, Color(0.85, 0.95, 1.0, 0.65 * life_norm), 2.2, true)
		_overlay_canvas.draw_circle(mpos, 2.8, Color(1.0, 1.0, 1.0, life_norm))

	# 10. SECTOR-SPECIFIC PROCEDURAL OVERLAYS
	_draw_sector_specific_elements(half_w, half_h)


func _draw_sector_specific_elements(half_w: float, half_h: float) -> void:
	var sec: StringName = current_sector
	var next_sec: StringName = _target_sector
	var blend: float = _sector_blend

	# Check which sectors are active or blending in
	var asteroid_alpha: float = 0.0
	var star_alpha: float = 0.0
	var bh_alpha: float = 0.0

	if sec == SECTOR_ASTEROIDS:
		asteroid_alpha = 1.0 - (blend if next_sec != SECTOR_ASTEROIDS else 0.0)
	elif next_sec == SECTOR_ASTEROIDS:
		asteroid_alpha = blend

	if sec == SECTOR_STAR:
		star_alpha = 1.0 - (blend if next_sec != SECTOR_STAR else 0.0)
	elif next_sec == SECTOR_STAR:
		star_alpha = blend

	if sec == SECTOR_BLACK_HOLE:
		bh_alpha = 1.0 - (blend if next_sec != SECTOR_BLACK_HOLE else 0.0)
	elif next_sec == SECTOR_BLACK_HOLE:
		bh_alpha = blend

	if asteroid_alpha > 0.01:
		_draw_asteroid_belt_layer(half_w, half_h, asteroid_alpha)
	if star_alpha > 0.01:
		_draw_stellar_corona_layer(half_w, half_h, star_alpha)
	if bh_alpha > 0.01:
		_draw_black_hole_singularity_layer(half_w, half_h, bh_alpha)


func _draw_asteroid_belt_layer(half_w: float, half_h: float, alpha: float) -> void:
	# Particulate rocky dust
	for dp in _belt_dust_particles:
		var bpos: Vector2 = dp["pos"]
		var spd: float = float(dp["speed"])
		var sz: float = float(dp["size"])
		var col: Color = dp["color"]
		var dx: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var dy: float = _wrap_coord(bpos.y, half_h)
		_overlay_canvas.draw_circle(Vector2(dx, dy), sz, Color(col.r, col.g, col.b, col.a * alpha))

	# Drifting rocky asteroids with ore veins
	for ast in _belt_asteroids:
		var bpos: Vector2 = ast["pos"]
		var spd: float = float(ast["speed"])
		var rad: float = float(ast["radius"])
		var rot: float = float(ast["rot"]) + float(ast["rot_speed"]) * _time
		var pts: PackedVector2Array = ast["points"]
		var bcol: Color = ast["base_color"]
		var ocol: Color = ast["ore_color"]

		var ax: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var ay: float = _wrap_coord(bpos.y, half_h)
		var center: Vector2 = Vector2(ax, ay)

		var xform_pts: PackedVector2Array = PackedVector2Array()
		for p in pts:
			xform_pts.append(center + p.rotated(rot))
		_overlay_canvas.draw_colored_polygon(xform_pts, Color(bcol.r, bcol.g, bcol.b, bcol.a * alpha))
		xform_pts.append(xform_pts[0])
		_overlay_canvas.draw_polyline(xform_pts, Color(0.48, 0.52, 0.58, 0.85 * alpha), 1.8, true)

		# Ore vein highlight
		if ocol.a > 0.05:
			var v1: Vector2 = center + Vector2(-rad * 0.35, -rad * 0.2).rotated(rot)
			var v2: Vector2 = center + Vector2(rad * 0.32, rad * 0.25).rotated(rot)
			_overlay_canvas.draw_line(v1, v2, Color(ocol.r, ocol.g, ocol.b, ocol.a * alpha), 2.2, true)


func _draw_stellar_corona_layer(half_w: float, half_h: float, alpha: float) -> void:
	# Colossal blazing solar limb ahead on the left (-X, forward bow)
	var sun_center: Vector2 = Vector2(-half_w * 0.82, 0.0)
	var sun_rad: float = 620.0

	# Massive outer corona glow
	var pulse: float = 0.94 + 0.06 * sin(_time * 2.5)
	_overlay_canvas.draw_circle(sun_center, sun_rad * 2.4 * pulse, Color(1.0, 0.45, 0.12, 0.14 * alpha))
	_overlay_canvas.draw_circle(sun_center, sun_rad * 1.6 * pulse, Color(1.0, 0.65, 0.22, 0.26 * alpha))
	_overlay_canvas.draw_circle(sun_center, sun_rad * 1.15, Color(1.0, 0.82, 0.40, 0.50 * alpha))

	# Primary photosphere core
	_overlay_canvas.draw_circle(sun_center, sun_rad, Color(1.0, 0.92, 0.70, 0.98 * alpha))
	_overlay_canvas.draw_circle(sun_center, sun_rad * 0.75, Color(1.0, 0.99, 0.92, 0.98 * alpha))

	# Coronal prominence loops
	for loop in _star_prominence_loops:
		var ang: float = float(loop["base_angle"]) + sin(_time * 0.4 + float(loop["phase"])) * 0.08
		var h: float = float(loop["height"]) * (0.85 + 0.15 * sin(_time * 3.0 + float(loop["phase"])))
		var w: float = float(loop["width"])
		var col: Color = loop["color"]
		var base_pt: Vector2 = sun_center + Vector2(cos(ang), sin(ang)) * sun_rad
		var apex_pt: Vector2 = sun_center + Vector2(cos(ang), sin(ang)) * (sun_rad + h)
		var loop_pts: PackedVector2Array = PackedVector2Array([
			base_pt - Vector2(-sin(ang), cos(ang)) * w * 0.5,
			apex_pt,
			base_pt + Vector2(-sin(ang), cos(ang)) * w * 0.5,
		])
		_overlay_canvas.draw_polyline(loop_pts, Color(col.r, col.g, col.b, col.a * alpha), 3.5, true)

	# Solar wind streams blowing backwards (+X)
	for sw in _solar_wind_particles:
		var bpos: Vector2 = sw["pos"]
		var spd: float = float(sw["speed"])
		var slen: float = float(sw["length"])
		var scol: Color = sw["color"]
		var sx: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var sy: float = bpos.y
		_overlay_canvas.draw_line(Vector2(sx - slen, sy), Vector2(sx, sy), Color(scol.r, scol.g, scol.b, scol.a * alpha), 1.8, true)


func _draw_black_hole_singularity_layer(half_w: float, half_h: float, alpha: float) -> void:
	# Supermassive black hole on the forward left (-X)
	var bh_center: Vector2 = Vector2(-half_w * 0.35, 40.0)
	var horizon_rad: float = 68.0
	var disk_rad: float = 240.0
	var disk_tilt: float = 0.32
	var disk_ang: float = -0.25

	# Gravitational lensing outer Einstein ring & distortion glow
	_overlay_canvas.draw_circle(bh_center, disk_rad * 1.55, Color(0.45, 0.18, 0.75, 0.18 * alpha))
	_overlay_canvas.draw_arc(bh_center, horizon_rad * 1.65, 0.0, TAU, 36, Color(0.38, 0.78, 1.0, 0.45 * alpha), 3.0, true)

	# Back half of relativistic accretion disk (behind event horizon)
	_draw_tilted_ellipse_arc(_overlay_canvas, bh_center, disk_rad, disk_rad * disk_tilt, disk_ang, PI, TAU, Color(0.65, 0.18, 0.52, 0.55 * alpha), 12.0)
	_draw_tilted_ellipse_arc(_overlay_canvas, bh_center, disk_rad * 0.75, disk_rad * 0.75 * disk_tilt, disk_ang, PI, TAU, Color(1.0, 0.52, 0.18, 0.85 * alpha), 8.0)
	_draw_tilted_ellipse_arc(_overlay_canvas, bh_center, disk_rad * 0.52, disk_rad * 0.52 * disk_tilt, disk_ang, PI, TAU, Color(0.48, 0.92, 1.0, 0.95 * alpha), 4.5)

	# Pitch-black Event Horizon & Photon Sphere
	_overlay_canvas.draw_circle(bh_center, horizon_rad + 3.2, Color(0.78, 0.95, 1.0, 0.95 * alpha))
	_overlay_canvas.draw_circle(bh_center, horizon_rad, Color(0.002, 0.003, 0.008, alpha))

	# Front half of relativistic accretion disk (crossing in front)
	_draw_tilted_ellipse_arc(_overlay_canvas, bh_center, disk_rad, disk_rad * disk_tilt, disk_ang, 0.0, PI, Color(0.65, 0.18, 0.52, 0.55 * alpha), 12.0)
	_draw_tilted_ellipse_arc(_overlay_canvas, bh_center, disk_rad * 0.75, disk_rad * 0.75 * disk_tilt, disk_ang, 0.0, PI, Color(1.0, 0.52, 0.18, 0.85 * alpha), 8.5)
	_draw_tilted_ellipse_arc(_overlay_canvas, bh_center, disk_rad * 0.52, disk_rad * 0.52 * disk_tilt, disk_ang, 0.0, PI, Color(0.48, 0.92, 1.0, 0.95 * alpha), 5.0)

	# Relativistic polar jets (vertical gamma ray beams)
	var jet_top: Vector2 = bh_center + Vector2(0.0, -half_h * 0.95)
	var jet_bot: Vector2 = bh_center + Vector2(0.0, half_h * 0.95)
	_overlay_canvas.draw_line(bh_center, jet_top, Color(0.55, 0.88, 1.0, 0.40 * alpha), 3.5, true)
	_overlay_canvas.draw_line(bh_center, jet_bot, Color(0.55, 0.88, 1.0, 0.40 * alpha), 3.5, true)

	# Swirling infalling matter
	for m in _infalling_matter:
		var a: float = float(m["angle"]) + _time * float(m["speed"])
		var d: float = fposmod(float(m["distance"]) - _time * float(m["spiral_rate"]), 240.0) + horizon_rad * 1.1
		var m_pos: Vector2 = bh_center + Vector2(cos(a) * d, sin(a) * d * disk_tilt).rotated(disk_ang)
		var mcol: Color = m["color"]
		var msz: float = float(m["size"])
		_overlay_canvas.draw_circle(m_pos, msz, Color(mcol.r, mcol.g, mcol.b, mcol.a * alpha))
