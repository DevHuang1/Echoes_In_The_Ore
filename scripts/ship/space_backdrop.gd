@tool
extends AnimatedSprite2D

# Pure procedural deep-space cosmos backdrop (static/looping space image frames removed).
# Since Asteria-1's Bridge/Bow faces LEFT (-X, forward) and Aft Engines face RIGHT (+X, backward),
# all cosmic layers (nebula colors, stars, star systems, black holes, planets, and comets)
# stream BACKWARDS (+X, from left to right) at depth-graded parallax speeds!

const FIELD_EXTENTS: Vector2 = Vector2(3000.0, 1700.0)

var _overlay_canvas: Node2D = null
var _time: float = 0.0
var _base_origin: Vector2 = Vector2(887.0, 443.5)

var _nebula_clouds: Array[Dictionary] = []
var _far_stars: Array[Dictionary] = []
var _mid_stars: Array[Dictionary] = []
var _near_stars: Array[Dictionary] = []
var _star_systems: Array[Dictionary] = []
var _black_holes: Array[Dictionary] = []
var _planets: Array[Dictionary] = []
var _comets: Array[Dictionary] = []


func _ready() -> void:
	_base_origin = position
	# Remove the moving space image from AnimatedSprite2D so only procedural cosmos renders
	stop()
	sprite_frames = null
	modulate = Color(1.0, 1.0, 1.0, 1.0)

	_init_cosmos_layers()

	for child in get_children():
		child.queue_free()
	_overlay_canvas = Node2D.new()
	_overlay_canvas.name = "DeepSpaceCosmosCanvas"
	_overlay_canvas.draw.connect(_on_overlay_canvas_draw)
	add_child(_overlay_canvas)
	set_process(true)


func _hash_unit(index: int, salt: float) -> float:
	var v: float = sin(float(index) * 12.9898 + salt * 78.233) * 43758.5453
	return v - floorf(v)


func _init_cosmos_layers() -> void:
	_nebula_clouds.clear()
	_far_stars.clear()
	_mid_stars.clear()
	_near_stars.clear()
	_star_systems.clear()
	_black_holes.clear()
	_planets.clear()
	_comets.clear()

	# 1. 24 Volumetric color nebula clouds (cobalt, violet-magenta, cyan-teal, crimson-rose, and warm amber)
	var nebula_palette: Array[Color] = [
		Color(0.08, 0.28, 0.68, 0.085),
		Color(0.32, 0.12, 0.58, 0.075),
		Color(0.06, 0.52, 0.66, 0.070),
		Color(0.52, 0.14, 0.42, 0.060),
		Color(0.62, 0.34, 0.12, 0.052),
		Color(0.14, 0.18, 0.52, 0.080),
	]
	for i in range(24):
		var ncol: Color = nebula_palette[i % nebula_palette.size()]
		_nebula_clouds.append({
			"pos": Vector2((_hash_unit(i, 21.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 22.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 9.0 + _hash_unit(i, 23.3) * 7.5,
			"radius": 180.0 + _hash_unit(i, 24.4) * 240.0,
			"phase": _hash_unit(i, 25.5) * TAU,
			"color": ncol,
		})

	# 2. Star color palette
	var star_palette: Array[Color] = [
		Color(0.76, 0.88, 1.0, 1.0),
		Color(0.96, 0.98, 1.0, 1.0),
		Color(0.56, 0.84, 1.0, 1.0),
		Color(1.0, 0.86, 0.68, 1.0),
		Color(0.84, 0.72, 1.0, 1.0),
		Color(1.0, 0.68, 0.62, 1.0),
	]

	# 160 Far deep-space stars (slow backward +X drift)
	for i in range(160):
		var col: Color = star_palette[i % star_palette.size()]
		_far_stars.append({
			"pos": Vector2((_hash_unit(i, 1.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 2.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 10.0 + _hash_unit(i, 3.3) * 6.5,
			"size": 0.85 + _hash_unit(i, 4.4) * 0.85,
			"phase": _hash_unit(i, 5.5) * TAU,
			"color": col,
		})

	# 95 Mid-plane twinkling stars (medium backward +X drift)
	for i in range(95):
		var col: Color = star_palette[(i + 2) % star_palette.size()]
		_mid_stars.append({
			"pos": Vector2((_hash_unit(i, 6.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 7.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 22.0 + _hash_unit(i, 8.3) * 12.0,
			"size": 1.25 + _hash_unit(i, 9.4) * 1.25,
			"phase": _hash_unit(i, 10.5) * TAU,
			"color": col,
		})

	# 45 Near bright stars with diffraction spikes & motion trails (fast backward +X drift)
	for i in range(45):
		var col: Color = star_palette[(i + 1) % star_palette.size()]
		_near_stars.append({
			"pos": Vector2((_hash_unit(i, 11.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 12.2) - 0.5) * FIELD_EXTENTS.y),
			"speed": 46.0 + _hash_unit(i, 13.3) * 24.0,
			"size": 1.8 + _hash_unit(i, 14.4) * 1.4,
			"phase": _hash_unit(i, 15.5) * TAU,
			"color": col,
		})

	# 3. Distant Star Systems (multi-star & exoplanet orbital systems drifting backwards +X)
	_star_systems = [
		{
			"pos": Vector2(-820.0, -310.0),
			"speed": 14.0,
			"sun_color": Color(1.0, 0.88, 0.52, 1.0),
			"companion_color": Color(0.45, 0.84, 1.0, 0.95),
			"sun_radius": 11.0,
			"orbit_radii": [28.0, 48.0, 72.0],
			"orbit_speeds": [0.9, -0.55, 0.32],
			"planet_colors": [Color(0.86, 0.52, 0.36, 0.95), Color(0.38, 0.82, 0.92, 0.95), Color(0.72, 0.64, 0.94, 0.95)],
			"tilt": 0.46,
		},
		{
			"pos": Vector2(240.0, 320.0),
			"speed": 16.5,
			"sun_color": Color(0.52, 0.88, 1.0, 1.0),
			"companion_color": Color(1.0, 0.56, 0.42, 0.92),
			"sun_radius": 9.5,
			"orbit_radii": [24.0, 44.0],
			"orbit_speeds": [1.15, 0.48],
			"planet_colors": [Color(0.46, 0.94, 0.72, 0.95), Color(0.94, 0.78, 0.48, 0.95)],
			"tilt": 0.38,
		},
		{
			"pos": Vector2(960.0, -240.0),
			"speed": 12.5,
			"sun_color": Color(1.0, 0.64, 0.44, 1.0),
			"companion_color": Color(0.92, 0.82, 1.0, 0.90),
			"sun_radius": 10.0,
			"orbit_radii": [30.0, 56.0],
			"orbit_speeds": [-0.75, 0.40],
			"planet_colors": [Color(0.62, 0.78, 0.98, 0.95), Color(0.88, 0.48, 0.58, 0.95)],
			"tilt": 0.52,
		},
	]

	# 4. Black Holes with glowing relativistic accretion disks & gravitational lensing halos
	_black_holes = [
		{
			"pos": Vector2(-340.0, 250.0),
			"speed": 11.5,
			"horizon_radius": 22.0,
			"disk_radius": 68.0,
			"disk_tilt": 0.34,
			"disk_angle": -0.24,
			"inner_color": Color(1.0, 0.92, 0.68, 0.96),
			"mid_color": Color(1.0, 0.52, 0.20, 0.78),
			"outer_color": Color(0.62, 0.16, 0.48, 0.42),
		},
		{
			"pos": Vector2(780.0, -180.0),
			"speed": 9.5,
			"horizon_radius": 17.0,
			"disk_radius": 52.0,
			"disk_tilt": 0.38,
			"disk_angle": 0.30,
			"inner_color": Color(0.78, 0.96, 1.0, 0.95),
			"mid_color": Color(0.28, 0.68, 1.0, 0.74),
			"outer_color": Color(0.38, 0.18, 0.68, 0.40),
		},
	]

	# 5. Parallax Planets moving backwards (+X)
	_planets = [
		{
			"pos": Vector2(-620.0, -120.0),
			"speed": 20.0,
			"radius": 44.0,
			"body_color": Color(0.22, 0.46, 0.74, 0.96),
			"band_color": Color(0.36, 0.68, 0.92, 0.55),
			"atmo_color": Color(0.42, 0.84, 1.0, 0.36),
			"has_rings": true,
			"ring_color": Color(0.76, 0.88, 0.98, 0.52),
			"ring_tilt": 0.30,
		},
		{
			"pos": Vector2(120.0, -340.0),
			"speed": 27.0,
			"radius": 28.0,
			"body_color": Color(0.74, 0.34, 0.24, 0.96),
			"band_color": Color(0.92, 0.56, 0.34, 0.48),
			"atmo_color": Color(1.0, 0.62, 0.38, 0.30),
			"has_rings": false,
			"ring_color": Color.WHITE,
			"ring_tilt": 0.0,
		},
		{
			"pos": Vector2(580.0, 290.0),
			"speed": 32.0,
			"radius": 34.0,
			"body_color": Color(0.16, 0.58, 0.54, 0.96),
			"band_color": Color(0.38, 0.88, 0.74, 0.50),
			"atmo_color": Color(0.44, 0.96, 0.84, 0.34),
			"has_rings": true,
			"ring_color": Color(0.56, 0.94, 0.86, 0.42),
			"ring_tilt": 0.24,
		},
		{
			"pos": Vector2(-1080.0, 310.0),
			"speed": 24.0,
			"radius": 22.0,
			"body_color": Color(0.54, 0.42, 0.72, 0.95),
			"band_color": Color(0.74, 0.62, 0.92, 0.45),
			"atmo_color": Color(0.82, 0.70, 1.0, 0.28),
			"has_rings": false,
			"ring_color": Color.WHITE,
			"ring_tilt": 0.0,
		},
	]

	# 6. Comets with glowing coma heads and long ion/dust tails moving backwards (+X)
	for i in range(5):
		_comets.append({
			"pos": Vector2((_hash_unit(i, 41.1) - 0.5) * FIELD_EXTENTS.x, (_hash_unit(i, 42.2) - 0.5) * FIELD_EXTENTS.y * 0.82),
			"vel": Vector2(135.0 + float(i) * 34.0, (_hash_unit(i, 43.3) - 0.5) * 28.0),
			"tail_len": 110.0 + float(i % 3) * 38.0,
			"color": Color(0.48, 0.92, 1.0, 0.95) if (i % 2 == 0) else Color(0.72, 0.84, 1.0, 0.95),
			"phase": float(i) * 1.7,
		})


func _process(delta: float) -> void:
	_time = fposmod(_time + delta, 100000.0)
	position = _base_origin
	scale = Vector2.ONE

	if is_instance_valid(_overlay_canvas):
		_overlay_canvas.queue_redraw()


func _wrap_coord(val: float, half_span: float) -> float:
	var span: float = half_span * 2.0
	return fposmod(val + half_span, span) - half_span


func _draw_tilted_ellipse_arc(canvas: Node2D, center: Vector2, rx: float, ry: float, rot: float, start_ang: float, end_ang: float, col: Color, width: float) -> void:
	var steps: int = 28
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

	# 0. Deep cosmic abyss background fill (replaces the old static/looping JPEG space image)
	_overlay_canvas.draw_rect(
		Rect2(Vector2(-half_w, -half_h), FIELD_EXTENTS),
		Color(0.010, 0.016, 0.032, 1.0),
		true
	)

	# 1. Volumetric color nebulae drifting backwards (+X)
	for i in range(_nebula_clouds.size()):
		var neb: Dictionary = _nebula_clouds[i]
		var bpos: Vector2 = neb["pos"]
		var spd: float = float(neb["speed"])
		var rad: float = float(neb["radius"])
		var phase: float = float(neb["phase"])
		var col: Color = neb["color"]

		var nx: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var ny: float = _wrap_coord(bpos.y + sin(_time * 0.22 + phase) * 14.0, half_h)
		var npos: Vector2 = Vector2(nx, ny)
		var breathe: float = 0.88 + 0.20 * sin(_time * 0.5 + phase)
		_overlay_canvas.draw_circle(npos, rad * breathe, col)
		_overlay_canvas.draw_circle(
			npos + Vector2(rad * 0.26, -rad * 0.14),
			rad * 0.65 * breathe,
			Color(minf(col.r * 1.25, 1.0), minf(col.g * 1.25, 1.0), minf(col.b * 1.25, 1.0), col.a * 1.3)
		)

	# 2. Far deep-space starfield layer (streaming backwards +X)
	for i in range(_far_stars.size()):
		var st: Dictionary = _far_stars[i]
		var bpos: Vector2 = st["pos"]
		var spd: float = float(st["speed"])
		var sz: float = float(st["size"])
		var phase: float = float(st["phase"])
		var col: Color = st["color"]

		var sx: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var sy: float = _wrap_coord(bpos.y, half_h)
		var twinkle: float = 0.45 + 0.55 * (0.5 + 0.5 * sin(_time * 1.8 + phase))
		_overlay_canvas.draw_circle(Vector2(sx, sy), sz, Color(col.r, col.g, col.b, 0.62 * twinkle))

	# 3. Distant Star Systems (binary/primary suns with orbiting exoplanets moving backwards +X)
	for i in range(_star_systems.size()):
		var sys: Dictionary = _star_systems[i]
		var bpos: Vector2 = sys["pos"]
		var spd: float = float(sys["speed"])
		var sx: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var sy: float = _wrap_coord(bpos.y, half_h)
		var center: Vector2 = Vector2(sx, sy)
		var sun_col: Color = sys["sun_color"]
		var comp_col: Color = sys["companion_color"]
		var sun_r: float = float(sys["sun_radius"])
		var tilt: float = float(sys["tilt"])
		var radii: Array = sys["orbit_radii"]
		var speeds: Array = sys["orbit_speeds"]
		var pcols: Array = sys["planet_colors"]

		# Outer stellar corona glow
		_overlay_canvas.draw_circle(center, sun_r * 4.2, Color(sun_col.r, sun_col.g, sun_col.b, 0.10))
		_overlay_canvas.draw_circle(center, sun_r * 2.3, Color(sun_col.r, sun_col.g, sun_col.b, 0.24))

		# Elliptical planetary orbits & revolving exoplanets
		for o_idx in range(radii.size()):
			var orad: float = float(radii[o_idx])
			var ospd: float = float(speeds[o_idx])
			var pcol: Color = pcols[o_idx]
			_draw_tilted_ellipse_arc(_overlay_canvas, center, orad, orad * tilt, -0.18, 0.0, TAU, Color(sun_col.r, sun_col.g, sun_col.b, 0.16), 1.0)
			var pang: float = _time * ospd + float(o_idx) * 2.1
			var p_offset: Vector2 = Vector2(cos(pang) * orad, sin(pang) * orad * tilt).rotated(-0.18)
			var p_world: Vector2 = center + p_offset
			_overlay_canvas.draw_circle(p_world, 3.2, pcol)
			_overlay_canvas.draw_circle(p_world + Vector2(-1.0, -1.0), 1.4, Color(1.0, 1.0, 1.0, 0.65))

		# Binary companion star & primary star core
		var comp_ang: float = _time * 1.6 + float(i)
		var comp_pos: Vector2 = center + Vector2(cos(comp_ang) * (sun_r * 1.45), sin(comp_ang) * (sun_r * 0.75))
		_overlay_canvas.draw_circle(comp_pos, sun_r * 0.48, comp_col)
		_overlay_canvas.draw_circle(center, sun_r, sun_col)
		_overlay_canvas.draw_circle(center, sun_r * 0.55, Color(1.0, 0.99, 0.94, 0.96))

	# 4. Black Holes with gravitational lensing & glowing relativistic accretion disks
	for i in range(_black_holes.size()):
		var bh: Dictionary = _black_holes[i]
		var bpos: Vector2 = bh["pos"]
		var spd: float = float(bh["speed"])
		var bx: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var by: float = _wrap_coord(bpos.y, half_h)
		var center: Vector2 = Vector2(bx, by)
		var h_rad: float = float(bh["horizon_radius"])
		var d_rad: float = float(bh["disk_radius"])
		var d_tilt: float = float(bh["disk_tilt"])
		var d_ang: float = float(bh["disk_angle"])
		var in_col: Color = bh["inner_color"]
		var mid_col: Color = bh["mid_color"]
		var out_col: Color = bh["outer_color"]

		# Gravitational lensing outer glow & warped Einstein ring
		_overlay_canvas.draw_circle(center, d_rad * 1.25, Color(out_col.r, out_col.g, out_col.b, 0.14))
		_overlay_canvas.draw_arc(center, h_rad * 1.48, 0.0, TAU, 32, Color(mid_col.r, mid_col.g, mid_col.b, 0.38), 2.5, true)

		# Back half of tilted accretion disk (behind event horizon)
		_draw_tilted_ellipse_arc(_overlay_canvas, center, d_rad, d_rad * d_tilt, d_ang, PI, TAU, out_col, 7.0)
		_draw_tilted_ellipse_arc(_overlay_canvas, center, d_rad * 0.78, d_rad * 0.78 * d_tilt, d_ang, PI, TAU, mid_col, 5.0)
		_draw_tilted_ellipse_arc(_overlay_canvas, center, d_rad * 0.58, d_rad * 0.58 * d_tilt, d_ang, PI, TAU, in_col, 3.0)

		# Pitch-black Event Horizon & razor-thin relativistic photon ring
		_overlay_canvas.draw_circle(center, h_rad + 2.2, in_col)
		_overlay_canvas.draw_circle(center, h_rad, Color(0.005, 0.005, 0.012, 1.0))

		# Front half of tilted accretion disk (crossing in front of the black hole)
		_draw_tilted_ellipse_arc(_overlay_canvas, center, d_rad, d_rad * d_tilt, d_ang, 0.0, PI, out_col, 7.0)
		_draw_tilted_ellipse_arc(_overlay_canvas, center, d_rad * 0.78, d_rad * 0.78 * d_tilt, d_ang, 0.0, PI, mid_col, 5.2)
		_draw_tilted_ellipse_arc(_overlay_canvas, center, d_rad * 0.58, d_rad * 0.58 * d_tilt, d_ang, 0.0, PI, in_col, 3.2)

	# 5. Mid-plane twinkling stars (moving backwards +X)
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
		var twinkle: float = 0.55 + 0.45 * (0.5 + 0.5 * sin(_time * 3.1 + phase))
		_overlay_canvas.draw_circle(spos, sz * 1.8, Color(col.r, col.g, col.b, 0.20 * twinkle))
		_overlay_canvas.draw_circle(spos, sz, Color(col.r, col.g, col.b, 0.88 * twinkle))

	# 6. Parallax Planets (ringed gas giants & cratered exoplanets moving backwards +X)
	for i in range(_planets.size()):
		var pl: Dictionary = _planets[i]
		var bpos: Vector2 = pl["pos"]
		var spd: float = float(pl["speed"])
		var rad: float = float(pl["radius"])
		var bcol: Color = pl["body_color"]
		var band_col: Color = pl["band_color"]
		var atmo_col: Color = pl["atmo_color"]
		var has_rings: bool = bool(pl["has_rings"])
		var rcol: Color = pl["ring_color"]
		var rtilt: float = float(pl["ring_tilt"])

		var px: float = _wrap_coord(bpos.x + _time * spd, half_w)
		var py: float = _wrap_coord(bpos.y, half_h)
		var pcenter: Vector2 = Vector2(px, py)

		if has_rings:
			_draw_tilted_ellipse_arc(_overlay_canvas, pcenter, rad * 1.85, rad * 1.85 * rtilt, -0.22, PI, TAU, rcol, 4.0)
			_draw_tilted_ellipse_arc(_overlay_canvas, pcenter, rad * 1.52, rad * 1.52 * rtilt, -0.22, PI, TAU, Color(rcol.r, rcol.g, rcol.b, rcol.a * 0.65), 2.2)

		# Planet atmosphere halo & main sphere
		_overlay_canvas.draw_circle(pcenter, rad + 4.0, atmo_col)
		_overlay_canvas.draw_circle(pcenter, rad, bcol)
		# Latitudinal cloud bands / surface features
		_overlay_canvas.draw_line(pcenter + Vector2(-rad * 0.82, -rad * 0.28), pcenter + Vector2(rad * 0.82, -rad * 0.28), band_col, 3.2, true)
		_overlay_canvas.draw_line(pcenter + Vector2(-rad * 0.88, rad * 0.16), pcenter + Vector2(rad * 0.88, rad * 0.16), band_col, 2.4, true)
		# Night-side shadow crescent on the right (+X) limb
		_overlay_canvas.draw_circle(pcenter + Vector2(rad * 0.28, rad * 0.08), rad * 0.82, Color(0.01, 0.02, 0.04, 0.62))
		# Sunlit crescent rim on the left (-X) limb
		_overlay_canvas.draw_arc(pcenter, rad, PI * 0.58, PI * 1.42, 24, Color(atmo_col.r, atmo_col.g, atmo_col.b, 0.72), 2.0, true)

		if has_rings:
			_draw_tilted_ellipse_arc(_overlay_canvas, pcenter, rad * 1.85, rad * 1.85 * rtilt, -0.22, 0.0, PI, rcol, 4.0)
			_draw_tilted_ellipse_arc(_overlay_canvas, pcenter, rad * 1.52, rad * 1.52 * rtilt, -0.22, 0.0, PI, Color(rcol.r, rcol.g, rcol.b, rcol.a * 0.65), 2.2)

	# 7. Comets with bright coma & streaming ion/dust tails moving backwards (+X)
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
		var dust_end: Vector2 = head - (dir.rotated(0.12)) * (tlen * 0.82)

		# Split warm dust tail + bright cyan ion tail streaming behind the comet
		_overlay_canvas.draw_line(dust_end, head, Color(1.0, 0.82, 0.52, 0.22), 5.0, true)
		_overlay_canvas.draw_line(tail_end, head, Color(ccol.r, ccol.g, ccol.b, 0.34), 4.2, true)
		_overlay_canvas.draw_line(head - dir * (tlen * 0.45), head, Color(0.88, 0.98, 1.0, 0.78), 2.4, true)
		# Glowing coma & nucleus
		var pulse: float = 0.85 + 0.25 * sin(_time * 6.0 + phase)
		_overlay_canvas.draw_circle(head, 7.5 * pulse, Color(ccol.r, ccol.g, ccol.b, 0.28))
		_overlay_canvas.draw_circle(head, 3.2, Color(0.96, 1.0, 1.0, 0.98))

	# 8. Near bright parallax stars with backward (+X) motion streaks & diffraction spikes
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

		# Motion trail behind fast-moving foreground stars (trailing to the left -X as star moves right +X)
		var trail_len: float = spd * 0.22
		_overlay_canvas.draw_line(spos - Vector2(trail_len, 0.0), spos, Color(col.r, col.g, col.b, 0.32 * twinkle), 1.3, true)
		_overlay_canvas.draw_circle(spos, sz * 2.4, Color(col.r, col.g, col.b, 0.22 * twinkle))
		_overlay_canvas.draw_circle(spos, sz, Color(1.0, 0.98, 0.95, 0.96 * twinkle))
		var spike: float = sz * (2.6 + 0.8 * twinkle)
		var spike_col: Color = Color(col.r, col.g, col.b, 0.52 * twinkle)
		_overlay_canvas.draw_line(spos - Vector2(spike, 0.0), spos + Vector2(spike, 0.0), spike_col, 1.0, true)
		_overlay_canvas.draw_line(spos - Vector2(0.0, spike), spos + Vector2(0.0, spike), spike_col, 1.0, true)
